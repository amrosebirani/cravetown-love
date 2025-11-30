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
- Game mode (version_select, launcher, main, etc.)
- Town info (name, boundaries)
- Camera position
- Buildings (positions, types, workers, production)
- Characters (names, roles, workplaces)
- Inventory (all resources and quantities)
- UI state (active menus, modals)
- Available actions you can take

Use this to understand what's happening in the game before taking actions.""",
            inputSchema={
                "type": "object",
                "properties": {
                    "include": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "State sections to include: all, town, camera, buildings, characters, inventory, ui_state, available_actions, events, metrics, controls. Defaults to all."
                    },
                    "depth": {
                        "type": "string",
                        "enum": ["minimal", "summary", "full"],
                        "default": "summary",
                        "description": "Level of detail: minimal (IDs only), summary (key fields), full (all data including cravings)"
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
- select_mine_resource: Select resource for mine (params: resource_type)""",
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
                            "advance_time"
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
                    "name": {"type": "string", "description": "Name value (for set_town_name)"},
                    "grain_type": {"type": "string", "description": "Grain type to select"},
                    "resource_type": {"type": "string", "description": "Mine resource type to select"},
                    "ticks": {"type": "integer", "description": "Number of game ticks to advance"}
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

Query types:
- available_buildings: List all building types with costs and whether you can afford them
- building: Get details about a specific building (id required)
- inventory_item: Check quantity of a specific item (id required)
- available_actions: Get list of currently available actions""",
            inputSchema={
                "type": "object",
                "properties": {
                    "query_type": {
                        "type": "string",
                        "enum": ["building", "available_buildings", "inventory_item", "available_actions"],
                        "description": "Type of query"
                    },
                    "id": {
                        "type": "string",
                        "description": "Entity ID for specific queries (building ID or item name)"
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

Event types include:
- building_placed, building_removed
- resource_added, resource_removed
- state_changed, mode_changed
- grain_selected, modal_opened, modal_closed
- error, warning""",
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
                        "description": "Filter by event types"
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
