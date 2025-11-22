--
-- InfoSystemState - Information System for managing building recipes and data
-- CRUD interface for building recipes, worker requirements, etc.
--

InfoSystemState = {}
InfoSystemState.__index = InfoSystemState

function InfoSystemState:Create()
    local this = {
        -- Data
        mRecipes = {},
        mSelectedRecipeIndex = nil,
        mEditingRecipe = nil,

        -- UI State
        mLeftPanelWidth = 250,
        mScrollOffset = 0,
        mScrollMax = 0,

        -- Edit mode
        mEditMode = false,
        mEditField = nil,  -- Which field is being edited (e.g., "name", "productionTime", "input_wheat")
        mEditValue = "",   -- Current edit value

        -- Input buffer for text input
        mInputActive = false,
        mInputField = nil,
        mInputBuffer = "",

        -- Commodity picker
        mShowCommodityPicker = false,
        mPickerMode = nil,  -- "input" or "output"
        mPickerScrollOffset = 0,
        mPickerScrollMax = 0,
        mPickerSearchTerm = "",
        mCommodityList = {},

        -- Tabs
        mCurrentTab = "recipes"  -- recipes, workers, commodities
    }

    setmetatable(this, self)
    this:LoadRecipes()
    return this
end

function InfoSystemState:LoadRecipes()
    -- Load building_recipes.json
    local path = "data/building_recipes.json"
    local contents = love.filesystem.read(path)

    if contents then
        local json = require("code/json")
        local data = json.decode(contents)

        if data and data.recipes then
            self.mRecipes = data.recipes
            print("Loaded " .. #self.mRecipes .. " building recipes")
        else
            print("Warning: No recipes found in building_recipes.json")
            self.mRecipes = {}
        end
    else
        print("Warning: Could not load building_recipes.json")
        self.mRecipes = {}
    end

    -- Load commodity list from commodities.json
    self:LoadCommodities()
end

function InfoSystemState:LoadCommodities()
    local path = "data/commodities.json"
    local contents = love.filesystem.read(path)

    if contents then
        local json = require("code/json")
        local data = json.decode(contents)

        if data and data.commodities then
            self.mCommodityList = data.commodities
            print("Loaded " .. #self.mCommodityList .. " commodities")
        else
            print("Warning: No commodities found in commodities.json")
            self.mCommodityList = {}
        end
    else
        print("Warning: Could not load commodities.json")
        self.mCommodityList = {}
    end
end

function InfoSystemState:SaveRecipes()
    local json = require("code/json")
    local data = {
        recipes = self.mRecipes
    }

    local encoded = json.encode(data)
    local success = love.filesystem.write("data/building_recipes.json", encoded)

    if success then
        print("Recipes saved successfully!")
        return true
    else
        print("Error: Failed to save recipes")
        return false
    end
end

function InfoSystemState:Enter(params)
    print("Entering Information System")
end

function InfoSystemState:Exit()
end

function InfoSystemState:Update(dt)
    -- Handle clicks
    if gMousePressed and gMousePressed.button == 1 then
        local mx, my = gMousePressed.x, gMousePressed.y

        -- Check left panel (recipe list)
        if mx <= self.mLeftPanelWidth then
            self:HandleRecipeListClick(mx, my)
        else
            -- Check edit panel
            self:HandleEditPanelClick(mx, my)
        end
    end
end

function InfoSystemState:HandleRecipeListClick(mx, my)
    local itemHeight = 50
    local startY = 120
    local listY = startY - self.mScrollOffset

    for i, recipe in ipairs(self.mRecipes) do
        local itemY = listY + (i - 1) * itemHeight

        if my >= itemY and my <= itemY + itemHeight then
            self.mSelectedRecipeIndex = i
            self.mEditingRecipe = nil  -- Copy for editing
            return
        end
    end
end

function InfoSystemState:HandleEditPanelClick(mx, my)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Check Save button
    local saveX = screenW - 220
    local saveY = 70
    if mx >= saveX and mx <= saveX + 100 and my >= saveY and my <= saveY + 35 then
        self:SaveRecipes()
        return
    end

    -- Check Add New button
    local addX = screenW - 110
    local addY = 70
    if mx >= addX and mx <= addX + 100 and my >= addY and my <= addY + 35 then
        self:AddNewRecipe()
        return
    end

    -- Check Delete button
    local deleteX = screenW - 330
    local deleteY = 70
    if mx >= deleteX and mx <= deleteX + 100 and my >= deleteY and my <= deleteY + 35 then
        self:DeleteCurrentRecipe()
        return
    end

    -- Check if clicking on editable fields
    if self.mSelectedRecipeIndex then
        local recipe = self.mRecipes[self.mSelectedRecipeIndex]
        local editorX = self.mLeftPanelWidth + 20
        local editorY = 120
        local lineHeight = 30

        -- Calculate field positions and check clicks
        local y = editorY

        -- Skip buildingType (read-only ID)
        y = y + lineHeight

        -- Name field
        if my >= y and my <= y + lineHeight and mx >= editorX + 150 and mx <= editorX + 500 then
            self:StartEditingField("name", recipe.name)
            return
        end
        y = y + lineHeight

        -- Production Time field
        if my >= y and my <= y + lineHeight and mx >= editorX + 150 and mx <= editorX + 500 then
            self:StartEditingField("productionTime", tostring(recipe.productionTime))
            return
        end
    end
end

function InfoSystemState:StartEditingField(fieldName, currentValue)
    self.mInputActive = true
    self.mInputField = fieldName
    self.mInputBuffer = currentValue or ""
    print("Editing field: " .. fieldName .. " = " .. self.mInputBuffer)
end

function InfoSystemState:StopEditingField()
    if not self.mInputActive then return end

    local recipe = self.mRecipes[self.mSelectedRecipeIndex]
    if not recipe then
        self.mInputActive = false
        return
    end

    -- Apply the edited value
    if self.mInputField == "name" then
        recipe.name = self.mInputBuffer
    elseif self.mInputField == "productionTime" then
        recipe.productionTime = tonumber(self.mInputBuffer) or 60
    elseif self.mInputField:match("^input_") then
        local commodity = self.mInputField:sub(7)
        local amount = tonumber(self.mInputBuffer) or 0
        if amount > 0 then
            recipe.inputs[commodity] = amount
        else
            recipe.inputs[commodity] = nil
        end
    elseif self.mInputField:match("^output_") then
        local commodity = self.mInputField:sub(8)
        local amount = tonumber(self.mInputBuffer) or 0
        if amount > 0 then
            recipe.outputs[commodity] = amount
        else
            recipe.outputs[commodity] = nil
        end
    end

    self.mInputActive = false
    self.mInputField = nil
    self.mInputBuffer = ""
    print("Field updated")
end

function InfoSystemState:DeleteCurrentRecipe()
    if self.mSelectedRecipeIndex then
        local recipe = self.mRecipes[self.mSelectedRecipeIndex]
        print("Deleting recipe: " .. recipe.name)
        table.remove(self.mRecipes, self.mSelectedRecipeIndex)
        self.mSelectedRecipeIndex = nil
    end
end

function InfoSystemState:AddNewRecipe()
    local newRecipe = {
        buildingType = "new_building",
        name = "New Building",
        productionTime = 60,
        inputs = {},
        outputs = {},
        workers = {
            required = 1,
            max = 5,
            vocations = {},
            efficiencyBonus = 0.10
        },
        notes = ""
    }

    table.insert(self.mRecipes, newRecipe)
    self.mSelectedRecipeIndex = #self.mRecipes
    print("Added new recipe")
end

function InfoSystemState:Render()
    love.graphics.clear(0.15, 0.15, 0.17)

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Render top bar
    self:RenderTopBar()

    -- Render left panel (recipe list)
    self:RenderRecipeList()

    -- Render main panel (selected recipe editor)
    if self.mSelectedRecipeIndex then
        self:RenderRecipeEditor()
    else
        self:RenderEmptyState()
    end

    -- Render commodity picker modal on top
    self:RenderCommodityPicker()
end

function InfoSystemState:RenderTopBar()
    local screenW = love.graphics.getWidth()

    -- Top bar background
    love.graphics.setColor(0.2, 0.2, 0.23)
    love.graphics.rectangle("fill", 0, 0, screenW, 60)

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(24)
    love.graphics.print("Information System - Building Recipes", 20, 18)

    -- Recipe count
    love.graphics.setNewFont(14)
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print(#self.mRecipes .. " recipes loaded", 20, 42)

    -- Editing indicator
    if self.mInputActive then
        love.graphics.setColor(1, 1, 0.3)
        love.graphics.print("Editing: " .. self.mInputField, 250, 42)
    end

    -- Buttons
    -- Delete button
    love.graphics.setColor(0.7, 0.3, 0.3)
    love.graphics.rectangle("fill", screenW - 330, 70, 100, 35, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(16)
    love.graphics.print("Delete", screenW - 305, 78)

    -- Save button
    love.graphics.setColor(0.3, 0.6, 0.3)
    love.graphics.rectangle("fill", screenW - 220, 70, 100, 35, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Save", screenW - 195, 78)

    -- Add New button
    love.graphics.setColor(0.4, 0.5, 0.7)
    love.graphics.rectangle("fill", screenW - 110, 70, 100, 35, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Add New", screenW - 90, 78)

    -- Back button
    love.graphics.setColor(0.7, 0.3, 0.3)
    love.graphics.rectangle("fill", screenW - 120, 15, 100, 30, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Back (ESC)", screenW - 110, 20)
end

function InfoSystemState:RenderRecipeList()
    local screenH = love.graphics.getHeight()

    -- Panel background
    love.graphics.setColor(0.22, 0.22, 0.25)
    love.graphics.rectangle("fill", 0, 60, self.mLeftPanelWidth, screenH - 60)

    -- Header
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(18)
    love.graphics.print("Building Types", 15, 75)

    -- List items
    local itemHeight = 50
    local startY = 120
    local listHeight = screenH - startY

    -- Scissor for scrolling
    love.graphics.setScissor(0, startY, self.mLeftPanelWidth, listHeight)

    local yOffset = startY - self.mScrollOffset

    for i, recipe in ipairs(self.mRecipes) do
        local itemY = yOffset + (i - 1) * itemHeight

        -- Skip if outside visible area
        if itemY + itemHeight >= startY and itemY <= startY + listHeight then
            local isSelected = (i == self.mSelectedRecipeIndex)

            -- Background
            if isSelected then
                love.graphics.setColor(0.35, 0.45, 0.55)
            elseif i % 2 == 0 then
                love.graphics.setColor(0.25, 0.25, 0.28)
            else
                love.graphics.setColor(0.22, 0.22, 0.25)
            end
            love.graphics.rectangle("fill", 5, itemY, self.mLeftPanelWidth - 10, itemHeight - 2)

            -- Text
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(14)
            love.graphics.print(recipe.name or recipe.buildingType, 15, itemY + 8)

            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.setNewFont(11)
            love.graphics.print("ID: " .. recipe.buildingType, 15, itemY + 28)
        end
    end

    -- Calculate scroll max
    local totalHeight = #self.mRecipes * itemHeight
    self.mScrollMax = math.max(0, totalHeight - listHeight)

    love.graphics.setScissor()

    -- Scrollbar
    if self.mScrollMax > 0 then
        local scrollbarHeight = listHeight * (listHeight / totalHeight)
        local scrollbarY = startY + (self.mScrollOffset / self.mScrollMax) * (listHeight - scrollbarHeight)

        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", self.mLeftPanelWidth - 8, scrollbarY, 6, scrollbarHeight, 3, 3)
    end
end

function InfoSystemState:RenderRecipeEditor()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local editorX = self.mLeftPanelWidth + 20
    local editorY = 120
    local editorW = screenW - self.mLeftPanelWidth - 40

    local recipe = self.mRecipes[self.mSelectedRecipeIndex]
    if not recipe then return end

    -- Background
    love.graphics.setColor(0.18, 0.18, 0.20)
    love.graphics.rectangle("fill", self.mLeftPanelWidth, 60, screenW - self.mLeftPanelWidth, screenH - 60)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(20)
    love.graphics.print("Editing: " .. recipe.name, editorX, 75)

    local y = editorY
    local lineHeight = 30

    -- Building Type (read-only)
    love.graphics.setNewFont(14)
    love.graphics.setColor(0.8, 0.8, 0.3)
    love.graphics.print("Building Type:", editorX, y)
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print(recipe.buildingType .. " (read-only)", editorX + 150, y)
    y = y + lineHeight

    -- Name (editable)
    love.graphics.setColor(0.8, 0.8, 0.3)
    love.graphics.print("Name:", editorX, y)

    local nameValue = recipe.name
    local isEditingName = (self.mInputActive and self.mInputField == "name")
    if isEditingName then
        nameValue = self.mInputBuffer
        -- Highlight editing field
        love.graphics.setColor(0.3, 0.3, 0.4)
        love.graphics.rectangle("fill", editorX + 148, y - 2, 350, lineHeight - 4, 3, 3)
        love.graphics.setColor(1, 1, 0.5)
    else
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.print(nameValue, editorX + 150, y)

    -- Show cursor if editing
    if isEditingName then
        local textWidth = love.graphics.getFont():getWidth(nameValue)
        love.graphics.print("|", editorX + 150 + textWidth, y)
    end

    -- Edit hint
    if not isEditingName then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.setNewFont(11)
        love.graphics.print("(click to edit)", editorX + 450, y + 3)
        love.graphics.setNewFont(14)
    end
    y = y + lineHeight

    -- Production Time (editable)
    love.graphics.setColor(0.8, 0.8, 0.3)
    love.graphics.print("Production Time:", editorX, y)

    local timeValue = tostring(recipe.productionTime) .. "s"
    local isEditingTime = (self.mInputActive and self.mInputField == "productionTime")
    if isEditingTime then
        timeValue = self.mInputBuffer .. "s"
        -- Highlight editing field
        love.graphics.setColor(0.3, 0.3, 0.4)
        love.graphics.rectangle("fill", editorX + 148, y - 2, 200, lineHeight - 4, 3, 3)
        love.graphics.setColor(1, 1, 0.5)
    else
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.print(timeValue, editorX + 150, y)

    -- Show cursor if editing
    if isEditingTime then
        local textWidth = love.graphics.getFont():getWidth(timeValue)
        love.graphics.print("|", editorX + 150 + textWidth, y)
    end

    -- Edit hint
    if not isEditingTime then
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.setNewFont(11)
        love.graphics.print("(click to edit)", editorX + 350, y + 3)
        love.graphics.setNewFont(14)
    end
    y = y + lineHeight * 1.5

    -- Inputs section
    love.graphics.setNewFont(16)
    love.graphics.setColor(0.5, 0.8, 0.5)
    love.graphics.print("INPUTS:", editorX, y)

    -- Add Input button
    love.graphics.setColor(0.3, 0.6, 0.3)
    love.graphics.rectangle("fill", editorX + 100, y - 2, 80, 22, 3, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(12)
    love.graphics.print("+ Add", editorX + 115, y + 2)
    y = y + lineHeight

    love.graphics.setNewFont(14)
    if recipe.inputs and next(recipe.inputs) then
        for commodity, amount in pairs(recipe.inputs) do
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("  • " .. commodity .. ": " .. amount, editorX, y)

            -- Edit button
            love.graphics.setColor(0.5, 0.5, 0.7)
            love.graphics.rectangle("fill", editorX + 250, y, 45, 20, 3, 3)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(11)
            love.graphics.print("Edit", editorX + 258, y + 3)

            -- Remove button
            love.graphics.setColor(0.7, 0.3, 0.3)
            love.graphics.rectangle("fill", editorX + 300, y, 60, 20, 3, 3)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Remove", editorX + 308, y + 3)

            love.graphics.setNewFont(14)
            y = y + lineHeight
        end
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("  (No inputs required)", editorX, y)
        y = y + lineHeight
    end
    y = y + lineHeight * 0.5

    -- Outputs section
    love.graphics.setNewFont(16)
    love.graphics.setColor(0.8, 0.5, 0.8)
    love.graphics.print("OUTPUTS:", editorX, y)

    -- Add Output button
    love.graphics.setColor(0.6, 0.3, 0.6)
    love.graphics.rectangle("fill", editorX + 110, y - 2, 80, 22, 3, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(12)
    love.graphics.print("+ Add", editorX + 125, y + 2)
    y = y + lineHeight

    love.graphics.setNewFont(14)
    if recipe.outputs and next(recipe.outputs) then
        for commodity, amount in pairs(recipe.outputs) do
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print("  • " .. commodity .. ": " .. amount, editorX, y)

            -- Edit button
            love.graphics.setColor(0.5, 0.5, 0.7)
            love.graphics.rectangle("fill", editorX + 250, y, 45, 20, 3, 3)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(11)
            love.graphics.print("Edit", editorX + 258, y + 3)

            -- Remove button
            love.graphics.setColor(0.7, 0.3, 0.3)
            love.graphics.rectangle("fill", editorX + 300, y, 60, 20, 3, 3)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Remove", editorX + 308, y + 3)

            love.graphics.setNewFont(14)
            y = y + lineHeight
        end
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("  (No outputs)", editorX, y)
        y = y + lineHeight
    end
    y = y + lineHeight * 0.5

    -- Workers section
    love.graphics.setNewFont(16)
    love.graphics.setColor(0.5, 0.7, 0.9)
    love.graphics.print("WORKERS:", editorX, y)
    y = y + lineHeight

    love.graphics.setNewFont(14)
    if recipe.workers then
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.print("  Required: " .. recipe.workers.required, editorX, y)
        y = y + lineHeight
        love.graphics.print("  Maximum: " .. recipe.workers.max, editorX, y)
        y = y + lineHeight
        love.graphics.print("  Efficiency Bonus: " .. (recipe.workers.efficiencyBonus * 100) .. "%", editorX, y)
        y = y + lineHeight

        if recipe.workers.vocations and #recipe.workers.vocations > 0 then
            love.graphics.print("  Vocations: " .. table.concat(recipe.workers.vocations, ", "), editorX, y)
            y = y + lineHeight
        end
    end
    y = y + lineHeight * 0.5

    -- Notes
    if recipe.notes and recipe.notes ~= "" then
        love.graphics.setNewFont(12)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.printf("Notes: " .. recipe.notes, editorX, y, editorW)
    end
end

function InfoSystemState:RenderEmptyState()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setNewFont(18)
    local text = "Select a building type to edit"
    local textWidth = love.graphics.getFont():getWidth(text)
    love.graphics.print(text, (screenW + self.mLeftPanelWidth) / 2 - textWidth / 2, screenH / 2)
end

function InfoSystemState:OnMouseWheel(dx, dy)
    local mx, my = love.mouse.getPosition()

    -- Scroll left panel
    if mx <= self.mLeftPanelWidth then
        self.mScrollOffset = self.mScrollOffset - dy * 40
        self.mScrollOffset = math.max(0, math.min(self.mScrollOffset, self.mScrollMax))
    end
end

function InfoSystemState:keypressed(key)
    if not self.mInputActive then return end

    if key == "return" or key == "kpenter" then
        -- Save and stop editing
        self:StopEditingField()
    elseif key == "escape" then
        -- Cancel editing
        self.mInputActive = false
        self.mInputField = nil
        self.mInputBuffer = ""
    elseif key == "backspace" then
        -- Remove last character
        self.mInputBuffer = self.mInputBuffer:sub(1, -2)
    end
end

function InfoSystemState:textinput(t)
    if not self.mInputActive then return end

    -- Add typed character to buffer
    self.mInputBuffer = self.mInputBuffer .. t
end

function InfoSystemState:RenderCommodityPicker()
    if not self.mShowCommodityPicker then return end

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal
    local modalW = 500
    local modalH = 600
    local modalX = (screenW - modalW) / 2
    local modalY = (screenH - modalH) / 2

    love.graphics.setColor(0.25, 0.25, 0.28)
    love.graphics.rectangle("fill", modalX, modalY, modalW, modalH, 10, 10)

    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(20)
    local title = "Select Commodity - " .. (self.mPickerMode == "input" and "Input" or "Output")
    love.graphics.print(title, modalX + 20, modalY + 15)

    -- Close button
    love.graphics.setColor(0.8, 0.3, 0.3)
    love.graphics.rectangle("fill", modalX + modalW - 35, modalY + 10, 25, 25, 3, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(16)
    love.graphics.print("X", modalX + modalW - 28, modalY + 13)

    -- Commodity list
    local listY = modalY + 60
    local listHeight = modalH - 80
    local itemHeight = 40

    love.graphics.setScissor(modalX + 10, listY, modalW - 20, listHeight)

    local yOffset = listY - self.mPickerScrollOffset

    for i, comm in ipairs(self.mCommodityList) do
        local itemY = yOffset + (i - 1) * itemHeight

        if itemY + itemHeight >= listY and itemY <= listY + listHeight then
            local mx, my = love.mouse.getPosition()
            local isHovered = mx >= modalX + 10 and mx <= modalX + modalW - 10 and
                             my >= itemY and my <= itemY + itemHeight

            -- Background
            if isHovered then
                love.graphics.setColor(0.35, 0.35, 0.38)
            elseif i % 2 == 0 then
                love.graphics.setColor(0.28, 0.28, 0.31)
            else
                love.graphics.setColor(0.25, 0.25, 0.28)
            end
            love.graphics.rectangle("fill", modalX + 10, itemY, modalW - 20, itemHeight - 2)

            -- Icon
            love.graphics.setColor(0.8, 0.8, 0.3)
            love.graphics.rectangle("fill", modalX + 20, itemY + 5, 30, 30)
            love.graphics.setColor(0, 0, 0)
            love.graphics.setNewFont(14)
            love.graphics.print(comm.icon or "?", modalX + 28, itemY + 12)

            -- Name
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(16)
            love.graphics.print(comm.name, modalX + 60, itemY + 8)

            -- Category
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.setNewFont(11)
            love.graphics.print(comm.category or "", modalX + 60, itemY + 25)
        end
    end

    -- Calculate scroll max
    local totalHeight = #self.mCommodityList * itemHeight
    self.mPickerScrollMax = math.max(0, totalHeight - listHeight)

    love.graphics.setScissor()

    -- Scrollbar
    if self.mPickerScrollMax > 0 then
        local scrollbarHeight = listHeight * (listHeight / totalHeight)
        local scrollbarY = listY + (self.mPickerScrollOffset / self.mPickerScrollMax) * (listHeight - scrollbarHeight)

        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", modalX + modalW - 18, scrollbarY, 6, scrollbarHeight, 3, 3)
    end
end

return InfoSystemState
