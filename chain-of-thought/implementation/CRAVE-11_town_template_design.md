# CRAVE-11: Town Template Data Design

**Created:** 2025-12-31
**Status:** Implementation Ready
**Type:** CFP Prototype - No Gold/Currency System
**Target:** 4 Indian Specialty Starter Towns

---

## Executive Summary

This document provides complete specifications for **4 specialty starter towns** for the Cravetown CFP prototype. Each town focuses on producing one signature Indian dish with a complete, balanced supply chain designed to survive **20+ production cycles** independently.

**The Four Towns:**
1. **Vada Pav Town (Mumbai)** - ⭐ Easy
2. **Poha Town (Indore)** - ⭐ Easy
3. **Dosa Town (Bangalore)** - ⭐⭐ Medium
4. **Rasogulla Town (Kolkata)** - ⭐⭐⭐ Hard

**Key Constraint:** CFP prototype has **NO gold/wages/currency** - pure production-consumption mechanics only.

---

## 1. Difficulty Rating System

### Criteria Definition

Difficulty is calculated based on **four weighted factors**:

#### Factor 1: Production Chain Complexity (Weight: 2.0)
- **Simple (1 point)**: Raw material → Final product (1 step)
- **Basic (2 points)**: Raw → Processed → Final (2 steps)
- **Intermediate (3 points)**: Raw → Processed → Intermediate → Final (3 steps)
- **Complex (4 points)**: Multiple parallel chains converging (4+ steps)

#### Factor 2: Timing Complexity (Weight: 0.001 per second)
- **Fast (<30 min)**: Quick production cycles
- **Medium (30-90 min)**: Moderate wait times
- **Slow (90-180 min)**: Long production cycles
- **Very Slow (>180 min)**: Extended production (fermentation, aging)

#### Factor 3: Resource Scarcity (Weight: 3.0)
- **Abundant (1 point)**: All inputs produced in-town with surplus
- **Balanced (2 points)**: Production barely meets demand
- **Scarce (3 points)**: Tight resource management required
- **Critical (4 points)**: Constant shortages, requires perfect planning

#### Factor 4: Worker Efficiency Requirement (Weight: 1.5)
- **General Labor (1 point)**: Any worker can do any job
- **Semi-Specialized (2 points)**: Mix of general and specialized workers
- **Specialized (3 points)**: Most jobs require specific vocations
- **Highly Specialized (4 points)**: All jobs require rare vocations

### Difficulty Score Formula

```
Difficulty Score =
  (Chain Complexity × 2.0) +
  (Total Production Time in seconds × 0.001) +
  (Resource Scarcity × 3.0) +
  (Worker Specialization × 1.5)
```

### Difficulty Tiers

| Tier | Score Range | Stars | Citizen Count | Starting Inventory |
|------|-------------|-------|---------------|-------------------|
| Easy | 0 - 18 | ⭐ | 8-10 | 30 cycles worth |
| Medium | 18 - 28 | ⭐⭐ | 10-12 | 20 cycles worth |
| Hard | 28+ | ⭐⭐⭐ | 12-15 | 10 cycles worth |

---

## 2. Production Cycle Definition

### What is "1 Cycle"?

**1 Production Cycle** = Completion of the **slowest building's production batch** in the town's primary supply chain.

- **Vada Pav Town**: 1 cycle = 25 minutes (Vada Making time)
- **Poha Town**: 1 cycle = 40 minutes (Rice Flattening time)
- **Dosa Town**: 1 cycle = 180 minutes (Dosa fermentation time)
- **Rasogulla Town**: 1 cycle = 180 minutes (Sugarcane farming time)

### Survival Requirement

Each town must have sufficient **starting inventory** to survive **20+ production cycles** without any building completing a production run. This ensures:
- Citizens can consume food during startup
- Buildings have inputs for initial production
- Emergency buffer exists for mistakes

---

## 3. Citizen Consumption Rates

### Per-Cycle Consumption (Standard Rates)

| Resource Type | Lower Class | Middle Class | Upper Class |
|--------------|-------------|--------------|-------------|
| Food (Biological) | 3-4 units | 4-5 units | 5-6 units |
| Water | 5 units | 5 units | 5 units |
| Clothing (decay) | 0.1 units | 0.15 units | 0.2 units |
| Luxury Items | 0 units | 0.5 units | 1 unit |

### CFP Prototype Simplification

For these starter towns, we use **simplified consumption**:
- **All citizens**: 4 food units per cycle (average of all classes)
- **Water**: Assumed abundant (wells/rivers provide infinite)
- **Clothing**: Not tracked in starter period
- **Specialty dish**: Counted as "luxury food" in biological category

---

## 4. Town #1: Vada Pav Town (Mumbai)

### Overview
**Specialty:** Vada Pav (Vada + Pav combo)
**City:** Mumbai
**Difficulty:** ⭐ Easy
**Description:** "Mumbai's beloved street snack comes alive in this bustling town. The sharp crack of fried vada contrasts with the soft warmth of freshly baked pav buns. Chutney vendors add their secret blends as workers shuttle between fryers and ovens, creating the perfect harmony of crispy and fluffy."

### Difficulty Calculation
- **Chain Complexity**: 3 steps (Farm → Mill/Press → Kitchen/Bakery → Final) = 3 × 2.0 = **6.0**
- **Timing**: Max 1500 seconds (Vada Making) × 0.001 = **1.5**
- **Resource Scarcity**: Balanced (2) × 3.0 = **6.0**
- **Worker Specialization**: Semi-specialized (2) × 1.5 = **3.0**
- **Total Score**: 6.0 + 1.5 + 6.0 + 3.0 = **16.5** → ⭐ Easy

### Supply Chain Diagram

```
VADA PRODUCTION CHAIN:
Lentil Farm (2 workers) ────────────────────────────┐
                                                     ├──► Street Food Kitchen (2 workers) ──► VADA
Groundnut Farm (1 worker) ──► Oil Press (1 worker) ─┘
                                  │
                                  └──────────────────────────────────┐
PAV PRODUCTION CHAIN:                                                │
Wheat Farm (2 workers) ──► Flour Mill (1 worker) ──► Bakery (1 worker) ──► PAV
                                                                      │
                                                                      │
COMBINED: VADA + PAV = VADA PAV MEAL ◄────────────────────────────────┘
```

### Buildings

| Building Type | Recipe | Workers | Position | Notes |
|--------------|--------|---------|----------|-------|
| Farm | Lentil Farming | 2 | (100, 100) | Primary vada ingredient |
| Farm | Wheat Farming | 2 | (250, 100) | For pav production |
| Farm | Groundnut Farming | 1 | (400, 100) | For oil |
| Flour Mill | Flour Milling | 1 | (250, 250) | Wheat → Flour |
| Oil Press | Groundnut Oil Pressing | 1 | (400, 250) | Groundnut → Oil |
| Bakery | Pav Baking | 1 | (150, 400) | Flour → Pav |
| Street Food Kitchen | Vada Making | 2 | (350, 400) | Lentils + Oil + Spices → Vada |
| Lodge | - | 0 | (550, 250) | Housing for 6 workers |
| Cottage | - | 0 | (550, 400) | Housing for family of 4 |

**Total Buildings:** 9
**Production Buildings:** 7
**Housing:** 2 (capacity: 10 citizens)

### Citizens

| # | Name | Vocation | Class | Age | Workplace | Housing | Family |
|---|------|----------|-------|-----|-----------|---------|--------|
| 0 | Ganesh Pawar | Street Food Cook | Middle | 38 | Kitchen #6 | Cottage #8 | Owner, spouse to #1 |
| 1 | Sushila Pawar | Street Food Cook | Middle | 35 | Kitchen #6 | Cottage #8 | Spouse to #0 |
| 2 | Rahul Pawar | Apprentice | Lower | 15 | Kitchen #6 | Cottage #8 | Child of #0 |
| 3 | Meera Pawar | Child | Lower | 8 | None | Cottage #8 | Child of #0 |
| 4 | Ramesh Yadav | Farmer | Lower | 28 | Farm #0 | Lodge #7 | - |
| 5 | Priya Yadav | Farmer | Lower | 26 | Farm #1 | Lodge #7 | Spouse to #4 |
| 6 | Vijay Kumar | Farmer | Lower | 24 | Farm #2 | Lodge #7 | - |
| 7 | Sunita Sharma | Grain Processor | Lower | 30 | Flour Mill #3 | Lodge #7 | - |
| 8 | Anil Gupta | Oil Presser | Lower | 32 | Oil Press #4 | Lodge #7 | - |
| 9 | Kavita Desai | Baker | Lower | 29 | Bakery #5 | Lodge #7 | - |

**Total Citizens:** 10
**Workers:** 8 (2 children)
**Families:** 1 (Pawar family)

### Production Rates & Bottleneck Analysis

#### Production Chain 1: Vada
| Step | Building | Input | Output | Time | Rate/Hour |
|------|----------|-------|--------|------|-----------|
| 1 | Lentil Farm | 15 lentil_seed | 60 lentils | 105 min | 34.3 lentils/hr |
| 2 | Street Food Kitchen | 5 lentils + 2 oil + 1 spices | 20 vada | 25 min | 48 vada/hr |

**Bottleneck:** Lentil farming (slowest step)
**Vada Production Rate:** Limited by lentil supply = ~34 lentils/hr = ~136 vada/hr potential

#### Production Chain 2: Pav
| Step | Building | Input | Output | Time | Rate/Hour |
|------|----------|-------|--------|------|-----------|
| 1 | Wheat Farm | 20 wheat_seed | 80 wheat | 120 min | 40 wheat/hr |
| 2 | Flour Mill | 50 wheat | 45 flour | 30 min | 90 flour/hr |
| 3 | Bakery | 12 flour | 20 pav | 4 min | 300 pav/hr |

**Bottleneck:** Wheat farming (slowest step)
**Pav Production Rate:** Limited by wheat supply = ~40 wheat/hr = ~72 flour/hr = ~120 pav/hr

#### Production Chain 3: Oil
| Step | Building | Input | Output | Time | Rate/Hour |
|------|----------|-------|--------|------|-----------|
| 1 | Groundnut Farm | 15 groundnut_seed | 100 groundnut | 120 min | 50 groundnut/hr |
| 2 | Oil Press | 30 groundnut | 12 oil | 40 min | 18 oil/hr |

**Bottleneck:** Oil pressing (conversion rate)
**Oil Production Rate:** ~18 oil/hr

#### Combined Analysis
- **Vada needs oil**: 20 vada = 2 oil → 10 vada per oil
- **Oil production**: 18 oil/hr → supports 180 vada/hr (NOT the bottleneck)
- **Vada needs lentils**: 20 vada = 5 lentils → 4 vada per lentil
- **Lentil production**: 34 lentils/hr → supports ~136 vada/hr (IS the bottleneck)

**Conclusion:** Lentil farming limits vada production to **~136 vada/hr**

### Starting Inventory (30 Cycles @ 25 min/cycle = 12.5 hours)

#### Seeds (for 4 planting cycles)
- `lentil_seed`: 60 (4 × 15)
- `wheat_seed`: 80 (4 × 20)
- `groundnut_seed`: 60 (4 × 15)

#### Raw Materials (2-3 production batches worth)
- `lentils`: 150 (for immediate vada production)
- `wheat`: 200 (for flour/pav production)
- `groundnut`: 200 (for oil production)

#### Processed Goods (buffer for startup)
- `flour`: 100 (ready for pav baking)
- `oil`: 50 (ready for vada making)
- `spices`: 40 (slow consumption)

#### Final Products (3 days worth for 10 citizens)
- `vada`: 120 (10 citizens × 4 food/cycle × 3 days)
- `pav`: 120 (served with vada)

#### Essentials
- `water`: 500 (ample supply)
- `bread`: 80 (backup food)
- `cloth`: 40 (for initial needs)
- `thread`: 30

**Total Inventory Items:** 14 commodity types

---

## 5. Town #2: Poha Town (Indore)

### Overview
**Specialty:** Poha (Flattened Rice Breakfast)
**City:** Indore
**Difficulty:** ⭐ Easy
**Description:** "Dawn breaks over Indore, and the city awakens to the gentle sizzle of flattened rice in kadhai pans. This is poha country - where every morning begins with golden beaten rice cooked with onions, turmeric, and curry leaves. Your town has mastered the art of the perfect breakfast: rice mills that flatten grains just right, vegetable farms providing fresh onions, and skilled cooks who know that poha is more than food - it's a way of life."

### Difficulty Calculation
- **Chain Complexity**: 3 steps (Farm → Mill/Press → Kitchen) = 3 × 2.0 = **6.0**
- **Timing**: Max 2400 seconds (Rice Flattening) × 0.001 = **2.4**
- **Resource Scarcity**: Balanced (2) × 3.0 = **6.0**
- **Worker Specialization**: Semi-specialized (2) × 1.5 = **3.0**
- **Total Score**: 6.0 + 2.4 + 6.0 + 3.0 = **17.4** → ⭐ Easy

### Supply Chain Diagram

```
Rice Paddy Farm (2 workers) ──► Rice Mill (1 worker) ──┐
                                                        ├──► Street Food Kitchen (2 workers) ──► POHA
Onion Farm (2 workers) ────────────────────────────────┘

Groundnut Farm (1 worker) ──► Oil Press (1 worker) ────┘
```

### Buildings

| Building Type | Recipe | Workers | Position | Notes |
|--------------|--------|---------|----------|-------|
| Farm | Rice Farming | 2 | (100, 100) | Primary ingredient |
| Farm | Onion Farming | 2 | (250, 100) | For flavor |
| Farm | Groundnut Farming | 1 | (400, 100) | For oil |
| Rice Mill | Rice Flattening | 1 | (175, 250) | Rice → Flattened Rice |
| Oil Press | Groundnut Oil Pressing | 1 | (400, 250) | Groundnut → Oil |
| Street Food Kitchen | Poha Making | 2 | (275, 400) | Flattened Rice + Onion + Oil → Poha |
| Lodge | - | 0 | (550, 250) | Housing for 7 workers |
| Cottage | - | 0 | (550, 400) | Housing for family of 3 |

**Total Buildings:** 8
**Production Buildings:** 6
**Housing:** 2 (capacity: 10 citizens)

### Citizens

| # | Name | Vocation | Class | Age | Workplace | Housing | Family |
|---|------|----------|-------|-----|-----------|---------|--------|
| 0 | Deepak Malhotra | Street Food Cook | Middle | 40 | Kitchen #5 | Cottage #7 | Owner, spouse to #1 |
| 1 | Pooja Malhotra | Street Food Cook | Middle | 37 | Kitchen #5 | Cottage #7 | Spouse to #0 |
| 2 | Aarav Malhotra | Apprentice | Lower | 12 | Kitchen #5 | Cottage #7 | Child of #0 |
| 3 | Sanjay Thakur | Grain Processor | Lower | 33 | Rice Mill #3 | Lodge #6 | - |
| 4 | Rekha Chauhan | Farmer | Lower | 27 | Farm #0 | Lodge #6 | - |
| 5 | Manoj Yadav | Farmer | Lower | 29 | Farm #0 | Lodge #6 | - |
| 6 | Geeta Pandey | Farmer | Lower | 25 | Farm #1 | Lodge #6 | - |
| 7 | Ramesh Tiwari | Farmer | Lower | 31 | Farm #1 | Lodge #6 | - |
| 8 | Nisha Jain | Farmer | Lower | 26 | Farm #2 | Lodge #6 | - |
| 9 | Divya Agarwal | Oil Presser | Lower | 28 | Oil Press #4 | Lodge #6 | - |

**Total Citizens:** 10
**Workers:** 9 (1 child apprentice)
**Families:** 1 (Malhotra family)

### Production Rates & Bottleneck Analysis

#### Production Chain: Poha
| Step | Building | Input | Output | Time | Rate/Hour |
|------|----------|-------|--------|------|-----------|
| 1a | Rice Farm | 20 rice_seed | 80 rice | 120 min | 40 rice/hr |
| 1b | Onion Farm | 20 onion_seed | 90 onion | 105 min | 51 onion/hr |
| 1c | Groundnut Farm | 15 groundnut_seed | 100 groundnut | 120 min | 50 groundnut/hr |
| 2a | Rice Mill | 35 rice | 30 flattened_rice | 40 min | 45 flattened_rice/hr |
| 2b | Oil Press | 30 groundnut | 12 oil | 40 min | 18 oil/hr |
| 3 | Street Food Kitchen | 10 flattened_rice + 3 onion + 1 oil + 1 spices | 18 poha | 15 min | 72 poha/hr |

**Bottleneck:** Rice farming → Rice mill conversion
**Poha Production Rate:** 40 rice/hr → ~34 flattened_rice/hr → ~61 poha/hr

### Starting Inventory (30 Cycles @ 40 min/cycle = 20 hours)

#### Seeds (for 4 planting cycles)
- `rice_seed`: 80 (4 × 20)
- `onion_seed`: 80 (4 × 20)
- `groundnut_seed`: 60 (4 × 15)

#### Raw Materials
- `rice`: 280 (7 production batches)
- `onion`: 200
- `groundnut`: 180

#### Processed Goods
- `flattened_rice`: 150 (ready for poha making)
- `oil`: 60

#### Final Products
- `poha`: 240 (10 citizens × 4 food/cycle × 6 days)

#### Essentials
- `spices`: 50
- `water`: 500
- `bread`: 100
- `cloth`: 40
- `thread`: 30

**Total Inventory Items:** 13 commodity types

---

## 6. Town #3: Dosa Town (Bangalore)

### Overview
**Specialty:** Dosa (South Indian Fermented Crepe)
**City:** Bangalore
**Difficulty:** ⭐⭐ Medium
**Description:** "The sound of batter spreading on hot griddles echoes through Bangalore's morning air. Here, dosa is an art form - the thin, crispy rice crepe that fuels the city's tech workers and traditionalists alike. Your town combines old and new: rice mills grinding grain, lentil farms supplying protein, and restaurants perfecting the fermentation that makes dosa irresistible. Whether served plain, masala, or paper-thin, each dosa tells a story of South Indian culinary excellence."

### Difficulty Calculation
- **Chain Complexity**: 3 steps + fermentation (4) × 2.0 = **8.0**
- **Timing**: Max 10800 seconds (Dosa fermentation) × 0.001 = **10.8**
- **Resource Scarcity**: Balanced (2) × 3.0 = **6.0**
- **Worker Specialization**: Specialized (3) × 1.5 = **4.5**
- **Total Score**: 8.0 + 10.8 + 6.0 + 4.5 = **29.3** → ⭐⭐ Medium

### Supply Chain Diagram

```
Rice Paddy Farm (2 workers) ────────────┐
                                        ├──► Restaurant (2 workers) ──► DOSA
Lentil Farm (2 workers) ────────────────┤      (3 hour fermentation)
                                        │
Groundnut Farm (1 worker) ──► Oil Press (1 worker) ──┘
```

### Buildings

| Building Type | Recipe | Workers | Position | Notes |
|--------------|--------|---------|----------|-------|
| Farm | Rice Farming | 2 | (100, 100) | Main ingredient |
| Farm | Lentil Farming | 2 | (250, 100) | For batter |
| Farm | Groundnut Farming | 1 | (400, 100) | For oil |
| Oil Press | Groundnut Oil Pressing | 1 | (400, 250) | Groundnut → Oil |
| Restaurant | Dosa Making | 2 | (250, 400) | Rice + Lentils + Oil → Dosa |
| Lodge | - | 0 | (550, 250) | Housing for 6 workers |
| Cottage | - | 0 | (550, 400) | Housing for family of 4 |

**Total Buildings:** 7
**Production Buildings:** 5
**Housing:** 2 (capacity: 10 citizens)

### Citizens

| # | Name | Vocation | Class | Age | Workplace | Housing | Family |
|---|------|----------|-------|-----|-----------|---------|--------|
| 0 | Suresh Krishnan | Restaurant Cook | Middle | 42 | Restaurant #4 | Cottage #6 | Owner, spouse to #1 |
| 1 | Lakshmi Krishnan | Restaurant Cook | Middle | 39 | Restaurant #4 | Cottage #6 | Spouse to #0 |
| 2 | Arjun Krishnan | Apprentice | Lower | 14 | Restaurant #4 | Cottage #6 | Child of #0 |
| 3 | Priya Krishnan | Child | Lower | 9 | None | Cottage #6 | Child of #0 |
| 4 | Venkat Reddy | Farmer | Lower | 34 | Farm #0 | Lodge #5 | - |
| 5 | Bhavani Menon | Farmer | Lower | 30 | Farm #0 | Lodge #5 | - |
| 6 | Ganesh Rao | Farmer | Lower | 28 | Farm #1 | Lodge #5 | - |
| 7 | Vasantha Kumar | Farmer | Lower | 26 | Farm #1 | Lodge #5 | - |
| 8 | Prakash Shetty | Farmer | Lower | 32 | Farm #2 | Lodge #5 | - |
| 9 | Sharada Bhat | Oil Presser | Lower | 29 | Oil Press #3 | Lodge #5 | - |

**Total Citizens:** 10
**Workers:** 8 (2 children)
**Families:** 1 (Krishnan family)

### Production Rates & Bottleneck Analysis

#### Production Chain: Dosa
| Step | Building | Input | Output | Time | Rate/Hour |
|------|----------|-------|--------|------|-----------|
| 1a | Rice Farm | 20 rice_seed | 80 rice | 120 min | 40 rice/hr |
| 1b | Lentil Farm | 15 lentil_seed | 60 lentils | 105 min | 34.3 lentils/hr |
| 1c | Groundnut Farm | 15 groundnut_seed | 100 groundnut | 120 min | 50 groundnut/hr |
| 2 | Oil Press | 30 groundnut | 12 oil | 40 min | 18 oil/hr |
| 3 | Restaurant | 5 rice + 2 lentils + 1 oil | 20 dosa | 180 min | 6.7 dosa/hr |

**Bottleneck:** Dosa fermentation time (3 hours)
**Dosa Production Rate:** ~6.7 dosa/hr (extremely slow due to fermentation)

**Critical Note:** The 3-hour fermentation creates a **severe bottleneck**. To meet citizen needs, the town must:
- Start multiple batches staggered throughout the day
- Maintain large buffer of finished dosas
- Have ample raw materials

### Starting Inventory (20 Cycles @ 180 min/cycle = 60 hours = 2.5 days)

#### Seeds (for 4 planting cycles)
- `rice_seed`: 80 (4 × 20)
- `lentil_seed`: 60 (4 × 15)
- `groundnut_seed`: 60 (4 × 15)

#### Raw Materials (LARGE buffer due to fermentation)
- `rice`: 400 (for continuous batching)
- `lentils`: 200
- `groundnut`: 200

#### Processed Goods
- `oil`: 80

#### Final Products (CRITICAL - must have large stock)
- `dosa`: 800 (10 citizens × 4 food/cycle × 20 cycles)
  - **Rationale:** Fermentation is slow, so starting dosas MUST last entire survival period

#### Essentials
- `spices`: 50
- `water`: 500
- `bread`: 200 (important backup due to dosa scarcity)
- `cloth`: 50
- `thread`: 40

**Total Inventory Items:** 12 commodity types

---

## 7. Town #4: Rasogulla Town (Kolkata)

### Overview
**Specialty:** Rasogulla (Bengali Sweet)
**City:** Kolkata
**Difficulty:** ⭐⭐⭐ Hard
**Description:** "In the City of Joy, sweetness isn't just a flavor - it's a philosophy. Kolkata's rasogulla, those spongy white spheres soaked in sugar syrup, represent Bengali culinary genius at its finest. Your town faces a delicious challenge: maintaining dairy supply for fresh paneer, managing sugar production, and perfecting the delicate art of rasogulla-making. The process is complex, requiring patience and skill, but when done right, each bite is pure bliss."

### Difficulty Calculation
- **Chain Complexity**: 5 steps (Farm → Dairy/Sugar Mill → Sweet Shop) = 5 × 2.0 = **10.0**
- **Timing**: Max 10800 seconds (Sugarcane farming) × 0.001 = **10.8**
- **Resource Scarcity**: Scarce (3) × 3.0 = **9.0**
- **Worker Specialization**: Highly Specialized (4) × 1.5 = **6.0**
- **Total Score**: 10.0 + 10.8 + 9.0 + 6.0 = **35.8** → ⭐⭐⭐ Hard

### Supply Chain Diagram

```
PANEER PRODUCTION:
Dairy Farm (with cows) ──► Dairy (2 workers) ──┐
                              (Milk Production)  ├──► Sweet Shop (2 workers) ──► RASOGULLA
                              (Paneer Making)    │
                                                 │
SUGAR PRODUCTION:                                │
Sugarcane Farm (2 workers) ──► Sugar Mill (1 worker) ──┘
                                 (Sugar Refining)

FEED PRODUCTION:
Wheat Farm (2 workers) ──► Flour Mill (1 worker) ──► Dairy (for cow feed)
```

### Buildings

| Building Type | Recipe | Workers | Position | Notes |
|--------------|--------|---------|----------|-------|
| Dairy Farm | Milk Production | 0 | (100, 100) | Natural milk production (passive) |
| Farm | Sugarcane Farming | 2 | (250, 100) | For sugar |
| Farm | Wheat Farming | 2 | (400, 100) | For animal feed (indirect) |
| Dairy | Paneer Making | 2 | (175, 250) | Milk → Paneer |
| Sugar Mill | Sugar Refining | 1 | (250, 250) | Sugarcane → Sugar |
| Flour Mill | Flour Milling | 1 | (400, 250) | Wheat → Flour (for backup food) |
| Sweet Shop | Rasogulla Making | 2 | (250, 400) | Paneer + Sugar → Rasogulla |
| Lodge | - | 0 | (550, 200) | Housing for 6 workers |
| Lodge | - | 0 | (550, 350) | Housing for 6 workers |

**Total Buildings:** 9
**Production Buildings:** 7
**Housing:** 2 (capacity: 12 citizens)

### Citizens

| # | Name | Vocation | Class | Age | Workplace | Housing | Family |
|---|------|----------|-------|-----|-----------|---------|--------|
| 0 | Subhash Bose | Sweet Maker | Middle | 45 | Sweet Shop #6 | Lodge #7 | Owner |
| 1 | Mala Chatterjee | Sweet Maker | Middle | 42 | Sweet Shop #6 | Lodge #7 | Business partner to #0 |
| 2 | Partha Banerjee | Dairy Worker | Lower | 36 | Dairy #3 | Lodge #7 | - |
| 3 | Rina Mukherjee | Dairy Worker | Lower | 33 | Dairy #3 | Lodge #7 | - |
| 4 | Tapan Dutta | Sugar Processor | Lower | 38 | Sugar Mill #4 | Lodge #7 | - |
| 5 | Suchitra Sen | Farmer | Lower | 29 | Farm #1 | Lodge #7 | - |
| 6 | Ranjan Das | Farmer | Lower | 31 | Farm #1 | Lodge #8 | - |
| 7 | Kabita Ghosh | Farmer | Lower | 27 | Farm #2 | Lodge #8 | - |
| 8 | Biswajit Roy | Farmer | Lower | 34 | Farm #2 | Lodge #8 | - |
| 9 | Ananya Sinha | Animal Herder | Lower | 26 | Dairy Farm #0 | Lodge #8 | - |
| 10 | Somnath Basu | Animal Herder | Lower | 30 | Dairy Farm #0 | Lodge #8 | - |
| 11 | Tandra Sarkar | Grain Processor | Lower | 28 | Flour Mill #5 | Lodge #8 | - |

**Total Citizens:** 12
**Workers:** 12 (all adults)
**Families:** 0 (all individual workers, some business partners)

### Production Rates & Bottleneck Analysis

#### Production Chain 1: Paneer
| Step | Building | Input | Output | Time | Rate/Hour |
|------|----------|-------|--------|------|-----------|
| 1 | Dairy Farm | - (passive) | 50 milk | 60 min | 50 milk/hr |
| 2 | Dairy | 25 milk | 4 paneer | 60 min | 4 paneer/hr |

**Paneer Rate:** 50 milk/hr → 8 paneer/hr (2 batches)

#### Production Chain 2: Sugar
| Step | Building | Input | Output | Time | Rate/Hour |
|------|----------|-------|--------|------|-----------|
| 1 | Sugarcane Farm | 10 sugarcane_cutting | 80 sugar_cane | 180 min | 26.7 sugar_cane/hr |
| 2 | Sugar Mill | 50 sugar_cane | 12 sugar | 60 min | 12 sugar/hr |

**Sugar Rate:** 26.7 sugar_cane/hr → ~6.4 sugar/hr

#### Production Chain 3: Rasogulla
| Step | Building | Input | Output | Time | Rate/Hour |
|------|----------|-------|--------|------|-----------|
| 3 | Sweet Shop | 8 paneer + 6 sugar | 15 rasogulla | 60 min | 15 rasogulla/hr |

**Bottlenecks:**
1. **Sugarcane farming** (3 hours) - slowest step
2. **Sugar conversion** - limits rasogulla production
3. **Paneer production** - dairy limits

**Rasogulla Production Rate:**
- Needs 8 paneer/hr → Have 8 paneer/hr ✓
- Needs 6 sugar/hr → Have ~6.4 sugar/hr ✓ (barely sufficient!)
- **Maximum:** ~15 rasogulla/hr (IF both inputs available)

**Critical Resource Management:**
- Sugarcane farming MUST run continuously
- Dairy MUST produce without interruption
- ANY shortage halts entire chain

### Starting Inventory (10 Cycles @ 180 min/cycle = 30 hours = 1.25 days)

**Note:** Hard difficulty = MINIMAL starting inventory. Citizens must manage carefully.

#### Seeds (for 3 planting cycles only - tighter than other towns)
- `sugarcane_cutting`: 30 (3 × 10)
- `wheat_seed`: 60 (3 × 20)

#### Raw Materials (MINIMAL buffer)
- `milk`: 200 (from dairy farm initial stock)
- `sugar_cane`: 150
- `wheat`: 150

#### Processed Goods (small buffer)
- `paneer`: 32 (enough for 4 rasogulla batches)
- `sugar`: 36 (enough for 6 rasogulla batches)
- `flour`: 60

#### Final Products (TIGHT - only 1 day worth)
- `rasogulla`: 480 (12 citizens × 4 food/cycle × 10 cycles)
  - **This is BARELY enough** - town MUST start production immediately

#### Essentials
- `feed`: 200 (for dairy animals)
- `water`: 600
- `bread`: 100 (critical backup food)
- `cloth`: 30
- `thread`: 20

**Total Inventory Items:** 13 commodity types

---

## 8. Detailed JSON Schema

### Schema Structure (Detailed Format)

```json
{
  "version": "1.0.0",
  "description": "Specialty starter towns - CFP prototype (no gold/currency)",
  "note": "Uses detailed schema with positions, worker assignments, and family relations",

  "towns": [
    {
      "id": "unique_town_id",
      "name": "Town Name",
      "displayName": "City - Description",
      "city": "City Name",
      "specialty": "specialty_commodity_id",
      "difficulty": "easy|medium|hard",
      "difficultyScore": 16.5,
      "description": "Full narrative description...",

      "starterBuildings": [
        {
          "typeId": "building_type_id",
          "recipeName": "Specific Recipe Name",
          "workers": 2,
          "ownerCitizenIndex": 0,
          "position": {"x": 100, "y": 100},
          "initialOccupants": [3, 4, 5]
        }
      ],

      "starterCitizens": [
        {
          "name": "Full Name",
          "vocation": "worker_type_id",
          "class": "lower|middle|upper",
          "age": 35,
          "workplaceIndex": 5,
          "housingIndex": 7,
          "familyRelation": {
            "type": "spouse|child|parent",
            "targetIndex": 0
          }
        }
      ],

      "starterInventory": [
        {
          "commodityId": "commodity_id",
          "quantity": 500
        }
      ],

      "population": {
        "initialCount": 10,
        "targetSurvivalCycles": 20,
        "cycleDefinition": "Time for slowest production building to complete one batch"
      }
    }
  ]
}
```

### Key Field Definitions

| Field | Type | Description |
|-------|------|-------------|
| `typeId` | string | Must match `id` in `building_types.json` |
| `recipeName` | string | Must match `recipeName` in `building_recipes.json` |
| `ownerCitizenIndex` | integer | Index into `starterCitizens` array (for business buildings) |
| `workplaceIndex` | integer | Index into `starterBuildings` array (where citizen works) |
| `housingIndex` | integer | Index into `starterBuildings` array (where citizen lives) |
| `initialOccupants` | array | List of citizen indices who live in this housing |
| `vocation` | string | Must match `id` in `worker_types.json` |
| `class` | string | `lower`, `middle`, or `upper` |
| `familyRelation` | object | Links to another citizen by index |

---

## 9. Missing Worker Types Analysis

### Required Vocations (from all 4 towns)

1. **Street Food Cook** - Vada Pav, Poha towns
2. **Restaurant Cook** - Dosa town
3. **Grain Processor** - Poha, Rasogulla towns
4. **Oil Presser** - Vada Pav, Poha, Dosa towns
5. **Baker** - Vada Pav town
6. **Sweet Maker** - Rasogulla town
7. **Dairy Worker** - Rasogulla town
8. **Sugar Processor** - Rasogulla town
9. **Animal Herder** - Rasogulla town
10. **Farmer** - All towns
11. **Apprentice** - Family member role (child worker)

### Existing in `worker_types.json`
- ✅ `farmer`
- ✅ `baker`
- ✅ `cook` (generic, but NOT "Restaurant Cook" or "Street Food Cook")

### Need to Add
- ❌ `street_food_cook`
- ❌ `restaurant_cook`
- ❌ `grain_processor`
- ❌ `oil_presser`
- ❌ `sweet_maker`
- ❌ `dairy_worker`
- ❌ `sugar_processor`
- ❌ `animal_herder`
- ❌ `apprentice`

**Total to Add:** 9 new worker types

---

## 10. Verification Checklist

### Data Integrity
- [ ] All `buildingType` IDs exist in `building_types.json`
- [ ] All `recipeName` IDs exist in `building_recipes.json`
- [ ] All `commodityId` IDs exist in `commodities.json`
- [ ] All `vocation` IDs exist in `worker_types.json` (after additions)

### Balance Validation
- [ ] Vada Pav Town: 30 cycles × 25 min = 12.5 hours survival ✓
- [ ] Poha Town: 30 cycles × 40 min = 20 hours survival ✓
- [ ] Dosa Town: 20 cycles × 180 min = 60 hours survival ✓
- [ ] Rasogulla Town: 10 cycles × 180 min = 30 hours survival ✓

### Production Chain Validation
- [ ] Each town has complete supply chain (no missing buildings)
- [ ] Starting inventory sufficient for survival period
- [ ] Worker assignments match building requirements
- [ ] Housing capacity ≥ citizen count

### Schema Validation
- [ ] All citizen indices valid (workplaceIndex, housingIndex)
- [ ] All building indices valid (ownerCitizenIndex, initialOccupants)
- [ ] Family relations form valid links
- [ ] No circular dependencies

### CFP Prototype Compliance
- [ ] NO gold fields anywhere
- [ ] NO wage/salary fields
- [ ] NO currency references
- [ ] Pure production-consumption model

---

## 11. Implementation Sequence

### Step 1: Add Worker Types
- Update `data/alpha/worker_types.json`
- Add all 9 missing worker types

### Step 2: Update Starting Towns JSON
- Replace simplified schema with detailed schema
- Implement all 4 towns with complete data
- Validate all references

### Step 3: Verification
- Run JSON syntax validation
- Verify all commodity/building/recipe references
- Check production balance calculations
- Test survival duration calculations

### Step 4: Linear Issue Updates
- Update CRAVE-11 description
- Update CRAVE-15 description

---

## 12. Acceptance Criteria

CRAVE-11 is **COMPLETE** when:

1. ✅ All 4 towns fully specified in this design document
2. ✅ Production chains balanced and verified with bottleneck analysis
3. ✅ Starting resources calculated for tier-based survival (Easy: 30, Medium: 20, Hard: 10 cycles)
4. ✅ Difficulty ratings assigned with explicit formula and criteria
5. ✅ 9 new worker types added to `worker_types.json`
6. ✅ `starting_towns.json` implemented with detailed schema (positions, worker indices, family relations)
7. ✅ All JSON validates with no syntax errors
8. ✅ All references verified (no orphaned commodity/building/recipe/worker IDs)
9. ✅ Linear issues CRAVE-11 and CRAVE-15 updated to reflect current scope
10. ✅ NO gold/currency/wage fields in any new content

---

**End of Design Document**

**Next Steps:**
1. Implement worker types additions
2. Implement detailed starting_towns.json
3. Update Linear issues
4. Final verification
