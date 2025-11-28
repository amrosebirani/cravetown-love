-- CharacterV2.lua
-- Complete 6-layer character state model for consumption system
-- Layers: Identity → Base Cravings → Current Cravings → Satisfaction → Commodity Multipliers → History

Character = {}
Character.__index = Character

-- Module-level data (loaded once at init)
local ConsumptionMechanics = nil
local FulfillmentVectors = nil
local CharacterTraits = nil
local CharacterClasses = nil
local DimensionDefinitions = nil
local CommodityFatigueRates = nil
local EnablementRules = nil

-- Initialize data (called once at prototype start)
function Character.Init(mechanicsData, fulfillmentData, traitsData, classesData, dimensionsData, fatigueData, enablementData)
    ConsumptionMechanics = mechanicsData
    FulfillmentVectors = fulfillmentData
    CharacterTraits = traitsData
    CharacterClasses = classesData
    DimensionDefinitions = dimensionsData
    CommodityFatigueRates = fatigueData
    EnablementRules = enablementData

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

    if not DimensionDefinitions then return end

    -- Map coarse dimension indices to names and vice versa
    for _, coarseDim in ipairs(DimensionDefinitions.coarseDimensions) do
        Character.coarseNames[coarseDim.index] = coarseDim.id
        Character.coarseNameToIndex[coarseDim.id] = coarseDim.index
    end

    -- Map fine dimensions to their parent coarse
    for _, fineDim in ipairs(DimensionDefinitions.fineDimensions) do
        Character.fineNames[fineDim.index] = fineDim.id
        -- Convert parent coarse name to index
        local parentCoarseIndex = Character.coarseNameToIndex[fineDim.parentCoarse]
        if parentCoarseIndex then
            Character.fineToCoarseMap[fineDim.index] = parentCoarseIndex
        else
            print("Warning: Unknown parent coarse '" .. tostring(fineDim.parentCoarse) .. "' for fine dimension " .. tostring(fineDim.index))
        end
    end

    -- Build coarse to fine range mapping
    for coarseIdx = 0, 8 do
        local fineStart = nil
        local fineEnd = nil

        for fineIdx = 0, 48 do
            if Character.fineToCoarseMap[fineIdx] == coarseIdx then
                if not fineStart then
                    fineStart = fineIdx
                end
                fineEnd = fineIdx
            end
        end

        if fineStart then
            Character.coarseToFineMap[coarseIdx] = {
                start = fineStart,
                finish = fineEnd
            }
        end
    end

    -- Debug output
    print("CharacterV2 dimension maps built:")
    print("  Coarse dimensions: " .. #DimensionDefinitions.coarseDimensions)
    print("  Fine dimensions: " .. #DimensionDefinitions.fineDimensions)
    print("  coarseToFineMap entries: " .. tostring(#Character.coarseToFineMap))
    for idx, range in pairs(Character.coarseToFineMap) do
        local name = Character.coarseNames[idx] or "unknown"
        print(string.format("    [%d] %s: fine %d-%d", idx, name, range.start, range.finish))
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
    char.currentCravings = {}
    for i = 0, 48 do
        char.currentCravings[i] = 0
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

    print(string.format("GenerateBaseCravings called with class='%s'", tostring(class)))

    if not CharacterClasses or not CharacterClasses.classes then
        -- Fallback: uniform distribution
        print("  Warning: CharacterClasses not loaded, using fallback")
        for i = 0, 48 do
            baseCravings[i] = 1.0
        end
        return baseCravings
    end

    -- Find class data
    local classData = nil
    for _, c in ipairs(CharacterClasses.classes) do
        if c.id == class then
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

    -- Copy fine-grained base cravings from class
    for i = 0, 48 do
        baseCravings[i] = classData.baseCravingVector.fine[i + 1] or 0  -- Lua 1-indexed
    end

    -- Apply trait multipliers to base cravings
    if traits and #traits > 0 and CharacterTraits and CharacterTraits.traits then
        for _, traitId in ipairs(traits) do
            for _, traitData in ipairs(CharacterTraits.traits) do
                if traitData.id == traitId and traitData.cravingMultipliers and traitData.cravingMultipliers.fine then
                    for i = 0, 48 do
                        local multiplier = traitData.cravingMultipliers.fine[i + 1] or 1.0
                        baseCravings[i] = baseCravings[i] * multiplier
                    end
                    break
                end
            end
        end
    end

    return baseCravings
end

-- =============================================================================
-- LAYER 4: Generate Starting Satisfaction (coarse 9D)
-- =============================================================================

function Character.GenerateStartingSatisfaction(class)
    local satisfaction = {}

    -- Use consumption_mechanics starting ranges (coarse)
    if ConsumptionMechanics and ConsumptionMechanics.characterGeneration and
       ConsumptionMechanics.characterGeneration.startingSatisfactionRanges and
       ConsumptionMechanics.characterGeneration.startingSatisfactionRanges[class] then
        local ranges = ConsumptionMechanics.characterGeneration.startingSatisfactionRanges[class]
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

    for i = 0, 48 do
        local baseRate = self.baseCravings[i] or 0
        self.currentCravings[i] = self.currentCravings[i] + (baseRate * ratio)

        -- Cap at reasonable max (e.g., 200)
        self.currentCravings[i] = math.min(self.currentCravings[i], 200)
    end
end

-- =============================================================================
-- LAYER 4: Update Satisfaction (Lifetime Tracker)
-- =============================================================================

function Character:UpdateSatisfaction(currentCycle)
    -- Satisfaction decays naturally over time based on currentCravings
    -- Higher unfulfilled currentCravings = faster satisfaction decay

    if not ConsumptionMechanics or not ConsumptionMechanics.cravingDecayRates then
        return
    end

    local decayRates = ConsumptionMechanics.cravingDecayRates

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

    if CommodityFatigueRates and CommodityFatigueRates.commodities and
       CommodityFatigueRates.commodities[commodity] then
        local fatigueData = CommodityFatigueRates.commodities[commodity]
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
    local cooldownCycles = ConsumptionMechanics and
                          ConsumptionMechanics.commodityDiminishingReturns and
                          ConsumptionMechanics.commodityDiminishingReturns.varietyCooldownCycles or 10

    if cyclesSinceLast > cooldownCycles then
        -- Reset fatigue
        return 1.0
    end

    -- Calculate fatigue multiplier using exponential decay
    -- multiplier = exp(-consecutiveCount * effectiveFatigueRate)
    local multiplier = math.exp(-consecutiveCount * effectiveFatigueRate)

    -- Apply min threshold
    local minMultiplier = ConsumptionMechanics and
                         ConsumptionMechanics.commodityDiminishingReturns and
                         ConsumptionMechanics.commodityDiminishingReturns.minMultiplier or 0.25

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

        local cooldownCycles = ConsumptionMechanics and
                              ConsumptionMechanics.commodityDiminishingReturns and
                              ConsumptionMechanics.commodityDiminishingReturns.varietyCooldownCycles or 10

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
    local decayCycles = ConsumptionMechanics and
                       ConsumptionMechanics.commodityDiminishingReturns and
                       ConsumptionMechanics.commodityDiminishingReturns.otherCommodityDecayCycles or 3

    local decayRate = ConsumptionMechanics and
                     ConsumptionMechanics.commodityDiminishingReturns and
                     ConsumptionMechanics.commodityDiminishingReturns.otherCommodityDecayRate or 1

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

function Character:FulfillCraving(commodity, quantity, currentCycle)
    if not FulfillmentVectors or not FulfillmentVectors.commodities then
        print("Error: FulfillmentVectors not initialized")
        return false, 0, 1.0
    end

    local commodityData = FulfillmentVectors.commodities[commodity]
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
        fatigueMultiplier = fatigueMultiplier
    })

    -- Trim history to max length
    while #self.consumptionHistory > self.maxHistoryLength do
        table.remove(self.consumptionHistory)
    end

    -- Visual feedback
    local varietyThreshold = ConsumptionMechanics and
                            ConsumptionMechanics.commodityDiminishingReturns and
                            ConsumptionMechanics.commodityDiminishingReturns.varietySeekingThreshold or 0.70

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

    if not EnablementRules or not EnablementRules.rules then
        return false
    end

    -- Find the rule
    local rule = nil
    for _, r in ipairs(EnablementRules.rules) do
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
                    local weight = 1.0  -- Could use aggregationWeight from dimension_definitions
                    total = total + (self.currentCravings[fineIndex] or 0) * weight
                    totalWeight = totalWeight + weight
                    count = count + 1
                end
            end

            coarseCravings[coarseName] = totalWeight > 0 and (total / totalWeight) or 0
        end
    end

    return coarseCravings
end

-- =============================================================================
-- Priority Calculation (with fairness modes)
-- =============================================================================

function Character:CalculatePriority(currentCycle, allocationMode)
    if not ConsumptionMechanics or not ConsumptionMechanics.priorityCalculation then
        return 100
    end

    local config = ConsumptionMechanics.priorityCalculation

    -- Base class weight
    local classWeight = config.classWeights[self.class] or 1

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

    -- Calculate base priority
    local basePriority = classWeight * 100 + desperationScore

    -- Apply fairness penalty if in fairness mode
    local finalPriority = basePriority
    if allocationMode == "fairness" then
        finalPriority = basePriority - self.fairnessPenalty
    end

    self.allocationPriority = finalPriority
    return finalPriority
end

-- Check if character accepts a given quality level
function Character:AcceptsQuality(quality)
    -- For now, all characters accept all qualities
    -- TODO: Implement class-based quality acceptance (e.g., elite prefers luxury)
    return true
end

-- =============================================================================
-- Utility Functions
-- =============================================================================

function Character.GenerateRandomName()
    if not ConsumptionMechanics or not ConsumptionMechanics.names then
        return "Character_" .. math.random(1000, 9999)
    end

    local first = ConsumptionMechanics.names.first
    local last = ConsumptionMechanics.names.last
    return first[math.random(#first)] .. " " .. last[math.random(#last)]
end

function Character.GetRandomVocation()
    if not ConsumptionMechanics or not ConsumptionMechanics.vocations then
        return "Worker"
    end

    local vocations = ConsumptionMechanics.vocations
    return vocations[math.random(#vocations)]
end

function Character.GetRandomTraits(count, class)
    if not ConsumptionMechanics or not ConsumptionMechanics.characterGeneration or
       not ConsumptionMechanics.characterGeneration.traits or
       not ConsumptionMechanics.characterGeneration.traits.available then
        return {}
    end

    local availableTraits = ConsumptionMechanics.characterGeneration.traits.available
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
    local sum = 0
    local count = 0
    for _, value in pairs(self.satisfaction) do
        sum = sum + value
        count = count + 1
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

    if not ConsumptionMechanics or not ConsumptionMechanics.consequenceThresholds or
       not ConsumptionMechanics.consequenceThresholds.emigration then
        return false
    end

    local config = ConsumptionMechanics.consequenceThresholds.emigration
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

    if not ConsumptionMechanics or not ConsumptionMechanics.consequenceThresholds or
       not ConsumptionMechanics.consequenceThresholds.productivity then
        return
    end

    local config = ConsumptionMechanics.consequenceThresholds.productivity
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

    if not ConsumptionMechanics or not ConsumptionMechanics.consequenceThresholds or
       not ConsumptionMechanics.consequenceThresholds.protest then
        return false
    end

    local config = ConsumptionMechanics.consequenceThresholds.protest
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

return Character
