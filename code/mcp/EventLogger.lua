--
-- EventLogger.lua - Logs game events for MCP observation
-- Tracks all significant game events so AI agents can observe what happened
--

local Protocol = require("code.mcp.Protocol")

local EventLogger = {}
EventLogger.__index = EventLogger

local MAX_LOG_SIZE = 1000  -- Maximum events to keep in memory

function EventLogger:init(bridge)
    local self = setmetatable({}, EventLogger)
    self.bridge = bridge
    self.logs = {}
    self.lastReadFrame = 0
    self.enabled = true
    return self
end

function EventLogger:update(dt)
    -- Could add periodic state change detection here if needed
end

-- Log an event
function EventLogger:log(eventType, data)
    if not self.enabled then return end

    local event = {
        type = eventType,
        data = data or {},
        frame = self.bridge.frameCount,
        timestamp = love.timer.getTime()
    }

    table.insert(self.logs, event)

    -- Trim old logs if needed
    while #self.logs > MAX_LOG_SIZE do
        table.remove(self.logs, 1)
    end

    -- Send event to connected client immediately
    if self.bridge.connected then
        self.bridge:sendEvent(eventType, data)
    end

    -- Also print to console for debugging
    print(string.format("[MCP Event] %s: %s", eventType, self:dataToString(data)))
end

-- Helper to convert data table to string for logging
function EventLogger:dataToString(data)
    if not data then return "{}" end
    local parts = {}
    for k, v in pairs(data) do
        if type(v) == "table" then
            table.insert(parts, k .. "={...}")
        else
            table.insert(parts, k .. "=" .. tostring(v))
        end
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end

-- Get logs with filtering
function EventLogger:getLogs(params)
    params = params or {}
    local sinceFrame = params.since_frame or 0
    local eventTypes = params.event_types
    local limit = params.limit or 50

    local filtered = {}

    -- Iterate from newest to oldest
    for i = #self.logs, 1, -1 do
        local event = self.logs[i]

        if event.frame > sinceFrame then
            local include = true

            -- Filter by event type if specified
            if eventTypes and #eventTypes > 0 then
                include = false
                for _, et in ipairs(eventTypes) do
                    if event.type == et then
                        include = true
                        break
                    end
                end
            end

            if include then
                -- Insert at beginning to maintain chronological order
                table.insert(filtered, 1, event)
                if #filtered >= limit then
                    break
                end
            end
        end
    end

    return {
        events = filtered,
        count = #filtered,
        from_frame = sinceFrame,
        current_frame = self.bridge.frameCount,
        total_logged = #self.logs
    }
end

-- Get events since last read (for streaming updates)
function EventLogger:getRecentEvents()
    local recent = {}
    local lastFrame = self.lastReadFrame

    for _, event in ipairs(self.logs) do
        if event.frame > lastFrame then
            table.insert(recent, event)
        end
    end

    self.lastReadFrame = self.bridge.frameCount
    return recent
end

-- Clear all logs
function EventLogger:clear()
    self.logs = {}
    self.lastReadFrame = 0
end

-- Enable/disable logging
function EventLogger:setEnabled(enabled)
    self.enabled = enabled
end

-- Convenience methods for common events
function EventLogger:logBuildingPlaced(building)
    self:log(Protocol.EventTypes.BUILDING_PLACED, {
        id = building.mId or #(gTown and gTown.mBuildings or {}),
        type = building.mTypeId or (building.mBuildingType and building.mBuildingType.id) or "unknown",
        name = building.mName or "Unknown",
        x = building.mX,
        y = building.mY,
        width = building.mWidth,
        height = building.mHeight
    })
end

function EventLogger:logStateChanged(fromState, toState)
    self:log(Protocol.EventTypes.STATE_CHANGED, {
        from = fromState,
        to = toState
    })
end

function EventLogger:logModeChanged(fromMode, toMode)
    self:log(Protocol.EventTypes.MODE_CHANGED, {
        from = fromMode,
        to = toMode
    })
end

function EventLogger:logResourceChanged(commodityId, oldAmount, newAmount, action)
    local eventType = newAmount > oldAmount and Protocol.EventTypes.RESOURCE_ADDED or Protocol.EventTypes.RESOURCE_REMOVED
    self:log(eventType, {
        commodity = commodityId,
        old_amount = oldAmount,
        new_amount = newAmount,
        delta = newAmount - oldAmount,
        action = action or "unknown"
    })
end

function EventLogger:logModalOpened(modalName)
    self:log(Protocol.EventTypes.MODAL_OPENED, {
        modal = modalName
    })
end

function EventLogger:logModalClosed(modalName)
    self:log(Protocol.EventTypes.MODAL_CLOSED, {
        modal = modalName
    })
end

function EventLogger:logGrainSelected(buildingId, grainType)
    self:log(Protocol.EventTypes.GRAIN_SELECTED, {
        building_id = buildingId,
        grain_type = grainType
    })
end

function EventLogger:logError(message, details)
    self:log(Protocol.EventTypes.ERROR, {
        message = message,
        details = details
    })
end

return EventLogger
