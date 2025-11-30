#!/usr/bin/env python3
"""
Play Demo Script

Demonstrates how to play Cravetown programmatically via the MCP interface.
This script will:
1. Start the main game
2. Name the town
3. Build a farm and bakery
4. Move the camera around

Usage:
    python examples/play_demo.py
"""

import asyncio
import json
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from mcp_server.game_client import GameClient


async def wait_for_state(client, condition_fn, timeout=5.0, interval=0.1):
    """Wait for a game state condition to be met."""
    elapsed = 0
    while elapsed < timeout:
        state = await client.get_state()
        if condition_fn(state):
            return state
        await asyncio.sleep(interval)
        elapsed += interval
    return None


async def main():
    print("=" * 50)
    print("Cravetown Play Demo")
    print("=" * 50)

    client = GameClient()
    await client.connect()

    # Check current state
    state = await client.get_state()
    print(f"\nCurrent mode: {state.get('mode')}")

    # If in version_select, we need to manually progress
    if state.get('mode') == 'version_select':
        print("\nPlease select a version in the game first...")
        print("(Click on 'base' or another version)")

        # Wait for mode to change
        state = await wait_for_state(
            client,
            lambda s: s.get('mode') != 'version_select',
            timeout=30
        )
        if not state:
            print("Timeout waiting for version selection")
            return

    # If in launcher, start the main game
    if state.get('mode') == 'launcher':
        print("\nStarting main game...")
        result = await client.execute_action("start_game")
        print(f"Result: {result}")

        # Wait for mode to change to main
        await asyncio.sleep(0.5)
        state = await client.get_state()

    # Check if TownNameModal is open
    if state.get('mode') == 'main':
        ui_state = state.get('ui_state', {})
        if ui_state.get('modal_name') == 'TownNameModal':
            print("\nSetting town name to 'DemoTown'...")
            result = await client.execute_action("set_town_name", name="DemoTown")
            print(f"Result: {result}")
            await asyncio.sleep(0.5)

    # Now we should be in TownView
    state = await client.get_state()
    print(f"\nCurrent UI state: {state.get('ui_state', {}).get('active_state')}")

    # Move camera to see the town
    print("\nMoving camera to center...")
    await client.execute_action("move_camera", x=0, y=0)
    await asyncio.sleep(0.3)

    # Query available buildings
    print("\nChecking available buildings...")
    buildings = await client.query("available_buildings")
    if buildings.get('building_types'):
        affordable = [b for b in buildings['building_types'] if b.get('can_afford')]
        print(f"Can afford {len(affordable)} building types")

    # Try to place a farm
    if state.get('ui_state', {}).get('active_state') == 'TownView':
        print("\nStarting farm placement...")
        result = await client.execute_action("start_building_placement", building_type="farm")
        print(f"Result: {result}")

        if result.get('success'):
            await asyncio.sleep(0.3)

            # Place the farm
            print("Placing farm at (100, 100)...")
            result = await client.execute_action("place_building", x=100, y=100)
            print(f"Result: {result}")

            await asyncio.sleep(0.5)

            # Check if grain selection modal appeared
            state = await client.get_state()
            if state.get('ui_state', {}).get('modal_name') == 'GrainSelectionModal':
                print("Selecting wheat grain...")
                result = await client.execute_action("select_grain", grain_type="wheat")
                print(f"Result: {result}")

    # Get final state
    await asyncio.sleep(0.5)
    state = await client.get_state(depth="full")

    print("\n--- Final State ---")
    print(f"Mode: {state.get('mode')}")
    if state.get('town'):
        print(f"Town: {state['town'].get('name')}")
        print(f"Buildings: {state['town'].get('building_count')}")
    if state.get('buildings'):
        print("Buildings placed:")
        for b in state['buildings']:
            print(f"  - {b.get('name')} ({b.get('type')}) at ({b.get('x')}, {b.get('y')})")

    # Check inventory
    if state.get('inventory'):
        print("Inventory (non-zero):")
        for item, qty in state['inventory'].items():
            if qty > 0:
                print(f"  {item}: {qty}")

    print("\n" + "=" * 50)
    print("Demo complete!")
    print("=" * 50)

    await client.close()


if __name__ == "__main__":
    asyncio.run(main())
