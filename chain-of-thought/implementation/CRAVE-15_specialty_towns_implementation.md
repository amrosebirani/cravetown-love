# CRAVE-15: Specialty Starting Towns Implementation Plan

**Created:** 2025-12-28
**Status:** Ready for Implementation
**Branch:** `feat/specialty-starting-towns` (separate from feat/tea-coffee-implementation)
**Type:** Prototype - No Gold/Currency System

---

## Executive Summary

Create 4 Indian specialty starter towns as a **separate launcher option** with complete supply chains. Each town focuses on producing one signature dish and can survive 20+ production cycles independently.

**Key Constraint:** CFP prototype has **NO gold/wages/currency** - pure production-consumption mechanics only.

---

## 1. The Four Towns

### 🥟 Samosa Town (Mumbai)
**Specialty:** Samosa
**Difficulty:** ⭐ Easy
**Description:** "The aroma of fried samosas fills the air as vendors call out to customers on bustling Mumbai streets. Workers gather around steaming pots of oil, rhythmically folding triangular pockets of spiced potato filling. The sizzle of deep-frying echoes through narrow lanes where generations have perfected this golden street food."

**Supply Chain:**
```
Potato Farm (2 workers) ──┐
                          ├──► Flour Mill (1 worker) ──┐
Wheat Farm (2 workers) ───┘                            ├──► Street Food Kitchen (2 workers) ──► SAMOSA
                                                       │
Groundnut Farm (1 worker) ──► Oil Press (1 worker) ───┘
```

**Status:** ✅ **COMPLETE** - All buildings, commodities, and recipes exist!

---

### 🍔 Vada Pav Town (Mumbai)
**Specialty:** Vada Pav (Vada + Pav combo)
**Difficulty:** ⭐ Easy
**Description:** "Mumbai's beloved street snack comes alive in this bustling town. The sharp crack of fried vada contrasts with the soft warmth of freshly baked pav buns. Chutney vendors add their secret blends as workers shuttle between fryers and ovens, creating the perfect harmony of crispy and fluffy."

**Supply Chain:**
```
Potato Farm (2 workers) ──► Street Food Kitchen (2 workers) ──► VADA ──┐
                                                                       ├──► Served together
Wheat Farm (2 workers) ──► Flour Mill (1 worker) ──► Bakery (1 worker) ──► PAV ──┘
```

**Missing:**
- ❌ `pav` commodity (bread bun)
- ❌ Bakery recipe: Pav Baking

---

### 🥞 Dosa Town (Bangalore)
**Specialty:** Dosa
**Difficulty:** ⭐⭐ Medium
**Description:** "The gentle hiss of dosa batter hitting hot griddles creates a morning symphony in Bangalore's breakfast capital. Rice paddies shimmer in the distance as workers mill grains into fine flour. The tangy aroma of fermented batter mingles with fresh coconut chutney, a testament to centuries of South Indian culinary tradition."

**Supply Chain:**
```
Rice Paddy (2 workers) ──► Rice Mill (1 worker) ──┐
                                                   ├──► Street Food Kitchen (2 workers) ──► DOSA
Lentil Farm (2 workers) ──────────────────────────┘
                          (dal/urad_dal)
```

**Missing:**
- ❌ `rice_mill` building type
- ❌ Rice Mill recipe: Rice → Rice Flour
- ❌ Street Food Kitchen recipe: Dosa Making (may exist - needs verification)

---

### 🍡 Rasogulla Town (Kolkata)
**Specialty:** Rasogulla
**Difficulty:** ⭐⭐ Medium
**Description:** "Sweet shops line the streets of this Kolkata-inspired haven, where workers carefully knead paneer into perfect spheres. Sugarcane fields sway nearby as mills crush their golden stalks. The fragrance of cardamom-infused sugar syrup drifts through the air, promising the spongy delight of freshly made rasogulla."

**Supply Chain:**
```
Sugarcane Farm (2 workers) ──► Sugar Mill (1 worker) ───┐
                                                         ├──► Sweet Shop (2 workers) ──► RASOGULLA
Dairy (2 workers) ──────────► Paneer Production ────────┘
```

**Missing:**
- ❌ `rasogulla` commodity
- ❌ Sweet Shop recipe: Rasogulla Making
- ⚠️ Verify: Can Farm grow sugarcane? (or does sugarcane_cutting already exist?)

---

## 2. Missing Pieces Analysis

### A. Commodities to Add

| Commodity ID | Name | Category | Icon | Base Value | Dependencies | Quality | Perishable |
|-------------|------|----------|------|------------|--------------|---------|------------|
| `pav` | Pav | processed_food | Pv | 3 | flour | basic | true |
| `flattened_rice` | Flattened Rice | processed_food | FR | 4 | rice | basic | false |
| `poha` | Poha | prepared_food | Po | 6 | flattened_rice, onion, oil | good | true |
| `rasogulla` | Rasogulla | sweet | Rg | 8 | paneer, sugar | luxury | false |

**Notes:**
- Using existing `dal` for dosa (not adding separate `urad_dal`)
- `flattened_rice` is intermediate product, `poha` is final dish
- Rasogulla not perishable due to sugar preservation

---

### B. Buildings to Add

#### Rice Mill
```json
{
  "id": "rice_mill",
  "name": "Rice Mill",
  "category": "production",
  "label": "RM",
  "color": [0.85, 0.8, 0.7],
  "description": "Processes rice into flour or flattened rice",
  "workCategories": ["Grain Processing", "General Labor"],
  "workerEfficiency": {
    "Grain Processing": 1.0,
    "General Labor": 0.5
  },
  "upgradeLevels": [
    {
      "level": 0,
      "name": "Basic Rice Mill",
      "description": "A basic rice mill with 2 work stations",
      "stations": 2,
      "width": 56,
      "height": 56,
      "constructionMaterials": {
        "wood": 40,
        "stone": 30
      },
      "storage": {
        "inputCapacity": 200,
        "outputCapacity": 180
      }
    }
  ]
}
```

---

### C. Recipes to Add

#### 1. Rice Mill - Rice Flour Production
```json
{
  "buildingType": "rice_mill",
  "name": "Rice Mill",
  "recipeName": "Rice Milling",
  "category": "Production",
  "productionTime": 1800,
  "inputs": {
    "rice": 50
  },
  "outputs": {
    "rice_flour": 45
  },
  "notes": "30 minutes. Grinds 50 rice into 45 rice flour for dosa."
}
```

#### 2. Rice Mill - Flattened Rice Production
```json
{
  "buildingType": "rice_mill",
  "name": "Rice Mill",
  "recipeName": "Rice Flattening",
  "category": "Production",
  "productionTime": 1800,
  "inputs": {
    "rice": 50
  },
  "outputs": {
    "flattened_rice": 48
  },
  "notes": "30 minutes. Flattens 50 rice into 48 flattened rice (poha/chivda)."
}
```

#### 3. Bakery - Pav Baking
```json
{
  "buildingType": "bakery",
  "name": "Bakery",
  "recipeName": "Pav Baking",
  "category": "Consumable",
  "productionTime": 300,
  "inputs": {
    "flour": 8
  },
  "outputs": {
    "pav": 12
  },
  "notes": "5 minutes. Bakes 8 flour into 12 pav buns."
}
```

#### 4. Street Food Kitchen - Poha Making
```json
{
  "buildingType": "street_food_kitchen",
  "name": "Street Food Kitchen",
  "recipeName": "Poha Making",
  "category": "Production",
  "productionTime": 900,
  "inputs": {
    "flattened_rice": 10,
    "onion": 2,
    "oil": 1,
    "spices": 1
  },
  "outputs": {
    "poha": 12
  },
  "notes": "15 minutes. Cooks flattened rice with onions and spices into 12 servings of poha."
}
```

#### 5. Street Food Kitchen - Dosa Making
```json
{
  "buildingType": "street_food_kitchen",
  "name": "Street Food Kitchen",
  "recipeName": "Dosa Making",
  "category": "Production",
  "productionTime": 10800,
  "inputs": {
    "rice_flour": 10,
    "dal": 5,
    "oil": 1
  },
  "outputs": {
    "dosa": 20
  },
  "notes": "3 hours (includes fermentation). Rice flour + lentils produces 20 dosas."
}
```

#### 6. Sweet Shop - Rasogulla Making
```json
{
  "buildingType": "sweet_shop",
  "name": "Sweet Shop",
  "recipeName": "Rasogulla Making",
  "category": "Production",
  "productionTime": 2400,
  "inputs": {
    "paneer": 5,
    "sugar": 3
  },
  "outputs": {
    "rasogulla": 10
  },
  "notes": "40 minutes. Kneads paneer into balls and simmers in sugar syrup to produce 10 rasogullas."
}
```

---

## 3. JSON Structure: starting_towns.json

**Location:** `data/starting_towns/starting_towns.json`

### Schema Design

```json
{
  "version": "1.0.0",
  "description": "Specialty starter towns - CFP prototype (no gold/currency)",
  "note": "These towns are designed for pure production-consumption balance testing",

  "towns": [
    {
      "id": "samosa_mumbai",
      "name": "Samosa Town",
      "displayName": "Mumbai - Street Food Capital",
      "city": "Mumbai",
      "specialty": "samosa",
      "difficulty": "easy",
      "difficultyStars": 1,
      "description": "The aroma of fried samosas fills the air...",

      "starterBuildings": [
        {
          "typeId": "farm",
          "recipeName": "Potato Farming",
          "workers": 2,
          "position": {"x": 100, "y": 100}
        },
        {
          "typeId": "farm",
          "recipeName": "Wheat Farming",
          "workers": 2,
          "position": {"x": 250, "y": 100}
        },
        {
          "typeId": "farm",
          "recipeName": "Groundnut Farming",
          "workers": 1,
          "position": {"x": 400, "y": 100}
        },
        {
          "typeId": "flour_mill",
          "workers": 1,
          "position": {"x": 175, "y": 250}
        },
        {
          "typeId": "oil_press",
          "workers": 1,
          "position": {"x": 325, "y": 250}
        },
        {
          "typeId": "street_food_kitchen",
          "recipeName": "Samosa Making",
          "workers": 2,
          "ownerCitizenIndex": 0,
          "position": {"x": 250, "y": 400}
        },
        {
          "typeId": "lodge",
          "position": {"x": 500, "y": 250},
          "initialOccupants": [3, 4, 5, 6, 7, 8]
        },
        {
          "typeId": "cottage",
          "position": {"x": 600, "y": 250},
          "initialOccupants": [0, 1, 2]
        }
      ],

      "starterCitizens": [
        {
          "name": "Ramesh Patel",
          "vocation": "Street Food Vendor",
          "class": "middle",
          "workplaceIndex": 5,
          "housingIndex": 7,
          "age": 35
        },
        {
          "name": "Sunita Patel",
          "vocation": "Street Food Vendor",
          "class": "middle",
          "workplaceIndex": 5,
          "housingIndex": 7,
          "age": 32,
          "familyRelation": {"type": "spouse", "targetIndex": 0}
        },
        {
          "name": "Amit Patel",
          "vocation": "Apprentice",
          "class": "lower",
          "workplaceIndex": 5,
          "housingIndex": 7,
          "age": 14,
          "familyRelation": {"type": "child", "targetIndex": 0}
        },
        {
          "name": "Vijay Sharma",
          "vocation": "Farmer",
          "class": "lower",
          "workplaceIndex": 0,
          "housingIndex": 6,
          "age": 28
        },
        {
          "name": "Priya Desai",
          "vocation": "Farmer",
          "class": "lower",
          "workplaceIndex": 1,
          "housingIndex": 6,
          "age": 26
        },
        {
          "name": "Rajesh Kumar",
          "vocation": "Miller",
          "class": "lower",
          "workplaceIndex": 3,
          "housingIndex": 6,
          "age": 30
        },
        {
          "name": "Kavita Gupta",
          "vocation": "Oil Presser",
          "class": "lower",
          "workplaceIndex": 4,
          "housingIndex": 6,
          "age": 24
        },
        {
          "name": "Anil Rao",
          "vocation": "Farmer",
          "class": "lower",
          "workplaceIndex": 2,
          "housingIndex": 6,
          "age": 22
        },
        {
          "name": "Meena Singh",
          "vocation": "Laborer",
          "class": "lower",
          "workplaceIndex": 0,
          "housingIndex": 6,
          "age": 29
        }
      ],

      "starterInventory": [
        {"commodityId": "potato_seed", "quantity": 80},
        {"commodityId": "wheat_seed", "quantity": 80},
        {"commodityId": "groundnut_seed", "quantity": 60},
        {"commodityId": "potato", "quantity": 120},
        {"commodityId": "wheat", "quantity": 100},
        {"commodityId": "groundnut", "quantity": 70},
        {"commodityId": "flour", "quantity": 50},
        {"commodityId": "oil", "quantity": 30},
        {"commodityId": "spices", "quantity": 20},
        {"commodityId": "samosa", "quantity": 60},
        {"commodityId": "water", "quantity": 200},
        {"commodityId": "bread", "quantity": 40},
        {"commodityId": "cloth", "quantity": 30},
        {"commodityId": "thread", "quantity": 20}
      ],

      "population": {
        "initialCount": 9,
        "targetSurvivalCycles": 20
      }
    }
  ]
}
```

**Key Fields:**
- `workplaceIndex` / `housingIndex` - reference `starterBuildings` array
- `ownerCitizenIndex` - building owner (for businesses)
- `recipeName` - specific recipe to assign (not just autoAssign)
- NO gold/wealth fields anywhere
- `initialOccupants` - who lives in housing

---

## 4. Resource Balance Calculations

### Methodology

**Formula:**
```
Starting Inventory = (Production Cycle Time × Target Cycles × Buffer) + Emergency Reserve
```

**Assumptions:**
- 9 citizens average per town
- 20 production cycles target
- 1 cycle = 60 seconds (1 minute game time)
- Buffer = 1.5x (50% safety margin)

### Example: Samosa Town

**Production Rates:**
- Potato Farm: 80 potatoes / 2 hours (120 cycles)
- Wheat Farm: 80 wheat / 2 hours (120 cycles)
- Groundnut Farm: 50 groundnut / 2 hours (120 cycles)
- Flour Mill: 50 wheat → 45 flour / 30 min (30 cycles)
- Oil Press: 30 groundnut → 25 oil / 30 min (30 cycles)
- Street Food Kitchen: 3 flour + 10 potato + 2 oil + 1 spices → 15 samosa / 30 min

**Consumption per Citizen per Day (assumed):**
- Biological (food): 6-8 units
- Water: 15 units
- Clothing: 0.2 units (slow decay)

**Starting Inventory Rationale:**

Seeds (enough for 4 harvest cycles):
- potato_seed: 80 (covers 4 plantings)
- wheat_seed: 80
- groundnut_seed: 60

Raw Materials (2 production cycles worth):
- potato: 120 (2 × 60 needed for batch)
- wheat: 100
- groundnut: 70

Processed (immediate buffer):
- flour: 50 (ready for immediate samosa production)
- oil: 30
- spices: 20 (slow consumption)

Final Product:
- samosa: 60 (3 days worth for 9 citizens)

Essentials:
- water: 200 (covers 1.5 days for 9 citizens)
- bread: 40 (backup food)
- cloth/thread: 30/20 (slow consumption)

---

## 5. Implementation Task Breakdown

### Phase 1: Add Commodities ✅
**Files:** `data/alpha/commodities.json`

**Tasks:**
1. Add `pav` commodity (after `bread`, before `flour`)
2. Add `flattened_rice` commodity (after `rice`, with other rice products)
3. Add `poha` commodity (in prepared_food section, near samosa)
4. Add `rasogulla` commodity (in sweet section)

**Validation:** Run search to confirm all 4 added

---

### Phase 2: Add Fulfillment Vectors ✅
**Files:** `data/alpha/craving_system/fulfillment_vectors.json`

**Tasks:**
1. Add `pav` vector (copy from bread, adjust values)
2. Add `flattened_rice` vector (minimal - intermediate product)
3. Add `poha` vector (biological + touch satisfaction)
4. Add `rasogulla` vector (biological + shiny_objects + exotic_goods)

---

### Phase 3: Add Rice Mill Building ✅
**Files:** `data/alpha/building_types.json`

**Task:** Insert `rice_mill` definition after `flour_mill` (around line 800-900)

**Validation:** Search for `"id": "rice_mill"` confirms addition

---

### Phase 4: Add Recipes ✅
**Files:** `data/alpha/building_recipes.json`

**Tasks:**
1. Add 2 rice_mill recipes (Rice Milling, Rice Flattening)
2. Add bakery recipe (Pav Baking) - after "Bread Baking"
3. Add street_food_kitchen recipe (Poha Making) - after existing street food recipes
4. Verify/add street_food_kitchen recipe (Dosa Making)
5. Add sweet_shop recipe (Rasogulla Making)

**Validation:**
- Search for each recipeName
- Check recipe inputs/outputs match commodity IDs

---

### Phase 5: Create Starting Towns JSON ✅
**Files:** `data/starting_towns/starting_towns.json` (NEW FILE)

**Tasks:**
1. Create directory: `data/starting_towns/`
2. Create JSON file with schema
3. Define Samosa Town (complete)
4. Define Vada Pav Town
5. Define Dosa Town
6. Define Rasogulla Town

**Validation:**
- JSON syntax valid
- All commodityId references exist
- All buildingType references exist
- All recipeName references exist
- Citizen count matches housing capacity

---

### Phase 6: Verification & Testing ✅

**Checklist:**
- [ ] All 4 new commodities searchable in commodities.json
- [ ] All 4 new fulfillment vectors in fulfillment_vectors.json
- [ ] rice_mill building exists with 2 upgrade levels
- [ ] 6 new recipes added to building_recipes.json
- [ ] starting_towns.json has all 4 towns
- [ ] Each town has 8-12 citizens
- [ ] Each town has complete supply chain (no missing buildings)
- [ ] Starting inventory calculated for 20+ cycle survival
- [ ] NO gold/wealth/wage fields anywhere

---

## 6. Post-Implementation

**NOT included in this task:**
- Lua integration code (NewGameSetup.lua)
- Launcher UI changes
- Loading logic (StarterTownLoader.lua)
- Testing in-game

**These will be separate CRAVE tasks**

---

## 7. Acceptance Criteria

✅ **This task is COMPLETE when:**
1. All 4 commodities added to commodities.json
2. All 4 fulfillment vectors added
3. rice_mill building type exists
4. All 6 recipes added to building_recipes.json
5. starting_towns.json file created with all 4 towns fully specified
6. All JSON files validate (no syntax errors)
7. All references verified (no orphaned commodity/building IDs)
8. NO gold/currency references in any new content

---

## 8. Quick Reference

### Commodities Added
- `pav` - Bread bun
- `flattened_rice` - Beaten rice (intermediate)
- `poha` - Flattened rice dish
- `rasogulla` - Spongy sweet

### Buildings Added
- `rice_mill` - Rice processing

### Recipes Added
- Rice Mill: Rice Milling (rice → rice_flour)
- Rice Mill: Rice Flattening (rice → flattened_rice)
- Bakery: Pav Baking (flour → pav)
- Street Food Kitchen: Poha Making (flattened_rice + onion + oil + spices → poha)
- Street Food Kitchen: Dosa Making (rice_flour + dal + oil → dosa)
- Sweet Shop: Rasogulla Making (paneer + sugar → rasogulla)

### Files Modified
1. `data/alpha/commodities.json` (+4 commodities)
2. `data/alpha/craving_system/fulfillment_vectors.json` (+4 vectors)
3. `data/alpha/building_types.json` (+1 building: rice_mill)
4. `data/alpha/building_recipes.json` (+6 recipes)

### Files Created
1. `data/starting_towns/starting_towns.json` (NEW)

---

**End of Implementation Plan**
