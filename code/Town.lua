--
-- Town - manages all buildings and town state
--

require("code/Inventory")
require("code/River")
require("code/Forest")
require("code/Mine")
require("code/Mountain")

Town = {}
Town.__index = Town

function Town:Create(params)
    local this = {
        mName = (params and params.name) or "Cravetown",
        mBuildings = {},
        mInventory = Inventory:Create(),
        -- Town boundaries centered at world origin (0, 0)
        mBoundaryWidth = 2500,
        mBoundaryHeight = 2500,
        mBoundaryMinX = -1250,
        mBoundaryMinY = -1250,
        mBoundaryMaxX = 1250,
        mBoundaryMaxY = 1250
    }

    -- Create a river flowing through the center
    this.mRiver = River:Create({
        startY = -1350,
        endY = 1350,
        centerX = 0,
        baseWidth = 180, -- Increased from 120
        curviness = 120,
        widthVariation = 0.4
    })

    -- Create random forest regions (after river so we can avoid it)
    this.mForest = Forest:Create({
        minX = -1250,
        minY = -1250,
        maxX = 1250,
        maxY = 1250,
        numRegions = math.random(3, 6),
        river = this.mRiver
    })

    -- Create mine sites (after river and forest so we can avoid them)
    this.mMines = Mine:Create({
        minX = -1250,
        minY = -1250,
        maxX = 1250,
        maxY = 1250,
        river = this.mRiver,
        forest = this.mForest
    })

    -- Create mountain ranges at edges (after all other nature elements)
    this.mMountains = Mountain:Create({
        minX = -1250,
        minY = -1250,
        maxX = 1250,
        maxY = 1250,
        river = this.mRiver,
        forest = this.mForest,
        mines = this.mMines,
        inventory = this.mInventory  -- Pass inventory reference
    })

    -- Add comprehensive starting resources - 1000 of each item

    -- GRAINS
    this.mInventory:Add("wheat", 1000)
    this.mInventory:Add("maize", 1000)
    this.mInventory:Add("rice", 1000)
    this.mInventory:Add("barley", 1000)
    this.mInventory:Add("oats", 1000)
    this.mInventory:Add("rye", 1000)

    -- FRUITS (berries added by mountains automatically)
    this.mInventory:Add("apple", 1000)
    this.mInventory:Add("mango", 1000)
    this.mInventory:Add("orange", 1000)
    this.mInventory:Add("grapes", 1000)
    this.mInventory:Add("berries", 1000)
    this.mInventory:Add("peach", 1000)
    this.mInventory:Add("pear", 1000)

    -- VEGETABLES
    this.mInventory:Add("potato", 1000)
    this.mInventory:Add("carrot", 1000)
    this.mInventory:Add("onion", 1000)
    this.mInventory:Add("cabbage", 1000)
    this.mInventory:Add("tomato", 1000)
    this.mInventory:Add("lettuce", 1000)
    this.mInventory:Add("beans", 1000)
    this.mInventory:Add("pumpkin", 1000)

    -- CROPS
    this.mInventory:Add("flowers", 1000)
    this.mInventory:Add("indigo", 1000)
    this.mInventory:Add("sugar_cane", 1000)

    -- ANIMAL PRODUCTS
    this.mInventory:Add("wool", 1000)
    this.mInventory:Add("milk", 1000)
    this.mInventory:Add("eggs", 1000)
    this.mInventory:Add("meat", 1000)
    this.mInventory:Add("leather", 1000)

    -- PROCESSED FOOD
    this.mInventory:Add("cheese", 1000)
    this.mInventory:Add("butter", 1000)
    this.mInventory:Add("bread", 1000)
    this.mInventory:Add("flour", 1000)
    this.mInventory:Add("sugar", 1000)
    this.mInventory:Add("honey", 1000)
    this.mInventory:Add("wine", 1000)
    this.mInventory:Add("beer", 1000)
    this.mInventory:Add("pastries", 1000)
    this.mInventory:Add("preserved_food", 1000)

    -- DYES
    this.mInventory:Add("red_dye", 1000)
    this.mInventory:Add("blue_dye", 1000)
    this.mInventory:Add("yellow_dye", 1000)
    this.mInventory:Add("black_dye", 1000)

    -- TEXTILES
    this.mInventory:Add("paper", 1000)
    this.mInventory:Add("cotton", 1000)
    this.mInventory:Add("flax", 1000)
    this.mInventory:Add("thread", 1000)
    this.mInventory:Add("cloth", 1000)
    this.mInventory:Add("linen", 1000)
    this.mInventory:Add("silk", 1000)

    -- CLOTHING
    this.mInventory:Add("simple_clothes", 1000)
    this.mInventory:Add("work_clothes", 1000)
    this.mInventory:Add("fine_clothes", 1000)
    this.mInventory:Add("luxury_clothes", 1000)
    this.mInventory:Add("winter_coat", 1000)
    this.mInventory:Add("shoes", 1000)
    this.mInventory:Add("boots", 1000)
    this.mInventory:Add("hat", 1000)

    -- TOOLS
    this.mInventory:Add("axe", 1000)
    this.mInventory:Add("hammer", 1000)
    this.mInventory:Add("saw", 1000)
    this.mInventory:Add("pickaxe", 1000)
    this.mInventory:Add("shovel", 1000)
    this.mInventory:Add("hoe", 1000)
    this.mInventory:Add("scythe", 1000)
    this.mInventory:Add("chisel", 1000)
    this.mInventory:Add("needle", 1000)

    -- FURNITURE
    this.mInventory:Add("chair", 1000)
    this.mInventory:Add("table", 1000)
    this.mInventory:Add("bed", 1000)
    this.mInventory:Add("cabinet", 1000)
    this.mInventory:Add("wardrobe", 1000)
    this.mInventory:Add("bench", 1000)
    this.mInventory:Add("bookshelf", 1000)
    this.mInventory:Add("desk", 1000)

    -- RAW MINERALS (added by mines automatically, but adding some extra)
    this.mInventory:Add("coal", 1000)
    this.mInventory:Add("stone", 1000)
    this.mInventory:Add("marble", 1000)
    this.mInventory:Add("clay", 1000)
    this.mInventory:Add("sand", 1000)

    -- REFINED METALS
    this.mInventory:Add("iron", 1000)
    this.mInventory:Add("steel", 1000)
    this.mInventory:Add("copper", 1000)
    this.mInventory:Add("bronze", 1000)
    this.mInventory:Add("gold", 1000)
    this.mInventory:Add("silver", 1000)

    -- BUILDING MATERIALS
    this.mInventory:Add("bricks", 1000)
    this.mInventory:Add("timber", 1000)
    this.mInventory:Add("planks", 1000)
    this.mInventory:Add("cement", 1000)
    this.mInventory:Add("glass", 1000)
    this.mInventory:Add("nails", 1000)
    this.mInventory:Add("wood", 1000)

    -- CRAFTED GOODS
    this.mInventory:Add("pottery", 1000)
    this.mInventory:Add("jewelry", 1000)
    this.mInventory:Add("perfume", 1000)
    this.mInventory:Add("painting", 1000)
    this.mInventory:Add("sculpture", 1000)
    this.mInventory:Add("book", 1000)

    -- UTILITIES
    this.mInventory:Add("candle", 1000)
    this.mInventory:Add("lamp_oil", 1000)
    this.mInventory:Add("soap", 1000)
    this.mInventory:Add("medicine", 1000)
    this.mInventory:Add("charcoal", 1000)
    this.mInventory:Add("oil", 1000)

    setmetatable(this, self)
    return this
end

function Town:AddBuilding(building)
    table.insert(self.mBuildings, building)
    building:SetPlaced(true)
    print("Building added! Total buildings:", #self.mBuildings)
end

function Town:GetBuildings()
    return self.mBuildings
end

function Town:CheckCollision(building)
    -- Check if the building collides with any existing buildings
    for _, existingBuilding in ipairs(self.mBuildings) do
        if building:CheckCollision(existingBuilding) then
            return true
        end
    end

    -- Check if the building collides with the river
    if self.mRiver and self.mRiver:CheckCollision(building) then
        return true
    end

    -- Check if the building collides with forest trees
    if self.mForest and self.mForest:CheckCollision(building) then
        return true
    end

    -- Check if the building collides with mine sites
    if self.mMines and self.mMines:CheckCollision(building) then
        return true
    end

    -- Check if the building collides with mountain ranges
    if self.mMountains and self.mMountains:CheckCollision(building) then
        return true
    end

    return false
end

function Town:IsWithinBoundaries(building)
    -- Check if building is completely within town boundaries
    local x, y, w, h = building:GetBounds()

    return x >= self.mBoundaryMinX and
        y >= self.mBoundaryMinY and
        x + w <= self.mBoundaryMaxX and
        y + h <= self.mBoundaryMaxY
end

function Town:GetBoundaries()
    return self.mBoundaryMinX, self.mBoundaryMinY,
        self.mBoundaryMaxX, self.mBoundaryMaxY
end

function Town:Update(dt)
    -- Update river animation
    if self.mRiver then
        self.mRiver:Update(dt)
    end

    -- Commented out: Using fixed quantities instead of time-based mine production
    -- if self.mMines then
    --     self.mMines:Update(dt)
    -- end

    -- Update all buildings for production
    for _, building in ipairs(self.mBuildings) do
        if building.Update then
            building:Update(dt)
        end
    end
end

function Town:Render()
    -- Draw town boundary background (light green)
    love.graphics.setColor(0.4, 0.6, 0.4, 1)
    love.graphics.rectangle("fill",
        self.mBoundaryMinX, self.mBoundaryMinY,
        self.mBoundaryWidth, self.mBoundaryHeight)

    -- Draw boundary border
    love.graphics.setColor(0.2, 0.3, 0.2, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line",
        self.mBoundaryMinX, self.mBoundaryMinY,
        self.mBoundaryWidth, self.mBoundaryHeight)
    love.graphics.setLineWidth(1)

    -- Draw mountain ranges (in background, at edges)
    if self.mMountains then
        self.mMountains:Render()
    end

    -- Draw mine sites (before forest and river so they're on bottom)
    if self.mMines then
        self.mMines:Render()
    end

    -- Draw the forest (before river so river is on top)
    if self.mForest then
        self.mForest:Render()
    end

    -- Draw the river
    if self.mRiver then
        self.mRiver:Render()
    end

    -- Draw crosshair at world origin (0, 0)
    local size = 30
    local thickness = 2
    love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    love.graphics.setLineWidth(thickness)

    -- Horizontal line
    love.graphics.line(-size, 0, size, 0)
    -- Vertical line
    love.graphics.line(0, -size, 0, size)

    -- Center dot
    love.graphics.circle("fill", 0, 0, 4)

    love.graphics.setLineWidth(1)

    -- Render all placed buildings
    for i, building in ipairs(self.mBuildings) do
        if building and building.Render then
            building:Render(true)
            -- Debug: draw position info
            love.graphics.setColor(0, 0, 0)
            love.graphics.print(i, building.mX, building.mY - 15)
        end
    end

    -- Check for hovered farm/bakery and show production info
    if gCamera and gCamera.toWorldCoords then
        local mx, my = love.mouse.getPosition()
        local worldX, worldY = gCamera:toWorldCoords(mx, my)
        local tooltipShown = false

        -- Check buildings first
        for _, building in ipairs(self.mBuildings) do
            if building:IsMouseOver(worldX, worldY) then
                -- Check for farm/bakery production info
                if (building.mTypeId == "farm" or building.mTypeId == "bakery") then
                    local productionInfo = building:GetProductionInfo()
                    if productionInfo then
                        self:RenderProductionBubble(building, productionInfo)
                        tooltipShown = true
                    end
                -- Check for custom mines
                elseif building.mIsCustomMine then
                    self:RenderCustomMineTooltip(building)
                    tooltipShown = true
                end
                break  -- Only show one tooltip at a time
            end
        end

        -- Check mines if no building tooltip shown
        if not tooltipShown and self.mMines then
            local hoveredMine = self.mMines:GetMineAtPosition(worldX, worldY)
            if hoveredMine then
                self:RenderMineTooltip(hoveredMine)
            end
        end
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function Town:RenderProductionBubble(building, info)
    -- Render production info bubble above the building
    local bubbleX = building.mX + building.mWidth / 2
    local bubbleY = building.mY - 10

    local font = love.graphics.getFont()
    local lines = {}
    for line in info:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    local maxWidth = 0
    for _, line in ipairs(lines) do
        local lineWidth = font:getWidth(line)
        maxWidth = math.max(maxWidth, lineWidth)
    end

    local lineHeight = font:getHeight()
    local bubbleWidth = maxWidth + 20
    local bubbleHeight = (#lines * lineHeight) + 15
    local bubbleTopY = bubbleY - bubbleHeight - 5

    -- Draw bubble background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", bubbleX - bubbleWidth/2, bubbleTopY, bubbleWidth, bubbleHeight, 5, 5)

    -- Draw bubble border
    love.graphics.setColor(0.6, 0.8, 0.6)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", bubbleX - bubbleWidth/2, bubbleTopY, bubbleWidth, bubbleHeight, 5, 5)
    love.graphics.setLineWidth(1)

    -- Draw pointer (triangle pointing down to building)
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.polygon("fill",
        bubbleX, bubbleY,
        bubbleX - 8, bubbleY - 8,
        bubbleX + 8, bubbleY - 8
    )

    -- Draw text
    love.graphics.setColor(1, 1, 1)
    local textY = bubbleTopY + 8
    for _, line in ipairs(lines) do
        local textWidth = font:getWidth(line)
        love.graphics.print(line, bubbleX - textWidth/2, textY)
        textY = textY + lineHeight
    end
end

function Town:RenderMineTooltip(mine)
    -- Render tooltip for mine showing ore name and size
    local bubbleX = mine.x
    local bubbleY = mine.y - mine.size

    local font = love.graphics.getFont()
    local oreName = mine.oreName or "Unknown Ore"
    local sizeText = ""
    if mine.oreSize == "large" then
        sizeText = "Large (10 units)"
    elseif mine.oreSize == "medium" then
        sizeText = "Medium (5 units)"
    elseif mine.oreSize == "small" then
        sizeText = "Small (3 units)"
    end

    local lineHeight = font:getHeight()
    local nameWidth = font:getWidth(oreName)
    local sizeWidth = font:getWidth(sizeText)
    local maxWidth = math.max(nameWidth, sizeWidth)

    local bubbleWidth = maxWidth + 20
    local bubbleHeight = (lineHeight * 2) + 15
    local bubbleTopY = bubbleY - bubbleHeight - 10

    -- Draw bubble background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", bubbleX - bubbleWidth/2, bubbleTopY, bubbleWidth, bubbleHeight, 5, 5)

    -- Draw bubble border using ore color
    love.graphics.setColor(mine.color[1], mine.color[2], mine.color[3])
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", bubbleX - bubbleWidth/2, bubbleTopY, bubbleWidth, bubbleHeight, 5, 5)
    love.graphics.setLineWidth(1)

    -- Draw pointer (triangle pointing down to mine)
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.polygon("fill",
        bubbleX, bubbleY - 5,
        bubbleX - 8, bubbleY - 13,
        bubbleX + 8, bubbleY - 13
    )

    -- Draw text
    love.graphics.setColor(1, 1, 1)
    local textY = bubbleTopY + 8

    -- Ore name
    local textWidth = font:getWidth(oreName)
    love.graphics.print(oreName, bubbleX - textWidth/2, textY)
    textY = textY + lineHeight

    -- Size info
    love.graphics.setColor(0.8, 0.8, 0.8)
    textWidth = font:getWidth(sizeText)
    love.graphics.print(sizeText, bubbleX - textWidth/2, textY)
end

function Town:RenderCustomMineTooltip(building)
    -- Render tooltip for custom mine buildings
    local bubbleX = building.mX + building.mWidth / 2
    local bubbleY = building.mY - 10

    local font = love.graphics.getFont()
    local oreName = building.mMineOreName or "Unknown Ore"
    local sizeText = ""
    if building.mMineOreSize == "large" then
        sizeText = "Large (10 units)"
    elseif building.mMineOreSize == "medium" then
        sizeText = "Medium (5 units)"
    elseif building.mMineOreSize == "small" then
        sizeText = "Small (3 units)"
    end

    local lineHeight = font:getHeight()
    local nameWidth = font:getWidth(oreName)
    local sizeWidth = font:getWidth(sizeText)
    local maxWidth = math.max(nameWidth, sizeWidth)

    local bubbleWidth = maxWidth + 20
    local bubbleHeight = (lineHeight * 2) + 15
    local bubbleTopY = bubbleY - bubbleHeight - 10

    -- Draw bubble background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", bubbleX - bubbleWidth/2, bubbleTopY, bubbleWidth, bubbleHeight, 5, 5)

    -- Draw bubble border using ore color
    love.graphics.setColor(building.mMineOreColor[1], building.mMineOreColor[2], building.mMineOreColor[3])
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", bubbleX - bubbleWidth/2, bubbleTopY, bubbleWidth, bubbleHeight, 5, 5)
    love.graphics.setLineWidth(1)

    -- Draw pointer (triangle pointing down to mine)
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.polygon("fill",
        bubbleX, bubbleY - 5,
        bubbleX - 8, bubbleY - 13,
        bubbleX + 8, bubbleY - 13
    )

    -- Draw text
    love.graphics.setColor(1, 1, 1)
    local textY = bubbleTopY + 8

    -- Ore name
    local textWidth = font:getWidth(oreName)
    love.graphics.print(oreName, bubbleX - textWidth/2, textY)
    textY = textY + lineHeight

    -- Size info
    love.graphics.setColor(0.8, 0.8, 0.8)
    textWidth = font:getWidth(sizeText)
    love.graphics.print(sizeText, bubbleX - textWidth/2, textY)
end

function Town:RenderOutOfBounds()
    -- Render gray areas outside town boundaries
    -- This should be rendered on top of everything to create a "fog" effect
    local camX, camY = gCamera.x, gCamera.y
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local zoom = gCamera.scale or 1

    -- Calculate visible world area
    local worldLeft = camX - screenW / (2 * zoom)
    local worldRight = camX + screenW / (2 * zoom)
    local worldTop = camY - screenH / (2 * zoom)
    local worldBottom = camY + screenH / (2 * zoom)

    love.graphics.setColor(0.2, 0.2, 0.2, 0.7)

    -- Top gray area (above boundary)
    if worldTop < self.mBoundaryMinY then
        love.graphics.rectangle("fill",
            worldLeft, worldTop,
            worldRight - worldLeft, self.mBoundaryMinY - worldTop)
    end

    -- Bottom gray area (below boundary)
    if worldBottom > self.mBoundaryMaxY then
        love.graphics.rectangle("fill",
            worldLeft, self.mBoundaryMaxY,
            worldRight - worldLeft, worldBottom - self.mBoundaryMaxY)
    end

    -- Left gray area (left of boundary)
    if worldLeft < self.mBoundaryMinX then
        love.graphics.rectangle("fill",
            worldLeft, math.max(worldTop, self.mBoundaryMinY),
            self.mBoundaryMinX - worldLeft,
            math.min(worldBottom, self.mBoundaryMaxY) - math.max(worldTop, self.mBoundaryMinY))
    end

    -- Right gray area (right of boundary)
    if worldRight > self.mBoundaryMaxX then
        love.graphics.rectangle("fill",
            self.mBoundaryMaxX, math.max(worldTop, self.mBoundaryMinY),
            worldRight - self.mBoundaryMaxX,
            math.min(worldBottom, self.mBoundaryMaxY) - math.max(worldTop, self.mBoundaryMinY))
    end

    love.graphics.setColor(1, 1, 1)
end

function Town:GetBuildingCount()
    return #self.mBuildings
end

function Town:GetInventory()
    return self.mInventory
end

function Town:GetMines()
    return self.mMines
end

function Town:GetMineAtPosition(x, y)
    if self.mMines then
        return self.mMines:GetMineAtPosition(x, y)
    end
    return nil
end

function Town:GetRiver()
    return self.mRiver
end

function Town:GetForest()
    return self.mForest
end

function Town:GetMountains()
    return self.mMountains
end
