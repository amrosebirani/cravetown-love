# CRAVE-10: System Verification - Productivity, Terrain, Economy

**Created:** 2026-01-11
**Linear Issue:** [CRAVE-10](https://linear.app/cravetown-dev/issue/CRAVE-10/f-system-verification-productivity-terrain-economy)
**Status:** In Progress
**Priority:** High

---

## Objective

Verify that key systems from UI spec are actually connected and working:
1. **F1:** Satisfaction → Worker Productivity → Production Rate
2. **F2:** Terrain/Fertility → Building Placement → Production Efficiency

---

## Executive Summary

| System | Current State | Verdict |
|--------|---------------|---------|
| F1: Satisfaction → Production | Implemented (town-wide) | **WORKING** - but granularity may need review |
| F2: Terrain → Production | Fully implemented | **WORKING** - needs verification test |

Both systems are implemented and connected. Verification tests need to be added to the debug panel to confirm behavior in-game.

---

## Part 1: Code Path Analysis

### F1: Satisfaction → Production Connection

#### Current Implementation Flow

```
Character Satisfaction
        ↓
CharacterV2.lua:UpdateProductivity()
        ↓
character.productivityMultiplier (0.1 to 1.0)
        ↓
TownConsequences.lua:CalculateTownStats()
        ↓
world.stats.productivityMultiplier (town-wide average)
        ↓
AlphaWorld.lua:updateProduction() (line ~1689)
        ↓
efficiency = productivityMultiplier * resourceEfficiency
        ↓
Production Rate Applied
```

#### Key Code Locations

| File | Function/Line | Purpose |
|------|---------------|---------|
| `code/consumption/CharacterV2.lua` | `UpdateProductivity()` | Calculates individual productivity from satisfaction |
| `code/consumption/TownConsequences.lua` | `CalculateTownStats()` | Aggregates to town-wide multiplier |
| `code/AlphaWorld.lua` | `updateProduction()` ~L1689 | Applies efficiency to production rate |

#### Productivity Formula (from CharacterV2.lua)

```lua
-- Satisfaction range: typically 0-100 (can go negative or above)
-- Productivity calculation:
if avgSatisfaction < 50 then
    productivityMultiplier = math.max(0.1, avgSatisfaction / 50)
else
    productivityMultiplier = 1.0
end
```

**Effect Table:**

| Avg Satisfaction | Productivity Multiplier | Production Rate |
|------------------|------------------------|-----------------|
| 100 | 1.0 | 100% |
| 75 | 1.0 | 100% |
| 50 | 1.0 | 100% |
| 40 | 0.8 | 80% |
| 25 | 0.5 | 50% |
| 10 | 0.2 | 20% |
| 0 | 0.1 (floor) | 10% |

#### Verdict: **WORKING**

The connection exists and is proportionate. Satisfaction below 50 linearly reduces productivity.

---

### F2: Terrain/Fertility → Production Connection

#### Current Implementation Flow

```
Map Generation (NaturalResources.lua)
        ↓
Resource Grid (fertility, ground_water per cell)
        ↓
Building Placement (AlphaWorld.lua)
        ↓
calculateLocationEfficiency() called
        ↓
building.resourceEfficiency stored (0.0 to 1.0)
        ↓
Production applies: efficiency = productivityMultiplier * resourceEfficiency
        ↓
Production Rate Applied
```

#### Key Code Locations

| File | Function/Line | Purpose |
|------|---------------|---------|
| `code/NaturalResources.lua` | `NaturalResources:new()` | Generates resource distribution |
| `code/NaturalResources.lua` | `getResourceAt()` | Returns resource value at position |
| `code/AlphaNaturalResources.lua` | `calculateLocationEfficiency()` | Calculates building efficiency from terrain |
| `code/AlphaWorld.lua` | Building placement | Stores `resourceEfficiency` on building |

#### Efficiency Formula (from natural_resources_architecture.md)

```lua
-- Building-specific resource weights
local resourceWeights = {
    ["farm"] = { fertility = 0.7, ground_water = 0.3 },
    ["mine"] = { iron_ore = 0.5, coal = 0.3, stone = 0.2 },
    ["lumber_mill"] = { -- proximity to forest },
    -- etc.
}

-- Weighted average calculation
locationEfficiency = sum(resourceValue[i] * weight[i]) / sum(weight[i])
```

**Effect Table (Farm Example):**

| Fertility | Ground Water | Location Efficiency | Production Rate* |
|-----------|--------------|---------------------|------------------|
| 1.0 | 1.0 | 1.0 | 100% |
| 0.8 | 0.6 | 0.74 | 74% |
| 0.5 | 0.5 | 0.5 | 50% |
| 0.3 | 0.2 | 0.27 | 27% |
| 0.0 | 0.0 | 0.0 | 0% |

*Assuming productivityMultiplier = 1.0

#### Verdict: **WORKING**

The connection exists and is proportionate. Terrain directly affects production through `resourceEfficiency`.

---

## Part 2: Verification Tests

### Test F1: Satisfaction → Production Rate

#### Test Procedure

1. Start game with default town
2. Open Debug Panel → Buildings tab
3. Select a producing building (e.g., Farm)
4. Note current production rate/cycle time
5. Use satisfaction override slider to set town satisfaction to 25%
6. Observe production rate change
7. Verify rate is ~50% of original (since 25/50 = 0.5 multiplier)

#### Expected Results

| Satisfaction Override | Expected Productivity | Expected Production |
|----------------------|----------------------|---------------------|
| 100% | 1.0 | Normal |
| 50% | 1.0 | Normal |
| 25% | 0.5 | Half speed |
| 10% | 0.2 | 1/5 speed |

#### Debug Panel Addition Required

**New Control: Satisfaction Override Slider**
- Location: Debug Panel → Overview tab (or new "Testing" tab)
- Control: Slider (0-100) + "Override Active" checkbox
- Effect: When active, bypasses natural satisfaction calculation and sets all characters to slider value
- Display: Show current `world.stats.productivityMultiplier` value

---

### Test F2: Terrain/Fertility → Production Rate

#### Test Procedure

1. Start game with default town
2. Enable Resource Overlay (Fertility view)
3. Identify high fertility area (green) and low fertility area (red/brown)
4. Place Farm A on high fertility (~0.8+)
5. Place Farm B on low fertility (~0.3 or below)
6. Open Debug Panel → Buildings tab
7. Compare `resourceEfficiency` values for both farms
8. Observe production rates differ proportionally

#### Expected Results

| Farm Location | Fertility | Expected Efficiency | Production vs Optimal |
|---------------|-----------|--------------------|-----------------------|
| High fertility | 0.8 | ~0.74-0.86 | 74-86% |
| Low fertility | 0.3 | ~0.27-0.35 | 27-35% |

#### Debug Panel Addition Required

**Enhancement: Show Resource Efficiency in Building Detail**
- Location: Debug Panel → Buildings tab → Building Detail popup
- Display: Add `Resource Efficiency: X.XX` field
- Also show: Breakdown by resource type (fertility: X.X, ground_water: X.X)

---

## Part 3: Implementation Plan

### Phase 1: Debug Panel Enhancements

#### Task 1.1: Add Satisfaction Override Control

**File:** `code/DebugPanel.lua`

**Implementation:**
```lua
-- Add to Overview tab or create new "Testing" tab
-- Components:
-- 1. Checkbox: "Override Satisfaction"
-- 2. Slider: 0-100 value
-- 3. Display: Current productivityMultiplier

-- When override is active:
-- In TownConsequences.CalculateTownStats():
if debugPanel.satisfactionOverride.active then
    world.stats.productivityMultiplier = debugPanel.satisfactionOverride.value / 50
    -- Clamp to 0.1-1.0 range per formula
end
```

**UI Layout:**
```
┌─ Testing ─────────────────────────────┐
│ [x] Override Satisfaction             │
│ Value: [====●=====] 50                │
│                                       │
│ Current Productivity: 1.00x           │
│ Expected Production: 100%             │
└───────────────────────────────────────┘
```

#### Task 1.2: Add Resource Efficiency to Building Detail

**File:** `code/DebugPanel.lua`

**Implementation:**
- In `drawBuildingDetail()` function
- Add section showing `building.resourceEfficiency`
- Show breakdown if available

**UI Addition:**
```
┌─ Building Detail: Farm #3 ────────────┐
│ Type: Farm                            │
│ Workers: 2/2                          │
│                                       │
│ ── Location Efficiency ──             │  ← NEW
│ Overall: 0.74                         │
│   Fertility: 0.80 (weight: 0.7)       │
│   Ground Water: 0.60 (weight: 0.3)    │
│                                       │
│ ── Production ──                      │
│ State: PRODUCING                      │
│ Progress: 45%                         │
│ Effective Rate: 74% (0.74 × 1.0)      │  ← Shows both multipliers
└───────────────────────────────────────┘
```

### Phase 2: Verification Execution

#### Task 2.1: F1 Verification

1. Implement satisfaction override (Task 1.1)
2. Run test procedure for F1
3. Document results with screenshots
4. Mark F1 as VERIFIED or identify fix needed

#### Task 2.2: F2 Verification

1. Implement resource efficiency display (Task 1.2)
2. Run test procedure for F2
3. Document results with screenshots
4. Mark F2 as VERIFIED or identify fix needed

### Phase 3: Fix Any Broken Systems (if needed)

Based on code analysis, both systems appear functional. However, if verification reveals issues:

#### Potential Fix F1: Per-Worker Productivity (if needed)

Current: Town-wide productivity affects all buildings equally
Alternative: Each worker's individual satisfaction affects their assigned building

```lua
-- In Building production calculation:
local workerEfficiency = 1.0
if station.worker then
    local worker = getCharacterById(station.worker)
    workerEfficiency = worker.productivityMultiplier
end
efficiency = workerEfficiency * resourceEfficiency
```

**Decision:** Keep town-wide for now (simpler, already working). Per-worker is a future enhancement.

#### Potential Fix F2: Dynamic Resource Recalculation (if needed)

Current: `resourceEfficiency` calculated once at placement
Alternative: Recalculate periodically (for depleting resources)

**Decision:** Not needed for fertility (doesn't deplete). May need for mining operations later.

---

## Part 4: Proportionality Rationale

### Why These Multiplier Ranges?

#### Satisfaction → Productivity (0.1 to 1.0)

- **Floor of 0.1:** Even extremely unhappy workers produce something (prevents total shutdown)
- **Threshold at 50:** Reasonable satisfaction means no penalty (not punishing "okay" happiness)
- **Linear below 50:** Proportionate degradation (25 satisfaction = 50% output)
- **No bonus above 50:** Avoiding runaway positive feedback loops

#### Terrain → Efficiency (0.0 to 1.0)

- **Range 0-1:** Simple multiplicative model
- **Weighted averages:** Different buildings care about different resources (farm cares about fertility, mine cares about ore)
- **No floor:** Building on barren land really should produce almost nothing
- **Encourages strategic placement:** Players must consider terrain when building

### Combined Effect Formula

```
Final Production Rate = Base Rate × Productivity Multiplier × Resource Efficiency

Example:
- Base Rate: 1 wheat per 60 seconds
- Satisfaction: 25% → Productivity: 0.5
- Fertility: 0.74 → Efficiency: 0.74
- Final Rate: 1 wheat per (60 / 0.5 / 0.74) = 162 seconds
  Or equivalently: 0.37 wheat per 60 seconds
```

---

## Part 5: Acceptance Criteria

### F1: Satisfaction → Production

- [ ] Debug panel has satisfaction override control
- [ ] Override correctly affects `world.stats.productivityMultiplier`
- [ ] Production rate changes proportionally when satisfaction changes
- [ ] Test documented with before/after observations

### F2: Terrain → Production

- [ ] Debug panel shows `resourceEfficiency` in building detail
- [ ] Efficiency breakdown shows contributing resources
- [ ] Different terrain locations produce different efficiency values
- [ ] Production rate differs between high/low fertility farm placements
- [ ] Test documented with before/after observations

### General

- [ ] Debug panel readability maintained (no cluttered UI)
- [ ] All findings documented in this file
- [ ] Linear issue updated with results

---

## Appendix: Key File References

| File | Purpose |
|------|---------|
| `code/consumption/CharacterV2.lua` | Satisfaction tracking, productivity calculation |
| `code/consumption/TownConsequences.lua` | Town stats aggregation |
| `code/AlphaWorld.lua` | Production calculation, building placement |
| `code/NaturalResources.lua` | Resource grid, distribution |
| `code/AlphaNaturalResources.lua` | Location efficiency calculation |
| `code/DebugPanel.lua` | Debug visualization (to be enhanced) |
| `code/ResourceOverlay.lua` | Resource visualization overlay |

---

## Change Log

| Date | Change |
|------|--------|
| 2026-01-11 | Initial document created, code analysis complete |
