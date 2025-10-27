# Repository Guidelines

## Project Structure & Module Organization
Keep the gameplay loop in `main.lua` and configuration in `conf.lua`; both live at the repo root for quick access within the LÖVE launcher. Add new game modules as separate Lua files in the root or a dedicated `src/` folder, and require them from `main.lua`. Store art, audio, and fonts together under `assets/` with logical subfolders (`assets/sfx`, `assets/ui`, etc.) so they can ship cleanly inside the `.love` bundle. Mirror test doubles or sample scenes alongside the files they exercise to simplify reviews.

## Build, Test, and Development Commands
Use `love .` from the repository root to launch the game with LÖVE 11.4. Package distributions by running `zip -r build/cravetown.love . -x "build/*"` and then double-clicking the resulting archive with the LÖVE runtime. When experimenting with rendering or input changes, pair `love --console .` to surface runtime warnings in the terminal.

## Coding Style & Naming Conventions
Follow Lua 5.1 syntax with four-space indentation and trailing newline at EOF. Name callback functions using LÖVE’s canonical hooks (`love.load`, `love.update`, `love.draw`), and prefer lower_snake_case for locals and module tables (`player_state`, `menu_controller`). Group related helper functions into tables to avoid globals, and keep screen constants in an uppercase table (`WINDOW.WIDTH`). Run `stylua --verify main.lua conf.lua` before pushing if you introduce the formatter.

## Testing Guidelines
We currently rely on manual playtesting. Run `love .` after each change and verify window sizing, input, and draw order on at least one desktop resolution. If you introduce automated specs, add them under `tests/` and document the runner (e.g., `busted tests`). Preserve deterministic behaviour by seeding RNG in `love.load` whenever your feature depends on randomness.

## Commit & Pull Request Guidelines
Aim for concise, present-tense commit subjects (examples in history: “adding the base prompt and it's responses”). Group related Lua and asset changes together so reviewers can run `love .` against a single commit if needed. Pull requests should explain gameplay impact, list manual test steps, and attach screenshots or GIFs for visual tweaks. Mention linked issues or design references, and call out any assets that require attribution so they can be tracked in `README.md`.
