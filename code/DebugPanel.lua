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
    panel.collapsed = true  -- Start collapsed
    panel.currentTab = "overview"  -- "overview", "citizens", "buildings", "economy", "events"

    -- Panel position and dimensions
    panel.x = love.graphics.getWidth() - 420  -- Right side of screen
    panel.y = 60  -- Below top bar
    panel.width = 400
    panel.height = math.min(700, love.graphics.getHeight() - 100)  -- Adaptive height
    panel.collapsedHeight = 45

    -- Dragging state
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

    -- Tab definitions
    panel.tabs = {
        {id = "overview", label = "Overview", icon = "📊"},
        {id = "citizens", label = "Citizens", icon = "👥"},
        {id = "buildings", label = "Buildings", icon = "🏛️"},
        {id = "economy", label = "Economy", icon = "💰"},
        {id = "events", label = "Events", icon = "📝"}
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
    if not self.visible then return end

    self:InitFonts()
    self.buttons = {}

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Ensure panel stays within screen bounds
    self.x = math.max(0, math.min(self.x, screenW - self.width))
    self.y = math.max(0, math.min(self.y, screenH - (self.collapsed and self.collapsedHeight or self.height)))

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
        elseif self.currentTab == "citizens" then
            self:RenderCitizensTab(self.x + 10, contentY - self.scrollOffset, self.width - 20)
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

    -- Buttons in header
    local btnY = self.y + 7
    local btnH = 22

    -- Expand/Collapse button
    local expandLabel = self.collapsed and "Expand" or "Collapse"
    local expandIcon = self.collapsed and "▼" or "▲"
    self:RenderButton(expandIcon .. " " .. expandLabel, self.x + self.width - 120, btnY, 75, btnH, function()
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
        love.graphics.setFont(self.fonts.tiny)
        local textColor = isActive and self.colors.text or self.colors.textDim
        love.graphics.setColor(textColor)
        local text = tab.icon .. " " .. tab.label
        local textW = self.fonts.tiny:getWidth(text)
        love.graphics.print(text, tabX + (tabW - textW) / 2, tabY + 10)

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

    -- Set max scroll
    self.maxScroll = math.max(0, y - startY - (self.height - 80))
end

-- =============================================================================
-- CITIZENS TAB
-- =============================================================================
function DebugPanel:RenderCitizensTab(x, startY, w)
    local y = startY + 10

    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.4, 0.7, 0.9)
    love.graphics.print("CITIZENS LIST", x, y)
    y = y + 20

    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Click a citizen to view details", x, y)
    y = y + 18

    local citizens = (self.world and self.world.citizens) or {}

    if #citizens == 0 then
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("No citizens yet", x, y)
        y = y + 20
    else
        -- Sort by satisfaction (lowest first to highlight issues)
        local sortedCitizens = {}
        for _, citizen in ipairs(citizens) do
            table.insert(sortedCitizens, citizen)
        end
        table.sort(sortedCitizens, function(a, b)
            local satA = a.GetAverageSatisfaction and a:GetAverageSatisfaction() or 50
            local satB = b.GetAverageSatisfaction and b:GetAverageSatisfaction() or 50
            return satA < satB
        end)

        love.graphics.setFont(self.fonts.small)
        for i, citizen in ipairs(sortedCitizens) do
            local avgSat = citizen.GetAverageSatisfaction and citizen:GetAverageSatisfaction() or 50

            -- Satisfaction color indicator
            local satColor = avgSat >= 60 and {0.3, 0.7, 0.3} or
                            (avgSat >= 30 and {0.7, 0.7, 0.3} or {0.7, 0.3, 0.3})
            love.graphics.setColor(satColor)
            love.graphics.circle("fill", x + 5, y + 6, 4)

            -- Citizen name and class
            love.graphics.setColor(self.colors.text)
            love.graphics.print(citizen.name or "Unknown", x + 15, y)

            love.graphics.setColor(self.colors.textDim)
            love.graphics.print(string.format("[%s]", citizen.class or "?"), x + 150, y)

            -- Satisfaction value
            love.graphics.setColor(satColor)
            love.graphics.print(string.format("%.0f%%", avgSat), x + 220, y)

            -- Make clickable - show in console for now
            local btnY = y - 2
            table.insert(self.buttons, {
                x = x, y = btnY, w = w - 10, h = 14,
                onClick = function()
                    -- TODO: Integrate with CharacterDetailPanel if available
                    print("Debug: Selected citizen:", citizen.name, "Satisfaction:", avgSat)
                end
            })

            y = y + 16
        end
    end

    self.maxScroll = math.max(0, y - startY - (self.height - 80))
end

-- =============================================================================
-- BUILDINGS TAB
-- =============================================================================
function DebugPanel:RenderBuildingsTab(x, startY, w)
    local y = startY + 10

    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.8, 0.6, 0.4)
    love.graphics.print("BUILDINGS", x, y)
    y = y + 22

    local buildings = (self.world and self.world.buildings) or {}

    if #buildings == 0 then
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("No buildings yet", x, y)
        y = y + 20
    else
        -- Count by category
        local categories = {}
        for _, building in ipairs(buildings) do
            local cat = (building.type and building.type.category) or "unknown"
            categories[cat] = (categories[cat] or 0) + 1
        end

        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Building Count by Category:", x, y)
        y = y + 16

        for cat, count in pairs(categories) do
            love.graphics.setColor(self.colors.text)
            love.graphics.print(string.format("  %s: %d", cat, count), x, y)
            y = y + 14
        end
        y = y + 10

        -- Production status summary
        love.graphics.setFont(self.fonts.header)
        love.graphics.setColor(0.6, 0.7, 0.8)
        love.graphics.print("PRODUCTION STATUS", x, y)
        y = y + 18

        local producing = 0
        local idle = 0
        local noMaterials = 0
        local noWorkers = 0

        for _, building in ipairs(buildings) do
            if building.stations then
                for _, station in ipairs(building.stations) do
                    if station.state == "PRODUCING" then
                        producing = producing + 1
                    elseif station.state == "IDLE" then
                        idle = idle + 1
                    elseif station.state == "NO_MATERIALS" then
                        noMaterials = noMaterials + 1
                    elseif station.state == "NO_WORKER" then
                        noWorkers = noWorkers + 1
                    end
                end
            end
        end

        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.success)
        love.graphics.print(string.format("Producing: %d", producing), x, y)
        y = y + 14

        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print(string.format("Idle: %d", idle), x, y)
        y = y + 14

        love.graphics.setColor(self.colors.warning)
        love.graphics.print(string.format("No Materials: %d", noMaterials), x, y)
        y = y + 14

        love.graphics.setColor(self.colors.error)
        love.graphics.print(string.format("No Workers: %d", noWorkers), x, y)
        y = y + 20
    end

    self.maxScroll = math.max(0, y - startY - (self.height - 80))
end

-- =============================================================================
-- ECONOMY TAB
-- =============================================================================
function DebugPanel:RenderEconomyTab(x, startY, w)
    local y = startY + 10

    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.print("ECONOMY", x, y)
    y = y + 22

    local gold = (self.world and self.world.gold) or 0

    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Town Gold:", x, y)
    love.graphics.setColor(0.9, 0.8, 0.4)
    love.graphics.print(string.format("%d", gold), x + 100, y)
    y = y + 20

    -- Wealth distribution (if economySystem available)
    if self.world and self.world.economySystem then
        love.graphics.setFont(self.fonts.header)
        love.graphics.setColor(0.7, 0.7, 0.9)
        love.graphics.print("WEALTH DISTRIBUTION", x, y)
        y = y + 18

        -- TODO: Calculate wealth distribution from economySystem
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("Wealth analysis coming soon", x, y)
        y = y + 20
    else
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("Economy system not initialized", x, y)
        y = y + 20
    end

    self.maxScroll = math.max(0, y - startY - (self.height - 80))
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

    -- Check if clicking header (drag handle)
    if button == 1 and y >= self.y and y <= self.y + 35 and
       x >= self.x and x <= self.x + self.width then
        self.isDragging = true
        self.dragOffsetX = x - self.x
        self.dragOffsetY = y - self.y
        return true
    end

    -- Check button clicks
    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and
           y >= btn.y and y <= btn.y + btn.h then
            if btn.onClick then
                btn.onClick()
            end
            return true
        end
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
    if not self.visible or not self.isDragging then return false end

    self.x = x - self.dragOffsetX
    self.y = y - self.dragOffsetY

    return true
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
