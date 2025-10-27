--
-- BuildingMenu - bottom menu showing available buildings to place
--

BuildingMenu = {}
BuildingMenu.__index = BuildingMenu

function BuildingMenu:Create()
    local this = {
        mHeight = 100,
        mPadding = 10,
        mButtonWidth = 80,
        mButtonHeight = 80,
        mButtons = {}
    }

    setmetatable(this, self)

    -- Create button for house building
    table.insert(this.mButtons, {
        type = "house",
        label = "H",
        color = {0.2, 0.4, 0.8},
        x = this.mPadding,
        y = love.graphics.getHeight() - this.mHeight + this.mPadding,
        width = this.mButtonWidth,
        height = this.mButtonHeight
    })

    return this
end

function BuildingMenu:Enter()
    -- Called when this state is entered
end

function BuildingMenu:Exit()
    -- Called when this state is exited
end

function BuildingMenu:Update(dt)
    -- Check for mouse clicks on buttons
    if gMouseReleased and gMouseReleased.button == 1 then
        local mx, my = gMouseReleased.x, gMouseReleased.y

        for _, button in ipairs(self.mButtons) do
            if mx >= button.x and mx <= button.x + button.width and
               my >= button.y and my <= button.y + button.height then
                -- Button clicked - switch to building placement state
                gStateMachine:Change("BuildingPlacement", {type = button.type})
                return false -- Stop processing input
            end
        end
    end

    return true -- Continue processing input for states below
end

function BuildingMenu:Render()
    -- Draw menu background
    love.graphics.setColor(0.3, 0.3, 0.3, 0.9)
    love.graphics.rectangle(
        "fill",
        0,
        love.graphics.getHeight() - self.mHeight,
        love.graphics.getWidth(),
        self.mHeight
    )

    -- Draw buttons
    for _, button in ipairs(self.mButtons) do
        -- Check if mouse is hovering
        local mx, my = love.mouse.getPosition()
        local isHovering = mx >= button.x and mx <= button.x + button.width and
                          my >= button.y and my <= button.y + button.height

        -- Draw button background
        if isHovering then
            love.graphics.setColor(button.color[1] * 1.2, button.color[2] * 1.2, button.color[3] * 1.2)
        else
            love.graphics.setColor(button.color[1], button.color[2], button.color[3])
        end
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)

        -- Draw button border
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height)

        -- Draw label
        love.graphics.setColor(1, 1, 1)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(button.label)
        local textHeight = font:getHeight()
        love.graphics.print(
            button.label,
            button.x + button.width / 2 - textWidth / 2,
            button.y + button.height / 2 - textHeight / 2
        )
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function BuildingMenu:HandleInput()
    -- Input is handled in Update
end
