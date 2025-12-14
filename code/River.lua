--
-- River - represents a river flowing through the town with natural curves and width variation
--

River = {}
River.__index = River

function River:Create(params)
    local flowLevels = {"Dry", "Low Flow", "Mid Flow", "Full Flow"}
    local this = {
        -- River flows from top to bottom with natural curves
        mBaseWidth = params.baseWidth or 180,
        mColor = params.color or {0.2, 0.4, 0.7},
        mBankColor = params.bankColor or {0.25, 0.42, 0.28},  -- Very subtle, close to grass
        mBankWidth = 4,  -- Minimal bank width for subtle edge
        mPoints = {},  -- Array of {x, y, width, flowSpeed, clarity} points defining the river path
        mSegmentLength = 3,  -- Much smaller segments for smoother curves
        mTime = 0,  -- Animation time
        mFlowStatus = flowLevels[math.random(1, #flowLevels)],  -- Random flow level
        -- Lake/reservoir at the end of the river - organic shape
        mLake = nil,  -- Will be set after path generation
        mLakePoints = {}  -- Organic polygon points for the lake
    }

    setmetatable(this, self)

    -- Load water shader
    local shaderCode = love.filesystem.read("shaders/water.glsl")
    this.mWaterShader = love.graphics.newShader(shaderCode)

    -- Generate river path from top to bottom
    this:GeneratePath(params)

    return this
end

-- Catmull-Rom spline interpolation
function River:CatmullRom(p0, p1, p2, p3, t)
    local t2 = t * t
    local t3 = t2 * t

    return {
        x = 0.5 * ((2 * p1.x) +
            (-p0.x + p2.x) * t +
            (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 +
            (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3),
        y = 0.5 * ((2 * p1.y) +
            (-p0.y + p2.y) * t +
            (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 +
            (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3),
        width = 0.5 * ((2 * p1.width) +
            (-p0.width + p2.width) * t +
            (2 * p0.width - 5 * p1.width + 4 * p2.width - p3.width) * t2 +
            (-p0.width + 3 * p1.width - 3 * p2.width + p3.width) * t3),
        flowSpeed = 0.5 * ((2 * p1.flowSpeed) +
            (-p0.flowSpeed + p2.flowSpeed) * t +
            (2 * p0.flowSpeed - 5 * p1.flowSpeed + 4 * p2.flowSpeed - p3.flowSpeed) * t2 +
            (-p0.flowSpeed + 3 * p1.flowSpeed - 3 * p2.flowSpeed + p3.flowSpeed) * t3),
        clarity = 0.5 * ((2 * p1.clarity) +
            (-p0.clarity + p2.clarity) * t +
            (2 * p0.clarity - 5 * p1.clarity + 4 * p2.clarity - p3.clarity) * t2 +
            (-p0.clarity + 3 * p1.clarity - 3 * p2.clarity + p3.clarity) * t3)
    }
end

function River:GeneratePath(params)
    local startY = params.startY or -750
    local endY = params.endY or 750
    local centerX = params.centerX or 0
    local curviness = params.curviness or 120  -- How much the river curves
    local widthVariation = params.widthVariation or 0.4  -- 40% width variation

    -- Use multiple sine waves with different frequencies for natural curves
    local y = startY
    local phase1 = math.random() * math.pi * 2
    local phase2 = math.random() * math.pi * 2
    local phase3 = math.random() * math.pi * 2
    local flowPhase = math.random() * math.pi * 2
    local clarityPhase = math.random() * math.pi * 2

    -- First, generate control points
    local controlPoints = {}
    local controlPointSpacing = 40  -- Larger spacing for control points

    while y <= endY do
        -- Combine multiple sine waves for natural-looking curves
        local wave1 = math.sin(y / 180 + phase1) * curviness
        local wave2 = math.sin(y / 95 + phase2) * (curviness * 0.5)
        local wave3 = math.sin(y / 45 + phase3) * (curviness * 0.25)
        local offset = wave1 + wave2 + wave3

        -- Vary the width naturally using another sine wave
        local widthPhase = y / 130 + phase1
        local widthFactor = 1 + math.sin(widthPhase) * widthVariation
        local width = self.mBaseWidth * widthFactor

        -- Calculate flow speed: faster in narrow sections, slower in wide sections
        -- Also add some random variation
        local speedFromWidth = 2.0 - (widthFactor * 0.8)  -- Narrower = faster
        local speedVariation = math.sin(y / 200 + flowPhase) * 0.3
        local flowSpeed = math.max(0.5, math.min(2.5, speedFromWidth + speedVariation))

        -- Calculate water clarity: varies along the river
        -- Generally muddy with some variation
        local clarityFromSpeed = 0.5 - ((flowSpeed - 0.5) / 2.0) * 0.3  -- Faster = muddier
        local clarityVariation = math.sin(y / 150 + clarityPhase) * 0.15
        local clarity = math.max(0.2, math.min(0.6, clarityFromSpeed + clarityVariation))

        table.insert(controlPoints, {
            x = centerX + offset,
            y = y,
            width = width,
            flowSpeed = flowSpeed,
            clarity = clarity
        })

        y = y + controlPointSpacing
    end

    -- Now interpolate between control points using Catmull-Rom splines
    -- Use more steps for smoother curves
    for i = 1, #controlPoints - 1 do
        local p0 = controlPoints[math.max(1, i - 1)]
        local p1 = controlPoints[i]
        local p2 = controlPoints[i + 1]
        local p3 = controlPoints[math.min(#controlPoints, i + 2)]

        -- Generate interpolated points with smaller segments for smoother curves
        local steps = math.floor(controlPointSpacing / self.mSegmentLength)
        for step = 0, steps - 1 do
            local t = step / steps
            local point = self:CatmullRom(p0, p1, p2, p3, t)
            table.insert(self.mPoints, point)
        end
    end

    -- Add the last control point
    table.insert(self.mPoints, controlPoints[#controlPoints])

    -- Create organic lake at the end of the river
    self:GenerateOrganicLake()
end

-- Generate an organic/natural shaped lake at the end of the river
function River:GenerateOrganicLake()
    local lastPoint = self.mPoints[#self.mPoints]
    if not lastPoint then return end

    -- Lake center is slightly below the last river point
    local lakeBaseRadius = self.mBaseWidth * 1.8
    local lakeCenterX = lastPoint.x
    local lakeCenterY = lastPoint.y + lakeBaseRadius * 0.4

    -- Generate organic lake shape using perlin-like noise
    local numPoints = 24  -- Number of points around the perimeter
    local angleStep = (2 * math.pi) / numPoints

    -- Generate random variation for organic shape
    local seed = lakeCenterX * 1000 + lakeCenterY  -- Pseudo-random seed
    math.randomseed(seed)

    -- Create irregular radii for each point
    local radii = {}
    for i = 1, numPoints do
        -- Base radius with smooth random variation
        local angle = (i - 1) * angleStep
        -- Multiple sine waves for organic shape
        local variation = 0.15 * math.sin(angle * 2 + math.random() * 0.5) +
                          0.1 * math.sin(angle * 3 + math.random() * 0.3) +
                          0.08 * math.sin(angle * 5 + math.random() * 0.2)
        radii[i] = lakeBaseRadius * (0.85 + variation + math.random() * 0.15)
    end

    -- Smooth the radii to avoid sharp transitions
    local smoothedRadii = {}
    for i = 1, numPoints do
        local prev = radii[((i - 2) % numPoints) + 1]
        local curr = radii[i]
        local next = radii[(i % numPoints) + 1]
        smoothedRadii[i] = (prev + curr * 2 + next) / 4
    end

    -- Generate lake boundary points
    self.mLakePoints = {}
    self.mLakeBankPoints = {}

    for i = 1, numPoints do
        local angle = (i - 1) * angleStep
        local radius = smoothedRadii[i]
        local bankRadius = radius + self.mBankWidth

        -- Water edge
        table.insert(self.mLakePoints, {
            x = lakeCenterX + math.cos(angle) * radius,
            y = lakeCenterY + math.sin(angle) * radius
        })

        -- Bank edge
        table.insert(self.mLakeBankPoints, {
            x = lakeCenterX + math.cos(angle) * bankRadius,
            y = lakeCenterY + math.sin(angle) * bankRadius
        })
    end

    -- Store lake info for collision detection
    self.mLake = {
        x = lakeCenterX,
        y = lakeCenterY,
        radius = lakeBaseRadius,
        innerRadius = lakeBaseRadius - self.mBankWidth
    }

    -- Reset random seed
    math.randomseed(os.time())
end

function River:GetBounds()
    -- Return array of bounding boxes for collision detection
    local bounds = {}

    for i = 1, #self.mPoints - 1 do
        local p1 = self.mPoints[i]
        local p2 = self.mPoints[i + 1]

        -- Use the maximum width of the two points for the segment
        local maxWidth = math.max(p1.width, p2.width)

        -- Create a bounding box for this segment
        local minX = math.min(p1.x, p2.x) - maxWidth / 2
        local maxX = math.max(p1.x, p2.x) + maxWidth / 2
        local minY = math.min(p1.y, p2.y)
        local maxY = math.max(p1.y, p2.y)

        table.insert(bounds, {
            x = minX,
            y = minY,
            width = maxX - minX,
            height = maxY - minY
        })
    end

    return bounds
end

function River:CheckCollision(building)
    -- Check if building collides with any river segment
    local bx, by, bw, bh = building:GetBounds()
    local bounds = self:GetBounds()

    for _, riverSegment in ipairs(bounds) do
        -- AABB collision detection
        if bx < riverSegment.x + riverSegment.width and
           bx + bw > riverSegment.x and
           by < riverSegment.y + riverSegment.height and
           by + bh > riverSegment.y then
            return true
        end
    end

    return false
end

-- Check if a point is within a certain distance of the river
-- Returns: isNear (boolean), distance (number or nil)
function River:IsPointNear(x, y, minDistance)
    minDistance = minDistance or 0

    for i = 1, #self.mPoints - 1 do
        local p = self.mPoints[i]
        local nextPoint = self.mPoints[i + 1]

        -- Check if y is between this point and next
        local minY = math.min(p.y, nextPoint.y)
        local maxY = math.max(p.y, nextPoint.y)

        if y >= minY and y <= maxY then
            -- Interpolate the X position of river center at this Y
            local t = (y - p.y) / (nextPoint.y - p.y + 0.001)
            local riverX = p.x + t * (nextPoint.x - p.x)
            local riverWidth = p.width + t * (nextPoint.width - p.width)

            -- Calculate distance from river edge
            local distFromCenter = math.abs(x - riverX)
            local distFromEdge = distFromCenter - (riverWidth / 2)

            -- Check if point is within threshold distance of river
            if distFromEdge < minDistance then
                return true, math.max(0, distFromEdge)
            end
        end
    end

    return false, nil
end

-- Get distance from a point to the nearest river edge
-- Returns distance (positive = outside river, negative = inside river)
function River:GetDistanceToRiver(x, y)
    local minDist = math.huge

    for i = 1, #self.mPoints - 1 do
        local p = self.mPoints[i]
        local nextPoint = self.mPoints[i + 1]

        local minY = math.min(p.y, nextPoint.y)
        local maxY = math.max(p.y, nextPoint.y)

        if y >= minY and y <= maxY then
            local t = (y - p.y) / (nextPoint.y - p.y + 0.001)
            local riverX = p.x + t * (nextPoint.x - p.x)
            local riverWidth = p.width + t * (nextPoint.width - p.width)

            local distFromCenter = math.abs(x - riverX)
            local distFromEdge = distFromCenter - (riverWidth / 2)

            minDist = math.min(minDist, distFromEdge)
        end
    end

    -- Also check distance to lake using polygon-based check
    if self.mLake and self.mLakePoints and #self.mLakePoints > 0 then
        -- First do a quick check with approximate radius
        local dx = x - self.mLake.x
        local dy = y - self.mLake.y
        local distToLakeCenter = math.sqrt(dx * dx + dy * dy)

        -- If close enough to lake, do precise polygon check
        if distToLakeCenter < self.mLake.radius * 1.5 then
            local insideLake = self:IsPointInPolygon(x, y, self.mLakePoints)
            if insideLake then
                minDist = -10  -- Inside the lake
            else
                -- Find distance to nearest lake edge
                local minLakeDist = math.huge
                for i = 1, #self.mLakePoints do
                    local p1 = self.mLakePoints[i]
                    local p2 = self.mLakePoints[(i % #self.mLakePoints) + 1]
                    local dist = self:PointToSegmentDistance(x, y, p1.x, p1.y, p2.x, p2.y)
                    minLakeDist = math.min(minLakeDist, dist)
                end
                minDist = math.min(minDist, minLakeDist)
            end
        end
    end

    return minDist
end

-- Check if a point is inside a polygon (ray casting algorithm)
function River:IsPointInPolygon(x, y, polygon)
    local inside = false
    local j = #polygon

    for i = 1, #polygon do
        local xi, yi = polygon[i].x, polygon[i].y
        local xj, yj = polygon[j].x, polygon[j].y

        if ((yi > y) ~= (yj > y)) and
           (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end

    return inside
end

-- Distance from point to line segment
function River:PointToSegmentDistance(px, py, x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    local lenSq = dx * dx + dy * dy

    if lenSq == 0 then
        -- Segment is a point
        return math.sqrt((px - x1)^2 + (py - y1)^2)
    end

    local t = math.max(0, math.min(1, ((px - x1) * dx + (py - y1) * dy) / lenSq))
    local projX = x1 + t * dx
    local projY = y1 + t * dy

    return math.sqrt((px - projX)^2 + (py - projY)^2)
end

-- Check if a point is inside water (river or lake)
-- Returns true if point is in water
function River:IsPointInWater(x, y)
    return self:GetDistanceToRiver(x, y) < 0
end

-- Check if a point is inside water with buffer (for collision)
-- Returns true if point is too close to water
function River:IsPointNearWater(x, y, buffer)
    buffer = buffer or 20
    local dist = self:GetDistanceToRiver(x, y)
    return dist < buffer
end

function River:Update(dt)
    -- Update animation time
    self.mTime = self.mTime + dt
end

function River:Render()
    -- Build left and right edge vertices for the entire river
    local leftBankEdge = {}
    local rightBankEdge = {}
    local leftWaterEdge = {}
    local rightWaterEdge = {}
    local leftHighlight = {}
    local rightHighlight = {}

    -- First pass: calculate raw normals
    local normals = {}
    for i = 1, #self.mPoints do
        local p = self.mPoints[i]
        local dx, dy, length

        -- Calculate direction for perpendicular offset
        if i == 1 then
            -- First point: use direction to next point
            local pNext = self.mPoints[i + 1]
            dx = pNext.x - p.x
            dy = pNext.y - p.y
        elseif i == #self.mPoints then
            -- Last point: use direction from previous point
            local pPrev = self.mPoints[i - 1]
            dx = p.x - pPrev.x
            dy = p.y - pPrev.y
        else
            -- Middle points: use central difference (average of forward and backward)
            local pPrev = self.mPoints[i - 1]
            local pNext = self.mPoints[i + 1]
            dx = pNext.x - pPrev.x
            dy = pNext.y - pPrev.y
        end

        length = math.sqrt(dx * dx + dy * dy)
        if length > 0 then
            dx = dx / length
            dy = dy / length
        end

        local nx = -dy  -- Perpendicular x (normalized)
        local ny = dx   -- Perpendicular y (normalized)

        normals[i] = {x = nx, y = ny}
    end

    -- Second pass: smooth normals to prevent sharp corners
    local smoothedNormals = {}
    for i = 1, #normals do
        if i == 1 or i == #normals then
            -- Keep endpoints as-is
            smoothedNormals[i] = normals[i]
        else
            -- Average with neighbors for smoother transitions - larger radius for more smoothing
            local smoothRadius = 5
            local sumX, sumY = 0, 0
            local count = 0

            for j = math.max(1, i - smoothRadius), math.min(#normals, i + smoothRadius) do
                sumX = sumX + normals[j].x
                sumY = sumY + normals[j].y
                count = count + 1
            end

            -- Normalize the averaged normal
            local len = math.sqrt(sumX * sumX + sumY * sumY)
            if len > 0 then
                smoothedNormals[i] = {x = sumX / len, y = sumY / len}
            else
                smoothedNormals[i] = normals[i]
            end
        end
    end

    -- Third pass: build edge vertices using smoothed normals
    for i = 1, #self.mPoints do
        local p = self.mPoints[i]
        local nx = smoothedNormals[i].x
        local ny = smoothedNormals[i].y

        -- Calculate edge positions
        local bankHalfWidth = (p.width + self.mBankWidth * 2) / 2
        local waterHalfWidth = p.width / 2
        local highlightWidth = p.width / 3

        -- Bank edges
        table.insert(leftBankEdge, {x = p.x + nx * bankHalfWidth, y = p.y + ny * bankHalfWidth})
        table.insert(rightBankEdge, {x = p.x - nx * bankHalfWidth, y = p.y - ny * bankHalfWidth})

        -- Water edges
        table.insert(leftWaterEdge, {x = p.x + nx * waterHalfWidth, y = p.y + ny * waterHalfWidth})
        table.insert(rightWaterEdge, {x = p.x - nx * waterHalfWidth, y = p.y - ny * waterHalfWidth})

        -- Highlight edges
        table.insert(leftHighlight, {x = p.x + nx * highlightWidth, y = p.y + ny * highlightWidth})
    end

    -- Skip drawing bank - just draw water directly for cleaner look
    -- (Banks were too visible and looked weird)

    -- Draw river water with shader - use average flow direction for entire river
    -- Calculate overall flow direction (top to bottom)
    local totalDx, totalDy = 0, 0
    for i = 1, #self.mPoints - 1 do
        local p1 = self.mPoints[i]
        local p2 = self.mPoints[i + 1]
        totalDx = totalDx + (p2.x - p1.x)
        totalDy = totalDy + (p2.y - p1.y)
    end
    local len = math.sqrt(totalDx * totalDx + totalDy * totalDy)
    if len > 0 then
        totalDx = totalDx / len
        totalDy = totalDy / len
    end

    -- Calculate average flow speed and clarity
    local avgFlowSpeed = 0
    local avgClarity = 0
    for _, p in ipairs(self.mPoints) do
        avgFlowSpeed = avgFlowSpeed + p.flowSpeed
        avgClarity = avgClarity + p.clarity
    end
    avgFlowSpeed = avgFlowSpeed / #self.mPoints
    avgClarity = avgClarity / #self.mPoints

    -- Set shader parameters once for entire river
    self.mWaterShader:send("time", self.mTime)
    self.mWaterShader:send("flowDirection", {totalDx, totalDy})
    self.mWaterShader:send("flowSpeed", avgFlowSpeed * 1.5)
    self.mWaterShader:send("waterColor", self.mColor)
    self.mWaterShader:send("clarity", avgClarity)

    -- Draw entire river with shader applied using triangle strip
    love.graphics.setShader(self.mWaterShader)
    love.graphics.setColor(1, 1, 1)

    -- Build vertices for water triangle strip
    local waterVertices = {}
    for i = 1, #leftWaterEdge do
        table.insert(waterVertices, leftWaterEdge[i].x)
        table.insert(waterVertices, leftWaterEdge[i].y)
        table.insert(waterVertices, rightWaterEdge[i].x)
        table.insert(waterVertices, rightWaterEdge[i].y)
    end

    -- Draw as triangle strip
    if #waterVertices >= 6 then
        local mesh = love.graphics.newMesh(#waterVertices / 2, "strip", "static")
        for i = 1, #waterVertices / 2 do
            mesh:setVertex(i, waterVertices[i * 2 - 1], waterVertices[i * 2])
        end
        love.graphics.draw(mesh)
    end

    -- Reset shader
    love.graphics.setShader()

    -- Draw the organic lake at the end (no bank, just water)
    if self.mLake and self.mLakePoints and #self.mLakePoints >= 3 then
        -- Draw lake water with shader (organic polygon)
        love.graphics.setShader(self.mWaterShader)
        love.graphics.setColor(1, 1, 1)

        local waterVerts = {}
        for _, p in ipairs(self.mLakePoints) do
            table.insert(waterVerts, p.x)
            table.insert(waterVerts, p.y)
        end

        if love.math.isConvex(waterVerts) then
            love.graphics.polygon("fill", waterVerts)
        else
            -- Triangulate for non-convex polygon
            local ok, triangles = pcall(love.math.triangulate, waterVerts)
            if ok and triangles then
                for _, tri in ipairs(triangles) do
                    love.graphics.polygon("fill", tri)
                end
            end
        end

        love.graphics.setShader()
    end

    -- No highlights needed - keep the water uniform and muddy
    love.graphics.setColor(1, 1, 1)
end

return River
