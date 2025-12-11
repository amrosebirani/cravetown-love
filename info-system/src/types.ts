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
  workers?: WorkerRequirements;  // Made optional for backwards compatibility
  inputCostPrice?: Record<string, number>;
  outputSellingPrice?: Record<string, number>;
  accelerationClause?: string;
  additionalLogic?: string;
  notes: string;
}

export interface BuildingRecipesData {
  recipes: BuildingRecipe[];
}

export interface CommodityCategory {
  id: string;
  name: string;
  description?: string;
  tags: string[];
  color: string;
}

export interface CommodityCategoriesData {
  version: string;
  categories: CommodityCategory[];
}

export type QualityTier = 'poor' | 'basic' | 'good' | 'luxury' | 'masterwork';

export interface Commodity {
  id: string;
  name: string;
  category: string;
  description?: string;
  quality?: QualityTier;  // Default quality tier for this commodity
  icon?: string;
  stackSize?: number;
  baseValue?: number;
  isRaw?: boolean;
  perishable?: boolean;
}

// Quality Tier Definition Types
export interface QualityTierDefinition {
  id: string;
  name: string;
  description: string;
  order: number;
  defaultMultiplier: number;
  valueMultiplier: number;
  color: [number, number, number];
}

export interface QualityTiersData {
  version: string;
  description?: string;
  tiers: QualityTierDefinition[];
  defaultTier: string;
  productionRules?: {
    description: string;
    factors: Record<string, { description: string; weight: number }>;
    upgradeChance?: { description: string; baseChance: number; skillBonus: number };
    degradeChance?: { description: string; baseChance: number; penaltyForLowMaintenance: number };
  };
  classAcceptance?: Record<string, { accepted: string[]; rejected: string[] }>;
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

export interface BuildingUpgradeLevel {
  level: number;
  name: string;
  description: string;
  stations: number;  // Number of work stations (= max workers)
  width: number;
  height: number;
  constructionMaterials?: Record<string, number>;  // For level 0
  upgradeMaterials?: Record<string, number>;  // For levels > 0
  storage: {
    inputCapacity: number;
    outputCapacity: number;
  };
}

export interface BuildingType {
  id: string;
  name: string;
  category: string;
  label: string;  // 2-letter abbreviation
  color: [number, number, number];  // RGB color array [0-1, 0-1, 0-1]
  description?: string;
  workCategories?: string[];  // Categories of workers that can work here
  workerEfficiency?: Record<string, number>;  // Efficiency multiplier per work category (0.0 to 1.0)
  upgradeLevels: BuildingUpgradeLevel[];  // Array of upgrade levels (0, 1, 2, ...)
  placementConstraints?: PlacementConstraints;  // Natural resource constraints for placement

  // Legacy fields (for backwards compatibility during migration)
  baseWidth?: number;
  baseHeight?: number;
  variableSize?: boolean;
  minWidth?: number;
  minHeight?: number;
  maxWidth?: number;
  maxHeight?: number;
  properties?: Record<string, any>;
  constructionMaterials?: Record<string, number>;
  storage?: {
    inputCapacity: number;
    outputCapacity: number;
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
  durationCycles?: number | null;  // How many cycles before expiry (null for consumable/permanent)
  effectDecayRate?: number;        // Effectiveness loss per cycle (0 = no decay)
  notes?: string;
}

export interface FulfillmentVectorsData {
  version: string;
  note?: string;
  commodities: Record<string, CommodityFulfillment>;
}

// Version/Mod Management Types

export interface GameVersion {
  id: string;
  name: string;
  description: string;
  author: string;
  version: string;
  active: boolean;
  createdDate: string;
  lastModified: string;
  dataPath: string;
  thumbnail?: string | null;
  tags?: string[];
  parentVersion?: string;  // For cloned versions
}

export interface VersionsManifest {
  versions: GameVersion[];
  activeVersion: string;
  metadata: {
    formatVersion: string;
    lastUpdated: string;
  };
}

// Commodity Fatigue Rate Types

export interface CommodityFatigueRate {
  baseFatigueRate: number;
  fatigueModifiers: Record<string, number>;
}

export interface CommodityFatigueRatesData {
  version: string;
  description: string;
  defaultFatigueRate: number;
  defaultRecoveryRate: number;
  commodities: Record<string, CommodityFatigueRate>;
  categoryDefaults: Record<string, number>;
}

// Substitution Rules Types

export interface SubstituteRule {
  commodity: string;
  efficiency: number;
  distance: number;
}

export interface CommoditySubstitution {
  substitutes: SubstituteRule[];
}

export interface SubstitutionRulesData {
  version: string;
  description: string;
  substitutionHierarchies: Record<string, Record<string, CommoditySubstitution>>;
  desperationRules: {
    enabled: boolean;
    desperationThreshold: number;
    desperationSubstitutes: Record<string, SubstituteRule[]>;
  };
}

// ============================================================================
// Natural Resources Types
// ============================================================================

export type ResourceCategory = 'continuous' | 'discrete';
export type DistributionType = 'perlin_hybrid' | 'regional_cluster';
export type EfficiencyFormula = 'weighted_average' | 'direct' | 'minimum';

export interface PerlinDistribution {
  type: 'perlin_hybrid';
  perlinWeight: number;
  hotspotWeight: number;
  frequency: number;
  octaves: number;
  persistence: number;
  hotspotCount: [number, number];
  hotspotRadius: [number, number];
  hotspotIntensity: [number, number];
}

export interface ClusterDistribution {
  type: 'regional_cluster';
  depositCount: [number, number];
  depositRadius: [number, number];
  centerRichness: [number, number];
  falloffExponent: number;
  noiseVariation: number;
}

export interface RiverInfluence {
  enabled: boolean;
  range: number;
  boost: number;
}

export interface CollisionRules {
  riverDistance: number;
  sameTypeDistance: number;
  boundaryBuffer: number;
}

export interface ResourceVisualization {
  color: [number, number, number];
  opacity: number;
  showThreshold: number;
}

export interface NaturalResource {
  id: string;
  name: string;
  category: ResourceCategory;
  description?: string;
  distribution: PerlinDistribution | ClusterDistribution;
  riverInfluence?: RiverInfluence;
  collisionRules?: CollisionRules;
  visualization: ResourceVisualization;
}

export interface NaturalResourcesData {
  version: string;
  naturalResources: NaturalResource[];
}

// ============================================================================
// Building Placement Constraints Types
// ============================================================================

export interface ResourceRequirement {
  resourceId: string;
  weight: number;
  minValue: number;
  displayName: string;
  anyOf?: string[];  // For "any ore" type requirements (e.g., mine can use any ore)
}

export interface PlacementConstraints {
  enabled: boolean;
  requiredResources?: ResourceRequirement[];
  efficiencyFormula?: EfficiencyFormula;
  warningThreshold?: number;
  blockingThreshold?: number;
}

// ============================================================================
// Time Slots Types
// ============================================================================

export interface TimeSlot {
  id: string;
  name: string;
  startHour: number;
  endHour: number;
  description: string;
  color: [number, number, number];  // RGB [0-1, 0-1, 0-1]
}

export interface TimeSlotsData {
  version: string;
  slots: TimeSlot[];
}

// ============================================================================
// Craving Slots (Craving-to-Slot Mapping) Types
// ============================================================================

export interface CravingSlotMapping {
  slots: string[];  // Array of slot IDs
  frequencyPerDay: number;
  description?: string;
}

export interface SlotModifier {
  additionalSlots?: string[];
  removeSlots?: string[];
  description?: string;
}

export interface CravingSlotsData {
  version: string;
  description?: string;
  mappings: Record<string, CravingSlotMapping>;  // keyed by fine dimension id
  classModifiers: Record<string, Record<string, SlotModifier>>;  // class id -> dimension id -> modifier
  traitModifiers: Record<string, Record<string, SlotModifier>>;  // trait id -> dimension id -> modifier
  durableSlots?: {
    description: string;
    categorySlots: Record<string, string>;  // durable category -> slot id for daily application
  };
}

// ============================================================================
// Units System Types
// ============================================================================

export interface BaseUnitType {
  base: string;
  display: string[];
  conversions?: Record<string, number>;
}

export interface PersonDayBaseline {
  calories: number;
  waterLiters: number;
  sleepHours: number;
  description?: string;
}

export interface CommodityUnit {
  unit: string;
  caloriesPerUnit?: number;
  weightKg?: number;
  volumeLiters?: number;
  dailyNeedAmount?: number;
  durationType?: 'consumable' | 'durable' | 'permanent';
  durationDays?: number;
  description?: string;
  [key: string]: any;  // Allow additional fields
}

export interface UnitsData {
  version: string;
  description?: string;
  baseUnits: Record<string, BaseUnitType>;
  personDayBaseline: PersonDayBaseline;
  commodityUnits: Record<string, CommodityUnit>;
  displayFormats?: Record<string, string>;
}

// ============================================================================
// Starting Locations Types
// ============================================================================

export interface MountainPosition {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface OasisPosition {
  x: number;
  y: number;
}

export interface LocationTerrain {
  riverEnabled: boolean;
  riverWidth: number;
  riverPosition: 'none' | 'center' | 'east' | 'west';
  forestDensity: number;  // 0.0 to 1.0
  mountainsEnabled: boolean;
  mountainCount: number;
  mountainPositions: MountainPosition[];
  oasisEnabled?: boolean;
  oasisPosition?: OasisPosition;
  oasisRadius?: number;
  groundColor: [number, number, number];  // RGB [0-1, 0-1, 0-1]
  waterColor: [number, number, number];  // RGB [0-1, 0-1, 0-1]
}

export interface StarterBuilding {
  typeId: string;
  x: number;
  y: number;
  autoAssignRecipe: boolean;
}

export interface StarterResource {
  commodityId: string;
  quantity: number;
}

export interface StarterCitizen {
  classId: string;
  vocationId: string;
  traitIds?: string[];  // Optional array of traits
}

export interface LocationPopulation {
  initialCount: number;
  classDistribution: Record<string, number>;  // class id -> percentage (0-1) - used as fallback
  starterCitizens?: StarterCitizen[];  // Specific citizens to spawn (optional, overrides distribution)
}

export interface StartingLocation {
  id: string;
  name: string;
  icon: string;
  description: string;
  bonus: string;
  challenge: string;
  terrain: LocationTerrain;
  productionModifiers: Record<string, number>;  // category -> multiplier
  starterBuildings: StarterBuilding[];
  starterResources: StarterResource[];
  starterGold: number;
  population: LocationPopulation;
}

export interface StartingLocationsData {
  version: string;
  description?: string;
  locations: StartingLocation[];
}

// ============================================================================
// Phase 7: Ownership & Housing System Types
// ============================================================================

// Emergent Class role for starter citizens (not fixed class)
export type IntendedRole = 'wealthy' | 'merchant' | 'craftsman' | 'laborer';

// Updated StarterCitizen with emergent class support
export interface StarterCitizenV2 {
  name?: string;  // Optional custom name
  vocationId: string;
  traitIds?: string[];
  // Emergent class fields (replaces classId)
  startingWealth: number;  // Gold amount to start with
  intendedRole: IntendedRole;  // Role determines starting wealth defaults
  housingBuildingIndex?: number;  // Index into starterBuildings for housing assignment
  // Legacy support
  classId?: string;  // Deprecated, kept for backwards compatibility
}

// Updated StarterBuilding with ownership and housing support
export interface StarterBuildingV2 {
  typeId: string;
  x: number;
  y: number;
  autoAssignRecipe: boolean;
  // Ownership fields
  ownerCitizenIndex?: number;  // null/undefined = town-owned, number = citizen index
  // Housing fields
  initialOccupants?: number[];  // Citizen indices for housing buildings
  rentRate?: number;  // Override default rent rate
}

// Land plot for starter locations
export interface StarterLandPlot {
  gridX: number;
  gridY: number;
  ownerCitizenIndex?: number;  // null/undefined = town-owned
  purchasePrice?: number;  // Override auto-calculated price
}

// Economic system type
export type EconomicSystemType = 'capitalist' | 'collectivist' | 'feudal';

// Updated StartingLocation with land and economy support
export interface StartingLocationV2 extends StartingLocation {
  // New fields
  starterLandPlots?: StarterLandPlot[];
  economicSystem?: EconomicSystemType;
  startingTreasury?: number;  // Override default starting gold
  // V2 buildings and citizens (with ownership support)
  starterBuildingsV2?: StarterBuildingV2[];
  starterCitizensV2?: StarterCitizenV2[];
}

// ============================================================================
// Land System Types
// ============================================================================

export interface LandGridSettings {
  plotWidth: number;
  plotHeight: number;
  worldWidth?: number;
  worldHeight?: number;
}

export interface LandPricing {
  basePlotPrice: number;
  locationMultipliers: Record<string, number>;  // center, edge, river-adjacent, etc.
  terrainMultipliers: Record<string, number>;  // fertile, rocky, etc.
}

export interface LandImmigrationRequirement {
  minPlots: number;
  maxPlots: number;
  description?: string;
}

export interface LandOverlayColors {
  townOwned: string;
  citizenOwned: string;
  forSale: string;
  gridLines: string;
  gridLinesOpacity?: number;
}

export interface LandConfig {
  version: string;
  gridSettings: LandGridSettings;
  pricing: LandPricing;
  immigrationRequirements: Record<IntendedRole, LandImmigrationRequirement>;
  overlayColors: LandOverlayColors;
}

// ============================================================================
// Class Thresholds Types (Emergent Class System)
// ============================================================================

export interface NetWorthThreshold {
  min?: number;
  max?: number;
}

export interface ClassThresholds {
  version: string;
  description?: string;
  netWorthThresholds: {
    elite: NetWorthThreshold;
    upper: NetWorthThreshold;
    middle: NetWorthThreshold;
    lower: NetWorthThreshold;
  };
  capitalRatioThresholds: {
    elite: number;  // Min capital ratio to be elite
    upper: number;  // Min capital ratio to be upper
    middle: number;  // Min capital ratio to be middle
  };
  skillIncomeThresholds?: {
    elite: number;
    upper: number;
    middle: number;
  };
}

// ============================================================================
// Economic System Configuration Types
// ============================================================================

export interface CapitalistConfig {
  privateOwnershipEnabled: boolean;
  profitDistribution: {
    owner: number;  // Percentage to owner
    workers: number;  // Percentage to workers
    treasury: number;  // Percentage to town treasury (tax)
  };
  taxRates: {
    income: number;  // Income tax rate
    property: number;  // Property/land tax rate
    trade: number;  // Sales/trade tax rate
  };
}

export interface CollectivistConfig {
  stateOwnershipPercentage: number;  // % of buildings town-owned
  resourceDistribution: 'equal' | 'need_based' | 'contribution_based';
  collectiveBuildingOwnership: boolean;
  maxPrivateWealth?: number;
}

export interface FeudalConfig {
  lordVassalEnabled: boolean;
  tributePercentage: number;  // % of production to lord
  tithesEnabled: boolean;
  tithePercentage: number;  // % to religious institutions
  nobleLandAllocation: {
    minPlotsPerNoble: number;
    serfsPerPlot: number;
  };
}

export interface EconomicSystemConfig {
  version: string;
  defaultSystem: EconomicSystemType;
  systems: {
    capitalist: CapitalistConfig;
    collectivist: CollectivistConfig;
    feudal: FeudalConfig;
  };
}

// ============================================================================
// Housing Configuration Types
// ============================================================================

export interface HousingConfig {
  capacity: number;  // Max occupants
  unitsCount?: number;  // Number of separate units (for apartments/tenements)
  housingQuality: number;  // 0.0 to 1.0
  qualityTier: QualityTier;
  rentPerOccupant: number;  // Gold per cycle
  targetClasses: string[];  // Ideal classes for this housing
  acceptableClasses?: string[];  // Classes that can live here (broader)
  upgradeableTo?: string;  // Building type ID for upgrade path
  upgradeCost?: {
    materials: Record<string, number>;
    gold: number;
    cycles: number;
  };
}

// Extended BuildingType with housing support
export interface BuildingTypeWithHousing extends BuildingType {
  housingConfig?: HousingConfig;
  fulfillmentVector?: {
    coarse: number[];
    fine: Record<string, number>;
  };
}

// ============================================================================
// Building Fulfillment Vectors Types
// ============================================================================

export interface BuildingFulfillment {
  id: string;
  fulfillmentVector: {
    coarse: number[];
    fine: Record<string, number>;
  };
  tags: string[];
  qualityMultipliers: Record<string, number>;
  notes?: string;
}

export interface BuildingFulfillmentVectorsData {
  version: string;
  buildings: Record<string, BuildingFulfillment>;
}

// Extended FulfillmentVectorsData with buildings
export interface FulfillmentVectorsDataV2 extends FulfillmentVectorsData {
  buildings?: Record<string, BuildingFulfillment>;
}

// ============================================================================
// Relationship Types
// ============================================================================

export type RelationshipType =
  | 'spouse' | 'parent' | 'child' | 'sibling'
  | 'employer' | 'employee'
  | 'landlord' | 'tenant'
  | 'business_partner'
  | 'friend' | 'rival'
  | 'colleague' | 'neighbour';

export interface RelationshipTypeConfig {
  id: RelationshipType;
  name: string;
  description: string;
  bidirectional: boolean;  // true = both parties have same relationship
  inverseType?: RelationshipType;  // For non-bidirectional (e.g., parent -> child)
  satisfactionBonus: number;  // Bonus to satisfaction when relationship active
  autoCreateRules?: {
    sameWorkplace?: boolean;  // Auto-create colleague
    adjacentPlot?: boolean;  // Auto-create neighbour
    sameHousing?: boolean;  // Auto-create for roommates
  };
}

export interface RelationshipTypesData {
  version: string;
  relationships: RelationshipTypeConfig[];
}

// ============================================================================
// Immigration Configuration Types
// ============================================================================

export interface RoleImmigrationConfig {
  landRequired: number;  // Plots required (0 = can rent)
  minWealth: number;  // Minimum starting wealth
  housingRequired: boolean;  // Must have housing available
  minHousingQuality?: number;  // Min housing quality (0.0-1.0)
  familySize?: {
    min: number;
    max: number;
  };
}

export interface ImmigrationConfigData {
  version: string;
  roleRequirements: Record<IntendedRole, RoleImmigrationConfig>;
  queueSettings: {
    maxQueueSize: number;
    maxWaitCycles: number;  // Cycles before leaving queue
    processingRate: number;  // Max immigrants per cycle
  };
  attractionFactors: {
    housingAvailability: number;  // Weight
    averageSatisfaction: number;  // Weight
    jobAvailability: number;  // Weight
    wealthOpportunity: number;  // Weight
  };
}

// ============================================================================
// Pre-Computed Commodity Cache Types
// ============================================================================

export interface CommodityCacheEntry {
  id: string;
  value: number;
}

export interface DimensionCache {
  available: CommodityCacheEntry[];
  sortedByValue: string[];  // Just commodity IDs, pre-sorted by value descending
}

export interface SubstitutionGroupCache {
  members: string[];
  available: string[];
}

export interface PreComputedCommodityCache {
  version: string;
  generatedAt: string;
  sourceDataHashes: {
    fulfillmentVectors: string;
    dimensionDefinitions: string;
    substitutionRules: string;
  };
  byCoarseDimension: Record<string, DimensionCache>;
  byFineDimension: Record<string, DimensionCache>;
  substitutionGroups: Record<string, SubstitutionGroupCache>;
  metadata: {
    coarseCacheCount: number;
    fineCacheCount: number;
    substitutionGroupCount: number;
    totalCommodities: number;
  };
}
