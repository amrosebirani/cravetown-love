--
-- Prototype2State - Production Engine prototype
-- Blank canvas with building cards on left and building picker on right
--

require("code/DataLoader")
require("code/CharacterFactory")
local ProductionStats = require("code/ProductionStats")
local StatsVisualization = require("code/StatsVisualization")

Prototype2State = {}
Prototype2State.__index = Prototype2State

function Prototype2State:Create()
    local this = {
        -- Buildings array (no spatial placement, just cards)
        mBuildings = {},

        -- Building types loaded from JSON
        mBuildingTypes = {},      -- Array of all building types
        mBuildingTypesById = {},  -- Map of id -> building type for quick lookup

        -- UI state
        mRightPanelWidth = 400,
        mSelectedBuildingType = nil,
        mHoveredBuildingType = nil,

        -- Building categories for organization
        mCategories = {},

        -- Scroll state for building grid
        mBuildingScrollOffset = 0,
        mBuildingScrollMax = 0,

        -- Scroll state for right panel
        mRightScrollOffset = 0,
        mRightScrollMax = 0,

        -- Resource management panels
        mShowHRPanel = false,
        mShowCommodityPanel = false,

        -- Worker resources
        mWorkerTypes = {},
        mWorkerCounts = {},  -- {workerTypeId: count}
        mWorkerPool = {},     -- Array of all hired worker characters

        -- Employment associations (for optimal querying)
        mEmployment = {
            byWorker = {},    -- {workerId: buildingId}
            byBuilding = {},  -- {buildingId: {workerId1, workerId2, ...}}
            workerLookup = {} -- {workerId: worker} for fast lookup
        },

        -- Commodity resources
        mCommodities = {},
        mCommodityCounts = {},  -- {commodityId: count}

        -- Time scale and production
        mTimeScale = "normal",  -- "slow", "normal", "fast"
        mTimeScales = {
            slow = 500,
            normal = 1500,
            fast = 3000
        },
        mGameTime = 0,  -- Accumulated game time in seconds

        -- View state
        mShowHRPoolView = false,  -- Toggle between Buildings view and HR Pool view

        -- Scroll state for resource panels
        mHRScrollOffset = 0,
        mHRScrollMax = 0,
        mCommodityScrollOffset = 0,
        mCommodityScrollMax = 0,
        mCommodityCategoryScrollOffset = 0,
        mCommodityCategoryScrollMax = 0,
        mSelectedCommodityCategory = nil,  -- nil shows all, otherwise filter by category

        -- Recipe picker modal state
        mShowRecipeModal = false,
        mBuildingRecipes = {},   -- All recipes loaded from JSON
        mRecipeScrollOffset = 0,
        mRecipeScrollMax = 0,

        -- Building detail modal state
        mShowBuildingModal = false,
        mSelectedBuilding = nil,  -- Building that was clicked
        mSelectedStation = nil,  -- Station that was clicked (for recipe assignment)
        mBuildingModalScrollOffset = 0,
        mBuildingModalScrollMax = 0,

        mModalJustOpened = false,  -- Flag to prevent closing modal on same click that opened it

        -- Stats tracking
        mStats = ProductionStats.new(),
        mShowStatsPanel = false,  -- Toggle for stats panel visibility
        mSelectedStatCommodity = nil,  -- Commodity selected for detailed trend view
        mGameTick = 0,  -- Game tick counter for stats sampling
        mStatsScrollOffset = 0,  -- Scroll offset for commodity list
        mStatsScrollMax = 0  -- Max scroll for commodity list
    }

    setmetatable(this, self)

    -- Load data from JSON files (must be first to load building types)
    this:LoadGameData()

    -- Categorize building types after loading
    this:CategorizeBuildingTypes()

    return this
end

function Prototype2State:LoadGameData()
    -- Load building types
    local success0, buildingTypes = pcall(DataLoader.loadBuildingTypes)
    if success0 then
        self.mBuildingTypes = buildingTypes
        -- Create lookup table by id
        for _, bt in ipairs(buildingTypes) do
            self.mBuildingTypesById[bt.id] = bt
        end
        print("Loaded " .. #buildingTypes .. " building types")
    else
        print("Warning: Failed to load building types: " .. tostring(buildingTypes))
        self.mBuildingTypes = {}
    end

    -- Load worker types
    local success, workerTypes = pcall(DataLoader.loadWorkerTypes)
    if success then
        self.mWorkerTypes = workerTypes
        -- Initialize all worker counts to 0
        for _, wt in ipairs(workerTypes) do
            self.mWorkerCounts[wt.id] = 0
        end
        print("Loaded " .. #workerTypes .. " worker types")
    else
        print("Warning: Failed to load worker types: " .. tostring(workerTypes))
        self.mWorkerTypes = {}
    end

    -- Load commodities
    local success2, commodities = pcall(DataLoader.loadCommodities)
    if success2 then
        self.mCommodities = commodities
        -- Initialize all commodity counts to 0
        for _, c in ipairs(commodities) do
            self.mCommodityCounts[c.id] = 0
        end
        print("Loaded " .. #commodities .. " commodities")
    else
        print("Warning: Failed to load commodities: " .. tostring(commodities))
        self.mCommodities = {}
    end

    -- Load building recipes
    local success3, recipes = pcall(DataLoader.loadBuildingRecipes)
    if success3 then
        self.mBuildingRecipes = recipes
        print("Loaded " .. #recipes .. " building recipes")
    else
        print("Warning: Failed to load building recipes: " .. tostring(recipes))
        self.mBuildingRecipes = {}
    end
end

function Prototype2State:CategorizeBuildingTypes()
    -- Clear the initial categories (we'll build them dynamically)
    self.mCategories = {}

    -- Go through all loaded building types and categorize them
    for _, buildingType in ipairs(self.mBuildingTypes) do
        if buildingType.category then
            -- Capitalize first letter for display
            local categoryName = buildingType.category:sub(1,1):upper() .. buildingType.category:sub(2)

            -- Find or create category (case-insensitive comparison)
            local foundCategory = nil
            for _, cat in ipairs(self.mCategories) do
                if cat.name:lower() == categoryName:lower() then
                    foundCategory = cat
                    break
                end
            end

            if not foundCategory then
                foundCategory = {name = categoryName, types = {}}
                table.insert(self.mCategories, foundCategory)
            end

            table.insert(foundCategory.types, {
                id = buildingType.id,
                data = buildingType
            })
        end
    end

    -- Sort categories alphabetically
    table.sort(self.mCategories, function(a, b)
        return a.name < b.name
    end)
end

function Prototype2State:Enter(params)
    print("Entering Prototype 2: Production Engine")
end

function Prototype2State:Exit()
end

function Prototype2State:keypressed(key)
    -- Handle escape key to close stats panel
    if key == "escape" then
        if self.mShowStatsPanel then
            self.mShowStatsPanel = false
            return true  -- Indicate that we handled the key
        end
    end
    return false  -- Indicate that we didn't handle the key
end

function Prototype2State:Update(dt)
    -- Reset modal just opened flag at the start of each frame
    if self.mModalJustOpened then
        self.mModalJustOpened = false
    end

    -- Update game time based on time scale
    local timeMultiplier = self.mTimeScales[self.mTimeScale]
    local gameDt = dt * timeMultiplier
    self.mGameTime = self.mGameTime + gameDt

    -- Update game tick for stats
    self.mGameTick = self.mGameTick + 1
    self.mStats:updateTick(self.mGameTick)

    -- Update worker utilization stats
    local totalWorkers = 0
    local activeWorkers = 0
    for _, worker in ipairs(self.mWorkerPool) do
        totalWorkers = totalWorkers + 1
        if self.mEmployment.byWorker[worker.id] then
            activeWorkers = activeWorkers + 1
        end
    end
    self.mStats:recordWorkerStats(totalWorkers, activeWorkers)

    -- Record stockpile levels
    for commodityId, count in pairs(self.mCommodityCounts) do
        self.mStats:recordStockpile(commodityId, count)
    end

    -- Update production for all buildings
    self:UpdateProduction(gameDt)

    -- TEST: Press 'T' to manually trigger recipe modal (for debugging)
    if love.keyboard.isDown("t") and #self.mBuildings > 0 then
        if not self.mShowRecipeModal then
            print("TEST: Manually triggering recipe modal with T key")
            self.mSelectedBuilding = self.mBuildings[1]
            self.mShowRecipeModal = true
            self.mRecipeScrollOffset = 0
            self.mModalJustOpened = true
        end
    end

    -- Handle mouse clicks
    if gMousePressed and gMousePressed.button == 1 then
        local mx, my = gMousePressed.x, gMousePressed.y

        print("Mouse click at: " .. mx .. ", " .. my)
        print("mShowHRPoolView: " .. tostring(self.mShowHRPoolView))
        print("mShowRecipeModal: " .. tostring(self.mShowRecipeModal))
        print("mModalJustOpened: " .. tostring(self.mModalJustOpened))

        -- PRIORITY 1: Handle modals first (they should block all clicks below)

        -- Check if clicking on Stats panel (full-screen modal - consumes all clicks)
        if self.mShowStatsPanel then
            self:HandleStatsPanelClick(mx, my)
            -- Stats panel is a full-screen modal, don't process any other clicks
            gMousePressed = nil
            return
        end

        -- Check if clicking on recipe modal (but not if it was just opened this frame)
        if self.mShowRecipeModal and not self.mModalJustOpened then
            print("Calling HandleRecipeModalClick")
            self:HandleRecipeModalClick(mx, my)
            -- Recipe modal is a modal, don't process clicks below it
            gMousePressed = nil
            return
        elseif self.mShowRecipeModal and self.mModalJustOpened then
            print("Skipping HandleRecipeModalClick - modal just opened")
            gMousePressed = nil
            return
        end

        -- Check if clicking on building detail modal
        if self.mShowBuildingModal and not self.mModalJustOpened then
            self:HandleBuildingModalClick(mx, my)
            -- Building modal is a modal, don't process clicks below it
            gMousePressed = nil
            return
        elseif self.mShowBuildingModal and self.mModalJustOpened then
            print("Skipping HandleBuildingModalClick - modal just opened")
            gMousePressed = nil
            return
        end

        -- PRIORITY 2: Handle panels (if no modals are open)

        -- Check if clicking on HR panel
        if self.mShowHRPanel then
            self:HandleHRPanelClick(mx, my)
        end

        -- Check if clicking on Commodity panel
        if self.mShowCommodityPanel then
            self:HandleCommodityPanelClick(mx, my)
        end

        -- PRIORITY 3: Handle UI elements (if no modals or panels blocking)

        -- Check for top bar button clicks
        if my <= 60 then
            self:HandleTopBarClick(mx, my)
        end

        -- Check for speed control clicks (bottom left)
        self:HandleSpeedControlClick(mx, my)

        -- Check if clicking on right panel (building picker)
        local screenW = love.graphics.getWidth()
        local rightPanelX = screenW - self.mRightPanelWidth

        if mx >= rightPanelX and not self.mShowHRPanel and not self.mShowCommodityPanel then
            self:HandleRightPanelClick(mx, my)
        end

        -- Check if clicking on a building card (when not in modal)
        if not self.mShowRecipeModal and not self.mShowBuildingModal and not self.mShowHRPoolView then
            print("Calling HandleBuildingCardClick")
            self:HandleBuildingCardClick(mx, my)
        else
            print("Skipping HandleBuildingCardClick - HRPoolView=" .. tostring(self.mShowHRPoolView) .. ", RecipeModal=" .. tostring(self.mShowRecipeModal) .. ", BuildingModal=" .. tostring(self.mShowBuildingModal))
        end
    end
end

function Prototype2State:UpdateProduction(gameDt)
    -- Update production state and progress for each station in each building
    for _, building in ipairs(self.mBuildings) do
        for _, station in ipairs(building.stations) do
            local recipe = station.recipe

            -- State 1: Check if station has a recipe
            if not recipe then
                station.state = "IDLE"
                station.progress = 0
                goto continue_station
            end

            -- State 2: Check if station has a worker
            if not station.worker then
                station.state = "NO_WORKER"
                station.progress = 0
                goto continue_station
            end

            -- State 3: Check if station has raw materials (only when starting production)
            if station.state ~= "PRODUCING" or station.progress == 0 then
                local hasAllInputs = true

                -- Check each input requirement
                for commodityId, requiredAmount in pairs(recipe.inputs) do
                    local availableInInventory = self.mCommodityCounts[commodityId] or 0
                    local availableInStorage = building.storage.inputs[commodityId] or 0
                    local totalAvailable = availableInInventory + availableInStorage

                    if totalAvailable < requiredAmount then
                        hasAllInputs = false
                        break
                    end
                end

                if not hasAllInputs then
                    station.state = "NO_MATERIALS"
                    station.progress = 0
                    goto continue_station
                end

                -- If we reach here and state was not PRODUCING, pull inputs from inventory
                if station.state ~= "PRODUCING" then
                    self:PullInputsForStation(building, station)
                end
            end

            -- State 4: Production is active
            station.state = "PRODUCING"

            -- Update progress based on game time and worker efficiency
            local progressIncrement = (gameDt / recipe.productionTime) * station.efficiency
            station.progress = station.progress + progressIncrement

            -- Check if production cycle completed
            if station.progress >= 1.0 then
                self:CompleteStationProduction(building, station)
                station.progress = 0  -- Reset for next cycle
            end

            ::continue_station::
        end
    end
end

function Prototype2State:PullInputsForBuilding(building)
    -- Pull inputs from inventory to building's local storage
    -- Strategy: Fill storage to maximum capacity (not just for one cycle)
    local recipe = building.production.recipe
    if not recipe then return end

    -- Calculate available storage capacity
    local storageAvailable = building.storage.inputCapacity - building.storage.inputUsed

    if storageAvailable <= 0 then
        return  -- Storage is full
    end

    -- Try to pull as much as possible for each input commodity
    for commodityId, requiredAmount in pairs(recipe.inputs) do
        local availableInInventory = self.mCommodityCounts[commodityId] or 0
        local availableInStorage = building.storage.inputs[commodityId] or 0

        if availableInInventory > 0 then
            -- Calculate how much we can pull
            -- Limited by: inventory amount, storage capacity, and maintaining proportions
            local maxPull = math.min(availableInInventory, storageAvailable)

            if maxPull > 0 then
                -- Transfer from inventory to building storage
                self.mCommodityCounts[commodityId] = self.mCommodityCounts[commodityId] - maxPull
                building.storage.inputs[commodityId] = availableInStorage + maxPull
                building.storage.inputUsed = building.storage.inputUsed + maxPull
                storageAvailable = storageAvailable - maxPull

                if storageAvailable <= 0 then
                    break  -- Storage is now full
                end
            end
        end
    end
end

function Prototype2State:CompleteProduction(building)
    -- Handle production completion: consume inputs, produce outputs
    local recipe = building.production.recipe
    if not recipe then return end

    -- Consume inputs from building storage
    for commodityId, amount in pairs(recipe.inputs) do
        local currentAmount = building.storage.inputs[commodityId] or 0
        local actualConsumed = math.min(currentAmount, amount)  -- Only consume what's actually there
        local newAmount = currentAmount - actualConsumed
        building.storage.inputs[commodityId] = newAmount
        building.storage.inputUsed = math.max(0, building.storage.inputUsed - actualConsumed)

        -- Record consumption in stats
        self.mStats:recordConsumption(commodityId, actualConsumed)

        -- If commodity is now 0, remove it from storage to keep things clean
        if newAmount <= 0 then
            building.storage.inputs[commodityId] = nil
        end
    end

    -- Produce outputs to building storage (with overflow to inventory)
    for commodityId, amount in pairs(recipe.outputs) do
        local currentAmount = building.storage.outputs[commodityId] or 0
        local storageAvailable = building.storage.outputCapacity - building.storage.outputUsed

        -- How much can fit in local storage?
        local toStorage = math.min(amount, storageAvailable)
        local overflow = amount - toStorage

        -- Add to local storage
        if toStorage > 0 then
            building.storage.outputs[commodityId] = currentAmount + toStorage
            building.storage.outputUsed = building.storage.outputUsed + toStorage
        end

        -- Add overflow to town inventory
        if overflow > 0 then
            self.mCommodityCounts[commodityId] = (self.mCommodityCounts[commodityId] or 0) + overflow
        end

        -- Record production in stats (total amount produced)
        self.mStats:recordProduction(commodityId, amount, building.id)
    end

    print("Production completed at " .. building.name .. " (" .. recipe.recipeName .. ")")

    -- After production completes, try to refill input storage from inventory
    self:PullInputsForBuilding(building)
end

-- ============================================================================
-- STATION-BASED PRODUCTION FUNCTIONS (New system)
-- ============================================================================

function Prototype2State:PullInputsForStation(building, station)
    -- Pull inputs for ONE production cycle for this station
    local recipe = station.recipe
    if not recipe then return false end

    -- Check if we have enough materials for one cycle
    local hasAllInputs = true
    for commodityId, requiredAmount in pairs(recipe.inputs) do
        local availableInInventory = self.mCommodityCounts[commodityId] or 0
        local availableInStorage = building.storage.inputs[commodityId] or 0
        local totalAvailable = availableInInventory + availableInStorage

        if totalAvailable < requiredAmount then
            hasAllInputs = false
            break
        end
    end

    if not hasAllInputs then
        return false  -- Can't start production cycle
    end

    -- Pull exactly what we need for one cycle
    for commodityId, requiredAmount in pairs(recipe.inputs) do
        local availableInStorage = building.storage.inputs[commodityId] or 0

        -- Try to pull from building storage first
        if availableInStorage >= requiredAmount then
            -- All from storage
            building.storage.inputs[commodityId] = availableInStorage - requiredAmount
            building.storage.inputUsed = building.storage.inputUsed - requiredAmount

            -- Clean up if zero
            if building.storage.inputs[commodityId] <= 0 then
                building.storage.inputs[commodityId] = nil
            end
        else
            -- Need to pull from both storage and inventory
            local fromStorage = availableInStorage
            local fromInventory = requiredAmount - fromStorage

            -- Take from storage
            if fromStorage > 0 then
                building.storage.inputs[commodityId] = nil
                building.storage.inputUsed = building.storage.inputUsed - fromStorage
            end

            -- Take from inventory
            self.mCommodityCounts[commodityId] = (self.mCommodityCounts[commodityId] or 0) - fromInventory
        end
    end

    return true  -- Successfully pulled inputs
end

function Prototype2State:CompleteStationProduction(building, station)
    -- Complete production for this station: produce outputs, record stats
    local recipe = station.recipe
    if not recipe then return end

    -- Produce outputs to building storage (with overflow to inventory)
    for commodityId, amount in pairs(recipe.outputs) do
        local currentAmount = building.storage.outputs[commodityId] or 0
        local storageAvailable = building.storage.outputCapacity - building.storage.outputUsed

        -- How much can fit in local storage?
        local toStorage = math.min(amount, storageAvailable)
        local overflow = amount - toStorage

        -- Add to local storage
        if toStorage > 0 then
            building.storage.outputs[commodityId] = currentAmount + toStorage
            building.storage.outputUsed = building.storage.outputUsed + toStorage
        end

        -- Add overflow to town inventory
        if overflow > 0 then
            self.mCommodityCounts[commodityId] = (self.mCommodityCounts[commodityId] or 0) + overflow
        end

        -- Record production in stats (total amount produced)
        self.mStats:recordProduction(commodityId, amount, building.id)
    end

    print("Station " .. station.id .. " completed production at " .. building.name .. " (" .. recipe.recipeName .. ")")

    -- Reset station state for next cycle
    station.progress = 0
    station.state = "IDLE"  -- Will be updated in next UpdateProduction cycle
end

function Prototype2State:HandleSpeedControlClick(mx, my)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Speed control position (matching RenderSpeedControl)
    local controlX = 20
    local controlY = screenH - 60
    local btnY = controlY + 22
    local btnSize = 25

    -- Check decrease button (-)
    local minusX = controlX + 10
    if mx >= minusX and mx <= minusX + btnSize and
       my >= btnY and my <= btnY + btnSize then
        -- Cycle to slower speed
        if self.mTimeScale == "fast" then
            self.mTimeScale = "normal"
        elseif self.mTimeScale == "normal" then
            self.mTimeScale = "slow"
        end
        -- Already at slowest, do nothing
        return
    end

    -- Check increase button (+)
    local plusX = controlX + 165
    if mx >= plusX and mx <= plusX + btnSize and
       my >= btnY and my <= btnY + btnSize then
        -- Cycle to faster speed
        if self.mTimeScale == "slow" then
            self.mTimeScale = "normal"
        elseif self.mTimeScale == "normal" then
            self.mTimeScale = "fast"
        end
        -- Already at fastest, do nothing
        return
    end
end

function Prototype2State:HandleRightPanelClick(mx, my)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local rightPanelX = screenW - self.mRightPanelWidth

    -- Calculate which building type was clicked (accounting for scroll)
    local listY = 110
    local yOffset = listY - self.mRightScrollOffset
    local itemHeight = 60
    local spacing = 10
    local categorySpacing = 30

    for _, category in ipairs(self.mCategories) do
        -- Skip category header
        yOffset = yOffset + 25

        -- Building items
        for _, buildingType in ipairs(category.types) do
            local itemY = yOffset

            if my >= itemY and my <= itemY + itemHeight then
                -- Add this building
                self:AddBuilding(buildingType.id)
                return
            end

            yOffset = yOffset + itemHeight + spacing
        end

        yOffset = yOffset + categorySpacing
    end
end

function Prototype2State:HandleTopBarClick(mx, my)
    local screenW = love.graphics.getWidth()

    -- Buildings view button
    local buildingsButtonX = 20
    local buildingsButtonW = 120
    if mx >= buildingsButtonX and mx <= buildingsButtonX + buildingsButtonW and my >= 15 and my <= 45 then
        self.mShowHRPoolView = false
        return
    end

    -- HR Pool view button
    local hrPoolButtonX = 150
    local hrPoolButtonW = 120
    if mx >= hrPoolButtonX and mx <= hrPoolButtonX + hrPoolButtonW and my >= 15 and my <= 45 then
        self.mShowHRPoolView = true
        return
    end

    -- HR button (Human Resources)
    local hrButtonX = screenW - 480
    local hrButtonW = 170
    if mx >= hrButtonX and mx <= hrButtonX + hrButtonW and my >= 15 and my <= 45 then
        self.mShowHRPanel = not self.mShowHRPanel
        if self.mShowHRPanel then
            self.mShowCommodityPanel = false
        end
        return
    end

    -- Commodity button
    local commButtonX = screenW - 290
    local commButtonW = 170
    if mx >= commButtonX and mx <= commButtonX + commButtonW and my >= 15 and my <= 45 then
        self.mShowCommodityPanel = not self.mShowCommodityPanel
        if self.mShowCommodityPanel then
            self.mShowHRPanel = false
            self.mShowStatsPanel = false
        end
        return
    end

    -- Stats button
    local statsButtonX = screenW - 100
    local statsButtonW = 80
    if mx >= statsButtonX and mx <= statsButtonX + statsButtonW and my >= 15 and my <= 45 then
        self.mShowStatsPanel = not self.mShowStatsPanel
        if self.mShowStatsPanel then
            self.mShowHRPanel = false
            self.mShowCommodityPanel = false
        end
        return
    end
end

function Prototype2State:HandleHRPanelClick(mx, my)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local panelX = screenW - self.mRightPanelWidth
    local listY = 110

    -- Check if clicking inside the panel
    if mx < panelX then
        return
    end

    local yOffset = listY - self.mHRScrollOffset
    local itemHeight = 50
    local spacing = 5

    for _, wt in ipairs(self.mWorkerTypes) do
        if my >= yOffset and my <= yOffset + itemHeight then
            -- Check if clicking + or - button
            local buttonY = yOffset + 15
            local buttonSize = 25

            -- - button
            local minusX = panelX + self.mRightPanelWidth - 80
            if mx >= minusX and mx <= minusX + buttonSize and
               my >= buttonY and my <= buttonY + buttonSize then
                if self.mWorkerCounts[wt.id] > 0 then
                    self.mWorkerCounts[wt.id] = self.mWorkerCounts[wt.id] - 1
                    -- Remove the last unemployed worker of this type from the pool
                    for i = #self.mWorkerPool, 1, -1 do
                        local worker = self.mWorkerPool[i]
                        if worker.workerType == wt.id and not worker.employed then
                            print("Fired: " .. worker.name .. " (" .. worker.workerTypeName .. ")")
                            table.remove(self.mWorkerPool, i)
                            break
                        end
                    end
                end
                return
            end

            -- + button
            local plusX = panelX + self.mRightPanelWidth - 40
            if mx >= plusX and mx <= plusX + buttonSize and
               my >= buttonY and my <= buttonY + buttonSize then
                self.mWorkerCounts[wt.id] = self.mWorkerCounts[wt.id] + 1
                -- Create a worker character and add to pool
                local worker = CharacterFactory.CreateWorker(wt)
                table.insert(self.mWorkerPool, worker)
                self.mEmployment.workerLookup[worker.id] = worker
                print("Hired: " .. worker.name .. " as " .. worker.workerTypeName)

                -- Run free agency to assign worker to a building
                self:RunFreeAgency()
                return
            end
        end

        yOffset = yOffset + itemHeight + spacing
    end
end

function Prototype2State:HandleCommodityPanelClick(mx, my)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local panelX = screenW - self.mRightPanelWidth

    -- Check if clicking inside the panel
    if mx < panelX then
        return
    end

    -- Get unique categories
    local categories = {
        {id = "all", name = "All"},
        {id = "nonzero", name = "In Stock"}
    }
    local categorySet = {}
    for _, c in ipairs(self.mCommodities) do
        if c.category and not categorySet[c.category] then
            categorySet[c.category] = true
            table.insert(categories, {id = c.category, name = c.category})
        end
    end
    table.sort(categories, function(a, b)
        if a.id == "all" then return true end
        if b.id == "all" then return false end
        if a.id == "nonzero" then return true end
        if b.id == "nonzero" then return false end
        return a.name < b.name
    end)

    -- Check category button clicks (left side bar with scroll)
    local filterY = 110
    local filterWidth = 150
    local filterX = panelX
    local filterHeight = screenH - filterY

    local btnY = filterY + 5 - self.mCommodityCategoryScrollOffset

    for i, category in ipairs(categories) do
        local btnX = filterX + 5
        local btnW = filterWidth - 10
        local btnH = 25

        if mx >= btnX and mx <= btnX + btnW and
           my >= btnY and my <= btnY + btnH and
           my >= filterY and my <= filterY + filterHeight then  -- Within visible area
            self.mSelectedCommodityCategory = category.id
            self.mCommodityScrollOffset = 0  -- Reset scroll when changing category
            return
        end

        btnY = btnY + 28
    end

    -- Commodity list (right side)
    local listX = filterX + filterWidth + 10
    local listY = filterY + 5

    -- Filter commodities by selected category
    local filteredCommodities = {}
    for _, c in ipairs(self.mCommodities) do
        local include = false

        if self.mSelectedCommodityCategory == nil or self.mSelectedCommodityCategory == "all" then
            include = true
        elseif self.mSelectedCommodityCategory == "nonzero" then
            include = (self.mCommodityCounts[c.id] or 0) > 0
        else
            include = c.category == self.mSelectedCommodityCategory
        end

        if include then
            table.insert(filteredCommodities, c)
        end
    end

    local yOffset = listY - self.mCommodityScrollOffset
    local itemHeight = 50
    local spacing = 5

    -- Get listWidth for button positioning
    local listWidth = self.mRightPanelWidth - 150 - 20  -- Same as in render

    for _, c in ipairs(filteredCommodities) do
        if my >= yOffset and my <= yOffset + itemHeight then
            -- Check if clicking + or - button
            local buttonY = yOffset + 15
            local buttonSize = 25

            -- - button (subtract 10)
            local minusX = listX + listWidth - 60
            if mx >= minusX and mx <= minusX + buttonSize and
               my >= buttonY and my <= buttonY + buttonSize then
                self.mCommodityCounts[c.id] = math.max(0, self.mCommodityCounts[c.id] - 10)
                return
            end

            -- + button (add 10)
            local plusX = listX + listWidth - 30
            if mx >= plusX and mx <= plusX + buttonSize and
               my >= buttonY and my <= buttonY + buttonSize then
                self.mCommodityCounts[c.id] = self.mCommodityCounts[c.id] + 10
                return
            end
        end

        yOffset = yOffset + itemHeight + spacing
    end
end

function Prototype2State:HandleStatsPanelClick(mx, my)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Panel dimensions (same as in RenderStatsPanel)
    local panelY = 60
    local panelH = screenH - 120

    local leftPanelX = 20
    local leftPanelW = 350
    local leftPanelY = panelY
    local leftPanelH = panelH

    -- Check if clicking in left panel (commodity list)
    if mx >= leftPanelX and mx <= leftPanelX + leftPanelW and
       my >= leftPanelY and my <= leftPanelY + leftPanelH then

        -- Get tracked commodities
        local trackedCommodities = self.mStats:getTrackedCommodities()

        if #trackedCommodities > 0 then
            local listY = leftPanelY + 65
            local listHeight = leftPanelH - 75
            local itemHeight = 60
            local spacing = 5

            -- Check which commodity was clicked
            local yOffset = listY - self.mStatsScrollOffset

            for _, commodityId in ipairs(trackedCommodities) do
                -- Check if click is on this item
                if my >= yOffset and my <= yOffset + itemHeight and
                   mx >= leftPanelX + 10 and mx <= leftPanelX + leftPanelW - 10 then
                    -- Select this commodity
                    self.mSelectedStatCommodity = commodityId
                    return true  -- Consumed the click
                end

                yOffset = yOffset + itemHeight + spacing
            end
        end
    end

    -- Consume ALL clicks when stats panel is open (don't let them through)
    -- This is a full-screen modal
    return true
end

function Prototype2State:HandleBuildingCardClick(mx, my)
    print("HandleBuildingCardClick called: mx=" .. mx .. ", my=" .. my)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local gridWidth = screenW - self.mRightPanelWidth
    local gridY = 60
    local listY = 140
    local listHeight = screenH - listY - 10
    local padding = 20
    local cols = 3
    local cardSpacing = 15
    local categorySpacing = 30

    -- Calculate card dimensions
    local availableWidth = gridWidth - (padding * 2) - (cardSpacing * (cols - 1))
    local cardWidth = availableWidth / cols
    local cardHeight = 120

    print("Grid bounds: x=" .. gridWidth .. ", y=" .. listY .. "-" .. (listY + listHeight))

    -- Check if click is within grid area
    if mx >= gridWidth or my < listY or my > listY + listHeight then
        print("Click outside grid area")
        return
    end

    -- Group buildings by category
    local buildingsByCategory = {}
    local categoryOrder = {}
    print("Number of buildings: " .. #self.mBuildings)
    for _, building in ipairs(self.mBuildings) do
        local cat = building.category or "Uncategorized"
        if not buildingsByCategory[cat] then
            buildingsByCategory[cat] = {}
            table.insert(categoryOrder, cat)
        end
        table.insert(buildingsByCategory[cat], building)
    end

    -- Check which card was clicked
    local yOffset = listY - self.mBuildingScrollOffset

    for _, categoryName in ipairs(categoryOrder) do
        local buildings = buildingsByCategory[categoryName]

        -- Skip category header
        yOffset = yOffset + 25

        -- Check each building card in rows of 3
        local col = 0
        local rowY = yOffset

        for i, building in ipairs(buildings) do
            local x = padding + (col * (cardWidth + cardSpacing))

            -- Check if click is within this card
            if mx >= x and mx <= x + cardWidth and
               my >= rowY and my <= rowY + cardHeight then
                -- Open building detail modal
                self.mSelectedBuilding = building
                self.mShowBuildingModal = true
                self.mModalJustOpened = true  -- Prevent closing on same click
                self.mBuildingModalScrollOffset = 0
                return
            end

            col = col + 1
            if col >= cols then
                col = 0
                rowY = rowY + cardHeight + cardSpacing
            end
        end

        -- Move to next row if we didn't complete the last row
        if col > 0 then
            rowY = rowY + cardHeight + cardSpacing
        end

        yOffset = rowY + categorySpacing
    end
end

function Prototype2State:AddBuilding(buildingTypeId)
    local buildingType = self.mBuildingTypesById[buildingTypeId]

    if not buildingType then
        print("Warning: Building type not found: " .. tostring(buildingTypeId))
        return
    end

    -- Get the level 0 upgrade data
    local level0 = buildingType.upgradeLevels and buildingType.upgradeLevels[1] or nil
    if not level0 then
        print("Error: Building type " .. buildingTypeId .. " has no upgrade levels!")
        return
    end

    -- Initialize stations array
    local stationsArray = {}
    for i = 1, level0.stations do
        table.insert(stationsArray, {
            id = i,
            recipe = nil,          -- Recipe assigned to this station
            worker = nil,          -- Worker assigned to this station (worker ID)
            state = "IDLE",        -- IDLE, PRODUCING, NO_MATERIALS, NO_WORKER
            progress = 0,          -- Production progress (0.0 to 1.0)
            efficiency = 1.0       -- Worker efficiency multiplier
        })
    end

    -- Create a simple building record (no spatial position)
    local building = {
        id = #self.mBuildings + 1,
        typeId = buildingTypeId,
        type = buildingType,
        name = buildingType.name,
        category = buildingType.category,
        addedTime = love.timer.getTime(),

        -- Upgrade level (starts at 0)
        level = 0,
        maxStations = level0.stations,
        width = level0.width,
        height = level0.height,

        -- Stations array (each station is independent)
        stations = stationsArray,

        -- Local storage (from upgrade level) - shared across all stations
        storage = {
            -- Input storage: {commodityId: currentAmount}
            inputs = {},
            inputCapacity = level0.storage and level0.storage.inputCapacity or 300,
            inputUsed = 0,

            -- Output storage: {commodityId: currentAmount}
            outputs = {},
            outputCapacity = level0.storage and level0.storage.outputCapacity or 300,
            outputUsed = 0
        }
    }

    table.insert(self.mBuildings, building)

    -- Initialize employment tracking for this building
    self.mEmployment.byBuilding[building.id] = {}

    print("Added building: " .. building.name .. " (#" .. building.id .. ")")

    -- Run free agency to check if any workers want to join this building
    self:RunFreeAgency()
end

-- Employment Association Management
function Prototype2State:AssignWorkerToBuilding(worker, building)
    -- Remove from previous building if employed
    if worker.employed and worker.assignedBuilding then
        self:UnassignWorkerFromBuilding(worker)
    end

    -- Find first available station in the building
    local availableStation = nil
    for _, station in ipairs(building.stations) do
        if not station.worker then
            availableStation = station
            break
        end
    end

    if not availableStation then
        print("Cannot assign " .. worker.name .. " to " .. building.name .. " - all stations occupied")
        return false
    end

    -- Assign to new building and station
    worker.employed = true
    worker.assignedBuilding = building.id
    worker.assignedStation = availableStation.id
    worker.hiredDate = love.timer.getTime()

    -- Update association structures
    self.mEmployment.byWorker[worker.id] = building.id
    table.insert(self.mEmployment.byBuilding[building.id], worker.id)
    self.mEmployment.workerLookup[worker.id] = worker

    -- Assign worker to the station
    availableStation.worker = worker.id

    -- Calculate worker efficiency for this station based on work categories
    local efficiency = 1.0
    if building.type.workerEfficiency and worker.workCategories then
        for _, category in ipairs(worker.workCategories) do
            if building.type.workerEfficiency[category] then
                efficiency = math.max(efficiency, building.type.workerEfficiency[category])
            end
        end
    end
    availableStation.efficiency = efficiency

    print("Assigned " .. worker.name .. " to " .. building.name .. " Station " .. availableStation.id .. " (efficiency: " .. efficiency .. ")")
    return true
end

function Prototype2State:UnassignWorkerFromBuilding(worker)
    if not worker.employed or not worker.assignedBuilding then
        return
    end

    local buildingId = worker.assignedBuilding
    local stationId = worker.assignedStation

    -- Remove from association structures
    self.mEmployment.byWorker[worker.id] = nil

    -- Remove from building's worker list
    if self.mEmployment.byBuilding[buildingId] then
        for i, wid in ipairs(self.mEmployment.byBuilding[buildingId]) do
            if wid == worker.id then
                table.remove(self.mEmployment.byBuilding[buildingId], i)
                break
            end
        end
    end

    -- Remove from building's station
    for _, building in ipairs(self.mBuildings) do
        if building.id == buildingId then
            -- Clear the worker from the station
            for _, station in ipairs(building.stations) do
                if station.worker == worker.id then
                    station.worker = nil
                    station.state = "NO_WORKER"
                    station.progress = 0
                    break
                end
            end
            break
        end
    end

    -- Update worker status
    worker.employed = false
    worker.assignedBuilding = nil
    worker.assignedStation = nil

    print("Unassigned " .. worker.name .. " from building #" .. buildingId .. " station #" .. (stationId or "?"))
end

function Prototype2State:GetWorkersForBuilding(buildingId)
    local workerIds = self.mEmployment.byBuilding[buildingId] or {}
    local workers = {}
    for _, workerId in ipairs(workerIds) do
        local worker = self.mEmployment.workerLookup[workerId]
        if worker then
            table.insert(workers, worker)
        end
    end
    return workers
end

function Prototype2State:GetBuildingForWorker(workerId)
    local buildingId = self.mEmployment.byWorker[workerId]
    if not buildingId then
        return nil
    end

    for _, building in ipairs(self.mBuildings) do
        if building.id == buildingId then
            return building
        end
    end
    return nil
end

-- Free Agency System
function Prototype2State:RunFreeAgency()
    -- Check each unemployed worker
    for _, worker in ipairs(self.mWorkerPool) do
        if not worker.employed then
            local bestBuilding = self:FindBestBuildingForWorker(worker)
            if bestBuilding then
                self:AssignWorkerToBuilding(worker, bestBuilding)
            end
        end
    end
end

function Prototype2State:FindBestBuildingForWorker(worker)
    local bestBuilding = nil
    local bestScore = -math.huge

    -- Get worker's work categories from their worker type
    local workerType = nil
    for _, wt in ipairs(self.mWorkerTypes) do
        if wt.id == worker.workerType then
            workerType = wt
            break
        end
    end

    if not workerType or not workerType.workCategories then
        return nil
    end

    -- Check each building
    for _, building in ipairs(self.mBuildings) do
        -- Skip buildings where no station has a recipe selected
        local hasRecipe = false
        for _, station in ipairs(building.stations) do
            if station.recipe then
                hasRecipe = true
                break
            end
        end

        if not hasRecipe then
            goto continue
        end

        local buildingType = building.type

        -- Check if building needs workers from any of this worker's categories
        local canWorkHere = false
        local efficiencyBonus = 0

        if buildingType.workCategories then
            for _, workerCat in ipairs(workerType.workCategories) do
                for _, buildingCat in ipairs(buildingType.workCategories) do
                    if workerCat == buildingCat then
                        canWorkHere = true
                        -- Get efficiency bonus for this category
                        if buildingType.workerEfficiency and buildingType.workerEfficiency[workerCat] then
                            efficiencyBonus = math.max(efficiencyBonus, buildingType.workerEfficiency[workerCat])
                        end
                        break
                    end
                end
            end
        end

        if not canWorkHere then
            goto continue
        end

        -- Check if building has space for more workers (max = number of stations)
        local currentWorkerCount = #(self.mEmployment.byBuilding[building.id] or {})
        local maxWorkers = #building.stations

        if currentWorkerCount >= maxWorkers then
            goto continue
        end

        -- Calculate score based on:
        -- 1. Worker's minimum wage (base)
        -- 2. Efficiency bonus
        -- 3. Current occupancy (prefer less crowded buildings)
        local wage = worker.minimumWage or 10
        local occupancyFactor = 1 - (currentWorkerCount / maxWorkers)

        local score = wage * 10 + efficiencyBonus * 100 + occupancyFactor * 50

        if score > bestScore then
            bestScore = score
            bestBuilding = building
        end

        ::continue::
    end

    return bestBuilding
end

function Prototype2State:HandleRecipeModalClick(mx, my)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Modal dimensions
    local modalWidth = 600
    local modalHeight = 500
    local modalX = (screenW - modalWidth) / 2
    local modalY = (screenH - modalHeight) / 2

    -- Check if clicking outside modal to close
    if mx < modalX or mx > modalX + modalWidth or
       my < modalY or my > modalY + modalHeight then
        self.mShowRecipeModal = false
        self.mSelectedBuilding = nil
        return
    end

    -- Close button
    local closeButtonX = modalX + modalWidth - 35
    local closeButtonY = modalY + 10
    local closeButtonSize = 25
    if mx >= closeButtonX and mx <= closeButtonX + closeButtonSize and
       my >= closeButtonY and my <= closeButtonY + closeButtonSize then
        self.mShowRecipeModal = false
        self.mSelectedBuilding = nil
        return
    end

    -- Filter recipes for this building type
    local buildingTypeId = self.mSelectedBuilding.typeId
    local availableRecipes = {}
    for _, recipe in ipairs(self.mBuildingRecipes) do
        if recipe.buildingType == buildingTypeId then
            table.insert(availableRecipes, recipe)
        end
    end

    -- Check recipe list clicks
    local listY = modalY + 80
    local listHeight = modalHeight - 100
    local recipeHeight = 80
    local recipeSpacing = 10

    local yOffset = listY - self.mRecipeScrollOffset

    for _, recipe in ipairs(availableRecipes) do
        if my >= yOffset and my <= yOffset + recipeHeight and
           mx >= modalX + 20 and mx <= modalX + modalWidth - 20 then
            -- Recipe selected! Assign to the selected station
            if self.mSelectedStation then
                -- Assign to specific station
                self.mSelectedStation.recipe = recipe
                self.mSelectedStation.state = "IDLE"  -- Will be updated in UpdateProduction
                print("Selected recipe: " .. recipe.recipeName .. " for building #" .. self.mSelectedBuilding.id .. " station " .. self.mSelectedStation.id)
            else
                -- Fallback: assign to first empty station (for backwards compatibility)
                local assignedCount = 0
                for _, station in ipairs(self.mSelectedBuilding.stations) do
                    if not station.recipe then
                        station.recipe = recipe
                        station.state = "IDLE"
                        assignedCount = assignedCount + 1
                        break
                    end
                end

                if assignedCount > 0 then
                    print("Selected recipe: " .. recipe.recipeName .. " for building #" .. self.mSelectedBuilding.id .. " (assigned to first empty station)")
                else
                    print("All stations already have recipes assigned")
                end
            end

            -- Run free agency to assign workers to this building
            self:RunFreeAgency()

            -- Close recipe modal and clear selected station
            self.mShowRecipeModal = false
            self.mSelectedStation = nil
            if not self.mShowBuildingModal then
                self.mSelectedBuilding = nil
            end
            return
        end

        yOffset = yOffset + recipeHeight + recipeSpacing
    end
end

function Prototype2State:Render()
    love.graphics.clear(0.92, 0.92, 0.92)

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Render main view - conditional based on view toggle
    if self.mShowHRPoolView then
        self:RenderHRPoolGrid()
    else
        self:RenderBuildingGrid()
    end

    -- Render right panel - conditional based on which panel is active
    if self.mShowHRPanel then
        self:RenderHRPanel()
    elseif self.mShowCommodityPanel then
        self:RenderCommodityPanel()
    else
        self:RenderRightPanel()
    end

    -- Render top bar
    self:RenderTopBar()

    -- Render game speed control
    self:RenderSpeedControl()

    -- Render stats panel (if active, overlays everything except modals)
    if self.mShowStatsPanel then
        self:RenderStatsPanel()
    end

    -- Render building detail modal
    if self.mShowBuildingModal then
        self:RenderBuildingModal()
    end

    -- Render recipe picker modal (on top of everything)
    if self.mShowRecipeModal then
        self:RenderRecipeModal()
    end
end

function Prototype2State:RenderBuildingGrid()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local gridX = 0
    local gridWidth = screenW - self.mRightPanelWidth
    local gridY = 60

    -- Background
    love.graphics.setColor(0.25, 0.25, 0.28)
    love.graphics.rectangle("fill", gridX, gridY, gridWidth, screenH - gridY)

    -- Title and count
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(20)
    love.graphics.print("Building Cards", 20, 75)

    love.graphics.setNewFont(14)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(#self.mBuildings .. " buildings", 20, 105)

    -- If no buildings, show message
    if #self.mBuildings == 0 then
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.setNewFont(18)
        local text = "Select buildings from the right panel to add building cards"
        local textWidth = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, (gridWidth - textWidth) / 2, screenH / 2 - 20)
        return
    end

    -- Scrollable area
    local listY = 140
    local listHeight = screenH - listY - 10
    local padding = 20
    local cols = 3
    local cardSpacing = 15
    local categorySpacing = 30

    -- Calculate card dimensions
    local availableWidth = gridWidth - (padding * 2) - (cardSpacing * (cols - 1))
    local cardWidth = availableWidth / cols
    local cardHeight = 120

    -- Enable scissor for scrolling
    love.graphics.setScissor(gridX, listY, gridWidth, listHeight)

    -- Group buildings by category
    local buildingsByCategory = {}
    local categoryOrder = {}  -- Track order
    for _, building in ipairs(self.mBuildings) do
        local cat = building.category or "Uncategorized"
        if not buildingsByCategory[cat] then
            buildingsByCategory[cat] = {}
            table.insert(categoryOrder, cat)
        end
        table.insert(buildingsByCategory[cat], building)
    end

    -- Calculate total content height FIRST
    local totalContentHeight = 0
    for _, categoryName in ipairs(categoryOrder) do
        local buildings = buildingsByCategory[categoryName]
        totalContentHeight = totalContentHeight + 25  -- Category header

        -- Calculate rows needed for this category
        local numRows = math.ceil(#buildings / cols)
        totalContentHeight = totalContentHeight + (numRows * (cardHeight + cardSpacing))
        totalContentHeight = totalContentHeight + categorySpacing
    end

    -- Update scroll max BEFORE rendering
    self.mBuildingScrollMax = math.max(0, totalContentHeight - listHeight)

    -- Render buildings in grid layout
    local yOffset = listY - self.mBuildingScrollOffset

    for _, categoryName in ipairs(categoryOrder) do
        local buildings = buildingsByCategory[categoryName]
        -- Category header
        if yOffset + 25 >= listY and yOffset <= listY + listHeight then
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.setNewFont(16)
            love.graphics.print(categoryName, padding, yOffset)
        end
        yOffset = yOffset + 25
        totalContentHeight = totalContentHeight + 25

        -- Render buildings in rows of 3
        local col = 0
        local rowY = yOffset
        local startY = yOffset

        for i, building in ipairs(buildings) do
            local x = padding + (col * (cardWidth + cardSpacing))

            -- Render card if in visible area
            if rowY + cardHeight >= listY and rowY <= listY + listHeight then
                self:RenderBuildingCard(building, x, rowY, cardWidth, cardHeight)
            end

            col = col + 1
            if col >= cols then
                col = 0
                rowY = rowY + cardHeight + cardSpacing
            end
        end

        -- Move to next row if we didn't complete the last row
        if col > 0 then
            rowY = rowY + cardHeight + cardSpacing
        end

        -- Calculate height used by this category
        local categoryHeight = rowY - startY
        totalContentHeight = totalContentHeight + categoryHeight + categorySpacing
        yOffset = rowY + categorySpacing
    end

    -- Update scroll max
    self.mBuildingScrollMax = math.max(0, totalContentHeight - listHeight)

    -- Disable scissor
    love.graphics.setScissor()

    -- Draw scrollbar if needed
    if self.mBuildingScrollMax > 0 then
        local scrollbarX = gridWidth - 8
        local scrollbarWidth = 6
        local scrollbarHeight = listHeight * (listHeight / totalContentHeight)
        local scrollbarY = listY + (self.mBuildingScrollOffset / self.mBuildingScrollMax) * (listHeight - scrollbarHeight)

        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 3, 3)
    end
end

function Prototype2State:RenderBuildingCard(building, x, y, width, height)
    -- Card background
    love.graphics.setColor(0.35, 0.35, 0.38)
    love.graphics.rectangle("fill", x, y, width, height, 8, 8)

    -- Card border
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, 8, 8)

    -- Building type color indicator
    if building.type.color then
        love.graphics.setColor(unpack(building.type.color))
        love.graphics.rectangle("fill", x, y, 8, height, 8, 8, 0, 0)
    end

    -- Building name and ID
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(18)
    love.graphics.print(building.name, x + 15, y + 10)

    love.graphics.setNewFont(12)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("ID: " .. building.id, x + 15, y + 35)

    -- Station summary info
    local stationsActive = 0
    local stationsIdle = 0
    local stationsNoWorker = 0
    local stationsNoMaterial = 0

    for _, station in ipairs(building.stations) do
        if station.state == "PRODUCING" then
            stationsActive = stationsActive + 1
        elseif station.state == "IDLE" then
            stationsIdle = stationsIdle + 1
        elseif station.state == "NO_WORKER" then
            stationsNoWorker = stationsNoWorker + 1
        elseif station.state == "NO_MATERIALS" then
            stationsNoMaterial = stationsNoMaterial + 1
        end
    end

    love.graphics.setColor(0.5, 0.8, 0.5)
    love.graphics.print("Stations: " .. #building.stations, x + 15, y + 55)

    -- Production state summary with color coding
    local stateColor = {0.6, 0.6, 0.6}
    local stateText = ""

    if stationsActive > 0 then
        stateColor = {0.4, 0.8, 0.4}  -- Green
        stateText = stationsActive .. " producing"
    elseif stationsNoWorker > 0 then
        stateColor = {0.8, 0.5, 0.5}  -- Red
        stateText = stationsNoWorker .. " need workers"
    elseif stationsNoMaterial > 0 then
        stateColor = {0.9, 0.7, 0.3}  -- Yellow
        stateText = stationsNoMaterial .. " need materials"
    elseif stationsIdle > 0 then
        stateColor = {0.8, 0.6, 0.3}  -- Orange
        stateText = stationsIdle .. " idle (no recipe)"
    else
        stateText = "All stations idle"
    end

    love.graphics.setColor(unpack(stateColor))
    love.graphics.print("State: " .. stateText, x + 15, y + 75)

    -- Worker info (show stations)
    local workers = self:GetWorkersForBuilding(building.id)
    local workerCount = #workers

    love.graphics.setColor(0.7, 0.7, 1.0)
    love.graphics.print("Workers: " .. workerCount .. "/" .. #building.stations .. " stations", x + 15, y + 95)

    -- Progress bar background
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", x + 15, y + height - 25, width - 30, 15, 3, 3)

    -- Progress bar fill (average progress across all active stations)
    local totalProgress = 0
    local activeStationCount = 0

    for _, station in ipairs(building.stations) do
        if station.state == "PRODUCING" and station.progress > 0 then
            totalProgress = totalProgress + station.progress
            activeStationCount = activeStationCount + 1
        end
    end

    local avgProgress = activeStationCount > 0 and (totalProgress / activeStationCount) or 0

    -- Progress bar color based on overall state
    local progressBarColor = {0.4, 0.7, 0.4}  -- Default green

    if stationsActive > 0 then
        progressBarColor = {0.4, 0.8, 0.4}  -- Bright green
    elseif stationsNoMaterial > 0 then
        progressBarColor = {0.9, 0.7, 0.3}  -- Yellow
    elseif stationsNoWorker > 0 then
        progressBarColor = {0.8, 0.5, 0.5}  -- Red
    else
        progressBarColor = {0.6, 0.6, 0.6}  -- Gray
    end

    love.graphics.setColor(unpack(progressBarColor))
    local progressWidth = (width - 30) * avgProgress
    if progressWidth > 0 then
        love.graphics.rectangle("fill", x + 15, y + height - 25, progressWidth, 15, 3, 3)
    end

    -- Progress percentage text
    if stationsActive > 0 and avgProgress > 0 then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(11)
        local progressText = string.format("%d%%", avgProgress * 100)
        love.graphics.print(progressText, x + width - 45, y + height - 24)
    end
end

function Prototype2State:RenderRightPanel()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local rightPanelX = screenW - self.mRightPanelWidth

    -- Panel background
    love.graphics.setColor(0.28, 0.28, 0.32)
    love.graphics.rectangle("fill", rightPanelX, 60, self.mRightPanelWidth, screenH - 60)

    -- Panel title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(20)
    love.graphics.print("Add Building", rightPanelX + 20, 75)

    -- Scrollable area dimensions
    local listY = 110
    local listHeight = screenH - listY - 10
    local listWidth = self.mRightPanelWidth - 10  -- Leave space for scrollbar

    -- Enable scissor (clipping) for scrollable area
    love.graphics.setScissor(rightPanelX, listY, listWidth, listHeight)

    -- Render building types by category (with scroll offset)
    local yOffset = listY - self.mRightScrollOffset
    local itemHeight = 60
    local spacing = 10
    local categorySpacing = 30

    local totalContentHeight = 0

    for _, category in ipairs(self.mCategories) do
        -- Category header
        if yOffset + 25 >= listY and yOffset <= listY + listHeight then
            love.graphics.setColor(0.9, 0.9, 0.5)
            love.graphics.setNewFont(14)
            love.graphics.print(category.name, rightPanelX + 20, yOffset)
        end
        yOffset = yOffset + 25
        totalContentHeight = totalContentHeight + 25

        -- Building type items
        for _, buildingType in ipairs(category.types) do
            -- Skip rendering if outside visible area (optimization)
            if yOffset + itemHeight >= listY and yOffset <= listY + listHeight then
                local mx, my = love.mouse.getPosition()
                local isHovered = mx >= rightPanelX + 15 and mx <= rightPanelX + self.mRightPanelWidth - 15 and
                                 my >= yOffset and my <= yOffset + itemHeight

                -- Item background
                if isHovered then
                    love.graphics.setColor(0.45, 0.45, 0.48)
                else
                    love.graphics.setColor(0.35, 0.35, 0.38)
                end
                love.graphics.rectangle("fill", rightPanelX + 15, yOffset, self.mRightPanelWidth - 40, itemHeight, 5, 5)

                -- Color indicator
                if buildingType.data.color then
                    love.graphics.setColor(unpack(buildingType.data.color))
                    love.graphics.rectangle("fill", rightPanelX + 15, yOffset, 6, itemHeight, 5, 5, 0, 0)
                end

                -- Building name
                love.graphics.setColor(1, 1, 1)
                love.graphics.setNewFont(16)
                love.graphics.print(buildingType.data.name, rightPanelX + 28, yOffset + 10)

                -- Building label (short code)
                love.graphics.setNewFont(12)
                love.graphics.setColor(0.7, 0.7, 0.7)
                if buildingType.data.label then
                    love.graphics.print(buildingType.data.label, rightPanelX + 28, yOffset + 35)
                end
            end

            yOffset = yOffset + itemHeight + spacing
            totalContentHeight = totalContentHeight + itemHeight + spacing
        end

        yOffset = yOffset + categorySpacing
        totalContentHeight = totalContentHeight + categorySpacing
    end

    -- Calculate max scroll
    self.mRightScrollMax = math.max(0, totalContentHeight - listHeight)

    -- Disable scissor
    love.graphics.setScissor()

    -- Draw scrollbar if needed
    if self.mRightScrollMax > 0 then
        local scrollbarX = rightPanelX + self.mRightPanelWidth - 8
        local scrollbarWidth = 6
        local scrollbarHeight = listHeight * (listHeight / totalContentHeight)
        local scrollbarY = listY + (self.mRightScrollOffset / self.mRightScrollMax) * (listHeight - scrollbarHeight)

        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 3, 3)
    end
end

function Prototype2State:RenderHRPoolGrid()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local gridX = 0
    local gridWidth = screenW - self.mRightPanelWidth
    local gridY = 60

    -- Background
    love.graphics.setColor(0.25, 0.25, 0.28)
    love.graphics.rectangle("fill", gridX, gridY, gridWidth, screenH - gridY)

    -- Title and count
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(20)
    love.graphics.print("Worker Pool", 20, 75)

    love.graphics.setNewFont(14)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(#self.mWorkerPool .. " workers", 20, 105)

    -- If no workers, show message
    if #self.mWorkerPool == 0 then
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.setNewFont(18)
        local text = "Use Human Resources panel to hire workers"
        local textWidth = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, (gridWidth - textWidth) / 2, screenH / 2 - 20)
        return
    end

    -- Scrollable area
    local listY = 140
    local listHeight = screenH - listY - 10
    local padding = 20
    local cols = 3
    local cardSpacing = 15
    local categorySpacing = 30

    -- Calculate card dimensions
    local availableWidth = gridWidth - (padding * 2) - (cardSpacing * (cols - 1))
    local cardWidth = availableWidth / cols
    local cardHeight = 140  -- Taller cards for worker info

    -- Group workers by category
    local workersByCategory = {}
    local categoryOrder = {}  -- Track order for deterministic iteration
    for _, worker in ipairs(self.mWorkerPool) do
        local cat = worker.category or "Uncategorized"
        if not workersByCategory[cat] then
            workersByCategory[cat] = {}
            table.insert(categoryOrder, cat)  -- Maintain order
        end
        table.insert(workersByCategory[cat], worker)
    end

    -- Calculate total content height FIRST (before rendering)
    local totalContentHeight = 0
    for _, categoryName in ipairs(categoryOrder) do
        local workers = workersByCategory[categoryName]
        totalContentHeight = totalContentHeight + 25  -- Category header

        -- Calculate rows needed for this category
        local numRows = math.ceil(#workers / cols)
        totalContentHeight = totalContentHeight + (numRows * (cardHeight + cardSpacing))
        totalContentHeight = totalContentHeight + categorySpacing
    end

    -- Update scroll max BEFORE rendering
    self.mBuildingScrollMax = math.max(0, totalContentHeight - listHeight)

    -- Enable scissor for scrolling
    love.graphics.setScissor(gridX, listY, gridWidth, listHeight)

    -- Render workers in grid layout with deterministic order
    local yOffset = listY - self.mBuildingScrollOffset

    for _, categoryName in ipairs(categoryOrder) do
        local workers = workersByCategory[categoryName]

        -- Category header
        if yOffset + 25 >= listY and yOffset <= listY + listHeight then
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.setNewFont(16)
            love.graphics.print(categoryName .. " (" .. #workers .. ")", padding, yOffset)
        end
        yOffset = yOffset + 25

        -- Render workers in rows of 3
        local col = 0
        local rowY = yOffset

        for i, worker in ipairs(workers) do
            local x = padding + (col * (cardWidth + cardSpacing))

            -- Render card if in visible area
            if rowY + cardHeight >= listY and rowY <= listY + listHeight then
                self:RenderWorkerCard(worker, x, rowY, cardWidth, cardHeight)
            end

            col = col + 1
            if col >= cols then
                col = 0
                rowY = rowY + cardHeight + cardSpacing
            end
        end

        -- Move to next row if we didn't complete the last row
        if col > 0 then
            rowY = rowY + cardHeight + cardSpacing
        end

        yOffset = rowY + categorySpacing
    end

    -- Disable scissor
    love.graphics.setScissor()

    -- Draw scrollbar if needed
    if self.mBuildingScrollMax > 0 then
        local scrollbarX = gridWidth - 8
        local scrollbarWidth = 6
        local scrollbarHeight = listHeight * (listHeight / totalContentHeight)
        local scrollbarY = listY + (self.mBuildingScrollOffset / self.mBuildingScrollMax) * (listHeight - scrollbarHeight)

        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 3, 3)
    end
end

function Prototype2State:RenderWorkerCard(worker, x, y, width, height)
    -- Card background
    local bgColor = worker.employed and {0.4, 0.45, 0.38} or {0.35, 0.35, 0.38}
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, width, height, 8, 8)

    -- Card border
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, 8, 8)

    -- Status indicator (left edge)
    if worker.employed then
        love.graphics.setColor(0.4, 0.7, 0.4)  -- Green if employed
    else
        love.graphics.setColor(0.6, 0.6, 0.6)  -- Gray if unemployed
    end
    love.graphics.rectangle("fill", x, y, 6, height, 8, 8, 0, 0)

    -- Worker name
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(16)
    love.graphics.print(worker.name, x + 12, y + 10)

    -- Worker type
    love.graphics.setNewFont(13)
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.print(worker.workerTypeName, x + 12, y + 32)

    -- Skill level and age
    love.graphics.setNewFont(11)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Level: " .. worker.skillLevel, x + 12, y + 52)
    love.graphics.print("Age: " .. worker.age, x + 12, y + 68)

    -- Gender and status
    love.graphics.print(worker.gender .. ", " .. worker.status, x + 12, y + 84)

    -- Employment status and workplace
    love.graphics.setNewFont(11)
    if worker.employed then
        love.graphics.setColor(0.4, 0.8, 0.4)
        love.graphics.print("EMPLOYED", x + 12, y + 100)

        -- Show workplace
        local workplace = self:GetBuildingForWorker(worker.id)
        if workplace then
            love.graphics.setColor(0.6, 0.7, 0.8)
            love.graphics.setNewFont(10)
            love.graphics.print("at " .. workplace.name .. " #" .. workplace.id, x + 12, y + 114)
        end
    else
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("Available for work", x + 12, y + 100)
    end

    -- Wage
    love.graphics.setColor(0.9, 0.9, 0.5)
    love.graphics.setNewFont(11)
    love.graphics.print("$" .. worker.currentWage .. "/hr", x + width - 50, y + height - 25)
end

function Prototype2State:RenderTopBar()
    local screenW = love.graphics.getWidth()

    -- Top bar background
    love.graphics.setColor(0.2, 0.2, 0.23)
    love.graphics.rectangle("fill", 0, 0, screenW, 60)

    -- Buildings button
    local buildingsButtonX = 20
    local buildingsButtonW = 120
    if not self.mShowHRPoolView then
        love.graphics.setColor(0.3, 0.6, 0.8)  -- Highlighted when active
    else
        love.graphics.setColor(0.4, 0.4, 0.5)  -- Normal
    end
    love.graphics.rectangle("fill", buildingsButtonX, 15, buildingsButtonW, 30, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(14)
    love.graphics.print("Buildings", buildingsButtonX + 25, 22)

    -- HR Pool button
    local hrPoolButtonX = 150
    local hrPoolButtonW = 120
    if self.mShowHRPoolView then
        love.graphics.setColor(0.5, 0.7, 0.4)  -- Highlighted when active
    else
        love.graphics.setColor(0.4, 0.4, 0.5)  -- Normal
    end
    love.graphics.rectangle("fill", hrPoolButtonX, 15, hrPoolButtonW, 30, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(14)
    love.graphics.print("HR Pool", hrPoolButtonX + 30, 22)

    -- Human Resources button
    local hrButtonX = screenW - 480
    local hrButtonW = 170
    if self.mShowHRPanel then
        love.graphics.setColor(0.3, 0.6, 0.8)
    else
        love.graphics.setColor(0.4, 0.4, 0.5)
    end
    love.graphics.rectangle("fill", hrButtonX, 15, hrButtonW, 30, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(14)
    love.graphics.print("Human Resources", hrButtonX + 12, 22)

    -- Commodity Resources button
    local commButtonX = screenW - 290
    local commButtonW = 170
    if self.mShowCommodityPanel then
        love.graphics.setColor(0.3, 0.6, 0.8)
    else
        love.graphics.setColor(0.4, 0.4, 0.5)
    end
    love.graphics.rectangle("fill", commButtonX, 15, commButtonW, 30, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(14)
    love.graphics.print("Commodity Resources", commButtonX + 5, 22)

    -- Stats button
    local statsButtonX = screenW - 100
    local statsButtonW = 80
    if self.mShowStatsPanel then
        love.graphics.setColor(0.8, 0.6, 0.3)
    else
        love.graphics.setColor(0.4, 0.4, 0.5)
    end
    love.graphics.rectangle("fill", statsButtonX, 15, statsButtonW, 30, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(14)
    love.graphics.print("Stats", statsButtonX + 22, 22)
end

function Prototype2State:RenderSpeedControl()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Position at bottom left
    local controlX = 20
    local controlY = screenH - 60
    local controlWidth = 200
    local controlHeight = 40

    -- Background
    love.graphics.setColor(0.2, 0.2, 0.23)
    love.graphics.rectangle("fill", controlX, controlY, controlWidth, controlHeight, 5, 5)

    -- Speed label
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(12)
    love.graphics.print("Game Speed:", controlX + 10, controlY + 5)

    -- Current speed value
    local speedValue = self.mTimeScales[self.mTimeScale]
    love.graphics.setColor(0.7, 0.9, 0.7)
    love.graphics.setNewFont(14)
    love.graphics.print(speedValue .. "x", controlX + 85, controlY + 3)

    -- Decrease button (-)
    local btnY = controlY + 22
    local btnSize = 25
    local minusX = controlX + 10
    love.graphics.setColor(0.5, 0.3, 0.3)
    love.graphics.rectangle("fill", minusX, btnY, btnSize, btnSize, 3, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(18)
    love.graphics.print("-", minusX + 8, btnY + 1)

    -- Speed indicator
    love.graphics.setNewFont(12)
    local speedText = self.mTimeScale
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(speedText, controlX + 50, btnY + 4)

    -- Increase button (+)
    local plusX = controlX + 165
    love.graphics.setColor(0.3, 0.5, 0.3)
    love.graphics.rectangle("fill", plusX, btnY, btnSize, btnSize, 3, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(18)
    love.graphics.print("+", plusX + 6, btnY + 1)
end

function Prototype2State:RenderHRPanel()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local rightPanelX = screenW - self.mRightPanelWidth

    -- Panel background
    love.graphics.setColor(0.28, 0.28, 0.32)
    love.graphics.rectangle("fill", rightPanelX, 60, self.mRightPanelWidth, screenH - 60)

    -- Panel title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(20)
    love.graphics.print("Human Resources", rightPanelX + 20, 75)

    -- Scrollable area dimensions
    local listY = 110
    local listHeight = (screenH - 40) - listY  -- Stop before summary area
    local listWidth = self.mRightPanelWidth - 10

    -- Enable scissor (clipping) for scrollable area
    love.graphics.setScissor(rightPanelX, listY, listWidth, listHeight)

    -- Render worker types (with scroll offset)
    local yOffset = listY - self.mHRScrollOffset
    local itemHeight = 50
    local spacing = 5
    local totalContentHeight = 0

    for _, wt in ipairs(self.mWorkerTypes) do
        -- Skip rendering if outside visible area (optimization)
        if yOffset + itemHeight >= listY and yOffset <= listY + listHeight then
            -- Item background
            love.graphics.setColor(0.35, 0.35, 0.38)
            love.graphics.rectangle("fill", rightPanelX + 15, yOffset, self.mRightPanelWidth - 30, itemHeight, 5, 5)

            -- Worker name
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(14)
            love.graphics.print(wt.name, rightPanelX + 25, yOffset + 8)

            -- Worker category (smaller, gray)
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.setNewFont(11)
            love.graphics.print(wt.category, rightPanelX + 25, yOffset + 28)

            -- Count display
            local count = self.mWorkerCounts[wt.id] or 0
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(16)
            local countText = tostring(count)
            local countWidth = love.graphics.getFont():getWidth(countText)
            love.graphics.print(countText, rightPanelX + self.mRightPanelWidth - 120, yOffset + 15)

            -- - button
            local buttonY = yOffset + 15
            local buttonSize = 25
            local minusX = rightPanelX + self.mRightPanelWidth - 80
            love.graphics.setColor(0.5, 0.3, 0.3)
            love.graphics.rectangle("fill", minusX, buttonY, buttonSize, buttonSize, 3, 3)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(18)
            love.graphics.print("-", minusX + 8, buttonY + 1)

            -- + button
            local plusX = rightPanelX + self.mRightPanelWidth - 40
            love.graphics.setColor(0.3, 0.5, 0.3)
            love.graphics.rectangle("fill", plusX, buttonY, buttonSize, buttonSize, 3, 3)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(18)
            love.graphics.print("+", plusX + 6, buttonY + 1)
        end

        yOffset = yOffset + itemHeight + spacing
        totalContentHeight = totalContentHeight + itemHeight + spacing
    end

    -- Calculate max scroll
    self.mHRScrollMax = math.max(0, totalContentHeight - listHeight)

    -- Disable scissor
    love.graphics.setScissor()

    -- Draw scrollbar if needed
    if self.mHRScrollMax > 0 then
        local scrollbarX = rightPanelX + self.mRightPanelWidth - 8
        local scrollbarWidth = 6
        local scrollbarHeight = listHeight * (listHeight / totalContentHeight)
        local scrollbarY = listY + (self.mHRScrollOffset / self.mHRScrollMax) * (listHeight - scrollbarHeight)

        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 3, 3)
    end

    -- Summary at bottom
    local totalWorkers = 0
    for _, count in pairs(self.mWorkerCounts) do
        totalWorkers = totalWorkers + count
    end

    love.graphics.setColor(0.2, 0.2, 0.23)
    love.graphics.rectangle("fill", rightPanelX, screenH - 40, self.mRightPanelWidth, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(14)
    love.graphics.print("Total Workers: " .. totalWorkers, rightPanelX + 20, screenH - 25)
end

function Prototype2State:RenderCommodityPanel()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local rightPanelX = screenW - self.mRightPanelWidth

    -- Panel background
    love.graphics.setColor(0.28, 0.28, 0.32)
    love.graphics.rectangle("fill", rightPanelX, 60, self.mRightPanelWidth, screenH - 60)

    -- Panel title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(20)
    love.graphics.print("Commodities", rightPanelX + 20, 75)

    -- Get unique categories from commodities
    local categories = {
        {id = "all", name = "All"},
        {id = "nonzero", name = "In Stock"}
    }
    local categorySet = {}
    for _, c in ipairs(self.mCommodities) do
        if c.category and not categorySet[c.category] then
            categorySet[c.category] = true
            table.insert(categories, {id = c.category, name = c.category})
        end
    end
    -- Sort categories (skip first 2: all, nonzero)
    table.sort(categories, function(a, b)
        if a.id == "all" then return true end
        if b.id == "all" then return false end
        if a.id == "nonzero" then return true end
        if b.id == "nonzero" then return false end
        return a.name < b.name
    end)

    -- LEFT SIDE: Category filter bar
    local filterY = 110
    local filterWidth = 150
    local filterX = rightPanelX
    local filterHeight = (screenH - 40) - filterY  -- Stop before summary area

    -- Dark background for category bar
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", filterX, filterY, filterWidth, filterHeight)

    -- Enable scissor for category scrolling
    love.graphics.setScissor(filterX, filterY, filterWidth, filterHeight)

    -- Draw category buttons with scroll
    local btnY = filterY + 5 - self.mCommodityCategoryScrollOffset
    local categoryContentHeight = 0

    for i, category in ipairs(categories) do
        local btnX = filterX + 5
        local btnW = filterWidth - 10
        local btnH = 25

        -- Only render if visible
        if btnY + btnH >= filterY and btnY <= filterY + filterHeight then
            local isSelected = (self.mSelectedCommodityCategory == category.id) or
                              (self.mSelectedCommodityCategory == nil and category.id == "all")

            if isSelected then
                love.graphics.setColor(0.3, 0.5, 0.7)  -- Blue highlight
            else
                love.graphics.setColor(0.25, 0.25, 0.25)
            end

            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 3, 3)

            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(13)
            love.graphics.print(category.name, btnX + 8, btnY + 5)
        end

        btnY = btnY + 28
        categoryContentHeight = categoryContentHeight + 28
    end

    -- Calculate max scroll for categories
    self.mCommodityCategoryScrollMax = math.max(0, categoryContentHeight - filterHeight)

    love.graphics.setScissor()

    -- Draw scrollbar for categories if needed
    if self.mCommodityCategoryScrollMax > 0 then
        local scrollbarHeight = filterHeight * (filterHeight / categoryContentHeight)
        local scrollbarY = filterY + (self.mCommodityCategoryScrollOffset / self.mCommodityCategoryScrollMax) * (filterHeight - scrollbarHeight)

        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", filterX + filterWidth - 8, scrollbarY, 6, scrollbarHeight, 3, 3)
    end

    -- RIGHT SIDE: Commodity list
    local listX = filterX + filterWidth + 10
    local listY = filterY + 5
    local listWidth = self.mRightPanelWidth - filterWidth - 20
    local listHeight = (screenH - 40) - listY  -- Stop before summary area

    -- Enable scissor (clipping) for scrollable area
    love.graphics.setScissor(listX, listY, listWidth, listHeight)

    -- Filter commodities by selected category
    local filteredCommodities = {}
    for _, c in ipairs(self.mCommodities) do
        local include = false

        if self.mSelectedCommodityCategory == nil or self.mSelectedCommodityCategory == "all" then
            include = true
        elseif self.mSelectedCommodityCategory == "nonzero" then
            include = (self.mCommodityCounts[c.id] or 0) > 0
        else
            include = c.category == self.mSelectedCommodityCategory
        end

        if include then
            table.insert(filteredCommodities, c)
        end
    end

    -- Render filtered commodities (with scroll offset)
    local yOffset = listY - self.mCommodityScrollOffset
    local itemHeight = 50
    local spacing = 5
    local totalContentHeight = 0

    for _, c in ipairs(filteredCommodities) do
        -- Skip rendering if outside visible area (optimization)
        if yOffset + itemHeight >= listY and yOffset <= listY + listHeight then
            local count = self.mCommodityCounts[c.id] or 0

            -- Item background (highlight if count > 0)
            if count > 0 then
                love.graphics.setColor(0.4, 0.4, 0.45)
            else
                love.graphics.setColor(0.35, 0.35, 0.38)
            end
            love.graphics.rectangle("fill", listX, yOffset, listWidth, itemHeight - 2, 5, 5)

            -- Commodity name
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(14)
            love.graphics.print(c.name, listX + 10, yOffset + 8)

            -- Commodity category (smaller, gray)
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.setNewFont(11)
            love.graphics.print(c.category, listX + 10, yOffset + 28)

            -- Count display
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(16)
            local countText = tostring(count)
            local countWidth = love.graphics.getFont():getWidth(countText)
            love.graphics.print(countText, listX + listWidth - 100, yOffset + 15)

            -- - button (subtract 10)
            local buttonY = yOffset + 15
            local buttonSize = 25
            local minusX = listX + listWidth - 60
            love.graphics.setColor(0.5, 0.3, 0.3)
            love.graphics.rectangle("fill", minusX, buttonY, buttonSize, buttonSize, 3, 3)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(18)
            love.graphics.print("-", minusX + 8, buttonY + 1)

            -- + button (add 10)
            local plusX = listX + listWidth - 30
            love.graphics.setColor(0.3, 0.5, 0.3)
            love.graphics.rectangle("fill", plusX, buttonY, buttonSize, buttonSize, 3, 3)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(18)
            love.graphics.print("+", plusX + 6, buttonY + 1)
        end

        yOffset = yOffset + itemHeight + spacing
        totalContentHeight = totalContentHeight + itemHeight + spacing
    end

    -- Calculate max scroll
    self.mCommodityScrollMax = math.max(0, totalContentHeight - listHeight)

    -- Disable scissor
    love.graphics.setScissor()

    -- Draw scrollbar if needed
    if self.mCommodityScrollMax > 0 then
        local scrollbarX = rightPanelX + self.mRightPanelWidth - 8
        local scrollbarWidth = 6
        local scrollbarHeight = listHeight * (listHeight / totalContentHeight)
        local scrollbarY = listY + (self.mCommodityScrollOffset / self.mCommodityScrollMax) * (listHeight - scrollbarHeight)

        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 3, 3)
    end

    -- Summary at bottom
    local totalCommodities = 0
    local uniqueCommodities = 0
    for id, count in pairs(self.mCommodityCounts) do
        totalCommodities = totalCommodities + count
        if count > 0 then
            uniqueCommodities = uniqueCommodities + 1
        end
    end

    love.graphics.setColor(0.2, 0.2, 0.23)
    love.graphics.rectangle("fill", rightPanelX, screenH - 40, self.mRightPanelWidth, 40)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(12)
    love.graphics.print("Total: " .. totalCommodities .. " | Types: " .. uniqueCommodities, rightPanelX + 20, screenH - 25)
end

function Prototype2State:RenderRecipeModal()
    if not self.mSelectedBuilding then
        return
    end

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
    love.graphics.setNewFont(20)
    love.graphics.print("Select Recipe", modalX + 20, modalY + 15)

    -- Building name
    love.graphics.setNewFont(14)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("for " .. self.mSelectedBuilding.name .. " (#" .. self.mSelectedBuilding.id .. ")", modalX + 20, modalY + 45)

    -- Close button (X)
    local closeButtonX = modalX + modalWidth - 35
    local closeButtonY = modalY + 10
    local closeButtonSize = 25
    love.graphics.setColor(0.7, 0.3, 0.3)
    love.graphics.rectangle("fill", closeButtonX, closeButtonY, closeButtonSize, closeButtonSize, 3, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(16)
    love.graphics.print("X", closeButtonX + 7, closeButtonY + 2)

    -- Filter recipes for this building type
    local buildingTypeId = self.mSelectedBuilding.typeId

    local availableRecipes = {}
    for _, recipe in ipairs(self.mBuildingRecipes) do
        if recipe.buildingType == buildingTypeId then
            table.insert(availableRecipes, recipe)
        end
    end

    -- Recipe list area
    local listY = modalY + 80
    local listHeight = modalHeight - 100
    local recipeHeight = 80
    local recipeSpacing = 10

    -- Enable scissor for scrolling
    love.graphics.setScissor(modalX + 20, listY, modalWidth - 40, listHeight)

    if #availableRecipes == 0 then
        -- No recipes available
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.setNewFont(16)
        love.graphics.print("No recipes available for this building type", modalX + 40, listY + 50)
    else
        -- Render recipes
        local yOffset = listY - self.mRecipeScrollOffset

        for _, recipe in ipairs(availableRecipes) do
            -- Recipe card
            love.graphics.setColor(0.3, 0.3, 0.33)
            love.graphics.rectangle("fill", modalX + 20, yOffset, modalWidth - 40, recipeHeight, 5, 5)

            -- Recipe card border (hover effect would go here)
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", modalX + 20, yOffset, modalWidth - 40, recipeHeight, 5, 5)

            -- Recipe name
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(16)
            love.graphics.print(recipe.recipeName, modalX + 30, yOffset + 10)

            -- Production time
            love.graphics.setNewFont(12)
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("Time: " .. recipe.productionTime .. "s", modalX + 30, yOffset + 35)

            -- Inputs
            local inputsText = "In: "
            local inputCount = 0
            for input, qty in pairs(recipe.inputs or {}) do
                if inputCount > 0 then inputsText = inputsText .. ", " end
                inputsText = inputsText .. input .. " x" .. qty
                inputCount = inputCount + 1
            end
            if inputCount == 0 then inputsText = inputsText .. "None" end
            love.graphics.print(inputsText, modalX + 30, yOffset + 50)

            -- Outputs
            local outputsText = "Out: "
            local outputCount = 0
            for output, qty in pairs(recipe.outputs or {}) do
                if outputCount > 0 then outputsText = outputsText .. ", " end
                outputsText = outputsText .. output .. " x" .. qty
                outputCount = outputCount + 1
            end
            if outputCount == 0 then outputsText = outputsText .. "None" end
            love.graphics.setColor(0.5, 0.8, 0.5)
            love.graphics.print(outputsText, modalX + 30, yOffset + 65)

            yOffset = yOffset + recipeHeight + recipeSpacing
        end

        -- Calculate scroll max
        local totalContentHeight = #availableRecipes * (recipeHeight + recipeSpacing)
        self.mRecipeScrollMax = math.max(0, totalContentHeight - listHeight)
    end

    -- Disable scissor
    love.graphics.setScissor()

    -- Draw scrollbar if needed
    if self.mRecipeScrollMax > 0 then
        local totalContentHeight = #availableRecipes * (recipeHeight + recipeSpacing)
        local scrollbarX = modalX + modalWidth - 25
        local scrollbarWidth = 6
        local scrollbarHeight = listHeight * (listHeight / totalContentHeight)
        local scrollbarY = listY + (self.mRecipeScrollOffset / self.mRecipeScrollMax) * (listHeight - scrollbarHeight)

        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 3, 3)
    end
end

function Prototype2State:OnMouseWheel(dx, dy)
    local mx, my = love.mouse.getPosition()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local rightPanelX = screenW - self.mRightPanelWidth

    -- If stats panel is open, scroll it instead
    if self.mShowStatsPanel then
        -- Stats panel dimensions (same as in RenderStatsPanel)
        local leftPanelX = 20
        local leftPanelW = 350
        local panelY = 60

        -- Check if mouse is over left panel (commodity list)
        if mx >= leftPanelX and mx <= leftPanelX + leftPanelW and my >= panelY then
            self.mStatsScrollOffset = self.mStatsScrollOffset - dy * 30
            self.mStatsScrollOffset = math.max(0, math.min(self.mStatsScrollOffset, self.mStatsScrollMax))
        end
        return
    end

    -- If building modal is open, scroll it instead
    if self.mShowBuildingModal then
        self.mBuildingModalScrollOffset = self.mBuildingModalScrollOffset - dy * 30
        self.mBuildingModalScrollOffset = math.max(0, math.min(self.mBuildingModalScrollOffset, self.mBuildingModalScrollMax))
        return
    end

    -- If recipe modal is open, scroll it instead
    if self.mShowRecipeModal then
        local modalWidth = 600
        local modalHeight = 500
        local modalX = (screenW - modalWidth) / 2
        local modalY = (screenH - modalHeight) / 2

        -- Check if mouse is over the modal
        if mx >= modalX and mx <= modalX + modalWidth and
           my >= modalY and my <= modalY + modalHeight then
            self.mRecipeScrollOffset = self.mRecipeScrollOffset - dy * 30
            self.mRecipeScrollOffset = math.max(0, math.min(self.mRecipeScrollOffset, self.mRecipeScrollMax))
        end
        return
    end

    -- Check if mouse is over right panel
    if mx >= rightPanelX then
        if self.mShowHRPanel then
            -- Scroll HR panel
            self.mHRScrollOffset = self.mHRScrollOffset - dy * 120
            self.mHRScrollOffset = math.max(0, math.min(self.mHRScrollOffset, self.mHRScrollMax))
        elseif self.mShowCommodityPanel then
            -- Scroll Commodity panel - check if mouse is over category bar or commodity list
            local filterY = 110
            local filterWidth = 150
            local filterX = rightPanelX

            if mx >= filterX and mx < filterX + filterWidth and my >= filterY then
                -- Mouse over category bar - scroll categories
                self.mCommodityCategoryScrollOffset = self.mCommodityCategoryScrollOffset - dy * 30
                self.mCommodityCategoryScrollOffset = math.max(0, math.min(self.mCommodityCategoryScrollOffset, self.mCommodityCategoryScrollMax))
            else
                -- Mouse over commodity list - scroll commodities
                self.mCommodityScrollOffset = self.mCommodityScrollOffset - dy * 120
                self.mCommodityScrollOffset = math.max(0, math.min(self.mCommodityScrollOffset, self.mCommodityScrollMax))
            end
        else
            -- Scroll right panel (building picker)
            self.mRightScrollOffset = self.mRightScrollOffset - dy * 120
            self.mRightScrollOffset = math.max(0, math.min(self.mRightScrollOffset, self.mRightScrollMax))
        end
    else
        -- Scroll building/worker grid (left side) - matching InventoryDrawer scroll speed
        self.mBuildingScrollOffset = self.mBuildingScrollOffset - dy * 30
        self.mBuildingScrollOffset = math.max(0, math.min(self.mBuildingScrollOffset, self.mBuildingScrollMax))
    end
end

-- Building Detail Modal
function Prototype2State:RenderBuildingModal()
    if not self.mSelectedBuilding then
        return
    end

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
    love.graphics.setNewFont(22)
    love.graphics.print(self.mSelectedBuilding.name .. " #" .. self.mSelectedBuilding.id, modalX + 20, modalY + 15)

    -- Close button (X)
    local closeButtonSize = 30
    local closeButtonX = modalX + modalWidth - closeButtonSize - 10
    local closeButtonY = modalY + 10
    love.graphics.setColor(0.7, 0.3, 0.3)
    love.graphics.rectangle("fill", closeButtonX, closeButtonY, closeButtonSize, closeButtonSize, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(18)
    love.graphics.print("X", closeButtonX + 9, closeButtonY + 4)

    -- Scrollable content area
    local contentY = modalY + 60
    local contentHeight = modalHeight - 70
    love.graphics.setScissor(modalX + 10, contentY, modalWidth - 20, contentHeight)

    local yOffset = contentY - self.mBuildingModalScrollOffset

    -- Section 1: Stations
    local stationSectionHeight = 50 + (#self.mSelectedBuilding.stations * 90)
    love.graphics.setColor(0.35, 0.35, 0.38)
    love.graphics.rectangle("fill", modalX + 20, yOffset, modalWidth - 40, stationSectionHeight, 8, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(18)
    love.graphics.print("Stations (" .. #self.mSelectedBuilding.stations .. ")", modalX + 30, yOffset + 10)

    -- Render each station
    local stationY = yOffset + 45
    for _, station in ipairs(self.mSelectedBuilding.stations) do
        -- Station card
        local cardWidth = modalWidth - 80
        local cardHeight = 80
        local stateColor = {0.4, 0.4, 0.42}

        if station.state == "PRODUCING" then
            stateColor = {0.35, 0.5, 0.35}
        elseif station.state == "NO_WORKER" then
            stateColor = {0.5, 0.35, 0.35}
        elseif station.state == "NO_MATERIALS" then
            stateColor = {0.5, 0.45, 0.3}
        end

        love.graphics.setColor(unpack(stateColor))
        love.graphics.rectangle("fill", modalX + 40, stationY, cardWidth, cardHeight, 6, 6)

        -- Station ID
        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(14)
        love.graphics.print("Station " .. station.id, modalX + 50, stationY + 8)

        -- Recipe info
        if station.recipe then
            love.graphics.setNewFont(13)
            love.graphics.setColor(0.8, 0.9, 0.8)
            love.graphics.print(station.recipe.recipeName, modalX + 50, stationY + 28)
        else
            love.graphics.setNewFont(13)
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("No recipe", modalX + 50, stationY + 28)
        end

        -- Worker info
        if station.worker then
            local workerObj = self.mEmployment.workerLookup[station.worker]
            if workerObj then
                love.graphics.setNewFont(12)
                love.graphics.setColor(0.7, 0.8, 0.9)
                love.graphics.print("Worker: " .. workerObj.name, modalX + 50, stationY + 48)
            end
        else
            love.graphics.setNewFont(12)
            love.graphics.setColor(0.8, 0.6, 0.6)
            love.graphics.print("No worker assigned", modalX + 50, stationY + 48)
        end

        -- State and progress
        love.graphics.setNewFont(11)
        love.graphics.setColor(0.8, 0.8, 0.8)
        local stateText = station.state
        if station.state == "PRODUCING" then
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
            love.graphics.setNewFont(12)
            local text = "Change Recipe"
            local textWidth = love.graphics.getFont():getWidth(text)
            love.graphics.print(text, buttonX + (buttonWidth - textWidth) / 2, buttonY + 5)
        else
            -- Add Recipe button
            love.graphics.setColor(0.5, 0.7, 0.4)
            love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight, 4, 4)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(12)
            local text = "Add Recipe"
            local textWidth = love.graphics.getFont():getWidth(text)
            love.graphics.print(text, buttonX + (buttonWidth - textWidth) / 2, buttonY + 5)
        end

        stationY = stationY + cardHeight + 10
    end

    yOffset = yOffset + stationSectionHeight + 10

    -- Section 2: Storage (with commodity breakdown)
    local storage = self.mSelectedBuilding.storage

    -- Count commodities
    local inputCommodityCount = 0
    for _ in pairs(storage.inputs) do inputCommodityCount = inputCommodityCount + 1 end
    local outputCommodityCount = 0
    for _ in pairs(storage.outputs) do outputCommodityCount = outputCommodityCount + 1 end

    local storageSectionHeight = 100 + (inputCommodityCount * 25) + (outputCommodityCount * 25)

    love.graphics.setColor(0.35, 0.35, 0.38)
    love.graphics.rectangle("fill", modalX + 20, yOffset, modalWidth - 40, storageSectionHeight, 8, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(18)
    love.graphics.print("Storage", modalX + 30, yOffset + 10)

    local storageY = yOffset + 40

    -- Input storage header
    love.graphics.setNewFont(14)
    love.graphics.setColor(0.9, 0.8, 0.6)
    love.graphics.print("Input Storage:", modalX + 30, storageY)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(storage.inputUsed .. " / " .. storage.inputCapacity .. " units", modalX + 160, storageY)
    storageY = storageY + 25

    -- List input commodities
    if inputCommodityCount > 0 then
        love.graphics.setNewFont(12)
        for commodityId, amount in pairs(storage.inputs) do
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("  • " .. commodityId .. ":", modalX + 40, storageY)
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.print(amount .. " units", modalX + 200, storageY)
            storageY = storageY + 20
        end
        storageY = storageY + 5
    else
        love.graphics.setNewFont(12)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("  (empty)", modalX + 40, storageY)
        storageY = storageY + 25
    end

    -- Output storage header
    love.graphics.setNewFont(14)
    love.graphics.setColor(0.6, 0.9, 0.7)
    love.graphics.print("Output Storage:", modalX + 30, storageY)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(storage.outputUsed .. " / " .. storage.outputCapacity .. " units", modalX + 180, storageY)
    storageY = storageY + 25

    -- List output commodities
    if outputCommodityCount > 0 then
        love.graphics.setNewFont(12)
        for commodityId, amount in pairs(storage.outputs) do
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("  • " .. commodityId .. ":", modalX + 40, storageY)
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.print(amount .. " units", modalX + 200, storageY)
            storageY = storageY + 20
        end
        storageY = storageY + 5
    else
        love.graphics.setNewFont(12)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("  (empty)", modalX + 40, storageY)
        storageY = storageY + 25
    end

    yOffset = yOffset + storageSectionHeight + 10

    -- Section 3: Workers
    local workers = self:GetWorkersForBuilding(self.mSelectedBuilding.id)
    local workerSectionHeight = 50 + (#workers * 150)  -- Header + worker cards

    love.graphics.setColor(0.35, 0.35, 0.38)
    love.graphics.rectangle("fill", modalX + 20, yOffset, modalWidth - 40, math.max(100, workerSectionHeight), 8, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(18)
    love.graphics.print("Workers (" .. #workers .. ")", modalX + 30, yOffset + 10)

    if #workers == 0 then
        love.graphics.setNewFont(14)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("No workers assigned yet", modalX + 30, yOffset + 45)
    else
        local workerY = yOffset + 45
        for _, worker in ipairs(workers) do
            -- Worker card
            local cardWidth = modalWidth - 80
            local cardHeight = 140
            love.graphics.setColor(0.4, 0.45, 0.38)
            love.graphics.rectangle("fill", modalX + 40, workerY, cardWidth, cardHeight, 6, 6)

            -- Worker info
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(16)
            love.graphics.print(worker.name, modalX + 50, workerY + 10)

            love.graphics.setNewFont(13)
            love.graphics.setColor(0.8, 0.8, 0.9)
            love.graphics.print(worker.workerTypeName, modalX + 50, workerY + 32)

            love.graphics.setNewFont(11)
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("Level: " .. worker.skillLevel, modalX + 50, workerY + 52)
            love.graphics.print("Age: " .. worker.age, modalX + 50, workerY + 68)
            love.graphics.print(worker.gender .. ", " .. worker.status, modalX + 50, workerY + 84)

            love.graphics.setColor(0.9, 0.9, 0.5)
            love.graphics.print("Wage: $" .. worker.currentWage .. "/hr", modalX + 50, workerY + 105)

            workerY = workerY + cardHeight + 10
        end
    end

    -- Calculate total content height for scrolling
    -- Stations (variable) + Storage (variable) + Workers (variable) + padding (20)
    local totalContentHeight = stationSectionHeight + 10 + storageSectionHeight + 10 + workerSectionHeight + 20
    self.mBuildingModalScrollMax = math.max(0, totalContentHeight - contentHeight)

    love.graphics.setScissor()

    -- Draw scrollbar if needed
    if self.mBuildingModalScrollMax > 0 then
        local scrollbarX = modalX + modalWidth - 18
        local scrollbarWidth = 6
        local scrollbarHeight = contentHeight * (contentHeight / totalContentHeight)
        local scrollbarY = contentY + (self.mBuildingModalScrollOffset / self.mBuildingModalScrollMax) * (contentHeight - scrollbarHeight)

        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 3, 3)
    end
end

function Prototype2State:HandleBuildingModalClick(mx, my)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local modalWidth = 700
    local modalHeight = 600
    local modalX = (screenW - modalWidth) / 2
    local modalY = (screenH - modalHeight) / 2

    -- Close button
    local closeButtonSize = 30
    local closeButtonX = modalX + modalWidth - closeButtonSize - 10
    local closeButtonY = modalY + 10

    if mx >= closeButtonX and mx <= closeButtonX + closeButtonSize and
       my >= closeButtonY and my <= closeButtonY + closeButtonSize then
        self.mShowBuildingModal = false
        self.mSelectedBuilding = nil
        return
    end

    -- Click outside modal = close
    if mx < modalX or mx > modalX + modalWidth or
       my < modalY or my > modalY + modalHeight then
        self.mShowBuildingModal = false
        self.mSelectedBuilding = nil
        return
    end

    -- Check for station recipe button clicks
    local contentY = modalY + 60
    local yOffset = contentY - self.mBuildingModalScrollOffset

    local stationY = yOffset + 45
    local cardWidth = modalWidth - 80
    local cardHeight = 80

    for _, station in ipairs(self.mSelectedBuilding.stations) do
        -- Check if clicking on this station's recipe button
        local buttonWidth = 120
        local buttonHeight = 25
        local buttonX = modalX + cardWidth - buttonWidth + 20
        local buttonY = stationY + cardHeight - buttonHeight - 8

        if mx >= buttonX and mx <= buttonX + buttonWidth and
           my >= buttonY and my <= buttonY + buttonHeight then
            -- Store which station was clicked
            self.mSelectedStation = station
            -- Open recipe modal
            self.mShowRecipeModal = true
            self.mModalJustOpened = true
            self.mRecipeScrollOffset = 0
            return
        end

        stationY = stationY + cardHeight + 10
    end
end

function Prototype2State:RenderStatsPanel()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Full-screen modal background (blocks all clicks below)
    love.graphics.setColor(0.05, 0.05, 0.08, 0.98)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Get stats data
    local summary = self.mStats:getMetricsSummary()
    local trackedCommodities = self.mStats:getTrackedCommodities()

    -- Panel dimensions (similar to commodity panel)
    local panelY = 60  -- Below top bar
    local panelH = screenH - 120  -- Leave space for bottom

    -- LEFT SIDE: Commodity list (master)
    local leftPanelX = 20
    local leftPanelW = 350
    local leftPanelY = panelY
    local leftPanelH = panelH

    -- Left panel background
    love.graphics.setColor(0.2, 0.2, 0.22)
    love.graphics.rectangle("fill", leftPanelX, leftPanelY, leftPanelW, leftPanelH, 5, 5)

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(20)
    love.graphics.print("Production Stats", leftPanelX + 15, leftPanelY + 15)

    -- Hint text
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.setNewFont(12)
    love.graphics.print("Press ESC to close", leftPanelX + 15, leftPanelY + 40)

    -- Scrollable commodity list
    local listY = leftPanelY + 65
    local listHeight = leftPanelH - 75

    -- Enable scissor for scrolling
    love.graphics.setScissor(leftPanelX, listY, leftPanelW, listHeight)

    if #trackedCommodities > 0 then
        -- Auto-select first commodity if none selected
        if not self.mSelectedStatCommodity then
            self.mSelectedStatCommodity = trackedCommodities[1]
        end

        local yOffset = listY - self.mStatsScrollOffset
        local itemHeight = 60
        local spacing = 5
        local totalContentHeight = 0

        for _, commodityId in ipairs(trackedCommodities) do
            -- Only render if visible
            if yOffset + itemHeight >= listY and yOffset <= listY + listHeight then
                local isSelected = (self.mSelectedStatCommodity == commodityId)

                -- Item background
                if isSelected then
                    love.graphics.setColor(0.35, 0.55, 0.75)  -- Blue highlight
                else
                    love.graphics.setColor(0.28, 0.28, 0.32)
                end
                love.graphics.rectangle("fill", leftPanelX + 10, yOffset, leftPanelW - 20, itemHeight, 5, 5)

                -- Commodity name
                love.graphics.setColor(1, 1, 1)
                love.graphics.setNewFont(14)
                love.graphics.print(commodityId, leftPanelX + 20, yOffset + 8)

                -- Production rate
                local prodRate = summary.productionRate[commodityId] or 0
                love.graphics.setColor(0.4, 0.8, 0.4)
                love.graphics.setNewFont(12)
                love.graphics.print(string.format("Prod: %.1f/min", prodRate), leftPanelX + 20, yOffset + 28)

                -- Consumption rate
                local consRate = summary.consumptionRate[commodityId] or 0
                love.graphics.setColor(0.9, 0.4, 0.4)
                love.graphics.print(string.format("Cons: %.1f/min", consRate), leftPanelX + 20, yOffset + 43)

                -- Net production
                local netProd = summary.netProduction[commodityId] or 0
                local netColor = netProd >= 0 and {0.4, 0.8, 0.4} or {0.9, 0.4, 0.4}
                love.graphics.setColor(netColor)
                love.graphics.print(string.format("Net: %+.1f", netProd), leftPanelX + 180, yOffset + 35)
            end

            yOffset = yOffset + itemHeight + spacing
            totalContentHeight = totalContentHeight + itemHeight + spacing
        end

        -- Calculate max scroll
        self.mStatsScrollMax = math.max(0, totalContentHeight - listHeight)

        -- Draw scrollbar if needed
        if self.mStatsScrollMax > 0 then
            local scrollbarX = leftPanelX + leftPanelW - 18
            local scrollbarWidth = 6
            local scrollbarHeight = listHeight * (listHeight / totalContentHeight)
            local scrollbarY = listY + (self.mStatsScrollOffset / self.mStatsScrollMax) * (listHeight - scrollbarHeight)

            love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
            love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 3, 3)
        end
    else
        -- No data message
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.setNewFont(14)
        love.graphics.print("No production data yet.\nStart producing to see stats!", leftPanelX + 30, listY + 50)
    end

    love.graphics.setScissor()

    -- RIGHT SIDE: Detailed stats for selected commodity (detail)
    local rightPanelX = leftPanelX + leftPanelW + 20
    local rightPanelW = screenW - rightPanelX - 20
    local rightPanelY = panelY
    local rightPanelH = panelH

    -- Right panel background
    love.graphics.setColor(0.15, 0.15, 0.17)
    love.graphics.rectangle("fill", rightPanelX, rightPanelY, rightPanelW, rightPanelH, 5, 5)

    if self.mSelectedStatCommodity and #trackedCommodities > 0 then
        -- Title with commodity name
        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(18)
        love.graphics.print("Details: " .. self.mSelectedStatCommodity, rightPanelX + 20, rightPanelY + 15)

        -- Summary cards
        local cardY = rightPanelY + 50
        local cardW = (rightPanelW - 60) / 3
        local cardH = 90

        local prodRate = summary.productionRate[self.mSelectedStatCommodity] or 0
        local consRate = summary.consumptionRate[self.mSelectedStatCommodity] or 0
        local netProd = summary.netProduction[self.mSelectedStatCommodity] or 0

        -- Production rate card
        StatsVisualization.drawStatCard(rightPanelX + 20, cardY, cardW, cardH,
            prodRate, "Production Rate",
            {format = "%.1f/min", valueColor = {0.4, 0.8, 0.4, 1}})

        -- Consumption rate card
        StatsVisualization.drawStatCard(rightPanelX + 30 + cardW, cardY, cardW, cardH,
            consRate, "Consumption Rate",
            {format = "%.1f/min", valueColor = {0.9, 0.4, 0.4, 1}})

        -- Net production card
        local netColor = netProd >= 0 and {0.4, 0.8, 0.4, 1} or {0.9, 0.4, 0.4, 1}
        StatsVisualization.drawStatCard(rightPanelX + 40 + cardW * 2, cardY, cardW, cardH,
            netProd, "Net Production",
            {format = "%+.1f/min", valueColor = netColor})

        -- Charts
        local chartY = cardY + cardH + 20
        local chartH = (rightPanelH - (chartY - rightPanelY) - 20) / 2 - 10

        -- Get trend data
        local prodTrend = self.mStats:getProductionTrend(self.mSelectedStatCommodity, 60)
        local consTrend = self.mStats:getConsumptionTrend(self.mSelectedStatCommodity, 60)
        local stockTrend = self.mStats:getStockpileTrend(self.mSelectedStatCommodity, 60)

        -- Production vs Consumption chart
        if #prodTrend > 0 or #consTrend > 0 then
            StatsVisualization.drawStackedAreaChart(rightPanelX + 20, chartY, rightPanelW - 40, chartH,
                prodTrend, consTrend,
                {title = "Production vs Consumption (per period)"})
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.setNewFont(14)
            love.graphics.print("No production/consumption data yet", rightPanelX + 40, chartY + chartH/2)
        end

        -- Stockpile level chart
        local stockChartY = chartY + chartH + 20
        if #stockTrend > 1 then
            StatsVisualization.drawLineChart(rightPanelX + 20, stockChartY, rightPanelW - 40, chartH,
                stockTrend,
                {title = "Stockpile Level Over Time", color = {0.8, 0.6, 0.2, 1}})
        else
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.setNewFont(14)
            love.graphics.print("No stockpile data yet", rightPanelX + 40, stockChartY + chartH/2)
        end
    else
        -- No commodity selected
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.setNewFont(16)
        love.graphics.print("Select a commodity from the list", rightPanelX + rightPanelW/2 - 140, rightPanelY + rightPanelH/2)
    end
end

return Prototype2State
