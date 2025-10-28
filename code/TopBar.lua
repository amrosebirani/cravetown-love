--
-- TopBar - top menu bar with buttons (inventory, etc.)
--

TopBar = {}
TopBar.__index = TopBar

function TopBar:Create()
    local this = {
        mHeight = 50,
        mButtons = {}
    }

    setmetatable(this, self)

    -- Create inventory button
    table.insert(this.mButtons, {
        id = "inventory",
        label = "Inventory",
        icon = "I",
        x = 10,
        y = 5,
        width = 120,
        height = 40,
        color = {0.2, 0.6, 0.4}
    })

    -- Could add more buttons here (Settings, Stats, etc.)
    table.insert(this.mButtons, {
        id = "stats",
        label = "Stats",
        icon = "S",
        x = 140,
        y = 5,
        width = 100,
        height = 40,
        color = {0.4, 0.4, 0.6}
    })

    return this
end

function TopBar:Enter()
end

function TopBar:Exit()
end

function TopBar:Update(dt)
    -- Check for button clicks
    if gMouseReleased and gMouseReleased.button == 1 then
        local mx, my = gMouseReleased.x, gMouseReleased.y

        for _, button in ipairs(self.mButtons) do
            if mx >= button.x and mx <= button.x + button.width and
               my >= button.y and my <= button.y + button.height then
                -- Button clicked
                self:OnButtonClick(button.id)
                return false -- Stop processing
            end
        end
    end

    return true -- Continue processing input for states below
end

function TopBar:OnButtonClick(buttonId)
    if buttonId == "inventory" then
        -- Toggle inventory drawer
        local drawerOpen = false
        for i = #gStateStack.mStates, 1, -1 do
            local state = gStateStack.mStates[i]
            if state.mIsInventoryDrawer then
                -- Close drawer
                gStateStack:Pop()
                drawerOpen = true
                break
            end
        end

        if not drawerOpen then
            -- Open drawer
            require("code/InventoryDrawer")
            local drawer = InventoryDrawer:Create()
            gStateStack:Push(drawer)
        end
    elseif buttonId == "stats" then
        print("Stats button clicked - not implemented yet")
    end
end

function TopBar:Render()
    -- Draw background
    love.graphics.setColor(0.25, 0.25, 0.25, 0.95)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), self.mHeight)

    -- Draw buttons
    local mx, my = love.mouse.getPosition()

    for _, button in ipairs(self.mButtons) do
        local isHovering = mx >= button.x and mx <= button.x + button.width and
                          my >= button.y and my <= button.y + button.height

        -- Button background
        if isHovering then
            love.graphics.setColor(button.color[1] * 1.3, button.color[2] * 1.3, button.color[3] * 1.3)
        else
            love.graphics.setColor(button.color[1], button.color[2], button.color[3])
        end
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 5, 5)

        -- Button border
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 5, 5)

        -- Button text
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

function TopBar:HandleInput()
end

return TopBar
