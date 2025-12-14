--
-- AlphaPrototypeState - Alpha prototype experience
-- Birthday edition for Mansi - starts with splash, then title screen, then game
--

local BirthdaySplash = require("code/BirthdaySplash")
local TitleScreen = require("code/TitleScreen")
local NewGameSetup = require("code/NewGameSetup")
local AlphaWorld = require("code/AlphaWorld")
local AlphaUI = require("code/AlphaUI")
local DataLoader = require("code/DataLoader")
local LoadingScreen = require("code/LoadingScreen")

AlphaPrototypeState = {}
AlphaPrototypeState.__index = AlphaPrototypeState

function AlphaPrototypeState:Create()
    local this = {
        mPhase = "splash",  -- splash, title, setup, worldloading, game
        mSplash = nil,
        mTitleScreen = nil,
        mNewGameSetup = nil,
        mWorld = nil,
        mUI = nil,
        mGameConfig = nil,  -- Configuration from new game setup
        mLoadingScreen = nil,  -- Loading screen during world generation
        mLoadingCoroutine = nil  -- Coroutine for async loading
    }

    setmetatable(this, self)
    return this
end

function AlphaPrototypeState:Enter()
    -- Skip birthday splash for now, go directly to title screen
    self:OnSplashComplete()
end

function AlphaPrototypeState:OnSplashComplete()
    print("Birthday splash complete - showing title screen...")
    self.mPhase = "title"
    self.mSplash = nil

    -- Create title screen with callbacks
    self.mTitleScreen = TitleScreen:Create({
        new_game = function() self:OnNewGame() end,
        continue = function() self:OnContinue() end,
        load_game = function() self:OnLoadGame() end,
        settings = function() self:OnSettings() end,
        credits = function() self:OnCredits() end,
        quit = function() self:OnQuit() end
    })
end

function AlphaPrototypeState:OnNewGame()
    print("Starting new game setup...")
    self.mPhase = "setup"

    -- Create new game setup wizard
    self.mNewGameSetup = NewGameSetup:Create(
        function(config) self:OnSetupComplete(config) end,
        function() self:OnSetupCancel() end
    )
end

function AlphaPrototypeState:OnSetupComplete(config)
    print("New game setup complete - starting game...")
    self.mGameConfig = config
    self.mNewGameSetup = nil
    self:StartGame()
end

function AlphaPrototypeState:OnSetupCancel()
    print("Setup cancelled - returning to title screen...")
    self.mPhase = "title"
    self.mNewGameSetup = nil
end

function AlphaPrototypeState:OnContinue()
    -- Load quicksave and start game
    print("Continue - loading quicksave...")
    local saveData = self:LoadSaveFile("quicksave.json")
    if saveData then
        self:StartGameFromSave(saveData)
    else
        print("No quicksave found!")
    end
end

function AlphaPrototypeState:OnLoadGame()
    -- Show load game modal in dedicated phase
    print("Showing load game modal...")
    self.mPhase = "loading"

    -- Create a temporary world (needed for the save/load modal)
    local tempWorld = {
        townName = "Loading...",
        citizens = {},
        buildings = {},
        inventory = {},
        gold = 0,
        LogEvent = function() end
    }

    -- Create save/load modal
    local SaveLoadModal = require("code.SaveLoadModal")
    self.mLoadModal = SaveLoadModal:Create(tempWorld, function()
        -- On close, return to title screen
        self.mPhase = "title"
        self.mLoadModal = nil
    end)
    self.mLoadModal:SetMode("load")

    -- Set up load callback
    self.mLoadModal.onLoad = function(saveData)
        self:StartGameFromSave(saveData)
        self.mLoadModal = nil
    end
end

function AlphaPrototypeState:OnSettings()
    -- TODO: Show settings panel
    print("Settings - not yet implemented")
end

function AlphaPrototypeState:OnCredits()
    -- TODO: Show credits screen
    print("Credits - not yet implemented")
end

function AlphaPrototypeState:OnQuit()
    -- Return to launcher
    ReturnToLauncher()
end

function AlphaPrototypeState:StartGame()
    -- Switch to loading phase
    self.mPhase = "worldloading"
    self.mTitleScreen = nil

    -- Create and show loading screen
    self.mLoadingScreen = LoadingScreen:Create()
    self.mLoadingScreen:Show()

    -- Create coroutine for async loading
    self.mLoadingCoroutine = coroutine.create(function()
        self:LoadWorldAsync()
    end)
end

-- Async world loading with progress updates
function AlphaPrototypeState:LoadWorldAsync()
    local yield = coroutine.yield

    -- Step 1: Load configuration (5%)
    self.mLoadingScreen:SetProgress(0.05, "Loading configuration...")
    yield()

    local locationId = self.mGameConfig and self.mGameConfig.location or "fertile_plains"
    local startingLocation = DataLoader.getStartingLocationById(locationId)
    self.mStartingLocation = startingLocation

    local terrainConfig = nil
    if startingLocation and startingLocation.terrain then
        terrainConfig = startingLocation.terrain
    end

    -- Step 2: Create world zones (15%)
    self.mLoadingScreen:SetProgress(0.15, "Generating world zones...")
    yield()

    -- Step 3: Initialize world (25%)
    self.mLoadingScreen:SetProgress(0.25, "Creating world...", "Initializing terrain")
    yield()

    self.mWorld = AlphaWorld:Create(terrainConfig, function(progress, message)
        -- Callback from AlphaWorld for progress updates (25% - 60%)
        local scaledProgress = 0.25 + progress * 0.35
        self.mLoadingScreen:SetProgress(scaledProgress, "Creating world...", message)
    end)

    -- Step 4: Apply configuration (65%)
    self.mLoadingScreen:SetProgress(0.65, "Applying configuration...")
    yield()

    if self.mGameConfig then
        self.mWorld.townName = self.mGameConfig.townName or "Prosperityville"
        self.mWorld.gameConfig = self.mGameConfig
    end

    if startingLocation and startingLocation.productionModifiers then
        self.mWorld.productionModifiers = startingLocation.productionModifiers
    end

    -- Step 5: Initialize UI (70%)
    self.mLoadingScreen:SetProgress(0.70, "Initializing interface...")
    yield()

    self.mUI = AlphaUI:Create(self.mWorld)
    self.mUI.onLoadGame = function(saveData)
        self:StartGameFromSave(saveData)
    end

    -- Apply tutorial mode from game config
    if self.mUI.tutorialSystem then
        local tutorialMode = self.mGameConfig and self.mGameConfig.tutorialMode or "full"
        if tutorialMode == "none" then
            self.mUI.tutorialSystem:SetEnabled(false)
        elseif tutorialMode == "hints" then
            -- Hints-only mode: skip the step-by-step but keep enabled for hints
            self.mUI.tutorialSystem:Skip()
        end
        -- "full" mode is the default (already enabled)
    end

    -- Step 6: Setup starter content (75% - 95%)
    self.mLoadingScreen:SetProgress(0.75, "Setting up starter content...")
    yield()

    self:SetupStarterContentAsync()

    -- Step 7: Finalize (100%)
    self.mLoadingScreen:SetProgress(1.0, "Ready!")
    yield()

    -- Start paused so player can observe
    self.mWorld.isPaused = true

    -- Small delay to show 100%
    self.mLoadingComplete = true
end

-- Async version of SetupStarterContent with progress updates
function AlphaPrototypeState:SetupStarterContentAsync()
    -- Use starting location if available, otherwise fall back to alpha_starter_config
    local config
    if self.mStartingLocation then
        config = {
            starterBuildings = self.mStartingLocation.starterBuildings or {},
            starterResources = self.mStartingLocation.starterResources or {},
            starterGold = self.mStartingLocation.starterGold or 1000,
            population = self.mStartingLocation.population or nil,
            starterCitizens = self.mStartingLocation.starterCitizens or nil,
            starterLandPlots = self.mStartingLocation.starterLandPlots or {}
        }
        print("[SetupStarterContent] Using starting location: " .. (self.mStartingLocation.id or "unknown"))
    else
        config = DataLoader.loadAlphaStarterConfig()
        if not config then
            config = {
                starterBuildings = {},
                starterResources = {},
                starterGold = 1000
            }
        end
        print("[SetupStarterContent] Using fallback alpha_starter_config")
    end

    -- Apply difficulty modifiers
    if self.mGameConfig then
        if self.mGameConfig.difficulty == "relaxed" then
            config.starterGold = (config.starterGold or 1000) * 2
            for _, res in ipairs(config.starterResources or {}) do
                res.quantity = math.floor(res.quantity * 1.5)
            end
        elseif self.mGameConfig.difficulty == "challenging" then
            config.starterGold = math.floor((config.starterGold or 1000) * 0.5)
        elseif self.mGameConfig.difficulty == "survival" then
            config.starterGold = math.floor((config.starterGold or 1000) * 0.25)
            config.starterResources = {}
        end
    end

    -- Track created buildings
    local buildingsByIndex = {}
    local usedPositions = {}
    local buildingArea = self.mWorld.worldZones and self.mWorld.worldZones:GetBuildingArea()

    -- Add starter buildings
    local starterBuildings = config.starterBuildings or {}
    local totalBuildings = #starterBuildings

    for buildingIndex, buildingConfig in ipairs(starterBuildings) do
        -- Update progress (75% to 85%)
        local buildingProgress = 0.75 + (buildingIndex / totalBuildings) * 0.10
        self.mLoadingScreen:SetProgress(buildingProgress, "Placing buildings...",
            string.format("Building %d of %d: %s", buildingIndex, totalBuildings, buildingConfig.typeId or "unknown"))

        local x, y = buildingConfig.x, buildingConfig.y

        local function isValidPosition(px, py)
            if buildingArea then
                if px < buildingArea.x or py < buildingArea.y or
                   px + 60 > buildingArea.x + buildingArea.width or
                   py + 60 > buildingArea.y + buildingArea.height then
                    return false
                end
            end
            if self.mWorld:IsBuildingInWater(px, py, 60, 60) then return false end
            if self.mWorld.forest and self.mWorld.forest:CheckRectCollision(px, py, 60, 60) then return false end
            if self.mWorld.mountains and self.mWorld.mountains:CheckRectCollision(px, py, 60, 60) then return false end
            for _, pos in ipairs(usedPositions) do
                if math.abs(px - pos.x) < 70 and math.abs(py - pos.y) < 70 then return false end
            end
            for _, building in ipairs(self.mWorld.buildings) do
                if px < building.x + 70 and px + 60 > building.x and
                   py < building.y + 70 and py + 60 > building.y then
                    return false
                end
            end
            return true
        end

        if not isValidPosition(x, y) then
            local found = false
            local searchMinX, searchMaxX, searchMinY, searchMaxY
            if buildingArea then
                searchMinX = buildingArea.x + 10
                searchMaxX = buildingArea.x + buildingArea.width - 70
                searchMinY = buildingArea.y + 10
                searchMaxY = buildingArea.y + buildingArea.height - 70
            else
                searchMinX, searchMaxX, searchMinY, searchMaxY = 100, 1200, 100, 1200
            end

            for tryX = searchMinX, searchMaxX, 70 do
                for tryY = searchMinY, searchMaxY, 70 do
                    if isValidPosition(tryX, tryY) then
                        x, y = tryX, tryY
                        found = true
                        break
                    end
                end
                if found then break end
            end
        end

        table.insert(usedPositions, {x = x, y = y})

        local building = self.mWorld:AddBuilding(buildingConfig.typeId, x, y)
        if building then
            buildingsByIndex[buildingIndex - 1] = building
            if buildingConfig.autoAssignRecipe then
                for _, recipe in ipairs(self.mWorld.buildingRecipes) do
                    if recipe.buildingType == buildingConfig.typeId then
                        self.mWorld:AssignRecipeToStation(building, 1, recipe.id)
                        break
                    end
                end
            end
        end
    end

    -- Spawn citizens
    local citizensByIndex = {}
    local starterCitizens = config.starterCitizens or {}
    local totalCitizens = #starterCitizens

    if totalCitizens > 0 then
        self.mLoadingScreen:SetProgress(0.85, "Spawning citizens...",
            string.format("0 of %d citizens", totalCitizens))

        for citizenIndex, citizenConfig in ipairs(starterCitizens) do
            local citizenProgress = 0.85 + (citizenIndex / totalCitizens) * 0.08
            self.mLoadingScreen:SetProgress(citizenProgress, "Spawning citizens...",
                string.format("Citizen %d of %d: %s", citizenIndex, totalCitizens, citizenConfig.name or "Unknown"))

            local classId = "middle"
            if citizenConfig.intendedRole == "wealthy" then classId = "upper"
            elseif citizenConfig.intendedRole == "merchant" then classId = "middle"
            elseif citizenConfig.intendedRole == "craftsman" then classId = "middle"
            elseif citizenConfig.intendedRole == "laborer" then classId = "lower"
            end

            local citizen = self.mWorld:AddCitizen(classId, citizenConfig.name, nil, {
                startingWealth = citizenConfig.startingWealth or 0,
                vocation = citizenConfig.vocation
            })

            if citizen then
                citizensByIndex[citizenIndex - 1] = citizen
            end
        end
    elseif config.population then
        -- Fallback to population config
        local totalPop = (config.population.middle or 0) + (config.population.lower or 0) + (config.population.upper or 0)
        local spawned = 0
        for classId, count in pairs(config.population) do
            for i = 1, count do
                spawned = spawned + 1
                local progress = 0.85 + (spawned / totalPop) * 0.08
                self.mLoadingScreen:SetProgress(progress, "Spawning citizens...",
                    string.format("Citizen %d of %d", spawned, totalPop))
                self.mWorld:AddCitizen(classId)
            end
        end
    end

    -- Assign land plots
    self.mLoadingScreen:SetProgress(0.93, "Assigning land plots...")
    for _, plotConfig in ipairs(config.starterLandPlots or {}) do
        local plotId = plotConfig.plotId
        local ownerCitizen = citizensByIndex[plotConfig.ownerCitizenIndex]
        if plotId and ownerCitizen then
            self.mWorld.landSystem:TransferOwnership(plotId, ownerCitizen.id, 0, 1)
        end
    end

    -- Assign building ownership
    self.mLoadingScreen:SetProgress(0.95, "Assigning building ownership...")
    for buildingIndex, buildingConfig in ipairs(starterBuildings) do
        if buildingConfig.ownerCitizenIndex ~= nil then
            local building = buildingsByIndex[buildingIndex - 1]
            local ownerCitizen = citizensByIndex[buildingConfig.ownerCitizenIndex]
            if building and ownerCitizen and self.mWorld.ownershipManager then
                self.mWorld.ownershipManager:TransferBuilding(building.id, ownerCitizen.id, 0, 1)
            end
        end
    end

    -- Assign housing (supports both initialOccupants on buildings and housingBuildingIndex on citizens)
    self.mLoadingScreen:SetProgress(0.96, "Assigning housing...")

    -- First: process initialOccupants from buildings
    for buildingIndex, buildingConfig in ipairs(starterBuildings) do
        local building = buildingsByIndex[buildingIndex - 1]
        if building and self.mWorld.housingSystem then
            -- Support both 'assignedCitizens' and 'initialOccupants' field names
            local occupants = buildingConfig.assignedCitizens or buildingConfig.initialOccupants
            if occupants then
                for _, citizenIdx in ipairs(occupants) do
                    local citizen = citizensByIndex[citizenIdx]
                    if citizen then
                        self.mWorld.housingSystem:AssignHousing(citizen.id, building.id)
                    end
                end
            end
        end
    end

    -- Second: process housingBuildingIndex from citizen configs (if not already assigned)
    for citizenIndex, citizenConfig in ipairs(starterCitizens) do
        if citizenConfig.housingBuildingIndex ~= nil then
            local citizen = citizensByIndex[citizenIndex - 1]
            local housingBuilding = buildingsByIndex[citizenConfig.housingBuildingIndex]
            if citizen and housingBuilding and self.mWorld.housingSystem then
                -- Check if citizen is not already assigned
                local currentAssignment = self.mWorld.housingSystem:GetHousingAssignment(citizen.id)
                if not currentAssignment or not currentAssignment.buildingId then
                    self.mWorld.housingSystem:AssignHousing(citizen.id, housingBuilding.id)
                end
            end
        end
    end

    -- Assign workplaces from workplaceIndex
    self.mLoadingScreen:SetProgress(0.97, "Assigning workplaces...")
    for citizenIndex, citizenConfig in ipairs(starterCitizens) do
        if citizenConfig.workplaceIndex ~= nil then
            local citizen = citizensByIndex[citizenIndex - 1]
            local workplace = buildingsByIndex[citizenConfig.workplaceIndex]
            if citizen and workplace then
                self.mWorld:AssignWorkerToBuilding(citizen, workplace)
            end
        end
    end

    -- Add starter resources
    self.mLoadingScreen:SetProgress(0.98, "Adding starter resources...")
    for _, resource in ipairs(config.starterResources or {}) do
        self.mWorld:AddToInventory(resource.commodityId, resource.quantity)
    end

    if config.starterGold then
        self.mWorld.gold = config.starterGold
    end

    -- Finalize
    self.mLoadingScreen:SetProgress(0.99, "Finalizing...")
    self.mWorld:UpdateStats()
    self.mWorld:RunFreeAgency()

    local townName = self.mWorld.townName or "CraveTown"
    self.mWorld:LogEvent("info", "Welcome to " .. townName .. "! Press SPACE to start.", {})
    self.mWorld:LogEvent("info", "Use 1/2/3 to change game speed, H for help.", {})
end

function AlphaPrototypeState:StartGameFromSave(saveData)
    self.mPhase = "game"
    self.mTitleScreen = nil

    -- Initialize world from save data
    self.mWorld = AlphaWorld:Create()
    self.mWorld:LoadFromSaveData(saveData)

    -- Initialize UI
    self.mUI = AlphaUI:Create(self.mWorld)

    -- Set up load callback for in-game save/load
    self.mUI.onLoadGame = function(data)
        self:StartGameFromSave(data)
    end

    -- Start paused
    self.mWorld.isPaused = true
end

function AlphaPrototypeState:LoadSaveFile(filename)
    local content = love.filesystem.read(filename)
    if content then
        local ok, data = pcall(function()
            return require("code.json").decode(content)
        end)
        if ok and data then
            return data
        end
    end
    return nil
end

function AlphaPrototypeState:Update(dt)
    if self.mPhase == "splash" then
        if self.mSplash then
            local done = self.mSplash:Update(dt)
            if done then
                self:OnSplashComplete()
            end
        end
    elseif self.mPhase == "title" then
        if self.mTitleScreen then
            self.mTitleScreen:Update(dt)
        end
    elseif self.mPhase == "setup" then
        if self.mNewGameSetup then
            self.mNewGameSetup:Update(dt)
        end
    elseif self.mPhase == "loading" then
        if self.mLoadModal then
            self.mLoadModal:Update(dt)
        end
    elseif self.mPhase == "worldloading" then
        -- Update loading screen animation
        if self.mLoadingScreen then
            self.mLoadingScreen:Update(dt)
        end

        -- Resume coroutine if still running
        if self.mLoadingCoroutine and coroutine.status(self.mLoadingCoroutine) ~= "dead" then
            local ok, err = coroutine.resume(self.mLoadingCoroutine)
            if not ok then
                print("[LoadingError] " .. tostring(err))
                -- On error, jump to game phase anyway
                self.mPhase = "game"
            end
        elseif self.mLoadingComplete then
            -- Loading finished, wait a moment then transition to game
            self.mLoadingCompleteTimer = (self.mLoadingCompleteTimer or 0) + dt
            if self.mLoadingCompleteTimer > 0.5 then
                self.mPhase = "game"
                self.mLoadingScreen = nil
                self.mLoadingCoroutine = nil
                self.mLoadingComplete = nil
                self.mLoadingCompleteTimer = nil
            end
        end
    elseif self.mPhase == "game" then
        if self.mWorld then
            self.mWorld:Update(dt)
        end
        if self.mUI then
            self.mUI:Update(dt)
        end
    end
end

function AlphaPrototypeState:Render()
    if self.mPhase == "splash" then
        if self.mSplash then
            self.mSplash:Render()
        end
    elseif self.mPhase == "title" then
        if self.mTitleScreen then
            self.mTitleScreen:Render()
        end
    elseif self.mPhase == "setup" then
        -- Render title screen dimmed behind setup
        if self.mTitleScreen then
            self.mTitleScreen:Render()
        end
        if self.mNewGameSetup then
            self.mNewGameSetup:Render()
        end
    elseif self.mPhase == "loading" then
        -- Render title screen dimmed behind load modal
        if self.mTitleScreen then
            self.mTitleScreen:Render()
        end
        if self.mLoadModal then
            self.mLoadModal:Render()
        end
    elseif self.mPhase == "worldloading" then
        -- Render loading screen
        if self.mLoadingScreen then
            self.mLoadingScreen:Render()
        end
    elseif self.mPhase == "game" then
        if self.mUI then
            self.mUI:Render()
        end
    end
end

function AlphaPrototypeState:keypressed(key)
    if self.mPhase == "splash" then
        if self.mSplash and self.mSplash.keypressed then
            return self.mSplash:keypressed(key)
        end
    elseif self.mPhase == "title" then
        if self.mTitleScreen then
            return self.mTitleScreen:HandleKeyPress(key)
        end
    elseif self.mPhase == "setup" then
        if self.mNewGameSetup then
            return self.mNewGameSetup:HandleKeyPress(key)
        end
    elseif self.mPhase == "loading" then
        if self.mLoadModal then
            return self.mLoadModal:HandleKeyPress(key)
        end
    elseif self.mPhase == "game" then
        if self.mUI then
            return self.mUI:HandleKeyPress(key)
        end
    end
    return false
end

function AlphaPrototypeState:textinput(text)
    if self.mPhase == "setup" then
        if self.mNewGameSetup then
            return self.mNewGameSetup:TextInput(text)
        end
    elseif self.mPhase == "game" then
        if self.mUI then
            return self.mUI:HandleTextInput(text)
        end
    end
    return false
end

function AlphaPrototypeState:mousepressed(x, y, button)
    if self.mPhase == "title" then
        if self.mTitleScreen then
            return self.mTitleScreen:HandleClick(x, y, button)
        end
    elseif self.mPhase == "setup" then
        if self.mNewGameSetup then
            return self.mNewGameSetup:HandleClick(x, y, button)
        end
    elseif self.mPhase == "loading" then
        if self.mLoadModal then
            return self.mLoadModal:HandleClick(x, y, button)
        end
    elseif self.mPhase == "game" then
        if self.mUI then
            return self.mUI:HandleClick(x, y, button)
        end
    end
    return false
end

function AlphaPrototypeState:wheelmoved(x, y)
    if self.mPhase == "game" then
        if self.mUI then
            return self.mUI:HandleMouseWheel(x, y)
        end
    end
    return false
end

function AlphaPrototypeState:mousemoved(x, y, dx, dy)
    if self.mPhase == "title" then
        if self.mTitleScreen then
            self.mTitleScreen:UpdateHover(x, y)
        end
    elseif self.mPhase == "setup" then
        if self.mNewGameSetup then
            self.mNewGameSetup:HandleMouseMove(x, y)
        end
    elseif self.mPhase == "loading" then
        if self.mLoadModal then
            self.mLoadModal:HandleMouseMove(x, y)
        end
    elseif self.mPhase == "game" then
        if self.mUI then
            return self.mUI:HandleMouseMove(x, y)
        end
    end
    return false
end

return AlphaPrototypeState
