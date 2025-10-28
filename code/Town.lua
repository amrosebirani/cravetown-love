--
-- Town - manages all buildings and town state
--

require("code/Inventory")

Town = {}
Town.__index = Town

function Town:Create()
    local this = {
        mBuildings = {},
        mInventory = Inventory:Create()
    }

    -- Add comprehensive starting resources to bootstrap economy

    -- Raw building materials
    this.mInventory:Add("stone", 200)      -- Enough for Lumberjack + other buildings
    this.mInventory:Add("wood", 150)       -- Basic construction
    this.mInventory:Add("timber", 100)     -- For advanced buildings
    this.mInventory:Add("ore", 100)        -- For smelter
    this.mInventory:Add("clay", 80)        -- For bricks
    this.mInventory:Add("sand", 60)        -- For glass

    -- Processed materials
    this.mInventory:Add("iron", 50)        -- Tools and nails
    this.mInventory:Add("nails", 100)      -- Common construction
    this.mInventory:Add("bricks", 80)      -- Building material
    this.mInventory:Add("planks", 60)      -- Refined wood

    -- Food and farming
    this.mInventory:Add("wheat", 100)      -- Starting food
    this.mInventory:Add("bread", 50)       -- Processed food

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
    return false
end

function Town:Render()
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

function Town:GetBuildingCount()
    return #self.mBuildings
end

function Town:GetInventory()
    return self.mInventory
end
