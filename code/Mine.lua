--
-- Mine - represents mining sites for different ores, which are commodities under CommodityTypes.lua
-- These produce: Coal, Iron Ore, Copper Ore, Gold Ore, Silver Ore, Stone, Marble, Clay, Sand
-- Mines are generated in the Town.lua file, and are used to produce commodities for the Town.
-- Mines are also used to build Buildings, in the "BuildingDefinitions.lua" file.
-- Mines can be depleted over time, and will produce less ore as they are depleted.
-- Mines can be abundant, partial, or depleted.

require("code/CommodityTypes")

Mine = {}
Mine.__index = Mine

-- Define mine types with their associated ores, colors, and size classifications
-- Size determines fixed quantity: large=10 units, medium=5 units, small=3 units
local MINE_TYPES = {
    {ore = "coal", color = {0.1, 0.1, 0.1}, name = "Coal", size = "large"},
    {ore = "ore", color = {0.5, 0.4, 0.3}, name = "Iron Ore", size = "large"},
    {ore = "copper_ore", color = {0.6, 0.4, 0.2}, name = "Copper Ore", size = "medium"},
    {ore = "gold_ore", color = {0.9, 0.8, 0.3}, name = "Gold Ore", size = "small"},
    {ore = "silver_ore", color = {0.7, 0.7, 0.7}, name = "Silver Ore", size = "small"},
    {ore = "stone", color = {0.5, 0.5, 0.5}, name = "Stone", size = "large"},
    {ore = "marble", color = {0.9, 0.9, 0.9}, name = "Marble", size = "small"},
    {ore = "clay", color = {0.6, 0.5, 0.4}, name = "Clay", size = "medium"},
    {ore = "sand", color = {0.8, 0.7, 0.6}, name = "Sand", size = "medium"}
}

-- Helper function to get fixed quantity based on ore size
local function GetOreQuantity(oreSize)
    if oreSize == "large" then
        return 10
    elseif oreSize == "medium" then
        return 5
    elseif oreSize == "small" then
        return 3
    end
    return 0
end

function Mine:Create(params)
    local abundanceLevels = {"Depleted", "Partial", "Abundant"}
    local this = {
        mBoundaryMinX = params.minX or -1250,
        mBoundaryMinY = params.minY or -1250,
        mBoundaryMaxX = params.maxX or 1250,
        mBoundaryMaxY = params.maxY or 1250,
        mRiver = params.river,  -- Reference to river for collision checking
        mForest = params.forest,  -- Reference to forest for collision checking
        mSites = {},  -- Array of mine sites {x, y, size, ore, type}
        mAbundanceStatus = abundanceLevels[math.random(1, #abundanceLevels)]  -- Random abundance level
    }

    setmetatable(this, self)

    -- Generate random mine sites
    this:GenerateMineSites(params)

    return this
end

function Mine:GenerateMineSites(params)
    -- Create at least one mine of each type
    local numMinesPerType = 1  -- Each ore type gets at least one mine
    local totalMines = numMinesPerType * #MINE_TYPES

    for mineTypeIndex, mineType in ipairs(MINE_TYPES) do
        for i = 1, numMinesPerType do
            local attempts = 0
            local maxAttempts = 100  -- Increased from 50
            local mineX, mineY, mineSize
            local found = false

            repeat
                -- Try completely random positions within bounds
                mineX = math.random(self.mBoundaryMinX + 100, self.mBoundaryMaxX - 100)
                mineY = math.random(self.mBoundaryMinY + 100, self.mBoundaryMaxY - 100)

                -- On later attempts, try anywhere on the map
                if attempts > 50 then
                    mineX = math.random(self.mBoundaryMinX + 50, self.mBoundaryMaxX - 50)
                    mineY = math.random(self.mBoundaryMinY + 50, self.mBoundaryMaxY - 50)
                end

                mineSize = math.random(30, 45)

                attempts = attempts + 1

                if self:IsValidMineLocation(mineX, mineY, mineSize) then
                    found = true
                end
            until (attempts >= maxAttempts or found)

            -- Place the mine if we found a valid location
            if found and mineX and mineY and mineSize then
                local quantity = GetOreQuantity(mineType.size)

                table.insert(self.mSites, {
                    x = mineX,
                    y = mineY,
                    size = mineSize,
                    ore = mineType.ore,
                    oreName = mineType.name,
                    color = mineType.color,
                    typeIndex = mineTypeIndex,
                    oreSize = mineType.size,
                    quantity = quantity
                })

                -- Add fixed quantity to town inventory
                if gTown and gTown.mInventory then
                    gTown.mInventory:Add(mineType.ore, quantity)
                end

                print("Mine placed: " .. mineType.name .. " (size: " .. mineType.size .. ", quantity: " .. quantity .. ")")
            else
                print("WARNING: Could not place mine for " .. mineType.name .. " after " .. maxAttempts .. " attempts")
            end
        end
    end
end

function Mine:IsValidMineLocation(x, y, size)
    -- Check if mine is too close to river
    if self.mRiver then
        local riverBounds = self.mRiver:GetBounds()
        local bufferZone = 80  -- Minimum distance from river
        
        for _, riverSegment in ipairs(riverBounds) do
            local expandedX = riverSegment.x - bufferZone
            local expandedY = riverSegment.y - bufferZone
            local expandedWidth = riverSegment.width + (bufferZone * 2)
            local expandedHeight = riverSegment.height + (bufferZone * 2)
            
            if x < expandedX + expandedWidth and
               x + size > expandedX and
               y < expandedY + expandedHeight and
               y + size > expandedY then
                return false
            end
        end
    end
    
    -- Check if mine is too close to forest trees
    if self.mForest and self.mForest.mTrees then
        local forestTrees = self.mForest.mTrees
        local bufferZone = 60
        
        for _, tree in ipairs(forestTrees) do
            -- Ensure tree has valid properties
            if tree and tree.x and tree.y and tree.size then
                local distanceSquared = (x - tree.x)^2 + (y - tree.y)^2
                local treeRadius = tree.size * 1.5
                local totalRadius = treeRadius + bufferZone
                
                if distanceSquared < (totalRadius * totalRadius) then
                    return false
                end
            end
        end
    end
    
    -- Check if mine is too close to other mines
    for _, existingMine in ipairs(self.mSites) do
        -- Ensure existingMine has valid properties
        if existingMine and existingMine.x and existingMine.y and existingMine.size then
            local distanceSquared = (x - existingMine.x)^2 + (y - existingMine.y)^2
            local minDistance = (size + existingMine.size + 40)^2
            
            if distanceSquared < minDistance then
                return false
            end
        end
    end
    
    return true
end

function Mine:CheckCollision(building)
    -- Check if building collides with any mine site
    local bx, by, bw, bh = building:GetBounds()
    
    for _, mine in ipairs(self.mSites) do
        -- Treat mine as a circle
        local mineRadius = mine.size
        
        -- Find closest point on rectangle to circle center
        local closestX = math.max(bx, math.min(mine.x, bx + bw))
        local closestY = math.max(by, math.min(mine.y, by + bh))
        
        -- Calculate distance from closest point to circle center
        local distX = mine.x - closestX
        local distY = mine.y - closestY
        local distanceSquared = distX * distX + distY * distY
        
        -- Check if distance is less than circle radius
        if distanceSquared < (mineRadius * mineRadius) then
            return true
        end
    end
    
    return false
end

function Mine:GetMineAtPosition(x, y)
    -- Find which mine (if any) is at the given position
    for _, mine in ipairs(self.mSites) do
        local distance = math.sqrt((x - mine.x)^2 + (y - mine.y)^2)
        if distance <= mine.size then
            return mine
        end
    end
    return nil
end

function Mine:Render()
    -- Draw each mine site with 3D ore-like appearance
    for _, mine in ipairs(self.mSites) do
        -- Validate mine has all required properties
        if mine and mine.x and mine.y and mine.size and mine.color then
            local x, y = mine.x, mine.y
            local radius = mine.size
            local baseColor = mine.color

            -- Shadow layer (bottom-right)
            love.graphics.setColor(0, 0, 0, 0.4)
            love.graphics.circle("fill", x + 3, y + 3, radius)

            -- Dark base layer
            love.graphics.setColor(baseColor[1] * 0.4, baseColor[2] * 0.4, baseColor[3] * 0.4)
            love.graphics.circle("fill", x, y, radius)

            -- Mid-tone layer (slightly smaller)
            love.graphics.setColor(baseColor[1] * 0.7, baseColor[2] * 0.7, baseColor[3] * 0.7)
            love.graphics.circle("fill", x - 1, y - 1, radius * 0.85)

            -- Main color layer
            love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3])
            love.graphics.circle("fill", x - 2, y - 2, radius * 0.7)

            -- Highlight layer (top-left, small)
            love.graphics.setColor(
                math.min(1, baseColor[1] * 1.5),
                math.min(1, baseColor[2] * 1.5),
                math.min(1, baseColor[3] * 1.5),
                0.8
            )
            love.graphics.circle("fill", x - radius * 0.3, y - radius * 0.3, radius * 0.3)

            -- Smaller bright highlight
            love.graphics.setColor(1, 1, 1, 0.6)
            love.graphics.circle("fill", x - radius * 0.35, y - radius * 0.35, radius * 0.15)

            -- Dark outline
            love.graphics.setColor(0, 0, 0, 0.8)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", x, y, radius)
            love.graphics.setLineWidth(1)
        end
    end

    love.graphics.setColor(1, 1, 1)
end

function Mine:GetSiteCount()
    return #self.mSites
end

-- Commented out: Using fixed quantities instead of time-based production
-- function Mine:Update(dt)
--     -- Mine production happens automatically over time
--     for _, mine in ipairs(self.mSites) do
--         if mine.ore and mine.size then
--             -- Production rate based on mine size and abundance
--             local baseRate = 0.1  -- Ore per second
--             local sizeMultiplier = mine.size / 30  -- Bigger mines produce more
--             local abundanceMultiplier = 1
--
--             if self.mAbundanceStatus == "Abundant" then
--                 abundanceMultiplier = 1.5
--             elseif self.mAbundanceStatus == "Partial" then
--                 abundanceMultiplier = 0.7
--             else  -- Depleted
--                 abundanceMultiplier = 0.2
--             end
--
--             local productionRate = baseRate * sizeMultiplier * abundanceMultiplier
--             local amountProduced = productionRate * dt
--
--             -- Add to town inventory
--             if gTown and gTown.mInventory then
--                 gTown.mInventory:Add(mine.ore, amountProduced)
--             end
--         end
--     end
-- end