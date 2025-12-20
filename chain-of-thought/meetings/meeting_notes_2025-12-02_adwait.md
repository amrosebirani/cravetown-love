# Meeting Notes: Adwait Discussion
**Date:** 2025-12-02
**Participants:** Amrose, Adwait
**Status:** Ideas & Exploration

---

## Executive Summary

Wide-ranging discussion covering marketing strategy, economic models, mathematical simplification, trade foundations, demographic factors, environmental systems, governance models, and extensibility. Key themes: moving from "communist allocation" to market-based models, establishing foundations for trade, and making the simulation more realistic with time-based cravings and demographic factors.

---

## 1. Caricature Towns - Marketing Strategy

### Idea Origin
From Saransh - create caricature representations of real-world cities.

### Concept
Map the craving ecosystem from real cities into game towns:
- **Bengaluru** - Tech hub, high exotic_goods cravings, work-life balance issues
- **Mumbai** - Financial center, high social_status, density stress
- **Tokyo** - Precision culture, high safety/order, unique vice patterns
- **Paris** - Art/culture, high psychological_beauty, food sophistication
- **Madrid** - Social warmth, high social_connection, leisure-oriented

### Marketing Angle
- Organic adoption through cultural recognition
- Players see their city represented (even if exaggerated)
- Social sharing: "Look how they portrayed Mumbai!"
- Local influencer engagement potential
- Expandable to more cities based on demand

### Implementation Considerations
```
Per-city configuration:
- Base craving distributions (what do residents want?)
- Available commodities (local specialties)
- Class distribution (economic structure)
- Trait frequencies (cultural tendencies)
- Starting satisfaction ranges
- Unique events/consequences
```

### Open Questions
- [ ] How caricatured vs. realistic? (Satire risk)
- [ ] Research methodology for city profiles
- [ ] Legal/cultural sensitivity review needed
- [ ] Which cities first? (Market size vs. ease of modeling)

---

## 2. Economic Models: Communist → Market Transition

### Current State: "Communist Allocation"
```
Current model:
- Central allocation engine distributes resources
- Priority based on need + class weight
- No currency, no prices, no ownership negotiation
- Town inventory is communal pool
```

### Proposed: Market/Free-Agency Model
```
Market model:
- Characters have income/wealth
- Internal town market with prices
- Characters purchase based on budget + preference
- Prices fluctuate based on supply/demand
- Wealth accumulation possible
```

### Hybrid Approaches
```
Option A: Tiered System
- Basic needs (biological, safety) → guaranteed allocation
- Luxury needs (status, exotic) → market purchase

Option B: Voucher System
- Characters receive vouchers/credits per cycle
- Spend vouchers in prioritized order
- Unused vouchers accumulate (savings)

Option C: Mixed Economy
- Some commodities state-allocated (healthcare, housing)
- Others market-traded (luxury goods, vice)
- Tax system redistributes wealth

Option D: Full Market with Safety Net
- Everything market-based
- But minimum consumption guaranteed for lower classes
- Funded by taxation of upper classes
```

### Implementation Complexity
| Model | Complexity | New Systems Needed |
|-------|------------|-------------------|
| Current (Communist) | Low | None (current) |
| Voucher System | Medium | Currency, savings |
| Mixed Economy | High | Prices, taxes, market |
| Full Market | Very High | All above + bankruptcy, loans |

### Research Questions
- [ ] How do prices emerge from supply/demand?
- [ ] What happens when characters can't afford basics?
- [ ] How does wealth inequality affect town stability?
- [ ] Can we model inflation/deflation?

---

## 3. Commodity × Character Matrix

### Concept
A matrix showing relationship between each commodity and each character.

### Potential Uses

**Use 1: Preference Mapping**
```
         Wheat  Wine  Gold  Bed   Book
Alice    0.8    0.2   0.5   1.0   0.9
Bob      1.0    0.7   0.3   0.8   0.2
Carol    0.6    0.9   0.8   0.7   0.4

Values = preference strength or cumulative consumption
```

**Use 2: Fatigue State**
```
         Wheat  Wine  Gold  Bed   Book
Alice    0.25   1.0   0.8   0.95  0.6
Bob      0.5    0.4   1.0   0.9   1.0

Values = current fatigue multiplier
```

**Use 3: Ownership (for durables)**
```
         Bed   Chair  House  Tools
Alice    1     2      1      0
Bob      1     1      0      3
Carol    0     1      1      1

Values = quantity owned
```

**Use 4: Consumption History**
```
         Wheat  Wine  Gold  Bed
Alice    45     12    3     1
Bob      30     25    0     1

Values = total consumed this session
```

### Analytical Value
- Identify consumption patterns
- Detect inequality (some have everything, others nothing)
- Balance commodity design (is anything never consumed?)
- Feed into AI decision-making

### Visualization Ideas
- Heatmap in UI
- Cluster analysis (similar consumption patterns)
- Time-series animation

---

## 4. Mathematical Simplification: Markov Chains / HMMs

### Current Complexity
- 49 fine dimensions tracked per character
- Multiple interacting systems (fatigue, satisfaction, cravings)
- Exponential calculations, priority scoring
- Computationally intensive per cycle

### Markov Chain Application

**Concept:** Model character states as discrete states with transition probabilities.

```
States: {Satisfied, Neutral, Craving, Desperate, Protesting, Emigrating}

Transition Matrix P:
                Satisfied  Neutral  Craving  Desperate  Protesting  Emigrating
Satisfied       0.7        0.25     0.05     0          0           0
Neutral         0.2        0.5      0.25     0.05       0           0
Craving         0.1        0.3      0.4      0.15       0.05        0
Desperate       0.05       0.1      0.2      0.4        0.2         0.05
Protesting      0.1        0.2      0.2      0.2        0.25        0.05
Emigrating      0           0        0        0          0           1.0
```

**Benefits:**
- Simpler computation (matrix multiplication)
- Statistically predictable long-term behavior
- Easy to balance (adjust probabilities)
- Can pre-compute steady states

**Challenges:**
- Loses nuance of 49 dimensions
- Transition probabilities still need derivation from current formulas
- May feel less "alive" / more mechanical

### Hidden Markov Model Application

**Concept:** Observable outputs (consumption, protests) are emissions from hidden states (true satisfaction).

```
Hidden States: {Thriving, Stable, Struggling, Failing}
Observations: {Consumes_Luxury, Consumes_Basic, Protests, Emigrates, Idle}

Emission Probabilities:
              Luxury  Basic  Protest  Emigrate  Idle
Thriving      0.4     0.3    0.0      0.0       0.3
Stable        0.2     0.5    0.0      0.0       0.3
Struggling    0.05    0.6    0.2      0.05      0.1
Failing       0.0     0.3    0.4      0.2       0.1
```

**Use Case:** Player can't see true satisfaction (hidden), only observes behavior. Creates more realistic uncertainty.

### Recommendation
Consider a **hybrid approach**:
- Keep detailed simulation for core gameplay
- Use Markov approximation for:
  - Large population simulations (1000+ characters)
  - AI predictions ("what will happen if...")
  - Background/non-visible characters
  - Tutorial/educational mode

---

## 5. Trade Foundation: Exchange Surplus for Needs

### Current State
```
Production → Town Inventory → Consumption

All internal, no external trade
```

### Trade Foundation Concept
```
Town Production
      ↓
Town Consumption (satisfy local needs)
      ↓
Surplus Remaining
      ↓
Export for External Needs ←→ Import what we lack
```

### Key Insight
> "We have production, consumption, internal satisfaction. The remaining we can exchange for remaining needs/cravings."

### Trade Mechanics to Design

**Export Value Calculation:**
```
exportValue[commodity] = surplus[commodity] × qualityMultiplier × scarcityBonus

Where:
- surplus = production - consumption
- qualityMultiplier = based on commodity quality tier
- scarcityBonus = if this commodity rare globally
```

**Import Priority:**
```
importPriority[commodity] = unfulfilledCravings[commodity] × urgencyMultiplier

Where:
- unfulfilledCravings = demand we couldn't satisfy locally
- urgencyMultiplier = how critical (biological > luxury)
```

**Trade Balance:**
```
For each trade partner:
  ourExports = Σ(exportValue[c] × quantity[c])
  ourImports = Σ(importCost[c] × quantity[c])

  tradeBalance = ourExports - ourImports

  if tradeBalance < 0:
    Accumulate debt / reduce future imports
  if tradeBalance > 0:
    Accumulate credit / increase purchasing power
```

### Trade Partner Types
| Partner Type | Behavior |
|--------------|----------|
| Friendly Town | Fair prices, flexible terms |
| Neutral Town | Market prices, strict balance |
| Rival Town | Premium prices, may embargo |
| Caravan/Merchant | High markup, exotic goods |
| Empire/Overlord | Tribute required, protection offered |

### Prerequisites for Trade
- [ ] Surplus calculation (production - consumption)
- [ ] External demand signal (what do others want?)
- [ ] Pricing mechanism
- [ ] Trade route / transport cost
- [ ] Currency or barter equivalence

---

## 6. Demographic Factors: Age & Gender

### Age Multipliers

**Concept:** Craving intensities vary by life stage.

```
Age Brackets:
- Child (0-12): High biological, low status, no vice
- Teen (13-19): High social, high exotic, emerging vice
- Young Adult (20-35): Balanced, high ambition, peak consumption
- Middle Age (36-55): High comfort, moderate status, established patterns
- Elder (56+): High safety, high touch, declining biological needs

Example Multipliers (biological dimension):
Age Bracket    Multiplier
Child          1.3
Teen           1.1
Young Adult    1.0
Middle Age     0.9
Elder          0.8

Example Multipliers (vice dimension):
Age Bracket    Multiplier
Child          0.0
Teen           0.3
Young Adult    1.0
Middle Age     0.8
Elder          0.5
```

### Gender Factors

**Approach Considerations:**
- Biological differences (pregnancy, physical needs)
- Social role differences (culturally variable)
- Avoid stereotyping - make configurable per town/culture

```
Option A: No gender differences
- Simplest, avoids controversy
- Less realistic for historical simulations

Option B: Configurable per town culture
- Town metadata includes gender role settings
- Historical towns: traditional roles
- Modern towns: minimal differences

Option C: Individual variation
- Each character has personal modifiers
- Gender is one factor among many (like traits)
```

### Implementation Considerations
- [ ] Age progression over time?
- [ ] Birth/death mechanics?
- [ ] Family units and dependents?
- [ ] Cultural configuration for gender roles?

---

## 7. Environmental Factors: Weather & Disasters

### Weather System

**Weather States:**
```
States: {Clear, Cloudy, Rain, Storm, Snow, Heatwave, Drought}

Effects per state:
Clear:
  - productivity: 1.0
  - safety_craving: 0.9x
  - mood_bonus: +5 satisfaction

Storm:
  - productivity: 0.6
  - safety_craving: 1.5x
  - shelter_importance: critical
  - outdoor_work: suspended

Drought:
  - food_production: 0.5x
  - water_craving: 2.0x
  - fire_risk: elevated
```

**Seasonal Patterns:**
```
Spring: Growth season, moderate weather
Summer: Peak production, heatwave risk
Autumn: Harvest, preparation for winter
Winter: Scarcity, high safety/warmth cravings
```

### Natural Disasters

**Disaster Types:**
| Disaster | Probability | Duration | Effects |
|----------|-------------|----------|---------|
| Flood | Low | 3-5 cycles | Destroy crops, damage buildings |
| Earthquake | Very Low | 1 cycle | Structural damage, casualties |
| Plague | Low | 10-20 cycles | Productivity loss, deaths |
| Famine | Medium (after drought) | 5-15 cycles | Starvation, emigration |
| Fire | Medium | 1-3 cycles | Inventory destruction |

**Disaster Response:**
```
Pre-disaster:
  - Warning signs (if any)
  - Preparation opportunity

During disaster:
  - Immediate effects
  - Emergency allocation mode
  - Mutual aid vs. hoarding behavior

Post-disaster:
  - Recovery phase
  - Rebuilding needs
  - Long-term consequences (trauma, distrust)
```

### Weather × Location Interaction
Different caricature towns have different weather patterns:
- Mumbai: Monsoon season, flooding risk
- Tokyo: Earthquake risk, typhoons
- Madrid: Summer heatwaves, mild winters

---

## 8. Time-Based Craving Activation

### Current State
```
All 49 cravings active all the time
Cravings accumulate continuously
```

### Proposed: Circadian/Temporal Patterns

**Daily Cycle:**
```
Time of Day    Active Cravings
─────────────────────────────────────────
Morning        biological_nutrition (breakfast)
               psychological_stimulation (wake up)

Midday         biological_nutrition (lunch)
               social_connection (lunch socializing)

Afternoon      psychological (work fatigue)
               exotic_goods (afternoon slump → novelty seeking)

Evening        biological_nutrition (dinner)
               social_connection (family time)
               vice (after-work drinks)

Night          touch_comfort (rest)
               safety_shelter (security)
               psychological_peace (sleep quality)
```

**Implementation Options:**

**Option A: Multiplier by Time**
```lua
timeMultiplier[dimension][hour] = {
  biological_nutrition = {
    [6] = 1.5,   -- breakfast peak
    [12] = 1.5,  -- lunch peak
    [18] = 1.5,  -- dinner peak
    default = 0.3
  },
  safety_shelter = {
    [22] = 1.5,  -- night safety concerns
    [23] = 1.5,
    [0] = 1.5,
    default = 0.7
  }
}
```

**Option B: Activation Windows**
```lua
activationWindows[dimension] = {
  biological_nutrition = {{5,9}, {11,14}, {17,21}},
  safety_shelter = {{20,6}},  -- night hours
  vice = {{17,24}}  -- evening/night
}

-- Cravings only accumulate during active windows
```

**Option C: Urgency Curves**
```lua
-- Craving urgency follows curve throughout day
urgencyCurve[biological_nutrition] = function(hour)
  -- Peaks at meal times, low otherwise
  return gaussian_peak(hour, 7) + gaussian_peak(hour, 12) + gaussian_peak(hour, 19)
end
```

### Benefits
- More realistic behavior patterns
- Natural rhythm to town activity
- Strategic timing for events/disasters
- Day/night gameplay variation

### Challenges
- More complex craving math
- Need in-game clock system
- Balancing 24-hour cycle vs. real-time

---

## 9. Governance Models / Town Types

### Economic System Spectrum

```
Full Communist ◄─────────────────────────────────► Full Free Market
     │                    │                    │
     ▼                    ▼                    ▼
  Central            Mixed/Hybrid           Price
  Planning           Economies              Signals
```

### Model Definitions

**A. Communist / Central Planning**
```
Characteristics:
- State owns all means of production
- Central allocation based on "need"
- No private property for productive assets
- Equal distribution goal

Game Mechanics:
- Current allocation engine (need-based priority)
- No currency system
- No wealth accumulation
- Town manages all inventory

Consequences:
- Equality enforced
- Innovation suppressed (no incentive)
- Shortages possible (no price signals)
- Bureaucracy overhead
```

**B. Keynesian / Mixed Economy**
```
Characteristics:
- Private markets exist
- Government intervention during downturns
- Public goods provided (infrastructure, defense)
- Progressive taxation
- Counter-cyclical spending

Game Mechanics:
- Market for most goods
- Government "floor" for essential needs
- Taxation funds public services
- Stimulus during recessions

Consequences:
- Moderate inequality
- Boom/bust cycles possible
- Social safety net
- Debates over intervention level
```

**C. Capitalist Welfare State**
```
Characteristics:
- Free markets primary
- Strong social safety net
- Universal basic services (health, education)
- Funded by significant taxation

Game Mechanics:
- Full market pricing
- Universal basic income or services
- High tax rates on wealthy
- Public housing, healthcare

Consequences:
- Market efficiency + social protection
- High administrative overhead
- Possible disincentive effects
- Class mobility possible
```

**D. Pure Free Market**
```
Characteristics:
- Minimal government
- Price signals allocate everything
- Private property absolute
- No safety net

Game Mechanics:
- All commodities market-priced
- Characters accumulate wealth/debt
- Bankruptcy possible
- No guaranteed allocation

Consequences:
- Maximum efficiency (in theory)
- Extreme inequality
- Poverty → death/emigration
- Innovation incentivized
```

### Comparative Simulation Value
```
Running same town under different governance:
- Which maximizes total satisfaction?
- Which minimizes emigration?
- Which is most stable?
- Which handles disasters best?
- Which produces most innovation?
```

### Implementation Approach
```lua
GovernanceModel = {
  allocationMode = "central" | "market" | "hybrid",
  taxRate = 0.0 to 0.8,
  safetyNet = {
    enabled = true/false,
    coversDimensions = {"biological", "safety"},
    fundedBy = "taxation" | "charity" | "none"
  },
  priceDiscovery = {
    enabled = true/false,
    mechanism = "auction" | "posted" | "negotiated"
  },
  propertyRights = {
    durables = "private" | "communal",
    land = "private" | "state",
    productive = "private" | "worker-owned" | "state"
  }
}
```

---

## 10. Civilization Evolution: Immigration, Trade, Tax

### Big Picture Vision

```
Town Lifecycle:
┌─────────────────────────────────────────────────────────────────┐
│ FOUNDING                                                         │
│   └─► Initial population, resources, governance choice          │
├─────────────────────────────────────────────────────────────────┤
│ GROWTH                                                           │
│   └─► Immigration attracted by opportunity                      │
│   └─► Trade surplus enables specialization                      │
│   └─► Tax revenue funds infrastructure                          │
├─────────────────────────────────────────────────────────────────┤
│ MATURITY                                                         │
│   └─► Stable population with turnover                           │
│   └─► Established trade relationships                           │
│   └─► Complex governance structures                             │
├─────────────────────────────────────────────────────────────────┤
│ DECLINE OR TRANSFORMATION                                        │
│   └─► Resource depletion → adaptation needed                    │
│   └─► External threats → defense or diplomacy                   │
│   └─► Internal conflict → revolution or reform                  │
└─────────────────────────────────────────────────────────────────┘
```

### Immigration Mechanics

**Pull Factors (attract immigrants):**
- High average satisfaction
- Low inequality
- Available jobs (production capacity)
- Cultural reputation
- Safety/stability

**Push Factors (from other places):**
- War/disaster elsewhere
- Economic collapse
- Persecution

**Immigration Impact:**
```
Positive:
- Labor force growth
- Skill diversity
- Cultural enrichment
- Tax base expansion

Negative:
- Initial resource strain
- Cultural friction (if not managed)
- Wage pressure (for existing workers)
- Infrastructure strain
```

### Trade Evolution

```
Stage 1: Autarky
  - Self-sufficient
  - No trade
  - Limited variety

Stage 2: Barter
  - Direct exchange with neighbors
  - No currency
  - Limited by coincidence of wants

Stage 3: Currency Trade
  - Money as medium of exchange
  - Wider trade networks
  - Price discovery

Stage 4: Specialization
  - Comparative advantage
  - Export focus
  - Import dependence

Stage 5: Trade Alliances
  - Multi-town agreements
  - Preferential terms
  - Collective bargaining
```

### Taxation System

**Tax Types:**
| Tax Type | Base | Effect |
|----------|------|--------|
| Income Tax | Character earnings | Progressive revenue |
| Sales Tax | Transactions | Consumption-based |
| Property Tax | Durables/land owned | Wealth-based |
| Trade Tariff | Imports/exports | Protectionism |
| Luxury Tax | High-end goods | Inequality reduction |

**Tax Revenue Uses:**
- Public goods (infrastructure, defense)
- Safety net (welfare, healthcare)
- Emergency fund (disaster response)
- Investment (education, research)

---

## 11. Robert Axelrod's Tournament - Game Theory

### Background
Robert Axelrod's famous iterated Prisoner's Dilemma tournament showed that **Tit-for-Tat** (cooperate first, then mirror opponent's last move) was remarkably successful.

### Application to Cravetown

**Inter-Character Interactions:**
```
When characters can help/hurt each other:
- Share resources in scarcity?
- Report crimes/cheating?
- Cooperate on production?
- Form/break alliances?

Strategies:
- Always Cooperate (naive)
- Always Defect (exploitative)
- Tit-for-Tat (reciprocal)
- Generous Tit-for-Tat (forgiving)
- Random (unpredictable)
```

**Inter-Town Interactions:**
```
Trade relationships as repeated games:
- Honor agreements or cheat?
- Share information or deceive?
- Mutual defense or abandon?

Reputation system:
- Towns remember past behavior
- Cheaters get excluded
- Cooperators attract partners
```

**AI Character Strategies:**
```lua
CharacterStrategy = {
  id = "tit_for_tat",
  firstMove = "cooperate",
  memory = 3,  -- remember last N interactions

  decide = function(self, history, partner)
    if #history == 0 then
      return self.firstMove
    end
    -- Mirror partner's last action
    return history[#history].partnerAction
  end
}
```

### Tournament Mode (Gameplay Feature?)
- Pit different strategies against each other
- Evolve winning strategies over generations
- Educational demonstration of game theory

---

## 12. Scriptable System (Screeps-like)

### Concept
Allow players/modders to inject custom scripts that control aspects of the simulation.

### Inspiration: Screeps
Screeps is an MMO where players write JavaScript to control their units. Key lessons:
- Sandboxed execution environment
- API for reading game state
- API for issuing commands
- Rate limiting to prevent abuse

### Scriptable Surfaces in Cravetown

**A. Allocation Policy Scripts**
```lua
-- Custom allocation logic
function allocate(character, inventory, context)
  -- Player-defined priority
  if character.class == "Elite" and context.isEmergency then
    return nil  -- Elite don't get priority in emergencies
  end

  -- Custom commodity selection
  local preferred = character.traits.vegetarian
    and filterVegetarian(inventory)
    or inventory

  return selectBestMatch(character.cravings, preferred)
end
```

**B. Governance Policy Scripts**
```lua
-- Custom tax calculation
function calculateTax(character, earnings)
  local brackets = {
    {0, 100, 0.0},      -- No tax under 100
    {100, 500, 0.1},    -- 10% for 100-500
    {500, 1000, 0.2},   -- 20% for 500-1000
    {1000, nil, 0.35}   -- 35% above 1000
  }
  return applyBrackets(earnings, brackets)
end
```

**C. Event Response Scripts**
```lua
-- Custom disaster response
function onDisaster(disasterType, severity)
  if disasterType == "famine" then
    -- Implement rationing
    setAllocationMode("emergency")
    setClassPriority("Lower", 10)  -- Prioritize vulnerable
    suspendLuxuryAllocation()
  end
end
```

**D. Trade Strategy Scripts**
```lua
-- Custom trade logic
function evaluateTrade(offer, partner)
  local ourNeed = calculateNeed(offer.weGet)
  local ourSurplus = calculateSurplus(offer.weGive)
  local partnerReputation = getReputation(partner)

  if partnerReputation < 0.5 then
    return reject("Untrusted partner")
  end

  if ourNeed > ourSurplus * 1.2 then
    return accept()
  else
    return counter(modifyOffer(offer, 0.9))
  end
end
```

### Technical Implementation

**Sandboxing Options:**
- Lua sandbox (current codebase is Lua)
- WebAssembly for performance
- JavaScript with VM (like Screeps)

**API Design:**
```lua
CravetownAPI = {
  -- Read-only state access
  getCharacters = function() end,
  getInventory = function() end,
  getCycle = function() end,
  getWeather = function() end,

  -- Command execution
  setAllocationPolicy = function(policy) end,
  setTaxRate = function(rate) end,
  proposeTrade = function(partner, offer) end,

  -- Event subscription
  onCycleEnd = function(callback) end,
  onDisaster = function(callback) end,
  onEmigration = function(callback) end
}
```

**Safety Considerations:**
- CPU time limits per script
- Memory limits
- No file system access
- Rate limiting on commands
- Validation of all inputs

### Potential Uses
- AI research (evolve governance strategies)
- Education (teach economics through scripting)
- Competitive leagues (best-managed town wins)
- Modding community content

---

## Summary: Priority Ordering

Based on discussion, rough prioritization:

### Near-term (Foundation)
1. **Trade foundation** - Export surplus, import needs
2. **Market model exploration** - Move beyond pure communist allocation
3. **Time-based cravings** - Circadian rhythms

### Medium-term (Depth)
4. **Governance models** - Different town economic systems
5. **Demographics** - Age/gender factors
6. **Weather/disasters** - Environmental factors
7. **Commodity × Character matrix** - Analytics foundation

### Long-term (Expansion)
8. **Caricature towns** - Marketing/content strategy
9. **Scriptable system** - Extensibility
10. **Immigration/civilization** - Multi-town dynamics
11. **Axelrod tournament** - Game theory features
12. **Markov simplification** - Performance optimization

---

## Action Items

- [ ] Research market pricing mechanisms for games
- [ ] Prototype trade surplus calculation
- [ ] Design time-of-day craving multiplier system
- [ ] Create governance model configuration schema
- [ ] Evaluate Lua sandboxing libraries
- [ ] Draft caricature city profiles (start with 3)
- [ ] Review Axelrod's work for applicable concepts

---

## References

- Axelrod, Robert. "The Evolution of Cooperation" (1984)
- Screeps documentation: https://docs.screeps.com/
- Comparative economic systems literature
- Circadian rhythm research for craving patterns

---

*Document created: 2025-12-02*
*Next review: After trade foundation prototype*
