--
-- Town - manages all buildings and town state
--

require("code/Inventory")
require("code/River")
require("code/Forest")
require("code/Mine")

Town = {}
Town.__index = Town

function Town:Create()
    local this = {
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

    -- Add comprehensive starting resources to bootstrap economy

    -- Raw building materials
    this.mInventory:Add("stone", 200)  -- Enough for Lumberjack + other buildings
    this.mInventory:Add("wood", 150)   -- Basic construction
    this.mInventory:Add("timber", 100) -- For advanced buildings
    this.mInventory:Add("ore", 100)    -- For smelter
    this.mInventory:Add("clay", 80)    -- For bricks
    this.mInventory:Add("sand", 60)    -- For glass

    -- Processed materials
    this.mInventory:Add("iron", 50)   -- Tools and nails
    this.mInventory:Add("nails", 100) -- Common construction
    this.mInventory:Add("bricks", 80) -- Building material
    this.mInventory:Add("planks", 60) -- Refined wood

    -- Food and farming
    this.mInventory:Add("wheat", 100) -- Starting food
    this.mInventory:Add("bread", 50)  -- Processed food

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
    
    -- Update mine production
    if self.mMines then
        self.mMines:Update(dt)
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

    -- Reset color
    love.graphics.setColor(1, 1, 1)
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
