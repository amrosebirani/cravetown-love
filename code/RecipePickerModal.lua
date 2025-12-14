--
-- RecipePickerModal - allows selecting a recipe for a station
--

require("code/DataLoader")

RecipePickerModal = {}
RecipePickerModal.__index = RecipePickerModal

function RecipePickerModal:Create(building, stationIndex, onSelect)
    local this = {
        mBuilding = building,
        mStationIndex = stationIndex,
        mOnSelect = onSelect,
        mModalWidth = 450,
        mModalHeight = 400,
        mScrollOffset = 0,
        mMaxScroll = 0,
        mRecipes = {},
        mRecipeButtons = {},
        mCloseButton = nil,
        mJustOpened = true  -- Prevent closing on the same click that opened the modal
    }

    setmetatable(this, self)
    this:LoadRecipes()
    this:CalculateLayout()
    return this
end

function RecipePickerModal:LoadRecipes()
    -- Load all recipes from JSON
    local allRecipes = DataLoader.loadBuildingRecipes()

    -- Filter recipes for this building type
    self.mRecipes = {}
    local buildingTypeId = self.mBuilding.mTypeId

    for _, recipe in ipairs(allRecipes) do
        if recipe.buildingType == buildingTypeId then
            table.insert(self.mRecipes, recipe)
        end
    end

    -- Add a "Clear Recipe" option at the beginning
    table.insert(self.mRecipes, 1, {
        recipeName = "Clear Recipe",
        name = "None",
        category = "",
        productionTime = 0,
        inputs = {},
        outputs = {},
        isClear = true
    })
end

function RecipePickerModal:CalculateLayout()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local modalX = (screenW - self.mModalWidth) / 2
    local modalY = (screenH - self.mModalHeight) / 2

    -- Calculate recipe button positions
    self.mRecipeButtons = {}
    local recipeY = modalY + 60
    local recipeHeight = 80
    local recipeSpacing = 8

    for i, recipe in ipairs(self.mRecipes) do
        table.insert(self.mRecipeButtons, {
            recipeIndex = i,
            x = modalX + 20,
            y = recipeY + (i - 1) * (recipeHeight + recipeSpacing),
            width = self.mModalWidth - 40,
            height = recipeHeight
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
    local contentHeight = 60 + (#self.mRecipes * (recipeHeight + recipeSpacing))
    self.mMaxScroll = math.max(0, contentHeight - self.mModalHeight + 40)
end

function RecipePickerModal:Enter()
end

function RecipePickerModal:Exit()
end

function RecipePickerModal:HandleInput()
    return true  -- Block input to lower states
end

function RecipePickerModal:OnMouseWheel(dx, dy)
    -- Handle mouse wheel scrolling
    self.mScrollOffset = self.mScrollOffset - dy * 30
    self.mScrollOffset = math.max(0, math.min(self.mScrollOffset, self.mMaxScroll))
end

function RecipePickerModal:Update(dt)
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

    -- Check recipe buttons (account for scroll offset)
    for _, btn in ipairs(self.mRecipeButtons) do
        local btnY = btn.y - self.mScrollOffset
        if mx >= btn.x and mx <= btn.x + btn.width and
           my >= btnY and my <= btnY + btn.height then
            -- Recipe selected
            local recipe = self.mRecipes[btn.recipeIndex]
            if recipe.isClear then
                -- Clear recipe callback
                if self.mOnSelect then
                    self.mOnSelect(nil)
                end
            else
                -- Select this recipe
                if self.mOnSelect then
                    self.mOnSelect(recipe)
                end
            end
            gStateStack:Pop()
            return false
        end
    end

    return true
end

function RecipePickerModal:FormatTime(seconds)
    if seconds >= 3600 then
        local hours = math.floor(seconds / 3600)
        local mins = math.floor((seconds % 3600) / 60)
        if mins > 0 then
            return string.format("%dh %dm", hours, mins)
        else
            return string.format("%dh", hours)
        end
    elseif seconds >= 60 then
        local mins = math.floor(seconds / 60)
        local secs = seconds % 60
        if secs > 0 then
            return string.format("%dm %ds", mins, secs)
        else
            return string.format("%dm", mins)
        end
    else
        return string.format("%ds", seconds)
    end
end

function RecipePickerModal:Render()
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
    local titleText = "Select Recipe for Station " .. self.mStationIndex
    local font = love.graphics.getFont()
    local titleWidth = font:getWidth(titleText)
    love.graphics.print(titleText, modalX + (self.mModalWidth - titleWidth) / 2, modalY + 15)

    -- Draw building info
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Building: " .. self.mBuilding.mName, modalX + 20, modalY + 40)

    -- Set up scissor for scrolling content
    love.graphics.setScissor(modalX, modalY + 60, self.mModalWidth, self.mModalHeight - 70)

    -- Draw recipe buttons
    for i, btn in ipairs(self.mRecipeButtons) do
        local recipe = self.mRecipes[i]
        local btnY = btn.y - self.mScrollOffset

        -- Check hover
        local hoveringRecipe = mx >= btn.x and mx <= btn.x + btn.width and
                               my >= btnY and my <= btnY + btn.height

        -- Button background
        if recipe.isClear then
            love.graphics.setColor(hoveringRecipe and 0.35 or 0.25, 0.2, 0.2)
        else
            love.graphics.setColor(hoveringRecipe and 0.3 or 0.22, hoveringRecipe and 0.35 or 0.27, hoveringRecipe and 0.4 or 0.32)
        end
        love.graphics.rectangle("fill", btn.x, btnY, btn.width, btn.height, 5, 5)

        -- Button border
        if recipe.isClear then
            love.graphics.setColor(0.6, 0.3, 0.3)
        else
            love.graphics.setColor(0.5, 0.6, 0.7)
        end
        love.graphics.rectangle("line", btn.x, btnY, btn.width, btn.height, 5, 5)

        -- Recipe name
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(recipe.recipeName, btn.x + 10, btnY + 8)

        if not recipe.isClear then
            -- Category and time
            love.graphics.setColor(0.6, 0.6, 0.6)
            local categoryText = recipe.category or ""
            if recipe.productionTime and recipe.productionTime > 0 then
                categoryText = categoryText .. " | Time: " .. self:FormatTime(recipe.productionTime)
            end
            love.graphics.print(categoryText, btn.x + 10, btnY + 26)

            -- Inputs
            love.graphics.setColor(0.9, 0.6, 0.5)
            local inputText = "In: "
            local hasInputs = false
            for commodityId, amount in pairs(recipe.inputs or {}) do
                if hasInputs then inputText = inputText .. ", " end
                inputText = inputText .. amount .. " " .. commodityId
                hasInputs = true
            end
            if not hasInputs then inputText = "In: (none)" end
            love.graphics.print(inputText, btn.x + 10, btnY + 44)

            -- Outputs
            love.graphics.setColor(0.5, 0.9, 0.5)
            local outputText = "Out: "
            local hasOutputs = false
            for commodityId, amount in pairs(recipe.outputs or {}) do
                if hasOutputs then outputText = outputText .. ", " end
                outputText = outputText .. amount .. " " .. commodityId
                hasOutputs = true
            end
            if not hasOutputs then outputText = "Out: (none)" end
            love.graphics.print(outputText, btn.x + 10, btnY + 62)
        else
            -- Clear recipe description
            love.graphics.setColor(0.7, 0.5, 0.5)
            love.graphics.print("Remove the current recipe from this station", btn.x + 10, btnY + 30)
        end
    end

    love.graphics.setScissor()

    -- Show scroll indicator if needed
    if self.mMaxScroll > 0 then
        love.graphics.setColor(0.5, 0.5, 0.5)
        local scrollBarHeight = 20
        local scrollBarY = modalY + 60 + (self.mScrollOffset / self.mMaxScroll) * (self.mModalHeight - 90 - scrollBarHeight)
        love.graphics.rectangle("fill", modalX + self.mModalWidth - 15, scrollBarY, 10, scrollBarHeight, 3, 3)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

