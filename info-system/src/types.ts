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
  storage?: {
    inputCapacity: number;    // Max units of input materials that can be stored
    outputCapacity: number;   // Max units of output products that can be stored
  };
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

// Craving System Types

export interface CoarseDimension {
  id: string;
  index: number;
  name: string;
  description: string;
  tier: string;
  criticalThreshold: number;
  emigrationWeight: number;
  productivityImpact: number;
  decayRate?: number;
}

export interface FineDimension {
  id: string;
  index: number;
  parentCoarse: string;
  name: string;
  tags: string[];
  aggregationWeight: number;
  decayRate?: number;
}

export interface DimensionDefinitions {
  version: string;
  dimensionCount: {
    coarse: number;
    fine: number;
  };
  coarseDimensions: CoarseDimension[];
  fineDimensions: FineDimension[];
  metadata: {
    lastUpdated: string;
    changeLog: Array<{
      version: string;
      date: string;
      changes: string;
    }>;
    futureExpansion: {
      reservedIndices: {
        coarse: number[];
        fine: number[];
      };
      notes: string;
    };
  };
}

export interface CharacterClass {
  id: string;
  name: string;
  description: string;
  allocationPriority: number;
  baseIncome: number;
  baseCravingVector: {
    coarse: number[];
    fine: number[];
  };
  thresholds: {
    emigration: number;
    riotContribution: number;
    criticalSatisfaction: number;
  };
  acceptedQualityTiers: string[];
  rejectedQualityTiers: string[];
}

export interface CharacterClassesData {
  version: string;
  classes: CharacterClass[];
}

export interface CharacterTrait {
  id: string;
  name: string;
  description: string;
  rarity: string;
  cravingMultipliers: {
    coarse: number[];
    fine: number[];
  };
  specialEffects?: Record<string, any>;
}

export interface CharacterTraitsData {
  version: string;
  traits: CharacterTrait[];
}

export interface EnablementRule {
  id: string;
  name: string;
  description: string;
  trigger: {
    type: string;
    [key: string]: any;
  };
  effect: {
    cravingModifier: {
      coarse: number[];
      fine: number[];
    };
    permanent?: boolean;
  };
}

export interface EnablementRulesData {
  version: string;
  rules: EnablementRule[];
}

export interface CommodityFulfillment {
  id: string;
  fulfillmentVector: {
    coarse: number[];
    fine: Record<string, number>;
  };
  tags: string[];
  durability: string;
  qualityMultipliers: Record<string, number>;
  reusableValue?: number;
  notes?: string;
}

export interface FulfillmentVectorsData {
  version: string;
  note?: string;
  commodities: Record<string, CommodityFulfillment>;
}
