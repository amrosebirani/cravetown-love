--
-- CommodityTypes - defines all resource/commodity types in the game
-- Now loads from external data/commodities.json file for modding support
--

local DataLoader = require("code/DataLoader")

CommodityTypes = {}

local function createCommodity(config)
    return {
        id = config.id,
        name = config.name,
        category = config.category,
        icon = config.icon or "?",
        stackSize = config.stackSize or 1000,
        baseValue = config.baseValue or 1,
        perishable = config.perishable or false,
        description = config.description or "",
        isRaw = config.isRaw or false,  -- Raw resources have no dependencies
        dependencies = config.dependencies or {}  -- Array of commodity IDs this depends on (raw materials)
    }
end

-- Load all commodities from JSON file
local commoditiesData = DataLoader.loadCommodities()
for _, commodityConfig in ipairs(commoditiesData) do
    -- Create uppercase key from ID (e.g., "wheat" -> "WHEAT")
    local key = string.upper(commodityConfig.id)
    CommodityTypes[key] = createCommodity(commodityConfig)
end

-- Helper functions
function CommodityTypes.getAllCommodities()
    local commodities = {}
    for key, value in pairs(CommodityTypes) do
        if type(value) == "table" and value.id then
            table.insert(commodities, value)
        end
    end
    -- Sort by category and name
    table.sort(commodities, function(a, b)
        if a.category == b.category then
            return a.name < b.name
        end
        return a.category < b.category
    end)
    return commodities
end

function CommodityTypes.getById(id)
    for key, value in pairs(CommodityTypes) do
        if type(value) == "table" and value.id == id then
            return value
        end
    end
    return nil
end

function CommodityTypes.getByCategory(category)
    local commodities = {}
    for key, value in pairs(CommodityTypes) do
        if type(value) == "table" and value.id and value.category == category then
            table.insert(commodities, value)
        end
    end
    return commodities
end

return CommodityTypes
