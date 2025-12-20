# Balance Analysis: 500-1000 Citizens

**Created:** 2025-12-18
**Status:** In Progress
**Related Tasks:** [A] Balance Analysis & Tuning

---

## 1. Population Parameters

### Class Distribution (from consumption_mechanics.json)
| Class  | Percentage | @ 500 citizens | @ 1000 citizens |
|--------|-----------|----------------|-----------------|
| Elite  | 10%       | 50             | 100             |
| Upper  | 20%       | 100            | 200             |
| Middle | 40%       | 200            | 400             |
| Lower  | 30%       | 150            | 300             |

---

## 2. Craving Decay Rates (Per 60-second Cycle)

### Biological Craving Decay (Most Critical)
| Class  | Decay/Cycle | Total Daily (6 slots) | Weekly Decay |
|--------|-------------|----------------------|--------------|
| Elite  | 2.0         | 12.0                 | 84.0         |
| Upper  | 2.5         | 15.0                 | 105.0        |
| Middle | 3.0         | 18.0                 | 126.0        |
| Lower  | 3.5         | 21.0                 | 147.0        |

### Average Biological Decay for 500 Citizens
- Elite (50): 50 * 2.0 = 100/cycle
- Upper (100): 100 * 2.5 = 250/cycle
- Middle (200): 200 * 3.0 = 600/cycle
- Lower (150): 150 * 3.5 = 525/cycle
- **Total: 1,475 biological decay points per cycle**

### Average Biological Decay for 1000 Citizens
- **Total: 2,950 biological decay points per cycle**

---

## 3. Commodity Fulfillment Analysis

### Key Biological Commodities
| Commodity  | Biological Fulfillment | Fine Details |
|------------|----------------------|--------------|
| Bread      | 12                   | grain: 15, protein: 2 |
| Meat       | 15                   | protein: 20, grain: 2 |
| Vegetable  | 10                   | produce: 15, hygiene: 2, hydration: 3 |
| Wheat      | 8                    | grain: 12, protein: 1 |
| Medicine   | 30                   | medicine: 50 |
| Cake       | 8                    | grain: 10, produce: 3 |

### Consumption Requirement Calculation
To maintain biological satisfaction at stable levels (replenish decay):

**For 500 citizens (1,475 decay/cycle):**
- Bread: 1,475 / 12 = ~123 units/cycle
- OR Vegetables: 1,475 / 10 = ~148 units/cycle
- OR Mixed: ~60 bread + ~75 vegetables per cycle

**For 1000 citizens (2,950 decay/cycle):**
- Bread: 2,950 / 12 = ~246 units/cycle
- OR Vegetables: 2,950 / 10 = ~295 units/cycle
- OR Mixed: ~120 bread + ~150 vegetables per cycle

---

## 4. Production Rate Analysis

### Current Recipe Production Times & Outputs

| Building | Recipe | Time (sec) | Output | Output/hour |
|----------|--------|------------|--------|-------------|
| Farm | Wheat | 7200 | 100 wheat | 50/hr |
| Farm | Vegetable | 5400 | 80 veg | 53/hr |
| Farm | Fruit | 10800 | 60 fruit | 20/hr |
| Farm | Cotton | 7200 | 80 cotton | 40/hr |
| Bakery | Bread | 180 | 8 bread | 160/hr |
| Bakery | Cake | 480 | 2 cake | 15/hr |
| Restaurant | Meal | 300 | 10 meal | 120/hr |
| Bar | Beer | 7200 | 30 beer | 15/hr |
| Bar | Whiskey | 14400 | 20 whiskey | 5/hr |
| Mine | Iron | 1200 | 100 ore | 300/hr |
| Mine | Gold | 1800 | 50 ore | 100/hr |

### Building Worker Capacity
| Building | Level 0 Stations | Level 1 Stations | Level 2 Stations |
|----------|-----------------|-----------------|-----------------|
| Farm | 2 | 4 | 8 |
| Bakery | 1 | 2 | 4 |
| Restaurant | 2 | 4 | 8 |
| Bar | 2 | 4 | 8 |
| Mine | 2 | 4 | 8 |

---

## 5. Building Requirements Calculation

### Assumptions
- 1 game hour = 60 real seconds (1 cycle)
- 6 time slots per day
- Workers work ~4 time slots per day
- Production efficiency = 1.0 (optimal case)

### For 500 Citizens - Bread-based Economy

**Consumption:** ~123 bread/cycle = ~740 bread/game-day

**Production:**
- 1 Bakery (Level 0, 1 station) = 160 bread/hr = 160 bread/cycle
- Need: 740 / 160 = ~4.6 stations → **3 Level-0 Bakeries OR 1 Level-1 + 1 Level-0**

**Wheat Supply for Bakeries:**
- 8 bread uses 10 wheat → 740 bread needs 925 wheat/day
- 1 Farm (Level 0) produces ~50 wheat/hr in work slots
- Working 4 slots = 200 wheat/day
- Need: 925 / 200 = ~4.6 farms → **5 Wheat Farms (Level 0)**

### For 500 Citizens - Summary Building Requirements

| Building Type | Quantity | Workers | Purpose |
|--------------|----------|---------|---------|
| Wheat Farm | 5 | 10 | Raw grain |
| Vegetable Farm | 2 | 4 | Vegetables/variety |
| Bakery | 3 | 3 | Bread production |
| Restaurant | 2 | 4 | Meal preparation |
| Bar | 1 | 2 | Social/vice needs |
| Housing | 100+ | - | 5 people/house |
| **Total Production Workers** | **~23** | - | 4.6% of population |

### For 1000 Citizens - Summary Building Requirements

| Building Type | Quantity | Workers | Purpose |
|--------------|----------|---------|---------|
| Wheat Farm | 10 | 20 | Raw grain |
| Vegetable Farm | 4 | 8 | Vegetables/variety |
| Bakery | 6 | 6 | Bread production |
| Restaurant | 4 | 8 | Meal preparation |
| Bar | 2 | 4 | Social/vice needs |
| Housing | 200+ | - | 5 people/house |
| **Total Production Workers** | **~46** | - | 4.6% of population |

---

## 6. Balance Issues Identified

### Issue 1: Production is VERY Fast
- Current system: 160 bread/hour per bakery station
- This feels too fast - 1 bakery can feed ~650 people
- **Recommendation:** Slow production by 3-5x OR increase consumption

### Issue 2: Worker Efficiency is High
- Only ~5% of population needs to work in food production
- Leaves 95% for other activities (or unemployed)
- **This might be intentional** - allows diverse economy

### Issue 3: Missing Production Chains
For Indian dish starter towns, we need these recipes:
- **Samosa Kitchen:** potato + flour + oil → samosa
- **Poha Kitchen:** flattened rice + onion + oil → poha
- **Sweet Shop:** sugar + flour → jalebi

### Issue 4: Craving Dimension Coverage
Current recipes primarily cover **Biological** cravings.
Need more variety for:
- Touch/Comfort (clothing, furniture)
- Psychological (books, art, entertainment)
- Social Status (luxury items)
- Social Connection (bars, gathering places)
- Vice (alcohol, sweets)

---

## 7. Recommended Balance Adjustments

### Option A: Increase Production Time (Slower Economy)
```json
// Proposed changes to building_recipes.json
{
  "bakery": {
    "productionTime": 180 → 600  // 10 min instead of 3 min
    // Result: 48 bread/hr instead of 160
  },
  "farm_wheat": {
    "productionTime": 7200 → 14400  // 4 hours instead of 2
    // Result: 25 wheat/hr instead of 50
  }
}
```

### Option B: Increase Consumption (Hungrier Citizens)
```json
// Proposed changes to consumption_mechanics.json
{
  "cravingDecayRates": {
    "biological": {
      "elite": 2.0 → 4.0,
      "upper": 2.5 → 5.0,
      "middle": 3.0 → 6.0,
      "lower": 3.5 → 7.0
    }
  }
}
```

### Option C: Hybrid Approach (Recommended)
1. Increase production time by 2x
2. Increase consumption by 1.5x
3. Add variety requirements (diminishing returns force multiple food types)

---

## 8. Indian Dish Production Chains

### Samosa Town Chain
```
Potato Farm (new) → Potato
Wheat Farm → Wheat → Mill → Flour
Groundnut Farm (new) → Groundnut → Oil Press → Oil

Samosa Kitchen: 3 potato + 2 flour + 1 oil → 5 samosa (300 sec)
```

### Poha Town Chain
```
Rice Paddy (new) → Rice → Rice Mill → Flattened Rice
Onion Farm (new) → Onion
Groundnut Farm → Groundnut → Oil Press → Oil

Poha Kitchen: 5 flattened_rice + 2 onion + 1 oil → 6 poha (240 sec)
```

### Jalebi Town Chain
```
Sugarcane Farm (new) → Sugarcane → Sugar Mill → Sugar
Wheat Farm → Wheat → Mill → Flour

Sweet Shop: 3 sugar + 2 flour → 4 jalebi (360 sec)
```

### Mining Town Chain (Existing)
```
Iron Mine → Iron Ore → Forge → Iron Tools
```

---

## 9. Starting Town Building Ratios

### Samosa Town (12 citizens)
| Building | Count | Workers | Notes |
|----------|-------|---------|-------|
| Potato Farm | 1 | 2 | Main ingredient |
| Wheat Farm | 1 | 2 | For flour |
| Groundnut Farm | 1 | 1 | For oil |
| Mill | 1 | 1 | Wheat → Flour |
| Oil Press | 1 | 1 | Groundnut → Oil |
| Samosa Kitchen | 1 | 2 | Final product |
| Small Houses | 3 | - | 4 people each |
| **Total** | **9 buildings** | **9 workers** | 75% employment |

### Starting Resources (20 cycles buffer)
- Gold: 500
- Wheat: 200
- Potato: 100
- Groundnut: 50
- Flour: 50
- Oil: 25
- Samosa: 50 (emergency food)
- Wood: 100 (repairs)
- Stone: 50 (repairs)

---

## 10. Next Steps

1. [ ] **Verify current production rates** match what's in building_recipes.json
2. [ ] **Add missing recipes** for Indian dishes
3. [ ] **Add missing commodities** (potato, groundnut, oil, samosa, poha, jalebi, etc.)
4. [ ] **Add fulfillment vectors** for new commodities
5. [ ] **Test 100-citizen town** for 50 cycles
6. [ ] **Adjust rates** based on testing
7. [ ] **Document final balance values**

---

## 11. Production Efficiency Summary Table

| Citizens | Biological Decay/cycle | Bread Needed/cycle | Bakeries Needed | Farms Needed |
|----------|----------------------|-------------------|-----------------|--------------|
| 100 | 295 | ~25 | 1 (Level 0) | 2 |
| 250 | 738 | ~62 | 1 (Level 1) | 3 |
| 500 | 1,475 | ~123 | 3 (Level 0) | 5 |
| 750 | 2,213 | ~185 | 2 (Level 1) | 8 |
| 1000 | 2,950 | ~246 | 6 (Level 0) | 10 |

---

*Document created as part of Task [A] Balance Analysis & Tuning*
