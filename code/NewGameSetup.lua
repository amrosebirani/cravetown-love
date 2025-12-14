--
-- NewGameSetup.lua
-- New game setup wizard for CraveTown Alpha
-- Following game_ui_flow_specification.md Section 3.2
--

NewGameSetup = {}
NewGameSetup.__index = NewGameSetup

function NewGameSetup:Create(onComplete, onCancel)
    local setup = setmetatable({}, NewGameSetup)

    setup.onComplete = onComplete
    setup.onCancel = onCancel

    -- Current step (1 = Town Name & Location, 2 = Starting Conditions, 3 = Tutorial)
    setup.currentStep = 1
    setup.totalSteps = 3

    -- Fonts
    setup.fonts = {
        title = love.graphics.newFont(24),
        header = love.graphics.newFont(18),
        normal = love.graphics.newFont(14),
        small = love.graphics.newFont(12)
    }

    -- Colors
    setup.colors = {
        background = {0.1, 0.1, 0.14},
        panel = {0.15, 0.15, 0.2},
        border = {0.3, 0.3, 0.35},
        title = {0.85, 0.7, 0.3},
        text = {0.9, 0.9, 0.95},
        textDim = {0.6, 0.6, 0.65},
        accent = {0.4, 0.7, 1.0},
        button = {0.25, 0.25, 0.3},
        buttonHover = {0.35, 0.35, 0.4},
        buttonDisabled = {0.2, 0.2, 0.22},
        selected = {0.3, 0.5, 0.7},
        inputBg = {0.08, 0.08, 0.1},
        inputBorder = {0.4, 0.4, 0.45}
    }

    -- Game configuration (the result)
    setup.config = {
        townName = "Prosperityville",
        location = "fertile_plains",
        difficulty = "normal",
        economicSystem = "communist",
        tutorialMode = "full"
    }

    -- Location options
    setup.locations = {
        {id = "river_valley", name = "River Valley", icon = "~", bonus = "+20% fishing, +water access", challenge = "-15% farming space"},
        {id = "mountain_pass", name = "Mountain Pass", icon = "^", bonus = "+30% ore/mining", challenge = "-20% farm output"},
        {id = "fertile_plains", name = "Fertile Plains", icon = "*", bonus = "+20% farm output, +water", challenge = "-10% ore availability"},
        {id = "forest_edge", name = "Forest Edge", icon = "#", bonus = "+30% lumber, +hunting", challenge = "-15% open building space"},
        {id = "desert_oasis", name = "Desert Oasis", icon = "o", bonus = "+exotic goods trade", challenge = "-30% water, -20% farming"},
        {id = "mining_hills", name = "Mining Hills", icon = "M", bonus = "+40% ore, +gems", challenge = "-25% farming, limited water"}
    }

    -- Difficulty options
    setup.difficulties = {
        {id = "story", name = "Story Mode", desc = "Generous resources, slow craving growth"},
        {id = "normal", name = "Normal", desc = "Balanced challenge"},
        {id = "challenging", name = "Challenging", desc = "Scarce resources, faster craving growth"},
        {id = "survival", name = "Survival", desc = "Minimal starting resources"}
    }

    -- Economic systems
    setup.economicSystems = {
        {id = "communist", name = "Communist", desc = "Central allocation (recommended for start)"},
        {id = "mixed", name = "Mixed Economy", desc = "Basic needs allocated, luxury = market"},
        {id = "market", name = "Free Market", desc = "Everything price-based (advanced)"}
    }

    -- Tutorial options
    setup.tutorialOptions = {
        {id = "full", name = "Full Tutorial", desc = "Step-by-step guidance through first 50 cycles"},
        {id = "tips", name = "Tips Only", desc = "Occasional hints when things go wrong"},
        {id = "none", name = "No Tutorial", desc = "Jump straight into the game"}
    }

    -- UI state
    setup.hoveredButton = nil
    setup.isTypingName = false
    setup.cursorBlink = 0

    -- Selected indices for radio buttons
    setup.selectedLocation = 3  -- fertile_plains
    setup.selectedDifficulty = 2  -- normal
    setup.selectedEconomic = 1  -- communist
    setup.selectedTutorial = 1  -- full

    return setup
end

function NewGameSetup:Update(dt)
    -- Cursor blink for text input
    self.cursorBlink = (self.cursorBlink + dt) % 1.0

    return false
end

function NewGameSetup:Render()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Panel dimensions
    local panelW = math.min(700, screenW - 100)
    local panelH = math.min(550, screenH - 80)
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    -- Panel background
    love.graphics.setColor(self.colors.panel)
    love.graphics.rectangle("fill", panelX, panelY, panelW, panelH, 8, 8)

    -- Panel border
    love.graphics.setColor(self.colors.border)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panelX, panelY, panelW, panelH, 8, 8)

    -- Step indicator
    self:RenderStepIndicator(panelX, panelY, panelW)

    -- Content area
    local contentY = panelY + 60
    local contentH = panelH - 120

    if self.currentStep == 1 then
        self:RenderStep1(panelX, contentY, panelW, contentH)
    elseif self.currentStep == 2 then
        self:RenderStep2(panelX, contentY, panelW, contentH)
    elseif self.currentStep == 3 then
        self:RenderStep3(panelX, contentY, panelW, contentH)
    end

    -- Navigation buttons
    self:RenderNavButtons(panelX, panelY + panelH - 50, panelW)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

function NewGameSetup:RenderStepIndicator(panelX, panelY, panelW)
    love.graphics.setFont(self.fonts.header)

    local stepNames = {"Town & Location", "Starting Conditions", "Tutorial"}

    for i = 1, self.totalSteps do
        local x = panelX + (i - 0.5) * (panelW / self.totalSteps)
        local y = panelY + 20

        -- Step circle
        local radius = 12
        if i == self.currentStep then
            love.graphics.setColor(self.colors.accent)
            love.graphics.circle("fill", x, y, radius)
            love.graphics.setColor(1, 1, 1)
        elseif i < self.currentStep then
            love.graphics.setColor(0.3, 0.6, 0.3)
            love.graphics.circle("fill", x, y, radius)
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(self.colors.border)
            love.graphics.circle("line", x, y, radius)
        end

        -- Step number
        love.graphics.setFont(self.fonts.small)
        local numText = tostring(i)
        local numW = self.fonts.small:getWidth(numText)
        love.graphics.print(numText, x - numW / 2, y - 6)

        -- Step name (below circle)
        love.graphics.setFont(self.fonts.small)
        local nameW = self.fonts.small:getWidth(stepNames[i])
        if i == self.currentStep then
            love.graphics.setColor(self.colors.text)
        else
            love.graphics.setColor(self.colors.textDim)
        end
        love.graphics.print(stepNames[i], x - nameW / 2, y + 18)
    end
end

function NewGameSetup:RenderStep1(panelX, contentY, panelW, contentH)
    local padding = 30
    local x = panelX + padding
    local y = contentY + 10
    local innerW = panelW - padding * 2

    -- Title
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(self.colors.title)
    love.graphics.print("CREATE YOUR TOWN", x, y)
    y = y + 40

    -- Town name input
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Town Name:", x, y)
    y = y + 25

    -- Input box
    local inputW = 300
    local inputH = 30
    love.graphics.setColor(self.colors.inputBg)
    love.graphics.rectangle("fill", x, y, inputW, inputH, 4, 4)
    love.graphics.setColor(self.isTypingName and self.colors.accent or self.colors.inputBorder)
    love.graphics.rectangle("line", x, y, inputW, inputH, 4, 4)

    love.graphics.setColor(self.colors.text)
    love.graphics.print(self.config.townName, x + 8, y + 7)

    -- Cursor
    if self.isTypingName and self.cursorBlink < 0.5 then
        local cursorX = x + 8 + self.fonts.normal:getWidth(self.config.townName)
        love.graphics.rectangle("fill", cursorX, y + 5, 2, 20)
    end

    y = y + 50

    -- Location selection
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Starting Location:", x, y)
    y = y + 30

    -- Location grid (2 columns)
    local colW = (innerW - 20) / 2
    local row = 0
    local col = 0

    for i, loc in ipairs(self.locations) do
        local locX = x + col * (colW + 20)
        local locY = y + row * 70

        local isSelected = i == self.selectedLocation
        local isHovered = self.hoveredButton == "loc_" .. i

        -- Location box
        if isSelected then
            love.graphics.setColor(self.colors.selected)
        elseif isHovered then
            love.graphics.setColor(self.colors.buttonHover)
        else
            love.graphics.setColor(self.colors.button)
        end
        love.graphics.rectangle("fill", locX, locY, colW, 60, 4, 4)

        if isSelected then
            love.graphics.setColor(self.colors.accent)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", locX, locY, colW, 60, 4, 4)
        end

        -- Location icon and name
        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(self.colors.text)
        love.graphics.print(loc.icon .. " " .. loc.name, locX + 10, locY + 8)

        -- Bonus/challenge
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(0.4, 0.8, 0.4)
        love.graphics.print(loc.bonus, locX + 10, locY + 26)
        love.graphics.setColor(0.9, 0.5, 0.4)
        love.graphics.print(loc.challenge, locX + 10, locY + 42)

        col = col + 1
        if col >= 2 then
            col = 0
            row = row + 1
        end
    end
end

function NewGameSetup:RenderStep2(panelX, contentY, panelW, contentH)
    local padding = 30
    local x = panelX + padding
    local y = contentY + 10
    local innerW = panelW - padding * 2

    -- Title
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(self.colors.title)
    love.graphics.print("STARTING CONDITIONS", x, y)
    y = y + 40

    -- Difficulty
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Difficulty:", x, y)
    y = y + 25

    for i, diff in ipairs(self.difficulties) do
        local isSelected = i == self.selectedDifficulty
        local isHovered = self.hoveredButton == "diff_" .. i

        local radioX = x
        local radioY = y

        -- Radio circle
        if isSelected then
            love.graphics.setColor(self.colors.accent)
            love.graphics.circle("fill", radioX + 8, radioY + 8, 8)
        else
            love.graphics.setColor(self.colors.border)
            love.graphics.circle("line", radioX + 8, radioY + 8, 8)
        end

        -- Label
        love.graphics.setColor(isHovered and self.colors.accent or self.colors.text)
        love.graphics.print(diff.name, radioX + 25, radioY)

        -- Description
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("- " .. diff.desc, radioX + 25, radioY + 18)
        love.graphics.setFont(self.fonts.normal)

        y = y + 40
    end

    y = y + 10

    -- Economic System
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Economic System:", x, y)
    y = y + 25

    for i, econ in ipairs(self.economicSystems) do
        local isSelected = i == self.selectedEconomic
        local isHovered = self.hoveredButton == "econ_" .. i

        local radioX = x
        local radioY = y

        if isSelected then
            love.graphics.setColor(self.colors.accent)
            love.graphics.circle("fill", radioX + 8, radioY + 8, 8)
        else
            love.graphics.setColor(self.colors.border)
            love.graphics.circle("line", radioX + 8, radioY + 8, 8)
        end

        love.graphics.setColor(isHovered and self.colors.accent or self.colors.text)
        love.graphics.print(econ.name, radioX + 25, radioY)

        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print("- " .. econ.desc, radioX + 25, radioY + 18)
        love.graphics.setFont(self.fonts.normal)

        y = y + 40
    end
end

function NewGameSetup:RenderStep3(panelX, contentY, panelW, contentH)
    local padding = 30
    local x = panelX + padding
    local y = contentY + 10

    -- Title
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(self.colors.title)
    love.graphics.print("TUTORIAL", x, y)
    y = y + 40

    -- Question
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Would you like guidance as you play?", x, y)
    y = y + 40

    -- Tutorial options
    for i, opt in ipairs(self.tutorialOptions) do
        local isSelected = i == self.selectedTutorial
        local isHovered = self.hoveredButton == "tut_" .. i

        local optX = x
        local optY = y
        local optW = panelW - padding * 2
        local optH = 60

        -- Option box
        if isSelected then
            love.graphics.setColor(self.colors.selected)
        elseif isHovered then
            love.graphics.setColor(self.colors.buttonHover)
        else
            love.graphics.setColor(self.colors.button)
        end
        love.graphics.rectangle("fill", optX, optY, optW, optH, 4, 4)

        if isSelected then
            love.graphics.setColor(self.colors.accent)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", optX, optY, optW, optH, 4, 4)
        end

        -- Radio indicator
        love.graphics.setColor(isSelected and self.colors.accent or self.colors.border)
        love.graphics.circle(isSelected and "fill" or "line", optX + 25, optY + optH / 2, 10)

        -- Text
        love.graphics.setFont(self.fonts.header)
        love.graphics.setColor(self.colors.text)
        love.graphics.print(opt.name, optX + 50, optY + 10)

        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print(opt.desc, optX + 50, optY + 32)

        y = y + 75
    end

    -- Summary
    y = y + 20
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Summary: " .. self.config.townName .. " in " ..
        self.locations[self.selectedLocation].name .. " (" ..
        self.difficulties[self.selectedDifficulty].name .. ")", x, y)
end

function NewGameSetup:RenderNavButtons(x, y, panelW)
    local buttonW = 120
    local buttonH = 35

    -- Back button (not on first step)
    if self.currentStep > 1 then
        local backX = x + 30
        local isHovered = self.hoveredButton == "back"

        love.graphics.setColor(isHovered and self.colors.buttonHover or self.colors.button)
        love.graphics.rectangle("fill", backX, y, buttonW, buttonH, 4, 4)

        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(self.colors.text)
        local text = "< BACK"
        local textW = self.fonts.normal:getWidth(text)
        love.graphics.print(text, backX + (buttonW - textW) / 2, y + 9)
    end

    -- Next/Start button
    local nextX = x + panelW - buttonW - 30
    local isHovered = self.hoveredButton == "next"
    local isStart = self.currentStep == self.totalSteps

    love.graphics.setColor(isHovered and {0.3, 0.6, 0.4} or {0.2, 0.5, 0.3})
    love.graphics.rectangle("fill", nextX, y, buttonW, buttonH, 4, 4)

    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(1, 1, 1)
    local text = isStart and "START GAME" or "NEXT >"
    local textW = self.fonts.normal:getWidth(text)
    love.graphics.print(text, nextX + (buttonW - textW) / 2, y + 9)
end

function NewGameSetup:HandleKeyPress(key)
    if self.isTypingName then
        if key == "backspace" then
            self.config.townName = self.config.townName:sub(1, -2)
            return true
        elseif key == "return" or key == "escape" then
            self.isTypingName = false
            return true
        end
    else
        if key == "escape" then
            if self.onCancel then self.onCancel() end
            return true
        elseif key == "return" then
            self:NextStep()
            return true
        elseif key == "left" or key == "backspace" then
            self:PrevStep()
            return true
        elseif key == "right" then
            self:NextStep()
            return true
        end
    end

    return false
end

function NewGameSetup:TextInput(text)
    if self.isTypingName then
        -- Limit name length
        if #self.config.townName < 30 then
            self.config.townName = self.config.townName .. text
        end
        return true
    end
    return false
end

function NewGameSetup:HandleClick(mx, my, button)
    if button ~= 1 then return false end

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local panelW = math.min(700, screenW - 100)
    local panelH = math.min(550, screenH - 80)
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2
    local padding = 30

    -- Check name input click (Step 1)
    if self.currentStep == 1 then
        local inputX = panelX + padding
        local inputY = panelY + 60 + 10 + 40 + 25
        local inputW = 300
        local inputH = 30

        if mx >= inputX and mx <= inputX + inputW and
           my >= inputY and my <= inputY + inputH then
            self.isTypingName = true
            return true
        else
            self.isTypingName = false
        end

        -- Check location clicks
        local locY = inputY + 50 + 30
        local colW = (panelW - padding * 2 - 20) / 2
        for i = 1, #self.locations do
            local col = (i - 1) % 2
            local row = math.floor((i - 1) / 2)
            local locX = panelX + padding + col * (colW + 20)
            local locBoxY = locY + row * 70

            if mx >= locX and mx <= locX + colW and
               my >= locBoxY and my <= locBoxY + 60 then
                self.selectedLocation = i
                self.config.location = self.locations[i].id
                return true
            end
        end
    end

    -- Check difficulty clicks (Step 2)
    if self.currentStep == 2 then
        local diffY = panelY + 60 + 10 + 40 + 25
        for i = 1, #self.difficulties do
            local radioY = diffY + (i - 1) * 40
            if mx >= panelX + padding and mx <= panelX + padding + 300 and
               my >= radioY and my <= radioY + 35 then
                self.selectedDifficulty = i
                self.config.difficulty = self.difficulties[i].id
                return true
            end
        end

        -- Economic system clicks
        local econY = diffY + #self.difficulties * 40 + 10 + 25
        for i = 1, #self.economicSystems do
            local radioY = econY + (i - 1) * 40
            if mx >= panelX + padding and mx <= panelX + padding + 400 and
               my >= radioY and my <= radioY + 35 then
                self.selectedEconomic = i
                self.config.economicSystem = self.economicSystems[i].id
                return true
            end
        end
    end

    -- Check tutorial clicks (Step 3)
    if self.currentStep == 3 then
        local tutY = panelY + 60 + 10 + 40 + 40
        for i = 1, #self.tutorialOptions do
            local optY = tutY + (i - 1) * 75
            if mx >= panelX + padding and mx <= panelX + panelW - padding and
               my >= optY and my <= optY + 60 then
                self.selectedTutorial = i
                self.config.tutorialMode = self.tutorialOptions[i].id
                return true
            end
        end
    end

    -- Navigation buttons
    local navY = panelY + panelH - 50
    local buttonW = 120
    local buttonH = 35

    -- Back button
    if self.currentStep > 1 then
        local backX = panelX + 30
        if mx >= backX and mx <= backX + buttonW and
           my >= navY and my <= navY + buttonH then
            self:PrevStep()
            return true
        end
    end

    -- Next/Start button
    local nextX = panelX + panelW - buttonW - 30
    if mx >= nextX and mx <= nextX + buttonW and
       my >= navY and my <= navY + buttonH then
        self:NextStep()
        return true
    end

    return false
end

function NewGameSetup:HandleMouseMove(mx, my)
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local panelW = math.min(700, screenW - 100)
    local panelH = math.min(550, screenH - 80)
    local panelX = (screenW - panelW) / 2
    local panelY = (screenH - panelH) / 2

    self.hoveredButton = nil

    -- Check nav buttons
    local navY = panelY + panelH - 50
    local buttonW = 120
    local buttonH = 35

    if self.currentStep > 1 then
        local backX = panelX + 30
        if mx >= backX and mx <= backX + buttonW and
           my >= navY and my <= navY + buttonH then
            self.hoveredButton = "back"
            return
        end
    end

    local nextX = panelX + panelW - buttonW - 30
    if mx >= nextX and mx <= nextX + buttonW and
       my >= navY and my <= navY + buttonH then
        self.hoveredButton = "next"
        return
    end

    -- Step-specific hover detection would go here
end

function NewGameSetup:NextStep()
    if self.currentStep < self.totalSteps then
        self.currentStep = self.currentStep + 1
    else
        -- Complete setup
        self:Complete()
    end
end

function NewGameSetup:PrevStep()
    if self.currentStep > 1 then
        self.currentStep = self.currentStep - 1
    end
end

function NewGameSetup:Complete()
    -- Finalize config values
    self.config.location = self.locations[self.selectedLocation].id
    self.config.difficulty = self.difficulties[self.selectedDifficulty].id
    self.config.economicSystem = self.economicSystems[self.selectedEconomic].id
    self.config.tutorialMode = self.tutorialOptions[self.selectedTutorial].id

    if self.onComplete then
        self.onComplete(self.config)
    end
end

return NewGameSetup
