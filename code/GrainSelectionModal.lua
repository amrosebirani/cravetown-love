--
-- GrainSelectionModal - modal dialog for selecting which grain a farm will produce
--

GrainSelectionModal = {}
GrainSelectionModal.__index = GrainSelectionModal

function GrainSelectionModal:Create(building)
    local this = {
        mIsGrainSelectionModal = true,
        mBuilding = building,
        mGrainOptions = {
            {id = "wheat", name = "Wheat", color = {0.9, 0.8, 0.4}, description = "Classic grain for bread"},
            {id = "barley", name = "Barley", color = {0.8, 0.7, 0.3}, description = "Used for brewing and feed"},
            {id = "rice", name = "Rice", color = {0.95, 0.95, 0.9}, description = "Staple grain for many"},
            {id = "maize", name = "Maize", color = {0.9, 0.7, 0.2}, description = "Versatile corn grain"},
            {id = "rye", name = "Rye", color = {0.6, 0.5, 0.3}, description = "Hardy winter grain"},
            {id = "oats", name = "Oats", color = {0.85, 0.75, 0.5}, description = "Nutritious breakfast grain"}
        },
        mButtons = {},
        mModalWidth = 500,
        mModalHeight = 480
    }

    setmetatable(this, self)

    -- Create buttons for each grain option
    this:CreateButtons()

    return this
end

function GrainSelectionModal:CreateButtons()
    local buttonWidth = 420
    local buttonHeight = 55
    local buttonSpacing = 8
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local modalX = (screenW - self.mModalWidth) / 2
    local modalY = (screenH - self.mModalHeight) / 2

    local startY = modalY + 90

    for i, grain in ipairs(self.mGrainOptions) do
        local buttonX = modalX + (self.mModalWidth - buttonWidth) / 2
        local buttonY = startY + (i - 1) * (buttonHeight + buttonSpacing)

        table.insert(self.mButtons, {
            grain = grain,
            x = buttonX,
            y = buttonY,
            width = buttonWidth,
            height = buttonHeight
        })
    end
end

function GrainSelectionModal:Enter()
end

function GrainSelectionModal:Exit()
end

function GrainSelectionModal:HandleInput()
    return true
end

function GrainSelectionModal:Update(dt)
    -- Check for button clicks
    if gMouseReleased and gMouseReleased.button == 1 then
        local mx, my = gMouseReleased.x, gMouseReleased.y

        for _, button in ipairs(self.mButtons) do
            if mx >= button.x and mx <= button.x + button.width and
               my >= button.y and my <= button.y + button.height then
                -- Grain selected
                self:OnGrainSelected(button.grain.id)
                return false
            end
        end
    end

    return true
end

function GrainSelectionModal:OnGrainSelected(grainId)
    -- Set the grain type for the building
    if self.mBuilding then
        self.mBuilding.mProducedGrain = grainId
        print("Farm will produce: " .. grainId)
    end

    -- Close the modal
    gStateStack:Pop()
end

function GrainSelectionModal:Render()
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
    local titleText = "Select Grain Type for Farm"
    local titleWidth = font:getWidth(titleText)
    love.graphics.print(titleText, modalX + (self.mModalWidth - titleWidth) / 2, modalY + 20)

    -- Draw instruction
    local instructionText = "Choose which grain this farm will produce:"
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
                button.grain.color[1] * 1.2,
                button.grain.color[2] * 1.2,
                button.grain.color[3] * 1.2,
                0.95
            )
        else
            love.graphics.setColor(
                button.grain.color[1],
                button.grain.color[2],
                button.grain.color[3],
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

        -- Draw grain icon/indicator
        love.graphics.setColor(0.3, 0.2, 0.1, 0.8)
        love.graphics.circle("fill", button.x + 25, button.y + button.height / 2, 15)

        -- Button text - grain name
        love.graphics.setColor(0.1, 0.1, 0.1)
        local nameText = button.grain.name
        love.graphics.print(nameText, button.x + 50, button.y + 10)

        -- Button text - description
        love.graphics.setColor(0.3, 0.3, 0.3)
        local descText = button.grain.description
        love.graphics.print(descText, button.x + 50, button.y + 32)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end
