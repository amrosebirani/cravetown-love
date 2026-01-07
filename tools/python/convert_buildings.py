#!/usr/bin/env python3
"""
Convert building_types.json to new station-based schema with upgrade levels.
"""

import json

def convert_building_type(building):
    """Convert a single building type to the new schema."""

    # Extract base properties we want to keep
    new_building = {
        "id": building["id"],
        "name": building["name"],
        "category": building["category"],
        "label": building["label"],
        "color": building["color"],
        "description": building.get("description", ""),
        "workCategories": building.get("workCategories", []),
        "workerEfficiency": building.get("workerEfficiency", {})
    }

    # Get sizing info
    base_width = building.get("baseWidth", 80)
    base_height = building.get("baseHeight", 80)

    # Get storage info
    storage = building.get("storage", {})
    input_cap = storage.get("inputCapacity", 300)
    output_cap = storage.get("outputCapacity", 300)

    # Get construction materials
    materials = building.get("constructionMaterials", {})

    # Determine max workers from properties
    props = building.get("properties", {})
    max_workers = props.get("maxWorkers", props.get("maxFarmers", props.get("maxBakers", 4)))

    # Create 3 upgrade levels with increasing stations
    # Level 0: Start with 2 stations (or 1 for very small buildings)
    # Level 1: Double the stations
    # Level 2: Further increase

    base_stations = max(2, max_workers // 4) if max_workers >= 4 else 1

    upgrade_levels = [
        {
            "level": 0,
            "name": f"Basic {building['name']}",
            "description": f"A basic {building['name'].lower()} with {base_stations} work station{'s' if base_stations > 1 else ''}",
            "stations": base_stations,
            "width": int(base_width * 0.7),
            "height": int(base_height * 0.7),
            "constructionMaterials": materials,
            "storage": {
                "inputCapacity": int(input_cap * 0.6),
                "outputCapacity": int(output_cap * 0.6)
            }
        },
        {
            "level": 1,
            "name": f"Improved {building['name']}",
            "description": f"An improved {building['name'].lower()} with {base_stations * 2} work stations",
            "stations": base_stations * 2,
            "width": base_width,
            "height": base_height,
            "upgradeMaterials": {k: int(v * 0.5) for k, v in materials.items()},
            "storage": {
                "inputCapacity": input_cap,
                "outputCapacity": output_cap
            }
        },
        {
            "level": 2,
            "name": f"Advanced {building['name']}",
            "description": f"An advanced {building['name'].lower()} with {base_stations * 4} work stations and modern equipment",
            "stations": base_stations * 4,
            "width": int(base_width * 1.5),
            "height": int(base_height * 1.5),
            "upgradeMaterials": {k: int(v * 0.8) for k, v in materials.items()},
            "storage": {
                "inputCapacity": int(input_cap * 1.6),
                "outputCapacity": int(output_cap * 2)
            }
        }
    ]

    new_building["upgradeLevels"] = upgrade_levels

    return new_building


def main():
    # Read the original file
    with open('data/building_types.json', 'r') as f:
        data = json.load(f)

    # Skip farm (already converted manually)
    converted_buildings = []
    for building in data['buildingTypes']:
        if building['id'] == 'farm':
            # Keep the manually converted farm
            converted_buildings.append(building)
        else:
            # Convert all others
            converted_buildings.append(convert_building_type(building))

    # Write the new file
    data['buildingTypes'] = converted_buildings

    with open('data/building_types.json', 'w') as f:
        json.dump(data, f, indent=2)

    print(f"Converted {len(converted_buildings)} building types")
    print("Successfully updated data/building_types.json")


if __name__ == "__main__":
    main()
