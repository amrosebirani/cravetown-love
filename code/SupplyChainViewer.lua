--
-- SupplyChainViewer.lua
-- Visual DAG showing how commodities are produced from raw resources
-- Shows buildings/recipes needed and current vs required state
--

local DataLoader = require("code/DataLoader")
require("code/CommodityTypes")

SupplyChainViewer = {}
SupplyChainViewer.__index = SupplyChainViewer

-- Configuration
local CONFIG = {
    modalWidth = 600,
    modalHeight = 500,
    nodeWidth = 100,
    nodeHeight = 60,
    horizontalSpacing = 120,
    verticalSpacing = 90,
    padding = 20,

    colors = {
        background = {0.12, 0.12, 0.15, 0.98},
        border = {0.4, 0.4, 0.4},
        nodeOwned = {0.2, 0.5, 0.2},           -- Green: building owned
        nodeMissing = {0.6, 0.2, 0.2},         -- Red: building not owned
        nodeRaw = {0.4, 0.4, 0.4},             -- Gray: raw resource
        nodeHighlight = {0.3, 0.5, 0.7},       -- Blue highlight
        arrow = {0.6, 0.6, 0.6},
        text = {1, 1, 1},
        textDim = {0.7, 0.7, 0.7},
        button = {0.3, 0.5, 0.7},
        buttonHover = {0.4, 0.6, 0.8},
        closeButton = {0.6, 0.2, 0.2}
    }
}

function SupplyChainViewer:Create(world)
    local viewer = setmetatable({}, SupplyChainViewer)

    viewer.world = world
    viewer.isVisible = false
    viewer.chainRoot = nil
    viewer.commodityId = nil
    viewer.commodityName = nil
    viewer.requirements = nil

    -- Layout data
    viewer.nodePositions = {}  -- {commodityId = {x, y, node}}
    viewer.maxDepth = 0
    viewer.scrollOffsetY = 0
    viewer.contentHeight = 0

    -- UI state
    viewer.closeButton = nil
    viewer.buildButton = nil
    viewer.hoveredNode = nil

    -- Cache data - use world's data if available (correct version), otherwise load from DataLoader
    if world and world.recipes then
        viewer.recipes = world.recipes
    else
        viewer.recipes = DataLoader.loadBuildingRecipes()
    end
    if world and world.buildingTypes then
        viewer.buildingTypes = world.buildingTypes
    else
        viewer.buildingTypes = DataLoader.loadBuildingTypes()
    end
    viewer.recipeByOutput = {}  -- Cached lookup: outputCommodityId -> recipe

    -- Build recipe output lookup (primary recipe per commodity)
    viewer:BuildRecipeLookup()

    return viewer
end

-- Build lookup table: commodity -> recipe that produces it
function SupplyChainViewer:BuildRecipeLookup()
    self.recipeByOutput = {}

    for _, recipe in ipairs(self.recipes) do
        if recipe.outputs then
            for outputId, quantity in pairs(recipe.outputs) do
                -- Only store first recipe found (primary)
                if not self.recipeByOutput[outputId] then
                    self.recipeByOutput[outputId] = recipe
                end
            end
        end
    end

    -- Debug: count recipes
    local count = 0
    for _ in pairs(self.recipeByOutput) do count = count + 1 end
    print("[SupplyChainViewer] Built recipe lookup with " .. count .. " output commodities")

    -- Debug: check for wheat
    if self.recipeByOutput["wheat"] then
        print("  Found recipe for wheat: " .. (self.recipeByOutput["wheat"].recipeName or "unnamed"))
    else
        print("  WARNING: No recipe found for wheat!")
    end
end

-- Find the recipe that produces a commodity
function SupplyChainViewer:FindRecipeProducing(commodityId)
    return self.recipeByOutput[commodityId]
end

-- Get building type by ID
function SupplyChainViewer:GetBuildingType(buildingTypeId)
    for _, bt in ipairs(self.buildingTypes) do
        if bt.id == buildingTypeId then
            return bt
        end
    end
    return nil
end

-- Get building name
function SupplyChainViewer:GetBuildingName(buildingTypeId)
    local bt = self:GetBuildingType(buildingTypeId)
    return bt and bt.name or buildingTypeId
end

-- Get building gold cost
function SupplyChainViewer:GetBuildingCost(buildingTypeId)
    local bt = self:GetBuildingType(buildingTypeId)
    if bt and bt.constructionCost then
        return bt.constructionCost.gold or 0
    end
    return 0
end

-- Get workers needed for building
function SupplyChainViewer:GetWorkersForBuilding(buildingTypeId)
    local bt = self:GetBuildingType(buildingTypeId)
    if bt and bt.upgradeLevels and bt.upgradeLevels[1] then
        return bt.upgradeLevels[1].workers or bt.upgradeLevels[1].stations or 1
    end
    return 1
end

-- Count how many of a building type the player owns
function SupplyChainViewer:CountBuildings(buildingTypeId)
    if not buildingTypeId or not self.world or not self.world.buildings then
        return 0
    end

    local count = 0
    for _, building in ipairs(self.world.buildings) do
        if building.mTypeId == buildingTypeId then
            count = count + 1
        end
    end
    return count
end

-- Build the supply chain DAG for a commodity
function SupplyChainViewer:BuildChain(commodityId, depth, visited)
    depth = depth or 0
    visited = visited or {}

    -- Prevent infinite recursion
    if visited[commodityId] then
        return nil
    end
    visited[commodityId] = true

    -- Use world's commodities data (which is loaded from the active version)
    local commodity = nil
    if self.world and self.world.commoditiesById then
        commodity = self.world.commoditiesById[commodityId]
    end
    if not commodity then
        commodity = CommodityTypes.getById(commodityId)
    end
    if not commodity then
        return nil
    end

    local node = {
        commodityId = commodityId,
        commodityName = commodity.name,
        icon = commodity.icon,
        depth = depth,
        inputs = {},
        isRaw = commodity.isRaw or false,
        recipe = nil,
        buildingType = nil,
        buildingName = nil,
        workersNeeded = 0,
        goldCost = 0,
        buildingsOwned = 0,
        buildingsNeeded = 1,
        canProduce = false
    }

    -- Find recipe that produces this commodity
    local recipe = self:FindRecipeProducing(commodityId)

    -- Check if this is a "seed" commodity - where the recipe that produces it
    -- also requires it as an input (self-replenishing like wheat_seed -> wheat + wheat_seed)
    -- In this case, treat it as raw since we can't trace further back
    local isSelfReplenishing = false
    if recipe and recipe.inputs and recipe.inputs[commodityId] then
        isSelfReplenishing = true
    end

    if recipe and not isSelfReplenishing then
        node.isRaw = false  -- Has a recipe, so not a raw resource
        node.recipe = recipe
        node.buildingType = recipe.buildingType
        node.buildingName = self:GetBuildingName(recipe.buildingType)
        node.workersNeeded = self:GetWorkersForBuilding(recipe.buildingType)
        node.goldCost = self:GetBuildingCost(recipe.buildingType)

        -- Recursively build child nodes for each input
        if recipe.inputs then
            for inputId, quantity in pairs(recipe.inputs) do
                local childNode = self:BuildChain(inputId, depth + 1, visited)
                if childNode then
                    table.insert(node.inputs, {
                        commodityId = inputId,
                        quantity = quantity,
                        node = childNode
                    })
                end
            end
        end

        -- Sort inputs for consistent display
        table.sort(node.inputs, function(a, b)
            return a.commodityId < b.commodityId
        end)
    else
        -- No recipe = raw resource (leaf node)
        node.isRaw = true
    end

    -- Calculate current state
    node.buildingsOwned = self:CountBuildings(node.buildingType)
    node.canProduce = node.isRaw or (node.buildingsOwned >= node.buildingsNeeded)

    -- Track max depth
    if depth > self.maxDepth then
        self.maxDepth = depth
    end

    return node
end

-- Calculate total requirements for the chain
function SupplyChainViewer:CalculateRequirements(node, requirements)
    requirements = requirements or {
        buildings = {},
        totalWorkers = 0,
        totalGold = 0,
        missing = {},
        owned = {}
    }

    if node.buildingType then
        -- Track unique buildings needed
        if not requirements.buildings[node.buildingType] then
            requirements.buildings[node.buildingType] = {
                name = node.buildingName,
                needed = 1,
                owned = node.buildingsOwned,
                workers = node.workersNeeded,
                gold = node.goldCost
            }

            if node.buildingsOwned < 1 then
                table.insert(requirements.missing, node.buildingType)
                requirements.totalWorkers = requirements.totalWorkers + node.workersNeeded
                requirements.totalGold = requirements.totalGold + node.goldCost
            else
                table.insert(requirements.owned, node.buildingType)
            end
        end
    end

    -- Recurse to children
    for _, input in ipairs(node.inputs) do
        self:CalculateRequirements(input.node, requirements)
    end

    return requirements
end

-- Layout nodes in the DAG for rendering
function SupplyChainViewer:LayoutNodes(node, depth, xOffset, layoutData)
    depth = depth or 0
    xOffset = xOffset or 0
    layoutData = layoutData or {
        nodePositions = {},
        depthWidths = {},  -- Track width needed at each depth
        depthCounts = {}   -- Track nodes at each depth
    }

    -- Initialize depth tracking
    layoutData.depthCounts[depth] = (layoutData.depthCounts[depth] or 0) + 1

    -- Calculate position based on depth
    local x = xOffset
    local y = depth * CONFIG.verticalSpacing + CONFIG.padding

    -- Store node position
    layoutData.nodePositions[node.commodityId] = {
        x = x,
        y = y,
        node = node
    }

    -- Layout children
    local childXOffset = x - ((#node.inputs - 1) * CONFIG.horizontalSpacing / 2)
    for i, input in ipairs(node.inputs) do
        self:LayoutNodes(input.node, depth + 1, childXOffset + (i - 1) * CONFIG.horizontalSpacing, layoutData)
    end

    return layoutData
end

-- Open the viewer for a specific commodity
function SupplyChainViewer:Open(commodityId)
    if not commodityId then return end

    -- Use world's commodities data (which is loaded from the active version)
    -- Fall back to CommodityTypes for backwards compatibility
    local commodity = nil
    if self.world and self.world.commoditiesById then
        commodity = self.world.commoditiesById[commodityId]
    end
    if not commodity then
        commodity = CommodityTypes.getById(commodityId)
    end
    if not commodity then
        print("[SupplyChainViewer] Unknown commodity: " .. commodityId)
        return
    end

    self.commodityId = commodityId
    self.commodityName = commodity.name
    self.maxDepth = 0
    self.scrollOffsetY = 0

    -- Build the chain
    self.chainRoot = self:BuildChain(commodityId)

    if not self.chainRoot then
        print("[SupplyChainViewer] Failed to build chain for: " .. commodityId)
        return
    end

    -- Calculate requirements
    self.requirements = self:CalculateRequirements(self.chainRoot)

    -- Layout nodes
    local layoutData = self:LayoutNodes(self.chainRoot, 0, CONFIG.modalWidth / 2)
    self.nodePositions = layoutData.nodePositions

    -- Calculate content height
    self.contentHeight = (self.maxDepth + 1) * CONFIG.verticalSpacing + CONFIG.nodeHeight + 200

    self.isVisible = true

    print("[SupplyChainViewer] Opened for: " .. self.commodityName)
    print("  Chain depth: " .. self.maxDepth)
    print("  Missing buildings: " .. #self.requirements.missing)
end

-- Close the viewer
function SupplyChainViewer:Close()
    self.isVisible = false
    self.chainRoot = nil
    self.commodityId = nil
    self.nodePositions = {}
end

-- Check if point is inside a rectangle
local function pointInRect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

-- Handle mouse click
function SupplyChainViewer:HandleClick(x, y)
    if not self.isVisible then return false end

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local modalX = (screenW - CONFIG.modalWidth) / 2
    local modalY = (screenH - CONFIG.modalHeight) / 2

    -- Check close button
    local closeX = modalX + CONFIG.modalWidth - 35
    local closeY = modalY + 10
    if pointInRect(x, y, closeX, closeY, 25, 25) then
        self:Close()
        return true
    end

    -- Check click outside modal
    if not pointInRect(x, y, modalX, modalY, CONFIG.modalWidth, CONFIG.modalHeight) then
        self:Close()
        return true
    end

    -- Check "Build Missing" button
    if self.buildButton then
        local bb = self.buildButton
        if pointInRect(x, y, bb.x, bb.y, bb.width, bb.height) then
            self:BuildMissingBuildings()
            return true
        end
    end

    return true  -- Consume click
end

-- Handle mouse wheel
function SupplyChainViewer:OnMouseWheel(dx, dy)
    if not self.isVisible then return end

    local viewHeight = CONFIG.modalHeight - 180  -- Account for header and footer
    local maxScroll = math.max(0, self.contentHeight - viewHeight)

    self.scrollOffsetY = self.scrollOffsetY - dy * 30
    self.scrollOffsetY = math.max(0, math.min(self.scrollOffsetY, maxScroll))
end

-- Build missing buildings
function SupplyChainViewer:BuildMissingBuildings()
    if not self.requirements or #self.requirements.missing == 0 then
        return
    end

    -- Enter placement mode for the first missing building
    local buildingTypeId = self.requirements.missing[1]

    if self.world and self.world.ui then
        self.world.ui:EnterPlacementMode(buildingTypeId)
        self:Close()
    end
end

-- Draw an arrow between two points
local function drawArrow(x1, y1, x2, y2, color)
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.setLineWidth(2)
    love.graphics.line(x1, y1, x2, y2)

    -- Draw arrowhead
    local angle = math.atan2(y2 - y1, x2 - x1)
    local arrowSize = 8
    local ax1 = x2 - arrowSize * math.cos(angle - math.pi / 6)
    local ay1 = y2 - arrowSize * math.sin(angle - math.pi / 6)
    local ax2 = x2 - arrowSize * math.cos(angle + math.pi / 6)
    local ay2 = y2 - arrowSize * math.sin(angle + math.pi / 6)

    love.graphics.polygon("fill", x2, y2, ax1, ay1, ax2, ay2)
    love.graphics.setLineWidth(1)
end

-- Render the viewer
function SupplyChainViewer:Render()
    if not self.isVisible or not self.chainRoot then return end

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local modalX = (screenW - CONFIG.modalWidth) / 2
    local modalY = (screenH - CONFIG.modalHeight) / 2

    -- Draw overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- Draw modal background
    love.graphics.setColor(CONFIG.colors.background[1], CONFIG.colors.background[2],
                           CONFIG.colors.background[3], CONFIG.colors.background[4])
    love.graphics.rectangle("fill", modalX, modalY, CONFIG.modalWidth, CONFIG.modalHeight, 10, 10)

    -- Draw modal border
    love.graphics.setColor(CONFIG.colors.border[1], CONFIG.colors.border[2], CONFIG.colors.border[3])
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", modalX, modalY, CONFIG.modalWidth, CONFIG.modalHeight, 10, 10)
    love.graphics.setLineWidth(1)

    -- Draw title
    love.graphics.setColor(CONFIG.colors.text[1], CONFIG.colors.text[2], CONFIG.colors.text[3])
    local titleText = "Supply Chain: " .. (self.commodityName or "Unknown")
    local font = love.graphics.getFont()
    local titleWidth = font:getWidth(titleText)
    love.graphics.print(titleText, modalX + (CONFIG.modalWidth - titleWidth) / 2, modalY + 15)

    -- Draw close button
    local closeX = modalX + CONFIG.modalWidth - 35
    local closeY = modalY + 10
    local mx, my = love.mouse.getPosition()
    local hoveringClose = pointInRect(mx, my, closeX, closeY, 25, 25)

    love.graphics.setColor(hoveringClose and 0.7 or CONFIG.colors.closeButton[1],
                           hoveringClose and 0.3 or CONFIG.colors.closeButton[2],
                           hoveringClose and 0.3 or CONFIG.colors.closeButton[3])
    love.graphics.rectangle("fill", closeX, closeY, 25, 25, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("X", closeX + 8, closeY + 4)

    -- Separator
    love.graphics.setColor(CONFIG.colors.border[1], CONFIG.colors.border[2], CONFIG.colors.border[3], 0.5)
    love.graphics.line(modalX + 10, modalY + 45, modalX + CONFIG.modalWidth - 10, modalY + 45)

    -- DAG content area (with scrolling)
    local dagAreaY = modalY + 50
    local dagAreaHeight = CONFIG.modalHeight - 180

    love.graphics.setScissor(modalX, dagAreaY, CONFIG.modalWidth, dagAreaHeight)

    -- Draw arrows first (behind nodes)
    for commodityId, pos in pairs(self.nodePositions) do
        local node = pos.node
        local nodeX = modalX + pos.x - CONFIG.nodeWidth / 2
        local nodeY = dagAreaY + pos.y - self.scrollOffsetY

        for _, input in ipairs(node.inputs) do
            local childPos = self.nodePositions[input.commodityId]
            if childPos then
                local childX = modalX + childPos.x
                local childY = dagAreaY + childPos.y - self.scrollOffsetY

                -- Arrow from child to parent (input flows up)
                drawArrow(childX, childY, nodeX + CONFIG.nodeWidth / 2, nodeY + CONFIG.nodeHeight,
                         CONFIG.colors.arrow)
            end
        end
    end

    -- Draw nodes
    self.hoveredNode = nil
    for commodityId, pos in pairs(self.nodePositions) do
        local node = pos.node
        local nodeX = modalX + pos.x - CONFIG.nodeWidth / 2
        local nodeY = dagAreaY + pos.y - self.scrollOffsetY

        -- Only draw if visible
        if nodeY + CONFIG.nodeHeight > dagAreaY and nodeY < dagAreaY + dagAreaHeight then
            -- Determine node color
            local nodeColor
            if node.isRaw then
                nodeColor = CONFIG.colors.nodeRaw
            elseif node.canProduce then
                nodeColor = CONFIG.colors.nodeOwned
            else
                nodeColor = CONFIG.colors.nodeMissing
            end

            -- Check hover
            local isHovered = pointInRect(mx, my, nodeX, nodeY, CONFIG.nodeWidth, CONFIG.nodeHeight)
            if isHovered then
                self.hoveredNode = node
            end

            -- Draw node background
            if isHovered then
                love.graphics.setColor(CONFIG.colors.nodeHighlight[1], CONFIG.colors.nodeHighlight[2],
                                       CONFIG.colors.nodeHighlight[3], 0.3)
                love.graphics.rectangle("fill", nodeX - 3, nodeY - 3, CONFIG.nodeWidth + 6, CONFIG.nodeHeight + 6, 8, 8)
            end

            love.graphics.setColor(nodeColor[1], nodeColor[2], nodeColor[3], 0.9)
            love.graphics.rectangle("fill", nodeX, nodeY, CONFIG.nodeWidth, CONFIG.nodeHeight, 5, 5)

            -- Draw node border
            love.graphics.setColor(CONFIG.colors.border[1], CONFIG.colors.border[2], CONFIG.colors.border[3])
            love.graphics.rectangle("line", nodeX, nodeY, CONFIG.nodeWidth, CONFIG.nodeHeight, 5, 5)

            -- Draw commodity name (center)
            love.graphics.setColor(CONFIG.colors.text[1], CONFIG.colors.text[2], CONFIG.colors.text[3])
            local nameText = node.commodityName or commodityId
            if #nameText > 12 then
                nameText = string.sub(nameText, 1, 11) .. ".."
            end
            local nameWidth = font:getWidth(nameText)
            love.graphics.print(nameText, nodeX + (CONFIG.nodeWidth - nameWidth) / 2, nodeY + 8)

            -- Draw building name or "Raw"
            love.graphics.setColor(CONFIG.colors.textDim[1], CONFIG.colors.textDim[2], CONFIG.colors.textDim[3])
            local subText = node.isRaw and "(Raw)" or (node.buildingName or "")
            if #subText > 14 then
                subText = string.sub(subText, 1, 13) .. ".."
            end
            local subWidth = font:getWidth(subText)
            love.graphics.print(subText, nodeX + (CONFIG.nodeWidth - subWidth) / 2, nodeY + 26)

            -- Draw owned indicator
            if not node.isRaw then
                local ownedText = node.buildingsOwned .. "/" .. node.buildingsNeeded
                local ownedWidth = font:getWidth(ownedText)
                if node.canProduce then
                    love.graphics.setColor(0.4, 0.9, 0.4)
                else
                    love.graphics.setColor(0.9, 0.4, 0.4)
                end
                love.graphics.print(ownedText, nodeX + (CONFIG.nodeWidth - ownedWidth) / 2, nodeY + 42)
            end
        end
    end

    love.graphics.setScissor()

    -- Draw requirements summary at bottom
    local summaryY = modalY + CONFIG.modalHeight - 120
    love.graphics.setColor(0.15, 0.15, 0.18)
    love.graphics.rectangle("fill", modalX + 10, summaryY, CONFIG.modalWidth - 20, 110, 5, 5)

    love.graphics.setColor(CONFIG.colors.text[1], CONFIG.colors.text[2], CONFIG.colors.text[3])
    love.graphics.print("Requirements:", modalX + 20, summaryY + 10)

    -- List missing buildings
    if self.requirements then
        local reqY = summaryY + 30

        if #self.requirements.missing > 0 then
            love.graphics.setColor(0.9, 0.4, 0.4)
            local missingText = "Missing: "
            for i, btId in ipairs(self.requirements.missing) do
                local bt = self.requirements.buildings[btId]
                missingText = missingText .. (bt and bt.name or btId)
                if i < #self.requirements.missing then
                    missingText = missingText .. ", "
                end
            end
            if #missingText > 70 then
                missingText = string.sub(missingText, 1, 67) .. "..."
            end
            love.graphics.print(missingText, modalX + 20, reqY)
            reqY = reqY + 18

            -- Workers and gold needed
            love.graphics.setColor(CONFIG.colors.textDim[1], CONFIG.colors.textDim[2], CONFIG.colors.textDim[3])
            love.graphics.print(string.format("Workers needed: %d | Gold needed: %d",
                self.requirements.totalWorkers, self.requirements.totalGold), modalX + 20, reqY)
        else
            love.graphics.setColor(0.4, 0.9, 0.4)
            love.graphics.print("All buildings owned! You can produce this commodity.", modalX + 20, reqY)
        end

        -- Draw "Build Missing" button if there are missing buildings
        if #self.requirements.missing > 0 then
            local btnX = modalX + CONFIG.modalWidth - 180
            local btnY = summaryY + 70
            local btnW = 160
            local btnH = 30

            self.buildButton = {x = btnX, y = btnY, width = btnW, height = btnH}

            local hoveringBtn = pointInRect(mx, my, btnX, btnY, btnW, btnH)
            love.graphics.setColor(hoveringBtn and CONFIG.colors.buttonHover[1] or CONFIG.colors.button[1],
                                   hoveringBtn and CONFIG.colors.buttonHover[2] or CONFIG.colors.button[2],
                                   hoveringBtn and CONFIG.colors.buttonHover[3] or CONFIG.colors.button[3])
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 5, 5)

            love.graphics.setColor(1, 1, 1)
            local btnText = "Build Missing"
            local btnTextWidth = font:getWidth(btnText)
            love.graphics.print(btnText, btnX + (btnW - btnTextWidth) / 2, btnY + 7)
        else
            self.buildButton = nil
        end
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

return SupplyChainViewer
