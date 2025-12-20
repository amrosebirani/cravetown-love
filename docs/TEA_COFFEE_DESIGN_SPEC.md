# Tea & Coffee Production System - Design Specification

**Version:** 1.0
**Date:** December 20, 2024
**Status:** ✅ IMPLEMENTED

---

## Table of Contents

1. [Overview](#overview)
2. [Commodity Definitions](#commodity-definitions)
3. [Farm Buildings](#farm-buildings)
4. [Production Buildings](#production-buildings)
5. [Recipe Specifications](#recipe-specifications)
6. [Worker Types](#worker-types)
7. [Craving Satisfaction](#craving-satisfaction)
8. [Implementation Files](#implementation-files)
9. [Real-World Based Values](#real-world-based-values)

---

## 1. Overview

This specification adds a complete tea and coffee production chain to Cravetown:

**Production Chain:**
```
Seeds (inventory)
  ↓
Tea/Coffee Farms (with water input)
  ↓
Tea Leaves / Coffee Leaves
  ↓
Beverage Shop OR Restaurant
  ↓
Tea Drink / Coffee Drink (final products)
```

**Key Design Principles:**
- Tea leaves produce **3x faster** than coffee leaves (real-world reflection)
- Both satisfy **Biological + Social + Psychological** cravings
- Coffee has **higher satisfaction** than tea (except touch, which is equal)
- Introduces new **Barista** worker type
- Uses existing **Farmer** worker type
- Follows existing building upgrade levels (0, 1, 2)

---

## 2. Commodity Definitions

### 2.1 New Commodities

All new commodities to be added to `commodity_cache.json`:

| Commodity ID | Name | Category | Perishable | Quality Tier | Description |
|---|---|---|---|---|---|
| `tea_seed` | Tea Seeds | seed | false | basic | Seeds for growing tea plants |
| `coffee_seed` | Coffee Seeds | seed | false | basic | Seeds for growing coffee plants |
| `tea_leaves` | Tea Leaves | raw_material | true | basic | Fresh tea leaves for brewing |
| `coffee_leaves` | Coffee Leaves | raw_material | true | basic | Fresh coffee beans/leaves for brewing |
| `tea_drink` | Tea | beverage | true | basic | Hot brewed tea |
| `coffee_drink` | Coffee | beverage | true | basic | Hot brewed coffee |

**Notes:**
- Seeds are NOT perishable (can be stored indefinitely)
- Leaves ARE perishable (shelf life logic to be added later)
- Final drinks ARE perishable (shelf life logic to be added later)
- Quality tier follows existing grain model (static, not dynamic)
- No rarity level (food commodities don't use this)

---

## 3. Farm Buildings

### 3.1 Tea Farm

**Building Type ID:** `tea_farm`
**Category:** agriculture
**Label:** TF
**Color:** [0.2, 0.5, 0.3] (tea green)
**Description:** Cultivates tea plants and harvests tea leaves

**Work Categories:**
- Agriculture (efficiency: 1.0)
- General Labor (efficiency: 0.3)

**Placement Constraints:**
- Requires: Soil Fertility (weight: 0.6, min: 0.2)
- Requires: Ground Water (weight: 0.4, min: 0.15)
- Formula: weighted_average
- Warning threshold: 0.4
- Blocking threshold: 0.2

**Upgrade Levels:**

| Level | Name | Stations | Width | Height | Construction Materials | Storage (Input/Output) |
|---|---|---|---|---|---|---|
| 0 | Small Tea Farm | 2 | 80 | 80 | wood: 30, hoe: 2, tea_seed: 50 | 300 / 500 |
| 1 | Medium Tea Farm | 4 | 120 | 120 | wood: 30, stone: 15, hoe: 2, tea_seed: 25 | 500 / 1000 |
| 2 | Large Tea Farm | 8 | 180 | 180 | wood: 50, stone: 30, hoe: 4, scythe: 4, tea_seed: 30 | 800 / 2000 |

### 3.2 Coffee Farm

**Building Type ID:** `coffee_farm`
**Category:** agriculture
**Label:** CF
**Color:** [0.4, 0.25, 0.15] (coffee brown)
**Description:** Cultivates coffee plants and harvests coffee beans

**Work Categories:**
- Agriculture (efficiency: 1.0)
- General Labor (efficiency: 0.3)

**Placement Constraints:**
- Requires: Soil Fertility (weight: 0.7, min: 0.25)
- Requires: Ground Water (weight: 0.3, min: 0.2)
- Formula: weighted_average
- Warning threshold: 0.45
- Blocking threshold: 0.25

**Upgrade Levels:**

| Level | Name | Stations | Width | Height | Construction Materials | Storage (Input/Output) |
|---|---|---|---|---|---|---|
| 0 | Small Coffee Farm | 2 | 80 | 80 | wood: 30, hoe: 2, coffee_seed: 50 | 300 / 500 |
| 1 | Medium Coffee Farm | 4 | 120 | 120 | wood: 30, stone: 15, hoe: 2, coffee_seed: 25 | 500 / 1000 |
| 2 | Large Coffee Farm | 8 | 180 | 180 | wood: 50, stone: 30, hoe: 4, scythe: 4, coffee_seed: 30 | 800 / 2000 |

**Note:** Coffee requires slightly higher fertility/water than tea (real-world accuracy)

---

## 4. Production Buildings

### 4.1 Beverage Shop (NEW)

**Building Type ID:** `beverage_shop`
**Category:** production
**Label:** BS
**Color:** [0.6, 0.4, 0.2] (warm brown, similar to bakery)
**Description:** Specializes in preparing hot beverages like tea and coffee

**Work Categories:**
- Beverage Preparation (efficiency: 1.0)
- Hospitality (efficiency: 0.6)

**Upgrade Levels:**

| Level | Name | Stations | Width | Height | Construction Materials | Storage (Input/Output) |
|---|---|---|---|---|---|---|
| 0 | Basic Beverage Shop | 1 | 49 | 49 | wood: 35, bricks: 25 | 180 / 180 |
| 1 | Improved Beverage Shop | 2 | 70 | 70 | wood: 18, bricks: 13 | 300 / 300 |
| 2 | Advanced Beverage Shop | 4 | 105 | 105 | wood: 28, bricks: 20 | 480 / 600 |

**Notes:**
- Follows bakery sizing pattern
- Starts with 1 station (like bakery Level 0)
- Requires new **Barista** worker type for full efficiency
- Can only produce tea and coffee (for now)

### 4.2 Restaurant (UPDATED)

**Building Type ID:** `restaurant` (existing)
**Changes:** Add tea and coffee production recipes

No structural changes to restaurant building definition.
Only add new recipes (see Section 5).

---

## 5. Recipe Specifications

### 5.1 Tea Farm Production

**Building Type:** tea_farm
**Recipe Name:** Tea Leaf Harvesting
**Category:** Raw Material
**Production Time:** 90 seconds (per batch)

**Inputs:**
- water: 2 units (ongoing input - simulates irrigation)

**Outputs:**
- tea_leaves: 24 units

**Notes:**
- Real-world: Tea harvest cycle is ~60-90 days, scaled to 90 seconds for gameplay
- Water represents irrigation requirement
- Level 0 farm (2 stations): 24 leaves/90s = 16 leaves/min
- Yields scale with station count

### 5.2 Coffee Farm Production

**Building Type:** coffee_farm
**Recipe Name:** Coffee Bean Harvesting
**Category:** Raw Material
**Production Time:** 270 seconds (per batch)
**TEA IS 3X FASTER than coffee**

**Inputs:**
- water: 3 units (ongoing input - coffee needs more water)

**Outputs:**
- coffee_leaves: 20 units

**Notes:**
- Real-world: Coffee harvest takes 3-4 years initial, then annual cycles
- 3x slower than tea (as specified)
- Level 0 farm (2 stations): 20 beans/270s = 4.4 beans/min
- Requires more water than tea (real-world accurate)

### 5.3 Tea Drink Production (Beverage Shop)

**Building Type:** beverage_shop
**Recipe Name:** Tea Brewing
**Category:** Consumable
**Production Time:** 60 seconds (per batch)

**Inputs (per 10 cups):**
- tea_leaves: 4 units
- water: 8 units
- sugar: 2 units
- fuel: 1 unit (for boiling)
- milk: 2 units
- spices: 0.5 units (masala chai style)

**Outputs:**
- tea_drink: 10 cups

**Notes:**
- Real-world: Professional tea brewing takes 3-5 minutes
- Spices give it authentic Indian chai flavor
- Ratio allows for sustainable production loop

### 5.4 Coffee Drink Production (Beverage Shop)

**Building Type:** beverage_shop
**Recipe Name:** Coffee Brewing
**Category:** Consumable
**Production Time:** 75 seconds (per batch)

**Inputs (per 10 cups):**
- coffee_leaves: 5 units
- water: 8 units
- sugar: 2 units
- fuel: 1 unit (for brewing)
- milk: 2 units

**Outputs:**
- coffee_drink: 10 cups

**Notes:**
- Real-world: Espresso/filter coffee takes 2-4 minutes
- Uses more coffee beans than tea (stronger brew)
- Slightly longer production time than tea (more involved process)
- No spices (traditional coffee)

### 5.5 Tea Drink Production (Restaurant)

**Building Type:** restaurant
**Recipe Name:** Restaurant Tea Service
**Category:** Consumable
**Production Time:** 60 seconds (same as beverage shop)

**Inputs:** (same as beverage shop)
**Outputs:** tea_drink: 10 cups

**Notes:**
- Restaurant can produce tea at same rate as Beverage Shop
- Uses existing "Food Preparation" worker category

### 5.6 Coffee Drink Production (Restaurant)

**Building Type:** restaurant
**Recipe Name:** Restaurant Coffee Service
**Category:** Consumable
**Production Time:** 75 seconds (same as beverage shop)

**Inputs:** (same as beverage shop)
**Outputs:** coffee_drink: 10 cups

**Notes:**
- Restaurant can produce coffee at same rate as Beverage Shop
- Uses existing "Food Preparation" worker category

---

## 6. Worker Types

### 6.1 Barista (NEW)

**Worker Type ID:** `barista`
**Category:** Specialized Production
**Description:** Expert in preparing hot beverages, particularly tea and coffee

**Compatible Workplaces:**
- beverage_shop (efficiency: 1.0)
- restaurant (efficiency: 0.7)

**Skill Level System:**
- Follows existing skill level 1-5 system
- Efficiency bonus: 1.0 + ((skillLevel - 1) × 0.15)
- Level 1: 1.0x efficiency
- Level 5: 1.6x efficiency (master barista)

**Notes:**
- **This is a completely new worker type**
- Must be added to character vocation system
- Can work at restaurant but with reduced efficiency
- Barista at restaurant = 0.7x efficiency (not their specialty)

### 6.2 Farmer (EXISTING - No Changes)

**Worker Type ID:** `farmer`
**Use For:** Tea Farm, Coffee Farm

No changes needed - existing farmer vocation works for both new farm types.

---

## 7. Craving Satisfaction

### 7.1 Tea Drink

**Commodity ID:** `tea_drink`

**Fulfillment Vectors:**
- **Biological:** 18 (moderate energy/hydration)
- **Social Connection:** 22 (tea culture, social gathering)
- **Psychological:** 24 (awakening, focus, comfort)
- **Touch/Sensory:** 14 (warmth, aroma)

**Total Satisfaction Value:** 78

**Explanation:**
- Lower biological than coffee (less caffeine)
- High social (tea time, conversations)
- High psychological (calming + alertness)
- Moderate sensory (pleasant warmth)

### 7.2 Coffee Drink

**Commodity ID:** `coffee_drink`

**Fulfillment Vectors:**
- **Biological:** 25 (high energy, stronger effect)
- **Social Connection:** 26 (cafe culture, meetings)
- **Psychological:** 30 (strong awakening, productivity boost)
- **Touch/Sensory:** 14 (warmth, rich aroma - same as tea)

**Total Satisfaction Value:** 95

**Comparison to Tea:**
- ✅ Coffee > Tea in Biological (25 vs 18)
- ✅ Coffee > Tea in Social (26 vs 22)
- ✅ Coffee > Tea in Psychological (30 vs 24)
- ✅ Coffee = Tea in Touch/Sensory (14 vs 14)

**Explanation:**
- Higher biological (more caffeine, stronger effect)
- Higher social (modern cafe culture)
- Much higher psychological (productivity, wakefulness)
- Same sensory (both are warm, aromatic beverages)

---

## 8. Implementation Files

### Files to Modify:

1. **`data/base/building_types.json`**
   - Add `tea_farm` building definition
   - Add `coffee_farm` building definition
   - Add `beverage_shop` building definition

2. **`data/base/building_recipes.json`**
   - Add tea farm harvesting recipe
   - Add coffee farm harvesting recipe
   - Add tea brewing recipe (beverage shop)
   - Add coffee brewing recipe (beverage shop)
   - Add tea brewing recipe (restaurant)
   - Add coffee brewing recipe (restaurant)

3. **`data/alpha/craving_system/commodity_cache.json`**
   - Add 6 new commodities with fulfillment vectors

4. **Character/Vocation System** (exact file TBD)
   - Add `barista` vocation
   - Define compatible workplaces
   - Set efficiency multipliers

5. **Inventory/Seed System** (exact file TBD)
   - Ensure `tea_seed` and `coffee_seed` appear in seed inventory
   - Follow existing seed treatment

---

## 9. Real-World Based Values

### Tea Production
- **Real-world:** Tea bushes ready in 3 years, harvest every 7-14 days
- **Game:** 90 second harvest cycles (fast for gameplay)
- **Output:** 24 leaves per cycle (sustainable for 10 cups per batch)

### Coffee Production
- **Real-world:** Coffee trees ready in 3-4 years, harvest annually
- **Game:** 270 seconds (3x slower than tea, as specified)
- **Output:** 20 beans per cycle (premium product, lower yield)

### Tea Brewing
- **Real-world:** 3-5 minutes steeping time
- **Game:** 60 seconds (batch production for 10 cups)
- **Ratio:** 4 tea leaves : 8 water : 2 sugar : 2 milk : 0.5 spices → 10 cups

### Coffee Brewing
- **Real-world:** 2-4 minutes (espresso/filter)
- **Game:** 75 seconds (slightly longer, more involved)
- **Ratio:** 5 coffee beans : 8 water : 2 sugar : 2 milk → 10 cups

### Satisfaction Logic
- **Tea:** Calming, social, moderate energy (78 total)
- **Coffee:** Energizing, productivity, stronger caffeine (95 total)
- Reflects real-world cultural and chemical differences

---

## 10. Production Chain Example

### Scenario: Making 100 Cups of Tea

**Step 1:** Harvest Tea Leaves
- Tea Farm (Level 0, 2 stations)
- Input: 8 water units
- Time: 90 seconds × 4 batches = 6 minutes
- Output: 96 tea leaves

**Step 2:** Brew Tea
- Beverage Shop (Level 0, 1 station)
- Input: 40 tea leaves, 80 water, 20 sugar, 10 fuel, 20 milk, 5 spices
- Time: 60 seconds × 10 batches = 10 minutes
- Output: 100 tea drinks

**Total Time:** ~16 minutes
**Total Resources:** 8 water (farm) + 80 water (brew) + 20 sugar + 10 fuel + 20 milk + 5 spices

### Scenario: Making 100 Cups of Coffee

**Step 1:** Harvest Coffee Beans
- Coffee Farm (Level 0, 2 stations)
- Input: 15 water units
- Time: 270 seconds × 5 batches = 22.5 minutes
- Output: 100 coffee beans

**Step 2:** Brew Coffee
- Beverage Shop (Level 0, 1 station)
- Input: 50 coffee beans, 80 water, 20 sugar, 10 fuel, 20 milk
- Time: 75 seconds × 10 batches = 12.5 minutes
- Output: 100 coffee drinks

**Total Time:** ~35 minutes (slower due to 3x farm time)
**Total Resources:** 15 water (farm) + 80 water (brew) + 20 sugar + 10 fuel + 20 milk

---

## 11. Balance Considerations

### Economic Balance
- **Tea:** Faster production, lower satisfaction → Good early-game beverage
- **Coffee:** Slower production, higher satisfaction → Premium product

### Resource Usage
- Both require: water, sugar, fuel, milk
- Tea additionally needs: spices (adds cost/complexity)
- Coffee needs: more beans per batch (5 vs 4)

### Worker Requirements
- Farms: Use existing Farmer vocation (no new training needed)
- Beverage Shop: Requires new Barista vocation (specialization)
- Restaurant: Can make both but less efficiently (0.7x)

### Building Costs
- Beverage Shop costs are intentionally omitted (cost system not active)
- Construction materials follow bakery pattern
- Upgrade materials scale proportionally

---

## 12. Open Questions / Future Considerations

### Phase 2 (Future):
1. **Shelf Life System:** When implemented, set:
   - tea_leaves: 3 game days
   - coffee_leaves: 5 game days (drier, lasts longer)
   - tea_drink: 0.5 game days (best fresh)
   - coffee_drink: 0.5 game days (best fresh)

2. **Regional Association:**
   - Tea → Kolkata (Darjeeling tea region)
   - Coffee → Bangalore (coffee capital of India)
   - Implement when commodity-city association is finalized

3. **Quality Tiers (Future Dynamic System):**
   - Currently: static "basic" tier
   - Future: poor/basic/good/luxury based on worker skill
   - Premium coffee (luxury tier) could satisfy even more

4. **Additional Beverages:**
   - Beverage Shop could expand to: chai, filter coffee, cold coffee, etc.
   - Recipe variants: with/without milk, with/without sugar

5. **Seed Merchant:**
   - When economy system expands, add tea/coffee seed merchant
   - Currently: seeds appear in inventory like other seeds

---

## 13. Validation Checklist

Before implementation, verify:

- [ ] All commodity IDs are unique (no conflicts with existing commodities)
- [ ] Building IDs are unique (tea_farm, coffee_farm, beverage_shop)
- [ ] Recipe production times are balanced against existing recipes
- [ ] Worker efficiencies match existing patterns
- [ ] Fulfillment vectors are within 0-100 range
- [ ] Construction materials reference existing commodities
- [ ] Input/output ratios create sustainable production loops
- [ ] Tea production is 3x faster than coffee (verified)
- [ ] Coffee satisfaction > tea satisfaction (except touch)
- [ ] Barista vocation definition is complete

---

## 14. Summary

### New Commodities: 6
- tea_seed, coffee_seed
- tea_leaves, coffee_leaves
- tea_drink, coffee_drink

### New Buildings: 3
- tea_farm
- coffee_farm
- beverage_shop

### Updated Buildings: 1
- restaurant (add 2 new recipes)

### New Worker Types: 1
- barista

### New Recipes: 6
- Tea farm harvesting
- Coffee farm harvesting
- Tea brewing (beverage shop)
- Coffee brewing (beverage shop)
- Tea brewing (restaurant)
- Coffee brewing (restaurant)

---

**END OF DESIGN SPECIFICATION**

**Next Steps:**
1. Review this document for accuracy
2. Answer any clarifying questions
3. Approve design
4. Implement changes to files
5. Test production chains
6. Balance tuning

---

**Document Status:** ✅ IMPLEMENTED

---

## Implementation Summary

All components have been successfully implemented:

### Files Modified:
1. ✅ **`data/base/building_types.json`** - Added 3 new buildings
   - tea_farm (lines 1097-1192)
   - coffee_farm (lines 1193-1288)
   - beverage_shop (lines 1289-1358)

2. ✅ **`data/base/building_recipes.json`** - Added 6 new recipes
   - tea_farm: Tea Leaf Harvesting (lines 362-375)
   - coffee_farm: Coffee Bean Harvesting (lines 376-389)
   - beverage_shop: Tea Brewing (lines 390-408)
   - beverage_shop: Coffee Brewing (lines 409-426)
   - restaurant: Restaurant Tea Service (lines 427-445)
   - restaurant: Restaurant Coffee Service (lines 446-463)

3. ✅ **`data/alpha/craving_system/fulfillment_vectors.json`** - Added 6 new commodities
   - tea_seed (lines 10788-10815)
   - coffee_seed (lines 10816-10843)
   - tea_leaves (lines 10844-10876)
   - coffee_leaves (lines 10877-10910)
   - tea_drink (lines 10911-10950)
   - coffee_drink (lines 10951-10990)

4. ✅ **`data/base/worker_types.json`** - Added barista worker type
   - barista (lines 50-61)

### Key Implementation Details:
- **Tea production is 3x faster than coffee** (90s vs 270s farm cycle) ✓
- **Coffee has higher satisfaction than tea** in biological (25 vs 18), social (26 vs 22), psychological (30 vs 24) ✓
- **Both have equal touch/sensory satisfaction** (14 vs 14) ✓
- **Barista worker type** created with "Beverage Preparation" and "Hospitality" work categories ✓
- **All 6 commodities** properly defined with fulfillment vectors and quality multipliers ✓
- **Both farms** have placement constraints for fertility and ground water ✓
- **Beverage shop** follows bakery pattern (1/2/4 stations across levels) ✓
- **Restaurant** can now produce tea and coffee alongside meals ✓

### Validation Checklist:
- ✅ All commodity IDs are unique (tea_seed, coffee_seed, tea_leaves, coffee_leaves, tea_drink, coffee_drink)
- ✅ Building IDs are unique (tea_farm, coffee_farm, beverage_shop)
- ✅ Recipe production times are balanced (90s tea, 270s coffee farm; 60s tea, 75s coffee brew)
- ✅ Worker efficiencies match existing patterns (Agriculture: 1, Beverage Preparation: 1)
- ✅ Fulfillment vectors follow correct structure (9-element coarse arrays)
- ✅ Construction materials reference existing commodities
- ✅ Input/output ratios create sustainable production loops
- ✅ Tea production is 3x faster than coffee (verified: 90s vs 270s)
- ✅ Coffee satisfaction > tea satisfaction except touch (verified: 25>18, 26>22, 30>24, 14=14)
- ✅ Barista vocation definition is complete

**Implementation Date:** December 20, 2024
**Implemented By:** Claude Code
