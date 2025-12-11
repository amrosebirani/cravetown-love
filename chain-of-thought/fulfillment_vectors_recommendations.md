# Comprehensive Fulfillment Vectors Recommendations

## Overview

This document provides detailed recommendations for mapping all commodities to craving dimensions (fulfillment vectors). Each commodity is assigned one or more craving dimensions it can satisfy, along with satisfaction values and consumption mechanics.

## Craving Dimension Reference

The 49 craving dimensions are organized into 9 coarse categories:

### Biological (7 dimensions)
- `biological_nutrition_grain` - Grain-based foods
- `biological_nutrition_protein` - Protein sources
- `biological_nutrition_produce` - Fruits, vegetables
- `biological_hydration` - Liquids, beverages
- `biological_health_medicine` - Medical care
- `biological_health_hygiene` - Cleanliness
- `biological_energy_rest` - Sleep, rest
- `biological_energy_stimulation` - Energy boosters

### Safety (5 dimensions)
- `safety_security_law` - Law and order
- `safety_security_defense` - Personal defense
- `safety_shelter_housing` - Housing
- `safety_shelter_warmth` - Temperature comfort
- `safety_fire_protection` - Fire safety

### Touch/Physical (6 dimensions)
- `touch_clothing_everyday` - Basic clothing
- `touch_clothing_formal` - Formal attire
- `touch_furniture_functional` - Functional furniture
- `touch_furniture_decorative` - Decorative items
- `touch_textiles_bedding` - Bedding
- `touch_sensory_luxury` - Luxury sensory items

### Psychological (7 dimensions)
- `psychological_education_books` - Reading
- `psychological_education_formal` - Formal education
- `psychological_entertainment_arts` - Arts, culture
- `psychological_entertainment_games` - Games, leisure
- `psychological_purpose_work` - Meaningful work
- `psychological_purpose_religion` - Spirituality
- `psychological_purpose_civic` - Civic participation

### Status (6 dimensions)
- `status_reputation_display` - Status display
- `status_reputation_title` - Titles, recognition
- `status_wealth_precious` - Precious items
- `status_wealth_property` - Property ownership
- `status_service_servants` - Being served
- `status_fashion_luxury` - Luxury fashion

### Social (5 dimensions)
- `social_friendship_casual` - Casual socializing
- `social_friendship_intimate` - Close relationships
- `social_community_church` - Religious community
- `social_community_civic` - Civic community
- `social_family_bonds` - Family bonds

### Exotic (4 dimensions)
- `exotic_food_spices` - Exotic spices
- `exotic_food_imports` - Imported foods
- `exotic_items_textiles` - Exotic textiles
- `exotic_items_novelty` - Novelty items

### Shiny (4 dimensions)
- `shiny_precious_gold` - Gold items
- `shiny_precious_silver` - Silver items
- `shiny_precious_gems` - Gemstones
- `shiny_decorative_art` - Decorative art

### Vice (5 dimensions)
- `vice_alcohol_beer` - Beer
- `vice_alcohol_spirits` - Spirits, wine
- `vice_gambling` - Gambling
- `vice_indulgence_sweets` - Sweets
- `vice_indulgence_excess` - Excess/gluttony

---

## Fulfillment Vector Schema

Each commodity fulfillment entry should have:

```json
{
  "commodityId": "bread",
  "fulfillment": [
    {
      "dimension": "biological_nutrition_grain",
      "satisfaction": 0.7,
      "consumptionRate": 2,
      "consumptionUnit": "loaf",
      "consumptionPeriod": "day"
    }
  ],
  "consumptionType": "consumable",
  "qualityTier": "standard",
  "notes": "Staple food"
}
```

### Consumption Types
- `consumable` - Single use, destroyed on consumption (food, candles)
- `durable` - Multiple uses over time (furniture, clothing, tools)
- `permanent` - Owned indefinitely (jewelry, art)
- `service` - Provides ongoing effect while owned (housing)
- `raw_material` - Not directly consumed, used in production

### Quality Tiers
- `basic` - Minimal satisfaction (0.3-0.5)
- `standard` - Normal satisfaction (0.5-0.7)
- `fine` - Good satisfaction (0.7-0.85)
- `luxury` - High satisfaction (0.85-1.0)

---

## FOOD COMMODITIES

### Grains & Grain Products

| Commodity | Dimension | Satisfaction | Rate | Period | Type | Tier |
|-----------|-----------|--------------|------|--------|------|------|
| wheat | raw_material | - | - | - | raw_material | - |
| rice | biological_nutrition_grain | 0.6 | 0.4kg | day | consumable | standard |
| barley | raw_material | - | - | - | raw_material | - |
| oats | biological_nutrition_grain | 0.55 | 0.3kg | day | consumable | standard |
| rye | raw_material | - | - | - | raw_material | - |
| maize | biological_nutrition_grain | 0.5 | 0.3kg | day | consumable | basic |
| ragi | biological_nutrition_grain | 0.5 | 0.3kg | day | consumable | basic |
| flour | raw_material | - | - | - | raw_material | - |
| rice_flour | raw_material | - | - | - | raw_material | - |
| cornmeal | raw_material | - | - | - | raw_material | - |
| lentil_flour | raw_material | - | - | - | raw_material | - |

### Bread & Baked Goods

| Commodity | Dimension | Satisfaction | Rate | Period | Type | Tier |
|-----------|-----------|--------------|------|--------|------|------|
| bread | biological_nutrition_grain | 0.7 | 1.5 loaf | day | consumable | standard |
| roti | biological_nutrition_grain | 0.65 | 4 pc | day | consumable | standard |
| naan | biological_nutrition_grain | 0.75 | 2 pc | day | consumable | fine |
| paratha | biological_nutrition_grain | 0.7 | 2 pc | day | consumable | standard |
| puri | biological_nutrition_grain | 0.65 | 3 pc | day | consumable | standard |
| tortilla | biological_nutrition_grain | 0.6 | 4 pc | day | consumable | standard |
| pastries | biological_nutrition_grain + vice_indulgence_sweets | 0.8 / 0.7 | 1 pc | day | consumable | fine |
| cake | vice_indulgence_sweets | 0.9 | 0.1 pc | day | consumable | luxury |

### Protein Sources

| Commodity | Dimension | Satisfaction | Rate | Period | Type | Tier |
|-----------|-----------|--------------|------|--------|------|------|
| meat (generic) | biological_nutrition_protein | 0.7 | 0.3kg | day | consumable | standard |
| chicken | biological_nutrition_protein | 0.7 | 0.25kg | day | consumable | standard |
| beef | biological_nutrition_protein | 0.75 | 0.3kg | day | consumable | standard |
| mutton | biological_nutrition_protein | 0.8 | 0.25kg | day | consumable | fine |
| eggs | biological_nutrition_protein | 0.6 | 2 pc | day | consumable | standard |
| cheese | biological_nutrition_protein | 0.75 | 0.05kg | day | consumable | fine |
| paneer | biological_nutrition_protein | 0.7 | 0.1kg | day | consumable | standard |
| lentils | biological_nutrition_protein | 0.6 | 0.2kg | day | consumable | basic |

### Fruits & Produce

| Commodity | Dimension | Satisfaction | Rate | Period | Type | Tier |
|-----------|-----------|--------------|------|--------|------|------|
| apple | biological_nutrition_produce | 0.7 | 2 pc | day | consumable | standard |
| mango | biological_nutrition_produce + exotic_food_imports | 0.85 / 0.6 | 1 pc | day | consumable | fine |
| orange | biological_nutrition_produce | 0.7 | 2 pc | day | consumable | standard |
| grapes | biological_nutrition_produce | 0.65 | 0.2kg | day | consumable | standard |
| berries | biological_nutrition_produce | 0.6 | 0.1kg | day | consumable | standard |
| peach | biological_nutrition_produce | 0.7 | 2 pc | day | consumable | standard |
| pear | biological_nutrition_produce | 0.65 | 2 pc | day | consumable | standard |
| watermelon | biological_nutrition_produce + biological_hydration | 0.7 / 0.3 | 0.5kg | day | consumable | standard |
| date | biological_nutrition_produce + vice_indulgence_sweets | 0.75 / 0.4 | 0.05kg | day | consumable | fine |
| coconut | biological_nutrition_produce + biological_hydration | 0.7 / 0.4 | 0.5 pc | day | consumable | standard |

### Vegetables

| Commodity | Dimension | Satisfaction | Rate | Period | Type | Tier |
|-----------|-----------|--------------|------|--------|------|------|
| potato | biological_nutrition_produce | 0.5 | 0.3kg | day | consumable | basic |
| carrot | biological_nutrition_produce | 0.5 | 0.15kg | day | consumable | basic |
| tomato | biological_nutrition_produce | 0.45 | 0.15kg | day | consumable | basic |
| lettuce | biological_nutrition_produce | 0.4 | 0.1kg | day | consumable | basic |
| beans | biological_nutrition_produce + biological_nutrition_protein | 0.5 / 0.4 | 0.15kg | day | consumable | basic |
| cabbage | biological_nutrition_produce | 0.45 | 0.2kg | day | consumable | basic |
| broccoli | biological_nutrition_produce | 0.55 | 0.15kg | day | consumable | standard |
| onion | biological_nutrition_produce | 0.3 | 0.1kg | day | consumable | basic |
| pumpkin | biological_nutrition_produce | 0.5 | 0.3kg | day | consumable | basic |
| pepper | biological_nutrition_produce + exotic_food_spices | 0.4 / 0.5 | 0.02kg | day | consumable | standard |
| vegetable | biological_nutrition_produce | 0.5 | 0.3kg | day | consumable | basic |

### Prepared Meals

| Commodity | Dimension(s) | Satisfaction | Rate | Period | Type | Tier |
|-----------|--------------|--------------|------|--------|------|------|
| meal | biological_nutrition_grain + biological_nutrition_protein + biological_nutrition_produce | 0.8 / 0.7 / 0.6 | 3 | day | consumable | standard |
| dal | biological_nutrition_protein | 0.65 | 1 serving | day | consumable | standard |
| biryani | biological_nutrition_grain + biological_nutrition_protein + exotic_food_spices | 0.9 / 0.85 / 0.7 | 1 serving | day | consumable | luxury |
| khichdi | biological_nutrition_grain + biological_nutrition_protein | 0.65 / 0.5 | 1 serving | day | consumable | basic |
| pulao | biological_nutrition_grain | 0.7 | 1 serving | day | consumable | standard |
| porridge | biological_nutrition_grain | 0.55 | 1 serving | day | consumable | basic |
| vegetable_soup | biological_nutrition_produce + safety_shelter_warmth | 0.5 / 0.3 | 1 serving | day | consumable | basic |
| salad | biological_nutrition_produce | 0.5 | 1 serving | day | consumable | basic |
| stew | biological_nutrition_protein + biological_nutrition_produce + safety_shelter_warmth | 0.75 / 0.5 / 0.4 | 1 serving | day | consumable | standard |
| pie | biological_nutrition_grain + vice_indulgence_sweets | 0.7 / 0.6 | 0.5 pc | day | consumable | fine |

### Indian Street Food

| Commodity | Dimension(s) | Satisfaction | Rate | Period | Type | Tier |
|-----------|--------------|--------------|------|--------|------|------|
| samosa | biological_nutrition_grain + vice_indulgence_excess | 0.65 / 0.5 | 2 pc | day | consumable | standard |
| kachori | biological_nutrition_grain + vice_indulgence_excess | 0.6 / 0.45 | 2 pc | day | consumable | standard |
| pakora | biological_nutrition_produce + vice_indulgence_excess | 0.5 / 0.4 | 4 pc | day | consumable | basic |
| vada | biological_nutrition_protein + vice_indulgence_excess | 0.55 / 0.4 | 2 pc | day | consumable | basic |
| idli | biological_nutrition_grain | 0.6 | 3 pc | day | consumable | standard |
| dosa | biological_nutrition_grain | 0.65 | 2 pc | day | consumable | standard |

### Sweets

| Commodity | Dimension | Satisfaction | Rate | Period | Type | Tier |
|-----------|-----------|--------------|------|--------|------|------|
| ladoo | vice_indulgence_sweets | 0.8 | 2 pc | day | consumable | fine |
| jalebi | vice_indulgence_sweets | 0.75 | 3 pc | day | consumable | fine |
| halwa | vice_indulgence_sweets + safety_shelter_warmth | 0.8 / 0.3 | 1 serving | day | consumable | fine |
| candy | vice_indulgence_sweets | 0.6 | 3 pc | day | consumable | standard |
| sugar | raw_material | - | - | - | raw_material | - |
| honey | vice_indulgence_sweets + biological_health_medicine | 0.7 / 0.3 | 0.02kg | day | consumable | fine |

### Preserved Foods

| Commodity | Dimension | Satisfaction | Rate | Period | Type | Tier |
|-----------|-----------|--------------|------|--------|------|------|
| preserved_food | biological_nutrition_grain | 0.5 | 0.3kg | day | consumable | basic |
| dried_fruit | biological_nutrition_produce + vice_indulgence_sweets | 0.6 / 0.5 | 0.1kg | day | consumable | standard |
| pickles | biological_nutrition_produce + exotic_food_spices | 0.4 / 0.4 | 0.05kg | day | consumable | standard |
| jam | vice_indulgence_sweets | 0.6 | 0.03kg | day | consumable | standard |
| tomato_sauce | exotic_food_spices | 0.3 | 0.05kg | day | consumable | basic |

### Dairy Products

| Commodity | Dimension | Satisfaction | Rate | Period | Type | Tier |
|-----------|-----------|--------------|------|--------|------|------|
| milk | biological_hydration + biological_nutrition_protein | 0.6 / 0.4 | 0.5L | day | consumable | standard |
| curd | biological_nutrition_protein + biological_health_medicine | 0.6 / 0.2 | 0.25L | day | consumable | standard |
| cream | vice_indulgence_excess | 0.5 | 0.05L | day | consumable | fine |
| butter | raw_material | - | - | - | raw_material | - |
| ghee | raw_material (cooking ingredient, small satisfaction as luxury) | 0.3 | 0.02kg | day | consumable | fine |
| buttermilk | biological_hydration | 0.5 | 0.3L | day | consumable | basic |

### Nuts & Seeds (as food)

| Commodity | Dimension | Satisfaction | Rate | Period | Type | Tier |
|-----------|-----------|--------------|------|--------|------|------|
| groundnut | biological_nutrition_protein | 0.5 | 0.05kg | day | consumable | basic |

---

## BEVERAGES

| Commodity | Dimension(s) | Satisfaction | Rate | Period | Type | Tier |
|-----------|--------------|--------------|------|--------|------|------|
| wine | vice_alcohol_spirits + social_friendship_casual | 0.8 / 0.5 | 0.25 bottle | day | consumable | fine |
| beer | vice_alcohol_beer + social_friendship_casual | 0.7 / 0.4 | 0.5L | day | consumable | standard |
| whiskey | vice_alcohol_spirits | 0.85 | 0.05L | day | consumable | luxury |
| rum | vice_alcohol_spirits + social_friendship_casual | 0.75 / 0.4 | 0.1L | day | consumable | fine |
| cider | vice_alcohol_beer + biological_hydration | 0.6 / 0.3 | 0.3L | day | consumable | standard |
| fruit_juice | biological_hydration + biological_nutrition_produce | 0.7 / 0.4 | 0.3L | day | consumable | standard |

### CRITICAL MISSING: Water
Need to add:
```json
{
  "id": "water",
  "fulfillment": [
    {
      "dimension": "biological_hydration",
      "satisfaction": 0.8,
      "consumptionRate": 2,
      "consumptionUnit": "liter",
      "consumptionPeriod": "day"
    }
  ],
  "consumptionType": "consumable",
  "qualityTier": "basic",
  "notes": "Essential - every citizen needs water daily"
}
```

### RECOMMENDED: Tea
```json
{
  "id": "tea",
  "fulfillment": [
    {
      "dimension": "biological_hydration",
      "satisfaction": 0.6
    },
    {
      "dimension": "biological_energy_stimulation",
      "satisfaction": 0.7
    },
    {
      "dimension": "social_friendship_casual",
      "satisfaction": 0.4
    }
  ],
  "consumptionType": "consumable",
  "qualityTier": "standard"
}
```

---

## CLOTHING

### Everyday Clothing

| Commodity | Dimension(s) | Satisfaction | Durability | Type | Tier |
|-----------|--------------|--------------|------------|------|------|
| simple_clothes | touch_clothing_everyday | 0.6 | 90 days | durable | basic |
| clothing | touch_clothing_everyday | 0.5 | 90 days | durable | basic |
| shirt | touch_clothing_everyday | 0.55 | 90 days | durable | basic |
| pants | touch_clothing_everyday | 0.55 | 90 days | durable | basic |
| work_clothes | touch_clothing_everyday + psychological_purpose_work | 0.65 / 0.3 | 120 days | durable | standard |
| uniform | touch_clothing_everyday + psychological_purpose_work | 0.7 / 0.4 | 120 days | durable | standard |

### Formal & Luxury Clothing

| Commodity | Dimension(s) | Satisfaction | Durability | Type | Tier |
|-----------|--------------|--------------|------------|------|------|
| fine_clothes | touch_clothing_formal + status_fashion_luxury | 0.8 / 0.5 | 180 days | durable | fine |
| luxury_clothes | touch_clothing_formal + status_fashion_luxury + status_reputation_display | 0.9 / 0.8 / 0.6 | 180 days | durable | luxury |
| dress | touch_clothing_formal + status_fashion_luxury | 0.75 / 0.5 | 180 days | durable | fine |
| formal_attire | touch_clothing_formal + status_fashion_luxury + status_reputation_display | 0.85 / 0.7 / 0.5 | 180 days | durable | fine |
| ceremonial_robes | touch_clothing_formal + status_fashion_luxury + psychological_purpose_religion | 0.95 / 0.9 / 0.7 | 365 days | durable | luxury |

### Outerwear & Weather

| Commodity | Dimension(s) | Satisfaction | Durability | Type | Tier |
|-----------|--------------|--------------|------------|------|------|
| coat | touch_clothing_everyday + safety_shelter_warmth | 0.7 / 0.6 | 180 days | durable | standard |
| winter_coat | safety_shelter_warmth + touch_clothing_everyday | 0.85 / 0.6 | 180 days | durable | fine |
| hat | touch_clothing_everyday | 0.4 | 120 days | durable | basic |
| wool_hat | touch_clothing_everyday + safety_shelter_warmth | 0.5 / 0.5 | 90 days | durable | standard |

### Footwear

| Commodity | Dimension(s) | Satisfaction | Durability | Type | Tier |
|-----------|--------------|--------------|------------|------|------|
| shoes | touch_clothing_everyday | 0.6 | 120 days | durable | standard |
| boots | touch_clothing_everyday + psychological_purpose_work | 0.7 / 0.3 | 150 days | durable | standard |

### Accessories

| Commodity | Dimension(s) | Satisfaction | Durability | Type | Tier |
|-----------|--------------|--------------|------------|------|------|
| gloves | touch_clothing_everyday + safety_shelter_warmth | 0.5 / 0.4 | 90 days | durable | standard |
| wool_gloves | touch_clothing_everyday + safety_shelter_warmth | 0.5 / 0.5 | 60 days | durable | standard |

---

## FURNITURE

### Sleeping & Rest

| Commodity | Dimension(s) | Satisfaction | Durability | Type | Tier |
|-----------|--------------|--------------|------------|------|------|
| bed | biological_energy_rest + touch_textiles_bedding | 0.8 / 0.7 | 365 days | durable | standard |
| cradle | biological_energy_rest (children) | 0.5 | 365 days | durable | basic |

### Seating

| Commodity | Dimension(s) | Satisfaction | Durability | Type | Tier |
|-----------|--------------|--------------|------------|------|------|
| chair | touch_furniture_functional | 0.6 | 500 days | durable | standard |
| bench | touch_furniture_functional + social_friendship_casual | 0.5 / 0.3 | 500 days | durable | basic |
| stool | touch_furniture_functional | 0.4 | 500 days | durable | basic |

### Tables & Surfaces

| Commodity | Dimension(s) | Satisfaction | Durability | Type | Tier |
|-----------|--------------|--------------|------------|------|------|
| table | touch_furniture_functional | 0.6 | 500 days | durable | standard |
| desk | touch_furniture_functional + psychological_education_books | 0.65 / 0.4 | 500 days | durable | standard |

### Storage

| Commodity | Dimension(s) | Satisfaction | Durability | Type | Tier |
|-----------|--------------|--------------|------------|------|------|
| cabinet | touch_furniture_functional | 0.5 | 700 days | durable | standard |
| wardrobe | touch_furniture_functional | 0.55 | 700 days | durable | standard |
| bookshelf | touch_furniture_functional + psychological_education_books | 0.55 / 0.5 | 700 days | durable | standard |
| shelf | touch_furniture_functional | 0.4 | 500 days | durable | basic |
| chest | touch_furniture_functional + safety_security_defense | 0.5 / 0.3 | 700 days | durable | standard |

### Building Components

| Commodity | Dimension(s) | Satisfaction | Durability | Type | Tier |
|-----------|--------------|--------------|------------|------|------|
| door | safety_shelter_housing + safety_security_defense | 0.4 / 0.4 | 1000 days | durable | standard |

---

## TOOLS

Tools don't directly satisfy cravings but provide work efficiency. They should have a special mechanic:

| Commodity | Work Category Bonus | Durability | Type | Tier |
|-----------|---------------------|------------|------|------|
| axe | Forestry +50% | 365 days | durable | standard |
| hammer | Construction +30% | 365 days | durable | standard |
| saw | Woodworking +40% | 365 days | durable | standard |
| pickaxe | Mining +50% | 365 days | durable | standard |
| shovel | Agriculture +20%, Mining +20% | 365 days | durable | standard |
| hoe | Agriculture +40% | 365 days | durable | standard |
| scythe | Agriculture (Harvesting) +60% | 365 days | durable | standard |
| chisel | Artisan Crafts +30%, Art +40% | 365 days | durable | standard |
| needle | Tailoring +40% | 180 days | durable | basic |
| knife | General +10% | 365 days | durable | basic |
| nails | Construction material | - | consumable | - |

**Special Case:** Tools should provide indirect satisfaction through `psychological_purpose_work` when used at appropriate jobs.

---

## HOUSEHOLD & HYGIENE

### Lighting

| Commodity | Dimension(s) | Satisfaction | Duration | Type | Tier |
|-----------|--------------|--------------|----------|------|------|
| candle | (lighting effect) | N/A | 8 hours | consumable | basic |
| beeswax_candle | touch_sensory_luxury + (lighting effect) | 0.4 | 10 hours | consumable | fine |
| lamp_oil | (lighting fuel) | N/A | 20 hours | consumable | standard |

**Note:** Lighting commodities should provide a "lighting" effect that enables evening activities. Without light, citizens can't fulfill evening cravings for entertainment, reading, etc.

### Hygiene

| Commodity | Dimension(s) | Satisfaction | Rate | Period | Type | Tier |
|-----------|--------------|--------------|------|--------|------|------|
| soap | biological_health_hygiene | 0.7 | 0.033 bar | day | consumable | standard |
| flower_water | biological_health_hygiene + touch_sensory_luxury | 0.5 / 0.4 | 0.02L | day | consumable | standard |
| perfume | touch_sensory_luxury + status_reputation_display | 0.7 / 0.4 | 0.01 bottle | day | consumable | fine |

### Health & Medicine

| Commodity | Dimension(s) | Satisfaction | Trigger | Type | Tier |
|-----------|--------------|--------------|---------|------|------|
| medicine | biological_health_medicine | 0.8 | when sick | consumable | standard |
| healing_salve | biological_health_medicine | 0.7 | when injured | consumable | standard |
| tonic | biological_health_medicine + biological_energy_stimulation | 0.5 / 0.4 | preventive | consumable | fine |
| medicinal_herbs | biological_health_medicine | 0.4 | when sick | consumable | basic |

### Containers & Household Items

| Commodity | Dimension(s) | Satisfaction | Durability | Type | Tier |
|-----------|--------------|--------------|------------|------|------|
| pottery | touch_furniture_functional | 0.4 | 500 days | durable | basic |
| ceramics | touch_furniture_functional | 0.5 | 500 days | durable | standard |
| glassware | touch_furniture_functional + touch_furniture_decorative | 0.5 / 0.3 | 300 days | durable | standard |
| barrel | (storage container) | N/A | 1000 days | durable | - |
| crate | (storage container) | N/A | 365 days | durable | - |
| bottle | (container) | N/A | 1000 days | durable | - |
| mirror | touch_furniture_decorative + biological_health_hygiene | 0.5 / 0.3 | 3650 days | durable | fine |

---

## LUXURY & STATUS ITEMS

### Jewelry

| Commodity | Dimension(s) | Satisfaction | Type | Tier |
|-----------|--------------|--------------|------|------|
| jewelry | status_wealth_precious + status_reputation_display | 0.7 / 0.5 | permanent | fine |
| silver_ring | shiny_precious_silver + status_reputation_display | 0.6 / 0.3 | permanent | standard |
| gold_ring | shiny_precious_gold + status_reputation_display | 0.8 / 0.5 | permanent | fine |
| silver_necklace | shiny_precious_silver + status_fashion_luxury | 0.7 / 0.5 | permanent | fine |
| gold_necklace | shiny_precious_gold + status_fashion_luxury | 0.85 / 0.7 | permanent | luxury |
| gemstone_jewelry | shiny_precious_gems + shiny_precious_gold + status_wealth_precious | 0.9 / 0.7 / 0.8 | permanent | luxury |
| crown | shiny_precious_gold + shiny_precious_gems + status_reputation_title | 1.0 / 0.9 / 0.9 | permanent | luxury |

### Art & Decorations

| Commodity | Dimension(s) | Satisfaction | Type | Tier |
|-----------|--------------|--------------|------|------|
| painting | psychological_entertainment_arts + shiny_decorative_art | 0.7 / 0.6 | permanent | fine |
| portrait | psychological_entertainment_arts + shiny_decorative_art + status_reputation_display | 0.8 / 0.7 / 0.5 | permanent | luxury |
| sculpture | psychological_entertainment_arts + shiny_decorative_art | 0.8 / 0.75 | permanent | luxury |
| statue | psychological_entertainment_arts + shiny_decorative_art + psychological_purpose_religion | 0.85 / 0.8 / 0.4 | permanent | luxury |
| bronze_sculpture | shiny_decorative_art + psychological_entertainment_arts | 0.75 / 0.7 | permanent | fine |
| figurine | touch_furniture_decorative | 0.4 | durable | basic |
| tapestry | touch_furniture_decorative + shiny_decorative_art + exotic_items_textiles | 0.7 / 0.6 / 0.5 | permanent | fine |
| terracotta | touch_furniture_decorative | 0.5 | durable | standard |

### Precious Materials (as owned items)

| Commodity | Dimension(s) | Satisfaction | Type | Tier |
|-----------|--------------|--------------|------|------|
| gold | shiny_precious_gold + status_wealth_precious | 0.8 / 0.7 | permanent | luxury |
| silver | shiny_precious_silver + status_wealth_precious | 0.6 / 0.5 | permanent | fine |
| gemstone | shiny_precious_gems + status_wealth_precious | 0.85 / 0.75 | permanent | luxury |
| gold_item | shiny_precious_gold + status_wealth_precious | 0.75 / 0.6 | permanent | fine |

---

## BOOKS & EDUCATION

| Commodity | Dimension(s) | Satisfaction | Type | Tier |
|-----------|--------------|--------------|------|------|
| book | psychological_education_books + psychological_entertainment_arts | 0.7 / 0.4 | permanent | standard |
| manuscript | psychological_education_books + status_wealth_precious | 0.85 / 0.5 | permanent | luxury |
| paper | raw_material | - | - | - |
| fine_paper | raw_material | - | - | - |
| ink | raw_material | - | - | - |

---

## TEXTILES (Intermediate goods - mostly raw materials)

| Commodity | Type | Notes |
|-----------|------|-------|
| cloth | raw_material | For clothing production |
| red_cloth | raw_material | Dyed textile |
| blue_cloth | raw_material | Dyed textile |
| yellow_cloth | raw_material | Dyed textile |
| green_cloth | raw_material | Dyed textile |
| purple_cloth | raw_material | Luxury dyed textile |
| black_cloth | raw_material | Dyed textile |
| orange_cloth | raw_material | Dyed textile |
| linen | raw_material | Fine textile |
| dyed_linen | raw_material | Colored fine textile |
| embroidered_linen | exotic_items_textiles (if owned) | 0.6 | Luxury decorative |
| silk | exotic_items_textiles + status_fashion_luxury | 0.8 / 0.6 | Luxury material |
| wool | raw_material | For clothing/textiles |
| cotton | raw_material | For textiles |
| thread | raw_material | Sewing material |
| yarn | raw_material | Knitting material |

---

## CONSTRUCTION MATERIALS (No direct fulfillment)

All construction materials are used for building and don't directly satisfy citizen cravings:

| Commodity | Type |
|-----------|------|
| timber | raw_material |
| planks | raw_material |
| lumber | raw_material |
| wood | raw_material |
| stone | raw_material |
| cut_stone | raw_material |
| bricks | raw_material |
| tiles | raw_material |
| cement | raw_material |
| mortar | raw_material |
| concrete | raw_material |
| plaster | raw_material |
| stucco | raw_material |
| quickite | raw_material |
| limestone | raw_material |
| sand | raw_material |
| clay | raw_material |
| glass | raw_material |
| window_pane | raw_material |
| clay_pipe | raw_material |
| column | raw_material |
| gravestone | raw_material |

**Note:** These materials are consumed during building construction. The building itself (housing) provides `safety_shelter_housing`.

---

## METALS & ORES (No direct fulfillment)

| Commodity | Type |
|-----------|------|
| iron | raw_material |
| iron_ore | raw_material |
| steel | raw_material |
| copper | raw_material |
| copper_ore | raw_material |
| bronze | raw_material |
| gold_ore | raw_material |
| silver_ore | raw_material |
| coal | raw_material |

---

## SEEDS & SAPLINGS (No direct fulfillment)

All seeds and saplings are planting materials for agriculture:

| Category | Items |
|----------|-------|
| Grain Seeds | wheat_seed, rice_seed, barley_seeds, oats_seeds, rye_seeds, maize_seed, ragi_seeds |
| Vegetable Seeds | potato_seed, carrot_seed, tomato_seed, lettuce_seed, bean_seed, cabbage_seed, broccoli_seed, onion_seed, pumpkin_seed, vegetable_seed, pepper_seed |
| Fruit Seeds/Saplings | fruit_seed, apple_sapling, mango_sapling, orange_sapling, peach_sapling, pear_sapling, grape_vine, date_palm_sapling, coconut_palm_sapling, watermelon_seed, berry_bush |
| Other Seeds | cotton_seed, flax_seed, flower_seed, indigo_seed, herb_seed, mustard_seed, sesame_seed, groundnut_seed, sunflower_seed, sugarcane_cutting, lentil_seed, rubber_tree_sapling |

---

## ANIMAL & BYPRODUCTS

| Commodity | Type | Notes |
|-----------|------|-------|
| hen | raw_material | Egg production |
| sheep | raw_material | Wool production |
| bee_colony | raw_material | Honey production |
| feathers | raw_material | Pillow/decoration material |
| beeswax | raw_material | Candle making |
| raw_hide | raw_material | Leather production |
| tanned_leather | raw_material | Quality leather |
| leather | raw_material | For goods production |
| tallow | raw_material | Candle/soap making |
| lye | raw_material | Soap making |
| latex | raw_material | Rubber production |
| rubber | raw_material | Manufacturing |
| wood_pulp | raw_material | Paper production |
| sawdust | raw_material | Byproduct |
| molasses | raw_material | Rum production |
| feed | raw_material | Animal food |

---

## DYES (No direct fulfillment)

All dyes are production materials:

| Commodity | Type |
|-----------|------|
| red_dye | raw_material |
| blue_dye | raw_material |
| yellow_dye | raw_material |
| black_dye | raw_material |
| green_dye | raw_material |
| purple_dye | raw_material |
| orange_dye | raw_material |
| indigo | raw_material |
| flowers | raw_material |

---

## SPECIAL COMMODITIES

### Currency
| Commodity | Type | Notes |
|-----------|------|-------|
| currency_note | (currency) | Medium of exchange |

### Trees
| Commodity | Type | Notes |
|-----------|------|-------|
| tree | raw_material | For forestry |

### Oil
| Commodity | Dimension(s) | Satisfaction | Type | Tier |
|-----------|--------------|--------------|------|------|
| oil | raw_material (cooking) | N/A | raw_material | - |

**Note:** Cooking oil is a production ingredient, not directly consumed.

---

## MISSING COMMODITIES - RECOMMENDATIONS

Based on the craving system, these commodities should be added:

### Essential
1. **water** - Basic hydration (CRITICAL)
2. **tea** - Stimulation + hydration + social
3. **lamp** - Lighting furniture piece

### Important
4. **fish** - Protein alternative
5. **incense** - Religious/spiritual satisfaction
6. **musical_instrument** - Entertainment
7. **toys** - Child entertainment
8. **towel** - Hygiene

### Nice to Have
9. **coffee** - Stimulation
10. **games/dice** - Entertainment/games
11. **prayer_beads** - Religious

---

## CONSUMPTION MECHANICS SUMMARY

### Daily Consumables
- Food: 3 meals/day across grain, protein, produce dimensions
- Water: 2L/day (biological_hydration)
- Light: 1 candle/evening (enables evening activities)

### Weekly/Monthly
- Soap: ~1 bar/month
- Alcohol: Optional, 2-3 drinks/week for those with vice cravings
- Perfume: 1 bottle/month for those with luxury cravings

### Durables (Ownership-based)
- Clothing: Checked daily, replaced when worn
- Furniture: Provides ongoing satisfaction while owned
- Tools: Work efficiency bonuses

### Permanent (Wealth accumulation)
- Jewelry, Art, Books: Owned indefinitely, provide ongoing status satisfaction

### Triggered
- Medicine: Only when sick
- Healing salve: Only when injured
- Winter coat: Only in cold weather

---

## QUALITY TIER MODIFIERS

Apply these multipliers to base satisfaction:

| Tier | Multiplier | Examples |
|------|------------|----------|
| Basic | 0.7x | Simple clothes, roti, dal |
| Standard | 1.0x | Bread, normal meals, chairs |
| Fine | 1.3x | Fine clothes, biryani, wine |
| Luxury | 1.6x | Ceremonial robes, crown, whiskey |

---

## IMPLEMENTATION NOTES

1. **Prioritize Essential Needs**: Hunger, hydration, and shelter should be weighted heavily
2. **Tier System**: Quality tiers allow same commodity type to satisfy different wealth levels
3. **Triggered Events**: Some consumptions only happen under conditions (illness, weather)
4. **Lighting Dependency**: Evening cravings require lighting to be satisfiable
5. **Social Multipliers**: Some commodities provide bonus satisfaction when consumed socially
6. **Work Tool Integration**: Tools don't satisfy cravings directly but improve work output

---

*Document Version: 2.0*
*For: Cravetown Consumption/Craving System Implementation*
