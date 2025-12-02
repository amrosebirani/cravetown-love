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

return ActionHandler
