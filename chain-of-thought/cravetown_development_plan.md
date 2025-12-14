# Cravetown Development Plan
## Resource Allocation & Craving System Implementation

**Presentation for Development Team**  
Version 1.0 | November 2025

---

## Table of Contents

1. Executive Summary
2. System Overview & Core Concepts
3. Development Strategy
4. Information System Foundation
5. Prototype 1: Consumption Engine
6. Prototype 2: Production Engine
7. Integration & Merge Plan
8. Timeline & Milestones
9. Team Structure & Responsibilities
10. Risk Management
11. Success Metrics
12. Next Steps & Questions

---

## 1. Executive Summary

### Project Vision
Build a sophisticated resource allocation simulation where **120+ commodities** flow through **30+ building types** to satisfy **7 craving types** across a dynamic population with **4 social classes**.

### Core Innovation
A **hierarchy-based craving system** where character satisfaction drives immigration, production efficiency, and town prosperity through realistic substitution patterns and quality preferences.

### Development Approach
- **3-Phase Parallel Development**: Information System → Dual Prototypes → Integration
- **Two 4-week prototype streams** (Consumption + Production)
- **2-week integration phase** before final features
- **12-week total timeline** to working game loop

### Why This Approach?
- **Parallel velocity**: Two developers can work simultaneously without blocking
- **Incremental validation**: Each prototype proves core mechanics independently
- **Reduced integration risk**: Clear contracts defined upfront
- **Flexible iteration**: Data-driven design allows rapid balancing

---

## 2. System Overview & Core Concepts

### The Three-Loop Game Cycle

```
┌─────────────────────────────────────────────────────────┐
│                    GAME LOOP (60s)                      │
│                                                         │
│  ┌──────────────┐      ┌──────────────┐      ┌───────┐│
│  │ PRODUCTION   │ ───► │ ALLOCATION & │ ───► │ CONS- ││
│  │              │      │ CONSUMPTION  │      │ EQUEN ││
│  │ Buildings    │      │              │      │ -CES  ││
│  │ produce      │      │ Characters   │      │       ││
│  │ commodities  │      │ consume      │      │ Pop   ││
│  │              │      │ resources    │      │ reacts││
│  └──────────────┘      └──────────────┘      └───────┘│
│         ▲                                         │    │
│         │          FEEDBACK LOOP                  │    │
│         │   (Satisfaction → Production Efficiency)│    │
│         └─────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### 7 Craving Types

| Craving Type | Description | Example Commodities | Character Impact |
|--------------|-------------|---------------------|------------------|
| **Biological** | Food, water, medicine | Wheat, meat, medicine | Critical - emigrate if <20 |
| **Touch** | Tactile comfort, clothing | Cloth, furniture, clothes | Important for stability |
| **Psychological** | Mental stimulation | Books, art, education | Class-dependent necessity |
| **Safety** | Security, protection | Police, walls, medicine | Baseline requirement |
| **Social Status** | Prestige, reputation | Jewelry, manor, servants | Elite priority |
| **Exotic Goods** | Novelty, luxury food | Wine, spices, silk | Optional but desired |
| **Shiny Objects** | Material wealth | Gold, silver, decorations | Aspirational |

### 4 Social Classes

```
┌──────────────────────────────────────────────────────────────┐
│ ELITE                                                        │
│ • Social Status = Survival (reputation matters as much as food)│
│ • High exotic goods + shiny objects demand                   │
│ • Will only accept luxury quality goods                      │
│ • First priority in allocation queue                         │
├──────────────────────────────────────────────────────────────┤
│ UPPER CLASS                                                  │
│ • High comfort + psychological needs                         │
│ • Accepts good/luxury quality                                │
│ • Second priority in allocation                              │
├──────────────────────────────────────────────────────────────┤
│ MIDDLE CLASS                                                 │
│ • Balanced needs across all cravings                         │
│ • Accepts basic/good quality                                 │
│ • Third priority in allocation                               │
├──────────────────────────────────────────────────────────────┤
│ LOWER CLASS                                                  │
│ • High biological needs, low status needs                    │
│ • Accepts poor/basic quality                                 │
│ • Fourth priority in allocation                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 3. Development Strategy

### The Problem with Traditional Approach

**Traditional Game Development:**
```
Build everything → Test everything → Debug everything → Balance everything
                                          ↓
                              (9 months of pain)
```

**Issues:**
- Can't test consumption without production
- Can't test production without consumption
- Geographic systems block all testing
- One developer blocks the other
- Integration happens at the worst possible time (end)

### Our Solution: Parallel Prototyping

```
┌─────────────────────────────────────────────────────┐
│              INFORMATION SYSTEM (Week 1-2)          │
│  Central data repository - both prototypes read     │
│  from same source of truth                          │
└─────────────────────────────────────────────────────┘
              │                            │
              ▼                            ▼
┌──────────────────────────┐  ┌──────────────────────────┐
│  PROTOTYPE 1 (Week 3-6)  │  │  PROTOTYPE 2 (Week 3-6)  │
│  Consumption Engine      │  │  Production Engine       │
│                          │  │                          │
│  • Character behavior    │  │  • Building production   │
│  • Craving satisfaction  │  │  • Worker efficiency     │
│  • Allocation system     │  │  • Resource generation   │
│  • Emigration/riots      │  │  • Bottleneck detection  │
│                          │  │                          │
│  Developer A             │  │  Developer B             │
└──────────────────────────┘  └──────────────────────────┘
              │                            │
              └────────────┬───────────────┘
                           ▼
              ┌────────────────────────┐
              │ INTEGRATION (Week 7-9) │
              │ Full game loop active  │
              └────────────────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │  FINAL FEATURES        │
              │  (Week 10-12)          │
              │  • Geography           │
              │  • Immigration         │
              │  • Weather/Events      │
              └────────────────────────┘
```

---

## 4. Information System Foundation

### Week 1-2: Data Layer First

**File Structure:**

```
/data
├── /commodities
│   ├── commodities.json          (120 items with attributes)
│   ├── craving_mappings.json     (commodity → craving type)
│   ├── quality_tiers.json        (poor/basic/good/luxury)
│   └── substitution_rules.json   (hierarchy + cross-category)
│
├── /characters
│   ├── character_classes.json    (Elite/Upper/Middle/Lower)
│   ├── character_traits.json     (Ambitious, Frugal, etc)
│   └── vocations.json            (Miner, Teacher, etc)
│
├── /buildings
│   ├── building_recipes.json     (inputs → outputs)
│   └── worker_requirements.json  (roles, quantities, bonuses)
│
└── /systems
    ├── free_agency_rules.json    (how characters choose)
    ├── satisfaction_decay.json   (decay rates per class)
    └── consequence_thresholds.json (riot/emigrate triggers)
```

### Week 1-2 Deliverables

**✅ Definition of Done:**
- All JSON files created with example data
- JSON schemas validated (no syntax errors)
- All 120 commodities catalogued with initial mappings
- All 30+ buildings defined with recipes
- Character classes + 10 traits defined
- Substitution rules for major categories defined
- Version 1.0 tagged in Git repository

---

## 5. Prototype 1: Consumption Engine (Week 3-6)

### Developer A Focus
Character behavior, craving systems, resource allocation

### Key Components

**Week 3: Character System Foundation**
- Character.lua - Individual state & behavior
- 7 craving types with decay rates
- Personal inventory management
- Character cards UI with color coding

**Week 4: Allocation System**
- Priority queue based on class + desperation
- Substitution logic (wheat → barley → rice)
- Resource control panel (manual commodity injection for testing)
- Fulfillment tracking

**Week 5: Consequence System**
- Emigration triggers (satisfaction < 30 for 3 cycles)
- Riot mechanics (town avg < 20)
- Event logging
- Town status dashboard

**Week 6: Analytics & Grouping**
- Class/Vocation aggregation views
- Craving heatmap (7 columns × N characters)
- Top shortages/surpluses reporting
- CSV export for data analysis

### Success Criteria
✅ 100 characters run for 100 cycles without crashes  
✅ All 7 craving types decay and refill correctly  
✅ Allocation respects class priority  
✅ Substitution works  
✅ Emigration triggers appropriately  
✅ Riots occur at correct thresholds  

---

## 6. Prototype 2: Production Engine (Week 3-6)

### Developer B Focus
Building production, worker management, efficiency tracking

### Key Components

**Week 3: Building System**
- Building.lua - Production state machine
- Recipe management (inputs → outputs → time)
- Efficiency calculation (workers + satisfaction)
- Building cards UI with progress bars

**Week 4: Workforce Management**
- Worker assignment (free agency + manual)
- Vocation matching to building types
- Worker pool UI
- Global satisfaction slider (for testing)

**Week 5-6: Production Analytics**
- Output trend charts (last 50 cycles)
- Bottleneck detection (input shortage, worker shortage, inefficiency)
- Efficiency reports (actual vs theoretical)
- Inventory level tracking

### Success Criteria
✅ All 30+ buildings produce at correct rates  
✅ Production time affected by worker efficiency  
✅ Buildings block when inputs unavailable  
✅ Free agency assigns workers appropriately  
✅ Satisfaction slider measurably affects production  
✅ Bottleneck detection identifies real issues  

---

## 7. Integration & Merge Plan (Week 7-9)

### Week 7: Shared State Unification

**Create:**
- TownState.lua - Canonical state structure
- StateSerializer.lua - Save/load JSON
- IntegrationTests.lua - Cross-prototype validation

**Deliverables:**
- Both prototypes can save/load compatible state files
- State validation catches reference errors
- Can run Prototype 1 → save → load in Prototype 2 (and vice versa)

### Week 8-9: Three-Loop Implementation

**GameLoop.lua:**

```lua
function GameLoop:RunCycle()
    -- PHASE 1: PRODUCTION
    ProductionSystem:ProduceAll(townState, cycleTime)
    
    -- PHASE 2: ALLOCATION & CONSUMPTION
    AllocationSystem:RunCycle(townState)
    
    -- PHASE 3: CONSEQUENCES
    ConsequenceSystem:Evaluate(townState)
    
    -- FEEDBACK LOOP
    UpdateProductionEfficiency(townState)
end
```

**Critical Connection: Feedback Loop**
```
Character Satisfaction 
    ↓
Worker Productivity
    ↓
Building Efficiency
    ↓
Production Output
    ↓
Town Inventory
    ↓
Allocation Success
    ↓
Character Satisfaction (cycle completes)
```

### Integration Success Criteria
✅ 100 characters + 30 buildings run 100 cycles stably  
✅ Feedback loop creates observable effects  
✅ Can reach equilibrium states  
✅ Save/load works mid-game  
✅ No crashes or memory leaks  

---

## 8. Timeline & Milestones

### 12-Week Breakdown

```
Week 1-2:  Information System Foundation
Week 3-6:  Parallel Prototypes (Consumption + Production)
Week 7-9:  Integration & Three-Loop Implementation
Week 10-12: Geography, Immigration, Final Features
```

### Detailed Schedule

**PHASE 0: Foundation (Week 1-2)**
- Day 1-2: Data structure design
- Day 3-4: Commodity data (120 items)
- Day 5: Character classes & traits
- Week 2: Building recipes & system rules

**PHASE 1: Parallel Development (Week 3-6)**

Developer A (Prototype 1):
- Week 3: Character System
- Week 4: Allocation System
- Week 5: Consequence System
- Week 6: Analytics & Testing

Developer B (Prototype 2):
- Week 3: Building System
- Week 4: Workforce Management
- Week 5-6: Production Analytics

**PHASE 2: Integration (Week 7-9)**
- Week 7: State unification & serialization
- Week 8: Three-loop implementation
- Week 9: Final testing & optimization

**PHASE 3: Final Features (Week 10-12)**
- Week 10: Geography & spatial systems
- Week 11: Immigration & population dynamics
- Week 12: Polish & special features

---

## 9. Team Structure & Responsibilities

### 2-Developer Team Structure

```
Week 1-2: COLLABORATIVE
├─ Both developers + Designer
├─ Shared data structure design
└─ Collective ownership of schemas

Week 3-6: PARALLEL
├─ Developer A: Prototype 1 (Consumption)
└─ Developer B: Prototype 2 (Production)

Week 7-9: COLLABORATIVE
├─ Pair programming on GameLoop
├─ Cross-testing each other's code
└─ Collaborative debugging

Week 10-12: PARALLEL
├─ Developer A: Geography systems
└─ Developer B: Immigration & events
```

### Communication Protocols

**Daily (15 min):**
- What completed yesterday?
- What working on today?
- Any blockers?

**Weekly (1 hour):**
- Demo progress
- Review state compatibility
- Update risk register

**Bi-weekly (2 hours):**
- Cross-load state files
- Integration testing
- Plan merge strategy

---

## 10. Risk Management

### Top 5 Risks & Mitigation

**1. Data Schema Evolution** (High Impact, Medium Probability)
- **Mitigation:** Freeze schema after Week 2, versioned migrations for changes
- **Contingency:** 1-week pause to update both prototypes if major change needed

**2. Integration Complexity** (Critical Impact, High Probability)
- **Mitigation:** Define contract Week 2, weekly cross-loading, 3-week buffer
- **Contingency:** Cut final features if integration >3 weeks

**3. Performance Degradation** (Medium Impact, Medium Probability)
- **Mitigation:** Weekly profiling, 60 FPS target, spatial indexing
- **Contingency:** Reduce scope (50 chars, 15 buildings max)

**4. Free Agency Mismatch** (Medium Impact, High Probability)
- **Mitigation:** Shared JSON definition, unit tests, cross-validation
- **Contingency:** One implementation becomes canonical

**5. Balancing Iteration** (Low Impact, Very High Probability)
- **Mitigation:** All parameters in JSON, CSV export, designer access
- **Contingency:** Ongoing post-Week 12 (not blocking)

---

## 11. Success Metrics

### Prototype 1 Success
✅ 100 characters × 100 cycles stable  
✅ All 7 craving types working  
✅ Priority allocation correct  
✅ Substitution functional  
✅ Emigration/riots trigger  

### Prototype 2 Success
✅ 30+ buildings producing  
✅ Efficiency affects production time  
✅ Blockage detection works  
✅ Free agency assigns appropriately  
✅ Analytics show patterns  

### Integration Success
✅ 100 chars + 30 buildings × 100 cycles  
✅ Feedback loop observable  
✅ Equilibrium achievable  
✅ Save/load functional  
✅ 60 FPS maintained  

### Final Game Success
✅ All systems with geography  
✅ Immigration/emigration dynamic  
✅ Weather/events functional  
✅ No game-breaking bugs  
✅ Tutorial/onboarding complete  

---

## 12. Next Steps & Questions

### Immediate Actions (This Week)

**Team Decision Points:**
1. **JSON vs SQLite?** → Start JSON, migrate Week 7
2. **2 or 3 developers?** → Determines parallel capacity
3. **Which developer takes which prototype?** → Match skills to requirements
4. **Designer availability?** → Impacts data structure design in Week 1-2

**Week 1 Kickoff Tasks:**
- Set up Git repository with branch structure
- Create project documentation folder
- Schedule daily standups (15 min, same time)
- Assign data structure ownership (who owns which JSON files)

### Open Questions for Discussion

**Technical:**
- What game engine/framework? (LÖVE, Unity, Godot, custom?)
- Performance targets for final game? (100 chars? 200 chars?)
- Save file format? (JSON human-readable vs binary compact?)

**Design:**
- How many commodity types realistically needed? (120 or scale down?)
- Quality tier implementation? (Hard-coded or dynamic based on rarity?)
- Immigration rate formula? (Linear with happiness or threshold-based?)

**Process:**
- Code review process details? (All PRs reviewed or only critical paths?)
- Testing framework? (Unit tests required? Integration tests only?)
- Documentation standards? (Inline comments? Separate docs?)

### Resources Needed

**Development:**
- 2 Developer seats (full-time, 12 weeks)
- 1 Designer (part-time, 4-6 hours/week)
- Git hosting (GitHub/GitLab)
- Project management tool (Jira/Trello/Linear)

**Tools:**
- Code editor/IDE licenses
- Asset creation tools (if visual prototype needed)
- Analytics/monitoring tools (for performance profiling)

**Deliverables Checklist:**
- [ ] Information System (Week 2)
- [ ] Prototype 1 Demo (Week 6)
- [ ] Prototype 2 Demo (Week 6)
- [ ] Integrated Game Loop (Week 9)
- [ ] Final Game with All Features (Week 12)
- [ ] Documentation Package (Week 12)
- [ ] Balance Configuration Files (Week 12)

---

## Appendix: Technical Deep Dives

### A. Example Character Data Structure

```lua
Character = {
    id = "char_001",
    name = "John Smith",
    class = "Middle",
    vocation = "Baker",
    traits = {"Ambitious", "Frugal"},
    
    satisfaction = {
        biological = 65,
        touch = 45,
        psychological = 30,
        safety = 50,
        socialStatus = 20,
        exoticGoods = 10,
        shinyObjects = 15
    },
    
    personalInventory = {
        wheat = 5,
        bread = 2,
        simple_clothes = 1
    },
    
    employment = {
        building = "bakery_01",
        wage = 10,
        productivity = 1.1
    },
    
    residence = {
        building = "home_03",
        quality = "Home"
    }
}
```

### B. Example Building Data Structure

```lua
Building = {
    id = "bakery_01",
    type = "Bakery",
    
    recipe = {
        inputs = { wheat = 2, water = 1 },
        outputs = { bread = 5 },
        productionTime = 60
    },
    
    workforce = {
        assigned = {"char_001", "char_045"},
        required = 2,
        bonus = 0.15
    },
    
    state = "PRODUCING",
    productionProgress = 68,
    efficiency = 1.45
}
```

### C. Example Commodity Definition

```json
{
  "wheat": {
    "id": "wheat",
    "name": "Wheat",
    "category": "grain",
    "cravingTypes": {
      "biological": 8
    },
    "qualityTiers": {
      "poor": { "satisfactionMultiplier": 0.5 },
      "basic": { "satisfactionMultiplier": 1.0 },
      "good": { "satisfactionMultiplier": 1.5 },
      "luxury": { "satisfactionMultiplier": 2.0 }
    },
    "substitutions": [
      { "commodity": "rice", "efficiency": 0.95 },
      { "commodity": "barley", "efficiency": 0.80 }
    ]
  }
}
```

---

## Conclusion

This parallel prototyping approach offers:

✅ **Speed** - 2 developers work simultaneously  
✅ **Safety** - Each system validated independently  
✅ **Flexibility** - Data-driven design enables rapid iteration  
✅ **Quality** - Integration risks identified and mitigated early  

**The key to success:** Define data structures Week 1-2, maintain clear integration contracts, and test cross-compatibility weekly.

**Ready to build Cravetown!**

---

**Questions?**
