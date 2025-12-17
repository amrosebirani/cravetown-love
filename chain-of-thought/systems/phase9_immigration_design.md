# Phase 9: Immigration System Design for Alpha Prototype

## Overview

Immigration is how players grow their town population. Potential immigrants appear based on a mix of town attractiveness, town needs, and randomness. Players review applicants and decide who to accept, reject, or defer.

---

## 1. Immigrant Pool Generation

### 1.1 Generation Formula

Each generation cycle (every 5 days), generate new applicants using this distribution:

| Source | Weight | Description |
|--------|--------|-------------|
| **Attraction-Based** | 50% | Class weighted by town's class attractiveness scores |
| **Needs-Based** | 25% | Vocations matching unfilled job positions |
| **Random** | 25% | Fully random class/vocation for variety |

### 1.2 Pool Size

- **Queue Capacity:** 10 applicants maximum
- **Generation Frequency:** Every 5 days
- **New Applicants Per Cycle:** Fill queue up to 10 (generate `10 - currentQueueSize` new applicants)

### 1.3 Applicant Expiry

- Each applicant has a random expiry between **10-20 days**
- Expired applicants are automatically removed from queue
- Player is notified when applicants expire: "Marcus Chen has found another town"

### 1.4 Attraction-Based Generation (50%)

Calculate class attractiveness scores:

```lua
function CalculateClassAttractiveness(class)
    local baseAttraction = 50

    -- Factor 1: Average satisfaction of existing citizens of this class
    local classSatisfaction = GetAverageClassSatisfaction(class)
    local satBonus = (classSatisfaction - 50) * 0.5  -- -25 to +25

    -- Factor 2: Available housing for this class
    local housingAvailable = GetVacantHousingForClass(class) > 0
    local housingBonus = housingAvailable and 15 or -20

    -- Factor 3: Economic opportunity (jobs available)
    local jobsAvailable = GetUnfilledJobsForClass(class)
    local jobBonus = math.min(jobsAvailable * 3, 20)

    -- Factor 4: Town reputation (overall happiness)
    local townHappiness = GetOverallTownHappiness()
    local repBonus = (townHappiness - 50) * 0.3  -- -15 to +15

    return math.max(0, math.min(100, baseAttraction + satBonus + housingBonus + jobBonus + repBonus))
end
```

When generating attraction-based immigrants:
1. Calculate attractiveness for each class
2. Use as weights for random class selection
3. Higher attractiveness = more likely to get applicants of that class

### 1.5 Needs-Based Generation (25%)

Analyze town's unfilled positions:

```lua
function GetTownNeeds()
    local needs = {}

    for _, building in ipairs(buildings) do
        local vacantSlots = building.maxWorkers - #building.workers
        if vacantSlots > 0 then
            for _, vocation in ipairs(building.preferredVocations) do
                needs[vocation] = (needs[vocation] or 0) + vacantSlots
            end
        end
    end

    return needs
end
```

Generate immigrants with vocations weighted by need count.

### 1.6 Random Generation (25%)

Fully random selection:
- Random class (uniform distribution)
- Random vocation from class-appropriate list
- Ensures variety and unexpected opportunities

---

## 2. Immigrant Character Generation

### 2.1 Character Properties

When generating an immigrant, randomize:

| Property | Method |
|----------|--------|
| **Name** | Random from name pool (first + last) |
| **Age** | Random within class-appropriate range |
| **Gender** | Random (50/50) |
| **Class** | Based on generation type (attraction/needs/random) |
| **Vocation** | Based on generation type, weighted by class |
| **Traits** | 1-3 random traits from trait pool |
| **Craving Profile** | Generated with class modifiers |
| **Family** | Random chance (30% has spouse, 20% has children) |
| **Starting Wealth** | Based on class |
| **Expiry Days** | Random 10-20 days |

### 2.2 Class-Appropriate Ranges

```lua
local classRanges = {
    Elite = {
        ageMin = 30, ageMax = 70,
        wealthMin = 2000, wealthMax = 5000,
        familyChance = 0.4
    },
    Upper = {
        ageMin = 25, ageMax = 65,
        wealthMin = 800, wealthMax = 2500,
        familyChance = 0.35
    },
    Middle = {
        ageMin = 20, ageMax = 60,
        wealthMin = 200, wealthMax = 800,
        familyChance = 0.5
    },
    Working = {
        ageMin = 18, ageMax = 55,
        wealthMin = 50, wealthMax = 300,
        familyChance = 0.45
    },
    Poor = {
        ageMin = 16, ageMax = 50,
        wealthMin = 0, wealthMax = 100,
        familyChance = 0.3
    }
}
```

### 2.3 Craving Profile Generation

Use existing `CharacterV3.GenerateStartingSatisfactionFine()` with class modifiers.

Top cravings are derived from the lowest satisfaction dimensions (what they seek most).

---

## 3. Compatibility Score Calculation

### 3.1 Formula

Compatibility is a weighted score from multiple factors:

```lua
function CalculateCompatibility(immigrant, town)
    local weights = GetCompatibilityWeights()  -- From game settings

    -- Factor 1: Craving Satisfaction Potential (40% default)
    local cravingScore = CalculateCravingSatisfactionPotential(immigrant, town)

    -- Factor 2: Housing Availability (25% default)
    local housingScore = CalculateHousingMatch(immigrant, town)

    -- Factor 3: Job Availability (25% default)
    local jobScore = CalculateJobMatch(immigrant, town)

    -- Factor 4: Social Fit (10% default)
    local socialScore = CalculateSocialFit(immigrant, town)

    local total = (cravingScore * weights.craving) +
                  (housingScore * weights.housing) +
                  (jobScore * weights.job) +
                  (socialScore * weights.social)

    return math.floor(total)
end
```

### 3.2 Default Weights (Configurable in Game Settings)

```lua
defaultCompatibilityWeights = {
    craving = 0.40,   -- How well town can satisfy their needs
    housing = 0.25,   -- Is appropriate housing available
    job = 0.25,       -- Is matching work available
    social = 0.10     -- Do they fit with existing population
}
```

### 3.3 Craving Satisfaction Potential

```lua
function CalculateCravingSatisfactionPotential(immigrant, town)
    local topCravings = immigrant:GetTopCravings(5)  -- 5 most urgent needs
    local totalScore = 0

    for i, craving in ipairs(topCravings) do
        -- Check if town produces commodities that fulfill this craving
        local canFulfill = CanTownFulfillCraving(town, craving)
        local weight = (6 - i) / 15  -- Weight by priority: 5/15, 4/15, 3/15, 2/15, 1/15
        totalScore = totalScore + (canFulfill * 100 * weight)
    end

    return totalScore
end

function CanTownFulfillCraving(town, craving)
    -- Check production capacity and current inventory
    local commodities = GetCommoditiesForCraving(craving)
    local fulfillment = 0

    for _, commodity in ipairs(commodities) do
        local inInventory = town.inventory[commodity] or 0
        local productionRate = GetTownProductionRate(town, commodity)

        if inInventory > 10 or productionRate > 0 then
            fulfillment = fulfillment + 0.5
        end
        if inInventory > 50 or productionRate > 5 then
            fulfillment = fulfillment + 0.5
        end
    end

    return math.min(1, fulfillment)
end
```

### 3.4 Housing Match

```lua
function CalculateHousingMatch(immigrant, town)
    local class = immigrant.class
    local vacantHousing = GetVacantHousingByClass(town)

    -- Exact class match
    if vacantHousing[class] and vacantHousing[class] > 0 then
        return 100
    end

    -- One class above (willing to live modestly)
    local classAbove = GetClassAbove(class)
    if classAbove and vacantHousing[classAbove] and vacantHousing[classAbove] > 0 then
        return 70
    end

    -- One class below (will be cramped but okay)
    local classBelow = GetClassBelow(class)
    if classBelow and vacantHousing[classBelow] and vacantHousing[classBelow] > 0 then
        return 50
    end

    -- No suitable housing
    return 0
end
```

### 3.5 Job Match

```lua
function CalculateJobMatch(immigrant, town)
    local vocation = immigrant.vocation
    local vocations = immigrant.alternateVocations or {}
    table.insert(vocations, 1, vocation)

    for i, voc in ipairs(vocations) do
        local openings = GetJobOpeningsForVocation(town, voc)
        if openings > 0 then
            -- Primary vocation = 100%, alternates = 80%, 60%, etc.
            return 100 - (i - 1) * 20
        end
    end

    -- Can work as general laborer
    local laborJobs = GetJobOpeningsForVocation(town, "General Labor")
    if laborJobs > 0 then
        return 30
    end

    return 0  -- No work available
end
```

### 3.6 Social Fit

```lua
function CalculateSocialFit(immigrant, town)
    local score = 50  -- Base neutral fit

    -- Bonus if there are others of same class
    local sameClassCount = CountCitizensOfClass(town, immigrant.class)
    score = score + math.min(sameClassCount * 5, 25)

    -- Bonus if there are others with same vocation
    local sameVocationCount = CountCitizensWithVocation(town, immigrant.vocation)
    score = score + math.min(sameVocationCount * 10, 25)

    return math.min(100, score)
end
```

---

## 4. Immigration Queue Management

### 4.1 Queue State

```lua
immigrationQueue = {
    applicants = {},          -- List of immigrant profiles
    lastGenerationDay = 0,    -- Track when we last generated
    generationInterval = 5,   -- Days between generations
}
```

### 4.2 Daily Update

```lua
function UpdateImmigrationQueue(currentDay)
    -- Remove expired applicants
    for i = #queue.applicants, 1, -1 do
        local applicant = queue.applicants[i]
        if currentDay >= applicant.expiryDay then
            LogEvent("immigration", applicant.name .. " found another town")
            table.remove(queue.applicants, i)
        end
    end

    -- Generate new applicants if interval passed
    if currentDay - queue.lastGenerationDay >= queue.generationInterval then
        local toGenerate = 10 - #queue.applicants
        if toGenerate > 0 then
            GenerateNewApplicants(toGenerate)
            queue.lastGenerationDay = currentDay
        end
    end
end
```

### 4.3 Accept/Reject/Defer Actions

```lua
function AcceptApplicant(applicant)
    -- Find housing
    local housing = FindHousingForClass(applicant.class)
    if not housing then
        return false, "No suitable housing available"
    end

    -- Create citizen from applicant
    local citizen = CreateCitizenFromApplicant(applicant)
    citizen.residence = housing

    -- Add family members if any
    if applicant.family then
        for _, familyMember in ipairs(applicant.family) do
            local member = CreateCitizenFromApplicant(familyMember)
            member.residence = housing
            AddCitizen(member)
        end
    end

    -- Add gold to town treasury
    town.gold = town.gold + applicant.startingWealth

    AddCitizen(citizen)
    RemoveFromQueue(applicant)
    LogEvent("immigration", applicant.name .. " has joined the town!")

    return true
end

function RejectApplicant(applicant)
    RemoveFromQueue(applicant)
    LogEvent("immigration", applicant.name .. " was rejected")
end

function DeferApplicant(applicant)
    -- Move to end of queue, reduce remaining days slightly
    RemoveFromQueue(applicant)
    applicant.expiryDay = applicant.expiryDay - 2  -- Impatience penalty
    table.insert(queue.applicants, applicant)
end
```

---

## 5. UI Design

### 5.1 Immigration Panel (Modal)

Accessed via left panel button or 'I' key:

```
+======================================================================+
| IMMIGRATION - Manage Who Joins Your Town                    [X]      |
+======================================================================+
|                                                                      |
| TOWN ATTRACTIVENESS                                                  |
| Overall: [========--] 78/100 (Good)                                  |
|                                                                      |
| By Class:                                                            |
| Elite:   [======----] 62   Upper:  [========--] 78                   |
| Middle:  [=========--] 85  Working: [=======---] 72                  |
| Poor:    [======----] 58                                             |
|                                                                      |
+----------------------------------------------------------------------+
| APPLICANTS (7 waiting)                    Housing Available: 13      |
| Next batch in: 3 days                                                |
+----------------------------------------------------------------------+
|                                                                      |
| +------------------------------------------------------------------+ |
| | Marcus Chen | Age 28 | Middle Class          Expires: 12 days   | |
| | Vocation: Blacksmith                                             | |
| | Traits: [Hardworking] [Ambitious]                                | |
| |                                                                  | |
| | TOP NEEDS:                                                       | |
| | ! Safety & Shelter (HIGH)                                        | |
| | * Achievement (MEDIUM)                                           | |
| | * Social Connection (MEDIUM)                                     | |
| |                                                                  | |
| | OFFERS: Blacksmithing skill, Family (+2), 250 gold               | |
| |                                                                  | |
| | COMPATIBILITY: [========--] 82% - Good fit!                      | |
| |                                                                  | |
| | [ACCEPT]  [REJECT]  [DEFER]  [Details...]                        | |
| +------------------------------------------------------------------+ |
|                                                                      |
| +------------------------------------------------------------------+ |
| | Elena Vasquez | Age 45 | Upper Class          Expires: 8 days    | |
| | Vocation: Merchant                                               | |
| | Traits: [Wealthy] [Demanding]                                    | |
| |                                                                  | |
| | TOP NEEDS:                                                       | |
| | ! Luxury Goods (HIGH)                                            | |
| | ! Status Display (HIGH)                                          | |
| | * Entertainment (MEDIUM)                                         | |
| |                                                                  | |
| | OFFERS: Trade connections, 2500 gold                             | |
| |                                                                  | |
| | COMPATIBILITY: [====------] 45% - Poor fit, may leave quickly    | |
| |                                                                  | |
| | [ACCEPT]  [REJECT]  [DEFER]  [Details...]                        | |
| +------------------------------------------------------------------+ |
|                                                                      |
| [Scroll for more...]                                                 |
|                                                                      |
+----------------------------------------------------------------------+
| BULK: [Accept All >70%] [Reject All <40%]    Policy: [Selective v]   |
+======================================================================+
```

### 5.2 Applicant Detail Modal

When clicking "Details...":

```
+======================================================================+
| APPLICANT: Marcus Chen                                      [X]      |
+======================================================================+
|                                                                      |
| BASIC INFO                                                           |
| Name: Marcus Chen              Age: 28        Gender: Male           |
| Class: Middle                  Vocation: Blacksmith                  |
| Origin: Ironhaven (fled due to mine collapse)                        |
|                                                                      |
| TRAITS                                                               |
| [Hardworking] +15% productivity                                      |
| [Ambitious] +20% career growth, needs achievement                    |
|                                                                      |
| FAMILY                                                               |
| Li Chen (Wife) - Age 26, Homemaker                                   |
| Wei Chen (Son) - Age 4, Child                                        |
|                                                                      |
+----------------------------------------------------------------------+
| NEEDS ANALYSIS                                                       |
+----------------------------------------------------------------------+
|                                                                      |
| COARSE NEEDS (9 categories):                                         |
| Biological:    [========--] 80  Safety:       [==========] 95        |
| Touch:         [======----] 62  Psychological: [=========--] 88      |
| Status:        [=======---] 72  Social:       [=========--] 90       |
| Exotic:        [===-------] 35  Shiny:        [==--------] 25        |
| Vice:          [=---------] 12                                       |
|                                                                      |
| TOP FINE DIMENSIONS:                                                 |
| 1. safety_shelter_housing: 95                                        |
| 2. social_connection_family: 92                                      |
| 3. psychological_achievement: 88                                     |
|                                                                      |
+----------------------------------------------------------------------+
| YOUR TOWN'S ABILITY TO SATISFY                                       |
+----------------------------------------------------------------------+
|                                                                      |
| [OK] Housing: 3 vacant Middle-class homes                            |
| [OK] Safety: Town happiness 72%, stable                              |
| [OK] Work: Forge needs blacksmith!                                   |
| [??] Achievement: Limited career paths                               |
| [OK] Community: Active town events                                   |
|                                                                      |
| PREDICTED SATISFACTION: 78%                                          |
| EMIGRATION RISK: 12% (Low)                                           |
|                                                                      |
+----------------------------------------------------------------------+
| BACKSTORY                                                            |
+----------------------------------------------------------------------+
| "The mines of Ironhaven collapsed last winter, killing many. Marcus  |
|  seeks a safe place to raise his family where he can practice his    |
|  craft. He values stability and community above all else."           |
|                                                                      |
+----------------------------------------------------------------------+
|                                                                      |
|           [ACCEPT]        [REJECT]        [DEFER]                    |
|                                                                      |
+======================================================================+
```

### 5.3 Left Panel Integration

Add to left panel (below alerts):

```
+----------------------------------+
| Immigration                      |
| [=======---] 7 waiting           |
| [!] 2 expire soon                |
| [View Applicants]                |
+----------------------------------+
```

### 5.4 Notification Events

- "New immigrants are waiting!" (when batch generated)
- "[Name] has found another town" (when expired)
- "[Name] has joined the town!" (when accepted)
- "[Name] was rejected" (when rejected)

---

## 6. Procedural Backstory Generation

### 6.1 Template System

Generate backstory from immigrant's craving profile:

```lua
function GenerateBackstory(immigrant)
    local topNeed = immigrant:GetTopCraving()
    local lowDimension = immigrant:GetLowestSatisfaction()

    local templates = {
        safety = {
            "After {hardship}, {name} seeks a safe haven for {family_or_self}.",
            "{name} fled {origin} due to {danger}. {pronoun} needs stability.",
        },
        biological = {
            "{name} left {origin} seeking better food and living conditions.",
            "Famine struck {origin}. {name} hopes to find abundance here.",
        },
        social = {
            "{name} lost {pronoun_possessive} community in {origin}. {pronoun} seeks belonging.",
            "Seeking connection, {name} left the isolation of {origin}.",
        },
        achievement = {
            "{name} outgrew {origin} and seeks new challenges.",
            "Ambitious {name} wants to prove {pronoun_reflexive} in a growing town.",
        },
        status = {
            "{name} seeks recognition that {origin} could never provide.",
            "Once prominent in {origin}, {name} fell from grace and seeks redemption.",
        }
    }

    local hardships = {
        "the great fire", "the plague", "the war", "the famine",
        "the mine collapse", "the flood", "political persecution"
    }

    local dangers = {
        "rising violence", "corrupt lords", "economic collapse",
        "religious persecution", "tribal conflicts"
    }

    -- Fill template with immigrant data
    return FillTemplate(templates[topNeed.category], immigrant, hardships, dangers)
end
```

---

## 7. Implementation Tasks

### Task 9.1: Immigration Data Structures
- Create `ImmigrantProfile` structure
- Add `immigrationQueue` to AlphaWorld
- Add generation settings to game config

### Task 9.2: Immigrant Generation System
- Implement attraction-based generation (50%)
- Implement needs-based generation (25%)
- Implement random generation (25%)
- Character creation with all randomized properties

### Task 9.3: Compatibility Calculation
- Implement craving satisfaction potential
- Implement housing match
- Implement job match
- Implement social fit
- Add configurable weights

### Task 9.4: Queue Management
- Daily expiry check
- Generation interval tracking
- Accept/Reject/Defer actions

### Task 9.5: Immigration Panel UI
- Main immigration modal
- Applicant cards with summary
- Detail modal for full profile
- Left panel integration with notification

### Task 9.6: Procedural Backstory
- Template system
- Variable substitution
- Origin name generation

---

## 8. Files Summary

| File | Action | Purpose |
|------|--------|---------|
| `code/ImmigrationSystem.lua` | Create | Core immigration logic |
| `code/AlphaWorld.lua` | Modify | Integrate immigration queue |
| `code/AlphaUI.lua` | Modify | Immigration panel and modals |
| `data/alpha/immigration_config.json` | Create | Generation settings, templates |
| `data/alpha/names.json` | Create | Name pools for generation |
| `data/alpha/origins.json` | Create | Origin town names and backstory elements |
