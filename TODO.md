# CraveTown Alpha - Implementation Status & TODO

**Document Version:** 1.0
**Last Updated:** 2025-12-07
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
| SETTINGS button | Partially | Button exists, panel not built |
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
- Quick access buttons in top bar not all implemented (Analytics, Trade, Policy missing)
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
**Status:** PARTIALLY IMPLEMENTED

| Spec Feature | Implementation Status | Notes |
|--------------|----------------------|-------|
| SPACE - Pause/Resume | Implemented | Works |
| 1/2/3 - Speed 1x/2x/5x | Implemented | 4 for 10x also works |
| B - Build menu | Implemented | Opens build modal |
| C - Citizens panel | Not Implemented | Spec feature |
| I - Inventory | Not Implemented | Spec feature |
| A - Analytics | Not Implemented | Spec feature |
| T - Trade | Not Implemented | Spec feature |
| P - Policy | Not Implemented | Spec feature |
| M - Immigration | Implemented | Opens immigration modal |
| ESC - Close panel | Implemented | Works for modals |
| F5/F9 - Save/Load | Implemented | Quicksave/load |
| H - Help overlay | Implemented | Shows keyboard shortcuts |
| WASD/Arrows - Pan | Implemented | Camera movement |
| Scroll - Zoom | Implemented | Mouse wheel zoom |

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

---

## PENDING FEATURES (TODO)

### 1. Settings Panel (Section 11.2)
**Priority:** HIGH
**Status:** NOT IMPLEMENTED

Required tabs:
- [ ] **Gameplay Tab**
  - [ ] Simulation speed options display
  - [ ] Auto-pause on events (Critical/Warning/Info checkboxes)
  - [ ] Tutorial hints toggle
  - [ ] Notification frequency dropdown
  - [ ] Autosave interval setting

- [ ] **Display Tab**
  - [ ] Resolution dropdown
  - [ ] Fullscreen toggle
  - [ ] UI Scale slider
  - [ ] Show character names option (Always/Hover/Never)
  - [ ] Show production numbers toggle
  - [ ] Color blind mode dropdown

- [ ] **Audio Tab**
  - [ ] Master volume slider
  - [ ] Music volume slider
  - [ ] SFX volume slider
  - [ ] Notification sounds toggle

- [ ] **Controls Tab** (Optional)
  - [ ] Key rebinding interface

- [ ] **Accessibility Tab**
  - [ ] Larger text option
  - [ ] High contrast mode

---

### 2. Immigration System Enhancements (Section 5.2-5.3)
**Priority:** HIGH
**Status:** PARTIALLY IMPLEMENTED - Basic immigration works, needs enhancements

Current state: Basic immigration modal with accept/reject/defer

Missing features:
- [ ] **Town Attractiveness Display**
  - [ ] Overall attractiveness score (0-100)
  - [ ] Per-class appeal breakdown with descriptions

- [ ] **Compatibility Score** per applicant
  - [ ] Visual percentage bar
  - [ ] Text explanation of compatibility

- [ ] **Applicant Card Enhancements**
  - [ ] "What they offer" section (skills, wealth, family)
  - [ ] "What they seek" section (top needs)
  - [ ] Star indicator for rare/skilled workers

- [ ] **Bulk Actions**
  - [ ] "Accept All Compatible (>70%)" button
  - [ ] "Reject All Low (<40%)" button
  - [ ] Auto-Accept toggle

- [ ] **Immigration Policies**
  - [ ] Open Borders / Selective / Restrictive / Closed options
  - [ ] Class preference sliders (who to attract more)

- [ ] **Full Profile Modal** (Section 5.3)
  - [ ] Detailed origin story
  - [ ] Family members list
  - [ ] 9-dimension need breakdown
  - [ ] Predicted satisfaction percentage
  - [ ] Emigration risk percentage

---

### 3. Emigration Warning Panel (Section 5.4)
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

### 4. Build Menu Improvements (Section 6.1)
**Priority:** MEDIUM
**Status:** PARTIALLY IMPLEMENTED - Basic build menu exists

Missing features:
- [ ] **Search bar** for buildings
- [ ] **Category tabs**: All / Housing / Production / Services / Infrastructure / Decorative
- [ ] **Grid layout** with building images (currently list-based)
- [ ] **Building cards** showing:
  - [ ] Visual image/icon
  - [ ] Capacity (for housing)
  - [ ] Class requirement (for housing)
  - [ ] Worker range (min-max)
  - [ ] Input requirements preview
- [ ] **"Show more" expansion** for each category

---

### 5. Building Detail Enhancements (Section 6.3)
**Priority:** MEDIUM
**Status:** PARTIALLY IMPLEMENTED - Basic details shown

Missing features:
- [ ] **Upgrade system**
  - [ ] Level indicator
  - [ ] Upgrade button with cost
  - [ ] Benefits preview

- [ ] **Efficiency breakdown**
  - [ ] Location fertility contribution
  - [ ] Worker skill average contribution
  - [ ] Staffing level contribution
  - [ ] Lifetime production counter

- [ ] **Priority setting** (High/Medium/Low)
- [ ] **Pause Production** toggle
- [ ] **Demolish** button with salvage value display

---

### 6. Workplace Selection System
**Priority:** MEDIUM
**Status:** DESIGN DEVIATION - Free Agency Model

**Important Note:** The spec describes a "Worker Assignment Modal" where the player assigns workers to buildings. However, CraveTown uses a **Free Agency Model** where:
- **Citizens choose their own workplace** based on their preferences, skills, and satisfaction
- **Players influence** workplace selection through building placement, job availability, and town policies
- **Citizens may change jobs** based on satisfaction, skill match, and opportunities

This is a **deliberate design choice** for more emergent gameplay.

Current implementation:
- [x] Citizens autonomously select workplaces
- [x] Skill matching affects citizen preferences
- [x] Citizens can be unemployed if no suitable work

Potential enhancements (without breaking free agency):
- [ ] **Workplace Preferences panel** in character detail
  - [ ] Show which buildings citizen prefers
  - [ ] Show skill compatibility scores
- [ ] **Job Posting system** for buildings
  - [ ] Buildings can "advertise" open positions
  - [ ] Higher wages attract better workers
- [ ] **Workplace satisfaction factors** display
  - [ ] Why citizen chose current workplace
  - [ ] What would make them switch

---

### 7. Citizens Overview Panel (Section 7.1)
**Priority:** HIGH
**Status:** NOT IMPLEMENTED (Shortcut 'C' not active)

Required features:
- [ ] **View modes**: Grid / List / Compact toggle
- [ ] **Filters**: Class / Status / Vocation / Satisfaction dropdowns
- [ ] **Sorting**: Satisfaction / Name / Class / Age / Priority
- [ ] **Search bar** for citizen names
- [ ] **Citizen cards** in grid view showing:
  - [ ] Satisfaction color indicator
  - [ ] Class label
  - [ ] Vocation
  - [ ] Status (Working/Unemployed/Protesting/Critical)
  - [ ] Possession icons
- [ ] **Pagination** (Page X of Y, Prev/Next)
- [ ] **Summary statistics bar**
  - [ ] Average satisfaction
  - [ ] Unemployment rate
  - [ ] At-risk count
- [ ] **Mass actions dropdown**
  - [ ] Export data
  - [ ] Prioritize selected

---

### 8. Character Detail Modal Enhancements (Section 7.2)
**Priority:** MEDIUM
**Status:** PARTIALLY IMPLEMENTED - Basic modal exists

Missing features:
- [ ] **49-Dimension View** toggle
  - [ ] Expand each coarse category to show fine dimensions
  - [ ] Top 10 urgent cravings list

- [ ] **Commodity Fatigue display**
  - [ ] Effectiveness percentage per commodity
  - [ ] "Tired of X" indicators
  - [ ] Variety tip message

- [ ] **Possessions section**
  - [ ] Durable goods owned with condition bars
  - [ ] Remaining cycle counters
  - [ ] Effectiveness percentages

- [ ] **Consumption History**
  - [ ] Last 20 cycles log
  - [ ] Success/failure indicators
  - [ ] Satisfaction delta per consumption

- [ ] **Economy & Wealth section**
  - [ ] Current wealth
  - [ ] Income/expenses per cycle
  - [ ] Net savings
  - [ ] Wealth rank in town

- [ ] **Status & Risks section**
  - [ ] Priority rank
  - [ ] Productivity percentage
  - [ ] Consecutive failures count
  - [ ] Emigration risk percentage
  - [ ] Protest risk percentage

---

### 9. Inventory Panel (Section 8.1)
**Priority:** HIGH
**Status:** NOT IMPLEMENTED (Shortcut 'I' not active)

Required features:
- [ ] **Category tabs**: All / Food / Materials / Goods / Luxury / Durables
- [ ] **Sorting**: Quantity / Name / Value / Demand / Trend
- [ ] **Table view** with columns:
  - [ ] Item name with icon
  - [ ] Quantity
  - [ ] Trend arrow (up/down/stable)
  - [ ] Production rate per cycle
  - [ ] Consumption rate per cycle
  - [ ] Status indicator (Surplus/Balanced/Shortage)
- [ ] **Treasury section**
  - [ ] Current gold
  - [ ] Income per cycle
  - [ ] Expenses per cycle
  - [ ] Net per cycle
- [ ] **Quick actions**
  - [ ] Import goods button
  - [ ] Export surplus button
  - [ ] Auto-trade rules
  - [ ] View trade log

---

### 10. Trade System (Section 8.2)
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

### 11. Analytics Dashboard (Section 9.1)
**Priority:** MEDIUM
**Status:** NOT IMPLEMENTED (Shortcut 'A' not active)

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

- [ ] **Production Tab**
  - [ ] Per-commodity production rates
  - [ ] Building efficiency rankings
  - [ ] Supply/demand balance

- [ ] **Demographics Tab**
  - [ ] Class distribution pie chart
  - [ ] Age distribution histogram
  - [ ] Vocation breakdown

---

### 12. Allocation Policy Panel (Section 9.2)
**Priority:** MEDIUM
**Status:** NOT IMPLEMENTED (Shortcut 'P' not active)

Required features:
- [ ] **Economic Model selection**
  - [ ] Communist Allocation
  - [ ] Mixed Economy
  - [ ] Market Economy

- [ ] **Priority Mode selection** (Communist/Mixed only)
  - [ ] Need-Based
  - [ ] Balanced
  - [ ] Egalitarian

- [ ] **Class Weights sliders**
  - [ ] Elite/Upper/Middle/Lower/Poor multipliers

- [ ] **Fairness Settings**
  - [ ] History penalty slider
  - [ ] Critical threshold input

- [ ] **Budget per class** inputs
- [ ] **Quick Presets** buttons
- [ ] **Preview** showing top 10 priority characters

---

### 13. Governance Panel (Section 9.3)
**Priority:** LOW
**Status:** NOT IMPLEMENTED

Required features:
- [ ] **Government Type display** (initially locked)
  - [ ] Benevolent Dictatorship (starting)
  - [ ] Council Rule / Merchant Guild / Theocracy / Democracy (unlockable)

- [ ] **Taxation sliders**
  - [ ] Income tax with effect preview
  - [ ] Trade tax with effect preview
  - [ ] Luxury tax with effect preview

- [ ] **Laws & Edicts toggles**
  - [ ] Mandatory Work
  - [ ] Rationing
  - [ ] Free Education
  - [ ] Closed Borders
  - [ ] Effect descriptions for each

---

### 14. Notifications System (Section 12)
**Priority:** MEDIUM
**Status:** PARTIALLY IMPLEMENTED - Event log exists, no toast notifications

Missing features:
- [ ] **Toast notifications** in corner
  - [ ] Critical (red) with auto-pause
  - [ ] Warning (orange)
  - [ ] Info (green)
  - [ ] Success (checkmark)

- [ ] **Auto-pause on critical events** option
- [ ] **Notification toast format**
  - [ ] Icon + title
  - [ ] Brief description
  - [ ] Action buttons

- [ ] **Event History Modal**
  - [ ] Filterable by type
  - [ ] Range selector (last X cycles)
  - [ ] Export to file
  - [ ] Clear old events

---

### 15. Visual Indicators (Section 4.4)
**Priority:** LOW
**Status:** NOT IMPLEMENTED

Missing features:
- [ ] **Building status glows**
  - [ ] Green = Producing efficiently
  - [ ] Yellow = Understaffed or shortage
  - [ ] Red = Stopped/blocked

- [ ] **Speech bubbles** on buildings for events
- [ ] **Citizen satisfaction circles**
  - [ ] Green (>70%)
  - [ ] Yellow (40-70%)
  - [ ] Red (<40%)

- [ ] **Protest/Searching indicators** (! and ? icons)

---

### 16. Mini-map Enhancements (Section 4.3)
**Priority:** LOW
**Status:** PARTIALLY IMPLEMENTED - Basic mini-map with river

Missing features:
- [ ] **Clickable navigation** - Click to pan camera
- [ ] **Legend** showing icon meanings
- [ ] **Forests shown** (currently only river)
- [ ] **Resource deposit indicators**

---

### 17. Information System Tabs (Section 10)
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

### 18. Tutorial System (Section 3.3)
**Priority:** LOW
**Status:** NOT IMPLEMENTED

Required features:
- [ ] **Step-by-step guidance** for first 30 cycles
- [ ] **Highlight system** for UI elements
- [ ] **Tutorial steps**:
  - [ ] Cycles 1-3: Welcome, camera pan
  - [ ] Cycles 4-6: Click a citizen
  - [ ] Cycles 7-10: Satisfaction bars explanation
  - [ ] Cycles 11-15: Build a farm
  - [ ] Cycles 16-20: Assign workers
  - [ ] Cycles 21-25: Watch production
  - [ ] Cycles 26-30: Handle immigration

---

## PRIORITY ORDER

### Phase 1 - Core Gameplay (HIGH PRIORITY)
1. Settings Panel
2. Citizens Overview Panel (C key)
3. Inventory Panel (I key)
4. Immigration System Enhancements

### Phase 2 - Management (MEDIUM PRIORITY)
5. Analytics Dashboard (A key)
6. Allocation Policy Panel (P key)
7. Emigration Warning Panel
8. Build Menu Improvements
9. Building Detail Enhancements
10. Worker Assignment Modal
11. Character Detail Modal Enhancements
12. Notifications System

### Phase 3 - Polish (LOW PRIORITY)
13. Trade System (T key)
14. Governance Panel
15. Visual Indicators
16. Mini-map Enhancements
17. Information System Tabs
18. Tutorial System

---

## NOTES

### Keyboard Shortcut Summary
| Key | Feature | Status |
|-----|---------|--------|
| B | Build Menu | IMPLEMENTED |
| C | Citizens Panel | NOT IMPLEMENTED |
| I | Inventory | NOT IMPLEMENTED |
| A | Analytics | NOT IMPLEMENTED |
| T | Trade | NOT IMPLEMENTED |
| P | Policy | NOT IMPLEMENTED |
| M | Immigration | IMPLEMENTED |

### Color Scheme Reference (from spec Section 14)
- Background: #1a1a2e
- Panel: #25253a
- Accent (Gold): #d4a855
- Success: #4ade80
- Warning: #fb923c
- Critical: #ef4444
- Neutral: #facc15
- Info: #60a5fa
