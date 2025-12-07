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
    table.insert(actions, {action = "set_simulation_speed", description = "Set speed (1x, 2x, 5x, 10x)"})
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
            ["4"] = "Set speed 10x"
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

return GameStateCapture
