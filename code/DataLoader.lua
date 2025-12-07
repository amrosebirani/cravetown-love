--
-- DataLoader - loads game data from external JSON files
--

local json = require("code/json")

DataLoader = {}
DataLoader.activeVersion = "base"  -- Default version

function DataLoader.setActiveVersion(versionId)
    DataLoader.activeVersion = versionId
    print("DataLoader: Active version set to '" .. versionId .. "'")
end

function DataLoader.getActiveVersion()
    return DataLoader.activeVersion
end

function DataLoader.loadJSON(filepath)
    local contents, size = love.filesystem.read(filepath)
    if not contents then
        error("Failed to load file: " .. filepath)
    end

    local data = json.decode(contents)
    return data
end

function DataLoader.loadVersionsManifest()
    print("Loading versions manifest from data/versions.json...")
    local data = DataLoader.loadJSON("data/versions.json")
    return data
end

function DataLoader.loadCommodities()
    local filepath = "data/" .. DataLoader.activeVersion .. "/commodities.json"
    print("Loading commodities from " .. filepath .. "...")
    local data = DataLoader.loadJSON(filepath)
    return data.commodities or {}
end

function DataLoader.loadCommodityCategories()
    local filepath = "data/" .. DataLoader.activeVersion .. "/commodity_categories.json"
    print("Loading commodity categories from " .. filepath .. "...")
    local success, data = pcall(function()
        return DataLoader.loadJSON(filepath)
    end)
    if success and data then
        return data.categories or {}
    else
        print("  WARNING: Could not load commodity categories, returning empty")
        return {}
    end
end

function DataLoader.loadBuildings()
    local filepath = "data/" .. DataLoader.activeVersion .. "/buildings.json"
    print("Loading buildings from " .. filepath .. "...")
    local data = DataLoader.loadJSON(filepath)
    return data.buildings or {}
end

function DataLoader.loadWorkerTypes()
    local filepath = "data/" .. DataLoader.activeVersion .. "/worker_types.json"
    print("Loading worker types from " .. filepath .. "...")
    local data = DataLoader.loadJSON(filepath)
    if data then
        print("  JSON loaded successfully, workerTypes count: " .. (data.workerTypes and #data.workerTypes or "nil"))
    else
        print("  WARNING: data is nil after JSON load")
    end
    return data.workerTypes or {}
end

function DataLoader.loadBuildingRecipes()
    local filepath = "data/" .. DataLoader.activeVersion .. "/building_recipes.json"
    print("Loading building recipes from " .. filepath .. "...")
    local data = DataLoader.loadJSON(filepath)
    return data.recipes or {}
end

function DataLoader.loadBuildingTypes()
    local filepath = "data/" .. DataLoader.activeVersion .. "/building_types.json"
    print("Loading building types from " .. filepath .. "...")
    local data = DataLoader.loadJSON(filepath)
    return data.buildingTypes or {}
end

function DataLoader.loadNaturalResources()
    local filepath = "data/" .. DataLoader.activeVersion .. "/natural_resources.json"
    print("Loading natural resources from " .. filepath .. "...")
    local success, data = pcall(function()
        return DataLoader.loadJSON(filepath)
    end)
    if success and data then
        return data
    else
        print("  WARNING: Could not load natural resources, returning empty data")
        return { naturalResources = {} }
    end
end

-- =============================================================================
-- CRAVING SYSTEM DATA
-- =============================================================================

function DataLoader.loadCharacterClasses()
    local filepath = "data/" .. DataLoader.activeVersion .. "/craving_system/character_classes.json"
    print("Loading character classes from " .. filepath .. "...")
    local data = DataLoader.loadJSON(filepath)
    return data
end

function DataLoader.loadDimensionDefinitions()
    local filepath = "data/" .. DataLoader.activeVersion .. "/craving_system/dimension_definitions.json"
    print("Loading dimension definitions from " .. filepath .. "...")
    local data = DataLoader.loadJSON(filepath)
    return data
end

function DataLoader.loadCharacterTraits()
    local filepath = "data/" .. DataLoader.activeVersion .. "/craving_system/character_traits.json"
    print("Loading character traits from " .. filepath .. "...")
    local data = DataLoader.loadJSON(filepath)
    return data
end

function DataLoader.loadCommodityFatigueRates()
    local filepath = "data/" .. DataLoader.activeVersion .. "/craving_system/commodity_fatigue_rates.json"
    print("Loading commodity fatigue rates from " .. filepath .. "...")
    local data = DataLoader.loadJSON(filepath)
    return data
end

function DataLoader.loadEnablementRules()
    local filepath = "data/" .. DataLoader.activeVersion .. "/craving_system/enablement_rules.json"
    print("Loading enablement rules from " .. filepath .. "...")
    local data = DataLoader.loadJSON(filepath)
    return data
end

function DataLoader.loadFulfillmentVectors()
    local filepath = "data/" .. DataLoader.activeVersion .. "/craving_system/fulfillment_vectors.json"
    print("Loading fulfillment vectors from " .. filepath .. "...")
    local data = DataLoader.loadJSON(filepath)
    return data
end

function DataLoader.loadConsumptionMechanics()
    local filepath = "data/" .. DataLoader.activeVersion .. "/consumption_mechanics.json"
    print("Loading consumption mechanics from " .. filepath .. "...")
    local data = DataLoader.loadJSON(filepath)
    return data
end

function DataLoader.loadSubstitutionRules()
    local filepath = "data/" .. DataLoader.activeVersion .. "/substitution_rules.json"
    print("Loading substitution rules from " .. filepath .. "...")
    local data = DataLoader.loadJSON(filepath)
    return data
end

function DataLoader.loadTimeSlots()
    local filepath = "data/" .. DataLoader.activeVersion .. "/time_slots.json"
    print("Loading time slots from " .. filepath .. "...")
    local success, data = pcall(function()
        return DataLoader.loadJSON(filepath)
    end)
    if success and data then
        return data.slots or {}
    else
        print("  WARNING: Could not load time slots, returning defaults")
        return nil
    end
end

function DataLoader.loadCravingSlots()
    local filepath = "data/" .. DataLoader.activeVersion .. "/craving_slots.json"
    print("Loading craving slots from " .. filepath .. "...")
    local success, data = pcall(function()
        return DataLoader.loadJSON(filepath)
    end)
    if success and data then
        return data
    else
        print("  WARNING: Could not load craving slots, returning empty")
        return { mappings = {}, classModifiers = {}, traitModifiers = {} }
    end
end

-- =============================================================================
-- HELPER FUNCTIONS FOR CLASS DATA
-- =============================================================================

-- Get list of class IDs from character_classes.json
function DataLoader.getClassIds()
    local classes = DataLoader.loadCharacterClasses()
    if classes and classes.classes then
        local ids = {}
        for _, class in ipairs(classes.classes) do
            table.insert(ids, class.id)
        end
        return ids
    end
    return {"elite", "upper", "middle", "lower"}
end

-- Get list of class names from character_classes.json
function DataLoader.getClassNames()
    local classes = DataLoader.loadCharacterClasses()
    if classes and classes.classes then
        local names = {}
        for _, class in ipairs(classes.classes) do
            table.insert(names, class.name)
        end
        return names
    end
    return {"Elite", "Upper Class", "Middle Class", "Lower Class"}
end

-- Get class data by ID
function DataLoader.getClassById(classId)
    local classes = DataLoader.loadCharacterClasses()
    if classes and classes.classes then
        for _, class in ipairs(classes.classes) do
            if class.id == classId or class.name == classId then
                return class
            end
        end
    end
    return nil
end

-- Get default class distribution for spawning
function DataLoader.getDefaultClassDistribution()
    local classes = DataLoader.loadCharacterClasses()
    if classes and classes.classes then
        local distribution = {}
        local count = #classes.classes
        -- Default: higher classes are rarer
        -- elite: 5%, upper: 15%, middle: 50%, lower: 30%
        local defaultWeights = {0.05, 0.15, 0.50, 0.30}
        for i, class in ipairs(classes.classes) do
            distribution[class.id] = defaultWeights[i] or (1 / count)
        end
        return distribution
    end
    return {elite = 0.05, upper = 0.15, middle = 0.50, lower = 0.30}
end

-- Get default class ID
function DataLoader.getDefaultClassId()
    local classes = DataLoader.loadCharacterClasses()
    if classes and classes.classes and #classes.classes >= 3 then
        return classes.classes[3].id  -- middle class (index 3)
    end
    return "middle"
end

-- Get dimension count
function DataLoader.getCoarseDimensionCount()
    local dims = DataLoader.loadDimensionDefinitions()
    if dims and dims.dimensionCount then
        return dims.dimensionCount.coarse or 9
    end
    return 9
end

function DataLoader.getFineDimensionCount()
    local dims = DataLoader.loadDimensionDefinitions()
    if dims and dims.dimensionCount then
        return dims.dimensionCount.fine or 50
    end
    return 50
end

-- =============================================================================
-- IMMIGRATION SYSTEM DATA
-- =============================================================================

function DataLoader.loadImmigrationConfig()
    local filepath = "data/" .. DataLoader.activeVersion .. "/immigration_config.json"
    print("Loading immigration config from " .. filepath .. "...")
    local success, data = pcall(function()
        return DataLoader.loadJSON(filepath)
    end)
    if success and data then
        return data
    else
        print("  WARNING: Could not load immigration config, returning nil")
        return nil
    end
end

function DataLoader.loadNames()
    local filepath = "data/" .. DataLoader.activeVersion .. "/names.json"
    print("Loading names from " .. filepath .. "...")
    local success, data = pcall(function()
        return DataLoader.loadJSON(filepath)
    end)
    if success and data then
        return data
    else
        print("  WARNING: Could not load names, returning nil")
        return nil
    end
end

function DataLoader.loadOrigins()
    local filepath = "data/" .. DataLoader.activeVersion .. "/origins.json"
    print("Loading origins from " .. filepath .. "...")
    local success, data = pcall(function()
        return DataLoader.loadJSON(filepath)
    end)
    if success and data then
        return data
    else
        print("  WARNING: Could not load origins, returning nil")
        return nil
    end
end

-- =============================================================================
-- ALPHA STARTER CONFIG
-- =============================================================================

function DataLoader.loadAlphaStarterConfig()
    local filepath = "data/" .. DataLoader.activeVersion .. "/alpha_starter_config.json"
    print("Loading alpha starter config from " .. filepath .. "...")
    local success, data = pcall(function()
        return DataLoader.loadJSON(filepath)
    end)
    if success and data then
        return data
    else
        print("  WARNING: Could not load alpha starter config, returning defaults")
        return nil
    end
end

return DataLoader
