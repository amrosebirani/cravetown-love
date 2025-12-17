# Natural Resources System - Architecture Document

**Version:** 1.0
**Created:** 2025-11-30
**Status:** Draft

---

## Table of Contents

1. [Overview](#1-overview)
2. [System Goals](#2-system-goals)
3. [Natural Resource Types](#3-natural-resource-types)
4. [Distribution Algorithms](#4-distribution-algorithms)
5. [Data Architecture](#5-data-architecture)
6. [Building Placement Constraints](#6-building-placement-constraints)
7. [Efficiency Calculation](#7-efficiency-calculation)
8. [Visualization System](#8-visualization-system)
9. [Integration Points](#9-integration-points)
10. [Future Considerations](#10-future-considerations)

---

## 1. Overview

The Natural Resources System adds underground and surface resources to the game world that affect building placement and production efficiency. Resources are distributed across the map grid using procedural generation, creating strategic decisions around where to place resource-dependent buildings.

### Core Concept

```
┌─────────────────────────────────────────────────────────────────┐
│                         GAME MAP                                │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                                                         │   │
│  │   [Fertility: 0.8]  [Water: 0.6]  [Iron: 0.0]          │   │
│  │        ↓                                                │   │
│  │   ┌─────────┐                                          │   │
│  │   │  FARM   │ ← Efficiency = (0.8 * 0.7) + (0.6 * 0.3) │   │
│  │   │  85%    │              = 0.56 + 0.18 = 0.74 (74%)  │   │
│  │   └─────────┘                                          │   │
│  │                                                         │   │
│  │   [Fertility: 0.2]  [Water: 0.3]  [Iron: 0.9]          │   │
│  │                                       ↓                 │   │
│  │                                 ┌─────────┐            │   │
│  │                                 │  MINE   │            │   │
│  │                                 │  90%    │            │   │
│  │                                 └─────────┘            │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. System Goals

### Primary Goals

1. **Strategic Depth**: Players must consider resource distribution when placing buildings
2. **Visual Feedback**: Toggle-able overlay system shows resource distribution
3. **Production Impact**: Building efficiency directly tied to underlying resources
4. **Data-Driven**: All resource types and building constraints defined in JSON

### Design Principles

- **Continuous Values**: Resources use 0.0-1.0 scale for smooth efficiency calculations
- **Linear Efficiency**: Simple multiplier system (resource value = efficiency multiplier)
- **One-Time Calculation**: Efficiency computed at building placement, not per-tick
- **Non-Depleting**: Resources remain constant (can be changed later)
- **Modular**: Easy to add new resource types without code changes

---

## 3. Natural Resource Types

### 3.1 Resource Categories

Resources fall into two distribution categories:

| Category | Distribution Method | Characteristics |
|----------|-------------------|-----------------|
| **Continuous** | Perlin noise + hotspots | Gradual variation, covers large areas |
| **Discrete** | Regional clusters | Localized deposits, clear boundaries |

### 3.2 Resource Definitions

#### Continuous Resources (Perlin + Hotspots)

| Resource | Coverage | River Influence | Description |
|----------|----------|-----------------|-------------|
| **Ground Water** | 60-80% | +30% near river | Underground aquifers |
| **Land Fertility** | 50-70% | +20% near river | Soil quality for farming |

#### Discrete Resources (Regional Clusters)

| Resource | Deposits | Radius | Rarity | Description |
|----------|----------|--------|--------|-------------|
| **Iron Ore** | 3-5 | 80-150px | Common | Primary metal ore |
| **Copper Ore** | 2-4 | 60-120px | Moderate | Secondary metal ore |
| **Coal** | 2-4 | 100-180px | Common | Fuel source |
| **Gold Ore** | 1-2 | 40-80px | Rare | Precious metal |
| **Silver Ore** | 1-2 | 40-80px | Rare | Precious metal |
| **Stone** | 4-6 | 80-150px | Very Common | Construction material |
| **Oil** | 1-2 | 60-100px | Very Rare | Industrial fuel |
| **Natural Gas** | 1-3 | 50-90px | Rare | Often near oil |
| **Clay** | 2-4 | 60-100px | Moderate | Brick material |

### 3.3 Resource Value Scale

All resources use a continuous 0.0 to 1.0 scale with semantic tiers:

| Value Range | Tier Name | Visual Color | Efficiency Impact |
|-------------|-----------|--------------|-------------------|
| 0.00 - 0.19 | None/Trace | Transparent | Building not recommended |
| 0.20 - 0.39 | Poor | Light shade | 20-39% efficiency |
| 0.40 - 0.59 | Moderate | Medium shade | 40-59% efficiency |
| 0.60 - 0.79 | Good | Dark shade | 60-79% efficiency |
| 0.80 - 1.00 | Excellent | Full color | 80-100% efficiency |

---

## 4. Distribution Algorithms

### 4.1 Perlin Noise (Continuous Resources)

Used for ground water and fertility. Creates natural-looking gradients.

```
Algorithm: Perlin Hybrid Distribution
─────────────────────────────────────
1. Generate base Perlin noise layer
   - Frequency: 0.008 - 0.015 (controls "blobiness")
   - Octaves: 3-4 (adds detail)
   - Persistence: 0.5 (octave falloff)

2. Generate hotspot layer
   - Place 2-4 circular hotspots randomly
   - Each hotspot has center (x,y), radius, intensity
   - Value at point = gaussian falloff from center

3. Combine layers
   - final_value = (perlin * 0.6) + (hotspots * 0.4)
   - Clamp to [0, 1]

4. Apply river influence (for water/fertility)
   - Boost values within 200px of river by 20-30%
```

**Visual Representation:**

```
Perlin Base:          Hotspots:           Combined:
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ ░░▒▒▓▓██▓▓▒▒ │    │      ██      │    │ ░░▒▒████▓▓▒▒ │
│ ░░▒▒▓▓▓▓▒▒░░ │ +  │     ████     │ =  │ ░░▒▒████▒▒░░ │
│ ▒▒▓▓▓▓▒▒░░░░ │    │    ██████    │    │ ▒▒████▓▓░░░░ │
│ ▓▓▓▓▒▒░░░░▒▒ │    │      ██      │    │ ▓▓██▒▒░░░░▒▒ │
└───────────────┘    └───────────────┘    └───────────────┘
```

### 4.2 Regional Clusters (Discrete Resources)

Used for ore deposits, oil, etc. Creates distinct deposit locations.

```
Algorithm: Regional Cluster Distribution
────────────────────────────────────────
1. Determine deposit count (random in range)

2. For each deposit:
   a. Generate random center position
   b. Check collision with:
      - River (min 100px distance)
      - Other deposits of same type (min 150px)
      - Map boundaries (50px buffer)
   c. Retry up to 50 times if collision

3. For each deposit, generate values:
   a. Center has maximum richness (0.7 - 1.0)
   b. Values fall off with distance from center
   c. Falloff formula: value = center_value * (1 - (dist/radius)^2)
   d. Add noise variation (±10%)
```

**Visual Representation:**

```
Single Ore Deposit:

      ░░░░░░░
    ░░▒▒▒▒▒▒░░
   ░░▒▒▓▓▓▓▒▒░░
  ░░▒▒▓▓██▓▓▒▒░░    █ = 0.9+ (center)
  ░░▒▒▓▓██▓▓▒▒░░    ▓ = 0.6-0.9
   ░░▒▒▓▓▓▓▒▒░░     ▒ = 0.3-0.6
    ░░▒▒▒▒▒▒░░      ░ = 0.1-0.3
      ░░░░░░░
```

### 4.3 Resource Grid Resolution

Resources are stored at grid cell level, not pixel level:

| Property | Value | Notes |
|----------|-------|-------|
| Cell Size | 20x20 pixels | Matches building grid |
| Map Size | 2500x2500 pixels | Standard map |
| Grid Size | 125x125 cells | 15,625 cells total |
| Memory | ~150KB per resource | 10 resources = 1.5MB |

---

## 5. Data Architecture

### 5.1 File Structure

```
/data/base/
├── natural_resources.json      # Resource type definitions
├── building_types.json         # Updated with placement constraints
└── resource_distribution.json  # Optional: preset distributions

/info-system/src/
├── types/
│   └── index.ts               # Updated with resource types
├── components/
│   ├── NaturalResourceManager.tsx  # NEW: Resource editor
│   └── BuildingTypeManager.tsx     # Updated: constraint editor
└── constants/
    └── index.ts               # Resource-related constants

/code/
├── NaturalResources.lua       # NEW: Resource system
├── PerlinNoise.lua            # NEW: Noise generation
├── ResourceOverlay.lua        # NEW: Visualization
├── Building.lua               # Updated: efficiency calculation
└── Town.lua                   # Updated: initialization
```

### 5.2 JSON Schema: natural_resources.json

```json
{
  "naturalResources": [
    {
      "id": "ground_water",
      "name": "Ground Water",
      "category": "continuous",
      "distribution": {
        "type": "perlin_hybrid",
        "perlinWeight": 0.6,
        "hotspotWeight": 0.4,
        "frequency": 0.01,
        "octaves": 3,
        "persistence": 0.5,
        "hotspotCount": [2, 4],
        "hotspotRadius": [150, 300],
        "hotspotIntensity": [0.6, 1.0]
      },
      "riverInfluence": {
        "enabled": true,
        "range": 200,
        "boost": 0.3
      },
      "visualization": {
        "color": [0.2, 0.5, 0.9],
        "opacity": 0.6,
        "showThreshold": 0.1
      }
    },
    {
      "id": "iron_ore",
      "name": "Iron Ore",
      "category": "discrete",
      "distribution": {
        "type": "regional_cluster",
        "depositCount": [3, 5],
        "depositRadius": [80, 150],
        "centerRichness": [0.7, 1.0],
        "falloffExponent": 2,
        "noiseVariation": 0.1
      },
      "collisionRules": {
        "riverDistance": 100,
        "sameTypeDistance": 150,
        "boundaryBuffer": 50
      },
      "visualization": {
        "color": [0.6, 0.3, 0.2],
        "opacity": 0.7,
        "showThreshold": 0.2
      }
    }
  ]
}
```

### 5.3 JSON Schema: building_types.json (Updated)

```json
{
  "buildingTypes": [
    {
      "id": "farm",
      "name": "Farm",
      "category": "agriculture",
      "placementConstraints": {
        "enabled": true,
        "requiredResources": [
          {
            "resourceId": "fertility",
            "weight": 0.7,
            "minValue": 0.2,
            "displayName": "Soil Fertility"
          },
          {
            "resourceId": "ground_water",
            "weight": 0.3,
            "minValue": 0.1,
            "displayName": "Ground Water"
          }
        ],
        "efficiencyFormula": "weighted_average",
        "warningThreshold": 0.4,
        "blockingThreshold": 0.2
      }
    },
    {
      "id": "mine",
      "name": "Mine",
      "category": "extraction",
      "placementConstraints": {
        "enabled": true,
        "requiredResources": [
          {
            "resourceId": "ore_any",
            "weight": 1.0,
            "minValue": 0.1,
            "displayName": "Ore Deposit",
            "anyOf": ["iron_ore", "copper_ore", "coal", "gold_ore", "silver_ore"]
          }
        ],
        "efficiencyFormula": "direct",
        "warningThreshold": 0.3,
        "blockingThreshold": 0.1
      }
    },
    {
      "id": "bakery",
      "name": "Bakery",
      "placementConstraints": {
        "enabled": false
      }
    }
  ]
}
```

### 5.4 TypeScript Types (info-system)

```typescript
// Natural Resource Definition
interface NaturalResource {
  id: string;
  name: string;
  category: 'continuous' | 'discrete';
  distribution: PerlinDistribution | ClusterDistribution;
  riverInfluence?: RiverInfluence;
  visualization: ResourceVisualization;
}

interface PerlinDistribution {
  type: 'perlin_hybrid';
  perlinWeight: number;
  hotspotWeight: number;
  frequency: number;
  octaves: number;
  persistence: number;
  hotspotCount: [number, number];
  hotspotRadius: [number, number];
  hotspotIntensity: [number, number];
}

interface ClusterDistribution {
  type: 'regional_cluster';
  depositCount: [number, number];
  depositRadius: [number, number];
  centerRichness: [number, number];
  falloffExponent: number;
  noiseVariation: number;
}

interface RiverInfluence {
  enabled: boolean;
  range: number;
  boost: number;
}

interface ResourceVisualization {
  color: [number, number, number];
  opacity: number;
  showThreshold: number;
}

// Placement Constraints
interface PlacementConstraints {
  enabled: boolean;
  requiredResources?: ResourceRequirement[];
  efficiencyFormula: 'weighted_average' | 'direct' | 'minimum';
  warningThreshold?: number;
  blockingThreshold?: number;
}

interface ResourceRequirement {
  resourceId: string;
  weight: number;
  minValue: number;
  displayName: string;
  anyOf?: string[];  // For "any ore" type requirements
}
```

### 5.5 Lua Data Structures

```lua
-- Resource grid (per resource type)
ResourceGrid = {
    resourceId = "ground_water",
    cellSize = 20,
    width = 125,      -- cells
    height = 125,     -- cells
    values = {},      -- 2D array [x][y] = 0.0-1.0
}

-- Resource manager (holds all grids)
NaturalResources = {
    grids = {},           -- keyed by resource ID
    definitions = {},     -- loaded from JSON
    overlayVisible = {},  -- which overlays are showing
}

-- Building efficiency data (stored on building)
Building.locationEfficiency = {
    baseEfficiency = 0.74,
    resourceBreakdown = {
        fertility = 0.8,
        ground_water = 0.6
    }
}
```

---

## 6. Building Placement Constraints

### 6.1 Constraint Types

| Building Type | Required Resources | Formula | Min Threshold |
|---------------|-------------------|---------|---------------|
| Farm | Fertility (70%) + Water (30%) | Weighted Average | 0.2 |
| Mine | Any Ore | Direct | 0.1 |
| Quarry | Stone | Direct | 0.3 |
| Oil Derrick | Oil | Direct | 0.5 |
| Gas Well | Natural Gas | Direct | 0.5 |
| Well | Ground Water | Direct | 0.3 |

### 6.2 Efficiency Formulas

**Weighted Average** (for multiple resources):
```
efficiency = Σ(resource_value[i] * weight[i])
```

**Direct** (for single resource):
```
efficiency = resource_value
```

**Minimum** (all resources must meet threshold):
```
efficiency = min(resource_value[i] for all i)
```

### 6.3 Placement Feedback

When placing a building with constraints:

| Condition | Visual | Message |
|-----------|--------|---------|
| efficiency >= 0.6 | Green outline | "Excellent location (X%)" |
| 0.4 <= efficiency < 0.6 | Yellow outline | "Moderate location (X%)" |
| threshold <= efficiency < 0.4 | Orange outline | "Poor location (X%)" |
| efficiency < threshold | Red outline | "Cannot build here (insufficient X)" |

---

## 7. Efficiency Calculation

### 7.1 Calculation Flow

```
Building Placement Request
         │
         ▼
┌─────────────────────────┐
│ Get building footprint  │
│ (x, y, width, height)   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ Get all cells covered   │
│ by building footprint   │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ For each required       │
│ resource:               │
│ - Average value across  │
│   all covered cells     │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ Apply efficiency        │
│ formula (weighted avg,  │
│ direct, or minimum)     │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ Store on building       │
│ Return efficiency       │
└─────────────────────────┘
```

### 7.2 Sample Calculation

**Scenario:** Placing a 80x80 Farm at position (200, 300)

```
Step 1: Get covered cells
- Cell range: x=[10,13], y=[15,18] (4x4 = 16 cells)

Step 2: Average resource values
- Fertility values: [0.7, 0.8, 0.9, 0.8, 0.6, 0.7, 0.8, 0.9, ...]
- Average fertility: 0.78
- Water values: [0.5, 0.6, 0.5, 0.4, 0.6, 0.7, 0.5, 0.6, ...]
- Average water: 0.55

Step 3: Apply weighted average
- efficiency = (0.78 * 0.7) + (0.55 * 0.3)
- efficiency = 0.546 + 0.165 = 0.711

Step 4: Store result
- building.locationEfficiency = 0.711 (71.1%)
```

### 7.3 Production Impact

The location efficiency multiplies the building's base production rate:

```
actual_production = base_production * worker_efficiency * location_efficiency
```

---

## 8. Visualization System

### 8.1 Overlay Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    RENDER LAYERS                        │
├─────────────────────────────────────────────────────────┤
│ Layer 5: UI / HUD                                       │
│ Layer 4: Buildings / Characters                         │
│ Layer 3: Resource Overlays (toggle-able)    ◄── NEW     │
│ Layer 2: Trees / Natural Objects                        │
│ Layer 1: Terrain / Ground                               │
│ Layer 0: Water / River                                  │
└─────────────────────────────────────────────────────────┘
```

### 8.2 Overlay Controls

```
┌──────────────────────────────────────┐
│  Resource Overlays          [Hide All]│
├──────────────────────────────────────┤
│  [✓] Ground Water      ████████      │
│  [✓] Fertility         ████████      │
│  [ ] Iron Ore          ████████      │
│  [ ] Copper Ore        ████████      │
│  [ ] Coal              ████████      │
│  [ ] Gold Ore          ████████      │
│  [ ] Silver Ore        ████████      │
│  [ ] Stone             ████████      │
│  [ ] Oil               ████████      │
│  [ ] Natural Gas       ████████      │
└──────────────────────────────────────┘
```

### 8.3 Rendering Approach

Each visible overlay renders as a semi-transparent color grid:

```lua
function ResourceOverlay:Render(resourceId)
    local grid = self.grids[resourceId]
    local viz = self.definitions[resourceId].visualization

    for x = 1, grid.width do
        for y = 1, grid.height do
            local value = grid.values[x][y]
            if value >= viz.showThreshold then
                -- Color intensity based on value
                love.graphics.setColor(
                    viz.color[1],
                    viz.color[2],
                    viz.color[3],
                    value * viz.opacity
                )
                love.graphics.rectangle("fill",
                    (x-1) * grid.cellSize,
                    (y-1) * grid.cellSize,
                    grid.cellSize,
                    grid.cellSize
                )
            end
        end
    end
end
```

### 8.4 Performance Optimization

- Only render visible overlays
- Use shader-based rendering for large grids
- Cache overlay textures (regenerate only on toggle)
- Reduce opacity for distant zoom levels

---

## 9. Integration Points

### 9.1 Town Initialization

```lua
-- Town.lua
function Town:Create(params)
    -- Existing initialization...
    self.river = River:Create(params)
    self.forest = Forest:Create(params)

    -- NEW: Initialize natural resources
    self.naturalResources = NaturalResources:Create({
        river = self.river,
        boundaryMinX = params.minX,
        boundaryMaxX = params.maxX,
        boundaryMinY = params.minY,
        boundaryMaxY = params.maxY
    })

    -- Continue with mines, mountains, etc...
end
```

### 9.2 Building Placement

```lua
-- BuildingManager.lua (or Building.lua)
function BuildingManager:PlaceBuilding(buildingType, x, y)
    -- Get placement constraints from building type data
    local constraints = buildingType.placementConstraints

    if constraints and constraints.enabled then
        -- Calculate efficiency
        local efficiency, breakdown = self.naturalResources:CalculateEfficiency(
            x, y,
            buildingType.width,
            buildingType.height,
            constraints
        )

        -- Check minimum threshold
        if efficiency < constraints.blockingThreshold then
            return false, "Insufficient resources"
        end

        -- Store efficiency on building
        building.locationEfficiency = efficiency
        building.resourceBreakdown = breakdown
    else
        building.locationEfficiency = 1.0
    end

    -- Continue with placement...
end
```

### 9.3 Production System Integration

```lua
-- In production calculation
function Building:CalculateProduction()
    local baseRate = self.recipe.outputRate
    local workerEff = self:CalculateWorkerEfficiency()
    local locationEff = self.locationEfficiency or 1.0

    return baseRate * workerEff * locationEff
end
```

---

## 10. Future Considerations

### 10.1 Resource Depletion (Not in v1)

Could be added later:
- Mines deplete over time
- Oil wells run dry
- Depletion rate based on extraction rate
- Discovery of new deposits via exploration

### 10.2 Seasonal Variation (Not in v1)

Could be added:
- Fertility changes with seasons
- Water table varies with rainfall
- Winter affects surface water

### 10.3 Technology Impact (Not in v1)

Could be added:
- Advanced mining increases ore yield
- Irrigation improves water access
- Fertilizers boost fertility

### 10.4 Trading & Transportation (Not in v1)

- Resources can be transported (cost penalty)
- Trading post for resource exchange
- Pipeline system for oil/gas

---

## Appendix A: Resource Color Scheme

| Resource | RGB | Hex | Preview |
|----------|-----|-----|---------|
| Ground Water | (51, 128, 230) | #3380E6 | Blue |
| Fertility | (76, 153, 51) | #4C9933 | Green |
| Iron Ore | (153, 77, 51) | #994D33 | Brown-Red |
| Copper Ore | (204, 128, 77) | #CC804D | Orange-Brown |
| Coal | (51, 51, 51) | #333333 | Dark Gray |
| Gold Ore | (230, 204, 51) | #E6CC33 | Gold |
| Silver Ore | (192, 192, 192) | #C0C0C0 | Silver |
| Stone | (128, 128, 128) | #808080 | Gray |
| Oil | (26, 26, 26) | #1A1A1A | Black |
| Natural Gas | (179, 230, 255) | #B3E6FF | Light Blue |
| Clay | (204, 153, 102) | #CC9966 | Tan |

---

## Appendix B: Default Distribution Parameters

```json
{
  "ground_water": {
    "frequency": 0.01,
    "octaves": 3,
    "hotspots": [2, 4],
    "riverBoost": 0.3
  },
  "fertility": {
    "frequency": 0.012,
    "octaves": 4,
    "hotspots": [3, 5],
    "riverBoost": 0.2
  },
  "iron_ore": {
    "deposits": [3, 5],
    "radius": [80, 150]
  },
  "copper_ore": {
    "deposits": [2, 4],
    "radius": [60, 120]
  },
  "coal": {
    "deposits": [2, 4],
    "radius": [100, 180]
  },
  "gold_ore": {
    "deposits": [1, 2],
    "radius": [40, 80]
  },
  "silver_ore": {
    "deposits": [1, 2],
    "radius": [40, 80]
  },
  "stone": {
    "deposits": [4, 6],
    "radius": [80, 150]
  },
  "oil": {
    "deposits": [1, 2],
    "radius": [60, 100]
  },
  "natural_gas": {
    "deposits": [1, 3],
    "radius": [50, 90]
  },
  "clay": {
    "deposits": [2, 4],
    "radius": [60, 100]
  }
}
```
