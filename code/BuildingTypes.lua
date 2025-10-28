--
-- BuildingTypes - defines all building types and their properties
--

BuildingTypes = {}

-- Base building configuration
local function createBuildingType(config)
    return {
        id = config.id,
        name = config.name,
        category = config.category,
        label = config.label,
        color = config.color or {0.5, 0.5, 0.5},
        baseWidth = config.baseWidth or 70,
        baseHeight = config.baseHeight or 70,
        variableSize = config.variableSize or false,
        minWidth = config.minWidth,
        minHeight = config.minHeight,
        maxWidth = config.maxWidth,
        maxHeight = config.maxHeight,
        properties = config.properties or {},
        constructionMaterials = config.constructionMaterials or {}  -- {commodityId = amount}
    }
end

-- RESIDENTIAL BUILDINGS
BuildingTypes.LODGE = createBuildingType({
    id = "lodge",
    name = "Lodge",
    category = "residential",
    label = "L",
    color = {0.3, 0.5, 0.7},
    baseWidth = 60,
    baseHeight = 60,
    properties = {
        capacity = 4,
        currentOccupants = 0,
        comfort = 1  -- Basic comfort level
    },
    constructionMaterials = {
        wood = 30,
        stone = 20
    }
})

BuildingTypes.FAMILY_HOME = createBuildingType({
    id = "family_home",
    name = "Family Home",
    category = "residential",
    variableSize = true,
    minWidth = 60,
    minHeight = 60,
    maxWidth = 120,
    maxHeight = 120,
    label = "FH",
    color = {0.2, 0.4, 0.8},
    baseWidth = 80,
    baseHeight = 80,
    properties = {
        capacity = 8,
        currentOccupants = 0,
        comfort = 2
    },
    constructionMaterials = {
        timber = 50,
        bricks = 40,
        nails = 20
    }
})

BuildingTypes.MANOR = createBuildingType({
    id = "manor",
    name = "Manor",
    category = "residential",
    label = "M",
    color = {0.4, 0.3, 0.7},
    baseWidth = 120,
    baseHeight = 120,
    properties = {
        capacity = 16,
        currentOccupants = 0,
        comfort = 3
    },
    constructionMaterials = {
        timber = 100,
        bricks = 80,
        glass = 30,
        nails = 50,
        planks = 60
    }
})

-- MEDICAL
BuildingTypes.HOSPITAL = createBuildingType({
    id = "hospital",
    name = "Hospital",
    category = "medical",
    label = "H+",
    color = {0.9, 0.3, 0.3},
    baseWidth = 100,
    baseHeight = 100,
    properties = {
        availableBeds = 20,
        maxBeds = 20,
        maxDoctors = 5,
        currentDoctors = 0,
        currentPatients = 0
    },
    constructionMaterials = {
        bricks = 80,
        timber = 60,
        glass = 40,
        bed = 20,
        nails = 40
    }
})

-- RESOURCE PRODUCTION
BuildingTypes.MINE = createBuildingType({
    id = "mine",
    name = "Mine",
    category = "production",
    label = "Mi",
    color = {0.4, 0.3, 0.2},
    baseWidth = 90,
    baseHeight = 90,
    properties = {
        maxMiners = 10,
        currentMiners = 0,
        producePerPerson = 5,  -- units per day
        localStorageCapacity = 500,
        currentStorage = 0,
        resourceType = "ore"
    },
    constructionMaterials = {
        timber = 80,
        stone = 60,
        pickaxe = 10
    }
})

BuildingTypes.FARM = createBuildingType({
    id = "farm",
    name = "Farm",
    category = "production",
    label = "Fr",
    color = {0.3, 0.6, 0.2},
    variableSize = true,
    baseWidth = 120,
    baseHeight = 120,
    minWidth = 80,
    minHeight = 80,
    maxWidth = 300,
    maxHeight = 300,
    properties = {
        maxFarmers = 8,
        currentFarmers = 0,
        baseFarmYield = 10,  -- units per area unit
        farmArea = 0,  -- calculated from size
        localStorageCapacity = 1000,
        currentStorage = 0,
        cropType = "wheat"
    },
    constructionMaterials = {
        wood = 50,
        hoe = 8,
        scythe = 5
    }
})

BuildingTypes.ANIMAL_FARM = createBuildingType({
    id = "animal_farm",
    name = "Animal Farm",
    category = "production",
    label = "AF",
    color = {0.5, 0.4, 0.2},
    baseWidth = 100,
    baseHeight = 100,
    properties = {
        maxFarmers = 6,
        currentFarmers = 0,
        maxAnimals = 50,
        currentAnimals = 0,
        producePerAnimal = 2,
        animalType = "cattle"
    },
    constructionMaterials = {
        timber = 70,
        nails = 30,
        wood = 40
    }
})

-- RESOURCE GATHERING & BASIC PRODUCTION
BuildingTypes.LUMBERJACK = createBuildingType({
    id = "lumberjack",
    name = "Logging Camp",
    category = "production",
    label = "LC",
    color = {0.4, 0.5, 0.3},
    baseWidth = 80,
    baseHeight = 80,
    properties = {
        maxWorkers = 6,
        currentWorkers = 0,
        productionRate = 30,  -- timber and wood per day
        storageCapacity = 500,
        currentStorage = 0
    },
    constructionMaterials = {
        stone = 40
    }
})

BuildingTypes.SAWMILL = createBuildingType({
    id = "sawmill",
    name = "Sawmill",
    category = "production",
    label = "SM",
    color = {0.5, 0.4, 0.2},
    baseWidth = 90,
    baseHeight = 90,
    properties = {
        maxWorkers = 4,
        currentWorkers = 0,
        recipes = {"planks"},
        productionRate = 20,
        inputStorage = {timber = 0},
        outputStorage = {planks = 0}
    },
    constructionMaterials = {
        timber = 80,
        iron = 30,
        nails = 40
    }
})

BuildingTypes.SMELTER = createBuildingType({
    id = "smelter",
    name = "Smelter",
    category = "production",
    label = "Sm",
    color = {0.6, 0.3, 0.1},
    baseWidth = 90,
    baseHeight = 90,
    properties = {
        maxWorkers = 5,
        currentWorkers = 0,
        recipes = {"iron", "copper", "gold", "silver", "steel"},
        productionRate = 15,
        inputStorage = {ore = 0, coal = 0},
        outputStorage = {iron = 0}
    },
    constructionMaterials = {
        bricks = 100,
        stone = 80,
        iron = 40
    }
})

BuildingTypes.TEXTILE_MILL = createBuildingType({
    id = "textile_mill",
    name = "Textile Mill",
    category = "production",
    label = "TM",
    color = {0.6, 0.6, 0.5},
    baseWidth = 85,
    baseHeight = 85,
    properties = {
        maxWorkers = 6,
        currentWorkers = 0,
        recipes = {"thread"},
        productionRate = 25,
        inputStorage = {cotton = 0, wool = 0},
        outputStorage = {thread = 0}
    },
    constructionMaterials = {
        timber = 70,
        iron = 30,
        nails = 35
    }
})

BuildingTypes.DYE_WORKS = createBuildingType({
    id = "dye_works",
    name = "Dye Works",
    category = "production",
    label = "DW",
    color = {0.7, 0.4, 0.6},
    baseWidth = 70,
    baseHeight = 70,
    properties = {
        maxWorkers = 3,
        currentWorkers = 0,
        recipes = {"red_dye", "blue_dye", "yellow_dye", "black_dye"},
        productionRate = 15
    },
    constructionMaterials = {
        timber = 50,
        bricks = 40,
        nails = 25
    }
})

BuildingTypes.PAPER_MILL = createBuildingType({
    id = "paper_mill",
    name = "Paper Mill",
    category = "production",
    label = "PM",
    color = {0.7, 0.7, 0.6},
    baseWidth = 80,
    baseHeight = 80,
    properties = {
        maxWorkers = 4,
        currentWorkers = 0,
        recipes = {"paper"},
        productionRate = 20,
        inputStorage = {wood = 0},
        outputStorage = {paper = 0}
    },
    constructionMaterials = {
        timber = 60,
        iron = 25,
        nails = 30
    }
})

BuildingTypes.CHARCOAL_BURNER = createBuildingType({
    id = "charcoal_burner",
    name = "Charcoal Burner",
    category = "production",
    label = "CB",
    color = {0.2, 0.2, 0.2},
    baseWidth = 70,
    baseHeight = 70,
    properties = {
        maxWorkers = 3,
        currentWorkers = 0,
        recipes = {"charcoal"},
        productionRate = 25,
        inputStorage = {wood = 0},
        outputStorage = {charcoal = 0}
    },
    constructionMaterials = {
        stone = 60,
        bricks = 40,
        timber = 30
    }
})

BuildingTypes.GLASSWORKS = createBuildingType({
    id = "glassworks",
    name = "Glassworks",
    category = "production",
    label = "GW",
    color = {0.6, 0.8, 0.9},
    baseWidth = 80,
    baseHeight = 80,
    properties = {
        maxWorkers = 4,
        currentWorkers = 0,
        recipes = {"glass"},
        productionRate = 10,
        inputStorage = {sand = 0},
        outputStorage = {glass = 0}
    },
    constructionMaterials = {
        bricks = 80,
        stone = 60,
        iron = 30
    }
})

BuildingTypes.FORGE = createBuildingType({
    id = "forge",
    name = "Forge",
    category = "production",
    label = "Fg",
    color = {0.5, 0.2, 0.1},
    baseWidth = 75,
    baseHeight = 75,
    properties = {
        maxWorkers = 3,
        currentWorkers = 0,
        recipes = {"nails"},
        productionRate = 50,  -- nails are produced in bulk
        inputStorage = {iron = 0},
        outputStorage = {nails = 0}
    },
    constructionMaterials = {
        bricks = 60,
        stone = 50,
        iron = 30
    }
})

BuildingTypes.CANDLE_MAKER = createBuildingType({
    id = "candle_maker",
    name = "Candle Maker",
    category = "production",
    label = "CM",
    color = {0.9, 0.9, 0.7},
    baseWidth = 60,
    baseHeight = 60,
    properties = {
        maxWorkers = 2,
        currentWorkers = 0,
        recipes = {"candle"},
        productionRate = 15,
        inputStorage = {honey = 0},
        outputStorage = {candle = 0}
    },
    constructionMaterials = {
        timber = 40,
        bricks = 30,
        nails = 20
    }
})

-- FOOD PROCESSING
BuildingTypes.BAKERY = createBuildingType({
    id = "bakery",
    name = "Bakery",
    category = "food_processing",
    label = "Bk",
    color = {0.8, 0.6, 0.3},
    baseWidth = 70,
    baseHeight = 70,
    properties = {
        maxBakers = 3,
        currentBakers = 0,
        recipes = {"bread", "pastries"},
        productionRate = 20,  -- items per day
        inputStorage = {wheat = 0},
        outputStorage = {bread = 0}
    },
    constructionMaterials = {
        bricks = 50,
        timber = 30,
        stone = 40
    }
})

BuildingTypes.COMMUNITY_KITCHEN = createBuildingType({
    id = "community_kitchen",
    name = "Community Kitchen",
    category = "food_processing",
    label = "CK",
    color = {0.7, 0.5, 0.2},
    baseWidth = 90,
    baseHeight = 90,
    properties = {
        maxCooks = 5,
        currentCooks = 0,
        recipes = {"stew", "soup", "roast"},
        mealsPerDay = 100,
        inputStorage = {},
        servingCapacity = 50
    },
    constructionMaterials = {
        bricks = 60,
        timber = 40,
        table = 5,
        bench = 10
    }
})

-- SERVICES
BuildingTypes.POLICE_STATION = createBuildingType({
    id = "police_station",
    name = "Police Station",
    category = "service",
    label = "PS",
    color = {0.2, 0.2, 0.6},
    baseWidth = 80,
    baseHeight = 80,
    properties = {
        maxOfficers = 10,
        currentOfficers = 0,
        coverageRadius = 200,
        safetyBonus = 0.5
    },
    constructionMaterials = {
        bricks = 70,
        timber = 50,
        iron = 20,
        nails = 30
    }
})

BuildingTypes.SCHOOL = createBuildingType({
    id = "school",
    name = "School",
    category = "education",
    label = "Sc",
    color = {0.3, 0.5, 0.5},
    baseWidth = 100,
    baseHeight = 100,
    properties = {
        maxTeachers = 5,
        currentTeachers = 0,
        maxStudents = 100,
        currentStudents = 0,
        educationLevel = 1
    },
    constructionMaterials = {
        bricks = 80,
        timber = 60,
        desk = 30,
        bench = 30,
        book = 50
    }
})

BuildingTypes.UNIVERSITY = createBuildingType({
    id = "university",
    name = "University",
    category = "education",
    label = "Un",
    color = {0.2, 0.4, 0.6},
    baseWidth = 150,
    baseHeight = 150,
    properties = {
        maxProfessors = 10,
        currentProfessors = 0,
        maxStudents = 200,
        currentStudents = 0,
        educationLevel = 3
    },
    constructionMaterials = {
        bricks = 150,
        timber = 100,
        glass = 60,
        desk = 50,
        bench = 50,
        book = 200,
        nails = 80
    }
})

BuildingTypes.TEMPLE = createBuildingType({
    id = "temple",
    name = "Temple",
    category = "spiritual",
    label = "Tm",
    color = {0.7, 0.6, 0.3},
    baseWidth = 90,
    baseHeight = 90,
    properties = {
        maxPriests = 3,
        currentPriests = 0,
        capacity = 100,
        spiritualBonus = 0.3
    },
    constructionMaterials = {
        marble = 60,
        timber = 50,
        glass = 30,
        nails = 40
    }
})

BuildingTypes.POWERHOUSE = createBuildingType({
    id = "powerhouse",
    name = "PowerHouse",
    category = "infrastructure",
    label = "PH",
    color = {0.8, 0.7, 0.2},
    baseWidth = 110,
    baseHeight = 110,
    properties = {
        maxWorkers = 8,
        currentWorkers = 0,
        powerOutput = 1000,
        fuelConsumption = 50,
        currentFuel = 0
    },
    constructionMaterials = {
        bricks = 120,
        iron = 80,
        copper = 40,
        steel = 60,
        nails = 70
    }
})

-- CRAFTING
BuildingTypes.CARPENTRY = createBuildingType({
    id = "carpentry",
    name = "Carpentry",
    category = "crafting",
    label = "Cp",
    color = {0.5, 0.3, 0.1},
    baseWidth = 70,
    baseHeight = 70,
    properties = {
        maxCarpenters = 4,
        currentCarpenters = 0,
        recipes = {"furniture", "tools"},
        productionRate = 10
    },
    constructionMaterials = {
        timber = 60,
        nails = 30,
        saw = 4,
        hammer = 4
    }
})

BuildingTypes.WEAVER = createBuildingType({
    id = "weaver",
    name = "Weaver",
    category = "crafting",
    label = "Wv",
    color = {0.6, 0.5, 0.4},
    baseWidth = 70,
    baseHeight = 70,
    properties = {
        maxWeavers = 3,
        currentWeavers = 0,
        recipes = {"cloth", "fabric"},
        productionRate = 15
    },
    constructionMaterials = {
        timber = 50,
        wood = 30,
        nails = 25
    }
})

BuildingTypes.TAILOR_SHOP = createBuildingType({
    id = "tailor_shop",
    name = "Tailor Shop",
    category = "crafting",
    label = "TS",
    color = {0.5, 0.4, 0.5},
    baseWidth = 60,
    baseHeight = 60,
    properties = {
        maxTailors = 2,
        currentTailors = 0,
        recipes = {"clothes", "garments"},
        productionRate = 8
    },
    constructionMaterials = {
        timber = 40,
        nails = 20,
        needle = 10,
        table = 2
    }
})

BuildingTypes.BLACKSMITH = createBuildingType({
    id = "blacksmith",
    name = "Blacksmith",
    category = "crafting",
    label = "BS",
    color = {0.3, 0.3, 0.3},
    baseWidth = 80,
    baseHeight = 80,
    properties = {
        maxBlacksmiths = 3,
        currentBlacksmiths = 0,
        recipes = {"tools", "weapons", "metal_goods"},
        productionRate = 5
    },
    constructionMaterials = {
        bricks = 70,
        stone = 50,
        iron = 40,
        hammer = 3
    }
})

BuildingTypes.BRICK_MAKER = createBuildingType({
    id = "brick_maker",
    name = "Brick Maker",
    category = "crafting",
    label = "BM",
    color = {0.6, 0.3, 0.2},
    baseWidth = 80,
    baseHeight = 80,
    properties = {
        maxWorkers = 4,
        currentWorkers = 0,
        productionRate = 100,  -- bricks per day
        currentStorage = 0,
        storageCapacity = 5000
    },
    constructionMaterials = {
        timber = 50,
        stone = 60,
        wood = 40
    }
})

BuildingTypes.MASONRY = createBuildingType({
    id = "masonry",
    name = "Masonry",
    category = "crafting",
    label = "Ms",
    color = {0.5, 0.5, 0.5},
    baseWidth = 80,
    baseHeight = 80,
    properties = {
        maxMasons = 5,
        currentMasons = 0,
        recipes = {"stone_blocks", "sculptures"},
        productionRate = 8
    },
    constructionMaterials = {
        stone = 80,
        timber = 40,
        chisel = 5,
        hammer = 5
    }
})

-- MARKETPLACE
BuildingTypes.MARKET = createBuildingType({
    id = "market",
    name = "Open Market",
    category = "commerce",
    label = "Mk",
    color = {0.7, 0.7, 0.2},
    variableSize = true,
    baseWidth = 150,
    baseHeight = 150,
    minWidth = 100,
    minHeight = 100,
    maxWidth = 400,
    maxHeight = 400,
    properties = {
        shopSlots = 10,
        occupiedSlots = 0,
        rentPerSlot = 50,
        autoAssign = true,
        shops = {}  -- array of shop data
    },
    constructionMaterials = {
        timber = 100,
        wood = 80,
        nails = 60
    }
})

-- Helper function to get all building types as a list
function BuildingTypes.getAllTypes()
    local types = {}
    for key, value in pairs(BuildingTypes) do
        if type(value) == "table" and value.id then
            table.insert(types, value)
        end
    end
    return types
end

-- Helper function to get building type by id
function BuildingTypes.getById(id)
    for key, value in pairs(BuildingTypes) do
        if type(value) == "table" and value.id == id then
            return value
        end
    end
    return nil
end

-- Helper function to get building types by category
function BuildingTypes.getByCategory(category)
    local types = {}
    for key, value in pairs(BuildingTypes) do
        if type(value) == "table" and value.id and value.category == category then
            table.insert(types, value)
        end
    end
    return types
end

return BuildingTypes
