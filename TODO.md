# CraveTown Alpha - Implementation Status & TODO

**Document Version:** 1.3
**Last Updated:** 2025-12-10
**Reference:** `chain-of-thought/game_ui_flow_specification.md`

---

## Overview

This document tracks the implementation status of all features specified in the Game UI Flow Specification. Each section maps to the specification document and notes what is implemented, what deviates, and what remains TODO.

---

## COMPLETED FEATURES

### 1. Title Screen & Main Menu (Section 3.1)
**Status:** IMPLEMENTED

| Spec Feature | Implementation Status | Notes |
|--------------|----------------------|-------|
| NEW GAME button | Implemented | Opens New Game Setup flow |
| CONTINUE button | Implemented | Loads quicksave if available |
| LOAD GAME button | Implemented | Opens SaveLoadModal |
| SETTINGS button | Implemented | Opens Settings Panel |
| CREDITS button | Stub | Prints to console only |
| QUIT button | Implemented | Returns to launcher |
| Version display | Implemented | Shows v0.1.0 |

### 2. New Game Setup Flow (Section 3.2)
**Status:** IMPLEMENTED

| Spec Feature | Implementation Status | Notes |
|--------------|----------------------|-------|
| Town Name input | Implemented | Text input field |
| Starting Location selection | Implemented | 6 location options with bonuses |
| Difficulty selection | Implemented | Story/Normal/Challenging/Survival |
| Starting Population slider | Implemented | 5-30 range |
| Class Distribution | Implemented | Balanced/Working/Established/Custom |
| Economic System | Implemented | Communist/Mixed/Free Market |
| Tutorial Preference | Implemented | Full/Tips/None |

**Deviation:** Location selection shows bonuses but map preview is simplified (no visual map, just text descriptions).

### 3. Main Game Screen Layout (Section 4.1-4.6)
**Status:** IMPLEMENTED

| Spec Feature | Implementation Status | Notes |
|--------------|----------------------|-------|
| Top Bar with stats | Implemented | Town name, pop, gold, day, speed |
| Left Panel (Quick Stats) | Implemented | Happiness bars, alerts, mini-map, quick build |
| Center World View | Implemented | Top-down view with buildings/citizens |
| Right Panel (Selection) | Implemented | Shows building or citizen details |
| Bottom Bar (Event Log) | Implemented | Scrollable log with filter |

**Deviations:**
- World view is top-down, not isometric (spec allows both)
- Housing capacity not shown next to population

### 4. Save/Load System (Section 11.1)
**Status:** IMPLEMENTED

| Spec Feature | Implementation Status | Notes |
|--------------|----------------------|-------|
| 5 Save Slots | Implemented | With save/load/delete |
| Slot metadata display | Implemented | Town name, cycle, pop, satisfaction |
| Autosave toggle | Implemented | With interval setting |
| F5 Quicksave | Implemented | Works during gameplay |
| F9 Quickload | Implemented | Works during gameplay |
| Last save timestamps | Implemented | Displayed in modal |

### 5. Keyboard Shortcuts (Section 13.1-13.2)
**Status:** IMPLEMENTED

| Spec Feature | Implementation Status | Notes |
|--------------|----------------------|-------|
| SPACE - Pause/Resume | Implemented | Works |
| 1/2/3/4 - Speed 1x/2x/5x/10x | Implemented | All speeds work |
| B - Build menu | Implemented | Opens build modal |
| C - Citizens panel | Implemented | Opens citizens overview |
| I - Inventory | Implemented | Opens inventory panel |
| P - Production Analytics | Implemented | Opens production panel |
| S - Settings | Implemented | Opens settings panel |
| A - Analytics | Implemented | Placeholder panel |
| M - Immigration | Implemented | Opens immigration modal |
| ESC - Close panel | Implemented | Works for all modals |
| F5/F9 - Save/Load | Implemented | Quicksave/load |
| H - Help overlay | Implemented | Shows keyboard shortcuts |
| WASD/Arrows - Pan | Implemented | Camera movement |
| Scroll - Zoom | Implemented | Mouse wheel zoom |
| R - Resource overlay | Implemented | Toggle resource view |
| L - Save/Load menu | Implemented | Opens save/load modal |

### 6. River/Forest/Natural Resources
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| River with curves | Implemented | Procedural generation with water shader |
| Lake at river end | Implemented | Organic polygon shape |
| Forest regions | Implemented | Avoids river, multiple regions |
| Natural resources overlay | Implemented | Toggle with R key |
| Resource masking | Implemented | No resources in water/forest |
| River on mini-map | Implemented | Shows river path |

### 7. Recipe Picker Modal
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| Recipe selection for buildings | Implemented | Modal opens when clicking recipe slot |
| Recipe list with inputs/outputs | Implemented | Shows all compatible recipes |
| Recipe details display | Implemented | Input requirements, output quantities |
| Recipe assignment to station | Implemented | Assigns selected recipe to building slot |
| Multiple recipe slots per building | Implemented | Buildings can have multiple production slots |

**Location:** `code/RecipePickerModal.lua`

### 8. Production System
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| Building production cycles | Implemented | Time-based production with efficiency |
| Recipe-based production | Implemented | Buildings produce based on assigned recipes |
| Input consumption | Implemented | Production consumes required inputs |
| Output generation | Implemented | Produced goods added to inventory |
| Efficiency calculation | Implemented | Based on workers, resources, location |

### 9. Citizens Overview Panel (Section 7.1)
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| View modes (Grid/List) | Implemented | Toggle between views |
| Class filter | Implemented | All/Elite/Upper/Middle/Lower |
| Status filter | Implemented | All/Happy/Neutral/Stressed/Critical/Protesting |
| Sorting | Implemented | Satisfaction/Name/Class/Age/Vocation |
| Pagination | Implemented | Page X of Y with Prev/Next |
| Citizen cards | Implemented | Shows name, class, vocation, status, satisfaction |
| Workplace display | Implemented | Shows assigned workplace |
| Summary statistics | Implemented | Average satisfaction, counts by status |

**Location:** `code/AlphaUI.lua` (RenderCitizensPanel)

### 10. Inventory Panel (Section 8.1)
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| Category tabs | Implemented | Dynamic from commodity data |
| Scrollable category list | Implemented | With mouse wheel support |
| Commodity list | Implemented | Shows quantities per category |
| All categories view | Implemented | Shows everything |
| Filter by category | Implemented | Click category to filter |

**Location:** `code/AlphaUI.lua` (RenderInventoryPanel)

### 11. Production Analytics Panel
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| Commodities tab | Implemented | Production rates, consumption, net, stock |
| Buildings tab | Implemented | Efficiency rankings with status |
| Worker utilization | Implemented | Shows employment percentage |
| Commodity detail view | Implemented | Depletion estimates, status |
| Building efficiency bars | Implemented | Color-coded by efficiency level |
| Keyboard shortcut (P) | Implemented | Toggle panel |

**Location:** `code/AlphaUI.lua` (RenderProductionAnalyticsPanel)

### 12. Free Agency System (Workplace Selection)
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| Autonomous workplace selection | Implemented | Citizens choose based on preferences |
| Vocation-based matching | Implemented | Matches worker types to work categories |
| Skill compatibility | Implemented | Citizens prefer matching workplaces |
| Daily job seeking | Implemented | Unemployed citizens seek work each day |

**Design Note:** This is a deliberate deviation from spec's manual worker assignment - uses emergent gameplay model.

**Location:** `code/FreeAgencySystem.lua`

### 13. Settings Panel (Section 11.2)
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| Gameplay Tab | Implemented | Auto-pause, tutorial hints, autosave settings |
| Display Tab | Implemented | Fullscreen, vsync, UI scale, color blind mode |
| Audio Tab | Implemented | Placeholder with volume sliders |
| Accessibility Tab | Implemented | Larger text, high contrast, reduced motion |
| Reset to Defaults | Implemented | Per-tab reset button |
| Settings persistence | Implemented | Saves to JSON file |
| Keyboard shortcut (S) | Implemented | Toggle panel |

**Location:** `code/AlphaUI.lua` (RenderSettingsPanel), `code/GameSettings.lua`

### 14. Immigration System Enhancements (Section 5.2-5.3)
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| Town Attractiveness Display | Implemented | Progress bar with color coding |
| Compatibility Score breakdown | Implemented | Housing, Job, Social, Needs scores |
| Bulk Actions | Implemented | Accept 70%+, Accept All, Reject All |
| Primary Needs display | Implemented | Top 4 cravings shown |
| Traits as chips | Implemented | Styled trait display |
| Family member cards | Implemented | With dependent indicators |
| Scrollable detail panel | Implemented | Mouse wheel support |
| Initial applicants | Implemented | 5-8 generated at game start |

**Location:** `code/AlphaUI.lua` (RenderImmigrationModal), `code/ImmigrationSystem.lua`

### 15. Build Menu Improvements (Section 6.1)
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| Search bar | Implemented | Text input with real-time filtering |
| Category tabs | Implemented | All/Housing/Production/Agriculture/Extraction/Services |
| Grid layout | Implemented | Card-based layout with scroll support |
| Building cards | Implemented | Shows name, cost, capacity, workers |
| Affordability indicator | Implemented | Cards dimmed when can't afford |
| Scroll support | Implemented | Mouse wheel scrolling in grid |

**Location:** `code/AlphaUI.lua` (RenderBuildMenuModal)

### 16. Character Detail Modal (Section 7.2)
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| 49-Dimension View | Implemented | Expandable coarse→fine dimensions |
| Top Current Cravings | Implemented | Top 10 most urgent cravings |
| Commodity Fatigue display | Implemented | Effectiveness bars per commodity |
| Possessions section | Implemented | Durables with remaining cycles |
| Consumption History | Implemented | Last 20 cycles with success/failure |
| Economy & Wealth | Implemented | Wealth, income, expenses, rank, class |
| Housing section | Implemented | Current residence, rent, satisfaction |
| Status & Risks | Implemented | Emigration/protest risk, productivity |

**Location:** `code/CharacterDetailPanel.lua`

### 17. Land Ownership System (Phase 8)
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| Land grid overlay | Implemented | Toggle with L key |
| Land overlay legend | Implemented | Toggle with SHIFT+L |
| Plot ownership display | Implemented | Color-coded by owner |
| Hover tooltips | Implemented | Shows plot details, price, owner |
| Land registry panel | Implemented | Full registry management |
| Building ownership | Implemented | Track owner per building |

**Location:** `code/LandOverlay.lua`, `code/LandSystem.lua`, `code/LandRegistryPanel.lua`

### 18. Housing System (Phase 8)
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| Housing overview panel | Implemented | Toggle with G key |
| Housing assignments | Implemented | Citizens assigned to residences |
| Rent tracking | Implemented | Per-occupant rent |
| Housing satisfaction | Implemented | Quality, space, location factors |
| Housing assignment modal | Implemented | Manage assignments |

**Location:** `code/HousingSystem.lua`, `code/HousingOverviewPanel.lua`, `code/HousingAssignmentModal.lua`

### 19. Save/Load Migration (Phase 9)
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| Save land ownership | Implemented | Serializes LandSystem state |
| Save character economics | Implemented | Wealth, income, expenses |
| Save housing assignments | Implemented | Housing system state |
| Save relationships | Implemented | Character relationships |
| Backwards compatibility | Implemented | Migrates old saves to v0.2.0 |
| Version comparison | Implemented | Semantic version migration |

**Location:** `code/SaveManager.lua`

### 20. Building Detail Enhancements (Section 6.3)
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| Upgrade system | Implemented | Level indicator, cost display, upgrade button |
| Priority setting | Implemented | High/Normal/Low cycling button |
| Pause Production | Implemented | Toggle button with visual feedback |
| Demolish button | Implemented | With salvage value display |

**Location:** `code/AlphaUI.lua` (RenderBuildingModal)

### 21. Notifications System (Section 12)
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| Toast notifications | Implemented | Top-right corner with slide-in animations |
| Critical (red) | Implemented | Auto-pause on critical events |
| Warning (orange) | Implemented | Attention-needed alerts |
| Info (blue) | Implemented | General information |
| Success (green) | Implemented | Positive feedback |
| Action buttons | Implemented | Clickable actions per notification |
| Sound feedback | Implemented | Optional notification sounds |

**Location:** `code/NotificationSystem.lua`

### 22. Visual Indicators (Section 4.4)
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| Building status glows | Implemented | Green/yellow/red/orange based on status |
| Speech bubbles | Implemented | !, ?, || indicators on buildings |
| Citizen satisfaction circles | Implemented | Green/yellow/red outer ring |
| Emigration risk glow | Implemented | Pulsing red aura for at-risk citizens |
| Protest indicators | Implemented | X symbol for protesting citizens |
| Searching indicators | Implemented | ? symbol for job seekers |

**Location:** `code/AlphaUI.lua` (RenderBuilding, RenderCitizen)

### 23. Mini-map Enhancements (Section 4.3)
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| Clickable navigation | Implemented | Click to pan camera |
| Legend hint | Implemented | "Click to navigate" text |
| Forests shown | Implemented | Forest regions on minimap |
| Resource deposits | Implemented | Color-coded by resource type |
| Citizen satisfaction | Implemented | Green/yellow/red dots |
| Paused building indicators | Implemented | Different color for paused |

**Location:** `code/AlphaUI.lua` (RenderMiniMap, HandleMinimapClick)

### 24. Tutorial System (Section 3.3)
**Status:** IMPLEMENTED

| Feature | Implementation Status | Notes |
|---------|----------------------|-------|
| Step-by-step guidance | Implemented | 7 tutorial steps for first 30 cycles |
| Highlight system | Implemented | Pulsing highlights on UI elements |
| Welcome/Camera step | Implemented | Cycles 1-3 |
| Citizen selection step | Implemented | Cycles 4-6 |
| Satisfaction explanation | Implemented | Cycles 7-10 |
| Building tutorial | Implemented | Cycles 11-15 |
| Production tutorial | Implemented | Cycles 16-20 |
| Immigration tutorial | Implemented | Cycles 21-25 |
| Save reminder | Implemented | Cycles 26-30 |
| Skip/Next buttons | Implemented | User control over tutorial progress |
| Save/Load serialization | Implemented | Tutorial progress persists |

**Location:** `code/TutorialSystem.lua`

---

## PENDING FEATURES (TODO)

### 1. Emigration Warning Panel (Section 5.4)
**Priority:** MEDIUM
**Status:** NOT IMPLEMENTED

Required features:
- [ ] Modal showing at-risk citizens
- [ ] Each entry shows:
  - [ ] Satisfaction percentage
  - [ ] Emigration risk percentage
  - [ ] Primary reason for unhappiness
  - [ ] Suggested solution
  - [ ] "View Profile" button
  - [ ] "Prioritize Allocation" button
- [ ] Town-wide emigration factors summary
- [ ] Link to Allocation Policy panel

---

### 2. Trade System (Section 8.2)
**Priority:** LOW
**Status:** NOT IMPLEMENTED

Required features:
- [ ] **Trading Partners list**
  - [ ] Partner name with relationship status
  - [ ] Distance (travel days)
  - [ ] Their exports/imports
  - [ ] Tariff rate

- [ ] **Active Trade Routes display**
  - [ ] Route direction
  - [ ] Goods being traded
  - [ ] Value
  - [ ] Transit status

- [ ] **Trade balance summary**
- [ ] **New Trade form**
  - [ ] Partner dropdown
  - [ ] Export quantity inputs
  - [ ] Import quantity inputs
  - [ ] Net cost calculator
  - [ ] Recurring option

---

### 3. Analytics Dashboard (Section 9.1)
**Priority:** MEDIUM
**Status:** NOT IMPLEMENTED (Placeholder exists)

Required tabs:
- [ ] **Overview Tab**
  - [ ] Satisfaction distribution chart
  - [ ] Population trend graph
  - [ ] Key metrics summary

- [ ] **Satisfaction Tab**
  - [ ] 9-dimension breakdown bars
  - [ ] Distribution histogram
  - [ ] Trend lines over 100 cycles
  - [ ] Key insights text

- [ ] **Economy Tab**
  - [ ] Treasury trend graph
  - [ ] Income/expense breakdown
  - [ ] Wealth distribution by class
  - [ ] Gini coefficient

- [ ] **Demographics Tab**
  - [ ] Class distribution pie chart
  - [ ] Age distribution histogram
  - [ ] Vocation breakdown

---

### 4. Allocation Policy Panel (Section 9.2)
**Priority:** MEDIUM
**Status:** IMPLEMENTED IN PROTOTYPE - Needs porting to main game

**Current Implementation (ConsumptionPrototype):**
The allocation system has been redesigned with these key changes:
- **Class-based priority REMOVED** - Priority is now purely desperation-based (lowest satisfaction = highest priority)
- **Class advantage through consumption budgets** - Wealthier classes consume more items per cycle (Elite=10, Upper=7, Middle=5, Working=3, Poor=2)
- **No class weights for allocation order** - All citizens compete equally based on need

**Existing features in ConsumptionPrototype (`code/ConsumptionPrototype.lua`):**
- [x] Priority Mode selection (need_based, equality)
- [x] Fairness Enable toggle
- [x] Class Consumption Budgets (items per cycle per class)
- [x] Dimension Priorities (9 coarse dimensions)
- [x] Substitution Aggressiveness slider
- [x] Reserve Threshold setting
- [x] Quick Presets (Egalitarian, Class-Stratified, Rawlsian, Utilitarian)
- [x] Scrollable modal with proper UI

**To port to main game (AlphaUI):**
- [ ] Create AllocationPolicyPanel.lua module
- [ ] Integrate with AlphaWorld's allocation system
- [ ] Add keyboard shortcut (suggested: O for pOlicy)
- [ ] Sync with economic system selected at game start

---

### 5. Governance Panel (Section 9.3)
**Priority:** LOW
**Status:** PARTIALLY IMPLEMENTED - Data exists, needs UI

**Current Implementation:**
Economic systems are defined in `data/alpha/economic_systems.json` with three systems:
- **Capitalist** (Free Market) - Private ownership, market wages, full taxation
- **Collectivist** (Collective Ownership) - State ownership, state wages, no private property
- **Feudal** (Feudal Hierarchy) - Land-based hierarchy, titles, tribute system

**Existing data structures:**
- [x] Ownership rules (private allowed, land/building ownership, inheritance)
- [x] Income systems (market/state/traditional wages, profit distribution)
- [x] Taxation by class (income tax, capital gains, property tax, trade tax)
- [x] Class mobility settings
- [x] Feudal titles and obligations

**UI features still needed:**
- [ ] **Economic System Display** (read-only, set at game start)
  - [ ] Show current system name and description
  - [ ] Show ownership rules
  - [ ] Show taxation rates

- [ ] **Taxation Adjustment** (if system allows)
  - [ ] Income tax sliders by class
  - [ ] Trade tax slider
  - [ ] Property tax slider

- [ ] **Laws & Edicts toggles** (future feature)
  - [ ] Mandatory Work
  - [ ] Rationing
  - [ ] Free Education
  - [ ] Closed Borders

**Note:** Government type unlocking (Democracy, Council, etc.) is a future feature not currently in scope.

---

### 6. Information System Tabs (Section 10)
**Priority:** LOW
**Status:** PARTIALLY IMPLEMENTED - Recipes exist

Missing features:
- [ ] **Characters Reference Tab** (Section 10.3)
  - [ ] Vocations list with details
  - [ ] Traits list with effects
  - [ ] Classes explanation

- [ ] **Buildings Reference Tab**
  - [ ] All building types
  - [ ] Requirements
  - [ ] Production details

- [ ] **Mechanics Reference Tab**
  - [ ] Satisfaction system explanation
  - [ ] Allocation rules
  - [ ] Trade mechanics

---

## PRIORITY ORDER

### Phase 1 - Core Gameplay (HIGH PRIORITY) - COMPLETE
1. ~~Settings Panel~~ DONE
2. ~~Immigration System Enhancements~~ DONE
3. ~~Build Menu Improvements~~ DONE
4. ~~Character Detail Modal Enhancements~~ DONE
5. ~~Land Ownership System~~ DONE
6. ~~Housing System~~ DONE
7. ~~Save/Load Migration~~ DONE

### Phase 2 - Management (MEDIUM PRIORITY) - PARTIALLY COMPLETE
1. ~~Building Detail Enhancements~~ DONE
2. ~~Notifications System~~ DONE
3. ~~Visual Indicators~~ DONE
4. ~~Mini-map Enhancements~~ DONE
5. ~~Tutorial System~~ DONE
6. Analytics Dashboard (A key - full implementation)
7. Allocation Policy Panel (port from ConsumptionPrototype)
8. Emigration Warning Panel

### Phase 3 - Polish (LOW PRIORITY)
1. Trade System (T key)
2. Governance Panel (UI for existing economic_systems.json)
3. Information System Tabs

---

## NOTES

### Keyboard Shortcut Summary
| Key | Feature | Status |
|-----|---------|--------|
| B | Build Menu | IMPLEMENTED |
| C | Citizens Panel | IMPLEMENTED |
| I | Inventory | IMPLEMENTED |
| P | Production Analytics | IMPLEMENTED |
| S | Settings | IMPLEMENTED |
| A | Analytics | IMPLEMENTED (placeholder) |
| M | Immigration | IMPLEMENTED |
| R | Resource Overlay | IMPLEMENTED |
| L | Land Overlay | IMPLEMENTED |
| SHIFT+L | Land Registry Panel | IMPLEMENTED |
| G | Housing Overview | IMPLEMENTED |
| D | Character Details | IMPLEMENTED |
| H | Help Overlay | IMPLEMENTED |
| F5 | Quicksave | IMPLEMENTED |
| F6 | Save/Load Menu | IMPLEMENTED |
| F9 | Quickload | IMPLEMENTED |

### Allocation System Design (Updated)

The allocation system has been redesigned with these principles:

1. **Desperation-Based Priority** - Citizens with lowest satisfaction get allocated first (no class-based priority order)

2. **Class Advantage Through Consumption Budgets** - Wealthier classes can consume more items per cycle:
   - Elite: 10 items/cycle
   - Upper: 7 items/cycle
   - Middle: 5 items/cycle
   - Working: 3 items/cycle
   - Poor: 2 items/cycle

3. **No Class Weights** - The old "class_based" priority mode was removed. All citizens compete equally for allocation based on need.

4. **Fairness Mode** - Optional mode that adjusts priority based on recent consumption history

5. **Dimension Priorities** - Can adjust which of the 9 coarse satisfaction dimensions are prioritized

### Color Scheme Reference (from spec Section 14)
- Background: #1a1a2e
- Panel: #25253a
- Accent (Gold): #d4a855
- Success: #4ade80
- Warning: #fb923c
- Critical: #ef4444
- Neutral: #facc15
- Info: #60a5fa
