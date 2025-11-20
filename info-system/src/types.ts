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
}

export interface WorkerTypesData {
  workerTypes: WorkerType[];
}
