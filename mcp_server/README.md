# Cravetown MCP Server

An MCP (Model Context Protocol) server that allows AI agents like Claude to play and test the Cravetown game.

## Overview

This server creates a bridge between AI agents and the Cravetown game, enabling:

- **Visual Gameplay**: Watch Claude play the game in real-time on your screen
- **QA Testing**: Automated testing of game mechanics
- **Balance Analysis**: AI observation and suggestions for game balancing
- **Multi-agent Play**: Different AI personas playing as different characters

## Quick Start

### 1. Install the MCP Server

```bash
cd mcp_server
pip install -e .
```

Or install dependencies directly:
```bash
pip install mcp>=1.0.0
```

### 2. Launch the Game with MCP Enabled

```bash
cd /path/to/cravetown-love
CRAVETOWN_MCP=1 love .
```

Optional environment variables:
- `CRAVETOWN_MCP_PORT=9999` - TCP port (default: 9999)
- `CRAVETOWN_HEADLESS=1` - Run without rendering (faster for testing)

### 3. Configure Claude Code

Add to your Claude Code MCP settings (`~/.claude/settings.json` or project `.claude/settings.json`):

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

### 4. Play!

Now you can ask Claude to play the game:

> "Play Cravetown - start the main game, name the town 'ClaudeVille', and build a farm"

## Available Tools

### cravetown_game_state
Get a snapshot of the current game state including buildings, characters, inventory, and UI state.

### cravetown_send_input
Send low-level keyboard and mouse inputs to the game.

### cravetown_action
Execute high-level game actions like placing buildings, setting production, etc.

### cravetown_control
Control game execution - pause, resume, change speed, take screenshots.

### cravetown_query
Query specific game data like available buildings or inventory items.

### cravetown_logs
Get game event logs to understand what happened.

## Game Controls Reference

### Global Controls
| Key | Action |
|-----|--------|
| F5 | Hot reload (development) |
| F11 / Alt+Enter | Toggle fullscreen |
| Escape | Return to launcher / Cancel |

### Town View (Main Game)
| Key | Action |
|-----|--------|
| W / Up | Move camera up |
| A / Left | Move camera left |
| S / Down | Move camera down |
| D / Right | Move camera right |

### Building Placement
| Input | Action |
|-------|--------|
| Mouse move | Position building preview |
| Left click | Place building (if valid) |
| Right click | Cancel placement |
| W/S | Adjust height (variable buildings) |
| A/D | Adjust width (variable buildings) |

### Building Menu (Bottom Panel)
| Input | Action |
|-------|--------|
| Left click | Select building to place |
| Hover | Show building info tooltip |

### Modals
| Input | Action |
|-------|--------|
| Text input | Type text (name fields) |
| Enter | Confirm |
| Escape | Cancel |
| Left click | Select options |

## Example Session - Main Game

```python
# Claude's thought process when playing:

# 1. First, get the current state
state = await cravetown_game_state(depth="full")
# Shows: mode="launcher", available modes...

# 2. Start the main game
await cravetown_action(action="start_game")

# 3. Check state again - now in TownNameModal
state = await cravetown_game_state()
# Shows: ui_state.modal_open=true, modal_name="TownNameModal"

# 4. Set the town name
await cravetown_action(action="set_town_name", name="ClaudeVille")

# 5. Check available buildings
buildings = await cravetown_query(query_type="available_buildings")
# Shows: farm (can_afford=true), bakery (can_afford=true), ...

# 6. Start placing a farm
await cravetown_action(action="start_building_placement", building_type="farm")

# 7. Place it at a good location
await cravetown_action(action="place_building", x=100, y=100)

# 8. Select grain type when modal appears
await cravetown_action(action="select_grain", grain_type="wheat")

# 9. Continue playing...
```

## Consumption Prototype Mode

The consumption prototype is a specialized mode for testing and balancing the game's economic/satisfaction system. This is where AI agents can help analyze game balance.

### Launching Consumption Prototype

From the launcher, click on "Test Cache" or navigate via MCP actions.

### Example Session - Balance Analysis

```python
# Claude analyzing consumption balance:

# 1. Get current state
state = await cravetown_game_state(depth="full")
# Shows: mode="consumption_prototype", simulation, statistics, characters

# 2. Check initial stats
stats = await cravetown_query(query_type="consumption_stats")
# Shows: avg_satisfaction=0.75, gini_coefficient=0.12, ...

# 3. Add more characters to stress test
await cravetown_action(action="add_random_characters", count=10)

# 4. Inject resources to test allocation
await cravetown_action(action="inject_resource", commodity="bread", amount=50)
await cravetown_action(action="inject_resource", commodity="fish", amount=30)

# 5. Run some cycles
await cravetown_action(action="skip_cycles", count=5)

# 6. Check how resources were distributed
allocation = await cravetown_query(query_type="allocation_details")
# Shows: who got what and why

# 7. Test different allocation policies
await cravetown_action(action="apply_policy_preset", preset="rawlsian")
await cravetown_action(action="skip_cycles", count=5)
stats_rawlsian = await cravetown_query(query_type="consumption_stats")

await cravetown_action(action="apply_policy_preset", preset="utilitarian")
await cravetown_action(action="skip_cycles", count=5)
stats_utilitarian = await cravetown_query(query_type="consumption_stats")

# 8. Compare: rawlsian should have lower gini (more equal)
#    utilitarian should have higher avg satisfaction

# 9. Test crisis recovery
await cravetown_action(action="trigger_riot")  # Sets all satisfaction to 0
await cravetown_action(action="skip_cycles", count=20)
recovery_stats = await cravetown_query(query_type="consumption_stats")
# Analyze: How quickly does the system recover?

# 10. Check individual character details
char_id = state["characters"][0]["id"]
details = await cravetown_query(query_type="character", character_id=char_id, depth="full")
# Shows: all 6 layers of character model
```

### Character Model (6 Layers)

Each character in the consumption prototype has:

1. **Identity**: name, role
2. **Base Cravings**: 49 fine-grained cravings in 9 categories (Food, Drink, Shelter, etc.)
3. **Current Cravings**: Modified by consumption history
4. **Satisfaction**: 0.0-1.0 value affecting priority
5. **Commodity Multipliers**: Fatigue from repeated consumption
6. **Consumption History**: What/when consumed

### Balance Metrics to Watch

- **avg_satisfaction**: Overall happiness (target: 0.6-0.8)
- **gini_coefficient**: Inequality (lower = more fair, 0.0-0.3 is good)
- **min_satisfaction**: Worst-off character (should stay above 0.3)
- **characters_below_threshold**: Count of unhappy characters

### Policy Presets

| Preset | Priority | Good For |
|--------|----------|----------|
| equal | round_robin | Maximum fairness |
| needs_based | highest_craving | Addressing urgent needs |
| utilitarian | maximize total | Efficiency |
| rawlsian | lowest_satisfaction | Helping worst-off |

### Consumption Prototype Actions

| Action | Description |
|--------|-------------|
| pause_simulation | Pause consumption cycles |
| resume_simulation | Resume simulation |
| set_simulation_speed | Set speed (0.5, 1.0, 2.0, 5.0) |
| skip_cycles | Fast-forward N cycles |
| add_character | Add a character |
| add_random_characters | Add N random characters |
| inject_resource | Add commodity to inventory |
| set_allocation_policy | Configure allocation |
| apply_policy_preset | Apply preset |
| trigger_riot | Test crisis (satisfaction → 0) |
| trigger_civil_unrest | Test mild crisis (−30%) |
| set_all_satisfaction | Set everyone's satisfaction |

## Architecture

```
┌─────────────────────────────────────────┐
│         Claude / AI Agent               │
└─────────────────┬───────────────────────┘
                  │ MCP Protocol (stdio)
┌─────────────────▼───────────────────────┐
│      MCP Server (Python)                │
│  - cravetown_game_state                 │
│  - cravetown_send_input                 │
│  - cravetown_action                     │
│  - cravetown_control                    │
│  - cravetown_query                      │
│  - cravetown_logs                       │
└─────────────────┬───────────────────────┘
                  │ TCP (localhost:9999)
┌─────────────────▼───────────────────────┐
│      Love2D Game (Lua)                  │
│  - MCPBridge (TCP server)               │
│  - GameStateCapture                     │
│  - InputRelay                           │
│  - ActionHandler                        │
│  - EventLogger                          │
└─────────────────────────────────────────┘
```

## Development

### Testing the Connection

```python
# test_connection.py
import asyncio
from mcp_server.game_client import GameClient

async def test():
    client = GameClient()
    await client.connect()

    state = await client.get_state()
    print(f"Game mode: {state.get('mode')}")

    buildings = await client.query("available_buildings")
    print(f"Available buildings: {len(buildings.get('building_types', []))}")

    await client.close()

asyncio.run(test())
```

### Adding New Actions

1. Add action to `Protocol.lua` in `Protocol.GameActions`
2. Implement handler in `ActionHandler.lua`
3. Update tool description in `server.py`

### Adding New State Capture

1. Add capture method to `GameStateCapture.lua`
2. Include in the `capture()` method
3. Update the `include` options in tool schema

## Troubleshooting

### "Connection refused"
- Make sure the game is running with `CRAVETOWN_MCP=1`
- Check the port matches (default 9999)

### "Not connected to game"
- The MCP server will auto-connect when you use a tool
- If game was restarted, try using a tool again

### Actions not working
- Check `ui_state` in game state to see current mode
- Make sure you're in the right state (e.g., TownView for building placement)
- Check `available_actions` to see what's possible

## License

MIT License - Same as Cravetown game
