# Era Progression & Trade System Implementation TODO

**Created:** 2025-01-22
**Status:** Ready for Implementation
**Estimated Phases:** 3 (A: Era System, B: Trade System, C: Polish)
**Related Documents:**
- [Era Progression System Design](../systems/era_progression_system_design.md)
- [Trade System Design](../systems/trade_system_design.md)
- [Narrative Script](../systems/era_narrative_script.md)

---

## Overview

This TODO list provides a step-by-step implementation guide for:
1. **Era Progression System** - Progressive craving/building unlocks
2. **Trade System** - Inter-town trading with AI partners
3. **Narrative Events** - Story-driven era transitions

---

## Phase A: Era System Foundation

### A1. Data Configuration [CRITICAL]

#### A1.1 Create eras.json
- [ ] Create file `data/alpha/eras.json`
- [ ] Define Settlement era (id: "settlement", order: 1)
  - [ ] enabled_craving_categories: ["biological"]
  - [ ] enabled_buildings: ["farm", "well", "bakery", "lodge", "sawmill", "granary"]
  - [ ] time_slot_mode: "simple"
  - [ ] unlock_conditions: { "auto": true }
  - [ ] narrative_event with title and description
- [ ] Define Village era (id: "village", order: 2)
  - [ ] enabled_craving_categories: ["biological", "safety", "touch"]
  - [ ] enabled_buildings: ["guard_post", "tailor", "carpenter", "smithy", "warehouse"]
  - [ ] time_slot_mode: "simple"
  - [ ] unlock_conditions: population: 15, min_avg_satisfaction: 45, sustained_cycles: 20
  - [ ] narrative_event
- [ ] Define Town era (id: "town", order: 3)
  - [ ] enabled_craving_categories: add "psychological", "social_connection"
  - [ ] enabled_buildings: ["school", "temple", "tavern", "library", "hospital"]
  - [ ] time_slot_mode: "full"
  - [ ] unlock_conditions: population: 35, min_avg_satisfaction: 50, required_buildings: ["guard_post", "tailor"]
  - [ ] narrative_event
- [ ] Define City era (id: "city", order: 4)
  - [ ] enabled_craving_categories: add "social_status", "utility"
  - [ ] enabled_buildings: ["bank", "workshop", "manor", "courthouse", "depot"]
  - [ ] time_slot_mode: "full"
  - [ ] unlock_conditions: population: 75, min_treasury: 3000, elite_population_percent: 5
  - [ ] narrative_event
- [ ] Define Metropolis era (id: "metropolis", order: 5)
  - [ ] enabled_craving_categories: add "exotic_goods", "shiny_objects", "vice"
  - [ ] enabled_buildings: ["market", "jeweler", "brewery", "theater", "casino"]
  - [ ] time_slot_mode: "full"
  - [ ] unlock_conditions: population: 150, min_treasury: 10000, active_trade_routes: 1
  - [ ] narrative_event
- [ ] Add time_slot_modes configuration
  - [ ] "simple" mode: slots ["morning", "evening", "night"] with mapping
  - [ ] "full" mode: slots ["early_morning", "morning", "afternoon", "evening", "night", "late_night"]
- [ ] Validate all building IDs exist in building_types.json

#### A1.2 Update craving_slots.json
- [ ] Open `data/alpha/craving_slots.json`
- [ ] For each craving mapping, add `simple_slots` array:
  - [ ] biological_nutrition_grain: simple_slots: ["morning", "evening"]
  - [ ] biological_nutrition_protein: simple_slots: ["evening"]
  - [ ] biological_nutrition_produce: simple_slots: ["morning", "evening"]
  - [ ] biological_hydration: simple_slots: ["morning", "evening", "night"]
  - [ ] biological_health_medicine: simple_slots: ["morning", "evening"]
  - [ ] biological_health_hygiene: simple_slots: ["morning", "night"]
  - [ ] biological_energy_rest: simple_slots: ["night"]
  - [ ] biological_energy_stimulation: simple_slots: ["morning"]
- [ ] Add simple_slots to all safety cravings
- [ ] Add simple_slots to all touch cravings
- [ ] Add simple_slots to all psychological cravings
- [ ] Add simple_slots to all social_connection cravings
- [ ] Add simple_slots to all social_status cravings
- [ ] Add simple_slots to all utility cravings
- [ ] Add simple_slots to all exotic_goods cravings
- [ ] Add simple_slots to all shiny_objects cravings
- [ ] Add simple_slots to all vice cravings
- [ ] Validate JSON syntax

---

### A2. Core EraSystem Module [CRITICAL]

#### A2.1 Create EraSystem.lua
- [ ] Create file `code/EraSystem.lua`
- [ ] Define EraSystem table with state variables:
  ```lua
  local EraSystem = {
      currentEra = nil,
      eras = {},
      sustainedCycles = 0,
      unlockHistory = {},
      isClassicMode = false,
      listeners = {}
  }
  ```
- [ ] Implement `EraSystem:Init(configPath, isClassicMode)`
  - [ ] Load eras.json using JSON library
  - [ ] Parse and store era definitions
  - [ ] Set initial era based on isClassicMode flag
  - [ ] Initialize sustainedCycles to 0

#### A2.2 Implement era accessors
- [ ] `GetCurrentEra()` - returns current era table
- [ ] `GetNextEra()` - returns next era or nil if at Metropolis
- [ ] `GetPreviousEra()` - returns previous era or nil if at Settlement
- [ ] `GetEraById(id)` - finds era by string ID
- [ ] `GetFirstEra()` - returns Settlement era
- [ ] `GetFinalEra()` - returns Metropolis era

#### A2.3 Implement craving category methods
- [ ] `GetEnabledCravingCategories()` - returns array of enabled category strings
- [ ] `IsCravingCategoryEnabled(category)` - boolean check if category is enabled
- [ ] Add helper `GetCravingCategory(cravingId)` - extracts category from craving ID
  - Parse prefix before first underscore (e.g., "biological" from "biological_nutrition_grain")

#### A2.4 Implement building methods
- [ ] `GetEnabledBuildings()` - returns current era's buildings only
- [ ] `GetAllEnabledBuildings()` - accumulates buildings from all eras up to current
- [ ] `IsBuildingEnabled(buildingType)` - boolean check

#### A2.5 Implement time slot methods
- [ ] `GetTimeSlotMode()` - returns "simple" or "full"
- [ ] `GetSimplifiedSlot(fullSlot)` - maps 6 slots to 3
- [ ] `GetTimeSlotConfig()` - returns full time slot configuration

---

### A3. Unlock Condition Checking [HIGH]

#### A3.1 Implement condition checks
- [ ] `CheckUnlockConditions(townState)` - main checking function
- [ ] Returns tuple: (allConditionsMet: boolean, progress: table)
- [ ] Implement individual condition checkers:
  - [ ] Population check: `#townState.citizens >= conditions.population`
  - [ ] Satisfaction check: Calculate average from all citizens
  - [ ] Treasury check: `townState.gold >= conditions.min_treasury`
  - [ ] Required buildings check: Loop through required_buildings array
  - [ ] Elite population percent: Count elite/upper class citizens
  - [ ] Active trade routes: Call TradeSystem:GetActiveRouteCount()

#### A3.2 Implement helper calculations
- [ ] `CalculateAverageSatisfaction(townState)` - weighted average across citizens
- [ ] `GetElitePopulationPercent(townState)` - (elite + upper) / total * 100
- [ ] `HasBuilding(townState, buildingType)` - check if building exists
- [ ] `HasAllRequiredBuildings(townState, requiredList)` - check all

#### A3.3 Implement sustained cycles tracking
- [ ] Track `sustainedCycles` counter
- [ ] Increment when all conditions met
- [ ] Reset to 0 when any condition fails
- [ ] Check against `conditions.sustained_cycles` requirement

---

### A4. Era Advancement [HIGH]

#### A4.1 Implement advancement logic
- [ ] `AdvanceEra()` function
  - [ ] Get next era
  - [ ] Update currentEra reference
  - [ ] Reset sustainedCycles to 0
  - [ ] Record in unlockHistory
  - [ ] Trigger narrative event
  - [ ] Notify listeners

#### A4.2 Implement event listener system
- [ ] `RegisterListener(callback)` - adds callback to listeners array
- [ ] `UnregisterListener(callback)` - removes callback
- [ ] `NotifyListeners(event, data)` - calls all listeners with event

#### A4.3 Implement update loop
- [ ] `Update(townState, dt)` function
  - [ ] Call CheckUnlockConditions
  - [ ] If met, increment sustainedCycles
  - [ ] If sustained requirement met, call AdvanceEra
  - [ ] If not met, reset sustainedCycles

---

### A5. Save/Load [HIGH]

#### A5.1 Implement save data
- [ ] `GetSaveData()` returns:
  ```lua
  {
      currentEraId = string,
      sustainedCycles = number,
      unlockHistory = array,
      isClassicMode = boolean
  }
  ```

#### A5.2 Implement load data
- [ ] `LoadSaveData(data)` function
  - [ ] Handle nil data (migration from old saves)
  - [ ] Default to Settlement era if no era data
  - [ ] Restore all state variables

---

### A6. AllocationEngineV2 Integration [HIGH]

#### A6.1 Add era filtering
- [ ] Import EraSystem module at top of file
- [ ] In `AllocateForCharacter()`:
  - [ ] Get enabled categories: `EraSystem:GetEnabledCravingCategories()`
  - [ ] Before selecting target craving, filter by enabled categories
  - [ ] Only consider cravings whose category is in enabled list

#### A6.2 Implement category extraction
- [ ] Add helper function `GetCravingCategory(cravingId)`
- [ ] Extract prefix before first underscore
- [ ] Cache results for performance

#### A6.3 Implement time slot simplification
- [ ] Check `EraSystem:GetTimeSlotMode()` before slot lookups
- [ ] If "simple", use `GetSimplifiedSlot()` to map current slot
- [ ] Update `GetActiveCravingsForSlot()` to use simple_slots when appropriate

#### A6.4 Testing
- [ ] Test that only biological cravings are allocated in Settlement
- [ ] Test that safety/touch appear in Village
- [ ] Test transition from simple to full time slots at Town era
- [ ] Verify no crashes with disabled cravings

---

### A7. Building Menu Integration [HIGH]

#### A7.1 Modify BuildingMenu.lua
- [ ] Import EraSystem module
- [ ] In `GetAvailableBuildings()`:
  - [ ] Filter by `EraSystem:IsBuildingEnabled(building.id)`
  - [ ] Or use `EraSystem:GetAllEnabledBuildings()` for accumulated list
- [ ] Update UI rendering to only show enabled buildings

#### A7.2 Optional: Locked building display
- [ ] Show locked buildings grayed out
- [ ] Display "Unlocks in [Era Name]" tooltip
- [ ] Requires mapping buildings to their unlock era

---

### A8. Citizen Panel Integration [MEDIUM]

#### A8.1 Modify CitizenPanel.lua (or equivalent)
- [ ] Import EraSystem module
- [ ] In craving bars rendering:
  - [ ] Get enabled categories
  - [ ] Only render bars for enabled categories
  - [ ] Adapt layout for fewer bars in early eras

#### A8.2 Update satisfaction display
- [ ] Only calculate/show satisfaction for enabled cravings
- [ ] Adjust aggregate calculation to use only enabled categories

---

### A9. AlphaPrototypeState Integration [HIGH]

#### A9.1 Initialize EraSystem
- [ ] In game initialization, call `EraSystem:Init(configPath, isClassicMode)`
- [ ] Pass isClassicMode based on difficulty selection

#### A9.2 Add update loop
- [ ] In main game update, call `EraSystem:Update(townState, dt)`
- [ ] Handle era advancement event (pause game, show modal)

#### A9.3 Add save/load integration
- [ ] In save function, include `EraSystem:GetSaveData()`
- [ ] In load function, call `EraSystem:LoadSaveData(data)`
- [ ] Handle migration for saves without era data

---

### A10. Era Transition UI [MEDIUM]

#### A10.1 Create EraTransitionModal.lua
- [ ] Create file `code/ui/EraTransitionModal.lua`
- [ ] Full-screen overlay with dimmed background
- [ ] Display era name prominently (large font, centered)
- [ ] Show narrative description text
- [ ] List new unlocked cravings with icons
- [ ] List new unlocked buildings with icons
- [ ] "Continue" button to dismiss
- [ ] Connect to EraSystem listener

#### A10.2 Create EraProgressIndicator.lua (Optional)
- [ ] Create file `code/ui/EraProgressIndicator.lua`
- [ ] Small HUD element in corner
- [ ] Shows current era name
- [ ] Progress bar toward next era (based on conditions met)
- [ ] Click to expand and see detailed requirements

---

### A11. Classic Difficulty Mode [LOW]

#### A11.1 Modify NewGameSetup.lua
- [ ] Add "Classic" to difficulty options
- [ ] Description: "All craving categories, buildings, and trade unlocked from start."
- [ ] Set flag to pass to EraSystem:Init()

#### A11.2 Test classic mode
- [ ] Verify starts at Metropolis era
- [ ] Verify all buildings available
- [ ] Verify all cravings active
- [ ] Verify trade system accessible

---

## Phase B: Trade System

### B1. Trade Data Configuration [CRITICAL for Phase B]

#### B1.1 Create trade_partners.json
- [ ] Create directory `data/alpha/trade/`
- [ ] Create file `data/alpha/trade/trade_partners.json`
- [ ] Define Saltshore (fishing_village):
  - [ ] id, name, specialty: "fishing", location: "coastal"
  - [ ] exports: fish (20, 5g), dried_fish (10, 8g), salt (5, 12g)
  - [ ] imports: wheat (high, 8g), tools (high, 25g), vegetables (medium, 6g)
  - [ ] personality: friendliness: 0.8, priceFlexibility: 0.2, reliability: 0.9
  - [ ] discoveryRequirement: era: "city", startingLocations: ["river_valley", "fertile_plains"]
- [ ] Define Ironholt (mining_town):
  - [ ] specialty: "mining"
  - [ ] exports: iron_ore, coal, tools
  - [ ] imports: food (all types), cloth, wood
  - [ ] personality: aggressive (friendliness: 0.4)
- [ ] Define Goldwheat (farming_hamlet):
  - [ ] specialty: "farming"
  - [ ] exports: wheat, vegetables, livestock
  - [ ] imports: metal goods, cloth, luxuries
  - [ ] personality: conservative (priceFlexibility: 0.1)
- [ ] Define Timberfall (forest_camp):
  - [ ] specialty: "forestry"
  - [ ] exports: lumber, herbs, game_meat
  - [ ] imports: metal tools, cloth, food
  - [ ] personality: cautious
- [ ] Define Sandhaven (desert_oasis):
  - [ ] specialty: "trade_hub"
  - [ ] exports: exotic spices, silk, gems
  - [ ] imports: everything (hub role)
  - [ ] personality: opportunistic, premium prices
  - [ ] discoveryRequirement: era: "metropolis"
- [ ] Define Peakrest (mountain_monastery):
  - [ ] specialty: "crafts"
  - [ ] exports: books, art, medicine
  - [ ] imports: basic food, cloth, building materials
  - [ ] personality: scholarly

#### B1.2 Create trade_config.json
- [ ] Create file `data/alpha/trade/trade_config.json`
- [ ] Define establishment_costs per partner type (500-1500g)
- [ ] Define establishment_time (5-10 cycles)
- [ ] Define exchange_frequency (10 cycles)
- [ ] Define route_slots_per_era: { city: 1, metropolis: 5 }
- [ ] Define agreement_duration (50 cycles)
- [ ] Define trust_decay_rate
- [ ] Define price_fluctuation_range

---

### B2. Core TradeSystem Module [HIGH for Phase B]

#### B2.1 Create TradeSystem.lua
- [ ] Create file `code/TradeSystem.lua`
- [ ] Define TradeSystem table:
  ```lua
  local TradeSystem = {
      partners = {},
      activeRoutes = {},
      establishingRoutes = {},
      discoveredPartners = {},
      config = {}
  }
  ```
- [ ] Implement `Init(configPath)`
  - [ ] Load trade_partners.json
  - [ ] Load trade_config.json
  - [ ] Initialize empty routes

#### B2.2 Implement partner discovery
- [ ] `DiscoverPartners(townState, startingLocation)` function
  - [ ] Check era requirement for each partner
  - [ ] Check location compatibility
  - [ ] Apply random discovery chance
  - [ ] Add to discoveredPartners list
- [ ] `GetDiscoveredPartners()` - returns list
- [ ] `GetAvailablePartners()` - discovered but no active route

#### B2.3 Implement route management
- [ ] `EstablishRoute(partnerId)` function
  - [ ] Check gold cost
  - [ ] Deduct gold
  - [ ] Create establishing route entry
  - [ ] Set establishment countdown
- [ ] `CompleteEstablishment(routeId)` - called when countdown reaches 0
- [ ] `GetActiveRoutes()` - returns active routes array
- [ ] `GetEstablishingRoutes()` - returns in-progress routes
- [ ] `GetActiveRouteCount()` - for EraSystem integration
- [ ] `SuspendRoute(routeId)` - pause exchanges
- [ ] `ResumeRoute(routeId)` - resume exchanges
- [ ] `TerminateRoute(routeId)` - end route permanently

#### B2.4 Implement trade exchange
- [ ] `ProcessAllExchanges()` - called each cycle
  - [ ] Loop through active routes
  - [ ] Check if exchange is due (based on frequency)
  - [ ] Call ProcessExchange for each due route
- [ ] `ProcessExchange(route)` function
  - [ ] Process exports: remove from inventory, gain gold
  - [ ] Process imports: spend gold, add to inventory
  - [ ] Handle partial fulfillment (not enough goods/gold)
  - [ ] Update trust level
  - [ ] Log transaction

#### B2.5 Implement partner AI pricing
- [ ] `CalculateExportPrice(partner, commodity, basePrice)` function
  - [ ] Apply personality modifiers (friendliness)
  - [ ] Apply trust modifier (better prices over time)
  - [ ] Apply supply/demand modifier
- [ ] `CalculateImportPrice(partner, commodity, basePrice)` function
  - [ ] Similar modifiers

#### B2.6 Implement save/load
- [ ] `GetSaveData()` returns:
  - activeRoutes, establishingRoutes, discoveredPartners
  - Partner trust levels
- [ ] `LoadSaveData(data)` restores state

---

### B3. Trade System Integration [HIGH for Phase B]

#### B3.1 Integrate with AlphaPrototypeState
- [ ] Initialize TradeSystem in game start
- [ ] Call `TradeSystem:Update(dt)` each cycle
  - [ ] Update establishing routes countdown
  - [ ] Complete establishment when ready
  - [ ] Process exchanges for active routes
- [ ] Include trade data in save/load

#### B3.2 Integrate with EraSystem
- [ ] TradeSystem only active when era >= City
- [ ] `GetActiveRouteCount()` used by EraSystem for Metropolis unlock
- [ ] Trigger partner discovery event on City era entry
- [ ] Expand route slots on Metropolis entry

#### B3.3 Integrate with Inventory
- [ ] Verify import commodities exist in commodity definitions
- [ ] Add imported goods to town inventory correctly
- [ ] Remove exported goods from inventory correctly
- [ ] Handle edge cases (not enough to export)

---

### B4. Trade UI [MEDIUM for Phase B]

#### B4.1 Create TradePanel.lua
- [ ] Create file `code/ui/TradePanel.lua`
- [ ] Design panel layout:
  - [ ] Available partners section (discovered, no route)
  - [ ] Active routes section (with details)
  - [ ] Trade balance summary
  - [ ] Route slot counter (X/Y)
- [ ] For each available partner:
  - [ ] Show name, specialty, exports/imports preview
  - [ ] Show establishment cost
  - [ ] "Establish Route" button
- [ ] For each active route:
  - [ ] Show partner name, cycles active
  - [ ] Show current export/import quantities
  - [ ] "Modify Deal", "Suspend", "Terminate" buttons
- [ ] Add hotkey to open panel (T key?)
- [ ] Only show when era >= City

#### B4.2 Create TradeRouteModal.lua
- [ ] Create file `code/ui/TradeRouteModal.lua`
- [ ] Modal for configuring new route:
  - [ ] Partner details display
  - [ ] Export configuration (select commodities, quantities)
  - [ ] Import configuration (select commodities, quantities)
  - [ ] Price preview
  - [ ] Estimated profit/loss calculation
  - [ ] "Establish" and "Cancel" buttons
- [ ] Modal for modifying existing route:
  - [ ] Same configuration options
  - [ ] "Save Changes" and "Cancel" buttons

#### B4.3 Trade notifications
- [ ] Notification when route is established
- [ ] Notification when exchange completes
- [ ] Notification when partner discovered
- [ ] Warning when exports can't be fulfilled

---

## Phase C: Polish & Testing

### C1. Narrative Events [MEDIUM]

#### C1.1 Create event scheduling system
- [ ] `ScheduleEvent(eventId, cyclesInFuture)` function
- [ ] Store scheduled events with trigger cycle
- [ ] Process scheduled events in game update loop
- [ ] Display event modals when triggered

#### C1.2 Create era-specific events
- [ ] Settlement events:
  - [ ] "first_harvest" - triggered on first wheat production
  - [ ] "hungry_week" - triggered on food shortage
  - [ ] "first_death" - triggered on first citizen death
- [ ] Village events:
  - [ ] "bandit_scare" - scheduled at cycle 10
  - [ ] "tailor_arrival" - immigration event
  - [ ] "first_wedding" - triggered on marriage
- [ ] Town events:
  - [ ] "traveling_scholar" - scheduled event
  - [ ] "religious_festival" - annual event
  - [ ] "founder_death" - Kamala's death
- [ ] City events:
  - [ ] "trade_emissary" - scheduled at era entry + 5 cycles
  - [ ] "class_conflict" - triggered by high inequality
- [ ] Metropolis events:
  - [ ] "exotic_merchants" - scheduled at era entry
  - [ ] "vice_proposal" - triggered by gold threshold

#### C1.3 Create event data structure
- [ ] Create `data/alpha/narrative/era_events.json`
- [ ] Define event triggers, text, choices, consequences
- [ ] Create `code/NarrativeSystem.lua` for event management

---

### C2. Visual & Audio Polish [LOW]

#### C2.1 Era transition effects
- [ ] Add celebration particles on era advancement
- [ ] Add sound effect for era transition
- [ ] Smooth fade animations for modal

#### C2.2 Trade visual feedback
- [ ] Caravan animation during establishment (optional)
- [ ] Trade exchange success notification
- [ ] Trade balance indicator (+/- gold per cycle)

---

### C3. Testing [HIGH]

#### C3.1 Era progression testing
- [ ] Test Settlement start with only biological cravings
- [ ] Test Settlement → Village transition at 15 pop, 45% sat
- [ ] Test sustained cycles requirement (must hold 20 cycles)
- [ ] Test Village → Town transition with building requirements
- [ ] Test Town → City transition with elite population check
- [ ] Test City → Metropolis transition with trade route requirement
- [ ] Test all narrative events trigger correctly
- [ ] Test Classic mode starts at Metropolis with everything unlocked

#### C3.2 Craving filtering testing
- [ ] Verify only enabled cravings are allocated
- [ ] Verify satisfaction calculations use only enabled cravings
- [ ] Verify no null/crash errors with disabled cravings
- [ ] Verify UI only shows enabled craving bars

#### C3.3 Time slot testing
- [ ] Verify 3-slot mode works in Settlement/Village
- [ ] Verify transition to 6-slot mode at Town era
- [ ] Verify cravings map correctly between slot modes
- [ ] Verify no allocation issues during transition

#### C3.4 Building filtering testing
- [ ] Verify only enabled buildings appear in menu
- [ ] Verify building count increases each era
- [ ] Verify can still access buildings from previous eras

#### C3.5 Trade system testing
- [ ] Test partner discovery at City era
- [ ] Test route establishment (gold deduction, countdown)
- [ ] Test exchange mechanics (export/import)
- [ ] Test AI pricing with different personalities
- [ ] Test Metropolis unlock with active trade route
- [ ] Test save/load preserves trade state

#### C3.6 Save/Load testing
- [ ] Test save includes era state
- [ ] Test load restores correct era
- [ ] Test migration from old saves (default to Settlement)
- [ ] Test trade routes persist across save/load

---

### C4. Documentation [LOW]

#### C4.1 Update project documentation
- [ ] Update CLAUDE.md with era system overview
- [ ] Update STRUCTURE.md with new files

#### C4.2 Create player documentation
- [ ] Write era progression guide
- [ ] Write trade system tutorial
- [ ] Document unlock requirements

---

## Summary Checklist

### Phase A Deliverables
- [ ] `data/alpha/eras.json` - Complete
- [ ] `data/alpha/craving_slots.json` - Updated with simple_slots
- [ ] `code/EraSystem.lua` - Complete with all methods
- [ ] `code/ui/EraTransitionModal.lua` - Complete
- [ ] `code/ui/EraProgressIndicator.lua` - Optional
- [ ] AllocationEngineV2.lua modifications - Complete
- [ ] BuildingMenu.lua modifications - Complete
- [ ] CitizenPanel.lua modifications - Complete
- [ ] AlphaPrototypeState.lua modifications - Complete
- [ ] NewGameSetup.lua modifications - Complete

### Phase B Deliverables
- [ ] `data/alpha/trade/trade_partners.json` - Complete
- [ ] `data/alpha/trade/trade_config.json` - Complete
- [ ] `code/TradeSystem.lua` - Complete
- [ ] `code/ui/TradePanel.lua` - Complete
- [ ] `code/ui/TradeRouteModal.lua` - Complete
- [ ] Trade system integration with AlphaPrototypeState - Complete
- [ ] Trade system integration with EraSystem - Complete

### Phase C Deliverables
- [ ] Narrative event system - Complete
- [ ] All era events implemented - Complete
- [ ] Visual polish - Complete
- [ ] All testing passed - Complete
- [ ] Documentation updated - Complete

---

## Estimated Effort

| Phase | Tasks | Complexity | Notes |
|-------|-------|------------|-------|
| A1-A2 | Data + Core EraSystem | Medium | Foundation work |
| A3-A5 | Unlock logic + Save/Load | Medium | Core mechanics |
| A6-A9 | Integration | High | Multiple file modifications |
| A10-A11 | UI + Classic mode | Low-Medium | Polish |
| B1-B2 | Trade data + core | Medium-High | New system |
| B3-B4 | Trade integration + UI | Medium | Integration work |
| C1-C4 | Polish + Testing | Medium | Quality assurance |

**Recommended approach:** Complete Phase A fully before starting Phase B. Trade system depends on Era system being stable.
