--
-- BuildingMenu - bottom menu showing available buildings to place
--

require("code/BuildingTypes")

BuildingMenu = {}
BuildingMenu.__index = BuildingMenu

function BuildingMenu:Create()
    local this = {
        mHeight = 120,
        mPadding = 5,
        mButtonWidth = 60,
        mButtonHeight = 60,
        mButtons = {},
        mScrollOffset = 0,
        mMaxScroll = 0
    }

    setmetatable(this, self)

    -- Create buttons for all building types
    local allTypes = BuildingTypes.getAllTypes()
    local screenW = love.graphics.getWidth()
    local menuY = love.graphics.getHeight() - this.mHeight
    local buttonSpacing = 5
    local currentX = this.mPadding
    local currentY = menuY + this.mPadding
    local rowHeight = this.mButtonHeight + buttonSpacing

    for i, buildingType in ipairs(allTypes) do
        -- Check if we need to wrap to next row
        if currentX + this.mButtonWidth > screenW - this.mPadding then
            currentX = this.mPadding
            currentY = currentY + rowHeight
        end

        table.insert(this.mButtons, {
            buildingType = buildingType,
            label = buildingType.label,
            color = buildingType.color,
            name = buildingType.name,
            x = currentX,
            y = currentY,
            width = this.mButtonWidth,
            height = this.mButtonHeight,
            baseY = currentY  -- Store base Y for scrolling
        })

        currentX = currentX + this.mButtonWidth + buttonSpacing
    end

    -- Calculate max scroll
    local lastButton = this.mButtons[#this.mButtons]
    if lastButton then
        local totalHeight = (lastButton.baseY - menuY) + rowHeight
        this.mMaxScroll = math.max(0, totalHeight - this.mHeight + this.mPadding * 2)
    end

    return this
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
    -- Handle mouse wheel scrolling (when mouse is over menu)
    local mx, my = love.mouse.getPosition()
    local menuY = love.graphics.getHeight() - self.mHeight

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
    local menuY = love.graphics.getHeight() - self.mHeight

    -- Draw menu background
    love.graphics.setColor(0.3, 0.3, 0.3, 0.9)
    love.graphics.rectangle("fill", 0, menuY, love.graphics.getWidth(), self.mHeight)

    -- Scissor to clip buttons to menu area
    love.graphics.setScissor(0, menuY, love.graphics.getWidth(), self.mHeight)

    -- Draw buttons
    local mx, my = love.mouse.getPosition()
    local hoveredButton = nil

    for _, button in ipairs(self.mButtons) do
        -- Only draw if button is visible in menu area
        if button.y + button.height >= menuY and button.y <= menuY + self.mHeight then
            -- Check if we can afford this building
            local canAfford = self:CanAffordBuilding(button.buildingType)

            -- Check if mouse is hovering
            local isHovering = mx >= button.x and mx <= button.x + button.width and
                              my >= button.y and my <= button.y + button.height

            if isHovering then
                hoveredButton = button
            end

            -- Draw button background
            if not canAfford then
                -- Gray out if can't afford
                love.graphics.setColor(0.3, 0.3, 0.3)
            elseif isHovering then
                love.graphics.setColor(button.color[1] * 1.3, button.color[2] * 1.3, button.color[3] * 1.3)
            else
                love.graphics.setColor(button.color[1], button.color[2], button.color[3])
            end
            love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)

            -- Draw button border
            if not canAfford then
                love.graphics.setColor(0.5, 0, 0)  -- Red border for unaffordable
            else
                love.graphics.setColor(0, 0, 0)
            end
            love.graphics.rectangle("line", button.x, button.y, button.width, button.height)

            -- Draw label
            if not canAfford then
                love.graphics.setColor(0.6, 0.6, 0.6)  -- Dimmed text
            else
                love.graphics.setColor(1, 1, 1)
            end
            local font = love.graphics.getFont()
            local textWidth = font:getWidth(button.label)
            local textHeight = font:getHeight()
            love.graphics.print(
                button.label,
                button.x + button.width / 2 - textWidth / 2,
                button.y + button.height / 2 - textHeight / 2
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

        local tooltipWidth = maxWidth + 10
        local tooltipHeight = (#tooltipLines * lineHeight) + 6
        local tooltipX = hoveredButton.x + hoveredButton.width / 2 - tooltipWidth / 2
        local tooltipY = hoveredButton.y - tooltipHeight - 10

        -- Tooltip background
        love.graphics.setColor(0, 0, 0, 0.9)
        love.graphics.rectangle("fill", tooltipX - 5, tooltipY - 3, tooltipWidth, tooltipHeight)

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
