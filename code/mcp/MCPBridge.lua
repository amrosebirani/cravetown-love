--
-- MCPBridge.lua - Main bridge module for MCP communication
-- Handles TCP server, message routing, and coordinates all MCP subsystems
--

local socket = require("socket")
local json = require("code.json")

local Protocol = require("code.mcp.Protocol")
local GameStateCapture = require("code.mcp.GameStateCapture")
local InputRelay = require("code.mcp.InputRelay")
local ActionHandler = require("code.mcp.ActionHandler")
local EventLogger = require("code.mcp.EventLogger")

local MCPBridge = {}
MCPBridge.__index = MCPBridge

-- Configuration defaults
local DEFAULT_PORT = 9999
local DEFAULT_HOST = "127.0.0.1"
local READ_BUFFER_SIZE = 4096

function MCPBridge:init(config)
    local self = setmetatable({}, MCPBridge)

    self.config = config or {}
    self.port = self.config.port or DEFAULT_PORT
    self.host = self.config.host or DEFAULT_HOST
    self.headless = self.config.headless or false

    -- TCP server and client state
    self.server = nil
    self.client = nil
    self.connected = false
    self.buffer = ""

    -- Game state
    self.frameCount = 0
    self.paused = false
    self.gameSpeed = 1.0
    self.lastMode = nil

    -- Initialize subsystems (pass self as bridge reference)
    self.eventLogger = EventLogger:init(self)
    self.stateCapture = GameStateCapture:init(self)
    self.inputRelay = InputRelay:init(self)
    self.actionHandler = ActionHandler:init(self)

    -- Start TCP server
    local success = self:startServer()
    if success then
        print("[MCP] Bridge initialized on " .. self.host .. ":" .. self.port)
        print("[MCP] Headless mode: " .. tostring(self.headless))
    else
        print("[MCP] Warning: Failed to start server")
    end

    return self
end

function MCPBridge:startServer()
    self.server = socket.tcp()
    self.server:setoption("reuseaddr", true)

    local success, err = self.server:bind(self.host, self.port)
    if not success then
        print("[MCP] Failed to bind to " .. self.host .. ":" .. self.port .. ": " .. tostring(err))
        return false
    end

    local listenSuccess, listenErr = self.server:listen(1)
    if not listenSuccess then
        print("[MCP] Failed to listen: " .. tostring(listenErr))
        return false
    end

    self.server:settimeout(0)  -- Non-blocking
    print("[MCP] Server listening on " .. self.host .. ":" .. self.port)
    return true
end

function MCPBridge:update(dt)
    self.frameCount = self.frameCount + 1

    -- Track mode changes
    if gMode ~= self.lastMode then
        self.eventLogger:logModeChanged(self.lastMode, gMode)
        self.lastMode = gMode
    end

    -- Accept new connections
    -- Guard against corrupted server socket (can happen after hot-reload)
    if not self.connected and self.server then
        local ok, client, err = pcall(function()
            return self.server:accept()
        end)
        if not ok then
            -- Server socket is corrupted, try to restart
            print("[MCP] Server socket corrupted, attempting restart...")
            self:startServer()
            return
        end
        if client then
            self.client = client
            self.client:settimeout(0)
            self.connected = true
            self.buffer = ""
            print("[MCP] Client connected")

            -- Install input hooks when client connects
            self.inputRelay:installHooks()

            -- Log connection event
            self.eventLogger:log("client_connected", {})
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
    -- Try to read data from client
    local data, err, partial = self.client:receive(READ_BUFFER_SIZE)

    if data then
        self.buffer = self.buffer .. data
    elseif partial and #partial > 0 then
        self.buffer = self.buffer .. partial
    elseif err == "closed" then
        print("[MCP] Client disconnected")
        self.connected = false
        self.client = nil
        self.buffer = ""
        return
    end

    -- Process complete messages (newline-delimited JSON)
    while true do
        local newlinePos = self.buffer:find("\n")
        if not newlinePos then
            break
        end

        local message = self.buffer:sub(1, newlinePos - 1)
        self.buffer = self.buffer:sub(newlinePos + 1)

        if #message > 0 then
            self:handleMessage(message)
        end
    end
end

function MCPBridge:handleMessage(data)
    local success, message = pcall(json.decode, data)
    if not success then
        self:sendError(nil, "Invalid JSON: " .. tostring(message))
        return
    end

    -- Handle handshake
    if message.type == Protocol.MessageTypes.HANDSHAKE then
        self:handleHandshake(message)
        return
    end

    -- Handle requests
    if message.type == Protocol.MessageTypes.REQUEST then
        self:handleRequest(message)
        return
    end

    self:sendError(message.id, "Unknown message type: " .. tostring(message.type))
end

function MCPBridge:handleHandshake(message)
    local response = {
        type = Protocol.MessageTypes.HANDSHAKE_ACK,
        version = Protocol.VERSION,
        game = "cravetown",
        state = "ready",
        frame = self.frameCount,
        mode = gMode,
        capabilities = {
            "state_capture",
            "input_relay",
            "actions",
            "control",
            "events"
        }
    }
    self:send(response)
    print("[MCP] Handshake completed with client version: " .. tostring(message.version))
end

function MCPBridge:handleRequest(message)
    local method = message.method
    local params = message.params or {}
    local id = message.id

    -- Method handlers
    local handlers = {
        [Protocol.Methods.GET_STATE] = function()
            return self.stateCapture:capture(params)
        end,

        [Protocol.Methods.SEND_INPUT] = function()
            return self.inputRelay:inject(params)
        end,

        [Protocol.Methods.SEND_ACTION] = function()
            return self.actionHandler:execute(params)
        end,

        [Protocol.Methods.CONTROL] = function()
            return self:handleControl(params)
        end,

        [Protocol.Methods.QUERY] = function()
            return self.stateCapture:query(params)
        end,

        [Protocol.Methods.GET_LOGS] = function()
            return self.eventLogger:getLogs(params)
        end,
    }

    local handler = handlers[method]
    if handler then
        local success, result = pcall(handler)
        if success then
            self:sendResponse(id, true, result)
        else
            self:sendError(id, "Handler error: " .. tostring(result))
            print("[MCP] Handler error for " .. method .. ": " .. tostring(result))
        end
    else
        self:sendError(id, "Unknown method: " .. tostring(method))
    end
end

function MCPBridge:handleControl(params)
    local command = params.command
    local value = params.value

    if command == Protocol.ControlCommands.PAUSE then
        self.paused = true
        return {paused = true}

    elseif command == Protocol.ControlCommands.RESUME then
        self.paused = false
        return {paused = false}

    elseif command == Protocol.ControlCommands.SET_SPEED then
        self.gameSpeed = math.max(0.1, math.min(10.0, tonumber(value) or 1.0))
        return {speed = self.gameSpeed}

    elseif command == Protocol.ControlCommands.SCREENSHOT then
        local filename = value or ("screenshot_" .. os.time() .. ".png")
        love.graphics.captureScreenshot(filename)
        self.eventLogger:log("screenshot_taken", {filename = filename})
        return {filename = filename}

    elseif command == Protocol.ControlCommands.RESET then
        -- Return to launcher and reinitialize
        ReturnToLauncher()
        return {reset = true, mode = gMode}

    elseif command == Protocol.ControlCommands.HEADLESS then
        self.headless = value == true
        return {headless = self.headless}

    elseif command == Protocol.ControlCommands.QUIT then
        love.event.quit()
        return {quit = true}
    end

    return {error = "Unknown command: " .. tostring(command)}
end

function MCPBridge:send(data)
    if self.connected and self.client then
        local encoded = json.encode(data) .. "\n"
        local success, err = self.client:send(encoded)
        if not success then
            print("[MCP] Send error: " .. tostring(err))
            if err == "closed" then
                self.connected = false
                self.client = nil
            end
        end
    end
end

function MCPBridge:sendResponse(id, success, data)
    self:send({
        id = id,
        type = Protocol.MessageTypes.RESPONSE,
        success = success,
        data = data,
        frame = self.frameCount,
        timestamp = socket.gettime()
    })
end

function MCPBridge:sendError(id, message)
    self:send({
        id = id,
        type = Protocol.MessageTypes.RESPONSE,
        success = false,
        error = message,
        frame = self.frameCount,
        timestamp = socket.gettime()
    })
end

function MCPBridge:sendEvent(eventType, data)
    self:send({
        type = Protocol.MessageTypes.EVENT,
        event = eventType,
        data = data,
        frame = self.frameCount,
        timestamp = socket.gettime()
    })
end

-- Getters for game control
function MCPBridge:isPaused()
    return self.paused
end

function MCPBridge:getGameSpeed()
    return self.gameSpeed
end

function MCPBridge:isHeadless()
    return self.headless
end

function MCPBridge:isConnected()
    return self.connected
end

-- Shutdown
function MCPBridge:shutdown()
    self.eventLogger:log("bridge_shutdown", {})

    if self.client then
        self.client:close()
        self.client = nil
    end
    if self.server then
        self.server:close()
        self.server = nil
    end
    self.connected = false
    print("[MCP] Bridge shutdown complete")
end

return MCPBridge
