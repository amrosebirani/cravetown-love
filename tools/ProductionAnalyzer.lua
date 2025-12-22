--[[
ProductionAnalyzer.lua
Measures actual production rates across all building types over N cycles
Exports to CSV for balance analysis (Task A1)

Usage:
1. Load Alpha prototype
2. Create buildings with workers
3. Run this analyzer for 100+ cycles
4. Check output/production_rates.csv
]]

local ProductionAnalyzer = {}
ProductionAnalyzer.__index = ProductionAnalyzer

function ProductionAnalyzer:new()
    local pa = setmetatable({}, ProductionAnalyzer)

    -- Tracking data
    pa.startTime = nil
    pa.endTime = nil
    pa.cycleCount = 0
    pa.targetCycles = 100
    pa.isRunning = false

    -- Production tracking: [buildingType][recipeId] = {produced, timeActive, stationCount}
    pa.productionData = {}

    -- Building tracking: [buildingType] = {count, totalStations, activeStations}
    pa.buildingStats = {}

    -- Output path
    pa.outputPath = "output/production_rates.csv"

    return pa
end

function ProductionAnalyzer:Start(world, targetCycles)
    self.isRunning = true
    self.startTime = love.timer.getTime()
    self.targetCycles = targetCycles or 100
    self.cycleCount = 0
    self.world = world

    print("[ProductionAnalyzer] Started - tracking " .. targetCycles .. " cycles")
    print("[ProductionAnalyzer] Buildings in world: " .. #world.buildings)

    -- Initialize tracking for all buildings
    for _, building in ipairs(world.buildings) do
        local typeId = building.typeId

        if not self.buildingStats[typeId] then
            self.buildingStats[typeId] = {
                count = 0,
                totalStations = 0,
                activeStations = 0
            }
        end

        self.buildingStats[typeId].count = self.buildingStats[typeId].count + 1
        self.buildingStats[typeId].totalStations = self.buildingStats[typeId].totalStations + #building.stations

        -- Initialize production tracking for each recipe
        for _, station in ipairs(building.stations) do
            if station.recipe then
                local recipeId = station.recipe.id

                if not self.productionData[typeId] then
                    self.productionData[typeId] = {}
                end

                if not self.productionData[typeId][recipeId] then
                    self.productionData[typeId][recipeId] = {
                        recipeName = station.recipe.name,
                        productionTime = station.recipe.productionTime,
                        outputs = station.recipe.outputs,
                        totalProduced = {},
                        cyclesActive = 0,
                        stationCount = 0
                    }

                    -- Initialize output tracking
                    for outputId, qty in pairs(station.recipe.outputs or {}) do
                        self.productionData[typeId][recipeId].totalProduced[outputId] = 0
                    end
                end

                self.productionData[typeId][recipeId].stationCount =
                    self.productionData[typeId][recipeId].stationCount + 1
            end
        end
    end
end

function ProductionAnalyzer:Update(dt)
    if not self.isRunning then return end

    -- Track production completion
    for _, building in ipairs(self.world.buildings) do
        local typeId = building.typeId

        for _, station in ipairs(building.stations) do
            if station.recipe and station.state == "PRODUCING" then
                self.buildingStats[typeId].activeStations =
                    self.buildingStats[typeId].activeStations + 1
            end

            -- Detect production completion (progress wrapped around)
            if station.recipe and station.lastProgress then
                if station.lastProgress > 0.9 and station.progress < 0.1 then
                    -- Production completed!
                    local recipeId = station.recipe.id
                    local data = self.productionData[typeId][recipeId]

                    -- Record outputs
                    for outputId, qty in pairs(station.recipe.outputs or {}) do
                        data.totalProduced[outputId] = data.totalProduced[outputId] + qty
                    end

                    data.cyclesActive = data.cyclesActive + 1
                end
            end

            station.lastProgress = station.progress
        end
    end

    -- Track cycles (60 second intervals)
    local elapsed = love.timer.getTime() - self.startTime
    local currentCycle = math.floor(elapsed / 60)

    if currentCycle > self.cycleCount then
        self.cycleCount = currentCycle
        print("[ProductionAnalyzer] Cycle " .. self.cycleCount .. "/" .. self.targetCycles)

        -- Reset active stations counter
        for typeId, stats in pairs(self.buildingStats) do
            stats.activeStations = 0
        end
    end

    -- Check if done
    if self.cycleCount >= self.targetCycles then
        self:Finish()
    end
end

function ProductionAnalyzer:Finish()
    if not self.isRunning then return end

    self.isRunning = false
    self.endTime = love.timer.getTime()

    local totalSeconds = self.endTime - self.startTime
    local totalHours = totalSeconds / 3600

    print("[ProductionAnalyzer] Finished!")
    print("[ProductionAnalyzer] Total time: " .. totalSeconds .. " seconds (" .. totalHours .. " hours)")

    -- Export to CSV
    self:ExportCSV()
end

function ProductionAnalyzer:ExportCSV()
    local csv = {}

    -- Header
    table.insert(csv, "building_type,recipe_id,recipe_name,production_time_sec,station_count,output_commodity,output_qty_per_batch,total_produced,cycles_active,output_per_hour,output_per_cycle")

    -- Data rows
    for buildingType, recipes in pairs(self.productionData) do
        for recipeId, data in pairs(recipes) do
            for outputId, totalProduced in pairs(data.totalProduced) do
                local outputQtyPerBatch = data.outputs[outputId] or 0
                local productionTime = data.productionTime
                local stationCount = data.stationCount
                local cyclesActive = data.cyclesActive

                -- Calculate rates
                local totalSeconds = self.endTime - self.startTime
                local outputPerHour = (totalProduced / totalSeconds) * 3600
                local outputPerCycle = (totalProduced / self.cycleCount)

                local row = string.format(
                    "%s,%s,%s,%.1f,%d,%s,%d,%d,%d,%.2f,%.2f",
                    buildingType,
                    recipeId,
                    data.recipeName,
                    productionTime,
                    stationCount,
                    outputId,
                    outputQtyPerBatch,
                    totalProduced,
                    cyclesActive,
                    outputPerHour,
                    outputPerCycle
                )

                table.insert(csv, row)
            end
        end
    end

    -- Write to file
    local fullPath = self.outputPath
    local csvContent = table.concat(csv, "\n")

    -- Ensure output directory exists
    os.execute("mkdir -p output")

    local file = io.open(fullPath, "w")
    if file then
        file:write(csvContent)
        file:close()
        print("[ProductionAnalyzer] Exported to " .. fullPath)
        print("[ProductionAnalyzer] Rows written: " .. #csv)
    else
        print("[ProductionAnalyzer] ERROR: Could not write to " .. fullPath)
    end

    -- Also print summary to console
    print("\n=== PRODUCTION SUMMARY ===")
    for buildingType, stats in pairs(self.buildingStats) do
        print(string.format("%s: %d buildings, %d stations, avg %.1f active",
            buildingType, stats.count, stats.totalStations, stats.activeStations / self.cycleCount))
    end
end

return ProductionAnalyzer
