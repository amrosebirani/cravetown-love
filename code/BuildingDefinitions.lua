--
-- BuildingDefinitions - defines all 23 workplace building types
--

BuildingDefinitions = {
    {
        type = "farm",
        label = "Farm",
        workplaceType = "farm",
        color = {0.4, 0.7, 0.3},
        width = 80,
        height = 80
    },
    {
        type = "bakery",
        label = "Bakery",
        workplaceType = "bakery",
        color = {0.8, 0.6, 0.3},
        width = 70,
        height = 70
    },
    {
        type = "kitchen",
        label = "Kitchen",
        workplaceType = "kitchen",
        color = {0.9, 0.5, 0.2},
        width = 70,
        height = 70
    },
    {
        type = "worksite",
        label = "Worksite",
        workplaceType = "worksite",
        color = {0.5, 0.5, 0.5},
        width = 70,
        height = 70
    },
    {
        type = "station",
        label = "Station",
        workplaceType = "station",
        color = {0.2, 0.3, 0.8},
        width = 70,
        height = 70
    },
    {
        type = "school",
        label = "School",
        workplaceType = "school",
        color = {0.7, 0.3, 0.7},
        width = 80,
        height = 80
    },
    {
        type = "temple",
        label = "Temple",
        workplaceType = "temple",
        color = {0.9, 0.9, 0.7},
        width = 70,
        height = 70
    },
    {
        type = "depot",
        label = "Depot",
        workplaceType = "depot",
        color = {0.3, 0.6, 0.7},
        width = 70,
        height = 70
    },
    {
        type = "hospital",
        label = "Hospital",
        workplaceType = "hospital",
        color = {1.0, 0.3, 0.3},
        width = 80,
        height = 80
    },
    {
        type = "workshop",
        label = "Workshop",
        workplaceType = "workshop",
        color = {0.4, 0.5, 0.6},
        width = 70,
        height = 70
    },
    {
        type = "powerhouse",
        label = "Power",
        workplaceType = "powerhouse",
        color = {1.0, 1.0, 0.3},
        width = 70,
        height = 70
    },
    {
        type = "carpentry",
        label = "Carpentry",
        workplaceType = "carpentry",
        color = {0.6, 0.4, 0.2},
        width = 70,
        height = 70
    },
    {
        type = "studio",
        label = "Studio",
        workplaceType = "studio",
        color = {0.9, 0.4, 0.6},
        width = 70,
        height = 70
    },
    {
        type = "tailorshop",
        label = "Tailor",
        workplaceType = "tailorshop",
        color = {0.7, 0.5, 0.8},
        width = 70,
        height = 70
    },
    {
        type = "smithy",
        label = "Smithy",
        workplaceType = "smithy",
        color = {1.0, 0.8, 0.2},
        width = 70,
        height = 70
    },
    {
        type = "house",
        label = "House",
        workplaceType = "house",
        color = {0.9, 0.7, 0.7},
        width = 70,
        height = 70
    },
    {
        type = "bank",
        label = "Bank",
        workplaceType = "bank",
        color = {0.3, 0.5, 0.3},
        width = 70,
        height = 70
    },
    {
        type = "mine",
        label = "Mine",
        workplaceType = "mine",
        color = {0.3, 0.3, 0.3},
        width = 80,
        height = 80
    },
    {
        type = "forge",
        label = "Forge",
        workplaceType = "forge",
        color = {0.4, 0.4, 0.4},
        width = 70,
        height = 70
    },
    {
        type = "brickyard",
        label = "Brickyard",
        workplaceType = "brickyard",
        color = {0.7, 0.3, 0.2},
        width = 80,
        height = 80
    },
    {
        type = "none",
        label = "None",
        workplaceType = "none",
        color = {1.0, 0.8, 0.6},
        width = 50,
        height = 50
    }
    -- Note: Farm is shared by Cow and Chicken (already defined above)
}

function GetBuildingDefinition(buildingType)
    for _, def in ipairs(BuildingDefinitions) do
        if def.type == buildingType then
            return def
        end
    end
    return nil
end