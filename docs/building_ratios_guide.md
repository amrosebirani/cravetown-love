# Building Ratios Guide
**Version:** 1.0 (Pre-Balance Adjustment)
**Status:** DRAFT - Awaiting measurement data from analysis tools
**Last Updated:** 2025-12-20

---

## Purpose

This guide provides recommended building counts and worker allocations for sustaining towns of different sizes. These ratios ensure production matches consumption to maintain citizen satisfaction equilibrium.

**⚠️ IMPORTANT**: Current calculations show severe production bottlenecks. Awaiting real measurement data before finalizing recommendations.

---

## 1. Time Scale Reference

### Real Time vs Game Time
- **1 Cycle** = 60 real seconds (consumption tick)
- **1 Game Day** (Normal Speed) = 300 real seconds = 5 cycles
- **1 Game Day** (Fast Speed) = 150 real seconds = 2.5 cycles
- **1 Game Day** (Faster Speed) = 60 real seconds = 1 cycle

### Time Slot System
- **1 Game Day** = 6 time slots
  - Dawn (4-6 AM)
  - Morning (6-12 PM)
  - Afternoon (12-6 PM)
  - Evening (6-9 PM)
  - Night (9 PM-12 AM)
  - Late Night (12-4 AM)

- **Working Hours**: Citizens work during 4 active slots (Morning, Afternoon, Evening, Night)

---

## 2. Population Class Distribution

Based on `consumption_mechanics.json`:

| Class  | Percentage | @ 100 | @ 500 | @ 1000 |
|--------|-----------|-------|-------|--------|
| Elite  | 10%       | 10    | 50    | 100    |
| Upper  | 20%       | 20    | 100   | 200    |
| Middle | 40%       | 40    | 200   | 400    |
| Lower  | 30%       | 30    | 150   | 300    |

---

## 3. Craving Decay Rates (Current Values)

### Biological Craving (Food/Water - Highest Priority)
| Class  | Decay/Cycle | Decay/Hour | Decay/Day (Normal) |
|--------|-------------|------------|--------------------|
| Elite  | 2.0         | 120        | 600                |
| Upper  | 2.5         | 150        | 750                |
| Middle | 3.0         | 180        | 900                |
| Lower  | 3.5         | 210        | 1,050              |

### Touch Craving (Clothing/Comfort)
| Class  | Decay/Cycle | Decay/Hour | Decay/Day (Normal) |
|--------|-------------|------------|--------------------|
| Elite  | 1.5         | 90         | 450                |
| Upper  | 2.0         | 120        | 600                |
| Middle | 2.5         | 150        | 750                |
| Lower  | 3.0         | 180        | 900                |

### Psychological Craving (Entertainment/Education)
| Class  | Decay/Cycle | Decay/Hour | Decay/Day (Normal) |
|--------|-------------|------------|--------------------|
| Elite  | 3.0         | 180        | 900                |
| Upper  | 2.5         | 150        | 750                |
| Middle | 2.0         | 120        | 600                |
| Lower  | 1.5         | 90         | 450                |

### Social Status Craving (Luxury/Prestige)
| Class  | Decay/Cycle | Decay/Hour | Decay/Day (Normal) |
|--------|-------------|------------|--------------------|
| Elite  | 5.0         | 300        | 1,500              |
| Upper  | 3.0         | 180        | 900                |
| Middle | 2.0         | 120        | 600                |
| Lower  | 1.0         | 60         | 300                |

**Note**: See `consumption_mechanics.json` for complete decay rates across all 9 dimensions.

---

## 4. Production Rates (Current - BEFORE 5x Adjustment)

### Food Production Chain

#### Wheat Farm
- **Production Time**: 7200 seconds (2 hours real time)
- **Output**: 100 wheat
- **Rate**: 50 wheat/hour per station
- **Workers**: 2 per station (Level 0)

#### Bakery (Bread Recipe)
- **Production Time**: 180 seconds (3 minutes real time)
- **Input**: 10 wheat per batch
- **Output**: 8 bread
- **Rate**: 160 bread/hour per station
- **Workers**: 1 per station (Level 0)

#### Restaurant (Meal Recipe)
- **Production Time**: 300 seconds (5 minutes real time)
- **Inputs**: Various ingredients
- **Output**: 10 meals
- **Rate**: 120 meals/hour per station
- **Workers**: 2 per station (Level 0)

### Fulfillment Values (Biological Dimension)
| Commodity | Biological Points | Other Benefits |
|-----------|------------------|----------------|
| Bread     | 12               | grain: 15, protein: 2 |
| Meat      | 15               | protein: 20, grain: 2 |
| Vegetable | 10               | produce: 15, hydration: 3 |
| Meal      | 18               | Multiple dimensions |

---

## 5. Building Requirements (PRELIMINARY - NEEDS VERIFICATION)

### For 100 Citizens (10/20/40/30 Distribution)

#### Biological Decay Calculation
- Elite (10): 10 × 2.0 = 20/cycle
- Upper (20): 20 × 2.5 = 50/cycle
- Middle (40): 40 × 3.0 = 120/cycle
- Lower (30): 30 × 3.5 = 105/cycle
- **Total**: 295 biological points/cycle

**Per Hour**: 295 × 60 = 17,700 points/hour

#### Bread-Based Economy
**Consumption Needed**:
- 17,700 points ÷ 12 (bread fulfillment) = **1,475 bread/hour**

**Production Available** (Current Rates):
- 1 Bakery station = 160 bread/hour
- **Stations Needed**: 1,475 ÷ 160 = **9.2 bakery stations**

**Wheat Supply**:
- 1,475 bread needs 1,844 wheat/hour (1.25 wheat per bread)
- 1 Wheat Farm station = 50 wheat/hour
- **Farms Needed**: 1,844 ÷ 50 = **37 wheat farm stations**

#### Preliminary Building List for 100 Citizens
| Building Type | Quantity (Level 0) | Stations | Workers | Purpose |
|--------------|-------------------|----------|---------|---------|
| Wheat Farm   | 19                | 38       | 76      | Wheat production |
| Bakery       | 10                | 10       | 10      | Bread production |
| **TOTAL FOOD WORKERS** | **29 buildings** | **48 stations** | **86** | **86% of population!** |

**⚠️ CRITICAL ISSUE**: This shows 86% of the population must work in food production - **completely unsustainable**!

---

### For 500 Citizens (50/100/200/150 Distribution)

#### Biological Decay Calculation
- Elite (50): 50 × 2.0 = 100/cycle
- Upper (100): 100 × 2.5 = 250/cycle
- Middle (200): 200 × 3.0 = 600/cycle
- Lower (150): 150 × 3.5 = 525/cycle
- **Total**: 1,475 biological points/cycle

**Per Hour**: 1,475 × 60 = 88,500 points/hour

#### Bread-Based Economy
**Consumption Needed**:
- 88,500 points ÷ 12 = **7,375 bread/hour**

**Production Available** (Current Rates):
- 1 Bakery station = 160 bread/hour
- **Stations Needed**: 7,375 ÷ 160 = **46 bakery stations**

**Wheat Supply**:
- 7,375 bread needs 9,219 wheat/hour
- 1 Wheat Farm station = 50 wheat/hour
- **Farms Needed**: 9,219 ÷ 50 = **185 wheat farm stations**

#### Preliminary Building List for 500 Citizens
| Building Type | Quantity (Level 0) | Stations | Workers | Purpose |
|--------------|-------------------|----------|---------|---------|
| Wheat Farm   | 93                | 186      | 372     | Wheat production |
| Bakery       | 46                | 46       | 46      | Bread production |
| **TOTAL FOOD WORKERS** | **139 buildings** | **232 stations** | **418** | **84% of population!** |

**⚠️ CRITICAL ISSUE**: Same unsustainable ratio - confirms production is too slow OR consumption too high.

---

### For 1000 Citizens (100/200/400/300 Distribution)

#### Biological Decay Calculation
- **Total**: 2,950 biological points/cycle
- **Per Hour**: 177,000 points/hour

#### Bread-Based Economy
- **Bread Needed**: 14,750 bread/hour
- **Bakery Stations**: 92
- **Wheat Farm Stations**: 370
- **Food Workers**: ~836 (**84% of population**)

---

## 6. Identified Imbalances & Issues

### Issue 1: Production Too Slow
**Current State**:
- 1 Bakery station feeds only ~11 people (not 650 as previously thought)
- 84% of population must work in food production
- Leaves only 16% for other industries

**Root Cause**:
- Production times too long relative to consumption rates
- OR fulfillment values too low
- OR decay rates too high

### Issue 2: Craving Balance Skewed Toward Biological

**Current Decay Totals (500 citizens/cycle)**:
| Dimension         | Total Decay/Cycle | % of Total |
|-------------------|------------------|------------|
| Biological        | 1,475            | 34%        |
| Social Status     | 1,550            | 36%        |
| Touch             | 1,075            | 25%        |
| Psychological     | 1,100            | 26%        |
| (Other dims...)   | TBD              | TBD        |

**Observations**:
- Biological + Social Status = 70% of decay pressure
- Missing production chains for 6 other dimensions
- Players will only focus on food/housing, ignoring variety

### Issue 3: Missing Production Variety
**Currently Available**:
- Biological: Wheat, Bread, some vegetables
- Touch: (Missing clothing, furniture)
- Psychological: (Missing books, art, entertainment)
- Social Status: (Missing luxury goods)

---

## 7. Proposed Balance Adjustments

### Option A: Increase Production Speed (5x Multiplier)
**Change**: Reduce all `productionTime` values by 5x in `building_recipes.json`

**Example**:
```json
{
  "bakery_bread": {
    "productionTime": 180 → 36  // 3 min → 36 seconds
  },
  "farm_wheat": {
    "productionTime": 7200 → 1440  // 2 hours → 24 minutes
  }
}
```

**Result**:
- 1 Bakery station = 800 bread/hour (instead of 160)
- 500 citizens need ~9 bakery stations (instead of 46)
- Food workers = ~16% of population (sustainable!)

**Recommended**: ✅ This is the preferred approach (User specified Option A with 5x multiplier)

### Option B: Decrease Consumption (NOT RECOMMENDED)
User specified to keep consumption rates as-is.

### Option C: Increase Fulfillment Values
Alternative: Make bread provide 60 points instead of 12 (5x multiplier).
- Same net effect as Option A
- Easier to balance with variety
- Consider for future tuning

---

## 8. Recommended Craving Balance Distribution

To create meaningful gameplay variety, aim for this **target decay distribution**:

### Tier 1: Survival Needs (60% of total decay pressure)
- **Biological**: 35% - Food/water (always highest priority)
- **Safety**: 15% - Security/medicine/shelter
- **Touch**: 10% - Basic clothing/furniture

### Tier 2: Social & Psychological (30% of total decay pressure)
- **Psychological**: 12% - Entertainment/education/art
- **Social Connection**: 10% - Community activities
- **Social Status**: 8% - Prestige/luxury for higher classes

### Tier 3: Luxury & Indulgence (10% of total decay pressure)
- **Exotic Goods**: 4% - Imported/rare items
- **Shiny Objects**: 4% - Wealth/decorations
- **Vice**: 2% - Alcohol/indulgences

### Implementation Approach
To achieve this balance while keeping `consumption_mechanics.json` unchanged:

1. **Add More Production Chains**:
   - Clothing: Cotton Farm → Spinner → Weaver → Tailor
   - Furniture: Lumber → Carpenter → Furniture
   - Books: Paper Mill → Printer → Bookshop
   - Luxury: Goldsmith, Jeweler, Art Studio

2. **Adjust Fulfillment Vectors**:
   - Ensure each commodity fulfills 2-3 dimensions (not just biological)
   - Example: Meal = biological + social_connection + psychological (fine dining)

3. **Add Quality Tiers**:
   - Poor quality = biological only
   - Good quality = biological + touch
   - Luxury quality = biological + touch + social_status

---

## 9. Worker Allocation Guidelines

### Post-Balance (After 5x Production Speed Increase)

#### For 500 Citizens (Balanced Economy)
| Sector | Workers | % of Pop | Buildings |
|--------|---------|----------|-----------|
| Food Production | 80 | 16% | 10 farms, 9 bakeries, 2 restaurants |
| Clothing/Textiles | 30 | 6% | 5 cotton farms, 3 weavers, 2 tailors |
| Housing/Furniture | 20 | 4% | 3 sawmills, 2 carpenters |
| Luxury/Culture | 20 | 4% | 1 goldsmith, 1 artist, 1 bookshop |
| Services | 30 | 6% | 2 bars, 1 school, 1 temple |
| Idle/Unemployed | 20 | 4% | Available for expansion |
| Non-Working (Children, Retired) | 300 | 60% | - |

**Target**: ~30% employment rate (typical for medieval/agricultural societies)

---

## 10. Starting Resources for New Towns

### Small Town (100 Citizens)
| Resource | Quantity | Days Supply |
|----------|----------|-------------|
| Gold | 1,000 | - |
| Wheat | 500 | 7 days |
| Bread | 300 | 5 days |
| Vegetables | 200 | 5 days |
| Wood | 200 | Construction |
| Stone | 100 | Construction |
| Simple Clothes | 50 | 1 per 2 citizens |

### Medium Town (500 Citizens)
| Resource | Quantity | Days Supply |
|----------|----------|-------------|
| Gold | 5,000 | - |
| Wheat | 2,500 | 7 days |
| Bread | 1,500 | 5 days |
| Vegetables | 1,000 | 5 days |
| Meat | 300 | 3 days |
| Wood | 1,000 | Construction |
| Stone | 500 | Construction |
| Simple Clothes | 250 | 1 per 2 citizens |
| Fine Clothes | 50 | Elite/Upper |

### Large Town (1000 Citizens)
| Resource | Quantity | Days Supply |
|----------|----------|-------------|
| Gold | 10,000 | - |
| Wheat | 5,000 | 7 days |
| Bread | 3,000 | 5 days |
| Vegetables | 2,000 | 5 days |
| Meat | 600 | 3 days |
| Wood | 2,000 | Construction |
| Stone | 1,000 | Construction |
| Iron Ore | 200 | Tools |
| Simple Clothes | 500 | 1 per 2 citizens |
| Fine Clothes | 100 | Elite/Upper |

---

## 11. Next Steps

1. **✅ DONE**: Created `ProductionAnalyzer.lua` and `ConsumptionAnalyzer.lua`
2. **IN PROGRESS**: Run analysis tools with test town (100-500 citizens, 100 cycles)
3. **PENDING**: Verify calculations against actual measurement data
4. **PENDING**: Apply 5x production speed multiplier to all recipes
5. **PENDING**: Test balanced economy with 500-citizen town
6. **PENDING**: Add missing production chains for non-biological dimensions
7. **PENDING**: Update this guide with verified ratios

---

## 12. How to Use This Guide

### For Game Designers
- Use the **Building Requirements** tables as a baseline for tuning
- Adjust `productionTime` in `building_recipes.json` to match target worker %
- Use **Craving Balance** targets to guide new recipe/building design

### For Players
- Once balanced, use **Worker Allocation** tables for town planning
- Aim for ~30% employment rate for sustainable growth
- Diversify production to cover all craving dimensions

### For Developers
- Run `ProductionAnalyzer.lua` and `ConsumptionAnalyzer.lua` after any balance changes
- Compare output CSVs against this guide's target ratios
- Update fulfillment vectors to match desired craving distribution

---

**Status**: ⚠️ DRAFT - Awaiting measurement data validation
**Next Review**: After A1/A2 analysis tools complete and 5x production adjustment applied

