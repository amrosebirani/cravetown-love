# Choice Architecture System Design

**Created:** 2025-01-24
**Status:** Design Document
**Type:** Game Systems Architecture
**Related Documents:**
- [Era Narrative Script](era_narrative_script.md)
- [Era Progression System Design](era_progression_system_design.md)

---

## Table of Contents

1. [Introduction](#introduction)
2. [Core Philosophy](#core-philosophy)
3. [High-Level Architecture](#high-level-architecture)
4. [Data Model Design](#data-model-design)
5. [The Context Object](#the-context-object)
6. [Effect Builders & Composition](#effect-builders--composition)
7. [System Components](#system-components)
8. [Cross-Choice Influence](#cross-choice-influence)
9. [First-Order vs Second-Order Effects](#first-order-vs-second-order-effects)
10. [Implementation Priority](#implementation-priority)
11. [Key Design Principles](#key-design-principles)

---

## Introduction

This document describes the architecture for Cravetown's narrative choice system - a system that must:

1. Present meaningful choices at specific trigger points
2. Track player decisions persistently across eras
3. Apply immediate consequences (first-order effects)
4. Propagate long-term systemic changes (second-order effects)
5. Create emergent storytelling through accumulated choices

The system uses **lambda-based effects** rather than static data structures, allowing for maximum flexibility and dynamic behavior.

---

## Core Philosophy

### Why Lambda Functions Instead of Static Data?

Instead of:
```lua
-- Static data (limited)
first_order = {
    satisfaction_changes = {
        { target = "all", category = "biological", delta = 2 }
    }
}
```

We use:
```lua
-- Dynamic function (powerful)
first_order = function(ctx)
    -- Can access anything, calculate anything, do anything
    local foodPerPerson = ctx.inventory.food / #ctx.characters
    local delta = math.min(5, foodPerPerson * 0.5)

    for _, char in ipairs(ctx.characters) do
        char:ModifySatisfaction("biological", delta)
    end
end
```

### Comparison Table

| Aspect | Static Data | Lambda Functions |
|--------|-------------|------------------|
| **Flexibility** | Limited to predefined effect types | Can do anything |
| **Context awareness** | Hardcoded values | Dynamic based on game state |
| **Conditional logic** | Requires complex nested structures | Natural if/else |
| **Cross-choice effects** | Difficult to implement | Callbacks and closures |
| **Debugging** | Need to trace through data | Can add print statements |
| **Testing** | Need to mock entire system | Can unit test functions |
| **Composition** | Verbose JSON nesting | Clean function composition |
| **Performance** | Slightly faster parsing | Negligible runtime cost |

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CHOICE ARCHITECTURE OVERVIEW                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐    ┌──────────────┐    ┌───────────────┐                  │
│  │   TRIGGER   │───▶│    CHOICE    │───▶│  CONSEQUENCE  │                  │
│  │   SYSTEM    │    │   RESOLVER   │    │    ENGINE     │                  │
│  └─────────────┘    └──────────────┘    └───────────────┘                  │
│        │                   │                    │                           │
│        │                   │                    │                           │
│        ▼                   ▼                    ▼                           │
│  ┌─────────────┐    ┌──────────────┐    ┌───────────────┐                  │
│  │  Condition  │    │   Player     │    │  First-Order  │                  │
│  │  Evaluator  │    │   History    │    │   Effects     │                  │
│  └─────────────┘    └──────────────┘    └───────────────┘                  │
│                            │                    │                           │
│                            │                    ▼                           │
│                            │           ┌───────────────┐                   │
│                            └──────────▶│ Second-Order  │                   │
│                                        │   Effects     │                   │
│                                        └───────────────┘                   │
│                                                │                           │
│                                                ▼                           │
│                                        ┌───────────────┐                   │
│                                        │  World State  │                   │
│                                        │   Mutation    │                   │
│                                        └───────────────┘                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Choice Lifecycle Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    CHOICE LIFECYCLE FLOW                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   GAME STATE                                                                │
│       │                                                                     │
│       ▼                                                                     │
│   ┌───────────────────┐                                                    │
│   │  Trigger System   │──── Every Cycle ────┐                              │
│   │  evaluates all    │                      │                              │
│   │  choice triggers  │                      │                              │
│   └───────────────────┘                      │                              │
│       │                                      │                              │
│       │ Conditions Met                       │                              │
│       ▼                                      │                              │
│   ┌───────────────────┐                      │                              │
│   │  Choice Modal     │                      │                              │
│   │  presented to     │◀─────────────────────┘                              │
│   │  player           │                                                     │
│   └───────────────────┘                                                     │
│       │                                                                     │
│       │ Player Selects Option                                               │
│       ▼                                                                     │
│   ┌───────────────────┐     ┌───────────────────┐                          │
│   │  First-Order      │────▶│  Immediate        │                          │
│   │  Effects          │     │  - Satisfaction   │                          │
│   │                   │     │  - Resources      │                          │
│   │                   │     │  - Productivity   │                          │
│   │                   │     │  - Deaths/Births  │                          │
│   └───────────────────┘     └───────────────────┘                          │
│       │                                                                     │
│       ▼                                                                     │
│   ┌───────────────────┐     ┌───────────────────┐                          │
│   │  Second-Order     │────▶│  Systemic         │                          │
│   │  Effects          │     │  - Town Values    │                          │
│   │                   │     │  - Memories       │                          │
│   │                   │     │  - Unlocks        │                          │
│   │                   │     │  - Class Tension  │                          │
│   │                   │     │  - Future Mods    │                          │
│   └───────────────────┘     └───────────────────┘                          │
│       │                                                                     │
│       ▼                                                                     │
│   ┌───────────────────┐                                                    │
│   │  Player History   │                                                    │
│   │  Updated          │                                                    │
│   │  - Choice logged  │                                                    │
│   │  - Patterns calc  │                                                    │
│   │  - Values updated │                                                    │
│   └───────────────────┘                                                    │
│       │                                                                     │
│       ▼                                                                     │
│   ┌───────────────────┐     ┌───────────────────┐                          │
│   │  Future Choice    │────▶│  Some choices     │                          │
│   │  Availability     │     │  unlocked/locked  │                          │
│   │  Modified         │     │  based on history │                          │
│   └───────────────────┘     └───────────────────┘                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Model Design

### 1. Choice Definition Structure

Choices are defined as Lua modules with lambda functions for triggers and effects:

```lua
-- data/alpha/narrative/choices/settlement_era.lua

local SettlementChoices = {}

SettlementChoices.hungry_week = {
    id = "hungry_week",
    era = "settlement",

    -- TRIGGER: Function for maximum flexibility
    trigger = function(ctx)
        return ctx.inventory.food < 10
           and ctx:CyclesSince("food_above_10") >= 3
           and ctx.era == "settlement"
           and not ctx.history:HasMadeChoice("hungry_week")
    end,

    -- PRESENTATION
    presentation = {
        title = "The Hungry Week",
        narrative = function(ctx)
            -- Dynamic narrative based on state
            local days = ctx:CyclesSince("food_above_10")
            local hungriest = ctx:GetMostDesperateCharacter()

            return string.format([[
The grain stores have been empty for %d days.

%s approaches you with hollow eyes:
"My children haven't eaten since yesterday. Please... is there nothing left?"

You look at the inventory. %d scraps of bread remain.
Enough for some. Not enough for all.
            ]], days, hungriest.name, ctx.inventory.bread or 0)
        end,
        speaker = function(ctx)
            return ctx:GetMostDesperateCharacter()
        end,
        mood = "crisis"
    },

    -- OPTIONS with lambda effects
    options = {
        -- See detailed option definitions below
    },

    -- Meta configuration
    weight = 100,
    timeout = nil,
    default_option = "ration_equally"
}

return SettlementChoices
```

### 2. Option Definition with Lambda Effects

Each option contains lambda functions for availability, preview, and effects:

```lua
{
    id = "ration_equally",
    label = "Ration equally",
    description = "Everyone gets the same, even if it's little",
    tags = { "egalitarian", "fair" },

    -- Requirements as function
    available = function(ctx)
        return true  -- Always available
    end,

    -- Preview what will happen (shown to player before choosing)
    preview = function(ctx)
        local perPerson = math.floor(ctx.inventory.food / #ctx.characters)
        return {
            "Each person receives " .. perPerson .. " food",
            "All citizens: +2 biological satisfaction",
            "Town value: +10 egalitarianism"
        }
    end,

    -- FIRST ORDER: Immediate effects
    first_order = function(ctx)
        local food = ctx.inventory.food
        local perPerson = math.floor(food / #ctx.characters)

        -- Distribute food
        ctx.inventory.food = food % #ctx.characters  -- Remainder stays

        -- Everyone gets a small boost
        for _, char in ipairs(ctx.characters) do
            char:ModifySatisfaction("biological", 2)
            char:AddToPersonalInventory("food", perPerson)

            -- Memory: "We shared equally during the hungry week"
            char:AddMemory({
                event = "hungry_week",
                type = "shared_equally",
                sentiment = "solidarity",
                cycle = ctx.cycle
            })
        end

        ctx:SetFlag("chose_equality_hungry_week")
        ctx:Log("Distributed %d food equally among %d citizens", food, #ctx.characters)
    end,

    -- SECOND ORDER: Systemic/delayed effects
    second_order = function(ctx)
        -- Town values shift
        ctx.values:Modify("egalitarianism", 10)
        ctx.values:Modify("community_cohesion", 5)

        -- Future choice weighting
        ctx.history:AddModifier({
            id = "equality_precedent",
            type = "choice_affinity",
            -- Future egalitarian choices feel more natural
            apply = function(choice, option)
                if option.tags and option.tags.egalitarian then
                    return { weight_bonus = 0.2, reason = "You've chosen equality before" }
                end
            end,
            duration = "permanent"
        })

        -- Immigration effect: Attract community-minded people
        ctx:ScheduleEffect(20, function(futureCtx)
            if futureCtx.values.egalitarianism > 20 then
                futureCtx.immigration:AddApplicant({
                    name = "Community-minded immigrant",
                    traits = { "cooperative", "humble" },
                    reason = "Heard of your fair treatment during hardship"
                })
            end
        end)
    end
}
```

### 3. Complex Option: Prioritize Children

```lua
{
    id = "prioritize_children",
    label = "Prioritize children",
    description = "They need it most",
    tags = { "family_focused", "protective" },

    available = function(ctx)
        return ctx:HasFamiliesWithChildren()
    end,

    preview = function(ctx)
        local families = ctx:GetFamiliesWithChildren()
        local workers = ctx:GetWorkers()
        return {
            #families .. " families with children receive full rations",
            "Workers receive nothing",
            "Worker productivity: -10% for 5 cycles"
        }
    end,

    first_order = function(ctx)
        local families = ctx:GetFamiliesWithChildren()
        local workers = ctx:GetWorkers()
        local totalFood = ctx.inventory.food

        -- Calculate fair share for families
        local familyShare = math.floor(totalFood / #families)

        for _, family in ipairs(families) do
            for _, member in ipairs(family.members) do
                member:ModifySatisfaction("biological", 5)
                member:AddMemory({
                    event = "hungry_week",
                    type = "children_fed",
                    sentiment = "grateful",
                    cycle = ctx.cycle
                })
            end
        end

        -- Workers go hungry
        for _, worker in ipairs(workers) do
            if not worker:HasChildren() then
                worker:ModifySatisfaction("biological", -3)

                -- Sentiment depends on worker personality
                local sentiment = "resentful"
                if worker:HasTrait("selfless") or worker:HasTrait("family_oriented") then
                    sentiment = "understanding"
                end

                worker:AddMemory({
                    event = "hungry_week",
                    type = "went_hungry_for_children",
                    sentiment = sentiment,
                    cycle = ctx.cycle
                })
            end
        end

        -- Productivity penalty
        ctx:AddTemporaryModifier({
            id = "hungry_workers",
            target = "workers_without_children",
            type = "productivity",
            modifier = 0.9,
            duration = 5,
            reason = "Workers are weakened from hunger"
        })

        ctx.inventory.food = 0
        ctx:SetFlag("chose_children_priority_hungry_week")
    end,

    second_order = function(ctx)
        ctx.values:Modify("family_focus", 15)
        ctx.values:Modify("worker_solidarity", -5)

        -- Class tension tracking
        ctx.tension:AddIncident({
            between = { "workers", "families" },
            severity = 5,
            cause = "hungry_week_food_priority",
            decay_rate = 0.5  -- per cycle
        })

        -- This choice enables future "child welfare" choices
        ctx.history:UnlockChoice("establish_child_welfare")

        -- Workers with "resentful" memory may reference this later
        ctx:RegisterCallback("worker_grievance_choice", function(grievanceCtx)
            local resentful = grievanceCtx:CountCharactersWithMemory(
                "went_hungry_for_children", "resentful"
            )
            if resentful > 3 then
                return {
                    extra_dialogue = string.format(
                        "Vijay adds: 'Remember the hungry week? %d of us went " ..
                        "without so the children could eat. We didn't complain " ..
                        "then. But this is different.'",
                        resentful
                    ),
                    severity_modifier = 1.2
                }
            end
        end)
    end
}
```

### 4. Gambling/Conditional Option: Trust the Harvest

```lua
{
    id = "trust_harvest",
    label = "Trust the harvest",
    description = "It will come. Hold what remains for emergency.",
    tags = { "gamble", "faith", "risky" },

    available = function(ctx)
        return ctx:HasBuilding("farm") and ctx:GetProductionProgress("farm") > 0.5
    end,

    preview = function(ctx)
        local farmProgress = ctx:GetProductionProgress("farm")
        local estimatedCycles = math.ceil((1 - farmProgress) / 0.1)

        return {
            "Harvest estimated in " .. estimatedCycles .. " cycles",
            "⚠️ GAMBLE: Success depends on actual harvest timing",
            "Success: +10 satisfaction for all",
            "Failure: -15 satisfaction, risk of death"
        }
    end,

    first_order = function(ctx)
        -- This is a DEFERRED first-order effect
        -- We don't know the outcome yet

        ctx:SetFlag("waiting_for_harvest_gamble")
        ctx.inventory.food = ctx.inventory.food  -- Keep what we have

        -- Schedule the resolution
        ctx:ScheduleConditionalEffect({
            id = "harvest_gamble_resolution",

            -- Check every cycle
            check = function(checkCtx)
                if checkCtx.inventory.food > 20 then
                    return "success"  -- Harvest came in
                elseif checkCtx:CyclesSince("waiting_for_harvest_gamble") > 5 then
                    return "failure"  -- Took too long
                end
                return nil  -- Keep waiting
            end,

            outcomes = {
                success = function(successCtx)
                    successCtx:ClearFlag("waiting_for_harvest_gamble")

                    for _, char in ipairs(successCtx.characters) do
                        char:ModifySatisfaction("biological", 10)
                        char:AddMemory({
                            event = "hungry_week",
                            type = "harvest_came_through",
                            sentiment = "relieved",
                            cycle = successCtx.cycle
                        })
                    end

                    successCtx:ShowNotification({
                        title = "The Harvest Arrives!",
                        text = "Your faith was rewarded. The harvest came just in time.",
                        mood = "celebration"
                    })

                    successCtx:SetFlag("lucky_harvest")
                end,

                failure = function(failCtx)
                    failCtx:ClearFlag("waiting_for_harvest_gamble")

                    for _, char in ipairs(failCtx.characters) do
                        char:ModifySatisfaction("biological", -15)
                        char:AddMemory({
                            event = "hungry_week",
                            type = "harvest_gamble_failed",
                            sentiment = "angry",
                            cycle = failCtx.cycle
                        })
                    end

                    -- Death risk
                    local vulnerable = failCtx:GetVulnerableCharacters()
                    for _, char in ipairs(vulnerable) do
                        if math.random() < 0.15 then  -- 15% death chance
                            failCtx:KillCharacter(char, {
                                cause = "starvation",
                                narrative = char.name .. " could not survive the hunger."
                            })
                        end
                    end

                    failCtx:ShowNotification({
                        title = "The Harvest Is Late",
                        text = "Your gamble failed. The people have suffered for your faith.",
                        mood = "tragedy"
                    })

                    failCtx:SetFlag("harvest_gamble_failed")
                end
            }
        })
    end,

    second_order = function(ctx)
        -- These apply regardless of outcome
        -- But we also register outcome-dependent effects

        ctx:RegisterCallback("harvest_gamble_resolved", function(resolveCtx, outcome)
            if outcome == "success" then
                resolveCtx.values:Modify("faith", 10)
                resolveCtx.history:AddModifier({
                    id = "lucky_leader",
                    type = "reputation",
                    traits = { "visionary", "blessed" },
                    duration = 50  -- cycles
                })
            else
                resolveCtx.values:Modify("faith", -5)
                resolveCtx.values:Modify("trust_in_leadership", -15)
                resolveCtx.history:AddModifier({
                    id = "reckless_leader",
                    type = "reputation",
                    traits = { "reckless", "gambler" },
                    duration = 100
                })

                -- Future choices may reference this failure
                resolveCtx:RegisterCallback("any_risky_choice", function(riskyCtx)
                    return {
                        extra_dialogue = "Someone mutters: 'Remember the harvest " ..
                            "gamble? Some of us have long memories.'",
                        option_modifiers = {
                            risky_options = { trust_penalty = -10 }
                        }
                    }
                end)
            end
        end)
    end
}
```

### 5. Player Choice History Schema

```lua
-- Persistent across entire game
PlayerChoiceHistory = {
    version = "1.0",

    -- Raw choice log
    choices_made = {
        {
            choice_id = "hungry_week_choice",
            option_selected = "prioritize_children",
            cycle = 45,
            era = "settlement",
            context = {
                population = 14,
                food_level = 3,
                average_satisfaction = 42
            }
        },
        -- ... all choices
    },

    -- Derived statistics (for second-order effects)
    choice_patterns = {
        egalitarian_choices = 3,
        authoritarian_choices = 1,
        risk_taking_choices = 2,
        conservative_choices = 4
    },

    -- Town values (accumulated from choices)
    town_values = {
        egalitarianism = 25,      -- -100 to +100
        family_focus = 40,
        productivity_focus = 15,
        tradition = 30,
        innovation = -10,
        militarism = 0,
        diplomacy = 20
    },

    -- Active modifiers from past choices
    active_modifiers = {
        {
            id = "equality_precedent",
            source_choice = "hungry_week_choice",
            type = "choice_weight",
            modifier = 1.2,
            expires_cycle = nil  -- permanent
        }
    },

    -- Character memories of choices
    character_memories = {
        ["char_001"] = {
            { memory = "went_hungry_for_children", sentiment = "grateful", cycle = 45 }
        },
        ["char_002"] = {
            { memory = "went_hungry_for_children", sentiment = "resentful", cycle = 45 }
        }
    },

    -- Flags for conditional logic
    flags = {
        "chose_equality_hungry_week",
        "first_death_occurred",
        "built_school"
    }
}
```

### 6. Town Values System Schema

```lua
-- data/alpha/narrative/town_values.json

TownValues = {
    -- Core value dimensions
    dimensions = {
        egalitarianism = {
            description = "Equality vs Hierarchy",
            range = { -100, 100 },
            affects = {
                choice_availability = true,
                npc_reactions = true,
                immigration = true
            }
        },
        family_focus = {
            description = "Family vs Individual priority",
            range = { -100, 100 }
        },
        productivity_focus = {
            description = "Growth vs Sustainability",
            range = { -100, 100 }
        },
        tradition = {
            description = "Conservative vs Progressive",
            range = { -100, 100 }
        },
        militarism = {
            description = "Defensive vs Diplomatic",
            range = { -100, 100 }
        },
        spirituality = {
            description = "Secular vs Religious",
            range = { -100, 100 }
        }
    },

    -- Value thresholds trigger special content
    thresholds = {
        {
            dimension = "egalitarianism",
            threshold = 50,
            direction = "above",
            unlocks = {
                choices = { "worker_council_formation" },
                buildings = { "commune_hall" },
                events = { "equality_festival" }
            }
        },
        {
            dimension = "egalitarianism",
            threshold = -50,
            direction = "below",
            unlocks = {
                choices = { "noble_court_formation" },
                buildings = { "palace" },
                events = { "class_unrest" }
            }
        }
    }
}
```

---

## The Context Object

The `ctx` parameter is the key to the entire system. It's a rich context object that provides access to everything the choice functions need.

### ChoiceContext.lua

```lua
-- code/narrative/ChoiceContext.lua

local ChoiceContext = {}
ChoiceContext.__index = ChoiceContext

function ChoiceContext:new(townState, playerHistory, narrativeSystem)
    local ctx = setmetatable({}, ChoiceContext)

    -- Core state references
    ctx.townState = townState
    ctx.history = playerHistory
    ctx.narrative = narrativeSystem

    -- Convenience accessors
    ctx.characters = townState.characters
    ctx.inventory = townState.inventory
    ctx.buildings = townState.buildings
    ctx.cycle = townState.currentCycle
    ctx.era = townState.currentEra
    ctx.values = playerHistory.townValues
    ctx.tension = townState.classTension
    ctx.immigration = townState.immigrationSystem

    -- Callback registry for cross-choice effects
    ctx.callbacks = {}

    -- Scheduled effects
    ctx.scheduledEffects = {}
    ctx.conditionalEffects = {}

    return ctx
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    QUERY METHODS
    These let choice functions ask questions about the world
    ═══════════════════════════════════════════════════════════════════════════
]]--

function ChoiceContext:GetCharactersByClass(class)
    local result = {}
    for _, char in ipairs(self.characters) do
        if char.class == class then
            table.insert(result, char)
        end
    end
    return result
end

function ChoiceContext:GetCharactersByTrait(trait)
    local result = {}
    for _, char in ipairs(self.characters) do
        if char:HasTrait(trait) then
            table.insert(result, char)
        end
    end
    return result
end

function ChoiceContext:GetFamiliesWithChildren()
    local families = {}
    for _, char in ipairs(self.characters) do
        if char:HasChildren() and not families[char.familyId] then
            families[char.familyId] = {
                id = char.familyId,
                members = self:GetFamilyMembers(char.familyId)
            }
        end
    end
    return TableValues(families)
end

function ChoiceContext:GetFamilyMembers(familyId)
    local members = {}
    for _, char in ipairs(self.characters) do
        if char.familyId == familyId then
            table.insert(members, char)
        end
    end
    return members
end

function ChoiceContext:GetWorkers()
    local result = {}
    for _, char in ipairs(self.characters) do
        if char.employment and char.employment.building then
            table.insert(result, char)
        end
    end
    return result
end

function ChoiceContext:GetWorkersAssignedToProduction()
    local result = {}
    for _, char in ipairs(self.characters) do
        if char.employment and char.employment.building then
            local building = self.townState:GetBuildingById(char.employment.building)
            if building and building:IsProductionBuilding() then
                table.insert(result, char)
            end
        end
    end
    return result
end

function ChoiceContext:GetMostDesperateCharacter()
    local mostDesperate = nil
    local lowestSat = 100

    for _, char in ipairs(self.characters) do
        local sat = char:GetAverageSatisfaction()
        if sat < lowestSat then
            lowestSat = sat
            mostDesperate = char
        end
    end

    return mostDesperate
end

function ChoiceContext:GetVulnerableCharacters()
    local result = {}
    for _, char in ipairs(self.characters) do
        if char.age > 60 or char.age < 10 or char:HasTrait("sickly") then
            table.insert(result, char)
        end
    end
    return result
end

function ChoiceContext:HasBuilding(buildingType)
    for _, building in ipairs(self.buildings) do
        if building.type == buildingType then
            return true
        end
    end
    return false
end

function ChoiceContext:HasFamiliesWithChildren()
    return #self:GetFamiliesWithChildren() > 0
end

function ChoiceContext:GetProductionProgress(buildingType)
    for _, building in ipairs(self.buildings) do
        if building.type == buildingType then
            return building.productionProgress or 0
        end
    end
    return 0
end

function ChoiceContext:CyclesSince(event)
    local eventCycle = self.history:GetEventCycle(event)
    if eventCycle then
        return self.cycle - eventCycle
    end
    -- If event never happened, check for state-based "events"
    if event == "food_above_10" then
        return self.history:CyclesSinceCondition(function(state)
            return state.inventory.food > 10
        end)
    end
    return 999  -- Very long time
end

function ChoiceContext:CountCharactersWithMemory(memoryType, sentiment)
    local count = 0
    for _, char in ipairs(self.characters) do
        for _, memory in ipairs(char.memories or {}) do
            if memory.type == memoryType and
               (sentiment == nil or memory.sentiment == sentiment) then
                count = count + 1
                break
            end
        end
    end
    return count
end

function ChoiceContext:CountCharactersWithTrait(trait)
    local count = 0
    for _, char in ipairs(self.characters) do
        if char:HasTrait(trait) then
            count = count + 1
        end
    end
    return count
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    MUTATION METHODS
    These let choice functions change the world
    ═══════════════════════════════════════════════════════════════════════════
]]--

function ChoiceContext:SetFlag(flag)
    self.history:SetFlag(flag)
end

function ChoiceContext:ClearFlag(flag)
    self.history:ClearFlag(flag)
end

function ChoiceContext:Log(format, ...)
    local message = string.format(format, ...)
    self.narrative:AddToLog(self.cycle, message)
end

function ChoiceContext:AddTemporaryModifier(modifier)
    self.townState:AddModifier(modifier)
end

function ChoiceContext:AddTownTrait(trait)
    self.townState:AddTrait(trait)
end

function ChoiceContext:UnlockBuilding(buildingType)
    self.townState:UnlockBuilding(buildingType)
end

function ChoiceContext:KillCharacter(character, details)
    self.townState:RemoveCharacter(character.id, details)
    self.narrative:TriggerDeathEvent(character, details)
end

function ChoiceContext:ShowNotification(notification)
    self.narrative:ShowNotification(notification)
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    SCHEDULING METHODS
    These let choice functions schedule future effects
    ═══════════════════════════════════════════════════════════════════════════
]]--

function ChoiceContext:ScheduleEffect(cyclesFromNow, effectFn)
    table.insert(self.scheduledEffects, {
        triggerCycle = self.cycle + cyclesFromNow,
        effect = effectFn
    })
end

function ChoiceContext:ScheduleConditionalEffect(config)
    table.insert(self.conditionalEffects, {
        id = config.id,
        check = config.check,
        outcomes = config.outcomes,
        startCycle = self.cycle
    })
end

function ChoiceContext:RegisterCallback(eventName, callbackFn)
    if not self.callbacks[eventName] then
        self.callbacks[eventName] = {}
    end
    table.insert(self.callbacks[eventName], callbackFn)
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    CALLBACK INVOCATION
    Called by the narrative system when relevant events occur
    ═══════════════════════════════════════════════════════════════════════════
]]--

function ChoiceContext:InvokeCallbacks(eventName, ...)
    local results = {}
    if self.callbacks[eventName] then
        for _, callback in ipairs(self.callbacks[eventName]) do
            local result = callback(self, ...)
            if result then
                table.insert(results, result)
            end
        end
    end
    return results
end

return ChoiceContext
```

---

## Effect Builders & Composition

Create reusable effect building blocks for cleaner choice definitions:

### EffectBuilders.lua

```lua
-- code/narrative/EffectBuilders.lua

local Effects = {}

--[[
    ═══════════════════════════════════════════════════════════════════════════
    SATISFACTION EFFECTS
    ═══════════════════════════════════════════════════════════════════════════
]]--

function Effects.ModifySatisfaction(target, category, delta)
    return function(ctx)
        local chars = Effects._resolveTarget(ctx, target)
        for _, char in ipairs(chars) do
            char:ModifySatisfaction(category, delta)
        end
    end
end

function Effects.ModifyAllSatisfaction(target, deltas)
    return function(ctx)
        local chars = Effects._resolveTarget(ctx, target)
        for _, char in ipairs(chars) do
            for category, delta in pairs(deltas) do
                char:ModifySatisfaction(category, delta)
            end
        end
    end
end

function Effects.ScaledSatisfaction(target, category, baseAmount, scaleFn)
    return function(ctx)
        local chars = Effects._resolveTarget(ctx, target)
        for _, char in ipairs(chars) do
            local scale = scaleFn(ctx, char)
            char:ModifySatisfaction(category, baseAmount * scale)
        end
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    RESOURCE EFFECTS
    ═══════════════════════════════════════════════════════════════════════════
]]--

function Effects.ModifyResource(resource, delta)
    return function(ctx)
        ctx.inventory[resource] = (ctx.inventory[resource] or 0) + delta
    end
end

function Effects.TransferResource(resource, fromInventory, toTarget, amount)
    return function(ctx)
        local available = ctx.inventory[resource] or 0
        local toTransfer = math.min(available, amount)

        ctx.inventory[resource] = available - toTransfer

        local chars = Effects._resolveTarget(ctx, toTarget)
        local perChar = math.floor(toTransfer / #chars)

        for _, char in ipairs(chars) do
            char:AddToPersonalInventory(resource, perChar)
        end
    end
end

function Effects.DistributeEqually(resource)
    return function(ctx)
        local available = ctx.inventory[resource] or 0
        local perChar = math.floor(available / #ctx.characters)
        local remainder = available % #ctx.characters

        for _, char in ipairs(ctx.characters) do
            char:AddToPersonalInventory(resource, perChar)
        end

        ctx.inventory[resource] = remainder
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    MEMORY EFFECTS
    ═══════════════════════════════════════════════════════════════════════════
]]--

function Effects.AddMemory(target, memoryTemplate)
    return function(ctx)
        local chars = Effects._resolveTarget(ctx, target)
        for _, char in ipairs(chars) do
            local sentiment = memoryTemplate.sentiment

            -- Dynamic sentiment based on character
            if type(sentiment) == "function" then
                sentiment = sentiment(ctx, char)
            elseif type(sentiment) == "table" then
                -- Trait-based sentiment lookup
                sentiment = Effects._resolveSentiment(char, sentiment)
            end

            char:AddMemory({
                event = memoryTemplate.event,
                type = memoryTemplate.type,
                sentiment = sentiment,
                cycle = ctx.cycle,
                details = memoryTemplate.details
            })
        end
    end
end

function Effects._resolveSentiment(char, sentimentMap)
    -- sentimentMap = { default = "neutral", selfless = "grateful", greedy = "resentful" }
    for trait, sentiment in pairs(sentimentMap) do
        if trait ~= "default" and char:HasTrait(trait) then
            return sentiment
        end
    end
    return sentimentMap.default or "neutral"
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    VALUE EFFECTS
    ═══════════════════════════════════════════════════════════════════════════
]]--

function Effects.ModifyTownValue(dimension, delta)
    return function(ctx)
        ctx.values:Modify(dimension, delta)
    end
end

function Effects.ModifyTownValues(changes)
    return function(ctx)
        for dimension, delta in pairs(changes) do
            ctx.values:Modify(dimension, delta)
        end
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    PRODUCTIVITY EFFECTS
    ═══════════════════════════════════════════════════════════════════════════
]]--

function Effects.TemporaryProductivityModifier(target, modifier, duration, reason)
    return function(ctx)
        ctx:AddTemporaryModifier({
            id = "productivity_" .. tostring(ctx.cycle),
            target = target,
            type = "productivity",
            modifier = modifier,
            duration = duration,
            reason = reason
        })
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    FLAG EFFECTS
    ═══════════════════════════════════════════════════════════════════════════
]]--

function Effects.SetFlag(flag)
    return function(ctx)
        ctx:SetFlag(flag)
    end
end

function Effects.SetFlags(flags)
    return function(ctx)
        for _, flag in ipairs(flags) do
            ctx:SetFlag(flag)
        end
    end
end

function Effects.ClearFlag(flag)
    return function(ctx)
        ctx:ClearFlag(flag)
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    UNLOCK EFFECTS
    ═══════════════════════════════════════════════════════════════════════════
]]--

function Effects.UnlockBuilding(buildingType)
    return function(ctx)
        ctx:UnlockBuilding(buildingType)
    end
end

function Effects.UnlockChoice(choiceId)
    return function(ctx)
        ctx.history:UnlockChoice(choiceId)
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    COMPOSITION UTILITIES
    ═══════════════════════════════════════════════════════════════════════════
]]--

function Effects.Sequence(...)
    local effects = {...}
    return function(ctx)
        for _, effect in ipairs(effects) do
            effect(ctx)
        end
    end
end

function Effects.Conditional(condition, thenEffect, elseEffect)
    return function(ctx)
        if condition(ctx) then
            if thenEffect then thenEffect(ctx) end
        else
            if elseEffect then elseEffect(ctx) end
        end
    end
end

function Effects.ForEach(targetResolver, effectTemplate)
    return function(ctx)
        local targets = targetResolver(ctx)
        for _, target in ipairs(targets) do
            local effect = effectTemplate(target)
            effect(ctx)
        end
    end
end

function Effects.WithProbability(probability, effect)
    return function(ctx)
        if math.random() < probability then
            effect(ctx)
        end
    end
end

function Effects.Delayed(cyclesFromNow, effect)
    return function(ctx)
        ctx:ScheduleEffect(cyclesFromNow, effect)
    end
end

--[[
    ═══════════════════════════════════════════════════════════════════════════
    HELPERS
    ═══════════════════════════════════════════════════════════════════════════
]]--

function Effects._resolveTarget(ctx, target)
    if type(target) == "function" then
        return target(ctx)
    elseif target == "all" then
        return ctx.characters
    elseif target == "workers" then
        return ctx:GetWorkers()
    elseif target == "workers_without_children" then
        local result = {}
        for _, char in ipairs(ctx:GetWorkers()) do
            if not char:HasChildren() then
                table.insert(result, char)
            end
        end
        return result
    elseif target == "families" then
        local result = {}
        for _, family in ipairs(ctx:GetFamiliesWithChildren()) do
            for _, member in ipairs(family.members) do
                table.insert(result, member)
            end
        end
        return result
    elseif target == "elite" then
        return ctx:GetCharactersByClass("Elite")
    elseif target == "upper" then
        return ctx:GetCharactersByClass("Upper")
    elseif target == "middle" then
        return ctx:GetCharactersByClass("Middle")
    elseif target == "lower" then
        return ctx:GetCharactersByClass("Lower")
    elseif target == "vulnerable" then
        return ctx:GetVulnerableCharacters()
    elseif type(target) == "table" then
        return target  -- Already a list of characters
    end
    return {}
end

return Effects
```

### Using Effect Builders for Cleaner Choice Definitions

```lua
local Effects = require("code.narrative.EffectBuilders")

local choice = {
    id = "education_debate",
    era = "town",

    trigger = function(ctx)
        return ctx.era == "town"
           and ctx:HasBuilding("school")
           and ctx:CyclesSince("school_built") >= 10
           and not ctx.history:HasMadeChoice("education_debate")
    end,

    presentation = {
        title = "The Education Debate",
        narrative = function(ctx)
            return [[
A heated argument erupts at the town gathering.

The FARMERS speak:
    "Our children should work the fields!
     Books don't grow wheat. Dreams don't feed mouths."

The CRAFTSMEN counter:
    "An educated child can become anything -
     a doctor, a merchant, even a leader!"

The town looks to you. What kind of society will this be?
            ]]
        end,
        mood = "debate"
    },

    options = {
        {
            id = "universal_education",
            label = "Universal education",
            description = "Every child attends school",
            tags = { "egalitarian", "progressive" },

            available = function(ctx) return true end,

            preview = function(ctx)
                return {
                    "All children will attend school",
                    "+5 psychological satisfaction for all",
                    "+10 egalitarianism, +15 innovation",
                    "Slower labor pool growth short-term"
                }
            end,

            -- Clean, declarative first-order effects
            first_order = Effects.Sequence(
                Effects.ModifySatisfaction("all", "psychological", 5),
                Effects.SetFlag("universal_education"),
                Effects.AddMemory("all", {
                    event = "education_debate",
                    type = "universal_education_enacted",
                    sentiment = {
                        default = "hopeful",
                        traditional = "skeptical",
                        intellectual = "excited"
                    }
                }),
                -- Custom logic when needed
                function(ctx)
                    ctx:UnlockBuilding("university")
                    ctx:Log("Universal education policy enacted")
                end
            ),

            -- Second-order effects
            second_order = Effects.Sequence(
                Effects.ModifyTownValues({
                    egalitarianism = 10,
                    innovation = 15,
                    tradition = -5
                }),
                -- Long-term scheduled effect
                Effects.Delayed(30, function(futureCtx)
                    local educated = futureCtx:CountCharactersWithTrait("educated")
                    if educated > 10 then
                        futureCtx:AddTownTrait("center_of_learning")
                        futureCtx:ShowNotification({
                            title = "Center of Learning",
                            text = "Your commitment to education has made the town famous for learning.",
                            mood = "achievement"
                        })
                    end
                end)
            )
        },

        {
            id = "selective_education",
            label = "Selective education",
            description = "Only craftsmen's children attend",
            tags = { "class_based", "traditional" },

            available = function(ctx) return true end,

            preview = function(ctx)
                local craftsmen = ctx:GetCharactersByTrait("craftsman")
                return {
                    #craftsmen .. " craftsmen families' children will attend",
                    "Craftsmen: +10 satisfaction",
                    "Farmers: -5 satisfaction",
                    "Class divisions begin to solidify"
                }
            end,

            first_order = Effects.Sequence(
                Effects.ModifySatisfaction(
                    function(ctx) return ctx:GetCharactersByTrait("craftsman") end,
                    "psychological", 10
                ),
                Effects.ModifySatisfaction(
                    function(ctx) return ctx:GetCharactersByTrait("farmer") end,
                    "psychological", -5
                ),
                Effects.SetFlag("selective_education"),
                Effects.AddMemory("all", {
                    event = "education_debate",
                    type = "selective_education_enacted",
                    sentiment = function(ctx, char)
                        if char:HasTrait("craftsman") then
                            return "privileged"
                        elseif char:HasTrait("farmer") then
                            return "excluded"
                        end
                        return "neutral"
                    end
                })
            ),

            second_order = Effects.Sequence(
                Effects.ModifyTownValues({
                    egalitarianism = -15,
                    tradition = 10
                }),
                function(ctx)
                    ctx.tension:AddIncident({
                        between = { "craftsmen", "farmers" },
                        severity = 10,
                        cause = "education_inequality"
                    })
                end
            )
        }
    },

    weight = 80,
    timeout = nil
}
```

---

## System Components

### 1. NarrativeSystem.lua (Main Coordinator)

```lua
-- code/narrative/NarrativeSystem.lua

local ChoiceContext = require("code.narrative.ChoiceContext")

local NarrativeSystem = {}
NarrativeSystem.__index = NarrativeSystem

function NarrativeSystem:new(townState, playerHistory)
    local system = setmetatable({}, NarrativeSystem)

    system.townState = townState
    system.playerHistory = playerHistory
    system.choices = {}
    system.activeChoice = nil
    system.choiceQueue = {}
    system.pendingConditionalEffects = {}
    system.scheduledEffects = {}
    system.registeredCallbacks = {}

    return system
end

function NarrativeSystem:LoadChoices()
    -- Load all choice definitions from Lua modules
    local settlementChoices = require("data.alpha.narrative.choices.settlement_era")
    local villageChoices = require("data.alpha.narrative.choices.village_era")
    local townChoices = require("data.alpha.narrative.choices.town_era")
    local cityChoices = require("data.alpha.narrative.choices.city_era")
    local metropolisChoices = require("data.alpha.narrative.choices.metropolis_era")

    local allChoices = {
        settlementChoices,
        villageChoices,
        townChoices,
        cityChoices,
        metropolisChoices
    }

    for _, choiceSet in ipairs(allChoices) do
        for id, choice in pairs(choiceSet) do
            self.choices[id] = choice
        end
    end

    print(string.format("Loaded %d choices", TableLength(self.choices)))
end

function NarrativeSystem:Update(dt)
    -- Skip if modal is open
    if self.activeChoice then return end

    -- Create context for this cycle
    local ctx = self:CreateContext()

    -- Process scheduled effects
    self:ProcessScheduledEffects(ctx)

    -- Process conditional effects
    self:ProcessConditionalEffects(ctx)

    -- Check for new triggers
    self:EvaluateTriggers(ctx)

    -- Present next queued choice if any
    if #self.choiceQueue > 0 then
        self:PresentChoice(self.choiceQueue[1])
        table.remove(self.choiceQueue, 1)
    end
end

function NarrativeSystem:CreateContext()
    local ctx = ChoiceContext:new(self.townState, self.playerHistory, self)

    -- Attach persistent callbacks from previous choices
    ctx.callbacks = self.registeredCallbacks

    return ctx
end

function NarrativeSystem:EvaluateTriggers(ctx)
    local triggered = {}

    for id, choice in pairs(self.choices) do
        -- Skip if already made (unless repeatable)
        if not choice.repeatable and ctx.history:HasMadeChoice(id) then
            goto continue
        end

        -- Evaluate trigger function
        local shouldTrigger = false
        if type(choice.trigger) == "function" then
            local success, result = pcall(choice.trigger, ctx)
            if success then
                shouldTrigger = result
            else
                print(string.format("Error evaluating trigger for '%s': %s", id, result))
            end
        end

        if shouldTrigger then
            table.insert(triggered, {
                choice = choice,
                weight = choice.weight or 50
            })
        end

        ::continue::
    end

    -- Sort by weight (higher weight = higher priority)
    table.sort(triggered, function(a, b) return a.weight > b.weight end)

    -- Add to queue
    for _, item in ipairs(triggered) do
        table.insert(self.choiceQueue, item.choice)
    end
end

function NarrativeSystem:PresentChoice(choice)
    self.activeChoice = choice

    local ctx = self:CreateContext()

    -- Build presentation
    local presentation = choice.presentation
    local narrative = presentation.narrative
    if type(narrative) == "function" then
        narrative = narrative(ctx)
    end

    local title = presentation.title
    if type(title) == "function" then
        title = title(ctx)
    end

    -- Get available options
    local availableOptions = {}
    local optionsList = choice.options
    if type(optionsList) == "function" then
        optionsList = optionsList(ctx)
    end

    for _, option in ipairs(optionsList) do
        local available = true
        if option.available then
            available = option.available(ctx)
        end

        if available then
            local preview = nil
            if option.preview then
                preview = option.preview(ctx)
            end

            table.insert(availableOptions, {
                id = option.id,
                label = option.label,
                description = option.description,
                preview = preview,
                tags = option.tags,
                historical_bonus = option.historical_bonus
            })
        end
    end

    -- Show modal (interface with UI system)
    self:ShowChoiceModal({
        title = title,
        narrative = narrative,
        mood = presentation.mood,
        speaker = presentation.speaker,
        options = availableOptions,
        onSelect = function(optionId)
            self:ResolveChoice(choice, optionId)
        end
    })
end

function NarrativeSystem:ResolveChoice(choice, selectedOptionId)
    local ctx = self:CreateContext()

    -- Find selected option
    local optionsList = choice.options
    if type(optionsList) == "function" then
        optionsList = optionsList(ctx)
    end

    local selectedOption = nil
    for _, option in ipairs(optionsList) do
        if option.id == selectedOptionId then
            selectedOption = option
            break
        end
    end

    if not selectedOption then
        error("Invalid option selected: " .. tostring(selectedOptionId))
    end

    -- Record choice in history
    self.playerHistory:RecordChoice(choice.id, selectedOptionId, {
        cycle = ctx.cycle,
        era = ctx.era,
        context = self:CaptureContextSnapshot(ctx)
    })

    -- Execute first-order effects
    if selectedOption.first_order then
        local success, err = pcall(selectedOption.first_order, ctx)
        if not success then
            print(string.format("Error in first_order for '%s.%s': %s",
                choice.id, selectedOptionId, err))
        end
    end

    -- Execute second-order effects
    if selectedOption.second_order then
        local success, err = pcall(selectedOption.second_order, ctx)
        if not success then
            print(string.format("Error in second_order for '%s.%s': %s",
                choice.id, selectedOptionId, err))
        end
    end

    -- Collect any scheduled/conditional effects from context
    for _, effect in ipairs(ctx.scheduledEffects) do
        table.insert(self.scheduledEffects, effect)
    end
    for _, effect in ipairs(ctx.conditionalEffects) do
        table.insert(self.pendingConditionalEffects, effect)
    end

    -- Merge callbacks (these persist across choices)
    for eventName, callbacks in pairs(ctx.callbacks) do
        if not self.registeredCallbacks[eventName] then
            self.registeredCallbacks[eventName] = {}
        end
        for _, cb in ipairs(callbacks) do
            -- Avoid duplicates
            local isDuplicate = false
            for _, existing in ipairs(self.registeredCallbacks[eventName]) do
                if existing == cb then
                    isDuplicate = true
                    break
                end
            end
            if not isDuplicate then
                table.insert(self.registeredCallbacks[eventName], cb)
            end
        end
    end

    -- Close modal
    self.activeChoice = nil
    self:CloseChoiceModal()

    -- Invoke any listeners for choice completion
    self:InvokeCallbacks("choice_made", choice.id, selectedOptionId)

    print(string.format("Choice resolved: %s -> %s", choice.id, selectedOptionId))
end

function NarrativeSystem:ProcessScheduledEffects(ctx)
    for i = #self.scheduledEffects, 1, -1 do
        local scheduled = self.scheduledEffects[i]
        if ctx.cycle >= scheduled.triggerCycle then
            local success, err = pcall(scheduled.effect, ctx)
            if not success then
                print(string.format("Error in scheduled effect: %s", err))
            end
            table.remove(self.scheduledEffects, i)
        end
    end
end

function NarrativeSystem:ProcessConditionalEffects(ctx)
    for i = #self.pendingConditionalEffects, 1, -1 do
        local conditional = self.pendingConditionalEffects[i]

        local success, result = pcall(conditional.check, ctx)
        if not success then
            print(string.format("Error checking conditional '%s': %s",
                conditional.id, result))
            goto continue
        end

        if result then
            local outcome = conditional.outcomes[result]
            if outcome then
                local outcomeSuccess, outcomeErr = pcall(outcome, ctx)
                if not outcomeSuccess then
                    print(string.format("Error in conditional outcome '%s.%s': %s",
                        conditional.id, result, outcomeErr))
                end
            end
            table.remove(self.pendingConditionalEffects, i)

            -- Fire callback if registered
            self:InvokeCallbacks(conditional.id .. "_resolved", result)
        end

        ::continue::
    end
end

function NarrativeSystem:InvokeCallbacks(eventName, ...)
    local ctx = self:CreateContext()
    local results = {}

    if self.registeredCallbacks[eventName] then
        for _, callback in ipairs(self.registeredCallbacks[eventName]) do
            local success, result = pcall(callback, ctx, ...)
            if success and result then
                table.insert(results, result)
            elseif not success then
                print(string.format("Error in callback for '%s': %s", eventName, result))
            end
        end
    end

    return results
end

function NarrativeSystem:CaptureContextSnapshot(ctx)
    return {
        population = #ctx.characters,
        inventory = DeepCopy(ctx.inventory),
        averageSatisfaction = ctx.townState:GetAverageSatisfaction(),
        townValues = DeepCopy(ctx.values:GetAll()),
        buildings = #ctx.buildings
    }
end

-- UI Interface methods (implement based on your UI system)
function NarrativeSystem:ShowChoiceModal(config)
    -- Interface with ChoiceModal.lua
    if self.choiceModal then
        self.choiceModal:Show(config)
    end
end

function NarrativeSystem:CloseChoiceModal()
    if self.choiceModal then
        self.choiceModal:Hide()
    end
end

-- Serialization for save/load
function NarrativeSystem:Serialize()
    return {
        scheduledEffects = self.scheduledEffects,
        pendingConditionalEffects = self.pendingConditionalEffects,
        -- Note: callbacks are functions and can't be serialized
        -- They must be re-registered when loading choices
    }
end

function NarrativeSystem:Deserialize(data)
    self.scheduledEffects = data.scheduledEffects or {}
    self.pendingConditionalEffects = data.pendingConditionalEffects or {}
end

return NarrativeSystem
```

### 2. PlayerChoiceHistory.lua

```lua
-- code/narrative/PlayerChoiceHistory.lua

local PlayerChoiceHistory = {}
PlayerChoiceHistory.__index = PlayerChoiceHistory

function PlayerChoiceHistory:new()
    local history = setmetatable({}, PlayerChoiceHistory)

    history.version = "1.0"
    history.choices_made = {}
    history.choice_patterns = {
        egalitarian_choices = 0,
        authoritarian_choices = 0,
        risk_taking_choices = 0,
        conservative_choices = 0,
        family_focused_choices = 0,
        productivity_focused_choices = 0
    }
    history.town_values = {
        egalitarianism = 0,
        family_focus = 0,
        productivity_focus = 0,
        tradition = 0,
        innovation = 0,
        militarism = 0,
        diplomacy = 0,
        spirituality = 0,
        trust_in_leadership = 50,
        community_cohesion = 50
    }
    history.active_modifiers = {}
    history.character_memories = {}
    history.flags = {}
    history.unlocked_choices = {}
    history.event_cycles = {}

    return history
end

function PlayerChoiceHistory:RecordChoice(choiceId, optionId, metadata)
    table.insert(self.choices_made, {
        choice_id = choiceId,
        option_selected = optionId,
        cycle = metadata.cycle,
        era = metadata.era,
        context = metadata.context,
        timestamp = os.time()
    })

    -- Update patterns based on option tags
    -- This would need the option definition to extract tags
end

function PlayerChoiceHistory:HasMadeChoice(choiceId)
    for _, choice in ipairs(self.choices_made) do
        if choice.choice_id == choiceId then
            return true
        end
    end
    return false
end

function PlayerChoiceHistory:ChoseOption(choiceId, optionId)
    for _, choice in ipairs(self.choices_made) do
        if choice.choice_id == choiceId and choice.option_selected == optionId then
            return true
        end
    end
    return false
end

function PlayerChoiceHistory:GetChoicesMade()
    return self.choices_made
end

function PlayerChoiceHistory:GetLastChoice()
    if #self.choices_made > 0 then
        return self.choices_made[#self.choices_made]
    end
    return nil
end

-- Flag management
function PlayerChoiceHistory:SetFlag(flag)
    self.flags[flag] = true
end

function PlayerChoiceHistory:ClearFlag(flag)
    self.flags[flag] = nil
end

function PlayerChoiceHistory:HasFlag(flag)
    return self.flags[flag] == true
end

-- Event cycle tracking
function PlayerChoiceHistory:RecordEventCycle(eventName, cycle)
    self.event_cycles[eventName] = cycle
end

function PlayerChoiceHistory:GetEventCycle(eventName)
    return self.event_cycles[eventName]
end

function PlayerChoiceHistory:CyclesSinceCondition(conditionFn)
    -- This would need access to historical state snapshots
    -- For now, return a large number
    return 999
end

-- Modifier management
function PlayerChoiceHistory:AddModifier(modifier)
    table.insert(self.active_modifiers, modifier)
end

function PlayerChoiceHistory:GetModifiers(filterType)
    if not filterType then
        return self.active_modifiers
    end

    local result = {}
    for _, mod in ipairs(self.active_modifiers) do
        if mod.type == filterType then
            table.insert(result, mod)
        end
    end
    return result
end

function PlayerChoiceHistory:RemoveExpiredModifiers(currentCycle)
    for i = #self.active_modifiers, 1, -1 do
        local mod = self.active_modifiers[i]
        if mod.expires_cycle and currentCycle >= mod.expires_cycle then
            table.remove(self.active_modifiers, i)
        end
    end
end

-- Character memory management
function PlayerChoiceHistory:AddCharacterMemory(characterId, memory)
    if not self.character_memories[characterId] then
        self.character_memories[characterId] = {}
    end
    table.insert(self.character_memories[characterId], memory)
end

function PlayerChoiceHistory:GetCharacterMemories(characterId)
    return self.character_memories[characterId] or {}
end

-- Choice unlocking
function PlayerChoiceHistory:UnlockChoice(choiceId)
    self.unlocked_choices[choiceId] = true
end

function PlayerChoiceHistory:IsChoiceUnlocked(choiceId)
    return self.unlocked_choices[choiceId] == true
end

-- Town values (wrapper for convenience)
function PlayerChoiceHistory:GetTownValue(dimension)
    return self.town_values[dimension] or 0
end

-- Serialization
function PlayerChoiceHistory:Serialize()
    return {
        version = self.version,
        choices_made = self.choices_made,
        choice_patterns = self.choice_patterns,
        town_values = self.town_values,
        active_modifiers = self.active_modifiers,
        character_memories = self.character_memories,
        flags = self.flags,
        unlocked_choices = self.unlocked_choices,
        event_cycles = self.event_cycles
    }
end

function PlayerChoiceHistory:Deserialize(data)
    self.version = data.version or "1.0"
    self.choices_made = data.choices_made or {}
    self.choice_patterns = data.choice_patterns or {}
    self.town_values = data.town_values or {}
    self.active_modifiers = data.active_modifiers or {}
    self.character_memories = data.character_memories or {}
    self.flags = data.flags or {}
    self.unlocked_choices = data.unlocked_choices or {}
    self.event_cycles = data.event_cycles or {}
end

return PlayerChoiceHistory
```

### 3. TownValueSystem.lua

```lua
-- code/narrative/TownValueSystem.lua

local TownValueSystem = {}
TownValueSystem.__index = TownValueSystem

function TownValueSystem:new(playerHistory)
    local system = setmetatable({}, TownValueSystem)

    system.playerHistory = playerHistory
    system.values = playerHistory.town_values
    system.thresholds = {}
    system.triggeredThresholds = {}

    system:LoadThresholds()

    return system
end

function TownValueSystem:LoadThresholds()
    -- Define threshold triggers
    self.thresholds = {
        -- Egalitarianism thresholds
        {
            dimension = "egalitarianism",
            threshold = 50,
            direction = "above",
            id = "high_egalitarianism",
            unlocks = {
                choices = { "worker_council_formation", "commune_establishment" },
                buildings = { "commune_hall" },
                events = { "equality_festival" },
                traits = { "egalitarian_society" }
            }
        },
        {
            dimension = "egalitarianism",
            threshold = -50,
            direction = "below",
            id = "low_egalitarianism",
            unlocks = {
                choices = { "noble_court_formation", "caste_system" },
                buildings = { "palace", "servants_quarters" },
                events = { "class_unrest" },
                traits = { "hierarchical_society" }
            }
        },

        -- Tradition vs Innovation
        {
            dimension = "tradition",
            threshold = 50,
            direction = "above",
            id = "high_tradition",
            unlocks = {
                choices = { "elder_council", "ancestral_worship" },
                buildings = { "ancestral_shrine" },
                traits = { "traditional_society" }
            }
        },
        {
            dimension = "innovation",
            threshold = 50,
            direction = "above",
            id = "high_innovation",
            unlocks = {
                choices = { "research_academy", "inventors_guild" },
                buildings = { "laboratory", "workshop_advanced" },
                traits = { "innovative_society" }
            }
        },

        -- Militarism vs Diplomacy
        {
            dimension = "militarism",
            threshold = 40,
            direction = "above",
            id = "militaristic",
            unlocks = {
                choices = { "military_expansion", "conscription" },
                buildings = { "barracks", "fortress" },
                traits = { "militaristic_society" }
            }
        },
        {
            dimension = "diplomacy",
            threshold = 40,
            direction = "above",
            id = "diplomatic",
            unlocks = {
                choices = { "trade_alliance", "cultural_exchange" },
                buildings = { "embassy", "trading_post" },
                traits = { "diplomatic_society" }
            }
        }
    }
end

function TownValueSystem:Modify(dimension, delta)
    local oldValue = self.values[dimension] or 0
    local newValue = math.max(-100, math.min(100, oldValue + delta))
    self.values[dimension] = newValue

    -- Update in player history
    self.playerHistory.town_values[dimension] = newValue

    -- Check thresholds
    self:CheckThresholds(dimension, oldValue, newValue)

    return newValue
end

function TownValueSystem:Get(dimension)
    return self.values[dimension] or 0
end

function TownValueSystem:GetAll()
    return self.values
end

function TownValueSystem:CheckThresholds(dimension, oldValue, newValue)
    for _, threshold in ipairs(self.thresholds) do
        if threshold.dimension == dimension then
            local crossed = false

            if threshold.direction == "above" then
                crossed = oldValue < threshold.threshold and newValue >= threshold.threshold
            elseif threshold.direction == "below" then
                crossed = oldValue > threshold.threshold and newValue <= threshold.threshold
            end

            if crossed and not self.triggeredThresholds[threshold.id] then
                self:TriggerThreshold(threshold)
                self.triggeredThresholds[threshold.id] = true
            end
        end
    end
end

function TownValueSystem:TriggerThreshold(threshold)
    print(string.format("Threshold triggered: %s (%s %s %d)",
        threshold.id, threshold.dimension, threshold.direction, threshold.threshold))

    local unlocks = threshold.unlocks

    -- Unlock choices
    if unlocks.choices then
        for _, choiceId in ipairs(unlocks.choices) do
            self.playerHistory:UnlockChoice(choiceId)
        end
    end

    -- Unlock buildings (would interface with building system)
    if unlocks.buildings then
        for _, building in ipairs(unlocks.buildings) do
            -- self.townState:UnlockBuilding(building)
        end
    end

    -- Add town traits
    if unlocks.traits then
        for _, trait in ipairs(unlocks.traits) do
            -- self.townState:AddTrait(trait)
        end
    end

    -- Queue events
    if unlocks.events then
        for _, event in ipairs(unlocks.events) do
            -- self.eventSystem:QueueEvent(event)
        end
    end
end

function TownValueSystem:GetDominantValues(count)
    count = count or 3

    local sorted = {}
    for dimension, value in pairs(self.values) do
        table.insert(sorted, { dimension = dimension, value = math.abs(value), raw = value })
    end

    table.sort(sorted, function(a, b) return a.value > b.value end)

    local result = {}
    for i = 1, math.min(count, #sorted) do
        table.insert(result, {
            dimension = sorted[i].dimension,
            value = sorted[i].raw,
            direction = sorted[i].raw >= 0 and "positive" or "negative"
        })
    end

    return result
end

function TownValueSystem:GetTownIdentity()
    local dominant = self:GetDominantValues(3)
    local identityTraits = {}

    for _, value in ipairs(dominant) do
        if math.abs(value.value) > 30 then
            if value.dimension == "egalitarianism" then
                table.insert(identityTraits, value.value > 0 and "Egalitarian" or "Hierarchical")
            elseif value.dimension == "tradition" then
                table.insert(identityTraits, value.value > 0 and "Traditional" or "Progressive")
            elseif value.dimension == "militarism" then
                table.insert(identityTraits, value.value > 0 and "Militaristic" or "Peaceful")
            elseif value.dimension == "spirituality" then
                table.insert(identityTraits, value.value > 0 and "Religious" or "Secular")
            elseif value.dimension == "family_focus" then
                table.insert(identityTraits, value.value > 0 and "Family-Oriented" or "Individualistic")
            end
        end
    end

    return identityTraits
end

return TownValueSystem
```

---

## Cross-Choice Influence

One of the most powerful features of the lambda-based system is how past choices can influence future ones through callbacks.

### Example: Worker's Grievance Influenced by Hungry Week

```lua
-- In city_era.lua

local workerGrievance = {
    id = "workers_grievance",
    era = "city",

    trigger = function(ctx)
        return ctx.era == "city"
           and ctx.tension:GetLevel("workers", "elite") > 50
           and not ctx.history:HasMadeChoice("workers_grievance")
    end,

    presentation = {
        title = "Worker's Grievance",
        narrative = function(ctx)
            local baseNarrative = [[
A crowd gathers outside the Courthouse.
Their leader, a mason named Vijay, carries a petition.

"We built this city with our HANDS!" he declares.
"Every brick. Every road. Every wall that keeps YOU safe.

The merchants count gold while we count copper.
The elite eat fish while we eat the same grain as always.

We don't want revolution. We want FAIRNESS."
]]

            -- Check for callbacks from past choices
            local additions = ctx:InvokeCallbacks("worker_grievance_choice")

            for _, addition in ipairs(additions) do
                if addition.extra_dialogue then
                    baseNarrative = baseNarrative .. "\n\n" .. addition.extra_dialogue
                end
                if addition.severity_modifier then
                    -- Store for use in effects
                    ctx._grievance_severity = (ctx._grievance_severity or 1) * addition.severity_modifier
                end
            end

            return baseNarrative
        end,
        mood = "tension"
    },

    -- Options can also be dynamic
    options = function(ctx)
        local baseOptions = {
            {
                id = "accept_all",
                label = "Accept all demands",
                description = "Higher wages, guaranteed rations, council seat",
                tags = { "egalitarian", "worker_friendly" },

                preview = function(ctx)
                    return {
                        "Workers: +20 satisfaction",
                        "Elite: -15 satisfaction, may emigrate",
                        "Production costs: +15%"
                    }
                end,

                first_order = function(ctx)
                    local workers = ctx:GetWorkers()
                    for _, worker in ipairs(workers) do
                        worker:ModifySatisfaction("socialStatus", 20)
                        worker:AddMemory({
                            event = "workers_grievance",
                            type = "demands_accepted",
                            sentiment = "vindicated"
                        })
                    end

                    local elite = ctx:GetCharactersByClass("Elite")
                    for _, e in ipairs(elite) do
                        e:ModifySatisfaction("socialStatus", -15)
                        e:AddMemory({
                            event = "workers_grievance",
                            type = "workers_empowered",
                            sentiment = "threatened"
                        })
                    end

                    ctx:AddTemporaryModifier({
                        id = "higher_wages",
                        type = "production_cost",
                        modifier = 1.15,
                        duration = "permanent",
                        reason = "Increased worker wages"
                    })

                    ctx:SetFlag("worker_council_exists")
                end,

                second_order = function(ctx)
                    ctx.values:Modify("egalitarianism", 20)
                    ctx.values:Modify("worker_solidarity", 15)

                    -- Check for elite emigration
                    ctx:ScheduleEffect(5, function(futureCtx)
                        local unhappyElite = {}
                        for _, e in ipairs(futureCtx:GetCharactersByClass("Elite")) do
                            if e:GetSatisfaction("socialStatus") < 30 then
                                table.insert(unhappyElite, e)
                            end
                        end

                        for _, e in ipairs(unhappyElite) do
                            if math.random() < 0.3 then
                                futureCtx:TriggerEmigration(e, {
                                    reason = "loss_of_privilege",
                                    narrative = e.name .. " has left for a town that 'respects success'."
                                })
                            end
                        end
                    end)
                end
            },

            {
                id = "accept_wage_only",
                label = "Accept wage increase only",
                description = "Compromise position",
                tags = { "moderate", "compromise" },
                -- ... effects
            },

            {
                id = "reject",
                label = "Reject demands",
                description = "Maintain current order",
                tags = { "authoritarian", "status_quo" },
                -- ... effects
            },

            {
                id = "public_debate",
                label = "Public debate",
                description = "Let the town decide",
                tags = { "democratic" },
                -- ... effects
            }
        }

        -- Check for extra options from past choices
        local additions = ctx:InvokeCallbacks("worker_grievance_choice")
        for _, addition in ipairs(additions) do
            if addition.extra_option then
                table.insert(baseOptions, addition.extra_option)
            end
        end

        return baseOptions
    end,

    weight = 90
}
```

---

## First-Order vs Second-Order Effects

### Effects Matrix by Choice Type

| Choice Type | First-Order (Immediate) | Second-Order (Systemic) |
|-------------|------------------------|------------------------|
| **Resource Crisis** | Resource redistribution, satisfaction ±, productivity ± | Town values shift, class tension, future choice weights |
| **Policy Decision** | Unlock buildings, modifier application | Permanent town identity, NPC reactions, immigration patterns |
| **Character Event** | Individual satisfaction, relationship change | Memory formation, influence spread, legacy effects |
| **External Threat** | Resource loss, death risk, safety satisfaction | Militarism value, future threat frequency, reputation |
| **Moral Dilemma** | Split satisfaction effects | Deep value polarization, character memories, story branches |

### First-Order Effects (Immediate)

These happen immediately when a choice is made:
- Satisfaction changes (individual or group)
- Resource transfers or consumption
- Productivity modifiers (temporary)
- Death/birth events
- Flag setting
- Building unlocks
- Immediate notifications

### Second-Order Effects (Systemic)

These are long-term, systemic consequences:
- Town value shifts (shape identity over time)
- Character memories (affect future interactions)
- Future choice unlocks or locks
- Callback registrations (influence future choices)
- Scheduled effects (trigger in N cycles)
- Immigration/emigration patterns
- Class tension modifications
- Reputation changes

---

## Implementation Priority

### Phase 1: Core Infrastructure
1. **ChoiceContext.lua** - The context object with query/mutation methods
2. **NarrativeSystem.lua** - Main coordinator for triggers and resolution
3. **PlayerChoiceHistory.lua** - Persistence and history tracking
4. **EffectBuilders.lua** - Composition utilities

### Phase 2: UI Integration
5. **ChoiceModal.lua** - UI for presenting choices and options
6. **ChoicePreview.lua** - Show previews before selection
7. Integration with existing game loop

### Phase 3: Persistence & Town Values
8. **TownValueSystem.lua** - Track accumulated values
9. Threshold triggers and unlocks
10. Save/load integration

### Phase 4: Advanced Features
11. Character memory system integration
12. Conditional/gambling outcome resolution
13. Cross-choice callbacks
14. Choice weight modifiers from history

### Phase 5: Content Creation
15. Define Settlement era choices (8-10 choices)
16. Define Village era choices (8-10 choices)
17. Define Town era choices (10-12 choices)
18. Define City era choices (10-12 choices)
19. Define Metropolis era choices (10-12 choices)
20. Balancing and playtesting

---

## Key Design Principles

1. **Choices must feel consequential** - Both immediate feedback AND long-term echoes

2. **No "right" answer** - Every choice has tradeoffs that appeal to different playstyles

3. **History matters** - Past choices should influence future options and their weights

4. **Emergent identity** - Accumulated choices create a unique "town personality"

5. **Transparent consequences** - Players should understand immediate effects before choosing

6. **Hidden depth** - Second-order effects reveal themselves over time, creating "aha" moments

7. **Character-centric** - Choices affect individuals who remember, not just statistics

8. **Composable effects** - Use effect builders to create complex behaviors from simple parts

9. **Testable** - Lambda functions can be unit tested in isolation

10. **Extensible** - New choices can be added without modifying core systems

---

## File Structure

```
code/
  narrative/
    ChoiceContext.lua           -- Context object for choice functions
    NarrativeSystem.lua         -- Main coordinator
    PlayerChoiceHistory.lua     -- History and persistence
    TownValueSystem.lua         -- Town values and thresholds
    EffectBuilders.lua          -- Composable effect utilities

  ui/
    ChoiceModal.lua             -- Modal for presenting choices
    ChoicePreview.lua           -- Preview panel for options

data/
  alpha/
    narrative/
      choices/
        settlement_era.lua      -- Settlement era choices
        village_era.lua         -- Village era choices
        town_era.lua            -- Town era choices
        city_era.lua            -- City era choices
        metropolis_era.lua      -- Metropolis era choices

      town_values.lua           -- Value dimension definitions
      thresholds.lua            -- Threshold trigger definitions
```

---

## Appendix: Complete Hungry Week Choice Definition

```lua
-- data/alpha/narrative/choices/settlement_era.lua

local Effects = require("code.narrative.EffectBuilders")

local SettlementChoices = {}

SettlementChoices.hungry_week = {
    id = "hungry_week",
    era = "settlement",

    trigger = function(ctx)
        return ctx.inventory.food < 10
           and ctx:CyclesSince("food_above_10") >= 3
           and ctx.era == "settlement"
           and not ctx.history:HasMadeChoice("hungry_week")
    end,

    presentation = {
        title = "The Hungry Week",
        narrative = function(ctx)
            local days = ctx:CyclesSince("food_above_10")
            local hungriest = ctx:GetMostDesperateCharacter()

            return string.format([[
The grain stores have been empty for %d days.

%s approaches you with hollow eyes:
"My children haven't eaten since yesterday. Please... is there nothing left?"

You look at the inventory. %d scraps of bread remain.
Enough for some. Not enough for all.

Kamala watches from the doorway. This is YOUR decision now.
            ]], days, hungriest.name, ctx.inventory.bread or 0)
        end,
        speaker = function(ctx)
            return ctx:GetMostDesperateCharacter()
        end,
        mood = "crisis"
    },

    options = {
        -- Option A: Ration Equally
        {
            id = "ration_equally",
            label = "Ration equally",
            description = "Everyone gets the same, even if it's little",
            tags = { "egalitarian", "fair", "safe" },

            available = function(ctx) return true end,

            preview = function(ctx)
                local perPerson = math.floor(ctx.inventory.food / #ctx.characters)
                return {
                    "Each person receives " .. perPerson .. " food",
                    "All citizens: +2 biological satisfaction",
                    "Town value: +10 egalitarianism",
                    "No one is full, but no one is forgotten"
                }
            end,

            first_order = Effects.Sequence(
                function(ctx)
                    local food = ctx.inventory.food
                    local perPerson = math.floor(food / #ctx.characters)
                    ctx.inventory.food = food % #ctx.characters

                    for _, char in ipairs(ctx.characters) do
                        char:AddToPersonalInventory("food", perPerson)
                    end
                end,
                Effects.ModifySatisfaction("all", "biological", 2),
                Effects.AddMemory("all", {
                    event = "hungry_week",
                    type = "shared_equally",
                    sentiment = "solidarity"
                }),
                Effects.SetFlag("chose_equality_hungry_week")
            ),

            second_order = Effects.Sequence(
                Effects.ModifyTownValues({
                    egalitarianism = 10,
                    community_cohesion = 5
                }),
                function(ctx)
                    ctx.history:AddModifier({
                        id = "equality_precedent",
                        type = "choice_affinity",
                        apply = function(choice, option)
                            if option.tags and TableContains(option.tags, "egalitarian") then
                                return { weight_bonus = 0.2, reason = "Equality precedent" }
                            end
                        end,
                        duration = "permanent"
                    })
                end,
                Effects.Delayed(20, function(futureCtx)
                    if futureCtx.values:Get("egalitarianism") > 20 then
                        futureCtx.immigration:AddApplicant({
                            name = "Community-minded immigrant",
                            traits = { "cooperative", "humble" },
                            reason = "Heard of fair treatment during hardship"
                        })
                    end
                end)
            )
        },

        -- Option B: Prioritize Children
        {
            id = "prioritize_children",
            label = "Prioritize children",
            description = "They need it most",
            tags = { "family_focused", "protective" },

            available = function(ctx)
                return ctx:HasFamiliesWithChildren()
            end,

            preview = function(ctx)
                local families = ctx:GetFamiliesWithChildren()
                return {
                    #families .. " families with children receive full rations",
                    "Families: +5 biological satisfaction",
                    "Workers without children: -3 satisfaction, -10% productivity",
                    "Town value: +15 family focus"
                }
            end,

            first_order = function(ctx)
                local families = ctx:GetFamiliesWithChildren()
                local workers = ctx:GetWorkers()

                for _, family in ipairs(families) do
                    for _, member in ipairs(family.members) do
                        member:ModifySatisfaction("biological", 5)
                        member:AddMemory({
                            event = "hungry_week",
                            type = "children_fed",
                            sentiment = "grateful",
                            cycle = ctx.cycle
                        })
                    end
                end

                for _, worker in ipairs(workers) do
                    if not worker:HasChildren() then
                        worker:ModifySatisfaction("biological", -3)

                        local sentiment = "resentful"
                        if worker:HasTrait("selfless") or worker:HasTrait("family_oriented") then
                            sentiment = "understanding"
                        end

                        worker:AddMemory({
                            event = "hungry_week",
                            type = "went_hungry_for_children",
                            sentiment = sentiment,
                            cycle = ctx.cycle
                        })
                    end
                end

                ctx:AddTemporaryModifier({
                    id = "hungry_workers",
                    target = "workers_without_children",
                    type = "productivity",
                    modifier = 0.9,
                    duration = 5,
                    reason = "Workers weakened from hunger"
                })

                ctx.inventory.food = 0
                ctx:SetFlag("chose_children_priority_hungry_week")
            end,

            second_order = function(ctx)
                ctx.values:Modify("family_focus", 15)
                ctx.values:Modify("worker_solidarity", -5)

                ctx.tension:AddIncident({
                    between = { "workers", "families" },
                    severity = 5,
                    cause = "hungry_week_food_priority",
                    decay_rate = 0.5
                })

                ctx.history:UnlockChoice("establish_child_welfare")

                ctx:RegisterCallback("worker_grievance_choice", function(grievanceCtx)
                    local resentful = grievanceCtx:CountCharactersWithMemory(
                        "went_hungry_for_children", "resentful"
                    )
                    if resentful > 3 then
                        return {
                            extra_dialogue = string.format(
                                "Vijay adds: 'Remember the hungry week? %d of us went " ..
                                "without so the children could eat. We didn't complain " ..
                                "then. But this is different.'",
                                resentful
                            ),
                            severity_modifier = 1.2
                        }
                    end
                end)
            end
        },

        -- Option C: Prioritize Workers
        {
            id = "prioritize_workers",
            label = "Prioritize workers",
            description = "Without them, no harvest comes",
            tags = { "pragmatic", "productivity_focused" },

            available = function(ctx) return true end,

            preview = function(ctx)
                local workers = ctx:GetWorkersAssignedToProduction()
                return {
                    #workers .. " production workers receive full rations",
                    "Workers: +5 biological satisfaction, +10% productivity",
                    "Families: -5 satisfaction",
                    "Town value: +15 productivity focus"
                }
            end,

            first_order = function(ctx)
                local workers = ctx:GetWorkersAssignedToProduction()
                local families = ctx:GetFamiliesWithChildren()

                for _, worker in ipairs(workers) do
                    worker:ModifySatisfaction("biological", 5)
                    worker:AddMemory({
                        event = "hungry_week",
                        type = "prioritized_as_worker",
                        sentiment = "validated",
                        cycle = ctx.cycle
                    })
                end

                for _, family in ipairs(families) do
                    for _, member in ipairs(family.members) do
                        member:ModifySatisfaction("biological", -5)

                        local sentiment = "resentful"
                        if member:HasTrait("pragmatic") then
                            sentiment = "understanding"
                        end

                        member:AddMemory({
                            event = "hungry_week",
                            type = "family_went_hungry",
                            sentiment = sentiment,
                            cycle = ctx.cycle
                        })
                    end
                end

                ctx:AddTemporaryModifier({
                    id = "well_fed_workers",
                    target = "workers",
                    type = "productivity",
                    modifier = 1.1,
                    duration = 10,
                    reason = "Workers well-fed and energized"
                })

                ctx.inventory.food = 0
                ctx:SetFlag("chose_workers_priority_hungry_week")
            end,

            second_order = function(ctx)
                ctx.values:Modify("productivity_focus", 15)
                ctx.values:Modify("family_focus", -10)

                if ctx.values:Get("productivity_focus") > 30 then
                    ctx:AddTownTrait("industrious")
                end

                ctx:RegisterCallback("class_divide_choice", function(divideCtx)
                    local resentful = divideCtx:CountCharactersWithMemory(
                        "family_went_hungry", "resentful"
                    )
                    if resentful > 2 then
                        return {
                            extra_option = {
                                id = "family_compensation",
                                label = "Compensate families first",
                                description = "Make up for past sacrifices",
                                tags = { "family_focused", "redemptive" },
                                available = function() return true end,
                                preview = function()
                                    return {
                                        "Prioritize family housing",
                                        "Families: +10 satisfaction",
                                        "Heals old wounds"
                                    }
                                end,
                                first_order = function(compCtx)
                                    -- Implementation
                                end,
                                second_order = function(compCtx)
                                    compCtx.values:Modify("family_focus", 20)
                                end
                            }
                        }
                    end
                end)
            end
        },

        -- Option D: Trust the Harvest (Gamble)
        {
            id = "trust_harvest",
            label = "Trust the harvest",
            description = "It will come. Hold what remains for emergency.",
            tags = { "gamble", "faith", "risky" },

            available = function(ctx)
                return ctx:HasBuilding("farm") and ctx:GetProductionProgress("farm") > 0.5
            end,

            preview = function(ctx)
                local farmProgress = ctx:GetProductionProgress("farm")
                local estimatedCycles = math.ceil((1 - farmProgress) / 0.1)

                return {
                    "Harvest estimated in " .. estimatedCycles .. " cycles",
                    "⚠️ GAMBLE: Outcome depends on harvest timing",
                    "Success: +10 satisfaction for all, leader reputation boost",
                    "Failure: -15 satisfaction, death risk for vulnerable, reputation damage"
                }
            end,

            first_order = function(ctx)
                ctx:SetFlag("waiting_for_harvest_gamble")

                ctx:ScheduleConditionalEffect({
                    id = "harvest_gamble_resolution",

                    check = function(checkCtx)
                        if checkCtx.inventory.food > 20 then
                            return "success"
                        elseif checkCtx:CyclesSince("waiting_for_harvest_gamble") > 5 then
                            return "failure"
                        end
                        return nil
                    end,

                    outcomes = {
                        success = function(successCtx)
                            successCtx:ClearFlag("waiting_for_harvest_gamble")

                            for _, char in ipairs(successCtx.characters) do
                                char:ModifySatisfaction("biological", 10)
                                char:AddMemory({
                                    event = "hungry_week",
                                    type = "harvest_came_through",
                                    sentiment = "relieved",
                                    cycle = successCtx.cycle
                                })
                            end

                            successCtx:ShowNotification({
                                title = "The Harvest Arrives!",
                                text = "Your faith was rewarded. The harvest came just in time.",
                                mood = "celebration"
                            })

                            successCtx:SetFlag("lucky_harvest")

                            -- Second-order for success
                            successCtx.values:Modify("faith", 10)
                            successCtx.history:AddModifier({
                                id = "lucky_leader",
                                type = "reputation",
                                traits = { "visionary", "blessed" },
                                duration = 50
                            })
                        end,

                        failure = function(failCtx)
                            failCtx:ClearFlag("waiting_for_harvest_gamble")

                            for _, char in ipairs(failCtx.characters) do
                                char:ModifySatisfaction("biological", -15)
                                char:AddMemory({
                                    event = "hungry_week",
                                    type = "harvest_gamble_failed",
                                    sentiment = "angry",
                                    cycle = failCtx.cycle
                                })
                            end

                            -- Death risk for vulnerable
                            local vulnerable = failCtx:GetVulnerableCharacters()
                            for _, char in ipairs(vulnerable) do
                                if math.random() < 0.15 then
                                    failCtx:KillCharacter(char, {
                                        cause = "starvation",
                                        narrative = char.name .. " could not survive the hunger."
                                    })
                                end
                            end

                            failCtx:ShowNotification({
                                title = "The Harvest Is Late",
                                text = "Your gamble failed. The people have suffered.",
                                mood = "tragedy"
                            })

                            failCtx:SetFlag("harvest_gamble_failed")

                            -- Second-order for failure
                            failCtx.values:Modify("faith", -5)
                            failCtx.values:Modify("trust_in_leadership", -15)
                            failCtx.history:AddModifier({
                                id = "reckless_leader",
                                type = "reputation",
                                traits = { "reckless", "gambler" },
                                duration = 100
                            })

                            failCtx:RegisterCallback("any_risky_choice", function(riskyCtx)
                                return {
                                    extra_dialogue = "Someone mutters: 'Remember the harvest " ..
                                        "gamble? Some of us have long memories.'",
                                    option_modifiers = {
                                        risky_options = { trust_penalty = -10 }
                                    }
                                }
                            end)
                        end
                    }
                })
            end,

            second_order = function(ctx)
                -- Most second-order effects are in the conditional outcomes
                -- This runs immediately regardless of outcome
                ctx:Log("Player chose to gamble on the harvest")
            end
        }
    },

    weight = 100,
    timeout = nil,
    default_option = "ration_equally"
}

return SettlementChoices
```

---

*This architecture supports the rich narrative scripted in the era document while remaining flexible enough to add new choices without rewriting core systems. The lambda-based approach provides maximum flexibility while the effect builders ensure common patterns remain clean and maintainable.*
