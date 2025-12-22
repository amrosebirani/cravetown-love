--
-- AlphaWorld.lua
-- Integrated world system combining production and consumption
-- Birthday Edition for Mansi
--

local CharacterV3 = require("code.consumption.CharacterV3")
local AllocationEngineV2 = require("code.consumption.AllocationEngineV2")
local CommodityCache = require("code.consumption.CommodityCache")
-- TownConsequences not used in alpha (no emigration/riots/protests)
local DataLoader = require("code.DataLoader")
local TimeManager = require("code.TimeManager")
local NaturalResources = require("code.NaturalResources")
local ImmigrationSystem = require("code.ImmigrationSystem")
local River = require("code.River")
local Forest = require("code.Forest")
local Mountain = require("code.Mountain")
local ProductionStats = require("code.ProductionStats")
local WorldZones = require("code.WorldZones")

-- Ownership & Housing Systems
local LandSystem = require("code.LandSystem")
local OwnershipManager = require("code.OwnershipManager")
local EconomicsSystem = require("code.EconomicsSystem")
local HousingSystem = require("code.HousingSystem")

AlphaWorld = {}
AlphaWorld.__index = AlphaWorld

function AlphaWorld:Create(terrainConfig, progressCallback)
    local world = setmetatable({}, AlphaWorld)

    -- Progress reporting helper
    local function reportProgress(progress, message)
        if progressCallback then
            progressCallback(progress, message)
        end
    end

    -- Store terrain config for later use
    world.terrainConfig = terrainConfig

    -- Load all game data
    reportProgress(0.0, "Loading game data...")
    world:LoadData()

    -- Initialize consumption subsystems
    reportProgress(0.1, "Initializing character system...")
    CharacterV3.Init(
        world.consumptionMechanics,
        world.fulfillmentVectors,
        world.characterTraits,
        world.characterClasses,
        world.dimensionDefinitions,
        world.commodityFatigueRates,
        world.enablementRules,
        world.classThresholds  -- Phase 3: for emergent class calculation
    )
    -- Initialize delayed reaction satisfaction system with default difficulty
    CharacterV3.SetDifficultySettings("normal")
    reportProgress(0.15, "Initializing commodity cache...")
    CommodityCache.Init(world.fulfillmentVectors, world.dimensionDefinitions, world.substitutionRules, CharacterV3)
    reportProgress(0.2, "Initializing allocation engine...")
    AllocationEngineV2.Init(world.consumptionMechanics, world.fulfillmentVectors, world.substitutionRules, CharacterV3, CommodityCache)
    -- Alpha: No consequences system (no emigration/riots/protests)

    -- Town state
    world.townName = "Cravetown"
    world.gameTime = 0

    -- Time Manager - centralized time handling
    world.timeManager = TimeManager:Create()

    -- Set up time manager callbacks
    world.timeManager.onSlotChange = function(slotIndex, slot)
        world:OnSlotChange(slotIndex, slot)
    end
    world.timeManager.onDayChange = function(dayNumber)
        world:OnDayChange(dayNumber)
    end

    -- Backward compatibility properties (delegate to TimeManager)
    world.isPaused = true
    world.timeManager:Pause()

    -- Global slot counter for fatigue tracking (starts at 1)
    world.globalSlotCounter = 1
    CharacterV3.SetCurrentGlobalSlot(1)

    -- Citizens (using CharacterV3)
    world.citizens = {}
    world.nextCitizenId = 1

    -- Buildings
    world.buildings = {}
    world.nextBuildingId = 1

    -- Town inventory (shared resources)
    world.inventory = {}

    -- Production tracking
    world.productionQueue = {}

    -- Gold/Treasury
    world.gold = 1000

    -- Statistics
    world.stats = {
        totalPopulation = 0,
        averageSatisfaction = 0,
        satisfactionByClass = {},
        totalEmigrations = 0,
        totalImmigrations = 0,
        totalRiots = 0,
        productivityMultiplier = 1.0,
        currentSlotName = "Morning",
        housingCapacity = 0,
        employedCount = 0,
        unemployedCount = 0
    }

    -- Production statistics tracking
    world.productionStats = ProductionStats.new()
    world.productionStatsTick = 0

    -- Event log
    world.eventLog = {}
    world.maxEvents = 100

    -- Selection state (for UI)
    world.selectedEntity = nil  -- Can be citizen or building
    world.selectedEntityType = nil  -- "citizen" or "building"

    -- Immigration system
    world.immigrationSystem = ImmigrationSystem:Create(world)

    -- World boundaries (larger world for more exploration)
    world.worldWidth = 3200
    world.worldHeight = 2400

    -- Natural resources for building efficiency (using full NaturalResources system)
    world.naturalResources = NaturalResources:Create({
        minX = 0,
        maxX = world.worldWidth,
        minY = 0,
        maxY = world.worldHeight,
        river = nil,  -- River will be set after creation
        cellSize = 20,
        seed = os.time()
    })

    local tc = terrainConfig or {}  -- terrain config shorthand
    local halfW = world.worldWidth / 2
    local halfH = world.worldHeight / 2

    -- ==========================================================================
    -- ZONE-BASED WORLD GENERATION
    -- First create WorldZones to define where each terrain type should go
    -- ==========================================================================
    reportProgress(0.3, "Planning world zones...")

    -- Build location config for WorldZones
    local locationConfig = {
        riverPosition = tc.riverPosition or "east",
        riverWidth = tc.riverWidth or 200,
        mountainPosition = tc.mountainPosition or "none",
        mountainDepth = tc.mountainDepth or 300,
        forestCoverage = tc.forestDensity or 0.25
    }

    -- Disable river in zones if not enabled
    if tc.riverEnabled == false then
        locationConfig.riverPosition = "none"
    end

    -- Disable mountains in zones if not enabled
    if not tc.mountainsEnabled then
        locationConfig.mountainPosition = "none"
    elseif tc.mountainPositions and #tc.mountainPositions > 0 then
        -- Use first mountain position from config
        locationConfig.mountainPosition = tc.mountainPositions[1] or "north"
    end

    -- Create world zones
    world.worldZones = WorldZones:Create(world.worldWidth, world.worldHeight, locationConfig)

    -- ==========================================================================
    -- Create river based on zone definition
    -- ==========================================================================
    reportProgress(0.4, "Generating river...")

    local riverZone = world.worldZones:GetRiverZone()
    if riverZone then
        -- Calculate river center from zone
        local riverCenterX = (riverZone.x + riverZone.width / 2) - halfW
        local riverWidth = tc.riverWidth or 80

        world.river = River:Create({
            startY = -halfH - 50,
            endY = halfH + 50,
            centerX = riverCenterX,
            baseWidth = riverWidth,
            curviness = 120,
            widthVariation = 0.3
        })
    else
        world.river = nil
    end

    -- ==========================================================================
    -- Create forest within designated forest zones
    -- ==========================================================================
    reportProgress(0.5, "Growing forests...")

    local forestZones = world.worldZones:GetForestZones()
    world.forest = Forest:Create({
        minX = 0,
        minY = 0,
        maxX = world.worldWidth,
        maxY = world.worldHeight,
        river = world.river,
        zones = forestZones  -- Pass zone boundaries instead of numRegions
    })

    -- ==========================================================================
    -- Create mountains within designated mountain zones
    -- ==========================================================================
    reportProgress(0.6, "Raising mountains...")

    world.mountains = nil
    local mountainZones = world.worldZones:GetMountainZones()
    if mountainZones and #mountainZones > 0 then
        -- Convert zone positions to mountain positions for backward compatibility
        local mountainPositions = {}
        for _, mz in ipairs(mountainZones) do
            -- Determine position based on zone location
            if mz.y < halfH / 2 then
                table.insert(mountainPositions, "north")
            elseif mz.y > halfH * 1.5 then
                table.insert(mountainPositions, "south")
            elseif mz.x < halfW / 2 then
                table.insert(mountainPositions, "west")
            else
                table.insert(mountainPositions, "east")
            end
        end

        if #mountainPositions > 0 then
            world.mountains = Mountain.CreateTerrain({
                minX = 0,
                minY = 0,
                maxX = world.worldWidth,
                maxY = world.worldHeight,
                positions = mountainPositions
            })
            print("[AlphaWorld] Created mountains: " .. world.mountains:GetRangeCount() .. " ranges")
        end
    end

    -- Store ground and water colors from terrain config
    world.groundColor = tc.groundColor or {0.4, 0.5, 0.3}
    world.waterColor = tc.waterColor or {0.2, 0.4, 0.7}

    -- Now set the river reference and generate resources
    reportProgress(0.7, "Generating natural resources...")
    world.naturalResources.mRiver = world.river
    world.naturalResources:generateAll()

    -- Post-process resources to mask out water and forest areas
    reportProgress(0.75, "Processing terrain...")
    world:MaskResourcesInBlockedAreas()

    -- ==========================================================================
    -- OWNERSHIP & HOUSING SYSTEMS
    -- ==========================================================================
    reportProgress(0.8, "Setting up land system...")

    -- Land System - manages plot grid and ownership
    world.landSystem = LandSystem:Create({
        worldWidth = world.worldWidth,
        worldHeight = world.worldHeight
    })

    -- Mark blocked terrain in land system (water, mountains)
    reportProgress(0.85, "Marking terrain plots...")
    world:InitializeLandTerrain()

    -- Ownership Manager - tracks building/land ownership
    reportProgress(0.9, "Initializing ownership system...")
    world.ownershipManager = OwnershipManager:Create(world.landSystem, nil)

    -- Economics System - per-character finances and emergent class
    reportProgress(0.93, "Setting up economics...")
    world.economicsSystem = EconomicsSystem:Create(world.ownershipManager)

    -- Housing System - housing assignment and satisfaction
    reportProgress(0.97, "Configuring housing system...")
    world.housingSystem = HousingSystem:Create(nil, world.economicsSystem, nil)

    reportProgress(1.0, "World ready!")
    return world
end

-- Initialize land terrain based on water, mountains, and forests
function AlphaWorld:InitializeLandTerrain()
    if not self.landSystem then return end

    local gridColumns = self.landSystem.gridColumns
    local gridRows = self.landSystem.gridRows
    local plotWidth = self.landSystem.plotWidth
    local plotHeight = self.landSystem.plotHeight

    for gx = 0, gridColumns - 1 do
        for gy = 0, gridRows - 1 do
            local plotId = self.landSystem:GetPlotId(gx, gy)
            local worldX = gx * plotWidth + plotWidth / 2
            local worldY = gy * plotHeight + plotHeight / 2

            -- Check if plot is in water
            if self:IsPositionInWater(worldX, worldY) then
                self.landSystem:SetPlotTerrain(plotId, "water", true)
            -- Check if plot is in mountains
            elseif self.mountains and self.mountains:CheckRectCollision(
                gx * plotWidth, gy * plotHeight, plotWidth, plotHeight
            ) then
                self.landSystem:SetPlotTerrain(plotId, "mountain", true)
            -- Check if plot is in forest
            elseif self.forest and self.forest:CheckRectCollision(
                gx * plotWidth, gy * plotHeight, plotWidth, plotHeight
            ) then
                self.landSystem:SetPlotTerrain(plotId, "forest", false)
                -- Set natural resources for forest plots
                self.landSystem:SetPlotResources(plotId, {"timber"})
            end
        end
    end

    print("[AlphaWorld] Initialized land terrain for " .. gridColumns * gridRows .. " plots")
end

-- Mask out resources in areas covered by water or forest
function AlphaWorld:MaskResourcesInBlockedAreas()
    if not self.naturalResources then return end

    local nr = self.naturalResources
    local gridWidth, gridHeight, cellSize = nr:getGridDimensions()
    local minX, maxX, minY, maxY = nr:getBoundaries()

    local resourceIds = nr:getAllResourceIds()

    for _, resourceId in ipairs(resourceIds) do
        local gridData = nr:getGridData(resourceId)
        if gridData then
            for gx = 1, gridWidth do
                for gy = 1, gridHeight do
                    -- Get world position for this cell
                    local worldX = minX + (gx - 0.5) * cellSize
                    local worldY = minY + (gy - 0.5) * cellSize

                    -- Check if this position is in water
                    local inWater = self:IsPositionInWater(worldX, worldY)

                    -- Check if this position is in forest
                    local inForest = false
                    if self.forest then
                        inForest = self.forest:CheckRectCollision(
                            worldX - cellSize/2,
                            worldY - cellSize/2,
                            cellSize,
                            cellSize
                        )
                    end

                    -- Zero out resources in blocked areas
                    if inWater or inForest then
                        gridData[gx][gy] = 0
                    end
                end
            end
        end
    end

    print("[AlphaWorld] Masked resources in water and forest areas")
end

function AlphaWorld:LoadData()
    -- Consumption data
    self.consumptionMechanics = DataLoader.loadConsumptionMechanics()
    self.fulfillmentVectors = DataLoader.loadFulfillmentVectors()
    self.characterTraits = DataLoader.loadCharacterTraits()
    self.characterClasses = DataLoader.loadCharacterClasses()
    self.dimensionDefinitions = DataLoader.loadDimensionDefinitions()
    self.commodityFatigueRates = DataLoader.loadCommodityFatigueRates()
    self.enablementRules = DataLoader.loadEnablementRules()
    self.substitutionRules = DataLoader.loadSubstitutionRules()

    -- Economics data (Phase 3)
    self.classThresholds = DataLoader.loadClassThresholds()
    self.economicSystemsConfig = DataLoader.loadEconomicSystems()
    self.landConfig = DataLoader.loadLandConfig()

    -- Production data
    self.buildingTypes = DataLoader.loadBuildingTypes() or {}
    self.buildingTypesById = {}
    for _, bt in ipairs(self.buildingTypes) do
        self.buildingTypesById[bt.id] = bt
    end

    self.buildingRecipes = DataLoader.loadBuildingRecipes() or {}
    self.recipesById = {}
    for _, recipe in ipairs(self.buildingRecipes) do
        -- Use buildingType as the key (recipes don't have id field)
        local key = recipe.id or recipe.buildingType
        if key then
            self.recipesById[key] = recipe
        end
    end

    self.commodities = DataLoader.loadCommodities() or {}
    self.commoditiesById = {}
    for _, c in ipairs(self.commodities) do
        self.commoditiesById[c.id] = c
    end

    -- Load commodity categories from data
    self.commodityCategories = DataLoader.loadCommodityCategories() or {}
    self.commodityCategoriesById = {}
    for _, cat in ipairs(self.commodityCategories) do
        self.commodityCategoriesById[cat.id] = cat
    end

    self.workerTypes = DataLoader.loadWorkerTypes() or {}

    -- Build vocation-to-workCategories lookup (matches vocation name to work categories)
    self.vocationWorkCategories = {}
    for _, wt in ipairs(self.workerTypes) do
        -- Use the name (e.g., "Farmer") as the key since that's what citizens have
        self.vocationWorkCategories[wt.name] = wt.workCategories or {}
        -- Also add lowercase version for case-insensitive matching
        self.vocationWorkCategories[wt.name:lower()] = wt.workCategories or {}
    end

    -- Time slots - load via DataLoader
    local timeSlots = DataLoader.loadTimeSlots()
    if timeSlots and #timeSlots > 0 then
        self.timeSlots = timeSlots
    else
        -- Fallback: load directly from path if DataLoader method fails
        local success, data = pcall(function()
            return DataLoader.loadJSON("data/" .. DataLoader.activeVersion .. "/time_slots.json")
        end)
        if success and data and data.slots then
            self.timeSlots = data.slots
        else
            print("  WARNING: Could not load time slots, using minimal defaults")
            self.timeSlots = {
                {id = "morning", name = "Morning", startHour = 6, endHour = 12, color = {1.0, 0.95, 0.7}},
                {id = "afternoon", name = "Afternoon", startHour = 12, endHour = 18, color = {1.0, 1.0, 0.85}},
                {id = "evening", name = "Evening", startHour = 18, endHour = 22, color = {1.0, 0.75, 0.5}},
                {id = "night", name = "Night", startHour = 22, endHour = 6, color = {0.2, 0.2, 0.4}}
            }
        end
    end

    -- Build slot lookup by ID
    self.timeSlotsById = {}
    for i, slot in ipairs(self.timeSlots) do
        self.timeSlotsById[slot.id] = slot
        slot.index = i
    end

    -- Craving-to-slot mappings via DataLoader
    self.cravingSlots = DataLoader.loadCravingSlots()

    -- Build slot-to-cravings index for quick lookup during allocation
    self.slotToCravings = {}
    for _, slot in ipairs(self.timeSlots) do
        self.slotToCravings[slot.id] = {}
    end
    if self.cravingSlots.mappings then
        for cravingId, mapping in pairs(self.cravingSlots.mappings) do
            for _, slotId in ipairs(mapping.slots or {}) do
                if self.slotToCravings[slotId] then
                    table.insert(self.slotToCravings[slotId], cravingId)
                end
            end
        end
    end

    print("AlphaWorld loaded: " .. #self.buildingTypes .. " building types, " ..
          #self.commodities .. " commodities, " .. #self.timeSlots .. " time slots")

    -- Log slot-craving mappings
    for slotId, cravings in pairs(self.slotToCravings) do
        print("  Slot " .. slotId .. ": " .. #cravings .. " active cravings")
    end
end

-- =============================================================================
-- TIME & SPEED CONTROL (delegates to TimeManager)
-- =============================================================================

function AlphaWorld:SetTimeScale(scale)
    self.timeManager:SetSpeed(scale)
end

function AlphaWorld:TogglePause()
    self.isPaused = self.timeManager:TogglePause()
    return self.isPaused
end

function AlphaWorld:Pause()
    self.timeManager:Pause()
    self.isPaused = true
end

function AlphaWorld:Resume()
    self.timeManager:Resume()
    self.isPaused = false
end

function AlphaWorld:GetCurrentHour()
    return self.timeManager:GetHour()
end

function AlphaWorld:GetTimeString()
    return self.timeManager:GetTimeString()
end

function AlphaWorld:GetDayNightColor()
    return self.timeManager:GetDayNightColor()
end

-- Get cravings active in current slot
function AlphaWorld:GetActiveCravingsForSlot()
    local slotId = self.timeManager:GetCurrentSlotId()
    return self.slotToCravings[slotId] or {}
end

-- Callback when slot changes
function AlphaWorld:OnSlotChange(slotIndex, slot)
    self.stats.currentSlotName = slot and slot.name or "Unknown"
    self:LogEvent("slot", slot.name .. " begins", {slotId = slot.id})

    -- Update global slot counter for fatigue tracking
    -- Global slot = (day - 1) * slotsPerDay + slotIndex
    local slotsPerDay = self.timeManager:GetSlotCount()
    local dayNumber = self.timeManager:GetDay()
    self.globalSlotCounter = ((dayNumber - 1) * slotsPerDay) + slotIndex
    CharacterV3.SetCurrentGlobalSlot(self.globalSlotCounter)

    -- Apply durable goods effects (slot-aware)
    local currentSlotId = slot and slot.id or "unknown"
    local durableSlots = self.cravingSlots.durableSlots and self.cravingSlots.durableSlots.categorySlots or {}
    for _, citizen in ipairs(self.citizens) do
        citizen:ApplyActiveEffectsSatisfaction(currentSlotId, durableSlots)
    end

    -- Process consumption for this slot
    self:ProcessSlotConsumption()

    -- Update statistics
    self:UpdateStats()
end

-- Callback when day changes
function AlphaWorld:OnDayChange(dayNumber)
    self:LogEvent("day", "Day " .. dayNumber .. " begins", {})

    -- Update immigration system
    if self.immigrationSystem then
        self.immigrationSystem:Update(dayNumber)
    end

    -- Run free agency - citizens seek best workplaces daily
    self:RunFreeAgency()

    -- Apply housing satisfaction (once per day)
    self:ApplyHousingSatisfaction(dayNumber)

    -- Process delayed reaction satisfaction system (streak-based, once per day)
    self:ProcessDelayedReactionSatisfaction(dayNumber)

    -- Process economic updates
    self:ProcessDailyEconomics(dayNumber)
end

-- Apply housing fulfillment to all citizens once per day
function AlphaWorld:ApplyHousingSatisfaction(dayNumber)
    if not self.housingSystem then
        return
    end

    local homelessCount = 0
    local housedCount = 0

    for _, citizen in ipairs(self.citizens) do
        local result = self.housingSystem:ApplyHousingFulfillment(citizen.id, citizen, dayNumber)

        if result.applied then
            housedCount = housedCount + 1
            -- Apply the housing fulfillment to the citizen's satisfaction
            -- The fulfillment vector is already calculated and filtered by enabled dimensions
            if result.fulfillment and citizen.ApplyHousingFulfillment then
                citizen:ApplyHousingFulfillment(result.fulfillment, result.crowdingModifier)
            end
        else
            homelessCount = homelessCount + 1
            -- Apply homeless penalty
            if result.penalty and citizen.ApplyHomelessPenalty then
                citizen:ApplyHomelessPenalty(result.penalty)
            end
        end
    end

    -- Update housing stats
    self.stats.homelessCount = homelessCount
    self.stats.housedCount = housedCount

    if homelessCount > 0 then
        self:LogEvent("housing", homelessCount .. " homeless citizens suffering", {
            severity = "warning"
        })
    end
end

-- Process delayed reaction satisfaction system for all citizens (once per day)
-- This implements the streak-based satisfaction system where satisfaction only
-- changes after N buffer days of consistently met/unmet cravings
function AlphaWorld:ProcessDelayedReactionSatisfaction(dayNumber)
    local criticalCount = 0
    local totalProcessed = 0

    for _, citizen in ipairs(self.citizens) do
        -- Check if citizen has the ProcessEndOfDay method (CharacterV3)
        if citizen.ProcessEndOfDay then
            local processed = citizen:ProcessEndOfDay(dayNumber)
            if processed then
                totalProcessed = totalProcessed + 1

                -- Track citizens with critical unmet streaks
                if citizen.GetCriticalStreaks then
                    local criticalStreaks = citizen:GetCriticalStreaks()
                    if #criticalStreaks > 0 then
                        criticalCount = criticalCount + 1
                    end
                end
            end
        end
    end

    -- Log if there are citizens with critical needs
    if criticalCount > 0 then
        self:LogEvent("satisfaction", criticalCount .. " citizens have critical unmet needs", {
            severity = "warning"
        })
    end
end

-- Process daily economic activities
function AlphaWorld:ProcessDailyEconomics(dayNumber)
    -- Start new economic cycle
    if self.economicsSystem then
        self.economicsSystem:StartNewCycle()
    end

    -- Process daily wage payments for all working citizens
    self:ProcessWagePayments(dayNumber)

    -- Process rent payments every 15 days (rent cycle)
    local rentCycleInterval = 15
    if self.housingSystem and dayNumber % rentCycleInterval == 0 then
        -- Use enhanced rent processing with eviction handling
        local rentResults = self.housingSystem:ProcessRentWithEviction(dayNumber)
        if #rentResults.collected > 0 then
            self:LogEvent("economics", #rentResults.collected .. " rent payments processed (" ..
                math.floor(rentResults.totalCollected) .. " gold)", {})
        end
        if #rentResults.overdue > 0 then
            self:LogEvent("economics", #rentResults.overdue .. " citizens behind on rent", {
                severity = "warning"
            })
        end
        if #rentResults.evicted > 0 then
            self:LogEvent("housing", #rentResults.evicted .. " citizens evicted for non-payment", {
                severity = "critical"
            })
        end
    end

    -- Process relocation queue daily (homeless citizens seeking housing)
    if self.housingSystem then
        local relocated = self.housingSystem:ProcessRelocationQueue(dayNumber)
        if #relocated > 0 then
            self:LogEvent("housing", #relocated .. " citizens found new housing", {})
        end

        -- Check for citizens wanting to relocate (class changes, upgrades)
        local relocationDesires = self.housingSystem:CheckRelocationDesires(dayNumber)
        if #relocationDesires > 0 then
            self:LogEvent("housing", #relocationDesires .. " citizens seeking better housing", {})
        end
    end

    -- Recalculate emergent classes every 15 days (same as rent cycle)
    if self.economicsSystem and dayNumber % rentCycleInterval == 0 then
        for _, citizen in ipairs(self.citizens) do
            local newClass = self.economicsSystem:GetClass(citizen.id, dayNumber)
            -- Update citizen's class if it changed
            if newClass ~= citizen.class then
                local oldClass = citizen.class
                citizen.class = newClass
                self:LogEvent("class_change", citizen.name .. " is now " .. newClass, {
                    from = oldClass,
                    to = newClass
                })
            end
        end
    end
end

-- Process wage payments for all employed citizens
function AlphaWorld:ProcessWagePayments(dayNumber)
    if not self.economicsSystem then
        return
    end

    local totalWagesPaid = 0
    local workersPaid = 0

    for _, citizen in ipairs(self.citizens) do
        -- Check if citizen has a workplace
        if citizen.workplace then
            -- Get the citizen's wage rate
            local wageRate = self:GetCitizenWageRate(citizen)

            if wageRate > 0 then
                -- Determine who pays the wage: building owner or town treasury
                local buildingOwnerId = nil
                if self.ownershipManager then
                    buildingOwnerId = self.ownershipManager:GetBuildingOwner(citizen.workplace.id)
                end

                if buildingOwnerId and buildingOwnerId ~= "town" then
                    -- Building is privately owned - owner pays wage from their funds
                    local ownerCanPay, _ = self.economicsSystem:SpendGold(
                        buildingOwnerId,
                        wageRate,
                        "wage_" .. citizen.id
                    )

                    if ownerCanPay then
                        -- Owner paid, worker receives wage
                        self.economicsSystem:AddGold(citizen.id, wageRate, "wage_" .. citizen.workplace.id)
                        totalWagesPaid = totalWagesPaid + wageRate
                        workersPaid = workersPaid + 1
                    else
                        -- Owner can't afford wages - TODO: handle this (worker might leave)
                        -- For now, town pays as subsidy
                        if self.gold >= wageRate then
                            self.gold = self.gold - wageRate
                            self.economicsSystem:AddGold(citizen.id, wageRate, "wage_subsidy_" .. citizen.workplace.id)
                            totalWagesPaid = totalWagesPaid + wageRate
                            workersPaid = workersPaid + 1
                        end
                    end
                else
                    -- Town-owned building or no owner - town pays wages
                    if self.gold >= wageRate then
                        self.gold = self.gold - wageRate
                        self.economicsSystem:AddGold(citizen.id, wageRate, "wage_" .. (citizen.workplace.id or "town"))
                        totalWagesPaid = totalWagesPaid + wageRate
                        workersPaid = workersPaid + 1
                    end
                end
            end
        end
    end

    -- Update stats
    self.stats.dailyWagesPaid = totalWagesPaid

    -- Log if significant wages paid
    if workersPaid > 0 and dayNumber % 5 == 0 then
        self:LogEvent("economics", string.format("%d workers paid %d gold in wages", workersPaid, totalWagesPaid), {})
    end
end

-- Get wage rate for a citizen based on their vocation
function AlphaWorld:GetCitizenWageRate(citizen)
    -- Look up worker type by vocation
    local vocation = citizen.vocation or "General Worker"

    -- Try to find in loaded worker types
    if self.workerTypes then
        for _, wt in ipairs(self.workerTypes) do
            if wt.name == vocation or wt.id == vocation then
                return wt.minimumWage or 10
            end
        end
    end

    -- Default wage based on class if no vocation match
    local classWages = {
        Elite = 25,
        Upper = 18,
        Middle = 12,
        Working = 8,
        Poor = 5
    }

    return classWages[citizen.class] or 10
end

-- Backward compatibility getters
function AlphaWorld:GetCurrentSlot()
    return self.timeManager:GetCurrentSlot()
end

function AlphaWorld:GetSlotProgress()
    return self.timeManager:GetSlotProgress()
end

-- Get day number
function AlphaWorld:GetDayNumber()
    return self.timeManager:GetDay()
end

-- =============================================================================
-- WATER/RIVER COLLISION
-- =============================================================================

-- Convert world coordinates to river-centered coordinates
function AlphaWorld:WorldToRiverCoords(worldX, worldY)
    local riverX = worldX - self.worldWidth / 2
    local riverY = worldY - self.worldHeight / 2
    return riverX, riverY
end

-- Check if a point is in water (river or lake)
function AlphaWorld:IsPositionInWater(x, y)
    if not self.river then return false end

    local riverX, riverY = self:WorldToRiverCoords(x, y)
    -- Use 60px buffer to keep buildings well away from water edges
    return self.river:IsPointNearWater(riverX, riverY, 60)
end

-- Check if a building rectangle overlaps with water
function AlphaWorld:IsBuildingInWater(x, y, width, height)
    if not self.river then return false end

    -- Check corners and center of building
    local checkPoints = {
        {x, y},                           -- Top-left
        {x + width, y},                   -- Top-right
        {x, y + height},                  -- Bottom-left
        {x + width, y + height},          -- Bottom-right
        {x + width/2, y + height/2},      -- Center
        {x + width/2, y},                 -- Top-center
        {x + width/2, y + height},        -- Bottom-center
        {x, y + height/2},                -- Left-center
        {x + width, y + height/2}         -- Right-center
    }

    for _, point in ipairs(checkPoints) do
        local inWater = self:IsPositionInWater(point[1], point[2])
        if inWater then
            return true
        end
    end

    return false
end

-- =============================================================================
-- CITIZEN MANAGEMENT
-- =============================================================================

function AlphaWorld:AddCitizen(class, name, traits, options)
    options = options or {}
    local defaultClass = DataLoader.getDefaultClassId()
    local citizen = CharacterV3:New(class or defaultClass, "citizen_" .. self.nextCitizenId)
    self.nextCitizenId = self.nextCitizenId + 1

    if name then
        citizen.name = name
    end

    if traits then
        for _, traitId in ipairs(traits) do
            citizen:AddTrait(traitId)
        end
    end

    -- Position for visual display (random within building area, avoiding water and trees)
    local maxAttempts = 100
    local attempt = 0
    local x, y
    local validPosition = false

    -- Get building area from WorldZones if available
    local buildingArea = self.worldZones and self.worldZones:GetBuildingArea()

    -- Helper to check if position is valid
    local function isValidPos(px, py)
        if self:IsPositionInWater(px, py) then return false end
        if self.forest and self.forest:CheckRectCollision(px - 10, py - 10, 20, 20) then return false end
        return true
    end

    while attempt < maxAttempts and not validPosition do
        if buildingArea then
            -- Spawn within the designated building area
            x = buildingArea.x + math.random(20, buildingArea.width - 40)
            y = buildingArea.y + math.random(20, buildingArea.height - 40)
        else
            -- Fallback: left side of map (original behavior)
            if attempt < 50 then
                x = math.random(50, math.min(450, self.worldWidth / 2))
            else
                x = math.random(50, self.worldWidth - 50)
            end
            y = math.random(50, self.worldHeight - 50)
        end
        validPosition = isValidPos(x, y)
        attempt = attempt + 1
    end

    -- Fallback: if still invalid, use building area center or left side
    if not validPosition then
        if buildingArea then
            x = buildingArea.x + buildingArea.width / 2
            y = buildingArea.y + buildingArea.height / 2
        else
            x = math.random(50, 200)
            y = math.random(50, self.worldHeight - 50)
        end
    end

    citizen.x = x
    citizen.y = y
    citizen.targetX = citizen.x
    citizen.targetY = citizen.y

    -- Work assignment
    citizen.workplace = nil
    citizen.workStation = nil

    -- Vocation from options
    if options.vocation then
        citizen.vocation = options.vocation
    end

    -- Initialize in economics system with starting wealth
    local startingWealth = options.startingWealth or 0
    if self.economicsSystem then
        self.economicsSystem:InitializeCharacter(citizen.id, startingWealth)
    end

    table.insert(self.citizens, citizen)
    self.stats.totalPopulation = #self.citizens

    self:LogEvent("immigration", citizen.name .. " joined the town", {class = citizen.class})

    return citizen
end

function AlphaWorld:RemoveCitizen(citizen, reason)
    for i, c in ipairs(self.citizens) do
        if c.id == citizen.id then
            table.remove(self.citizens, i)
            self.stats.totalPopulation = #self.citizens

            if reason == "emigration" then
                self.stats.totalEmigrations = self.stats.totalEmigrations + 1
                self:LogEvent("emigration", citizen.name .. " left the town (unsatisfied)", {class = citizen.class})
            elseif reason == "death" then
                self:LogEvent("death", citizen.name .. " passed away", {class = citizen.class})
            end

            return true
        end
    end
    return false
end

function AlphaWorld:SpawnInitialPopulation(count, classDistribution)
    -- Use DataLoader to get default distribution if not provided
    classDistribution = classDistribution or DataLoader.getDefaultClassDistribution()

    local defaultClass = DataLoader.getDefaultClassId()

    for i = 1, count do
        local roll = math.random()
        local cumulative = 0
        local selectedClass = defaultClass

        for classId, probability in pairs(classDistribution) do
            cumulative = cumulative + probability
            if roll <= cumulative then
                selectedClass = classId
                break
            end
        end

        self:AddCitizen(selectedClass)
    end

    self:LogEvent("founding", "Town founded with " .. count .. " citizens", {})
end

-- =============================================================================
-- BUILDING MANAGEMENT
-- =============================================================================

function AlphaWorld:AddBuilding(buildingTypeId, x, y, options)
    options = options or {}
    local buildingType = self.buildingTypesById[buildingTypeId]
    if not buildingType then
        print("Unknown building type: " .. tostring(buildingTypeId))
        return nil
    end

    -- Get level 0 data
    local levelData = buildingType.upgradeLevels and buildingType.upgradeLevels[1] or {}

    local building = {
        id = "building_" .. self.nextBuildingId,
        typeId = buildingTypeId,
        type = buildingType,
        name = buildingType.name,
        x = x or math.random(100, 700),
        y = y or math.random(100, 500),
        level = 0,

        -- Stations for production
        stations = {},

        -- Storage
        inputStorage = {},
        outputStorage = {},
        storageCapacity = levelData.storageCapacity or 100,

        -- Workers assigned
        workers = {},
        maxWorkers = levelData.workers or 2,

        -- Housing specific
        capacity = levelData.capacity or 0,
        residents = {},
        housingClass = buildingType.housingClass or "Middle"
    }

    -- Initialize stations based on building type
    local stationCount = levelData.stations or 1

    for i = 1, stationCount do
        table.insert(building.stations, {
            id = i,
            recipe = nil,
            progress = 0,
            state = "IDLE",  -- IDLE, PRODUCING, NO_MATERIALS, NO_WORKER
            worker = nil
        })
    end

    self.nextBuildingId = self.nextBuildingId + 1
    table.insert(self.buildings, building)

    -- Register building ownership
    local ownerId = options.ownerId or OwnershipManager.TOWN_OWNER_ID
    local purchasePrice = options.purchasePrice or (buildingType.constructionCost and buildingType.constructionCost.gold) or 0
    if self.ownershipManager then
        self.ownershipManager:RegisterBuilding(building.id, ownerId, purchasePrice, self.timeManager:GetDay())
    end

    -- Register housing building if it has housingConfig
    if buildingType.housingConfig and self.housingSystem then
        self.housingSystem:RegisterHousingBuilding(building.id, buildingTypeId)

        -- Assign initial occupants if provided
        if options.initialOccupants then
            for _, occupantId in ipairs(options.initialOccupants) do
                self.housingSystem:AssignHousing(occupantId, building.id)
            end
        end
    end

    -- Register building on land plots
    if self.landSystem then
        local plots = self.landSystem:GetPlotsForBuilding(x, y, 60, 60)
        for _, plot in ipairs(plots) do
            self.landSystem:AddBuildingToPlot(plot.id, building.id)
        end
    end

    self:LogEvent("construction", building.name .. " built", {type = buildingTypeId})

    return building
end

function AlphaWorld:AssignRecipeToStation(building, stationIndex, recipeId)
    local station = building.stations[stationIndex]
    if not station then return false end

    local recipe = self.recipesById[recipeId]
    if not recipe then return false end

    station.recipe = recipe
    station.progress = 0
    station.state = "IDLE"

    self:LogEvent("recipe", building.name .. " station " .. stationIndex .. " set to produce " .. recipe.name, {})

    return true
end

function AlphaWorld:AssignWorkerToBuilding(citizen, building)
    if #building.workers >= building.maxWorkers then
        return false
    end

    -- Remove from previous workplace
    if citizen.workplace then
        for i, w in ipairs(citizen.workplace.workers) do
            if w.id == citizen.id then
                table.remove(citizen.workplace.workers, i)
                break
            end
        end
    end

    citizen.workplace = building
    table.insert(building.workers, citizen)

    return true
end

-- =============================================================================
-- FREE AGENCY SYSTEM
-- Citizens autonomously seek the best workplace based on their preferences
-- =============================================================================

function AlphaWorld:RunFreeAgency()
    print("[FreeAgency] Running for " .. #self.citizens .. " citizens")
    -- Run for all citizens - both unemployed seeking jobs and employed considering better options
    for _, citizen in ipairs(self.citizens) do
        -- Unemployed citizens always seek work
        if not citizen.workplace then
            local bestBuilding = self:FindBestBuildingForCitizen(citizen)
            if bestBuilding then
                print("[FreeAgency] " .. citizen.name .. " (" .. (citizen.vocation or "?") .. ") -> " .. bestBuilding.name)
                self:AssignWorkerToBuilding(citizen, bestBuilding)
                self:LogEvent("employment", citizen.name .. " started working at " .. bestBuilding.name, {})
            end
        else
            -- Employed citizens may switch if a much better option is available
            -- Only consider switching if satisfaction at current job is low
            local currentSatisfaction = self:CalculateJobSatisfaction(citizen, citizen.workplace)
            if currentSatisfaction < 50 then
                local bestBuilding = self:FindBestBuildingForCitizen(citizen, true)  -- exclude current
                if bestBuilding then
                    local newSatisfaction = self:CalculateJobSatisfaction(citizen, bestBuilding)
                    -- Only switch if new job is significantly better (20+ points)
                    if newSatisfaction > currentSatisfaction + 20 then
                        local oldWorkplace = citizen.workplace
                        self:AssignWorkerToBuilding(citizen, bestBuilding)
                        self:LogEvent("employment", citizen.name .. " left " .. oldWorkplace.name .. " for " .. bestBuilding.name, {})
                    end
                end
            end
        end
    end
end

function AlphaWorld:FindBestBuildingForCitizen(citizen, excludeCurrent)
    local bestBuilding = nil
    local bestScore = -math.huge
    local debugVocation = citizen.vocation or "?"

    for _, building in ipairs(self.buildings) do
        -- Skip current workplace if requested
        if excludeCurrent and citizen.workplace and citizen.workplace.id == building.id then
            goto continue
        end

        -- Skip buildings that don't have any recipe assigned
        local hasRecipe = false
        for _, station in ipairs(building.stations or {}) do
            if station.recipe then
                hasRecipe = true
                break
            end
        end
        if not hasRecipe then
            goto continue
        end

        -- Check if building has space for more workers
        local maxWorkers = building.maxWorkers or #(building.stations or {})
        if #(building.workers or {}) >= maxWorkers then
            goto continue
        end

        -- Check if citizen is qualified for this building type
        local buildingType = self.buildingTypesById[building.typeId]
        local qualified = self:IsCitizenQualifiedForBuilding(citizen, buildingType)
        if not qualified then
            -- Debug: Print why Shoemaker was rejected
            if debugVocation == "Shoemaker" then
                print("[FindBest] " .. debugVocation .. " NOT qualified for " .. building.name .. " (" .. (building.typeId or "?") .. ")")
            end
            goto continue
        end

        -- Calculate job satisfaction score
        local score = self:CalculateJobSatisfaction(citizen, building)

        -- Debug: Print qualified buildings for Shoemaker
        if debugVocation == "Shoemaker" then
            print("[FindBest] " .. debugVocation .. " qualified for " .. building.name .. " score=" .. score)
        end

        if score > bestScore then
            bestScore = score
            bestBuilding = building
        end

        ::continue::
    end

    return bestBuilding
end

function AlphaWorld:IsCitizenQualifiedForBuilding(citizen, buildingType)
    if not buildingType then return true end  -- Default allow if no type info

    -- Check work categories if defined
    local buildingCategories = buildingType.workCategories
    if not buildingCategories or #buildingCategories == 0 then
        return true  -- No restrictions
    end

    -- Get citizen's vocation and look up their work categories from worker_types.json
    local citizenVocation = citizen.vocation or "General Worker"

    -- Look up work categories from the vocationWorkCategories lookup table
    local citizenCategories = self.vocationWorkCategories[citizenVocation]
        or self.vocationWorkCategories[citizenVocation:lower()]

    -- DEBUG: Log when falling back to General Labor
    if not citizenCategories then
        print("[DEBUG] Vocation lookup FAILED for: '" .. citizenVocation .. "'")
        print("[DEBUG] Available vocations in lookup:")
        local count = 0
        for k, v in pairs(self.vocationWorkCategories) do
            if count < 10 then
                print("  - '" .. k .. "' -> " .. table.concat(v, ", "))
            end
            count = count + 1
        end
        if count > 10 then
            print("  ... and " .. (count - 10) .. " more")
        end
        citizenCategories = {"General Labor"}
    end

    -- Check for overlap between citizen's work categories and building's requirements
    for _, citizenCat in ipairs(citizenCategories) do
        for _, buildingCat in ipairs(buildingCategories) do
            if citizenCat == buildingCat then
                return true
            end
        end
    end

    return false  -- No matching work categories
end

function AlphaWorld:CalculateJobSatisfaction(citizen, building)
    local score = 50  -- Base score

    -- Factor 1: Distance from home (citizens prefer closer workplaces)
    if citizen.homeX and citizen.homeY and building.x and building.y then
        local dx = citizen.homeX - building.x
        local dy = citizen.homeY - building.y
        local distance = math.sqrt(dx * dx + dy * dy)
        -- Prefer closer buildings (100 units = -10 points, 500 units = -50 points)
        score = score - (distance / 10)
    end

    -- Factor 2: Building efficiency (higher efficiency = better pay potential)
    local efficiency = building.resourceEfficiency or 1.0
    score = score + efficiency * 30

    -- Factor 3: Crowdedness (prefer less crowded buildings)
    local maxWorkers = building.maxWorkers or #(building.stations or {})
    local currentWorkers = #(building.workers or {})
    if maxWorkers > 0 then
        local crowdedness = currentWorkers / maxWorkers
        score = score + (1 - crowdedness) * 20
    end

    -- Factor 4: Class compatibility (some classes prefer certain building types)
    local buildingType = self.buildingTypesById[building.typeId]
    if buildingType and citizen.class then
        local classPreference = self:GetClassBuildingPreference(citizen.class, buildingType)
        score = score + classPreference
    end

    -- Factor 5: Recipe outputs (prefer buildings producing goods the citizen wants)
    for _, station in ipairs(building.stations or {}) do
        if station.recipe and station.recipe.outputs then
            for outputId, _ in pairs(station.recipe.outputs) do
                -- Check if this commodity is in citizen's desired categories
                local commodity = self.commoditiesById[outputId]
                if commodity and self:DoesCitizenDesireCommodity(citizen, commodity) then
                    score = score + 10
                end
            end
        end
    end

    return score
end

function AlphaWorld:GetClassBuildingPreference(class, buildingType)
    -- Class preferences for different building types
    local preferences = {
        elite = {
            luxury = 20, commerce = 15, services = 10,
            farming = -20, mining = -30, labor = -30
        },
        upper = {
            commerce = 15, services = 10, manufacturing = 5,
            farming = -10, mining = -15
        },
        middle = {
            manufacturing = 10, crafting = 10, commerce = 5,
            farming = 0, mining = -5
        },
        lower = {
            farming = 10, mining = 5, labor = 10,
            luxury = -10
        }
    }

    local classPrefs = preferences[class]
    if not classPrefs or not buildingType.workCategories then
        return 0
    end

    local totalPref = 0
    for _, category in ipairs(buildingType.workCategories or {}) do
        totalPref = totalPref + (classPrefs[category] or 0)
    end

    return totalPref
end

function AlphaWorld:DoesCitizenDesireCommodity(citizen, commodity)
    -- Simple check: citizens desire commodities in their class's typical consumption
    -- This could be expanded based on the craving system
    if not commodity.category then return false end

    local classDesires = {
        elite = {"luxury", "exotic", "vice", "services"},
        upper = {"luxury", "processed_food", "services", "exotic"},
        middle = {"processed_food", "basic_goods", "services"},
        lower = {"basic_food", "basic_goods"}
    }

    local desires = classDesires[citizen.class] or classDesires.middle
    for _, desiredCategory in ipairs(desires) do
        if commodity.category == desiredCategory then
            return true
        end
    end

    return false
end

-- =============================================================================
-- BUILDING PLACEMENT & EFFICIENCY
-- =============================================================================

function AlphaWorld:CanAffordBuilding(buildingType)
    if not buildingType then return false, "Invalid building type" end

    -- Check gold cost
    local cost = buildingType.constructionCost or {}
    local goldCost = cost.gold or 0
    if goldCost > self.gold then
        return false, "Insufficient gold (need " .. goldCost .. ")"
    end

    -- Check material costs
    for materialId, required in pairs(cost.materials or {}) do
        local available = self.inventory[materialId] or 0
        if available < required then
            return false, "Need " .. required .. " " .. materialId
        end
    end

    return true, nil
end

function AlphaWorld:CalculateBuildingEfficiency(buildingType, x, y, width, height)
    width = width or 60
    height = height or 60

    -- No constraints = 100% efficiency
    if not buildingType.placementConstraints or not buildingType.placementConstraints.enabled then
        return 1.0, {}, true
    end

    local constraints = buildingType.placementConstraints
    local breakdown = {}
    local totalWeight = 0
    local weightedSum = 0
    local allRequirementsMet = true

    for _, req in ipairs(constraints.requiredResources or {}) do
        local value = 0
        local resourceName = req.displayName or req.resourceId

        if req.anyOf then
            -- Pick best from list of resources
            value = self.naturalResources:getBestOfAny(req.anyOf, x, y, width, height)
            resourceName = req.displayName or "Resource"
        else
            -- Single resource
            value = self.naturalResources:getAverageValue(req.resourceId, x, y, width, height)
        end

        local weight = req.weight or 1
        local minValue = req.minValue or 0
        local met = value >= minValue

        breakdown[req.resourceId or req.displayName] = {
            value = value,
            weight = weight,
            met = met,
            minValue = minValue,
            displayName = resourceName
        }

        weightedSum = weightedSum + (value * weight)
        totalWeight = totalWeight + weight

        if not met then
            allRequirementsMet = false
        end
    end

    local efficiency = totalWeight > 0 and (weightedSum / totalWeight) or 1.0
    local blockingThreshold = constraints.blockingThreshold or 0.1
    local canPlace = efficiency >= blockingThreshold and allRequirementsMet

    return efficiency, breakdown, canPlace
end

function AlphaWorld:ValidateBuildingPlacement(buildingType, x, y, width, height)
    width = width or 60
    height = height or 60

    local errors = {}

    -- Check world boundaries
    if x < 0 or y < 0 or x + width > self.worldWidth or y + height > self.worldHeight then
        table.insert(errors, "Out of bounds")
    end

    -- Check if within designated building area (zone-based validation)
    if self.worldZones and not self.worldZones:IsInBuildingArea(x, y, width, height) then
        table.insert(errors, "Outside building area")
    end

    -- Check collision with river/water
    if self:IsBuildingInWater(x, y, width, height) then
        table.insert(errors, "Cannot build on water")
    end

    -- Check collision with forest/trees (backup check in case trees exist outside zones)
    if self.forest and self.forest:CheckRectCollision(x, y, width, height) then
        table.insert(errors, "Cannot build on trees")
    end

    -- Check collision with mountains
    if self.mountains and self.mountains:CheckRectCollision(x, y, width, height) then
        table.insert(errors, "Cannot build on mountains")
    end

    -- Check collision with existing buildings
    for _, building in ipairs(self.buildings) do
        local bw = 60
        local bh = 60
        if x < building.x + bw and x + width > building.x and
           y < building.y + bh and y + height > building.y then
            table.insert(errors, "Overlaps with " .. (building.name or "building"))
        end
    end

    -- Check resource efficiency
    local efficiency, breakdown, canPlaceResources = self:CalculateBuildingEfficiency(buildingType, x, y, width, height)
    if not canPlaceResources then
        table.insert(errors, "Insufficient resources")
    end

    local isValid = #errors == 0
    return isValid, errors, efficiency, breakdown
end

function AlphaWorld:PlaceBuilding(buildingType, x, y)
    -- Validate
    local isValid, errors, efficiency, breakdown = self:ValidateBuildingPlacement(buildingType, x, y)
    if not isValid then
        return nil, errors
    end

    -- Check affordability
    local canAfford, affordError = self:CanAffordBuilding(buildingType)
    if not canAfford then
        return nil, {affordError}
    end

    -- Deduct costs
    local cost = buildingType.constructionCost or {}
    if cost.gold then
        self.gold = self.gold - cost.gold
    end
    for materialId, required in pairs(cost.materials or {}) do
        self:RemoveFromInventory(materialId, required)
    end

    -- Create building with efficiency stored
    local building = self:AddBuilding(buildingType.id, x, y)
    if building then
        building.resourceEfficiency = efficiency
        building.efficiencyBreakdown = breakdown
    end

    return building, nil
end

-- =============================================================================
-- INVENTORY MANAGEMENT
-- =============================================================================

function AlphaWorld:AddToInventory(commodityId, amount)
    self.inventory[commodityId] = (self.inventory[commodityId] or 0) + amount
end

function AlphaWorld:RemoveFromInventory(commodityId, amount)
    local current = self.inventory[commodityId] or 0
    local removed = math.min(current, amount)
    self.inventory[commodityId] = current - removed
    return removed
end

function AlphaWorld:GetInventoryCount(commodityId)
    return self.inventory[commodityId] or 0
end

-- =============================================================================
-- PRODUCTION LOOP
-- =============================================================================

function AlphaWorld:UpdateProduction(dt)
    for _, building in ipairs(self.buildings) do
        self:UpdateBuildingProduction(building, dt)
    end
end

function AlphaWorld:UpdateBuildingProduction(building, dt)
    for _, station in ipairs(building.stations) do
        if station.recipe then
            -- Check if we have a worker
            local hasWorker = #building.workers > 0
            if not hasWorker then
                station.state = "NO_WORKER"
            else
                -- Check if we have materials
                -- Recipe inputs can be dictionary format {commodityId: quantity} or array format [{commodityId, quantity}]
                local hasMaterials = true
                for commodityId, quantity in pairs(station.recipe.inputs or {}) do
                    -- Handle both dictionary format and array format
                    local inputId = type(commodityId) == "string" and commodityId or (quantity.commodityId or commodityId)
                    local inputQty = type(quantity) == "number" and quantity or (quantity.quantity or 1)
                    local available = self:GetInventoryCount(inputId)
                    if available < inputQty then
                        hasMaterials = false
                        break
                    end
                end

                if not hasMaterials then
                    station.state = "NO_MATERIALS"
                else
                    station.state = "PRODUCING"

                    -- Progress production
                    local productionTime = station.recipe.productionTime or 10
                    -- Apply both global productivity and building's resource efficiency
                    local resourceEfficiency = building.resourceEfficiency or 1.0
                    local efficiency = self.stats.productivityMultiplier * resourceEfficiency
                    station.progress = station.progress + (dt * efficiency / productionTime)

                    -- Complete production
                    if station.progress >= 1 then
                        station.progress = 0

                        -- Consume inputs and record stats
                        for commodityId, quantity in pairs(station.recipe.inputs or {}) do
                            local inputId = type(commodityId) == "string" and commodityId or (quantity.commodityId or commodityId)
                            local inputQty = type(quantity) == "number" and quantity or (quantity.quantity or 1)
                            self:RemoveFromInventory(inputId, inputQty)
                            -- Record consumption in production stats
                            if self.productionStats then
                                self.productionStats:recordConsumption(inputId, inputQty)
                            end
                        end

                        -- Produce outputs and record stats
                        for commodityId, quantity in pairs(station.recipe.outputs or {}) do
                            local outputId = type(commodityId) == "string" and commodityId or (quantity.commodityId or commodityId)
                            local outputQty = type(quantity) == "number" and quantity or (quantity.quantity or 1)
                            self:AddToInventory(outputId, outputQty)
                            -- Record production in production stats
                            if self.productionStats then
                                self.productionStats:recordProduction(outputId, outputQty, building.id)
                            end
                        end

                        self:LogEvent("production", building.name .. " produced " .. station.recipe.name, {})
                    end
                end
            end
        else
            station.state = "IDLE"
        end
    end
end

-- =============================================================================
-- CONSUMPTION LOOP
-- =============================================================================

function AlphaWorld:UpdateConsumption(dt)
    -- Accumulate cravings for each citizen
    -- Pass active cravings for current slot for slot-based accumulation
    local activeCravings = self:GetActiveCravingsForSlot()
    for _, citizen in ipairs(self.citizens) do
        citizen:UpdateCurrentCravings(dt, activeCravings)
    end
end

function AlphaWorld:ProcessSlotConsumption()
    -- Run allocation engine at end of each slot
    -- Calculate cycle number: (day - 1) * slotsPerDay + currentSlotIndex
    local day = self.timeManager:GetDay() or 1
    local slotIndex = self.timeManager.currentSlotIndex or 1
    local slotsPerDay = #(self.timeManager.timeSlots or {}) or 6
    local currentCycle = (day - 1) * slotsPerDay + slotIndex
    local allocations = AllocationEngineV2.AllocateCycle(self.citizens, self.inventory, currentCycle, "need_based", {
        fairnessEnabled = true
    })

    -- Apply allocations (result is the list of allocations directly)
    if allocations and #allocations > 0 then
        for _, allocation in ipairs(allocations) do
            local citizen = allocation.character
            local commodityId = allocation.commodityId
            local quantity = allocation.quantity

            if citizen and commodityId and quantity then
                -- Remove from inventory
                self:RemoveFromInventory(commodityId, quantity)

                -- Apply to character
                citizen:Consume(commodityId, quantity)
            end
        end

        -- Log summary
        self:LogEvent("consumption", #allocations .. " allocations made", {})
    end
end

-- =============================================================================
-- SELECTION
-- =============================================================================

function AlphaWorld:SelectEntity(entity, entityType)
    self.selectedEntity = entity
    self.selectedEntityType = entityType
end

function AlphaWorld:ClearSelection()
    self.selectedEntity = nil
    self.selectedEntityType = nil
end

function AlphaWorld:GetCitizenAt(x, y, radius)
    radius = radius or 20
    for _, citizen in ipairs(self.citizens) do
        local dx = citizen.x - x
        local dy = citizen.y - y
        if dx * dx + dy * dy <= radius * radius then
            return citizen
        end
    end
    return nil
end

function AlphaWorld:GetBuildingAt(x, y)
    for _, building in ipairs(self.buildings) do
        local bw = 60  -- building width
        local bh = 60  -- building height
        if x >= building.x and x <= building.x + bw and
           y >= building.y and y <= building.y + bh then
            return building
        end
    end
    return nil
end

-- =============================================================================
-- MAIN UPDATE LOOP
-- =============================================================================

function AlphaWorld:Update(dt)
    -- Update time manager (handles pause internally, triggers slot/day change callbacks)
    self.timeManager:Update(dt)

    -- Sync pause state for backward compatibility
    self.isPaused = self.timeManager.isPaused

    -- Update river animation even when paused
    if self.river then
        self.river:Update(dt)
    end

    if self.isPaused then return end

    self.gameTime = self.gameTime + dt

    -- Update production stats tick
    if self.productionStats then
        self.productionStatsTick = self.productionStatsTick + 1
        self.productionStats:updateTick(self.productionStatsTick)

        -- Record worker utilization
        local totalWorkers = #self.citizens
        local activeWorkers = 0
        for _, citizen in ipairs(self.citizens) do
            if citizen.workplace then
                activeWorkers = activeWorkers + 1
            end
        end
        self.productionStats:recordWorkerStats(totalWorkers, activeWorkers)

        -- Record stockpile levels
        for commodityId, quantity in pairs(self.inventory) do
            self.productionStats:recordStockpile(commodityId, quantity)
        end
    end

    -- Update production
    self:UpdateProduction(dt)

    -- Update consumption (craving accumulation)
    self:UpdateConsumption(dt)

    -- Update citizen positions (visual movement)
    self:UpdateCitizenPositions(dt)
end

function AlphaWorld:UpdateCitizenPositions(dt)
    for _, citizen in ipairs(self.citizens) do
        -- Initialize target position if not set
        if not citizen.targetX or not citizen.targetY then
            citizen.targetX = citizen.x or 100
            citizen.targetY = citizen.y or 100
        end

        -- Simple wandering behavior
        if math.random() < 0.01 then
            -- Find a valid target that doesn't collide with river
            local attempts = 0
            local validTarget = false
            local newX, newY

            while not validTarget and attempts < 10 do
                newX = math.random(100, 700)
                newY = math.random(100, 500)

                -- Check river collision
                local inRiver = false
                if self.river then
                    inRiver = self.river:IsPointNear(newX - self.worldWidth * 0.5, newY - self.worldHeight * 0.5, 30)
                end

                if not inRiver then
                    validTarget = true
                end
                attempts = attempts + 1
            end

            if validTarget then
                citizen.targetX = newX
                citizen.targetY = newY
            end
        end

        local dx = citizen.targetX - citizen.x
        local dy = citizen.targetY - citizen.y
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist > 5 then
            local speed = 50 * dt
            local newX = citizen.x + (dx / dist) * speed
            local newY = citizen.y + (dy / dist) * speed

            -- Check if new position is in river
            local inRiver = false
            if self.river then
                inRiver = self.river:IsPointNear(newX - self.worldWidth * 0.5, newY - self.worldHeight * 0.5, 20)
            end

            if not inRiver then
                citizen.x = newX
                citizen.y = newY
            end
        end
    end
end

function AlphaWorld:UpdateStats()
    -- Update population count
    self.stats.totalPopulation = #self.citizens

    local totalSat = 0
    local classSat = {}
    local classCount = {}
    local employed = 0
    local unemployed = 0

    for _, citizen in ipairs(self.citizens) do
        local sat = citizen:GetAverageSatisfaction() or 50
        totalSat = totalSat + sat

        -- Track by class (normalize to match characterClasses IDs: elite, upper, middle, lower)
        local rawClass = (citizen.emergentClass or citizen.class or "middle"):lower()
        -- Map legacy class names to current system (Working/Poor -> lower)
        local classMap = {
            working = "lower",
            poor = "lower",
        }
        local class = classMap[rawClass] or rawClass
        classSat[class] = (classSat[class] or 0) + sat
        classCount[class] = (classCount[class] or 0) + 1

        -- Employment
        if citizen.workplace then
            employed = employed + 1
        else
            unemployed = unemployed + 1
        end
    end

    self.stats.averageSatisfaction = #self.citizens > 0 and (totalSat / #self.citizens) or 0
    self.stats.employedCount = employed
    self.stats.unemployedCount = unemployed

    -- Calculate per-class satisfaction
    self.stats.satisfactionByClass = {}
    for class, total in pairs(classSat) do
        self.stats.satisfactionByClass[class] = classCount[class] > 0 and (total / classCount[class]) or 0
    end

    -- Calculate housing capacity
    local housingCap = 0
    for _, building in ipairs(self.buildings) do
        if building.type and building.type.category == "housing" then
            -- Get capacity from upgrade level or building type
            local capacity = building.capacity or 4
            if not building.capacity and building.type.upgradeLevels then
                local level = building.level or 0
                local levelData = building.type.upgradeLevels[level + 1]
                if levelData and levelData.capacity then
                    capacity = levelData.capacity
                end
            end
            housingCap = housingCap + capacity
        end
    end
    self.stats.housingCapacity = housingCap
end

-- =============================================================================
-- EVENT LOG
-- =============================================================================

function AlphaWorld:LogEvent(eventType, message, details)
    local currentSlot = self.timeManager:GetCurrentSlot()
    table.insert(self.eventLog, 1, {
        time = self.gameTime,
        day = self.timeManager:GetDay(),
        slot = currentSlot and currentSlot.index or 1,
        type = eventType,
        message = message,
        details = details
    })

    -- Trim log
    while #self.eventLog > self.maxEvents do
        table.remove(self.eventLog)
    end
end

-- =============================================================================
-- PRODUCTION STATS ACCESS
-- =============================================================================

function AlphaWorld:GetProductionStats()
    return self.productionStats
end

function AlphaWorld:GetProductionMetrics()
    if self.productionStats then
        return self.productionStats:getMetricsSummary()
    end
    return nil
end

function AlphaWorld:GetBuildingEfficiencies()
    -- Calculate efficiency for each building based on worker count and production state
    local efficiencies = {}

    for _, building in ipairs(self.buildings) do
        local totalStations = #building.stations
        local activeStations = 0
        local producingStations = 0

        for _, station in ipairs(building.stations) do
            if station.recipe then
                activeStations = activeStations + 1
                if station.state == "PRODUCING" then
                    producingStations = producingStations + 1
                end
            end
        end

        local workerCount = #(building.workers or {})
        local maxWorkers = building.maxWorkers or totalStations

        -- Calculate efficiency as percentage
        local efficiency = 0
        if activeStations > 0 then
            efficiency = (producingStations / activeStations) * 100
        end

        -- Worker utilization
        local workerUtil = maxWorkers > 0 and (workerCount / maxWorkers) * 100 or 0

        table.insert(efficiencies, {
            id = building.id,
            name = building.name,
            typeId = building.typeId,
            efficiency = efficiency,
            workerUtilization = workerUtil,
            workerCount = workerCount,
            maxWorkers = maxWorkers,
            activeStations = activeStations,
            producingStations = producingStations,
            totalStations = totalStations
        })
    end

    -- Sort by efficiency descending
    table.sort(efficiencies, function(a, b)
        return a.efficiency > b.efficiency
    end)

    return efficiencies
end

-- =============================================================================
-- SAVE/LOAD
-- =============================================================================

function AlphaWorld:LoadFromSaveData(saveData)
    -- Restore town info
    self.townName = saveData.townName or "CraveTown"
    self.gold = saveData.gold or 0
    self.gameConfig = saveData.gameConfig

    -- Restore time state
    if saveData.timeState then
        self.timeManager.currentHour = saveData.timeState.currentHour or 6
        self.timeManager.dayNumber = saveData.timeState.dayNumber or 1
        self.timeManager.currentSlotIndex = saveData.timeState.currentSlotIndex or 1
        self.isPaused = saveData.timeState.isPaused ~= false
        if saveData.timeState.currentSpeed then
            self.timeManager:SetSpeed(saveData.timeState.currentSpeed)
        end
        if self.isPaused then
            self.timeManager:Pause()
        else
            self.timeManager:Resume()
        end
    end

    -- Restore inventory
    self.inventory = saveData.inventory or {}

    -- Restore buildings
    self.buildings = {}
    local buildingsById = {}
    for _, buildingData in ipairs(saveData.buildings or {}) do
        local building = self:CreateBuildingFromData(buildingData)
        if building then
            table.insert(self.buildings, building)
            buildingsById[building.id] = building
        end
    end
    self.nextBuildingId = #self.buildings + 1

    -- Restore citizens
    self.citizens = {}
    for _, citizenData in ipairs(saveData.citizens or {}) do
        local citizen = self:CreateCitizenFromData(citizenData, buildingsById)
        if citizen then
            table.insert(self.citizens, citizen)
        end
    end
    self.nextCitizenId = #self.citizens + 1

    -- Restore immigration queue
    if saveData.immigrationQueue and self.immigrationSystem then
        self.immigrationSystem.queue = {}
        for _, applicantData in ipairs(saveData.immigrationQueue) do
            table.insert(self.immigrationSystem.queue, applicantData)
        end
    end

    -- Restore event log
    self.eventLog = saveData.eventLog or {}

    -- Restore stats history
    self.statsHistory = saveData.statsHistory or {}

    -- Restore ownership & housing systems
    if saveData.landSystemData and self.landSystem then
        self.landSystem:Deserialize(saveData.landSystemData)
    end
    if saveData.ownershipData and self.ownershipManager then
        self.ownershipManager:Deserialize(saveData.ownershipData)
    end
    if saveData.economicsData and self.economicsSystem then
        self.economicsSystem:Deserialize(saveData.economicsData)
    end
    if saveData.housingData and self.housingSystem then
        self.housingSystem:Deserialize(saveData.housingData)
    end

    -- Update stats
    self:UpdateStats()

    -- Log the load
    self:LogEvent("info", "Game loaded: " .. self.townName, {})
end

-- Serialize world state for saving
function AlphaWorld:Serialize()
    local saveData = {
        townName = self.townName,
        gold = self.gold,
        gameConfig = self.gameConfig,

        timeState = {
            currentHour = self.timeManager.currentHour,
            dayNumber = self.timeManager.dayNumber,
            currentSlotIndex = self.timeManager.currentSlotIndex,
            isPaused = self.isPaused,
            currentSpeed = self.timeManager.currentSpeed
        },

        inventory = self.inventory,
        buildings = {},
        citizens = {},
        eventLog = self.eventLog,
        statsHistory = self.statsHistory
    }

    -- Serialize buildings
    for _, building in ipairs(self.buildings) do
        local workerIds = {}
        for _, worker in ipairs(building.workers or {}) do
            table.insert(workerIds, worker.id)
        end

        table.insert(saveData.buildings, {
            id = building.id,
            typeId = building.typeId,
            x = building.x,
            y = building.y,
            name = building.name,
            workers = workerIds,
            stations = building.stations,
            isPaused = building.isPaused,
            priority = building.priority
        })
    end

    -- Serialize citizens
    for _, citizen in ipairs(self.citizens) do
        table.insert(saveData.citizens, {
            id = citizen.id,
            name = citizen.name,
            class = citizen.class,
            age = citizen.age,
            vocation = citizen.vocation,
            wealth = citizen.wealth,
            traits = citizen.traits,
            x = citizen.x,
            y = citizen.y,
            possessions = citizen.possessions,
            cravings = citizen.cravings,
            fatigueState = citizen.fatigueState,
            workplaceId = citizen.workplace and citizen.workplace.id or nil
        })
    end

    -- Serialize immigration queue
    if self.immigrationSystem and self.immigrationSystem.queue then
        saveData.immigrationQueue = self.immigrationSystem.queue
    end

    -- Serialize ownership & housing systems
    if self.landSystem then
        saveData.landSystemData = self.landSystem:Serialize()
    end
    if self.ownershipManager then
        saveData.ownershipData = self.ownershipManager:Serialize()
    end
    if self.economicsSystem then
        saveData.economicsData = self.economicsSystem:Serialize()
    end
    if self.housingSystem then
        saveData.housingData = self.housingSystem:Serialize()
    end

    return saveData
end

function AlphaWorld:CreateBuildingFromData(data)
    local buildingDef = nil
    for _, def in ipairs(self.buildingTypes) do
        if def.id == data.typeId then
            buildingDef = def
            break
        end
    end

    if not buildingDef then
        return nil
    end

    local building = {
        id = data.id,
        typeId = data.typeId,
        x = data.x,
        y = data.y,
        name = data.name or buildingDef.name,
        workers = {},  -- Will be filled when loading citizens
        workerIds = data.workers or {},  -- Store for later linking
        stations = data.stations or buildingDef.stations or 1,
        maxWorkers = buildingDef.maxWorkers or 2,
        isPaused = data.isPaused or false,
        priority = data.priority or 5,
        definition = buildingDef
    }

    -- Add GetBounds method
    building.GetBounds = function(self)
        local w = buildingDef.width or 80
        local h = buildingDef.height or 60
        return self.x, self.y, w, h
    end

    return building
end

function AlphaWorld:CreateCitizenFromData(data, buildingsById)
    local citizen = CharacterV3.Create({
        id = data.id,
        name = data.name,
        class = data.class,
        age = data.age
    })

    if not citizen then
        return nil
    end

    -- Restore additional properties
    citizen.vocation = data.vocation
    citizen.wealth = data.wealth or 0
    citizen.traits = data.traits or {}
    citizen.x = data.x or 0
    citizen.y = data.y or 0
    citizen.possessions = data.possessions or {}

    -- Restore craving state
    if data.cravings then
        citizen.cravings = data.cravings
    end
    if data.fatigueState then
        citizen.fatigueState = data.fatigueState
    end

    -- Link to workplace
    if data.workplaceId and buildingsById[data.workplaceId] then
        local workplace = buildingsById[data.workplaceId]
        citizen.workplace = workplace
        table.insert(workplace.workers, citizen)
    end

    return citizen
end

return AlphaWorld
