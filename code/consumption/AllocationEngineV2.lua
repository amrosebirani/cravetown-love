-- AllocationEngineV2.lua
-- Refactored allocation engine to work with CharacterV2 (6-layer state model)
-- Key changes from V1:
-- 1. Works with 49D fine-grained dimensions internally
-- 2. Aggregates to 9D coarse dimensions for allocation decisions
-- 3. Uses distance-based boost for substitution
-- 4. Supports fairness mode in priority calculation

local AllocationEngineV2 = {}

local ConsumptionMechanics = nil
local FulfillmentVectors = nil
local SubstitutionRules = nil
local CharacterV2 = nil
local CommodityCache = nil

-- Initialize data
function AllocationEngineV2.Init(mechanicsData, fulfillmentData, substitutionData, characterV2Module, cacheModule)
    ConsumptionMechanics = mechanicsData
    FulfillmentVectors = fulfillmentData
    SubstitutionRules = substitutionData
    CharacterV2 = characterV2Module
    CommodityCache = cacheModule
end

-- Allocate resources for one cycle
function AllocationEngineV2.AllocateCycle(characters, townInventory, currentCycle, mode)
    mode = mode or "standard"  -- "standard" or "fairness"

    local allocationLog = {
        cycle = currentCycle,
        timestamp = os.time(),
        mode = mode,
        allocations = {},
        stats = {
            totalAttempts = 0,
            granted = 0,
            substituted = 0,
            failed = 0
        },
        shortages = {}
    }

    -- Calculate priorities for all characters with mode
    for _, character in ipairs(characters) do
        if not character.hasEmigrated then
            character:CalculatePriority(currentCycle, mode)
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
        local allocation = AllocationEngineV2.AllocateForCharacter(
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
        if allocation.status == "failed" and allocation.requestedCommodity then
            local commodity = allocation.requestedCommodity
            allocationLog.shortages[commodity] = (allocationLog.shortages[commodity] or 0) + 1
        end
    end

    return allocationLog
end

-- Allocate resources for a single character
function AllocationEngineV2.AllocateForCharacter(character, townInventory, currentCycle, rank)
    local allocation = {
        rank = rank,
        characterId = character.id or character.name,
        characterName = character.name,
        characterClass = character.class,
        priority = character.allocationPriority,
        requestedCommodity = nil,
        allocatedCommodity = nil,
        quantity = 1,
        status = "failed",  -- granted/substituted/failed/no_needs
        satisfactionGain = 0,
        commodityMultiplier = 1.0,  -- Changed from varietyMultiplier
        substitutionChain = {}
    }

    -- Determine which craving to address (highest currentCraving with highest weight)
    local targetCoarseCraving, targetCommodity = AllocationEngineV2.SelectTargetCraving(character, townInventory, currentCycle)

    if not targetCoarseCraving then
        allocation.status = "no_needs"
        return allocation
    end

    allocation.requestedCommodity = targetCommodity

    -- Try to allocate the primary commodity
    if townInventory[targetCommodity] and townInventory[targetCommodity] > 0 then
        -- Check commodity multiplier (fatigue)
        local commodityMultiplier = character:CalculateCommodityMultiplier(targetCommodity, currentCycle)
        local config = ConsumptionMechanics.commodityDiminishingReturns

        -- If fatigued (< threshold), try substitutes first
        if commodityMultiplier < config.varietySeekingThreshold then
            local substitute, chain = AllocationEngineV2.FindBestSubstitute(
                targetCommodity, targetCoarseCraving, character, townInventory, currentCycle
            )

            if substitute and substitute ~= targetCommodity then
                -- Use substitute instead
                allocation.allocatedCommodity = substitute
                allocation.substitutionChain = chain
                allocation.status = "substituted"
                allocation.commodityMultiplier = character:CalculateCommodityMultiplier(substitute, currentCycle)

                -- Consume from inventory
                townInventory[substitute] = townInventory[substitute] - allocation.quantity

                -- Invalidate cache for this commodity
                if CommodityCache then
                    CommodityCache.InvalidateCommodity(substitute)
                end

                -- Fulfill craving
                local success, gain, multiplier = character:FulfillCraving(substitute, allocation.quantity, currentCycle)
                allocation.satisfactionGain = gain or 0
                character:RecordAllocationAttempt(true, currentCycle)

                return allocation
            end
        end

        -- Allocate primary commodity
        allocation.allocatedCommodity = targetCommodity
        allocation.status = "granted"
        allocation.commodityMultiplier = commodityMultiplier

        -- Consume from inventory
        townInventory[targetCommodity] = townInventory[targetCommodity] - allocation.quantity

        -- Invalidate cache for this commodity
        if CommodityCache then
            CommodityCache.InvalidateCommodity(targetCommodity)
        end

        -- Fulfill craving
        local success, gain, multiplier = character:FulfillCraving(targetCommodity, allocation.quantity, currentCycle)
        allocation.satisfactionGain = gain or 0
        character:RecordAllocationAttempt(true, currentCycle)

        return allocation
    end

    -- Primary commodity not available, try substitution
    local substitute, chain = AllocationEngineV2.FindBestSubstitute(
        targetCommodity, targetCoarseCraving, character, townInventory, currentCycle
    )

    if substitute then
        allocation.allocatedCommodity = substitute
        allocation.substitutionChain = chain
        allocation.status = "substituted"
        allocation.commodityMultiplier = character:CalculateCommodityMultiplier(substitute, currentCycle)

        -- Consume from inventory
        townInventory[substitute] = townInventory[substitute] - allocation.quantity

        -- Invalidate cache for this commodity
        if CommodityCache then
            CommodityCache.InvalidateCommodity(substitute)
        end

        -- Fulfill craving
        local success, gain, multiplier = character:FulfillCraving(substitute, allocation.quantity, currentCycle)
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
-- Works at fine-grained (49D) level to avoid medicine dominating biological
function AllocationEngineV2.SelectTargetCraving(character, townInventory, currentCycle)
    local config = ConsumptionMechanics.priorityCalculation
    local bestCommodity = nil
    local bestScore = 0
    local bestCoarseName = nil

    -- Debug: show coarse cravings for context
    local coarseCravings = character:AggregateCurrentCravingsToCoarse()
    print(string.format("  SelectTargetCraving for %s:", character.name))
    for coarseName, cravingValue in pairs(coarseCravings) do
        print(string.format("    %s: %.2f", coarseName, cravingValue))
    end

    -- Iterate through fine dimensions (0-48) and find best available commodity
    -- This avoids the problem where high-value items (medicine=50) dominate coarse categories
    for fineIdx = 0, 48 do
        local fineCraving = character.currentCravings[fineIdx] or 0

        if fineCraving > 0 then
            local fineName = CharacterV2.fineNames[fineIdx]
            local coarseIdx = CharacterV2.fineToCoarseMap[fineIdx]
            local coarseName = CharacterV2.coarseNames[coarseIdx]
            local coarseWeight = config.cravingPriorityWeights[coarseName] or 0.5

            -- Check all available commodities that fulfill this fine dimension
            for commodityId, commodityData in pairs(FulfillmentVectors.commodities) do
                if townInventory[commodityId] and townInventory[commodityId] > 0 then
                    local fineVector = commodityData.fulfillmentVector and commodityData.fulfillmentVector.fine
                    if fineVector and fineVector[fineName] then
                        local fulfillmentPoints = fineVector[fineName]
                        local quality = commodityData.quality or "basic"

                        if character:AcceptsQuality(quality) then
                            local commodityMultiplier = character:CalculateCommodityMultiplier(commodityId, currentCycle)
                            -- Score = craving * coarse weight * fulfillment points * commodity multiplier
                            local score = fineCraving * coarseWeight * fulfillmentPoints * commodityMultiplier

                            if score > bestScore then
                                bestScore = score
                                bestCommodity = commodityId
                                bestCoarseName = coarseName
                            end
                        end
                    end
                end
            end
        end
    end

    print(string.format("  Target dimension: %s, Best commodity: %s (score=%.2f)",
        tostring(bestCoarseName), tostring(bestCommodity), bestScore))

    return bestCoarseName, bestCommodity
end

-- Get best commodity for a coarse craving dimension
-- Uses fine-grained (49D) fulfillment vectors internally
-- Only considers commodities that are available in townInventory
function AllocationEngineV2.GetBestCommodityForCraving(coarseCraving, character, townInventory, currentCycle)
    local bestCommodity = nil
    local bestScore = 0

    -- Map coarse craving to coarse dimension index (0-8 for CharacterV2)
    local coarseIndex = CharacterV2.coarseNameToIndex[coarseCraving]
    if not coarseIndex then
        return nil
    end

    -- Get range of fine dimensions for this coarse dimension
    local fineRange = CharacterV2.coarseToFineMap[coarseIndex]
    if not fineRange then
        print("Warning: No fine dimension range for coarse index " .. tostring(coarseIndex))
        return nil
    end

    -- Iterate through all commodities and calculate fine-grained match score
    local checkedCount = 0
    local availableCount = 0
    for commodityId, commodityData in pairs(FulfillmentVectors.commodities) do
        -- Only consider commodities that are available in inventory
        if townInventory[commodityId] and townInventory[commodityId] > 0 then
            checkedCount = checkedCount + 1
            local fineVector = commodityData.fulfillmentVector and commodityData.fulfillmentVector.fine
            if fineVector then
                availableCount = availableCount + 1
                -- Calculate total fine-dimensional contribution for this coarse dimension
                local totalPoints = 0
                local count = 0

                local fineStart = fineRange.start
                local fineEnd = fineRange.finish

                for fineIdx = fineStart, fineEnd do
                    -- Get the string name for this fine dimension (e.g., "biological_nutrition_grain")
                    local fineName = CharacterV2.fineNames[fineIdx]
                    if fineName then
                        local points = fineVector[fineName] or 0
                        if points > 0 then
                            totalPoints = totalPoints + points
                            count = count + 1
                        end
                    end
                end

                if totalPoints > 0 then
                    -- Check quality acceptance
                    local quality = commodityData.quality or "basic"
                    local acceptsQuality = character:AcceptsQuality(quality)
                    if acceptsQuality then
                        -- Factor in commodity multiplier (personalized fatigue)
                        local commodityMultiplier = character:CalculateCommodityMultiplier(commodityId, currentCycle)
                        local score = totalPoints * commodityMultiplier

                        if score > bestScore then
                            bestScore = score
                            bestCommodity = commodityId
                        end
                    else
                        print(string.format("      %s: totalPoints=%.1f but quality '%s' not accepted", commodityId, totalPoints, quality))
                    end
                end
            end
        end
    end

    print(string.format("    Checked %d commodities, best: %s (score=%.2f)", checkedCount, tostring(bestCommodity), bestScore))

    return bestCommodity
end

-- Find best available substitute for a commodity
-- Includes distance-based boost calculation
function AllocationEngineV2.FindBestSubstitute(primaryCommodity, targetCoarseCraving, character, townInventory, currentCycle)
    local bestSubstitute = nil
    local bestScore = 0
    local bestChain = {}

    -- Check hierarchy substitutes first
    for category, commodities in pairs(SubstitutionRules.substitutionHierarchies) do
        if commodities[primaryCommodity] then
            for _, substituteRule in ipairs(commodities[primaryCommodity].substitutes) do
                local substituteCommodity = substituteRule.commodity
                local efficiency = substituteRule.efficiency
                local distance = substituteRule.distance or 0.5  -- Fallback if distance missing

                -- Check availability
                if townInventory[substituteCommodity] and townInventory[substituteCommodity] > 0 then
                    -- Check quality acceptance
                    local substData = FulfillmentVectors.commodities[substituteCommodity]
                    if substData and character:AcceptsQuality(substData.quality) then
                        -- Calculate commodity multiplier for substitute
                        local commodityMultiplier = character:CalculateCommodityMultiplier(substituteCommodity, currentCycle)

                        -- Calculate distance-based boost
                        -- When fatigued (low multiplier), closer substitutes get stronger boost
                        local primaryMultiplier = character:CalculateCommodityMultiplier(primaryCommodity, currentCycle)
                        local distanceBoost = 1.0

                        if primaryMultiplier < 1.0 then
                            -- Boost = (1 - currentMultiplier) * (1 - distance) * boostFactor
                            local boostFactor = 0.5  -- Configurable boost strength
                            distanceBoost = 1.0 + ((1.0 - primaryMultiplier) * (1.0 - distance) * boostFactor)
                        end

                        -- Final score with distance boost
                        local score = efficiency * commodityMultiplier * distanceBoost

                        if score > bestScore then
                            bestScore = score
                            bestSubstitute = substituteCommodity
                            bestChain = {
                                {commodity = primaryCommodity, available = 0},
                                {
                                    commodity = substituteCommodity,
                                    available = townInventory[substituteCommodity],
                                    efficiency = efficiency,
                                    distance = distance,
                                    distanceBoost = distanceBoost
                                }
                            }
                        end
                    end
                end
            end
        end
    end

    -- If desperate and nothing found, try desperation substitutes
    if not bestSubstitute and SubstitutionRules.desperationRules then
        local desperationConfig = SubstitutionRules.desperationRules
        if desperationConfig.enabled then
            -- Get average satisfaction for this coarse dimension
            local coarseIndex = CharacterV2.coarseNameToIndex[targetCoarseCraving]
            local avgSatisfaction = 50

            if coarseIndex then
                avgSatisfaction = character.satisfaction[coarseIndex] or 50
            end

            if avgSatisfaction < (desperationConfig.desperationThreshold or 20) then
                local desperateSubstitutes = desperationConfig.desperationSubstitutes[targetCoarseCraving]
                if desperateSubstitutes then
                    for _, rule in ipairs(desperateSubstitutes) do
                        local substituteCommodity = rule.commodity
                        local efficiency = rule.efficiency
                        local distance = rule.distance or 0.8  -- Desperation = distant

                        if townInventory[substituteCommodity] and townInventory[substituteCommodity] > 0 then
                            local substData = FulfillmentVectors.commodities[substituteCommodity]
                            if substData and character:AcceptsQuality(substData.quality) then
                                local commodityMultiplier = character:CalculateCommodityMultiplier(substituteCommodity, currentCycle)
                                local score = efficiency * commodityMultiplier * 0.8  -- Penalty for desperation

                                if score > bestScore then
                                    bestScore = score
                                    bestSubstitute = substituteCommodity
                                    bestChain = {
                                        {commodity = primaryCommodity, available = 0},
                                        {
                                            commodity = substituteCommodity,
                                            available = townInventory[substituteCommodity],
                                            efficiency = efficiency,
                                            distance = distance,
                                            desperation = true
                                        }
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

return AllocationEngineV2
