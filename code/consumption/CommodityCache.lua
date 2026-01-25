-- CommodityCache.lua
-- Hierarchical commodity caching system for fast allocation lookups
-- Phase 4 of consumption system implementation
--
-- Performance targets:
-- - Allocation cycle: < 5ms for 100 characters with 50 commodities
-- - Cache rebuild: < 2ms for full rebuild
-- - Smart invalidation by dimension/group
--
-- Now supports pre-computed cache from info-system for faster startup

local CommodityCache = {}
local DataLoader = require("code.DataLoader")

-- Module-level data
local FulfillmentVectors = nil
local DimensionDefinitions = nil
local SubstitutionRules = nil
local CharacterV2 = nil

-- Cache structure
CommodityCache.cache = {
    -- Level 1: By coarse dimension (9 dimensions)
    byCoarseDimension = {},

    -- Level 2: By fine dimension (49 dimensions)
    byFineDimension = {},

    -- Level 3: Substitution groups
    substitutionGroups = {},

    -- Metadata
    lastFullRebuild = 0,
    totalRebuilds = 0,
    totalInvalidations = 0,
    loadedFromPrecomputed = false
}

-- Performance tracking
CommodityCache.stats = {
    rebuildTimeMs = 0,
    lookupCount = 0,
    cacheHits = 0,
    cacheMisses = 0
}

-- Primary dimension threshold: only cache commodities if their fulfillment
-- value for a dimension is at least this fraction of their max fulfillment
-- This prevents commodities from being allocated for secondary/incidental purposes
-- (e.g., apples being used for medicine when they're primarily produce)
CommodityCache.PRIMARY_THRESHOLD = 0.5  -- 50% of max value

-- Helper: Get the maximum fulfillment value across all fine dimensions for a commodity
function CommodityCache.GetMaxFulfillmentValue(fineVector)
    local maxValue = 0
    for _, value in pairs(fineVector) do
        if value > maxValue then
            maxValue = value
        end
    end
    return maxValue
end

-- Helper: Check if a dimension is a "primary" dimension for a commodity
-- A dimension is primary if its value is >= PRIMARY_THRESHOLD of the commodity's max value
function CommodityCache.IsPrimaryDimension(fineVector, fineName)
    local value = fineVector[fineName] or 0
    if value == 0 then return false end
    local maxValue = CommodityCache.GetMaxFulfillmentValue(fineVector)
    if maxValue == 0 then return false end
    return value >= (maxValue * CommodityCache.PRIMARY_THRESHOLD)
end

-- Try to load pre-computed cache from info-system
function CommodityCache.TryLoadPrecomputed()
    local startTime = love.timer.getTime()
    local filepath = "data/" .. DataLoader.activeVersion .. "/craving_system/commodity_cache.json"

    -- Try to load the pre-computed cache file
    local success, precomputed = pcall(function()
        return DataLoader.loadJSON(filepath)
    end)

    if not success or not precomputed then
        print("CommodityCache: No pre-computed cache found at " .. filepath)
        return false
    end

    -- Validate structure
    if not precomputed.byCoarseDimension or not precomputed.byFineDimension then
        print("CommodityCache: Pre-computed cache has invalid structure")
        return false
    end

    -- Load into cache structure
    local cache = CommodityCache.cache

    -- Load coarse dimension caches
    for coarseName, cacheData in pairs(precomputed.byCoarseDimension) do
        cache.byCoarseDimension[coarseName] = {
            available = cacheData.available or {},
            sortedByValue = cacheData.sortedByValue or {},
            lastUpdated = love.timer.getTime(),
            dirty = false,
            lookupCount = 0
        }
    end

    -- Load fine dimension caches
    for fineName, cacheData in pairs(precomputed.byFineDimension) do
        cache.byFineDimension[fineName] = {
            available = cacheData.available or {},
            sortedByValue = cacheData.sortedByValue or {},
            lastUpdated = love.timer.getTime(),
            dirty = false,
            lookupCount = 0
        }
    end

    -- Load substitution groups
    if precomputed.substitutionGroups then
        for category, groupData in pairs(precomputed.substitutionGroups) do
            cache.substitutionGroups[category] = {
                members = groupData.members or {},
                available = groupData.available or {},
                lastUpdated = love.timer.getTime(),
                dirty = false
            }
        end
    end

    cache.loadedFromPrecomputed = true
    cache.precomputedVersion = precomputed.version
    cache.precomputedGeneratedAt = precomputed.generatedAt

    local endTime = love.timer.getTime()
    local loadTime = (endTime - startTime) * 1000

    print(string.format("CommodityCache: Loaded pre-computed cache in %.2fms", loadTime))
    if precomputed.metadata then
        print(string.format("  - Coarse caches: %d", precomputed.metadata.coarseCacheCount or 0))
        print(string.format("  - Fine caches: %d", precomputed.metadata.fineCacheCount or 0))
        print(string.format("  - Substitution groups: %d", precomputed.metadata.substitutionGroupCount or 0))
        print(string.format("  - Total commodities: %d", precomputed.metadata.totalCommodities or 0))
    end
    print(string.format("  - Generated at: %s", precomputed.generatedAt or "unknown"))

    return true
end

-- Initialize cache system
function CommodityCache.Init(fulfillmentData, dimensionsData, substitutionData, characterV2Module)
    FulfillmentVectors = fulfillmentData
    DimensionDefinitions = dimensionsData
    SubstitutionRules = substitutionData
    CharacterV2 = characterV2Module

    print("CommodityCache: Initializing cache system...")

    -- First, try to load pre-computed cache from info-system
    if CommodityCache.TryLoadPrecomputed() then
        print("CommodityCache: Using pre-computed cache (skipping rebuild)")
        return
    end

    -- Fall back to building cache from scratch
    print("CommodityCache: Building cache from scratch...")

    -- Build initial cache structure
    CommodityCache.InitializeCacheStructure()

    -- Perform full rebuild with all commodities
    local allInventory = {}
    if FulfillmentVectors and FulfillmentVectors.commodities then
        for commodityId, _ in pairs(FulfillmentVectors.commodities) do
            allInventory[commodityId] = 1  -- Assume available for initial cache
        end
    end

    CommodityCache.RebuildFullCache(allInventory)

    print("CommodityCache: Initialization complete")
    print(string.format("  - Coarse caches: %d", CommodityCache.CountCoarseCaches()))
    print(string.format("  - Fine caches: %d", CommodityCache.CountFineCaches()))
    print(string.format("  - Substitution groups: %d", CommodityCache.CountSubstitutionGroups()))
end

-- Initialize empty cache structure
function CommodityCache.InitializeCacheStructure()
    local cache = CommodityCache.cache

    -- Level 1: Coarse dimension caches (0-8)
    for coarseIdx = 0, 8 do
        local coarseName = CharacterV2.coarseNames[coarseIdx]
        if coarseName then
            cache.byCoarseDimension[coarseName] = {
                available = {},      -- List of commodity IDs
                sortedByValue = {},  -- Pre-sorted by total fulfillment value
                lastUpdated = 0,
                dirty = true,
                lookupCount = 0
            }
        end
    end

    -- Level 2: Fine dimension caches (0-48)
    for fineIdx = 0, 48 do
        local fineName = CharacterV2.fineNames[fineIdx]
        if fineName then
            cache.byFineDimension[fineName] = {
                available = {},      -- List of commodity IDs
                sortedByValue = {},  -- Pre-sorted by fulfillment value for this dimension
                lastUpdated = 0,
                dirty = true,
                lookupCount = 0
            }
        end
    end

    -- Level 3: Substitution groups
    if SubstitutionRules and SubstitutionRules.substitutionHierarchies then
        for category, commodities in pairs(SubstitutionRules.substitutionHierarchies) do
            cache.substitutionGroups[category] = {
                members = {},
                available = {},
                lastUpdated = 0,
                dirty = true
            }
        end
    end
end

-- Full cache rebuild (called when inventory changes significantly)
function CommodityCache.RebuildFullCache(inventory)
    local startTime = love.timer.getTime()
    local cache = CommodityCache.cache

    -- Clear all caches
    for _, coarseCache in pairs(cache.byCoarseDimension) do
        coarseCache.available = {}
        coarseCache.sortedByValue = {}
        coarseCache.dirty = false
    end

    for _, fineCache in pairs(cache.byFineDimension) do
        fineCache.available = {}
        fineCache.sortedByValue = {}
        fineCache.dirty = false
    end

    for _, groupCache in pairs(cache.substitutionGroups) do
        groupCache.available = {}
    end

    -- Rebuild caches from inventory
    if FulfillmentVectors and FulfillmentVectors.commodities then
        for commodityId, commodityData in pairs(FulfillmentVectors.commodities) do
            -- Only cache available commodities
            if inventory[commodityId] and inventory[commodityId] > 0 then
                local fineVector = commodityData.fulfillmentVector and commodityData.fulfillmentVector.fine

                if fineVector then
                    -- Add to fine dimension caches (only for PRIMARY dimensions)
                    -- This prevents commodities from being used for secondary/incidental purposes
                    for fineName, points in pairs(fineVector) do
                        -- Only include if this is a primary dimension (>= threshold of max)
                        local isPrimary = CommodityCache.IsPrimaryDimension(fineVector, fineName)
                        if isPrimary and cache.byFineDimension[fineName] then
                            table.insert(cache.byFineDimension[fineName].available, {
                                id = commodityId,
                                value = points
                            })
                        end
                    end

                    -- Add to coarse dimension caches
                    -- Aggregate ONLY primary fine dimension values to coarse
                    local coarseValues = {}
                    for fineName, points in pairs(fineVector) do
                        -- Only aggregate primary dimensions to coarse caches
                        local isPrimary = CommodityCache.IsPrimaryDimension(fineVector, fineName)
                        if isPrimary then
                            -- Find coarse parent
                            local fineIdx = CharacterV2.fineNames and CommodityCache.FindFineIndex(fineName)
                            if fineIdx then
                                local coarseIdx = CharacterV2.fineToCoarseMap[fineIdx]
                                local coarseName = CharacterV2.coarseNames[coarseIdx]
                                if coarseName then
                                    coarseValues[coarseName] = (coarseValues[coarseName] or 0) + points
                                end
                            end
                        end
                    end

                    for coarseName, totalPoints in pairs(coarseValues) do
                        if cache.byCoarseDimension[coarseName] then
                            table.insert(cache.byCoarseDimension[coarseName].available, {
                                id = commodityId,
                                value = totalPoints
                            })
                        end
                    end
                end
            end
        end
    end

    -- Sort all caches by value (descending)
    for _, fineCache in pairs(cache.byFineDimension) do
        table.sort(fineCache.available, function(a, b)
            return a.value > b.value
        end)
        -- Extract just IDs for sortedByValue
        fineCache.sortedByValue = {}
        for _, entry in ipairs(fineCache.available) do
            table.insert(fineCache.sortedByValue, entry.id)
        end
    end

    for _, coarseCache in pairs(cache.byCoarseDimension) do
        table.sort(coarseCache.available, function(a, b)
            return a.value > b.value
        end)
        -- Extract just IDs for sortedByValue
        coarseCache.sortedByValue = {}
        for _, entry in ipairs(coarseCache.available) do
            table.insert(coarseCache.sortedByValue, entry.id)
        end
    end

    -- Rebuild substitution groups
    if SubstitutionRules and SubstitutionRules.substitutionHierarchies then
        for category, commodities in pairs(SubstitutionRules.substitutionHierarchies) do
            if cache.substitutionGroups[category] then
                for commodityId, _ in pairs(commodities) do
                    if inventory[commodityId] and inventory[commodityId] > 0 then
                        table.insert(cache.substitutionGroups[category].available, commodityId)
                    end
                end
            end
        end
    end

    -- Update metadata
    local endTime = love.timer.getTime()
    local rebuildTime = (endTime - startTime) * 1000  -- Convert to ms

    cache.lastFullRebuild = love.timer.getTime()
    cache.totalRebuilds = cache.totalRebuilds + 1
    CommodityCache.stats.rebuildTimeMs = rebuildTime

    print(string.format("CommodityCache: Full rebuild completed in %.2fms", rebuildTime))
end

-- Smart invalidation: mark specific dimensions as dirty
function CommodityCache.InvalidateCommodity(commodityId)
    local cache = CommodityCache.cache

    if not FulfillmentVectors or not FulfillmentVectors.commodities then
        return
    end

    local commodityData = FulfillmentVectors.commodities[commodityId]
    if not commodityData then
        return
    end

    local fineVector = commodityData.fulfillmentVector and commodityData.fulfillmentVector.fine
    if not fineVector then
        return
    end

    -- Invalidate affected fine dimension caches
    for fineName, points in pairs(fineVector) do
        if points > 0 and cache.byFineDimension[fineName] then
            cache.byFineDimension[fineName].dirty = true
        end
    end

    -- Invalidate affected coarse dimension caches
    local affectedCoarse = {}
    for fineName, points in pairs(fineVector) do
        if points > 0 then
            local fineIdx = CommodityCache.FindFineIndex(fineName)
            if fineIdx then
                local coarseIdx = CharacterV2.fineToCoarseMap[fineIdx]
                local coarseName = CharacterV2.coarseNames[coarseIdx]
                if coarseName and not affectedCoarse[coarseName] then
                    affectedCoarse[coarseName] = true
                    if cache.byCoarseDimension[coarseName] then
                        cache.byCoarseDimension[coarseName].dirty = true
                    end
                end
            end
        end
    end

    -- Invalidate substitution group
    if SubstitutionRules and SubstitutionRules.substitutionHierarchies then
        for category, commodities in pairs(SubstitutionRules.substitutionHierarchies) do
            if commodities[commodityId] and cache.substitutionGroups[category] then
                cache.substitutionGroups[category].dirty = true
            end
        end
    end

    cache.totalInvalidations = cache.totalInvalidations + 1
end

-- Get commodities for a specific fine dimension (fast lookup)
function CommodityCache.GetCommoditiesForFineDimension(fineName, inventory)
    local cache = CommodityCache.cache.byFineDimension[fineName]

    if not cache then
        CommodityCache.stats.cacheMisses = CommodityCache.stats.cacheMisses + 1
        return {}
    end

    cache.lookupCount = cache.lookupCount + 1
    CommodityCache.stats.lookupCount = CommodityCache.stats.lookupCount + 1

    -- If dirty, rebuild this cache
    if cache.dirty then
        CommodityCache.RebuildFineDimensionCache(fineName, inventory)
    end

    CommodityCache.stats.cacheHits = CommodityCache.stats.cacheHits + 1
    return cache.sortedByValue
end

-- Get commodities for a specific coarse dimension (fast lookup)
function CommodityCache.GetCommoditiesForCoarseDimension(coarseName, inventory)
    local cache = CommodityCache.cache.byCoarseDimension[coarseName]

    if not cache then
        CommodityCache.stats.cacheMisses = CommodityCache.stats.cacheMisses + 1
        return {}
    end

    cache.lookupCount = cache.lookupCount + 1
    CommodityCache.stats.lookupCount = CommodityCache.stats.lookupCount + 1

    -- If dirty, rebuild this cache
    if cache.dirty then
        CommodityCache.RebuildCoarseDimensionCache(coarseName, inventory)
    end

    CommodityCache.stats.cacheHits = CommodityCache.stats.cacheHits + 1
    return cache.sortedByValue
end

-- Rebuild a single fine dimension cache
-- Only includes commodities for which this dimension is PRIMARY (>= threshold of max)
function CommodityCache.RebuildFineDimensionCache(fineName, inventory)
    local cache = CommodityCache.cache.byFineDimension[fineName]
    if not cache then return end

    cache.available = {}

    if FulfillmentVectors and FulfillmentVectors.commodities then
        for commodityId, commodityData in pairs(FulfillmentVectors.commodities) do
            if inventory[commodityId] and inventory[commodityId] > 0 then
                local fineVector = commodityData.fulfillmentVector and commodityData.fulfillmentVector.fine
                if fineVector and fineVector[fineName] then
                    -- Only include if this is a primary dimension for this commodity
                    local isPrimary = CommodityCache.IsPrimaryDimension(fineVector, fineName)
                    if isPrimary then
                        table.insert(cache.available, {
                            id = commodityId,
                            value = fineVector[fineName]
                        })
                    end
                end
            end
        end
    end

    -- Sort by value descending
    table.sort(cache.available, function(a, b)
        return a.value > b.value
    end)

    -- Extract IDs
    cache.sortedByValue = {}
    for _, entry in ipairs(cache.available) do
        table.insert(cache.sortedByValue, entry.id)
    end

    cache.dirty = false
    cache.lastUpdated = love.timer.getTime()
end

-- Rebuild a single coarse dimension cache
-- Only aggregates PRIMARY fine dimensions (>= threshold of max)
function CommodityCache.RebuildCoarseDimensionCache(coarseName, inventory)
    local cache = CommodityCache.cache.byCoarseDimension[coarseName]
    if not cache then return end

    cache.available = {}

    -- Get coarse index
    local coarseIdx = CharacterV2.coarseNameToIndex[coarseName]
    if not coarseIdx then return end

    -- Get fine dimension indices for this coarse
    local fineIndices = CharacterV2.coarseToFineMap[coarseIdx]
    if not fineIndices or #fineIndices == 0 then return end

    if FulfillmentVectors and FulfillmentVectors.commodities then
        for commodityId, commodityData in pairs(FulfillmentVectors.commodities) do
            if inventory[commodityId] and inventory[commodityId] > 0 then
                local fineVector = commodityData.fulfillmentVector and commodityData.fulfillmentVector.fine
                if fineVector then
                    -- Sum up only PRIMARY fine values in this coarse dimension
                    local totalValue = 0
                    for _, fineIdx in ipairs(fineIndices) do
                        local fineName = CharacterV2.fineNames[fineIdx]
                        if fineName and fineVector[fineName] then
                            -- Only include if this is a primary dimension
                            local isPrimary = CommodityCache.IsPrimaryDimension(fineVector, fineName)
                            if isPrimary then
                                totalValue = totalValue + fineVector[fineName]
                            end
                        end
                    end

                    if totalValue > 0 then
                        table.insert(cache.available, {
                            id = commodityId,
                            value = totalValue
                        })
                    end
                end
            end
        end
    end

    -- Sort by value descending
    table.sort(cache.available, function(a, b)
        return a.value > b.value
    end)

    -- Extract IDs
    cache.sortedByValue = {}
    for _, entry in ipairs(cache.available) do
        table.insert(cache.sortedByValue, entry.id)
    end

    cache.dirty = false
    cache.lastUpdated = love.timer.getTime()
end

-- Helper: Find fine dimension index by name
function CommodityCache.FindFineIndex(fineName)
    if not CharacterV2.fineNames then return nil end

    for idx, name in pairs(CharacterV2.fineNames) do
        if name == fineName then
            return idx
        end
    end

    return nil
end

-- Utility: Count coarse caches
function CommodityCache.CountCoarseCaches()
    local count = 0
    for _ in pairs(CommodityCache.cache.byCoarseDimension) do
        count = count + 1
    end
    return count
end

-- Utility: Count fine caches
function CommodityCache.CountFineCaches()
    local count = 0
    for _ in pairs(CommodityCache.cache.byFineDimension) do
        count = count + 1
    end
    return count
end

-- Utility: Count substitution groups
function CommodityCache.CountSubstitutionGroups()
    local count = 0
    for _ in pairs(CommodityCache.cache.substitutionGroups) do
        count = count + 1
    end
    return count
end

-- Get cache statistics
function CommodityCache.GetStats()
    local hitRate = CommodityCache.stats.lookupCount > 0
        and (CommodityCache.stats.cacheHits / CommodityCache.stats.lookupCount * 100)
        or 0

    return {
        totalRebuilds = CommodityCache.cache.totalRebuilds,
        totalInvalidations = CommodityCache.cache.totalInvalidations,
        lookupCount = CommodityCache.stats.lookupCount,
        cacheHits = CommodityCache.stats.cacheHits,
        cacheMisses = CommodityCache.stats.cacheMisses,
        hitRate = hitRate,
        lastRebuildTimeMs = CommodityCache.stats.rebuildTimeMs,
        coarseCaches = CommodityCache.CountCoarseCaches(),
        fineCaches = CommodityCache.CountFineCaches(),
        substitutionGroups = CommodityCache.CountSubstitutionGroups(),
        loadedFromPrecomputed = CommodityCache.cache.loadedFromPrecomputed or false,
        precomputedVersion = CommodityCache.cache.precomputedVersion,
        precomputedGeneratedAt = CommodityCache.cache.precomputedGeneratedAt
    }
end

-- Print cache statistics
function CommodityCache.PrintStats()
    local stats = CommodityCache.GetStats()
    print("=== CommodityCache Statistics ===")
    if stats.loadedFromPrecomputed then
        print("  Source: Pre-computed (from info-system)")
        print(string.format("  Generated at: %s", stats.precomputedGeneratedAt or "unknown"))
    else
        print("  Source: Built at runtime")
    end
    print(string.format("  Total rebuilds: %d", stats.totalRebuilds))
    print(string.format("  Total invalidations: %d", stats.totalInvalidations))
    print(string.format("  Lookup count: %d", stats.lookupCount))
    print(string.format("  Cache hits: %d (%.1f%%)", stats.cacheHits, stats.hitRate))
    print(string.format("  Cache misses: %d", stats.cacheMisses))
    print(string.format("  Last rebuild time: %.2fms", stats.lastRebuildTimeMs))
    print(string.format("  Coarse caches: %d", stats.coarseCaches))
    print(string.format("  Fine caches: %d", stats.fineCaches))
    print(string.format("  Substitution groups: %d", stats.substitutionGroups))
end

-- Reset statistics (for testing)
function CommodityCache.ResetStats()
    CommodityCache.stats = {
        rebuildTimeMs = 0,
        lookupCount = 0,
        cacheHits = 0,
        cacheMisses = 0
    }
end

return CommodityCache
