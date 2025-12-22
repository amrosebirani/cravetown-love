``# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Common commands

### Run the LÖVE game
- Run (from repo root):
  - `love .`
- Run with console output (useful for runtime warnings/logging):
  - `love --console .`

### Hot reload
- Hot reload is wired via `lurker` in `main.lua`.
- Manual reload: press `F5` (see `main.lua`).

### MCP-enabled game run (AI bridge)
- Start the game with the TCP MCP bridge enabled:
  - `CRAVETOWN_MCP=1 love .`
- Optional env vars:
  - `CRAVETOWN_MCP_PORT=9999`
  - `CRAVETOWN_HEADLESS=1` (skip rendering for faster automated testing)

### Build a distributable `.love`
- From repo root:
  - `zip -r build/cravetown.love . -x "build/*"`

### Formatting / linting
- Lua formatting is currently manual; if you introduce `stylua`, verify core entrypoints:
  - `stylua --verify main.lua conf.lua`

### “Tests”
- The game primarily uses manual playtesting:
  - Run `love .` after changes and sanity-check window sizing, input, and draw order.
- MCP sanity check (after starting the game with `CRAVETOWN_MCP=1`):
  - `python examples/test_connection.py`

## Info System (desktop app for editing game data)

The `info-system/` directory is a React + TypeScript + Vite frontend wrapped in Tauri.

From `info-system/`:
- Install deps:
  - `npm install`
- Run (recommended):
  - `npm run tauri:dev`
- Lint:
  - `npm run lint`
- Build:
  - `npm run tauri:build`

## MCP server (Python)

`mcp_server/` exposes an MCP server (for Claude/agents) that connects to the game’s TCP bridge.

- Install (editable):
  - `pip install -e mcp_server`
- Run:
  - `cravetown-mcp`
  - (or) `python -m mcp_server.server`

Environment variables used by the MCP server:
- `CRAVETOWN_HOST` (default `localhost`)
- `CRAVETOWN_PORT` (default `9999`)

## High-level architecture

### Runtime entrypoints
- `conf.lua` configures the LÖVE runtime (LÖVE 11.4, window defaults).
- `main.lua` is the main runtime router:
  - Sets up globals and one-time init in `love.load`.
  - Routes update/draw/input based on `gMode` (version selection, launcher, main game, prototypes/tests).
  - Initializes the MCP bridge when `CRAVETOWN_MCP=1`.

### Modes and state management
This repo uses two layers of “state”:
- **Mode router** (`gMode` in `main.lua`):
  - `version_select` → `launcher` → one of (`main`, `alpha`, `prototype2`, `test_cache`, etc.).
- **In-mode state machine** (main game):
  - `code/StateMachine.lua` manages the current world-state (`TownView`, `BuildingPlacement`).
  - `code/StateStack.lua` stacks UI states/modals (top bar, building menu, detail modals, etc.).

Key files:
- `code/Town.lua`: owns world bounds, natural features (river/forest/mines/mountains), and the town inventory/buildings list.
- `code/TownViewState.lua`: main camera movement + click-to-open building detail.
- `code/BuildingPlacementState.lua`: placement preview, collision/bounds checks, and final placement.

### Data model and “versions”
Game data lives under `data/` as JSON.

There are two important patterns:
- **Versioned data used by DataLoader**
  - `code/DataLoader.lua` loads JSON from `data/<activeVersion>/...`.
  - `data/versions.json` is the manifest shown in the startup version picker (`code/VersionSelector.lua`).
- **Top-level shared JSON (legacy / tooling)**
  - Some tooling (and the in-game `code/InfoSystemState.lua`) reads/writes top-level `data/*.json` (e.g. `data/building_recipes.json`, `data/commodities.json`).

When making data changes, verify which consumer you’re targeting:
- If the game path uses `DataLoader`, update the active version’s files under `data/<version>/`.
- If you’re updating the Info System apps, check whether they read top-level `data/*.json` or versioned data.

### MCP integration architecture
There are two pieces:
- **In-game TCP server**: `code/mcp/MCPBridge.lua` (enabled by `CRAVETOWN_MCP=1`) and its subsystems:
  - `code/mcp/GameStateCapture.lua` (serialize game state)
  - `code/mcp/InputRelay.lua` (inject input)
  - `code/mcp/ActionHandler.lua` (high-level actions)
  - `code/mcp/EventLogger.lua`
  - `code/mcp/Protocol.lua` (shared enums/strings)
- **Agent-facing MCP server**: `mcp_server/` (Python) connects to the TCP bridge and exposes tools like `cravetown_game_state` and `cravetown_action`.

If you add/extend actions, the project docs describe the intended workflow:
- Add new action constants in `code/mcp/Protocol.lua`.
- Implement handling in `code/mcp/ActionHandler.lua`.
- Update Python tool schemas/descriptions in `mcp_server/server.py`.

## Repo conventions (from AGENTS.md)
- Keep gameplay loop in `main.lua` and config in `conf.lua`.
- Prefer adding new Lua modules under `code/` (or a dedicated `src/`) and require them from `main.lua`.
- Store assets under `assets/` with logical subfolders.
- Lua style: Lua 5.1, 4-space indentation, trailing newline; prefer lower_snake_case for locals/modules; avoid globals by grouping helpers into tables.
