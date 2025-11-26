--
-- VersionSelector - Version selection screen shown at startup
--

require("code/DataLoader")

VersionSelector = {}
VersionSelector.__index = VersionSelector

function VersionSelector:Create()
    local this = {
        mVersions = {},
        mActiveVersionId = "base",
        mHoveredIndex = nil,
        mSelectedVersion = nil,
        mScrollOffset = 0,
        mMaxScroll = 0
    }

    -- Load versions from manifest
    local success, manifest = pcall(function()
        return DataLoader.loadVersionsManifest()
    end)

    if success and manifest then
        this.mVersions = manifest.versions or {}
        this.mActiveVersionId = manifest.activeVersion or "base"
        print("VersionSelector: Loaded " .. #this.mVersions .. " versions")
        print("VersionSelector: Active version: " .. this.mActiveVersionId)
    else
        print("VersionSelector: Failed to load versions manifest, defaulting to base")
        -- Create a default base version entry
        this.mVersions = {
            {
                id = "base",
                name = "Base Game",
                description = "Default game data",
                author = "Cravetown Team",
                version = "1.0.0",
                active = true
            }
        }
    end

    setmetatable(this, self)
    return this
end

function VersionSelector:Update(dt)
    -- Check mouse hover
    local mx, my = love.mouse.getPosition()
    self.mHoveredIndex = nil

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local cardWidth = 500
    local cardHeight = 120
    local spacing = 20
    local startX = (screenW - cardWidth) / 2
    local startY = 180

    -- Calculate visible area
    local visibleHeight = screenH - startY - 100
    local maxVisibleCards = math.floor(visibleHeight / (cardHeight + spacing))

    for i, version in ipairs(self.mVersions) do
        local y = startY + (i - 1) * (cardHeight + spacing) - self.mScrollOffset

        -- Only check hover for visible cards
        if y >= startY - cardHeight and y <= screenH then
            if mx >= startX and mx <= startX + cardWidth and
               my >= y and my <= y + cardHeight then
                self.mHoveredIndex = i
            end
        end
    end

    -- Check for click
    if gMousePressed and gMousePressed.button == 1 and self.mHoveredIndex then
        self.mSelectedVersion = self.mVersions[self.mHoveredIndex].id
        -- Set the active version in DataLoader
        DataLoader.setActiveVersion(self.mSelectedVersion)
        return true  -- Signal version selected
    end

    return false
end

function VersionSelector:OnMouseWheel(dx, dy)
    local screenH = love.graphics.getHeight()
    local cardHeight = 120
    local spacing = 20
    local startY = 180
    local visibleHeight = screenH - startY - 100

    -- Calculate max scroll
    local totalHeight = #self.mVersions * (cardHeight + spacing)
    self.mMaxScroll = math.max(0, totalHeight - visibleHeight)

    -- Scroll with mouse wheel
    self.mScrollOffset = self.mScrollOffset - (dy * 50)
    self.mScrollOffset = math.max(0, math.min(self.mScrollOffset, self.mMaxScroll))
end

function VersionSelector:Render()
    love.graphics.clear(0.95, 0.95, 0.95)

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Title
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.setNewFont(48)
    local title = "Select Game Version"
    local titleWidth = love.graphics.getFont():getWidth(title)
    love.graphics.print(title, (screenW - titleWidth) / 2, 50)

    -- Subtitle
    love.graphics.setNewFont(18)
    love.graphics.setColor(0.4, 0.4, 0.4)
    local subtitle = "Choose which version/mod to play"
    local subtitleWidth = love.graphics.getFont():getWidth(subtitle)
    love.graphics.print(subtitle, (screenW - subtitleWidth) / 2, 110)

    -- Version cards
    local cardWidth = 500
    local cardHeight = 120
    local spacing = 20
    local startY = 180
    local startX = (screenW - cardWidth) / 2

    -- Create scissor for scrollable area
    local visibleHeight = screenH - startY - 100
    love.graphics.setScissor(startX, startY, cardWidth, visibleHeight)

    for i, version in ipairs(self.mVersions) do
        local y = startY + (i - 1) * (cardHeight + spacing) - self.mScrollOffset
        local isHovered = (self.mHoveredIndex == i)
        local isActive = (version.id == self.mActiveVersionId)

        -- Only render visible cards
        if y >= startY - cardHeight and y <= screenH then
            -- Card background
            if isActive then
                love.graphics.setColor(0.3, 0.7, 0.3)  -- Green for active
            elseif isHovered then
                love.graphics.setColor(0.4, 0.6, 0.9)  -- Light blue for hover
            else
                love.graphics.setColor(0.5, 0.5, 0.6)  -- Gray for inactive
            end
            love.graphics.rectangle("fill", startX, y, cardWidth, cardHeight, 10, 10)

            -- Card border
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", startX, y, cardWidth, cardHeight, 10, 10)

            -- Active badge
            if isActive then
                love.graphics.setColor(0.2, 0.9, 0.2)
                love.graphics.setNewFont(14)
                love.graphics.print("● ACTIVE", startX + cardWidth - 80, y + 10)
            end

            -- Version name
            love.graphics.setColor(1, 1, 1)
            love.graphics.setNewFont(24)
            love.graphics.print(version.name, startX + 20, y + 15)

            -- Version ID and version number
            love.graphics.setNewFont(14)
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.print("ID: " .. version.id .. " | v" .. (version.version or "1.0.0"), startX + 20, y + 45)

            -- Description
            love.graphics.setNewFont(14)
            love.graphics.setColor(0.95, 0.95, 0.95)
            local desc = version.description or "No description"
            if #desc > 60 then
                desc = desc:sub(1, 57) .. "..."
            end
            love.graphics.print(desc, startX + 20, y + 68)

            -- Author
            love.graphics.setNewFont(12)
            love.graphics.setColor(0.85, 0.85, 0.85)
            love.graphics.print("by " .. (version.author or "Unknown"), startX + 20, y + 92)
        end
    end

    -- Remove scissor
    love.graphics.setScissor()

    -- Scroll indicator
    if self.mMaxScroll > 0 then
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.setNewFont(14)
        love.graphics.print("Scroll with mouse wheel", screenW / 2 - 80, screenH - 40)

        -- Scrollbar
        local scrollbarX = startX + cardWidth + 20
        local scrollbarY = startY
        local scrollbarHeight = visibleHeight
        local scrollbarWidth = 8

        -- Background
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.rectangle("fill", scrollbarX, scrollbarY, scrollbarWidth, scrollbarHeight, 4, 4)

        -- Thumb
        local thumbHeight = math.max(30, scrollbarHeight * (visibleHeight / (visibleHeight + self.mMaxScroll)))
        local thumbY = scrollbarY + (self.mScrollOffset / self.mMaxScroll) * (scrollbarHeight - thumbHeight)
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", scrollbarX, thumbY, scrollbarWidth, thumbHeight, 4, 4)
    end

    -- Instructions
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setNewFont(14)
    local instructions = "Click a version to select and continue | ESC to quit"
    local instrWidth = love.graphics.getFont():getWidth(instructions)
    love.graphics.print(instructions, (screenW - instrWidth) / 2, screenH - 60)

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function VersionSelector:GetSelectedVersion()
    return self.mSelectedVersion
end

return VersionSelector
