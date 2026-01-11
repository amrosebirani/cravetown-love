# Biological Craving Balance Analysis (1000 Citizens)

**Created:** 2025-12-20
**Status:** Complete Analysis
**Purpose:** Determine production requirements for all biological cravings with 2-3 commodity varieties each

---

## 1. Biological Fine Dimensions Summary

There are **14 biological fine dimensions** (indices 0-7, 57, 60-63):

| Index | ID | Name | Slots | Multiplier |
|-------|-----|------|-------|------------|
| 0 | biological_nutrition_grain | Grain Nutrition | 3 (early_morning, afternoon, evening) | ×2.5 |
| 1 | biological_nutrition_protein | Protein Nutrition | 2 (afternoon, evening) | ×1.67 |
| 2 | biological_nutrition_produce | Produce Nutrition | 3 (morning, afternoon, evening) | ×2.5 |
| 3 | biological_hydration | Hydration | 5 (early_morning, morning, afternoon, evening, night) | ×4.17 |
| 4 | biological_health_medicine | Medicine | 2 (morning, evening) | ×1.67 |
| 5 | biological_health_hygiene | Hygiene | 2 (early_morning, night) | ×1.67 |
| 6 | biological_energy_rest | Rest Quality | 1 (late_night) | ×0.83 |
| 7 | biological_energy_stimulation | Energy Stimulation | 2 (early_morning, afternoon) | ×1.67 |
| 57 | biological_nutrition_fat | Fat Nutrition | 2 (early_morning, afternoon) | ×1.67 |
| 60 | biological_taste_spicy | Spicy Taste | N/A (assume 2) | ×1.67 |
| 61 | biological_taste_crunchy | Crunchy Taste | N/A (assume 2) | ×1.67 |
| 62 | biological_taste_wholesome | Wholesome Taste | N/A (assume 2) | ×1.67 |
| 63 | biological_fragrance_exotic | Exotic Fragrance | 3 (night, late_night, early_morning) | ×2.5 |

**Note:** Multiplier = (slots × 50 seconds) / 60 seconds per cycle

---

## 2. Population Distribution (1000 Citizens)

| Class | % | Count | Notes |
|-------|---|-------|-------|
| Elite | 10% | 100 | Highest cravings, picky about quality |
| Upper | 20% | 200 | Moderate-high cravings |
| Middle | 40% | 400 | Balanced cravings |
| Lower | 30% | 300 | High biological, low luxury |

---

## 3. Base Cravings by Class (Biological Only)

From `character_classes.json`, baseCravingVector.fine indices:

| Dimension | Elite [idx] | Upper [idx] | Middle [idx] | Lower [idx] |
|-----------|-------------|-------------|--------------|-------------|
| Grain (0) | 4.9 | 3.5 | 4.0 | 4.5 |
| Protein (1) | 5.0 | 3.0 | 3.5 | 4.0 |
| Produce (2) | 4.9 | 3.5 | 4.0 | 4.5 |
| Hydration (3) | 5.7 | 3.0 | 3.5 | 4.0 |
| Medicine (4) | 2.0 | 2.5 | 3.0 | 3.5 |
| Hygiene (5) | 8.6 | 2.5 | 3.0 | 3.5 |
| Rest (6) | 8.6 | 2.5 | 2.5 | 3.0 |
| Stimulation (7) | 5.0 | 2.0 | 2.0 | 2.5 |
| Fat (57) | ~5.0* | ~2.5* | ~3.0* | ~3.5* |

*Fat values estimated based on pattern - need to verify index 57 in the vector

---

## 4. Daily Craving Accumulation (1000 Citizens)

### Formula
```
Daily Craving Points = Σ (baseCraving × slotMultiplier × classCount)
```

### 4.1 Grain Nutrition (Index 0) - 3 slots = ×2.5

| Class | Base | ×2.5 | Count | Total/Day |
|-------|------|------|-------|-----------|
| Elite | 4.9 | 12.25 | 100 | 1,225 |
| Upper | 3.5 | 8.75 | 200 | 1,750 |
| Middle | 4.0 | 10.0 | 400 | 4,000 |
| Lower | 4.5 | 11.25 | 300 | 3,375 |
| **Total** | | | **1000** | **10,350 pts/day** |

### 4.2 Protein Nutrition (Index 1) - 2 slots = ×1.67

| Class | Base | ×1.67 | Count | Total/Day |
|-------|------|-------|-------|-----------|
| Elite | 5.0 | 8.35 | 100 | 835 |
| Upper | 3.0 | 5.01 | 200 | 1,002 |
| Middle | 3.5 | 5.85 | 400 | 2,338 |
| Lower | 4.0 | 6.68 | 300 | 2,004 |
| **Total** | | | **1000** | **6,179 pts/day** |

### 4.3 Produce Nutrition (Index 2) - 3 slots = ×2.5

| Class | Base | ×2.5 | Count | Total/Day |
|-------|------|------|-------|-----------|
| Elite | 4.9 | 12.25 | 100 | 1,225 |
| Upper | 3.5 | 8.75 | 200 | 1,750 |
| Middle | 4.0 | 10.0 | 400 | 4,000 |
| Lower | 4.5 | 11.25 | 300 | 3,375 |
| **Total** | | | **1000** | **10,350 pts/day** |

### 4.4 Hydration (Index 3) - 5 slots = ×4.17

| Class | Base | ×4.17 | Count | Total/Day |
|-------|------|-------|-------|-----------|
| Elite | 5.7 | 23.77 | 100 | 2,377 |
| Upper | 3.0 | 12.51 | 200 | 2,502 |
| Middle | 3.5 | 14.60 | 400 | 5,838 |
| Lower | 4.0 | 16.68 | 300 | 5,004 |
| **Total** | | | **1000** | **15,721 pts/day** |

### 4.5 Medicine (Index 4) - 2 slots = ×1.67

| Class | Base | ×1.67 | Count | Total/Day |
|-------|------|-------|-------|-----------|
| Elite | 2.0 | 3.34 | 100 | 334 |
| Upper | 2.5 | 4.18 | 200 | 835 |
| Middle | 3.0 | 5.01 | 400 | 2,004 |
| Lower | 3.5 | 5.85 | 300 | 1,754 |
| **Total** | | | **1000** | **4,927 pts/day** |

### 4.6 Hygiene (Index 5) - 2 slots = ×1.67

| Class | Base | ×1.67 | Count | Total/Day |
|-------|------|-------|-------|-----------|
| Elite | 8.6 | 14.36 | 100 | 1,436 |
| Upper | 2.5 | 4.18 | 200 | 835 |
| Middle | 3.0 | 5.01 | 400 | 2,004 |
| Lower | 3.5 | 5.85 | 300 | 1,754 |
| **Total** | | | **1000** | **6,029 pts/day** |

### 4.7 Rest Quality (Index 6) - 1 slot = ×0.83

| Class | Base | ×0.83 | Count | Total/Day |
|-------|------|-------|-------|-----------|
| Elite | 8.6 | 7.14 | 100 | 714 |
| Upper | 2.5 | 2.08 | 200 | 415 |
| Middle | 2.5 | 2.08 | 400 | 830 |
| Lower | 3.0 | 2.49 | 300 | 747 |
| **Total** | | | **1000** | **2,706 pts/day** |

### 4.8 Energy Stimulation (Index 7) - 2 slots = ×1.67

| Class | Base | ×1.67 | Count | Total/Day |
|-------|------|-------|-------|-----------|
| Elite | 5.0 | 8.35 | 100 | 835 |
| Upper | 2.0 | 3.34 | 200 | 668 |
| Middle | 2.0 | 3.34 | 400 | 1,336 |
| Lower | 2.5 | 4.18 | 300 | 1,253 |
| **Total** | | | **1000** | **4,092 pts/day** |

### Summary Table: Daily Craving Points (1000 Citizens)

| Dimension | Daily Points | Priority |
|-----------|-------------|----------|
| Hydration | 15,721 | Critical |
| Grain | 10,350 | Critical |
| Produce | 10,350 | Critical |
| Protein | 6,179 | High |
| Hygiene | 6,029 | High |
| Medicine | 4,927 | Medium |
| Stimulation | 4,092 | Medium |
| Rest | 2,706 | Low |

---

## 5. Commodity Selection (2-3 Varieties per Craving)

### 5.1 Grain Commodities

| Commodity | Grain Fulfillment | Production Chain |
|-----------|------------------|------------------|
| **Bread** | 15 | Wheat → Mill → Bakery |
| **Roti** | 12 | Wheat → Mill → Tandoor |
| **Rice** | 12 | Rice Paddy (raw) |

**Primary:** Bread (15 pts) - best value
**Variety 1:** Roti (12 pts) - Indian staple
**Variety 2:** Rice (12 pts) - different production chain

### 5.2 Protein Commodities

| Commodity | Protein Fulfillment | Production Chain |
|-----------|---------------------|------------------|
| **Meat** | 20 | Pasture → Butcher |
| **Eggs** | 16.5 | Poultry Farm |
| **Paneer** | 7 | Dairy → Cheese Maker |

**Primary:** Meat (20 pts) - highest value
**Variety 1:** Eggs (16.5 pts) - easy production
**Variety 2:** Paneer (7 pts) - vegetarian option

### 5.3 Produce Commodities

| Commodity | Produce Fulfillment | Production Chain |
|-----------|---------------------|------------------|
| **Vegetable** | 15 | Vegetable Farm |
| **Potato** | 15 | Potato Farm |
| **Carrot** | 15 | Carrot Farm |

**Primary:** Vegetable (15 pts) - generic
**Variety 1:** Potato (15 pts) - Indian staple
**Variety 2:** Carrot (15 pts) - variety

### 5.4 Hydration Commodities

| Commodity | Hydration Fulfillment | Production Chain |
|-----------|----------------------|------------------|
| **Beer** | 5 | Grain → Brewery |
| **Fruits** | 5 | Orchard |
| **Vegetables** | 3 | Farm |

**Note:** Hydration values are LOW! This may be a balance issue.
- Need **Water** commodity with higher fulfillment (15-20?)
- Currently relying on food items for hydration

**Primary:** Water (need to add, suggest 20 pts)
**Variety 1:** Beer (5 pts) - also fulfills vice
**Variety 2:** Fruits like watermelon (5 pts)

### 5.5 Medicine Commodities

| Commodity | Medicine Fulfillment | Production Chain |
|-----------|---------------------|------------------|
| **Medicine** | 17.5 | Herbalist/Apothecary |
| **Tonic** | 7.5 | Herbalist |
| **Healing Salve** | 5.5 | Herbalist |

**Primary:** Medicine (17.5 pts)
**Variety 1:** Tonic (7.5 pts) - preventive
**Variety 2:** Healing Salve (5.5 pts) - injury treatment

### 5.6 Hygiene Commodities

| Commodity | Hygiene Fulfillment | Production Chain |
|-----------|---------------------|------------------|
| **Soap** | 10 | Tallow/Oil → Soap Maker |
| **Fine Clothes** | 5 | Textile → Tailor |
| **Ceramics** | 5 | Clay → Potter |

**Primary:** Soap (10 pts)
**Variety 1:** Clean clothes (5 pts)
**Variety 2:** Pottery/ceramics for storage (5 pts)

### 5.7 Rest Quality Commodities

| Commodity | Rest Fulfillment | Production Chain |
|-----------|-----------------|------------------|
| **Bed** | 15 | Carpenter |

**Only option:** Bed (durable, not consumable)
- This is a one-time purchase per household
- Need to verify how durables work in consumption

### 5.8 Energy Stimulation Commodities

| Commodity | Stimulation Fulfillment | Production Chain |
|-----------|------------------------|------------------|
| **Date** | 10.5 | Date Palm |
| **Pastries** | 5 | Bakery |
| **Coconut** | 5 | Coconut Palm |

**Primary:** Date (10.5 pts) - high energy
**Variety 1:** Pastries (5 pts) - breakfast item
**Variety 2:** Coffee/Tea (need to add?)

---

## 6. Production Requirements (1000 Citizens, Per Day)

### 6.1 Grain Production

**Need:** 10,350 grain points/day

Using mix: 60% Bread, 25% Roti, 15% Rice

| Commodity | Points | Need | Fulfillment | Units/Day |
|-----------|--------|------|-------------|-----------|
| Bread | 6,210 | 60% | 15 | 414 |
| Roti | 2,588 | 25% | 12 | 216 |
| Rice | 1,553 | 15% | 12 | 129 |

### 6.2 Protein Production

**Need:** 6,179 protein points/day

Using mix: 50% Meat, 30% Eggs, 20% Paneer

| Commodity | Points | Need | Fulfillment | Units/Day |
|-----------|--------|------|-------------|-----------|
| Meat | 3,090 | 50% | 20 | 155 |
| Eggs | 1,854 | 30% | 16.5 | 112 |
| Paneer | 1,236 | 20% | 7 | 177 |

### 6.3 Produce Production

**Need:** 10,350 produce points/day

Using mix: 40% Vegetable, 35% Potato, 25% Carrot

| Commodity | Points | Need | Fulfillment | Units/Day |
|-----------|--------|------|-------------|-----------|
| Vegetable | 4,140 | 40% | 15 | 276 |
| Potato | 3,623 | 35% | 15 | 242 |
| Carrot | 2,588 | 25% | 15 | 173 |

### 6.4 Hydration Production

**Need:** 15,721 hydration points/day

**PROBLEM:** Current commodities have LOW hydration values (3-5 pts)!

If only using beer (5 pts): 15,721 / 5 = **3,144 beer/day** - impossible!

**RECOMMENDATION:** Add Water commodity with 20 hydration points
- Using 80% Water, 20% Beer:
  - Water: 12,577 pts / 20 = 629 water/day
  - Beer: 3,144 pts / 5 = 629 beer/day

### 6.5 Medicine Production

**Need:** 4,927 medicine points/day

Using mix: 70% Medicine, 30% Tonic

| Commodity | Points | Need | Fulfillment | Units/Day |
|-----------|--------|------|-------------|-----------|
| Medicine | 3,449 | 70% | 17.5 | 197 |
| Tonic | 1,478 | 30% | 7.5 | 197 |

### 6.6 Hygiene Production

**Need:** 6,029 hygiene points/day

Using mix: 70% Soap, 30% Clothes (reuse)

| Commodity | Points | Need | Fulfillment | Units/Day |
|-----------|--------|------|-------------|-----------|
| Soap | 4,220 | 70% | 10 | 422 |
| Clothes | 1,809 | 30% | 5 | 362 |

### 6.7 Rest Quality

**Need:** 2,706 rest points/day

**Bed** is a durable - need 1 per citizen = **1,000 beds total**
(One-time production, not daily)

### 6.8 Energy Stimulation

**Need:** 4,092 stimulation points/day

Using mix: 60% Date, 40% Pastries

| Commodity | Points | Need | Fulfillment | Units/Day |
|-----------|--------|------|-------------|-----------|
| Date | 2,455 | 60% | 10.5 | 234 |
| Pastries | 1,637 | 40% | 5 | 327 |

---

## 7. Summary: Daily Production Targets

| Commodity | Units/Day | Primary Craving |
|-----------|-----------|-----------------|
| **Bread** | 414 | Grain |
| **Roti** | 216 | Grain |
| **Rice** | 129 | Grain |
| **Meat** | 155 | Protein |
| **Eggs** | 112 | Protein |
| **Paneer** | 177 | Protein |
| **Vegetable** | 276 | Produce |
| **Potato** | 242 | Produce |
| **Carrot** | 173 | Produce |
| **Water** | 629 | Hydration (NEW!) |
| **Beer** | 629 | Hydration + Vice |
| **Medicine** | 197 | Medicine |
| **Tonic** | 197 | Medicine |
| **Soap** | 422 | Hygiene |
| **Date** | 234 | Stimulation |
| **Pastries** | 327 | Stimulation |
| **Bed** | 1,000 | Rest (one-time) |

---

## 8. Building Production Analysis

### 8.1 Current Recipe Data

| Recipe | Time (sec) | Output | Output/Day (300s) |
|--------|-----------|--------|-------------------|
| Wheat Farming | 7200 | 10 wheat | 0.42 wheat |
| Rice Farming | 7200 | 10 rice | 0.42 rice |
| Potato Farming | 7200 | 120 potato | 5 potato |
| Vegetable Farming | 5400 | 80 veg | 4.4 veg |
| Carrot Farming | 5400 | 80 carrot | 4.4 carrot |
| Bread Baking | 180 | 8 bread | 13.3 bread |
| Roti Making | 600 | 20 roti | 10 roti |

### 8.2 Stations Needed (Current Recipes)

**Bread (need 414/day):**
- Bread per station: 13.3/day
- Bakery stations needed: 414 / 13.3 = **31 stations**

**Wheat for Bread (need ~520 wheat for 414 bread):**
- Wheat per station: 0.42/day
- Farm stations needed: 520 / 0.42 = **1,238 stations** ❌ IMPOSSIBLE

### 8.3 With 5x Farm Speed

| Recipe | New Time | Output/Day |
|--------|----------|-----------|
| Wheat Farming | 1440s | 2.08 wheat |
| Rice Farming | 1440s | 2.08 rice |
| Potato Farming | 1440s | 25 potato |
| Vegetable Farming | 1080s | 22.2 veg |
| Carrot Farming | 1080s | 22.2 carrot |

**Wheat for Bread (5x speed):**
- Farm stations needed: 520 / 2.08 = **250 stations** ❌ Still too many

### 8.4 With 10x Farm Speed + 2x Output

| Recipe | Time | Output | Output/Day |
|--------|------|--------|-----------|
| Wheat Farming | 720s | 100 wheat | 41.7 wheat |
| Rice Farming | 720s | 100 rice | 41.7 rice |

**Wheat for Bread (10x speed, 10x output):**
- Farm stations needed: 520 / 41.7 = **13 stations** ✓ Reasonable

---

## 9. Recommended Recipe Fixes

### 9.1 Farming Recipes

| Recipe | Current | Recommended | Change |
|--------|---------|-------------|--------|
| Wheat | 7200s → 10 | 720s → 100 | 10x speed, 10x output |
| Rice | 7200s → 10 | 720s → 100 | 10x speed, 10x output |
| Potato | 7200s → 120 | 1440s → 120 | 5x speed |
| Vegetable | 5400s → 80 | 1080s → 80 | 5x speed |
| Carrot | 5400s → 80 | 1080s → 80 | 5x speed |
| Groundnut | 7200s → 100 | 1440s → 100 | 5x speed |

### 9.2 Add Missing Commodities

1. **Water** - fulfillment: hydration: 20
2. **Coffee/Tea** - fulfillment: stimulation: 15, hydration: 3
3. **Milk** - exists but needs recipe

### 9.3 Add Missing Recipes

1. **Well/Water Pump** → Water (continuous production)
2. **Poultry Farm** → Eggs
3. **Dairy Farm** → Milk
4. **Cheese Maker** → Paneer/Cheese

---

## 10. Final Building Count (1000 Citizens)

With recommended recipe fixes (10x grain, 5x vegetables):

| Building | Stations | Level 2 Buildings | Workers |
|----------|----------|-------------------|---------|
| Wheat Farm | 13 | 2 | 16 |
| Rice Farm | 3 | 1 | 8 |
| Vegetable Farm | 13 | 2 | 16 |
| Potato Farm | 10 | 2 | 16 |
| Carrot Farm | 8 | 1 | 8 |
| Bakery | 31 | 8 | 32 |
| Tandoor | 22 | 6 | 24 |
| Pasture/Ranch | 15 | 2 | 16 |
| Butcher | 8 | 2 | 8 |
| Poultry Farm | 12 | 2 | 16 |
| Dairy | 10 | 2 | 16 |
| Well | 32 | 8 | 32 |
| Brewery | 32 | 4 | 32 |
| Herbalist | 20 | 3 | 24 |
| Soap Maker | 21 | 3 | 24 |
| Date Palm | 12 | 2 | 16 |
| **Total** | | **~48 buildings** | **~300 workers** |

**30% of population in food/biological production** - reasonable for a pre-industrial economy!

---

## 11. Key Issues Found

1. **Wheat/Rice output is 10x too low** - Only 10 units vs 120 for potato
2. **No Water commodity** - Hydration relies on food/alcohol (unrealistic)
3. **No Coffee/Tea** - Stimulation relies on dates/pastries
4. **Hygiene Elite value (8.6) seems too high** - Needs review
5. **Rest Elite value (8.6) seems too high** - Needs review

---

## 12. Action Items

1. [ ] Fix wheat/rice recipe: 7200s→10 to 720s→100
2. [ ] Add Water commodity with hydration: 20
3. [ ] Add Well building with water production
4. [ ] Add Coffee/Tea commodity with stimulation: 15
5. [ ] Review Elite baseCraving values for hygiene/rest
6. [ ] Verify Fat, Spicy, Crunchy dimensions have time slots defined
7. [ ] Test with 100 citizens to verify balance

---

*Document created: 2025-12-20*
*Related: balance_analysis_corrected.md, specialized_starting_towns_design.md*
