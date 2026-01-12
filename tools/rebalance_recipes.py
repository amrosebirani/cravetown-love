#!/usr/bin/env python3
"""
Recipe Rebalancing Script for Cravetown
Caps all production times at 1800s (30 min) and adjusts inputs/outputs proportionally.
"""

import json
import copy
from pathlib import Path

# Configuration
MAX_TIME = 1800  # 30 minutes max

# Category-specific rules: (target_time_range, output_factor)
# output_factor: what fraction of original output to keep when time is scaled down
CATEGORY_RULES = {
    # Already handled orchards manually, skip them
    "orchard": {"skip": True},

    # Farms: fast production (5-15 min)
    "farm": {"min_time": 300, "max_time": 900, "output_factor": 0.25, "input_factor": 0.25},

    # Mining: medium-slow (15-30 min)
    "mine": {"min_time": 900, "max_time": 1800, "output_factor": 0.20, "input_factor": 1.0},

    # Hunting/Animal: slow (25-30 min)
    "hunting_lodge": {"min_time": 900, "max_time": 1500, "output_factor": 0.25, "input_factor": 1.0},

    # Brewing/Distillery/Winery: medium (15-25 min)
    "bar": {"min_time": 600, "max_time": 1200, "output_factor": 0.25, "input_factor": 0.25},
    "distillery": {"min_time": 900, "max_time": 1500, "output_factor": 0.25, "input_factor": 0.25},
    "winery": {"min_time": 1200, "max_time": 1800, "output_factor": 0.25, "input_factor": 0.25},

    # Dairy: medium (15-25 min)
    "dairy": {"min_time": 600, "max_time": 1200, "output_factor": 0.30, "input_factor": 0.30},

    # Forge/Smelting: medium (12-25 min)
    "forge": {"min_time": 720, "max_time": 1500, "output_factor": 0.30, "input_factor": 0.30},

    # Preservery: medium (10-20 min)
    "preservery": {"min_time": 600, "max_time": 1200, "output_factor": 0.30, "input_factor": 0.30},

    # Charcoal: medium (15-20 min)
    "charcoal_kiln": {"min_time": 900, "max_time": 1200, "output_factor": 0.25, "input_factor": 0.25},

    # Tannery: medium (10-25 min)
    "tannery": {"min_time": 600, "max_time": 1500, "output_factor": 0.35, "input_factor": 0.35},

    # Scriptorium/Art: slow luxury (20-30 min)
    "scriptorium": {"min_time": 1200, "max_time": 1800, "output_factor": 0.30, "input_factor": 0.30},
    "art_workshop": {"min_time": 1200, "max_time": 1800, "output_factor": 0.30, "input_factor": 0.30},

    # Stonecutters: slow (20-30 min)
    "stonecutters": {"min_time": 1200, "max_time": 1800, "output_factor": 0.30, "input_factor": 0.30},

    # Jewelry: slow luxury (25-30 min)
    "jewelry_workshop": {"min_time": 1500, "max_time": 1800, "output_factor": 0.30, "input_factor": 0.30},

    # Weaving: slow luxury (20-30 min)
    "weaving_workshop": {"min_time": 1200, "max_time": 1800, "output_factor": 0.30, "input_factor": 0.30},

    # Tailor (specialty): medium (15-25 min)
    "tailor": {"min_time": 900, "max_time": 1500, "output_factor": 0.35, "input_factor": 0.35},

    # Restaurant: fast (5-15 min)
    "restaurant": {"min_time": 300, "max_time": 900, "output_factor": 0.35, "input_factor": 0.35},

    # Apiary: slow (25-30 min)
    "apiary": {"min_time": 1500, "max_time": 1800, "output_factor": 0.15, "input_factor": 0.15},

    # Brickyard: medium (15-25 min) - cap at 1800
    "brickyard": {"min_time": 900, "max_time": 1500, "output_factor": 0.40, "input_factor": 0.40},

    # Furniture: medium (15-25 min) - cap at 1800
    "furniture_shop": {"min_time": 900, "max_time": 1500, "output_factor": 0.50, "input_factor": 0.50},

    # Tailor shop: fast-medium (8-25 min)
    "tailor_shop": {"min_time": 480, "max_time": 1500, "output_factor": 0.50, "input_factor": 0.50},

    # Textile: fast-medium (5-15 min)
    "textile_mill": {"min_time": 300, "max_time": 900, "output_factor": 0.50, "input_factor": 0.50},
}

# Specific recipe overrides for critical balancing
RECIPE_OVERRIDES = {
    # Critical food chain - keep bakery fast with good output
    "Bread Baking": {"time": 120, "output_factor": 1.25},  # 2 min, boost output
    "Pav Baking": {"time": 180, "output_factor": 1.0},
    "Meal Preparation": {"time": 180, "output_factor": 1.0},

    # Goat and honey are special animal products
    "Goat Raising": {"time": 1800, "outputs": {"goat": 2}, "inputs": {"goat": 1}},
    "Honey Production": {"time": 1800, "outputs": {"honey": 5, "beeswax": 2}, "inputs": {}},

    # Wine/Cider - luxury drinks
    "Wine Making": {"time": 1500, "outputs": {"wine": 8}, "inputs": {"grapes": 25}},
    "Cider Making": {"time": 1200, "outputs": {"cider": 10}, "inputs": {"apple": 20}},

    # Crown and tapestry are ultra-luxury
    "Crown Crafting": {"time": 1800},
    "Tapestry Weaving": {"time": 1800},
}


def scale_time(old_time, building_type):
    """Calculate new production time based on building category."""
    if old_time <= MAX_TIME:
        return old_time  # Already within limit

    rules = CATEGORY_RULES.get(building_type, {})
    if rules.get("skip"):
        return old_time  # Skip this category

    min_time = rules.get("min_time", 600)
    max_time = rules.get("max_time", MAX_TIME)

    # Scale proportionally within the target range
    # Higher original times -> closer to max_time
    if old_time > 86400:  # More than 1 day
        return max_time
    elif old_time > 10800:  # More than 3 hours
        return int(min_time + (max_time - min_time) * 0.9)
    elif old_time > 7200:  # More than 2 hours
        return int(min_time + (max_time - min_time) * 0.7)
    elif old_time > 3600:  # More than 1 hour
        return int(min_time + (max_time - min_time) * 0.5)
    else:  # Between 30 min and 1 hour
        return int(min_time + (max_time - min_time) * 0.3)


def scale_quantity(old_qty, old_time, new_time, factor):
    """Scale quantity proportionally with a factor."""
    if old_time == 0:
        return old_qty

    # Basic scaling: new_qty = old_qty * factor
    new_qty = int(old_qty * factor)
    return max(1, new_qty)  # At least 1


def rebalance_recipe(recipe):
    """Rebalance a single recipe."""
    building_type = recipe.get("buildingType", "")
    recipe_name = recipe.get("recipeName", "")
    old_time = recipe.get("productionTime", 0)
    old_outputs = recipe.get("outputs", {})
    old_inputs = recipe.get("inputs", {})

    # Check for specific override first
    override = RECIPE_OVERRIDES.get(recipe_name, {})

    if override:
        new_time = override.get("time", old_time)

        # Handle explicit outputs override
        if "outputs" in override:
            new_outputs = override["outputs"]
        else:
            output_factor = override.get("output_factor", 1.0)
            new_outputs = {k: max(1, int(v * output_factor)) for k, v in old_outputs.items()}

        # Handle explicit inputs override
        if "inputs" in override:
            new_inputs = override["inputs"]
        else:
            new_inputs = old_inputs  # Keep original inputs unless specified

    else:
        # Check if building type should be skipped
        rules = CATEGORY_RULES.get(building_type, {})
        if rules.get("skip"):
            return recipe  # Return unchanged

        # Only modify if over the limit
        if old_time <= MAX_TIME:
            return recipe  # Already within limit

        # Calculate new time
        new_time = scale_time(old_time, building_type)

        # Scale outputs and inputs
        output_factor = rules.get("output_factor", 0.30)
        input_factor = rules.get("input_factor", 0.30)

        new_outputs = {k: scale_quantity(v, old_time, new_time, output_factor)
                       for k, v in old_outputs.items()}
        new_inputs = {k: scale_quantity(v, old_time, new_time, input_factor)
                      for k, v in old_inputs.items()}

    # Update recipe
    recipe["productionTime"] = new_time
    recipe["outputs"] = new_outputs
    if new_inputs:
        recipe["inputs"] = new_inputs

    # Update notes
    minutes = new_time // 60
    seconds = new_time % 60
    if seconds == 0:
        time_str = f"{minutes} min"
    else:
        time_str = f"{minutes}m {seconds}s"

    old_note = recipe.get("notes", "")
    recipe["notes"] = f"{time_str}. Rebalanced from {old_time}s. {old_note[:50]}..."

    return recipe


def rebalance_all(input_path, output_path=None):
    """Rebalance all recipes in the file."""
    with open(input_path, 'r') as f:
        data = json.load(f)

    recipes = data.get("recipes", [])
    changes = []

    for i, recipe in enumerate(recipes):
        old_time = recipe.get("productionTime", 0)
        old_outputs = copy.deepcopy(recipe.get("outputs", {}))

        rebalance_recipe(recipe)

        new_time = recipe.get("productionTime", 0)
        new_outputs = recipe.get("outputs", {})

        if old_time != new_time or old_outputs != new_outputs:
            changes.append({
                "recipe": recipe.get("recipeName"),
                "building": recipe.get("buildingType"),
                "old_time": old_time,
                "new_time": new_time,
                "old_outputs": old_outputs,
                "new_outputs": new_outputs
            })

    # Save
    out_path = output_path or input_path
    with open(out_path, 'w') as f:
        json.dump(data, f, indent=2)

    # Print summary
    print(f"Rebalanced {len(changes)} recipes")
    for c in changes[:20]:  # Show first 20
        print(f"  {c['recipe']}: {c['old_time']}s -> {c['new_time']}s")
    if len(changes) > 20:
        print(f"  ... and {len(changes) - 20} more")

    return changes


if __name__ == "__main__":
    input_file = Path(__file__).parent.parent / "data/alpha/building_recipes.json"
    rebalance_all(input_file)
