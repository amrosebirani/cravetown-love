--
-- PlotSelectionModal.lua
-- Modal for selecting land plots during immigration of wealthy/merchant applicants
--
-- ┌─────────────────────────────────────────────────────────────────────────────────┐
-- │ SELECT LAND PLOTS                                                           [X] │
-- ├─────────────────────────────────────────────────────────────────────────────────┤
-- │ Applicant: Heinrich Mueller    Role: wealthy    Wealth: 5000 gold               │
-- │ Required: 4-10 plots                                         Selected: 4        │
-- ├────────────────────────────────────────────────┬────────────────────────────────┤
-- │                                                │ Available Plots (45)  [List]   │
-- │   ┌───┬───┬───┬───┬───┬───┬───┬───┐          │ ┌────────────────────────────┐  │
-- │   │   │   │ ▓ │ ▓ │   │ ≈ │ ≈ │   │          │ │ Plot 12,8     150g      ☑ │  │
-- │   ├───┼───┼───┼───┼───┼───┼───┼───┤          │ │ grass       river-adjacent │  │
-- │   │   │ ▓ │ ▓ │ ▓ │   │ ≈ │   │   │          │ ├────────────────────────────┤  │
-- │   ├───┼───┼───┼───┼───┼───┼───┼───┤          │ │ Plot 13,8     140g      ☐ │  │
-- │   │   │ ▓ │ ▒ │ ▒ │   │   │   │ ♦ │          │ │ grass                      │  │
-- │   ├───┼───┼───┼───┼───┼───┼───┼───┤          │ ├────────────────────────────┤  │
-- │   │   │   │ ▒ │ ▒ │   │   │ ♦ │ ♦ │          │ │ Plot 14,9     180g      ☑ │  │
-- │   └───┴───┴───┴───┴───┴───┴───┴───┘          │ │ fertile      iron ore      │  │
-- │                                                │ └────────────────────────────┘  │
-- │   Drag to pan, scroll to zoom, click to select│                                 │
-- ├────────────────────────────────────────────────┴────────────────────────────────┤
-- │ Selected Plots: 4      Total Cost: 620 gold      Remaining: 4380 gold           │
-- │ Ready to confirm land purchase                                                  │
-- │                                                      [CANCEL]    [CONFIRM]      │
-- └─────────────────────────────────────────────────────────────────────────────────┘
--
-- LEGEND:
--   ▓ = Selected plot (green highlight)
--   ▒ = Available plot (dim green)
--   ≈ = Water (blocked)
--   ♦ = Mountain (blocked)
--   (empty) = Unavailable/owned
--

local PlotSelectionModal = {}
PlotSelectionModal.__index = PlotSelectionModal

function PlotSelectionModal:Create(world, applicant, onComplete, onCancel)
    local modal = setmetatable({}, PlotSelectionModal)

    modal.world = world
    modal.applicant = applicant
    modal.onComplete = onComplete
    modal.onCancel = onCancel

    -- Get land requirements for this applicant
    local landReqs = applicant.landRequirements or {}
    modal.minPlots = landReqs.minPlots or 0
    modal.maxPlots = landReqs.maxPlots or 10

    -- Track selected plots
    modal.selectedPlots = {}
    modal.totalCost = 0

    -- Get available plots
    modal.availablePlots = {}
    if world.landSystem then
        local townPlots = world.landSystem:GetAvailablePlots()
        for _, plot in ipairs(townPlots) do
            -- Check if applicant can afford this plot
            if (plot.purchasePrice or 0) <= (applicant.wealth or 0) then
                table.insert(modal.availablePlots, plot)
            end
        end
        -- Sort by price (cheapest first)
        table.sort(modal.availablePlots, function(a, b)
            return (a.purchasePrice or 0) < (b.purchasePrice or 0)
        end)
    end

    -- UI State
    modal.scrollOffset = 0
    modal.maxScroll = 0
    modal.hoverPlotId = nil

    -- Grid view state
    modal.showGridView = true
    modal.gridCameraX = 0
    modal.gridCameraY = 0
    modal.gridZoom = 0.15  -- Show larger area

    -- Center grid camera on first available plot
    if #modal.availablePlots > 0 then
        local firstPlot = modal.availablePlots[1]
        modal.gridCameraX = firstPlot.worldX - 400
        modal.gridCameraY = firstPlot.worldY - 300
    end

    -- Fonts
    modal.fonts = {
        title = love.graphics.newFont(20),
        header = love.graphics.newFont(16),
        normal = love.graphics.newFont(14),
        small = love.graphics.newFont(12),
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
        plotAvailable = {0.2, 0.5, 0.2, 0.5},
        plotSelected = {0.4, 0.7, 0.4, 0.7},
        plotUnavailable = {0.5, 0.3, 0.3, 0.3},
        plotHover = {0.5, 0.6, 0.8, 0.5},
        gridLines = {0.3, 0.3, 0.3, 0.4}
    }

    return modal
end

function PlotSelectionModal:Update(dt)
    -- Could add animations here
end

function PlotSelectionModal:Render()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Modal dimensions (larger to show grid)
    local modalW = 1000
    local modalH = 700
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
    love.graphics.print("SELECT LAND PLOTS", modalX + 20, modalY + 15)

    -- Close button
    local closeX = modalX + modalW - 40
    local closeY = modalY + 10
    love.graphics.setFont(self.fonts.header)
    love.graphics.setColor(self.colors.danger)
    love.graphics.print("X", closeX + 8, closeY + 2)
    self.closeBtn = {x = closeX, y = closeY, w = 30, h = 30}

    -- Applicant info bar
    local infoY = modalY + 45
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Applicant: " .. self.applicant.name, modalX + 20, infoY)
    love.graphics.print("Role: " .. (self.applicant.intendedRole or "unknown"), modalX + 250, infoY)

    love.graphics.setColor(self.colors.gold)
    love.graphics.print("Wealth: " .. self.applicant.wealth .. " gold", modalX + 400, infoY)

    -- Requirements
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print(string.format("Required: %d-%d plots", self.minPlots, self.maxPlots), modalX + 580, infoY)

    -- Selection status
    local selectedCount = #self.selectedPlots
    local statusColor = selectedCount >= self.minPlots and self.colors.success or self.colors.warning
    love.graphics.setColor(statusColor)
    love.graphics.print(string.format("Selected: %d", selectedCount), modalX + 750, infoY)

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(modalX + 20, infoY + 25, modalX + modalW - 20, infoY + 25)

    -- Main content area - split into grid view and list
    local contentY = infoY + 35
    local contentH = modalH - 150

    if self.showGridView then
        -- Grid view (left 60%)
        local gridW = modalW * 0.6 - 30
        local gridH = contentH
        self:RenderGridView(modalX + 15, contentY, gridW, gridH)

        -- Plot list (right 40%)
        local listX = modalX + gridW + 25
        local listW = modalW * 0.4 - 25
        self:RenderPlotList(listX, contentY, listW, gridH)
    else
        -- Full list view
        self:RenderPlotList(modalX + 15, contentY, modalW - 30, contentH)
    end

    -- Bottom bar with totals and action buttons
    self:RenderBottomBar(modalX, modalY + modalH - 70, modalW)

    love.graphics.setColor(1, 1, 1)
end

function PlotSelectionModal:RenderGridView(x, y, w, h)
    -- Background
    love.graphics.setColor(0.05, 0.08, 0.05)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)

    -- Clip to grid area
    love.graphics.setScissor(x, y, w, h)

    local landSystem = self.world.landSystem
    if not landSystem then
        love.graphics.setScissor()
        return
    end

    local plotWidth = landSystem.plotWidth
    local plotHeight = landSystem.plotHeight
    local zoom = self.gridZoom

    -- Calculate visible grid range
    local startGridX = math.floor(self.gridCameraX / plotWidth)
    local startGridY = math.floor(self.gridCameraY / plotHeight)
    local endGridX = math.ceil((self.gridCameraX + w / zoom) / plotWidth)
    local endGridY = math.ceil((self.gridCameraY + h / zoom) / plotHeight)

    -- Clamp to grid bounds
    startGridX = math.max(0, startGridX)
    startGridY = math.max(0, startGridY)
    endGridX = math.min(landSystem.gridColumns - 1, endGridX)
    endGridY = math.min(landSystem.gridRows - 1, endGridY)

    -- Draw terrain background (simplified)
    for gx = startGridX, endGridX do
        for gy = startGridY, endGridY do
            local plotId = landSystem:GetPlotId(gx, gy)
            local plot = landSystem.plots[plotId]

            if plot then
                local screenX = x + (gx * plotWidth - self.gridCameraX) * zoom
                local screenY = y + (gy * plotHeight - self.gridCameraY) * zoom
                local screenW = plotWidth * zoom
                local screenH = plotHeight * zoom

                -- Terrain color
                if plot.isBlocked then
                    if plot.terrainType == "water" then
                        love.graphics.setColor(0.2, 0.3, 0.5, 0.6)
                    elseif plot.terrainType == "mountain" then
                        love.graphics.setColor(0.4, 0.35, 0.3, 0.6)
                    else
                        love.graphics.setColor(0.3, 0.3, 0.3, 0.4)
                    end
                elseif plot.terrainType == "forest" then
                    love.graphics.setColor(0.15, 0.35, 0.15, 0.5)
                else
                    love.graphics.setColor(0.2, 0.35, 0.2, 0.3)
                end
                love.graphics.rectangle("fill", screenX, screenY, screenW, screenH)
            end
        end
    end

    -- Draw plot overlays
    for gx = startGridX, endGridX do
        for gy = startGridY, endGridY do
            local plotId = landSystem:GetPlotId(gx, gy)
            local plot = landSystem.plots[plotId]

            if plot then
                local screenX = x + (gx * plotWidth - self.gridCameraX) * zoom
                local screenY = y + (gy * plotHeight - self.gridCameraY) * zoom
                local screenW = plotWidth * zoom
                local screenH = plotHeight * zoom

                -- Check if this plot is available, selected, or unavailable
                local isSelected = self:IsPlotSelected(plotId)
                local isAvailable = self:IsPlotAvailable(plotId)
                local isHovered = self.hoverPlotId == plotId

                if isSelected then
                    love.graphics.setColor(self.colors.plotSelected)
                    love.graphics.rectangle("fill", screenX, screenY, screenW, screenH)
                    -- Selection border
                    love.graphics.setColor(0.4, 0.9, 0.4)
                    love.graphics.setLineWidth(2)
                    love.graphics.rectangle("line", screenX, screenY, screenW, screenH)
                    love.graphics.setLineWidth(1)
                elseif isHovered and isAvailable then
                    love.graphics.setColor(self.colors.plotHover)
                    love.graphics.rectangle("fill", screenX, screenY, screenW, screenH)
                elseif isAvailable then
                    love.graphics.setColor(self.colors.plotAvailable)
                    love.graphics.rectangle("fill", screenX, screenY, screenW, screenH)
                end

                -- Grid lines
                love.graphics.setColor(self.colors.gridLines)
                love.graphics.rectangle("line", screenX, screenY, screenW, screenH)

                -- Price label for available plots (if zoomed in enough)
                if isAvailable and screenW > 30 then
                    love.graphics.setFont(self.fonts.tiny)
                    love.graphics.setColor(self.colors.gold)
                    local price = plot.purchasePrice or 0
                    love.graphics.print(price, screenX + 2, screenY + 2)
                end
            end
        end
    end

    love.graphics.setScissor()

    -- Grid view controls hint
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.setColor(self.colors.textDim)
    love.graphics.print("Drag to pan, scroll to zoom, click to select", x + 5, y + h - 15)

    -- Store grid area for interaction
    self.gridArea = {x = x, y = y, w = w, h = h}
end

function PlotSelectionModal:RenderPlotList(x, y, w, h)
    -- Background
    love.graphics.setColor(0.08, 0.08, 0.1)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)

    -- Header
    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Available Plots (" .. #self.availablePlots .. ")", x + 10, y + 5)

    -- Toggle view button
    local toggleBtnX = x + w - 80
    local toggleBtnY = y + 5
    love.graphics.setColor(self.colors.button)
    love.graphics.rectangle("fill", toggleBtnX, toggleBtnY, 70, 20, 3, 3)
    love.graphics.setColor(self.colors.text)
    love.graphics.setFont(self.fonts.tiny)
    love.graphics.print(self.showGridView and "List Only" or "Show Grid", toggleBtnX + 5, toggleBtnY + 4)
    self.toggleViewBtn = {x = toggleBtnX, y = toggleBtnY, w = 70, h = 20}

    -- Scrollable list
    local listY = y + 30
    local listH = h - 35
    local cardH = 50
    local spacing = 5

    love.graphics.setScissor(x, listY, w, listH)

    self.plotCards = {}

    for i, plot in ipairs(self.availablePlots) do
        local cardY = listY + (i - 1) * (cardH + spacing) - self.scrollOffset

        -- Skip if off-screen
        if cardY + cardH < listY or cardY > y + h then
            goto continue
        end

        local isSelected = self:IsPlotSelected(plot.id)

        -- Card background
        if isSelected then
            love.graphics.setColor(0.2, 0.35, 0.2)
        else
            love.graphics.setColor(0.15, 0.15, 0.18)
        end
        love.graphics.rectangle("fill", x + 5, cardY, w - 10, cardH, 3, 3)

        -- Selection indicator
        if isSelected then
            love.graphics.setColor(self.colors.success)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", x + 5, cardY, w - 10, cardH, 3, 3)
            love.graphics.setLineWidth(1)

            -- Checkmark
            love.graphics.setFont(self.fonts.normal)
            love.graphics.print("✓", x + w - 25, cardY + 15)
        end

        -- Plot info
        love.graphics.setFont(self.fonts.small)
        love.graphics.setColor(self.colors.text)
        love.graphics.print(string.format("Plot %d, %d", plot.gridX, plot.gridY), x + 10, cardY + 5)

        love.graphics.setFont(self.fonts.tiny)
        love.graphics.setColor(self.colors.textDim)
        love.graphics.print(plot.terrainType or "grass", x + 10, cardY + 20)

        -- Natural resources
        if plot.naturalResources and #plot.naturalResources > 0 then
            love.graphics.setColor(0.5, 0.7, 0.5)
            love.graphics.print(table.concat(plot.naturalResources, ", "), x + 80, cardY + 20)
        end

        -- Price
        love.graphics.setFont(self.fonts.normal)
        love.graphics.setColor(self.colors.gold)
        love.graphics.print(plot.purchasePrice .. "g", x + w - 60, cardY + 15)

        -- Store card bounds
        self.plotCards[i] = {x = x + 5, y = cardY, w = w - 10, h = cardH, plot = plot}

        ::continue::
    end

    -- Calculate max scroll
    self.maxScroll = math.max(0, #self.availablePlots * (cardH + spacing) - listH)

    love.graphics.setScissor()

    -- Store list area for scroll detection
    self.listArea = {x = x, y = listY, w = w, h = listH}
end

function PlotSelectionModal:RenderBottomBar(x, y, w)
    -- Background
    love.graphics.setColor(0.12, 0.12, 0.15)
    love.graphics.rectangle("fill", x, y, w, 70)

    -- Divider
    love.graphics.setColor(0.3, 0.3, 0.35)
    love.graphics.line(x + 20, y, x + w - 20, y)

    -- Cost summary
    local summaryX = x + 20
    local summaryY = y + 10

    love.graphics.setFont(self.fonts.normal)
    love.graphics.setColor(self.colors.text)
    love.graphics.print("Selected Plots: " .. #self.selectedPlots, summaryX, summaryY)

    -- Total cost
    love.graphics.setColor(self.colors.gold)
    love.graphics.print("Total Cost: " .. self.totalCost .. " gold", summaryX + 180, summaryY)

    -- Remaining wealth
    local remaining = self.applicant.wealth - self.totalCost
    local remainingColor = remaining >= 0 and self.colors.success or self.colors.danger
    love.graphics.setColor(remainingColor)
    love.graphics.print("Remaining: " .. remaining .. " gold", summaryX + 380, summaryY)

    -- Validation message
    summaryY = summaryY + 22
    love.graphics.setFont(self.fonts.small)
    if #self.selectedPlots < self.minPlots then
        love.graphics.setColor(self.colors.warning)
        love.graphics.print("Select at least " .. self.minPlots .. " plots to proceed", summaryX, summaryY)
    elseif remaining < 0 then
        love.graphics.setColor(self.colors.danger)
        love.graphics.print("Not enough gold for selected plots", summaryX, summaryY)
    else
        love.graphics.setColor(self.colors.success)
        love.graphics.print("Ready to confirm land purchase", summaryX, summaryY)
    end

    -- Action buttons
    local btnW = 120
    local btnH = 35
    local btnY = y + 17

    -- Cancel button
    local cancelX = x + w - btnW * 2 - 30
    love.graphics.setColor(self.colors.danger[1], self.colors.danger[2], self.colors.danger[3], 0.8)
    love.graphics.rectangle("fill", cancelX, btnY, btnW, btnH, 4, 4)
    love.graphics.setColor(self.colors.text)
    love.graphics.setFont(self.fonts.normal)
    local cancelText = "CANCEL"
    local cancelTextW = self.fonts.normal:getWidth(cancelText)
    love.graphics.print(cancelText, cancelX + (btnW - cancelTextW) / 2, btnY + 8)
    self.cancelBtn = {x = cancelX, y = btnY, w = btnW, h = btnH}

    -- Confirm button
    local confirmX = x + w - btnW - 15
    local canConfirm = #self.selectedPlots >= self.minPlots and (self.applicant.wealth - self.totalCost) >= 0
    if canConfirm then
        love.graphics.setColor(self.colors.success[1], self.colors.success[2], self.colors.success[3], 0.9)
    else
        love.graphics.setColor(0.3, 0.3, 0.3)
    end
    love.graphics.rectangle("fill", confirmX, btnY, btnW, btnH, 4, 4)
    love.graphics.setColor(1, 1, 1, canConfirm and 1 or 0.5)
    local confirmText = "CONFIRM"
    local confirmTextW = self.fonts.normal:getWidth(confirmText)
    love.graphics.print(confirmText, confirmX + (btnW - confirmTextW) / 2, btnY + 8)
    self.confirmBtn = {x = confirmX, y = btnY, w = btnW, h = btnH, enabled = canConfirm}
end

function PlotSelectionModal:IsPlotSelected(plotId)
    for _, id in ipairs(self.selectedPlots) do
        if id == plotId then
            return true
        end
    end
    return false
end

function PlotSelectionModal:IsPlotAvailable(plotId)
    for _, plot in ipairs(self.availablePlots) do
        if plot.id == plotId then
            return true
        end
    end
    return false
end

function PlotSelectionModal:TogglePlotSelection(plotId)
    local plot = nil
    for _, p in ipairs(self.availablePlots) do
        if p.id == plotId then
            plot = p
            break
        end
    end

    if not plot then return end

    if self:IsPlotSelected(plotId) then
        -- Deselect
        for i, id in ipairs(self.selectedPlots) do
            if id == plotId then
                table.remove(self.selectedPlots, i)
                self.totalCost = self.totalCost - (plot.purchasePrice or 0)
                break
            end
        end
    else
        -- Select (if under max and can afford)
        if #self.selectedPlots < self.maxPlots then
            local newTotal = self.totalCost + (plot.purchasePrice or 0)
            if newTotal <= self.applicant.wealth then
                table.insert(self.selectedPlots, plotId)
                self.totalCost = newTotal
            end
        end
    end
end

function PlotSelectionModal:HandleClick(x, y, button)
    -- Close button
    if self.closeBtn then
        local btn = self.closeBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            if self.onCancel then self.onCancel() end
            return true
        end
    end

    -- Toggle view button
    if self.toggleViewBtn then
        local btn = self.toggleViewBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            self.showGridView = not self.showGridView
            return true
        end
    end

    -- Cancel button
    if self.cancelBtn then
        local btn = self.cancelBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            if self.onCancel then self.onCancel() end
            return true
        end
    end

    -- Confirm button
    if self.confirmBtn and self.confirmBtn.enabled then
        local btn = self.confirmBtn
        if x >= btn.x and x < btn.x + btn.w and y >= btn.y and y < btn.y + btn.h then
            if self.onComplete then
                self.onComplete(self.selectedPlots, self.totalCost)
            end
            return true
        end
    end

    -- Grid view click
    if self.gridArea and self.showGridView then
        local ga = self.gridArea
        if x >= ga.x and x < ga.x + ga.w and y >= ga.y and y < ga.y + ga.h then
            -- Convert screen coords to grid coords
            local landSystem = self.world.landSystem
            if landSystem then
                local worldX = (x - ga.x) / self.gridZoom + self.gridCameraX
                local worldY = (y - ga.y) / self.gridZoom + self.gridCameraY

                local gridX = math.floor(worldX / landSystem.plotWidth)
                local gridY = math.floor(worldY / landSystem.plotHeight)

                local plotId = landSystem:GetPlotId(gridX, gridY)
                if plotId and self:IsPlotAvailable(plotId) then
                    self:TogglePlotSelection(plotId)
                end
            end
            return true
        end
    end

    -- Plot list click
    if self.plotCards then
        for _, card in ipairs(self.plotCards) do
            if card and x >= card.x and x < card.x + card.w and y >= card.y and y < card.y + card.h then
                if card.plot then
                    self:TogglePlotSelection(card.plot.id)
                end
                return true
            end
        end
    end

    return true  -- Consume click
end

function PlotSelectionModal:HandleMouseWheel(x, y, dx, dy)
    local mouseX, mouseY = love.mouse.getPosition()

    -- Scroll plot list
    if self.listArea then
        local la = self.listArea
        if mouseX >= la.x and mouseX < la.x + la.w and mouseY >= la.y and mouseY < la.y + la.h then
            self.scrollOffset = math.max(0, math.min(self.maxScroll, self.scrollOffset - dy * 30))
            return true
        end
    end

    -- Zoom grid view
    if self.gridArea and self.showGridView then
        local ga = self.gridArea
        if mouseX >= ga.x and mouseX < ga.x + ga.w and mouseY >= ga.y and mouseY < ga.y + ga.h then
            local oldZoom = self.gridZoom
            self.gridZoom = math.max(0.05, math.min(0.5, self.gridZoom + dy * 0.02))

            -- Zoom towards mouse position
            local worldX = (mouseX - ga.x) / oldZoom + self.gridCameraX
            local worldY = (mouseY - ga.y) / oldZoom + self.gridCameraY
            self.gridCameraX = worldX - (mouseX - ga.x) / self.gridZoom
            self.gridCameraY = worldY - (mouseY - ga.y) / self.gridZoom

            return true
        end
    end

    return false
end

function PlotSelectionModal:HandleMouseMove(x, y, dx, dy)
    -- Update hover state for grid
    if self.gridArea and self.showGridView then
        local ga = self.gridArea
        if x >= ga.x and x < ga.x + ga.w and y >= ga.y and y < ga.y + ga.h then
            local landSystem = self.world.landSystem
            if landSystem then
                local worldX = (x - ga.x) / self.gridZoom + self.gridCameraX
                local worldY = (y - ga.y) / self.gridZoom + self.gridCameraY

                local gridX = math.floor(worldX / landSystem.plotWidth)
                local gridY = math.floor(worldY / landSystem.plotHeight)

                self.hoverPlotId = landSystem:GetPlotId(gridX, gridY)
            end
        else
            self.hoverPlotId = nil
        end
    end
end

function PlotSelectionModal:HandleDrag(dx, dy)
    -- Pan grid view when dragging
    if self.gridArea and self.showGridView then
        self.gridCameraX = self.gridCameraX - dx / self.gridZoom
        self.gridCameraY = self.gridCameraY - dy / self.gridZoom
    end
end

function PlotSelectionModal:HandleKeyPress(key)
    if key == "escape" then
        if self.onCancel then self.onCancel() end
        return true
    end
    return false
end

return PlotSelectionModal
