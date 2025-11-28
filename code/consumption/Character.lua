-- Character.lua
-- Character system with two-layer decay: craving decay + commodity fulfillment decay

Character = {}
Character.__index = Character

local ConsumptionMechanics = nil
local FulfillmentVectors = nil
local CharacterTraits = nil

-- Initialize data (called once at prototype start)
function Character.Init(mechanicsData, fulfillmentData, characterTraitsData)
    ConsumptionMechanics = mechanicsData
    FulfillmentVectors = fulfillmentData
    CharacterTraits = characterTraitsData
end

-- Generate a new character
function Character:New(class, id)
    local char = setmetatable({}, Character)

    -- Identity
    char.id = id or "char_" .. tostring(math.random(100000, 999999))
    char.name = Character.GenerateRandomName()
    char.age = math.random(18, 65)

    -- Classification
    char.class = class or "Middle"
    char.vocation = Character.GetRandomVocation()
    char.traits = Character.GetRandomTraits(2, char.class)

    -- Satisfaction State (0-100 for each craving)
    char.satisfaction = Character.GenerateStartingSatisfaction(char.class)

    -- Layer 2: Commodity consumption history
    char.commodityHistory = {}

    -- Craving history tracking
    char.cravingHistory = {}
    for cravingType, _ in pairs(char.satisfaction) do
        char.cravingHistory[cravingType] = {
            lastFulfilled = 0,
            cyclesSinceCritical = 0
        }
    end

    -- Allocation state
    char.allocationPriority = 0
    char.lastAllocationCycle = 0
    char.allocationSuccessRate = 0.5
    char.successCount = 0
    char.attemptCount = 0

    -- Emigration tracking
    char.consecutiveLowSatisfactionCycles = 0
    char.emigrationThreshold = ConsumptionMechanics.consequenceThresholds.emigration.averageSatisfactionThreshold[char.class]
    char.hasEmigrated = false

    -- Visual state
    char.position = {x = 0, y = 0}
    char.highlighted = false
    char.status = "idle"  -- idle/happy/stressed/leaving/variety_seeking
    char.statusMessage = ""

    return char
end

-- Generate random name
function Character.GenerateRandomName()
    local first = ConsumptionMechanics.names.first
    local last = ConsumptionMechanics.names.last
    return first[math.random(#first)] .. " " .. last[math.random(#last)]
end

-- Get random vocation
function Character.GetRandomVocation()
    local vocations = ConsumptionMechanics.vocations
    return vocations[math.random(#vocations)]
end

-- Get random traits
function Character.GetRandomTraits(count, class)
    local availableTraits = ConsumptionMechanics.characterGeneration.traits.available
    local selected = {}
    local indices = {}

    -- Randomly select traits
    while #selected < count and #selected < #availableTraits do
        local idx = math.random(#availableTraits)
        if not indices[idx] then
            indices[idx] = true
            table.insert(selected, availableTraits[idx].id)
        end
    end

    return selected
end

-- Generate starting satisfaction based on class
function Character.GenerateStartingSatisfaction(class)
    local ranges = ConsumptionMechanics.characterGeneration.startingSatisfactionRanges[class]
    local satisfaction = {}

    for cravingType, range in pairs(ranges) do
        satisfaction[cravingType] = math.random(range[1], range[2])
    end

    return satisfaction
end

-- LAYER 1: Craving Decay (time-based need regeneration)
function Character:DecayCravings(deltaTime)
    local decayRates = ConsumptionMechanics.cravingDecayRates

    for cravingType, value in pairs(self.satisfaction) do
        -- Get base decay rate for this class
        local baseDecay = decayRates[cravingType][self.class]

        -- Calculate trait multipliers from character_traits.json
        local traitMultiplier = self:CalculateTraitMultiplier(cravingType)

        -- Apply decay (normalize to 60-second cycle)
        local decay = baseDecay * traitMultiplier * (deltaTime / 60.0)
        self.satisfaction[cravingType] = math.max(0, value - decay)

        -- Track critical periods
        if self.satisfaction[cravingType] < 20 then
            self.cravingHistory[cravingType].cyclesSinceCritical =
                self.cravingHistory[cravingType].cyclesSinceCritical + 1
        end
    end
end

-- Calculate combined trait multiplier for a craving type
function Character:CalculateTraitMultiplier(cravingType)
    if not self.traits or #self.traits == 0 then
        return 1.0
    end

    -- Map craving type to coarse dimension index
    local dimensionMap = {
        biological = 1,
        safety = 2,
        touch = 3,
        psychological = 4,
        social_status = 5,
        social_connection = 6,
        exotic_goods = 7,
        shiny_objects = 8,
        vice = 9
    }
    local dimensionIndex = dimensionMap[cravingType]
    if not dimensionIndex then
        return 1.0
    end

    -- Multiplicatively combine trait multipliers
    local combinedMultiplier = 1.0
    for _, traitId in ipairs(self.traits) do
        -- Find trait data in CharacterTraits
        if CharacterTraits and CharacterTraits.traits then
            for _, traitData in ipairs(CharacterTraits.traits) do
                if traitData.id == traitId then
                    local coarseMultipliers = traitData.cravingMultipliers and traitData.cravingMultipliers.coarse
                    if coarseMultipliers and coarseMultipliers[dimensionIndex] then
                        combinedMultiplier = combinedMultiplier * coarseMultipliers[dimensionIndex]
                    end
                    break
                end
            end
        end
    end

    return combinedMultiplier
end

-- LAYER 2: Calculate commodity fulfillment multiplier (variety-seeking)
function Character:CalculateCommodityFulfillmentMultiplier(commodity, currentCycle)
    local history = self.commodityHistory[commodity]
    local config = ConsumptionMechanics.commodityDiminishingReturns

    if not history then
        -- First time consuming this commodity
        return 1.0
    end

    local consecutiveCount = history.consecutiveConsumptions
    local cyclesSinceLastConsumed = currentCycle - history.lastConsumed

    -- Reset if enough time has passed (variety cooldown)
    if cyclesSinceLastConsumed > config.varietyCooldownCycles then
        history.consecutiveConsumptions = 0
        history.fulfillmentMultiplier = 1.0
        return 1.0
    end

    -- Diminishing returns formula
    local multiplier = math.max(
        config.minMultiplier,
        1.0 - (consecutiveCount * config.decayRate)
    )

    history.fulfillmentMultiplier = multiplier
    return multiplier
end

-- LAYER 2: Update commodity consumption history
function Character:UpdateCommodityHistory(commodity, currentCycle)
    local config = ConsumptionMechanics.commodityDiminishingReturns

    if not self.commodityHistory[commodity] then
        self.commodityHistory[commodity] = {
            lastConsumed = currentCycle,
            consecutiveConsumptions = 1,
            fulfillmentMultiplier = 1.0
        }
    else
        local history = self.commodityHistory[commodity]
        local cyclesSinceLast = currentCycle - history.lastConsumed

        if cyclesSinceLast <= config.varietyCooldownCycles then
            -- Still in "tired of this" period
            history.consecutiveConsumptions = history.consecutiveConsumptions + 1
        else
            -- Cooldown expired, reset counter
            history.consecutiveConsumptions = 1
        end

        history.lastConsumed = currentCycle
    end

    -- Decay other commodities' consecutive counts (variety bonus)
    for otherCommodity, otherHistory in pairs(self.commodityHistory) do
        if otherCommodity ~= commodity then
            local cyclesSince = currentCycle - otherHistory.lastConsumed
            if cyclesSince >= config.otherCommodityDecayCycles then
                -- Reduce consecutive count over time
                otherHistory.consecutiveConsumptions = math.max(0,
                    otherHistory.consecutiveConsumptions - config.otherCommodityDecayRate)
            end
        end
    end
end

-- Fulfill craving by consuming a commodity (BOTH LAYERS)
function Character:FulfillCraving(commodity, quantity, currentCycle)
    local commodityData = FulfillmentVectors.commodities[commodity]
    if not commodityData then
        print("Warning: No fulfillment data for commodity: " .. commodity)
        return false
    end

    -- LAYER 2: Get commodity-specific diminishing returns multiplier
    local commodityMultiplier = self:CalculateCommodityFulfillmentMultiplier(commodity, currentCycle)

    -- Get quality multiplier (from commodity's qualityMultipliers or default to basic)
    local qualityMultipliers = commodityData.qualityMultipliers or {basic = 1.0}
    local qualityMultiplier = qualityMultipliers.basic or 1.0

    -- Use coarse fulfillment vector (9 dimensions)
    local coarseVector = commodityData.fulfillmentVector.coarse
    if not coarseVector then
        print("Warning: No coarse fulfillment vector for: " .. commodity)
        return false
    end

    -- Map coarse dimensions to craving names
    local dimensionNames = {
        "biological",      -- index 0 -> 1 in Lua
        "safety",          -- index 1 -> 2
        "touch",           -- index 2 -> 3
        "psychological",   -- index 3 -> 4
        "social_status",   -- index 4 -> 5
        "social_connection", -- index 5 -> 6
        "exotic_goods",    -- index 6 -> 7
        "shiny_objects",   -- index 7 -> 8
        "vice"             -- index 8 -> 9
    }

    -- Apply fulfillment to each craving
    local totalGain = 0
    for i, dimensionName in ipairs(dimensionNames) do
        local basePoints = coarseVector[i]  -- Lua 1-based indexing
        if basePoints and basePoints > 0 then
            -- Calculate gain with BOTH quality AND commodity variety multipliers
            local gain = basePoints * qualityMultiplier * commodityMultiplier * quantity

            -- Apply with cap (can't exceed 100)
            local oldValue = self.satisfaction[dimensionName] or 0
            self.satisfaction[dimensionName] = math.min(100, oldValue + gain)
            totalGain = totalGain + gain

            -- Reset critical tracker
            if self.cravingHistory[dimensionName] then
                self.cravingHistory[dimensionName].lastFulfilled = currentCycle
                self.cravingHistory[dimensionName].cyclesSinceCritical = 0
            end
        end
    end

    -- LAYER 2: Update commodity consumption history
    self:UpdateCommodityHistory(commodity, currentCycle)

    -- Visual feedback for variety-seeking
    local config = ConsumptionMechanics.commodityDiminishingReturns
    if commodityMultiplier < config.varietySeekingThreshold then
        self.status = "variety_seeking"
        self.statusMessage = "🔁 Tired of " .. commodity
    else
        self.status = "happy"
        self.statusMessage = ""
    end

    return true, totalGain, commodityMultiplier
end

-- Check if character accepts a quality level (simplified for now)
function Character:AcceptsQuality(quality)
    -- For now, all characters accept all qualities
    -- TODO: Implement class-based quality acceptance
    return true
end

-- Calculate allocation priority (used by allocation engine)
function Character:CalculatePriority(currentCycle)
    local config = ConsumptionMechanics.priorityCalculation

    -- Base class weight
    local classWeight = config.classWeights[self.class]

    -- Calculate desperation score
    local desperationScore = 0
    for cravingType, satisfaction in pairs(self.satisfaction) do
        local cravingWeight = config.cravingPriorityWeights[cravingType] or 0.5

        -- Determine desperation level
        local desperationMultiplier
        if satisfaction < config.desperationThresholds.critical then
            desperationMultiplier = config.desperationMultipliers.critical
        elseif satisfaction < config.desperationThresholds.low then
            desperationMultiplier = config.desperationMultipliers.low
        elseif satisfaction < config.desperationThresholds.medium then
            desperationMultiplier = config.desperationMultipliers.medium
        elseif satisfaction < config.desperationThresholds.high then
            desperationMultiplier = config.desperationMultipliers.high
        else
            desperationMultiplier = config.desperationMultipliers.satisfied
        end

        desperationScore = desperationScore + (desperationMultiplier * cravingWeight)
    end

    -- Calculate final priority
    self.allocationPriority = classWeight * 100 + desperationScore

    return self.allocationPriority
end

-- Get average satisfaction
function Character:GetAverageSatisfaction()
    local sum = 0
    local count = 0
    for _, value in pairs(self.satisfaction) do
        sum = sum + value
        count = count + 1
    end
    return count > 0 and (sum / count) or 0
end

-- Get critical craving count
function Character:GetCriticalCravingCount()
    local count = 0
    for _, value in pairs(self.satisfaction) do
        if value < 20 then
            count = count + 1
        end
    end
    return count
end

-- Check if character should emigrate
function Character:CheckEmigration(currentCycle)
    if self.hasEmigrated then
        return false
    end

    local config = ConsumptionMechanics.consequenceThresholds.emigration
    if not config.enabled then
        return false
    end

    local avgSatisfaction = self:GetAverageSatisfaction()

    -- Track low satisfaction cycles
    if avgSatisfaction < config.averageSatisfactionThreshold[self.class] then
        self.consecutiveLowSatisfactionCycles = self.consecutiveLowSatisfactionCycles + 1
    else
        self.consecutiveLowSatisfactionCycles = 0
    end

    -- Check emigration conditions
    local criticalCount = self:GetCriticalCravingCount()
    local threshold = config.consecutiveLowSatisfactionCycles[self.class]

    if self.consecutiveLowSatisfactionCycles >= threshold and
       criticalCount >= config.criticalCravingsRequired then
        -- Roll for emigration
        if math.random() < config.emigrationChancePerCycle then
            self.hasEmigrated = true
            self.status = "leaving"
            self.statusMessage = "💼 Emigrating"
            return true
        end
    end

    return false
end

-- Update allocation success rate
function Character:RecordAllocationAttempt(success, currentCycle)
    self.attemptCount = self.attemptCount + 1
    if success then
        self.successCount = self.successCount + 1
    end
    self.allocationSuccessRate = self.successCount / self.attemptCount
    self.lastAllocationCycle = currentCycle
end

return Character
