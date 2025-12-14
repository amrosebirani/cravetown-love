-- CharacterV2.lua
-- Complete 6-layer character state model for consumption system
-- Layers: Identity → Base Cravings → Current Cravings → Satisfaction → Commodity Multipliers → History

Character = Character or {}  -- Preserve table across hot reloads
Character.__index = Character

-- Data stored on Character table (survives hot reload)
-- These were previously module-level locals which got reset on hot reload
Character._ConsumptionMechanics = Character._ConsumptionMechanics or nil
Character._FulfillmentVectors = Character._FulfillmentVectors or nil
Character._CharacterTraits = Character._CharacterTraits or nil
Character._CharacterClasses = Character._CharacterClasses or nil
Character._DimensionDefinitions = Character._DimensionDefinitions or nil
Character._CommodityFatigueRates = Character._CommodityFatigueRates or nil
Character._EnablementRules = Character._EnablementRules or nil

-- Initialize data (called once at prototype start)
function Character.Init(mechanicsData, fulfillmentData, traitsData, classesData, dimensionsData, fatigueData, enablementData)
    Character._ConsumptionMechanics = mechanicsData
    Character._FulfillmentVectors = fulfillmentData
    Character._CharacterTraits = traitsData
    Character._CharacterClasses = classesData
    Character._DimensionDefinitions = dimensionsData
    Character._CommodityFatigueRates = fatigueData
    Character._EnablementRules = enablementData

    -- Build fine->coarse mapping for fast lookup
    Character.BuildDimensionMaps()
end

-- Build mapping from fine dimension index to coarse dimension
function Character.BuildDimensionMaps()
    Character.fineToCoarseMap = {}
    Character.coarseNames = {}
    Character.coarseNameToIndex = {}
    Character.coarseToFineMap = {}
    Character.fineNames = {}

    if not Character._DimensionDefinitions then return end

    -- Map coarse dimension indices to names and vice versa
    for _, coarseDim in ipairs(Character._DimensionDefinitions.coarseDimensions) do
        Character.coarseNames[coarseDim.index] = coarseDim.id
        Character.coarseNameToIndex[coarseDim.id] = coarseDim.index
    end

    -- Map fine dimensions to their parent coarse and store aggregation weights
    Character.fineAggregationWeights = {}  -- fineIndex -> aggregationWeight
    Character.coarseWeightSums = {}  -- coarseIndex -> sum of weights for normalization

    for _, fineDim in ipairs(Character._DimensionDefinitions.fineDimensions) do
        Character.fineNames[fineDim.index] = fineDim.id
        -- Store aggregation weight (default to 1.0 if not specified)
        Character.fineAggregationWeights[fineDim.index] = fineDim.aggregationWeight or 1.0

        -- Convert parent coarse name to index
        local parentCoarseIndex = Character.coarseNameToIndex[fineDim.parentCoarse]
        if parentCoarseIndex then
            Character.fineToCoarseMap[fineDim.index] = parentCoarseIndex
            -- Accumulate weight sums for each coarse dimension
            Character.coarseWeightSums[parentCoarseIndex] = (Character.coarseWeightSums[parentCoarseIndex] or 0) + (fineDim.aggregationWeight or 1.0)
        else
            print("Warning: Unknown parent coarse '" .. tostring(fineDim.parentCoarse) .. "' for fine dimension " .. tostring(fineDim.index))
        end
    end

    -- Build coarse to fine mapping (array of fine indices for each coarse)
    -- This correctly handles non-contiguous fine dimension indices
    local coarseCount = #Character._DimensionDefinitions.coarseDimensions
    local fineCount = #Character._DimensionDefinitions.fineDimensions

    for coarseIdx = 0, coarseCount - 1 do
        Character.coarseToFineMap[coarseIdx] = {}
    end

    for fineIdx = 0, fineCount - 1 do
        local coarseIdx = Character.fineToCoarseMap[fineIdx]
        if coarseIdx ~= nil then
            table.insert(Character.coarseToFineMap[coarseIdx], fineIdx)
        end
    end

    -- Debug output
    print("CharacterV2 dimension maps built:")
    print("  Coarse dimensions: " .. coarseCount)
    print("  Fine dimensions: " .. fineCount)
    print("  coarseToFineMap entries: " .. tostring(#Character.coarseToFineMap))
    for idx, fineIndices in pairs(Character.coarseToFineMap) do
        local name = Character.coarseNames[idx] or "unknown"
        print(string.format("    [%d] %s: %d fine dimensions [%s]", idx, name, #fineIndices, table.concat(fineIndices, ", ")))
    end
end

-- Generate a new character
function Character:New(class, id)
    local char = setmetatable({}, Character)

    -- =============================================================================
    -- LAYER 1: Base Identity (static)
    -- =============================================================================
    char.id = id or "char_" .. tostring(math.random(100000, 999999))
    char.name = Character.GenerateRandomName()
    char.age = math.random(18, 65)
    char.class = class or "Middle"
    char.vocation = Character.GetRandomVocation()
    char.traits = Character.GetRandomTraits(2, char.class)

    -- =============================================================================
    -- LAYER 2: Base Cravings (quasi-static, 49D fine-grained)
    -- =============================================================================
    -- These are the character's baseline craving rates per cycle
    char.baseCravings = Character.GenerateBaseCravings(char.class, char.traits)

    -- =============================================================================
    -- LAYER 3: Current Cravings (49D fine-grained accumulation tracker)
    -- =============================================================================
    -- Accumulates based on baseCravings, resets when satisfied
    -- Initialize with several cycles worth of cravings so characters can consume
    -- multiple resources per cycle from the start
    char.currentCravings = {}
    local startingCravingMultiplier = 10  -- Start with 10 cycles worth of accumulated cravings
    for i = 0, 48 do
        local baseRate = char.baseCravings[i] or 0
        char.currentCravings[i] = baseRate * startingCravingMultiplier
    end

    -- =============================================================================
    -- LAYER 4: Satisfaction State (9D coarse, lifetime happiness tracker)
    -- =============================================================================
    -- Derived from currentCravings fulfillment, ranges -100 to 300
    char.satisfaction = Character.GenerateStartingSatisfaction(char.class)

    -- =============================================================================
    -- LAYER 5: Commodity Multipliers (fatigue system, 0.0 to 1.0)
    -- =============================================================================
    -- Tracks fatigue for each commodity (personalized variety-seeking)
    char.commodityMultipliers = {}  -- [commodityId] = {multiplier, consecutiveCount, lastConsumed}

    -- =============================================================================
    -- LAYER 6: Consumption History (last 20 decisions)
    -- =============================================================================
    char.consumptionHistory = {}  -- Array of {cycle, commodity, quantity, gain, multiplier}
    char.maxHistoryLength = 20

    -- =============================================================================
    -- LAYER 7: Active Effects (durable goods providing ongoing satisfaction)
    -- =============================================================================
    -- Tracks owned durable/permanent goods that provide passive satisfaction each cycle
    char.activeEffects = {}
    --[[
      Each effect entry:
      {
        commodityId = "bed",              -- Which commodity this effect is from
        category = "furniture_sleep",     -- Category for slot management
        durability = "durable",           -- "durable" or "permanent"
        acquiredCycle = 50,               -- When it was acquired
        durationCycles = 500,             -- Original duration (nil for permanent)
        remainingCycles = 450,            -- Cycles left (nil for permanent)
        effectDecayRate = 0.001,          -- How fast effectiveness decreases
        currentEffectiveness = 0.95,      -- 1.0 to 0.0, decays over time
        fulfillmentVector = {...},        -- Cached fine vector from commodity
        maxOwned = 1                      -- Max allowed in this category
      }
    ]]

    -- =============================================================================
    -- Enablement State (tracks which rules have been applied)
    -- =============================================================================
    char.appliedEnablements = {}  -- Set of enablement rule IDs that have been applied
    char.enablementTriggers = {}  -- Tracks conditions for enablement triggers

    -- =============================================================================
    -- Allocation State
    -- =============================================================================
    char.allocationPriority = 0
    char.lastAllocationCycle = 0
    char.allocationSuccessRate = 0.5
    char.successCount = 0
    char.attemptCount = 0
    char.fairnessPenalty = 0

    -- =============================================================================
    -- Emigration tracking
    -- =============================================================================
    char.consecutiveLowSatisfactionCycles = 0
    char.emigrationThreshold = 30  -- Will be set from config
    char.hasEmigrated = false

    -- =============================================================================
    -- Phase 5: Productivity and Protest tracking
    -- =============================================================================
    char.productivityMultiplier = 1.0  -- 1.0 = full productivity, 0.0 = no work
    char.consecutiveFailedAllocations = 0  -- Track failures for protest trigger
    char.isProtesting = false  -- Whether character is actively protesting

    -- =============================================================================
    -- Visual state
    -- =============================================================================
    char.position = {x = 0, y = 0}
    char.highlighted = false
    char.status = "idle"  -- idle/happy/stressed/leaving/variety_seeking
    char.statusMessage = ""

    return char
end

-- =============================================================================
-- LAYER 2: Base Cravings Generation
-- =============================================================================

function Character.GenerateBaseCravings(class, traits)
    local baseCravings = {}

    -- Normalize class to lowercase for comparison
    local classLower = string.lower(class or "middle")
    print(string.format("GenerateBaseCravings called with class='%s' (normalized: '%s')", tostring(class), classLower))

    if not Character._CharacterClasses or not Character._CharacterClasses.classes then
        -- Fallback: uniform distribution
        print("  Warning: CharacterClasses not loaded, using fallback")
        for i = 0, 48 do
            baseCravings[i] = 1.0
        end
        return baseCravings
    end

    -- Find class data (case-insensitive comparison)
    local classData = nil
    for _, c in ipairs(Character._CharacterClasses.classes) do
        if string.lower(c.id) == classLower then
            classData = c
            break
        end
    end

    if not classData then
        print(string.format("  Warning: Class '%s' not found, using fallback", tostring(class)))
        for i = 0, 48 do
            baseCravings[i] = 1.0
        end
        return baseCravings
    end

    if not classData.baseCravingVector or not classData.baseCravingVector.fine then
        print("  Warning: baseCravingVector.fine not found, using fallback")
        for i = 0, 48 do
            baseCravings[i] = 1.0
        end
        return baseCravings
    end

    print(string.format("  Found class data for '%s', loading base cravings", class))
    print(string.format("  Fine vector has %d elements", #classData.baseCravingVector.fine))

    -- Copy fine-grained base cravings from class
    for i = 0, 48 do
        baseCravings[i] = classData.baseCravingVector.fine[i + 1] or 0  -- Lua 1-indexed
    end

    -- Debug: print first few base cravings
    print(string.format("  Base cravings [0-4]: %.2f, %.2f, %.2f, %.2f, %.2f",
        baseCravings[0] or 0, baseCravings[1] or 0, baseCravings[2] or 0,
        baseCravings[3] or 0, baseCravings[4] or 0))

    -- Apply trait multipliers to base cravings
    if traits and #traits > 0 and Character._CharacterTraits and Character._CharacterTraits.traits then
        print(string.format("  Applying %d traits: %s", #traits, table.concat(traits, ", ")))
        for _, traitId in ipairs(traits) do
            local traitIdLower = string.lower(traitId)
            local foundTrait = false
            for _, traitData in ipairs(Character._CharacterTraits.traits) do
                if string.lower(traitData.id) == traitIdLower and traitData.cravingMultipliers and traitData.cravingMultipliers.fine then
                    print(string.format("    Applying trait '%s' multipliers", traitData.id))
                    for i = 0, 48 do
                        local multiplier = traitData.cravingMultipliers.fine[i + 1] or 1.0
                        baseCravings[i] = baseCravings[i] * multiplier
                    end
                    foundTrait = true
                    break
                end
            end
            if not foundTrait then
                print(string.format("    Warning: Trait '%s' not found in CharacterTraits", traitId))
            end
        end
    else
        print("  No traits to apply or CharacterTraits not loaded")
    end

    -- Debug: print first few base cravings after traits
    print(string.format("  Final cravings [0-4]: %.2f, %.2f, %.2f, %.2f, %.2f",
        baseCravings[0] or 0, baseCravings[1] or 0, baseCravings[2] or 0,
        baseCravings[3] or 0, baseCravings[4] or 0))

    return baseCravings
end

-- =============================================================================
-- LAYER 4: Generate Starting Satisfaction (coarse 9D)
-- =============================================================================

function Character.GenerateStartingSatisfaction(class)
    local satisfaction = {}

    -- Convert class to lowercase for JSON lookup (JSON uses "elite", code uses "Elite")
    local classKey = string.lower(class)
    -- Map "working" and "poor" to "lower" class ranges (JSON only has elite/upper/middle/lower)
    if classKey == "working" or classKey == "poor" then
        classKey = "lower"
    end

    -- Use consumption_mechanics starting ranges (coarse)
    if Character._ConsumptionMechanics and Character._ConsumptionMechanics.characterGeneration and
       Character._ConsumptionMechanics.characterGeneration.startingSatisfactionRanges and
       Character._ConsumptionMechanics.characterGeneration.startingSatisfactionRanges[classKey] then
        local ranges = Character._ConsumptionMechanics.characterGeneration.startingSatisfactionRanges[classKey]
        for cravingType, range in pairs(ranges) do
            satisfaction[cravingType] = math.random(range[1], range[2])
        end
    else
        -- Fallback: all at 50
        for i = 0, 8 do
            local coarseName = Character.coarseNames[i] or "unknown"
            satisfaction[coarseName] = 50
        end
    end

    return satisfaction
end

-- =============================================================================
-- LAYER 3: Update Current Cravings (Accumulation)
-- =============================================================================

function Character:UpdateCurrentCravings(deltaTime)
    -- Accumulate cravings based on baseCravings decay rates
    -- currentCravings += baseCravings * (deltaTime / cycleTime)

    local cycleTime = 60.0  -- 60 seconds per cycle
    local ratio = deltaTime / cycleTime

    -- Max craving is relative to base craving (e.g., 50x base rate)
    -- This represents the maximum intensity a craving can reach
    -- Once capped, satisfaction continues to decay but craving intensity plateaus
    local maxCravingMultiplier = 50.0

    for i = 0, 48 do
        local baseRate = self.baseCravings[i] or 0
        local maxCraving = math.max(baseRate * maxCravingMultiplier, 50)  -- At least 50, or 50x base

        self.currentCravings[i] = self.currentCravings[i] + (baseRate * ratio)

        -- Cap at max craving for this dimension
        self.currentCravings[i] = math.min(self.currentCravings[i], maxCraving)
    end
end

-- =============================================================================
-- LAYER 4: Update Satisfaction (Lifetime Tracker)
-- =============================================================================

function Character:UpdateSatisfaction(currentCycle)
    -- Satisfaction decays naturally over time based on currentCravings
    -- Higher unfulfilled currentCravings = faster satisfaction decay

    if not Character._ConsumptionMechanics or not Character._ConsumptionMechanics.cravingDecayRates then
        return
    end

    local decayRates = Character._ConsumptionMechanics.cravingDecayRates

    -- Decay each coarse dimension based on its unfulfilled currentCravings
    for coarseIndex = 0, 8 do
        local coarseName = Character.coarseNames[coarseIndex]
        if coarseName and self.satisfaction[coarseName] then
            -- Calculate average unfulfilled currentCravings for this coarse dimension
            local totalCraving = 0
            local count = 0

            for fineIndex = 0, 48 do
                if Character.fineToCoarseMap[fineIndex] == coarseName then
                    totalCraving = totalCraving + (self.currentCravings[fineIndex] or 0)
                    count = count + 1
                end
            end

            local avgCraving = count > 0 and (totalCraving / count) or 0

            -- Decay rate accelerates with unfulfilled cravings
            local baseDecay = decayRates[coarseName] and decayRates[coarseName][self.class] or 2.0
            local cravingMultiplier = 1.0 + (avgCraving / 50.0)  -- More craving = faster decay
            local decay = baseDecay * cravingMultiplier

            self.satisfaction[coarseName] = self.satisfaction[coarseName] - decay

            -- Clamp to range [-100, 300]
            self.satisfaction[coarseName] = math.max(-100, math.min(300, self.satisfaction[coarseName]))
        end
    end
end

-- =============================================================================
-- LAYER 5: Calculate Commodity Multiplier (Personalized Fatigue)
-- =============================================================================

function Character:CalculateCommodityMultiplier(commodity, currentCycle)
    local history = self.commodityMultipliers[commodity]

    if not history then
        -- First time consuming this commodity
        return 1.0
    end

    local consecutiveCount = history.consecutiveCount or 0
    local cyclesSinceLast = currentCycle - (history.lastConsumed or 0)

    -- Get commodity-specific fatigue config
    local baseFatigueRate = 0.12  -- default
    local traitModifier = 1.0

    if Character._CommodityFatigueRates and Character._CommodityFatigueRates.commodities and
       Character._CommodityFatigueRates.commodities[commodity] then
        local fatigueData = Character._CommodityFatigueRates.commodities[commodity]
        baseFatigueRate = fatigueData.baseFatigueRate or baseFatigueRate

        -- Apply trait-specific modifiers
        if fatigueData.fatigueModifiers and self.traits then
            for _, traitId in ipairs(self.traits) do
                if fatigueData.fatigueModifiers[traitId] then
                    traitModifier = traitModifier * fatigueData.fatigueModifiers[traitId]
                end
            end
        end
    end

    local effectiveFatigueRate = baseFatigueRate * traitModifier

    -- Check if enough time has passed for cooldown
    local cooldownCycles = Character._ConsumptionMechanics and
                          Character._ConsumptionMechanics.commodityDiminishingReturns and
                          Character._ConsumptionMechanics.commodityDiminishingReturns.varietyCooldownCycles or 10

    if cyclesSinceLast > cooldownCycles then
        -- Reset fatigue
        return 1.0
    end

    -- Calculate fatigue multiplier using exponential decay
    -- multiplier = exp(-consecutiveCount * effectiveFatigueRate)
    local multiplier = math.exp(-consecutiveCount * effectiveFatigueRate)

    -- Apply min threshold
    local minMultiplier = Character._ConsumptionMechanics and
                         Character._ConsumptionMechanics.commodityDiminishingReturns and
                         Character._ConsumptionMechanics.commodityDiminishingReturns.minMultiplier or 0.25

    multiplier = math.max(minMultiplier, multiplier)

    return multiplier
end

-- =============================================================================
-- LAYER 5: Update Commodity Multiplier History
-- =============================================================================

function Character:UpdateCommodityHistory(commodity, currentCycle)
    if not self.commodityMultipliers[commodity] then
        self.commodityMultipliers[commodity] = {
            consecutiveCount = 1,
            lastConsumed = currentCycle,
            multiplier = 1.0
        }
    else
        local history = self.commodityMultipliers[commodity]
        local cyclesSinceLast = currentCycle - history.lastConsumed

        local cooldownCycles = Character._ConsumptionMechanics and
                              Character._ConsumptionMechanics.commodityDiminishingReturns and
                              Character._ConsumptionMechanics.commodityDiminishingReturns.varietyCooldownCycles or 10

        if cyclesSinceLast <= cooldownCycles then
            -- Still in fatigue period
            history.consecutiveCount = history.consecutiveCount + 1
        else
            -- Cooldown expired, reset
            history.consecutiveCount = 1
        end

        history.lastConsumed = currentCycle
    end

    -- Decay other commodities' consecutive counts over time
    local decayCycles = Character._ConsumptionMechanics and
                       Character._ConsumptionMechanics.commodityDiminishingReturns and
                       Character._ConsumptionMechanics.commodityDiminishingReturns.otherCommodityDecayCycles or 3

    local decayRate = Character._ConsumptionMechanics and
                     Character._ConsumptionMechanics.commodityDiminishingReturns and
                     Character._ConsumptionMechanics.commodityDiminishingReturns.otherCommodityDecayRate or 1

    for otherCommodity, otherHistory in pairs(self.commodityMultipliers) do
        if otherCommodity ~= commodity then
            local cyclesSince = currentCycle - otherHistory.lastConsumed
            if cyclesSince >= decayCycles then
                otherHistory.consecutiveCount = math.max(0, otherHistory.consecutiveCount - decayRate)
            end
        end
    end
end

-- =============================================================================
-- LAYER 3 & 4: Fulfill Craving (Consume Commodity)
-- =============================================================================

function Character:FulfillCraving(commodity, quantity, currentCycle, allocationType)
    allocationType = allocationType or "consumed"  -- Default to consumed for backward compatibility

    if not Character._FulfillmentVectors or not Character._FulfillmentVectors.commodities then
        print("Error: Character._FulfillmentVectors not initialized")
        return false, 0, 1.0
    end

    local commodityData = Character._FulfillmentVectors.commodities[commodity]
    if not commodityData then
        print("Warning: No fulfillment data for commodity: " .. commodity)
        return false, 0, 1.0
    end

    -- LAYER 5: Get commodity-specific fatigue multiplier
    local fatigueMultiplier = self:CalculateCommodityMultiplier(commodity, currentCycle)

    -- Get quality multiplier (default to basic)
    local qualityMultipliers = commodityData.qualityMultipliers or {basic = 1.0}
    local qualityMultiplier = qualityMultipliers.basic or 1.0

    -- Use fine-grained fulfillment vector (49D)
    local fineVector = commodityData.fulfillmentVector.fine
    if not fineVector then
        print("Warning: No fine fulfillment vector for: " .. commodity)
        return false, 0, fatigueMultiplier
    end

    -- LAYER 3: Reduce currentCravings (fine-grained)
    local totalCravingReduction = 0
    for fineDimId, points in pairs(fineVector) do
        if points and points > 0 then
            -- Find fine dimension index
            local fineIndex = nil
            for idx, name in pairs(Character.fineNames) do
                if name == fineDimId then
                    fineIndex = idx
                    break
                end
            end

            if fineIndex then
                local gain = points * qualityMultiplier * fatigueMultiplier * quantity
                local oldValue = self.currentCravings[fineIndex] or 0
                self.currentCravings[fineIndex] = math.max(0, oldValue - gain)
                totalCravingReduction = totalCravingReduction + gain
            end
        end
    end

    -- LAYER 4: Increase satisfaction (coarse-grained, derived from craving reduction)
    -- Aggregate the fine reductions to coarse dimensions
    for fineIndex, cravingValue in pairs(self.currentCravings) do
        local coarseName = Character.fineToCoarseMap[fineIndex]
        if coarseName then
            -- If this fine dimension was satisfied, boost its parent coarse satisfaction
            local fineDimId = Character.fineNames[fineIndex]
            if fineVector[fineDimId] and fineVector[fineDimId] > 0 then
                local boost = fineVector[fineDimId] * qualityMultiplier * fatigueMultiplier * quantity * 0.5
                self.satisfaction[coarseName] = math.min(300, (self.satisfaction[coarseName] or 0) + boost)
            end
        end
    end

    -- LAYER 5: Update commodity fatigue history
    self:UpdateCommodityHistory(commodity, currentCycle)

    -- LAYER 6: Add to consumption history
    table.insert(self.consumptionHistory, 1, {
        cycle = currentCycle,
        commodity = commodity,
        quantity = quantity,
        cravingReduction = totalCravingReduction,
        fatigueMultiplier = fatigueMultiplier,
        allocationType = allocationType  -- "consumed" or "acquired"
    })

    -- Trim history to max length
    while #self.consumptionHistory > self.maxHistoryLength do
        table.remove(self.consumptionHistory)
    end

    -- Visual feedback
    local varietyThreshold = Character._ConsumptionMechanics and
                            Character._ConsumptionMechanics.commodityDiminishingReturns and
                            Character._ConsumptionMechanics.commodityDiminishingReturns.varietySeekingThreshold or 0.70

    if fatigueMultiplier < varietyThreshold then
        self.status = "variety_seeking"
        self.statusMessage = "🔁 Tired of " .. commodity
    else
        self.status = "happy"
        self.statusMessage = ""
    end

    return true, totalCravingReduction, fatigueMultiplier
end

-- =============================================================================
-- Enablement System: Apply Enablement Rules
-- =============================================================================

function Character:ApplyEnablement(ruleId, currentCycle)
    -- Check if already applied
    if self.appliedEnablements[ruleId] then
        return false
    end

    if not Character._EnablementRules or not Character._EnablementRules.rules then
        return false
    end

    -- Find the rule
    local rule = nil
    for _, r in ipairs(Character._EnablementRules.rules) do
        if r.id == ruleId then
            rule = r
            break
        end
    end

    if not rule or not rule.effect or not rule.effect.cravingModifier then
        return false
    end

    -- Apply fine-grained craving modifier to baseCravings
    local fineModifier = rule.effect.cravingModifier.fine
    if fineModifier then
        for i = 0, 48 do
            local modifier = fineModifier[i + 1] or 0  -- Lua 1-indexed
            if modifier ~= 0 then
                self.baseCravings[i] = self.baseCravings[i] + modifier
                self.baseCravings[i] = math.max(0, self.baseCravings[i])  -- Can't be negative
            end
        end
    end

    -- Mark as applied (if permanent)
    if rule.effect.permanent == nil or rule.effect.permanent then
        self.appliedEnablements[ruleId] = currentCycle
    end

    return true
end

-- =============================================================================
-- Aggregation: Fine → Coarse (for display/analytics)
-- =============================================================================

function Character:AggregateCurrentCravingsToCoarse()
    local coarseCravings = {}

    for coarseIndex = 0, 8 do
        local coarseName = Character.coarseNames[coarseIndex]
        if coarseName then
            local total = 0
            local count = 0
            local totalWeight = 0

            for fineIndex = 0, 48 do
                -- Fixed: compare coarseIndex (number) to fineToCoarseMap (number), not to coarseName (string)
                if Character.fineToCoarseMap[fineIndex] == coarseIndex then
                    -- Use aggregationWeight from dimension definitions
                    local weight = Character.fineAggregationWeights[fineIndex] or 1.0
                    total = total + (self.currentCravings[fineIndex] or 0) * weight
                    totalWeight = totalWeight + weight
                    count = count + 1
                end
            end

            -- Normalize by dividing by sum of weights
            coarseCravings[coarseName] = totalWeight > 0 and (total / totalWeight) or 0
        end
    end

    return coarseCravings
end

-- =============================================================================
-- Priority Calculation (with fairness modes)
-- =============================================================================

function Character:CalculatePriority(currentCycle, allocationMode)
    if not Character._ConsumptionMechanics or not Character._ConsumptionMechanics.priorityCalculation then
        return 100
    end

    local config = Character._ConsumptionMechanics.priorityCalculation

    -- Phase 5: Priority is based purely on desperation (unfulfilled cravings)
    -- Class is NOT used for priority - only for quality acceptance and consumption budgets

    -- Aggregate current cravings to coarse for priority calculation
    local coarseCravings = self:AggregateCurrentCravingsToCoarse()

    -- Calculate desperation score based on coarse cravings
    local desperationScore = 0
    for coarseName, cravingValue in pairs(coarseCravings) do
        local cravingWeight = config.cravingPriorityWeights[coarseName] or 0.5

        -- Determine desperation level based on craving value
        local desperationMultiplier = 0
        if cravingValue > 100 then
            desperationMultiplier = config.desperationMultipliers.critical or 10.0
        elseif cravingValue > 60 then
            desperationMultiplier = config.desperationMultipliers.low or 5.0
        elseif cravingValue > 30 then
            desperationMultiplier = config.desperationMultipliers.medium or 2.0
        elseif cravingValue > 10 then
            desperationMultiplier = config.desperationMultipliers.high or 1.0
        else
            desperationMultiplier = config.desperationMultipliers.satisfied or 0.1
        end

        desperationScore = desperationScore + (desperationMultiplier * cravingWeight)
    end

    -- Priority is purely based on desperation (no class weight)
    local basePriority = desperationScore

    -- Apply fairness penalty if in fairness mode
    local finalPriority = basePriority
    if allocationMode == "fairness" then
        finalPriority = basePriority - self.fairnessPenalty
    end

    self.allocationPriority = finalPriority
    return finalPriority
end

-- Check if character accepts a given quality level
-- Phase 5: Class-based quality acceptance from behavior templates
-- Uses emergent class for quality acceptance (not initial/template class)
-- TODO: Define quality tiers properly at commodity level, production level, and inventory level
function Character:AcceptsQuality(quality)
    if not quality then
        return true  -- No quality specified = accept
    end

    -- Phase 5: Use emergent class for quality acceptance
    local effectiveClass = self:GetEffectiveClass()

    -- Find class data for this character's emergent class
    local classData = nil
    if Character._CharacterClasses and Character._CharacterClasses.classes then
        local classLower = string.lower(effectiveClass or "middle")
        for _, c in ipairs(Character._CharacterClasses.classes) do
            if string.lower(c.id) == classLower then
                classData = c
                break
            end
        end
    end

    -- If no class data found, accept all qualities
    if not classData then
        return true
    end

    local qualityLower = string.lower(quality)

    -- Check rejected qualities first
    if classData.rejectedQualityTiers then
        for _, rejectedTier in ipairs(classData.rejectedQualityTiers) do
            if string.lower(rejectedTier) == qualityLower then
                return false  -- Quality is explicitly rejected
            end
        end
    end

    -- Check accepted qualities
    if classData.acceptedQualityTiers and #classData.acceptedQualityTiers > 0 then
        for _, acceptedTier in ipairs(classData.acceptedQualityTiers) do
            if string.lower(acceptedTier) == qualityLower then
                return true  -- Quality is explicitly accepted
            end
        end
        -- Has accepted list but quality not in it = reject
        return false
    end

    -- No accepted list = accept all (except rejected)
    return true
end

-- Get the current effective class (emergent if available, else assigned)
-- CharacterV2 doesn't track emergent class, so returns assigned class
function Character:GetEffectiveClass()
    return self.emergentClass or self.class or "middle"
end

-- =============================================================================
-- Utility Functions
-- =============================================================================

function Character.GenerateRandomName()
    if not Character._ConsumptionMechanics or not Character._ConsumptionMechanics.names then
        return "Character_" .. math.random(1000, 9999)
    end

    local first = Character._ConsumptionMechanics.names.first
    local last = Character._ConsumptionMechanics.names.last
    return first[math.random(#first)] .. " " .. last[math.random(#last)]
end

function Character.GetRandomVocation()
    if not Character._ConsumptionMechanics or not Character._ConsumptionMechanics.vocations then
        return "Worker"
    end

    local vocations = Character._ConsumptionMechanics.vocations
    return vocations[math.random(#vocations)]
end

function Character.GetRandomTraits(count, class)
    if not Character._ConsumptionMechanics or not Character._ConsumptionMechanics.characterGeneration or
       not Character._ConsumptionMechanics.characterGeneration.traits or
       not Character._ConsumptionMechanics.characterGeneration.traits.available then
        return {}
    end

    local availableTraits = Character._ConsumptionMechanics.characterGeneration.traits.available
    local selected = {}
    local indices = {}

    while #selected < count and #selected < #availableTraits do
        local idx = math.random(#availableTraits)
        if not indices[idx] then
            indices[idx] = true
            table.insert(selected, availableTraits[idx].id)
        end
    end

    return selected
end

function Character:GetAverageSatisfaction()
    -- Only average the 9 coarse dimensions explicitly
    local coarseKeys = {
        "biological", "safety", "touch", "psychological",
        "social_status", "social_connection", "exotic_goods",
        "shiny_objects", "vice"
    }

    local sum = 0
    local count = 0
    for _, key in ipairs(coarseKeys) do
        local value = self.satisfaction[key]
        if value then
            sum = sum + value
            count = count + 1
        end
    end
    return count > 0 and (sum / count) or 0
end

function Character:GetCriticalCravingCount()
    local count = 0
    local coarseCravings = self:AggregateCurrentCravingsToCoarse()
    for _, value in pairs(coarseCravings) do
        if value > 80 then  -- Critical threshold
            count = count + 1
        end
    end
    return count
end

function Character:CheckEmigration(currentCycle)
    if self.hasEmigrated then
        return false
    end

    if not Character._ConsumptionMechanics or not Character._ConsumptionMechanics.consequenceThresholds or
       not Character._ConsumptionMechanics.consequenceThresholds.emigration then
        return false
    end

    local config = Character._ConsumptionMechanics.consequenceThresholds.emigration
    if not config.enabled then
        return false
    end

    local avgSatisfaction = self:GetAverageSatisfaction()

    -- Track low satisfaction cycles
    local threshold = config.averageSatisfactionThreshold[self.class] or 30
    if avgSatisfaction < threshold then
        self.consecutiveLowSatisfactionCycles = self.consecutiveLowSatisfactionCycles + 1
    else
        self.consecutiveLowSatisfactionCycles = 0
    end

    -- Check emigration conditions
    local criticalCount = self:GetCriticalCravingCount()
    local cycleThreshold = config.consecutiveLowSatisfactionCycles[self.class] or 5

    if self.consecutiveLowSatisfactionCycles >= cycleThreshold and
       criticalCount >= (config.criticalCravingsRequired or 2) then
        -- Roll for emigration
        if math.random() < (config.emigrationChancePerCycle or 0.1) then
            self.hasEmigrated = true
            self.status = "leaving"
            self.statusMessage = "💼 Emigrating"
            return true
        end
    end

    return false
end

function Character:RecordAllocationAttempt(success, currentCycle)
    self.attemptCount = self.attemptCount + 1
    if success then
        self.successCount = self.successCount + 1
        -- Reset fairness penalty on success
        self.fairnessPenalty = 0
        -- Reset consecutive failures
        self.consecutiveFailedAllocations = 0
    else
        -- Increase fairness penalty on failure
        self.fairnessPenalty = self.fairnessPenalty + 50
        -- Track consecutive failures for protest
        self.consecutiveFailedAllocations = self.consecutiveFailedAllocations + 1
    end
    self.allocationSuccessRate = self.successCount / self.attemptCount
    self.lastAllocationCycle = currentCycle
end

-- =============================================================================
-- Phase 5: Productivity Degradation
-- =============================================================================

function Character:UpdateProductivity()
    -- Productivity degrades linearly when average satisfaction < 50
    -- Formula: productivityMultiplier = avgSatisfaction / 50 (when < 50)
    -- When satisfaction >= 50, productivity is at full (1.0)

    if not Character._ConsumptionMechanics or not Character._ConsumptionMechanics.consequenceThresholds or
       not Character._ConsumptionMechanics.consequenceThresholds.productivity then
        return
    end

    local config = Character._ConsumptionMechanics.consequenceThresholds.productivity
    if not config.enabled then
        return
    end

    local avgSatisfaction = self:GetAverageSatisfaction()
    local threshold = config.degradationThreshold or 50

    if avgSatisfaction < threshold then
        -- Linear degradation: satisfaction/threshold
        self.productivityMultiplier = avgSatisfaction / threshold

        -- Apply minimum productivity floor
        local minProductivity = config.minimumProductivity or 0.1
        self.productivityMultiplier = math.max(minProductivity, self.productivityMultiplier)

        -- Update status
        if self.productivityMultiplier < 0.5 then
            self.status = "stressed"
            self.statusMessage = "⚠️ Low productivity"
        end
    else
        -- Full productivity when satisfied
        self.productivityMultiplier = 1.0
    end
end

-- =============================================================================
-- Phase 5: Protest Mechanics
-- =============================================================================

function Character:CheckProtest(currentCycle)
    if self.hasEmigrated or self.isProtesting then
        return false
    end

    if not Character._ConsumptionMechanics or not Character._ConsumptionMechanics.consequenceThresholds or
       not Character._ConsumptionMechanics.consequenceThresholds.protest then
        return false
    end

    local config = Character._ConsumptionMechanics.consequenceThresholds.protest
    if not config.enabled then
        return false
    end

    local avgSatisfaction = self:GetAverageSatisfaction()

    -- Check protest conditions
    local satisfactionThreshold = config.averageSatisfactionThreshold[self.class] or 30
    local failureThreshold = config.consecutiveFailuresRequired or 10

    if avgSatisfaction < satisfactionThreshold and
       self.consecutiveFailedAllocations >= failureThreshold then
        -- Roll for protest (random chance per cycle)
        local protestChance = config.protestChancePerCycle or 0.2
        if math.random() < protestChance then
            self.isProtesting = true
            self.status = "protesting"
            self.statusMessage = "✊ Protesting"

            -- Protesters have zero productivity
            self.productivityMultiplier = 0

            return true
        end
    end

    -- Check if protest should end (satisfaction improved)
    if self.isProtesting then
        local endThreshold = config.protestEndThreshold or 40
        if avgSatisfaction >= endThreshold then
            self.isProtesting = false
            self.status = "idle"
            self.statusMessage = ""
            -- Recalculate productivity normally
            self:UpdateProductivity()
        end
    end

    return false
end

-- =============================================================================
-- LAYER 7: Active Effects (Durable Goods System)
-- =============================================================================

-- Add an active effect from acquiring a durable/permanent commodity
function Character:AddActiveEffect(commodityId, currentCycle)
    if not Character._FulfillmentVectors or not Character._FulfillmentVectors.commodities then
        print("Error: FulfillmentVectors not loaded for AddActiveEffect")
        return false, "FulfillmentVectors not loaded"
    end

    local commodityData = Character._FulfillmentVectors.commodities[commodityId]
    if not commodityData then
        print("Warning: No commodity data for: " .. tostring(commodityId))
        return false, "Commodity not found"
    end

    local durability = commodityData.durability or "consumable"
    if durability == "consumable" then
        print("Warning: Cannot add active effect for consumable: " .. commodityId)
        return false, "Commodity is consumable"
    end

    local category = commodityData.category or commodityId
    local maxOwned = commodityData.maxOwned or 1

    -- Check if at max capacity for this category
    local currentCount = self:GetActiveEffectCountByCategory(category)
    if currentCount >= maxOwned then
        -- Replace oldest effect in this category if at max
        self:RemoveOldestEffectInCategory(category)
    end

    -- Get fulfillment vector
    local fulfillmentVector = nil
    if commodityData.fulfillmentVector and commodityData.fulfillmentVector.fine then
        fulfillmentVector = commodityData.fulfillmentVector.fine
    end

    if not fulfillmentVector then
        print("Warning: No fine fulfillment vector for: " .. commodityId)
        return false, "No fulfillment vector"
    end

    -- Create the effect entry
    local effect = {
        commodityId = commodityId,
        category = category,
        durability = durability,
        acquiredCycle = currentCycle,
        durationCycles = commodityData.durationCycles,  -- nil for permanent
        remainingCycles = commodityData.durationCycles, -- nil for permanent
        effectDecayRate = commodityData.effectDecayRate or 0,
        currentEffectiveness = 1.0,  -- Start at full effectiveness
        fulfillmentVector = fulfillmentVector,
        maxOwned = maxOwned
    }

    table.insert(self.activeEffects, effect)
    print(string.format("  %s acquired %s (%s, %s cycles)",
        self.name, commodityId, durability,
        effect.durationCycles and tostring(effect.durationCycles) or "permanent"))

    return true, effect
end

-- Update all active effects (decay effectiveness, decrement remaining cycles, remove expired)
function Character:UpdateActiveEffects(currentCycle)
    local expiredIndices = {}
    local expiredEffects = {}

    for i, effect in ipairs(self.activeEffects) do
        -- Apply effectiveness decay
        if effect.effectDecayRate and effect.effectDecayRate > 0 then
            effect.currentEffectiveness = effect.currentEffectiveness * (1 - effect.effectDecayRate)
            -- Clamp to minimum
            effect.currentEffectiveness = math.max(0.1, effect.currentEffectiveness)
        end

        -- Decrement remaining cycles for durables (not permanents)
        if effect.durability == "durable" and effect.remainingCycles then
            effect.remainingCycles = effect.remainingCycles - 1

            -- Check if expired
            if effect.remainingCycles <= 0 then
                table.insert(expiredIndices, i)
                table.insert(expiredEffects, effect)
                print(string.format("  %s's %s has worn out", self.name, effect.commodityId))
            end
        end
    end

    -- Remove expired effects (in reverse order to maintain indices)
    for i = #expiredIndices, 1, -1 do
        table.remove(self.activeEffects, expiredIndices[i])
    end

    return expiredEffects
end

-- Apply passive satisfaction from all active effects
function Character:ApplyActiveEffectsSatisfaction(currentCycle)
    if #self.activeEffects == 0 then
        return
    end

    local totalCravingReduction = 0

    for _, effect in ipairs(self.activeEffects) do
        local effectiveness = effect.currentEffectiveness or 1.0
        local fulfillmentVector = effect.fulfillmentVector

        if fulfillmentVector then
            -- Apply fulfillment vector to reduce cravings (similar to FulfillCraving but passive)
            for fineDimId, points in pairs(fulfillmentVector) do
                if points and points > 0 then
                    -- Find fine dimension index
                    local fineIndex = nil
                    for idx, name in pairs(Character.fineNames) do
                        if name == fineDimId then
                            fineIndex = idx
                            break
                        end
                    end

                    if fineIndex then
                        -- Apply reduced effect (passive satisfaction is gentler than active consumption)
                        local passiveMultiplier = 0.3  -- Passive effects are 30% as strong per cycle
                        local gain = points * effectiveness * passiveMultiplier
                        local oldValue = self.currentCravings[fineIndex] or 0
                        self.currentCravings[fineIndex] = math.max(0, oldValue - gain)
                        totalCravingReduction = totalCravingReduction + gain
                    end
                end
            end

            -- Also boost satisfaction (coarse level) slightly
            for fineDimId, points in pairs(fulfillmentVector) do
                if points and points > 0 then
                    local fineIndex = nil
                    for idx, name in pairs(Character.fineNames) do
                        if name == fineDimId then
                            fineIndex = idx
                            break
                        end
                    end

                    if fineIndex then
                        local coarseName = Character.fineToCoarseMap[fineIndex]
                        if coarseName and self.satisfaction[coarseName] then
                            local passiveBoost = points * effectiveness * 0.1  -- Small satisfaction boost
                            self.satisfaction[coarseName] = math.min(300, self.satisfaction[coarseName] + passiveBoost)
                        end
                    end
                end
            end
        end
    end

    return totalCravingReduction
end

-- Check if character has an active effect in a specific category
function Character:HasActiveEffectForCategory(category)
    for _, effect in ipairs(self.activeEffects) do
        if effect.category == category then
            return true
        end
    end
    return false
end

-- Get count of active effects for a specific commodity
function Character:GetActiveEffectCount(commodityId)
    local count = 0
    for _, effect in ipairs(self.activeEffects) do
        if effect.commodityId == commodityId then
            count = count + 1
        end
    end
    return count
end

-- Get count of active effects in a category
function Character:GetActiveEffectCountByCategory(category)
    local count = 0
    for _, effect in ipairs(self.activeEffects) do
        if effect.category == category then
            count = count + 1
        end
    end
    return count
end

-- Remove oldest effect in a category (for replacement)
function Character:RemoveOldestEffectInCategory(category)
    local oldestIndex = nil
    local oldestCycle = math.huge

    for i, effect in ipairs(self.activeEffects) do
        if effect.category == category then
            if effect.acquiredCycle < oldestCycle then
                oldestCycle = effect.acquiredCycle
                oldestIndex = i
            end
        end
    end

    if oldestIndex then
        local removed = self.activeEffects[oldestIndex]
        table.remove(self.activeEffects, oldestIndex)
        print(string.format("  %s replaced old %s", self.name, removed.commodityId))
        return removed
    end
    return nil
end

-- Remove a specific active effect by index
function Character:RemoveActiveEffect(index)
    if index > 0 and index <= #self.activeEffects then
        local removed = self.activeEffects[index]
        table.remove(self.activeEffects, index)
        return removed
    end
    return nil
end

-- Remove active effect by commodity ID (removes first match)
function Character:RemoveActiveEffectByCommodity(commodityId)
    for i, effect in ipairs(self.activeEffects) do
        if effect.commodityId == commodityId then
            table.remove(self.activeEffects, i)
            return effect
        end
    end
    return nil
end

-- Get active effect by commodity ID
function Character:GetActiveEffect(commodityId)
    for _, effect in ipairs(self.activeEffects) do
        if effect.commodityId == commodityId then
            return effect
        end
    end
    return nil
end

-- Check if character can acquire a durable (not at max capacity)
function Character:CanAcquireDurable(commodityId)
    if not Character._FulfillmentVectors or not Character._FulfillmentVectors.commodities then
        return false
    end

    local commodityData = Character._FulfillmentVectors.commodities[commodityId]
    if not commodityData then
        return false
    end

    local durability = commodityData.durability or "consumable"
    if durability == "consumable" then
        return true  -- Consumables can always be acquired
    end

    local category = commodityData.category or commodityId
    local maxOwned = commodityData.maxOwned or 1

    -- Check current count - if at max, can still acquire (will replace oldest)
    -- Return true but indicate replacement will happen
    local currentCount = self:GetActiveEffectCountByCategory(category)
    return true, currentCount >= maxOwned  -- second return indicates replacement
end

-- Get total possession count
function Character:GetPossessionCount()
    return #self.activeEffects
end

-- Get all possessions summary for UI
function Character:GetPossessionsSummary()
    local summary = {
        total = #self.activeEffects,
        byCategory = {},
        items = {}
    }

    for _, effect in ipairs(self.activeEffects) do
        -- Count by category
        summary.byCategory[effect.category] = (summary.byCategory[effect.category] or 0) + 1

        -- Build item list
        table.insert(summary.items, {
            commodityId = effect.commodityId,
            category = effect.category,
            durability = effect.durability,
            remainingCycles = effect.remainingCycles,
            durationCycles = effect.durationCycles,
            effectiveness = effect.currentEffectiveness,
            acquiredCycle = effect.acquiredCycle
        })
    end

    return summary
end

return Character
