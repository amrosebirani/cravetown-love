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

-- Class-based consumption budget (items per cycle)
-- Wealthier classes can consume more resources to satisfy more cravings
AllocationEngineV2.classConsumptionBudget = {
    Elite = 10,
    Upper = 7,
    Middle = 5,
    Working = 3,
    Poor = 2,
    Lower = 3  -- Alias for Working
}

-- Initialize data
function AllocationEngineV2.Init(mechanicsData, fulfillmentData, substitutionData, characterV2Module, cacheModule)
    ConsumptionMechanics = mechanicsData
    FulfillmentVectors = fulfillmentData
    SubstitutionRules = substitutionData
    CharacterV2 = characterV2Module
    CommodityCache = cacheModule
end

-- Allocate resources for one cycle
-- policy is optional and contains: priorityMode, fairnessEnabled, classPriorities, dimensionPriorities
function AllocationEngineV2.AllocateCycle(characters, townInventory, currentCycle, mode, policy)
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
            failed = 0,
            noNeeds = 0
        },
        shortages = {},
        consumptionByClass = {}
    }

    -- Calculate priorities for all characters
    -- If policy is provided, use policy-based priority calculation
    for _, character in ipairs(characters) do
        if not character.hasEmigrated then
            if policy then
                character.allocationPriority = AllocationEngineV2.CalculatePriorityWithPolicy(character, currentCycle, policy)
            else
                character:CalculatePriority(currentCycle, mode)
            end
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

    -- Initialize consumption budget for each character based on class
    -- Use policy consumptionBudgets if provided, otherwise fall back to default
    local remainingBudget = {}
    for _, character in ipairs(sortedCharacters) do
        local budget
        if policy and policy.consumptionBudgets and policy.consumptionBudgets[character.class] then
            budget = policy.consumptionBudgets[character.class]
        else
            budget = AllocationEngineV2.classConsumptionBudget[character.class] or 3
        end
        remainingBudget[character] = budget
        allocationLog.consumptionByClass[character.class] = allocationLog.consumptionByClass[character.class] or {budget = 0, consumed = 0}
        allocationLog.consumptionByClass[character.class].budget = allocationLog.consumptionByClass[character.class].budget + budget
    end

    -- Sequential allocation: each character exhausts their budget before moving to next
    -- Characters are processed in priority order (highest first)
    -- For each character, allocate from highest craving to lowest until budget exhausted
    for rank, character in ipairs(sortedCharacters) do
        local budget = remainingBudget[character]
        local allocationsForCharacter = 0

        -- Keep allocating until budget exhausted or no more needs
        while remainingBudget[character] > 0 do
            local allocation = AllocationEngineV2.AllocateForCharacter(
                character, townInventory, currentCycle, rank
            )
            table.insert(allocationLog.allocations, allocation)

            -- Update stats
            allocationLog.stats.totalAttempts = allocationLog.stats.totalAttempts + 1

            if allocation.status == "granted" then
                allocationLog.stats.granted = allocationLog.stats.granted + 1
                remainingBudget[character] = remainingBudget[character] - 1
                allocationLog.consumptionByClass[character.class].consumed = allocationLog.consumptionByClass[character.class].consumed + 1
                allocationsForCharacter = allocationsForCharacter + 1
            elseif allocation.status == "substituted" then
                allocationLog.stats.substituted = allocationLog.stats.substituted + 1
                remainingBudget[character] = remainingBudget[character] - 1
                allocationLog.consumptionByClass[character.class].consumed = allocationLog.consumptionByClass[character.class].consumed + 1
                allocationsForCharacter = allocationsForCharacter + 1
            elseif allocation.status == "no_needs" then
                allocationLog.stats.noNeeds = allocationLog.stats.noNeeds + 1
                -- No more cravings to satisfy, move to next character
                break
            else
                allocationLog.stats.failed = allocationLog.stats.failed + 1
                -- Track shortages
                if allocation.requestedCommodity then
                    local commodity = allocation.requestedCommodity
                    allocationLog.shortages[commodity] = (allocationLog.shortages[commodity] or 0) + 1
                end
                -- Failed to get this commodity, but try next craving
                remainingBudget[character] = remainingBudget[character] - 1
            end
        end

        -- Debug: log how many allocations this character got
        if allocationsForCharacter > 0 then
            print(string.format("  %s (%s): %d/%d allocations",
                character.name, character.class, allocationsForCharacter, budget))
        end
    end

    return allocationLog
end

-- Helper: Check if a commodity is durable or permanent
function AllocationEngineV2.IsDurable(commodityId)
    if not FulfillmentVectors or not FulfillmentVectors.commodities then
        return false
    end
    local commodityData = FulfillmentVectors.commodities[commodityId]
    if not commodityData then
        return false
    end
    local durability = commodityData.durability or "consumable"
    return durability == "durable" or durability == "permanent"
end

-- Helper: Get commodity durability info
function AllocationEngineV2.GetDurabilityInfo(commodityId)
    if not FulfillmentVectors or not FulfillmentVectors.commodities then
        return nil
    end
    local commodityData = FulfillmentVectors.commodities[commodityId]
    if not commodityData then
        return nil
    end
    return {
        durability = commodityData.durability or "consumable",
        durationCycles = commodityData.durationCycles,
        effectDecayRate = commodityData.effectDecayRate or 0,
        category = commodityData.category or commodityId,
        maxOwned = commodityData.maxOwned or 1
    }
end

-- Helper: Process commodity allocation (handles both consumables and durables)
function AllocationEngineV2.ProcessAllocation(character, commodityId, quantity, currentCycle)
    local durabilityInfo = AllocationEngineV2.GetDurabilityInfo(commodityId)

    if durabilityInfo and (durabilityInfo.durability == "durable" or durabilityInfo.durability == "permanent") then
        -- Durable/Permanent: Add as active effect
        local success, effect = character:AddActiveEffect(commodityId, currentCycle)
        if success then
            -- Also give immediate satisfaction boost for acquiring the item
            local immediateGain = character:FulfillCraving(commodityId, quantity, currentCycle, "acquired")
            return true, immediateGain or 0, "acquired"
        else
            return false, 0, "failed_to_acquire"
        end
    else
        -- Consumable: Normal craving fulfillment
        local success, gain, multiplier = character:FulfillCraving(commodityId, quantity, currentCycle, "consumed")
        return success, gain or 0, "consumed"
    end
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
        status = "failed",  -- granted/substituted/failed/no_needs/acquired
        satisfactionGain = 0,
        commodityMultiplier = 1.0,
        substitutionChain = {},
        allocationType = "consumed"  -- "consumed" or "acquired" (for durables)
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

                -- Process allocation (handles durables vs consumables)
                local success, gain, allocType = AllocationEngineV2.ProcessAllocation(
                    character, substitute, allocation.quantity, currentCycle
                )
                allocation.satisfactionGain = gain
                allocation.allocationType = allocType
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

        -- Process allocation (handles durables vs consumables)
        local success, gain, allocType = AllocationEngineV2.ProcessAllocation(
            character, targetCommodity, allocation.quantity, currentCycle
        )
        allocation.satisfactionGain = gain
        allocation.allocationType = allocType
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

        -- Process allocation (handles durables vs consumables)
        local success, gain, allocType = AllocationEngineV2.ProcessAllocation(
            character, substitute, allocation.quantity, currentCycle
        )
        allocation.satisfactionGain = gain
        allocation.allocationType = allocType
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
                    -- Skip durables that character already owns at max capacity
                    if AllocationEngineV2.IsDurable(commodityId) then
                        if not character:CanAcquireDurable(commodityId) then
                            goto continue_commodity_select
                        end
                    end

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
                ::continue_commodity_select::
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
            -- Skip durables that character already owns at max capacity
            if AllocationEngineV2.IsDurable(commodityId) then
                if not character:CanAcquireDurable(commodityId) then
                    goto continue_commodity_best
                end
            end

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
        ::continue_commodity_best::
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
                    -- Skip durables that character already owns at max capacity
                    if AllocationEngineV2.IsDurable(substituteCommodity) then
                        if not character:CanAcquireDurable(substituteCommodity) then
                            goto continue_substitute_hierarchy
                        end
                    end

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
                ::continue_substitute_hierarchy::
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
                            -- Skip durables that character already owns at max capacity
                            if AllocationEngineV2.IsDurable(substituteCommodity) then
                                if not character:CanAcquireDurable(substituteCommodity) then
                                    goto continue_substitute_desperation
                                end
                            end

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
                        ::continue_substitute_desperation::
                    end
                end
            end
        end
    end

    return bestSubstitute, bestChain
end

-- Calculate priority using policy settings
-- Phase 5: Priority is based on desperation (unfulfilled cravings) + fairness penalty
-- Class is NOT used for priority - only for quality acceptance and consumption budgets
-- policy contains: priorityMode, fairnessEnabled, dimensionPriorities
function AllocationEngineV2.CalculatePriorityWithPolicy(character, currentCycle, policy)
    local priority = 0

    local priorityMode = policy.priorityMode or "need_based"

    if priorityMode == "equality" then
        -- Everyone gets same base priority with small random factor
        priority = 100 + math.random(0, 10)

    else -- need_based (default) - Phase 5: desperation-based, no class weight
        -- Use dimension priorities to weight cravings (desperation score)
        local coarseCravings = character:AggregateCurrentCravingsToCoarse()
        local desperationScore = 0

        if policy.dimensionPriorities then
            for dimKey, dimWeight in pairs(policy.dimensionPriorities) do
                local craving = coarseCravings[dimKey] or 0
                desperationScore = desperationScore + (craving * dimWeight)
            end
        else
            -- Fallback: sum all cravings with default weights
            for _, craving in pairs(coarseCravings) do
                desperationScore = desperationScore + craving
            end
        end

        -- Priority is purely based on desperation (no class weight)
        priority = desperationScore
    end

    -- Apply fairness penalty if enabled (reduces priority for recently satisfied characters)
    if policy.fairnessEnabled then
        priority = priority - (character.fairnessPenalty or 0)
    end

    return priority
end

return AllocationEngineV2
