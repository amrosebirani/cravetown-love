# Phase 8: Building System Design for Alpha Prototype

## Overview

This document describes the building system UI for the Alpha prototype, integrating the existing building placement logic, resource overlays, and efficiency systems from the main game into the new UI layout.

---

## 1. UI Integration Points

### 1.1 Build Menu Access (Left Panel - Already Implemented Quick Build)

The existing Quick Build section in the left panel will be expanded:

```
LEFT PANEL
+----------------------------------+
| Quick Build                      |
| +------------+ +------------+    |
| | [House]    | | [Farm]     |    |
| +------------+ +------------+    |
| +------------+ +------------+    |
| | [Workshop] | | [Market]   |    |
| +------------+ +------------+    |
| [More Buildings...]              |
+----------------------------------+
```

Clicking "More Buildings..." opens a full Build Menu modal.

### 1.2 Full Build Menu Modal (New)

A modal overlay following the UI spec pattern:

```
+======================================================================+
| BUILD MENU                                              [X] Close    |
+======================================================================+
|                                                                      |
| CATEGORIES:                                                          |
| [All] [Housing] [Production] [Services]                              |
|                                                                      |
+----------------------------------------------------------------------+
| HOUSING                                                              |
+----------------------------------------------------------------------+
| +-------------+ +-------------+ +-------------+ +-------------+      |
| |   [Icon]    | |   [Icon]    | |   [Icon]    | |   [Icon]    |      |
| |   Hovel     | |   Cottage   | |   House     | |   Manor     |      |
| |  Cap: 2     | |  Cap: 4     | |  Cap: 6     | |  Cap: 8     |      |
| |  Cost: 50g  | |  Cost: 150g | |  Cost: 400g | |  Cost:1200g |      |
| |  [BUILD]    | |  [BUILD]    | |  [BUILD]    | |  [BUILD]    |      |
| +-------------+ +-------------+ +-------------+ +-------------+      |
|                                                                      |
+----------------------------------------------------------------------+
| PRODUCTION                                                           |
+----------------------------------------------------------------------+
| +-------------+ +-------------+ +-------------+ +-------------+      |
| |   [Icon]    | |   [Icon]    | |   [Icon]    | |   [Icon]    |      |
| | Wheat Farm  | |   Bakery    | |   Mine      | |   Workshop  |      |
| | Out: Wheat  | | Out: Bread  | | Out: Ore    | | Out: Tools  |      |
| | Workers:2-4 | | Workers:1-2 | | Workers:2-6 | | Workers:2-4 |      |
| | Cost: 200g  | | Cost: 300g  | | Cost: 500g  | | Cost: 400g  |      |
| | [BUILD]     | | [BUILD]     | | [BUILD]     | | [BUILD]     |      |
| +-------------+ +-------------+ +-------------+ +-------------+      |
|                                                                      |
+======================================================================+
```

### 1.3 Key Differences from Main Game

| Main Game | Alpha Prototype |
|-----------|-----------------|
| Bottom bar with collapsible building buttons | Left panel quick build + modal for full menu |
| BuildingMenu.lua handles selection | AlphaUI handles selection, enters placement mode |
| StateMachine state change | Same approach, integrated into AlphaWorld |
| Affordability check via gTown.mInventory | Affordability check via AlphaWorld.inventory |

---

## 2. Building Placement Mode

When a building is selected for placement, the UI enters placement mode:

### 2.1 Visual State

```
+======================================================================+
| TOP BAR (dimmed)                                                     |
+======================================================================+
|  LEFT    |              CENTER - PLACEMENT MODE              | RIGHT |
|  PANEL   |                                                   | PANEL |
| (dimmed) |   [World view with terrain tiles]                 |(shows |
|          |                                                   | place-|
|          |        +-------+                                  | ment  |
|          |        | GHOST |  <- Building preview             | info) |
|          |        | BLDG  |     (follows mouse)              |       |
|          |        +-------+                                  |       |
|          |   ~~~~~~~~~~~~  <- Path connections               |       |
|          |                                                   |       |
|          |   [Resource overlay visible if 'R' pressed]       |       |
+======================================================================+
| BOTTOM BAR: [Left-click: Place] [Right-click: Cancel] [R: Resources] |
+======================================================================+
```

### 2.2 Right Panel During Placement

Shows placement requirements and efficiency:

```
+-----------------------------------+
| PLACING: Wheat Farm               |
+-----------------------------------+
| Size: 60x60 pixels                |
|                                   |
| REQUIREMENTS:                     |
| +-------------------------------+ |
| | Flat terrain       [CHECK]    | |
| | No obstructions    [CHECK]    | |
| | Within boundaries  [CHECK]    | |
| +-------------------------------+ |
|                                   |
| RESOURCE EFFICIENCY: 78%          |
| +-------------------------------+ |
| | Fertility:   85%   [MET]      | |
| | Ground Water: 65%  [MET]      | |
| +-------------------------------+ |
|                                   |
| (Move closer to river for        |
|  better water access)            |
|                                   |
| COST: 200 gold                   |
| [Materials needed: none]         |
+-----------------------------------+
```

### 2.3 Ghost Building Rendering

From existing BuildingPlacementState logic:
- Green tint = valid placement
- Red tint = invalid placement (collision, out of bounds, insufficient resources)
- Semi-transparent (alpha 0.6)

### 2.4 Resource Overlay Integration

The existing ResourceOverlay system will be ported:
- Toggle with 'R' key during placement
- Shows color-coded grid for:
  - Fertility (green gradient)
  - Ground Water (blue gradient)
  - Ore deposits (red/brown for iron, orange for copper, black for coal)
- Control panel in corner to toggle individual resources

---

## 3. Efficiency Calculation System

### 3.1 Integration from Existing System

Port the logic from `NaturalResources.lua` and `Town.lua`:

```lua
-- In AlphaWorld (or new AlphaNaturalResources module)
function AlphaWorld:CalculateBuildingEfficiency(buildingType, x, y, width, height)
    -- Check placementConstraints from buildingType
    if not buildingType.placementConstraints or not buildingType.placementConstraints.enabled then
        return 1.0, {}, true  -- No constraints = 100% efficiency
    end

    local constraints = buildingType.placementConstraints
    local breakdown = {}
    local totalWeight = 0
    local weightedSum = 0
    local allRequirementsMet = true

    for _, req in ipairs(constraints.requiredResources) do
        local value = self:GetResourceValue(req.resourceId, x, y, width, height)
        local met = value >= (req.minValue or 0)

        breakdown[req.resourceId] = {
            value = value,
            weight = req.weight or 1,
            met = met,
            displayName = req.displayName or req.resourceId
        }

        weightedSum = weightedSum + (value * (req.weight or 1))
        totalWeight = totalWeight + (req.weight or 1)

        if not met then
            allRequirementsMet = false
        end
    end

    local efficiency = totalWeight > 0 and (weightedSum / totalWeight) or 1.0
    local canPlace = efficiency >= (constraints.blockingThreshold or 0.1)

    return efficiency, breakdown, canPlace and allRequirementsMet
end
```

### 3.2 Resource Grid System

For alpha, we'll use a simplified procedural generation:

```lua
-- AlphaNaturalResources.lua
AlphaNaturalResources = {}

function AlphaNaturalResources:Create(width, height, cellSize)
    local res = {}
    res.width = width
    res.height = height
    res.cellSize = cellSize or 20
    res.grid = {}

    -- Generate grids for different resources
    res.grid.fertility = res:GeneratePerlinGrid(0.02, "fertility")
    res.grid.ground_water = res:GeneratePerlinGrid(0.015, "water")
    res.grid.iron_ore = res:GenerateDepositGrid("iron", 3)

    return setmetatable(res, {__index = AlphaNaturalResources})
end

function AlphaNaturalResources:GeneratePerlinGrid(frequency, seed)
    -- Simplified Perlin-like noise for alpha
    local grid = {}
    math.randomseed(seed:byte(1) * 1000 + os.time())

    local cols = math.ceil(self.width / self.cellSize)
    local rows = math.ceil(self.height / self.cellSize)

    for row = 1, rows do
        grid[row] = {}
        for col = 1, cols do
            -- Simplified noise: base + random variation + distance from center
            local cx, cy = cols/2, rows/2
            local dist = math.sqrt((col-cx)^2 + (row-cy)^2) / math.max(cols, rows)
            local base = 0.5 + math.random() * 0.3 - dist * 0.3
            grid[row][col] = math.max(0, math.min(1, base))
        end
    end
    return grid
end
```

---

## 4. Building Data Integration

### 4.1 Building Type Structure (from existing JSON)

Buildings should define placement constraints:

```json
{
  "id": "wheat_farm",
  "name": "Wheat Farm",
  "category": "production",
  "placementConstraints": {
    "enabled": true,
    "requiredResources": [
      {"resourceId": "fertility", "weight": 0.7, "minValue": 0.2, "displayName": "Fertility"},
      {"resourceId": "ground_water", "weight": 0.3, "minValue": 0.1, "displayName": "Water"}
    ],
    "efficiencyFormula": "weighted_average",
    "blockingThreshold": 0.1
  },
  "constructionCost": {
    "gold": 200,
    "materials": {}
  },
  "upgradeLevels": [
    {"stations": 1, "workers": 2, "storageCapacity": 50}
  ]
}
```

### 4.2 Affordability Check

```lua
function AlphaWorld:CanAffordBuilding(buildingType)
    -- Check gold
    local cost = buildingType.constructionCost or {}
    if (cost.gold or 0) > self.gold then
        return false, "Insufficient gold"
    end

    -- Check materials
    for materialId, required in pairs(cost.materials or {}) do
        if (self.inventory[materialId] or 0) < required then
            return false, "Missing " .. materialId
        end
    end

    return true, nil
end
```

---

## 5. Implementation Tasks

### Task 8.1: Building Placement Mode

**Files to modify:**
- `code/AlphaUI.lua` - Add placement mode rendering and input
- `code/AlphaWorld.lua` - Add building placement methods

**New state fields in AlphaUI:**
```lua
ui.placementMode = false
ui.placementBuilding = nil     -- Building type being placed
ui.placementX = 0
ui.placementY = 0
ui.placementValid = false
ui.placementEfficiency = 1.0
ui.placementBreakdown = {}
```

**Key methods:**
- `AlphaUI:EnterPlacementMode(buildingType)`
- `AlphaUI:ExitPlacementMode()`
- `AlphaUI:UpdatePlacement(mx, my)`
- `AlphaUI:RenderPlacementGhost()`
- `AlphaUI:RenderPlacementInfo()` (right panel during placement)

### Task 8.2: Resource Overlay System

**New file:** `code/AlphaNaturalResources.lua`

**Key methods:**
- `Create(width, height)`
- `GenerateResources()`
- `GetValue(resourceId, x, y)`
- `GetAverageValue(resourceId, x, y, w, h)`
- `RenderOverlay(resourceId, camera, alpha)`

**Integration with AlphaUI:**
- 'R' key toggles overlay during placement
- Resource panel in top-right corner

### Task 8.3: Full Build Menu Modal

**New file or section in AlphaUI:** Build menu modal

**Features:**
- Category filtering (Housing, Production, Services)
- Building cards with icon, name, stats, cost
- Affordability indication (grayed out if can't afford)
- Click to enter placement mode

### Task 8.4: Production Integration

**Already partially implemented in AlphaWorld. Enhancements:**
- Store placement efficiency on building
- Apply efficiency to production rate
- Show efficiency in building details (right panel)

---

## 6. Interaction Flow

```
1. User clicks "More Buildings..." in left panel
   OR clicks quick build button
   |
   v
2. Full Build Menu modal opens (for "More Buildings...")
   OR directly enters placement mode (for quick build)
   |
   v
3. User selects building type
   |
   v
4. UI enters Placement Mode:
   - World view shows ghost building at cursor
   - Right panel shows placement requirements
   - 'R' key toggles resource overlay
   - Efficiency updates in real-time as cursor moves
   |
   v
5. User left-clicks to place:
   - Validate placement (collision, bounds, resources)
   - If valid: Deduct cost, create building, exit placement mode
   - If invalid: Show error feedback, remain in placement mode
   |
   v
6. Building appears in world
   - Right panel shows building details
   - Production starts when workers assigned
```

---

## 7. Visual Design Notes

### Color Scheme (consistent with existing UI)
- Valid placement: Green tint (#66CC66 at 40% opacity)
- Invalid placement: Red tint (#CC6666 at 40% opacity)
- Efficiency colors:
  - 80%+: Green
  - 40-79%: Yellow/Orange
  - <40%: Red

### Resource Overlay Colors (from existing ResourceOverlay)
- Fertility: Green gradient
- Ground Water: Blue gradient
- Iron Ore: Brown/Red
- Copper Ore: Orange
- Coal: Dark gray/Black

### Ghost Building
- Same dimensions as final building
- Semi-transparent (60% opacity)
- Border highlight shows validity
- Subtle pulsing animation when valid

---

## 8. Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `code/AlphaUI.lua` | Modify | Add placement mode, build menu modal |
| `code/AlphaWorld.lua` | Modify | Add placement validation, efficiency calc |
| `code/AlphaNaturalResources.lua` | Create | Resource grid generation and queries |
| `code/AlphaPrototypeState.lua` | Modify | Wire up new input handlers |
| `data/*/building_types.json` | Modify | Add placementConstraints to building definitions |
