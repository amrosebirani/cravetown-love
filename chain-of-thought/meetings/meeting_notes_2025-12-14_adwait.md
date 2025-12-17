# Meeting Notes: Adwait Discussion - Bugs & Future Vision
**Date:** 2025-12-14
**Participants:** Amrose, Adwait
**Status:** Bug Review & Feature Planning
**High-Level Goal:** Get the game playable in the next 1 week

---

## Executive Summary

Discussion covering bug fixes, missing features, and future vision for evolving Cravetown into Riot City. Key areas: housing scalability, tutorial system, citizen lifecycle modeling, economic systems verification, and community/modding ecosystem. The meeting identified critical bugs blocking playability and longer-term architectural considerations for social systems.

---

## 1. Future Evolution: Riot City Housing

### Concept
For future evolution from Cravetown to Riot City, need high-density housing options:
- **Apartments** - Multi-family housing for middle-class density
- **Slums** - High-density, low-quality housing for lower classes
- Both allow many citizens in small footprint

### Implementation Considerations
```
Housing density evolution:
- Current: House → single family
- Future: House < Apartment < Slum (by density)
- Trade-off: Density vs. Quality vs. Satisfaction impact
```

### Status
- [ ] Design housing capacity scaling system
- [ ] Define satisfaction penalties for high-density housing

---

## 2. UI Flow Verification

### Action Required
Need comprehensive review against the original Game UI Flow specification document (`game_ui_flow_specification.md`) to identify any missed implementation details.

### Status
- [ ] Cross-reference implemented flows with specification
- [ ] Document gaps and missing features
- [ ] Prioritize for 1-week playability target

---

## 3. Bugs & Issues

### 3.1 Recipe Selection Click - Glitchy
**Priority:** High (affects gameplay)
**Description:** Recipe selection UI has click registration issues
**Status:**
- [ ] Investigate click event handling in recipe selection
- [ ] Fix glitchy behavior

### 3.2 Game Loading Slow at 1%
**Priority:** High (first impression issue)
**Description:** Loading appears to stall at 1%
**Possible Causes:**
- Heavy initial data loading
- Asset loading bottleneck
- Synchronous operations blocking progress updates
**Status:**
- [ ] Profile loading sequence
- [ ] Identify bottleneck at 1%
- [ ] Implement fix or progress feedback improvement

### 3.3 Input/Output Storage in Buildings
**Priority:** Medium-High
**Description:** Building input/output storage system not implemented well
**Status:**
- [ ] Review current storage implementation
- [ ] Identify specific issues
- [ ] Redesign if necessary

### 3.4 Butcher Building Missing
**Priority:** Medium
**Description:** Start building "butcher" is not showing in building menu
**Status:**
- [ ] Check building definitions
- [ ] Verify butcher is registered properly
- [ ] Fix visibility issue

### 3.5 Version Manager Data Cloning
**Priority:** Medium
**Description:** Data not being properly cloned in version manager
**Status:**
- [ ] Review version manager clone logic
- [ ] Implement proper deep cloning

### 3.6 Housing "21 Available" Bug in Immigration Modal
**Priority:** Medium
**Description:** Immigration modal shows incorrect housing availability (21)
**Status:**
- [ ] Debug housing calculation in immigration modal
- [ ] Fix the availability count

### 3.7 Quality Tier Random Values in Housing Overview
**Priority:** Medium
**Description:** Quality tier shows random/incorrect values in housing overview
**Status:**
- [ ] Trace quality tier data source
- [ ] Fix display logic

### 3.8 Forest Not Highlighted in Mini Map
**Priority:** Low
**Description:** Forest terrain not rendering on mini map
**Status:**
- [ ] Check mini map rendering for forest tiles
- [ ] Add forest highlighting

### 3.9 Balance Issue - Consumption vs Production
**Priority:** High (affects playability)
**Description:** Consumption rate exceeds production rate; resources deplete too fast
**Options:**
- Slow down consumption
- Speed up production
- Increase starting resources
**Status:**
- [ ] Analyze consumption/production ratios
- [ ] Adjust balance or starting resources

---

## 4. Features to Verify/Test

### 4.1 Productivity Impact
**Question:** Is productivity impact implemented and working?
**Status:**
- [ ] Verify productivity system is connected
- [ ] Test productivity effects on production

### 4.2 Location & Terrain Multipliers in Land System
**Question:** Are location multipliers and terrain multipliers working?
**Status:**
- [ ] Test location multiplier effects
- [ ] Verify terrain multipliers apply correctly

### 4.3 Economic System Components
**Question:** Are rents, building profits, and taxes working correctly?
**Status:**
- [ ] Test rent collection
- [ ] Verify building profit calculations
- [ ] Check tax system

### 4.4 Mountains Rendering
**Question:** Are mountains rendering in the system?
**Status:**
- [ ] Check mountain terrain rendering
- [ ] Fix if not displaying

### 4.5 Town Attractiveness & Compatibility Score
**Question:** Need to verify calculation for town attractiveness and compatibility
**Status:**
- [ ] Review attractiveness calculation
- [ ] Verify compatibility score formula

### 4.6 Economic System & Difficulty Selection
**Question:** Is the economic system and difficulty selected in game initialize screens actually incorporated into gameplay?
**Status:**
- [ ] Verify difficulty selection affects gameplay
- [ ] Check economic system selection integration

### 4.7 Upgrade & Demolish in Building Details
**Status:**
- [ ] Test building upgrade functionality
- [ ] Test building demolish functionality

### 4.8 MCP Working for Alpha Prototype
**Status:**
- [ ] Test MCP integration with alpha prototype
- [ ] Verify all MCP commands work

---

## 5. New Features & Improvements

### 5.1 Tutorial System
**Need:** Design and implement tutorial system for new players
**Considerations:**
- Progressive disclosure of mechanics
- Interactive vs. passive tutorials
- Skip option for experienced players
**Status:**
- [ ] Design tutorial flow
- [ ] Identify key teaching moments

### 5.2 Commodity Value Chain Visualization
**Concept:** Visual info showing how commodities are produced
**Example:** Selecting "samosa" shows:
```
Natural Resources → Intermediate → Final Product
Potato     ─┐
Wheat      ─┼─→ [Processing] ─→ Samosa
Groundnut  ─┘
```
**Status:**
- [ ] Design value chain visualization UI
- [ ] Implement in info system

### 5.3 Immigration/Emigration Weight Unification
**Insight:** Emigration weights can be reused for immigration calculations
**Status:**
- [ ] Review current weight systems
- [ ] Unify where appropriate

### 5.4 Dynamic Class Preview Calculator
**Location:** Info System UI
**Need:** Make class preview calculator dynamic (real-time updates)
**Status:**
- [ ] Implement dynamic updates
- [ ] Connect to live data

### 5.5 Differentiated Views for Housing vs Work Buildings
**Need:** Different UI/information display for:
- Housing buildings (capacity, residents, quality)
- Work buildings (workers, production, efficiency)
**Status:**
- [ ] Design differentiated views
- [ ] Implement building-type-specific panels

### 5.6 Town Gold Lifecycle
**Question:** What is the complete lifecycle of town gold?
**Needs Documentation:**
- Sources of gold
- Drains of gold
- Balance considerations
**Status:**
- [ ] Document gold lifecycle
- [ ] Verify implementation matches design

---

## 6. Citizen Fulfillment Model

### Factors Affecting Fulfillment & Personality Traits

#### 6.1 Direct Satisfaction Sources
1. **Commodities** - Consumption satisfies cravings
2. **Housing** - Quality, location, density
3. **Weather** - Environmental satisfaction
4. **People Around** - Social environment effect

#### 6.2 Community Social Forces
1. **Family System**
   - Family bonds
   - Household satisfaction

2. **Social Circle**
   - **Coworkers** - Workplace relationships
   - **Neighbours & Friends** - Community bonds
   - **Religion/Spirituality** - Belief system satisfaction

### Status
- [ ] Review current fulfillment implementation
- [ ] Design social forces system
- [ ] Prioritize which factors to implement first

---

## 7. Human-Centric Citizen Model

### Core Concepts
Citizens should have agency over:
1. **Avenues** - What opportunities they pursue
2. **Ownerships** - What they can own/control
3. **Labour** - How they contribute work

### Free Agency Integration
All these decisions should emerge from free agency system:
- Citizens make choices based on personality + circumstances
- Creates emergent behavior rather than predetermined paths
- Enables wealth accumulation or bankruptcy paths

### Asset Ownership System
**Concept:** Citizens can:
- Start businesses
- Accumulate wealth
- Go bankrupt
- Take loans from Bank building

### Implementation Considerations
```
Citizen Economic Agent:
- Personal wealth
- Owned assets (buildings, businesses)
- Debt obligations
- Income sources (wages, profits, rents)
- Risk tolerance (personality trait)
```

### Status
- [ ] Design citizen ownership system
- [ ] Define bankruptcy/wealth mechanics
- [ ] Plan Bank building functionality

---

## 8. Additional Systems to Consider

### 8.1 Social Security
**Concept:** Safety net for struggling citizens
**Related:** Class solidarity/consciousness

### 8.2 Emergent Story System
**Concept:** Stories emerge from simulation rather than scripted events

### Status
- [ ] Design social security mechanics
- [ ] Explore emergent storytelling patterns

---

## 9. Community & Tooling

### 9.1 Team Fortress Modding Research
**Action:** Pull info on how Valve enabled TF2 modding community
**Goals:**
- Understand community engagement patterns
- Apply lessons to Cravetown modding

### Status
- [ ] Research TF2/Valve modding approach
- [ ] Document applicable patterns

### 9.2 Better Tooling for Onboarding
**Timeline Target:** 3 months to crack "Cravetown Bengaluru caricature game"
**Tooling Needs:**
1. Explain data model clearly
2. Then explain game mechanics
3. Lower barrier to entry for new developers

### Status
- [ ] Create data model documentation
- [ ] Create game mechanics guide
- [ ] Streamline onboarding process

---

## Priority Matrix for 1-Week Playability

### Critical (Must Fix)
1. Balance issue - consumption vs production
2. Recipe selection glitchy
3. Game loading slow at 1%
4. Butcher building missing

### High (Should Fix)
5. Input/output storage in buildings
6. Housing availability bug in immigration
7. Verify productivity impact working

### Medium (Nice to Have)
8. Quality tier random values
9. Forest mini map highlight
10. Version manager cloning
11. Differentiated housing/work views

### Deferred (Post-1-Week)
- Tutorial system
- Commodity value chain visualization
- Social forces implementation
- Citizen ownership system

---

## Next Steps

1. **Immediate:** Triage and fix critical bugs
2. **This Week:** Verify all core systems working
3. **Parallel:** Document findings for future sprints
4. **Post-1-Week:** Begin tutorial and advanced features

---

*Document created: 2025-12-17*
*Based on meeting discussion: 2025-12-14*
