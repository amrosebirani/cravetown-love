-- TestAllocationEngineV2State.lua
-- Test prototype for AllocationEngineV2 with CharacterV2
-- Tests Phase 3: Refactored allocation system

local DataLoader = require("code.DataLoader")
local CharacterV2 = require("code.consumption.CharacterV2")
local AllocationEngineV2 = require("code.consumption.AllocationEngineV2")
local CommodityCache = require("code.consumption.CommodityCache")
local TownConsequences = require("code.consumption.TownConsequences")

local TestAllocationEngineV2State = {}

function TestAllocationEngineV2State:enter()
    print("\n=== AllocationEngineV2 Test Prototype ===\n")

    -- Load all required data
    self:loadData()

    -- Initialize CharacterV2
    CharacterV2.Init(
        self.consumptionMechanics,
        self.fulfillmentVectors,
        self.characterTraits,
        self.characterClasses,
        self.dimensionDefinitions,
        self.commodityFatigueRates,
        self.enablementRules
    )

    -- Initialize CommodityCache
    CommodityCache.Init(
        self.fulfillmentVectors,
        self.dimensionDefinitions,
        self.substitutionRules,
        CharacterV2
    )

    -- Initialize AllocationEngineV2 with cache
    AllocationEngineV2.Init(
        self.consumptionMechanics,
        self.fulfillmentVectors,
        self.substitutionRules,
        CharacterV2,
        CommodityCache
    )

    -- Initialize TownConsequences
    TownConsequences.Init(self.consumptionMechanics)

    -- Create test characters
    self.characters = {}
    table.insert(self.characters, CharacterV2:New("elite", "elite_1"))
    table.insert(self.characters, CharacterV2:New("middle", "middle_1"))
    table.insert(self.characters, CharacterV2:New("lower", "lower_1"))

    -- Debug: Check baseCravings
    print("\nDebug: Checking base cravings for first character:")
    local char1 = self.characters[1]
    local totalBase = 0
    for i = 0, 48 do
        totalBase = totalBase + (char1.baseCravings[i] or 0)
    end
    print(string.format("  Total base cravings: %.2f", totalBase))
    print(string.format("  Sample base[0]: %.4f, base[10]: %.4f, base[20]: %.4f",
        char1.baseCravings[0] or 0,
        char1.baseCravings[10] or 0,
        char1.baseCravings[20] or 0))

    -- Set up test inventory (limited resources to test substitution)
    self.townInventory = {
        -- Grains
        wheat = 2,
        rice = 1,
        bread = 3,

        -- Fruits
        apple = 2,
        orange = 0,  -- Out of stock to test substitution

        -- Meat
        beef = 1,
        fish = 2,

        -- Luxury
        wine = 1,
        silk = 0,  -- Out of stock
        gold = 1,

        -- Other
        water = 10,
        wood = 5
    }

    -- Create backup of initial inventory for display
    self.initialInventory = {}
    for k, v in pairs(self.townInventory) do
        self.initialInventory[k] = v
    end

    -- Test state
    self.currentCycle = 0
    self.deltaTime = 0
    self.cycleTime = 3.0  -- 3 seconds per cycle for testing
    self.allocationLog = nil
    self.testPhase = "accumulation"  -- accumulation, allocation, complete

    print("✓ Loaded " .. #self.characters .. " test characters")
    print("✓ Test prototype initialized\n")

    -- Let cravings accumulate before first allocation
    print("Phase 1: Accumulating cravings (3 cycles)...\n")
end

function TestAllocationEngineV2State:loadData()
    print("Loading data files...")

    -- Load consumption mechanics
    local success, result = pcall(function() return DataLoader.loadJSON("data/base/consumption_mechanics.json") end)
    if success and result then
        self.consumptionMechanics = result
        print("  ✓ consumption_mechanics.json")
    else
        print("  ✗ Failed to load consumption_mechanics.json: " .. tostring(result))
        self.consumptionMechanics = {}
    end

    -- Load fulfillment vectors
    success, result = pcall(function() return DataLoader.loadJSON("data/base/craving_system/fulfillment_vectors.json") end)
    if success and result then
        self.fulfillmentVectors = result
        print("  ✓ fulfillment_vectors.json")
    else
        print("  ✗ Failed to load fulfillment_vectors.json: " .. tostring(result))
        self.fulfillmentVectors = {commodities = {}}
    end

    -- Load character traits
    success, result = pcall(function() return DataLoader.loadJSON("data/base/craving_system/character_traits.json") end)
    if success and result then
        self.characterTraits = result
        print("  ✓ character_traits.json")
    else
        print("  ✗ Failed to load character_traits.json: " .. tostring(result))
        self.characterTraits = {traits = {}}
    end

    -- Load character classes
    success, result = pcall(function() return DataLoader.loadJSON("data/base/craving_system/character_classes.json") end)
    if success and result then
        self.characterClasses = result
        print("  ✓ character_classes.json")
    else
        print("  ✗ Failed to load character_classes.json: " .. tostring(result))
        self.characterClasses = {classes = {}}
    end

    -- Load dimension definitions
    success, result = pcall(function() return DataLoader.loadJSON("data/base/craving_system/dimension_definitions.json") end)
    if success and result then
        self.dimensionDefinitions = result
        print("  ✓ dimension_definitions.json")
    else
        print("  ✗ Failed to load dimension_definitions.json: " .. tostring(result))
        self.dimensionDefinitions = {coarseDimensions = {}, fineDimensions = {}}
    end

    -- Load commodity fatigue rates
    success, result = pcall(function() return DataLoader.loadJSON("data/base/craving_system/commodity_fatigue_rates.json") end)
    if success and result then
        self.commodityFatigueRates = result
        print("  ✓ commodity_fatigue_rates.json")
    else
        print("  ✗ Failed to load commodity_fatigue_rates.json: " .. tostring(result))
        self.commodityFatigueRates = {commodities = {}}
    end

    -- Load enablement rules
    success, result = pcall(function() return DataLoader.loadJSON("data/base/craving_system/enablement_rules.json") end)
    if success and result then
        self.enablementRules = result
        print("  ✓ enablement_rules.json")
    else
        print("  ✗ Failed to load enablement_rules.json: " .. tostring(result))
        self.enablementRules = {rules = {}}
    end

    -- Load substitution rules
    success, result = pcall(function() return DataLoader.loadJSON("data/base/substitution_rules.json") end)
    if success and result then
        self.substitutionRules = result
        print("  ✓ substitution_rules.json")
    else
        print("  ✗ Failed to load substitution_rules.json: " .. tostring(result))
        self.substitutionRules = {substitutionHierarchies = {}}
    end

    print("")
end

function TestAllocationEngineV2State:update(dt)
    -- Update cycle timer
    self.deltaTime = self.deltaTime + dt

    -- DEBUG: This should print every frame
    if math.random() < 0.01 then  -- Print 1% of frames to avoid spam
        print(string.format("[DEBUG] update called: cycle=%d, phase=%s, deltaTime=%.2f",
            self.currentCycle, self.testPhase, self.deltaTime))
    end

    if self.deltaTime >= self.cycleTime then
        self.deltaTime = self.deltaTime - self.cycleTime
        self.currentCycle = self.currentCycle + 1

        if self.testPhase == "accumulation" then
            -- Accumulation phase: let cravings build up
            print(string.format("Accumulation cycle %d (deltaTime=%.1f)", self.currentCycle, self.cycleTime))
            for _, char in ipairs(self.characters) do
                char:UpdateCurrentCravings(self.cycleTime)
                char:UpdateSatisfaction(self.currentCycle)

                -- Phase 5: Update individual consequences
                char:UpdateProductivity()
                char:CheckProtest(self.currentCycle)
                char:CheckEmigration(self.currentCycle)
            end

            -- Debug: Check current cravings after this cycle
            if self.currentCycle == 1 then
                local char1 = self.characters[1]
                local totalCurrent = 0
                for i = 0, 48 do
                    totalCurrent = totalCurrent + (char1.currentCravings[i] or 0)
                end
                print(string.format("  After cycle 1: char1 total currentCravings = %.2f", totalCurrent))
            end

            if self.currentCycle >= 3 then
                self.testPhase = "allocation"
                print("\n=== Phase 2: Running Allocation Tests ===\n")
                self:runAllocationTests()
                self.testPhase = "complete"
            end

        elseif self.testPhase == "complete" then
            -- Continue updating characters
            for _, char in ipairs(self.characters) do
                char:UpdateCurrentCravings(self.cycleTime)
                char:UpdateSatisfaction(self.currentCycle)

                -- Phase 5: Update individual consequences
                char:UpdateProductivity()
                char:CheckProtest(self.currentCycle)
                char:CheckEmigration(self.currentCycle)
            end

            -- Phase 5: Check town-level consequences
            local civilUnrest, penalty, protestCount, totalPop = TownConsequences.CheckCivilUnrest(self.characters)
            if civilUnrest then
                print(string.format("⚠️ CIVIL UNREST! %d/%d protesting (%.1f%%), productivity penalty: %.0f%%",
                    protestCount, totalPop, (protestCount/totalPop)*100, penalty*100))
            end

            local riot, damageInfo = TownConsequences.CheckRiot(self.characters, self.currentCycle)
            if riot then
                print(string.format("💥 RIOT! Dissatisfaction: %.1f%%, Inequality: %.1f",
                    damageInfo.dissatisfiedPercentage, damageInfo.inequality))
                local damagedItems = TownConsequences.ApplyRiotDamage(self.townInventory, damageInfo)
                for _, item in ipairs(damagedItems) do
                    print(string.format("  - %s: -%d (remaining: %d)", item.commodity, item.damage, item.remaining))
                end
            end

            local massEmigration, emigrantCount = TownConsequences.CheckMassEmigration(self.characters, self.currentCycle)
            if massEmigration then
                print(string.format("📦 MASS EMIGRATION! %d characters left this cycle", emigrantCount))
            end
        end
    end
end

function TestAllocationEngineV2State:runAllocationTests()
    print("TEST 1: Standard Mode Allocation")
    print("─────────────────────────────────\n")

    -- Show state before allocation
    print("Before Allocation:")
    for i, char in ipairs(self.characters) do
        local coarseCravings = char:AggregateCurrentCravingsToCoarse()
        local avgCraving = 0
        local count = 0
        for _, value in pairs(coarseCravings) do
            avgCraving = avgCraving + value
            count = count + 1
        end
        avgCraving = count > 0 and (avgCraving / count) or 0

        local priority = char:CalculatePriority(self.currentCycle, "standard")
        print(string.format("  %d. %s (%s): Avg Craving=%.1f, Priority=%.2f",
            i, char.name, char.class, avgCraving, priority))
    end
    print("")

    -- Show initial inventory
    print("Initial Inventory:")
    for commodity, quantity in pairs(self.initialInventory) do
        print(string.format("  %s: %d", commodity, quantity))
    end
    print("")

    -- Run allocation cycle
    self.allocationLog = AllocationEngineV2.AllocateCycle(
        self.characters, self.townInventory, self.currentCycle, "standard"
    )

    -- Display results
    print("Allocation Results:")
    print(string.format("  Mode: %s", self.allocationLog.mode))
    print(string.format("  Granted: %d, Substituted: %d, Failed: %d",
        self.allocationLog.stats.granted,
        self.allocationLog.stats.substituted,
        self.allocationLog.stats.failed))
    print("")

    print("Individual Allocations:")
    for _, allocation in ipairs(self.allocationLog.allocations) do
        local statusSymbol = {
            granted = "✓",
            substituted = "→",
            failed = "✗",
            no_needs = "○"
        }
        local symbol = statusSymbol[allocation.status] or "?"

        print(string.format("  %s [Rank %d] %s (%s):",
            symbol, allocation.rank, allocation.characterName, allocation.characterClass))

        if allocation.status == "granted" then
            print(string.format("      Requested: %s → Allocated: %s",
                allocation.requestedCommodity, allocation.allocatedCommodity))
            print(string.format("      Satisfaction Gain: %.2f, Multiplier: %.3f",
                allocation.satisfactionGain, allocation.commodityMultiplier))

        elseif allocation.status == "substituted" then
            print(string.format("      Requested: %s → Substituted: %s",
                allocation.requestedCommodity, allocation.allocatedCommodity))

            if #allocation.substitutionChain > 0 then
                local subInfo = allocation.substitutionChain[2]
                if subInfo then
                    print(string.format("      Efficiency: %.2f, Distance: %.2f, Boost: %.2fx",
                        subInfo.efficiency or 0,
                        subInfo.distance or 0,
                        subInfo.distanceBoost or 1))
                end
            end

            print(string.format("      Satisfaction Gain: %.2f, Multiplier: %.3f",
                allocation.satisfactionGain, allocation.commodityMultiplier))

        elseif allocation.status == "failed" then
            print(string.format("      Requested: %s → FAILED (out of stock)",
                allocation.requestedCommodity))
        end
    end
    print("")

    -- Show inventory after allocation
    print("Inventory After Allocation:")
    for commodity, quantity in pairs(self.townInventory) do
        local initial = self.initialInventory[commodity] or 0
        local consumed = initial - quantity
        if consumed > 0 then
            print(string.format("  %s: %d → %d (-%d consumed)",
                commodity, initial, quantity, consumed))
        end
    end
    print("")

    -- Show character state after allocation
    print("After Allocation:")
    for i, char in ipairs(self.characters) do
        local avgSat = char:GetAverageSatisfaction()
        print(string.format("  %d. %s (%s): Avg Satisfaction=%.1f, Productivity=%.1f%%%s",
            i, char.name, char.class, avgSat, char.productivityMultiplier * 100,
            char.isProtesting and " [PROTESTING]" or (char.hasEmigrated and " [EMIGRATED]" or "")))
    end
    print("")

    -- Display cache statistics
    print("=== Phase 4: Cache Performance ===\n")
    CommodityCache.PrintStats()
    print("")

    -- Display Phase 5 consequences statistics
    print("=== Phase 5: Consequences System ===\n")
    local stats = TownConsequences.CalculateTownStats(self.characters)
    print(string.format("Total Population: %d (Active: %d, Emigrated: %d)",
        stats.totalPopulation, stats.activePopulation, stats.emigratedCount))
    print(string.format("Average Satisfaction: %.1f", stats.averageSatisfaction))
    print(string.format("Average Productivity: %.1f%%", stats.averageProductivity * 100))
    print(string.format("Protesting: %d (%.1f%%)", stats.protestingCount,
        stats.activePopulation > 0 and (stats.protestingCount / stats.activePopulation * 100) or 0))
    print(string.format("Dissatisfied: %d (satisfaction < 40)", stats.dissatisfiedCount))
    print(string.format("Stressed: %d (productivity < 50%%)", stats.stressedCount))
    print("")

    print("By Class:")
    for class, classStats in pairs(stats.byClass) do
        print(string.format("  %s: Count=%d, Avg Satisfaction=%.1f, Avg Productivity=%.1f%%",
            class, classStats.count, classStats.averageSatisfaction or 0,
            (classStats.averageProductivity or 0) * 100))
    end
    print("")

    print("\n=== Test Complete ===")
    print("Press ESC to return to launcher\n")
end

function TestAllocationEngineV2State:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("AllocationEngineV2 Test Prototype", 20, 20)
    love.graphics.print("Phase 3: Allocation Engine Refactor", 20, 40)
    love.graphics.print(string.format("Current Cycle: %d", self.currentCycle), 20, 70)
    love.graphics.print(string.format("Phase: %s", self.testPhase), 20, 90)
    love.graphics.print("Check console for test results", 20, 120)
    love.graphics.print("Press ESC to return to launcher", 20, 150)

    -- Draw character status
    local y = 200
    for i, char in ipairs(self.characters) do
        love.graphics.print(string.format("%d. %s (%s)", i, char.name, char.class), 20, y)

        local coarseCravings = char:AggregateCurrentCravingsToCoarse()
        local avgCraving = 0
        local count = 0
        for _, value in pairs(coarseCravings) do
            avgCraving = avgCraving + value
            count = count + 1
        end
        avgCraving = count > 0 and (avgCraving / count) or 0

        local avgSat = char:GetAverageSatisfaction()

        love.graphics.print(string.format("   Avg Craving: %.1f | Avg Satisfaction: %.1f",
            avgCraving, avgSat), 30, y + 20)

        y = y + 60
    end

    -- Draw allocation results if available
    if self.allocationLog then
        y = y + 20
        love.graphics.print("Last Allocation Results:", 20, y)
        y = y + 25
        love.graphics.print(string.format("Granted: %d | Substituted: %d | Failed: %d",
            self.allocationLog.stats.granted,
            self.allocationLog.stats.substituted,
            self.allocationLog.stats.failed), 30, y)
    end
end

function TestAllocationEngineV2State:keypressed(key)
    if key == "escape" then
        -- This will be handled by main.lua to return to launcher
        return false
    end
end

return TestAllocationEngineV2State
