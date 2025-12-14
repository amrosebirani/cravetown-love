# Consumption & Production System - Computation Reference

**Version:** 1.0
**Last Updated:** 2025-12-02
**Purpose:** Single source of truth for all calculations, formulas, and algorithms in the consumption and production systems.

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Craving System](#2-craving-system)
3. [Satisfaction System](#3-satisfaction-system)
4. [Commodity Fatigue & Diminishing Returns](#4-commodity-fatigue--diminishing-returns)
5. [Allocation System](#5-allocation-system)
6. [Substitution System](#6-substitution-system)
7. [Durable Goods System](#7-durable-goods-system)
8. [Consequences System](#8-consequences-system)
9. [System Interactions](#9-system-interactions)
10. [Configuration Reference](#10-configuration-reference)
11. [Example Calculations](#11-example-calculations)
12. [Tuning Guide](#12-tuning-guide)
13. [Debugging Guide](#13-debugging-guide)
14. [Design Rationale](#14-design-rationale)
15. [Quick Reference](#15-quick-reference)

---

## 1. System Overview

### 1.1 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CONSUMPTION PROTOTYPE                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐               │
│  │   CHARACTER  │    │  ALLOCATION  │    │    TOWN      │               │
│  │   SYSTEM     │◄──►│   ENGINE     │◄──►│  INVENTORY   │               │
│  └──────┬───────┘    └──────┬───────┘    └──────────────┘               │
│         │                   │                                            │
│         ▼                   ▼                                            │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐               │
│  │  CRAVING     │    │ SUBSTITUTION │    │  COMMODITY   │               │
│  │  FULFILLMENT │◄──►│    RULES     │◄──►│   CACHE      │               │
│  └──────┬───────┘    └──────────────┘    └──────────────┘               │
│         │                                                                │
│         ▼                                                                │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐               │
│  │ SATISFACTION │───►│ CONSEQUENCES │───►│  EMIGRATION  │               │
│  │    DECAY     │    │   (RIOTS)    │    │  & PROTEST   │               │
│  └──────────────┘    └──────────────┘    └──────────────┘               │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Per-Cycle Processing Order

```
Each 60-second cycle:
┌─────────────────────────────────────────────────────────────────┐
│ 1. UPDATE CRAVINGS (continuous within cycle)                    │
│    └─► currentCravings += baseCravings * (dt / 60)              │
├─────────────────────────────────────────────────────────────────┤
│ 2. UPDATE ACTIVE EFFECTS (once per cycle)                       │
│    ├─► Decay effectiveness of durables                          │
│    ├─► Decrement remaining cycles                               │
│    └─► Remove expired durables                                  │
├─────────────────────────────────────────────────────────────────┤
│ 3. APPLY PASSIVE SATISFACTION (once per cycle)                  │
│    └─► Durables reduce cravings at 30% strength                 │
├─────────────────────────────────────────────────────────────────┤
│ 4. RUN ALLOCATION CYCLE                                         │
│    ├─► Calculate priorities for all characters                  │
│    ├─► Sort by priority (highest first)                         │
│    └─► Allocate budget items per character                      │
├─────────────────────────────────────────────────────────────────┤
│ 5. UPDATE SATISFACTION (once per cycle)                         │
│    └─► Decay based on remaining unfulfilled cravings            │
├─────────────────────────────────────────────────────────────────┤
│ 6. UPDATE PRODUCTIVITY (continuous)                             │
│    └─► productivityMultiplier = satisfaction / 50               │
├─────────────────────────────────────────────────────────────────┤
│ 7. CHECK CONSEQUENCES                                           │
│    ├─► Check protests                                           │
│    ├─► Check emigration                                         │
│    ├─► Check civil unrest                                       │
│    ├─► Check riots                                              │
│    └─► Check mass emigration                                    │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 Dimension System

The system uses a **hierarchical 49-dimension model**:

```
COARSE (9 dimensions)          FINE (49 dimensions)
─────────────────────          ────────────────────
0: biological          ──────► 0-6:   nutrition_grain, nutrition_meat, hydration, etc.
1: safety              ──────► 7-11:  shelter, protection, health, etc.
2: touch               ──────► 12-17: comfort, intimacy, warmth, etc.
3: psychological       ──────► 18-24: peace, stimulation, beauty, etc.
4: social_status       ──────► 25-30: recognition, achievement, luxury, etc.
5: social_connection   ──────► 31-36: belonging, friendship, family, etc.
6: exotic_goods        ──────► 37-41: novelty, rarity, foreign, etc.
7: shiny_objects       ──────► 42-45: gold, gems, precious, etc.
8: vice                ──────► 46-48: alcohol, gambling, indulgence, etc.
```

---

## 2. Craving System

### 2.1 Base Craving Generation

**Purpose:** Generate per-cycle craving accumulation rates based on class and traits.

**File:** `code/consumption/CharacterV2.lua`
**Function:** `Character.GenerateBaseCravings(class, traits)` (Lines 210-295)

**Algorithm:**
```lua
-- Step 1: Load class base cravings (49 values)
baseCravings = CharacterClasses[class].baseCravings.fine

-- Step 2: Apply trait modifiers (multiplicative)
for each trait in traits:
    traitData = CharacterTraits[trait]
    for i = 0 to 48:
        baseCravings[i] = baseCravings[i] * traitData.cravingMultipliers.fine[i]

return baseCravings
```

**Example Values (Elite class):**
| Fine Dimension | Base Value | After "Ambitious" Trait |
|----------------|------------|------------------------|
| biological_nutrition_grain | 4.9 | 4.9 (1.0x) |
| social_status_recognition | 5.0 | 7.5 (1.5x) |
| social_status_achievement | 5.7 | 9.1 (1.6x) |

**Configuration Files:**
- Class bases: `data/base/craving_system/character_classes.json`
- Trait modifiers: `data/base/craving_system/character_traits.json`

---

### 2.2 Current Craving Accumulation

**Purpose:** Accumulate unfulfilled cravings over time.

**File:** `code/consumption/CharacterV2.lua`
**Function:** `Character:UpdateCurrentCravings(deltaTime)` (Lines 334-355)

**Formula:**
```
ratio = deltaTime / cycleTime
currentCravings[i] = currentCravings[i] + (baseCravings[i] * ratio)
currentCravings[i] = min(currentCravings[i], max(baseCravings[i] * 50, 50))
```

**Parameters:**
| Parameter | Value | Source |
|-----------|-------|--------|
| cycleTime | 60 seconds | Hardcoded |
| maxCravingMultiplier | 50x base | Hardcoded |
| startingCravings | 10x base | Initialization |

**Behavior:**
- Cravings grow linearly within each cycle
- Cap prevents unbounded growth during extended periods without allocation
- Characters start with 10 cycles worth of pre-accumulated cravings

---

### 2.3 Craving Fulfillment

**Purpose:** Reduce cravings when commodity consumed.

**File:** `code/consumption/CharacterV2.lua`
**Function:** `Character:FulfillCraving(commodity, quantity, currentCycle, allocationType)` (Lines 514-610)

**Formula:**
```
fatigueMultiplier = CalculateCommodityMultiplier(commodity, currentCycle)
qualityMultiplier = commodityData.qualityMultipliers[quality] or 1.0

For each fine dimension in commodity.fulfillmentVector.fine:
    gain = points * qualityMultiplier * fatigueMultiplier * quantity
    currentCravings[fineIdx] = max(0, currentCravings[fineIdx] - gain)
```

**Example:**
```
Wheat consumption:
- fulfillmentVector.fine.biological_nutrition_grain = 30
- qualityMultiplier (basic) = 1.0
- fatigueMultiplier = 0.8 (consumed 3 times recently)
- quantity = 1

Craving reduction = 30 * 1.0 * 0.8 * 1 = 24 points
```

---

### 2.4 Coarse Craving Aggregation

**Purpose:** Sum fine cravings into coarse dimensions for UI and priority calculation.

**File:** `code/consumption/CharacterV2.lua`
**Function:** `Character:AggregateCurrentCravingsToCoarse()` (Lines 748-768)

**Formula:**
```
For each coarse dimension (0-8):
    fineIndices = coarseToFineMap[coarseIdx]  -- e.g., {0, 1, 5, 12} (array of indices)
    coarseCraving = sum(currentCravings[i] for i in fineIndices)

Note: coarseToFineMap stores an array of fine dimension indices (not a contiguous range)
to correctly handle non-contiguous fine dimension assignments.
```

---

## 3. Satisfaction System

### 3.1 Starting Satisfaction

**Purpose:** Initialize satisfaction values by class.

**File:** `code/consumption/CharacterV2.lua`
**Function:** `Character.GenerateStartingSatisfaction(class)` (Lines 301-328)

**Formula:**
```
For each coarse dimension:
    range = startingSatisfactionRanges[class][dimension]
    satisfaction[dimension] = random(range[1], range[2])
```

**Configuration (consumption_mechanics.json):**
| Class | Biological | Safety | Social Status |
|-------|------------|--------|---------------|
| Elite | 60-80 | 70-90 | 50-70 |
| Upper | 50-70 | 60-80 | 40-60 |
| Middle | 30-50 | 40-60 | 30-50 |
| Lower | 20-40 | 30-50 | 20-40 |

---

### 3.2 Satisfaction Decay

**Purpose:** Natural satisfaction loss based on unfulfilled cravings.

**File:** `code/consumption/CharacterV2.lua`
**Function:** `Character:UpdateSatisfaction(currentCycle)` (Lines 361-399)

**Formula:**
```
For each coarse dimension:
    avgCraving = sum(currentCravings in this coarse) / count
    baseDecay = cravingDecayRates[dimension][class]
    cravingMultiplier = 1.0 + (avgCraving / 50.0)
    actualDecay = baseDecay * cravingMultiplier

    satisfaction[dimension] -= actualDecay
    satisfaction[dimension] = clamp(-100, 300)
```

**Configuration (consumption_mechanics.json):**
| Dimension | Elite | Upper | Middle | Lower |
|-----------|-------|-------|--------|-------|
| biological | 2.0 | 2.5 | 3.0 | 3.5 |
| safety | 1.5 | 2.0 | 2.5 | 3.0 |
| social_status | 5.0 | 4.0 | 3.0 | 2.0 |
| vice | 2.5 | 2.0 | 1.5 | 1.0 |

**Design Note:** Elite decay faster on status (they care more), slower on biological (better baseline).

---

### 3.3 Satisfaction Boost from Consumption

**Purpose:** Increase satisfaction when cravings fulfilled.

**File:** `code/consumption/CharacterV2.lua`
**Function:** Part of `FulfillCraving()` (Lines 562-574)

**Formula:**
```
For each fine dimension satisfied:
    coarseName = fineToCoarseMap[fineIdx]
    boost = fineVector[fineName] * qualityMultiplier * fatigueMultiplier * quantity * 0.5
    satisfaction[coarseName] = min(300, satisfaction[coarseName] + boost)
```

**Note:** Boost factor is 0.5x the craving reduction (softer effect on satisfaction).

---

### 3.4 Average Satisfaction

**Purpose:** Single metric for character wellbeing.

**File:** `code/consumption/CharacterV2.lua`
**Function:** `Character:GetAverageSatisfaction()` (Lines 770-787)

**Formula:**
```
coarseKeys = {"biological", "safety", "touch", "psychological",
              "social_status", "social_connection", "exotic_goods",
              "shiny_objects", "vice"}

total = sum(satisfaction[key] for key in coarseKeys)
average = total / 9
```

**Range:** -100 to 300 (clamped per dimension)

---

## 4. Commodity Fatigue & Diminishing Returns

### 4.1 Commodity Multiplier Calculation

**Purpose:** Reduce effectiveness of repeated consumption (variety-seeking mechanic).

**File:** `code/consumption/CharacterV2.lua`
**Function:** `Character:CalculateCommodityMultiplier(commodity, currentCycle)` (Lines 405-459)

**Formula:**
```
cyclesSinceLast = currentCycle - lastConsumed

if cyclesSinceLast > cooldownCycles (10):
    return 1.0  -- Fully recovered

baseFatigueRate = commodityFatigueRates[commodity] or 0.12
traitModifier = product(fatigueModifiers[trait] for trait in character.traits)
effectiveFatigueRate = baseFatigueRate * traitModifier

multiplier = exp(-consecutiveCount * effectiveFatigueRate)
multiplier = max(minMultiplier, multiplier)  -- Floor at 0.25

return multiplier
```

**Exponential Decay Curve:**
```
Consecutive Count | Multiplier (rate=0.12) | Multiplier (rate=0.15)
------------------|------------------------|------------------------
0                 | 1.00                   | 1.00
1                 | 0.89                   | 0.86
2                 | 0.79                   | 0.74
3                 | 0.70                   | 0.64
5                 | 0.55                   | 0.47
10                | 0.30                   | 0.25 (floor)
```

**Configuration (commodity_fatigue_rates.json):**
| Commodity | Base Rate | Notes |
|-----------|-----------|-------|
| wheat | 0.15 | Staple, fatigues faster |
| apple | 0.10 | Variety fruit |
| wine | 0.08 | Luxury, slower fatigue |
| bed | 0.03 | Durable, very slow |
| gold | 0.02 | Precious, minimal fatigue |

**Trait Modifiers:**
| Trait | Modifier | Effect |
|-------|----------|--------|
| hedonist | 1.5x | Bores easily |
| frugal | 0.8x | Appreciates consistency |
| glutton | 1.3x | Needs variety in food |

---

### 4.2 Commodity History Tracking

**Purpose:** Track consumption patterns for fatigue calculation.

**File:** `code/consumption/CharacterV2.lua`
**Function:** `Character:UpdateCommodityHistory(commodity, currentCycle)` (Lines 465-508)

**Algorithm:**
```lua
if cyclesSinceLast <= cooldownCycles:
    consecutiveCount += 1
else:
    consecutiveCount = 1  -- Reset after cooldown

lastConsumed = currentCycle

-- Decay other commodities' consecutive counts
for otherCommodity in allTracked:
    if currentCycle - other.lastConsumed >= 3:
        other.consecutiveCount = max(0, other.consecutiveCount - 1)
```

---

## 5. Allocation System

### 5.1 Priority Calculation

**Purpose:** Determine allocation order (higher = served first).

**File:** `code/consumption/CharacterV2.lua`
**Function:** `Character:CalculatePriority(currentCycle, mode)` (Lines 694-740)

**Formula:**
```
classWeight = classWeights[class]  -- Elite:10, Upper:7, Middle:4, Lower:1

desperationScore = 0
for each coarse dimension:
    cravingValue = aggregatedCravings[dimension]
    dimensionWeight = cravingPriorityWeights[dimension]

    if cravingValue > 100: desperationMultiplier = 10.0  -- Critical
    elif cravingValue > 60: desperationMultiplier = 5.0  -- High
    elif cravingValue > 30: desperationMultiplier = 2.0  -- Medium
    elif cravingValue > 10: desperationMultiplier = 1.0  -- Low
    else: desperationMultiplier = 0.1  -- Satisfied

    desperationScore += desperationMultiplier * dimensionWeight

basePriority = classWeight * 100 + desperationScore

if mode == "fairness":
    finalPriority = basePriority - fairnessPenalty
else:
    finalPriority = basePriority
```

**Configuration:**
| Class | Weight | Base Priority |
|-------|--------|---------------|
| Elite | 10 | 1000 |
| Upper | 7 | 700 |
| Middle | 4 | 400 |
| Lower | 1 | 100 |

| Dimension | Weight | Rationale |
|-----------|--------|-----------|
| biological | 1.0 | Survival needs |
| safety | 0.9 | Security needs |
| touch | 0.7 | Comfort needs |
| social_connection | 0.6 | Belonging |
| psychological | 0.5 | Mental wellbeing |
| social_status | 0.3 | Status symbols |
| exotic_goods | 0.2 | Luxury |
| shiny_objects | 0.2 | Wealth display |
| vice | 0.1 | Indulgences |

---

### 5.2 Allocation Budget by Class

**Purpose:** Limit consumption per cycle by class.

**File:** `code/consumption/AllocationEngineV2.lua`
**Constant:** `AllocationEngineV2.classConsumptionBudget` (Lines 19-26)

| Class | Budget | Rationale |
|-------|--------|-----------|
| Elite | 10 | Wealthy, many needs |
| Upper | 7 | Comfortable |
| Middle | 5 | Moderate |
| Working/Lower | 3 | Limited resources |
| Poor | 2 | Subsistence |

---

### 5.3 Target Craving Selection

**Purpose:** Choose which craving to address (best commodity-craving match).

**File:** `code/consumption/AllocationEngineV2.lua`
**Function:** `AllocationEngineV2.SelectTargetCraving(character, townInventory, currentCycle)` (Lines 330-392)

**Formula:**
```
bestScore = 0
bestCommodity = nil

for fineIdx = 0 to 48:
    if currentCravings[fineIdx] > 0:
        fineName = fineNames[fineIdx]
        coarseWeight = cravingPriorityWeights[coarseName]

        for each commodity in inventory (quantity > 0):
            -- Skip durables already owned at max
            if isDurable(commodity) and not canAcquire(commodity):
                continue

            fulfillmentPoints = commodity.fulfillmentVector.fine[fineName]
            if fulfillmentPoints > 0:
                commodityMultiplier = CalculateCommodityMultiplier(commodity)

                score = fineCraving * coarseWeight * fulfillmentPoints * commodityMultiplier

                if score > bestScore:
                    bestScore = score
                    bestCommodity = commodity

return bestCommodity
```

**Design Note:** Iterates fine dimensions (not coarse) to avoid "medicine dominates biological" problem where high-value items always win.

---

### 5.4 Full Allocation Cycle

**Purpose:** Distribute commodities to all characters.

**File:** `code/consumption/AllocationEngineV2.lua`
**Function:** `AllocationEngineV2.AllocateCycle(...)` (Lines 39-147)

**Algorithm:**
```lua
-- Step 1: Calculate priorities
for each character (not emigrated):
    character.allocationPriority = CalculatePriority(...)

-- Step 2: Sort by priority (descending)
sortedCharacters = sort(characters, priority DESC)

-- Step 3: Sequential allocation (not round-robin)
for rank, character in sortedCharacters:
    budget = classConsumptionBudget[character.class]

    while budget > 0:
        allocation = AllocateForCharacter(character, inventory)

        if allocation.status == "granted" or "substituted":
            budget -= 1
        elif allocation.status == "no_needs":
            break  -- Character satisfied
        else:
            budget -= 1  -- Failed, still counts

return allocationLog
```

**Important:** Sequential allocation ensures high-priority characters get full budget before lower priorities are served.

---

## 6. Substitution System

### 6.1 Substitution Rules Structure

**File:** `data/base/substitution_rules.json`

```json
{
  "substitutionHierarchies": {
    "grains": {
      "wheat": {
        "substitutes": [
          {"commodity": "rice", "efficiency": 0.95, "distance": 0.10},
          {"commodity": "barley", "efficiency": 0.90, "distance": 0.12},
          {"commodity": "bread", "efficiency": 1.10, "distance": 0.20}
        ]
      }
    }
  },
  "desperationRules": {
    "enabled": true,
    "desperationThreshold": 20,
    "desperationSubstitutes": {
      "biological": [
        {"commodity": "scraps", "efficiency": 0.50, "distance": 0.80}
      ]
    }
  }
}
```

**Parameters:**
| Parameter | Range | Meaning |
|-----------|-------|---------|
| efficiency | 0.5-1.2 | How satisfying vs. original (1.0 = equal) |
| distance | 0.0-1.0 | How different (0.0 = identical, 1.0 = completely different) |

---

### 6.2 Distance-Based Boost

**Purpose:** When fatigued on primary, closer substitutes get bonus.

**File:** `code/consumption/AllocationEngineV2.lua`
**Function:** `AllocationEngineV2.FindBestSubstitute(...)` (Lines 479-599)

**Formula:**
```
primaryMultiplier = CalculateCommodityMultiplier(primaryCommodity)

if primaryMultiplier < 1.0:
    boostFactor = 0.5
    distanceBoost = 1.0 + ((1.0 - primaryMultiplier) * (1.0 - distance) * boostFactor)
else:
    distanceBoost = 1.0

score = efficiency * substituteMultiplier * distanceBoost
```

**Example:**
```
Primary: wheat (multiplier = 0.30, very fatigued)
Substitute: rice (efficiency = 0.95, distance = 0.10)

distanceBoost = 1.0 + ((1.0 - 0.30) * (1.0 - 0.10) * 0.5)
             = 1.0 + (0.70 * 0.90 * 0.5)
             = 1.0 + 0.315
             = 1.315

Final score = 0.95 * riceMultiplier * 1.315
```

**Design Rationale:** Close substitutes (low distance) benefit more when you're tired of the original. This encourages natural variety-seeking within categories.

---

## 7. Durable Goods System

### 7.1 Durability Types

| Type | Duration | Decay | Example |
|------|----------|-------|---------|
| consumable | 1 use | N/A | bread, wheat |
| durable | N cycles | Yes | bed (500), clothes (150) |
| permanent | Forever | Optional | house, gold jewelry |

---

### 7.2 Active Effect Structure

**File:** `code/consumption/CharacterV2.lua` (Lines 144-163)

```lua
activeEffect = {
    commodityId = "bed",
    category = "furniture_sleep",
    durability = "durable",
    acquiredCycle = 50,
    durationCycles = 500,
    remainingCycles = 487,
    effectDecayRate = 0.001,
    currentEffectiveness = 0.95,
    fulfillmentVector = {...},
    maxOwned = 1
}
```

---

### 7.3 Effectiveness Decay

**File:** `code/consumption/CharacterV2.lua`
**Function:** `Character:UpdateActiveEffects(currentCycle)` (Lines 1047-1078)

**Formula:**
```
currentEffectiveness = currentEffectiveness * (1 - effectDecayRate)
currentEffectiveness = max(0.1, currentEffectiveness)  -- Floor at 10%

if durability == "durable":
    remainingCycles -= 1
    if remainingCycles <= 0:
        Remove effect (worn out)
```

**Decay Examples:**
| Item | Rate | After 100 cycles | After 500 cycles |
|------|------|------------------|------------------|
| bed | 0.001 | 90.5% | 60.6% |
| clothes | 0.005 | 60.6% | 10% (floor) |
| gold | 0.0001 | 99.0% | 95.1% |

---

### 7.4 Passive Satisfaction

**File:** `code/consumption/CharacterV2.lua`
**Function:** `Character:ApplyActiveEffectsSatisfaction(currentCycle)` (Lines 1080-1143)

**Formula:**
```
passiveMultiplier = 0.3  -- 30% of active consumption strength
satisfactionBoostMultiplier = 0.1  -- 10% satisfaction boost

for each activeEffect:
    effectiveness = effect.currentEffectiveness

    for each fine dimension in fulfillmentVector:
        -- Reduce cravings
        gain = points * effectiveness * passiveMultiplier
        currentCravings[fineIdx] = max(0, currentCravings[fineIdx] - gain)

        -- Boost satisfaction
        boost = points * effectiveness * satisfactionBoostMultiplier
        satisfaction[coarse] = min(300, satisfaction[coarse] + boost)
```

**Example (Bed with 95% effectiveness):**
```
Fulfillment: touch_comfort_rest = 15

Passive craving reduction = 15 * 0.95 * 0.3 = 4.275 points/cycle
Satisfaction boost = 15 * 0.95 * 0.1 = 1.425 points/cycle
```

---

## 8. Consequences System

### 8.1 Productivity Calculation

**File:** `code/consumption/CharacterV2.lua`
**Function:** `Character:UpdateProductivity()` (Lines 890-925)

**Formula:**
```
avgSatisfaction = GetAverageSatisfaction()
threshold = 50

if avgSatisfaction < threshold:
    productivityMultiplier = avgSatisfaction / threshold
    productivityMultiplier = max(0.1, productivityMultiplier)
else:
    productivityMultiplier = 1.0

if isProtesting:
    productivityMultiplier = 0
```

**Productivity Curve:**
| Satisfaction | Productivity |
|--------------|--------------|
| 50+ | 100% |
| 40 | 80% |
| 25 | 50% |
| 10 | 20% |
| 0 | 10% (minimum) |
| -50 | 10% (clamped) |
| Protesting | 0% |

---

### 8.2 Protest Trigger

**File:** `code/consumption/CharacterV2.lua`
**Function:** `Character:CheckProtest()` (Lines 931-981)

**Conditions:**
```
Must satisfy ALL:
1. avgSatisfaction < satisfactionThreshold (30)
2. consecutiveFailedAllocations >= 10
3. random() < 0.2 (20% chance per cycle)
4. Not already protesting
5. Not emigrated
```

**End Condition:**
```
avgSatisfaction >= 40  →  Stop protesting
```

---

### 8.3 Emigration Trigger

**File:** `code/consumption/CharacterV2.lua`
**Function:** `Character:CheckEmigration(currentCycle)` (Lines 825-866)

**Conditions:**
```
Must satisfy ALL:
1. avgSatisfaction < threshold[class] (Elite:50, Lower:25)
2. consecutiveLowSatisfactionCycles >= cycleThreshold[class] (Elite:5, Lower:15)
3. criticalCravingCount >= 2 (coarse dimensions > 80)
4. random() < 0.15 (15% chance per cycle)
```

**Configuration:**
| Class | Satisfaction Threshold | Cycles Required |
|-------|----------------------|-----------------|
| Elite | 50 | 5 |
| Upper | 40 | 8 |
| Middle | 30 | 12 |
| Lower | 25 | 15 |

---

### 8.4 Civil Unrest

**File:** `code/consumption/TownConsequences.lua`
**Function:** `TownConsequences.CheckCivilUnrest(characters)` (Lines 18-58)

**Formula:**
```
protestPercentage = (protestingCount / totalPopulation) * 100

if protestPercentage >= 20:
    townProductivityPenalty = 0.5  -- 50% reduction
    return true
```

---

### 8.5 Riot Detection

**File:** `code/consumption/TownConsequences.lua`
**Function:** `TownConsequences.CheckRiot(characters, currentCycle)` (Lines 64-148)

**Conditions:**
```
1. dissatisfiedPercentage >= 40% (satisfaction < 40)
2. inequality >= 50 (max class avg - min class avg)
3. random() < 0.10 (10% chance per cycle)
```

**Damage:**
```
inventoryDamagePercent = 0.10 (10% of all commodities destroyed)
```

---

## 9. System Interactions

### 9.1 Feedback Loops

```
POSITIVE FEEDBACK (Downward Spiral):
┌─────────────────────────────────────────────────────────────┐
│ Low Satisfaction → Low Productivity → Less Production       │
│        ↑                                    ↓               │
│        └──── Fewer Goods ← Less to Allocate ←──────────────┘
└─────────────────────────────────────────────────────────────┘

NEGATIVE FEEDBACK (Stabilizing):
┌─────────────────────────────────────────────────────────────┐
│ High Cravings → Higher Priority → More Allocations          │
│        ↑                                    ↓               │
│        └──── Cravings Reduced ← Needs Met ←────────────────┘
└─────────────────────────────────────────────────────────────┘

VARIETY-SEEKING FEEDBACK:
┌─────────────────────────────────────────────────────────────┐
│ Repeated Consumption → Fatigue Increases → Lower Multiplier │
│        ↑                                           ↓        │
│        └── Try Different Commodity ← Substitution Boost ←──┘
└─────────────────────────────────────────────────────────────┘
```

### 9.2 Cross-System Effects

| Source System | Affects | Mechanism |
|---------------|---------|-----------|
| Craving Fulfillment | Satisfaction | +0.5x boost per fulfilled dimension |
| Satisfaction | Productivity | Linear degradation below 50 |
| Satisfaction | Emigration | Threshold check per class |
| Satisfaction | Protest | Threshold + failure count |
| Commodity Fatigue | Allocation | Multiplier reduces effectiveness |
| Commodity Fatigue | Substitution | Distance boost when fatigued |
| Active Effects | Cravings | 30% passive reduction per cycle |
| Active Effects | Satisfaction | 10% passive boost per cycle |
| Protests | Civil Unrest | 20%+ protesting → town penalty |
| Inequality | Riots | High inequality + dissatisfaction → damage |

---

## 10. Configuration Reference

### 10.1 File Locations

| Configuration | File Path |
|---------------|-----------|
| Dimension definitions | `data/base/craving_system/dimension_definitions.json` |
| Character classes | `data/base/craving_system/character_classes.json` |
| Character traits | `data/base/craving_system/character_traits.json` |
| Fulfillment vectors | `data/base/craving_system/fulfillment_vectors.json` |
| Commodity fatigue rates | `data/base/craving_system/commodity_fatigue_rates.json` |
| Substitution rules | `data/base/substitution_rules.json` |
| Consumption mechanics | `data/base/consumption_mechanics.json` |
| Enablement rules | `data/base/enablement_rules.json` |

### 10.2 Key Parameters Quick Reference

| Parameter | Location | Default | Effect |
|-----------|----------|---------|--------|
| cycleTime | Hardcoded | 60s | Allocation frequency |
| maxCravingMultiplier | Hardcoded | 50x | Craving cap |
| satisfactionBoostFactor | Hardcoded | 0.5x | How much consumption boosts satisfaction |
| passiveEffectStrength | Hardcoded | 0.3x | Durable passive effect strength |
| minFatigueMultiplier | consumption_mechanics | 0.25 | Floor for commodity fatigue |
| varietyCooldownCycles | consumption_mechanics | 10 | Cycles to reset fatigue |
| varietySeekingThreshold | consumption_mechanics | 0.70 | Multiplier that triggers substitution |
| protestThreshold | consumption_mechanics | 30 | Satisfaction for protest risk |
| protestFailureCount | Hardcoded | 10 | Consecutive failures for protest |
| emigrationChance | Hardcoded | 0.15 | Per-cycle chance when conditions met |
| riotChance | TownConsequences | 0.10 | Per-cycle chance when conditions met |

---

## 11. Example Calculations

### 11.1 Full Allocation Example

**Scenario:** Elite character "Lord Ashford" in cycle 50

**Step 1: Current State**
```
Class: Elite
Traits: ["ambitious", "hedonist"]
Current Cravings (coarse aggregated):
  biological: 45
  safety: 20
  social_status: 120 (critical!)
  vice: 80

Satisfaction:
  biological: 65
  social_status: 25
  vice: 40
```

**Step 2: Priority Calculation**
```
classWeight = 10 (Elite)
basePriority = 10 * 100 = 1000

Desperation scores:
  biological (45): medium (2.0) × weight (1.0) = 2.0
  safety (20): low (1.0) × weight (0.9) = 0.9
  social_status (120): critical (10.0) × weight (0.3) = 3.0
  vice (80): high (5.0) × weight (0.1) = 0.5

Total desperation = 2.0 + 0.9 + 3.0 + 0.5 = 6.4

finalPriority = 1000 + 6.4 = 1006.4
```

**Step 3: Target Selection**
```
Highest scoring fine dimension: social_status_recognition (from 120 coarse)

Available commodities for social_status_recognition:
  - gold_jewelry: 25 points, multiplier 0.95 → score = 120 × 0.3 × 25 × 0.95 = 855
  - silk_clothes: 15 points, multiplier 0.80 → score = 120 × 0.3 × 15 × 0.80 = 432

Best: gold_jewelry (score 855)
```

**Step 4: Allocation**
```
Allocate gold_jewelry to Lord Ashford
- Remove 1 from inventory
- FulfillCraving(gold_jewelry, 1, 50)
  - Reduce social_status_recognition by 25 × 1.0 × 0.95 × 1 = 23.75
  - Boost social_status satisfaction by 25 × 1.0 × 0.95 × 1 × 0.5 = 11.875
- Update fatigue history for gold_jewelry
- Budget remaining: 10 - 1 = 9
```

---

### 11.2 Durable Passive Effect Example

**Scenario:** Character owns a bed (500 cycles, 0.001 decay)

**Cycle 100 (50 cycles after acquisition):**
```
Effectiveness after 50 cycles:
  effectiveness = 1.0 × (1 - 0.001)^50
               = 1.0 × 0.999^50
               = 0.951 (95.1%)

Remaining cycles: 500 - 50 = 450

Bed fulfillment vector:
  touch_comfort_rest: 15
  psychological_peace_relaxation: 10

Passive effects this cycle:
  touch_comfort_rest reduction = 15 × 0.951 × 0.3 = 4.28 points
  psychological reduction = 10 × 0.951 × 0.3 = 2.85 points

  touch satisfaction boost = 15 × 0.951 × 0.1 = 1.43 points
  psychological satisfaction boost = 10 × 0.951 × 0.1 = 0.95 points
```

---

## 12. Tuning Guide

### 12.1 Making Characters More/Less Demanding

| Goal | Parameter | Change |
|------|-----------|--------|
| More demanding | baseCravings in class JSON | Increase values |
| Less demanding | baseCravings in class JSON | Decrease values |
| Faster satisfaction decay | cravingDecayRates | Increase per-class values |
| Slower decay | cravingDecayRates | Decrease per-class values |

### 12.2 Adjusting Class Inequality

| Goal | Parameter | Change |
|------|-----------|--------|
| More inequality | classWeights | Increase Elite, decrease Lower |
| Less inequality | classWeights | Flatten values (e.g., all 5) |
| Elite more patient | emigrationThresholds | Lower Elite threshold |
| Lower class more resilient | consecutiveCyclesRequired | Increase Lower value |

### 12.3 Tuning Variety-Seeking

| Goal | Parameter | Change |
|------|-----------|--------|
| More variety seeking | baseFatigueRate in commodities | Increase |
| Less variety seeking | baseFatigueRate | Decrease |
| Faster recovery | varietyCooldownCycles | Decrease |
| Earlier substitution trigger | varietySeekingThreshold | Increase (e.g., 0.80) |

### 12.4 Balancing Durables

| Goal | Parameter | Change |
|------|-----------|--------|
| Durables more impactful | passiveMultiplier (hardcoded) | Increase from 0.3 |
| Durables less impactful | passiveMultiplier | Decrease |
| Longer lasting | durationCycles in commodity | Increase |
| Faster degradation | effectDecayRate | Increase |

---

## 13. Debugging Guide

### 13.1 Common Issues

**Issue: Characters not consuming anything**
```
Check:
1. townInventory has commodities (quantity > 0)
2. Character has cravings (currentCravings > 0)
3. Character not emigrated (hasEmigrated == false)
4. Commodity fulfillment vectors match craving dimensions
```

**Issue: Single commodity dominates**
```
Check:
1. Commodity fatigue rates - too low means no variety seeking
2. Substitution rules exist for alternatives
3. varietySeekingThreshold - may need lowering
```

**Issue: Satisfaction never improves**
```
Check:
1. Decay rates vs fulfillment points (decay may exceed gains)
2. satisfactionBoostFactor (0.5x may be too low)
3. Quality multipliers on commodities
```

**Issue: Everyone emigrating**
```
Check:
1. Starting satisfaction ranges (too low?)
2. Commodity supply vs population
3. Class consumption budgets (too low?)
4. Decay rates (too high?)
```

### 13.2 Debug Logging

Key print statements in the code:
- `SelectTargetCraving`: Shows craving values and selected commodity
- `AllocateForCharacter`: Shows allocation result and status
- `FulfillCraving`: Shows craving reduction amounts
- `UpdateActiveEffects`: Shows expiring durables

---

## 14. Design Rationale

### 14.1 Why 49 Dimensions?

**Problem:** 9 coarse dimensions cause "medicine dominates biological" - high-value items always win their category.

**Solution:** 49 fine dimensions allow nuanced matching. A character craving "nutrition_grain" won't accept "nutrition_medicine" even though both are "biological."

### 14.2 Why Exponential Fatigue Decay?

**Problem:** Linear fatigue feels artificial - people don't get equally bored each time.

**Solution:** Exponential decay (`e^(-count * rate)`) models real psychology:
- First few times: minimal fatigue
- Repeated consumption: accelerating boredom
- Natural floor at 25%: never completely useless

### 14.3 Why Sequential Allocation (not Round-Robin)?

**Problem:** Round-robin is "fair" but unrealistic - in scarcity, powerful people get more.

**Solution:** Sequential by priority models real resource competition:
- Elite exhaust budget before Lower gets chance
- Creates meaningful class dynamics
- Fairness mode available as alternative policy

### 14.4 Why Passive Effects at 30%?

**Problem:** If durables gave 100% per cycle, consumables become pointless.

**Solution:** 30% passive effect means:
- Durables provide steady baseline
- Consumables still needed for full satisfaction
- Characters with both durables AND consumables thrive

### 14.5 Why Distance-Based Substitution Boost?

**Problem:** When fatigued, any substitute equally good - unrealistic.

**Solution:** Close substitutes (low distance) get bonus when fatigued:
- Tired of wheat? Rice (close) better than bread (distant)
- Models real preference for "similar but different"
- Encourages variety within categories

---

## 15. Quick Reference

### 15.1 Formula Cheat Sheet

```
CRAVING ACCUMULATION:
  craving[i] += base[i] × (dt / 60)

SATISFACTION DECAY:
  decay = baseDecay × (1 + avgCraving / 50)

COMMODITY FATIGUE:
  multiplier = e^(-consecutiveCount × fatigueRate)
  multiplier = max(0.25, multiplier)

PRIORITY SCORE:
  priority = classWeight × 100 + Σ(desperationMultiplier × dimensionWeight)

SUBSTITUTION BOOST:
  boost = 1 + (1 - primaryMultiplier) × (1 - distance) × 0.5

PASSIVE DURABLE EFFECT:
  reduction = points × effectiveness × 0.3

PRODUCTIVITY:
  productivity = min(1.0, satisfaction / 50)
```

### 15.2 Threshold Quick Reference

| Check | Threshold | Consequence |
|-------|-----------|-------------|
| Variety seeking | multiplier < 0.70 | Try substitution |
| Craving critical | coarse > 80 | Counts toward emigration |
| Satisfaction low | varies by class | Starts emigration timer |
| Protest trigger | satisfaction < 30, failures >= 10 | 20% chance/cycle |
| Emigration trigger | consecutive cycles + critical cravings | 15% chance/cycle |
| Civil unrest | 20% protesting | 50% town productivity |
| Riot trigger | 40% dissatisfied + inequality >= 50 | 10% chance/cycle |

### 15.3 Class Comparison

| Metric | Elite | Upper | Middle | Lower |
|--------|-------|-------|--------|-------|
| Priority weight | 10 | 7 | 4 | 1 |
| Budget/cycle | 10 | 7 | 5 | 3 |
| Satisfaction start | 60-80 | 50-70 | 30-50 | 20-40 |
| Emigration threshold | 50 | 40 | 30 | 25 |
| Cycles before emigration risk | 5 | 8 | 12 | 15 |
| Biological decay | 2.0 | 2.5 | 3.0 | 3.5 |
| Status decay | 5.0 | 4.0 | 3.0 | 2.0 |

---

## Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2025-12-02 | 1.0 | Initial comprehensive documentation |

---

*This document is the single source of truth for all consumption and production system computations. Update this document when modifying any calculation logic.*
