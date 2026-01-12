--
-- DebugPanel.lua
-- Toggleable debug panel for viewing game metrics, character data, and system status
-- Created for CRAVE-6: [B] Debug Panel Foundation
--
-- Features:
-- - Tab-based interface (Overview, Citizens, Buildings, Economy, Events)
-- - Developer vs Expert Player View modes
-- - Draggable and collapsible panel
-- - Real-time metrics from ProductionStats, AlphaWorld.stats, CharacterV3
--
-- Hotkey: F12 to toggle
--

local DebugPanel = {}
DebugPanel.__index = DebugPanel

function DebugPanel:Create(world)
    local panel = setmetatable({}, DebugPanel)

    panel.world = world
    panel.visible = false
    panel.collapsed = false  -- Start expanded to show tabs
    panel.currentTab = "overview"  -- "overview", "citizens", "buildings", "economy", "events"

    -- Panel position and dimensions
    panel.x = love.graphics.getWidth() - 520  -- Right side of screen
    panel.y = 50  -- Below top bar
    panel.width = 500
    panel.height = math.min(850, love.graphics.getHeight() - 80)  -- Adaptive height, larger
    panel.collapsedHeight = 45

    -- No dragging (fixed modal)
    panel.isDragging = false
    panel.dragOffsetX = 0
    panel.dragOffsetY = 0

    -- Scrolling state
    panel.scrollOffset = 0
    panel.maxScroll = 0

    -- Colors
    panel.colors = {
        background = {0.12, 0.12, 0.15, 0.98},
        headerBg = {0.15, 0.18, 0.22, 1},
        border = {0.3, 0.5, 0.7, 1},
        tabActive = {0.3, 0.5, 0.7, 1},
        tabInactive = {0.2, 0.25, 0.3, 0.8},
        text = {1, 1, 1, 1},
        textDim = {0.7, 0.7, 0.7, 1},
        textMuted = {0.5, 0.5, 0.5, 1},
        success = {0.4, 0.8, 0.4, 1},
        warning = {0.9, 0.8, 0.3, 1},
        error = {0.9, 0.4, 0.4, 1},
        info = {0.4, 0.6, 0.9, 1},
    }

    -- Tab definitions (using ASCII-safe icons)
    -- Note: Citizens tab removed - use the dedicated Citizens Panel instead
    panel.tabs = {
        {id = "overview", label = "Overview", icon = "[O]"},
        {id = "cravings", label = "Cravings", icon = "[R]"},
        {id = "buildings", label = "Buildings", icon = "[B]"},
        {id = "economy", label = "Economy", icon = "[E]"},
        {id = "events", label = "Events", icon = "[L]"}
    }

    -- Buildings tab state
    panel.buildingFilter = "all"  -- "all", "producing", "idle", "no_materials", "no_worker"
    panel.selectedBuilding = nil
    panel.buildingTypeFilter = "all"  -- "all" or specific type

    -- Cravings tab state
    panel.selectedFineDimension = nil  -- Selected fine dimension index
    panel.cravingsClassFilter = "all"  -- "all", "elite", "upper", "middle", "lower"
    panel.cravingsDimensionPickerOpen = false  -- Whether dimension picker dropdown is open
    panel.cravingsCoarseFilter = "all"  -- Filter dimensions in picker by coarse parent

    -- Economy tab state (CRAVE-19: Economy Flow Visualization)
    panel.economyFilter = "active"  -- "active", "top20", "all"
    panel.economyFilterDropdownOpen = false
    panel.economyCache = {
        lastRefreshCycle = 0,
        filteredCommodities = {},
        sankeyData = {
            production = {},   -- {commodityId, rate, category}
            consumption = {},  -- {commodityId, rate, category}
            totalStock = 0,
            totalProduction = 0,
            totalConsumption = 0
        },
        commodityDetails = {}, -- sorted array of {id, prodRate, consRate, stock, delta, trend}
        sparklineData = {}     -- commodityId -> {values}
    }

    -- Category colors for Sankey diagram
    panel.categoryColors = {
        biological = {0.4, 0.7, 0.3, 1},      -- Green
        touch = {0.3, 0.5, 0.8, 1},           -- Blue
        safety = {0.8, 0.6, 0.2, 1},          -- Orange
        psychological = {0.7, 0.4, 0.7, 1},   -- Purple
        social_status = {0.8, 0.7, 0.3, 1},   -- Gold
        social_connection = {0.5, 0.7, 0.8, 1}, -- Cyan
        exotic_goods = {0.9, 0.4, 0.4, 1},    -- Red
        shiny_objects = {0.9, 0.8, 0.3, 1},   -- Yellow
        vice = {0.5, 0.3, 0.5, 1},            -- Dark purple
        utility = {0.5, 0.5, 0.5, 1},         -- Gray
        default = {0.6, 0.6, 0.6, 1}          -- Light gray
    }

    -- Fonts (initialized on first render)
    panel.fonts = nil

    -- Buttons for click handling
    panel.buttons = {}

    return panel
end

function DebugPanel:InitFonts()
    if not self.fonts then
        self.fonts = {
            title = love.graphics.newFont(14),
            header = love.graphics.newFont(12),
            normal = love.graphics.newFont(11),
            small = love.graphics.newFont(10),
            tiny = love.graphics.newFont(9),
        }
    end
end

function DebugPanel:Toggle()
    self.visible = not self.visible

    if self.visible then
        -- Reset scroll when opening
        self.scrollOffset = 0
    end
end

function DebugPanel:Show()
    self.visible = true
    self.scrollOffset = 0
end

function DebugPanel:Hide()
    self.visible = false
end

function DebugPanel:IsVisible()
    return self.visible
end

function DebugPanel:ToggleCollapse()
    self.collapsed = not self.collapsed
    if not self.collapsed then
        self.scrollOffset = 0
    end
end

-- Mode toggle removed - single mode only per CRAVE-6 requirements

function DebugPanel:SetTab(tabId)
    self.currentTab = tabId
    self.scrollOffset = 0
end

function DebugPanel:Update(dt)
    -- Clear buttons for next frame
    self.buttons = {}
end

function DebugPanel:Render()
    self:InitFonts()
    self.buttons = {}

    -- Toggle button now in left panel (AlphaUI), no longer rendered here

    if not self.visible then return end

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Fixed centered position (recalculate in case window resized)
    self.x = (screenW - self.width) / 2
    self.y = (screenH - self.height) / 2

    local panelHeight = self.collapsed and self.collapsedHeight or self.height

    -- Panel background
    love.graphics.setColor(self.colors.background)
    love.graphics.rectangle("fill", self.x, self.y, self.width, panelHeight, 6, 6)
    love.graphics.setColor(self.colors.border)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.x, self.y, self.width, panelHeight, 6, 6)

    -- Header
    self:RenderHeader()

    -- Only render content if not collapsed
    if not self.collapsed then
        -- Tabs
        self:RenderTabs()

        -- Content area with scissor
        local contentY = self.y + 75
        local contentH = self.height - 80
        love.graphics.setScissor(self.x + 5, contentY, self.width - 10, contentH)

        -- Render current tab content
        if self.currentTab == "overview" then
            self:RenderOverviewTab(self.x + 10, contentY - self.scrollOffset, self.width - 20)
        elseif self.currentTab == "cravings" then
            self:RenderCravingsTab(self.x + 10, contentY - self.scrollOffset, self.width - 20)
        elseif self.currentTab == "buildings" then
            self:RenderBuildingsTab(self.x + 10, contentY - self.scrollOffset, self.width - 20)
        elseif self.currentTab == "economy" then
            self:RenderEconomyTab(self.x + 10, contentY - self.scrollOffset, self.width - 20)
        elseif self.currentTab == "events" then
            self:RenderEventsTab(self.x + 10, contentY - self.scrollOffset, self.width - 20)
        end

        love.graphics.setScissor()

        -- Scroll indicator
        if self.maxScroll > 0 then
            local scrollBarH = contentH * (contentH / (contentH + self.maxScroll))
            local scrollBarY = contentY + (self.scrollOffset / self.maxScroll) * (contentH - scrollBarH)
            love.graphics.setColor(0.4, 0.5, 0.6, 0.6)
            love.graphics.rectangle("fill", self.x + self.width - 8, scrollBarY, 4, scrollBarH, 2, 2)
        end
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- =============================================================================
-- TOGGLE BUTTON (Always Visible)
-- =============================================================================
function DebugPanel:RenderToggleButton()
    -- Position in top-right corner, below speed selector (to avoid overlap)
    local btnW = 100
    local btnH = 30
    local btnX = love.graphics.getWidth() - btnW - 10
    local btnY = 50  -- Moved down to avoid speed selector

    local mx, my = love.mouse.getPosition()
    local isHover = mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH

    -- Button background
    if isHover then
        love.graphics.setColor(0.4, 0.6, 0.8, 0.95)
    else
        love.graphics.setColor(0.3, 0.5, 0.7, 0.9)
    end
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)

    -- Button border
    love.graphics.setColor(0.5, 0.7, 0.9, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", btnX, btnY, btnW, btnH, 4, 4)

    -- Button text
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(1, 1, 1, 1)
    local text = "Debug View"
    local textW = self.fonts.small:getWidth(text)
    love.graphics.print(text, btnX + (btnW - textW) / 2, btnY + 9)

    -- Store for click handling
    table.insert(self.buttons, {
        x = btnX, y = btnY, w = btnW, h = btnH,
        onClick = function() self:Toggle() end
    })
end

-- =============================================================================
-- HEADER
-- =============================================================================
function DebugPanel:RenderHeader()
    -- Header background (drag handle area)
    love.graphics.setColor(self.colors.headerBg)
    love.graphics.rectangle("fill", self.x, self.y, self.width, 35, 6, 6)
    love.graphics.rectangle("fill", self.x, self.y + 25, self.width, 10)

    -- Title
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("DEBUG PANEL", self.x + 10, self.y + 8)

    -- Subtitle (F12 to toggle)
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Press F12 to toggle", self.x + 115, self.y + 11)

    -- Close button (only button in header)
    local btnY = self.y + 7
    local btnH = 22

    -- Expand/Collapse button
    local expandLabel = self.collapsed and "Expand" or "Collapse"
    local expandIcon = self.collapsed and "[+]" or "[-]"
    self:RenderButton(expandIcon .. " " .. expandLabel, self.x + self.width - 120, btnY, 85, btnH, function()
        self:ToggleCollapse()
    end, {0.4, 0.5, 0.6})

    -- Close button
    self:RenderButton("X", self.x + self.width - 40, btnY, 30, btnH, function()
        self:Hide()
    end, {0.7, 0.3, 0.3})
end

-- =============================================================================
-- TABS
-- =============================================================================
function DebugPanel:RenderTabs()
    local tabY = self.y + 40
    local tabW = self.width / #self.tabs
    local tabH = 30

    for i, tab in ipairs(self.tabs) do
        local tabX = self.x + (i - 1) * tabW
        local isActive = self.currentTab == tab.id

        -- Tab background
        if isActive then
            love.graphics.setColor(self.colors.tabActive)
        else
            love.graphics.setColor(self.colors.tabInactive)
        end
        love.graphics.rectangle("fill", tabX, tabY, tabW, tabH)

        -- Tab border
        love.graphics.setColor(0.2, 0.3, 0.4, 0.6)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", tabX, tabY, tabW, tabH)

        -- Tab text
        love.graphics.setFont(self.fonts.small)
        local textColor = isActive and self.colors.text or self.colors.textDim
        love.graphics.setColor(textColor)
        local text = tab.label
        local textW = self.fonts.small:getWidth(text)
        love.graphics.print(text, tabX + (tabW - textW) / 2, tabY + 8)

        -- Store button for click handling
        table.insert(self.buttons, {
            x = tabX, y = tabY, w = tabW, h = tabH,
            onClick = function() self:SetTab(tab.id) end
        })
    end
end

-- =============================================================================
-- OVERVIEW TAB
-- =============================================================================
function DebugPanel:RenderOverviewTab(x, startY, w)
    local y = startY + 10

    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.4, 0.8, 0.6)
    love.graphics.print("POPULATION & SATISFACTION", x, y)
    y = y + 22

    love.graphics.setFont(self.fonts.normal)

    -- Get stats from world
    local stats = self.world and self.world.stats or {}
    local totalPop = stats.totalPopulation or 0
    local avgSat = stats.averageSatisfaction or 0
    local housed = stats.housedCount or 0
    local homeless = stats.homelessCount or 0
    local employed = stats.employedCount or 0
    local unemployed = stats.unemployedCount or 0

    -- Population metrics
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Total Population:", x, y)
    love.graphics.setColor(self.colors.text)
    love.graphics.print(tostring(totalPop), x + 130, y)
    y = y + 16

    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Average Satisfaction:", x, y)
    local satColor = avgSat >= 60 and self.colors.success or
                     (avgSat >= 30 and self.colors.warning or self.colors.error)
    love.graphics.setColor(satColor)
    love.graphics.print(string.format("%.1f%%", avgSat), x + 130, y)
    y = y + 16

    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Housed / Homeless:", x, y)
    love.graphics.setColor(self.colors.text)
    love.graphics.print(string.format("%d / %d", housed, homeless), x + 130, y)
    y = y + 16

    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Employed / Unemployed:", x, y)
    love.graphics.setColor(self.colors.text)
    love.graphics.print(string.format("%d / %d", employed, unemployed), x + 130, y)
    y = y + 20

    -- Satisfaction by class
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.8, 0.6, 0.4)
    love.graphics.print("SATISFACTION BY CLASS", x, y)
    y = y + 20

    love.graphics.setFont(self.fonts.small)
    local satisfactionByClass = stats.satisfactionByClass or {}
    local classes = {"elite", "upper", "middle", "lower"}
    local classLabels = {"Elite", "Upper", "Middle", "Lower"}

    for i, classKey in ipairs(classes) do
        local classSat = satisfactionByClass[classKey] or 0
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print(classLabels[i] .. ":", x, y)

        -- Bar
        local barX = x + 60
        local barW = 120
        local barH = 10
        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", barX, y + 1, barW, barH)

        local fillW = (classSat / 100) * barW
        local barColor = classSat >= 60 and {0.3, 0.7, 0.3} or
                        (classSat >= 30 and {0.7, 0.7, 0.3} or {0.7, 0.3, 0.3})
        love.graphics.setColor(barColor)
        love.graphics.rectangle("fill", barX, y + 1, fillW, barH)

        love.graphics.setColor(self.colors.text)
        love.graphics.print(string.format("%.1f%%", classSat), barX + barW + 5, y)
        y = y + 14
    end
    y = y + 10

    -- Production metrics (if ProductionStats available)
    if self.world and self.world.productionStats then
        love.graphics.setFont(self.fonts.header)
        love.graphics.setColor(0.6, 0.4, 0.8)
        love.graphics.print("PRODUCTION", x, y)
        y = y + 20

        love.graphics.setFont(self.fonts.small)
        local metrics = self.world.productionStats:getMetricsSummary()

        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Worker Utilization:", x, y)
        love.graphics.setColor(self.colors.text)
        love.graphics.print(string.format("%.1f%%", metrics.workerUtilization or 0), x + 130, y)
        y = y + 14

        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Active / Total Workers:", x, y)
        love.graphics.setColor(self.colors.text)
        love.graphics.print(string.format("%d / %d", metrics.activeWorkers or 0, metrics.totalWorkers or 0), x + 130, y)
        y = y + 18

        -- Top producers
        if metrics.topProducers and #metrics.topProducers > 0 then
            love.graphics.setFont(self.fonts.tiny)
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("Top Producers:", x, y)
            y = y + 12

            for i = 1, math.min(3, #metrics.topProducers) do
                local producer = metrics.topProducers[i]
                love.graphics.setColor(self.colors.textMuted)
                love.graphics.print(string.format("%d. %s: %.1f/min", i, producer.id, producer.rate), x + 10, y)
                y = y + 11
            end
            y = y + 6
        end
    end

    y = y + 10

    -- Testing section (for CRAVE-10 verification)
    y = self:RenderTestingSection(x, y, w)

    -- Set max scroll
    self.maxScroll = math.max(0, y - startY - (self.height - 80))
end

-- =============================================================================
-- TESTING SECTION (for CRAVE-10 verification)
-- =============================================================================
function DebugPanel:RenderTestingSection(x, y, w)
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.9, 0.6, 0.3)
    love.graphics.print("TESTING (F1: Satisfaction -> Production)", x, y)
    y = y + 20

    -- Current productivity multiplier display
    local productivityMult = (self.world and self.world.stats and self.world.stats.productivityMultiplier) or 1.0
    local avgSat = (self.world and self.world.stats and self.world.stats.averageSatisfaction) or 50

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Productivity Multiplier:", x, y)
    local prodColor = productivityMult >= 0.8 and self.colors.success or
                     (productivityMult >= 0.5 and self.colors.warning or self.colors.error)
    love.graphics.setColor(prodColor)
    love.graphics.print(string.format("%.2fx (%.0f%% production)", productivityMult, productivityMult * 100), x + 140, y)
    y = y + 16

    -- Override checkbox
    local override = self.world and self.world.debugSatisfactionOverride
    local isOverrideActive = override and override.active or false

    -- Checkbox
    local checkboxX = x
    local checkboxY = y
    local checkboxSize = 14

    love.graphics.setColor(0.2, 0.25, 0.3)
    love.graphics.rectangle("fill", checkboxX, checkboxY, checkboxSize, checkboxSize, 2, 2)
    love.graphics.setColor(0.5, 0.55, 0.6)
    love.graphics.rectangle("line", checkboxX, checkboxY, checkboxSize, checkboxSize, 2, 2)

    if isOverrideActive then
        love.graphics.setColor(0.3, 0.7, 0.4)
        love.graphics.rectangle("fill", checkboxX + 3, checkboxY + 3, checkboxSize - 6, checkboxSize - 6, 1, 1)
    end

    love.graphics.setColor(self.colors.text)
    love.graphics.print("Override Satisfaction", checkboxX + checkboxSize + 6, checkboxY)

    -- Checkbox click handler
    table.insert(self.buttons, {
        x = checkboxX, y = checkboxY, w = checkboxSize + 120, h = checkboxSize,
        onClick = function()
            if self.world and self.world.debugSatisfactionOverride then
                self.world.debugSatisfactionOverride.active = not self.world.debugSatisfactionOverride.active
            end
        end
    })
    y = y + 20

    -- Slider (only show if override is active)
    if isOverrideActive and override then
        love.graphics.setFont(self.fonts.tiny)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Override Value:", x, y + 2)

        local sliderX = x + 90
        local sliderW = w - 140
        local sliderH = 12
        local sliderValue = override.value or 50

        -- Slider track
        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", sliderX, y, sliderW, sliderH, 3, 3)

        -- Slider fill (colored by value)
        local fillColor = sliderValue >= 50 and {0.3, 0.6, 0.3} or
                         (sliderValue >= 25 and {0.7, 0.6, 0.2} or {0.7, 0.3, 0.3})
        love.graphics.setColor(fillColor)
        local fillW = (sliderValue / 100) * sliderW
        love.graphics.rectangle("fill", sliderX, y, fillW, sliderH, 3, 3)

        -- Slider handle
        local handleX = sliderX + fillW - 4
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", handleX, y - 2, 8, sliderH + 4, 2, 2)

        -- Value display
        love.graphics.setColor(self.colors.text)
        love.graphics.print(string.format("%d%%", sliderValue), sliderX + sliderW + 8, y)

        -- Slider click/drag handler
        table.insert(self.buttons, {
            x = sliderX, y = y - 2, w = sliderW, h = sliderH + 4,
            onClick = function()
                -- Calculate new value based on mouse position
                local mx = love.mouse.getX()
                local newValue = math.floor(((mx - sliderX) / sliderW) * 100)
                newValue = math.max(0, math.min(100, newValue))
                if self.world and self.world.debugSatisfactionOverride then
                    self.world.debugSatisfactionOverride.value = newValue
                end
            end
        })
        y = y + 18

        -- Expected productivity based on override
        local expectedProd = sliderValue < 50 and math.max(0.1, sliderValue / 50) or 1.0
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print(string.format("Expected Production: %.0f%% (multiplier: %.2fx)", expectedProd * 100, expectedProd), x, y)
        y = y + 14
    end

    y = y + 5
    return y
end

-- =============================================================================
-- BUILDINGS TAB (Enhanced with filters, click-to-select, detail view)
-- =============================================================================
function DebugPanel:RenderBuildingsTab(x, startY, w)
    local y = startY + 10

    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.8, 0.6, 0.4)
    love.graphics.print("BUILDINGS", x, y)
    y = y + 20

    local buildings = (self.world and self.world.buildings) or {}

    if #buildings == 0 then
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("No buildings yet", x, y)
        y = y + 20
        self.maxScroll = 0
        return
    end

    -- Filter buttons
    y = self:RenderBuildingFilters(x, y, w)
    y = y + 10

    -- Count buildings by status
    local statusCounts = {all = 0, producing = 0, idle = 0, no_materials = 0, no_worker = 0}
    local buildingTypes = {}

    for _, building in ipairs(buildings) do
        statusCounts.all = statusCounts.all + 1
        local bType = building.name or building.mName or "Unknown"
        buildingTypes[bType] = (buildingTypes[bType] or 0) + 1

        local status = self:GetBuildingPrimaryStatus(building)
        if statusCounts[status] then
            statusCounts[status] = statusCounts[status] + 1
        end
    end

    -- Status summary line
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print(string.format("Prod: %d | Idle: %d | NoMat: %d | NoWkr: %d",
        statusCounts.producing, statusCounts.idle, statusCounts.no_materials, statusCounts.no_worker), x, y)
    y = y + 16

    -- Building list
    love.graphics.setFont(self.fonts.small)
    local filteredBuildings = self:FilterBuildings(buildings)

    for i, building in ipairs(filteredBuildings) do
        local status = self:GetBuildingPrimaryStatus(building)
        local isSelected = self.selectedBuilding == building

        -- Row background for selected
        if isSelected then
            love.graphics.setColor(0.3, 0.4, 0.5, 0.4)
            love.graphics.rectangle("fill", x - 5, y - 2, w + 10, 18, 3, 3)
        end

        -- Status indicator (use colored circle instead of emoji)
        local statusColor = self.colors.textMuted
        if status == "producing" then
            statusColor = self.colors.success
        elseif status == "no_materials" then
            statusColor = self.colors.warning
        elseif status == "no_worker" then
            statusColor = self.colors.error
        end

        love.graphics.setColor(statusColor)
        love.graphics.circle("fill", x + 5, y + 6, 4)

        -- Building name
        local bName = building.name or building.mName or "Building"
        love.graphics.setColor(isSelected and self.colors.info or self.colors.text)
        love.graphics.print(bName, x + 18, y)

        -- Recipe/worker info
        local recipeInfo = self:GetBuildingRecipeInfo(building)
        local workerInfo = self:GetBuildingWorkerInfo(building)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print(recipeInfo, x + 130, y)
        love.graphics.print(workerInfo, x + w - 55, y)

        -- Click handler
        local btnY = y - 2
        table.insert(self.buttons, {
            x = x - 5, y = btnY, w = w + 10, h = 18,
            onClick = function()
                if self.selectedBuilding == building then
                    self.selectedBuilding = nil
                else
                    self.selectedBuilding = building
                end
            end
        })

        y = y + 18
    end

    y = y + 10

    -- Building detail view (if selected)
    if self.selectedBuilding then
        y = self:RenderBuildingDetailView(x, y, w, self.selectedBuilding)
    end

    self.maxScroll = math.max(0, y - startY - (self.height - 80))
end

function DebugPanel:RenderBuildingFilters(x, y, w)
    love.graphics.setFont(self.fonts.tiny)

    -- Filter label
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Filter:", x, y + 4)

    -- Filter buttons
    local filters = {
        {id = "all", label = "All"},
        {id = "producing", label = "Prod"},
        {id = "idle", label = "Idle"},
        {id = "no_materials", label = "NoMat"},
        {id = "no_worker", label = "NoWkr"}
    }

    local btnX = x + 40
    local btnW = 55
    local btnH = 18

    for _, filter in ipairs(filters) do
        local isActive = self.buildingFilter == filter.id
        local color = isActive and {0.3, 0.5, 0.7} or {0.2, 0.25, 0.3}
        self:RenderButton(filter.label, btnX, y, btnW, btnH, function()
            self.buildingFilter = filter.id
        end, color)
        btnX = btnX + btnW + 3
    end

    return y + btnH + 5
end

function DebugPanel:GetBuildingPrimaryStatus(building)
    if not building.stations and not building.mStations then
        return "idle"
    end

    local stations = building.stations or building.mStations or {}
    local hasProducing = false
    local hasNoMaterials = false
    local hasNoWorker = false

    for _, station in ipairs(stations) do
        if station.state == "PRODUCING" then
            hasProducing = true
        elseif station.state == "NO_MATERIALS" then
            hasNoMaterials = true
        elseif station.state == "NO_WORKER" then
            hasNoWorker = true
        end
    end

    if hasProducing then return "producing" end
    if hasNoMaterials then return "no_materials" end
    if hasNoWorker then return "no_worker" end
    return "idle"
end

function DebugPanel:FilterBuildings(buildings)
    local filtered = {}
    for _, building in ipairs(buildings) do
        local status = self:GetBuildingPrimaryStatus(building)
        if self.buildingFilter == "all" or self.buildingFilter == status then
            table.insert(filtered, building)
        end
    end
    return filtered
end

function DebugPanel:GetBuildingRecipeInfo(building)
    local stations = building.stations or building.mStations or {}
    for _, station in ipairs(stations) do
        if station.recipe then
            local recipeName = station.recipe.name or station.recipe.id or "Recipe"
            if #recipeName > 15 then
                recipeName = recipeName:sub(1, 12) .. "..."
            end
            return recipeName
        end
    end
    return "No Recipe"
end

function DebugPanel:GetBuildingWorkerInfo(building)
    local workers = building.workers or building.mWorkers or {}
    local stations = building.stations or building.mStations or {}
    local maxWorkers = #stations > 0 and #stations or 2
    return string.format("%d/%d wkr", #workers, maxWorkers)
end

function DebugPanel:RenderBuildingDetailView(x, y, w, building)
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.5, 0.7, 0.9)
    love.graphics.print("SELECTED: " .. (building.name or building.mName or "Building"), x, y)
    y = y + 20

    local stations = building.stations or building.mStations or {}

    -- Production State
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.6, 0.7, 0.8)
    love.graphics.print("Production State", x, y)
    y = y + 14

    love.graphics.setFont(self.fonts.tiny)
    for i, station in ipairs(stations) do
        local stateColor = self.colors.textMuted
        if station.state == "PRODUCING" then stateColor = self.colors.success
        elseif station.state == "NO_MATERIALS" then stateColor = self.colors.warning
        elseif station.state == "NO_WORKER" then stateColor = self.colors.error
        end

        love.graphics.setColor(stateColor)
        local recipeName = station.recipe and (station.recipe.name or station.recipe.id) or "No Recipe"
        local progress = station.progress or 0
        local progressBar = string.rep("█", math.floor(progress * 10)) .. string.rep("░", 10 - math.floor(progress * 10))
        love.graphics.print(string.format("Station %d: %s [%s] %.0f%%", i, station.state or "IDLE", progressBar, progress * 100), x + 5, y)
        y = y + 12
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("  Recipe: " .. recipeName, x + 5, y)
        y = y + 12
    end
    y = y + 5

    -- Location Efficiency (F2: Terrain -> Production)
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.4, 0.8, 0.6)
    love.graphics.print("Location Efficiency (F2)", x, y)
    y = y + 14

    local resourceEfficiency = building.resourceEfficiency or 1.0
    local productivityMult = (self.world and self.world.stats and self.world.stats.productivityMultiplier) or 1.0
    local effectiveRate = resourceEfficiency * productivityMult

    love.graphics.setFont(self.fonts.tiny)

    -- Resource efficiency (terrain-based)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("  Terrain Efficiency:", x + 5, y)
    local effColor = resourceEfficiency >= 0.7 and self.colors.success or
                    (resourceEfficiency >= 0.4 and self.colors.warning or self.colors.error)
    love.graphics.setColor(effColor)
    love.graphics.print(string.format("%.0f%%", resourceEfficiency * 100), x + 130, y)
    y = y + 11

    -- Productivity multiplier (satisfaction-based)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("  Productivity (Sat):", x + 5, y)
    local prodColor = productivityMult >= 0.8 and self.colors.success or
                     (productivityMult >= 0.5 and self.colors.warning or self.colors.error)
    love.graphics.setColor(prodColor)
    love.graphics.print(string.format("%.0f%%", productivityMult * 100), x + 130, y)
    y = y + 11

    -- Effective production rate
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("  Effective Rate:", x + 5, y)
    local rateColor = effectiveRate >= 0.6 and self.colors.success or
                     (effectiveRate >= 0.3 and self.colors.warning or self.colors.error)
    love.graphics.setColor(rateColor)
    love.graphics.print(string.format("%.0f%% (%.2f x %.2f)", effectiveRate * 100, resourceEfficiency, productivityMult), x + 130, y)
    y = y + 14

    -- Show resource breakdown if available
    if building.efficiencyBreakdown then
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("  Resource Breakdown:", x + 5, y)
        y = y + 11
        for resource, data in pairs(building.efficiencyBreakdown) do
            love.graphics.setColor(self.colors.textDim)
            local val = type(data) == "table" and (data.value or 0) or data
            local wgt = type(data) == "table" and (data.weight or 0) or 1
            love.graphics.print(string.format("    %s: %.2f (wt: %.1f)", resource, val, wgt), x + 5, y)
            y = y + 10
        end
    end
    y = y + 5

    -- Input Buffer
    local storage = building.mStorage or {}
    if storage.inputs then
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(0.7, 0.6, 0.5)
        local inputUsed = storage.inputUsed or 0
        local inputCap = storage.inputCapacity or 300
        love.graphics.print(string.format("Input Buffer (%d/%d)", inputUsed, inputCap), x, y)
        y = y + 14

        love.graphics.setFont(self.fonts.tiny)
        love.graphics.setColor(self.colors.textDim)
        local hasInputs = false
        for commodityId, amount in pairs(storage.inputs) do
            if amount > 0 then
                love.graphics.print(string.format("  %s: %d", commodityId, amount), x + 5, y)
                y = y + 11
                hasInputs = true
            end
        end
        if not hasInputs then
            love.graphics.print("  (empty)", x + 5, y)
            y = y + 11
        end
    end
    y = y + 5

    -- Output Buffer
    if storage.outputs then
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(0.5, 0.7, 0.6)
        local outputUsed = storage.outputUsed or 0
        local outputCap = storage.outputCapacity or 500
        love.graphics.print(string.format("Output Buffer (%d/%d)", outputUsed, outputCap), x, y)
        y = y + 14

        love.graphics.setFont(self.fonts.tiny)
        love.graphics.setColor(self.colors.textDim)
        local hasOutputs = false
        for commodityId, amount in pairs(storage.outputs) do
            if amount > 0 then
                love.graphics.print(string.format("  %s: %d", commodityId, amount), x + 5, y)
                y = y + 11
                hasOutputs = true
            end
        end
        if not hasOutputs then
            love.graphics.print("  (empty)", x + 5, y)
            y = y + 11
        end
    end
    y = y + 5

    -- Workers
    local workers = building.workers or building.mWorkers or {}
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.6, 0.6, 0.8)
    love.graphics.print(string.format("Workers (%d)", #workers), x, y)
    y = y + 14

    love.graphics.setFont(self.fonts.tiny)
    if #workers == 0 then
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("  No workers assigned", x + 5, y)
        y = y + 11
    else
        for _, workerId in ipairs(workers) do
            local worker = self:FindCitizenById(workerId)
            local workerName = worker and (worker.name or "Unknown") or ("ID:" .. tostring(workerId))
            local efficiency = building.resourceEfficiency or 1.0
            love.graphics.setColor(self.colors.textDim)
            love.graphics.print(string.format("  %s - Eff: %.0f%%", workerName, efficiency * 100), x + 5, y)
            y = y + 11
        end
    end
    y = y + 5

    -- Bottleneck indicator
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.7, 0.7, 0.5)
    love.graphics.print("Bottleneck", x, y)
    y = y + 14

    love.graphics.setFont(self.fonts.tiny)
    local bottleneck = self:DetectBottleneck(building)
    if bottleneck == "none" then
        love.graphics.setColor(self.colors.success)
        love.graphics.print("  [OK] No bottleneck - producing normally", x + 5, y)
    elseif bottleneck == "no_workers" then
        love.graphics.setColor(self.colors.error)
        love.graphics.print("  [!] Missing workers - assign citizens", x + 5, y)
    elseif bottleneck == "no_materials" then
        love.graphics.setColor(self.colors.warning)
        love.graphics.print("  [!] Waiting for materials", x + 5, y)
    elseif bottleneck == "no_recipe" then
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("  [-] No recipe assigned", x + 5, y)
    end
    y = y + 14

    -- Production History
    y = self:RenderProductionHistory(x, y, w, building)

    return y
end

function DebugPanel:FindCitizenById(citizenId)
    if not self.world or not self.world.citizens then return nil end
    for _, citizen in ipairs(self.world.citizens) do
        if citizen.id == citizenId then
            return citizen
        end
    end
    return nil
end

function DebugPanel:DetectBottleneck(building)
    local stations = building.stations or building.mStations or {}
    local workers = building.workers or building.mWorkers or {}

    if #workers == 0 then
        return "no_workers"
    end

    local hasRecipe = false
    local hasNoMaterials = false

    for _, station in ipairs(stations) do
        if station.recipe then
            hasRecipe = true
            if station.state == "NO_MATERIALS" then
                hasNoMaterials = true
            end
        end
    end

    if not hasRecipe then
        return "no_recipe"
    end

    if hasNoMaterials then
        return "no_materials"
    end

    return "none"
end

function DebugPanel:RenderProductionHistory(x, y, w, building)
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.6, 0.5, 0.7)
    love.graphics.print("Production History (Last 10)", x, y)
    y = y + 14

    love.graphics.setFont(self.fonts.tiny)

    local history = {}
    if building.GetProductionHistory then
        history = building:GetProductionHistory()
    elseif building.mProductionHistory then
        -- Manual reverse for display
        for i = #building.mProductionHistory, 1, -1 do
            table.insert(history, building.mProductionHistory[i])
        end
    end

    if #history == 0 then
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("  No production history yet", x + 5, y)
        y = y + 12
    else
        for i, entry in ipairs(history) do
            if i > 10 then break end

            local statusColor = self.colors.success
            local statusIcon = "[+]"
            if entry.status == "blocked_no_materials" then
                statusColor = self.colors.warning
                statusIcon = "[!]"
            elseif entry.status == "blocked_no_worker" then
                statusColor = self.colors.error
                statusIcon = "[X]"
            end

            love.graphics.setColor(statusColor)

            -- Format outputs
            local outputStr = ""
            if entry.outputs then
                local parts = {}
                for commodityId, amount in pairs(entry.outputs) do
                    table.insert(parts, "+" .. amount .. " " .. commodityId)
                end
                outputStr = table.concat(parts, ", ")
            end

            -- Format duration
            local durationStr = ""
            if entry.duration and entry.duration > 0 then
                if entry.duration >= 60 then
                    durationStr = string.format("(%.1fm)", entry.duration / 60)
                else
                    durationStr = string.format("(%.1fs)", entry.duration)
                end
            end

            local recipeName = entry.recipeName or entry.recipeId or "?"
            if entry.status == "completed" then
                love.graphics.print(string.format("  %s Cycle %d: %s %s", statusIcon, entry.cycle or 0, outputStr, durationStr), x + 5, y)
            else
                local reason = entry.status == "blocked_no_materials" and "No materials" or "No worker"
                love.graphics.print(string.format("  %s Cycle %d: BLOCKED - %s", statusIcon, entry.cycle or 0, reason), x + 5, y)
            end
            y = y + 11
        end
    end

    return y + 5
end

-- =============================================================================
-- CRAVINGS TAB (Select dimension, show all citizens)
-- =============================================================================
function DebugPanel:RenderCravingsTab(x, startY, w)
    local y = startY + 10

    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.9, 0.5, 0.5)
    love.graphics.print("CRAVING DIMENSION VIEW", x, y)
    y = y + 22

    local citizens = (self.world and self.world.citizens) or {}

    -- Get dimension data from CharacterV3 (preferred) or CharacterV2
    local CharacterV3 = require("code.consumption.CharacterV3")
    local CharacterV2 = nil
    pcall(function() CharacterV2 = require("code/consumption/CharacterV2") end)

    -- Use CharacterV3 if available, fall back to CharacterV2
    local CharRef = CharacterV3
    if not CharRef or not CharRef.fineNames or not next(CharRef.fineNames or {}) then
        CharRef = CharacterV2
    end

    if not CharRef or not CharRef.fineNames or not next(CharRef.fineNames or {}) then
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("Dimension data not loaded", x, y)
        y = y + 20
        self.maxScroll = 0
        return
    end

    local fineNames = CharRef.fineNames or {}
    local coarseNames = CharRef.coarseNames or {}
    local fineToCoarseMap = CharRef.fineToCoarseMap or {}

    -- Build sorted list of dimensions for picker
    local dimensionList = {}
    for fineIdx, fineName in pairs(fineNames) do
        local coarseIdx = fineToCoarseMap[fineIdx]
        local coarseName = coarseNames[coarseIdx] or "unknown"
        table.insert(dimensionList, {
            idx = fineIdx,
            name = fineName,
            coarse = coarseName
        })
    end
    table.sort(dimensionList, function(a, b)
        if a.coarse ~= b.coarse then
            return a.coarse < b.coarse
        end
        return a.name < b.name
    end)

    -- Set default selection if none
    if not self.selectedFineDimension and #dimensionList > 0 then
        self.selectedFineDimension = dimensionList[1].idx
    end

    -- Dimension picker
    y = self:RenderDimensionPicker(x, y, w, dimensionList, fineNames)
    y = y + 10

    -- Class filter
    y = self:RenderClassFilter(x, y, w)
    y = y + 10

    -- Show citizens for selected dimension
    if self.selectedFineDimension and #citizens > 0 then
        y = self:RenderCitizenListForDimension(x, y, w, citizens, self.selectedFineDimension, fineNames, coarseNames, fineToCoarseMap)
    elseif #citizens == 0 then
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("No citizens to analyze", x, y)
        y = y + 20
    end

    self.maxScroll = math.max(0, y - startY - (self.height - 80))
end

function DebugPanel:RenderDimensionPicker(x, y, w, dimensionList, fineNames)
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Dimension:", x, y + 3)

    -- Current selection display / dropdown button
    local btnX = x + 75
    local btnW = w - 85
    local btnH = 22

    local selectedName = "Select dimension..."
    if self.selectedFineDimension and fineNames[self.selectedFineDimension] then
        selectedName = fineNames[self.selectedFineDimension]
        if #selectedName > 40 then
            selectedName = selectedName:sub(1, 37) .. "..."
        end
    end

    -- Dropdown button
    local dropdownColor = self.cravingsDimensionPickerOpen and {0.4, 0.45, 0.5} or {0.25, 0.3, 0.35}
    love.graphics.setColor(dropdownColor)
    love.graphics.rectangle("fill", btnX, y, btnW, btnH, 3, 3)
    love.graphics.setColor(0.5, 0.55, 0.6)
    love.graphics.rectangle("line", btnX, y, btnW, btnH, 3, 3)

    love.graphics.setColor(self.colors.text)
    love.graphics.print(selectedName, btnX + 8, y + 4)

    local arrow = self.cravingsDimensionPickerOpen and "[-]" or "[v]"
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print(arrow, btnX + btnW - 25, y + 4)

    -- Toggle dropdown on click
    table.insert(self.buttons, {
        x = btnX, y = y, w = btnW, h = btnH,
        onClick = function()
            self.cravingsDimensionPickerOpen = not self.cravingsDimensionPickerOpen
        end
    })

    y = y + btnH + 2

    -- Dropdown list (if open)
    if self.cravingsDimensionPickerOpen then
        -- Coarse filter row
        love.graphics.setFont(self.fonts.tiny)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Filter:", btnX, y + 2)

        local coarseFilters = {
            {id = "all", label = "All"},
            {id = "biological", label = "Bio"},
            {id = "safety", label = "Safe"},
            {id = "touch", label = "Tch"},
            {id = "psychological", label = "Psy"},
            {id = "social_status", label = "Sts"},
            {id = "social_connection", label = "Soc"},
            {id = "exotic_goods", label = "Exo"},
            {id = "shiny_objects", label = "Shy"},
            {id = "vice", label = "Vic"},
            {id = "utility", label = "Utl"}
        }
        local filterBtnX = btnX + 35
        local filterBtnW = 28
        local filterBtnH = 14

        for _, filter in ipairs(coarseFilters) do
            local label = filter.label
            local coarse = filter.id
            local isActive = self.cravingsCoarseFilter == coarse
            local color = isActive and {0.5, 0.4, 0.4} or {0.2, 0.25, 0.3}

            love.graphics.setColor(color)
            love.graphics.rectangle("fill", filterBtnX, y, filterBtnW, filterBtnH, 2, 2)
            love.graphics.setColor(self.colors.text)
            local tw = self.fonts.tiny:getWidth(label)
            love.graphics.print(label, filterBtnX + (filterBtnW - tw) / 2, y + 1)

            table.insert(self.buttons, {
                x = filterBtnX, y = y, w = filterBtnW, h = filterBtnH,
                onClick = function()
                    self.cravingsCoarseFilter = coarse
                end
            })
            filterBtnX = filterBtnX + filterBtnW + 2
        end
        y = y + filterBtnH + 4

        -- Dropdown list background
        local listH = math.min(200, #dimensionList * 14 + 4)
        love.graphics.setColor(0.15, 0.18, 0.22, 0.98)
        love.graphics.rectangle("fill", btnX, y, btnW, listH, 3, 3)
        love.graphics.setColor(0.4, 0.45, 0.5)
        love.graphics.rectangle("line", btnX, y, btnW, listH, 3, 3)

        -- List items
        local listY = y + 2
        love.graphics.setFont(self.fonts.tiny)
        for _, dim in ipairs(dimensionList) do
            -- Apply coarse filter
            if self.cravingsCoarseFilter == "all" or dim.coarse == self.cravingsCoarseFilter then
                local isSelected = self.selectedFineDimension == dim.idx
                local itemH = 14

                if listY < y + listH - 2 then
                    if isSelected then
                        love.graphics.setColor(0.3, 0.4, 0.5, 0.5)
                        love.graphics.rectangle("fill", btnX + 2, listY, btnW - 4, itemH)
                    end

                    love.graphics.setColor(self.colors.text)
                    local displayName = dim.name
                    if #displayName > 45 then
                        displayName = displayName:sub(1, 42) .. "..."
                    end
                    love.graphics.print(displayName, btnX + 6, listY + 1)

                    -- Click to select
                    table.insert(self.buttons, {
                        x = btnX + 2, y = listY, w = btnW - 4, h = itemH,
                        onClick = function()
                            self.selectedFineDimension = dim.idx
                            self.cravingsDimensionPickerOpen = false
                        end
                    })

                    listY = listY + itemH
                end
            end
        end

        y = y + listH + 2
    end

    return y
end

function DebugPanel:RenderClassFilter(x, y, w)
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Class:", x, y + 2)

    local classes = {
        {id = "all", label = "All"},
        {id = "Elite", label = "Elite"},
        {id = "Upper", label = "Upper"},
        {id = "Middle", label = "Middle"},
        {id = "Lower", label = "Lower"}
    }

    local btnX = x + 50
    local btnW = 50
    local btnH = 18

    for _, cls in ipairs(classes) do
        local isActive = self.cravingsClassFilter == cls.id
        local color = isActive and {0.4, 0.5, 0.6} or {0.2, 0.25, 0.3}

        love.graphics.setColor(color)
        love.graphics.rectangle("fill", btnX, y, btnW, btnH, 2, 2)
        love.graphics.setColor(0.5, 0.55, 0.6)
        love.graphics.rectangle("line", btnX, y, btnW, btnH, 2, 2)

        love.graphics.setColor(self.colors.text)
        love.graphics.setFont(self.fonts.tiny)
        local tw = self.fonts.tiny:getWidth(cls.label)
        love.graphics.print(cls.label, btnX + (btnW - tw) / 2, y + 3)

        table.insert(self.buttons, {
            x = btnX, y = y, w = btnW, h = btnH,
            onClick = function()
                self.cravingsClassFilter = cls.id
            end
        })

        btnX = btnX + btnW + 4
    end

    return y + btnH + 2
end

function DebugPanel:RenderCitizenListForDimension(x, y, w, citizens, fineIdx, fineNames, coarseNames, fineToCoarseMap)
    local fineName = fineNames[fineIdx] or "Unknown"
    local coarseIdx = fineToCoarseMap[fineIdx]
    local coarseName = coarseNames[coarseIdx] or "unknown"

    -- Header
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.7, 0.8, 0.9)
    love.graphics.print("Citizens - " .. fineName, x, y)
    y = y + 16

    -- Column headers
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Name", x + 5, y)
    love.graphics.print("Class", x + 140, y)
    love.graphics.print("Craving", x + 200, y)
    y = y + 14

    -- Separator
    love.graphics.setColor(0.3, 0.35, 0.4)
    love.graphics.line(x, y, x + w, y)
    y = y + 4

    -- Gather and filter citizen data
    local citizenData = {}
    local maxCraving = 0  -- Track max for bar scaling
    for _, citizen in ipairs(citizens) do
        -- Apply class filter
        local citizenClass = citizen.class or "middle"
        local filterMatch = self.cravingsClassFilter == "all" or
                           citizenClass:lower() == self.cravingsClassFilter:lower()

        if filterMatch then
            local craving = 0

            -- Get current craving for this fine dimension
            if citizen.currentCravings then
                craving = citizen.currentCravings[fineIdx] or 0
            end

            if craving > maxCraving then
                maxCraving = craving
            end

            table.insert(citizenData, {
                name = citizen.name or "Unknown",
                class = citizenClass,
                craving = craving
            })
        end
    end

    -- Sort by craving (highest first = most needy at top)
    table.sort(citizenData, function(a, b)
        return a.craving > b.craving
    end)

    -- Ensure maxCraving has a reasonable minimum for bar scaling
    if maxCraving < 1 then maxCraving = 1 end

    -- Render citizen rows
    love.graphics.setFont(self.fonts.small)
    for _, cData in ipairs(citizenData) do
        -- Craving level color indicator (high craving = red/warning, low = green)
        local cravingRatio = cData.craving / maxCraving
        local cravColor = cravingRatio >= 0.7 and self.colors.error or
                         (cravingRatio >= 0.4 and self.colors.warning or self.colors.success)

        love.graphics.setColor(cravColor)
        love.graphics.circle("fill", x + 8, y + 6, 4)

        -- Name
        love.graphics.setColor(self.colors.text)
        local displayName = cData.name
        if #displayName > 18 then
            displayName = displayName:sub(1, 15) .. "..."
        end
        love.graphics.print(displayName, x + 18, y)

        -- Class
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print(cData.class, x + 140, y)

        -- Craving bar (scaled to max craving among citizens)
        local barX = x + 200
        local barW = 100
        local barH = 10
        love.graphics.setColor(0.2, 0.2, 0.25)
        love.graphics.rectangle("fill", barX, y + 2, barW, barH)
        local fillW = (cData.craving / maxCraving) * barW
        love.graphics.setColor(cravColor)
        love.graphics.rectangle("fill", barX, y + 2, fillW, barH)

        -- Craving value
        love.graphics.setColor(self.colors.text)
        love.graphics.print(string.format("%.1f", cData.craving), barX + barW + 8, y)

        y = y + 18
    end

    if #citizenData == 0 then
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("No citizens match filter", x + 10, y)
        y = y + 20
    end

    return y
end

-- =============================================================================
-- ECONOMY TAB (CRAVE-19: Economy Flow Visualization)
-- =============================================================================
function DebugPanel:RenderEconomyTab(x, startY, w)
    local y = startY + 10

    -- Header
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.print("ECONOMY FLOW VISUALIZATION", x, y)
    y = y + 22

    -- Check if production stats available
    if not self.world or not self.world.productionStats then
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("Production stats not initialized", x, y)
        self.maxScroll = 0
        return
    end

    -- Refresh economy data
    self:RefreshEconomyData()

    -- Filter dropdown
    y = self:RenderEconomyFilter(x, y, w)
    y = y + 10

    -- Sankey diagram (Production -> Inventory -> Consumption)
    y = self:RenderSankeyDiagram(x, y, w, 160)
    y = y + 15

    -- Commodity details table with sparklines
    y = self:RenderCommodityTable(x, y, w)

    self.maxScroll = math.max(0, y - startY - (self.height - 80))
end

-- Refresh economy data cache
function DebugPanel:RefreshEconomyData()
    if not self.world or not self.world.productionStats then return end

    local stats = self.world.productionStats
    local inventory = self.world.inventory or {}

    -- Get flow summary
    local flowSummary = stats:getFlowSummary(inventory)
    local totalFlows = stats:getTotalFlowRates()

    -- Calculate total stock
    local totalStock = 0
    for _, qty in pairs(inventory) do
        totalStock = totalStock + (qty or 0)
    end

    -- Update sankey data
    self.economyCache.sankeyData.totalProduction = totalFlows.totalProduction
    self.economyCache.sankeyData.totalConsumption = totalFlows.totalConsumption
    self.economyCache.sankeyData.totalStock = totalStock

    -- Filter commodities based on current filter
    local filtered = {}
    if self.economyFilter == "active" then
        -- Show commodities with any production, consumption, OR stock > 0
        for _, item in ipairs(flowSummary) do
            if item.prodRate > 0 or item.consRate > 0 or item.stock > 0 then
                table.insert(filtered, item)
            end
        end
    elseif self.economyFilter == "top20" then
        -- Show top 20 by flow volume + stock (already sorted)
        for i = 1, math.min(20, #flowSummary) do
            if flowSummary[i] then
                table.insert(filtered, flowSummary[i])
            end
        end
    else
        -- Show all
        filtered = flowSummary
    end

    self.economyCache.commodityDetails = filtered

    -- Get sparkline data (dual: production and consumption separately)
    local recentProd = stats:getRecentProductionByCommodity(10)
    local recentCons = stats:getRecentConsumptionByCommodity(10)

    self.economyCache.sparklineData = {}
    for _, item in ipairs(filtered) do
        local prodValues = recentProd[item.id] or {}
        local consValues = recentCons[item.id] or {}

        -- Store both production and consumption separately for dual sparklines
        local maxLen = math.max(#prodValues, #consValues, 1)
        local sparkData = {
            production = {},
            consumption = {}
        }

        for i = 1, maxLen do
            table.insert(sparkData.production, prodValues[i] or 0)
            table.insert(sparkData.consumption, consValues[i] or 0)
        end

        self.economyCache.sparklineData[item.id] = sparkData
    end
end

-- Render filter dropdown
function DebugPanel:RenderEconomyFilter(x, y, w)
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Filter:", x, y + 3)

    -- Dropdown button
    local btnX = x + 50
    local btnW = 180
    local btnH = 22

    local filterLabels = {
        active = "Active (recent flow)",
        top20 = "Top 20 by volume",
        all = "All commodities"
    }

    local currentLabel = filterLabels[self.economyFilter] or "Active"

    -- Button background
    local dropdownColor = self.economyFilterDropdownOpen and {0.4, 0.45, 0.5} or {0.25, 0.3, 0.35}
    love.graphics.setColor(dropdownColor)
    love.graphics.rectangle("fill", btnX, y, btnW, btnH, 3, 3)
    love.graphics.setColor(0.5, 0.55, 0.6)
    love.graphics.rectangle("line", btnX, y, btnW, btnH, 3, 3)

    love.graphics.setColor(self.colors.text)
    love.graphics.print(currentLabel, btnX + 8, y + 4)

    local arrow = self.economyFilterDropdownOpen and "[-]" or "[v]"
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print(arrow, btnX + btnW - 25, y + 4)

    -- Toggle dropdown on click
    table.insert(self.buttons, {
        x = btnX, y = y, w = btnW, h = btnH,
        onClick = function()
            self.economyFilterDropdownOpen = not self.economyFilterDropdownOpen
        end
    })

    y = y + btnH + 2

    -- Dropdown list (if open)
    if self.economyFilterDropdownOpen then
        local filters = {
            {id = "active", label = "Active (recent flow)"},
            {id = "top20", label = "Top 20 by volume"},
            {id = "all", label = "All commodities"}
        }

        love.graphics.setColor(0.15, 0.18, 0.22, 0.98)
        love.graphics.rectangle("fill", btnX, y, btnW, #filters * 20 + 4, 3, 3)
        love.graphics.setColor(0.4, 0.45, 0.5)
        love.graphics.rectangle("line", btnX, y, btnW, #filters * 20 + 4, 3, 3)

        local listY = y + 2
        love.graphics.setFont(self.fonts.tiny)
        for _, filter in ipairs(filters) do
            local isSelected = self.economyFilter == filter.id

            if isSelected then
                love.graphics.setColor(0.3, 0.4, 0.5, 0.5)
                love.graphics.rectangle("fill", btnX + 2, listY, btnW - 4, 18)
            end

            love.graphics.setColor(self.colors.text)
            love.graphics.print(filter.label, btnX + 8, listY + 2)

            table.insert(self.buttons, {
                x = btnX + 2, y = listY, w = btnW - 4, h = 18,
                onClick = function()
                    self.economyFilter = filter.id
                    self.economyFilterDropdownOpen = false
                end
            })

            listY = listY + 20
        end

        y = y + #filters * 20 + 6
    end

    return y
end

-- Render Sankey-style flow diagram
function DebugPanel:RenderSankeyDiagram(x, y, w, h)
    -- Three columns: Production | Inventory | Consumption
    local midCol = x + w / 2
    local rightCol = x + w - 50

    local sankeyData = self.economyCache.sankeyData
    local totalProd = sankeyData.totalProduction or 0
    local totalCons = sankeyData.totalConsumption or 0
    local totalStock = sankeyData.totalStock or 0

    -- Summary boxes - horizontal layout
    local boxW = 100
    local boxH = 38
    local boxY = y

    -- Production box (left)
    love.graphics.setColor(0.18, 0.28, 0.18, 0.9)
    love.graphics.rectangle("fill", x, boxY, boxW, boxH, 4, 4)
    love.graphics.setColor(0.4, 0.65, 0.4)
    love.graphics.rectangle("line", x, boxY, boxW, boxH, 4, 4)
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.5, 0.85, 0.5)
    love.graphics.print("PRODUCTION", x + 8, boxY + 3)
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.text)
    love.graphics.print(string.format("%.1f / min", totalProd), x + 8, boxY + 20)

    -- Arrow 1
    love.graphics.setColor(0.45, 0.5, 0.45, 0.7)
    love.graphics.print("->", x + boxW + 8, boxY + 12)

    -- Inventory box (center)
    local invBoxX = midCol - boxW / 2
    love.graphics.setColor(0.18, 0.22, 0.32, 0.9)
    love.graphics.rectangle("fill", invBoxX, boxY, boxW, boxH, 4, 4)
    love.graphics.setColor(0.45, 0.55, 0.75)
    love.graphics.rectangle("line", invBoxX, boxY, boxW, boxH, 4, 4)
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.6, 0.75, 0.95)
    love.graphics.print("INVENTORY", invBoxX + 10, boxY + 3)
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.text)
    love.graphics.print(string.format("%d units", totalStock), invBoxX + 10, boxY + 20)

    -- Arrow 2
    love.graphics.setColor(0.5, 0.45, 0.45, 0.7)
    love.graphics.print("->", invBoxX + boxW + 8, boxY + 12)

    -- Consumption box (right)
    local consBoxX = rightCol - boxW
    love.graphics.setColor(0.32, 0.18, 0.18, 0.9)
    love.graphics.rectangle("fill", consBoxX, boxY, boxW, boxH, 4, 4)
    love.graphics.setColor(0.75, 0.45, 0.4)
    love.graphics.rectangle("line", consBoxX, boxY, boxW, boxH, 4, 4)
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.95, 0.55, 0.5)
    love.graphics.print("CONSUMPTION", consBoxX + 5, boxY + 3)
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.text)
    love.graphics.print(string.format("%.1f / min", totalCons), consBoxX + 5, boxY + 20)

    y = boxY + boxH + 8

    -- Net flow indicator (centered, separate line)
    local netFlow = totalProd - totalCons
    love.graphics.setFont(self.fonts.tiny)
    local netText, netColor
    if netFlow > 0.1 then
        netColor = {0.4, 0.75, 0.4}
        netText = string.format("Net Flow: +%.1f/min (surplus)", netFlow)
    elseif netFlow < -0.1 then
        netColor = {0.85, 0.45, 0.4}
        netText = string.format("Net Flow: %.1f/min (deficit)", netFlow)
    else
        netColor = {0.55, 0.55, 0.55}
        netText = "Net Flow: 0.0/min (balanced)"
    end
    love.graphics.setColor(netColor)
    love.graphics.print(netText, x, y)
    y = y + 18

    -- Separator line
    love.graphics.setColor(0.3, 0.32, 0.38, 0.5)
    love.graphics.line(x, y, x + w, y)
    y = y + 8

    -- Flow diagram section header
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Active Flows (top 6 commodities):", x, y)
    y = y + 14

    -- Draw flow lines (Sankey-style)
    local flowY = y
    local commodities = self.economyCache.commodityDetails or {}
    local maxRate = 0
    for _, item in ipairs(commodities) do
        maxRate = math.max(maxRate, item.prodRate, item.consRate)
    end
    if maxRate < 1 then maxRate = 1 end

    -- Also calculate max stock for stock-based flow width when no rates
    local maxStock = 1
    for _, item in ipairs(commodities) do
        maxStock = math.max(maxStock, item.stock or 0)
    end

    -- Draw flow lines for top commodities (limit to avoid clutter)
    local flowCount = math.min(6, #commodities)
    local flowSpacing = 18

    for i = 1, flowCount do
        local item = commodities[i]
        if item then
            local yOffset = flowY + (i - 1) * flowSpacing

            -- Get category color
            local category = self:GetCommodityCategory(item.id)
            local color = self.categoryColors[category] or self.categoryColors.default

            local hasActiveFlow = item.prodRate > 0 or item.consRate > 0

            -- Commodity label with indicator dot (left side)
            love.graphics.setColor(color)
            love.graphics.circle("fill", x + 4, yOffset + 5, 3)
            love.graphics.setFont(self.fonts.tiny)
            local shortName = item.id
            if #shortName > 12 then shortName = shortName:sub(1, 10) .. ".." end
            love.graphics.print(shortName, x + 12, yOffset)

            -- Production flow bar (green)
            local prodBarX = x + 110
            local barMaxW = 80
            if item.prodRate > 0 then
                local barW = math.max(4, (item.prodRate / maxRate) * barMaxW)
                love.graphics.setColor(0.35, 0.7, 0.4, 0.85)
                love.graphics.rectangle("fill", prodBarX, yOffset + 1, barW, 8, 2, 2)
                -- Arrow tip
                love.graphics.polygon("fill", prodBarX + barW, yOffset + 5, prodBarX + barW - 4, yOffset + 1, prodBarX + barW - 4, yOffset + 9)
            end

            -- Consumption flow bar (red)
            local consBarX = x + 200
            if item.consRate > 0 then
                local barW = math.max(4, (item.consRate / maxRate) * barMaxW)
                love.graphics.setColor(0.8, 0.4, 0.35, 0.85)
                love.graphics.rectangle("fill", consBarX, yOffset + 1, barW, 8, 2, 2)
                -- Arrow tip
                love.graphics.polygon("fill", consBarX + barW, yOffset + 5, consBarX + barW - 4, yOffset + 1, consBarX + barW - 4, yOffset + 9)
            end

            -- Stock indicator (if has stock but no flow)
            if not hasActiveFlow and item.stock and item.stock > 0 then
                local stockW = math.max(4, (item.stock / maxStock) * 40)
                love.graphics.setColor(0.4, 0.5, 0.65, 0.5)
                love.graphics.rectangle("fill", prodBarX, yOffset + 1, stockW, 8, 2, 2)
            end

            -- Rate labels on the right
            love.graphics.setFont(self.fonts.tiny)
            if item.prodRate > 0 or item.consRate > 0 then
                love.graphics.setColor(self.colors.textDim)
                local rateStr = ""
                if item.prodRate > 0 then rateStr = rateStr .. "+" .. string.format("%.0f", item.prodRate) end
                if item.consRate > 0 then
                    if #rateStr > 0 then rateStr = rateStr .. " " end
                    rateStr = rateStr .. "-" .. string.format("%.0f", item.consRate)
                end
                love.graphics.print(rateStr, x + 290, yOffset)
            end
        end
    end

    return flowY + flowCount * flowSpacing + 10
end

-- Draw a Bezier curve flow line with arrow
function DebugPanel:DrawBezierFlow(x1, y1, x2, y2, width, color, showArrow)
    love.graphics.setColor(color[1], color[2], color[3], 0.6)
    love.graphics.setLineWidth(width)

    -- Simple bezier with control points for smooth S-curve
    local cx1 = x1 + (x2 - x1) * 0.35
    local cx2 = x1 + (x2 - x1) * 0.65

    local points = {}
    local lastX, lastY, secondLastX, secondLastY

    for t = 0, 1, 0.04 do
        local px = (1-t)^3 * x1 + 3*(1-t)^2*t * cx1 + 3*(1-t)*t^2 * cx2 + t^3 * x2
        local py = (1-t)^3 * y1 + 3*(1-t)^2*t * y1 + 3*(1-t)*t^2 * y2 + t^3 * y2
        table.insert(points, px)
        table.insert(points, py)
        secondLastX, secondLastY = lastX, lastY
        lastX, lastY = px, py
    end

    if #points >= 4 then
        love.graphics.line(points)
    end

    -- Draw arrowhead at the end
    if showArrow ~= false and lastX and secondLastX then
        local angle = math.atan2(lastY - secondLastY, lastX - secondLastX)
        local arrowSize = math.max(6, width * 1.5)

        love.graphics.setColor(color[1], color[2], color[3], 0.85)

        -- Arrow triangle
        local ax1 = lastX - arrowSize * math.cos(angle - 0.4)
        local ay1 = lastY - arrowSize * math.sin(angle - 0.4)
        local ax2 = lastX - arrowSize * math.cos(angle + 0.4)
        local ay2 = lastY - arrowSize * math.sin(angle + 0.4)

        love.graphics.polygon("fill", lastX, lastY, ax1, ay1, ax2, ay2)
    end

    love.graphics.setLineWidth(1)
end

-- Render commodity details table
function DebugPanel:RenderCommodityTable(x, y, w)
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.7, 0.8, 0.9)
    love.graphics.print("COMMODITY DETAILS", x, y)
    y = y + 18

    -- Column headers
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Commodity", x + 5, y)
    love.graphics.print("Prod", x + 130, y)
    love.graphics.print("Cons", x + 175, y)
    love.graphics.print("Stock", x + 220, y)
    love.graphics.print("Net", x + 270, y)

    -- Sparkline legend header
    love.graphics.setColor(0.3, 0.7, 0.35)
    love.graphics.rectangle("fill", x + 320, y + 2, 6, 6)
    love.graphics.setColor(0.8, 0.35, 0.35)
    love.graphics.rectangle("fill", x + 328, y + 2, 6, 6)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Trend", x + 338, y)
    y = y + 14

    -- Separator
    love.graphics.setColor(0.3, 0.35, 0.4)
    love.graphics.line(x, y, x + w, y)
    y = y + 4

    local commodities = self.economyCache.commodityDetails or {}

    if #commodities == 0 then
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("No commodity data available", x + 10, y)
        y = y + 20
        return y
    end

    -- Render each commodity row
    love.graphics.setFont(self.fonts.tiny)
    for i, item in ipairs(commodities) do
        if i > 30 then break end  -- Limit rows to avoid performance issues

        -- Row background (alternating)
        if i % 2 == 0 then
            love.graphics.setColor(0.15, 0.17, 0.2, 0.5)
            love.graphics.rectangle("fill", x, y - 1, w, 16)
        end

        -- Category color indicator
        local category = self:GetCommodityCategory(item.id)
        local catColor = self.categoryColors[category] or self.categoryColors.default
        love.graphics.setColor(catColor)
        love.graphics.circle("fill", x + 8, y + 6, 4)

        -- Commodity name
        love.graphics.setColor(self.colors.text)
        local displayName = item.id
        if #displayName > 16 then displayName = displayName:sub(1, 14) .. ".." end
        love.graphics.print(displayName, x + 18, y)

        -- Production rate
        love.graphics.setColor(0.5, 0.8, 0.5)
        love.graphics.print(string.format("%.1f", item.prodRate), x + 130, y)

        -- Consumption rate
        love.graphics.setColor(0.8, 0.5, 0.5)
        love.graphics.print(string.format("%.1f", item.consRate), x + 175, y)

        -- Stock
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print(string.format("%d", item.stock), x + 220, y)

        -- Net rate with surplus/deficit indicator
        local netRate = item.netRate or (item.prodRate - item.consRate)
        if netRate > 0.1 then
            love.graphics.setColor(self.colors.success)
            love.graphics.print(string.format("+%.1f", netRate), x + 270, y)
        elseif netRate < -0.1 then
            love.graphics.setColor(self.colors.error)
            love.graphics.print(string.format("%.1f", netRate), x + 270, y)
        else
            love.graphics.setColor(self.colors.textMuted)
            love.graphics.print("0.0", x + 270, y)
        end

        -- Sparkline (trend)
        local sparkData = self.economyCache.sparklineData[item.id] or {}
        self:RenderSparkline(x + 320, y + 1, 60, 12, sparkData)

        y = y + 16
    end

    return y + 10
end

-- Render dual sparkline (production + consumption as separate bars)
function DebugPanel:RenderSparkline(x, y, w, h, sparkData)
    -- Handle both old format (array) and new format (table with production/consumption)
    local prodData = {}
    local consData = {}

    if sparkData then
        if sparkData.production then
            prodData = sparkData.production
            consData = sparkData.consumption or {}
        elseif type(sparkData) == "table" and #sparkData > 0 then
            -- Fallback: old format (net values only)
            for _, val in ipairs(sparkData) do
                if val > 0 then
                    table.insert(prodData, val)
                    table.insert(consData, 0)
                else
                    table.insert(prodData, 0)
                    table.insert(consData, -val)
                end
            end
        end
    end

    local numBars = math.max(#prodData, #consData)

    if numBars == 0 then
        -- Empty placeholder with hint text
        love.graphics.setColor(0.15, 0.17, 0.2)
        love.graphics.rectangle("fill", x, y, w, h)
        love.graphics.setColor(0.3, 0.32, 0.35)
        love.graphics.setFont(self.fonts.tiny)
        love.graphics.print("--", x + w/2 - 5, y + 1)
        return
    end

    -- Background
    love.graphics.setColor(0.12, 0.14, 0.17)
    love.graphics.rectangle("fill", x, y, w, h)

    -- Find max value for scaling (across both production and consumption)
    local maxVal = 0.1
    for i = 1, numBars do
        maxVal = math.max(maxVal, prodData[i] or 0, consData[i] or 0)
    end

    -- Calculate bar dimensions
    local barGroupWidth = (w - 2) / numBars
    local barWidth = math.max(1, (barGroupWidth - 1) / 2)  -- Two bars per slot

    -- Draw bars for each time period
    for i = 1, numBars do
        local groupX = x + 1 + (i - 1) * barGroupWidth
        local prod = prodData[i] or 0
        local cons = consData[i] or 0

        -- Production bar (green, left side of each slot)
        if prod > 0 then
            local barH = math.max(1, (prod / maxVal) * (h - 2))
            love.graphics.setColor(0.3, 0.7, 0.35, 0.9)
            love.graphics.rectangle("fill", groupX, y + h - 1 - barH, barWidth, barH)
        end

        -- Consumption bar (red, right side of each slot)
        if cons > 0 then
            local barH = math.max(1, (cons / maxVal) * (h - 2))
            love.graphics.setColor(0.8, 0.35, 0.35, 0.9)
            love.graphics.rectangle("fill", groupX + barWidth, y + h - 1 - barH, barWidth, barH)
        end
    end

    -- Subtle baseline
    love.graphics.setColor(0.3, 0.32, 0.35, 0.4)
    love.graphics.line(x, y + h - 1, x + w, y + h - 1)
end

-- Get commodity category for coloring
function DebugPanel:GetCommodityCategory(commodityId)
    -- Try to get category from fulfillment vectors if available
    if self.world and self.world.fulfillmentVectors and self.world.fulfillmentVectors.commodities then
        local commodityData = self.world.fulfillmentVectors.commodities[commodityId]
        if commodityData and commodityData.category then
            return commodityData.category
        end
    end

    -- Fallback: infer from commodity name
    local id = commodityId:lower()
    if id:find("wheat") or id:find("bread") or id:find("meat") or id:find("food") or id:find("vegetable") or id:find("fruit") or id:find("grain") then
        return "biological"
    elseif id:find("cloth") or id:find("wool") or id:find("cotton") or id:find("textile") or id:find("leather") then
        return "touch"
    elseif id:find("tool") or id:find("weapon") or id:find("medicine") or id:find("armor") then
        return "safety"
    elseif id:find("book") or id:find("art") or id:find("music") or id:find("paint") then
        return "psychological"
    elseif id:find("gold") or id:find("silver") or id:find("gem") or id:find("jewel") then
        return "shiny_objects"
    elseif id:find("wine") or id:find("beer") or id:find("spice") or id:find("silk") or id:find("exotic") then
        return "exotic_goods"
    elseif id:find("furniture") or id:find("luxury") or id:find("fine") then
        return "social_status"
    elseif id:find("tobacco") or id:find("alcohol") then
        return "vice"
    else
        return "utility"
    end
end

-- =============================================================================
-- EVENTS TAB
-- =============================================================================
function DebugPanel:RenderEventsTab(x, startY, w)
    local y = startY + 10

    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.6, 0.7, 0.8)
    love.graphics.print("EVENT LOG (Last 50)", x, y)
    y = y + 22

    local eventLog = (self.world and self.world.eventLog) or {}

    if #eventLog == 0 then
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("No events recorded yet", x, y)
        y = y + 20
    else
        love.graphics.setFont(self.fonts.tiny)

        local startIdx = math.max(1, #eventLog - 49)
        for i = #eventLog, startIdx, -1 do
            local event = eventLog[i]

            -- Color by event type
            local eventColor = self.colors.text
            if event.type == "error" or event.type == "emigration" then
                eventColor = self.colors.error
            elseif event.type == "warning" or event.type == "shortage" then
                eventColor = self.colors.warning
            elseif event.type == "success" or event.type == "immigration" then
                eventColor = self.colors.success
            end

            love.graphics.setColor(eventColor)
            local timeStr = event.time or event.day or "?"
            local msg = event.message or event.details or "Unknown event"
            love.graphics.print(string.format("[%s] %s", tostring(timeStr), msg), x, y)
            y = y + 12
        end
    end

    self.maxScroll = math.max(0, y - startY - (self.height - 80))
end

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

function DebugPanel:RenderButton(text, x, y, w, h, onClick, color)
    local mx, my = love.mouse.getPosition()
    local isHover = mx >= x and mx <= x + w and my >= y and my <= y + h

    color = color or {0.3, 0.4, 0.5}

    if isHover then
        love.graphics.setColor(color[1] + 0.1, color[2] + 0.1, color[3] + 0.1)
    else
        love.graphics.setColor(color[1], color[2], color[3])
    end
    love.graphics.rectangle("fill", x, y, w, h, 2, 2)

    love.graphics.setColor(0.5, 0.6, 0.7)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, w, h, 2, 2)

    love.graphics.setColor(1, 1, 1)
    local font = love.graphics.getFont()
    local textW = font:getWidth(text)
    local textH = font:getHeight()
    love.graphics.print(text, x + (w - textW) / 2, y + (h - textH) / 2 + 1)

    -- Store for click handling
    table.insert(self.buttons, {x = x, y = y, w = w, h = h, onClick = onClick})
end

function DebugPanel:HandleMousePress(x, y, button)
    if not self.visible then return false end
    if button ~= 1 then return false end

    -- Check button clicks FIRST (before drag handling)
    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and
           y >= btn.y and y <= btn.y + btn.h then
            if btn.onClick then
                btn.onClick()
            end
            return true
        end
    end

    -- Check if clicking header (drag handle) - only if no button was clicked
    if y >= self.y and y <= self.y + 35 and
       x >= self.x and x <= self.x + self.width then
        self.isDragging = true
        self.dragOffsetX = x - self.x
        self.dragOffsetY = y - self.y
        return true
    end

    -- Check if click is within panel bounds (consume event)
    local panelHeight = self.collapsed and self.collapsedHeight or self.height
    if x >= self.x and x <= self.x + self.width and
       y >= self.y and y <= self.y + panelHeight then
        return true
    end

    return false
end

function DebugPanel:HandleMouseRelease(x, y, button)
    if not self.visible then return false end

    if button == 1 and self.isDragging then
        self.isDragging = false
        return true
    end

    return false
end

function DebugPanel:HandleMouseMove(x, y)
    if not self.visible then return false end

    -- Check if mouse button is still held - if not, stop dragging
    if self.isDragging then
        if not love.mouse.isDown(1) then
            self.isDragging = false
            return false
        end

        self.x = x - self.dragOffsetX
        self.y = y - self.dragOffsetY
        return true
    end

    return false
end

function DebugPanel:HandleMouseWheel(dx, dy)
    if not self.visible or self.collapsed then return false end

    -- Check if mouse is over panel
    local mx, my = love.mouse.getPosition()
    if mx >= self.x and mx <= self.x + self.width and
       my >= self.y and my <= self.y + self.height then
        self.scrollOffset = math.max(0, math.min(self.maxScroll, self.scrollOffset - dy * 30))
        return true
    end

    return false
end

function DebugPanel:HandleKeyPress(key)
    if not self.visible then return false end

    if key == "escape" then
        self:Hide()
        return true
    end

    return false
end

return DebugPanel
