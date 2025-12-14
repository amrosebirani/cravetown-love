--
-- Forest - represents random forest regions with varying tree densities
--

Forest = {}
Forest.__index = Forest

function Forest:Create(params)
    local densityLevels = {"Clear", "Sparse", "Moderate", "Dense"}
    local this = {
        mBoundaryMinX = params.minX or 0,
        mBoundaryMinY = params.minY or 0,
        mBoundaryMaxX = params.maxX or 2500,
        mBoundaryMaxY = params.maxY or 2500,
        mRiver = params.river,  -- Reference to river for collision checking
        mRegions = {},  -- Array of forest regions
        mTrees = {},    -- Array of individual trees {x, y, size}
        mDensityStatus = densityLevels[math.random(1, #densityLevels)],  -- Random density level
        -- Store world dimensions for coordinate conversion
        -- River uses centered coords where (0,0) is world center
        mWorldWidth = (params.maxX or 2500) - (params.minX or 0),
        mWorldHeight = (params.maxY or 2500) - (params.minY or 0),
        -- Store zones if provided (zone-based generation)
        mZones = params.zones
    }

    setmetatable(this, self)

    -- Generate forest - either zone-based or random regions
    if params.zones and #params.zones > 0 then
        this:GenerateForestFromZones(params.zones)
    else
        this:GenerateForestRegions(params)
    end

    return this
end

function Forest:WorldToRiverCoords(worldX, worldY)
    -- Convert world coordinates to river-centered coordinates
    -- World coords: (0,0) at top-left, river coords: (0,0) at center
    local riverX = worldX - self.mWorldWidth / 2
    local riverY = worldY - self.mWorldHeight / 2
    return riverX, riverY
end

function Forest:IsRegionNearRiver(centerX, centerY, radius)
    -- Check if a forest region center is too close to the river
    if not self.mRiver then
        return false
    end

    -- Convert region center to river-centered coordinates
    local riverX, riverY = self:WorldToRiverCoords(centerX, centerY)

    -- Use river's GetDistanceToRiver to check proximity
    local distance = self.mRiver:GetDistanceToRiver(riverX, riverY)

    -- Keep regions away from river (region radius + buffer)
    local minDistanceFromRiver = radius + 150  -- Larger buffer zone

    return distance < minDistanceFromRiver
end

-- Generate trees within pre-defined zones (from WorldZones)
function Forest:GenerateForestFromZones(zones)
    print("[Forest] Generating trees within " .. #zones .. " designated zones")

    for i, zone in ipairs(zones) do
        -- Create a region for each zone
        local region = {
            centerX = zone.x + zone.width / 2,
            centerY = zone.y + zone.height / 2,
            -- Use zone dimensions to calculate equivalent radius
            radius = math.min(zone.width, zone.height) / 2,
            density = 0.6 + math.random() * 0.4,  -- 0.6 to 1.0
            irregularity = 0.3,
            -- Store zone bounds for rectangular tree placement
            zoneX = zone.x,
            zoneY = zone.y,
            zoneWidth = zone.width,
            zoneHeight = zone.height
        }

        table.insert(self.mRegions, region)

        -- Generate trees within this zone (rectangular, not circular)
        self:GenerateTreesInZone(region)

        print(string.format("[Forest] Zone %d: (%d,%d) %dx%d - %d trees",
            i, zone.x, zone.y, zone.width, zone.height, #self.mTrees))
    end

    print("[Forest] Total trees generated: " .. #self.mTrees)
end

-- Generate trees within a rectangular zone
function Forest:GenerateTreesInZone(region)
    -- Calculate number of trees based on zone area and density
    local area = region.zoneWidth * region.zoneHeight
    local numTrees = math.floor(area * region.density / 600)  -- More trees per zone

    local padding = 20  -- Keep trees away from zone edges

    for i = 1, numTrees do
        local maxAttempts = 15
        local attempts = 0
        local treeX, treeY, size

        repeat
            -- Random position within zone bounds
            treeX = region.zoneX + padding + math.random() * (region.zoneWidth - padding * 2)
            treeY = region.zoneY + padding + math.random() * (region.zoneHeight - padding * 2)

            -- Calculate tree size
            local baseSize = 8 + math.random() * 7  -- 8 to 15
            -- Add some variation based on distance from center
            local dx = treeX - region.centerX
            local dy = treeY - region.centerY
            local distFromCenter = math.sqrt(dx * dx + dy * dy)
            local maxDist = math.max(region.zoneWidth, region.zoneHeight) / 2
            local centeredness = 1 - math.min(1, distFromCenter / maxDist)
            size = baseSize * (0.7 + centeredness * 0.4)

            attempts = attempts + 1
        until (attempts >= maxAttempts or not self:CheckTreeRiverCollision(treeX, treeY, size))

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

    -- Convert tree world coordinates to river-centered coordinates
    local riverX, riverY = self:WorldToRiverCoords(x, y)

    -- Use river's GetDistanceToRiver for more reliable collision
    local distance = self.mRiver:GetDistanceToRiver(riverX, riverY)

    -- Buffer: tree size + river width margin
    local bufferZone = 80  -- Generous buffer around river
    local checkDistance = size + bufferZone

    return distance < checkDistance
end

function Forest:GenerateTreesInRegion(region)
    -- Calculate approximate number of trees based on area and density
    local area = math.pi * region.radius * region.radius
    local numTrees = math.floor(area * region.density / 800)  -- Higher divisor = fewer trees

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
    return self:CheckRectCollision(bx, by, bw, bh)
end

-- Check if a rectangle collides with any tree
function Forest:CheckRectCollision(bx, by, bw, bh)
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
    -- Draw trees as simple layered triangles (pine tree style)
    for _, tree in ipairs(self.mTrees) do
        local size = tree.size
        local x, y = tree.x, tree.y

        -- Use tree's position to create consistent color variation
        local colorSeed = (tree.x * 7 + tree.y * 13) % 100 / 100
        local greenBase = 0.35 + colorSeed * 0.15  -- 0.35 to 0.50
        local greenVariation = 0.1 + colorSeed * 0.1  -- slight variation

        -- Draw 3 layered triangles for a pine tree look
        -- Bottom layer (largest, darkest)
        love.graphics.setColor(0.1, greenBase - 0.1, 0.1, 1)
        local bottomSize = size * 1.2
        love.graphics.polygon("fill",
            x, y - size * 0.3,
            x - bottomSize, y + size * 0.8,
            x + bottomSize, y + size * 0.8
        )

        -- Middle layer
        love.graphics.setColor(0.12, greenBase, 0.12, 1)
        local midSize = size * 0.9
        love.graphics.polygon("fill",
            x, y - size * 0.8,
            x - midSize, y + size * 0.3,
            x + midSize, y + size * 0.3
        )

        -- Top layer (smallest, brightest)
        love.graphics.setColor(0.15, greenBase + greenVariation, 0.15, 1)
        local topSize = size * 0.6
        love.graphics.polygon("fill",
            x, y - size * 1.3,
            x - topSize, y - size * 0.2,
            x + topSize, y - size * 0.2
        )
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

return Forest
