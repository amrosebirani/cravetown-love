--
-- EconomicsSystem.lua
-- Per-character income/expense tracking, net worth calculation, and emergent class system
--

local DataLoader = require("code.DataLoader")

local EconomicsSystem = {}
EconomicsSystem.__index = EconomicsSystem

-- Default class (if thresholds not met)
local DEFAULT_CLASS = "lower"

function EconomicsSystem:Create(ownershipManager)
    local system = setmetatable({}, EconomicsSystem)

    system.ownershipManager = ownershipManager

    -- Load configuration
    system.classThresholds = system:LoadClassThresholds()
    system.economicSystemConfig = system:LoadEconomicSystemConfig()

    -- Per-character financial data: characterId -> financialRecord
    system.characterFinances = {}

    -- Class cache: characterId -> { class, lastCalculated }
    system.classCache = {}

    -- Calculation interval (recalculate class every N cycles)
    system.classCalculationInterval = system.classThresholds.classCalculationInterval or 20

    print("[EconomicsSystem] Created with system: " .. (system.economicSystemConfig.activeSystem or "capitalist"))

    return system
end

function EconomicsSystem:LoadClassThresholds()
    local filepath = "data/" .. DataLoader.activeVersion .. "/class_thresholds.json"
    print("Loading class thresholds from " .. filepath .. "...")
    local success, data = pcall(function()
        return DataLoader.loadJSON(filepath)
    end)
    if success and data then
        return data
    else
        print("  WARNING: Could not load class thresholds, using defaults")
        return {
            classCalculationInterval = 20,
            netWorthThresholds = {
                elite = { min = 10000 },
                upper = { min = 3000 },
                middle = { min = 500 }
            },
            capitalRatioThresholds = {
                elite = 0.8,
                upper = 0.5,
                middle = 0.2
            }
        }
    end
end

function EconomicsSystem:LoadEconomicSystemConfig()
    local filepath = "data/" .. DataLoader.activeVersion .. "/economic_systems.json"
    print("Loading economic systems from " .. filepath .. "...")
    local success, data = pcall(function()
        return DataLoader.loadJSON(filepath)
    end)
    if success and data then
        return data
    else
        print("  WARNING: Could not load economic systems, using defaults")
        return {
            activeSystem = "capitalist",
            systems = {
                capitalist = {
                    description = "Default capitalist system"
                }
            }
        }
    end
end

-- ============================================================================
-- Character Financial Records
-- ============================================================================

function EconomicsSystem:InitializeCharacter(characterId, startingWealth)
    startingWealth = startingWealth or 0

    self.characterFinances[characterId] = {
        -- Liquid assets
        gold = startingWealth,

        -- Income tracking (per cycle)
        incomeThisCycle = 0,
        incomeSources = {},  -- { source, amount }

        -- Expense tracking (per cycle)
        expensesThisCycle = 0,
        expenseItems = {},  -- { item, amount }

        -- Historical totals
        totalIncomeEarned = 0,
        totalExpensesSpent = 0,

        -- For class calculation
        lastClassCalculation = 0
    }

    -- Clear class cache
    self.classCache[characterId] = nil

    print(string.format("[EconomicsSystem] Initialized character %s with %d gold", characterId, startingWealth))
end

function EconomicsSystem:GetCharacterFinances(characterId)
    return self.characterFinances[characterId]
end

function EconomicsSystem:GetGold(characterId)
    local finances = self.characterFinances[characterId]
    if finances then
        return finances.gold
    end
    return 0
end

function EconomicsSystem:AddGold(characterId, amount, source)
    local finances = self.characterFinances[characterId]
    if not finances then
        self:InitializeCharacter(characterId, 0)
        finances = self.characterFinances[characterId]
    end

    finances.gold = finances.gold + amount
    finances.incomeThisCycle = finances.incomeThisCycle + amount
    finances.totalIncomeEarned = finances.totalIncomeEarned + amount

    table.insert(finances.incomeSources, {
        source = source or "unknown",
        amount = amount
    })

    return finances.gold
end

function EconomicsSystem:SpendGold(characterId, amount, item)
    local finances = self.characterFinances[characterId]
    if not finances then
        return false, "Character not initialized"
    end

    if finances.gold < amount then
        return false, "Insufficient funds"
    end

    finances.gold = finances.gold - amount
    finances.expensesThisCycle = finances.expensesThisCycle + amount
    finances.totalExpensesSpent = finances.totalExpensesSpent + amount

    table.insert(finances.expenseItems, {
        item = item or "unknown",
        amount = amount
    })

    return true, finances.gold
end

function EconomicsSystem:TransferGold(fromCharacterId, toCharacterId, amount, reason)
    local fromFinances = self.characterFinances[fromCharacterId]
    if not fromFinances then
        return false, "Sender not initialized"
    end

    if fromFinances.gold < amount then
        return false, "Insufficient funds"
    end

    -- Deduct from sender
    self:SpendGold(fromCharacterId, amount, "transfer_to_" .. toCharacterId .. "_" .. (reason or ""))

    -- Add to recipient
    self:AddGold(toCharacterId, amount, "transfer_from_" .. fromCharacterId .. "_" .. (reason or ""))

    return true
end

-- ============================================================================
-- Net Worth Calculation
-- ============================================================================

function EconomicsSystem:CalculateNetWorth(characterId)
    local finances = self.characterFinances[characterId]
    if not finances then
        return 0
    end

    -- Liquid assets
    local netWorth = finances.gold

    -- Add owned assets value
    if self.ownershipManager then
        netWorth = netWorth + self.ownershipManager:GetTotalAssetValue(characterId)
    end

    return netWorth
end

function EconomicsSystem:CalculateCapitalRatio(characterId)
    -- Capital ratio = asset value / total net worth
    local finances = self.characterFinances[characterId]
    if not finances then
        return 0
    end

    local netWorth = self:CalculateNetWorth(characterId)
    if netWorth <= 0 then
        return 0
    end

    local assetValue = 0
    if self.ownershipManager then
        assetValue = self.ownershipManager:GetTotalAssetValue(characterId)
    end

    return assetValue / netWorth
end

-- ============================================================================
-- Emergent Class System
-- ============================================================================

function EconomicsSystem:CalculateClass(characterId, currentCycle)
    -- Check cache first
    local cached = self.classCache[characterId]
    if cached then
        local cyclesSinceCalc = currentCycle - cached.lastCalculated
        if cyclesSinceCalc < self.classCalculationInterval then
            return cached.class
        end
    end

    -- Calculate fresh
    local netWorth = self:CalculateNetWorth(characterId)
    local capitalRatio = self:CalculateCapitalRatio(characterId)

    local thresholds = self.classThresholds.netWorthThresholds or {}
    local capitalThresholds = self.classThresholds.capitalRatioThresholds or {}

    local calculatedClass = DEFAULT_CLASS

    -- Check thresholds from highest to lowest
    if netWorth >= (thresholds.elite and thresholds.elite.min or 10000) and
       capitalRatio >= (capitalThresholds.elite or 0.8) then
        calculatedClass = "elite"
    elseif netWorth >= (thresholds.upper and thresholds.upper.min or 3000) and
           capitalRatio >= (capitalThresholds.upper or 0.5) then
        calculatedClass = "upper"
    elseif netWorth >= (thresholds.middle and thresholds.middle.min or 500) and
           capitalRatio >= (capitalThresholds.middle or 0.2) then
        calculatedClass = "middle"
    end

    -- Update cache
    self.classCache[characterId] = {
        class = calculatedClass,
        lastCalculated = currentCycle,
        netWorth = netWorth,
        capitalRatio = capitalRatio
    }

    return calculatedClass
end

function EconomicsSystem:GetClass(characterId, currentCycle)
    -- Wrapper that always returns a class
    currentCycle = currentCycle or 0
    return self:CalculateClass(characterId, currentCycle)
end

function EconomicsSystem:GetClassDetails(characterId, currentCycle)
    -- Force calculation to update cache
    self:CalculateClass(characterId, currentCycle or 0)
    return self.classCache[characterId]
end

-- ============================================================================
-- Cycle Processing
-- ============================================================================

function EconomicsSystem:StartNewCycle()
    -- Reset per-cycle tracking for all characters
    for characterId, finances in pairs(self.characterFinances) do
        finances.incomeThisCycle = 0
        finances.expensesThisCycle = 0
        finances.incomeSources = {}
        finances.expenseItems = {}
    end
end

function EconomicsSystem:GetCycleSummary(characterId)
    local finances = self.characterFinances[characterId]
    if not finances then
        return nil
    end

    return {
        income = finances.incomeThisCycle,
        expenses = finances.expensesThisCycle,
        netChange = finances.incomeThisCycle - finances.expensesThisCycle,
        currentGold = finances.gold,
        incomeSources = finances.incomeSources,
        expenseItems = finances.expenseItems
    }
end

-- ============================================================================
-- Statistics
-- ============================================================================

function EconomicsSystem:GetTownStatistics(currentCycle)
    local stats = {
        totalPopulation = 0,
        totalWealth = 0,
        averageWealth = 0,
        classCounts = {
            elite = 0,
            upper = 0,
            middle = 0,
            lower = 0
        },
        wealthDistribution = {
            top10Percent = 0,
            bottom50Percent = 0
        }
    }

    -- Collect all character data
    local wealthList = {}
    for characterId, _ in pairs(self.characterFinances) do
        local netWorth = self:CalculateNetWorth(characterId)
        local class = self:GetClass(characterId, currentCycle)

        stats.totalPopulation = stats.totalPopulation + 1
        stats.totalWealth = stats.totalWealth + netWorth
        stats.classCounts[class] = (stats.classCounts[class] or 0) + 1

        table.insert(wealthList, netWorth)
    end

    if stats.totalPopulation > 0 then
        stats.averageWealth = stats.totalWealth / stats.totalPopulation

        -- Sort for distribution calculation
        table.sort(wealthList, function(a, b) return a > b end)

        -- Top 10%
        local top10Count = math.max(1, math.floor(stats.totalPopulation * 0.1))
        for i = 1, top10Count do
            stats.wealthDistribution.top10Percent = stats.wealthDistribution.top10Percent + (wealthList[i] or 0)
        end

        -- Bottom 50%
        local bottom50Start = math.floor(stats.totalPopulation * 0.5) + 1
        for i = bottom50Start, stats.totalPopulation do
            stats.wealthDistribution.bottom50Percent = stats.wealthDistribution.bottom50Percent + (wealthList[i] or 0)
        end
    end

    return stats
end

function EconomicsSystem:CalculateGiniCoefficient()
    -- Calculate Gini coefficient for wealth inequality
    local wealthList = {}
    for characterId, _ in pairs(self.characterFinances) do
        table.insert(wealthList, self:CalculateNetWorth(characterId))
    end

    local n = #wealthList
    if n < 2 then
        return 0
    end

    table.sort(wealthList)

    local totalWealth = 0
    local cumulativeSum = 0

    for i, wealth in ipairs(wealthList) do
        totalWealth = totalWealth + wealth
        cumulativeSum = cumulativeSum + (n + 1 - i) * wealth
    end

    if totalWealth == 0 then
        return 0
    end

    local gini = (n + 1 - 2 * cumulativeSum / totalWealth) / n
    return math.max(0, math.min(1, gini))
end

-- ============================================================================
-- Serialization
-- ============================================================================

function EconomicsSystem:Serialize()
    return {
        characterFinances = self.characterFinances,
        classCache = self.classCache
    }
end

function EconomicsSystem:Deserialize(data)
    if not data then return end

    self.characterFinances = data.characterFinances or {}
    self.classCache = data.classCache or {}

    print("[EconomicsSystem] Deserialized economic data")
end

-- Remove a character from the economics system (e.g., on emigration/death)
function EconomicsSystem:RemoveCharacter(characterId)
    if not characterId then return false end

    -- Remove from finances tracking
    if self.characterFinances[characterId] then
        self.characterFinances[characterId] = nil
    end

    -- Remove from class cache
    if self.classCache[characterId] then
        self.classCache[characterId] = nil
    end

    return true
end

-- ============================================================================
-- Constants
-- ============================================================================

EconomicsSystem.DEFAULT_CLASS = DEFAULT_CLASS
EconomicsSystem.CLASS_ORDER = { "elite", "upper", "middle", "lower" }

return EconomicsSystem
