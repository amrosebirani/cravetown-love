# Consumption System Architecture v2.0

**Author:** Claude + Amrose Birani
**Date:** 2025-11-27
**Status:** Final Design - Ready for Implementation

---

## Executive Summary

This document defines the complete consumption system architecture for CraveTown. The system models human needs, preferences, consumption decisions, and their consequences through a multi-layered vector-based approach operating at **fine-grained (49 dimensions)** precision.

### Core Philosophy
- **Precision Computation**: All mechanics operate at fine (49D) level
- **Manageable UI**: Display aggregated to coarse (9D) level
- **Emergent Behavior**: Complex outcomes from simple rules
- **Performance First**: Hierarchical caching and smart invalidation

---

## 1. Character State Layers

### Layer 1: Base Identity (Static)
Immutable character attributes that define their archetype.

```lua
Character.identity = {
    id = "char_492851",
    name = "John Smith",
    age = 35,
    gender = "male",
    class = "Middle",        -- Elite/Upper/Middle/Lower
    vocation = "baker",
    traits = {
        "ambitious",
        "intellectual"
    }
}
```

**Purpose**: Foundation for all derived values, never changes during character lifetime.

---

### Layer 2: Base Cravings Vector (Quasi-Static)
The "genetic" need profile - how much each fine craving naturally decays per cycle.

```lua
-- Computed from: class × trait_multipliers × age_modifier × gender_modifier
Character.baseCravings = {
    -- Fine level (49 dimensions)
    biological_nutrition_grain = 3.0,      -- Points/cycle decay rate
    biological_nutrition_protein = 2.5,
    biological_nutrition_fruit = 2.0,
    biological_hydration_water = 4.0,
    biological_taste_sweet = 1.5,
    biological_taste_savory = 2.0,
    biological_warmth = 3.0,
    biological_energy = 2.5,

    safety_shelter_basic = 2.0,
    safety_shelter_premium = 1.0,
    safety_defense_personal = 1.5,
    safety_defense_community = 1.0,
    safety_stability = 2.0,

    touch_clothing_basic = 1.5,
    touch_clothing_premium = 0.5,
    touch_furniture_basic = 1.0,
    touch_furniture_premium = 0.3,
    touch_beauty_personal = 1.0,
    touch_beauty_environmental = 0.8,

    psychological_purpose = 1.5,
    psychological_achievement = 1.8,
    psychological_education = 2.0,
    psychological_entertainment = 2.5,
    psychological_creativity = 1.0,
    psychological_spirituality = 1.0,
    psychological_autonomy = 1.5,

    social_status_wealth_display = 2.0,
    social_status_power = 1.5,
    social_status_prestige = 1.8,
    social_status_reputation = 1.5,
    social_status_authority = 1.0,
    social_status_household_display = 1.2,

    social_connection_family = 1.5,
    social_connection_community = 1.8,
    social_connection_romantic = 1.0,
    social_connection_friendship = 2.0,
    social_connection_belonging = 1.5,

    exotic_goods_spices = 1.0,
    exotic_goods_fabrics = 0.8,
    exotic_goods_art = 0.5,
    exotic_goods_technology = 0.3,

    shiny_objects_jewelry = 1.0,
    shiny_objects_decor = 0.8,
    shiny_objects_collectibles = 0.5,
    shiny_objects_novelty = 1.2,

    vice_alcohol = 1.5,
    vice_gambling = 0.5,
    vice_indulgence = 1.0,
    vice_escapism = 1.2,
    vice_stimulants = 0.8
}
```

**Modification Triggers:**
- **Trait changes** (rare, player-driven events)
- **Age progression** (gradual shifts over time)
- **Enablement vectors** (see Layer 2.5)

**Calculation Formula:**
```lua
function CalculateBaseCravings(character)
    local base = CLASS_VECTORS[character.class]

    -- Apply trait multipliers (multiplicative)
    for _, trait in ipairs(character.traits) do
        local traitData = TRAIT_DATA[trait]
        for dim, value in pairs(base) do
            base[dim] = base[dim] * traitData.cravingMultipliers.fine[dim]
        end
    end

    -- Apply age modifier (additive)
    local ageMod = CalculateAgeModifier(character.age)
    for dim, value in pairs(base) do
        base[dim] = base[dim] + ageMod[dim]
    end

    return base
end
```

---

### Layer 2.5: Enablement Vectors (Dynamic Unlocking)
External triggers that unlock or amplify new cravings.

```lua
Character.enablementState = {
    has_house = false,
    has_family = false,
    has_education = false,
    has_social_standing = false,
    -- ... more conditions
}

-- Enablement rules (defined in enablement_vectors.json)
EnablementRules = {
    has_house = {
        unlocks = {
            touch_furniture_basic = 2.5,      -- Unlocked from 0
            touch_furniture_premium = 0.8,
            social_status_household_display = 1.5
        },
        amplifies = {
            safety_shelter_premium = 1.5      -- Multiplier on existing craving
        }
    },
    has_family = {
        unlocks = {
            social_connection_family = 3.0
        },
        amplifies = {
            safety_shelter_basic = 1.3,
            biological_nutrition_protein = 1.2  -- Need to feed family
        }
    }
}
```

**Application:**
```lua
function Character:ApplyEnablement(enablementType)
    self.enablementState[enablementType] = true
    local rules = EnablementRules[enablementType]

    -- Unlock new cravings
    for craving, value in pairs(rules.unlocks) do
        if self.baseCravings[craving] == 0 then
            self.baseCravings[craving] = value
            print("New craving unlocked: " .. craving)
        end
    end

    -- Amplify existing cravings
    for craving, multiplier in pairs(rules.amplifies) do
        self.baseCravings[craving] = self.baseCravings[craving] * multiplier
    end
end
```

---

### Layer 3: Current Cravings Vector (Dynamic - Accumulation/Decay)
Tracks the **immediate need state** - accumulates over time, resets to 0 when satisfied.

```lua
Character.currentCravings = {
    -- Fine level (49 dimensions)
    -- Values represent "points accumulated since last satisfaction"
    biological_nutrition_grain = 45.2,
    biological_nutrition_protein = 12.8,
    biological_hydration_water = 78.5,
    -- ... all 49 dimensions
}
```

**Behavior:**
- **Starts at 0** when character is created or after consumption
- **Accumulates** based on `baseCravings` decay rate per cycle
- **Resets to 0** (or partial) when satisfied by consumption
- **Triggers allocation** when crosses threshold

**Update Formula (every cycle):**
```lua
function Character:UpdateCurrentCravings(deltaTime)
    for craving, baseDecay in pairs(self.baseCravings) do
        if baseDecay > 0 then  -- Only accumulate if enabled
            -- Accumulate based on base decay rate
            local accumulation = baseDecay * (deltaTime / 60.0)
            self.currentCravings[craving] = self.currentCravings[craving] + accumulation
        end
    end
end
```

**Consumption Effect:**
```lua
function Character:ConsumeCommodity(commodity, quantity)
    local fulfillmentVector = COMMODITIES[commodity].fulfillmentVector.fine

    for dim, points in pairs(fulfillmentVector) do
        if points > 0 then
            -- Reset/reduce current craving
            local satisfaction = points * quantity
            self.currentCravings[dim] = math.max(0, self.currentCravings[dim] - satisfaction)
        end
    end
end
```

**Example Cycle:**
```
Cycle 1:  currentCravings.biological_nutrition_grain = 0
          (just ate bread)

Cycle 2:  + 3.0 accumulation = 3.0
Cycle 3:  + 3.0 accumulation = 6.0
Cycle 4:  + 3.0 accumulation = 9.0
...
Cycle 15: + 3.0 accumulation = 45.0 (crosses threshold = 40)
          → Character gets priority for grain allocation
          → Eats bread → resets to 0
```

---

### Layer 4: Satisfaction State Vector (Dynamic - Lifetime Tracker)
Long-term satisfaction state that influences character happiness and consequences.

```lua
Character.satisfaction = {
    -- Fine level (49 dimensions)
    -- Range: -100 (miserable) to 300 (ecstatic)
    biological_nutrition_grain = 65.2,
    biological_nutrition_protein = 45.8,
    biological_hydration_water = 120.5,
    -- ... all 49 dimensions
}

-- Aggregated for UI/Priority
Character.satisfactionCoarse = {
    -- Coarse level (9 dimensions)
    -- Average of fine dimensions within each coarse category
    biological = 72.3,      -- Avg of 8 fine biologicals
    safety = 58.1,          -- Avg of 5 fine safety
    touch = 45.0,           -- Avg of 6 fine touch
    psychological = 62.5,   -- Avg of 7 fine psychological
    social_status = 55.0,   -- Avg of 6 fine social_status
    social_connection = 68.0, -- Avg of 5 fine social_connection
    exotic_goods = 30.0,    -- Avg of 4 fine exotic_goods
    shiny_objects = 25.0,   -- Avg of 4 fine shiny_objects
    vice = 40.0             -- Avg of 5 fine vice
}
```

**Update Formula:**
```lua
function Character:UpdateSatisfaction(deltaTime)
    -- 1. Decay satisfaction over time (slow)
    local satisfactionDecayRate = 0.5  -- Points per cycle
    for dim, value in pairs(self.satisfaction) do
        self.satisfaction[dim] = math.max(-100, value - satisfactionDecayRate * (deltaTime / 60.0))
    end

    -- 2. Penalty for unmet current cravings (fast)
    for craving, currentNeed in pairs(self.currentCravings) do
        if currentNeed > 40 then  -- High unmet need
            local penalty = (currentNeed - 40) * 0.2  -- Escalating penalty
            self.satisfaction[craving] = math.max(-100, self.satisfaction[craving] - penalty * (deltaTime / 60.0))
        end
    end
end

function Character:ApplySatisfactionGain(commodity, quantity)
    local fulfillmentVector = COMMODITIES[commodity].fulfillmentVector.fine
    local commodityMultiplier = self:GetCommodityMultiplier(commodity)

    for dim, points in pairs(fulfillmentVector) do
        if points > 0 then
            -- Gain satisfaction (capped at 300)
            local gain = points * quantity * commodityMultiplier
            self.satisfaction[dim] = math.min(300, self.satisfaction[dim] + gain)
        end
    end

    -- Update coarse aggregates
    self:RecalculateSatisfactionCoarse()
end
```

**Relationship to Current Cravings:**
- `currentCravings` = short-term needs (hours/days)
- `satisfaction` = long-term happiness (weeks/months)
- High `currentCravings` with low `satisfaction` = desperate + miserable
- Low `currentCravings` with high `satisfaction` = content + thriving

---

### Layer 5: Commodity Multiplier Vector (Dynamic - Fatigue/Boredom)
Tracks diminishing returns and variety-seeking behavior per commodity.

```lua
Character.commodityMultipliers = {
    -- Per commodity, range: 0.0 (completely tired) to 1.0 (fresh)
    bread = 0.73,
    meat = 1.0,
    cake = 0.42,
    wine = 0.85,
    -- ... all commodities in game
}

Character.commodityHistory = {
    bread = {
        consecutiveConsumptions = 5,
        lastConsumed = cycle_42,
        totalConsumed = 127
    },
    meat = {
        consecutiveConsumptions = 0,
        lastConsumed = cycle_35,
        totalConsumed = 48
    }
}
```

**Decay Formula (Personalized):**
```lua
function Character:CalculateCommodityMultiplier(commodity)
    local history = self.commodityHistory[commodity]
    if not history then return 1.0 end  -- Never consumed

    -- Get base fatigue rate from commodity + trait modifiers
    local commodityData = COMMODITIES[commodity]
    local baseFatigueRate = commodityData.baseFatigueRate or 0.15

    -- Apply trait modifiers
    local traitMultiplier = 1.0
    for _, trait in ipairs(self.traits) do
        if commodityData.fatigueModifiers[trait] then
            traitMultiplier = traitMultiplier * commodityData.fatigueModifiers[trait]
        end
    end

    local effectiveFatigueRate = baseFatigueRate * traitMultiplier

    -- Exponential decay based on consecutive consumptions
    local fatigue = math.exp(-history.consecutiveConsumptions * effectiveFatigueRate)

    -- Recovery based on time since last consumed
    local cyclesSince = currentCycle - history.lastConsumed
    local recoveryRate = 0.1  -- 10% recovery per cycle
    local recovery = math.min(1.0, cyclesSince * recoveryRate)

    -- Combined multiplier
    return math.max(0.0, fatigue * recovery)
end
```

**Example Progression (bread, baseFatigueRate=0.15, frugal character=0.8x):**
```
Cycle 1:  Eat bread → consecutiveConsumptions = 1 → multiplier = 0.88
Cycle 2:  Eat bread → consecutiveConsumptions = 2 → multiplier = 0.78
Cycle 3:  Eat bread → consecutiveConsumptions = 3 → multiplier = 0.68
Cycle 4:  Eat bread → consecutiveConsumptions = 4 → multiplier = 0.60
Cycle 5:  Eat bread → consecutiveConsumptions = 5 → multiplier = 0.52
          → "Tired of bread" triggers variety-seeking
```

---

### Layer 6: Consumption History (Analytics)
Recent decisions for UI display and pattern analysis.

```lua
Character.consumptionHistory = {
    {
        cycle = 45,
        commodity = "bread",
        quantity = 1,
        satisfactionGains = {
            biological_nutrition_grain = 5.2,
            biological_taste_savory = 2.1
        },
        multiplier = 0.73,
        status = "granted"  -- granted/substituted/failed
    },
    {
        cycle = 44,
        commodity = "wine",
        quantity = 1,
        satisfactionGains = {
            psychological_entertainment = 8.1,
            vice_alcohol = 3.2
        },
        multiplier = 0.95,
        status = "granted"
    },
    {
        cycle = 43,
        commodity = nil,
        status = "failed"
    }
    -- ... last 20 entries
}
```

---

## 2. Allocation System

### 2.1 Priority Calculation

```lua
function Character:CalculatePriority(currentCycle, allocationPolicy)
    local priority = 0

    -- Factor 1: Desperation score (from currentCravings)
    local desperationScore = 0
    for craving, currentNeed in pairs(self.currentCravings) do
        if currentNeed > 40 then
            -- Exponential weight for critical needs
            desperationScore = desperationScore + math.exp((currentNeed - 40) / 20)
        end
    end
    priority = priority + desperationScore * 100

    -- Factor 2: Class weight (user-configurable)
    local classWeight = allocationPolicy.classWeights[self.class]
    priority = priority + classWeight * 10

    -- Factor 3: Allocation history (fairness mechanic)
    if allocationPolicy.fairnessMode ~= "pure_priority" then
        local recentAllocations = self:CountRecentAllocations(5)  -- Last 5 cycles
        local historyPenalty = allocationPolicy.allocationHistoryWeight
        priority = priority * (1.0 / (1.0 + recentAllocations * historyPenalty))
    end

    -- Factor 4: Critical override
    local avgSatisfaction = self:GetAverageSatisfactionCoarse()
    if avgSatisfaction < allocationPolicy.criticalThreshold then
        priority = priority * 2.0  -- Double priority for critical characters
    end

    return priority
end
```

### 2.2 Allocation Algorithm

```lua
function AllocationEngine:AllocateCycle(characters, inventory, currentCycle, policy)
    -- Step 1: Calculate priorities
    for _, char in ipairs(characters) do
        char:CalculatePriority(currentCycle, policy)
    end

    -- Step 2: Sort by priority (highest first)
    table.sort(characters, function(a, b)
        return a.priority > b.priority
    end)

    -- Step 3: Sequential allocation
    for rank, char in ipairs(characters) do
        -- Find highest current craving
        local targetCraving = char:GetHighestCurrentCraving()

        -- Get candidate commodities from cache
        local candidates = CommodityCache:GetCommoditiesForCraving(targetCraving)

        -- Score each candidate
        local bestCommodity = nil
        local bestScore = 0

        for _, commodity in ipairs(candidates) do
            if inventory[commodity] > 0 then
                local score = self:ScoreCommodity(char, commodity, targetCraving)
                if score > bestScore then
                    bestScore = score
                    bestCommodity = commodity
                end
            end
        end

        -- Allocate if found
        if bestCommodity then
            self:AllocateCommodity(char, bestCommodity, 1, inventory)
        else
            char:RecordFailedAllocation(currentCycle)
        end
    end
end

function AllocationEngine:ScoreCommodity(character, commodity, targetCraving)
    local fulfillmentVector = COMMODITIES[commodity].fulfillmentVector.fine
    local commodityMultiplier = character:GetCommodityMultiplier(commodity)

    -- Base satisfaction points for target craving
    local baseScore = fulfillmentVector[targetCraving] or 0

    -- Apply fatigue multiplier
    local score = baseScore * commodityMultiplier

    -- Bonus for multi-dimensional satisfaction
    for craving, points in pairs(fulfillmentVector) do
        if craving ~= targetCraving and character.currentCravings[craving] > 20 then
            score = score + points * 0.5  -- 50% bonus for secondary satisfaction
        end
    end

    return score
end
```

---

## 3. Substitution & Variety-Seeking

### 3.1 Substitution Distance

Defined in `substitution_rules.json`:

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

### 3.2 Boost Mechanics

When a character consumes a commodity, related substitutes become more attractive:

```lua
function Character:BoostSubstitutes(consumedCommodity)
    local rules = SubstitutionRules[consumedCommodity]
    if not rules then return end

    -- Boost close substitutes
    for _, sub in ipairs(rules.close_substitutes) do
        local currentMultiplier = self.commodityMultipliers[sub.commodity]
        local gap = 1.0 - currentMultiplier
        local boost = gap * (1.0 - sub.distance) * 0.3  -- 30% boost factor
        self.commodityMultipliers[sub.commodity] = math.min(1.0, currentMultiplier + boost)
    end

    -- Boost distant substitutes (smaller effect)
    for _, sub in ipairs(rules.distant_substitutes) do
        local currentMultiplier = self.commodityMultipliers[sub.commodity]
        local gap = 1.0 - currentMultiplier
        local boost = gap * (1.0 - sub.distance) * 0.15  -- 15% boost factor
        self.commodityMultipliers[sub.commodity] = math.min(1.0, currentMultiplier + boost)
    end
end
```

**Example:**
```
Character tired of cake (multiplier = 0.3)
Consumes pie (close substitute, distance = 0.1)

Cake boost calculation:
  gap = 1.0 - 0.3 = 0.7
  boost = 0.7 * (1.0 - 0.1) * 0.3 = 0.189
  new multiplier = 0.3 + 0.189 = 0.489

Character tired of bread (multiplier = 0.5)
Consumes pie (distant substitute, distance = 0.5)

Bread boost calculation:
  gap = 1.0 - 0.5 = 0.5
  boost = 0.5 * (1.0 - 0.5) * 0.15 = 0.0375
  new multiplier = 0.5 + 0.0375 = 0.5375
```

---

## 4. Consequences System

### 4.1 Individual Consequences

```lua
function Character:CheckConsequences(currentCycle)
    local avgSatisfaction = self:GetAverageSatisfactionCoarse()
    local consecutiveFailures = self:GetConsecutiveFailures()

    -- Productivity impact (gradual)
    if avgSatisfaction < 50 then
        self.productivityMultiplier = avgSatisfaction / 50  -- Linear decay
    else
        self.productivityMultiplier = 1.0
    end

    -- Protest (medium severity)
    if avgSatisfaction < 30 and consecutiveFailures > 10 then
        if math.random() < 0.05 then
            self.status = "protesting"
            self.productivityMultiplier = 0.0  -- Stop working
            return "protest"
        end
    end

    -- Emigration check (requires external opportunity)
    if avgSatisfaction < 10 and consecutiveFailures > 20 then
        local opportunity = TownEvents:GetMatchingEmigrationOpportunity(self)
        if opportunity and math.random() < 0.15 then
            self:Emigrate(opportunity.destination)
            return "emigrated"
        end
    end

    return "normal"
end
```

### 4.2 Town-Level Consequences

```lua
function Town:CheckCollectiveConsequences()
    local dissatisfiedCount = 0
    local protestingCount = 0

    for _, char in ipairs(self.characters) do
        if char:GetAverageSatisfactionCoarse() < 30 then
            dissatisfiedCount = dissatisfiedCount + 1
        end
        if char.status == "protesting" then
            protestingCount = protestingCount + 1
        end
    end

    local totalChars = #self.characters
    local dissatisfactionRate = dissatisfiedCount / totalChars
    local protestRate = protestingCount / totalChars

    -- Civil unrest (20%+ protesting)
    if protestRate > 0.20 then
        self.civilUnrestActive = true
        self.globalProductivityMultiplier = 0.5  -- 50% productivity penalty
    end

    -- Riot (40%+ dissatisfied + inequality)
    if dissatisfactionRate > 0.40 then
        local inequality = self:CalculateInequalityIndex()
        if inequality > 0.6 and math.random() < 0.10 then
            self:TriggerRiot()
        end
    end
end

function Town:TriggerRiot()
    print("RIOT! Town resources being destroyed")

    -- Damage random inventory
    for commodity, quantity in pairs(self.inventory) do
        local damage = math.floor(quantity * math.random(0.1, 0.3))  -- 10-30% loss
        self.inventory[commodity] = math.max(0, quantity - damage)
    end

    -- Damage random buildings
    local damagedBuildings = math.floor(#self.buildings * 0.05)  -- 5% of buildings
    for i = 1, damagedBuildings do
        local building = self.buildings[math.random(#self.buildings)]
        building.health = math.max(0, building.health - 50)
    end

    -- Reset some dissatisfaction (catharsis)
    for _, char in ipairs(self.characters) do
        if char:GetAverageSatisfactionCoarse() < 40 then
            char:ApplySatisfactionGain("riot_catharsis", 10)  -- Small relief
        end
    end
end
```

### 4.3 Emigration Opportunities

```lua
-- Mocked events for prototype
TownEvents = {
    emigrationOpportunities = {
        {
            cycle = 150,
            requirements = {
                class = {"Lower", "Middle"},
                vocation = {"farmer", "laborer"},
                satisfaction_threshold = 30
            },
            slots = 5,
            destination = "MockTown_A"
        },
        {
            cycle = 300,
            requirements = {
                class = {"Upper", "Elite"},
                vocation = {"merchant", "noble"},
                satisfaction_threshold = 50
            },
            slots = 2,
            destination = "MockTown_B"
        }
    }
}
```

---

## 5. Performance Optimization

### 5.1 Hierarchical Cache

```lua
CommodityCache = {
    -- Level 1: By coarse dimension
    byCoarseDimension = {
        biological = {
            available = {"bread", "meat", "rice", "fish"},
            lastUpdated = 42,
            dirty = false
        }
    },

    -- Level 2: By fine dimension
    byFineDimension = {
        biological_nutrition_grain = {
            available = {"bread", "rice", "wheat"},
            sorted = true,  -- Pre-sorted by base fulfillment
            lastUpdated = 42,
            dirty = false
        }
    },

    -- Level 3: Substitution groups
    substitutionGroups = {
        grains = {
            members = {"bread", "rice", "wheat"},
            lastUpdated = 42,
            dirty = false
        }
    }
}
```

### 5.2 Cache Invalidation

```lua
function InvalidateCache(commodity)
    -- Find affected fine dimensions
    local fulfillmentVector = COMMODITIES[commodity].fulfillmentVector.fine

    for dim, points in pairs(fulfillmentVector) do
        if points > 0 then
            -- Invalidate fine cache
            CommodityCache.byFineDimension[dim].dirty = true

            -- Invalidate parent coarse cache
            local coarseDim = GetCoarseDimension(dim)
            CommodityCache.byCoarseDimension[coarseDim].dirty = true
        end
    end

    -- Invalidate substitution group
    local group = GetSubstitutionGroup(commodity)
    if group then
        CommodityCache.substitutionGroups[group].dirty = true
    end
end

function RebuildCache()
    -- Only rebuild dirty caches
    for dim, cache in pairs(CommodityCache.byFineDimension) do
        if cache.dirty then
            cache.available = {}
            for commodity, data in pairs(COMMODITIES) do
                if data.fulfillmentVector.fine[dim] > 0 and inventory[commodity] > 0 then
                    table.insert(cache.available, commodity)
                end
            end

            -- Sort by base fulfillment (descending)
            table.sort(cache.available, function(a, b)
                return COMMODITIES[a].fulfillmentVector.fine[dim] >
                       COMMODITIES[b].fulfillmentVector.fine[dim]
            end)

            cache.dirty = false
            cache.lastUpdated = currentCycle
        end
    end
end
```

### 5.3 Performance Targets

- **Allocation cycle**: < 5ms for 100 characters with 50 commodities
- **Cache rebuild**: < 2ms for full rebuild
- **Priority calculation**: < 0.05ms per character
- **UI update**: 60 FPS with all visualizations

---

## 6. UI Design

### 6.1 Character Detail Modal

```
╔════════════════ CHARACTER: John Smith ════════════════╗
║ Class: Middle | Age: 35 | Vocation: Baker            ║
║ Traits: [Ambitious] [Intellectual]                   ║
║ Enablements: [Has House] [Has Education]             ║
╠═══════════════════════════════════════════════════════╣
║ SATISFACTION (Coarse - 9 dimensions)                  ║
║ ▓▓▓▓▓▓░░░░ Biological: 65/100       [Expand ▼]       ║
║ ▓▓▓▓▓▓▓▓░░ Safety: 80/100           [Expand ▼]       ║
║ ▓▓▓░░░░░░░ Psychological: 30/100 ⚠️  [Expand ▼]       ║
║ ▓▓▓▓▓▓▓░░░ Touch: 70/100            [Expand ▼]       ║
║ ▓▓▓▓▓░░░░░ Social Status: 55/100    [Expand ▼]       ║
║ ▓▓▓▓▓▓▓▓░░ Social Connection: 68/100 [Expand ▼]      ║
║ ▓▓░░░░░░░░ Exotic Goods: 30/100     [Expand ▼]       ║
║ ▓▓░░░░░░░░ Shiny Objects: 25/100    [Expand ▼]       ║
║ ▓▓▓▓░░░░░░ Vice: 40/100             [Expand ▼]       ║
╠═══════════════════════════════════════════════════════╣
║ CURRENT CRAVINGS (Top 10 Most Urgent)                ║
║ 🔥 biological_nutrition_grain: 78 (urgent!)          ║
║ 🔥 psychological_entertainment: 65                   ║
║ 🔥 social_connection_friendship: 52                  ║
║ ⚡ touch_clothing_basic: 45                          ║
║ ⚡ biological_taste_sweet: 38                        ║
║ ... (show top 10)                                    ║
╠═══════════════════════════════════════════════════════╣
║ COMMODITY FATIGUE (Top 10 Most Consumed)            ║
║ 🍞 Bread: ▓▓▓░░ 60% effective (tired, 5x consumed)  ║
║ 🥩 Meat: ▓▓▓▓▓ 100% effective (fresh)               ║
║ 🍰 Cake: ▓░░░░ 20% effective (very tired, 8x)       ║
║ 🍺 Beer: ▓▓▓▓░ 80% effective (3x consumed)          ║
║ ... (show top 10)                                    ║
╠═══════════════════════════════════════════════════════╣
║ RECENT CONSUMPTION (Last 10 cycles)                  ║
║ Cycle 45: ✓ Bread → bio_grain +5.2, taste +2.1      ║
║ Cycle 44: ✓ Wine → psych_ent +8.1, vice +3.2        ║
║ Cycle 43: ✗ FAILED (no allocation)                   ║
║ Cycle 42: ✓ Bread → bio_grain +3.8 (diminished)     ║
║ Cycle 41: ✓ Meat → bio_protein +9.5                 ║
║ ... (show last 10)                                   ║
╠═══════════════════════════════════════════════════════╣
║ STATUS                                                ║
║ Priority Rank: #12 / 50                              ║
║ Productivity: 85% (slightly unhappy)                 ║
║ Consecutive Failures: 1                              ║
║ Emigration Risk: Low (2%)                            ║
║ Protest Risk: Medium (15%)                           ║
╚═══════════════════════════════════════════════════════╝
```

### 6.2 Fine Dimension Expansion

When clicking "Expand" on coarse dimension:

```
╔═══════════════════════════════════════════════════════╗
║ BIOLOGICAL (Coarse: 65/100)          [Collapse ▲]    ║
╠═══════════════════════════════════════════════════════╣
║ Top 10 Fine Dimensions:                               ║
║ ▓▓▓▓▓▓▓▓▓░ nutrition_grain: 95        (high!)        ║
║ ▓▓▓▓▓▓▓▓░░ hydration_water: 85                       ║
║ ▓▓▓▓▓▓▓░░░ taste_savory: 78                          ║
║ ▓▓▓▓▓▓▓░░░ energy: 75                                ║
║ ▓▓▓▓▓▓░░░░ warmth: 68                                ║
║ ▓▓▓▓▓▓░░░░ nutrition_protein: 65                     ║
║ ▓▓▓▓▓░░░░░ taste_sweet: 55                           ║
║ ▓▓▓▓▓░░░░░ nutrition_fruit: 52                       ║
║                                                       ║
║ Bottom 10 Fine Dimensions:                            ║
║ ▓▓░░░░░░░░ nutrition_spice: 25        (low!)         ║
║ ▓░░░░░░░░░ taste_bitter: 15           (critical!)    ║
╚═══════════════════════════════════════════════════════╝
```

### 6.3 Allocation Policy Panel (Added Last)

```
╔══════════ ALLOCATION POLICY ══════════╗
║ Class Weights:                        ║
║ Elite:  [=========|=] 10              ║
║ Upper:  [======|====] 7               ║
║ Middle: [===|=======] 4               ║
║ Lower:  [=|=========] 1               ║
║                                       ║
║ Fairness Mode:                        ║
║ ○ Pure Priority (rich always win)    ║
║ ● Balanced (history penalty)          ║
║ ○ Egalitarian (equal chances)        ║
║                                       ║
║ History Penalty: [=====|=====] 50%   ║
║ (Higher = more fair distribution)     ║
║                                       ║
║ Critical Override Threshold: 15       ║
║ (Ignore class weights below this)     ║
╚═══════════════════════════════════════╝
```

---

## 7. Implementation Checklist

### Phase 1: Core Data Structures (Day 1)
- [ ] Create `dimension_definitions.json` with all 49 fine dimensions mapped to 9 coarse
- [ ] Update `character_traits.json` with fine-level multipliers (49D arrays)
- [ ] Update `fulfillment_vectors.json` for all commodities (49D fine vectors)
- [ ] Create `enablement_vectors.json` with unlock/amplify rules
- [ ] Create `commodity_fatigue_rates.json` with base rates + trait modifiers
- [ ] Update `substitution_rules.json` with distance values

### Phase 2: Character System Refactor (Day 1-2)
- [ ] Refactor `Character.lua` to support all 6 layers
- [ ] Implement `UpdateCurrentCravings()` (accumulation logic)
- [ ] Implement `UpdateSatisfaction()` (lifetime tracker)
- [ ] Implement `CalculateCommodityMultiplier()` (personalized fatigue)
- [ ] Implement `ApplyEnablement()` (unlock new cravings)
- [ ] Implement `CalculatePriority()` (with fairness modes)
- [ ] Add aggregation functions (fine → coarse)

### Phase 3: Allocation Engine Refactor (Day 2)
- [ ] Refactor `AllocationEngine.lua` for fine-grained computation
- [ ] Implement commodity scoring with multipliers
- [ ] Implement substitution boost mechanics
- [ ] Add allocation policy support (class weights, fairness)

### Phase 4: Cache System (Day 2-3)
- [ ] Create `CommodityCache.lua` with hierarchical structure
- [ ] Implement smart invalidation (by dimension/group)
- [ ] Add cache rebuild logic with dirty flags
- [ ] Performance profiling and optimization

### Phase 5: Consequences System (Day 3)
- [ ] Implement individual consequences (productivity, protest)
- [ ] Implement town-level consequences (unrest, riot)
- [ ] Add emigration opportunity system (mocked events)
- [ ] Add riot damage mechanics (inventory + buildings)

### Phase 6: UI Implementation (Day 3-4)
- [ ] Update character detail modal with all 6 sections
- [ ] Implement coarse dimension bars with expand/collapse
- [ ] Add fine dimension heatmap (top 10 + bottom 10)
- [ ] Add commodity fatigue display
- [ ] Add consumption history log
- [ ] Add allocation policy panel (last priority)

### Phase 7: Testing & Balancing (Day 4)
- [ ] Test with 10 characters, 20 commodities
- [ ] Test with 100 characters, 50 commodities
- [ ] Verify cache performance (<5ms allocation)
- [ ] Balance decay rates, fatigue rates, satisfaction gains
- [ ] Test edge cases (starvation, riots, emigration)

---

## 8. Open Questions for Future

1. **Social influence vectors**: Should characters influence each other's cravings?
2. **Learning vectors**: Should consumption patterns shift base cravings over time?
3. **Quality tiers**: How do basic/premium/luxury variants affect fatigue?
4. **Seasonal variation**: Should base cravings shift with seasons/weather?
5. **Cultural drift**: Should town-wide consumption patterns emerge?

---

## Appendix A: Formulas Reference

### Base Cravings Calculation
```lua
baseCraving[dim] = CLASS_BASE[dim] * TRAIT_MULT[dim] * AGE_MOD[dim] * GENDER_MOD[dim]
```

### Current Cravings Accumulation
```lua
currentCravings[dim] += baseCravings[dim] * (deltaTime / 60.0)
```

### Satisfaction Update
```lua
satisfaction[dim] -= 0.5 * (deltaTime / 60.0)  -- Slow decay
if currentCravings[dim] > 40 then
    satisfaction[dim] -= (currentCravings[dim] - 40) * 0.2 * (deltaTime / 60.0)
end
```

### Commodity Multiplier
```lua
fatigue = exp(-consecutiveConsumptions * effectiveFatigueRate)
recovery = min(1.0, cyclesSince * 0.1)
multiplier = max(0.0, fatigue * recovery)
```

### Substitution Boost
```lua
boost = (1.0 - currentMultiplier) * (1.0 - distance) * boostFactor
newMultiplier = min(1.0, currentMultiplier + boost)
```

### Priority Score
```lua
priority = desperationScore * 100 + classWeight * 10
if fairnessMode == "balanced" then
    priority *= (1.0 / (1.0 + recentAllocations * historyWeight))
end
if avgSatisfaction < criticalThreshold then
    priority *= 2.0
end
```

---

**Document Status:** Final Design - Ready for Implementation
**Next Step:** Begin Phase 1 data file creation
