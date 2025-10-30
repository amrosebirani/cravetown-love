--
-- MineSelectionModal - modal dialog for selecting which ore type a mine will extract
--

MineSelectionModal = {}
MineSelectionModal.__index = MineSelectionModal

function MineSelectionModal:Create(building)
    local this = {
        mIsMineSelectionModal = true,
        mBuilding = building,
        mOreOptions = {
            {ore = "coal", color = {0.1, 0.1, 0.1}, name = "Coal", size = "large", description = "Large deposit (10 units)"},
            {ore = "ore", color = {0.5, 0.4, 0.3}, name = "Iron Ore", size = "large", description = "Large deposit (10 units)"},
            {ore = "stone", color = {0.5, 0.5, 0.5}, name = "Stone", size = "large", description = "Large deposit (10 units)"},
            {ore = "copper_ore", color = {0.6, 0.4, 0.2}, name = "Copper Ore", size = "medium", description = "Medium deposit (5 units)"},
            {ore = "clay", color = {0.6, 0.5, 0.4}, name = "Clay", size = "medium", description = "Medium deposit (5 units)"},
            {ore = "sand", color = {0.8, 0.7, 0.6}, name = "Sand", size = "medium", description = "Medium deposit (5 units)"},
            {ore = "gold_ore", color = {0.9, 0.8, 0.3}, name = "Gold Ore", size = "small", description = "Small deposit (3 units)"},
            {ore = "silver_ore", color = {0.7, 0.7, 0.7}, name = "Silver Ore", size = "small", description = "Small deposit (3 units)"},
            {ore = "marble", color = {0.9, 0.9, 0.9}, name = "Marble", size = "small", description = "Small deposit (3 units)"}
        },
        mButtons = {},
        mModalWidth = 500,
        mModalHeight = 680,  -- Increased to fit all 9 ore options
        mScrollOffset = 0
    }

    setmetatable(this, self)

    -- Create buttons for each ore option
    this:CreateButtons()

    return this
end

function MineSelectionModal:CreateButtons()
    local buttonWidth = 420
    local buttonHeight = 55
    local buttonSpacing = 8
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local modalX = (screenW - self.mModalWidth) / 2
    local modalY = (screenH - self.mModalHeight) / 2

    local startY = modalY + 90

    for i, ore in ipairs(self.mOreOptions) do
        local buttonX = modalX + (self.mModalWidth - buttonWidth) / 2
        local buttonY = startY + (i - 1) * (buttonHeight + buttonSpacing)

        table.insert(self.mButtons, {
            ore = ore,
            x = buttonX,
            y = buttonY,
            width = buttonWidth,
            height = buttonHeight
        })
    end
end

function MineSelectionModal:Enter()
end

function MineSelectionModal:Exit()
end

function MineSelectionModal:HandleInput()
    return true
end

function MineSelectionModal:Update(dt)
    -- Check for button clicks
    if gMouseReleased and gMouseReleased.button == 1 then
        local mx, my = gMouseReleased.x, gMouseReleased.y

        for _, button in ipairs(self.mButtons) do
            if mx >= button.x and mx <= button.x + button.width and
               my >= button.y and my <= button.y + button.height then
                -- Ore selected
                self:OnOreSelected(button.ore)
                return false
            end
        end
    end

    return true
end

function MineSelectionModal:OnOreSelected(oreData)
    -- Set the ore type for the building as a custom mine
    if self.mBuilding then
        self.mBuilding.mIsCustomMine = true
        self.mBuilding.mMineOre = oreData.ore
        self.mBuilding.mMineOreName = oreData.name
        self.mBuilding.mMineOreColor = oreData.color
        self.mBuilding.mMineOreSize = oreData.size

        -- Calculate ore quantity based on size
        local quantity = 0
        if oreData.size == "large" then
            quantity = 10
        elseif oreData.size == "medium" then
            quantity = 5
        elseif oreData.size == "small" then
            quantity = 3
        end
        self.mBuilding.mMineOreQuantity = quantity

        print("Mine will extract: " .. oreData.name .. " (" .. quantity .. " units)")
    end

    -- Close the modal
    gStateStack:Pop()
end

function MineSelectionModal:Render()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Draw modal background
    local modalX = (screenW - self.mModalWidth) / 2
    local modalY = (screenH - self.mModalHeight) / 2

    love.graphics.setColor(0.2, 0.2, 0.2, 0.95)
    love.graphics.rectangle("fill", modalX, modalY, self.mModalWidth, self.mModalHeight, 10, 10)

    -- Draw modal border
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", modalX, modalY, self.mModalWidth, self.mModalHeight, 10, 10)
    love.graphics.setLineWidth(1)

    -- Draw title
    love.graphics.setColor(1, 1, 1)
    local font = love.graphics.getFont()
    local titleText = "Select Ore Type for Mine"
    local titleWidth = font:getWidth(titleText)
    love.graphics.print(titleText, modalX + (self.mModalWidth - titleWidth) / 2, modalY + 20)

    -- Draw instruction
    local instructionText = "Choose which ore this mine will extract:"
    local instructionWidth = font:getWidth(instructionText)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(instructionText, modalX + (self.mModalWidth - instructionWidth) / 2, modalY + 50)

    -- Draw buttons
    local mx, my = love.mouse.getPosition()

    for _, button in ipairs(self.mButtons) do
        local isHovering = mx >= button.x and mx <= button.x + button.width and
                          my >= button.y and my <= button.y + button.height

        -- Button background
        if isHovering then
            love.graphics.setColor(
                math.min(1, button.ore.color[1] * 1.4),
                math.min(1, button.ore.color[2] * 1.4),
                math.min(1, button.ore.color[3] * 1.4),
                0.95
            )
        else
            love.graphics.setColor(
                button.ore.color[1],
                button.ore.color[2],
                button.ore.color[3],
                0.85
            )
        end
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 8, 8)

        -- Button border
        if isHovering then
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.setLineWidth(3)
        else
            love.graphics.setColor(0, 0, 0, 0.5)
            love.graphics.setLineWidth(2)
        end
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 8, 8)
        love.graphics.setLineWidth(1)

        -- Draw ore icon/indicator (circular ore representation)
        love.graphics.setColor(
            button.ore.color[1] * 0.7,
            button.ore.color[2] * 0.7,
            button.ore.color[3] * 0.7,
            0.8
        )
        love.graphics.circle("fill", button.x + 25, button.y + button.height / 2, 15)

        -- Highlight on ore icon
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.circle("fill", button.x + 20, button.y + button.height / 2 - 5, 5)

        -- Button text - ore name
        love.graphics.setColor(1, 1, 1)
        local nameText = button.ore.name
        love.graphics.print(nameText, button.x + 50, button.y + 10)

        -- Button text - description
        love.graphics.setColor(0.9, 0.9, 0.9)
        local descText = button.ore.description
        love.graphics.print(descText, button.x + 50, button.y + 32)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

return MineSelectionModal
