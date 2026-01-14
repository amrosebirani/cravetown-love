-- AllocationEngineV2.lua
-- Refactored allocation engine to work with CharacterV3 (6-layer state model)
-- Key changes from V1:
-- 1. Works with 49D fine-grained dimensions internally
-- 2. Aggregates to 9D coarse dimensions for allocation decisions
-- 3. Uses distance-based boost for substitution
-- 4. Supports fairness mode in priority calculation

local AllocationEngineV2 = {}

local ConsumptionMechanics = nil
local FulfillmentVectors = nil
local SubstitutionRules = nil
local CharacterModule = nil  -- CharacterV3 module (passed via Init)
local CommodityCache = nil

-- Minimum accumulated craving value to trigger allocation attempt
local CRAVING_THRESHOLD = 1.0

-- Class-based consumption budget (items per cycle) - DEPRECATED in V2
-- Kept for backwards compatibility with AllocateCycle (original function)
AllocationEngineV2.classConsumptionBudget = {
    Elite = 10,
    Upper = 7,
    Middle = 5,
    Working = 3,
    Poor = 2,
    Lower = 3 -- Alias for Working
}

-- Initialize data
function AllocationEngineV2.Init(mechanicsData, fulfillmentData, substitutionData, characterModule, cacheModule)
    ConsumptionMechanics = mechanicsData
    FulfillmentVectors = fulfillmentData
    SubstitutionRules = substitutionData
    CharacterModule = characterModule
    CommodityCache = cacheModule
end

-- Allocate resources for one cycle
-- policy is optional and contains: priorityMode, fairnessEnabled, classPriorities, dimensionPriorities
function AllocationEngineV2.AllocateCycle(characters, townInventory, currentCycle, mode, policy)
    mode = mode or "standard" -- "standard" or "fairness"

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
                character.allocationPriority = AllocationEngineV2.CalculatePriorityWithPolicy(character, currentCycle,
                    policy)
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
        allocationLog.consumptionByClass[character.class] = allocationLog.consumptionByClass[character.class] or
            { budget = 0, consumed = 0 }
        allocationLog.consumptionByClass[character.class].budget = allocationLog.consumptionByClass[character.class]
            .budget + budget
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
                allocationLog.consumptionByClass[character.class].consumed = allocationLog.consumptionByClass
                    [character.class].consumed + 1
                allocationsForCharacter = allocationsForCharacter + 1
            elseif allocation.status == "substituted" then
                allocationLog.stats.substituted = allocationLog.stats.substituted + 1
                remainingBudget[character] = remainingBudget[character] - 1
                allocationLog.consumptionByClass[character.class].consumed = allocationLog.consumptionByClass
                    [character.class].consumed + 1
                allocationsForCharacter = allocationsForCharacter + 1
            elseif allocation.status == "no_needs" then
                allocationLog.stats.noNeeds = allocationLog.stats.noNeeds + 1
                -- No more cravings to satisfy, move to next character
                break
            else
                allocationLog.stats.failed = allocationLog.stats.failed + 1
                -- Track shortages
                if allocation.requestedCommodity then
                    allocationLog.shortages[allocation.requestedCommodity] = (allocationLog.shortages[allocation.requestedCommodity] or 0) +
                        1
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
        status = "failed", -- granted/substituted/failed/no_needs/acquired
        satisfactionGain = 0,
        commodityMultiplier = 1.0,
        substitutionChain = {},
        allocationType = "consumed" -- "consumed" or "acquired" (for durables)
    }

    -- Determine which craving to address (highest currentCraving with highest weight)
    local targetCoarseCraving, targetCommodity = AllocationEngineV2.SelectTargetCraving(character, townInventory,
        currentCycle)

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
                local _, gain, allocType = AllocationEngineV2.ProcessAllocation(
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
        if targetCommodity then
            townInventory[targetCommodity] = townInventory[targetCommodity] - allocation.quantity
        end

        -- Invalidate cache for this commodity
        if CommodityCache then
            CommodityCache.InvalidateCommodity(targetCommodity)
        end

        -- Process allocation (handles durables vs consumables)
        local _, gain, allocType = AllocationEngineV2.ProcessAllocation(
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

    -- Iterate through fine dimensions and find best available commodity
    -- This avoids the problem where high-value items (medicine=50) dominate coarse categories
    local fineMaxIdx = CharacterModule.GetFineMaxIndex and CharacterModule.GetFineMaxIndex() or 48
    for fineIdx = 0, fineMaxIdx do
        local fineCraving = character.currentCravings[fineIdx] or 0

        if fineCraving > 0 then
            local fineName = CharacterModule.fineNames[fineIdx]
            local coarseIdx = CharacterModule.fineToCoarseMap[fineIdx]
            local coarseName = CharacterModule.coarseNames[coarseIdx]
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

    -- Map coarse craving to coarse dimension index (0-8 for CharacterV3)
    local coarseIndex = CharacterModule.coarseNameToIndex[coarseCraving]
    if not coarseIndex then
        return nil
    end

    -- Get fine dimension indices for this coarse dimension
    local fineIndices = CharacterModule.coarseToFineMap[coarseIndex]
    if not fineIndices or #fineIndices == 0 then
        print("Warning: No fine dimensions for coarse index " .. tostring(coarseIndex))
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

                for _, fineIdx in ipairs(fineIndices) do
                    -- Get the string name for this fine dimension (e.g., "biological_nutrition_grain")
                    local fineName = CharacterModule.fineNames[fineIdx]
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
                        print(string.format("      %s: totalPoints=%.1f but quality '%s' not accepted", commodityId,
                            totalPoints, quality))
                    end
                end
            end
        end
        ::continue_commodity_best::
    end

    print(string.format("    Checked %d commodities, best: %s (score=%.2f)", checkedCount, tostring(bestCommodity),
        bestScore))

    return bestCommodity
end

-- Find best available substitute for a commodity
-- Includes distance-based boost calculation
function AllocationEngineV2.FindBestSubstitute(primaryCommodity, targetCoarseCraving, character, townInventory,
                                               currentCycle)
    local bestSubstitute = nil
    local bestScore = 0
    local bestChain = {}

    -- Check hierarchy substitutes first
    for category, commodities in pairs(SubstitutionRules.substitutionHierarchies) do
        if commodities[primaryCommodity] then
            for _, substituteRule in ipairs(commodities[primaryCommodity].substitutes) do
                local substituteCommodity = substituteRule.commodity
                local efficiency = substituteRule.efficiency
                local distance = substituteRule.distance or 0.5 -- Fallback if distance missing

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
                        local commodityMultiplier = character:CalculateCommodityMultiplier(substituteCommodity,
                            currentCycle)

                        -- Calculate distance-based boost
                        -- When fatigued (low multiplier), closer substitutes get stronger boost
                        local primaryMultiplier = character:CalculateCommodityMultiplier(primaryCommodity, currentCycle)
                        local distanceBoost = 1.0

                        if primaryMultiplier < 1.0 then
                            -- Boost = (1 - currentMultiplier) * (1 - distance) * boostFactor
                            local boostFactor = 0.5 -- Configurable boost strength
                            distanceBoost = 1.0 + ((1.0 - primaryMultiplier) * (1.0 - distance) * boostFactor)
                        end

                        -- Final score with distance boost
                        local score = efficiency * commodityMultiplier * distanceBoost

                        if score > bestScore then
                            bestScore = score
                            bestSubstitute = substituteCommodity
                            bestChain = {
                                { commodity = primaryCommodity, available = 0 },
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
            local coarseIndex = CharacterModule.coarseNameToIndex[targetCoarseCraving]
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
                        local distance = rule.distance or 0.8 -- Desperation = distant

                        if townInventory[substituteCommodity] and townInventory[substituteCommodity] > 0 then
                            -- Skip durables that character already owns at max capacity
                            if AllocationEngineV2.IsDurable(substituteCommodity) then
                                if not character:CanAcquireDurable(substituteCommodity) then
                                    goto continue_substitute_desperation
                                end
                            end

                            local substData = FulfillmentVectors.commodities[substituteCommodity]
                            if substData and character:AcceptsQuality(substData.quality) then
                                local commodityMultiplier = character:CalculateCommodityMultiplier(substituteCommodity,
                                    currentCycle)
                                local score = efficiency * commodityMultiplier * 0.8 -- Penalty for desperation

                                if score > bestScore then
                                    bestScore = score
                                    bestSubstitute = substituteCommodity
                                    bestChain = {
                                        { commodity = primaryCommodity, available = 0 },
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

    -- Apply fairness boost if enabled (increases priority for characters who failed recent allocations)
    if policy.fairnessEnabled then
        priority = priority + (character.fairnessPenalty or 0)
    end

    return priority
end

-- =============================================================================
-- V2 ALLOCATION: Performance-optimized allocation using active cravings
-- =============================================================================

-- Calculate priority based only on ACTIVE cravings for this slot
-- Unlike CalculatePriorityWithPolicy which uses ALL coarse cravings,
-- this only considers the fine cravings that are actually active in the current slot
function AllocationEngineV2.CalculatePriorityForActiveCravings(character, currentCycle, activeCravings, policy)
    local priority = 0
    local priorityMode = policy.priorityMode or "need_based"

    if priorityMode == "equality" then
        -- Everyone gets same base priority with small random factor
        priority = 100 + math.random(0, 10)
    else -- need_based
        -- Calculate desperation only from ACTIVE cravings (not all 49)
        local desperationScore = 0

        for _, cravingId in ipairs(activeCravings) do
            local fineIdx = CharacterModule.GetFineIndexFromCravingId(cravingId)
            if fineIdx then
                local craving = character.currentCravings[fineIdx] or 0

                -- Optional: weight by dimension priority if provided
                local coarseIdx = CharacterModule.fineToCoarseMap[fineIdx]
                local coarseName = CharacterModule.coarseNames[coarseIdx]
                local weight = 1.0
                if policy.dimensionPriorities and coarseName then
                    weight = policy.dimensionPriorities[coarseName] or 1.0
                end

                desperationScore = desperationScore + (craving * weight)
            end
        end

        priority = desperationScore
    end

    -- Apply fairness boost if enabled
    if policy.fairnessEnabled then
        priority = priority + (character.fairnessPenalty or 0)
    end

    return priority
end

-- Allocate multiple units of a commodity to a character
-- Returns success (bool), total satisfaction gain (number)
function AllocationEngineV2.AllocateMultipleUnits(character, commodityId, quantity, townInventory, currentCycle, allocationLog)
    -- Check durable ownership limits (durables should only be 1 at a time)
    if AllocationEngineV2.IsDurable(commodityId) then
        if not character:CanAcquireDurable(commodityId) then
            return false, 0
        end
        quantity = 1  -- Force single unit for durables
    end

    -- Check commodity fatigue
    local commodityMultiplier = character:CalculateCommodityMultiplier(commodityId, currentCycle)
    if commodityMultiplier < 0.3 then
        return false, 0  -- Too fatigued, try next commodity
    end

    -- Allocate from inventory
    townInventory[commodityId] = townInventory[commodityId] - quantity

    -- Invalidate cache
    if CommodityCache then
        CommodityCache.InvalidateCommodity(commodityId)
    end

    -- Process allocation (fulfill craving with quantity)
    local success, gain, allocType = AllocationEngineV2.ProcessAllocation(
        character, commodityId, quantity, currentCycle
    )

    -- Record attempt (success/fail affects fairness penalty)
    character:RecordAllocationAttempt(success, currentCycle)

    -- Log allocation
    table.insert(allocationLog.allocations, {
        characterId = character.id,
        characterName = character.name,
        allocatedCommodity = commodityId,
        quantity = quantity,
        status = success and "granted" or "failed",
        satisfactionGain = gain or 0
    })

    allocationLog.stats.granted = allocationLog.stats.granted + (success and 1 or 0)
    allocationLog.stats.totalUnits = allocationLog.stats.totalUnits + quantity

    return success, gain or 0
end

-- V2 Allocation: Loop by active cravings, not by citizens
-- Processes only cravings that are active for the current slot
-- Characters consume as many units as needed to drain their accumulated craving
function AllocationEngineV2.AllocateCycleV2(characters, townInventory, currentCycle, activeCravings, mode, policy)
    policy = policy or {}
    mode = mode or "need_based"

    local allocationLog = {
        cycle = currentCycle,
        timestamp = os.time(),
        mode = mode,
        allocations = {},
        stats = {
            granted = 0,
            failed = 0,
            totalUnits = 0,
            cravingsProcessed = 0
        }
    }

    -- 1. Calculate priorities based on ACTIVE cravings only, then sort
    local sortedCharacters = {}
    for _, character in ipairs(characters) do
        if not character.hasEmigrated then
            -- Use new priority function that only considers active cravings
            character.allocationPriority = AllocationEngineV2.CalculatePriorityForActiveCravings(
                character, currentCycle, activeCravings, policy
            )
            table.insert(sortedCharacters, character)
        end
    end
    table.sort(sortedCharacters, function(a, b)
        return a.allocationPriority > b.allocationPriority
    end)

    -- 2. For each active fine craving in this slot
    for _, cravingId in ipairs(activeCravings) do
        local fineIdx = CharacterModule.GetFineIndexFromCravingId(cravingId)
        if fineIdx then
            allocationLog.stats.cravingsProcessed = allocationLog.stats.cravingsProcessed + 1

            -- Get pre-sorted commodities from cache
            local cachedCommodities = CommodityCache.GetCommoditiesForFineDimension(cravingId, townInventory)

            -- PRE-FILTER: Build list of available commodities with quantities and fulfillment values
            local availableCommodities = {}
            for _, commodityId in ipairs(cachedCommodities) do
                local qty = townInventory[commodityId] or 0
                if qty > 0 then
                    local commodityData = FulfillmentVectors.commodities[commodityId]
                    local fulfillmentValue = 0
                    if commodityData and commodityData.fulfillmentVector and commodityData.fulfillmentVector.fine then
                        fulfillmentValue = commodityData.fulfillmentVector.fine[cravingId] or 0
                    end
                    table.insert(availableCommodities, {
                        id = commodityId,
                        qty = qty,
                        fulfillmentValue = fulfillmentValue,
                        quality = commodityData and commodityData.quality or "basic"
                    })
                end
            end

            -- For each citizen in priority order
            for _, character in ipairs(sortedCharacters) do
                -- Check if citizen has accumulated craving for this dimension
                local currentCraving = character.currentCravings[fineIdx] or 0

                -- Keep consuming until craving drained or no commodities available
                while currentCraving > CRAVING_THRESHOLD and #availableCommodities > 0 do
                    local allocated = false

                    -- Find first commodity that character accepts quality for
                    local i = 1
                    while i <= #availableCommodities do
                        local entry = availableCommodities[i]

                        if entry.qty > 0 and character:AcceptsQuality(entry.quality) then
                            -- Calculate how many units needed to drain this craving
                            local unitsNeeded = math.ceil(currentCraving / math.max(entry.fulfillmentValue, 1))
                            local unitsToAllocate = math.min(unitsNeeded, entry.qty)

                            -- Allocate multiple units
                            local success, totalGain = AllocationEngineV2.AllocateMultipleUnits(
                                character, entry.id, unitsToAllocate, townInventory, currentCycle, allocationLog
                            )

                            if success then
                                -- Update local tracking
                                entry.qty = entry.qty - unitsToAllocate
                                currentCraving = currentCraving - totalGain

                                -- Remove depleted commodity
                                if entry.qty == 0 then
                                    table.remove(availableCommodities, i)
                                end

                                allocated = true
                                break
                            end
                        end
                        i = i + 1
                    end

                    -- If no allocation possible (no acceptable commodities), move to next citizen
                    if not allocated then
                        -- Record failed attempt for fairness system
                        if currentCraving > CRAVING_THRESHOLD then
                            character:RecordAllocationAttempt(false, currentCycle)

                            -- LAYER 8: Apply immediate satisfaction penalty based on streak
                            -- This penalizes citizens whose active cravings cannot be fulfilled
                            -- Penalty magnitude increases with consecutive days of unmet craving
                            if character.ApplyUnfulfilledCravingPenalty then
                                character:ApplyUnfulfilledCravingPenalty(fineIdx, currentCycle)
                            end

                            allocationLog.stats.failed = allocationLog.stats.failed + 1
                        end
                        break
                    end
                end
            end
        end
    end

    print(string.format("[AllocationEngineV2.V2] Cycle %d: %d cravings, %d allocations, %d units, %d failed",
        currentCycle, allocationLog.stats.cravingsProcessed, allocationLog.stats.granted,
        allocationLog.stats.totalUnits, allocationLog.stats.failed))

    return allocationLog
end

return AllocationEngineV2
