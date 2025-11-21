# CraveTown Setup Guide

This guide covers installation and setup for both the main game and the Information System on macOS and Windows.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Running the Game](#running-the-game)
- [Information System Setup](#information-system-setup)

---

## Prerequisites

### For the Game (LÖVE2D)

#### macOS
1. Install LÖVE2D:
   ```bash
   brew install --cask love
   ```
   Or download from: https://love2d.org/

#### Windows
1. Download and install LÖVE2D from: https://love2d.org/
2. Add LÖVE to your PATH or note the installation directory (typically `C:\Program Files\LOVE\`)

### For the Information System (Tauri + React)

#### macOS
1. Install Rust:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   source $HOME/.cargo/env
   ```

2. Install Node.js (v18 or later):
   ```bash
   brew install node
   ```

#### Windows
1. Install Rust:
   - Download from: https://rustup.rs/
   - Run the installer and follow the prompts
   - Restart your terminal after installation

2. Install Node.js (v18 or later):
   - Download from: https://nodejs.org/
   - Run the installer and follow the prompts

3. Install Visual Studio C++ Build Tools:
   - Download from: https://visualstudio.microsoft.com/visual-cpp-build-tools/
   - Install "Desktop development with C++" workload

---

## Running the Game

### macOS
```bash
cd /path/to/cravetown-love
love .
```

Or run in background:
```bash
love . &
```

### Windows
```cmd
cd C:\path\to\cravetown-love
"C:\Program Files\LOVE\love.exe" .
```

Or if LÖVE is in your PATH:
```cmd
love .
```

### Game Controls
- Use the interface to build and manage your town
- Check the in-game menus for specific building recipes and worker assignments

---

## Information System Setup

The Information System is a Tauri-based desktop application for managing game data (building recipes, commodities, and worker types).

### First-Time Installation

1. Navigate to the info-system directory:
   ```bash
   cd info-system
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Verify Tauri CLI installation:
   ```bash
   npm run tauri --version
   ```

### Running the Information System

#### Development Mode (Recommended)

**macOS/Linux:**
```bash
npm run tauri:dev
```

**Windows:**
```cmd
npm run tauri:dev
```

This will:
- Start the Vite dev server on port 5173
- Launch the Tauri application window
- Enable hot-reload for instant updates

#### Building for Production

**macOS:**
```bash
npm run tauri:build
```
The built app will be in: `src-tauri/target/release/bundle/`

**Windows:**
```cmd
npm run tauri:build
```
The built app will be in: `src-tauri\target\release\bundle\`

### Using the Information System

The Information System has three main sections:

1. **Building Recipes**
   - Add, edit, and delete building production recipes
   - Define inputs, outputs, production time, and worker requirements
   - Search and filter recipes by name, type, or category

2. **Commodities**
   - Manage all game items (resources, products, etc.)
   - Define commodity categories and descriptions
   - Used in building recipe inputs and outputs

3. **Worker Types**
   - Define worker vocations (carpenter, farmer, doctor, etc.)
   - Set skill levels and minimum wages
   - Assign worker types to building recipes

### Data Files

All data is stored in JSON format in the `data/` directory at the root level:
- `data/building_recipes.json` - Building production recipes
- `data/commodities.json` - Game items and resources
- `data/worker_types.json` - Worker vocations and wages

These files are shared between the game and the Information System.

---

## Troubleshooting

### Game Issues

**"No code to run" error:**
- Ensure you're in the correct directory with `main.lua`
- Check that all Lua files are present

**White/blank screen:**
- Check console for error messages
- Verify all required assets are present

### Information System Issues

**"Failed to load" errors:**
- Ensure the `data/` directory exists at the root level
- Check that JSON files are valid (use a JSON validator)
- Verify file permissions

**Tauri compilation errors (Windows):**
- Ensure Visual Studio C++ Build Tools are installed
- Restart terminal after installing Rust
- Run `rustc --version` to verify Rust installation

**Port 5173 already in use:**
- Stop other Vite dev servers
- Or change the port in `vite.config.ts`

**Blank white screen:**
- Check browser console for errors (F12)
- Verify all dependencies are installed: `npm install`
- Clear cache: `npm run build` then restart

---

## Development Notes

### Project Structure
```
cravetown-love/
├── main.lua                  # Game entry point

├── data/                     # Shared JSON data files
│   ├── building_recipes.json
│   ├── commodities.json
│   └── worker_types.json
├── info-system/              # Information System (Tauri + React)
│   ├── src/                  # React components
│   ├── src-tauri/            # Rust backend
│   └── dist/                 # Built frontend assets
└── prototype2/               # Game prototypes
```

### Making Changes

**To update game data:**
1. Use the Information System to edit recipes, commodities, or worker types
2. Changes are automatically saved to `data/` JSON files
3. Restart the game to load updated data

**To modify the Information System:**
1. Edit files in `info-system/src/`
2. Changes hot-reload in development mode
3. Rebuild for production when ready

---

## Additional Resources

- LÖVE2D Documentation: https://love2d.org/wiki/Main_Page
- Tauri Documentation: https://tauri.app/
- React Documentation: https://react.dev/

For issues or questions, please refer to the project documentation or create an issue in the project repository.
