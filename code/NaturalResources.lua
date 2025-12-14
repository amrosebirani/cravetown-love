--
-- NaturalResources - Manages natural resource distribution across the game map
-- Uses PerlinNoise for continuous resources and cluster generation for discrete deposits
--

require("code.PerlinNoise")

NaturalResources = {}
NaturalResources.__index = NaturalResources

-- Default cell size for resource grid (in pixels)
local DEFAULT_CELL_SIZE = 20

--
-- Create a new NaturalResources manager
--
-- @param params - Configuration table:
--   river: Reference to river object for collision/influence
--   boundaryMinX, boundaryMaxX, boundaryMinY, boundaryMaxY: Map boundaries
--   seed: Random seed for generation (optional)
--   cellSize: Grid cell size in pixels (optional, default 20)
--
function NaturalResources:Create(params)
    local this = {
        -- Map boundaries
        mBoundaryMinX = params.boundaryMinX or params.minX or -1250,
        mBoundaryMaxX = params.boundaryMaxX or params.maxX or 1250,
        mBoundaryMinY = params.boundaryMinY or params.minY or -1250,
        mBoundaryMaxY = params.boundaryMaxY or params.maxY or 1250,

        -- Grid configuration
        mCellSize = params.cellSize or DEFAULT_CELL_SIZE,

        -- References
        mRiver = params.river,

        -- Resource definitions (loaded from JSON)
        mDefinitions = {},

        -- Resource grids (2D arrays of values)
        mGrids = {},

        -- Deposit locations for discrete resources
        mDeposits = {},

        -- Hotspot locations for continuous resources
        mHotspots = {},

        -- Noise generator
        mNoise = nil,

        -- Random seed
        mSeed = params.seed or os.time(),

        -- Generated flag
        mGenerated = false
    }

    setmetatable(this, self)

    -- Calculate grid dimensions
    local mapWidth = this.mBoundaryMaxX - this.mBoundaryMinX
    local mapHeight = this.mBoundaryMaxY - this.mBoundaryMinY
    this.mGridWidth = math.ceil(mapWidth / this.mCellSize)
    this.mGridHeight = math.ceil(mapHeight / this.mCellSize)

    -- Initialize noise generator
    this.mNoise = PerlinNoise:Create(this.mSeed)

    -- Load resource definitions
    this:loadDefinitions()

    return this
end

--
-- Load resource definitions from JSON file
--
function NaturalResources:loadDefinitions()
    local DataLoader = require("code.DataLoader")

    local success, data = pcall(function()
        return DataLoader.loadNaturalResources()
    end)

    if success and data and data.naturalResources then
        for _, resource in ipairs(data.naturalResources) do
            self.mDefinitions[resource.id] = resource
        end
        print("[NaturalResources] Loaded " .. #data.naturalResources .. " resource definitions")
    else
        print("[NaturalResources] Warning: Could not load resource definitions, using defaults")
        self:loadDefaultDefinitions()
    end
end

--
-- Load default resource definitions (fallback)
--
function NaturalResources:loadDefaultDefinitions()
    -- Continuous resources
    self.mDefinitions["ground_water"] = {
        id = "ground_water",
        name = "Ground Water",
        category = "continuous",
        distribution = {
            type = "perlin_hybrid",
            perlinWeight = 0.6,
            hotspotWeight = 0.4,
            frequency = 0.01,
            octaves = 3,
            persistence = 0.5,
            hotspotCount = {2, 4},
            hotspotRadius = {150, 300},
            hotspotIntensity = {0.6, 1.0}
        },
        riverInfluence = { enabled = true, range = 200, boost = 0.3 },
        visualization = { color = {0.2, 0.5, 0.9}, opacity = 0.6, showThreshold = 0.1 }
    }

    self.mDefinitions["fertility"] = {
        id = "fertility",
        name = "Land Fertility",
        category = "continuous",
        distribution = {
            type = "perlin_hybrid",
            perlinWeight = 0.6,
            hotspotWeight = 0.4,
            frequency = 0.012,
            octaves = 4,
            persistence = 0.5,
            hotspotCount = {3, 5},
            hotspotRadius = {120, 280},
            hotspotIntensity = {0.5, 1.0}
        },
        riverInfluence = { enabled = true, range = 150, boost = 0.2 },
        visualization = { color = {0.3, 0.6, 0.2}, opacity = 0.6, showThreshold = 0.1 }
    }

    -- Discrete resources
    self.mDefinitions["iron_ore"] = {
        id = "iron_ore",
        name = "Iron Ore",
        category = "discrete",
        distribution = {
            type = "regional_cluster",
            depositCount = {3, 5},
            depositRadius = {80, 150},
            centerRichness = {0.7, 1.0},
            falloffExponent = 2,
            noiseVariation = 0.1
        },
        collisionRules = { riverDistance = 100, sameTypeDistance = 200, boundaryBuffer = 50 },
        visualization = { color = {0.6, 0.3, 0.2}, opacity = 0.7, showThreshold = 0.2 }
    }

    self.mDefinitions["copper_ore"] = {
        id = "copper_ore",
        name = "Copper Ore",
        category = "discrete",
        distribution = {
            type = "regional_cluster",
            depositCount = {2, 4},
            depositRadius = {60, 120},
            centerRichness = {0.6, 0.95},
            falloffExponent = 2,
            noiseVariation = 0.1
        },
        collisionRules = { riverDistance = 100, sameTypeDistance = 180, boundaryBuffer = 50 },
        visualization = { color = {0.8, 0.5, 0.3}, opacity = 0.7, showThreshold = 0.2 }
    }

    self.mDefinitions["coal"] = {
        id = "coal",
        name = "Coal",
        category = "discrete",
        distribution = {
            type = "regional_cluster",
            depositCount = {2, 4},
            depositRadius = {100, 180},
            centerRichness = {0.7, 1.0},
            falloffExponent = 2,
            noiseVariation = 0.15
        },
        collisionRules = { riverDistance = 80, sameTypeDistance = 220, boundaryBuffer = 50 },
        visualization = { color = {0.2, 0.2, 0.2}, opacity = 0.7, showThreshold = 0.2 }
    }

    self.mDefinitions["gold_ore"] = {
        id = "gold_ore",
        name = "Gold Ore",
        category = "discrete",
        distribution = {
            type = "regional_cluster",
            depositCount = {1, 2},
            depositRadius = {40, 80},
            centerRichness = {0.8, 1.0},
            falloffExponent = 2.5,
            noiseVariation = 0.05
        },
        collisionRules = { riverDistance = 100, sameTypeDistance = 300, boundaryBuffer = 80 },
        visualization = { color = {0.9, 0.8, 0.2}, opacity = 0.8, showThreshold = 0.3 }
    }

    self.mDefinitions["silver_ore"] = {
        id = "silver_ore",
        name = "Silver Ore",
        category = "discrete",
        distribution = {
            type = "regional_cluster",
            depositCount = {1, 2},
            depositRadius = {40, 80},
            centerRichness = {0.75, 1.0},
            falloffExponent = 2.5,
            noiseVariation = 0.05
        },
        collisionRules = { riverDistance = 100, sameTypeDistance = 300, boundaryBuffer = 80 },
        visualization = { color = {0.75, 0.75, 0.75}, opacity = 0.8, showThreshold = 0.3 }
    }

    self.mDefinitions["stone"] = {
        id = "stone",
        name = "Stone",
        category = "discrete",
        distribution = {
            type = "regional_cluster",
            depositCount = {4, 6},
            depositRadius = {80, 150},
            centerRichness = {0.6, 1.0},
            falloffExponent = 1.5,
            noiseVariation = 0.2
        },
        collisionRules = { riverDistance = 60, sameTypeDistance = 150, boundaryBuffer = 40 },
        visualization = { color = {0.5, 0.5, 0.5}, opacity = 0.6, showThreshold = 0.15 }
    }

    self.mDefinitions["oil"] = {
        id = "oil",
        name = "Oil",
        category = "discrete",
        distribution = {
            type = "regional_cluster",
            depositCount = {1, 2},
            depositRadius = {60, 100},
            centerRichness = {0.8, 1.0},
            falloffExponent = 3,
            noiseVariation = 0.05
        },
        collisionRules = { riverDistance = 150, sameTypeDistance = 400, boundaryBuffer = 100 },
        visualization = { color = {0.1, 0.1, 0.1}, opacity = 0.8, showThreshold = 0.4 }
    }

    self.mDefinitions["natural_gas"] = {
        id = "natural_gas",
        name = "Natural Gas",
        category = "discrete",
        distribution = {
            type = "regional_cluster",
            depositCount = {1, 3},
            depositRadius = {50, 90},
            centerRichness = {0.7, 1.0},
            falloffExponent = 2.5,
            noiseVariation = 0.1
        },
        collisionRules = { riverDistance = 120, sameTypeDistance = 250, boundaryBuffer = 80 },
        visualization = { color = {0.7, 0.9, 1.0}, opacity = 0.7, showThreshold = 0.35 }
    }

    self.mDefinitions["clay"] = {
        id = "clay",
        name = "Clay",
        category = "discrete",
        distribution = {
            type = "regional_cluster",
            depositCount = {2, 4},
            depositRadius = {60, 100},
            centerRichness = {0.6, 0.95},
            falloffExponent = 2,
            noiseVariation = 0.15
        },
        collisionRules = { riverDistance = 50, sameTypeDistance = 150, boundaryBuffer = 40 },
        visualization = { color = {0.8, 0.6, 0.4}, opacity = 0.6, showThreshold = 0.2 }
    }
end

--
-- Initialize an empty grid for a resource
--
function NaturalResources:initGrid(resourceId)
    self.mGrids[resourceId] = {}
    for x = 1, self.mGridWidth do
        self.mGrids[resourceId][x] = {}
        for y = 1, self.mGridHeight do
            self.mGrids[resourceId][x][y] = 0
        end
    end
end

--
-- Convert world coordinates to grid coordinates
--
function NaturalResources:worldToGrid(worldX, worldY)
    local gridX = math.floor((worldX - self.mBoundaryMinX) / self.mCellSize) + 1
    local gridY = math.floor((worldY - self.mBoundaryMinY) / self.mCellSize) + 1

    -- Clamp to grid bounds
    gridX = math.max(1, math.min(self.mGridWidth, gridX))
    gridY = math.max(1, math.min(self.mGridHeight, gridY))

    return gridX, gridY
end

--
-- Convert grid coordinates to world coordinates (center of cell)
--
function NaturalResources:gridToWorld(gridX, gridY)
    local worldX = self.mBoundaryMinX + (gridX - 0.5) * self.mCellSize
    local worldY = self.mBoundaryMinY + (gridY - 0.5) * self.mCellSize
    return worldX, worldY
end

--
-- Check if a position is near the river
--
function NaturalResources:isNearRiver(x, minDistance)
    if not self.mRiver then
        return false
    end
    -- Simple check: river flows roughly around X=0
    return math.abs(x) < minDistance
end

--
-- Generate a continuous resource (ground water, fertility)
--
function NaturalResources:generateContinuousResource(resourceId)
    local def = self.mDefinitions[resourceId]
    if not def or def.category ~= "continuous" then
        print("[NaturalResources] Warning: " .. resourceId .. " is not a continuous resource")
        return
    end

    local dist = def.distribution
    self:initGrid(resourceId)

    -- Generate hotspots
    local hotspotCount = dist.hotspotCount or {2, 4}
    local hotspotRadius = dist.hotspotRadius or {150, 300}
    local hotspotIntensity = dist.hotspotIntensity or {0.6, 1.0}

    local bounds = {
        minX = self.mBoundaryMinX,
        maxX = self.mBoundaryMaxX,
        minY = self.mBoundaryMinY,
        maxY = self.mBoundaryMaxY
    }

    local hotspots = self.mNoise:generateHotspots(
        hotspotCount[1], hotspotCount[2],
        bounds,
        hotspotRadius[1], hotspotRadius[2],
        hotspotIntensity[1], hotspotIntensity[2]
    )
    self.mHotspots[resourceId] = hotspots

    -- Generate grid values
    local perlinWeight = dist.perlinWeight or 0.6
    local hotspotWeight = dist.hotspotWeight or 0.4
    local frequency = dist.frequency or 0.01
    local octaves = dist.octaves or 3

    local riverInfluence = def.riverInfluence or { enabled = false }

    for gx = 1, self.mGridWidth do
        for gy = 1, self.mGridHeight do
            local worldX, worldY = self:gridToWorld(gx, gy)

            -- Calculate hybrid value
            local value = self.mNoise:hybridValue(
                worldX, worldY,
                hotspots,
                perlinWeight, hotspotWeight,
                frequency, octaves
            )

            -- Apply river influence
            if riverInfluence.enabled then
                value = self.mNoise:applyRiverInfluence(
                    value,
                    worldX,
                    worldY,
                    riverInfluence.range or 200,
                    riverInfluence.boost or 0.3,
                    self.mRiver
                )
            end

            self.mGrids[resourceId][gx][gy] = value
        end
    end

    print("[NaturalResources] Generated continuous resource: " .. resourceId)
end

--
-- Generate a discrete resource (ores, oil, etc.)
--
function NaturalResources:generateDiscreteResource(resourceId, allDeposits)
    local def = self.mDefinitions[resourceId]
    if not def or def.category ~= "discrete" then
        print("[NaturalResources] Warning: " .. resourceId .. " is not a discrete resource")
        return
    end

    local dist = def.distribution
    local collision = def.collisionRules or {}
    self:initGrid(resourceId)

    -- Generate deposit locations
    local bounds = {
        minX = self.mBoundaryMinX,
        maxX = self.mBoundaryMaxX,
        minY = self.mBoundaryMinY,
        maxY = self.mBoundaryMaxY
    }

    local deposits = self.mNoise:generateDeposits(
        dist.depositCount[1], dist.depositCount[2],
        bounds,
        dist.depositRadius[1], dist.depositRadius[2],
        dist.centerRichness[1], dist.centerRichness[2],
        collision,
        allDeposits,
        self.mRiver
    )
    self.mDeposits[resourceId] = deposits

    -- Fill grid based on deposits
    local falloffExponent = dist.falloffExponent or 2
    local noiseVariation = dist.noiseVariation or 0.1

    for gx = 1, self.mGridWidth do
        for gy = 1, self.mGridHeight do
            local worldX, worldY = self:gridToWorld(gx, gy)

            local value = self.mNoise:clusterValue(
                worldX, worldY,
                deposits,
                falloffExponent,
                noiseVariation
            )

            self.mGrids[resourceId][gx][gy] = value
        end
    end

    print("[NaturalResources] Generated discrete resource: " .. resourceId .. " with " .. #deposits .. " deposits")

    return deposits
end

--
-- Generate all resources
--
function NaturalResources:generateAll()
    print("[NaturalResources] Generating all resources...")
    local startTime = os.clock()

    -- Seed random for consistent generation
    math.randomseed(self.mSeed)

    -- Generate continuous resources first
    for resourceId, def in pairs(self.mDefinitions) do
        if def.category == "continuous" then
            self:generateContinuousResource(resourceId)
        end
    end

    -- Generate discrete resources (accumulate deposits for collision)
    local allDeposits = {}
    for resourceId, def in pairs(self.mDefinitions) do
        if def.category == "discrete" then
            local newDeposits = self:generateDiscreteResource(resourceId, allDeposits)
            if newDeposits then
                for _, deposit in ipairs(newDeposits) do
                    table.insert(allDeposits, deposit)
                end
            end
        end
    end

    self.mGenerated = true
    local elapsed = os.clock() - startTime
    print(string.format("[NaturalResources] Generation complete in %.3f seconds", elapsed))
end

--
-- Get resource value at a world position
--
function NaturalResources:getValue(resourceId, worldX, worldY)
    if not self.mGrids[resourceId] then
        return 0
    end

    local gx, gy = self:worldToGrid(worldX, worldY)
    return self.mGrids[resourceId][gx][gy] or 0
end

--
-- Get average resource value in an area
--
function NaturalResources:getAverageValue(resourceId, worldX, worldY, width, height)
    if not self.mGrids[resourceId] then
        return 0
    end

    local startGX, startGY = self:worldToGrid(worldX, worldY)
    local endGX, endGY = self:worldToGrid(worldX + width, worldY + height)

    local total = 0
    local count = 0

    for gx = startGX, endGX do
        for gy = startGY, endGY do
            if self.mGrids[resourceId][gx] and self.mGrids[resourceId][gx][gy] then
                total = total + self.mGrids[resourceId][gx][gy]
                count = count + 1
            end
        end
    end

    return count > 0 and (total / count) or 0
end

--
-- Get maximum resource value in an area
--
function NaturalResources:getMaxValue(resourceId, worldX, worldY, width, height)
    if not self.mGrids[resourceId] then
        return 0
    end

    local startGX, startGY = self:worldToGrid(worldX, worldY)
    local endGX, endGY = self:worldToGrid(worldX + width, worldY + height)

    local maxVal = 0

    for gx = startGX, endGX do
        for gy = startGY, endGY do
            if self.mGrids[resourceId][gx] and self.mGrids[resourceId][gx][gy] then
                maxVal = math.max(maxVal, self.mGrids[resourceId][gx][gy])
            end
        end
    end

    return maxVal
end

--
-- Get the best matching resource from a list (for "anyOf" constraints)
--
function NaturalResources:getBestOfAny(resourceIds, worldX, worldY, width, height)
    local bestValue = 0
    local bestResourceId = nil

    for _, resourceId in ipairs(resourceIds) do
        local value = self:getAverageValue(resourceId, worldX, worldY, width, height)
        if value > bestValue then
            bestValue = value
            bestResourceId = resourceId
        end
    end

    return bestValue, bestResourceId
end

--
-- Calculate building efficiency based on placement constraints
--
-- @param buildingType - Building type definition with placementConstraints
-- @param worldX, worldY - Building position
-- @param width, height - Building dimensions
-- @return efficiency (0-1), breakdown table, canPlace boolean
--
function NaturalResources:calculateBuildingEfficiency(buildingType, worldX, worldY, width, height)
    local constraints = buildingType.placementConstraints

    -- No constraints = 100% efficiency
    if not constraints or not constraints.enabled then
        return 1.0, {}, true
    end

    local requiredResources = constraints.requiredResources or {}
    if #requiredResources == 0 then
        return 1.0, {}, true
    end

    local breakdown = {}
    local formula = constraints.efficiencyFormula or "weighted_average"
    local blockingThreshold = constraints.blockingThreshold or 0.1

    local totalWeight = 0
    local weightedSum = 0
    local minValue = 1.0

    for _, req in ipairs(requiredResources) do
        local value = 0
        local matchedResource = req.resourceId

        -- Handle "anyOf" resources (like ore_any)
        if req.anyOf and #req.anyOf > 0 then
            value, matchedResource = self:getBestOfAny(req.anyOf, worldX, worldY, width, height)
        else
            value = self:getAverageValue(req.resourceId, worldX, worldY, width, height)
        end

        breakdown[req.resourceId] = {
            value = value,
            weight = req.weight,
            minValue = req.minValue,
            displayName = req.displayName,
            matchedResource = matchedResource
        }

        -- Check minimum threshold
        if value < (req.minValue or 0) then
            -- Resource requirement not met
            breakdown[req.resourceId].met = false
        else
            breakdown[req.resourceId].met = true
        end

        -- For formulas
        totalWeight = totalWeight + req.weight
        weightedSum = weightedSum + (value * req.weight)
        minValue = math.min(minValue, value)
    end

    -- Calculate efficiency based on formula
    local efficiency = 0

    if formula == "weighted_average" then
        efficiency = totalWeight > 0 and (weightedSum / totalWeight) or 0
    elseif formula == "direct" then
        -- Use the first resource's value directly
        if #requiredResources > 0 then
            local firstReq = requiredResources[1]
            if firstReq.anyOf then
                efficiency = self:getBestOfAny(firstReq.anyOf, worldX, worldY, width, height)
            else
                efficiency = self:getAverageValue(firstReq.resourceId, worldX, worldY, width, height)
            end
        end
    elseif formula == "minimum" then
        efficiency = minValue
    end

    -- Clamp efficiency
    efficiency = math.max(0, math.min(1, efficiency))

    -- Check if can place
    local canPlace = efficiency >= blockingThreshold

    return efficiency, breakdown, canPlace
end

--
-- Get resource definition
--
function NaturalResources:getDefinition(resourceId)
    return self.mDefinitions[resourceId]
end

--
-- Get all resource IDs
--
function NaturalResources:getAllResourceIds()
    local ids = {}
    for id, _ in pairs(self.mDefinitions) do
        table.insert(ids, id)
    end
    return ids
end

--
-- Get deposits for a resource
--
function NaturalResources:getDeposits(resourceId)
    return self.mDeposits[resourceId] or {}
end

--
-- Get hotspots for a resource
--
function NaturalResources:getHotspots(resourceId)
    return self.mHotspots[resourceId] or {}
end

--
-- Check if resources have been generated
--
function NaturalResources:isGenerated()
    return self.mGenerated
end

--
-- Get grid dimensions
--
function NaturalResources:getGridDimensions()
    return self.mGridWidth, self.mGridHeight, self.mCellSize
end

--
-- Get map boundaries
--
function NaturalResources:getBoundaries()
    return self.mBoundaryMinX, self.mBoundaryMaxX, self.mBoundaryMinY, self.mBoundaryMaxY
end

--
-- Serialize resource data for saving
--
function NaturalResources:serialize()
    local data = {
        seed = self.mSeed,
        cellSize = self.mCellSize,
        boundaries = {
            minX = self.mBoundaryMinX,
            maxX = self.mBoundaryMaxX,
            minY = self.mBoundaryMinY,
            maxY = self.mBoundaryMaxY
        },
        grids = {},
        deposits = self.mDeposits,
        hotspots = self.mHotspots,
        generated = self.mGenerated
    }

    -- Serialize grids (can be large, consider compression)
    for resourceId, grid in pairs(self.mGrids) do
        data.grids[resourceId] = {}
        for x = 1, self.mGridWidth do
            data.grids[resourceId][x] = {}
            for y = 1, self.mGridHeight do
                -- Store with reduced precision to save space
                data.grids[resourceId][x][y] = math.floor(grid[x][y] * 1000) / 1000
            end
        end
    end

    return data
end

--
-- Deserialize resource data from save
--
function NaturalResources:deserialize(data)
    if not data then return false end

    self.mSeed = data.seed or self.mSeed
    self.mCellSize = data.cellSize or self.mCellSize

    if data.boundaries then
        self.mBoundaryMinX = data.boundaries.minX or self.mBoundaryMinX
        self.mBoundaryMaxX = data.boundaries.maxX or self.mBoundaryMaxX
        self.mBoundaryMinY = data.boundaries.minY or self.mBoundaryMinY
        self.mBoundaryMaxY = data.boundaries.maxY or self.mBoundaryMaxY
    end

    -- Recalculate grid dimensions
    local mapWidth = self.mBoundaryMaxX - self.mBoundaryMinX
    local mapHeight = self.mBoundaryMaxY - self.mBoundaryMinY
    self.mGridWidth = math.ceil(mapWidth / self.mCellSize)
    self.mGridHeight = math.ceil(mapHeight / self.mCellSize)

    -- Restore grids
    if data.grids then
        self.mGrids = data.grids
    end

    -- Restore deposits and hotspots
    self.mDeposits = data.deposits or {}
    self.mHotspots = data.hotspots or {}
    self.mGenerated = data.generated or false

    return true
end

--
-- Get grid data for rendering (used by overlay)
--
function NaturalResources:getGridData(resourceId)
    return self.mGrids[resourceId]
end

--
-- Debug: Print resource statistics
--
function NaturalResources:printStats()
    print("=== Natural Resources Statistics ===")
    print(string.format("Grid: %dx%d cells, %dpx per cell", self.mGridWidth, self.mGridHeight, self.mCellSize))
    print(string.format("Boundaries: (%.0f,%.0f) to (%.0f,%.0f)",
        self.mBoundaryMinX, self.mBoundaryMinY, self.mBoundaryMaxX, self.mBoundaryMaxY))
    print("")

    for resourceId, def in pairs(self.mDefinitions) do
        local grid = self.mGrids[resourceId]
        if grid then
            local total = 0
            local count = 0
            local maxVal = 0
            local minVal = 1

            for x = 1, self.mGridWidth do
                for y = 1, self.mGridHeight do
                    local val = grid[x][y] or 0
                    total = total + val
                    count = count + 1
                    maxVal = math.max(maxVal, val)
                    if val > 0 then
                        minVal = math.min(minVal, val)
                    end
                end
            end

            local avg = count > 0 and (total / count) or 0
            local deposits = self.mDeposits[resourceId]
            local numDeposits = deposits and #deposits or 0

            print(string.format("%s (%s):", def.name, def.category))
            print(string.format("  Avg: %.3f, Min: %.3f, Max: %.3f", avg, minVal, maxVal))
            if numDeposits > 0 then
                print(string.format("  Deposits: %d", numDeposits))
            end
        end
    end
    print("=====================================")
end

return NaturalResources
