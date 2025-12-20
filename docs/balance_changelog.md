# Balance Changelog

Track all balance adjustments to production rates, consumption rates, and economic parameters.

---

## Format
```
## YYYY-MM-DD HH:MM:SS
**Change**: Description of what was changed
**File**: File path
**Reason**: Why this change was made
**Impact**: Expected gameplay impact
**Test Results**: Link to test data or notes
```

---

## 2025-12-20 (Initial Analysis)
**Change**: Created balance analysis tooling and documentation
**Files**:
- `tools/ProductionAnalyzer.lua`
- `tools/ConsumptionAnalyzer.lua`
- `docs/building_ratios_guide.md`
- `docs/balance_analysis_status.md`

**Findings**:
- Current production rates require 84% of population to work in food production
- 1 bakery station feeds only 11 people (not 650 as initially thought)
- Craving balance heavily skewed toward biological (35%) and social status (36%)

**Proposed Fix**:
- Apply 5x production speed multiplier to all recipes
- Target: 16% employment in food production
- Add production chains for 6 missing craving dimensions

**Status**: Awaiting measurement data from analysis tools

---

## Pending Changes

### [Scheduled] 5x Production Speed Increase
**When**: After A6 (measurement verification) completes
**File**: `data/alpha/building_recipes.json`
**Method**: Run `python tools/apply_production_multiplier.py --multiplier 0.2`
**Expected Impact**:
- Bakery bread: 180s → 36s
- Farm wheat: 7200s → 1440s
- Food workers: 84% → 16% of population

**Acceptance Criteria**:
- [ ] 500-citizen town reaches equilibrium
- [ ] Production matches consumption ±10%
- [ ] Average satisfaction 60-70%
- [ ] Employment rate 25-35%

---

<!-- Automated entries from apply_production_multiplier.py will be appended here -->
