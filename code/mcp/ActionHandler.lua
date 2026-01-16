--
-- ActionHandler.lua - Handles high-level game actions
-- Provides semantic game operations that map to sequences of inputs/state changes
--

local Protocol = require("code.mcp.Protocol")

local ActionHandler = {}
ActionHandler.__index = ActionHandler

function ActionHandler:init(bridge)
    local self = setmetatable({}, ActionHandler)
    self.bridge = bridge
    return self
end

-- Main execute function - dispatches to specific action handlers
function ActionHandler:execute(params)
    local action = params.action
    local actionParams = params.params or params

    -- Check if we're in consumption prototype mode
    if gMode == "test_cache" and gTestCache and gTestCache.prototype then
        return self:executeConsumptionAction(action, actionParams)
    end

    -- Check if we're in alpha prototype mode
    if gMode == "alpha" and gAlphaPrototype then
        return self:executeAlphaAction(action, actionParams)
    end

    local handlers = {
        -- Building actions
        place_building = function() return self:placeBuilding(actionParams) end,
        start_building_placement = function() return self:startBuildingPlacement(actionParams) end,
        select_building = function() return self:selectBuilding(actionParams) end,
        cancel_placement = function() return self:cancelPlacement(actionParams) end,

        -- Worker actions
        assign_worker = function() return self:assignWorker(actionParams) end,
        remove_worker = function() return self:removeWorker(actionParams) end,

        -- Production actions
        set_production = function() return self:setProduction(actionParams) end,
        select_grain = function() return self:selectGrain(actionParams) end,
        select_mine_resource = function() return self:selectMineResource(actionParams) end,

        -- Camera actions
        move_camera = function() return self:moveCamera(actionParams) end,
        move_camera_by = function() return self:moveCameraBy(actionParams) end,
        zoom_camera = function() return self:zoomCamera(actionParams) end,

        -- UI actions
        open_menu = function() return self:openMenu(actionParams) end,
        close_menu = function() return self:closeMenu(actionParams) end,
        click_button = function() return self:clickButton(actionParams) end,

        -- Game flow actions
        set_town_name = function() return self:setTownName(actionParams) end,
        start_game = function() return self:startGame(actionParams) end,
        return_to_launcher = function() return self:returnToLauncher(actionParams) end,
        advance_time = function() return self:advanceTime(actionParams) end,

        -- Character actions
        hire_character = function() return self:hireCharacter(actionParams) end,

        -- Mode switching
        launch_consumption_prototype = function() return self:launchConsumptionPrototype(actionParams) end,
    }

    local handler = handlers[action]
    if handler then
        local success, result = pcall(handler)
        if success then
            return result
        else
            return {success = false, error = "Action error: " .. tostring(result)}
        end
    end

    return {success = false, error = "Unknown action: " .. tostring(action)}
end

-- Start building placement mode
function ActionHandler:startBuildingPlacement(params)
    local buildingType = params.building_type

    if not buildingType then
        return {success = false, error = "building_type is required"}
    end

    -- Check if we're in main mode and TownView state
    if gMode ~= "main" then
        return {success = false, error = "Must be in main game mode"}
    end

    if not gStateMachine or gStateMachine.mCurrentStateName ~= "TownView" then
        return {success = false, error = "Must be in TownView state"}
    end

    -- Find the building type
    if not BuildingTypes then
        return {success = false, error = "BuildingTypes not loaded"}
    end

    local bt = BuildingTypes[buildingType] or BuildingTypes[string.upper(buildingType)]
    if not bt then
        -- Try to find by id
        if BuildingTypes.getAllTypes then
            for _, t in ipairs(BuildingTypes.getAllTypes()) do
                if t.id == buildingType then
                    bt = t
                    break
                end
            end
        end
    end

    if not bt then
        return {success = false, error = "Unknown building type: " .. tostring(buildingType)}
    end

    -- Check if we can afford it
    if bt.constructionMaterials and gTown and gTown.mInventory then
        for commodityId, required in pairs(bt.constructionMaterials) do
            local available = gTown.mInventory:Get(commodityId) or 0
            if available < required then
                return {success = false, error = "Cannot afford building. Need " .. required .. " " .. commodityId .. ", have " .. available}
            end
        end
    end

    -- Change to BuildingPlacement state
    gStateMachine:Change("BuildingPlacement", {buildingType = bt})

    self.bridge.eventLogger:log(Protocol.EventTypes.STATE_CHANGED, {
        from = "TownView",
        to = "BuildingPlacement",
        building_type = buildingType
    })

    return {success = true, building_type = buildingType, state = "BuildingPlacement"}
end

-- Place building at specific coordinates
function ActionHandler:placeBuilding(params)
    local x = params.x
    local y = params.y
    local width = params.width
    local height = params.height

    -- Check if we're in BuildingPlacement state
    if not gStateMachine or gStateMachine.mCurrentStateName ~= "BuildingPlacement" then
        return {success = false, error = "Must be in BuildingPlacement state. Use start_building_placement first."}
    end

    local placementState = gStateMachine.mCurrentState
    if not placementState or not placementState.mBuildingToPlace then
        return {success = false, error = "No building to place"}
    end

    local building = placementState.mBuildingToPlace

    -- Set position if provided
    if x and y then
        building:SetPosition(x, y)
    end

    -- Set size if provided and building supports variable size
    if building.mBuildingType.variableSize then
        if width then
            local minW = building.mBuildingType.minWidth or 50
            local maxW = building.mBuildingType.maxWidth or 200
            building.mWidth = math.max(minW, math.min(maxW, width))
        end
        if height then
            local minH = building.mBuildingType.minHeight or 50
            local maxH = building.mBuildingType.maxHeight or 200
            building.mHeight = math.max(minH, math.min(maxH, height))
        end
    end

    -- Check if placement is valid
    local hasCollision = gTown:CheckCollision(building)
    local isWithinBounds = gTown:IsWithinBoundaries(building)

    if hasCollision then
        return {success = false, error = "Cannot place here - collision with another building"}
    end

    if not isWithinBounds then
        return {success = false, error = "Cannot place here - outside town boundaries"}
    end

    -- Simulate left click to place
    local screenX, screenY = gCamera:getScreenCoords(building.mX + building.mWidth/2, building.mY + building.mHeight/2)
    gMouseReleased = {x = screenX, y = screenY, button = 1}

    -- Let the game's update loop handle the placement
    -- The BuildingPlacementState will process gMouseReleased and place the building

    return {
        success = true,
        message = "Building placement initiated",
        position = {x = building.mX, y = building.mY},
        size = {width = building.mWidth, height = building.mHeight}
    }
end

-- Cancel building placement
function ActionHandler:cancelPlacement(params)
    if not gStateMachine or gStateMachine.mCurrentStateName ~= "BuildingPlacement" then
        return {success = false, error = "Not in BuildingPlacement state"}
    end

    -- Simulate right click to cancel
    gMouseReleased = {x = love.mouse.getX(), y = love.mouse.getY(), button = 2}

    return {success = true, message = "Placement cancelled"}
end

-- Select a building
function ActionHandler:selectBuilding(params)
    local buildingId = params.building_id

    if not buildingId then
        return {success = false, error = "building_id is required"}
    end

    if gTown and gTown.mBuildings and gTown.mBuildings[buildingId] then
        gSelectedBuilding = gTown.mBuildings[buildingId]
        return {success = true, building_id = buildingId}
    end

    return {success = false, error = "Building not found: " .. tostring(buildingId)}
end

-- Move camera to absolute position
function ActionHandler:moveCamera(params)
    local x = params.x
    local y = params.y

    if not x or not y then
        return {success = false, error = "x and y are required"}
    end

    if gCamera then
        gCamera.x = x
        gCamera.y = y
        return {success = true, x = x, y = y}
    end

    return {success = false, error = "Camera not available"}
end

-- Move camera by relative amount
function ActionHandler:moveCameraBy(params)
    local dx = params.dx or 0
    local dy = params.dy or 0

    if gCamera then
        gCamera:move(dx, dy)
        return {success = true, dx = dx, dy = dy, new_x = gCamera.x, new_y = gCamera.y}
    end

    return {success = false, error = "Camera not available"}
end

-- Set camera zoom
function ActionHandler:zoomCamera(params)
    local scale = params.scale

    if not scale then
        return {success = false, error = "scale is required"}
    end

    if gCamera then
        gCamera.scale = math.max(0.1, math.min(5.0, scale))
        return {success = true, scale = gCamera.scale}
    end

    return {success = false, error = "Camera not available"}
end

-- Open a menu
function ActionHandler:openMenu(params)
    local menuName = params.menu_name

    if not menuName then
        return {success = false, error = "menu_name is required"}
    end

    -- Handle specific menus
    if menuName == "inventory" then
        if InventoryDrawer then
            local drawer = InventoryDrawer:Create()
            gStateStack:Push(drawer)
            return {success = true, menu = "inventory"}
        end
    elseif menuName == "character" then
        if CharacterMenu then
            local menu = CharacterMenu:Create()
            gStateStack:Push(menu)
            return {success = true, menu = "character"}
        end
    end

    return {success = false, error = "Unknown menu: " .. tostring(menuName)}
end

-- Close current menu/modal
function ActionHandler:closeMenu(params)
    if gStateStack and #gStateStack.mStates > 2 then  -- Keep TopBar and BuildingMenu
        gStateStack:Pop()
        return {success = true}
    end

    return {success = false, error = "No menu to close"}
end

-- Click a button by position or name
function ActionHandler:clickButton(params)
    local x = params.x
    local y = params.y
    local buttonName = params.button_name

    if x and y then
        -- Click at specific coordinates
        self.bridge.inputRelay:inject({
            type = "mouse",
            action = "click",
            x = x,
            y = y,
            button = 1
        })
        return {success = true, x = x, y = y}
    end

    return {success = false, error = "x and y coordinates required"}
end

-- Set town name
function ActionHandler:setTownName(params)
    local name = params.name

    if not name then
        return {success = false, error = "name is required"}
    end

    -- Check if TownNameModal is open
    if gStateStack and #gStateStack.mStates > 0 then
        local topState = gStateStack.mStates[#gStateStack.mStates]
        if TownNameModal and getmetatable(topState) == TownNameModal then
            -- Set the name directly
            topState.mTownName = name
            -- Simulate Enter key to confirm
            if topState.keypressed then
                topState:keypressed("return")
            end
            return {success = true, name = name}
        end
    end

    -- If modal is not open, just set the town name directly
    if gTown then
        gTown.mName = name
        return {success = true, name = name, note = "Set directly (no modal open)"}
    end

    return {success = false, error = "Cannot set town name - no modal open and no town exists"}
end

-- Start the main game
function ActionHandler:startGame(params)
    if gMode == "launcher" and gPrototypeLauncher then
        -- Find and click the "Main Game" option
        InitializeMainGame()
        return {success = true, mode = "main"}
    elseif gMode == "version_select" then
        return {success = false, error = "Must select version first"}
    end

    return {success = false, error = "Cannot start game from current mode: " .. tostring(gMode)}
end

-- Return to launcher
function ActionHandler:returnToLauncher(params)
    if gMode ~= "launcher" and gMode ~= "version_select" then
        ReturnToLauncher()
        return {success = true}
    end

    return {success = false, error = "Already at launcher or version select"}
end

-- Select grain for a farm
function ActionHandler:selectGrain(params)
    local buildingId = params.building_id
    local grainType = params.grain_type

    if not grainType then
        return {success = false, error = "grain_type is required"}
    end

    -- Check if GrainSelectionModal is open
    if gStateStack and #gStateStack.mStates > 0 then
        local topState = gStateStack.mStates[#gStateStack.mStates]
        if GrainSelectionModal and getmetatable(topState) == GrainSelectionModal then
            -- Try to select the grain
            if topState.mBuilding then
                topState.mBuilding.mProducedGrain = grainType
                gStateStack:Pop()

                self.bridge.eventLogger:log(Protocol.EventTypes.GRAIN_SELECTED, {
                    building_id = buildingId,
                    grain_type = grainType
                })

                return {success = true, grain_type = grainType}
            end
        end
    end

    -- If no modal, try to set directly on building
    if buildingId and gTown and gTown.mBuildings and gTown.mBuildings[buildingId] then
        gTown.mBuildings[buildingId].mProducedGrain = grainType
        return {success = true, grain_type = grainType, note = "Set directly"}
    end

    return {success = false, error = "No grain selection modal open and no building_id provided"}
end

-- Select resource for a mine
function ActionHandler:selectMineResource(params)
    local buildingId = params.building_id
    local resourceType = params.resource_type

    if not resourceType then
        return {success = false, error = "resource_type is required"}
    end

    -- Similar logic to selectGrain
    if gStateStack and #gStateStack.mStates > 0 then
        local topState = gStateStack.mStates[#gStateStack.mStates]
        if MineSelectionModal and getmetatable(topState) == MineSelectionModal then
            if topState.mBuilding then
                topState.mBuilding.mMineResource = resourceType
                gStateStack:Pop()
                return {success = true, resource_type = resourceType}
            end
        end
    end

    if buildingId and gTown and gTown.mBuildings and gTown.mBuildings[buildingId] then
        gTown.mBuildings[buildingId].mMineResource = resourceType
        return {success = true, resource_type = resourceType, note = "Set directly"}
    end

    return {success = false, error = "No mine selection modal open and no building_id provided"}
end

-- Advance time
function ActionHandler:advanceTime(params)
    local ticks = params.ticks or 1
    local dt = 1/60  -- Simulate 60fps

    for i = 1, ticks do
        -- Call game update
        if gMode == "main" then
            if gTown then gTown:Update(dt) end
            if gStateMachine then gStateMachine:Update(dt) end
            if gStateStack then gStateStack:Update(dt) end
        end
        self.bridge.frameCount = self.bridge.frameCount + 1
    end

    return {success = true, ticks_advanced = ticks, new_frame = self.bridge.frameCount}
end

-- Assign worker (placeholder - depends on game implementation)
function ActionHandler:assignWorker(params)
    return {success = false, error = "Worker assignment not yet implemented"}
end

-- Remove worker (placeholder - depends on game implementation)
function ActionHandler:removeWorker(params)
    return {success = false, error = "Worker removal not yet implemented"}
end

-- Set production (placeholder - depends on game implementation)
function ActionHandler:setProduction(params)
    return {success = false, error = "Set production not yet implemented"}
end

-- Hire character (placeholder - depends on game implementation)
function ActionHandler:hireCharacter(params)
    return {success = false, error = "Character hiring not yet implemented"}
end

-- Launch consumption prototype from launcher
function ActionHandler:launchConsumptionPrototype(params)
    if gMode == "launcher" then
        InitializeTestCache()
        return {success = true, mode = "test_cache"}
    end
    return {success = false, error = "Must be in launcher mode"}
end

-- ============================================================================
-- CONSUMPTION PROTOTYPE ACTIONS
-- For game balance testing and AI observation
-- ============================================================================

function ActionHandler:executeConsumptionAction(action, params)
    local proto = gTestCache.prototype

    local handlers = {
        -- Simulation controls
        pause_simulation = function() return self:consumptionPause(proto) end,
        resume_simulation = function() return self:consumptionResume(proto) end,
        toggle_simulation = function() return self:consumptionToggle(proto) end,
        set_simulation_speed = function() return self:consumptionSetSpeed(proto, params) end,
        skip_cycles = function() return self:consumptionSkipCycles(proto, params) end,

        -- Character management
        add_character = function() return self:consumptionAddCharacter(proto, params) end,
        add_random_characters = function() return self:consumptionAddRandomCharacters(proto, params) end,
        clear_all_characters = function() return self:consumptionClearCharacters(proto) end,
        remove_character = function() return self:consumptionRemoveCharacter(proto, params) end,

        -- Inventory management
        inject_resource = function() return self:consumptionInjectResource(proto, params) end,
        fill_basic_inventory = function() return self:consumptionFillBasic(proto) end,
        fill_luxury_inventory = function() return self:consumptionFillLuxury(proto) end,
        double_inventory = function() return self:consumptionDoubleInventory(proto) end,
        clear_inventory = function() return self:consumptionClearInventory(proto) end,

        -- Policy changes
        set_allocation_policy = function() return self:consumptionSetPolicy(proto, params) end,
        apply_policy_preset = function() return self:consumptionApplyPreset(proto, params) end,

        -- Testing tools
        trigger_riot = function() return self:consumptionTriggerRiot(proto) end,
        trigger_civil_unrest = function() return self:consumptionTriggerUnrest(proto) end,
        trigger_mass_emigration = function() return self:consumptionTriggerEmigration(proto, params) end,
        trigger_random_protest = function() return self:consumptionTriggerProtest(proto) end,
        set_all_satisfaction = function() return self:consumptionSetSatisfaction(proto, params) end,
        randomize_all_satisfaction = function() return self:consumptionRandomizeSatisfaction(proto) end,
        reset_all_cravings = function() return self:consumptionResetCravings(proto) end,
        reset_all_fatigue = function() return self:consumptionResetFatigue(proto) end,
        clear_all_protests = function() return self:consumptionClearProtests(proto) end,

        -- General actions that still work
        return_to_launcher = function() return self:returnToLauncher(params) end,
    }

    local handler = handlers[action]
    if handler then
        local success, result = pcall(handler)
        if success then
            return result
        else
            return {success = false, error = "Consumption action error: " .. tostring(result)}
        end
    end

    return {success = false, error = "Unknown consumption action: " .. tostring(action)}
end

-- Simulation controls
function ActionHandler:consumptionPause(proto)
    proto.isPaused = true
    return {success = true, paused = true}
end

function ActionHandler:consumptionResume(proto)
    proto.isPaused = false
    return {success = true, paused = false}
end

function ActionHandler:consumptionToggle(proto)
    proto.isPaused = not proto.isPaused
    return {success = true, paused = proto.isPaused}
end

function ActionHandler:consumptionSetSpeed(proto, params)
    local speed = params.speed or 1.0
    -- Valid speeds: 1, 2, 5, 10
    local validSpeeds = {1, 2, 5, 10}
    local found = false
    for _, v in ipairs(validSpeeds) do
        if v == speed then found = true break end
    end
    if not found then
        speed = math.max(1, math.min(10, speed))
    end
    proto.simulationSpeed = speed
    return {success = true, speed = proto.simulationSpeed}
end

function ActionHandler:consumptionSkipCycles(proto, params)
    local count = params.count or params.cycles or 1
    proto:SkipCycles(count)
    return {success = true, cycles_skipped = count, new_cycle = proto.cycleNumber}
end

-- Character management
function ActionHandler:consumptionAddCharacter(proto, params)
    local class = params.class or "Middle"
    local traits = params.traits or {}
    local vocation = params.vocation

    proto:AddCharacter(class, traits, vocation)
    local char = proto.characters[#proto.characters]

    return {
        success = true,
        character = {
            name = char.name,
            class = char.class,
            age = char.age,
            vocation = char.vocation,
            traits = char.traits
        },
        total_characters = #proto.characters
    }
end

function ActionHandler:consumptionAddRandomCharacters(proto, params)
    local count = params.count or 1
    proto:AddRandomCharacters(count)
    return {success = true, added = count, total_characters = #proto.characters}
end

function ActionHandler:consumptionClearCharacters(proto)
    proto:ClearAllCharacters()
    return {success = true, total_characters = 0}
end

function ActionHandler:consumptionRemoveCharacter(proto, params)
    local id = params.id or params.name
    if not id then
        return {success = false, error = "id or name required"}
    end

    for i, char in ipairs(proto.characters) do
        if i == tonumber(id) or char.name == id then
            proto:RemoveCharacter(char)
            return {success = true, removed = char.name}
        end
    end
    return {success = false, error = "Character not found: " .. tostring(id)}
end

-- Inventory management
function ActionHandler:consumptionInjectResource(proto, params)
    local commodity = params.commodity
    local amount = params.amount or 100

    if not commodity then
        return {success = false, error = "commodity is required"}
    end

    proto:InjectResource(commodity, amount)
    return {
        success = true,
        commodity = commodity,
        amount_added = amount,
        new_total = proto.townInventory[commodity] or 0
    }
end

function ActionHandler:consumptionFillBasic(proto)
    proto:FillBasicInventory()
    return {success = true, inventory_type = "basic"}
end

function ActionHandler:consumptionFillLuxury(proto)
    proto:FillLuxuryInventory()
    return {success = true, inventory_type = "luxury"}
end

function ActionHandler:consumptionDoubleInventory(proto)
    proto:DoubleInventory()
    return {success = true, action = "doubled"}
end

function ActionHandler:consumptionClearInventory(proto)
    proto:ClearInventory()
    return {success = true, action = "cleared"}
end

-- Policy changes
function ActionHandler:consumptionSetPolicy(proto, params)
    -- Update policy settings
    if params.priority_mode then
        proto.allocationPolicy.priorityMode = params.priority_mode
    end
    if params.fairness_enabled ~= nil then
        proto.allocationPolicy.fairnessEnabled = params.fairness_enabled
    end
    if params.class_priorities then
        for class, priority in pairs(params.class_priorities) do
            proto.allocationPolicy.classPriorities[class] = priority
        end
    end
    if params.consumption_budgets then
        for class, budget in pairs(params.consumption_budgets) do
            proto.allocationPolicy.consumptionBudgets[class] = budget
        end
    end
    if params.dimension_priorities then
        for dim, priority in pairs(params.dimension_priorities) do
            proto.allocationPolicy.dimensionPriorities[dim] = priority
        end
    end
    if params.substitution_aggressiveness then
        proto.allocationPolicy.substitutionAggressiveness = params.substitution_aggressiveness
    end
    if params.reserve_threshold then
        proto.allocationPolicy.reserveThreshold = params.reserve_threshold
    end

    return {success = true, policy = proto.allocationPolicy}
end

function ActionHandler:consumptionApplyPreset(proto, params)
    local presetName = params.preset or params.name
    if not presetName then
        return {success = false, error = "preset name required"}
    end

    proto:ApplyPolicyPreset(presetName)
    return {success = true, preset = presetName, policy = proto.allocationPolicy}
end

-- Testing tools
function ActionHandler:consumptionTriggerRiot(proto)
    proto:TriggerRiot()
    return {success = true, event = "riot"}
end

function ActionHandler:consumptionTriggerUnrest(proto)
    proto:TriggerCivilUnrest()
    return {success = true, event = "civil_unrest"}
end

function ActionHandler:consumptionTriggerEmigration(proto, params)
    local count = params.count or 3
    proto:TriggerMassEmigration(count)
    return {success = true, event = "mass_emigration", count = count}
end

function ActionHandler:consumptionTriggerProtest(proto)
    proto:TriggerRandomProtest()
    return {success = true, event = "random_protest"}
end

function ActionHandler:consumptionSetSatisfaction(proto, params)
    local value = params.value or 50
    proto:SetAllSatisfaction(value)
    return {success = true, satisfaction_set = value}
end

function ActionHandler:consumptionRandomizeSatisfaction(proto)
    proto:RandomizeAllSatisfaction()
    return {success = true, action = "randomized"}
end

function ActionHandler:consumptionResetCravings(proto)
    proto:ResetAllCravings()
    return {success = true, action = "cravings_reset"}
end

function ActionHandler:consumptionResetFatigue(proto)
    proto:ResetAllFatigue()
    return {success = true, action = "fatigue_reset"}
end

function ActionHandler:consumptionClearProtests(proto)
    proto:ClearAllProtests()
    return {success = true, action = "protests_cleared"}
end

-- ============================================================================
-- ALPHA PROTOTYPE ACTIONS
-- For town building simulation with production and consumption
-- ============================================================================

function ActionHandler:executeAlphaAction(action, params)
    local alpha = gAlphaPrototype
    local phase = alpha.mPhase

    -- Pre-game phase actions
    if phase ~= "game" then
        return self:executeAlphaPhaseAction(alpha, phase, action, params)
    end

    local world = alpha.mWorld
    local ui = alpha.mUI

    if not world then
        return {success = false, error = "Alpha world not initialized"}
    end

    local handlers = {
        -- Time controls
        pause = function() return self:alphaPause(world) end,
        resume = function() return self:alphaResume(world) end,
        toggle_pause = function() return self:alphaTogglePause(world) end,
        set_speed = function() return self:alphaSetSpeed(world, params) end,

        -- Camera actions
        move_camera = function() return self:alphaMoveCamera(ui, params) end,
        move_camera_by = function() return self:alphaMoveCameraBy(ui, params) end,
        zoom_camera = function() return self:alphaZoomCamera(ui, params) end,

        -- Building actions
        start_building_placement = function() return self:alphaStartBuildingPlacement(world, ui, params) end,
        place_building = function() return self:alphaPlaceBuilding(world, ui, params) end,
        cancel_placement = function() return self:alphaCancelPlacement(ui) end,

        -- Worker management
        assign_worker = function() return self:alphaAssignWorker(world, params) end,
        remove_worker = function() return self:alphaRemoveWorker(world, params) end,

        -- Recipe management
        assign_recipe = function() return self:alphaAssignRecipe(world, params) end,

        -- Housing management
        assign_housing = function() return self:alphaAssignHousing(world, params) end,
        unassign_housing = function() return self:alphaUnassignHousing(world, params) end,

        -- Immigration
        accept_immigrant = function() return self:alphaAcceptImmigrant(world, params) end,
        reject_immigrant = function() return self:alphaRejectImmigrant(world, params) end,

        -- Inventory management
        add_resource = function() return self:alphaAddResource(world, params) end,
        remove_resource = function() return self:alphaRemoveResource(world, params) end,
        add_gold = function() return self:alphaAddGold(world, params) end,

        -- Selection
        select_building = function() return self:alphaSelectBuilding(world, params) end,
        select_citizen = function() return self:alphaSelectCitizen(world, params) end,
        clear_selection = function() return self:alphaClearSelection(world) end,

        -- UI toggles
        toggle_inventory = function() return self:alphaToggleInventory(ui) end,
        toggle_build_menu = function() return self:alphaToggleBuildMenu(ui) end,
        toggle_citizens = function() return self:alphaToggleCitizens(ui) end,
        toggle_immigration = function() return self:alphaToggleImmigration(ui) end,
        toggle_help = function() return self:alphaToggleHelp(ui) end,
        close_all_panels = function() return self:alphaCloseAllPanels(ui) end,

        -- Save/Load
        quick_save = function() return self:alphaQuickSave(world) end,
        quick_load = function() return self:alphaQuickLoad(alpha) end,

        -- Testing/Debug actions
        add_citizen = function() return self:alphaAddCitizen(world, params) end,
        remove_citizen = function() return self:alphaRemoveCitizen(world, params) end,
        advance_time = function() return self:alphaAdvanceTime(world, params) end,
        run_free_agency = function() return self:alphaRunFreeAgency(world) end,

        -- General actions that still work
        return_to_launcher = function() return self:returnToLauncher(params) end,
    }

    local handler = handlers[action]
    if handler then
        local success, result = pcall(handler)
        if success then
            return result
        else
            return {success = false, error = "Alpha action error: " .. tostring(result)}
        end
    end

    return {success = false, error = "Unknown alpha action: " .. tostring(action)}
end

-- Pre-game phase actions (splash, title, setup, loading)
function ActionHandler:executeAlphaPhaseAction(alpha, phase, action, params)
    if phase == "splash" then
        if action == "skip_splash" then
            -- Simulate key press to skip
            if alpha.mSplash and alpha.mSplash.Skip then
                alpha.mSplash:Skip()
                return {success = true, action = "splash_skipped"}
            end
            alpha:OnSplashComplete()
            return {success = true, action = "splash_skipped"}
        end
    elseif phase == "title" then
        if action == "new_game" then
            alpha:OnNewGame()
            return {success = true, action = "new_game_started", phase = alpha.mPhase}
        elseif action == "continue_game" then
            alpha:OnContinue()
            return {success = true, action = "continue_game"}
        elseif action == "load_game" then
            alpha:OnLoadGame()
            return {success = true, action = "load_game_opened"}
        elseif action == "quit" or action == "return_to_launcher" then
            alpha:OnQuit()
            return {success = true, action = "quit"}
        end
    elseif phase == "setup" then
        if action == "cancel_setup" then
            alpha:OnSetupCancel()
            return {success = true, action = "setup_cancelled"}
        elseif action == "start_game" then
            -- Start with default config
            local config = {
                townName = params.town_name or "Cravetown",
                difficulty = params.difficulty or "normal",
                location = params.location or "fertile_plains"
            }
            alpha:OnSetupComplete(config)
            return {success = true, action = "game_starting", config = config}
        elseif action == "set_town_name" then
            if alpha.mNewGameSetup then
                alpha.mNewGameSetup.townName = params.name or "Cravetown"
                return {success = true, town_name = alpha.mNewGameSetup.townName}
            end
        end
    elseif phase == "loading" or phase == "worldloading" then
        return {success = false, error = "Cannot perform actions while loading"}
    end

    return {success = false, error = "Unknown phase action: " .. tostring(action) .. " for phase: " .. phase}
end

-- Time controls
function ActionHandler:alphaPause(world)
    world:Pause()
    self.bridge.eventLogger:log("alpha_paused", {})
    return {success = true, paused = true}
end

function ActionHandler:alphaResume(world)
    world:Resume()
    self.bridge.eventLogger:log("alpha_resumed", {})
    return {success = true, paused = false}
end

function ActionHandler:alphaTogglePause(world)
    local isPaused = world:TogglePause()
    return {success = true, paused = isPaused}
end

function ActionHandler:alphaSetSpeed(world, params)
    local speed = params.speed or 1
    -- Map speed values to TimeManager speed names
    local speedMap = {
        [1] = "normal",   -- 1x
        [2] = "fast",     -- 2x
        [3] = "faster",   -- 5x
        [4] = "fastest",  -- 10x
        [5] = "turbo"     -- 20x
    }
    local speedName = speedMap[speed] or "normal"
    world:SetTimeScale(speedName)
    return {success = true, speed = speed, speedName = speedName}
end

-- Camera actions
function ActionHandler:alphaMoveCamera(ui, params)
    if not ui then return {success = false, error = "UI not available"} end

    local x = params.x
    local y = params.y

    if not x or not y then
        return {success = false, error = "x and y are required"}
    end

    ui.cameraX = x
    ui.cameraY = y
    return {success = true, x = x, y = y}
end

function ActionHandler:alphaMoveCameraBy(ui, params)
    if not ui then return {success = false, error = "UI not available"} end

    local dx = params.dx or 0
    local dy = params.dy or 0

    ui.cameraX = (ui.cameraX or 0) + dx
    ui.cameraY = (ui.cameraY or 0) + dy

    return {success = true, new_x = ui.cameraX, new_y = ui.cameraY}
end

function ActionHandler:alphaZoomCamera(ui, params)
    if not ui then return {success = false, error = "UI not available"} end

    local scale = params.scale or 1.0
    ui.cameraZoom = math.max(0.25, math.min(4.0, scale))

    return {success = true, zoom = ui.cameraZoom}
end

-- Building placement
function ActionHandler:alphaStartBuildingPlacement(world, ui, params)
    local buildingTypeId = params.building_type

    if not buildingTypeId then
        return {success = false, error = "building_type is required"}
    end

    -- Find building type
    local buildingType = world.buildingTypesById[buildingTypeId]
    if not buildingType then
        return {success = false, error = "Unknown building type: " .. tostring(buildingTypeId)}
    end

    -- Check affordability
    local canAfford, affordError = world:CanAffordBuilding(buildingType)
    if not canAfford then
        return {success = false, error = affordError}
    end

    -- Set placement mode in UI
    if ui then
        ui.placementMode = true
        ui.placementBuildingType = buildingType
        ui.placementX = ui.cameraX or 0
        ui.placementY = ui.cameraY or 0
        ui.placementValid = true
    end

    self.bridge.eventLogger:log("alpha_placement_started", {building_type = buildingTypeId})

    return {success = true, building_type = buildingTypeId, mode = "placement"}
end

function ActionHandler:alphaPlaceBuilding(world, ui, params)
    local x = params.x
    local y = params.y

    -- If in placement mode, use the selected building type
    if ui and ui.placementMode and ui.placementBuildingType then
        local buildingType = ui.placementBuildingType

        -- Use provided coordinates or current placement position
        x = x or ui.placementX
        y = y or ui.placementY

        if not x or not y then
            return {success = false, error = "x and y are required"}
        end

        -- Validate and place
        local building, errors = world:PlaceBuilding(buildingType, x, y)

        -- Exit placement mode
        ui.placementMode = false
        ui.placementBuildingType = nil

        if building then
            self.bridge.eventLogger:log("alpha_building_placed", {
                building_id = building.id,
                building_type = buildingType.id,
                x = x, y = y
            })
            return {
                success = true,
                building_id = building.id,
                building_type = buildingType.id,
                x = x, y = y,
                efficiency = building.resourceEfficiency
            }
        else
            return {success = false, error = table.concat(errors or {"Unknown placement error"}, ", ")}
        end
    end

    -- Direct placement without UI mode
    local buildingTypeId = params.building_type
    if not buildingTypeId then
        return {success = false, error = "building_type is required (not in placement mode)"}
    end

    local buildingType = world.buildingTypesById[buildingTypeId]
    if not buildingType then
        return {success = false, error = "Unknown building type: " .. tostring(buildingTypeId)}
    end

    if not x or not y then
        return {success = false, error = "x and y are required"}
    end

    local building, errors = world:PlaceBuilding(buildingType, x, y)
    if building then
        self.bridge.eventLogger:log("alpha_building_placed", {
            building_id = building.id,
            building_type = buildingTypeId,
            x = x, y = y
        })
        return {
            success = true,
            building_id = building.id,
            building_type = buildingTypeId,
            x = x, y = y,
            efficiency = building.resourceEfficiency
        }
    else
        return {success = false, error = table.concat(errors or {"Unknown placement error"}, ", ")}
    end
end

function ActionHandler:alphaCancelPlacement(ui)
    if not ui then return {success = false, error = "UI not available"} end

    ui.placementMode = false
    ui.placementBuildingType = nil

    return {success = true, action = "placement_cancelled"}
end

-- Worker management
function ActionHandler:alphaAssignWorker(world, params)
    local citizenId = params.citizen_id
    local buildingId = params.building_id

    if not citizenId or not buildingId then
        return {success = false, error = "citizen_id and building_id are required"}
    end

    -- Find citizen
    local citizen = nil
    for _, c in ipairs(world.citizens or {}) do
        if c.id == citizenId then
            citizen = c
            break
        end
    end

    if not citizen then
        return {success = false, error = "Citizen not found: " .. tostring(citizenId)}
    end

    -- Find building
    local building = nil
    for _, b in ipairs(world.buildings or {}) do
        if b.id == buildingId then
            building = b
            break
        end
    end

    if not building then
        return {success = false, error = "Building not found: " .. tostring(buildingId)}
    end

    -- Assign worker
    local success = world:AssignWorkerToBuilding(citizen, building)
    if success then
        self.bridge.eventLogger:log("alpha_worker_assigned", {
            citizen_id = citizenId,
            building_id = buildingId
        })
        return {success = true, citizen_id = citizenId, building_id = buildingId}
    else
        return {success = false, error = "Failed to assign worker (building may be full)"}
    end
end

function ActionHandler:alphaRemoveWorker(world, params)
    local citizenId = params.citizen_id

    if not citizenId then
        return {success = false, error = "citizen_id is required"}
    end

    -- Find citizen
    for _, citizen in ipairs(world.citizens or {}) do
        if citizen.id == citizenId then
            if citizen.workplace then
                local oldWorkplace = citizen.workplace
                -- Remove from workers list
                for i, w in ipairs(oldWorkplace.workers or {}) do
                    if w.id == citizenId then
                        table.remove(oldWorkplace.workers, i)
                        break
                    end
                end
                citizen.workplace = nil
                citizen.workStation = nil

                self.bridge.eventLogger:log("alpha_worker_removed", {
                    citizen_id = citizenId,
                    building_id = oldWorkplace.id
                })
                return {success = true, citizen_id = citizenId, old_workplace = oldWorkplace.id}
            else
                return {success = false, error = "Citizen is not employed"}
            end
        end
    end

    return {success = false, error = "Citizen not found: " .. tostring(citizenId)}
end

-- Recipe management
function ActionHandler:alphaAssignRecipe(world, params)
    local buildingId = params.building_id
    local stationIndex = params.station_index or 1
    local recipeId = params.recipe_id

    if not buildingId or not recipeId then
        return {success = false, error = "building_id and recipe_id are required"}
    end

    -- Find building
    local building = nil
    for _, b in ipairs(world.buildings or {}) do
        if b.id == buildingId then
            building = b
            break
        end
    end

    if not building then
        return {success = false, error = "Building not found: " .. tostring(buildingId)}
    end

    -- Assign recipe
    local success = world:AssignRecipeToStation(building, stationIndex, recipeId)
    if success then
        self.bridge.eventLogger:log("alpha_recipe_assigned", {
            building_id = buildingId,
            station_index = stationIndex,
            recipe_id = recipeId
        })
        return {success = true, building_id = buildingId, station_index = stationIndex, recipe_id = recipeId}
    else
        return {success = false, error = "Failed to assign recipe"}
    end
end

-- Housing management
function ActionHandler:alphaAssignHousing(world, params)
    local citizenId = params.citizen_id
    local buildingId = params.building_id

    if not citizenId or not buildingId then
        return {success = false, error = "citizen_id and building_id are required"}
    end

    if not world.housingSystem then
        return {success = false, error = "Housing system not available"}
    end

    local success = world.housingSystem:AssignHousing(citizenId, buildingId)
    if success then
        self.bridge.eventLogger:log("alpha_housing_assigned", {
            citizen_id = citizenId,
            building_id = buildingId
        })
        return {success = true, citizen_id = citizenId, building_id = buildingId}
    else
        return {success = false, error = "Failed to assign housing (building may be full or incompatible)"}
    end
end

function ActionHandler:alphaUnassignHousing(world, params)
    local citizenId = params.citizen_id

    if not citizenId then
        return {success = false, error = "citizen_id is required"}
    end

    if not world.housingSystem then
        return {success = false, error = "Housing system not available"}
    end

    local success = world.housingSystem:UnassignHousing(citizenId)
    if success then
        self.bridge.eventLogger:log("alpha_housing_unassigned", {citizen_id = citizenId})
        return {success = true, citizen_id = citizenId}
    else
        return {success = false, error = "Failed to unassign housing"}
    end
end

-- Immigration
function ActionHandler:alphaAcceptImmigrant(world, params)
    local index = params.index or 1

    if not world.immigrationSystem then
        return {success = false, error = "Immigration system not available"}
    end

    local queue = world.immigrationSystem.queue or {}
    if #queue == 0 then
        return {success = false, error = "No immigrants in queue"}
    end

    if index < 1 or index > #queue then
        return {success = false, error = "Invalid index: " .. tostring(index)}
    end

    local applicant = queue[index]
    table.remove(queue, index)

    -- Create citizen from applicant
    local citizen = world:AddCitizen(applicant.class, applicant.name, applicant.traits, {
        vocation = applicant.vocation,
        startingWealth = applicant.startingWealth or 0
    })

    if citizen then
        world.stats.totalImmigrations = (world.stats.totalImmigrations or 0) + 1
        self.bridge.eventLogger:log("alpha_immigrant_accepted", {
            citizen_id = citizen.id,
            name = citizen.name
        })
        return {success = true, citizen_id = citizen.id, name = citizen.name}
    else
        return {success = false, error = "Failed to create citizen"}
    end
end

function ActionHandler:alphaRejectImmigrant(world, params)
    local index = params.index or 1

    if not world.immigrationSystem then
        return {success = false, error = "Immigration system not available"}
    end

    local queue = world.immigrationSystem.queue or {}
    if #queue == 0 then
        return {success = false, error = "No immigrants in queue"}
    end

    if index < 1 or index > #queue then
        return {success = false, error = "Invalid index: " .. tostring(index)}
    end

    local applicant = queue[index]
    table.remove(queue, index)

    self.bridge.eventLogger:log("alpha_immigrant_rejected", {name = applicant.name})
    return {success = true, name = applicant.name, action = "rejected"}
end

-- Inventory management
function ActionHandler:alphaAddResource(world, params)
    local commodityId = params.commodity_id or params.commodity
    local amount = params.amount or 1

    if not commodityId then
        return {success = false, error = "commodity_id is required"}
    end

    world:AddToInventory(commodityId, amount)

    self.bridge.eventLogger:log("alpha_resource_added", {
        commodity = commodityId,
        amount = amount
    })

    return {success = true, commodity = commodityId, amount = amount, new_total = world.inventory[commodityId]}
end

function ActionHandler:alphaRemoveResource(world, params)
    local commodityId = params.commodity_id or params.commodity
    local amount = params.amount or 1

    if not commodityId then
        return {success = false, error = "commodity_id is required"}
    end

    local removed = world:RemoveFromInventory(commodityId, amount)

    return {success = true, commodity = commodityId, amount_removed = removed, remaining = world.inventory[commodityId] or 0}
end

function ActionHandler:alphaAddGold(world, params)
    local amount = params.amount or 100

    world.gold = (world.gold or 0) + amount

    self.bridge.eventLogger:log("alpha_gold_added", {amount = amount})

    return {success = true, amount = amount, new_total = world.gold}
end

-- Selection
function ActionHandler:alphaSelectBuilding(world, params)
    local buildingId = params.building_id

    if not buildingId then
        return {success = false, error = "building_id is required"}
    end

    for _, building in ipairs(world.buildings or {}) do
        if building.id == buildingId then
            world:SelectEntity(building, "building")
            return {success = true, selected = buildingId, type = "building"}
        end
    end

    return {success = false, error = "Building not found: " .. tostring(buildingId)}
end

function ActionHandler:alphaSelectCitizen(world, params)
    local citizenId = params.citizen_id

    if not citizenId then
        return {success = false, error = "citizen_id is required"}
    end

    for _, citizen in ipairs(world.citizens or {}) do
        if citizen.id == citizenId then
            world:SelectEntity(citizen, "citizen")
            return {success = true, selected = citizenId, type = "citizen"}
        end
    end

    return {success = false, error = "Citizen not found: " .. tostring(citizenId)}
end

function ActionHandler:alphaClearSelection(world)
    world:ClearSelection()
    return {success = true, action = "selection_cleared"}
end

-- UI toggles
function ActionHandler:alphaToggleInventory(ui)
    if not ui then return {success = false, error = "UI not available"} end
    ui.showInventoryPanel = not ui.showInventoryPanel
    return {success = true, show_inventory = ui.showInventoryPanel}
end

function ActionHandler:alphaToggleBuildMenu(ui)
    if not ui then return {success = false, error = "UI not available"} end
    ui.showBuildMenuModal = not ui.showBuildMenuModal
    return {success = true, show_build_menu = ui.showBuildMenuModal}
end

function ActionHandler:alphaToggleCitizens(ui)
    if not ui then return {success = false, error = "UI not available"} end
    ui.showCitizensPanel = not ui.showCitizensPanel
    return {success = true, show_citizens = ui.showCitizensPanel}
end

function ActionHandler:alphaToggleImmigration(ui)
    if not ui then return {success = false, error = "UI not available"} end
    ui.showImmigrationModal = not ui.showImmigrationModal
    return {success = true, show_immigration = ui.showImmigrationModal}
end

function ActionHandler:alphaToggleHelp(ui)
    if not ui then return {success = false, error = "UI not available"} end
    ui.showHelpOverlay = not ui.showHelpOverlay
    return {success = true, show_help = ui.showHelpOverlay}
end

function ActionHandler:alphaCloseAllPanels(ui)
    if not ui then return {success = false, error = "UI not available"} end

    ui.showInventoryPanel = false
    ui.showBuildMenuModal = false
    ui.showCitizensPanel = false
    ui.showImmigrationModal = false
    ui.showHelpOverlay = false
    ui.showAnalyticsPanel = false
    ui.showSettingsPanel = false
    ui.placementMode = false

    return {success = true, action = "all_panels_closed"}
end

-- Save/Load
function ActionHandler:alphaQuickSave(world)
    local saveData = world:Serialize()
    local content = require("code.json").encode(saveData)
    local success, err = love.filesystem.write("quicksave.json", content)

    if success then
        self.bridge.eventLogger:log("alpha_quick_saved", {})
        return {success = true, action = "quick_saved"}
    else
        return {success = false, error = "Failed to save: " .. tostring(err)}
    end
end

function ActionHandler:alphaQuickLoad(alpha)
    local content = love.filesystem.read("quicksave.json")
    if not content then
        return {success = false, error = "No quicksave file found"}
    end

    local ok, saveData = pcall(function()
        return require("code.json").decode(content)
    end)

    if ok and saveData then
        alpha:StartGameFromSave(saveData)
        self.bridge.eventLogger:log("alpha_quick_loaded", {})
        return {success = true, action = "quick_loaded"}
    else
        return {success = false, error = "Failed to parse save file"}
    end
end

-- Testing/Debug actions
function ActionHandler:alphaAddCitizen(world, params)
    local class = params.class or "middle"
    local name = params.name
    local traits = params.traits
    local vocation = params.vocation

    local citizen = world:AddCitizen(class, name, traits, {
        vocation = vocation,
        startingWealth = params.starting_wealth or 0
    })

    if citizen then
        self.bridge.eventLogger:log("alpha_citizen_added", {
            citizen_id = citizen.id,
            name = citizen.name,
            class = citizen.class
        })
        return {
            success = true,
            citizen_id = citizen.id,
            name = citizen.name,
            class = citizen.class
        }
    else
        return {success = false, error = "Failed to add citizen"}
    end
end

function ActionHandler:alphaRemoveCitizen(world, params)
    local citizenId = params.citizen_id
    local reason = params.reason or "removed"

    if not citizenId then
        return {success = false, error = "citizen_id is required"}
    end

    for _, citizen in ipairs(world.citizens or {}) do
        if citizen.id == citizenId then
            local success = world:RemoveCitizen(citizen, reason)
            if success then
                self.bridge.eventLogger:log("alpha_citizen_removed", {citizen_id = citizenId})
                return {success = true, citizen_id = citizenId}
            end
        end
    end

    return {success = false, error = "Citizen not found: " .. tostring(citizenId)}
end

function ActionHandler:alphaAdvanceTime(world, params)
    local ticks = params.ticks or 60  -- Default to 1 second at 60fps
    local dt = 1/60

    for i = 1, ticks do
        world:Update(dt)
    end

    self.bridge.frameCount = self.bridge.frameCount + ticks

    return {
        success = true,
        ticks_advanced = ticks,
        day = world.timeManager:GetDay(),
        hour = world.timeManager:GetHour(),
        slot = world.timeManager:GetCurrentSlotId()
    }
end

function ActionHandler:alphaRunFreeAgency(world)
    world:RunFreeAgency()
    return {success = true, action = "free_agency_completed"}
end

return ActionHandler
