-- TownConsequences.lua
-- Phase 5: Town-level consequence system
-- Handles civil unrest, riots, and mass emigration

local TownConsequences = {}

local ConsumptionMechanics = nil

-- Initialize module with data
function TownConsequences.Init(mechanicsData)
    ConsumptionMechanics = mechanicsData
end

-- =============================================================================
-- Civil Unrest Detection
-- =============================================================================

function TownConsequences.CheckCivilUnrest(characters)
    -- When 20%+ of population is protesting, apply town-wide productivity penalty

    if not ConsumptionMechanics or not ConsumptionMechanics.consequenceThresholds or
       not ConsumptionMechanics.consequenceThresholds.civilUnrest then
        return false, 0
    end

    local config = ConsumptionMechanics.consequenceThresholds.civilUnrest
    if not config.enabled then
        return false, 0
    end

    -- Count protesting characters
    local totalPopulation = 0
    local protestingCount = 0

    for _, char in ipairs(characters) do
        if not char.hasEmigrated then
            totalPopulation = totalPopulation + 1
            if char.isProtesting then
                protestingCount = protestingCount + 1
            end
        end
    end

    if totalPopulation == 0 then
        return false, 0
    end

    local protestPercentage = (protestingCount / totalPopulation) * 100
    local threshold = config.protestPercentageThreshold or 20

    if protestPercentage >= threshold then
        -- Apply town-wide productivity penalty
        local penalty = config.productivityPenalty or 0.5
        return true, penalty, protestingCount, totalPopulation
    end

    return false, 0, protestingCount, totalPopulation
end

-- =============================================================================
-- Riot Detection and Damage
-- =============================================================================

function TownConsequences.CheckRiot(characters, currentCycle)
    -- When 40%+ dissatisfied AND inequality exists, riot can occur
    -- Riots damage inventory and buildings

    if not ConsumptionMechanics or not ConsumptionMechanics.consequenceThresholds or
       not ConsumptionMechanics.consequenceThresholds.riots then
        return false, nil
    end

    local config = ConsumptionMechanics.consequenceThresholds.riots
    if not config.enabled then
        return false, nil
    end

    -- Count dissatisfied characters (avg satisfaction < threshold)
    local totalPopulation = 0
    local dissatisfiedCount = 0
    local satisfactionByClass = {}

    for _, char in ipairs(characters) do
        if not char.hasEmigrated then
            totalPopulation = totalPopulation + 1

            local avgSat = char:GetAverageSatisfaction()
            local threshold = config.dissatisfactionThreshold or 40

            if avgSat < threshold then
                dissatisfiedCount = dissatisfiedCount + 1
            end

            -- Track satisfaction by class for inequality calculation
            if not satisfactionByClass[char.class] then
                satisfactionByClass[char.class] = {total = 0, count = 0}
            end
            satisfactionByClass[char.class].total = satisfactionByClass[char.class].total + avgSat
            satisfactionByClass[char.class].count = satisfactionByClass[char.class].count + 1
        end
    end

    if totalPopulation == 0 then
        return false, nil
    end

    local dissatisfiedPercentage = (dissatisfiedCount / totalPopulation) * 100
    local dissatisfiedThreshold = config.dissatisfiedPercentageThreshold or 40

    -- Check dissatisfaction level
    if dissatisfiedPercentage < dissatisfiedThreshold then
        return false, nil
    end

    -- Calculate inequality (difference between highest and lowest class average satisfaction)
    local avgByClass = {}
    for class, data in pairs(satisfactionByClass) do
        avgByClass[class] = data.total / data.count
    end

    local maxSat = -1000
    local minSat = 1000
    for _, avg in pairs(avgByClass) do
        maxSat = math.max(maxSat, avg)
        minSat = math.min(minSat, avg)
    end

    local inequality = maxSat - minSat
    local inequalityThreshold = config.inequalityThreshold or 50

    -- Check if riot conditions are met
    if inequality >= inequalityThreshold then
        -- Roll for riot (random chance)
        local riotChance = config.riotChancePerCycle or 0.1
        if math.random() < riotChance then
            -- Riot triggered!
            local damage = {
                inventoryDamagePercent = config.inventoryDamagePercent or 0.1,  -- 10% of inventory
                buildingDamageCount = config.buildingDamageCount or math.random(1, 3),
                dissatisfiedPercentage = dissatisfiedPercentage,
                inequality = inequality
            }
            return true, damage
        end
    end

    return false, nil
end

-- =============================================================================
-- Apply Riot Damage to Town Inventory
-- =============================================================================

function TownConsequences.ApplyRiotDamage(townInventory, damageInfo)
    -- Damage a percentage of each commodity in inventory
    local damagePercent = damageInfo.inventoryDamagePercent or 0.1
    local damagedCommodities = {}

    for commodity, quantity in pairs(townInventory) do
        if quantity > 0 then
            local damage = math.floor(quantity * damagePercent)
            if damage > 0 then
                townInventory[commodity] = math.max(0, townInventory[commodity] - damage)
                table.insert(damagedCommodities, {
                    commodity = commodity,
                    damage = damage,
                    remaining = townInventory[commodity]
                })
            end
        end
    end

    return damagedCommodities
end

-- =============================================================================
-- Mass Emigration Detection
-- =============================================================================

function TownConsequences.CheckMassEmigration(characters, currentCycle)
    -- Track when multiple characters emigrate in same cycle
    -- Can trigger town-level "emigration opportunity" events

    if not ConsumptionMechanics or not ConsumptionMechanics.consequenceThresholds or
       not ConsumptionMechanics.consequenceThresholds.massEmigration then
        return false, 0
    end

    local config = ConsumptionMechanics.consequenceThresholds.massEmigration
    if not config.enabled then
        return false, 0
    end

    -- Count emigrants this cycle
    local emigrantCount = 0
    for _, char in ipairs(characters) do
        if char.hasEmigrated and char.lastAllocationCycle == currentCycle then
            emigrantCount = emigrantCount + 1
        end
    end

    local threshold = config.emigrantsPerCycleThreshold or 3

    if emigrantCount >= threshold then
        return true, emigrantCount
    end

    return false, emigrantCount
end

-- =============================================================================
-- Calculate Town Statistics
-- =============================================================================

function TownConsequences.CalculateTownStats(characters)
    local stats = {
        totalPopulation = 0,
        activePopulation = 0,
        protestingCount = 0,
        emigratedCount = 0,
        averageSatisfaction = 0,
        averageProductivity = 0,
        dissatisfiedCount = 0,  -- satisfaction < 40
        stressedCount = 0,  -- productivity < 0.5
        byClass = {}
    }

    local totalSatisfaction = 0
    local totalProductivity = 0

    for _, char in ipairs(characters) do
        stats.totalPopulation = stats.totalPopulation + 1

        if char.hasEmigrated then
            stats.emigratedCount = stats.emigratedCount + 1
        else
            stats.activePopulation = stats.activePopulation + 1

            local avgSat = char:GetAverageSatisfaction()
            totalSatisfaction = totalSatisfaction + avgSat
            totalProductivity = totalProductivity + char.productivityMultiplier

            if char.isProtesting then
                stats.protestingCount = stats.protestingCount + 1
            end

            if avgSat < 40 then
                stats.dissatisfiedCount = stats.dissatisfiedCount + 1
            end

            if char.productivityMultiplier < 0.5 then
                stats.stressedCount = stats.stressedCount + 1
            end

            -- Track by class
            if not stats.byClass[char.class] then
                stats.byClass[char.class] = {
                    count = 0,
                    totalSatisfaction = 0,
                    totalProductivity = 0,
                    protesting = 0,
                    emigrated = 0
                }
            end

            local classStats = stats.byClass[char.class]
            classStats.count = classStats.count + 1
            classStats.totalSatisfaction = classStats.totalSatisfaction + avgSat
            classStats.totalProductivity = classStats.totalProductivity + char.productivityMultiplier

            if char.isProtesting then
                classStats.protesting = classStats.protesting + 1
            end
        end
    end

    if stats.activePopulation > 0 then
        stats.averageSatisfaction = totalSatisfaction / stats.activePopulation
        stats.averageProductivity = totalProductivity / stats.activePopulation
    end

    -- Calculate class averages
    for class, classStats in pairs(stats.byClass) do
        if classStats.count > 0 then
            classStats.averageSatisfaction = classStats.totalSatisfaction / classStats.count
            classStats.averageProductivity = classStats.totalProductivity / classStats.count
        end
    end

    return stats
end

return TownConsequences
