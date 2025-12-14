-- AllocationEngine.lua
-- Priority-based allocation with substitution and variety-seeking

AllocationEngine = {}

local ConsumptionMechanics = nil
local FulfillmentVectors = nil
local SubstitutionRules = nil

-- Initialize data
function AllocationEngine.Init(mechanicsData, fulfillmentData, substitutionData)
    ConsumptionMechanics = mechanicsData
    FulfillmentVectors = fulfillmentData
    SubstitutionRules = substitutionData
end

-- Allocate resources for one cycle
function AllocationEngine.AllocateCycle(characters, townInventory, currentCycle)
    local allocationLog = {
        cycle = currentCycle,
        timestamp = os.time(),
        allocations = {},
        stats = {
            totalAttempts = 0,
            granted = 0,
            substituted = 0,
            failed = 0
        },
        shortages = {}
    }

    -- Calculate priorities for all characters
    for _, character in ipairs(characters) do
        if not character.hasEmigrated then
            character:CalculatePriority(currentCycle)
        end
    end

    -- Sort characters by priority (highest first)
    local sortedCharacters = {}
    for _, character in ipairs(characters) do
        if not character.hasEmigrated then
            table.insert(sortedCharacters, character)
        end
    end
    table.sort(sortedCharacters, function(a, b)
        return a.allocationPriority > b.allocationPriority
    end)

    -- Allocate resources in priority order
    for rank, character in ipairs(sortedCharacters) do
        local allocation = AllocationEngine.AllocateForCharacter(
            character, townInventory, currentCycle, rank
        )
        table.insert(allocationLog.allocations, allocation)

        -- Update stats
        allocationLog.stats.totalAttempts = allocationLog.stats.totalAttempts + 1
        if allocation.status == "granted" then
            allocationLog.stats.granted = allocationLog.stats.granted + 1
        elseif allocation.status == "substituted" then
            allocationLog.stats.substituted = allocationLog.stats.substituted + 1
        else
            allocationLog.stats.failed = allocationLog.stats.failed + 1
        end

        -- Track shortages
        if allocation.status == "failed" then
            local commodity = allocation.requestedCommodity
            allocationLog.shortages[commodity] = (allocationLog.shortages[commodity] or 0) + 1
        end
    end

    return allocationLog
end

-- Allocate resources for a single character
function AllocationEngine.AllocateForCharacter(character, townInventory, currentCycle, rank)
    local allocation = {
        rank = rank,
        characterId = character.id,
        characterName = character.name,
        characterClass = character.class,
        priority = character.allocationPriority,
        requestedCommodity = nil,
        allocatedCommodity = nil,
        quantity = 1,
        status = "failed",  -- granted/substituted/failed
        satisfactionGain = 0,
        varietyMultiplier = 1.0,
        substitutionChain = {}
    }

    -- Determine which craving to address (lowest satisfaction with highest weight)
    local targetCraving, targetCommodity = AllocationEngine.SelectTargetCraving(character, currentCycle)

    if not targetCraving then
        allocation.status = "no_needs"
        return allocation
    end

    allocation.requestedCommodity = targetCommodity

    -- Try to allocate the primary commodity
    if townInventory[targetCommodity] and townInventory[targetCommodity] > 0 then
        -- Check if character is tired of this commodity
        local varietyMultiplier = character:CalculateCommodityFulfillmentMultiplier(targetCommodity, currentCycle)
        local config = ConsumptionMechanics.commodityDiminishingReturns

        -- If tired (< threshold), try substitutes first
        if varietyMultiplier < config.varietySeekingThreshold then
            local substitute, chain = AllocationEngine.FindBestSubstitute(
                targetCommodity, targetCraving, character, townInventory, currentCycle
            )

            if substitute and substitute ~= targetCommodity then
                -- Use substitute instead
                allocation.allocatedCommodity = substitute
                allocation.substitutionChain = chain
                allocation.status = "substituted"
                allocation.varietyMultiplier = character:CalculateCommodityFulfillmentMultiplier(substitute, currentCycle)

                -- Consume from inventory
                townInventory[substitute] = townInventory[substitute] - allocation.quantity

                -- Fulfill craving
                local success, gain, _ = character:FulfillCraving(substitute, allocation.quantity, currentCycle)
                allocation.satisfactionGain = gain or 0
                character:RecordAllocationAttempt(true, currentCycle)

                return allocation
            end
        end

        -- Allocate primary commodity
        allocation.allocatedCommodity = targetCommodity
        allocation.status = "granted"
        allocation.varietyMultiplier = varietyMultiplier

        -- Consume from inventory
        townInventory[targetCommodity] = townInventory[targetCommodity] - allocation.quantity

        -- Fulfill craving
        local success, gain, _ = character:FulfillCraving(targetCommodity, allocation.quantity, currentCycle)
        allocation.satisfactionGain = gain or 0
        character:RecordAllocationAttempt(true, currentCycle)

        return allocation
    end

    -- Primary commodity not available, try substitution
    local substitute, chain = AllocationEngine.FindBestSubstitute(
        targetCommodity, targetCraving, character, townInventory, currentCycle
    )

    if substitute then
        allocation.allocatedCommodity = substitute
        allocation.substitutionChain = chain
        allocation.status = "substituted"
        allocation.varietyMultiplier = character:CalculateCommodityFulfillmentMultiplier(substitute, currentCycle)

        -- Consume from inventory
        townInventory[substitute] = townInventory[substitute] - allocation.quantity

        -- Fulfill craving
        local success, gain, _ = character:FulfillCraving(substitute, allocation.quantity, currentCycle)
        allocation.satisfactionGain = gain or 0
        character:RecordAllocationAttempt(true, currentCycle)

        return allocation
    end

    -- Failed to allocate anything
    allocation.status = "failed"
    character:RecordAllocationAttempt(false, currentCycle)

    return allocation
end

-- Select which craving to target for this character
function AllocationEngine.SelectTargetCraving(character, currentCycle)
    local config = ConsumptionMechanics.priorityCalculation
    local lowestScore = math.huge
    local targetCraving = nil
    local targetCommodity = nil

    for cravingType, satisfaction in pairs(character.satisfaction) do
        local weight = config.cravingPriorityWeights[cravingType] or 0.5
        local score = satisfaction / weight  -- Lower score = higher priority

        if score < lowestScore then
            lowestScore = score
            targetCraving = cravingType
        end
    end

    if targetCraving then
        -- Find best commodity for this craving
        targetCommodity = AllocationEngine.GetBestCommodityForCraving(targetCraving, character, currentCycle)
    end

    return targetCraving, targetCommodity
end

-- Get best commodity for a craving dimension
function AllocationEngine.GetBestCommodityForCraving(cravingType, character, currentCycle)
    local bestCommodity = nil
    local bestScore = 0

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
        return nil
    end

    for commodityId, commodityData in pairs(FulfillmentVectors.commodities) do
        local coarseVector = commodityData.fulfillmentVector and commodityData.fulfillmentVector.coarse
        if coarseVector then
            local points = coarseVector[dimensionIndex]
            if points and points > 0 then
                -- Consider quality acceptance
                if character:AcceptsQuality(commodityData.quality or "basic") then
                    -- Factor in variety (prefer commodities we haven't consumed recently)
                    local varietyMultiplier = character:CalculateCommodityFulfillmentMultiplier(commodityId, currentCycle)
                    local score = points * varietyMultiplier

                    if score > bestScore then
                        bestScore = score
                        bestCommodity = commodityId
                    end
                end
            end
        end
    end

    return bestCommodity
end

-- Find best available substitute for a commodity
function AllocationEngine.FindBestSubstitute(primaryCommodity, targetCraving, character, townInventory, currentCycle)
    local bestSubstitute = nil
    local bestScore = 0
    local bestChain = {}

    -- Check hierarchy substitutes first
    for category, commodities in pairs(SubstitutionRules.substitutionHierarchies) do
        if commodities[primaryCommodity] then
            for _, substituteRule in ipairs(commodities[primaryCommodity].substitutes) do
                local substituteCommodity = substituteRule.commodity
                local efficiency = substituteRule.efficiency

                -- Check availability
                if townInventory[substituteCommodity] and townInventory[substituteCommodity] > 0 then
                    -- Check quality acceptance
                    local substData = FulfillmentVectors.commodities[substituteCommodity]
                    if substData and character:AcceptsQuality(substData.quality) then
                        -- Calculate score with variety multiplier
                        local varietyMultiplier = character:CalculateCommodityFulfillmentMultiplier(substituteCommodity, currentCycle)
                        local score = efficiency * varietyMultiplier

                        -- Prefer substitutes with better variety multiplier
                        if score > bestScore then
                            bestScore = score
                            bestSubstitute = substituteCommodity
                            bestChain = {
                                {commodity = primaryCommodity, available = 0},
                                {commodity = substituteCommodity, available = townInventory[substituteCommodity], efficiency = efficiency}
                            }
                        end
                    end
                end
            end
        end
    end

    -- If desperate and nothing found, try cross-category desperation substitutes
    if not bestSubstitute then
        local desperationConfig = SubstitutionRules.desperationSubstitution
        if desperationConfig.enabled then
            local satisfaction = character.satisfaction[targetCraving] or 50
            if satisfaction < desperationConfig.criticalThreshold then
                local desperateRules = desperationConfig.rules[targetCraving]
                if desperateRules then
                    for _, rule in ipairs(desperateRules.desperateSubstitutes) do
                        local substituteCommodity = rule.commodity
                        local efficiency = rule.efficiency

                        if townInventory[substituteCommodity] and townInventory[substituteCommodity] > 0 then
                            local substData = FulfillmentVectors.commodities[substituteCommodity]
                            if substData and character:AcceptsQuality(substData.quality) then
                                local varietyMultiplier = character:CalculateCommodityFulfillmentMultiplier(substituteCommodity, currentCycle)
                                local score = efficiency * varietyMultiplier * 0.8  -- Penalty for desperation substitution

                                if score > bestScore then
                                    bestScore = score
                                    bestSubstitute = substituteCommodity
                                    bestChain = {
                                        {commodity = primaryCommodity, available = 0},
                                        {commodity = substituteCommodity, available = townInventory[substituteCommodity], efficiency = efficiency, desperation = true}
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return bestSubstitute, bestChain
end

return AllocationEngine
