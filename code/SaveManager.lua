--
-- SaveManager.lua
-- Handles saving and loading game state for CraveTown Alpha
--
-- Phase 9: Updated to include land ownership, character economics,
-- housing assignments, and relationships
--

local json = require("code.json")

SaveManager = {}
SaveManager.__index = SaveManager

-- Constants
SaveManager.MAX_SLOTS = 5
SaveManager.QUICKSAVE_FILE = "quicksave.json"
SaveManager.AUTOSAVE_FILE = "autosave.json"
SaveManager.SETTINGS_FILE = "settings.json"
SaveManager.CURRENT_VERSION = "0.2.0"  -- Updated for Phase 9

function SaveManager:Create()
    local manager = setmetatable({}, SaveManager)

    -- Autosave settings
    manager.autosaveEnabled = true
    manager.autosaveInterval = 25  -- cycles between autosaves
    manager.lastAutosaveCycle = 0

    -- Load settings if they exist
    manager:LoadSettings()

    return manager
end

-- =============================================================================
-- SETTINGS
-- =============================================================================

function SaveManager:LoadSettings()
    local content = love.filesystem.read(self.SETTINGS_FILE)
    if content then
        local ok, settings = pcall(json.decode, content)
        if ok and settings then
            self.autosaveEnabled = settings.autosaveEnabled ~= false
            self.autosaveInterval = settings.autosaveInterval or 25
        end
    end
end

function SaveManager:SaveSettings()
    local settings = {
        autosaveEnabled = self.autosaveEnabled,
        autosaveInterval = self.autosaveInterval
    }
    local content = json.encode(settings)
    love.filesystem.write(self.SETTINGS_FILE, content)
end

-- =============================================================================
-- SLOT MANAGEMENT
-- =============================================================================

function SaveManager:GetSlotFilename(slotNumber)
    return "save_slot_" .. slotNumber .. ".json"
end

function SaveManager:GetSlotInfo(slotNumber)
    local filename = self:GetSlotFilename(slotNumber)
    local content = love.filesystem.read(filename)

    if not content then
        return nil  -- Empty slot
    end

    local ok, data = pcall(json.decode, content)
    if not ok or not data then
        return nil
    end

    -- Return metadata only
    return {
        slotNumber = slotNumber,
        townName = data.townName or "Unknown",
        cycleNumber = data.cycleNumber or 0,
        dayNumber = data.dayNumber or 1,
        population = data.population or 0,
        satisfaction = data.averageSatisfaction or 0,
        gold = data.gold or 0,
        savedAt = data.savedAt or "Unknown",
        version = data.version or "0.0.0"
    }
end

function SaveManager:GetAllSlotInfo()
    local slots = {}
    for i = 1, self.MAX_SLOTS do
        slots[i] = self:GetSlotInfo(i)
    end
    return slots
end

function SaveManager:DeleteSlot(slotNumber)
    local filename = self:GetSlotFilename(slotNumber)
    if love.filesystem.getInfo(filename) then
        love.filesystem.remove(filename)
        return true
    end
    return false
end

-- =============================================================================
-- SAVING
-- =============================================================================

function SaveManager:CreateSaveData(world)
    -- Serialize world state
    local saveData = {
        version = self.CURRENT_VERSION,
        savedAt = os.date("%Y-%m-%d %H:%M:%S"),

        -- Town info
        townName = world.townName or "CraveTown",
        cycleNumber = world.cycleCount or 0,
        dayNumber = world.timeManager and world.timeManager.dayNumber or 1,
        gold = world.gold or 0,

        -- Game config
        gameConfig = world.gameConfig,

        -- Statistics
        population = #world.citizens,
        averageSatisfaction = self:CalculateAverageSatisfaction(world),

        -- Time state
        timeState = {
            currentHour = world.timeManager and world.timeManager.currentHour or 6,
            dayNumber = world.timeManager and world.timeManager.dayNumber or 1,
            currentSlotIndex = world.timeManager and world.timeManager.currentSlotIndex or 1,
            isPaused = world.isPaused or false,
            currentSpeed = world.timeManager and world.timeManager.currentSpeed or "normal"
        },

        -- Inventory
        inventory = world.inventory or {},

        -- Buildings
        buildings = self:SerializeBuildings(world),

        -- Citizens (includes economics, relationships, housing)
        citizens = self:SerializeCitizens(world),

        -- Immigration queue
        immigrationQueue = self:SerializeImmigrationQueue(world),

        -- Event log (last 100 events)
        eventLog = self:SerializeEventLog(world),

        -- Stats history
        statsHistory = world.statsHistory or {},

        -- Phase 9: Land System state
        landSystem = self:SerializeLandSystem(world),

        -- Phase 9: Housing System state
        housingSystem = self:SerializeHousingSystem(world),

        -- Phase 9: Economics System state (if separate from citizens)
        economicsSystem = self:SerializeEconomicsSystem(world)
    }

    return saveData
end

function SaveManager:CalculateAverageSatisfaction(world)
    if not world.citizens or #world.citizens == 0 then
        return 0
    end

    local total = 0
    for _, citizen in ipairs(world.citizens) do
        if citizen.GetAverageSatisfaction then
            total = total + citizen:GetAverageSatisfaction()
        end
    end
    return math.floor(total / #world.citizens)
end

function SaveManager:SerializeBuildings(world)
    local buildings = {}
    for _, building in ipairs(world.buildings or {}) do
        table.insert(buildings, {
            id = building.id,
            typeId = building.typeId,
            x = building.x,
            y = building.y,
            name = building.name,
            workers = self:SerializeWorkerIds(building.workers),
            stations = building.stations,
            isPaused = building.isPaused,
            priority = building.priority,

            -- Phase 9: Ownership data
            ownerId = building.ownerId,
            landPlotId = building.landPlotId,

            -- Phase 9: Housing-specific data
            isHousing = building.isHousing,
            housingQuality = building.housingQuality,
            housingCapacity = building.housingCapacity,
            rentPerOccupant = building.rentPerOccupant,
            occupants = building.occupants  -- List of citizen IDs
        })
    end
    return buildings
end

function SaveManager:SerializeWorkerIds(workers)
    local ids = {}
    for _, worker in ipairs(workers or {}) do
        if worker.id then
            table.insert(ids, worker.id)
        end
    end
    return ids
end

function SaveManager:SerializeCitizens(world)
    local citizens = {}
    for _, citizen in ipairs(world.citizens or {}) do
        local citizenData = {
            id = citizen.id,
            name = citizen.name,
            age = citizen.age,
            vocation = citizen.vocation,
            traits = citizen.traits,

            -- Legacy class field (for backwards compat, may be nil in new saves)
            class = citizen.class,

            -- Phase 9: Emergent class system
            emergentClass = citizen.emergentClass,

            -- Phase 9: Economics data
            economics = {
                wealth = citizen.wealth or citizen.economics and citizen.economics.wealth or 0,
                liquidAssets = citizen.liquidAssets or citizen.economics and citizen.economics.liquidAssets or 0,
                fixedAssets = citizen.fixedAssets or citizen.economics and citizen.economics.fixedAssets or 0,
                incomePerCycle = citizen.incomePerCycle or citizen.economics and citizen.economics.incomePerCycle or 0,
                expensesPerCycle = citizen.expensesPerCycle or citizen.economics and citizen.economics.expensesPerCycle or 0,
                lastCalculatedCycle = citizen.lastEconomicsCalculation or 0
            },

            -- Craving state
            cravings = citizen.cravings,
            baseCravings = citizen.baseCravings,
            currentCravings = citizen.currentCravings,
            satisfaction = citizen.satisfaction,
            fatigueState = citizen.fatigueState,
            commodityMultipliers = citizen.commodityMultipliers,

            -- Position
            x = citizen.x,
            y = citizen.y,

            -- Work assignment
            workplaceId = citizen.workplace and citizen.workplace.id or citizen.workplaceId,

            -- Possessions
            possessions = citizen.possessions,
            activeEffects = citizen.activeEffects,

            -- Phase 9: Housing assignment
            housingId = citizen.housingId or citizen.residence,
            rentPaid = citizen.rentPaid,
            housingSatisfaction = citizen.housingSatisfaction,

            -- Phase 9: Land ownership
            ownedPlotIds = citizen.ownedPlotIds or {},
            ownedBuildingIds = citizen.ownedBuildingIds or {},

            -- Phase 9: Relationships
            relationships = self:SerializeRelationships(citizen),

            -- Consumption history (last 20 entries)
            consumptionHistory = self:SerializeConsumptionHistory(citizen),

            -- Status flags
            isProtesting = citizen.isProtesting,
            hasEmigrated = citizen.hasEmigrated,
            productivity = citizen.productivity,
            allocationPriority = citizen.allocationPriority,
            consecutiveFailures = citizen.consecutiveFailures
        }
        table.insert(citizens, citizenData)
    end
    return citizens
end

function SaveManager:SerializeRelationships(citizen)
    if not citizen.relationships then
        return {}
    end

    local relationships = {}
    for targetId, rel in pairs(citizen.relationships) do
        relationships[tostring(targetId)] = {
            type = rel.type,
            strength = rel.strength,
            establishedCycle = rel.establishedCycle
        }
    end
    return relationships
end

function SaveManager:SerializeConsumptionHistory(citizen)
    if not citizen.consumptionHistory then
        return {}
    end

    -- Only keep last 20 entries
    local history = {}
    local startIndex = math.max(1, #citizen.consumptionHistory - 19)
    for i = startIndex, #citizen.consumptionHistory do
        local entry = citizen.consumptionHistory[i]
        table.insert(history, {
            cycle = entry.cycle,
            commodity = entry.commodity,
            quantity = entry.quantity,
            fatigueMultiplier = entry.fatigueMultiplier,
            allocationType = entry.allocationType
        })
    end
    return history
end

function SaveManager:SerializeImmigrationQueue(world)
    if not world.immigrationSystem then
        return {}
    end

    local queue = {}
    for _, applicant in ipairs(world.immigrationSystem.queue or {}) do
        table.insert(queue, {
            name = applicant.name,
            age = applicant.age,
            class = applicant.class,
            vocation = applicant.vocation,
            wealth = applicant.wealth,
            traits = applicant.traits,
            expiryDay = applicant.expiryDay,
            backstory = applicant.backstory
        })
    end
    return queue
end

function SaveManager:SerializeEventLog(world)
    local events = {}
    local log = world.eventLog or {}
    local startIndex = math.max(1, #log - 99)  -- Last 100 events

    for i = startIndex, #log do
        table.insert(events, log[i])
    end
    return events
end

-- =============================================================================
-- PHASE 9: SYSTEM SERIALIZATION
-- =============================================================================

function SaveManager:SerializeLandSystem(world)
    if not world.landSystem then
        return nil
    end

    -- Use LandSystem's own Serialize method if available
    if world.landSystem.Serialize then
        return world.landSystem:Serialize()
    end

    -- Fallback manual serialization
    return {
        gridColumns = world.landSystem.gridColumns,
        gridRows = world.landSystem.gridRows,
        plotWidth = world.landSystem.plotWidth,
        plotHeight = world.landSystem.plotHeight,
        plots = world.landSystem.plots,
        plotsByOwner = world.landSystem.plotsByOwner
    }
end

function SaveManager:SerializeHousingSystem(world)
    if not world.housingSystem then
        return nil
    end

    -- Use HousingSystem's own Serialize method if available
    if world.housingSystem.Serialize then
        return world.housingSystem:Serialize()
    end

    -- Fallback manual serialization
    return {
        housingAssignments = world.housingSystem.housingAssignments,
        buildingOccupancy = world.housingSystem.buildingOccupancy,
        relocationQueue = world.housingSystem.relocationQueue,
        familyUnits = world.housingSystem.familyUnits
    }
end

function SaveManager:SerializeEconomicsSystem(world)
    if not world.economicsSystem then
        return nil
    end

    -- Use EconomicsSystem's own Serialize method if available
    if world.economicsSystem.Serialize then
        return world.economicsSystem:Serialize()
    end

    -- Fallback: economics data is mostly on citizens, so this may be minimal
    return {
        lastClassCalculationCycle = world.economicsSystem.lastClassCalculationCycle,
        classThresholds = world.economicsSystem.classThresholds,
        economicSystemType = world.economicsSystem.economicSystemType
    }
end

function SaveManager:SaveToSlot(world, slotNumber)
    if slotNumber < 1 or slotNumber > self.MAX_SLOTS then
        return false, "Invalid slot number"
    end

    local saveData = self:CreateSaveData(world)
    local content = json.encode(saveData)
    local filename = self:GetSlotFilename(slotNumber)

    local success = love.filesystem.write(filename, content)
    if success then
        return true, "Saved to slot " .. slotNumber
    else
        return false, "Failed to save"
    end
end

function SaveManager:Quicksave(world)
    local saveData = self:CreateSaveData(world)
    local content = json.encode(saveData)

    local success = love.filesystem.write(self.QUICKSAVE_FILE, content)
    if success then
        return true, "Quicksave complete"
    else
        return false, "Quicksave failed"
    end
end

function SaveManager:Autosave(world)
    local saveData = self:CreateSaveData(world)
    local content = json.encode(saveData)

    local success = love.filesystem.write(self.AUTOSAVE_FILE, content)
    if success then
        self.lastAutosaveCycle = world.cycleCount or 0
        return true, "Autosave complete"
    else
        return false, "Autosave failed"
    end
end

function SaveManager:CheckAutosave(world)
    if not self.autosaveEnabled then
        return false
    end

    local currentCycle = world.cycleCount or 0
    if currentCycle - self.lastAutosaveCycle >= self.autosaveInterval then
        return self:Autosave(world)
    end
    return false
end

-- =============================================================================
-- LOADING
-- =============================================================================

function SaveManager:LoadFromSlot(slotNumber)
    local filename = self:GetSlotFilename(slotNumber)
    return self:LoadFromFile(filename)
end

function SaveManager:Quickload()
    return self:LoadFromFile(self.QUICKSAVE_FILE)
end

function SaveManager:LoadAutosave()
    return self:LoadFromFile(self.AUTOSAVE_FILE)
end

function SaveManager:LoadFromFile(filename)
    local content = love.filesystem.read(filename)
    if not content then
        return nil, "File not found"
    end

    local ok, data = pcall(json.decode, content)
    if not ok or not data then
        return nil, "Invalid save file"
    end

    return data, "Load successful"
end

function SaveManager:HasQuicksave()
    return love.filesystem.getInfo(self.QUICKSAVE_FILE) ~= nil
end

function SaveManager:HasAutosave()
    return love.filesystem.getInfo(self.AUTOSAVE_FILE) ~= nil
end

function SaveManager:GetQuicksaveInfo()
    local data, err = self:LoadFromFile(self.QUICKSAVE_FILE)
    if not data then return nil end

    return {
        townName = data.townName or "Unknown",
        cycleNumber = data.cycleNumber or 0,
        savedAt = data.savedAt or "Unknown"
    }
end

function SaveManager:GetAutosaveInfo()
    local data, err = self:LoadFromFile(self.AUTOSAVE_FILE)
    if not data then return nil end

    return {
        townName = data.townName or "Unknown",
        cycleNumber = data.cycleNumber or 0,
        savedAt = data.savedAt or "Unknown"
    }
end

-- =============================================================================
-- PHASE 9: DESERIALIZATION & WORLD RESTORATION
-- =============================================================================

function SaveManager:RestoreWorld(world, saveData)
    if not saveData then
        return false, "No save data provided"
    end

    -- Migrate old saves if needed
    saveData = self:MigrateOldSave(saveData)

    -- Basic town info
    world.townName = saveData.townName or "CraveTown"
    world.cycleCount = saveData.cycleNumber or 0
    world.gold = saveData.gold or 0
    world.isPaused = saveData.timeState and saveData.timeState.isPaused or false

    -- Game config
    if saveData.gameConfig then
        world.gameConfig = saveData.gameConfig
    end

    -- Time state
    if world.timeManager and saveData.timeState then
        world.timeManager.currentHour = saveData.timeState.currentHour or 6
        world.timeManager.dayNumber = saveData.timeState.dayNumber or 1
        world.timeManager.currentSlotIndex = saveData.timeState.currentSlotIndex or 1
        world.timeManager.currentSpeed = saveData.timeState.currentSpeed or "normal"
    end

    -- Inventory
    world.inventory = saveData.inventory or {}

    -- Event log
    world.eventLog = saveData.eventLog or {}

    -- Stats history
    world.statsHistory = saveData.statsHistory or {}

    -- Restore systems in order (land first, then buildings, then citizens)
    self:RestoreLandSystem(world, saveData.landSystem)
    self:RestoreBuildings(world, saveData.buildings)
    self:RestoreCitizens(world, saveData.citizens)
    self:RestoreHousingSystem(world, saveData.housingSystem)
    self:RestoreEconomicsSystem(world, saveData.economicsSystem)
    self:RestoreImmigrationQueue(world, saveData.immigrationQueue)

    -- Rebuild worker references after citizens are loaded
    self:RebuildWorkerReferences(world)

    return true, "World restored successfully"
end

function SaveManager:RestoreLandSystem(world, landData)
    if not landData then return end

    if world.landSystem then
        -- Use LandSystem's own Deserialize method if available
        if world.landSystem.Deserialize then
            world.landSystem:Deserialize(landData)
        else
            -- Fallback manual restore
            if landData.plots then
                world.landSystem.plots = landData.plots
            end
            if landData.plotsByOwner then
                world.landSystem.plotsByOwner = landData.plotsByOwner
            end
        end
    end
end

function SaveManager:RestoreBuildings(world, buildingsData)
    if not buildingsData then return end

    world.buildings = {}

    for _, bData in ipairs(buildingsData) do
        local building = {
            id = bData.id,
            typeId = bData.typeId,
            x = bData.x,
            y = bData.y,
            name = bData.name,
            stations = bData.stations,
            isPaused = bData.isPaused,
            priority = bData.priority,
            workers = {},  -- Will be rebuilt after citizens are loaded
            workerIds = bData.workers,  -- Store IDs temporarily

            -- Phase 9: Ownership data
            ownerId = bData.ownerId,
            landPlotId = bData.landPlotId,

            -- Phase 9: Housing-specific data
            isHousing = bData.isHousing,
            housingQuality = bData.housingQuality,
            housingCapacity = bData.housingCapacity,
            rentPerOccupant = bData.rentPerOccupant,
            occupants = bData.occupants or {}
        }

        table.insert(world.buildings, building)
    end
end

function SaveManager:RestoreCitizens(world, citizensData)
    if not citizensData then return end

    world.citizens = {}

    for _, cData in ipairs(citizensData) do
        local citizen = {
            id = cData.id,
            name = cData.name,
            age = cData.age,
            vocation = cData.vocation,
            traits = cData.traits,

            -- Phase 9: Emergent class (migrated from old class if needed)
            emergentClass = cData.emergentClass,

            -- Phase 9: Economics data
            wealth = cData.economics and cData.economics.wealth or 0,
            liquidAssets = cData.economics and cData.economics.liquidAssets or 0,
            fixedAssets = cData.economics and cData.economics.fixedAssets or 0,
            incomePerCycle = cData.economics and cData.economics.incomePerCycle or 0,
            expensesPerCycle = cData.economics and cData.economics.expensesPerCycle or 0,
            lastEconomicsCalculation = cData.economics and cData.economics.lastCalculatedCycle or 0,

            -- Craving state
            cravings = cData.cravings,
            baseCravings = cData.baseCravings,
            currentCravings = cData.currentCravings,
            satisfaction = cData.satisfaction,
            fatigueState = cData.fatigueState,
            commodityMultipliers = cData.commodityMultipliers,

            -- Position
            x = cData.x,
            y = cData.y,

            -- Work assignment (store ID for later resolution)
            workplaceId = cData.workplaceId,

            -- Possessions
            possessions = cData.possessions,
            activeEffects = cData.activeEffects,

            -- Phase 9: Housing assignment
            housingId = cData.housingId,
            rentPaid = cData.rentPaid,
            housingSatisfaction = cData.housingSatisfaction,

            -- Phase 9: Land ownership
            ownedPlotIds = cData.ownedPlotIds or {},
            ownedBuildingIds = cData.ownedBuildingIds or {},

            -- Phase 9: Relationships
            relationships = self:DeserializeRelationships(cData.relationships),

            -- Consumption history
            consumptionHistory = cData.consumptionHistory or {},

            -- Status flags
            isProtesting = cData.isProtesting,
            hasEmigrated = cData.hasEmigrated,
            productivity = cData.productivity,
            allocationPriority = cData.allocationPriority,
            consecutiveFailures = cData.consecutiveFailures
        }

        table.insert(world.citizens, citizen)
    end
end

function SaveManager:DeserializeRelationships(relData)
    if not relData then return {} end

    local relationships = {}
    for targetIdStr, rel in pairs(relData) do
        local targetId = tonumber(targetIdStr)
        if targetId then
            relationships[targetId] = {
                type = rel.type,
                strength = rel.strength,
                establishedCycle = rel.establishedCycle
            }
        end
    end
    return relationships
end

function SaveManager:RestoreHousingSystem(world, housingData)
    if not housingData then return end

    if world.housingSystem then
        -- Use HousingSystem's own Deserialize method if available
        if world.housingSystem.Deserialize then
            world.housingSystem:Deserialize(housingData)
        else
            -- Fallback manual restore
            world.housingSystem.housingAssignments = housingData.housingAssignments or {}
            world.housingSystem.buildingOccupancy = housingData.buildingOccupancy or {}
            world.housingSystem.relocationQueue = housingData.relocationQueue or {}
            world.housingSystem.familyUnits = housingData.familyUnits or {}
        end
    end
end

function SaveManager:RestoreEconomicsSystem(world, economicsData)
    if not economicsData then return end

    if world.economicsSystem then
        -- Use EconomicsSystem's own Deserialize method if available
        if world.economicsSystem.Deserialize then
            world.economicsSystem:Deserialize(economicsData)
        else
            -- Fallback manual restore
            world.economicsSystem.lastClassCalculationCycle = economicsData.lastClassCalculationCycle
            world.economicsSystem.classThresholds = economicsData.classThresholds
            world.economicsSystem.economicSystemType = economicsData.economicSystemType
        end
    end
end

function SaveManager:RestoreImmigrationQueue(world, queueData)
    if not queueData then return end

    if world.immigrationSystem then
        world.immigrationSystem.queue = {}
        for _, applicant in ipairs(queueData) do
            table.insert(world.immigrationSystem.queue, {
                name = applicant.name,
                age = applicant.age,
                class = applicant.class,
                vocation = applicant.vocation,
                wealth = applicant.wealth,
                traits = applicant.traits,
                expiryDay = applicant.expiryDay,
                backstory = applicant.backstory
            })
        end
    end
end

function SaveManager:RebuildWorkerReferences(world)
    -- Create citizen lookup by ID
    local citizensById = {}
    for _, citizen in ipairs(world.citizens or {}) do
        citizensById[citizen.id] = citizen
    end

    -- Rebuild building worker references
    for _, building in ipairs(world.buildings or {}) do
        if building.workerIds then
            building.workers = {}
            for _, workerId in ipairs(building.workerIds) do
                local worker = citizensById[workerId]
                if worker then
                    table.insert(building.workers, worker)
                    worker.workplace = building
                end
            end
            building.workerIds = nil  -- Clean up temporary storage
        end
    end

    -- Rebuild workplace references from workplaceId
    for _, citizen in ipairs(world.citizens or {}) do
        if citizen.workplaceId and not citizen.workplace then
            for _, building in ipairs(world.buildings or {}) do
                if building.id == citizen.workplaceId then
                    citizen.workplace = building
                    break
                end
            end
        end
    end
end

-- =============================================================================
-- PHASE 9: BACKWARDS COMPATIBILITY MIGRATION
-- =============================================================================
--
-- Migration Strategy:
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │                        SAVE VERSION MIGRATION                            │
-- ├──────────────────────────────────────────────────────────────────────────┤
-- │                                                                          │
-- │  Version Detection:                                                      │
-- │  ┌─────────────────────────────────────────────────────────────────┐    │
-- │  │ if saveData.version == nil or saveData.version < "0.2.0":       │    │
-- │  │   → Old save format detected                                     │    │
-- │  │   → Migrate citizens from class → emergent class                │    │
-- │  │   → Initialize economics from class defaults                     │    │
-- │  │   → Initialize empty land/housing data                          │    │
-- │  └─────────────────────────────────────────────────────────────────┘    │
-- │                                                                          │
-- │  Class → Economics Migration:                                            │
-- │  ┌───────────────┬─────────────────────────────────────────────────┐    │
-- │  │ Old Class     │ New Economics Defaults                          │    │
-- │  ├───────────────┼─────────────────────────────────────────────────┤    │
-- │  │ "Wealthy"     │ wealth: 5000, liquidAssets: 3000                │    │
-- │  │ "Comfortable" │ wealth: 1500, liquidAssets: 1000                │    │
-- │  │ "Modest"      │ wealth: 400, liquidAssets: 300                  │    │
-- │  │ "Poor"        │ wealth: 50, liquidAssets: 50                    │    │
-- │  │ (default)     │ wealth: 200, liquidAssets: 150                  │    │
-- │  └───────────────┴─────────────────────────────────────────────────┘    │
-- │                                                                          │
-- └──────────────────────────────────────────────────────────────────────────┘
--

function SaveManager:MigrateOldSave(saveData)
    local version = saveData.version or "0.0.0"

    -- No migration needed for current version
    if self:CompareVersions(version, self.CURRENT_VERSION) >= 0 then
        return saveData
    end

    -- Migrate from pre-0.2.0 (no economics/land/housing systems)
    if self:CompareVersions(version, "0.2.0") < 0 then
        saveData = self:MigrateToV020(saveData)
    end

    -- Update version to current
    saveData.version = self.CURRENT_VERSION

    return saveData
end

function SaveManager:CompareVersions(v1, v2)
    -- Parse version strings "X.Y.Z" and compare
    local function parseVersion(v)
        local major, minor, patch = v:match("(%d+)%.(%d+)%.(%d+)")
        return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
    end

    local m1, n1, p1 = parseVersion(v1)
    local m2, n2, p2 = parseVersion(v2)

    if m1 ~= m2 then return m1 - m2 end
    if n1 ~= n2 then return n1 - n2 end
    return p1 - p2
end

function SaveManager:MigrateToV020(saveData)
    -- Migrate citizens from old class system to economics
    if saveData.citizens then
        for _, citizen in ipairs(saveData.citizens) do
            self:MigrateCitizenEconomics(citizen)
        end
    end

    -- Initialize empty land system data if missing
    if not saveData.landSystem then
        saveData.landSystem = nil  -- Will use defaults
    end

    -- Initialize empty housing system data if missing
    if not saveData.housingSystem then
        saveData.housingSystem = nil  -- Will use defaults
    end

    -- Initialize empty economics system data if missing
    if not saveData.economicsSystem then
        saveData.economicsSystem = nil  -- Will use defaults
    end

    return saveData
end

function SaveManager:MigrateCitizenEconomics(citizen)
    -- Skip if already has economics data
    if citizen.economics and citizen.economics.wealth then
        return
    end

    -- Migration defaults based on old class
    local classDefaults = {
        ["Wealthy"] = {
            wealth = 5000,
            liquidAssets = 3000,
            fixedAssets = 2000,
            incomePerCycle = 50,
            expensesPerCycle = 30
        },
        ["Comfortable"] = {
            wealth = 1500,
            liquidAssets = 1000,
            fixedAssets = 500,
            incomePerCycle = 20,
            expensesPerCycle = 15
        },
        ["Modest"] = {
            wealth = 400,
            liquidAssets = 300,
            fixedAssets = 100,
            incomePerCycle = 10,
            expensesPerCycle = 8
        },
        ["Poor"] = {
            wealth = 50,
            liquidAssets = 50,
            fixedAssets = 0,
            incomePerCycle = 5,
            expensesPerCycle = 5
        }
    }

    local defaults = classDefaults[citizen.class] or {
        wealth = 200,
        liquidAssets = 150,
        fixedAssets = 50,
        incomePerCycle = 8,
        expensesPerCycle = 6
    }

    -- Set economics data
    citizen.economics = {
        wealth = defaults.wealth,
        liquidAssets = defaults.liquidAssets,
        fixedAssets = defaults.fixedAssets,
        incomePerCycle = defaults.incomePerCycle,
        expensesPerCycle = defaults.expensesPerCycle,
        lastCalculatedCycle = 0
    }

    -- Migrate class to emergentClass
    citizen.emergentClass = citizen.class
    -- Note: We keep citizen.class for backwards compat reads, but new saves won't use it
end

return SaveManager
