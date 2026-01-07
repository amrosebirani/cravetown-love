--
-- TownSelectionScreen - UI for selecting specialty starting town
--

TownSelectionScreen = {}
TownSelectionScreen.__index = TownSelectionScreen

function TownSelectionScreen:Create(townsData)
    local this = {
        mTowns = townsData or {},
        mHoveredIndex = nil,
        mSelectedTownId = nil,
        -- Create fonts once to avoid memory leak
        mFonts = {
            title = love.graphics.newFont(42),
            cardTitle = love.graphics.newFont(20),
            cardSubtitle = love.graphics.newFont(14),
            cardDesc = love.graphics.newFont(12),
            difficulty = love.graphics.newFont(14),
            hover = love.graphics.newFont(14),
            footer = love.graphics.newFont(14)
        }
    }

    setmetatable(this, self)
    return this
end

function TownSelectionScreen:Update(dt)
    -- Check mouse hover
    local mx, my = love.mouse.getPosition()
    self.mHoveredIndex = nil

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Grid layout: 2x2
    local cardWidth = 450
    local cardHeight = 200
    local spacingX = 40
    local spacingY = 30
    local cols = 2
    local rows = math.ceil(#self.mTowns / cols)

    local totalWidth = (cols * cardWidth) + ((cols - 1) * spacingX)
    local totalHeight = (rows * cardHeight) + ((rows - 1) * spacingY)
    local startX = (screenW - totalWidth) / 2
    local startY = 180  -- Below title

    for i, town in ipairs(self.mTowns) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local x = startX + col * (cardWidth + spacingX)
        local y = startY + row * (cardHeight + spacingY)

        if mx >= x and mx <= x + cardWidth and
           my >= y and my <= y + cardHeight then
            self.mHoveredIndex = i
        end
    end

    -- Check for click
    if gMousePressed and gMousePressed.button == 1 and self.mHoveredIndex then
        self.mSelectedTownId = self.mTowns[self.mHoveredIndex].id
        return true  -- Signal selection made
    end

    return false
end

function TownSelectionScreen:Render()
    love.graphics.clear(0.12, 0.12, 0.15)  -- Dark background

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Title
    love.graphics.setColor(1, 0.9, 0.6)
    love.graphics.setFont(self.mFonts.title)
    local title = "Select Your Specialty Town"
    local titleWidth = self.mFonts.title:getWidth(title)
    love.graphics.print(title, (screenW - titleWidth) / 2, 60)

    -- Subtitle
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.setFont(self.mFonts.cardSubtitle)
    local subtitle = "Each town specializes in a unique Indian street food"
    local subtitleWidth = self.mFonts.cardSubtitle:getWidth(subtitle)
    love.graphics.print(subtitle, (screenW - subtitleWidth) / 2, 115)

    -- Town cards in 2x2 grid
    local cardWidth = 450
    local cardHeight = 200
    local spacingX = 40
    local spacingY = 30
    local cols = 2
    local rows = math.ceil(#self.mTowns / cols)

    local totalWidth = (cols * cardWidth) + ((cols - 1) * spacingX)
    local startX = (screenW - totalWidth) / 2
    local startY = 180

    -- Difficulty colors
    local difficultyColors = {
        easy = {0.4, 0.8, 0.4},
        medium = {0.9, 0.7, 0.3},
        hard = {0.9, 0.3, 0.3}
    }

    for i, town in ipairs(self.mTowns) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local x = startX + col * (cardWidth + spacingX)
        local y = startY + row * (cardHeight + spacingY)
        local isHovered = (self.mHoveredIndex == i)

        -- Card background with gradient effect
        if isHovered then
            love.graphics.setColor(0.25, 0.25, 0.28)
        else
            love.graphics.setColor(0.18, 0.18, 0.21)
        end
        love.graphics.rectangle("fill", x, y, cardWidth, cardHeight, 8, 8)

        -- Card border
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.setLineWidth(isHovered and 3 or 1.5)
        love.graphics.rectangle("line", x, y, cardWidth, cardHeight, 8, 8)

        -- Difficulty badge
        local diffColor = difficultyColors[town.difficulty] or {0.6, 0.6, 0.6}
        love.graphics.setColor(diffColor[1], diffColor[2], diffColor[3])
        local badgeWidth = 80
        local badgeHeight = 24
        love.graphics.rectangle("fill", x + cardWidth - badgeWidth - 10, y + 10, badgeWidth, badgeHeight, 4, 4)

        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.mFonts.difficulty)
        local diffText = town.difficulty:upper()
        local diffTextWidth = self.mFonts.difficulty:getWidth(diffText)
        love.graphics.print(diffText, x + cardWidth - badgeWidth - 10 + (badgeWidth - diffTextWidth) / 2, y + 13)

        -- Town name (city)
        love.graphics.setColor(1, 0.95, 0.7)
        love.graphics.setFont(self.mFonts.cardTitle)
        love.graphics.print(town.city, x + 15, y + 15)

        -- Specialty
        love.graphics.setColor(0.9, 0.9, 0.9)
        love.graphics.setFont(self.mFonts.cardSubtitle)
        local specialtyText = "Specialty: " .. town.name
        love.graphics.print(specialtyText, x + 15, y + 42)

        -- Description (truncated)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.setFont(self.mFonts.cardDesc)
        local desc = town.description
        if #desc > 280 then
            desc = desc:sub(1, 280) .. "..."
        end
        love.graphics.printf(desc, x + 15, y + 70, cardWidth - 30)

        -- Hover instruction
        if isHovered then
            love.graphics.setColor(1, 1, 0.6)
            love.graphics.setFont(self.mFonts.hover)
            love.graphics.print("Click to select this town", x + 15, y + cardHeight - 30)
        end
    end

    -- Footer
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.setFont(self.mFonts.footer)
    local footer = "Press ESC to return to launcher"
    love.graphics.print(footer, 20, screenH - 30)

    love.graphics.setColor(1, 1, 1)
end

function TownSelectionScreen:GetSelectedTownId()
    return self.mSelectedTownId
end

return TownSelectionScreen
