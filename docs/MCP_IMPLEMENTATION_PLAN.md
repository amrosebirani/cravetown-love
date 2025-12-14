# Cravetown MCP Implementation Plan

This document provides a step-by-step implementation guide with code templates for each phase.

---

## Quick Start Checklist

- [ ] Phase 1: Create Lua MCP Bridge with TCP server
- [ ] Phase 1: Create Python MCP server skeleton
- [ ] Phase 1: Implement handshake protocol
- [ ] Phase 2: Implement game state serialization
- [ ] Phase 3: Implement input relay system
- [ ] Phase 4: Implement high-level actions
- [ ] Phase 5: Implement control and logging
- [ ] Phase 6: Testing and documentation

---

## Phase 1: Foundation

### Step 1.1: Create MCP Directory Structure

```bash
mkdir -p code/mcp
mkdir -p mcp_server/tools
mkdir -p examples
```

### Step 1.2: Create MCPBridge.lua

**File**: `code/mcp/MCPBridge.lua`

```lua
-- MCPBridge.lua
-- Main bridge module for MCP communication

local socket = require("socket")
local json = require("json")  -- Use existing json.lua in project

local MCPBridge = {}
MCPBridge.__index = MCPBridge

-- Configuration defaults
local DEFAULT_PORT = 9999
local DEFAULT_HOST = "127.0.0.1"

function MCPBridge:init(config)
    local self = setmetatable({}, MCPBridge)

    self.config = config or {}
    self.port = self.config.port or DEFAULT_PORT
    self.host = self.config.host or DEFAULT_HOST
    self.headless = self.config.headless or false

    self.server = nil
    self.client = nil
    self.connected = false
    self.buffer = ""

    self.frameCount = 0
    self.paused = false
    self.gameSpeed = 1.0

    -- Initialize subsystems
    self.stateCapture = require("code.mcp.GameStateCapture"):init(self)
    self.inputRelay = require("code.mcp.InputRelay"):init(self)
    self.actionHandler = require("code.mcp.ActionHandler"):init(self)
    self.eventLogger = require("code.mcp.EventLogger"):init(self)

    -- Start TCP server
    self:startServer()

    print("[MCP] Bridge initialized on " .. self.host .. ":" .. self.port)
    return self
end

function MCPBridge:startServer()
    self.server = socket.tcp()
    self.server:setoption("reuseaddr", true)

    local success, err = self.server:bind(self.host, self.port)
    if not success then
        print("[MCP] Failed to bind: " .. tostring(err))
        return false
    end

    self.server:listen(1)
    self.server:settimeout(0)  -- Non-blocking

    print("[MCP] Server listening on " .. self.host .. ":" .. self.port)
    return true
end

function MCPBridge:update(dt)
    self.frameCount = self.frameCount + 1

    -- Accept new connections
    if not self.connected then
        local client, err = self.server:accept()
        if client then
            self.client = client
            self.client:settimeout(0)
            self.connected = true
            print("[MCP] Client connected")
        end
    end

    -- Read incoming messages
    if self.connected then
        self:readMessages()
    end

    -- Update subsystems
    self.inputRelay:update(dt)
    self.eventLogger:update(dt)
end

function MCPBridge:readMessages()
    local data, err, partial = self.client:receive("*l")

    if data then
        self:handleMessage(data)
    elseif err == "closed" then
        print("[MCP] Client disconnected")
        self.connected = false
        self.client = nil
    elseif partial and #partial > 0 then
        self.buffer = self.buffer .. partial
    end
end

function MCPBridge:handleMessage(data)
    local success, message = pcall(json.decode, data)
    if not success then
        self:sendError(nil, "Invalid JSON: " .. tostring(message))
        return
    end

    -- Handle handshake
    if message.type == "handshake" then
        self:handleHandshake(message)
        return
    end

    -- Handle requests
    if message.type == "request" then
        self:handleRequest(message)
        return
    end

    self:sendError(message.id, "Unknown message type: " .. tostring(message.type))
end

function MCPBridge:handleHandshake(message)
    local response = {
        type = "handshake_ack",
        version = "1.0",
        game = "cravetown",
        state = "ready",
        frame = self.frameCount
    }
    self:send(response)
    print("[MCP] Handshake completed")
end

function MCPBridge:handleRequest(message)
    local method = message.method
    local params = message.params or {}
    local id = message.id

    local handlers = {
        get_state = function() return self.stateCapture:capture(params) end,
        send_input = function() return self.inputRelay:inject(params) end,
        send_action = function() return self.actionHandler:execute(params) end,
        control = function() return self:handleControl(params) end,
        query = function() return self.stateCapture:query(params) end,
        get_logs = function() return self.eventLogger:getLogs(params) end,
    }

    local handler = handlers[method]
    if handler then
        local success, result = pcall(handler)
        if success then
            self:sendResponse(id, true, result)
        else
            self:sendError(id, "Handler error: " .. tostring(result))
        end
    else
        self:sendError(id, "Unknown method: " .. tostring(method))
    end
end

function MCPBridge:handleControl(params)
    local command = params.command
    local value = params.value

    if command == "pause" then
        self.paused = true
        return {paused = true}
    elseif command == "resume" then
        self.paused = false
        return {paused = false}
    elseif command == "set_speed" then
        self.gameSpeed = math.max(0.1, math.min(10.0, value or 1.0))
        return {speed = self.gameSpeed}
    elseif command == "screenshot" then
        local filename = value or ("screenshot_" .. os.time() .. ".png")
        love.graphics.captureScreenshot(filename)
        return {filename = filename}
    elseif command == "reset" then
        -- Implement reset logic
        return {reset = true}
    elseif command == "headless" then
        self.headless = value
        return {headless = self.headless}
    end

    return {error = "Unknown command: " .. tostring(command)}
end

function MCPBridge:send(data)
    if self.connected and self.client then
        local encoded = json.encode(data) .. "\n"
        self.client:send(encoded)
    end
end

function MCPBridge:sendResponse(id, success, data)
    self:send({
        id = id,
        type = "response",
        success = success,
        data = data,
        timestamp = socket.gettime()
    })
end

function MCPBridge:sendError(id, message)
    self:send({
        id = id,
        type = "response",
        success = false,
        error = message,
        timestamp = socket.gettime()
    })
end

function MCPBridge:sendEvent(eventType, data)
    self:send({
        type = "event",
        event = eventType,
        data = data,
        frame = self.frameCount,
        timestamp = socket.gettime()
    })
end

function MCPBridge:isPaused()
    return self.paused
end

function MCPBridge:getGameSpeed()
    return self.gameSpeed
end

function MCPBridge:isHeadless()
    return self.headless
end

function MCPBridge:shutdown()
    if self.client then
        self.client:close()
    end
    if self.server then
        self.server:close()
    end
    print("[MCP] Bridge shutdown")
end

return MCPBridge
```

### Step 1.3: Create GameStateCapture.lua

**File**: `code/mcp/GameStateCapture.lua`

```lua
-- GameStateCapture.lua
-- Captures and serializes game state for MCP

local GameStateCapture = {}
GameStateCapture.__index = GameStateCapture

function GameStateCapture:init(bridge)
    local self = setmetatable({}, GameStateCapture)
    self.bridge = bridge
    return self
end

function GameStateCapture:capture(params)
    local include = params.include or {"all"}
    local depth = params.depth or "summary"

    local state = {
        frame = self.bridge.frameCount,
        timestamp = love.timer.getTime(),
        dt = love.timer.getDelta(),
        mode = gMode or "unknown",
        game_speed = self.bridge.gameSpeed,
        paused = self.bridge.paused
    }

    local includeAll = self:hasInclude(include, "all")

    -- Town state
    if includeAll or self:hasInclude(include, "town") then
        state.town = self:captureTown(depth)
    end

    -- Camera state
    if includeAll or self:hasInclude(include, "camera") then
        state.camera = self:captureCamera()
    end

    -- Buildings
    if includeAll or self:hasInclude(include, "buildings") then
        state.buildings = self:captureBuildings(depth, params.building_filter)
    end

    -- Characters
    if includeAll or self:hasInclude(include, "characters") then
        state.characters = self:captureCharacters(depth)
    end

    -- Inventory
    if includeAll or self:hasInclude(include, "inventory") then
        state.inventory = self:captureInventory()
    end

    -- UI State
    if includeAll or self:hasInclude(include, "ui_state") then
        state.ui_state = self:captureUIState()
    end

    -- Events since last capture
    if includeAll or self:hasInclude(include, "events") then
        state.events_since_last = self.bridge.eventLogger:getRecentEvents()
    end

    -- Metrics
    if includeAll or self:hasInclude(include, "metrics") then
        state.metrics = self:captureMetrics()
    end

    return state
end

function GameStateCapture:hasInclude(include, key)
    for _, v in ipairs(include) do
        if v == key then return true end
    end
    return false
end

function GameStateCapture:captureTown(depth)
    if not gTown then return nil end

    local town = {
        name = gTown.mName or "Unknown",
        bounds = {
            minX = gTown.mMinX or -1250,
            maxX = gTown.mMaxX or 1250,
            minY = gTown.mMinY or -1250,
            maxY = gTown.mMaxY or 1250
        }
    }

    if depth == "full" then
        -- Add more detail for full depth
        town.building_count = gTown.mBuildings and #gTown.mBuildings or 0
    end

    return town
end

function GameStateCapture:captureCamera()
    if not gCamera then return nil end

    return {
        x = gCamera.x or 0,
        y = gCamera.y or 0,
        scale = gCamera.scale or 1.0
    }
end

function GameStateCapture:captureBuildings(depth, filter)
    if not gTown or not gTown.mBuildings then return {} end

    local buildings = {}
    for i, building in ipairs(gTown.mBuildings) do
        local b = self:captureBuilding(building, i, depth)

        -- Apply filter if provided
        if filter then
            local include = true
            if filter.type and b.type ~= filter.type then
                include = false
            end
            if filter.placed ~= nil and b.placed ~= filter.placed then
                include = false
            end
            if include then
                table.insert(buildings, b)
            end
        else
            table.insert(buildings, b)
        end
    end

    return buildings
end

function GameStateCapture:captureBuilding(building, id, depth)
    local b = {
        id = id,
        type = building.mBuildingType and building.mBuildingType.id or "unknown",
        x = building.mX or 0,
        y = building.mY or 0,
        width = building.mWidth or 0,
        height = building.mHeight or 0,
        placed = building.mPlaced or false
    }

    if depth ~= "minimal" then
        b.workers = {}
        if building.mWorkers then
            for _, worker in ipairs(building.mWorkers) do
                table.insert(b.workers, worker.mId or worker.mName or "unknown")
            end
        end

        -- Production state
        if building.mProductionTimer then
            b.production = {
                active = building.mProductionTimer > 0,
                progress = building.mProductionTimer
            }
        end

        -- Bakery specific
        if building.mBakery then
            b.bakery = {
                active = building.mBakery.active,
                timer = building.mBakery.timer
            }
        end

        -- Farm grain type
        if building.mProducedGrain then
            b.grain_type = building.mProducedGrain
        end
    end

    return b
end

function GameStateCapture:captureCharacters(depth)
    -- This will depend on how characters are stored in your game
    -- Check if there's a global character list or if they're in buildings
    local characters = {}

    -- If characters are tracked globally
    if gCharacters then
        for i, char in ipairs(gCharacters) do
            table.insert(characters, self:captureCharacter(char, i, depth))
        end
    end

    -- Also check building workers
    if gTown and gTown.mBuildings then
        for _, building in ipairs(gTown.mBuildings) do
            if building.mWorkers then
                for _, worker in ipairs(building.mWorkers) do
                    -- Avoid duplicates if already captured
                    table.insert(characters, self:captureCharacter(worker, nil, depth))
                end
            end
        end
    end

    return characters
end

function GameStateCapture:captureCharacter(char, id, depth)
    local c = {
        id = id or char.mId or char.mName or "unknown",
        name = char.mName or "Unknown",
        type = char.mType or "unknown"
    }

    if depth ~= "minimal" then
        c.age = char.mAge
        c.workplace = char.mWorkplace and char.mWorkplace.mId or nil
        c.class = char.mClass
        c.status = char.mStatus
    end

    if depth == "full" then
        -- Include craving data if available
        if char.mCravings then
            c.cravings = {}
            for name, craving in pairs(char.mCravings) do
                c.cravings[name] = {
                    current = craving.current or 0,
                    base = craving.base or 0
                }
            end
        end
    end

    return c
end

function GameStateCapture:captureInventory()
    if not gTown or not gTown.mInventory then return {} end

    local inv = {}
    if gTown.mInventory.mStorage then
        for key, value in pairs(gTown.mInventory.mStorage) do
            inv[key] = value
        end
    end

    return inv
end

function GameStateCapture:captureUIState()
    local ui = {
        active_state = "unknown",
        stack = {},
        modal = nil,
        selected_building = nil
    }

    -- Get active state machine state
    if gStateMachine and gStateMachine.mCurrentState then
        ui.active_state = gStateMachine.mCurrentStateName or "unknown"
    end

    -- Get state stack
    if gStateStack and gStateStack.mStates then
        for i, state in ipairs(gStateStack.mStates) do
            table.insert(ui.stack, state.__name or "unknown")
        end
    end

    return ui
end

function GameStateCapture:captureMetrics()
    return {
        fps = love.timer.getFPS(),
        memory_kb = collectgarbage("count"),
        frame = self.bridge.frameCount
    }
end

function GameStateCapture:query(params)
    local queryType = params.query_type
    local id = params.id
    local filter = params.filter

    if queryType == "building" and id then
        if gTown and gTown.mBuildings and gTown.mBuildings[id] then
            return self:captureBuilding(gTown.mBuildings[id], id, "full")
        end
        return {error = "Building not found"}
    end

    if queryType == "available_buildings" then
        -- Return available building types
        local types = {}
        if BuildingTypes then
            for key, bt in pairs(BuildingTypes) do
                table.insert(types, {
                    id = bt.id or key,
                    name = bt.name or key,
                    width = bt.width,
                    height = bt.height
                })
            end
        end
        return {building_types = types}
    end

    if queryType == "inventory_item" and id then
        if gTown and gTown.mInventory then
            return {
                item = id,
                quantity = gTown.mInventory:Get(id) or 0
            }
        end
    end

    return {error = "Unknown query type: " .. tostring(queryType)}
end

return GameStateCapture
```

### Step 1.4: Create InputRelay.lua

**File**: `code/mcp/InputRelay.lua`

```lua
-- InputRelay.lua
-- Injects input events into the game

local InputRelay = {}
InputRelay.__index = InputRelay

function InputRelay:init(bridge)
    local self = setmetatable({}, InputRelay)
    self.bridge = bridge

    -- Injected input state
    self.injectedKeys = {}
    self.injectedMouseButtons = {}
    self.injectedMousePos = {x = 0, y = 0}

    -- Queue for timed releases
    self.releaseQueue = {}

    -- Override love functions to include injected input
    self:installHooks()

    return self
end

function InputRelay:installHooks()
    -- Store original functions
    self._originalKeyboardIsDown = love.keyboard.isDown

    -- Override keyboard.isDown
    local relay = self
    love.keyboard.isDown = function(key)
        if relay.injectedKeys[key] then
            return true
        end
        return relay._originalKeyboardIsDown(key)
    end
end

function InputRelay:update(dt)
    -- Process release queue
    local toRemove = {}
    for i, release in ipairs(self.releaseQueue) do
        release.time = release.time - dt
        if release.time <= 0 then
            if release.type == "key" then
                self:doKeyRelease(release.key)
            elseif release.type == "mouse" then
                self:doMouseRelease(release.button)
            end
            table.insert(toRemove, i)
        end
    end

    -- Remove processed releases (in reverse order)
    for i = #toRemove, 1, -1 do
        table.remove(self.releaseQueue, toRemove[i])
    end
end

function InputRelay:inject(params)
    local inputType = params.type or params.input_type
    local action = params.action

    if inputType == "key" then
        return self:handleKeyInput(params)
    elseif inputType == "mouse" then
        return self:handleMouseInput(params)
    end

    return {error = "Unknown input type: " .. tostring(inputType)}
end

function InputRelay:handleKeyInput(params)
    local action = params.action
    local key = params.key

    if not key then
        return {error = "Key is required"}
    end

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

    return {error = "Unknown key action: " .. tostring(action)}
end

function InputRelay:doKeyPress(key)
    self.injectedKeys[key] = true
    -- Trigger love.keypressed if defined
    if love.keypressed then
        love.keypressed(key, key, false)
    end
end

function InputRelay:doKeyRelease(key)
    self.injectedKeys[key] = false
    -- Trigger love.keyreleased if defined
    if love.keyreleased then
        love.keyreleased(key)
    end
end

function InputRelay:handleMouseInput(params)
    local action = params.action
    local x = params.x or love.mouse.getX()
    local y = params.y or love.mouse.getY()
    local button = params.button or 1

    if action == "move" then
        -- Update mouse position (note: this doesn't actually move the system cursor)
        self.injectedMousePos.x = x
        self.injectedMousePos.y = y
        if love.mousemoved then
            love.mousemoved(x, y, 0, 0, false)
        end
        return {success = true, action = "move", x = x, y = y}

    elseif action == "press" then
        self:doMousePress(x, y, button)
        return {success = true, action = "press", x = x, y = y, button = button}

    elseif action == "release" then
        self:doMouseRelease(button)
        return {success = true, action = "release", button = button}

    elseif action == "click" then
        local duration = params.duration or 0.05
        self:doMousePress(x, y, button)
        table.insert(self.releaseQueue, {
            type = "mouse",
            button = button,
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

    return {error = "Unknown mouse action: " .. tostring(action)}
end

function InputRelay:doMousePress(x, y, button)
    self.injectedMouseButtons[button] = true
    -- Set global mouse state if used in game
    if gMousePressed then
        gMousePressed = true
    end
    if love.mousepressed then
        love.mousepressed(x, y, button, false, 1)
    end
end

function InputRelay:doMouseRelease(button)
    self.injectedMouseButtons[button] = false
    if gMouseReleased then
        gMouseReleased = true
    end
    if love.mousereleased then
        love.mousereleased(self.injectedMousePos.x, self.injectedMousePos.y, button, false, 1)
    end
end

return InputRelay
```

### Step 1.5: Create ActionHandler.lua

**File**: `code/mcp/ActionHandler.lua`

```lua
-- ActionHandler.lua
-- Handles high-level game actions

local ActionHandler = {}
ActionHandler.__index = ActionHandler

function ActionHandler:init(bridge)
    local self = setmetatable({}, ActionHandler)
    self.bridge = bridge
    return self
end

function ActionHandler:execute(params)
    local action = params.action
    local actionParams = params.params or params

    local handlers = {
        place_building = function() return self:placeBuilding(actionParams) end,
        select_building = function() return self:selectBuilding(actionParams) end,
        assign_worker = function() return self:assignWorker(actionParams) end,
        remove_worker = function() return self:removeWorker(actionParams) end,
        set_production = function() return self:setProduction(actionParams) end,
        move_camera = function() return self:moveCamera(actionParams) end,
        zoom_camera = function() return self:zoomCamera(actionParams) end,
        open_menu = function() return self:openMenu(actionParams) end,
        close_menu = function() return self:closeMenu(actionParams) end,
        select_grain = function() return self:selectGrain(actionParams) end,
        hire_character = function() return self:hireCharacter(actionParams) end,
        advance_time = function() return self:advanceTime(actionParams) end,
    }

    local handler = handlers[action]
    if handler then
        return handler()
    end

    return {error = "Unknown action: " .. tostring(action)}
end

function ActionHandler:placeBuilding(params)
    local buildingType = params.building_type
    local x = params.x
    local y = params.y
    local width = params.width
    local height = params.height

    if not buildingType or not x or not y then
        return {error = "building_type, x, and y are required"}
    end

    -- Check if BuildingTypes exists and has the type
    if not BuildingTypes or not BuildingTypes[buildingType] then
        return {error = "Unknown building type: " .. tostring(buildingType)}
    end

    -- Create building through the game's building system
    local Building = require("code.Building")
    local building = Building:Create(BuildingTypes[buildingType])

    if width then building.mWidth = width end
    if height then building.mHeight = height end

    building.mX = x
    building.mY = y
    building.mPlaced = true

    -- Add to town
    if gTown and gTown.mBuildings then
        table.insert(gTown.mBuildings, building)
        local buildingId = #gTown.mBuildings

        -- Log event
        self.bridge.eventLogger:log("building_placed", {
            id = buildingId,
            type = buildingType,
            x = x,
            y = y
        })

        return {
            success = true,
            building_id = buildingId,
            type = buildingType
        }
    end

    return {error = "Could not add building to town"}
end

function ActionHandler:selectBuilding(params)
    local buildingId = params.building_id

    if not buildingId then
        return {error = "building_id is required"}
    end

    if gTown and gTown.mBuildings and gTown.mBuildings[buildingId] then
        -- Set as selected (depends on game implementation)
        gSelectedBuilding = gTown.mBuildings[buildingId]
        return {success = true, building_id = buildingId}
    end

    return {error = "Building not found: " .. tostring(buildingId)}
end

function ActionHandler:assignWorker(params)
    local characterId = params.character_id
    local buildingId = params.building_id

    if not characterId or not buildingId then
        return {error = "character_id and building_id are required"}
    end

    -- Implementation depends on game's worker assignment system
    -- This is a template - adapt to actual game logic

    return {error = "Worker assignment not yet implemented"}
end

function ActionHandler:removeWorker(params)
    local characterId = params.character_id

    if not characterId then
        return {error = "character_id is required"}
    end

    return {error = "Worker removal not yet implemented"}
end

function ActionHandler:setProduction(params)
    local buildingId = params.building_id
    local recipe = params.recipe

    if not buildingId or not recipe then
        return {error = "building_id and recipe are required"}
    end

    return {error = "Set production not yet implemented"}
end

function ActionHandler:moveCamera(params)
    local x = params.x
    local y = params.y

    if not x or not y then
        return {error = "x and y are required"}
    end

    if gCamera then
        gCamera.x = x
        gCamera.y = y
        return {success = true, x = x, y = y}
    end

    return {error = "Camera not available"}
end

function ActionHandler:zoomCamera(params)
    local scale = params.scale

    if not scale then
        return {error = "scale is required"}
    end

    if gCamera then
        gCamera.scale = math.max(0.1, math.min(5.0, scale))
        return {success = true, scale = gCamera.scale}
    end

    return {error = "Camera not available"}
end

function ActionHandler:openMenu(params)
    local menuName = params.menu_name

    if not menuName then
        return {error = "menu_name is required"}
    end

    -- Implementation depends on how menus are opened in the game
    return {error = "Menu opening not yet implemented"}
end

function ActionHandler:closeMenu(params)
    -- Close current menu/modal
    if gStateStack and #gStateStack.mStates > 0 then
        gStateStack:Pop()
        return {success = true}
    end

    return {error = "No menu to close"}
end

function ActionHandler:selectGrain(params)
    local buildingId = params.building_id
    local grainType = params.grain_type

    if not buildingId or not grainType then
        return {error = "building_id and grain_type are required"}
    end

    if gTown and gTown.mBuildings and gTown.mBuildings[buildingId] then
        local building = gTown.mBuildings[buildingId]
        building.mProducedGrain = grainType
        return {success = true, building_id = buildingId, grain_type = grainType}
    end

    return {error = "Building not found: " .. tostring(buildingId)}
end

function ActionHandler:hireCharacter(params)
    local characterType = params.character_type

    if not characterType then
        return {error = "character_type is required"}
    end

    -- Implementation depends on character creation system
    return {error = "Character hiring not yet implemented"}
end

function ActionHandler:advanceTime(params)
    local ticks = params.ticks or 1

    -- Manually advance game time
    for i = 1, ticks do
        if love.update then
            love.update(1/60)  -- Simulate 60fps tick
        end
    end

    return {success = true, ticks_advanced = ticks}
end

return ActionHandler
```

### Step 1.6: Create EventLogger.lua

**File**: `code/mcp/EventLogger.lua`

```lua
-- EventLogger.lua
-- Logs game events for MCP observation

local EventLogger = {}
EventLogger.__index = EventLogger

local MAX_LOG_SIZE = 1000

function EventLogger:init(bridge)
    local self = setmetatable({}, EventLogger)
    self.bridge = bridge
    self.logs = {}
    self.lastReadFrame = 0
    return self
end

function EventLogger:update(dt)
    -- Could add periodic state change detection here
end

function EventLogger:log(eventType, data)
    local event = {
        type = eventType,
        data = data,
        frame = self.bridge.frameCount,
        timestamp = love.timer.getTime()
    }

    table.insert(self.logs, event)

    -- Trim old logs if needed
    while #self.logs > MAX_LOG_SIZE do
        table.remove(self.logs, 1)
    end

    -- Send event to connected client
    self.bridge:sendEvent(eventType, data)
end

function EventLogger:getLogs(params)
    local sinceFrame = params.since_frame or 0
    local eventTypes = params.event_types
    local limit = params.limit or 50

    local filtered = {}

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
        current_frame = self.bridge.frameCount
    }
end

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

function EventLogger:clear()
    self.logs = {}
end

return EventLogger
```

### Step 1.7: Create Protocol.lua

**File**: `code/mcp/Protocol.lua`

```lua
-- Protocol.lua
-- Message protocol definitions

local Protocol = {}

Protocol.VERSION = "1.0"

Protocol.MessageTypes = {
    HANDSHAKE = "handshake",
    HANDSHAKE_ACK = "handshake_ack",
    REQUEST = "request",
    RESPONSE = "response",
    EVENT = "event"
}

Protocol.Methods = {
    GET_STATE = "get_state",
    SEND_INPUT = "send_input",
    SEND_ACTION = "send_action",
    CONTROL = "control",
    QUERY = "query",
    GET_LOGS = "get_logs"
}

Protocol.EventTypes = {
    BUILDING_PLACED = "building_placed",
    BUILDING_REMOVED = "building_removed",
    WORKER_ASSIGNED = "worker_assigned",
    WORKER_REMOVED = "worker_removed",
    PRODUCTION_STARTED = "production_started",
    PRODUCTION_COMPLETE = "production_complete",
    RESOURCE_ADDED = "resource_added",
    RESOURCE_REMOVED = "resource_removed",
    CHARACTER_HIRED = "character_hired",
    CHARACTER_FIRED = "character_fired",
    CRAVING_SATISFIED = "craving_satisfied",
    CRAVING_UNFULFILLED = "craving_unfulfilled",
    STATE_CHANGED = "state_changed",
    UI_ACTION = "ui_action",
    ERROR = "error"
}

return Protocol
```

### Step 1.8: Create Python MCP Server

**File**: `mcp_server/server.py`

```python
#!/usr/bin/env python3
"""
Cravetown MCP Server

This server provides MCP tools for interacting with the Cravetown game.
"""

import asyncio
import json
import os
from typing import Any
from mcp.server import Server
from mcp.types import Tool, TextContent
from mcp.server.stdio import stdio_server

from game_client import GameClient

# Initialize MCP server
app = Server("cravetown-mcp")

# Game client instance
game_client: GameClient | None = None


async def get_game_client() -> GameClient:
    """Get or create game client connection."""
    global game_client
    if game_client is None or not game_client.connected:
        host = os.environ.get("CRAVETOWN_HOST", "localhost")
        port = int(os.environ.get("CRAVETOWN_PORT", "9999"))
        game_client = GameClient(host, port)
        await game_client.connect()
    return game_client


@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available MCP tools."""
    return [
        Tool(
            name="cravetown_game_state",
            description="Get the current game state snapshot including town, buildings, characters, inventory, and UI state.",
            inputSchema={
                "type": "object",
                "properties": {
                    "include": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "State sections to include: all, town, camera, buildings, characters, inventory, ui_state, events, metrics. Defaults to all."
                    },
                    "depth": {
                        "type": "string",
                        "enum": ["minimal", "summary", "full"],
                        "default": "summary",
                        "description": "Level of detail: minimal (IDs only), summary (key fields), full (all data)"
                    },
                    "building_filter": {
                        "type": "object",
                        "description": "Filter buildings by properties like type or placed status"
                    }
                }
            }
        ),
        Tool(
            name="cravetown_send_input",
            description="Send low-level input events (keyboard/mouse) to the game.",
            inputSchema={
                "type": "object",
                "properties": {
                    "input_type": {
                        "type": "string",
                        "enum": ["key", "mouse"],
                        "description": "Type of input event"
                    },
                    "action": {
                        "type": "string",
                        "enum": ["press", "release", "tap", "click", "move", "scroll"],
                        "description": "Input action to perform"
                    },
                    "key": {
                        "type": "string",
                        "description": "Key name for keyboard input (e.g., 'w', 'space', 'escape')"
                    },
                    "x": {"type": "number", "description": "X coordinate for mouse input"},
                    "y": {"type": "number", "description": "Y coordinate for mouse input"},
                    "button": {
                        "type": "integer",
                        "description": "Mouse button (1=left, 2=right, 3=middle)"
                    },
                    "dx": {"type": "number", "description": "Delta X for scroll"},
                    "dy": {"type": "number", "description": "Delta Y for scroll"},
                    "duration": {
                        "type": "number",
                        "description": "Duration for tap/click actions in seconds"
                    }
                },
                "required": ["input_type", "action"]
            }
        ),
        Tool(
            name="cravetown_action",
            description="Execute a high-level game action like placing buildings, assigning workers, or controlling the camera.",
            inputSchema={
                "type": "object",
                "properties": {
                    "action": {
                        "type": "string",
                        "enum": [
                            "place_building", "select_building", "assign_worker",
                            "remove_worker", "set_production", "move_camera",
                            "zoom_camera", "open_menu", "close_menu",
                            "select_grain", "hire_character", "advance_time"
                        ],
                        "description": "Action to perform"
                    },
                    "building_type": {"type": "string", "description": "Type of building to place"},
                    "building_id": {"type": "integer", "description": "ID of building to interact with"},
                    "character_id": {"type": "string", "description": "ID of character"},
                    "x": {"type": "number", "description": "X coordinate"},
                    "y": {"type": "number", "description": "Y coordinate"},
                    "width": {"type": "number", "description": "Building width"},
                    "height": {"type": "number", "description": "Building height"},
                    "scale": {"type": "number", "description": "Camera zoom scale"},
                    "menu_name": {"type": "string", "description": "Name of menu to open"},
                    "grain_type": {"type": "string", "description": "Type of grain to select"},
                    "character_type": {"type": "string", "description": "Type of character to hire"},
                    "ticks": {"type": "integer", "description": "Number of ticks to advance"}
                },
                "required": ["action"]
            }
        ),
        Tool(
            name="cravetown_control",
            description="Control game execution: pause, resume, set speed, take screenshots, or reset the game.",
            inputSchema={
                "type": "object",
                "properties": {
                    "command": {
                        "type": "string",
                        "enum": ["pause", "resume", "set_speed", "screenshot", "reset", "headless"],
                        "description": "Control command to execute"
                    },
                    "value": {
                        "description": "Command-specific value (e.g., speed multiplier, filename, or boolean)"
                    }
                },
                "required": ["command"]
            }
        ),
        Tool(
            name="cravetown_query",
            description="Query specific game entities or available options.",
            inputSchema={
                "type": "object",
                "properties": {
                    "query_type": {
                        "type": "string",
                        "enum": ["building", "character", "inventory_item", "available_buildings", "available_actions"],
                        "description": "Type of query"
                    },
                    "id": {
                        "type": "string",
                        "description": "Entity ID for specific queries"
                    },
                    "filter": {
                        "type": "object",
                        "description": "Filter criteria"
                    }
                },
                "required": ["query_type"]
            }
        ),
        Tool(
            name="cravetown_logs",
            description="Get game event logs for observing what happened in the game.",
            inputSchema={
                "type": "object",
                "properties": {
                    "since_frame": {
                        "type": "integer",
                        "description": "Get events since this frame number"
                    },
                    "event_types": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Filter by event types (e.g., building_placed, production_complete)"
                    },
                    "limit": {
                        "type": "integer",
                        "default": 50,
                        "description": "Maximum number of events to return"
                    }
                }
            }
        )
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict[str, Any]) -> list[TextContent]:
    """Handle tool calls."""
    try:
        client = await get_game_client()

        if name == "cravetown_game_state":
            result = await client.request("get_state", arguments)
        elif name == "cravetown_send_input":
            result = await client.request("send_input", arguments)
        elif name == "cravetown_action":
            result = await client.request("send_action", arguments)
        elif name == "cravetown_control":
            result = await client.request("control", arguments)
        elif name == "cravetown_query":
            result = await client.request("query", arguments)
        elif name == "cravetown_logs":
            result = await client.request("get_logs", arguments)
        else:
            result = {"error": f"Unknown tool: {name}"}

        return [TextContent(
            type="text",
            text=json.dumps(result, indent=2)
        )]

    except Exception as e:
        return [TextContent(
            type="text",
            text=json.dumps({"error": str(e)})
        )]


async def main():
    """Run the MCP server."""
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())


if __name__ == "__main__":
    asyncio.run(main())
```

### Step 1.9: Create Game Client

**File**: `mcp_server/game_client.py`

```python
"""
Game client for connecting to Cravetown TCP server.
"""

import asyncio
import json
import uuid
from typing import Any


class GameClient:
    """Async TCP client for communicating with the Cravetown game."""

    def __init__(self, host: str = "localhost", port: int = 9999):
        self.host = host
        self.port = port
        self.reader: asyncio.StreamReader | None = None
        self.writer: asyncio.StreamWriter | None = None
        self.connected = False
        self.pending_requests: dict[str, asyncio.Future] = {}

    async def connect(self) -> bool:
        """Connect to the game server."""
        try:
            self.reader, self.writer = await asyncio.open_connection(
                self.host, self.port
            )
            self.connected = True

            # Start background reader
            asyncio.create_task(self._read_loop())

            # Perform handshake
            await self._handshake()

            return True
        except Exception as e:
            print(f"Connection failed: {e}")
            self.connected = False
            return False

    async def _handshake(self):
        """Perform handshake with game server."""
        handshake = {
            "type": "handshake",
            "version": "1.0",
            "client": "mcp-server"
        }
        await self._send(handshake)
        # Handshake response handled in read loop

    async def _send(self, data: dict):
        """Send data to the game server."""
        if self.writer:
            message = json.dumps(data) + "\n"
            self.writer.write(message.encode())
            await self.writer.drain()

    async def _read_loop(self):
        """Background task to read responses from server."""
        try:
            while self.connected and self.reader:
                line = await self.reader.readline()
                if not line:
                    break

                try:
                    message = json.loads(line.decode().strip())
                    await self._handle_message(message)
                except json.JSONDecodeError:
                    continue

        except Exception as e:
            print(f"Read error: {e}")
        finally:
            self.connected = False

    async def _handle_message(self, message: dict):
        """Handle incoming message from server."""
        msg_type = message.get("type")

        if msg_type == "handshake_ack":
            print(f"Connected to game: {message.get('game')}")
            return

        if msg_type == "response":
            request_id = message.get("id")
            if request_id and request_id in self.pending_requests:
                future = self.pending_requests.pop(request_id)
                if message.get("success"):
                    future.set_result(message.get("data"))
                else:
                    future.set_result({"error": message.get("error")})
            return

        if msg_type == "event":
            # Could store events or notify subscribers
            pass

    async def request(self, method: str, params: dict = None) -> Any:
        """Send a request and wait for response."""
        if not self.connected:
            await self.connect()

        request_id = str(uuid.uuid4())
        future: asyncio.Future = asyncio.get_event_loop().create_future()
        self.pending_requests[request_id] = future

        request = {
            "id": request_id,
            "type": "request",
            "method": method,
            "params": params or {}
        }

        await self._send(request)

        try:
            result = await asyncio.wait_for(future, timeout=10.0)
            return result
        except asyncio.TimeoutError:
            self.pending_requests.pop(request_id, None)
            return {"error": "Request timed out"}

    async def close(self):
        """Close the connection."""
        self.connected = False
        if self.writer:
            self.writer.close()
            await self.writer.wait_closed()
```

### Step 1.10: Create Package Files

**File**: `mcp_server/__init__.py`

```python
"""Cravetown MCP Server Package."""

__version__ = "0.1.0"
```

**File**: `mcp_server/pyproject.toml`

```toml
[project]
name = "cravetown-mcp-server"
version = "0.1.0"
description = "MCP server for Cravetown game integration"
requires-python = ">=3.10"
dependencies = [
    "mcp>=0.1.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project.scripts]
cravetown-mcp = "server:main"
```

---

## Phase 2-6: Remaining Implementation

See the main architecture document for detailed specifications for:
- Phase 2: Complete state capture for all game entities
- Phase 3: Full input relay system with timing
- Phase 4: All high-level action implementations
- Phase 5: Game control and event logging
- Phase 6: Testing and documentation

---

## Testing the Setup

### 1. Start the game with MCP enabled:

```bash
CRAVETOWN_MCP=1 love .
```

### 2. Test connection manually:

```python
# test_connection.py
import asyncio
from game_client import GameClient

async def test():
    client = GameClient()
    await client.connect()
    state = await client.request("get_state", {"depth": "summary"})
    print(state)

asyncio.run(test())
```

### 3. Configure Claude Code MCP:

Add to your MCP settings:

```json
{
  "mcpServers": {
    "cravetown": {
      "command": "python",
      "args": ["-m", "mcp_server.server"],
      "cwd": "/path/to/cravetown-love",
      "env": {
        "CRAVETOWN_HOST": "localhost",
        "CRAVETOWN_PORT": "9999"
      }
    }
  }
}
```

---

## Next Steps

1. Create the directory structure and files
2. Modify `main.lua` to integrate MCPBridge
3. Test basic connectivity
4. Iterate on state capture completeness
5. Add more high-level actions as needed
6. Create example Claude prompts for gameplay
