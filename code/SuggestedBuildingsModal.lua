--
-- SuggestedBuildingsModal.lua
-- Shows suggested buildings for remaining plots after elite immigration
--
-- ┌─────────────────────────────────────────────────────────────────────────────────┐
-- │ SUGGESTED BUILDINGS FOR Heinrich Mueller                                    [X] │
-- ├─────────────────────────────────────────────────────────────────────────────────┤
-- │ You have 3 remaining plots after your residence was placed.                     │
-- │ Here are some recommended buildings based on your intended role:                │
-- ├─────────────────────────────────────────────────────────────────────────────────┤
-- │ INCOME-GENERATING                                                               │
-- │ ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐               │
-- │ │ Workshop         │  │ Market Stall     │  │ Additional House │               │
-- │ │ [Cost: 300g]     │  │ [Cost: 250g]     │  │ [Cost: 400g]     │               │
-- │ │ Income: ~20g/day │  │ Income: ~15g/day │  │ Rent: ~10g/day   │               │
-- │ │ [BUILD]          │  │ [BUILD]          │  │ [BUILD]          │               │
-- │ └──────────────────┘  └──────────────────┘  └──────────────────┘               │
-- │                                                                                 │
-- │ STORAGE & UTILITY                                                               │
-- │ ┌──────────────────┐  ┌──────────────────┐                                     │
-- │ │ Warehouse        │  │ Granary          │                                     │
-- │ │ [Cost: 200g]     │  │ [Cost: 180g]     │                                     │
-- │ │ +50 storage      │  │ +100 food store  │                                     │
-- │ │ [BUILD]          │  │ [BUILD]          │                                     │
-- │ └──────────────────┘  └──────────────────┘                                     │
-- ├─────────────────────────────────────────────────────────────────────────────────┤
-- │ Your Wealth: 4380 gold                          [SKIP FOR NOW]  [VIEW PLOTS]    │
-- └─────────────────────────────────────────────────────────────────────────────────┘
--

local SuggestedBuildingsModal = {}
SuggestedBuildingsModal.__index = SuggestedBuildingsModal

function SuggestedBuildingsModal:Create(world, citizen, remainingPlots, onClose)
    local modal = setmetatable({}, SuggestedBuildingsModal)

    modal.world = world
    modal.citizen = citizen
    modal.remainingPlots = remainingPlots or {}
    modal.onClose = onClose

    -- Get suggested buildings based on citizen's intended role
    modal.suggestions = modal:GenerateSuggestions()

    -- UI State
    modal.scrollOffset = 0
    modal.maxScroll = 0
    modal.hoveredSuggestion = nil

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
        gold = {1.0, 0.85, 0.3},
        success = {0.4, 0.8, 0.4},
        warning = {1.0, 0.7, 0.3},
        danger = {1.0, 0.4, 0.4},
        button = {0.25, 0.25, 0.3},
        buttonHover = {0.35, 0.35, 0.4},
        cardBg = {0.15, 0.15, 0.18},
        cardHover = {0.2, 0.2, 0.25}
    }

    return modal
end

function SuggestedBuildingsModal:GenerateSuggestions()
    local suggestions = {
        income = {},
        utility = {}
    }

    -- Get building types from world
    local buildingTypes = self.world.buildingTypes or {}

    -- Define suggested building IDs by category
    local incomeBuildings = {"workshop", "market_stall", "townhouse", "bakery", "blacksmith"}
    local utilityBuildings = {"warehouse", "granary", "well", "lodge"}

    -- Filter available buildings and categorize
    for _, bType in ipairs(buildingTypes) do
        local suggestion = {
            typeId = bType.id,
            name = bType.name,
            cost = bType.baseCost or bType.constructionCost or 100,
            description = bType.description or "",
            category = bType.category or "other"
        }

        -- Add income estimate based on category
        if bType.category == "production" then
            suggestion.incomeEstimate = "~15-30g/day"
            table.insert(suggestions.income, suggestion)
        elseif bType.category == "commercial" or bType.id == "market_stall" then
            suggestion.incomeEstimate = "~10-20g/day"
            table.insert(suggestions.income, suggestion)
        elseif bType.category == "housing" and bType.id ~= "manor" and bType.id ~= "estate" then
            suggestion.incomeEstimate = "Rent: ~5-15g/day"
            table.insert(suggestions.income, suggestion)
        elseif bType.category == "storage" or bType.id == "warehouse" or bType.id == "granary" then
            suggestion.utilityDesc = "+Storage capacity"
            table.insert(suggestions.utility, suggestion)
        end
    end

    -- Limit to 4 per category
    while #suggestions.income > 4 do
        table.remove(suggestions.income)
    end
    while #suggestions.utility > 3 do
        table.remove(suggestions.utility)
    end

    return suggestions
end

function SuggestedBuildingsModal:Update(dt)
    -- Could add animations here
end

function SuggestedBuildingsModal:Render()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal dimensions
    local modalW = 700
    local modalH = 520
    local modalX = (screenW - modalW) / 2
    local modalY = (screenH - modalH) / 2

    -- Modal background
    love.graphics.setColor(self.colors.background)
    love.graphics.rectangle("fill", modalX, modalY, modalW, modalH, 8, 8)

    -- Modal border
    love.graphics.setColor(0.4, 0.5, 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", modalX, modalY, modalW, modalH, 8, 8)
    love.graphics.setLineWidth(1)

    -- Header
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("SUGGESTED BUILDINGS", modalX + 20, modalY + 15)

    -- Close button
    local closeX = modalX + modalW - 40
    local closeY = modalY + 10
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.danger)
    love.graphics.print("X", closeX + 8, closeY + 2)
    self.closeBtn = {x = closeX, y = closeY, w = 30, h = 30}

    -- Citizen info
    local infoY = modalY + 45
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("For: " .. (self.citizen.name or "New Citizen"), modalX + 20, infoY)

    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Remaining plots: " .. #self.remainingPlots, modalX + 250, infoY)

    -- Wealth display
    local wealth = 0
    if self.world.economicsSystem then
        wealth = self.world.economicsSystem:GetGold(self.citizen.id)
    end
    love.graphics.setColor(self.colors.gold)
    love.graphics.print("Wealth: " .. wealth .. " gold", modalX + 450, infoY)

    -- Description
    infoY = infoY + 25
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Your residence has been placed. Here are recommended buildings for your remaining plots:", modalX + 20, infoY)

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(modalX + 20, infoY + 22, modalX + modalW - 20, infoY + 22)

    -- Content area
    local contentY = infoY + 30
    local contentH = modalH - 160

    love.graphics.setScissor(modalX, contentY, modalW, contentH)

    local y = contentY - self.scrollOffset

    -- Income-generating buildings section
    if #self.suggestions.income > 0 then
        love.graphics.setFont(self.fonts.header)
        love.graphics.setColor(self.colors.accent)
        love.graphics.print("INCOME-GENERATING", modalX + 20, y)
        y = y + 25

        self:RenderBuildingCards(modalX + 20, y, modalW - 40, self.suggestions.income, "income")
        y = y + 120
    end

    -- Utility buildings section
    if #self.suggestions.utility > 0 then
        love.graphics.setFont(self.fonts.header)
        love.graphics.setColor(self.colors.accent)
        love.graphics.print("STORAGE & UTILITY", modalX + 20, y)
        y = y + 25

        self:RenderBuildingCards(modalX + 20, y, modalW - 40, self.suggestions.utility, "utility")
        y = y + 120
    end

    -- Calculate max scroll
    self.maxScroll = math.max(0, y - contentY - contentH + 50)

    love.graphics.setScissor()

    -- Bottom bar
    self:RenderBottomBar(modalX, modalY + modalH - 55, modalW)

    love.graphics.setColor(1, 1, 1)
end

function SuggestedBuildingsModal:RenderBuildingCards(x, y, w, buildings, category)
    local cardW = 155
    local cardH = 90
    local spacing = 10
    local cardsPerRow = math.floor(w / (cardW + spacing))

    self.buildingCards = self.buildingCards or {}
    self.buildingCards[category] = {}

    for i, building in ipairs(buildings) do
        local col = (i - 1) % cardsPerRow
        local cardX = x + col * (cardW + spacing)
        local cardY = y

        -- Card background
        local isHovered = self.hoveredSuggestion == building.typeId
        if isHovered then
            love.graphics.setColor(self.colors.cardHover)
        else
            love.graphics.setColor(self.colors.cardBg)
        end
        love.graphics.rectangle("fill", cardX, cardY, cardW, cardH, 4, 4)

        -- Card border
        love.graphics.setColor(0.3, 0.3, 0.35)
        love.graphics.rectangle("line", cardX, cardY, cardW, cardH, 4, 4)

        -- Building name
        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(self.colors.text)
        local displayName = building.name
        if #displayName > 18 then
            displayName = displayName:sub(1, 16) .. ".."
        end
        love.graphics.print(displayName, cardX + 8, cardY + 8)

        -- Cost
        love.graphics.setFont(self.fonts.tiny)
        love.graphics.setColor(self.colors.gold)
        love.graphics.print("Cost: " .. building.cost .. "g", cardX + 8, cardY + 28)

        -- Income/utility description
        love.graphics.setColor(self.colors.success)
        if building.incomeEstimate then
            love.graphics.print(building.incomeEstimate, cardX + 8, cardY + 42)
        elseif building.utilityDesc then
            love.graphics.print(building.utilityDesc, cardX + 8, cardY + 42)
        end

        -- Build button
        local btnY = cardY + cardH - 25
        local btnW = cardW - 16
        local btnH = 18

        -- Check if can afford
        local wealth = 0
        if self.world.economicsSystem then
            wealth = self.world.economicsSystem:GetGold(self.citizen.id)
        end
        local canAfford = wealth >= building.cost

        if canAfford then
            love.graphics.setColor(0.2, 0.4, 0.3)
        else
            love.graphics.setColor(0.3, 0.3, 0.3)
        end
        love.graphics.rectangle("fill", cardX + 8, btnY, btnW, btnH, 3, 3)

        love.graphics.setColor(1, 1, 1, canAfford and 1 or 0.5)
        love.graphics.setFont(self.fonts.tiny)
        love.graphics.print("BUILD", cardX + 8 + btnW/2 - 15, btnY + 3)

        -- Store card bounds
        table.insert(self.buildingCards[category], {
            x = cardX, y = cardY, w = cardW, h = cardH,
            building = building,
            btnX = cardX + 8, btnY = btnY, btnW = btnW, btnH = btnH,
            canAfford = canAfford
        })
    end
end

function SuggestedBuildingsModal:RenderBottomBar(x, y, w)
    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x + 20, y, x + w - 20, y)

    -- Action buttons
    local btnW = 110
    local btnH = 32
    local btnY = y + 12

    -- Skip button
    local skipX = x + w - btnW * 2 - 25
    love.graphics.setColor(self.colors.textDim[1], self.colors.textDim[2], self.colors.textDim[3], 0.7)
    love.graphics.rectangle("fill", skipX, btnY, btnW, btnH, 4, 4)
    love.graphics.setColor(self.colors.text)
    love.graphics.setFont(self.fonts.normal)
    local skipText = "SKIP FOR NOW"
    local skipTextW = self.fonts.normal:getWidth(skipText)
    love.graphics.print(skipText, skipX + (btnW - skipTextW) / 2, btnY + 8)
    self.skipBtn = {x = skipX, y = btnY, w = btnW, h = btnH}

    -- View plots button (opens land overlay)
    local viewX = x + w - btnW - 15
    love.graphics.setColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 0.8)
    love.graphics.rectangle("fill", viewX, btnY, btnW, btnH, 4, 4)
    love.graphics.setColor(1, 1, 1)
    local viewText = "VIEW PLOTS"
    local viewTextW = self.fonts.normal:getWidth(viewText)
    love.graphics.print(viewText, viewX + (btnW - viewTextW) / 2, btnY + 8)
    self.viewPlotsBtn = {x = viewX, y = btnY, w = btnW, h = btnH}
end

function SuggestedBuildingsModal:HandleClick(x, y, button)
    -- Close button
    if self.closeBtn then
        local btn = self.closeBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            if self.onClose then self.onClose() end
            return true
        end
    end

    -- Skip button
    if self.skipBtn then
        local btn = self.skipBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            if self.onClose then self.onClose() end
            return true
        end
    end

    -- View plots button
    if self.viewPlotsBtn then
        local btn = self.viewPlotsBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            -- Close modal and trigger land overlay
            if self.onClose then self.onClose("view_land") end
            return true
        end
    end

    -- Building card build buttons
    if self.buildingCards then
        for category, cards in pairs(self.buildingCards) do
            for _, card in ipairs(cards) do
                -- Check build button
                if card.canAfford and x >= card.btnX and x < card.btnX + card.btnW and
                   y >= card.btnY and y < card.btnY + card.btnH then
                    -- Trigger building placement mode
                    if self.onClose then
                        self.onClose("build", card.building.typeId)
                    end
                    return true
                end
            end
        end
    end

    return true  -- Consume click
end

function SuggestedBuildingsModal:HandleMouseWheel(x, y, dx, dy)
    self.scrollOffset = math.max(0, math.min(self.maxScroll, self.scrollOffset - dy * 30))
    return true
end

function SuggestedBuildingsModal:HandleMouseMove(x, y)
    -- Update hover state for building cards
    self.hoveredSuggestion = nil

    if self.buildingCards then
        for category, cards in pairs(self.buildingCards) do
            for _, card in ipairs(cards) do
                if x >= card.x and x < card.x + card.w and y >= card.y and y < card.y + card.h then
                    self.hoveredSuggestion = card.building.typeId
                    return
                end
            end
        end
    end
end

function SuggestedBuildingsModal:HandleKeyPress(key)
    if key == "escape" then
        if self.onClose then self.onClose() end
        return true
    end
    return false
end

return SuggestedBuildingsModal
