--
-- DataLoader - loads game data from external JSON files
--

local json = require("code/json")

DataLoader = {}

function DataLoader.loadJSON(filepath)
    local contents, size = love.filesystem.read(filepath)
    if not contents then
        error("Failed to load file: " .. filepath)
    end

    local data = json.decode(contents)
    return data
end

function DataLoader.loadCommodities()
    print("Loading commodities from data/commodities.json...")
    local data = DataLoader.loadJSON("data/commodities.json")
    return data.commodities or {}
end

function DataLoader.loadBuildings()
    print("Loading buildings from data/buildings.json...")
    local data = DataLoader.loadJSON("data/buildings.json")
    return data.buildings or {}
end

return DataLoader
