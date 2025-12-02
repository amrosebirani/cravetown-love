# Durable Goods System - Implementation Plan

**Created:** 2025-12-02
**Status:** Planning
**Goal:** Implement a system where commodities can provide ongoing satisfaction over multiple cycles (durables) vs instant one-time satisfaction (consumables).

---

## Overview

### Current System
- All commodities are consumed instantly (1 unit per allocation)
- Cravings reduce immediately upon consumption
- No distinction between bread (eaten once) and bed (used repeatedly)

### New System
- **Consumables**: Instant, one-time satisfaction (bread, cake, medicine)
- **Durables**: Ongoing satisfaction over multiple cycles (bed, furniture, tools)
- **Permanent**: Last forever within normal gameplay (house)

---

## Design Decisions

| Question | Decision |
|----------|----------|
| Ownership | Durables owned by individual characters |
| Worn-out handling | Replace (no repair system) |
| Category limits | One per category by default, configurable via metadata |
| Passive satisfaction | Full fulfillment vector applied each cycle |
| Allocation priority | Same as consumables (craving-based selection) |
| Inventory | Removed from town inventory when acquired |

---

## Phase 1: Data Structure Updates

### Task 1.1: Update Commodity Metadata Schema
**File:** `data/base/craving_system/fulfillment_vectors.json`

Add new fields to commodity definitions:
```json
{
  "bed": {
    "id": "bed",
    "durability": "durable",        // "consumable" | "durable" | "permanent"
    "durationCycles": 100,          // cycles before expiry (null for consumable/permanent)
    "effectDecayRate": 0.01,        // effectiveness loss per cycle (0 = no decay)
    "maxOwned": 1,                  // max instances character can own (default 1)
    "category": "furniture_sleep",  // for slot management
    "fulfillmentVector": {...}
  }
}
```

**Defaults:**
- `durability`: "consumable" (if not specified)
- `durationCycles`: null (consumables don't have duration)
- `effectDecayRate`: 0 (no decay by default)
- `maxOwned`: 1 (one per category)

### Task 1.2: Update Sample Commodities with Durability Info
Add durability metadata to existing commodities in fulfillment_vectors.json:
- Food items → consumable
- Furniture → durable (50-200 cycles)
- Tools → durable (100-500 cycles)
- Clothing → durable (50-150 cycles)
- Housing → permanent
- Decorative → durable with maxOwned > 1

---

## Phase 2: Character State Changes

### Task 2.1: Add Active Effects Layer to CharacterV2
**File:** `code/consumption/CharacterV2.lua`

Add new character state:
```lua
-- LAYER 7: Active Effects (durable goods providing ongoing satisfaction)
char.activeEffects = {}  -- Array of active durable/permanent goods
--[[
  Each effect:
  {
    commodityId = "bed",
    category = "furniture_sleep",
    acquiredCycle = 50,
    remainingCycles = 95,        -- nil for permanent
    currentEffectiveness = 0.95, -- 1.0 to 0.0, decays over time
    fulfillmentVector = {...},   -- cached fine vector
    durability = "durable"       -- "durable" | "permanent"
  }
]]
```

### Task 2.2: Implement AddActiveEffect Function
**File:** `code/consumption/CharacterV2.lua`

```lua
function Character:AddActiveEffect(commodityId, currentCycle)
  -- Get commodity data
  -- Check if can add (maxOwned limit, category slot)
  -- If replacing existing in same category, remove old
  -- Create effect entry
  -- Add to activeEffects array
end
```

### Task 2.3: Implement UpdateActiveEffects Function
**File:** `code/consumption/CharacterV2.lua`

Called each cycle to:
- Decay effectiveness based on effectDecayRate
- Decrement remainingCycles for durables
- Remove expired effects (remainingCycles <= 0)
- Skip permanent items (no expiry)

```lua
function Character:UpdateActiveEffects(currentCycle)
  -- Iterate through activeEffects
  -- Apply decay: effect.currentEffectiveness *= (1 - decayRate)
  -- Decrement: effect.remainingCycles -= 1 (if not permanent)
  -- Remove expired: filter out where remainingCycles <= 0
end
```

### Task 2.4: Implement ApplyActiveEffectsSatisfaction Function
**File:** `code/consumption/CharacterV2.lua`

Called each cycle to passively reduce cravings:
```lua
function Character:ApplyActiveEffectsSatisfaction(currentCycle)
  -- For each active effect:
  --   Apply fulfillmentVector * currentEffectiveness to reduce cravings
  --   Similar to FulfillCraving but without fatigue tracking
end
```

### Task 2.5: Implement HasActiveEffectForCategory Function
**File:** `code/consumption/CharacterV2.lua`

```lua
function Character:HasActiveEffectForCategory(category)
  -- Check if character already has an active effect in this category
  -- Return true/false
end

function Character:GetActiveEffectCount(commodityId)
  -- Count how many of this commodity character owns
  -- For maxOwned checking
end
```

---

## Phase 3: Allocation Logic Changes

### Task 3.1: Modify AllocateForCharacter for Durables
**File:** `code/consumption/AllocationEngineV2.lua`

When allocating a durable:
1. Check if character already has max in this category
2. If yes, skip this commodity (try next best)
3. If no, allocate and create active effect instead of instant consumption

```lua
-- In AllocateForCharacter:
local commodityData = FulfillmentVectors.commodities[targetCommodity]
local durability = commodityData.durability or "consumable"

if durability == "durable" or durability == "permanent" then
  -- Check if character can acquire this
  local category = commodityData.category or targetCommodity
  local maxOwned = commodityData.maxOwned or 1

  if character:GetActiveEffectCount(targetCommodity) >= maxOwned then
    -- Already has max, this commodity not available for this character
    -- Try substitution or next craving
  else
    -- Allocate as durable: create active effect
    character:AddActiveEffect(targetCommodity, currentCycle)
    -- Still remove from inventory
    townInventory[targetCommodity] = townInventory[targetCommodity] - 1
  end
else
  -- Consumable: existing instant consumption logic
  character:FulfillCraving(targetCommodity, 1, currentCycle)
end
```

### Task 3.2: Update SelectTargetCraving to Skip Owned Durables
**File:** `code/consumption/AllocationEngineV2.lua`

When evaluating commodities, skip durables the character already owns (at max capacity):
```lua
-- In the commodity evaluation loop:
if commodityData.durability == "durable" or commodityData.durability == "permanent" then
  local maxOwned = commodityData.maxOwned or 1
  if character:GetActiveEffectCount(commodityId) >= maxOwned then
    -- Skip this commodity, character already has it
    goto continue_commodity
  end
end
```

---

## Phase 4: Cycle Processing Integration

### Task 4.1: Integrate Active Effects into Update Loop
**File:** `code/ConsumptionPrototype.lua`

In the Update function, before allocation:
```lua
-- Update and apply active effects for all characters
for _, character in ipairs(self.characters) do
  if not character.hasEmigrated then
    -- 1. Update effects (decay, remove expired)
    character:UpdateActiveEffects(self.cycleNumber)
    -- 2. Apply passive satisfaction from active effects
    character:ApplyActiveEffectsSatisfaction(self.cycleNumber)
  end
end
```

### Task 4.2: Add Active Effects to Cycle Logging
Log when effects are applied, when they expire, etc. for the event log.

---

## Phase 5: Save/Load Support

### Task 5.1: Include Active Effects in Save Data
**File:** `code/ConsumptionPrototype.lua`

Update `CreateSaveData` to include character.activeEffects.

### Task 5.2: Restore Active Effects on Load
**File:** `code/ConsumptionPrototype.lua`

Update `LoadSaveData` to restore character.activeEffects.

---

## Phase 6: UI Updates (Consumption Prototype)

### Task 6.1: Add Possessions Section to Character Detail Modal
**File:** `code/ConsumptionPrototype.lua`

Add new section "POSSESSIONS" (Section 7) in RenderCharacterDetailModal:
```
┌─────────────────────────────────────────────────────┐
│ POSSESSIONS (3 items)                               │
├─────────────────────────────────────────────────────┤
│ 🛏️ Bed (furniture_sleep)                            │
│    Remaining: 87/100 cycles | Effectiveness: 93%   │
│    [████████░░] Condition                           │
│                                                     │
│ 🪑 Chair (furniture_comfort)                        │
│    Remaining: 45/80 cycles | Effectiveness: 78%    │
│    [██████░░░░] Condition                           │
│                                                     │
│ 🏠 House (housing) - PERMANENT                      │
│    Effectiveness: 100%                              │
└─────────────────────────────────────────────────────┘
```

Display for each possession:
- Commodity name and category
- Durability type badge (durable/permanent)
- Remaining cycles (for durables)
- Current effectiveness as percentage and bar
- Fulfillment preview (what cravings it satisfies)

### Task 6.2: Add Edit Mode Controls for Possessions
**File:** `code/ConsumptionPrototype.lua`

In edit mode, allow:
- Remove possession (X button)
- Add possession manually (dropdown of available durables)
- Reset effectiveness to 100%
- Set remaining cycles

### Task 6.3: Update Consumption History for Durables
**File:** `code/ConsumptionPrototype.lua`

Show "Acquired bed (durable, 100 cycles)" instead of "Consumed bed".
Add icon/badge to distinguish acquisitions from consumptions.

### Task 6.4: Add Possessions Summary to Character Card
**File:** `code/ConsumptionPrototype.lua`

On character card in grid view:
- Small icons showing owned durables (bed, house, etc.)
- Or count badge: "📦 3" (3 possessions)
- Color indicator if any possession is degraded (<50% effectiveness)

### Task 6.5: Add Possessions Column to Analytics Heatmap Table
**File:** `code/ConsumptionPrototype.lua`

In table-style heatmap view:
- Add column showing possession count per character
- Or icons for key possessions (housing, furniture)

### Task 6.6: Add Town Possessions Summary to Analytics
**File:** `code/ConsumptionPrototype.lua`

In Analytics modal, add section showing:
- Total durables owned across town
- Breakdown by category (X beds, Y chairs, Z houses)
- Characters without essential durables (no housing, no bed)
- Average possession effectiveness

---

## Phase 7: Testing & Polish

### Task 7.1: Add Test Scenario for Durables
In Testing Tools, add scenario that:
- Adds characters with no possessions
- Adds durable goods to inventory
- Verifies characters acquire and benefit from them

### Task 7.2: Verify Balance
- Check that durables don't make consumables obsolete
- Verify cravings are satisfied appropriately
- Test edge cases (effect expiry, replacement)

---

## Phase 8: Information System Updates

### Task 8.1: Add Commodities Tab to InfoSystem
**File:** `code/InfoSystemState.lua`

Create a new tab for viewing/editing commodities:
- Tab button alongside "Recipes", "Workers"
- List of all commodities in left panel
- Search/filter functionality
- Category grouping (optional)

### Task 8.2: Create Commodity Detail View
**File:** `code/InfoSystemState.lua`

Display commodity information:
- Basic info: id, name, tags
- Fulfillment vector (coarse & fine)
- Quality multipliers
- **NEW: Durability section**

### Task 8.3: Add Durability Fields Display
**File:** `code/InfoSystemState.lua`

Show durability-related fields:
```
┌─────────────────────────────────────┐
│ DURABILITY                          │
├─────────────────────────────────────┤
│ Type:        [Consumable ▼]         │
│ Duration:    [100    ] cycles       │
│ Decay Rate:  [0.005  ] per cycle    │
│ Category:    [furniture_sleep    ]  │
│ Max Owned:   [1      ]              │
└─────────────────────────────────────┘
```

### Task 8.4: Implement Durability Fields Editing
**File:** `code/InfoSystemState.lua`

Allow editing durability fields:
- Dropdown for durability type (consumable/durable/permanent)
- Number inputs for durationCycles, effectDecayRate, maxOwned
- Text input for category
- Validation (e.g., permanent items don't need duration)

### Task 8.5: Save Commodity Changes
**File:** `code/InfoSystemState.lua`

- Save edited commodity data back to fulfillment_vectors.json
- Or create a separate commodities_overrides.json for modding
- Handle data versioning

### Task 8.6: Load Durability Data from Fulfillment Vectors
**File:** `code/InfoSystemState.lua`

Update LoadCommodities to also load from fulfillment_vectors.json:
- Merge basic commodity info with fulfillment vector data
- Display combined view in the UI

### Task 8.7: Add Commodity Categories Management (Optional)
**File:** `code/InfoSystemState.lua`

- View/edit list of valid categories
- Assign colors to categories for visual grouping
- Filter commodities by category

---

## Implementation Order

| Phase | Description | Tasks | Priority | Dependencies |
|-------|-------------|-------|----------|--------------|
| 1 | Data Structure Updates | 1.1, 1.2 | HIGH | None |
| 2 | Character State Changes | 2.1-2.5 | HIGH | Phase 1 |
| 3 | Allocation Logic Changes | 3.1, 3.2 | HIGH | Phase 2 |
| 4 | Cycle Processing | 4.1, 4.2 | HIGH | Phase 3 |
| 5 | Save/Load Support | 5.1, 5.2 | MEDIUM | Phase 4 |
| 6 | UI Updates (Consumption Prototype) | 6.1-6.6 | MEDIUM | Phase 4 |
| 7 | Testing & Polish | 7.1, 7.2 | MEDIUM | Phase 6 |
| 8 | Information System Updates | 8.1-8.7 | MEDIUM | Phase 1 |

**Total: 8 phases, 28 tasks**

---

## Example Commodity Configurations

```json
// Consumable (default)
"bread": {
  "durability": "consumable",
  "fulfillmentVector": {"biological_nutrition_grain": 15}
}

// Durable with decay
"bed": {
  "durability": "durable",
  "durationCycles": 100,
  "effectDecayRate": 0.005,
  "category": "furniture_sleep",
  "maxOwned": 1,
  "fulfillmentVector": {"touch_comfort_rest": 15, "psychological_peace_relaxation": 10}
}

// Durable with multiple allowed
"painting": {
  "durability": "durable",
  "durationCycles": 500,
  "effectDecayRate": 0.001,
  "category": "decoration",
  "maxOwned": 5,
  "fulfillmentVector": {"psychological_beauty_visual": 5}
}

// Permanent
"house": {
  "durability": "permanent",
  "category": "housing",
  "maxOwned": 1,
  "fulfillmentVector": {"safety_shelter_weather": 20, "psychological_peace_privacy": 15}
}
```

---

## Change Log

| Date | Task | Status | Notes |
|------|------|--------|-------|
| 2025-12-02 | - | Planning | Created implementation plan |
| 2025-12-02 | Phase 1 | Complete | Updated fulfillment_vectors.json with durability schema and sample commodities |
| 2025-12-02 | Phase 2 | Complete | Added activeEffects layer to CharacterV2, implemented AddActiveEffect, UpdateActiveEffects, ApplyActiveEffectsSatisfaction |
| 2025-12-02 | Phase 3 | Complete | Modified AllocateForCharacter, SelectTargetCraving, GetBestCommodityForCraving, FindBestSubstitute to handle durables |
| 2025-12-02 | Phase 4 | Complete | Integrated active effects into update loop with expiry and acquisition logging |
| 2025-12-02 | Phase 5 | Complete | Added save/load support for activeEffects |
| 2025-12-02 | Phase 6 | Complete | Added Possessions section to character detail modal, possession count on cards, updated history display |

