--
-- CommodityDefinitions - defines all resource/commodity types in the game
--

CommodityDefinitions = {
    -- Agricultural Products
    wheat = {
        id = "wheat",
        name = "Wheat",
        category = "agricultural",
        icon = "W",
        color = {0.9, 0.8, 0.4} -- Golden
    },
    maize = {
        id = "maize",
        name = "Maize",
        category = "agricultural",
        icon = "M",
        color = {0.9, 0.7, 0.3} -- Yellow
    },
    sugarcane = {
        id = "sugarcane",
        name = "Sugarcane",
        category = "agricultural",
        icon = "S",
        color = {0.6, 0.8, 0.4} -- Light green
    },
    cotton = {
        id = "cotton",
        name = "Cotton",
        category = "agricultural",
        icon = "C",
        color = {0.9, 0.9, 0.9} -- White
    },

    -- Food Products
    bread = {
        id = "bread",
        name = "Bread",
        category = "food",
        icon = "B",
        color = {0.7, 0.5, 0.3} -- Brown
    },
    flour = {
        id = "flour",
        name = "Flour",
        category = "food",
        icon = "F",
        color = {0.95, 0.95, 0.9} -- Off-white
    },

    -- Animal Products
    milk = {
        id = "milk",
        name = "Milk",
        category = "animal",
        icon = "Mk",
        color = {0.95, 0.95, 0.95} -- White
    },
    eggs = {
        id = "eggs",
        name = "Eggs",
        category = "animal",
        icon = "E",
        color = {0.9, 0.85, 0.7} -- Light brown
    },
    wool = {
        id = "wool",
        name = "Wool",
        category = "animal",
        icon = "Wl",
        color = {0.9, 0.9, 0.85} -- Cream
    },

    -- Mining/Minerals
    coal = {
        id = "coal",
        name = "Coal",
        category = "mineral",
        icon = "Co",
        color = {0.2, 0.2, 0.2} -- Black
    },
    iron = {
        id = "iron",
        name = "Iron",
        category = "mineral",
        icon = "Fe",
        color = {0.5, 0.5, 0.5} -- Gray
    },
    stone = {
        id = "stone",
        name = "Stone",
        category = "mineral",
        icon = "St",
        color = {0.6, 0.6, 0.6} -- Light gray
    },
    clay = {
        id = "clay",
        name = "Clay",
        category = "mineral",
        icon = "Cl",
        color = {0.6, 0.4, 0.3} -- Brown-red
    },

    -- Manufactured Goods
    bricks = {
        id = "bricks",
        name = "Bricks",
        category = "construction",
        icon = "Br",
        color = {0.7, 0.3, 0.2} -- Red brick
    },
    thread = {
        id = "thread",
        name = "Thread",
        category = "textile",
        icon = "Th",
        color = {0.8, 0.8, 0.8} -- Light gray
    },
    linen = {
        id = "linen",
        name = "Linen",
        category = "textile",
        icon = "L",
        color = {0.9, 0.9, 0.8} -- Off-white
    },
    tools = {
        id = "tools",
        name = "Tools",
        category = "manufactured",
        icon = "T",
        color = {0.4, 0.4, 0.4} -- Dark gray
    },
    furniture = {
        id = "furniture",
        name = "Furniture",
        category = "manufactured",
        icon = "Fr",
        color = {0.6, 0.4, 0.2} -- Wood brown
    },
    clothes = {
        id = "clothes",
        name = "Clothes",
        category = "manufactured",
        icon = "Ct",
        color = {0.5, 0.6, 0.8} -- Blue
    },

    -- Misc
    wood = {
        id = "wood",
        name = "Wood",
        category = "raw_material",
        icon = "Wd",
        color = {0.5, 0.3, 0.1} -- Dark brown
    },
    planks = {
        id = "planks",
        name = "Planks",
        category = "construction",
        icon = "Pl",
        color = {0.7, 0.5, 0.3} -- Light brown
    }
}

-- Get list of all commodity IDs
function GetAllCommodityIds()
    local ids = {}
    for id, _ in pairs(CommodityDefinitions) do
        table.insert(ids, id)
    end
    table.sort(ids)
    return ids
end

-- Get commodity definition by ID
function GetCommodityDefinition(commodityId)
    return CommodityDefinitions[commodityId]
end

-- Get commodities by category
function GetCommoditiesByCategory(category)
    local result = {}
    for id, def in pairs(CommodityDefinitions) do
        if def.category == category then
            table.insert(result, def)
        end
    end
    return result
end
