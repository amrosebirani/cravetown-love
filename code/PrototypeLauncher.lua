--
-- PrototypeLauncher - Main menu to select which prototype to launch
--

PrototypeLauncher = {}
PrototypeLauncher.__index = PrototypeLauncher

function PrototypeLauncher:Create()
    local this = {
        mPrototypes = {
            {
                id = "alpha",
                name = "Alpha Prototype (Birthday Edition)",
                description = "Play the alpha prototype - A special birthday gift for Mansi!",
                color = {0.9, 0.4, 0.6},
                highlight = true
            },
            {
                id = "specialty_towns",
                name = "Specialty Towns (CFP Prototype)",
                description = "Choose from 4 Indian specialty towns: Mumbai (Vada Pav), Indore (Poha), Bangalore (Dosa), Kolkata (Rasogulla)",
                color = {0.95, 0.7, 0.3},
                highlight = true
            },
            {
                id = "main",
                name = "Main Game",
                description = "Full game with geography, buildings, and town management",
                color = {0.2, 0.6, 0.9}
            },
            {
                id = "prototype2",
                name = "Prototype 2: Production Engine",
                description = "Building production, worker management, efficiency tracking",
                color = {0.4, 0.8, 0.4}
            },
            {
                id = "test_cache",
                name = "Consumption System Test (Phase 5)",
                description = "Complete system: cache, allocation, productivity, protest & riots",
                color = {0.9, 0.6, 0.3}
            }
        },
        mHoveredIndex = nil,
        mSelectedPrototype = nil,
        -- Create fonts once to avoid memory leak
        mFonts = {
            title = love.graphics.newFont(48),
            cardTitle = love.graphics.newFont(24),
            cardDesc = love.graphics.newFont(14),
            hover = love.graphics.newFont(16),
            footer = love.graphics.newFont(14)
        }
    }

    setmetatable(this, self)
    return this
end

function PrototypeLauncher:Update(dt)
    -- Check mouse hover
    local mx, my = love.mouse.getPosition()
    self.mHoveredIndex = nil

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local cardWidth = 340
    local cardHeight = 130
    local spacingX = 30
    local spacingY = 25
    local startY = 150

    -- Grid layout: 2 cards in row 1, 3 cards in row 2
    local gridPositions = {
        -- Row 1: 2 cards centered
        {row = 0, col = 0, totalInRow = 2},
        {row = 0, col = 1, totalInRow = 2},
        -- Row 2: 3 cards centered
        {row = 1, col = 0, totalInRow = 3},
        {row = 1, col = 1, totalInRow = 3},
        {row = 1, col = 2, totalInRow = 3},
    }

    for i, proto in ipairs(self.mPrototypes) do
        if gridPositions[i] then
            local pos = gridPositions[i]
            local rowWidth = pos.totalInRow * cardWidth + (pos.totalInRow - 1) * spacingX
            local rowStartX = (screenW - rowWidth) / 2
            local x = rowStartX + pos.col * (cardWidth + spacingX)
            local y = startY + pos.row * (cardHeight + spacingY)

            if mx >= x and mx <= x + cardWidth and
               my >= y and my <= y + cardHeight then
                self.mHoveredIndex = i
            end
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
    love.graphics.setFont(self.mFonts.title)
    local title = "CraveTown - Select Prototype"
    local titleWidth = self.mFonts.title:getWidth(title)
    love.graphics.print(title, (screenW - titleWidth) / 2, 50)

    -- Grid layout cards
    local cardWidth = 340
    local cardHeight = 130
    local spacingX = 30
    local spacingY = 25
    local startY = 150

    -- Grid layout: 2 cards in row 1, 3 cards in row 2
    local gridPositions = {
        {row = 0, col = 0, totalInRow = 2},
        {row = 0, col = 1, totalInRow = 2},
        {row = 1, col = 0, totalInRow = 3},
        {row = 1, col = 1, totalInRow = 3},
        {row = 1, col = 2, totalInRow = 3},
    }

    for i, proto in ipairs(self.mPrototypes) do
        if gridPositions[i] then
            local pos = gridPositions[i]
            local rowWidth = pos.totalInRow * cardWidth + (pos.totalInRow - 1) * spacingX
            local rowStartX = (screenW - rowWidth) / 2
            local x = rowStartX + pos.col * (cardWidth + spacingX)
            local y = startY + pos.row * (cardHeight + spacingY)
            local isHovered = (self.mHoveredIndex == i)

            -- Card background
            if isHovered then
                love.graphics.setColor(proto.color[1] * 0.9, proto.color[2] * 0.9, proto.color[3] * 0.9)
            else
                love.graphics.setColor(proto.color[1] * 0.7, proto.color[2] * 0.7, proto.color[3] * 0.7)
            end
            love.graphics.rectangle("fill", x, y, cardWidth, cardHeight, 10, 10)

            -- Card border
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.setLineWidth(isHovered and 3 or 2)
            love.graphics.rectangle("line", x, y, cardWidth, cardHeight, 10, 10)

            -- Card content
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(self.mFonts.cardTitle)
            -- Truncate name if too long for card
            local displayName = proto.name
            if #displayName > 28 then displayName = displayName:sub(1, 25) .. "..." end
            love.graphics.print(displayName, x + 15, y + 15)

            love.graphics.setColor(0.95, 0.95, 0.95)
            love.graphics.setFont(self.mFonts.cardDesc)
            love.graphics.printf(proto.description, x + 15, y + 50, cardWidth - 30)

            -- Hover instruction
            if isHovered then
                love.graphics.setColor(1, 1, 1)
                love.graphics.setFont(self.mFonts.hover)
                love.graphics.print("Click to launch", x + 15, y + cardHeight - 30)
            end
        end
    end

    -- Footer
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setFont(self.mFonts.footer)
    local footer = "Press ESC to quit"
    love.graphics.print(footer, 20, screenH - 30)

    love.graphics.setColor(1, 1, 1)
end

function PrototypeLauncher:GetSelectedPrototype()
    return self.mSelectedPrototype
end

return PrototypeLauncher
