--
-- InputRelay.lua - Injects input events into the game
-- Allows AI agents to control the game via keyboard/mouse simulation
--

local Protocol = require("code.mcp.Protocol")

local InputRelay = {}
InputRelay.__index = InputRelay

function InputRelay:init(bridge)
    local self = setmetatable({}, InputRelay)
    self.bridge = bridge

    -- Injected input state
    self.injectedKeys = {}
    self.injectedMouseButtons = {}
    self.injectedMousePos = {x = 0, y = 0}

    -- Queue for timed releases (for tap/click actions)
    self.releaseQueue = {}

    -- Track if hooks are installed
    self.hooksInstalled = false

    return self
end

-- Install hooks to override Love2D input functions
function InputRelay:installHooks()
    if self.hooksInstalled then return end

    -- Store original functions
    self._originalKeyboardIsDown = love.keyboard.isDown
    self._originalMouseIsDown = love.mouse.isDown
    self._originalMouseGetPosition = love.mouse.getPosition

    -- Override keyboard.isDown to include injected keys
    local relay = self
    love.keyboard.isDown = function(...)
        local keys = {...}
        for _, key in ipairs(keys) do
            if relay.injectedKeys[key] then
                return true
            end
        end
        return relay._originalKeyboardIsDown(...)
    end

    -- Override mouse.isDown to include injected buttons
    love.mouse.isDown = function(button)
        if relay.injectedMouseButtons[button] then
            return true
        end
        return relay._originalMouseIsDown(button)
    end

    -- Override mouse.getPosition to return injected position when set
    love.mouse.getPosition = function()
        -- If we have a recently injected mouse position, return it
        if relay.injectedMousePos.active then
            return relay.injectedMousePos.x, relay.injectedMousePos.y
        end
        return relay._originalMouseGetPosition()
    end

    self.hooksInstalled = true
    print("[MCP] Input hooks installed")
end

-- Update function - process release queue
function InputRelay:update(dt)
    -- Process release queue
    local toRemove = {}
    for i, release in ipairs(self.releaseQueue) do
        release.time = release.time - dt
        if release.time <= 0 then
            if release.type == "key" then
                self:doKeyRelease(release.key)
            elseif release.type == "mouse" then
                self:doMouseRelease(release.button, release.x, release.y)
            end
            table.insert(toRemove, i)
        end
    end

    -- Remove processed releases (in reverse order to preserve indices)
    for i = #toRemove, 1, -1 do
        table.remove(self.releaseQueue, toRemove[i])
    end

    -- Clear injected mouse position after a frame if no buttons are pressed
    if self.injectedMousePos.active then
        local hasButtons = false
        for _ in pairs(self.injectedMouseButtons) do
            hasButtons = true
            break
        end
        if not hasButtons then
            -- Keep active for one more frame, then clear
            if self.injectedMousePos.frameDelay then
                self.injectedMousePos.frameDelay = self.injectedMousePos.frameDelay - 1
                if self.injectedMousePos.frameDelay <= 0 then
                    self.injectedMousePos.active = false
                    self.injectedMousePos.frameDelay = nil
                end
            else
                self.injectedMousePos.frameDelay = 2  -- Keep for 2 more frames
            end
        end
    end
end

-- Main inject function - handles both key and mouse inputs
function InputRelay:inject(params)
    local inputType = params.type or params.input_type
    local action = params.action

    if inputType == "key" then
        return self:handleKeyInput(params)
    elseif inputType == "mouse" then
        return self:handleMouseInput(params)
    end

    return {success = false, error = "Unknown input type: " .. tostring(inputType)}
end

-- Handle keyboard input
function InputRelay:handleKeyInput(params)
    local action = params.action
    local key = params.key

    if not key then
        return {success = false, error = "Key is required"}
    end

    -- Validate key name
    key = string.lower(key)

    if action == "press" then
        self:doKeyPress(key)
        return {success = true, action = "press", key = key}

    elseif action == "release" then
        self:doKeyRelease(key)
        return {success = true, action = "release", key = key}

    elseif action == "tap" then
        local duration = params.duration or 0.1
        self:doKeyPress(key)
        table.insert(self.releaseQueue, {
            type = "key",
            key = key,
            time = duration
        })
        return {success = true, action = "tap", key = key, duration = duration}
    end

    return {success = false, error = "Unknown key action: " .. tostring(action)}
end

-- Simulate key press
function InputRelay:doKeyPress(key)
    self.injectedKeys[key] = true

    -- Trigger love.keypressed callback if defined
    if love.keypressed then
        love.keypressed(key, key, false)
    end

    self.bridge.eventLogger:log("input_key_press", {key = key})
end

-- Simulate key release
function InputRelay:doKeyRelease(key)
    self.injectedKeys[key] = nil

    -- Trigger love.keyreleased callback if defined
    if love.keyreleased then
        love.keyreleased(key)
    end
end

-- Handle mouse input
function InputRelay:handleMouseInput(params)
    local action = params.action
    local x = params.x or self.injectedMousePos.x
    local y = params.y or self.injectedMousePos.y
    local button = params.button or 1

    if action == "move" then
        self.injectedMousePos.x = x
        self.injectedMousePos.y = y
        self.injectedMousePos.active = true
        self.injectedMousePos.frameDelay = nil  -- Reset frame delay

        if love.mousemoved then
            love.mousemoved(x, y, 0, 0, false)
        end
        return {success = true, action = "move", x = x, y = y}

    elseif action == "press" then
        self:doMousePress(x, y, button)
        return {success = true, action = "press", x = x, y = y, button = button}

    elseif action == "release" then
        self:doMouseRelease(button, x, y)
        return {success = true, action = "release", x = x, y = y, button = button}

    elseif action == "click" then
        local duration = params.duration or 0.05
        self:doMousePress(x, y, button)
        table.insert(self.releaseQueue, {
            type = "mouse",
            button = button,
            x = x,
            y = y,
            time = duration
        })
        return {success = true, action = "click", x = x, y = y, button = button}

    elseif action == "scroll" then
        local dx = params.dx or 0
        local dy = params.dy or 0
        if love.wheelmoved then
            love.wheelmoved(dx, dy)
        end
        return {success = true, action = "scroll", dx = dx, dy = dy}
    end

    return {success = false, error = "Unknown mouse action: " .. tostring(action)}
end

-- Simulate mouse press
function InputRelay:doMousePress(x, y, button)
    self.injectedMouseButtons[button] = true
    self.injectedMousePos.x = x
    self.injectedMousePos.y = y
    self.injectedMousePos.active = true  -- Enable position override

    -- Set global mouse state (used by the game)
    gMousePressed = {x = x, y = y, button = button}

    if love.mousepressed then
        love.mousepressed(x, y, button, false, 1)
    end

    self.bridge.eventLogger:log("input_mouse_press", {x = x, y = y, button = button})
end

-- Simulate mouse release
function InputRelay:doMouseRelease(button, x, y)
    self.injectedMouseButtons[button] = nil

    x = x or self.injectedMousePos.x
    y = y or self.injectedMousePos.y

    -- Set global mouse state (used by the game)
    gMouseReleased = {x = x, y = y, button = button}

    if love.mousereleased then
        love.mousereleased(x, y, button, false, 1)
    end

    -- Keep position active for a short time after release to allow hover detection
    -- It will be cleared on next update cycle if no buttons are pressed
end

-- Simulate text input
function InputRelay:injectText(text)
    if love.textinput then
        for i = 1, #text do
            local char = text:sub(i, i)
            love.textinput(char)
        end
    end
    return {success = true, text = text}
end

-- Clear all injected inputs
function InputRelay:clearAll()
    self.injectedKeys = {}
    self.injectedMouseButtons = {}
    self.releaseQueue = {}
end

-- Get current injected state (for debugging)
function InputRelay:getState()
    local keys = {}
    for k, _ in pairs(self.injectedKeys) do
        table.insert(keys, k)
    end

    local buttons = {}
    for b, _ in pairs(self.injectedMouseButtons) do
        table.insert(buttons, b)
    end

    return {
        pressed_keys = keys,
        pressed_buttons = buttons,
        mouse_position = self.injectedMousePos,
        pending_releases = #self.releaseQueue
    }
end

return InputRelay
