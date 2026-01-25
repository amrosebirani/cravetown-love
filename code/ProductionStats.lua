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

    -- Daily history tracking (last 30 days)
    self.maxDailyHistory = 30
    self.dailyHistory = {}  -- Array of daily records, newest at end
    self.currentDayData = {
        day = 0,
        produced = {},           -- commodityId -> quantity
        consumedByCitizens = {}, -- commodityId -> quantity
        consumedByBuildings = {}, -- commodityId -> quantity
        -- Citizen issues tracking
        citizenIssues = {
            -- Fine dimension issues: fineDimensionId -> { citizens = {id=true}, totalSatisfaction = 0, count = 0 }
            fineIssues = {},
            -- Coarse dimension issues: coarseDimensionId -> { citizens = {id=true}, totalSatisfaction = 0, count = 0 }
            coarseIssues = {},
            -- Housing issues
            homelessCitizens = {},  -- Set of citizen IDs
            homelessCount = 0
        },
        -- Allocation failure tracking (proactive warnings)
        allocationFailures = {
            -- commodityId -> { failedCount = N, citizensAffected = {id=true}, citizenCount = 0 }
            shortages = {},
            totalFailedAllocations = 0
        }
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
    -- Accumulate in current period (tick-level)
    self.currentPeriod.production[commodityId] = (self.currentPeriod.production[commodityId] or 0) + quantity

    if buildingId then
        self.currentPeriod.buildingOutputs[buildingId] = self.currentPeriod.buildingOutputs[buildingId] or {}
        self.currentPeriod.buildingOutputs[buildingId][commodityId] =
            (self.currentPeriod.buildingOutputs[buildingId][commodityId] or 0) + quantity
    end

    -- Also accumulate in daily tracking
    self.currentDayData.produced[commodityId] = (self.currentDayData.produced[commodityId] or 0) + quantity
end

-- Record consumption event (legacy - use recordBuildingConsumption or recordCitizenConsumption instead)
function ProductionStats:recordConsumption(commodityId, quantity)
    self.currentPeriod.consumption[commodityId] = (self.currentPeriod.consumption[commodityId] or 0) + quantity
end

-- Record building consumption (raw materials used in production)
function ProductionStats:recordBuildingConsumption(commodityId, quantity)
    -- Accumulate in current period (tick-level)
    self.currentPeriod.consumption[commodityId] = (self.currentPeriod.consumption[commodityId] or 0) + quantity

    -- Also accumulate in daily tracking
    self.currentDayData.consumedByBuildings[commodityId] = (self.currentDayData.consumedByBuildings[commodityId] or 0) + quantity
end

-- Record citizen consumption (direct consumption by citizens)
function ProductionStats:recordCitizenConsumption(commodityId, quantity)
    -- Accumulate in current period (tick-level)
    self.currentPeriod.consumption[commodityId] = (self.currentPeriod.consumption[commodityId] or 0) + quantity

    -- Also accumulate in daily tracking
    self.currentDayData.consumedByCitizens[commodityId] = (self.currentDayData.consumedByCitizens[commodityId] or 0) + quantity
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

-- =============================================================================
-- DAILY HISTORY TRACKING
-- =============================================================================

-- Finalize the current day's data and archive it, then reset for new day
-- Should be called at the start of each new day with the previous day number
function ProductionStats:finalizeDayAndReset(completedDayNumber)
    -- Only archive if there's data (day > 0 means we have actual data)
    if completedDayNumber > 0 then
        -- Check if we have any data to archive
        local hasData = next(self.currentDayData.produced) ~= nil or
                       next(self.currentDayData.consumedByCitizens) ~= nil or
                       next(self.currentDayData.consumedByBuildings) ~= nil

        -- Also check if we have citizen issues to archive
        local hasIssues = (self.currentDayData.citizenIssues.homelessCount > 0) or
                         (next(self.currentDayData.citizenIssues.coarseIssues) ~= nil)

        -- Check if we have allocation failures to archive
        local hasShortages = self.currentDayData.allocationFailures.totalFailedAllocations > 0

        if hasData or hasIssues or hasShortages then
            -- Create deep copy of current day data
            local dayRecord = {
                day = completedDayNumber,
                produced = {},
                consumedByCitizens = {},
                consumedByBuildings = {},
                citizenIssues = {
                    fineIssues = {},
                    coarseIssues = {},
                    homelessCount = self.currentDayData.citizenIssues.homelessCount
                },
                allocationFailures = {
                    shortages = {},
                    totalFailedAllocations = self.currentDayData.allocationFailures.totalFailedAllocations
                }
            }

            for commodityId, qty in pairs(self.currentDayData.produced) do
                dayRecord.produced[commodityId] = qty
            end
            for commodityId, qty in pairs(self.currentDayData.consumedByCitizens) do
                dayRecord.consumedByCitizens[commodityId] = qty
            end
            for commodityId, qty in pairs(self.currentDayData.consumedByBuildings) do
                dayRecord.consumedByBuildings[commodityId] = qty
            end

            -- Copy citizen issues (we don't need the citizen ID sets, just counts and averages)
            for fineId, fineData in pairs(self.currentDayData.citizenIssues.fineIssues) do
                dayRecord.citizenIssues.fineIssues[fineId] = {
                    count = fineData.count,
                    totalSatisfaction = fineData.totalSatisfaction,
                    coarseParent = fineData.coarseParent
                }
            end
            for coarseId, coarseData in pairs(self.currentDayData.citizenIssues.coarseIssues) do
                dayRecord.citizenIssues.coarseIssues[coarseId] = {
                    count = coarseData.count,
                    totalSatisfaction = coarseData.totalSatisfaction
                }
            end

            -- Copy allocation failures (we don't need the citizen ID sets, just counts)
            for commodityId, shortageData in pairs(self.currentDayData.allocationFailures.shortages) do
                dayRecord.allocationFailures.shortages[commodityId] = {
                    failedCount = shortageData.failedCount,
                    citizenCount = shortageData.citizenCount
                }
            end

            -- Add to history
            table.insert(self.dailyHistory, dayRecord)

            -- Prune if exceeds max history
            while #self.dailyHistory > self.maxDailyHistory do
                table.remove(self.dailyHistory, 1)
            end

            print(string.format("[ProductionStats] Archived Day %d: %d produced, %d citizen consumed, %d building consumed",
                completedDayNumber,
                self:countTableValues(dayRecord.produced),
                self:countTableValues(dayRecord.consumedByCitizens),
                self:countTableValues(dayRecord.consumedByBuildings)))
        end
    end

    -- Reset current day data for the new day
    self.currentDayData = {
        day = completedDayNumber + 1,
        produced = {},
        consumedByCitizens = {},
        consumedByBuildings = {},
        citizenIssues = {
            fineIssues = {},
            coarseIssues = {},
            homelessCitizens = {},
            homelessCount = 0
        },
        allocationFailures = {
            shortages = {},
            totalFailedAllocations = 0
        }
    }
end

-- Helper to count total values in a commodity table
function ProductionStats:countTableValues(tbl)
    local total = 0
    for _, qty in pairs(tbl) do
        total = total + qty
    end
    return total
end

-- Get daily history (returns last N days, newest first)
function ProductionStats:getDailyHistory(numDays)
    numDays = numDays or self.maxDailyHistory

    local result = {}
    local startIdx = math.max(1, #self.dailyHistory - numDays + 1)

    -- Return in reverse order (newest first)
    for i = #self.dailyHistory, startIdx, -1 do
        table.insert(result, self.dailyHistory[i])
    end

    return result
end

-- Get a specific day's data by day number
function ProductionStats:getDayData(dayNumber)
    for _, dayRecord in ipairs(self.dailyHistory) do
        if dayRecord.day == dayNumber then
            return dayRecord
        end
    end
    return nil
end

-- Get the current (incomplete) day's data
function ProductionStats:getCurrentDayData()
    return self.currentDayData
end

-- Get list of all days with recorded data
function ProductionStats:getRecordedDays()
    local days = {}
    for _, dayRecord in ipairs(self.dailyHistory) do
        table.insert(days, dayRecord.day)
    end
    -- Sort ascending
    table.sort(days)
    return days
end

-- Get summary totals for a specific day
function ProductionStats:getDaySummary(dayNumber)
    local dayData = self:getDayData(dayNumber)
    if not dayData then
        return nil
    end

    return {
        day = dayData.day,
        totalProduced = self:countTableValues(dayData.produced),
        totalConsumedByCitizens = self:countTableValues(dayData.consumedByCitizens),
        totalConsumedByBuildings = self:countTableValues(dayData.consumedByBuildings),
        producedItems = dayData.produced,
        consumedByCitizensItems = dayData.consumedByCitizens,
        consumedByBuildingsItems = dayData.consumedByBuildings
    }
end

-- =============================================================================
-- CITIZEN ISSUES TRACKING
-- =============================================================================

-- Record a citizen issue for a fine dimension
-- Called when a citizen has low satisfaction in a specific fine dimension
function ProductionStats:recordCitizenFineDimensionIssue(fineDimensionId, citizenId, satisfaction, coarseDimensionId)
    local fineIssues = self.currentDayData.citizenIssues.fineIssues
    local coarseIssues = self.currentDayData.citizenIssues.coarseIssues

    -- Track fine dimension issue
    if not fineIssues[fineDimensionId] then
        fineIssues[fineDimensionId] = {
            citizens = {},
            totalSatisfaction = 0,
            count = 0,
            coarseParent = coarseDimensionId
        }
    end

    -- Only count each citizen once per fine dimension per day
    if not fineIssues[fineDimensionId].citizens[citizenId] then
        fineIssues[fineDimensionId].citizens[citizenId] = true
        fineIssues[fineDimensionId].totalSatisfaction = fineIssues[fineDimensionId].totalSatisfaction + satisfaction
        fineIssues[fineDimensionId].count = fineIssues[fineDimensionId].count + 1
    end

    -- Also track at coarse level
    if coarseDimensionId then
        if not coarseIssues[coarseDimensionId] then
            coarseIssues[coarseDimensionId] = {
                citizens = {},
                totalSatisfaction = 0,
                count = 0
            }
        end

        -- Only count each citizen once per coarse dimension per day
        if not coarseIssues[coarseDimensionId].citizens[citizenId] then
            coarseIssues[coarseDimensionId].citizens[citizenId] = true
            coarseIssues[coarseDimensionId].totalSatisfaction = coarseIssues[coarseDimensionId].totalSatisfaction + satisfaction
            coarseIssues[coarseDimensionId].count = coarseIssues[coarseDimensionId].count + 1
        end
    end
end

-- Record a homeless citizen
function ProductionStats:recordHomelessCitizen(citizenId)
    local homeless = self.currentDayData.citizenIssues.homelessCitizens
    if not homeless[citizenId] then
        homeless[citizenId] = true
        self.currentDayData.citizenIssues.homelessCount = self.currentDayData.citizenIssues.homelessCount + 1
    end
end

-- Clear homeless tracking (call at start of each slot to refresh)
function ProductionStats:clearHomelessTracking()
    self.currentDayData.citizenIssues.homelessCitizens = {}
    self.currentDayData.citizenIssues.homelessCount = 0
end

-- =============================================================================
-- ALLOCATION FAILURE TRACKING (Proactive Warnings)
-- =============================================================================

-- Record an allocation failure when a commodity couldn't be provided
-- Called when AllocationEngineV2 fails to allocate a requested commodity
function ProductionStats:recordAllocationFailure(commodityId, citizenId)
    if not commodityId then return end

    local shortages = self.currentDayData.allocationFailures.shortages

    if not shortages[commodityId] then
        shortages[commodityId] = {
            failedCount = 0,
            citizensAffected = {},
            citizenCount = 0
        }
    end

    -- Increment failed count for this commodity
    shortages[commodityId].failedCount = shortages[commodityId].failedCount + 1

    -- Track unique citizens affected (only count each citizen once per commodity)
    if citizenId and not shortages[commodityId].citizensAffected[citizenId] then
        shortages[commodityId].citizensAffected[citizenId] = true
        shortages[commodityId].citizenCount = shortages[commodityId].citizenCount + 1
    end

    -- Increment total failed allocations
    self.currentDayData.allocationFailures.totalFailedAllocations =
        self.currentDayData.allocationFailures.totalFailedAllocations + 1
end

-- Clear allocation failure tracking (call at start of each day if needed)
function ProductionStats:clearAllocationFailures()
    self.currentDayData.allocationFailures = {
        shortages = {},
        totalFailedAllocations = 0
    }
end

-- Get complete day end summary with issues aggregation
-- Returns data formatted for DayEndSummaryModal
function ProductionStats:getDayEndSummary(dayNumber)
    local dayData = self:getDayData(dayNumber)
    if not dayData then
        return nil
    end

    -- Aggregate issues by severity
    local issuesByCoarse = {}
    local totalIssueCount = 0

    -- Severity thresholds
    local CRITICAL_THRESHOLD = 20
    local WARNING_THRESHOLD = 40
    local MILD_THRESHOLD = 60

    -- Process coarse issues
    if dayData.citizenIssues and dayData.citizenIssues.coarseIssues then
        for coarseId, issueData in pairs(dayData.citizenIssues.coarseIssues) do
            if issueData.count > 0 then
                local avgSatisfaction = issueData.totalSatisfaction / issueData.count
                local severity = "mild"
                if avgSatisfaction < CRITICAL_THRESHOLD then
                    severity = "critical"
                elseif avgSatisfaction < WARNING_THRESHOLD then
                    severity = "warning"
                end

                -- Collect fine dimension breakdowns for this coarse
                local fineBreakdown = {}
                if dayData.citizenIssues.fineIssues then
                    for fineId, fineData in pairs(dayData.citizenIssues.fineIssues) do
                        if fineData.coarseParent == coarseId and fineData.count > 0 then
                            table.insert(fineBreakdown, {
                                id = fineId,
                                count = fineData.count,
                                avgSatisfaction = fineData.totalSatisfaction / fineData.count
                            })
                        end
                    end
                end

                -- Sort fine breakdown by count (most affected first)
                table.sort(fineBreakdown, function(a, b) return a.count > b.count end)

                issuesByCoarse[coarseId] = {
                    coarseId = coarseId,
                    count = issueData.count,
                    avgSatisfaction = avgSatisfaction,
                    severity = severity,
                    fineBreakdown = fineBreakdown
                }
                totalIssueCount = totalIssueCount + 1
            end
        end
    end

    -- Add housing issues
    local homelessCount = dayData.citizenIssues and dayData.citizenIssues.homelessCount or 0
    local hasHousingIssue = homelessCount > 0

    -- Process allocation failures (proactive warnings)
    local shortagesList = {}
    local totalFailedAllocations = 0
    if dayData.allocationFailures then
        totalFailedAllocations = dayData.allocationFailures.totalFailedAllocations or 0
        if dayData.allocationFailures.shortages then
            for commodityId, shortageData in pairs(dayData.allocationFailures.shortages) do
                table.insert(shortagesList, {
                    commodityId = commodityId,
                    failedCount = shortageData.failedCount,
                    citizenCount = shortageData.citizenCount
                })
            end
            -- Sort by failed count (most failures first)
            table.sort(shortagesList, function(a, b) return a.failedCount > b.failedCount end)
        end
    end
    local hasShortages = totalFailedAllocations > 0

    -- Determine overall hasIssues flag
    local hasIssues = totalIssueCount > 0 or hasHousingIssue or hasShortages

    -- Sort issues by severity (critical first) then by count
    local sortedIssues = {}
    for _, issue in pairs(issuesByCoarse) do
        table.insert(sortedIssues, issue)
    end
    table.sort(sortedIssues, function(a, b)
        local severityOrder = {critical = 1, warning = 2, mild = 3}
        if severityOrder[a.severity] ~= severityOrder[b.severity] then
            return severityOrder[a.severity] < severityOrder[b.severity]
        end
        return a.count > b.count
    end)

    return {
        day = dayNumber,
        hasIssues = hasIssues,

        -- Issues data
        issues = sortedIssues,
        issuesByCoarse = issuesByCoarse,
        totalIssueCategories = totalIssueCount,

        -- Housing issues
        homelessCount = homelessCount,

        -- Allocation failure / shortage data (proactive warnings)
        shortages = shortagesList,
        totalFailedAllocations = totalFailedAllocations,
        hasShortages = hasShortages,

        -- Production/Consumption data
        produced = dayData.produced,
        consumedByCitizens = dayData.consumedByCitizens,
        consumedByBuildings = dayData.consumedByBuildings,
        totalProduced = self:countTableValues(dayData.produced),
        totalConsumedByCitizens = self:countTableValues(dayData.consumedByCitizens),
        totalConsumedByBuildings = self:countTableValues(dayData.consumedByBuildings)
    }
end

return ProductionStats
