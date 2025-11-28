-- TestCharacterV2State.lua
-- Test prototype for CharacterV2 6-layer state model

local DataLoader = require("code.DataLoader")
local CharacterV2 = require("code.consumption.CharacterV2")

local TestCharacterV2State = {}

function TestCharacterV2State:enter()
    print("\n=== CharacterV2 Test Prototype ===\n")

    -- Load all required data
    self:loadData()

    -- Initialize CharacterV2 with data
    CharacterV2.Init(
        self.consumptionMechanics,
        self.fulfillmentVectors,
        self.characterTraits,
        self.characterClasses,
        self.dimensionDefinitions,
        self.commodityFatigueRates,
        self.enablementRules
    )

    -- Create test characters
    self.characters = {}
    table.insert(self.characters, CharacterV2:New("Elite", "test_elite_1"))
    table.insert(self.characters, CharacterV2:New("Middle", "test_middle_1"))
    table.insert(self.characters, CharacterV2:New("Lower", "test_lower_1"))

    -- Test state
    self.currentCycle = 0
    self.deltaTime = 0
    self.cycleTime = 2.0  -- 2 seconds per cycle for testing
    self.testPhase = 1
    self.testLog = {}

    print("✓ Loaded " .. #self.characters .. " test characters")
    print("✓ Test prototype initialized\n")

    self:runTests()
end

function TestCharacterV2State:loadData()
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

    print("")
end

function TestCharacterV2State:runTests()
    print("=== Running Phase 2 Tests ===\n")

    -- Test 1: Base Cravings Generation
    self:testBaseCravings()

    -- Test 2: Current Cravings Accumulation
    self:testCurrentCravingsAccumulation()

    -- Test 3: Satisfaction Decay
    self:testSatisfactionDecay()

    -- Test 4: Commodity Fatigue
    self:testCommodityFatigue()

    -- Test 5: Enablement System
    self:testEnablementSystem()

    -- Test 6: Aggregation
    self:testAggregation()

    -- Test 7: Priority Calculation
    self:testPriorityCalculation()

    print("\n=== All Tests Complete ===\n")
end

function TestCharacterV2State:testBaseCravings()
    print("TEST 1: Base Cravings Generation")
    print("─────────────────────────────────")

    for _, char in ipairs(self.characters) do
        local totalBaseCravings = 0
        local count = 0
        for i = 0, 48 do
            totalBaseCravings = totalBaseCravings + (char.baseCravings[i] or 0)
            count = count + 1
        end
        local avgBaseCraving = count > 0 and (totalBaseCravings / count) or 0

        print(string.format("  %s (%s): %.2f avg base craving across 49D",
            char.name, char.class, avgBaseCraving))
    end
    print("")
end

function TestCharacterV2State:testCurrentCravingsAccumulation()
    print("TEST 2: Current Cravings Accumulation")
    print("─────────────────────────────────────")

    -- Simulate 3 cycles of accumulation
    for cycle = 1, 3 do
        for _, char in ipairs(self.characters) do
            char:UpdateCurrentCravings(60.0)  -- 1 full cycle
        end

        -- Print results after cycle
        local char = self.characters[1]  -- Elite character
        local totalCurrent = 0
        for i = 0, 48 do
            totalCurrent = totalCurrent + (char.currentCravings[i] or 0)
        end
        print(string.format("  After cycle %d: %s has %.2f total currentCravings",
            cycle, char.name, totalCurrent))
    end
    print("")
end

function TestCharacterV2State:testSatisfactionDecay()
    print("TEST 3: Satisfaction Decay")
    print("──────────────────────────")

    local char = self.characters[2]  -- Middle class character

    -- Print initial satisfaction
    local avgSat = char:GetAverageSatisfaction()
    print(string.format("  Initial avg satisfaction: %.2f", avgSat))

    -- Simulate 5 cycles of decay
    for cycle = 1, 5 do
        char:UpdateSatisfaction(cycle)
        avgSat = char:GetAverageSatisfaction()
        print(string.format("  After cycle %d: %.2f avg satisfaction", cycle, avgSat))
    end
    print("")
end

function TestCharacterV2State:testCommodityFatigue()
    print("TEST 4: Commodity Fatigue System")
    print("─────────────────────────────────")

    local char = self.characters[3]  -- Lower class character

    -- Consume "bread" multiple times
    print("  Consuming 'bread' 5 times in a row:")
    for i = 1, 5 do
        local success, gain, multiplier = char:FulfillCraving("bread", 1, i)
        if success then
            print(string.format("    Consumption %d: multiplier = %.3f, gain = %.2f",
                i, multiplier, gain))
        end
    end

    -- Wait 11 cycles (cooldown period) and consume again
    print("  After 11-cycle cooldown, consuming bread again:")
    local success, gain, multiplier = char:FulfillCraving("bread", 1, 16)
    if success then
        print(string.format("    Consumption after cooldown: multiplier = %.3f (should be ~1.0)",
            multiplier))
    end
    print("")
end

function TestCharacterV2State:testEnablementSystem()
    print("TEST 5: Enablement System")
    print("─────────────────────────")

    local char = self.characters[1]  -- Elite character

    -- Check if enablement rules exist
    if not self.enablementRules or not self.enablementRules.rules or #self.enablementRules.rules == 0 then
        print("  ⚠ No enablement rules loaded, skipping test")
        print("")
        return
    end

    -- Get first enablement rule
    local ruleId = self.enablementRules.rules[1].id
    print(string.format("  Applying enablement rule: %s", ruleId))

    -- Get base craving for dimension 20 before
    local beforeValue = char.baseCravings[20] or 0

    -- Apply enablement
    local success = char:ApplyEnablement(ruleId, 1)

    if success then
        local afterValue = char.baseCravings[20] or 0
        print(string.format("    BaseCraving[20] before: %.2f, after: %.2f",
            beforeValue, afterValue))
        print("    ✓ Enablement applied successfully")
    else
        print("    ✗ Enablement failed to apply")
    end
    print("")
end

function TestCharacterV2State:testAggregation()
    print("TEST 6: Fine → Coarse Aggregation")
    print("──────────────────────────────────")

    local char = self.characters[2]  -- Middle class character

    -- Aggregate current cravings to coarse
    local coarseCravings = char:AggregateCurrentCravingsToCoarse()

    print("  Coarse cravings (9D) aggregated from fine (49D):")
    for i = 0, 8 do
        local coarseName = CharacterV2.coarseNames[i]
        if coarseName and coarseCravings[coarseName] then
            print(string.format("    %s: %.2f", coarseName, coarseCravings[coarseName]))
        end
    end
    print("")
end

function TestCharacterV2State:testPriorityCalculation()
    print("TEST 7: Priority Calculation")
    print("────────────────────────────")

    -- Calculate priority for each character
    for _, char in ipairs(self.characters) do
        local priority = char:CalculatePriority(self.currentCycle, "standard")
        print(string.format("  %s (%s): priority = %.2f",
            char.name, char.class, priority))
    end

    -- Test fairness mode
    print("\n  Testing fairness mode (simulating allocation failure):")
    local char = self.characters[1]
    char:RecordAllocationAttempt(false, 1)  -- Failed attempt
    char:RecordAllocationAttempt(false, 2)  -- Failed attempt
    local priorityBefore = char:CalculatePriority(3, "standard")
    local priorityFairness = char:CalculatePriority(3, "fairness")
    print(string.format("    Standard priority: %.2f", priorityBefore))
    print(string.format("    Fairness priority: %.2f (with penalty)", priorityFairness))
    print("")
end

function TestCharacterV2State:update(dt)
    -- Update cycle timer
    self.deltaTime = self.deltaTime + dt

    if self.deltaTime >= self.cycleTime then
        self.deltaTime = self.deltaTime - self.cycleTime
        self.currentCycle = self.currentCycle + 1

        -- Update all characters
        for _, char in ipairs(self.characters) do
            char:UpdateCurrentCravings(self.cycleTime)
            char:UpdateSatisfaction(self.currentCycle)
        end
    end
end

function TestCharacterV2State:draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("CharacterV2 Test Prototype", 20, 20)
    love.graphics.print("Check console for test results", 20, 40)
    love.graphics.print(string.format("Current Cycle: %d", self.currentCycle), 20, 70)
    love.graphics.print("Press ESC to exit", 20, 100)

    -- Draw character status
    local y = 140
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
end

function TestCharacterV2State:keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

return TestCharacterV2State
