# Cravetown: Commodity-Focus Prototype (CFP) - Final Design Document

## Executive Summary

The Commodity-Focus Prototype (CFP) is a simplified, focused implementation of Cravetown that introduces players to the core economic simulation through four culturally-significant Indian dishes. Each commodity represents a complete production chain tied to a specific Indian city, creating an accessible entry point while maintaining the game's sophisticated craving and economic systems.

**Document Status:** WIP
**Last Updated:** December 17, 2024
**Version:** 3.0 (Final)

---

## Table of Contents

1. [Core Concept](#1-core-concept)
2. [Commodity Specifications](#2-commodity-specifications)
3. [Craving Satisfaction Mapping](#3-craving-satisfaction-mapping)
4. [Game Flow Architecture](#4-game-flow-architecture)
5. [Technical Implementation Requirements](#5-technical-implementation-requirements)
6. [Conflict Resolution & Solutions](#6-conflict-resolution--solutions)
7. [Development Roadmap](#7-development-roadmap)
8. [Future Expansion Paths](#8-future-expansion-paths)
9. [Technical Specifications](#9-technical-specifications)
10. [Success Metrics](#10-success-metrics)
11. [Risk Analysis](#11-risk-analysis)
12. [Appendices](#appendices)

---

## 1. Core Concept

### 1.1 Overview

CFP allows players to choose ONE of four commodity-town combinations:

1. **Vada Pav** (Mumbai) - Street food icon, medium complexity
2. **Dosa** (Bangalore) - Fermented delicacy, high complexity
3. **Poha** (Indore) - Quick breakfast dish, low complexity
4. **Rasgolla** (Kolkata) - Sweet specialty, very high complexity

Each choice initiates a town pre-configured with:
- City-specific aesthetics and naming conventions
- Appropriate building types for that commodity's production chain
- Character types aligned with the production needs
- Recipe-specific resource requirements
- Starting inventory of basic ingredients

### 1.2 Design Philosophy

- **Focused Learning**: Master one production chain before scaling complexity
- **Cultural Authenticity**: Each commodity reflects its city's culinary heritage
- **Economic Fundamentals**: Teach supply chains, resource allocation, and market dynamics
- **Multiplayer Foundation**: Build towards inter-town trading (Phase 4)

### 1.3 Key Innovations

1. **Recipe-based Production System**: Multi-ingredient production with time/quality management
2. **Multi-Craving Satisfaction**: Single commodity satisfies multiple craving types
3. **Rupee Economy**: Currency system (₹) for wages, building costs, and trading
4. **Specialized Buildings**: "Dish Shops" with advanced production logic
5. **Cultural Immersion**: Authentic Indian street food economy simulation

---

## 2. Commodity Specifications

### 2.1 Vada Pav (Mumbai)

#### Recipe Components

**Base Ingredients:**
- Potatoes (Primary) - 2 units
- Wheat Flour - 1 unit
- Gram Flour (Besan) - 1 unit
- Green Chilies - 0.5 units
- Garlic - 0.5 units
- Spices (Turmeric, Mustard Seeds) - 0.25 units
- Oil - 1 unit

**Finished Product:** 1 Vada Pav = 12 Total Satisfaction Points

#### Production Chain Buildings

1. **Farm** → Produces: Potatoes, Green Chilies, Garlic
2. **Mill** → Processes: Wheat → Wheat Flour, Gram → Gram Flour
3. **Spice Grinder** → Processes: Raw Spices → Ground Spices
4. **Vada Pav Shop** ✨ → Combines all ingredients → Vada Pav

*(✨ = New specialized building for CFP)*

#### Character Types Needed

- 3x Farmers (Potato, Chili, Garlic specializations)
- 2x Millers
- 1x Spice Worker
- 2x Cooks (generic cook role, assigned to Vada Pav Shop)

#### Production Stats

- **Production Time:** 120 seconds per batch (2 cooks)
- **Batch Size:** 10 Vada Pav per cycle
- **Difficulty:** ⭐⭐⭐ Medium (Beginner-friendly)
- **Starting Rupees:** ₹1,000

---

### 2.2 Dosa (Bangalore)

#### Recipe Components

**Base Ingredients:**
- Rice - 3 units
- Urad Dal (Black Lentils) - 1 unit
- Fenugreek Seeds - 0.25 units
- Salt - 0.25 units
- Water - 2 units
- Oil - 0.5 units

**Optional Filling (Masala Dosa):**
- Potatoes - 2 units
- Onions - 1 unit
- Curry Leaves - 0.5 units
- Spices - 0.5 units

**Finished Product:** 1 Dosa = 15 points, 1 Masala Dosa = 18 points

#### Production Chain Buildings

1. **Paddy Farm** → Produces: Rice, Urad Dal
2. **Spice Farm** → Produces: Fenugreek, Curry Leaves
3. **Mill** → Processes: Rice + Urad Dal → Dosa Batter
4. **Dosa Kitchen** ✨ → Fermentation (8 hrs) → Dosa/Masala Dosa

#### Character Types Needed

- 3x Farmers (Rice, Dal, Spice specializations)
- 2x Millers (includes fermentation specialist)
- 3x Cooks (generic cook role, assigned to Dosa Kitchen)

#### Production Stats

- **Fermentation Time:** 8 in-game hours (automatic)
- **Cooking Time:** 60 seconds per dosa
- **Batch Size:** 8 dosa per cycle
- **Difficulty:** ⭐⭐⭐⭐ High (Fermentation complexity)
- **Starting Rupees:** ₹1,200

---

### 2.3 Poha (Indore)

#### Recipe Components

**Base Ingredients:**
- Flattened Rice (Poha) - 2 units
- Potatoes - 1 unit
- Onions - 1 unit
- Peanuts - 0.5 units
- Green Chilies - 0.5 units
- Curry Leaves - 0.25 units
- Mustard Seeds - 0.25 units
- Turmeric - 0.25 units
- Lemon Juice - 0.25 units
- Oil - 0.5 units

**Garnish:**
- Coriander Leaves - 0.25 units
- Sev (Gram Flour Noodles) - 0.25 units

**Finished Product:** 1 Poha = 11 Total Satisfaction Points

#### Production Chain Buildings

1. **Paddy Farm** → Produces: Rice
2. **Vegetable Farm** → Produces: Potatoes, Onions, Green Chilies, Coriander
3. **Rice Flattening Mill** → Processes: Rice → Flattened Rice (Poha)
4. **Oil Mill** → Processes: Peanuts → Peanut Oil (+ Peanuts for garnish)
5. **Spice Grinder** → Processes: Raw Spices → Ground Spices
6. **Poha Kitchen** ✨ → Combines all ingredients → Poha

#### Character Types Needed

- 4x Farmers (Rice, Vegetable, Peanut specializations)
- 2x Millers (Rice + Oil)
- 1x Spice Worker
- 2x Cooks (generic cook role, assigned to Poha Kitchen)

#### Production Stats

- **Production Time:** 90 seconds per batch
- **Batch Size:** 12 Poha per cycle
- **Difficulty:** ⭐⭐ Low (Fast, beginner-friendly)
- **Starting Rupees:** ₹800

---

### 2.4 Rasgolla (Kolkata)

#### Recipe Components

**Base Ingredients:**
- Milk - 5 units
- Lemon Juice / Vinegar - 0.5 units
- Sugar - 2 units
- Water - 3 units
- Cardamom - 0.25 units
- Rose Water - 0.25 units (optional)

**Finished Product:** 1 Rasgolla Serving (6 pieces) = 20 Total Satisfaction Points

#### Production Chain Buildings

1. **Dairy Farm** → Produces: Milk (from Cows)
2. **Sugar Mill** → Processes: Sugarcane → Sugar
3. **Citrus Farm** → Produces: Lemons
4. **Spice Farm** → Produces: Cardamom
5. **Sweet Shop (Mithai Shop)** ✨ → Processes: All ingredients → Rasgolla

#### Character Types Needed

- 3x Farmers (Dairy, Sugarcane, Citrus/Spice specializations)
- 1x Sugar Miller
- 3x Cooks (generic cook role, sweet-making specialists)

#### Production Stats

- **Production Time:** 300 seconds per batch (includes boiling)
- **Batch Size:** 4 rasgolla servings (24 pieces) per cycle
- **Difficulty:** ⭐⭐⭐⭐⭐ Very High (Complex process, quality-sensitive)
- **Starting Rupees:** ₹1,500

---

## 3. Craving Satisfaction Mapping

### 3.1 Ingredient-Level Cravings

Each raw ingredient satisfies base cravings:

| Ingredient Category | Craving Type | Satisfaction Points |
|-------------------|--------------|-------------------|
| **Grains (Rice, Wheat)** | Biological | 5 |
| **Vegetables (Potato, Onion)** | Biological | 4 |
| **Proteins (Dal, Milk)** | Biological | 6 |
| **Spices** | Sensory | 3 |
| **Oil/Fats** | Biological | 3 |
| **Sugar** | Sensory | 4 |
| **Chilies** | Sensory | 3 |

### 3.2 Finished Product Cravings (Multi-Craving System)

**✅ IMPLEMENTED:** Finished goods satisfy multiple craving types simultaneously.

#### Vada Pav
- Biological: 6 points (filling, satisfying)
- Sensory: 4 points (spicy, aromatic)
- Social Status: 2 points (street food culture, Mumbai identity)
- **Total: 12 points across 3 craving types**

#### Dosa
- Biological: 5 points (nutritious, fermented)
- Sensory: 5 points (crispy texture, fermented tang)
- Touch: 2 points (warmth, comfort)
- Emotional & Psychological: 3 points (South Indian tradition)
- **Total: 15 points across 4 craving types**

#### Poha
- Biological: 5 points (light, nutritious)
- Sensory: 4 points (textural variety, aromatic)
- Social Status: 2 points (breakfast culture)
- **Total: 11 points across 3 craving types**

#### Rasgolla
- Sensory: 8 points (sweet, soft, unique texture)
- Exotic Goods: 4 points (special occasion treat)
- Shiny Objects: 3 points (white, pristine appearance)
- Emotional & Psychological: 5 points (Bengali cultural pride, celebrations)
- **Total: 20 points across 4 craving types**

### 3.3 Quality & Rarity Modifiers

**Quality Tiers for Finished Products:**

| Quality | Ingredient Quality | Satisfaction Multiplier |
|---------|-------------------|----------------------|
| Poor | Low-quality inputs, expired | 0.7x |
| Basic | Standard quality, fresh | 1.0x |
| Good | High-quality inputs, skilled prep | 1.3x |
| Luxury | Premium ingredients, master chef | 1.6x |

**Rarity Scoring:**
- Common ingredients (Rice, Potato): Rarity = 1.0x
- Uncommon ingredients (Specific spices): Rarity = 1.1x
- Rare ingredients (Premium Dairy): Rarity = 1.3x
- Exotic ingredients (Imported items): Rarity = 1.5x

---

## 4. Game Flow Architecture

### 4.1 Initial Setup Flow

```
[Game Launch]
    ↓
[CFP Mode Selection]
    ├─→ Vada Pav (Mumbai)
    ├─→ Dosa (Bangalore)
    ├─→ Poha (Indore)
    └─→ Rasgolla (Kolkata)
    ↓
[Town Initialization]
    ├─→ Generate City-Specific Aesthetic
    ├─→ Spawn Initial Buildings (Empty)
    ├─→ Populate Character Pool (Unemployed)
    ├─→ Initialize Inventory (Starter Resources)
    └─→ Set Starting Rupee Reserve (₹)
    ↓
[Tutorial / Guided Setup] (Optional)
    ├─→ Place Required Buildings
    ├─→ Assign Workers to Buildings
    └─→ Review Recipe Requirements
    ↓
[Pre-Production Phase]
    ├─→ Verify Supply Chain Completeness
    ├─→ Initial Resource Allocation
    └─→ Character Assignment Confirmation
    ↓
[Production Phase START]
```

### 4.2 Core Game Loop (CFP Version)

```
┌─────────────────────────────────────────────┐
│       GAME LOOP (1 In-Game Day = 60s)       │
└─────────────────────────────────────────────┘
                    ↓
        ┌───────────────────────┐
        │   PHASE 1: PRODUCTION │
        └───────────────────────┘
                    ↓
    ┌──────────────────────────────────┐
    │ Farms produce raw ingredients    │
    │ Mills process ingredients        │
    │ Dish Shops combine into dishes   │
    │ Add to Town Inventory            │
    │ Pay Worker Wages (₹)             │
    └──────────────────────────────────┘
                    ↓
        ┌───────────────────────┐
        │  PHASE 2: ALLOCATION  │
        └───────────────────────┘
                    ↓
    ┌──────────────────────────────────┐
    │ Characters generate demands      │
    │ Sort by Priority Queue:          │
    │   1. Character Class             │
    │   2. Current Satisfaction Level  │
    │   3. Craving Urgency             │
    │ Distribute from Town Inventory   │
    │ → Personal Inventory             │
    └──────────────────────────────────┘
                    ↓
        ┌───────────────────────┐
        │  PHASE 3: CONSUMPTION │
        └───────────────────────┘
                    ↓
    ┌──────────────────────────────────┐
    │ Characters consume from Personal │
    │ Inventory                        │
    │ Update Satisfaction Levels       │
    │ (Multi-Craving System)           │
    │ Calculate Craving Fulfillment    │
    └──────────────────────────────────┘
                    ↓
        ┌───────────────────────┐
        │ PHASE 4: CONSEQUENCES │
        └───────────────────────┘
                    ↓
    ┌──────────────────────────────────┐
    │ Update Character Happiness       │
    │ Trigger Events:                  │
    │   - Immigration (if happy)       │
    │   - Emigration (if unhappy)      │
    │   - Production Efficiency Change │
    │ Update Town Statistics           │
    │ Rupee Balance Check              │
    └──────────────────────────────────┘
                    ↓
        ┌───────────────────────┐
        │ PHASE 5: MARKET OPEN  │
        │ 🚧 (Phase 4 Feature)  │
        └───────────────────────┘
                    ↓
    ┌──────────────────────────────────┐
    │ Calculate Surplus/Deficit        │
    │ Open Trading Interface           │
    │ Enable Inter-Town Trading        │
    │ Rupee/Barter Transactions        │
    └──────────────────────────────────┘
                    ↓
            [Loop Repeats]
```
`
### 4.3 Multiplayer Trading Flow (Future - Phase 4)

**🚧 DEFERRED TO LATER PHASE**``

See Section 6 for implementation details.

---

## 5. Technical Implementation Requirements
`
### 5.1 New Systems to Build

#### 5.1.1 Commodity Selection System

**File:** `CommoditySelector.lua`

**Status:** ✅ NEW SYSTEM - Build in Phase 1

```lua
CommoditySelector = {
    commodities = {
        vadapav = {
            id = "vadapav",
            name = "Vada Pav",
            city = "Mumbai",
            description = "Mumbai's iconic street food",
            recipe = { ... },
            buildings = { ... },
            characters = { ... },
            startingRupees = 1000
        },
        dosa = { ... },
        poha = { ... },
        rasgolla = { ... }
    }
}
```

**Required Functions:**
- `ShowCommoditySelection()` - Display selection screen UI
- `InitializeTown(commodityID)` - Setup town based on choice
- `GetCommodityRecipe(commodityID)` - Return ingredient requirements
- `GetCommodityBuildings(commodityID)` - Return required building types
- `LoadCommodityAssets(commodityID)` - Load city-specific graphics/sounds

**Conflicts:** ❌ None (entirely new system)

---

#### 5.1.2 Recipe Management System

**File:** `RecipeSystem.lua`

**Status:** ✅ NEW SYSTEM - Build in Phase 1

```lua
RecipeSystem = {
    recipes = {
        vadapav = {
            inputs = {
                { commodity = "potato", quantity = 2 },
                { commodity = "wheat_flour", quantity = 1 },
                { commodity = "gram_flour", quantity = 1 },
                { commodity = "green_chili", quantity = 0.5 },
                { commodity = "garlic", quantity = 0.5 },
                { commodity = "spices", quantity = 0.25 },
                { commodity = "oil", quantity = 1 }
            },
            output = {
                commodity = "vadapav",
                quantity = 10, -- batch size
                productionTime = 120 -- seconds
            },
            building = "vadapav_shop",
            requiredWorkers = 2
        }
    }
}
```

**Required Functions:**
- `CanProduce(recipeID, inventory)` - Check if ingredients available
- `ConsumeIngredients(recipeID, inventory)` - Remove ingredients from town inventory
- `ProduceOutput(recipeID)` - Create finished product
- `GetRecipeInfo(recipeID)` - Return recipe details for UI display
- `GetMissingIngredients(recipeID, inventory)` - Return list of shortages

**Integration Points:**
- Connects to existing `Inventory.lua`
- Extends `BuildingTypes.lua` with new production buildings
- Hooks into `Town.lua` production phase

**Conflicts:** ⚠️ See Section 6.1.1 & 6.1.2 (RESOLVED)

---

#### 5.1.3 Rupee Currency System

**File:** `CurrencySystem.lua`

**Status:** ✅ NEW SYSTEM - Build in Phase 3

```lua
CurrencySystem = {
    currencyName = "Rupee",
    currencySymbol = "₹",
    rupeeReserves = {}, -- townID → rupee amount
    transactionHistory = {}
}
```

**Required Functions:**
- `InitializeRupees(townID, startingRupees)` - Give town initial ₹
- `AddRupees(townID, amount, reason)` - Credit rupees
- `DeductRupees(townID, amount, reason)` - Debit rupees (returns success/fail)
- `GetRupeeBalance(townID)` - Check current rupees
- `RecordTransaction(fromTownID, toTownID, amount, commodityID, transactionType)`

**Integration Points:**
- Add `mRupeeReserve` to `Town.lua`
- Display rupees in UI (TopBar) with ₹ symbol
- Connect to wage payment system (Phase 3)
- Connect to Trading System (Phase 4) for purchases

**Conflicts:** ✅ RESOLVED - Currency renamed from "Gold" to "Rupee" (See Section 6.1.5)

---

#### 5.1.4 Trading & Market System (Future)

**File:** `TradingSystem.lua`

**Status:** 🚧 DEFERRED TO PHASE 4 (Multiplayer)

**See Section 6.1.3 & 6.1.4 for details**

---

### 5.2 Extensions to Existing Systems

#### 5.2.1 CommodityTypes.lua - NEW COMMODITIES

**Status:** ✅ EXTEND EXISTING - Build in Phase 1

**Add approximately 40+ new commodity types:**

**Grains & Processed:**
- `rice`, `wheat`, `wheat_flour`, `gram_flour`, `flattened_rice`, `urad_dal`

**Vegetables:**
- `potato`, `onion`, `green_chili`, `curry_leaves`, `coriander`, `garlic`

**Dairy:**
- `milk`, `chenna` (for rasgolla)

**Sugars & Sweets:**
- `sugar`, `sugarcane`, `rose_water`, `cardamom`

**Oils & Fats:**
- `oil`, `peanut`, `peanut_oil`

**Spices:**
- `turmeric`, `mustard_seeds`, `fenugreek`, `spices_generic`

**Acids:**
- `lemon`, `lemon_juice`, `vinegar`

**Finished Products:**
- `vadapav`, `dosa`, `masala_dosa`, `poha`, `rasgolla`

**Required Extension:**

```lua
-- In CommodityTypes.lua - Example for Vada Pav
{
    id = "vadapav",
    name = "Vada Pav",
    category = "prepared_food",

    -- NEW: Multi-craving arrays
    cravingCategories = {"biological", "sensory", "social_status"},
    satisfactionValue = {
        biological = 6,
        sensory = 4,
        social_status = 2
    },

    qualityTier = "basic", -- poor/basic/good/luxury
    rarity = 2, -- 1-4 scale
    perishable = true,
    shelfLife = 1, -- game days
    baseValue = 10 -- Worth 10 Rupees when sold
}
```

**Conflicts:** ✅ RESOLVED - See Section 6.1.6

**Solution:**
- Create `validate_commodity_ids.lua` script to check for duplicates
- Keep CFP commodities in separate file: `data/cfp/cfp_commodities.json`
- Load alongside existing commodities

---

#### 5.2.2 BuildingTypes.lua - NEW BUILDINGS

**Status:** ✅ EXTEND EXISTING - Build in Phase 1

**Add 11+ new building types:**

1. **Paddy Farm** (Rice production)
2. **Spice Farm** (Specialty spices)
3. **Dairy Farm** (Milk production)
4. **Sugar Mill** (Sugarcane → Sugar)
5. **Rice Flattening Mill** (Rice → Flattened Rice)
6. **Oil Mill** (Peanuts → Oil)
7. **Spice Grinder** (Raw Spices → Ground Spices)
8. **Vada Pav Shop** ✨ (Recipe: Vada Pav)
9. **Dosa Kitchen** ✨ (Recipe: Dosa, Masala Dosa)
10. **Poha Kitchen** ✨ (Recipe: Poha)
11. **Sweet Shop / Mithai Shop** ✨ (Recipe: Rasgolla)

*(✨ = Specialized dish production building)*

**Required Extension:**

```lua
-- In BuildingTypes.lua - Example for Vada Pav Shop
{
    id = "vadapav_shop",
    name = "Vada Pav Shop",
    category = "dish_production",
    isDishProduction = true, -- NEW FLAG for filtering

    size = { width = 3, height = 3 },
    cost = {
        rupees = 200,
        wood = 10,
        stone = 5
    },

    recipe = {
        recipeID = "vadapav",
        productionTime = 120, -- seconds per batch
        batchSize = 10, -- dishes per cycle
        workersRequired = 2,
        workerBonus = 0.15 -- efficiency per additional worker
    },

    -- NEW: Production state management
    productionQueue = {},
    currentProduction = {
        recipeID = nil,
        progress = 0,
        startTime = nil,
        expectedCompletion = nil
    },

    resourceStoppage = {
        isStopped = false,
        missingIngredients = {},
        stoppedAt = nil
    },

    cravingOutput = {
        primary = "biological",
        secondary = "sensory"
    }
}
```

**Conflicts:** ⚠️ See Section 6.1.1 & 6.1.2 (RESOLVED)

**Solution:** Specialized dish buildings with `isDishProduction` flag handle recipe-based production separately from existing buildings.

---

#### 5.2.3 CharacterTypes.lua - NEW SPECIALIZATIONS

**Status:** ✅ EXTEND EXISTING - Build in Phase 1

**Add specialized character types:**

- `farmer_paddy` (rice cultivation)
- `farmer_dairy` (milk production)
- `farmer_spice` (specialty crops)
- `farmer_vegetable` (vegetables)
- `miller_sugar` (sugar processing)
- `miller_rice` (rice flattening)
- `miller_oil` (oil pressing)
- `spice_worker` (spice grinding)
- **`cook`** (generic role for ALL dish shops) ✅

**Required Extension:**

```lua
-- In CharacterTypes.lua - Generic Cook Role
{
    id = "cook",
    name = "Cook",
    category = "transformer",

    -- Compatible with ALL dish shops
    compatibleWorkplaces = {
        "vadapav_shop",
        "dosa_kitchen",
        "poha_kitchen",
        "sweet_shop"
    },

    -- Base efficiency
    efficiency = {
        base = 1.0,
        satisfactionMultiplier = 0.02 -- +2% per satisfaction point above 50
    },

    -- Wage system (Phase 3)
    wages = {
        base = 50, -- Rupees per day
        skill_bonus = 10 -- Rupees per skill level
    },

    -- OPTIONAL: For future specialization system (Phase 4+)
    specialization = nil, -- Can be "vadapav", "dosa", "poha", "rasgolla"
    specializationBonus = 0.15 -- +15% efficiency when working at specialized dish
}
```

**Conflicts:** ✅ RESOLVED - See Section 6.1.7

**Solution:** Use generic "cook" role for all dish shops. Optional specialization system for future enhancement.

---

#### 5.2.4 Character.lua - MULTI-CRAVING CONSUMPTION

**Status:** ✅ EXTEND EXISTING - Build in Phase 2

**Extend `Character:ConsumeCommodity()` to handle multi-craving fulfillment:**

```lua
-- In Character.lua
function Character:ConsumeCommodity(commodityID, quantity)
    local commodityData = CommodityTypes[commodityID]

    -- NEW: Multi-craving satisfaction (for CFP finished goods)
    if commodityData.cravingCategories then
        for _, cravingType in ipairs(commodityData.cravingCategories) do
            local satisfaction = commodityData.satisfactionValue[cravingType] or 0

            -- Apply quality modifier if present
            if commodityData.qualityTier then
                local qualityMultiplier = self:GetQualityMultiplier(commodityData.qualityTier)
                satisfaction = satisfaction * qualityMultiplier
            end

            -- Apply rarity bonus if present
            if commodityData.rarity then
                local rarityBonus = self:GetRarityBonus(commodityData.rarity)
                satisfaction = satisfaction * rarityBonus
            end

            -- Update satisfaction for this craving type
            self.mSatisfactionLevels[cravingType] =
                math.min(100, self.mSatisfactionLevels[cravingType] + satisfaction)
        end
    else
        -- OLD: Single craving (backward compatible with existing commodities)
        local cravingType = commodityData.cravingCategory
        local satisfaction = commodityData.satisfaction or 0

        self.mSatisfactionLevels[cravingType] =
            math.min(100, self.mSatisfactionLevels[cravingType] + satisfaction)
    end

    -- Remove from personal inventory
    self.mPersonalInventory[commodityID] =
        (self.mPersonalInventory[commodityID] or 0) - quantity

    -- Recalculate aggregate happiness
    self:CalculateHappiness()
end

function Character:GetQualityMultiplier(qualityTier)
    local multipliers = {
        poor = 0.7,
        basic = 1.0,
        good = 1.3,
        luxury = 1.6
    }
    return multipliers[qualityTier] or 1.0
end

function Character:GetRarityBonus(rarity)
    if rarity <= 1 then return 1.0 end      -- common
    if rarity == 2 then return 1.1 end      -- uncommon
    if rarity == 3 then return 1.3 end      -- rare
    if rarity >= 4 then return 1.5 end      -- exotic
    return 1.0
end
```

**Conflicts:** ✅ RESOLVED - See Section 6.1.10

**Example Usage:**

```lua
-- When character consumes 1 Vada Pav:
-- biological: +6 points
-- sensory: +4 points
-- social_status: +2 points
-- Total: +12 satisfaction across 3 craving types
```

---

#### 5.2.5 Building.lua - DISH PRODUCTION LOGIC

**Status:** ✅ EXTEND EXISTING - Build in Phase 1

**Extend `Building:Update()` to handle specialized dish production:**

```lua
-- In Building.lua
function Building:Update(dt)
    if self.mType.isDishProduction then
        -- ===== DISH PRODUCTION LOGIC =====

        -- 1. Check for resource stoppages
        if self.resourceStoppage.isStopped then
            if self:CheckIngredientsAvailable() then
                self:ResumeProduction()
            else
                return -- Stay stopped until resources available
            end
        end

        -- 2. Process current production
        if self.currentProduction.recipeID then
            local dt_adjusted = dt

            -- Apply worker efficiency multiplier
            local efficiency = self:CalculateWorkerEfficiency()
            dt_adjusted = dt * efficiency

            self.currentProduction.progress = self.currentProduction.progress + dt_adjusted

            -- Check if production complete
            if self.currentProduction.progress >= self.mType.recipe.productionTime then
                self:CompleteProduction()
                self:StartNextInQueue()
            end
        else
            -- No current production, start next in queue
            self:StartNextInQueue()
        end

        -- 3. Handle production intervals (auto-queue management)
        self:ManageProductionInterval(dt)

    elseif self.mType.recipe then
        -- OLD STYLE: Simple recipe-based (non-dish buildings like Mill)
        RecipeSystem:ProcessRecipe(self.mType.recipe, self.mOwner:GetInventory())

    else
        -- LEGACY: Input/output logic for existing buildings
        self:ProcessInputOutput()
    end
end

function Building:CheckIngredientsAvailable()
    local recipe = RecipeSystem:GetRecipe(self.mType.recipe.recipeID)
    local inventory = self.mOwner:GetInventory()

    for _, ingredient in ipairs(recipe.inputs) do
        if inventory:GetQuantity(ingredient.commodity) < ingredient.quantity then
            return false
        end
    end
    return true
end

function Building:StartNextInQueue()
    if #self.productionQueue > 0 then
        local nextOrder = table.remove(self.productionQueue, 1)

        -- Consume ingredients
        if self:ConsumeIngredients(nextOrder.recipeID) then
            self.currentProduction = {
                recipeID = nextOrder.recipeID,
                progress = 0,
                startTime = os.time(),
                expectedCompletion = os.time() + self.mType.recipe.productionTime
            }
        else
            -- Not enough ingredients, trigger stoppage
            self.resourceStoppage.isStopped = true
            self.resourceStoppage.stoppedAt = os.time()
            self.resourceStoppage.missingIngredients = self:GetMissingIngredients(nextOrder.recipeID)

            -- Log stoppage for UI alert
            print("[STOPPAGE] " .. self.mType.name .. " stopped: Missing ingredients")
        end
    end
end

function Building:CompleteProduction()
    local recipe = RecipeSystem:GetRecipe(self.currentProduction.recipeID)
    local inventory = self.mOwner:GetInventory()

    -- Add outputs to town inventory
    for _, output in ipairs(recipe.outputs) do
        inventory:Add(output.commodity, output.quantity * self.mType.recipe.batchSize)
    end

    -- Log production for analytics
    table.insert(self.outputHistory, {
        recipeID = self.currentProduction.recipeID,
        timestamp = os.time(),
        quantity = self.mType.recipe.batchSize
    })

    -- Reset current production
    self.currentProduction = {
        recipeID = nil,
        progress = 0,
        startTime = nil,
        expectedCompletion = nil
    }

    print("[PRODUCTION] " .. self.mType.name .. " completed: " .. recipe.outputs[1].commodity)
end

function Building:ConsumeIngredients(recipeID)
    local recipe = RecipeSystem:GetRecipe(recipeID)
    local inventory = self.mOwner:GetInventory()

    -- Check all ingredients available first
    for _, ingredient in ipairs(recipe.inputs) do
        if inventory:GetQuantity(ingredient.commodity) < ingredient.quantity then
            return false -- Not enough
        end
    end

    -- Consume all ingredients
    for _, ingredient in ipairs(recipe.inputs) do
        inventory:Remove(ingredient.commodity, ingredient.quantity)
    end

    return true
end

function Building:CalculateWorkerEfficiency()
    local baseEfficiency = 1.0
    local workerCount = #self.workforce.assigned
    local requiredWorkers = self.mType.recipe.workersRequired

    -- Understaffed penalty
    if workerCount < requiredWorkers then
        baseEfficiency = baseEfficiency * (workerCount / requiredWorkers)
    end

    -- Worker bonus for extra workers
    if workerCount > requiredWorkers then
        local bonusWorkers = workerCount - requiredWorkers
        baseEfficiency = baseEfficiency + (bonusWorkers * self.mType.recipe.workerBonus)
    end

    -- Worker satisfaction modifier (calculated from assigned workers)
    local avgSatisfaction = self:GetAverageWorkerSatisfaction()
    local satisfactionModifier = 1.0 + ((avgSatisfaction - 50) * 0.02) -- ±2% per point above/below 50

    return baseEfficiency * satisfactionModifier
end

function Building:GetMissingIngredients(recipeID)
    local recipe = RecipeSystem:GetRecipe(recipeID)
    local inventory = self.mOwner:GetInventory()
    local missing = {}

    for _, ingredient in ipairs(recipe.inputs) do
        local current = inventory:GetQuantity(ingredient.commodity)
        if current < ingredient.quantity then
            table.insert(missing, {
                commodity = ingredient.commodity,
                needed = ingredient.quantity,
                current = current,
                shortage = ingredient.quantity - current
            })
        end
    end

    return missing
end
```

**Conflicts:** ✅ RESOLVED - See Section 6.1.1 & 6.1.2

**Solution:** Use `isDishProduction` flag to route to specialized production logic. Existing buildings continue using old input/output system.

---

#### 5.2.6 Town.lua - RUPEE & CFP EXTENSIONS

**Status:** ✅ EXTEND EXISTING - Build in Phase 3

**Add new variables:**

```lua
Town = {
    -- Existing
    mInventory = Inventory:new(),
    mBuildings = {},
    mCharacterPool = {},

    -- NEW FOR CFP
    mCommodityFocus = nil, -- "vadapav", "dosa", "poha", "rasgolla"
    mRupeeReserve = 1000, -- Starting rupees (₹)

    -- 🚧 Phase 4 (Multiplayer)
    mMarketListings = {}, -- Active market listings
    mTradeHistory = {}, -- Completed trades

    mProductionStats = {
        targetCommodity = 0,
        totalProduced = 0,
        surplusDeficit = 0
    }
}
```

**New Methods:**

```lua
function Town:GetCommodityFocus()
    return self.mCommodityFocus
end

function Town:SetCommodityFocus(commodityID)
    self.mCommodityFocus = commodityID
end

function Town:GetRupeeBalance()
    return self.mRupeeReserve
end

function Town:AddRupees(amount, reason)
    self.mRupeeReserve = self.mRupeeReserve + amount
    print("[RUPEE] +" .. amount .. " (Reason: " .. reason .. ")")
end

function Town:DeductRupees(amount, reason)
    if self.mRupeeReserve >= amount then
        self.mRupeeReserve = self.mRupeeReserve - amount
        print("[RUPEE] -" .. amount .. " (Reason: " .. reason .. ")")
        return true
    else
        print("[RUPEE] INSUFFICIENT FUNDS: Need " .. amount .. ", Have " .. self.mRupeeReserve)
        return false
    end
end

-- 🚧 Phase 3: Wage System
function Town:PayWages()
    local totalWages = 0

    for _, char in ipairs(self.mCharacterPool) do
        if char.employment and char.employment.building then
            local wage = char.dailyWage or 50 -- default ₹50/day

            if self:DeductRupees(wage, "Wage: " .. char.name) then
                totalWages = totalWages + wage

                -- Increase character satisfaction for being paid
                char.mSatisfactionLevels.social_status =
                    math.min(100, char.mSatisfactionLevels.social_status + 5)
            else
                -- Cannot pay wage - dissatisfaction
                char.mSatisfactionLevels.social_status =
                    math.max(0, char.mSatisfactionLevels.social_status - 10)

                print("[WARNING] Cannot pay wage for " .. char.name)
            end
        end
    end

    print("[WAGES] Total paid: ₹" .. totalWages)
    return totalWages
end

-- 🚧 Phase 4: Trading (Multiplayer)
function Town:GetSurplusForTrade()
    -- Calculate surplus of target commodity
    local produced = self.mProductionStats.totalProduced
    local consumed = 0 -- Calculate from character consumption logs
    return produced - consumed
end

function Town:ListItemOnMarket(commodityID, quantity, priceRupees, barterOffer)
    -- To be implemented in Phase 4
end

function Town:ProcessTradeRequest(tradeData)
    -- To be implemented in Phase 4
end
```

**Conflicts:** ❌ None (extensions to existing system)

---

### 5.3 New UI Components Required

#### 5.3.1 Commodity Selection Screen

**File:** `CommoditySelectionUI.lua`

**Status:** ✅ NEW UI - Build in Phase 1

**Components:**
- 4 large cards showing each commodity option
- City name, commodity image/icon, brief description
- Difficulty indicator (⭐ rating)
- Starting rupees display
- "Select" button for each commodity
- Back button to main menu

**Mockup:**

```
┌─────────────────────────────────────────────────────────┐
│        CHOOSE YOUR COMMODITY-TOWN FOCUS                 │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐  ┌──────────────┐                   │
│  │  VADA PAV    │  │    DOSA      │                   │
│  │   Mumbai     │  │  Bangalore   │                   │
│  │  [Image 🍔]  │  │  [Image 🥞]  │                   │
│  │  ⭐⭐⭐       │  │  ⭐⭐⭐⭐     │                   │
│  │  ₹1,000      │  │  ₹1,200      │                   │
│  │  [SELECT]    │  │  [SELECT]    │                   │
│  └──────────────┘  └──────────────┘                   │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐                   │
│  │    POHA      │  │  RASGOLLA    │                   │
│  │   Indore     │  │   Kolkata    │                   │
│  │  [Image 🍚]  │  │  [Image ⚪]  │                   │
│  │  ⭐⭐         │  │  ⭐⭐⭐⭐⭐   │                   │
│  │  ₹800        │  │  ₹1,500      │                   │
│  │  [SELECT]    │  │  [SELECT]    │                   │
│  └──────────────┘  └──────────────┘                   │
│                                                          │
│                            [BACK]                        │
└─────────────────────────────────────────────────────────┘
```

---

#### 5.3.2 Recipe Info Panel

**File:** `RecipeInfoUI.lua`

**Status:** ✅ NEW UI - Build in Phase 2

**Purpose:** Show current recipe requirements and production progress

**Components:**
- Recipe name and icon
- Ingredient list with current/required quantities
- Progress bars for each ingredient
- Production rate (items/hour)
- Estimated time to next completion
- Stoppage alerts (if building blocked)

**Mockup:**

```
┌─────────────────────────────────────────┐
│  RECIPE: VADA PAV                       │
├─────────────────────────────────────────┤
│  Ingredients:                           │
│  ☑ Potatoes:        50 / 20  [█████░░] │
│  ☐ Wheat Flour:      5 / 10  [██░░░░░] │
│  ☑ Gram Flour:      15 / 10  [█████░░] │
│  ☑ Green Chilies:    8 / 5   [████░░░] │
│  ☐ Garlic:           2 / 5   [█░░░░░░] │
│  ☑ Spices:           3 / 2.5 [████░░░] │
│  ☑ Oil:             20 / 10  [█████░░] │
├─────────────────────────────────────────┤
│  Production Rate: 5 Vada Pav / hour    │
│  Next Completion: 8 minutes             │
│  Total Produced Today: 42               │
│                                          │
│  🚨 WARNING: Low Wheat Flour!           │
└─────────────────────────────────────────┘
```

---

#### 5.3.3 Rupee Display (TopBar Extension)

**File:** Update existing `TopBarUI.lua`

**Status:** ✅ EXTEND EXISTING - Build in Phase 3

**Add rupee counter to top bar:**

```
┌─────────────────────────────────────────────┐
│  CRAVETOWN  |  ₹1,250  |  Day: 5            │
└─────────────────────────────────────────────┘
```

**Additional Info (on hover/tap):**
- Rupee reserve: ₹1,250
- Daily wages: -₹350
- Daily income: +₹0 (from sales)
- Net: -₹350/day

---

#### 5.3.4 Production Stats Panel

**File:** `ProductionStatsUI.lua`

**Status:** ✅ NEW UI - Build in Phase 2

**Purpose:** Show daily production vs consumption of target commodity

**Mockup:**

```
┌────────────────────────────────────────┐
│  VADA PAV PRODUCTION                   │
├────────────────────────────────────────┤
│  Today's Production:     42            │
│  Today's Consumption:    35            │
│  Net Surplus:            +7            │
│                                         │
│  Weekly Trend:          [▲ Growing]    │
│  Inventory Stock:        215           │
│                                         │
│  [VIEW MARKET] 🚧                      │
└────────────────────────────────────────┘
```

---

#### 5.3.5 Market/Trading Interface (Future)

**File:** `MarketUI.lua`

**Status:** 🚧 DEFERRED TO PHASE 4 (Multiplayer)

See Appendix for detailed mockups.

---

## 6. Conflict Resolution & Solutions

This section details all conflicts between CFP requirements and existing game systems, with approved solutions.

---

### 6.1.1 ⚠️ CONFLICT: Existing Building Production Logic

**Problem:**
- Existing building production logic assumes single `inputs` → single `outputs`
- Current `Building:Update()` doesn't handle recipe-based production with multiple ingredients

**CFP Needs:**
- Recipe-based production with 7+ ingredients (e.g., Vada Pav)
- Complex production logic with time, intervals, queues, resource management, and stoppages

**✅ SOLUTION (Approved):**

Create **specialized dish buildings** for each commodity:
- **"Vada Pav Shop"**
- **"Dosa Kitchen"**
- **"Poha Kitchen"**
- **"Sweet Shop"** (for Rasgolla)

These buildings will:
1. Be separate from existing production buildings
2. Use `isDishProduction = true` flag for easy identification
3. Handle recipe-based production with full state management
4. Not interfere with existing building logic

**Implementation:** See Section 5.2.5 for complete `Building:Update()` extension code.

**Status:** ✅ Ready for Phase 1 implementation

---

### 6.1.2 ⚠️ CONFLICT: Building:Update() Method Extension

**Problem:**
- `Building:Update()` needs to handle recipe-based production
- Must support time tracking, interval management, action queues, resource management, and stoppage logic

**CFP Needs:**
- Full production state machine for dish buildings:
  - Time: Track production progress (0-100%)
  - Intervals: Auto-queue next production cycle
  - Actions: Start, pause, resume, complete
  - Queue: Multiple orders waiting
  - Resources: Check availability, consume on start, alert on shortage
  - Stoppage: Pause when ingredients missing, resume when available

**✅ SOLUTION (Approved):**

Extend `Building:Update()` with conditional logic based on `isDishProduction` flag:

```lua
function Building:Update(dt)
    if self.mType.isDishProduction then
        -- NEW: Dish production state machine
        self:UpdateDishProduction(dt)
    elseif self.mType.recipe then
        -- EXISTING: Simple recipe buildings
        self:UpdateRecipeProduction(dt)
    else
        -- LEGACY: Input/output buildings
        self:UpdateInputOutputProduction(dt)
    end
end
```

**Key Components:**

1. **Time Management:**
   - `currentProduction.progress` (0 → productionTime)
   - Worker efficiency modifier applied to progress rate

2. **Interval Management:**
   - `ManageProductionInterval(dt)` auto-adds orders to queue
   - Configurable: continuous production vs manual orders

3. **Action Queue:**
   - `productionQueue` stores pending orders
   - `StartNextInQueue()` called after completion

4. **Resource Management:**
   - `CheckIngredientsAvailable()` before starting
   - `ConsumeIngredients()` deducts from town inventory
   - `GetMissingIngredients()` returns shortage list

5. **Stoppage Logic:**
   - `resourceStoppage.isStopped` flag
   - `resourceStoppage.missingIngredients` for UI alerts
   - Automatic resume when ingredients available

**Status:** ✅ Ready for Phase 1 implementation (see Section 5.2.5 for full code)

---

### 6.1.3 ⚠️ CONFLICT: Multiplayer Architecture

**Problem:**
- Current game is single-player; all state is local
- No server infrastructure exists

**CFP Needs:**
- Inter-town trading requires multiplayer or network architecture
- Market listings must be shared across players

**🚧 SOLUTION (Deferred to Later Phase):**

***This will be implemented in Phase 4 after core CFP mechanics are stable.***

**Phased Approach:**

| Phase | Scope | Implementation |
|-------|-------|----------------|
| **Phase 1-2** | Single-Player CFP | No multiplayer, focus on production/consumption |
| **Phase 3** | Local Economy | Rupee system, wage payments, building costs |
| **Phase 4** | Multiplayer Trading | LAN or server-based trading with market UI |

**Phase 4 Options:**

**Option A: Local Network (LAN) - RECOMMENDED FOR PROTOTYPE**
- Use `lua-enet` library for LÖVE2D
- LAN-only trading (same WiFi)
- Simple offer/accept protocol
- No persistent storage needed
- **Pro:** Fast to implement, good for testing
- **Con:** Limited to local network

**Option B: Dedicated Server (Full Implementation)**
- Custom Lua server or cloud backend (Firebase/PlayFab)
- Database persistence
- Global marketplace
- Asynchronous trading
- **Pro:** Full online multiplayer
- **Con:** Complex, requires hosting infrastructure

**Phase 1-3 Workaround:**
- Create "Trading Post" building with NPC towns
- Simulate market with AI-driven listings
- Test economic systems without multiplayer

**Status:** 🚧 Deferred to Phase 4, use single-player testing in Phase 1-3

---

### 6.1.4 ⚠️ CONFLICT: Inter-Town Inventory Transfers

**Problem:**
- Inventory system is local to one town
- No transfer mechanisms between towns exist

**CFP Needs:**
- Commodities must move between towns for trading
- Need secure transfer protocol to prevent duplication/loss

**🚧 SOLUTION (Deferred to Later Phase):**

***This depends on multiplayer architecture (Conflict 6.1.3) and will be implemented together in Phase 4.***

**Phase 4 Implementation Plan:**

```lua
-- In Inventory.lua
function Inventory:TransferTo(targetInventory, commodityID, quantity)
    -- Validation
    if self:GetQuantity(commodityID) < quantity then
        return false, "Insufficient quantity"
    end

    -- Deduct from source
    self:Remove(commodityID, quantity)

    -- Add to target (with confirmation)
    targetInventory:Add(commodityID, quantity)

    -- Log transfer for audit trail
    self:LogTransfer(targetInventory.townID, commodityID, quantity)

    return true
end

-- NEW: Pending transfer system (for network lag)
Inventory = {
    mItems = {},
    mIncomingTrades = {}, -- Items being received
    mOutgoingTrades = {}  -- Items being sent (locked)
}

function Inventory:LockForTrade(commodityID, quantity, tradeID)
    -- Move to outgoingTrades, locked until trade completes/cancels
end

function Inventory:ReceiveTradeItem(commodityID, quantity, fromTownID)
    -- Add to mIncomingTrades, transfer to mItems after confirmation
end
```

**Temporary Solution for Phase 1-3 Testing:**
- Create global market inventory (not player-owned)
- Towns can sell TO market (remove from town inventory)
- Towns can buy FROM market (add to town inventory)
- Simulates trading without actual inter-town transfers

**Status:** 🚧 Deferred to Phase 4, use market simulation for Phase 1-3

---

### 6.1.5 🚨 CRITICAL CONFLICT: Currency System - Gold vs Rupee

**Problem:**
- `gold` exists as a minable commodity (`gold_ore`)
- Term "Gold" has **two conflicting meanings**:
  1. `gold_ore` - Commodity mined from mountains
  2. `Gold` (currency) - Payment medium for wages/trading

**CFP Needs:**
- Currency for wages, trading, town finances
- Clear distinction from `gold_ore` commodity

**✅ SOLUTION (Approved & CRITICAL):**

**Rename currency from "Gold" to "Rupee" (₹)**

**Rationale:**
- **Thematically appropriate**: All four cities are Indian (Mumbai, Bangalore, Kolkata, Indore)
- **Historically accurate**: Rupee is the currency of India
- **No confusion**: Clearly distinct from `gold_ore` commodity
- **Familiar**: Players understand Rupee in Indian context
- **Cultural consistency**: Matches CFP's focus on Indian street food

**Implementation Changes:**

```lua
-- ✅ KEEP: Gold as minable ore commodity
-- In CommodityTypes.lua
{
    id = "gold_ore",
    name = "Gold Ore",
    category = "raw_material",
    icon = "Au",
    stackSize = 1000,
    baseValue = 50, -- Worth 50 Rupees when sold to market
    description = "Precious metal ore - can be refined or sold for Rupees"
}

-- ✅ NEW: Rupee currency system
-- In CurrencySystem.lua
CurrencySystem = {
    currencyName = "Rupee",
    currencySymbol = "₹",
    rupeeReserves = {}, -- townID → rupee amount
    transactionHistory = {}
}

function CurrencySystem:InitializeRupees(townID, startingRupees)
    self.rupeeReserves[townID] = startingRupees or 1000
end

function CurrencySystem:AddRupees(townID, amount, reason)
    self.rupeeReserves[townID] = (self.rupeeReserves[townID] or 0) + amount
    self:RecordTransaction(townID, nil, amount, reason)
end

function CurrencySystem:DeductRupees(townID, amount, reason)
    if self:GetBalance(townID) >= amount then
        self.rupeeReserves[townID] = self.rupeeReserves[townID] - amount
        self:RecordTransaction(townID, nil, -amount, reason)
        return true
    end
    return false -- Insufficient rupees
end

function CurrencySystem:GetBalance(townID)
    return self.rupeeReserves[townID] or 0
end
```

**Required Renaming Throughout Codebase:**

| OLD (Remove) | NEW (Replace with) |
|--------------|-------------------|
| `mGoldReserve` | `mRupeeReserve` |
| `goldReserve` | `rupeeReserve` |
| `priceGold` | `priceRupees` |
| `goldCost` | `rupeeCost` |
| `payGold()` | `payRupees()` |
| "Price in Gold" (UI) | "Price in Rupees (₹)" |
| "gold per day" (wages) | "Rupees per day" |

**UI Updates:**
- TopBar: Display as `₹1,250` (use ₹ symbol)
- Building costs: `₹200` instead of `200 Gold`
- Wage payments: `₹50/day` instead of `50 gold/day`
- Market prices: `₹100` instead of `100g`

**Status:** ✅ Critical for Phase 3, must be implemented before wage/trading systems

---

### 6.1.6 ⚠️ CONFLICT: Adding 40+ New Commodities

**Problem:**
- Existing game has ~120 commodities
- Inventory UI designed for current commodity count
- Risk of ID conflicts between existing and new commodities

**CFP Needs:**
- Add ~40+ new commodities for Indian dishes:
  - Spices (turmeric, mustard seeds, fenugreek, etc.)
  - Processed items (wheat flour, gram flour, flattened rice, etc.)
  - Finished products (vadapav, dosa, poha, rasgolla)

**✅ SOLUTION (Approved):**

**Simply add the new commodities** with proper validation and organization.

**1. ID Conflict Prevention:**

```lua
-- Create validate_commodity_ids.lua
function ValidateCommodityIDs()
    local seen = {}
    local duplicates = {}

    for _, commodity in ipairs(CommodityTypes.mCommodities) do
        if seen[commodity.id] then
            table.insert(duplicates, commodity.id)
        end
        seen[commodity.id] = true
    end

    if #duplicates > 0 then
        error("DUPLICATE COMMODITY IDs: " .. table.concat(duplicates, ", "))
    end

    print("✅ Commodity validation passed: " .. #CommodityTypes.mCommodities .. " unique commodities")
end

-- Run on game startup in debug mode
if DEBUG_MODE then
    ValidateCommodityIDs()
end
```

**2. Organization Strategy:**

Keep CFP commodities in separate file for easy management:

```
/data/commodities/
    - commodities.json (existing 120 items)
    - cfp_commodities.json (NEW: 40+ CFP items)
```

Load both files on startup:

```lua
-- In CommodityTypes:Load()
CommodityTypes:LoadFile("data/commodities/commodities.json")
CommodityTypes:LoadFile("data/commodities/cfp_commodities.json")
CommodityTypes:ValidateNoDuplicates()
```

**3. Naming Convention:**

Use clear prefixes/suffixes to avoid confusion:
- Finished goods: `vadapav`, `dosa`, `masala_dosa`, `poha`, `rasgolla`
- Processed: `wheat_flour`, `gram_flour`, `flattened_rice`, `dosa_batter`
- Raw: `green_chili`, `curry_leaves`, `urad_dal`

**4. Inventory UI Pagination (If Needed):**

If total commodities exceed ~150 items:
- Add category tabs: `[Grains] [Vegetables] [Prepared Foods] [All]`
- Implement search/filter: `[Search: ___________]`
- Add sorting: `[Sort: Name ▼]`

**Status:** ✅ Ready for Phase 1, create validation script during implementation

---

### 6.1.7 ⚠️ CONFLICT: Character Assignment Logic

**Problem:**
- Existing character assignment logic assumes generic roles (worker, farmer, miner)
- Characters can work at any compatible building
- No specialization system exists

**CFP Needs:**
- Specialized roles for dish production (cooks with different skills)
- Potential for specialization bonuses (e.g., Dosa specialist works faster at Dosa Kitchen)

**✅ SOLUTION (Approved):**

**Keep character assignment logic generic** for simplicity in Phase 1.

**Phase 1 Implementation:**

```lua
-- In CharacterTypes.lua - Generic cook role
{
    id = "cook",
    name = "Cook",
    category = "transformer",

    -- Compatible with ALL dish shops
    compatibleWorkplaces = {
        "vadapav_shop",
        "dosa_kitchen",
        "poha_kitchen",
        "sweet_shop"
    },

    efficiency = {
        base = 1.0,
        satisfactionMultiplier = 0.02 -- +2% per satisfaction point above 50
    },

    wages = {
        base = 50, -- Rupees per day
        skill_bonus = 0 -- No skill system in Phase 1
    }
}

-- In Building.lua - Assignment check
function Building:CanAssignCharacter(character)
    if character.vocation == "cook" and self.mType.isDishProduction then
        return true
    end

    -- Check compatibility list
    for _, workplace in ipairs(character.compatibleWorkplaces) do
        if workplace == self.mType.id then
            return true
        end
    end

    return false
end
```

**Optional Future Enhancement (Phase 4+):**

```lua
-- Add specialization system later
Character = {
    vocation = "cook",
    specialization = nil, -- "vadapav", "dosa", "poha", "rasgolla"
}

-- If cook specializes in Dosa and works at Dosa Kitchen:
function Building:CalculateWorkerEfficiency()
    local efficiency = baseEfficiency

    for _, workerID in ipairs(self.workforce.assigned) do
        local worker = GetCharacterByID(workerID)

        -- Specialization bonus
        if worker.specialization == self.mType.recipe.recipeID then
            efficiency = efficiency + 0.15 -- +15% bonus
        end
    end

    return efficiency
end
```

**Rationale:**
- Allows rapid prototyping without over-engineering
- Can add depth later without breaking existing systems
- Mirrors real-world: generalist cooks can learn specialties

**Status:** ✅ Ready for Phase 1, specialization deferred to Phase 4+

---

### 6.1.8 🚧 CONFLICT: Skill & Efficiency Tracking

**Problem:**
- Characters have basic attributes only
- No skill levels, XP tracking, or progression system
- No way to differentiate experienced vs novice workers

**CFP Needs:**
- Skill levels (1-5) with efficiency multipliers
- Experience point accumulation over time
- Training and skill advancement system
- Higher-skilled workers deserve higher wages

**⚠️ SOLUTION (Needs Implementation - Phase 3 Priority):**

***This is a core requirement for CFP's labor depth model and must be implemented in Phase 3.***

**Minimal Implementation (Phase 3):**

```lua
-- In Character.lua - Add skill tracking
Character = {
    vocation = "cook",
    skillLevel = 1, -- 1-5 (all start at 1)
    experience = 0, -- XP points (not used yet)

    -- Derived stats
    skillEfficiency = 1.0, -- Recalculated when skillLevel changes
    dailyWage = 50 -- Recalculated: baseWage + (skillLevel * 10)
}

function Character:CalculateSkillEfficiency()
    -- Level 1: 1.0x (base)
    -- Level 2: 1.15x
    -- Level 3: 1.30x
    -- Level 4: 1.45x
    -- Level 5: 1.60x (master)
    self.skillEfficiency = 1.0 + ((self.skillLevel - 1) * 0.15)
end

function Character:CalculateDailyWage()
    local characterType = CharacterTypes[self.vocation]
    local baseWage = characterType.wages.base or 50
    local skillBonus = characterType.wages.skill_bonus or 10

    self.dailyWage = baseWage + (self.skillLevel * skillBonus)
end

-- Manual skill level adjustment (for testing Phase 3)
function Character:SetSkillLevel(level)
    self.skillLevel = math.max(1, math.min(5, level))
    self:CalculateSkillEfficiency()
    self:CalculateDailyWage()
end
```

**Full Implementation (Phase 4+):**

```lua
-- XP System
function Character:GainExperience(amount)
    self.experience = self.experience + amount

    -- Check for level up
    local xpRequired = self:GetXPRequiredForNextLevel()
    if self.experience >= xpRequired then
        self:LevelUp()
    end
end

function Character:GetXPRequiredForNextLevel()
    -- Quadratic scaling: 100, 400, 900, 1600, 2500
    local nextLevel = self.skillLevel + 1
    return 100 * (nextLevel ^ 2)
end

function Character:LevelUp()
    if self.skillLevel < 5 then
        self.skillLevel = self.skillLevel + 1
        self.experience = 0 -- Reset XP for next level
        self:CalculateSkillEfficiency()
        self:CalculateDailyWage()

        print("[LEVEL UP!] " .. self.name .. " is now Level " .. self.skillLevel .. " " .. self.vocation)
    end
end

-- XP gain triggers (call during production)
function Building:CompleteProduction()
    -- ... existing code ...

    -- Award XP to all assigned workers
    for _, workerID in ipairs(self.workforce.assigned) do
        local worker = GetCharacterByID(workerID)
        local xpAmount = 10 * (worker.satisfaction / 100) -- More XP if satisfied
        worker:GainExperience(xpAmount)
    end
end
```

**Training Building (Phase 4+):**

```lua
-- Cooking School building accelerates XP gain
{
    id = "cooking_school",
    name = "Cooking School",
    category = "education",

    trainingBonus = {
        xpMultiplier = 2.0, -- 2x XP gain for students
        maxStudents = 5
    }
}
```

**Status:** 🚧 Urgent - Must implement minimal version in Phase 3, full XP system in Phase 4

---

### 6.1.9 🚧 CONFLICT: Wage System

**Problem:**
- No wage system implemented
- Characters currently work for free
- No economic pressure on town finances

**CFP Needs:**
- Daily wage payments in Rupees (₹)
- Wage affects character satisfaction (social_status craving)
- Town must manage Rupee reserves to pay workers
- Inability to pay wages causes dissatisfaction/emigration

**⚠️ SOLUTION (Urgent - Phase 3 Priority):**

***This is critical for CFP's economic model and must be implemented in Phase 3.***

**Minimal Implementation (Phase 3):**

```lua
-- In Character.lua - Add wage tracking
Character = {
    vocation = "cook",
    dailyWage = 50, -- Fixed for Phase 3, skill-based in Phase 4

    employment = {
        building = buildingID or nil,
        startDate = timestamp,
        daysWorked = 0,
        unpaidDays = 0 -- Track missed payments
    }
}

-- In Town.lua - Wage payment system
function Town:PayWages()
    local totalWages = 0
    local unpaidWorkers = {}

    for _, char in ipairs(self.mCharacterPool) do
        if char.employment and char.employment.building then
            local wage = char.dailyWage

            if self.mRupeeReserve >= wage then
                -- SUCCESS: Pay wage
                self.mRupeeReserve = self.mRupeeReserve - wage
                totalWages = totalWages + wage
                char.employment.unpaidDays = 0

                -- Increase satisfaction for being paid
                char.mSatisfactionLevels.social_status =
                    math.min(100, char.mSatisfactionLevels.social_status + 5)

                print("[WAGE] Paid " .. char.name .. ": ₹" .. wage)

            else
                -- FAILURE: Cannot pay wage
                char.employment.unpaidDays = char.employment.unpaidDays + 1
                table.insert(unpaidWorkers, char.name)

                -- Severe dissatisfaction
                char.mSatisfactionLevels.social_status =
                    math.max(0, char.mSatisfactionLevels.social_status - 15)

                -- After 3 unpaid days, worker quits
                if char.employment.unpaidDays >= 3 then
                    print("[QUIT] " .. char.name .. " quit due to non-payment!")
                    self:UnassignCharacter(char.id)
                    -- Potentially emigrates
                end
            end
        end
    end

    -- Alerts
    if #unpaidWorkers > 0 then
        print("⚠️ [ALERT] Cannot pay wages for " .. #unpaidWorkers .. " workers!")
        print("   Unpaid: " .. table.concat(unpaidWorkers, ", "))
    end

    print("💰 [WAGES] Total paid: ₹" .. totalWages .. " | Remaining: ₹" .. self.mRupeeReserve)
    return totalWages
end

-- In GameLoop.lua - Call daily
function GameLoop:EndOfDayCycle()
    self.mTown:PayWages() -- Pay all workers
    self.mTown:UpdateSatisfaction() -- Decay satisfaction
    self.mTown:CheckMigration() -- Emigration check
end
```

**Wage Economics:**

| Worker Type | Base Wage (Phase 3) | Skill-Based Wage (Phase 4) |
|-------------|---------------------|----------------------------|
| Farmer | ₹40/day | ₹40 + (10 × skillLevel) |
| Miller | ₹50/day | ₹50 + (10 × skillLevel) |
| Cook | ₹50/day | ₹50 + (15 × skillLevel) |
| Specialist | ₹60/day | ₹60 + (15 × skillLevel) |

**Example Daily Costs:**

```
Vada Pav Town (10 workers):
- 3 Farmers × ₹40 = ₹120
- 2 Millers × ₹50 = ₹100
- 1 Spice Worker × ₹50 = ₹50
- 2 Cooks × ₹50 = ₹100
- 2 Support × ₹40 = ₹80
─────────────────────────────
TOTAL DAILY WAGES: ₹450

Starting Rupees: ₹1,000
Days until broke (no income): ~2.2 days

→ Player MUST generate income (selling commodities) or town collapses!
```

**Full Implementation (Phase 4+):**

```lua
-- Skill-based wages
function Character:CalculateDailyWage()
    local baseWage = CharacterTypes[self.vocation].wages.base
    local skillBonus = CharacterTypes[self.vocation].wages.skill_bonus
    self.dailyWage = baseWage + (self.skillLevel * skillBonus)
end

-- Market rate adjustments (supply/demand for workers)
function Town:CalculateWageMultiplier()
    local unemployed = self:CountUnemployedCharacters()
    local openPositions = self:CountOpenPositions()

    if openPositions > unemployed then
        return 1.2 -- Labor shortage: wages +20%
    elseif unemployed > openPositions * 2 then
        return 0.9 -- Labor surplus: wages -10%
    else
        return 1.0 -- Balanced market
    end
end

-- Bonus payments for high productivity
function Building:AwardProductionBonus()
    if self.mProductionEfficiency > 1.2 then -- >120% efficiency
        for _, workerID in ipairs(self.workforce.assigned) do
            local worker = GetCharacterByID(workerID)
            local bonus = worker.dailyWage * 0.1 -- 10% bonus
            self.mOwner:AddRupees(-bonus, "Production bonus: " .. worker.name)
            print("💰 [BONUS] " .. worker.name .. " earned ₹" .. bonus .. " bonus!")
        end
    end
end
```

**Status:** 🚧 Urgent - Must implement minimal version in Phase 3 for economic pressure

---

### 6.1.10 ⚠️ CONFLICT: Multi-Craving Satisfaction

**Problem:**
- Existing craving satisfaction: one commodity → one craving type
- `Character:ConsumeCommodity()` assumes single satisfaction value
- Example: eating `wheat` only satisfies `biological` craving

**CFP Needs:**
- Finished goods (Vada Pav, Dosa, etc.) satisfy **multiple craving types simultaneously**
- Example: Vada Pav satisfies biological (6), sensory (4), social_status (2)
- Quality and rarity modifiers affect satisfaction

**✅ SOLUTION (Approved):**

**Extend `Character:ConsumeCommodity()` to handle multi-craving fulfillment.**

**Implementation:** See Section 5.2.4 for complete code.

**Key Changes:**

```lua
-- OLD: Single craving (backward compatible)
{
    id = "wheat",
    cravingCategory = "biological", -- Single
    satisfaction = 5 -- Single value
}

-- NEW: Multi-craving (CFP finished goods)
{
    id = "vadapav",
    cravingCategories = {"biological", "sensory", "social_status"}, -- Array
    satisfactionValue = {
        biological = 6,
        sensory = 4,
        social_status = 2
    },
    qualityTier = "basic",
    rarity = 2
}
```

**Consumption Example:**

```lua
-- Character consumes 1 Vada Pav (basic quality, rarity=2)
character:ConsumeCommodity("vadapav", 1)

-- Results:
-- biological: +6 points (base)
-- sensory: +4 points (base)
-- social_status: +2 points (base)
-- Total: +12 satisfaction across 3 craving types

-- If Vada Pav was "good" quality (1.3x multiplier):
-- biological: +7.8 points
-- sensory: +5.2 points
-- social_status: +2.6 points
-- Total: +15.6 satisfaction
```

**Balance Considerations:**

1. **Finished goods are more valuable than raw ingredients:**
   - Raw potato: +4 biological only
   - Vada Pav (uses 2 potatoes + 6 other ingredients): +12 across 3 types
   - Encourages production chains over raw consumption

2. **Diminishing returns prevent exploitation:**
   - Eating 10 Vada Pav doesn't give 120 satisfaction
   - Each craving type caps at 100
   - Excess satisfaction is wasted

3. **Perishability limits hoarding:**
   - Finished goods have `shelfLife = 1-2 days`
   - Expired food gives reduced/negative satisfaction
   - Encourages daily production/consumption cycles

**Status:** ✅ Ready for Phase 2 implementation (see Section 5.2.4 for full code)

---

## 7. Development Roadmap

### Phase 1: Foundation (Weeks 1-2)

**Goal:** Core CFP systems without multiplayer or economy

**Tasks:**

1. **Create CommoditySelector.lua**
   - Build selection screen UI (4 commodity cards)
   - Define 4 commodity configurations
   - Implement town initialization logic

2. **Create RecipeSystem.lua**
   - Implement recipe data structures
   - Build recipe processing logic (ingredient check, consumption, output)
   - Test with one commodity (Vada Pav)

3. **Extend CommodityTypes.lua**
   - Add all 40+ new commodities
   - Define multi-craving mappings (`cravingCategories`, `satisfactionValue`)
   - Add quality/rarity attributes
   - Create `validate_commodity_ids.lua` script

4. **Extend BuildingTypes.lua**
   - Add 11 new building types (4 dish shops + 7 processing buildings)
   - Implement `isDishProduction` flag
   - Define recipe links (`recipeID`, `productionTime`, `batchSize`)

5. **Extend Building.lua**
   - Update `Building:Update()` with dish production logic
   - Implement production state machine (queue, stoppage, completion)
   - Add worker efficiency calculations

6. **Extend CharacterTypes.lua**
   - Add specialized character types (farmers, millers, cooks)
   - Define generic "cook" role compatible with all dish shops

**Deliverable:** Single-player CFP where player can choose Vada Pav and complete full production chain (ingredients → dish)

**Testing Criteria:**
- [ ] Can select commodity from selection screen
- [ ] Town initializes with correct buildings/characters
- [ ] Can place all required buildings on map
- [ ] Can assign workers to buildings
- [ ] Production cycle completes successfully
- [ ] Finished goods appear in inventory
- [ ] Buildings stop/resume on ingredient shortage

---

### Phase 2: Multi-Craving & Balance (Week 3)

**Goal:** Refine craving satisfaction and balance production rates

**Tasks:**

1. **Update Character:ConsumeCommodity()**
   - Implement multi-craving satisfaction logic
   - Add quality modifiers (poor/basic/good/luxury)
   - Add rarity bonuses

2. **Update CravingDefinitions.lua**
   - Map all 4 commodities to craving types
   - Test satisfaction decay rates
   - Balance satisfaction values

3. **Balance Production Rates**
   - Adjust building production times (Poha fast, Rasgolla slow)
   - Tune worker efficiency bonuses
   - Ensure supply meets demand (no perpetual shortages)

4. **Implement Recipe Info UI**
   - Show ingredient progress bars
   - Display production stats (rate, next completion)
   - Add warnings for shortages

5. **Add Production Stats Panel**
   - Calculate daily net production (produced - consumed)
   - Display surplus/deficit for target commodity
   - Highlight trade opportunities (for Phase 4)

**Deliverable:** All 4 commodities playable, balanced, and satisfying

**Testing Criteria:**
- [ ] All commodities have functional production chains
- [ ] Characters have stable satisfaction (40-70 range for 10+ days)
- [ ] No catastrophic shortages or infinite surpluses
- [ ] UI clearly shows production status and shortages
- [ ] Different commodities feel different (Poha fast, Rasgolla complex)

---

### Phase 3: Rupee Economy & Wages (Week 4)

**Goal:** Add currency and wage system (no trading yet)

**Tasks:**

1. **Create CurrencySystem.lua**
   - Implement rupee tracking with ₹ symbol
   - Add `InitializeRupees()`, `AddRupees()`, `DeductRupees()` functions
   - Transaction history logging

2. **Extend Town.lua**
   - Add `mRupeeReserve` variable
   - Implement `Town:PayWages()` system
   - Handle insufficient rupees (worker dissatisfaction)

3. **Update TopBar UI**
   - Display rupee balance: `₹1,250`
   - Show daily wage costs on hover
   - Alert when rupees < 3 days of wages

4. **Implement Skill System (Minimal)**
   - Add `skillLevel` (1-5) to Character
   - Calculate efficiency: `1.0 + (skillLevel - 1) × 0.15`
   - Calculate wages: `baseWage + (skillLevel × 10)`
   - Manual skill adjustment (no XP yet)

5. **Add Building Costs**
   - Buildings cost rupees to construct
   - Deduct from town rupees on placement
   - Alert if insufficient rupees

6. **Economic Testing**
   - Run 30-day simulation
   - Verify wage payments deplete rupees
   - Test worker quit behavior (unpaid for 3 days)
   - Balance starting rupees vs wage costs

**Deliverable:** Complete rupee economy with wage pressure

**Testing Criteria:**
- [ ] Rupees display correctly in UI
- [ ] Wages paid daily, deducted from reserve
- [ ] Workers quit if unpaid for 3+ days
- [ ] Satisfaction drops when unpaid
- [ ] Building construction costs rupees
- [ ] Town can become bankrupt (₹0)
- [ ] Economic pressure incentivizes efficiency

---

### Phase 4: Local Network Multiplayer (Weeks 5-6)

**Goal:** Enable 2-player trading on same WiFi (LAN)

**Tasks:**

1. **Research Networking Libraries**
   - Evaluate `lua-enet`, `lua-socket` for LÖVE2D
   - Test basic send/receive on LAN
   - Choose library based on ease of use

2. **Create TradingSystem.lua**
   - Market listing data structures
   - Trade offer/acceptance logic
   - Inventory transfer functions (with rollback on failure)

3. **Build MarketUI.lua**
   - Browse listings interface (see other towns' offers)
   - List item for sale (set rupee price or barter request)
   - Trade offer interface (send offer, counter-offer)
   - Trade history log

4. **Implement Server Discovery**
   - Broadcast server presence on LAN
   - Client can discover and connect
   - Display list of available towns to trade with

5. **Implement Trading Protocol**
   - Sync market listings across clients
   - Send/receive trade offers
   - Execute trades with confirmation (both parties approve)
   - Handle edge cases (disconnection, duplicate offers)

6. **Test Multiplayer Trading**
   - Two devices on same WiFi
   - List item, browse, make offer, accept, complete trade
   - Verify inventory sync
   - Test disconnection handling

**Deliverable:** Working 2-player LAN trading system

**Testing Criteria:**
- [ ] Two devices can discover each other on LAN
- [ ] Market listings appear on both devices
- [ ] Trade can be initiated and completed
- [ ] Rupees and commodities transfer correctly
- [ ] No data loss or duplication
- [ ] Disconnection handled gracefully

---

### Phase 5: Polish & Balance (Week 7)

**Goal:** Refinement and playtesting for demo readiness

**Tasks:**

1. **Playtesting with Real Users**
   - Gather feedback on production difficulty
   - Identify confusing UI elements
   - Test trading flow with real players

2. **Balance Adjustments**
   - Tweak production rates based on feedback
   - Adjust rupee costs/wages for economic balance
   - Refine craving satisfaction values

3. **Visual Polish**
   - Improve UI aesthetics (colors, fonts, spacing)
   - Add icons for commodities (food icons)
   - Animation for successful trades (celebration effect)
   - City-specific aesthetics (Mumbai vs Bangalore themes)

4. **Tutorial System**
   - Guided setup for first-time players
   - Tooltips explaining recipe requirements
   - Example trade flow walkthrough

5. **Bug Fixes**
   - Address crashes reported during testing
   - Fix inventory bugs (duplication, loss)
   - Resolve sync issues in multiplayer

6. **Performance Optimization**
   - Profile for bottlenecks (production loops, UI updates)
   - Optimize for mobile (touch controls, screen size)

**Deliverable:** Polished, playable CFP ready for public demo

**Testing Criteria:**
- [ ] 10+ playtesters complete 1-hour sessions without confusion
- [ ] No critical bugs or crashes
- [ ] Frame rate stable (60 FPS on target devices)
- [ ] Tutorial reduces learning curve (players understand in <5 min)
- [ ] Visual polish feels cohesive and thematic

---

## 8. Future Expansion Paths

### 8.1 Additional Commodities (Post-Launch)

**New Indian Dishes:**
- **Biryani** (Hyderabad) - Layered rice dish, very complex
- **Pani Puri** (Delhi) - Street snack, fast production
- **Dhokla** (Gujarat) - Steamed cake, fermentation like Dosa
- **Litti Chokha** (Bihar) - Stuffed wheat balls, rustic

Each with unique production chains, craving profiles, and regional themes.

---

### 8.2 Advanced Trading Features

- **Trading Guilds** - Players form alliances for bulk trades and shared resources
- **Commodity Futures** - Pre-order future production at locked prices
- **Dynamic Pricing** - Market-driven price fluctuations based on supply/demand
- **Trade Routes** - Establish regular trade agreements with other towns
- **Auction House** - Bidding system for rare/high-quality goods

---

### 8.3 Competitive Elements

- **Production Leaderboards** - Highest output of each commodity (weekly/monthly)
- **Wealth Leaderboards** - Most rupees accumulated
- **Town Reputation** - Based on trade reliability (fulfilled vs failed trades)
- **Seasonal Events** - Limited-time high-demand periods (festivals, holidays)
- **Achievements** - "Vada Pav Master", "100 Trades Completed", etc.

---

### 8.4 Expanded Economy

- **Taxation** - Government spending on infrastructure (roads, police)
- **Loans** - Borrow rupees for expansion (with interest payments)
- **Investments** - Stake rupees in other towns for returns
- **Insurance** - Protect against production failures (pay premiums)
- **Bank System** - Store rupees with interest, withdraw anytime

---

### 8.5 Skill & Training Expansion

- **Full XP System** - Characters gain XP per production cycle
- **Training Buildings** - Cooking schools that accelerate XP gain
- **Specialization Trees** - Cooks choose mastery paths (speed, quality, multi-dish)
- **Master Chefs** - Level 5 cooks unlock unique recipes
- **Apprenticeship** - Low-skill workers learn from masters

---

## 9. Technical Specifications

### 9.1 File Structure (New)

```
cravetown-love/
├── src/
│   ├── core/ (Existing shared systems)
│   │   ├── Town.lua
│   │   ├── Building.lua
│   │   ├── Character.lua
│   │   ├── Inventory.lua
│   │   └── ...
│   ├── alpha/ (Original prototype code)
│   └── cfp/ (NEW: CFP-specific code)
│       ├── CommoditySelector.lua
│       ├── RecipeSystem.lua
│       ├── CurrencySystem.lua
│       ├── TradingSystem.lua (Phase 4)
│       ├── ui/
│       │   ├── CommoditySelectionUI.lua
│       │   ├── RecipeInfoUI.lua
│       │   ├── MarketUI.lua (Phase 4)
│       │   └── ProductionStatsUI.lua
│       └── data/
│           ├── CommodityRecipes.lua
│           └── CommodityConfigurations.lua
├── data/
│   ├── commodities/
│   │   ├── commodities.json (existing 120)
│   │   └── cfp_commodities.json (NEW: 40+ CFP items)
│   ├── buildings/
│   │   └── cfp_buildings.json (NEW: 11+ CFP buildings)
│   └── characters/
│       └── cfp_characters.json (NEW: specialized types)
└── assets/
    └── cfp/
        ├── images/ (commodity icons, building sprites)
        ├── sounds/ (Indian city ambience)
        └── ui/ (themed UI elements)
```

---

### 9.2 Data Formats

#### Commodity Configuration

```lua
{
    id = "vadapav",
    name = "Vada Pav",
    city = {
        name = "Mumbai",
        aesthetic = "mumbai_theme", -- Color scheme, fonts, sounds
        startingRupees = 1000
    },
    recipe = {
        recipeID = "vadapav",
        productionTime = 120,
        batchSize = 10
    },
    buildings = {
        { type = "farm", count = 2 },
        { type = "mill", count = 1 },
        { type = "spice_grinder", count = 1 },
        { type = "vadapav_shop", count = 1 }
    },
    characters = {
        { type = "farmer", count = 3 },
        { type = "miller", count = 2 },
        { type = "spice_worker", count = 1 },
        { type = "cook", count = 2 }
    },
    startingInventory = {
        { commodity = "potato", quantity = 10 },
        { commodity = "wheat", quantity = 5 },
        { commodity = "gram", quantity = 5 }
    }
}
```

---

#### Market Listing (Phase 4)

```lua
{
    listingID = "listing_12345",
    sellerTownID = "town_mumbai_001",
    sellerName = "Mumbai Town #001",
    commodityID = "vadapav",
    quantity = 50,
    priceRupees = 100, -- 100 rupees total (₹2 per Vada Pav)
    barterOffer = {
        commodityID = "dosa",
        quantity = 30
    },
    timestamp = 1703001234,
    expiresAt = 1703087634, -- 24 hours later
    status = "active" -- active, pending, completed, cancelled
}
```

---

#### Trade Offer (Phase 4)

```lua
{
    offerID = "offer_67890",
    buyerTownID = "town_bangalore_002",
    buyerName = "Bangalore Town #002",
    sellerTownID = "town_mumbai_001",
    listingID = "listing_12345",
    offerType = "rupees", -- or "barter"
    offerAmount = 100, -- if offerType = "rupees"
    offerCommodity = nil, -- if offerType = "barter"
    offerQuantity = nil, -- if offerType = "barter"
    status = "pending", -- pending, accepted, rejected, completed
    timestamp = 1703001300
}
```

---

### 9.3 API Endpoints (For Future Dedicated Server)

**When implementing dedicated server in future, these APIs are needed:**

---

**GET** `/market/listings`
- Returns all active market listings
- Query params: `?commodityID=vadapav&maxPrice=200`
- Response: Array of market listing objects

---

**POST** `/market/list`
- Create new market listing
- Body: `{ townID, commodityID, quantity, priceRupees, barterOffer }`
- Response: `{ listingID, status: "active" }`

---

**POST** `/market/offer`
- Send trade offer on a listing
- Body: `{ buyerTownID, listingID, offerType, offerData }`
- Response: `{ offerID, status: "pending" }`

---

**POST** `/market/accept`
- Accept a trade offer (seller action)
- Body: `{ offerID }`
- Executes transaction atomically
- Response: `{ status: "completed", transferDetails }`

---

**GET** `/town/:townID/inventory`
- Get current town inventory
- Response: `{ commodityID → quantity }`

---

**POST** `/town/:townID/transfer`
- Transfer commodity to another town (trade execution)
- Body: `{ targetTownID, commodityID, quantity }`
- Response: `{ success: true, newBalance }`

---

## 10. Success Metrics

### 10.1 Gameplay Metrics

- **Production Efficiency:** % of game time with active production (target: >70%)
- **Craving Satisfaction:** Average character satisfaction (target: 50-70)
- **Trade Volume:** Number of trades per session (Phase 4)
- **Rupee Flow:** Rupees earned vs spent ratio (target: break-even by day 10)

### 10.2 Player Engagement

- **Session Length:** Average play session duration (target: 30+ minutes)
- **Retention:** % of players returning next day (target: 40%+)
- **Commodity Diversity:** % of players trying all 4 commodities (target: 60%+)
- **Multiplayer Adoption:** % of players engaging in trades (Phase 4)

### 10.3 Technical Performance

- **Frame Rate:** Maintain 60 FPS on mobile devices
- **Network Latency:** <100ms for trade actions (Phase 4)
- **Crash Rate:** <0.1% of sessions
- **Save/Load Time:** <2 seconds for town state

---

## 11. Risk Analysis

### 11.1 Technical Risks

**Risk:** Multiplayer networking complexity
**Mitigation:** Start with LAN-only (Phase 4), defer internet multiplayer
**Fallback:** Single-player with AI traders

---

**Risk:** Balance issues (production too slow/fast)
**Mitigation:** Extensive playtesting in Phase 2/5, adjustable parameters
**Fallback:** Difficulty settings for production rates

---

**Risk:** Performance with many towns/trades
**Mitigation:** Optimize data structures, limit active listings to 100
**Fallback:** Cap simultaneous players/listings per server

---

### 11.2 Design Risks

**Risk:** Trading too complex for casual players
**Mitigation:** Simple UI, clear tutorials, AI assistance
**Fallback:** Simplified rupee-only trading (remove barter)

---

**Risk:** One commodity becoming dominant
**Mitigation:** Unique advantages for each (Poha fast, Rasgolla high-value), seasonal events
**Fallback:** Balance patches based on play data

---

**Risk:** Wage system creates too much pressure
**Mitigation:** Generous starting rupees (₹1000), slow ramp-up
**Fallback:** "Easy mode" with lower wages or rupee subsidies

---

### 11.3 Scope Risks

**Risk:** Feature creep delaying launch
**Mitigation:** Strict phase adherence, MVP mentality (Phase 1-3 first)
**Fallback:** Cut multiplayer for initial release

---

**Risk:** Insufficient testing before demo
**Mitigation:** Weekly playtests starting Week 3, external testers in Week 6
**Fallback:** Focus on one commodity (Vada Pav) for demo

---

## 12. Conclusion

The Commodity-Focus Prototype provides a streamlined entry point to Cravetown's economic simulation while laying groundwork for future expansion. By focusing on four culturally significant Indian commodities, players learn production chains, resource management, and trading in a contextualized, authentic environment.

**Key Innovations:**
1. **Recipe-based Production System** - Multi-ingredient dishes with complex production logic
2. **Multi-Craving Satisfaction** - Single commodity satisfies multiple needs simultaneously
3. **Rupee Economy** - Currency system (₹) for wages, building costs, and trading
4. **Cultural Authenticity** - Indian street food with city-specific themes

**Critical Path to Launch:**
1. ✅ Phase 1: Build recipe system and production chains (Weeks 1-2)
2. ✅ Phase 2: Balance craving satisfaction and production rates (Week 3)
3. 🚧 Phase 3: Add rupee economy and wage system (Week 4)
4. 🚧 Phase 4: Implement local multiplayer trading (Weeks 5-6)
5. 🚧 Phase 5: Polish and playtest for demo (Week 7)

**Conflicts Resolved:**
- ✅ Specialized dish buildings (Section 6.1.1 & 6.1.2)
- ✅ Rupee currency system (Section 6.1.5)
- ✅ Multi-craving satisfaction (Section 6.1.10)
- ✅ Generic cook roles (Section 6.1.7)
- ✅ Commodity ID validation (Section 6.1.6)
- 🚧 Skill tracking system (Section 6.1.8 - Phase 3 priority)
- 🚧 Wage payment system (Section 6.1.9 - Phase 3 priority)
- 🚧 Multiplayer architecture (Section 6.1.3 - Phase 4)

**Next Steps:**
1. Review this document with full team
2. Approve conflict resolutions and design decisions
3. Set up CFP development branches
4. Create task assignments for Phase 1
5. Begin implementation Week 1

---

## Appendices

### Appendix A: Complete Commodity Recipes

*(Detailed ingredient lists and preparation steps for all 4 commodities - see original draft Section A.1-A.4)*

### Appendix B: Building Specifications (CFP-Specific)

*(Building costs, worker requirements, production rates - see original draft Section B.1-B.4)*

### Appendix C: Character Efficiency Modifiers

*(Efficiency formulas and calculations - see original draft Section C)*

### Appendix D: Rupee Economy Formulas

*(Building costs, wages, AI pricing - see original draft Section D)*

### Appendix E: Network Protocol Specification

*(Message types and formats for Phase 4 multiplayer - see original draft Section E)*

---

**END OF FINAL DESIGN DOCUMENT**

---

**Document Version:** 3.0 (FINAL)
**Last Updated:** December 17, 2024
**Author:** Cravetown Development Team
**Status:** ✅ READY FOR IMPLEMENTATION

**Changelog (v3.0 - FINAL):**
- ✅ All 10 conflicts resolved with approved solutions
- ✅ Currency renamed from "Gold" to "Rupee" (₹) throughout
- ✅ Clear prioritization: Phase 1-2 (production), Phase 3 (economy), Phase 4 (multiplayer)
- ✅ 🚧 markers for deferred/urgent items
- ✅ Complete code examples for all critical systems
- ✅ Development roadmap with clear deliverables
- ✅ Success metrics and risk mitigation strategies
- ✅ Future expansion paths identified

**Critical Items for Immediate Implementation:**
1. Specialized dish buildings with production state machine (Phase 1)
2. Multi-craving satisfaction system (Phase 2)
3. Rupee currency system with wage payments (Phase 3 - URGENT)
4. Skill tracking system (Phase 3 - URGENT)
