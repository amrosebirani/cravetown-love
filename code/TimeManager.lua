--
-- TimeManager.lua
-- Centralized time management for the alpha prototype
-- Handles day/night cycle, time slots, and speed controls
--

local DataLoader = require("code/DataLoader")

TimeManager = {}
TimeManager.__index = TimeManager

function TimeManager:Create()
    local tm = setmetatable({}, TimeManager)

    -- Load time slots from data
    tm:LoadTimeSlots()

    -- Time state
    tm.currentHour = 6.0           -- 0-24 hours (starts at 6 AM)
    tm.dayNumber = 1
    tm.currentSlotIndex = 1        -- 1-indexed into timeSlots array
    tm.slotProgress = 0            -- 0-1 progress through current slot

    -- Speed settings (from design doc)
    -- Normal: 5 min real = 1 game day (300 sec)
    -- Fast: 2.5 min = 1 day (150 sec)
    -- Faster: 60 sec = 1 day
    tm.speedSettings = {
        normal = 300,    -- seconds per game day (1x)
        fast = 150,      -- seconds per game day (2x)
        faster = 60,     -- seconds per game day (5x)
        fastest = 30,    -- seconds per game day (10x)
        turbo = 15       -- seconds per game day (20x)
    }
    tm.currentSpeed = "normal"
    tm.secondsPerDay = tm.speedSettings.normal

    -- Pause state
    tm.isPaused = true

    -- Callbacks for events
    tm.onSlotChange = nil         -- function(newSlotIndex, newSlot)
    tm.onDayChange = nil          -- function(newDayNumber)
    tm.onHourChange = nil         -- function(newHour)

    -- Calculate initial slot
    tm:UpdateCurrentSlot()

    return tm
end

function TimeManager:LoadTimeSlots()
    local slots = DataLoader.loadTimeSlots()
    if slots and #slots > 0 then
        self.timeSlots = slots
    else
        -- Fallback minimal slots
        self.timeSlots = {
            {id = "early_morning", name = "Early Morning", startHour = 5, endHour = 8},
            {id = "morning", name = "Morning", startHour = 8, endHour = 12},
            {id = "afternoon", name = "Afternoon", startHour = 12, endHour = 17},
            {id = "evening", name = "Evening", startHour = 17, endHour = 21},
            {id = "night", name = "Night", startHour = 21, endHour = 24},
            {id = "late_night", name = "Late Night", startHour = 0, endHour = 5}
        }
    end

    -- Build lookup by ID
    self.slotById = {}
    for i, slot in ipairs(self.timeSlots) do
        slot.index = i
        self.slotById[slot.id] = slot
    end

    print("TimeManager loaded " .. #self.timeSlots .. " time slots")
end

-- =============================================================================
-- SPEED CONTROL
-- =============================================================================

function TimeManager:SetSpeed(speed)
    if self.speedSettings[speed] then
        self.currentSpeed = speed
        self.secondsPerDay = self.speedSettings[speed]
        print("TimeManager: Speed set to " .. speed .. " (" .. self.secondsPerDay .. " sec/day)")
    end
end

function TimeManager:TogglePause()
    self.isPaused = not self.isPaused
    return self.isPaused
end

function TimeManager:Pause()
    self.isPaused = true
end

function TimeManager:Resume()
    self.isPaused = false
end

-- =============================================================================
-- TIME UPDATE
-- =============================================================================

function TimeManager:Update(dt)
    if self.isPaused then return end

    -- Calculate hours per second based on speed
    -- 24 hours per day / secondsPerDay = hours per real second
    local hoursPerSecond = 24 / self.secondsPerDay

    local prevHour = math.floor(self.currentHour)
    local prevSlotIndex = self.currentSlotIndex

    -- Advance time
    self.currentHour = self.currentHour + (dt * hoursPerSecond)

    -- Handle day rollover
    if self.currentHour >= 24 then
        self.currentHour = self.currentHour - 24
        self.dayNumber = self.dayNumber + 1

        if self.onDayChange then
            self.onDayChange(self.dayNumber)
        end
    end

    -- Update current slot based on hour
    self:UpdateCurrentSlot()

    -- Fire slot change event
    if self.currentSlotIndex ~= prevSlotIndex then
        local newSlot = self.timeSlots[self.currentSlotIndex]
        if self.onSlotChange then
            self.onSlotChange(self.currentSlotIndex, newSlot)
        end
    end

    -- Fire hour change event
    local newHour = math.floor(self.currentHour)
    if newHour ~= prevHour then
        if self.onHourChange then
            self.onHourChange(newHour)
        end
    end
end

function TimeManager:UpdateCurrentSlot()
    local hour = self.currentHour

    for i, slot in ipairs(self.timeSlots) do
        local startH = slot.startHour
        local endH = slot.endHour

        -- Handle slots that wrap midnight
        if endH <= startH then
            -- Slot wraps midnight (e.g., 21-5)
            if hour >= startH or hour < endH then
                self.currentSlotIndex = i
                self:CalculateSlotProgress(slot)
                return
            end
        else
            -- Normal slot
            if hour >= startH and hour < endH then
                self.currentSlotIndex = i
                self:CalculateSlotProgress(slot)
                return
            end
        end
    end

    -- Fallback to first slot
    self.currentSlotIndex = 1
    self.slotProgress = 0
end

function TimeManager:CalculateSlotProgress(slot)
    local startH = slot.startHour
    local endH = slot.endHour
    local duration

    if endH <= startH then
        -- Wraps midnight
        duration = (24 - startH) + endH
        if self.currentHour >= startH then
            self.slotProgress = (self.currentHour - startH) / duration
        else
            self.slotProgress = (24 - startH + self.currentHour) / duration
        end
    else
        duration = endH - startH
        self.slotProgress = (self.currentHour - startH) / duration
    end

    self.slotProgress = math.max(0, math.min(1, self.slotProgress))
end

-- =============================================================================
-- GETTERS
-- =============================================================================

function TimeManager:GetCurrentSlot()
    return self.timeSlots[self.currentSlotIndex]
end

function TimeManager:GetCurrentSlotId()
    local slot = self:GetCurrentSlot()
    return slot and slot.id or "unknown"
end

function TimeManager:GetCurrentSlotName()
    local slot = self:GetCurrentSlot()
    return slot and slot.name or "Unknown"
end

function TimeManager:GetHour()
    return self.currentHour
end

function TimeManager:GetDay()
    return self.dayNumber
end

function TimeManager:GetTimeString()
    local hour = math.floor(self.currentHour)
    local minute = math.floor((self.currentHour % 1) * 60)
    return string.format("%02d:%02d", hour, minute)
end

function TimeManager:GetSlotCount()
    return #self.timeSlots
end

function TimeManager:GetSlotProgress()
    return self.slotProgress
end

-- Get seconds per slot at current speed
function TimeManager:GetSecondsPerSlot()
    return self.secondsPerDay / #self.timeSlots
end

-- =============================================================================
-- DAY/NIGHT COLORS
-- =============================================================================

function TimeManager:GetDayNightColor()
    local slot = self:GetCurrentSlot()
    if slot and slot.color then
        return slot.color[1], slot.color[2], slot.color[3]
    end

    -- Fallback based on hour
    local hour = self.currentHour
    if hour >= 6 and hour < 8 then
        return 1.0, 0.85, 0.6   -- Dawn
    elseif hour >= 8 and hour < 17 then
        return 1.0, 0.95, 0.85  -- Day
    elseif hour >= 17 and hour < 20 then
        return 1.0, 0.75, 0.5   -- Dusk
    else
        return 0.3, 0.3, 0.5    -- Night
    end
end

-- =============================================================================
-- SLOT QUERIES
-- =============================================================================

function TimeManager:GetSlotById(slotId)
    return self.slotById[slotId]
end

function TimeManager:GetAllSlots()
    return self.timeSlots
end

-- Check if a specific slot is the current one
function TimeManager:IsSlot(slotId)
    return self:GetCurrentSlotId() == slotId
end

return TimeManager
