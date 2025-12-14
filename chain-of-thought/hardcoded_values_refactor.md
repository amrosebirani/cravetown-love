# Hardcoded Values Refactoring Plan

**Created:** 2025-12-06
**Purpose:** Document all hardcoded class names and dimension counts, plan data-driven approach

---

## Current State

### Data Files Already Exist

The following JSON files already define the values that are hardcoded in Lua:

| File | Content |
|------|---------|
| `data/base/craving_system/character_classes.json` | 4 classes: elite, upper, middle, lower |
| `data/base/craving_system/dimension_definitions.json` | 9 coarse, 50 fine dimensions |

### Hardcoded Values in Code

#### 1. Class Names (22 occurrences)

| File | Lines | Issue |
|------|-------|-------|
| `ConsumptionPrototype.lua` | 71, 2780, 2799, 2889, 3288, 3340, 3533, 4305, 4319, 4505, 5762, 6748, 6779-6785 | Hardcoded class arrays and conditionals |
| `Character.lua` | 29 | Default "Middle" class |
| `CharacterV2.lua` | 103 | Default "Middle" class |
| `CharacterFactory.lua` | 33-37 | Class distribution with percentages |
| `TestCharacterV2State.lua` | 28-30 | Test character classes |
| `mcp/ActionHandler.lua` | 604 | Default "Middle" class |

#### 2. Dimension Counts (Comments/Display Only)

Most mentions of "49" and "9" in code are in comments or display strings:
- `ConsumptionPrototype.lua:6372` - Display text "9 dimensions" / "49 dimensions"
- `ConsumptionPrototype.lua:6505` - Comment about fine level
- Various comments describing the system

**Note:** The dimension counts are not hardcoded in logic - arrays are sized dynamically from loaded data. Only display text references the counts.

---

## Solution: Create DataRegistry Module

### Approach

Create a central `DataRegistry.lua` module that:
1. Loads all game data files on startup
2. Provides accessor methods for classes, dimensions
3. Caches computed values (class list, dimension counts)
4. Is the single source of truth for data across the codebase

### File: `code/DataRegistry.lua` (NEW)

```lua
local DataRegistry = {}

-- Loaded data
DataRegistry.characterClasses = nil
DataRegistry.dimensionDefinitions = nil

-- Cached computed values
DataRegistry.classNames = nil  -- {"Elite", "Upper Class", "Middle Class", "Lower Class"}
DataRegistry.classIds = nil    -- {"elite", "upper", "middle", "lower"}
DataRegistry.coarseDimensionCount = 0
DataRegistry.fineDimensionCount = 0

function DataRegistry:Load()
    -- Load character_classes.json
    local classData = self:LoadJSON("data/base/craving_system/character_classes.json")
    if classData then
        self.characterClasses = classData
        self.classNames = {}
        self.classIds = {}
        for _, class in ipairs(classData.classes) do
            table.insert(self.classNames, class.name)
            table.insert(self.classIds, class.id)
        end
    end

    -- Load dimension_definitions.json
    local dimData = self:LoadJSON("data/base/craving_system/dimension_definitions.json")
    if dimData then
        self.dimensionDefinitions = dimData
        self.coarseDimensionCount = dimData.dimensionCount.coarse
        self.fineDimensionCount = dimData.dimensionCount.fine
    end
end

function DataRegistry:GetClassNames()
    return self.classNames or {"Elite", "Upper Class", "Middle Class", "Lower Class"}
end

function DataRegistry:GetClassIds()
    return self.classIds or {"elite", "upper", "middle", "lower"}
end

function DataRegistry:GetDefaultClass()
    return self.classIds and self.classIds[3] or "middle"  -- Middle is usually index 3
end

function DataRegistry:GetClassByIndex(index)
    return self.characterClasses and self.characterClasses.classes[index] or nil
end

function DataRegistry:GetClassById(id)
    if not self.characterClasses then return nil end
    for _, class in ipairs(self.characterClasses.classes) do
        if class.id == id or class.name == id then
            return class
        end
    end
    return nil
end

function DataRegistry:GetCoarseDimensionCount()
    return self.coarseDimensionCount or 9
end

function DataRegistry:GetFineDimensionCount()
    return self.fineDimensionCount or 50
end

return DataRegistry
```

---

## Refactoring Steps

### Step 1: Create DataRegistry Module
- Create `code/DataRegistry.lua`
- Add JSON loading utility
- Initialize on game startup

### Step 2: Update Class References

Replace hardcoded class arrays:

**Before:**
```lua
local classes = {"Elite", "Upper", "Middle", "Working", "Poor"}
```

**After:**
```lua
local DataRegistry = require("code.DataRegistry")
local classes = DataRegistry:GetClassNames()
```

### Step 3: Update Default Class

**Before:**
```lua
char.class = class or "Middle"
```

**After:**
```lua
local DataRegistry = require("code.DataRegistry")
char.class = class or DataRegistry:GetDefaultClass()
```

### Step 4: Update Display Strings

**Before:**
```lua
local levelText = self.heatmapLevel == "coarse" and "Coarse Level (9 dimensions)" or "Fine Level (49 dimensions)"
```

**After:**
```lua
local DataRegistry = require("code.DataRegistry")
local coarseCount = DataRegistry:GetCoarseDimensionCount()
local fineCount = DataRegistry:GetFineDimensionCount()
local levelText = self.heatmapLevel == "coarse"
    and string.format("Coarse Level (%d dimensions)", coarseCount)
    or string.format("Fine Level (%d dimensions)", fineCount)
```

---

## Files Requiring Updates

| File | Changes Needed |
|------|----------------|
| `code/DataRegistry.lua` | CREATE - Central data accessor |
| `code/ConsumptionPrototype.lua` | Replace 12 class references, 2 dimension counts |
| `code/Character.lua` | Replace default class |
| `code/consumption/CharacterV2.lua` | Replace default class |
| `code/CharacterFactory.lua` | Load class distribution from data |
| `code/consumption/TestCharacterV2State.lua` | Use DataRegistry for test classes |
| `code/mcp/ActionHandler.lua` | Replace default class |
| `code/main.lua` or startup | Call DataRegistry:Load() |

---

## Data File Updates

### Sync JSON with Code Expectations

The JSON has 4 classes: `elite`, `upper`, `middle`, `lower`
The code references 5: `Elite`, `Upper`, `Middle`, `Working`, `Poor`

**Decision:** Update code to use JSON's 4 classes, or add "Working" and "Poor" to JSON.

Recommendation: Keep 4 classes (Elite, Upper, Middle, Lower) - simpler for alpha.
- "Working" class not in JSON - remove from code or add to JSON
- "Poor" class not in JSON - "Lower" serves same purpose

---

## Implementation Priority

**For Alpha:**
- Create DataRegistry module
- Update critical paths (CharacterV2, AllocationEngine)
- Leave display strings as-is (low impact)

**Post-Alpha:**
- Complete refactoring of all hardcoded references
- Add validation that data files match expected schema
- Support modding via data overrides

---

## Change Log

| Date | Change |
|------|--------|
| 2025-12-06 | Created refactoring plan |

