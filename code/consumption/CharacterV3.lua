-- CharacterV3.lua
-- Complete 6-layer character state model for consumption system
-- Alpha prototype version with slot-based craving system
-- Layers: Identity → Base Cravings → Current Cravings → Satisfaction → Commodity Multipliers → History

CharacterV3 = CharacterV3 or {}  -- Preserve table across hot reloads
CharacterV3.__index = CharacterV3

-- Data stored on CharacterV3 table (survives hot reload)
CharacterV3._ConsumptionMechanics = CharacterV3._ConsumptionMechanics or nil
CharacterV3._FulfillmentVectors = CharacterV3._FulfillmentVectors or nil
CharacterV3._CharacterTraits = CharacterV3._CharacterTraits or nil
CharacterV3._CharacterClasses = CharacterV3._CharacterClasses or nil
CharacterV3._DimensionDefinitions = CharacterV3._DimensionDefinitions or nil
CharacterV3._CommodityFatigueRates = CharacterV3._CommodityFatigueRates or nil
CharacterV3._EnablementRules = CharacterV3._EnablementRules or nil
CharacterV3._ClassThresholds = CharacterV3._ClassThresholds or nil  -- For emergent class calculation

-- Initialize data (called once at prototype start)
function CharacterV3.Init(mechanicsData, fulfillmentData, traitsData, classesData, dimensionsData, fatigueData, enablementData, classThresholdsData)
    CharacterV3._ConsumptionMechanics = mechanicsData
    CharacterV3._FulfillmentVectors = fulfillmentData
    CharacterV3._CharacterTraits = traitsData
    CharacterV3._CharacterClasses = classesData
    CharacterV3._DimensionDefinitions = dimensionsData
    CharacterV3._CommodityFatigueRates = fatigueData
    CharacterV3._EnablementRules = enablementData
    CharacterV3._ClassThresholds = classThresholdsData

    -- Build fine->coarse mapping for fast lookup
    CharacterV3.BuildDimensionMaps()

    -- Build craving ID to index map for slot-based system
    CharacterV3.BuildCravingIdToIndexMap()
end

-- Separate method to set class thresholds (can be called after Init)
function CharacterV3.SetClassThresholds(thresholdsData)
    CharacterV3._ClassThresholds = thresholdsData
    print("[CharacterV3] Class thresholds loaded")
end

-- Build mapping from fine dimension index to coarse dimension
function CharacterV3.BuildDimensionMaps()
    CharacterV3.fineToCoarseMap = {}
    CharacterV3.coarseNames = {}
    CharacterV3.coarseNameToIndex = {}
    CharacterV3.coarseToFineMap = {}
    CharacterV3.fineNames = {}

    if not CharacterV3._DimensionDefinitions then return end

    -- Map coarse dimension indices to names and vice versa
    for _, coarseDim in ipairs(CharacterV3._DimensionDefinitions.coarseDimensions) do
        CharacterV3.coarseNames[coarseDim.index] = coarseDim.id
        CharacterV3.coarseNameToIndex[coarseDim.id] = coarseDim.index
    end

    -- Map fine dimensions to their parent coarse and store aggregation weights
    CharacterV3.fineAggregationWeights = {}  -- fineIndex -> aggregationWeight
    CharacterV3.coarseWeightSums = {}  -- coarseIndex -> sum of weights for normalization

    for _, fineDim in ipairs(CharacterV3._DimensionDefinitions.fineDimensions) do
        CharacterV3.fineNames[fineDim.index] = fineDim.id
        -- Store aggregation weight (default to 1.0 if not specified)
        CharacterV3.fineAggregationWeights[fineDim.index] = fineDim.aggregationWeight or 1.0

        -- Convert parent coarse name to index
        local parentCoarseIndex = CharacterV3.coarseNameToIndex[fineDim.parentCoarse]
        if parentCoarseIndex then
            CharacterV3.fineToCoarseMap[fineDim.index] = parentCoarseIndex
            -- Accumulate weight sums for each coarse dimension
            CharacterV3.coarseWeightSums[parentCoarseIndex] = (CharacterV3.coarseWeightSums[parentCoarseIndex] or 0) + (fineDim.aggregationWeight or 1.0)
        else
            print("Warning: Unknown parent coarse '" .. tostring(fineDim.parentCoarse) .. "' for fine dimension " .. tostring(fineDim.index))
        end
    end

    -- Debug output for aggregation weights
    print("  Aggregation weight sums per coarse dimension:")
    for coarseIdx, weightSum in pairs(CharacterV3.coarseWeightSums) do
        local name = CharacterV3.coarseNames[coarseIdx] or "unknown"
        print(string.format("    [%d] %s: weight sum = %.3f", coarseIdx, name, weightSum))
    end

    -- Get dimension counts from loaded data
    local coarseCount = CharacterV3._DimensionDefinitions.dimensionCount and
                        CharacterV3._DimensionDefinitions.dimensionCount.coarse or
                        #CharacterV3._DimensionDefinitions.coarseDimensions
    local fineCount = CharacterV3._DimensionDefinitions.dimensionCount and
                      CharacterV3._DimensionDefinitions.dimensionCount.fine or
                      #CharacterV3._DimensionDefinitions.fineDimensions

    -- Build coarse to fine mapping (array of fine indices for each coarse)
    -- This correctly handles non-contiguous fine dimension indices
    for coarseIdx = 0, coarseCount - 1 do
        CharacterV3.coarseToFineMap[coarseIdx] = {}
    end

    for fineIdx = 0, fineCount - 1 do
        local coarseIdx = CharacterV3.fineToCoarseMap[fineIdx]
        if coarseIdx ~= nil then
            table.insert(CharacterV3.coarseToFineMap[coarseIdx], fineIdx)
        end
    end

    -- Cache dimension counts for easy access
    if CharacterV3._DimensionDefinitions.dimensionCount then
        CharacterV3._fineDimensionCount = CharacterV3._DimensionDefinitions.dimensionCount.fine or 50
        CharacterV3._coarseDimensionCount = CharacterV3._DimensionDefinitions.dimensionCount.coarse or 9
    else
        CharacterV3._fineDimensionCount = #CharacterV3._DimensionDefinitions.fineDimensions
        CharacterV3._coarseDimensionCount = #CharacterV3._DimensionDefinitions.coarseDimensions
    end

    -- Debug output
    print("CharacterV3 dimension maps built:")
    print("  Coarse dimensions: " .. CharacterV3._coarseDimensionCount)
    print("  Fine dimensions: " .. CharacterV3._fineDimensionCount)
    print("  coarseToFineMap entries: " .. tostring(#CharacterV3.coarseToFineMap))
    for idx, fineIndices in pairs(CharacterV3.coarseToFineMap) do
        local name = CharacterV3.coarseNames[idx] or "unknown"
        print(string.format("    [%d] %s: %d fine dimensions [%s]", idx, name, #fineIndices, table.concat(fineIndices, ", ")))
    end
end

-- Get dimension counts (0-indexed, so max index is count - 1)
function CharacterV3.GetFineDimensionCount()
    return CharacterV3._fineDimensionCount or 50
end

function CharacterV3.GetCoarseDimensionCount()
    return CharacterV3._coarseDimensionCount or 9
end

function CharacterV3.GetFineMaxIndex()
    return CharacterV3.GetFineDimensionCount() - 1
end

function CharacterV3.GetCoarseMaxIndex()
    return CharacterV3.GetCoarseDimensionCount() - 1
end

-- Build lookup from craving ID to fine dimension index
function CharacterV3.BuildCravingIdToIndexMap()
    CharacterV3.cravingIdToIndex = {}
    if CharacterV3._DimensionDefinitions and CharacterV3._DimensionDefinitions.fineDimensions then
        for _, fineDim in ipairs(CharacterV3._DimensionDefinitions.fineDimensions) do
            CharacterV3.cravingIdToIndex[fineDim.id] = fineDim.index
        end
    end
end

-- Get fine dimension index from craving ID
function CharacterV3.GetFineIndexFromCravingId(cravingId)
    if not CharacterV3.cravingIdToIndex then
        CharacterV3.BuildCravingIdToIndexMap()
    end
    return CharacterV3.cravingIdToIndex[cravingId]
end

-- Generate a new character
function CharacterV3:New(class, id)
    local char = setmetatable({}, CharacterV3)

    -- =============================================================================
    -- LAYER 1: Base Identity (static)
    -- =============================================================================
    char.id = id or "char_" .. tostring(math.random(100000, 999999))
    char.name = CharacterV3.GenerateRandomName()
    char.age = math.random(18, 65)
    char.class = class or "Middle"
    char.vocation = CharacterV3.GetRandomVocation()
    char.traits = CharacterV3.GetRandomTraits(2, char.class)

    -- =============================================================================
    -- LAYER 2: Base Cravings (quasi-static, 49D fine-grained)
    -- =============================================================================
    -- These are the character's baseline craving rates per cycle
    char.baseCravings = CharacterV3.GenerateBaseCravings(char.class, char.traits)

    -- =============================================================================
    -- LAYER 3: Current Cravings (49D fine-grained accumulation tracker)
    -- =============================================================================
    -- Accumulates based on baseCravings, resets when satisfied
    -- Initialize with several cycles worth of cravings so characters can consume
    -- multiple resources per cycle from the start
    char.currentCravings = {}
    local startingCravingMultiplier = 10  -- Start with 10 cycles worth of accumulated cravings
    for i = 0, CharacterV3.GetFineMaxIndex() do
        local baseRate = char.baseCravings[i] or 0
        char.currentCravings[i] = baseRate * startingCravingMultiplier
    end

    -- =============================================================================
    -- LAYER 4: Satisfaction State (Fine-grained + Coarse aggregation)
    -- =============================================================================
    -- Fine satisfaction (50D) - primary tracking, ranges -100 to 300
    -- Coarse satisfaction (9D) - computed from fine, for display
    char.satisfactionFine = {}
    char.satisfaction = {}  -- Coarse satisfaction (computed from fine)

    -- Initialize fine-level satisfaction
    CharacterV3.GenerateStartingSatisfactionFine(char, char.class)

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

    -- =============================================================================
    -- ECONOMICS & OWNERSHIP (Phase 3 additions)
    -- =============================================================================
    -- Note: Main economics tracking is in EconomicsSystem.lua
    -- These fields are for quick reference and backward compatibility
    char.emergentClass = nil  -- Calculated from economics, not assigned
    char.lastClassCalculation = 0  -- Cycle number when class was last calculated

    -- Housing reference (managed by HousingSystem)
    char.housingId = nil  -- Building ID where character lives
    char.householdId = nil  -- Household group ID (for families)

    -- Employment (managed by workplace assignment)
    char.employment = {
        employerId = nil,  -- Owner ID of workplace
        workplaceId = nil,  -- Building ID (redundant with workplace for clarity)
        wageRate = 0,  -- Per-cycle wage
    }

    -- Relationships with other characters
    char.relationships = {}
    --[[
        Format: {
            [targetId] = {
                type = "spouse"|"parent"|"child"|"sibling"|"employer"|"employee"|
                       "landlord"|"tenant"|"colleague"|"neighbour"|"friend"|"rival",
                since = cycle,
                metadata = {}
            }
        }
    ]]

    return char
end

-- =============================================================================
-- LAYER 2: Base Cravings Generation
-- =============================================================================

function CharacterV3.GenerateBaseCravings(class, traits)
    local baseCravings = {}

    -- Normalize class to lowercase for comparison
    local classLower = string.lower(class or "middle")
    print(string.format("GenerateBaseCravings called with class='%s' (normalized: '%s')", tostring(class), classLower))

    if not CharacterV3._CharacterClasses or not CharacterV3._CharacterClasses.classes then
        -- Fallback: uniform distribution
        print("  Warning: CharacterClasses not loaded, using fallback")
        for i = 0, CharacterV3.GetFineMaxIndex() do
            baseCravings[i] = 1.0
        end
        return baseCravings
    end

    -- Find class data (case-insensitive comparison)
    local classData = nil
    for _, c in ipairs(CharacterV3._CharacterClasses.classes) do
        if string.lower(c.id) == classLower then
            classData = c
            break
        end
    end

    if not classData then
        print(string.format("  Warning: Class '%s' not found, using fallback", tostring(class)))
        for i = 0, CharacterV3.GetFineMaxIndex() do
            baseCravings[i] = 1.0
        end
        return baseCravings
    end

    if not classData.baseCravingVector or not classData.baseCravingVector.fine then
        print("  Warning: baseCravingVector.fine not found, using fallback")
        for i = 0, CharacterV3.GetFineMaxIndex() do
            baseCravings[i] = 1.0
        end
        return baseCravings
    end

    print(string.format("  Found class data for '%s', loading base cravings", class))
    print(string.format("  Fine vector has %d elements", #classData.baseCravingVector.fine))

    -- Copy fine-grained base cravings from class
    for i = 0, CharacterV3.GetFineMaxIndex() do
        baseCravings[i] = classData.baseCravingVector.fine[i + 1] or 0  -- Lua 1-indexed
    end

    -- Debug: print first few base cravings
    print(string.format("  Base cravings [0-4]: %.2f, %.2f, %.2f, %.2f, %.2f",
        baseCravings[0] or 0, baseCravings[1] or 0, baseCravings[2] or 0,
        baseCravings[3] or 0, baseCravings[4] or 0))

    -- Apply trait multipliers to base cravings
    if traits and #traits > 0 and CharacterV3._CharacterTraits and CharacterV3._CharacterTraits.traits then
        print(string.format("  Applying %d traits: %s", #traits, table.concat(traits, ", ")))
        for _, traitId in ipairs(traits) do
            local traitIdLower = string.lower(traitId)
            local foundTrait = false
            for _, traitData in ipairs(CharacterV3._CharacterTraits.traits) do
                if string.lower(traitData.id) == traitIdLower and traitData.cravingMultipliers and traitData.cravingMultipliers.fine then
                    print(string.format("    Applying trait '%s' multipliers", traitData.id))
                    for i = 0, CharacterV3.GetFineMaxIndex() do
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
-- LAYER 4: Generate Starting Satisfaction (Fine-level 50D + Coarse aggregation)
-- =============================================================================

-- Initialize fine-level satisfaction for a character
function CharacterV3.GenerateStartingSatisfactionFine(char, class)
    -- Convert class to lowercase for JSON lookup
    local classKey = string.lower(class)
    if classKey == "working" or classKey == "poor" then
        classKey = "lower"
    end

    -- Get coarse starting ranges from consumption_mechanics
    local coarseRanges = {}
    if CharacterV3._ConsumptionMechanics and CharacterV3._ConsumptionMechanics.characterGeneration and
       CharacterV3._ConsumptionMechanics.characterGeneration.startingSatisfactionRanges and
       CharacterV3._ConsumptionMechanics.characterGeneration.startingSatisfactionRanges[classKey] then
        coarseRanges = CharacterV3._ConsumptionMechanics.characterGeneration.startingSatisfactionRanges[classKey]
    end

    -- Initialize fine satisfaction based on parent coarse ranges
    for fineIdx = 0, CharacterV3.GetFineMaxIndex() do
        local coarseIdx = CharacterV3.fineToCoarseMap[fineIdx]
        local coarseName = coarseIdx and CharacterV3.coarseNames[coarseIdx] or nil

        if coarseName and coarseRanges[coarseName] then
            local range = coarseRanges[coarseName]
            -- Add some variance within fine dimensions
            local baseValue = math.random(range[1], range[2])
            local variance = math.random(-10, 10)
            char.satisfactionFine[fineIdx] = math.max(-100, math.min(300, baseValue + variance))
        else
            -- Default to 50 with some variance
            char.satisfactionFine[fineIdx] = 50 + math.random(-10, 10)
        end
    end

    -- Compute initial coarse satisfaction from fine
    CharacterV3.ComputeCoarseSatisfaction(char)
end

-- Compute coarse satisfaction as weighted average of fine dimensions
function CharacterV3.ComputeCoarseSatisfaction(char)
    char.satisfaction = {}

    for coarseIdx = 0, CharacterV3.GetCoarseMaxIndex() do
        local coarseName = CharacterV3.coarseNames[coarseIdx]
        if coarseName then
            local total = 0
            local totalWeight = 0

            for fineIdx = 0, CharacterV3.GetFineMaxIndex() do
                if CharacterV3.fineToCoarseMap[fineIdx] == coarseIdx then
                    -- Use aggregationWeight from dimension definitions
                    local weight = CharacterV3.fineAggregationWeights[fineIdx] or 1.0
                    total = total + (char.satisfactionFine[fineIdx] or 50) * weight
                    totalWeight = totalWeight + weight
                end
            end

            -- Normalize by dividing by sum of weights
            char.satisfaction[coarseName] = totalWeight > 0 and (total / totalWeight) or 50
        end
    end
end

-- Legacy function for backward compatibility
function CharacterV3.GenerateStartingSatisfaction(class)
    local satisfaction = {}
    local classKey = string.lower(class)
    if classKey == "working" or classKey == "poor" then
        classKey = "lower"
    end

    if CharacterV3._ConsumptionMechanics and CharacterV3._ConsumptionMechanics.characterGeneration and
       CharacterV3._ConsumptionMechanics.characterGeneration.startingSatisfactionRanges and
       CharacterV3._ConsumptionMechanics.characterGeneration.startingSatisfactionRanges[classKey] then
        local ranges = CharacterV3._ConsumptionMechanics.characterGeneration.startingSatisfactionRanges[classKey]
        for cravingType, range in pairs(ranges) do
            satisfaction[cravingType] = math.random(range[1], range[2])
        end
    else
        for i = 0, CharacterV3.GetCoarseMaxIndex() do
            local coarseName = CharacterV3.coarseNames[i] or "unknown"
            satisfaction[coarseName] = 50
        end
    end

    return satisfaction
end

-- =============================================================================
-- LAYER 3: Update Current Cravings (Accumulation)
-- =============================================================================

function CharacterV3:UpdateCurrentCravings(deltaTime, activeCravings)
    -- Accumulate cravings based on baseCravings decay rates
    -- currentCravings += baseCravings * (deltaTime / cycleTime)
    -- If activeCravings provided, only accumulate those (slot-based system)

    local cycleTime = 60.0  -- 60 seconds per cycle
    local ratio = deltaTime / cycleTime

    -- Max craving is relative to base craving (e.g., 50x base rate)
    -- This represents the maximum intensity a craving can reach
    -- Once capped, satisfaction continues to decay but craving intensity plateaus
    local maxCravingMultiplier = 50.0

    -- If activeCravings provided, only accumulate those dimensions
    if activeCravings and #activeCravings > 0 then
        -- Build set of active indices for quick lookup
        local activeIndices = {}
        for _, cravingId in ipairs(activeCravings) do
            local idx = CharacterV3.GetFineIndexFromCravingId(cravingId)
            if idx then
                activeIndices[idx] = true
            end
        end

        -- Only accumulate active cravings
        for i = 0, CharacterV3.GetFineMaxIndex() do
            if activeIndices[i] then
                local baseRate = self.baseCravings[i] or 0
                local maxCraving = math.max(baseRate * maxCravingMultiplier, 50)

                self.currentCravings[i] = self.currentCravings[i] + (baseRate * ratio)
                self.currentCravings[i] = math.min(self.currentCravings[i], maxCraving)
            end
        end
    else
        -- Fallback: accumulate all cravings (old behavior)
        for i = 0, CharacterV3.GetFineMaxIndex() do
            local baseRate = self.baseCravings[i] or 0
            local maxCraving = math.max(baseRate * maxCravingMultiplier, 50)

            self.currentCravings[i] = self.currentCravings[i] + (baseRate * ratio)
            self.currentCravings[i] = math.min(self.currentCravings[i], maxCraving)
        end
    end
end

-- =============================================================================
-- LAYER 4: Update Satisfaction (Fine-Level Decay)
-- =============================================================================

function CharacterV3:UpdateSatisfaction(currentCycle)
    -- Fine-level satisfaction decays based on unfulfilled currentCravings
    -- Higher unfulfilled currentCravings = faster satisfaction decay

    if not CharacterV3._ConsumptionMechanics or not CharacterV3._ConsumptionMechanics.cravingDecayRates then
        return
    end

    local decayRates = CharacterV3._ConsumptionMechanics.cravingDecayRates

    -- Phase 5: Use emergent class for decay rates (not initial/template class)
    local effectiveClass = self:GetEffectiveClass()

    -- Decay each fine dimension based on its unfulfilled currentCravings
    for fineIdx = 0, CharacterV3.GetFineMaxIndex() do
        local currentCraving = self.currentCravings[fineIdx] or 0

        -- Get parent coarse for decay rate lookup
        local coarseIdx = CharacterV3.fineToCoarseMap[fineIdx]
        local coarseName = coarseIdx and CharacterV3.coarseNames[coarseIdx] or nil

        -- Base decay from coarse dimension settings using emergent class
        local baseDecay = 1.0
        if coarseName and decayRates[coarseName] and decayRates[coarseName][effectiveClass] then
            baseDecay = decayRates[coarseName][effectiveClass]
        end

        -- Decay accelerates with unfulfilled cravings
        local cravingMultiplier = 1.0 + (currentCraving / 50.0)
        local decay = baseDecay * cravingMultiplier * 0.2  -- Scale down for fine-level

        -- Apply decay to fine satisfaction
        local currentSat = self.satisfactionFine[fineIdx] or 50
        self.satisfactionFine[fineIdx] = math.max(-100, math.min(300, currentSat - decay))
    end

    -- Recompute coarse satisfaction from fine
    CharacterV3.ComputeCoarseSatisfaction(self)
end

-- =============================================================================
-- LAYER 5: Calculate Commodity Multiplier (Slot-Based Fatigue)
-- =============================================================================

-- Global slot counter for fatigue tracking (set by AlphaWorld)
CharacterV3._currentGlobalSlot = 0

function CharacterV3.SetCurrentGlobalSlot(slot)
    CharacterV3._currentGlobalSlot = slot
end

function CharacterV3:CalculateCommodityMultiplier(commodity, currentSlotOrCycle)
    -- Use global slot counter if available, otherwise fall back to passed value
    local currentSlot = CharacterV3._currentGlobalSlot > 0 and CharacterV3._currentGlobalSlot or currentSlotOrCycle

    local history = self.commodityMultipliers[commodity]

    if not history then
        -- First time consuming this commodity
        return 1.0
    end

    local consecutiveCount = history.consecutiveCount or 0
    local slotsSinceLast = currentSlot - (history.lastConsumedSlot or history.lastConsumed or 0)

    -- Get commodity-specific fatigue config
    local baseFatigueRate = 0.12  -- default
    local traitModifier = 1.0

    if CharacterV3._CommodityFatigueRates and CharacterV3._CommodityFatigueRates.commodities and
       CharacterV3._CommodityFatigueRates.commodities[commodity] then
        local fatigueData = CharacterV3._CommodityFatigueRates.commodities[commodity]
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

    -- Check if enough slots have passed for cooldown (default 4 slots = ~2/3 of a day)
    local cooldownSlots = CharacterV3._ConsumptionMechanics and
                          CharacterV3._ConsumptionMechanics.commodityDiminishingReturns and
                          CharacterV3._ConsumptionMechanics.commodityDiminishingReturns.varietyCooldownSlots or 4

    if slotsSinceLast > cooldownSlots then
        -- Reset fatigue
        return 1.0
    end

    -- Calculate fatigue multiplier using exponential decay
    -- multiplier = exp(-consecutiveCount * effectiveFatigueRate)
    local multiplier = math.exp(-consecutiveCount * effectiveFatigueRate)

    -- Apply min threshold
    local minMultiplier = CharacterV3._ConsumptionMechanics and
                         CharacterV3._ConsumptionMechanics.commodityDiminishingReturns and
                         CharacterV3._ConsumptionMechanics.commodityDiminishingReturns.minMultiplier or 0.25

    multiplier = math.max(minMultiplier, multiplier)

    return multiplier
end

-- =============================================================================
-- LAYER 5: Update Commodity Multiplier History (Slot-Based)
-- =============================================================================

function CharacterV3:UpdateCommodityHistory(commodity, currentSlotOrCycle)
    -- Use global slot counter if available
    local currentSlot = CharacterV3._currentGlobalSlot > 0 and CharacterV3._currentGlobalSlot or currentSlotOrCycle

    if not self.commodityMultipliers[commodity] then
        self.commodityMultipliers[commodity] = {
            consecutiveCount = 1,
            lastConsumedSlot = currentSlot,
            multiplier = 1.0
        }
    else
        local history = self.commodityMultipliers[commodity]
        local slotsSinceLast = currentSlot - (history.lastConsumedSlot or history.lastConsumed or 0)

        -- Cooldown in slots (default 4 = about 2/3 of a day)
        local cooldownSlots = CharacterV3._ConsumptionMechanics and
                              CharacterV3._ConsumptionMechanics.commodityDiminishingReturns and
                              CharacterV3._ConsumptionMechanics.commodityDiminishingReturns.varietyCooldownSlots or 4

        if slotsSinceLast <= cooldownSlots then
            -- Still in fatigue period
            history.consecutiveCount = history.consecutiveCount + 1
        else
            -- Cooldown expired, reset
            history.consecutiveCount = 1
        end

        history.lastConsumedSlot = currentSlot
    end

    -- Decay other commodities' consecutive counts over time (in slots)
    local decaySlots = CharacterV3._ConsumptionMechanics and
                       CharacterV3._ConsumptionMechanics.commodityDiminishingReturns and
                       CharacterV3._ConsumptionMechanics.commodityDiminishingReturns.otherCommodityDecaySlots or 2

    local decayRate = CharacterV3._ConsumptionMechanics and
                     CharacterV3._ConsumptionMechanics.commodityDiminishingReturns and
                     CharacterV3._ConsumptionMechanics.commodityDiminishingReturns.otherCommodityDecayRate or 1

    for otherCommodity, otherHistory in pairs(self.commodityMultipliers) do
        if otherCommodity ~= commodity then
            local slotsSince = currentSlot - (otherHistory.lastConsumedSlot or otherHistory.lastConsumed or 0)
            if slotsSince >= decaySlots then
                otherHistory.consecutiveCount = math.max(0, otherHistory.consecutiveCount - decayRate)
            end
        end
    end
end

-- =============================================================================
-- LAYER 3 & 4: Fulfill Craving (Consume Commodity)
-- =============================================================================

function CharacterV3:FulfillCraving(commodity, quantity, currentCycle, allocationType)
    allocationType = allocationType or "consumed"  -- Default to consumed for backward compatibility

    if not CharacterV3._FulfillmentVectors or not CharacterV3._FulfillmentVectors.commodities then
        print("Error: CharacterV3._FulfillmentVectors not initialized")
        return false, 0, 1.0
    end

    local commodityData = CharacterV3._FulfillmentVectors.commodities[commodity]
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
            for idx, name in pairs(CharacterV3.fineNames) do
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

    -- LAYER 4: Increase fine-level satisfaction (then compute coarse)
    for fineDimId, points in pairs(fineVector) do
        if points and points > 0 then
            -- Find fine dimension index
            local fineIndex = nil
            for idx, name in pairs(CharacterV3.fineNames) do
                if name == fineDimId then
                    fineIndex = idx
                    break
                end
            end

            if fineIndex then
                -- Boost fine satisfaction directly
                local boost = points * qualityMultiplier * fatigueMultiplier * quantity * 0.5
                local currentSat = self.satisfactionFine[fineIndex] or 50
                self.satisfactionFine[fineIndex] = math.min(300, currentSat + boost)
            end
        end
    end

    -- Recompute coarse satisfaction from fine
    CharacterV3.ComputeCoarseSatisfaction(self)

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
    local varietyThreshold = CharacterV3._ConsumptionMechanics and
                            CharacterV3._ConsumptionMechanics.commodityDiminishingReturns and
                            CharacterV3._ConsumptionMechanics.commodityDiminishingReturns.varietySeekingThreshold or 0.70

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

function CharacterV3:ApplyEnablement(ruleId, currentCycle)
    -- Check if already applied
    if self.appliedEnablements[ruleId] then
        return false
    end

    if not CharacterV3._EnablementRules or not CharacterV3._EnablementRules.rules then
        return false
    end

    -- Find the rule
    local rule = nil
    for _, r in ipairs(CharacterV3._EnablementRules.rules) do
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
        for i = 0, CharacterV3.GetFineMaxIndex() do
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

function CharacterV3:AggregateCurrentCravingsToCoarse()
    local coarseCravings = {}

    for coarseIndex = 0, CharacterV3.GetCoarseMaxIndex() do
        local coarseName = CharacterV3.coarseNames[coarseIndex]
        if coarseName then
            local total = 0
            local count = 0
            local totalWeight = 0

            for fineIndex = 0, CharacterV3.GetFineMaxIndex() do
                -- Fixed: compare coarseIndex (number) to fineToCoarseMap (number), not to coarseName (string)
                if CharacterV3.fineToCoarseMap[fineIndex] == coarseIndex then
                    -- Use aggregationWeight from dimension definitions
                    local weight = CharacterV3.fineAggregationWeights[fineIndex] or 1.0
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

function CharacterV3:CalculatePriority(currentCycle, allocationMode)
    if not CharacterV3._ConsumptionMechanics or not CharacterV3._ConsumptionMechanics.priorityCalculation then
        return 100
    end

    local config = CharacterV3._ConsumptionMechanics.priorityCalculation

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
function CharacterV3:AcceptsQuality(quality)
    if not quality then
        return true  -- No quality specified = accept
    end

    -- Phase 5: Use emergent class for quality acceptance
    local effectiveClass = self:GetEffectiveClass()

    -- Find class data for this character's emergent class
    local classData = nil
    if CharacterV3._CharacterClasses and CharacterV3._CharacterClasses.classes then
        local classLower = string.lower(effectiveClass or "middle")
        for _, c in ipairs(CharacterV3._CharacterClasses.classes) do
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

-- =============================================================================
-- Utility Functions
-- =============================================================================

function CharacterV3.GenerateRandomName()
    if not CharacterV3._ConsumptionMechanics or not CharacterV3._ConsumptionMechanics.names then
        return "Character_" .. math.random(1000, 9999)
    end

    local first = CharacterV3._ConsumptionMechanics.names.first
    local last = CharacterV3._ConsumptionMechanics.names.last
    return first[math.random(#first)] .. " " .. last[math.random(#last)]
end

function CharacterV3.GetRandomVocation()
    if not CharacterV3._ConsumptionMechanics or not CharacterV3._ConsumptionMechanics.vocations then
        return "Worker"
    end

    local vocations = CharacterV3._ConsumptionMechanics.vocations
    return vocations[math.random(#vocations)]
end

function CharacterV3.GetRandomTraits(count, class)
    if not CharacterV3._ConsumptionMechanics or not CharacterV3._ConsumptionMechanics.characterGeneration or
       not CharacterV3._ConsumptionMechanics.characterGeneration.traits or
       not CharacterV3._ConsumptionMechanics.characterGeneration.traits.available then
        return {}
    end

    local availableTraits = CharacterV3._ConsumptionMechanics.characterGeneration.traits.available
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

function CharacterV3:GetAverageSatisfaction()
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

function CharacterV3:GetCriticalCravingCount()
    local count = 0
    local coarseCravings = self:AggregateCurrentCravingsToCoarse()
    for _, value in pairs(coarseCravings) do
        if value > 80 then  -- Critical threshold
            count = count + 1
        end
    end
    return count
end

function CharacterV3:CheckEmigration(currentCycle)
    if self.hasEmigrated then
        return false
    end

    if not CharacterV3._ConsumptionMechanics or not CharacterV3._ConsumptionMechanics.consequenceThresholds or
       not CharacterV3._ConsumptionMechanics.consequenceThresholds.emigration then
        return false
    end

    local config = CharacterV3._ConsumptionMechanics.consequenceThresholds.emigration
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

function CharacterV3:RecordAllocationAttempt(success, currentCycle)
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

function CharacterV3:UpdateProductivity()
    -- Productivity degrades linearly when average satisfaction < 50
    -- Formula: productivityMultiplier = avgSatisfaction / 50 (when < 50)
    -- When satisfaction >= 50, productivity is at full (1.0)

    if not CharacterV3._ConsumptionMechanics or not CharacterV3._ConsumptionMechanics.consequenceThresholds or
       not CharacterV3._ConsumptionMechanics.consequenceThresholds.productivity then
        return
    end

    local config = CharacterV3._ConsumptionMechanics.consequenceThresholds.productivity
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

function CharacterV3:CheckProtest(currentCycle)
    if self.hasEmigrated or self.isProtesting then
        return false
    end

    if not CharacterV3._ConsumptionMechanics or not CharacterV3._ConsumptionMechanics.consequenceThresholds or
       not CharacterV3._ConsumptionMechanics.consequenceThresholds.protest then
        return false
    end

    local config = CharacterV3._ConsumptionMechanics.consequenceThresholds.protest
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
function CharacterV3:AddActiveEffect(commodityId, currentCycle)
    if not CharacterV3._FulfillmentVectors or not CharacterV3._FulfillmentVectors.commodities then
        print("Error: FulfillmentVectors not loaded for AddActiveEffect")
        return false, "FulfillmentVectors not loaded"
    end

    local commodityData = CharacterV3._FulfillmentVectors.commodities[commodityId]
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
function CharacterV3:UpdateActiveEffects(currentCycle)
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

-- Apply passive satisfaction from active effects (slot-aware)
-- currentSlotId: the current slot ID (e.g., "late_night", "evening")
-- durableSlots: mapping from category to slot (from craving_slots.json)
function CharacterV3:ApplyActiveEffectsSatisfaction(currentSlotId, durableSlots)
    if #self.activeEffects == 0 then
        return 0
    end

    local totalCravingReduction = 0
    durableSlots = durableSlots or {}

    for _, effect in ipairs(self.activeEffects) do
        -- Check if this effect should apply in the current slot
        local category = effect.category
        local effectSlot = durableSlots[category]

        -- If no slot specified for category, default to "late_night" for furniture/housing
        if not effectSlot then
            if category and (category:find("furniture") or category:find("housing") or category:find("sleep")) then
                effectSlot = "late_night"
            elseif category and category:find("decoration") then
                effectSlot = "evening"
            else
                effectSlot = "late_night"  -- Default for other durables
            end
        end

        -- Only apply if we're in the right slot
        if currentSlotId == effectSlot then
            local effectiveness = effect.currentEffectiveness or 1.0
            local fulfillmentVector = effect.fulfillmentVector

            if fulfillmentVector then
                -- Apply fulfillment vector to reduce cravings
                for fineDimId, points in pairs(fulfillmentVector) do
                    if points and points > 0 then
                        local fineIndex = CharacterV3.GetFineIndexFromCravingId(fineDimId)

                        if fineIndex then
                            -- Passive effects are applied once per day (stronger than per-cycle)
                            local passiveMultiplier = 1.0  -- Full effect since it's once per day
                            local gain = points * effectiveness * passiveMultiplier
                            local oldValue = self.currentCravings[fineIndex] or 0
                            self.currentCravings[fineIndex] = math.max(0, oldValue - gain)
                            totalCravingReduction = totalCravingReduction + gain

                            -- Also boost fine satisfaction
                            local currentSat = self.satisfactionFine[fineIndex] or 50
                            local satBoost = points * effectiveness * 0.5
                            self.satisfactionFine[fineIndex] = math.min(300, currentSat + satBoost)
                        end
                    end
                end

                -- Recompute coarse satisfaction
                CharacterV3.ComputeCoarseSatisfaction(self)
            end
        end
    end

    return totalCravingReduction
end

-- Check if character has an active effect in a specific category
function CharacterV3:HasActiveEffectForCategory(category)
    for _, effect in ipairs(self.activeEffects) do
        if effect.category == category then
            return true
        end
    end
    return false
end

-- Get count of active effects for a specific commodity
function CharacterV3:GetActiveEffectCount(commodityId)
    local count = 0
    for _, effect in ipairs(self.activeEffects) do
        if effect.commodityId == commodityId then
            count = count + 1
        end
    end
    return count
end

-- Get count of active effects in a category
function CharacterV3:GetActiveEffectCountByCategory(category)
    local count = 0
    for _, effect in ipairs(self.activeEffects) do
        if effect.category == category then
            count = count + 1
        end
    end
    return count
end

-- Remove oldest effect in a category (for replacement)
function CharacterV3:RemoveOldestEffectInCategory(category)
    local oldestIndex = nil
    local oldestCycle = math.huge

    for i, effect in ipairs(self.activeEffects) do
        if effect.category == category then
            -- Ensure acquiredCycle is a number (handle legacy data where it might be a table)
            local cycle = effect.acquiredCycle
            if type(cycle) ~= "number" then
                cycle = 0  -- Treat invalid/legacy data as oldest
            end
            if cycle < oldestCycle then
                oldestCycle = cycle
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
function CharacterV3:RemoveActiveEffect(index)
    if index > 0 and index <= #self.activeEffects then
        local removed = self.activeEffects[index]
        table.remove(self.activeEffects, index)
        return removed
    end
    return nil
end

-- Remove active effect by commodity ID (removes first match)
function CharacterV3:RemoveActiveEffectByCommodity(commodityId)
    for i, effect in ipairs(self.activeEffects) do
        if effect.commodityId == commodityId then
            table.remove(self.activeEffects, i)
            return effect
        end
    end
    return nil
end

-- Get active effect by commodity ID
function CharacterV3:GetActiveEffect(commodityId)
    for _, effect in ipairs(self.activeEffects) do
        if effect.commodityId == commodityId then
            return effect
        end
    end
    return nil
end

-- Check if character can acquire a durable (not at max capacity)
function CharacterV3:CanAcquireDurable(commodityId)
    if not CharacterV3._FulfillmentVectors or not CharacterV3._FulfillmentVectors.commodities then
        return false
    end

    local commodityData = CharacterV3._FulfillmentVectors.commodities[commodityId]
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
function CharacterV3:GetPossessionCount()
    return #self.activeEffects
end

-- Get all possessions summary for UI
function CharacterV3:GetPossessionsSummary()
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

-- =============================================================================
-- EMERGENT CLASS SYSTEM (Phase 3)
-- =============================================================================

-- Calculate emergent class based on net worth and capital ratio
-- Uses loaded _ClassThresholds data
function CharacterV3:CalculateEmergentClass(netWorth, capitalRatio, currentCycle)
    -- Get thresholds from loaded data or use defaults
    local thresholds = CharacterV3._ClassThresholds or {}
    local netWorthThresholds = thresholds.netWorthThresholds or {
        elite = { min = 10000 },
        upper = { min = 3000 },
        middle = { min = 500 }
    }
    local capitalRatioThresholds = thresholds.capitalRatioThresholds or {
        elite = 0.8,
        upper = 0.5,
        middle = 0.2
    }

    local newClass = "lower"  -- Default

    -- Check thresholds from highest to lowest
    if netWorth >= (netWorthThresholds.elite and netWorthThresholds.elite.min or 10000) and
       capitalRatio >= (capitalRatioThresholds.elite or 0.8) then
        newClass = "elite"
    elseif netWorth >= (netWorthThresholds.upper and netWorthThresholds.upper.min or 3000) and
           capitalRatio >= (capitalRatioThresholds.upper or 0.5) then
        newClass = "upper"
    elseif netWorth >= (netWorthThresholds.middle and netWorthThresholds.middle.min or 500) and
           capitalRatio >= (capitalRatioThresholds.middle or 0.2) then
        newClass = "middle"
    end

    -- Check for class change
    local oldClass = self.emergentClass or self.class

    if newClass ~= oldClass then
        self:OnClassChange(oldClass, newClass, currentCycle)
    end

    self.emergentClass = newClass
    self.lastClassCalculation = currentCycle or 0

    return newClass
end

-- Called when emergent class changes
function CharacterV3:OnClassChange(oldClass, newClass, currentCycle)
    print(string.format("[CharacterV3] %s class changed: %s -> %s",
        self.name, oldClass or "none", newClass))

    -- Update base cravings based on new class template
    -- This adjusts what the character desires based on their new social position
    local newBaseCravings = CharacterV3.GenerateBaseCravings(newClass, self.traits)

    -- Blend old and new cravings (gradual transition, not instant)
    local blendFactor = 0.3  -- 30% new cravings per calculation
    for i = 0, CharacterV3.GetFineMaxIndex() do
        local oldValue = self.baseCravings[i] or 0
        local newValue = newBaseCravings[i] or 0
        self.baseCravings[i] = oldValue * (1 - blendFactor) + newValue * blendFactor
    end

    -- Update the display class (for backward compatibility)
    self.class = newClass

    -- Housing preference may change - signal to HousingSystem
    -- (HousingSystem checks this via ShouldSeekBetterHousing)
end

-- Get the current effective class (emergent if calculated, else assigned)
function CharacterV3:GetEffectiveClass()
    return self.emergentClass or self.class or "middle"
end

-- =============================================================================
-- RELATIONSHIP MANAGEMENT (Phase 3)
-- =============================================================================

-- Add a relationship with another character
function CharacterV3:AddRelationship(targetId, relationType, currentCycle, metadata)
    if not targetId or not relationType then
        return false
    end

    self.relationships[targetId] = {
        type = relationType,
        since = currentCycle or 0,
        metadata = metadata or {}
    }

    return true
end

-- Remove a relationship
function CharacterV3:RemoveRelationship(targetId)
    if self.relationships[targetId] then
        self.relationships[targetId] = nil
        return true
    end
    return false
end

-- Get relationship with a specific character
function CharacterV3:GetRelationship(targetId)
    return self.relationships[targetId]
end

-- Get all relationships of a specific type
function CharacterV3:GetRelationshipsByType(relationType)
    local result = {}
    for targetId, rel in pairs(self.relationships) do
        if rel.type == relationType then
            result[targetId] = rel
        end
    end
    return result
end

-- Check if character has a specific relationship type
function CharacterV3:HasRelationshipType(relationType)
    for _, rel in pairs(self.relationships) do
        if rel.type == relationType then
            return true
        end
    end
    return false
end

-- Get all relationship target IDs
function CharacterV3:GetAllRelationshipIds()
    local ids = {}
    for targetId, _ in pairs(self.relationships) do
        table.insert(ids, targetId)
    end
    return ids
end

-- Update colleague relationships based on workplace
function CharacterV3:UpdateColleagueRelationships(coworkerIds, currentCycle)
    -- Remove old colleague relationships
    local toRemove = {}
    for targetId, rel in pairs(self.relationships) do
        if rel.type == "colleague" then
            local stillCoworker = false
            for _, coworkerId in ipairs(coworkerIds or {}) do
                if coworkerId == targetId then
                    stillCoworker = true
                    break
                end
            end
            if not stillCoworker then
                table.insert(toRemove, targetId)
            end
        end
    end

    for _, targetId in ipairs(toRemove) do
        self:RemoveRelationship(targetId)
    end

    -- Add new colleague relationships
    for _, coworkerId in ipairs(coworkerIds or {}) do
        if coworkerId ~= self.id and not self.relationships[coworkerId] then
            self:AddRelationship(coworkerId, "colleague", currentCycle)
        end
    end
end

-- =============================================================================
-- HOUSING INTEGRATION (Phase 3)
-- =============================================================================

-- Set housing assignment (called by HousingSystem)
function CharacterV3:SetHousing(buildingId, currentCycle)
    local oldHousingId = self.housingId
    self.housingId = buildingId

    -- Log if changed
    if oldHousingId ~= buildingId then
        print(string.format("[CharacterV3] %s moved to housing %s",
            self.name, buildingId or "homeless"))
    end
end

-- Check if character is housed
function CharacterV3:IsHoused()
    return self.housingId ~= nil
end

-- Get housing satisfaction modifier (for craving system integration)
function CharacterV3:GetHousingSatisfactionModifier()
    if not self.housingId then
        return 0.5  -- Penalty for being homeless
    end
    return 1.0  -- Normal satisfaction when housed
end

-- Apply housing fulfillment to satisfaction (called daily by AlphaWorld)
function CharacterV3:ApplyHousingFulfillment(fulfillmentVector, crowdingModifier)
    if not fulfillmentVector then return end

    crowdingModifier = crowdingModifier or 1.0

    -- Apply each dimension's fulfillment to the character's fine satisfaction
    for dimensionId, value in pairs(fulfillmentVector) do
        -- Find the dimension index
        local fineIndex = nil
        if dimensionDefinitionsRef and dimensionDefinitionsRef.fineDimensions then
            for _, dim in ipairs(dimensionDefinitionsRef.fineDimensions) do
                if dim.id == dimensionId then
                    fineIndex = dim.index
                    break
                end
            end
        end

        if fineIndex then
            -- Apply fulfillment to fine satisfaction
            -- Housing provides baseline satisfaction, doesn't fully fulfill
            local currentValue = self.fineSatisfaction[fineIndex] or 0
            local fulfillmentAmount = value * crowdingModifier * 0.01  -- Scale to 0-1 range
            local newValue = math.min(1.0, currentValue + fulfillmentAmount)
            self.fineSatisfaction[fineIndex] = newValue
        end
    end

    -- Track that housing fulfillment was applied this cycle
    self.lastHousingFulfillmentCycle = CharacterV3.currentGlobalSlot
end

-- Apply penalty for being homeless
function CharacterV3:ApplyHomelessPenalty(penaltyAmount)
    penaltyAmount = penaltyAmount or -50

    -- Apply penalty to shelter-related dimensions
    local shelterDimensions = {
        "safety_shelter_housing_basic",
        "safety_shelter_weather",
        "safety_shelter_warmth"
    }

    for _, dimensionId in ipairs(shelterDimensions) do
        -- Find the dimension index
        local fineIndex = nil
        if dimensionDefinitionsRef and dimensionDefinitionsRef.fineDimensions then
            for _, dim in ipairs(dimensionDefinitionsRef.fineDimensions) do
                if dim.id == dimensionId then
                    fineIndex = dim.index
                    break
                end
            end
        end

        if fineIndex then
            -- Reduce satisfaction for shelter-related dimensions
            local currentValue = self.fineSatisfaction[fineIndex] or 0.5
            local penaltyFraction = penaltyAmount * 0.01  -- Convert to 0-1 scale
            local newValue = math.max(0, currentValue + penaltyFraction)
            self.fineSatisfaction[fineIndex] = newValue
        end
    end

    -- Mark as homeless for UI purposes
    self.isHomeless = true
    self.lastHomelessPenaltyCycle = CharacterV3.currentGlobalSlot
end

return CharacterV3
