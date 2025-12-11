--
-- TutorialSystem.lua
-- Step-by-step guidance system for new players
--
-- ┌────────────────────────────────────────────────────────────────────────────┐
-- │                          TUTORIAL SYSTEM                                   │
-- ├────────────────────────────────────────────────────────────────────────────┤
-- │                                                                            │
-- │   Tutorial Flow (First 30 Cycles):                                         │
-- │   ┌─────────────────────────────────────────────────────────────────┐     │
-- │   │ Cycle 1-3:   Welcome & Camera Controls                          │     │
-- │   │              "Welcome to CraveTown! Use WASD to pan camera"     │     │
-- │   │              Highlight: Camera pan area                          │     │
-- │   ├─────────────────────────────────────────────────────────────────┤     │
-- │   │ Cycle 4-6:   Citizen Selection                                   │     │
-- │   │              "Click on a citizen to see their details"          │     │
-- │   │              Highlight: Any citizen sprite                       │     │
-- │   ├─────────────────────────────────────────────────────────────────┤     │
-- │   │ Cycle 7-10:  Satisfaction Explained                              │     │
-- │   │              "Citizens have 9 need categories..."               │     │
-- │   │              Highlight: Satisfaction bars in left panel         │     │
-- │   ├─────────────────────────────────────────────────────────────────┤     │
-- │   │ Cycle 11-15: Building a Farm                                     │     │
-- │   │              "Press B to open Build menu, select Farm"          │     │
-- │   │              Highlight: Build button → Farm card                │     │
-- │   ├─────────────────────────────────────────────────────────────────┤     │
-- │   │ Cycle 16-20: Production                                          │     │
-- │   │              "Buildings produce goods automatically..."         │     │
-- │   │              Highlight: Production panel (P key)                │     │
-- │   ├─────────────────────────────────────────────────────────────────┤     │
-- │   │ Cycle 21-25: Immigration                                         │     │
-- │   │              "New citizens want to join! Press M to review"     │     │
-- │   │              Highlight: Immigration modal                        │     │
-- │   ├─────────────────────────────────────────────────────────────────┤     │
-- │   │ Cycle 26-30: Save & Continue                                     │     │
-- │   │              "You're doing great! Press F5 to quicksave"        │     │
-- │   │              Tutorial Complete!                                  │     │
-- │   └─────────────────────────────────────────────────────────────────┘     │
-- │                                                                            │
-- │   Visual Elements:                                                         │
-- │   - Highlight pulse around target UI element                              │
-- │   - Tooltip box with instruction text                                     │
-- │   - "Next" / "Skip Tutorial" buttons                                      │
-- │   - Progress indicator (Step X of Y)                                      │
-- │                                                                            │
-- └────────────────────────────────────────────────────────────────────────────┘
--

local TutorialSystem = {}
TutorialSystem.__index = TutorialSystem

function TutorialSystem:Create(world)
    local system = setmetatable({}, TutorialSystem)

    system.world = world
    system.enabled = true
    system.currentStep = 0
    system.completed = false
    system.skipped = false

    -- Step completion tracking
    system.stepCompleted = {}

    -- Animation state
    system.highlightPulse = 0
    system.tooltipAlpha = 0

    -- Tutorial steps definition
    system.steps = {
        -- Step 1: Welcome & Camera
        {
            id = "welcome",
            title = "Welcome to CraveTown!",
            message = "Use WASD or Arrow Keys to pan the camera around your town.\nScroll the mouse wheel to zoom in and out.",
            cycleRange = {1, 3},
            highlight = "camera",
            completionCondition = "camera_moved",
            hint = "Try moving the camera with WASD"
        },

        -- Step 2: Citizen Selection
        {
            id = "select_citizen",
            title = "Meet Your Citizens",
            message = "Click on any citizen to see their details.\nEach citizen has unique traits and needs.",
            cycleRange = {4, 6},
            highlight = "citizen",
            completionCondition = "citizen_selected",
            hint = "Click on a citizen in the world"
        },

        -- Step 3: Satisfaction System
        {
            id = "satisfaction",
            title = "Understanding Satisfaction",
            message = "Citizens have 9 need categories (food, safety, social, etc.).\nThe bars on the left show town-wide satisfaction levels.\nKeep citizens happy to prevent emigration!",
            cycleRange = {7, 10},
            highlight = "left_panel_bars",
            completionCondition = "viewed_satisfaction",
            hint = "Look at the satisfaction bars on the left"
        },

        -- Step 4: Build Menu
        {
            id = "build_menu",
            title = "Building Your Town",
            message = "Press B to open the Build Menu.\nBuildings produce goods that satisfy citizen needs.\nStart with a Farm to produce food!",
            cycleRange = {11, 15},
            highlight = "build_button",
            completionCondition = "building_placed",
            hint = "Press B and place a building"
        },

        -- Step 5: Production
        {
            id = "production",
            title = "Production & Resources",
            message = "Press P to see Production Analytics.\nThis shows what your buildings are producing.\nWatch for shortages and plan accordingly!",
            cycleRange = {16, 20},
            highlight = "production_panel",
            completionCondition = "production_viewed",
            hint = "Press P to view production"
        },

        -- Step 6: Immigration
        {
            id = "immigration",
            title = "Growing Your Town",
            message = "Press M to review immigration applicants.\nNew citizens want to join your town!\nReview their needs and accept those who fit.",
            cycleRange = {21, 25},
            highlight = "immigration_button",
            completionCondition = "immigration_viewed",
            hint = "Press M to view immigration"
        },

        -- Step 7: Save & Complete
        {
            id = "save_game",
            title = "Save Your Progress",
            message = "Press F5 to quicksave your game.\nPress F6 to access the full Save/Load menu.\nYou've completed the tutorial - good luck, Mayor!",
            cycleRange = {26, 30},
            highlight = "none",
            completionCondition = "game_saved",
            hint = "Press F5 to quicksave"
        }
    }

    -- Colors
    system.colors = {
        background = {0.1, 0.1, 0.15, 0.95},
        border = {0.83, 0.66, 0.33, 1},  -- Gold accent
        highlight = {0.83, 0.66, 0.33, 0.6},
        text = {1, 1, 1, 1},
        textDim = {0.7, 0.7, 0.7, 1},
        button = {0.3, 0.5, 0.7, 1},
        buttonHover = {0.4, 0.6, 0.8, 1},
        skip = {0.5, 0.5, 0.5, 1}
    }

    -- Fonts (will be set on first render)
    system.fonts = nil

    -- Input tracking for completion conditions
    system.cameraMoved = false
    system.citizenSelected = false
    system.buildMenuOpened = false
    system.buildingPlaced = false
    system.productionViewed = false
    system.immigrationViewed = false
    system.gameSaved = false

    return system
end

function TutorialSystem:InitFonts()
    if not self.fonts then
        self.fonts = {
            title = love.graphics.newFont(16),
            body = love.graphics.newFont(12),
            hint = love.graphics.newFont(11),
            button = love.graphics.newFont(11),
            step = love.graphics.newFont(10)
        }
    end
end

-- =============================================================================
-- UPDATE
-- =============================================================================

function TutorialSystem:Update(dt)
    if not self.enabled or self.completed or self.skipped then
        return
    end

    -- Update highlight pulse animation
    self.highlightPulse = (self.highlightPulse + dt * 2) % (2 * math.pi)

    -- Update tooltip fade
    if self.currentStep > 0 then
        self.tooltipAlpha = math.min(1, self.tooltipAlpha + dt * 3)
    end

    -- Check for step progression based on cycle
    local currentCycle = self.world and self.world.cycleCount or 0

    -- Find appropriate step for current cycle
    local targetStep = 0
    for i, step in ipairs(self.steps) do
        if currentCycle >= step.cycleRange[1] and currentCycle <= step.cycleRange[2] then
            targetStep = i
            break
        elseif currentCycle > step.cycleRange[2] then
            -- Past this step's range, mark as completed if not already
            self.stepCompleted[i] = true
        end
    end

    -- Progress to new step if needed
    if targetStep > 0 and targetStep ~= self.currentStep then
        self:SetStep(targetStep)
    end

    -- Check if current step is completed
    if self.currentStep > 0 then
        self:CheckStepCompletion()
    end

    -- Check if all steps completed
    if currentCycle > 30 then
        self:Complete()
    end
end

function TutorialSystem:SetStep(stepIndex)
    if stepIndex < 1 or stepIndex > #self.steps then
        return
    end

    self.currentStep = stepIndex
    self.tooltipAlpha = 0  -- Reset fade for new step

    -- Play step change sound
    self:PlayStepSound()
end

function TutorialSystem:CheckStepCompletion()
    local step = self.steps[self.currentStep]
    if not step then return end

    local completed = false

    if step.completionCondition == "camera_moved" then
        completed = self.cameraMoved
    elseif step.completionCondition == "citizen_selected" then
        completed = self.citizenSelected
    elseif step.completionCondition == "viewed_satisfaction" then
        -- Auto-complete after viewing for a few seconds
        completed = self.tooltipAlpha >= 1 and love.timer.getTime() > (self.stepStartTime or 0) + 5
    elseif step.completionCondition == "building_placed" then
        completed = self.buildingPlaced
    elseif step.completionCondition == "production_viewed" then
        completed = self.productionViewed
    elseif step.completionCondition == "immigration_viewed" then
        completed = self.immigrationViewed
    elseif step.completionCondition == "game_saved" then
        completed = self.gameSaved
    end

    if completed and not self.stepCompleted[self.currentStep] then
        self.stepCompleted[self.currentStep] = true

        -- Show completion notification
        if self.world and self.world.notificationSystem then
            self.world.notificationSystem:Success(
                "Tutorial Step Complete!",
                step.title .. " - Great job!"
            )
        end
    end
end

-- =============================================================================
-- EVENT TRACKING
-- =============================================================================

function TutorialSystem:OnCameraMoved()
    self.cameraMoved = true
end

function TutorialSystem:OnCitizenSelected()
    self.citizenSelected = true
end

function TutorialSystem:OnBuildMenuOpened()
    self.buildMenuOpened = true
end

function TutorialSystem:OnBuildingPlaced()
    self.buildingPlaced = true
end

function TutorialSystem:OnProductionViewed()
    self.productionViewed = true
end

function TutorialSystem:OnImmigrationViewed()
    self.immigrationViewed = true
end

function TutorialSystem:OnGameSaved()
    self.gameSaved = true
end

-- =============================================================================
-- RENDERING
-- =============================================================================

function TutorialSystem:Render()
    if not self.enabled or self.completed or self.skipped then
        return
    end

    if self.currentStep < 1 or self.currentStep > #self.steps then
        return
    end

    self:InitFonts()

    local step = self.steps[self.currentStep]
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Render highlight effect
    self:RenderHighlight(step.highlight)

    -- Render tooltip
    self:RenderTooltip(step, screenW, screenH)
end

function TutorialSystem:RenderHighlight(highlightType)
    if highlightType == "none" then return end

    local pulse = (math.sin(self.highlightPulse) + 1) / 2  -- 0 to 1
    local highlightAlpha = 0.3 + pulse * 0.3

    love.graphics.setColor(self.colors.highlight[1], self.colors.highlight[2],
                          self.colors.highlight[3], highlightAlpha * self.tooltipAlpha)
    love.graphics.setLineWidth(3)

    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    if highlightType == "camera" then
        -- Highlight the world view area
        local x = 220
        local y = 50
        local w = screenW - 440
        local h = screenH - 170
        self:DrawPulsingRect(x, y, w, h)

    elseif highlightType == "citizen" then
        -- Highlight first citizen if any
        if self.world and self.world.citizens and #self.world.citizens > 0 then
            local citizen = self.world.citizens[1]
            if citizen.x and citizen.y then
                -- This would need camera transform - simplified here
                love.graphics.circle("line", screenW / 2, screenH / 2, 50 + pulse * 10)
            end
        end

    elseif highlightType == "left_panel_bars" then
        -- Highlight satisfaction area in left panel
        self:DrawPulsingRect(10, 200, 200, 150)

    elseif highlightType == "build_button" then
        -- Highlight build button area (B key indicator)
        self:DrawPulsingRect(screenW / 2 - 100, screenH - 60, 200, 40)

    elseif highlightType == "production_panel" then
        -- Highlight P key area
        self:DrawPulsingRect(screenW / 2 - 100, screenH - 60, 200, 40)

    elseif highlightType == "immigration_button" then
        -- Highlight M key area
        self:DrawPulsingRect(screenW / 2 - 100, screenH - 60, 200, 40)
    end

    love.graphics.setLineWidth(1)
end

function TutorialSystem:DrawPulsingRect(x, y, w, h)
    local pulse = (math.sin(self.highlightPulse) + 1) / 2
    local expand = pulse * 5

    love.graphics.rectangle("line", x - expand, y - expand, w + expand * 2, h + expand * 2, 8, 8)
end

function TutorialSystem:RenderTooltip(step, screenW, screenH)
    local mx, my = love.mouse.getPosition()

    -- Tooltip dimensions
    local tooltipW = 380
    local tooltipH = 180
    local padding = 15

    -- Position at bottom center
    local tooltipX = (screenW - tooltipW) / 2
    local tooltipY = screenH - tooltipH - 100

    -- Apply fade alpha
    local alpha = self.tooltipAlpha

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.4 * alpha)
    love.graphics.rectangle("fill", tooltipX + 4, tooltipY + 4, tooltipW, tooltipH, 8, 8)

    -- Background
    love.graphics.setColor(self.colors.background[1], self.colors.background[2],
                          self.colors.background[3], self.colors.background[4] * alpha)
    love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipW, tooltipH, 8, 8)

    -- Border (gold accent)
    love.graphics.setColor(self.colors.border[1], self.colors.border[2],
                          self.colors.border[3], alpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", tooltipX, tooltipY, tooltipW, tooltipH, 8, 8)
    love.graphics.setLineWidth(1)

    -- Step indicator
    love.graphics.setFont(self.fonts.step)
    love.graphics.setColor(self.colors.textDim[1], self.colors.textDim[2],
                          self.colors.textDim[3], alpha)
    local stepText = string.format("Step %d of %d", self.currentStep, #self.steps)
    love.graphics.print(stepText, tooltipX + padding, tooltipY + padding)

    -- Completion checkmark if step is completed
    if self.stepCompleted[self.currentStep] then
        love.graphics.setColor(0.3, 0.8, 0.4, alpha)
        love.graphics.print(" +", tooltipX + padding + self.fonts.step:getWidth(stepText), tooltipY + padding)
    end

    -- Title
    love.graphics.setFont(self.fonts.title)
    love.graphics.setColor(self.colors.border[1], self.colors.border[2],
                          self.colors.border[3], alpha)
    love.graphics.print(step.title, tooltipX + padding, tooltipY + padding + 18)

    -- Message
    love.graphics.setFont(self.fonts.body)
    love.graphics.setColor(self.colors.text[1], self.colors.text[2],
                          self.colors.text[3], alpha)
    love.graphics.printf(step.message, tooltipX + padding, tooltipY + padding + 45,
                        tooltipW - padding * 2, "left")

    -- Hint
    love.graphics.setFont(self.fonts.hint)
    love.graphics.setColor(self.colors.textDim[1], self.colors.textDim[2],
                          self.colors.textDim[3], alpha)
    love.graphics.print("Tip: " .. step.hint, tooltipX + padding, tooltipY + tooltipH - 55)

    -- Buttons
    local btnY = tooltipY + tooltipH - 35
    local btnH = 26

    -- Skip button
    local skipW = 80
    local skipX = tooltipX + padding
    local skipHovered = mx >= skipX and mx <= skipX + skipW and my >= btnY and my <= btnY + btnH

    love.graphics.setColor(skipHovered and {0.4, 0.4, 0.4, alpha} or {0.3, 0.3, 0.3, alpha})
    love.graphics.rectangle("fill", skipX, btnY, skipW, btnH, 4, 4)
    love.graphics.setFont(self.fonts.button)
    love.graphics.setColor(self.colors.text[1], self.colors.text[2], self.colors.text[3], alpha)
    local skipTextW = self.fonts.button:getWidth("Skip Tutorial")
    love.graphics.print("Skip Tutorial", skipX + (skipW - skipTextW) / 2, btnY + 6)

    self.skipButton = {x = skipX, y = btnY, w = skipW, h = btnH}

    -- Next/Got it button (if step is completed)
    if self.stepCompleted[self.currentStep] then
        local nextW = 80
        local nextX = tooltipX + tooltipW - padding - nextW
        local nextHovered = mx >= nextX and mx <= nextX + nextW and my >= btnY and my <= btnY + btnH

        love.graphics.setColor(nextHovered and self.colors.buttonHover or self.colors.button)
        love.graphics.rectangle("fill", nextX, btnY, nextW, btnH, 4, 4)
        love.graphics.setColor(self.colors.text)

        local nextText = self.currentStep < #self.steps and "Next" or "Finish"
        local nextTextW = self.fonts.button:getWidth(nextText)
        love.graphics.print(nextText, nextX + (nextW - nextTextW) / 2, btnY + 6)

        self.nextButton = {x = nextX, y = btnY, w = nextW, h = btnH}
    else
        self.nextButton = nil
    end
end

-- =============================================================================
-- INPUT HANDLING
-- =============================================================================

function TutorialSystem:HandleClick(mx, my)
    if not self.enabled or self.completed or self.skipped then
        return false
    end

    -- Check skip button
    if self.skipButton then
        local btn = self.skipButton
        if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
            self:Skip()
            return true
        end
    end

    -- Check next button
    if self.nextButton then
        local btn = self.nextButton
        if mx >= btn.x and mx <= btn.x + btn.w and my >= btn.y and my <= btn.y + btn.h then
            if self.currentStep < #self.steps then
                self:SetStep(self.currentStep + 1)
            else
                self:Complete()
            end
            return true
        end
    end

    return false
end

-- =============================================================================
-- CONTROL
-- =============================================================================

function TutorialSystem:Skip()
    self.skipped = true

    if self.world and self.world.notificationSystem then
        self.world.notificationSystem:Info(
            "Tutorial Skipped",
            "Press H anytime to see keyboard shortcuts"
        )
    end
end

function TutorialSystem:Complete()
    self.completed = true

    if self.world and self.world.notificationSystem then
        self.world.notificationSystem:Success(
            "Tutorial Complete!",
            "You've learned the basics. Good luck, Mayor!"
        )
    end
end

function TutorialSystem:Reset()
    self.currentStep = 0
    self.completed = false
    self.skipped = false
    self.stepCompleted = {}
    self.cameraMoved = false
    self.citizenSelected = false
    self.buildMenuOpened = false
    self.buildingPlaced = false
    self.productionViewed = false
    self.immigrationViewed = false
    self.gameSaved = false
end

function TutorialSystem:SetEnabled(enabled)
    self.enabled = enabled
end

function TutorialSystem:IsActive()
    return self.enabled and not self.completed and not self.skipped
end

-- =============================================================================
-- SOUND
-- =============================================================================

function TutorialSystem:PlayStepSound()
    local sampleRate = 44100
    local frequency = 523  -- C5
    local duration = 0.15
    local samples = math.floor(sampleRate * duration)

    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)

    for i = 0, samples - 1 do
        local t = i / sampleRate
        local envelope = 1 - (t / duration)
        local value = math.sin(2 * math.pi * frequency * t) * 0.15 * envelope
        soundData:setSample(i, value)
    end

    local source = love.audio.newSource(soundData)
    source:setVolume(0.3)
    source:play()
end

-- =============================================================================
-- SERIALIZATION
-- =============================================================================

function TutorialSystem:Serialize()
    return {
        enabled = self.enabled,
        currentStep = self.currentStep,
        completed = self.completed,
        skipped = self.skipped,
        stepCompleted = self.stepCompleted,
        cameraMoved = self.cameraMoved,
        citizenSelected = self.citizenSelected,
        buildMenuOpened = self.buildMenuOpened,
        buildingPlaced = self.buildingPlaced,
        productionViewed = self.productionViewed,
        immigrationViewed = self.immigrationViewed,
        gameSaved = self.gameSaved
    }
end

function TutorialSystem:Deserialize(data)
    if not data then return end

    self.enabled = data.enabled ~= false
    self.currentStep = data.currentStep or 0
    self.completed = data.completed or false
    self.skipped = data.skipped or false
    self.stepCompleted = data.stepCompleted or {}
    self.cameraMoved = data.cameraMoved or false
    self.citizenSelected = data.citizenSelected or false
    self.buildMenuOpened = data.buildMenuOpened or false
    self.buildingPlaced = data.buildingPlaced or false
    self.productionViewed = data.productionViewed or false
    self.immigrationViewed = data.immigrationViewed or false
    self.gameSaved = data.gameSaved or false
end

return TutorialSystem
