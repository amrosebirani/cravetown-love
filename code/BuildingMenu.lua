--
-- BuildingMenu - bottom menu showing available buildings to place
--

require("code/BuildingTypes")

BuildingMenu = {}
BuildingMenu.__index = BuildingMenu

function BuildingMenu:Create()
    local this = {
        mHeight = 200,  -- Increased from 120 to show more rows
        mPadding = 5,
        mButtonWidth = 72,
        mButtonHeight = 72,
        mButtons = {},
        mScrollOffset = 0,
        mMaxScroll = 0,
        mButtonSpacing = 5,
        -- Collapse state
        mCollapsed = false,
        mCollapseButtonWidth = 80,
        mCollapseButtonHeight = 24,
        -- Animation
        mAnimating = false,
        mAnimProgress = 1.0,  -- 1 = fully expanded, 0 = fully collapsed
        mAnimSpeed = 5.0  -- Animation speed
    }

    setmetatable(this, self)

    -- Create buttons for all building types (just store the building type data)
    local allTypes = BuildingTypes.getAllTypes()
    for i, buildingType in ipairs(allTypes) do
        table.insert(this.mButtons, {
            buildingType = buildingType,
            label = buildingType.label,
            color = buildingType.color,
            name = buildingType.name,
            width = this.mButtonWidth,
            height = this.mButtonHeight
        })
    end

    -- Sort buttons alphabetically by label
    table.sort(this.mButtons, function(a, b)
        return a.label < b.label
    end)

    -- Calculate initial positions
    this:RecalculateLayout()

    return this
end

function BuildingMenu:RecalculateLayout()
    -- Recalculate button positions based on current screen size
    local screenW = love.graphics.getWidth()
    local menuY = love.graphics.getHeight() - self.mHeight
    local currentX = self.mPadding
    local currentY = menuY + self.mPadding
    local rowHeight = self.mButtonHeight + self.mButtonSpacing

    for i, button in ipairs(self.mButtons) do
        -- Check if we need to wrap to next row
        if currentX + self.mButtonWidth > screenW - self.mPadding then
            currentX = self.mPadding
            currentY = currentY + rowHeight
        end

        button.x = currentX
        button.y = currentY
        button.baseY = currentY

        currentX = currentX + self.mButtonWidth + self.mButtonSpacing
    end

    -- Calculate max scroll
    local lastButton = self.mButtons[#self.mButtons]
    if lastButton then
        local totalHeight = (lastButton.baseY - menuY) + rowHeight
        self.mMaxScroll = math.max(0, totalHeight - self.mHeight + self.mPadding * 2)
    end
end

function BuildingMenu:Enter()
    -- Called when this state is entered
end

function BuildingMenu:Exit()
    -- Called when this state is exited
end

function BuildingMenu:CanAffordBuilding(buildingType)
    -- Check if player has enough materials to build this building
    if not buildingType.constructionMaterials then
        return true  -- No materials required
    end

    for commodityId, requiredAmount in pairs(buildingType.constructionMaterials) do
        local availableAmount = gTown.mInventory:Get(commodityId)
        if availableAmount < requiredAmount then
            return false
        end
    end

    return true
end

function BuildingMenu:Update(dt)
    local mx, my = love.mouse.getPosition()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Update animation
    if self.mAnimating then
        local targetProgress = self.mCollapsed and 0 or 1
        local diff = targetProgress - self.mAnimProgress
        if math.abs(diff) < 0.01 then
            self.mAnimProgress = targetProgress
            self.mAnimating = false
        else
            self.mAnimProgress = self.mAnimProgress + diff * self.mAnimSpeed * dt
        end
    end

    -- Calculate collapse button position (center top of menu area)
    local collapseButtonX = (screenW - self.mCollapseButtonWidth) / 2
    local collapseButtonY = screenH - self.mCollapseButtonHeight - (self.mHeight * self.mAnimProgress)

    -- Check for collapse button click
    if gMouseReleased and gMouseReleased.button == 1 then
        if mx >= collapseButtonX and mx <= collapseButtonX + self.mCollapseButtonWidth and
           my >= collapseButtonY and my <= collapseButtonY + self.mCollapseButtonHeight then
            -- Toggle collapse
            self.mCollapsed = not self.mCollapsed
            self.mAnimating = true
            return true
        end
    end

    -- Don't process button clicks when collapsed or animating
    if self.mCollapsed or self.mAnimProgress < 0.9 then
        return true
    end

    -- Handle mouse wheel scrolling (when mouse is over menu)
    local menuY = screenH - self.mHeight

    if my >= menuY then
        -- Mouse is over menu - handle scroll
        if love.mouse.isDown(3) then  -- Middle mouse button
            -- Could implement drag scrolling
        end
    end

    -- Check for mouse clicks on buttons
    if gMouseReleased and gMouseReleased.button == 1 then
        for _, button in ipairs(self.mButtons) do
            if mx >= button.x and mx <= button.x + button.width and
               my >= button.y and my <= button.y + button.height then
                -- Check if we can afford this building
                if self:CanAffordBuilding(button.buildingType) then
                    -- Button clicked - switch to building placement state
                    gStateMachine:Change("BuildingPlacement", {buildingType = button.buildingType})
                    return false -- Stop processing input
                end
                -- If we can't afford it, don't do anything (button is disabled)
            end
        end
    end

    return true -- Continue processing input for states below
end

function BuildingMenu:Render()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    -- Calculate animated menu position
    local visibleHeight = self.mHeight * self.mAnimProgress
    local menuY = screenH - visibleHeight

    -- Calculate collapse button position
    local collapseButtonX = (screenW - self.mCollapseButtonWidth) / 2
    local collapseButtonY = menuY - self.mCollapseButtonHeight

    -- Draw collapse/expand button (always visible)
    local mx, my = love.mouse.getPosition()
    local isHoveringButton = mx >= collapseButtonX and mx <= collapseButtonX + self.mCollapseButtonWidth and
                             my >= collapseButtonY and my <= collapseButtonY + self.mCollapseButtonHeight

    -- Button background
    if isHoveringButton then
        love.graphics.setColor(0.4, 0.4, 0.4, 0.95)
    else
        love.graphics.setColor(0.3, 0.3, 0.3, 0.9)
    end
    love.graphics.rectangle("fill", collapseButtonX, collapseButtonY, self.mCollapseButtonWidth, self.mCollapseButtonHeight, 5, 5)

    -- Button border
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle("line", collapseButtonX, collapseButtonY, self.mCollapseButtonWidth, self.mCollapseButtonHeight, 5, 5)

    -- Button text/arrow
    love.graphics.setColor(1, 1, 1)
    local buttonText = self.mCollapsed and "▲ Sites" or "▼ Sites"
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(buttonText)
    love.graphics.print(buttonText, collapseButtonX + (self.mCollapseButtonWidth - textWidth) / 2, collapseButtonY + 5)

    -- Don't render menu content if fully collapsed
    if self.mAnimProgress < 0.01 then
        love.graphics.setColor(1, 1, 1)
        return
    end

    -- Draw menu background
    love.graphics.setColor(0.3, 0.3, 0.3, 0.9)
    love.graphics.rectangle("fill", 0, menuY, screenW, visibleHeight)

    -- Scissor to clip buttons to menu area
    love.graphics.setScissor(0, menuY, screenW, visibleHeight)

    -- Draw buttons (offset by animation)
    local hoveredButton = nil
    local baseMenuY = screenH - self.mHeight  -- Original menu position for button layout
    local yOffset = menuY - baseMenuY  -- How much to offset buttons

    for _, button in ipairs(self.mButtons) do
        local buttonY = button.y + yOffset

        -- Only draw if button is visible in menu area
        if buttonY + button.height >= menuY and buttonY <= menuY + visibleHeight then
            -- Check if we can afford this building
            local canAfford = self:CanAffordBuilding(button.buildingType)

            -- Check if mouse is hovering (only when fully expanded)
            local isHovering = self.mAnimProgress > 0.9 and
                              mx >= button.x and mx <= button.x + button.width and
                              my >= buttonY and my <= buttonY + button.height

            if isHovering then
                hoveredButton = button
                hoveredButton.renderY = buttonY
            end

            -- Draw button background (improved tile UI)
            if not canAfford then
                -- Gray out if can't afford
                love.graphics.setColor(0.28, 0.28, 0.28)
            elseif isHovering then
                love.graphics.setColor(button.color[1] * 1.25, button.color[2] * 1.25, button.color[3] * 1.25)
            else
                love.graphics.setColor(button.color[1], button.color[2], button.color[3])
            end
            -- subtle shadow
            love.graphics.rectangle("fill", button.x + 2, buttonY + 2, button.width, button.height, 8, 8)
            -- main tile
            love.graphics.setColor(0.15, 0.15, 0.15)
            love.graphics.rectangle("fill", button.x, buttonY, button.width, button.height, 8, 8)
            love.graphics.setColor(button.color[1], button.color[2], button.color[3])
            love.graphics.rectangle("line", button.x, buttonY, button.width, button.height, 8, 8)

            -- Draw label (two-letter uppercase) - centered
            if not canAfford then
                love.graphics.setColor(0.6, 0.6, 0.6)  -- Dimmed text
            else
                love.graphics.setColor(1, 1, 1)
            end
            local function toUpperTwo(lbl)
                local letters = string.gsub(lbl or "", "[^A-Za-z]", "")
                letters = string.upper(letters)
                if #letters >= 2 then
                    return string.sub(letters, 1, 2)
                end
                return letters
            end
            local labelText = toUpperTwo(button.label)
            local labelTextWidth = font:getWidth(labelText)
            local textHeight = font:getHeight()
            love.graphics.print(
                labelText,
                button.x + button.width / 2 - labelTextWidth / 2,
                buttonY + button.height / 2 - textHeight / 2
            )
        end
    end

    love.graphics.setScissor()

    -- Draw tooltip for hovered button
    if hoveredButton then
        local font = love.graphics.getFont()
        local lineHeight = font:getHeight()
        local tooltipLines = {hoveredButton.name}

        -- Add material requirements if any
        if hoveredButton.buildingType.constructionMaterials then
            table.insert(tooltipLines, "Required materials:")
            for commodityId, requiredAmount in pairs(hoveredButton.buildingType.constructionMaterials) do
                local availableAmount = gTown.mInventory:Get(commodityId)
                local hasEnough = availableAmount >= requiredAmount
                local colorPrefix = hasEnough and "" or "* "
                local line = string.format("%s%s: %d/%d", colorPrefix, commodityId, availableAmount, requiredAmount)
                table.insert(tooltipLines, line)
            end
        end

        -- Calculate tooltip dimensions
        local maxWidth = 0
        for _, line in ipairs(tooltipLines) do
            local lineWidth = font:getWidth(line)
            maxWidth = math.max(maxWidth, lineWidth)
        end

        local tooltipWidth = maxWidth + 20
        local tooltipHeight = (#tooltipLines * lineHeight) + 10
        local tooltipX = hoveredButton.x + hoveredButton.width / 2 - tooltipWidth / 2
        local buttonRenderY = hoveredButton.renderY or hoveredButton.y
        local tooltipY = buttonRenderY - tooltipHeight - 10

        -- Keep tooltip on screen
        local screenW = love.graphics.getWidth()
        if tooltipX < 5 then
            tooltipX = 5
        elseif tooltipX + tooltipWidth > screenW - 5 then
            tooltipX = screenW - tooltipWidth - 5
        end

        -- Tooltip background
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipWidth, tooltipHeight, 5, 5)

        -- Tooltip text
        for i, line in ipairs(tooltipLines) do
            if i == 1 then
                love.graphics.setColor(1, 1, 1)  -- White for title
            elseif i == 2 then
                love.graphics.setColor(0.8, 0.8, 0.8)  -- Light gray for "Required materials:"
            else
                -- Check if material requirement is met
                local hasStar = string.sub(line, 1, 2) == "* "
                if hasStar then
                    love.graphics.setColor(1, 0.3, 0.3)  -- Red for insufficient
                else
                    love.graphics.setColor(0.3, 1, 0.3)  -- Green for sufficient
                end
            end
            love.graphics.print(line, tooltipX, tooltipY + (i - 1) * lineHeight)
        end
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function BuildingMenu:HandleInput()
    -- Input is handled in Update
end
