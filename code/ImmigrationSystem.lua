--
-- ImmigrationSystem.lua
-- Manages immigrant generation, queue, and integration for Alpha Prototype
--

local DataLoader = require("code.DataLoader")
local CharacterV3 = require("code.consumption.CharacterV3")

ImmigrationSystem = {}
ImmigrationSystem.__index = ImmigrationSystem

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

function ImmigrationSystem:Create(world)
    local sys = setmetatable({}, ImmigrationSystem)

    sys.world = world

    -- Load configuration
    sys:LoadConfig()

    -- Load land config for immigration requirements
    sys.landConfig = DataLoader.loadLandConfig()

    -- Queue state
    sys.queue = {}
    sys.lastGenerationDay = 0

    -- Generate initial applicants so there's something to see
    sys:GenerateInitialApplicants()

    return sys
end

function ImmigrationSystem:GenerateInitialApplicants()
    -- Generate 5-8 initial applicants
    local count = math.random(5, 8)
    self:GenerateApplicants(count, 1)
    print("ImmigrationSystem: Generated " .. count .. " initial applicants")
end

function ImmigrationSystem:LoadConfig()
    -- Load immigration config
    self.config = DataLoader.loadImmigrationConfig() or self:GetDefaultConfig()

    -- Load names
    self.names = DataLoader.loadNames() or self:GetDefaultNames()

    -- Load origins
    self.origins = DataLoader.loadOrigins() or self:GetDefaultOrigins()

    -- Load worker types and build vocations by class dynamically
    self.workerTypes = DataLoader.loadWorkerTypes() or {}
    self:BuildVocationsFromWorkerTypes()

    print("ImmigrationSystem: Loaded config, " .. #self.names.lastNames .. " last names, " ..
          #self.origins.townNames .. " origin towns, " .. #self.workerTypes .. " worker types")
end

function ImmigrationSystem:BuildVocationsFromWorkerTypes()
    -- Build vocationsForClass dynamically from worker_types.json based on minimumWage/skillLevel
    -- This replaces any hardcoded vocations in config
    local vocsByClass = {
        Elite = {},
        Upper = {},
        Middle = {},
        Working = {},
        Poor = {}
    }

    for _, wt in ipairs(self.workerTypes) do
        local wage = wt.minimumWage or 10
        local skill = wt.skillLevel or "Basic"
        local name = wt.name

        -- Map to class based on wage and skill level
        if wage >= 25 or skill == "Expert" then
            table.insert(vocsByClass.Elite, name)
        elseif wage >= 15 or skill == "Skilled" then
            table.insert(vocsByClass.Upper, name)
        elseif wage >= 10 then
            table.insert(vocsByClass.Middle, name)
        elseif wage >= 8 then
            table.insert(vocsByClass.Working, name)
        else
            table.insert(vocsByClass.Poor, name)
        end
    end

    -- Also add to adjacent classes for more variety
    for _, wt in ipairs(self.workerTypes) do
        local wage = wt.minimumWage or 10
        local name = wt.name

        -- Working class can also have some middle-tier jobs
        if wage >= 10 and wage < 15 then
            if not self:TableContains(vocsByClass.Working, name) then
                table.insert(vocsByClass.Working, name)
            end
        end
        -- Poor can also do basic working class jobs
        if wage >= 7 and wage < 10 then
            if not self:TableContains(vocsByClass.Poor, name) then
                table.insert(vocsByClass.Poor, name)
            end
        end
    end

    -- Override config vocationsForClass with dynamically built one
    self.config.vocationsForClass = vocsByClass
end

function ImmigrationSystem:TableContains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end

function ImmigrationSystem:GetDefaultConfig()
    return {
        generation = {
            attractionWeight = 0.50,
            needsWeight = 0.25,
            randomWeight = 0.25,
            queueCapacity = 10,
            generationIntervalDays = 5,
            expiryMinDays = 10,
            expiryMaxDays = 20,
            deferPenaltyDays = 2
        },
        compatibilityWeights = {
            craving = 0.40,
            housing = 0.25,
            job = 0.25,
            social = 0.10
        },
        classRanges = {
            Elite = {ageMin = 30, ageMax = 70, wealthMin = 2000, wealthMax = 5000, familyChance = 0.40},
            Upper = {ageMin = 25, ageMax = 65, wealthMin = 800, wealthMax = 2500, familyChance = 0.35},
            Middle = {ageMin = 20, ageMax = 60, wealthMin = 200, wealthMax = 800, familyChance = 0.50},
            Working = {ageMin = 18, ageMax = 55, wealthMin = 50, wealthMax = 300, familyChance = 0.45},
            Poor = {ageMin = 16, ageMax = 50, wealthMin = 0, wealthMax = 100, familyChance = 0.30}
        },
        -- vocationsForClass is built dynamically from worker_types.json in BuildVocationsFromWorkerTypes()
        vocationsForClass = {}
    }
end

function ImmigrationSystem:GetDefaultNames()
    return {
        firstNames = {
            male = {"John", "William", "James", "Thomas", "Robert"},
            female = {"Mary", "Elizabeth", "Sarah", "Anna", "Margaret"}
        },
        lastNames = {"Smith", "Johnson", "Williams", "Brown", "Jones"}
    }
end

function ImmigrationSystem:GetDefaultOrigins()
    return {
        townNames = {"Ironhaven", "Millbrook", "Stonegate", "Riverside"},
        hardships = {"the great fire", "the plague", "the famine"},
        dangers = {"rising violence", "corrupt lords", "economic collapse"},
        motivations = {default = {"seeks a fresh start"}},
        backstoryTemplates = {"{name} fled {origin} after {hardship}."}
    }
end

-- =============================================================================
-- QUEUE MANAGEMENT
-- =============================================================================

function ImmigrationSystem:Update(currentDay)
    -- Remove expired applicants
    self:RemoveExpiredApplicants(currentDay)

    -- Generate new applicants if interval passed
    local genConfig = self.config.generation
    if currentDay - self.lastGenerationDay >= genConfig.generationIntervalDays then
        local toGenerate = genConfig.queueCapacity - #self.queue
        if toGenerate > 0 then
            self:GenerateApplicants(toGenerate, currentDay)
            self.lastGenerationDay = currentDay
            self.world:LogEvent("immigration", "New immigrants are seeking to join!", {})
        end
    end
end

function ImmigrationSystem:RemoveExpiredApplicants(currentDay)
    for i = #self.queue, 1, -1 do
        local applicant = self.queue[i]
        if currentDay >= applicant.expiryDay then
            self.world:LogEvent("immigration", applicant.name .. " found another town", {})
            table.remove(self.queue, i)
        end
    end
end

function ImmigrationSystem:GetQueueCount()
    return #self.queue
end

function ImmigrationSystem:GetApplicants()
    return self.queue
end

function ImmigrationSystem:GetDaysUntilNextBatch(currentDay)
    local genConfig = self.config.generation
    return math.max(0, genConfig.generationIntervalDays - (currentDay - self.lastGenerationDay))
end

-- =============================================================================
-- APPLICANT ACTIONS
-- =============================================================================

function ImmigrationSystem:AcceptApplicant(applicant, selectedPlots)
    -- Phase 4: Check land requirements for wealthy/merchant roles
    local landReqs = applicant.landRequirements or {}
    if landReqs.minPlots and landReqs.minPlots > 0 then
        if not selectedPlots or #selectedPlots < landReqs.minPlots then
            return false, "Must purchase at least " .. landReqs.minPlots .. " plots"
        end

        -- Verify applicant can afford the plots
        local totalPlotCost = 0
        if self.world.landSystem then
            for _, plotId in ipairs(selectedPlots) do
                local plot = self.world.landSystem:GetPlotById(plotId)
                if plot then
                    totalPlotCost = totalPlotCost + (plot.purchasePrice or 0)
                end
            end
        end

        if totalPlotCost > (applicant.wealth or 0) then
            return false, "Insufficient funds for land purchase"
        end

        -- Deduct plot cost from wealth
        applicant.wealth = applicant.wealth - totalPlotCost
        -- Town receives the money
        self.world.gold = self.world.gold + totalPlotCost
    end

    -- Find housing using HousingSystem if available
    local housing = nil
    if self.world.housingSystem then
        local availableHousing = self.world.housingSystem:GetAvailableHousing(applicant.class)
        if #availableHousing > 0 then
            housing = { id = availableHousing[1].buildingId }
        end
    else
        housing = self:FindHousingForClass(applicant.class)
    end

    if not housing then
        -- For wealthy/merchant who bought land, they can build their own housing
        if landReqs.minPlots and landReqs.minPlots > 0 and selectedPlots and #selectedPlots > 0 then
            -- Auto-setup for elites: place a house on their first plot
            housing = self:AutoSetupEliteHousing(applicant, selectedPlots)
        end

        if not housing then
            return false, "No suitable housing available"
        end
    end

    -- Create citizen from applicant
    local citizen = self:CreateCitizenFromApplicant(applicant)
    if not citizen then
        return false, "Failed to create citizen"
    end

    -- Phase 4: Initialize in economics system
    if self.world.economicsSystem then
        self.world.economicsSystem:InitializeCharacter(citizen.id, applicant.wealth or 0)
    end

    -- Assign housing using HousingSystem if available
    if self.world.housingSystem and housing and housing.id then
        self.world.housingSystem:AssignHousing(citizen.id, housing.id)
    else
        -- Legacy housing assignment
        citizen.residence = housing
        if housing and housing.residents then
            table.insert(housing.residents, citizen)
        end
    end

    -- Phase 4: Transfer land plots to new owner
    if selectedPlots and self.world.landSystem then
        for _, plotId in ipairs(selectedPlots) do
            self.world.landSystem:TransferOwnership(plotId, citizen.id, 0, self.world.timeManager:GetDay())
        end
    end

    -- Add to world
    table.insert(self.world.citizens, citizen)

    -- Add family members
    local familyMembers = {}
    if applicant.family then
        for _, familyMember in ipairs(applicant.family) do
            local member = self:CreateCitizenFromApplicant(familyMember)
            if member then
                -- Initialize family member in economics (dependents have 0 wealth)
                if self.world.economicsSystem then
                    self.world.economicsSystem:InitializeCharacter(member.id, 0)
                end

                -- Assign housing
                if self.world.housingSystem and housing and housing.id then
                    self.world.housingSystem:AssignHousing(member.id, housing.id)
                else
                    member.residence = housing
                    if housing and housing.residents then
                        table.insert(housing.residents, member)
                    end
                end

                -- Add family relationships
                citizen:AddRelationship(member.id, familyMember.familyRelationType or "family", self.world.timeManager:GetDay())
                member:AddRelationship(citizen.id, "family", self.world.timeManager:GetDay())

                table.insert(self.world.citizens, member)
                table.insert(familyMembers, member)
            end
        end
    end

    -- Remove from queue
    self:RemoveFromQueue(applicant)

    -- Log event
    local familyNote = applicant.family and (" (with " .. #applicant.family .. " family members)") or ""
    local landNote = (selectedPlots and #selectedPlots > 0) and (" and purchased " .. #selectedPlots .. " plots") or ""
    self.world:LogEvent("immigration", applicant.name .. " has joined the town!" .. familyNote .. landNote, {})

    return true, citizen, nil
end

-- Auto-setup housing for elite immigrants (Phase 4)
function ImmigrationSystem:AutoSetupEliteHousing(applicant, selectedPlots)
    if not selectedPlots or #selectedPlots == 0 then
        return nil
    end

    -- Get the first plot to build on
    local firstPlotId = selectedPlots[1]
    local plot = self.world.landSystem and self.world.landSystem:GetPlotById(firstPlotId)

    if not plot then
        return nil
    end

    -- Determine housing type based on intended role
    local housingType = "house"  -- default
    if applicant.intendedRole == "wealthy" then
        housingType = "manor"
        if (applicant.wealth or 0) > 3000 then
            housingType = "estate"
        end
    elseif applicant.intendedRole == "merchant" then
        housingType = "townhouse"
    end

    -- Check if building type exists
    local buildingType = self.world.buildingTypesById and self.world.buildingTypesById[housingType]
    if not buildingType then
        housingType = "house"  -- fallback
    end

    -- Create the building
    local building = self.world:AddBuilding(housingType, plot.worldX, plot.worldY, {
        ownerId = applicant.name,  -- Will be updated to citizen.id after creation
        purchasePrice = 0  -- They already own the land
    })

    if building then
        print(string.format("[ImmigrationSystem] Auto-placed %s for %s on plot %s",
            housingType, applicant.name, firstPlotId))
        return building
    end

    return nil
end

-- Check if applicant can be accepted (for UI) (Phase 4)
function ImmigrationSystem:CanAcceptApplicant(applicant)
    local landReqs = applicant.landRequirements or {}

    -- Check land requirements
    if landReqs.minPlots and landReqs.minPlots > 0 then
        -- Check if enough town-owned plots are available
        local availablePlots = 0
        if self.world.landSystem then
            local townPlots = self.world.landSystem:GetAvailablePlots()
            availablePlots = #townPlots
        end

        if availablePlots < landReqs.minPlots then
            return false, "Not enough plots available (need " .. landReqs.minPlots .. ", have " .. availablePlots .. ")"
        end

        -- Check if applicant can afford the minimum required plots
        local minPlotCost = 0
        if self.world.landSystem then
            local townPlots = self.world.landSystem:GetAvailablePlots()
            -- Sort by price (cheapest first)
            table.sort(townPlots, function(a, b)
                return (a.purchasePrice or 0) < (b.purchasePrice or 0)
            end)
            for i = 1, math.min(landReqs.minPlots, #townPlots) do
                minPlotCost = minPlotCost + (townPlots[i].purchasePrice or 0)
            end
        end

        if minPlotCost > (applicant.wealth or 0) then
            return false, "Cannot afford minimum plots (cost " .. minPlotCost .. ", have " .. (applicant.wealth or 0) .. ")"
        end
    end

    -- Check housing availability (for non-land-buying immigrants)
    if not landReqs.minPlots or landReqs.minPlots == 0 then
        local hasHousing = false
        if self.world.housingSystem then
            local available = self.world.housingSystem:GetAvailableHousing(applicant.class)
            hasHousing = #available > 0
        else
            hasHousing = self:FindHousingForClass(applicant.class) ~= nil
        end

        if not hasHousing then
            return false, "No suitable housing available"
        end
    end

    return true, nil
end

-- Get available plots for selection (Phase 4)
function ImmigrationSystem:GetAvailablePlotsForPurchase(applicant)
    if not self.world.landSystem then
        return {}
    end

    local townPlots = self.world.landSystem:GetAvailablePlots()
    local affordablePlots = {}

    for _, plot in ipairs(townPlots) do
        if (plot.purchasePrice or 0) <= (applicant.wealth or 0) then
            table.insert(affordablePlots, {
                id = plot.id,
                gridX = plot.gridX,
                gridY = plot.gridY,
                price = plot.purchasePrice or 0,
                terrainType = plot.terrainType,
                resources = plot.naturalResources
            })
        end
    end

    -- Sort by price
    table.sort(affordablePlots, function(a, b)
        return a.price < b.price
    end)

    return affordablePlots
end

function ImmigrationSystem:RejectApplicant(applicant)
    self:RemoveFromQueue(applicant)
    self.world:LogEvent("immigration", applicant.name .. " was rejected", {})
end

function ImmigrationSystem:DeferApplicant(applicant)
    -- Move to end of queue with penalty
    self:RemoveFromQueue(applicant)
    applicant.expiryDay = applicant.expiryDay - self.config.generation.deferPenaltyDays
    table.insert(self.queue, applicant)
end

function ImmigrationSystem:RemoveFromQueue(applicant)
    for i, a in ipairs(self.queue) do
        if a == applicant then
            table.remove(self.queue, i)
            return
        end
    end
end

-- =============================================================================
-- APPLICANT GENERATION
-- =============================================================================

function ImmigrationSystem:GenerateApplicants(count, currentDay)
    local genConfig = self.config.generation

    -- Calculate how many of each type
    local attractionCount = math.floor(count * genConfig.attractionWeight + 0.5)
    local needsCount = math.floor(count * genConfig.needsWeight + 0.5)
    local randomCount = count - attractionCount - needsCount

    -- Generate attraction-based applicants
    for i = 1, attractionCount do
        local applicant = self:GenerateAttractionBasedApplicant(currentDay)
        if applicant then
            table.insert(self.queue, applicant)
        end
    end

    -- Generate needs-based applicants
    for i = 1, needsCount do
        local applicant = self:GenerateNeedsBasedApplicant(currentDay)
        if applicant then
            table.insert(self.queue, applicant)
        end
    end

    -- Generate random applicants
    for i = 1, randomCount do
        local applicant = self:GenerateRandomApplicant(currentDay)
        if applicant then
            table.insert(self.queue, applicant)
        end
    end

    print("ImmigrationSystem: Generated " .. #self.queue .. " applicants")
end

function ImmigrationSystem:GenerateAttractionBasedApplicant(currentDay)
    -- Calculate class attractiveness and pick weighted random class
    local attractiveness = self:CalculateClassAttractiveness()
    local class = self:WeightedRandomClass(attractiveness)

    return self:GenerateApplicantOfClass(class, currentDay)
end

function ImmigrationSystem:GenerateNeedsBasedApplicant(currentDay)
    -- Get town's unfilled positions
    local needs = self:GetTownNeeds()

    if next(needs) == nil then
        -- No specific needs, fall back to random
        return self:GenerateRandomApplicant(currentDay)
    end

    -- Pick weighted random vocation based on needs
    local vocation = self:WeightedRandomVocation(needs)
    local class = self:GetClassForVocation(vocation)

    local applicant = self:GenerateApplicantOfClass(class, currentDay)
    if applicant then
        applicant.vocation = vocation
    end
    return applicant
end

function ImmigrationSystem:GenerateRandomApplicant(currentDay)
    -- Fully random class selection
    local classes = {"Elite", "Upper", "Middle", "Working", "Poor"}
    local class = classes[math.random(1, #classes)]

    return self:GenerateApplicantOfClass(class, currentDay)
end

function ImmigrationSystem:GenerateApplicantOfClass(class, currentDay)
    local classRange = self.config.classRanges[class]
    if not classRange then
        classRange = {ageMin = 20, ageMax = 50, wealthMin = 100, wealthMax = 500, familyChance = 0.3}
    end

    local genConfig = self.config.generation

    -- Basic info
    local gender = math.random() > 0.5 and "male" or "female"
    local firstName = self:RandomFirstName(gender)
    local lastName = self:RandomLastName()
    local name = firstName .. " " .. lastName

    local age = math.random(classRange.ageMin, classRange.ageMax)
    local wealth = math.random(classRange.wealthMin, classRange.wealthMax)

    -- Determine intendedRole based on class and wealth (Phase 4)
    local intendedRole = self:DetermineIntendedRole(class, wealth)

    -- Vocation - "General Worker" is the fallback from worker_types.json
    local vocations = self.config.vocationsForClass[class] or {"General Worker"}
    local vocation = vocations[math.random(1, #vocations)]

    -- Traits
    local traitCount = math.random(classRange.traitCountMin or 1, classRange.traitCountMax or 2)
    local traits = self:GenerateRandomTraits(traitCount)

    -- Expiry
    local expiryDays = math.random(genConfig.expiryMinDays, genConfig.expiryMaxDays)
    local expiryDay = currentDay + expiryDays

    -- Family
    local family = nil
    if math.random() < classRange.familyChance then
        family = self:GenerateFamily(class, lastName, currentDay)
    end

    -- Origin and backstory
    local origin = self.origins.townNames[math.random(1, #self.origins.townNames)]

    -- Create craving profile (using CharacterV3 generation)
    local cravingProfile = self:GenerateCravingProfile(class)

    -- Generate backstory
    local backstory = self:GenerateBackstory(name, gender, vocation, origin, cravingProfile)

    -- Get land requirements for this role
    local landRequirements = self:GetLandRequirementsForRole(intendedRole)

    local applicant = {
        name = name,
        firstName = firstName,
        lastName = lastName,
        gender = gender,
        age = age,
        class = class,
        intendedRole = intendedRole,  -- Phase 4: wealthy/merchant/craftsman/laborer
        vocation = vocation,
        traits = traits,
        wealth = wealth,
        startingWealth = wealth,  -- Alias for Phase 4 compatibility
        origin = origin,
        backstory = backstory,
        family = family,
        cravingProfile = cravingProfile,
        expiryDay = expiryDay,
        arrivalDay = currentDay,
        landRequirements = landRequirements  -- Phase 4: how many plots they need
    }

    -- Calculate compatibility
    applicant.compatibility = self:CalculateCompatibility(applicant)

    return applicant
end

-- Determine intended role based on class and wealth (Phase 4)
function ImmigrationSystem:DetermineIntendedRole(class, wealth)
    -- Map class to intendedRole
    if class == "Elite" then
        return "wealthy"
    elseif class == "Upper" then
        -- Upper class could be wealthy or merchant depending on wealth
        if wealth >= 2000 then
            return "wealthy"
        else
            return "merchant"
        end
    elseif class == "Middle" then
        -- Middle class could be merchant or craftsman
        if wealth >= 500 then
            return "merchant"
        else
            return "craftsman"
        end
    elseif class == "Working" or class == "Poor" then
        return "laborer"
    else
        return "laborer"
    end
end

-- Get land requirements for an intended role (Phase 4)
function ImmigrationSystem:GetLandRequirementsForRole(intendedRole)
    local requirements = {
        minPlots = 0,
        maxPlots = 0,
        minTotalValue = 0
    }

    if self.landConfig and self.landConfig.immigrationRequirements then
        local roleReqs = self.landConfig.immigrationRequirements[intendedRole]
        if roleReqs then
            requirements.minPlots = roleReqs.minPlots or 0
            requirements.maxPlots = roleReqs.maxPlots or 0
            requirements.minTotalValue = roleReqs.minTotalValue or 0
        end
    else
        -- Default requirements
        if intendedRole == "wealthy" then
            requirements.minPlots = 4
            requirements.maxPlots = 10
        elseif intendedRole == "merchant" then
            requirements.minPlots = 2
            requirements.maxPlots = 4
        end
        -- craftsman and laborer have 0 requirements
    end

    return requirements
end

function ImmigrationSystem:GenerateFamily(class, lastName, currentDay)
    local family = {}

    -- Spouse
    local spouseGender = math.random() > 0.5 and "male" or "female"
    local spouseFirstName = self:RandomFirstName(spouseGender)
    local spouse = {
        name = spouseFirstName .. " " .. lastName,
        firstName = spouseFirstName,
        lastName = lastName,
        gender = spouseGender,
        age = math.random(20, 55),
        class = class,
        vocation = "Homemaker",
        traits = self:GenerateRandomTraits(1),
        isDependent = true
    }
    table.insert(family, spouse)

    -- Children (0-3)
    local childCount = math.random(0, 2)
    for i = 1, childCount do
        local childGender = math.random() > 0.5 and "male" or "female"
        local childFirstName = self:RandomFirstName(childGender)
        local child = {
            name = childFirstName .. " " .. lastName,
            firstName = childFirstName,
            lastName = lastName,
            gender = childGender,
            age = math.random(2, 16),
            class = class,
            vocation = "Child",
            traits = {},
            isDependent = true
        }
        table.insert(family, child)
    end

    return family
end

-- =============================================================================
-- COMPATIBILITY CALCULATION
-- =============================================================================

function ImmigrationSystem:CalculateCompatibility(applicant)
    local weights = self.config.compatibilityWeights

    local cravingScore = self:CalculateCravingSatisfactionPotential(applicant)
    local housingScore = self:CalculateHousingMatch(applicant)
    local jobScore = self:CalculateJobMatch(applicant)
    local socialScore = self:CalculateSocialFit(applicant)

    local total = (cravingScore * weights.craving) +
                  (housingScore * weights.housing) +
                  (jobScore * weights.job) +
                  (socialScore * weights.social)

    return math.floor(total)
end

function ImmigrationSystem:CalculateCravingSatisfactionPotential(applicant)
    -- Get top cravings from profile
    local topCravings = self:GetTopCravings(applicant.cravingProfile, 5)
    local totalScore = 0

    for i, craving in ipairs(topCravings) do
        local canFulfill = self:CanTownFulfillCraving(craving)
        local weight = (6 - i) / 15  -- 5/15, 4/15, 3/15, 2/15, 1/15
        totalScore = totalScore + (canFulfill * 100 * weight)
    end

    return totalScore
end

function ImmigrationSystem:CanTownFulfillCraving(craving)
    -- Check if town produces commodities that fulfill this craving
    -- Simplified: check inventory levels
    local inventory = self.world.inventory or {}
    local productionBuildings = self.world.buildings or {}

    local score = 0.3  -- Base score

    -- Check if we have production buildings
    if #productionBuildings > 2 then
        score = score + 0.3
    end

    -- Check inventory diversity
    local inventoryCount = 0
    for _, count in pairs(inventory) do
        if count > 0 then
            inventoryCount = inventoryCount + 1
        end
    end
    if inventoryCount > 3 then
        score = score + 0.4
    end

    return math.min(1, score)
end

function ImmigrationSystem:CalculateHousingMatch(applicant)
    local class = applicant.class
    local vacantHousing = self:GetVacantHousingByClass()

    -- Exact class match
    if vacantHousing[class] and vacantHousing[class] > 0 then
        return 100
    end

    -- Any housing available (simplified for alpha)
    local totalVacant = 0
    for _, count in pairs(vacantHousing) do
        totalVacant = totalVacant + count
    end

    if totalVacant > 0 then
        return 60  -- Some housing, not ideal
    end

    return 0  -- No housing
end

function ImmigrationSystem:CalculateJobMatch(applicant)
    local vocation = applicant.vocation
    local openings = self:GetJobOpeningsForVocation(vocation)

    if openings > 0 then
        return 100
    end

    -- Check for any jobs
    local totalOpenings = self:GetTotalJobOpenings()
    if totalOpenings > 0 then
        return 40  -- Can work, not ideal vocation
    end

    return 10  -- No jobs, but can be unemployed
end

function ImmigrationSystem:CalculateSocialFit(applicant)
    local score = 50  -- Base neutral fit

    -- Bonus for others of same class
    local sameClassCount = 0
    for _, citizen in ipairs(self.world.citizens or {}) do
        if citizen.class == applicant.class then
            sameClassCount = sameClassCount + 1
        end
    end
    score = score + math.min(sameClassCount * 5, 25)

    -- Bonus for existing population (not too small)
    local popSize = #(self.world.citizens or {})
    if popSize >= 5 then
        score = score + 15
    end
    if popSize >= 10 then
        score = score + 10
    end

    return math.min(100, score)
end

-- =============================================================================
-- TOWN ANALYSIS
-- =============================================================================

function ImmigrationSystem:CalculateClassAttractiveness()
    local attractiveness = {}
    local classes = {"Elite", "Upper", "Middle", "Working", "Poor"}

    for _, class in ipairs(classes) do
        local baseAttraction = 50

        -- Factor 1: Average satisfaction of existing citizens of this class
        local classSat = self:GetAverageClassSatisfaction(class)
        local satBonus = (classSat - 50) * 0.5

        -- Factor 2: Available housing
        local housingAvailable = self:GetVacantHousingByClass()[class] or 0
        local housingBonus = housingAvailable > 0 and 15 or -10

        -- Factor 3: Job availability
        local jobBonus = math.min(self:GetTotalJobOpenings() * 2, 20)

        -- Factor 4: Town reputation
        local townHappiness = self.world.stats and self.world.stats.averageSatisfaction or 50
        local repBonus = (townHappiness - 50) * 0.3

        attractiveness[class] = math.max(5, math.min(100, baseAttraction + satBonus + housingBonus + jobBonus + repBonus))
    end

    return attractiveness
end

function ImmigrationSystem:GetAverageClassSatisfaction(class)
    local total = 0
    local count = 0

    for _, citizen in ipairs(self.world.citizens or {}) do
        if citizen.class == class then
            local sat = citizen.GetAverageSatisfaction and citizen:GetAverageSatisfaction() or 50
            total = total + sat
            count = count + 1
        end
    end

    return count > 0 and (total / count) or 50
end

function ImmigrationSystem:GetVacantHousingByClass()
    local vacant = {Elite = 0, Upper = 0, Middle = 0, Working = 0, Poor = 0}

    for _, building in ipairs(self.world.buildings or {}) do
        if building.type and building.type.category == "housing" then
            local capacity = building.capacity or 4
            local residents = building.residents and #building.residents or 0
            local free = capacity - residents

            if free > 0 then
                -- Determine housing class (simplified)
                local housingClass = building.housingClass or "Middle"
                vacant[housingClass] = (vacant[housingClass] or 0) + free
            end
        end
    end

    -- Also count general housing capacity
    local totalCapacity = 0
    local totalResidents = #(self.world.citizens or {})
    for _, building in ipairs(self.world.buildings or {}) do
        if building.type and building.type.category == "housing" then
            totalCapacity = totalCapacity + (building.capacity or 4)
        end
    end

    -- Simplified: distribute remaining to Middle class
    local remaining = totalCapacity - totalResidents
    if remaining > 0 then
        vacant.Middle = (vacant.Middle or 0) + remaining
    end

    return vacant
end

function ImmigrationSystem:GetTownNeeds()
    local needs = {}

    for _, building in ipairs(self.world.buildings or {}) do
        local maxWorkers = building.maxWorkers or 2
        local currentWorkers = building.workers and #building.workers or 0
        local vacantSlots = maxWorkers - currentWorkers

        if vacantSlots > 0 then
            -- Get preferred vocations for building
            local vocations = building.type and building.type.workCategories or {"General Labor"}
            for _, vocation in ipairs(vocations) do
                needs[vocation] = (needs[vocation] or 0) + vacantSlots
            end
        end
    end

    return needs
end

function ImmigrationSystem:GetJobOpeningsForVocation(vocation)
    local openings = 0

    for _, building in ipairs(self.world.buildings or {}) do
        local maxWorkers = building.maxWorkers or 2
        local currentWorkers = building.workers and #building.workers or 0
        local vacantSlots = maxWorkers - currentWorkers

        if vacantSlots > 0 then
            local vocations = building.type and building.type.workCategories or {}
            for _, v in ipairs(vocations) do
                if v == vocation or v == "General Labor" then
                    openings = openings + vacantSlots
                    break
                end
            end
        end
    end

    return openings
end

function ImmigrationSystem:GetTotalJobOpenings()
    local openings = 0

    for _, building in ipairs(self.world.buildings or {}) do
        local maxWorkers = building.maxWorkers or 2
        local currentWorkers = building.workers and #building.workers or 0
        openings = openings + (maxWorkers - currentWorkers)
    end

    return openings
end

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

function ImmigrationSystem:WeightedRandomClass(attractiveness)
    local total = 0
    for _, weight in pairs(attractiveness) do
        total = total + weight
    end

    local rand = math.random() * total
    local cumulative = 0

    for class, weight in pairs(attractiveness) do
        cumulative = cumulative + weight
        if rand <= cumulative then
            return class
        end
    end

    return "Middle"  -- Fallback
end

function ImmigrationSystem:WeightedRandomVocation(needs)
    local total = 0
    for _, weight in pairs(needs) do
        total = total + weight
    end

    if total == 0 then
        return "General Worker"
    end

    local rand = math.random() * total
    local cumulative = 0

    for vocation, weight in pairs(needs) do
        cumulative = cumulative + weight
        if rand <= cumulative then
            return vocation
        end
    end

    return "General Worker"
end

function ImmigrationSystem:GetClassForVocation(vocation)
    for class, vocations in pairs(self.config.vocationsForClass or {}) do
        for _, v in ipairs(vocations) do
            if v == vocation then
                return class
            end
        end
    end
    return "Working"  -- Default
end

function ImmigrationSystem:RandomFirstName(gender)
    local names = self.names.firstNames[gender] or self.names.firstNames.male
    return names[math.random(1, #names)]
end

function ImmigrationSystem:RandomLastName()
    return self.names.lastNames[math.random(1, #self.names.lastNames)]
end

function ImmigrationSystem:GenerateRandomTraits(count)
    -- characterTraits has structure {version: "...", traits: [...]}
    local traitsData = self.world.characterTraits or {}
    local allTraits = traitsData.traits or {}
    local traitIds = {}

    -- allTraits is an array of trait objects with id, name, etc.
    for _, trait in ipairs(allTraits) do
        if trait.id then
            table.insert(traitIds, trait.name or trait.id)
        end
    end

    if #traitIds == 0 then
        return {"Hardworking"}  -- Fallback
    end

    local traits = {}
    local used = {}

    for i = 1, count do
        local attempts = 0
        while attempts < 10 do
            local idx = math.random(1, #traitIds)
            local trait = traitIds[idx]
            if not used[trait] then
                table.insert(traits, trait)
                used[trait] = true
                break
            end
            attempts = attempts + 1
        end
    end

    return traits
end

function ImmigrationSystem:GenerateCravingProfile(class)
    -- Simplified craving profile based on class
    local profile = {}
    local coarseNames = {"Biological", "Safety", "Touch", "Psychological", "Status", "Social", "Exotic", "Shiny", "Vice"}

    -- Class-based modifiers
    local classModifiers = {
        Elite = {Biological = -20, Safety = -10, Status = 30, Exotic = 20, Shiny = 25},
        Upper = {Biological = -10, Safety = -5, Status = 20, Exotic = 10, Shiny = 15},
        Middle = {Biological = 0, Safety = 0, Psychological = 10, Social = 10},
        Working = {Biological = 10, Safety = 10, Social = 5, Status = -10},
        Poor = {Biological = 20, Safety = 20, Status = -20, Exotic = -20, Shiny = -20}
    }

    local mods = classModifiers[class] or {}

    for _, name in ipairs(coarseNames) do
        local base = 40 + math.random(0, 40)
        local mod = mods[name] or 0
        profile[name] = math.max(10, math.min(100, base + mod))
    end

    return profile
end

function ImmigrationSystem:GetTopCravings(profile, count)
    local sorted = {}
    for name, value in pairs(profile) do
        table.insert(sorted, {name = name, value = value})
    end

    table.sort(sorted, function(a, b) return a.value > b.value end)

    local result = {}
    for i = 1, math.min(count, #sorted) do
        table.insert(result, sorted[i])
    end

    return result
end

function ImmigrationSystem:FindHousingForClass(class)
    -- Find first available housing
    for _, building in ipairs(self.world.buildings or {}) do
        if building.type and building.type.category == "housing" then
            local capacity = building.capacity or 4
            local residents = building.residents and #building.residents or 0
            if residents < capacity then
                return building
            end
        end
    end
    return nil
end

function ImmigrationSystem:CreateCitizenFromApplicant(applicant)
    -- Create a CharacterV3 from applicant data
    local citizen = CharacterV3:New(applicant.class)

    citizen.name = applicant.name
    citizen.firstName = applicant.firstName
    citizen.lastName = applicant.lastName
    citizen.gender = applicant.gender
    citizen.age = applicant.age
    citizen.vocation = applicant.vocation
    citizen.traits = applicant.traits or {}
    citizen.origin = applicant.origin
    citizen.backstory = applicant.backstory

    -- Set position
    citizen.x = 100 + math.random(0, 400)
    citizen.y = 100 + math.random(0, 300)

    return citizen
end

-- =============================================================================
-- BACKSTORY GENERATION
-- =============================================================================

function ImmigrationSystem:GenerateBackstory(name, gender, vocation, origin, cravingProfile)
    local topCravings = self:GetTopCravings(cravingProfile, 3)
    local topCategory = topCravings[1] and topCravings[1].name or "default"

    -- Get motivation based on top need
    local motivations = self.origins.motivations[topCategory:lower()] or self.origins.motivations.default or {"seeks a fresh start"}
    local motivation = motivations[math.random(1, #motivations)]

    -- Get hardship and danger
    local hardship = self.origins.hardships[math.random(1, #self.origins.hardships)]
    local danger = self.origins.dangers[math.random(1, #self.origins.dangers)]

    -- Get template
    local templates = self.origins.backstoryTemplates or {"{name} fled {origin} after {hardship}."}
    local template = templates[math.random(1, #templates)]

    -- Pronoun setup
    local pronoun = gender == "male" and "he" or "she"
    local possessive = gender == "male" and "his" or "her"
    local reflexive = gender == "male" and "himself" or "herself"
    local pronounCap = gender == "male" and "He" or "She"

    -- Fill template
    local backstory = template
    backstory = backstory:gsub("{name}", name)
    backstory = backstory:gsub("{origin}", origin)
    backstory = backstory:gsub("{hardship}", hardship)
    backstory = backstory:gsub("{danger}", danger)
    backstory = backstory:gsub("{vocation}", vocation)
    backstory = backstory:gsub("{motivation_sentence}", pronounCap .. " " .. motivation)
    backstory = backstory:gsub("{motivation_short}", motivation:gsub("seeks ", ""):gsub("hopes to ", ""):gsub("wants to ", ""))
    backstory = backstory:gsub("{pronoun}", pronoun)
    backstory = backstory:gsub("{possessive}", possessive)
    backstory = backstory:gsub("{reflexive}", reflexive)
    backstory = backstory:gsub("{family}", "the family")
    backstory = backstory:gsub("{year}", tostring(1200 + math.random(0, 50)))

    return backstory
end

-- =============================================================================
-- OVERALL TOWN ATTRACTIVENESS
-- =============================================================================

function ImmigrationSystem:GetOverallAttractiveness()
    local attractiveness = self:CalculateClassAttractiveness()
    local total = 0
    local count = 0

    for _, value in pairs(attractiveness) do
        total = total + value
        count = count + 1
    end

    return count > 0 and (total / count) or 50
end

function ImmigrationSystem:GetTotalVacantHousing()
    local vacant = self:GetVacantHousingByClass()
    local total = 0
    for _, count in pairs(vacant) do
        total = total + count
    end
    return total
end

return ImmigrationSystem
