# Consumption Prototype - Comprehensive Design Document
**CraveTown: Prototype 1 - Character Behavior & Resource Allocation**

Version 1.0 | November 2025

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Core Loop & Game Flow](#core-loop--game-flow)
3. [UI/UX Design Philosophy](#uiux-design-philosophy)
4. [Screen-by-Screen Layout](#screen-by-screen-layout)
5. [Character System Design](#character-system-design)
6. [Craving & Satisfaction Mechanics](#craving--satisfaction-mechanics)
7. [Resource Injection System](#resource-injection-system)
8. [Allocation Algorithm](#allocation-algorithm)
9. [Substitution System](#substitution-system)
10. [Consequence System](#consequence-system)
11. [Analytics & Visualization](#analytics--visualization)
12. [Enhancement Ideas](#enhancement-ideas)
13. [Implementation Roadmap](#implementation-roadmap)

---

## Executive Summary

### What We're Building
A **standalone consumption simulator** where players:
- **Create & manage characters** with unique traits and class backgrounds
- **Watch cravings decay** in real-time across 7 craving dimensions
- **Control resource supply** through a commodity injection panel
- **Observe allocation decisions** as characters compete for resources
- **Analyze satisfaction patterns** through rich data visualizations
- **Experience consequences** when satisfaction drops (emigration, riots, decay)

### Design Philosophy
**"Make the invisible visible"** - Turn abstract systems (satisfaction, substitution, allocation) into tangible, observable, manipulable experiences.

**Key Principles:**
1. **Transparency Over Mystery** - Show all calculations, don't hide the math
2. **Control Through Experimentation** - Let players inject scenarios and see outcomes
3. **Data-Driven Storytelling** - Characters are data entities, but tell human stories
4. **Rapid Iteration** - Change parameters and instantly see results

---

## Core Loop & Game Flow

### The 60-Second Cycle

```
┌─────────────────────────────────────────────────────────┐
│                    CONSUMPTION CYCLE                     │
│                      (60 seconds)                        │
│                                                          │
│  ①  DECAY PHASE              (0-10s)                    │
│     • All cravings decay by configured rate             │
│     • Visual: Character cards pulse red on critical     │
│     • Audio: Subtle warning sounds for <20 satisfaction │
│                                                          │
│  ②  ALLOCATION PHASE         (10-40s)                   │
│     • Characters sorted by priority (class + desperation)│
│     • Sequential allocation with substitution attempts  │
│     • Visual: Resources "flow" from inventory to chars  │
│     • Audio: Satisfaction "ding" on successful fulfill  │
│                                                          │
│  ③  CONSEQUENCE PHASE        (40-55s)                   │
│     • Check emigration triggers (<30 for 3 cycles)      │
│     • Check riot conditions (town avg <20)              │
│     • Apply satisfaction effects to productivity        │
│     • Visual: Characters leave/riot animations          │
│                                                          │
│  ④  REPORTING PHASE          (55-60s)                   │
│     • Update all analytics dashboards                   │
│     • Log events to history                             │
│     • Save state snapshot                               │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Player Intervention Points

Players can interact **at any time**, not just between cycles:

- **Pause/Resume** - Freeze the simulation to inspect state
- **Speed Control** - 0.5x, 1x, 2x, 5x, 10x speed
- **Inject Resources** - Add commodities instantly to inventory
- **Spawn Characters** - Add new characters with custom traits
- **Delete Characters** - Remove characters from simulation
- **Modify Cravings** - Directly edit satisfaction levels (for testing)
- **Trigger Events** - Force emigration, riots, or enablements

---

## UI/UX Design Philosophy

### Visual Language

**Color System:**
```
Satisfaction Levels:
├─ 80-100: Vibrant Green    (thriving)
├─ 60-79:  Light Green      (comfortable)
├─ 40-59:  Yellow           (coping)
├─ 20-39:  Orange           (stressed)
└─ 0-19:   Red              (critical)

Character Classes:
├─ Elite:       Deep Purple  (#7B2CBF)
├─ Upper:       Royal Blue   (#1E88E5)
├─ Middle:      Forest Green (#43A047)
└─ Lower:       Warm Brown   (#8D6E63)

Craving Types:
├─ Biological:    Red        (life-critical)
├─ Touch:         Blue       (comfort)
├─ Psychological: Purple     (mental)
├─ Safety:        Gray       (security)
├─ Social Status: Gold       (prestige)
├─ Exotic Goods:  Orange     (luxury)
└─ Shiny Objects: Silver     (material)
```

**Typography:**
- **Headers:** 24-32px, Bold, Sans-Serif (e.g., Roboto Condensed)
- **Body:** 14-16px, Regular, Sans-Serif
- **Data:** 12-14px, Monospace (for numbers, perfect alignment)
- **Labels:** 11-12px, Uppercase, Tracking +1px

**Layout Principles:**
1. **Left Panel** - Control & Input (Resource Injection, Simulation Controls)
2. **Center** - Main View (Character Grid, Analytics)
3. **Right Panel** - Information & Details (Selected Character, Stats)
4. **Bottom Bar** - Timeline, Cycle Counter, Global Stats

---

## Screen-by-Screen Layout

### 🏠 Main View: "Character Grid"

**Primary Screen - 80% of gameplay time**

```
┌────────────────────────────────────────────────────────────────────────┐
│  🎛️ CONTROLS                CRAVETOWN CONSUMPTION PROTOTYPE     ℹ️ INFO │
│                                                                         │
│  [▶ Pause] [⏩ 2x]  Cycle: 47  Time: 00:47  Pop: 50  Avg Sat: 62%     │
├─────────────────┬───────────────────────────────────────┬──────────────┤
│                 │                                       │              │
│ 📦 RESOURCES    │      🧍 CHARACTER GRID (50)          │ 📊 SELECTED  │
│                 │                                       │              │
│ Quick Inject:   │  ┌──────┐ ┌──────┐ ┌──────┐        │ John Smith   │
│                 │  │ ELITE│ │UPPER │ │MIDDLE│        │ Middle Class │
│ [+10 Wheat]     │  │ Anna │ │ Tom  │ │ John │        │ Baker        │
│ [+10 Bread]     │  │ 78%  │ │ 65%  │ │ 52%  │        │              │
│ [+5 Cloth]      │  └──────┘ └──────┘ └──────┘        │ 🔴 Bio: 45%  │
│ [+5 Books]      │                                      │ 🔵 Touch: 60%│
│                 │  ┌──────┐ ┌──────┐ ┌──────┐        │ 🟣 Psych: 30%│
│ Custom Inject:  │  │LOWER │ │LOWER │ │MIDDLE│        │ ⚪ Safe: 55%│
│ [Commodity ▼]   │  │ Mary │ │ Bob  │ │ Sue  │        │ 🟡 Status:20%│
│ [Qty: ___]      │  │ 42%  │ │ 38%  │ │ 61%  │        │ 🟠 Exotic:10%│
│ [Inject]        │  └──────┘ └──────┘ └──────┘        │ ⚪ Shiny: 15%│
│                 │                                       │              │
│ 🏃 CHARACTER    │  Grid continues...                    │ Inventory:   │
│                 │  (5x10 = 50 characters)              │ Wheat: 3     │
│ [+ Add Elite]   │                                       │ Bread: 1     │
│ [+ Add Upper]   │  [Sort: Priority ▼]                  │ Cloth: 0     │
│ [+ Add Middle]  │  [Filter: All ▼]                     │              │
│ [+ Add Lower]   │  [View: Cards ▼]                     │ Actions:     │
│ [+ Random 10]   │                                       │ [Delete]     │
│                 │                                       │ [Edit Cravings]
│ 🎯 SCENARIOS    │                                       │ [Full History]
│                 │                                       │              │
│ [Famine]        │                                       │              │
│ [Abundance]     │                                       │              │
│ [Class War]     │                                       │              │
│ [Reset All]     │                                       │              │
│                 │                                       │              │
└─────────────────┴───────────────────────────────────────┴──────────────┘
│  📈 TIMELINE: [▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 47/100       │
│  Avg Satisfaction:  [▓▓▓▓▓▓▓░░░] 62%    Riots: 0   Emigrations: 3    │
└─────────────────────────────────────────────────────────────────────────┘
```

**Character Card Detail (Hover Tooltip):**
```
┌──────────────────────────────┐
│ John Smith                   │
│ Middle Class | Baker         │
│ Traits: Ambitious, Frugal    │
├──────────────────────────────┤
│ 🔴 Biological:      45% ▼-2  │
│ 🔵 Touch:           60% ▲+1  │
│ 🟣 Psychological:   30% ▼-3  │
│ ⚪ Safety:          55% →0   │
│ 🟡 Social Status:   20% ▼-5  │
│ 🟠 Exotic Goods:    10% ▼-1  │
│ ⚪ Shiny Objects:   15% ▼-2  │
├──────────────────────────────┤
│ Priority Score: 342          │
│ Next in Queue: #12           │
│ Last Allocated: Cycle 45     │
│ Allocation Success: 65%      │
└──────────────────────────────┘
```

---

### 📊 Analytics View: "Craving Heatmap"

**Toggle from Main View with [Tab] key**

```
┌─────────────────────────────────────────────────────────────────────────┐
│  📊 ANALYTICS: CRAVING HEATMAP                          [Back to Grid]  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Filter: [All Classes ▼]  [All Vocations ▼]  Sort: [Avg Satisfaction]  │
│                                                                          │
│  Character    Class    Bio  Touch Psych Safe Stat Exotic Shiny  Avg    │
│  ────────────────────────────────────────────────────────────────────   │
│  Anna Elite   ELITE    █92  █88   █85   █90  █95  █82    █88   89%    │
│  Tom Baker    UPPER    ▓78  ▓65   ▓70   ▓72  ▓60  ▓55    ▓58   65%    │
│  John Smith   MIDDLE   ▒45  ▓60   ▒30   ▓55  ▒20  ▒10    ▒15   34%    │
│  Mary Cook    LOWER    ▒38  ▒42   ▒25   ▒48  ░12  ░5     ░8    25%    │
│  Bob Miner    LOWER    ░15  ▒35   ░18   ▒40  ░8   ░3     ░5    18%    │
│  ...                                                                     │
│  (50 rows total)                                                        │
│                                                                          │
│  █ = 80-100%  ▓ = 60-79%  ▒ = 40-59%  ░ = 20-39%  ░ = 0-19%           │
│                                                                          │
├─────────────────────────────────────────────────────────────────────────┤
│  AGGREGATE STATISTICS                                                   │
│                                                                          │
│  Average by Craving:                                                    │
│  🔴 Biological:    [▓▓▓▓▓▓▓░░░] 67%    (Critical Count: 5)            │
│  🔵 Touch:         [▓▓▓▓▓░░░░░] 55%    (Critical Count: 12)           │
│  🟣 Psychological: [▒▒▒▒░░░░░░] 42%    (Critical Count: 18)           │
│  ⚪ Safety:        [▓▓▓▓▓▓░░░░] 61%    (Critical Count: 8)            │
│  🟡 Social Status: [▒▒▒░░░░░░░] 35%    (Critical Count: 22)           │
│  🟠 Exotic Goods:  [▒▒░░░░░░░░] 28%    (Critical Count: 28)           │
│  ⚪ Shiny Objects: [▒▒░░░░░░░░] 25%    (Critical Count: 30)           │
│                                                                          │
│  Average by Class:                                                      │
│  Elite:        [█████████░] 87%    Upper:  [▓▓▓▓▓▓▓░░░] 68%           │
│  Middle Class: [▒▒▒▒▒░░░░░] 52%    Lower:  [▒▒▒░░░░░░░] 34%           │
└─────────────────────────────────────────────────────────────────────────┘
```

---

### 📦 Allocation Log View: "Who Got What"

**Real-time allocation tracking**

```
┌─────────────────────────────────────────────────────────────────────────┐
│  📦 ALLOCATION LOG - Cycle 47                           [Back to Grid]  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ⏱️ PHASE: Allocation (28s / 60s)                                      │
│                                                                          │
│  #  Character      Class   Priority  Requested      Allocated   Status │
│  ─────────────────────────────────────────────────────────────────────  │
│  1  Anna Elite     ELITE   982       Luxury_Meal    ✅ Granted   +15   │
│  2  Tom Baker      UPPER   765       Wheat          ✅ Granted   +8    │
│  3  Sue Teacher    UPPER   753       Books          ✅ Granted   +12   │
│  4  John Smith     MIDDLE  542       Wheat          ⚠️ Subst:Rice +6   │
│  5  Mary Cook      LOWER   438       Bread          ❌ Failed     -5   │
│  6  Bob Miner      LOWER   412       Cloth          ✅ Granted   +4    │
│  ...                                                                     │
│                                                                          │
│  📊 CURRENT CYCLE SUMMARY (so far):                                    │
│  • Allocated: 28 / 50 characters                                       │
│  • Granted: 22 (78%)                                                   │
│  • Substituted: 4 (14%)                                                │
│  • Failed: 2 (7%)                                                      │
│                                                                          │
│  🚨 SHORTAGES DETECTED:                                                │
│  • Bread: 0 remaining (8 requests denied)                              │
│  • Books: 2 remaining (high demand)                                    │
│  • Luxury_Meal: 1 remaining (elite priority consumed all)             │
│                                                                          │
├─────────────────────────────────────────────────────────────────────────┤
│  SUBSTITUTION DETAILS (Hover for info)                                 │
│                                                                          │
│  John Smith requested "Wheat" but none available.                      │
│  Substitution chain attempted:                                         │
│    Wheat (0 available) →                                               │
│    Rice (5 available, 95% efficiency) ✅ SUCCESS                       │
│                                                                          │
│  Satisfaction gain: 8 * 0.95 = 7.6 → +8 Bio craving                   │
└─────────────────────────────────────────────────────────────────────────┘
```

---

### 🎯 Consequences Dashboard: "What Happened"

**Post-cycle analysis**

```
┌─────────────────────────────────────────────────────────────────────────┐
│  🎯 CONSEQUENCES - Cycle 47 Complete                    [Back to Grid]  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ⚠️ EVENTS THIS CYCLE:                                                 │
│                                                                          │
│  🏃 EMIGRATION (2 characters left town)                                │
│  ├─ Bob Miner (Lower, satisfaction 18% for 3 cycles)                  │
│  └─ Sarah Farmer (Lower, satisfaction 15% for 4 cycles)               │
│                                                                          │
│  😡 RIOT WARNING (threshold: 20% town average)                         │
│  └─ Current town average: 34% (safe for now)                          │
│                                                                          │
│  📉 PRODUCTIVITY IMPACT:                                               │
│  └─ 12 workers have <40% satisfaction → 15% productivity penalty      │
│                                                                          │
│  ✅ POSITIVE EVENTS:                                                   │
│  └─ 8 characters achieved 80%+ satisfaction → +10% productivity        │
│                                                                          │
├─────────────────────────────────────────────────────────────────────────┤
│  📈 HISTORICAL TRENDS (Last 10 Cycles)                                 │
│                                                                          │
│  Population:     [52→52→50→50→49→49→48→48→48→48]  -8% overall        │
│  Avg Satisfaction: [45→47→43→38→35→34→36→38→32→34]  -24% overall     │
│  Emigrations/cycle:[0→0→2→0→1→0→0→1→0→2]    Total: 6                 │
│  Riots:          [0→0→0→0→0→0→0→0→0→0]    Total: 0                   │
│                                                                          │
│  🔴 CRITICAL ALERT: Downward spiral detected!                         │
│     Lower satisfaction → emigration → fewer workers →                  │
│     lower production → lower satisfaction (feedback loop)              │
│                                                                          │
│  💡 RECOMMENDATION: Inject Wheat (15 units) and Bread (10 units)      │
│     to stabilize biological cravings.                                  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

### 🧪 Scenario Lab: "What-If Testing"

**Experimental sandbox**

```
┌─────────────────────────────────────────────────────────────────────────┐
│  🧪 SCENARIO LAB                                       [Back to Grid]   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  PRESET SCENARIOS:                                                      │
│                                                                          │
│  🌾 FAMINE                                    [Load]                    │
│  └─ Zero biological goods for 5 cycles, watch chaos unfold             │
│                                                                          │
│  🎉 ABUNDANCE                                 [Load]                    │
│  └─ 1000 of every commodity, everyone satisfied                        │
│                                                                          │
│  ⚔️ CLASS WAR                                [Load]                    │
│  └─ Elite only get resources, lower class starves                      │
│                                                                          │
│  🎲 RANDOM CHAOS                              [Load]                    │
│  └─ Random commodity injection every cycle                             │
│                                                                          │
│  📚 EDUCATION BOOM                            [Load]                    │
│  └─ Flood of books, test psychological satisfaction                    │
│                                                                          │
├─────────────────────────────────────────────────────────────────────────┤
│  CUSTOM SCENARIO BUILDER:                                              │
│                                                                          │
│  Population Mix:                                                        │
│  Elite:  [______] (0-100)   Upper:  [______] (0-100)                  │
│  Middle: [______] (0-100)   Lower:  [______] (0-100)                  │
│                                                                          │
│  Initial Inventory:                                                    │
│  [ ] Empty (stress test)                                               │
│  [ ] Normal (balanced start)                                           │
│  [ ] Abundant (easy mode)                                              │
│  [ ] Custom: [Edit Inventory...]                                       │
│                                                                          │
│  Decay Rates:                                                          │
│  [ ] Default (as configured in data)                                   │
│  [ ] Fast (2x decay - brutal)                                          │
│  [ ] Slow (0.5x decay - forgiving)                                     │
│  [ ] None (test allocation only)                                       │
│                                                                          │
│  Allocation Rules:                                                     │
│  [ ] Class Priority (default)                                          │
│  [ ] Random (no priority)                                              │
│  [ ] Desperation Only (ignore class)                                   │
│  [ ] Reverse Priority (lower class first)                             │
│                                                                          │
│  [▶ Run Scenario for 100 cycles]  [💾 Save Scenario]                 │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Character System Design

### Character Data Structure

```lua
Character = {
    -- Identity
    id = "char_001",
    name = "John Smith",
    age = 32,

    -- Classification
    class = "Middle",           -- Elite/Upper/Middle/Lower
    vocation = "Baker",         -- Profession (for production engine later)
    traits = {                  -- 2-3 traits per character
        "Ambitious",            -- +20% status craving decay
        "Frugal"                -- -15% exotic goods craving
    },

    -- Satisfaction State (0-100 for each)
    satisfaction = {
        biological = 65,        -- Food, water, medicine
        touch = 45,             -- Cloth, furniture, comfort
        psychological = 30,     -- Books, art, education
        safety = 50,            -- Security, police, walls
        socialStatus = 20,      -- Jewelry, prestige items
        exoticGoods = 10,       -- Wine, spices, luxury food
        shinyObjects = 15       -- Gold, silver, decorations
    },

    -- Decay Tracking (cycles since last fulfilled)
    cravingHistory = {
        biological = {lastFulfilled = 2, cyclesSinceCritical = 0},
        touch = {lastFulfilled = 5, cyclesSinceCritical = 0},
        -- ... for each craving
    },

    -- Allocation State
    allocationPriority = 542,   -- Calculated each cycle
    lastAllocationCycle = 45,
    allocationSuccessRate = 0.65,  -- Historical success %

    -- Personal Inventory (for future use in production)
    inventory = {
        wheat = 3,
        bread = 1,
        cloth = 0
    },

    -- Emigration Tracking
    consecutiveLowSatisfactionCycles = 1,  -- Count toward emigration
    emigrationThreshold = 30,              -- Class-dependent

    -- Visual State
    position = {x = 100, y = 200},  -- On grid
    highlighted = false,             -- User selected
    animationState = "idle"          -- idle/happy/stressed/leaving
}
```

### Character Generation

**Smart Generation Based on Class:**

```lua
function GenerateCharacter(class)
    local char = {}

    -- Name from pool
    char.name = RandomName()

    -- Class-specific starting satisfaction
    if class == "Elite" then
        char.satisfaction.socialStatus = random(70, 90)  -- Elite care about status
        char.satisfaction.biological = random(60, 80)    -- Good access to food
        char.satisfaction.exoticGoods = random(50, 70)   -- Love luxury
    elseif class == "Lower" then
        char.satisfaction.biological = random(20, 40)    -- Struggling for food
        char.satisfaction.socialStatus = random(10, 30)  -- Low status concern
        char.satisfaction.exoticGoods = random(5, 15)    -- Can't afford luxury
    end

    -- Traits affect base cravings
    char.traits = PickRandomTraits(2, class)
    ApplyTraitModifiers(char)

    return char
end
```

---

## Craving & Satisfaction Mechanics

### Two-Layer Decay System

The prototype implements **two independent decay mechanisms** that work together to create realistic consumption patterns:

**Quick Summary:**
- **Layer 1 (Craving Decay):** "I'm getting hungry again" - time-based need regeneration
- **Layer 2 (Commodity Decay):** "I'm tired of cake, I want pie" - variety-seeking behavior

**Concrete Example:**

```
Cycle 1:  Character eats cake → Biological craving: 40% → 65% (+25)
          Commodity history: cake = 1 consumption (100% effectiveness)

Cycle 5:  Character eats cake again → Biological: 50% → 71% (+21, 85% effective)
          Commodity history: cake = 2 consecutive (85% effectiveness)

Cycle 9:  Character eats cake again → Biological: 45% → 59% (+14, 70% effective)
          Commodity history: cake = 3 consecutive (70% effectiveness)
          STATUS: "🔁 Tired of cake" appears on character

Cycle 13: Character eats cake again → Biological: 40% → 50% (+10, 55% effective)
          Allocation system now PREFERS pie/dessert substitutes if available

Cycle 20: Character eats PIE instead → Biological: 35% → 57% (+22, 95% effective)
          Commodity history: cake decay starts, pie = 1 consumption
          Cake consecutive count reduces over time (variety cooldown)

Cycle 35: Enough time passed → Cake resets to 100% effectiveness
          Character can enjoy cake again like it's the first time
```

---

#### Layer 1: Craving Decay (Time-Based Need Regeneration)

**What it does:** Your biological/psychological needs naturally increase over time, creating recurring demand.

**Example:** "I haven't eaten in a while, so I'm getting hungry again."

**Per-Cycle Decay Formula:**

```lua
function DecayCravings(character, deltaTime)
    for cravingType, value in pairs(character.satisfaction) do
        -- Get decay rate from data
        local baseDecay = GetDecayRate(cravingType, character.class)

        -- Trait modifiers
        local traitMultiplier = GetTraitDecayMultiplier(character.traits, cravingType)

        -- Apply decay
        local decay = baseDecay * traitMultiplier * (deltaTime / 60)
        character.satisfaction[cravingType] = math.max(0, value - decay)

        -- Track critical periods
        if character.satisfaction[cravingType] < 20 then
            character.cravingHistory[cravingType].cyclesSinceCritical += 1
        end
    end
end
```

**Decay Rates by Class (examples):**
```json
{
  "biological": {
    "Elite": 2.0,
    "Upper": 2.5,
    "Middle": 3.0,
    "Lower": 3.5
  },
  "socialStatus": {
    "Elite": 5.0,
    "Upper": 3.0,
    "Middle": 2.0,
    "Lower": 1.0
  }
}
```

**Design Insight:** Elite decay social status faster (5.0) than biological (2.0) because status matters more to their identity. Lower class decays biological faster because survival is primary concern.

---

#### Layer 2: Commodity Fulfillment Decay (Variety-Seeking / Diminishing Returns)

**What it does:** Repeated consumption of the same commodity provides diminishing satisfaction over time. Characters crave variety within the same craving category.

**Example:** "I've eaten cake 5 times in a row. I'm tired of cake. I want pie instead!"

**Commodity Consumption Tracking:**

```lua
Character = {
    -- ... existing fields

    -- NEW: Track recent consumption history per commodity
    commodityHistory = {
        cake = {
            lastConsumed = 47,           -- Cycle number
            consecutiveConsumptions = 5, -- Times consumed without variety
            fulfillmentMultiplier = 0.40 -- 40% effectiveness (down from 100%)
        },
        wheat = {
            lastConsumed = 43,
            consecutiveConsumptions = 2,
            fulfillmentMultiplier = 0.85
        }
        -- ... other commodities
    }
}
```

**Diminishing Returns Formula:**

```lua
function CalculateCommodityFulfillmentMultiplier(character, commodity)
    local history = character.commodityHistory[commodity]

    if not history then
        -- First time consuming this commodity
        return 1.0  -- 100% effectiveness
    end

    local consecutiveCount = history.consecutiveConsumptions
    local cyclesSinceLastConsumed = CurrentCycle - history.lastConsumed

    -- Reset if enough time has passed (variety cooldown)
    if cyclesSinceLastConsumed > 10 then
        history.consecutiveConsumptions = 0
        return 1.0
    end

    -- Diminishing returns formula
    -- 1st time: 100%
    -- 2nd time: 85%
    -- 3rd time: 70%
    -- 4th time: 55%
    -- 5th time: 40%
    -- 6th time: 25%
    -- 7th+ time: 25% (floor)
    local multiplier = math.max(0.25, 1.0 - (consecutiveCount * 0.15))

    history.fulfillmentMultiplier = multiplier
    return multiplier
end

function UpdateCommodityHistory(character, commodity)
    if not character.commodityHistory[commodity] then
        character.commodityHistory[commodity] = {
            lastConsumed = CurrentCycle,
            consecutiveConsumptions = 1,
            fulfillmentMultiplier = 1.0
        }
    else
        local history = character.commodityHistory[commodity]
        local cyclesSinceLast = CurrentCycle - history.lastConsumed

        if cyclesSinceLast <= 10 then
            -- Still in "tired of this" period
            history.consecutiveConsumptions = history.consecutiveConsumptions + 1
        else
            -- Cooldown expired, reset counter
            history.consecutiveConsumptions = 1
        end

        history.lastConsumed = CurrentCycle
    end

    -- Decay other commodities' consecutive counts (variety bonus)
    for otherCommodity, otherHistory in pairs(character.commodityHistory) do
        if otherCommodity ~= commodity then
            local cyclesSince = CurrentCycle - otherHistory.lastConsumed
            if cyclesSince >= 3 then
                -- Reduce consecutive count over time
                otherHistory.consecutiveConsumptions = math.max(0,
                    otherHistory.consecutiveConsumptions - 1)
            end
        end
    end
end
```

**Substitution Preference Due to Boredom:**

When a character is "tired" of a commodity (multiplier < 0.70), the allocation system will:

1. **Prefer substitutes** even if the primary commodity is available
2. **Apply substitution efficiency bonus** (+10%) for variety-seeking behavior
3. **Show visual indicator** in UI: "🔁 Seeking variety" next to character name

```lua
function SelectCommodityForAllocation(character, cravingType)
    -- Get primary commodity request (highest fulfillment for this craving)
    local primaryCommodity = GetBestCommodityForCraving(cravingType)
    local primaryMultiplier = CalculateCommodityFulfillmentMultiplier(character, primaryCommodity)

    -- If tired of primary (< 70%), prefer substitutes
    if primaryMultiplier < 0.70 then
        local substitutes = GetSubstitutesForCommodity(primaryCommodity, cravingType)

        for _, substitute in ipairs(substitutes) do
            local subMultiplier = CalculateCommodityFulfillmentMultiplier(character, substitute)

            -- Prefer substitute if it has better multiplier
            if subMultiplier > primaryMultiplier + 0.10 then
                return substitute, "variety_seeking"
            end
        end
    end

    return primaryCommodity, "normal"
end
```

---

### Satisfaction Gain System

**Fulfillment Formula (Now with Commodity Decay):**

```lua
function FulfillCraving(character, commodity, quantity)
    -- Get fulfillment vector from data
    local fulfillmentVector = GetFulfillmentVector(commodity)

    -- LAYER 2: Get commodity-specific diminishing returns multiplier
    local commodityMultiplier = CalculateCommodityFulfillmentMultiplier(character, commodity)

    for cravingType, basePoints in pairs(fulfillmentVector) do
        -- Quality multiplier
        local quality = GetCommodityQuality(commodity)  -- poor/basic/good/luxury
        local qualityMultiplier = GetQualityMultiplier(quality)

        -- Class acceptance (Elite won't accept "poor" quality)
        if not ClassAcceptsQuality(character.class, quality) then
            continue
        end

        -- Calculate gain with BOTH quality AND commodity variety multipliers
        local gain = basePoints * qualityMultiplier * commodityMultiplier * quantity

        -- Apply with diminishing returns (can't exceed 100)
        character.satisfaction[cravingType] = math.min(100,
            character.satisfaction[cravingType] + gain)

        -- Reset critical tracker
        character.cravingHistory[cravingType].lastFulfilled = CurrentCycle
        character.cravingHistory[cravingType].cyclesSinceCritical = 0
    end

    -- LAYER 2: Update commodity consumption history
    UpdateCommodityHistory(character, commodity)

    -- Visual feedback for variety-seeking
    if commodityMultiplier < 0.70 then
        ShowCharacterStatus(character, "🔁 Tired of " .. commodity)
    end
end
```

**Example Fulfillment Vector (Wheat):**
```json
{
  "wheat": {
    "biological": 8,
    "touch": 0,
    "psychological": 0,
    "safety": 1,
    "socialStatus": 0,
    "exoticGoods": 0,
    "shinyObjects": 0
  }
}
```

---

## Resource Injection System

### Manual Injection Panel

**Design: Quick-Access + Custom**

```lua
-- Quick Inject Buttons (most common commodities)
QuickInjectButtons = {
    {commodity = "wheat", amount = 10, icon = "🌾"},
    {commodity = "bread", amount = 10, icon = "🍞"},
    {commodity = "cloth", amount = 5, icon = "👕"},
    {commodity = "books", amount = 5, icon = "📚"},
    {commodity = "wine", amount = 3, icon = "🍷"},
    {commodity = "gold", amount = 2, icon = "🪙"}
}

-- Custom Injection
function ShowCustomInjectDialog()
    -- Dropdown: All 120+ commodities
    -- Number input: 1-1000
    -- Button: Inject Now
end

function InjectResource(commodity, amount)
    TownInventory[commodity] = (TownInventory[commodity] or 0) + amount

    -- Visual feedback
    ShowFloatingText("+" .. amount .. " " .. commodity, position)
    PlaySound("resource_added.wav")

    -- Log for analytics
    LogEvent("RESOURCE_INJECTED", {commodity, amount, cycle})
end
```

### Automated Injection (Advanced Feature)

**Design: Scheduled Resource Streams**

```lua
-- Player can configure periodic injections
InjectSchedule = {
    {
        commodity = "wheat",
        amount = 20,
        frequency = 3,      -- Every 3 cycles
        enabled = true
    },
    {
        commodity = "bread",
        amount = 15,
        frequency = 2,
        enabled = true
    }
}

function ProcessScheduledInjections(currentCycle)
    for _, schedule in ipairs(InjectSchedule) do
        if schedule.enabled and (currentCycle % schedule.frequency == 0) then
            InjectResource(schedule.commodity, schedule.amount)
        end
    end
end
```

**UI for Scheduled Injections:**
```
┌─────────────────────────────────────┐
│  📅 SCHEDULED INJECTIONS            │
├─────────────────────────────────────┤
│  Wheat:  20 units / 3 cycles  [✓]  │
│  Bread:  15 units / 2 cycles  [✓]  │
│  Cloth:  10 units / 5 cycles  [ ]  │
│                                     │
│  [+ Add Schedule]                   │
└─────────────────────────────────────┘
```

---

## Allocation Algorithm

### Priority Calculation

**Formula: Class Base + Desperation Modifier**

```lua
function CalculateAllocationPriority(character)
    -- Class base priority
    local classPriority = {
        Elite = 1000,
        Upper = 750,
        Middle = 500,
        Lower = 250
    }

    local base = classPriority[character.class]

    -- Desperation modifier (low satisfaction = higher priority)
    local avgSatisfaction = CalculateAverageSatisfaction(character)
    local desperationBonus = (100 - avgSatisfaction) * 2  -- 0 to 200

    -- Critical craving bonus (any craving < 20)
    local criticalBonus = 0
    for _, value in pairs(character.satisfaction) do
        if value < 20 then
            criticalBonus += 100
        end
    end

    return base + desperationBonus + criticalBonus
end
```

**Example Priority Scores:**
- Elite at 80% satisfaction: 1000 + 40 + 0 = **1040**
- Middle at 30% satisfaction with 2 critical: 500 + 140 + 200 = **840**
- Lower at 50% satisfaction: 250 + 100 + 0 = **350**

**Result:** Middle class character in crisis gets priority over comfortable Elite!

---

### Allocation Loop

**Sequential Processing with Substitution**

```lua
function RunAllocationCycle(characters, inventory)
    -- Sort by priority (highest first)
    table.sort(characters, function(a, b)
        return a.allocationPriority > b.allocationPriority
    end)

    local allocationLog = {}

    for _, char in ipairs(characters) do
        -- Determine what character needs most
        local neediest = FindLowestCraving(char)
        local commodity = PickBestCommodityForCraving(neediest, char.class)

        -- Attempt allocation
        if inventory[commodity] and inventory[commodity] > 0 then
            -- Success: Grant resource
            inventory[commodity] -= 1
            FulfillCraving(char, commodity, 1)
            table.insert(allocationLog, {
                char = char.name,
                requested = commodity,
                result = "GRANTED",
                satisfactionGain = CalculateGain(commodity, neediest)
            })
        else
            -- Failure: Try substitution
            local substitute = FindSubstitute(commodity, inventory)
            if substitute then
                inventory[substitute] -= 1
                FulfillCraving(char, substitute, 1)
                table.insert(allocationLog, {
                    char = char.name,
                    requested = commodity,
                    result = "SUBSTITUTED",
                    granted = substitute,
                    efficiency = GetSubstitutionEfficiency(commodity, substitute)
                })
            else
                -- Total failure
                table.insert(allocationLog, {
                    char = char.name,
                    requested = commodity,
                    result = "FAILED"
                })
            end
        end
    end

    return allocationLog
end
```

---

## Substitution System

### Hierarchy-Based Substitution

**Design: Each commodity has ranked alternatives**

```json
{
  "wheat": {
    "category": "grain",
    "substitutes": [
      {"item": "rice", "efficiency": 0.95, "reason": "Same grain family"},
      {"item": "barley", "efficiency": 0.80, "reason": "Coarser grain"},
      {"item": "bread", "efficiency": 0.70, "reason": "Processed wheat"}
    ]
  }
}
```

**Substitution Algorithm:**

```lua
function FindSubstitute(requestedCommodity, inventory)
    local substitutes = GetSubstitutes(requestedCommodity)

    -- Try substitutes in order of efficiency
    table.sort(substitutes, function(a, b)
        return a.efficiency > b.efficiency
    end)

    for _, sub in ipairs(substitutes) do
        if inventory[sub.item] and inventory[sub.item] > 0 then
            return sub.item, sub.efficiency
        end
    end

    return nil  -- No substitutes available
end
```

### Cross-Category Substitution

**Design: Desperation allows reaching across categories**

```lua
-- If biological < 10 and no grain available, try ANY food
function DesperationSubstitution(character, cravingType, inventory)
    if character.satisfaction[cravingType] < 10 then
        -- Get ALL commodities that fulfill this craving
        local alternatives = GetAllCommoditiesForCraving(cravingType)

        for _, commodity in ipairs(alternatives) do
            if inventory[commodity] > 0 then
                return commodity, 0.5  -- 50% efficiency (desperate measure)
            end
        end
    end

    return nil
end
```

---

## Consequence System

### Emigration Mechanics

**Trigger: <30% satisfaction for 3 consecutive cycles**

```lua
function CheckEmigration(character, currentCycle)
    local avgSat = CalculateAverageSatisfaction(character)

    if avgSat < character.emigrationThreshold then
        character.consecutiveLowSatisfactionCycles += 1
    else
        character.consecutiveLowSatisfactionCycles = 0  -- Reset
    end

    -- Emigration threshold
    if character.consecutiveLowSatisfactionCycles >= 3 then
        EmitEvent("CHARACTER_EMIGRATED", character)
        RemoveCharacter(character)
        return true
    end

    return false
end
```

**Visual: Emigration Animation**
- Character card pulses red for 3 cycles (warning)
- On emigration: Card fades out with "walking away" animation
- Sound: Sad departure chime
- Log message: "John Smith has left town due to poor living conditions"

---

### Riot System

**Trigger: Town average satisfaction < 20%**

```lua
function CheckRiotConditions(characters, currentCycle)
    local totalSat = 0
    for _, char in ipairs(characters) do
        totalSat += CalculateAverageSatisfaction(char)
    end

    local townAverage = totalSat / #characters

    if townAverage < 20 then
        -- Riot threshold reached
        if not RiotActive then
            StartRiot(currentCycle)
        end

        -- Riot effects
        ApplyRiotPenalties()
        return true
    else
        if RiotActive then
            EndRiot(currentCycle)
        end
        return false
    end
end

function ApplyRiotPenalties()
    -- Production completely stops (for production engine integration)
    GlobalProductionMultiplier = 0

    -- Additional decay
    GlobalDecayMultiplier = 2.0

    -- Visual effects
    ShakeScreen()
    PlaySound("riot_sounds.wav")
    ShowGlobalWarning("🔥 RIOT IN PROGRESS! 🔥")
end
```

---

### Productivity Feedback (for Production Engine)

**Design: Satisfaction directly affects work output**

```lua
function CalculateWorkerProductivity(character)
    local avgSat = CalculateAverageSatisfaction(character)

    -- Productivity curve
    if avgSat >= 80 then
        return 1.20  -- +20% bonus
    elseif avgSat >= 60 then
        return 1.05  -- +5% bonus
    elseif avgSat >= 40 then
        return 1.00  -- Normal
    elseif avgSat >= 20 then
        return 0.85  -- -15% penalty
    else
        return 0.60  -- -40% penalty (critical)
    end
end
```

---

## Analytics & Visualization

### Real-Time Charts

**1. Satisfaction Timeline (Line Chart)**
```
100% ┤
     │     ┌──┐
 80% ┤    ╱    ╲
     │   ╱      ╲
 60% ┤  ╱        ╲───
     │ ╱              ╲
 40% ┤╱                ╲──
     │                     ╲
 20% ┤                      ╲
     │
  0% └─────────────────────────
     0   20   40   60   80  100
           Cycles

Legend:
─── Town Average
─── Elite Average
─── Lower Average
─── Critical Threshold (20%)
```

**2. Craving Distribution (Radar Chart)**
```
        Biological
           100
            │
            ●───── 65
           ╱│╲
          ╱ │ ╲
  Touch  ●  │  ● Psychological
        60  │ 30
         ╲  │  ╱
          ╲ │ ╱
    Safety ●─┼─● Status
          55 0 20

(7-pointed radar for each character or class average)
```

**3. Class Disparity Visualization**
```
Elite      ████████████████████ 87%
Upper      ████████████▓░░░░░░░ 68%
Middle     ████████░░░░░░░░░░░░ 52%
Lower      ████▓░░░░░░░░░░░░░░░ 34%
           0%                 100%
```

---

### Data Export

**CSV Export for External Analysis**

```lua
function ExportAnalyticsCSV(filename)
    local csv = "Cycle,CharacterID,Name,Class,Vocation,"
    csv = csv .. "Biological,Touch,Psychological,Safety,Status,Exotic,Shiny,"
    csv = csv .. "AvgSatisfaction,Priority,Emigrated\n"

    for cycleNum, snapshot in ipairs(CycleHistory) do
        for _, char in ipairs(snapshot.characters) do
            csv = csv .. string.format("%d,%s,%s,%s,%s,%d,%d,%d,%d,%d,%d,%d,%.2f,%d,%s\n",
                cycleNum, char.id, char.name, char.class, char.vocation,
                char.satisfaction.biological,
                char.satisfaction.touch,
                char.satisfaction.psychological,
                char.satisfaction.safety,
                char.satisfaction.socialStatus,
                char.satisfaction.exoticGoods,
                char.satisfaction.shinyObjects,
                CalculateAverageSatisfaction(char),
                char.allocationPriority,
                char.emigrated and "YES" or "NO")
        end
    end

    SaveFile(filename, csv)
end
```

---

## Enhancement Ideas

### 🎮 Gamification Elements

**1. Achievements System**
```
🏆 "No One Left Behind" - 100 cycles without emigration
🏆 "Satisfied Citizens" - Maintain 80%+ town average for 50 cycles
🏆 "Crisis Manager" - Recover from <20% average to 60%+ in 10 cycles
🏆 "Perfectly Balanced" - All 7 craving types within 5% of each other
🏆 "Class Harmony" - All classes within 10% satisfaction of each other
```

**2. Challenge Modes**
- **Speed Run:** How fast can you stabilize 100 characters?
- **Resource Limit:** Only 500 total commodities allowed across 100 cycles
- **Random Injection:** You can't control what resources appear
- **Class Collapse:** One class randomly gets ZERO resources each cycle

---

### 🧠 AI-Assisted Balancing

**Auto-Suggest Injection Amounts**

```lua
function CalculateRecommendedInjection()
    -- Analyze current shortages
    local shortages = {}
    for _, char in ipairs(Characters) do
        local neediest = FindLowestCraving(char)
        local commodity = PickBestCommodityForCraving(neediest)
        shortages[commodity] = (shortages[commodity] or 0) + 1
    end

    -- Sort by demand
    local recommendations = {}
    for commodity, count in pairs(shortages) do
        table.insert(recommendations, {
            commodity = commodity,
            amount = math.ceil(count * 1.2),  -- 20% buffer
            urgency = CalculateUrgency(commodity, count)
        })
    end

    return recommendations
end
```

**Display:**
```
💡 RECOMMENDED INJECTIONS:
  • Wheat: 18 units (16 characters need it - HIGH URGENCY)
  • Cloth: 8 units (7 characters need it - MEDIUM)
  • Books: 5 units (4 characters need it - LOW)

  [Inject All] [Inject High Only] [Dismiss]
```

---

### 📊 Historical Playback

**"Replay" Feature**

```lua
-- Save every cycle state
function SaveCycleSnapshot(cycle, characters, inventory)
    CycleHistory[cycle] = {
        characters = DeepCopy(characters),
        inventory = DeepCopy(inventory),
        events = DeepCopy(EventLog)
    }
end

-- Playback mode
function EnterPlaybackMode()
    -- Scrubber UI at bottom
    -- Can drag to any cycle
    -- Can play forward/backward
    -- Speed controls

    -- Shows what WOULD happen with different injections
end
```

**UI:**
```
┌─────────────────────────────────────────────────────────┐
│  ⏮️  ⏪  ▶️  ⏩  ⏭️   [Speed: 1x ▼]                    │
│  ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤   │
│  0    10    20    30    40    50    60    70    80    │
│                        👆 Cycle 47                      │
│                                                         │
│  💡 WHAT-IF MODE:                                      │
│  At cycle 30, inject 20 Wheat? [Test Impact]          │
└─────────────────────────────────────────────────────────┘
```

---

### 🎭 Character Stories

**Narrative Generation**

```lua
function GenerateCharacterStory(character, cycleCount)
    local stories = {}

    -- Analyze character's journey
    if character.satisfaction.biological < 30 then
        table.insert(stories, character.name .. " is struggling to find enough food.")
    end

    if character.consecutiveLowSatisfactionCycles >= 2 then
        table.insert(stories, character.name .. " is seriously considering leaving town.")
    end

    if CalculateAverageSatisfaction(character) > 80 then
        table.insert(stories, character.name .. " is thriving and encouraging others to stay.")
    end

    -- Trait-based stories
    if HasTrait(character, "Ambitious") and character.satisfaction.socialStatus < 40 then
        table.insert(stories, character.name .. " feels their ambitions are being crushed.")
    end

    return stories
end
```

**Display:**
```
┌────────────────────────────────────────────┐
│  📖 CHARACTER STORIES                      │
├────────────────────────────────────────────┤
│  John Smith (Middle, Baker)               │
│  "John is struggling to find enough       │
│   food. His ambitious nature makes him    │
│   frustrated with the lack of             │
│   opportunity in town."                   │
│                                            │
│  Cycles in town: 47                       │
│  Likely to emigrate in: 1 cycle ⚠️       │
└────────────────────────────────────────────┘
```

---

### 🔄 Enablement System Integration

**Dynamic Craving Changes**

From the data: `enablement_rules.json` defines triggers that change cravings

```lua
function CheckEnablementRules(character, townState)
    local rules = LoadEnablementRules()

    for _, rule in ipairs(rules) do
        if EvaluateTrigger(rule.trigger, character, townState) then
            -- Apply craving modifier
            for cravingType, modifier in pairs(rule.effect.cravingModifier) do
                character.satisfaction[cravingType] += modifier

                -- Visual feedback
                ShowFloatingText(
                    rule.name .. " triggered!",
                    character.position,
                    COLOR_YELLOW
                )
            end
        end
    end
end
```

**Example Enablement:**
```json
{
  "id": "education_unlocks_art",
  "trigger": {
    "type": "COMMODITY_CONSUMED",
    "commodity": "books",
    "count": 10
  },
  "effect": {
    "cravingModifier": {
      "psychological": 20,
      "socialStatus": 10
    },
    "permanent": true
  }
}
```

**Result:** After reading 10 books, character gains permanent +20 psychological satisfaction and becomes more interested in art/status.

---

### 📱 Second Screen Dashboard

**Companion Web View (Bonus Feature)**

Serve a web dashboard on localhost:8080 showing real-time stats:

```lua
-- Simple HTTP server exposing JSON API
function ServeAnalyticsDashboard()
    -- Endpoints:
    -- GET /api/characters - Current state
    -- GET /api/cycles/latest - Last cycle data
    -- GET /api/heatmap - Craving heatmap data
    -- GET /api/events - Event stream

    -- WebSocket for real-time updates
end
```

**Use Cases:**
- Stream on Twitch with overlay stats
- Analyze data on second monitor
- Remote monitoring during long simulations
- Share live URLs with testers

---

## Implementation Roadmap

### Week-by-Week Plan

**Week 1: Foundation**
- [ ] Character.lua data structure
- [ ] Character spawning with class/trait selection
- [ ] Basic character grid rendering
- [ ] Decay system implementation
- [ ] Manual resource injection panel

**Week 2: Allocation Core**
- [ ] Priority calculation algorithm
- [ ] Allocation loop with sequential processing
- [ ] Substitution system (hierarchy only)
- [ ] Fulfillment vector application
- [ ] Allocation log view

**Week 3: Consequences**
- [ ] Emigration trigger system
- [ ] Riot detection and effects
- [ ] Productivity calculation (for future integration)
- [ ] Event logging system
- [ ] Consequence dashboard

**Week 4: Polish & Analytics**
- [ ] Craving heatmap view
- [ ] Real-time chart implementations
- [ ] CSV export functionality
- [ ] Scenario presets
- [ ] Historical playback
- [ ] Performance optimization (100 chars × 100 cycles stable)

---

### File Structure

```
/code
├── Prototype1State.lua           (Main state, orchestration)
├── Character.lua                 (Character class & behavior)
├── CravingSystem.lua             (Decay, fulfillment logic)
├── AllocationEngine.lua          (Priority queue, allocation loop)
├── SubstitutionSystem.lua        (Hierarchy, cross-category logic)
├── ConsequenceSystem.lua         (Emigration, riots, effects)
├── ResourceInjector.lua          (Manual & scheduled injection)
├── AnalyticsDashboard.lua        (Charts, heatmaps, exports)
├── ScenarioLab.lua               (Preset scenarios, what-if mode)
└── CharacterRenderer.lua         (Visual representation)

/data/base/craving_system
├── dimension_definitions.json    (7 craving types, decay rates)
├── character_classes.json        (Elite/Upper/Middle/Lower definitions)
├── character_traits.json         (Ambitious, Frugal, etc.)
├── fulfillment_vectors.json      (Commodity → Craving mapping)
├── enablement_rules.json         (Dynamic craving changes)
└── substitution_rules.json       (Hierarchy & efficiency)
```

---

## Success Criteria

### Prototype Validation Checklist

**Core Functionality:**
- [ ] 100 characters run for 100 cycles without crashes
- [ ] All 7 craving types decay correctly based on class
- [ ] Allocation respects class priority system
- [ ] Desperation can override class priority
- [ ] Substitution works for all major commodity categories
- [ ] Emigration triggers at correct thresholds
- [ ] Riots occur when town average <20%
- [ ] Productivity feedback calculates correctly

**User Experience:**
- [ ] Can spawn/delete characters easily
- [ ] Resource injection is instant and clear
- [ ] Character card hover shows full detail
- [ ] Allocation log updates in real-time
- [ ] Analytics views are readable and useful
- [ ] Can export data to CSV
- [ ] Scenario presets work correctly
- [ ] Performance: 60 FPS with 100 characters

**Integration Readiness:**
- [ ] Character state can be serialized to JSON
- [ ] Productivity values ready for production engine
- [ ] Clear APIs for production system to query satisfaction
- [ ] Event system compatible with main game loop
- [ ] No hardcoded dependencies on production systems

---

## Final Thoughts

This prototype is designed to be:

1. **Standalone** - Fully functional without production engine
2. **Observable** - Every calculation visible to player
3. **Experimental** - Easy to tweak parameters and see results
4. **Educational** - Teaches complex systems through play
5. **Integration-Ready** - Clean APIs for merging with production engine

The key insight: **Consumption is the heart of the game.** Production exists to serve consumption needs. By building this first, we validate the core emotional loop: *characters have needs → resources fulfill needs → satisfaction drives behavior.*

Once this loop feels good, adding production becomes "just" a matter of generating the resources that the consumption engine demands.

---

**Ready to implement! 🚀**
