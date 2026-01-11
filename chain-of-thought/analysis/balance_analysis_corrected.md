# Corrected Balance Analysis: 1000 Citizens

**Created:** 2025-12-20
**Status:** Corrected Analysis (v2 - with time slots)
**Previous Version:** balance_analysis_500_1000_citizens.md (FLAWED - wrong time units)

---

## Critical Corrections from Previous Analysis

| Issue | Previous (Wrong) | Corrected |
|-------|-----------------|-----------|
| Production time unit | Assumed game time | **Real seconds** |
| Consumption calculation | Used decay rates directly | **baseCravings × time ratio** |
| Time per game day | Not considered | **300 real seconds (5 min)** |
| Time slot system | Not factored | **Cravings only accumulate in active slots** |

---

## 1. Time System Summary

```
Real Time          Game Time (Normal Speed)
-----------        ------------------------
60 seconds    =    1 cycle
300 seconds   =    1 game day (6 cycles)
5 minutes     =    1 game day
50 seconds    =    1 time slot (6 slots per day)
2 hours       =    24 game days
```

**Key insight:** Production times are in REAL SECONDS, not game time!

### Time Slots (from craving_slots.json)
```
early_morning  →  50 real seconds
morning        →  50 real seconds
afternoon      →  50 real seconds
evening        →  50 real seconds
night          →  50 real seconds
late_night     →  50 real seconds
─────────────────────────────────
Total          →  300 real seconds = 1 game day
```

**Critical:** Cravings only accumulate during their designated time slots!

---

## 2. Craving Accumulation Formula

From `CharacterV3.lua` line 498-542:

```lua
local cycleTime = 60.0  -- 60 seconds per cycle
local ratio = deltaTime / cycleTime
-- Only accumulates if this dimension is active in current slot
if activeIndices[i] then
    self.currentCravings[i] = self.currentCravings[i] + (baseRate * ratio)
end
```

### Slot-Aware Accumulation

Each craving dimension has designated active slots (from `craving_slots.json`):

| Dimension | Active Slots | Slots/Day | Real Seconds |
|-----------|--------------|-----------|--------------|
| biological_nutrition_grain | early_morning, afternoon, evening | 3 | 150s |
| biological_nutrition_protein | afternoon, evening | 2 | 100s |
| biological_nutrition_produce | morning, afternoon, evening | 3 | 150s |
| biological_hydration | early_morning, morning, afternoon, evening, night | 5 | 250s |
| vice_alcohol_beer | evening, night | 2 | 100s |

**Per game day accumulation = baseCravings × (activeSlots × 50 / 60)**

For grain (3 slots): baseCravings × (150 / 60) = **baseCravings × 2.5**

---

## 3. Base Cravings by Class (from character_classes.json)

### Fine Dimension Index 0: `biological_nutrition_grain` (3 slots → ×2.5)

| Class | baseCravings[0] | Per Game Day (×2.5) |
|-------|-----------------|---------------------|
| Elite | 4.9 | 12.25 |
| Upper | 3.5 | 8.75 |
| Middle | 4.0 | 10.0 |
| Lower | 4.5 | 11.25 |

### Fine Dimension Index 1: `biological_nutrition_protein` (2 slots → ×1.67)

| Class | baseCravings[1] | Per Game Day (×1.67) |
|-------|-----------------|----------------------|
| Elite | 5.0 | 8.35 |
| Upper | 3.0 | 5.01 |
| Middle | 3.5 | 5.85 |
| Lower | 4.0 | 6.68 |

### Fine Dimension Index 2: `biological_nutrition_produce` (3 slots → ×2.5)

| Class | baseCravings[2] | Per Game Day (×2.5) |
|-------|-----------------|---------------------|
| Elite | 4.9 | 12.25 |
| Upper | 3.5 | 8.75 |
| Middle | 4.0 | 10.0 |
| Lower | 4.5 | 11.25 |

---

## 4. Commodity Fulfillment Vectors (from fulfillment_vectors.json)

| Commodity | Grain (dim 0) | Protein (dim 1) | Produce (dim 2) |
|-----------|---------------|-----------------|-----------------|
| Wheat | 12 | 1 | 0 |
| Bread | 15 | 2 | 0 |
| Meat | 2 | 20 | 0 |
| Vegetable | 0 | 0 | 15 |
| Beer | 4 | 0 | 0 |

---

## 5. Bread Consumption Calculation (1000 Citizens)

### Step 1: Grain craving per citizen per day (with 3 active slots)

| Class | % Population | Count | Grain/day (×2.5) | Total Grain Craving |
|-------|-------------|-------|------------------|---------------------|
| Elite | 10% | 100 | 12.25 | 1,225 |
| Upper | 20% | 200 | 8.75 | 1,750 |
| Middle | 40% | 400 | 10.0 | 4,000 |
| Lower | 30% | 300 | 11.25 | 3,375 |
| **Total** | 100% | **1000** | | **10,350 grain points/day** |

### Step 2: Bread needed to fulfill grain craving

- 1 bread = 15 grain fulfillment points
- **Bread needed = 10,350 / 15 = 690 bread per game day**

---

## 6. Bread Production Calculation

### Recipe: Bread Baking
```
Production Time: 180 real seconds (3 minutes)
Input: 10 wheat
Output: 8 bread
```

### Per Bakery Station per Game Day
```
Game day = 300 real seconds
Production cycles per day = 300 / 180 = 1.67 cycles
Bread per station per day = 1.67 × 8 = 13.3 bread
```

### Bakery Stations Needed for 1000 Citizens
```
Bread needed: 690 per day
Bread per station: 13.3 per day
Stations needed: 690 / 13.3 = 52 stations
```

### Building Configuration Options

| Building Level | Stations | Buildings Needed |
|---------------|----------|------------------|
| Level 0 | 1 station | 52 bakeries |
| Level 1 | 2 stations | 26 bakeries |
| Level 2 | 4 stations | 13 bakeries |

---

## 7. Wheat Production Calculation

### Wheat Consumption by Bakeries
```
52 stations × 1.67 cycles/day × 10 wheat/cycle = 868 wheat per day
```

### Recipe: Wheat Farming
```
Production Time: 7200 real seconds (2 hours = 120 minutes)
Input: 5 wheat_seed
Output: 100 wheat
```

### Per Farm Station per Game Day
```
Game day = 300 real seconds
Production cycles per day = 300 / 7200 = 0.0417 cycles
Wheat per station per day = 0.0417 × 100 = 4.17 wheat
```

**PROBLEM: Farms are still slow but more manageable with slot-adjusted numbers!**

### Farm Stations Needed for 1000 Citizens
```
Wheat needed: 868 per day
Wheat per station: 4.17 per day
Farm stations needed: 868 / 4.17 = 208 farm stations
```

### Building Configuration

| Building Level | Stations | Buildings Needed |
|---------------|----------|------------------|
| Level 0 | 2 stations | 104 farms |
| Level 1 | 4 stations | 52 farms |
| Level 2 | 8 stations | 26 farms |

---

## 8. Complete Supply Chain Summary (1000 Citizens - Grain Only)

| Building Type | Level 2 Count | Stations | Workers (est.) |
|--------------|---------------|----------|----------------|
| Wheat Farm | 26 | 208 | 208 |
| Bakery | 13 | 52 | 52 |
| **Total** | **39 buildings** | **260 stations** | **260 workers** |

**26% of population working just for grain!** (down from 52% before slot adjustment)

---

## 9. Multi-Craving Analysis (Slot-Adjusted)

Citizens have 66 fine dimensions of cravings. Let's look at the key biological ones:

### Daily Craving Accumulation (1000 Citizens, Weighted Average, Slot-Adjusted)

| Dimension | Avg baseCraving | Slots | Multiplier | Daily | 1000 Citizens |
|-----------|-----------------|-------|------------|-------|---------------|
| Grain (0) | 4.07 | 3 | ×2.5 | 10.18 | 10,175 |
| Protein (1) | 3.68 | 2 | ×1.67 | 6.15 | 6,146 |
| Produce (2) | 4.07 | 3 | ×2.5 | 10.18 | 10,175 |
| Hydration (3) | 3.87 | 5 | ×4.17 | 16.14 | 16,138 |
| Medicine (4) | 2.75 | 2 | ×1.67 | 4.59 | 4,593 |
| Hygiene (5) | 4.15 | 2 | ×1.67 | 6.93 | 6,931 |
| Rest (6) | 3.90 | 1 | ×0.83 | 3.24 | 3,237 |
| Stimulation (7) | 2.88 | 2 | ×1.67 | 4.81 | 4,810 |

### Commodities Needed per Day (1000 Citizens, Slot-Adjusted)

| Need | Commodity | Fulfillment | Daily Craving | Units Needed/Day |
|------|-----------|-------------|---------------|------------------|
| Grain | Bread | 15 | 10,175 | 678 |
| Protein | Meat | 20 | 6,146 | 307 |
| Produce | Vegetable | 15 | 10,175 | 678 |
| Hydration | Water/Beer | 5 | 16,138 | 3,228 |

---

## 10. The Scaling Problem

### Current Production Times are TOO SLOW for Large Populations

| Recipe | Real Time | Game Days | Issue |
|--------|-----------|-----------|-------|
| Wheat | 2 hours | 24 days | Way too slow |
| Vegetable | 1.5 hours | 18 days | Too slow |
| Beer | 2 hours | 24 days | Too slow |
| Bread | 3 min | 0.6 days | Reasonable |

### Options to Fix

**Option A: Speed up farm production (5x faster)**
```
Current: 7200 sec → 100 wheat
Proposed: 1440 sec → 100 wheat (24 min real time)

Result: 20.8 wheat per station per day
Farms needed: 868 / 20.8 = 42 farm stations (vs 208)
```

**Option B: Increase farm output (5x more)**
```
Current: 7200 sec → 100 wheat
Proposed: 7200 sec → 500 wheat

Result: 20.8 wheat per station per day
Same reduction in farms needed
```

**Option C: Reduce craving accumulation rate**
```
Current: baseCravings[0] = 4.0 (middle class)
Proposed: baseCravings[0] = 0.8

Result: 5x less bread needed
Farms needed: 42 farm stations
```

**Option D: Increase commodity fulfillment**
```
Current: 1 bread = 15 grain points
Proposed: 1 bread = 75 grain points

Result: 5x less bread needed
```

---

## 11. Recommended Balance (Option A + tweaks)

### Proposed Production Time Changes

| Recipe | Current | Proposed | Speedup |
|--------|---------|----------|---------|
| Wheat Farming | 7200s | 1440s | 5x |
| Vegetable Farming | 5400s | 1080s | 5x |
| Fruit Farming | 10800s | 2160s | 5x |
| Cotton Farming | 7200s | 1440s | 5x |
| Beer Brewing | 7200s | 2400s | 3x |
| Whiskey Distilling | 14400s | 4800s | 3x |
| Iron Mining | 1200s | 600s | 2x |
| Gold Mining | 1800s | 900s | 2x |

### With 5x Farm Speed: Buildings for 1000 Citizens

| Building Type | Level 2 Count | Stations | Workers |
|--------------|---------------|----------|---------|
| Wheat Farm | 6 | 42 | 42 |
| Vegetable Farm | 5 | 34 | 34 |
| Bakery | 13 | 52 | 52 |
| Restaurant | 10 | 40 | 40 |
| **Total Food** | **34 buildings** | **168 stations** | **168 workers** |

**17% of population in food production** - much more reasonable!

---

## 12. Worker Capacity Check

From `building_types.json`:

| Building | Level 0 | Level 1 | Level 2 |
|----------|---------|---------|---------|
| Farm | 2 workers | 4 workers | 8 workers |
| Bakery | 1 worker | 2 workers | 4 workers |
| Restaurant | 2 workers | 4 workers | 8 workers |

Workers needed for 1000 citizens (with 5x farm speed):
- Wheat Farms: 6 buildings × 8 workers = 48
- Vegetable Farms: 5 buildings × 8 workers = 40
- Bakeries: 13 buildings × 4 workers = 52
- Restaurants: 10 buildings × 8 workers = 80
- **Total food workers: 220 (22% of population)**

Add housing, services, mining, textiles: ~40-50% employment rate seems reasonable.

---

## 13. Starter Town Calculations (12 Citizens)

### Scaling down from 1000 to 12 citizens (1.2%)

With slot-adjusted consumption for 12 citizens:

| Need | Daily Points (12 citizens) | Commodity | Fulfillment | Units/Day |
|------|---------------------------|-----------|-------------|-----------|
| Grain | 10,350 × 0.012 = 124 pts | Bread | 15 | 8.3 bread |
| Protein | 6,146 × 0.012 = 74 pts | Meat | 20 | 3.7 meat |
| Produce | 10,175 × 0.012 = 122 pts | Vegetable | 15 | 8.1 veg |

### Production Needed (with 5x farm speed)

| Recipe | Time (5x) | Output | Per Station/Day | Stations Needed |
|--------|-----------|--------|-----------------|-----------------|
| Wheat | 1440s | 100 | 20.8 wheat | 1 (makes 16.6 bread worth) |
| Bread | 180s | 8 | 13.3 bread | 1 (makes 13.3 bread) |
| Vegetable | 1080s | 80 | 22.2 veg | 1 (makes 22.2 veg) |

### Samosa Town Starter (12 Citizens)
With corrected 5x farm speed:

| Building | Level | Workers | Daily Output |
|----------|-------|---------|--------------|
| Potato Farm | 0 | 2 | ~21 potato |
| Wheat Farm | 0 | 2 | ~21 wheat |
| Groundnut Farm | 0 | 1 | ~10 groundnut |
| Mill | 0 | 1 | flour |
| Oil Press | 0 | 1 | oil |
| Samosa Kitchen | 0 | 2 | samosas |
| Houses | - | - | 3 small houses |
| **Total** | | **9 workers** | |

**75% employment rate for starter town** - tight but manageable

---

## 14. Action Items

1. [ ] **Reduce farm production times by 5x** in `building_recipes.json`
2. [ ] **Reduce brewing/distilling times by 3x**
3. [ ] **Reduce mining times by 2x**
4. [ ] **Add missing Indian dish recipes** (samosa, poha, jalebi)
5. [ ] **Add missing commodities** (potato, groundnut, flattened_rice, etc.)
6. [ ] **Add fulfillment vectors** for new commodities
7. [ ] **Test with 100 citizens** to verify balance
8. [ ] **Adjust as needed** based on playtest feedback

---

## 15. Summary Comparison

| Metric | Original (Wrong) | Corrected (Slot-Adjusted) |
|--------|-----------------|---------------------------|
| Bakeries for 1000 citizens | 6 | **13 (Level 2)** |
| Farms for 1000 citizens | 10 | **26 (Level 2)** or 6 with 5x speed |
| Workers in food production | 5% | **17-22%** (with 5x farm speed) |
| Farm production time | 2 game hours | **2 REAL hours = 24 game days** |
| Bread needed per day | ~246 | **690** (slot-adjusted) |
| Grain craving multiplier | ×5 | **×2.5** (3 active slots) |

---

*Document created: 2025-12-20*
*This supersedes the previous balance_analysis_500_1000_citizens.md*
