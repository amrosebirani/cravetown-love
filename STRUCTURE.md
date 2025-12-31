# Cravetown Project Structure

**Last Updated:** 2025-12-31
**Purpose:** Documentation of project organization, naming conventions, and directory structure

---

## 📁 Directory Overview

```
cravetown-love/
├── 📂 code/                    # Lua game source code
├── 📂 data/                    # Game data (JSON files)
├── 📂 chain-of-thought/        # Design documents and planning
├── 📂 docs/                    # Technical documentation
├── 📂 assets/                  # Game assets (sprites, images)
├── 📂 shaders/                 # LÖVE2D shader files
├── 📂 tools/                   # Development utilities
├── 📂 info-system/             # Standalone Tauri information system app
├── 📂 examples/                # Code examples and templates
├── 📂 mcp_server/              # MCP (Model Context Protocol) server
├── 📄 main.lua                 # LÖVE2D entry point
├── 📄 conf.lua                 # LÖVE2D configuration
└── 📄 [Documentation Files]    # Root-level docs (see below)
```

---

## 📄 Root-Level Documentation Files

### Core Documentation
- **`README.md`** - Project overview and quick start guide
- **`STRUCTURE.md`** _(this file)_ - Project structure and organization guide
- **`CLAUDE.md`** - Instructions for Claude AI assistant (codebase guidance)
- **`WARP.md`** - Project guide, commands, and architecture overview
- **`SETUP.md`** - Development environment setup instructions
- **`AGENTS.md`** - Agent-based development documentation

### Configuration
- **`conf.lua`** - LÖVE2D game engine configuration
- **`.gitignore`** - Git ignore rules

---

## 📂 Detailed Directory Structure

### `/code` - Game Source Code (Lua)

**Purpose:** All LÖVE2D/Lua game logic and systems

**Organization:**
- **Root level:** Core game systems, UI components, state management
- **`/code/consumption/`** - Consumption prototype and character systems
- **`/code/fx/`** - Visual effects and particles
- **`/code/mcp/`** - MCP integration code

**Naming Convention:**
- PascalCase for all Lua files (e.g., `BuildingSystem.lua`, `Character.lua`)
- Descriptive names indicating purpose (e.g., `TownSelectionScreen.lua`)
- State files end with `State` (e.g., `AlphaPrototypeState.lua`, `SpecialtyTownsState.lua`)

---

### `/data` - Game Data (JSON)

**Purpose:** All game configuration and content data

**Structure:**
```
data/
├── alpha/                      # Alpha version game data (active)
│   ├── building_recipes.json
│   ├── building_types.json
│   ├── commodities.json
│   ├── worker_types.json
│   ├── craving_system/         # Craving/satisfaction system data
│   └── ...
├── base/                       # Base/fallback game data
├── starting_towns/             # Specialty town templates (CFP prototype)
│   └── starting_towns.json
└── versions.json               # Data version management
```

**Naming Convention:**
- snake_case for all JSON files (e.g., `building_types.json`, `worker_types.json`)
- Plural names for collections (e.g., `commodities.json`, not `commodity.json`)
- Descriptive folder names in snake_case

---

### `/chain-of-thought` - Design & Planning Documents

**Purpose:** Design documents, meeting notes, analysis, and planning artifacts

**Structure:**
```
chain-of-thought/
├── README.md                   # Overview of chain-of-thought structure
├── analysis/                   # Game balance and design analysis
│   ├── balance_analysis_500_1000_citizens.md
│   ├── commodity_fulfillment_vectors_analysis.md
│   └── ...
├── implementation/             # Implementation plans for specific features
│   ├── CRAVE-11_town_template_design.md
│   ├── CRAVE-15_specialty_towns_implementation.md
│   └── ...
├── meetings/                   # Meeting notes and decisions
│   ├── cravetown-meeting-001-nov22-2025.md
│   └── meeting_notes_YYYY-MM-DD_[name].md
├── systems/                    # System design documents
│   ├── CFP_Design_Document_FINAL.md
│   ├── consumption_system_architecture_v2.md
│   └── ...
└── todo-lists/                 # Project planning and task lists
    ├── one_week_playability_sprint.md
    ├── cravetown_development_plan.md
    └── ...
```

**Naming Convention:**
- **snake_case** for analysis and system docs (e.g., `balance_analysis_status.md`)
- **UPPERCASE-NUMBER** for Linear issue plans (e.g., `CRAVE-11_town_template_design.md`)
- **kebab-case** for meeting notes with dates (e.g., `meeting_notes_2025-12-02_adwait.md`)
- Descriptive, self-explanatory names

---

### `/docs` - Technical Documentation

**Purpose:** Technical specifications, architecture docs, and reference guides

**Current Contents:**
- `CFP_Design_Document_FINAL.md` - Commodity-Focus Prototype design
- `economic-system-design.md` - Economic system architecture
- `housing-system-design.md` - Housing system specification
- `MCP_GAME_LAYER_ARCHITECTURE.md` - MCP integration architecture
- `TEA_COFFEE_DESIGN_SPEC.md` - Tea & coffee feature spec
- `balance_analysis_status.md` - Balance tracking
- `building_ratios_guide.md` - Production balancing guide
- `Urban_Dynamics_*.pdf` - Reference PDFs

**Naming Convention:**
- **kebab-case** for multi-word docs (e.g., `economic-system-design.md`)
- **UPPERCASE** for important/final specs (e.g., `CFP_Design_Document_FINAL.md`)
- Version suffixes where applicable (e.g., `_v2`, `_FINAL`)

---

### `/tools` - Development Utilities

**Purpose:** Scripts, utilities, and archived development artifacts

**Structure:**
```
tools/
├── python/                     # Python utility scripts
│   ├── convert_buildings.py   # Convert building data formats
│   ├── convert_recipes.py     # Convert recipe data formats
│   └── generate_building_sprites.py
└── archive/                    # Archived old files
    ├── TODO.md                 # Old TODO (archived)
    ├── TODO_UI_FEATURES.md
    ├── claude_response.txt     # AI conversation history
    ├── gpt_response.txt
    └── original_prompt.txt
```

**Usage:**
- Python scripts: Data conversion and generation utilities
- Archive: Historical files kept for reference only

---

### `/info-system` - Information System (Tauri App)

**Purpose:** Standalone React + Tauri desktop application for managing game data

**Structure:** Separate sub-project with own package.json, dependencies
- Independent build system (Vite + Tauri)
- Own documentation in `info-system/README.md`
- See `info-system/INFORMATION_SYSTEM_GUIDE.md` for details

---

### `/assets` - Game Assets

**Purpose:** Sprites, images, and visual assets

**Structure:**
```
assets/
└── buildings/                  # Building sprite sheets
```

---

### `/mcp_server` - MCP Server

**Purpose:** Model Context Protocol server for AI integration

See `mcp_server/README.md` for details.

---

## 🎯 Naming Conventions Summary

| Type | Convention | Examples |
|------|------------|----------|
| **Lua files** | PascalCase | `BuildingSystem.lua`, `AlphaWorld.lua` |
| **JSON data** | snake_case | `building_types.json`, `worker_types.json` |
| **Implementation plans** | CRAVE-NN_description | `CRAVE-11_town_template_design.md` |
| **System designs** | snake_case | `consumption_system_architecture.md` |
| **Technical docs** | kebab-case | `economic-system-design.md` |
| **Meeting notes** | meeting_YYYY-MM-DD | `meeting_notes_2025-12-02_adwait.md` |
| **Root docs** | UPPERCASE | `README.md`, `CLAUDE.md`, `WARP.md` |

---

## 📝 Document Metadata Standard

All markdown documents should include metadata header:

```markdown
# Document Title

**Created:** YYYY-MM-DD
**Last Updated:** YYYY-MM-DD
**Status:** [Draft|In Progress|Complete|Archived]
**Type:** [Design|Implementation Plan|Analysis|Meeting Notes|Guide]
**Purpose:** Brief description of document purpose

---

[Content begins here...]
```

---

## 🔄 Cross-References

### Related Documentation
- **Game Design:** See `/chain-of-thought/systems/CFP_Design_Document_FINAL.md`
- **Development Plan:** See `/chain-of-thought/todo-lists/one_week_playability_sprint.md`
- **Setup Guide:** See `SETUP.md` in root
- **AI Instructions:** See `CLAUDE.md` in root
- **MCP Architecture:** See `/docs/MCP_GAME_LAYER_ARCHITECTURE.md`

### Data Specifications
- **Building Types:** `/data/alpha/building_types.json`
- **Commodities:** `/data/alpha/commodities.json`
- **Recipes:** `/data/alpha/building_recipes.json`
- **Worker Types:** `/data/alpha/worker_types.json`

---

## 🚫 What NOT to Commit

The `.gitignore` file excludes:
- `node_modules/` - npm dependencies
- `dist/`, `src-tauri/target/` - Build outputs
- `.claude/`, `.vscode/`, `.idea/` - IDE files
- `*.log`, `.DS_Store` - Temporary/system files
- `package-lock.json` - Lock files (regenerated)

---

## 📌 Quick Reference

### Finding Documentation
1. **Game mechanics:** → `/chain-of-thought/systems/`
2. **Implementation plans:** → `/chain-of-thought/implementation/`
3. **Technical specs:** → `/docs/`
4. **Meeting decisions:** → `/chain-of-thought/meetings/`
5. **Task tracking:** → `/chain-of-thought/todo-lists/`

### Common Tasks
- **Add new commodity:** Edit `/data/alpha/commodities.json`
- **Add new building:** Edit `/data/alpha/building_types.json`
- **Add new recipe:** Edit `/data/alpha/building_recipes.json`
- **Update game code:** Files in `/code/`
- **Update AI instructions:** Edit `CLAUDE.md`

---

**Maintained by:** Cravetown Development Team
**Questions?** Check `WARP.md` for project commands and guidance
