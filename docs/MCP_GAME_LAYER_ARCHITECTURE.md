# Cravetown MCP Game Layer Architecture

## Executive Summary

This document outlines the architecture for a Model Context Protocol (MCP) server that enables AI agents (Claude, RL agents, test scripts) to interact with the Cravetown game. The system creates a bidirectional communication layer between external agents and the game engine, allowing for:

1. **QA Testing** - Automated gameplay testing and regression detection
2. **Game Balance Analysis** - AI observation and balancing suggestions
3. **Multi-agent Play** - Different AI personas playing as different characters
4. **Headless Testing** - CI/CD integration without rendering overhead

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Claude / AI Agent                             │
│   (Uses MCP tools to interact with game)                            │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ MCP Protocol
                           │ (JSON-RPC over stdio)
┌──────────────────────────▼──────────────────────────────────────────┐
│                     MCP Server (Python)                              │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  Tools:                                                      │    │
│  │  • game_state      - Get current game state snapshot         │    │
│  │  • send_input      - Send input events to game               │    │
│  │  • send_action     - Send high-level game actions            │    │
│  │  • game_control    - Pause/resume/speed/screenshot           │    │
│  │  • query_entities  - Query specific entities                 │    │
│  │  • get_logs        - Retrieve game event logs                │    │
│  │  • save_load       - Save/load game state                    │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                           │                                          │
│  ┌────────────────────────▼────────────────────────────────────┐    │
│  │  Communication Layer                                         │    │
│  │  • TCP Socket (default: localhost:9999)                     │    │
│  │  • Named Pipes (alternative for local-only)                 │    │
│  │  • JSON message protocol                                    │    │
│  └────────────────────────┬────────────────────────────────────┘    │
└──────────────────────────┼──────────────────────────────────────────┘
                           │
                           │ TCP/Pipe
                           │
┌──────────────────────────▼──────────────────────────────────────────┐
│                    Love2D Game (Lua)                                 │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  MCPBridge Module                                            │    │
│  │  • Connection management (server/client mode)               │    │
│  │  • Message serialization (JSON)                             │    │
│  │  • Request/response handling                                │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                           │                                          │
│  ┌────────────────────────▼────────────────────────────────────┐    │
│  │  GameStateCapture                                            │    │
│  │  • Serialize Town, Buildings, Characters, Inventory         │    │
│  │  • Capture UI state, active modals                          │    │
│  │  • Performance metrics                                      │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                           │                                          │
│  ┌────────────────────────▼────────────────────────────────────┐    │
│  │  InputRelay                                                  │    │
│  │  • Keyboard event injection                                 │    │
│  │  • Mouse event injection                                    │    │
│  │  • High-level action mapping                                │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                           │                                          │
│  ┌────────────────────────▼────────────────────────────────────┐    │
│  │  EventLogger                                                 │    │
│  │  • Game event capture                                       │    │
│  │  • State change notifications                               │    │
│  │  • Performance logging                                      │    │
│  └─────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Component Specifications

### 1. MCP Server (Python)

The MCP server acts as a bridge between Claude (or any MCP client) and the game.

**Location**: `/mcp_server/`

**Technology Stack**:
- Python 3.10+
- `mcp` library (official MCP SDK)
- `asyncio` for async communication
- `json` for message serialization

**Server Structure**:
```
mcp_server/
├── __init__.py
├── server.py              # Main MCP server entry point
├── game_client.py         # TCP client to connect to game
├── tools/
│   ├── __init__.py
│   ├── game_state.py      # game_state tool implementation
│   ├── send_input.py      # Input event tools
│   ├── send_action.py     # High-level action tools
│   ├── game_control.py    # Control tools (pause, speed, etc.)
│   ├── query.py           # Entity query tools
│   └── save_load.py       # Save/load state tools
├── protocol.py            # Message protocol definitions
└── config.py              # Configuration
```

---

### 2. Communication Protocol

#### Message Format

All messages use JSON with a standard envelope:

**Request (MCP Server → Game)**:
```json
{
  "id": "uuid-v4",
  "type": "request",
  "method": "get_state|send_input|send_action|control|query|save|load",
  "params": { ... },
  "timestamp": 1234567890.123
}
```

**Response (Game → MCP Server)**:
```json
{
  "id": "uuid-v4",
  "type": "response",
  "success": true,
  "data": { ... },
  "error": null,
  "timestamp": 1234567890.456
}
```

**Event (Game → MCP Server, unsolicited)**:
```json
{
  "id": "uuid-v4",
  "type": "event",
  "event": "state_changed|building_placed|character_hired|...",
  "data": { ... },
  "timestamp": 1234567890.789
}
```

#### Connection Protocol

1. Game starts TCP server on configured port (default 9999)
2. MCP server connects as client
3. Handshake exchange:
   - Client sends: `{"type": "handshake", "version": "1.0", "client": "mcp-server"}`
   - Server responds: `{"type": "handshake_ack", "version": "1.0", "game": "cravetown", "state": "ready"}`
4. Communication proceeds with request/response pattern
5. Game can push events asynchronously

---

### 3. Game State Capture System

#### State Snapshot Structure

```json
{
  "frame": 12345,
  "timestamp": 1234567890.123,
  "dt": 0.016,
  "mode": "main",
  "game_speed": 1.0,
  "paused": false,

  "town": {
    "name": "MyTown",
    "bounds": {
      "minX": -1250, "maxX": 1250,
      "minY": -1250, "maxY": 1250
    }
  },

  "camera": {
    "x": 100.5,
    "y": -50.2,
    "scale": 1.0
  },

  "buildings": [
    {
      "id": 1,
      "type": "farm",
      "x": 200,
      "y": 150,
      "width": 100,
      "height": 80,
      "placed": true,
      "workers": ["char_1", "char_2"],
      "production": {
        "active": true,
        "progress": 0.75,
        "output": "wheat"
      }
    }
  ],

  "characters": [
    {
      "id": "char_1",
      "name": "John Smith",
      "type": "farmer",
      "age": 32,
      "workplace": 1,
      "satisfaction": 0.8,
      "cravings": {
        "sustenance": { "current": 0.6, "base": 0.7 },
        "comfort": { "current": 0.4, "base": 0.5 }
      }
    }
  ],

  "inventory": {
    "wheat": 500,
    "bread": 120,
    "wood": 300
  },

  "ui_state": {
    "active_state": "TownViewState",
    "stack": ["TopBar", "BuildingMenu"],
    "modal": null,
    "selected_building": null
  },

  "events_since_last": [
    {"type": "production_complete", "building_id": 1, "item": "wheat", "amount": 10},
    {"type": "character_satisfied", "character_id": "char_1", "craving": "sustenance"}
  ],

  "metrics": {
    "fps": 60,
    "update_time_ms": 2.3,
    "render_time_ms": 4.1,
    "memory_mb": 128
  }
}
```

#### Selective State Queries

For efficiency, agents can request specific subsets:

```json
{
  "method": "get_state",
  "params": {
    "include": ["buildings", "inventory"],
    "building_filter": {"type": "farm"},
    "depth": "summary"  // "summary" | "full" | "minimal"
  }
}
```

---

### 4. Input Relay System

#### Low-Level Input Events

**Keyboard**:
```json
{
  "method": "send_input",
  "params": {
    "type": "key",
    "action": "press|release|tap",
    "key": "w|a|s|d|space|escape|return|...",
    "modifiers": ["ctrl", "shift", "alt"]
  }
}
```

**Mouse**:
```json
{
  "method": "send_input",
  "params": {
    "type": "mouse",
    "action": "press|release|click|move|scroll",
    "button": 1,  // 1=left, 2=right, 3=middle
    "x": 640,
    "y": 360,
    "dx": 0,  // for scroll
    "dy": -1  // for scroll
  }
}
```

#### High-Level Actions

The action system provides semantic game actions that map to sequences of inputs:

```json
{
  "method": "send_action",
  "params": {
    "action": "place_building",
    "building_type": "farm",
    "x": 200,
    "y": 150,
    "width": 100,  // optional for variable-size buildings
    "height": 80
  }
}
```

**Available Actions**:

| Action | Parameters | Description |
|--------|------------|-------------|
| `place_building` | `building_type, x, y, [width, height]` | Place a building at coordinates |
| `select_building` | `building_id` | Select a building |
| `assign_worker` | `character_id, building_id` | Assign worker to building |
| `remove_worker` | `character_id` | Remove worker from building |
| `set_production` | `building_id, recipe` | Set production recipe |
| `move_camera` | `x, y` | Move camera to position |
| `zoom_camera` | `scale` | Set camera zoom |
| `open_menu` | `menu_name` | Open a specific menu |
| `close_menu` | | Close current menu/modal |
| `select_grain` | `building_id, grain_type` | Select grain for farm |
| `hire_character` | `character_type` | Hire a new character |
| `advance_time` | `ticks` | Advance simulation time |

---

### 5. Game Control System

```json
{
  "method": "control",
  "params": {
    "command": "pause|resume|set_speed|screenshot|reset|quit",
    "value": 2.0  // for set_speed
  }
}
```

**Control Commands**:

| Command | Value | Description |
|---------|-------|-------------|
| `pause` | - | Pause game simulation |
| `resume` | - | Resume game simulation |
| `set_speed` | `float` | Set game speed multiplier (0.1 - 10.0) |
| `screenshot` | `filename` | Capture screenshot |
| `reset` | - | Reset to initial state |
| `quit` | - | Quit game |
| `set_mode` | `string` | Switch game mode |
| `headless` | `bool` | Enable/disable rendering |

---

### 6. Event Logging System

The game maintains an event log that agents can query:

```json
{
  "method": "get_logs",
  "params": {
    "since_frame": 12000,
    "event_types": ["building_placed", "production_complete"],
    "limit": 100
  }
}
```

**Event Types**:
- `building_placed` - Building was placed
- `building_removed` - Building was removed
- `worker_assigned` - Worker assigned to building
- `worker_removed` - Worker removed from building
- `production_started` - Production cycle started
- `production_complete` - Production cycle finished
- `resource_added` - Resource added to inventory
- `resource_removed` - Resource removed from inventory
- `character_hired` - New character hired
- `character_fired` - Character fired/left
- `craving_satisfied` - Character craving satisfied
- `craving_unfulfilled` - Character craving not met
- `state_changed` - Game state changed
- `ui_action` - UI interaction occurred
- `error` - Error occurred

---

## Love2D Integration

### Module Structure

```
code/
├── mcp/
│   ├── MCPBridge.lua          # Main bridge module
│   ├── GameStateCapture.lua   # State serialization
│   ├── InputRelay.lua         # Input injection
│   ├── ActionHandler.lua      # High-level action processing
│   ├── EventLogger.lua        # Event logging
│   └── Protocol.lua           # Message protocol
```

### MCPBridge Integration Points

**main.lua modifications**:

```lua
-- In love.load()
local MCPBridge = require("code.mcp.MCPBridge")

function love.load()
    -- Existing initialization...

    -- Initialize MCP bridge if enabled
    if os.getenv("CRAVETOWN_MCP") == "1" then
        gMCPBridge = MCPBridge:init({
            port = tonumber(os.getenv("CRAVETOWN_MCP_PORT")) or 9999,
            headless = os.getenv("CRAVETOWN_HEADLESS") == "1"
        })
    end
end

-- In love.update(dt)
function love.update(dt)
    -- Process MCP messages (non-blocking)
    if gMCPBridge then
        gMCPBridge:update(dt)
    end

    -- Existing update logic...
end

-- In love.draw()
function love.draw()
    if gMCPBridge and gMCPBridge.headless then
        return  -- Skip rendering in headless mode
    end

    -- Existing draw logic...
end

-- In love.quit()
function love.quit()
    if gMCPBridge then
        gMCPBridge:shutdown()
    end
end
```

### Input Injection

The InputRelay module injects inputs into Love2D's input system:

```lua
-- InputRelay.lua
local InputRelay = {}

-- Injected input state
InputRelay.injectedKeys = {}
InputRelay.injectedMouse = {x = 0, y = 0, buttons = {}}

function InputRelay:injectKeyPress(key)
    self.injectedKeys[key] = true
    -- Trigger love.keypressed callback
    if love.keypressed then
        love.keypressed(key, key, false)
    end
end

function InputRelay:injectKeyRelease(key)
    self.injectedKeys[key] = false
    -- Trigger love.keyreleased callback
    if love.keyreleased then
        love.keyreleased(key)
    end
end

function InputRelay:injectMouseClick(x, y, button)
    self.injectedMouse.x = x
    self.injectedMouse.y = y
    self.injectedMouse.buttons[button] = true

    if love.mousepressed then
        love.mousepressed(x, y, button, false, 1)
    end
end

-- Override love.keyboard.isDown to include injected keys
local originalIsDown = love.keyboard.isDown
function love.keyboard.isDown(key)
    if InputRelay.injectedKeys[key] then
        return true
    end
    return originalIsDown(key)
end

return InputRelay
```

---

## MCP Server Tools Specification

### Tool: `cravetown_game_state`

Get the current game state snapshot.

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "include": {
      "type": "array",
      "items": {"type": "string"},
      "description": "State sections to include: town, buildings, characters, inventory, ui_state, events, metrics"
    },
    "depth": {
      "type": "string",
      "enum": ["minimal", "summary", "full"],
      "default": "summary"
    }
  }
}
```

**Output**: Full or partial game state JSON

---

### Tool: `cravetown_send_input`

Send low-level input events to the game.

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "input_type": {
      "type": "string",
      "enum": ["key", "mouse"],
      "description": "Type of input"
    },
    "action": {
      "type": "string",
      "enum": ["press", "release", "tap", "click", "move", "scroll"],
      "description": "Input action"
    },
    "key": {
      "type": "string",
      "description": "Key name for keyboard input"
    },
    "x": {"type": "number", "description": "X coordinate for mouse"},
    "y": {"type": "number", "description": "Y coordinate for mouse"},
    "button": {"type": "integer", "description": "Mouse button (1=left, 2=right)"}
  },
  "required": ["input_type", "action"]
}
```

---

### Tool: `cravetown_action`

Execute a high-level game action.

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "action": {
      "type": "string",
      "enum": ["place_building", "select_building", "assign_worker", "remove_worker", "set_production", "move_camera", "open_menu", "close_menu", "hire_character"],
      "description": "Action to perform"
    },
    "params": {
      "type": "object",
      "description": "Action-specific parameters"
    }
  },
  "required": ["action"]
}
```

---

### Tool: `cravetown_control`

Control game execution.

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "command": {
      "type": "string",
      "enum": ["pause", "resume", "set_speed", "screenshot", "reset", "headless"],
      "description": "Control command"
    },
    "value": {
      "description": "Command-specific value"
    }
  },
  "required": ["command"]
}
```

---

### Tool: `cravetown_query`

Query specific entities or data.

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "query_type": {
      "type": "string",
      "enum": ["building", "character", "inventory_item", "available_buildings", "available_actions"],
      "description": "What to query"
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
```

---

### Tool: `cravetown_logs`

Get game event logs.

**Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "since_frame": {
      "type": "integer",
      "description": "Get events since this frame"
    },
    "event_types": {
      "type": "array",
      "items": {"type": "string"},
      "description": "Filter by event types"
    },
    "limit": {
      "type": "integer",
      "default": 50,
      "description": "Maximum events to return"
    }
  }
}
```

---

## Implementation Phases

### Phase 1: Foundation (Core Infrastructure)

**Goal**: Establish basic communication between MCP server and game

**Tasks**:
1. Create `MCPBridge.lua` with TCP server
2. Create basic Python MCP server with connection handling
3. Implement handshake protocol
4. Add `game_state` tool with minimal state capture
5. Test basic connectivity

**Deliverables**:
- Game can accept TCP connections
- MCP server can connect and receive state
- Basic state snapshot working

---

### Phase 2: State Capture (Read Operations)

**Goal**: Complete game state capture system

**Tasks**:
1. Implement `GameStateCapture.lua` with full serialization:
   - Town state
   - Buildings with production state
   - Characters with cravings
   - Inventory
   - UI state
2. Add selective state queries (include/exclude)
3. Add depth levels (minimal/summary/full)
4. Implement `cravetown_query` tool
5. Add performance metrics capture

**Deliverables**:
- Full game state accessible via MCP
- Efficient partial state queries
- Entity-specific queries working

---

### Phase 3: Input System (Write Operations)

**Goal**: Enable agents to interact with the game

**Tasks**:
1. Implement `InputRelay.lua`:
   - Keyboard injection
   - Mouse injection
   - Input state management
2. Implement `cravetown_send_input` tool
3. Test input injection with existing game states
4. Handle input timing and sequences

**Deliverables**:
- Agents can send keyboard/mouse inputs
- Inputs correctly affect game state
- Timing handled properly

---

### Phase 4: Action System (High-Level Commands)

**Goal**: Semantic game actions for easier agent interaction

**Tasks**:
1. Implement `ActionHandler.lua`:
   - Map actions to input sequences
   - Handle action validation
   - Coordinate with game state
2. Implement all high-level actions:
   - Building placement
   - Worker management
   - Production control
   - Camera control
   - Menu navigation
3. Implement `cravetown_action` tool
4. Add action result reporting

**Deliverables**:
- High-level actions working
- Actions properly validated
- Results reported to agent

---

### Phase 5: Control & Logging (Game Management)

**Goal**: Game control and observability

**Tasks**:
1. Implement game control:
   - Pause/resume
   - Speed control
   - Screenshot capture
   - Headless mode
   - Reset functionality
2. Implement `EventLogger.lua`:
   - Capture game events
   - Maintain event buffer
   - Support filtering
3. Implement `cravetown_control` tool
4. Implement `cravetown_logs` tool

**Deliverables**:
- Full game control via MCP
- Event logging working
- Headless mode functional

---

### Phase 6: Testing & Polish

**Goal**: Robust, well-tested system

**Tasks**:
1. Create test suite for MCP communication
2. Create example agent scripts
3. Document all tools thoroughly
4. Add error handling and recovery
5. Performance optimization
6. Create Claude-specific prompts/examples

**Deliverables**:
- Test suite passing
- Example scripts working
- Documentation complete
- System stable

---

## Use Case Examples

### 1. QA Testing

```python
# Automated QA test
async def test_building_placement():
    state = await mcp.call_tool("cravetown_game_state", {})

    # Place a farm
    result = await mcp.call_tool("cravetown_action", {
        "action": "place_building",
        "params": {"building_type": "farm", "x": 200, "y": 100}
    })

    # Verify placement
    new_state = await mcp.call_tool("cravetown_game_state", {
        "include": ["buildings"]
    })

    assert len(new_state["buildings"]) == len(state["buildings"]) + 1
    assert new_state["buildings"][-1]["type"] == "farm"
```

### 2. Claude Playing the Game

```
Claude receives game state, analyzes it, and decides actions:

"Looking at the current state, I see:
- 3 farms producing wheat
- 1 bakery with no workers
- Low bread inventory (50 units)
- 2 unemployed characters

I should assign a worker to the bakery to increase bread production.
Let me execute that action..."

[Uses cravetown_action tool with assign_worker]
```

### 3. Balance Analysis

```python
# Run game for 1000 ticks and analyze
for _ in range(1000):
    await mcp.call_tool("cravetown_control", {"command": "set_speed", "value": 10})
    await asyncio.sleep(0.1)

state = await mcp.call_tool("cravetown_game_state", {"depth": "full"})
logs = await mcp.call_tool("cravetown_logs", {"since_frame": 0})

# Analyze resource accumulation, character satisfaction, etc.
analysis = analyze_game_balance(state, logs)
```

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CRAVETOWN_MCP` | `0` | Enable MCP bridge (`1` to enable) |
| `CRAVETOWN_MCP_PORT` | `9999` | TCP port for MCP connection |
| `CRAVETOWN_HEADLESS` | `0` | Run without rendering |
| `CRAVETOWN_MCP_LOG` | `0` | Enable MCP message logging |

### MCP Server Configuration

```json
{
  "mcpServers": {
    "cravetown": {
      "command": "python",
      "args": ["-m", "cravetown_mcp_server"],
      "env": {
        "CRAVETOWN_HOST": "localhost",
        "CRAVETOWN_PORT": "9999"
      }
    }
  }
}
```

---

## Security Considerations

1. **Local Only**: TCP server binds to localhost only
2. **No Authentication**: Designed for local development use
3. **Sandboxed**: Game actions limited to game scope
4. **Rate Limiting**: Consider adding rate limits for production use

---

## Future Enhancements

1. **WebSocket Support**: For web-based agents
2. **Replay System**: Record and replay agent sessions
3. **Multi-Agent**: Multiple agents controlling different aspects
4. **Training Mode**: Optimized for RL training loops
5. **Visual State**: Screenshot-based state for vision models
6. **Diff-Based Updates**: Send only state changes for efficiency

---

## Appendix A: Message Examples

### Complete Interaction Flow

```
# 1. Connection
CLIENT -> {"type": "handshake", "version": "1.0", "client": "mcp-server"}
SERVER <- {"type": "handshake_ack", "version": "1.0", "game": "cravetown", "state": "ready"}

# 2. Get initial state
CLIENT -> {"id": "1", "type": "request", "method": "get_state", "params": {}}
SERVER <- {"id": "1", "type": "response", "success": true, "data": {...state...}}

# 3. Place a building
CLIENT -> {"id": "2", "type": "request", "method": "send_action", "params": {"action": "place_building", "building_type": "farm", "x": 200, "y": 100}}
SERVER <- {"id": "2", "type": "response", "success": true, "data": {"building_id": 5}}

# 4. Game event notification
SERVER <- {"type": "event", "event": "building_placed", "data": {"id": 5, "type": "farm"}}

# 5. Query the new building
CLIENT -> {"id": "3", "type": "request", "method": "query", "params": {"query_type": "building", "id": 5}}
SERVER <- {"id": "3", "type": "response", "success": true, "data": {...building details...}}
```

---

## Appendix B: Lua Socket Library

For TCP communication in Love2D, we'll use LuaSocket:

```lua
-- Using love2d's built-in socket or luasocket
local socket = require("socket")

-- Create TCP server
local server = socket.tcp()
server:bind("127.0.0.1", 9999)
server:listen(1)
server:settimeout(0)  -- Non-blocking

-- Accept connections in update loop
local client, err = server:accept()
if client then
    client:settimeout(0)
    -- Handle client...
end
```

---

## Appendix C: Directory Structure

```
cravetown-love/
├── main.lua                    # Modified to include MCP bridge
├── conf.lua
├── code/
│   ├── mcp/                    # NEW: MCP integration
│   │   ├── MCPBridge.lua
│   │   ├── GameStateCapture.lua
│   │   ├── InputRelay.lua
│   │   ├── ActionHandler.lua
│   │   ├── EventLogger.lua
│   │   └── Protocol.lua
│   ├── ... (existing code)
├── mcp_server/                 # NEW: Python MCP server
│   ├── __init__.py
│   ├── server.py
│   ├── game_client.py
│   ├── tools/
│   │   ├── __init__.py
│   │   ├── game_state.py
│   │   ├── send_input.py
│   │   ├── send_action.py
│   │   ├── game_control.py
│   │   ├── query.py
│   │   └── logs.py
│   ├── protocol.py
│   └── config.py
├── docs/
│   └── MCP_GAME_LAYER_ARCHITECTURE.md  # This document
└── examples/                   # NEW: Example scripts
    ├── qa_test.py
    ├── claude_player.py
    └── balance_analyzer.py
```
