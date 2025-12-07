--
-- SaveManager.lua
-- Handles saving and loading game state for CraveTown Alpha
--

local json = require("code.json")

SaveManager = {}
SaveManager.__index = SaveManager

-- Constants
SaveManager.MAX_SLOTS = 5
SaveManager.QUICKSAVE_FILE = "quicksave.json"
SaveManager.AUTOSAVE_FILE = "autosave.json"
SaveManager.SETTINGS_FILE = "settings.json"

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
        version = "0.1.0",
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

        -- Citizens
        citizens = self:SerializeCitizens(world),

        -- Immigration queue
        immigrationQueue = self:SerializeImmigrationQueue(world),

        -- Event log (last 100 events)
        eventLog = self:SerializeEventLog(world),

        -- Stats history
        statsHistory = world.statsHistory or {}
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
            priority = building.priority
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
            class = citizen.class,
            vocation = citizen.vocation,
            wealth = citizen.wealth,
            traits = citizen.traits,

            -- Craving state
            cravings = citizen.cravings,
            fatigueState = citizen.fatigueState,

            -- Position
            x = citizen.x,
            y = citizen.y,

            -- Work assignment
            workplaceId = citizen.workplace and citizen.workplace.id or nil,

            -- Possessions
            possessions = citizen.possessions
        }
        table.insert(citizens, citizenData)
    end
    return citizens
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

return SaveManager
