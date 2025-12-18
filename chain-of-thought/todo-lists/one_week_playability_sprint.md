# Cravetown Alpha - One Week Playability Sprint

**Created:** 2025-12-18
**Target:** Playable Alpha for Expert Game Players
**Team:** 2 Developers + Design Capacity
**Population Target:** 500-1000 citizens

---

## Executive Summary

This document outlines a comprehensive task breakdown to achieve playability. Tasks are organized by **dependency level** - work on any task once its dependencies are complete. This allows maximum parallelization between the two developers.

### Design Decisions (From Clarifications)
- **Story Flow:** Medium - Animated cutscenes with narrator
- **Town Themes:** Indian dishes (Samosa, Poha, Jalebi towns)
- **Debug View:** Both developer and expert player modes
- **Tutorial:** Overlay hints (not full interactive)
- **Population:** 500-1000 citizens target
- **Challenge:** Events disrupt momentum (not escalating difficulty)
- **Character Sprites:** Need library recommendation (see section below)

---

## Sprite/Animation Library Recommendation

For LÖVE2D citizen sprites and animations, I recommend:

### Option 1: **Anim8** (Recommended for Quick Start)
```lua
-- https://github.com/kikito/anim8
-- Simple sprite animation library

local anim8 = require 'anim8'
local spritesheet = love.graphics.newImage('citizens.png')
local grid = anim8.newGrid(32, 32, spritesheet:getWidth(), spritesheet:getHeight())

-- Create walking animation
local walkAnimation = anim8.newAnimation(grid('1-4', 1), 0.1)

function love.update(dt)
    walkAnimation:update(dt)
end

function love.draw()
    walkAnimation:draw(spritesheet, x, y)
end
```

### Option 2: **Peachy** (For Aseprite Integration)
- If using Aseprite for sprite creation: https://github.com/josh-perry/peachy
- Directly imports .json files from Aseprite

### Option 3: **Procedural Generation** (Fastest to Implement)
- Use simple geometric shapes with color variation
- Different shapes for different classes/vocations
- Add satisfaction color halo
- Can upgrade to sprites later

**Recommendation:** Start with **procedural shapes** (already have basic shapes) and add **Anim8** for walking animation. Create simple 4-frame walk cycle sprites later.

---

## Dependency Levels

```
LEVEL 0: No Dependencies (Start Immediately)
══════════════════════════════════════════════
├── [A] Balance Analysis & Tuning
├── [B] Debug Panel Foundation
├── [C] Movement State Machine
├── [D] Bug: Loading Performance (1%)
├── [E] Bug: Recipe Selection Click
├── [F] System Verification (Productivity, Terrain, Economy)
└── [G] Town Template Data Design

LEVEL 1: Depends on Level 0
══════════════════════════════════════════════
├── [H] Pathfinding System (depends on C)
├── [I] Debug Overlays - Building/Citizen (depends on B)
├── [J] Balance Implementation (depends on A)
├── [K] Starter Town JSON Creation (depends on G, A)
├── [L] Bug: Butcher Missing (depends on F verification)
└── [M] Bug: Housing Availability (any time)

LEVEL 2: Depends on Level 1
══════════════════════════════════════════════
├── [N] Daily Routines System (depends on H)
├── [O] Economy Flow Visualization (depends on I)
├── [P] Story Flow / Cutscene System (depends on K)
├── [Q] Specialized Building Types (depends on K)
└── [R] Bug: Input/Output Storage (any time)

LEVEL 3: Depends on Level 2
══════════════════════════════════════════════
├── [S] Character Visual Representation (depends on N)
├── [T] Tutorial Overlay System (depends on any core systems)
├── [U] Supply Chain Viewer (depends on Q)
└── [V] Event System Foundation (depends on J balance)

LEVEL 4: Integration & Polish
══════════════════════════════════════════════
├── [W] Full Integration Testing
├── [X] Remaining Bug Fixes
├── [Y] Final Balance Pass
└── [Z] Documentation & Playtest
```

---

## LEVEL 0: No Dependencies

These can all start immediately in parallel.

---

### [A] Balance Analysis & Tuning
**Effort:** 4-6 hours | **Type:** Design + Data

**Objective:** Ensure 500-1000 citizens can be sustained with proper building ratios.

**Tasks:**
- [ ] A1: Export current production rates per building type
- [ ] A2: Export current consumption rates per citizen per class
- [ ] A3: Calculate required buildings for 500 citizens
- [ ] A4: Calculate required buildings for 1000 citizens
- [ ] A5: Document building ratio recommendations
- [ ] A6: Identify current imbalances
- [ ] A7: Propose rate adjustments (production up OR consumption down)

**Deliverables:**
```
Balance Spreadsheet:
─────────────────────────────────────────────────────────
Commodity    | Consumption/1000/day | Prod/Building/day | Buildings Needed
─────────────────────────────────────────────────────────
Grain        | 2000                 | 50                | 40 farms
Bread        | 1500                 | 30                | 50 bakeries
Meat         | 800                  | 20                | 40 butchers
...
```

**Files to Update:**
- `data/base/consumption_mechanics.json`
- `data/base/building_types.json` (production rates)

---

### [B] Debug Panel Foundation
**Effort:** 4-5 hours | **Type:** Code

**Objective:** Create toggleable debug panel with tabs for different views.

**Tasks:**
- [ ] B1: Create `code/DebugPanel.lua` with basic structure
- [ ] B2: Add toggle hotkey (F12 or ` backtick)
- [ ] B3: Implement tab system (Overview, Citizens, Buildings, Economy, Events)
- [ ] B4: Create Overview tab:
  - Population by class
  - Average satisfaction by dimension (9 coarse)
  - Production rates summary
  - Consumption rates summary
  - Gold balance and flow
- [ ] B5: Add mode toggle: Developer View vs Expert Player View
- [ ] B6: Make panel draggable/collapsible
- [ ] B7: Hook into AlphaUI rendering

**Developer View Features:**
- Raw data dumps
- Memory usage
- Frame time
- Entity counts

**Expert Player View Features:**
- Polished graphs
- Trend indicators
- Recommendations

**File to Create:** `code/DebugPanel.lua`

---

### [C] Movement State Machine
**Effort:** 4-5 hours | **Type:** Code

**Objective:** Create character movement state tracking and basic movement logic.

**Tasks:**
- [ ] C1: Create `code/CharacterMovement.lua`
- [ ] C2: Define movement states enum:
  ```lua
  MOVEMENT_STATE = {
      IDLE = "idle",
      WALKING = "walking",
      WORKING = "working",
      RESTING = "resting",
      CONSUMING = "consuming",
      WANDERING = "wandering"
  }
  ```
- [ ] C3: Add position data to citizen structure:
  ```lua
  citizen.position = {
      x = 0, y = 0,
      targetX = 0, targetY = 0,
      currentBuildingId = nil,
      destinationBuildingId = nil,
      state = "idle",
      speed = 50,
      facing = "right"
  }
  ```
- [ ] C4: Implement `setDestination(citizen, x, y, buildingId)`
- [ ] C5: Implement `updateMovement(citizen, dt)` - linear interpolation toward target
- [ ] C6: Add building entrance point calculation
- [ ] C7: Hook into AlphaWorld:Update()

**File to Create:** `code/CharacterMovement.lua`

---

### [D] Bug: Loading Performance (1%)
**Effort:** 3-4 hours | **Type:** Code - Bug Fix

**Objective:** Fix loading stall at 1% - this is a real performance issue.

**Investigation Tasks:**
- [ ] D1: Profile `AlphaPrototypeState:LoadWorldAsync()`
- [ ] D2: Identify which step takes longest
- [ ] D3: Check if DataLoader operations are blocking
- [ ] D4: Check coroutine yield frequency

**Fix Tasks:**
- [ ] D5: Add more granular progress updates
- [ ] D6: Split heavy operations into smaller chunks with yields
- [ ] D7: Consider lazy loading for non-essential data
- [ ] D8: Add loading substep messages for user feedback

**Likely Culprits:**
- Large JSON file parsing
- World terrain generation
- Building placement validation
- Citizen generation loop

---

### [E] Bug: Recipe Selection Click
**Effort:** 2-3 hours | **Type:** Code - Bug Fix

**Objective:** Fix glitchy click registration in recipe selection UI.

**Investigation Tasks:**
- [ ] E1: Test recipe selection with logging
- [ ] E2: Check MouseReleased event propagation
- [ ] E3: Verify button bounds calculation
- [ ] E4: Check for overlapping clickable elements

**Fix Tasks:**
- [ ] E5: Fix click detection logic
- [ ] E6: Add visual click feedback (button press animation)
- [ ] E7: Add audio click feedback (optional)
- [ ] E8: Test across different screen resolutions

---

### [F] System Verification
**Effort:** 3-4 hours | **Type:** Code - Verification

**Objective:** Verify that key systems from UI spec are actually connected and working.

**Tasks:**
- [ ] F1: **Productivity Impact on Production**
  - Test: Change citizen satisfaction
  - Verify: Production rate changes accordingly
  - If broken: Connect satisfaction → worker productivity → building efficiency

- [ ] F2: **Location/Terrain Multipliers**
  - Test: Place farm on high fertility vs low fertility
  - Verify: Production rate differs
  - If broken: Connect terrain data → building placement → efficiency modifier

- [ ] F3: **Rents System**
  - Test: Citizens in housing
  - Verify: Gold deducted from citizens / added to building owner
  - If broken: Implement rent collection in cycle loop

- [ ] F4: **Building Profits**
  - Test: Production building operating
  - Verify: Profit calculated and added to town treasury
  - If broken: Implement profit calculation

- [ ] F5: **Tax System**
  - Test: End of cycle
  - Verify: Taxes collected based on settings
  - If broken: Implement tax collection

- [ ] F6: Document which systems work and which need implementation
- [ ] F7: Create tickets for non-working systems

---

### [G] Town Template Data Design
**Effort:** 3-4 hours | **Type:** Design

**Objective:** Design the data structure and content for specialized starter towns.

**Tasks:**
- [ ] G1: Define town template JSON schema
- [ ] G2: Design **Samosa Town** (Mumbai):
  - Buildings: Potato Farm, Wheat Farm, Groundnut Farm, Mill, Oil Press, Samosa Kitchen
  - Citizens: 9-12 (farmers, millers, cooks)
  - Starting inventory
  - Production chain balance

- [ ] G3: Design **Poha Town** (Indore):
  - Buildings: Rice Paddy, Groundnut Farm, Onion Farm, Rice Mill, Oil Press, Poha Kitchen
  - Citizens: 10-12
  - Production chain balance

- [ ] G4: Design **Jalebi Town** (Sweet Town):
  - Buildings: Sugarcane Farm, Wheat Farm, Sugar Mill, Flour Mill, Sweet Shop
  - Citizens: 10-12
  - Production chain balance

- [ ] G5: Design **Mining Town** (Generic fallback):
  - Buildings: Iron Mine, Forge
  - Citizens: 8-10
  - Production chain balance

- [ ] G6: Calculate starting resources for each (survive 20+ cycles)
- [ ] G7: Define difficulty rating for each

**Deliverable:** Design document with all town specifications

---

## LEVEL 1: Depends on Level 0

---

### [H] Pathfinding System
**Depends on:** [C] Movement State Machine
**Effort:** 5-6 hours | **Type:** Code

**Objective:** Implement A* pathfinding for citizen movement.

**Tasks:**
- [ ] H1: Create `code/NavGrid.lua`:
  ```lua
  NavGrid = {
      cellSize = 20,          -- Grid cell size in pixels
      cells = {},             -- 2D array: 0=walkable, 1=blocked, 2=road
      width = 0,
      height = 0
  }
  ```
- [ ] H2: Implement `NavGrid:Generate(world)`:
  - Mark building footprints as blocked
  - Mark roads as preferred (lower cost)
  - Mark water as blocked (unless bridge exists)

- [ ] H3: Create `code/Pathfinder.lua`
- [ ] H4: Implement A* algorithm:
  ```lua
  function Pathfinder:FindPath(startX, startY, endX, endY)
      -- Returns array of {x, y} waypoints
  end
  ```
- [ ] H5: Add path cost modifiers:
  - Road: 0.7x cost
  - Grass: 1.0x cost
  - Rough terrain: 1.5x cost

- [ ] H6: Implement path caching for common routes (home→work)
- [ ] H7: Add path recalculation when buildings placed/removed
- [ ] H8: Integrate with CharacterMovement:
  ```lua
  function CharacterMovement:MoveTo(citizen, targetX, targetY)
      citizen.path = Pathfinder:FindPath(citizen.x, citizen.y, targetX, targetY)
      citizen.pathIndex = 1
  end
  ```

**Files to Create:**
- `code/NavGrid.lua`
- `code/Pathfinder.lua`

---

### [I] Debug Overlays - Building/Citizen
**Depends on:** [B] Debug Panel Foundation
**Effort:** 5-6 hours | **Type:** Code

**Objective:** Add detailed debug views for individual buildings and citizens.

**Tasks:**
- [ ] I1: **Citizens Tab in Debug Panel:**
  - Sortable list of all citizens
  - Filter by class, satisfaction level, employment
  - Click to select and show details

- [ ] I2: **Citizen Detail View:**
  - All 49 fine dimensions with values
  - Current craving intensities (top 10)
  - Fatigue per commodity
  - Current schedule/activity
  - Employment info
  - Housing info
  - Movement path (if walking)

- [ ] I3: **Buildings Tab in Debug Panel:**
  - List of all buildings by type
  - Filter by production status
  - Click to select and show details

- [ ] I4: **Building Detail View:**
  - Production queue state
  - Input buffer contents
  - Output buffer contents
  - Worker list with efficiency
  - Bottleneck indicator (what's missing)
  - Production history (last 10 cycles)

- [ ] I5: **World Overlay Modes** (toggle with hotkeys):
  - Satisfaction heatmap (color citizens by satisfaction)
  - Production overlay (show what each building produces)
  - Housing capacity overlay
  - Employment overlay (show unemployed)

- [ ] I6: Add overlay toggle buttons to debug panel

---

### [J] Balance Implementation
**Depends on:** [A] Balance Analysis
**Effort:** 3-4 hours | **Type:** Data

**Objective:** Apply balance changes identified in analysis.

**Tasks:**
- [ ] J1: Update production rates in `building_types.json`
- [ ] J2: Update consumption rates in `consumption_mechanics.json`
- [ ] J3: Update craving decay rates if needed
- [ ] J4: Test with 100 citizens for 50 cycles
- [ ] J5: Test with 500 citizens for 50 cycles
- [ ] J6: Verify town can reach equilibrium
- [ ] J7: Document final balance values

---

### [K] Starter Town JSON Creation
**Depends on:** [G] Town Template Design, [A] Balance Analysis
**Effort:** 4-5 hours | **Type:** Data + Code

**Objective:** Create actual JSON files for starter towns and loading logic.

**Tasks:**
- [ ] K1: Create `data/starting_towns/` directory
- [ ] K2: Create `samosa_town.json`:
  ```json
  {
    "id": "samosa_town",
    "name": "Samosa Town",
    "city": "Mumbai",
    "description": "Street food capital - specializes in samosa production",
    "difficulty": 2,
    "startingPopulation": 12,

    "startingBuildings": [...],
    "startingCitizens": [...],
    "startingInventory": {...},

    "productionChain": {
      "primary": "samosa",
      "buildings": ["potato_farm", "wheat_farm", "groundnut_farm", "mill", "oil_press", "samosa_kitchen"]
    },

    "exports": ["samosa"],
    "imports": ["tools", "clothing"],

    "storyIntro": "Mumbai's street food culture has always been legendary..."
  }
  ```
- [ ] K3: Create `poha_town.json`
- [ ] K4: Create `jalebi_town.json`
- [ ] K5: Create `mining_town.json`
- [ ] K6: Update `NewGameSetup.lua` to show town selection
- [ ] K7: Implement `StarterTownLoader.lua`:
  ```lua
  function StarterTownLoader:LoadTown(townId)
      local data = json.decode(love.filesystem.read("data/starting_towns/" .. townId .. ".json"))
      -- Create buildings, citizens, set inventory
  end
  ```
- [ ] K8: Add town preview in selection UI (show chain, difficulty, description)

**Files to Create:**
- `data/starting_towns/samosa_town.json`
- `data/starting_towns/poha_town.json`
- `data/starting_towns/jalebi_town.json`
- `data/starting_towns/mining_town.json`
- `code/StarterTownLoader.lua`

---

### [L] Bug: Butcher Missing
**Depends on:** [F] System Verification (to understand building registration)
**Effort:** 1-2 hours | **Type:** Bug Fix

**Tasks:**
- [ ] L1: Check `building_types.json` for butcher definition
- [ ] L2: Check building menu population logic
- [ ] L3: Fix registration if missing
- [ ] L4: Test butcher placement and production

---

### [M] Bug: Housing Availability
**Effort:** 2-3 hours | **Type:** Bug Fix

**Tasks:**
- [ ] M1: Trace housing calculation in immigration modal
- [ ] M2: Identify where "21" comes from
- [ ] M3: Fix calculation to use actual available slots
- [ ] M4: Add unit test for housing calculation

---

## LEVEL 2: Depends on Level 1

---

### [N] Daily Routines System
**Depends on:** [H] Pathfinding System
**Effort:** 5-6 hours | **Type:** Code

**Objective:** Characters follow daily schedules, moving between locations.

**Tasks:**
- [ ] N1: Create `code/DailyRoutine.lua`
- [ ] N2: Define schedule templates:
  ```lua
  SCHEDULES = {
      employed = {
          {0, 5, "sleep", "residence"},
          {5, 6, "wake", "residence"},
          {6, 7, "breakfast", "residence"},
          {7, 8, "commute", "workplace"},
          {8, 12, "work", "workplace"},
          {12, 13, "lunch", "residence_or_market"},
          {13, 17, "work", "workplace"},
          {17, 18, "commute", "residence"},
          {18, 19, "dinner", "residence"},
          {19, 21, "leisure", "tavern_or_residence"},
          {21, 24, "rest", "residence"}
      },
      unemployed = {...},
      homeless = {...}
  }
  ```
- [ ] N3: Implement `getCurrentActivity(citizen, hour)`:
  - Look up schedule based on employment status
  - Return activity type and location type

- [ ] N4: Implement `resolveLocation(citizen, locationType)`:
  - "residence" → citizen's assigned housing building
  - "workplace" → citizen's assigned work building
  - "market" → nearest market building
  - "tavern" → nearest tavern building

- [ ] N5: Connect to time system:
  - On slot change, recalculate all citizen destinations
  - Trigger movement to new destinations

- [ ] N6: Add homeless special case:
  - Find shelter spots (under trees, near warm buildings)
  - Wandering behavior when not sleeping

- [ ] N7: Add activity-specific states:
  - Working: Stay at workplace, show work indicator
  - Resting: Stay at home, possibly invisible (inside)
  - Commuting: Walking between locations

---

### [O] Economy Flow Visualization
**Depends on:** [I] Debug Overlays
**Effort:** 4-5 hours | **Type:** Code

**Objective:** Visualize how resources flow through the town economy.

**Tasks:**
- [ ] O1: Create Economy tab in Debug Panel
- [ ] O2: Implement Sankey-style flow diagram:
  ```
  PRODUCTION          INVENTORY           CONSUMPTION
  ──────────          ─────────           ───────────

  Farm (40) ────────┐
                    ├───► Wheat (500) ───┬──► Elite (50)
  Farm (35) ────────┘                    ├──► Upper (100)
                                         ├──► Middle (200)
                                         └──► Lower (150)
  ```
- [ ] O3: Add commodity filter (view single commodity flow)
- [ ] O4: Show surplus/deficit indicators
- [ ] O5: Add trend sparklines (last 10 cycles)
- [ ] O6: Show gold flow separately:
  - Sources: Building profits, taxes
  - Sinks: Wages, building costs, imports

---

### [P] Story Flow / Cutscene System
**Depends on:** [K] Starter Town JSON
**Effort:** 6-8 hours | **Type:** Code + Content

**Objective:** Animated introduction cutscenes with narrator for each starter town.

**Tasks:**
- [ ] P1: Create `code/CutsceneSystem.lua`:
  ```lua
  Cutscene = {
      slides = {},          -- Array of slide data
      currentSlide = 1,
      textProgress = 0,     -- For typewriter effect
      state = "idle"        -- idle, playing, waiting_input
  }
  ```
- [ ] P2: Define slide structure:
  ```lua
  Slide = {
      background = "story/mumbai_intro_1.png",
      characters = {},      -- Character positions on screen
      text = "Long ago, traders from distant lands...",
      narrator = true,
      duration = 5,         -- Auto-advance after 5 seconds (or click)
      animation = "fade_in" -- Transition type
  }
  ```
- [ ] P3: Implement cutscene renderer:
  - Background image
  - Overlay characters (simple sprites for now)
  - Text box at bottom with typewriter effect
  - "Click to continue" prompt

- [ ] P4: Create story content for Samosa Town:
  ```
  Slide 1: "The streets of Mumbai have always been alive with the aroma of spices..."
  Slide 2: "A small group of settlers ventured out, carrying their family recipes..."
  Slide 3: "They found fertile land, and with it, a chance to build something new..."
  Slide 4: "Now, it's your turn to lead them. Will you create the ultimate Samosa Town?"
  ```
- [ ] P5: Create story content for Poha Town
- [ ] P6: Create story content for Jalebi Town
- [ ] P7: Create story content for Mining Town
- [ ] P8: Add skip button for replays
- [ ] P9: Integrate with NewGameSetup flow:
  - Select town → Play cutscene → Start game

**Files to Create:**
- `code/CutsceneSystem.lua`
- `data/story/samosa_town_intro.json`
- `data/story/poha_town_intro.json`
- `data/story/jalebi_town_intro.json`
- `data/story/mining_town_intro.json`

**Note:** For art, use placeholder colored rectangles or simple procedural backgrounds initially.

---

### [Q] Specialized Building Types
**Depends on:** [K] Starter Town JSON
**Effort:** 4-5 hours | **Type:** Data + Code

**Objective:** Add all buildings needed for Indian dish production chains.

**Tasks:**
- [ ] Q1: Add to `building_types.json`:

  **Samosa Chain:**
  - `potato_farm` (produces: potatoes)
  - `wheat_farm` (produces: wheat)
  - `groundnut_farm` (produces: groundnuts)
  - `flour_mill` (wheat → flour)
  - `oil_press` (groundnuts → oil)
  - `samosa_kitchen` (potato + flour + oil → samosa)

  **Poha Chain:**
  - `rice_paddy` (produces: rice)
  - `onion_farm` (produces: onions)
  - `rice_mill` (rice → flattened_rice)
  - `poha_kitchen` (flattened_rice + onions + oil + peanuts → poha)

  **Jalebi Chain:**
  - `sugarcane_farm` (produces: sugarcane)
  - `sugar_mill` (sugarcane → sugar)
  - `sweet_shop` (flour + sugar + oil → jalebi)

- [ ] Q2: Add corresponding commodities to `commodities.json`:
  - potatoes, groundnuts, sugarcane
  - flour, oil, flattened_rice, sugar
  - samosa, poha, jalebi

- [ ] Q3: Define fulfillment vectors for new commodities
- [ ] Q4: Add building icons (placeholder colored squares)
- [ ] Q5: Test each production chain independently

---

### [R] Bug: Input/Output Storage
**Effort:** 3-4 hours | **Type:** Bug Fix

**Tasks:**
- [ ] R1: Review building input buffer implementation
- [ ] R2: Review building output buffer implementation
- [ ] R3: Identify specific issues (overflow? underflow? not saving?)
- [ ] R4: Fix storage logic
- [ ] R5: Add storage capacity display in building UI

---

## LEVEL 3: Depends on Level 2

---

### [S] Character Visual Representation
**Depends on:** [N] Daily Routines
**Effort:** 4-5 hours | **Type:** Code

**Objective:** Render citizens in world view with appropriate visuals.

**Tasks:**
- [ ] S1: Enhance citizen rendering in `AlphaWorld.lua`:
  - Draw citizens at their world positions
  - Different colors/shapes for different classes
  - Satisfaction indicator (colored halo: green/yellow/red)

- [ ] S2: Add movement animation:
  - Simple oscillating motion while walking
  - Or: Integrate Anim8 for sprite animation

- [ ] S3: Add state indicators:
  - Working: Tool icon above head
  - Resting: Zzz icon
  - Eating: Food icon
  - Protesting: Exclamation mark
  - Homeless: Different posture/color

- [ ] S4: Add facing direction:
  - Flip sprite based on movement direction

- [ ] S5: Implement LOD (Level of Detail):
  - Zoomed out: Simple dots
  - Zoomed in: Full detail
  - Far edge: Don't render

- [ ] S6: Add click selection:
  - Click citizen → Show in right panel
  - Highlight selected citizen

---

### [T] Tutorial Overlay System
**Depends on:** Core systems stable
**Effort:** 4-5 hours | **Type:** Code + Content

**Objective:** Overlay hints that guide new players without blocking gameplay.

**Tasks:**
- [ ] T1: Create `code/TutorialOverlay.lua`:
  ```lua
  TutorialOverlay = {
      hints = {},
      currentHintIndex = 1,
      hintsShown = {},      -- Track which hints already shown
      enabled = true
  }
  ```
- [ ] T2: Define hint structure:
  ```lua
  Hint = {
      id = "camera_controls",
      trigger = "game_start",         -- When to show
      position = {x = 0.5, y = 0.1},  -- Screen position (0-1)
      text = "Use WASD or Arrow keys to move the camera",
      highlightElement = nil,         -- Optional UI element to highlight
      dismissAfter = 10,              -- Auto-dismiss after 10 seconds
      dismissOnAction = "camera_moved" -- Or dismiss when action taken
  }
  ```
- [ ] T3: Create hint content:
  ```
  1. Camera controls (on start)
  2. Time controls (after 5 seconds)
  3. Building menu (after 10 seconds)
  4. Worker assignment (when first building placed)
  5. Citizen satisfaction (when first citizen selected)
  6. Production (when building starts producing)
  7. Immigration (when first immigrant arrives)
  ```
- [ ] T4: Implement hint renderer:
  - Semi-transparent box with text
  - Optional arrow pointing to UI element
  - "Got it" button or auto-dismiss

- [ ] T5: Add highlight system:
  - Pulse animation on highlighted element
  - Darken rest of screen slightly

- [ ] T6: Track hint progress:
  - Don't show same hint twice
  - Save progress to settings

- [ ] T7: Add "Reset Tutorial" option in settings

**File to Create:** `code/TutorialOverlay.lua`

---

### [U] Supply Chain Viewer
**Depends on:** [Q] Specialized Building Types
**Effort:** 4-5 hours | **Type:** Code

**Objective:** Show visual diagram of how each commodity is produced.

**Tasks:**
- [ ] U1: Create `code/SupplyChainViewer.lua`
- [ ] U2: Build chain data from commodities and recipes:
  ```lua
  function SupplyChainViewer:BuildChain(commodityId)
      -- Trace backwards from final product
      -- Find all inputs and their sources
      -- Build tree structure
  end
  ```
- [ ] U3: Render chain diagram:
  ```
  ┌─────────────────────────────────────────────────────────┐
  │ SUPPLY CHAIN: Samosa                                    │
  ├─────────────────────────────────────────────────────────┤
  │                                                         │
  │   🥔 Potato ──────┐                                     │
  │   (Potato Farm)   │                                     │
  │                   ├───► 🏭 Flour Mill ─────┐            │
  │   🌾 Wheat ───────┤     (→ Flour)          │            │
  │   (Wheat Farm)    │                        ├──► 🥟 Samosa│
  │                   │                        │   (Kitchen) │
  │   🥜 Groundnut ───┤                        │            │
  │   (Groundnut Farm)└───► 🏭 Oil Press ──────┘            │
  │                        (→ Cooking Oil)                  │
  │                                                         │
  └─────────────────────────────────────────────────────────┘
  ```
- [ ] U4: Show requirements calculation:
  - For X output, you need Y of each input
  - Calculate worker requirements
  - Calculate gold investment

- [ ] U5: Show current vs needed:
  - ✅ Have: 2 Potato Farms
  - ❌ Need: 1 more Flour Mill

- [ ] U6: Add "Build This Chain" button:
  - Enter build mode with buildings in sequence

- [ ] U7: Access from:
  - Info panel (I key)
  - Building detail panel
  - Commodity tooltip

**File to Create:** `code/SupplyChainViewer.lua`

---

### [V] Event System Foundation
**Depends on:** [J] Balance Implementation (need stable baseline)
**Effort:** 4-5 hours | **Type:** Code

**Objective:** Create disruptive events that challenge player's equilibrium.

**Tasks:**
- [ ] V1: Create `code/EventSystem.lua`:
  ```lua
  EventSystem = {
      possibleEvents = {},
      activeEvents = {},
      eventCooldown = 50,    -- Minimum cycles between events
      lastEventCycle = 0
  }
  ```
- [ ] V2: Define event types:
  ```lua
  Events = {
      drought = {
          name = "Drought",
          description = "Water sources dry up, farm production reduced",
          duration = 10,    -- Cycles
          effects = {
              productionMultiplier = {farm = 0.5}
          },
          triggers = {minPopulation = 100, minCycle = 50}
      },
      pest_infestation = {
          name = "Pest Infestation",
          description = "Crops are being destroyed by pests",
          ...
      },
      disease_outbreak = {
          name = "Disease Outbreak",
          description = "Illness spreads, workers less productive",
          ...
      },
      trade_opportunity = {
          name = "Trade Caravan",
          description = "Traders offer good prices for your goods",
          ...  -- Positive event
      },
      immigration_wave = {
          name = "Refugees Arrive",
          description = "A large group seeks shelter in your town",
          ...
      }
  }
  ```
- [ ] V3: Implement event triggering:
  - Random chance each cycle
  - Weight by town conditions
  - Respect cooldown

- [ ] V4: Implement event effects:
  - Modify production rates
  - Modify consumption rates
  - Add/remove citizens
  - Affect satisfaction

- [ ] V5: Create event notification UI:
  - Modal announcement when event starts
  - Ongoing indicator in top bar
  - Notification when event ends

- [ ] V6: Create 5-10 initial events for variety

**File to Create:** `code/EventSystem.lua`

---

## LEVEL 4: Integration & Polish

---

### [W] Full Integration Testing
**Effort:** 4-6 hours | **Type:** Testing

**Tasks:**
- [ ] W1: Start new Samosa Town game
- [ ] W2: Play through 100 cycles
- [ ] W3: Verify all systems work together:
  - Citizens move to work/home
  - Production runs
  - Consumption happens
  - Satisfaction changes
  - Immigration works
  - Events trigger

- [ ] W4: Test with 500 citizens
- [ ] W5: Test with 1000 citizens
- [ ] W6: Measure performance (target: 60 FPS)
- [ ] W7: Document any issues found

---

### [X] Remaining Bug Fixes
**Effort:** 3-4 hours | **Type:** Bug Fix

**Tasks:**
- [ ] X1: Quality tier random values fix
- [ ] X2: Forest not in mini map fix
- [ ] X3: Version manager data cloning fix
- [ ] X4: Any bugs discovered during integration testing

---

### [Y] Final Balance Pass
**Effort:** 2-3 hours | **Type:** Design

**Tasks:**
- [ ] Y1: Playtest each starter town
- [ ] Y2: Adjust starting resources if needed
- [ ] Y3: Adjust production rates if needed
- [ ] Y4: Verify difficulty feels right
- [ ] Y5: Document final numbers

---

### [Z] Documentation & Playtest
**Effort:** 2-3 hours | **Type:** Documentation

**Tasks:**
- [ ] Z1: Update README with play instructions
- [ ] Z2: Document keyboard shortcuts
- [ ] Z3: Create quick reference card for mechanics
- [ ] Z4: Get external playtest feedback
- [ ] Z5: Note issues for post-sprint

---

## Quick Reference: Task Dependencies

```
No Dependencies:          A, B, C, D, E, F, G

A (Balance Analysis)      → J (Balance Implementation)
                          → K (Starter Towns)

B (Debug Foundation)      → I (Debug Overlays)
                          → O (Economy Viz)

C (Movement State)        → H (Pathfinding)
                          → N (Daily Routines)
                          → S (Visual Representation)

F (System Verification)   → L (Butcher Bug)

G (Town Design)           → K (Starter Town JSON)
                          → P (Story/Cutscenes)
                          → Q (Specialized Buildings)

H (Pathfinding)           → N (Daily Routines)

I (Debug Overlays)        → O (Economy Viz)

K (Starter Towns)         → P (Story Flow)
                          → Q (Specialized Buildings)

N (Daily Routines)        → S (Visual Representation)

Q (Specialized Buildings) → U (Supply Chain Viewer)

J (Balance Impl)          → V (Event System)

All Core Systems          → T (Tutorial)
                          → W (Integration Testing)
```

---

## Parallel Work Assignment (Suggestion)

### Developer 1 Focus: Core Systems & Movement
- C → H → N → S (Movement chain)
- D (Loading fix)
- V (Event system)

### Developer 2 Focus: UI & Data
- B → I → O (Debug panel chain)
- K → P → Q → U (Town content chain)
- E, L, M, R (Bug fixes)

### Both / Designer:
- A → J (Balance)
- F (Verification)
- G (Design)
- T (Tutorial)
- W, X, Y, Z (Integration)

---

## Success Metrics

### Minimum Viable Playability ✓
- [ ] Can select and start a specialized town (Samosa Town minimum)
- [ ] Citizens visually present and moving in world
- [ ] Production and consumption balanced (town survives 100+ cycles)
- [ ] Debug panel shows internal state
- [ ] No critical bugs blocking gameplay
- [ ] Basic tutorial hints explain mechanics

### Full Playability Goal ✓
- [ ] All 4 starter towns available with cutscene intros
- [ ] Full character movement with daily routines
- [ ] Comprehensive debug visualization (both modes)
- [ ] Supply chain viewer working
- [ ] Event system creating disruptions
- [ ] All reported bugs fixed
- [ ] 500-1000 citizens at 60 FPS

---

## Files Summary

### To Create
```
code/CharacterMovement.lua
code/NavGrid.lua
code/Pathfinder.lua
code/DailyRoutine.lua
code/DebugPanel.lua
code/StarterTownLoader.lua
code/CutsceneSystem.lua
code/TutorialOverlay.lua
code/SupplyChainViewer.lua
code/EventSystem.lua

data/starting_towns/samosa_town.json
data/starting_towns/poha_town.json
data/starting_towns/jalebi_town.json
data/starting_towns/mining_town.json
data/story/samosa_town_intro.json
data/story/poha_town_intro.json
data/story/jalebi_town_intro.json
data/story/mining_town_intro.json
```

### To Update
```
code/AlphaWorld.lua (citizen rendering, movement)
code/AlphaUI.lua (debug panel, supply chain viewer)
code/NewGameSetup.lua (town selection)
code/AlphaPrototypeState.lua (loading optimization)
data/base/building_types.json (new buildings, balance)
data/base/commodities.json (new commodities)
data/base/consumption_mechanics.json (balance)
```

---

*Document created: 2025-12-18*
*Ready for sprint execution*
