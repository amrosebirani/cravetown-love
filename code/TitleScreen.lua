--
-- TitleScreen.lua
-- Main menu / title screen for CraveTown Alpha
-- Following game_ui_flow_specification.md Section 3.1
--

TitleScreen = {}
TitleScreen.__index = TitleScreen

function TitleScreen:Create(callbacks)
    local screen = setmetatable({}, TitleScreen)

    screen.callbacks = callbacks or {}

    -- Animation state
    screen.titleAlpha = 0
    screen.titleScale = 1.2
    screen.menuAlpha = 0
    screen.animTimer = 0
    screen.animPhase = "title_in" -- title_in, menu_in, ready

    -- Fonts
    screen.fonts = {
        title = love.graphics.newFont(48),
        subtitle = love.graphics.newFont(18),
        menu = love.graphics.newFont(20),
        version = love.graphics.newFont(12)
    }

    -- Menu items
    screen.menuItems = {
        {id = "new_game", label = "NEW GAME", enabled = true},
        {id = "continue", label = "CONTINUE", enabled = false}, -- Enabled if save exists
        {id = "load_game", label = "LOAD GAME", enabled = true},
        {id = "settings", label = "SETTINGS", enabled = true},
        {id = "credits", label = "CREDITS", enabled = true},
        {id = "quit", label = "QUIT", enabled = true}
    }

    screen.selectedIndex = 1
    screen.hoveredIndex = nil

    -- Colors
    screen.colors = {
        background = {0.08, 0.08, 0.12},
        title = {0.85, 0.7, 0.3},
        subtitle = {0.7, 0.7, 0.75},
        menuNormal = {0.8, 0.8, 0.85},
        menuHover = {1.0, 0.9, 0.5},
        menuDisabled = {0.4, 0.4, 0.45},
        menuSelected = {0.4, 0.7, 1.0},
        version = {0.5, 0.5, 0.55}
    }

    -- Check for existing save to enable Continue
    screen:CheckForSaveGame()

    return screen
end

function TitleScreen:CheckForSaveGame()
    -- Check if quicksave or any save slot exists
    local saveDir = love.filesystem.getSaveDirectory()
    local hasSave = love.filesystem.getInfo("quicksave.json") ~= nil

    -- Also check save slots
    for i = 1, 5 do
        if love.filesystem.getInfo("save_slot_" .. i .. ".json") then
            hasSave = true
            break
        end
    end

    -- Enable/disable continue button
    self.menuItems[2].enabled = hasSave
end

function TitleScreen:Update(dt)
    self.animTimer = self.animTimer + dt

    if self.animPhase == "title_in" then
        -- Fade in title over 1 second
        self.titleAlpha = math.min(1, self.animTimer / 1.0)
        self.titleScale = 1.2 - 0.2 * math.min(1, self.animTimer / 1.0)

        if self.animTimer >= 1.2 then
            self.animPhase = "menu_in"
            self.animTimer = 0
        end

    elseif self.animPhase == "menu_in" then
        -- Fade in menu over 0.5 seconds
        self.menuAlpha = math.min(1, self.animTimer / 0.5)

        if self.animTimer >= 0.5 then
            self.animPhase = "ready"
        end
    end

    -- Update hovered item based on mouse position
    local mx, my = love.mouse.getPosition()
    self:UpdateHover(mx, my)

    return false -- not done
end

function TitleScreen:UpdateHover(mx, my)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local menuY = screenH * 0.45
    local itemHeight = 45

    self.hoveredIndex = nil

    for i, item in ipairs(self.menuItems) do
        local itemY = menuY + (i - 1) * itemHeight
        local itemW = 200
        local itemX = (screenW - itemW) / 2

        if mx >= itemX and mx <= itemX + itemW and
           my >= itemY and my <= itemY + 35 then
            if item.enabled then
                self.hoveredIndex = i
            end
            break
        end
    end
end

function TitleScreen:Render()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Background
    love.graphics.setColor(self.colors.background)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Decorative elements (subtle town silhouette at bottom)
    self:RenderBackground(screenW, screenH)

    -- Title
    love.graphics.setFont(self.fonts.title)
    local titleText = "CRAVETOWN"
    local titleW = self.fonts.title:getWidth(titleText)

    local r, g, b = unpack(self.colors.title)
    love.graphics.setColor(r, g, b, self.titleAlpha)

    love.graphics.push()
    love.graphics.translate(screenW / 2, screenH * 0.2)
    love.graphics.scale(self.titleScale, self.titleScale)
    love.graphics.print(titleText, -titleW / 2, 0)
    love.graphics.pop()

    -- Subtitle
    love.graphics.setFont(self.fonts.subtitle)
    local subtitleText = '"Build a Town That Satisfies"'
    local subtitleW = self.fonts.subtitle:getWidth(subtitleText)
    r, g, b = unpack(self.colors.subtitle)
    love.graphics.setColor(r, g, b, self.titleAlpha * 0.8)
    love.graphics.print(subtitleText, (screenW - subtitleW) / 2, screenH * 0.28)

    -- Menu items
    if self.menuAlpha > 0 then
        self:RenderMenu(screenW, screenH)
    end

    -- Version
    love.graphics.setFont(self.fonts.version)
    local versionText = "v0.1.0 Alpha - Birthday Edition"
    local versionW = self.fonts.version:getWidth(versionText)
    r, g, b = unpack(self.colors.version)
    love.graphics.setColor(r, g, b, self.menuAlpha)
    love.graphics.print(versionText, (screenW - versionW) / 2, screenH - 30)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function TitleScreen:RenderBackground(screenW, screenH)
    -- Subtle decorative buildings silhouette at bottom
    love.graphics.setColor(0.12, 0.12, 0.16, 0.5)

    local groundY = screenH - 60

    -- Simple building silhouettes
    local buildings = {
        {x = 50, w = 40, h = 80},
        {x = 100, w = 60, h = 120},
        {x = 170, w = 35, h = 65},
        {x = 220, w = 50, h = 95},
        {x = screenW - 250, w = 45, h = 85},
        {x = screenW - 190, w = 70, h = 130},
        {x = screenW - 110, w = 40, h = 70},
        {x = screenW - 60, w = 55, h = 100}
    }

    for _, b in ipairs(buildings) do
        love.graphics.rectangle("fill", b.x, groundY - b.h, b.w, b.h)
    end

    -- Ground line
    love.graphics.setColor(0.15, 0.15, 0.2, 0.8)
    love.graphics.rectangle("fill", 0, groundY, screenW, 60)
end

function TitleScreen:RenderMenu(screenW, screenH)
    love.graphics.setFont(self.fonts.menu)
    local menuY = screenH * 0.45
    local itemHeight = 45

    for i, item in ipairs(self.menuItems) do
        local itemY = menuY + (i - 1) * itemHeight
        local text = item.label
        local textW = self.fonts.menu:getWidth(text)
        local textX = (screenW - textW) / 2

        local r, g, b
        local alpha = self.menuAlpha

        if not item.enabled then
            r, g, b = unpack(self.colors.menuDisabled)
        elseif i == self.hoveredIndex then
            r, g, b = unpack(self.colors.menuHover)
            -- Draw highlight background
            love.graphics.setColor(1, 1, 1, 0.1 * alpha)
            love.graphics.rectangle("fill", textX - 20, itemY - 5, textW + 40, 35, 5, 5)
        elseif i == self.selectedIndex then
            r, g, b = unpack(self.colors.menuSelected)
        else
            r, g, b = unpack(self.colors.menuNormal)
        end

        love.graphics.setColor(r, g, b, alpha)
        love.graphics.print(text, textX, itemY)

        -- Selection indicator
        if i == self.selectedIndex and item.enabled then
            love.graphics.print(">", textX - 25, itemY)
            love.graphics.print("<", textX + textW + 10, itemY)
        end
    end
end

function TitleScreen:HandleKeyPress(key)
    if self.animPhase ~= "ready" then
        -- Skip animation
        self.titleAlpha = 1
        self.titleScale = 1
        self.menuAlpha = 1
        self.animPhase = "ready"
        return true
    end

    if key == "up" or key == "w" then
        self:MoveCursor(-1)
        return true
    elseif key == "down" or key == "s" then
        self:MoveCursor(1)
        return true
    elseif key == "return" or key == "space" then
        self:SelectCurrentItem()
        return true
    end

    return false
end

function TitleScreen:MoveCursor(direction)
    local newIndex = self.selectedIndex + direction

    -- Wrap around
    if newIndex < 1 then
        newIndex = #self.menuItems
    elseif newIndex > #self.menuItems then
        newIndex = 1
    end

    -- Skip disabled items
    local attempts = 0
    while not self.menuItems[newIndex].enabled and attempts < #self.menuItems do
        newIndex = newIndex + direction
        if newIndex < 1 then newIndex = #self.menuItems end
        if newIndex > #self.menuItems then newIndex = 1 end
        attempts = attempts + 1
    end

    self.selectedIndex = newIndex
end

function TitleScreen:SelectCurrentItem()
    local item = self.menuItems[self.selectedIndex]
    if not item.enabled then return end

    self:TriggerCallback(item.id)
end

function TitleScreen:HandleClick(x, y, button)
    if button ~= 1 then return false end

    if self.animPhase ~= "ready" then
        -- Skip animation
        self.titleAlpha = 1
        self.titleScale = 1
        self.menuAlpha = 1
        self.animPhase = "ready"
        return true
    end

    if self.hoveredIndex then
        local item = self.menuItems[self.hoveredIndex]
        if item.enabled then
            self.selectedIndex = self.hoveredIndex
            self:TriggerCallback(item.id)
            return true
        end
    end

    return false
end

function TitleScreen:TriggerCallback(itemId)
    if self.callbacks[itemId] then
        self.callbacks[itemId]()
    elseif self.callbacks.onSelect then
        self.callbacks.onSelect(itemId)
    end
end

return TitleScreen
