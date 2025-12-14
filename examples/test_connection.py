#!/usr/bin/env python3
"""
Test Connection Script

Tests the basic connection to the Cravetown game via TCP.
Run this after starting the game with CRAVETOWN_MCP=1

Usage:
    python examples/test_connection.py
"""

import asyncio
import json
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from mcp_server.game_client import GameClient


async def main():
    print("=" * 50)
    print("Cravetown MCP Connection Test")
    print("=" * 50)

    # Create client
    client = GameClient(
        host=os.environ.get("CRAVETOWN_HOST", "localhost"),
        port=int(os.environ.get("CRAVETOWN_PORT", "9999"))
    )

    print(f"\nConnecting to {client.host}:{client.port}...")

    # Try to connect
    connected = await client.connect()
    if not connected:
        print("\nFailed to connect!")
        print("\nMake sure the game is running with:")
        print("  CRAVETOWN_MCP=1 love .")
        return

    print("Connected successfully!")

    # Get game state
    print("\n--- Game State ---")
    state = await client.get_state(depth="summary")
    print(f"Mode: {state.get('mode')}")
    print(f"Frame: {state.get('frame')}")
    print(f"Paused: {state.get('paused')}")

    if state.get('town'):
        print(f"Town: {state['town'].get('name')}")
        print(f"Buildings: {state['town'].get('building_count')}")

    if state.get('camera'):
        print(f"Camera: ({state['camera'].get('x'):.1f}, {state['camera'].get('y'):.1f})")

    if state.get('inventory'):
        print(f"Inventory items: {len(state['inventory'])}")

    if state.get('ui_state'):
        print(f"UI State: {state['ui_state'].get('active_state')}")
        print(f"Modal open: {state['ui_state'].get('modal_open')}")

    # Query available buildings
    print("\n--- Available Buildings ---")
    buildings = await client.query("available_buildings")
    if buildings.get('building_types'):
        for bt in buildings['building_types'][:5]:  # Show first 5
            affordable = "Yes" if bt.get('can_afford') else "No"
            print(f"  {bt.get('name')}: Can afford: {affordable}")
        if len(buildings['building_types']) > 5:
            print(f"  ... and {len(buildings['building_types']) - 5} more")

    # Get available actions
    print("\n--- Available Actions ---")
    if state.get('available_actions'):
        for action in state['available_actions']:
            print(f"  {action.get('action')}: {action.get('description')}")

    # Get recent logs
    print("\n--- Recent Events ---")
    logs = await client.get_logs(limit=5)
    if logs.get('events'):
        for event in logs['events']:
            print(f"  [{event.get('frame')}] {event.get('type')}: {event.get('data')}")
    else:
        print("  No recent events")

    print("\n--- Controls Reference ---")
    state_with_controls = await client.get_state(include=["controls"])
    if state_with_controls.get('controls'):
        controls = state_with_controls['controls']
        print("  Global: ESC=Back, F11=Fullscreen, F5=Hot reload")
        print("  Town View: WASD=Camera movement")
        print("  Placement: Click=Place, Right-click=Cancel")

    print("\n" + "=" * 50)
    print("Connection test complete!")
    print("=" * 50)

    await client.close()


if __name__ == "__main__":
    asyncio.run(main())
