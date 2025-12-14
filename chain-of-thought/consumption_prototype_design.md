# Consumption Prototype - Implementation Design Document
**CraveTown: Prototype 1 - Character Behavior & Resource Allocation**

Version 2.0 | November 2025

---

## Document Purpose

This document provides the **implementation roadmap** for the consumption prototype. For the complete **system architecture** (mechanics, formulas, data structures), see:

📘 **[consumption_system_architecture_v2.md](./consumption_system_architecture_v2.md)**

---

## Table of Contents

1. [Implementation Overview](#implementation-overview)
2. [Phase Breakdown](#phase-breakdown)
3. [File Structure](#file-structure)
4. [Data File Specifications](#data-file-specifications)
5. [Code Modules](#code-modules)
6. [UI Implementation](#ui-implementation)
7. [Testing Strategy](#testing-strategy)
8. [Performance Targets](#performance-targets)

---

## Implementation Overview

### Architecture Summary

The consumption system uses a **6-layer character state model** with **fine-grained (49D) computation** and **coarse-grained (9D) display**:

**Character State Layers:**
1. **Base Identity** (static): class, traits, age, vocation, gender
2. **Base Cravings** (quasi-static): Decay rates per fine dimension, modified by enablement
3. **Current Cravings** (dynamic): Accumulation tracker, resets on satisfaction
4. **Satisfaction State** (dynamic): Lifetime happiness tracker (-100 to 300)
5. **Commodity Multipliers** (dynamic): Fatigue/boredom per commodity (0.0 to 1.0)
6. **Consumption History** (analytics): Last 20 decisions for UI display

**Key Mechanics:**
- **Allocation**: Priority-based with configurable fairness
- **Substitution**: Distance-based boost system
- **Fatigue**: Personalized commodity decay (trait + commodity dependent)
- **Enablement**: External triggers unlock/amplify new cravings
- **Consequences**: Productivity → Protest → Riot (with damage)
- **Emigration**: Triggered by external opportunities

### Implementation Timeline

**Target: 4 days of focused development**

- **Day 1**: Data files + Character system refactor
- **Day 2**: Allocation engine + Cache system
- **Day 3**: Consequences + Core UI
- **Day 4**: Advanced UI + Testing + Balancing

---

## Phase Breakdown

### Phase 1: Core Data Structures (Day 1 Morning)

**Duration:** 3-4 hours

**Objectives:**
- Create all JSON data files with fine-grained (49D) structure
- Update existing files to support new architecture
- Validate data integrity and dimension mappings

**Tasks:**

1. **Create `dimension_definitions.json`** ✓ (Already exists)
   - Maps 49 fine dimensions to 9 coarse dimensions
   - Defines display names, icons, descriptions

2. **Update `character_traits.json`** ✓ (Already has 49D structure)
   - Verify all traits have `cravingMultipliers.fine` arrays (49 elements)
   - Add any missing traits

3. **Update `fulfillment_vectors.json`** ✓ (Already has fine structure)
   - Verify all commodities have `fulfillmentVector.fine` arrays (49 elements)
   - Add any missing commodities

4. **Create `enablement_vectors.json`** (NEW)
   ```json
   {
     "enablements": [
       {
         "id": "has_house",
         "name": "Has House",
         "description": "Character owns or has access to housing",
         "unlocks": {
           "touch_furniture_basic": 2.5,
           "touch_furniture_premium": 0.8,
           "social_status_household_display": 1.5
         },
         "amplifies": {
           "safety_shelter_premium": 1.5
         }
       },
       {
         "id": "has_family",
         "name": "Has Family",
         "unlocks": {
           "social_connection_family": 3.0
         },
         "amplifies": {
           "safety_shelter_basic": 1.3,
           "biological_nutrition_protein": 1.2
         }
       }
     ]
   }
   ```

5. **Create `commodity_fatigue_rates.json`** (NEW)
   ```json
   {
     "commodities": {
       "bread": {
         "baseFatigueRate": 0.15,
         "fatigueModifiers": {
           "frugal": 0.8,
           "hedonist": 1.5,
           "glutton": 1.3
         }
       },
       "wine": {
         "baseFatigueRate": 0.10,
         "fatigueModifiers": {
           "ascetic": 1.8,
           "hedonist": 0.7,
           "addict": 0.5
         }
       }
     }
   }
   ```

6. **Update `substitution_rules.json`** (Add distance values)
   ```json
   {
     "cake": {
       "close_substitutes": [
         {"commodity": "pie", "distance": 0.1},
         {"commodity": "pastry", "distance": 0.15}
       ],
       "distant_substitutes": [
         {"commodity": "cookies", "distance": 0.3},
         {"commodity": "bread", "distance": 0.5}
       ]
     }
   }
   ```

**Success Criteria:**
- All JSON files load without errors
- Dimension mappings verified (49 fine → 9 coarse)
- All commodities have complete fulfillment vectors

---

### Phase 2: Character System Refactor (Day 1 Afternoon)

**Duration:** 4-5 hours

**Objectives:**
- Refactor `Character.lua` to support all 6 state layers
- Implement accumulation logic for current cravings
- Implement satisfaction tracking with bounds
- Implement personalized commodity fatigue

**Files to Modify:**
- `/code/consumption/Character.lua`

**New Functions:**

```lua
-- Layer 2: Base Cravings (with enablement)
function Character:ApplyEnablement(enablementType)
function Character:RecalculateBaseCravings()

-- Layer 3: Current Cravings (accumulation)
function Character:UpdateCurrentCravings(deltaTime)
function Character:GetHighestCurrentCraving()

-- Layer 4: Satisfaction State
function Character:UpdateSatisfaction(deltaTime)
function Character:ApplySatisfactionGain(commodity, quantity)
function Character:RecalculateSatisfactionCoarse()

-- Layer 5: Commodity Multipliers
function Character:CalculateCommodityMultiplier(commodity)
function Character:UpdateCommodityHistory(commodity, cycle)
function Character:BoostSubstitutes(commodity)

-- Layer 6: Consumption History
function Character:RecordConsumption(cycle, commodity, gains)
function Character:GetConsumptionHistory(count)
```

**Key Implementation Details:**

1. **Current Cravings Accumulation**
   ```lua
   function Character:UpdateCurrentCravings(deltaTime)
       for craving, baseDecay in pairs(self.baseCravings) do
           if baseDecay > 0 then  -- Only if enabled
               local accumulation = baseDecay * (deltaTime / 60.0)
               self.currentCravings[craving] = self.currentCravings[craving] + accumulation
           end
       end
   end
   ```

2. **Satisfaction Update with Bounds**
   ```lua
   function Character:UpdateSatisfaction(deltaTime)
       -- Slow natural decay
       for dim, value in pairs(self.satisfaction) do
           self.satisfaction[dim] = math.max(-100, value - 0.5 * (deltaTime / 60.0))
       end

       -- Penalty for high unmet cravings
       for craving, currentNeed in pairs(self.currentCravings) do
           if currentNeed > 40 then
               local penalty = (currentNeed - 40) * 0.2 * (deltaTime / 60.0)
               self.satisfaction[craving] = math.max(-100, self.satisfaction[craving] - penalty)
           end
       end
   end
   ```

3. **Personalized Fatigue**
   ```lua
   function Character:CalculateCommodityMultiplier(commodity)
       local history = self.commodityHistory[commodity]
       if not history then return 1.0 end

       -- Get personalized fatigue rate
       local fatigueData = CommodityFatigueRates.commodities[commodity]
       local baseFatigueRate = fatigueData.baseFatigueRate

       local traitMultiplier = 1.0
       for _, trait in ipairs(self.traits) do
           if fatigueData.fatigueModifiers[trait] then
               traitMultiplier = traitMultiplier * fatigueData.fatigueModifiers[trait]
           end
       end

       local effectiveFatigueRate = baseFatigueRate * traitMultiplier

       -- Exponential decay
       local fatigue = math.exp(-history.consecutiveConsumptions * effectiveFatigueRate)

       -- Recovery
       local cyclesSince = currentCycle - history.lastConsumed
       local recovery = math.min(1.0, cyclesSince * 0.1)

       return math.max(0.0, fatigue * recovery)
   end
   ```

**Success Criteria:**
- All 6 layers properly separated
- Current cravings accumulate correctly
- Satisfaction tracks lifetime happiness
- Commodity multipliers decay with consumption
- Enablement unlocks new cravings

---

### Phase 3: Allocation Engine Refactor (Day 2 Morning)

**Duration:** 3-4 hours

**Objectives:**
- Update allocation to work with fine-grained (49D) computation
- Implement commodity scoring with multipliers
- Add substitution boost mechanics
- Support configurable allocation policies

**Files to Modify:**
- `/code/consumption/AllocationEngine.lua`

**New Functions:**

```lua
function AllocationEngine:ScoreCommodity(character, commodity, targetCraving)
function AllocationEngine:AllocateCommodity(character, commodity, quantity, inventory)
function AllocationEngine:ApplySubstitutionBoost(character, commodity)
```

**Key Changes:**

1. **Commodity Scoring with Multipliers**
   ```lua
   function AllocationEngine:ScoreCommodity(character, commodity, targetCraving)
       local fulfillmentVector = FulfillmentVectors.commodities[commodity].fulfillmentVector.fine
       local commodityMultiplier = character:CalculateCommodityMultiplier(commodity)

       -- Base satisfaction for target craving
       local baseScore = fulfillmentVector[targetCraving] or 0

       -- Apply fatigue multiplier
       local score = baseScore * commodityMultiplier

       -- Bonus for multi-dimensional satisfaction
       for craving, points in pairs(fulfillmentVector) do
           if craving ~= targetCraving and character.currentCravings[craving] > 20 then
               score = score + points * 0.5 * commodityMultiplier
           end
       end

       return score
   end
   ```

2. **Priority with Fairness**
   ```lua
   function Character:CalculatePriority(currentCycle, policy)
       local priority = 0

       -- Desperation from current cravings
       local desperationScore = 0
       for craving, currentNeed in pairs(self.currentCravings) do
           if currentNeed > 40 then
               desperationScore = desperationScore + math.exp((currentNeed - 40) / 20)
           end
       end
       priority = priority + desperationScore * 100

       -- Class weight
       priority = priority + policy.classWeights[self.class] * 10

       -- Fairness penalty
       if policy.fairnessMode == "balanced" then
           local recentAllocations = self:CountRecentAllocations(5)
           priority = priority * (1.0 / (1.0 + recentAllocations * policy.allocationHistoryWeight))
       end

       -- Critical override
       if self:GetAverageSatisfactionCoarse() < policy.criticalThreshold then
           priority = priority * 2.0
       end

       return priority
   end
   ```

**Success Criteria:**
- Allocation works with 49D fine cravings
- Commodity multipliers affect scoring
- Substitution boost increases related commodity attractiveness
- Priority respects allocation policy settings

---

### Phase 4: Cache System (Day 2 Afternoon)

**Duration:** 3-4 hours

**Objectives:**
- Create hierarchical commodity cache
- Implement smart invalidation
- Optimize allocation performance

**Files to Create:**
- `/code/consumption/CommodityCache.lua`

**Cache Structure:**

```lua
CommodityCache = {
    -- Level 1: By coarse dimension
    byCoarseDimension = {},

    -- Level 2: By fine dimension
    byFineDimension = {},

    -- Level 3: Substitution groups
    substitutionGroups = {}
}

function CommodityCache:Initialize(commodities, inventory)
function CommodityCache:Invalidate(commodity)
function CommodityCache:Rebuild()
function CommodityCache:GetCommoditiesForCraving(fineCraving)
```

**Success Criteria:**
- Cache rebuilds only when dirty
- Invalidation targets specific dimensions
- Allocation cycle < 5ms for 100 characters

---

### Phase 5: Consequences System (Day 3 Morning)

**Duration:** 3-4 hours

**Objectives:**
- Implement productivity degradation
- Add protest/riot mechanics
- Create emigration opportunity system

**Files to Modify:**
- `/code/consumption/Character.lua` (add CheckConsequences)
- `/code/ConsumptionPrototype.lua` (add town-level consequences)

**New Functions:**

```lua
-- Character level
function Character:UpdateProductivity()
function Character:CheckProtest(currentCycle)
function Character:CheckEmigration(currentCycle, opportunities)

-- Town level
function ConsumptionPrototype:CheckCollectiveConsequences()
function ConsumptionPrototype:TriggerRiot()
function ConsumptionPrototype:GenerateEmigrationOpportunity()
```

**Success Criteria:**
- Productivity scales with satisfaction
- Riots damage inventory and buildings
- Emigration requires external opportunity + low satisfaction

---

### Phase 6: Core UI Implementation (Day 3 Afternoon)

**Duration:** 4-5 hours

**Objectives:**
- Update character detail modal with all 6 sections
- Add coarse dimension display with expand/collapse
- Show commodity fatigue
- Display consumption history

**Files to Modify:**
- `/code/ConsumptionPrototype.lua`

**UI Sections:**

1. **Character Header** (identity + enablements)
2. **Satisfaction Coarse** (9 bars with expand buttons)
3. **Current Cravings** (top 10 most urgent)
4. **Commodity Fatigue** (top 10 most consumed)
5. **Consumption History** (last 10 cycles)
6. **Status** (priority, productivity, risks)

**Success Criteria:**
- All sections render correctly
- Expand/collapse works for fine dimensions
- Performance: 60 FPS with 50 characters displayed

---

### Phase 7: Advanced UI (Day 4 Morning)

**Duration:** 3-4 hours

**Objectives:**
- Add fine dimension heatmap (top 10 + bottom 10)
- Create allocation policy panel
- Add visual indicators (warnings, icons)

**New Components:**

1. **Fine Dimension Heatmap**
   - Top 10 highest satisfaction dimensions
   - Bottom 10 lowest satisfaction dimensions
   - Color-coded bars (green=high, yellow=medium, red=low)

2. **Allocation Policy Panel**
   - Sliders for class weights
   - Radio buttons for fairness mode
   - Slider for history penalty weight
   - Input for critical threshold

**Success Criteria:**
- Heatmap shows fine dimensions correctly
- Policy changes affect allocation behavior immediately
- UI remains responsive with all panels open

---

### Phase 8: Testing & Balancing (Day 4 Afternoon)

**Duration:** 3-4 hours

**Objectives:**
- Test edge cases and stress scenarios
- Balance decay rates and satisfaction gains
- Performance profiling
- Bug fixes

**Test Scenarios:**

1. **Starvation Test**: 10 characters, 0 inventory → all should protest/emigrate
2. **Abundance Test**: 10 characters, 1000 of each commodity → all should reach 300 satisfaction
3. **Fatigue Test**: 1 character, only bread → should get tired and crave substitutes
4. **Riot Test**: 100 characters, low satisfaction → should trigger riot
5. **Performance Test**: 100 characters, 50 commodities → allocation < 5ms

**Balancing Targets:**

- Average character satisfaction: 50-70 in balanced scenario
- Fatigue kicks in after 3-5 consecutive consumptions
- Substitution boost recovers ~50% of multiplier
- Riot requires 40%+ dissatisfied population
- Emigration occurs for <10% of critically dissatisfied

**Success Criteria:**
- All test scenarios pass
- Performance targets met
- No critical bugs
- Gameplay feels balanced

---

## File Structure

```
/data/base/
├── consumption_mechanics.json           (✓ Exists)
├── craving_system/
│   ├── dimension_definitions.json       (✓ Exists)
│   ├── fulfillment_vectors.json         (✓ Exists)
│   ├── character_traits.json            (✓ Exists)
│   ├── enablement_vectors.json          (NEW)
│   └── commodity_fatigue_rates.json     (NEW)
└── substitution_rules.json              (✓ Exists - needs distance values)

/code/consumption/
├── Character.lua                        (REFACTOR)
├── AllocationEngine.lua                 (REFACTOR)
└── CommodityCache.lua                   (NEW)

/code/
└── ConsumptionPrototype.lua             (REFACTOR - UI updates)
```

---

## Data File Specifications

### enablement_vectors.json

```json
{
  "version": "1.0.0",
  "enablements": [
    {
      "id": "has_house",
      "name": "Has House",
      "description": "Character owns or has access to housing",
      "unlocks": {
        "touch_furniture_basic": 2.5,
        "touch_furniture_premium": 0.8,
        "social_status_household_display": 1.5
      },
      "amplifies": {
        "safety_shelter_premium": 1.5
      }
    },
    {
      "id": "has_family",
      "name": "Has Family",
      "description": "Character has dependents or family members",
      "unlocks": {
        "social_connection_family": 3.0
      },
      "amplifies": {
        "safety_shelter_basic": 1.3,
        "biological_nutrition_protein": 1.2
      }
    },
    {
      "id": "has_education",
      "name": "Has Education",
      "description": "Character has received formal education",
      "unlocks": {
        "psychological_education": 2.0
      },
      "amplifies": {
        "psychological_achievement": 1.4,
        "social_status_prestige": 1.2
      }
    }
  ]
}
```

### commodity_fatigue_rates.json

```json
{
  "version": "1.0.0",
  "commodities": {
    "bread": {
      "baseFatigueRate": 0.15,
      "fatigueModifiers": {
        "frugal": 0.8,
        "hedonist": 1.5,
        "glutton": 1.3
      }
    },
    "meat": {
      "baseFatigueRate": 0.12,
      "fatigueModifiers": {
        "frugal": 1.0,
        "hedonist": 1.2,
        "glutton": 1.5
      }
    },
    "wine": {
      "baseFatigueRate": 0.10,
      "fatigueModifiers": {
        "ascetic": 1.8,
        "hedonist": 0.7,
        "addict": 0.5
      }
    },
    "cake": {
      "baseFatigueRate": 0.20,
      "fatigueModifiers": {
        "frugal": 1.3,
        "hedonist": 0.8,
        "glutton": 0.6
      }
    }
  }
}
```

---

## Code Modules

### Character.lua Structure

```lua
-- DATA
local ConsumptionMechanics = nil
local FulfillmentVectors = nil
local CharacterTraits = nil
local EnablementVectors = nil
local CommodityFatigueRates = nil

-- INITIALIZATION
function Character.Init(...)

-- LAYER 1: Base Identity
function Character:New(class, id)
function Character.GenerateRandomName()

-- LAYER 2: Base Cravings
function Character:RecalculateBaseCravings()
function Character:ApplyEnablement(enablementType)

-- LAYER 3: Current Cravings
function Character:UpdateCurrentCravings(deltaTime)
function Character:GetHighestCurrentCraving()

-- LAYER 4: Satisfaction State
function Character:UpdateSatisfaction(deltaTime)
function Character:ApplySatisfactionGain(commodity, quantity)
function Character:RecalculateSatisfactionCoarse()
function Character:GetAverageSatisfactionCoarse()

-- LAYER 5: Commodity Multipliers
function Character:CalculateCommodityMultiplier(commodity)
function Character:UpdateCommodityHistory(commodity, cycle)
function Character:BoostSubstitutes(commodity)

-- LAYER 6: Consumption History
function Character:RecordConsumption(cycle, commodity, gains)
function Character:GetConsumptionHistory(count)

-- PRIORITY & CONSEQUENCES
function Character:CalculatePriority(currentCycle, policy)
function Character:CheckConsequences(currentCycle)
function Character:UpdateProductivity()
```

---

## UI Implementation

### Character Modal Layout

```lua
function ConsumptionPrototype:RenderCharacterModal(character)
    -- Header: Identity + Enablements
    self:RenderCharacterHeader(character)

    -- Section 1: Satisfaction (Coarse - 9D)
    self:RenderSatisfactionCoarse(character)

    -- Section 2: Current Cravings (Top 10)
    self:RenderCurrentCravings(character)

    -- Section 3: Commodity Fatigue (Top 10)
    self:RenderCommodityFatigue(character)

    -- Section 4: Consumption History (Last 10)
    self:RenderConsumptionHistory(character)

    -- Section 5: Status & Risks
    self:RenderCharacterStatus(character)

    -- Optional: Fine Dimension Heatmap (if expanded)
    if character.showFineHeatmap then
        self:RenderFineHeatmap(character, character.expandedDimension)
    end
end
```

---

## Testing Strategy

### Unit Tests (Lua)

1. **Character State Tests**
   - Test current cravings accumulation
   - Test satisfaction bounds (-100 to 300)
   - Test commodity multiplier calculation
   - Test enablement unlocking

2. **Allocation Tests**
   - Test priority calculation
   - Test commodity scoring
   - Test substitution boost

3. **Cache Tests**
   - Test invalidation logic
   - Test rebuild performance
   - Test dimension mapping

### Integration Tests

1. **Full Cycle Test**: 10 characters, 10 cycles, verify all state updates
2. **Starvation Test**: 0 inventory, verify consequences trigger
3. **Riot Test**: Mass dissatisfaction, verify riot mechanics
4. **Performance Test**: 100 characters, 1000 cycles, measure timing

---

## Performance Targets

### Allocation Cycle
- **Target**: < 5ms for 100 characters with 50 commodities
- **Breakdown**:
  - Priority calculation: < 1ms
  - Commodity scoring: < 2ms
  - Allocation execution: < 2ms

### Cache Operations
- **Rebuild**: < 2ms for full cache
- **Invalidation**: < 0.1ms per commodity
- **Lookup**: < 0.01ms per query

### UI Rendering
- **Target**: 60 FPS (16.67ms per frame)
- **Character modal**: < 5ms to render
- **Grid view**: < 8ms for 50 characters

---

## Implementation Checklist

### Day 1: Data + Character System
- [ ] Create enablement_vectors.json
- [ ] Create commodity_fatigue_rates.json
- [ ] Update substitution_rules.json with distances
- [ ] Refactor Character.lua (all 6 layers)
- [ ] Test character state updates

### Day 2: Allocation + Cache
- [ ] Refactor AllocationEngine.lua
- [ ] Create CommodityCache.lua
- [ ] Implement smart invalidation
- [ ] Test allocation with cache
- [ ] Performance profiling

### Day 3: Consequences + Core UI
- [ ] Implement consequence system
- [ ] Update character modal (6 sections)
- [ ] Add expand/collapse for dimensions
- [ ] Test UI performance

### Day 4: Advanced UI + Testing
- [ ] Add fine dimension heatmap
- [ ] Create allocation policy panel
- [ ] Run all test scenarios
- [ ] Balance parameters
- [ ] Fix bugs

---

## Next Steps

1. **Review this implementation plan** with the team
2. **Start Phase 1** (Day 1 Morning): Create data files
3. **Daily standups** to track progress and blockers
4. **Continuous testing** as each phase completes

---

**Document Status:** Implementation Ready
**Last Updated:** 2025-11-27
**See Also:** [consumption_system_architecture_v2.md](./consumption_system_architecture_v2.md)
