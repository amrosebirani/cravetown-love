--
-- HousingSystem.lua
-- Housing assignment, satisfaction, upgrades, and relocation management
--

local DataLoader = require("code.DataLoader")

local HousingSystem = {}
HousingSystem.__index = HousingSystem

-- Housing status
local HOUSING_STATUS = {
    HOMELESS = "homeless",
    HOUSED = "housed",
    SEEKING = "seeking"
}

-- Occupancy types
local OCCUPANCY_TYPE = {
    FAMILY = "family",       -- Family unit (cannot be split)
    SINGLE = "single",       -- Single occupant
    ROOMMATE = "roommate"    -- Single sharing with others
}

-- Rent payment status
local RENT_STATUS = {
    CURRENT = "current",
    OVERDUE_1 = "overdue_1",   -- 1 cycle overdue
    OVERDUE_2 = "overdue_2",   -- 2 cycles overdue
    EVICTION_WARNING = "eviction_warning",  -- 3+ cycles, final warning
    EVICTED = "evicted"
}

-- Crowding thresholds (occupants / capacity)
local CROWDING_THRESHOLDS = {
    COMFORTABLE = 0.5,    -- <= 50% capacity
    NORMAL = 0.75,        -- <= 75% capacity
    CROWDED = 1.0,        -- <= 100% capacity
    OVERCROWDED = 1.25    -- > 100% (if allowed)
}

function HousingSystem:Create(buildingManager, economicsSystem, cravingSystem, landSystem)
    local system = setmetatable({}, HousingSystem)

    system.buildingManager = buildingManager
    system.economicsSystem = economicsSystem
    system.cravingSystem = cravingSystem
    system.landSystem = landSystem

    -- Housing assignments: characterId -> housingRecord
    system.housingAssignments = {}

    -- Building occupancy: buildingId -> { occupants[], capacity, housingConfig }
    system.buildingOccupancy = {}

    -- Family units: familyId -> { headId, memberIds[], housingNeeded }
    system.familyUnits = {}

    -- Relocation queue: characters seeking new housing
    system.relocationQueue = {}

    -- Eviction warnings: characterId -> { cyclesOverdue, lastWarningCycle }
    system.evictionWarnings = {}

    -- Load building types for housing config lookup
    system.buildingTypes = system:LoadBuildingTypes()

    -- Housing dimension indices (from dimension_definitions.json)
    system.housingDimensions = {
        basic = 50,
        good = 51,
        luxury = 52,
        prestige = 53,
        weather = 54
    }

    -- Configuration
    system.config = {
        maxRentOverdueCycles = 60,        -- Cycles before eviction
        evictionGracePeriod = 10,         -- Extra cycle after warning
        roommateCompatibilityThreshold = 0.3,  -- Min relationship score for roommates
        crowdingSatisfactionPenalty = {
            comfortable = 0,
            normal = 0,
            crowded = -10,
            overcrowded = -25
        },
        allowOvercrowding = false,       -- Whether to allow > 100% capacity
        landRentEnabled = true           -- Whether to charge land rent separately
    }

    print("[HousingSystem] Created with family tracking")

    return system
end

function HousingSystem:LoadBuildingTypes()
    local filepath = "data/" .. DataLoader.activeVersion .. "/building_types.json"
    local success, data = pcall(function()
        return DataLoader.loadJSON(filepath)
    end)
    if success and data then
        return data
    else
        print("  WARNING: Could not load building types for HousingSystem")
        return {}
    end
end

-- ============================================================================
-- Building Registration
-- ============================================================================

function HousingSystem:RegisterHousingBuilding(buildingId, buildingTypeId)
    local buildingType = self.buildingTypes[buildingTypeId]
    if not buildingType or not buildingType.housingConfig then
        return false, "Building type is not housing"
    end

    local config = buildingType.housingConfig

    self.buildingOccupancy[buildingId] = {
        buildingTypeId = buildingTypeId,
        occupants = {},
        capacity = config.capacity or 1,
        housingQuality = config.housingQuality or 0.5,
        qualityTier = config.qualityTier or "basic",
        rentPerOccupant = config.rentPerOccupant or 0,
        targetClasses = config.targetClasses or {},
        upgradeableTo = config.upgradeableTo
    }

    print(string.format("[HousingSystem] Registered housing building %s (%s) with capacity %d",
        buildingId, buildingTypeId, config.capacity or 1))

    return true
end

function HousingSystem:UnregisterHousingBuilding(buildingId)
    local occupancy = self.buildingOccupancy[buildingId]
    if not occupancy then
        return false
    end

    -- Evict all occupants
    for _, characterId in ipairs(occupancy.occupants) do
        self:EvictCharacter(characterId, "building_removed")
    end

    self.buildingOccupancy[buildingId] = nil
    return true
end

-- ============================================================================
-- Housing Assignment
-- ============================================================================

function HousingSystem:AssignHousing(characterId, buildingId)
    local occupancy = self.buildingOccupancy[buildingId]
    if not occupancy then
        return false, "Building is not registered housing"
    end

    if #occupancy.occupants >= occupancy.capacity then
        return false, "Building is at capacity"
    end

    -- Remove from current housing if any
    local currentHousing = self.housingAssignments[characterId]
    if currentHousing and currentHousing.buildingId then
        self:RemoveFromHousing(characterId)
    end

    -- Add to new housing
    table.insert(occupancy.occupants, characterId)

    self.housingAssignments[characterId] = {
        buildingId = buildingId,
        buildingTypeId = occupancy.buildingTypeId,
        status = HOUSING_STATUS.HOUSED,
        assignedCycle = 0,  -- Should be set by caller
        housingQuality = occupancy.housingQuality,
        qualityTier = occupancy.qualityTier,
        rentAmount = occupancy.rentPerOccupant
    }

    -- Remove from relocation queue if present
    self:RemoveFromRelocationQueue(characterId)

    print(string.format("[HousingSystem] Assigned %s to housing %s", characterId, buildingId))

    return true
end

function HousingSystem:RemoveFromHousing(characterId)
    local assignment = self.housingAssignments[characterId]
    if not assignment or not assignment.buildingId then
        return false
    end

    local occupancy = self.buildingOccupancy[assignment.buildingId]
    if occupancy then
        for i, occupantId in ipairs(occupancy.occupants) do
            if occupantId == characterId then
                table.remove(occupancy.occupants, i)
                break
            end
        end
    end

    self.housingAssignments[characterId] = {
        buildingId = nil,
        status = HOUSING_STATUS.HOMELESS,
        previousBuildingId = assignment.buildingId
    }

    return true
end

function HousingSystem:EvictCharacter(characterId, reason)
    local success = self:RemoveFromHousing(characterId)
    if success then
        -- Add to relocation queue
        self:AddToRelocationQueue(characterId, reason or "evicted")
        print(string.format("[HousingSystem] Evicted %s: %s", characterId, reason or "evicted"))
    end
    return success
end

-- ============================================================================
-- Housing Queries
-- ============================================================================

function HousingSystem:GetHousingAssignment(characterId)
    return self.housingAssignments[characterId]
end

function HousingSystem:GetHousingStatus(characterId)
    local assignment = self.housingAssignments[characterId]
    if assignment then
        return assignment.status
    end
    return HOUSING_STATUS.HOMELESS
end

function HousingSystem:GetBuildingOccupancy(buildingId)
    return self.buildingOccupancy[buildingId]
end

function HousingSystem:GetBuildingOccupants(buildingId)
    local occupancy = self.buildingOccupancy[buildingId]
    if occupancy then
        return occupancy.occupants
    end
    return {}
end

function HousingSystem:GetAvailableHousing(targetClass)
    local available = {}

    for buildingId, occupancy in pairs(self.buildingOccupancy) do
        if #occupancy.occupants < occupancy.capacity then
            -- Check if class is appropriate
            local classMatch = true
            if targetClass and #occupancy.targetClasses > 0 then
                classMatch = false
                for _, tc in ipairs(occupancy.targetClasses) do
                    if tc == targetClass then
                        classMatch = true
                        break
                    end
                end
            end

            if classMatch then
                table.insert(available, {
                    buildingId = buildingId,
                    buildingTypeId = occupancy.buildingTypeId,
                    availableSlots = occupancy.capacity - #occupancy.occupants,
                    housingQuality = occupancy.housingQuality,
                    qualityTier = occupancy.qualityTier,
                    rent = occupancy.rentPerOccupant,
                    targetClasses = occupancy.targetClasses
                })
            end
        end
    end

    -- Sort by quality (highest first)
    table.sort(available, function(a, b)
        return a.housingQuality > b.housingQuality
    end)

    return available
end

function HousingSystem:GetHousingStatistics()
    local stats = {
        totalCapacity = 0,
        totalOccupied = 0,
        totalVacant = 0,
        homeless = 0,
        byQualityTier = {},
        occupancyRate = 0
    }

    for buildingId, occupancy in pairs(self.buildingOccupancy) do
        stats.totalCapacity = stats.totalCapacity + occupancy.capacity
        stats.totalOccupied = stats.totalOccupied + #occupancy.occupants

        local tier = occupancy.qualityTier or "basic"
        if not stats.byQualityTier[tier] then
            stats.byQualityTier[tier] = { capacity = 0, occupied = 0 }
        end
        stats.byQualityTier[tier].capacity = stats.byQualityTier[tier].capacity + occupancy.capacity
        stats.byQualityTier[tier].occupied = stats.byQualityTier[tier].occupied + #occupancy.occupants
    end

    stats.totalVacant = stats.totalCapacity - stats.totalOccupied

    -- Count homeless
    for characterId, assignment in pairs(self.housingAssignments) do
        if assignment.status == HOUSING_STATUS.HOMELESS then
            stats.homeless = stats.homeless + 1
        end
    end

    if stats.totalCapacity > 0 then
        stats.occupancyRate = stats.totalOccupied / stats.totalCapacity
    end

    return stats
end

-- ============================================================================
-- Relocation Queue
-- ============================================================================

function HousingSystem:AddToRelocationQueue(characterId, reason)
    -- Check if already in queue
    for _, entry in ipairs(self.relocationQueue) do
        if entry.characterId == characterId then
            return false
        end
    end

    table.insert(self.relocationQueue, {
        characterId = characterId,
        reason = reason or "seeking",
        addedCycle = 0,  -- Should be set by caller
        priority = self:CalculateRelocationPriority(characterId, reason)
    })

    local assignment = self.housingAssignments[characterId]
    if assignment then
        assignment.status = HOUSING_STATUS.SEEKING
    end

    return true
end

function HousingSystem:RemoveFromRelocationQueue(characterId)
    for i, entry in ipairs(self.relocationQueue) do
        if entry.characterId == characterId then
            table.remove(self.relocationQueue, i)
            return true
        end
    end
    return false
end

function HousingSystem:CalculateRelocationPriority(characterId, reason)
    -- Higher priority for evictions, lower for voluntary moves
    local basePriority = 50

    if reason == "evicted" or reason == "building_removed" then
        basePriority = 100
    elseif reason == "upgrade" then
        basePriority = 30
    elseif reason == "downgrade" then
        basePriority = 70
    end

    return basePriority
end

function HousingSystem:ProcessRelocationQueue(currentCycle)
    -- Sort by priority (highest first)
    table.sort(self.relocationQueue, function(a, b)
        return a.priority > b.priority
    end)

    local processed = {}

    for _, entry in ipairs(self.relocationQueue) do
        local characterId = entry.characterId

        -- Get character's class if economics system is available
        local targetClass = nil
        if self.economicsSystem then
            targetClass = self.economicsSystem:GetClass(characterId, currentCycle)
        end

        -- Find available housing
        local available = self:GetAvailableHousing(targetClass)

        if #available > 0 then
            -- Assign to best available
            local success = self:AssignHousing(characterId, available[1].buildingId)
            if success then
                table.insert(processed, characterId)
            end
        end
    end

    -- Report results
    if #processed > 0 then
        print(string.format("[HousingSystem] Processed relocation for %d characters", #processed))
    end

    return processed
end

-- ============================================================================
-- Housing Satisfaction (Integration with Craving System)
-- ============================================================================

function HousingSystem:GetHousingFulfillmentVector(characterId)
    local assignment = self.housingAssignments[characterId]
    if not assignment or assignment.status ~= HOUSING_STATUS.HOUSED then
        -- Homeless - no housing fulfillment
        return nil
    end

    local occupancy = self.buildingOccupancy[assignment.buildingId]
    if not occupancy then
        return nil
    end

    -- Look up building's fulfillment vector from building types
    local buildingType = self.buildingTypes[occupancy.buildingTypeId]
    if buildingType and buildingType.fulfillmentVector then
        return buildingType.fulfillmentVector
    end

    return nil
end

function HousingSystem:CalculateHousingSatisfaction(characterId)
    local assignment = self.housingAssignments[characterId]
    if not assignment or assignment.status ~= HOUSING_STATUS.HOUSED then
        return 0
    end

    -- Base satisfaction from housing quality
    return assignment.housingQuality or 0.5
end

function HousingSystem:ShouldSeekBetterHousing(characterId, currentCycle)
    local assignment = self.housingAssignments[characterId]
    if not assignment then
        return true, "homeless"
    end

    if assignment.status == HOUSING_STATUS.HOMELESS then
        return true, "homeless"
    end

    -- Check if current housing matches class
    if self.economicsSystem then
        local characterClass = self.economicsSystem:GetClass(characterId, currentCycle)
        local occupancy = self.buildingOccupancy[assignment.buildingId]

        if occupancy and #occupancy.targetClasses > 0 then
            local classMatch = false
            for _, tc in ipairs(occupancy.targetClasses) do
                if tc == characterClass then
                    classMatch = true
                    break
                end
            end

            if not classMatch then
                -- Check if character can afford better
                local available = self:GetAvailableHousing(characterClass)
                if #available > 0 and available[1].housingQuality > assignment.housingQuality then
                    return true, "class_mismatch"
                end
            end
        end
    end

    return false, nil
end

-- ============================================================================
-- Rent Processing
-- ============================================================================

function HousingSystem:ProcessRentPayments(currentCycle)
    local rentCollected = {}

    for characterId, assignment in pairs(self.housingAssignments) do
        if assignment.status == HOUSING_STATUS.HOUSED and assignment.rentAmount > 0 then
            local buildingId = assignment.buildingId

            -- Try to pay rent via economics system
            if self.economicsSystem then
                local success, result = self.economicsSystem:SpendGold(
                    characterId,
                    assignment.rentAmount,
                    "rent_" .. buildingId
                )

                if success then
                    table.insert(rentCollected, {
                        characterId = characterId,
                        buildingId = buildingId,
                        amount = assignment.rentAmount
                    })
                else
                    -- Can't pay rent - could trigger eviction
                    print(string.format("[HousingSystem] %s can't afford rent for %s",
                        characterId, buildingId))
                    -- For now, don't evict - just flag
                    assignment.rentOverdue = (assignment.rentOverdue or 0) + 1
                end
            end
        end
    end

    return rentCollected
end

-- ============================================================================
-- Housing Upgrades
-- ============================================================================

function HousingSystem:CanUpgradeBuilding(buildingId)
    local occupancy = self.buildingOccupancy[buildingId]
    if not occupancy or not occupancy.upgradeableTo then
        return false, "No upgrade path"
    end

    -- Check if upgrade target exists
    local upgradeType = self.buildingTypes[occupancy.upgradeableTo]
    if not upgradeType then
        return false, "Upgrade building type not found"
    end

    return true, occupancy.upgradeableTo
end

function HousingSystem:UpgradeBuilding(buildingId, newBuildingTypeId)
    local occupancy = self.buildingOccupancy[buildingId]
    if not occupancy then
        return false, "Building not registered"
    end

    local newType = self.buildingTypes[newBuildingTypeId]
    if not newType or not newType.housingConfig then
        return false, "Invalid upgrade target"
    end

    local newConfig = newType.housingConfig

    -- Store current occupants
    local currentOccupants = {}
    for _, occupantId in ipairs(occupancy.occupants) do
        table.insert(currentOccupants, occupantId)
    end

    -- Update building config
    occupancy.buildingTypeId = newBuildingTypeId
    occupancy.capacity = newConfig.capacity or occupancy.capacity
    occupancy.housingQuality = newConfig.housingQuality or occupancy.housingQuality
    occupancy.qualityTier = newConfig.qualityTier or occupancy.qualityTier
    occupancy.rentPerOccupant = newConfig.rentPerOccupant or occupancy.rentPerOccupant
    occupancy.targetClasses = newConfig.targetClasses or occupancy.targetClasses
    occupancy.upgradeableTo = newConfig.upgradeableTo

    -- Update assignments for current occupants
    for _, occupantId in ipairs(currentOccupants) do
        local assignment = self.housingAssignments[occupantId]
        if assignment then
            assignment.buildingTypeId = newBuildingTypeId
            assignment.housingQuality = occupancy.housingQuality
            assignment.qualityTier = occupancy.qualityTier
            assignment.rentAmount = occupancy.rentPerOccupant
        end
    end

    -- Check if over capacity after upgrade
    if #currentOccupants > occupancy.capacity then
        -- Evict excess occupants (lowest priority first)
        local toEvict = #currentOccupants - occupancy.capacity
        for i = 1, toEvict do
            local evictId = currentOccupants[#currentOccupants - i + 1]
            self:EvictCharacter(evictId, "capacity_reduced")
        end
    end

    print(string.format("[HousingSystem] Upgraded building %s to %s", buildingId, newBuildingTypeId))

    return true
end

-- ============================================================================
-- Serialization
-- ============================================================================

function HousingSystem:Serialize()
    return {
        housingAssignments = self.housingAssignments,
        buildingOccupancy = self.buildingOccupancy,
        relocationQueue = self.relocationQueue
    }
end

function HousingSystem:Deserialize(data)
    if not data then return end

    self.housingAssignments = data.housingAssignments or {}
    self.buildingOccupancy = data.buildingOccupancy or {}
    self.relocationQueue = data.relocationQueue or {}

    print("[HousingSystem] Deserialized housing data")
end

-- ============================================================================
-- Constants
-- ============================================================================

HousingSystem.HOUSING_STATUS = HOUSING_STATUS
HousingSystem.OCCUPANCY_TYPE = OCCUPANCY_TYPE
HousingSystem.RENT_STATUS = RENT_STATUS
HousingSystem.CROWDING_THRESHOLDS = CROWDING_THRESHOLDS

-- ============================================================================
-- Family Management
-- ============================================================================

function HousingSystem:RegisterFamilyUnit(headId, memberIds, familyId)
    familyId = familyId or ("family_" .. headId)

    self.familyUnits[familyId] = {
        headId = headId,
        memberIds = memberIds or {},
        housingNeeded = 1 + #(memberIds or {}),
        createdCycle = 0  -- Set by caller
    }

    print(string.format("[HousingSystem] Registered family unit %s with %d members",
        familyId, self.familyUnits[familyId].housingNeeded))

    return familyId
end

function HousingSystem:GetFamilyUnit(characterId)
    -- Check if character is head of a family
    for familyId, family in pairs(self.familyUnits) do
        if family.headId == characterId then
            return familyId, family
        end
        -- Check if character is a member
        for _, memberId in ipairs(family.memberIds) do
            if memberId == characterId then
                return familyId, family
            end
        end
    end
    return nil, nil
end

function HousingSystem:GetFamilySize(characterId)
    local familyId, family = self:GetFamilyUnit(characterId)
    if family then
        return family.housingNeeded
    end
    return 1  -- Single person
end

function HousingSystem:AssignFamilyToHousing(familyId, buildingId)
    local family = self.familyUnits[familyId]
    if not family then
        return false, "Family not found"
    end

    local occupancy = self.buildingOccupancy[buildingId]
    if not occupancy then
        return false, "Building is not registered housing"
    end

    local availableSlots = occupancy.capacity - #occupancy.occupants
    if availableSlots < family.housingNeeded then
        return false, "Not enough space for family"
    end

    -- Assign head of household
    local success, err = self:AssignHousing(family.headId, buildingId)
    if not success then
        return false, "Failed to assign head: " .. (err or "unknown")
    end

    -- Mark as family occupancy
    local headAssignment = self.housingAssignments[family.headId]
    if headAssignment then
        headAssignment.occupancyType = OCCUPANCY_TYPE.FAMILY
        headAssignment.familyId = familyId
        headAssignment.isHeadOfHousehold = true
    end

    -- Assign all family members
    for _, memberId in ipairs(family.memberIds) do
        success, err = self:AssignHousing(memberId, buildingId)
        if success then
            local memberAssignment = self.housingAssignments[memberId]
            if memberAssignment then
                memberAssignment.occupancyType = OCCUPANCY_TYPE.FAMILY
                memberAssignment.familyId = familyId
                memberAssignment.isHeadOfHousehold = false
            end
        else
            print(string.format("[HousingSystem] WARNING: Could not assign family member %s: %s",
                memberId, err or "unknown"))
        end
    end

    print(string.format("[HousingSystem] Assigned family %s (%d members) to %s",
        familyId, family.housingNeeded, buildingId))

    return true
end

-- ============================================================================
-- Roommate System
-- ============================================================================

function HousingSystem:CanBeRoommates(characterId1, characterId2)
    -- Check if both are singles (not in family units)
    local family1 = self:GetFamilyUnit(characterId1)
    local family2 = self:GetFamilyUnit(characterId2)

    if family1 or family2 then
        return false, "One or both characters are in family units"
    end

    -- Could add relationship/compatibility checks here
    -- For now, any two singles can be roommates
    return true
end

function HousingSystem:AssignAsRoommate(characterId, buildingId)
    local familyId = self:GetFamilyUnit(characterId)
    if familyId then
        return false, "Character is in a family unit - cannot assign as roommate"
    end

    local success, err = self:AssignHousing(characterId, buildingId)
    if not success then
        return false, err
    end

    local assignment = self.housingAssignments[characterId]
    if assignment then
        assignment.occupancyType = OCCUPANCY_TYPE.ROOMMATE
    end

    return true
end

function HousingSystem:GetRoommateCount(buildingId)
    local occupancy = self.buildingOccupancy[buildingId]
    if not occupancy then
        return 0
    end

    local count = 0
    for _, occupantId in ipairs(occupancy.occupants) do
        local assignment = self.housingAssignments[occupantId]
        if assignment and assignment.occupancyType == OCCUPANCY_TYPE.ROOMMATE then
            count = count + 1
        end
    end

    return count
end

-- ============================================================================
-- Crowding System
-- ============================================================================

function HousingSystem:GetCrowdingLevel(buildingId)
    local occupancy = self.buildingOccupancy[buildingId]
    if not occupancy or occupancy.capacity == 0 then
        return 0
    end

    return #occupancy.occupants / occupancy.capacity
end

function HousingSystem:GetCrowdingStatus(buildingId)
    local level = self:GetCrowdingLevel(buildingId)

    if level <= CROWDING_THRESHOLDS.COMFORTABLE then
        return "comfortable", level
    elseif level <= CROWDING_THRESHOLDS.NORMAL then
        return "normal", level
    elseif level <= CROWDING_THRESHOLDS.CROWDED then
        return "crowded", level
    else
        return "overcrowded", level
    end
end

function HousingSystem:GetCrowdingSatisfactionModifier(buildingId)
    local status = self:GetCrowdingStatus(buildingId)
    return self.config.crowdingSatisfactionPenalty[status] or 0
end

function HousingSystem:CanAddOccupant(buildingId, characterId)
    local occupancy = self.buildingOccupancy[buildingId]
    if not occupancy then
        return false, "Building not registered as housing"
    end

    local currentOccupants = #occupancy.occupants
    local familySize = self:GetFamilySize(characterId)
    local newTotal = currentOccupants + familySize

    if newTotal > occupancy.capacity then
        if self.config.allowOvercrowding and newTotal <= occupancy.capacity * CROWDING_THRESHOLDS.OVERCROWDED then
            return true, "overcrowded"  -- Allow but warn
        end
        return false, "Would exceed capacity"
    end

    return true
end

-- ============================================================================
-- Enhanced Rent System
-- ============================================================================

function HousingSystem:CalculateTotalRent(characterId)
    local assignment = self.housingAssignments[characterId]
    if not assignment or assignment.status ~= HOUSING_STATUS.HOUSED then
        return 0
    end

    local housingRent = assignment.rentAmount or 0
    local landRent = 0

    -- Add land rent if enabled
    if self.config.landRentEnabled and self.landSystem then
        local buildingId = assignment.buildingId
        local buildingLandRent = self.landSystem:GetBuildingLandRent(buildingId)
        if buildingLandRent then
            -- Divide land rent among occupants
            local occupancy = self.buildingOccupancy[buildingId]
            if occupancy and #occupancy.occupants > 0 then
                landRent = buildingLandRent / #occupancy.occupants
            end
        end
    end

    return housingRent + landRent
end

function HousingSystem:ProcessRentWithEviction(currentCycle)
    local results = {
        collected = {},
        overdue = {},
        evicted = {},
        totalCollected = 0
    }

    for characterId, assignment in pairs(self.housingAssignments) do
        if assignment.status == HOUSING_STATUS.HOUSED then
            local rentAmount = self:CalculateTotalRent(characterId)

            if rentAmount > 0 and self.economicsSystem then
                local success = self.economicsSystem:SpendGold(
                    characterId,
                    rentAmount,
                    "rent_" .. assignment.buildingId
                )

                if success then
                    -- Rent paid successfully
                    table.insert(results.collected, {
                        characterId = characterId,
                        amount = rentAmount
                    })
                    results.totalCollected = results.totalCollected + rentAmount

                    -- Clear any overdue warnings
                    assignment.rentOverdue = 0
                    self.evictionWarnings[characterId] = nil
                else
                    -- Failed to pay rent
                    assignment.rentOverdue = (assignment.rentOverdue or 0) + 1

                    table.insert(results.overdue, {
                        characterId = characterId,
                        cyclesOverdue = assignment.rentOverdue,
                        amount = rentAmount
                    })

                    -- Check for eviction
                    if assignment.rentOverdue >= self.config.maxRentOverdueCycles then
                        -- Issue eviction warning first
                        if not self.evictionWarnings[characterId] then
                            self.evictionWarnings[characterId] = {
                                cyclesOverdue = assignment.rentOverdue,
                                warningCycle = currentCycle
                            }
                            print(string.format("[HousingSystem] Eviction warning issued to %s", characterId))
                        elseif currentCycle >= self.evictionWarnings[characterId].warningCycle + self.config.evictionGracePeriod then
                            -- Grace period expired - evict
                            self:EvictCharacter(characterId, "rent_nonpayment")
                            table.insert(results.evicted, characterId)
                        end
                    end
                end
            end
        end
    end

    if #results.evicted > 0 then
        print(string.format("[HousingSystem] Evicted %d characters for non-payment", #results.evicted))
    end

    return results
end

function HousingSystem:CanAffordHousing(characterId, buildingId)
    local occupancy = self.buildingOccupancy[buildingId]
    if not occupancy then
        return false, "Building not registered"
    end

    if not self.economicsSystem then
        return true  -- No economics system, assume affordable
    end

    local rentAmount = occupancy.rentPerOccupant
    local citizenIncome = self.economicsSystem:GetCitizenIncome(characterId)

    -- Rent should be at most ~50% of income to be affordable
    local maxAffordableRent = citizenIncome * 0.5

    if rentAmount <= maxAffordableRent then
        return true, "affordable"
    elseif rentAmount <= citizenIncome then
        return true, "stretched"  -- Can afford but tight
    else
        return false, "unaffordable"
    end
end

-- ============================================================================
-- Immigration Gating
-- ============================================================================

function HousingSystem:CanAcceptImmigrant(immigrantClass, familySize)
    familySize = familySize or 1

    -- Find housing suitable for this class with enough space
    local available = self:GetAvailableHousing(immigrantClass)

    for _, housing in ipairs(available) do
        if housing.availableSlots >= familySize then
            return true, housing.buildingId
        end
    end

    return false, nil
end

function HousingSystem:ReserveHousingForImmigrant(buildingId, immigrantId, familySize)
    local occupancy = self.buildingOccupancy[buildingId]
    if not occupancy then
        return false, "Building not found"
    end

    -- Check availability
    if occupancy.capacity - #occupancy.occupants < familySize then
        return false, "Not enough space"
    end

    -- Create a pending assignment
    self.housingAssignments[immigrantId] = {
        buildingId = buildingId,
        buildingTypeId = occupancy.buildingTypeId,
        status = HOUSING_STATUS.SEEKING,  -- Will become HOUSED on arrival
        reservedCycle = 0,  -- Set by caller
        housingQuality = occupancy.housingQuality,
        qualityTier = occupancy.qualityTier,
        rentAmount = occupancy.rentPerOccupant,
        isReservation = true
    }

    print(string.format("[HousingSystem] Reserved housing %s for immigrant %s", buildingId, immigrantId))

    return true
end

function HousingSystem:ConfirmImmigrantArrival(immigrantId)
    local assignment = self.housingAssignments[immigrantId]
    if not assignment or not assignment.isReservation then
        return false, "No reservation found"
    end

    -- Convert reservation to actual assignment
    local buildingId = assignment.buildingId
    local occupancy = self.buildingOccupancy[buildingId]

    if occupancy then
        table.insert(occupancy.occupants, immigrantId)
    end

    assignment.status = HOUSING_STATUS.HOUSED
    assignment.isReservation = nil
    assignment.arrivalCycle = 0  -- Set by caller

    print(string.format("[HousingSystem] Confirmed immigrant %s arrival at %s", immigrantId, buildingId))

    return true
end

-- ============================================================================
-- Housing Satisfaction with Fulfillment Vectors
-- ============================================================================

function HousingSystem:ApplyHousingFulfillment(characterId, character, currentCycle)
    local assignment = self.housingAssignments[characterId]
    if not assignment or assignment.status ~= HOUSING_STATUS.HOUSED then
        -- Homeless - no fulfillment, apply penalty
        return {
            applied = false,
            reason = "homeless",
            penalty = -50  -- Significant penalty for being homeless
        }
    end

    local buildingId = assignment.buildingId
    local occupancy = self.buildingOccupancy[buildingId]
    if not occupancy then
        return { applied = false, reason = "building_not_found" }
    end

    -- Get building fulfillment vector
    local fulfillmentVector = self:GetHousingFulfillmentVector(characterId)
    if not fulfillmentVector then
        return { applied = false, reason = "no_fulfillment_vector" }
    end

    -- Apply crowding modifier
    local crowdingModifier = 1.0
    local crowdingStatus = self:GetCrowdingStatus(buildingId)
    if crowdingStatus == "comfortable" then
        crowdingModifier = 1.1  -- Bonus for spacious
    elseif crowdingStatus == "crowded" then
        crowdingModifier = 0.95
    elseif crowdingStatus == "overcrowded" then
        crowdingModifier = 0.75
    end

    -- Calculate effective fulfillment based on character's enabled dimensions
    local effectiveFulfillment = {}
    local totalFulfillment = 0

    if fulfillmentVector.fine then
        for dimension, value in pairs(fulfillmentVector.fine) do
            -- Check if this dimension is enabled for the character's class
            local isEnabled = self:IsDimensionEnabled(character, dimension)
            if isEnabled then
                local modifiedValue = value * crowdingModifier
                effectiveFulfillment[dimension] = modifiedValue
                totalFulfillment = totalFulfillment + modifiedValue
            end
        end
    end

    return {
        applied = true,
        buildingId = buildingId,
        buildingType = occupancy.buildingTypeId,
        fulfillment = effectiveFulfillment,
        totalFulfillment = totalFulfillment,
        crowdingModifier = crowdingModifier,
        crowdingStatus = crowdingStatus
    }
end

function HousingSystem:IsDimensionEnabled(character, dimensionId)
    -- Check if this housing dimension is enabled for the character
    -- This depends on their emergent class
    if not character then return false end

    -- Basic housing is always enabled
    if dimensionId == "safety_shelter_housing_basic" or
       dimensionId == "safety_shelter_weather" or
       dimensionId == "safety_shelter_warmth" then
        return true
    end

    -- Get character's effective class
    local characterClass = "lower"
    if character.GetEffectiveClass then
        characterClass = character:GetEffectiveClass()
    elseif character.class then
        characterClass = character.class
    end

    -- Class-based dimension enablement
    local classOrder = { lower = 1, middle = 2, upper = 3, elite = 4 }
    local charClassOrder = classOrder[characterClass] or 1

    if dimensionId == "safety_shelter_housing_good" then
        return charClassOrder >= 2  -- Middle+
    elseif dimensionId == "safety_shelter_housing_luxury" then
        return charClassOrder >= 3  -- Upper+
    elseif dimensionId == "safety_shelter_housing_prestige" then
        return charClassOrder >= 4  -- Elite only
    end

    -- Other dimensions (furniture, etc.) - enabled for all
    return true
end

-- ============================================================================
-- Relocation Desire System
-- ============================================================================

function HousingSystem:CheckRelocationDesires(currentCycle)
    local relocationDesires = {}

    for characterId, assignment in pairs(self.housingAssignments) do
        if assignment.status == HOUSING_STATUS.HOUSED then
            local desire, reason = self:ShouldSeekBetterHousing(characterId, currentCycle)

            if desire then
                -- Check if already in relocation queue
                local alreadyInQueue = false
                for _, entry in ipairs(self.relocationQueue) do
                    if entry.characterId == characterId then
                        alreadyInQueue = true
                        break
                    end
                end

                if not alreadyInQueue then
                    table.insert(relocationDesires, {
                        characterId = characterId,
                        currentBuildingId = assignment.buildingId,
                        reason = reason
                    })
                end
            end
        end
    end

    -- Add to relocation queue
    for _, desire in ipairs(relocationDesires) do
        self:AddToRelocationQueue(desire.characterId, desire.reason)
    end

    return relocationDesires
end

-- ============================================================================
-- Extended Serialization
-- ============================================================================

function HousingSystem:Serialize()
    return {
        housingAssignments = self.housingAssignments,
        buildingOccupancy = self.buildingOccupancy,
        familyUnits = self.familyUnits,
        relocationQueue = self.relocationQueue,
        evictionWarnings = self.evictionWarnings,
        config = self.config
    }
end

function HousingSystem:Deserialize(data)
    if not data then return end

    self.housingAssignments = data.housingAssignments or {}
    self.buildingOccupancy = data.buildingOccupancy or {}
    self.familyUnits = data.familyUnits or {}
    self.relocationQueue = data.relocationQueue or {}
    self.evictionWarnings = data.evictionWarnings or {}

    if data.config then
        -- Merge with defaults to handle new config options
        for k, v in pairs(data.config) do
            self.config[k] = v
        end
    end

    print("[HousingSystem] Deserialized housing data with family tracking")
end

return HousingSystem
