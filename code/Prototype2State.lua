--
-- Prototype2State - Production Engine prototype
-- Blank canvas with building cards on left and building picker on right
--

require("code/DataLoader")
require("code/CharacterFactory")

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
        mRightPanelWidth = 300,
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

        -- View state
        mShowHRPoolView = false,  -- Toggle between Buildings view and HR Pool view

        -- Scroll state for resource panels
        mHRScrollOffset = 0,
        mHRScrollMax = 0,
        mCommodityScrollOffset = 0,
        mCommodityScrollMax = 0,

        -- Recipe picker modal state
        mShowRecipeModal = false,
        mBuildingRecipes = {},   -- All recipes loaded from JSON
        mRecipeScrollOffset = 0,
        mRecipeScrollMax = 0,

        -- Building detail modal state
        mShowBuildingModal = false,
        mSelectedBuilding = nil,  -- Building that was clicked
        mBuildingModalScrollOffset = 0,
        mBuildingModalScrollMax = 0,

        mModalJustOpened = false  -- Flag to prevent closing modal on same click that opened it
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

function Prototype2State:Update(dt)
    -- Reset modal just opened flag at the start of each frame
    if self.mModalJustOpened then
        self.mModalJustOpened = false
    end

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

        -- Check for top bar button clicks
        if my <= 60 then
            self:HandleTopBarClick(mx, my)
        end

        -- Check if clicking on right panel (building picker)
        local screenW = love.graphics.getWidth()
        local rightPanelX = screenW - self.mRightPanelWidth

        if mx >= rightPanelX and not self.mShowHRPanel and not self.mShowCommodityPanel then
            self:HandleRightPanelClick(mx, my)
        end

        -- Check if clicking on HR panel
        if self.mShowHRPanel then
            self:HandleHRPanelClick(mx, my)
        end

        -- Check if clicking on Commodity panel
        if self.mShowCommodityPanel then
            self:HandleCommodityPanelClick(mx, my)
        end

        -- Check if clicking on a building card (when not in modal)
        if not self.mShowRecipeModal and not self.mShowBuildingModal and not self.mShowHRPoolView then
            print("Calling HandleBuildingCardClick")
            self:HandleBuildingCardClick(mx, my)
        else
            print("Skipping HandleBuildingCardClick - HRPoolView=" .. tostring(self.mShowHRPoolView) .. ", RecipeModal=" .. tostring(self.mShowRecipeModal) .. ", BuildingModal=" .. tostring(self.mShowBuildingModal))
        end

        -- Check if clicking on building detail modal
        if self.mShowBuildingModal and not self.mModalJustOpened then
            self:HandleBuildingModalClick(mx, my)
        end

        -- Check if clicking on recipe modal (but not if it was just opened this frame)
        if self.mShowRecipeModal and not self.mModalJustOpened then
            print("Calling HandleRecipeModalClick")
            self:HandleRecipeModalClick(mx, my)
        elseif self.mShowRecipeModal and self.mModalJustOpened then
            print("Skipping HandleRecipeModalClick - modal just opened")
        end
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
    local listY = 110

    -- Check if clicking inside the panel
    if mx < panelX then
        return
    end

    local yOffset = listY - self.mCommodityScrollOffset
    local itemHeight = 50
    local spacing = 5

    for _, c in ipairs(self.mCommodities) do
        if my >= yOffset and my <= yOffset + itemHeight then
            -- Check if clicking + or - button
            local buttonY = yOffset + 15
            local buttonSize = 25

            -- - button (subtract 10)
            local minusX = panelX + self.mRightPanelWidth - 80
            if mx >= minusX and mx <= minusX + buttonSize and
               my >= buttonY and my <= buttonY + buttonSize then
                self.mCommodityCounts[c.id] = math.max(0, self.mCommodityCounts[c.id] - 10)
                return
            end

            -- + button (add 10)
            local plusX = panelX + self.mRightPanelWidth - 40
            if mx >= plusX and mx <= plusX + buttonSize and
               my >= buttonY and my <= buttonY + buttonSize then
                self.mCommodityCounts[c.id] = self.mCommodityCounts[c.id] + 10
                return
            end
        end

        yOffset = yOffset + itemHeight + spacing
    end
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

    -- Create a simple building record (no spatial position)
    local building = {
        id = #self.mBuildings + 1,
        typeId = buildingTypeId,
        type = buildingType,
        name = buildingType.name,
        category = buildingType.category,
        addedTime = love.timer.getTime(),

        -- Production state (to be implemented)
        production = {
            state = "IDLE",  -- IDLE, PRODUCING, BLOCKED, COMPLETED
            progress = 0,
            efficiency = 1.0,
            workers = {},
            inputs = {},
            outputs = {},
            recipe = nil  -- Selected recipe for this building
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

    -- Assign to new building
    worker.employed = true
    worker.assignedBuilding = building.id
    worker.hiredDate = love.timer.getTime()

    -- Update association structures
    self.mEmployment.byWorker[worker.id] = building.id
    table.insert(self.mEmployment.byBuilding[building.id], worker.id)
    self.mEmployment.workerLookup[worker.id] = worker

    -- Add to building's production workers list
    table.insert(building.production.workers, worker.id)

    print("Assigned " .. worker.name .. " to " .. building.name)
end

function Prototype2State:UnassignWorkerFromBuilding(worker)
    if not worker.employed or not worker.assignedBuilding then
        return
    end

    local buildingId = worker.assignedBuilding

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

    -- Remove from building's production workers
    for _, building in ipairs(self.mBuildings) do
        if building.id == buildingId then
            for i, wid in ipairs(building.production.workers) do
                if wid == worker.id then
                    table.remove(building.production.workers, i)
                    break
                end
            end
            break
        end
    end

    -- Update worker status
    worker.employed = false
    worker.assignedBuilding = nil

    print("Unassigned " .. worker.name .. " from building #" .. buildingId)
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
        -- Skip buildings without a recipe selected
        if not building.production.recipe then
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

        -- Check if building has space for more workers
        local recipe = building.production.recipe
        local currentWorkerCount = #(self.mEmployment.byBuilding[building.id] or {})
        local maxWorkers = recipe.workers and recipe.workers.max or 0

        if currentWorkerCount >= maxWorkers then
            goto continue
        end

        -- Calculate score based on:
        -- 1. Wage offered (from recipe)
        -- 2. Efficiency bonus
        -- 3. Current occupancy (prefer less crowded buildings)
        local wage = recipe.workers and recipe.workers.wages or worker.minimumWage
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
            -- Recipe selected!
            self.mSelectedBuilding.production.recipe = recipe
            self.mSelectedBuilding.production.state = "READY"
            print("Selected recipe: " .. recipe.recipeName .. " for building #" .. self.mSelectedBuilding.id)

            -- Run free agency to assign workers to this building
            self:RunFreeAgency()

            -- Close recipe modal (but keep building modal open if it was open)
            self.mShowRecipeModal = false
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

    -- Recipe info
    if building.production.recipe then
        love.graphics.setColor(0.5, 0.8, 0.5)
        love.graphics.print("Recipe: " .. building.production.recipe.recipeName, x + 15, y + 55)
    else
        love.graphics.setColor(0.8, 0.6, 0.3)
        love.graphics.print("Click to select recipe", x + 15, y + 55)
    end

    -- Production state
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("State: " .. building.production.state, x + 15, y + 75)

    -- Worker info
    local workers = self:GetWorkersForBuilding(building.id)
    local workerCount = #workers
    local maxWorkers = building.production.recipe and building.production.recipe.workers and building.production.recipe.workers.max or 0

    if building.production.recipe then
        love.graphics.setColor(0.7, 0.7, 1.0)
        love.graphics.print("Workers: " .. workerCount .. "/" .. maxWorkers, x + 15, y + 95)
    end

    -- Progress bar placeholder
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", x + 15, y + height - 25, width - 30, 15, 3, 3)

    love.graphics.setColor(0.4, 0.7, 0.4)
    local progressWidth = (width - 30) * building.production.progress
    if progressWidth > 0 then
        love.graphics.rectangle("fill", x + 15, y + height - 25, progressWidth, 15, 3, 3)
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
    local listHeight = screenH - listY - 10
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

    -- Scrollable area dimensions
    local listY = 110
    local listHeight = screenH - listY - 50  -- Extra space for summary
    local listWidth = self.mRightPanelWidth - 10

    -- Enable scissor (clipping) for scrollable area
    love.graphics.setScissor(rightPanelX, listY, listWidth, listHeight)

    -- Render commodities (with scroll offset)
    local yOffset = listY - self.mCommodityScrollOffset
    local itemHeight = 50
    local spacing = 5
    local totalContentHeight = 0

    for _, c in ipairs(self.mCommodities) do
        -- Skip rendering if outside visible area (optimization)
        if yOffset + itemHeight >= listY and yOffset <= listY + listHeight then
            local count = self.mCommodityCounts[c.id] or 0

            -- Item background (highlight if count > 0)
            if count > 0 then
                love.graphics.setColor(0.4, 0.4, 0.45)
            else
                love.graphics.setColor(0.35, 0.35, 0.38)
            end
            love.graphics.rectangle("fill", rightPanelX + 15, yOffset, self.mRightPanelWidth - 30, itemHeight, 5, 5)

            -- Commodity name
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(14)
            love.graphics.print(c.name, rightPanelX + 25, yOffset + 8)

            -- Commodity category (smaller, gray)
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.setNewFont(11)
            love.graphics.print(c.category, rightPanelX + 25, yOffset + 28)

            -- Count display
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(16)
            local countText = tostring(count)
            local countWidth = love.graphics.getFont():getWidth(countText)
            love.graphics.print(countText, rightPanelX + self.mRightPanelWidth - 120, yOffset + 15)

            -- - button (subtract 10)
            local buttonY = yOffset + 15
            local buttonSize = 25
            local minusX = rightPanelX + self.mRightPanelWidth - 80
            love.graphics.setColor(0.5, 0.3, 0.3)
            love.graphics.rectangle("fill", minusX, buttonY, buttonSize, buttonSize, 3, 3)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(18)
            love.graphics.print("-", minusX + 8, buttonY + 1)

            -- + button (add 10)
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
            -- Scroll Commodity panel
            self.mCommodityScrollOffset = self.mCommodityScrollOffset - dy * 120
            self.mCommodityScrollOffset = math.max(0, math.min(self.mCommodityScrollOffset, self.mCommodityScrollMax))
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

    -- Section 1: Recipe
    love.graphics.setColor(0.35, 0.35, 0.38)
    love.graphics.rectangle("fill", modalX + 20, yOffset, modalWidth - 40, 120, 8, 8)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(18)
    love.graphics.print("Recipe", modalX + 30, yOffset + 10)

    if self.mSelectedBuilding.production.recipe then
        local recipe = self.mSelectedBuilding.production.recipe

        love.graphics.setNewFont(16)
        love.graphics.setColor(0.7, 0.9, 0.7)
        love.graphics.print(recipe.recipeName, modalX + 30, yOffset + 40)

        love.graphics.setNewFont(13)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("Time: " .. math.floor(recipe.productionTime / 60) .. " min", modalX + 30, yOffset + 65)

        -- Change Recipe button
        local buttonWidth = 140
        local buttonHeight = 30
        local buttonX = modalX + modalWidth - buttonWidth - 30
        local buttonY = yOffset + 75

        love.graphics.setColor(0.4, 0.5, 0.7)
        love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight, 5, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(14)
        local text = "Change Recipe"
        local textWidth = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, buttonX + (buttonWidth - textWidth) / 2, buttonY + 7)
    else
        love.graphics.setNewFont(14)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("No recipe selected", modalX + 30, yOffset + 40)

        -- Select Recipe button
        local buttonWidth = 140
        local buttonHeight = 30
        local buttonX = modalX + modalWidth - buttonWidth - 30
        local buttonY = yOffset + 75

        love.graphics.setColor(0.5, 0.7, 0.4)
        love.graphics.rectangle("fill", buttonX, buttonY, buttonWidth, buttonHeight, 5, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(14)
        local text = "Select Recipe"
        local textWidth = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, buttonX + (buttonWidth - textWidth) / 2, buttonY + 7)
    end

    yOffset = yOffset + 130

    -- Section 2: Workers
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
    local totalContentHeight = 130 + workerSectionHeight + 20
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

    -- Check recipe button click
    local contentY = modalY + 60
    local yOffset = contentY - self.mBuildingModalScrollOffset

    local buttonWidth = 140
    local buttonHeight = 30
    local buttonX = modalX + modalWidth - buttonWidth - 30
    local buttonY = yOffset + 75

    if mx >= buttonX and mx <= buttonX + buttonWidth and
       my >= buttonY and my <= buttonY + buttonHeight then
        -- Open recipe modal
        self.mShowRecipeModal = true
        self.mModalJustOpened = true
        self.mRecipeScrollOffset = 0
        return
    end
end

return Prototype2State
