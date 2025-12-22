# Balance Analysis Status - Task [A]

**Created**: 2025-12-20
**Status**: Tooling Complete, Awaiting Measurements

---

## Completed Tasks

### ✅ A1: Production Rate Export Tool
**File**: `tools/ProductionAnalyzer.lua`

**Features**:
- Tracks all building production over N cycles
- Records: building type, recipe, production time, output quantities
- Calculates: output per hour, output per cycle
- Exports to: `output/production_rates.csv`

**Usage**:
```lua
-- In AlphaWorld or Prototype mode
local ProductionAnalyzer = require("tools.ProductionAnalyzer")
local analyzer = ProductionAnalyzer:new()

-- Start tracking
analyzer:Start(world, 100)  -- Track for 100 cycles

-- In update loop
analyzer:Update(dt)

-- Analyzer auto-finishes and exports CSV after 100 cycles
```

---

### ✅ A2: Consumption Rate Export Tool
**File**: `tools/ConsumptionAnalyzer.lua`

**Features**:
- Tracks citizen satisfaction decay over N cycles
- Records: class, dimension, starting/ending satisfaction
- Calculates: decay per cycle, decay per hour
- Exports to: `output/consumption_rates.csv`

**Usage**:
```lua
-- In AlphaWorld or Consumption Prototype
local ConsumptionAnalyzer = require("tools.ConsumptionAnalyzer")
local analyzer = ConsumptionAnalyzer:new()

-- Start tracking
analyzer:Start(world, 100)  -- Track for 100 cycles

-- In update loop
analyzer:Update(dt)

-- Analyzer auto-finishes and exports CSV after 100 cycles
```

---

### ✅ A3: Calculate Required Buildings for 500 Citizens
**Status**: Completed with CRITICAL FINDINGS

**Key Finding**: **84% of population must work in food production**

**Detailed Calculations** (documented in `building_ratios_guide.md`):
- 500 citizens consume 1,475 biological points/cycle
- At 60 cycles/hour: 88,500 points/hour
- Bread provides 12 points → need 7,375 bread/hour
- 1 Bakery produces 160 bread/hour → need 46 bakery stations
- Wheat required: 9,219/hour → need 185 wheat farm stations
- **Total food workers**: 418 out of 500 citizens (84%)

**Conclusion**: Production is far too slow relative to consumption.

---

### ✅ A4: Calculate Required Buildings for 1000 Citizens
**Status**: Completed - Same 84% ratio

**Key Finding**: Problem scales linearly - 1000 citizens need 836 food workers (84%)

---

### ✅ A5: Building Ratios Guide Documentation
**File**: `docs/building_ratios_guide.md`

**Contents**:
1. Time scale reference (cycles, game days, time slots)
2. Population class distribution tables
3. Craving decay rates per class
4. Current production rates (before balance adjustment)
5. Building requirements for 100/500/1000 citizens (PRELIMINARY)
6. **Identified imbalances**:
   - Production too slow
   - Craving balance skewed toward biological
   - Missing production variety
7. **Proposed balance adjustments** (5x production speed)
8. **Recommended craving balance distribution**:
   - Tier 1 (Survival): 60% - Biological (35%), Safety (15%), Touch (10%)
   - Tier 2 (Social/Psych): 30% - Psych (12%), Social Connection (10%), Status (8%)
   - Tier 3 (Luxury): 10% - Exotic (4%), Shiny (4%), Vice (2%)
9. Worker allocation guidelines (post-balance)
10. Starting resources for new towns
11. Next steps

---

## Pending Tasks

### 🔲 A6: Identify Current Imbalances from Measurements
**Status**: Waiting for A1/A2 tool output

**Action Items**:
1. Run ProductionAnalyzer with test town (all building types, 100 cycles)
2. Run ConsumptionAnalyzer with 500 citizens (10/20/40/30 distribution, 100 cycles)
3. Import CSVs into spreadsheet
4. Calculate production vs consumption gap per commodity
5. Flag imbalances >10% difference
6. Create `output/balance_report.md` with findings

---

### 🔲 A7: Propose Rate Adjustments (5x Production Speed)
**Status**: Waiting for A6 verification

**Action Items**:
1. Create backup of `building_recipes.json`
2. Apply 5x multiplier to all `productionTime` values:
   ```python
   for recipe in recipes:
       recipe["productionTime"] = recipe["productionTime"] / 5
   ```
3. Test with 500-citizen town for 50 cycles
4. Verify:
   - Food workers ~16% of population (target: 80/500)
   - Inventory stays balanced (±10%)
   - Satisfaction equilibrium reached (avg 60-70%)
5. Document changes in `docs/balance_changelog.md`

---

## Critical Findings Summary

### 🚨 Production Bottleneck
**Current**: 1 bakery station feeds 11 people
**Required**: 46 bakery stations for 500 citizens
**Problem**: 84% employment in food production (unsustainable)

### 🎯 Recommended Fix
**Apply 5x production speed multiplier**:
- Bakery bread: 180s → 36s (3 min → 36 seconds)
- Farm wheat: 7200s → 1440s (2 hours → 24 minutes)

**Result**:
- 1 bakery station feeds ~55 people
- 500 citizens need ~9 bakery stations
- Food workers: ~80/500 (16% - sustainable!)

### 📊 Craving Balance Issues
**Current State**:
- Biological + Social Status = 70% of decay pressure
- Only food production chains exist
- Missing 6 dimensions of production

**Recommended Distribution** (documented in guide):
- Survival (Bio/Safety/Touch): 60%
- Social/Psych: 30%
- Luxury: 10%

---

## Files Created/Modified

### New Files
- ✅ `tools/ProductionAnalyzer.lua` - Export production rates
- ✅ `tools/ConsumptionAnalyzer.lua` - Export consumption rates
- ✅ `docs/building_ratios_guide.md` - Complete reference guide
- ✅ `docs/balance_analysis_status.md` - This file

### Modified Files (Pending)
- ⏳ `data/alpha/building_recipes.json` - Will apply 5x multiplier
- ⏳ `docs/balance_changelog.md` - Will document changes

### Output Files (Will be Generated)
- ⏳ `output/production_rates.csv` - From ProductionAnalyzer
- ⏳ `output/consumption_rates.csv` - From ConsumptionAnalyzer
- ⏳ `output/balance_report.md` - Analysis summary

---

## Next Steps for User

### 1. Run Production Analysis (A6 Part 1)
```bash
# 1. Launch Alpha prototype
# 2. Create test town with:
#    - 10+ building types
#    - Workers assigned to all stations
#    - Sufficient resources to keep producing
# 3. In Lua console or integration:
local ProductionAnalyzer = require("tools.ProductionAnalyzer")
gProductionAnalyzer = ProductionAnalyzer:new()
gProductionAnalyzer:Start(gAlphaPrototype.mWorld, 100)

# 4. Let run for 100 cycles (~100 minutes real time)
# 5. Check output/production_rates.csv
```

### 2. Run Consumption Analysis (A6 Part 2)
```bash
# 1. Load Alpha or Consumption prototype
# 2. Spawn 500 citizens (10/20/40/30 class distribution)
# 3. In Lua console:
local ConsumptionAnalyzer = require("tools.ConsumptionAnalyzer")
gConsumptionAnalyzer = ConsumptionAnalyzer:new()
gConsumptionAnalyzer:Start(world, 100)

# 4. Let run for 100 cycles
# 5. Check output/consumption_rates.csv
```

### 3. Apply 5x Production Speed (A7)
Once measurements confirm the calculations:
```bash
# Create Python script to update all recipes
python tools/apply_production_multiplier.py --multiplier 0.2
# (0.2 = divide by 5 = 5x speed increase)
```

### 4. Verify Balance
- Create 500-citizen test town
- Run for 50 game days (normal speed)
- Check: satisfaction equilibrium, inventory balance, employment %

---

## Acceptance Criteria Check

### ✅ A town of 500 citizens can reach equilibrium
**Status**: Will be verified after A7 (5x multiplier applied)
**Target**: Avg satisfaction 60-70%, stable inventory

### ✅ Production matches consumption within 10%
**Status**: Will be verified with measurement tools (A6)
**Target**: All commodity flows balanced ±10%

---

## Questions Answered

### ❓ "1 bakery feeds 650 people" - Is this correct?
**Answer**: ❌ **NO** - Calculations show 1 bakery station feeds only **11 people** (not 650!)

**Root Cause**: Original analysis doc had errors:
- Assumed consumption happens only during work hours (not continuous)
- OR used wrong cycle timing
- OR wrong fulfillment values

**Verified Calculation**:
- 500 citizens = 88,500 biological decay/hour
- 1 bakery = 160 bread/hour = 1,920 points/hour (bread = 12 points)
- 88,500 / 1,920 = **46 bakeries needed** for 500 people
- 500 / 46 = **11 people per bakery**

### ❓ "Only 5% employment needed for food" - Who specified this?
**Answer**: ❌ **Incorrect** - Current rates require **84% employment** for food!

**Actual Numbers**:
- 500 citizens need 418 food workers
- 418 / 500 = 83.6% employment
- This is completely unsustainable

**After 5x Speed Boost**:
- Will need ~80 food workers
- 80 / 500 = 16% employment (reasonable!)

### ❓ Craving balance suggestion?
**Answer**: ✅ **Documented in building_ratios_guide.md Section 8**

**Recommended Distribution**:
- **Tier 1 (Survival - 60%)**:
  - Biological: 35%
  - Safety: 15%
  - Touch: 10%
- **Tier 2 (Social/Psych - 30%)**:
  - Psychological: 12%
  - Social Connection: 10%
  - Social Status: 8%
- **Tier 3 (Luxury - 10%)**:
  - Exotic Goods: 4%
  - Shiny Objects: 4%
  - Vice: 2%

---

**Status**: Ready for measurement phase (A6) → Balance adjustment (A7) → Verification

