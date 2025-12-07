--
-- SaveLoadModal.lua
-- Save/Load game modal for CraveTown Alpha
-- Following game_ui_flow_specification.md Section 11.1
--

local SaveManager = require("code.SaveManager")

SaveLoadModal = {}
SaveLoadModal.__index = SaveLoadModal

function SaveLoadModal:Create(world, onClose)
    local modal = setmetatable({}, SaveLoadModal)

    modal.world = world
    modal.onClose = onClose

    -- Initialize save manager
    modal.saveManager = SaveManager:Create()

    -- Fonts
    modal.fonts = {
        title = love.graphics.newFont(24),
        header = love.graphics.newFont(18),
        normal = love.graphics.newFont(14),
        small = love.graphics.newFont(12)
    }

    -- Colors
    modal.colors = {
        background = {0.1, 0.1, 0.14},
        panel = {0.15, 0.15, 0.2},
        border = {0.3, 0.3, 0.35},
        title = {0.85, 0.7, 0.3},
        text = {0.9, 0.9, 0.95},
        textDim = {0.6, 0.6, 0.65},
        accent = {0.4, 0.7, 1.0},
        button = {0.25, 0.25, 0.3},
        buttonHover = {0.35, 0.35, 0.4},
        buttonDanger = {0.5, 0.2, 0.2},
        buttonDangerHover = {0.6, 0.3, 0.3},
        buttonSuccess = {0.2, 0.5, 0.3},
        buttonSuccessHover = {0.3, 0.6, 0.4},
        slotEmpty = {0.12, 0.12, 0.15},
        slotFilled = {0.18, 0.18, 0.22},
        slotSelected = {0.25, 0.35, 0.45}
    }

    -- UI State
    modal.mode = "save"  -- "save" or "load"
    modal.selectedSlot = nil
    modal.hoveredSlot = nil
    modal.hoveredButton = nil
    modal.confirmDelete = nil  -- Slot number awaiting delete confirmation
    modal.statusMessage = nil
    modal.statusTimer = 0

    -- Load slot info
    modal.slots = modal.saveManager:GetAllSlotInfo()
    modal.quicksaveInfo = modal.saveManager:GetQuicksaveInfo()
    modal.autosaveInfo = modal.saveManager:GetAutosaveInfo()

    -- Autosave settings
    modal.autosaveEnabled = modal.saveManager.autosaveEnabled
    modal.autosaveInterval = modal.saveManager.autosaveInterval

    return modal
end

function SaveLoadModal:SetMode(mode)
    self.mode = mode
    self.selectedSlot = nil
    self.confirmDelete = nil
end

function SaveLoadModal:RefreshSlots()
    self.slots = self.saveManager:GetAllSlotInfo()
    self.quicksaveInfo = self.saveManager:GetQuicksaveInfo()
    self.autosaveInfo = self.saveManager:GetAutosaveInfo()
end

function SaveLoadModal:ShowStatus(message)
    self.statusMessage = message
    self.statusTimer = 2.0
end

function SaveLoadModal:Update(dt)
    if self.statusTimer > 0 then
        self.statusTimer = self.statusTimer - dt
        if self.statusTimer <= 0 then
            self.statusMessage = nil
        end
    end
end

function SaveLoadModal:Render()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Panel dimensions
    local panelW = math.min(600, screenW - 80)
    local panelH = math.min(520, screenH - 80)
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Panel background
    love.graphics.setColor(self.colors.panel)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 8, 8)

    -- Panel border
    love.graphics.setColor(self.colors.border)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 8, 8)

    -- Title
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(self.colors.title)
    local title = self.mode == "save" and "SAVE GAME" or "LOAD GAME"
    local titleW = self.fonts.title:getWidth(title)
    love.graphics.print(title, panelX + (panelW - titleW) / 2, panelY + 15)

    -- Mode tabs
    self:RenderModeTabs(panelX, panelY + 55, panelW)

    -- Save slots
    self:RenderSlots(panelX + 20, panelY + 95, panelW - 40, panelH - 200)

    -- Autosave settings (only in save mode)
    if self.mode == "save" then
        self:RenderAutosaveSettings(panelX + 20, panelY + panelH - 95, panelW - 40)
    end

    -- Quick actions
    self:RenderQuickActions(panelX + 20, panelY + panelH - 50, panelW - 40)

    -- Status message
    if self.statusMessage then
        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(0.4, 0.8, 0.4)
        local msgW = self.fonts.normal:getWidth(self.statusMessage)
        love.graphics.print(self.statusMessage, panelX + (panelW - msgW) / 2, panelY + panelH - 25)
    end

    -- Close button
    self:RenderCloseButton(panelX + panelW - 35, panelY + 10)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function SaveLoadModal:RenderModeTabs(x, y, width)
    local tabW = 100
    local tabH = 30
    local gap = 10

    local tabs = {
        {id = "save", label = "SAVE"},
        {id = "load", label = "LOAD"}
    }

    local startX = x + (width - (#tabs * tabW + (#tabs - 1) * gap)) / 2

    for i, tab in ipairs(tabs) do
        local tabX = startX + (i - 1) * (tabW + gap)
        local isActive = self.mode == tab.id
        local isHovered = self.hoveredButton == "tab_" .. tab.id

        if isActive then
            love.graphics.setColor(self.colors.accent)
        elseif isHovered then
            love.graphics.setColor(self.colors.buttonHover)
        else
            love.graphics.setColor(self.colors.button)
        end
        love.graphics.rectangle("fill", tabX, y, tabW, tabH, 4, 4)

        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(isActive and {1, 1, 1} or self.colors.textDim)
        local labelW = self.fonts.normal:getWidth(tab.label)
        love.graphics.print(tab.label, tabX + (tabW - labelW) / 2, y + 7)
    end
end

function SaveLoadModal:RenderSlots(x, y, width, height)
    local slotH = 65
    local gap = 8
    local slotsY = y

    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("SAVE SLOTS", x, slotsY)
    slotsY = slotsY + 28

    for i = 1, self.saveManager.MAX_SLOTS do
        local slotInfo = self.slots[i]
        local slotY = slotsY + (i - 1) * (slotH + gap)

        -- Skip if out of view
        if slotY + slotH > y + height then break end

        self:RenderSlot(x, slotY, width, slotH, i, slotInfo)
    end
end

function SaveLoadModal:RenderSlot(x, y, width, height, slotNumber, slotInfo)
    local isSelected = self.selectedSlot == slotNumber
    local isHovered = self.hoveredSlot == slotNumber
    local isEmpty = slotInfo == nil
    local isConfirmingDelete = self.confirmDelete == slotNumber

    -- Slot background
    if isSelected then
        love.graphics.setColor(self.colors.slotSelected)
    elseif isHovered then
        love.graphics.setColor(self.colors.buttonHover)
    elseif isEmpty then
        love.graphics.setColor(self.colors.slotEmpty)
    else
        love.graphics.setColor(self.colors.slotFilled)
    end
    love.graphics.rectangle("fill", x, y, width, height, 4, 4)

    if isSelected then
        love.graphics.setColor(self.colors.accent)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x, y, width, height, 4, 4)
    end

    -- Slot content
    local contentX = x + 12
    local contentY = y + 8

    love.graphics.setFont(self.fonts.normal)

    if isEmpty then
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Slot " .. slotNumber .. ": [Empty]", contentX, contentY + 15)

        -- Save button for empty slot (only in save mode)
        if self.mode == "save" then
            local btnW = 70
            local btnH = 28
            local btnX = x + width - btnW - 10
            local btnY = y + (height - btnH) / 2
            local btnHovered = self.hoveredButton == "save_" .. slotNumber

            love.graphics.setColor(btnHovered and self.colors.buttonSuccessHover or self.colors.buttonSuccess)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)
            love.graphics.setColor(1, 1, 1)
            local txt = "SAVE"
            local txtW = self.fonts.normal:getWidth(txt)
            love.graphics.print(txt, btnX + (btnW - txtW) / 2, btnY + 6)
        end
    else
        -- Slot header
        love.graphics.setColor(self.colors.text)
        love.graphics.print("Slot " .. slotNumber .. ": " .. slotInfo.townName, contentX, contentY)

        -- Details
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textDim)
        local details = string.format("Day %d | Pop: %d | Satisfaction: %d%% | Gold: %d",
            slotInfo.dayNumber or 1,
            slotInfo.population or 0,
            slotInfo.satisfaction or 0,
            slotInfo.gold or 0)
        love.graphics.print(details, contentX, contentY + 20)

        love.graphics.print("Saved: " .. (slotInfo.savedAt or "Unknown"), contentX, contentY + 36)

        -- Action buttons
        local btnW = 55
        local btnH = 24
        local btnGap = 6
        local btnY = y + (height - btnH) / 2

        if isConfirmingDelete then
            -- Confirm delete buttons
            local confirmX = x + width - 130

            love.graphics.setFont(self.fonts.small)
            love.graphics.setColor(self.colors.text)
            love.graphics.print("Delete?", confirmX - 50, btnY + 5)

            -- Yes button
            local yesHovered = self.hoveredButton == "confirm_yes_" .. slotNumber
            love.graphics.setColor(yesHovered and self.colors.buttonDangerHover or self.colors.buttonDanger)
            love.graphics.rectangle("fill", confirmX, btnY, 40, btnH, 4, 4)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Yes", confirmX + 10, btnY + 5)

            -- No button
            local noHovered = self.hoveredButton == "confirm_no_" .. slotNumber
            love.graphics.setColor(noHovered and self.colors.buttonHover or self.colors.button)
            love.graphics.rectangle("fill", confirmX + 50, btnY, 40, btnH, 4, 4)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("No", confirmX + 62, btnY + 5)
        else
            local btnX = x + width - btnW * 3 - btnGap * 2 - 10

            -- Load button
            local loadHovered = self.hoveredButton == "load_" .. slotNumber
            love.graphics.setColor(loadHovered and self.colors.buttonHover or self.colors.button)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)
            love.graphics.setFont(self.fonts.small)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("LOAD", btnX + 12, btnY + 5)
            btnX = btnX + btnW + btnGap

            -- Save button (only in save mode)
            if self.mode == "save" then
                local saveHovered = self.hoveredButton == "save_" .. slotNumber
                love.graphics.setColor(saveHovered and self.colors.buttonSuccessHover or self.colors.buttonSuccess)
                love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)
                love.graphics.setColor(1, 1, 1)
                love.graphics.print("SAVE", btnX + 12, btnY + 5)
            end
            btnX = btnX + btnW + btnGap

            -- Delete button
            local deleteHovered = self.hoveredButton == "delete_" .. slotNumber
            love.graphics.setColor(deleteHovered and self.colors.buttonDangerHover or self.colors.buttonDanger)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4, 4)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("DEL", btnX + 15, btnY + 5)
        end
    end
end

function SaveLoadModal:RenderAutosaveSettings(x, y, width)
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("AUTOSAVE", x, y)

    -- Checkbox
    local checkX = x + 90
    local checkY = y + 2
    local checkSize = 16

    local checkHovered = self.hoveredButton == "autosave_toggle"
    love.graphics.setColor(checkHovered and self.colors.buttonHover or self.colors.button)
    love.graphics.rectangle("fill", checkX, checkY, checkSize, checkSize, 2, 2)

    if self.autosaveEnabled then
        love.graphics.setColor(self.colors.accent)
        love.graphics.rectangle("fill", checkX + 3, checkY + 3, checkSize - 6, checkSize - 6, 2, 2)
    end

    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Enable", checkX + 22, y)

    -- Interval
    love.graphics.print("Every:", x + 180, y)
    love.graphics.setColor(self.colors.text)
    love.graphics.print(self.autosaveInterval .. " cycles", x + 225, y)

    -- Autosave info
    if self.autosaveInfo then
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Last: " .. self.autosaveInfo.savedAt, x + 320, y + 2)
    end
end

function SaveLoadModal:RenderQuickActions(x, y, width)
    local btnW = 110
    local btnH = 30
    local gap = 10

    -- Quicksave button (save mode only)
    if self.mode == "save" then
        local qsHovered = self.hoveredButton == "quicksave"
        love.graphics.setColor(qsHovered and self.colors.buttonSuccessHover or self.colors.buttonSuccess)
        love.graphics.rectangle("fill", x, y, btnW, btnH, 4, 4)
        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Quicksave", x + 15, y + 7)
    end

    -- Quickload button
    local qlX = self.mode == "save" and (x + btnW + gap) or x
    local hasQuicksave = self.quicksaveInfo ~= nil
    local qlHovered = self.hoveredButton == "quickload"

    if hasQuicksave then
        love.graphics.setColor(qlHovered and self.colors.buttonHover or self.colors.button)
    else
        love.graphics.setColor(0.2, 0.2, 0.22)
    end
    love.graphics.rectangle("fill", qlX, y, btnW, btnH, 4, 4)
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(hasQuicksave and (qlHovered and {1, 1, 1} or self.colors.text) or self.colors.textDim)
    love.graphics.print("Quickload", qlX + 15, y + 7)

    -- Load Autosave button
    local laX = qlX + btnW + gap
    local hasAutosave = self.autosaveInfo ~= nil
    local laHovered = self.hoveredButton == "load_autosave"

    if hasAutosave then
        love.graphics.setColor(laHovered and self.colors.buttonHover or self.colors.button)
    else
        love.graphics.setColor(0.2, 0.2, 0.22)
    end
    love.graphics.rectangle("fill", laX, y, btnW + 10, btnH, 4, 4)
    love.graphics.setColor(hasAutosave and (laHovered and {1, 1, 1} or self.colors.text) or self.colors.textDim)
    love.graphics.print("Load Auto", laX + 15, y + 7)
end

function SaveLoadModal:RenderCloseButton(x, y)
    local size = 24
    local isHovered = self.hoveredButton == "close"

    love.graphics.setColor(isHovered and self.colors.buttonDangerHover or self.colors.buttonDanger)
    love.graphics.rectangle("fill", x, y, size, size, 4, 4)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(x + 6, y + 6, x + size - 6, y + size - 6)
    love.graphics.line(x + size - 6, y + 6, x + 6, y + size - 6)
end

function SaveLoadModal:HandleKeyPress(key)
    if key == "escape" then
        if self.confirmDelete then
            self.confirmDelete = nil
        else
            self:Close()
        end
        return true
    elseif key == "f5" then
        self:DoQuicksave()
        return true
    elseif key == "f9" then
        self:DoQuickload()
        return true
    end
    return false
end

function SaveLoadModal:HandleClick(mx, my, button)
    if button ~= 1 then return false end

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local panelW = math.min(600, screenW - 80)
    local panelH = math.min(520, screenH - 80)
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Close button
    if mx >= panelX + panelW - 35 and mx <= panelX + panelW - 11 and
       my >= panelY + 10 and my <= panelY + 34 then
        self:Close()
        return true
    end

    -- Mode tabs
    local tabW = 100
    local tabH = 30
    local gap = 10
    local tabY = panelY + 55
    local startX = panelX + (panelW - (2 * tabW + gap)) / 2

    if my >= tabY and my <= tabY + tabH then
        if mx >= startX and mx <= startX + tabW then
            self:SetMode("save")
            return true
        elseif mx >= startX + tabW + gap and mx <= startX + 2 * tabW + gap then
            self:SetMode("load")
            return true
        end
    end

    -- Slot buttons
    local slotsX = panelX + 20
    local slotsY = panelY + 95 + 28
    local slotH = 65
    local slotGap = 8
    local slotW = panelW - 40

    for i = 1, self.saveManager.MAX_SLOTS do
        local slotY = slotsY + (i - 1) * (slotH + slotGap)
        local slotInfo = self.slots[i]

        if my >= slotY and my <= slotY + slotH and mx >= slotsX and mx <= slotsX + slotW then
            -- Check button clicks within slot
            local btnW = 55
            local btnH = 24
            local btnGap = 6
            local btnY = slotY + (slotH - btnH) / 2

            if self.confirmDelete == i then
                -- Confirm/cancel delete
                local confirmX = slotsX + slotW - 130
                if mx >= confirmX and mx <= confirmX + 40 and my >= btnY and my <= btnY + btnH then
                    self:DeleteSlot(i)
                    return true
                elseif mx >= confirmX + 50 and mx <= confirmX + 90 and my >= btnY and my <= btnY + btnH then
                    self.confirmDelete = nil
                    return true
                end
            else
                local btnX = slotsX + slotW - btnW * 3 - btnGap * 2 - 10

                if slotInfo == nil then
                    -- Empty slot - save button
                    if self.mode == "save" then
                        local saveBtnX = slotsX + slotW - 80
                        if mx >= saveBtnX and mx <= saveBtnX + 70 and my >= btnY and my <= btnY + 28 then
                            self:SaveToSlot(i)
                            return true
                        end
                    end
                else
                    -- Load button
                    if mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH then
                        self:LoadFromSlot(i)
                        return true
                    end
                    btnX = btnX + btnW + btnGap

                    -- Save button
                    if self.mode == "save" then
                        if mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH then
                            self:SaveToSlot(i)
                            return true
                        end
                    end
                    btnX = btnX + btnW + btnGap

                    -- Delete button
                    if mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH then
                        self.confirmDelete = i
                        return true
                    end
                end
            end

            -- Select slot
            self.selectedSlot = i
            return true
        end
    end

    -- Autosave toggle
    if self.mode == "save" then
        local checkX = panelX + 20 + 90
        local checkY = panelY + panelH - 95 + 2
        if mx >= checkX and mx <= checkX + 16 and my >= checkY and my <= checkY + 16 then
            self.autosaveEnabled = not self.autosaveEnabled
            self.saveManager.autosaveEnabled = self.autosaveEnabled
            self.saveManager:SaveSettings()
            return true
        end
    end

    -- Quick action buttons
    local qaY = panelY + panelH - 50
    local btnW = 110
    local btnH = 30
    local qaGap = 10
    local qaX = panelX + 20

    if my >= qaY and my <= qaY + btnH then
        if self.mode == "save" then
            if mx >= qaX and mx <= qaX + btnW then
                self:DoQuicksave()
                return true
            end
            qaX = qaX + btnW + qaGap
        end

        if mx >= qaX and mx <= qaX + btnW then
            self:DoQuickload()
            return true
        end
        qaX = qaX + btnW + qaGap

        if mx >= qaX and mx <= qaX + btnW + 10 then
            self:LoadAutosave()
            return true
        end
    end

    return true  -- Consume click within modal
end

function SaveLoadModal:HandleMouseMove(mx, my)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local panelW = math.min(600, screenW - 80)
    local panelH = math.min(520, screenH - 80)
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    self.hoveredSlot = nil
    self.hoveredButton = nil

    -- Close button
    if mx >= panelX + panelW - 35 and mx <= panelX + panelW - 11 and
       my >= panelY + 10 and my <= panelY + 34 then
        self.hoveredButton = "close"
        return
    end

    -- Mode tabs
    local tabW = 100
    local tabH = 30
    local gap = 10
    local tabY = panelY + 55
    local startX = panelX + (panelW - (2 * tabW + gap)) / 2

    if my >= tabY and my <= tabY + tabH then
        if mx >= startX and mx <= startX + tabW then
            self.hoveredButton = "tab_save"
            return
        elseif mx >= startX + tabW + gap and mx <= startX + 2 * tabW + gap then
            self.hoveredButton = "tab_load"
            return
        end
    end

    -- Slots
    local slotsX = panelX + 20
    local slotsY = panelY + 95 + 28
    local slotH = 65
    local slotGap = 8
    local slotW = panelW - 40

    for i = 1, self.saveManager.MAX_SLOTS do
        local slotY = slotsY + (i - 1) * (slotH + slotGap)

        if my >= slotY and my <= slotY + slotH and mx >= slotsX and mx <= slotsX + slotW then
            self.hoveredSlot = i
            local slotInfo = self.slots[i]

            -- Check button hovers
            local btnW = 55
            local btnH = 24
            local btnGap = 6
            local btnY = slotY + (slotH - btnH) / 2

            if self.confirmDelete == i then
                local confirmX = slotsX + slotW - 130
                if mx >= confirmX and mx <= confirmX + 40 and my >= btnY and my <= btnY + btnH then
                    self.hoveredButton = "confirm_yes_" .. i
                elseif mx >= confirmX + 50 and mx <= confirmX + 90 and my >= btnY and my <= btnY + btnH then
                    self.hoveredButton = "confirm_no_" .. i
                end
            else
                if slotInfo == nil then
                    if self.mode == "save" then
                        local saveBtnX = slotsX + slotW - 80
                        if mx >= saveBtnX and mx <= saveBtnX + 70 and my >= btnY and my <= btnY + 28 then
                            self.hoveredButton = "save_" .. i
                        end
                    end
                else
                    local btnX = slotsX + slotW - btnW * 3 - btnGap * 2 - 10

                    if mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH then
                        self.hoveredButton = "load_" .. i
                    end
                    btnX = btnX + btnW + btnGap

                    if self.mode == "save" then
                        if mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH then
                            self.hoveredButton = "save_" .. i
                        end
                    end
                    btnX = btnX + btnW + btnGap

                    if mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH then
                        self.hoveredButton = "delete_" .. i
                    end
                end
            end
            return
        end
    end

    -- Autosave toggle
    if self.mode == "save" then
        local checkX = panelX + 20 + 90
        local checkY = panelY + panelH - 95 + 2
        if mx >= checkX and mx <= checkX + 16 and my >= checkY and my <= checkY + 16 then
            self.hoveredButton = "autosave_toggle"
            return
        end
    end

    -- Quick actions
    local qaY = panelY + panelH - 50
    local btnW = 110
    local btnH = 30
    local qaGap = 10
    local qaX = panelX + 20

    if my >= qaY and my <= qaY + btnH then
        if self.mode == "save" then
            if mx >= qaX and mx <= qaX + btnW then
                self.hoveredButton = "quicksave"
                return
            end
            qaX = qaX + btnW + qaGap
        end

        if mx >= qaX and mx <= qaX + btnW then
            self.hoveredButton = "quickload"
            return
        end
        qaX = qaX + btnW + qaGap

        if mx >= qaX and mx <= qaX + btnW + 10 then
            self.hoveredButton = "load_autosave"
            return
        end
    end
end

function SaveLoadModal:SaveToSlot(slotNumber)
    local success, msg = self.saveManager:SaveToSlot(self.world, slotNumber)
    if success then
        self:ShowStatus("Saved to Slot " .. slotNumber)
        self:RefreshSlots()
    else
        self:ShowStatus("Save failed: " .. msg)
    end
end

function SaveLoadModal:LoadFromSlot(slotNumber)
    local data, msg = self.saveManager:LoadFromSlot(slotNumber)
    if data then
        self:ShowStatus("Loading Slot " .. slotNumber .. "...")
        -- Trigger load callback
        if self.onLoad then
            self.onLoad(data)
        end
        self:Close()
    else
        self:ShowStatus("Load failed: " .. msg)
    end
end

function SaveLoadModal:DeleteSlot(slotNumber)
    local success = self.saveManager:DeleteSlot(slotNumber)
    if success then
        self:ShowStatus("Slot " .. slotNumber .. " deleted")
        self:RefreshSlots()
    end
    self.confirmDelete = nil
end

function SaveLoadModal:DoQuicksave()
    local success, msg = self.saveManager:Quicksave(self.world)
    if success then
        self:ShowStatus("Quicksave complete (F5)")
        self:RefreshSlots()
    else
        self:ShowStatus("Quicksave failed")
    end
end

function SaveLoadModal:DoQuickload()
    if not self.saveManager:HasQuicksave() then
        self:ShowStatus("No quicksave found")
        return
    end

    local data, msg = self.saveManager:Quickload()
    if data then
        self:ShowStatus("Loading quicksave...")
        if self.onLoad then
            self.onLoad(data)
        end
        self:Close()
    else
        self:ShowStatus("Quickload failed")
    end
end

function SaveLoadModal:LoadAutosave()
    if not self.saveManager:HasAutosave() then
        self:ShowStatus("No autosave found")
        return
    end

    local data, msg = self.saveManager:LoadAutosave()
    if data then
        self:ShowStatus("Loading autosave...")
        if self.onLoad then
            self.onLoad(data)
        end
        self:Close()
    else
        self:ShowStatus("Autosave load failed")
    end
end

function SaveLoadModal:Close()
    if self.onClose then
        self.onClose()
    end
end

return SaveLoadModal
