# Cravetown

**A town-building simulation game focused on production chains and citizen satisfaction**

Built with LÖVE2D (Lua) | Indian food specialty towns | Commodity-focused economy

---

## 🎮 What is Cravetown?

Cravetown is a town simulation game where you manage production chains, satisfy citizen cravings, and build thriving communities. The game features a unique craving-based satisfaction system where citizens have desires across multiple categories (biological, emotional, social status, etc.) that must be fulfilled through a complex web of production and consumption.

### Current Prototypes

1. **Commodity-Focus Prototype (CFP)** - Core production-consumption mechanics without currency
2. **Specialty Towns** - Choose from 4 Indian food specialty starter towns:
   - 🥟 Vada Pav Town (Mumbai) - Easy
   - 🍚 Poha Town (Indore) - Easy
   - 🥞 Dosa Town (Bangalore) - Medium
   - 🍡 Rasogulla Town (Kolkata) - Hard

---

## 🚀 Quick Start

### Prerequisites

- **LÖVE2D** 11.4+ ([Download](https://love2d.org/))
- **Lua** 5.1+ (included with LÖVE)
- For info-system: **Node.js** 18+, **Rust** (for Tauri)

### Running the Game

```bash
# Option 1: Run directly with LÖVE
love .

# Option 2: On macOS (if LÖVE is in Applications)
open -a love .

# Option 3: From executable
./love .
```

### Launcher Options

1. **Specialty Towns (CFP Prototype)** - Play one of 4 specialty towns
2. **Alpha Prototype** - Full alpha game with all systems
3. **Consumption Prototype** - Test character satisfaction systems
4. **Production Prototype** - Test building production systems

---

## 📁 Project Structure

See **[STRUCTURE.md](./STRUCTURE.md)** for complete project organization details.

```
cravetown-love/
├── code/               # Lua game source
├── data/               # JSON game data
├── chain-of-thought/   # Design documents
├── docs/               # Technical documentation
├── assets/             # Game assets
├── tools/              # Development utilities
└── info-system/        # Tauri information system app
```

---

## 📚 Documentation

### For Players
- **[SETUP.md](./SETUP.md)** - Development environment setup
- **[WARP.md](./WARP.md)** - Project commands and quick reference

### For Developers
- **[STRUCTURE.md](./STRUCTURE.md)** - Project organization guide
- **[CLAUDE.md](./CLAUDE.md)** - AI assistant instructions
- **[CFP Design Doc](./docs/CFP_Design_Document_FINAL.md)** - Core game design
- **[One Week Sprint](./chain-of-thought/todo-lists/one_week_playability_sprint.md)** - Current development plan

### Technical Specs
- **[Economic System](./docs/economic-system-design.md)**
- **[Housing System](./docs/housing-system-design.md)**
- **[MCP Architecture](./docs/MCP_GAME_LAYER_ARCHITECTURE.md)**

---

## 🎯 Core Game Systems

### Production System
- 50+ building types with upgrade paths
- Complex production chains (e.g., wheat → flour → bread → vada pav)
- Resource requirements and placement constraints
- Worker efficiency based on vocation matching

### Craving System
- 7 craving categories (biological, touch, psychological, safety, social status, exotic goods, shiny objects)
- Dynamic satisfaction calculation based on consumption
- Class-based (Elite, Upper, Middle, Lower) and trait-based modifiers
- Substitution hierarchies for unavailable goods

### Immigration & Population
- Dynamic immigration based on town satisfaction
- Family relations (spouse, children)
- Age progression and life events
- Housing assignment and capacity management

---

## 🛠️ Development

### Tech Stack
- **Game Engine:** LÖVE2D (Lua)
- **Data Format:** JSON
- **Info System:** React + TypeScript + Tauri
- **Version Control:** Git + GitHub

### Key Files
- **Entry Point:** `main.lua` - Game initialization and launcher
- **Core Systems:** `/code/AlphaWorld.lua`, `/code/AlphaUI.lua`
- **Data:** `/data/alpha/*.json`

### Adding New Content

```lua
-- Add new commodity (data/alpha/commodities.json)
{
  "id": "new_item",
  "name": "New Item",
  "category": "processed_food",
  "baseValue": 10,
  "quality": "basic"
}

-- Add new building (data/alpha/building_types.json)
{
  "id": "new_building",
  "name": "New Building",
  "category": "production",
  "upgradeLevels": [...]
}

-- Add new recipe (data/alpha/building_recipes.json)
{
  "buildingType": "new_building",
  "recipeName": "New Recipe",
  "inputs": {"item_a": 2},
  "outputs": {"item_b": 1},
  "productionTime": 600
}
```

---

## 🧪 Testing

### Manual Testing
1. Launch game via LÖVE
2. Select prototype from launcher
3. Test specific systems/features

### Data Validation
```bash
# Verify JSON syntax
python tools/python/validate_json.py

# Check commodity references
grep -r "commodity_id" data/alpha/
```

---

## 📦 Build & Distribution

### Creating .love file
```bash
# Zip game files
zip -r cravetown.love . -x ".*" -x "node_modules/*" -x "tools/*"

# Run
love cravetown.love
```

### Info System (Tauri App)
```bash
cd info-system
npm install
npm run tauri dev      # Development
npm run tauri build    # Production build
```

---

## 🤝 Contributing

### Workflow
1. Check Linear board for tasks
2. Create feature branch: `feat/feature-name`
3. Follow naming conventions (see STRUCTURE.md)
4. Add metadata headers to new documents
5. Test thoroughly before committing
6. Reference Linear issues in commits (e.g., "feat: Add butcher building (CRAVE-16)")

### Commit Message Format
```
<type>: <description> (<issue>)

Examples:
feat: Add specialty town loading system (CRAVE-15)
fix: Resolve butcher building menu display (CRAVE-16)
docs: Update CFP design with tea/coffee chains
refactor: Clean up project structure
```

---

## 📝 Current Status

- **Version:** Alpha (CFP Prototype)
- **Active Branch:** `feat/tea-coffee-implementation`
- **Recent Milestones:**
  - ✅ CRAVE-11: Town template design complete
  - ✅ CRAVE-15: Specialty towns implementation
  - ✅ CRAVE-16: Butcher building added
- **In Progress:** Tea & coffee production chains

See `/chain-of-thought/todo-lists/one_week_playability_sprint.md` for current sprint tasks.

---

## 🐛 Known Issues

Check Linear board: [Cravetown-Dev](https://linear.app/cravetown-dev/)

---

## 📄 License

[License information to be added]

---

## 🙏 Acknowledgments

- Built with LÖVE2D game framework
- Urban Dynamics system design reference
- Community feedback and playtesting

---

**For more information:**
- Project Guide: [WARP.md](./WARP.md)
- Structure Guide: [STRUCTURE.md](./STRUCTURE.md)
- Setup Instructions: [SETUP.md](./SETUP.md)
