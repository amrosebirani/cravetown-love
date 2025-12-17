# CraveTown Alpha - Design Summary

**Created:** 2025-12-06
**Purpose:** Birthday gift alpha prototype for Mansi
**Status:** Planning Complete - Ready for Implementation

---

## Core System Changes from Original Design

### 1. Temporal System: Cycles → Time Slots

**Before:** 60-second cycles, all cravings processed every cycle
**After:** 6 time slots per day, cravings activate in specific slots

| Slot | Hours | Description |
|------|-------|-------------|
| early_morning | 5:00-8:00 | Wake up, breakfast |
| morning | 8:00-12:00 | Work, activities |
| afternoon | 12:00-17:00 | Lunch, social |
| evening | 17:00-21:00 | Dinner, entertainment |
| night | 21:00-24:00 | Relaxation |
| late_night | 0:00-5:00 | Sleep, rest |

**Day Speeds:**
- Normal: 5 minutes real-time = 1 game day
- Fast: 2.5 minutes = 1 game day
- Faster: 60 seconds = 1 game day

---

### 2. Craving-Slot Mapping System

Each fine craving dimension maps to specific slots:

```
biological_nutrition_grain → [early_morning, afternoon, evening]
biological_nutrition_protein → [afternoon, evening]
touch_comfort_rest → [late_night]
psychological_entertainment → [evening, night]
```

**Modifiers:**
- Class modifiers: Elite have leisure in afternoon
- Trait modifiers: Workaholics skip evening entertainment

**Processing:**
- Cravings only accumulate during their mapped slots
- Allocation runs at slot boundaries
- Durables apply once per day at specific slot (e.g., beds at late_night)

---

### 3. Units System

**Person-Day Baseline:**
- 2000 calories
- 2 liters water
- 8 hours sleep

**Commodity Units:**
```json
{
  "wheat": { "unit": "kg", "caloriesPerUnit": 3400 },
  "bread": { "unit": "loaf", "weightKg": 0.5, "caloriesPerUnit": 1200 },
  "meat": { "unit": "kg", "caloriesPerUnit": 2500 },
  "water": { "unit": "liter" },
  "bed": { "unit": "piece", "durationType": "permanent" }
}
```

**Display Format:**
- "1 loaf (500g) provides 60% daily grain need"
- "Bakery produces 15 loaves/day, feeds 9 people"

---

### 4. Allocation Algorithm

**New Approach:** Find optimal commodity bundle for slot's active cravings

**Algorithm (Greedy for Alpha):**
1. Get character's active craving vector for current slot
2. Sort cravings by urgency (highest first)
3. For each craving, find best available commodity
4. Allocate until inventory depleted or satisfied

**Pre-computed Index:**
```json
{
  "byCraving": {
    "biological_nutrition_grain": [
      { "commodityId": "bread", "effectiveness": 15, "rank": 1 },
      { "commodityId": "wheat", "effectiveness": 12, "rank": 2 }
    ]
  },
  "byCommodity": {
    "bread": [
      { "cravingId": "biological_nutrition_grain", "points": 15 }
    ]
  }
}
```

---

### 5. Satisfaction Tracking

**Before:** 9-dimensional coarse satisfaction
**After:** 49-dimensional fine satisfaction

- Track satisfaction at fine level
- Compute coarse as **average** of fine dimensions (not sum)
- Display both in UI where appropriate

---

### 6. Simplified Economy (Alpha)

**Removed for Alpha:**
- Consumption budget (allocate based on inventory only)
- Wealth/income system (deferred)
- Complex consequences (emigration, protests, riots)

**Kept for Alpha (if time permits):**
- Trade: Fixed world prices (15% above local)
- Loans: 8% interest, 30-day repayment, credit rating

---

### 7. Durable Goods (Already Implemented)

- Consumables: Instant satisfaction (bread, medicine)
- Durables: Ongoing satisfaction, decay over time (bed, furniture)
- Permanent: Last forever (house)

**Alpha Change:** Durables apply once per day at specific slot

---

## Data Files Summary

### New Files to Create

| File | Purpose |
|------|---------|
| `data/base/time_slots.json` | 6 time slot definitions |
| `data/base/craving_slots.json` | Craving-to-slot mappings |
| `data/base/units.json` | Units system configuration |
| `data/base/commodity_craving_index.json` | Pre-computed lookup (generated) |
| `data/base/immigration_config.json` | Immigration settings |
| `data/base/economy_config.json` | Trade/loan settings |

### Files to Update

| File | Changes |
|------|---------|
| `fulfillment_vectors.json` | Add unit fields to commodities |
| `consumption_mechanics.json` | Slot-based fatigue settings |
| `building_types.json` | Verify all required fields |

---

## Code Architecture

### New Lua Files

| File | Purpose |
|------|---------|
| `code/BirthdaySplash.lua` | Birthday splash screen for Mansi |
| `code/TimeManager.lua` | Time/day tracking, slot transitions |
| `code/SlotManager.lua` | Slot-based craving activation |

### Major Updates

| File | Changes |
|------|---------|
| `ConsumptionPrototype.lua` | Time system integration, slot processing |
| `CharacterV2.lua` | Fine satisfaction, slot-based effects |
| `AllocationEngineV2.lua` | New bundle-finding algorithm |
| `CravingManager.lua` | Slot mappings, class/trait modifiers |
| `InfoSystemState.lua` | New tabs for slots, units, economy |

---

## UI Changes Summary

### World View (New)
- Grid-based terrain with buildings
- Character sprites moving
- Day/night visual cycle

### Top Bar
- Town name, day number, time of day
- Speed controls (Normal/Fast/Faster/Pause)
- Population count

### Panels
- Left: Quick stats, alerts, mini-map
- Right: Selected entity details
- Bottom: Event log with filters

### Character Modal Updates
- Fine satisfaction breakdown
- Slot-based activity display
- Possession effectiveness
- Consumption history per slot

### Info System New Tabs
- Time Slots (edit slot definitions)
- Units (configure units and baselines)
- Economy (trade/loan settings)
- Slot Mapping (craving-to-slot assignments)

---

## Birthday Splash Screen

**Shown:** Once per session, before title screen
**Content:**
- "Happy Birthday Mansi!" (animated title)
- "This game is dedicated to you" (subtitle)
- Gentle animation (floating hearts/stars/particles)
- "Click to Continue" prompt
- Skip after 2 seconds with any key/click

---

## Implementation Priority

### P0 - Must Have (Core Playability)
1. Birthday splash screen
2. Time system (day/night, 6 slots)
3. Slot-based craving activation
4. New allocation algorithm
5. Basic UI showing time and satisfaction

### P1 - Should Have (Full Experience)
1. Building placement
2. Production integration
3. Immigration system
4. World view with characters

### P2 - Nice to Have (Polish)
1. Trade system
2. Loan system
3. Notifications
4. Icon spritesheet

### P3 - Cut if Needed
1. Advanced analytics
2. Insights system
3. Complex consequence chains

---

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Slot count | 6 | Matches natural daily rhythm |
| Satisfaction level | Fine (49D) | More granular player feedback |
| Coarse computation | Average of fine | Prevents inflation |
| Durable application | Once per day | Prevents overpowered passive income |
| Budget system | Removed | Simplifies alpha, adds later |
| Wealth system | Deferred | Focus on core loop |
| Icons | Spritesheet | Better control, consistent style |
| Backstories | Procedural | Generated from craving profile |

---

## Testing Checklist

- [ ] Birthday splash appears and is skippable
- [ ] Day/night cycle visible
- [ ] 6 time slots transition correctly
- [ ] Cravings only activate in mapped slots
- [ ] Allocation produces sensible results
- [ ] Character satisfaction visible and updating
- [ ] Buildings can be placed
- [ ] Production adds to inventory
- [ ] Immigration generates characters
- [ ] No crashes during 10-minute play session

---

## Change Log

| Date | Change |
|------|--------|
| 2025-12-06 | Created consolidated design summary |

