-- ProductionStats.lua
-- Time-series statistics tracking for production and consumption

local ProductionStats = {}
ProductionStats.__index = ProductionStats

function ProductionStats.new()
    local self = setmetatable({}, ProductionStats)

    -- Configuration
    self.maxSamples = 200  -- Keep last 200 periods
    self.samplingInterval = 60  -- Sample every 60 ticks (1 game minute)
    self.currentTick = 0
    self.lastSampleTick = 0

    -- Historical data (ring buffers)
    self.history = {
        commodityProduction = {},   -- { tick, commodity_id, quantity }
        commodityConsumption = {},  -- { tick, commodity_id, quantity }
        buildingOutput = {},        -- { tick, building_id, commodity_id, quantity }
        workerUtilization = {},     -- { tick, total_workers, active_workers }
        stockpiles = {},            -- { tick, commodity_id, quantity }
    }

    -- Current period accumulator (reset after each sample)
    self.currentPeriod = {
        production = {},   -- commodity_id -> quantity
        consumption = {},  -- commodity_id -> quantity
        buildingOutputs = {},  -- building_id -> { commodity_id -> quantity }
    }

    -- Aggregated metrics for quick access
    self.metrics = {
        productionRate = {},     -- commodity_id -> units per minute
        consumptionRate = {},    -- commodity_id -> units per minute
        netProduction = {},      -- commodity_id -> production - consumption
        topProducers = {},       -- List of top 5 commodities by production
        topConsumers = {},       -- List of top 5 commodities by consumption
        totalWorkers = 0,
        activeWorkers = 0,
    }

    return self
end

-- Update tick counter
function ProductionStats:updateTick(tick)
    self.currentTick = tick

    -- Check if we should sample
    if self.currentTick - self.lastSampleTick >= self.samplingInterval then
        self:sampleAndRecord()
        self.lastSampleTick = self.currentTick
    end
end

-- Record production event
function ProductionStats:recordProduction(commodityId, quantity, buildingId)
    -- Accumulate in current period
    self.currentPeriod.production[commodityId] = (self.currentPeriod.production[commodityId] or 0) + quantity

    if buildingId then
        self.currentPeriod.buildingOutputs[buildingId] = self.currentPeriod.buildingOutputs[buildingId] or {}
        self.currentPeriod.buildingOutputs[buildingId][commodityId] =
            (self.currentPeriod.buildingOutputs[buildingId][commodityId] or 0) + quantity
    end
end

-- Record consumption event
function ProductionStats:recordConsumption(commodityId, quantity)
    self.currentPeriod.consumption[commodityId] = (self.currentPeriod.consumption[commodityId] or 0) + quantity
end

-- Record worker utilization
function ProductionStats:recordWorkerStats(totalWorkers, activeWorkers)
    self.metrics.totalWorkers = totalWorkers
    self.metrics.activeWorkers = activeWorkers
end

-- Record stockpile levels
function ProductionStats:recordStockpile(commodityId, quantity)
    -- Store for current tick (will be sampled)
    self.currentStockpiles = self.currentStockpiles or {}
    self.currentStockpiles[commodityId] = quantity
end

-- Sample current period and record to history
function ProductionStats:sampleAndRecord()
    -- Record production
    for commodityId, quantity in pairs(self.currentPeriod.production) do
        self:addToHistory('commodityProduction', {
            tick = self.currentTick,
            commodity = commodityId,
            quantity = quantity
        })
    end

    -- Record consumption
    for commodityId, quantity in pairs(self.currentPeriod.consumption) do
        self:addToHistory('commodityConsumption', {
            tick = self.currentTick,
            commodity = commodityId,
            quantity = quantity
        })
    end

    -- Record building outputs
    for buildingId, outputs in pairs(self.currentPeriod.buildingOutputs) do
        for commodityId, quantity in pairs(outputs) do
            self:addToHistory('buildingOutput', {
                tick = self.currentTick,
                building = buildingId,
                commodity = commodityId,
                quantity = quantity
            })
        end
    end

    -- Record worker utilization
    self:addToHistory('workerUtilization', {
        tick = self.currentTick,
        total = self.metrics.totalWorkers,
        active = self.metrics.activeWorkers
    })

    -- Record stockpiles
    if self.currentStockpiles then
        for commodityId, quantity in pairs(self.currentStockpiles) do
            self:addToHistory('stockpiles', {
                tick = self.currentTick,
                commodity = commodityId,
                quantity = quantity
            })
        end
    end

    -- Calculate rates (per minute)
    local minutesPerSample = self.samplingInterval / 60
    for commodityId, quantity in pairs(self.currentPeriod.production) do
        self.metrics.productionRate[commodityId] = quantity / minutesPerSample
    end
    for commodityId, quantity in pairs(self.currentPeriod.consumption) do
        self.metrics.consumptionRate[commodityId] = quantity / minutesPerSample
    end

    -- Calculate net production
    local allCommodities = {}
    for id in pairs(self.currentPeriod.production) do allCommodities[id] = true end
    for id in pairs(self.currentPeriod.consumption) do allCommodities[id] = true end

    for commodityId in pairs(allCommodities) do
        local prod = self.currentPeriod.production[commodityId] or 0
        local cons = self.currentPeriod.consumption[commodityId] or 0
        self.metrics.netProduction[commodityId] = prod - cons
    end

    -- Update top producers/consumers
    self:updateTopLists()

    -- Reset current period
    self.currentPeriod = {
        production = {},
        consumption = {},
        buildingOutputs = {},
    }
    self.currentStockpiles = nil
end

-- Add entry to history with ring buffer management
function ProductionStats:addToHistory(category, entry)
    local history = self.history[category]
    table.insert(history, entry)

    -- Prune if exceeds max samples
    if #history > self.maxSamples then
        table.remove(history, 1)
    end
end

-- Update top producers and consumers lists
function ProductionStats:updateTopLists()
    -- Sort by production rate
    local prodList = {}
    for commodityId, rate in pairs(self.metrics.productionRate) do
        table.insert(prodList, {id = commodityId, rate = rate})
    end
    table.sort(prodList, function(a, b) return a.rate > b.rate end)

    self.metrics.topProducers = {}
    for i = 1, math.min(5, #prodList) do
        table.insert(self.metrics.topProducers, prodList[i])
    end

    -- Sort by consumption rate
    local consList = {}
    for commodityId, rate in pairs(self.metrics.consumptionRate) do
        table.insert(consList, {id = commodityId, rate = rate})
    end
    table.sort(consList, function(a, b) return a.rate > b.rate end)

    self.metrics.topConsumers = {}
    for i = 1, math.min(5, #consList) do
        table.insert(self.metrics.topConsumers, consList[i])
    end
end

-- Get production trend for a commodity (last N samples)
function ProductionStats:getProductionTrend(commodityId, numSamples)
    numSamples = numSamples or 60  -- Default: last 60 samples

    local trend = {}
    local history = self.history.commodityProduction
    local startIdx = math.max(1, #history - numSamples + 1)

    for i = startIdx, #history do
        local entry = history[i]
        if entry.commodity == commodityId then
            table.insert(trend, {tick = entry.tick, quantity = entry.quantity})
        end
    end

    return trend
end

-- Get consumption trend for a commodity
function ProductionStats:getConsumptionTrend(commodityId, numSamples)
    numSamples = numSamples or 60

    local trend = {}
    local history = self.history.commodityConsumption
    local startIdx = math.max(1, #history - numSamples + 1)

    for i = startIdx, #history do
        local entry = history[i]
        if entry.commodity == commodityId then
            table.insert(trend, {tick = entry.tick, quantity = entry.quantity})
        end
    end

    return trend
end

-- Get stockpile trend for a commodity
function ProductionStats:getStockpileTrend(commodityId, numSamples)
    numSamples = numSamples or 60

    local trend = {}
    local history = self.history.stockpiles
    local startIdx = math.max(1, #history - numSamples + 1)

    for i = startIdx, #history do
        local entry = history[i]
        if entry.commodity == commodityId then
            table.insert(trend, {tick = entry.tick, quantity = entry.quantity})
        end
    end

    return trend
end

-- Get worker utilization trend
function ProductionStats:getWorkerUtilizationTrend(numSamples)
    numSamples = numSamples or 60

    local trend = {}
    local history = self.history.workerUtilization
    local startIdx = math.max(1, #history - numSamples + 1)

    for i = startIdx, #history do
        local entry = history[i]
        local utilization = entry.total > 0 and (entry.active / entry.total * 100) or 0
        table.insert(trend, {tick = entry.tick, utilization = utilization})
    end

    return trend
end

-- Get all commodities being tracked
function ProductionStats:getTrackedCommodities()
    local commodities = {}

    for id in pairs(self.metrics.productionRate) do
        commodities[id] = true
    end
    for id in pairs(self.metrics.consumptionRate) do
        commodities[id] = true
    end

    local list = {}
    for id in pairs(commodities) do
        table.insert(list, id)
    end
    table.sort(list)

    return list
end

-- Get current metrics summary
function ProductionStats:getMetricsSummary()
    return {
        productionRate = self.metrics.productionRate,
        consumptionRate = self.metrics.consumptionRate,
        netProduction = self.metrics.netProduction,
        topProducers = self.metrics.topProducers,
        topConsumers = self.metrics.topConsumers,
        workerUtilization = self.metrics.totalWorkers > 0
            and (self.metrics.activeWorkers / self.metrics.totalWorkers * 100) or 0,
        totalWorkers = self.metrics.totalWorkers,
        activeWorkers = self.metrics.activeWorkers,
    }
end

return ProductionStats
