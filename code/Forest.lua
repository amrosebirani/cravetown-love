--
-- Forest - represents random forest regions with varying tree densities
--

Forest = {}
Forest.__index = Forest

function Forest:Create(params)
    local densityLevels = {"Clear", "Sparse", "Moderate", "Dense"}
    local this = {
        mBoundaryMinX = params.minX or -1250,
        mBoundaryMinY = params.minY or -1250,
        mBoundaryMaxX = params.maxX or 1250,
        mBoundaryMaxY = params.maxY or 1250,
        mRiver = params.river,  -- Reference to river for collision checking
        mRegions = {},  -- Array of forest regions
        mTrees = {},    -- Array of individual trees {x, y, size}
        mDensityStatus = densityLevels[math.random(1, #densityLevels)]  -- Random density level
    }

    setmetatable(this, self)

    -- Generate random forest regions
    this:GenerateForestRegions(params)

    return this
end

function Forest:IsRegionNearRiver(centerX, centerY, radius)
    -- Check if a forest region center is too close to the river
    if not self.mRiver then
        return false
    end

    -- Minimum distance from river center (approximately)
    local minDistanceFromRiver = 250

    -- Simple check: is the region center close to X=0 (river center)?
    -- Since river flows vertically around X=0, avoid regions too close to X=0
    if math.abs(centerX) < minDistanceFromRiver then
        return true
    end

    return false
end

function Forest:GenerateForestRegions(params)
    local numRegions = params.numRegions or math.random(3, 6)

    -- Generate random forest regions
    for i = 1, numRegions do
        local region
        local attempts = 0
        local maxAttempts = 20

        -- Try to generate a region that's not too close to the river
        repeat
            region = {
                -- Random center point within boundaries
                centerX = math.random(self.mBoundaryMinX + 200, self.mBoundaryMaxX - 200),
                centerY = math.random(self.mBoundaryMinY + 200, self.mBoundaryMaxY - 200),
                -- Random size (radius)
                radius = math.random(150, 350),
                -- Random density (trees per unit area)
                density = math.random() * 0.8 + 0.3,  -- 0.3 to 1.1 (higher = denser)
                -- Shape irregularity
                irregularity = math.random() * 0.4 + 0.2  -- 0.2 to 0.6
            }

            attempts = attempts + 1
        until (not self:IsRegionNearRiver(region.centerX, region.centerY, region.radius) or attempts >= maxAttempts)

        -- Only add region if we found a good spot or exhausted attempts
        if attempts < maxAttempts or not self.mRiver then
            table.insert(self.mRegions, region)

            -- Generate trees for this region
            self:GenerateTreesInRegion(region)
        end
    end
end

function Forest:CheckTreeRiverCollision(x, y, size)
    -- Check if a tree at position (x, y) with given size collides with the river
    if not self.mRiver then
        return false
    end

    local riverBounds = self.mRiver:GetBounds()
    local treeRadius = size * 1.5  -- Account for triangle height
    local bufferZone = 25  -- Add significant buffer around river (in pixels)

    for _, riverSegment in ipairs(riverBounds) do
        -- Expand river segment bounds by buffer zone
        local expandedX = riverSegment.x - bufferZone
        local expandedY = riverSegment.y - bufferZone
        local expandedWidth = riverSegment.width + (bufferZone * 2)
        local expandedHeight = riverSegment.height + (bufferZone * 2)

        -- Find closest point on expanded river segment rectangle to tree position
        local closestX = math.max(expandedX, math.min(x, expandedX + expandedWidth))
        local closestY = math.max(expandedY, math.min(y, expandedY + expandedHeight))

        -- Calculate distance from closest point to tree center
        local distX = x - closestX
        local distY = y - closestY
        local distanceSquared = distX * distX + distY * distY

        -- Check if distance is less than tree radius plus buffer
        local totalRadius = treeRadius + bufferZone
        if distanceSquared < (totalRadius * totalRadius) then
            return true
        end
    end

    return false
end

function Forest:GenerateTreesInRegion(region)
    -- Calculate approximate number of trees based on area and density
    local area = math.pi * region.radius * region.radius
    local numTrees = math.floor(area * region.density / 300)  -- Adjust divisor for tree spacing

    -- Use Poisson-like distribution for natural tree placement
    for i = 1, numTrees do
        -- Generate random position within region using rejection sampling
        local maxAttempts = 30
        local attempts = 0
        local treeX, treeY, size

        repeat
            -- Random angle and distance from center
            local angle = math.random() * math.pi * 2
            local distance = math.random() * region.radius

            -- Add irregularity to make region edge less circular
            local irregularityFactor = 1 + (math.random() - 0.5) * region.irregularity
            distance = distance * irregularityFactor

            treeX = region.centerX + math.cos(angle) * distance
            treeY = region.centerY + math.sin(angle) * distance

            -- Calculate tree size for this position
            local distFromCenter = math.sqrt(
                (treeX - region.centerX)^2 + (treeY - region.centerY)^2
            )
            local centeredness = 1 - (distFromCenter / region.radius)
            local baseSize = 8 + math.random() * 7  -- 8 to 15
            size = baseSize * (0.7 + centeredness * 0.5)  -- Larger trees near center

            attempts = attempts + 1
        until (attempts >= maxAttempts or
               (treeX >= self.mBoundaryMinX and treeX <= self.mBoundaryMaxX and
                treeY >= self.mBoundaryMinY and treeY <= self.mBoundaryMaxY and
                not self:CheckTreeRiverCollision(treeX, treeY, size)))

        if attempts < maxAttempts then
            table.insert(self.mTrees, {
                x = treeX,
                y = treeY,
                size = size,
                regionIndex = #self.mRegions
            })
        end
    end
end

function Forest:CheckCollision(building)
    -- Check if building collides with any tree
    local bx, by, bw, bh = building:GetBounds()

    for _, tree in ipairs(self.mTrees) do
        -- Treat tree as a small circle
        local treeRadius = tree.size * 0.8  -- Slightly smaller collision box

        -- Find closest point on rectangle to circle center
        local closestX = math.max(bx, math.min(tree.x, bx + bw))
        local closestY = math.max(by, math.min(tree.y, by + bh))

        -- Calculate distance from closest point to circle center
        local distX = tree.x - closestX
        local distY = tree.y - closestY
        local distanceSquared = distX * distX + distY * distY

        -- Check if distance is less than circle radius
        if distanceSquared < (treeRadius * treeRadius) then
            return true
        end
    end

    return false
end

function Forest:Render()
    -- Draw forest regions (debug - optional, can be removed)
    -- Uncomment to see region boundaries
    --[[
    love.graphics.setColor(0.2, 0.5, 0.2, 0.2)
    for _, region in ipairs(self.mRegions) do
        love.graphics.circle("fill", region.centerX, region.centerY, region.radius)
    end
    ]]

    -- Draw trees as green triangles
    love.graphics.setColor(0.1, 0.5, 0.1, 1)  -- Dark green

    for _, tree in ipairs(self.mTrees) do
        -- Draw triangle pointing up
        local size = tree.size
        local height = size * 1.5  -- Make triangles taller

        -- Triangle vertices (pointing up)
        local vertices = {
            tree.x, tree.y - height,      -- Top point
            tree.x - size, tree.y + size, -- Bottom left
            tree.x + size, tree.y + size  -- Bottom right
        }

        love.graphics.polygon("fill", vertices)

        -- Add a small brown trunk (rectangle)
        love.graphics.setColor(0.4, 0.2, 0.1, 1)  -- Brown
        local trunkWidth = size * 0.3
        local trunkHeight = size * 0.5
        love.graphics.rectangle("fill",
            tree.x - trunkWidth / 2,
            tree.y + size,
            trunkWidth,
            trunkHeight)

        -- Reset to green for next tree
        love.graphics.setColor(0.1, 0.5, 0.1, 1)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function Forest:GetTreeCount()
    return #self.mTrees
end

function Forest:GetRegionCount()
    return #self.mRegions
end
