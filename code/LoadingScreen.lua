--
-- LoadingScreen.lua
-- Displays loading progress with a bar and status text during game initialization
--

local LoadingScreen = {}
LoadingScreen.__index = LoadingScreen

function LoadingScreen:Create()
    local screen = setmetatable({}, LoadingScreen)

    screen.progress = 0          -- 0.0 to 1.0
    screen.statusText = "Initializing..."
    screen.subText = ""          -- Secondary text (e.g., "Building 3 of 10")
    screen.visible = false

    -- Visual settings
    screen.barWidth = 400
    screen.barHeight = 24
    screen.backgroundColor = {0.08, 0.08, 0.12, 1}
    screen.barBackgroundColor = {0.15, 0.15, 0.2, 1}
    screen.barFillColor = {0.3, 0.6, 0.9, 1}
    screen.barBorderColor = {0.4, 0.5, 0.6, 1}
    screen.textColor = {0.9, 0.9, 0.9, 1}
    screen.subTextColor = {0.6, 0.6, 0.7, 1}

    -- Animation
    screen.animatedProgress = 0
    screen.pulseTime = 0

    return screen
end

function LoadingScreen:Show()
    self.visible = true
    self.progress = 0
    self.animatedProgress = 0
    self.statusText = "Initializing..."
    self.subText = ""
end

function LoadingScreen:Hide()
    self.visible = false
end

function LoadingScreen:SetProgress(progress, statusText, subText)
    self.progress = math.max(0, math.min(1, progress))
    if statusText then
        self.statusText = statusText
    end
    if subText then
        self.subText = subText
    else
        self.subText = ""
    end
end

function LoadingScreen:Update(dt)
    if not self.visible then return end

    -- Smooth animation toward target progress
    local diff = self.progress - self.animatedProgress
    self.animatedProgress = self.animatedProgress + diff * math.min(1, dt * 8)

    -- Pulse animation
    self.pulseTime = self.pulseTime + dt
end

function LoadingScreen:Render()
    if not self.visible then return end

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Full screen background
    love.graphics.setColor(self.backgroundColor)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Title
    local titleFont = love.graphics.newFont(28)
    love.graphics.setFont(titleFont)
    love.graphics.setColor(0.9, 0.85, 0.7, 1)
    local title = "Loading World"
    local titleW = titleFont:getWidth(title)
    love.graphics.print(title, (screenW - titleW) / 2, screenH / 2 - 80)

    -- Progress bar position
    local barX = (screenW - self.barWidth) / 2
    local barY = screenH / 2

    -- Bar background
    love.graphics.setColor(self.barBackgroundColor)
    love.graphics.rectangle("fill", barX, barY, self.barWidth, self.barHeight, 4, 4)

    -- Bar fill with pulse effect
    local pulse = 0.05 * math.sin(self.pulseTime * 4)
    local r, g, b = self.barFillColor[1], self.barFillColor[2], self.barFillColor[3]
    love.graphics.setColor(r + pulse, g + pulse, b + pulse, 1)

    local fillWidth = self.animatedProgress * self.barWidth
    if fillWidth > 0 then
        love.graphics.rectangle("fill", barX, barY, fillWidth, self.barHeight, 4, 4)
    end

    -- Bar border
    love.graphics.setColor(self.barBorderColor)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", barX, barY, self.barWidth, self.barHeight, 4, 4)

    -- Percentage text on bar
    local percentFont = love.graphics.newFont(12)
    love.graphics.setFont(percentFont)
    love.graphics.setColor(1, 1, 1, 0.9)
    local percentText = string.format("%.0f%%", self.animatedProgress * 100)
    local percentW = percentFont:getWidth(percentText)
    love.graphics.print(percentText, barX + (self.barWidth - percentW) / 2, barY + 5)

    -- Status text below bar
    local statusFont = love.graphics.newFont(14)
    love.graphics.setFont(statusFont)
    love.graphics.setColor(self.textColor)
    local statusW = statusFont:getWidth(self.statusText)
    love.graphics.print(self.statusText, (screenW - statusW) / 2, barY + self.barHeight + 15)

    -- Sub-text (smaller, dimmer)
    if self.subText and self.subText ~= "" then
        local subFont = love.graphics.newFont(11)
        love.graphics.setFont(subFont)
        love.graphics.setColor(self.subTextColor)
        local subW = subFont:getWidth(self.subText)
        love.graphics.print(self.subText, (screenW - subW) / 2, barY + self.barHeight + 35)
    end

    -- Loading dots animation
    local dots = string.rep(".", math.floor(self.pulseTime * 2) % 4)
    love.graphics.setColor(0.5, 0.5, 0.6, 1)
    love.graphics.print(dots, (screenW + statusW) / 2 + 5, barY + self.barHeight + 15)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return LoadingScreen
