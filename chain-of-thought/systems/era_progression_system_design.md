# Era Progression System Design

**Created:** 2025-01-22
**Status:** Design Complete
**Related Documents:**
- [Consumption System Architecture](consumption_system_architecture_v2.md)
- [Immigration Design](phase9_immigration_design.md)
- [Marketplace Economy Design](marketplace_economy_design.md)
- [Specialized Starting Towns](specialized_starting_towns_design.md)

---

## Executive Summary

The Era Progression System introduces **progressive complexity** to Cravetown by gating craving categories, buildings, and mechanics behind 5 town eras. Players start with only biological cravings (food, water, rest) and gradually unlock safety, comfort, social, and luxury needs as their town grows. This follows Maslow's hierarchy and reduces cognitive overload for new players.

---

## 1. Problem Statement

### 1.1 Current State Issues

The current game throws **all 10 craving categories** at the player immediately:
- Biological, Safety, Touch, Psychological, Social Status, Social Connection, Exotic Goods, Shiny Objects, Vice, Utility

With **6 time slots** and **66 fine-grained cravings**, this creates massive cognitive overload:

1. **Too Many Variables at Once**: 10 categories × 6 time slots × 5 classes = overwhelming
2. **No Mental Model Building**: Players can't form intuition about one system before another is introduced
3. **Feedback Loop Confusion**: Hard to diagnose why satisfaction is dropping when 10+ factors are at play
4. **Analysis Paralysis**: Too many buildings to choose from, too many cravings to track

### 1.2 Design Goals

1. **Maslow Before Mechanics**: Start with survival (biological), then safety, then higher needs
2. **One System at a Time**: Introduce new complexity only after player demonstrates mastery
3. **Clear Cause-Effect**: When something new is introduced, it should have obvious impact
4. **Opt-in Complexity**: Advanced players can accelerate; new players get guided pace
5. **Natural Narrative**: Progression should feel like town evolution, not arbitrary unlocks

---

## 2. Era System Overview

### 2.1 The Five Eras

| Era | Name | Cravings Active | Time Slots | Unlock Trigger |
|-----|------|-----------------|------------|----------------|
| 1 | **Settlement** | Biological | 3 (simple) | Game start |
| 2 | **Village** | + Safety, Touch | 3 (simple) | 15 pop, 45% sat, 20 cycles |
| 3 | **Town** | + Psychological, Social Connection | 6 (full) | 35 pop, 50% sat, buildings |
| 4 | **City** | + Social Status, Utility | 6 (full) | 75 pop, 3000 gold, 5% elite |
| 5 | **Metropolis** | + Exotic, Shiny, Vice | 6 (full) | 150 pop, 10000 gold, 1 trade route |

### 2.2 Era State Machine

```
┌─────────────┐    population>=15     ┌─────────────┐    population>=35     ┌─────────────┐
│  SETTLEMENT │    satisfaction>=45   │   VILLAGE   │    satisfaction>=50   │    TOWN     │
│   (Era 1)   │────sustain 20 cycles──│   (Era 2)   │────buildings built────│   (Era 3)   │
└─────────────┘                       └─────────────┘                       └─────────────┘
                                                                                   │
      ┌────────────────────────────────────────────────────────────────────────────┘
      │
      │    population>=75            ┌─────────────┐    population>=150     ┌─────────────┐
      │    treasury>=3000            │    CITY     │    treasury>=10000     │ METROPOLIS  │
      └────5% elite population───────│   (Era 4)   │────active trade route──│   (Era 5)   │
                                     └─────────────┘                        └─────────────┘
```

### 2.3 Craving Category Distribution by Era

| Category | Tier | Era Unlocked | Rationale |
|----------|------|--------------|-----------|
| `biological` | Survival | Settlement (1) | Core survival - food, water, rest |
| `safety` | Security | Village (2) | Protection becomes concern with growth |
| `touch` | Comfort | Village (2) | Clothing/comfort after basic survival |
| `psychological` | Social-Psychological | Town (3) | Education, meaning, faith |
| `social_connection` | Social-Psychological | Town (3) | Community bonds, friendship |
| `social_status` | Social-Psychological | City (4) | Class distinctions, prestige |
| `utility` | Special | City (4) | Tools, practical goods for industry |
| `exotic_goods` | Aspirational | Metropolis (5) | Foreign luxuries via trade |
| `shiny_objects` | Aspirational | Metropolis (5) | Gems, precious metals |
| `vice` | Special | Metropolis (5) | Entertainment, indulgence |

---

## 3. Detailed Era Specifications

### 3.1 Era 1: Settlement

**Theme:** Survival against nature and starvation

**Active Cravings:** Biological only
- `biological_nutrition_grain`
- `biological_nutrition_protein`
- `biological_nutrition_produce`
- `biological_hydration`
- `biological_health_medicine`
- `biological_health_hygiene`
- `biological_energy_rest`
- `biological_energy_stimulation`

**Available Buildings:**
- Farm
- Well
- Bakery
- Lodge
- Sawmill
- Granary

**Time Slot Mode:** Simple (3 slots)
- Morning (5am-5pm) - combines early_morning, morning, afternoon
- Evening (5pm-9pm) - evening only
- Night (9pm-5am) - combines night, late_night

**Unlock Conditions:** Auto (game start)

**Narrative Event:**
> "A New Beginning"
> Your settlers have arrived. Keep them fed and sheltered to survive.

**Player Experience:**
- Simple feedback loop: "Citizens are hungry → build farm → citizens happy"
- Only 3-4 craving bars visible per citizen
- Tutorial focuses entirely on food production chain

---

### 3.2 Era 2: Village

**Theme:** Building community, facing external threats

**New Cravings:** Safety + Touch
- `safety_security_law`
- `safety_security_defense`
- `safety_shelter_housing`
- `safety_shelter_warmth`
- `touch_clothing_everyday`
- `touch_clothing_work`
- `touch_furniture_comfort`
- `touch_furniture_sleep`

**New Buildings:**
- Guard Post
- Tailor
- Carpenter
- Smithy
- Warehouse

**Time Slot Mode:** Simple (3 slots)

**Unlock Conditions:**
- Population >= 15
- Average satisfaction >= 45%
- Sustained for 20 cycles

**Narrative Event:**
> "Growing Pains"
> As your settlement grows, citizens worry about safety and comfort.
> Wild animals have been spotted nearby...

**Player Experience:**
- Safety bar appears on citizens
- Guard Post provides area-of-effect safety satisfaction
- Clothing becomes important (Touch category)
- Citizens now have 5-6 visible craving bars

---

### 3.3 Era 3: Town

**Theme:** Cultural development, community building

**New Cravings:** Psychological + Social Connection
- `psychological_education_books`
- `psychological_education_training`
- `psychological_meaning_religion`
- `psychological_meaning_purpose`
- `psychological_entertainment_arts`
- `psychological_entertainment_games`
- `social_connection_family`
- `social_connection_friendship`
- `social_connection_community`

**New Buildings:**
- School
- Temple
- Tavern
- Library
- Hospital

**Time Slot Mode:** Full (6 slots) - complexity increases

**Unlock Conditions:**
- Population >= 35
- Average satisfaction >= 50%
- Required buildings: guard_post, tailor

**Narrative Event:**
> "A Place to Call Home"
> Your village thrives! Citizens now seek meaning, knowledge, and community bonds.

**Player Experience:**
- Psychological needs emerge (education, spiritual fulfillment)
- Social connection becomes important (friendship, community)
- Time slots expand to full 6 - more temporal complexity
- Class differences start mattering more

---

### 3.4 Era 4: City

**Theme:** Trade relations, class conflict, economic growth

**New Cravings:** Social Status + Utility
- `status_prestige_housing`
- `status_prestige_clothing`
- `status_prestige_position`
- `status_wealth_precious`
- `status_wealth_display`
- `utility_tools_crafting`
- `utility_tools_farming`
- `utility_equipment_work`

**New Buildings:**
- Bank
- Workshop
- Manor
- Courthouse
- Depot

**Time Slot Mode:** Full (6 slots)

**Unlock Conditions:**
- Population >= 75
- Treasury >= 3000 gold
- Elite/Upper population >= 5%

**Narrative Event:**
> "Rise of the Elite"
> Wealth accumulates and class distinctions emerge.
> The ambitious seek status and prestige.

**Player Experience:**
- Status symbols matter (housing quality, clothing tiers)
- Elite class citizens emerge or immigrate
- Tool quality affects production efficiency
- **TRADE SYSTEM UNLOCKS** - can establish routes with other towns

---

### 3.5 Era 5: Metropolis

**Theme:** Managing prosperity, luxury, and vice

**New Cravings:** Exotic Goods + Shiny Objects + Vice
- `exotic_food_delicacies`
- `exotic_food_imported`
- `exotic_goods_spices`
- `exotic_goods_materials`
- `shiny_precious_metals`
- `shiny_precious_gems`
- `shiny_decorative_objects`
- `vice_intoxicants_alcohol`
- `vice_intoxicants_tobacco`
- `vice_gambling`
- `vice_indulgence`

**New Buildings:**
- Market
- Jeweler
- Brewery
- Theater
- Casino

**Time Slot Mode:** Full (6 slots)

**Unlock Conditions:**
- Population >= 150
- Treasury >= 10000 gold
- Active trade routes >= 1

**Narrative Event:**
> "Cosmopolitan Dreams"
> Your city's fame spreads far! Exotic merchants arrive with rare goods,
> and citizens develop... refined tastes.

**Player Experience:**
- Full craving system active (all 10 categories)
- Luxury economy emerges
- Vice management becomes a factor
- Trade networks for exotic goods
- Full game complexity unlocked

---

## 4. Time Slot Simplification

### 4.1 Slot Mapping

**Full Mode (6 slots):**
```
early_morning (5am-8am)
morning (8am-12pm)
afternoon (12pm-5pm)
evening (5pm-9pm)
night (9pm-12am)
late_night (12am-5am)
```

**Simple Mode (3 slots):**
```
morning (5am-5pm)    ← combines early_morning, morning, afternoon
evening (5pm-9pm)    ← evening only
night (9pm-5am)      ← combines night, late_night
```

### 4.2 Craving Slot Mapping

Each craving needs both `slots` (full mode) and `simple_slots` (simple mode):

```json
{
  "biological_nutrition_grain": {
    "slots": ["early_morning", "afternoon", "evening"],
    "simple_slots": ["morning", "evening"],
    "frequencyPerDay": 3
  },
  "biological_hydration": {
    "slots": ["early_morning", "morning", "afternoon", "evening", "night"],
    "simple_slots": ["morning", "evening", "night"],
    "frequencyPerDay": 5
  },
  "biological_energy_rest": {
    "slots": ["late_night"],
    "simple_slots": ["night"],
    "frequencyPerDay": 1
  }
}
```

### 4.3 Slot Selection Algorithm

```lua
function GetActiveCravingsForSlot(character, currentSlot, eraTimeSlotMode)
    local activeCravings = {}

    -- Determine which slot to check based on era mode
    local slotToCheck = currentSlot
    if eraTimeSlotMode == "simple" then
        slotToCheck = GetSimplifiedSlot(currentSlot)
    end

    for cravingId, cravingDef in pairs(CravingSlots) do
        -- Check if craving category is enabled in current era
        local category = GetCravingCategory(cravingId)
        if EraSystem:IsCravingCategoryEnabled(category) then
            -- Get appropriate slot list
            local activeSlots = eraTimeSlotMode == "simple"
                and cravingDef.simple_slots
                or cravingDef.slots

            if table.contains(activeSlots, slotToCheck) then
                table.insert(activeCravings, cravingId)
            end
        end
    end

    return activeCravings
end

function GetSimplifiedSlot(fullSlot)
    local mapping = {
        early_morning = "morning",
        morning = "morning",
        afternoon = "morning",
        evening = "evening",
        night = "night",
        late_night = "night"
    }
    return mapping[fullSlot]
end
```

---

## 5. Building Unlock System

### 5.1 Building Accumulation

Buildings unlock cumulatively - each era adds new options without removing previous ones:

```lua
function EraSystem:GetAllEnabledBuildings()
    local enabled = {}

    -- Accumulate buildings from all eras up to current
    for i = 1, self.currentEra.order do
        local era = self.eras[i]
        for _, buildingId in ipairs(era.enabled_buildings) do
            enabled[buildingId] = true
        end
    end

    return enabled
end
```

### 5.2 Building Distribution

| Era | Cumulative Building Count | New Buildings |
|-----|---------------------------|---------------|
| Settlement | 6 | Farm, Well, Bakery, Lodge, Sawmill, Granary |
| Village | 11 | +Guard Post, Tailor, Carpenter, Smithy, Warehouse |
| Town | 16 | +School, Temple, Tavern, Library, Hospital |
| City | 21 | +Bank, Workshop, Manor, Courthouse, Depot |
| Metropolis | 26 | +Market, Jeweler, Brewery, Theater, Casino |

### 5.3 Building Menu Integration

```lua
function BuildingMenu:GetAvailableBuildings()
    local available = {}

    for _, building in ipairs(AllBuildingTypes) do
        if EraSystem:IsBuildingEnabled(building.id) then
            building.canAfford = townState.gold >= building.constructionCost
            table.insert(available, building)
        end
    end

    -- Sort by category or era order
    table.sort(available, function(a, b)
        return a.eraOrder < b.eraOrder
    end)

    return available
end
```

---

## 6. Era Transition Algorithm

### 6.1 Condition Checking

```lua
function EraSystem:CheckUnlockConditions(townState)
    local currentEra = self.currentEra
    local nextEra = self:GetNextEra()
    if not nextEra then return false, {} end  -- Already at Metropolis

    local conditions = nextEra.unlock_conditions
    local allMet = true
    local progress = {}

    -- Population check
    if conditions.population then
        local pop = #townState.citizens
        progress.population = { current = pop, required = conditions.population }
        if pop < conditions.population then allMet = false end
    end

    -- Satisfaction check
    if conditions.min_avg_satisfaction then
        local avgSat = self:CalculateAverageSatisfaction(townState)
        progress.satisfaction = { current = avgSat, required = conditions.min_avg_satisfaction }
        if avgSat < conditions.min_avg_satisfaction then allMet = false end
    end

    -- Sustained cycles check
    if conditions.sustained_cycles then
        if self.sustainedCycles < conditions.sustained_cycles then
            allMet = false
        end
        progress.sustained = { current = self.sustainedCycles, required = conditions.sustained_cycles }
    end

    -- Treasury check
    if conditions.min_treasury then
        local gold = townState.gold
        progress.treasury = { current = gold, required = conditions.min_treasury }
        if gold < conditions.min_treasury then allMet = false end
    end

    -- Required buildings check
    if conditions.required_buildings then
        local missingBuildings = {}
        for _, buildingType in ipairs(conditions.required_buildings) do
            if not self:HasBuilding(townState, buildingType) then
                allMet = false
                table.insert(missingBuildings, buildingType)
            end
        end
        progress.buildings = { missing = missingBuildings }
    end

    -- Elite population check
    if conditions.elite_population_percent then
        local elitePercent = self:GetElitePopulationPercent(townState)
        progress.elite = { current = elitePercent, required = conditions.elite_population_percent }
        if elitePercent < conditions.elite_population_percent then allMet = false end
    end

    -- Trade routes check
    if conditions.active_trade_routes then
        local routes = TradeSystem:GetActiveRouteCount()
        progress.trade = { current = routes, required = conditions.active_trade_routes }
        if routes < conditions.active_trade_routes then allMet = false end
    end

    return allMet, progress
end
```

### 6.2 Sustained Cycles Tracking

```lua
function EraSystem:Update(townState, dt)
    local conditionsMet, progress = self:CheckUnlockConditions(townState)

    if conditionsMet then
        -- Increment sustained counter
        self.sustainedCycles = self.sustainedCycles + 1

        -- Check if sustained requirement is met
        local nextEra = self:GetNextEra()
        local requiredSustain = nextEra.unlock_conditions.sustained_cycles or 0

        if self.sustainedCycles >= requiredSustain then
            self:AdvanceEra()
        end
    else
        -- Reset sustained counter if conditions no longer met
        self.sustainedCycles = 0
    end
end
```

### 6.3 Era Advancement

```lua
function EraSystem:AdvanceEra()
    local nextEra = self:GetNextEra()
    if not nextEra then return end

    -- Update current era
    local previousEra = self.currentEra
    self.currentEra = nextEra
    self.sustainedCycles = 0

    -- Record in unlock history
    table.insert(self.unlockHistory, {
        era = nextEra.id,
        timestamp = os.time(),
        cycle = GameState.currentCycle
    })

    -- Trigger narrative event
    self:TriggerNarrativeEvent(nextEra.narrative_event)

    -- Notify listeners
    self:NotifyListeners("era_advanced", {
        previous = previousEra,
        current = nextEra,
        newCravings = self:GetNewCravingCategories(previousEra, nextEra),
        newBuildings = self:GetNewBuildings(previousEra, nextEra)
    })
end
```

---

## 7. Classic Mode (Sandbox)

### 7.1 Purpose

For veteran players who want full complexity from the start:
- All eras unlocked immediately
- All buildings available
- All craving categories active
- Full 6 time slots
- Trade system available from start

### 7.2 Implementation

```lua
function EraSystem:Init(configPath, isClassicMode)
    -- Load era configuration
    self.eras = self:LoadConfig(configPath)

    if isClassicMode then
        -- Start at final era
        self.currentEra = self:GetFinalEra()  -- Metropolis
        self.isClassicMode = true
    else
        -- Start at first era
        self.currentEra = self:GetFirstEra()  -- Settlement
        self.isClassicMode = false
    end

    self.sustainedCycles = 0
    self.unlockHistory = {}
end
```

### 7.3 UI Integration

Add to NewGameSetup difficulty options:
```
Difficulty: Classic
Description: "All craving categories, buildings, and trade systems unlocked
from the start. For experienced players who want full complexity."
```

---

## 8. Save/Load Integration

### 8.1 Save Data Structure

```lua
function EraSystem:GetSaveData()
    return {
        currentEraId = self.currentEra.id,
        sustainedCycles = self.sustainedCycles,
        unlockHistory = self.unlockHistory,
        isClassicMode = self.isClassicMode
    }
end
```

### 8.2 Load Data

```lua
function EraSystem:LoadSaveData(data)
    if data then
        -- Find era by ID
        self.currentEra = self:GetEraById(data.currentEraId)
        self.sustainedCycles = data.sustainedCycles or 0
        self.unlockHistory = data.unlockHistory or {}
        self.isClassicMode = data.isClassicMode or false
    else
        -- Migration: Old save without era data
        -- Default to Settlement era
        self.currentEra = self:GetFirstEra()
        self.sustainedCycles = 0
        self.unlockHistory = {}
        self.isClassicMode = false
    end
end
```

---

## 9. Integration Points

### 9.1 AllocationEngineV2

- Filter cravings by `EraSystem:IsCravingCategoryEnabled(category)`
- Use `EraSystem:GetTimeSlotMode()` for slot simplification

### 9.2 BuildingMenu

- Filter buildings by `EraSystem:IsBuildingEnabled(buildingType)`

### 9.3 CitizenPanel

- Only show craving bars for enabled categories
- Adapt satisfaction display to era

### 9.4 AlphaPrototypeState

- Initialize EraSystem on game start
- Call `EraSystem:Update()` each cycle
- Include era data in save/load

### 9.5 TradeSystem

- Only available in City era (Era 4) and later
- Provides `GetActiveRouteCount()` for Metropolis unlock condition

---

## 10. Data Configuration

### 10.1 eras.json Structure

```json
{
  "eras": [
    {
      "id": "settlement",
      "name": "Settlement",
      "order": 1,
      "enabled_craving_categories": ["biological"],
      "enabled_buildings": ["farm", "well", "bakery", "lodge", "sawmill", "granary"],
      "time_slot_mode": "simple",
      "unlock_conditions": { "auto": true },
      "narrative_event": {
        "title": "A New Beginning",
        "description": "Your settlers have arrived. Keep them fed and sheltered to survive."
      }
    }
  ],
  "time_slot_modes": {
    "simple": {
      "slots": ["morning", "evening", "night"],
      "mapping": {
        "morning": ["early_morning", "morning", "afternoon"],
        "evening": ["evening"],
        "night": ["night", "late_night"]
      }
    },
    "full": {
      "slots": ["early_morning", "morning", "afternoon", "evening", "night", "late_night"]
    }
  }
}
```

---

## 11. Files to Create/Modify

### New Files
| File | Purpose |
|------|---------|
| `data/alpha/eras.json` | Era definitions and configuration |
| `code/EraSystem.lua` | Core era progression logic |
| `code/ui/EraTransitionModal.lua` | Era advancement UI |
| `code/ui/EraProgressIndicator.lua` | HUD progress display |

### Modified Files
| File | Changes |
|------|---------|
| `code/AlphaPrototypeState.lua` | Initialize/update EraSystem |
| `code/consumption/AllocationEngineV2.lua` | Filter cravings by era |
| `code/BuildingMenu.lua` | Filter buildings by era |
| `code/ui/CitizenPanel.lua` | Filter craving bars |
| `code/NewGameSetup.lua` | Add Classic difficulty |
| `data/alpha/craving_slots.json` | Add simple_slots mappings |

---

## Appendix A: Craving Category Reference

| ID | Name | Tier | Era | Index |
|----|------|------|-----|-------|
| `biological` | Biological | survival | 1 | 0 |
| `safety` | Safety | security | 2 | 1 |
| `touch` | Touch | comfort | 2 | 2 |
| `psychological` | Psychological | social_psychological | 3 | 3 |
| `social_connection` | Social Connection | social_psychological | 3 | 5 |
| `social_status` | Social Status | social_psychological | 4 | 4 |
| `utility` | Utility | special | 4 | 9 |
| `exotic_goods` | Exotic Goods | aspirational | 5 | 6 |
| `shiny_objects` | Shiny Objects | aspirational | 5 | 7 |
| `vice` | Vice | special | 5 | 8 |
