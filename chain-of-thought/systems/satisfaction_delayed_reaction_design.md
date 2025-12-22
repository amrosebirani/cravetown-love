# Satisfaction Delayed Reaction System Design

**Created:** 2025-12-20
**Status:** Design Discussion
**Related Documents:**
- [Consumption System Architecture v2](consumption_system_architecture_v2.md)
- [Balance Analysis](../analysis/balance_analysis_500_1000_citizens.md)

---

## 1. Problem Statement

### Current Issues
1. **Missing `ApplySatisfactionGain` function** - The design document specifies this but it's not implemented in `CharacterV2.lua`
2. **Satisfaction is too reactive** - Currently tracks like a "fast" metric when it should represent long-term happiness (weeks/months)
3. **No delayed reaction** - Satisfaction changes immediately with each cycle, not reflecting psychological reality

### Design Goal
Create a satisfaction system where:
- **Short-term fluctuations don't immediately affect long-term happiness**
- **Sustained unmet needs lead to exponential satisfaction decay**
- **Sustained fulfilled needs lead to logarithmic satisfaction gain**
- **Asymmetric curves reflect psychological reality** (negativity bias, trust builds slowly)

---

## 2. Core Concept: Streak-Based Delayed Reaction

### 2.1 The Streak Tracker
Each character tracks consecutive days of met/unmet cravings per dimension:

```lua
Character.cravingStreaks = {
    biological_nutrition_grain = {
        type = "met",      -- "met" or "unmet"
        days = 5,          -- consecutive days in this state
        lastUpdated = 142  -- cycle number
    },
    psychological_entertainment = {
        type = "unmet",
        days = 3,
        lastUpdated = 142
    }
    -- ... all 49 fine dimensions (or 9 coarse dimensions)
}
```

### 2.2 Buffer Threshold (N)
- **N = threshold days before satisfaction starts changing**
- Same N for all dimensions (simplicity)
- Same N for all classes (class differences already in base cravings)
- **N can vary by game difficulty** (key balancing lever)

| Difficulty | N (buffer days) | Decay Speed | Gain Speed |
|------------|-----------------|-------------|------------|
| Easy       | 7 days          | Slow        | Fast       |
| Normal     | 5 days          | Medium      | Medium     |
| Hard       | 3 days          | Fast        | Slow       |
| Brutal     | 2 days          | Very Fast   | Very Slow  |

### 2.3 Asymmetric Response Curves

**Decay Formula (Exponential - things fall apart fast):**
```
decay = -min(30, exp(max(0, (streak_days - N) * 0.08)))
```

Where:
- `streak_days` = consecutive days unmet
- `N` = buffer threshold
- Result capped at -30 per update to prevent instant collapse

**Gain Formula (Logarithmic - trust builds slowly):**
```
gain = min(10, 20 * log(max(1, (streak_days - N) * 0.5)))
```

Where:
- `streak_days` = consecutive days met
- `N` = buffer threshold
- Result capped at +10 per update for gradual growth

### 2.4 Visual Representation

```
Satisfaction Change vs Streak Days (N=5)

       |
   +10 |                          ____-------- (gain cap)
       |                     ___--
       |                 __--
  Gain |            ___--
       |        __--
       |    __--
    0  |----                   N=5
       |    __
       |        __
 Decay |            ___
       |                 ___
       |                      ____
   -30 |                           _______ (decay cap)
       |________________________________
       0   2   4   6   8   10  12  14  16
                Streak Days
```

---

## 3. Met/Unmet Definition

### 3.1 Two Candidate Approaches

**Option A: Threshold-Based**
```lua
-- "Met" if current craving is below threshold
local threshold = maxCraving * 0.5  -- 50% of max
local isMet = currentCraving < threshold
```

**Option B: Flow-Based (Relative to Decay)**
```lua
-- "Met" if fulfillment exceeded decay for the day
local dailyDecay = baseCraving * cyclesPerDay
local dailyFulfillment = totalFulfillmentToday
local isMet = dailyFulfillment >= dailyDecay
```

### 3.2 Recommended: Hybrid Approach

Combine both for robustness:

```lua
function Character:IsCravingMet(dimension)
    local currentCraving = self.currentCravings[dimension]
    local baseCraving = self.baseCravings[dimension]
    local maxCraving = baseCraving * 50  -- max accumulation

    -- Threshold check: craving is low enough
    local thresholdMet = currentCraving < (maxCraving * 0.5)

    -- Flow check: fulfilled more than decayed today
    local dailyDecay = baseCraving * CYCLES_PER_DAY
    local todayFulfillment = self.todayFulfillment[dimension] or 0
    local flowMet = todayFulfillment >= dailyDecay

    -- Met if EITHER condition is true (generous interpretation)
    -- Or use AND for stricter interpretation
    return thresholdMet or flowMet
end
```

### 3.3 Daily Fulfillment Tracking

Need to track fulfillment per dimension per day:

```lua
Character.todayFulfillment = {
    biological_nutrition_grain = 15.5,  -- points fulfilled today
    psychological_entertainment = 0,     -- nothing fulfilled
    -- ... all dimensions
}

-- Reset at start of each game day
function Character:ResetDailyFulfillment()
    for dim, _ in pairs(self.todayFulfillment) do
        self.todayFulfillment[dim] = 0
    end
end

-- Called when consuming commodity
function Character:RecordFulfillment(dimension, points)
    self.todayFulfillment[dimension] =
        (self.todayFulfillment[dimension] or 0) + points
end
```

---

## 4. Streak Update Logic

### 4.1 End of Day Processing

```lua
function Character:UpdateStreaksEndOfDay(currentDay)
    for dimension, streak in pairs(self.cravingStreaks) do
        local isMet = self:IsCravingMet(dimension)

        if isMet then
            if streak.type == "met" then
                -- Continue met streak
                streak.days = streak.days + 1
            else
                -- Switch from unmet to met
                streak.type = "met"
                streak.days = 1
            end
        else
            if streak.type == "unmet" then
                -- Continue unmet streak
                streak.days = streak.days + 1
            else
                -- Switch from met to unmet
                streak.type = "unmet"
                streak.days = 1
            end
        end

        streak.lastUpdated = currentDay
    end

    -- Reset daily fulfillment tracking
    self:ResetDailyFulfillment()
end
```

### 4.2 Satisfaction Update (Daily, Not Per-Cycle)

```lua
function Character:UpdateSatisfactionDaily(difficultySettings)
    local N = difficultySettings.bufferDays  -- e.g., 5 for normal

    for dimension, streak in pairs(self.cravingStreaks) do
        local streakDays = streak.days
        local change = 0

        if streak.type == "unmet" and streakDays > N then
            -- Exponential decay after buffer
            local x = streakDays - N
            change = -math.min(30, math.exp(x * 0.08))

        elseif streak.type == "met" and streakDays > N then
            -- Logarithmic gain after buffer
            local x = streakDays - N
            change = math.min(10, 20 * math.log(x * 0.5 + 1))
        end

        -- Apply change
        if change ~= 0 then
            self.satisfaction[dimension] = math.max(-100,
                math.min(300, self.satisfaction[dimension] + change))
        end
    end

    -- Recalculate coarse aggregates
    self:RecalculateSatisfactionCoarse()
end
```

---

## 5. Difficulty Scaling

### 5.1 Difficulty Parameters

```lua
DIFFICULTY_SETTINGS = {
    easy = {
        bufferDays = 7,
        decayMultiplier = 0.5,   -- slower decay
        gainMultiplier = 1.5,    -- faster gain
        decayExponent = 0.06,    -- gentler curve
        gainLogScale = 25        -- more generous
    },
    normal = {
        bufferDays = 5,
        decayMultiplier = 1.0,
        gainMultiplier = 1.0,
        decayExponent = 0.08,
        gainLogScale = 20
    },
    hard = {
        bufferDays = 3,
        decayMultiplier = 1.5,   -- faster decay
        gainMultiplier = 0.7,    -- slower gain
        decayExponent = 0.10,    -- steeper curve
        gainLogScale = 15        -- stingier
    },
    brutal = {
        bufferDays = 2,
        decayMultiplier = 2.0,
        gainMultiplier = 0.5,
        decayExponent = 0.12,
        gainLogScale = 10
    }
}
```

### 5.2 Formula with Difficulty

```lua
function Character:CalculateSatisfactionChange(streak, settings)
    local N = settings.bufferDays
    local streakDays = streak.days

    if streak.type == "unmet" and streakDays > N then
        local x = streakDays - N
        local baseDecay = math.exp(x * settings.decayExponent)
        return -math.min(30, baseDecay * settings.decayMultiplier)

    elseif streak.type == "met" and streakDays > N then
        local x = streakDays - N
        local baseGain = settings.gainLogScale * math.log(x * 0.5 + 1)
        return math.min(10, baseGain * settings.gainMultiplier)
    end

    return 0  -- Within buffer period
end
```

---

## 6. Integration with Existing System

### 6.1 Dimension Counts (Current)
- **10 coarse dimensions**: biological, safety, touch, psychological, social_status, social_connection, exotic_goods, shiny_objects, vice, utility
- **66 fine dimensions**: indices 0-65, mapped to coarse parents
- Source: `data/alpha/craving_system/dimension_definitions.json`

### 6.2 What Changes

| Component | Current | New |
|-----------|---------|-----|
| Satisfaction update frequency | Per cycle (60 sec) | Per day (6 cycles) |
| Decay trigger | Immediate | After N days unmet |
| Gain mechanism | None implemented | After N days met |
| Tracking granularity | Per dimension | Per dimension + streak (66D) |

### 6.3 New Data Structures

```lua
-- Add to Character
Character.cravingStreaks = {}      -- dimension -> {type, days, lastUpdated}
Character.todayFulfillment = {}    -- dimension -> points fulfilled today
Character.lastDayProcessed = 0     -- track which day was last processed
```

### 6.4 Hook Points

1. **On Consumption** (`FulfillCraving`):
   - Call `RecordFulfillment(dimension, points)`

2. **On Day Change** (new hook needed):
   - Call `UpdateStreaksEndOfDay(currentDay)`
   - Call `UpdateSatisfactionDaily(difficultySettings)`
   - Call `ResetDailyFulfillment()`

3. **Remove from per-cycle update**:
   - Remove satisfaction decay from `UpdateSatisfaction()`
   - Keep only `UpdateCurrentCravings()` per cycle

---

## 7. Example Scenario

### Character: John Smith (Middle Class, Normal Difficulty)
- N = 5 buffer days
- Tracking: `biological_nutrition_grain`

```
Day 1: Craving met (ate bread)
       streak = {type: "met", days: 1}
       satisfaction change = 0 (within buffer)

Day 2: Craving met
       streak = {type: "met", days: 2}
       satisfaction change = 0

Day 3: Craving met
       streak = {type: "met", days: 3}
       satisfaction change = 0

Day 4: Craving met
       streak = {type: "met", days: 4}
       satisfaction change = 0

Day 5: Craving met
       streak = {type: "met", days: 5}
       satisfaction change = 0 (exactly at buffer)

Day 6: Craving met
       streak = {type: "met", days: 6}
       x = 6 - 5 = 1
       gain = min(10, 20 * log(1 * 0.5 + 1)) = min(10, 20 * 0.405) = +8.1

Day 7: Craving NOT met (no bread available)
       streak = {type: "unmet", days: 1}  // RESET!
       satisfaction change = 0 (within buffer)

Day 8: Craving NOT met
       streak = {type: "unmet", days: 2}
       satisfaction change = 0

... (days 9-11 also unmet)

Day 12: Craving NOT met
        streak = {type: "unmet", days: 6}
        x = 6 - 5 = 1
        decay = -min(30, exp(1 * 0.08)) = -min(30, 1.083) = -1.08

Day 15: Craving NOT met
        streak = {type: "unmet", days: 9}
        x = 9 - 5 = 4
        decay = -min(30, exp(4 * 0.08)) = -min(30, 1.377) = -1.38

Day 20: Craving NOT met
        streak = {type: "unmet", days: 14}
        x = 14 - 5 = 9
        decay = -min(30, exp(9 * 0.08)) = -min(30, 2.054) = -2.05

Day 30: Craving NOT met
        streak = {type: "unmet", days: 24}
        x = 24 - 5 = 19
        decay = -min(30, exp(19 * 0.08)) = -min(30, 4.57) = -4.57
```

Notice how:
- Gain builds slowly even after buffer (logarithmic)
- One bad day resets the met streak
- Decay accelerates exponentially after buffer
- Caps prevent instant collapse/ecstasy

---

## 8. Open Questions

1. ~~**Coarse vs Fine granularity for streaks?**~~
   - **Decision: Fine-grained (66D) streak tracking**
   - More precise tracking per fine dimension
   - Matches the 66 fine dimensions defined in `dimension_definitions.json`
   - 10 coarse dimensions aggregate from 66 fine dimensions

2. **Should breaking a streak partially preserve it?**
   - Current: One bad day resets to 0
   - Alternative: Decay the streak by 1-2 days instead of full reset
   - **Recommendation**: Keep simple reset for now, can tune later

3. **What about the first N days of a new game?**
   - Characters start with no streak history
   - **Recommendation**: Initialize with small random streaks (1-3 days) to avoid everyone hitting buffer simultaneously

---

## 9. Implementation Checklist

- [x] Add `cravingStreaks` data structure to Character (CharacterV3.lua:267-282)
- [x] Add `todayFulfillment` tracking to Character (CharacterV3.lua:268)
- [x] Implement `IsCravingMet()` function (hybrid approach) (CharacterV3.lua:676-694)
- [x] Implement `UpdateStreaksEndOfDay()` function (CharacterV3.lua:697-744)
- [x] Implement `UpdateSatisfactionDaily()` with new formulas (CharacterV3.lua:769-788)
- [x] Add difficulty settings to game config (CharacterV3.lua:20-50)
- [x] Hook day-change event to trigger daily updates (AlphaWorld.lua:580, 625-656)
- [ ] Remove per-cycle satisfaction decay from `UpdateSatisfaction()` (OPTIONAL - keep for now as fallback)
- [x] Add `RecordFulfillment()` call to consumption logic (CharacterV3.lua:1027-1028)
- [x] Initialize streaks for new characters (CharacterV3.lua:272-282)
- [ ] Add streak visualization to debug panel (TODO: separate task)
- [ ] Test with different difficulty settings (TODO: manual testing)

---

*Document created: 2025-12-20*
*Status: IMPLEMENTED - Core system complete, pending debug visualization and testing*
