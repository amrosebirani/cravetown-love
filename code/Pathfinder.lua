-- Pathfinder.lua
-- A* pathfinding implementation with 8-way movement
-- Uses binary heap for efficient open set operations

local Pathfinder = {}
Pathfinder.__index = Pathfinder

-- 8-directional movement with costs
local DIRECTIONS = {
    {dx = 1, dy = 0, cost = 1.0},      -- Right
    {dx = -1, dy = 0, cost = 1.0},     -- Left
    {dx = 0, dy = 1, cost = 1.0},      -- Down
    {dx = 0, dy = -1, cost = 1.0},     -- Up
    {dx = 1, dy = 1, cost = 1.414},    -- Diagonal SE
    {dx = -1, dy = 1, cost = 1.414},   -- Diagonal SW
    {dx = 1, dy = -1, cost = 1.414},   -- Diagonal NE
    {dx = -1, dy = -1, cost = 1.414}   -- Diagonal NW
}

-- ============================================================================
-- Binary Heap (Min-Heap) for open set
-- ============================================================================

local BinaryHeap = {}
BinaryHeap.__index = BinaryHeap

function BinaryHeap.new()
    return setmetatable({
        data = {},      -- Array of {index, priority}
        lookup = {}     -- index -> position in data array
    }, BinaryHeap)
end

function BinaryHeap:Push(index, priority)
    local pos = #self.data + 1
    self.data[pos] = {index = index, priority = priority}
    self.lookup[index] = pos
    self:BubbleUp(pos)
end

function BinaryHeap:Pop()
    if #self.data == 0 then return nil end

    local top = self.data[1]
    self.lookup[top.index] = nil

    local last = table.remove(self.data)
    if #self.data > 0 then
        self.data[1] = last
        self.lookup[last.index] = 1
        self:BubbleDown(1)
    end

    return top.index
end

function BinaryHeap:Update(index, priority)
    local pos = self.lookup[index]
    if not pos then return end

    local oldPriority = self.data[pos].priority
    self.data[pos].priority = priority

    if priority < oldPriority then
        self:BubbleUp(pos)
    else
        self:BubbleDown(pos)
    end
end

function BinaryHeap:Contains(index)
    return self.lookup[index] ~= nil
end

function BinaryHeap:IsEmpty()
    return #self.data == 0
end

function BinaryHeap:BubbleUp(pos)
    while pos > 1 do
        local parent = math.floor(pos / 2)
        if self.data[pos].priority < self.data[parent].priority then
            self:Swap(pos, parent)
            pos = parent
        else
            break
        end
    end
end

function BinaryHeap:BubbleDown(pos)
    local size = #self.data
    while true do
        local left = pos * 2
        local right = pos * 2 + 1
        local smallest = pos

        if left <= size and self.data[left].priority < self.data[smallest].priority then
            smallest = left
        end
        if right <= size and self.data[right].priority < self.data[smallest].priority then
            smallest = right
        end

        if smallest ~= pos then
            self:Swap(pos, smallest)
            pos = smallest
        else
            break
        end
    end
end

function BinaryHeap:Swap(i, j)
    self.data[i], self.data[j] = self.data[j], self.data[i]
    self.lookup[self.data[i].index] = i
    self.lookup[self.data[j].index] = j
end

-- ============================================================================
-- Pathfinder
-- ============================================================================

function Pathfinder:Create(navigationGrid)
    local pf = setmetatable({}, Pathfinder)
    pf.grid = navigationGrid
    pf.maxIterations = 2000  -- Prevent infinite loops on large maps
    return pf
end

-- Octile distance heuristic (optimal for 8-way movement)
function Pathfinder:Heuristic(x1, y1, x2, y2)
    local dx = math.abs(x2 - x1)
    local dy = math.abs(y2 - y1)
    return math.max(dx, dy) + (1.414 - 1) * math.min(dx, dy)
end

-- Main pathfinding function
-- Returns array of {x, y} waypoints in world coordinates, or nil if no path
function Pathfinder:FindPath(startX, startY, endX, endY)
    local grid = self.grid

    -- Convert world coords to grid coords
    local startGX, startGY = grid:WorldToGrid(startX, startY)
    local endGX, endGY = grid:WorldToGrid(endX, endY)

    -- Bounds check
    if not grid:IsValidCell(startGX, startGY) or not grid:IsValidCell(endGX, endGY) then
        return nil
    end

    -- If start is blocked, find nearest walkable
    if not grid:IsWalkable(startGX, startGY) then
        local newGX, newGY = grid:FindNearestWalkable(startGX, startGY, 10)
        if newGX then
            startGX, startGY = newGX, newGY
        else
            return nil  -- Can't find walkable start
        end
    end

    -- If destination is blocked, find nearest walkable
    if not grid:IsWalkable(endGX, endGY) then
        local newGX, newGY = grid:FindNearestWalkable(endGX, endGY, 10)
        if newGX then
            endGX, endGY = newGX, newGY
        else
            return nil  -- Can't find walkable destination
        end
    end

    -- Early out: already at destination
    if startGX == endGX and startGY == endGY then
        local wx, wy = grid:GridToWorld(endGX, endGY)
        return {{x = wx, y = wy}}
    end

    -- A* algorithm
    local openSet = BinaryHeap.new()
    local closedSet = {}
    local cameFrom = {}
    local gScore = {}
    local fScore = {}

    local startIndex = grid:GetIndex(startGX, startGY)
    local endIndex = grid:GetIndex(endGX, endGY)

    gScore[startIndex] = 0
    fScore[startIndex] = self:Heuristic(startGX, startGY, endGX, endGY)
    openSet:Push(startIndex, fScore[startIndex])

    local iterations = 0

    while not openSet:IsEmpty() and iterations < self.maxIterations do
        iterations = iterations + 1

        local currentIndex = openSet:Pop()
        local currentGX = math.floor(currentIndex / grid.gridHeight)
        local currentGY = currentIndex % grid.gridHeight

        -- Reached destination
        if currentIndex == endIndex then
            return self:ReconstructPath(cameFrom, currentIndex, grid, endX, endY)
        end

        closedSet[currentIndex] = true

        -- Explore neighbors
        for _, dir in ipairs(DIRECTIONS) do
            local neighborGX = currentGX + dir.dx
            local neighborGY = currentGY + dir.dy

            if grid:IsValidCell(neighborGX, neighborGY) and grid:IsWalkable(neighborGX, neighborGY) then
                local neighborIndex = grid:GetIndex(neighborGX, neighborGY)

                if not closedSet[neighborIndex] then
                    -- For diagonal movement, ensure we don't cut corners
                    local canMove = true
                    if dir.dx ~= 0 and dir.dy ~= 0 then
                        if not grid:IsWalkable(currentGX + dir.dx, currentGY) or
                           not grid:IsWalkable(currentGX, currentGY + dir.dy) then
                            canMove = false
                        end
                    end

                    if canMove then
                        local tentativeG = gScore[currentIndex] + dir.cost

                        if not gScore[neighborIndex] or tentativeG < gScore[neighborIndex] then
                            cameFrom[neighborIndex] = currentIndex
                            gScore[neighborIndex] = tentativeG
                            fScore[neighborIndex] = tentativeG + self:Heuristic(neighborGX, neighborGY, endGX, endGY)

                            if not openSet:Contains(neighborIndex) then
                                openSet:Push(neighborIndex, fScore[neighborIndex])
                            else
                                openSet:Update(neighborIndex, fScore[neighborIndex])
                            end
                        end
                    end
                end
            end
        end
    end

    return nil  -- No path found
end

-- Reconstruct path from cameFrom map
function Pathfinder:ReconstructPath(cameFrom, currentIndex, grid, finalX, finalY)
    local path = {}

    while currentIndex do
        local gx = math.floor(currentIndex / grid.gridHeight)
        local gy = currentIndex % grid.gridHeight
        local worldX, worldY = grid:GridToWorld(gx, gy)

        table.insert(path, 1, {x = worldX, y = worldY})
        currentIndex = cameFrom[currentIndex]
    end

    -- Replace final waypoint with exact destination
    if #path > 0 then
        path[#path] = {x = finalX, y = finalY}
    end

    -- Simplify path by removing redundant waypoints
    path = self:SimplifyPath(path, grid)

    return path
end

-- Remove waypoints that can be skipped (line-of-sight optimization)
function Pathfinder:SimplifyPath(path, grid)
    if #path <= 2 then
        return path
    end

    local simplified = {path[1]}
    local currentIndex = 1

    while currentIndex < #path do
        local farthest = currentIndex + 1

        -- Find farthest point we can see in line-of-sight
        for i = currentIndex + 2, #path do
            if self:HasLineOfSight(path[currentIndex], path[i], grid) then
                farthest = i
            else
                break
            end
        end

        table.insert(simplified, path[farthest])
        currentIndex = farthest
    end

    return simplified
end

-- Check if there's a clear line of sight between two points
function Pathfinder:HasLineOfSight(from, to, grid)
    local fromGX, fromGY = grid:WorldToGrid(from.x, from.y)
    local toGX, toGY = grid:WorldToGrid(to.x, to.y)

    -- Bresenham's line algorithm
    local dx = math.abs(toGX - fromGX)
    local dy = math.abs(toGY - fromGY)
    local sx = fromGX < toGX and 1 or -1
    local sy = fromGY < toGY and 1 or -1
    local err = dx - dy

    local x, y = fromGX, fromGY

    while true do
        if not grid:IsWalkable(x, y) then
            return false
        end

        if x == toGX and y == toGY then
            break
        end

        local e2 = 2 * err
        if e2 > -dy then
            err = err - dy
            x = x + sx
        end
        if e2 < dx then
            err = err + dx
            y = y + sy
        end
    end

    return true
end

-- Debug: Draw a path
function Pathfinder:DebugDrawPath(path)
    if not path or #path < 2 then return end

    love.graphics.setColor(0, 1, 1, 0.8)
    love.graphics.setLineWidth(2)

    for i = 1, #path - 1 do
        love.graphics.line(path[i].x, path[i].y, path[i+1].x, path[i+1].y)
    end

    -- Draw waypoints
    love.graphics.setColor(1, 1, 0, 1)
    for _, waypoint in ipairs(path) do
        love.graphics.circle("fill", waypoint.x, waypoint.y, 4)
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

return Pathfinder
