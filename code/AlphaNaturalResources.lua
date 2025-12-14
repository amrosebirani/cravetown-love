--
-- AlphaNaturalResources.lua
-- Simplified natural resource generation and overlay for Alpha Prototype
-- Provides resource values for building efficiency calculations
--

AlphaNaturalResources = {}
AlphaNaturalResources.__index = AlphaNaturalResources

function AlphaNaturalResources:Create(worldWidth, worldHeight)
    local res = setmetatable({}, AlphaNaturalResources)

    res.worldWidth = worldWidth or 800
    res.worldHeight = worldHeight or 600
    res.cellSize = 20  -- Grid cell size in pixels

    res.cols = math.ceil(res.worldWidth / res.cellSize)
    res.rows = math.ceil(res.worldHeight / res.cellSize)

    -- Resource grids
    res.grids = {}

    -- Resource definitions
    res.resources = {
        fertility = {
            name = "Fertility",
            color = {0.3, 0.7, 0.3},
            opacity = 0.5,
            showThreshold = 0.2
        },
        ground_water = {
            name = "Ground Water",
            color = {0.3, 0.5, 0.8},
            opacity = 0.5,
            showThreshold = 0.2
        },
        iron_ore = {
            name = "Iron Ore",
            color = {0.6, 0.3, 0.2},
            opacity = 0.6,
            showThreshold = 0.3
        },
        copper_ore = {
            name = "Copper Ore",
            color = {0.8, 0.5, 0.2},
            opacity = 0.6,
            showThreshold = 0.3
        },
        coal = {
            name = "Coal",
            color = {0.2, 0.2, 0.2},
            opacity = 0.6,
            showThreshold = 0.3
        }
    }

    -- Overlay visibility state
    res.overlayVisible = false
    res.visibleResources = {
        fertility = true,
        ground_water = true,
        iron_ore = false,
        copper_ore = false,
        coal = false
    }

    -- Generate all resources
    res:GenerateAll()

    return res
end

-- =============================================================================
-- GENERATION
-- =============================================================================

function AlphaNaturalResources:GenerateAll()
    print("AlphaNaturalResources: Generating resource grids...")

    -- Generate continuous resources (Perlin-like noise)
    self.grids.fertility = self:GenerateContinuousResource("fertility", 0.03, 2)
    self.grids.ground_water = self:GenerateContinuousResource("water", 0.025, 3)

    -- Generate discrete deposits
    self.grids.iron_ore = self:GenerateDepositResource("iron", 4, 0.7)
    self.grids.copper_ore = self:GenerateDepositResource("copper", 3, 0.6)
    self.grids.coal = self:GenerateDepositResource("coal", 3, 0.65)

    print("AlphaNaturalResources: Generated " .. self.cols .. "x" .. self.rows .. " grids")
end

function AlphaNaturalResources:GenerateContinuousResource(seed, frequency, hotspots)
    local grid = {}

    -- Seed random based on resource type
    local seedNum = 0
    for i = 1, #seed do
        seedNum = seedNum + seed:byte(i) * i
    end
    math.randomseed(seedNum)

    -- Generate hotspot centers
    local centers = {}
    for i = 1, hotspots do
        table.insert(centers, {
            x = math.random(1, self.cols),
            y = math.random(1, self.rows),
            strength = 0.5 + math.random() * 0.5,
            radius = math.random(5, 15)
        })
    end

    -- Generate grid values
    for row = 1, self.rows do
        grid[row] = {}
        for col = 1, self.cols do
            -- Base noise value
            local noise = self:SimplexNoise2D(col * frequency, row * frequency, seedNum)
            local value = (noise + 1) / 2  -- Normalize to 0-1

            -- Add hotspot influence
            for _, center in ipairs(centers) do
                local dist = math.sqrt((col - center.x)^2 + (row - center.y)^2)
                if dist < center.radius then
                    local influence = (1 - dist / center.radius) * center.strength
                    value = value + influence
                end
            end

            grid[row][col] = math.max(0, math.min(1, value))
        end
    end

    return grid
end

function AlphaNaturalResources:GenerateDepositResource(seed, numDeposits, maxValue)
    local grid = {}

    -- Initialize grid to zero
    for row = 1, self.rows do
        grid[row] = {}
        for col = 1, self.cols do
            grid[row][col] = 0
        end
    end

    -- Seed random
    local seedNum = 0
    for i = 1, #seed do
        seedNum = seedNum + seed:byte(i) * i * 7
    end
    math.randomseed(seedNum)

    -- Generate deposit clusters
    for i = 1, numDeposits do
        local cx = math.random(3, self.cols - 3)
        local cy = math.random(3, self.rows - 3)
        local radius = math.random(2, 5)
        local strength = 0.5 + math.random() * 0.5

        -- Fill deposit area with falloff
        for row = math.max(1, cy - radius), math.min(self.rows, cy + radius) do
            for col = math.max(1, cx - radius), math.min(self.cols, cx + radius) do
                local dist = math.sqrt((col - cx)^2 + (row - cy)^2)
                if dist <= radius then
                    local falloff = 1 - (dist / radius)
                    local value = falloff * strength * maxValue
                    grid[row][col] = math.max(grid[row][col], value)
                end
            end
        end
    end

    return grid
end

-- Simple 2D noise function (simplified Perlin-like)
function AlphaNaturalResources:SimplexNoise2D(x, y, seed)
    local function hash(x, y)
        local n = x + y * 57 + seed
        n = (n * (n * n * 15731 + 789221) + 1376312589) % 2147483648
        return (n / 1073741824) - 1
    end

    local x0 = math.floor(x)
    local y0 = math.floor(y)
    local x1 = x0 + 1
    local y1 = y0 + 1

    local sx = x - x0
    local sy = y - y0

    -- Smoothstep
    local u = sx * sx * (3 - 2 * sx)
    local v = sy * sy * (3 - 2 * sy)

    -- Interpolate
    local n00 = hash(x0, y0)
    local n10 = hash(x1, y0)
    local n01 = hash(x0, y1)
    local n11 = hash(x1, y1)

    local nx0 = n00 * (1 - u) + n10 * u
    local nx1 = n01 * (1 - u) + n11 * u

    return nx0 * (1 - v) + nx1 * v
end

-- =============================================================================
-- VALUE QUERIES
-- =============================================================================

function AlphaNaturalResources:WorldToGrid(worldX, worldY)
    local col = math.floor(worldX / self.cellSize) + 1
    local row = math.floor(worldY / self.cellSize) + 1
    return col, row
end

function AlphaNaturalResources:GetValue(resourceId, worldX, worldY)
    local grid = self.grids[resourceId]
    if not grid then return 0 end

    local col, row = self:WorldToGrid(worldX, worldY)
    if row < 1 or row > self.rows or col < 1 or col > self.cols then
        return 0
    end

    return grid[row][col] or 0
end

function AlphaNaturalResources:GetAverageValue(resourceId, worldX, worldY, width, height)
    local grid = self.grids[resourceId]
    if not grid then return 0 end

    local startCol, startRow = self:WorldToGrid(worldX, worldY)
    local endCol, endRow = self:WorldToGrid(worldX + width, worldY + height)

    local total = 0
    local count = 0

    for row = math.max(1, startRow), math.min(self.rows, endRow) do
        for col = math.max(1, startCol), math.min(self.cols, endCol) do
            total = total + (grid[row][col] or 0)
            count = count + 1
        end
    end

    return count > 0 and (total / count) or 0
end

function AlphaNaturalResources:GetMaxValue(resourceId, worldX, worldY, width, height)
    local grid = self.grids[resourceId]
    if not grid then return 0 end

    local startCol, startRow = self:WorldToGrid(worldX, worldY)
    local endCol, endRow = self:WorldToGrid(worldX + width, worldY + height)

    local maxVal = 0

    for row = math.max(1, startRow), math.min(self.rows, endRow) do
        for col = math.max(1, startCol), math.min(self.cols, endCol) do
            maxVal = math.max(maxVal, grid[row][col] or 0)
        end
    end

    return maxVal
end

-- Get best value from a list of resource types (for "anyOf" constraints)
function AlphaNaturalResources:GetBestOfAny(resourceIds, worldX, worldY, width, height)
    local bestValue = 0
    local bestResource = nil

    for _, resourceId in ipairs(resourceIds) do
        local value = self:GetAverageValue(resourceId, worldX, worldY, width, height)
        if value > bestValue then
            bestValue = value
            bestResource = resourceId
        end
    end

    return bestValue, bestResource
end

-- =============================================================================
-- OVERLAY RENDERING
-- =============================================================================

function AlphaNaturalResources:ToggleOverlay()
    self.overlayVisible = not self.overlayVisible
    return self.overlayVisible
end

function AlphaNaturalResources:SetOverlayVisible(visible)
    self.overlayVisible = visible
end

function AlphaNaturalResources:ToggleResource(resourceId)
    if self.visibleResources[resourceId] ~= nil then
        self.visibleResources[resourceId] = not self.visibleResources[resourceId]
    end
end

function AlphaNaturalResources:RenderOverlay(offsetX, offsetY, viewWidth, viewHeight, cameraX, cameraY)
    if not self.overlayVisible then return end

    -- When called with camera 0,0, we're inside a graphics transform
    -- Just render all cells using world coordinates directly
    -- The scissor/clipping will handle visibility

    -- Render each visible resource
    for resourceId, visible in pairs(self.visibleResources) do
        if visible and self.grids[resourceId] and self.resources[resourceId] then
            local res = self.resources[resourceId]
            local grid = self.grids[resourceId]

            for row = 1, self.rows do
                for col = 1, self.cols do
                    local value = grid[row] and grid[row][col] or 0
                    if value >= res.showThreshold then
                        -- World coordinates: (col-1)*cellSize, (row-1)*cellSize
                        local x = (col - 1) * self.cellSize
                        local y = (row - 1) * self.cellSize

                        local alpha = value * res.opacity
                        love.graphics.setColor(res.color[1], res.color[2], res.color[3], alpha)
                        love.graphics.rectangle("fill", x, y, self.cellSize, self.cellSize)
                    end
                end
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function AlphaNaturalResources:RenderOverlayPanel(x, y, fonts)
    if not self.overlayVisible then return end

    local panelWidth = 150
    local panelHeight = 20 + 20 * 5  -- Header + resources

    -- Background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", x, y, panelWidth, panelHeight, 4, 4)

    -- Border
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("line", x, y, panelWidth, panelHeight, 4, 4)

    -- Title
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Resource Overlays", x + 8, y + 4)

    -- Resource toggles
    local ry = y + 22
    for resourceId, res in pairs(self.resources) do
        local visible = self.visibleResources[resourceId]

        -- Checkbox
        love.graphics.setColor(0.3, 0.3, 0.35)
        love.graphics.rectangle("fill", x + 8, ry + 2, 12, 12, 2, 2)

        if visible then
            love.graphics.setColor(res.color[1], res.color[2], res.color[3])
            love.graphics.rectangle("fill", x + 10, ry + 4, 8, 8, 1, 1)
        end

        -- Color swatch
        love.graphics.setColor(res.color[1], res.color[2], res.color[3])
        love.graphics.rectangle("fill", x + 24, ry + 2, 12, 12, 2, 2)

        -- Label
        love.graphics.setColor(visible and {1, 1, 1} or {0.5, 0.5, 0.5})
        love.graphics.print(res.name, x + 42, ry + 1)

        ry = ry + 18
    end

    love.graphics.setColor(1, 1, 1)
end

-- Handle click on overlay panel (returns true if handled)
function AlphaNaturalResources:HandleOverlayPanelClick(clickX, clickY, panelX, panelY)
    if not self.overlayVisible then return false end

    local panelWidth = 150

    -- Check if click is within panel
    if clickX < panelX or clickX > panelX + panelWidth then return false end

    -- Check resource toggles
    local ry = panelY + 22
    for resourceId, _ in pairs(self.resources) do
        if clickY >= ry and clickY < ry + 18 then
            self:ToggleResource(resourceId)
            return true
        end
        ry = ry + 18
    end

    return false
end

return AlphaNaturalResources
