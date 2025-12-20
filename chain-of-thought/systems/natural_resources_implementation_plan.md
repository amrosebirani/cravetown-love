# Natural Resources System - Implementation Plan

**Version:** 1.0
**Created:** 2025-11-30
**Status:** Ready for Implementation
**Related:** [Architecture Document](./natural_resources_architecture.md)

---

## Overview

This document outlines the step-by-step implementation plan for the Natural Resources System. The plan is divided into phases, with each phase containing specific, testable tasks.

---

## Phase Summary

| Phase | Name | Tasks | Dependencies |
|-------|------|-------|--------------|
| 1 | Data Layer & Info System | 8 | None |
| 2 | Perlin Noise Implementation | 5 | None |
| 3 | Resource Distribution (Lua) | 10 | Phase 2 |
| 4 | Building Constraints | 6 | Phase 1, 3 |
| 5 | Visualization System | 7 | Phase 3 |
| 6 | Integration & Testing | 6 | All |

**Total Tasks:** 42

---

## Phase 1: Data Layer & Info System

**Goal:** Define all resource types and building constraints in the data layer, create management UI.

### Task 1.1: Create Natural Resource Types Definition

**File:** `info-system/src/types/index.ts`

Add TypeScript interfaces:
- `NaturalResource`
- `PerlinDistribution`
- `ClusterDistribution`
- `RiverInfluence`
- `ResourceVisualization`
- `NaturalResourcesData`

**Acceptance Criteria:**
- [ ] All interfaces defined and exported
- [ ] No TypeScript errors

---

### Task 1.2: Create natural_resources.json

**File:** `data/base/natural_resources.json`

Create JSON file with all 11 resource definitions:
- ground_water (perlin_hybrid)
- fertility (perlin_hybrid)
- iron_ore (regional_cluster)
- copper_ore (regional_cluster)
- coal (regional_cluster)
- gold_ore (regional_cluster)
- silver_ore (regional_cluster)
- stone (regional_cluster)
- oil (regional_cluster)
- natural_gas (regional_cluster)
- clay (regional_cluster)

**Acceptance Criteria:**
- [ ] Valid JSON syntax
- [ ] All resources have required fields
- [ ] Distribution parameters match architecture doc

---

### Task 1.3: Add Placement Constraint Types

**File:** `info-system/src/types/index.ts`

Add to existing BuildingType interface:
- `PlacementConstraints`
- `ResourceRequirement`

**Acceptance Criteria:**
- [ ] Types integrated with existing BuildingType
- [ ] Optional `placementConstraints` field added

---

### Task 1.4: Create API Functions for Natural Resources

**File:** `info-system/src/api/index.ts`

Add functions:
- `loadNaturalResources(): Promise<NaturalResourcesData>`
- `saveNaturalResources(data: NaturalResourcesData): Promise<void>`

**Acceptance Criteria:**
- [ ] Functions load/save from correct path
- [ ] Error handling in place

---

### Task 1.5: Create NaturalResourceManager Component

**File:** `info-system/src/components/NaturalResourceManager.tsx`

Create React component to manage natural resource definitions:
- Table listing all resources
- Add/Edit/Delete functionality
- Form for resource properties
- Distribution type selector (perlin vs cluster)
- Color picker for visualization
- Parameter editors for distribution settings

**Acceptance Criteria:**
- [ ] Can view list of resources
- [ ] Can add new resource
- [ ] Can edit existing resource
- [ ] Can delete resource
- [ ] Changes persist to JSON

---

### Task 1.6: Add Resource Constants

**File:** `info-system/src/constants/index.ts`

Add:
- `RESOURCE_CATEGORIES = ['continuous', 'discrete']`
- `DISTRIBUTION_TYPES = ['perlin_hybrid', 'regional_cluster']`
- `EFFICIENCY_FORMULAS = ['weighted_average', 'direct', 'minimum']`

**Acceptance Criteria:**
- [ ] Constants exported and usable

---

### Task 1.7: Update BuildingTypeManager - Add Constraints Tab

**File:** `info-system/src/components/BuildingTypeManager.tsx`

Add new tab "Placement Constraints" with:
- Enable/disable toggle
- Resource requirement list
- Add/remove resource requirements
- Weight and minValue inputs
- Efficiency formula selector
- Warning/blocking threshold inputs

**Acceptance Criteria:**
- [ ] New tab visible in building editor
- [ ] Can enable/disable constraints
- [ ] Can add resource requirements
- [ ] Can set weights and thresholds
- [ ] Changes save to building_types.json

---

### Task 1.8: Update building_types.json with Constraints

**File:** `data/base/building_types.json`

Add `placementConstraints` to relevant buildings:
- Farm: fertility + ground_water
- Mine: ore_any (iron, copper, coal, gold, silver)

Leave `enabled: false` for buildings without constraints:
- Sawmill, Bakery, Restaurant, etc.

**Acceptance Criteria:**
- [ ] Farm has correct constraints
- [ ] Mine has correct constraints
- [ ] Other buildings have disabled constraints
- [ ] JSON validates correctly

---

## Phase 2: Perlin Noise Implementation

**Goal:** Create a robust Perlin noise generator in Lua for continuous resource distribution.

### Task 2.1: Create PerlinNoise.lua Base

**File:** `code/PerlinNoise.lua`

Implement:
- `PerlinNoise:Create(seed)` - constructor with seed
- Permutation table generation
- Gradient vectors

**Acceptance Criteria:**
- [ ] Deterministic output for same seed
- [ ] No external dependencies

---

### Task 2.2: Implement 2D Perlin Noise

**File:** `code/PerlinNoise.lua`

Add method:
- `PerlinNoise:noise2D(x, y)` - returns value -1 to 1

Implement:
- Fade function (smoothstep)
- Linear interpolation
- Dot product with gradient

**Acceptance Criteria:**
- [ ] Returns values in -1 to 1 range
- [ ] Smooth transitions between cells
- [ ] Performance: < 1ms for 1000 calls

---

### Task 2.3: Implement Octave Noise (fBm)

**File:** `code/PerlinNoise.lua`

Add method:
- `PerlinNoise:fbm(x, y, octaves, persistence, frequency)`

Implement fractal Brownian motion:
- Multiple noise layers
- Each octave doubles frequency, reduces amplitude

**Acceptance Criteria:**
- [ ] Configurable octaves (1-8)
- [ ] Output normalized to 0-1 range
- [ ] More detail with more octaves

---

### Task 2.4: Add Hotspot Generation

**File:** `code/PerlinNoise.lua`

Add methods:
- `PerlinNoise:generateHotspots(count, bounds, radiusRange)`
- `PerlinNoise:hotspotValue(x, y, hotspots)` - gaussian falloff

**Acceptance Criteria:**
- [ ] Hotspots placed within bounds
- [ ] Smooth falloff from center
- [ ] No overlapping hotspot centers

---

### Task 2.5: Create Noise Test/Debug Mode

**File:** `code/PerlinNoise.lua` or `code/NoiseTest.lua`

Add visualization function:
- Generate noise texture
- Display as grayscale image
- Toggle between raw noise, fbm, hotspots

**Acceptance Criteria:**
- [ ] Can visualize noise output
- [ ] Useful for debugging parameters

---

## Phase 3: Resource Distribution (Lua)

**Goal:** Generate resource grids using the distribution algorithms.

### Task 3.1: Create NaturalResources.lua Base

**File:** `code/NaturalResources.lua`

Implement:
- `NaturalResources:Create(params)` - constructor
- Load resource definitions from JSON
- Initialize empty grids structure
- Store river reference

**Acceptance Criteria:**
- [ ] Loads definitions from data/base/natural_resources.json
- [ ] Creates grid structure for each resource
- [ ] Stores boundary parameters

---

### Task 3.2: Implement Resource Grid Structure

**File:** `code/NaturalResources.lua`

Add:
- Grid data structure (2D array)
- Cell size configuration (20px default)
- `getCell(worldX, worldY)` - convert world coords to grid
- `getValue(resourceId, worldX, worldY)` - get resource value

**Acceptance Criteria:**
- [ ] Grid dimensions match map size
- [ ] Coordinate conversion accurate
- [ ] Can read values at any world position

---

### Task 3.3: Implement Continuous Distribution Generator

**File:** `code/NaturalResources.lua`

Add method:
- `NaturalResources:generateContinuousResource(resourceDef)`

Algorithm:
1. Generate base Perlin noise
2. Generate hotspots
3. Combine with weights
4. Apply river influence if enabled
5. Normalize to 0-1

**Acceptance Criteria:**
- [ ] Ground water generates correctly
- [ ] Fertility generates correctly
- [ ] River boost visible near river
- [ ] Values in 0-1 range

---

### Task 3.4: Implement Cluster Distribution Generator

**File:** `code/NaturalResources.lua`

Add method:
- `NaturalResources:generateClusterResource(resourceDef)`

Algorithm:
1. Determine deposit count
2. Place deposit centers (with collision checks)
3. For each cell, calculate value based on distance to nearest deposit
4. Apply falloff and noise variation

**Acceptance Criteria:**
- [ ] Correct number of deposits generated
- [ ] Deposits avoid river
- [ ] Deposits don't overlap excessively
- [ ] Smooth falloff from deposit centers

---

### Task 3.5: Add Collision Detection for Deposits

**File:** `code/NaturalResources.lua`

Add methods:
- `isNearRiver(x, y, minDistance)`
- `isNearOtherDeposit(x, y, deposits, minDistance)`
- `isInBounds(x, y, buffer)`

**Acceptance Criteria:**
- [ ] Deposits placed away from river
- [ ] Same-type deposits have spacing
- [ ] Deposits within map boundaries

---

### Task 3.6: Implement generateAll Method

**File:** `code/NaturalResources.lua`

Add method:
- `NaturalResources:generateAll()`

Generate all resources in order:
1. Continuous resources first (water, fertility)
2. Discrete resources (ores, etc.)

**Acceptance Criteria:**
- [ ] All 11 resources generate
- [ ] Generation completes in < 500ms
- [ ] Memory usage reasonable (< 5MB)

---

### Task 3.7: Add Resource Query Methods

**File:** `code/NaturalResources.lua`

Add methods:
- `getResourceValue(resourceId, x, y)` - single point
- `getAverageValue(resourceId, x, y, width, height)` - area average
- `getMaxValueInArea(resourceId, x, y, width, height)` - for deposits

**Acceptance Criteria:**
- [ ] Point queries fast (< 0.1ms)
- [ ] Area queries accurate
- [ ] Handle edge cases (out of bounds)

---

### Task 3.8: Implement Efficiency Calculation

**File:** `code/NaturalResources.lua`

Add method:
- `calculateBuildingEfficiency(buildingType, x, y, width, height)`

Returns:
- efficiency (0-1)
- breakdown (resource -> value mapping)
- canPlace (boolean based on threshold)

**Acceptance Criteria:**
- [ ] Weighted average formula works
- [ ] Direct formula works
- [ ] Minimum formula works
- [ ] Respects min thresholds

---

### Task 3.9: Add "Any Of" Resource Matching

**File:** `code/NaturalResources.lua`

For mine-type buildings that accept multiple ore types:
- Check all resources in `anyOf` list
- Return highest value found
- Track which resource provided the value

**Acceptance Criteria:**
- [ ] Mine can be placed on any ore type
- [ ] Uses highest ore value at location
- [ ] Reports which ore type is dominant

---

### Task 3.10: Add Serialization Support

**File:** `code/NaturalResources.lua`

Add methods:
- `serialize()` - convert grids to saveable format
- `deserialize(data)` - restore from saved data

**Acceptance Criteria:**
- [ ] Can save resource grids
- [ ] Can load resource grids
- [ ] Loaded data matches original

---

## Phase 4: Building Constraints

**Goal:** Integrate resource constraints into building placement.

### Task 4.1: Update DataLoader for Constraints

**File:** `code/DataLoader.lua`

Update `loadBuildingTypes()` to include:
- `placementConstraints` field
- Validate constraint data structure

**Acceptance Criteria:**
- [ ] Constraints loaded from JSON
- [ ] Missing constraints default to disabled
- [ ] No errors on load

---

### Task 4.2: Add Efficiency to Building Creation

**File:** `code/Building.lua` or relevant building file

When creating building:
- Check if constraints enabled
- Calculate efficiency via NaturalResources
- Store on building instance

**Acceptance Criteria:**
- [ ] Buildings with constraints get efficiency calculated
- [ ] Buildings without constraints get efficiency = 1.0
- [ ] Efficiency accessible for production calc

---

### Task 4.3: Add Placement Validation

**File:** Placement handling code

Before placing building:
- Check if location meets minimum threshold
- Return appropriate error if cannot place

**Acceptance Criteria:**
- [ ] Cannot place farm on barren land
- [ ] Cannot place mine without ore
- [ ] Clear error message shown

---

### Task 4.4: Add Placement Preview Feedback

**File:** UI/rendering code for building placement

When hovering placement location:
- Calculate efficiency preview
- Show color-coded outline (green/yellow/orange/red)
- Display efficiency percentage

**Acceptance Criteria:**
- [ ] Green for > 60% efficiency
- [ ] Yellow for 40-60%
- [ ] Orange for threshold to 40%
- [ ] Red for below threshold (can't place)

---

### Task 4.5: Integrate Efficiency into Production

**File:** Production calculation code

Modify production formula:
```
actual = base * workerEfficiency * locationEfficiency
```

**Acceptance Criteria:**
- [ ] Farm produces more on fertile land
- [ ] Mine produces more on rich ore
- [ ] Effect is observable in game

---

### Task 4.6: Add Building Info Display

**File:** Building info UI

Show in building details:
- Location efficiency percentage
- Resource breakdown (what resources affect it)
- Tier label (Poor/Moderate/Good/Excellent)

**Acceptance Criteria:**
- [ ] Efficiency visible in building info
- [ ] Breakdown shows individual resources
- [ ] Clear and understandable

---

## Phase 5: Visualization System

**Goal:** Create toggle-able overlay system for viewing resource distribution.

### Task 5.1: Create ResourceOverlay.lua Base

**File:** `code/ResourceOverlay.lua`

Implement:
- `ResourceOverlay:Create(naturalResources)`
- Track visible overlays (table of booleans)
- Store rendering parameters

**Acceptance Criteria:**
- [ ] Links to NaturalResources instance
- [ ] Can track which overlays are visible

---

### Task 5.2: Implement Single Resource Render

**File:** `code/ResourceOverlay.lua`

Add method:
- `renderResource(resourceId)`

Render grid as colored rectangles:
- Color from resource definition
- Alpha based on value
- Skip cells below showThreshold

**Acceptance Criteria:**
- [ ] Renders correct color
- [ ] Intensity matches value
- [ ] Transparent where no resource

---

### Task 5.3: Implement Overlay Toggle

**File:** `code/ResourceOverlay.lua`

Add methods:
- `toggleOverlay(resourceId)`
- `showOverlay(resourceId)`
- `hideOverlay(resourceId)`
- `hideAll()`

**Acceptance Criteria:**
- [ ] Can toggle individual overlays
- [ ] Can show multiple overlays
- [ ] Can hide all at once

---

### Task 5.4: Add Render Method

**File:** `code/ResourceOverlay.lua`

Add method:
- `render()` - render all visible overlays

Call from appropriate render layer (between terrain and buildings).

**Acceptance Criteria:**
- [ ] Overlays render in correct layer
- [ ] Multiple overlays can blend
- [ ] Performance acceptable

---

### Task 5.5: Create Overlay Control Panel UI

**File:** Game UI code

Add panel with:
- Title "Resource Overlays"
- Checkbox for each resource
- Color swatch next to each
- "Hide All" button

**Acceptance Criteria:**
- [ ] Panel visible in game
- [ ] Checkboxes toggle overlays
- [ ] Visual feedback for active overlays

---

### Task 5.6: Add Keyboard Shortcuts

**File:** Input handling code

Add shortcuts:
- `R` - Toggle overlay panel visibility
- `1-9` - Quick toggle specific resources (optional)

**Acceptance Criteria:**
- [ ] R key toggles panel
- [ ] Shortcuts work when not in text input

---

### Task 5.7: Optimize Overlay Rendering

**File:** `code/ResourceOverlay.lua`

Optimizations:
- Only re-render changed overlays
- Use canvas/texture caching
- Reduce draw calls

**Acceptance Criteria:**
- [ ] Smooth performance with overlays on
- [ ] No visible lag when toggling
- [ ] Maintains 60 FPS

---

## Phase 6: Integration & Testing

**Goal:** Connect all systems and verify everything works together.

### Task 6.1: Update Town.lua Initialization

**File:** `code/Town.lua`

Add to Town:Create():
```lua
self.naturalResources = NaturalResources:Create({
    river = self.river,
    boundaries = {...}
})
self.naturalResources:generateAll()
self.resourceOverlay = ResourceOverlay:Create(self.naturalResources)
```

**Acceptance Criteria:**
- [ ] Resources generate on town creation
- [ ] No errors during initialization
- [ ] Resources accessible from town

---

### Task 6.2: Add Overlay Rendering to Town

**File:** `code/Town.lua`

In Town:Render():
- Add overlay render call at appropriate layer

**Acceptance Criteria:**
- [ ] Overlays visible when enabled
- [ ] Correct layer ordering

---

### Task 6.3: Integration Test - Farm Placement

**Test:**
1. Start new game
2. Enable fertility overlay
3. Find high fertility area
4. Place farm
5. Verify efficiency matches visual

**Acceptance Criteria:**
- [ ] Farm efficiency correlates with overlay color
- [ ] Cannot place farm in zero fertility area
- [ ] Production affected by efficiency

---

### Task 6.4: Integration Test - Mine Placement

**Test:**
1. Start new game
2. Enable iron ore overlay
3. Find ore deposit
4. Place mine on deposit
5. Verify high efficiency
6. Try placing mine away from ore
7. Verify blocked or low efficiency

**Acceptance Criteria:**
- [ ] Mine requires ore deposit
- [ ] Efficiency based on ore richness
- [ ] Multiple ore types work

---

### Task 6.5: Save/Load Test

**Test:**
1. Generate resources
2. Save game
3. Load game
4. Verify resources match

**Acceptance Criteria:**
- [ ] Resources persist across save/load
- [ ] No regeneration on load
- [ ] Building efficiencies preserved

---

### Task 6.6: Performance Test

**Test:**
1. Generate full map resources
2. Enable all overlays
3. Pan around map
4. Monitor FPS

**Acceptance Criteria:**
- [ ] 60 FPS maintained
- [ ] No memory leaks
- [ ] Overlay toggle responsive

---

## Implementation Notes

### Dependencies Between Tasks

```
Phase 1 (Data) ──────────────────────────────┐
                                             │
Phase 2 (Perlin) ─────┐                      │
                      │                      │
                      ▼                      ▼
              Phase 3 (Distribution) ◄───────┤
                      │                      │
                      ▼                      │
              Phase 4 (Constraints) ◄────────┘
                      │
                      ▼
              Phase 5 (Visualization)
                      │
                      ▼
              Phase 6 (Integration)
```

### Suggested Order

1. **Phase 1** and **Phase 2** can be done in parallel
2. **Phase 3** requires Phase 2
3. **Phase 4** requires Phase 1 and Phase 3
4. **Phase 5** requires Phase 3
5. **Phase 6** requires all previous phases

### Testing Strategy

- Unit test Perlin noise functions
- Unit test grid queries
- Integration test placement constraints
- Manual test visualizations
- Performance test with full data

---

## Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2025-11-30 | 1.0 | Initial plan created |
