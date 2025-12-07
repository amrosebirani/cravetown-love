# Info System TODO List - Alpha Release

**Purpose:** Enable parallel data entry while game prototype is being built
**Priority:** HIGH - Must complete first to unblock data work
**Target:** Before game prototype work begins

---

## Overview

This document lists all Info System UI changes needed to support the new slot-based temporal craving system, units system, and other alpha features.

---

## Phase 1: Core Schema Updates (CRITICAL - Do First)

### Task 1.1: Add Time Slots Definition
**File:** `data/base/time_slots.json` (NEW)
**Info System:** Add new "Time Slots" tab

```json
{
  "slots": [
    {
      "id": "early_morning",
      "name": "Early Morning",
      "startHour": 5,
      "endHour": 8,
      "description": "Wake up, breakfast preparation"
    },
    {
      "id": "morning",
      "name": "Morning",
      "startHour": 8,
      "endHour": 12,
      "description": "Work, morning activities"
    },
    {
      "id": "afternoon",
      "name": "Afternoon",
      "startHour": 12,
      "endHour": 17,
      "description": "Lunch, afternoon work, social"
    },
    {
      "id": "evening",
      "name": "Evening",
      "startHour": 17,
      "endHour": 21,
      "description": "Dinner, entertainment, family"
    },
    {
      "id": "night",
      "name": "Night",
      "startHour": 21,
      "endHour": 24,
      "description": "Relaxation, preparation for sleep"
    },
    {
      "id": "late_night",
      "name": "Late Night",
      "startHour": 0,
      "endHour": 5,
      "description": "Sleep, rest"
    }
  ]
}
```

**Info System UI:**
- [ ] Create "Time Slots" tab in Info System
- [ ] List view of all slots
- [ ] Edit: id, name, startHour, endHour, description
- [ ] Visual timeline representation showing slot coverage
- [ ] Validation: slots must cover full 24 hours without gaps

---

### Task 1.2: Add Craving-to-Slot Mapping
**File:** `data/base/craving_slots.json` (NEW)
**Info System:** Add "Slot Mapping" section in Cravings tab

```json
{
  "mappings": {
    "biological_nutrition_grain": {
      "slots": ["early_morning", "afternoon", "evening"],
      "frequencyPerDay": 3,
      "description": "Meals throughout the day"
    },
    "biological_nutrition_protein": {
      "slots": ["afternoon", "evening"],
      "frequencyPerDay": 2
    },
    "touch_comfort_rest": {
      "slots": ["late_night"],
      "frequencyPerDay": 1,
      "description": "Sleep need"
    },
    "psychological_entertainment": {
      "slots": ["evening", "night"],
      "frequencyPerDay": 1
    }
  },
  "classModifiers": {
    "Elite": {
      "psychological_entertainment": {
        "additionalSlots": ["afternoon"],
        "description": "Elite have leisure time in afternoon"
      }
    }
  },
  "traitModifiers": {
    "Workaholic": {
      "psychological_entertainment": {
        "removeSlots": ["evening"],
        "description": "Workaholics skip evening entertainment"
      }
    }
  }
}
```

**Info System UI:**
- [ ] In Cravings/Dimensions tab, add "Slot Mapping" section
- [ ] For each fine dimension, show:
  - Multi-select dropdown for slots
  - Frequency per day (how many times this craving activates)
  - Description field
- [ ] Separate tabs/sections for:
  - Base mappings (all characters)
  - Class modifiers (additional/removed slots per class)
  - Trait modifiers (additional/removed slots per trait)
- [ ] Visual: Show which cravings are active in each slot

---

### Task 1.3: Add Units System
**File:** `data/base/units.json` (NEW)
**Info System:** Add "Units" tab

```json
{
  "baseUnits": {
    "weight": {
      "base": "kg",
      "display": ["g", "kg"],
      "conversions": { "g": 0.001 }
    },
    "volume": {
      "base": "liter",
      "display": ["ml", "liter"],
      "conversions": { "ml": 0.001 }
    },
    "count": {
      "base": "piece",
      "display": ["piece"]
    },
    "time": {
      "base": "cycle",
      "display": ["cycle", "day"],
      "conversions": { "day": 1 }
    }
  },
  "personDayBaseline": {
    "calories": 2000,
    "water_liters": 2,
    "sleep_hours": 8,
    "description": "Base daily needs for an average adult"
  },
  "commodityUnits": {
    "wheat": { "unit": "kg", "caloriesPerUnit": 3400 },
    "bread": { "unit": "loaf", "weightKg": 0.5, "caloriesPerUnit": 1200 },
    "meat": { "unit": "kg", "caloriesPerUnit": 2500 },
    "water": { "unit": "liter", "caloriesPerUnit": 0 },
    "wine": { "unit": "bottle", "volumeLiters": 0.75 },
    "bed": { "unit": "piece", "durationType": "permanent" },
    "cloth": { "unit": "meter" }
  }
}
```

**Info System UI:**
- [ ] Create "Units" tab with sections:
  - Base unit types (weight, volume, count, time)
  - Person-day baseline settings
  - Commodity unit assignments
- [ ] In Commodities tab, add unit selection dropdown
- [ ] Show calculated "daily need" based on fulfillment vectors and baseline

---

### Task 1.4: Update Fulfillment Vectors with Units
**File:** `data/base/craving_system/fulfillment_vectors.json`
**Info System:** Update Commodities tab

Add to each commodity:
```json
{
  "bread": {
    "unit": "loaf",
    "unitWeight": 0.5,
    "caloriesPerUnit": 1200,
    "dailyConsumptionBaseline": 0.5,
    "fulfillmentVector": { ... }
  }
}
```

**Info System UI:**
- [ ] Add unit fields to commodity editor
- [ ] Show "Provides X% of daily [dimension] need" calculated field
- [ ] Display in human-readable format: "1 loaf (500g) provides..."

---

## Phase 2: Craving System Updates

### Task 2.1: Fine-Level Satisfaction Tracking
**Current:** Satisfaction tracked at coarse (9D) level only
**New:** Track at fine (49D) level, compute coarse as average

**Info System UI:**
- [ ] In dimension editor, add toggle: "Track satisfaction at fine level"
- [ ] Show coarse dimensions as "computed from fine averages"
- [ ] Update any satisfaction displays to show fine breakdown

---

### Task 2.2: Pre-computed Commodity-Craving Index
**File:** `data/base/commodity_craving_index.json` (GENERATED)
**Info System:** Auto-generate on save

```json
{
  "byCraving": {
    "biological_nutrition_grain": [
      { "commodityId": "bread", "effectiveness": 15, "rank": 1 },
      { "commodityId": "wheat", "effectiveness": 12, "rank": 2 },
      { "commodityId": "cake", "effectiveness": 8, "rank": 3 }
    ]
  },
  "byCommodity": {
    "bread": [
      { "cravingId": "biological_nutrition_grain", "points": 15 },
      { "cravingId": "biological_nutrition_protein", "points": 2 },
      { "cravingId": "touch_sensory_luxury", "points": 3 }
    ]
  }
}
```

**Info System UI:**
- [ ] Add "Regenerate Index" button in Commodities tab
- [ ] Auto-regenerate when any commodity fulfillment vector changes
- [ ] Show index preview: "This commodity best satisfies: [list]"
- [ ] Show reverse: "This craving is best satisfied by: [list]"

---

### Task 2.3: Update Fatigue/Freshness System for Slots
**File:** Update `consumption_mechanics.json`

Change from cycle-based to slot-based:
```json
{
  "fatigue": {
    "trackingLevel": "slot",
    "freshnessCooldownSlots": 6,
    "decayRatePerSlot": 0.15,
    "description": "Freshness tracked per slot, not per cycle"
  }
}
```

**Info System UI:**
- [ ] Update fatigue settings to use "slots" instead of "cycles"
- [ ] Add explanation text about slot-based tracking

---

## Phase 3: Building & Production Updates

### Task 3.1: Verify Building Types Schema
**File:** `data/base/building_types.json`

Ensure all fields shown in UI spec are present:
- [ ] id, name, category
- [ ] cost (gold)
- [ ] size (width x height in tiles)
- [ ] outputs (commodities produced)
- [ ] inputs (commodities required)
- [ ] productionRate (units per cycle)
- [ ] workerCapacity (min, max, efficiency bonus)
- [ ] placementConstraints (from natural resources)

**Info System UI:**
- [ ] Verify all fields editable
- [ ] Add production rate display with units: "15 kg wheat/day"
- [ ] Show "Feeds X people" calculated field

---

### Task 3.2: Recipe Display with Units
**Info System UI:**
- [ ] Update recipe display to show units:
  ```
  Bakery: 2 kg wheat + 0.5 L water → 3 loaves bread
  Time: 4 hours | Feeds: 6 people
  ```
- [ ] Calculate and show daily capacity
- [ ] Show worker efficiency impact

---

## Phase 4: Immigration & Trade Data

### Task 4.1: Immigration Configuration
**File:** `data/base/immigration_config.json` (NEW)

```json
{
  "attractivenessWeights": {
    "avgSatisfaction": 0.3,
    "housingAvailability": 0.25,
    "jobAvailability": 0.2,
    "wealthOpportunity": 0.15,
    "safetyRating": 0.1
  },
  "immigrantGenerationRate": {
    "basePerDay": 0.5,
    "attractivenessMultiplier": true
  },
  "backstoryTemplates": {
    "lowSafety": "[name] fled [origin] seeking safety from [threat]",
    "lowFood": "[name] left [origin] due to famine and food shortages",
    "lowOpportunity": "[name] seeks better opportunities than [origin] offered"
  }
}
```

**Info System UI:**
- [ ] Create "Immigration" settings tab
- [ ] Edit attractiveness weights
- [ ] Edit backstory templates
- [ ] Preview backstory generation

---

### Task 4.2: Trade/Loan Configuration
**File:** `data/base/economy_config.json` (NEW)

```json
{
  "worldMarket": {
    "priceMultiplier": 1.15,
    "description": "World prices are 15% above local"
  },
  "loans": {
    "interestRate": 0.08,
    "repaymentCycles": 30,
    "maxLoanMultiplier": 2.0,
    "latePaymentPenalty": 0.02,
    "creditRatingLevels": ["Poor", "Fair", "Good", "Excellent"]
  },
  "localPrices": {
    "wheat": 3,
    "bread": 8,
    "meat": 15,
    "wine": 12
  }
}
```

**Info System UI:**
- [ ] Create "Economy" settings tab
- [ ] Edit local prices per commodity
- [ ] Edit loan parameters
- [ ] Edit world market multiplier

---

## Phase 5: Analytics & Insights

### Task 5.1: Insight Rules Configuration
**File:** `data/base/insight_rules.json` (NEW)

```json
{
  "rules": [
    {
      "id": "low_satisfaction_dimension",
      "condition": "dimension.satisfaction < 40 && dimension.daysBelowThreshold > 3",
      "template": "[dimensionName] satisfaction is critically low. Consider [suggestion].",
      "suggestions": {
        "biological_nutrition": "increasing food production or imports",
        "psychological_entertainment": "building a tavern or theater",
        "touch_comfort_rest": "ensuring adequate housing with beds"
      },
      "priority": "high"
    },
    {
      "id": "shortage_warning",
      "condition": "commodity.daysOfSupply < 5",
      "template": "[commodityName] will run out in [days] days at current consumption.",
      "priority": "medium"
    },
    {
      "id": "emigration_risk",
      "condition": "character.emigrationRisk > 0.5",
      "template": "[count] citizens are at high risk of leaving.",
      "priority": "high"
    }
  ]
}
```

**Info System UI:**
- [ ] Create "Insights" configuration tab
- [ ] List all insight rules
- [ ] Edit conditions (with syntax help)
- [ ] Edit templates
- [ ] Set priority levels

---

## Phase 6: Data Validation & Cleanup

### Task 6.1: Remove Hardcoded Values
Search and update:
- [ ] Class names (Elite, Upper, Middle, Lower, Poor) → Load from data
- [ ] Fine craving count (49) → Compute from loaded dimensions
- [ ] Coarse craving count (9) → Compute from loaded categories
- [ ] Slot count → Load from time_slots.json

### Task 6.2: Schema Validation
**Info System UI:**
- [ ] Add "Validate All Data" button
- [ ] Check for:
  - All cravings have slot mappings
  - All commodities have units
  - All buildings have required fields
  - No orphaned references

---

## Implementation Order

```
Week 1 Priority (Unblock Data Entry):
├── Task 1.1: Time Slots Definition
├── Task 1.2: Craving-to-Slot Mapping
├── Task 1.3: Units System
└── Task 1.4: Update Fulfillment Vectors

Week 1 Secondary:
├── Task 2.1: Fine-Level Satisfaction
├── Task 2.2: Commodity-Craving Index
└── Task 2.3: Fatigue/Freshness Updates

Week 2 (Can Do During Game Dev):
├── Task 3.1-3.2: Building/Recipe Updates
├── Task 4.1-4.2: Immigration/Trade Config
├── Task 5.1: Insight Rules
└── Task 6.1-6.2: Validation & Cleanup
```

---

## Files to Create/Update Summary

### New Files:
- `data/base/time_slots.json`
- `data/base/craving_slots.json`
- `data/base/units.json`
- `data/base/commodity_craving_index.json` (generated)
- `data/base/immigration_config.json`
- `data/base/economy_config.json`
- `data/base/insight_rules.json`

### Updated Files:
- `data/base/craving_system/fulfillment_vectors.json` (add units)
- `data/base/consumption_mechanics.json` (slot-based fatigue)
- `data/base/building_types.json` (verify schema)

### Info System New Tabs:
- Time Slots
- Units
- Economy (Trade/Loans)
- Insights Configuration

### Info System Updated Tabs:
- Commodities (add units, slot mapping preview)
- Cravings/Dimensions (add slot mapping editor)
- Buildings (units in production display)

---

## Change Log

| Date | Change |
|------|--------|
| 2025-12-06 | Created initial TODO list for alpha |
