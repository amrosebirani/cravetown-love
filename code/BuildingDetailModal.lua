--
-- BuildingDetailModal - shows building details with stations, recipes, and storage
--

BuildingDetailModal = {}
BuildingDetailModal.__index = BuildingDetailModal

-- Station state colors
local STATE_COLORS = {
    IDLE = {0.5, 0.5, 0.5},
    PRODUCING = {0.2, 0.7, 0.2},
    NO_WORKER = {0.7, 0.5, 0.2},
    NO_MATERIALS = {0.7, 0.2, 0.2}
}

function BuildingDetailModal:Create(building)
    local this = {
        mBuilding = building,
        mModalWidth = 500,
        mModalHeight = 450,
        mScrollOffset = 0,
        mMaxScroll = 0,
        mStationButtons = {},  -- Store button positions for click detection
        mCloseButton = nil,
        mJustOpened = true  -- Prevent closing on the same click that opened the modal
    }

    setmetatable(this, self)
    this:CalculateLayout()
    return this
end

function BuildingDetailModal:CalculateLayout()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local modalX = (screenW - self.mModalWidth) / 2
    local modalY = (screenH - self.mModalHeight) / 2

    -- Calculate station button positions
    self.mStationButtons = {}
    local stationY = modalY + 100
    local stationHeight = 60
    local stationSpacing = 8

    for i, station in ipairs(self.mBuilding.mStations) do
        table.insert(self.mStationButtons, {
            stationIndex = i,
            x = modalX + 20,
            y = stationY + (i - 1) * (stationHeight + stationSpacing),
            width = self.mModalWidth - 40,
            height = stationHeight,
            recipeButtonX = modalX + self.mModalWidth - 130,
            recipeButtonWidth = 100,
            recipeButtonHeight = 30
        })
    end

    -- Close button
    self.mCloseButton = {
        x = modalX + self.mModalWidth - 35,
        y = modalY + 10,
        width = 25,
        height = 25
    }

    -- Calculate content height for scrolling
    local contentHeight = 100 + (#self.mBuilding.mStations * (stationHeight + stationSpacing)) + 120
    self.mMaxScroll = math.max(0, contentHeight - self.mModalHeight + 40)
end

function BuildingDetailModal:Enter()
    print("BuildingDetailModal:Enter() called for building: " .. (self.mBuilding.mName or "unknown"))
    print("  Stations count: " .. #self.mBuilding.mStations)
end

function BuildingDetailModal:Exit()
end

function BuildingDetailModal:HandleInput()
    return true  -- Block input to lower states
end

function BuildingDetailModal:OnMouseWheel(dx, dy)
    -- Handle mouse wheel scrolling
    self.mScrollOffset = self.mScrollOffset - dy * 30
    self.mScrollOffset = math.max(0, math.min(self.mScrollOffset, self.mMaxScroll))
end

function BuildingDetailModal:Update(dt)
    -- Skip processing the click that opened this modal
    if self.mJustOpened then
        if not gMouseReleased then
            -- Mouse released, safe to process clicks now
            self.mJustOpened = false
        end
        return true
    end

    if not gMouseReleased then
        return true
    end

    local mx, my = gMouseReleased.x, gMouseReleased.y
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local modalX = (screenW - self.mModalWidth) / 2
    local modalY = (screenH - self.mModalHeight) / 2

    -- Check close button
    if self.mCloseButton then
        local cb = self.mCloseButton
        if mx >= cb.x and mx <= cb.x + cb.width and
           my >= cb.y and my <= cb.y + cb.height then
            gStateStack:Pop()
            return false
        end
    end

    -- Check click outside modal to close
    if mx < modalX or mx > modalX + self.mModalWidth or
       my < modalY or my > modalY + self.mModalHeight then
        gStateStack:Pop()
        return false
    end

    -- Check station recipe buttons
    for _, btn in ipairs(self.mStationButtons) do
        local rbX = btn.recipeButtonX
        local rbY = btn.y + (btn.height - btn.recipeButtonHeight) / 2

        if mx >= rbX and mx <= rbX + btn.recipeButtonWidth and
           my >= rbY and my <= rbY + btn.recipeButtonHeight then
            -- Open recipe picker for this station
            self:OpenRecipePicker(btn.stationIndex)
            return false
        end
    end

    return true
end

function BuildingDetailModal:OpenRecipePicker(stationIndex)
    require("code/RecipePickerModal")
    local station = self.mBuilding.mStations[stationIndex]
    local modal = RecipePickerModal:Create(self.mBuilding, stationIndex, function(recipe)
        -- Callback when recipe is selected
        station.recipe = recipe
        station.state = recipe and "NO_WORKER" or "IDLE"
        station.progress = 0
        local recipeName = recipe and (recipe.recipeName or recipe.name) or "none"
        print("Station " .. stationIndex .. " recipe set to: " .. recipeName)
    end)
    gStateStack:Push(modal)
end

function BuildingDetailModal:Render()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Draw modal background
    local modalX = (screenW - self.mModalWidth) / 2
    local modalY = (screenH - self.mModalHeight) / 2

    love.graphics.setColor(0.15, 0.15, 0.15, 0.98)
    love.graphics.rectangle("fill", modalX, modalY, self.mModalWidth, self.mModalHeight, 10, 10)

    -- Draw modal border
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", modalX, modalY, self.mModalWidth, self.mModalHeight, 10, 10)
    love.graphics.setLineWidth(1)

    -- Draw close button
    local cb = self.mCloseButton
    local mx, my = love.mouse.getPosition()
    local hoveringClose = mx >= cb.x and mx <= cb.x + cb.width and
                          my >= cb.y and my <= cb.y + cb.height

    love.graphics.setColor(hoveringClose and 0.6 or 0.4, 0.2, 0.2)
    love.graphics.rectangle("fill", cb.x, cb.y, cb.width, cb.height, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("X", cb.x + 8, cb.y + 4)

    -- Draw title
    love.graphics.setColor(1, 1, 1)
    local titleText = self.mBuilding.mName
    local font = love.graphics.getFont()
    local titleWidth = font:getWidth(titleText)
    love.graphics.print(titleText, modalX + (self.mModalWidth - titleWidth) / 2, modalY + 15)

    -- Draw building info
    love.graphics.setColor(0.7, 0.7, 0.7)
    local infoText = string.format("ID: %s | Category: %s | Stations: %d",
        self.mBuilding.mTypeId,
        self.mBuilding.mCategory or "unknown",
        #self.mBuilding.mStations)
    love.graphics.print(infoText, modalX + 20, modalY + 45)

    -- Draw efficiency if available
    if self.mBuilding.mResourceEfficiency then
        local effText = string.format("Resource Efficiency: %.0f%%", self.mBuilding.mResourceEfficiency * 100)
        love.graphics.setColor(0.5, 0.9, 0.5)
        love.graphics.print(effText, modalX + 20, modalY + 65)
    end

    -- Draw stations section
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Stations:", modalX + 20, modalY + 85)

    -- Set up scissor for scrolling content
    love.graphics.setScissor(modalX, modalY + 100, self.mModalWidth, self.mModalHeight - 140)

    for i, btn in ipairs(self.mStationButtons) do
        local station = self.mBuilding.mStations[i]
        local stateColor = STATE_COLORS[station.state] or STATE_COLORS.IDLE

        -- Station background
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", btn.x, btn.y - self.mScrollOffset, btn.width, btn.height, 5, 5)

        -- Station state indicator (left border)
        love.graphics.setColor(stateColor[1], stateColor[2], stateColor[3])
        love.graphics.rectangle("fill", btn.x, btn.y - self.mScrollOffset, 5, btn.height, 5, 0)

        -- Station number
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Station " .. i, btn.x + 15, btn.y + 8 - self.mScrollOffset)

        -- Recipe name or "No Recipe"
        love.graphics.setColor(0.8, 0.8, 0.8)
        local recipeName = "No Recipe"
        if station.recipe then
            recipeName = station.recipe.recipeName or station.recipe.name or "Unknown Recipe"
        end
        love.graphics.print(recipeName, btn.x + 15, btn.y + 28 - self.mScrollOffset)

        -- State text
        love.graphics.setColor(stateColor[1], stateColor[2], stateColor[3])
        love.graphics.print(station.state, btn.x + 200, btn.y + 8 - self.mScrollOffset)

        -- Progress bar (if producing)
        if station.state == "PRODUCING" and station.progress > 0 then
            local barWidth = 100
            local barHeight = 8
            local barX = btn.x + 200
            local barY = btn.y + 30 - self.mScrollOffset

            -- Background
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", barX, barY, barWidth, barHeight, 2, 2)

            -- Progress
            love.graphics.setColor(0.2, 0.7, 0.2)
            love.graphics.rectangle("fill", barX, barY, barWidth * station.progress, barHeight, 2, 2)

            -- Percentage text
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(string.format("%.0f%%", station.progress * 100), barX + barWidth + 10, barY - 2)
        end

        -- Recipe button
        local rbX = btn.recipeButtonX
        local rbY = btn.y + (btn.height - btn.recipeButtonHeight) / 2 - self.mScrollOffset
        local hoveringRecipe = mx >= rbX and mx <= rbX + btn.recipeButtonWidth and
                               my >= rbY and my <= rbY + btn.recipeButtonHeight

        love.graphics.setColor(hoveringRecipe and 0.4 or 0.3, hoveringRecipe and 0.5 or 0.4, hoveringRecipe and 0.6 or 0.5)
        love.graphics.rectangle("fill", rbX, rbY, btn.recipeButtonWidth, btn.recipeButtonHeight, 5, 5)
        love.graphics.setColor(0.6, 0.7, 0.8)
        love.graphics.rectangle("line", rbX, rbY, btn.recipeButtonWidth, btn.recipeButtonHeight, 5, 5)

        love.graphics.setColor(1, 1, 1)
        local buttonText = station.recipe and "Change" or "Set Recipe"
        local btnTextWidth = font:getWidth(buttonText)
        love.graphics.print(buttonText, rbX + (btn.recipeButtonWidth - btnTextWidth) / 2, rbY + 7)
    end

    love.graphics.setScissor()

    -- Draw storage section at bottom
    local storageY = modalY + self.mModalHeight - 80
    love.graphics.setColor(0.25, 0.25, 0.25)
    love.graphics.rectangle("fill", modalX + 10, storageY, self.mModalWidth - 20, 70, 5, 5)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Storage", modalX + 20, storageY + 5)

    -- Input storage
    love.graphics.setColor(0.7, 0.7, 0.7)
    local inputText = string.format("Inputs: %d / %d",
        self.mBuilding.mStorage.inputUsed,
        self.mBuilding.mStorage.inputCapacity)
    love.graphics.print(inputText, modalX + 20, storageY + 25)

    -- Output storage
    local outputText = string.format("Outputs: %d / %d",
        self.mBuilding.mStorage.outputUsed,
        self.mBuilding.mStorage.outputCapacity)
    love.graphics.print(outputText, modalX + 20, storageY + 45)

    -- Draw input/output commodity counts
    local inputX = modalX + 150
    for commodityId, amount in pairs(self.mBuilding.mStorage.inputs) do
        if amount > 0 then
            love.graphics.setColor(0.5, 0.7, 0.9)
            love.graphics.print(commodityId .. ": " .. amount, inputX, storageY + 25)
            inputX = inputX + 80
        end
    end

    local outputX = modalX + 150
    for commodityId, amount in pairs(self.mBuilding.mStorage.outputs) do
        if amount > 0 then
            love.graphics.setColor(0.7, 0.9, 0.5)
            love.graphics.print(commodityId .. ": " .. amount, outputX, storageY + 45)
            outputX = outputX + 80
        end
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end
