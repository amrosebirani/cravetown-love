--
-- CharacterDetailPanel.lua
-- Comprehensive character detail modal for Alpha game mode
-- Merges TODO.md Section 4 requirements with Phase 8 Housing/Economics
--
-- ┌────────────────────────────────────────────────────────────────────────────────┐
-- │                        CHARACTER DETAILS: John Smith                            │
-- │                                                            [Edit Mode] [X]      │
-- ├────────────────────────────────────────────────────────────────────────────────┤
-- │ ┌──────────────────────────────────────────────────────────────────────────┐   │
-- │ │ IDENTITY & ENABLEMENTS                                                    │   │
-- │ │ Name: John Smith    Class: Merchant    Age: 34    Vocation: Baker        │   │
-- │ │ Traits: Glutton, Ambitious                                                │   │
-- │ │ Enablements: Luxury Goods, Fine Dining                                    │   │
-- │ └──────────────────────────────────────────────────────────────────────────┘   │
-- │                                                                                 │
-- │ ┌──────────────────────────────────────────────────────────────────────────┐   │
-- │ │ SATISFACTION (9 Dimensions)                      [Expand All] [Collapse] │   │
-- │ │ > Biological    ████████░░░░░░░░  65%  Sat |  Craving: 12.5 (B:2.1)     │   │
-- │ │ v Safety        ██████████░░░░░░  78%  Sat |  Craving: 8.2  (B:1.5)     │   │
-- │ │     safety_shelter    ████░░░░░░  B:0.5  C:3.2                           │   │
-- │ │     safety_security   ██████░░░░  B:0.8  C:5.0                           │   │
-- │ │ > Touch         ████████████░░░░  85%  Sat |  Craving: 5.1  (B:0.9)     │   │
-- │ │ > Psychological ██████░░░░░░░░░░  45%  Sat |  Craving: 22.3 (B:3.2)     │   │
-- │ │ ... (5 more dimensions)                                                   │   │
-- │ │ Average Satisfaction: 67.2                                                │   │
-- │ └──────────────────────────────────────────────────────────────────────────┘   │
-- │                                                                                 │
-- │ ┌──────────────────────────────────────────────────────────────────────────┐   │
-- │ │ TOP CURRENT CRAVINGS                                                      │   │
-- │ │ 1. psychological_esteem  15.2    2. biological_food    12.8              │   │
-- │ │ 3. social_belonging       9.5    4. safety_shelter      8.1              │   │
-- │ │ ... (6 more)                                                              │   │
-- │ └──────────────────────────────────────────────────────────────────────────┘   │
-- │                                                                                 │
-- │ ┌──────────────────────────────────────────────────────────────────────────┐   │
-- │ │ COMMODITY FATIGUE (Top 10 Most Consumed)                                  │   │
-- │ │ bread:     ████████░░  80% effective (tired)                             │   │
-- │ │            Consumed: 5x consecutive, Last: Cycle 42                       │   │
-- │ │ fish:      ██████████  98% effective (fresh)                             │   │
-- │ │            Consumed: 1x consecutive, Last: Cycle 44                       │   │
-- │ │ ... (8 more)                                                              │   │
-- │ └──────────────────────────────────────────────────────────────────────────┘   │
-- │                                                                                 │
-- │ ┌──────────────────────────────────────────────────────────────────────────┐   │
-- │ │ CONSUMPTION HISTORY (Last 20 Cycles)                                      │   │
-- │ │ * Cycle 44: Consumed bread (80% effective)                               │   │
-- │ │   -> biological_food +8.0, biological_comfort +2.0                       │   │
-- │ │ + Cycle 43: Acquired furniture (durable)                                  │   │
-- │ │ x Cycle 42: FAILED (no allocation)                                        │   │
-- │ │ ... (scrollable)                                                          │   │
-- │ └──────────────────────────────────────────────────────────────────────────┘   │
-- │                                                                                 │
-- │ ┌──────────────────────────────────────────────────────────────────────────┐   │
-- │ │ POSSESSIONS (Durables & Permanents)                                       │   │
-- │ │ furniture [DURABLE]     (household)                                       │   │
-- │ │   Effectiveness: ████████░░  85%    Remaining: 12/20 cycles              │   │
-- │ │ house [PERMANENT]       (shelter)                                         │   │
-- │ │   Effectiveness: ██████████ 100%                                          │   │
-- │ └──────────────────────────────────────────────────────────────────────────┘   │
-- │                                                                                 │
-- │ ┌──────────────────────────────────────────────────────────────────────────┐   │
-- │ │ ECONOMY & WEALTH                                          [NEW SECTION]  │   │
-- │ │ ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐            │   │
-- │ │ │ Current Wealth  │  │ Income/Cycle    │  │ Expenses/Cycle  │            │   │
-- │ │ │    1,250 gold   │  │    +45 gold     │  │    -32 gold     │            │   │
-- │ │ └─────────────────┘  └─────────────────┘  └─────────────────┘            │   │
-- │ │                                                                           │   │
-- │ │ Net Savings: +13 gold/cycle                                               │   │
-- │ │ Wealth Rank: #3 of 24 citizens                                            │   │
-- │ │                                                                           │   │
-- │ │ Capital Ratio: 35% (Liquid: 812g, Fixed: 438g)                           │   │
-- │ │ Emergent Class: MERCHANT (Net Worth: 1,250g, Capital: 35%)               │   │
-- │ │                                                                           │   │
-- │ │ Land Owned: 3 plots (value: 300g)                                         │   │
-- │ │ Buildings Owned: 1 (Bakery - value: 500g)                                │   │
-- │ └──────────────────────────────────────────────────────────────────────────┘   │
-- │                                                                                 │
-- │ ┌──────────────────────────────────────────────────────────────────────────┐   │
-- │ │ HOUSING                                                   [NEW SECTION]  │   │
-- │ │ Current Residence: Stone House #4                                         │   │
-- │ │ Quality Tier: ★★★☆☆ (3/5)                                                │   │
-- │ │ Monthly Rent: 15 gold                                                     │   │
-- │ │ Rent Status: PAID ✓                                                       │   │
-- │ │                                                                           │   │
-- │ │ Housing Satisfaction: 72%                                                 │   │
-- │ │ ┌─────────────────────────────────────────────────────────┐              │   │
-- │ │ │ Quality Match:  ████████░░  (tier matches class)        │              │   │
-- │ │ │ Space:          ██████░░░░  (1 of 2 occupants)          │              │   │
-- │ │ │ Location:       █████████░  (near workplace)            │              │   │
-- │ │ └─────────────────────────────────────────────────────────┘              │   │
-- │ │                                                                           │   │
-- │ │ [Request Relocation]  [View Available Housing]                           │   │
-- │ └──────────────────────────────────────────────────────────────────────────┘   │
-- │                                                                                 │
-- │ ┌──────────────────────────────────────────────────────────────────────────┐   │
-- │ │ STATUS & RISKS                                                            │   │
-- │ │ Protesting: No     Emigrated: No     Status: CONTENT                     │   │
-- │ │ Productivity: 95%  Priority: 2.3                                          │   │
-- │ │ Consecutive Failures: 0                                                   │   │
-- │ │ Emigration Risk: Low    Protest Risk: Low                                │   │
-- │ └──────────────────────────────────────────────────────────────────────────┘   │
-- │                                                                                 │
-- │ [Edit Mode Actions: Reset Cravings | Reset Satisfaction | Trigger Events]      │
-- └────────────────────────────────────────────────────────────────────────────────┘
--
-- SECTIONS:
-- 1. Identity & Enablements - Name, class, age, vocation, traits, enablements
-- 2. Satisfaction - 9 coarse dimensions with expandable 49 fine dimensions
-- 3. Top Current Cravings - Top 10 most urgent cravings
-- 4. Commodity Fatigue - Consumption fatigue with effectiveness bars
-- 5. Consumption History - Last 20 cycles with success/failure indicators
-- 6. Possessions - Durables & permanents with condition/remaining cycles
-- 7. Economy & Wealth - NEW: Net worth, income, expenses, class calculation
-- 8. Housing - NEW: Current residence, rent, satisfaction breakdown
-- 9. Status & Risks - Emigration/protest risk, productivity, priority
--

local CharacterDetailPanel = {}
CharacterDetailPanel.__index = CharacterDetailPanel

-- Import CharacterV2 for craving dimension mappings
local CharacterV2 = require("code.CharacterV2")

function CharacterDetailPanel:Create(world)
    local panel = setmetatable({}, CharacterDetailPanel)

    panel.world = world
    panel.visible = false
    panel.character = nil
    panel.scrollOffset = 0
    panel.maxScroll = 0
    panel.editMode = false

    -- Expanded dimension tracking
    panel.expandedDimensions = {}

    -- Colors
    panel.colors = {
        background = {0.12, 0.12, 0.15, 0.98},
        border = {0.3, 0.5, 0.7, 1},
        headerBg = {0.15, 0.18, 0.22, 1},
        sectionBg = {0.1, 0.1, 0.12, 0.8},
        sectionBorder = {0.25, 0.3, 0.35, 0.8},
        text = {1, 1, 1, 1},
        textDim = {0.7, 0.7, 0.7, 1},
        textMuted = {0.5, 0.5, 0.5, 1},
        gold = {0.98, 0.85, 0.37, 1},
        green = {0.4, 0.8, 0.4, 1},
        red = {0.9, 0.4, 0.4, 1},
        yellow = {0.9, 0.8, 0.3, 1},
        blue = {0.4, 0.6, 0.9, 1},
        purple = {0.7, 0.5, 0.9, 1},
    }

    -- Coarse dimension names for satisfaction display
    panel.coarseNames = {
        "Biological", "Safety", "Touch", "Psychological",
        "Social Status", "Social Connection", "Exotic Goods",
        "Shiny Objects", "Vice"
    }
    panel.coarseKeys = {
        "biological", "safety", "touch", "psychological",
        "social_status", "social_connection", "exotic_goods",
        "shiny_objects", "vice"
    }

    -- Fonts (initialized on first render)
    panel.fonts = nil

    return panel
end

function CharacterDetailPanel:InitFonts()
    if not self.fonts then
        self.fonts = {
            title = love.graphics.newFont(16),
            header = love.graphics.newFont(13),
            normal = love.graphics.newFont(11),
            small = love.graphics.newFont(10),
            tiny = love.graphics.newFont(9),
        }
    end
end

function CharacterDetailPanel:Show(character)
    self.character = character
    self.visible = true
    self.scrollOffset = 0
    self.editMode = false
    self.expandedDimensions = {}
end

function CharacterDetailPanel:Hide()
    self.visible = false
    self.character = nil
    self.editMode = false
end

function CharacterDetailPanel:IsVisible()
    return self.visible
end

function CharacterDetailPanel:Toggle(character)
    if self.visible and self.character == character then
        self:Hide()
    else
        self:Show(character)
    end
end

function CharacterDetailPanel:Render()
    if not self.visible or not self.character then return end

    self:InitFonts()

    local char = self.character
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Modal dimensions
    local w = math.min(950, screenW - 40)
    local h = math.min(780, screenH - 40)
    local x = (screenW - w) / 2
    local y = (screenH - h) / 2

    -- Backdrop
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal background
    love.graphics.setColor(self.colors.background)
    love.graphics.rectangle("fill", x, y, w, h, 8, 8)
    love.graphics.setColor(self.colors.border)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 8, 8)

    -- Title bar
    love.graphics.setColor(self.colors.headerBg)
    love.graphics.rectangle("fill", x, y, w, 45, 8, 8)
    love.graphics.rectangle("fill", x, y + 35, w, 10)

    -- Title
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("CHARACTER DETAILS: " .. (char.name or "Unknown"), x + 20, y + 12)

    -- Edit mode toggle button
    local editBtnColor = self.editMode and {0.8, 0.5, 0.2} or {0.3, 0.5, 0.3}
    self:RenderButton(self.editMode and "Exit Edit" or "Edit Mode",
        x + w - 170, y + 10, 75, 26, function()
            self.editMode = not self.editMode
        end, editBtnColor)

    -- Close button
    self:RenderButton("X", x + w - 40, y + 10, 30, 26, function()
        self:Hide()
    end, {0.6, 0.3, 0.3})

    -- Content area with scroll
    local contentX = x + 15
    local contentY = y + 55
    local contentW = w - 30
    local contentH = h - 65

    -- Set up scissor for scrollable content
    love.graphics.setScissor(contentX, contentY, contentW, contentH)

    local scrollY = contentY - self.scrollOffset
    local padding = 12

    -- Render all sections
    scrollY = self:RenderIdentitySection(contentX, scrollY, contentW, char)
    scrollY = scrollY + padding

    scrollY = self:RenderSatisfactionSection(contentX, scrollY, contentW, char)
    scrollY = scrollY + padding

    scrollY = self:RenderTopCravingsSection(contentX, scrollY, contentW, char)
    scrollY = scrollY + padding

    scrollY = self:RenderFatigueSection(contentX, scrollY, contentW, char)
    scrollY = scrollY + padding

    scrollY = self:RenderHistorySection(contentX, scrollY, contentW, char)
    scrollY = scrollY + padding

    scrollY = self:RenderPossessionsSection(contentX, scrollY, contentW, char)
    scrollY = scrollY + padding

    scrollY = self:RenderEconomySection(contentX, scrollY, contentW, char)
    scrollY = scrollY + padding

    scrollY = self:RenderHousingSection(contentX, scrollY, contentW, char)
    scrollY = scrollY + padding

    scrollY = self:RenderStatusSection(contentX, scrollY, contentW, char)

    -- Calculate max scroll
    self.maxScroll = math.max(0, scrollY - contentY + self.scrollOffset - contentH + 20)

    -- Reset scissor
    love.graphics.setScissor()

    -- Scroll indicator
    if self.maxScroll > 0 then
        local scrollBarH = contentH * (contentH / (contentH + self.maxScroll))
        local scrollBarY = contentY + (self.scrollOffset / self.maxScroll) * (contentH - scrollBarH)
        love.graphics.setColor(0.4, 0.5, 0.6, 0.6)
        love.graphics.rectangle("fill", x + w - 10, scrollBarY, 6, scrollBarH, 3, 3)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- =============================================================================
-- SECTION 1: Identity & Enablements
-- =============================================================================
function CharacterDetailPanel:RenderIdentitySection(x, y, w, char)
    local startY = y

    -- Section header
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.4, 0.6, 0.8)
    love.graphics.print("IDENTITY & ENABLEMENTS", x, y)
    y = y + 20

    -- Basic info row
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Name: " .. (char.name or "Unknown"), x, y)
    love.graphics.print("Class: " .. (char.class or char.emergentClass or "Unknown"), x + 180, y)
    love.graphics.print("Age: " .. (char.age or "?"), x + 340, y)
    love.graphics.print("Vocation: " .. (char.vocation or "None"), x + 420, y)
    y = y + 18

    -- Traits
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Traits: ", x, y)
    local traitStr = "None"
    if char.traits and #char.traits > 0 then
        traitStr = table.concat(char.traits, ", ")
    end
    love.graphics.setColor(0.6, 0.75, 0.8)
    love.graphics.print(traitStr, x + 45, y)
    y = y + 16

    -- Enablements
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Enablements: ", x, y)
    local enableStr = "Standard access"
    if char.appliedEnablements and next(char.appliedEnablements) then
        local enabled = {}
        for ruleId, _ in pairs(char.appliedEnablements) do
            table.insert(enabled, ruleId)
        end
        enableStr = table.concat(enabled, ", ")
    end
    love.graphics.setColor(0.6, 0.7, 0.6)
    love.graphics.print(enableStr, x + 78, y)
    y = y + 18

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x, y, x + w, y)

    return y + 5
end

-- =============================================================================
-- SECTION 2: Satisfaction (9 Dimensions with Expandable 49)
-- =============================================================================
function CharacterDetailPanel:RenderSatisfactionSection(x, y, w, char)
    -- Section header
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.4, 0.8, 0.6)
    love.graphics.print("SATISFACTION (9 Dimensions)", x, y)

    -- Expand/Collapse all buttons
    local allExpanded = true
    local anyExpanded = false
    for i = 0, 8 do
        if self.expandedDimensions[i] then anyExpanded = true else allExpanded = false end
    end

    self:RenderButton(allExpanded and "Collapse All" or "Expand All",
        x + w - 85, y - 2, 80, 18, function()
            if allExpanded then
                self.expandedDimensions = {}
            else
                for i = 0, 8 do self.expandedDimensions[i] = true end
            end
        end, {0.3, 0.4, 0.5})

    y = y + 22

    local barW = w - 220
    local barH = 8

    for i, key in ipairs(self.coarseKeys) do
        local coarseIdx = i - 1
        local satValue = char.satisfaction and char.satisfaction[key] or 0
        local isExpanded = self.expandedDimensions[coarseIdx]

        -- Calculate coarse-level cravings
        local coarseCurrentCraving = 0
        local coarseBaseCraving = 0
        local fineIndices = CharacterV2.coarseToFineMap and CharacterV2.coarseToFineMap[coarseIdx]
        if fineIndices then
            for _, fineIdx in ipairs(fineIndices) do
                coarseCurrentCraving = coarseCurrentCraving + (char.currentCravings and char.currentCravings[fineIdx] or 0)
                coarseBaseCraving = coarseBaseCraving + (char.baseCravings and char.baseCravings[fineIdx] or 0)
            end
        end

        -- Expand/collapse arrow
        local arrow = isExpanded and "v" or ">"
        self:RenderButton(arrow, x, y - 2, 16, 16, function()
            self.expandedDimensions[coarseIdx] = not self.expandedDimensions[coarseIdx]
        end, {0.25, 0.35, 0.45})

        -- Dimension name
        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(0.85, 0.85, 0.85)
        love.graphics.print(self.coarseNames[i], x + 20, y)
        y = y + 16

        -- Satisfaction bar
        local barX = x + 90
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("Sat", x + 25, y + 1)

        -- Bar background
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", barX, y + 2, barW, barH, 2, 2)

        -- Bar fill
        local satFill = math.min(math.max(satValue, 0), 100) / 100 * barW
        local r, g, b = self:GetSatisfactionColor(satValue)
        love.graphics.setColor(r, g, b)
        love.graphics.rectangle("fill", barX, y + 2, satFill, barH, 2, 2)

        -- Value
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(string.format("%.0f%%", satValue), barX + barW + 8, y)

        -- Craving info
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print(string.format("C:%.1f (B:%.1f)", coarseCurrentCraving, coarseBaseCraving),
            barX + barW + 50, y)
        y = y + 14

        -- Show fine dimensions if expanded
        if isExpanded and fineRange then
            love.graphics.setFont(self.fonts.tiny)
            for fineIdx = fineRange.start, fineRange.finish do
                local fineName = CharacterV2.fineNames and CharacterV2.fineNames[fineIdx] or ("fine_" .. fineIdx)
                local fineValue = char.currentCravings and char.currentCravings[fineIdx] or 0
                local baseCraving = char.baseCravings and char.baseCravings[fineIdx] or 0

                -- Shorten name
                local shortName = fineName:gsub("^%w+_", "")

                love.graphics.setColor(0.5, 0.5, 0.55)
                love.graphics.print("    " .. shortName, x + 30, y)

                -- Mini bar
                local miniBarX = x + 200
                local miniBarW = 120
                love.graphics.setColor(0.18, 0.18, 0.22)
                love.graphics.rectangle("fill", miniBarX, y + 2, miniBarW, 6, 2, 2)

                local maxCraving = math.max(baseCraving * 50, 50)
                local fillW = math.min(fineValue / maxCraving, 1.0) * miniBarW
                if fillW > 0 then
                    local intensity = fineValue / maxCraving
                    love.graphics.setColor(0.3 + intensity * 0.6, 0.7 - intensity * 0.4, 0.3)
                    love.graphics.rectangle("fill", miniBarX, y + 2, fillW, 6, 2, 2)
                end

                love.graphics.setColor(0.6, 0.6, 0.6)
                love.graphics.print(string.format("B:%.1f C:%.0f", baseCraving, fineValue),
                    miniBarX + miniBarW + 8, y)
                y = y + 12
            end
            y = y + 4
        end

        y = y + 4
    end

    -- Average satisfaction
    local avgSat = 0
    if char.GetAverageSatisfaction then
        avgSat = char:GetAverageSatisfaction()
    elseif char.satisfaction then
        local total, count = 0, 0
        for _, key in ipairs(self.coarseKeys) do
            if char.satisfaction[key] then
                total = total + char.satisfaction[key]
                count = count + 1
            end
        end
        avgSat = count > 0 and (total / count) or 0
    end

    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(0.8, 0.8, 0.4)
    love.graphics.print(string.format("Average Satisfaction: %.1f%%", avgSat), x, y)
    y = y + 20

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x, y, x + w, y)

    return y + 5
end

-- =============================================================================
-- SECTION 3: Top Current Cravings
-- =============================================================================
function CharacterDetailPanel:RenderTopCravingsSection(x, y, w, char)
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.8, 0.6, 0.4)
    love.graphics.print("TOP CURRENT CRAVINGS", x, y)
    y = y + 20

    -- Get top 10 cravings
    local cravingsList = {}
    if char.currentCravings then
        for i = 0, 48 do
            local craving = char.currentCravings[i] or 0
            if craving > 0.1 then
                local fineName = CharacterV2.fineNames and CharacterV2.fineNames[i] or ("dim_" .. i)
                table.insert(cravingsList, {index = i, name = fineName, value = craving})
            end
        end
    end
    table.sort(cravingsList, function(a, b) return a.value > b.value end)

    love.graphics.setFont(self.fonts.small)
    if #cravingsList == 0 then
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("No significant cravings", x, y)
        y = y + 16
    else
        for i = 1, math.min(10, #cravingsList) do
            local craving = cravingsList[i]
            local col = (i - 1) % 2
            local row = math.floor((i - 1) / 2)
            local cx = x + col * (w / 2)
            local cy = y + row * 16

            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.print(i .. ". " .. craving.name, cx, cy)
            love.graphics.setColor(0.9, 0.7, 0.4)
            love.graphics.print(string.format("%.1f", craving.value), cx + 170, cy)
        end
        y = y + math.ceil(math.min(10, #cravingsList) / 2) * 16 + 8
    end

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x, y, x + w, y)

    return y + 5
end

-- =============================================================================
-- SECTION 4: Commodity Fatigue
-- =============================================================================
function CharacterDetailPanel:RenderFatigueSection(x, y, w, char)
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.6, 0.4, 0.8)
    love.graphics.print("COMMODITY FATIGUE (Top 10 Most Consumed)", x, y)
    y = y + 22

    local fatigueList = {}
    if char.commodityMultipliers then
        for commodity, data in pairs(char.commodityMultipliers) do
            table.insert(fatigueList, {
                commodity = commodity,
                multiplier = data.multiplier or 1.0,
                consecutiveCount = data.consecutiveCount or 0,
                lastConsumed = data.lastConsumed or 0
            })
        end
    end
    table.sort(fatigueList, function(a, b) return a.consecutiveCount > b.consecutiveCount end)

    love.graphics.setFont(self.fonts.small)
    if #fatigueList == 0 then
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("No consumption data yet", x, y)
        y = y + 18
    else
        local maxToShow = math.min(10, #fatigueList)
        for i = 1, maxToShow do
            local fatigue = fatigueList[i]

            -- Commodity name
            love.graphics.setColor(0.85, 0.85, 0.85)
            love.graphics.print(fatigue.commodity .. ":", x, y)

            -- Effectiveness bar
            local barX = x + 100
            local barW = 80
            local barH = 12
            love.graphics.setColor(0.2, 0.2, 0.25)
            love.graphics.rectangle("fill", barX, y + 1, barW, barH)

            local effectiveness = fatigue.multiplier
            local fillW = effectiveness * barW
            if effectiveness >= 0.8 then
                love.graphics.setColor(0.3, 0.7, 0.3)
            elseif effectiveness >= 0.5 then
                love.graphics.setColor(0.7, 0.7, 0.3)
            else
                love.graphics.setColor(0.8, 0.3, 0.3)
            end
            love.graphics.rectangle("fill", barX, y + 1, fillW, barH)

            -- Status text
            local statusText = effectiveness >= 0.95 and "fresh" or
                              (effectiveness >= 0.7 and "tired" or "VERY TIRED")
            local statusColor = effectiveness >= 0.95 and self.colors.green or
                               (effectiveness >= 0.7 and self.colors.yellow or self.colors.red)
            love.graphics.setColor(statusColor)
            love.graphics.print(string.format("%.0f%% (%s)", effectiveness * 100, statusText),
                barX + barW + 10, y)
            y = y + 14

            -- Consumption count
            love.graphics.setColor(self.colors.textMuted)
            love.graphics.print(string.format("  %dx consecutive, Last: Cycle %d",
                fatigue.consecutiveCount, fatigue.lastConsumed), x, y)
            y = y + 16
        end
    end

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x, y, x + w, y)

    return y + 5
end

-- =============================================================================
-- SECTION 5: Consumption History
-- =============================================================================
function CharacterDetailPanel:RenderHistorySection(x, y, w, char)
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.4, 0.7, 0.7)
    love.graphics.print("CONSUMPTION HISTORY (Last 20 Cycles)", x, y)
    y = y + 20

    local history = char.consumptionHistory or {}

    love.graphics.setFont(self.fonts.small)
    if #history == 0 then
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("No consumption history yet", x, y)
        y = y + 16
    else
        local maxToShow = math.min(20, #history)
        for i = 1, maxToShow do
            local entry = history[i]

            if entry.commodity then
                local isAcquired = entry.allocationType == "acquired"
                local effectiveness = entry.fatigueMultiplier or 1.0

                if isAcquired then
                    love.graphics.setColor(self.colors.purple)
                    love.graphics.print("+", x, y)
                else
                    love.graphics.setColor(self.colors.green)
                    love.graphics.print("*", x, y)
                end

                -- Color based on effectiveness
                if effectiveness >= 0.8 then
                    love.graphics.setColor(0.7, 0.9, 0.7)
                elseif effectiveness >= 0.5 then
                    love.graphics.setColor(0.9, 0.9, 0.6)
                else
                    love.graphics.setColor(0.9, 0.6, 0.6)
                end

                local actionText = isAcquired and "Acquired" or "Consumed"
                love.graphics.print(string.format("Cycle %d: %s %s (%.0f%% effective)",
                    entry.cycle or 0, actionText, entry.commodity, effectiveness * 100), x + 12, y)
            else
                love.graphics.setColor(self.colors.red)
                love.graphics.print("x", x, y)
                love.graphics.print(string.format("Cycle %d: FAILED (no allocation)", entry.cycle or 0), x + 12, y)
            end
            y = y + 14
        end
    end

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x, y, x + w, y)

    return y + 5
end

-- =============================================================================
-- SECTION 6: Possessions
-- =============================================================================
function CharacterDetailPanel:RenderPossessionsSection(x, y, w, char)
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.7, 0.5, 0.8)
    love.graphics.print("POSSESSIONS (Durables & Permanents)", x, y)
    y = y + 20

    local activeEffects = char.activeEffects or {}

    love.graphics.setFont(self.fonts.small)
    if #activeEffects == 0 then
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("No possessions", x, y)
        y = y + 16
    else
        for _, effect in ipairs(activeEffects) do
            -- Name and durability badge
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.print(effect.commodityId or "Unknown", x, y)

            local badgeX = x + 100
            if effect.durability == "permanent" then
                love.graphics.setColor(0.4, 0.8, 0.9)
                love.graphics.print("[PERMANENT]", badgeX, y)
            else
                love.graphics.setColor(0.8, 0.7, 0.4)
                love.graphics.print("[DURABLE]", badgeX, y)
            end

            love.graphics.setColor(self.colors.textMuted)
            love.graphics.print("(" .. (effect.category or "unknown") .. ")", badgeX + 80, y)
            y = y + 14

            -- Effectiveness bar
            local effectiveness = effect.currentEffectiveness or 1.0
            love.graphics.setColor(self.colors.textMuted)
            love.graphics.print("  Effectiveness:", x, y)

            local effBarX = x + 100
            local effBarW = 100
            love.graphics.setColor(0.2, 0.2, 0.25)
            love.graphics.rectangle("fill", effBarX, y + 2, effBarW, 8)

            if effectiveness >= 0.8 then
                love.graphics.setColor(0.3, 0.7, 0.3)
            elseif effectiveness >= 0.5 then
                love.graphics.setColor(0.7, 0.7, 0.3)
            else
                love.graphics.setColor(0.7, 0.4, 0.3)
            end
            love.graphics.rectangle("fill", effBarX, y + 2, effectiveness * effBarW, 8)

            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.print(string.format("%.0f%%", effectiveness * 100), effBarX + effBarW + 8, y)

            -- Remaining cycles for durables
            if effect.durability == "durable" and effect.remainingCycles then
                local remaining = effect.remainingCycles
                local total = effect.durationCycles or remaining
                love.graphics.setColor(self.colors.textDim)
                love.graphics.print(string.format("  Remaining: %d/%d cycles", remaining, total),
                    effBarX + effBarW + 50, y)
            end
            y = y + 16
        end
    end

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x, y, x + w, y)

    return y + 5
end

-- =============================================================================
-- SECTION 7: Economy & Wealth (NEW - from TODO.md)
-- =============================================================================
function CharacterDetailPanel:RenderEconomySection(x, y, w, char)
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.gold)
    love.graphics.print("ECONOMY & WEALTH", x, y)

    -- NEW badge
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(0.3, 0.6, 0.3)
    love.graphics.print("[NEW]", x + 140, y + 2)

    y = y + 22

    -- Get economic data from world systems
    local economySystem = self.world and self.world.economySystem
    local landSystem = self.world and self.world.landSystem
    local housingSystem = self.world and self.world.housingSystem

    -- Current wealth (liquid assets)
    local liquidWealth = char.wealth or char.gold or 0

    -- Calculate fixed assets (land + buildings)
    local landValue = 0
    local landCount = 0
    local buildingValue = 0
    local buildingCount = 0

    if landSystem and landSystem.plots then
        for _, plot in pairs(landSystem.plots) do
            if plot.ownerId == char.id then
                landValue = landValue + (plot.currentValue or plot.purchasePrice or 100)
                landCount = landCount + 1
            end
        end
    end

    if self.world and self.world.buildings then
        for _, building in pairs(self.world.buildings) do
            if building.ownerId == char.id then
                buildingValue = buildingValue + (building.value or 500)
                buildingCount = buildingCount + 1
            end
        end
    end

    local fixedAssets = landValue + buildingValue
    local netWorth = liquidWealth + fixedAssets
    local capitalRatio = netWorth > 0 and (fixedAssets / netWorth * 100) or 0

    -- Income/expenses (from character data or estimate)
    local incomePerCycle = char.incomePerCycle or char.income or 0
    local expensesPerCycle = char.expensesPerCycle or char.expenses or 0
    local netSavings = incomePerCycle - expensesPerCycle

    love.graphics.setFont(self.fonts.normal)

    -- Stats boxes row
    local boxW = (w - 30) / 3
    local boxH = 45
    local boxY = y

    -- Box 1: Current Wealth
    love.graphics.setColor(self.colors.sectionBg)
    love.graphics.rectangle("fill", x, boxY, boxW, boxH, 4, 4)
    love.graphics.setColor(self.colors.sectionBorder)
    love.graphics.rectangle("line", x, boxY, boxW, boxH, 4, 4)
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Current Wealth", x + 8, boxY + 5)
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.gold)
    love.graphics.print(string.format("%d gold", liquidWealth), x + 8, boxY + 22)

    -- Box 2: Income/Cycle
    local box2X = x + boxW + 15
    love.graphics.setColor(self.colors.sectionBg)
    love.graphics.rectangle("fill", box2X, boxY, boxW, boxH, 4, 4)
    love.graphics.setColor(self.colors.sectionBorder)
    love.graphics.rectangle("line", box2X, boxY, boxW, boxH, 4, 4)
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Income/Cycle", box2X + 8, boxY + 5)
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.green)
    love.graphics.print(string.format("+%d gold", incomePerCycle), box2X + 8, boxY + 22)

    -- Box 3: Expenses/Cycle
    local box3X = x + (boxW + 15) * 2
    love.graphics.setColor(self.colors.sectionBg)
    love.graphics.rectangle("fill", box3X, boxY, boxW, boxH, 4, 4)
    love.graphics.setColor(self.colors.sectionBorder)
    love.graphics.rectangle("line", box3X, boxY, boxW, boxH, 4, 4)
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Expenses/Cycle", box3X + 8, boxY + 5)
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.red)
    love.graphics.print(string.format("-%d gold", expensesPerCycle), box3X + 8, boxY + 22)

    y = boxY + boxH + 12

    -- Net savings
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Net Savings: ", x, y)
    if netSavings >= 0 then
        love.graphics.setColor(self.colors.green)
        love.graphics.print(string.format("+%d gold/cycle", netSavings), x + 85, y)
    else
        love.graphics.setColor(self.colors.red)
        love.graphics.print(string.format("%d gold/cycle", netSavings), x + 85, y)
    end
    y = y + 16

    -- Wealth rank
    local wealthRank = char.wealthRank or "?"
    local totalCitizens = 0
    if self.world and self.world.characters then
        for _ in pairs(self.world.characters) do
            totalCitizens = totalCitizens + 1
        end
    end
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Wealth Rank: ", x, y)
    love.graphics.setColor(self.colors.blue)
    love.graphics.print(string.format("#%s of %d citizens", tostring(wealthRank), totalCitizens), x + 85, y)
    y = y + 20

    -- Capital ratio
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print(string.format("Capital Ratio: %.0f%% (Liquid: %dg, Fixed: %dg)",
        capitalRatio, liquidWealth, fixedAssets), x, y)
    y = y + 16

    -- Emergent class calculation
    local emergentClass = char.emergentClass or self:CalculateEmergentClass(netWorth, capitalRatio)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Emergent Class: ", x, y)
    love.graphics.setColor(self:GetClassColor(emergentClass))
    love.graphics.print(string.format("%s (Net Worth: %dg, Capital: %.0f%%)",
        emergentClass, netWorth, capitalRatio), x + 100, y)
    y = y + 20

    -- Land and buildings owned
    love.graphics.setFont(self.fonts.small)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print(string.format("Land Owned: %d plots (value: %dg)", landCount, landValue), x, y)
    y = y + 14

    if buildingCount > 0 then
        love.graphics.print(string.format("Buildings Owned: %d (value: %dg)", buildingCount, buildingValue), x, y)
        y = y + 14
    end

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x, y + 4, x + w, y + 4)

    return y + 10
end

-- =============================================================================
-- SECTION 8: Housing (NEW - from Phase 8)
-- =============================================================================
function CharacterDetailPanel:RenderHousingSection(x, y, w, char)
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.5, 0.7, 0.9)
    love.graphics.print("HOUSING", x, y)

    -- NEW badge
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(0.3, 0.6, 0.3)
    love.graphics.print("[NEW]", x + 70, y + 2)

    y = y + 22

    local housingSystem = self.world and self.world.housingSystem
    local residence = char.residence or char.housingId
    local building = nil

    if residence and self.world and self.world.buildings then
        building = self.world.buildings[residence]
    end

    love.graphics.setFont(self.fonts.normal)

    if not building then
        -- Homeless
        love.graphics.setColor(self.colors.red)
        love.graphics.print("Current Residence: HOMELESS", x, y)
        y = y + 18

        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("This citizen has no assigned housing.", x, y)
        y = y + 16

        -- Show request relocation button in edit mode
        if self.editMode then
            self:RenderButton("Find Housing", x, y, 100, 22, function()
                -- TODO: Open housing assignment modal
            end, {0.3, 0.5, 0.6})
            y = y + 28
        end
    else
        -- Has housing
        local buildingName = building.name or building.type or "Unknown Building"
        love.graphics.setColor(self.colors.text)
        love.graphics.print("Current Residence: " .. buildingName, x, y)
        y = y + 18

        -- Quality tier
        local qualityTier = building.qualityTier or building.housingQuality or 1
        local maxTier = 5
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Quality Tier: ", x, y)

        -- Star rating
        local starX = x + 85
        for i = 1, maxTier do
            if i <= qualityTier then
                love.graphics.setColor(self.colors.gold)
                love.graphics.print("★", starX + (i-1) * 12, y)
            else
                love.graphics.setColor(0.3, 0.3, 0.3)
                love.graphics.print("☆", starX + (i-1) * 12, y)
            end
        end
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print(string.format(" (%d/%d)", qualityTier, maxTier), starX + maxTier * 12, y)
        y = y + 18

        -- Monthly rent
        local rent = building.rentPerOccupant or building.rent or 0
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Monthly Rent: ", x, y)
        love.graphics.setColor(self.colors.gold)
        love.graphics.print(string.format("%d gold", rent), x + 90, y)
        y = y + 18

        -- Rent status
        local rentPaid = char.rentPaid ~= false
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("Rent Status: ", x, y)
        if rentPaid then
            love.graphics.setColor(self.colors.green)
            love.graphics.print("PAID ✓", x + 80, y)
        else
            love.graphics.setColor(self.colors.red)
            love.graphics.print("OVERDUE ✗", x + 80, y)
        end
        y = y + 22

        -- Housing satisfaction breakdown
        local housingSatisfaction = char.housingSatisfaction or 70
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print(string.format("Housing Satisfaction: %.0f%%", housingSatisfaction), x, y)
        y = y + 18

        -- Satisfaction breakdown bars
        love.graphics.setFont(self.fonts.small)
        local breakdownItems = {
            {name = "Quality Match", value = char.qualityMatchScore or 80,
             desc = qualityTier >= (char.expectedQuality or 1) and "tier matches class" or "tier below expected"},
            {name = "Space", value = char.spaceScore or 60,
             desc = string.format("%d of %d occupants", building.occupantCount or 1, building.capacity or 4)},
            {name = "Location", value = char.locationScore or 90,
             desc = char.nearWorkplace and "near workplace" or "distance ok"}
        }

        for _, item in ipairs(breakdownItems) do
            love.graphics.setColor(self.colors.textMuted)
            love.graphics.print(item.name .. ":", x + 10, y)

            -- Bar
            local barX = x + 100
            local barW = 150
            love.graphics.setColor(0.2, 0.2, 0.25)
            love.graphics.rectangle("fill", barX, y + 2, barW, 10)

            local fillW = (item.value / 100) * barW
            if item.value >= 70 then
                love.graphics.setColor(0.3, 0.7, 0.3)
            elseif item.value >= 40 then
                love.graphics.setColor(0.7, 0.7, 0.3)
            else
                love.graphics.setColor(0.7, 0.3, 0.3)
            end
            love.graphics.rectangle("fill", barX, y + 2, fillW, 10)

            love.graphics.setColor(self.colors.textMuted)
            love.graphics.print("(" .. item.desc .. ")", barX + barW + 10, y)
            y = y + 16
        end
        y = y + 5

        -- Action buttons in edit mode
        if self.editMode then
            self:RenderButton("Request Relocation", x, y, 130, 22, function()
                -- TODO: Add to relocation queue
            end, {0.5, 0.4, 0.3})

            self:RenderButton("View Housing", x + 140, y, 110, 22, function()
                -- TODO: Open housing overview
            end, {0.3, 0.4, 0.5})
            y = y + 28
        end
    end

    -- Separator
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x, y, x + w, y)

    return y + 5
end

-- =============================================================================
-- SECTION 9: Status & Risks
-- =============================================================================
function CharacterDetailPanel:RenderStatusSection(x, y, w, char)
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(0.8, 0.4, 0.4)
    love.graphics.print("STATUS & RISKS", x, y)
    y = y + 20

    love.graphics.setFont(self.fonts.normal)

    -- Status flags row
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Protesting:", x, y)
    if char.isProtesting then
        love.graphics.setColor(self.colors.yellow)
        love.graphics.print("YES", x + 70, y)
    else
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("No", x + 70, y)
    end

    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Emigrated:", x + 150, y)
    if char.hasEmigrated then
        love.graphics.setColor(self.colors.red)
        love.graphics.print("YES", x + 220, y)
    else
        love.graphics.setColor(self.colors.textMuted)
        love.graphics.print("No", x + 220, y)
    end

    -- Status based on satisfaction
    local avgSat = 0
    if char.GetAverageSatisfaction then
        avgSat = char:GetAverageSatisfaction()
    end
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Status:", x + 300, y)
    if avgSat < 0 then
        love.graphics.setColor(self.colors.red)
        love.graphics.print("STRESSED", x + 350, y)
    elseif avgSat < 30 then
        love.graphics.setColor(self.colors.yellow)
        love.graphics.print("DISSATISFIED", x + 350, y)
    else
        love.graphics.setColor(self.colors.green)
        love.graphics.print("CONTENT", x + 350, y)
    end
    y = y + 18

    -- Productivity and priority
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print(string.format("Productivity: %.0f%%", (char.productivity or 1) * 100), x, y)
    love.graphics.print(string.format("Priority: %.1f", char.allocationPriority or 0), x + 150, y)
    y = y + 18

    -- Consecutive failures
    love.graphics.print(string.format("Consecutive Failures: %d", char.consecutiveFailures or 0), x, y)
    y = y + 18

    -- Risk indicators
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Emigration Risk:", x, y)
    local emigrationRisk = "Low"
    local emigrationColor = self.colors.green
    if avgSat < -50 then
        emigrationRisk = "CRITICAL"
        emigrationColor = self.colors.red
    elseif avgSat < 0 then
        emigrationRisk = "High"
        emigrationColor = {0.9, 0.5, 0.2}
    elseif avgSat < 30 then
        emigrationRisk = "Medium"
        emigrationColor = self.colors.yellow
    end
    love.graphics.setColor(emigrationColor)
    love.graphics.print(emigrationRisk, x + 110, y)

    -- Protest risk
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Protest Risk:", x + 200, y)
    local protestRisk = "Low"
    local protestColor = self.colors.green
    if avgSat < -30 then
        protestRisk = "High"
        protestColor = self.colors.red
    elseif avgSat < 20 then
        protestRisk = "Medium"
        protestColor = self.colors.yellow
    end
    love.graphics.setColor(protestColor)
    love.graphics.print(protestRisk, x + 290, y)
    y = y + 25

    return y
end

-- =============================================================================
-- Helper Functions
-- =============================================================================

function CharacterDetailPanel:RenderButton(text, x, y, w, h, onClick, color)
    local mx, my = love.mouse.getPosition()
    local isHover = mx >= x and mx <= x + w and my >= y and my <= y + h

    color = color or {0.3, 0.4, 0.5}

    if isHover then
        love.graphics.setColor(color[1] + 0.1, color[2] + 0.1, color[3] + 0.1)
    else
        love.graphics.setColor(color[1], color[2], color[3])
    end
    love.graphics.rectangle("fill", x, y, w, h, 3, 3)

    love.graphics.setColor(0.5, 0.6, 0.7)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, w, h, 3, 3)

    love.graphics.setColor(1, 1, 1)
    local font = love.graphics.getFont()
    local textW = font:getWidth(text)
    local textH = font:getHeight()
    love.graphics.print(text, x + (w - textW) / 2, y + (h - textH) / 2)

    -- Store for click handling
    if not self.buttons then self.buttons = {} end
    table.insert(self.buttons, {x = x, y = y, w = w, h = h, onClick = onClick})
end

function CharacterDetailPanel:GetSatisfactionColor(value)
    if value < 0 then
        return 0.8, 0.2, 0.2
    elseif value < 30 then
        return 0.9, 0.6, 0.2
    elseif value < 60 then
        return 0.8, 0.8, 0.3
    else
        return 0.3, 0.8, 0.3
    end
end

function CharacterDetailPanel:GetClassColor(class)
    local classColors = {
        PEASANT = {0.6, 0.5, 0.4},
        WORKER = {0.5, 0.6, 0.7},
        ARTISAN = {0.6, 0.7, 0.5},
        MERCHANT = {0.8, 0.7, 0.3},
        WEALTHY = {0.7, 0.5, 0.8},
        NOBLE = {0.9, 0.8, 0.4},
    }
    return classColors[class] or {0.7, 0.7, 0.7}
end

function CharacterDetailPanel:CalculateEmergentClass(netWorth, capitalRatio)
    -- Class thresholds (should match ClassThresholds.json)
    if netWorth < 100 then
        return "PEASANT"
    elseif netWorth < 500 then
        return "WORKER"
    elseif netWorth < 1500 and capitalRatio < 30 then
        return "ARTISAN"
    elseif netWorth < 3000 or capitalRatio >= 30 then
        return "MERCHANT"
    elseif netWorth < 10000 then
        return "WEALTHY"
    else
        return "NOBLE"
    end
end

function CharacterDetailPanel:HandleClick(screenX, screenY)
    if not self.visible then return false end

    -- Check button clicks
    if self.buttons then
        for _, btn in ipairs(self.buttons) do
            if screenX >= btn.x and screenX <= btn.x + btn.w and
               screenY >= btn.y and screenY <= btn.y + btn.h then
                if btn.onClick then
                    btn.onClick()
                end
                return true
            end
        end
    end

    -- Check if click is outside modal to close
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local w = math.min(950, screenW - 40)
    local h = math.min(780, screenH - 40)
    local x = (screenW - w) / 2
    local y = (screenH - h) / 2

    if screenX < x or screenX > x + w or screenY < y or screenY > y + h then
        self:Hide()
        return true
    end

    return true  -- Consume click within modal
end

function CharacterDetailPanel:HandleMouseWheel(dy)
    if not self.visible then return false end

    self.scrollOffset = math.max(0, math.min(self.maxScroll, self.scrollOffset - dy * 40))
    return true
end

function CharacterDetailPanel:HandleKeyPress(key)
    if not self.visible then return false end

    if key == "escape" then
        self:Hide()
        return true
    end

    return false
end

function CharacterDetailPanel:Update(dt)
    -- Clear buttons for next frame
    self.buttons = {}
end

return CharacterDetailPanel
