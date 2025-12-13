--
-- LandOverlay.lua
-- Toggle-able overlay showing land ownership, grid lines, and plot information
--
-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │                           LAND OWNERSHIP OVERLAY                           │
-- ├────────────────────────────────────────────────────────────────────────────┤
-- │                                                                            │
-- │   ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐                               │
-- │   │▓▓▓│▓▓▓│▓▓▓│   │   │░░░│░░░│≈≈≈│≈≈≈│≈≈≈│                               │
-- │   │T  │T  │T  │   │   │C1 │C1 │   │   │   │  T = Town-owned (blue)        │
-- │   ├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤  C1 = Citizen 1 (green)       │
-- │   │▓▓▓│▓▓▓│   │   │   │░░░│░░░│░░░│≈≈≈│≈≈≈│  ≈ = Water (blocked)          │
-- │   │T  │T  │   │   │   │C1 │C1 │C1 │   │   │  ♦ = Mountain (blocked)       │
-- │   ├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤  ▒ = For Sale (yellow)        │
-- │   │▒▒▒│▒▒▒│   │   │   │░░░│   │   │♦♦♦│♦♦♦│                               │
-- │   │$  │$  │   │   │   │C1 │   │   │   │   │  Hover shows: price, terrain,  │
-- │   ├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤              owner, resources  │
-- │   │   │   │░░░│░░░│   │   │   │   │♦♦♦│♦♦♦│                               │
-- │   │   │   │C2 │C2 │   │   │   │   │   │   │                               │
-- │   └───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘                               │
-- │                                                                            │
-- │   ┌─────────────────────────────────────────┐                             │
-- │   │ Plot (5, 3)                             │  <- Hover tooltip           │
-- │   │ Owner: Town                             │                             │
-- │   │ Terrain: Grass                          │                             │
-- │   │ Price: 120 gold                         │                             │
-- │   │ Resources: Iron ore                     │                             │
-- │   └─────────────────────────────────────────┘                             │
-- │                                                                            │
-- │   Toggle: [L] key    Legend: [SHIFT+L]                                    │
-- └────────────────────────────────────────────────────────────────────────────┘
--
-- COLORS:
--   Blue (#4a90d9) = Town-owned plots
--   Green (#52c41a) = Citizen-owned (varies by citizen for multi-owner view)
--   Yellow (#faad14) = For sale plots
--   Dark (#333333) = Blocked terrain
--   Grid lines = Semi-transparent gray
--

local LandOverlay = {}
LandOverlay.__index = LandOverlay

function LandOverlay:Create(world)
    local overlay = setmetatable({}, LandOverlay)

    overlay.world = world
    overlay.enabled = false
    overlay.showLegend = false
    overlay.hoverPlot = nil
    overlay.hoverX = 0
    overlay.hoverY = 0

    -- Colors (matching info-system LandConfigManager defaults)
    overlay.colors = {
        townOwned = {0.29, 0.56, 0.85, 0.5},     -- #4a90d9
        citizenOwned = {0.32, 0.77, 0.10, 0.5},  -- #52c41a
        forSale = {0.98, 0.68, 0.08, 0.5},       -- #faad14
        blocked = {0.2, 0.2, 0.2, 0.4},
        water = {0.2, 0.3, 0.6, 0.5},
        mountain = {0.4, 0.35, 0.3, 0.5},
        gridLines = {0.27, 0.27, 0.27, 0.4},     -- #444444 with 40% opacity
        hoverHighlight = {1, 1, 1, 0.3},
        tooltipBg = {0.1, 0.1, 0.12, 0.95},
        tooltipBorder = {0.4, 0.5, 0.6, 1},
        text = {1, 1, 1, 1},
        textDim = {0.7, 0.7, 0.7, 1},
    }

    -- Citizen color palette for multi-owner distinction
    overlay.citizenColors = {
        {0.32, 0.77, 0.10, 0.5},  -- Green
        {0.90, 0.49, 0.13, 0.5},  -- Orange
        {0.45, 0.31, 0.59, 0.5},  -- Purple
        {0.20, 0.60, 0.86, 0.5},  -- Sky blue
        {0.83, 0.33, 0.33, 0.5},  -- Red
        {0.94, 0.76, 0.06, 0.5},  -- Gold
        {0.26, 0.63, 0.28, 0.5},  -- Dark green
        {0.61, 0.35, 0.71, 0.5},  -- Violet
    }

    -- Fonts (will be set on first render if needed)
    overlay.fonts = nil

    return overlay
end

function LandOverlay:InitFonts()
    if not self.fonts then
        self.fonts = {
            normal = love.graphics.newFont(12),
            small = love.graphics.newFont(10),
            tiny = love.graphics.newFont(9),
        }
    end
end

function LandOverlay:Toggle()
    self.enabled = not self.enabled
    return self.enabled
end

function LandOverlay:ToggleLegend()
    self.showLegend = not self.showLegend
end

function LandOverlay:IsEnabled()
    return self.enabled
end

function LandOverlay:GetCitizenColor(citizenId)
    if not citizenId then return self.colors.townOwned end

    -- Handle both numeric and string citizen IDs
    local numericId
    if type(citizenId) == "number" then
        numericId = citizenId
    elseif type(citizenId) == "string" then
        -- Try to extract number from string like "citizen_1" or hash the string
        local num = citizenId:match("(%d+)")
        if num then
            numericId = tonumber(num)
        else
            -- Hash the string to get a consistent number
            numericId = 0
            for i = 1, #citizenId do
                numericId = numericId + citizenId:byte(i)
            end
        end
    else
        return self.colors.townOwned
    end

    -- Use consistent color based on citizen ID hash
    local colorIndex = (numericId % #self.citizenColors) + 1
    return self.citizenColors[colorIndex]
end

function LandOverlay:Render(camera)
    if not self.enabled then return end

    self:InitFonts()

    local landSystem = self.world.landSystem
    if not landSystem then return end

    local plotWidth = landSystem.plotWidth or 100
    local plotHeight = landSystem.plotHeight or 100

    -- Calculate visible range based on camera
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local camX, camY = camera:GetPosition()
    local camScale = camera:GetScale()

    -- Get the world view offset (accounts for UI panels)
    -- AlphaUI uses top-left corner camera coordinates
    local worldViewX = camera.leftPanelWidth or 200
    local worldViewY = camera.topBarHeight or 50
    local worldViewW = screenW - worldViewX - (camera.rightPanelWidth or 280)
    local worldViewH = screenH - worldViewY - (camera.eventLogHeight or 140)

    -- Calculate world coordinates of visible area
    -- Camera position is top-left corner of the world view
    local worldLeft = camX
    local worldTop = camY
    local worldRight = camX + worldViewW / camScale
    local worldBottom = camY + worldViewH / camScale

    -- Calculate grid range to render
    local startGridX = math.max(0, math.floor(worldLeft / plotWidth))
    local startGridY = math.max(0, math.floor(worldTop / plotHeight))
    local endGridX = math.min((landSystem.gridColumns or 32) - 1, math.ceil(worldRight / plotWidth))
    local endGridY = math.min((landSystem.gridRows or 24) - 1, math.ceil(worldBottom / plotHeight))

    -- Render plot overlays
    for gx = startGridX, endGridX do
        for gy = startGridY, endGridY do
            local plotId = landSystem:GetPlotId(gx, gy)
            local plot = landSystem.plots and landSystem.plots[plotId]

            if plot then
                -- Convert world position to screen position
                local screenX = worldViewX + (gx * plotWidth - camX) * camScale
                local screenY = worldViewY + (gy * plotHeight - camY) * camScale
                local screenPW = plotWidth * camScale
                local screenPH = plotHeight * camScale

                -- Determine plot color
                local color = self:GetPlotColor(plot)

                -- Draw plot fill
                love.graphics.setColor(color)
                love.graphics.rectangle("fill", screenX, screenY, screenPW, screenPH)

                -- Hover highlight
                if self.hoverPlot and self.hoverPlot.id == plotId then
                    love.graphics.setColor(self.colors.hoverHighlight)
                    love.graphics.rectangle("fill", screenX, screenY, screenPW, screenPH)
                end

                -- Grid lines
                love.graphics.setColor(self.colors.gridLines)
                love.graphics.rectangle("line", screenX, screenY, screenPW, screenPH)

                -- Owner indicator (if zoomed in enough)
                if screenPW > 30 and plot.ownerId then
                    love.graphics.setFont(self.fonts.tiny)
                    if plot.ownerId == "town" or plot.ownerId == 0 then
                        love.graphics.setColor(0.4, 0.6, 0.9)
                        love.graphics.print("T", screenX + 3, screenY + 2)
                    else
                        love.graphics.setColor(0.5, 0.8, 0.5)
                        love.graphics.print("C", screenX + 3, screenY + 2)
                    end
                end
            end
        end
    end

    -- Render hover tooltip
    if self.hoverPlot then
        self:RenderTooltip()
    end

    -- Render legend
    if self.showLegend then
        self:RenderLegend()
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function LandOverlay:GetPlotColor(plot)
    -- Blocked terrain
    if plot.isBlocked then
        if plot.terrainType == "water" then
            return self.colors.water
        elseif plot.terrainType == "mountain" then
            return self.colors.mountain
        else
            return self.colors.blocked
        end
    end

    -- For sale
    if plot.forSale then
        return self.colors.forSale
    end

    -- Owned by citizen
    if plot.ownerId and plot.ownerId ~= "town" and plot.ownerId ~= 0 then
        return self:GetCitizenColor(plot.ownerId)
    end

    -- Town-owned (default)
    return self.colors.townOwned
end

function LandOverlay:RenderTooltip()
    if not self.hoverPlot then return end

    local plot = self.hoverPlot
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Tooltip dimensions
    local tooltipW = 200
    local tooltipH = 100
    local padding = 10

    -- Position tooltip near mouse but keep on screen
    local tooltipX = math.min(self.hoverX + 15, screenW - tooltipW - 10)
    local tooltipY = math.min(self.hoverY + 15, screenH - tooltipH - 10)

    -- Background
    love.graphics.setColor(self.colors.tooltipBg)
    love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipW, tooltipH, 4, 4)

    -- Border
    love.graphics.setColor(self.colors.tooltipBorder)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", tooltipX, tooltipY, tooltipW, tooltipH, 4, 4)

    -- Content
    local y = tooltipY + padding

    -- Plot coordinates
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print(string.format("Plot (%d, %d)", plot.gridX or 0, plot.gridY or 0), tooltipX + padding, y)
    y = y + 16

    -- Owner
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    local ownerText = "Owner: "
    if not plot.ownerId or plot.ownerId == "town" or plot.ownerId == 0 then
        ownerText = ownerText .. "Town"
    else
        -- Try to get citizen name
        local citizen = self.world.characters and self.world.characters[plot.ownerId]
        ownerText = ownerText .. (citizen and citizen.name or ("Citizen #" .. plot.ownerId))
    end
    love.graphics.print(ownerText, tooltipX + padding, y)
    y = y + 14

    -- Terrain
    love.graphics.print("Terrain: " .. (plot.terrainType or "Grass"), tooltipX + padding, y)
    y = y + 14

    -- Price
    love.graphics.setColor(0.98, 0.85, 0.37)  -- Gold color
    love.graphics.print("Price: " .. (plot.purchasePrice or 100) .. " gold", tooltipX + padding, y)
    y = y + 14

    -- Resources
    if plot.naturalResources and #plot.naturalResources > 0 then
        love.graphics.setColor(0.5, 0.8, 0.5)
        love.graphics.print("Resources: " .. table.concat(plot.naturalResources, ", "), tooltipX + padding, y)
    end
end

function LandOverlay:RenderLegend()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Legend dimensions
    local legendW = 180
    local legendH = 160
    local padding = 10
    local legendX = screenW - legendW - 20
    local legendY = 60

    -- Background
    love.graphics.setColor(self.colors.tooltipBg)
    love.graphics.rectangle("fill", legendX, legendY, legendW, legendH, 4, 4)

    -- Border
    love.graphics.setColor(self.colors.tooltipBorder)
    love.graphics.rectangle("line", legendX, legendY, legendW, legendH, 4, 4)

    -- Title
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Land Overlay Legend", legendX + padding, legendY + padding)

    local y = legendY + padding + 20
    local boxSize = 14
    local items = {
        {color = self.colors.townOwned, label = "Town-owned"},
        {color = self.colors.citizenOwned, label = "Citizen-owned"},
        {color = self.colors.forSale, label = "For Sale"},
        {color = self.colors.water, label = "Water (blocked)"},
        {color = self.colors.mountain, label = "Mountain (blocked)"},
    }

    love.graphics.setFont(self.fonts.small)
    for _, item in ipairs(items) do
        -- Color box
        love.graphics.setColor(item.color)
        love.graphics.rectangle("fill", legendX + padding, y, boxSize, boxSize)
        love.graphics.setColor(self.colors.gridLines)
        love.graphics.rectangle("line", legendX + padding, y, boxSize, boxSize)

        -- Label
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print(item.label, legendX + padding + boxSize + 8, y + 1)

        y = y + 20
    end

    -- Controls hint
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("[L] Toggle overlay", legendX + padding, legendY + legendH - 25)
    love.graphics.print("[SHIFT+L] Toggle legend", legendX + padding, legendY + legendH - 13)
end

function LandOverlay:UpdateHover(screenX, screenY, camera)
    if not self.enabled then
        self.hoverPlot = nil
        return
    end

    local landSystem = self.world.landSystem
    if not landSystem then
        self.hoverPlot = nil
        return
    end

    self.hoverX = screenX
    self.hoverY = screenY

    -- Convert screen to world coordinates
    -- AlphaUI uses top-left corner camera coordinates
    local camX, camY = camera:GetPosition()
    local camScale = camera:GetScale()

    -- Get world view offset
    local worldViewX = camera.leftPanelWidth or 200
    local worldViewY = camera.topBarHeight or 50

    -- Convert screen position to world position
    local worldX = (screenX - worldViewX) / camScale + camX
    local worldY = (screenY - worldViewY) / camScale + camY

    -- Find plot at this position
    local plotWidth = landSystem.plotWidth or 100
    local plotHeight = landSystem.plotHeight or 100

    local gridX = math.floor(worldX / plotWidth)
    local gridY = math.floor(worldY / plotHeight)

    -- Bounds check
    if gridX < 0 or gridY < 0 or
       gridX >= (landSystem.gridColumns or 32) or
       gridY >= (landSystem.gridRows or 24) then
        self.hoverPlot = nil
        return
    end

    local plotId = landSystem:GetPlotId(gridX, gridY)
    self.hoverPlot = landSystem.plots and landSystem.plots[plotId]
end

function LandOverlay:HandleKeyPress(key, isShiftHeld)
    if key == "l" then
        if isShiftHeld then
            self:ToggleLegend()
        else
            self:Toggle()
        end
        return true
    end
    return false
end

return LandOverlay
