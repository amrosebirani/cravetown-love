# Character Movement & Daily Routine Design Document

## Overview

Characters in CraveTown are not static entities - they move through the world following daily routines, traveling between locations for work, rest, socialization, and consumption. This document defines the movement system, daily schedules, pathfinding, and special cases like homelessness.

---

## Part 1: Basic Movement System

### 1.1 Core Concepts

#### Movement States
Characters can be in one of several movement states:

| State | Description | Visual |
|-------|-------------|--------|
| `idle` | Standing still at current location | Character sprite, no animation |
| `walking` | Moving toward destination | Animated walking sprite |
| `working` | At workplace, performing job | Work animation at building |
| `resting` | At home, sleeping/relaxing | Inside housing (hidden or dim) |
| `consuming` | At consumption point (tavern, market) | Interaction animation |
| `wandering` | No destination, random movement | Slow random walk |
| `traveling` | Long-distance travel (entering/leaving town) | Walking toward edge |

#### Character Location Reference
```lua
character.location = {
    currentPosition = {x = 0, y = 0},      -- World coordinates
    currentBuildingId = nil,               -- If inside a building
    destinationPosition = {x = 0, y = 0},  -- Where heading
    destinationBuildingId = nil,           -- Target building
    movementState = "idle",                -- Current state
    movementSpeed = 50,                    -- Pixels per second (base)
    pathNodes = {},                        -- Pathfinding waypoints
    currentPathIndex = 1,                  -- Progress through path
}
```

### 1.2 Movement Speed Factors

Base movement speed is modified by:

| Factor | Effect | Example |
|--------|--------|---------|
| Class | Higher class = slightly faster | Elite: 1.1x, Lower: 0.9x |
| Age | Old/young slower | Child: 0.7x, Elder: 0.6x |
| Health/Satisfaction | Low satisfaction = slower | <30%: 0.8x speed |
| Terrain | Roads faster, rough terrain slower | Road: 1.2x, Forest: 0.6x |
| Weather | Bad weather slows | Rain: 0.8x, Snow: 0.5x |
| Carrying goods | Heavy loads slow down | Per item weight penalty |
| Time of day | Night movement slower | Night: 0.85x |

### 1.3 Pathfinding

#### Basic Pathfinding (Phase 1)
- Direct line movement toward destination
- Avoid buildings (collision boxes)
- Avoid water (unless bridge)
- Avoid mountains/impassable terrain

#### Advanced Pathfinding (Phase 2)
- A* pathfinding on navigation grid
- Prefer roads when available (faster)
- Use bridges to cross rivers
- Navigate around obstacles efficiently
- Path caching for common routes (home-work, home-market)

#### Navigation Grid
```lua
NavGrid = {
    cellSize = 20,                    -- Grid cell size in pixels
    cells = {},                       -- 2D array of walkability
    roadCells = {},                   -- Cells that are roads (speed bonus)
    bridges = {},                     -- Bridge locations for river crossing
}

-- Cell types
CELL_WALKABLE = 0
CELL_BLOCKED = 1
CELL_ROAD = 2
CELL_WATER = 3
CELL_BRIDGE = 4
```

---

## Part 2: Daily Routine System

### 2.1 Time Slot Activities

Characters follow routines based on time slots:

| Time Slot | Hours | Primary Activity | Secondary Activities |
|-----------|-------|------------------|---------------------|
| Late Night | 0-5 | Sleep at residence | - |
| Early Morning | 5-8 | Wake, breakfast, prepare | Travel to work |
| Morning | 8-12 | Work | - |
| Afternoon | 12-17 | Work (with lunch break) | Shopping, errands |
| Evening | 17-21 | Dinner, leisure | Socialization, tavern |
| Night | 21-24 | Relaxation, return home | Prepare for sleep |

### 2.2 Activity Scheduling

```lua
DailySchedule = {
    -- Each entry: {startHour, endHour, activity, location, priority}

    -- Employed character example
    employed = {
        {0, 5, "sleep", "residence", 100},
        {5, 6, "wake_prepare", "residence", 90},
        {6, 7, "breakfast", "residence", 80},
        {7, 8, "travel", "workplace", 85},
        {8, 12, "work", "workplace", 95},
        {12, 13, "lunch", "market_or_home", 70},
        {13, 17, "work", "workplace", 95},
        {17, 18, "travel", "residence", 85},
        {18, 19, "dinner", "residence", 80},
        {19, 21, "leisure", "tavern_or_home", 60},
        {21, 24, "evening_rest", "residence", 75},
    },

    -- Unemployed character example
    unemployed = {
        {0, 6, "sleep", "residence", 100},
        {6, 8, "wake_prepare", "residence", 70},
        {8, 12, "job_search", "town_center", 80},
        {12, 14, "rest", "residence_or_public", 60},
        {14, 17, "wander", "public_spaces", 50},
        {17, 21, "socialize", "tavern_or_plaza", 65},
        {21, 24, "return_home", "residence", 75},
    },
}
```

### 2.3 Activity Locations

| Activity | Location Type | Fallback Location |
|----------|--------------|-------------------|
| Sleep | Assigned housing | Homeless spot |
| Work | Assigned workplace | None (unemployed) |
| Breakfast/Dinner | Home | Market/tavern |
| Lunch | Market, tavern, home | Workplace area |
| Shopping | Market, shops | None |
| Leisure | Tavern, plaza, park | Wander |
| Worship | Temple, shrine | None |
| Socialization | Public spaces | Near others |

---

## Part 3: Workplace Movement

### 3.1 Commute System

When a character has an assigned workplace:

1. **Morning Commute** (Early Morning → Morning slot transition)
   - Character leaves residence
   - Travels to workplace building
   - Enters building, begins work state

2. **Work Period**
   - Character stays at/in workplace
   - May briefly leave for lunch (if enabled)
   - Visible working animation

3. **Evening Commute** (Afternoon → Evening transition)
   - Character leaves workplace
   - Travels to residence
   - May stop at market/tavern en route

### 3.2 Workplace Behavior

```lua
WorkplaceMovement = {
    -- Arrival behavior
    arriveAtWork = function(character, workplace)
        character.location.currentBuildingId = workplace.id
        character.movementState = "working"
        character.visible = workplace.showWorkers  -- Some buildings hide workers
    end,

    -- Departure behavior
    leaveWork = function(character)
        character.location.currentBuildingId = nil
        character.movementState = "walking"
        character.visible = true
        -- Set destination to home or next activity
    end,

    -- Lunch break (optional based on settings)
    lunchBreak = {
        enabled = true,
        duration = 1,  -- hours
        destinations = {"market", "home", "nearby_tavern"},
    },
}
```

### 3.3 Multi-Shift Work (Advanced)

For buildings that operate in shifts:

| Shift | Hours | Workers |
|-------|-------|---------|
| Day Shift | 6-14 | Group A |
| Evening Shift | 14-22 | Group B |
| Night Shift | 22-6 | Group C |

---

## Part 4: Homelessness System

### 4.1 Homeless Status

A character becomes homeless when:
- No housing assigned (`housingId = nil`)
- Evicted from housing (non-payment, building destroyed)
- New immigrant with no available housing (shouldn't happen with gates)
- Housing destroyed while occupied

### 4.2 Homeless Character Properties

```lua
HomelessCharacter = {
    isHomeless = true,
    homelessSince = cycle,           -- When became homeless
    preferredSleepSpot = nil,        -- Cached sleeping location
    shelterType = "none",            -- none, tree, abandoned, camp

    -- Penalties
    satisfactionPenalty = -20,       -- Constant satisfaction drain
    healthPenalty = -10,             -- Health degradation risk
    productivityMultiplier = 0.6,    -- Reduced work efficiency
    socialPenalty = -15,             -- Other citizens avoid
}
```

### 4.3 Homeless Sleep Locations

When homeless characters need to sleep, they seek shelter in priority order:

| Priority | Location Type | Quality | Weather Protection | Safety |
|----------|--------------|---------|-------------------|--------|
| 1 | Abandoned building | 0.3 | Full | Medium |
| 2 | Under bridge | 0.2 | Partial | Low |
| 3 | Large tree | 0.15 | Minimal | Low |
| 4 | Town well/fountain area | 0.1 | None | Medium |
| 5 | Near warm building (smithy, bakery) | 0.15 | None | Medium |
| 6 | Forest edge | 0.1 | None | Low |
| 7 | Open ground (last resort) | 0.05 | None | Very Low |

### 4.4 Homeless Daily Routine

```lua
HomelessSchedule = {
    {0, 5, "sleep", "shelter_spot", 100},
    {5, 7, "wake_wander", "town_area", 60},
    {7, 9, "seek_food", "market_or_charity", 90},
    {9, 12, "work_if_employed", "workplace", 85},
    {12, 14, "seek_food", "tavern_refuse_or_charity", 80},
    {14, 17, "work_or_wander", "workplace_or_public", 70},
    {17, 19, "seek_shelter", "potential_spots", 85},
    {19, 21, "settle_shelter", "chosen_spot", 90},
    {21, 24, "prepare_sleep", "shelter_spot", 95},
}
```

### 4.5 Homeless Shelter Selection Algorithm

```lua
function FindHomelessShelter(character, world)
    local shelterOptions = {}

    -- Check abandoned buildings
    for _, building in ipairs(world.buildings) do
        if building.abandoned and building.hasRoof then
            table.insert(shelterOptions, {
                type = "abandoned_building",
                position = building.entrance,
                quality = 0.3,
                weatherProtection = 1.0,
                capacity = building.capacity or 4,
            })
        end
    end

    -- Check bridges
    for _, bridge in ipairs(world.bridges) do
        table.insert(shelterOptions, {
            type = "under_bridge",
            position = {x = bridge.x, y = bridge.y + bridge.height},
            quality = 0.2,
            weatherProtection = 0.7,
            capacity = 3,
        })
    end

    -- Check large trees
    for _, tree in ipairs(world.trees) do
        if tree.size == "large" then
            table.insert(shelterOptions, {
                type = "tree",
                position = {x = tree.x, y = tree.y},
                quality = 0.15,
                weatherProtection = 0.3,
                capacity = 2,
            })
        end
    end

    -- Check warm buildings (smithy, bakery, etc.)
    for _, building in ipairs(world.buildings) do
        if building.emitsHeat then
            local nearbySpot = GetNearbySpot(building)
            table.insert(shelterOptions, {
                type = "warm_building_exterior",
                position = nearbySpot,
                quality = 0.15,
                weatherProtection = 0.1,
                warmthBonus = 0.3,
                capacity = 2,
            })
        end
    end

    -- Sort by quality and available capacity
    table.sort(shelterOptions, function(a, b)
        return a.quality > b.quality
    end)

    -- Find available spot (not full)
    for _, option in ipairs(shelterOptions) do
        local currentOccupants = GetHomelessAtLocation(option.position)
        if #currentOccupants < option.capacity then
            return option
        end
    end

    -- Last resort: open ground
    return {
        type = "open_ground",
        position = FindOpenGroundNearTown(),
        quality = 0.05,
        weatherProtection = 0,
        capacity = 999,
    }
end
```

### 4.6 Homeless Visual Indicators

| State | Visual | Animation |
|-------|--------|-----------|
| Wandering | Slower walk, hunched posture | Shuffling walk cycle |
| Sleeping (tree) | Sitting/lying at tree base | Occasional shift |
| Sleeping (ground) | Lying on ground, curled | Shivering if cold |
| Seeking food | Near market, looking around | Watching food stalls |
| Begging (advanced) | Near wealthy areas | Hand out gesture |

### 4.7 Homelessness Effects on Satisfaction

```lua
HomelessnessPenalties = {
    -- Coarse dimension penalties (applied per cycle)
    coarse = {
        physiological = -15,      -- Sleep quality poor
        safety_shelter = -40,     -- Major shelter penalty
        social_belonging = -10,   -- Social stigma
        esteem = -20,             -- Self-esteem impact
    },

    -- Fine dimension penalties
    fine = {
        safety_shelter_housing_basic = -50,    -- No housing
        safety_shelter_security = -20,         -- Vulnerable at night
        physiological_sleep = -25,             -- Poor sleep
        social_belonging_community = -15,      -- Excluded
        esteem_self_dignity = -30,             -- Dignity impact
    },

    -- Weather multipliers (bad weather = worse penalties)
    weatherMultipliers = {
        clear = 1.0,
        rain = 1.5,
        storm = 2.0,
        snow = 2.5,
        extreme_heat = 1.3,
        extreme_cold = 2.5,
    },
}
```

---

## Part 5: Social Movement Patterns

### 5.1 Social Gathering

Characters naturally gravitate toward:
- Other characters with positive relationships
- Public gathering spaces (plaza, market, tavern)
- Events and celebrations

### 5.2 Group Movement

When characters travel together:
- Families move as units
- Friends may walk together if paths overlap
- Work colleagues may commute together

```lua
GroupMovement = {
    familyStickTogether = true,
    friendsGroupChance = 0.3,       -- 30% chance to join friend's path
    colleagueGroupChance = 0.2,     -- 20% chance
    maxGroupSize = 4,
    groupSpeedPenalty = 0.9,        -- Groups 10% slower
}
```

### 5.3 Avoidance Behavior

Characters avoid:
- Hostile characters (rivals)
- Dangerous areas (crime, fire)
- Crowds if introverted (trait-based)
- Homeless (upper class avoidance)

---

## Part 6: Advanced Features

### 6.1 Event-Driven Movement

Special events override normal routines:

| Event | Movement Effect |
|-------|-----------------|
| Fire | Flee area, gather at safe distance |
| Festival | Move to festival location |
| Riot | Join riot or flee depending on satisfaction |
| Market Day | Increased market foot traffic |
| Funeral | Funeral participants travel to cemetery |
| Wedding | Guests travel to venue |

### 6.2 Errand System (Advanced)

Characters may have errands that interrupt routines:

```lua
Errand = {
    type = "shopping",              -- shopping, delivery, visit, worship
    destination = buildingId,
    priority = 60,                  -- Higher overrides schedule
    deadline = nil,                 -- Optional time limit
    items = {"bread", "cloth"},     -- What to acquire
    completed = false,
}
```

### 6.3 Visitor System

Non-resident characters visiting town:
- Traders from other towns
- Traveling merchants
- Pilgrims (if temple exists)
- Family visitors

---

## Part 7: Movement Data Structures

### 7.1 Character Movement State

```lua
CharacterMovement = {
    -- Current state
    state = "idle",                 -- idle, walking, working, resting, etc.

    -- Position
    position = {x = 0, y = 0},
    facing = "right",               -- left, right, up, down

    -- Destination
    destination = nil,              -- {x, y} or nil
    destinationBuilding = nil,      -- building ID or nil
    destinationType = nil,          -- "work", "home", "market", etc.

    -- Path
    path = {},                      -- Array of {x, y} waypoints
    pathIndex = 1,
    pathRecalcTimer = 0,            -- Recalc path every N seconds

    -- Speed
    baseSpeed = 50,                 -- pixels/second
    currentSpeed = 50,              -- after modifiers

    -- Schedule
    currentActivity = "idle",
    nextActivityTime = 0,           -- When to switch
    schedule = {},                  -- Daily schedule reference

    -- Homeless specifics
    isHomeless = false,
    shelterSpot = nil,
    shelterType = nil,
}
```

### 7.2 Movement Configuration

```lua
MovementConfig = {
    -- Speeds (pixels per second)
    speeds = {
        walk = 50,
        run = 100,
        sneak = 25,
        wander = 20,
    },

    -- Pathfinding
    pathfinding = {
        gridSize = 20,
        recalcInterval = 2.0,       -- seconds
        maxPathLength = 500,
        roadSpeedBonus = 1.3,
    },

    -- Schedule
    schedule = {
        activityTransitionTime = 0.5,  -- hours to transition
        lunchBreakEnabled = true,
        lunchBreakDuration = 1,        -- hours
    },

    -- Homeless
    homeless = {
        shelterSearchRadius = 500,
        maxHomelessPerSpot = 4,
        satisfactionPenaltyPerCycle = -5,
    },
}
```

---

## Part 8: Implementation Phases

### Phase 1: Basic Movement
- [ ] Simple point-to-point movement
- [ ] Building collision avoidance
- [ ] Home-work commute
- [ ] Time slot activity changes
- [ ] Basic idle/walking states

### Phase 2: Pathfinding
- [ ] Navigation grid generation
- [ ] A* pathfinding implementation
- [ ] Road preference
- [ ] Bridge usage
- [ ] Path caching

### Phase 3: Daily Routines
- [ ] Full schedule implementation
- [ ] Activity-specific locations
- [ ] Lunch breaks
- [ ] Evening leisure choices
- [ ] Weekend variations (if applicable)

### Phase 4: Homelessness
- [ ] Homeless status tracking
- [ ] Shelter spot selection
- [ ] Visual representation
- [ ] Satisfaction penalties
- [ ] Homeless routine

### Phase 5: Social Movement
- [ ] Group movement
- [ ] Family units
- [ ] Avoidance behaviors
- [ ] Gathering at social spots

### Phase 6: Advanced Features
- [ ] Event-driven movement
- [ ] Errand system
- [ ] Visitors
- [ ] Weather effects on movement

---

## Part 9: UI Considerations

### 9.1 Character Tooltips
Show when hovering:
- Current activity
- Destination (if moving)
- Home/workplace locations
- Homeless status

### 9.2 Movement Overlays
Optional toggles:
- Show character paths
- Show home connections
- Show workplace connections
- Highlight homeless citizens

### 9.3 Homeless Indicators
- Different sprite/color for homeless
- Shelter spot markers
- Warning icon in citizen panel
- Alert when someone becomes homeless

---

## Part 10: Performance Considerations

### 10.1 Optimization Strategies
- Path caching for repeated routes
- LOD (Level of Detail) for distant characters
- Batch pathfinding updates
- Skip movement updates for off-screen characters
- Simplify AI for large populations

### 10.2 Population Scaling
| Population | Movement Detail |
|------------|-----------------|
| <50 | Full pathfinding, all visible |
| 50-100 | Simplified paths, group batching |
| 100-200 | Key characters detailed, others simplified |
| >200 | Statistical movement, key characters only |

---

## Appendix A: Homeless Shelter Types Reference

| Type | Icon | Weather Protection | Comfort | Safety | Notes |
|------|------|-------------------|---------|--------|-------|
| Abandoned Building | House outline | 100% | 0.3 | Medium | Rare, best option |
| Under Bridge | Bridge icon | 70% | 0.2 | Low | Near water |
| Large Tree | Tree icon | 30% | 0.15 | Low | Common |
| Building Exterior (warm) | Fire icon | 10% | 0.15 | Medium | Near smithy/bakery |
| Town Well | Well icon | 0% | 0.1 | Medium | Central location |
| Forest Edge | Trees icon | 20% | 0.1 | Low | Edge of town |
| Open Ground | Ground icon | 0% | 0.05 | Very Low | Last resort |

---

## Appendix B: Activity Priority Reference

Higher priority activities override lower:

| Priority | Activity | Can Interrupt |
|----------|----------|---------------|
| 100 | Sleep (night) | No |
| 95 | Work | Only by emergency |
| 90 | Seek food (hungry) | Only by higher |
| 85 | Travel (commute) | No |
| 80 | Meals | By work |
| 75 | Return home | By emergency |
| 70 | Seek shelter (homeless) | Only by food |
| 60 | Leisure | Most things |
| 50 | Wander | Anything |
| 40 | Socialize (optional) | Most things |
