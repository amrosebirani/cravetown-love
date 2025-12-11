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

AlphaPrototypeState = {}
AlphaPrototypeState.__index = AlphaPrototypeState

function AlphaPrototypeState:Create()
    local this = {
        mPhase = "splash",  -- splash, title, setup, game
        mSplash = nil,
        mTitleScreen = nil,
        mNewGameSetup = nil,
        mWorld = nil,
        mUI = nil,
        mGameConfig = nil  -- Configuration from new game setup
    }

    setmetatable(this, self)
    return this
end

function AlphaPrototypeState:Enter()
    -- Create the birthday splash with callback
    self.mSplash = BirthdaySplash:Create(function()
        self:OnSplashComplete()
    end)
    self.mPhase = "splash"
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
    self.mPhase = "game"
    self.mTitleScreen = nil

    -- Load starting location based on game config
    local locationId = self.mGameConfig and self.mGameConfig.location or "fertile_plains"
    local startingLocation = DataLoader.getStartingLocationById(locationId)

    -- Store the starting location for SetupStarterContent
    self.mStartingLocation = startingLocation

    -- Get terrain config from starting location
    local terrainConfig = nil
    if startingLocation and startingLocation.terrain then
        terrainConfig = startingLocation.terrain
    end

    -- Initialize the alpha world with terrain config
    self.mWorld = AlphaWorld:Create(terrainConfig)

    -- Apply game config if available
    if self.mGameConfig then
        self.mWorld.townName = self.mGameConfig.townName or "Prosperityville"
        -- Store other config for use in setup
        self.mWorld.gameConfig = self.mGameConfig
    end

    -- Store production modifiers from starting location
    if startingLocation and startingLocation.productionModifiers then
        self.mWorld.productionModifiers = startingLocation.productionModifiers
        print("[AlphaPrototypeState] Applied production modifiers from location: " .. locationId)
    end

    -- Initialize UI
    self.mUI = AlphaUI:Create(self.mWorld)

    -- Set up load callback for in-game save/load
    self.mUI.onLoadGame = function(saveData)
        self:StartGameFromSave(saveData)
    end

    -- Set up starter content
    self:SetupStarterContent()

    -- Start paused so player can observe
    self.mWorld.isPaused = true
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

function AlphaPrototypeState:SetupStarterContent()
    -- Use starting location if available, otherwise fall back to alpha_starter_config
    local config
    if self.mStartingLocation then
        -- Use starting location data
        config = {
            population = self.mStartingLocation.population or {
                initialCount = 15,
                classDistribution = DataLoader.getDefaultClassDistribution()
            },
            starterBuildings = self.mStartingLocation.starterBuildings or {},
            starterResources = self.mStartingLocation.starterResources or {},
            starterGold = self.mStartingLocation.starterGold or 1000,
            starterCitizens = self.mStartingLocation.starterCitizens or nil,
            starterLandPlots = self.mStartingLocation.starterLandPlots or {}
        }
        print("[SetupStarterContent] Using starting location: " .. (self.mStartingLocation.id or "unknown"))
    else
        -- Fallback to alpha_starter_config
        config = DataLoader.loadAlphaStarterConfig()
        if not config then
            config = {
                population = {
                    initialCount = 15,
                    classDistribution = DataLoader.getDefaultClassDistribution()
                },
                starterBuildings = {},
                starterResources = {},
                starterGold = 1000
            }
        end
        print("[SetupStarterContent] Using fallback alpha_starter_config")
    end

    -- Apply game config overrides if available
    if self.mGameConfig then
        if self.mGameConfig.startingPopulation and not config.starterCitizens then
            config.population = config.population or {}
            config.population.initialCount = self.mGameConfig.startingPopulation
        end

        -- Apply difficulty modifiers
        if self.mGameConfig.difficulty == "story" then
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

    -- Track created buildings by index for citizen assignment
    local buildingsByIndex = {}

    -- Add starter buildings from config FIRST (before citizens, so we can assign housing)
    -- Validate positions to avoid water, trees, and other buildings
    local usedPositions = {}  -- Track positions already used

    for buildingIndex, buildingConfig in ipairs(config.starterBuildings or {}) do
        local x, y = buildingConfig.x, buildingConfig.y

        -- Helper to check if position is valid (not in water, trees, mountains, or overlapping other buildings)
        local function isValidPosition(px, py)
            -- Check water
            if self.mWorld:IsBuildingInWater(px, py, 60, 60) then
                return false
            end
            -- Check trees
            if self.mWorld.forest and self.mWorld.forest:CheckRectCollision(px, py, 60, 60) then
                return false
            end
            -- Check mountains
            if self.mWorld.mountains and self.mWorld.mountains:CheckRectCollision(px, py, 60, 60) then
                return false
            end
            -- Check already used positions
            for _, pos in ipairs(usedPositions) do
                if math.abs(px - pos.x) < 70 and math.abs(py - pos.y) < 70 then
                    return false
                end
            end
            -- Check existing buildings
            for _, building in ipairs(self.mWorld.buildings) do
                if px < building.x + 70 and px + 60 > building.x and
                   py < building.y + 70 and py + 60 > building.y then
                    return false
                end
            end
            return true
        end

        -- Check if position collides with water or trees and find alternative if needed
        if not isValidPosition(x, y) then
            -- Try to find a valid position nearby (on the left side of the world, away from river)
            local found = false
            -- Search in a larger area for the bigger world (3200x2400)
            for tryX = 100, 1200, 70 do
                for tryY = 100, 1200, 70 do
                    if isValidPosition(tryX, tryY) then
                        x, y = tryX, tryY
                        found = true
                        break
                    end
                end
                if found then break end
            end
        end

        -- Record this position as used
        table.insert(usedPositions, {x = x, y = y})

        local building = self.mWorld:AddBuilding(
            buildingConfig.typeId,
            x,
            y
        )
        if building then
            -- Store by 0-based index (to match JSON format)
            buildingsByIndex[buildingIndex - 1] = building

            -- Auto-assign first matching recipe if configured
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

    -- Spawn citizens - either from starterCitizens or population config
    local citizensByIndex = {}  -- Track citizens by their index for building/land assignment

    if config.starterCitizens and #config.starterCitizens > 0 then
        -- Use detailed starter citizens from starting_locations.json
        print("[SetupStarterContent] Spawning " .. #config.starterCitizens .. " starter citizens")
        for citizenIndex, citizenConfig in ipairs(config.starterCitizens) do
            -- Determine class based on intendedRole
            local classId = "middle"  -- default
            if citizenConfig.intendedRole == "wealthy" then
                classId = "upper"
            elseif citizenConfig.intendedRole == "merchant" then
                classId = "middle"
            elseif citizenConfig.intendedRole == "craftsman" then
                classId = "middle"
            elseif citizenConfig.intendedRole == "laborer" then
                classId = "lower"
            end

            local citizen = self.mWorld:AddCitizen(classId, citizenConfig.name, nil, {
                startingWealth = citizenConfig.startingWealth or 0,
                vocation = citizenConfig.vocation
            })

            if citizen then
                -- Store by 0-based index
                citizensByIndex[citizenIndex - 1] = citizen

                -- Assign to workplace if specified
                if citizenConfig.workplaceIndex ~= nil then
                    local workplace = buildingsByIndex[citizenConfig.workplaceIndex]
                    if workplace then
                        self.mWorld:AssignWorkerToBuilding(citizen, workplace)
                    end
                end

                -- Assign to housing if specified
                if citizenConfig.housingBuildingIndex ~= nil and self.mWorld.housingSystem then
                    local housingBuilding = buildingsByIndex[citizenConfig.housingBuildingIndex]
                    if housingBuilding then
                        self.mWorld.housingSystem:AssignHousing(citizen.id, housingBuilding.id)
                    end
                end
            end
        end
    else
        -- Fallback: Spawn initial population from config (legacy method)
        local popConfig = config.population or {}
        local count = popConfig.initialCount or 15
        local distribution = popConfig.classDistribution or DataLoader.getDefaultClassDistribution()
        self.mWorld:SpawnInitialPopulation(count, distribution)
    end

    -- Assign starter land plots to citizens
    if self.mWorld.landSystem then
        for _, plotConfig in ipairs(config.starterLandPlots or {}) do
            local plotId = self.mWorld.landSystem:GetPlotId(plotConfig.gridX, plotConfig.gridY)
            local ownerCitizen = citizensByIndex[plotConfig.ownerCitizenIndex]
            if plotId and ownerCitizen then
                self.mWorld.landSystem:TransferOwnership(plotId, ownerCitizen.id, 0, 1)
                print("[SetupStarterContent] Assigned plot " .. plotId .. " to " .. ownerCitizen.name)
            end
        end
    end

    -- Assign building ownership for buildings with ownerCitizenIndex
    for buildingIndex, buildingConfig in ipairs(config.starterBuildings or {}) do
        if buildingConfig.ownerCitizenIndex ~= nil then
            local building = buildingsByIndex[buildingIndex - 1]
            local ownerCitizen = citizensByIndex[buildingConfig.ownerCitizenIndex]
            if building and ownerCitizen and self.mWorld.ownershipManager then
                self.mWorld.ownershipManager:TransferBuilding(building.id, ownerCitizen.id, 0, 1)
                print("[SetupStarterContent] Assigned building " .. building.name .. " to " .. ownerCitizen.name)
            end
        end
    end

    -- Add starter resources from config
    for _, resource in ipairs(config.starterResources or {}) do
        self.mWorld:AddToInventory(resource.commodityId, resource.quantity)
    end

    -- Set starter gold
    if config.starterGold then
        self.mWorld.gold = config.starterGold
    end

    -- Update stats
    self.mWorld:UpdateStats()

    -- Run free agency to assign any remaining workers based on their vocations
    self.mWorld:RunFreeAgency()

    -- Log initial setup with town name
    local townName = self.mWorld.townName or "CraveTown"
    self.mWorld:LogEvent("info", "Welcome to " .. townName .. "! Press SPACE to start.", {})
    self.mWorld:LogEvent("info", "Use 1/2/3 to change game speed, H for help.", {})
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
