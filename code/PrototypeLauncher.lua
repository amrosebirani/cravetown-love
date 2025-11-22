--
-- PrototypeLauncher - Main menu to select which prototype to launch
--

PrototypeLauncher = {}
PrototypeLauncher.__index = PrototypeLauncher

function PrototypeLauncher:Create()
    local this = {
        mPrototypes = {
            {
                id = "main",
                name = "Main Game",
                description = "Full game with geography, buildings, and town management",
                color = {0.2, 0.6, 0.9}
            },
            {
                id = "prototype1",
                name = "Prototype 1: Consumption Engine",
                description = "Character behavior, craving systems, resource allocation",
                color = {0.9, 0.5, 0.3}
            },
            {
                id = "prototype2",
                name = "Prototype 2: Production Engine",
                description = "Building production, worker management, efficiency tracking",
                color = {0.4, 0.8, 0.4}
            }
        },
        mHoveredIndex = nil,
        mSelectedPrototype = nil
    }

    setmetatable(this, self)
    return this
end

function PrototypeLauncher:Update(dt)
    -- Check mouse hover
    local mx, my = love.mouse.getPosition()
    self.mHoveredIndex = nil

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local cardWidth = 400
    local cardHeight = 150
    local spacing = 30
    local totalHeight = (#self.mPrototypes * cardHeight) + ((#self.mPrototypes - 1) * spacing)
    local startY = (screenH - totalHeight) / 2
    local startX = (screenW - cardWidth) / 2

    for i, proto in ipairs(self.mPrototypes) do
        local y = startY + (i - 1) * (cardHeight + spacing)

        if mx >= startX and mx <= startX + cardWidth and
           my >= y and my <= y + cardHeight then
            self.mHoveredIndex = i
        end
    end

    -- Check for click
    if gMousePressed and gMousePressed.button == 1 and self.mHoveredIndex then
        self.mSelectedPrototype = self.mPrototypes[self.mHoveredIndex].id
        return true  -- Signal to launch
    end

    return false
end

function PrototypeLauncher:Render()
    love.graphics.clear(0.95, 0.95, 0.95)

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Title
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.setNewFont(48)
    local title = "CraveTown - Select Prototype"
    local titleWidth = love.graphics.getFont():getWidth(title)
    love.graphics.print(title, (screenW - titleWidth) / 2, 80)

    -- Prototype cards
    local cardWidth = 400
    local cardHeight = 150
    local spacing = 30
    local totalHeight = (#self.mPrototypes * cardHeight) + ((#self.mPrototypes - 1) * spacing)
    local startY = (screenH - totalHeight) / 2
    local startX = (screenW - cardWidth) / 2

    for i, proto in ipairs(self.mPrototypes) do
        local y = startY + (i - 1) * (cardHeight + spacing)
        local isHovered = (self.mHoveredIndex == i)

        -- Card background
        if isHovered then
            love.graphics.setColor(proto.color[1] * 0.9, proto.color[2] * 0.9, proto.color[3] * 0.9)
        else
            love.graphics.setColor(proto.color[1] * 0.7, proto.color[2] * 0.7, proto.color[3] * 0.7)
        end
        love.graphics.rectangle("fill", startX, y, cardWidth, cardHeight, 10, 10)

        -- Card border
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.setLineWidth(isHovered and 3 or 2)
        love.graphics.rectangle("line", startX, y, cardWidth, cardHeight, 10, 10)

        -- Card content
        love.graphics.setColor(1, 1, 1)
        love.graphics.setNewFont(24)
        love.graphics.print(proto.name, startX + 20, y + 20)

        love.graphics.setColor(0.95, 0.95, 0.95)
        love.graphics.setNewFont(14)
        love.graphics.printf(proto.description, startX + 20, y + 60, cardWidth - 40)

        -- Hover instruction
        if isHovered then
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(16)
            love.graphics.print("Click to launch", startX + 20, y + cardHeight - 35)
        end
    end

    -- Footer
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setNewFont(14)
    local footer = "Press ESC to quit"
    love.graphics.print(footer, 20, screenH - 30)

    love.graphics.setColor(1, 1, 1)
end

function PrototypeLauncher:GetSelectedPrototype()
    return self.mSelectedPrototype
end

return PrototypeLauncher
