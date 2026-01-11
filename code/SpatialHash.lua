-- SpatialHash.lua
-- Spatial hashing for efficient neighbor queries
-- Used for citizen-to-citizen collision/separation calculations

local SpatialHash = {}
SpatialHash.__index = SpatialHash

-- Create a new spatial hash grid
function SpatialHash:Create(cellSize, worldWidth, worldHeight)
    local hash = setmetatable({}, SpatialHash)

    hash.cellSize = cellSize or 50
    hash.worldWidth = worldWidth
    hash.worldHeight = worldHeight
    hash.gridWidth = math.ceil(worldWidth / hash.cellSize)
    hash.gridHeight = math.ceil(worldHeight / hash.cellSize)
    hash.buckets = {}

    return hash
end

-- Get cell key from world coordinates
function SpatialHash:GetCellKey(x, y)
    local gx = math.floor(x / self.cellSize)
    local gy = math.floor(y / self.cellSize)

    -- Clamp to valid grid bounds
    gx = math.max(0, math.min(self.gridWidth - 1, gx))
    gy = math.max(0, math.min(self.gridHeight - 1, gy))

    return gx * self.gridHeight + gy
end

-- Clear all buckets (call each frame before re-inserting)
function SpatialHash:Clear()
    self.buckets = {}
end

-- Insert an entity at a position
function SpatialHash:Insert(entity, x, y)
    local key = self:GetCellKey(x, y)

    if not self.buckets[key] then
        self.buckets[key] = {}
    end

    table.insert(self.buckets[key], entity)
end

-- Get all entities near a position within a radius
function SpatialHash:GetNearby(x, y, radius)
    local result = {}

    -- Calculate cell range to check
    local cellRadius = math.ceil(radius / self.cellSize)
    local centerGX = math.floor(x / self.cellSize)
    local centerGY = math.floor(y / self.cellSize)

    -- Check all cells within range
    for dx = -cellRadius, cellRadius do
        for dy = -cellRadius, cellRadius do
            local gx = centerGX + dx
            local gy = centerGY + dy

            -- Bounds check
            if gx >= 0 and gx < self.gridWidth and gy >= 0 and gy < self.gridHeight then
                local key = gx * self.gridHeight + gy
                local bucket = self.buckets[key]

                if bucket then
                    for _, entity in ipairs(bucket) do
                        table.insert(result, entity)
                    end
                end
            end
        end
    end

    return result
end

-- Get all entities near a position within a radius, with actual distance filtering
function SpatialHash:GetNearbyFiltered(x, y, radius)
    local result = {}
    local radiusSq = radius * radius

    -- Get all candidates from spatial hash
    local candidates = self:GetNearby(x, y, radius)

    -- Filter by actual distance
    for _, entity in ipairs(candidates) do
        if entity.x and entity.y then
            local dx = entity.x - x
            local dy = entity.y - y
            local distSq = dx * dx + dy * dy

            if distSq <= radiusSq then
                table.insert(result, entity)
            end
        end
    end

    return result
end

-- Count entities in a cell
function SpatialHash:GetCellCount(x, y)
    local key = self:GetCellKey(x, y)
    local bucket = self.buckets[key]
    return bucket and #bucket or 0
end

-- Get total entity count across all buckets
function SpatialHash:GetTotalCount()
    local count = 0
    for _, bucket in pairs(self.buckets) do
        count = count + #bucket
    end
    return count
end

-- Debug: Draw the spatial hash grid
function SpatialHash:DebugDraw(camera)
    if not camera then return end

    love.graphics.setLineWidth(1)

    -- Only draw visible cells
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local startGX = math.max(0, math.floor((camera.x - screenW/2) / self.cellSize))
    local startGY = math.max(0, math.floor((camera.y - screenH/2) / self.cellSize))
    local endGX = math.min(self.gridWidth - 1, math.ceil((camera.x + screenW/2) / self.cellSize))
    local endGY = math.min(self.gridHeight - 1, math.ceil((camera.y + screenH/2) / self.cellSize))

    for gx = startGX, endGX do
        for gy = startGY, endGY do
            local worldX = gx * self.cellSize
            local worldY = gy * self.cellSize
            local key = gx * self.gridHeight + gy
            local bucket = self.buckets[key]
            local count = bucket and #bucket or 0

            -- Color by occupancy
            if count > 0 then
                local intensity = math.min(1, count / 5)
                love.graphics.setColor(0, intensity, 1, 0.3)
                love.graphics.rectangle("fill", worldX, worldY, self.cellSize, self.cellSize)
            end

            -- Grid lines
            love.graphics.setColor(0.3, 0.3, 0.5, 0.3)
            love.graphics.rectangle("line", worldX, worldY, self.cellSize, self.cellSize)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return SpatialHash
