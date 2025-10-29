--
-- River - represents a river flowing through the town with natural curves and width variation
--

River = {}
River.__index = River

function River:Create(params)
    local this = {
        -- River flows from top to bottom with natural curves
        mBaseWidth = params.baseWidth or 180,
        mColor = params.color or {0.2, 0.4, 0.7},
        mBankColor = params.bankColor or {0.3, 0.5, 0.3},
        mBankWidth = 15,
        mPoints = {},  -- Array of {x, y, width, flowSpeed, clarity} points defining the river path
        mSegmentLength = 3,  -- Much smaller segments for smoother curves
        mTime = 0  -- Animation time
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

    -- Draw river banks using triangle strip
    love.graphics.setColor(self.mBankColor[1], self.mBankColor[2], self.mBankColor[3])

    -- Build vertices for triangle strip
    local bankVertices = {}
    for i = 1, #leftBankEdge do
        table.insert(bankVertices, leftBankEdge[i].x)
        table.insert(bankVertices, leftBankEdge[i].y)
        table.insert(bankVertices, rightBankEdge[i].x)
        table.insert(bankVertices, rightBankEdge[i].y)
    end

    -- Draw as triangle strip
    if #bankVertices >= 6 then
        local mesh = love.graphics.newMesh(#bankVertices / 2, "strip", "static")
        for i = 1, #bankVertices / 2 do
            mesh:setVertex(i, bankVertices[i * 2 - 1], bankVertices[i * 2])
        end
        love.graphics.draw(mesh)
    end

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

    -- No highlights needed - keep the water uniform and muddy
    love.graphics.setColor(1, 1, 1)
end
