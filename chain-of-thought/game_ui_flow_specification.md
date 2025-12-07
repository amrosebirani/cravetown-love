# CraveTown - Complete Game UI Flow Specification

**Created:** 2025-12-03
**Status:** Design Document
**Version:** 1.0

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Game Overview & Core Loop](#2-game-overview--core-loop)
3. [First-Time User Experience (FTUE)](#3-first-time-user-experience-ftue)
4. [Main Game Screen - World View](#4-main-game-screen---world-view)
5. [Immigration System](#5-immigration-system)
6. [Building & Construction System](#6-building--construction-system)
7. [Character Management](#7-character-management)
8. [Economy & Trade](#8-economy--trade)
9. [Town Management](#9-town-management)
10. [Information System](#10-information-system)
11. [Save/Load & Settings](#11-saveload--settings)
12. [Notifications & Events](#12-notifications--events)
13. [Keyboard Shortcuts & Accessibility](#13-keyboard-shortcuts--accessibility)
14. [Visual Design Language](#14-visual-design-language)
15. [Missing Features & Recommendations](#15-missing-features--recommendations)
16. [Screen Flow Diagrams](#16-screen-flow-diagrams)

---

## 1. Executive Summary

CraveTown is a town-building simulation where players manage a settlement by satisfying the complex needs of its inhabitants. The game features:

- **49-dimensional craving system** (displayed as 9 coarse categories)
- **5 social classes** with different priorities and behaviors
- **Durable goods** that provide ongoing satisfaction
- **Immigration/Emigration** based on town attractiveness
- **Production chains** with building placement and worker assignment
- **Multiple economic models** (communist allocation → market economy)

This document defines the complete UI flow for transforming the current prototype into a polished, playable game.

---

## 2. Game Overview & Core Loop

### 2.1 Core Gameplay Loop

```
┌─────────────────────────────────────────────────────────────────┐
│                      CORE GAME LOOP                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. OBSERVE          2. PLAN              3. ACT               │
│  ┌─────────┐        ┌─────────┐         ┌─────────┐            │
│  │ View    │  ───►  │ Decide  │  ───►   │ Build   │            │
│  │ Town    │        │ What to │         │ Assign  │            │
│  │ Status  │        │ Improve │         │ Accept  │            │
│  └─────────┘        └─────────┘         └─────────┘            │
│       ▲                                      │                  │
│       │                                      │                  │
│       │         4. SIMULATE                  │                  │
│       │        ┌─────────────┐               │                  │
│       └────────│ Time Passes │◄──────────────┘                  │
│                │ Needs Grow  │                                  │
│                │ Production  │                                  │
│                │ Allocation  │                                  │
│                └─────────────┘                                  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Player Goals

| Short-term Goals | Medium-term Goals | Long-term Goals |
|-----------------|-------------------|-----------------|
| Keep citizens fed | Grow population | Build prosperous civilization |
| Prevent emigration | Establish production chains | Achieve governance goals |
| Build basic housing | Attract skilled immigrants | Trade with other towns |
| Assign workers | Balance class satisfaction | Cultural/technological advancement |

### 2.3 Time Scale

- **1 Cycle** = 1 game day (adjustable 1x to 10x speed)
- **Early game**: ~50 cycles to establish basics
- **Mid game**: ~200 cycles to reach stability
- **Late game**: 500+ cycles for advanced goals

---

## 3. First-Time User Experience (FTUE)

### 3.1 Title Screen

```
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║                         CRAVETOWN                                ║
║                    "Build a Town That Satisfies"                 ║
║                                                                  ║
║                    [  NEW GAME  ]                                ║
║                    [ CONTINUE   ]                                ║
║                    [  LOAD GAME ]                                ║
║                    [  SETTINGS  ]                                ║
║                    [   CREDITS  ]                                ║
║                    [    QUIT    ]                                ║
║                                                                  ║
║                         v0.1.0                                   ║
╚══════════════════════════════════════════════════════════════════╝
```

### 3.2 New Game Setup Flow

```
STEP 1: TOWN NAME & LOCATION
╔════════════════════════════════════════════════════════════════╗
║  CREATE YOUR TOWN                                              ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  Town Name: [________________________]                         ║
║                                                                ║
║  Starting Location:                                            ║
║  ┌────────────────────────────────────────────────────┐        ║
║  │  [MAP PREVIEW - Shows terrain, resources]          │        ║
║  │                                                    │        ║
║  │     🌊 River Valley    🏔️ Mountain Pass            │        ║
║  │     🌾 Fertile Plains  🌲 Forest Edge              │        ║
║  │     🏜️ Desert Oasis    ⛏️ Mining Hills             │        ║
║  │                                                    │        ║
║  │  Selected: Fertile Plains                          │        ║
║  │  Bonuses: +20% farm output, +water access          │        ║
║  │  Challenges: -10% ore availability                 │        ║
║  └────────────────────────────────────────────────────┘        ║
║                                                                ║
║                          [ NEXT → ]                            ║
╚════════════════════════════════════════════════════════════════╝

STEP 2: STARTING CONDITIONS
╔════════════════════════════════════════════════════════════════╗
║  STARTING CONDITIONS                                           ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  Difficulty:                                                   ║
║  ○ Story Mode    - Generous resources, slow craving growth    ║
║  ● Normal        - Balanced challenge                          ║
║  ○ Challenging   - Scarce resources, faster craving growth    ║
║  ○ Survival      - Minimal starting resources                  ║
║                                                                ║
║  Starting Population: [15] (5-30)                              ║
║                                                                ║
║  Class Distribution:                                           ║
║  ○ Balanced      - Mix of all classes                          ║
║  ● Working Class - Mostly workers, few elite                   ║
║  ○ Established   - More upper/middle class                     ║
║  ○ Custom        - Set exact percentages                       ║
║                                                                ║
║  Economic System:                                              ║
║  ● Communist     - Central allocation (recommended for start)  ║
║  ○ Mixed Economy - Basic needs allocated, luxury = market      ║
║  ○ Free Market   - Everything price-based (advanced)           ║
║                                                                ║
║              [ ← BACK ]              [ NEXT → ]                ║
╚════════════════════════════════════════════════════════════════╝

STEP 3: TUTORIAL PREFERENCE
╔════════════════════════════════════════════════════════════════╗
║  TUTORIAL                                                      ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  Would you like guidance as you play?                          ║
║                                                                ║
║  ● Full Tutorial                                               ║
║    Step-by-step guidance through first 50 cycles               ║
║                                                                ║
║  ○ Tips Only                                                   ║
║    Occasional hints when things go wrong                       ║
║                                                                ║
║  ○ No Tutorial                                                 ║
║    Jump straight into the game                                 ║
║                                                                ║
║              [ ← BACK ]           [ START GAME ]               ║
╚════════════════════════════════════════════════════════════════╝
```

### 3.3 Tutorial Sequence

The tutorial unfolds across the first ~30 cycles:

| Cycle | Tutorial Step | UI Highlight | Player Action |
|-------|--------------|--------------|---------------|
| 1-3 | "Welcome to your town!" | World view | Pan camera |
| 4-6 | "These are your citizens" | Character panel | Click a citizen |
| 7-10 | "Their needs are shown here" | Satisfaction bars | Hover over bars |
| 11-15 | "Build a farm to produce food" | Build menu | Place farm |
| 16-20 | "Assign workers to the farm" | Worker assignment | Assign 2 workers |
| 21-25 | "Watch production begin" | Production indicator | Wait for output |
| 26-30 | "New immigrants want to join!" | Immigration panel | Accept/reject |

---

## 4. Main Game Screen - World View

### 4.1 Overall Layout

```
╔══════════════════════════════════════════════════════════════════════════╗
║ TOP BAR - Status & Quick Actions                                         ║
╠══════════════════════════════════════════════════════════════════════════╣
║  ┌──────────────────────────────────────────────────────────────────┐   ║
║  │ LEFT PANEL    │        CENTER - WORLD VIEW          │ RIGHT PANEL│   ║
║  │               │                                     │            │   ║
║  │ Quick Stats   │   [Isometric/Top-down game world]   │ Selected   │   ║
║  │ Mini-map      │                                     │ Entity     │   ║
║  │ Build Menu    │   Buildings, Characters moving,     │ Details    │   ║
║  │ Immigration   │   Resources, Production             │            │   ║
║  │               │                                     │ Actions    │   ║
║  └──────────────────────────────────────────────────────────────────┘   ║
╠══════════════════════════════════════════════════════════════════════════╣
║ BOTTOM BAR - Event Log & Alerts                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
```

### 4.2 Top Bar (Always Visible)

```
┌────────────────────────────────────────────────────────────────────────────┐
│ 🏠 Prosperityville    │ Pop: 87/100  │ 💰 2,450  │ Cycle: 2847  │ ⏸️ 1x 2x 5x │
│ Est. Cycle 1          │ +2 this cyc  │ +125/cyc  │ Day 47       │ ▶️ ⏩ ⏭️    │
├────────────────────────────────────────────────────────────────────────────┤
│ [📊 Analytics] [🔨 Build] [👥 Citizens] [📦 Inventory] [⚙️ Settings] [❓ Help] │
└────────────────────────────────────────────────────────────────────────────┘

Components:
- Town name & founding cycle
- Population (current / housing capacity)
- Treasury (total gold + income per cycle)
- Current cycle & day
- Time controls (pause, play, speed 1x/2x/5x/10x)
- Quick access buttons for major panels
```

### 4.3 Left Panel - Quick Access

```
┌─ QUICK STATS ────────────────┐
│ Overall Happiness: 58% 🟡    │
│ ▓▓▓▓▓▓░░░░                   │
│                              │
│ By Class:                    │
│ Elite:  ▓▓▓▓▓▓▓░░░ 72%      │
│ Upper:  ▓▓▓▓▓▓░░░░ 68%      │
│ Middle: ▓▓▓▓▓░░░░░ 54%      │
│ Lower:  ▓▓▓░░░░░░░ 38% ⚠️   │
├──────────────────────────────┤
│ ALERTS                       │
│ ⚠️ Bread shortage            │
│ 🔴 5 citizens critical       │
│ 📢 3 immigrants waiting      │
├──────────────────────────────┤
│ MINI-MAP                     │
│ ┌──────────────────────────┐ │
│ │  [Zoomed out view]       │ │
│ │  · = citizen             │ │
│ │  ▪ = building            │ │
│ │  ~ = water               │ │
│ │  [Viewport rectangle]    │ │
│ └──────────────────────────┘ │
├──────────────────────────────┤
│ QUICK BUILD                  │
│ [🏠 House] [🌾 Farm]         │
│ [⚒️ Workshop] [🏪 Market]    │
│ [More Buildings...]          │
└──────────────────────────────┘
```

### 4.4 Center - World View

The world is displayed in **isometric view** (or optionally top-down):

```
World View Features:
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│           ⛰️                 🌲🌲🌲                                  │
│                                                                     │
│              🏠   🏠              🌾🌾🌾                              │
│           🏠   🏛️   🏠         👨‍🌾  🌾                               │
│              🏠   🏠          🌾🌾🌾🌾                               │
│                  👫 👨‍👩‍👧                                             │
│                     ⚒️                                              │
│                   👷‍♂️👷‍♀️                                             │
│           💧💧💧💧💧💧💧💧💧💧💧💧                                     │
│                                                                     │
│                              🏪                                     │
│                            👥👥👥                                    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

Legend:
🏠 = Residence          🏛️ = Town Hall           🌾 = Farm
⚒️ = Workshop           🏪 = Market              💧 = Water
🌲 = Forest             ⛰️ = Mountain            👫 = Citizens (moving)
👷 = Worker at building  👨‍🌾 = Farmer working
```

**Interaction:**
- **Left-click** on building = Select, show details in right panel
- **Left-click** on citizen = Select, show character card
- **Right-click** = Context menu (options based on selection)
- **Scroll** = Zoom in/out
- **WASD/Arrow keys** = Pan camera
- **Middle-click drag** = Pan camera

**Visual Indicators on Buildings:**
- **Green glow** = Producing efficiently
- **Yellow glow** = Understaffed or resource shortage
- **Red glow** = Stopped/blocked
- **Speech bubble** = Event (citizen complaint, production complete)

**Visual Indicators on Citizens:**
- **Green circle** = Happy (satisfaction > 70%)
- **Yellow circle** = Neutral (40-70%)
- **Red circle** = Unhappy (< 40%)
- **!** = Protesting
- **?** = Looking for something (unmet need)

### 4.5 Right Panel - Selection Details

Changes based on what's selected:

**When Building Selected:**
```
┌─ SELECTED: Wheat Farm ────────┐
│ Status: 🟢 Active             │
│                               │
│ PRODUCTION                    │
│ Output: Wheat                 │
│ Rate: 15 units/cycle          │
│ Efficiency: 85%               │
│                               │
│ WORKERS (2/4)                 │
│ ┌─────────────────────────┐   │
│ │ 👨‍🌾 John (Farmer)        │   │
│ │    Skill: 75%           │   │
│ │ 👩‍🌾 Sarah (Farmer)       │   │
│ │    Skill: 82%           │   │
│ │ [+ Assign Worker]       │   │
│ └─────────────────────────┘   │
│                               │
│ REQUIRES                      │
│ Water: ✅ Available           │
│ Fertility: ✅ 80%             │
│                               │
│ ACTIONS                       │
│ [Upgrade] [Demolish] [Info]   │
└───────────────────────────────┘
```

**When Citizen Selected:**
```
┌─ SELECTED: Alice Smith ───────┐
│ Class: Middle | Age: 35       │
│ Vocation: Baker               │
│                               │
│ SATISFACTION: 65% 🟡          │
│ ▓▓▓▓▓▓░░░░                    │
│                               │
│ TOP NEEDS                     │
│ 🔥 Entertainment: 78          │
│ ⚡ Nutrition: 65              │
│ ⚡ Social: 52                 │
│                               │
│ CURRENT ACTIVITY              │
│ 🏠 At home, resting           │
│                               │
│ POSSESSIONS                   │
│ 🏠 House | 🛏️ Bed             │
│                               │
│ ACTIONS                       │
│ [View Details] [Assign Work]  │
│ [View History]                │
└───────────────────────────────┘
```

### 4.6 Bottom Bar - Event Log & Alerts

```
┌─ EVENT LOG ─────────────────────────────────────────────────────────────────┐
│ [Cycle 2847] 📦 Wheat Farm produced 15 wheat                               │
│ [Cycle 2847] ✓ Alice received bread (satisfaction +5)                      │
│ [Cycle 2847] 🚶 3 new immigrants arrived (accepted from queue)              │
│ [Cycle 2846] ⚠️ Bob's satisfaction critical - emigration risk!             │
│ [Cycle 2846] 🔴 Carol left town (emigrated to Riverside)                   │
│ [Filter: All ▼] [Clear] [Export Log]                    [Scroll ▲▼]        │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Immigration System

### 5.1 Overview

Immigration is how players grow their town. Potential immigrants appear based on:
- **Town reputation** (average satisfaction, wealth)
- **Available housing** (must have vacant homes)
- **Economic opportunity** (jobs available)
- **Class attractiveness** (how well each class is doing)

### 5.2 Immigration Queue Panel

Accessed via: Left panel "Immigration" button or alert notification

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ IMMIGRATION - Manage Who Joins Your Town                                  ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ TOWN ATTRACTIVENESS                                                       ║
║ Overall: ████████░░ 78/100 (Good - Moderate immigration)                  ║
║                                                                           ║
║ By Class Appeal:                                                          ║
║ Elite:   ██████░░░░ 62/100  "Decent luxury goods, but limited prestige"   ║
║ Upper:   ████████░░ 78/100  "Good opportunities for advancement"          ║
║ Middle:  █████████░ 85/100  "Strong worker protections"                   ║
║ Lower:   ███████░░░ 72/100  "Basic needs met, limited upward mobility"    ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ WAITING TO JOIN (7 applicants)                     Housing Available: 13   ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ ┌─ APPLICANT 1 ─────────────────────────────────────────────────────────┐ ║
║ │ 👨 Marcus Chen | Age: 28 | Class: Middle                              │ ║
║ │ Vocation: Blacksmith ⭐ (Skilled - rare!)                             │ ║
║ │ Traits: [Hardworking] [Ambitious]                                     │ ║
║ │                                                                       │ ║
║ │ PRIMARY NEEDS (What they seek):                                       │ ║
║ │ 🔥 Safety & Shelter (HIGH) - Wants stable housing                     │ ║
║ │ ⚡ Achievement (MEDIUM) - Wants career growth                         │ ║
║ │ ⚡ Social Connection (MEDIUM) - Has family, needs community           │ ║
║ │                                                                       │ ║
║ │ WHAT THEY OFFER:                                                      │ ║
║ │ • Blacksmithing skill (can work forge at 85% efficiency)              │ ║
║ │ • Brings family (+2 dependents, wife + child)                         │ ║
║ │ • Starting wealth: 250 gold                                           │ ║
║ │                                                                       │ ║
║ │ COMPATIBILITY: ████████░░ 82%                                         │ ║
║ │ "Your town can meet most of his needs. Good fit!"                     │ ║
║ │                                                                       │ ║
║ │ [✓ ACCEPT] [✗ REJECT] [⏳ DEFER] [View Full Profile]                   │ ║
║ └───────────────────────────────────────────────────────────────────────┘ ║
║                                                                           ║
║ ┌─ APPLICANT 2 ─────────────────────────────────────────────────────────┐ ║
║ │ 👩 Elena Vasquez | Age: 45 | Class: Upper                             │ ║
║ │ Vocation: Merchant                                                    │ ║
║ │ Traits: [Wealthy] [Demanding] [Experienced Trader]                    │ ║
║ │                                                                       │ ║
║ │ PRIMARY NEEDS:                                                        │ ║
║ │ 🔥 Luxury Goods (HIGH) - Expects fine wine, spices, art               │ ║
║ │ 🔥 Status Display (HIGH) - Wants prestigious home                     │ ║
║ │ ⚡ Entertainment (MEDIUM) - Cultural activities                       │ ║
║ │                                                                       │ ║
║ │ WHAT THEY OFFER:                                                      │ ║
║ │ • Trade connections (+15% import efficiency)                          │ ║
║ │ • Starting wealth: 2,500 gold                                         │ ║
║ │ • No dependents                                                       │ ║
║ │                                                                       │ ║
║ │ COMPATIBILITY: ████░░░░░░ 45% ⚠️                                      │ ║
║ │ "Your town lacks luxury goods she expects. May emigrate quickly."     │ ║
║ │                                                                       │ ║
║ │ [✓ ACCEPT] [✗ REJECT] [⏳ DEFER] [View Full Profile]                   │ ║
║ └───────────────────────────────────────────────────────────────────────┘ ║
║                                                                           ║
║ [Show 5 more applicants...]                                               ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ BULK ACTIONS                                                              ║
║ [Accept All Compatible (>70%)] [Reject All Low (<40%)] [Auto-Accept: OFF] ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ IMMIGRATION POLICY                                                        ║
║ ○ Open Borders - Accept everyone automatically                            ║
║ ● Selective - Manual review (current)                                     ║
║ ○ Restrictive - Only accept if compatibility > 80%                        ║
║ ○ Closed - No new immigrants                                              ║
║                                                                           ║
║ Class Preferences (who to attract more):                                  ║
║ [Elite: Low ▼] [Upper: Medium ▼] [Middle: High ▼] [Lower: Medium ▼]       ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

### 5.3 Applicant Full Profile

Clicking "View Full Profile" opens detailed modal:

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ APPLICANT PROFILE: Marcus Chen                                            ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ BASIC INFO                                                                ║
║ Name: Marcus Chen          Age: 28        Gender: Male                    ║
║ Class: Middle              Vocation: Blacksmith                           ║
║ Origin: Ironhaven (mining town, 3 days travel)                            ║
║                                                                           ║
║ TRAITS                                                                    ║
║ [Hardworking] - +15% productivity, +10% fatigue resistance                ║
║ [Ambitious] - +20% career growth, -10% contentment with current status    ║
║ [Family Oriented] - +25% social connection needs, +family brings others   ║
║                                                                           ║
║ FAMILY (Accompanying)                                                     ║
║ 👩 Li Chen (Wife) - Age 26, Homemaker, Traits: [Nurturing]                ║
║ 👶 Wei Chen (Son) - Age 4, Child (non-working)                            ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ DETAILED NEEDS ANALYSIS (What they crave most)                            ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ COARSE NEEDS (9 categories):                                              ║
║ Biological:      ████████░░ 80 - Standard food/water needs                ║
║ Safety:          ██████████ 95 - HIGH! Left Ironhaven due to unrest       ║
║ Touch:           ██████░░░░ 62 - Moderate comfort needs                   ║
║ Psychological:   █████████░ 88 - Values achievement, education            ║
║ Social Status:   ███████░░░ 72 - Wants to rise, not stay same class       ║
║ Social Connect:  █████████░ 90 - Family-focused, needs community          ║
║ Exotic Goods:    ███░░░░░░░ 35 - Low interest in luxuries                 ║
║ Shiny Objects:   ██░░░░░░░░ 25 - Practical, not materialistic             ║
║ Vice:            █░░░░░░░░░ 12 - Minimal vices                            ║
║                                                                           ║
║ TOP FINE DIMENSIONS (expanded):                                           ║
║ 1. safety_shelter_housing: 95                                             ║
║ 2. social_connection_family: 92                                           ║
║ 3. psychological_achievement: 88                                          ║
║ 4. social_connection_community: 85                                        ║
║ 5. biological_nutrition_protein: 78                                       ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ YOUR TOWN'S ABILITY TO SATISFY                                            ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ ✅ Housing: Available (3 vacant homes)                                    ║
║ ✅ Safety: Good (town happiness 72%, no recent unrest)                    ║
║ ✅ Work: Forge available, needs blacksmith!                               ║
║ ⚠️ Achievement: Limited career paths for blacksmiths                      ║
║ ✅ Community: Active town square, festivals scheduled                     ║
║ ✅ Food: Adequate protein production (meat, fish)                         ║
║                                                                           ║
║ PREDICTED SATISFACTION: 78% (Above average for Middle class)              ║
║ EMIGRATION RISK: 12% (Low - good fit)                                     ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ WHY THEY WANT TO LEAVE CURRENT LOCATION                                   ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ "Ironhaven has become dangerous. Mine collapses, rising crime, and the    ║
║  lord's taxes have doubled. I need somewhere safe to raise my family      ║
║  where I can practice my craft in peace."                                 ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║   [✓ ACCEPT (Assign Housing)] [✗ REJECT] [⏳ DEFER (Ask Again Later)]     ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

### 5.4 Emigration Warning Panel

When citizens are at risk of leaving:

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ ⚠️ EMIGRATION WARNING - Citizens Consider Leaving                         ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ 5 citizens are unhappy enough to consider emigration:                     ║
║                                                                           ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ 🔴 Bob Miller | Satisfaction: 18% | Risk: 85%                       │   ║
║ │    Reason: "Starving! No bread allocation for 5 cycles"             │   ║
║ │    Solution: Increase bread production or imports                   │   ║
║ │    [View Profile] [Prioritize Allocation]                           │   ║
║ ├─────────────────────────────────────────────────────────────────────┤   ║
║ │ 🟠 Carol Davis | Satisfaction: 32% | Risk: 45%                      │   ║
║ │    Reason: "No entertainment, bored and unfulfilled"                │   ║
║ │    Solution: Build tavern or theater                                │   ║
║ │    [View Profile] [Prioritize Allocation]                           │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ TOWN-WIDE EMIGRATION FACTORS:                                             ║
║ • Lower class satisfaction is 38% (target: 50%+)                          ║
║ • Bread shortage for 3 cycles                                             ║
║ • No entertainment buildings                                              ║
║                                                                           ║
║ [Dismiss] [View All At-Risk Citizens] [Open Allocation Policy]            ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## 6. Building & Construction System

### 6.1 Build Menu

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ BUILD MENU                                               [Search: ____]   ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ CATEGORIES:                                                               ║
║ [All] [Housing] [Production] [Services] [Infrastructure] [Decorative]     ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ HOUSING                                                                   ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐       ║
║ │   [Image]    │ │   [Image]    │ │   [Image]    │ │   [Image]    │       ║
║ │    Hovel     │ │  Cottage     │ │   House      │ │   Manor      │       ║
║ │  Capacity: 2 │ │ Capacity: 4  │ │ Capacity: 6  │ │ Capacity: 8  │       ║
║ │  Class: Poor │ │ Class: Lower │ │ Class: Middle│ │ Class: Upper │       ║
║ │  💰 50       │ │  💰 150      │ │  💰 400      │ │  💰 1200     │       ║
║ │  [BUILD]     │ │  [BUILD]     │ │  [BUILD]     │ │  [BUILD]     │       ║
║ └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘       ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ PRODUCTION - Food                                                         ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐       ║
║ │   [Image]    │ │   [Image]    │ │   [Image]    │ │   [Image]    │       ║
║ │  Wheat Farm  │ │   Bakery     │ │  Cattle Farm │ │  Butcher     │       ║
║ │ Output:Wheat │ │ Output:Bread │ │ Output:Cattle│ │ Output:Meat  │       ║
║ │ Workers: 2-4 │ │ Workers: 1-2 │ │ Workers: 2-4 │ │ Workers: 1-2 │       ║
║ │  💰 200      │ │  💰 300      │ │  💰 350      │ │  💰 250      │       ║
║ │ Needs:Water  │ │ Needs:Wheat  │ │ Needs:Grass  │ │ Needs:Cattle │       ║
║ │  [BUILD]     │ │  [BUILD]     │ │  [BUILD]     │ │  [BUILD]     │       ║
║ └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘       ║
║                                                                           ║
║ [Show more Production buildings...]                                       ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ SERVICES                                                                  ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐       ║
║ │   [Image]    │ │   [Image]    │ │   [Image]    │ │   [Image]    │       ║
║ │   Tavern     │ │   Market     │ │   Temple     │ │   School     │       ║
║ │ Entertainment│ │    Trade     │ │ Spirituality │ │  Education   │       ║
║ │ Workers: 1-3 │ │ Workers: 2-4 │ │ Workers: 1-2 │ │ Workers: 1-3 │       ║
║ │  💰 400      │ │  💰 600      │ │  💰 500      │ │  💰 800      │       ║
║ │  [BUILD]     │ │  [BUILD]     │ │  [BUILD]     │ │  [BUILD]     │       ║
║ └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘       ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

### 6.2 Building Placement Mode

When player clicks BUILD:

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PLACEMENT MODE                              │
│                                                                     │
│   Building: Wheat Farm                                              │
│   Size: 3x3 tiles                                                   │
│                                                                     │
│   [World view with ghost building following cursor]                 │
│                                                                     │
│   ┌─────────────────────────────────────────────────────────┐       │
│   │                                                         │       │
│   │         [Green overlay = valid placement]               │       │
│   │         [Red overlay = invalid placement]               │       │
│   │                                                         │       │
│   │              ┌─────┐                                    │       │
│   │              │ 🌾  │ ← Ghost building                   │       │
│   │              │     │                                    │       │
│   │              └─────┘                                    │       │
│   │                                                         │       │
│   └─────────────────────────────────────────────────────────┘       │
│                                                                     │
│   PLACEMENT REQUIREMENTS:                                           │
│   ✅ Flat terrain                                                   │
│   ✅ No obstructions                                                │
│   ✅ Water source nearby (within 5 tiles)                           │
│   ⚠️ Fertility: 65% (affects output)                                │
│                                                                     │
│   EFFICIENCY AT THIS LOCATION: 78%                                  │
│   (Move closer to water for better efficiency)                      │
│                                                                     │
│   [Left-Click to Place] [Right-Click to Cancel] [R to Rotate]       │
└─────────────────────────────────────────────────────────────────────┘
```

### 6.3 Building Detail Panel

When a building is selected:

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ BUILDING: Wheat Farm (Level 1)                              [Upgrade ⬆️]   ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ STATUS: 🟢 Producing                                                      ║
║                                                                           ║
║ PRODUCTION                                                                ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ Output: Wheat                                                       │   ║
║ │ Base Rate: 20 units/cycle                                           │   ║
║ │ Current Rate: 17 units/cycle (85% efficiency)                       │   ║
║ │                                                                     │   ║
║ │ Efficiency Breakdown:                                               │   ║
║ │ • Location fertility: 80% (+0%)                                     │   ║
║ │ • Worker skill avg: 75% (-5%)                                       │   ║
║ │ • Understaffed (2/4): -10%                                          │   ║
║ │                                                                     │   ║
║ │ Lifetime Production: 1,247 wheat                                    │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ WORKERS (2/4)                                                             ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ 👨‍🌾 John Smith (Farmer) - Skill: 75% - Productivity: 92%            │   ║
║ │    Status: Working | Satisfaction: 68%                              │   ║
║ │    [View] [Unassign]                                                │   ║
║ │                                                                     │   ║
║ │ 👩‍🌾 Mary Jones (Laborer) - Skill: 45% - Productivity: 78%           │   ║
║ │    Status: Working | Satisfaction: 54%                              │   ║
║ │    [View] [Unassign]                                                │   ║
║ │                                                                     │   ║
║ │ [+ Assign Worker] (2 slots available)                               │   ║
║ │    Best candidates: Tom (Farmer, 82%), Sarah (Farmer, 79%)          │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ RESOURCE REQUIREMENTS                                                     ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ Water: ✅ Connected (river 3 tiles away)                            │   ║
║ │ Fertility: 80% (Good)                                               │   ║
║ │ Sunlight: 100%                                                      │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ ACTIONS                                                                   ║
║ [Upgrade to Level 2 (💰 500)] [Set Priority] [Pause Production]           ║
║ [View Recipe] [Demolish (💰 +50 salvage)]                                 ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

### 6.4 Worker Assignment Modal

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ ASSIGN WORKERS TO: Wheat Farm                                             ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ Current Workers: 2/4      Production Impact: +25% per additional worker   ║
║                                                                           ║
║ AVAILABLE WORKERS (sorted by skill match)                                 ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ ⭐ RECOMMENDED                                                            ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ ☑️ Tom Brown | Vocation: Farmer | Skill: 82%                         │   ║
║ │    Currently: Unemployed | Satisfaction: 45% (wants work!)          │   ║
║ │    Impact: +22% production                                          │   ║
║ ├─────────────────────────────────────────────────────────────────────┤   ║
║ │ ☐ Sarah Green | Vocation: Farmer | Skill: 79%                       │   ║
║ │    Currently: Cattle Farm (understaffed there)                      │   ║
║ │    Impact: +20% production | ⚠️ Will leave Cattle Farm short        │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ OTHER WORKERS (lower skill match)                                         ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ ☐ Mike Wilson | Vocation: Laborer | Skill: 35%                      │   ║
║ │    Currently: Unemployed | Impact: +9% production                   │   ║
║ │ ☐ Lisa Anderson | Vocation: Baker | Skill: 25%                      │   ║
║ │    Currently: Bakery (fully staffed) | Impact: +6% production       │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ Selected: Tom Brown (+22%)                                                ║
║ New Production Rate: 17 → 21 units/cycle                                  ║
║                                                                           ║
║                    [ASSIGN SELECTED] [CANCEL]                             ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## 7. Character Management

### 7.1 Citizens Overview Panel

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ CITIZENS (87 total)                                    [Search: ____]     ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ FILTER: [All ▼] [Class ▼] [Status ▼] [Vocation ▼] [Satisfaction ▼]       ║
║ SORT:   [Satisfaction ▼] [Name] [Class] [Age] [Priority]                  ║
║ VIEW:   [Grid] [List] [Compact]                                           ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐              ║
║ │ 🔴 Bob     │ │ 🟠 Carol   │ │ 🟡 David   │ │ 🟢 Alice   │ ...          ║
║ │ Lower     │ │ Middle    │ │ Upper     │ │ Elite     │              ║
║ │ Sat: 18%  │ │ Sat: 32%  │ │ Sat: 58%  │ │ Sat: 85%  │              ║
║ │ Laborer   │ │ Baker     │ │ Merchant  │ │ Noble     │              ║
║ │ ⚠️ CRITICAL│ │ At Risk   │ │ Working   │ │ Happy     │              ║
║ │ 🏠        │ │ 🏠 🛏️     │ │ 🏠 🛏️ 📚  │ │ 🏠 🛏️ 📚 🖼️│              ║
║ └────────────┘ └────────────┘ └────────────┘ └────────────┘              ║
║                                                                           ║
║ ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐              ║
║ │ 🟢 Emma    │ │ 🟡 Frank   │ │ 🟢 Grace   │ │ 🟠 Henry   │ ...          ║
║ │ Middle    │ │ Lower     │ │ Middle    │ │ Lower     │              ║
║ │ Sat: 72%  │ │ Sat: 48%  │ │ Sat: 78%  │ │ Sat: 35%  │              ║
║ │ Farmer    │ │ Miner     │ │ Teacher   │ │ Laborer   │              ║
║ │ Working   │ │ Working   │ │ Working   │ │ Protesting│              ║
║ │ 🏠 🛏️     │ │ 🏠        │ │ 🏠 🛏️ 📚  │ │           │              ║
║ └────────────┘ └────────────┘ └────────────┘ └────────────┘              ║
║                                                                           ║
║ [Page 1 of 11] [← Prev] [Next →]                                         ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ SUMMARY STATISTICS                                                        ║
║ Average Satisfaction: 58% | Unemployment: 12% | At-Risk: 8 citizens       ║
║ [Export Data] [Mass Actions ▼]                                            ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

### 7.2 Character Detail Modal (Full)

This expands on the prototype's existing modal:

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ CHARACTER: Alice Smith                                    [Edit Mode ☐]   ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ ┌─ IDENTITY ──────────────────────────────────────────────────────────┐   ║
║ │ Name: Alice Smith          ID: char_492851                          │   ║
║ │ Age: 35                    Gender: Female                           │   ║
║ │ Class: Middle              Vocation: Baker                          │   ║
║ │ Traits: [Ambitious] [Intellectual] [Family-Oriented]                │   ║
║ │ Enablements: [Has House ✅] [Has Education ✅] [Has Family ✅]        │   ║
║ │ Residence: Cottage #12 (Capacity: 4, Occupants: 3)                  │   ║
║ │ Workplace: Bakery (Efficiency: 92%)                                 │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ ┌─ SATISFACTION (Coarse 9D) ──────────────────────── [Expand to 49D] ─┐   ║
║ │                                                                     │   ║
║ │ Biological:      ████████░░ 78/100  [▼]                             │   ║
║ │ Safety:          █████████░ 85/100  [▼]                             │   ║
║ │ Touch:           ███████░░░ 72/100  [▼]                             │   ║
║ │ Psychological:   █████░░░░░ 52/100  [▼] ⚠️ Low                       │   ║
║ │ Social Status:   ██████░░░░ 65/100  [▼]                             │   ║
║ │ Social Connect:  ████████░░ 82/100  [▼]                             │   ║
║ │ Exotic Goods:    ██░░░░░░░░ 25/100  [▼]                             │   ║
║ │ Shiny Objects:   █░░░░░░░░░ 15/100  [▼]                             │   ║
║ │ Vice:            ███░░░░░░░ 35/100  [▼]                             │   ║
║ │                                                                     │   ║
║ │ OVERALL: ██████░░░░ 65/100 (Content)                                │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ ┌─ CURRENT CRAVINGS (Top 10 Urgent) ──────────────────────────────────┐   ║
║ │                                                                     │   ║
║ │ 🔥 psychological_entertainment: 78 (CRITICAL!)                      │   ║
║ │    Last satisfied: 4 cycles ago | Decay rate: 3.2/cycle             │   ║
║ │    Best commodity: Wine, Book, Music                                │   ║
║ │                                                                     │   ║
║ │ 🔥 biological_nutrition_grain: 65                                   │   ║
║ │    Last satisfied: 1 cycle ago | Decay rate: 5.0/cycle              │   ║
║ │    Best commodity: Bread, Cake                                      │   ║
║ │                                                                     │   ║
║ │ ⚡ social_connection_friendship: 52                                 │   ║
║ │    Last satisfied: 8 cycles ago | Decay rate: 1.5/cycle             │   ║
║ │    Best commodity: Tavern visit, Festival                           │   ║
║ │                                                                     │   ║
║ │ [Show all 49 dimensions...]                                         │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ ┌─ COMMODITY FATIGUE (Diminishing Returns) ───────────────────────────┐   ║
║ │                                                                     │   ║
║ │ 🍞 Bread:  ███░░ 60% effective (consumed 5x recently)               │   ║
║ │ 🍰 Cake:   █░░░░ 20% effective (consumed 8x - TIRED!)               │   ║
║ │ 🍷 Wine:   ████░ 80% effective (consumed 3x)                        │   ║
║ │ 📖 Book:   █████ 100% (fresh - hasn't consumed recently)            │   ║
║ │                                                                     │   ║
║ │ TIP: Variety helps! Consuming different items prevents fatigue.     │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ ┌─ POSSESSIONS (Durable Goods Owned) ─────────────────────────────────┐   ║
║ │                                                                     │   ║
║ │ 🏠 House (housing) - PERMANENT                                      │   ║
║ │    Effectiveness: 100% | Provides: shelter +20, privacy +15/cycle   │   ║
║ │                                                                     │   ║
║ │ 🛏️ Bed (furniture_sleep) - DURABLE                                  │   ║
║ │    Remaining: 87/100 cycles | Effectiveness: 93%                    │   ║
║ │    Condition: [████████░░] Good                                     │   ║
║ │    Provides: rest +15, peace +10/cycle                              │   ║
║ │                                                                     │   ║
║ │ 📚 Bookshelf (furniture_study) - DURABLE                            │   ║
║ │    Remaining: 156/200 cycles | Effectiveness: 98%                   │   ║
║ │    Provides: education +8, entertainment +5/cycle                   │   ║
║ │                                                                     │   ║
║ │ [+ Add Possession] (Edit mode)                                      │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ ┌─ CONSUMPTION HISTORY (Last 20 Cycles) ──────────────────────────────┐   ║
║ │                                                                     │   ║
║ │ Cycle 2847: ✅ Bread → nutrition +5.2, taste +2.1                   │   ║
║ │ Cycle 2846: ✅ Acquired Bookshelf (durable, 200 cycles)             │   ║
║ │ Cycle 2845: ✅ Wine → entertainment +8.1, vice +3.2                 │   ║
║ │ Cycle 2844: ❌ FAILED - No allocation (shortage)                    │   ║
║ │ Cycle 2843: ✅ Bread → nutrition +3.8 (diminished by fatigue)       │   ║
║ │ Cycle 2842: ✅ Meat → protein +9.5, taste +4.3                      │   ║
║ │                                                                     │   ║
║ │ [Show more...] [Export History]                                     │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ ┌─ ECONOMY & WEALTH ──────────────────────────────────────────────────┐   ║
║ │                                                                     │   ║
║ │ Current Wealth: 345 gold                                            │   ║
║ │ Income: +25/cycle (from Bakery work)                                │   ║
║ │ Expenses: -12/cycle (food, rent, goods)                             │   ║
║ │ Net: +13/cycle                                                      │   ║
║ │ Savings Rate: 52%                                                   │   ║
║ │                                                                     │   ║
║ │ Wealth Rank: #23 of 87 (Top 27%)                                    │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ ┌─ STATUS & RISKS ────────────────────────────────────────────────────┐   ║
║ │                                                                     │   ║
║ │ Priority Rank: #12 of 87 (allocation order)                         │   ║
║ │ Productivity: 92% (slightly below max due to entertainment need)    │   ║
║ │ Consecutive Failures: 1                                             │   ║
║ │ Emigration Risk: Low (5%)                                           │   ║
║ │ Protest Risk: Very Low (1%)                                         │   ║
║ │                                                                     │   ║
║ │ Status: 🟢 STABLE - Content and productive                          │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ ACTIONS:                                                                  ║
║ [Assign to Building] [Prioritize Allocation] [View Family]               ║
║ [Relocate Housing] [View Full History] [Delete Character] (Edit mode)    ║
║                                                                           ║
║                                    [CLOSE]                                ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## 8. Economy & Trade

### 8.1 Inventory Panel

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ TOWN INVENTORY                                           [Search: ____]   ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ FILTER: [All ▼] [Food] [Materials] [Goods] [Luxury] [Durables]           ║
║ SORT:   [Quantity ▼] [Name] [Value] [Demand] [Trend]                     ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ CATEGORY: FOOD                                                            ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ Item          Qty     Trend    Production    Consumption    Status        ║
║ ─────────────────────────────────────────────────────────────────────     ║
║ 🌾 Wheat      892     ▲ +45    60/cycle      15/cycle       Surplus       ║
║ 🍞 Bread      452     → +2     40/cycle      38/cycle       Balanced      ║
║ 🥩 Meat       128     ▼ -12    15/cycle      27/cycle       ⚠️ Shortage   ║
║ 🥛 Milk       234     → +5     25/cycle      20/cycle       Surplus       ║
║ 🥬 Vegetable  345     ▲ +18    30/cycle      12/cycle       Surplus       ║
║ 🍷 Wine        87     ▼ -8     10/cycle      18/cycle       ⚠️ Shortage   ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ CATEGORY: DURABLES                                                        ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ Item          Qty     Trend    Production    In Use    Available          ║
║ ─────────────────────────────────────────────────────────────────────     ║
║ 🛏️ Bed         15     → 0      2/cycle       12        3 available        ║
║ 🪑 Chair       28     ▲ +3     3/cycle       22        6 available        ║
║ 📚 Book        45     → +1     5/cycle       38        7 available        ║
║ 🏠 House*      --     --       --            85        13 vacant          ║
║                                                                           ║
║ * Houses tracked separately in Building menu                              ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ TREASURY                                                                  ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ Gold: 💰 2,450                                                            ║
║ Income:  +350/cycle (taxes, trade)                                        ║
║ Expenses: -225/cycle (wages, imports, maintenance)                        ║
║ Net:     +125/cycle                                                       ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ QUICK ACTIONS                                                             ║
║ [Import Goods] [Export Surplus] [Set Auto-Trade Rules] [View Trade Log]  ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

### 8.2 Trade Panel

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ TRADE                                                                     ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ TRADING PARTNERS                                                          ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ 🏘️ Riverside (Friendly)     Distance: 2 days                        │   ║
║ │    Exports: Fish, Lumber    Imports: Wheat, Bread                   │   ║
║ │    Tariff: 5%               [Trade] [View Details]                  │   ║
║ ├─────────────────────────────────────────────────────────────────────┤   ║
║ │ ⛏️ Ironhaven (Neutral)       Distance: 3 days                        │   ║
║ │    Exports: Iron, Tools     Imports: Food, Cloth                    │   ║
║ │    Tariff: 10%              [Trade] [View Details]                  │   ║
║ ├─────────────────────────────────────────────────────────────────────┤   ║
║ │ 🏰 Kingstown (Distant)       Distance: 5 days                        │   ║
║ │    Exports: Luxury goods    Imports: Raw materials                  │   ║
║ │    Tariff: 15%              [Trade] [View Details]                  │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ ACTIVE TRADE ROUTES                                                       ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ Route                     Goods              Value      Status            ║
║ ────────────────────────────────────────────────────────────────────      ║
║ → Riverside               50 Wheat           150g       In transit (1d)   ║
║ ← Riverside               30 Fish            120g       Arriving today    ║
║ → Ironhaven               100 Bread          400g       In transit (2d)   ║
║                                                                           ║
║ Trade Balance: +85g/cycle (Surplus)                                       ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ START NEW TRADE                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ Partner: [Riverside ▼]                                                    ║
║                                                                           ║
║ EXPORT (You Send)              │ IMPORT (You Receive)                     ║
║ Wheat:     [50 ] @ 3g each     │ Fish:      [30 ] @ 4g each               ║
║ Bread:     [0  ] @ 8g each     │ Lumber:    [0  ] @ 6g each               ║
║                                │                                          ║
║ You Pay: 150g                  │ You Receive: 120g                        ║
║ Net Cost: 30g + 5% tariff = 31.5g                                        ║
║                                                                           ║
║ [Confirm Trade] [Set as Recurring] [Cancel]                               ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

### 8.3 Market Economy Panel (When Market Mode Enabled)

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ MARKET - Internal Town Economy                                            ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ PRICE BOARD                                                               ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ Commodity      Price    Change   Supply   Demand   Market Status    │   ║
║ │ ─────────────────────────────────────────────────────────────────── │   ║
║ │ 🍞 Bread       5g       ▼ -1     452      38/cyc   Buyer's market   │   ║
║ │ 🥩 Meat        12g      ▲ +3     128      27/cyc   Seller's market  │   ║
║ │ 🍷 Wine        8g       ▲ +2     87       18/cyc   Balanced         │   ║
║ │ 🛏️ Bed         45g      → 0      15       5/cyc    Stable           │   ║
║ │ 📚 Book        15g      ▼ -2     45       8/cyc    Buyer's market   │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ PRICE HISTORY (Last 50 cycles)                                            ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ Bread: [Chart showing price over time]                              │   ║
║ │   15g ─────────────────────────────                                 │   ║
║ │   10g ──────╱╲─────────────────────                                 │   ║
║ │    5g ─────╱  ╲____________________                                 │   ║
║ │        Cycle 2800         2850                                      │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ MARKET CONTROLS                                                           ║
║ Price Floor (Bread): [3g ]    Price Ceiling: [10g]                        ║
║ [Set Price Controls] [Remove Controls] [View All Price History]           ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ WEALTH DISTRIBUTION                                                       ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ Gini Coefficient: 0.42 (Moderate inequality)                              ║
║                                                                           ║
║ Wealth by Class:                                                          ║
║ Elite (2):    ████████████████████ 45% of total wealth (avg: 5,625g)     ║
║ Upper (8):    ████████████░░░░░░░░ 30% of total wealth (avg: 938g)       ║
║ Middle (35):  ██████░░░░░░░░░░░░░░ 18% of total wealth (avg: 129g)       ║
║ Lower (42):   ██░░░░░░░░░░░░░░░░░░  7% of total wealth (avg: 42g)        ║
║                                                                           ║
║ [View Detailed Distribution] [Set Wealth Redistribution Policy]           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## 9. Town Management

### 9.1 Analytics Dashboard

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ TOWN ANALYTICS                                                            ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ [Overview] [Satisfaction] [Economy] [Production] [Demographics]           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ SATISFACTION OVERVIEW                                                     ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │                                                                     │   ║
║ │ Town Average: ██████░░░░ 58%                                        │   ║
║ │                                                                     │   ║
║ │ Distribution:                                                       │   ║
║ │ 80-100% (Happy):    ████░░░░░░░░░░░░░░░░░░ 12 citizens (14%)       │   ║
║ │ 60-79% (Content):   ████████░░░░░░░░░░░░░░ 28 citizens (32%)       │   ║
║ │ 40-59% (Neutral):   ██████████░░░░░░░░░░░░ 32 citizens (37%)       │   ║
║ │ 20-39% (Unhappy):   ████░░░░░░░░░░░░░░░░░░ 10 citizens (12%)       │   ║
║ │ 0-19% (Critical):   █░░░░░░░░░░░░░░░░░░░░░  5 citizens (5%) ⚠️     │   ║
║ │                                                                     │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ SATISFACTION BY DIMENSION (Town Average)                                  ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ Biological:      ████████░░ 78% - Food/water needs mostly met       │   ║
║ │ Safety:          █████████░ 85% - Secure town, stable governance    │   ║
║ │ Touch:           ███████░░░ 72% - Adequate clothing/furniture       │   ║
║ │ Psychological:   █████░░░░░ 52% - Entertainment lacking ⚠️          │   ║
║ │ Social Status:   ██████░░░░ 65% - Class mobility exists             │   ║
║ │ Social Connect:  ████████░░ 82% - Strong community                  │   ║
║ │ Exotic Goods:    ██░░░░░░░░ 25% - Limited imports                   │   ║
║ │ Shiny Objects:   █░░░░░░░░░ 15% - Few luxury items                  │   ║
║ │ Vice:            ███░░░░░░░ 35% - Tavern exists but limited         │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ TRENDS (Last 100 Cycles)                                                  ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ 80% ─────────────────────────────────────                           │   ║
║ │ 60% ────────────╱‾‾‾‾╲________╱‾╲________                           │   ║
║ │ 40% ___________╱     ╲      ╱   ╲                                   │   ║
║ │ 20% ─────────────────────────────────────                           │   ║
║ │     Cycle 2750      2800      2850                                  │   ║
║ │                                                                     │   ║
║ │ ── Overall  ── Biological  ── Psychological                         │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ KEY INSIGHTS                                                              ║
║ • Entertainment is your weakest dimension - consider building a theater  ║
║ • Lower class satisfaction (38%) is dragging down the average            ║
║ • Meat shortage is causing biological satisfaction to drop               ║
║                                                                           ║
║ [Export Report] [Set Alerts] [Compare to Last Week]                       ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

### 9.2 Allocation Policy Panel

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ ALLOCATION POLICY - How Resources Are Distributed                         ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ ECONOMIC MODEL                                                            ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ ● Communist Allocation                                              │   ║
║ │   Central distribution based on need. No money required.            │   ║
║ │                                                                     │   ║
║ │ ○ Mixed Economy                                                     │   ║
║ │   Basic needs allocated; luxury goods require purchase.             │   ║
║ │                                                                     │   ║
║ │ ○ Market Economy                                                    │   ║
║ │   All goods bought/sold with money. Safety net for poor.            │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ PRIORITY MODE (Communist/Mixed only)                                      ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ ○ Need-Based                                                        │   ║
║ │   Most desperate characters get resources first.                    │   ║
║ │                                                                     │   ║
║ │ ● Balanced                                                          │   ║
║ │   Desperation + fairness (prevents same people always winning).     │   ║
║ │                                                                     │   ║
║ │ ○ Egalitarian                                                       │   ║
║ │   Equal chance for all, regardless of class or need.                │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ CLASS WEIGHTS                                                             ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ How much priority boost does each class get?                        │   ║
║ │                                                                     │   ║
║ │ Elite:  [══════════|] 10x    More resources, less often            │   ║
║ │ Upper:  [═══════|═══] 7x                                            │   ║
║ │ Middle: [════|══════] 4x                                            │   ║
║ │ Lower:  [═|═════════] 1x     Basic resources, fair share           │   ║
║ │                                                                     │   ║
║ │ Effect: Elite gets 10x the priority score boost vs Lower            │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ FAIRNESS SETTINGS                                                         ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ History Penalty: [═════|═════] 50%                                  │   ║
║ │ (Higher = more fair, lower classes get more turns)                  │   ║
║ │                                                                     │   ║
║ │ Critical Threshold: [15]                                            │   ║
║ │ (Ignore class weights for characters with craving below this)       │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ BUDGET PER CLASS (items/cycle)                                            ║
║ Elite: [10]  Upper: [8]  Middle: [5]  Lower: [3]  Poor: [2]              ║
║                                                                           ║
║ QUICK PRESETS                                                             ║
║ [Egalitarian] [Hierarchical] [Survival Mode] [Balanced] [Custom...]       ║
║                                                                           ║
║ PREVIEW: Top 10 Priority Characters                                       ║
║ #1 Bob (Lower, desperation 95) → #2 Alice (Elite, class bonus)...         ║
║                                                                           ║
║              [APPLY CHANGES] [REVERT] [SAVE AS PRESET]                    ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

### 9.3 Governance Panel

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ GOVERNANCE - Town Laws & Policies                                         ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ GOVERNMENT TYPE                                                           ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ Current: Benevolent Dictatorship (You control everything)           │   ║
║ │                                                                     │   ║
║ │ Other options (unlock through gameplay):                            │   ║
║ │ ○ Council Rule - Elected representatives vote on policies           │   ║
║ │ ○ Merchant Guild - Economy-focused, trade bonuses                   │   ║
║ │ ○ Theocracy - Temple-centered, spirituality bonuses                 │   ║
║ │ ○ Democracy - Citizens vote, slower decisions, higher satisfaction  │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ TAXATION                                                                  ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ Income Tax Rate: [═══════|═══] 15%                                  │   ║
║ │ Effect: +52g/cycle treasury, -3% citizen satisfaction               │   ║
║ │                                                                     │   ║
║ │ Trade Tax Rate: [════|══════] 5%                                    │   ║
║ │ Effect: +18g/cycle treasury, -5% trade volume                       │   ║
║ │                                                                     │   ║
║ │ Luxury Tax Rate: [══════════|] 25%                                  │   ║
║ │ Effect: +35g/cycle from elite purchases, no broad impact            │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ LAWS & EDICTS                                                             ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ ☑️ Mandatory Work - All able citizens must have a job                │   ║
║ │    Effect: -5% satisfaction, +15% productivity                      │   ║
║ │                                                                     │   ║
║ │ ☐ Rationing - Limit consumption during shortages                    │   ║
║ │    Effect: Spreads resources more evenly, lower max satisfaction    │   ║
║ │                                                                     │   ║
║ │ ☑️ Free Education - School access for all children                   │   ║
║ │    Effect: +10% child development, -20g/cycle cost                  │   ║
║ │                                                                     │   ║
║ │ ☐ Closed Borders - No new immigration                               │   ║
║ │    Effect: Population won't grow, but won't lose to emigration      │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ [ENACT NEW LAW] [VIEW ALL LAWS] [REPEAL LAW]                              ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## 10. Information System

### 10.1 Recipes Tab

(Already implemented - shows building recipes, inputs/outputs, worker requirements)

### 10.2 Commodities Tab

(Already implemented - shows all commodities with durability fields)

### 10.3 Characters Reference Tab (New)

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ INFORMATION SYSTEM - Character Reference                                  ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ [Recipes] [Commodities] [Characters] [Buildings] [Mechanics]              ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ VOCATIONS                                                                 ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ Farmer                                                              │   ║
║ │ • Works at: Farm, Orchard, Vineyard                                 │   ║
║ │ • Base productivity: 100%                                           │   ║
║ │ • Training time: 5 cycles                                           │   ║
║ │ • Typical class: Lower, Middle                                      │   ║
║ ├─────────────────────────────────────────────────────────────────────┤   ║
║ │ Blacksmith                                                          │   ║
║ │ • Works at: Forge, Armory                                           │   ║
║ │ • Base productivity: 100%                                           │   ║
║ │ • Training time: 15 cycles                                          │   ║
║ │ • Typical class: Middle                                             │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ TRAITS                                                                    ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ [Hardworking]                                                       │   ║
║ │ • +15% productivity                                                 │   ║
║ │ • +10% fatigue resistance                                           │   ║
║ │ • Occurrence: 12% of population                                     │   ║
║ ├─────────────────────────────────────────────────────────────────────┤   ║
║ │ [Ambitious]                                                         │   ║
║ │ • +20% career growth speed                                          │   ║
║ │ • -10% contentment with current status                              │   ║
║ │ • Occurrence: 8% of population                                      │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ CLASSES                                                                   ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ Elite                                                               │   ║
║ │ • Wealth threshold: >5,000g                                         │   ║
║ │ • Housing: Manor or better                                          │   ║
║ │ • Consumption priority: 10x                                         │   ║
║ │ • Craving profile: High luxury, status, exotic goods                │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## 11. Save/Load & Settings

### 11.1 Save/Load Panel

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ SAVE / LOAD GAME                                                          ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ SAVE SLOTS                                                                ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ Slot 1: "Prosperityville - Cycle 2847"                              │   ║
║ │         Saved: 2025-12-03 14:32 | Pop: 87 | Satisfaction: 58%       │   ║
║ │         [LOAD] [SAVE] [DELETE]                                      │   ║
║ ├─────────────────────────────────────────────────────────────────────┤   ║
║ │ Slot 2: "Ironhaven Experiment - Cycle 1205"                         │   ║
║ │         Saved: 2025-12-02 09:15 | Pop: 45 | Satisfaction: 72%       │   ║
║ │         [LOAD] [SAVE] [DELETE]                                      │   ║
║ ├─────────────────────────────────────────────────────────────────────┤   ║
║ │ Slot 3: [Empty]                                                     │   ║
║ │         [SAVE NEW]                                                  │   ║
║ ├─────────────────────────────────────────────────────────────────────┤   ║
║ │ Slot 4: [Empty]                                                     │   ║
║ │         [SAVE NEW]                                                  │   ║
║ ├─────────────────────────────────────────────────────────────────────┤   ║
║ │ Slot 5: [Empty]                                                     │   ║
║ │         [SAVE NEW]                                                  │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ AUTOSAVE                                                                  ║
║ ☑️ Enable Autosave    Every: [25 ▼] cycles                                ║
║ Last Autosave: Cycle 2825 (2025-12-03 14:20)                              ║
║ [Load Autosave]                                                           ║
║                                                                           ║
║ QUICKSAVE                                                                 ║
║ Press F5 to quicksave, F9 to quickload                                    ║
║ Last Quicksave: Cycle 2840 (2025-12-03 14:28)                             ║
║                                                                           ║
║                              [CLOSE]                                      ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

### 11.2 Settings Panel

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ SETTINGS                                                                  ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ [Gameplay] [Display] [Audio] [Controls] [Accessibility]                   ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ GAMEPLAY                                                                  ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ Simulation Speed Options: [1x] [2x] [5x] [10x]                      │   ║
║ │ Auto-pause on Events: ☑️ Critical | ☐ Warning | ☐ Info              │   ║
║ │ Tutorial Hints: ● On ○ Off                                          │   ║
║ │ Notification Frequency: [Medium ▼]                                  │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ DISPLAY                                                                   ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ Resolution: [1920x1080 ▼]                                           │   ║
║ │ Fullscreen: ● On ○ Off                                              │   ║
║ │ UI Scale: [═════|═════] 100%                                        │   ║
║ │ Show Character Names: ● Always ○ On Hover ○ Never                   │   ║
║ │ Show Production Numbers: ☑️                                          │   ║
║ │ Color Blind Mode: [Normal ▼]                                        │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║ AUDIO                                                                     ║
║ ┌─────────────────────────────────────────────────────────────────────┐   ║
║ │ Master Volume: [═══════|═══] 70%                                    │   ║
║ │ Music Volume:  [═════════|═] 90%                                    │   ║
║ │ SFX Volume:    [═════|═════] 50%                                    │   ║
║ │ Notification Sounds: ☑️                                              │   ║
║ └─────────────────────────────────────────────────────────────────────┘   ║
║                                                                           ║
║                    [APPLY] [RESET TO DEFAULTS] [CLOSE]                    ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## 12. Notifications & Events

### 12.1 Notification Types

| Priority | Icon | Examples | Auto-pause? |
|----------|------|----------|-------------|
| Critical | 🔴 | Riot, Mass emigration, Starvation | Yes |
| Warning | 🟠 | Shortage imminent, High emigration risk | Optional |
| Info | 🟢 | Production complete, Immigrant arrived | No |
| Success | ✅ | Trade complete, Building finished | No |

### 12.2 Notification Toast Format

```
┌────────────────────────────────────────────────────┐
│ 🔴 CRITICAL: 5 Citizens Starving!                  │
│ Bread supply exhausted. Production needed.         │
│ [View Citizens] [Inject Resources] [Dismiss]       │
└────────────────────────────────────────────────────┘
```

### 12.3 Event History Modal

```
╔═══════════════════════════════════════════════════════════════════════════╗
║ EVENT HISTORY                                                             ║
╠═══════════════════════════════════════════════════════════════════════════╣
║ FILTER: [All ▼] [Production] [Consumption] [Immigration] [Crisis]         ║
║ RANGE: [Last 100 cycles ▼]                                               ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║ [2847] 🟢 Wheat Farm produced 15 wheat                                    ║
║ [2847] 🟢 Alice received bread (satisfaction +5)                          ║
║ [2847] 🟢 3 immigrants arrived: Marcus, Li, Wei Chen                      ║
║ [2846] 🟠 Bob's satisfaction critical (18%) - emigration risk 85%         ║
║ [2846] 🔴 Carol emigrated to Riverside (reason: starvation)               ║
║ [2845] 🟢 New building: Bakery completed                                  ║
║ [2844] 🟠 Bread shortage warning (5 cycles supply remaining)              ║
║ [2843] 🟢 Trade complete: 50 wheat sold to Riverside (+150g)              ║
║ [2842] 🔴 RIOT in lower district! 15% inventory destroyed                 ║
║                                                                           ║
║ [Show more...] [Export to File] [Clear Old Events]                        ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

---

## 13. Keyboard Shortcuts & Accessibility

### 13.1 Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **SPACE** | Pause/Resume simulation |
| **1/2/3/4** | Set speed 1x/2x/5x/10x |
| **B** | Open Build menu |
| **C** | Open Citizens panel |
| **I** | Open Inventory |
| **A** | Open Analytics |
| **T** | Open Trade |
| **P** | Open Policy |
| **M** | Open Immigration |
| **ESC** | Close current panel / Back |
| **F5** | Quicksave |
| **F9** | Quickload |
| **H** | Toggle Help overlay |
| **WASD** | Pan camera |
| **Q/E** | Rotate camera (if applicable) |
| **Scroll** | Zoom in/out |
| **Tab** | Cycle through buildings |
| **Enter** | Confirm selection |
| **Delete** | Delete selected (with confirmation) |

### 13.2 Help Overlay

Pressing **H** shows:

```
┌─────────────────────────────────────────────────────────────────────┐
│                         KEYBOARD SHORTCUTS                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│ SIMULATION           │ PANELS              │ CAMERA                 │
│ SPACE - Pause/Play   │ B - Build           │ WASD - Pan             │
│ 1-4 - Speed          │ C - Citizens        │ Scroll - Zoom          │
│                      │ I - Inventory       │ Middle-drag - Pan      │
│ SAVE/LOAD            │ A - Analytics       │                        │
│ F5 - Quicksave       │ T - Trade           │ SELECTION              │
│ F9 - Quickload       │ P - Policy          │ Click - Select         │
│                      │ M - Immigration     │ Tab - Next building    │
│ GENERAL              │ ESC - Close/Back    │ Delete - Remove        │
│ H - This help        │                     │ Enter - Confirm        │
│                                                                     │
│                        Press H to close                             │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 14. Visual Design Language

### 14.1 Color Palette

| Purpose | Color | Hex |
|---------|-------|-----|
| **Background (Dark)** | Dark blue-gray | #1a1a2e |
| **Panel Background** | Slightly lighter | #25253a |
| **Primary Accent** | Warm gold | #d4a855 |
| **Success/Happy** | Green | #4ade80 |
| **Warning** | Orange | #fb923c |
| **Critical/Unhappy** | Red | #ef4444 |
| **Neutral** | Yellow | #facc15 |
| **Info** | Blue | #60a5fa |
| **Text Primary** | White | #ffffff |
| **Text Secondary** | Gray | #9ca3af |

### 14.2 Satisfaction Colors

```
Satisfaction Level    Color        Usage
───────────────────────────────────────────
80-100% (Happy)       #4ade80      Character cards, bars, icons
60-79% (Content)      #a3e635      Character cards, bars
40-59% (Neutral)      #facc15      Character cards, bars
20-39% (Unhappy)      #fb923c      Character cards, bars, warnings
0-19% (Critical)      #ef4444      Character cards, bars, alerts
```

### 14.3 Class Colors

```
Class       Primary Color    Usage
────────────────────────────────────────
Elite       #a855f7 (Purple) Badges, borders, indicators
Upper       #3b82f6 (Blue)   Badges, borders
Middle      #22c55e (Green)  Badges, borders
Lower       #eab308 (Yellow) Badges, borders
Poor        #78716c (Gray)   Badges, borders
```

### 14.4 Typography

```
Headings:    Bold, 18-24px
Subheadings: Semi-bold, 14-16px
Body Text:   Regular, 12-14px
Labels:      Regular, 10-12px
Numbers:     Monospace, 12-14px (for alignment)
```

### 14.5 Icons

Use consistent emoji or custom icon set:
- 🏠 House/Housing
- 🌾 Farm/Agriculture
- 🍞 Food/Bread
- 🥩 Meat
- 🍷 Wine/Entertainment
- 💰 Gold/Money
- 👥 Population
- 📊 Analytics
- ⚙️ Settings
- ⚠️ Warning
- ✅ Success
- ❌ Failure

---

## 15. Missing Features & Recommendations

### 15.1 Features Not Yet Covered

| Feature | Priority | Notes |
|---------|----------|-------|
| **Natural Resources Overlay** | High | Show water, fertility, ore deposits on map |
| **Weather System** | Medium | Affects production, mood |
| **Seasons** | Medium | Cyclical production changes |
| **Disasters** | Medium | Fire, plague, drought events |
| **Religion/Spirituality** | Medium | Temple buildings, faith satisfaction |
| **Crime & Security** | Medium | Guard posts, crime rates |
| **Education System** | Medium | Schools, literacy, skill growth |
| **Healthcare** | Medium | Hospitals, disease, aging |
| **Family & Reproduction** | High | Births, deaths, family trees |
| **Social Events** | Medium | Festivals, weddings, funerals |
| **Technology/Research** | Low | Unlock new buildings/features |
| **Achievements** | Low | Goals and milestones |
| **Scenarios/Challenges** | Medium | Pre-built scenarios with objectives |

### 15.2 Recommended Implementation Order

**Phase 1: Core Loop Polish (Current)**
- Immigration system ✓ (designed)
- World view with buildings and characters ✓ (designed)
- Worker assignment ✓ (designed)

**Phase 2: Natural Resources**
- Resource overlay on world map
- Building placement efficiency
- Resource constraints on production

**Phase 3: Family & Demographics**
- Births and deaths
- Family relationships
- Age-based craving changes
- Inheritance system

**Phase 4: Events & Disasters**
- Weather effects
- Seasonal changes
- Random events (fire, plague, etc.)
- Event response choices

**Phase 5: Advanced Economy**
- Full market economy mode
- Dynamic pricing
- Supply/demand simulation
- Trade route optimization

**Phase 6: Governance & Late Game**
- Government type transitions
- Laws and edicts
- Multi-town interaction
- Victory conditions

---

## 16. Screen Flow Diagrams

### 16.1 Main Navigation Flow

```
                              ┌─────────────┐
                              │ Title Screen│
                              └──────┬──────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              │                      │                      │
              ▼                      ▼                      ▼
       ┌────────────┐        ┌────────────┐        ┌────────────┐
       │  New Game  │        │  Continue  │        │  Load Game │
       └─────┬──────┘        └─────┬──────┘        └─────┬──────┘
             │                     │                      │
             ▼                     │                      │
       ┌────────────┐              │                      │
       │Setup Wizard│              │                      │
       │ (3 steps)  │              │                      │
       └─────┬──────┘              │                      │
             │                     │                      │
             └──────────────┬──────┴──────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  MAIN GAME    │
                    │  WORLD VIEW   │
                    └───────┬───────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
 ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
 │   BUILD     │    │  CITIZENS   │    │  ANALYTICS  │
 │   MENU      │    │   PANEL     │    │  DASHBOARD  │
 └─────────────┘    └──────┬──────┘    └─────────────┘
                           │
                           ▼
                   ┌─────────────┐
                   │ CHARACTER   │
                   │ DETAIL      │
                   └─────────────┘
```

### 16.2 Immigration Flow

```
┌─────────────────┐
│ Immigration     │
│ Notification    │
│ (Alert badge)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Immigration     │
│ Queue Panel     │
└────────┬────────┘
         │
   ┌─────┴─────┐
   │           │
   ▼           ▼
┌───────┐ ┌───────┐
│ACCEPT │ │REJECT │
└───┬───┘ └───────┘
    │
    ▼
┌─────────────────┐
│ Assign Housing  │
│ Modal           │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Citizen Added   │
│ to Town         │
└─────────────────┘
```

### 16.3 Building Flow

```
┌─────────────────┐
│ Click "Build"   │
│ in menu         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Building        │
│ Selection Menu  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Placement Mode  │
│ (Ghost building)│
└────────┬────────┘
         │
   ┌─────┴─────┐
   │           │
   ▼           ▼
┌───────┐ ┌───────┐
│PLACE  │ │CANCEL │
└───┬───┘ └───────┘
    │
    ▼
┌─────────────────┐
│ Building        │
│ Constructed     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Assign Workers  │
│ Prompt          │
└─────────────────┘
```

---

## 17. Appendix: Data Requirements

### 17.1 Save File Structure

```lua
saveData = {
    version = "1.0",
    townName = "Prosperityville",
    cycleNumber = 2847,
    treasury = 2450,

    characters = {
        -- Array of character objects with all 6 layers
    },

    buildings = {
        -- Array of building objects with workers, production state
    },

    inventory = {
        -- Commodity -> quantity mapping
    },

    immigrationQueue = {
        -- Array of pending immigrants
    },

    eventLog = {
        -- Last 1000 events
    },

    policies = {
        economicModel = "communist",
        allocationMode = "balanced",
        classWeights = {Elite=10, Upper=7, Middle=4, Lower=1},
        -- etc.
    },

    statistics = {
        -- Historical data for charts
    }
}
```

### 17.2 New Data Files Needed

| File | Purpose |
|------|---------|
| `buildings.json` | Building definitions (cost, workers, production) |
| `vocations.json` | Vocation definitions (skills, buildings) |
| `traits.json` | Trait definitions (effects, occurrence) |
| `events.json` | Random event definitions |
| `scenarios.json` | Pre-built scenario definitions |
| `locations.json` | Starting location definitions |
| `trade_partners.json` | NPC town definitions |

---

## 18. Change Log

| Date | Version | Changes |
|------|---------|---------|
| 2025-12-03 | 1.0 | Initial comprehensive UI flow specification |

---

## 19. Next Steps

1. **Review with team** - Get feedback on priorities and missing features
2. **Create mockups** - Visual designs for key screens
3. **Prioritize implementation** - Decide which screens to build first
4. **Define data schemas** - Finalize JSON structures
5. **Begin implementation** - Start with world view and immigration

---

*This document serves as the master reference for CraveTown's UI design. All implementation should align with these specifications.*
