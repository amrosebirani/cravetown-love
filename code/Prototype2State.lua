--
-- Prototype2State - Production Engine prototype
-- Blank canvas with building cards on left and building picker on right
--

require("code/BuildingTypes")

Prototype2State = {}
Prototype2State.__index = Prototype2State

function Prototype2State:Create()
    local this = {
        -- Buildings array (no spatial placement, just cards)
        mBuildings = {},

        -- UI state
        mRightPanelWidth = 300,
        mLeftPanelWidth = 400,
        mSelectedBuildingType = nil,
        mHoveredBuildingType = nil,

        -- Building categories for organization
        mCategories = {
            {name = "Production", types = {}},
            {name = "Resource", types = {}},
            {name = "Services", types = {}},
            {name = "Housing", types = {}}
        },

        -- Scroll state for left panel
        mLeftScrollOffset = 0,
        mLeftScrollMax = 0,

        -- Scroll state for right panel
        mRightScrollOffset = 0,
        mRightScrollMax = 0
    }

    setmetatable(this, self)

    -- Categorize building types
    this:CategorizeBuildingTypes()

    return this
end

function Prototype2State:CategorizeBuildingTypes()
    -- Clear the initial categories (we'll build them dynamically)
    self.mCategories = {}

    -- Go through all BuildingTypes and categorize them
    for typeId, buildingType in pairs(BuildingTypes) do
        if type(buildingType) == "table" and buildingType.category then
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
                id = typeId,
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
    -- Handle mouse clicks for adding buildings
    if gMousePressed and gMousePressed.button == 1 then
        local mx, my = gMousePressed.x, gMousePressed.y

        -- Check if clicking on right panel (building picker)
        local screenW = love.graphics.getWidth()
        local rightPanelX = screenW - self.mRightPanelWidth

        if mx >= rightPanelX then
            self:HandleRightPanelClick(mx, my)
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

function Prototype2State:AddBuilding(buildingTypeId)
    local buildingType = BuildingTypes[buildingTypeId]

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
            outputs = {}
        }
    }

    table.insert(self.mBuildings, building)
    print("Added building: " .. building.name .. " (#" .. building.id .. ")")
end

function Prototype2State:Render()
    love.graphics.clear(0.92, 0.92, 0.92)

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Render center canvas (blank for now)
    self:RenderCenterCanvas()

    -- Render left panel (building cards)
    self:RenderLeftPanel()

    -- Render right panel (building picker)
    self:RenderRightPanel()

    -- Render top bar
    self:RenderTopBar()
end

function Prototype2State:RenderCenterCanvas()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local canvasX = self.mLeftPanelWidth
    local canvasWidth = screenW - self.mLeftPanelWidth - self.mRightPanelWidth

    -- Blank canvas background
    love.graphics.setColor(0.98, 0.98, 0.98)
    love.graphics.rectangle("fill", canvasX, 60, canvasWidth, screenH - 60)

    -- Subtle grid pattern
    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.setLineWidth(1)
    local gridSize = 50
    for x = canvasX, canvasX + canvasWidth, gridSize do
        love.graphics.line(x, 60, x, screenH)
    end
    for y = 60, screenH, gridSize do
        love.graphics.line(canvasX, y, canvasX + canvasWidth, y)
    end

    -- Center text
    if #self.mBuildings == 0 then
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.setNewFont(24)
        local text = "Prototype 2: Production Engine"
        local textWidth = love.graphics.getFont():getWidth(text)
        love.graphics.print(text, canvasX + (canvasWidth - textWidth) / 2, screenH / 2 - 40)

        love.graphics.setNewFont(16)
        local subtext = "Select buildings from the right panel to add building cards"
        local subtextWidth = love.graphics.getFont():getWidth(subtext)
        love.graphics.print(subtext, canvasX + (canvasWidth - subtextWidth) / 2, screenH / 2)
    end
end

function Prototype2State:RenderLeftPanel()
    local screenH = love.graphics.getHeight()

    -- Panel background
    love.graphics.setColor(0.25, 0.25, 0.28)
    love.graphics.rectangle("fill", 0, 60, self.mLeftPanelWidth, screenH - 60)

    -- Panel title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(20)
    love.graphics.print("Building Cards", 20, 75)

    -- Building count
    love.graphics.setNewFont(14)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(#self.mBuildings .. " buildings", 20, 105)

    -- Render building cards grouped by category
    local yOffset = 140 - self.mLeftScrollOffset
    local cardHeight = 120
    local cardSpacing = 15
    local categorySpacing = 30

    -- Group buildings by category
    local buildingsByCategory = {}
    for _, building in ipairs(self.mBuildings) do
        local cat = building.category or "Uncategorized"
        if not buildingsByCategory[cat] then
            buildingsByCategory[cat] = {}
        end
        table.insert(buildingsByCategory[cat], building)
    end

    -- Render each category
    for categoryName, buildings in pairs(buildingsByCategory) do
        -- Category header
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.setNewFont(16)
        love.graphics.print(categoryName, 20, yOffset)
        yOffset = yOffset + 25

        -- Building cards in this category
        for _, building in ipairs(buildings) do
            self:RenderBuildingCard(building, 20, yOffset, self.mLeftPanelWidth - 40, cardHeight)
            yOffset = yOffset + cardHeight + cardSpacing
        end

        yOffset = yOffset + categorySpacing
    end

    -- Update scroll max
    self.mLeftScrollMax = math.max(0, yOffset - screenH + 60)
end

function Prototype2State:RenderBuildingCard(building, x, y, width, height)
    local screenH = love.graphics.getHeight()

    -- Skip if outside visible area
    if y + height < 60 or y > screenH then
        return
    end

    -- Card background
    love.graphics.setColor(0.35, 0.35, 0.38)
    love.graphics.rectangle("fill", x, y, width, height, 8, 8)

    -- Card border
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, 8, 8)

    -- Building type color indicator
    if building.type.color then
        love.graphics.setColor(building.type.color)
        love.graphics.rectangle("fill", x, y, 8, height, 8, 8, 0, 0)
    end

    -- Building name and ID
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(18)
    love.graphics.print(building.name, x + 15, y + 10)

    love.graphics.setNewFont(12)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("ID: " .. building.id, x + 15, y + 35)

    -- Production state (placeholder for now)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("State: " .. building.production.state, x + 15, y + 55)

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
                    love.graphics.setColor(buildingType.data.color)
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

function Prototype2State:RenderTopBar()
    local screenW = love.graphics.getWidth()

    -- Top bar background
    love.graphics.setColor(0.2, 0.2, 0.23)
    love.graphics.rectangle("fill", 0, 0, screenW, 60)

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(24)
    love.graphics.print("Prototype 2: Production Engine", 20, 18)

    -- Back button
    love.graphics.setColor(0.7, 0.3, 0.3)
    love.graphics.rectangle("fill", screenW - 120, 15, 100, 30, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(16)
    love.graphics.print("Back (ESC)", screenW - 110, 20)
end

function Prototype2State:OnMouseWheel(dx, dy)
    local mx, my = love.mouse.getPosition()
    local screenW = love.graphics.getWidth()
    local rightPanelX = screenW - self.mRightPanelWidth

    -- Check if mouse is over right panel
    if mx >= rightPanelX then
        -- Scroll right panel (increased from 30 to 40 for smoother scrolling)
        self.mRightScrollOffset = self.mRightScrollOffset - dy * 40
        self.mRightScrollOffset = math.max(0, math.min(self.mRightScrollOffset, self.mRightScrollMax))
    -- Check if mouse is over left panel
    elseif mx <= self.mLeftPanelWidth then
        -- Scroll left panel (increased from 30 to 40 for smoother scrolling)
        self.mLeftScrollOffset = self.mLeftScrollOffset - dy * 40
        self.mLeftScrollOffset = math.max(0, math.min(self.mLeftScrollOffset, self.mLeftScrollMax))
    end
end

return Prototype2State
