--[[
ConsumptionAnalyzer.lua
Measures actual consumption rates across all citizen classes over N cycles
Exports to CSV for balance analysis (Task A2)

Usage:
1. Load Alpha prototype or Consumption prototype
2. Spawn citizens with proper class distribution (10/20/40/30)
3. Run this analyzer for 100+ cycles
4. Check output/consumption_rates.csv
]]

local ConsumptionAnalyzer = {}
ConsumptionAnalyzer.__index = ConsumptionAnalyzer

function ConsumptionAnalyzer:new()
    local ca = setmetatable({}, ConsumptionAnalyzer)

    -- Tracking data
    ca.startTime = nil
    ca.endTime = nil
    ca.cycleCount = 0
    ca.targetCycles = 100
    ca.isRunning = false

    -- Consumption tracking: [class][dimension] = {totalDecay, snapshots}
    ca.consumptionData = {}

    -- Class distribution tracking
    ca.classDistribution = {
        elite = 0,
        upper = 0,
        middle = 0,
        lower = 0
    }

    -- Snapshot history (every 10 cycles)
    ca.snapshotInterval = 10
    ca.snapshots = {}

    -- Output path
    ca.outputPath = "output/consumption_rates.csv"

    return ca
end

function ConsumptionAnalyzer:Start(world, targetCycles)
    self.isRunning = true
    self.startTime = love.timer.getTime()
    self.targetCycles = targetCycles or 100
    self.cycleCount = 0
    self.world = world

    print("[ConsumptionAnalyzer] Started - tracking " .. targetCycles .. " cycles")
    print("[ConsumptionAnalyzer] Citizens in world: " .. #world.citizens)

    -- Count class distribution
    for _, citizen in ipairs(world.citizens) do
        local class = citizen.class or "middle"
        self.classDistribution[class] = (self.classDistribution[class] or 0) + 1

        -- Initialize tracking for this class
        if not self.consumptionData[class] then
            self.consumptionData[class] = {
                population = 0,
                dimensions = {}
            }
        end

        self.consumptionData[class].population = self.consumptionData[class].population + 1

        -- Initialize dimension tracking
        if citizen.satisfaction then
            for dimension, value in pairs(citizen.satisfaction) do
                if not self.consumptionData[class].dimensions[dimension] then
                    self.consumptionData[class].dimensions[dimension] = {
                        startingSatisfaction = 0,
                        currentSatisfaction = 0,
                        totalDecay = 0,
                        snapshotCount = 0
                    }
                end
            end
        end
    end

    -- Record initial satisfaction levels
    self:RecordSnapshot()
end

function ConsumptionAnalyzer:Update(dt)
    if not self.isRunning then return end

    -- Track cycles (60 second intervals)
    local elapsed = love.timer.getTime() - self.startTime
    local currentCycle = math.floor(elapsed / 60)

    if currentCycle > self.cycleCount then
        self.cycleCount = currentCycle
        print("[ConsumptionAnalyzer] Cycle " .. self.cycleCount .. "/" .. self.targetCycles)

        -- Take snapshot every N cycles
        if self.cycleCount % self.snapshotInterval == 0 then
            self:RecordSnapshot()
        end
    end

    -- Check if done
    if self.cycleCount >= self.targetCycles then
        self:Finish()
    end
end

function ConsumptionAnalyzer:RecordSnapshot()
    local snapshot = {
        cycle = self.cycleCount,
        time = love.timer.getTime(),
        classes = {}
    }

    for _, citizen in ipairs(self.world.citizens) do
        local class = citizen.class or "middle"

        if not snapshot.classes[class] then
            snapshot.classes[class] = {
                population = 0,
                dimensions = {}
            }
        end

        snapshot.classes[class].population = snapshot.classes[class].population + 1

        -- Record satisfaction per dimension
        if citizen.satisfaction then
            for dimension, value in pairs(citizen.satisfaction) do
                if not snapshot.classes[class].dimensions[dimension] then
                    snapshot.classes[class].dimensions[dimension] = {
                        total = 0,
                        count = 0,
                        min = 100,
                        max = 0
                    }
                end

                local dim = snapshot.classes[class].dimensions[dimension]
                dim.total = dim.total + value
                dim.count = dim.count + 1
                dim.min = math.min(dim.min, value)
                dim.max = math.max(dim.max, value)
            end
        end
    end

    table.insert(self.snapshots, snapshot)

    print("[ConsumptionAnalyzer] Snapshot #" .. #self.snapshots .. " recorded at cycle " .. self.cycleCount)
end

function ConsumptionAnalyzer:Finish()
    if not self.isRunning then return end

    self.isRunning = false
    self.endTime = love.timer.getTime()

    local totalSeconds = self.endTime - self.startTime
    local totalHours = totalSeconds / 3600

    print("[ConsumptionAnalyzer] Finished!")
    print("[ConsumptionAnalyzer] Total time: " .. totalSeconds .. " seconds (" .. totalHours .. " hours)")
    print("[ConsumptionAnalyzer] Total cycles: " .. self.cycleCount)

    -- Calculate decay rates
    self:CalculateDecayRates()

    -- Export to CSV
    self:ExportCSV()
end

function ConsumptionAnalyzer:CalculateDecayRates()
    -- Calculate average decay per cycle per class per dimension
    if #self.snapshots < 2 then
        print("[ConsumptionAnalyzer] WARNING: Not enough snapshots to calculate decay")
        return
    end

    local firstSnapshot = self.snapshots[1]
    local lastSnapshot = self.snapshots[#self.snapshots]

    for class, classData in pairs(lastSnapshot.classes) do
        if not self.consumptionData[class] then
            self.consumptionData[class] = {
                population = classData.population,
                dimensions = {}
            }
        end

        for dimension, dimData in pairs(classData.dimensions) do
            local avgEnd = dimData.total / dimData.count
            local avgStart = 0

            if firstSnapshot.classes[class] and firstSnapshot.classes[class].dimensions[dimension] then
                local startDim = firstSnapshot.classes[class].dimensions[dimension]
                avgStart = startDim.total / startDim.count
            end

            -- Calculate total decay
            local totalDecay = math.max(0, avgStart - avgEnd)
            local cyclesElapsed = lastSnapshot.cycle - firstSnapshot.cycle
            local decayPerCycle = cyclesElapsed > 0 and (totalDecay / cyclesElapsed) or 0

            if not self.consumptionData[class].dimensions[dimension] then
                self.consumptionData[class].dimensions[dimension] = {}
            end

            self.consumptionData[class].dimensions[dimension] = {
                startingSatisfaction = avgStart,
                endingSatisfaction = avgEnd,
                totalDecay = totalDecay,
                decayPerCycle = decayPerCycle,
                cyclesElapsed = cyclesElapsed
            }
        end
    end
end

function ConsumptionAnalyzer:ExportCSV()
    local csv = {}

    -- Header
    table.insert(csv, "class,population,dimension,starting_satisfaction,ending_satisfaction,total_decay,decay_per_cycle,decay_per_hour")

    -- Data rows
    for class, classData in pairs(self.consumptionData) do
        for dimension, dimData in pairs(classData.dimensions) do
            local decayPerHour = dimData.decayPerCycle * 60  -- 60 cycles per hour

            local row = string.format(
                "%s,%d,%s,%.2f,%.2f,%.2f,%.4f,%.2f",
                class,
                classData.population,
                dimension,
                dimData.startingSatisfaction or 0,
                dimData.endingSatisfaction or 0,
                dimData.totalDecay or 0,
                dimData.decayPerCycle or 0,
                decayPerHour
            )

            table.insert(csv, row)
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
        print("[ConsumptionAnalyzer] Exported to " .. fullPath)
        print("[ConsumptionAnalyzer] Rows written: " .. #csv)
    else
        print("[ConsumptionAnalyzer] ERROR: Could not write to " .. fullPath)
    end

    -- Also print summary to console
    print("\n=== CONSUMPTION SUMMARY ===")
    print("Total population: " .. #self.world.citizens)
    for class, count in pairs(self.classDistribution) do
        local percentage = (count / #self.world.citizens) * 100
        print(string.format("  %s: %d citizens (%.1f%%)", class, count, percentage))
    end
end

return ConsumptionAnalyzer
