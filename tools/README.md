# Tools Directory

**Created:** 2025-12-31
**Last Updated:** 2025-12-31
**Type:** Development Utilities Documentation
**Purpose:** Documentation of development tools, scripts, and archived files

---

## 📂 Directory Structure

```
tools/
├── python/         # Python utility scripts
│   ├── convert_buildings.py
│   ├── convert_recipes.py
│   └── generate_building_sprites.py
└── archive/        # Archived old files
    ├── TODO.md
    ├── TODO_UI_FEATURES.md
    ├── claude_response.txt
    ├── gpt_response.txt
    └── original_prompt.txt
```

---

## 🐍 Python Scripts

### `convert_buildings.py`

**Purpose:** Convert building data between different formats

**Usage:**
```bash
python tools/python/convert_buildings.py
```

**Input:** Old building format JSON
**Output:** New building format compatible with current game system

---

### `convert_recipes.py`

**Purpose:** Convert recipe data formats

**Usage:**
```bash
python tools/python/convert_recipes.py
```

**Input:** Recipe data in legacy format
**Output:** Updated recipe format for `data/alpha/building_recipes.json`

---

### `generate_building_sprites.py`

**Purpose:** Generate building sprite placeholders or batch process building graphics

**Usage:**
```bash
python tools/python/generate_building_sprites.py
```

**Note:** This may require PIL/Pillow or other image libraries.

---

## 📦 Archive

The `archive/` directory contains historical files kept for reference:

### Old TODO Files
- **`TODO.md`** - Original project TODO list (superseded by Linear board)
- **`TODO_UI_FEATURES.md`** - UI feature wishlist (archived)

### AI Conversation History
- **`claude_response.txt`** - Early Claude AI conversation
- **`gpt_response.txt`** - Early GPT conversation
- **`original_prompt.txt`** - Initial project prompt

**Note:** These files are archived for historical reference. Current development uses:
- Linear board for task tracking
- Chain-of-thought documents for design decisions
- Git commits for change history

---

## 🛠️ Adding New Tools

When adding new utility scripts:

1. **Place in appropriate subdirectory:**
   - Python scripts → `tools/python/`
   - Shell scripts → `tools/scripts/` (create if needed)
   - Other utilities → `tools/[category]/`

2. **Add documentation:**
   - Update this README with tool description
   - Add usage examples
   - Document dependencies

3. **Follow naming conventions:**
   - Descriptive snake_case names (e.g., `validate_json_data.py`)
   - Include file extension
   - Add shebang line for executable scripts

---

## 📝 Notes

- Tools in this directory are development utilities, not part of the game runtime
- Most Python scripts were used during early data migration
- Archived files are kept for historical reference but should not be edited

---

**See also:**
- [STRUCTURE.md](../STRUCTURE.md) - Project organization guide
- [WARP.md](../WARP.md) - Development commands and conventions
