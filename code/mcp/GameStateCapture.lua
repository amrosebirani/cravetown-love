--
-- GameStateCapture.lua - Captures and serializes game state for MCP
-- Provides comprehensive snapshots of the game for AI observation
--

local GameStateCapture = {}
GameStateCapture.__index = GameStateCapture

function GameStateCapture:init(bridge)
    local self = setmetatable({}, GameStateCapture)
    self.bridge = bridge
    return self
end

-- Main capture function - returns full or partial game state
function GameStateCapture:capture(params)
    params = params or {}
    local include = params.include or {"all"}
    local depth = params.depth or "summary"

    local state = {
        frame = self.bridge.frameCount,
        timestamp = love.timer.getTime(),
        dt = love.timer.getDelta(),
        mode = gMode or "unknown",
        game_speed = self.bridge.gameSpeed,
        paused = self.bridge.paused
    }

    local includeAll = self:hasInclude(include, "all")

    -- Special handling for consumption prototype mode (test_cache)
    if gMode == "test_cache" and gTestCache and gTestCache.prototype then
        return self:captureConsumptionPrototype(params, includeAll, depth)
    end

    -- Special handling for alpha prototype mode
    if gMode == "alpha" and gAlphaPrototype then
        return self:captureAlphaPrototype(params, includeAll, depth)
    end

    -- Screen info
    if includeAll or self:hasInclude(include, "screen") then
        state.screen = self:captureScreen()
    end

    -- Town state
    if includeAll or self:hasInclude(include, "town") then
        state.town = self:captureTown(depth)
    end

    -- Camera state
    if includeAll or self:hasInclude(include, "camera") then
        state.camera = self:captureCamera()
    end

    -- Buildings
    if includeAll or self:hasInclude(include, "buildings") then
        state.buildings = self:captureBuildings(depth, params.building_filter)
    end

    -- Characters
    if includeAll or self:hasInclude(include, "characters") then
        state.characters = self:captureCharacters(depth)
    end

    -- Inventory
    if includeAll or self:hasInclude(include, "inventory") then
        state.inventory = self:captureInventory()
    end

    -- UI State
    if includeAll or self:hasInclude(include, "ui_state") then
        state.ui_state = self:captureUIState()
    end

    -- Available actions
    if includeAll or self:hasInclude(include, "available_actions") then
        state.available_actions = self:captureAvailableActions()
    end

    -- Events since last capture
    if includeAll or self:hasInclude(include, "events") then
        state.events_since_last = self.bridge.eventLogger:getRecentEvents()
    end

    -- Metrics
    if includeAll or self:hasInclude(include, "metrics") then
        state.metrics = self:captureMetrics()
    end

    -- Controls reference
    if self:hasInclude(include, "controls") then
        state.controls = self:getControlsReference()
    end

    return state
end

function GameStateCapture:hasInclude(include, key)
    for _, v in ipairs(include) do
        if v == key then return true end
    end
    return false
end

function GameStateCapture:captureScreen()
    return {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight(),
        fullscreen = love.window.getFullscreen()
    }
end

function GameStateCapture:captureTown(depth)
    if not gTown then return nil end

    local town = {
        name = gTown.mName or "Unknown",
        bounds = {
            minX = gTown.mMinX or -1250,
            maxX = gTown.mMaxX or 1250,
            minY = gTown.mMinY or -1250,
            maxY = gTown.mMaxY or 1250
        },
        building_count = gTown.mBuildings and #gTown.mBuildings or 0
    }

    if depth == "full" then
        -- Add more detail for full depth
        town.has_river = gTown.mRiver ~= nil
        town.has_forest = gTown.mForest ~= nil
        town.has_mountains = gTown.mMountains ~= nil
        town.has_mines = gTown.mMines ~= nil
    end

    return town
end

function GameStateCapture:captureCamera()
    if not gCamera then return nil end

    local cam = {
        x = gCamera.x or 0,
        y = gCamera.y or 0,
        scale = gCamera.scale or 1.0,
        width = gCamera.w or love.graphics.getWidth(),
        height = gCamera.h or love.graphics.getHeight()
    }

    -- Add visible world bounds
    cam.visible_bounds = {
        left = cam.x - cam.width / 2 / cam.scale,
        right = cam.x + cam.width / 2 / cam.scale,
        top = cam.y - cam.height / 2 / cam.scale,
        bottom = cam.y + cam.height / 2 / cam.scale
    }

    return cam
end

function GameStateCapture:captureBuildings(depth, filter)
    if not gTown or not gTown.mBuildings then return {} end

    local buildings = {}
    for i, building in ipairs(gTown.mBuildings) do
        local b = self:captureBuilding(building, i, depth)

        -- Apply filter if provided
        if filter then
            local include = true
            if filter.type and b.type ~= filter.type then
                include = false
            end
            if filter.placed ~= nil and b.placed ~= filter.placed then
                include = false
            end
            if include then
                table.insert(buildings, b)
            end
        else
            table.insert(buildings, b)
        end
    end

    return buildings
end

function GameStateCapture:captureBuilding(building, id, depth)
    local typeId = building.mTypeId or (building.mBuildingType and building.mBuildingType.id) or "unknown"

    local b = {
        id = id,
        type = typeId,
        name = building.mName or "Unknown",
        x = building.mX or 0,
        y = building.mY or 0,
        width = building.mWidth or 0,
        height = building.mHeight or 0,
        placed = building.mPlaced or false
    }

    if depth ~= "minimal" then
        -- Workers
        b.workers = {}
        b.worker_count = 0
        if building.mWorkers then
            b.worker_count = #building.mWorkers
            for _, worker in ipairs(building.mWorkers) do
                table.insert(b.workers, worker.mName or "Unknown")
            end
        end

        -- Worker capacity
        if building.mBuildingType then
            b.max_workers = building.mBuildingType.maxWorkers or 0
        end

        -- Production state
        if building.mProductionTimer then
            b.production = {
                active = building.mProductionTimer > 0,
                timer = building.mProductionTimer
            }
        end

        -- Bakery specific
        if building.mBakery then
            b.bakery = {
                active = building.mBakery.active or false,
                timer = building.mBakery.timer or 0,
                wheat_per_bread = building.mBakery.wheatPerBread or 5,
                interval_sec = building.mBakery.intervalSec or 120
            }
        end

        -- Farm grain type
        if building.mProducedGrain then
            b.grain_type = building.mProducedGrain
        end

        -- Mine resource type
        if building.mMineResource then
            b.mine_resource = building.mMineResource
        end
    end

    if depth == "full" then
        -- Add building type info
        if building.mBuildingType then
            local bt = building.mBuildingType
            b.building_type_info = {
                label = bt.label,
                color = bt.color,
                variable_size = bt.variableSize or false
            }
            if bt.constructionMaterials then
                b.construction_materials = bt.constructionMaterials
            end
        end
    end

    return b
end

function GameStateCapture:captureCharacters(depth)
    local characters = {}
    local seen = {}  -- Track seen characters to avoid duplicates

    -- Check if there's a global character list
    if gCharacters then
        for i, char in ipairs(gCharacters) do
            local charData = self:captureCharacter(char, i, depth)
            if not seen[charData.name] then
                table.insert(characters, charData)
                seen[charData.name] = true
            end
        end
    end

    -- Also collect from building workers
    if gTown and gTown.mBuildings then
        for _, building in ipairs(gTown.mBuildings) do
            if building.mWorkers then
                for _, worker in ipairs(building.mWorkers) do
                    local name = worker.mName or "Unknown"
                    if not seen[name] then
                        table.insert(characters, self:captureCharacter(worker, nil, depth))
                        seen[name] = true
                    end
                end
            end
        end
    end

    return characters
end

function GameStateCapture:captureCharacter(char, id, depth)
    local c = {
        id = id or char.mId or char.mName or "unknown",
        name = char.mName or "Unknown",
        type = char.mType or "unknown"
    }

    if depth ~= "minimal" then
        c.age = char.mAge
        c.gender = char.mGender
        c.role = char.mRole
        c.class = char.mClass
        c.status = char.mStatus
        c.placed = char.mPlaced

        -- Workplace reference
        if char.mWorkplace then
            c.workplace = char.mWorkplace.mName or "Unknown"
        end
    end

    if depth == "full" then
        c.diet = char.mDiet
        c.money = char.mMoney
        c.children = char.mChildren

        -- Include craving data if available (CharacterV2)
        if char.getCravings then
            c.cravings = char:getCravings()
        elseif char.mCravings then
            c.cravings = {}
            for name, craving in pairs(char.mCravings) do
                c.cravings[name] = {
                    current = craving.current or 0,
                    base = craving.base or 0
                }
            end
        end
    end

    return c
end

function GameStateCapture:captureInventory()
    if not gTown or not gTown.mInventory then return {} end

    local inv = {}

    -- Get all stored items
    if gTown.mInventory.mStorage then
        for key, value in pairs(gTown.mInventory.mStorage) do
            inv[key] = value
        end
    end

    return inv
end

function GameStateCapture:captureUIState()
    local ui = {
        mode = gMode or "unknown",
        active_state = "unknown",
        state_stack = {},
        modal_open = false,
        modal_name = nil
    }

    -- Get active state machine state
    if gStateMachine and gStateMachine.mCurrentStateName then
        ui.active_state = gStateMachine.mCurrentStateName
    end

    -- Get state stack
    if gStateStack and gStateStack.mStates then
        for i, state in ipairs(gStateStack.mStates) do
            local stateName = "unknown"
            -- Try to determine state name
            if state.__name then
                stateName = state.__name
            elseif state.mName then
                stateName = state.mName
            else
                -- Check known state types
                if TopBar and getmetatable(state) == TopBar then
                    stateName = "TopBar"
                elseif BuildingMenu and getmetatable(state) == BuildingMenu then
                    stateName = "BuildingMenu"
                elseif TownNameModal and getmetatable(state) == TownNameModal then
                    stateName = "TownNameModal"
                    ui.modal_open = true
                    ui.modal_name = "TownNameModal"
                elseif GrainSelectionModal and getmetatable(state) == GrainSelectionModal then
                    stateName = "GrainSelectionModal"
                    ui.modal_open = true
                    ui.modal_name = "GrainSelectionModal"
                elseif BakerySetupModal and getmetatable(state) == BakerySetupModal then
                    stateName = "BakerySetupModal"
                    ui.modal_open = true
                    ui.modal_name = "BakerySetupModal"
                elseif MineSelectionModal and getmetatable(state) == MineSelectionModal then
                    stateName = "MineSelectionModal"
                    ui.modal_open = true
                    ui.modal_name = "MineSelectionModal"
                elseif InventoryDrawer and getmetatable(state) == InventoryDrawer then
                    stateName = "InventoryDrawer"
                elseif CharacterMenu and getmetatable(state) == CharacterMenu then
                    stateName = "CharacterMenu"
                end
            end
            table.insert(ui.state_stack, stateName)
        end
    end

    -- Building placement state info
    if gStateMachine and gStateMachine.mCurrentStateName == "BuildingPlacement" then
        local placementState = gStateMachine.mCurrentState
        if placementState and placementState.mBuildingToPlace then
            local b = placementState.mBuildingToPlace
            ui.placement = {
                building_type = b.mTypeId or (b.mBuildingType and b.mBuildingType.id) or "unknown",
                x = b.mX,
                y = b.mY,
                width = b.mWidth,
                height = b.mHeight,
                can_place = placementState.mCanPlace
            }
        end
    end

    return ui
end

function GameStateCapture:captureAvailableActions()
    local actions = {}

    -- Always available
    table.insert(actions, {action = "move_camera", description = "Move camera with WASD or arrow keys"})

    if gMode == "main" then
        if gStateMachine then
            if gStateMachine.mCurrentStateName == "TownView" then
                -- In town view, can start building placement
                table.insert(actions, {action = "start_building_placement", description = "Click a building in the menu to start placement"})
                table.insert(actions, {action = "open_menu", description = "Open inventory, stats, or other menus from top bar"})

            elseif gStateMachine.mCurrentStateName == "BuildingPlacement" then
                table.insert(actions, {action = "place_building", description = "Left-click to place the building"})
                table.insert(actions, {action = "cancel_placement", description = "Right-click to cancel placement"})
                table.insert(actions, {action = "adjust_size", description = "Use WASD/arrows to adjust size (variable buildings)"})
            end
        end

        -- Check for modals
        if gStateStack and #gStateStack.mStates > 0 then
            local topState = gStateStack.mStates[#gStateStack.mStates]
            if TownNameModal and getmetatable(topState) == TownNameModal then
                table.insert(actions, {action = "set_town_name", description = "Type town name and press Enter"})
            elseif GrainSelectionModal and getmetatable(topState) == GrainSelectionModal then
                table.insert(actions, {action = "select_grain", description = "Click to select grain type for farm"})
            end
        end
    elseif gMode == "launcher" then
        table.insert(actions, {action = "start_game", description = "Click 'Main Game' to start"})
    elseif gMode == "version_select" then
        table.insert(actions, {action = "select_version", description = "Click a version to select it"})
    end

    return actions
end

function GameStateCapture:captureMetrics()
    return {
        fps = love.timer.getFPS(),
        memory_kb = collectgarbage("count"),
        frame = self.bridge.frameCount,
        uptime = love.timer.getTime()
    }
end

function GameStateCapture:getControlsReference()
    return {
        global = {
            F5 = "Hot reload (development)",
            F11 = "Toggle fullscreen",
            ["Alt+Enter"] = "Toggle fullscreen",
            Escape = "Return to launcher / Cancel"
        },
        town_view = {
            W = "Move camera up",
            A = "Move camera left",
            S = "Move camera down",
            D = "Move camera right"
        },
        building_placement = {
            ["Left click"] = "Place building",
            ["Right click"] = "Cancel placement",
            W = "Increase height (variable buildings)",
            S = "Decrease height (variable buildings)",
            D = "Increase width (variable buildings)",
            A = "Decrease width (variable buildings)"
        },
        menus = {
            ["Left click"] = "Select option",
            ["Mouse wheel"] = "Scroll lists"
        }
    }
end

-- Query specific entities
function GameStateCapture:query(params)
    local queryType = params.query_type
    local id = params.id
    local filter = params.filter

    if queryType == "building" and id then
        if gTown and gTown.mBuildings and gTown.mBuildings[tonumber(id)] then
            return self:captureBuilding(gTown.mBuildings[tonumber(id)], tonumber(id), "full")
        end
        return {error = "Building not found: " .. tostring(id)}
    end

    if queryType == "available_buildings" then
        local types = {}
        if BuildingTypes and BuildingTypes.getAllTypes then
            for _, bt in ipairs(BuildingTypes.getAllTypes()) do
                local canAfford = true
                local materials = {}

                if bt.constructionMaterials and gTown and gTown.mInventory then
                    for commodityId, required in pairs(bt.constructionMaterials) do
                        local available = gTown.mInventory:Get(commodityId) or 0
                        materials[commodityId] = {required = required, available = available}
                        if available < required then
                            canAfford = false
                        end
                    end
                end

                table.insert(types, {
                    id = bt.id,
                    name = bt.name,
                    label = bt.label,
                    width = bt.width,
                    height = bt.height,
                    variable_size = bt.variableSize or false,
                    can_afford = canAfford,
                    materials = materials
                })
            end
        end
        return {building_types = types}
    end

    if queryType == "inventory_item" and id then
        if gTown and gTown.mInventory then
            return {
                item = id,
                quantity = gTown.mInventory:Get(id) or 0
            }
        end
    end

    if queryType == "available_actions" then
        return self:captureAvailableActions()
    end

    -- Consumption prototype queries
    if gMode == "test_cache" and gTestCache and gTestCache.prototype then
        return self:queryConsumptionPrototype(queryType, id, params)
    end

    -- Alpha prototype queries
    if gMode == "alpha" and gAlphaPrototype then
        return self:queryAlphaPrototype(queryType, id, params)
    end

    return {error = "Unknown query type: " .. tostring(queryType)}
end

-- ============================================================================
-- CONSUMPTION PROTOTYPE STATE CAPTURE
-- For game balance analysis and AI observation
-- ============================================================================

function GameStateCapture:captureConsumptionPrototype(params, includeAll, depth)
    local proto = gTestCache.prototype
    local include = params.include or {"all"}

    local state = {
        frame = self.bridge.frameCount,
        timestamp = love.timer.getTime(),
        mode = "consumption_prototype",

        -- Simulation state
        simulation = {
            cycle = proto.cycleNumber or 0,
            cycle_time = proto.cycleTime or 0,
            cycle_duration = proto.cycleDuration or 60,
            is_paused = proto.isPaused,
            speed = proto.simulationSpeed or 1.0
        }
    }

    -- Statistics (always include - critical for balance analysis)
    if includeAll or self:hasInclude(include, "statistics") or self:hasInclude(include, "stats") then
        state.statistics = self:captureConsumptionStats(proto)
    end

    -- Characters
    if includeAll or self:hasInclude(include, "characters") then
        state.characters = self:captureConsumptionCharacters(proto, depth)
    end

    -- Inventory
    if includeAll or self:hasInclude(include, "inventory") then
        state.inventory = proto.townInventory or {}
        state.inventory_total = proto:GetTotalInventoryCount()
    end

    -- Allocation policy
    if includeAll or self:hasInclude(include, "policy") then
        state.allocation_policy = proto.allocationPolicy
        state.policy_presets = {}
        if proto.policyPresets then
            for _, preset in ipairs(proto.policyPresets) do
                table.insert(state.policy_presets, {
                    name = preset.name,
                    description = preset.description
                })
            end
        end
    end

    -- Historical data (for trend analysis)
    if includeAll or self:hasInclude(include, "history") then
        state.history = {
            satisfaction = proto.satisfactionHistory or {},
            population = proto.populationHistory or {},
            max_cycles_tracked = proto.historyMaxCycles or 20
        }
    end

    -- Event log
    if includeAll or self:hasInclude(include, "events") then
        state.event_log = {}
        local maxEvents = params.max_events or 50
        local startIdx = math.max(1, #(proto.eventLog or {}) - maxEvents + 1)
        for i = startIdx, #(proto.eventLog or {}) do
            table.insert(state.event_log, proto.eventLog[i])
        end
    end

    -- UI state
    if includeAll or self:hasInclude(include, "ui_state") then
        state.ui_state = {
            current_view = proto.currentView,
            selected_character = proto.selectedCharacter and proto.selectedCharacter.name or nil,
            modals_open = {
                character_creator = proto.showCharacterCreator,
                resource_injector = proto.showResourceInjector,
                inventory = proto.showInventoryModal,
                heatmap = proto.showHeatmapModal,
                character_detail = proto.showCharacterDetailModal,
                analytics = proto.showAnalyticsModal,
                allocation_policy = proto.showAllocationPolicyModal,
                testing_tools = proto.showTestingToolsModal,
                save_load = proto.showSaveLoadModal
            },
            any_modal_open = proto:IsAnyModalOpen()
        }
    end

    -- Available actions for this mode
    if includeAll or self:hasInclude(include, "available_actions") then
        state.available_actions = self:captureConsumptionActions(proto)
    end

    -- Controls reference
    if self:hasInclude(include, "controls") then
        state.controls = self:getConsumptionControlsReference()
    end

    -- Metrics
    if includeAll or self:hasInclude(include, "metrics") then
        state.metrics = {
            fps = love.timer.getFPS(),
            memory_kb = collectgarbage("count"),
            character_count = #(proto.characters or {}),
            active_character_count = proto:GetActiveCharacterCount()
        }
    end

    return state
end

function GameStateCapture:captureConsumptionStats(proto)
    local stats = proto.stats or {}
    return {
        -- Core statistics
        total_cycles = stats.totalCycles or 0,
        total_allocations = stats.totalAllocations or 0,
        total_emigrations = stats.totalEmigrations or 0,
        total_riots = stats.totalRiots or 0,

        -- Population
        total_population = stats.totalPopulation or #(proto.characters or {}),
        active_population = stats.activePopulation or 0,
        protesting_count = stats.protestingCount or 0,
        emigrated_count = stats.emigratedCount or 0,
        dissatisfied_count = stats.dissatisfiedCount or 0,
        stressed_count = stats.stressedCount or 0,

        -- Averages
        average_satisfaction = stats.averageSatisfaction or 0,
        productivity_multiplier = stats.productivityMultiplier or 1.0,

        -- By class breakdown
        by_class = stats.byClass or {}
    }
end

function GameStateCapture:captureConsumptionCharacters(proto, depth)
    local characters = {}

    for i, char in ipairs(proto.characters or {}) do
        local c = {
            id = i,
            name = char.name,
            class = char.class,
            age = char.age,
            vocation = char.vocation,
            traits = char.traits or {},

            -- Status
            status = char.status,
            status_message = char.statusMessage,
            is_protesting = char.isProtesting,
            has_emigrated = char.hasEmigrated,

            -- Key metrics
            average_satisfaction = char:GetAverageSatisfaction(),
            productivity = char.productivityMultiplier or 1.0,
            allocation_success_rate = char.allocationSuccessRate or 0,
            critical_craving_count = char:GetCriticalCravingCount()
        }

        if depth ~= "minimal" then
            -- Satisfaction by dimension (9D coarse)
            c.satisfaction = {}
            if char.satisfaction then
                for dim, value in pairs(char.satisfaction) do
                    c.satisfaction[dim] = value
                end
            end

            -- Coarse cravings (9D aggregated)
            c.coarse_cravings = char:AggregateCurrentCravingsToCoarse()

            -- Fairness penalty
            c.fairness_penalty = char.fairnessPenalty or 0
            c.consecutive_failed_allocations = char.consecutiveFailedAllocations or 0
            c.consecutive_low_satisfaction_cycles = char.consecutiveLowSatisfactionCycles or 0
        end

        if depth == "full" then
            -- Fine-grained cravings (49D) - stored as object with string keys for JSON compatibility
            c.current_cravings = {}
            if char.currentCravings then
                for idx = 0, 48 do
                    c.current_cravings[tostring(idx)] = char.currentCravings[idx] or 0
                end
            end

            -- Base cravings - stored as object with string keys for JSON compatibility
            c.base_cravings = {}
            if char.baseCravings then
                for idx = 0, 48 do
                    c.base_cravings[tostring(idx)] = char.baseCravings[idx] or 0
                end
            end

            -- Commodity multipliers (fatigue)
            c.commodity_multipliers = {}
            if char.commodityMultipliers then
                for commodity, data in pairs(char.commodityMultipliers) do
                    c.commodity_multipliers[commodity] = {
                        multiplier = data.multiplier,
                        consecutive_count = data.consecutiveCount,
                        last_consumed = data.lastConsumed
                    }
                end
            end

            -- Consumption history
            c.consumption_history = char.consumptionHistory or {}

            -- Enablement state
            c.enablement_state = char.enablementState or {}
        end

        table.insert(characters, c)
    end

    return characters
end

function GameStateCapture:captureConsumptionActions(proto)
    local actions = {}

    -- Simulation controls
    if proto.isPaused then
        table.insert(actions, {action = "resume_simulation", description = "Press SPACE to resume simulation"})
    else
        table.insert(actions, {action = "pause_simulation", description = "Press SPACE to pause simulation"})
    end
    table.insert(actions, {action = "set_simulation_speed", description = "Set speed (1x, 2x, 5x, 10x, 20x)"})
    table.insert(actions, {action = "skip_cycles", description = "Skip N cycles instantly"})

    -- Character management
    table.insert(actions, {action = "add_character", description = "Add a character with class/traits"})
    table.insert(actions, {action = "add_random_characters", description = "Add N random characters"})
    table.insert(actions, {action = "clear_all_characters", description = "Remove all characters"})

    -- Inventory management
    table.insert(actions, {action = "inject_resource", description = "Add commodities to inventory"})
    table.insert(actions, {action = "fill_basic_inventory", description = "Fill with basic goods"})
    table.insert(actions, {action = "fill_luxury_inventory", description = "Fill with luxury goods"})
    table.insert(actions, {action = "double_inventory", description = "Double all inventory"})
    table.insert(actions, {action = "clear_inventory", description = "Clear all inventory"})

    -- Policy changes
    table.insert(actions, {action = "set_allocation_policy", description = "Change allocation policy settings"})
    table.insert(actions, {action = "apply_policy_preset", description = "Apply a predefined policy preset"})

    -- Testing tools
    table.insert(actions, {action = "trigger_riot", description = "Force a riot event"})
    table.insert(actions, {action = "trigger_civil_unrest", description = "Force civil unrest"})
    table.insert(actions, {action = "trigger_mass_emigration", description = "Force mass emigration"})
    table.insert(actions, {action = "trigger_random_protest", description = "Random character protests"})
    table.insert(actions, {action = "set_all_satisfaction", description = "Set all characters to a satisfaction level"})
    table.insert(actions, {action = "randomize_all_satisfaction", description = "Randomize all satisfaction"})
    table.insert(actions, {action = "reset_all_cravings", description = "Reset all cravings to base"})
    table.insert(actions, {action = "reset_all_fatigue", description = "Reset commodity fatigue"})

    return actions
end

function GameStateCapture:getConsumptionControlsReference()
    return {
        simulation = {
            SPACE = "Pause/Resume simulation",
            ["1"] = "Set speed 1x",
            ["2"] = "Set speed 2x",
            ["3"] = "Set speed 5x",
            ["4"] = "Set speed 10x",
            ["5"] = "Set speed 20x"
        },
        navigation = {
            ["Arrow keys"] = "Navigate character selection",
            Enter = "Open character detail",
            Escape = "Close modal / Return to launcher"
        },
        shortcuts = {
            C = "Open character creator",
            I = "Open inventory",
            A = "Open analytics",
            P = "Open allocation policy",
            T = "Open testing tools",
            S = "Open save/load",
            H = "Toggle help overlay"
        }
    }
end

function GameStateCapture:queryConsumptionPrototype(queryType, id, params)
    local proto = gTestCache.prototype

    if queryType == "character" and id then
        -- Find character by ID or name
        for i, char in ipairs(proto.characters or {}) do
            if i == tonumber(id) or char.name == id then
                return self:captureConsumptionCharacters({prototype = proto, characters = {char}}, "full")[1]
            end
        end
        return {error = "Character not found: " .. tostring(id)}
    end

    if queryType == "allocation_log" then
        local limit = params.limit or 10
        local logs = {}
        local startIdx = math.max(1, #(proto.allocationHistory or {}) - limit + 1)
        for i = startIdx, #(proto.allocationHistory or {}) do
            table.insert(logs, proto.allocationHistory[i])
        end
        return {allocation_logs = logs, count = #logs}
    end

    if queryType == "dimension_definitions" then
        return {dimensions = proto.dimensionDefinitions or {}}
    end

    if queryType == "character_classes" then
        return {classes = proto.characterClasses or {}}
    end

    if queryType == "traits" then
        return {traits = proto.characterTraits or {}}
    end

    if queryType == "fulfillment_vectors" then
        return {vectors = proto.fulfillmentVectors or {}}
    end

    if queryType == "substitution_rules" then
        return {rules = proto.substitutionRules or {}}
    end

    if queryType == "consumption_mechanics" then
        return {mechanics = proto.consumptionMechanics or {}}
    end

    if queryType == "commodities" then
        return {commodities = proto.commodities or {}}
    end

    if queryType == "available_actions" then
        return self:captureConsumptionActions(proto)
    end

    return {error = "Unknown consumption query type: " .. tostring(queryType)}
end

-- ============================================================================
-- ALPHA PROTOTYPE STATE CAPTURE
-- For town building simulation with production and consumption
-- ============================================================================

function GameStateCapture:captureAlphaPrototype(params, includeAll, depth)
    local include = params.include or {"all"}
    local alpha = gAlphaPrototype
    local phase = alpha.mPhase

    local state = {
        frame = self.bridge.frameCount,
        timestamp = love.timer.getTime(),
        mode = "alpha_prototype",
        phase = phase  -- splash, title, setup, loading, worldloading, game
    }

    -- Only include full game state when in "game" phase
    if phase ~= "game" then
        state.available_actions = self:captureAlphaPhaseActions(phase)
        return state
    end

    local world = alpha.mWorld
    local ui = alpha.mUI

    if not world then
        state.error = "World not initialized"
        return state
    end

    -- Time state
    if includeAll or self:hasInclude(include, "time") or self:hasInclude(include, "simulation") then
        state.time = self:captureAlphaTime(world)
    end

    -- Town info
    if includeAll or self:hasInclude(include, "town") then
        state.town = self:captureAlphaTown(world)
    end

    -- Statistics
    if includeAll or self:hasInclude(include, "statistics") or self:hasInclude(include, "stats") then
        state.statistics = self:captureAlphaStats(world)
    end

    -- Camera state
    if includeAll or self:hasInclude(include, "camera") then
        state.camera = self:captureAlphaCamera(ui)
    end

    -- Buildings
    if includeAll or self:hasInclude(include, "buildings") then
        state.buildings = self:captureAlphaBuildings(world, depth)
    end

    -- Citizens/Characters
    if includeAll or self:hasInclude(include, "characters") or self:hasInclude(include, "citizens") then
        state.citizens = self:captureAlphaCitizens(world, depth)
    end

    -- Inventory
    if includeAll or self:hasInclude(include, "inventory") then
        state.inventory = world.inventory or {}
        state.gold = world.gold or 0
    end

    -- Housing system
    if includeAll or self:hasInclude(include, "housing") then
        state.housing = self:captureAlphaHousing(world)
    end

    -- Land system
    if includeAll or self:hasInclude(include, "land") then
        state.land = self:captureAlphaLand(world)
    end

    -- Immigration
    if includeAll or self:hasInclude(include, "immigration") then
        state.immigration = self:captureAlphaImmigration(world)
    end

    -- UI state
    if includeAll or self:hasInclude(include, "ui_state") then
        state.ui_state = self:captureAlphaUIState(ui)
    end

    -- Event log
    if includeAll or self:hasInclude(include, "events") then
        state.event_log = self:captureAlphaEventLog(world, params.max_events or 50)
    end

    -- Production metrics
    if includeAll or self:hasInclude(include, "production") then
        state.production = self:captureAlphaProduction(world)
    end

    -- Available actions
    if includeAll or self:hasInclude(include, "available_actions") then
        state.available_actions = self:captureAlphaActions(world, ui)
    end

    -- Controls reference
    if self:hasInclude(include, "controls") then
        state.controls = self:getAlphaControlsReference()
    end

    -- Metrics
    if includeAll or self:hasInclude(include, "metrics") then
        state.metrics = {
            fps = love.timer.getFPS(),
            memory_kb = collectgarbage("count"),
            citizen_count = #(world.citizens or {}),
            building_count = #(world.buildings or {})
        }
    end

    return state
end

function GameStateCapture:captureAlphaTime(world)
    local tm = world.timeManager
    if not tm then return nil end

    return {
        is_paused = world.isPaused,
        day = tm:GetDay(),
        hour = tm:GetHour(),
        time_string = tm:GetTimeString(),
        current_slot = tm:GetCurrentSlot() and tm:GetCurrentSlot().name or "Unknown",
        current_slot_id = tm:GetCurrentSlotId(),
        slot_progress = tm:GetSlotProgress(),
        speed = tm.currentSpeed or 1,
        global_slot_counter = world.globalSlotCounter or 1
    }
end

function GameStateCapture:captureAlphaTown(world)
    return {
        name = world.townName or "Unknown",
        gold = world.gold or 0,
        world_width = world.worldWidth,
        world_height = world.worldHeight,
        has_river = world.river ~= nil,
        has_forest = world.forest ~= nil,
        has_mountains = world.mountains ~= nil
    }
end

function GameStateCapture:captureAlphaStats(world)
    local stats = world.stats or {}
    return {
        total_population = stats.totalPopulation or #(world.citizens or {}),
        average_satisfaction = stats.averageSatisfaction or 0,
        satisfaction_by_class = stats.satisfactionByClass or {},
        housing_capacity = stats.housingCapacity or 0,
        employed_count = stats.employedCount or 0,
        unemployed_count = stats.unemployedCount or 0,
        homeless_count = stats.homelessCount or 0,
        housed_count = stats.housedCount or 0,
        total_emigrations = stats.totalEmigrations or 0,
        total_immigrations = stats.totalImmigrations or 0,
        productivity_multiplier = stats.productivityMultiplier or 1.0,
        current_slot_name = stats.currentSlotName or "Unknown"
    }
end

function GameStateCapture:captureAlphaCamera(ui)
    if not ui then return nil end

    return {
        x = ui.cameraX or 0,
        y = ui.cameraY or 0,
        zoom = ui.cameraZoom or 1.0,
        world_width = ui.worldWidth,
        world_height = ui.worldHeight
    }
end

function GameStateCapture:captureAlphaBuildings(world, depth)
    local buildings = {}

    for i, building in ipairs(world.buildings or {}) do
        local b = {
            id = building.id,
            index = i,
            type_id = building.typeId,
            name = building.name,
            x = building.x,
            y = building.y,
            level = building.level or 0
        }

        if depth ~= "minimal" then
            -- Worker info
            b.workers = {}
            b.worker_count = #(building.workers or {})
            b.max_workers = building.maxWorkers or 0
            for _, worker in ipairs(building.workers or {}) do
                table.insert(b.workers, {
                    id = worker.id,
                    name = worker.name
                })
            end

            -- Station/production info
            b.stations = {}
            for si, station in ipairs(building.stations or {}) do
                table.insert(b.stations, {
                    id = station.id or si,
                    state = station.state or "IDLE",
                    progress = station.progress or 0,
                    recipe = station.recipe and station.recipe.name or nil,
                    recipe_id = station.recipe and station.recipe.id or nil
                })
            end

            -- Housing info
            if building.capacity and building.capacity > 0 then
                b.is_housing = true
                b.capacity = building.capacity
                b.residents = #(building.residents or {})
                b.housing_class = building.housingClass
            end

            -- Efficiency
            b.resource_efficiency = building.resourceEfficiency or 1.0

            -- Storage
            b.storage_capacity = building.storageCapacity or 0
        end

        if depth == "full" then
            -- Building type info
            if building.type then
                b.category = building.type.category
                b.construction_cost = building.type.constructionCost
            end
            b.efficiency_breakdown = building.efficiencyBreakdown
        end

        table.insert(buildings, b)
    end

    return buildings
end

function GameStateCapture:captureAlphaCitizens(world, depth)
    local citizens = {}

    for i, citizen in ipairs(world.citizens or {}) do
        local c = {
            id = citizen.id,
            index = i,
            name = citizen.name,
            class = citizen.class,
            age = citizen.age,
            vocation = citizen.vocation
        }

        if depth ~= "minimal" then
            -- Position
            c.x = citizen.x
            c.y = citizen.y

            -- Satisfaction
            if citizen.GetAverageSatisfaction then
                c.average_satisfaction = citizen:GetAverageSatisfaction()
            end

            -- Employment
            c.workplace = citizen.workplace and citizen.workplace.name or nil
            c.workplace_id = citizen.workplace and citizen.workplace.id or nil
            c.is_employed = citizen.workplace ~= nil

            -- Housing (get from housing system if available)
            if world.housingSystem then
                local assignment = world.housingSystem:GetHousingAssignment(citizen.id)
                if assignment then
                    c.housing_id = assignment.buildingId
                    c.is_housed = assignment.buildingId ~= nil
                else
                    c.is_housed = false
                end
            end

            -- Traits
            c.traits = citizen.traits or {}

            -- Status indicators
            if citizen.GetCriticalCravingCount then
                c.critical_cravings = citizen:GetCriticalCravingCount()
            end
        end

        if depth == "full" then
            -- Detailed satisfaction breakdown
            if citizen.satisfaction then
                c.satisfaction_breakdown = {}
                for dim, value in pairs(citizen.satisfaction) do
                    c.satisfaction_breakdown[dim] = value
                end
            end

            -- Cravings
            if citizen.AggregateCurrentCravingsToCoarse then
                c.coarse_cravings = citizen:AggregateCurrentCravingsToCoarse()
            end

            -- Wealth (from economics system)
            if world.economicsSystem then
                c.wealth = world.economicsSystem:GetWealth(citizen.id) or 0
            end

            -- Possessions
            c.possessions = citizen.possessions or {}
        end

        table.insert(citizens, c)
    end

    return citizens
end

function GameStateCapture:captureAlphaHousing(world)
    if not world.housingSystem then return nil end

    local hs = world.housingSystem
    return {
        total_capacity = hs:GetTotalCapacity(),
        total_occupied = hs:GetTotalOccupied(),
        vacancy_rate = hs:GetVacancyRate(),
        homeless_count = hs:GetHomelessCount(),
        relocation_queue_size = hs:GetRelocationQueueSize()
    }
end

function GameStateCapture:captureAlphaLand(world)
    if not world.landSystem then return nil end

    local ls = world.landSystem
    return {
        grid_columns = ls.gridColumns,
        grid_rows = ls.gridRows,
        plot_width = ls.plotWidth,
        plot_height = ls.plotHeight,
        total_plots = ls.gridColumns * ls.gridRows
    }
end

function GameStateCapture:captureAlphaImmigration(world)
    if not world.immigrationSystem then return nil end

    local is = world.immigrationSystem
    local queue = is.queue or {}

    local applicants = {}
    for i, app in ipairs(queue) do
        table.insert(applicants, {
            index = i,
            name = app.name,
            class = app.class,
            vocation = app.vocation,
            traits = app.traits
        })
    end

    return {
        queue_size = #queue,
        applicants = applicants
    }
end

function GameStateCapture:captureAlphaUIState(ui)
    if not ui then return nil end

    return {
        -- Placement mode
        placement_mode = ui.placementMode or false,
        placement_building_type = ui.placementBuildingType and ui.placementBuildingType.id or nil,
        placement_valid = ui.placementValid,
        placement_efficiency = ui.placementEfficiency,

        -- Modals
        show_build_menu = ui.showBuildMenuModal or false,
        show_inventory = ui.showInventoryPanel or false,
        show_citizens_panel = ui.showCitizensPanel or false,
        show_analytics = ui.showAnalyticsPanel or false,
        show_immigration = ui.showImmigrationModal or false,
        show_land_registry = ui.showLandRegistryPanel or false,
        show_housing_overview = ui.showHousingOverviewPanel or false,
        show_help = ui.showHelpOverlay or false,
        show_settings = ui.showSettingsPanel or false,

        -- Resource overlay
        show_resource_overlay = ui.showResourceOverlay or false,

        -- Selected entity
        selected_entity_type = ui.world and ui.world.selectedEntityType or nil,
        selected_entity_id = ui.world and ui.world.selectedEntity and ui.world.selectedEntity.id or nil
    }
end

function GameStateCapture:captureAlphaEventLog(world, maxEvents)
    local events = {}
    local log = world.eventLog or {}
    local startIdx = math.max(1, #log - maxEvents + 1)

    for i = startIdx, #log do
        local e = log[i]
        if e then
            table.insert(events, {
                time = e.time,
                day = e.day,
                slot = e.slot,
                type = e.type,
                message = e.message,
                details = e.details
            })
        end
    end

    return events
end

function GameStateCapture:captureAlphaProduction(world)
    local production = {
        buildings_producing = 0,
        buildings_idle = 0,
        buildings_no_materials = 0,
        buildings_no_workers = 0
    }

    for _, building in ipairs(world.buildings or {}) do
        for _, station in ipairs(building.stations or {}) do
            if station.state == "PRODUCING" then
                production.buildings_producing = production.buildings_producing + 1
            elseif station.state == "IDLE" then
                production.buildings_idle = production.buildings_idle + 1
            elseif station.state == "NO_MATERIALS" then
                production.buildings_no_materials = production.buildings_no_materials + 1
            elseif station.state == "NO_WORKER" then
                production.buildings_no_workers = production.buildings_no_workers + 1
            end
        end
    end

    -- Get production stats if available
    if world.productionStats then
        local metrics = world:GetProductionMetrics()
        if metrics then
            production.metrics = metrics
        end
    end

    return production
end

function GameStateCapture:captureAlphaPhaseActions(phase)
    local actions = {}

    if phase == "splash" then
        table.insert(actions, {action = "skip_splash", description = "Press any key to skip splash"})
    elseif phase == "title" then
        table.insert(actions, {action = "new_game", description = "Start a new game"})
        table.insert(actions, {action = "continue_game", description = "Continue from quicksave"})
        table.insert(actions, {action = "load_game", description = "Load a saved game"})
        table.insert(actions, {action = "quit", description = "Return to launcher"})
    elseif phase == "setup" then
        table.insert(actions, {action = "configure_game", description = "Configure new game settings"})
        table.insert(actions, {action = "cancel_setup", description = "Cancel and return to title"})
    elseif phase == "loading" or phase == "worldloading" then
        table.insert(actions, {action = "wait", description = "Loading in progress..."})
    end

    return actions
end

function GameStateCapture:captureAlphaActions(world, ui)
    local actions = {}

    -- Time controls
    if world.isPaused then
        table.insert(actions, {action = "resume", description = "Press SPACE to resume"})
    else
        table.insert(actions, {action = "pause", description = "Press SPACE to pause"})
    end
    table.insert(actions, {action = "set_speed", description = "Press 1/2/3 to change speed"})

    -- Building placement
    if ui and ui.placementMode then
        table.insert(actions, {action = "place_building", description = "Click to place building"})
        table.insert(actions, {action = "cancel_placement", description = "Right-click or ESC to cancel"})
    else
        table.insert(actions, {action = "start_building_placement", description = "Select building type to place"})
    end

    -- Camera
    table.insert(actions, {action = "move_camera", description = "WASD or arrow keys to move camera"})
    table.insert(actions, {action = "zoom_camera", description = "Mouse wheel to zoom"})

    -- Selection
    table.insert(actions, {action = "select_entity", description = "Click building or citizen to select"})

    -- UI toggles
    table.insert(actions, {action = "toggle_inventory", description = "Toggle inventory panel"})
    table.insert(actions, {action = "toggle_build_menu", description = "Open build menu"})
    table.insert(actions, {action = "toggle_citizens", description = "Toggle citizens panel"})

    -- Worker management
    table.insert(actions, {action = "assign_worker", description = "Assign worker to building"})
    table.insert(actions, {action = "remove_worker", description = "Remove worker from building"})

    -- Recipe management
    table.insert(actions, {action = "assign_recipe", description = "Assign recipe to building station"})

    -- Housing
    table.insert(actions, {action = "assign_housing", description = "Assign citizen to housing"})

    -- Immigration
    table.insert(actions, {action = "accept_immigrant", description = "Accept immigrant from queue"})
    table.insert(actions, {action = "reject_immigrant", description = "Reject immigrant from queue"})

    -- Save/Load
    table.insert(actions, {action = "quick_save", description = "Quick save the game"})
    table.insert(actions, {action = "quick_load", description = "Quick load the game"})

    return actions
end

function GameStateCapture:getAlphaControlsReference()
    return {
        time = {
            SPACE = "Pause/Resume game",
            ["1"] = "Normal speed",
            ["2"] = "Fast speed (2x)",
            ["3"] = "Very fast speed (4x)"
        },
        camera = {
            W = "Move camera up",
            A = "Move camera left",
            S = "Move camera down",
            D = "Move camera right",
            ["Mouse wheel"] = "Zoom in/out"
        },
        building = {
            ["Left click"] = "Place building / Select entity",
            ["Right click"] = "Cancel placement",
            B = "Open build menu"
        },
        panels = {
            I = "Toggle inventory",
            C = "Toggle citizens panel",
            H = "Toggle help overlay",
            Escape = "Close panel / Return to title"
        },
        saving = {
            F5 = "Quick save",
            F9 = "Quick load"
        }
    }
end

function GameStateCapture:queryAlphaPrototype(queryType, id, params)
    local alpha = gAlphaPrototype
    local world = alpha.mWorld

    if not world then
        return {error = "Alpha world not initialized"}
    end

    if queryType == "building" and id then
        -- Find building by ID or index
        for i, building in ipairs(world.buildings or {}) do
            if building.id == id or i == tonumber(id) then
                return self:captureAlphaBuildings({buildings = {building}}, "full")[1]
            end
        end
        return {error = "Building not found: " .. tostring(id)}
    end

    if queryType == "citizen" or queryType == "character" then
        if id then
            -- Find citizen by ID or name
            for i, citizen in ipairs(world.citizens or {}) do
                if citizen.id == id or citizen.name == id or i == tonumber(id) then
                    return self:captureAlphaCitizens({citizens = {citizen}}, "full")[1]
                end
            end
            return {error = "Citizen not found: " .. tostring(id)}
        end
    end

    if queryType == "available_buildings" then
        local types = {}
        for _, bt in ipairs(world.buildingTypes or {}) do
            local canAfford, affordError = world:CanAffordBuilding(bt)
            table.insert(types, {
                id = bt.id,
                name = bt.name,
                category = bt.category,
                description = bt.description,
                construction_cost = bt.constructionCost,
                can_afford = canAfford,
                afford_error = affordError
            })
        end
        return {building_types = types}
    end

    if queryType == "available_recipes" then
        local recipes = {}
        for _, recipe in ipairs(world.buildingRecipes or {}) do
            table.insert(recipes, {
                id = recipe.id,
                name = recipe.name,
                building_type = recipe.buildingType,
                inputs = recipe.inputs,
                outputs = recipe.outputs,
                production_time = recipe.productionTime
            })
        end
        return {recipes = recipes}
    end

    if queryType == "commodities" then
        local commodities = {}
        for _, c in ipairs(world.commodities or {}) do
            table.insert(commodities, {
                id = c.id,
                name = c.name,
                category = c.category,
                inventory_count = world.inventory[c.id] or 0
            })
        end
        return {commodities = commodities}
    end

    if queryType == "time_slots" then
        return {time_slots = world.timeSlots or {}}
    end

    if queryType == "production_stats" then
        return world:GetProductionMetrics() or {error = "No production stats available"}
    end

    if queryType == "building_efficiencies" then
        return {efficiencies = world:GetBuildingEfficiencies()}
    end

    if queryType == "housing_assignments" then
        if world.housingSystem then
            return world.housingSystem:GetAllAssignments()
        end
        return {error = "Housing system not available"}
    end

    if queryType == "land_plots" then
        if world.landSystem then
            -- Return summary of land ownership
            return {
                grid_columns = world.landSystem.gridColumns,
                grid_rows = world.landSystem.gridRows,
                plot_width = world.landSystem.plotWidth,
                plot_height = world.landSystem.plotHeight
            }
        end
        return {error = "Land system not available"}
    end

    if queryType == "immigration_queue" then
        return self:captureAlphaImmigration(world)
    end

    if queryType == "available_actions" then
        return self:captureAlphaActions(world, alpha.mUI)
    end

    return {error = "Unknown alpha query type: " .. tostring(queryType)}
end

return GameStateCapture
