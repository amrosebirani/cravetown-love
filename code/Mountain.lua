--
-- Mountain - represents mountain ranges at the edges and top of the town map
-- Each mountain provides a specific type of berry
--

require("code/CommodityTypes")

Mountain = {}
Mountain.__index = Mountain

-- Define mountain types with their associated berries and colors
local MOUNTAIN_TYPES = {
    {berry = "health_berry", color = {0.4, 0.7, 0.4}, name = "Health Berry Mountain"},
    {berry = "taste_berry", color = {0.8, 0.5, 0.3}, name = "Taste Berry Mountain"},
    {berry = "happy_berry", color = {0.9, 0.7, 0.2}, name = "Happy Berry Mountain"},
    {berry = "power_berry", color = {0.6, 0.3, 0.7}, name = "Power Berry Mountain"}
}

function Mountain:Create(params)
    local this = {
        mBoundaryMinX = params.minX or -1250,
        mBoundaryMinY = params.minY or -1250,
        mBoundaryMaxX = params.maxX or 1250,
        mBoundaryMaxY = params.maxY or 1250,
        mRiver = params.river,  -- Reference to river for collision checking
        mForest = params.forest,  -- Reference to forest for collision checking
        mMines = params.mines,  -- Reference to mines for collision checking
        mInventory = params.inventory,  -- Reference to inventory
        mRanges = {}  -- Array of mountain ranges {x, y, width, height, berry, berryName, color}
    }

    setmetatable(this, self)

    -- Generate mountain ranges at edges and top
    this:GenerateMountainRanges(params)

    return this
end

function Mountain:IsValidMountainLocation(x, y, width, height)
    -- Check if mountain range collides with rivers
    if self.mRiver then
        local riverBounds = self.mRiver:GetBounds()
        local bufferZone = 100  -- Minimum distance from river

        for _, riverSegment in ipairs(riverBounds) do
            local expandedX = riverSegment.x - bufferZone
            local expandedY = riverSegment.y - bufferZone
            local expandedWidth = riverSegment.width + (bufferZone * 2)
            local expandedHeight = riverSegment.height + (bufferZone * 2)

            -- Check rectangle-rectangle collision
            if x < expandedX + expandedWidth and
               x + width > expandedX and
               y < expandedY + expandedHeight and
               y + height > expandedY then
                return false
            end
        end
    end

    -- Check if mountain collides with forest trees
    if self.mForest and self.mForest.mTrees then
        local bufferZone = 80
        for _, tree in ipairs(self.mForest.mTrees) do
            if tree and tree.x and tree.y and tree.size then
                -- Check if tree is inside or near mountain range
                local treeRadius = tree.size + bufferZone
                -- Check if circle (tree) intersects with rectangle (mountain)
                local closestX = math.max(x, math.min(tree.x, x + width))
                local closestY = math.max(y, math.min(tree.y, y + height))
                local distX = tree.x - closestX
                local distY = tree.y - closestY
                local distanceSquared = distX * distX + distY * distY

                if distanceSquared < (treeRadius * treeRadius) then
                    return false
                end
            end
        end
    end

    -- Check if mountain collides with mine sites
    if self.mMines and self.mMines.mSites then
        local bufferZone = 80
        for _, mine in ipairs(self.mMines.mSites) do
            if mine and mine.x and mine.y and mine.size then
                local mineRadius = mine.size + bufferZone
                -- Check if circle (mine) intersects with rectangle (mountain)
                local closestX = math.max(x, math.min(mine.x, x + width))
                local closestY = math.max(y, math.min(mine.y, y + height))
                local distX = mine.x - closestX
                local distY = mine.y - closestY
                local distanceSquared = distX * distX + distY * distY

                if distanceSquared < (mineRadius * mineRadius) then
                    return false
                end
            end
        end
    end

    return true
end

function Mountain:GenerateMountainRanges(params)
    -- Create 4 mountain ranges, one for each berry type
    -- Place in 4 corners to avoid collisions

    -- Fixed corner positions - smaller mountains that won't collide
    local cornerPositions = {
        -- Top-left corner
        {x = self.mBoundaryMinX + 20, y = self.mBoundaryMinY + 20, width = 180, height = 150},
        -- Top-right corner
        {x = self.mBoundaryMaxX - 200, y = self.mBoundaryMinY + 20, width = 180, height = 150},
        -- Bottom-left corner
        {x = self.mBoundaryMinX + 20, y = self.mBoundaryMaxY - 170, width = 180, height = 150},
        -- Bottom-right corner
        {x = self.mBoundaryMaxX - 200, y = self.mBoundaryMaxY - 170, width = 180, height = 150}
    }

    for i, mountainType in ipairs(MOUNTAIN_TYPES) do
        local pos = cornerPositions[i]

        if pos then
            local range = {
                x = pos.x,
                y = pos.y,
                width = pos.width,
                height = pos.height,
                berry = mountainType.berry,
                berryName = mountainType.name,
                color = mountainType.color,
                quantity = 5  -- Each mountain provides 5 berries
            }

            table.insert(self.mRanges, range)

            -- Add fixed quantity to inventory
            if self.mInventory then
                self.mInventory:Add(mountainType.berry, 5)
                print("Mountain placed: " .. mountainType.name .. " at corner " .. i .. " - Added 5 " .. mountainType.berry)
            else
                print("WARNING: Mountain created but no inventory reference - berries not added!")
            end
        end
    end
end

function Mountain:CheckCollision(building)
    -- Check if building collides with any mountain range
    local bx, by, bw, bh = building:GetBounds()

    for _, range in ipairs(self.mRanges) do
        -- Check rectangle-rectangle collision
        if bx < range.x + range.width and
           bx + bw > range.x and
           by < range.y + range.height and
           by + bh > range.y then
            return true
        end
    end

    return false
end

function Mountain:GetMountainAtPosition(x, y)
    -- Find which mountain (if any) is at the given position
    for _, range in ipairs(self.mRanges) do
        if x >= range.x and x <= range.x + range.width and
           y >= range.y and y <= range.y + range.height then
            return range
        end
    end
    return nil
end

function Mountain:Render()
    -- Draw each mountain range
    for _, range in ipairs(self.mRanges) do
        if range and range.x and range.y and range.width and range.height and range.color then
            local baseY = range.y + range.height
            local numPeaks = math.max(3, math.floor(range.width / 120))

            -- Generate mountain silhouette points
            local points = {}

            -- Start at bottom left
            table.insert(points, range.x)
            table.insert(points, baseY)

            -- Create jagged mountain peaks across the width
            for i = 0, numPeaks do
                local progress = i / numPeaks
                local baseX = range.x + (progress * range.width)

                -- Add some randomness to peak positions (deterministic based on position)
                local seed = math.floor(baseX + range.y)
                math.randomseed(seed)
                local xOffset = (math.random() - 0.5) * 30
                local peakX = baseX + xOffset

                -- Vary peak heights
                local peakHeightRatio = 0.4 + (math.random() * 0.4)  -- 40-80% of range height
                local peakY = range.y + (range.height * (1 - peakHeightRatio))

                -- Add intermediate point going up
                if i > 0 then
                    local midX = (points[#points-1] + peakX) / 2
                    local midY = (points[#points] + peakY) / 2 + (math.random() * 20 - 10)
                    table.insert(points, midX)
                    table.insert(points, midY)
                end

                -- Add peak point
                table.insert(points, peakX)
                table.insert(points, peakY)
            end

            -- End at bottom right
            table.insert(points, range.x + range.width)
            table.insert(points, baseY)

            -- Reset random seed
            math.randomseed(os.time())

            -- Draw mountain silhouette with base color
            love.graphics.setColor(range.color[1], range.color[2], range.color[3], 0.8)
            love.graphics.polygon("fill", points)

            -- Draw darker peaks overlay for depth
            love.graphics.setColor(range.color[1] * 0.7, range.color[2] * 0.7, range.color[3] * 0.7, 0.9)
            for i = 0, numPeaks do
                local progress = i / numPeaks
                local baseX = range.x + (progress * range.width)

                local seed = math.floor(baseX + range.y)
                math.randomseed(seed)
                local xOffset = (math.random() - 0.5) * 30
                local peakX = baseX + xOffset
                local peakHeightRatio = 0.4 + (math.random() * 0.4)
                local peakY = range.y + (range.height * (1 - peakHeightRatio))

                -- Draw individual peak triangle
                local peakWidth = 50 + (math.random() * 40)
                love.graphics.polygon("fill",
                    peakX, peakY,
                    peakX - peakWidth/2, baseY,
                    peakX + peakWidth/2, baseY
                )
            end
            math.randomseed(os.time())

            -- Draw outline
            love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
            love.graphics.setLineWidth(2)
            love.graphics.polygon("line", points)
            love.graphics.setLineWidth(1)

            -- Draw berry name in center
            if range.berryName then
                local font = love.graphics.getFont()
                local textWidth = font:getWidth(range.berryName)
                local textHeight = font:getHeight()
                local centerX = range.x + range.width/2
                local centerY = range.y + range.height * 0.7  -- Lower in the mountain

                -- Draw background behind text for readability
                local padding = 6
                love.graphics.setColor(0, 0, 0, 0.8)
                love.graphics.rectangle("fill",
                    centerX - textWidth/2 - padding,
                    centerY - textHeight/2 - padding,
                    textWidth + padding*2,
                    textHeight + padding*2,
                    3, 3)

                -- Draw the berry name
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(range.berryName, centerX - textWidth/2, centerY - textHeight/2)
            end
        end
    end

    love.graphics.setColor(1, 1, 1)
end

function Mountain:GetRangeCount()
    return #self.mRanges
end
