--
-- NotificationSystem.lua
-- Toast notification system for CraveTown Alpha
--
-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │                        NOTIFICATION SYSTEM                                 │
-- ├────────────────────────────────────────────────────────────────────────────┤
-- │                                                                            │
-- │   Toast Notifications (top-right corner):                                  │
-- │   ┌─────────────────────────────────────────────┐                         │
-- │   │ ⚠  CRITICAL: Food shortage imminent!       │ ← Auto-pause option      │
-- │   │    Only 2 cycles of bread remaining        │                          │
-- │   │    [View Inventory] [Dismiss]              │                          │
-- │   └─────────────────────────────────────────────┘                         │
-- │                                                                            │
-- │   ┌─────────────────────────────────────────────┐                         │
-- │   │ ⚡ WARNING: Citizen unhappy                 │                          │
-- │   │    Maria is at 25% satisfaction            │                          │
-- │   │    [View Citizen]                          │                          │
-- │   └─────────────────────────────────────────────┘                         │
-- │                                                                            │
-- │   ┌─────────────────────────────────────────────┐                         │
-- │   │ ✓  SUCCESS: New immigrant arrived          │                          │
-- │   │    John has joined the town                │                          │
-- │   └─────────────────────────────────────────────┘                         │
-- │                                                                            │
-- │   ┌─────────────────────────────────────────────┐                         │
-- │   │ ℹ  INFO: Production complete               │                          │
-- │   │    Farm produced 5 wheat                   │                          │
-- │   └─────────────────────────────────────────────┘                         │
-- │                                                                            │
-- │   Notification Types:                                                      │
-- │   - CRITICAL (red)    : Food shortage, mass emigration, riots             │
-- │   - WARNING (orange)  : Low satisfaction, understaffed building           │
-- │   - INFO (blue)       : Production complete, new day                      │
-- │   - SUCCESS (green)   : Immigration, building complete                    │
-- │                                                                            │
-- │   Features:                                                                │
-- │   - Auto-pause on critical events (configurable)                          │
-- │   - Stacking with animation                                                │
-- │   - Action buttons for quick navigation                                   │
-- │   - Auto-dismiss timer (5s default, longer for critical)                  │
-- │   - Click to dismiss                                                       │
-- │                                                                            │
-- └────────────────────────────────────────────────────────────────────────────┘
--

local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

-- Notification types
NotificationSystem.TYPES = {
    CRITICAL = "critical",
    WARNING = "warning",
    INFO = "info",
    SUCCESS = "success"
}

function NotificationSystem:Create(world)
    local system = setmetatable({}, NotificationSystem)

    system.world = world
    system.notifications = {}
    system.maxVisible = 5
    system.notificationIdCounter = 0

    -- Settings (can be overridden by GameSettings)
    system.autoPauseOnCritical = true
    system.enabled = true
    system.soundEnabled = true

    -- Animation settings
    system.slideInDuration = 0.3
    system.fadeOutDuration = 0.5

    -- Display settings
    system.toastWidth = 320
    system.toastPadding = 12
    system.toastSpacing = 10
    system.cornerMargin = 20

    -- Colors
    system.colors = {
        critical = {0.93, 0.27, 0.27, 0.95},     -- #ef4444
        warning = {0.98, 0.57, 0.24, 0.95},      -- #fb923c
        info = {0.38, 0.65, 0.98, 0.95},         -- #60a5fa
        success = {0.29, 0.87, 0.50, 0.95},      -- #4ade80
        background = {0.1, 0.1, 0.12, 0.95},
        text = {1, 1, 1, 1},
        textDim = {0.8, 0.8, 0.8, 1},
        buttonBg = {0.2, 0.2, 0.25, 1},
        buttonHover = {0.3, 0.3, 0.35, 1}
    }

    -- Icons (using text symbols)
    system.icons = {
        critical = "!",
        warning = "!",
        info = "i",
        success = "+"
    }

    -- Default durations by type
    system.durations = {
        critical = 10.0,   -- Critical stays longer
        warning = 7.0,
        info = 5.0,
        success = 4.0
    }

    -- Fonts (will be set on first render)
    system.fonts = nil

    return system
end

function NotificationSystem:InitFonts()
    if not self.fonts then
        self.fonts = {
            title = love.graphics.newFont(13),
            body = love.graphics.newFont(11),
            icon = love.graphics.newFont(16),
            button = love.graphics.newFont(10)
        }
    end
end

-- =============================================================================
-- NOTIFICATION CREATION
-- =============================================================================

function NotificationSystem:Notify(type, title, message, options)
    if not self.enabled then return nil end

    options = options or {}

    self.notificationIdCounter = self.notificationIdCounter + 1
    local id = self.notificationIdCounter

    local notification = {
        id = id,
        type = type or self.TYPES.INFO,
        title = title or "Notification",
        message = message or "",

        -- Optional action button
        actionLabel = options.actionLabel,
        actionCallback = options.actionCallback,

        -- Timing
        duration = options.duration or self.durations[type] or 5.0,
        createdAt = love.timer.getTime(),
        remainingTime = options.duration or self.durations[type] or 5.0,

        -- Animation state
        slideProgress = 0,  -- 0 to 1 (slide in from right)
        fadeProgress = 1,   -- 1 to 0 (fade out)
        targetY = 0,        -- Target Y position (for stacking animation)
        currentY = 0,       -- Current Y position

        -- State
        dismissed = false,
        hovered = false
    }

    -- Add to front of list (newest at top)
    table.insert(self.notifications, 1, notification)

    -- Limit visible notifications
    while #self.notifications > self.maxVisible + 2 do
        table.remove(self.notifications)
    end

    -- Auto-pause on critical if enabled
    if type == self.TYPES.CRITICAL and self.autoPauseOnCritical then
        if self.world and not self.world.isPaused then
            self.world.isPaused = true
            -- Add a note that we paused
            notification.autoPaused = true
        end
    end

    -- Play sound
    if self.soundEnabled then
        self:PlayNotificationSound(type)
    end

    return id
end

-- Convenience methods
function NotificationSystem:Critical(title, message, options)
    return self:Notify(self.TYPES.CRITICAL, title, message, options)
end

function NotificationSystem:Warning(title, message, options)
    return self:Notify(self.TYPES.WARNING, title, message, options)
end

function NotificationSystem:Info(title, message, options)
    return self:Notify(self.TYPES.INFO, title, message, options)
end

function NotificationSystem:Success(title, message, options)
    return self:Notify(self.TYPES.SUCCESS, title, message, options)
end

-- =============================================================================
-- UPDATE
-- =============================================================================

function NotificationSystem:Update(dt)
    local screenW = love.graphics.getWidth()
    local baseY = self.cornerMargin + 50  -- Below top bar

    -- Calculate target Y positions for stacking
    local currentY = baseY
    for i, notif in ipairs(self.notifications) do
        if not notif.dismissed and i <= self.maxVisible then
            notif.targetY = currentY
            currentY = currentY + self:GetNotificationHeight(notif) + self.toastSpacing
        end
    end

    -- Update each notification
    for i = #self.notifications, 1, -1 do
        local notif = self.notifications[i]

        -- Slide in animation
        if notif.slideProgress < 1 then
            notif.slideProgress = math.min(1, notif.slideProgress + dt / self.slideInDuration)
        end

        -- Smooth Y position animation
        local yDiff = notif.targetY - notif.currentY
        notif.currentY = notif.currentY + yDiff * math.min(1, dt * 10)

        -- Timer countdown (pause if hovered)
        if not notif.hovered and not notif.dismissed then
            notif.remainingTime = notif.remainingTime - dt

            if notif.remainingTime <= 0 then
                notif.dismissed = true
            end
        end

        -- Fade out animation
        if notif.dismissed then
            notif.fadeProgress = notif.fadeProgress - dt / self.fadeOutDuration

            if notif.fadeProgress <= 0 then
                table.remove(self.notifications, i)
            end
        end
    end
end

function NotificationSystem:GetNotificationHeight(notif)
    self:InitFonts()

    local height = self.toastPadding * 2  -- Top and bottom padding
    height = height + self.fonts.title:getHeight()  -- Title
    height = height + 4  -- Spacing

    -- Message (may wrap)
    if notif.message and notif.message ~= "" then
        local maxWidth = self.toastWidth - self.toastPadding * 2 - 30  -- Account for icon
        local _, wrappedText = self.fonts.body:getWrap(notif.message, maxWidth)
        height = height + #wrappedText * self.fonts.body:getHeight()
    end

    -- Action button
    if notif.actionLabel then
        height = height + 8 + 24  -- Spacing + button height
    end

    return math.max(60, height)
end

-- =============================================================================
-- RENDERING
-- =============================================================================

function NotificationSystem:Render()
    if not self.enabled then return end

    self:InitFonts()

    local screenW = love.graphics.getWidth()
    local mx, my = love.mouse.getPosition()

    -- Render from bottom to top (so newest is on top visually)
    for i = #self.notifications, 1, -1 do
        local notif = self.notifications[i]

        if i <= self.maxVisible or notif.dismissed then
            self:RenderNotification(notif, screenW, mx, my)
        end
    end
end

function NotificationSystem:RenderNotification(notif, screenW, mx, my)
    local toastW = self.toastWidth
    local toastH = self:GetNotificationHeight(notif)
    local padding = self.toastPadding

    -- Calculate position with slide-in animation
    local slideOffset = (1 - self:EaseOutQuad(notif.slideProgress)) * (toastW + 20)
    local toastX = screenW - toastW - self.cornerMargin + slideOffset
    local toastY = notif.currentY

    -- Check hover state
    notif.hovered = mx >= toastX and mx <= toastX + toastW and
                    my >= toastY and my <= toastY + toastH

    -- Apply fade
    local alpha = notif.fadeProgress

    -- Get type color
    local typeColor = self.colors[notif.type] or self.colors.info

    -- Background with shadow
    love.graphics.setColor(0, 0, 0, 0.3 * alpha)
    love.graphics.rectangle("fill", toastX + 3, toastY + 3, toastW, toastH, 6, 6)

    -- Main background
    love.graphics.setColor(self.colors.background[1], self.colors.background[2],
                          self.colors.background[3], self.colors.background[4] * alpha)
    love.graphics.rectangle("fill", toastX, toastY, toastW, toastH, 6, 6)

    -- Left accent bar
    love.graphics.setColor(typeColor[1], typeColor[2], typeColor[3], alpha)
    love.graphics.rectangle("fill", toastX, toastY, 4, toastH, 6, 0)

    -- Border (subtle)
    love.graphics.setColor(typeColor[1], typeColor[2], typeColor[3], 0.3 * alpha)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", toastX, toastY, toastW, toastH, 6, 6)

    -- Icon circle
    local iconSize = 24
    local iconX = toastX + padding + iconSize / 2
    local iconY = toastY + padding + iconSize / 2

    love.graphics.setColor(typeColor[1], typeColor[2], typeColor[3], 0.2 * alpha)
    love.graphics.circle("fill", iconX, iconY, iconSize / 2)
    love.graphics.setColor(typeColor[1], typeColor[2], typeColor[3], alpha)
    love.graphics.circle("line", iconX, iconY, iconSize / 2)

    -- Icon text
    love.graphics.setFont(self.fonts.icon)
    love.graphics.setColor(typeColor[1], typeColor[2], typeColor[3], alpha)
    local iconText = self.icons[notif.type] or "i"
    local iconTextW = self.fonts.icon:getWidth(iconText)
    love.graphics.print(iconText, iconX - iconTextW / 2, iconY - self.fonts.icon:getHeight() / 2)

    -- Content area
    local contentX = toastX + padding + iconSize + 10
    local contentY = toastY + padding
    local contentW = toastW - padding * 2 - iconSize - 10

    -- Title
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(self.colors.text[1], self.colors.text[2],
                          self.colors.text[3], alpha)
    love.graphics.print(notif.title, contentX, contentY)
    contentY = contentY + self.fonts.title:getHeight() + 4

    -- Message
    if notif.message and notif.message ~= "" then
        love.graphics.setFont(self.fonts.body)
        love.graphics.setColor(self.colors.textDim[1], self.colors.textDim[2],
                              self.colors.textDim[3], alpha)
        love.graphics.printf(notif.message, contentX, contentY, contentW, "left")

        local _, wrappedText = self.fonts.body:getWrap(notif.message, contentW)
        contentY = contentY + #wrappedText * self.fonts.body:getHeight()
    end

    -- Action button
    if notif.actionLabel then
        contentY = contentY + 8
        local btnW = self.fonts.button:getWidth(notif.actionLabel) + 16
        local btnH = 22
        local btnX = contentX
        local btnY = contentY

        local btnHovered = mx >= btnX and mx <= btnX + btnW and
                          my >= btnY and my <= btnY + btnH

        love.graphics.setColor(btnHovered and self.colors.buttonHover[1] or self.colors.buttonBg[1],
                              btnHovered and self.colors.buttonHover[2] or self.colors.buttonBg[2],
                              btnHovered and self.colors.buttonHover[3] or self.colors.buttonBg[3],
                              alpha)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)

        love.graphics.setFont(self.fonts.button)
        love.graphics.setColor(self.colors.text[1], self.colors.text[2],
                              self.colors.text[3], alpha)
        love.graphics.print(notif.actionLabel, btnX + 8, btnY + 4)

        -- Store button bounds for click handling
        notif.actionButton = {x = btnX, y = btnY, w = btnW, h = btnH}
    end

    -- Close button (X)
    local closeSize = 18
    local closeX = toastX + toastW - closeSize - 6
    local closeY = toastY + 6
    local closeHovered = mx >= closeX and mx <= closeX + closeSize and
                        my >= closeY and my <= closeY + closeSize

    if notif.hovered then
        love.graphics.setColor(closeHovered and {0.8, 0.3, 0.3, alpha} or {0.5, 0.5, 0.5, alpha})
        love.graphics.setFont(self.fonts.body)
        love.graphics.print("x", closeX + 4, closeY)
    end

    -- Store close button bounds
    notif.closeButton = {x = closeX, y = closeY, w = closeSize, h = closeSize}

    -- Timer indicator (bottom progress bar)
    if not notif.dismissed then
        local progress = notif.remainingTime / notif.duration
        love.graphics.setColor(typeColor[1], typeColor[2], typeColor[3], 0.3 * alpha)
        love.graphics.rectangle("fill", toastX + 4, toastY + toastH - 3,
                               (toastW - 8) * progress, 2, 1, 1)
    end
end

function NotificationSystem:EaseOutQuad(t)
    return t * (2 - t)
end

-- =============================================================================
-- INPUT HANDLING
-- =============================================================================

function NotificationSystem:HandleClick(mx, my)
    for i, notif in ipairs(self.notifications) do
        if not notif.dismissed then
            -- Check close button
            if notif.closeButton then
                local btn = notif.closeButton
                if mx >= btn.x and mx <= btn.x + btn.w and
                   my >= btn.y and my <= btn.y + btn.h then
                    notif.dismissed = true
                    return true
                end
            end

            -- Check action button
            if notif.actionButton and notif.actionCallback then
                local btn = notif.actionButton
                if mx >= btn.x and mx <= btn.x + btn.w and
                   my >= btn.y and my <= btn.y + btn.h then
                    notif.actionCallback()
                    notif.dismissed = true
                    return true
                end
            end
        end
    end

    return false
end

-- =============================================================================
-- SOUND
-- =============================================================================

function NotificationSystem:PlayNotificationSound(type)
    local frequency = 440
    local duration = 0.15

    if type == self.TYPES.CRITICAL then
        frequency = 880  -- Higher, more urgent
        duration = 0.3
    elseif type == self.TYPES.WARNING then
        frequency = 660
        duration = 0.2
    elseif type == self.TYPES.SUCCESS then
        frequency = 523  -- C5, pleasant
        duration = 0.15
    end

    local sampleRate = 44100
    local samples = math.floor(sampleRate * duration)

    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)

    for i = 0, samples - 1 do
        local t = i / sampleRate
        local envelope = 1 - (t / duration)  -- Decay
        local value = math.sin(2 * math.pi * frequency * t) * 0.2 * envelope
        soundData:setSample(i, value)
    end

    local source = love.audio.newSource(soundData)
    source:setVolume(0.5)
    source:play()
end

-- =============================================================================
-- UTILITY
-- =============================================================================

function NotificationSystem:Dismiss(id)
    for _, notif in ipairs(self.notifications) do
        if notif.id == id then
            notif.dismissed = true
            return true
        end
    end
    return false
end

function NotificationSystem:DismissAll()
    for _, notif in ipairs(self.notifications) do
        notif.dismissed = true
    end
end

function NotificationSystem:GetActiveCount()
    local count = 0
    for _, notif in ipairs(self.notifications) do
        if not notif.dismissed then
            count = count + 1
        end
    end
    return count
end

function NotificationSystem:SetAutoPauseOnCritical(enabled)
    self.autoPauseOnCritical = enabled
end

function NotificationSystem:SetEnabled(enabled)
    self.enabled = enabled
end

function NotificationSystem:SetSoundEnabled(enabled)
    self.soundEnabled = enabled
end

return NotificationSystem
