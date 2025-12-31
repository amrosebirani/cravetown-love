#!/usr/bin/env python3
"""
Remove worker requirements from building_recipes.json since they now live in building types.
"""

import json

def main():
    # Read the original file
    with open('data/building_recipes.json', 'r') as f:
        data = json.load(f)

    # Remove workers field from each recipe
    for recipe in data['recipes']:
        if 'workers' in recipe:
            del recipe['workers']

    # Write the updated file
    with open('data/building_recipes.json', 'w') as f:
        json.dump(data, f, indent=2)

    print(f"Updated {len(data['recipes'])} recipes - removed worker requirements")
    print("Successfully updated data/building_recipes.json")


if __name__ == "__main__":
    main()
