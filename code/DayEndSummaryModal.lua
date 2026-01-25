--
-- DayEndSummaryModal.lua
-- Shows day end summary with citizen issues and production/consumption data
--

local json = require("code/json")

DayEndSummaryModal = {}
DayEndSummaryModal.__index = DayEndSummaryModal

-- Load dimension hints data
local dimensionHints = nil
local function loadDimensionHints()
    if dimensionHints then return dimensionHints end

    local contents = love.filesystem.read("data/alpha/craving_system/dimension_hints.json")
    if contents then
        dimensionHints = json.decode(contents)
    else
        dimensionHints = { fineHints = {}, coarseLabels = {} }
    end
    return dimensionHints
end

function DayEndSummaryModal:Create(world, dayNumber, onClose)
    local modal = setmetatable({}, DayEndSummaryModal)

    modal.world = world
    modal.dayNumber = dayNumber
    modal.onClose = onClose

    -- Load hints data
    modal.hints = loadDimensionHints()

    -- Get the summary data from ProductionStats
    modal.summary = nil
    if world.productionStats then
        modal.summary = world.productionStats:getDayEndSummary(dayNumber)
    end

    -- UI State
    modal.scrollOffset = 0
    modal.maxScroll = 0
    modal.contentHeight = 0

    -- Auto-show preference (from world or settings)
    modal.autoShowEnabled = world.showDayEndSummary ~= false

    -- Modal dimensions
    modal.modalWidth = 650
    modal.modalHeight = 550

    -- Fonts
    modal.fonts = {
        title = love.graphics.newFont(18),
        header = love.graphics.newFont(14),
        normal = love.graphics.newFont(12),
        small = love.graphics.newFont(11),
        tiny = love.graphics.newFont(10)
    }

    -- Colors
    modal.colors = {
        background = {0.1, 0.1, 0.12, 0.98},
        text = {1, 1, 1},
        textDim = {0.7, 0.7, 0.7},
        accent = {0.4, 0.7, 1.0},
        -- Severity colors
        critical = {0.8, 0.1, 0.1},
        criticalBg = {0.4, 0.1, 0.1, 0.8},
        warning = {0.9, 0.5, 0.0},
        warningBg = {0.4, 0.25, 0.0, 0.8},
        mild = {0.8, 0.6, 0.0},
        mildBg = {0.35, 0.3, 0.0, 0.8},
        -- Section colors
        production = {0.4, 0.8, 0.4},
        citizenConsumption = {0.4, 0.6, 0.9},
        buildingConsumption = {0.9, 0.6, 0.3},
        -- UI colors
        button = {0.25, 0.25, 0.3},
        buttonHover = {0.35, 0.35, 0.4},
        checkbox = {0.3, 0.3, 0.35},
        checkboxActive = {0.3, 0.5, 0.7}
    }

    -- Checkbox state
    modal.checkboxHovered = false
    modal.okButtonHovered = false

    -- Prevent instant close
    modal.justOpened = true

    return modal
end

function DayEndSummaryModal:Enter()
    print("DayEndSummaryModal:Enter() for Day " .. self.dayNumber)
end

function DayEndSummaryModal:Exit()
    print("DayEndSummaryModal:Exit()")
end

function DayEndSummaryModal:HandleInput()
    return true  -- Block input to lower states
end

function DayEndSummaryModal:Update(dt)
    -- Note: Click handling is done via HandleClick() when used with AlphaUI
    -- The gMouseReleased-based handling below is for legacy StateStack compatibility

    -- Check if gMouseReleased global exists (StateStack mode)
    if gMouseReleased == nil then
        return true  -- No StateStack, clicks handled via HandleClick()
    end

    -- Wait for mouse release after opening
    if self.justOpened then
        if gMouseReleased then
            self.justOpened = false
        end
        return true
    end

    local mx, my = gMouseReleased.x, gMouseReleased.y
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local modalX = (screenW - self.modalWidth) / 2
    local modalY = (screenH - self.modalHeight) / 2

    -- Check close button (X)
    local closeX = modalX + self.modalWidth - 35
    local closeY = modalY + 10
    if mx >= closeX and mx <= closeX + 25 and my >= closeY and my <= closeY + 25 then
        self:Close()
        return false
    end

    -- Check OK button
    local okBtnW = 80
    local okBtnH = 30
    local okBtnX = modalX + self.modalWidth - okBtnW - 20
    local okBtnY = modalY + self.modalHeight - okBtnH - 15
    if mx >= okBtnX and mx <= okBtnX + okBtnW and my >= okBtnY and my <= okBtnY + okBtnH then
        self:Close()
        return false
    end

    -- Check checkbox
    local checkboxSize = 16
    local checkboxX = modalX + 20
    local checkboxY = modalY + self.modalHeight - checkboxSize - 20
    if mx >= checkboxX and mx <= checkboxX + checkboxSize and my >= checkboxY and my <= checkboxY + checkboxSize then
        self:ToggleAutoShow()
        return true
    end

    -- Check click outside modal to close
    if mx < modalX or mx > modalX + self.modalWidth or
       my < modalY or my > modalY + self.modalHeight then
        self:Close()
        return false
    end

    return true
end

function DayEndSummaryModal:OnMouseWheel(dx, dy)
    self.scrollOffset = self.scrollOffset - dy * 30
    self.scrollOffset = math.max(0, math.min(self.scrollOffset, self.maxScroll))
end

-- HandleClick for AlphaUI integration (doesn't rely on gMouseReleased global)
function DayEndSummaryModal:HandleClick(mx, my, button)
    -- Wait for mouse release after opening (handled by justOpened flag)
    if self.justOpened then
        self.justOpened = false
        return true
    end

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local modalX = (screenW - self.modalWidth) / 2
    local modalY = (screenH - self.modalHeight) / 2

    -- Check close button (X)
    local closeX = modalX + self.modalWidth - 35
    local closeY = modalY + 10
    if mx >= closeX and mx <= closeX + 25 and my >= closeY and my <= closeY + 25 then
        self:Close()
        return true
    end

    -- Check OK button
    local okBtnW = 80
    local okBtnH = 30
    local okBtnX = modalX + self.modalWidth - okBtnW - 20
    local okBtnY = modalY + self.modalHeight - okBtnH - 15
    if mx >= okBtnX and mx <= okBtnX + okBtnW and my >= okBtnY and my <= okBtnY + okBtnH then
        self:Close()
        return true
    end

    -- Check checkbox
    local checkboxSize = 16
    local checkboxX = modalX + 20
    local checkboxY = modalY + self.modalHeight - checkboxSize - 20
    if mx >= checkboxX and mx <= checkboxX + checkboxSize and my >= checkboxY and my <= checkboxY + checkboxSize then
        self:ToggleAutoShow()
        return true
    end

    -- Check click outside modal to close
    if mx < modalX or mx > modalX + self.modalWidth or
       my < modalY or my > modalY + self.modalHeight then
        self:Close()
        return true
    end

    return true  -- Consume all clicks when modal is open
end

function DayEndSummaryModal:ToggleAutoShow()
    self.autoShowEnabled = not self.autoShowEnabled
    if self.world then
        self.world.showDayEndSummary = self.autoShowEnabled
    end
    print("DayEndSummaryModal: Auto-show set to " .. tostring(self.autoShowEnabled))
end

function DayEndSummaryModal:Close()
    if self.onClose then
        self.onClose()
    end
    -- Note: gStateStack:Pop() removed - modal closing is now handled by the onClose callback
    -- which is set up by AlphaUI to clear the modal state
end

function DayEndSummaryModal:Render()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local mx, my = love.mouse.getPosition()

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal position
    local modalX = (screenW - self.modalWidth) / 2
    local modalY = (screenH - self.modalHeight) / 2

    -- Modal background
    love.graphics.setColor(self.colors.background)
    love.graphics.rectangle("fill", modalX, modalY, self.modalWidth, self.modalHeight, 8, 8)

    -- Modal border
    love.graphics.setColor(0.4, 0.5, 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", modalX, modalY, self.modalWidth, self.modalHeight, 8, 8)
    love.graphics.setLineWidth(1)

    -- Title
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(self.colors.text)
    local titleText = "DAY " .. self.dayNumber .. " SUMMARY"
    local titleWidth = self.fonts.title:getWidth(titleText)
    love.graphics.print(titleText, modalX + (self.modalWidth - titleWidth) / 2, modalY + 15)

    -- Close button
    local closeX = modalX + self.modalWidth - 35
    local closeY = modalY + 10
    local hoveringClose = mx >= closeX and mx <= closeX + 25 and my >= closeY and my <= closeY + 25
    love.graphics.setColor(hoveringClose and 0.6 or 0.4, 0.2, 0.2)
    love.graphics.rectangle("fill", closeX, closeY, 25, 25, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.header)
    love.graphics.print("X", closeX + 8, closeY + 4)

    -- Content area (with scissor for scrolling)
    local contentY = modalY + 50
    local contentH = self.modalHeight - 100  -- Leave space for bottom controls
    love.graphics.setScissor(modalX + 10, contentY, self.modalWidth - 20, contentH)

    local y = contentY - self.scrollOffset

    -- Render content
    if self.summary then
        y = self:RenderIssuesSection(modalX, y)
        y = self:RenderShortagesSection(modalX, y)
        y = self:RenderProductionSection(modalX, y)
        y = self:RenderConsumptionSection(modalX, y)
    else
        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("No data available for Day " .. self.dayNumber, modalX + 20, y)
        y = y + 30
    end

    -- Calculate content height for scrolling
    self.contentHeight = y - (contentY - self.scrollOffset)
    self.maxScroll = math.max(0, self.contentHeight - contentH + 20)

    love.graphics.setScissor()

    -- Bottom controls
    self:RenderBottomControls(modalX, modalY, mx, my)

    love.graphics.setColor(1, 1, 1)
end

function DayEndSummaryModal:RenderIssuesSection(modalX, y)
    local summary = self.summary
    local hasIssues = summary.hasIssues
    local issueCount = #summary.issues
    local homelessCount = summary.homelessCount or 0

    if homelessCount > 0 then
        issueCount = issueCount + 1
    end

    -- Section header
    love.graphics.setFont(self.fonts.header)
    if hasIssues then
        love.graphics.setColor(self.colors.critical)
        love.graphics.print("!! CITIZEN ISSUES (" .. issueCount .. " problems)", modalX + 20, y)
    else
        love.graphics.setColor(self.colors.production)
        love.graphics.print("CITIZEN ISSUES - All citizens satisfied!", modalX + 20, y)
    end
    y = y + 25

    if not hasIssues then
        return y + 10
    end

    -- Render each issue by coarse dimension
    for _, issue in ipairs(summary.issues) do
        y = self:RenderIssueCard(modalX + 20, y, issue)
    end

    -- Render homeless issue if present
    if homelessCount > 0 then
        y = self:RenderHomelessCard(modalX + 20, y, homelessCount)
    end

    return y + 10
end

function DayEndSummaryModal:RenderIssueCard(x, y, issue)
    local cardWidth = self.modalWidth - 60
    local cardPadding = 10

    -- Determine colors based on severity
    local bgColor, textColor, severityLabel
    if issue.severity == "critical" then
        bgColor = self.colors.criticalBg
        textColor = self.colors.critical
        severityLabel = "CRITICAL"
    elseif issue.severity == "warning" then
        bgColor = self.colors.warningBg
        textColor = self.colors.warning
        severityLabel = "WARNING"
    else
        bgColor = self.colors.mildBg
        textColor = self.colors.mild
        severityLabel = "MILD"
    end

    -- Calculate card height based on content
    local fineCount = #issue.fineBreakdown
    local cardHeight = 50 + math.min(fineCount, 3) * 16 + 20

    -- Card background
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, cardWidth, cardHeight, 5, 5)

    -- Left border indicator
    love.graphics.setColor(textColor)
    love.graphics.rectangle("fill", x, y, 4, cardHeight, 5, 0)

    -- Issue icon and count
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.text)
    local coarseLabel = self.hints.coarseLabels[issue.coarseId] or issue.coarseId
    local mainText = string.format("[!] %d Citizens with %s Unmet", issue.count, coarseLabel)
    love.graphics.print(mainText, x + cardPadding + 5, y + cardPadding)

    -- Severity label on right
    love.graphics.setColor(textColor)
    local severityWidth = self.fonts.small:getWidth(severityLabel)
    love.graphics.setFont(self.fonts.small)
    love.graphics.print(severityLabel, x + cardWidth - severityWidth - cardPadding, y + cardPadding + 2)

    -- Fine dimension breakdown (top 3)
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    local fineY = y + cardPadding + 22
    for i, fine in ipairs(issue.fineBreakdown) do
        if i > 3 then break end
        local fineHint = self.hints.fineHints[fine.id]
        local issueText = fineHint and fineHint.issue or fine.id
        love.graphics.print("  - " .. fine.count .. " " .. issueText, x + cardPadding + 5, fineY)
        fineY = fineY + 16
    end
    if fineCount > 3 then
        love.graphics.print("  ... and " .. (fineCount - 3) .. " more", x + cardPadding + 5, fineY)
        fineY = fineY + 16
    end

    -- Hint section
    local hints = self:GetHintsForIssue(issue)
    if hints and #hints > 0 then
        love.graphics.setColor(self.colors.accent)
        local hintText = "Hint: " .. table.concat(hints, ", ")
        -- Truncate if too long
        if #hintText > 80 then
            hintText = hintText:sub(1, 77) .. "..."
        end
        love.graphics.print(hintText, x + cardPadding + 5, y + cardHeight - 18)
    end

    return y + cardHeight + 8
end

function DayEndSummaryModal:RenderHomelessCard(x, y, count)
    local cardWidth = self.modalWidth - 60
    local cardHeight = 50

    -- Use warning colors for homeless
    local bgColor = self.colors.warningBg
    local textColor = self.colors.warning

    -- Card background
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, cardWidth, cardHeight, 5, 5)

    -- Left border
    love.graphics.setColor(textColor)
    love.graphics.rectangle("fill", x, y, 4, cardHeight, 5, 0)

    -- Text
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("[!] " .. count .. " Homeless Citizens", x + 15, y + 10)

    -- Severity
    love.graphics.setColor(textColor)
    love.graphics.setFont(self.fonts.small)
    local severityWidth = self.fonts.small:getWidth("WARNING")
    love.graphics.print("WARNING", x + cardWidth - severityWidth - 10, y + 12)

    -- Hint
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.accent)
    local hint = self.hints.housingIssues and self.hints.housingIssues.homeless
    local hintText = hint and hint.hint or "Build more Lodges, Family Homes, or Manors"
    love.graphics.print("Hint: " .. hintText, x + 15, y + 32)

    return y + cardHeight + 8
end

function DayEndSummaryModal:GetHintsForIssue(issue)
    local hints = {}
    local seenBuildings = {}

    -- Collect unique hints from fine dimensions
    for _, fine in ipairs(issue.fineBreakdown) do
        local fineHint = self.hints.fineHints[fine.id]
        if fineHint and fineHint.buildings then
            for _, building in ipairs(fineHint.buildings) do
                if not seenBuildings[building] then
                    seenBuildings[building] = true
                    -- Capitalize first letter
                    local displayName = building:gsub("_", " "):gsub("^%l", string.upper)
                    table.insert(hints, displayName)
                    if #hints >= 3 then
                        break
                    end
                end
            end
        end
        if #hints >= 3 then
            break
        end
    end

    return hints
end

-- =============================================================================
-- SUPPLY SHORTAGES SECTION (Proactive Warnings)
-- =============================================================================

function DayEndSummaryModal:RenderShortagesSection(modalX, y)
    local summary = self.summary
    local hasShortages = summary.hasShortages
    local shortages = summary.shortages or {}
    local totalFailed = summary.totalFailedAllocations or 0

    -- Section header
    love.graphics.setFont(self.fonts.header)
    if hasShortages then
        love.graphics.setColor(self.colors.warning)  -- Orange for proactive warning
        love.graphics.print("!! SUPPLY SHORTAGES (" .. totalFailed .. " unmet requests)", modalX + 20, y)
    else
        love.graphics.setColor(self.colors.production)
        love.graphics.print("SUPPLY - All requests fulfilled!", modalX + 20, y)
    end
    y = y + 25

    if not hasShortages then
        return y + 5
    end

    -- Render top shortages (limit to 5 to keep modal manageable)
    local maxShortages = 5
    local count = 0
    for _, shortage in ipairs(shortages) do
        if count >= maxShortages then
            -- Show "and X more..." if there are more
            local remaining = #shortages - maxShortages
            if remaining > 0 then
                love.graphics.setFont(self.fonts.tiny)
                love.graphics.setColor(self.colors.textDim)
                love.graphics.print("  ... and " .. remaining .. " more shortage(s)", modalX + 20, y)
                y = y + 16
            end
            break
        end
        y = self:RenderShortageCard(modalX + 20, y, shortage)
        count = count + 1
    end

    return y + 10
end

function DayEndSummaryModal:RenderShortageCard(x, y, shortage)
    local cardWidth = self.modalWidth - 60
    local cardHeight = 50

    -- Use amber/orange colors (proactive warning, not critical yet)
    local bgColor = {0.4, 0.3, 0.1, 0.8}
    local textColor = self.colors.warning

    -- Card background
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, cardWidth, cardHeight, 5, 5)

    -- Left border
    love.graphics.setColor(textColor)
    love.graphics.rectangle("fill", x, y, 4, cardHeight, 5, 0)

    -- Commodity/dimension name (format nicely)
    local displayName = self:FormatShortageId(shortage.commodityId)

    -- Main text
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("[!] " .. displayName .. " shortage - " .. shortage.failedCount .. " requests unfulfilled",
        x + 15, y + 8)

    -- Citizens affected
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("    " .. shortage.citizenCount .. " citizen(s) affected", x + 15, y + 26)

    -- Hint
    local hint = self:GetHintForShortage(shortage.commodityId)
    if hint then
        love.graphics.setFont(self.fonts.tiny)
        love.graphics.setColor(self.colors.accent)
        local hintText = "Hint: " .. hint
        if #hintText > 70 then
            hintText = hintText:sub(1, 67) .. "..."
        end
        love.graphics.print(hintText, x + cardWidth - self.fonts.tiny:getWidth(hintText) - 10, y + 10)
    end

    return y + cardHeight + 6
end

function DayEndSummaryModal:FormatShortageId(id)
    if not id then return "Unknown" end

    -- Check if it's a fine dimension ID (contains underscores like "biological_nutrition_grain")
    if id:find("_") then
        -- It's a fine dimension - look up the label
        local fineHint = self.hints.fineHints and self.hints.fineHints[id]
        if fineHint and fineHint.issue then
            -- Capitalize first letter of issue
            local issue = fineHint.issue:gsub("^%l", string.upper)
            return issue
        end
        -- Fall back to formatting the ID
        return id:gsub("_", " "):gsub("(%a)([%w_']*)", function(first, rest)
            return first:upper() .. rest:lower()
        end)
    else
        -- It's a commodity ID - format it nicely
        return id:gsub("_", " "):gsub("(%a)([%w_']*)", function(first, rest)
            return first:upper() .. rest:lower()
        end)
    end
end

function DayEndSummaryModal:GetHintForShortage(id)
    if not id then return nil end

    -- Check if it's a fine dimension ID first
    if id:find("_") then
        local fineHint = self.hints.fineHints and self.hints.fineHints[id]
        if fineHint and fineHint.hint then
            return fineHint.hint
        end
    end

    -- Check commodity hints
    local commodityHints = self.hints.commodityHints
    if commodityHints and commodityHints[id] then
        return commodityHints[id].hint
    end

    -- No hint available
    return nil
end

function DayEndSummaryModal:RenderProductionSection(modalX, y)
    local summary = self.summary

    -- Section header
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.production)
    local totalProduced = summary.totalProduced or 0
    love.graphics.print("== PRODUCTION (" .. totalProduced .. " items)", modalX + 20, y)
    y = y + 22

    -- Production items
    if summary.produced and next(summary.produced) then
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.production)

        local itemsLine = ""
        local itemCount = 0
        for commodityId, qty in pairs(summary.produced) do
            if itemCount > 0 then
                itemsLine = itemsLine .. "  "
            end
            itemsLine = itemsLine .. commodityId .. " +" .. qty
            itemCount = itemCount + 1
            if itemCount >= 6 then
                love.graphics.print(itemsLine, modalX + 25, y)
                y = y + 16
                itemsLine = ""
                itemCount = 0
            end
        end
        if itemCount > 0 then
            love.graphics.print(itemsLine, modalX + 25, y)
            y = y + 16
        end
    else
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("No production recorded", modalX + 25, y)
        y = y + 16
    end

    return y + 10
end

function DayEndSummaryModal:RenderConsumptionSection(modalX, y)
    local summary = self.summary

    -- Section header
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.text)
    local totalCitizen = summary.totalConsumedByCitizens or 0
    local totalBuilding = summary.totalConsumedByBuildings or 0
    love.graphics.print("== CONSUMPTION (" .. (totalCitizen + totalBuilding) .. " items)", modalX + 20, y)
    y = y + 22

    -- Citizen consumption
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.citizenConsumption)
    if summary.consumedByCitizens and next(summary.consumedByCitizens) then
        local citizenLine = "Citizens: "
        local itemCount = 0
        for commodityId, qty in pairs(summary.consumedByCitizens) do
            if itemCount > 0 then
                citizenLine = citizenLine .. ", "
            end
            citizenLine = citizenLine .. commodityId .. " -" .. qty
            itemCount = itemCount + 1
            if itemCount >= 5 then
                break
            end
        end
        love.graphics.print(citizenLine, modalX + 25, y)
        y = y + 16
    else
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Citizens: No consumption recorded", modalX + 25, y)
        y = y + 16
    end

    -- Building consumption
    love.graphics.setColor(self.colors.buildingConsumption)
    if summary.consumedByBuildings and next(summary.consumedByBuildings) then
        local buildingLine = "Buildings: "
        local itemCount = 0
        for commodityId, qty in pairs(summary.consumedByBuildings) do
            if itemCount > 0 then
                buildingLine = buildingLine .. ", "
            end
            buildingLine = buildingLine .. commodityId .. " -" .. qty
            itemCount = itemCount + 1
            if itemCount >= 5 then
                break
            end
        end
        love.graphics.print(buildingLine, modalX + 25, y)
        y = y + 16
    else
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Buildings: No consumption recorded", modalX + 25, y)
        y = y + 16
    end

    return y + 10
end

function DayEndSummaryModal:RenderBottomControls(modalX, modalY, mx, my)
    -- Divider line
    local dividerY = modalY + self.modalHeight - 55
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(modalX + 20, dividerY, modalX + self.modalWidth - 20, dividerY)

    -- Checkbox for auto-show
    local checkboxSize = 16
    local checkboxX = modalX + 20
    local checkboxY = modalY + self.modalHeight - checkboxSize - 20

    self.checkboxHovered = mx >= checkboxX and mx <= checkboxX + checkboxSize and
                           my >= checkboxY and my <= checkboxY + checkboxSize

    -- Checkbox background
    if self.autoShowEnabled then
        love.graphics.setColor(self.colors.checkbox)
    else
        love.graphics.setColor(self.colors.checkboxActive)
    end
    love.graphics.rectangle("fill", checkboxX, checkboxY, checkboxSize, checkboxSize, 3, 3)

    -- Checkbox border
    love.graphics.setColor(self.checkboxHovered and 0.6 or 0.4, 0.6, 0.7)
    love.graphics.rectangle("line", checkboxX, checkboxY, checkboxSize, checkboxSize, 3, 3)

    -- Checkmark if disabled (inverted logic: checked = don't show)
    if not self.autoShowEnabled then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(self.fonts.small)
        love.graphics.print("X", checkboxX + 3, checkboxY + 1)
    end

    -- Checkbox label
    love.graphics.setColor(self.colors.textDim)
    love.graphics.setFont(self.fonts.small)
    love.graphics.print("Don't show this automatically", checkboxX + checkboxSize + 8, checkboxY + 1)

    -- OK Button
    local okBtnW = 80
    local okBtnH = 30
    local okBtnX = modalX + self.modalWidth - okBtnW - 20
    local okBtnY = modalY + self.modalHeight - okBtnH - 15

    self.okButtonHovered = mx >= okBtnX and mx <= okBtnX + okBtnW and
                           my >= okBtnY and my <= okBtnY + okBtnH

    love.graphics.setColor(self.okButtonHovered and self.colors.buttonHover or self.colors.button)
    love.graphics.rectangle("fill", okBtnX, okBtnY, okBtnW, okBtnH, 5, 5)

    love.graphics.setColor(0.5, 0.6, 0.7)
    love.graphics.rectangle("line", okBtnX, okBtnY, okBtnW, okBtnH, 5, 5)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.fonts.header)
    local okText = "OK"
    local okTextWidth = self.fonts.header:getWidth(okText)
    love.graphics.print(okText, okBtnX + (okBtnW - okTextWidth) / 2, okBtnY + 7)
end

return DayEndSummaryModal
