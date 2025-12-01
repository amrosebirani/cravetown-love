--
-- ResourceOverlay - Renders resource distribution overlays on the game map
-- Supports toggle-able layers for each resource type with color-coded visualization
--

ResourceOverlay = {}
ResourceOverlay.__index = ResourceOverlay

--
-- Create a new ResourceOverlay renderer
--
-- @param naturalResources - Reference to NaturalResources manager
--
function ResourceOverlay:Create(naturalResources)
    local this = {
        -- Reference to natural resources manager
        mNaturalResources = naturalResources,

        -- Track which overlays are visible
        mVisibleOverlays = {},

        -- Cached canvases for each resource (for performance)
        mCanvases = {},

        -- Canvas dirty flags (need regeneration)
        mDirty = {},

        -- Global overlay opacity multiplier
        mGlobalOpacity = 1.0,

        -- Show deposit markers (disabled for cleaner uniform view)
        mShowDepositMarkers = false,

        -- Panel visibility
        mPanelVisible = false,

        -- Panel position
        mPanelX = 10,
        mPanelY = 100,
        mPanelWidth = 200,
        mPanelHeight = 0,  -- Calculated based on resources
    }

    setmetatable(this, self)

    -- Initialize visibility (all off by default)
    local resourceIds = naturalResources:getAllResourceIds()
    for _, id in ipairs(resourceIds) do
        this.mVisibleOverlays[id] = false
        this.mDirty[id] = true
    end

    -- Calculate panel height
    this.mPanelHeight = 60 + (#resourceIds * 28)

    return this
end

--
-- Toggle overlay visibility for a resource
--
function ResourceOverlay:toggleOverlay(resourceId)
    self.mVisibleOverlays[resourceId] = not self.mVisibleOverlays[resourceId]
    return self.mVisibleOverlays[resourceId]
end

--
-- Show overlay for a resource
--
function ResourceOverlay:showOverlay(resourceId)
    self.mVisibleOverlays[resourceId] = true
end

--
-- Hide overlay for a resource
--
function ResourceOverlay:hideOverlay(resourceId)
    self.mVisibleOverlays[resourceId] = false
end

--
-- Hide all overlays
--
function ResourceOverlay:hideAll()
    for id, _ in pairs(self.mVisibleOverlays) do
        self.mVisibleOverlays[id] = false
    end
end

--
-- Show all overlays
--
function ResourceOverlay:showAll()
    for id, _ in pairs(self.mVisibleOverlays) do
        self.mVisibleOverlays[id] = true
    end
end

--
-- Check if any overlay is visible
--
function ResourceOverlay:hasVisibleOverlays()
    for _, visible in pairs(self.mVisibleOverlays) do
        if visible then
            return true
        end
    end
    return false
end

--
-- Set global opacity multiplier
--
function ResourceOverlay:setGlobalOpacity(opacity)
    self.mGlobalOpacity = math.max(0, math.min(1, opacity))
end

--
-- Toggle deposit markers
--
function ResourceOverlay:toggleDepositMarkers()
    self.mShowDepositMarkers = not self.mShowDepositMarkers
    return self.mShowDepositMarkers
end

--
-- Toggle panel visibility
--
function ResourceOverlay:togglePanel()
    self.mPanelVisible = not self.mPanelVisible
    return self.mPanelVisible
end

--
-- Mark overlay as dirty (needs regeneration)
--
function ResourceOverlay:markDirty(resourceId)
    if resourceId then
        self.mDirty[resourceId] = true
    else
        -- Mark all dirty
        for id, _ in pairs(self.mDirty) do
            self.mDirty[id] = true
        end
    end
end

--
-- Generate canvas for a resource overlay
--
function ResourceOverlay:generateCanvas(resourceId)
    local def = self.mNaturalResources:getDefinition(resourceId)
    if not def then return nil end

    local gridWidth, gridHeight, cellSize = self.mNaturalResources:getGridDimensions()
    local minX, maxX, minY, maxY = self.mNaturalResources:getBoundaries()

    local canvasWidth = gridWidth * cellSize
    local canvasHeight = gridHeight * cellSize

    -- Create canvas
    local canvas = love.graphics.newCanvas(canvasWidth, canvasHeight)

    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)

    local gridData = self.mNaturalResources:getGridData(resourceId)
    if not gridData then
        love.graphics.setCanvas()
        return canvas
    end

    local viz = def.visualization or {}
    local color = viz.color or {0.5, 0.5, 0.5}
    local baseOpacity = viz.opacity or 0.6
    local showThreshold = viz.showThreshold or 0.1

    -- Draw grid cells
    for gx = 1, gridWidth do
        for gy = 1, gridHeight do
            local value = gridData[gx] and gridData[gx][gy] or 0

            if value >= showThreshold then
                local alpha = value * baseOpacity
                love.graphics.setColor(color[1], color[2], color[3], alpha)
                love.graphics.rectangle("fill",
                    (gx - 1) * cellSize,
                    (gy - 1) * cellSize,
                    cellSize,
                    cellSize
                )
            end
        end
    end

    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)

    return canvas
end

--
-- Ensure canvas is generated and up to date
--
function ResourceOverlay:ensureCanvas(resourceId)
    if self.mDirty[resourceId] or not self.mCanvases[resourceId] then
        self.mCanvases[resourceId] = self:generateCanvas(resourceId)
        self.mDirty[resourceId] = false
    end
    return self.mCanvases[resourceId]
end

--
-- Render a single resource overlay (direct mode - no canvas)
--
function ResourceOverlay:renderResource(resourceId)
    if not self.mVisibleOverlays[resourceId] then
        return
    end

    local def = self.mNaturalResources:getDefinition(resourceId)
    if not def then return end

    local gridWidth, gridHeight, cellSize = self.mNaturalResources:getGridDimensions()
    local minX, maxX, minY, maxY = self.mNaturalResources:getBoundaries()

    local gridData = self.mNaturalResources:getGridData(resourceId)
    if not gridData then return end

    local viz = def.visualization or {}
    local color = viz.color or {0.5, 0.5, 0.5}
    local baseOpacity = viz.opacity or 0.6
    local showThreshold = viz.showThreshold or 0.1

    -- Draw grid cells directly in world space
    for gx = 1, gridWidth do
        for gy = 1, gridHeight do
            local value = gridData[gx] and gridData[gx][gy] or 0

            if value >= showThreshold then
                local alpha = value * baseOpacity * self.mGlobalOpacity
                love.graphics.setColor(color[1], color[2], color[3], alpha)
                love.graphics.rectangle("fill",
                    minX + (gx - 1) * cellSize,
                    minY + (gy - 1) * cellSize,
                    cellSize,
                    cellSize
                )
            end
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

--
-- Render all visible overlays
--
function ResourceOverlay:render()
    if not self.mNaturalResources:isGenerated() then
        return
    end

    -- Render each visible overlay
    for resourceId, visible in pairs(self.mVisibleOverlays) do
        if visible then
            self:renderResource(resourceId)
        end
    end
end

--
-- Render the control panel (call in screen space, not world space)
--
function ResourceOverlay:renderPanel()
    if not self.mPanelVisible then
        return
    end

    local x = self.mPanelX
    local y = self.mPanelY
    local w = self.mPanelWidth
    local h = self.mPanelHeight

    -- Panel background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", x, y, w, h, 5, 5)

    -- Panel border
    love.graphics.setColor(0.4, 0.4, 0.4, 1)
    love.graphics.rectangle("line", x, y, w, h, 5, 5)

    -- Title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Resource Overlays", x + 10, y + 8)

    -- Buttons row
    local btnY = y + 30

    -- Hide All button
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", x + 10, btnY, 85, 20, 3, 3)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Hide All", x + 20, btnY + 3)

    -- Show All button
    love.graphics.setColor(0.3, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", x + 105, btnY, 85, 20, 3, 3)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Show All", x + 115, btnY + 3)

    -- Resource list
    local resourceIds = self.mNaturalResources:getAllResourceIds()
    local itemY = btnY + 30

    for i, resourceId in ipairs(resourceIds) do
        local def = self.mNaturalResources:getDefinition(resourceId)
        if def then
            local visible = self.mVisibleOverlays[resourceId]
            local viz = def.visualization or {}
            local color = viz.color or {0.5, 0.5, 0.5}

            -- Checkbox background
            love.graphics.setColor(0.2, 0.2, 0.2, 1)
            love.graphics.rectangle("fill", x + 10, itemY, 18, 18, 2, 2)

            -- Checkbox border
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
            love.graphics.rectangle("line", x + 10, itemY, 18, 18, 2, 2)

            -- Checkmark if visible
            if visible then
                love.graphics.setColor(0.2, 0.8, 0.2, 1)
                love.graphics.print("✓", x + 13, itemY + 1)
            end

            -- Color swatch
            love.graphics.setColor(color[1], color[2], color[3], 1)
            love.graphics.rectangle("fill", x + 35, itemY + 2, 14, 14, 2, 2)
            love.graphics.setColor(0.6, 0.6, 0.6, 1)
            love.graphics.rectangle("line", x + 35, itemY + 2, 14, 14, 2, 2)

            -- Resource name
            love.graphics.setColor(1, 1, 1, visible and 1 or 0.5)
            local displayName = def.name or resourceId
            if #displayName > 15 then
                displayName = string.sub(displayName, 1, 14) .. "..."
            end
            love.graphics.print(displayName, x + 55, itemY + 2)

            itemY = itemY + 24
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

--
-- Handle mouse click on panel
-- Returns true if click was handled
--
function ResourceOverlay:handlePanelClick(mouseX, mouseY)
    if not self.mPanelVisible then
        return false
    end

    local x = self.mPanelX
    local y = self.mPanelY
    local w = self.mPanelWidth
    local h = self.mPanelHeight

    -- Check if click is within panel
    if mouseX < x or mouseX > x + w or mouseY < y or mouseY > y + h then
        return false
    end

    local btnY = y + 30

    -- Hide All button
    if mouseX >= x + 10 and mouseX <= x + 95 and mouseY >= btnY and mouseY <= btnY + 20 then
        self:hideAll()
        return true
    end

    -- Show All button
    if mouseX >= x + 105 and mouseX <= x + 190 and mouseY >= btnY and mouseY <= btnY + 20 then
        self:showAll()
        return true
    end

    -- Resource checkboxes
    local resourceIds = self.mNaturalResources:getAllResourceIds()
    local itemY = btnY + 30

    for i, resourceId in ipairs(resourceIds) do
        -- Click on checkbox or row
        if mouseY >= itemY and mouseY <= itemY + 24 and mouseX >= x + 10 and mouseX <= x + w - 10 then
            self:toggleOverlay(resourceId)
            return true
        end
        itemY = itemY + 24
    end

    return true  -- Click was in panel area
end

--
-- Handle keyboard input
--
function ResourceOverlay:handleKeyPress(key)
    if key == "r" then
        self:togglePanel()
        return true
    end

    -- Number keys 1-9 for quick toggle (if panel is visible)
    if self.mPanelVisible then
        local num = tonumber(key)
        if num and num >= 1 and num <= 9 then
            local resourceIds = self.mNaturalResources:getAllResourceIds()
            if resourceIds[num] then
                self:toggleOverlay(resourceIds[num])
                return true
            end
        end
    end

    return false
end

--
-- Get visible overlay count
--
function ResourceOverlay:getVisibleCount()
    local count = 0
    for _, visible in pairs(self.mVisibleOverlays) do
        if visible then
            count = count + 1
        end
    end
    return count
end

--
-- Set panel position
--
function ResourceOverlay:setPanelPosition(x, y)
    self.mPanelX = x
    self.mPanelY = y
end

--
-- Check if panel is visible
--
function ResourceOverlay:isPanelVisible()
    return self.mPanelVisible
end

--
-- Check if a specific overlay is visible
--
function ResourceOverlay:isOverlayVisible(resourceId)
    return self.mVisibleOverlays[resourceId] or false
end

return ResourceOverlay
