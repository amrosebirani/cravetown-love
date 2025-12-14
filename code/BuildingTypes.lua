--
-- BuildingTypes - loads building types from JSON data files
--

require("code/DataLoader")

BuildingTypes = {}

-- Convert JSON building type to game format
local function convertBuildingType(jsonData)
    -- Get base level (level 0) for initial size and materials
    local baseLevel = nil
    local maxLevel = nil
    if jsonData.upgradeLevels and #jsonData.upgradeLevels > 0 then
        baseLevel = jsonData.upgradeLevels[1]
        maxLevel = jsonData.upgradeLevels[#jsonData.upgradeLevels]
    end

    -- Determine if variable size based on upgrade levels
    local variableSize = jsonData.upgradeLevels and #jsonData.upgradeLevels > 1
    local baseWidth = baseLevel and baseLevel.width or 70
    local baseHeight = baseLevel and baseLevel.height or 70
    local maxWidth = maxLevel and maxLevel.width or baseWidth
    local maxHeight = maxLevel and maxLevel.height or baseHeight

    -- Build construction materials from base level
    local constructionMaterials = {}
    if baseLevel and baseLevel.constructionMaterials then
        for k, v in pairs(baseLevel.constructionMaterials) do
            constructionMaterials[k] = v
        end
    end

    -- Build properties from various JSON fields
    local properties = {}
    if baseLevel then
        properties.stations = baseLevel.stations
        if baseLevel.storage then
            properties.inputCapacity = baseLevel.storage.inputCapacity
            properties.outputCapacity = baseLevel.storage.outputCapacity
        end
    end

    -- Copy work categories and efficiency
    if jsonData.workCategories then
        properties.workCategories = jsonData.workCategories
    end
    if jsonData.workerEfficiency then
        properties.workerEfficiency = jsonData.workerEfficiency
    end

    return {
        id = jsonData.id,
        name = jsonData.name,
        category = jsonData.category,
        label = jsonData.label,
        description = jsonData.description,
        color = jsonData.color or {0.5, 0.5, 0.5},
        baseWidth = baseWidth,
        baseHeight = baseHeight,
        variableSize = variableSize,
        minWidth = baseWidth,
        minHeight = baseHeight,
        maxWidth = maxWidth,
        maxHeight = maxHeight,
        properties = properties,
        constructionMaterials = constructionMaterials,
        placementConstraints = jsonData.placementConstraints,
        upgradeLevels = jsonData.upgradeLevels,
        workCategories = jsonData.workCategories,
        workerEfficiency = jsonData.workerEfficiency
    }
end

-- Load building types from JSON
function BuildingTypes.loadFromJSON()
    local success, data = pcall(function()
        return DataLoader.loadBuildingTypes()
    end)

    if success and data then
        print("[BuildingTypes] Loading " .. #data .. " building types from JSON...")
        for _, jsonBuildingType in ipairs(data) do
            local buildingType = convertBuildingType(jsonBuildingType)
            -- Store by uppercase ID for backwards compatibility
            local key = string.upper(jsonBuildingType.id)
            BuildingTypes[key] = buildingType
            print("  Loaded: " .. buildingType.id .. " (" .. buildingType.name .. ")")
        end
        print("[BuildingTypes] Loaded " .. #data .. " building types")
        return true
    else
        print("[BuildingTypes] WARNING: Failed to load from JSON, using fallback")
        return false
    end
end

-- Fallback hardcoded building types (minimal set for compatibility)
local function loadFallbackTypes()
    print("[BuildingTypes] Loading fallback building types...")

    BuildingTypes.FARM = {
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
        properties = { stations = 2 },
        constructionMaterials = { wood = 50 },
        placementConstraints = {
            enabled = true,
            requiredResources = {
                { resourceId = "fertility", weight = 0.7, minValue = 0.1, displayName = "Soil Fertility" },
                { resourceId = "ground_water", weight = 0.3, minValue = 0.05, displayName = "Ground Water" }
            },
            efficiencyFormula = "weighted_average",
            warningThreshold = 0.4,
            blockingThreshold = 0.15
        }
    }

    BuildingTypes.MINE = {
        id = "mine",
        name = "Mine",
        category = "production",
        label = "Mi",
        color = {0.4, 0.3, 0.2},
        baseWidth = 90,
        baseHeight = 90,
        properties = { stations = 2 },
        constructionMaterials = { timber = 80, stone = 60 },
        placementConstraints = {
            enabled = true,
            requiredResources = {
                { resourceId = "ore_any", weight = 1.0, minValue = 0.1, displayName = "Ore Deposit",
                  anyOf = {"iron_ore", "copper_ore", "coal", "gold_ore", "silver_ore", "stone"} }
            },
            efficiencyFormula = "direct",
            warningThreshold = 0.3,
            blockingThreshold = 0.1
        }
    }

    BuildingTypes.LODGE = {
        id = "lodge",
        name = "Lodge",
        category = "residential",
        label = "L",
        color = {0.3, 0.5, 0.7},
        baseWidth = 60,
        baseHeight = 60,
        properties = { capacity = 4 },
        constructionMaterials = { wood = 30, stone = 20 }
    }
end

-- Initialize - try to load from JSON, fall back to hardcoded
function BuildingTypes.initialize()
    if not BuildingTypes.loadFromJSON() then
        loadFallbackTypes()
    end
end

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

-- Auto-initialize when loaded
BuildingTypes.initialize()

return BuildingTypes
