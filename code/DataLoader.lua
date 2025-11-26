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

return DataLoader
