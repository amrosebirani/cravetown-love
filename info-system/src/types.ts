export interface WorkerRequirements {
  required: number;
  max: number;
  vocations: string[];
  efficiencyBonus: number;
  wages?: number;
}

export interface BuildingRecipe {
  buildingType: string;
  name: string;
  recipeName: string;
  category: string;
  productionTime: number;
  inputs: Record<string, number>;
  outputs: Record<string, number>;
  workers: WorkerRequirements;
  inputCostPrice?: Record<string, number>;
  outputSellingPrice?: Record<string, number>;
  accelerationClause?: string;
  additionalLogic?: string;
  notes: string;
}

export interface BuildingRecipesData {
  recipes: BuildingRecipe[];
}

export interface Commodity {
  id: string;
  name: string;
  category: string;
  description?: string;
}

export interface CommoditiesData {
  commodities: Commodity[];
}

export interface WorkerType {
  id: string;
  name: string;
  category: string;
  minimumWage: number;
  skillLevel: string;
  description?: string;
  workCategories?: string[];  // Categories of work this worker can do
}

export interface WorkerTypesData {
  workerTypes: WorkerType[];
}

export interface BuildingType {
  id: string;
  name: string;
  category: string;
  label: string;  // 2-letter abbreviation
  color: [number, number, number];  // RGB color array [0-1, 0-1, 0-1]
  baseWidth: number;
  baseHeight: number;
  variableSize?: boolean;
  minWidth?: number;
  minHeight?: number;
  maxWidth?: number;
  maxHeight?: number;
  description?: string;
  workCategories?: string[];  // Categories of workers that can work here
  workerEfficiency?: Record<string, number>;  // Efficiency multiplier per work category (0.0 to 1.0)
  properties?: Record<string, any>;  // Building-specific properties
  constructionMaterials?: Record<string, number>;  // Materials needed to construct
}

export interface BuildingTypesData {
  buildingTypes: BuildingType[];
}

export interface WorkCategory {
  id: string;
  name: string;
  description?: string;
}

export interface WorkCategoriesData {
  workCategories: WorkCategory[];
}
