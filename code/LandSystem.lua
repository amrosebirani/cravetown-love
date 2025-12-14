--
-- LandSystem.lua
-- Manages the land plot grid and ownership system
--

local DataLoader = require("code.DataLoader")

local LandSystem = {}
LandSystem.__index = LandSystem

-- Constants
local TOWN_OWNER_ID = "TOWN"

function LandSystem:Create(config)
    local system = setmetatable({}, LandSystem)

    -- Load land config from data
    system.config = system:LoadConfig()

    -- Override with runtime config if provided
    if config then
        if config.worldWidth then system.worldWidth = config.worldWidth end
        if config.worldHeight then system.worldHeight = config.worldHeight end
    end

    -- World dimensions
    system.worldWidth = system.worldWidth or 3200
    system.worldHeight = system.worldHeight or 2400

    -- Grid settings from config
    local gridSettings = system.config.gridSettings or {}
    system.plotWidth = gridSettings.plotWidth or 100
    system.plotHeight = gridSettings.plotHeight or 100

    -- Calculate grid dimensions
    system.gridColumns = math.floor(system.worldWidth / system.plotWidth)
    system.gridRows = math.floor(system.worldHeight / system.plotHeight)

    -- Initialize plot grid
    system.plots = {}
    system.plotsByOwner = {}  -- Quick lookup: ownerId -> {plotId, ...}
    system.plotsByOwner[TOWN_OWNER_ID] = {}

    -- Generate initial plots (all town-owned)
    system:GeneratePlots()

    -- Overlay settings
    system.overlayEnabled = false
    system.overlayConfig = system.config.overlay or {}

    print("[LandSystem] Created with " .. system.gridColumns .. "x" .. system.gridRows .. " plots")

    return system
end

function LandSystem:LoadConfig()
    local filepath = "data/" .. DataLoader.activeVersion .. "/land_config.json"
    print("Loading land config from " .. filepath .. "...")
    local success, data = pcall(function()
        return DataLoader.loadJSON(filepath)
    end)
    if success and data then
        return data
    else
        print("  WARNING: Could not load land config, using defaults")
        return {
            gridSettings = { plotWidth = 100, plotHeight = 100 },
            pricing = { basePlotPrice = 100 },
            rent = { baseRentRate = 0.02 },
            immigrationRequirements = {},
            overlay = {}
        }
    end
end

function LandSystem:GeneratePlots()
    local pricing = self.config.pricing or {}
    local basePlotPrice = pricing.basePlotPrice or 100

    for gx = 0, self.gridColumns - 1 do
        for gy = 0, self.gridRows - 1 do
            local plotId = self:GetPlotId(gx, gy)

            local plot = {
                id = plotId,
                gridX = gx,
                gridY = gy,
                worldX = gx * self.plotWidth,
                worldY = gy * self.plotHeight,
                width = self.plotWidth,
                height = self.plotHeight,

                -- Ownership (all start as town-owned)
                ownerId = TOWN_OWNER_ID,
                purchasePrice = basePlotPrice,
                purchasedCycle = nil,

                -- Value factors
                baseValue = basePlotPrice,
                locationMultiplier = 1.0,
                developmentBonus = 0,

                -- Terrain (default grass, can be modified by world generation)
                terrainType = "grass",
                isBlocked = false,
                naturalResources = {},

                -- Development
                buildings = {}
            }

            self.plots[plotId] = plot
            table.insert(self.plotsByOwner[TOWN_OWNER_ID], plotId)
        end
    end
end

function LandSystem:GetPlotId(gridX, gridY)
    return string.format("plot_%d_%d", gridX, gridY)
end

function LandSystem:GetPlot(gridX, gridY)
    local plotId = self:GetPlotId(gridX, gridY)
    return self.plots[plotId]
end

function LandSystem:GetPlotById(plotId)
    return self.plots[plotId]
end

function LandSystem:GetPlotAtWorld(worldX, worldY)
    local gridX = math.floor(worldX / self.plotWidth)
    local gridY = math.floor(worldY / self.plotHeight)

    if gridX < 0 or gridX >= self.gridColumns or gridY < 0 or gridY >= self.gridRows then
        return nil
    end

    return self:GetPlot(gridX, gridY)
end

function LandSystem:GetPlotOwner(plotId)
    local plot = self.plots[plotId]
    if plot then
        return plot.ownerId
    end
    return nil
end

function LandSystem:GetPlotsOwnedBy(ownerId)
    local result = {}
    local plotIds = self.plotsByOwner[ownerId] or {}
    for _, plotId in ipairs(plotIds) do
        local plot = self.plots[plotId]
        if plot then
            table.insert(result, plot)
        end
    end
    return result
end

function LandSystem:GetTownOwnedPlots()
    return self:GetPlotsOwnedBy(TOWN_OWNER_ID)
end

function LandSystem:GetAvailablePlots()
    -- Available = town-owned and not blocked
    local result = {}
    local townPlots = self:GetTownOwnedPlots()
    for _, plot in ipairs(townPlots) do
        if not plot.isBlocked then
            table.insert(result, plot)
        end
    end
    return result
end

function LandSystem:CalculatePlotPrice(plot)
    local pricing = self.config.pricing or {}
    local basePlotPrice = pricing.basePlotPrice or 100
    local terrainMultipliers = pricing.terrainMultipliers or {}

    local price = basePlotPrice

    -- Location multiplier
    price = price * (plot.locationMultiplier or 1.0)

    -- Terrain multiplier
    local terrainMult = terrainMultipliers[plot.terrainType] or 1.0
    price = price * terrainMult

    -- Natural resources bonus
    if plot.naturalResources and #plot.naturalResources > 0 then
        price = price * (1 + #plot.naturalResources * 0.15)
    end

    -- Development bonus
    price = price * (1 + (plot.developmentBonus or 0))

    return math.floor(price)
end

function LandSystem:TransferOwnership(plotId, newOwnerId, price, currentCycle)
    local plot = self.plots[plotId]
    if not plot then
        return false, "Plot not found"
    end

    local oldOwnerId = plot.ownerId

    -- Remove from old owner's list
    if self.plotsByOwner[oldOwnerId] then
        for i, pid in ipairs(self.plotsByOwner[oldOwnerId]) do
            if pid == plotId then
                table.remove(self.plotsByOwner[oldOwnerId], i)
                break
            end
        end
    end

    -- Add to new owner's list
    if not self.plotsByOwner[newOwnerId] then
        self.plotsByOwner[newOwnerId] = {}
    end
    table.insert(self.plotsByOwner[newOwnerId], plotId)

    -- Update plot
    plot.ownerId = newOwnerId
    plot.purchasePrice = price or plot.purchasePrice
    plot.purchasedCycle = currentCycle

    print(string.format("[LandSystem] Transferred plot %s from %s to %s for %d gold",
        plotId, oldOwnerId or "none", newOwnerId, price or 0))

    return true, oldOwnerId
end

function LandSystem:SetPlotTerrain(plotId, terrainType, isBlocked)
    local plot = self.plots[plotId]
    if plot then
        plot.terrainType = terrainType
        if isBlocked ~= nil then
            plot.isBlocked = isBlocked
        end
        -- Recalculate price
        plot.purchasePrice = self:CalculatePlotPrice(plot)
    end
end

function LandSystem:SetPlotResources(plotId, resources)
    local plot = self.plots[plotId]
    if plot then
        plot.naturalResources = resources or {}
        plot.purchasePrice = self:CalculatePlotPrice(plot)
    end
end

function LandSystem:AddBuildingToPlot(plotId, buildingId)
    local plot = self.plots[plotId]
    if plot then
        table.insert(plot.buildings, buildingId)
        -- Increase development bonus
        plot.developmentBonus = (plot.developmentBonus or 0) + 0.05
        plot.purchasePrice = self:CalculatePlotPrice(plot)
    end
end

function LandSystem:RemoveBuildingFromPlot(plotId, buildingId)
    local plot = self.plots[plotId]
    if plot then
        for i, bid in ipairs(plot.buildings) do
            if bid == buildingId then
                table.remove(plot.buildings, i)
                break
            end
        end
    end
end

function LandSystem:GetPlotsForBuilding(worldX, worldY, buildingWidth, buildingHeight)
    -- Get all plots that a building would occupy
    local plots = {}

    local startGridX = math.floor(worldX / self.plotWidth)
    local startGridY = math.floor(worldY / self.plotHeight)
    local endGridX = math.floor((worldX + buildingWidth - 1) / self.plotWidth)
    local endGridY = math.floor((worldY + buildingHeight - 1) / self.plotHeight)

    for gx = startGridX, endGridX do
        for gy = startGridY, endGridY do
            local plot = self:GetPlot(gx, gy)
            if plot then
                table.insert(plots, plot)
            end
        end
    end

    return plots
end

function LandSystem:CanBuildAt(worldX, worldY, buildingWidth, buildingHeight, builderId)
    -- Check if a builder can place a building at this location
    local plots = self:GetPlotsForBuilding(worldX, worldY, buildingWidth, buildingHeight)

    if #plots == 0 then
        return false, "Outside world bounds"
    end

    local ownedPlots = {}
    local rentedPlots = {}
    local purchasePlots = {}

    for _, plot in ipairs(plots) do
        if plot.isBlocked then
            return false, "Plot is blocked (water/mountain)"
        end

        if plot.ownerId == builderId then
            table.insert(ownedPlots, plot)
        elseif plot.ownerId == TOWN_OWNER_ID then
            table.insert(purchasePlots, plot)
        else
            table.insert(rentedPlots, plot)
        end
    end

    return true, {
        owned = ownedPlots,
        rent = rentedPlots,
        purchase = purchasePlots,
        totalPlots = plots
    }
end

function LandSystem:GetImmigrationLandRequirements(intendedRole)
    local requirements = self.config.immigrationRequirements or {}
    return requirements[intendedRole] or { minPlots = 0, maxPlots = 0, minTotalValue = 0 }
end

function LandSystem:ToggleOverlay()
    self.overlayEnabled = not self.overlayEnabled
    return self.overlayEnabled
end

function LandSystem:SetOverlayEnabled(enabled)
    self.overlayEnabled = enabled
end

function LandSystem:Render(camera)
    if not self.overlayEnabled then return end

    local colors = self.overlayConfig.colors or {}
    local townColor = colors.townOwned or {0.2, 0.4, 0.8, 0.4}
    local citizenColor = colors.citizenOwned or {0.8, 0.6, 0.2, 0.4}
    local gridColor = colors.gridLines or {0.3, 0.3, 0.3, 0.5}

    -- Get visible area from camera
    local camX, camY = camera:GetPosition()
    local zoom = camera:GetZoom()
    local screenW = love.graphics.getWidth() / zoom
    local screenH = love.graphics.getHeight() / zoom

    local startX = math.max(0, math.floor((camX - screenW/2) / self.plotWidth))
    local startY = math.max(0, math.floor((camY - screenH/2) / self.plotHeight))
    local endX = math.min(self.gridColumns - 1, math.ceil((camX + screenW/2) / self.plotWidth))
    local endY = math.min(self.gridRows - 1, math.ceil((camY + screenH/2) / self.plotHeight))

    -- Draw plot ownership colors
    for gx = startX, endX do
        for gy = startY, endY do
            local plot = self:GetPlot(gx, gy)
            if plot then
                local color
                if plot.ownerId == TOWN_OWNER_ID then
                    color = townColor
                else
                    color = citizenColor
                end

                love.graphics.setColor(color[1], color[2], color[3], color[4])
                love.graphics.rectangle("fill", plot.worldX, plot.worldY, self.plotWidth, self.plotHeight)
            end
        end
    end

    -- Draw grid lines
    love.graphics.setColor(gridColor[1], gridColor[2], gridColor[3], gridColor[4])
    love.graphics.setLineWidth(1)

    for gx = startX, endX + 1 do
        local x = gx * self.plotWidth
        love.graphics.line(x, startY * self.plotHeight, x, (endY + 1) * self.plotHeight)
    end

    for gy = startY, endY + 1 do
        local y = gy * self.plotHeight
        love.graphics.line(startX * self.plotWidth, y, (endX + 1) * self.plotWidth, y)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Serialization for save/load
function LandSystem:Serialize()
    local data = {
        worldWidth = self.worldWidth,
        worldHeight = self.worldHeight,
        plotWidth = self.plotWidth,
        plotHeight = self.plotHeight,
        gridColumns = self.gridColumns,
        gridRows = self.gridRows,
        plots = {},
        overlayEnabled = self.overlayEnabled
    }

    -- Only serialize plots that differ from default (not town-owned with no buildings)
    for plotId, plot in pairs(self.plots) do
        if plot.ownerId ~= TOWN_OWNER_ID or #plot.buildings > 0 or plot.developmentBonus > 0 then
            data.plots[plotId] = {
                ownerId = plot.ownerId,
                purchasePrice = plot.purchasePrice,
                purchasedCycle = plot.purchasedCycle,
                developmentBonus = plot.developmentBonus,
                terrainType = plot.terrainType,
                isBlocked = plot.isBlocked,
                naturalResources = plot.naturalResources,
                buildings = plot.buildings
            }
        end
    end

    return data
end

function LandSystem:Deserialize(data)
    if not data then return end

    -- Restore modified plots
    for plotId, plotData in pairs(data.plots or {}) do
        local plot = self.plots[plotId]
        if plot then
            -- Transfer ownership if different from town
            if plotData.ownerId ~= TOWN_OWNER_ID then
                self:TransferOwnership(plotId, plotData.ownerId, plotData.purchasePrice, plotData.purchasedCycle)
            end

            plot.developmentBonus = plotData.developmentBonus or 0
            plot.terrainType = plotData.terrainType or "grass"
            plot.isBlocked = plotData.isBlocked or false
            plot.naturalResources = plotData.naturalResources or {}
            plot.buildings = plotData.buildings or {}
        end
    end

    self.overlayEnabled = data.overlayEnabled or false

    print("[LandSystem] Deserialized land data")
end

-- Static constant accessor
function LandSystem.GetTownOwnerId()
    return TOWN_OWNER_ID
end

return LandSystem
