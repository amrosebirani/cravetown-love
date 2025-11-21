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
