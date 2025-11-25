# CraveTown Information System - Complete Guide

## Table of Contents
1. [Introduction](#introduction)
2. [System Architecture](#system-architecture)
3. [Data Model Overview](#data-model-overview)
4. [Production System](#production-system)
5. [Craving System](#craving-system)
6. [Getting Started](#getting-started)
7. [Step-by-Step Setup Guide](#step-by-step-setup-guide)
8. [Advanced Features](#advanced-features)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

---

## Introduction

The CraveTown Information System is a comprehensive data management tool for configuring and balancing the game's economy and character needs system. It consists of two major subsystems:

1. **Production System** - Manages buildings, recipes, commodities, and workers
2. **Craving System** - Manages character needs, satisfaction, and fulfillment

This guide will help you understand the entire data model and how to configure everything using the UI.

---

## System Architecture

```
CraveTown Information System
│
├── Production System
│   ├── Building Types (physical structures)
│   ├── Building Recipes (production chains)
│   ├── Commodities (goods & services)
│   ├── Worker Types (labor force)
│   └── Work Categories (skill classifications)
│
└── Craving System
    ├── Craving Dimensions (9 coarse + 50 fine needs)
    ├── Character Classes (lower/middle/upper/elite)
    ├── Character Traits (personality modifiers)
    ├── Fulfillment Vectors (how commodities satisfy needs)
    ├── Enablement Rules (dynamic need changes)
    └── Substitution Calculator (commodity similarity)
```

---

## Data Model Overview

### Core Concepts

#### 1. **Commodities** → **Fulfillment Vectors**
- Commodities are goods/services (bread, clothing, entertainment)
- Each commodity has a Fulfillment Vector describing which needs it satisfies
- Fulfillment vectors use the 50-dimensional fine craving space

#### 2. **Characters** → **Base Cravings** + **Traits** + **Enablement Rules**
- Characters start with base cravings from their Class
- Traits multiply these base cravings (ambitious person craves achievement more)
- Enablement Rules add/subtract cravings based on life events (marriage, wealth, etc.)

#### 3. **Buildings** → **Recipes** → **Workers**
- Buildings (farms, bakeries, mines) are placed by players
- Each building runs Recipes that transform inputs into outputs
- Recipes require Workers with specific skills from Work Categories

---

## Production System

### 1. Building Types

**Purpose:** Define physical structures that can be placed in the town.

**Key Fields:**
- `id` - Unique identifier (e.g., "farm", "bakery")
- `name` - Display name
- `category` - Type classification (production, housing, service, etc.)
- `label` - 2-letter abbreviation shown on the map
- `color` - RGB color [0-1, 0-1, 0-1] for map rendering
- `baseWidth/baseHeight` - Default size in tiles
- `variableSize` - Can be resized (true/false)
- `workCategories` - List of compatible worker types
- `workerEfficiency` - Efficiency multipliers per work category (0.0-1.0)
- `storage` - Input/output capacity limits
- `constructionMaterials` - Resources needed to build

**Example:**
```json
{
  "id": "bakery",
  "name": "Bakery",
  "category": "production",
  "label": "BK",
  "color": [0.9, 0.7, 0.4],
  "baseWidth": 3,
  "baseHeight": 3,
  "workCategories": ["Baking", "Food Preparation"],
  "workerEfficiency": {
    "Baking": 1.0,
    "Food Preparation": 0.8
  },
  "storage": {
    "inputCapacity": 100,
    "outputCapacity": 50
  }
}
```

**How to Use:**
1. Navigate to **Building Types** in the menu
2. Click **Add Building Type**
3. Fill in all required fields
4. Set work categories that can work in this building
5. Configure worker efficiency multipliers
6. Save

---

### 2. Commodities

**Purpose:** Define all tradeable goods and services in the game.

**Key Fields:**
- `id` - Unique identifier (e.g., "wheat", "bread", "clothing")
- `name` - Display name
- `category` - Classification (grain, fruit, processed_food, luxury, etc.)
- `baseValue` - Base economic value
- `description` - Optional flavor text

**Categories:**
- **Food:** grain, fruit, vegetable, animal_product, processed_food
- **Materials:** textile, raw_mineral, refined_metal, construction, fuel
- **Goods:** clothing, furniture, tools, luxury
- **Services:** education, healthcare, entertainment

**How to Use:**
1. Navigate to **Commodities**
2. Click **Add Commodity**
3. Choose appropriate category (important for Quick Fill later)
4. Set base value relative to other commodities
5. Save

**Best Practice:** Create all commodities before setting up fulfillment vectors.

---

### 3. Building Recipes

**Purpose:** Define production chains - how buildings transform inputs into outputs.

**Key Fields:**
- `buildingType` - Which building runs this recipe
- `recipeName` - Unique name for this recipe
- `category` - Recipe classification
- `productionTime` - Minutes to complete one cycle
- `inputs` - Map of commodityId → quantity needed
- `outputs` - Map of commodityId → quantity produced
- `workers` - Worker requirements
  - `required` - Minimum workers needed
  - `max` - Maximum workers allowed
  - `vocations` - List of compatible work categories
  - `efficiencyBonus` - Bonus per skilled worker
  - `wages` - Wage per worker per cycle

**Example:**
```json
{
  "buildingType": "bakery",
  "recipeName": "Bake Bread",
  "category": "Food Production",
  "productionTime": 10,
  "inputs": {
    "wheat": 5,
    "water": 1
  },
  "outputs": {
    "bread": 3
  },
  "workers": {
    "required": 1,
    "max": 3,
    "vocations": ["Baking", "Food Preparation"],
    "efficiencyBonus": 0.15,
    "wages": 5
  }
}
```

**How to Use:**
1. Navigate to **Building Recipes**
2. Click **Add Recipe**
3. Select building type
4. Configure inputs (must be existing commodities)
5. Configure outputs
6. Set worker requirements
7. Save

---

### 4. Worker Types

**Purpose:** Define labor force types with different skills and wages.

**Key Fields:**
- `id` - Unique identifier (e.g., "baker", "farmer")
- `name` - Display name
- `category` - Skill classification
- `minimumWage` - Lowest acceptable wage
- `skillLevel` - Basic/Intermediate/Advanced/Expert
- `workCategories` - Categories of work they can perform

**How to Use:**
1. Navigate to **Worker Types**
2. Click **Add Worker Type**
3. Set minimum wage
4. Assign work categories they're trained in
5. Save

---

### 5. Work Categories

**Purpose:** Classification system for types of work (skills/vocations).

**Key Fields:**
- `id` - Unique identifier
- `name` - Display name
- `description` - What this category encompasses

**Examples:**
- Agriculture
- Baking
- Metalworking
- Education
- Healthcare

**How to Use:**
1. Navigate to **Work Categories**
2. Click **Add Work Category**
3. Define broad skill classifications
4. These will be used in Building Types, Worker Types, and Recipes

---

## Craving System

The craving system is the heart of CraveTown's character simulation. It models human needs using a multi-dimensional mathematical framework.

### Architecture: 9D → 50D System

```
9 Coarse Dimensions (high-level needs)
    ↓
50 Fine Dimensions (specific needs)
    ↓
Fulfillment Vectors (how commodities satisfy needs)
    ↓
Character Satisfaction (0-100%)
```

---

### 1. Craving Dimensions

**Purpose:** Define the mathematical space of human needs.

#### Coarse Dimensions (9D)

High-level need categories that aggregate multiple fine dimensions.

**Key Fields:**
- `id` - Unique identifier
- `index` - Position in 9D array (0-8)
- `name` - Display name
- `description` - What this dimension encompasses
- `tier` - Hierarchy level (survival/security/comfort/social_psychological/aspirational/special)
- `criticalThreshold` - Below this %, character is in crisis (0-100)
- `emigrationWeight` - How much this affects emigration decision (0-1)
- `productivityImpact` - Effect on work output (0-1, can be negative)
- `decayRate` - How fast satisfaction decreases per day (0-1)

**The 9 Coarse Dimensions:**
1. **Biological** (index 0) - Food, water, medicine, rest
2. **Safety** (index 1) - Protection, housing, security
3. **Touch** (index 2) - Physical comfort, clothing, furniture
4. **Psychological** (index 3) - Mental stimulation, learning, meaning
5. **Social Status** (index 4) - Reputation, wealth display
6. **Social Connection** (index 5) - Friendship, belonging, family
7. **Exotic Goods** (index 6) - Rare items, foreign foods
8. **Shiny Objects** (index 7) - Precious metals, gems, art
9. **Vice** (index 8) - Intoxicants, gambling, indulgence

**How to Use:**
1. Navigate to **Craving Dimensions** → **Coarse Dimensions (9D)** tab
2. Click **Edit** on any dimension to modify
3. Adjust `criticalThreshold` to control when characters panic
4. Set `emigrationWeight` to control emigration behavior
5. Configure `decayRate` to control how fast satisfaction drops
6. Save

**Best Practice:**
- Higher tier dimensions (aspirational) should have lower emigration weights
- Survival tier should have highest emigration weights
- Decay rates typically: biological (0.05), safety (0.02), psychological (0.01)

---

#### Fine Dimensions (50D)

Specific needs that roll up into coarse dimensions.

**Key Fields:**
- `id` - Unique identifier (format: `parentCoarse_subcategory_specific`)
- `index` - Position in 50D array (0-49)
- `parentCoarse` - Which coarse dimension this belongs to
- `name` - Display name
- `tags` - Searchable keywords
- `aggregationWeight` - How much this contributes to parent coarse (0-1)
- `decayRate` - Fine-grained decay rate (optional, inherits from coarse if not set)

**Example Fine Dimensions:**
```
Biological (8 fine dimensions):
  0. Grain Nutrition (weight: 0.20)
  1. Protein Nutrition (weight: 0.15)
  2. Produce Nutrition (weight: 0.15)
  3. Hydration (weight: 0.15)
  4. Medicine (weight: 0.10)
  5. Hygiene (weight: 0.10)
  6. Rest Quality (weight: 0.10)
  7. Energy Stimulation (weight: 0.05)
```

**Aggregation Formula:**
```
coarse_satisfaction[i] = Σ (fine_satisfaction[j] × aggregationWeight[j])
  for all fine dimensions j where parentCoarse = i
```

**How to Use:**
1. Navigate to **Craving Dimensions** → **Fine Dimensions (50D)** tab
2. Click **Edit** on any dimension
3. Verify `parentCoarse` is correct
4. Adjust `aggregationWeight` (all weights for a coarse parent should sum to ~1.0)
5. Add relevant `tags` for searchability
6. Save

**Best Practice:**
- Keep aggregation weights proportional to importance
- Use consistent naming: `parentCoarse_subcategory_specific`
- Add comprehensive tags for the Quick Fill feature

---

### 2. Character Classes

**Purpose:** Define socioeconomic tiers with different base craving profiles.

**Key Fields:**
- `id` - Unique identifier (lower/middle/upper/elite)
- `name` - Display name
- `description` - Class characteristics
- `allocationPriority` - Housing assignment order (1=highest)
- `baseIncome` - Starting wealth
- `baseCravingVector` - Default cravings
  - `coarse` - Array of 9 numbers (intensity of each coarse dimension)
  - `fine` - Array of 50 numbers (intensity of each fine dimension)
- `thresholds` - Behavior triggers
  - `emigration` - Leave town if overall satisfaction below this
  - `riotContribution` - Chance to riot per satisfaction point below threshold
  - `criticalSatisfaction` - Individual dimension crisis level
- `acceptedQualityTiers` - Quality levels they'll consume
- `rejectedQualityTiers` - Quality levels they refuse

**Example:**
```json
{
  "id": "lower",
  "name": "Lower Class",
  "baseCravingVector": {
    "coarse": [15, 12, 8, 5, 2, 8, 1, 1, 3],
    "fine": [/* 50 numbers */]
  },
  "thresholds": {
    "emigration": 30,
    "riotContribution": 0.05,
    "criticalSatisfaction": 20
  },
  "acceptedQualityTiers": ["poor", "basic"],
  "rejectedQualityTiers": ["masterwork"]
}
```

**How to Use:**
1. Navigate to **Character Classes**
2. Click **Edit** on any class
3. Adjust base craving vectors using the visual editor
   - Higher numbers = stronger craving
   - Lower class: Focus on biological & safety
   - Elite: Focus on status, psychological, exotic goods
4. Set thresholds based on class expectations
5. Configure quality tier preferences
6. Save

**Understanding Base Cravings:**
- These are **intensity multipliers**, not satisfaction levels
- A value of 10 means "strongly desires this"
- A value of 1 means "barely cares about this"
- These get modified by traits and enablement rules

---

### 3. Character Traits

**Purpose:** Personality traits that modify base cravings.

**Key Fields:**
- `id` - Unique identifier (e.g., "ambitious", "glutton")
- `name` - Display name
- `description` - Trait effects
- `rarity` - common/uncommon/rare/very-rare
- `cravingMultipliers` - Modifies base cravings
  - `coarse` - Array of 9 multipliers (default: 1.0)
  - `fine` - Array of 50 multipliers (default: 1.0)

**Multiplier Logic:**
```
final_craving = base_craving × trait_multiplier

Examples:
- 1.0 = no change
- 1.5 = 50% stronger craving
- 0.5 = 50% weaker craving
- 2.0 = double the craving
```

**Example:**
```json
{
  "id": "ambitious",
  "name": "Ambitious",
  "description": "Craves achievement and recognition",
  "rarity": "uncommon",
  "cravingMultipliers": {
    "coarse": [1.0, 1.0, 1.0, 1.5, 1.8, 1.0, 1.2, 1.3, 0.8],
    "fine": [/* psychological & status dimensions increased */]
  }
}
```

**How to Use:**
1. Navigate to **Character Traits**
2. Click **Add Character Trait**
3. Set rarity (affects spawn rate)
4. Use the vector editor to set multipliers
   - Focus on 2-3 dimensions to create clear personality
   - Group by parent coarse for easier editing
5. Test with View to see the multiplier heatmap
6. Save

**Best Practice:**
- Keep multipliers in range [0.5, 2.5] for balance
- Focus modifications on 2-3 related dimensions
- Create contrasting traits (ambitious ↔ content, glutton ↔ ascetic)

---

### 4. Fulfillment Vectors

**Purpose:** Define how commodities satisfy character needs.

**Key Fields:**
- `id` - Commodity ID this fulfillment vector applies to
- `fulfillmentVector` - How much this commodity satisfies each dimension
  - `coarse` - Array of 9 numbers (usually auto-calculated from fine)
  - `fine` - Object mapping dimension IDs to satisfaction amounts
- `tags` - Classification tags
- `durability` - consumable/durable/permanent
- `qualityMultipliers` - How quality affects fulfillment
  - `poor`, `basic`, `good`, `luxury`, `masterwork`
- `reusableValue` - For durable goods, how many uses
- `notes` - Design notes

**Example:**
```json
{
  "id": "bread",
  "fulfillmentVector": {
    "coarse": [0, 0, 0, 0, 0, 0, 0, 0, 0],
    "fine": {
      "biological_nutrition_grain": 15,
      "biological_nutrition_protein": 2,
      "touch_sensory_luxury": 3,
      "comfort_warmth_shelter": 2
    }
  },
  "tags": ["processed_food", "comfort", "nutrition"],
  "durability": "consumable",
  "qualityMultipliers": {
    "poor": 0.6,
    "basic": 1.0,
    "good": 1.3,
    "luxury": 1.6,
    "masterwork": 2.0
  }
}
```

**Quality System:**
```
actual_fulfillment = base_fulfillment × quality_multiplier

Example with bread:
- Poor bread: 15 × 0.6 = 9 grain nutrition
- Basic bread: 15 × 1.0 = 15 grain nutrition
- Luxury bread: 15 × 1.6 = 24 grain nutrition
```

**How to Use - Manual Method:**
1. Navigate to **Fulfillment Vectors**
2. Click **Add Fulfillment Vector**
3. Select commodity
4. Use the 50D vector editor to set fulfillment values
5. Add tags for categorization
6. Set durability type
7. Configure quality multipliers
8. Save

**How to Use - Quick Fill Method (RECOMMENDED):**
1. Navigate to **Fulfillment Vectors**
2. Click **Quick Fill** button
3. Select commodities to fill (or use "Select All & Auto-Fill")
4. Templates are auto-suggested based on commodity category
5. Review and adjust template/quality preset if needed
6. Click **Apply Templates**
7. Done! All selected commodities now have fulfillment vectors

**Quick Fill Templates Available:**
- **Food:** grain, fruit, vegetable, animal_product, processed_food, alcohol
- **Clothing:** clothing_basic, clothing_luxury
- **Home:** furniture, construction
- **Tools:** tools
- **Luxury:** luxury, refined_metal, jewelry
- **Textiles:** textile_raw, textile
- **Resources:** raw_mineral, fuel, dye
- **Special:** medicine, hygiene, seed, special_berry, plant, crafting

**Best Practice:**
- Use Quick Fill for initial setup
- Fine-tune important commodities manually afterward
- Keep fulfillment values in range [1-25] for balance
- Higher-tier goods should satisfy multiple dimensions
- Consider secondary satisfactions (bread gives comfort, not just nutrition)

---

### 5. Enablement Rules

**Purpose:** Dynamically modify cravings based on life events and circumstances.

**Key Fields:**
- `id` - Unique identifier
- `name` - Display name
- `description` - When and why this triggers
- `trigger` - Condition that activates this rule
  - `type` - Trigger type (see below)
  - Additional fields based on type
- `effect` - What happens when triggered
  - `cravingModifier` - Added to character's cravings
    - `coarse` - Array of 9 additive modifiers
    - `fine` - Array of 50 additive modifiers
  - `permanent` - If true, effect lasts forever (for class changes)

**Trigger Types:**

1. **owns_commodity_tag**
   ```json
   {
     "type": "owns_commodity_tag",
     "tag": "shelter",
     "minQuantity": 1
   }
   ```

2. **has_relationship**
   ```json
   {
     "type": "has_relationship",
     "relationship": "spouse"  // or "child", "parent", etc.
   }
   ```

3. **satisfaction_above**
   ```json
   {
     "type": "satisfaction_above",
     "cravingType": "biological",
     "threshold": 80
   }
   ```

4. **satisfaction_below**
   ```json
   {
     "type": "satisfaction_below",
     "cravingType": "safety",
     "threshold": 30
   }
   ```

5. **class_change**
   ```json
   {
     "type": "class_change",
     "newClass": "upper",
     "permanent": true
   }
   ```

**Modifier Logic:**
```
final_craving = (base × trait_multiplier) + Σ(enablement_modifiers)

Example:
- Base biological: 15
- Ambitious trait: ×1.0 = 15
- Has child: +2 = 17
- Owns house: +0 = 17
- Final: 17
```

**Example:**
```json
{
  "id": "has_children",
  "name": "Parenthood Effect",
  "description": "Having children dramatically increases biological and safety needs",
  "trigger": {
    "type": "has_relationship",
    "relationship": "child"
  },
  "effect": {
    "cravingModifier": {
      "coarse": [+2, +4, +2, +1, 0, +1, 0, 0, 0],
      "fine": [/* specific dimension increases */]
    },
    "permanent": false
  }
}
```

**How to Use:**
1. Navigate to **Enablement Rules**
2. Click **Add Enablement Rule**
3. Select trigger type
4. Fill trigger-specific fields
5. Use vector editor to set craving modifiers
   - Positive values increase cravings
   - Negative values decrease cravings
6. Check "permanent" for irreversible changes (class promotions)
7. Save

**Best Practice:**
- Use for major life events (marriage, children, homeownership)
- Use for class mobility effects
- Use for Maslow-style hierarchies (high safety → more psychological needs)
- Keep modifiers in range [-5, +5] for balance

**Built-in Rules Examples:**
- **Homeownership**: Increases furniture, decoration, status needs
- **Marriage**: Increases biological, safety, social needs
- **Children**: Dramatically increases biological & safety needs
- **Wealth Accumulation**: Owning gold makes you want more gold
- **Hierarchy of Needs**: High biological satisfaction → increased aspirational needs
- **Class Promotion**: Permanent shift in entire craving profile
- **Low Safety Stress**: Low safety increases all other cravings (stress effect)
- **Social Isolation**: Low social connection increases vices, decreases other needs

---

### 6. Substitution Calculator

**Purpose:** Analyze commodity similarity for balancing and substitution mechanics.

**How It Works:**
1. Calculates **Cosine Similarity** between fulfillment vectors
   - Measures directional similarity (what needs they satisfy)
   - Range: 0 (completely different) to 1 (identical direction)

2. Calculates **Euclidean Distance** between fulfillment vectors
   - Measures magnitude similarity (how much they satisfy)
   - Lower is more similar

3. Combines metrics into **Overall Similarity Score**
   - Formula: `0.7 × cosine + 0.3 × normalized_distance`
   - Range: 0 (no similarity) to 1 (perfect substitutes)

**Similarity Ratings:**
- **Excellent (90%+)**: Perfect substitutes, almost interchangeable
- **Good (70-90%)**: Strong substitutes, similar fulfillment profiles
- **Moderate (50-70%)**: Partial substitutes, overlap in some needs
- **Weak (30-50%)**: Limited substitution potential
- **Poor (<30%)**: Not substitutes, fulfill different needs

**How to Use:**
1. Navigate to **Substitution Calculator**
2. Select a commodity from dropdown
3. Adjust similarity threshold slider (default 50%)
4. Review ranked table of similar commodities
5. Use results to:
   - Balance production chains
   - Identify redundant commodities
   - Design substitution mechanics
   - Plan economic diversity

**Example Results:**
```
Selected: Wheat

Rank  Commodity    Category  Similarity  Cosine  Distance
1     Rice         grain     94%         0.98    2.3
2     Barley       grain     91%         0.96    3.1
3     Oats         grain     88%         0.94    4.2
4     Bread        food      67%         0.72    12.5
5     Pasta        food      61%         0.68    15.8
```

**Interpretation:**
- Rice, barley, oats are excellent substitutes for wheat
- Characters who need "grain nutrition" will accept any of these
- Bread is a moderate substitute (processed form of wheat)
- Production chains can offer choices without breaking balance

---

## Getting Started

### Prerequisites

1. **Tauri Desktop App** running
2. **Data directory** exists at: `../data/`
3. **JSON files** present (created automatically if missing)

### First Launch

1. Run the Information System app
2. You'll see two main sections in the sidebar:
   - **Production System** (5 managers)
   - **Craving System** (6 managers + calculator)
3. Start with the Production System, then move to Craving System

---

## Step-by-Step Setup Guide

### Phase 1: Foundation (Production System)

#### Step 1: Define Work Categories
**Time: 10 minutes**

1. Open **Work Categories**
2. Create broad skill classifications:
   - Agriculture
   - Animal Husbandry
   - Food Preparation
   - Baking
   - Woodworking
   - Mining
   - Metalworking
   - Textile Weaving
   - Healthcare
   - Education
3. Add descriptions for clarity

**Why first?** These are referenced by Building Types, Worker Types, and Recipes.

---

#### Step 2: Create Commodities
**Time: 30-60 minutes**

1. Open **Commodities**
2. Create all goods your economy will have
3. Organize by category:
   - **Raw Materials:** wood, stone, ore, clay, wool, cotton
   - **Grains:** wheat, rice, barley, oats, corn
   - **Produce:** apples, carrots, cabbage, potatoes
   - **Animal Products:** milk, eggs, meat, leather
   - **Processed Foods:** bread, cheese, beer, wine
   - **Textiles:** cloth, linen, silk
   - **Goods:** clothing, furniture, tools, jewelry
   - **Services:** education, healthcare, entertainment

4. Set appropriate base values
5. Use consistent naming

**Why second?** Recipes need commodity IDs as inputs/outputs.

---

#### Step 3: Define Building Types
**Time: 20-30 minutes**

1. Open **Building Types**
2. Create production buildings:
   - Farm (Agriculture)
   - Bakery (Baking)
   - Mine (Mining)
   - Smithy (Metalworking)
   - Weaver (Textile Weaving)
3. Create service buildings:
   - School (Education)
   - Clinic (Healthcare)
   - Tavern (Hospitality)
4. Create housing:
   - Cottage (Lower class)
   - House (Middle class)
   - Manor (Upper/Elite class)

5. For each building:
   - Set 2-letter label and color
   - Configure size (width/height)
   - Add compatible work categories
   - Set worker efficiency multipliers
   - Configure storage capacity

---

#### Step 4: Create Worker Types
**Time: 15 minutes**

1. Open **Worker Types**
2. Create workers matching your work categories:
   - Farmer (Agriculture)
   - Baker (Baking, Food Preparation)
   - Miner (Mining)
   - Smith (Metalworking, Blacksmithing)
   - Weaver (Textile Weaving)
   - Teacher (Education)
   - Doctor (Healthcare)

3. Set minimum wages based on skill level
4. Assign appropriate work categories

---

#### Step 5: Configure Building Recipes
**Time: 45-90 minutes**

1. Open **Building Recipes**
2. For each building, create production recipes
3. Example production chain:

```
Farm:
  - Grow Wheat: → 10 wheat (10 min)
  - Raise Chickens: → 5 eggs (15 min)

Mill:
  - Grind Wheat: 10 wheat → 8 flour (5 min)

Bakery:
  - Bake Bread: 5 flour + 1 water → 4 bread (10 min)
  - Make Pastries: 3 flour + 3 eggs + 1 milk → 6 pastries (15 min)

Mine:
  - Mine Iron: → 5 iron_ore (20 min)

Smithy:
  - Smelt Iron: 5 iron_ore + 2 coal → 3 iron_ingot (15 min)
  - Forge Tools: 2 iron_ingot → 1 tools (20 min)
```

4. Set appropriate worker requirements and wages

---

### Phase 2: Character Needs (Craving System)

#### Step 6: Review Craving Dimensions
**Time: 15 minutes**

1. Open **Craving Dimensions**
2. Review **Coarse Dimensions (9D)** tab
3. Understand the hierarchy:
   - Biological, Safety (survival)
   - Touch, Psychological, Social (comfort/growth)
   - Exotic, Shiny, Vice (aspirational/special)

4. Switch to **Fine Dimensions (50D)** tab
5. Review the 50 specific needs
6. Understand parent-child relationships

7. **Optional:** Adjust decay rates
   - Biological: faster decay (0.05 = 5% per day)
   - Psychological: slower decay (0.01 = 1% per day)

**Why sixth?** You need to understand dimensions before creating fulfillment vectors.

---

#### Step 7: Configure Character Classes
**Time: 30 minutes**

1. Open **Character Classes**
2. Review the 4 default classes: Lower, Middle, Upper, Elite
3. For each class, click **Edit** and adjust:

   **Lower Class:**
   - High: Biological (15), Safety (12), Vice (3)
   - Medium: Social Connection (8), Touch (8)
   - Low: Social Status (2), Psychological (5)

   **Middle Class:**
   - Balanced across all categories
   - Moderate status desires (8)
   - Growing psychological needs (10)

   **Upper Class:**
   - Lower biological (8) - taken for granted
   - High status (15), psychological (12)
   - Some exotic goods (5)

   **Elite:**
   - Minimal biological (5)
   - Maximum status (20), exotic (15), shiny (15)
   - High psychological (15)

4. Adjust thresholds:
   - Lower: emigration 30%, riot 0.05
   - Elite: emigration 50%, riot 0.02

5. Set quality preferences:
   - Lower: accepts poor/basic, rejects masterwork
   - Elite: accepts luxury/masterwork, rejects poor

---

#### Step 8: Create Character Traits
**Time: 30-45 minutes**

1. Open **Character Traits**
2. Create personality traits that multiply base cravings
3. Recommended traits:

   **Common (80% spawn rate):**
   - Content (↓ status, ↑ social connection)
   - Practical (↑ biological, ↓ exotic/shiny)
   - Social (↑ social connection, ↓ psychological)

   **Uncommon (15% spawn rate):**
   - Ambitious (↑ status, ↑ psychological, ↓ vice)
   - Glutton (↑ biological, ↑ vice)
   - Intellectual (↑ psychological, ↓ biological)
   - Materialistic (↑ shiny, ↑ status, ↑ exotic)

   **Rare (4% spawn rate):**
   - Ascetic (↓ biological, ↓ touch, ↑ psychological)
   - Hedonist (↑ vice, ↑ exotic, ↑ touch)
   - Recluse (↓ social connection, ↑ psychological)

   **Very Rare (1% spawn rate):**
   - Enlightened (↑↑ psychological, ↓↓ material needs)
   - Collector (↑↑↑ shiny objects, ↑ exotic)

4. Use multipliers in range [0.5, 2.5]
5. Focus on 2-3 dimensions per trait

---

#### Step 9: Create Fulfillment Vectors (QUICK FILL)
**Time: 15 minutes + 1-2 hours refinement**

1. Open **Fulfillment Vectors**
2. Click **Quick Fill** button (shows count of missing vectors)
3. Click **Select All & Auto-Fill**
4. Review auto-suggested templates:
   - Templates chosen based on commodity category
   - Quality presets chosen based on category and base value

5. Override specific templates if needed
6. Click **Apply Templates**
7. Done! All commodities now have fulfillment vectors

8. **Refinement (optional but recommended):**
   - Click **Edit** on important commodities
   - Fine-tune fulfillment values
   - Add secondary satisfactions
   - Adjust quality multipliers

**Templates Applied:**
- Grains → grain template (nutrition-focused)
- Fruits → fruit template (nutrition + luxury + health)
- Processed food → processed_food template (nutrition + comfort)
- Clothing → clothing_basic or clothing_luxury
- Furniture → furniture template (comfort + status)
- Luxury items → luxury template (status + aesthetics)

---

#### Step 10: Configure Enablement Rules
**Time: 30 minutes**

1. Open **Enablement Rules**
2. Review the 10 default rules (already configured)
3. **Optional:** Create custom rules for your game

**Default Rules:**
- Homeownership Effect
- Marriage Effect
- Parenthood Effect
- Wealth Accumulation Desire
- Hierarchy of Needs
- Class Promotion to Upper
- Class Promotion to Elite
- Education Multiplier
- Low Safety Stress
- Social Isolation Effect

4. Test by creating new rules:
   - "Has pet" → +3 social connection
   - "Owns art" → +2 aesthetics, +1 status
   - "High vice satisfaction" → -2 productivity

---

#### Step 11: Analyze with Substitution Calculator
**Time: 15 minutes**

1. Open **Substitution Calculator**
2. Select key commodities and review substitutes:
   - Which grains are interchangeable?
   - What can substitute for meat?
   - Are there redundant luxury items?

3. Use insights to:
   - Balance production chains
   - Ensure economic diversity
   - Plan scarcity mechanics

---

### Phase 3: Testing & Refinement

#### Step 12: Validate Data Consistency
**Time: 30 minutes**

1. **Recipe Validation:**
   - Do all recipe inputs exist as commodities?
   - Do all recipe outputs exist as commodities?
   - Are worker requirements reasonable?

2. **Fulfillment Validation:**
   - Does every commodity have a fulfillment vector?
   - Are fulfillment values balanced (1-25 range)?
   - Do quality multipliers make sense?

3. **Balance Validation:**
   - Run Substitution Calculator on key commodities
   - Are there any perfect substitutes (95%+)? (might be redundant)
   - Are there enough options in each category?

---

#### Step 13: Playtest in Game
**Time: Ongoing**

1. Export data to game
2. Test character behavior:
   - Do characters consume appropriate goods?
   - Do classes behave differently?
   - Do traits create noticeable personality?

3. Monitor satisfaction levels:
   - Are needs being met?
   - Are decay rates too fast/slow?
   - Are critical thresholds appropriate?

4. Test production chains:
   - Are recipes profitable?
   - Are production times balanced?
   - Are worker wages sustainable?

5. Iterate based on findings

---

## Advanced Features

### Vector Editors

All craving/fulfillment editors support:
- **50-dimensional sliders** for fine control
- **Coarse aggregation view** to see high-level effects
- **Group by parent** option for organized editing
- **Value presets** for quick adjustments

### Heatmap Visualization

View 50D vectors as color grids:
- **Red/Hot** = high values (strong craving/fulfillment)
- **Blue/Cold** = low values (weak craving/fulfillment)
- **Grouped by coarse dimension** for easy scanning

### Radar Charts

View 9D coarse vectors as radar charts:
- Easily see which dimensions dominate
- Compare multiple profiles visually
- Identify imbalances

### Bulk Operations

- **Quick Fill** for fulfillment vectors
- **Export/Import** JSON (manual via file system)
- **Batch editing** via table filters and sorts

---

## Best Practices

### Economy Design

1. **Start Simple**
   - Begin with 20-30 commodities
   - Add complexity gradually
   - Test each addition

2. **Production Chains**
   - Create 3-4 tier chains (raw → processed → finished → luxury)
   - Ensure multiple paths to same fulfillment
   - Balance production times with consumption rates

3. **Worker Balance**
   - Ensure all work categories are needed
   - Create specialization benefits
   - Balance wages with commodity values

### Craving System Design

1. **Fulfillment Values**
   - Keep in range [1-25] for most goods
   - Reserve 20+ for luxuries and rare items
   - Use secondary fulfillments liberally

2. **Class Differentiation**
   - Make classes feel distinct
   - Create aspiration gradients (lower wants upper's lifestyle)
   - Don't make any class "boring"

3. **Trait Design**
   - Create opposing pairs (ambitious ↔ content)
   - Make rare traits impactful
   - Avoid traits that are always bad

4. **Decay Rates**
   - Faster for biological (0.03-0.08)
   - Moderate for safety/social (0.01-0.03)
   - Slower for aspirational (0.005-0.01)
   - Consider seasonal variations

5. **Substitution**
   - Aim for 3-5 substitutes per commodity (50-80% similarity)
   - Avoid perfect substitutes (redundant)
   - Create substitution tiers (good/acceptable/poor)

### Data Organization

1. **Naming Conventions**
   - Use snake_case for IDs: `wheat_flour`, `iron_ingot`
   - Use Title Case for names: "Wheat Flour", "Iron Ingot"
   - Be consistent!

2. **Categories**
   - Keep categories small (5-10 items each)
   - Use hierarchy: material → textile → cotton
   - Tag liberally

3. **Version Control**
   - Backup JSON files regularly
   - Use git for data directory
   - Document major changes

---

## Troubleshooting

### Common Issues

**"Cannot find commodity XYZ in recipe"**
- Cause: Recipe references non-existent commodity
- Fix: Create the commodity or fix the recipe's input/output IDs

**"Fulfillment vector not showing in game"**
- Cause: Commodity ID mismatch between commodities.json and fulfillment_vectors.json
- Fix: Ensure IDs match exactly (case-sensitive)

**"Characters not consuming goods"**
- Cause: Fulfillment values too low, or wrong dimensions filled
- Fix: Check fulfillment vectors satisfy the character class's high-priority dimensions

**"All characters emigrating"**
- Cause: Satisfaction dropping below emigration threshold
- Fix: Check decay rates, ensure sufficient production, lower thresholds

**"No similar commodities found in Substitution Calculator"**
- Cause: Selected commodity has no fulfillment vector
- Fix: Add fulfillment vector for the commodity

**"Worker efficiency always 0%"**
- Cause: Building's workCategories doesn't match worker's workCategories
- Fix: Add overlapping work categories

### Performance Tips

1. **Large Datasets:**
   - Use pagination controls in tables
   - Filter and sort before editing
   - Close unused tabs

2. **Complex Vectors:**
   - Use Coarse view for quick edits
   - Group by parent for organization
   - Use presets when available

---

## Mathematical Formulas

### Satisfaction Calculation

```python
# Character's final craving for dimension i
base_craving[i] = character_class.baseCravingVector[i]
trait_multiplier[i] = character_trait.cravingMultipliers[i]
enablement_sum[i] = sum(rule.cravingModifier[i] for rule in active_rules)

final_craving[i] = (base_craving[i] × trait_multiplier[i]) + enablement_sum[i]

# Satisfaction from consumption
consumption_fulfillment[i] = sum(
    commodity.fulfillmentVector[i] × quantity × quality_multiplier
    for commodity in consumed_goods
)

# Satisfaction level (0-100%)
satisfaction[i] = min(100, (consumption_fulfillment[i] / final_craving[i]) × 100)

# Apply decay
satisfaction[i] -= satisfaction[i] × decay_rate[i] × days_passed

# Check thresholds
if satisfaction[i] < critical_threshold[i]:
    trigger_crisis()

if overall_satisfaction < emigration_threshold:
    consider_emigration()
```

### Coarse Aggregation

```python
# Roll up fine dimensions into coarse
coarse_satisfaction[c] = sum(
    fine_satisfaction[f] × aggregation_weight[f]
    for all fine f where parent_coarse[f] == c
)
```

### Substitution Similarity

```python
# Cosine similarity
def cosine_similarity(vec1, vec2):
    dot_product = sum(vec1[i] × vec2[i] for i in dimensions)
    magnitude1 = sqrt(sum(vec1[i]² for i in dimensions))
    magnitude2 = sqrt(sum(vec2[i]² for i in dimensions))
    return dot_product / (magnitude1 × magnitude2)

# Euclidean distance
def euclidean_distance(vec1, vec2):
    return sqrt(sum((vec1[i] - vec2[i])² for i in dimensions))

# Overall similarity
normalized_distance = 1 - min(euclidean_distance / 100, 1)
similarity = 0.7 × cosine_similarity + 0.3 × normalized_distance
```

---

## Appendix: Default Configurations

### Coarse Dimensions Reference

| Index | ID | Name | Tier | Critical | Emigration | Productivity |
|-------|-----|------|------|----------|------------|--------------|
| 0 | biological | Biological | survival | 20% | 0.40 | 0.50 |
| 1 | safety | Safety | security | 30% | 0.25 | 0.30 |
| 2 | touch | Touch | comfort | 25% | 0.10 | 0.20 |
| 3 | psychological | Psychological | social_psych | 20% | 0.15 | 0.25 |
| 4 | social_status | Social Status | social_psych | 15% | 0.05 | 0.15 |
| 5 | social_connection | Social Connection | social_psych | 30% | 0.15 | 0.20 |
| 6 | exotic_goods | Exotic Goods | aspirational | 10% | 0.02 | 0.05 |
| 7 | shiny_objects | Shiny Objects | aspirational | 10% | 0.01 | 0.05 |
| 8 | vice | Vice | special | 5% | 0.00 | -0.10 |

### Recommended Decay Rates

| Dimension | Decay Rate | Reasoning |
|-----------|------------|-----------|
| Biological | 0.05 | Food needed daily |
| Safety | 0.02 | Shelter constant need |
| Touch | 0.015 | Clothing wears slowly |
| Psychological | 0.01 | Mental needs gradual |
| Social Status | 0.008 | Reputation fades slowly |
| Social Connection | 0.012 | Relationships need maintenance |
| Exotic Goods | 0.005 | Novelty lasts longer |
| Shiny Objects | 0.003 | Possessions don't decay |
| Vice | 0.02 | Addictions resurface |

---

## Quick Reference: Setup Checklist

- [ ] **Work Categories** - Define skill classifications
- [ ] **Commodities** - Create all goods/services
- [ ] **Building Types** - Define structures and worker compatibility
- [ ] **Worker Types** - Create labor force
- [ ] **Building Recipes** - Configure production chains
- [ ] **Craving Dimensions** - Review and adjust decay rates
- [ ] **Character Classes** - Adjust base cravings and thresholds
- [ ] **Character Traits** - Create personality modifiers
- [ ] **Fulfillment Vectors** - Quick Fill all commodities
- [ ] **Enablement Rules** - Review and customize life event rules
- [ ] **Substitution Analysis** - Check commodity balance
- [ ] **Playtest** - Test in game and iterate

---

## Conclusion

The CraveTown Information System provides a comprehensive framework for creating a deep, balanced economy with realistic character simulation. By following this guide, you can:

1. Design complex production chains
2. Model nuanced character needs using multi-dimensional mathematics
3. Create distinct social classes and personalities
4. Balance consumption and production dynamically
5. Analyze and optimize your game's economy

The key to success is **iteration**: start simple, test frequently, and refine based on gameplay. The system is designed to be flexible - adjust values, add dimensions, and experiment until your town feels alive.

Happy town building! 🏰

---

## Additional Resources

- **JSON File Locations:**
  - Production: `../data/*.json`
  - Craving System: `../data/craving_system/*.json`

- **Backup Strategy:**
  - Copy entire `data/` directory before major changes
  - Use git for version control
  - Export important configurations to separate files

- **Community:**
  - Share your fulfillment templates
  - Compare character class profiles
  - Discuss balance strategies

---

**Document Version:** 1.0.0
**Last Updated:** 2025-11-25
**Information System Version:** 1.0.0
