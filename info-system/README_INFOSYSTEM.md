# CraveTown Information System

A desktop application for managing building recipes and commodities for the CraveTown game.

## Features

- **Building Recipes Manager**: Create, edit, and delete building recipes
  - Configure production time
  - Manage inputs and outputs with commodity picker
  - Set worker requirements and efficiency bonuses
  - Add notes and documentation

- **Commodities Manager**: Manage the game's commodity database
  - Add/edit/delete commodities
  - Organize by categories
  - Search and filter

## Tech Stack

- **Frontend**: React + TypeScript + Ant Design
- **Desktop Framework**: Tauri (Rust backend)
- **Data Storage**: JSON files in `../data/` directory

## Getting Started

### Prerequisites

- Node.js (v18+)
- Rust (latest stable)
- Cargo

### Running the Application

1. Navigate to the info-system directory:
   ```bash
   cd info-system
   ```

2. Start the development server:
   ```bash
   npm run tauri:dev
   ```

This will:
- Start the Vite development server
- Build the Rust backend
- Launch the desktop application

### Building for Production

```bash
npm run tauri:build
```

The built application will be in `src-tauri/target/release/`.

## Data Files

The application reads and writes to:
- `../data/building_recipes.json` - Building production recipes
- `../data/commodities.json` - Available commodities

These files are shared with the main CraveTown game.

## Development

### Project Structure

```
info-system/
├── src/
│   ├── components/
│   │   ├── RecipeManager.tsx      # Recipe list and management
│   │   ├── RecipeEditor.tsx       # Recipe form editor
│   │   ├── InputOutputEditor.tsx  # Inputs/outputs with commodity picker
│   │   ├── WorkerEditor.tsx       # Worker requirements editor
│   │   └── CommodityManager.tsx   # Commodity management
│   ├── api.ts                     # Tauri backend API calls
│   ├── types.ts                   # TypeScript type definitions
│   └── App.tsx                    # Main application
├── src-tauri/
│   ├── src/
│   │   └── lib.rs                 # Rust backend with file I/O
│   └── tauri.conf.json           # Tauri configuration
└── package.json
```

### API Functions

The `api.ts` module provides:
- `loadBuildingRecipes()` - Load recipes from JSON
- `saveBuildingRecipes()` - Save recipes to JSON
- `loadCommodities()` - Load commodities from JSON
- `saveCommodities()` - Save commodities to JSON

### Tauri Commands

Backend Rust commands in `src-tauri/src/lib.rs`:
- `read_json_file(file_path)` - Read JSON file
- `write_json_file(file_path, content)` - Write JSON file
- `get_data_dir()` - Get path to data directory

## Usage

### Managing Building Recipes

1. Click "Add Recipe" to create a new building recipe
2. Fill in:
   - Building Type ID (unique identifier)
   - Name (display name)
   - Production Time (in seconds)
3. Add inputs/outputs using the commodity picker
4. Configure worker requirements:
   - Required workers
   - Max workers
   - Vocations (worker types)
   - Efficiency bonus per additional worker
5. Save the recipe

### Managing Commodities

1. Click "Add Commodity" to create a new commodity
2. Fill in:
   - Commodity ID (unique identifier)
   - Name (display name)
   - Category (for organization)
   - Description (optional)
3. Save the commodity

## Integration with CraveTown

The Information System is designed to work alongside the main CraveTown game:

1. **Shared Data**: Both applications read/write the same JSON files
2. **Hot Reload**: Changes made in the Information System are immediately available to the game
3. **Prototype 2**: The Production Engine prototype will load recipes from `building_recipes.json`

## Troubleshooting

### Application won't start
- Ensure Rust and Cargo are installed: `rustc --version` and `cargo --version`
- Check that all npm dependencies are installed: `npm install`
- Try cleaning the build: `cd src-tauri && cargo clean`

### Can't read/write files
- Check that the `../data/` directory exists relative to the info-system folder
- Verify file permissions
- Check the console for error messages

### Changes not saving
- Ensure the application has write permissions to the data directory
- Check the browser console (F12) for errors
- Verify JSON file syntax is valid
