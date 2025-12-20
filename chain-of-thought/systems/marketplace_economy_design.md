# CraveTown Marketplace Economy Design

**Created:** 2025-12-01
**Status:** Design Phase

---

## Executive Summary

Transform CraveTown from a pure allocation-based distribution system to a **hybrid market economy** where characters act as free agents with wealth, making purchasing decisions based on their cravings, income, and available resources. The town acts as a regulator, setting price bounds and optionally controlling specific commodities through traditional allocation.

---

## Part A: Game Design Perspective

### 1. Core Philosophy

**Current System (Allocation):**
- Town receives resources → Algorithm distributes to characters based on need/priority
- Characters are passive recipients
- No concept of money or purchasing power

**Proposed System (Market + Optional Allocation):**
- Town receives resources → Resources enter marketplace with prices
- Characters actively purchase based on cravings + wealth + prices
- Wealth creates stratification and emergent behavior
- Town can regulate prices and allocate specific "essential" commodities

### 2. Character Wealth System

#### 2.1 Starting Wealth (by Class)

| Class | Starting Wealth | Rationale |
|-------|----------------|-----------|
| Elite | 5000-10000 | Inherited wealth, property |
| Upper | 2000-4000 | Professional savings |
| Middle | 500-1500 | Modest savings |
| Working | 100-400 | Limited savings |
| Poor | 0-100 | Living paycheck to paycheck |

#### 2.2 Income Sources

**Primary: Vocation-Based Income**
- Each vocation has a base income per cycle
- Income modified by:
  - Character productivity (satisfaction-based)
  - Economic conditions (town prosperity)
  - Class multiplier (same job pays different by class due to connections)

**Example Vocation Incomes:**
| Vocation | Base Income/Cycle | Notes |
|----------|-------------------|-------|
| Merchant | 50-100 | Variable based on trade |
| Craftsman | 30-50 | Steady |
| Farmer | 20-40 | Seasonal variation possible |
| Laborer | 15-25 | Low but stable |
| Scholar | 40-60 | Requires education infrastructure |
| Entertainer | 20-80 | High variance |

**Secondary: Wealth Growth**
- Interest on savings (small %, encourages hoarding)
- Property ownership (passive income from housing)
- Investments (future feature)

#### 2.3 Wealth Depletion

- Purchasing commodities
- Housing costs (rent or mortgage)
- Taxes (if implemented)
- Emergency expenses (random events)

### 3. Market Mechanics

#### 3.1 Price Discovery

**Option A: Simple Supply/Demand Curve**
```
Price = BasePrice * (1 + DemandPressure - SupplyPressure)

DemandPressure = (TotalCravings / Population) * DemandSensitivity
SupplyPressure = (Inventory / OptimalInventory) * SupplySensitivity
```

**Option B: Auction-Based (More Complex)**
- Characters submit bids based on willingness to pay
- Market clears at equilibrium price
- More realistic but computationally expensive

**Recommended: Option A** for initial implementation with configurable sensitivity parameters.

#### 3.2 Price Bounds (Town Regulation)

| Control Type | Description | Use Case |
|--------------|-------------|----------|
| Price Floor | Minimum price (protects producers) | Agriculture, basic crafts |
| Price Ceiling | Maximum price (protects consumers) | Essential foods, medicine |
| Fixed Price | State-controlled pricing | Utilities, basic housing |
| Free Market | No bounds | Luxury goods, exotic items |

#### 3.3 Commodity Categories by Market Type

| Category | Default Mode | Rationale |
|----------|--------------|-----------|
| Basic Food (bread, water) | Price Ceiling | Prevent starvation |
| Medicine | Price Ceiling | Health is fundamental |
| Luxury Food (wine, exotic) | Free Market | Non-essential |
| Clothing (basic) | Price Ceiling | Dignity/survival |
| Clothing (fashion) | Free Market | Status symbol |
| Housing | Mixed (rent ceiling) | Complex - see below |
| Tools/Crafts | Free Market | Economic goods |
| Entertainment | Free Market | Pure luxury |
| Vice (alcohol, tobacco) | Free Market + Tax | Sin tax opportunity |

### 4. Character Purchase Behavior

#### 4.1 Decision-Making Algorithm

```
For each cycle:
1. Calculate available budget = Wealth * SpendingWillingness
2. Identify unmet cravings, sorted by intensity
3. For each craving:
   a. Find commodities that fulfill this craving
   b. Calculate utility = (CravingReduction / Price) * QualityPreference
   c. If affordable and utility > threshold, add to purchase list
4. Execute purchases in priority order until budget exhausted
```

#### 4.2 Spending Willingness by Class

| Class | Spending Willingness | Savings Rate |
|-------|---------------------|--------------|
| Elite | 20-30% per cycle | High savings |
| Upper | 30-40% per cycle | Moderate savings |
| Middle | 40-60% per cycle | Some savings |
| Working | 60-80% per cycle | Little savings |
| Poor | 80-100% per cycle | No savings |

#### 4.3 Quality Preferences

- **Elite**: Strongly prefer luxury/masterwork, reject basic
- **Upper**: Prefer quality, accept basic reluctantly
- **Middle**: Accept all qualities, slight preference for better
- **Working**: Prioritize affordability over quality
- **Poor**: Buy cheapest available, any quality

### 5. Hybrid System: Market + Allocation

#### 5.1 When to Use Allocation

| Scenario | Use Allocation |
|----------|----------------|
| Emergency (famine, disaster) | Yes - ensure survival |
| Essential commodities | Optional - price ceiling may suffice |
| Wealth inequality crisis | Yes - prevent social collapse |
| Player choice | Yes - policy lever |

#### 5.2 Allocation Pool

Town can designate % of incoming resources to:
- **Market Pool**: Sold at market prices
- **Allocation Pool**: Distributed by need (existing algorithm)
- **Reserve Pool**: Held for emergencies

### 6. Economic Feedback Loops

#### 6.1 Positive Loops (Wealth Concentration)
- Rich buy quality goods → Higher satisfaction → Higher productivity → More income
- **Mitigation**: Progressive taxation, price ceilings, allocation for essentials

#### 6.2 Negative Loops (Death Spirals)
- Poor can't afford food → Low satisfaction → Low productivity → Less income → Can't afford food
- **Mitigation**:
  - Welfare system (basic allocation for those below poverty line)
  - Minimum wage
  - Price subsidies for essentials

#### 6.3 Market Stabilizers
- **Automatic**: Supply/demand naturally corrects over time
- **Policy**: Price controls, allocation pools, taxation
- **Events**: Market interventions, stimulus packages

### 7. Emergent Gameplay

#### 7.1 Player Decisions
- Set price bounds for commodities
- Allocate vs market ratio
- Tax rates (affects wealth distribution)
- Welfare thresholds
- Trade policies (future: import/export)

#### 7.2 Observable Outcomes
- Wealth inequality (Gini coefficient)
- Market prices fluctuation
- Class mobility (characters moving between classes)
- Satisfaction by wealth bracket
- Economic growth/contraction

#### 7.3 Interesting Scenarios
- **Scarcity**: Prices spike, poor suffer, riots increase
- **Abundance**: Prices drop, producers suffer, economic shift
- **Monopoly**: One commodity dominates, policy intervention needed
- **Innovation**: New commodities disrupt market

### 8. Game Balance Considerations

#### 8.1 Tuning Parameters
| Parameter | Effect | Starting Value |
|-----------|--------|----------------|
| DemandSensitivity | Price volatility | 0.5 |
| SupplySensitivity | Price stability | 0.5 |
| WealthDecayRate | Prevents infinite accumulation | 1%/cycle |
| WelfareThreshold | When allocation kicks in | Wealth < 50 |
| PriceCeilingMultiplier | Max above base price | 2.0x |
| PriceFloorMultiplier | Min below base price | 0.5x |

#### 8.2 Risk Mitigation
- **Save-scumming**: Prices have some randomness
- **Min-maxing**: Multiple valid strategies
- **Runaway states**: Hard limits on prices, mandatory welfare

---

## Part B: Technical & Performance Perspective

### 1. Data Structures

#### 1.1 Character Wealth Extension

```lua
-- Add to CharacterV2
character.wealth = {
    current = 0,           -- Current liquid wealth
    income = 0,            -- Last cycle's income
    expenses = 0,          -- Last cycle's expenses
    savingsRate = 0.2,     -- Target savings rate
    purchaseHistory = {},  -- Recent purchases for analytics
}

character.housing = {
    type = "none",         -- none/rent/own
    cost = 0,              -- Per cycle cost
    quality = "basic",     -- Affects satisfaction
}
```

#### 1.2 Market Data Structures

```lua
-- New: MarketSystem.lua
Market = {
    commodities = {},      -- {id: CommodityMarketData}
    priceHistory = {},     -- For trends
    transactionLog = {},   -- For analytics
    config = {
        demandSensitivity = 0.5,
        supplySensitivity = 0.5,
        maxPriceHistory = 20,
    }
}

CommodityMarketData = {
    id = "bread",
    basePrice = 10,
    currentPrice = 10,
    priceFloor = 5,        -- nil for no floor
    priceCeiling = 20,     -- nil for no ceiling
    marketMode = "market", -- "market", "allocated", "mixed"
    allocationRatio = 0,   -- % to allocation pool
    inventory = 0,         -- Available in market
    demandLastCycle = 0,   -- Tracking
    supplyLastCycle = 0,   -- Tracking
}
```

#### 1.3 Transaction Record

```lua
Transaction = {
    cycle = 0,
    buyer = "char_id",
    commodity = "bread",
    quantity = 1,
    price = 10,
    totalCost = 10,
}
```

### 2. Performance Analysis

#### 2.1 Per-Cycle Operations

| Operation | Complexity | Notes |
|-----------|------------|-------|
| Price Calculation | O(C) | C = commodities |
| Character Purchase Decisions | O(N * C) | N = characters |
| Transaction Processing | O(N * P) | P = purchases per char |
| Market Clearing | O(C) | Update inventories |
| Statistics Update | O(N) | Wealth, satisfaction |

**Total**: O(N * C) per cycle

#### 2.2 Scalability Estimates

| Characters | Commodities | Operations/Cycle | Acceptable? |
|------------|-------------|------------------|-------------|
| 50 | 100 | 5,000 | Yes |
| 100 | 100 | 10,000 | Yes |
| 500 | 100 | 50,000 | Yes |
| 1000 | 200 | 200,000 | Marginal |

**Recommendation**: Optimize for up to 500 characters initially.

#### 2.3 Optimization Strategies

**1. Batch Processing**
```lua
-- Instead of per-character, per-commodity
-- Group by commodity, process all buyers at once
function Market:ProcessCommodityBuyers(commodityId)
    local buyers = self:GetInterestedBuyers(commodityId)
    table.sort(buyers, function(a, b) return a.bid > b.bid end)
    -- Process in order until supply exhausted
end
```

**2. Caching**
- Cache commodity-to-craving mappings (already in CommodityCache)
- Cache price calculations (only recalculate when supply/demand changes)
- Cache character purchase preferences (only recalculate on satisfaction change)

**3. Lazy Evaluation**
- Only calculate prices for commodities with non-zero inventory
- Only evaluate purchase decisions for characters with wealth > 0

**4. Parallel Processing (Future)**
- Character decisions are independent → Can parallelize
- LÖVE2D is single-threaded, but can use coroutines for spreading work

### 3. Integration with Existing Systems

#### 3.1 Craving → Purchase Mapping

```lua
-- Existing: CommodityCache provides fulfillment vectors
-- New: Add price-aware utility calculation

function Character:CalculatePurchaseUtility(commodity, price)
    local fulfillment = CommodityCache:GetFulfillmentFor(commodity)
    local cravingReduction = self:EstimateCravingReduction(fulfillment)
    local qualityFit = self:GetQualityPreference(commodity.quality)

    -- Utility = how much satisfaction per gold spent
    return (cravingReduction * qualityFit) / price
end
```

#### 3.2 Satisfaction System (Unchanged Core)

- Characters still have 49D cravings and 9D satisfaction
- Purchasing commodities still reduces cravings via FulfillmentVectors
- Only change: commodities acquired via purchase, not allocation

#### 3.3 Consequences System (Adapted)

| Consequence | Trigger (Current) | Trigger (Market) |
|-------------|-------------------|------------------|
| Protest | Low satisfaction + failed allocations | Low satisfaction + can't afford needs |
| Emigration | Prolonged low satisfaction | Prolonged low satisfaction OR bankruptcy |
| Riot | Mass dissatisfaction | Mass dissatisfaction OR wealth inequality |

### 4. New Module Structure

```
code/
  economy/
    MarketSystem.lua       -- Core market mechanics
    PriceCalculator.lua    -- Price discovery algorithms
    TransactionProcessor.lua -- Execute purchases
    WealthManager.lua      -- Character income/expenses
    MarketAnalytics.lua    -- Track metrics, history
    MarketConfig.lua       -- Tuning parameters
```

### 5. Memory Footprint

#### 5.1 Per-Character Addition
| Field | Size | Notes |
|-------|------|-------|
| wealth.current | 8 bytes | number |
| wealth.income | 8 bytes | number |
| wealth.expenses | 8 bytes | number |
| purchaseHistory (10) | ~200 bytes | Last 10 purchases |
| housing | ~50 bytes | Struct |
| **Total** | ~275 bytes | Per character |

#### 5.2 Market System
| Data | Size | Notes |
|------|------|-------|
| CommodityMarketData * 200 | ~40 KB | All commodities |
| PriceHistory (20 cycles * 200) | ~32 KB | History tracking |
| TransactionLog (1000 recent) | ~50 KB | Analytics |
| **Total** | ~125 KB | Market overhead |

**Conclusion**: Memory impact is minimal.

### 6. Implementation Phases

#### Phase 1: Core Market (MVP)
- [ ] Character wealth field
- [ ] Basic income per cycle
- [ ] Simple price calculation
- [ ] Purchase decisions (greedy algorithm)
- [ ] Market UI in prototype

#### Phase 2: Price Controls
- [ ] Price floors/ceilings
- [ ] Market vs allocation mode per commodity
- [ ] Policy UI panel

#### Phase 3: Advanced Behavior
- [ ] Sophisticated purchase AI
- [ ] Savings behavior
- [ ] Housing system
- [ ] Wealth inequality metrics

#### Phase 4: Economic Events
- [ ] Market shocks
- [ ] Inflation/deflation
- [ ] Economic crises
- [ ] Policy interventions

---

## Part C: Risks & Mitigations

### Technical Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Performance degradation | Slow gameplay | Batch processing, caching |
| Economic instability | Unplayable states | Hard limits, auto-stabilizers |
| Complexity overload | Confusing UX | Gradual reveal, good defaults |
| Balance issues | Unfun gameplay | Extensive tuning parameters |

### Design Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Death spirals | Mass emigration | Welfare system, safety nets |
| Wealth hoarding | Stagnant economy | Wealth decay, taxation |
| Price volatility | Unpredictable gameplay | Smoothing, bounds |
| Analysis paralysis | Player overwhelmed | Good defaults, presets |

---

## Part D: Open Questions

1. **Housing System**: How deep? Simple rent vs complex property ownership?
2. **Taxation**: Implement now or defer? Flat vs progressive?
3. **Trade**: External trade with other towns (future feature)?
4. **Banking**: Loans, interest, debt? Adds depth but complexity.
5. **Currency**: Single currency or barter system option?
6. **Inheritance**: When characters die, where does wealth go?
7. **Starting State**: New game starts with what market conditions?

---

## Recommendation

**Start with Phase 1 (Core Market)** as a prototype within the Consumption Prototype:
1. Add wealth to characters
2. Add simple vocation-based income
3. Implement basic supply/demand pricing
4. Create purchase behavior (greedy, craving-priority)
5. Add "Market Mode" toggle (market vs allocation)
6. Add market panel to Analytics

This gives us a testable MVP to validate the design before committing to the full system.

---

## Appendix: Price Formula Details

### Supply/Demand Price Calculation

```lua
function Market:CalculatePrice(commodityId)
    local data = self.commodities[commodityId]
    local base = data.basePrice

    -- Demand pressure: high cravings = higher prices
    local totalDemand = self:CalculateTotalDemand(commodityId)
    local population = #self.characters
    local normalizedDemand = totalDemand / (population * 10)  -- 10 = expected avg craving
    local demandPressure = normalizedDemand * self.config.demandSensitivity

    -- Supply pressure: high inventory = lower prices
    local inventory = data.inventory
    local optimalInventory = population * 2  -- 2 units per person
    local normalizedSupply = inventory / optimalInventory
    local supplyPressure = normalizedSupply * self.config.supplySensitivity

    -- Calculate price
    local multiplier = 1 + demandPressure - supplyPressure
    multiplier = math.max(0.1, math.min(10, multiplier))  -- Clamp to 0.1x - 10x

    local price = base * multiplier

    -- Apply bounds
    if data.priceFloor then price = math.max(price, data.priceFloor) end
    if data.priceCeiling then price = math.min(price, data.priceCeiling) end

    return price
end
```

### Character Purchase Decision

```lua
function Character:DecidePurchases(market, budget)
    local purchases = {}
    local remaining = budget

    -- Get commodities sorted by utility
    local options = {}
    for id, data in pairs(market.commodities) do
        if data.inventory > 0 and data.marketMode ~= "allocated" then
            local utility = self:CalculatePurchaseUtility(id, data.currentPrice)
            if utility > 0 then
                table.insert(options, {
                    id = id,
                    price = data.currentPrice,
                    utility = utility
                })
            end
        end
    end

    table.sort(options, function(a, b) return a.utility > b.utility end)

    -- Greedy purchase
    for _, option in ipairs(options) do
        if remaining >= option.price then
            local qty = math.floor(remaining / option.price)
            qty = math.min(qty, market.commodities[option.id].inventory)
            if qty > 0 then
                table.insert(purchases, {
                    commodity = option.id,
                    quantity = qty,
                    price = option.price
                })
                remaining = remaining - (qty * option.price)
            end
        end
    end

    return purchases
end
```
