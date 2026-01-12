# CRAVE-19: Economy Flow Visualization - Implementation Document

**Linear Issue:** CRAVE-19 [O] Economy Flow Visualization
**Created:** 2026-01-11
**Status:** Planning Complete
**Branch:** `feat/tea-coffee-implementation`

---

## 1. Objective

Visualize how resources flow through the town economy via an enhanced Economy tab in the Debug Panel.

**Acceptance Criteria:**
- Can visualize any commodity's flow through Production → Inventory → Consumption
- Trends visible over time (last 10 time slots)
- Surplus/deficit indicators for each commodity

**Explicitly Out of Scope:**
- O6 (Gold flow tracking) - Gold/wage system not yet implemented

---

## 2. Architecture Context

### 2.1 Data Flow Pipeline

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  PRODUCTION │────▶│  INVENTORY  │────▶│ CONSUMPTION │
│  (Buildings)│     │   (Town)    │     │ (Citizens)  │
└─────────────┘     └─────────────┘     └─────────────┘
      │                   │                   │
      ▼                   ▼                   ▼
┌─────────────────────────────────────────────────────┐
│              ProductionStats.lua                     │
│  - recordProduction(commodityId, qty, buildingId)   │
│  - recordConsumption(commodityId, qty)              │
│  - recordStockpile(commodityId, qty)                │
│  - getProductionTrend(), getConsumptionTrend()      │
└─────────────────────────────────────────────────────┘
```

### 2.2 Key Data Sources

| Source | Location | Data Available |
|--------|----------|----------------|
| Production rates | `world.productionStats.metrics.productionRate` | commodity → units/min |
| Consumption rates | `world.productionStats.metrics.consumptionRate` | commodity → units/min |
| Net production | `world.productionStats.metrics.netProduction` | commodity → net change |
| Stockpiles | `world.inventory` | commodity → current qty |
| Historical data | `world.productionStats.history.*` | Ring buffers (200 samples) |
| Top producers | `world.productionStats.metrics.topProducers` | Top 5 commodities |

### 2.3 Time System Reference

| Concept | Value | Notes |
|---------|-------|-------|
| 1 Game Day | 300 real seconds (normal speed) | 6 time slots |
| 1 Time Slot | ~50 real seconds | 1 allocation cycle |
| 1 Cycle | 1 Time Slot | Used for trend tracking |
| "Last 10 cycles" | ~8.3 real minutes | ~1.7 game days |

---

## 3. Implementation Tasks

### Task Breakdown

| ID | Task | Priority | Complexity |
|----|------|----------|------------|
| O1 | Create Economy tab structure | High | Low |
| O2 | Implement Sankey-style flow diagram | High | High |
| O3 | Add commodity filter dropdown | Medium | Medium |
| O4 | Show surplus/deficit indicators | High | Medium |
| O5 | Add trend sparklines | Medium | Medium |

---

## 4. Detailed Design

### 4.1 Economy Tab Layout (O1)

```
┌─────────────────────────────────────────────────────────┐
│ ECONOMY FLOW VISUALIZATION                              │
├─────────────────────────────────────────────────────────┤
│ Filter: [Active (last 10 slots) ▼]                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐      │
│  │PRODUCTION│─────▶│INVENTORY │─────▶│CONSUMPTION│      │
│  │  247/min │      │  1,240   │      │  198/min │      │
│  └──────────┘      └──────────┘      └──────────┘      │
│                                                         │
│  [Sankey Flow Diagram Area - 200px height]             │
│                                                         │
├─────────────────────────────────────────────────────────┤
│ COMMODITY DETAILS                                       │
├─────────────────────────────────────────────────────────┤
│ Commodity      │ Prod  │ Cons  │ Stock │ Δ    │ Trend  │
│ ─────────────────────────────────────────────────────── │
│ ● wheat        │ 45/m  │ 32/m  │  120  │ +13  │ ▂▃▅▆▇ │
│ ● bread        │ 28/m  │ 41/m  │   45  │ -13  │ ▇▆▅▃▂ │
│ ● timber       │ 12/m  │  8/m  │  230  │  +4  │ ▃▃▄▄▅ │
│ ● cloth        │  6/m  │  9/m  │   18  │  -3  │ ▅▄▃▃▂ │
│ ...                                                     │
└─────────────────────────────────────────────────────────┘
```

### 4.2 Sankey Flow Diagram Design (O2)

**Simplified 3-Column Sankey:**

```
  PRODUCTION          INVENTORY         CONSUMPTION
  ┌────────┐                            ┌────────┐
  │ wheat  │════════╗     ╔═════════════│ wheat  │
  └────────┘        ║     ║             └────────┘
  ┌────────┐        ║     ║             ┌────────┐
  │ bread  │═══════╗║     ║╔════════════│ bread  │
  └────────┘       ║║     ║║            └────────┘
  ┌────────┐       ║║ ┌───╨╨───┐        ┌────────┐
  │ timber │══════╗║╚▶│       │◀╝╔══════│ timber │
  └────────┘      ║╚═▶│ STOCK │◀═╝      └────────┘
                  ╚══▶│ 1,240 │◀══╗
                      └───────┘   ║     ┌────────┐
                                  ╚═════│ cloth  │
                                        └────────┘
```

**Visual Rules:**
- Flow line width: `clamp(quantity / maxQuantity * 20, 2, 20)` pixels
- Colors by commodity category (biological=green, touch=blue, etc.)
- Production flows INTO inventory (left side)
- Consumption flows OUT OF inventory (right side)
- Inventory box size reflects total stockpile

**Implementation Approach:**
```lua
-- Sankey drawing pseudocode
function DrawSankeyFlow(x, y, width, height, commodityData)
    local leftCol = x + 60           -- Production column
    local midCol = x + width/2       -- Inventory column
    local rightCol = x + width - 60  -- Consumption column

    -- Draw inventory box (center)
    DrawInventoryBox(midCol, y, totalStock)

    -- Draw production flows (left to center)
    for commodity in productionData do
        local flowWidth = CalculateFlowWidth(commodity.rate)
        local color = GetCategoryColor(commodity.category)
        DrawBezierFlow(leftCol, prodY, midCol, invY, flowWidth, color)
    end

    -- Draw consumption flows (center to right)
    for commodity in consumptionData do
        local flowWidth = CalculateFlowWidth(commodity.rate)
        local color = GetCategoryColor(commodity.category)
        DrawBezierFlow(midCol, invY, rightCol, consY, flowWidth, color)
    end
end
```

### 4.3 Commodity Filter (O3)

**Filter Options:**
1. **Active (last 10 slots)** - Default. Shows commodities with any production OR consumption in last 10 cycles
2. **Top 20 by volume** - Sorted by `production_rate + consumption_rate`
3. **All commodities** - Full list with scrolling

**Data Structure:**
```lua
EconomyTab.filterOptions = {
    {id = "active", label = "Active (last 10 slots)"},
    {id = "top20", label = "Top 20 by volume"},
    {id = "all", label = "All commodities"}
}
EconomyTab.currentFilter = "active"
```

**Filter Logic:**
```lua
function GetFilteredCommodities(filter, productionStats)
    if filter == "active" then
        -- Return commodities with recent activity
        local active = {}
        for commodityId, rate in pairs(productionStats.metrics.productionRate) do
            if rate > 0 then active[commodityId] = true end
        end
        for commodityId, rate in pairs(productionStats.metrics.consumptionRate) do
            if rate > 0 then active[commodityId] = true end
        end
        return active
    elseif filter == "top20" then
        -- Sort by total flow volume, return top 20
        local volumes = {}
        for commodityId in pairs(allCommodities) do
            local prod = productionStats.metrics.productionRate[commodityId] or 0
            local cons = productionStats.metrics.consumptionRate[commodityId] or 0
            table.insert(volumes, {id = commodityId, volume = prod + cons})
        end
        table.sort(volumes, function(a,b) return a.volume > b.volume end)
        local top20 = {}
        for i = 1, math.min(20, #volumes) do
            top20[volumes[i].id] = true
        end
        return top20
    else
        return nil  -- All commodities
    end
end
```

### 4.4 Surplus/Deficit Indicators (O4)

**Two-Section Display:**

**Section A: Rate-Based (Production vs Consumption)**
```
Rate Analysis (units/min)
─────────────────────────────────────────
wheat:   [████████████▓▓▓▓    ]  +13/min  SURPLUS
bread:   [████████░░░░░░░░    ]  -13/min  DEFICIT
timber:  [██████████▓▓        ]   +4/min  SURPLUS
```

**Section B: Inventory Delta (Stockpile Changes)**
```
Stockpile Changes (last 10 slots)
─────────────────────────────────────────
wheat:   120 → 185  (+65)  ▲ Growing
bread:    82 →  45  (-37)  ▼ Depleting
timber:  210 → 230  (+20)  ▲ Growing
```

**Visual Indicators:**
- Green `▲` / `SURPLUS`: net positive
- Red `▼` / `DEFICIT`: net negative
- Yellow `─` / `STABLE`: within ±5% threshold
- Progress bar shows production (solid) vs consumption (striped/hatched)

### 4.5 Trend Sparklines (O5)

**Mini Bar Chart Implementation:**

```lua
function DrawSparkline(x, y, width, height, dataPoints)
    -- dataPoints: array of {value, timestamp} for last 10 cycles
    local barWidth = (width - 2) / #dataPoints
    local maxVal = GetMaxValue(dataPoints)

    for i, point in ipairs(dataPoints) do
        local barHeight = (point.value / maxVal) * height
        local barX = x + (i - 1) * barWidth
        local barY = y + height - barHeight

        -- Color based on trend direction
        local color = GetTrendColor(dataPoints, i)
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", barX, barY, barWidth - 1, barHeight)
    end
end
```

**Sparkline Specs:**
- Width: 60px
- Height: 12px
- 10 bars (one per cycle)
- Colors: green (increasing), red (decreasing), gray (stable)

---

## 5. Data Refresh Strategy

**Trigger:** `OnSlotChange` callback in AlphaWorld

**Implementation:**
```lua
-- In AlphaWorld:OnSlotChange()
function AlphaWorld:OnSlotChange(slotIndex, slot)
    -- ... existing code ...

    -- Refresh economy visualization data
    if self.debugPanel and self.debugPanel.currentTab == "economy" then
        self.debugPanel:RefreshEconomyData()
    end
end
```

**Cached Data Structure:**
```lua
DebugPanel.economyCache = {
    lastRefreshCycle = 0,
    filteredCommodities = {},
    sankeyData = {
        production = {},   -- {commodityId, rate, category}
        consumption = {},  -- {commodityId, rate, category}
        totalStock = 0
    },
    commodityDetails = {}, -- {commodityId, prodRate, consRate, stock, delta, trend}
    sparklineData = {}     -- {commodityId, {values}}
}
```

---

## 6. File Changes Required

### 6.1 Modified Files

| File | Changes |
|------|---------|
| `code/DebugPanel.lua` | Major: Replace `RenderEconomyTab()` (lines 1451-1488) |
| `code/ProductionStats.lua` | Minor: Add helper methods for trend data retrieval |

### 6.2 New Methods in DebugPanel.lua

```lua
-- Economy tab rendering
function DebugPanel:RenderEconomyTab(x, startY, w)
function DebugPanel:RenderEconomyFilter(x, y, w)
function DebugPanel:RenderSankeyDiagram(x, y, w, h)
function DebugPanel:RenderCommodityTable(x, y, w)
function DebugPanel:RenderSparkline(x, y, w, h, data)
function DebugPanel:RenderSurplusDeficitBar(x, y, w, prod, cons)

-- Data management
function DebugPanel:RefreshEconomyData()
function DebugPanel:GetFilteredCommodities()
function DebugPanel:CalculateSankeyFlows()
function DebugPanel:GetSparklineData(commodityId, numCycles)

-- Helpers
function DebugPanel:DrawBezierFlow(x1, y1, x2, y2, width, color)
function DebugPanel:GetCategoryColor(category)
```

### 6.3 New Methods in ProductionStats.lua

```lua
-- Get aggregated data for last N cycles
function ProductionStats:getRecentProduction(numCycles)
function ProductionStats:getRecentConsumption(numCycles)
function ProductionStats:getStockpileDelta(commodityId, numCycles)
```

---

## 7. Category Color Mapping

```lua
local categoryColors = {
    biological = {0.4, 0.7, 0.3, 1},      -- Green
    touch = {0.3, 0.5, 0.8, 1},           -- Blue
    safety = {0.8, 0.6, 0.2, 1},          -- Orange
    psychological = {0.7, 0.4, 0.7, 1},   -- Purple
    social_status = {0.8, 0.7, 0.3, 1},   -- Gold
    exotic_goods = {0.9, 0.4, 0.4, 1},    -- Red
    shiny_objects = {0.9, 0.8, 0.3, 1},   -- Yellow
    vice = {0.5, 0.3, 0.5, 1},            -- Dark purple
    utility = {0.5, 0.5, 0.5, 1},         -- Gray
    default = {0.6, 0.6, 0.6, 1}          -- Light gray
}
```

---

## 8. Testing Criteria

### 8.1 Visual Verification
- [ ] Sankey diagram renders without overlapping flows
- [ ] Flow widths are proportional to quantities
- [ ] Colors match commodity categories
- [ ] Sparklines show correct trend direction

### 8.2 Data Accuracy
- [ ] Production rates match `ProductionStats.metrics.productionRate`
- [ ] Consumption rates match actual allocation results
- [ ] Stock values match `world.inventory`
- [ ] Delta calculations are mathematically correct

### 8.3 Filter Functionality
- [ ] "Active" filter shows only commodities with recent activity
- [ ] "Top 20" filter correctly sorts by volume
- [ ] "All" filter shows complete list with scrolling
- [ ] Filter persists when switching tabs

### 8.4 Performance
- [ ] Tab renders in <16ms (60fps)
- [ ] Scrolling is smooth with 120+ commodities
- [ ] Memory stable over extended play sessions

---

## 9. Implementation Order

1. **Phase 1: Foundation** (O1)
   - Replace skeleton `RenderEconomyTab()`
   - Add filter dropdown UI
   - Set up data refresh on slot change

2. **Phase 2: Data Layer**
   - Implement `RefreshEconomyData()`
   - Add helper methods to `ProductionStats.lua`
   - Build commodity detail table

3. **Phase 3: Visualizations** (O2, O4, O5)
   - Implement Sankey diagram with Bezier curves
   - Add surplus/deficit progress bars
   - Add sparkline bar charts

4. **Phase 4: Polish**
   - Fine-tune flow widths and colors
   - Add hover tooltips (if time permits)
   - Performance optimization

---

## 10. Open Questions (Resolved)

| Question | Resolution |
|----------|------------|
| Gold flow tracking? | SKIPPED - system not implemented |
| Cycle definition? | 1 cycle = 1 time slot |
| Refresh frequency? | Once per slot change |
| Separate tabs for rate vs delta? | Same view, two sections |

---

## 11. Dependencies

- Depends on: CRAVE-6 Debug Panel Foundation (complete)
- Depends on: ProductionStats system (complete)
- No blocking dependencies identified

---

*Document created: 2026-01-11*
*Ready for implementation*
