#!/usr/bin/env python3
"""
apply_production_multiplier.py

Applies a production speed multiplier to all recipes in building_recipes.json
Used for Task A7: Balance adjustment (5x production speed increase)

Usage:
    python tools/apply_production_multiplier.py --multiplier 0.2
    # 0.2 = divide by 5 = 5x speed increase

    python tools/apply_production_multiplier.py --multiplier 2.0
    # 2.0 = multiply by 2 = 2x slowdown

    python tools/apply_production_multiplier.py --file data/base/building_recipes.json --multiplier 0.2
    # Specify custom file path
"""

import json
import argparse
import shutil
from datetime import datetime
from pathlib import Path


def backup_file(filepath):
    """Create timestamped backup of original file"""
    backup_path = filepath.with_suffix(f'.backup.{datetime.now().strftime("%Y%m%d_%H%M%S")}.json')
    shutil.copy2(filepath, backup_path)
    print(f"✅ Backup created: {backup_path}")
    return backup_path


def apply_multiplier(recipes_data, multiplier, dry_run=False):
    """Apply production time multiplier to all recipes"""
    changes = []

    for recipe in recipes_data.get("recipes", []):
        if "productionTime" in recipe:
            old_time = recipe["productionTime"]
            new_time = old_time * multiplier

            # Round to nearest second
            new_time = round(new_time)

            changes.append({
                "id": recipe.get("id", "unknown"),
                "name": recipe.get("name", "Unknown"),
                "old_time": old_time,
                "new_time": new_time,
                "change": f"{old_time}s → {new_time}s ({multiplier}x)"
            })

            if not dry_run:
                recipe["productionTime"] = new_time

    return changes


def format_time(seconds):
    """Format seconds into human-readable time"""
    if seconds < 60:
        return f"{seconds}s"
    elif seconds < 3600:
        return f"{seconds//60}m {seconds%60}s"
    else:
        hours = seconds // 3600
        minutes = (seconds % 3600) // 60
        return f"{hours}h {minutes}m"


def main():
    parser = argparse.ArgumentParser(
        description="Apply production speed multiplier to building recipes"
    )
    parser.add_argument(
        "--file",
        type=str,
        default="data/alpha/building_recipes.json",
        help="Path to building_recipes.json (default: data/alpha/building_recipes.json)"
    )
    parser.add_argument(
        "--multiplier",
        type=float,
        required=True,
        help="Multiplier for production time (0.2 = 5x faster, 2.0 = 2x slower)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview changes without modifying files"
    )
    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Skip backup creation (not recommended!)"
    )

    args = parser.parse_args()

    # Validate
    filepath = Path(args.file)
    if not filepath.exists():
        print(f"❌ Error: File not found: {filepath}")
        return 1

    # Load recipes
    print(f"📖 Loading: {filepath}")
    with open(filepath, 'r') as f:
        recipes_data = json.load(f)

    # Create backup (unless disabled or dry-run)
    if not args.dry_run and not args.no_backup:
        backup_path = backup_file(filepath)

    # Apply multiplier
    print(f"\n{'[DRY RUN] ' if args.dry_run else ''}Applying {args.multiplier}x multiplier...")
    changes = apply_multiplier(recipes_data, args.multiplier, dry_run=args.dry_run)

    # Print summary
    print(f"\n{'📋 PREVIEW' if args.dry_run else '✅ CHANGES APPLIED'}: {len(changes)} recipes modified\n")

    print("Recipe ID                        | Old Time      | New Time      | Change")
    print("-" * 85)
    for change in changes:
        print(f"{change['id']:32} | {format_time(change['old_time']):13} | {format_time(change['new_time']):13} | {args.multiplier}x")

    # Save changes
    if not args.dry_run:
        with open(filepath, 'w') as f:
            json.dump(recipes_data, f, indent=2)
        print(f"\n✅ Saved: {filepath}")

        # Create changelog entry
        changelog_path = Path("docs/balance_changelog.md")
        if changelog_path.exists():
            with open(changelog_path, 'a') as f:
                f.write(f"\n## {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
                f.write(f"**Change**: Applied {args.multiplier}x production speed multiplier\n")
                f.write(f"**File**: {filepath}\n")
                f.write(f"**Recipes Modified**: {len(changes)}\n")
                f.write(f"**Backup**: {backup_path if not args.no_backup else 'None'}\n\n")
            print(f"✅ Logged to: {changelog_path}")
    else:
        print("\n⚠️  DRY RUN - No files modified. Remove --dry-run to apply changes.")

    return 0


if __name__ == "__main__":
    exit(main())
