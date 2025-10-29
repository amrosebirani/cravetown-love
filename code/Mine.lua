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

-- Define mine types with their associated ores and colors
local MINE_TYPES = {
    {ore = "coal", color = {0.1, 0.1, 0.1}, name = "Coal"},
    {ore = "ore", color = {0.5, 0.4, 0.3}, name = "Iron Ore"},
    {ore = "copper_ore", color = {0.6, 0.4, 0.2}, name = "Copper Ore"},
    {ore = "gold_ore", color = {0.9, 0.8, 0.3}, name = "Gold Ore"},
    {ore = "silver_ore", color = {0.7, 0.7, 0.7}, name = "Silver Ore"},
    {ore = "stone", color = {0.5, 0.5, 0.5}, name = "Stone"},
    {ore = "marble", color = {0.9, 0.9, 0.9}, name = "Marble"},
    {ore = "clay", color = {0.6, 0.5, 0.4}, name = "Clay"},
    {ore = "sand", color = {0.8, 0.7, 0.6}, name = "Sand"}
}

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
            local maxAttempts = 50
            local mineX, mineY, mineSize
            local found = false
            
            repeat
                mineX = math.random(self.mBoundaryMinX + 100, self.mBoundaryMaxX - 100)
                mineY = math.random(self.mBoundaryMinY + 100, self.mBoundaryMaxY - 100)
                
                -- Prefer positions near river or forest but not too close
                if math.random() > 0.3 then  -- 70% chance to be near features
                    if math.random() > 0.5 then
                        -- Try to be near river (around X=0)
                        mineX = math.random(-200, 200)
                    else
                        -- Try to be near forest edges
                        mineX = math.random() > 0.5 and math.random(-400, -250) or math.random(250, 400)
                    end
                end
                
                mineSize = math.random(30, 45)
                
                attempts = attempts + 1
                
                if self:IsValidMineLocation(mineX, mineY, mineSize) then
                    found = true
                end
            until (attempts >= maxAttempts or found)
            
            -- Place the mine if we found a valid location
            if found and mineX and mineY and mineSize then
                table.insert(self.mSites, {
                    x = mineX,
                    y = mineY,
                    size = mineSize,
                    ore = mineType.ore,
                    oreName = mineType.name,
                    color = mineType.color,
                    typeIndex = mineTypeIndex
                })
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
    -- Draw each mine site as a circle
    for _, mine in ipairs(self.mSites) do
        -- Validate mine has all required properties
        if mine and mine.x and mine.y and mine.size and mine.color then
            -- Draw the mine circle with its color
            love.graphics.setColor(mine.color[1], mine.color[2], mine.color[3])
            love.graphics.circle("fill", mine.x, mine.y, mine.size)
            
            -- Draw border
            love.graphics.setColor(0, 0, 0)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", mine.x, mine.y, mine.size)
            love.graphics.setLineWidth(1)
            
            -- Draw full ore name in center
            if mine.oreName then
                local font = love.graphics.getFont()
                local textWidth = font:getWidth(mine.oreName)
                local textHeight = font:getHeight()
                
                -- Draw background behind text for readability
                local padding = 4
                love.graphics.setColor(0, 0, 0, 0.7)
                love.graphics.rectangle("fill", 
                    mine.x - textWidth/2 - padding, 
                    mine.y - textHeight/2 - padding, 
                    textWidth + padding*2, 
                    textHeight + padding*2)
                
                -- Draw the ore name
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(mine.oreName, mine.x - textWidth/2, mine.y - textHeight/2)
            end
        end
    end
    
    love.graphics.setColor(1, 1, 1)
end

function Mine:GetSiteCount()
    return #self.mSites
end

function Mine:Update(dt)
    -- Mine production happens automatically over time
    for _, mine in ipairs(self.mSites) do
        if mine.ore and mine.size then
            -- Production rate based on mine size and abundance
            local baseRate = 0.1  -- Ore per second
            local sizeMultiplier = mine.size / 30  -- Bigger mines produce more
            local abundanceMultiplier = 1
            
            if self.mAbundanceStatus == "Abundant" then
                abundanceMultiplier = 1.5
            elseif self.mAbundanceStatus == "Partial" then
                abundanceMultiplier = 0.7
            else  -- Depleted
                abundanceMultiplier = 0.2
            end
            
            local productionRate = baseRate * sizeMultiplier * abundanceMultiplier
            local amountProduced = productionRate * dt
            
            -- Add to town inventory
            if gTown and gTown.mInventory then
                gTown.mInventory:Add(mine.ore, amountProduced)
            end
        end
    end
end