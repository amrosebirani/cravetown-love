// Shared constants for the Information System
import { loadWorkCategories } from './api';

// Cache for work categories
let cachedWorkCategories: string[] | null = null;

/**
 * Load work categories from JSON file
 * Uses caching to avoid repeated API calls
 */
export async function getWorkCategories(): Promise<string[]> {
  if (cachedWorkCategories) {
    return cachedWorkCategories;
  }

  try {
    const data = await loadWorkCategories();
    cachedWorkCategories = data.workCategories.map(cat => cat.name);
    return cachedWorkCategories;
  } catch (error) {
    console.error('Failed to load work categories, using fallback:', error);
    // Fallback to basic categories if loading fails
    cachedWorkCategories = [
      'Agriculture',
      'Food Production',
      'Manufacturing',
      'Resource Extraction',
      'General Labor'
    ];
    return cachedWorkCategories;
  }
}

/**
 * Clear the work categories cache
 * Call this when work categories are updated
 */
export function clearWorkCategoriesCache() {
  cachedWorkCategories = null;
}

// Legacy static export for backwards compatibility
// Components should gradually migrate to use getWorkCategories()
export const WORK_CATEGORIES = [
  'Agriculture',
  'Animal Husbandry',
  'Food Preparation',
  'Baking',
  'Brewing & Distilling',
  'Woodworking',
  'Lumber Processing',
  'Forestry',
  'Mining',
  'Metalworking',
  'Blacksmithing',
  'Smelting',
  'Jewelry Crafting',
  'Textile Weaving',
  'Spinning',
  'Tailoring',
  'Footwear Manufacturing',
  'Masonry',
  'Brick Making',
  'Glassblowing',
  'Healthcare',
  'Nursing',
  'Education',
  'Philosophy',
  'Commerce',
  'Banking & Finance',
  'Hospitality',
  'General Labor',
  'Artisan Crafts'
] as const;

export type WorkCategory = typeof WORK_CATEGORIES[number];

// ============================================================================
// FULFILLMENT VECTOR TEMPLATES
// ============================================================================

export interface VectorTemplate {
  fine: Record<string, number>;
  tags: string[];
  durability: string;
  notes?: string;
}

// Category-based fulfillment templates
export const FULFILLMENT_TEMPLATES: Record<string, VectorTemplate> = {
  // FOOD - Grains
  grain: {
    fine: {
      biological_nutrition_grain: 12,
      biological_nutrition_protein: 1,
      biological_energy_stimulation: 0.5,
    },
    tags: ['grain', 'nutrition', 'basic_food', 'raw_material'],
    durability: 'consumable',
    notes: 'Basic grain - staple food',
  },

  // FOOD - Processed grain products
  processed_food: {
    fine: {
      biological_nutrition_grain: 15,
      biological_nutrition_protein: 2,
      touch_sensory_luxury: 3,
      comfort_warmth_shelter: 2,
    },
    tags: ['processed_food', 'comfort', 'nutrition'],
    durability: 'consumable',
    notes: 'Processed food items like bread, pastries',
  },

  // FOOD - Fruits
  fruit: {
    fine: {
      biological_nutrition_produce: 12,
      biological_hydration: 5,
      touch_sensory_luxury: 4,
      biological_health_hygiene: 1,
    },
    tags: ['fruit', 'produce', 'nutrition', 'fresh'],
    durability: 'consumable',
    notes: 'Fresh fruits',
  },

  // FOOD - Vegetables
  vegetable: {
    fine: {
      biological_nutrition_produce: 15,
      biological_health_hygiene: 2,
      biological_hydration: 3,
    },
    tags: ['vegetable', 'produce', 'nutrition', 'fresh'],
    durability: 'consumable',
    notes: 'Fresh vegetables',
  },

  // FOOD - Animal products (meat, dairy)
  animal_product: {
    fine: {
      biological_nutrition_protein: 20,
      biological_nutrition_grain: 2,
      touch_sensory_luxury: 3,
    },
    tags: ['protein', 'nutrition', 'animal_product'],
    durability: 'consumable',
    notes: 'Meat, dairy, eggs',
  },

  // BEVERAGES - Alcohol
  alcohol: {
    fine: {
      biological_nutrition_grain: 4,
      biological_hydration: 5,
      touch_sensory_luxury: 3,
      psychological_entertainment_games: 8,
      social_friendship_casual: 12,
      vice_alcohol_beer: 20,
    },
    tags: ['alcohol', 'social', 'indulgence', 'beverages'],
    durability: 'consumable',
    notes: 'Beer, wine, spirits',
  },

  // CLOTHING - Basic
  clothing_basic: {
    fine: {
      biological_health_hygiene: 5,
      comfort_warmth_shelter: 12,
      comfort_safety_protection: 8,
      social_status_recognition: 2,
    },
    tags: ['clothing', 'basic', 'protection', 'necessity'],
    durability: 'durable',
    notes: 'Simple clothes, work clothes',
  },

  // CLOTHING - Fine/Luxury
  clothing_luxury: {
    fine: {
      biological_health_hygiene: 5,
      comfort_warmth_shelter: 10,
      comfort_safety_protection: 6,
      social_status_recognition: 15,
      touch_sensory_luxury: 12,
      aspirational_beauty_aesthetics: 10,
    },
    tags: ['clothing', 'luxury', 'status', 'fashion'],
    durability: 'durable',
    notes: 'Fine clothes, luxury garments',
  },

  // FURNITURE
  furniture: {
    fine: {
      comfort_warmth_shelter: 10,
      comfort_rest_relaxation: 12,
      aspirational_beauty_aesthetics: 8,
      social_status_recognition: 5,
    },
    tags: ['furniture', 'comfort', 'home'],
    durability: 'permanent',
    notes: 'Chairs, tables, beds, cabinets',
  },

  // TOOLS
  tools: {
    fine: {
      comfort_safety_protection: 5,
      aspirational_achievement_purpose: 8,
      aspirational_growth_knowledge: 3,
    },
    tags: ['tools', 'production', 'utility'],
    durability: 'durable',
    notes: 'Work tools, crafting implements',
  },

  // LUXURY ITEMS - Art, jewelry
  luxury: {
    fine: {
      touch_sensory_luxury: 15,
      aspirational_beauty_aesthetics: 20,
      social_status_recognition: 18,
      aspirational_achievement_purpose: 8,
      psychological_entertainment_games: 5,
    },
    tags: ['luxury', 'art', 'status', 'wealth'],
    durability: 'permanent',
    notes: 'Jewelry, paintings, sculptures',
  },

  // TEXTILES - Raw materials
  textile_raw: {
    fine: {},
    tags: ['textile', 'raw_material', 'crafting'],
    durability: 'durable',
    notes: 'Cotton, wool, flax - used for crafting',
  },

  // TEXTILES - Processed
  textile: {
    fine: {
      touch_sensory_luxury: 5,
      aspirational_beauty_aesthetics: 3,
    },
    tags: ['textile', 'fabric', 'crafting'],
    durability: 'durable',
    notes: 'Cloth, linen, silk',
  },

  // CONSTRUCTION MATERIALS
  construction: {
    fine: {},
    tags: ['construction', 'building', 'raw_material'],
    durability: 'permanent',
    notes: 'Bricks, planks, cement - used for building',
  },

  // RAW MINERALS
  raw_mineral: {
    fine: {},
    tags: ['mineral', 'raw_material', 'mining'],
    durability: 'permanent',
    notes: 'Stone, ore, clay - raw materials',
  },

  // REFINED METALS
  refined_metal: {
    fine: {
      social_status_recognition: 3,
    },
    tags: ['metal', 'refined', 'valuable'],
    durability: 'permanent',
    notes: 'Iron, steel, gold, silver',
  },

  // FUEL
  fuel: {
    fine: {
      comfort_warmth_shelter: 8,
    },
    tags: ['fuel', 'energy', 'utility'],
    durability: 'consumable',
    notes: 'Wood, coal, oil - for heating and cooking',
  },

  // MISC - Medicine
  medicine: {
    fine: {
      biological_health_hygiene: 25,
      biological_rest_sleep: 5,
      comfort_safety_protection: 10,
    },
    tags: ['medicine', 'health', 'healing'],
    durability: 'consumable',
    notes: 'Healing items, remedies',
  },

  // MISC - Hygiene products
  hygiene: {
    fine: {
      biological_health_hygiene: 15,
      touch_sensory_luxury: 5,
      social_status_recognition: 3,
    },
    tags: ['hygiene', 'cleanliness', 'health'],
    durability: 'consumable',
    notes: 'Soap, perfume',
  },

  // DYE
  dye: {
    fine: {
      aspirational_beauty_aesthetics: 8,
      touch_sensory_luxury: 5,
    },
    tags: ['dye', 'color', 'crafting'],
    durability: 'consumable',
    notes: 'Coloring materials for textiles',
  },

  // CRAFTING MATERIALS
  crafting: {
    fine: {},
    tags: ['crafting', 'material', 'production'],
    durability: 'consumable',
    notes: 'Paper, nails, etc',
  },

  // SEEDS
  seed: {
    fine: {},
    tags: ['seed', 'agriculture', 'farming'],
    durability: 'consumable',
    notes: 'Seeds for planting',
  },

  // SPECIAL BERRIES
  special_berry: {
    fine: {
      biological_nutrition_produce: 8,
      biological_health_hygiene: 15,
      touch_sensory_luxury: 10,
      psychological_spirituality_purpose: 5,
    },
    tags: ['berry', 'special', 'rare', 'medicinal'],
    durability: 'consumable',
    notes: 'Rare berries with special properties',
  },

  // PLANT PRODUCTS
  plant: {
    fine: {
      aspirational_beauty_aesthetics: 5,
      touch_sensory_luxury: 3,
    },
    tags: ['plant', 'decorative', 'raw_material'],
    durability: 'consumable',
    notes: 'Flowers, decorative plants',
  },
};

// Quality multiplier presets
export const QUALITY_MULTIPLIERS = {
  basic_food: {
    poor: 0.6,
    basic: 1.0,
    good: 1.3,
    luxury: 1.6,
    masterwork: 2.0,
  },
  luxury_food: {
    poor: 0.5,
    basic: 1.0,
    good: 1.5,
    luxury: 2.2,
    masterwork: 3.0,
  },
  clothing: {
    poor: 0.5,
    basic: 1.0,
    good: 1.4,
    luxury: 2.0,
    masterwork: 2.8,
  },
  furniture: {
    poor: 0.6,
    basic: 1.0,
    good: 1.3,
    luxury: 1.8,
    masterwork: 2.5,
  },
  luxury_goods: {
    poor: 0.4,
    basic: 1.0,
    good: 1.6,
    luxury: 2.5,
    masterwork: 4.0,
  },
  tools: {
    poor: 0.7,
    basic: 1.0,
    good: 1.2,
    luxury: 1.4,
    masterwork: 1.6,
  },
  raw_materials: {
    poor: 0.8,
    basic: 1.0,
    good: 1.1,
    luxury: 1.2,
    masterwork: 1.3,
  },
};
