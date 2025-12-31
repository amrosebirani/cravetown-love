# Cravetown Implementation Plans

**Created:** 2024-11-22
**Last Updated:** 2025-12-31
**Type:** AI Assistant Instructions / Implementation Guide
**Purpose:** Comprehensive technical implementation notes and specifications for Claude AI assistant working on Cravetown codebase

> **Note:** For presentation-ready overview of development strategy, see [`cravetown_development_plan.md`](./chain-of-thought/todo-lists/cravetown_development_plan.md).
> **Note:** For complete project structure, see [`STRUCTURE.md`](./STRUCTURE.md).

---

## Cravetown Resource Allocation & Craving System using a Hierarchy-based Design

### Task 1: Unified Resource Taxonomy → Create ResourceTaxonomy.lua

**Central classification system (Tackling: Inventory/Commodity → Character → Buildings)**

- **0th step** → Total Commodities we have → 120

- **0th step** → 9 Craving types for these 120 to be divided in → Sensory, Biological, Touch, Emotional and Psychological, Safety and Survival, Social Status, Exotic (Foreign), Shiny, Rare

#### Example Mappings

**Biological Cravings (food/water/survival):**
- Grains: wheat, rice, barley, maize, oats, rye
- Vegetables: potato, carrot, onion, cabbage, tomato, lettuce, beans, pumpkin
- Fruits: apple, mango, orange, grapes, berries, peach, pear
- Processed: bread, flour, cheese, butter, preserved_food
- Animal: meat, milk, eggs
- Water (implicit need)

**Touch Cravings (tactile comfort):**
- Textiles: cotton, flax, silk, wool, thread, cloth, linen
- Clothes: simple_clothes, work_clothes, fine_clothes, luxury_clothes, winter_coat, shoes, boots, hat
- Furniture: chair, table, bed, cabinet, wardrobe, bench

**Emotional and Psychological Cravings (mental stimulation):**
- Cultural: book, painting, sculpture, music (if added)
- Entertainment: games (if added), performance
- Education: access to school/university

**Safety and Survival Cravings (security):**
- Protection: police presence, walls, guards
- Tools: axe, hammer, pickaxe (for self-sufficiency)
- Medicine: medicine, soap (hygiene)

**Social Status Cravings (prestige):**
- Housing: Manor > Family Home > Lodge
- Clothing: luxury_clothes > fine_clothes > work_clothes > simple_clothes
- Services: personal servants, education access

**Exotic Goods Cravings (novelty):**
- Luxury food: wine, beer, pastries, honey
- Rare items: perfume, silk, gold, spices (if added)
- Imported: items from trade (if added)

**Shiny Objects Cravings (material wealth):**
- Precious metals: gold, silver, jewelry
- Decorative: pottery, sculpture, painting
- Currency/wealth accumulation

#### Example of a priority-based structure (with an additional quality-tier funda which is discussed later)

**P1 - Survival (Critical)**
- Biological: Food, water
- If unsatisfied < 20: Character becomes desperate, may riot/leave
- Allocation Priority: HIGHEST

**P2 - Safety & Comfort (Important)**
- Safety: Security, medicine
- Touch: Basic clothing, shelter
- If unsatisfied < 30: Character becomes unhappy, productivity drops
- Allocation Priority: HIGH

**P3 - Social & Psychological (Nice-to-Have)**
- Psychological: Entertainment, education
- Social Status: Prestige items, position
- If unsatisfied < 40: Character is neutral, stays but doesn't thrive
- Allocation Priority: MEDIUM

**P4 - Luxury (Optional)**
- Exotic Goods: Rare items, delicacies
- Shiny Objects: Wealth, collectibles
- If unsatisfied: Character wants more but won't leave
- Allocation Priority: LOW

#### Example of class-specific mapping

**For Elite characters:**
- Their "survival" includes social status because reputation matters as much as food
- Lack of prestige / lowered output = critical dissatisfaction (craving score multiplier for every commodity reduced) (this multiplier effect can be for all classes)
- They have guaranteed access to Tier 1/2, competition is for Tier 3/4

#### Implementation Steps

**1st Step** → Create categories for each type of commodity (already built in Inventory funda - recheck!)

**2nd Step** → Create substitution rules (in CravingDefinitions.lua) for each individual commodity by comparing within the categories (human-intensive task, bias problem, discuss)

Example Substitution Hierarchies (this is not the quality-tier funda!):

```
BIOLOGICAL (Grain category):
Tier 1 (preferred): wheat, rice
Tier 2 (acceptable): barley, maize
Tier 3 (last resort): oats, rye

TOUCH (Clothing category):
Elite class: luxury_clothes ONLY
Upper class: fine_clothes OR luxury_clothes
Middle class: work_clothes OR fine_clothes
Lower class: simple_clothes OR work_clothes
```

**3rd Step** → Create substitution rules (in CravingDefinitions.lua) for categories themselves (using diminishing marginal utility)

**4th Step** → Create substitution rules (in CravingDefinitions.lua) for cross-category commodities individually

**5th step (Quality-tier funda, Inventory/Commodity Over)** → Add quality tiers (poor/basic/good/luxury) within each category for each commodity to derive Satisfaction Value (human intensive task - needs using a matrix system)

Example Quality Tiers (for now hard coded - but must be dynamic dependent on cost/rarity/exotic):
- Poor: Basic survival items (simple_clothes, bread, preserved_food) → Poor
- Basic: Standard items (work_clothes, fresh food, simple furniture) → Poor/Normal
- Good: Quality items (fine_clothes, variety of foods, crafted furniture) → Normal
- Luxury: Premium items (luxury_clothes, wine, jewelry, manor residence) → Elites

**6th Step (Character Mapping)** → Map building outputs to craving fulfillment using a scoring system (explained below) (should also factor in class with some baseline requirements)

Example of Baseline Craving Score (a dynamic model to be thought of later):

```lua
Lower Class Character:
cravingBaselines = {
    biological = 70,      -- High food need
    touch = 40,           -- Basic comfort
    psychological = 20,   -- Low mental stimulation need
    safety = 50,          -- Moderate security need
    socialStatus = 10,    -- Minimal prestige need
    exoticGoods = 5,      -- Rarely needs luxuries
    shinyObjects = 5      -- Minimal material wealth need
}

Elite Class Character:
cravingBaselines = {
    biological = 40,      -- Food is given, not a concern
    touch = 70,           -- High comfort standards
    psychological = 60,   -- Needs entertainment/culture
    safety = 80,          -- Very high security need
    socialStatus = 90,    -- Must maintain prestige
    exoticGoods = 80,     -- Constant luxury demand
    shinyObjects = 85     -- High wealth accumulation need
}
```

Example of what a dynamic model would be built on based on traits (map traits for each characterType) (again traits can be through vocation, age, gender etc.):
- Ambitious: +15 socialStatus, +10 shinyObjects
- Content: -20 socialStatus, -15 exoticGoods
- Paranoid: +25 safety
- Artistic: +30 psychological, +15 exoticGoods
- Frugal: -20 exoticGoods, -20 shinyObjects
- Vain: +25 socialStatus, +15 touch

Example of what a dynamic model would be built on based on vocations:
- Miner: Needs more biological → so more food
- Teacher: Needs more psychological → so more books
- Preacher: Needs high psychological, high socialStatus
- Doctor: Needs safety (medicine), psychological (books)

**7th Step (Building)** → Building Logic and Data to be mapped (human intensive, time consuming task)

Building requirements:
- Input requirements (from inventory, which is, in a way partially implemented, but has to be rechecked, verified and discussed)
- Output produced (added to inventory)
- Production rate (time per unit, also dynamic rules dependent on average satisfaction of workers, aggregate satisfaction of town, season will also have to be factored in)
- Worker requirement (Quantum, and exact specifications which affects rate)
- Worker Wages and Bonus System

Example of Building Logic:
```
SAWMILL:
inputs = { timber = 1 },
outputs = { planks = 4 },
productionTime = 60 seconds,
workersRequired = 2,
workerBonus = 0.2 per worker (faster production)
```

**8th Step** → Mapping Building Output to Craving Satisfaction (map these using Claude, and create a master list)

**Building → Primary Output with Quality Tier (Primary Craving) + Secondary Output with Quality Tier (Secondary Craving) + ….**

- Farm → biological (produces grains)
- Bakery → biological (produces bread)
- Textile Mill → touch (produces thread/cloth)
- Tailor Shop → touch + socialStatus (produces clothes)
- Police Station → safety (provides security)
- School → psychological (provides education)
- Market → exoticGoods + shinyObjects (enables trade)

**Some buildings satisfy cravings just by existing:**
- Police Station: +10 safety to all characters within 200 units
- School: +5 psychological to characters with children
- Temple: +10 psychological, +5 socialStatus
- Manor: +30 socialStatus to resident, +5 to neighbors (envy/aspiration)

**Extend CommodityTypes.lua:**
- Add cravingCategories array to each commodity
- Add satisfactionValue (how much it satisfies each craving type)
- Add qualityTier and class restrictions

---

### Task 2: Character Population Integration

**Add to Town.lua:**
- mCharacterPool - active character instances
- mPopulationStats - demographics tracking (also to be used later)
- SpawnInitialPopulation - until we have a proper immigration/emigration working system
- AddCharacter(character) and RemoveCharacter(character) methods

**Extend Character.lua:**
- Add mSatisfactionLevels = {} per craving type (0-100) (this should also match the scoring system)
- Add mPersonalInventory - small storage for consumed goods
- Add Update(dt) - decay satisfaction over time based on character class
- Add ConsumeCommodity() and CalculateHappiness() methods

---

### Task 3: Three-State Game Loop System → Create GameLoop.lua

**State 1: PRODUCTION - Buildings produce resources**
- Enable production for ALL 30+ building types based on recipes
- Workers assigned to buildings for production (currently on the free-agency funda based on the elementary craving background to production background matching system)
- Add resource gathering from nature (forests, mines) (need to discuss)

**State 2: ALLOCATION and CONSUMPTION - Distribute resources to satisfy cravings**
- Create AllocationSystem.lua with priority queue
- Higher-class characters get first pick
- Substitution system for unavailable goods (need not be necessary for this version)

#### How Allocation Should Work in every game loop (some fixed time period?)

**Phase A: Collect Demand**
- Each character generates a "Demand" based on:
  - Current satisfaction levels (which cravings are low?)
  - Class/trait/role modifiers
  - Available personal inventory space (this should only be dependent on size of family home since for now size of business is fixed (should we allow to change that as well?))
  - Priority Layering dependent on class and traits (fixed weightage to class + modified weightage to trait which are unique to each individual)

**Phase B: Sort Priority Queue**
- Sort all demands by:
  - Tier (Tier 1 > Tier 2 > Tier 3 > Tier 4) for each character type and each individual added
  - Character class (Elite > Upper > Middle > Lower) within same tier
  - Satisfaction level (more desperate = higher priority)
  - Tiebreaker logic to be implemented in case of deadlocks or conflicts (which the God should usually solve)

**Phase C: Fulfill Demands (Demand-filling)**
- Process queue in order:
  - Check if requested commodity available in town inventory
    - If yes: Transfer to character's personal inventory, mark satisfied
    - If no: Try substitutions (same tier, lower quality)
    - If still no: Mark as unfulfilled, remember for next game-loop
  - Continue until inventory depleted or queue empty

**Phase D: Consumption & Feedback**
- Characters consume from personal inventory then:
  - Update satisfaction levels for each individual → recalculate and aggregate for each characterType and each characterClass
  - Calculate new (updated) satisfaction level
  - Trigger events (immigration if happy, emigration if unhappy) (check some sort of thresholds here)
  - Re-calculate craving satisfied by each commodity level (decreasing multiplier effect?)

**State 3: CONSEQUENCES - Population reacts to satisfaction**
- High satisfaction → immigration, births and less deaths, improved life span, town growth
- Low satisfaction → emigration, unrest, riots, diseases, bad medical care, more deaths, bad immigration* (maybe later)
- Affects production efficiency (unhappy workers = slower production, more emigration, disease spread)

#### Feedback Loop Calculation (I need to put some work here, avoid for now)

```
For each character, every allocation cycle:
satisfaction = 0
totalWeight = 0

for each cravingType do:
    Priority-based weight = cravingBaseline[cravingType] / 100
    satisfactionScore = character-specific Satisfaction[cravingType]
    aggregate satisfaction += (satisfactionScore * trait-based weights)
end
```

#### Satisfaction Mapping across Each Town (needs to be discussed)

**Individual Character:**
- Satisfaction > 80: Productive worker (+20% production speed), may invite family/friends (immigration - which we will implement later)
- Satisfaction 50-80: Normal, stable
- Satisfaction 30-50: Unhappy, -10% production speed, low chance of emigration
- Satisfaction < 30: Very unhappy, -30% production speed, high chance of emigration
- Satisfaction < 10: Desperate, riot risk (strikes?), will emigrate within 1 game-day (fixed)

**Town-Wide:**
- Average Satisfaction > 70: Immigration rate +2 characters/week, town reputation grows
- Average Satisfaction 40-70: Stable population (equilibrium state or Pax State)
- Average Satisfaction < 40: Emigration rate +1 character/week, reputation declines (immigration declines)
- Average Satisfaction < 20: Crisis mode, riots/strikes possible, buildings may be damaged

#### Handling of adverse consequences (edge-cases: Starvation, Strikes, Plagues)

When resources run out:
- Severe shortage: Emergency alert to player, suggests building more farms/bakeries
- Serious but non-severe shortage: Warning, characters become unhappy
- Routine shortage: Normal, not all luxuries can be satisfied

---

### Task 4: Dynamic Craving System with Substitutions

**Create CravingSystem.lua:**
- Generate daily/hourly craving demands based on character class and for each individual character based on their traits
- Implement dynamic substitution matrix for different character classes separately and different (each) character separately (e.g., if no wheat, try barley → rice → beans) (some funda to be cracked based on demography, geography, proximity to resources/town/population, immigration, costs)
- Quality preferences based on class (eg. Elite won't accept poor-tier goods)
- Seasonal/event variations (festivals increase exoticGoods cravings) (last, and maybe much later)

**Add to CravingDefinitions.lua:**
- Define what does satisfaction in each of 7 craving types (right now, can be implemented via a score, but has to move to a proper thesis of its own)

Examples of each commodity gets spread across craving type and how each can be scored (which again depends on total "town status" - because importance/priority matrix, itself derived from substitution funda, will be dynamic and keep changing). Following example for a Pax time:
- biological: wheat (8/10), water (8/10), medicine (8/10)
- touch: basic clothes (7/10), furniture (6/10)
- psychological: books, art, entertainment
- safety: police presence, walls, weapons
- socialStatus: jewelry, fine_clothes, manor residency
- exoticGoods: spices, wine, imported items
- shinyObjects: gold, silver, decorative items

#### Immigration and Emigration Implementation for Later

**Immigration Trigger:**
- Town average happiness > 70
- Available housing (lodge/home/manor capacity) + Lower Taxes (taxes will be implemented later)
- Random new character spawns based on town's building types (eg. if you have a school, teachers may arrive)

**Emigration Trigger:**
- Individual happiness < 30 for 3+ days
- Character leaves + frees up housing + stops consuming

---

### Task 5: Production-to-Craving Satisfaction → Advanced Techniques and Visualization

**Applying Finite Element Analysis (worthiness of town)** (we will do this after all above steps are done)

How FEA works → Divide → Simplify → Simulate → Integrate → Predict

*How each element, character, building reacts to stress, rewards etc.*

#### Character-level UI Indicators
- Show all characters with color-coded happiness (green/yellow/orange/red)
- Click character (character card) → see their 7 craving bars (Satisfaction 0-100 in each cravingType and an aggregate Satisfaction Score)
- See what they consumed this game loop
- See what they requested but didn't get (unfulfilled) in this game loop

#### Production-level UI Indicators (Create AllocationMenu.lua)
- Production vs Demand Chart: For each commodity, show production rate vs consumption rate
- Shortage Alerts: Red highlights for items with demand > supply
- Surplus Indicators: Green for items with supply > demand (opportunity to trade/export)
- Production Bottle-neck Puzzles (daily) for God

#### Satisfaction and Aggregation UI
- Satisfaction Trends to track new and hot cravings (new, rare, shiny, exotic columns) cravings across towns
- Craving Satisfaction Heatmap: 7 columns (one per craving type), rows = characters, color = satisfaction level
- Population count and trend (↑ growing, ↓ shrinking) - mPopulationStats
- Class distribution (X% Elite, Y% Upper, Z% Middle, W% Lower)
- Top 3 shortages per game loop (overall, by class, by characterType - calculated by unfulfilled craving demand per game loop)
- Top 3 surpluses per game loop (overall, by class, by characterType - calculated by comparing previous and current game loops)

**Just read for now - instructions later.**

---

---

# ACCEPTED IMPLEMENTATION PLAN - Final Version

## Critical Analysis

### Strengths
1. **Parallel Development Smart** - Decoupling consumption (character behavior) from production (building economics) is brilliant. These are genuinely independent concerns until integration.
2. **Information System Foundation** - Starting with a data layer is absolutely correct. This prevents "code first, data later" chaos that plagues most simulation games.
3. **Incremental Complexity** - Deferring geography, immigration, and environmental factors until post-merge is wise. You're building the engine before the scenery.

### Potential Risks & Recommendations

**Risk 1: Data Schema Evolution**
- Your information system will evolve significantly as prototypes reveal edge cases
- **Mitigation**: Use a versioned schema with migration scripts. Each prototype should log "data gaps" they encounter back to the information system team

**Risk 2: Integration Complexity Underestimated**
- Merging two working prototypes is where 70% of unforeseen issues emerge
- **Recommendation**: Define the integration contract NOW
  - What data structures must both prototypes support?
  - What is the common "game tick" structure?
  - How will they share the town inventory state?

**Risk 3: Free Agency Algorithm**
- This appears in both prototypes but isn't fully specified
- **Clarification Needed**:
  - Is this weighted random selection?
  - First-come-first-served with priorities?
  - Auction/bidding system?
  - This needs to be in the Information System as a configurable ruleset

**Risk 4: "Left Menu" UI Coupling**
- Both prototypes have manual input menus that won't exist in final game
- **Suggestion**: Abstract these as "God Mode Controls" that can be:
  - Used in prototypes via UI
  - Driven by game logic in production
  - Useful for debugging/balancing post-launch

**Risk 5: Satisfaction Feedback Loop Missing from Prototype 2**
- Prototype 2 has "mean satisfaction slider" but doesn't model how production affects satisfaction
- **Gap**: How do you test "unhappy workers produce 30% less" without character models?
- **Solution**: Prototype 2 should stub character satisfaction with simple statistical distributions

**Risk 6: Testing Strategy Unclear**
- How do you validate each prototype works before merge?
- **Need**: Define success criteria
  - Prototype 1: "100 characters run for 50 cycles without crashes, emigration triggers correctly"
  - Prototype 2: "All 30 buildings produce at expected rates under varying worker scenarios"

---

## Architecture Suggestion: The "Shared State Contract"

Before developers split, define this strictly:

```lua
-- TownState.lua (shared by both prototypes)
TownState = {
    inventory = {},        -- All commodities available
    buildings = {},        -- All structures (P2 writes, P1 reads for employment)
    characters = {},       -- All people (P1 writes, P2 reads for labor)
    currentCycle = 0,      -- Game tick counter
    globalModifiers = {}   -- Weather, events, etc (empty in prototypes)
}
```

Both prototypes should be able to:
- Save TownState to JSON
- Load TownState from JSON
- Run independently with mocked data for the other half

This makes integration literally just connecting two state machines.

---

## Ultra-Detailed Breakdown for Team

### Phase 0: Foundation (Week 1-2)
**Team: Full Team Collaboration**

#### Deliverable 0.1: Information System Core

```
Structure:
/data
  /commodities
    - commodities.json (120 items, initial pass)
    - craving_mappings.json (commodity → craving types)
    - quality_tiers.json (poor/basic/good/luxury per commodity)
    - substitution_rules.json (within-category + cross-category)
  /characters
    - character_classes.json (Elite/Upper/Middle/Lower baselines)
    - character_traits.json (Ambitious, Frugal, etc with modifiers)
    - vocations.json (Miner, Teacher, etc with trait/craving profiles)
  /buildings
    - building_recipes.json (inputs → outputs → time)
    - building_worker_requirements.json
  /systems
    - free_agency_rules.json (HOW characters pick work/goods)
    - satisfaction_decay_rates.json (per class, per craving type)
    - consequence_thresholds.json (riot at <10, emigrate at <30, etc)
```

**Definition of Done**:
- [ ] All JSON schemas validated with example data
- [ ] SQLite schema created with foreign keys enforced
- [ ] Python/Lua script to validate data integrity (no orphaned references)
- [ ] Version 1.0 tagged in git

**Key Decision Point**: JSON vs SQLite?
- **JSON**: Easier to edit manually, better for initial iteration
- **SQLite**: Better for complex queries, necessary if >500 commodities
- **Recommendation**: Start JSON, migrate to SQLite at merge phase

---

### Phase 1: Prototype 1 - Consumption & Character Engine (Week 3-6)
**Team: Developer A + Designer**

#### Module 1.1: Character System Foundation (Week 3)

**File Structure**:
```
/prototype1
  /core
    - Character.lua
    - CharacterPool.lua
    - CravingSystem.lua
  /ui
    - CharacterCanvas.lua (left panel grid)
    - CharacterDetailPopup.lua
    - CravingHeatmap.lua
  /config
    - LoadInfoSystem.lua (reads from /data)
```

**Character.lua Requirements**:

```lua
Character = {
    -- Identity
    id = string,
    name = string,
    class = "Elite"|"Upper"|"Middle"|"Lower",
    vocation = string,
    traits = {string, ...},

    -- State
    satisfaction = {
        biological = 0-100,
        touch = 0-100,
        psychological = 0-100,
        safety = 0-100,
        socialStatus = 0-100,
        exoticGoods = 0-100,
        shinyObjects = 0-100
    },

    personalInventory = {
        [commodityId] = quantity,
        maxCapacity = number  -- based on housing
    },

    employment = {
        building = buildingId or nil,
        wage = number
    },

    residence = {
        building = buildingId or nil,
        quality = "Poor"|"Lodge"|"Home"|"Manor"
    },

    -- History (for debugging)
    satisfactionHistory = {},  -- last 10 cycles
    consumptionLog = {}        -- what consumed this cycle
}

function Character:Update(dt)
    -- Decay satisfaction based on class + traits
    -- Trigger emigration if < threshold for N cycles
end

function Character:GenerateCravingDemand()
    -- Returns prioritized list of {commodityId, quantity, priority}
end

function Character:ConsumeCommodity(commodityId, quality)
    -- Update satisfaction, remove from personalInventory
end

function Character:CalculateAggregateSatisfaction()
    -- Weighted average of 7 craving types
end
```

**Definition of Done**:
- [ ] Can spawn 100+ characters with random traits
- [ ] Satisfaction decays correctly over time
- [ ] Character cards display in grid
- [ ] Clicking card shows popup with all stats

---

#### Module 1.2: Free Agency & Allocation (Week 4)

**File**: `AllocationSystem.lua`

```lua
AllocationSystem = {}

function AllocationSystem:RunCycle(townState)
    -- Phase A: Collect Demand
    local demands = {}
    for _, char in ipairs(townState.characters) do
        local charDemands = char:GenerateCravingDemand()
        for _, demand in ipairs(charDemands) do
            table.insert(demands, {
                character = char,
                commodity = demand.commodity,
                quantity = demand.quantity,
                priority = self:CalculatePriority(char, demand)
            })
        end
    end

    -- Phase B: Sort by Priority
    table.sort(demands, function(a, b)
        return a.priority > b.priority
    end)

    -- Phase C: Fulfill Demands
    for _, demand in ipairs(demands) do
        if townState.inventory[demand.commodity] >= demand.quantity then
            -- Transfer to character
            -- Try substitution if needed
            -- Log fulfillment
        else
            -- Log unfulfilled demand
        end
    end

    -- Phase D: Consumption
    for _, char in ipairs(townState.characters) do
        char:ConsumeFromInventory()
        char:Update(dt)
    end
end

function AllocationSystem:CalculatePriority(character, demand)
    -- Class weight (Elite=4, Upper=3, Middle=2, Lower=1)
    -- Craving tier weight (Survival=4, Safety=3, Social=2, Luxury=1)
    -- Desperation multiplier (low satisfaction = higher priority)
    return score
end
```

**UI: Resource Control Panel (Left Menu)**

```
/ui/ResourceControlPanel.lua

Components:
- Commodity input table (add any commodity with quantity)
- Housing availability (Lodge x5, Home x10, Manor x2)
- Employment slots (Building list with open positions)
- "Run Cycle" button (advances 1 game tick)
- Cycle counter display
```

**Definition of Done**:
- [ ] Characters pick from available inventory correctly
- [ ] Priority queue respects class + desperation
- [ ] Substitution works (if no wheat, try barley)
- [ ] Unfulfilled demands logged per cycle

---

#### Module 1.3: Consequence System (Week 5)

**File**: `ConsequenceSystem.lua`

```lua
ConsequenceSystem = {}

function ConsequenceSystem:EvaluateCharacter(character)
    local sat = character:CalculateAggregateSatisfaction()

    if sat < 10 then
        -- CRITICAL: Immediate emigration risk
        if math.random() < 0.8 then  -- 80% chance to leave
            return "EMIGRATE"
        else
            return "RIOT"
        end
    elseif sat < 30 then
        -- UNHAPPY: Slow emigration
        if math.random() < 0.1 then  -- 10% chance per cycle
            return "EMIGRATE"
        end
    elseif sat < 50 then
        -- NEUTRAL: Productivity penalty
        character.productivityModifier = 0.9
    elseif sat > 80 then
        -- HAPPY: Productivity bonus
        character.productivityModifier = 1.2
    end

    return "STABLE"
end

function ConsequenceSystem:EvaluateTown(townState)
    local avgSatisfaction = self:CalculateAverageSatisfaction(townState)

    if avgSatisfaction < 20 then
        -- CRISIS: Riots, building damage
        self:TriggerRandomRiot(townState)
    elseif avgSatisfaction < 40 then
        -- DECLINING: Emigration wave
        -- (Will be used post-merge for immigration)
    end
end
```

**UI: Consequence Visualizations**

```
- Popup alerts: "John Smith is RIOTING!"
- Character card color coding:
  - Green: Happy (>80)
  - Yellow: Neutral (50-80)
  - Orange: Unhappy (30-50)
  - Red: Critical (<30)
- Town-wide satisfaction gauge (top of screen)
```

**Definition of Done**:
- [ ] Characters emigrate when satisfaction < 30 for 3 cycles
- [ ] Riots trigger when town avg < 20
- [ ] Color-coded character cards update in real-time
- [ ] Emigration frees up housing/employment slots

---

#### Module 1.4: Analytics & Grouping (Week 6)

**File**: `AnalyticsSystem.lua`

```lua
AnalyticsSystem = {}

function AnalyticsSystem:GetCravingsByClass()
    -- Returns { Elite: {bio: 45, touch: 70, ...}, Upper: {...}, ... }
end

function AnalyticsSystem:GetCravingsByVocation()
    -- Returns { Miner: {bio: 80, ...}, Teacher: {psy: 60, ...} }
end

function AnalyticsSystem:GetCravingsByRegion()
    -- (Stub for now, returns dummy data)
    -- Will be real post-merge when geography exists
end

function AnalyticsSystem:GetTopShortages(n)
    -- Returns top N most unfulfilled commodities this cycle
end
```

**UI: Analytics Dashboard**

```
/ui/AnalyticsDashboard.lua

Tabs:
1. Individual View (existing character cards)
2. Class View (Elite/Upper/Middle/Lower aggregate bars)
3. Vocation View (Miner/Teacher/etc aggregate bars)
4. Heatmap View (7 columns × N characters, color = satisfaction)
5. Shortage Report (top 3 unfulfilled demands)
```

**Definition of Done**:
- [ ] Can switch between 5 view tabs
- [ ] Heatmap updates every cycle
- [ ] Shortage report highlights critical items
- [ ] Export data to CSV for analysis

---

### Phase 2: Prototype 2 - Production Engine (Week 3-6)
**Team: Developer B**

#### Module 2.1: Building System (Week 3)

**File Structure**:
```
/prototype2
  /core
    - Building.lua
    - ProductionSystem.lua
    - WorkforceManager.lua
  /ui
    - BuildingCanvas.lua (building cards)
    - ProductionTrendsPanel.lua
    - WorkforceControlPanel.lua (left menu)
```

**Building.lua Requirements**:

```lua
Building = {
    id = string,
    type = "Farm"|"Bakery"|"Sawmill"|...,

    recipe = {
        inputs = { [commodityId] = quantity },
        outputs = { [commodityId] = quantity },
        productionTime = seconds
    },

    workforce = {
        assigned = {workerId, ...},
        required = number,
        efficiency = 0-1.0  -- based on satisfaction
    },

    state = "IDLE"|"PRODUCING"|"BLOCKED",
    productionProgress = 0-100,

    outputHistory = {}  -- last 20 cycles
}

function Building:Update(dt)
    if self.state == "PRODUCING" then
        self.productionProgress += dt / self.recipe.productionTime
        if self.productionProgress >= 1.0 then
            self:CompleteProduction()
        end
    end
end

function Building:StartProduction(townInventory)
    -- Check inputs available
    -- Deduct inputs from inventory
    -- Start timer
end

function Building:CompleteProduction(townInventory)
    -- Add outputs to inventory
    -- Log to outputHistory
    -- Reset state
end

function Building:CalculateEfficiency()
    -- Based on:
    -- 1. Worker satisfaction (from slider in prototype)
    -- 2. Worker count (bonus per worker)
    return baseEfficiency * workerBonus * satisfactionModifier
end
```

**Definition of Done**:
- [ ] All 30+ building types load from building_recipes.json
- [ ] Production cycles complete correctly
- [ ] Efficiency modifier affects production time
- [ ] Buildings block when inputs unavailable

---

#### Module 2.2: Workforce Management (Week 4)

**File**: `WorkforceManager.lua`

```lua
WorkforceManager = {}

function WorkforceManager:AssignWorker(worker, building, mode)
    if mode == "FREE_AGENCY" then
        -- Worker chooses based on:
        -- 1. Vocation match (Miner prefers Mine)
        -- 2. Wage (if implemented)
        -- 3. Distance (stub for now)
        building = self:BestMatchBuilding(worker)
    else
        -- Manual assignment (from UI)
    end

    building.workforce.assigned:insert(worker.id)
    worker.employment = building.id
end

function WorkforceManager:BestMatchBuilding(worker)
    -- Read from free_agency_rules.json
    -- Return building with highest score
end
```

**UI: Workforce Control Panel**

```
/ui/WorkforceControlPanel.lua

Components:
- Worker pool table:
  - [Add Worker] button
  - Columns: Name, Vocation, Assigned Building
- Free Agency toggle (ON/OFF)
- Satisfaction slider (0-100, affects all workers)
- Auto-assign button (distributes workers optimally)
```

**Definition of Done**:
- [ ] Can add workers manually or batch-create
- [ ] Free agency assigns workers to appropriate buildings
- [ ] Manual assignment overrides free agency
- [ ] Satisfaction slider affects production efficiency

---

#### Module 2.3: Production Trends & Analytics (Week 5-6)

**File**: `ProductionAnalytics.lua`

```lua
ProductionAnalytics = {}

function ProductionAnalytics:GetOutputTrends(buildingType)
    -- Returns time-series data for last 50 cycles
    return {
        cycles = {1, 2, 3, ...},
        outputs = {10, 12, 11, ...}
    }
end

function ProductionAnalytics:GetBottlenecks()
    -- Returns buildings that are:
    -- 1. BLOCKED most often (input shortage)
    -- 2. Underutilized (not enough workers)
    -- 3. Overproducing (outputs not consumed)
end

function ProductionAnalytics:GetEfficiencyReport()
    -- Per building: actual output vs theoretical max
end
```

**UI: Production Trends Panel**

```
/ui/ProductionTrendsPanel.lua

Sections:
1. Line chart: Output over time (per building type)
2. Bar chart: Efficiency comparison (all buildings)
3. Alert panel: Bottlenecks & warnings
4. Inventory levels: Current stock vs production rate
```

**Definition of Done**:
- [ ] Charts update in real-time every cycle
- [ ] Bottleneck detection highlights issues
- [ ] Can export trends to CSV
- [ ] Visual indicators for production health

---

### Phase 3: Integration (Week 7-9)
**Team: Both Developers + Full Team Testing**

#### Week 7: Shared State Unification

**Critical Files to Create**:
```
/integration
  - TownState.lua (canonical state manager)
  - StateSerializer.lua (save/load JSON)
  - IntegrationTests.lua (validate both prototypes work together)
```

**Integration Contract**:

```lua
-- Both prototypes must implement:
function Prototype:SaveState()
    return {
        version = "1.0",
        characters = {...},
        buildings = {...},
        inventory = {...},
        cycle = number
    }
end

function Prototype:LoadState(state)
    -- Reconstruct from state
end
```

**Integration Checklist**:
- [ ] Prototype 1 loads buildings from Prototype 2's save
- [ ] Prototype 2 loads characters from Prototype 1's save
- [ ] Characters can work at buildings and affect production
- [ ] Buildings produce goods that characters consume
- [ ] Complete 100 cycles end-to-end without errors

---

#### Week 8-9: Three-Loop Implementation

**Create**: `GameLoop.lua`

```lua
GameLoop = {
    state = "PRODUCTION",  -- or "ALLOCATION" or "CONSEQUENCES"
    cycleTime = 60 seconds  -- configurable
}

function GameLoop:RunCycle()
    -- State 1: Production (Prototype 2 logic)
    ProductionSystem:ProduceAll(townState)

    -- State 2: Allocation (Prototype 1 logic)
    AllocationSystem:RunCycle(townState)

    -- State 3: Consequences (Prototype 1 logic)
    ConsequenceSystem:Evaluate(townState)

    -- Feedback loop
    self:UpdateProductionEfficiency(townState)

    self.cycle += 1
end

function GameLoop:UpdateProductionEfficiency(townState)
    for _, building in ipairs(townState.buildings) do
        local avgWorkerSatisfaction = self:GetWorkerSatisfaction(building)
        building.efficiencyModifier = self:CalculateEfficiency(avgWorkerSatisfaction)
    end
end
```

**Definition of Done**:
- [ ] All three phases run sequentially
- [ ] Unhappy workers reduce production efficiency
- [ ] Production feeds consumption feeds satisfaction feeds production
- [ ] Stable equilibrium possible (town doesn't collapse or explode)

---

### Phase 4: Geography & Final Features (Week 10-12)

Now Safe to Add:
- Character movement on map
- Building placement/construction
- Immigration system (arrivals based on town happiness)
- Weather effects on production
- Random events (disasters, festivals)

---

## Team Split Recommendations

**Developer A (Prototype 1) Skills Needed**:
- Strong in state management (many characters, tracking history)
- UI/UX focus (dashboards, analytics, heatmaps)
- Algorithms (priority queues, sorting, grouping)

**Developer B (Prototype 2) Skills Needed**:
- Systems programming (production pipelines, efficiency calculations)
- Data structures (building recipes, worker assignments)
- Performance optimization (30+ buildings running in parallel)

**Shared Responsibilities**:
- Both must understand the Information System thoroughly
- Both must write integration tests for their modules
- Weekly sync: "Does my state structure match yours?"

---

## Success Metrics (Pre-Merge)

**Prototype 1 Ready When**:
- [ ] 100 characters run for 100 cycles without crashes
- [ ] Emigration triggers appropriately
- [ ] All 7 craving types decay and refill correctly
- [ ] Heatmap shows meaningful patterns

**Prototype 2 Ready When**:
- [ ] All buildings produce at correct rates
- [ ] Worker efficiency affects output measurably
- [ ] Bottleneck detection identifies real issues
- [ ] Can run 1000 cycles and generate meaningful trends

**Integration Ready When**:
- [ ] 100 characters + 30 buildings run 100 cycles
- [ ] Production → consumption → satisfaction → production loop is stable
- [ ] No memory leaks or performance degradation
- [ ] Data exports allow balancing analysis

---

## Risk Mitigation Checklist

**Before split**:
- [ ] All three teams agree on JSON schemas
- [ ] TownState structure locked in writing
- [ ] Free agency algorithm specified (not just "free agency")
- [ ] Integration success criteria defined
- [ ] Weekly sync meetings scheduled

**During development**:
- [ ] Daily: Both devs push to Git (avoid divergence)
- [ ] Weekly: Cross-prototype code review
- [ ] Bi-weekly: Try loading each other's state files

---

## FINAL EXECUTION ORDER

**The accepted plan is to build in this order:**

1. **Parallel Tackling → Production Simulation**
2. **Parallel Tackling → Consumption Simulation**
   - with Probabilistic Craving Patterns
3. **Parallel Tackling → Allocation Simulation**
4. **Building Substitution Rules**
5. **Building Consequences and Game Loop**
   - where satisfaction scale is relative and keeps rebalancing
   - should also be dependent on, apart from other things mentioned, **Neighbours**
6. **Building Immigration and Character Pools**
7. **Building Market, Currency and Transaction**
8. **Consolidating all of the above**

**Production simulation will come first.**

---

*This plan is exceptionally solid. The instinct to build the information layer first and split into parallel prototypes is exactly right. The main addition is formalizing the "integration contract" early so both developers are building toward a common interface, not just two separate games.*


<!-- TRIGGER.DEV advanced-tasks START -->
# Trigger.dev Advanced Tasks (v4)

**Advanced patterns and features for writing tasks**

## Tags & Organization

```ts
import { task, tags } from "@trigger.dev/sdk";

export const processUser = task({
  id: "process-user",
  run: async (payload: { userId: string; orgId: string }, { ctx }) => {
    // Add tags during execution
    await tags.add(`user_${payload.userId}`);
    await tags.add(`org_${payload.orgId}`);

    return { processed: true };
  },
});

// Trigger with tags
await processUser.trigger(
  { userId: "123", orgId: "abc" },
  { tags: ["priority", "user_123", "org_abc"] } // Max 10 tags per run
);

// Subscribe to tagged runs
for await (const run of runs.subscribeToRunsWithTag("user_123")) {
  console.log(`User task ${run.id}: ${run.status}`);
}
```

**Tag Best Practices:**

- Use prefixes: `user_123`, `org_abc`, `video:456`
- Max 10 tags per run, 1-64 characters each
- Tags don't propagate to child tasks automatically

## Concurrency & Queues

```ts
import { task, queue } from "@trigger.dev/sdk";

// Shared queue for related tasks
const emailQueue = queue({
  name: "email-processing",
  concurrencyLimit: 5, // Max 5 emails processing simultaneously
});

// Task-level concurrency
export const oneAtATime = task({
  id: "sequential-task",
  queue: { concurrencyLimit: 1 }, // Process one at a time
  run: async (payload) => {
    // Critical section - only one instance runs
  },
});

// Per-user concurrency
export const processUserData = task({
  id: "process-user-data",
  run: async (payload: { userId: string }) => {
    // Override queue with user-specific concurrency
    await childTask.trigger(payload, {
      queue: {
        name: `user-${payload.userId}`,
        concurrencyLimit: 2,
      },
    });
  },
});

export const emailTask = task({
  id: "send-email",
  queue: emailQueue, // Use shared queue
  run: async (payload: { to: string }) => {
    // Send email logic
  },
});
```

## Error Handling & Retries

```ts
import { task, retry, AbortTaskRunError } from "@trigger.dev/sdk";

export const resilientTask = task({
  id: "resilient-task",
  retry: {
    maxAttempts: 10,
    factor: 1.8, // Exponential backoff multiplier
    minTimeoutInMs: 500,
    maxTimeoutInMs: 30_000,
    randomize: false,
  },
  catchError: async ({ error, ctx }) => {
    // Custom error handling
    if (error.code === "FATAL_ERROR") {
      throw new AbortTaskRunError("Cannot retry this error");
    }

    // Log error details
    console.error(`Task ${ctx.task.id} failed:`, error);

    // Allow retry by returning nothing
    return { retryAt: new Date(Date.now() + 60000) }; // Retry in 1 minute
  },
  run: async (payload) => {
    // Retry specific operations
    const result = await retry.onThrow(
      async () => {
        return await unstableApiCall(payload);
      },
      { maxAttempts: 3 }
    );

    // Conditional HTTP retries
    const response = await retry.fetch("https://api.example.com", {
      retry: {
        maxAttempts: 5,
        condition: (response, error) => {
          return response?.status === 429 || response?.status >= 500;
        },
      },
    });

    return result;
  },
});
```

## Machines & Performance

```ts
export const heavyTask = task({
  id: "heavy-computation",
  machine: { preset: "large-2x" }, // 8 vCPU, 16 GB RAM
  maxDuration: 1800, // 30 minutes timeout
  run: async (payload, { ctx }) => {
    // Resource-intensive computation
    if (ctx.machine.preset === "large-2x") {
      // Use all available cores
      return await parallelProcessing(payload);
    }

    return await standardProcessing(payload);
  },
});

// Override machine when triggering
await heavyTask.trigger(payload, {
  machine: { preset: "medium-1x" }, // Override for this run
});
```

**Machine Presets:**

- `micro`: 0.25 vCPU, 0.25 GB RAM
- `small-1x`: 0.5 vCPU, 0.5 GB RAM (default)
- `small-2x`: 1 vCPU, 1 GB RAM
- `medium-1x`: 1 vCPU, 2 GB RAM
- `medium-2x`: 2 vCPU, 4 GB RAM
- `large-1x`: 4 vCPU, 8 GB RAM
- `large-2x`: 8 vCPU, 16 GB RAM

## Idempotency

```ts
import { task, idempotencyKeys } from "@trigger.dev/sdk";

export const paymentTask = task({
  id: "process-payment",
  retry: {
    maxAttempts: 3,
  },
  run: async (payload: { orderId: string; amount: number }) => {
    // Automatically scoped to this task run, so if the task is retried, the idempotency key will be the same
    const idempotencyKey = await idempotencyKeys.create(`payment-${payload.orderId}`);

    // Ensure payment is processed only once
    await chargeCustomer.trigger(payload, {
      idempotencyKey,
      idempotencyKeyTTL: "24h", // Key expires in 24 hours
    });
  },
});

// Payload-based idempotency
import { createHash } from "node:crypto";

function createPayloadHash(payload: any): string {
  const hash = createHash("sha256");
  hash.update(JSON.stringify(payload));
  return hash.digest("hex");
}

export const deduplicatedTask = task({
  id: "deduplicated-task",
  run: async (payload) => {
    const payloadHash = createPayloadHash(payload);
    const idempotencyKey = await idempotencyKeys.create(payloadHash);

    await processData.trigger(payload, { idempotencyKey });
  },
});
```

## Metadata & Progress Tracking

```ts
import { task, metadata } from "@trigger.dev/sdk";

export const batchProcessor = task({
  id: "batch-processor",
  run: async (payload: { items: any[] }, { ctx }) => {
    const totalItems = payload.items.length;

    // Initialize progress metadata
    metadata
      .set("progress", 0)
      .set("totalItems", totalItems)
      .set("processedItems", 0)
      .set("status", "starting");

    const results = [];

    for (let i = 0; i < payload.items.length; i++) {
      const item = payload.items[i];

      // Process item
      const result = await processItem(item);
      results.push(result);

      // Update progress
      const progress = ((i + 1) / totalItems) * 100;
      metadata
        .set("progress", progress)
        .increment("processedItems", 1)
        .append("logs", `Processed item ${i + 1}/${totalItems}`)
        .set("currentItem", item.id);
    }

    // Final status
    metadata.set("status", "completed");

    return { results, totalProcessed: results.length };
  },
});

// Update parent metadata from child task
export const childTask = task({
  id: "child-task",
  run: async (payload, { ctx }) => {
    // Update parent task metadata
    metadata.parent.set("childStatus", "processing");
    metadata.root.increment("childrenCompleted", 1);

    return { processed: true };
  },
});
```

## Advanced Triggering

### Frontend Triggering (React)

```tsx
"use client";
import { useTaskTrigger } from "@trigger.dev/react-hooks";
import type { myTask } from "../trigger/tasks";

function TriggerButton({ accessToken }: { accessToken: string }) {
  const { submit, handle, isLoading } = useTaskTrigger<typeof myTask>("my-task", { accessToken });

  return (
    <button onClick={() => submit({ data: "from frontend" })} disabled={isLoading}>
      Trigger Task
    </button>
  );
}
```

### Large Payloads

```ts
// For payloads > 512KB (max 10MB)
export const largeDataTask = task({
  id: "large-data-task",
  run: async (payload: { dataUrl: string }) => {
    // Trigger.dev automatically handles large payloads
    // For > 10MB, use external storage
    const response = await fetch(payload.dataUrl);
    const largeData = await response.json();

    return { processed: largeData.length };
  },
});

// Best practice: Use presigned URLs for very large files
await largeDataTask.trigger({
  dataUrl: "https://s3.amazonaws.com/bucket/large-file.json?presigned=true",
});
```

### Advanced Options

```ts
await myTask.trigger(payload, {
  delay: "2h30m", // Delay execution
  ttl: "24h", // Expire if not started within 24 hours
  priority: 100, // Higher priority (time offset in seconds)
  tags: ["urgent", "user_123"],
  metadata: { source: "api", version: "v2" },
  queue: {
    name: "priority-queue",
    concurrencyLimit: 10,
  },
  idempotencyKey: "unique-operation-id",
  idempotencyKeyTTL: "1h",
  machine: { preset: "large-1x" },
  maxAttempts: 5,
});
```

## Hidden Tasks

```ts
// Hidden task - not exported, only used internally
const internalProcessor = task({
  id: "internal-processor",
  run: async (payload: { data: string }) => {
    return { processed: payload.data.toUpperCase() };
  },
});

// Public task that uses hidden task
export const publicWorkflow = task({
  id: "public-workflow",
  run: async (payload: { input: string }) => {
    // Use hidden task internally
    const result = await internalProcessor.triggerAndWait({
      data: payload.input,
    });

    if (result.ok) {
      return { output: result.output.processed };
    }

    throw new Error("Internal processing failed");
  },
});
```

## Logging & Tracing

```ts
import { task, logger } from "@trigger.dev/sdk";

export const tracedTask = task({
  id: "traced-task",
  run: async (payload, { ctx }) => {
    logger.info("Task started", { userId: payload.userId });

    // Custom trace with attributes
    const user = await logger.trace(
      "fetch-user",
      async (span) => {
        span.setAttribute("user.id", payload.userId);
        span.setAttribute("operation", "database-fetch");

        const userData = await database.findUser(payload.userId);
        span.setAttribute("user.found", !!userData);

        return userData;
      },
      { userId: payload.userId }
    );

    logger.debug("User fetched", { user: user.id });

    try {
      const result = await processUser(user);
      logger.info("Processing completed", { result });
      return result;
    } catch (error) {
      logger.error("Processing failed", {
        error: error.message,
        userId: payload.userId,
      });
      throw error;
    }
  },
});
```

## Usage Monitoring

```ts
import { task, usage } from "@trigger.dev/sdk";

export const monitoredTask = task({
  id: "monitored-task",
  run: async (payload) => {
    // Get current run cost
    const currentUsage = await usage.getCurrent();
    logger.info("Current cost", {
      costInCents: currentUsage.costInCents,
      durationMs: currentUsage.durationMs,
    });

    // Measure specific operation
    const { result, compute } = await usage.measure(async () => {
      return await expensiveOperation(payload);
    });

    logger.info("Operation cost", {
      costInCents: compute.costInCents,
      durationMs: compute.durationMs,
    });

    return result;
  },
});
```

## Run Management

```ts
// Cancel runs
await runs.cancel("run_123");

// Replay runs with same payload
await runs.replay("run_123");

// Retrieve run with cost details
const run = await runs.retrieve("run_123");
console.log(`Cost: ${run.costInCents} cents, Duration: ${run.durationMs}ms`);
```

## Best Practices

- **Concurrency**: Use queues to prevent overwhelming external services
- **Retries**: Configure exponential backoff for transient failures
- **Idempotency**: Always use for payment/critical operations
- **Metadata**: Track progress for long-running tasks
- **Machines**: Match machine size to computational requirements
- **Tags**: Use consistent naming patterns for filtering
- **Large Payloads**: Use external storage for files > 10MB
- **Error Handling**: Distinguish between retryable and fatal errors

Design tasks to be stateless, idempotent, and resilient to failures. Use metadata for state tracking and queues for resource management.

<!-- TRIGGER.DEV advanced-tasks END -->