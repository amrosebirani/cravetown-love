-- NavigationGrid.lua
-- Grid-based walkability map for A* pathfinding
-- Cell size: 20 pixels (matches citizen collision check of 20x20)

local NavigationGrid = {}
NavigationGrid.__index = NavigationGrid

-- Create a new navigation grid for the given world
function NavigationGrid:Create(world)
    local grid = setmetatable({}, NavigationGrid)

    -- Cell size should match or exceed the collision check size in CharacterMovement
    -- CharacterMovement uses a 20x20 collision check area
    grid.cellSize = 20
    grid.worldWidth = world.worldWidth
    grid.worldHeight = world.worldHeight
    grid.gridWidth = math.ceil(world.worldWidth / grid.cellSize)
    grid.gridHeight = math.ceil(world.worldHeight / grid.cellSize)

    -- Walkability grid: 0 = blocked, 1 = walkable
    -- Using flat array for cache efficiency: [gx * gridHeight + gy]
    grid.walkable = {}

    -- Reference to world for collision queries
    grid.world = world

    -- Track if grid needs regeneration
    grid.dirty = true

    return grid
end

-- Convert world coordinates to grid coordinates
function NavigationGrid:WorldToGrid(worldX, worldY)
    local gx = math.floor(worldX / self.cellSize)
    local gy = math.floor(worldY / self.cellSize)
    return gx, gy
end

-- Convert grid coordinates to world coordinates (center of cell)
function NavigationGrid:GridToWorld(gx, gy)
    local worldX = gx * self.cellSize + self.cellSize / 2
    local worldY = gy * self.cellSize + self.cellSize / 2
    return worldX, worldY
end

-- Get flat array index from grid coordinates
function NavigationGrid:GetIndex(gx, gy)
    return gx * self.gridHeight + gy
end

-- Check if grid coordinates are valid
function NavigationGrid:IsValidCell(gx, gy)
    return gx >= 0 and gx < self.gridWidth and gy >= 0 and gy < self.gridHeight
end

-- Check if a cell is walkable
function NavigationGrid:IsWalkable(gx, gy)
    if not self:IsValidCell(gx, gy) then
        return false
    end
    local index = self:GetIndex(gx, gy)
    return self.walkable[index] == 1
end

-- Check if a world position is blocked by any obstacle
function NavigationGrid:IsCellBlocked(worldX, worldY)
    local world = self.world
    local halfCell = self.cellSize / 2

    -- World boundaries (with buffer)
    if worldX < halfCell or worldY < halfCell or
       worldX > world.worldWidth - halfCell or
       worldY > world.worldHeight - halfCell then
        return true
    end

    -- River collision (use buffer for safe pathfinding)
    if world.river then
        -- River uses coordinates relative to world center
        local riverX = worldX - world.worldWidth / 2
        local riverY = worldY - world.worldHeight / 2

        -- Check if point is in or near water
        local distance = world.river:GetDistanceToRiver(riverX, riverY)
        if distance and distance < 20 then
            return true
        end
    end

    -- Forest collision (check cell-sized area with buffer for safe pathfinding)
    -- Add extra buffer to ensure citizens don't clip trees when following paths
    local obstacleBuffer = 5
    if world.forest then
        if world.forest:CheckRectCollision(
            worldX - halfCell - obstacleBuffer, worldY - halfCell - obstacleBuffer,
            self.cellSize + obstacleBuffer * 2, self.cellSize + obstacleBuffer * 2
        ) then
            return true
        end
    end

    -- Mountain collision (with buffer)
    if world.mountains then
        if world.mountains:CheckRectCollision(
            worldX - halfCell - obstacleBuffer, worldY - halfCell - obstacleBuffer,
            self.cellSize + obstacleBuffer * 2, self.cellSize + obstacleBuffer * 2
        ) then
            return true
        end
    end

    return false
end

-- Generate the walkability grid from world obstacles
function NavigationGrid:Generate()
    local startTime = love.timer.getTime()

    for gx = 0, self.gridWidth - 1 do
        for gy = 0, self.gridHeight - 1 do
            local index = self:GetIndex(gx, gy)
            local worldX, worldY = self:GridToWorld(gx, gy)

            local blocked = self:IsCellBlocked(worldX, worldY)
            self.walkable[index] = blocked and 0 or 1
        end
    end

    self.dirty = false

    local elapsed = love.timer.getTime() - startTime
    print(string.format("[NavigationGrid] Generated %dx%d grid (%d cells) in %.3fs",
        self.gridWidth, self.gridHeight, self.gridWidth * self.gridHeight, elapsed))
end

-- Mark a rectangular area as blocked or unblocked (for buildings)
function NavigationGrid:MarkBuildingArea(x, y, width, height, blocked)
    local startGX = math.floor(x / self.cellSize)
    local startGY = math.floor(y / self.cellSize)
    local endGX = math.ceil((x + width) / self.cellSize)
    local endGY = math.ceil((y + height) / self.cellSize)

    for gx = startGX, endGX do
        for gy = startGY, endGY do
            if self:IsValidCell(gx, gy) then
                local index = self:GetIndex(gx, gy)
                self.walkable[index] = blocked and 0 or 1
            end
        end
    end
end

-- Find the nearest walkable cell to a given grid position
function NavigationGrid:FindNearestWalkable(gx, gy, maxRadius)
    maxRadius = maxRadius or 20

    -- If already walkable, return it
    if self:IsWalkable(gx, gy) then
        return gx, gy
    end

    -- Spiral outward search
    for radius = 1, maxRadius do
        for dx = -radius, radius do
            for dy = -radius, radius do
                -- Only check cells on the current ring perimeter
                if math.abs(dx) == radius or math.abs(dy) == radius then
                    local checkGX = gx + dx
                    local checkGY = gy + dy
                    if self:IsWalkable(checkGX, checkGY) then
                        return checkGX, checkGY
                    end
                end
            end
        end
    end

    return nil, nil  -- No walkable cell found
end

-- Get walkable neighbors of a cell (for pathfinding)
function NavigationGrid:GetWalkableNeighbors(gx, gy)
    local neighbors = {}

    -- 8-directional neighbors
    local directions = {
        {dx = 1, dy = 0},   -- Right
        {dx = -1, dy = 0},  -- Left
        {dx = 0, dy = 1},   -- Down
        {dx = 0, dy = -1},  -- Up
        {dx = 1, dy = 1},   -- Diagonal
        {dx = -1, dy = 1},
        {dx = 1, dy = -1},
        {dx = -1, dy = -1}
    }

    for _, dir in ipairs(directions) do
        local nx = gx + dir.dx
        local ny = gy + dir.dy

        if self:IsWalkable(nx, ny) then
            -- For diagonal movement, ensure we don't cut corners
            if dir.dx ~= 0 and dir.dy ~= 0 then
                if self:IsWalkable(gx + dir.dx, gy) and self:IsWalkable(gx, gy + dir.dy) then
                    table.insert(neighbors, {gx = nx, gy = ny, diagonal = true})
                end
            else
                table.insert(neighbors, {gx = nx, gy = ny, diagonal = false})
            end
        end
    end

    return neighbors
end

-- Debug: Draw the navigation grid
function NavigationGrid:DebugDraw(camera)
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

            if self:IsWalkable(gx, gy) then
                love.graphics.setColor(0, 1, 0, 0.1)
            else
                love.graphics.setColor(1, 0, 0, 0.3)
            end

            love.graphics.rectangle("fill", worldX, worldY, self.cellSize, self.cellSize)
            love.graphics.setColor(0.5, 0.5, 0.5, 0.2)
            love.graphics.rectangle("line", worldX, worldY, self.cellSize, self.cellSize)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return NavigationGrid
