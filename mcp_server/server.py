#!/usr/bin/env python3
"""
Cravetown MCP Server

This server provides MCP (Model Context Protocol) tools for AI agents
to interact with the Cravetown game.

Usage:
1. Start the game with MCP enabled:
   CRAVETOWN_MCP=1 love /path/to/cravetown-love

2. Configure Claude Code to use this MCP server (see README)

3. Use the tools to observe and control the game!
"""

import asyncio
import json
import os
from typing import Any

from mcp.server import Server
from mcp.types import Tool, TextContent
from mcp.server.stdio import stdio_server

from .game_client import GameClient

# Initialize MCP server
app = Server("cravetown-mcp")

# Game client instance (singleton)
_game_client: GameClient | None = None


async def get_game_client() -> GameClient:
    """Get or create game client connection."""
    global _game_client
    if _game_client is None or not _game_client.connected:
        host = os.environ.get("CRAVETOWN_HOST", "localhost")
        port = int(os.environ.get("CRAVETOWN_PORT", "9999"))
        _game_client = GameClient(host, port)
        await _game_client.connect()
    return _game_client


@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available MCP tools for Cravetown."""
    return [
        Tool(
            name="cravetown_game_state",
            description="""Get the current game state snapshot.

Returns information about:
- Game mode (version_select, launcher, main, test_cache/consumption_prototype)
- Town info (name, boundaries)
- Camera position
- Buildings (positions, types, workers, production)
- Characters (names, roles, workplaces)
- Inventory (all resources and quantities)
- UI state (active menus, modals)
- Available actions you can take

=== CONSUMPTION PROTOTYPE MODE ===
When in consumption prototype mode (mode="consumption_prototype"), returns:
- simulation: {cycle, cycle_time, is_paused, speed}
- statistics: {total_consumption, total_cycles, avg_satisfaction, min/max_satisfaction, gini_coefficient}
- characters: Array of character data with 6-layer model:
  - Layer 1: Identity (name, role)
  - Layer 2: Base cravings (49 fine-grained dimensions)
  - Layer 3: Current cravings (modified by history)
  - Layer 4: Satisfaction (0.0-1.0)
  - Layer 5: Commodity multipliers (fatigue)
  - Layer 6: Consumption history
- inventory: Town commodity inventory
- allocation_policy: Current allocation settings
- available_actions: Consumption-specific actions

Use depth="full" for detailed craving/fatigue data, "summary" for overview, "minimal" for just IDs.""",
            inputSchema={
                "type": "object",
                "properties": {
                    "include": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "State sections to include: all, town, camera, buildings, characters, inventory, ui_state, available_actions, events, metrics, controls, simulation, statistics, allocation_policy. Defaults to all."
                    },
                    "depth": {
                        "type": "string",
                        "enum": ["minimal", "summary", "full"],
                        "default": "summary",
                        "description": "Level of detail: minimal (IDs only), summary (key fields), full (all data including cravings/fatigue)"
                    }
                }
            }
        ),
        Tool(
            name="cravetown_send_input",
            description="""Send low-level input events (keyboard/mouse) to the game.

KEYBOARD CONTROLS:
- Movement: w/a/s/d or arrow keys
- Confirm: return/enter
- Cancel: escape
- Hot reload: f5
- Fullscreen: f11

MOUSE ACTIONS:
- click: Single click at position
- press/release: Hold and release
- move: Move mouse cursor
- scroll: Mouse wheel scroll

Use this for precise control. For common actions, prefer cravetown_action.""",
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
                        "description": "Input action: tap (press+release), click (mouse press+release)"
                    },
                    "key": {
                        "type": "string",
                        "description": "Key name for keyboard: w,a,s,d, up,down,left,right, space, return, escape, etc."
                    },
                    "x": {"type": "number", "description": "X screen coordinate for mouse input"},
                    "y": {"type": "number", "description": "Y screen coordinate for mouse input"},
                    "button": {
                        "type": "integer",
                        "description": "Mouse button: 1=left, 2=right, 3=middle"
                    },
                    "duration": {
                        "type": "number",
                        "description": "Duration for tap/click in seconds (default 0.1)"
                    }
                },
                "required": ["input_type", "action"]
            }
        ),
        Tool(
            name="cravetown_action",
            description="""Execute a high-level game action.

BUILDING ACTIONS:
- start_building_placement: Begin placing a building (params: building_type)
- place_building: Place building at coordinates (params: x, y, width?, height?)
- cancel_placement: Cancel current building placement

CAMERA ACTIONS:
- move_camera: Move camera to position (params: x, y)
- move_camera_by: Move camera by offset (params: dx, dy)
- zoom_camera: Set zoom level (params: scale)

UI ACTIONS:
- open_menu: Open a menu (params: menu_name = inventory|character)
- close_menu: Close current menu/modal
- set_town_name: Set the town name (params: name) - works with TownNameModal

GAME FLOW:
- start_game: Start the main game from launcher
- return_to_launcher: Return to the launcher menu

PRODUCTION:
- select_grain: Select grain type for farm (params: grain_type)
- select_mine_resource: Select resource for mine (params: resource_type)

=== CONSUMPTION PROTOTYPE ACTIONS ===
(Only available in consumption_prototype mode)

SIMULATION CONTROL:
- pause_simulation: Pause the consumption simulation
- resume_simulation: Resume the simulation
- set_simulation_speed: Set speed (params: speed = 0.5, 1.0, 2.0, 5.0)
- skip_cycles: Fast-forward N cycles (params: count)

CHARACTER MANAGEMENT:
- add_character: Add a character (params: name?, base_cravings?)
- add_random_characters: Add multiple random characters (params: count)
- remove_character: Remove a character (params: character_id)

RESOURCE MANAGEMENT:
- inject_resource: Add commodity to inventory (params: commodity, amount)
- set_inventory: Set exact inventory (params: inventory = {commodity: amount})
- clear_inventory: Clear all inventory

ALLOCATION POLICY:
- set_allocation_policy: Configure allocation (params: priority_mode, fairness_weight, per_capita_cap, allow_partial)
- apply_policy_preset: Apply preset (params: preset = "equal"|"needs_based"|"utilitarian"|"rawlsian")

TESTING/DEBUG (for balance analysis):
- trigger_riot: Set all satisfaction to 0 (tests recovery)
- trigger_civil_unrest: Reduce all satisfaction by 30%
- set_all_satisfaction: Set all characters (params: value = 0.0-1.0)
- set_character_satisfaction: Set one character (params: character_id, value)
- modify_character_craving: Adjust craving (params: character_id, dimension, value)
- reset_fatigue: Reset all commodity fatigue multipliers
- reset_history: Clear consumption history""",
            inputSchema={
                "type": "object",
                "properties": {
                    "action": {
                        "type": "string",
                        "enum": [
                            "start_building_placement", "place_building", "cancel_placement",
                            "move_camera", "move_camera_by", "zoom_camera",
                            "open_menu", "close_menu", "set_town_name",
                            "start_game", "return_to_launcher",
                            "select_grain", "select_mine_resource",
                            "advance_time",
                            "pause_simulation", "resume_simulation", "set_simulation_speed", "skip_cycles",
                            "add_character", "add_random_characters", "remove_character",
                            "inject_resource", "set_inventory", "clear_inventory",
                            "set_allocation_policy", "apply_policy_preset",
                            "trigger_riot", "trigger_civil_unrest", "set_all_satisfaction",
                            "set_character_satisfaction", "modify_character_craving",
                            "reset_fatigue", "reset_history"
                        ],
                        "description": "The action to perform"
                    },
                    "building_type": {"type": "string", "description": "Building type ID (e.g., 'farm', 'bakery', 'lodge')"},
                    "x": {"type": "number", "description": "X world coordinate"},
                    "y": {"type": "number", "description": "Y world coordinate"},
                    "dx": {"type": "number", "description": "X offset for relative movement"},
                    "dy": {"type": "number", "description": "Y offset for relative movement"},
                    "width": {"type": "number", "description": "Building width (for variable-size buildings)"},
                    "height": {"type": "number", "description": "Building height (for variable-size buildings)"},
                    "scale": {"type": "number", "description": "Camera zoom scale (0.1 to 5.0)"},
                    "menu_name": {"type": "string", "description": "Menu name: inventory, character"},
                    "name": {"type": "string", "description": "Name value (for set_town_name or add_character)"},
                    "grain_type": {"type": "string", "description": "Grain type to select"},
                    "resource_type": {"type": "string", "description": "Mine resource type to select"},
                    "ticks": {"type": "integer", "description": "Number of game ticks to advance"},
                    "speed": {"type": "number", "description": "Simulation speed multiplier (0.5, 1.0, 2.0, 5.0)"},
                    "count": {"type": "integer", "description": "Number of cycles to skip or characters to add"},
                    "character_id": {"type": "string", "description": "Character ID for targeted actions"},
                    "commodity": {"type": "string", "description": "Commodity type (e.g., 'bread', 'fish', 'water')"},
                    "amount": {"type": "number", "description": "Amount of commodity to inject"},
                    "inventory": {"type": "object", "description": "Inventory map {commodity: amount}"},
                    "priority_mode": {"type": "string", "enum": ["highest_craving", "lowest_satisfaction", "oldest_consumption", "round_robin"], "description": "Allocation priority mode"},
                    "fairness_weight": {"type": "number", "description": "Fairness weight 0.0-1.0"},
                    "per_capita_cap": {"type": "integer", "description": "Max units per character per cycle"},
                    "allow_partial": {"type": "boolean", "description": "Allow partial craving satisfaction"},
                    "preset": {"type": "string", "enum": ["equal", "needs_based", "utilitarian", "rawlsian"], "description": "Policy preset name"},
                    "value": {"type": "number", "description": "Satisfaction value 0.0-1.0"},
                    "dimension": {"type": "string", "description": "Craving dimension to modify"},
                    "base_cravings": {"type": "object", "description": "Custom base cravings for new character"}
                },
                "required": ["action"]
            }
        ),
        Tool(
            name="cravetown_control",
            description="""Control game execution.

Commands:
- pause: Pause the game simulation
- resume: Resume the game simulation
- set_speed: Set game speed multiplier (value: 0.1 to 10.0)
- screenshot: Take a screenshot (value: filename, optional)
- reset: Reset game to launcher
- headless: Toggle headless mode (value: true/false) - disables rendering for faster testing
- quit: Quit the game""",
            inputSchema={
                "type": "object",
                "properties": {
                    "command": {
                        "type": "string",
                        "enum": ["pause", "resume", "set_speed", "screenshot", "reset", "headless", "quit"],
                        "description": "Control command to execute"
                    },
                    "value": {
                        "description": "Command-specific value (speed multiplier, filename, or boolean)"
                    }
                },
                "required": ["command"]
            }
        ),
        Tool(
            name="cravetown_query",
            description="""Query specific game data.

MAIN GAME QUERIES:
- available_buildings: List all building types with costs and affordability
- building: Get details about a specific building (id required)
- inventory_item: Check quantity of a specific item (id required)
- available_actions: Get list of currently available actions

=== CONSUMPTION PROTOTYPE QUERIES ===
(Only available in consumption_prototype mode)

- character: Get detailed character data (params: character_id, depth)
  Returns all 6 layers: identity, base_cravings, current_cravings, satisfaction, fatigue, history

- character_cravings: Get craving breakdown for character (params: character_id)
  Returns 49 fine-grained cravings and 9 coarse aggregates

- character_history: Get consumption history (params: character_id, limit?)
  Returns recent consumptions with timestamps and satisfaction deltas

- allocation_details: Get last allocation cycle details
  Shows how resources were distributed and why

- consumption_stats: Get simulation statistics
  Returns: avg/min/max satisfaction, gini coefficient, consumption totals

- satisfaction_distribution: Get distribution of satisfaction levels
  Returns histogram and characters at each level

- craving_heatmap: Get aggregate craving intensity across all characters
  Useful for identifying which commodities are most needed

- policy_comparison: Compare effects of different allocation policies
  Simulates N cycles with different policies (read-only, doesn't modify state)""",
            inputSchema={
                "type": "object",
                "properties": {
                    "query_type": {
                        "type": "string",
                        "enum": [
                            "building", "available_buildings", "inventory_item", "available_actions",
                            "character", "character_cravings", "character_history",
                            "allocation_details", "consumption_stats", "satisfaction_distribution",
                            "craving_heatmap", "policy_comparison"
                        ],
                        "description": "Type of query"
                    },
                    "id": {
                        "type": "string",
                        "description": "Entity ID for specific queries (building ID or item name)"
                    },
                    "character_id": {
                        "type": "string",
                        "description": "Character ID for character-specific queries"
                    },
                    "depth": {
                        "type": "string",
                        "enum": ["minimal", "summary", "full"],
                        "description": "Detail level for character query"
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Limit results (e.g., history entries)"
                    }
                },
                "required": ["query_type"]
            }
        ),
        Tool(
            name="cravetown_logs",
            description="""Get game event logs.

Returns a list of events that occurred in the game, useful for:
- Understanding what happened between observations
- Tracking building placements, resource changes, state transitions
- Debugging issues
- Analyzing consumption patterns and satisfaction changes

MAIN GAME EVENTS:
- building_placed, building_removed
- resource_added, resource_removed
- state_changed, mode_changed
- grain_selected, modal_opened, modal_closed
- error, warning

CONSUMPTION PROTOTYPE EVENTS:
- consumption_cycle_complete: A consumption cycle finished
- consumption_character_added: New character created
- consumption_resource_injected: Resources added to inventory
- consumption_policy_changed: Allocation policy modified
- consumption_riot_triggered: Riot event triggered
- consumption_civil_unrest: Civil unrest event triggered
- consumption_satisfaction_set: Satisfaction manually set
- consumption_craving_modified: Character craving modified
- consumption_simulation_paused: Simulation paused
- consumption_simulation_resumed: Simulation resumed
- consumption_speed_changed: Simulation speed changed
- consumption_allocation_complete: Allocation finished (with distribution details)""",
            inputSchema={
                "type": "object",
                "properties": {
                    "since_frame": {
                        "type": "integer",
                        "description": "Get events since this frame number (0 for all)"
                    },
                    "event_types": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Filter by event types (see list above)"
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

        # Format result as readable text
        return [TextContent(
            type="text",
            text=json.dumps(result, indent=2)
        )]

    except Exception as e:
        return [TextContent(
            type="text",
            text=json.dumps({"error": str(e), "type": type(e).__name__})
        )]


async def main():
    """Run the MCP server."""
    print("[Cravetown MCP] Starting server...")
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())


def run():
    """Entry point for the MCP server."""
    asyncio.run(main())


if __name__ == "__main__":
    run()
