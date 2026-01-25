--
-- AlphaUI.lua
-- UI rendering for Alpha Prototype
-- Birthday Edition for Mansi
--
-- Layout following game_ui_flow_specification.md:
-- - Top Bar: Town info, population, gold, time, speed controls
-- - Left Panel: Quick stats, alerts, mini-map, quick build
-- - Center: World view with citizens and buildings
-- - Right Panel: Selected entity details
-- - Bottom Bar: Event log
--

local DataLoader = require("code/DataLoader")
local SaveLoadModal = require("code.SaveLoadModal")
local ResourceOverlay = require("code.ResourceOverlay")
local GameSettings = require("code.GameSettings")
local CharacterV3 = require("code.consumption.CharacterV3")
local PlotSelectionModal = require("code.PlotSelectionModal")
local SuggestedBuildingsModal = require("code.SuggestedBuildingsModal")

-- Phase 8: New UI panels for ownership/housing system
local LandOverlayModule = require("code.LandOverlay")
local LandRegistryPanel = require("code.LandRegistryPanel")
local HousingOverviewPanel = require("code.HousingOverviewPanel")
local HousingAssignmentModal = require("code.HousingAssignmentModal")
local CharacterDetailPanel = require("code.CharacterDetailPanel")

-- CRAVE-6: Debug Panel
local DebugPanel = require("code.DebugPanel")

-- Day End Summary Modal
local DayEndSummaryModal = require("code.DayEndSummaryModal")

-- Supply Chain Viewer
local SupplyChainViewer = require("code.SupplyChainViewer")

-- New systems: Notifications, Tutorial, Visual indicators
local NotificationSystem = require("code.NotificationSystem")
local TutorialSystem = require("code.TutorialSystem")

-- Cheat Console
local CheatConsole = require("code.CheatConsole")

AlphaUI = {}
AlphaUI.__index = AlphaUI

function AlphaUI:Create(world)
    local ui = setmetatable({}, AlphaUI)

    ui.world = world

    -- Layout dimensions
    ui.topBarHeight = 60
    ui.bottomBarHeight = 120
    ui.leftPanelWidth = 220
    ui.rightPanelWidth = 280

    -- Fonts
    ui.fonts = {
        title = love.graphics.newFont(24),
        header = love.graphics.newFont(18),
        normal = love.graphics.newFont(14),
        small = love.graphics.newFont(12),
        tiny = love.graphics.newFont(10)
    }

    -- Colors
    ui.colors = {
        topBar = {0.15, 0.15, 0.2, 0.95},
        leftPanel = {0.12, 0.12, 0.15, 0.9},
        rightPanel = {0.12, 0.12, 0.15, 0.9},
        bottomBar = {0.1, 0.1, 0.12, 0.9},
        text = {1, 1, 1},
        textDim = {0.7, 0.7, 0.7},
        accent = {0.4, 0.7, 1.0},
        gold = {1.0, 0.85, 0.3},
        success = {0.4, 0.8, 0.4},
        warning = {1.0, 0.7, 0.3},
        danger = {1.0, 0.4, 0.4},
        button = {0.25, 0.25, 0.3},
        buttonHover = {0.35, 0.35, 0.4},
        satisfactionHigh = {0.4, 0.8, 0.4},
        satisfactionMed = {0.9, 0.8, 0.3},
        satisfactionLow = {0.9, 0.4, 0.4},
        -- Terrain colors
        grass = {0.35, 0.55, 0.3},
        grassDark = {0.3, 0.45, 0.25},
        water = {0.3, 0.5, 0.7},
        path = {0.55, 0.5, 0.4}
    }

    -- UI State
    ui.hoveredButton = nil
    ui.eventLogScrollOffset = 0
    ui.showBuildMenu = false
    ui.buildMenuCategory = "all"
    ui.eventLogFilter = "all"  -- Event log filter: all, production, consumption, immigration

    -- Camera for world view
    ui.cameraX = 0
    ui.cameraY = 0
    ui.cameraZoom = 1.0

    -- World grid settings
    ui.gridSize = 50
    -- World dimensions synced from actual world
    ui.worldWidth = world.worldWidth or 1600
    ui.worldHeight = world.worldHeight or 1200

    -- Mini-map settings
    ui.minimapWidth = 180
    ui.minimapHeight = 100

    -- Quick build buttons
    ui.quickBuildButtons = {}

    -- Top bar action buttons
    ui.topBarButtons = {}

    -- Building placement mode
    ui.placementMode = false
    ui.placementBuildingType = nil
    ui.placementX = 0
    ui.placementY = 0
    ui.placementValid = false
    ui.placementEfficiency = 1.0
    ui.placementBreakdown = {}
    ui.placementErrors = {}

    -- Debug: Spawn citizen mode (press 'C' to toggle, click to spawn)
    ui.spawnCitizenMode = false

    -- Build menu modal
    ui.showBuildMenuModal = false
    ui.buildMenuScrollOffset = 0
    ui.buildMenuSearchQuery = ""
    ui.buildMenuSearchActive = false

    -- Resource overlay (using full ResourceOverlay system with panel)
    ui.showResourceOverlay = false
    ui.resourceOverlay = nil
    if world.naturalResources then
        ui.resourceOverlay = ResourceOverlay:Create(world.naturalResources)
        -- Position panel on left side, below top bar
        ui.resourceOverlay:setPanelPosition(10, 70)
    end

    -- Immigration panel state
    ui.showImmigrationModal = false
    ui.selectedApplicant = nil
    ui.immigrationScrollOffset = 0

    -- Plot selection modal state (for land purchase during immigration)
    ui.showPlotSelectionModal = false
    ui.plotSelectionModal = nil
    ui.pendingImmigrantApplicant = nil  -- Applicant waiting for plot selection

    -- Land distribution overlay state
    ui.showLandOverlay = false
    ui.landOverlay = LandOverlayModule:Create(world)

    -- Land registry panel state
    ui.showLandRegistryPanel = false
    ui.landRegistryPanel = LandRegistryPanel:Create(world)

    -- Housing assignment modal state
    ui.showHousingAssignmentModal = false
    ui.housingAssignmentModal = HousingAssignmentModal:Create(world,
        function(citizenIds, buildingId)  -- onComplete callback
            -- Assign all selected citizens to the building
            if world.housingSystem and citizenIds and buildingId then
                for _, citizenId in ipairs(citizenIds) do
                    world.housingSystem:AssignHousing(citizenId, buildingId)
                    print("[AlphaUI] Assigned citizen " .. citizenId .. " to housing " .. buildingId)
                end
            end
            ui.showHousingAssignmentModal = false
        end,
        function()  -- onCancel callback
            ui.showHousingAssignmentModal = false
        end
    )

    -- Housing overview panel state
    ui.showHousingOverviewPanel = false
    ui.housingOverviewPanel = HousingOverviewPanel:Create(world,
        function()  -- onAssignClick callback
            print("[AlphaUI] onAssignClick callback triggered!")
            print("[AlphaUI] ui.housingAssignmentModal = " .. tostring(ui.housingAssignmentModal))
            ui.showHousingAssignmentModal = true
            print("[AlphaUI] Set showHousingAssignmentModal = true")
            if ui.housingAssignmentModal then
                print("[AlphaUI] Calling housingAssignmentModal:Show()")
                ui.housingAssignmentModal:Show()
            end
        end,
        function()  -- onQueueClick callback
            -- TODO: Show relocation queue modal
            print("[AlphaUI] View Queue clicked - not yet implemented")
        end
    )

    -- Character detail panel state
    ui.characterDetailPanel = CharacterDetailPanel:Create(world)

    -- Debug panel state (CRAVE-6)
    ui.debugPanel = DebugPanel:Create(world)

    -- Supply chain viewer (shows commodity production DAGs)
    ui.supplyChainViewer = SupplyChainViewer:Create(world)
    -- Make globally accessible for InventoryDrawer
    gSupplyChainViewer = ui.supplyChainViewer

    -- Notification system
    ui.notificationSystem = NotificationSystem:Create(world)
    world.notificationSystem = ui.notificationSystem  -- Make accessible from world

    -- Tutorial system
    ui.tutorialSystem = TutorialSystem:Create(world)
    world.tutorialSystem = ui.tutorialSystem  -- Make accessible from world

    -- Suggested buildings modal state (for elite immigrants after land purchase)
    ui.showSuggestedBuildingsModal = false
    ui.suggestedBuildingsModal = nil
    ui.suggestedBuildingsCitizen = nil  -- Citizen the modal is for

    -- Help overlay state
    ui.showHelpOverlay = false

    -- Citizens panel state
    ui.showCitizensPanel = false
    ui.citizensScrollOffset = 0
    ui.citizensMaxScroll = 0
    ui.citizensFilter = "all"            -- all, elite, upper, middle, lower
    ui.citizensStatusFilter = "all"      -- all, happy, neutral, stressed, critical, protesting
    ui.citizensSort = "satisfaction"      -- satisfaction, name, class, age, vocation
    ui.citizensSortAsc = false           -- false = descending (lowest satisfaction first for urgency)
    ui.citizensViewMode = "grid"         -- grid, list
    ui.citizensPage = 1
    ui.citizensPerPage = 20
    ui.citizensCloseBtn = nil
    ui.citizensFilterBtns = {}
    ui.citizensStatusFilterBtns = {}
    ui.citizensSortBtns = {}
    ui.citizensViewBtns = {}
    ui.citizensCardBtns = {}
    ui.citizensPrevPageBtn = nil
    ui.citizensNextPageBtn = nil
    ui.selectedCitizenForModal = nil

    -- Analytics panel state
    ui.showAnalyticsPanel = false
    ui.analyticsTab = "overview"

    -- Production Analytics panel state
    ui.showProductionAnalyticsPanel = false
    ui.productionAnalyticsTab = "commodities"  -- commodities, buildings
    ui.productionAnalyticsScrollOffset = 0
    ui.productionAnalyticsMaxScroll = 0
    ui.selectedAnalyticsCommodity = nil
    ui.productionAnalyticsCloseBtn = nil
    ui.productionAnalyticsTabBtns = {}
    ui.productionAnalyticsCommodityBtns = {}

    -- Inventory panel state
    ui.showInventoryPanel = false
    ui.inventoryScrollOffset = 0
    ui.inventoryCategoryScrollOffset = 0
    ui.inventoryCategoryMaxScroll = 0
    ui.inventoryFilter = "all"
    ui.inventoryCategories = nil  -- Will be built dynamically from commodity data
    ui.inventoryMaxScroll = 0
    ui.inventoryCloseBtn = nil
    ui.inventoryCategoryBtns = {}
    ui.inventoryItemBtns = {}
    ui.inventoryCategoryArea = nil  -- Store area for scroll detection

    -- Save/Load modal state
    ui.showSaveLoadModal = false
    ui.saveLoadModal = nil
    ui.onLoadGame = nil  -- Callback for loading a game

    -- Building modal state (for detailed building management)
    ui.showBuildingModal = false
    ui.buildingModalScrollOffset = 0
    ui.buildingModalScrollMax = 0
    ui.selectedBuildingForModal = nil

    -- Recipe picker modal state
    ui.showRecipeModal = false
    ui.recipeModalScrollOffset = 0
    ui.recipeModalScrollMax = 0
    ui.selectedStation = nil
    ui.modalJustOpened = false

    -- Settings panel state
    ui.showSettingsPanel = false
    ui.settingsTab = "gameplay"  -- gameplay, display, audio, accessibility
    ui.settingsScrollOffset = 0
    ui.settingsMaxScroll = 0
    ui.settingsCloseBtn = nil
    ui.settingsTabBtns = {}
    ui.settingsControls = {}
    ui.gameSettings = GameSettings:GetInstance()

    -- Emigration warning panel state
    ui.showEmigrationPanel = false
    ui.emigrationScrollOffset = 0
    ui.emigrationMaxScroll = 0
    ui.emigrationCloseBtn = nil
    ui.emigrationCitizenBtns = {}
    ui.emigrationPrioritizeBtns = {}

    -- Cheat console state
    ui.showCheatConsole = false
    ui.cheatConsoleInput = ""
    ui.cheatConsoleHistory = {}  -- {input, output} pairs
    ui.cheatConsoleHistoryMax = 20
    ui.cheatConsoleCursorVisible = true
    ui.cheatConsoleCursorTimer = 0
    ui.cheatConsoleScrollOffset = 0

    -- Day End Summary Modal state
    ui.showDayEndSummaryModal = false
    ui.dayEndSummaryModal = nil

    return ui
end

-- =============================================================================
-- MAIN RENDER
-- =============================================================================

function AlphaUI:Render()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Apply day/night tint to background
    local r, g, b = self.world:GetDayNightColor()
    love.graphics.clear(r * 0.2, g * 0.2, b * 0.25)

    -- Render world view (center area)
    self:RenderWorldView()

    -- Render UI panels (dimmed if in placement mode)
    if self.placementMode then
        love.graphics.setColor(0.7, 0.7, 0.7)
    end
    self:RenderTopBar()
    self:RenderLeftPanel()

    -- Right panel shows placement info during placement mode
    if self.placementMode then
        love.graphics.setColor(1, 1, 1)
        self:RenderPlacementPanel()
    else
        self:RenderRightPanel()
    end

    self:RenderBottomBar()

    -- Render build menu modal on top
    if self.showBuildMenuModal then
        self:RenderBuildMenuModal()
    end

    -- Render immigration modal on top
    if self.showImmigrationModal then
        self:RenderImmigrationModal()
    end

    -- Render plot selection modal on top of immigration modal
    if self.showPlotSelectionModal and self.plotSelectionModal then
        self.plotSelectionModal:Render()
    end

    -- Render suggested buildings modal (for elite immigrants after land purchase)
    if self.showSuggestedBuildingsModal and self.suggestedBuildingsModal then
        self.suggestedBuildingsModal:Render()
    end

    -- Render placement mode instructions
    if self.placementMode then
        self:RenderPlacementInstructions()
    end

    -- Render spawn citizen mode indicator
    if self.spawnCitizenMode then
        self:RenderSpawnCitizenModeIndicator()
    end

    -- Render resource overlay panel (screen space, not world space)
    if self.showResourceOverlay and self.resourceOverlay then
        self.resourceOverlay:renderPanel()
    end

    -- Render land registry panel
    if self.showLandRegistryPanel and self.landRegistryPanel then
        self.landRegistryPanel:Render()
    end

    -- Render housing overview panel
    if self.showHousingOverviewPanel and self.housingOverviewPanel then
        self.housingOverviewPanel:Render()
    end

    -- Render housing assignment modal
    if self.showHousingAssignmentModal and self.housingAssignmentModal then
        self.housingAssignmentModal:Render()
    end

    -- Render inventory panel
    if self.showInventoryPanel then
        self:RenderInventoryPanel()
    end

    -- Render citizens panel
    if self.showCitizensPanel then
        self:RenderCitizensPanel()
    end

    -- Render production analytics panel
    if self.showProductionAnalyticsPanel then
        self:RenderProductionAnalyticsPanel()
    end

    -- Render settings panel
    if self.showSettingsPanel then
        self:RenderSettingsPanel()
    end

    -- Render emigration warning panel
    if self.showEmigrationPanel then
        self:RenderEmigrationPanel()
    end

    -- Render building modal (detailed building management)
    if self.showBuildingModal and self.selectedBuildingForModal then
        self:RenderBuildingModal()
    end

    -- Render recipe picker modal (on top of building modal)
    if self.showRecipeModal and self.selectedBuildingForModal then
        self:RenderRecipeModal()
    end

    -- Render character detail panel (on top of citizens panel)
    if self.characterDetailPanel and self.characterDetailPanel:IsVisible() then
        self.characterDetailPanel:Render()
    end

    -- Render help overlay on top of everything
    if self.showHelpOverlay then
        self:RenderHelpOverlay()
    end

    -- Render save/load modal on top of everything
    if self.showSaveLoadModal and self.saveLoadModal then
        self.saveLoadModal:Render()
    end

    -- Render day end summary modal (on top of most things)
    if self.showDayEndSummaryModal and self.dayEndSummaryModal then
        self.dayEndSummaryModal:Render()
    end

    -- Render notification toasts (almost on top)
    if self.notificationSystem then
        self.notificationSystem:Render()
    end

    -- Render debug panel (CRAVE-6) - always render toggle button, panel when visible
    if self.debugPanel then
        self.debugPanel:Render()
    end

    -- Render supply chain viewer (on top of most things)
    if self.supplyChainViewer and self.supplyChainViewer.isVisible then
        self.supplyChainViewer:Render()
    end

    -- Render cheat console (on top of most things)
    if self.showCheatConsole then
        self:RenderCheatConsole()
    end

    -- Render tutorial overlay (on very top)
    if self.tutorialSystem and self.tutorialSystem:IsActive() then
        self.tutorialSystem:Render()
    end
end

-- =============================================================================
-- TOP BAR
-- =============================================================================

function AlphaUI:RenderTopBar()
    local screenW = love.graphics.getWidth()
    local h = self.topBarHeight

    -- Background
    love.graphics.setColor(self.colors.topBar)
    love.graphics.rectangle("fill", 0, 0, screenW, h)

    -- Border
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.rectangle("line", 0, 0, screenW, h)

    -- Town name
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.text)
    love.graphics.print(self.world.townName, 15, 10)

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Est. Day 1", 15, 32)

    -- Population
    local popX = 180
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Pop: " .. self.world.stats.totalPopulation, popX, 12)

    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Housing: " .. self.world.stats.housingCapacity, popX, 32)

    -- Gold
    local goldX = 300
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.gold)
    love.graphics.print("Gold: " .. self.world.gold, goldX, 12)

    -- Day and Time (using TimeManager via world)
    local timeX = 400
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    local slot = self.world:GetCurrentSlot()
    local slotName = slot and slot.name or "???"
    love.graphics.print("Day " .. self.world:GetDayNumber() .. " - " .. slotName, timeX, 12)

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.accent)
    love.graphics.print(self.world:GetTimeString(), timeX, 32)

    -- Speed controls
    local speedX = screenW - 200
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)

    -- Pause/Play button
    local pauseText = self.world.isPaused and "[PAUSED]" or "[PLAYING]"
    local pauseColor = self.world.isPaused and self.colors.warning or self.colors.success
    love.graphics.setColor(pauseColor)
    love.graphics.print(pauseText, speedX, 12)

    -- Speed selector
    love.graphics.setFont(self.fonts.small)
    local speeds = {"normal", "fast", "faster", "fastest", "turbo"}
    local speedLabels = {"1x", "2x", "5x", "10x", "20x"}
    local speedBtnSpacing = 30  -- Spacing between speed buttons
    local currentSpeed = self.world.timeManager.currentSpeed
    for i, speed in ipairs(speeds) do
        local bx = speedX + (i - 1) * speedBtnSpacing
        local by = 32
        local isActive = currentSpeed == speed

        if isActive then
            love.graphics.setColor(self.colors.accent)
        else
            love.graphics.setColor(self.colors.textDim)
        end
        love.graphics.print(speedLabels[i], bx, by)
    end

    -- Top bar action buttons
    local btnY = 8
    local btnH = 32
    local btnSpacing = 8
    local btnStartX = 620
    love.graphics.setFont(self.fonts.small)

    local topBarButtons = {
        {id = "production", label = "Production", shortcut = "P"},
        {id = "build", label = "Build", shortcut = "B"},
        {id = "citizens", label = "Citizens", shortcut = "C"},
        {id = "inventory", label = "Inventory", shortcut = "I"},
        {id = "settings", label = "Settings", shortcut = "O"},
        {id = "help", label = "Help", shortcut = "H"}
    }

    self.topBarButtons = {}
    local btnX = btnStartX

    for _, btn in ipairs(topBarButtons) do
        local btnW = self.fonts.small:getWidth(btn.label) + 20
        local mx, my = love.mouse.getPosition()
        local isHovering = mx >= btnX and mx < btnX + btnW and my >= btnY and my < btnY + btnH

        -- Check if this panel is active
        local isActive = false
        if btn.id == "production" then isActive = self.showProductionAnalyticsPanel
        elseif btn.id == "build" then isActive = self.showBuildMenuModal
        elseif btn.id == "citizens" then isActive = self.showCitizensPanel
        elseif btn.id == "inventory" then isActive = self.showInventoryPanel
        elseif btn.id == "help" then isActive = self.showHelpOverlay
        end

        -- Button background
        if isActive then
            love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.6)
        elseif isHovering then
            love.graphics.setColor(0.35, 0.35, 0.4)
        else
            love.graphics.setColor(0.25, 0.25, 0.3)
        end
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)

        -- Button text
        love.graphics.setColor(isActive and {1, 1, 1} or self.colors.text)
        local textX = btnX + (btnW - self.fonts.small:getWidth(btn.label)) / 2
        love.graphics.print(btn.label, textX, btnY + 8)

        -- Store button bounds for click handling
        self.topBarButtons[btn.id] = {x = btnX, y = btnY, w = btnW, h = btnH}

        btnX = btnX + btnW + btnSpacing
    end

    love.graphics.setColor(1, 1, 1)
end

-- =============================================================================
-- LEFT PANEL
-- =============================================================================

function AlphaUI:RenderLeftPanel()
    local screenH = love.graphics.getHeight()
    local x = 0
    local y = self.topBarHeight
    local w = self.leftPanelWidth
    local h = screenH - self.topBarHeight - self.bottomBarHeight

    -- Background
    love.graphics.setColor(self.colors.leftPanel)
    love.graphics.rectangle("fill", x, y, w, h)

    -- Border
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.rectangle("line", x, y, w, h)

    local contentY = y + 10

    -- Quick Stats section
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Quick Stats", x + 10, contentY)
    contentY = contentY + 25

    -- Overall happiness
    love.graphics.setFont(self.fonts.normal)
    local avgSat = self.world.stats.averageSatisfaction
    local satColor = avgSat > 70 and self.colors.satisfactionHigh or
                     (avgSat > 40 and self.colors.satisfactionMed or self.colors.satisfactionLow)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Happiness:", x + 10, contentY)
    love.graphics.setColor(satColor)
    love.graphics.print(string.format("%.0f%%", avgSat), x + 100, contentY)
    contentY = contentY + 20

    -- Happiness bar
    self:RenderProgressBar(x + 10, contentY, w - 20, 12, avgSat / 100, satColor)
    contentY = contentY + 25

    -- By class (compact)
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("By Class:", x + 10, contentY)
    contentY = contentY + 14

    -- Get classes from data
    local classesData = self.world.characterClasses and self.world.characterClasses.classes or {}
    for _, classInfo in ipairs(classesData) do
        local classId = classInfo.id or ""
        local className = classInfo.name or classId
        local classSat = self.world.stats.satisfactionByClass[classId] or 0
        local classColor = classSat > 70 and self.colors.satisfactionHigh or
                          (classSat > 40 and self.colors.satisfactionMed or self.colors.satisfactionLow)

        love.graphics.setColor(self.colors.textDim)
        love.graphics.print(className .. ":", x + 10, contentY)
        love.graphics.setColor(classColor)
        love.graphics.print(string.format("%.0f%%", classSat), x + 75, contentY)

        self:RenderProgressBar(x + 110, contentY + 1, w - 125, 6, classSat / 100, classColor)
        contentY = contentY + 12
    end

    contentY = contentY + 8

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x + 10, contentY, x + w - 10, contentY)
    contentY = contentY + 8

    -- Alerts section
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Alerts", x + 10, contentY)
    contentY = contentY + 18

    love.graphics.setFont(self.fonts.tiny)
    -- Check for low inventory alerts
    local alertCount = 0
    local maxAlerts = 3
    for commodityId, count in pairs(self.world.inventory) do
        if count < 5 and count > 0 and alertCount < maxAlerts then
            love.graphics.setColor(self.colors.warning)
            local shortId = #commodityId > 15 and commodityId:sub(1, 13) .. ".." or commodityId
            love.graphics.print("! Low: " .. shortId, x + 10, contentY)
            contentY = contentY + 12
            alertCount = alertCount + 1
        end
    end

    -- Check for unhappy citizens
    local unhappyCount = 0
    for _, citizen in ipairs(self.world.citizens) do
        if (citizen:GetAverageSatisfaction() or 50) < 40 then
            unhappyCount = unhappyCount + 1
        end
    end
    if unhappyCount > 0 and alertCount < maxAlerts then
        love.graphics.setColor(self.colors.danger)
        love.graphics.print("! " .. unhappyCount .. " unhappy citizen(s)", x + 10, contentY)
        contentY = contentY + 12
        alertCount = alertCount + 1
    end

    if alertCount == 0 then
        love.graphics.setColor(self.colors.success)
        love.graphics.print("No alerts", x + 10, contentY)
        contentY = contentY + 12
    end

    contentY = contentY + 8

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x + 10, contentY, x + w - 10, contentY)
    contentY = contentY + 8

    -- Mini-map section
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Mini-Map", x + 10, contentY)
    contentY = contentY + 18

    self:RenderMiniMap(x + 10, contentY, w - 20, 80)
    contentY = contentY + 90

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x + 10, contentY, x + w - 10, contentY)
    contentY = contentY + 8

    -- Quick Build section
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Quick Build", x + 10, contentY)
    contentY = contentY + 18

    self:RenderQuickBuildButtons(x + 10, contentY, w - 20)
    contentY = contentY + 85  -- Account for quick build buttons height

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x + 10, contentY, x + w - 10, contentY)
    contentY = contentY + 8

    -- Immigration section
    self:RenderImmigrationQuickView(x + 10, contentY, w - 20)

    love.graphics.setColor(1, 1, 1)
end

function AlphaUI:RenderMiniMap(x, y, w, h)
    -- Store minimap bounds for click handling
    self.minimapBounds = {x = x, y = y, w = w, h = h}

    -- Background
    love.graphics.setColor(0.15, 0.2, 0.15, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)

    -- Border
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", x, y, w, h, 4, 4)

    -- Scale factors
    local scaleX = w / self.worldWidth
    local scaleY = h / self.worldHeight
    local halfW = self.worldWidth / 2
    local halfH = self.worldHeight / 2

    -- Draw forest (if available)
    if self.world.forest and self.world.forest.mRegions then
        love.graphics.setColor(0.2, 0.5, 0.2, 0.7)
        for _, region in ipairs(self.world.forest.mRegions) do
            -- Check if region has zone bounds (rectangular) or is circular
            if region.zoneX and region.zoneY then
                -- Zone-based rectangular region
                local fx = x + region.zoneX * scaleX
                local fy = y + region.zoneY * scaleY
                local fw = region.zoneWidth * scaleX
                local fh = region.zoneHeight * scaleY
                love.graphics.rectangle("fill", fx, fy, math.max(4, fw), math.max(4, fh))
            elseif region.centerX and region.centerY then
                -- Circular region
                local fx = x + region.centerX * scaleX
                local fy = y + region.centerY * scaleY
                local fr = (region.radius or 50) * math.min(scaleX, scaleY)
                love.graphics.circle("fill", fx, fy, math.max(3, fr))
            end
        end
    end

    -- Draw river (convert from river-centered coords to world coords)
    if self.world.river and self.world.river.mPoints then
        love.graphics.setColor(0.2, 0.4, 0.7, 0.9)

        for i = 1, #self.world.river.mPoints - 1 do
            local p1 = self.world.river.mPoints[i]
            local p2 = self.world.river.mPoints[i + 1]

            -- Convert river coords (centered) to world coords (top-left origin)
            local worldX1 = p1.x + halfW
            local worldY1 = p1.y + halfH
            local worldX2 = p2.x + halfW
            local worldY2 = p2.y + halfH

            -- Convert to minimap coords
            local mx1 = x + worldX1 * scaleX
            local my1 = y + worldY1 * scaleY
            local mx2 = x + worldX2 * scaleX
            local my2 = y + worldY2 * scaleY

            -- Draw river segment with width
            local riverWidth = math.max(2, ((p1.width + p2.width) / 2) * scaleX)
            love.graphics.setLineWidth(riverWidth)
            love.graphics.line(mx1, my1, mx2, my2)
        end

        -- Draw lake if present
        if self.world.river.mLake then
            local lake = self.world.river.mLake
            local lakeWorldX = lake.x + halfW
            local lakeWorldY = lake.y + halfH
            local lakeRadius = lake.radius * math.min(scaleX, scaleY)

            love.graphics.setColor(0.2, 0.4, 0.7, 0.9)
            love.graphics.circle("fill", x + lakeWorldX * scaleX, y + lakeWorldY * scaleY, math.max(3, lakeRadius))
        end

        love.graphics.setLineWidth(1)
    end

    -- Draw resource deposits (if available)
    if self.world.resourceDeposits then
        for _, deposit in ipairs(self.world.resourceDeposits) do
            local dx = x + deposit.x * scaleX
            local dy = y + deposit.y * scaleY

            -- Color by resource type
            if deposit.type == "iron" or deposit.type == "iron_ore" then
                love.graphics.setColor(0.6, 0.4, 0.3, 0.8)
            elseif deposit.type == "coal" then
                love.graphics.setColor(0.3, 0.3, 0.3, 0.8)
            elseif deposit.type == "gold" or deposit.type == "gold_ore" then
                love.graphics.setColor(0.9, 0.8, 0.3, 0.8)
            elseif deposit.type == "stone" then
                love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
            else
                love.graphics.setColor(0.5, 0.4, 0.3, 0.8)
            end

            love.graphics.circle("fill", dx, dy, 3)
        end
    end

    -- Draw buildings as small squares with status indication
    for _, building in ipairs(self.world.buildings) do
        local bx = x + building.x * scaleX
        local by = y + building.y * scaleY
        local bw = 60 * scaleX
        local bh = 60 * scaleY

        -- Color by type and status
        local isPaused = building.isPaused or building.mIsPaused
        if isPaused then
            love.graphics.setColor(0.5, 0.4, 0.3)  -- Orange-ish for paused
        elseif building.type and building.type.category == "housing" then
            love.graphics.setColor(0.6, 0.5, 0.4)
        elseif building.type and building.type.category == "production" then
            love.graphics.setColor(0.4, 0.6, 0.4)
        else
            love.graphics.setColor(0.5, 0.5, 0.6)
        end

        love.graphics.rectangle("fill", bx, by, math.max(3, bw), math.max(3, bh))
    end

    -- Draw citizens as tiny dots (color by satisfaction)
    for _, citizen in ipairs(self.world.citizens) do
        local cx = x + citizen.x * scaleX
        local cy = y + citizen.y * scaleY

        -- Color by satisfaction level
        local satisfaction = 0.5
        if citizen.GetAverageSatisfaction then
            satisfaction = citizen:GetAverageSatisfaction() / 100
        elseif citizen.satisfaction then
            satisfaction = citizen.satisfaction / 100
        end

        if satisfaction >= 0.7 then
            love.graphics.setColor(0.4, 0.9, 0.4, 0.9)  -- Green = happy
        elseif satisfaction >= 0.4 then
            love.graphics.setColor(0.9, 0.9, 0.4, 0.9)  -- Yellow = neutral
        else
            love.graphics.setColor(0.9, 0.4, 0.4, 0.9)  -- Red = unhappy
        end

        love.graphics.circle("fill", cx, cy, 1.5)
    end

    -- Draw viewport rectangle
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local viewW = screenW - self.leftPanelWidth - self.rightPanelWidth
    local viewH = screenH - self.topBarHeight - self.bottomBarHeight

    local vpX = x + self.cameraX * scaleX
    local vpY = y + self.cameraY * scaleY
    local vpW = viewW * scaleX
    local vpH = viewH * scaleY

    love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.5)
    love.graphics.rectangle("line", vpX, vpY, vpW, vpH)

    -- Mini-map legend hint
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
    love.graphics.print("Click to navigate", x + 2, y + h - 10)
end

-- Handle minimap click for navigation
function AlphaUI:HandleMinimapClick(mx, my)
    if not self.minimapBounds then return false end

    local bounds = self.minimapBounds
    if mx < bounds.x or mx > bounds.x + bounds.w or
       my < bounds.y or my > bounds.y + bounds.h then
        return false
    end

    -- Convert minimap coordinates to world coordinates
    local scaleX = bounds.w / self.worldWidth
    local scaleY = bounds.h / self.worldHeight

    local worldX = (mx - bounds.x) / scaleX
    local worldY = (my - bounds.y) / scaleY

    -- Center camera on clicked position
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local viewW = screenW - self.leftPanelWidth - self.rightPanelWidth
    local viewH = screenH - self.topBarHeight - self.bottomBarHeight

    -- Clamp camera position
    local maxCameraX = math.max(0, self.worldWidth - viewW)
    local maxCameraY = math.max(0, self.worldHeight - viewH)

    self.cameraX = math.max(0, math.min(maxCameraX, worldX - viewW / 2))
    self.cameraY = math.max(0, math.min(maxCameraY, worldY - viewH / 2))

    return true
end

function AlphaUI:RenderQuickBuildButtons(x, y, w)
    -- Quick build button definitions
    local buttons = {
        {id = "house", label = "House", color = {0.6, 0.5, 0.4}},
        {id = "farm", label = "Farm", color = {0.4, 0.6, 0.4}},
        {id = "workshop", label = "Workshop", color = {0.5, 0.5, 0.6}},
        {id = "market", label = "Market", color = {0.6, 0.6, 0.4}}
    }

    local buttonW = (w - 10) / 2
    local buttonH = 24

    love.graphics.setFont(self.fonts.tiny)

    for i, btn in ipairs(buttons) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local bx = x + col * (buttonW + 5)
        local by = y + row * (buttonH + 5)

        -- Button background
        local isHovered = self.hoveredButton == btn.id
        if isHovered then
            love.graphics.setColor(self.colors.buttonHover)
        else
            love.graphics.setColor(self.colors.button)
        end
        love.graphics.rectangle("fill", bx, by, buttonW, buttonH, 3, 3)

        -- Button icon color
        love.graphics.setColor(btn.color[1], btn.color[2], btn.color[3])
        love.graphics.rectangle("fill", bx + 3, by + 3, 18, 18, 2, 2)

        -- Button label
        love.graphics.setColor(self.colors.text)
        love.graphics.print(btn.label, bx + 24, by + 6)

        -- Store button bounds for click detection
        self.quickBuildButtons[btn.id] = {x = bx, y = by, w = buttonW, h = buttonH, typeId = btn.id}
    end

    -- "More Buildings" button
    local moreY = y + 2 * (buttonH + 5) + 8
    love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.8)
    love.graphics.rectangle("fill", x, moreY, w, 22, 3, 3)

    love.graphics.setColor(1, 1, 1)
    local moreText = "[B] More Buildings..."
    local textW = self.fonts.tiny:getWidth(moreText)
    love.graphics.print(moreText, x + (w - textW) / 2, moreY + 5)

    -- Store bounds for click detection
    self.moreBuildingsBtn = {x = x, y = moreY, w = w, h = 22}
end

function AlphaUI:RenderImmigrationQuickView(x, y, w)
    local immigrationSystem = self.world.immigrationSystem
    if not immigrationSystem then return end

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Immigration", x, y)
    y = y + 18

    local queueCount = immigrationSystem:GetQueueCount()
    local daysUntilNext = immigrationSystem:GetDaysUntilNextBatch(self.world:GetDayNumber())

    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Applicants: " .. queueCount, x, y)
    y = y + 12

    if daysUntilNext > 0 then
        love.graphics.print("Next batch: " .. daysUntilNext .. " days", x, y)
    else
        love.graphics.print("Batch arriving soon!", x, y)
    end
    y = y + 18

    -- "View Applicants" button
    local hasApplicants = queueCount > 0
    if hasApplicants then
        love.graphics.setColor(self.colors.success[1], self.colors.success[2], self.colors.success[3], 0.8)
    else
        love.graphics.setColor(0.3, 0.3, 0.35)
    end
    love.graphics.rectangle("fill", x, y, w, 22, 3, 3)

    love.graphics.setColor(1, 1, 1)
    local btnText = hasApplicants and ("[I] View " .. queueCount .. " Applicant(s)") or "No Applicants"
    local textW = self.fonts.tiny:getWidth(btnText)
    love.graphics.print(btnText, x + (w - textW) / 2, y + 5)

    -- Store button bounds
    self.immigrationBtn = {x = x, y = y, w = w, h = 22, enabled = hasApplicants}
end

-- =============================================================================
-- IMMIGRATION MODAL
-- =============================================================================

function AlphaUI:RenderImmigrationModal()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal dimensions
    local modalW = 900
    local modalH = 620
    local modalX = (screenW - modalW) / 2
    local modalY = (screenH - modalH) / 2

    -- Modal background
    love.graphics.setColor(0.1, 0.1, 0.12, 0.98)
    love.graphics.rectangle("fill", modalX, modalY, modalW, modalH, 8, 8)

    -- Modal border
    love.graphics.setColor(0.4, 0.5, 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", modalX, modalY, modalW, modalH, 8, 8)
    love.graphics.setLineWidth(1)

    -- Header
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("IMMIGRATION QUEUE", modalX + 20, modalY + 15)

    -- Close button
    local closeX = modalX + modalW - 40
    local closeY = modalY + 10
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.danger)
    love.graphics.print("X", closeX + 8, closeY + 2)
    self.immigrationCloseBtn = {x = closeX, y = closeY, w = 30, h = 30}

    local immigrationSystem = self.world.immigrationSystem

    -- Town Attractiveness visual display
    local attractiveness = immigrationSystem and immigrationSystem:GetOverallAttractiveness() or 50
    local vacantHousing = immigrationSystem and immigrationSystem:GetTotalVacantHousing() or 0
    local totalJobs = immigrationSystem and immigrationSystem:GetTotalJobOpenings() or 0

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Town Attractiveness:", modalX + 20, modalY + 48)

    local attractColor = attractiveness >= 70 and self.colors.success or
                        (attractiveness >= 40 and self.colors.warning or self.colors.danger)
    love.graphics.setColor(attractColor)
    love.graphics.print(string.format("%.0f%%", attractiveness), modalX + 155, modalY + 48)
    self:RenderProgressBar(modalX + 200, modalY + 50, 100, 12, attractiveness / 100, attractColor)

    -- Housing and Jobs stats with separators
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("|", modalX + 310, modalY + 48)
    love.graphics.print("Housing:", modalX + 325, modalY + 48)
    love.graphics.setColor(vacantHousing > 0 and self.colors.success or self.colors.danger)
    love.graphics.print(string.format("%d available", vacantHousing), modalX + 385, modalY + 48)

    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("|", modalX + 470, modalY + 48)
    love.graphics.print("Jobs:", modalX + 485, modalY + 48)
    love.graphics.setColor(totalJobs > 0 and self.colors.success or self.colors.warning)
    love.graphics.print(string.format("%d open", totalJobs), modalX + 520, modalY + 48)

    -- Bulk action buttons
    local bulkBtnY = modalY + 44
    local bulkBtnH = 22
    local bulkBtnSpacing = 5
    local bulkStartX = modalX + 580

    -- Accept All (70%+) button
    local applicants = immigrationSystem and immigrationSystem:GetApplicants() or {}
    local highCompatCount = 0
    for _, app in ipairs(applicants) do
        if (app.compatibility or 0) >= 70 then
            highCompatCount = highCompatCount + 1
        end
    end

    if highCompatCount > 0 and vacantHousing > 0 then
        love.graphics.setColor(0.2, 0.5, 0.3, 0.9)
    else
        love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
    end
    local autoAcceptW = 110
    love.graphics.rectangle("fill", bulkStartX, bulkBtnY, autoAcceptW, bulkBtnH, 3, 3)
    love.graphics.setColor(1, 1, 1, highCompatCount > 0 and 1 or 0.5)
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.print("Accept 70%+ (" .. highCompatCount .. ")", bulkStartX + 5, bulkBtnY + 5)
    self.immigrationAcceptHighBtn = {x = bulkStartX, y = bulkBtnY, w = autoAcceptW, h = bulkBtnH, enabled = highCompatCount > 0 and vacantHousing > 0}

    -- Accept All button
    bulkStartX = bulkStartX + autoAcceptW + bulkBtnSpacing
    if #applicants > 0 and vacantHousing > 0 then
        love.graphics.setColor(0.2, 0.4, 0.2, 0.9)
    else
        love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
    end
    local acceptAllW = 70
    love.graphics.rectangle("fill", bulkStartX, bulkBtnY, acceptAllW, bulkBtnH, 3, 3)
    love.graphics.setColor(1, 1, 1, #applicants > 0 and 1 or 0.5)
    love.graphics.print("Accept All", bulkStartX + 5, bulkBtnY + 5)
    self.immigrationAcceptAllBtn = {x = bulkStartX, y = bulkBtnY, w = acceptAllW, h = bulkBtnH, enabled = #applicants > 0 and vacantHousing > 0}

    -- Reject All button
    bulkStartX = bulkStartX + acceptAllW + bulkBtnSpacing
    if #applicants > 0 then
        love.graphics.setColor(0.5, 0.2, 0.2, 0.9)
    else
        love.graphics.setColor(0.2, 0.2, 0.2, 0.6)
    end
    local rejectAllW = 70
    love.graphics.rectangle("fill", bulkStartX, bulkBtnY, rejectAllW, bulkBtnH, 3, 3)
    love.graphics.setColor(1, 1, 1, #applicants > 0 and 1 or 0.5)
    love.graphics.print("Reject All", bulkStartX + 5, bulkBtnY + 5)
    self.immigrationRejectAllBtn = {x = bulkStartX, y = bulkBtnY, w = rejectAllW, h = bulkBtnH, enabled = #applicants > 0}

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(modalX + 20, modalY + 72, modalX + modalW - 20, modalY + 72)

    -- Split: Left side = applicant list, Right side = selected applicant details
    local listX = modalX + 15
    local listY = modalY + 82
    local listW = 340
    local listH = modalH - 102

    local detailX = modalX + listW + 30
    local detailY = modalY + 82
    local detailW = modalW - listW - 45
    local detailH = modalH - 102

    -- Render applicant list
    self:RenderApplicantList(listX, listY, listW, listH)

    -- Render selected applicant details
    self:RenderApplicantDetails(detailX, detailY, detailW, detailH)

    love.graphics.setColor(1, 1, 1)
end

function AlphaUI:RenderApplicantList(x, y, w, h)
    local immigrationSystem = self.world.immigrationSystem
    if not immigrationSystem then return end

    local applicants = immigrationSystem:GetApplicants()

    -- Background
    love.graphics.setColor(0.08, 0.08, 0.1)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)

    -- Header
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Applicants (" .. #applicants .. ")", x + 10, y + 5)

    -- Scrollable list
    local listY = y + 30
    local cardH = 55
    local spacing = 5

    love.graphics.setScissor(x, listY, w, h - 35)

    love.graphics.setFont(self.fonts.small)

    for i, applicant in ipairs(applicants) do
        local cardY = listY + (i - 1) * (cardH + spacing) - self.immigrationScrollOffset

        -- Skip if off-screen
        if cardY + cardH < listY or cardY > y + h then
            goto continue
        end

        -- Card background
        local isSelected = self.selectedApplicant == applicant
        if isSelected then
            love.graphics.setColor(0.25, 0.3, 0.4)
        else
            love.graphics.setColor(0.15, 0.15, 0.18)
        end
        love.graphics.rectangle("fill", x + 5, cardY, w - 10, cardH, 3, 3)

        -- Selection border
        if isSelected then
            love.graphics.setColor(self.colors.accent)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x + 5, cardY, w - 10, cardH, 3, 3)
            love.graphics.setLineWidth(1)
        end

        -- Name and class
        love.graphics.setColor(self.colors.text)
        love.graphics.print(applicant.name, x + 10, cardY + 5)

        love.graphics.setFont(self.fonts.tiny)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print(applicant.class .. " - " .. applicant.vocation, x + 10, cardY + 20)

        -- Compatibility score
        local compat = applicant.compatibility or 50
        local compatColor = compat >= 70 and self.colors.success or
                           (compat >= 40 and self.colors.warning or self.colors.danger)
        love.graphics.setColor(compatColor)
        love.graphics.print(string.format("Match: %d%%", compat), x + 10, cardY + 32)

        -- Expiry
        local daysLeft = applicant.expiryDay - self.world:GetDayNumber()
        local expiryColor = daysLeft <= 3 and self.colors.danger or self.colors.textDim
        love.graphics.setColor(expiryColor)
        love.graphics.print(daysLeft .. " days left", x + w - 70, cardY + 32)

        -- Family indicator
        if applicant.family and #applicant.family > 0 then
            love.graphics.setColor(0.6, 0.5, 0.8)
            love.graphics.print("+" .. #applicant.family .. " family", x + w - 75, cardY + 5)
        end

        love.graphics.setFont(self.fonts.small)

        -- Store card bounds
        self["applicantCard_" .. i] = {x = x + 5, y = cardY, w = w - 10, h = cardH, applicant = applicant}

        ::continue::
    end

    love.graphics.setScissor()

    if #applicants == 0 then
        love.graphics.setColor(self.colors.textDim)
        love.graphics.setFont(self.fonts.normal)
        love.graphics.print("No applicants", x + 10, listY + 10)
        love.graphics.setFont(self.fonts.small)
        love.graphics.print("New arrivals in " .. immigrationSystem:GetDaysUntilNextBatch(self.world:GetDayNumber()) .. " days", x + 10, listY + 30)
    end
end

function AlphaUI:RenderApplicantDetails(x, y, w, h)
    local applicant = self.selectedApplicant

    -- Background
    love.graphics.setColor(0.08, 0.08, 0.1)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)

    if not applicant then
        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Select an applicant", x + 20, y + 20)
        love.graphics.setFont(self.fonts.small)
        love.graphics.print("to view details", x + 20, y + 42)
        return
    end

    -- Scrollable content area
    local contentX = x + 10
    local contentW = w - 20
    local contentStartY = y + 5
    local contentH = h - 60  -- Leave room for buttons

    love.graphics.setScissor(x, y, w, contentH)

    local contentY = contentStartY - (self.applicantDetailScrollOffset or 0)

    -- Name and portrait area
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.text)
    love.graphics.print(applicant.name, contentX, contentY)
    contentY = contentY + 26

    -- Basic info - two columns
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print(string.format("%s Class, Age %d", applicant.class, applicant.age), contentX, contentY)
    love.graphics.print("Wealth: " .. applicant.wealth .. " gold", contentX + contentW/2, contentY)
    contentY = contentY + 16

    love.graphics.print("Vocation: " .. applicant.vocation, contentX, contentY)
    love.graphics.print("From: " .. applicant.origin, contentX + contentW/2, contentY)
    contentY = contentY + 16

    -- Intended role and land requirements
    local intendedRole = applicant.intendedRole or "laborer"
    local landReqs = applicant.landRequirements
    love.graphics.setColor(self.colors.accent)
    love.graphics.print("Role: " .. intendedRole, contentX, contentY)

    if landReqs and landReqs.minPlots and landReqs.minPlots > 0 then
        love.graphics.setColor(self.colors.warning)
        love.graphics.print(string.format("Land: %d-%d plots", landReqs.minPlots, landReqs.maxPlots or landReqs.minPlots), contentX + contentW/2, contentY)
    else
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Land: Not required", contentX + contentW/2, contentY)
    end
    contentY = contentY + 20

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(contentX, contentY, contentX + contentW, contentY)
    contentY = contentY + 8

    -- Overall Compatibility
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Compatibility Score", contentX, contentY)

    local compat = applicant.compatibility or 50
    local compatColor = compat >= 70 and self.colors.success or
                       (compat >= 40 and self.colors.warning or self.colors.danger)

    love.graphics.setColor(compatColor)
    love.graphics.print(string.format("%d%%", compat), contentX + 150, contentY)
    contentY = contentY + 22

    self:RenderProgressBar(contentX, contentY, contentW, 12, compat / 100, compatColor)
    contentY = contentY + 20

    -- Compatibility breakdown
    love.graphics.setFont(self.fonts.tiny)
    local immigrationSystem = self.world.immigrationSystem
    if immigrationSystem then
        -- Calculate individual scores
        local housingScore = immigrationSystem:CalculateHousingMatch(applicant)
        local jobScore = immigrationSystem:CalculateJobMatch(applicant)
        local socialScore = immigrationSystem:CalculateSocialFit(applicant)
        local cravingScore = immigrationSystem:CalculateCravingSatisfactionPotential(applicant)

        local breakdownY = contentY
        local barW = (contentW - 15) / 2
        local barH = 10

        -- Housing match
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Housing", contentX, breakdownY)
        local housingColor = housingScore >= 70 and self.colors.success or
                            (housingScore >= 40 and self.colors.warning or self.colors.danger)
        self:RenderProgressBar(contentX + 55, breakdownY + 2, barW - 55, barH, housingScore / 100, housingColor)
        love.graphics.setColor(housingColor)
        love.graphics.print(string.format("%d%%", housingScore), contentX + barW + 5, breakdownY)

        -- Job match
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Job", contentX + barW + 35, breakdownY)
        local jobColor = jobScore >= 70 and self.colors.success or
                        (jobScore >= 40 and self.colors.warning or self.colors.danger)
        self:RenderProgressBar(contentX + barW + 65, breakdownY + 2, barW - 55, barH, jobScore / 100, jobColor)
        love.graphics.setColor(jobColor)
        love.graphics.print(string.format("%d%%", jobScore), contentX + contentW - 25, breakdownY)

        breakdownY = breakdownY + 16

        -- Social fit
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Social", contentX, breakdownY)
        local socialColor = socialScore >= 70 and self.colors.success or
                           (socialScore >= 40 and self.colors.warning or self.colors.danger)
        self:RenderProgressBar(contentX + 55, breakdownY + 2, barW - 55, barH, socialScore / 100, socialColor)
        love.graphics.setColor(socialColor)
        love.graphics.print(string.format("%d%%", socialScore), contentX + barW + 5, breakdownY)

        -- Craving potential
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Needs", contentX + barW + 35, breakdownY)
        local cravingColor = cravingScore >= 70 and self.colors.success or
                            (cravingScore >= 40 and self.colors.warning or self.colors.danger)
        self:RenderProgressBar(contentX + barW + 65, breakdownY + 2, barW - 55, barH, cravingScore / 100, cravingColor)
        love.graphics.setColor(cravingColor)
        love.graphics.print(string.format("%d%%", cravingScore), contentX + contentW - 25, breakdownY)

        contentY = breakdownY + 22
    end

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(contentX, contentY, contentX + contentW, contentY)
    contentY = contentY + 8

    -- Top Cravings/Needs
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Primary Needs", contentX, contentY)
    contentY = contentY + 18

    love.graphics.setFont(self.fonts.tiny)
    if applicant.cravingProfile then
        local topCravings = immigrationSystem:GetTopCravings(applicant.cravingProfile, 4)
        local cravingX = contentX
        for i, craving in ipairs(topCravings) do
            local cravingW = contentW / 4 - 5
            love.graphics.setColor(self.colors.textDim)
            love.graphics.print(craving.name:sub(1, 6), cravingX, contentY)
            love.graphics.setColor(self.colors.accent)
            love.graphics.print(string.format("%d", craving.value), cravingX, contentY + 10)
            cravingX = cravingX + cravingW + 5
        end
        contentY = contentY + 28
    else
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("No craving data available", contentX, contentY)
        contentY = contentY + 18
    end

    -- Traits
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Traits", contentX, contentY)
    contentY = contentY + 16

    love.graphics.setFont(self.fonts.tiny)
    if applicant.traits and #applicant.traits > 0 then
        local traitX = contentX
        for _, trait in ipairs(applicant.traits) do
            -- Trait chip
            local traitText = tostring(trait)
            local chipW = self.fonts.tiny:getWidth(traitText) + 10
            love.graphics.setColor(0.25, 0.25, 0.35)
            love.graphics.rectangle("fill", traitX, contentY, chipW, 16, 3, 3)
            love.graphics.setColor(0.7, 0.7, 0.8)
            love.graphics.print(traitText, traitX + 5, contentY + 2)
            traitX = traitX + chipW + 5
            if traitX > contentX + contentW - 50 then
                traitX = contentX
                contentY = contentY + 18
            end
        end
        contentY = contentY + 22
    else
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("No special traits", contentX, contentY)
        contentY = contentY + 18
    end

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(contentX, contentY, contentX + contentW, contentY)
    contentY = contentY + 8

    -- Backstory
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Backstory", contentX, contentY)
    contentY = contentY + 16

    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    local backstory = applicant.backstory or "No backstory available."
    local wrappedLines = self:WrapText(backstory, contentW, self.fonts.tiny)
    for _, line in ipairs(wrappedLines) do
        love.graphics.print(line, contentX, contentY)
        contentY = contentY + 12
    end
    contentY = contentY + 8

    -- Family section
    if applicant.family and #applicant.family > 0 then
        love.graphics.setColor(0.3, 0.3, 0.35)
        love.graphics.line(contentX, contentY, contentX + contentW, contentY)
        contentY = contentY + 8

        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.text)
        love.graphics.print("Family (" .. #applicant.family .. " members)", contentX, contentY)
        contentY = contentY + 16

        love.graphics.setFont(self.fonts.tiny)
        for _, member in ipairs(applicant.family) do
            love.graphics.setColor(0.18, 0.18, 0.22)
            love.graphics.rectangle("fill", contentX, contentY, contentW, 28, 3, 3)

            love.graphics.setColor(self.colors.text)
            love.graphics.print(member.name, contentX + 5, contentY + 2)
            love.graphics.setColor(self.colors.textDim)
            love.graphics.print(member.vocation .. ", Age " .. member.age, contentX + 5, contentY + 14)

            if member.isDependent then
                love.graphics.setColor(0.6, 0.5, 0.3)
                love.graphics.print("Dependent", contentX + contentW - 55, contentY + 8)
            end

            contentY = contentY + 32
        end
    end

    -- Store max scroll
    self.applicantDetailScrollMax = math.max(0, contentY - contentStartY - contentH + 50)

    love.graphics.setScissor()

    -- Action buttons at bottom
    local btnY = y + h - 45
    local btnW = (w - 40) / 3
    local btnH = 32

    -- Accept/Select Land button
    local canAccept = self.world.immigrationSystem:GetTotalVacantHousing() > 0
    local landReqs = applicant.landRequirements
    local needsLand = landReqs and landReqs.minPlots and landReqs.minPlots > 0

    -- Check if enough plots available for land-requiring applicants
    local canAffordLand = true
    if needsLand and self.world.landSystem then
        local availablePlots = self.world.landSystem:GetAvailablePlots()
        canAffordLand = #availablePlots >= landReqs.minPlots
    end

    if canAccept and canAffordLand then
        love.graphics.setColor(self.colors.success[1], self.colors.success[2], self.colors.success[3], 0.9)
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
    end
    love.graphics.rectangle("fill", x + 10, btnY, btnW, btnH, 4, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.normal)
    local acceptText = needsLand and "SELECT LAND" or "ACCEPT"
    local acceptTextW = self.fonts.normal:getWidth(acceptText)
    love.graphics.print(acceptText, x + 10 + (btnW - acceptTextW) / 2, btnY + 7)
    self.acceptApplicantBtn = {x = x + 10, y = btnY, w = btnW, h = btnH, enabled = canAccept and canAffordLand}

    -- Defer button
    love.graphics.setColor(self.colors.warning[1], self.colors.warning[2], self.colors.warning[3], 0.8)
    love.graphics.rectangle("fill", x + 15 + btnW, btnY, btnW, btnH, 4, 4)
    love.graphics.setColor(1, 1, 1)
    local deferText = "DEFER"
    local deferTextW = self.fonts.normal:getWidth(deferText)
    love.graphics.print(deferText, x + 15 + btnW + (btnW - deferTextW) / 2, btnY + 7)
    self.deferApplicantBtn = {x = x + 15 + btnW, y = btnY, w = btnW, h = btnH}

    -- Reject button
    love.graphics.setColor(self.colors.danger[1], self.colors.danger[2], self.colors.danger[3], 0.8)
    love.graphics.rectangle("fill", x + 20 + btnW * 2, btnY, btnW, btnH, 4, 4)
    love.graphics.setColor(1, 1, 1)
    local rejectText = "REJECT"
    local rejectTextW = self.fonts.normal:getWidth(rejectText)
    love.graphics.print(rejectText, x + 20 + btnW * 2 + (btnW - rejectTextW) / 2, btnY + 7)
    self.rejectApplicantBtn = {x = x + 20 + btnW * 2, y = btnY, w = btnW, h = btnH}
end

function AlphaUI:WrapText(text, maxWidth, font)
    local lines = {}
    local words = {}

    -- Split into words
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end

    local currentLine = ""
    for i, word in ipairs(words) do
        local testLine = currentLine == "" and word or (currentLine .. " " .. word)
        if font:getWidth(testLine) <= maxWidth then
            currentLine = testLine
        else
            if currentLine ~= "" then
                table.insert(lines, currentLine)
            end
            currentLine = word
        end
    end
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end

    return lines
end

-- =============================================================================
-- RIGHT PANEL
-- =============================================================================

function AlphaUI:RenderRightPanel()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local w = self.rightPanelWidth
    local x = screenW - w
    local y = self.topBarHeight
    local h = screenH - self.topBarHeight - self.bottomBarHeight

    -- Background
    love.graphics.setColor(self.colors.rightPanel)
    love.graphics.rectangle("fill", x, y, w, h)

    -- Border
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.rectangle("line", x, y, w, h)

    local contentY = y + 10

    if self.world.selectedEntity then
        if self.world.selectedEntityType == "citizen" then
            self:RenderCitizenDetails(x, contentY, w)
        elseif self.world.selectedEntityType == "building" then
            self:RenderBuildingDetails(x, contentY, w)
        end
    else
        -- No selection
        love.graphics.setFont(self.fonts.header)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("No Selection", x + 10, contentY)
        contentY = contentY + 30

        love.graphics.setFont(self.fonts.small)
        love.graphics.print("Click on a citizen or", x + 10, contentY)
        contentY = contentY + 16
        love.graphics.print("building to view details", x + 10, contentY)
    end

    love.graphics.setColor(1, 1, 1)
end

function AlphaUI:RenderCitizenDetails(x, y, w)
    local citizen = self.world.selectedEntity

    -- Header
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.text)
    love.graphics.print(citizen.name or "Unknown", x + 10, y)
    y = y + 25

    -- Class and age
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Class: " .. (citizen.class or "?"), x + 10, y)
    y = y + 20
    love.graphics.print("Age: " .. (citizen.age or "?"), x + 10, y)
    y = y + 20
    love.graphics.print("Vocation: " .. (citizen.vocation or "None"), x + 10, y)
    y = y + 30

    -- Satisfaction
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Satisfaction", x + 10, y)
    y = y + 25

    local overallSat = citizen:GetAverageSatisfaction() or 50
    local satColor = overallSat > 70 and self.colors.satisfactionHigh or
                     (overallSat > 40 and self.colors.satisfactionMed or self.colors.satisfactionLow)

    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(satColor)
    love.graphics.print(string.format("Overall: %.0f%%", overallSat), x + 10, y)
    y = y + 20

    self:RenderProgressBar(x + 10, y, w - 30, 14, overallSat / 100, satColor)
    y = y + 25

    -- Top needs (coarse dimensions)
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Top Needs:", x + 10, y)
    y = y + 18

    -- Show coarse satisfaction levels (computed from fine in CharacterV3)
    local coarseNames = {"Biological", "Safety", "Touch", "Psychological",
                        "Status", "Social", "Exotic", "Shiny", "Vice"}

    if citizen.satisfaction then
        -- CharacterV3 uses satisfaction table keyed by name
        for i = 1, math.min(5, #coarseNames) do
            local name = coarseNames[i]
            local val = citizen.satisfaction[name] or 50
            local needColor = val < 40 and self.colors.danger or
                              (val < 70 and self.colors.warning or self.colors.success)
            love.graphics.setColor(needColor)
            love.graphics.print(string.format("%s: %.0f", name, val), x + 15, y)
            y = y + 14
        end
    elseif citizen.satisfactionCoarse then
        -- Legacy CharacterV2 uses array
        for i = 1, math.min(5, #coarseNames) do
            local val = citizen.satisfactionCoarse[i - 1] or 0
            local needColor = val < 40 and self.colors.danger or
                              (val < 70 and self.colors.warning or self.colors.success)
            love.graphics.setColor(needColor)
            love.graphics.print(string.format("%s: %.0f", coarseNames[i], val), x + 15, y)
            y = y + 14
        end
    end

    y = y + 15

    -- Work status
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Work", x + 10, y)
    y = y + 20

    love.graphics.setFont(self.fonts.small)
    if citizen.workplace then
        love.graphics.setColor(self.colors.success)
        love.graphics.print("Employed at: " .. citizen.workplace.name, x + 10, y)
    else
        love.graphics.setColor(self.colors.warning)
        love.graphics.print("Unemployed", x + 10, y)
    end
end

function AlphaUI:RenderBuildingDetails(x, y, w)
    local building = self.world.selectedEntity

    -- Check if this is a housing building
    local isHousing = false
    local housingOccupancy = nil
    if self.world.housingSystem and self.world.housingSystem.buildingOccupancy then
        housingOccupancy = self.world.housingSystem.buildingOccupancy[building.id]
        if housingOccupancy then
            isHousing = true
        end
    end

    -- Header
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.text)
    love.graphics.print(building.name or "Building", x + 10, y)
    y = y + 25

    -- Type
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Type: " .. (building.typeId or "?"), x + 10, y)
    y = y + 20
    love.graphics.print("Level: " .. ((building.level or 0) + 1), x + 10, y)
    y = y + 30

    if isHousing then
        -- Housing-specific details
        y = self:RenderHousingBuildingDetails(x, y, w, building, housingOccupancy)
    else
        -- Production building details
        y = self:RenderProductionBuildingDetails(x, y, w, building)
    end

    y = y + 15

    -- Action button (different text for housing vs production)
    local btnW = w - 20
    local btnH = 30
    local btnX = x + 10
    local btnY = y

    love.graphics.setColor(0.3, 0.5, 0.7)
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 5, 5)
    love.graphics.setColor(0.4, 0.6, 0.8)
    love.graphics.rectangle("line", btnX, btnY, btnW, btnH, 5, 5)

    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(1, 1, 1)
    local btnText = isHousing and "Manage Housing" or "Manage Building"
    local textW = self.fonts.normal:getWidth(btnText)
    love.graphics.print(btnText, btnX + (btnW - textW) / 2, btnY + 7)

    -- Store button position for click handling
    self.manageBuildingBtn = {x = btnX, y = btnY, w = btnW, h = btnH}
    self.isHousingBuilding = isHousing
end

function AlphaUI:RenderHousingBuildingDetails(x, y, w, building, housingOccupancy)
    -- Residents section
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Residents", x + 10, y)
    y = y + 20

    love.graphics.setFont(self.fonts.small)
    local occupants = housingOccupancy.occupants or {}
    local residentCount = #occupants
    local capacity = housingOccupancy.capacity or 1
    local residentColor = residentCount >= capacity and self.colors.success or
                        (residentCount > 0 and self.colors.warning or self.colors.danger)
    love.graphics.setColor(residentColor)
    love.graphics.print(residentCount .. " / " .. capacity, x + 10, y)
    y = y + 20

    -- List residents
    for i, residentId in ipairs(occupants) do
        if i > 5 then
            love.graphics.setColor(self.colors.textDim)
            love.graphics.print("  ... and " .. (residentCount - 5) .. " more", x + 15, y)
            y = y + 14
            break
        end
        local resident = self.world.characters and self.world.characters[residentId]
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("- " .. (resident and resident.name or "Resident"), x + 15, y)
        y = y + 14
    end

    if residentCount == 0 then
        love.graphics.setColor(self.colors.textMuted or {0.5, 0.5, 0.5})
        love.graphics.print("No residents", x + 15, y)
        y = y + 14
    end

    y = y + 15

    -- Housing Quality
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Housing Info", x + 10, y)
    y = y + 20

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)

    local qualityTier = housingOccupancy.qualityTier or "basic"
    local quality = housingOccupancy.housingQuality or 0.5
    love.graphics.print("Quality: " .. qualityTier .. " (" .. math.floor(quality * 100) .. "%)", x + 10, y)
    y = y + 16

    local rent = housingOccupancy.rentPerOccupant or 0
    love.graphics.setColor(self.colors.gold or {0.98, 0.85, 0.37})
    love.graphics.print("Rent: " .. rent .. "g per resident/cycle", x + 10, y)
    y = y + 16

    -- Target classes
    local targetClasses = housingOccupancy.targetClasses or {}
    if #targetClasses > 0 then
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Target: " .. table.concat(targetClasses, ", "), x + 10, y)
        y = y + 16
    end

    return y
end

function AlphaUI:RenderProductionBuildingDetails(x, y, w, building)
    -- Workers
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Workers", x + 10, y)
    y = y + 20

    love.graphics.setFont(self.fonts.small)
    local workers = building.workers or {}
    local workerCount = #workers
    local maxWorkers = building.maxWorkers or 2
    local workerColor = workerCount >= maxWorkers and self.colors.success or
                        (workerCount > 0 and self.colors.warning or self.colors.danger)
    love.graphics.setColor(workerColor)
    love.graphics.print(workerCount .. " / " .. maxWorkers, x + 10, y)
    y = y + 20

    -- List workers
    for i, worker in ipairs(workers) do
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("- " .. (worker.name or "Worker"), x + 15, y)
        y = y + 14
    end
    y = y + 15

    -- Stations
    local stations = building.stations or {}
    if #stations > 0 then
        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(self.colors.text)
        love.graphics.print("Production", x + 10, y)
        y = y + 20

        love.graphics.setFont(self.fonts.small)
        for i, station in ipairs(stations) do
            local stateColor = station.state == "PRODUCING" and self.colors.success or
                              (station.state == "IDLE" and self.colors.textDim or self.colors.warning)
            love.graphics.setColor(stateColor)
            local recipeName = station.recipe and station.recipe.name or "No recipe"
            love.graphics.print("Station " .. i .. ": " .. recipeName, x + 10, y)
            y = y + 14
            love.graphics.setColor(self.colors.textDim)
            love.graphics.print("  Status: " .. station.state, x + 10, y)
            y = y + 14

            if station.state == "PRODUCING" then
                love.graphics.print(string.format("  Progress: %.0f%%", station.progress * 100), x + 10, y)
                y = y + 14
            end

            -- Show recipe details (inputs and outputs)
            if station.recipe then
                -- Show inputs
                local inputsText = "  In: "
                local inputCount = 0
                for inputId, qty in pairs(station.recipe.inputs or {}) do
                    if inputCount > 0 then inputsText = inputsText .. ", " end
                    local inputName = self:GetCommodityDisplayName(inputId)
                    inputsText = inputsText .. inputName .. " x" .. qty
                    inputCount = inputCount + 1
                end
                if inputCount == 0 then inputsText = inputsText .. "None" end
                love.graphics.setColor(0.8, 0.7, 0.6)
                love.graphics.print(inputsText, x + 10, y)
                y = y + 14

                -- Show outputs
                local outputsText = "  Out: "
                local outputCount = 0
                for outputId, qty in pairs(station.recipe.outputs or {}) do
                    if outputCount > 0 then outputsText = outputsText .. ", " end
                    local outputName = self:GetCommodityDisplayName(outputId)
                    outputsText = outputsText .. outputName .. " x" .. qty
                    outputCount = outputCount + 1
                end
                if outputCount == 0 then outputsText = outputsText .. "None" end
                love.graphics.setColor(0.6, 0.9, 0.7)
                love.graphics.print(outputsText, x + 10, y)
                y = y + 14

                -- When NO_MATERIALS, show what's missing
                if station.state == "NO_MATERIALS" then
                    y = y + 2
                    love.graphics.setColor(self.colors.danger)
                    love.graphics.print("  Missing materials:", x + 10, y)
                    y = y + 14
                    for inputId, required in pairs(station.recipe.inputs or {}) do
                        local available = self.world.inventory[inputId] or 0
                        if available < required then
                            local inputName = self:GetCommodityDisplayName(inputId)
                            local missingText = string.format("    %s: %d / %d needed", inputName, available, required)
                            love.graphics.print(missingText, x + 10, y)
                            y = y + 14
                        end
                    end
                end
            end

            y = y + 5  -- Small gap between stations
        end

        y = y + 15
    end

    -- Resource Efficiency
    if building.resourceEfficiency then
        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(self.colors.text)
        love.graphics.print("Efficiency", x + 10, y)
        y = y + 20

        local eff = building.resourceEfficiency
        local effColor = eff >= 0.7 and self.colors.success or
                        (eff >= 0.4 and self.colors.warning or self.colors.danger)

        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(effColor)
        love.graphics.print(string.format("%.0f%%", eff * 100), x + 10, y)

        self:RenderProgressBar(x + 50, y + 2, w - 70, 10, eff, effColor)
        y = y + 20

        -- Breakdown
        if building.efficiencyBreakdown then
            for resId, data in pairs(building.efficiencyBreakdown) do
                local resColor = data.met and self.colors.success or self.colors.danger
                love.graphics.setColor(resColor)
                love.graphics.print(string.format("%s: %.0f%%", data.displayName or resId, data.value * 100), x + 15, y)
                y = y + 14
            end
        end
    end

    return y
end

-- =============================================================================
-- BOTTOM BAR (Event Log)
-- =============================================================================

function AlphaUI:RenderBottomBar()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local h = self.bottomBarHeight
    local y = screenH - h
    local x = self.leftPanelWidth
    local w = screenW - self.leftPanelWidth - self.rightPanelWidth

    -- Background
    love.graphics.setColor(self.colors.bottomBar)
    love.graphics.rectangle("fill", x, y, w, h)

    -- Border
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.rectangle("line", x, y, w, h)

    -- Header and filter buttons
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Event Log", x + 10, y + 5)

    -- Filter buttons
    self:RenderEventLogFilters(x + 120, y + 3, w - 140)

    -- Events
    love.graphics.setFont(self.fonts.small)
    local eventY = y + 28
    local maxEvents = 5
    local eventCount = 0

    for i = 1, #self.world.eventLog do
        if eventCount >= maxEvents then break end

        local event = self.world.eventLog[i]
        if event and self:ShouldShowEvent(event) then
            -- Event type color
            local typeColor = self.colors.textDim
            local typeIcon = ""
            if event.type == "day" or event.type == "slot" then
                typeColor = self.colors.accent
                typeIcon = ">"
            elseif event.type == "production" then
                typeColor = self.colors.success
                typeIcon = "+"
            elseif event.type == "consumption" then
                typeColor = self.colors.gold
                typeIcon = "*"
            elseif event.type == "immigration" then
                typeColor = self.colors.success
                typeIcon = "+"
            elseif event.type == "emigration" then
                typeColor = self.colors.danger
                typeIcon = "-"
            elseif event.type == "construction" then
                typeColor = self.colors.accent
                typeIcon = "#"
            end

            -- Time stamp
            love.graphics.setColor(self.colors.textDim)
            love.graphics.print(string.format("[Day %d]", event.day or 1), x + 10, eventY)

            -- Type icon
            love.graphics.setColor(typeColor)
            love.graphics.print(typeIcon, x + 65, eventY)

            -- Message
            local msg = event.message or ""
            if #msg > 60 then msg = msg:sub(1, 57) .. "..." end
            love.graphics.print(msg, x + 80, eventY)

            eventY = eventY + 16
            eventCount = eventCount + 1
        end
    end

    if eventCount == 0 then
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("No events to show", x + 10, eventY)
    end

    love.graphics.setColor(1, 1, 1)
end

function AlphaUI:RenderEventLogFilters(x, y, w)
    local filters = {
        {id = "all", label = "All"},
        {id = "production", label = "Prod"},
        {id = "consumption", label = "Cons"},
        {id = "immigration", label = "Immi"},
        {id = "time", label = "Time"}
    }

    local buttonW = 45
    local buttonH = 18
    local spacing = 5

    love.graphics.setFont(self.fonts.tiny)

    for i, filter in ipairs(filters) do
        local bx = x + (i - 1) * (buttonW + spacing)
        local isActive = self.eventLogFilter == filter.id

        -- Button background
        if isActive then
            love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.6)
        else
            love.graphics.setColor(self.colors.button)
        end
        love.graphics.rectangle("fill", bx, y, buttonW, buttonH, 2, 2)

        -- Button text
        if isActive then
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(self.colors.textDim)
        end

        local textW = self.fonts.tiny:getWidth(filter.label)
        love.graphics.print(filter.label, bx + (buttonW - textW) / 2, y + 3)

        -- Store button bounds for click detection
        self["filterButton_" .. filter.id] = {x = bx, y = y, w = buttonW, h = buttonH}
    end
end

function AlphaUI:ShouldShowEvent(event)
    if self.eventLogFilter == "all" then
        return true
    elseif self.eventLogFilter == "production" then
        return event.type == "production"
    elseif self.eventLogFilter == "consumption" then
        return event.type == "consumption"
    elseif self.eventLogFilter == "immigration" then
        return event.type == "immigration" or event.type == "emigration"
    elseif self.eventLogFilter == "time" then
        return event.type == "day" or event.type == "slot"
    end
    return true
end

-- =============================================================================
-- WORLD VIEW
-- =============================================================================

function AlphaUI:RenderWorldView()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local x = self.leftPanelWidth
    local y = self.topBarHeight
    local w = screenW - self.leftPanelWidth - self.rightPanelWidth
    local h = screenH - self.topBarHeight - self.bottomBarHeight

    -- Clip to world view area
    love.graphics.setScissor(x, y, w, h)

    -- Day/night tint
    local r, g, b = self.world:GetDayNightColor()

    -- Render terrain tiles (checkerboard grass pattern)
    self:RenderTerrain(x, y, w, h, r, g, b)

    -- Render resource overlay (if visible) - uses same coordinate approach as terrain
    if self.showResourceOverlay and self.resourceOverlay then
        self:RenderResourceOverlayAligned(x, y, w, h)
    end

    -- Render land distribution overlay (if visible)
    if self.showLandOverlay and self.world.landSystem then
        -- Use the LandOverlay module if available (has better visuals with owner labels)
        if self.landOverlay then
            self.landOverlay:Render(self)
        else
            self:RenderLandOverlay(x, y, w, h)
        end
    end

    -- Offset for camera - translate to world coordinates
    love.graphics.push()
    love.graphics.translate(x - self.cameraX, y - self.cameraY)

    -- Render river using native River:Render (river uses world-centered coordinates)
    if self.world.river then
        love.graphics.push()
        -- River is centered at worldWidth/2, so offset to match
        love.graphics.translate(self.world.worldWidth * 0.5, self.world.worldHeight * 0.5)
        self.world.river:Render()
        love.graphics.pop()
    end

    -- Render forest using native Forest:Render
    if self.world.forest then
        self.world.forest:Render()
    end

    -- Render mountains using native Mountain:Render
    if self.world.mountains then
        self.world.mountains:Render()
    end

    -- Render paths/roads between buildings (simple connections)
    self:RenderPaths(r, g, b)

    -- Render buildings
    for _, building in ipairs(self.world.buildings) do
        self:RenderBuilding(building)
    end

    -- Render placement ghost building
    if self.placementMode and self.placementBuildingType then
        self:RenderPlacementGhost()
    end

    -- Render citizens
    for _, citizen in ipairs(self.world.citizens) do
        self:RenderCitizen(citizen)
    end

    love.graphics.pop()
    love.graphics.setScissor()
end

function AlphaUI:RenderTerrain(x, y, w, h, dayR, dayG, dayB)
    local gridSize = self.gridSize
    local cols = math.ceil(w / gridSize) + 1
    local rows = math.ceil(h / gridSize) + 1

    -- Start position accounting for camera
    local startCol = math.floor(self.cameraX / gridSize)
    local startRow = math.floor(self.cameraY / gridSize)

    -- Calculate max columns and rows based on world size
    local maxWorldCol = math.floor(self.worldWidth / gridSize)
    local maxWorldRow = math.floor(self.worldHeight / gridSize)

    for row = 0, rows do
        for col = 0, cols do
            local worldCol = startCol + col
            local worldRow = startRow + row

            -- Skip tiles outside world boundaries
            if worldCol < 0 or worldRow < 0 or worldCol >= maxWorldCol or worldRow >= maxWorldRow then
                goto continue
            end

            local tileX = x + (col * gridSize) - (self.cameraX % gridSize)
            local tileY = y + (row * gridSize) - (self.cameraY % gridSize)

            -- Checkerboard grass pattern
            local isLight = (worldCol + worldRow) % 2 == 0
            local grass = isLight and self.colors.grass or self.colors.grassDark

            -- Apply day/night tint
            love.graphics.setColor(grass[1] * dayR, grass[2] * dayG, grass[3] * dayB)
            love.graphics.rectangle("fill", tileX, tileY, gridSize, gridSize)

            -- Subtle grid lines
            love.graphics.setColor(grass[1] * dayR * 0.8, grass[2] * dayG * 0.8, grass[3] * dayB * 0.8, 0.3)
            love.graphics.rectangle("line", tileX, tileY, gridSize, gridSize)

            ::continue::
        end
    end
end

-- Render resource overlay aligned with terrain (using same coordinate approach)
function AlphaUI:RenderResourceOverlayAligned(viewX, viewY, viewW, viewH)
    if not self.resourceOverlay or not self.world.naturalResources then
        return
    end

    local nr = self.world.naturalResources
    if not nr:isGenerated() then
        return
    end

    local gridWidth, gridHeight, cellSize = nr:getGridDimensions()
    local minX, maxX, minY, maxY = nr:getBoundaries()

    -- Calculate which cells are visible based on camera
    local startCellX = math.floor(self.cameraX / cellSize) + 1
    local startCellY = math.floor(self.cameraY / cellSize) + 1
    local endCellX = math.ceil((self.cameraX + viewW) / cellSize) + 1
    local endCellY = math.ceil((self.cameraY + viewH) / cellSize) + 1

    -- Clamp to grid bounds
    startCellX = math.max(1, startCellX)
    startCellY = math.max(1, startCellY)
    endCellX = math.min(gridWidth, endCellX)
    endCellY = math.min(gridHeight, endCellY)

    -- Get all resource IDs
    local resourceIds = nr:getAllResourceIds()

    for _, resourceId in ipairs(resourceIds) do
        if self.resourceOverlay:isOverlayVisible(resourceId) then
            local def = nr:getDefinition(resourceId)
            if def then
                local gridData = nr:getGridData(resourceId)
                if gridData then
                    local viz = def.visualization or {}
                    local color = viz.color or {0.5, 0.5, 0.5}
                    local baseOpacity = viz.opacity or 0.6
                    local showThreshold = viz.showThreshold or 0.1

                    -- Draw visible cells
                    for gx = startCellX, endCellX do
                        for gy = startCellY, endCellY do
                            local value = gridData[gx] and gridData[gx][gy] or 0

                            if value >= showThreshold then
                                -- Calculate screen position (same approach as terrain tiles)
                                local worldX = minX + (gx - 1) * cellSize
                                local worldY = minY + (gy - 1) * cellSize
                                local screenX = viewX + worldX - self.cameraX
                                local screenY = viewY + worldY - self.cameraY

                                local alpha = value * baseOpacity
                                love.graphics.setColor(color[1], color[2], color[3], alpha)
                                love.graphics.rectangle("fill", screenX, screenY, cellSize, cellSize)
                            end
                        end
                    end
                end
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Render land distribution overlay showing plot ownership
function AlphaUI:RenderLandOverlay(viewX, viewY, viewW, viewH)
    local landSystem = self.world.landSystem
    if not landSystem then return end

    local plotWidth = landSystem.plotWidth
    local plotHeight = landSystem.plotHeight

    -- Calculate visible grid range
    local startGridX = math.floor(self.cameraX / plotWidth)
    local startGridY = math.floor(self.cameraY / plotHeight)
    local endGridX = math.ceil((self.cameraX + viewW) / plotWidth)
    local endGridY = math.ceil((self.cameraY + viewH) / plotHeight)

    -- Clamp to grid bounds
    startGridX = math.max(0, startGridX)
    startGridY = math.max(0, startGridY)
    endGridX = math.min(landSystem.gridColumns - 1, endGridX)
    endGridY = math.min(landSystem.gridRows - 1, endGridY)

    -- Colors for different ownership states
    local colors = {
        townOwned = {0.2, 0.4, 0.8, 0.35},      -- Blue for town-owned
        citizenOwned = {0.6, 0.4, 0.2, 0.4},    -- Brown for citizen-owned
        blocked = {0.3, 0.3, 0.3, 0.2},         -- Gray for blocked (water/mountain)
        available = {0.2, 0.6, 0.2, 0.3},       -- Green for available/purchasable
        gridLine = {0.4, 0.4, 0.4, 0.4}
    }

    -- Draw plot colors
    for gx = startGridX, endGridX do
        for gy = startGridY, endGridY do
            local plotId = landSystem:GetPlotId(gx, gy)
            local plot = landSystem.plots[plotId]

            if plot then
                local screenX = viewX + (gx * plotWidth) - self.cameraX
                local screenY = viewY + (gy * plotHeight) - self.cameraY

                -- Determine plot color based on ownership and state
                if plot.isBlocked then
                    love.graphics.setColor(colors.blocked)
                elseif plot.ownerId == "TOWN" or not plot.ownerId then
                    -- Town-owned or unclaimed - show as available
                    love.graphics.setColor(colors.available)
                else
                    -- Citizen-owned
                    love.graphics.setColor(colors.citizenOwned)
                end

                love.graphics.rectangle("fill", screenX, screenY, plotWidth, plotHeight)

                -- Draw grid lines
                love.graphics.setColor(colors.gridLine)
                love.graphics.rectangle("line", screenX, screenY, plotWidth, plotHeight)
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Render land overlay legend panel
function AlphaUI:RenderLandOverlayPanel()
    local panelX = self.leftPanelWidth + 10
    local panelY = self.topBarHeight + 10
    local panelW = 180
    local panelH = 130

    -- Background
    love.graphics.setColor(0.1, 0.1, 0.12, 0.9)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 4, 4)

    -- Border
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 4, 4)

    -- Title
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("LAND OWNERSHIP", panelX + 10, panelY + 8)

    -- Legend items
    local legendY = panelY + 30
    local legendItems = {
        {color = {0.2, 0.6, 0.2, 0.8}, label = "Available (Town)"},
        {color = {0.6, 0.4, 0.2, 0.8}, label = "Citizen Owned"},
        {color = {0.3, 0.3, 0.3, 0.5}, label = "Blocked"},
    }

    love.graphics.setFont(self.fonts.tiny)
    for _, item in ipairs(legendItems) do
        love.graphics.setColor(item.color)
        love.graphics.rectangle("fill", panelX + 10, legendY, 15, 15)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.rectangle("line", panelX + 10, legendY, 15, 15)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print(item.label, panelX + 30, legendY + 2)
        legendY = legendY + 20
    end

    -- Statistics
    local landSystem = self.world.landSystem
    if landSystem then
        legendY = legendY + 5
        love.graphics.setColor(0.7, 0.7, 0.7)
        local townPlots = #(landSystem:GetAvailablePlots() or {})
        local totalPlots = landSystem.gridColumns * landSystem.gridRows
        love.graphics.print("Available: " .. townPlots .. "/" .. totalPlots, panelX + 10, legendY)
    end

    -- Hint
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.print("Press L to toggle", panelX + 10, panelY + panelH - 18)

    love.graphics.setColor(1, 1, 1)
end

function AlphaUI:RenderPaths(dayR, dayG, dayB)
    -- Draw simple path connections between buildings
    local pathColor = self.colors.path
    love.graphics.setColor(pathColor[1] * dayR, pathColor[2] * dayG, pathColor[3] * dayB, 0.6)
    love.graphics.setLineWidth(8)

    local buildings = self.world.buildings
    if #buildings < 2 then
        love.graphics.setLineWidth(1)
        return
    end

    -- Connect buildings in a simple network (each to nearest neighbor already connected)
    local connected = {buildings[1]}
    for i = 2, #buildings do
        local building = buildings[i]
        -- Find nearest connected building
        local nearestDist = math.huge
        local nearest = nil
        for _, cb in ipairs(connected) do
            local dx = building.x - cb.x
            local dy = building.y - cb.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < nearestDist then
                nearestDist = dist
                nearest = cb
            end
        end

        if nearest then
            -- Use world coordinates directly (we're inside the world rendering transform)
            local bx1 = building.x + 30
            local by1 = building.y + 30
            local bx2 = nearest.x + 30
            local by2 = nearest.y + 30
            love.graphics.line(bx1, by1, bx2, by2)
        end

        table.insert(connected, building)
    end

    love.graphics.setLineWidth(1)
end

function AlphaUI:RenderBuilding(building)
    -- Use world coordinates directly (we're inside the world rendering transform)
    local bx = building.x
    local by = building.y
    local bw = 60
    local bh = 60

    -- Building color based on type
    local buildingColor = {0.5, 0.4, 0.3}
    if building.type then
        if building.type.category == "housing" then
            buildingColor = {0.6, 0.5, 0.4}
        elseif building.type.category == "production" then
            buildingColor = {0.4, 0.5, 0.4}
        elseif building.type.category == "service" then
            buildingColor = {0.4, 0.4, 0.6}
        end
    end

    -- Day/night tint
    local r, g, b = self.world:GetDayNightColor()

    -- Determine building status for visual indicator
    local status = "idle"  -- idle, producing, understaffed, stopped, paused
    local isPaused = building.isPaused or building.mIsPaused or false
    local producing = false
    local hasNoMaterials = false
    local hasNoWorker = false

    if isPaused then
        status = "paused"
    else
        for _, station in ipairs(building.stations or {}) do
            if station.state == "PRODUCING" then
                producing = true
            elseif station.state == "NO_MATERIALS" then
                hasNoMaterials = true
            elseif station.state == "NO_WORKER" then
                hasNoWorker = true
            end
        end

        if producing then
            status = "producing"
        elseif hasNoMaterials then
            status = "stopped"
        elseif hasNoWorker then
            status = "understaffed"
        end
    end

    -- Status glow effect (renders behind building)
    local glowColor = nil
    local glowPulse = (math.sin(love.timer.getTime() * 3) + 1) / 2  -- 0 to 1 pulse

    if status == "producing" then
        glowColor = {0.3, 0.9, 0.3, 0.3 + glowPulse * 0.2}  -- Green glow
    elseif status == "understaffed" then
        glowColor = {0.9, 0.7, 0.2, 0.3 + glowPulse * 0.2}  -- Yellow glow
    elseif status == "stopped" then
        glowColor = {0.9, 0.3, 0.3, 0.3 + glowPulse * 0.3}  -- Red glow
    elseif status == "paused" then
        glowColor = {0.6, 0.5, 0.3, 0.3}  -- Orange glow (no pulse)
    end

    -- Draw glow
    if glowColor then
        love.graphics.setColor(glowColor)
        love.graphics.rectangle("fill", bx - 4, by - 4, bw + 8, bh + 8, 8, 8)
    end

    -- Building body
    love.graphics.setColor(buildingColor[1] * r, buildingColor[2] * g, buildingColor[3] * b)
    love.graphics.rectangle("fill", bx, by, bw, bh, 4, 4)

    -- Status border
    if status == "producing" then
        love.graphics.setColor(0.3, 0.9, 0.3, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", bx - 1, by - 1, bw + 2, bh + 2, 5, 5)
        love.graphics.setLineWidth(1)
    elseif status == "stopped" then
        love.graphics.setColor(0.9, 0.3, 0.3, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", bx - 1, by - 1, bw + 2, bh + 2, 5, 5)
        love.graphics.setLineWidth(1)
    elseif status == "understaffed" then
        love.graphics.setColor(0.9, 0.7, 0.2, 0.8)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", bx - 1, by - 1, bw + 2, bh + 2, 5, 5)
        love.graphics.setLineWidth(1)
    end

    -- Selection highlight
    if self.world.selectedEntity == building then
        love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.8)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", bx - 3, by - 3, bw + 6, bh + 6, 6, 6)
        love.graphics.setLineWidth(1)
    end

    -- Building name
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(1, 1, 1)
    local name = building.name or "?"
    if #name > 10 then name = name:sub(1, 8) .. ".." end
    love.graphics.print(name, bx + 5, by + bh - 14)

    -- Status icon (speech bubble style for issues)
    if status == "stopped" then
        -- Red "!" bubble
        love.graphics.setColor(0.9, 0.2, 0.2, 0.9)
        love.graphics.circle("fill", bx + bw - 5, by - 5, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.fonts.small)
        love.graphics.print("!", bx + bw - 8, by - 12)
    elseif status == "understaffed" then
        -- Yellow "?" bubble
        love.graphics.setColor(0.9, 0.7, 0.2, 0.9)
        love.graphics.circle("fill", bx + bw - 5, by - 5, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.fonts.small)
        love.graphics.print("?", bx + bw - 8, by - 12)
    elseif status == "paused" then
        -- Gray "||" bubble
        love.graphics.setColor(0.5, 0.5, 0.5, 0.9)
        love.graphics.circle("fill", bx + bw - 5, by - 5, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.fonts.tiny)
        love.graphics.print("||", bx + bw - 10, by - 11)
    end
end

function AlphaUI:RenderCitizen(citizen)
    -- Use world coordinates directly (we're inside the world rendering transform)
    local cx = citizen.x
    local cy = citizen.y
    local radius = 10

    -- Day/night tint
    local r, g, b = self.world:GetDayNightColor()

    -- Satisfaction determines appearance
    local sat = citizen:GetAverageSatisfaction() or 50
    local satColor
    local statusIndicator = nil
    local emigrationRisk = false
    local isProtesting = citizen.isProtesting or false
    local isSearching = citizen.searchingForWork or (not citizen.workplace and citizen.vocation)

    if sat > 70 then
        satColor = {0.4, 0.8, 0.4}  -- Green = Happy
    elseif sat > 40 then
        satColor = {0.9, 0.8, 0.3}  -- Yellow = Neutral
    else
        satColor = {0.9, 0.4, 0.4}  -- Red = Unhappy
        statusIndicator = "!"  -- Needs attention
    end

    -- Check emigration risk (very low satisfaction for extended time)
    if sat < 25 then
        emigrationRisk = true
    end

    -- Override status indicator based on special states
    if isProtesting then
        statusIndicator = "X"  -- Protesting
    elseif emigrationRisk then
        statusIndicator = "!!"  -- Emigration risk
    elseif isSearching then
        statusIndicator = "?"  -- Looking for work
    end

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.ellipse("fill", cx + 2, cy + radius - 2, radius * 0.8, radius * 0.3)

    -- Emigration risk warning glow (pulsing red aura)
    if emigrationRisk then
        local pulse = (math.sin(love.timer.getTime() * 5) + 1) / 2
        love.graphics.setColor(0.9, 0.2, 0.2, 0.3 + pulse * 0.3)
        love.graphics.circle("fill", cx, cy, radius + 8)
    end

    -- Protesting indicator (angry red glow)
    if isProtesting then
        local pulse = (math.sin(love.timer.getTime() * 8) + 1) / 2
        love.graphics.setColor(1, 0, 0, 0.4 + pulse * 0.3)
        love.graphics.circle("fill", cx, cy, radius + 6)
    end

    -- Get satisfaction gradient color (red to green)
    local gradientColor = self:GetSatisfactionGradientColor(sat)

    -- Determine shape based on class (circular for lower, squarish for upper)
    -- Use emergentClass first (new system), fall back to class (legacy)
    local rawClass = citizen.emergentClass or citizen.class or "middle"
    local classLower = string.lower(rawClass)

    -- Circular for lower classes (poor, working, lower)
    local isCircular = (classLower == "poor" or classLower == "working" or classLower == "lower")
    local cornerRadius
    if isCircular then
        cornerRadius = radius
    elseif classLower == "middle" then
        cornerRadius = radius * 0.5
    else  -- elite, upper
        cornerRadius = radius * 0.2
    end

    -- Face background with satisfaction gradient color and day/night tint
    love.graphics.setColor(gradientColor[1] * r, gradientColor[2] * g, gradientColor[3] * b)
    if isCircular then
        love.graphics.circle("fill", cx, cy, radius)
    else
        love.graphics.rectangle("fill", cx - radius, cy - radius, radius * 2, radius * 2, cornerRadius, cornerRadius)
    end

    -- Border (darker version of face color)
    love.graphics.setColor(gradientColor[1] * 0.6 * r, gradientColor[2] * 0.6 * g, gradientColor[3] * 0.6 * b)
    love.graphics.setLineWidth(1.5)
    if isCircular then
        love.graphics.circle("line", cx, cy, radius)
    else
        love.graphics.rectangle("line", cx - radius, cy - radius, radius * 2, radius * 2, cornerRadius, cornerRadius)
    end
    love.graphics.setLineWidth(1)

    -- Draw emoticon expression (eyes and mouth based on satisfaction)
    self:DrawEmoticonExpression(cx, cy, radius, sat)

    -- Status indicator with speech bubble
    if statusIndicator then
        local bubbleX = cx + radius + 2
        local bubbleY = cy - radius - 12
        local bubbleW = statusIndicator == "!!" and 18 or 14
        local bubbleH = 14

        -- Speech bubble background
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.rectangle("fill", bubbleX, bubbleY, bubbleW, bubbleH, 3, 3)

        -- Bubble pointer
        love.graphics.polygon("fill",
            bubbleX + 3, bubbleY + bubbleH,
            bubbleX + 8, bubbleY + bubbleH,
            bubbleX + 2, bubbleY + bubbleH + 4
        )

        -- Status text with appropriate color
        love.graphics.setFont(self.fonts.small)
        if statusIndicator == "X" then
            love.graphics.setColor(0.8, 0, 0)  -- Red for protesting
        elseif statusIndicator == "!!" then
            love.graphics.setColor(0.7, 0.1, 0.1)  -- Dark red for emigration risk
        elseif statusIndicator == "?" then
            love.graphics.setColor(0.2, 0.5, 0.8)  -- Blue for searching
        else
            love.graphics.setColor(0.9, 0.5, 0.1)  -- Orange for unhappy
        end
        love.graphics.print(statusIndicator, bubbleX + 3, bubbleY + 1)
    end

    -- Activity indicator
    if citizen.workplace then
        -- Working indicator (small tool icon area)
        love.graphics.setColor(0.3, 0.6, 0.9, 0.8)
        love.graphics.circle("fill", cx + radius, cy - radius, 4)
    end

    -- Selection highlight (match shape to class)
    if self.world.selectedEntity == citizen then
        love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.9)
        love.graphics.setLineWidth(3)
        if isCircular then
            love.graphics.circle("line", cx, cy, radius + 6)
        else
            love.graphics.rectangle("line", cx - radius - 6, cy - radius - 6, (radius + 6) * 2, (radius + 6) * 2, cornerRadius + 2, cornerRadius + 2)
        end
        love.graphics.setLineWidth(1)

        -- Pulsing effect using game time
        local pulse = math.sin(love.timer.getTime() * 4) * 0.3 + 0.7
        love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], pulse * 0.5)
        if isCircular then
            love.graphics.circle("line", cx, cy, radius + 10)
        else
            love.graphics.rectangle("line", cx - radius - 10, cy - radius - 10, (radius + 10) * 2, (radius + 10) * 2, cornerRadius + 4, cornerRadius + 4)
        end
    end
end

-- =============================================================================
-- PLACEMENT MODE
-- =============================================================================

function AlphaUI:EnterPlacementMode(buildingType, restrictedPlots, ownerCitizen)
    self.placementMode = true
    self.placementBuildingType = buildingType
    self.placementValid = false
    self.placementEfficiency = 1.0
    self.placementBreakdown = {}
    self.placementErrors = {}
    self.showResourceOverlay = true  -- Auto-show resources during placement

    -- Store restricted plots and owner for immigration-related placement
    self.placementRestrictedPlots = restrictedPlots  -- nil means no restriction (normal build menu)
    self.placementOwnerCitizen = ownerCitizen  -- The citizen who will own the building

    -- Show resource overlay panel with relevant resources enabled
    if self.resourceOverlay then
        self.resourceOverlay.mPanelVisible = true
        -- Show fertility and ground water by default for placement
        self.resourceOverlay:showOverlay("fertility")
        self.resourceOverlay:showOverlay("ground_water")
    end

    -- Enable land overlay if we have restricted plots (helps user see their plots)
    if restrictedPlots and #restrictedPlots > 0 then
        self.showLandOverlay = true

        -- Focus camera on the restricted plots
        self:FocusCameraOnPlots(restrictedPlots)

        -- Debug: print restricted plots
        print("[AlphaUI] EnterPlacementMode with " .. #restrictedPlots .. " restricted plots:")
        for i, plotIdOrObj in ipairs(restrictedPlots) do
            local plotId = type(plotIdOrObj) == "string" and plotIdOrObj or (plotIdOrObj.id or "unknown")
            print("  - Plot " .. i .. ": " .. plotId)
        end
    end

    -- Pause the game during placement
    self.world:Pause()

    local plotInfo = ""
    if restrictedPlots and #restrictedPlots > 0 then
        plotInfo = " (restricted to " .. #restrictedPlots .. " owned plots)"
    end
    print("Entered placement mode for: " .. (buildingType.name or buildingType.id) .. plotInfo)
end

-- Focus camera on a set of plots (centers view on them)
function AlphaUI:FocusCameraOnPlots(plots)
    if not plots or #plots == 0 then return end

    local landSystem = self.world.landSystem
    if not landSystem then return end

    -- Calculate bounding box of all plots
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for _, plotIdOrObj in ipairs(plots) do
        local plotId = type(plotIdOrObj) == "string" and plotIdOrObj or (plotIdOrObj.id or nil)
        if plotId then
            local plot = landSystem:GetPlotById(plotId)
            if plot then
                minX = math.min(minX, plot.worldX)
                minY = math.min(minY, plot.worldY)
                maxX = math.max(maxX, plot.worldX + (plot.width or 100))
                maxY = math.max(maxY, plot.worldY + (plot.height or 100))
            end
        end
    end

    if minX < math.huge then
        -- Calculate center of the bounding box
        local centerX = (minX + maxX) / 2
        local centerY = (minY + maxY) / 2

        -- Get the world view dimensions
        local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
        local worldViewW = screenW - self.leftPanelWidth - self.rightPanelWidth
        local worldViewH = screenH - self.topBarHeight - self.bottomBarHeight

        -- Set camera to center on the plots
        self.cameraX = centerX - worldViewW / 2
        self.cameraY = centerY - worldViewH / 2

        -- Clamp to world bounds
        local worldWidth = self.world.worldWidth or 2000
        local worldHeight = self.world.worldHeight or 1500
        self.cameraX = math.max(0, math.min(self.cameraX, worldWidth - worldViewW))
        self.cameraY = math.max(0, math.min(self.cameraY, worldHeight - worldViewH))

        print(string.format("[AlphaUI] Camera focused on plots at (%d, %d)", self.cameraX, self.cameraY))
    end
end

function AlphaUI:ExitPlacementMode()
    self.placementMode = false
    self.placementBuildingType = nil
    self.placementRestrictedPlots = nil
    self.placementOwnerCitizen = nil
    self.showResourceOverlay = false
    self.showBuildMenuModal = false

    -- Hide resource overlay panel
    if self.resourceOverlay then
        self.resourceOverlay.mPanelVisible = false
        self.resourceOverlay:hideAll()
    end

    -- Resume the game
    self.world:Resume()
end

function AlphaUI:UpdatePlacement(mouseX, mouseY)
    if not self.placementMode or not self.placementBuildingType then return end

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Convert screen coordinates to world coordinates
    local worldViewX = self.leftPanelWidth
    local worldViewY = self.topBarHeight

    -- Check if mouse is in world view area
    if mouseX < worldViewX or mouseX > screenW - self.rightPanelWidth then return end
    if mouseY < worldViewY or mouseY > screenH - self.bottomBarHeight then return end

    -- Calculate world position (center building on cursor)
    local buildingW = 60
    local buildingH = 60
    self.placementX = (mouseX - worldViewX) + self.cameraX - buildingW / 2
    self.placementY = (mouseY - worldViewY) + self.cameraY - buildingH / 2

    -- Snap to grid (optional)
    local gridSnap = 10
    self.placementX = math.floor(self.placementX / gridSnap) * gridSnap
    self.placementY = math.floor(self.placementY / gridSnap) * gridSnap

    -- Validate placement
    self.placementValid, self.placementErrors, self.placementEfficiency, self.placementBreakdown =
        self.world:ValidateBuildingPlacement(self.placementBuildingType, self.placementX, self.placementY, buildingW, buildingH)

    -- Additional validation: check if placement is within restricted plots (for immigration-related placement)
    if self.placementRestrictedPlots and #self.placementRestrictedPlots > 0 then
        local withinRestrictedPlot = self:IsPlacementWithinRestrictedPlots(self.placementX, self.placementY, buildingW, buildingH)
        if not withinRestrictedPlot then
            self.placementValid = false
            table.insert(self.placementErrors, "Must build on your purchased land plots")
        end
    end

    -- Additional validation: check affordability (only for town placement, not immigrant placement)
    if self.placementValid and not self.placementOwnerCitizen then
        local canAfford, affordError = self.world:CanAffordBuilding(self.placementBuildingType)
        if not canAfford then
            self.placementValid = false
            table.insert(self.placementErrors, affordError or "Cannot afford building")
        end
    end
end

-- Check if the building placement is within any of the restricted plots
function AlphaUI:IsPlacementWithinRestrictedPlots(x, y, w, h)
    if not self.placementRestrictedPlots or #self.placementRestrictedPlots == 0 then
        return true  -- No restriction
    end

    local landSystem = self.world.landSystem
    if not landSystem then
        return true  -- No land system, allow placement
    end

    -- Check each corner of the building
    local corners = {
        {x = x, y = y},
        {x = x + w, y = y},
        {x = x, y = y + h},
        {x = x + w, y = y + h}
    }

    -- All corners must be within restricted plots
    for _, corner in ipairs(corners) do
        local plot = landSystem:GetPlotAtWorld(corner.x, corner.y)
        if not plot then
            return false  -- Corner is outside any plot
        end

        -- Check if this plot is in our restricted list
        local isAllowed = false
        for _, allowedPlot in ipairs(self.placementRestrictedPlots) do
            -- Handle both plot ID strings and plot objects
            local allowedPlotId
            if type(allowedPlot) == "string" then
                -- It's a plot ID string (e.g., "plot_3_4")
                allowedPlotId = allowedPlot
            elseif type(allowedPlot) == "table" then
                -- It's a plot object
                allowedPlotId = allowedPlot.id
            end

            if allowedPlotId and allowedPlotId == plot.id then
                isAllowed = true
                break
            end
        end

        if not isAllowed then
            return false  -- Corner is in a plot we don't own
        end
    end

    return true
end

function AlphaUI:RenderPlacementGhost()
    local bType = self.placementBuildingType
    if not bType then return end

    local bw = 60
    local bh = 60
    -- Use world coordinates directly (we're inside the world rendering transform)
    local bx = self.placementX
    local by = self.placementY

    -- Day/night tint
    local r, g, b = self.world:GetDayNightColor()

    -- Color based on validity
    local ghostColor
    if self.placementValid then
        ghostColor = {0.4, 0.8, 0.4, 0.6}  -- Green, semi-transparent
    else
        ghostColor = {0.8, 0.3, 0.3, 0.6}  -- Red, semi-transparent
    end

    -- Building body
    love.graphics.setColor(ghostColor[1] * r, ghostColor[2] * g, ghostColor[3] * b, ghostColor[4])
    love.graphics.rectangle("fill", bx, by, bw, bh, 4, 4)

    -- Border
    love.graphics.setColor(ghostColor[1], ghostColor[2], ghostColor[3], 0.9)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", bx, by, bw, bh, 4, 4)
    love.graphics.setLineWidth(1)

    -- Building name
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(1, 1, 1)
    local name = bType.name or bType.id
    if #name > 10 then name = name:sub(1, 8) .. ".." end
    love.graphics.print(name, bx + 5, by + bh - 14)

    -- Efficiency indicator above building
    local effText = string.format("%.0f%%", self.placementEfficiency * 100)
    local effColor = self.placementEfficiency >= 0.7 and self.colors.success or
                    (self.placementEfficiency >= 0.4 and self.colors.warning or self.colors.danger)
    love.graphics.setColor(effColor)
    love.graphics.print(effText, bx + bw/2 - 12, by - 16)
end

function AlphaUI:RenderPlacementPanel()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local x = screenW - self.rightPanelWidth
    local y = self.topBarHeight
    local w = self.rightPanelWidth
    local h = screenH - self.topBarHeight - self.bottomBarHeight

    -- Background
    love.graphics.setColor(self.colors.rightPanel)
    love.graphics.rectangle("fill", x, y, w, h)

    -- Border
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.rectangle("line", x, y, w, h)

    local contentY = y + 10
    local bType = self.placementBuildingType

    if not bType then return end

    -- Header
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.accent)
    love.graphics.print("PLACING", x + 10, contentY)
    contentY = contentY + 25

    love.graphics.setColor(self.colors.text)
    love.graphics.print(bType.name or bType.id, x + 10, contentY)
    contentY = contentY + 30

    -- Size
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Size: 60x60", x + 10, contentY)
    contentY = contentY + 25

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x + 10, contentY, x + w - 10, contentY)
    contentY = contentY + 10

    -- Requirements section
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Requirements", x + 10, contentY)
    contentY = contentY + 22

    love.graphics.setFont(self.fonts.small)

    -- Check boundaries
    local inBounds = self.placementX >= 0 and self.placementY >= 0 and
                     self.placementX + 60 <= self.world.worldWidth and
                     self.placementY + 60 <= self.world.worldHeight
    love.graphics.setColor(inBounds and self.colors.success or self.colors.danger)
    love.graphics.print((inBounds and "[OK]" or "[X]") .. " Within bounds", x + 10, contentY)
    contentY = contentY + 16

    -- Check collision
    local noCollision = true
    for _, err in ipairs(self.placementErrors) do
        if err:find("Overlaps") then noCollision = false break end
    end
    love.graphics.setColor(noCollision and self.colors.success or self.colors.danger)
    love.graphics.print((noCollision and "[OK]" or "[X]") .. " No obstructions", x + 10, contentY)
    contentY = contentY + 25

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x + 10, contentY, x + w - 10, contentY)
    contentY = contentY + 10

    -- Efficiency section
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Resource Efficiency", x + 10, contentY)
    contentY = contentY + 22

    local eff = self.placementEfficiency
    local effColor = eff >= 0.7 and self.colors.success or
                    (eff >= 0.4 and self.colors.warning or self.colors.danger)

    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(effColor)
    love.graphics.print(string.format("%.0f%%", eff * 100), x + 10, contentY)

    self:RenderProgressBar(x + 70, contentY + 4, w - 90, 14, eff, effColor)
    contentY = contentY + 30

    -- Breakdown
    love.graphics.setFont(self.fonts.small)
    if self.placementBreakdown and next(self.placementBreakdown) then
        for resId, data in pairs(self.placementBreakdown) do
            local resColor = data.met and self.colors.success or self.colors.danger
            love.graphics.setColor(resColor)
            local checkMark = data.met and "[OK]" or "[X]"
            love.graphics.print(string.format("%s %s: %.0f%%", checkMark, data.displayName or resId, data.value * 100), x + 10, contentY)
            contentY = contentY + 16
        end
    else
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("No resource requirements", x + 10, contentY)
        contentY = contentY + 16
    end

    contentY = contentY + 15

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x + 10, contentY, x + w - 10, contentY)
    contentY = contentY + 10

    -- Cost section
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Cost", x + 10, contentY)
    contentY = contentY + 22

    love.graphics.setFont(self.fonts.small)
    local cost = bType.constructionCost or {}
    local goldCost = cost.gold or 0
    local canAffordGold = self.world.gold >= goldCost

    love.graphics.setColor(canAffordGold and self.colors.gold or self.colors.danger)
    love.graphics.print(string.format("Gold: %d / %d", goldCost, self.world.gold), x + 10, contentY)
    contentY = contentY + 16

    -- Material costs
    for materialId, required in pairs(cost.materials or {}) do
        local available = self.world.inventory[materialId] or 0
        local canAfford = available >= required
        love.graphics.setColor(canAfford and self.colors.success or self.colors.danger)
        love.graphics.print(string.format("%s: %d / %d", materialId, required, available), x + 10, contentY)
        contentY = contentY + 16
    end

    love.graphics.setColor(1, 1, 1)
end

function AlphaUI:RenderPlacementInstructions()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Instruction bar at bottom of world view
    local barX = self.leftPanelWidth
    local barY = screenH - self.bottomBarHeight - 30
    local barW = screenW - self.leftPanelWidth - self.rightPanelWidth
    local barH = 28

    -- Background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.9)
    love.graphics.rectangle("fill", barX, barY, barW, barH)

    -- Instructions
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(1, 1, 1)

    local instructions = "[Left-Click] Place   [Right-Click] Cancel   [R] Toggle Resources"
    local textW = self.fonts.small:getWidth(instructions)
    love.graphics.print(instructions, barX + (barW - textW) / 2, barY + 7)
end

function AlphaUI:RenderSpawnCitizenModeIndicator()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Instruction bar at bottom of world view (similar to placement mode)
    local barX = self.leftPanelWidth
    local barY = screenH - self.bottomBarHeight - 30
    local barW = screenW - self.leftPanelWidth - self.rightPanelWidth
    local barH = 28

    -- Background with cyan/teal tint for debug mode
    love.graphics.setColor(0.1, 0.15, 0.2, 0.9)
    love.graphics.rectangle("fill", barX, barY, barW, barH)

    -- Border to highlight debug mode
    love.graphics.setColor(0.2, 0.8, 0.8, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", barX, barY, barW, barH)
    love.graphics.setLineWidth(1)

    -- Instructions
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.3, 1, 1)

    local instructions = "[SPAWN CITIZEN MODE] Click anywhere to spawn a citizen - Press [SHIFT+C] to exit"
    local textW = self.fonts.small:getWidth(instructions)
    love.graphics.print(instructions, barX + (barW - textW) / 2, barY + 7)

    -- Also draw at mouse position for visual feedback
    local mx, my = love.mouse.getPosition()
    local worldX = self.leftPanelWidth
    local worldY = self.topBarHeight
    local worldW = screenW - self.leftPanelWidth - self.rightPanelWidth
    local worldH = screenH - self.topBarHeight - self.bottomBarHeight

    if mx >= worldX and mx < worldX + worldW and
       my >= worldY and my < worldY + worldH then
        -- Draw citizen preview at mouse
        love.graphics.setColor(0.2, 0.8, 0.8, 0.6)
        love.graphics.circle("fill", mx, my, 10)
        love.graphics.setColor(0.3, 1, 1, 0.8)
        love.graphics.circle("line", mx, my, 10)
    end

    love.graphics.setColor(1, 1, 1)
end

function AlphaUI:RenderBuildMenuModal()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal dimensions - larger for better layout
    local modalW = 850
    local modalH = 600
    local modalX = (screenW - modalW) / 2
    local modalY = (screenH - modalH) / 2

    -- Modal background
    love.graphics.setColor(0.12, 0.12, 0.15, 0.98)
    love.graphics.rectangle("fill", modalX, modalY, modalW, modalH, 10, 10)

    -- Modal border
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", modalX, modalY, modalW, modalH, 10, 10)
    love.graphics.setLineWidth(1)

    -- Header area with gradient effect
    love.graphics.setColor(0.15, 0.15, 0.2, 0.8)
    love.graphics.rectangle("fill", modalX, modalY, modalW, 55, 10, 10)
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(modalX + 10, modalY + 55, modalX + modalW - 10, modalY + 55)

    -- Header title
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("BUILD MENU", modalX + 20, modalY + 15)

    -- Close button
    local closeX = modalX + modalW - 45
    local closeY = modalY + 12
    local mx, my = love.mouse.getPosition()
    local closeHovered = mx >= closeX and mx <= closeX + 30 and my >= closeY and my <= closeY + 30
    love.graphics.setColor(closeHovered and {0.8, 0.2, 0.2} or self.colors.danger)
    love.graphics.rectangle("fill", closeX, closeY, 30, 30, 4, 4)
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("X", closeX + 9, closeY + 4)
    self.buildMenuCloseBtn = {x = closeX, y = closeY, w = 30, h = 30}

    -- Search bar
    local searchY = modalY + 65
    local searchX = modalX + 20
    local searchW = 250
    local searchH = 32

    -- Search box background
    local searchActive = self.buildMenuSearchActive
    love.graphics.setColor(searchActive and {0.2, 0.2, 0.25} or {0.15, 0.15, 0.18})
    love.graphics.rectangle("fill", searchX, searchY, searchW, searchH, 4, 4)
    love.graphics.setColor(searchActive and self.colors.accent or {0.35, 0.35, 0.4})
    love.graphics.rectangle("line", searchX, searchY, searchW, searchH, 4, 4)

    -- Search icon
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.5, 0.5, 0.55)
    love.graphics.print("[?]", searchX + 8, searchY + 9)

    -- Search text or placeholder
    local currentQuery = self.buildMenuSearchQuery or ""
    love.graphics.setColor(currentQuery == "" and {0.5, 0.5, 0.55} or self.colors.text)
    local searchText = currentQuery == "" and "Search buildings..." or currentQuery
    love.graphics.print(searchText, searchX + 35, searchY + 9)

    -- Blinking cursor when active
    if searchActive and math.floor(love.timer.getTime() * 2) % 2 == 0 then
        local cursorX = searchX + 35 + self.fonts.small:getWidth(currentQuery)
        love.graphics.setColor(self.colors.text)
        love.graphics.rectangle("fill", cursorX, searchY + 8, 2, 16)
    end

    self.buildMenuSearchBox = {x = searchX, y = searchY, w = searchW, h = searchH}

    -- Category tabs - more categories with icons
    local categories = {
        {id = "all", name = "All", icon = "*"},
        {id = "housing", name = "Housing", icon = "H"},
        {id = "production", name = "Production", icon = "P"},
        {id = "agriculture", name = "Agriculture", icon = "A"},
        {id = "extraction", name = "Extraction", icon = "E"},
        {id = "services", name = "Services", icon = "S"}
    }
    local tabY = searchY
    local tabX = searchX + searchW + 20
    local tabH = 32

    love.graphics.setFont(self.fonts.small)
    self.buildMenuTabs = {}
    for i, cat in ipairs(categories) do
        local isActive = self.buildMenuCategory == cat.id
        local tabW = self.fonts.small:getWidth(cat.name) + 24
        local tabHovered = mx >= tabX and mx <= tabX + tabW and my >= tabY and my <= tabY + tabH

        -- Tab background
        if isActive then
            love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.7)
        elseif tabHovered then
            love.graphics.setColor(0.25, 0.25, 0.3)
        else
            love.graphics.setColor(0.18, 0.18, 0.22)
        end
        love.graphics.rectangle("fill", tabX, tabY, tabW, tabH, 4, 4)

        -- Tab border when active
        if isActive then
            love.graphics.setColor(self.colors.accent)
            love.graphics.rectangle("line", tabX, tabY, tabW, tabH, 4, 4)
        end

        -- Tab text
        love.graphics.setColor(isActive and {1, 1, 1} or (tabHovered and {0.9, 0.9, 0.9} or self.colors.textDim))
        local textW = self.fonts.small:getWidth(cat.name)
        love.graphics.print(cat.name, tabX + (tabW - textW) / 2, tabY + 9)

        -- Store tab bounds
        self.buildMenuTabs[cat.id] = {x = tabX, y = tabY, w = tabW, h = tabH}
        tabX = tabX + tabW + 8
    end

    -- Building count - positioned below the tabs/search bar
    local buildings = self:GetFilteredBuildingTypes()

    -- Building cards area
    local cardsY = searchY + searchH + 15
    local cardsX = modalX + 20
    local cardsW = modalW - 40
    local cardsH = modalH - (cardsY - modalY) - 20

    -- Building count text in the cards area header
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print(#buildings .. " buildings found", cardsX + cardsW - 120, searchY + searchH - 2)

    -- Cards area background
    love.graphics.setColor(0.1, 0.1, 0.12)
    love.graphics.rectangle("fill", cardsX - 5, cardsY - 5, cardsW + 10, cardsH + 10, 6, 6)

    -- Scissor for scrolling
    love.graphics.setScissor(cardsX, cardsY, cardsW, cardsH)

    -- Card layout - larger cards with more info
    local cardW = 160
    local cardH = 145
    local cardSpacing = 12
    local cardsPerRow = math.floor((cardsW + cardSpacing) / (cardW + cardSpacing))
    if cardsPerRow < 1 then cardsPerRow = 1 end

    -- Calculate total content height for scroll
    local totalRows = math.ceil(#buildings / cardsPerRow)
    local totalContentH = totalRows * (cardH + cardSpacing) - cardSpacing  -- Remove trailing spacing
    self.buildMenuMaxScroll = math.max(0, totalContentH - cardsH)

    -- Clamp scroll offset to valid range
    self.buildMenuScrollOffset = self.buildMenuScrollOffset or 0
    if self.buildMenuScrollOffset > self.buildMenuMaxScroll then
        self.buildMenuScrollOffset = self.buildMenuMaxScroll
    end
    if self.buildMenuScrollOffset < 0 then
        self.buildMenuScrollOffset = 0
    end

    -- Clear old card bounds
    for k in pairs(self) do
        if type(k) == "string" and k:match("^buildCard_") then
            self[k] = nil
        end
    end

    love.graphics.setFont(self.fonts.small)

    for i, bType in ipairs(buildings) do
        local col = (i - 1) % cardsPerRow
        local row = math.floor((i - 1) / cardsPerRow)
        local cardX = cardsX + col * (cardW + cardSpacing)
        local cardY = cardsY + row * (cardH + cardSpacing) - self.buildMenuScrollOffset

        -- Skip if off-screen
        if cardY + cardH < cardsY or cardY > cardsY + cardsH then
            goto continue
        end

        -- Check affordability
        local canAfford, _ = self.world:CanAffordBuilding(bType)
        local cardHovered = mx >= cardX and mx <= cardX + cardW and my >= cardY and my <= cardY + cardH

        -- Card background with hover effect
        if cardHovered and canAfford then
            love.graphics.setColor(0.22, 0.22, 0.28)
        elseif canAfford then
            love.graphics.setColor(0.17, 0.17, 0.22)
        else
            love.graphics.setColor(0.15, 0.15, 0.18, 0.8)
        end
        love.graphics.rectangle("fill", cardX, cardY, cardW, cardH, 6, 6)

        -- Card border
        if cardHovered and canAfford then
            love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.8)
            love.graphics.setLineWidth(2)
        else
            love.graphics.setColor(0.35, 0.35, 0.4)
            love.graphics.setLineWidth(1)
        end
        love.graphics.rectangle("line", cardX, cardY, cardW, cardH, 6, 6)
        love.graphics.setLineWidth(1)

        -- Icon/Visual area with category-based color
        local iconColors = {
            housing = {0.6, 0.5, 0.4},
            production = {0.4, 0.55, 0.7},
            agriculture = {0.4, 0.65, 0.35},
            extraction = {0.55, 0.45, 0.35},
            services = {0.6, 0.5, 0.65}
        }
        local iconColor = iconColors[bType.category] or {0.5, 0.5, 0.5}
        local alpha = canAfford and 1 or 0.4

        -- Icon background
        love.graphics.setColor(iconColor[1] * 0.3, iconColor[2] * 0.3, iconColor[3] * 0.3, alpha)
        love.graphics.rectangle("fill", cardX + 10, cardY + 10, cardW - 20, 45, 4, 4)

        -- Building label/icon
        love.graphics.setColor(iconColor[1], iconColor[2], iconColor[3], alpha)
        love.graphics.setFont(self.fonts.header)
        local label = bType.label or bType.id:sub(1, 2):upper()
        local labelW = self.fonts.header:getWidth(label)
        love.graphics.print(label, cardX + (cardW - labelW) / 2, cardY + 20)

        -- Building name
        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(canAfford and {1, 1, 1} or {0.5, 0.5, 0.5})
        local name = bType.name or bType.id
        if #name > 18 then name = name:sub(1, 16) .. ".." end
        love.graphics.print(name, cardX + 10, cardY + 60)

        -- Category chip
        love.graphics.setFont(self.fonts.small)
        local category = bType.category or "other"
        local catColor = iconColors[category] or {0.5, 0.5, 0.5}
        love.graphics.setColor(catColor[1], catColor[2], catColor[3], 0.3)
        local catText = category:sub(1, 1):upper() .. category:sub(2)
        local catTextW = self.fonts.small:getWidth(catText)
        love.graphics.rectangle("fill", cardX + 10, cardY + 80, catTextW + 10, 16, 3, 3)
        love.graphics.setColor(catColor[1], catColor[2], catColor[3], canAfford and 1 or 0.5)
        love.graphics.print(catText, cardX + 15, cardY + 81)

        -- Workers info
        local stations = 0
        if bType.upgradeLevels and bType.upgradeLevels[1] then
            stations = bType.upgradeLevels[1].stations or 0
        end
        if stations > 0 then
            love.graphics.setColor(self.colors.textDim)
            love.graphics.print("Workers: " .. stations, cardX + 10, cardY + 100)
        elseif bType.category == "housing" then
            local capacity = 0
            if bType.upgradeLevels and bType.upgradeLevels[1] then
                capacity = bType.upgradeLevels[1].capacity or 0
            end
            love.graphics.setColor(self.colors.textDim)
            love.graphics.print("Capacity: " .. capacity, cardX + 10, cardY + 100)
        end

        -- Cost display
        local cost = bType.constructionCost or {}
        local goldCost = cost.gold or 0
        love.graphics.setColor(canAfford and self.colors.gold or self.colors.danger)
        love.graphics.print(goldCost .. " gold", cardX + cardW - 55, cardY + 100)

        -- BUILD button
        local btnY = cardY + cardH - 28
        local btnHovered = cardHovered and my >= btnY
        if canAfford then
            if btnHovered then
                love.graphics.setColor(self.colors.success[1] * 1.2, self.colors.success[2] * 1.2, self.colors.success[3] * 1.2, 0.9)
            else
                love.graphics.setColor(self.colors.success[1], self.colors.success[2], self.colors.success[3], 0.8)
            end
        else
            love.graphics.setColor(0.3, 0.3, 0.3, 0.7)
        end
        love.graphics.rectangle("fill", cardX + 8, btnY, cardW - 16, 22, 4, 4)

        love.graphics.setColor(1, 1, 1, canAfford and 1 or 0.5)
        local btnText = canAfford and "BUILD" or "LOCKED"
        local btnTextW = self.fonts.small:getWidth(btnText)
        love.graphics.print(btnText, cardX + (cardW - btnTextW) / 2, btnY + 4)

        -- Store card bounds for click detection
        self["buildCard_" .. i] = {x = cardX, y = cardY, w = cardW, h = cardH, buildingType = bType, canAfford = canAfford}

        ::continue::
    end

    love.graphics.setScissor()

    -- Scrollbar - only show if there's content to scroll
    if self.buildMenuMaxScroll > 0 then
        local scrollbarX = cardsX + cardsW + 5
        local scrollbarH = cardsH
        local thumbH = math.max(30, (cardsH / totalContentH) * scrollbarH)
        local scrollRatio = self.buildMenuScrollOffset / self.buildMenuMaxScroll
        local thumbY = cardsY + scrollRatio * (scrollbarH - thumbH)

        -- Scrollbar track
        love.graphics.setColor(0.15, 0.15, 0.18)
        love.graphics.rectangle("fill", scrollbarX, cardsY, 8, scrollbarH, 4, 4)

        -- Scrollbar thumb
        love.graphics.setColor(0.4, 0.4, 0.45)
        love.graphics.rectangle("fill", scrollbarX, thumbY, 8, thumbH, 4, 4)
    end

    -- No results message
    if #buildings == 0 then
        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(self.colors.textDim)
        local noResultsText = self.buildMenuSearchQuery ~= "" and "No buildings match your search" or "No buildings available"
        local textW = self.fonts.normal:getWidth(noResultsText)
        love.graphics.print(noResultsText, cardsX + (cardsW - textW) / 2, cardsY + cardsH / 2 - 10)
    end

    love.graphics.setColor(1, 1, 1)
end

-- =============================================================================
-- PRODUCTION ANALYTICS PANEL
-- =============================================================================

function AlphaUI:RenderProductionAnalyticsPanel()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Initialize state if needed (hot reload safety)
    self.productionAnalyticsTab = self.productionAnalyticsTab or "commodities"
    self.productionAnalyticsScrollOffset = self.productionAnalyticsScrollOffset or 0
    self.selectedAnalyticsCommodity = self.selectedAnalyticsCommodity or nil

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Panel dimensions (large centered panel)
    local panelW = math.min(900, screenW - 100)
    local panelH = screenH - self.topBarHeight - self.bottomBarHeight - 40
    local panelX = (screenW - panelW) / 2
    local panelY = self.topBarHeight + 20

    -- Panel background
    love.graphics.setColor(0.12, 0.12, 0.15)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 8, 8)

    -- Panel border
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 8, 8)

    -- Header
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Production Analytics", panelX + 20, panelY + 15)

    -- Close button
    local closeBtnX = panelX + panelW - 40
    local closeBtnY = panelY + 15
    local closeBtnSize = 25
    local mx, my = love.mouse.getPosition()
    local closeHover = mx >= closeBtnX and mx < closeBtnX + closeBtnSize and
                       my >= closeBtnY and my < closeBtnY + closeBtnSize

    love.graphics.setColor(closeHover and {0.8, 0.3, 0.3} or {0.5, 0.5, 0.5})
    love.graphics.rectangle("fill", closeBtnX, closeBtnY, closeBtnSize, closeBtnSize, 4, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.normal)
    love.graphics.print("X", closeBtnX + 7, closeBtnY + 3)

    self.productionAnalyticsCloseBtn = {x = closeBtnX, y = closeBtnY, w = closeBtnSize, h = closeBtnSize}

    -- Tab buttons
    local tabY = panelY + 55
    local tabX = panelX + 20
    local tabs = {
        {id = "commodities", label = "Commodities"},
        {id = "buildings", label = "Buildings"}
    }

    self.productionAnalyticsTabBtns = {}
    love.graphics.setFont(self.fonts.small)

    for _, tab in ipairs(tabs) do
        local tabW = self.fonts.small:getWidth(tab.label) + 24
        local tabH = 28
        local isActive = self.productionAnalyticsTab == tab.id
        local isHover = mx >= tabX and mx < tabX + tabW and my >= tabY and my < tabY + tabH

        if isActive then
            love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.7)
        elseif isHover then
            love.graphics.setColor(0.3, 0.3, 0.35)
        else
            love.graphics.setColor(0.2, 0.2, 0.25)
        end
        love.graphics.rectangle("fill", tabX, tabY, tabW, tabH, 4, 4)

        love.graphics.setColor(isActive and {1, 1, 1} or self.colors.textDim)
        love.graphics.print(tab.label, tabX + 12, tabY + 6)

        table.insert(self.productionAnalyticsTabBtns, {x = tabX, y = tabY, w = tabW, h = tabH, tabId = tab.id})
        tabX = tabX + tabW + 8
    end

    -- Content area
    local contentY = tabY + 40
    local contentH = panelH - (contentY - panelY) - 20

    if self.productionAnalyticsTab == "commodities" then
        self:RenderProductionCommoditiesTab(panelX + 15, contentY, panelW - 30, contentH)
    else
        self:RenderProductionBuildingsTab(panelX + 15, contentY, panelW - 30, contentH)
    end
end

function AlphaUI:RenderProductionCommoditiesTab(x, y, w, h)
    -- Get production metrics from world
    local metrics = self.world:GetProductionMetrics()
    if not metrics then
        love.graphics.setColor(self.colors.textDim)
        love.graphics.setFont(self.fonts.normal)
        love.graphics.print("No production data yet. Start some buildings producing!", x + 20, y + 20)
        return
    end

    -- Split into two columns: commodity list on left, detail on right
    local listW = 350
    local detailX = x + listW + 20
    local detailW = w - listW - 20

    -- Summary stats at top
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Worker Utilization:", x, y)

    local utilization = metrics.workerUtilization or 0
    local utilColor = utilization > 70 and self.colors.success or
                      utilization > 40 and self.colors.warning or
                      self.colors.danger
    love.graphics.setColor(utilColor)
    love.graphics.print(string.format("%.0f%% (%d/%d employed)", utilization,
        metrics.activeWorkers or 0, metrics.totalWorkers or 0), x + 140, y)

    -- Commodity list
    local listY = y + 35
    local listH = h - 35

    love.graphics.setColor(0.15, 0.15, 0.18)
    love.graphics.rectangle("fill", x, listY, listW, listH, 4, 4)

    -- Headers
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Commodity", x + 10, listY + 8)
    love.graphics.print("Prod/min", x + 180, listY + 8)
    love.graphics.print("Net", x + 260, listY + 8)
    love.graphics.print("Stock", x + 305, listY + 8)

    -- Get all commodities with production or consumption
    local commodityList = {}
    for commodityId, rate in pairs(metrics.productionRate or {}) do
        commodityList[commodityId] = commodityList[commodityId] or {}
        commodityList[commodityId].productionRate = rate
    end
    for commodityId, rate in pairs(metrics.consumptionRate or {}) do
        commodityList[commodityId] = commodityList[commodityId] or {}
        commodityList[commodityId].consumptionRate = rate
    end
    for commodityId, net in pairs(metrics.netProduction or {}) do
        commodityList[commodityId] = commodityList[commodityId] or {}
        commodityList[commodityId].netProduction = net
    end

    -- Convert to sorted array
    local sortedCommodities = {}
    for id, data in pairs(commodityList) do
        data.id = id
        data.productionRate = data.productionRate or 0
        data.consumptionRate = data.consumptionRate or 0
        data.netProduction = data.netProduction or 0
        -- Get current stock
        data.stock = self.world:GetInventoryCount(id)
        -- Get commodity name
        local commodity = self.world.commoditiesById[id]
        data.name = commodity and commodity.name or id
        table.insert(sortedCommodities, data)
    end

    -- Sort by production rate descending
    table.sort(sortedCommodities, function(a, b)
        return a.productionRate > b.productionRate
    end)

    -- Render commodity rows
    love.graphics.setScissor(x, listY + 30, listW, listH - 30)

    local rowY = listY + 30 - self.productionAnalyticsScrollOffset
    local rowH = 32
    self.productionAnalyticsCommodityBtns = {}

    for _, commodity in ipairs(sortedCommodities) do
        if rowY + rowH > listY + 30 and rowY < listY + listH then
            local mx, my = love.mouse.getPosition()
            local isHover = mx >= x and mx < x + listW and my >= rowY and my < rowY + rowH
            local isSelected = self.selectedAnalyticsCommodity == commodity.id

            -- Row background
            if isSelected then
                love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.3)
            elseif isHover then
                love.graphics.setColor(0.25, 0.25, 0.28)
            else
                love.graphics.setColor(0, 0, 0, 0)
            end
            love.graphics.rectangle("fill", x + 2, rowY, listW - 4, rowH)

            -- Commodity name
            love.graphics.setFont(self.fonts.small)
            love.graphics.setColor(1, 1, 1)
            local displayName = #commodity.name > 18 and commodity.name:sub(1, 16) .. ".." or commodity.name
            love.graphics.print(displayName, x + 10, rowY + 8)

            -- Production rate
            love.graphics.setColor(self.colors.success)
            love.graphics.print(string.format("%.1f", commodity.productionRate), x + 180, rowY + 8)

            -- Net production (color coded)
            local netColor = commodity.netProduction > 0 and self.colors.success or
                             commodity.netProduction < 0 and self.colors.danger or
                             self.colors.textDim
            love.graphics.setColor(netColor)
            local netPrefix = commodity.netProduction > 0 and "+" or ""
            love.graphics.print(netPrefix .. string.format("%.1f", commodity.netProduction), x + 260, rowY + 8)

            -- Stock
            love.graphics.setColor(self.colors.text)
            love.graphics.print(tostring(commodity.stock), x + 305, rowY + 8)

            table.insert(self.productionAnalyticsCommodityBtns, {
                x = x, y = rowY, w = listW, h = rowH, commodityId = commodity.id
            })
        end
        rowY = rowY + rowH
    end

    -- Update max scroll
    local totalHeight = #sortedCommodities * rowH
    self.productionAnalyticsMaxScroll = math.max(0, totalHeight - (listH - 30))

    love.graphics.setScissor()

    -- Scrollbar
    if self.productionAnalyticsMaxScroll > 0 then
        local scrollBarH = (listH - 30) * ((listH - 30) / totalHeight)
        local scrollBarY = listY + 30 + (self.productionAnalyticsScrollOffset / self.productionAnalyticsMaxScroll) * ((listH - 30) - scrollBarH)

        love.graphics.setColor(0.4, 0.4, 0.45)
        love.graphics.rectangle("fill", x + listW - 8, scrollBarY, 6, scrollBarH, 3, 3)
    end

    -- Detail panel (right side)
    love.graphics.setColor(0.15, 0.15, 0.18)
    love.graphics.rectangle("fill", detailX, listY, detailW, listH, 4, 4)

    if self.selectedAnalyticsCommodity then
        local commodity = nil
        for _, c in ipairs(sortedCommodities) do
            if c.id == self.selectedAnalyticsCommodity then
                commodity = c
                break
            end
        end

        if commodity then
            self:RenderCommodityDetail(detailX + 15, listY + 15, detailW - 30, listH - 30, commodity)
        end
    else
        love.graphics.setColor(self.colors.textDim)
        love.graphics.setFont(self.fonts.normal)
        love.graphics.print("Select a commodity to see details", detailX + 20, listY + 20)
    end
end

function AlphaUI:RenderCommodityDetail(x, y, w, h, commodity)
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(commodity.name, x, y)

    love.graphics.setFont(self.fonts.normal)

    -- Production rate
    local statY = y + 40
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Production Rate:", x, statY)
    love.graphics.setColor(self.colors.success)
    love.graphics.print(string.format("%.2f /min", commodity.productionRate), x + 150, statY)

    -- Consumption rate
    statY = statY + 25
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Consumption Rate:", x, statY)
    love.graphics.setColor(self.colors.danger)
    love.graphics.print(string.format("%.2f /min", commodity.consumptionRate), x + 150, statY)

    -- Net production
    statY = statY + 25
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Net Production:", x, statY)
    local netColor = commodity.netProduction > 0 and self.colors.success or
                     commodity.netProduction < 0 and self.colors.danger or
                     self.colors.textDim
    love.graphics.setColor(netColor)
    local netPrefix = commodity.netProduction > 0 and "+" or ""
    love.graphics.print(netPrefix .. string.format("%.2f /min", commodity.netProduction), x + 150, statY)

    -- Current stock
    statY = statY + 25
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Current Stock:", x, statY)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(tostring(commodity.stock), x + 150, statY)

    -- Time to depletion/surplus estimate
    statY = statY + 35
    love.graphics.setColor(self.colors.textDim)
    if commodity.netProduction < 0 and commodity.stock > 0 then
        local minutesToDepletion = commodity.stock / math.abs(commodity.netProduction)
        love.graphics.print("Est. Depletion:", x, statY)
        love.graphics.setColor(self.colors.warning)
        if minutesToDepletion < 60 then
            love.graphics.print(string.format("%.0f minutes", minutesToDepletion), x + 150, statY)
        else
            love.graphics.print(string.format("%.1f hours", minutesToDepletion / 60), x + 150, statY)
        end
    elseif commodity.netProduction > 0 then
        love.graphics.print("Status:", x, statY)
        love.graphics.setColor(self.colors.success)
        love.graphics.print("Surplus - Growing", x + 150, statY)
    else
        love.graphics.print("Status:", x, statY)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Balanced", x + 150, statY)
    end
end

function AlphaUI:RenderProductionBuildingsTab(x, y, w, h)
    -- Get building efficiencies from world
    local efficiencies = self.world:GetBuildingEfficiencies()

    if not efficiencies or #efficiencies == 0 then
        love.graphics.setColor(self.colors.textDim)
        love.graphics.setFont(self.fonts.normal)
        love.graphics.print("No buildings placed yet. Use the Build menu to add buildings!", x + 20, y + 20)
        return
    end

    -- Background
    love.graphics.setColor(0.15, 0.15, 0.18)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)

    -- Headers
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Building", x + 10, y + 10)
    love.graphics.print("Efficiency", x + 220, y + 10)
    love.graphics.print("Workers", x + 380, y + 10)
    love.graphics.print("Stations", x + 480, y + 10)
    love.graphics.print("Status", x + 590, y + 10)

    -- Building rows
    local rowY = y + 35
    local rowH = 40

    love.graphics.setScissor(x, y + 30, w, h - 30)

    for _, building in ipairs(efficiencies) do
        if rowY < y + h then
            -- Row background with efficiency color
            local effColor
            if building.efficiency >= 80 then
                effColor = {0.2, 0.4, 0.2, 0.3}
            elseif building.efficiency >= 50 then
                effColor = {0.4, 0.4, 0.2, 0.3}
            elseif building.efficiency > 0 then
                effColor = {0.4, 0.3, 0.2, 0.3}
            else
                effColor = {0.3, 0.2, 0.2, 0.3}
            end

            love.graphics.setColor(effColor)
            love.graphics.rectangle("fill", x + 2, rowY, w - 4, rowH - 2, 4, 4)

            -- Building name
            love.graphics.setFont(self.fonts.small)
            love.graphics.setColor(1, 1, 1)
            local displayName = #building.name > 25 and building.name:sub(1, 23) .. ".." or building.name
            love.graphics.print(displayName .. " #" .. building.id, x + 10, rowY + 5)

            -- Building type
            love.graphics.setColor(self.colors.textDim)
            love.graphics.setFont(self.fonts.tiny)
            love.graphics.print(building.typeId or "", x + 10, rowY + 22)

            -- Efficiency bar
            love.graphics.setFont(self.fonts.small)
            local barX = x + 220
            local barW = 100
            local barH = 16

            -- Bar background
            love.graphics.setColor(0.2, 0.2, 0.25)
            love.graphics.rectangle("fill", barX, rowY + 10, barW, barH, 3, 3)

            -- Bar fill
            local fillColor = building.efficiency >= 80 and self.colors.success or
                              building.efficiency >= 50 and self.colors.warning or
                              building.efficiency > 0 and {0.9, 0.6, 0.2} or
                              self.colors.danger
            love.graphics.setColor(fillColor)
            local fillW = (building.efficiency / 100) * barW
            if fillW > 0 then
                love.graphics.rectangle("fill", barX, rowY + 10, fillW, barH, 3, 3)
            end

            -- Efficiency text (inside bar)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(string.format("%.0f%%", building.efficiency), barX + barW + 10, rowY + 10)

            -- Workers
            local workerColor = building.workerCount >= building.maxWorkers and self.colors.success or
                                building.workerCount > 0 and self.colors.warning or
                                self.colors.danger
            love.graphics.setColor(workerColor)
            love.graphics.print(string.format("%d/%d", building.workerCount, building.maxWorkers), x + 380, rowY + 10)

            -- Stations
            love.graphics.setColor(self.colors.text)
            love.graphics.print(string.format("%d/%d active", building.producingStations, building.totalStations), x + 480, rowY + 10)

            -- Status
            local status, statusColor
            if building.producingStations > 0 then
                status = "Producing"
                statusColor = self.colors.success
            elseif building.activeStations > 0 and building.workerCount == 0 then
                status = "No Workers"
                statusColor = self.colors.danger
            elseif building.activeStations > 0 then
                status = "No Materials"
                statusColor = self.colors.warning
            elseif building.activeStations == 0 then
                status = "No Recipe"
                statusColor = self.colors.textDim
            else
                status = "Idle"
                statusColor = self.colors.textDim
            end

            love.graphics.setColor(statusColor)
            love.graphics.print(status, x + 590, rowY + 10)
        end
        rowY = rowY + rowH
    end

    love.graphics.setScissor()
end

function AlphaUI:HandleProductionAnalyticsPanelClick(x, y)
    -- Close button
    if self.productionAnalyticsCloseBtn then
        local btn = self.productionAnalyticsCloseBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.showProductionAnalyticsPanel = false
            return true
        end
    end

    -- Tab buttons
    for _, btn in ipairs(self.productionAnalyticsTabBtns or {}) do
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.productionAnalyticsTab = btn.tabId
            self.productionAnalyticsScrollOffset = 0
            self.selectedAnalyticsCommodity = nil
            return true
        end
    end

    -- Commodity list clicks (only on commodities tab)
    if self.productionAnalyticsTab == "commodities" then
        for _, btn in ipairs(self.productionAnalyticsCommodityBtns or {}) do
            if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
                self.selectedAnalyticsCommodity = btn.commodityId
                return true
            end
        end
    end

    return false
end

-- =============================================================================
-- INVENTORY PANEL
-- =============================================================================

function AlphaUI:RenderInventoryPanel()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Panel dimensions (drawer style from right)
    local panelW = 500
    local panelH = screenH - self.topBarHeight - self.bottomBarHeight
    local panelX = screenW - panelW
    local panelY = self.topBarHeight

    -- Panel background
    love.graphics.setColor(0.12, 0.12, 0.15, 0.98)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH)

    -- Panel border
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH)
    love.graphics.setLineWidth(1)

    -- Header
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("INVENTORY", panelX + 15, panelY + 12)

    -- Close button
    local closeX = panelX + panelW - 40
    local closeY = panelY + 10
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.danger)
    love.graphics.print("X", closeX + 8, closeY + 2)
    self.inventoryCloseBtn = {x = closeX, y = closeY, w = 30, h = 30}

    -- Category filters area (left column)
    local filterWidth = 140
    local filterX = panelX + 10
    local filterY = panelY + 50
    local filterH = panelH - 100  -- Leave room for summary at bottom

    -- Category filter background
    love.graphics.setColor(0.1, 0.1, 0.12)
    love.graphics.rectangle("fill", filterX, filterY, filterWidth, filterH, 4, 4)

    -- Store category area for scroll detection
    self.inventoryCategoryArea = {x = filterX, y = filterY, w = filterWidth, h = filterH}

    -- Get categories from data
    local categories = self:GetInventoryCategories()

    love.graphics.setFont(self.fonts.small)
    local categoryBtnH = 26
    local categorySpacing = 3
    local totalCategoryHeight = #categories * (categoryBtnH + categorySpacing)

    -- Calculate max scroll for categories
    self.inventoryCategoryMaxScroll = math.max(0, totalCategoryHeight - filterH + 10)

    -- Scissor for category scrolling
    love.graphics.setScissor(filterX, filterY, filterWidth, filterH)

    -- Store category buttons for click detection
    self.inventoryCategoryBtns = {}

    -- Ensure scroll offset is initialized
    self.inventoryCategoryScrollOffset = self.inventoryCategoryScrollOffset or 0

    for i, cat in ipairs(categories) do
        local btnX = filterX + 5
        local btnY = filterY + 5 + (i - 1) * (categoryBtnH + categorySpacing) - self.inventoryCategoryScrollOffset
        local btnW = filterWidth - 10

        -- Store button for click detection (always, even if not visible)
        -- But clamp the clickable area to the visible filter region
        local clickY = math.max(filterY, btnY)
        local clickH = math.min(btnY + categoryBtnH, filterY + filterH) - clickY
        if clickH > 0 then
            table.insert(self.inventoryCategoryBtns, {x = btnX, y = clickY, w = btnW, h = clickH, categoryId = cat.id})
        end

        -- Only render if visible
        if btnY + categoryBtnH >= filterY and btnY <= filterY + filterH then
            local isActive = self.inventoryFilter == cat.id
            local mx, my = love.mouse.getPosition()
            local isHovering = mx >= btnX and mx <= btnX + btnW and
                              my >= btnY and my <= btnY + categoryBtnH

            if isActive then
                love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.6)
            elseif isHovering then
                love.graphics.setColor(0.3, 0.3, 0.35)
            else
                love.graphics.setColor(0.2, 0.2, 0.22)
            end
            love.graphics.rectangle("fill", btnX, btnY, btnW, categoryBtnH, 3, 3)

            love.graphics.setColor(isActive and {1, 1, 1} or self.colors.textDim)
            love.graphics.print(cat.name, btnX + 8, btnY + 5)
        end
    end

    love.graphics.setScissor()

    -- Draw category scrollbar if needed
    if self.inventoryCategoryMaxScroll > 0 then
        local scrollbarHeight = math.max(20, filterH * (filterH / totalCategoryHeight))
        local scrollbarY = filterY + (self.inventoryCategoryScrollOffset / self.inventoryCategoryMaxScroll) * (filterH - scrollbarHeight)

        love.graphics.setColor(0.4, 0.4, 0.4, 0.6)
        love.graphics.rectangle("fill", filterX + filterWidth - 6, scrollbarY, 4, scrollbarHeight, 2, 2)
    end

    -- Commodity list area (right column)
    local listX = panelX + filterWidth + 20
    local listY = filterY
    local listW = panelW - filterWidth - 35
    local listH = filterH

    -- List background
    love.graphics.setColor(0.15, 0.15, 0.17)
    love.graphics.rectangle("fill", listX, listY, listW, listH, 4, 4)

    -- Get filtered commodities
    local filteredCommodities = self:GetFilteredCommodities()

    -- Scissor for scrolling
    love.graphics.setScissor(listX, listY, listW, listH)

    local itemHeight = 32
    local y = listY + 5 - self.inventoryScrollOffset

    -- Calculate max scroll
    local totalItemsHeight = #filteredCommodities * itemHeight
    self.inventoryMaxScroll = math.max(0, totalItemsHeight - listH + 10)

    -- Store item bounds for click detection
    self.inventoryItemBtns = {}

    for i, item in ipairs(filteredCommodities) do
        if y + itemHeight >= listY and y <= listY + listH then
            -- Alternating row colors
            if i % 2 == 0 then
                love.graphics.setColor(0.18, 0.18, 0.2)
            else
                love.graphics.setColor(0.16, 0.16, 0.18)
            end
            love.graphics.rectangle("fill", listX + 3, y, listW - 6, itemHeight - 2, 2, 2)

            -- Icon placeholder
            local iconBg = {0.6, 0.6, 0.4}
            if item.commodity.category then
                local catInfo = self.world.commodityCategoriesById[item.commodity.category]
                if catInfo and catInfo.color then
                    -- Parse hex color
                    local hex = catInfo.color:gsub("#", "")
                    iconBg = {
                        tonumber(hex:sub(1, 2), 16) / 255,
                        tonumber(hex:sub(3, 4), 16) / 255,
                        tonumber(hex:sub(5, 6), 16) / 255
                    }
                end
            end
            love.graphics.setColor(iconBg[1], iconBg[2], iconBg[3], 0.8)
            love.graphics.rectangle("fill", listX + 8, y + 4, 24, 24, 3, 3)

            -- Icon text
            love.graphics.setColor(0, 0, 0)
            love.graphics.setFont(self.fonts.tiny)
            local icon = item.commodity.icon or item.commodity.id:sub(1, 2):upper()
            love.graphics.print(icon, listX + 11, y + 8)

            -- Commodity name
            love.graphics.setFont(self.fonts.small)
            love.graphics.setColor(1, 1, 1)
            local name = item.commodity.name or item.commodity.id
            if #name > 18 then name = name:sub(1, 16) .. ".." end
            love.graphics.print(name, listX + 40, y + 4)

            -- Category label
            love.graphics.setFont(self.fonts.tiny)
            love.graphics.setColor(self.colors.textDim)
            local catName = item.commodity.category or "misc"
            love.graphics.print(catName, listX + 40, y + 18)

            -- "?" button for supply chain viewer
            local infoSize = 18
            local infoX = listX + listW - 85
            local infoY = y + 6
            local mx, my = love.mouse.getPosition()
            local isHoveringInfo = mx >= infoX and mx <= infoX + infoSize and
                                   my >= infoY and my <= infoY + infoSize

            love.graphics.setColor(isHoveringInfo and 0.4 or 0.3, isHoveringInfo and 0.6 or 0.5, isHoveringInfo and 0.9 or 0.8, 0.9)
            love.graphics.circle("fill", infoX + infoSize/2, infoY + infoSize/2, infoSize/2)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(self.fonts.small)
            local qWidth = self.fonts.small:getWidth("?")
            love.graphics.print("?", infoX + (infoSize - qWidth)/2, infoY + 1)

            -- Quantity
            love.graphics.setFont(self.fonts.normal)
            local quantity = item.quantity or 0
            local quantityText = self:FormatNumber(quantity)
            local quantityColor = quantity > 0 and self.colors.success or {0.5, 0.5, 0.5}
            love.graphics.setColor(quantityColor[1], quantityColor[2], quantityColor[3])
            local textWidth = self.fonts.normal:getWidth(quantityText)
            love.graphics.print(quantityText, listX + listW - textWidth - 12, y + 7)

            -- Store item bounds with info button area
            self.inventoryItemBtns[i] = {
                x = listX + 3, y = y, w = listW - 6, h = itemHeight - 2,
                commodity = item.commodity,
                infoBtn = {x = infoX, y = infoY, w = infoSize, h = infoSize}
            }
        end

        y = y + itemHeight
    end

    love.graphics.setScissor()

    -- Draw scrollbar if needed
    if self.inventoryMaxScroll > 0 then
        local scrollbarHeight = math.max(30, listH * (listH / totalItemsHeight))
        local scrollbarY = listY + (self.inventoryScrollOffset / self.inventoryMaxScroll) * (listH - scrollbarHeight)

        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", listX + listW - 8, scrollbarY, 6, scrollbarHeight, 3, 3)
    end

    -- Summary at bottom
    local summaryY = panelY + panelH - 45
    love.graphics.setColor(0.2, 0.2, 0.22)
    love.graphics.rectangle("fill", panelX + 10, summaryY, panelW - 20, 35, 4, 4)

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Total Items: " .. #filteredCommodities, panelX + 20, summaryY + 10)

    -- Total value (sum of quantities * baseValue)
    local totalValue = 0
    for _, item in ipairs(filteredCommodities) do
        totalValue = totalValue + (item.quantity * (item.commodity.baseValue or 1))
    end
    love.graphics.setColor(self.colors.gold)
    love.graphics.print("Est. Value: " .. self:FormatNumber(totalValue) .. " G", panelX + 200, summaryY + 10)

    love.graphics.setColor(1, 1, 1)
end

-- =============================================================================
-- CITIZENS OVERVIEW PANEL
-- =============================================================================

function AlphaUI:RenderCitizensPanel()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Defensive initialization for state variables (in case of hot reload)
    self.citizensPerPage = self.citizensPerPage or 20
    self.citizensPage = self.citizensPage or 1
    self.citizensFilter = self.citizensFilter or "all"
    self.citizensStatusFilter = self.citizensStatusFilter or "all"
    self.citizensSort = self.citizensSort or "satisfaction"
    self.citizensSortAsc = self.citizensSortAsc or false
    self.citizensViewMode = self.citizensViewMode or "grid"

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Panel dimensions (large modal covering most of screen)
    local panelW = math.min(1000, screenW - 100)
    local panelH = screenH - self.topBarHeight - self.bottomBarHeight - 40
    local panelX = (screenW - panelW) / 2
    local panelY = self.topBarHeight + 20

    -- Panel background
    love.graphics.setColor(0.12, 0.12, 0.15, 0.98)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 8, 8)

    -- Panel border
    love.graphics.setColor(0.4, 0.5, 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 8, 8)
    love.graphics.setLineWidth(1)

    -- Header with title and count
    local totalCitizens = #self.world.citizens
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("CITIZENS (" .. totalCitizens .. ")", panelX + 20, panelY + 12)

    -- Close button
    local closeX = panelX + panelW - 40
    local closeY = panelY + 10
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.danger)
    love.graphics.print("X", closeX + 8, closeY + 2)
    self.citizensCloseBtn = {x = closeX, y = closeY, w = 30, h = 30}

    -- Filter row
    local filterY = panelY + 50
    self:RenderCitizensFilterBar(panelX + 15, filterY, panelW - 30)

    -- Sort and view controls row
    local controlsY = filterY + 35
    self:RenderCitizensSortBar(panelX + 15, controlsY, panelW - 30)

    -- Main content area (grid/list of citizens)
    local contentY = controlsY + 40
    local contentH = panelH - (contentY - panelY) - 60  -- Leave space for summary

    -- Get filtered and sorted citizens
    local filteredCitizens = self:GetFilteredCitizens()
    local sortedCitizens = self:GetSortedCitizens(filteredCitizens)

    -- Pagination
    local totalPages = math.max(1, math.ceil(#sortedCitizens / self.citizensPerPage))
    self.citizensPage = math.max(1, math.min(self.citizensPage, totalPages))
    local startIdx = (self.citizensPage - 1) * self.citizensPerPage + 1
    local endIdx = math.min(startIdx + self.citizensPerPage - 1, #sortedCitizens)
    local pageCitizens = {}
    for i = startIdx, endIdx do
        table.insert(pageCitizens, sortedCitizens[i])
    end

    -- Render citizen cards
    if self.citizensViewMode == "grid" then
        self:RenderCitizensGrid(panelX + 15, contentY, panelW - 30, contentH, pageCitizens)
    else
        self:RenderCitizensList(panelX + 15, contentY, panelW - 30, contentH, pageCitizens)
    end

    -- Summary bar and pagination at bottom
    local summaryY = panelY + panelH - 50
    self:RenderCitizensSummary(panelX + 15, summaryY, panelW - 30, filteredCitizens, totalPages)

    love.graphics.setColor(1, 1, 1)
end

function AlphaUI:RenderCitizensFilterBar(x, y, w)
    love.graphics.setFont(self.fonts.small)

    -- Class filter
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("CLASS:", x, y + 4)

    local classFilters = {
        {id = "all", label = "All"},
        {id = "elite", label = "Elite"},
        {id = "upper", label = "Upper"},
        {id = "middle", label = "Middle"},
        {id = "lower", label = "Lower"}
    }

    self.citizensFilterBtns = {}
    local btnX = x + 50
    local btnH = 22
    local btnPadding = 5

    for _, filter in ipairs(classFilters) do
        local btnW = self.fonts.small:getWidth(filter.label) + 16
        local isActive = self.citizensFilter == filter.id
        local mx, my = love.mouse.getPosition()
        local isHover = mx >= btnX and mx < btnX + btnW and my >= y and my < y + btnH

        if isActive then
            love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.7)
        elseif isHover then
            love.graphics.setColor(0.35, 0.35, 0.4)
        else
            love.graphics.setColor(0.25, 0.25, 0.28)
        end
        love.graphics.rectangle("fill", btnX, y, btnW, btnH, 3, 3)

        love.graphics.setColor(isActive and {1, 1, 1} or self.colors.textDim)
        love.graphics.print(filter.label, btnX + 8, y + 4)

        table.insert(self.citizensFilterBtns, {x = btnX, y = y, w = btnW, h = btnH, filterId = filter.id})
        btnX = btnX + btnW + btnPadding
    end

    -- Status filter
    btnX = btnX + 30
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("STATUS:", btnX, y + 4)
    btnX = btnX + 55

    local statusFilters = {
        {id = "all", label = "All"},
        {id = "happy", label = "Happy", color = self.colors.satisfactionHigh},
        {id = "neutral", label = "Neutral", color = self.colors.satisfactionMed},
        {id = "stressed", label = "Stressed", color = {0.9, 0.6, 0.3}},
        {id = "critical", label = "Critical", color = self.colors.satisfactionLow},
        {id = "protesting", label = "Protesting", color = {0.8, 0.3, 0.8}}
    }

    self.citizensStatusFilterBtns = {}

    for _, filter in ipairs(statusFilters) do
        local btnW = self.fonts.small:getWidth(filter.label) + 16
        local isActive = self.citizensStatusFilter == filter.id
        local mx, my = love.mouse.getPosition()
        local isHover = mx >= btnX and mx < btnX + btnW and my >= y and my < y + btnH

        if isActive then
            if filter.color then
                love.graphics.setColor(filter.color[1], filter.color[2], filter.color[3], 0.7)
            else
                love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.7)
            end
        elseif isHover then
            love.graphics.setColor(0.35, 0.35, 0.4)
        else
            love.graphics.setColor(0.25, 0.25, 0.28)
        end
        love.graphics.rectangle("fill", btnX, y, btnW, btnH, 3, 3)

        love.graphics.setColor(isActive and {1, 1, 1} or self.colors.textDim)
        love.graphics.print(filter.label, btnX + 8, y + 4)

        table.insert(self.citizensStatusFilterBtns, {x = btnX, y = y, w = btnW, h = btnH, statusId = filter.id})
        btnX = btnX + btnW + btnPadding
    end
end

function AlphaUI:RenderCitizensSortBar(x, y, w)
    love.graphics.setFont(self.fonts.small)

    -- Sort options
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("SORT BY:", x, y + 4)

    local sortOptions = {
        {id = "satisfaction", label = "Satisfaction"},
        {id = "name", label = "Name"},
        {id = "class", label = "Class"},
        {id = "age", label = "Age"},
        {id = "vocation", label = "Vocation"}
    }

    self.citizensSortBtns = {}
    local btnX = x + 65
    local btnH = 22
    local btnPadding = 5

    for _, opt in ipairs(sortOptions) do
        local btnW = self.fonts.small:getWidth(opt.label) + 16
        local isActive = self.citizensSort == opt.id
        local mx, my = love.mouse.getPosition()
        local isHover = mx >= btnX and mx < btnX + btnW and my >= y and my < y + btnH

        if isActive then
            love.graphics.setColor(0.3, 0.5, 0.7)
        elseif isHover then
            love.graphics.setColor(0.35, 0.35, 0.4)
        else
            love.graphics.setColor(0.25, 0.25, 0.28)
        end
        love.graphics.rectangle("fill", btnX, y, btnW, btnH, 3, 3)

        love.graphics.setColor(isActive and {1, 1, 1} or self.colors.textDim)
        local arrow = isActive and (self.citizensSortAsc and " ^" or " v") or ""
        love.graphics.print(opt.label .. arrow, btnX + 8, y + 4)

        table.insert(self.citizensSortBtns, {x = btnX, y = y, w = btnW, h = btnH, sortId = opt.id})
        btnX = btnX + btnW + btnPadding
    end

    -- View mode toggle (right side)
    local viewModes = {
        {id = "grid", label = "Grid"},
        {id = "list", label = "List"}
    }

    self.citizensViewBtns = {}
    local viewX = x + w - 120

    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("VIEW:", viewX - 45, y + 4)

    for _, mode in ipairs(viewModes) do
        local btnW = self.fonts.small:getWidth(mode.label) + 16
        local isActive = self.citizensViewMode == mode.id
        local mx, my = love.mouse.getPosition()
        local isHover = mx >= viewX and mx < viewX + btnW and my >= y and my < y + btnH

        if isActive then
            love.graphics.setColor(0.4, 0.6, 0.4)
        elseif isHover then
            love.graphics.setColor(0.35, 0.35, 0.4)
        else
            love.graphics.setColor(0.25, 0.25, 0.28)
        end
        love.graphics.rectangle("fill", viewX, y, btnW, btnH, 3, 3)

        love.graphics.setColor(isActive and {1, 1, 1} or self.colors.textDim)
        love.graphics.print(mode.label, viewX + 8, y + 4)

        table.insert(self.citizensViewBtns, {x = viewX, y = y, w = btnW, h = btnH, modeId = mode.id})
        viewX = viewX + btnW + btnPadding
    end
end

function AlphaUI:RenderCitizensGrid(x, y, w, h, citizens)
    -- Grid layout: cards arranged in a grid
    local cardW = 150
    local cardH = 85
    local cardSpacing = 8
    local cardsPerRow = math.floor((w + cardSpacing) / (cardW + cardSpacing))
    cardsPerRow = math.max(1, cardsPerRow)

    -- Background
    love.graphics.setColor(0.08, 0.08, 0.1)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)

    -- Scissor for scrolling (not needed with pagination but keeping for safety)
    love.graphics.setScissor(x, y, w, h)

    self.citizensCardBtns = {}

    for i, citizen in ipairs(citizens) do
        local col = (i - 1) % cardsPerRow
        local row = math.floor((i - 1) / cardsPerRow)
        local cardX = x + 8 + col * (cardW + cardSpacing)
        local cardY = y + 8 + row * (cardH + cardSpacing)

        -- Skip if off-screen
        if cardY + cardH > y + h then
            break
        end

        self:RenderCitizenCard(cardX, cardY, cardW, cardH, citizen, i)
    end

    love.graphics.setScissor()

    -- Show empty message if no citizens
    if #citizens == 0 then
        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("No citizens match the current filters", x + 20, y + 30)
    end
end

function AlphaUI:RenderCitizensList(x, y, w, h, citizens)
    -- List layout: horizontal rows with more detail
    local rowH = 32
    local rowSpacing = 2

    -- Background
    love.graphics.setColor(0.08, 0.08, 0.1)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)

    -- Header row
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    local headerY = y + 5
    love.graphics.print("NAME", x + 10, headerY)
    love.graphics.print("CLASS", x + 140, headerY)
    love.graphics.print("VOCATION", x + 210, headerY)
    love.graphics.print("AGE", x + 310, headerY)
    love.graphics.print("SATISFACTION", x + 350, headerY)
    love.graphics.print("STATUS", x + 480, headerY)
    love.graphics.print("WORKPLACE", x + 570, headerY)

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x + 5, headerY + 14, x + w - 5, headerY + 14)

    local listY = headerY + 20
    local listH = h - 25

    -- Calculate scroll for list view
    local totalHeight = #citizens * (rowH + rowSpacing)
    self.citizensMaxScroll = math.max(0, totalHeight - listH)
    self.citizensScrollOffset = self.citizensScrollOffset or 0
    self.citizensScrollOffset = math.max(0, math.min(self.citizensScrollOffset, self.citizensMaxScroll))

    -- Store list area for scroll detection
    self.citizensListArea = {x = x, y = listY, w = w, h = listH}

    love.graphics.setScissor(x, listY, w, listH)

    self.citizensCardBtns = {}

    for i, citizen in ipairs(citizens) do
        local rowY = listY + (i - 1) * (rowH + rowSpacing) - self.citizensScrollOffset

        -- Skip if off-screen
        if rowY + rowH < listY or rowY > listY + listH then
            goto continue
        end

        self:RenderCitizenRow(x + 5, rowY, w - 10, rowH, citizen, i)

        ::continue::
    end

    love.graphics.setScissor()

    -- Scrollbar if needed
    if self.citizensMaxScroll > 0 then
        local scrollbarH = math.max(30, listH * (listH / totalHeight))
        local scrollbarY = listY + (self.citizensScrollOffset / self.citizensMaxScroll) * (listH - scrollbarH)
        love.graphics.setColor(0.5, 0.5, 0.5, 0.6)
        love.graphics.rectangle("fill", x + w - 8, scrollbarY, 6, scrollbarH, 3, 3)
    end

    -- Show empty message if no citizens
    if #citizens == 0 then
        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("No citizens match the current filters", x + 20, listY + 30)
    end
end

function AlphaUI:RenderCitizenCard(x, y, w, h, citizen, index)
    -- Calculate satisfaction
    local avgSat = citizen:GetAverageSatisfaction()
    local satColor, satStatus = self:GetSatisfactionColorAndStatus(avgSat)

    -- Card background with satisfaction-tinted border
    local mx, my = love.mouse.getPosition()
    local isHover = mx >= x and mx < x + w and my >= y and my < y + h

    if isHover then
        love.graphics.setColor(0.22, 0.22, 0.25)
    else
        love.graphics.setColor(0.15, 0.15, 0.18)
    end
    love.graphics.rectangle("fill", x, y, w, h, 5, 5)

    -- Satisfaction indicator strip on left
    love.graphics.setColor(satColor[1], satColor[2], satColor[3])
    love.graphics.rectangle("fill", x, y, 4, h, 5, 0)

    -- Name (truncate shorter to avoid overlap with status badge)
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.text)
    local displayName = citizen.name or "Unknown"
    if #displayName > 12 then displayName = displayName:sub(1, 10) .. ".." end
    love.graphics.print(displayName, x + 10, y + 6)

    -- Status badge (top right corner)
    local statusText = satStatus
    if citizen.isProtesting then statusText = "PROTEST" end
    local statusColor = satColor
    if citizen.isProtesting then statusColor = {0.8, 0.3, 0.8} end

    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(statusColor[1], statusColor[2], statusColor[3], 0.6)
    local statusW = self.fonts.tiny:getWidth(statusText) + 6
    love.graphics.rectangle("fill", x + w - statusW - 5, y + 5, statusW, 12, 2, 2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(statusText, x + w - statusW - 2, y + 6)

    -- Class badge (below name)
    love.graphics.setFont(self.fonts.tiny)
    local classColor = self:GetClassColor(citizen.class)
    love.graphics.setColor(classColor[1], classColor[2], classColor[3], 0.7)
    local classBadgeW = self.fonts.tiny:getWidth(citizen.class) + 8
    love.graphics.rectangle("fill", x + 10, y + 22, classBadgeW, 13, 2, 2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(citizen.class, x + 14, y + 23)

    -- Satisfaction bar
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print(string.format("Sat: %d%%", math.floor(avgSat)), x + 10, y + 40)

    -- Mini satisfaction bar
    local barX = x + 55
    local barY = y + 42
    local barW = w - 65
    local barH = 8
    love.graphics.setColor(0.2, 0.2, 0.22)
    love.graphics.rectangle("fill", barX, barY, barW, barH, 2, 2)
    love.graphics.setColor(satColor[1], satColor[2], satColor[3])
    love.graphics.rectangle("fill", barX, barY, barW * (avgSat / 100), barH, 2, 2)

    -- Vocation
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    local vocation = citizen.vocation or "None"
    if #vocation > 18 then vocation = vocation:sub(1, 16) .. ".." end
    love.graphics.print(vocation, x + 10, y + 55)

    -- Workplace indicator
    love.graphics.setFont(self.fonts.tiny)
    local workplace = citizen.workplace and citizen.workplace.name or "Unemployed"
    if #workplace > 18 then workplace = workplace:sub(1, 16) .. ".." end
    local wpColor = citizen.workplace and self.colors.success or self.colors.warning
    love.graphics.setColor(wpColor[1], wpColor[2], wpColor[3], 0.8)
    love.graphics.print(workplace, x + 10, y + 68)

    -- Store card for click detection
    table.insert(self.citizensCardBtns, {x = x, y = y, w = w, h = h, citizen = citizen})
end

function AlphaUI:RenderCitizenRow(x, y, w, h, citizen, index)
    -- Calculate satisfaction
    local avgSat = citizen:GetAverageSatisfaction()
    local satColor, satStatus = self:GetSatisfactionColorAndStatus(avgSat)

    -- Row background
    local mx, my = love.mouse.getPosition()
    local isHover = mx >= x and mx < x + w and my >= y and my < y + h

    if isHover then
        love.graphics.setColor(0.22, 0.22, 0.25)
    elseif index % 2 == 0 then
        love.graphics.setColor(0.14, 0.14, 0.16)
    else
        love.graphics.setColor(0.12, 0.12, 0.14)
    end
    love.graphics.rectangle("fill", x, y, w, h, 2, 2)

    -- Satisfaction indicator strip
    love.graphics.setColor(satColor[1], satColor[2], satColor[3])
    love.graphics.rectangle("fill", x, y, 3, h, 2, 0)

    -- Centered Y offset for text in smaller row
    local textY = y + (h - 12) / 2

    -- Name
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.text)
    local displayName = citizen.name or "Unknown"
    if #displayName > 14 then displayName = displayName:sub(1, 12) .. ".." end
    love.graphics.print(displayName, x + 8, textY)

    -- Class
    love.graphics.setFont(self.fonts.tiny)
    local classColor = self:GetClassColor(citizen.class)
    love.graphics.setColor(classColor[1], classColor[2], classColor[3])
    love.graphics.print(citizen.class, x + 135, textY)

    -- Vocation
    love.graphics.setColor(self.colors.textDim)
    local vocation = citizen.vocation or "None"
    if #vocation > 12 then vocation = vocation:sub(1, 10) .. ".." end
    love.graphics.print(vocation, x + 205, textY)

    -- Age
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print(tostring(citizen.age), x + 305, textY)

    -- Satisfaction with mini bar
    love.graphics.setColor(satColor[1], satColor[2], satColor[3])
    love.graphics.print(string.format("%d%%", math.floor(avgSat)), x + 345, textY)

    -- Mini bar
    local barX = x + 380
    local barY = y + (h - 6) / 2
    local barW = 80
    local barH = 6
    love.graphics.setColor(0.2, 0.2, 0.22)
    love.graphics.rectangle("fill", barX, barY, barW, barH, 2, 2)
    love.graphics.setColor(satColor[1], satColor[2], satColor[3])
    love.graphics.rectangle("fill", barX, barY, barW * (avgSat / 100), barH, 2, 2)

    -- Status
    local statusText = satStatus
    if citizen.isProtesting then statusText = "PROTEST" end
    local statusColor = satColor
    if citizen.isProtesting then statusColor = {0.8, 0.3, 0.8} end
    love.graphics.setColor(statusColor[1], statusColor[2], statusColor[3])
    love.graphics.print(statusText, x + 475, textY)

    -- Workplace
    local workplace = citizen.workplace and citizen.workplace.name or "Unemployed"
    if #workplace > 14 then workplace = workplace:sub(1, 12) .. ".." end
    local wpColor = citizen.workplace and self.colors.textDim or self.colors.warning
    love.graphics.setColor(wpColor[1], wpColor[2], wpColor[3])
    love.graphics.print(workplace, x + 565, textY)

    -- Store row for click detection
    table.insert(self.citizensCardBtns, {x = x, y = y, w = w, h = h, citizen = citizen})
end

function AlphaUI:RenderCitizensSummary(x, y, w, filteredCitizens, totalPages)
    -- Summary bar background
    love.graphics.setColor(0.2, 0.2, 0.22)
    love.graphics.rectangle("fill", x, y, w, 40, 4, 4)

    -- Calculate stats
    local totalSat = 0
    local unemployed = 0
    local atRisk = 0
    local protesting = 0

    for _, citizen in ipairs(filteredCitizens) do
        local sat = citizen:GetAverageSatisfaction()
        totalSat = totalSat + sat
        if not citizen.workplace then unemployed = unemployed + 1 end
        if sat < 30 then atRisk = atRisk + 1 end
        if citizen.isProtesting then protesting = protesting + 1 end
    end

    local avgSat = #filteredCitizens > 0 and (totalSat / #filteredCitizens) or 0

    -- Stats
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print(string.format("Showing: %d citizens", #filteredCitizens), x + 15, y + 5)

    love.graphics.print(string.format("Avg Satisfaction: %.0f%%", avgSat), x + 15, y + 22)

    local unemployedColor = unemployed > 0 and self.colors.warning or self.colors.textDim
    love.graphics.setColor(unemployedColor[1], unemployedColor[2], unemployedColor[3])
    love.graphics.print(string.format("Unemployed: %d", unemployed), x + 180, y + 5)

    local atRiskColor = atRisk > 0 and self.colors.danger or self.colors.textDim
    love.graphics.setColor(atRiskColor[1], atRiskColor[2], atRiskColor[3])
    love.graphics.print(string.format("At-Risk: %d", atRisk), x + 300, y + 5)

    local protestColor = protesting > 0 and {0.8, 0.3, 0.8} or self.colors.textDim
    love.graphics.setColor(protestColor[1], protestColor[2], protestColor[3])
    love.graphics.print(string.format("Protesting: %d", protesting), x + 400, y + 5)

    -- Pagination controls (right side)
    local pageText = string.format("Page %d of %d", self.citizensPage, totalPages)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print(pageText, x + w - 200, y + 12)

    -- Prev button
    local prevBtnX = x + w - 100
    local prevBtnY = y + 8
    local btnW = 40
    local btnH = 24
    local canPrev = self.citizensPage > 1
    love.graphics.setColor(canPrev and self.colors.button or {0.2, 0.2, 0.2})
    love.graphics.rectangle("fill", prevBtnX, prevBtnY, btnW, btnH, 3, 3)
    love.graphics.setColor(canPrev and self.colors.text or {0.4, 0.4, 0.4})
    love.graphics.print("<", prevBtnX + 16, prevBtnY + 5)
    self.citizensPrevPageBtn = {x = prevBtnX, y = prevBtnY, w = btnW, h = btnH, enabled = canPrev}

    -- Next button
    local nextBtnX = x + w - 50
    local canNext = self.citizensPage < totalPages
    love.graphics.setColor(canNext and self.colors.button or {0.2, 0.2, 0.2})
    love.graphics.rectangle("fill", nextBtnX, prevBtnY, btnW, btnH, 3, 3)
    love.graphics.setColor(canNext and self.colors.text or {0.4, 0.4, 0.4})
    love.graphics.print(">", nextBtnX + 16, prevBtnY + 5)
    self.citizensNextPageBtn = {x = nextBtnX, y = prevBtnY, w = btnW, h = btnH, enabled = canNext}
end

-- Helper function to get satisfaction color and status text
function AlphaUI:GetSatisfactionColorAndStatus(sat)
    if sat >= 70 then
        return self.colors.satisfactionHigh, "Happy"
    elseif sat >= 40 then
        return self.colors.satisfactionMed, "Neutral"
    elseif sat >= 20 then
        return {0.9, 0.6, 0.3}, "Stressed"
    else
        return self.colors.satisfactionLow, "Critical"
    end
end

-- Helper function to get class color
function AlphaUI:GetClassColor(class)
    local classLower = string.lower(class or "middle")
    if classLower == "elite" then
        return {0.9, 0.7, 0.3}  -- Gold
    elseif classLower == "upper" then
        return {0.6, 0.5, 0.9}  -- Purple
    elseif classLower == "middle" then
        return {0.4, 0.7, 0.9}  -- Blue
    else
        return {0.6, 0.6, 0.6}  -- Gray for lower
    end
end

-- Helper function to get satisfaction gradient color (red to green)
function AlphaUI:GetSatisfactionGradientColor(satisfaction)
    local sat = math.max(0, math.min(100, satisfaction))
    local r, g, b

    if sat < 25 then
        -- Red to Orange
        local t = sat / 25
        r, g, b = 0.9, 0.2 + t * 0.4, 0.2
    elseif sat < 50 then
        -- Orange to Yellow
        local t = (sat - 25) / 25
        r, g, b = 0.9, 0.6 + t * 0.3, 0.2
    elseif sat < 75 then
        -- Yellow to Light Green
        local t = (sat - 50) / 25
        r, g, b = 0.9 - t * 0.5, 0.9, 0.2 + t * 0.2
    else
        -- Light Green to Green
        local t = (sat - 75) / 25
        r, g, b = 0.4 - t * 0.1, 0.9, 0.4 - t * 0.1
    end

    return {r, g, b}
end

-- Helper function to draw emoticon expression based on satisfaction
function AlphaUI:DrawEmoticonExpression(cx, cy, radius, satisfaction)
    local eyeOffsetX = radius * 0.35
    local eyeOffsetY = radius * 0.15
    local eyeRadius = radius * 0.12

    -- Draw eyes (black dots)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", cx - eyeOffsetX, cy - eyeOffsetY, eyeRadius)
    love.graphics.circle("fill", cx + eyeOffsetX, cy - eyeOffsetY, eyeRadius)

    -- Draw mouth based on satisfaction
    local mouthY = cy + radius * 0.25
    local mouthWidth = radius * 0.5
    love.graphics.setLineWidth(2)

    if satisfaction >= 70 then
        -- Big smile
        love.graphics.arc("line", "open", cx, mouthY - radius * 0.1, mouthWidth, 0.2, math.pi - 0.2)
    elseif satisfaction >= 50 then
        -- Small smile
        love.graphics.arc("line", "open", cx, mouthY - radius * 0.05, mouthWidth * 0.7, 0.3, math.pi - 0.3)
    elseif satisfaction >= 30 then
        -- Neutral line
        love.graphics.line(cx - mouthWidth * 0.4, mouthY, cx + mouthWidth * 0.4, mouthY)
    elseif satisfaction >= 15 then
        -- Slight frown
        love.graphics.arc("line", "open", cx, mouthY + radius * 0.15, mouthWidth * 0.6, math.pi + 0.4, 2 * math.pi - 0.4)
    else
        -- Big frown + worried eyebrows
        love.graphics.arc("line", "open", cx, mouthY + radius * 0.25, mouthWidth * 0.8, math.pi + 0.2, 2 * math.pi - 0.2)
        -- Worried eyebrows
        love.graphics.line(cx - eyeOffsetX - eyeRadius, cy - eyeOffsetY - eyeRadius * 2,
                          cx - eyeOffsetX + eyeRadius, cy - eyeOffsetY - eyeRadius)
        love.graphics.line(cx + eyeOffsetX - eyeRadius, cy - eyeOffsetY - eyeRadius,
                          cx + eyeOffsetX + eyeRadius, cy - eyeOffsetY - eyeRadius * 2)
    end

    love.graphics.setLineWidth(1)
end

-- Get filtered citizens based on current filter settings
function AlphaUI:GetFilteredCitizens()
    local filtered = {}

    for _, citizen in ipairs(self.world.citizens) do
        local passesClassFilter = self.citizensFilter == "all" or
            string.lower(citizen.class) == self.citizensFilter

        local passesStatusFilter = true
        if self.citizensStatusFilter ~= "all" then
            local sat = citizen:GetAverageSatisfaction()
            local _, status = self:GetSatisfactionColorAndStatus(sat)
            status = string.lower(status)

            if self.citizensStatusFilter == "protesting" then
                passesStatusFilter = citizen.isProtesting
            elseif self.citizensStatusFilter == "happy" then
                passesStatusFilter = status == "happy"
            elseif self.citizensStatusFilter == "neutral" then
                passesStatusFilter = status == "neutral"
            elseif self.citizensStatusFilter == "stressed" then
                passesStatusFilter = status == "stressed"
            elseif self.citizensStatusFilter == "critical" then
                passesStatusFilter = status == "critical"
            end
        end

        if passesClassFilter and passesStatusFilter then
            table.insert(filtered, citizen)
        end
    end

    return filtered
end

-- Sort citizens based on current sort settings
function AlphaUI:GetSortedCitizens(citizens)
    local sorted = {}
    for _, c in ipairs(citizens) do
        table.insert(sorted, c)
    end

    local sortField = self.citizensSort
    local ascending = self.citizensSortAsc

    table.sort(sorted, function(a, b)
        local valA, valB

        if sortField == "satisfaction" then
            valA = a:GetAverageSatisfaction()
            valB = b:GetAverageSatisfaction()
        elseif sortField == "name" then
            valA = a.name or ""
            valB = b.name or ""
        elseif sortField == "class" then
            -- Custom class order: Elite > Upper > Middle > Lower
            local classOrder = {elite = 4, upper = 3, middle = 2, lower = 1}
            valA = classOrder[string.lower(a.class or "middle")] or 0
            valB = classOrder[string.lower(b.class or "middle")] or 0
        elseif sortField == "age" then
            valA = a.age or 0
            valB = b.age or 0
        elseif sortField == "vocation" then
            valA = a.vocation or ""
            valB = b.vocation or ""
        else
            valA = 0
            valB = 0
        end

        if ascending then
            return valA < valB
        else
            return valA > valB
        end
    end)

    return sorted
end

-- =============================================================================
-- BUILDING MANAGEMENT MODAL
-- =============================================================================

function AlphaUI:RenderBuildingModal()
    local building = self.selectedBuildingForModal
    if not building then return end

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal dimensions
    local modalWidth = 700
    local modalHeight = 600
    local modalX = (screenW - modalWidth) / 2
    local modalY = (screenH - modalHeight) / 2

    -- Modal background
    love.graphics.setColor(0.25, 0.25, 0.28)
    love.graphics.rectangle("fill", modalX, modalY, modalWidth, modalHeight, 10, 10)

    -- Modal border
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", modalX, modalY, modalWidth, modalHeight, 10, 10)

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.title)
    love.graphics.print((building.name or "Building") .. " #" .. (building.id or "?"), modalX + 20, modalY + 15)

    -- Close button (X)
    local closeButtonSize = 30
    local closeButtonX = modalX + modalWidth - closeButtonSize - 10
    local closeButtonY = modalY + 10
    love.graphics.setColor(0.7, 0.3, 0.3)
    love.graphics.rectangle("fill", closeButtonX, closeButtonY, closeButtonSize, closeButtonSize, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.header)
    love.graphics.print("X", closeButtonX + 9, closeButtonY + 4)

    -- Store close button for click handling
    self.buildingModalCloseBtn = {x = closeButtonX, y = closeButtonY, w = closeButtonSize, h = closeButtonSize}

    -- Scrollable content area
    local contentY = modalY + 60
    local contentHeight = modalHeight - 70
    love.graphics.setScissor(modalX + 10, contentY, modalWidth - 20, contentHeight)

    local yOffset = contentY - self.buildingModalScrollOffset

    -- Section 1: Stations
    local stations = building.stations or {}
    local stationSectionHeight = 50 + (#stations * 100)
    love.graphics.setColor(0.35, 0.35, 0.38)
    love.graphics.rectangle("fill", modalX + 20, yOffset, modalWidth - 40, stationSectionHeight, 8, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.header)
    love.graphics.print("Stations (" .. #stations .. ")", modalX + 30, yOffset + 10)

    -- Store station button areas for click handling
    self.stationRecipeButtons = {}

    -- Render each station
    local stationY = yOffset + 45
    for i, station in ipairs(stations) do
        -- Station card
        local cardWidth = modalWidth - 80
        local cardHeight = 90
        local stateColor = {0.4, 0.4, 0.42}

        if station.state == "PRODUCING" then
            stateColor = {0.35, 0.5, 0.35}
        elseif station.state == "NO_WORKER" or station.state == "IDLE" then
            stateColor = {0.5, 0.45, 0.3}
        elseif station.state == "NO_MATERIALS" then
            stateColor = {0.5, 0.35, 0.35}
        end

        love.graphics.setColor(unpack(stateColor))
        love.graphics.rectangle("fill", modalX + 40, stationY, cardWidth, cardHeight, 6, 6)

        -- Station ID
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.fonts.normal)
        love.graphics.print("Station " .. i, modalX + 50, stationY + 8)

        -- Recipe info
        if station.recipe then
            love.graphics.setFont(self.fonts.small)
            love.graphics.setColor(0.8, 0.9, 0.8)
            local recipeName = station.recipe.recipeName or station.recipe.name or "Recipe"
            love.graphics.print(recipeName, modalX + 50, stationY + 28)

            -- Show inputs/outputs
            local inputsText = "In: "
            local inputCount = 0
            for inputId, qty in pairs(station.recipe.inputs or {}) do
                if inputCount > 0 then inputsText = inputsText .. ", " end
                local inputName = self:GetCommodityDisplayName(inputId)
                inputsText = inputsText .. inputName .. " x" .. qty
                inputCount = inputCount + 1
            end
            if inputCount == 0 then inputsText = inputsText .. "None" end
            love.graphics.setColor(0.8, 0.7, 0.6)
            love.graphics.print(inputsText, modalX + 50, stationY + 44)

            local outputsText = "Out: "
            local outputCount = 0
            for outputId, qty in pairs(station.recipe.outputs or {}) do
                if outputCount > 0 then outputsText = outputsText .. ", " end
                local outputName = self:GetCommodityDisplayName(outputId)
                outputsText = outputsText .. outputName .. " x" .. qty
                outputCount = outputCount + 1
            end
            if outputCount == 0 then outputsText = outputsText .. "None" end
            love.graphics.setColor(0.6, 0.9, 0.7)
            love.graphics.print(outputsText, modalX + 50, stationY + 60)
        else
            love.graphics.setFont(self.fonts.small)
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("No recipe assigned", modalX + 50, stationY + 28)
        end

        -- State and progress (right side)
        love.graphics.setFont(self.fonts.tiny)
        love.graphics.setColor(0.8, 0.8, 0.8)
        local stateText = station.state or "IDLE"
        if station.state == "PRODUCING" and station.progress then
            stateText = stateText .. " (" .. math.floor(station.progress * 100) .. "%)"
        end
        love.graphics.print("State: " .. stateText, modalX + 400, stationY + 8)

        -- Recipe button (per station)
        local buttonWidth = 120
        local buttonHeight = 25
        local buttonX = modalX + cardWidth - buttonWidth + 20
        local buttonY = stationY + cardHeight - buttonHeight - 8

        if station.recipe then
            -- Change Recipe button
            love.graphics.setColor(0.4, 0.5, 0.7)
            love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight, 4, 4)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(self.fonts.small)
            local text = "Change Recipe"
            local textWidth = self.fonts.small:getWidth(text)
            love.graphics.print(text, buttonX + (buttonWidth - textWidth) / 2, buttonY + 5)
        else
            -- Add Recipe button
            love.graphics.setColor(0.5, 0.7, 0.4)
            love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight, 4, 4)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(self.fonts.small)
            local text = "Add Recipe"
            local textWidth = self.fonts.small:getWidth(text)
            love.graphics.print(text, buttonX + (buttonWidth - textWidth) / 2, buttonY + 5)
        end

        -- Store button position for click handling
        table.insert(self.stationRecipeButtons, {
            x = buttonX, y = buttonY, w = buttonWidth, h = buttonHeight,
            stationIndex = i, station = station
        })

        stationY = stationY + cardHeight + 10
    end

    yOffset = yOffset + stationSectionHeight + 15

    -- Section 2: Workers
    local workers = building.workers or {}
    local workerSectionHeight = 50 + (#workers * 120)
    if #workers == 0 then workerSectionHeight = 100 end

    love.graphics.setColor(0.35, 0.35, 0.38)
    love.graphics.rectangle("fill", modalX + 20, yOffset, modalWidth - 40, workerSectionHeight, 8, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.header)
    local maxWorkers = building.maxWorkers or #stations
    love.graphics.print("Workers (" .. #workers .. "/" .. maxWorkers .. ")", modalX + 30, yOffset + 10)

    if #workers == 0 then
        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("No workers assigned yet", modalX + 30, yOffset + 45)
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("Citizens will seek jobs here based on their preferences", modalX + 30, yOffset + 65)
    else
        local workerY = yOffset + 45
        for _, worker in ipairs(workers) do
            -- Worker card
            local cardWidth = modalWidth - 80
            local cardHeight = 110
            love.graphics.setColor(0.4, 0.45, 0.38)
            love.graphics.rectangle("fill", modalX + 40, workerY, cardWidth, cardHeight, 6, 6)

            -- Worker info
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(self.fonts.normal)
            love.graphics.print(worker.name or "Unknown", modalX + 50, workerY + 10)

            love.graphics.setFont(self.fonts.small)
            love.graphics.setColor(0.8, 0.8, 0.9)
            love.graphics.print(worker.vocation or "Worker", modalX + 50, workerY + 32)

            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("Class: " .. (worker.class or "?"), modalX + 50, workerY + 50)
            love.graphics.print("Age: " .. (worker.age or "?"), modalX + 50, workerY + 66)

            -- Satisfaction
            local sat = 50
            if worker.GetAverageSatisfaction then
                sat = worker:GetAverageSatisfaction() or 50
            end
            local satColor = sat > 70 and self.colors.success or (sat > 40 and self.colors.warning or self.colors.danger)
            love.graphics.setColor(satColor)
            love.graphics.print(string.format("Satisfaction: %.0f%%", sat), modalX + 200, workerY + 50)

            -- Status indicator
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.print("Status: " .. (worker.status or "idle"), modalX + 200, workerY + 66)

            workerY = workerY + cardHeight + 10
        end
    end

    yOffset = yOffset + workerSectionHeight + 15

    -- Section 3: Storage (inputs/outputs)
    local storageSectionHeight = 120
    love.graphics.setColor(0.35, 0.35, 0.38)
    love.graphics.rectangle("fill", modalX + 20, yOffset, modalWidth - 40, storageSectionHeight, 8, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.header)
    love.graphics.print("Storage", modalX + 30, yOffset + 10)

    local storageY = yOffset + 40
    love.graphics.setFont(self.fonts.small)

    -- Input storage
    love.graphics.setColor(0.9, 0.8, 0.6)
    love.graphics.print("Input Storage:", modalX + 30, storageY)
    local inputUsed = building.inputStorageUsed or 0
    local inputCap = building.inputStorageCapacity or 100
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(inputUsed .. " / " .. inputCap .. " units", modalX + 160, storageY)
    storageY = storageY + 25

    -- Output storage
    love.graphics.setColor(0.6, 0.9, 0.7)
    love.graphics.print("Output Storage:", modalX + 30, storageY)
    local outputUsed = building.outputStorageUsed or 0
    local outputCap = building.outputStorageCapacity or 100
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(outputUsed .. " / " .. outputCap .. " units", modalX + 160, storageY)

    yOffset = yOffset + storageSectionHeight + 15

    -- Section 4: Building Management (Upgrade, Priority, Pause, Demolish)
    local managementSectionHeight = 200
    love.graphics.setColor(0.35, 0.35, 0.38)
    love.graphics.rectangle("fill", modalX + 20, yOffset, modalWidth - 40, managementSectionHeight, 8, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.header)
    love.graphics.print("Building Management", modalX + 30, yOffset + 10)

    local mgmtY = yOffset + 45
    local btnWidth = 150
    local btnHeight = 35
    local btnSpacing = 15

    -- Store management buttons for click handling
    self.buildingMgmtButtons = {}

    -- Row 1: Upgrade and Priority
    -- Upgrade Button
    local currentLevel = building.level or building.mCurrentLevel or 0
    local maxLevel = 2  -- Max upgrade level
    local canUpgrade = currentLevel < maxLevel
    local upgradeCost = self:GetUpgradeCost(building, currentLevel + 1)

    if canUpgrade then
        love.graphics.setColor(0.3, 0.6, 0.4)
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
    end
    love.graphics.rectangle("fill", modalX + 30, mgmtY, btnWidth, btnHeight, 6, 6)

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(canUpgrade and {1, 1, 1} or {0.5, 0.5, 0.5})
    local upgradeText = canUpgrade and ("Upgrade (Lvl " .. (currentLevel + 2) .. ")") or "Max Level"
    local upgradeTextW = self.fonts.small:getWidth(upgradeText)
    love.graphics.print(upgradeText, modalX + 30 + (btnWidth - upgradeTextW) / 2, mgmtY + 5)

    if canUpgrade then
        love.graphics.setColor(0.9, 0.8, 0.4)
        local costText = upgradeCost .. " gold"
        local costTextW = self.fonts.small:getWidth(costText)
        love.graphics.print(costText, modalX + 30 + (btnWidth - costTextW) / 2, mgmtY + 20)
    end

    table.insert(self.buildingMgmtButtons, {
        x = modalX + 30, y = mgmtY, w = btnWidth, h = btnHeight,
        action = "upgrade", enabled = canUpgrade
    })

    -- Current Level indicator
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Current: Level " .. (currentLevel + 1), modalX + 30, mgmtY + btnHeight + 4)

    -- Priority Button
    local priorityX = modalX + 30 + btnWidth + btnSpacing
    local priority = building.priority or "normal"
    local priorityColors = {
        high = {0.7, 0.5, 0.3},
        normal = {0.4, 0.5, 0.6},
        low = {0.4, 0.4, 0.4}
    }
    love.graphics.setColor(priorityColors[priority] or priorityColors.normal)
    love.graphics.rectangle("fill", priorityX, mgmtY, btnWidth, btnHeight, 6, 6)

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(1, 1, 1)
    local priorityText = "Priority: " .. (priority:sub(1,1):upper() .. priority:sub(2))
    local priorityTextW = self.fonts.small:getWidth(priorityText)
    love.graphics.print(priorityText, priorityX + (btnWidth - priorityTextW) / 2, mgmtY + 10)

    table.insert(self.buildingMgmtButtons, {
        x = priorityX, y = mgmtY, w = btnWidth, h = btnHeight,
        action = "priority", enabled = true
    })

    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("Click to cycle", priorityX, mgmtY + btnHeight + 4)

    mgmtY = mgmtY + btnHeight + 25

    -- Row 2: Pause and Demolish
    -- Pause Production Button
    local isPaused = building.isPaused or building.mIsPaused or false

    if isPaused then
        love.graphics.setColor(0.6, 0.5, 0.3)
    else
        love.graphics.setColor(0.4, 0.5, 0.6)
    end
    love.graphics.rectangle("fill", modalX + 30, mgmtY, btnWidth, btnHeight, 6, 6)

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(1, 1, 1)
    local pauseText = isPaused and "Resume Production" or "Pause Production"
    local pauseTextW = self.fonts.small:getWidth(pauseText)
    love.graphics.print(pauseText, modalX + 30 + (btnWidth - pauseTextW) / 2, mgmtY + 10)

    table.insert(self.buildingMgmtButtons, {
        x = modalX + 30, y = mgmtY, w = btnWidth, h = btnHeight,
        action = "pause", enabled = true
    })

    -- Demolish Button
    local demolishX = modalX + 30 + btnWidth + btnSpacing
    local salvageValue = self:GetDemolishSalvage(building)

    love.graphics.setColor(0.6, 0.3, 0.3)
    love.graphics.rectangle("fill", demolishX, mgmtY, btnWidth, btnHeight, 6, 6)

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Demolish", demolishX + (btnWidth - self.fonts.small:getWidth("Demolish")) / 2, mgmtY + 5)

    love.graphics.setColor(0.9, 0.8, 0.4)
    local salvageText = "Salvage: " .. salvageValue .. "g"
    local salvageTextW = self.fonts.small:getWidth(salvageText)
    love.graphics.print(salvageText, demolishX + (btnWidth - salvageTextW) / 2, mgmtY + 20)

    table.insert(self.buildingMgmtButtons, {
        x = demolishX, y = mgmtY, w = btnWidth, h = btnHeight,
        action = "demolish", enabled = true
    })

    -- Calculate total content height for scrolling
    local totalContentHeight = stationSectionHeight + 15 + workerSectionHeight + 15 + storageSectionHeight + 15 + managementSectionHeight + 20
    self.buildingModalScrollMax = math.max(0, totalContentHeight - contentHeight)

    love.graphics.setScissor()

    -- Draw scrollbar if needed
    if self.buildingModalScrollMax > 0 then
        local scrollbarX = modalX + modalWidth - 18
        local scrollbarWidth = 6
        local scrollbarHeight = contentHeight * (contentHeight / totalContentHeight)
        local scrollbarY = contentY + (self.buildingModalScrollOffset / self.buildingModalScrollMax) * (contentHeight - scrollbarHeight)

        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 3, 3)
    end

    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1)
end

-- =============================================================================
-- RECIPE PICKER MODAL
-- =============================================================================

function AlphaUI:RenderRecipeModal()
    local building = self.selectedBuildingForModal
    if not building then return end

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal dimensions
    local modalWidth = 600
    local modalHeight = 500
    local modalX = (screenW - modalWidth) / 2
    local modalY = (screenH - modalHeight) / 2

    -- Modal background
    love.graphics.setColor(0.25, 0.25, 0.28)
    love.graphics.rectangle("fill", modalX, modalY, modalWidth, modalHeight, 10, 10)

    -- Modal border
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", modalX, modalY, modalWidth, modalHeight, 10, 10)

    -- Modal title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.header)
    love.graphics.print("Select Recipe", modalX + 20, modalY + 15)

    -- Building name
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("for " .. (building.name or "Building") .. " (#" .. (building.id or "?") .. ")", modalX + 20, modalY + 40)

    -- Close button (X)
    local closeButtonX = modalX + modalWidth - 35
    local closeButtonY = modalY + 10
    local closeButtonSize = 25
    love.graphics.setColor(0.7, 0.3, 0.3)
    love.graphics.rectangle("fill", closeButtonX, closeButtonY, closeButtonSize, closeButtonSize, 3, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.normal)
    love.graphics.print("X", closeButtonX + 7, closeButtonY + 2)

    -- Store close button
    self.recipeModalCloseBtn = {x = closeButtonX, y = closeButtonY, w = closeButtonSize, h = closeButtonSize}

    -- Filter recipes for this building type
    local buildingTypeId = building.typeId
    local allRecipes = self.world.buildingRecipes or {}

    local availableRecipes = {}
    for _, recipe in ipairs(allRecipes) do
        if recipe.buildingType == buildingTypeId then
            table.insert(availableRecipes, recipe)
        end
    end

    -- Recipe list area
    local listY = modalY + 70
    local listHeight = modalHeight - 90
    local recipeHeight = 85
    local recipeSpacing = 10

    -- Enable scissor for scrolling
    love.graphics.setScissor(modalX + 20, listY, modalWidth - 40, listHeight)

    -- Store recipe buttons for click handling
    self.recipeButtons = {}

    if #availableRecipes == 0 then
        -- No recipes available
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.setFont(self.fonts.normal)
        love.graphics.print("No recipes available for this building type", modalX + 40, listY + 50)
    else
        -- Render recipes
        local yOffset = listY - self.recipeModalScrollOffset

        for _, recipe in ipairs(availableRecipes) do
            -- Only render if visible
            if yOffset + recipeHeight > listY and yOffset < listY + listHeight then
                -- Recipe card
                love.graphics.setColor(0.3, 0.3, 0.33)
                love.graphics.rectangle("fill", modalX + 20, yOffset, modalWidth - 40, recipeHeight, 5, 5)

                -- Recipe card border (hover effect would go here)
                love.graphics.setColor(0.5, 0.5, 0.5)
                love.graphics.setLineWidth(1)
                love.graphics.rectangle("line", modalX + 20, yOffset, modalWidth - 40, recipeHeight, 5, 5)

                -- Recipe name
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(self.fonts.normal)
                love.graphics.print(recipe.recipeName or recipe.id or "Recipe", modalX + 30, yOffset + 10)

                -- Production time
                love.graphics.setFont(self.fonts.small)
                love.graphics.setColor(0.7, 0.7, 0.7)
                love.graphics.print("Time: " .. (recipe.productionTime or "?") .. "s", modalX + 30, yOffset + 32)

                -- Inputs
                local inputsText = "In: "
                local inputCount = 0
                for inputId, qty in pairs(recipe.inputs or {}) do
                    if inputCount > 0 then inputsText = inputsText .. ", " end
                    local inputName = self:GetCommodityDisplayName(inputId)
                    inputsText = inputsText .. inputName .. " x" .. qty
                    inputCount = inputCount + 1
                end
                if inputCount == 0 then inputsText = inputsText .. "None" end
                love.graphics.setColor(0.8, 0.7, 0.6)
                love.graphics.print(inputsText, modalX + 30, yOffset + 50)

                -- Outputs
                local outputsText = "Out: "
                local outputCount = 0
                for outputId, qty in pairs(recipe.outputs or {}) do
                    if outputCount > 0 then outputsText = outputsText .. ", " end
                    local outputName = self:GetCommodityDisplayName(outputId)
                    outputsText = outputsText .. outputName .. " x" .. qty
                    outputCount = outputCount + 1
                end
                if outputCount == 0 then outputsText = outputsText .. "None" end
                love.graphics.setColor(0.6, 0.9, 0.7)
                love.graphics.print(outputsText, modalX + 30, yOffset + 68)

                -- Store button position for click handling
                table.insert(self.recipeButtons, {
                    x = modalX + 20, y = yOffset, w = modalWidth - 40, h = recipeHeight,
                    recipe = recipe
                })
            end

            yOffset = yOffset + recipeHeight + recipeSpacing
        end

        -- Calculate scroll max
        local totalContentHeight = #availableRecipes * (recipeHeight + recipeSpacing)
        self.recipeModalScrollMax = math.max(0, totalContentHeight - listHeight)
    end

    -- Disable scissor
    love.graphics.setScissor()

    -- Draw scrollbar if needed
    if self.recipeModalScrollMax > 0 then
        local totalContentHeight = #availableRecipes * (recipeHeight + recipeSpacing)
        local scrollbarX = modalX + modalWidth - 25
        local scrollbarWidth = 6
        local scrollbarHeight = listHeight * (listHeight / totalContentHeight)
        local scrollbarY = listY + (self.recipeModalScrollOffset / self.recipeModalScrollMax) * (listHeight - scrollbarHeight)

        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 3, 3)
    end

    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1)
end

-- Helper to get commodity display name from ID
function AlphaUI:GetCommodityDisplayName(commodityId)
    local commoditiesById = self.world.commoditiesById or {}
    local commodity = commoditiesById[commodityId]
    if commodity then
        return commodity.name or commodityId
    end
    return commodityId
end

-- Helper function to get upgrade cost for a building
function AlphaUI:GetUpgradeCost(building, targetLevel)
    -- Base cost increases with level
    local baseCost = 100
    local buildingType = building.mBuildingType or building.type

    -- Get base cost from building type if available
    if buildingType and buildingType.cost then
        baseCost = buildingType.cost
    end

    -- Upgrade cost is roughly 50% of base cost per level
    return math.floor(baseCost * 0.5 * targetLevel)
end

-- Helper function to get demolish salvage value
function AlphaUI:GetDemolishSalvage(building)
    local baseCost = 100
    local buildingType = building.mBuildingType or building.type

    -- Get base cost from building type if available
    if buildingType and buildingType.cost then
        baseCost = buildingType.cost
    end

    -- Salvage is 30% of original cost
    local currentLevel = building.level or building.mCurrentLevel or 0
    local totalInvested = baseCost + (baseCost * 0.5 * currentLevel)

    return math.floor(totalInvested * 0.3)
end

-- Helper function to get filtered commodities based on current filter
function AlphaUI:GetFilteredCommodities()
    local filtered = {}
    local commodities = self.world.commodities or {}

    for _, commodity in ipairs(commodities) do
        local quantity = self.world:GetInventoryCount(commodity.id)
        local include = false

        if self.inventoryFilter == "all" then
            include = true
        elseif self.inventoryFilter == "nonzero" then
            include = quantity > 0
        else
            include = commodity.category == self.inventoryFilter
        end

        if include then
            table.insert(filtered, {
                commodity = commodity,
                quantity = quantity
            })
        end
    end

    -- Sort by category then name
    table.sort(filtered, function(a, b)
        if a.commodity.category ~= b.commodity.category then
            return (a.commodity.category or "") < (b.commodity.category or "")
        end
        return (a.commodity.name or a.commodity.id) < (b.commodity.name or b.commodity.id)
    end)

    return filtered
end

-- Helper to format numbers nicely
function AlphaUI:FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    else
        return string.format("%.0f", num)
    end
end

function AlphaUI:GetFilteredBuildingTypes()
    local result = {}
    local allTypes = self.world.buildingTypes or {}
    local searchQuery = (self.buildMenuSearchQuery or ""):lower()

    for _, bType in ipairs(allTypes) do
        local category = bType.category or "other"
        local name = (bType.name or bType.id or ""):lower()
        local description = (bType.description or ""):lower()

        -- Check search filter first
        local matchesSearch = true
        if searchQuery ~= "" then
            matchesSearch = name:find(searchQuery, 1, true) or
                           description:find(searchQuery, 1, true) or
                           category:find(searchQuery, 1, true)
        end

        if not matchesSearch then
            goto continue
        end

        -- Check category filter
        local matchesCategory = false
        if self.buildMenuCategory == "all" then
            matchesCategory = true
        elseif self.buildMenuCategory == "housing" and category == "housing" then
            matchesCategory = true
        elseif self.buildMenuCategory == "production" and category == "production" then
            matchesCategory = true
        elseif self.buildMenuCategory == "agriculture" and category == "agriculture" then
            matchesCategory = true
        elseif self.buildMenuCategory == "extraction" and category == "extraction" then
            matchesCategory = true
        elseif self.buildMenuCategory == "services" and (category == "services" or category == "service") then
            matchesCategory = true
        end

        if matchesCategory then
            table.insert(result, bType)
        end

        ::continue::
    end

    return result
end

-- =============================================================================
-- HELPERS
-- =============================================================================

-- Get inventory categories from world data (cached for performance)
function AlphaUI:GetInventoryCategories()
    -- Return cached categories if available
    if self.inventoryCategories then
        return self.inventoryCategories
    end

    -- Build categories from world data
    local categories = {
        {id = "all", name = "All Items"},
        {id = "nonzero", name = "In Stock"}
    }

    -- Add categories from world's commodity categories data
    if self.world and self.world.commodityCategories then
        for _, cat in ipairs(self.world.commodityCategories) do
            table.insert(categories, {
                id = cat.id,
                name = cat.name,
                color = cat.color
            })
        end
    end

    -- Cache for future use
    self.inventoryCategories = categories
    return categories
end

function AlphaUI:RenderProgressBar(x, y, w, h, value, color)
    value = math.max(0, math.min(1, value or 0))

    -- Background
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y, w, h, 2, 2)

    -- Fill
    if value > 0 then
        love.graphics.setColor(color or self.colors.accent)
        love.graphics.rectangle("fill", x, y, w * value, h, 2, 2)
    end

    -- Border
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", x, y, w, h, 2, 2)
end

-- =============================================================================
-- INPUT HANDLING
-- =============================================================================

function AlphaUI:HandleClick(x, y, button)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Handle day end summary modal clicks (has priority)
    if self.showDayEndSummaryModal and self.dayEndSummaryModal then
        if self.dayEndSummaryModal.HandleClick then
            return self.dayEndSummaryModal:HandleClick(x, y, button)
        end
    end

    -- Handle save/load modal clicks first (has priority)
    if self.showSaveLoadModal and self.saveLoadModal then
        return self.saveLoadModal:HandleClick(x, y, button)
    end

    -- Handle supply chain viewer clicks (high priority when visible)
    if self.supplyChainViewer and self.supplyChainViewer.isVisible then
        return self.supplyChainViewer:HandleClick(x, y)
    end

    -- Handle recipe modal clicks (on top of building modal)
    if self.showRecipeModal then
        if not self.modalJustOpened then
            return self:HandleRecipeModalClick(x, y)
        else
            self.modalJustOpened = false
            return true
        end
    end

    -- Handle building modal clicks
    if self.showBuildingModal then
        return self:HandleBuildingModalClick(x, y)
    end

    -- Handle character detail panel clicks FIRST (appears on top of citizens panel)
    if self.characterDetailPanel and self.characterDetailPanel:IsVisible() then
        if self.characterDetailPanel:HandleClick(x, y) then
            return true
        end
    end

    -- Handle inventory panel clicks
    if self.showInventoryPanel then
        return self:HandleInventoryPanelClick(x, y)
    end

    -- Handle citizens panel clicks
    if self.showCitizensPanel then
        return self:HandleCitizensPanelClick(x, y)
    end

    -- Handle production analytics panel clicks
    if self.showProductionAnalyticsPanel then
        return self:HandleProductionAnalyticsPanelClick(x, y)
    end

    -- Handle settings panel clicks
    if self.showSettingsPanel then
        return self:HandleSettingsPanelClick(x, y)
    end

    -- Handle emigration panel clicks
    if self.showEmigrationPanel then
        return self:HandleEmigrationPanelClick(x, y)
    end

    -- Handle right-click to cancel placement
    if button == 2 then
        if self.placementMode then
            self:ExitPlacementMode()
            return true
        end
        return false
    end

    if button ~= 1 then return false end

    -- Handle resource overlay panel clicks first (if visible)
    if self.showResourceOverlay and self.resourceOverlay then
        if self.resourceOverlay:handlePanelClick(x, y) then
            return true
        end
    end

    -- Handle debug panel clicks (CRAVE-6) - high priority
    -- Always check debug panel (toggle button always visible)
    if self.debugPanel then
        if self.debugPanel:HandleMousePress(x, y, button) then
            return true
        end
    end

    -- Handle housing assignment modal clicks
    if self.showHousingAssignmentModal and self.housingAssignmentModal then
        if self.housingAssignmentModal:HandleClick(x, y) then
            return true
        end
    end

    -- Handle housing overview panel clicks
    if self.showHousingOverviewPanel and self.housingOverviewPanel then
        if self.housingOverviewPanel:HandleClick(x, y) then
            return true
        end
    end

    -- Handle land registry panel clicks
    if self.showLandRegistryPanel and self.landRegistryPanel then
        if self.landRegistryPanel:HandleClick(x, y) then
            return true
        end
    end

    -- Handle plot selection modal clicks (highest priority - on top of immigration)
    if self.showPlotSelectionModal and self.plotSelectionModal then
        return self.plotSelectionModal:HandleClick(x, y, button)
    end

    -- Handle suggested buildings modal clicks
    if self.showSuggestedBuildingsModal and self.suggestedBuildingsModal then
        return self.suggestedBuildingsModal:HandleClick(x, y, button)
    end

    -- Handle build menu modal clicks
    if self.showBuildMenuModal then
        return self:HandleBuildMenuClick(x, y)
    end

    -- Handle immigration modal clicks
    if self.showImmigrationModal then
        return self:HandleImmigrationClick(x, y)
    end

    -- Handle placement mode clicks
    if self.placementMode then
        return self:HandlePlacementClick(x, y)
    end

    -- Check top bar speed controls FIRST (before action buttons)
    if y < self.topBarHeight then
        local speedX = screenW - 200
        -- Pause/Play toggle
        if x >= speedX and x < speedX + 80 and y >= 10 and y < 30 then
            self.world:TogglePause()
            return true
        end
        -- Speed buttons (use same spacing as rendering)
        local speeds = {"normal", "fast", "faster", "fastest", "turbo"}
        local speedBtnSpacing = 30  -- Must match rendering spacing
        for i, speed in ipairs(speeds) do
            local bx = speedX + (i - 1) * speedBtnSpacing
            if x >= bx and x < bx + speedBtnSpacing and y >= 32 and y < 50 then
                self.world:SetTimeScale(speed)
                return true
            end
        end
    end

    -- Check top bar action buttons
    for btnId, btn in pairs(self.topBarButtons) do
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            -- Close other panels first
            local closeOthers = function()
                self.showBuildMenuModal = false
                self.showImmigrationModal = false
                self.showCitizensPanel = false
                self.showAnalyticsPanel = false
                self.showInventoryPanel = false
                self.showHelpOverlay = false
                self.showProductionAnalyticsPanel = false
                self.showSettingsPanel = false
                self.showEmigrationPanel = false
            end

            if btnId == "production" then
                closeOthers()
                self.showProductionAnalyticsPanel = true
            elseif btnId == "build" then
                closeOthers()
                self.showBuildMenuModal = true
                self.buildMenuScrollOffset = 0
                self.buildMenuSearchQuery = ""
                self.buildMenuSearchActive = false
            elseif btnId == "citizens" then
                closeOthers()
                self.showCitizensPanel = true
            elseif btnId == "inventory" then
                closeOthers()
                self.showInventoryPanel = true
                self.inventoryScrollOffset = 0
            elseif btnId == "settings" then
                closeOthers()
                self.showSettingsPanel = true
                self.settingsScrollOffset = 0
            elseif btnId == "help" then
                closeOthers()
                self.showHelpOverlay = true
            end
            return true
        end
    end

    -- Check event log filter buttons (bottom bar)
    local bottomY = screenH - self.bottomBarHeight
    if y >= bottomY and y < screenH then
        local filters = {"all", "production", "consumption", "immigration", "time"}
        for _, filterId in ipairs(filters) do
            local btn = self["filterButton_" .. filterId]
            if btn and x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
                self.eventLogFilter = filterId
                return true
            end
        end
    end

    -- Handle minimap click (navigation)
    if self:HandleMinimapClick(x, y) then
        return true
    end

    -- Handle notification system clicks
    if self.notificationSystem and self.notificationSystem:HandleClick(x, y) then
        return true
    end

    -- Handle tutorial system clicks
    if self.tutorialSystem and self.tutorialSystem:IsActive() then
        if self.tutorialSystem:HandleClick(x, y) then
            return true
        end
    end

    -- Check quick build buttons (left panel)
    for btnId, btn in pairs(self.quickBuildButtons) do
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            -- Enter placement mode for this building type
            local buildingTypeId = self:GetBuildingTypeForQuickBuild(btnId)
            local buildingType = self:GetBuildingTypeById(buildingTypeId)
            if buildingType then
                self:EnterPlacementMode(buildingType)
            end
            return true
        end
    end

    -- Check "More Buildings" button
    if self.moreBuildingsBtn then
        local btn = self.moreBuildingsBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.showBuildMenuModal = true
            self.buildMenuScrollOffset = 0
            self.buildMenuSearchQuery = ""
            self.buildMenuSearchActive = false
            return true
        end
    end

    -- Check "Immigration" button
    if self.immigrationBtn and self.immigrationBtn.enabled then
        local btn = self.immigrationBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.showImmigrationModal = true
            self.selectedApplicant = nil
            self.immigrationScrollOffset = 0
            return true
        end
    end

    -- Check "Manage Building" button in right panel
    if self.manageBuildingBtn and self.world.selectedEntity and self.world.selectedEntityType == "building" then
        local btn = self.manageBuildingBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.selectedBuildingForModal = self.world.selectedEntity
            self.showBuildingModal = true
            self.buildingModalScrollOffset = 0
            return true
        end
    end

    -- Check if click is in world view area
    local worldX = self.leftPanelWidth
    local worldY = self.topBarHeight
    local worldW = screenW - self.leftPanelWidth - self.rightPanelWidth
    local worldH = screenH - self.topBarHeight - self.bottomBarHeight

    if x >= worldX and x < worldX + worldW and
       y >= worldY and y < worldY + worldH then
        -- Convert to world coordinates
        local wx = (x - worldX) + self.cameraX
        local wy = (y - worldY) + self.cameraY

        -- Handle spawn citizen mode (debug feature)
        if self.spawnCitizenMode then
            -- Spawn a citizen at the clicked world position
            -- AddCitizen signature: (class, name, traits, options)
            local citizen = self.world:AddCitizen(nil, nil, nil, {})
            if citizen then
                -- Override position to clicked location
                citizen.x = wx
                citizen.y = wy
                citizen.targetX = wx
                citizen.targetY = wy

                -- Set them to walking state so they pathfind back to town center
                local CharacterMovement = require("code.CharacterMovement")
                local townCenterX = self.world.worldWidth / 2
                local townCenterY = self.world.worldHeight / 2
                CharacterMovement.SetDestination(citizen, townCenterX, townCenterY)

                print(string.format("[Debug] Spawned citizen '%s' at (%.0f, %.0f) - walking to town center (%.0f, %.0f)",
                    citizen.name, wx, wy, townCenterX, townCenterY))
                -- Select the newly spawned citizen
                self.world:SelectEntity(citizen, "citizen")
            end
            return true
        end

        -- Check for citizen click
        local citizen = self.world:GetCitizenAt(wx, wy, 15)
        if citizen then
            self.world:SelectEntity(citizen, "citizen")
            return true
        end

        -- Check for building click
        local building = self.world:GetBuildingAt(wx, wy)
        if building then
            self.world:SelectEntity(building, "building")
            return true
        end

        -- Clear selection
        self.world:ClearSelection()
        return true
    end

    return false
end

function AlphaUI:HandlePlacementClick(x, y)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local worldX = self.leftPanelWidth
    local worldY = self.topBarHeight
    local worldW = screenW - self.leftPanelWidth - self.rightPanelWidth
    local worldH = screenH - self.topBarHeight - self.bottomBarHeight

    -- Check if click is in world view area
    if x >= worldX and x < worldX + worldW and
       y >= worldY and y < worldY + worldH then

        if self.placementValid then
            -- Check if this is an immigrant placement (has owner citizen and restricted plots)
            local isImmigrantPlacement = self.placementOwnerCitizen ~= nil and self.placementRestrictedPlots ~= nil

            local building, errors

            if isImmigrantPlacement then
                -- Immigrant pays for the building from their wealth
                building, errors = self:PlaceBuildingForImmigrant(
                    self.placementBuildingType,
                    self.placementX,
                    self.placementY,
                    self.placementOwnerCitizen
                )
            else
                -- Normal town placement
                building, errors = self.world:PlaceBuilding(self.placementBuildingType, self.placementX, self.placementY)
            end

            if building then
                local builderName = isImmigrantPlacement and self.placementOwnerCitizen.name or "Town"
                self.world:LogEvent("construction", builderName .. " built " .. (building.name or building.typeId), {})

                -- For immigrant placement, check if there are remaining plots and reopen modal
                if isImmigrantPlacement then
                    -- Remove the plot that was used from restricted plots
                    local usedPlotId = self:GetPlotIdAtPosition(self.placementX, self.placementY)
                    local remainingPlots = self:RemovePlotFromList(self.placementRestrictedPlots, usedPlotId)
                    local ownerCitizen = self.placementOwnerCitizen

                    self:ExitPlacementMode()

                    -- If there are remaining plots, reopen the suggested buildings modal
                    if remainingPlots and #remainingPlots > 0 then
                        self:OpenSuggestedBuildingsModal(ownerCitizen, remainingPlots)
                    else
                        -- Select the new building
                        self.world:SelectEntity(building, "building")
                    end
                else
                    self:ExitPlacementMode()
                    -- Select the new building
                    self.world:SelectEntity(building, "building")
                end
            else
                -- Show error (placement failed)
                print("Placement failed: " .. table.concat(errors or {}, ", "))
            end
        end
        return true
    end

    return false
end

-- Place a building paid for by an immigrant citizen
function AlphaUI:PlaceBuildingForImmigrant(buildingType, x, y, citizen)
    -- Validate placement
    local isValid, errors, efficiency, breakdown = self.world:ValidateBuildingPlacement(buildingType, x, y)
    if not isValid then
        return nil, errors
    end

    -- Check if citizen can afford the building
    local cost = buildingType.constructionCost or {}
    local goldCost = cost.gold or 0

    -- Get citizen's gold from economics system
    local citizenGold = 0
    if self.world.economicsSystem then
        citizenGold = self.world.economicsSystem:GetGold(citizen.id) or 0
    end

    if goldCost > citizenGold then
        return nil, {"Insufficient funds (need " .. goldCost .. " gold, have " .. math.floor(citizenGold) .. ")"}
    end

    -- Deduct cost from citizen's gold (not town gold)
    if self.world.economicsSystem and goldCost > 0 then
        self.world.economicsSystem:SpendGold(citizen.id, goldCost, "building_construction")
        print(string.format("[AlphaUI] Deducted %d gold from %s's gold for building", goldCost, citizen.name))
    end

    -- For material costs, still check town inventory (immigrants use town materials for now)
    for materialId, required in pairs(cost.materials or {}) do
        local available = self.world.inventory[materialId] or 0
        if available < required then
            return nil, {"Missing material: " .. materialId}
        end
    end

    -- Deduct materials from town inventory
    for materialId, required in pairs(cost.materials or {}) do
        self.world:RemoveFromInventory(materialId, required)
    end

    -- Create the building
    local building = self.world:AddBuilding(buildingType.id, x, y)
    if building then
        building.resourceEfficiency = efficiency
        building.efficiencyBreakdown = breakdown
        building.ownerId = citizen.id  -- Set the citizen as owner
        print(string.format("[AlphaUI] Building %s placed for %s (owner: %s)", buildingType.id, citizen.name, citizen.id))
    end

    return building, nil
end

-- Get plot ID at a world position
function AlphaUI:GetPlotIdAtPosition(worldX, worldY)
    local landSystem = self.world.landSystem
    if not landSystem then return nil end

    local plot = landSystem:GetPlotAtWorld(worldX, worldY)
    return plot and plot.id or nil
end

-- Remove a plot from the list and return the remaining plots
function AlphaUI:RemovePlotFromList(plots, plotIdToRemove)
    if not plots or not plotIdToRemove then return plots end

    local remaining = {}
    for _, plotIdOrObj in ipairs(plots) do
        local plotId = type(plotIdOrObj) == "string" and plotIdOrObj or (plotIdOrObj.id or nil)
        if plotId ~= plotIdToRemove then
            table.insert(remaining, plotIdOrObj)
        end
    end
    return remaining
end

function AlphaUI:HandleInventoryPanelClick(x, y)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local panelW = 500
    local panelX = screenW - panelW
    local panelY = self.topBarHeight
    local panelH = screenH - self.topBarHeight - self.bottomBarHeight

    -- Check close button
    if self.inventoryCloseBtn then
        local btn = self.inventoryCloseBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.showInventoryPanel = false
            return true
        end
    end

    -- Check category filter buttons
    for i, btn in ipairs(self.inventoryCategoryBtns or {}) do
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.inventoryFilter = btn.categoryId
            self.inventoryScrollOffset = 0
            return true
        end
    end

    -- Check "?" info buttons for supply chain viewer
    for i, btn in ipairs(self.inventoryItemBtns or {}) do
        if btn.infoBtn then
            local info = btn.infoBtn
            if x >= info.x and x < info.x + info.w and y >= info.y and y < info.y + info.h then
                -- Open supply chain viewer for this commodity
                if self.supplyChainViewer and btn.commodity then
                    self.supplyChainViewer:Open(btn.commodity.id)
                    return true
                end
            end
        end
    end

    -- Click outside panel = close
    if x < panelX then
        self.showInventoryPanel = false
        return true
    end

    return true  -- Consume click inside panel
end

function AlphaUI:HandleCitizensPanelClick(x, y)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local panelW = math.min(1000, screenW - 100)
    local panelH = screenH - self.topBarHeight - self.bottomBarHeight - 40
    local panelX = (screenW - panelW) / 2
    local panelY = self.topBarHeight + 20

    -- Check close button
    if self.citizensCloseBtn then
        local btn = self.citizensCloseBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.showCitizensPanel = false
            return true
        end
    end

    -- Check class filter buttons
    for _, btn in ipairs(self.citizensFilterBtns or {}) do
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.citizensFilter = btn.filterId
            self.citizensPage = 1  -- Reset to first page when filter changes
            return true
        end
    end

    -- Check status filter buttons
    for _, btn in ipairs(self.citizensStatusFilterBtns or {}) do
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.citizensStatusFilter = btn.statusId
            self.citizensPage = 1  -- Reset to first page when filter changes
            return true
        end
    end

    -- Check sort buttons
    for _, btn in ipairs(self.citizensSortBtns or {}) do
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            if self.citizensSort == btn.sortId then
                -- Toggle ascending/descending if same sort field clicked
                self.citizensSortAsc = not self.citizensSortAsc
            else
                self.citizensSort = btn.sortId
                self.citizensSortAsc = false  -- Default to descending
            end
            return true
        end
    end

    -- Check view mode buttons
    for _, btn in ipairs(self.citizensViewBtns or {}) do
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.citizensViewMode = btn.modeId
            return true
        end
    end

    -- Check pagination buttons
    if self.citizensPrevPageBtn and self.citizensPrevPageBtn.enabled then
        local btn = self.citizensPrevPageBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.citizensPage = self.citizensPage - 1
            return true
        end
    end

    if self.citizensNextPageBtn and self.citizensNextPageBtn.enabled then
        local btn = self.citizensNextPageBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.citizensPage = self.citizensPage + 1
            return true
        end
    end

    -- Check citizen card clicks
    for _, btn in ipairs(self.citizensCardBtns or {}) do
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            -- Select this citizen and show details
            self.world.selectedEntity = btn.citizen
            self.selectedCitizenForModal = btn.citizen
            -- Single-click opens detail panel
            self:OpenCharacterDetailPanel(btn.citizen)
            return true
        end
    end

    -- Click outside panel = close
    if x < panelX or x > panelX + panelW or
       y < panelY or y > panelY + panelH then
        self.showCitizensPanel = false
        return true
    end

    return true  -- Consume click inside panel
end

function AlphaUI:HandleBuildingModalClick(x, y)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local modalWidth = 700
    local modalHeight = 600
    local modalX = (screenW - modalWidth) / 2
    local modalY = (screenH - modalHeight) / 2

    -- Close button
    if self.buildingModalCloseBtn then
        local btn = self.buildingModalCloseBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.showBuildingModal = false
            self.selectedBuildingForModal = nil
            return true
        end
    end

    -- Click outside modal = close
    if x < modalX or x > modalX + modalWidth or
       y < modalY or y > modalY + modalHeight then
        self.showBuildingModal = false
        self.selectedBuildingForModal = nil
        return true
    end

    -- Check station recipe button clicks
    for _, btn in ipairs(self.stationRecipeButtons or {}) do
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            -- Store which station was clicked
            self.selectedStation = btn.station
            -- Open recipe modal
            self.showRecipeModal = true
            self.modalJustOpened = true
            self.recipeModalScrollOffset = 0
            return true
        end
    end

    -- Check building management button clicks
    for _, btn in ipairs(self.buildingMgmtButtons or {}) do
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self:HandleBuildingManagementAction(btn.action, btn.enabled)
            return true
        end
    end

    return true  -- Consume click inside modal
end

-- Handle building management actions (upgrade, priority, pause, demolish)
function AlphaUI:HandleBuildingManagementAction(action, enabled)
    local building = self.selectedBuildingForModal
    if not building then return end

    if action == "upgrade" and enabled then
        local currentLevel = building.level or building.mCurrentLevel or 0
        local cost = self:GetUpgradeCost(building, currentLevel + 1)

        if self.world.gold >= cost then
            self.world.gold = self.world.gold - cost

            -- Apply upgrade
            if building.mCurrentLevel ~= nil then
                building.mCurrentLevel = building.mCurrentLevel + 1
            else
                building.level = (building.level or 0) + 1
            end

            -- Increase building stats with upgrade
            if building.maxWorkers then
                building.maxWorkers = building.maxWorkers + 1
            end

            -- Notification
            if self.notificationSystem then
                self.notificationSystem:Success(
                    "Building Upgraded!",
                    (building.name or "Building") .. " is now Level " .. ((building.level or building.mCurrentLevel or 0) + 1)
                )
            end
        else
            if self.notificationSystem then
                self.notificationSystem:Warning(
                    "Insufficient Gold",
                    "Need " .. cost .. " gold to upgrade"
                )
            end
        end

    elseif action == "priority" then
        -- Cycle through priorities: normal -> high -> low -> normal
        local currentPriority = building.priority or "normal"
        local nextPriority = {
            normal = "high",
            high = "low",
            low = "normal"
        }
        building.priority = nextPriority[currentPriority] or "normal"

    elseif action == "pause" then
        -- Toggle pause state
        if building.mIsPaused ~= nil then
            building.mIsPaused = not building.mIsPaused
        else
            building.isPaused = not (building.isPaused or false)
        end

        local isPaused = building.isPaused or building.mIsPaused or false
        if self.notificationSystem then
            self.notificationSystem:Info(
                isPaused and "Production Paused" or "Production Resumed",
                (building.name or "Building") .. " production " .. (isPaused and "paused" or "resumed")
            )
        end

    elseif action == "demolish" then
        -- Confirm demolish with notification first
        local salvage = self:GetDemolishSalvage(building)

        -- Remove building from world
        for i, b in ipairs(self.world.buildings) do
            if b == building or b.id == building.id then
                table.remove(self.world.buildings, i)
                break
            end
        end

        -- Release workers
        for _, worker in ipairs(building.workers or {}) do
            if worker then
                worker.workplace = nil
                worker.workplaceId = nil
            end
        end

        -- Add salvage to treasury
        self.world.gold = self.world.gold + salvage

        -- Notification
        if self.notificationSystem then
            self.notificationSystem:Info(
                "Building Demolished",
                (building.name or "Building") .. " demolished. Salvaged " .. salvage .. " gold."
            )
        end

        -- Close modal
        self.showBuildingModal = false
        self.selectedBuildingForModal = nil
        self.world.selectedEntity = nil
        self.world.selectedEntityType = nil
    end
end

function AlphaUI:HandleRecipeModalClick(x, y)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local modalWidth = 600
    local modalHeight = 500
    local modalX = (screenW - modalWidth) / 2
    local modalY = (screenH - modalHeight) / 2

    -- Check if clicking outside modal to close
    if x < modalX or x > modalX + modalWidth or
       y < modalY or y > modalY + modalHeight then
        self.showRecipeModal = false
        self.selectedStation = nil
        return true
    end

    -- Close button
    if self.recipeModalCloseBtn then
        local btn = self.recipeModalCloseBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.showRecipeModal = false
            self.selectedStation = nil
            return true
        end
    end

    -- Check recipe list clicks
    for _, btn in ipairs(self.recipeButtons or {}) do
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            -- Recipe selected! Assign to the selected station
            if self.selectedStation then
                self.selectedStation.recipe = btn.recipe
                self.selectedStation.state = "IDLE"
                print("Selected recipe: " .. (btn.recipe.recipeName or btn.recipe.id) .. " for station")

                -- Run free agency so citizens can consider this new job opportunity
                self.world:RunFreeAgency()
            end

            -- Close recipe modal
            self.showRecipeModal = false
            self.selectedStation = nil
            return true
        end
    end

    return true  -- Consume click inside modal
end

function AlphaUI:HandleBuildMenuClick(x, y)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local modalW = 850
    local modalH = 600
    local modalX = (screenW - modalW) / 2
    local modalY = (screenH - modalH) / 2

    -- Check close button
    if self.buildMenuCloseBtn then
        local btn = self.buildMenuCloseBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.showBuildMenuModal = false
            self.buildMenuSearchActive = false
            return true
        end
    end

    -- Check search box click
    if self.buildMenuSearchBox then
        local box = self.buildMenuSearchBox
        if x >= box.x and x < box.x + box.w and y >= box.y and y < box.y + box.h then
            self.buildMenuSearchActive = true
            return true
        else
            -- Click outside search box deactivates it
            self.buildMenuSearchActive = false
        end
    end

    -- Check category tabs (new style with buildMenuTabs table)
    if self.buildMenuTabs then
        for catId, tab in pairs(self.buildMenuTabs) do
            if x >= tab.x and x < tab.x + tab.w and y >= tab.y and y < tab.y + tab.h then
                self.buildMenuCategory = catId
                self.buildMenuScrollOffset = 0
                return true
            end
        end
    end

    -- Check building cards
    for i = 1, 100 do  -- Check up to 100 cards (more buildings now)
        local card = self["buildCard_" .. i]
        if card and x >= card.x and x < card.x + card.w and y >= card.y and y < card.y + card.h then
            if card.canAfford and card.buildingType then
                self.showBuildMenuModal = false
                self.buildMenuSearchActive = false
                self:EnterPlacementMode(card.buildingType)
            end
            return true
        end
    end

    -- Click outside modal = close
    if x < modalX or x > modalX + modalW or y < modalY or y > modalY + modalH then
        self.showBuildMenuModal = false
        self.buildMenuSearchActive = false
        return true
    end

    return true  -- Consume click inside modal
end

function AlphaUI:HandleImmigrationClick(x, y)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local modalW = 900
    local modalH = 620
    local modalX = (screenW - modalW) / 2
    local modalY = (screenH - modalH) / 2

    local immigrationSystem = self.world.immigrationSystem

    -- Check close button
    if self.immigrationCloseBtn then
        local btn = self.immigrationCloseBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.showImmigrationModal = false
            self.selectedApplicant = nil
            return true
        end
    end

    -- Check bulk action buttons
    -- Accept 70%+ button
    if self.immigrationAcceptHighBtn and self.immigrationAcceptHighBtn.enabled then
        local btn = self.immigrationAcceptHighBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            local applicants = immigrationSystem:GetApplicants()
            local toAccept = {}
            for _, app in ipairs(applicants) do
                if (app.compatibility or 0) >= 70 then
                    table.insert(toAccept, app)
                end
            end
            local accepted = 0
            for _, app in ipairs(toAccept) do
                if immigrationSystem:GetTotalVacantHousing() > 0 then
                    local success = immigrationSystem:AcceptApplicant(app)
                    if success then accepted = accepted + 1 end
                end
            end
            self.selectedApplicant = nil
            self.world:LogEvent("immigration", "Bulk accepted " .. accepted .. " high-compatibility immigrants", {})
            return true
        end
    end

    -- Accept All button
    if self.immigrationAcceptAllBtn and self.immigrationAcceptAllBtn.enabled then
        local btn = self.immigrationAcceptAllBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            local applicants = immigrationSystem:GetApplicants()
            local toAccept = {}
            for _, app in ipairs(applicants) do
                table.insert(toAccept, app)
            end
            local accepted = 0
            for _, app in ipairs(toAccept) do
                if immigrationSystem:GetTotalVacantHousing() > 0 then
                    local success = immigrationSystem:AcceptApplicant(app)
                    if success then accepted = accepted + 1 end
                end
            end
            self.selectedApplicant = nil
            self.world:LogEvent("immigration", "Bulk accepted " .. accepted .. " immigrants", {})
            return true
        end
    end

    -- Reject All button
    if self.immigrationRejectAllBtn and self.immigrationRejectAllBtn.enabled then
        local btn = self.immigrationRejectAllBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            local applicants = immigrationSystem:GetApplicants()
            local toReject = {}
            for _, app in ipairs(applicants) do
                table.insert(toReject, app)
            end
            for _, app in ipairs(toReject) do
                immigrationSystem:RejectApplicant(app)
            end
            self.selectedApplicant = nil
            self.world:LogEvent("immigration", "Rejected all " .. #toReject .. " applicants", {})
            return true
        end
    end

    -- Check applicant cards
    for i = 1, 20 do  -- Check up to 20 applicant cards
        local card = self["applicantCard_" .. i]
        if card and x >= card.x and x < card.x + card.w and y >= card.y and y < card.y + card.h then
            self.selectedApplicant = card.applicant
            self.applicantDetailScrollOffset = 0  -- Reset scroll when selecting new applicant
            return true
        end
    end

    -- Check action buttons (only if applicant selected)
    if self.selectedApplicant then
        -- Accept button
        if self.acceptApplicantBtn and self.acceptApplicantBtn.enabled then
            local btn = self.acceptApplicantBtn
            if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
                -- Check if applicant needs land (wealthy/merchant roles)
                local landReqs = self.selectedApplicant.landRequirements
                if landReqs and landReqs.minPlots and landReqs.minPlots > 0 then
                    -- Open plot selection modal
                    self:OpenPlotSelectionModal(self.selectedApplicant)
                else
                    -- No land required, accept directly
                    local success, resultOrErr = immigrationSystem:AcceptApplicant(self.selectedApplicant, {})
                    if success then
                        self.selectedApplicant = nil
                    else
                        -- On failure, second return value is the error message
                        print("Could not accept: " .. (resultOrErr or "unknown error"))
                    end
                end
                return true
            end
        end

        -- Defer button
        if self.deferApplicantBtn then
            local btn = self.deferApplicantBtn
            if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
                immigrationSystem:DeferApplicant(self.selectedApplicant)
                self.selectedApplicant = nil
                return true
            end
        end

        -- Reject button
        if self.rejectApplicantBtn then
            local btn = self.rejectApplicantBtn
            if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
                immigrationSystem:RejectApplicant(self.selectedApplicant)
                self.selectedApplicant = nil
                return true
            end
        end
    end

    -- Click outside modal = close
    if x < modalX or x > modalX + modalW or y < modalY or y > modalY + modalH then
        self.showImmigrationModal = false
        self.selectedApplicant = nil
        return true
    end

    return true  -- Consume click inside modal
end

function AlphaUI:GetBuildingTypeById(typeId)
    if not typeId then return nil end
    for _, bType in ipairs(self.world.buildingTypes or {}) do
        if bType.id == typeId then
            return bType
        end
    end
    return nil
end

function AlphaUI:GetBuildingTypeForQuickBuild(btnId)
    -- Map quick build button IDs to actual building type IDs
    -- These should match building types defined in building_types.json
    local mapping = {
        house = "simple_house",
        farm = "wheat_farm",
        workshop = "workshop",
        market = "market"
    }
    return mapping[btnId]
end

function AlphaUI:HandleKeyPress(key)
    -- Handle cheat console FIRST (highest priority when open)
    -- Toggle cheat console with backtick/grave or F10
    if key == "`" or key == "grave" or key == "f10" then
        self.showCheatConsole = not self.showCheatConsole
        if self.showCheatConsole then
            self.cheatConsoleInput = ""
            self.cheatConsoleScrollOffset = 0
        end
        return true
    end

    -- When cheat console is open, capture ALL input
    if self.showCheatConsole then
        if key == "escape" then
            self.showCheatConsole = false
            return true
        elseif key == "return" then
            -- Execute command
            if self.cheatConsoleInput ~= "" then
                local result = CheatConsole:ParseAndExecute(self.cheatConsoleInput, self.world)
                table.insert(self.cheatConsoleHistory, {
                    input = self.cheatConsoleInput,
                    output = result or ""
                })
                -- Trim history if too long
                while #self.cheatConsoleHistory > self.cheatConsoleHistoryMax do
                    table.remove(self.cheatConsoleHistory, 1)
                end
                self.cheatConsoleInput = ""
                self.cheatConsoleScrollOffset = 0
            end
            return true
        elseif key == "backspace" then
            if #self.cheatConsoleInput > 0 then
                self.cheatConsoleInput = self.cheatConsoleInput:sub(1, -2)
            end
            return true
        elseif key == "up" then
            -- Scroll history up
            if #self.cheatConsoleHistory > 0 then
                self.cheatConsoleScrollOffset = math.min(self.cheatConsoleScrollOffset + 1, #self.cheatConsoleHistory * 2)
            end
            return true
        elseif key == "down" then
            -- Scroll history down
            self.cheatConsoleScrollOffset = math.max(self.cheatConsoleScrollOffset - 1, 0)
            return true
        elseif key == "pageup" then
            -- Scroll history up faster
            self.cheatConsoleScrollOffset = self.cheatConsoleScrollOffset + 5
            return true
        elseif key == "pagedown" then
            -- Scroll history down faster
            self.cheatConsoleScrollOffset = math.max(self.cheatConsoleScrollOffset - 5, 0)
            return true
        end
        -- Consume ALL other keys when console is open (prevent game input)
        return true
    end

    -- Handle plot selection modal keys (highest priority)
    if self.showPlotSelectionModal and self.plotSelectionModal then
        if self.plotSelectionModal:HandleKeyPress(key) then
            return true
        end
    end

    -- Handle suggested buildings modal keys
    if self.showSuggestedBuildingsModal and self.suggestedBuildingsModal then
        if self.suggestedBuildingsModal:HandleKeyPress(key) then
            return true
        end
    end

    -- Handle build menu search input first (highest priority when search is active)
    if self.showBuildMenuModal and self.buildMenuSearchActive then
        if key == "backspace" then
            if #self.buildMenuSearchQuery > 0 then
                self.buildMenuSearchQuery = self.buildMenuSearchQuery:sub(1, -2)
                self.buildMenuScrollOffset = 0
            end
            return true
        elseif key == "escape" then
            if self.buildMenuSearchQuery ~= "" then
                -- First escape clears search
                self.buildMenuSearchQuery = ""
                self.buildMenuScrollOffset = 0
            else
                -- Second escape deactivates search
                self.buildMenuSearchActive = false
            end
            return true
        elseif key == "return" then
            self.buildMenuSearchActive = false
            return true
        end
        -- Other keys are handled by textinput
        return false
    end

    -- Handle day end summary modal keys
    if self.showDayEndSummaryModal and self.dayEndSummaryModal then
        if self.dayEndSummaryModal.HandleKeyPress then
            if self.dayEndSummaryModal:HandleKeyPress(key) then
                return true
            end
        end
        -- Allow escape to close the modal
        if key == "escape" then
            self.showDayEndSummaryModal = false
            self.dayEndSummaryModal = nil
            return true
        end
        -- Consume other keys when modal is open
        return true
    end

    -- Handle save/load modal first (has priority)
    if self.showSaveLoadModal and self.saveLoadModal then
        return self.saveLoadModal:HandleKeyPress(key)
    end

    -- Quicksave/Quickload hotkeys (work anywhere)
    if key == "f5" then
        self:DoQuicksave()
        return true
    elseif key == "f9" then
        self:DoQuickload()
        return true
    end

    -- Handle 'H' to toggle help overlay (works anywhere except when search is active)
    if key == "h" and not self.buildMenuSearchActive then
        self.showHelpOverlay = not self.showHelpOverlay
        return true
    end

    -- If help overlay is shown, any key closes it
    if self.showHelpOverlay then
        self.showHelpOverlay = false
        return true
    end

    -- Handle escape during modals or placement
    if key == "escape" then
        -- New Phase 8 panels first (highest priority)
        if self.characterDetailPanel and self.characterDetailPanel:IsVisible() then
            self:CloseCharacterDetailPanel()
            return true
        elseif self.showHousingAssignmentModal then
            self:CloseHousingAssignmentModal()
            return true
        elseif self.showHousingOverviewPanel then
            self:CloseHousingOverviewPanel()
            return true
        elseif self.showLandRegistryPanel then
            self:CloseLandRegistryPanel()
            return true
        elseif self.showSaveLoadModal then
            self:CloseSaveLoadModal()
            return true
        elseif self.showRecipeModal then
            self.showRecipeModal = false
            self.selectedStation = nil
            return true
        elseif self.showBuildingModal then
            self.showBuildingModal = false
            self.selectedBuildingForModal = nil
            return true
        elseif self.showImmigrationModal then
            self.showImmigrationModal = false
            self.selectedApplicant = nil
            return true
        elseif self.showBuildMenuModal then
            self.showBuildMenuModal = false
            self.buildMenuSearchActive = false
            return true
        elseif self.showCitizensPanel then
            self.showCitizensPanel = false
            return true
        elseif self.showAnalyticsPanel then
            self.showAnalyticsPanel = false
            return true
        elseif self.showInventoryPanel then
            self.showInventoryPanel = false
            return true
        elseif self.showProductionAnalyticsPanel then
            self.showProductionAnalyticsPanel = false
            self.selectedAnalyticsCommodity = nil
            return true
        elseif self.showSettingsPanel then
            self.showSettingsPanel = false
            return true
        elseif self.showEmigrationPanel then
            self.showEmigrationPanel = false
            return true
        elseif self.placementMode then
            self:ExitPlacementMode()
            return true
        else
            self.world:ClearSelection()
            return true
        end
    end

    -- Handle 'R' to toggle resource overlay panel
    if key == "r" then
        self.showResourceOverlay = not self.showResourceOverlay
        -- Toggle panel visibility in ResourceOverlay
        if self.resourceOverlay then
            if self.showResourceOverlay then
                self.resourceOverlay.mPanelVisible = true
            else
                self.resourceOverlay.mPanelVisible = false
                self.resourceOverlay:hideAll()
            end
        end
        return true
    end

    -- Handle 'L' for land overlays
    if key == "l" then
        local isShiftHeld = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
        if isShiftHeld then
            -- SHIFT+L: Toggle Land Registry Panel
            self.showLandRegistryPanel = not self.showLandRegistryPanel
            if self.showLandRegistryPanel and self.landRegistryPanel then
                self.landRegistryPanel:Show()
            elseif self.landRegistryPanel then
                self.landRegistryPanel:Hide()
            end
        else
            -- L: Toggle Land Overlay
            self.showLandOverlay = not self.showLandOverlay
            if self.showLandOverlay and self.landOverlay then
                self.landOverlay.enabled = true
            elseif self.landOverlay then
                self.landOverlay.enabled = false
            end
        end
        return true
    end

    -- Handle 'G' for Housing Overview Panel
    if key == "g" then
        self.showHousingOverviewPanel = not self.showHousingOverviewPanel
        if self.showHousingOverviewPanel and self.housingOverviewPanel then
            self.housingOverviewPanel:Show()
        elseif self.housingOverviewPanel then
            self.housingOverviewPanel:Hide()
        end
        return true
    end

    -- Handle 'SHIFT+C' for Spawn Citizen mode (debug/test feature)
    if key == "c" and not self.buildMenuSearchActive then
        local isShiftHeld = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
        if isShiftHeld then
            self.spawnCitizenMode = not self.spawnCitizenMode
            if self.spawnCitizenMode then
                -- Exit placement mode if active
                if self.placementMode then
                    self:ExitPlacementMode()
                end
                print("[Debug] Spawn Citizen mode ENABLED - Click anywhere on the map to spawn a citizen")
            else
                print("[Debug] Spawn Citizen mode DISABLED")
            end
            return true
        end
    end

    -- Forward number keys to resource overlay when panel is visible
    if self.showResourceOverlay and self.resourceOverlay then
        local num = tonumber(key)
        if num and num >= 1 and num <= 9 then
            local resourceIds = self.world.naturalResources:getAllResourceIds()
            if resourceIds[num] then
                self.resourceOverlay:toggleOverlay(resourceIds[num])
                return true
            end
        end
    end

    -- Don't handle panel shortcuts during placement mode
    if self.placementMode then
        return false
    end

    -- Panel toggle shortcuts (close other panels when opening one)
    if key == "b" then
        -- Build menu
        self.showBuildMenuModal = not self.showBuildMenuModal
        if self.showBuildMenuModal then
            self.showImmigrationModal = false
            self.showCitizensPanel = false
            self.showAnalyticsPanel = false
            self.showProductionAnalyticsPanel = false
            self.buildMenuScrollOffset = 0
            self.buildMenuSearchQuery = ""
            self.buildMenuSearchActive = false
        end
        return true
    end

    if key == "m" then
        local immigrationSystem = self.world.immigrationSystem
        if immigrationSystem then
            local isShiftHeld = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
            if isShiftHeld then
                -- SHIFT+M: Regenerate immigration queue (for testing)
                immigrationSystem:RegenerateQueue()
                self.selectedApplicant = nil
                self.immigrationScrollOffset = 0
                -- Auto-open the immigration modal to see results
                self.showImmigrationModal = true
                self.showBuildMenuModal = false
                self.showCitizensPanel = false
                self.showAnalyticsPanel = false
                self.showProductionAnalyticsPanel = false
            else
                -- M: Toggle Immigration modal
                self.showImmigrationModal = not self.showImmigrationModal
                if self.showImmigrationModal then
                    self.showBuildMenuModal = false
                    self.showCitizensPanel = false
                    self.showAnalyticsPanel = false
                    self.showProductionAnalyticsPanel = false
                    self.selectedApplicant = nil
                    self.immigrationScrollOffset = 0
                end
            end
            return true
        end
    end

    if key == "c" then
        -- Citizens panel
        self.showCitizensPanel = not self.showCitizensPanel
        if self.showCitizensPanel then
            self.showBuildMenuModal = false
            self.showImmigrationModal = false
            self.showAnalyticsPanel = false
            self.showProductionAnalyticsPanel = false
        end
        return true
    end

    if key == "a" then
        -- Analytics panel
        self.showAnalyticsPanel = not self.showAnalyticsPanel
        if self.showAnalyticsPanel then
            self.showBuildMenuModal = false
            self.showImmigrationModal = false
            self.showCitizensPanel = false
            self.showInventoryPanel = false
            self.showProductionAnalyticsPanel = false
        end
        return true
    end

    if key == "i" then
        -- Inventory panel
        self.showInventoryPanel = not self.showInventoryPanel
        if self.showInventoryPanel then
            self.showBuildMenuModal = false
            self.showImmigrationModal = false
            self.showCitizensPanel = false
            self.showAnalyticsPanel = false
            self.showProductionAnalyticsPanel = false
            self.inventoryScrollOffset = 0
        end
        return true
    end

    if key == "p" then
        -- Production Analytics panel
        self.showProductionAnalyticsPanel = not self.showProductionAnalyticsPanel
        if self.showProductionAnalyticsPanel then
            self.showBuildMenuModal = false
            self.showImmigrationModal = false
            self.showCitizensPanel = false
            self.showAnalyticsPanel = false
            self.showInventoryPanel = false
            self.productionAnalyticsScrollOffset = 0
            self.selectedAnalyticsCommodity = nil
        end
        return true
    end

    if key == "f6" then
        -- Save/Load modal (F6 for save menu)
        self:OpenSaveLoadModal("save")
        return true
    end

    if key == "o" then
        -- Settings/Options panel
        self.showSettingsPanel = not self.showSettingsPanel
        if self.showSettingsPanel then
            self.showBuildMenuModal = false
            self.showImmigrationModal = false
            self.showCitizensPanel = false
            self.showAnalyticsPanel = false
            self.showInventoryPanel = false
            self.showProductionAnalyticsPanel = false
            self.showEmigrationPanel = false
            self.settingsScrollOffset = 0
        end
        return true
    end

    if key == "e" then
        -- Emigration warning panel
        self.showEmigrationPanel = not self.showEmigrationPanel
        if self.showEmigrationPanel then
            self.showBuildMenuModal = false
            self.showImmigrationModal = false
            self.showCitizensPanel = false
            self.showAnalyticsPanel = false
            self.showInventoryPanel = false
            self.showProductionAnalyticsPanel = false
            self.showSettingsPanel = false
            self.emigrationScrollOffset = 0
        end
        return true
    end

    if key == "d" then
        -- Open character detail panel for selected citizen
        if self.world.selectedEntity and self.world.selectedEntityType == "citizen" then
            self:OpenCharacterDetailPanel(self.world.selectedEntity)
            return true
        end
    end

    -- Don't handle game controls during modals
    if self.showBuildMenuModal or self.showImmigrationModal or self.showCitizensPanel or self.showAnalyticsPanel or self.showProductionAnalyticsPanel or self.showInventoryPanel or self.showSettingsPanel or self.showEmigrationPanel then
        return false
    end

    -- Simulation controls
    if key == "space" then
        self.world:TogglePause()
        return true
    elseif key == "1" then
        self.world:SetTimeScale("normal")
        return true
    elseif key == "2" then
        self.world:SetTimeScale("fast")
        return true
    elseif key == "3" then
        self.world:SetTimeScale("faster")
        return true
    elseif key == "4" then
        self.world:SetTimeScale("fastest")
        return true
    elseif key == "5" then
        self.world:SetTimeScale("turbo")
        return true
    end

    return false
end

function AlphaUI:Update(dt)
    -- Check for pending day end summary from world
    if self.world.pendingDayEndSummary and not self.showDayEndSummaryModal then
        local dayNumber = self.world.pendingDayEndSummary.dayNumber
        self.world.pendingDayEndSummary = nil  -- Clear the pending flag

        -- Create the modal with a close callback
        self.dayEndSummaryModal = DayEndSummaryModal:Create(self.world, dayNumber, function()
            self.showDayEndSummaryModal = false
            self.dayEndSummaryModal = nil
        end)
        self.showDayEndSummaryModal = true
    end

    -- Update day end summary modal
    if self.showDayEndSummaryModal and self.dayEndSummaryModal then
        if self.dayEndSummaryModal.Update then
            self.dayEndSummaryModal:Update(dt)
        end
    end

    -- Update save/load modal
    if self.showSaveLoadModal and self.saveLoadModal then
        self.saveLoadModal:Update(dt)
    end

    -- Update notification system
    if self.notificationSystem then
        self.notificationSystem:Update(dt)
    end

    -- Update tutorial system
    if self.tutorialSystem then
        self.tutorialSystem:Update(dt)
    end

    -- Update debug panel (CRAVE-6)
    if self.debugPanel then
        self.debugPanel:Update(dt)
    end

    -- Update placement mode (track mouse position)
    if self.placementMode then
        local mx, my = love.mouse.getPosition()
        self:UpdatePlacement(mx, my)
    end

    -- Track camera movement for tutorial
    local oldCamX, oldCamY = self.cameraX, self.cameraY

    -- Handle continuous camera movement with WASD/arrow keys
    local camSpeed = 200 * dt

    -- Calculate viewport size (center area minus panels)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local viewW = screenW - self.leftPanelWidth - self.rightPanelWidth
    local viewH = screenH - self.topBarHeight - self.bottomBarHeight

    -- Maximum camera position (world size minus viewport)
    local maxCameraX = math.max(0, self.worldWidth - viewW)
    local maxCameraY = math.max(0, self.worldHeight - viewH)

    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then
        self.cameraY = math.max(0, self.cameraY - camSpeed)
    end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then
        self.cameraY = math.min(maxCameraY, self.cameraY + camSpeed)
    end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        self.cameraX = math.max(0, self.cameraX - camSpeed)
    end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        self.cameraX = math.min(maxCameraX, self.cameraX + camSpeed)
    end

    -- Notify tutorial of camera movement
    if self.tutorialSystem and (self.cameraX ~= oldCamX or self.cameraY ~= oldCamY) then
        self.tutorialSystem:OnCameraMoved()
    end
end

function AlphaUI:HandleMouseWheel(x, y)
    -- Handle day end summary modal scroll (highest priority when open)
    if self.showDayEndSummaryModal and self.dayEndSummaryModal then
        if self.dayEndSummaryModal.OnMouseWheel then
            self.dayEndSummaryModal:OnMouseWheel(x, y)
        end
        return
    end

    -- Handle cheat console scroll (highest priority when open)
    if self.showCheatConsole then
        if y > 0 then
            -- Scroll up (show older history)
            self.cheatConsoleScrollOffset = self.cheatConsoleScrollOffset + 3
        elseif y < 0 then
            -- Scroll down (show newer history)
            self.cheatConsoleScrollOffset = math.max(self.cheatConsoleScrollOffset - 3, 0)
        end
        return
    end

    -- Handle debug panel scroll (CRAVE-6) - highest priority
    if self.debugPanel and self.debugPanel:IsVisible() then
        if self.debugPanel:HandleMouseWheel(x, y) then
            return
        end
    end

    -- Handle supply chain viewer scroll
    if self.supplyChainViewer and self.supplyChainViewer.isVisible then
        self.supplyChainViewer:OnMouseWheel(x, y)
        return
    end

    -- Handle character detail panel scroll
    if self.characterDetailPanel and self.characterDetailPanel:IsVisible() then
        if self.characterDetailPanel:HandleMouseWheel(y) then
            return
        end
    end

    -- Handle housing assignment modal scroll
    if self.showHousingAssignmentModal and self.housingAssignmentModal then
        if self.housingAssignmentModal:HandleMouseWheel(y) then
            return
        end
    end

    -- Handle housing overview panel scroll
    if self.showHousingOverviewPanel and self.housingOverviewPanel then
        if self.housingOverviewPanel:HandleMouseWheel(y) then
            return
        end
    end

    -- Handle land registry panel scroll
    if self.showLandRegistryPanel and self.landRegistryPanel then
        if self.landRegistryPanel:HandleMouseWheel(y) then
            return
        end
    end

    -- Handle plot selection modal scroll (highest priority)
    if self.showPlotSelectionModal and self.plotSelectionModal then
        if self.plotSelectionModal:HandleMouseWheel(x, y, 0, y) then
            return
        end
    end

    -- Handle suggested buildings modal scroll
    if self.showSuggestedBuildingsModal and self.suggestedBuildingsModal then
        if self.suggestedBuildingsModal:HandleMouseWheel(x, y, 0, y) then
            return
        end
    end

    -- Scroll recipe modal (has priority over building modal)
    if self.showRecipeModal then
        local newOffset = self.recipeModalScrollOffset - y * 30
        self.recipeModalScrollOffset = math.max(0, math.min(newOffset, self.recipeModalScrollMax))
        return
    end

    -- Scroll building modal
    if self.showBuildingModal then
        local newOffset = self.buildingModalScrollOffset - y * 30
        self.buildingModalScrollOffset = math.max(0, math.min(newOffset, self.buildingModalScrollMax))
        return
    end

    -- Scroll build menu modal
    if self.showBuildMenuModal then
        self.buildMenuScrollOffset = math.max(0, self.buildMenuScrollOffset - y * 30)
        return
    end

    -- Scroll immigration modal
    if self.showImmigrationModal then
        local mx, my = love.mouse.getPosition()
        local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
        local modalW, modalH = 900, 620
        local modalX = (screenW - modalW) / 2
        local modalY = (screenH - modalH) / 2

        -- Check if mouse is over detail panel (right side)
        local detailX = modalX + 340 + 30
        local detailY = modalY + 82
        local detailW = modalW - 340 - 45
        local detailH = modalH - 162

        if mx >= detailX and mx < detailX + detailW and
           my >= detailY and my < detailY + detailH then
            -- Scroll detail panel
            self.applicantDetailScrollOffset = self.applicantDetailScrollOffset or 0
            local newOffset = self.applicantDetailScrollOffset - y * 30
            self.applicantDetailScrollOffset = math.max(0, math.min(newOffset, self.applicantDetailScrollMax or 0))
        else
            -- Scroll applicant list
            self.immigrationScrollOffset = math.max(0, self.immigrationScrollOffset - y * 30)
        end
        return
    end

    -- Scroll inventory panel
    if self.showInventoryPanel then
        local mx, my = love.mouse.getPosition()

        -- Check if mouse is over category area
        if self.inventoryCategoryArea then
            local catArea = self.inventoryCategoryArea
            if mx >= catArea.x and mx < catArea.x + catArea.w and
               my >= catArea.y and my < catArea.y + catArea.h then
                -- Scroll categories
                local newOffset = self.inventoryCategoryScrollOffset - y * 30
                self.inventoryCategoryScrollOffset = math.max(0, math.min(newOffset, self.inventoryCategoryMaxScroll))
                return
            end
        end

        -- Otherwise scroll commodity list
        local newOffset = self.inventoryScrollOffset - y * 30
        self.inventoryScrollOffset = math.max(0, math.min(newOffset, self.inventoryMaxScroll))
        return
    end

    -- Scroll citizens panel (list view only)
    if self.showCitizensPanel and self.citizensViewMode == "list" then
        local mx, my = love.mouse.getPosition()

        -- Check if mouse is over list area
        if self.citizensListArea then
            local listArea = self.citizensListArea
            if mx >= listArea.x and mx < listArea.x + listArea.w and
               my >= listArea.y and my < listArea.y + listArea.h then
                local newOffset = self.citizensScrollOffset - y * 30
                self.citizensScrollOffset = math.max(0, math.min(newOffset, self.citizensMaxScroll or 0))
                return
            end
        end
        return  -- Don't zoom when citizens panel is open
    end

    -- Scroll production analytics panel
    if self.showProductionAnalyticsPanel then
        local newOffset = self.productionAnalyticsScrollOffset - y * 30
        self.productionAnalyticsScrollOffset = math.max(0, math.min(newOffset, self.productionAnalyticsMaxScroll or 0))
        return
    end

    -- Scroll emigration panel
    if self.showEmigrationPanel then
        local newOffset = self.emigrationScrollOffset - y * 30
        self.emigrationScrollOffset = math.max(0, math.min(newOffset, self.emigrationMaxScroll or 0))
        return
    end

    -- Zoom in/out with mouse wheel
    local zoomSpeed = 0.1
    if y > 0 then
        self.cameraZoom = math.min(2.0, self.cameraZoom + zoomSpeed)
    elseif y < 0 then
        self.cameraZoom = math.max(0.5, self.cameraZoom - zoomSpeed)
    end
end

function AlphaUI:HandleMouseMove(x, y)
    -- Handle debug panel dragging (CRAVE-6) - high priority
    if self.debugPanel and self.debugPanel:IsVisible() then
        if self.debugPanel:HandleMouseMove(x, y) then
            return
        end
    end

    -- Handle plot selection modal mouse move (highest priority)
    if self.showPlotSelectionModal and self.plotSelectionModal then
        -- Calculate dx, dy for drag handling
        local dx, dy = 0, 0
        if love.mouse.isDown(1) then
            -- Get delta from previous position (stored in modal or calculated)
            dx = x - (self.lastMouseX or x)
            dy = y - (self.lastMouseY or y)
            self.plotSelectionModal:HandleDrag(dx, dy)
        end
        self.plotSelectionModal:HandleMouseMove(x, y, dx, dy)
        self.lastMouseX = x
        self.lastMouseY = y
        return
    end

    -- Handle suggested buildings modal mouse move
    if self.showSuggestedBuildingsModal and self.suggestedBuildingsModal then
        self.suggestedBuildingsModal:HandleMouseMove(x, y)
        self.lastMouseX = x
        self.lastMouseY = y
        return
    end

    self.lastMouseX = x
    self.lastMouseY = y

    -- Handle save/load modal mouse move first (has priority)
    if self.showSaveLoadModal and self.saveLoadModal then
        self.saveLoadModal:HandleMouseMove(x, y)
        return
    end

    -- Update hovered button state
    self.hoveredButton = nil

    -- Update placement position
    if self.placementMode then
        self:UpdatePlacement(x, y)
    end

    -- Check quick build buttons
    for btnId, btn in pairs(self.quickBuildButtons) do
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.hoveredButton = btnId
            break
        end
    end
end

function AlphaUI:HandleMouseRelease(x, y, button)
    -- Forward to debug panel for drag handling (CRAVE-6)
    if self.debugPanel then
        if self.debugPanel:HandleMouseRelease(x, y, button) then
            return true
        end
    end

    -- Other mouse release handling can be added here in the future
    return false
end

-- =============================================================================
-- HELP OVERLAY
-- =============================================================================

function AlphaUI:RenderHelpOverlay()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Panel dimensions (increased height for more shortcuts)
    local panelW = math.min(700, screenW - 100)
    local panelH = math.min(580, screenH - 100)
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Panel background
    love.graphics.setColor(0.12, 0.12, 0.16)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 8, 8)

    -- Panel border
    love.graphics.setColor(0.3, 0.5, 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 8, 8)

    -- Title
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.85, 0.7, 0.3)
    local title = "KEYBOARD SHORTCUTS"
    local titleW = self.fonts.header:getWidth(title)
    love.graphics.print(title, panelX + (panelW - titleW) / 2, panelY + 15)

    -- Columns
    local col1X = panelX + 30
    local col2X = panelX + panelW / 2 + 20
    local startY = panelY + 55

    love.graphics.setFont(self.fonts.normal)

    -- Column 1: Simulation
    love.graphics.setColor(0.4, 0.7, 1.0)
    love.graphics.print("SIMULATION", col1X, startY)
    startY = startY + 25

    local shortcuts1 = {
        {"SPACE", "Pause / Resume"},
        {"1", "Normal speed (1x)"},
        {"2", "Fast speed (2x)"},
        {"3", "Faster speed (5x)"},
        {"4", "Fastest speed (10x)"},
        {"5", "Turbo speed (20x)"}
    }

    for _, shortcut in ipairs(shortcuts1) do
        love.graphics.setColor(0.9, 0.85, 0.5)
        love.graphics.print(shortcut[1], col1X, startY)
        love.graphics.setColor(0.8, 0.8, 0.85)
        love.graphics.print(shortcut[2], col1X + 80, startY)
        startY = startY + 22
    end

    startY = startY + 15

    -- Column 1: Panels
    love.graphics.setColor(0.4, 0.7, 1.0)
    love.graphics.print("PANELS", col1X, startY)
    startY = startY + 25

    local shortcuts2 = {
        {"B", "Build menu"},
        {"C", "Citizens panel"},
        {"I", "Inventory"},
        {"P", "Production Analytics"},
        {"M", "Immigration"},
        {"E", "Emigration warnings"},
        {"A", "Analytics"},
        {"O", "Settings/Options"},
        {"G", "Housing overview"},
        {"L", "Land overlay"},
        {"SHIFT+L", "Land registry panel"},
        {"D", "Citizen details (if selected)"},
        {"F6", "Save/Load menu"},
        {"H", "This help overlay"},
        {"ESC", "Close panel"}
    }

    for _, shortcut in ipairs(shortcuts2) do
        love.graphics.setColor(0.9, 0.85, 0.5)
        love.graphics.print(shortcut[1], col1X, startY)
        love.graphics.setColor(0.8, 0.8, 0.85)
        love.graphics.print(shortcut[2], col1X + 80, startY)
        startY = startY + 22
    end

    -- Column 2: Camera
    local startY2 = panelY + 55
    love.graphics.setColor(0.4, 0.7, 1.0)
    love.graphics.print("CAMERA", col2X, startY2)
    startY2 = startY2 + 25

    local shortcuts3 = {
        {"W / Up", "Pan up"},
        {"S / Down", "Pan down"},
        {"A / Left", "Pan left"},
        {"D / Right", "Pan right"},
        {"Scroll", "Zoom in/out"},
        {"Middle-drag", "Pan camera"}
    }

    for _, shortcut in ipairs(shortcuts3) do
        love.graphics.setColor(0.9, 0.85, 0.5)
        love.graphics.print(shortcut[1], col2X, startY2)
        love.graphics.setColor(0.8, 0.8, 0.85)
        love.graphics.print(shortcut[2], col2X + 100, startY2)
        startY2 = startY2 + 22
    end

    startY2 = startY2 + 15

    -- Column 2: Selection
    love.graphics.setColor(0.4, 0.7, 1.0)
    love.graphics.print("SELECTION", col2X, startY2)
    startY2 = startY2 + 25

    local shortcuts4 = {
        {"Left-click", "Select building/citizen"},
        {"Right-click", "Context menu"},
        {"Click empty", "Deselect"},
        {"F5", "Quicksave"},
        {"F9", "Quickload"},
        {"`", "Cheat console"}
    }

    for _, shortcut in ipairs(shortcuts4) do
        love.graphics.setColor(0.9, 0.85, 0.5)
        love.graphics.print(shortcut[1], col2X, startY2)
        love.graphics.setColor(0.8, 0.8, 0.85)
        love.graphics.print(shortcut[2], col2X + 100, startY2)
        startY2 = startY2 + 22
    end

    startY2 = startY2 + 15

    -- Column 2: Building Placement
    love.graphics.setColor(0.4, 0.7, 1.0)
    love.graphics.print("BUILDING PLACEMENT", col2X, startY2)
    startY2 = startY2 + 25

    local shortcuts5 = {
        {"R", "Toggle resource overlay"},
        {"Left-click", "Place building"},
        {"ESC", "Cancel placement"}
    }

    for _, shortcut in ipairs(shortcuts5) do
        love.graphics.setColor(0.9, 0.85, 0.5)
        love.graphics.print(shortcut[1], col2X, startY2)
        love.graphics.setColor(0.8, 0.8, 0.85)
        love.graphics.print(shortcut[2], col2X + 100, startY2)
        startY2 = startY2 + 22
    end

    -- Close hint
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.6, 0.6, 0.65)
    local closeText = "Press H or any key to close"
    local closeW = self.fonts.small:getWidth(closeText)
    love.graphics.print(closeText, panelX + (panelW - closeW) / 2, panelY + panelH - 30)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- =============================================================================
-- CHEAT CONSOLE
-- =============================================================================

function AlphaUI:RenderCheatConsole()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local consoleH = 220
    local consoleY = screenH - consoleH

    -- Update cursor blink
    self.cheatConsoleCursorTimer = self.cheatConsoleCursorTimer + love.timer.getDelta()
    if self.cheatConsoleCursorTimer > 0.5 then
        self.cheatConsoleCursorTimer = 0
        self.cheatConsoleCursorVisible = not self.cheatConsoleCursorVisible
    end

    -- Semi-transparent background
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", 0, consoleY, screenW, consoleH)

    -- Top border
    love.graphics.setColor(0.3, 1, 0.3, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.line(0, consoleY, screenW, consoleY)

    -- Title
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(0.3, 1, 0.3)
    love.graphics.print("CHEAT CONSOLE (type 'help' for commands, ` to close)", 10, consoleY + 5)

    -- History area
    local historyY = consoleY + 25
    local historyH = consoleH - 55
    local lineHeight = 18
    local maxVisibleLines = math.floor(historyH / lineHeight)

    love.graphics.setFont(self.fonts.small)

    -- Render history (newest at bottom)
    local visibleHistory = {}
    for i, entry in ipairs(self.cheatConsoleHistory) do
        table.insert(visibleHistory, {type = "input", text = "> " .. entry.input})
        if entry.output and entry.output ~= "" then
            -- Split multi-line output
            for line in entry.output:gmatch("[^\n]+") do
                table.insert(visibleHistory, {type = "output", text = "  " .. line})
            end
        end
    end

    -- Calculate scroll
    local totalLines = #visibleHistory
    local startLine = math.max(1, totalLines - maxVisibleLines + 1 - self.cheatConsoleScrollOffset)
    local endLine = math.min(totalLines, startLine + maxVisibleLines - 1)

    local y = historyY
    for i = startLine, endLine do
        local entry = visibleHistory[i]
        if entry then
            if entry.type == "input" then
                love.graphics.setColor(0.3, 1, 0.3)  -- Green for input
            else
                love.graphics.setColor(0.8, 0.8, 0.8)  -- Gray for output
            end
            love.graphics.print(entry.text, 10, y)
            y = y + lineHeight
        end
    end

    -- Scroll indicator
    if totalLines > maxVisibleLines then
        love.graphics.setColor(0.5, 0.5, 0.5)
        local scrollText = string.format("[%d/%d lines - Up/Down to scroll]",
            totalLines - self.cheatConsoleScrollOffset, totalLines)
        love.graphics.print(scrollText, screenW - 250, consoleY + 5)
    end

    -- Input line
    local inputY = screenH - 28
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, inputY - 4, screenW, 32)

    love.graphics.setColor(0.3, 1, 0.3)
    love.graphics.setFont(self.fonts.normal)

    -- Prompt and input
    local cursor = self.cheatConsoleCursorVisible and "_" or ""
    love.graphics.print("> " .. self.cheatConsoleInput .. cursor, 10, inputY)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- =============================================================================
-- SAVE/LOAD MODAL
-- =============================================================================

function AlphaUI:OpenSaveLoadModal(mode)
    mode = mode or "save"
    self.showSaveLoadModal = true

    -- Close other panels
    self.showBuildMenuModal = false
    self.showImmigrationModal = false
    self.showCitizensPanel = false
    self.showAnalyticsPanel = false

    -- Create modal with callbacks
    self.saveLoadModal = SaveLoadModal:Create(self.world, function()
        self:CloseSaveLoadModal()
    end)

    -- Set up load callback
    self.saveLoadModal.onLoad = function(saveData)
        if self.onLoadGame then
            self.onLoadGame(saveData)
        end
    end

    -- Set mode
    self.saveLoadModal:SetMode(mode)
end

function AlphaUI:CloseSaveLoadModal()
    self.showSaveLoadModal = false
    self.saveLoadModal = nil
end

function AlphaUI:DoQuicksave()
    local SaveManager = require("code.SaveManager")
    local saveManager = SaveManager:Create()

    local success, msg = saveManager:Quicksave(self.world)
    if success then
        self.world:LogEvent("info", "Quicksave complete (F5)", {})
    else
        self.world:LogEvent("warning", "Quicksave failed", {})
    end
end

function AlphaUI:DoQuickload()
    local SaveManager = require("code.SaveManager")
    local saveManager = SaveManager:Create()

    if not saveManager:HasQuicksave() then
        self.world:LogEvent("warning", "No quicksave found", {})
        return
    end

    local data, msg = saveManager:Quickload()
    if data and self.onLoadGame then
        self.onLoadGame(data)
    else
        self.world:LogEvent("warning", "Quickload failed", {})
    end
end

-- =============================================================================
-- SETTINGS PANEL
-- =============================================================================

function AlphaUI:RenderSettingsPanel()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Initialize state if needed
    self.settingsTab = self.settingsTab or "gameplay"
    self.settingsScrollOffset = self.settingsScrollOffset or 0

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Panel dimensions
    local panelW = math.min(700, screenW - 100)
    local panelH = math.min(550, screenH - 100)
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Panel background
    love.graphics.setColor(0.12, 0.12, 0.16)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 8, 8)

    -- Panel border
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 8, 8)

    -- Header
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Settings", panelX + 20, panelY + 15)

    -- Close button
    local closeBtnX = panelX + panelW - 40
    local closeBtnY = panelY + 15
    local closeBtnSize = 25
    local mx, my = love.mouse.getPosition()
    local closeHover = mx >= closeBtnX and mx < closeBtnX + closeBtnSize and
                       my >= closeBtnY and my < closeBtnY + closeBtnSize

    love.graphics.setColor(closeHover and {0.8, 0.3, 0.3} or {0.5, 0.5, 0.5})
    love.graphics.rectangle("fill", closeBtnX, closeBtnY, closeBtnSize, closeBtnSize, 4, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.normal)
    love.graphics.print("X", closeBtnX + 7, closeBtnY + 3)

    self.settingsCloseBtn = {x = closeBtnX, y = closeBtnY, w = closeBtnSize, h = closeBtnSize}

    -- Tab buttons
    local tabY = panelY + 55
    local tabX = panelX + 20
    local tabs = {
        {id = "gameplay", label = "Gameplay"},
        {id = "display", label = "Display"},
        {id = "audio", label = "Audio"},
        {id = "accessibility", label = "Accessibility"}
    }

    self.settingsTabBtns = {}
    love.graphics.setFont(self.fonts.small)

    for _, tab in ipairs(tabs) do
        local tabW = self.fonts.small:getWidth(tab.label) + 24
        local tabH = 28
        local isActive = self.settingsTab == tab.id
        local isHover = mx >= tabX and mx < tabX + tabW and my >= tabY and my < tabY + tabH

        if isActive then
            love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.7)
        elseif isHover then
            love.graphics.setColor(0.3, 0.3, 0.35)
        else
            love.graphics.setColor(0.2, 0.2, 0.25)
        end
        love.graphics.rectangle("fill", tabX, tabY, tabW, tabH, 4, 4)

        love.graphics.setColor(isActive and {1, 1, 1} or self.colors.textDim)
        love.graphics.print(tab.label, tabX + 12, tabY + 6)

        table.insert(self.settingsTabBtns, {x = tabX, y = tabY, w = tabW, h = tabH, tabId = tab.id})
        tabX = tabX + tabW + 8
    end

    -- Content area
    local contentX = panelX + 20
    local contentY = tabY + 45
    local contentW = panelW - 40
    local contentH = panelH - (contentY - panelY) - 60

    -- Content background
    love.graphics.setColor(0.15, 0.15, 0.18)
    love.graphics.rectangle("fill", contentX, contentY, contentW, contentH, 4, 4)

    -- Render tab content
    love.graphics.setScissor(contentX, contentY, contentW, contentH)

    if self.settingsTab == "gameplay" then
        self:RenderSettingsGameplayTab(contentX + 15, contentY + 10, contentW - 30, contentH - 20)
    elseif self.settingsTab == "display" then
        self:RenderSettingsDisplayTab(contentX + 15, contentY + 10, contentW - 30, contentH - 20)
    elseif self.settingsTab == "audio" then
        self:RenderSettingsAudioTab(contentX + 15, contentY + 10, contentW - 30, contentH - 20)
    elseif self.settingsTab == "accessibility" then
        self:RenderSettingsAccessibilityTab(contentX + 15, contentY + 10, contentW - 30, contentH - 20)
    end

    love.graphics.setScissor()

    -- Reset to defaults button
    local resetBtnW = 120
    local resetBtnH = 30
    local resetBtnX = panelX + panelW - resetBtnW - 20
    local resetBtnY = panelY + panelH - resetBtnH - 15
    local resetHover = mx >= resetBtnX and mx < resetBtnX + resetBtnW and
                       my >= resetBtnY and my < resetBtnY + resetBtnH

    love.graphics.setColor(resetHover and {0.6, 0.3, 0.3} or {0.4, 0.25, 0.25})
    love.graphics.rectangle("fill", resetBtnX, resetBtnY, resetBtnW, resetBtnH, 4, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.small)
    local resetText = "Reset to Defaults"
    local resetTextW = self.fonts.small:getWidth(resetText)
    love.graphics.print(resetText, resetBtnX + (resetBtnW - resetTextW) / 2, resetBtnY + 7)

    self.settingsResetBtn = {x = resetBtnX, y = resetBtnY, w = resetBtnW, h = resetBtnH}
end

function AlphaUI:RenderSettingsGameplayTab(x, y, w, h)
    self.settingsControls = {}
    -- Lazy initialization in case gameSettings wasn't set up
    if not self.gameSettings then
        self.gameSettings = GameSettings:GetInstance()
    end
    local settings = self.gameSettings
    local rowY = y

    love.graphics.setFont(self.fonts.normal)

    -- Auto-pause on Critical Events
    rowY = self:RenderSettingsCheckbox(x, rowY, w, "autoPauseOnCritical", "Auto-pause on Critical Events",
        "Automatically pause the game when critical events occur",
        settings:Get("gameplay", "autoPauseOnCritical"))

    -- Auto-pause on Warnings
    rowY = self:RenderSettingsCheckbox(x, rowY, w, "autoPauseOnWarning", "Auto-pause on Warnings",
        "Automatically pause the game when warnings occur",
        settings:Get("gameplay", "autoPauseOnWarning"))

    -- Tutorial Hints
    rowY = self:RenderSettingsCheckbox(x, rowY, w, "tutorialHints", "Tutorial Hints",
        "Show helpful hints during gameplay",
        settings:Get("gameplay", "tutorialHints"))

    -- Show Production Numbers
    rowY = self:RenderSettingsCheckbox(x, rowY, w, "showProductionNumbers", "Show Production Numbers",
        "Display production rates on buildings",
        settings:Get("gameplay", "showProductionNumbers"))

    -- Autosave Enabled
    rowY = self:RenderSettingsCheckbox(x, rowY, w, "autosaveEnabled", "Enable Autosave",
        "Automatically save the game periodically",
        settings:Get("gameplay", "autosaveEnabled"))

    -- Autosave Interval
    rowY = rowY + 10
    rowY = self:RenderSettingsSlider(x, rowY, w, "autosaveInterval", "Autosave Interval",
        "Cycles between autosaves",
        settings:Get("gameplay", "autosaveInterval"), 10, 100, 5, " cycles")

    -- Notification Frequency
    rowY = rowY + 10
    rowY = self:RenderSettingsDropdown(x, rowY, w, "notificationFrequency", "Notification Frequency",
        "How often to show notifications",
        settings:Get("gameplay", "notificationFrequency"),
        {
            {value = "minimal", label = "Minimal"},
            {value = "normal", label = "Normal"},
            {value = "verbose", label = "Verbose"}
        })
end

function AlphaUI:RenderSettingsDisplayTab(x, y, w, h)
    self.settingsControls = {}
    if not self.gameSettings then
        self.gameSettings = GameSettings:GetInstance()
    end
    local settings = self.gameSettings
    local rowY = y

    love.graphics.setFont(self.fonts.normal)

    -- Fullscreen
    rowY = self:RenderSettingsCheckbox(x, rowY, w, "fullscreen", "Fullscreen",
        "Run the game in fullscreen mode",
        settings:Get("display", "fullscreen"))

    -- VSync
    rowY = self:RenderSettingsCheckbox(x, rowY, w, "vsync", "VSync",
        "Synchronize frame rate with monitor refresh rate",
        settings:Get("display", "vsync"))

    -- Show Building Names
    rowY = self:RenderSettingsCheckbox(x, rowY, w, "showBuildingNames", "Show Building Names",
        "Display building names in the world view",
        settings:Get("display", "showBuildingNames"))

    -- UI Scale
    rowY = rowY + 10
    rowY = self:RenderSettingsSlider(x, rowY, w, "uiScale", "UI Scale",
        "Adjust the size of UI elements",
        settings:Get("display", "uiScale"), 0.75, 1.5, 0.05, "x")

    -- Camera Zoom Speed
    rowY = rowY + 10
    rowY = self:RenderSettingsSlider(x, rowY, w, "cameraZoomSpeed", "Zoom Speed",
        "How fast the camera zooms in/out",
        settings:Get("display", "cameraZoomSpeed"), 0.05, 0.3, 0.05, "")

    -- Show Character Names
    rowY = rowY + 10
    rowY = self:RenderSettingsDropdown(x, rowY, w, "showCharacterNames", "Character Names",
        "When to show character names",
        settings:Get("display", "showCharacterNames"),
        {
            {value = "always", label = "Always"},
            {value = "hover", label = "On Hover"},
            {value = "never", label = "Never"}
        })

    -- Color Blind Mode
    rowY = rowY + 10
    rowY = self:RenderSettingsDropdown(x, rowY, w, "colorBlindMode", "Color Blind Mode",
        "Adjust colors for color blindness",
        settings:Get("display", "colorBlindMode"),
        {
            {value = "none", label = "None"},
            {value = "protanopia", label = "Protanopia (Red-Blind)"},
            {value = "deuteranopia", label = "Deuteranopia (Green-Blind)"},
            {value = "tritanopia", label = "Tritanopia (Blue-Blind)"}
        })
end

function AlphaUI:RenderSettingsAudioTab(x, y, w, h)
    self.settingsControls = {}
    if not self.gameSettings then
        self.gameSettings = GameSettings:GetInstance()
    end
    local settings = self.gameSettings
    local rowY = y

    love.graphics.setFont(self.fonts.normal)

    -- Note about audio
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Audio system is planned for future implementation.", x, rowY)
    love.graphics.print("Settings below will take effect when audio is added.", x, rowY + 20)
    rowY = rowY + 50

    -- Master Volume
    rowY = self:RenderSettingsSlider(x, rowY, w, "masterVolume", "Master Volume",
        "Overall game volume",
        settings:Get("audio", "masterVolume"), 0, 1, 0.1, "%", true)

    -- Music Volume
    rowY = rowY + 10
    rowY = self:RenderSettingsSlider(x, rowY, w, "musicVolume", "Music Volume",
        "Background music volume",
        settings:Get("audio", "musicVolume"), 0, 1, 0.1, "%", true)

    -- SFX Volume
    rowY = rowY + 10
    rowY = self:RenderSettingsSlider(x, rowY, w, "sfxVolume", "SFX Volume",
        "Sound effects volume",
        settings:Get("audio", "sfxVolume"), 0, 1, 0.1, "%", true)

    -- Ambient Volume
    rowY = rowY + 10
    rowY = self:RenderSettingsSlider(x, rowY, w, "ambientVolume", "Ambient Volume",
        "Environmental sounds volume",
        settings:Get("audio", "ambientVolume"), 0, 1, 0.1, "%", true)

    -- Notification Sounds
    rowY = rowY + 15
    rowY = self:RenderSettingsCheckbox(x, rowY, w, "notificationSounds", "Notification Sounds",
        "Play sounds for notifications",
        settings:Get("audio", "notificationSounds"))

    -- UI Sounds
    rowY = self:RenderSettingsCheckbox(x, rowY, w, "uiSounds", "UI Sounds",
        "Play sounds for UI interactions",
        settings:Get("audio", "uiSounds"))
end

function AlphaUI:RenderSettingsAccessibilityTab(x, y, w, h)
    self.settingsControls = {}
    if not self.gameSettings then
        self.gameSettings = GameSettings:GetInstance()
    end
    local settings = self.gameSettings
    local rowY = y

    love.graphics.setFont(self.fonts.normal)

    -- Larger Text
    rowY = self:RenderSettingsCheckbox(x, rowY, w, "largerText", "Larger Text",
        "Increase text size throughout the game",
        settings:Get("accessibility", "largerText"))

    -- High Contrast
    rowY = self:RenderSettingsCheckbox(x, rowY, w, "highContrast", "High Contrast Mode",
        "Increase contrast for better visibility",
        settings:Get("accessibility", "highContrast"))

    -- Reduced Motion
    rowY = self:RenderSettingsCheckbox(x, rowY, w, "reducedMotion", "Reduced Motion",
        "Minimize animations and movement",
        settings:Get("accessibility", "reducedMotion"))

    -- Note about additional accessibility features
    rowY = rowY + 20
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Additional accessibility features coming soon:", x, rowY)
    rowY = rowY + 25
    love.graphics.print("- Screen reader support", x + 20, rowY)
    rowY = rowY + 20
    love.graphics.print("- Keyboard-only navigation", x + 20, rowY)
    rowY = rowY + 20
    love.graphics.print("- Customizable hotkeys", x + 20, rowY)
end

-- Helper: Render checkbox setting
function AlphaUI:RenderSettingsCheckbox(x, y, w, key, label, description, value)
    local mx, my = love.mouse.getPosition()
    local checkSize = 20
    local rowH = 45

    -- Checkbox
    local checkX = x
    local checkY = y + 5
    local isHover = mx >= checkX and mx < checkX + checkSize and my >= checkY and my < checkY + checkSize

    love.graphics.setColor(isHover and {0.35, 0.35, 0.4} or {0.25, 0.25, 0.3})
    love.graphics.rectangle("fill", checkX, checkY, checkSize, checkSize, 3, 3)
    love.graphics.setColor(0.4, 0.4, 0.45)
    love.graphics.rectangle("line", checkX, checkY, checkSize, checkSize, 3, 3)

    if value then
        love.graphics.setColor(self.colors.success)
        love.graphics.setFont(self.fonts.normal)
        love.graphics.print("✓", checkX + 3, checkY + 1)
    end

    -- Label
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.normal)
    love.graphics.print(label, x + checkSize + 10, y + 3)

    -- Description
    love.graphics.setColor(self.colors.textDim)
    love.graphics.setFont(self.fonts.small)
    love.graphics.print(description, x + checkSize + 10, y + 22)

    table.insert(self.settingsControls, {
        type = "checkbox",
        key = key,
        x = checkX,
        y = checkY,
        w = checkSize,
        h = checkSize,
        value = value
    })

    return y + rowH
end

-- Helper: Render slider setting
function AlphaUI:RenderSettingsSlider(x, y, w, key, label, description, value, minVal, maxVal, step, suffix, isPercent)
    local mx, my = love.mouse.getPosition()
    local sliderW = 200
    local sliderH = 8
    local sliderX = x + w - sliderW - 60
    local sliderY = y + 10
    local rowH = 50

    -- Label
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.normal)
    love.graphics.print(label, x, y + 3)

    -- Description
    love.graphics.setColor(self.colors.textDim)
    love.graphics.setFont(self.fonts.small)
    love.graphics.print(description, x, y + 22)

    -- Slider track
    love.graphics.setColor(0.25, 0.25, 0.3)
    love.graphics.rectangle("fill", sliderX, sliderY, sliderW, sliderH, 4, 4)

    -- Slider fill
    local normalizedValue = (value - minVal) / (maxVal - minVal)
    local fillW = normalizedValue * sliderW
    love.graphics.setColor(self.colors.accent)
    love.graphics.rectangle("fill", sliderX, sliderY, fillW, sliderH, 4, 4)

    -- Slider handle
    local handleX = sliderX + fillW - 6
    local handleY = sliderY - 4
    local handleW = 12
    local handleH = 16
    local handleHover = mx >= handleX and mx < handleX + handleW and my >= handleY and my < handleY + handleH

    love.graphics.setColor(handleHover and {1, 1, 1} or {0.9, 0.9, 0.9})
    love.graphics.rectangle("fill", handleX, handleY, handleW, handleH, 3, 3)

    -- Value display
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.small)
    local displayValue = isPercent and string.format("%.0f%%", value * 100) or
                         (suffix == " cycles" and string.format("%.0f%s", value, suffix) or
                         string.format("%.2f%s", value, suffix))
    love.graphics.print(displayValue, sliderX + sliderW + 10, y + 8)

    table.insert(self.settingsControls, {
        type = "slider",
        key = key,
        x = sliderX,
        y = sliderY - 4,
        w = sliderW,
        h = sliderH + 8,
        value = value,
        minVal = minVal,
        maxVal = maxVal,
        step = step
    })

    return y + rowH
end

-- Helper: Render dropdown setting
function AlphaUI:RenderSettingsDropdown(x, y, w, key, label, description, value, options)
    local mx, my = love.mouse.getPosition()
    local dropW = 180
    local dropH = 26
    local dropX = x + w - dropW
    local dropY = y + 5
    local rowH = 55

    -- Label
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.normal)
    love.graphics.print(label, x, y + 3)

    -- Description
    love.graphics.setColor(self.colors.textDim)
    love.graphics.setFont(self.fonts.small)
    love.graphics.print(description, x, y + 22)

    -- Find current option label
    local currentLabel = value
    for _, opt in ipairs(options) do
        if opt.value == value then
            currentLabel = opt.label
            break
        end
    end

    -- Dropdown button
    local isHover = mx >= dropX and mx < dropX + dropW and my >= dropY and my < dropY + dropH
    love.graphics.setColor(isHover and {0.35, 0.35, 0.4} or {0.25, 0.25, 0.3})
    love.graphics.rectangle("fill", dropX, dropY, dropW, dropH, 4, 4)
    love.graphics.setColor(0.4, 0.4, 0.45)
    love.graphics.rectangle("line", dropX, dropY, dropW, dropH, 4, 4)

    -- Current value
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.small)
    love.graphics.print(currentLabel, dropX + 10, dropY + 5)

    -- Arrow
    love.graphics.print("▼", dropX + dropW - 20, dropY + 5)

    table.insert(self.settingsControls, {
        type = "dropdown",
        key = key,
        x = dropX,
        y = dropY,
        w = dropW,
        h = dropH,
        value = value,
        options = options
    })

    return y + rowH
end

function AlphaUI:HandleSettingsPanelClick(x, y)
    -- Lazy initialization
    if not self.gameSettings then
        self.gameSettings = GameSettings:GetInstance()
    end

    -- Close button
    if self.settingsCloseBtn then
        local btn = self.settingsCloseBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.showSettingsPanel = false
            return true
        end
    end

    -- Tab buttons
    for _, btn in ipairs(self.settingsTabBtns or {}) do
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.settingsTab = btn.tabId
            self.settingsScrollOffset = 0
            return true
        end
    end

    -- Reset button
    if self.settingsResetBtn then
        local btn = self.settingsResetBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.gameSettings:ResetCategory(self.settingsTab)
            return true
        end
    end

    -- Settings controls
    for _, ctrl in ipairs(self.settingsControls or {}) do
        if x >= ctrl.x and x < ctrl.x + ctrl.w and y >= ctrl.y and y < ctrl.y + ctrl.h then
            if ctrl.type == "checkbox" then
                self:ToggleSettingsCheckbox(ctrl.key)
                return true
            elseif ctrl.type == "slider" then
                -- Calculate new value based on click position
                local relX = x - ctrl.x
                local normalized = math.max(0, math.min(1, relX / ctrl.w))
                local newValue = ctrl.minVal + normalized * (ctrl.maxVal - ctrl.minVal)
                -- Round to step
                newValue = math.floor(newValue / ctrl.step + 0.5) * ctrl.step
                self:SetSettingsValue(ctrl.key, newValue)
                return true
            elseif ctrl.type == "dropdown" then
                self:CycleSettingsDropdown(ctrl.key, ctrl.options, ctrl.value)
                return true
            end
        end
    end

    return true  -- Consume click
end

function AlphaUI:ToggleSettingsCheckbox(key)
    if not self.gameSettings then
        self.gameSettings = GameSettings:GetInstance()
    end
    local category = self:GetSettingsCategory(key)
    local currentValue = self.gameSettings:Get(category, key)
    self.gameSettings:Set(category, key, not currentValue)

    -- Apply immediate effects
    if key == "fullscreen" then
        self.gameSettings:ApplyDisplaySettings()
    elseif key == "vsync" then
        self.gameSettings:ApplyDisplaySettings()
    end
end

function AlphaUI:SetSettingsValue(key, value)
    if not self.gameSettings then
        self.gameSettings = GameSettings:GetInstance()
    end
    local category = self:GetSettingsCategory(key)
    self.gameSettings:Set(category, key, value)

    -- Apply immediate effects
    if key == "fullscreen" or key == "vsync" then
        self.gameSettings:ApplyDisplaySettings()
    end
end

function AlphaUI:CycleSettingsDropdown(key, options, currentValue)
    if not self.gameSettings then
        self.gameSettings = GameSettings:GetInstance()
    end
    -- Find current index and cycle to next
    local currentIndex = 1
    for i, opt in ipairs(options) do
        if opt.value == currentValue then
            currentIndex = i
            break
        end
    end
    local nextIndex = (currentIndex % #options) + 1
    local newValue = options[nextIndex].value

    local category = self:GetSettingsCategory(key)
    self.gameSettings:Set(category, key, newValue)
end

function AlphaUI:GetSettingsCategory(key)
    -- Map key to category
    local categoryMap = {
        -- Gameplay
        autoPauseOnCritical = "gameplay",
        autoPauseOnWarning = "gameplay",
        autoPauseOnInfo = "gameplay",
        tutorialHints = "gameplay",
        notificationFrequency = "gameplay",
        autosaveEnabled = "gameplay",
        autosaveInterval = "gameplay",
        showProductionNumbers = "gameplay",
        showSatisfactionNumbers = "gameplay",
        -- Display
        fullscreen = "display",
        vsync = "display",
        uiScale = "display",
        showCharacterNames = "display",
        showBuildingNames = "display",
        colorBlindMode = "display",
        cameraZoomSpeed = "display",
        cameraPanSpeed = "display",
        -- Audio
        masterVolume = "audio",
        musicVolume = "audio",
        sfxVolume = "audio",
        ambientVolume = "audio",
        notificationSounds = "audio",
        uiSounds = "audio",
        -- Accessibility
        largerText = "accessibility",
        highContrast = "accessibility",
        reducedMotion = "accessibility",
        screenReaderMode = "accessibility"
    }
    return categoryMap[key] or "gameplay"
end

-- =============================================================================
-- EMIGRATION WARNING PANEL
-- =============================================================================

function AlphaUI:GetAtRiskCitizens()
    -- Calculate emigration risk for all citizens and return sorted list
    local atRiskCitizens = {}

    -- Get emigration config
    local config = nil
    if CharacterV3 and CharacterV3._ConsumptionMechanics and
       CharacterV3._ConsumptionMechanics.consequenceThresholds and
       CharacterV3._ConsumptionMechanics.consequenceThresholds.emigration then
        config = CharacterV3._ConsumptionMechanics.consequenceThresholds.emigration
    end

    for _, citizen in ipairs(self.world.citizens) do
        if not citizen.hasEmigrated and citizen.status ~= "leaving" then
            local riskData = self:CalculateEmigrationRisk(citizen, config)
            if riskData.riskPercent > 0 then
                table.insert(atRiskCitizens, {
                    citizen = citizen,
                    riskPercent = riskData.riskPercent,
                    reasons = riskData.reasons,
                    solutions = riskData.solutions,
                    cyclesRemaining = riskData.cyclesRemaining
                })
            end
        end
    end

    -- Sort by risk percent (highest first)
    table.sort(atRiskCitizens, function(a, b)
        return a.riskPercent > b.riskPercent
    end)

    return atRiskCitizens
end

function AlphaUI:CalculateEmigrationRisk(citizen, config)
    local riskData = {
        riskPercent = 0,
        reasons = {},
        solutions = {},
        cyclesRemaining = nil
    }

    if not config or not config.enabled then
        return riskData
    end

    local avgSatisfaction = citizen:GetAverageSatisfaction() or 50
    local satisfactionThreshold = config.averageSatisfactionThreshold[citizen.class] or 30
    local cycleThreshold = config.consecutiveLowSatisfactionCycles[citizen.class] or 5
    local criticalRequired = config.criticalCravingsRequired or 2
    local criticalCount = citizen:GetCriticalCravingCount() or 0
    local lowCycles = citizen.consecutiveLowSatisfactionCycles or 0

    -- Check if below satisfaction threshold
    local isBelowThreshold = avgSatisfaction < satisfactionThreshold

    if not isBelowThreshold then
        return riskData  -- Not at risk
    end

    -- Calculate risk based on progress toward emigration
    local cycleProgress = math.min(lowCycles / cycleThreshold, 1.0)
    local criticalProgress = math.min(criticalCount / criticalRequired, 1.0)

    -- Base risk calculation
    -- Risk increases as they get closer to meeting both conditions
    if lowCycles > 0 or criticalCount > 0 then
        -- Calculate overall risk percentage
        local baseRisk = cycleProgress * 0.5 + criticalProgress * 0.5

        -- If both conditions met, they're at immediate risk (chance-based emigration)
        if lowCycles >= cycleThreshold and criticalCount >= criticalRequired then
            local emigrationChance = config.emigrationChancePerCycle or 0.15
            riskData.riskPercent = math.floor(baseRisk * 100 + emigrationChance * 100)
            riskData.riskPercent = math.min(100, riskData.riskPercent)
            riskData.cyclesRemaining = 0
            table.insert(riskData.reasons, "Immediate emigration risk!")
        else
            riskData.riskPercent = math.floor(baseRisk * 80)  -- Cap at 80% until conditions fully met
            local cyclesLeft = cycleThreshold - lowCycles
            if cyclesLeft > 0 then
                riskData.cyclesRemaining = cyclesLeft
            end
        end

        -- Add reasons
        if avgSatisfaction < satisfactionThreshold then
            table.insert(riskData.reasons, string.format("Low satisfaction: %.0f%% (needs %d%%)",
                avgSatisfaction, satisfactionThreshold))
        end

        if lowCycles > 0 then
            table.insert(riskData.reasons, string.format("Unhappy for %d cycles (threshold: %d)",
                lowCycles, cycleThreshold))
        end

        if criticalCount > 0 then
            table.insert(riskData.reasons, string.format("%d critical craving(s) (threshold: %d)",
                criticalCount, criticalRequired))
        end

        -- Get critical cravings and suggest solutions
        local criticalCravings = citizen.GetCriticalCravings and citizen:GetCriticalCravings() or {}
        for _, craving in ipairs(criticalCravings) do
            local solution = self:GetCravingSolution(craving, citizen)
            if solution then
                table.insert(riskData.solutions, solution)
            end
        end

        -- Generic solution
        if #riskData.solutions == 0 then
            table.insert(riskData.solutions, "Increase commodity production to meet needs")
            table.insert(riskData.solutions, "Prioritize this citizen in allocation")
        end
    end

    return riskData
end

function AlphaUI:GetCravingSolution(craving, citizen)
    -- Map craving types to suggested solutions
    local solutions = {
        -- Physiological needs
        food = "Build more farms or bakeries",
        water = "Build a well or expand water access",
        sleep = "Ensure housing availability",
        -- Safety needs
        shelter = "Build more housing",
        security = "Build a guardhouse or walls",
        -- Social needs
        companionship = "Organize social events",
        family = "Help family members immigrate",
        -- Esteem needs
        recognition = "Promote to better position",
        achievement = "Assign to productive building",
    }

    -- Try to match craving to solution
    if craving and craving.id then
        local cravingLower = string.lower(craving.id)
        for key, solution in pairs(solutions) do
            if string.find(cravingLower, key) then
                return solution
            end
        end
    end

    return nil
end

function AlphaUI:RenderEmigrationPanel()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Panel dimensions
    local panelW = math.min(800, screenW - 80)
    local panelH = math.min(600, screenH - 100)
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Panel background
    love.graphics.setColor(0.12, 0.12, 0.16)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 8, 8)

    -- Panel border (red-tinted for warning)
    love.graphics.setColor(0.7, 0.3, 0.3)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 8, 8)
    love.graphics.setLineWidth(1)

    -- Get at-risk citizens
    local atRiskCitizens = self:GetAtRiskCitizens()

    -- Header
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.danger)
    love.graphics.print("EMIGRATION WARNING", panelX + 20, panelY + 15)

    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print(string.format("%d citizen(s) at risk of leaving", #atRiskCitizens),
        panelX + 200, panelY + 20)

    -- Close button
    local closeBtnX = panelX + panelW - 40
    local closeBtnY = panelY + 15
    local closeBtnSize = 25
    local mx, my = love.mouse.getPosition()
    local closeHover = mx >= closeBtnX and mx < closeBtnX + closeBtnSize and
                       my >= closeBtnY and my < closeBtnY + closeBtnSize

    love.graphics.setColor(closeHover and {0.8, 0.3, 0.3} or {0.5, 0.5, 0.5})
    love.graphics.rectangle("fill", closeBtnX, closeBtnY, closeBtnSize, closeBtnSize, 4, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.normal)
    love.graphics.print("X", closeBtnX + 7, closeBtnY + 3)

    self.emigrationCloseBtn = {x = closeBtnX, y = closeBtnY, w = closeBtnSize, h = closeBtnSize}

    -- Content area
    local contentX = panelX + 15
    local contentY = panelY + 55
    local contentW = panelW - 30
    local contentH = panelH - 70

    -- Scrollable area
    love.graphics.setScissor(contentX, contentY, contentW, contentH)

    self.emigrationCitizenBtns = {}
    self.emigrationPrioritizeBtns = {}

    if #atRiskCitizens == 0 then
        -- No citizens at risk
        love.graphics.setFont(self.fonts.header)
        love.graphics.setColor(self.colors.success)
        local msg = "No citizens at risk of emigrating!"
        local msgW = self.fonts.header:getWidth(msg)
        love.graphics.print(msg, contentX + (contentW - msgW) / 2, contentY + 100)

        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(self.colors.textDim)
        local subMsg = "Your citizens are content with life in " .. (self.world.townName or "town")
        local subMsgW = self.fonts.normal:getWidth(subMsg)
        love.graphics.print(subMsg, contentX + (contentW - subMsgW) / 2, contentY + 135)
    else
        local rowY = contentY - self.emigrationScrollOffset
        local rowH = 120  -- Height per citizen card

        for i, riskData in ipairs(atRiskCitizens) do
            local citizen = riskData.citizen

            if rowY + rowH > contentY - 20 and rowY < contentY + contentH then
                -- Card background
                local cardX = contentX + 5
                local cardW = contentW - 10

                -- Risk-based color
                local bgAlpha = 0.3
                if riskData.riskPercent >= 80 then
                    love.graphics.setColor(0.5, 0.2, 0.2, bgAlpha)
                elseif riskData.riskPercent >= 50 then
                    love.graphics.setColor(0.5, 0.35, 0.2, bgAlpha)
                else
                    love.graphics.setColor(0.4, 0.4, 0.2, bgAlpha)
                end
                love.graphics.rectangle("fill", cardX, rowY, cardW, rowH - 10, 6, 6)

                -- Card border
                love.graphics.setColor(0.4, 0.4, 0.45)
                love.graphics.rectangle("line", cardX, rowY, cardW, rowH - 10, 6, 6)

                -- Citizen name and class
                love.graphics.setFont(self.fonts.normal)
                love.graphics.setColor(1, 1, 1)
                local displayName = citizen.name or "Unknown"
                love.graphics.print(displayName, cardX + 10, rowY + 8)

                love.graphics.setFont(self.fonts.tiny)
                love.graphics.setColor(self:GetClassColor(citizen.class))
                love.graphics.print(string.upper(citizen.class or "unknown"), cardX + 10, rowY + 28)

                -- Risk percentage (large, right side)
                love.graphics.setFont(self.fonts.header)
                local riskColor = riskData.riskPercent >= 80 and self.colors.danger or
                                  (riskData.riskPercent >= 50 and self.colors.warning or {0.8, 0.8, 0.3})
                love.graphics.setColor(riskColor)
                local riskText = string.format("%d%%", riskData.riskPercent)
                local riskTextW = self.fonts.header:getWidth(riskText)
                love.graphics.print(riskText, cardX + cardW - riskTextW - 100, rowY + 10)

                love.graphics.setFont(self.fonts.tiny)
                love.graphics.setColor(self.colors.textDim)
                love.graphics.print("RISK", cardX + cardW - riskTextW - 100, rowY + 35)

                -- Cycles remaining
                if riskData.cyclesRemaining and riskData.cyclesRemaining > 0 then
                    love.graphics.setColor(self.colors.warning)
                    love.graphics.print(string.format("~%d cycles left", riskData.cyclesRemaining),
                        cardX + cardW - riskTextW - 100, rowY + 48)
                elseif riskData.cyclesRemaining == 0 then
                    love.graphics.setColor(self.colors.danger)
                    love.graphics.print("IMMINENT!", cardX + cardW - riskTextW - 100, rowY + 48)
                end

                -- Reasons (left column)
                love.graphics.setFont(self.fonts.tiny)
                love.graphics.setColor(self.colors.textDim)
                love.graphics.print("Reasons:", cardX + 10, rowY + 45)

                local reasonY = rowY + 58
                love.graphics.setColor(self.colors.warning)
                for j, reason in ipairs(riskData.reasons) do
                    if j <= 3 then  -- Limit to 3 reasons
                        love.graphics.print("- " .. reason, cardX + 15, reasonY)
                        reasonY = reasonY + 12
                    end
                end

                -- Solutions (right column, middle)
                local solutionX = cardX + 300
                love.graphics.setColor(self.colors.textDim)
                love.graphics.print("Suggested Actions:", solutionX, rowY + 45)

                local solutionY = rowY + 58
                love.graphics.setColor(self.colors.success)
                for j, solution in ipairs(riskData.solutions) do
                    if j <= 3 then  -- Limit to 3 solutions
                        love.graphics.print("+ " .. solution, solutionX + 5, solutionY)
                        solutionY = solutionY + 12
                    end
                end

                -- Prioritize button
                local btnW = 75
                local btnH = 24
                local btnX = cardX + cardW - btnW - 10
                local btnY = rowY + rowH - btnH - 18
                local btnHover = mx >= btnX and mx < btnX + btnW and my >= btnY and my < btnY + btnH

                love.graphics.setColor(btnHover and {0.3, 0.5, 0.3} or {0.2, 0.35, 0.2})
                love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(self.fonts.tiny)
                local btnText = "Prioritize"
                local btnTextW = self.fonts.tiny:getWidth(btnText)
                love.graphics.print(btnText, btnX + (btnW - btnTextW) / 2, btnY + 6)

                table.insert(self.emigrationPrioritizeBtns, {
                    x = btnX, y = btnY, w = btnW, h = btnH,
                    citizenId = citizen.id
                })

                -- Store clickable area for citizen card
                table.insert(self.emigrationCitizenBtns, {
                    x = cardX, y = rowY, w = cardW, h = rowH - 10,
                    citizen = citizen
                })
            end

            rowY = rowY + rowH
        end

        -- Calculate max scroll
        local totalHeight = #atRiskCitizens * rowH
        self.emigrationMaxScroll = math.max(0, totalHeight - contentH)
    end

    love.graphics.setScissor()

    -- Summary bar at bottom
    local summaryY = panelY + panelH - 35
    love.graphics.setColor(0.15, 0.15, 0.18)
    love.graphics.rectangle("fill", panelX + 10, summaryY - 5, panelW - 20, 30, 4, 4)

    love.graphics.setFont(self.fonts.small)
    if #atRiskCitizens > 0 then
        local highRisk = 0
        local medRisk = 0
        local lowRisk = 0
        for _, rd in ipairs(atRiskCitizens) do
            if rd.riskPercent >= 80 then highRisk = highRisk + 1
            elseif rd.riskPercent >= 50 then medRisk = medRisk + 1
            else lowRisk = lowRisk + 1
            end
        end

        love.graphics.setColor(self.colors.danger)
        love.graphics.print(string.format("Critical: %d", highRisk), panelX + 20, summaryY)

        love.graphics.setColor(self.colors.warning)
        love.graphics.print(string.format("Warning: %d", medRisk), panelX + 120, summaryY)

        love.graphics.setColor({0.8, 0.8, 0.3})
        love.graphics.print(string.format("Watch: %d", lowRisk), panelX + 220, summaryY)
    else
        love.graphics.setColor(self.colors.success)
        love.graphics.print("All citizens stable", panelX + 20, summaryY)
    end

    -- Keyboard hint
    love.graphics.setColor(self.colors.textDim)
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.print("Press E or ESC to close", panelX + panelW - 140, summaryY + 2)
end

function AlphaUI:HandleEmigrationPanelClick(x, y)
    -- Close button
    if self.emigrationCloseBtn then
        local btn = self.emigrationCloseBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.showEmigrationPanel = false
            return true
        end
    end

    -- Prioritize buttons
    for _, btn in ipairs(self.emigrationPrioritizeBtns or {}) do
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            -- Prioritize this citizen in allocation
            self:PrioritizeCitizen(btn.citizenId)
            return true
        end
    end

    -- Citizen cards (click to select/view)
    for _, btn in ipairs(self.emigrationCitizenBtns or {}) do
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            -- Select citizen and close panel
            self.world:SelectCitizen(btn.citizen)
            self.showEmigrationPanel = false
            return true
        end
    end

    return true  -- Consume click to prevent clicking through panel
end

function AlphaUI:PrioritizeCitizen(citizenId)
    -- Find citizen and boost their allocation priority
    for _, citizen in ipairs(self.world.citizens) do
        if citizen.id == citizenId then
            -- Boost fairness penalty to give them priority in next allocation
            citizen.fairnessPenalty = (citizen.fairnessPenalty or 0) + 200

            -- Log the action
            if self.world.LogEvent then
                self.world:LogEvent({
                    type = "action",
                    message = string.format("Prioritized %s for resource allocation", citizen.name),
                    cycle = self.world.currentCycle
                })
            end

            break
        end
    end
end

-- =============================================================================
-- TEXT INPUT HANDLING
-- =============================================================================

function AlphaUI:HandleTextInput(text)
    -- Handle cheat console input (highest priority when open)
    if self.showCheatConsole then
        -- Skip backtick to avoid adding it to input
        if text ~= "`" and text ~= "~" then
            -- Only allow printable characters
            if text:match("^[%w%s%p]$") then
                self.cheatConsoleInput = self.cheatConsoleInput .. text
            end
        end
        return true
    end

    -- Handle build menu search input
    if self.showBuildMenuModal and self.buildMenuSearchActive then
        -- Only allow printable characters (no control chars)
        if text:match("^[%w%s%p]$") then
            self.buildMenuSearchQuery = self.buildMenuSearchQuery .. text
            self.buildMenuScrollOffset = 0
            return true
        end
    end
    return false
end

-- =============================================================================
-- PLOT SELECTION MODAL (for land purchase during immigration)
-- =============================================================================

function AlphaUI:OpenPlotSelectionModal(applicant)
    -- Store the applicant for after plot selection
    self.pendingImmigrantApplicant = applicant

    -- Create the modal with callbacks
    self.plotSelectionModal = PlotSelectionModal:Create(
        self.world,
        applicant,
        function(selectedPlots, totalCost)
            -- On confirm: accept immigrant with selected plots
            self:OnPlotSelectionComplete(selectedPlots, totalCost)
        end,
        function()
            -- On cancel: close modal, return to immigration
            self:OnPlotSelectionCancel()
        end
    )

    self.showPlotSelectionModal = true
end

function AlphaUI:OnPlotSelectionComplete(selectedPlots, totalCost)
    local applicant = self.pendingImmigrantApplicant
    if not applicant then
        print("[AlphaUI] Error: No pending applicant for plot selection")
        self:ClosePlotSelectionModal()
        return
    end

    local immigrationSystem = self.world.immigrationSystem
    if not immigrationSystem then
        print("[AlphaUI] Error: No immigration system")
        self:ClosePlotSelectionModal()
        return
    end

    -- Accept the applicant with the selected plots
    -- On success: returns true, citizen, nil
    -- On failure: returns false, "error message"
    local success, citizenOrErr, _ = immigrationSystem:AcceptApplicant(applicant, selectedPlots)

    if success then
        local citizen = citizenOrErr  -- On success, second value is the citizen
        self.world:LogEvent("immigration", applicant.name .. " immigrated and purchased " .. #selectedPlots .. " plots for " .. totalCost .. " gold", {})
        self.selectedApplicant = nil

        -- For elite/wealthy immigrants, show suggested buildings modal if they have remaining plots
        local intendedRole = applicant.intendedRole or "laborer"
        local minPlotsRequired = (applicant.landRequirements and applicant.landRequirements.minPlots) or 1

        -- Elite/wealthy immigrants typically buy more plots than needed for residence
        -- Show suggested buildings if they have remaining plots (beyond what residence needs)
        if (intendedRole == "elite" or intendedRole == "wealthy" or intendedRole == "merchant") and
           #selectedPlots > minPlotsRequired and citizen then
            -- Calculate remaining plots (plots beyond the residence)
            local remainingPlots = {}
            for i = 2, #selectedPlots do  -- Skip first plot (residence)
                table.insert(remainingPlots, selectedPlots[i])
            end

            if #remainingPlots > 0 then
                self:ClosePlotSelectionModal()
                self:OpenSuggestedBuildingsModal(citizen, remainingPlots)
                return  -- Don't close plot selection modal twice
            end
        end
    else
        local err = citizenOrErr  -- On failure, second value is the error message
        print("[AlphaUI] Failed to accept immigrant: " .. (err or "unknown error"))
        self.world:LogEvent("warning", "Immigration failed for " .. applicant.name .. ": " .. (err or "unknown"), {})
    end

    self:ClosePlotSelectionModal()
end

function AlphaUI:OnPlotSelectionCancel()
    self.world:LogEvent("info", "Land purchase cancelled for " .. (self.pendingImmigrantApplicant and self.pendingImmigrantApplicant.name or "applicant"), {})
    self:ClosePlotSelectionModal()
end

function AlphaUI:ClosePlotSelectionModal()
    self.showPlotSelectionModal = false
    self.plotSelectionModal = nil
    self.pendingImmigrantApplicant = nil
end

-- =============================================================================
-- SUGGESTED BUILDINGS MODAL (for elite immigrants after land purchase)
-- =============================================================================

function AlphaUI:OpenSuggestedBuildingsModal(citizen, remainingPlots)
    self.suggestedBuildingsCitizen = citizen
    self.suggestedBuildingsPlots = remainingPlots or {}  -- Store plots for placement restriction

    self.suggestedBuildingsModal = SuggestedBuildingsModal:Create(
        self.world,
        citizen,
        remainingPlots,
        function(action, buildingTypeId)
            self:OnSuggestedBuildingsClose(action, buildingTypeId)
        end
    )

    self.showSuggestedBuildingsModal = true
    print("[AlphaUI] Opened suggested buildings modal for " .. (citizen.name or "citizen"))
end

function AlphaUI:OnSuggestedBuildingsClose(action, buildingTypeId)
    print("[AlphaUI] OnSuggestedBuildingsClose called with action=" .. tostring(action) .. ", buildingTypeId=" .. tostring(buildingTypeId))

    if action == "build" and buildingTypeId then
        -- Look up the building type object from the ID
        local buildingType = self.world.buildingTypesById[buildingTypeId]
        if buildingType then
            -- Store plots and citizen before closing modal
            local restrictedPlots = self.suggestedBuildingsPlots
            local ownerCitizen = self.suggestedBuildingsCitizen

            print("[AlphaUI] restrictedPlots count: " .. (restrictedPlots and #restrictedPlots or 0))
            print("[AlphaUI] ownerCitizen: " .. (ownerCitizen and ownerCitizen.name or "nil"))

            -- Close ALL related modals first
            self:CloseSuggestedBuildingsModal()
            self.showImmigrationModal = false  -- Close immigration modal too
            print("[AlphaUI] Modals closed, showSuggestedBuildingsModal=" .. tostring(self.showSuggestedBuildingsModal) .. ", showImmigrationModal=" .. tostring(self.showImmigrationModal))

            -- Enter building placement mode with plot restriction
            self:EnterPlacementMode(buildingType, restrictedPlots, ownerCitizen)
            self.world:LogEvent("info", "Starting placement for " .. (buildingType.name or buildingTypeId), {})
        else
            print("[AlphaUI] Unknown building type: " .. tostring(buildingTypeId))
            self:CloseSuggestedBuildingsModal()
        end
    elseif action == "view_land" then
        -- Close modal and enable land overlay
        self:CloseSuggestedBuildingsModal()
        self.showLandOverlay = true
    else
        -- Skip - just close the modal
        self:CloseSuggestedBuildingsModal()
    end
end

function AlphaUI:CloseSuggestedBuildingsModal()
    print("[AlphaUI] CloseSuggestedBuildingsModal called")
    self.showSuggestedBuildingsModal = false
    self.suggestedBuildingsModal = nil
    self.suggestedBuildingsCitizen = nil
    self.suggestedBuildingsPlots = nil
end

-- =============================================================================
-- CAMERA ADAPTER METHODS (for modules expecting camera:GetPosition/GetScale)
-- =============================================================================

function AlphaUI:GetPosition()
    return self.cameraX, self.cameraY
end

function AlphaUI:GetScale()
    return self.cameraZoom
end

-- =============================================================================
-- NEW PANEL HELPER METHODS
-- =============================================================================

function AlphaUI:OpenLandRegistryPanel()
    self.showLandRegistryPanel = true
    if self.landRegistryPanel then
        self.landRegistryPanel:Show()
    end
end

function AlphaUI:CloseLandRegistryPanel()
    self.showLandRegistryPanel = false
    if self.landRegistryPanel then
        self.landRegistryPanel:Hide()
    end
end

function AlphaUI:OpenHousingOverviewPanel()
    self.showHousingOverviewPanel = true
    if self.housingOverviewPanel then
        self.housingOverviewPanel:Show()
    end
end

function AlphaUI:CloseHousingOverviewPanel()
    self.showHousingOverviewPanel = false
    if self.housingOverviewPanel then
        self.housingOverviewPanel:Hide()
    end
end

function AlphaUI:OpenHousingAssignmentModal(building)
    self.showHousingAssignmentModal = true
    if self.housingAssignmentModal then
        self.housingAssignmentModal:Show(building)
    end
end

function AlphaUI:CloseHousingAssignmentModal()
    self.showHousingAssignmentModal = false
    if self.housingAssignmentModal then
        self.housingAssignmentModal:Hide()
    end
end

function AlphaUI:OpenCharacterDetailPanel(character)
    if self.characterDetailPanel then
        self.characterDetailPanel:Show(character)
    end
end

function AlphaUI:CloseCharacterDetailPanel()
    if self.characterDetailPanel then
        self.characterDetailPanel:Hide()
    end
end

return AlphaUI
