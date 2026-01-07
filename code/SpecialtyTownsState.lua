--
-- SpecialtyTownsState - CFP Prototype for Indian Specialty Towns
-- Starts with town selection, then runs the game
--

local TownSelectionScreen = require("code/TownSelectionScreen")
local AlphaWorld = require("code/AlphaWorld")
local AlphaUI = require("code/AlphaUI")
local DataLoader = require("code/DataLoader")
local LoadingScreen = require("code/LoadingScreen")

SpecialtyTownsState = {}
SpecialtyTownsState.__index = SpecialtyTownsState

function SpecialtyTownsState:Create()
    local this = {
        mPhase = "townselection",  -- townselection, worldloading, game
        mTownSelection = nil,
        mWorld = nil,
        mUI = nil,
        mSelectedTownData = nil,
        mLoadingScreen = nil,
        mLoadingCoroutine = nil
    }

    setmetatable(this, self)
    return this
end

function SpecialtyTownsState:Enter()
    print("Entering Specialty Towns prototype...")
    self.mPhase = "townselection"

    -- Load town data and create selection screen
    local townsData = DataLoader.loadSpecialtyTowns()
    if #townsData == 0 then
        print("ERROR: No specialty towns data found!")
        return
    end

    self.mTownSelection = TownSelectionScreen:Create(townsData)
end

function SpecialtyTownsState:Update(dt)
    if self.mPhase == "townselection" then
        local selected = self.mTownSelection:Update(dt)
        if selected then
            local townId = self.mTownSelection:GetSelectedTownId()
            self.mSelectedTownData = DataLoader.getSpecialtyTownById(townId)
            if self.mSelectedTownData then
                print("Town selected: " .. self.mSelectedTownData.displayName)
                self:StartGame()
            end
        end

    elseif self.mPhase == "worldloading" then
        -- Resume loading coroutine
        if self.mLoadingCoroutine then
            local success, err = coroutine.resume(self.mLoadingCoroutine)
            if not success then
                print("ERROR during world loading: " .. tostring(err))
                self.mPhase = "game"  -- Try to continue anyway
            end

            -- Check if loading is complete
            if coroutine.status(self.mLoadingCoroutine) == "dead" then
                self.mLoadingCoroutine = nil
                self.mLoadingScreen:Hide()
                self.mPhase = "game"
                print("World loading complete - starting game!")
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

function SpecialtyTownsState:Render()
    if self.mPhase == "townselection" then
        if self.mTownSelection then
            self.mTownSelection:Render()
        end

    elseif self.mPhase == "worldloading" then
        if self.mLoadingScreen then
            self.mLoadingScreen:Render()
        end

    elseif self.mPhase == "game" then
        -- UI handles all rendering (including world)
        if self.mUI and self.mUI.Render then
            self.mUI:Render()
        else
            -- Error state - show message
            love.graphics.clear(0.2, 0.2, 0.2)
            love.graphics.setColor(1, 0.3, 0.3)
            love.graphics.printf("Error: Game failed to load. Press ESC to return to launcher.",
                0, 300, love.graphics.getWidth(), "center")
            love.graphics.setColor(1, 1, 1)
        end
    end
end

function SpecialtyTownsState:StartGame()
    self.mPhase = "worldloading"
    self.mTownSelection = nil

    -- Create and show loading screen
    self.mLoadingScreen = LoadingScreen:Create()
    self.mLoadingScreen:Show()

    -- Create coroutine for async loading
    self.mLoadingCoroutine = coroutine.create(function()
        self:LoadWorldAsync()
    end)
end

function SpecialtyTownsState:LoadWorldAsync()
    local yield = coroutine.yield
    local townData = self.mSelectedTownData

    -- Step 1: Load configuration (10%)
    self.mLoadingScreen:SetProgress(0.10, "Loading " .. townData.displayName .. "...")
    yield()

    -- CRITICAL: Set active version to "alpha" so building types load correctly
    DataLoader.setActiveVersion("alpha")
    print("[SpecialtyTownsState] Set DataLoader activeVersion to 'alpha'")

    -- No terrain for CFP prototype (pure production-consumption)
    local terrainConfig = nil

    -- Step 2: Initialize world (30%)
    self.mLoadingScreen:SetProgress(0.30, "Creating world...", "Initializing town")
    yield()

    self.mWorld = AlphaWorld:Create(terrainConfig, function(progress, message)
        local scaledProgress = 0.30 + progress * 0.30
        self.mLoadingScreen:SetProgress(scaledProgress, "Creating world...", message)
    end)

    -- Step 3: Set town name (60%)
    self.mLoadingScreen:SetProgress(0.60, "Setting up " .. townData.city .. "...")
    yield()

    self.mWorld.townName = townData.displayName

    -- Step 4: Spawn starter buildings (70%)
    self.mLoadingScreen:SetProgress(0.70, "Constructing buildings...")
    yield()

    self:SpawnStarterBuildings(townData.starterBuildings)

    -- Step 5: Spawn starter citizens (80%)
    self.mLoadingScreen:SetProgress(0.80, "Welcoming citizens...")
    yield()

    self:SpawnStarterCitizens(townData.starterCitizens)

    -- Step 6: Add starter inventory (85%)
    self.mLoadingScreen:SetProgress(0.85, "Stocking inventory...")
    yield()

    self:AddStarterInventory(townData.starterInventory)

    -- Step 7: Initialize UI (95%)
    self.mLoadingScreen:SetProgress(0.95, "Preparing interface...")
    yield()

    self.mUI = AlphaUI:Create(self.mWorld)

    -- Disable tutorial for CFP prototype
    if self.mUI.tutorialSystem then
        self.mUI.tutorialSystem:SetEnabled(false)
    end

    -- Step 8: Complete (100%)
    self.mLoadingScreen:SetProgress(1.0, "Ready!")
    yield()

    -- Step 9: Unpause the world (CFP prototype starts unpaused)
    if self.mWorld and self.mWorld.isPaused then
        self.mWorld.isPaused = false
        if self.mWorld.timeManager then
            self.mWorld.timeManager.isPaused = false
        end
        print("World unpaused - game is now running")
    end
end

function SpecialtyTownsState:SpawnStarterBuildings(starterBuildings)
    if not starterBuildings or #starterBuildings == 0 then
        return
    end

    local totalSpawned = 0
    self.mBuildingsList = {}  -- Store for later reference by index

    for idx, buildingConfig in ipairs(starterBuildings) do
        local buildingType = buildingConfig.typeId or buildingConfig.type
        local position = buildingConfig.position or {x = 200 + (idx * 80), y = 200}

        -- Use World's AddBuilding method with position from JSON
        local building = self.mWorld:AddBuilding(buildingType, position.x, position.y)

        if building then
            -- Store building reference
            self.mBuildingsList[idx] = building

            -- Set specific recipe if provided
            if buildingConfig.recipeName and building.SetRecipe then
                building:SetRecipe(buildingConfig.recipeName)
            end

            -- Note: Building ownership will be set after citizens are created
            -- Store ownerCitizenIndex for later assignment
            if buildingConfig.ownerCitizenIndex then
                building._pendingOwnerIndex = buildingConfig.ownerCitizenIndex
            end

            -- Store initialOccupants for housing assignment
            if buildingConfig.initialOccupants then
                building._pendingOccupants = buildingConfig.initialOccupants
            end

            -- Store worker count requirement
            if buildingConfig.workers then
                building._requiredWorkers = buildingConfig.workers
            end

            totalSpawned = totalSpawned + 1
        else
            print("WARNING: Failed to create building type: " .. buildingType)
        end
    end

    print("Spawned " .. totalSpawned .. " starter buildings")
end

function SpecialtyTownsState:SpawnStarterCitizens(starterCitizens)
    if not starterCitizens or #starterCitizens == 0 then
        return
    end

    self.mCitizensList = {}  -- Store for later reference by index

    -- First pass: Create all citizens
    for idx, citizenConfig in ipairs(starterCitizens) do
        -- Use class from JSON, default to middle if not specified
        local classId = citizenConfig.class or "middle"
        local citizen = self.mWorld:AddCitizen(classId, citizenConfig.name, nil, {
            vocation = citizenConfig.vocation or "General Labor",
            startingWealth = 0
        })

        if citizen then
            -- Store citizen reference
            self.mCitizensList[idx] = citizen

            -- Set age if provided
            if citizenConfig.age then
                citizen.mAge = citizenConfig.age
            end

            -- Store workplace and housing indices for later assignment
            if citizenConfig.workplaceIndex then
                citizen._pendingWorkplaceIndex = citizenConfig.workplaceIndex
            end
            if citizenConfig.housingIndex then
                citizen._pendingHousingIndex = citizenConfig.housingIndex
            end

            -- Store family relation for later linking
            if citizenConfig.familyRelation then
                citizen._pendingFamilyRelation = citizenConfig.familyRelation
            end
        else
            print("WARNING: Failed to create citizen: " .. citizenConfig.name)
        end
    end

    print("Spawned " .. #starterCitizens .. " starter citizens")

    -- Second pass: Assign workers to buildings
    self:AssignWorkersToBuildings()

    -- Third pass: Assign housing
    self:AssignHousing()

    -- Fourth pass: Set up family relations
    self:SetupFamilyRelations()

    -- Fifth pass: Set building ownership
    self:SetBuildingOwnership()
end

function SpecialtyTownsState:AddStarterInventory(starterInventory)
    if not starterInventory or #starterInventory == 0 then
        return
    end

    for _, item in ipairs(starterInventory) do
        -- Use World's AddToInventory method
        self.mWorld:AddToInventory(item.commodityId or item.commodity, item.quantity)
    end

    print("Added " .. #starterInventory .. " types of commodities to inventory")
end

function SpecialtyTownsState:AssignWorkersToBuildings()
    if not self.mCitizensList or not self.mBuildingsList then
        return
    end

    local assignedCount = 0

    for idx, citizen in pairs(self.mCitizensList) do
        if citizen._pendingWorkplaceIndex and citizen._pendingWorkplaceIndex >= 0 then
            -- Convert from 0-based JSON index to 1-based Lua index
            local workplaceIdx = citizen._pendingWorkplaceIndex + 1
            local building = self.mBuildingsList[workplaceIdx]

            if building then
                -- Try multiple methods to assign worker
                local success = false

                if building.AddWorker then
                    building:AddWorker(citizen)
                    success = true
                elseif building.AssignWorker then
                    building:AssignWorker(citizen)
                    success = true
                elseif building.mWorkers then
                    -- Direct assignment to workers table
                    table.insert(building.mWorkers, citizen)
                    success = true
                end

                -- Link citizen to workplace
                if citizen.SetWorkplace then
                    citizen:SetWorkplace(building)
                elseif citizen.mWorkplace ~= nil then
                    citizen.mWorkplace = building
                end

                if success then
                    assignedCount = assignedCount + 1
                end

                -- Clear pending data
                citizen._pendingWorkplaceIndex = nil
            else
                local citizenName = citizen.mName or citizen.name or tostring(citizen)
                print("WARNING: Workplace building index " .. (workplaceIdx - 1) .. " not found for citizen: " .. citizenName)
            end
        end
    end

    print("Assigned " .. assignedCount .. " workers to buildings")
end

function SpecialtyTownsState:AssignHousing()
    if not self.mCitizensList or not self.mBuildingsList then
        return
    end

    local assignedCount = 0

    -- Method 1: Citizens specify their housing via housingIndex
    for idx, citizen in pairs(self.mCitizensList) do
        if citizen._pendingHousingIndex then
            -- Convert from 0-based JSON index to 1-based Lua index
            local housingIdx = citizen._pendingHousingIndex + 1
            local housing = self.mBuildingsList[housingIdx]

            if housing then
                -- Assign citizen to housing
                if housing.AddOccupant then
                    housing:AddOccupant(citizen)
                    assignedCount = assignedCount + 1
                elseif housing.AssignOccupant then
                    housing:AssignOccupant(citizen)
                    assignedCount = assignedCount + 1
                end

                -- Link citizen to housing
                if citizen.SetHousing then
                    citizen:SetHousing(housing)
                end

                -- Clear pending data
                citizen._pendingHousingIndex = nil
            else
                local citizenName = citizen.mName or citizen.name or tostring(citizen)
                print("WARNING: Housing building index " .. (housingIdx - 1) .. " not found for citizen: " .. citizenName)
            end
        end
    end

    -- Method 2: Buildings specify initial occupants via initialOccupants array
    for idx, building in pairs(self.mBuildingsList) do
        if building._pendingOccupants then
            for _, jsonCitizenIdx in ipairs(building._pendingOccupants) do
                -- Convert from 0-based JSON index to 1-based Lua index
                local citizenIdx = jsonCitizenIdx + 1
                local citizen = self.mCitizensList[citizenIdx]

                if citizen then
                    -- Assign citizen to housing
                    if building.AddOccupant then
                        building:AddOccupant(citizen)
                        assignedCount = assignedCount + 1
                    elseif building.AssignOccupant then
                        building:AssignOccupant(citizen)
                        assignedCount = assignedCount + 1
                    end

                    -- Link citizen to housing
                    if citizen.SetHousing then
                        citizen:SetHousing(building)
                    end
                else
                    print("WARNING: Occupant citizen index " .. jsonCitizenIdx .. " not found for building")
                end
            end

            -- Clear pending data
            building._pendingOccupants = nil
        end
    end

    print("Assigned " .. assignedCount .. " citizens to housing")
end

function SpecialtyTownsState:SetupFamilyRelations()
    if not self.mCitizensList then
        return
    end

    local relationsCount = 0

    for idx, citizen in pairs(self.mCitizensList) do
        if citizen._pendingFamilyRelation then
            local relation = citizen._pendingFamilyRelation
            -- Convert from 0-based JSON index to 1-based Lua index
            local targetIdx = relation.targetIndex + 1
            local targetCitizen = self.mCitizensList[targetIdx]

            if targetCitizen then
                local success = false

                -- Set family relation
                if relation.type == "spouse" then
                    if citizen.SetSpouse and targetCitizen.SetSpouse then
                        citizen:SetSpouse(targetCitizen)
                        targetCitizen:SetSpouse(citizen)  -- Bidirectional
                        success = true
                    elseif citizen.mSpouse ~= nil then
                        -- Direct field assignment
                        citizen.mSpouse = targetCitizen
                        targetCitizen.mSpouse = citizen
                        success = true
                    end
                elseif relation.type == "child" then
                    if citizen.SetParent and targetCitizen.AddChild then
                        citizen:SetParent(targetCitizen)
                        targetCitizen:AddChild(citizen)
                        success = true
                    elseif citizen.mParent ~= nil and targetCitizen.mChildren then
                        citizen.mParent = targetCitizen
                        table.insert(targetCitizen.mChildren, citizen)
                        success = true
                    end
                elseif relation.type == "parent" then
                    if citizen.AddChild and targetCitizen.SetParent then
                        citizen:AddChild(targetCitizen)
                        targetCitizen:SetParent(citizen)
                        success = true
                    elseif citizen.mChildren and targetCitizen.mParent ~= nil then
                        table.insert(citizen.mChildren, targetCitizen)
                        targetCitizen.mParent = citizen
                        success = true
                    end
                end

                if success then
                    relationsCount = relationsCount + 1
                end

                -- Clear pending data
                citizen._pendingFamilyRelation = nil
            else
                local citizenName = citizen.mName or citizen.name or tostring(citizen)
                print("WARNING: Family relation target index " .. (targetIdx - 1) .. " not found for citizen: " .. citizenName)
            end
        end
    end

    print("Set up " .. relationsCount .. " family relations")
end

function SpecialtyTownsState:SetBuildingOwnership()
    if not self.mCitizensList or not self.mBuildingsList then
        return
    end

    local ownershipCount = 0

    for idx, building in pairs(self.mBuildingsList) do
        if building._pendingOwnerIndex then
            -- Convert from 0-based JSON index to 1-based Lua index
            local ownerIdx = building._pendingOwnerIndex + 1
            local owner = self.mCitizensList[ownerIdx]

            if owner then
                local success = false

                -- Set building owner
                if building.SetOwner then
                    building:SetOwner(owner)
                    success = true
                elseif building.mOwner ~= nil then
                    building.mOwner = owner
                    success = true
                end

                -- Link citizen to owned building
                if owner.AddOwnedBuilding then
                    owner:AddOwnedBuilding(building)
                elseif owner.mOwnedBuildings then
                    table.insert(owner.mOwnedBuildings, building)
                end

                if success then
                    ownershipCount = ownershipCount + 1
                end

                -- Clear pending data
                building._pendingOwnerIndex = nil
            else
                print("WARNING: Owner citizen index " .. (ownerIdx - 1) .. " not found for building")
            end
        end
    end

    print("Set " .. ownershipCount .. " building ownerships")
end

function SpecialtyTownsState:keypressed(key)
    if key == "escape" then
        if self.mPhase == "townselection" then
            -- Return to launcher
            ReturnToLauncher()
        elseif self.mPhase == "game" then
            if self.mUI and self.mUI.HandleKeyPress then
                return self.mUI:HandleKeyPress(key)
            end
        end
    elseif self.mPhase == "game" then
        if self.mUI and self.mUI.HandleKeyPress then
            return self.mUI:HandleKeyPress(key)
        end
    end
    return false
end

function SpecialtyTownsState:mousepressed(x, y, button)
    if self.mPhase == "game" then
        if self.mUI and self.mUI.HandleClick then
            return self.mUI:HandleClick(x, y, button)
        end
    end
    return false
end

function SpecialtyTownsState:mousereleased(x, y, button)
    -- AlphaUI handles clicks on press, not release
    -- No action needed here for now
    return false
end

function SpecialtyTownsState:mousemoved(x, y, dx, dy)
    if self.mPhase == "game" then
        if self.mUI and self.mUI.HandleMouseMove then
            return self.mUI:HandleMouseMove(x, y)
        end
    end
    return false
end

function SpecialtyTownsState:wheelmoved(dx, dy)
    if self.mPhase == "game" then
        if self.mUI and self.mUI.HandleMouseWheel then
            return self.mUI:HandleMouseWheel(dx, dy)
        end
    end
    return false
end

return SpecialtyTownsState
