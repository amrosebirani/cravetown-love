import { invoke } from '@tauri-apps/api/core';
import type {
  BuildingRecipesData,
  CommoditiesData,
  CommodityCategoriesData,
  WorkerTypesData,
  BuildingTypesData,
  WorkCategoriesData,
  DimensionDefinitions,
  CharacterClassesData,
  CharacterTraitsData,
  FulfillmentVectorsData,
  EnablementRulesData,
  CommodityFatigueRatesData,
  SubstitutionRulesData,
  VersionsManifest,
  GameVersion,
  NaturalResourcesData,
  TimeSlotsData,
  CravingSlotsData,
  UnitsData,
  StartingLocationsData,
  QualityTiersData,
  // Phase 7 types
  LandConfig,
  ClassThresholds,
  EconomicSystemConfig,
  ImmigrationConfigData,
  RelationshipTypesData,
  FulfillmentVectorsDataV2,
  // Pre-computed cache types
  PreComputedCommodityCache,
  CommodityCacheEntry,
  DimensionCache,
  SubstitutionGroupCache
} from './types';

// Active version state
let activeVersionPath: string | null = null;

/**
 * Get the currently active version path
 */
function getActiveVersionPath(): string {
  return activeVersionPath || 'base';
}

/**
 * Get the path to the data directory
 */
export async function getDataDir(): Promise<string> {
  return await invoke<string>('get_data_dir');
}

/**
 * Read a JSON file from the file system
 */
export async function readJsonFile(filePath: string): Promise<string> {
  return await invoke<string>('read_json_file', { filePath });
}

/**
 * Write a JSON file to the file system
 */
export async function writeJsonFile(filePath: string, content: string): Promise<void> {
  await invoke('write_json_file', { filePath, content });
}

/**
 * Load building recipes from JSON file
 */
export async function loadBuildingRecipes(): Promise<BuildingRecipesData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/building_recipes.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save building recipes to JSON file
 */
export async function saveBuildingRecipes(data: BuildingRecipesData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/building_recipes.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Load commodities from JSON file
 */
export async function loadCommodities(): Promise<CommoditiesData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/commodities.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save commodities to JSON file
 */
export async function saveCommodities(data: CommoditiesData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/commodities.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Load commodity categories from JSON file
 */
export async function loadCommodityCategories(): Promise<CommodityCategoriesData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/commodity_categories.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Load quality tiers from JSON file
 */
export async function loadQualityTiers(): Promise<QualityTiersData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_system/quality_tiers.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save quality tiers to JSON file
 */
export async function saveQualityTiers(data: QualityTiersData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_system/quality_tiers.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Save commodity categories to JSON file
 */
export async function saveCommodityCategories(data: CommodityCategoriesData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/commodity_categories.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Load worker types from JSON file
 */
export async function loadWorkerTypes(): Promise<WorkerTypesData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/worker_types.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save worker types to JSON file
 */
export async function saveWorkerTypes(data: WorkerTypesData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/worker_types.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Load building types from JSON file
 */
export async function loadBuildingTypes(): Promise<BuildingTypesData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/building_types.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save building types to JSON file
 */
export async function saveBuildingTypes(data: BuildingTypesData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/building_types.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Load work categories from JSON file
 */
export async function loadWorkCategories(): Promise<WorkCategoriesData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/work_categories.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save work categories to JSON file
 */
export async function saveWorkCategories(data: WorkCategoriesData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/work_categories.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Load dimension definitions from JSON file
 */
export async function loadDimensionDefinitions(): Promise<DimensionDefinitions> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_system/dimension_definitions.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save dimension definitions to JSON file
 */
export async function saveDimensionDefinitions(data: DimensionDefinitions): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_system/dimension_definitions.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Load character classes from JSON file
 */
export async function loadCharacterClasses(): Promise<CharacterClassesData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_system/character_classes.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save character classes to JSON file
 */
export async function saveCharacterClasses(data: CharacterClassesData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_system/character_classes.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Load character traits from JSON file
 */
export async function loadCharacterTraits(): Promise<CharacterTraitsData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_system/character_traits.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save character traits to JSON file
 */
export async function saveCharacterTraits(data: CharacterTraitsData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_system/character_traits.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Load fulfillment vectors from JSON file
 */
export async function loadFulfillmentVectors(): Promise<FulfillmentVectorsData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_system/fulfillment_vectors.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save fulfillment vectors to JSON file
 */
export async function saveFulfillmentVectors(data: FulfillmentVectorsData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_system/fulfillment_vectors.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Load enablement rules from JSON file
 */
export async function loadEnablementRules(): Promise<EnablementRulesData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_system/enablement_rules.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save enablement rules to JSON file
 */
export async function saveEnablementRules(data: EnablementRulesData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_system/enablement_rules.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Load commodity fatigue rates from JSON file
 */
export async function loadCommodityFatigueRates(): Promise<CommodityFatigueRatesData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_system/commodity_fatigue_rates.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save commodity fatigue rates to JSON file
 */
export async function saveCommodityFatigueRates(data: CommodityFatigueRatesData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_system/commodity_fatigue_rates.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Load substitution rules from JSON file
 */
export async function loadSubstitutionRules(): Promise<SubstitutionRulesData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/substitution_rules.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save substitution rules to JSON file
 */
export async function saveSubstitutionRules(data: SubstitutionRulesData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/substitution_rules.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

// =============================================================================
// Version Management APIs
// =============================================================================

/**
 * Initialize the version system by loading the active version from the manifest
 * This should be called when the app starts
 */
export async function initializeVersionSystem(): Promise<string> {
  try {
    const manifest = await loadVersionsManifest();
    const activeVersion = manifest.activeVersion || 'base';
    setActiveVersion(activeVersion);
    return activeVersion;
  } catch (error) {
    console.warn('Failed to load versions manifest, defaulting to base:', error);
    setActiveVersion('base');
    return 'base';
  }
}

/**
 * Get the currently active version ID
 */
export function getActiveVersion(): string {
  return getActiveVersionPath();
}

/**
 * Load the versions manifest
 */
export async function loadVersionsManifest(): Promise<VersionsManifest> {
  const dataDir = await getDataDir();
  const filePath = `${dataDir}/versions.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save the versions manifest
 */
export async function saveVersionsManifest(manifest: VersionsManifest): Promise<void> {
  const dataDir = await getDataDir();
  const filePath = `${dataDir}/versions.json`;
  const content = JSON.stringify(manifest, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Set the active version for this session
 */
export function setActiveVersion(versionId: string): void {
  activeVersionPath = versionId;
}

/**
 * Create a new blank version
 */
export async function createNewVersion(
  id: string,
  name: string,
  description: string,
  author: string
): Promise<GameVersion> {
  const manifest = await loadVersionsManifest();

  // Check if version already exists
  if (manifest.versions.find(v => v.id === id)) {
    throw new Error(`Version with id '${id}' already exists`);
  }

  const now = new Date().toISOString().split('T')[0];
  const newVersion: GameVersion = {
    id,
    name,
    description,
    author,
    version: '1.0.0',
    active: false,
    createdDate: now,
    lastModified: now,
    dataPath: `data/${id}`,
    thumbnail: null,
    tags: []
  };

  // Create directory structure (will be done via Tauri backend)
  const dataDir = await getDataDir();
  await invoke('create_version_directory', {
    dataDir,
    versionId: id
  });

  // Update manifest
  manifest.versions.push(newVersion);
  manifest.metadata.lastUpdated = now;
  await saveVersionsManifest(manifest);

  return newVersion;
}

/**
 * Clone an existing version
 */
export async function cloneVersion(
  sourceId: string,
  newId: string,
  newName: string,
  newAuthor: string
): Promise<GameVersion> {
  const manifest = await loadVersionsManifest();

  // Check if source exists
  const sourceVersion = manifest.versions.find(v => v.id === sourceId);
  if (!sourceVersion) {
    throw new Error(`Source version '${sourceId}' not found`);
  }

  // Check if new version already exists
  if (manifest.versions.find(v => v.id === newId)) {
    throw new Error(`Version with id '${newId}' already exists`);
  }

  const now = new Date().toISOString().split('T')[0];
  const clonedVersion: GameVersion = {
    id: newId,
    name: newName,
    description: `Cloned from ${sourceVersion.name}`,
    author: newAuthor,
    version: '1.0.0',
    active: false,
    createdDate: now,
    lastModified: now,
    dataPath: `data/${newId}`,
    thumbnail: null,
    tags: [...(sourceVersion.tags || [])],
    parentVersion: sourceId
  };

  // Clone directory (will be done via Tauri backend)
  const dataDir = await getDataDir();
  await invoke('clone_version_directory', {
    dataDir,
    sourceId,
    targetId: newId
  });

  // Update manifest
  manifest.versions.push(clonedVersion);
  manifest.metadata.lastUpdated = now;
  await saveVersionsManifest(manifest);

  return clonedVersion;
}

/**
 * Delete a version
 */
export async function deleteVersion(versionId: string): Promise<void> {
  const manifest = await loadVersionsManifest();

  // Prevent deleting base version
  if (versionId === 'base') {
    throw new Error('Cannot delete base version');
  }

  // Prevent deleting active version
  if (manifest.activeVersion === versionId) {
    throw new Error('Cannot delete the active version. Switch to another version first.');
  }

  // Check if version exists
  const versionIndex = manifest.versions.findIndex(v => v.id === versionId);
  if (versionIndex === -1) {
    throw new Error(`Version '${versionId}' not found`);
  }

  // Delete directory (will be done via Tauri backend)
  const dataDir = await getDataDir();
  await invoke('delete_version_directory', {
    dataDir,
    versionId
  });

  // Update manifest
  manifest.versions.splice(versionIndex, 1);
  manifest.metadata.lastUpdated = new Date().toISOString().split('T')[0];
  await saveVersionsManifest(manifest);
}

/**
 * Update version metadata
 */
export async function updateVersionMetadata(
  versionId: string,
  updates: Partial<Pick<GameVersion, 'name' | 'description' | 'author' | 'tags' | 'thumbnail'>>
): Promise<void> {
  const manifest = await loadVersionsManifest();

  const version = manifest.versions.find(v => v.id === versionId);
  if (!version) {
    throw new Error(`Version '${versionId}' not found`);
  }

  // Apply updates
  Object.assign(version, updates);
  version.lastModified = new Date().toISOString().split('T')[0];
  manifest.metadata.lastUpdated = version.lastModified;

  await saveVersionsManifest(manifest);
}

/**
 * Set the active version in the manifest
 */
export async function switchActiveVersion(versionId: string): Promise<void> {
  const manifest = await loadVersionsManifest();

  // Check if version exists
  const version = manifest.versions.find(v => v.id === versionId);
  if (!version) {
    throw new Error(`Version '${versionId}' not found`);
  }

  // Update active flags
  manifest.versions.forEach(v => {
    v.active = (v.id === versionId);
  });
  manifest.activeVersion = versionId;
  manifest.metadata.lastUpdated = new Date().toISOString().split('T')[0];

  await saveVersionsManifest(manifest);

  // Update session state
  setActiveVersion(versionId);
}

// =============================================================================
// Natural Resources APIs
// =============================================================================

/**
 * Load natural resources definitions from JSON file
 */
export async function loadNaturalResources(): Promise<NaturalResourcesData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/natural_resources.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save natural resources definitions to JSON file
 */
export async function saveNaturalResources(data: NaturalResourcesData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/natural_resources.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

// =============================================================================
// Time Slots APIs
// =============================================================================

/**
 * Load time slots from JSON file
 */
export async function loadTimeSlots(): Promise<TimeSlotsData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/time_slots.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save time slots to JSON file
 */
export async function saveTimeSlots(data: TimeSlotsData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/time_slots.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

// =============================================================================
// Craving Slots APIs
// =============================================================================

/**
 * Load craving-to-slot mappings from JSON file
 */
export async function loadCravingSlots(): Promise<CravingSlotsData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_slots.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save craving-to-slot mappings to JSON file
 */
export async function saveCravingSlots(data: CravingSlotsData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_slots.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

// =============================================================================
// Units System APIs
// =============================================================================

/**
 * Load units configuration from JSON file
 */
export async function loadUnits(): Promise<UnitsData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/units.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save units configuration to JSON file
 */
export async function saveUnits(data: UnitsData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/units.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

// =============================================================================
// Starting Locations APIs
// =============================================================================

/**
 * Load starting locations from JSON file
 */
export async function loadStartingLocations(): Promise<StartingLocationsData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/starting_locations.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save starting locations to JSON file
 */
export async function saveStartingLocations(data: StartingLocationsData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/starting_locations.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

// =============================================================================
// Phase 7: Land System APIs
// =============================================================================

/**
 * Load land configuration from JSON file
 */
export async function loadLandConfig(): Promise<LandConfig> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/land_config.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save land configuration to JSON file
 */
export async function saveLandConfig(data: LandConfig): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/land_config.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

// =============================================================================
// Phase 7: Class Thresholds APIs
// =============================================================================

/**
 * Load class thresholds from JSON file (emergent class system)
 */
export async function loadClassThresholds(): Promise<ClassThresholds> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/class_thresholds.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save class thresholds to JSON file
 */
export async function saveClassThresholds(data: ClassThresholds): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/class_thresholds.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

// =============================================================================
// Phase 7: Economic System APIs
// =============================================================================

/**
 * Load economic system configuration from JSON file
 */
export async function loadEconomicSystemConfig(): Promise<EconomicSystemConfig> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/economic_systems.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save economic system configuration to JSON file
 */
export async function saveEconomicSystemConfig(data: EconomicSystemConfig): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/economic_systems.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

// =============================================================================
// Phase 7: Immigration Config APIs
// =============================================================================

/**
 * Load immigration configuration from JSON file
 */
export async function loadImmigrationConfig(): Promise<ImmigrationConfigData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/immigration_config.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save immigration configuration to JSON file
 */
export async function saveImmigrationConfig(data: ImmigrationConfigData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/immigration_config.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

// =============================================================================
// Phase 7: Relationship Types APIs
// =============================================================================

/**
 * Load relationship types from JSON file
 */
export async function loadRelationshipTypes(): Promise<RelationshipTypesData> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/relationship_types.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save relationship types to JSON file
 */
export async function saveRelationshipTypes(data: RelationshipTypesData): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/relationship_types.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

// =============================================================================
// Phase 7: Extended Fulfillment Vectors (with Buildings)
// =============================================================================

/**
 * Load fulfillment vectors with building support
 */
export async function loadFulfillmentVectorsV2(): Promise<FulfillmentVectorsDataV2> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_system/fulfillment_vectors.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save fulfillment vectors with building support
 */
export async function saveFulfillmentVectorsV2(data: FulfillmentVectorsDataV2): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_system/fulfillment_vectors.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

// =============================================================================
// Pre-Computed Commodity Cache APIs
// =============================================================================

/**
 * Simple hash function for change detection
 */
function simpleHash(str: string): string {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32bit integer
  }
  return Math.abs(hash).toString(16);
}

/**
 * Generate pre-computed commodity cache from source data
 * This mirrors the logic in CommodityCache.lua but runs in the info-system
 */
export async function generateCommodityCache(): Promise<PreComputedCommodityCache> {
  // Load all required data
  const [fulfillmentData, dimensionData, substitutionData] = await Promise.all([
    loadFulfillmentVectors(),
    loadDimensionDefinitions(),
    loadSubstitutionRules()
  ]);

  // Build fine dimension name to index map
  const fineNameToIndex: Record<string, number> = {};
  const fineIndexToName: Record<number, string> = {};
  for (const fineDim of dimensionData.fineDimensions) {
    fineNameToIndex[fineDim.id] = fineDim.index;
    fineIndexToName[fineDim.index] = fineDim.id;
  }

  // Build coarse dimension name to index map
  const coarseNameToIndex: Record<string, number> = {};
  const coarseIndexToName: Record<number, string> = {};
  for (const coarseDim of dimensionData.coarseDimensions) {
    coarseNameToIndex[coarseDim.id] = coarseDim.index;
    coarseIndexToName[coarseDim.index] = coarseDim.id;
  }

  // Build fine to coarse mapping
  const fineToCoarseMap: Record<number, number> = {};
  for (const fineDim of dimensionData.fineDimensions) {
    const coarseIndex = coarseNameToIndex[fineDim.parentCoarse];
    if (coarseIndex !== undefined) {
      fineToCoarseMap[fineDim.index] = coarseIndex;
    }
  }

  // Build coarse to fine range mapping
  const coarseToFineRange: Record<number, { start: number; finish: number }> = {};
  for (let coarseIdx = 0; coarseIdx < dimensionData.coarseDimensions.length; coarseIdx++) {
    let fineStart: number | null = null;
    let fineEnd: number | null = null;

    for (const fineDim of dimensionData.fineDimensions) {
      if (fineToCoarseMap[fineDim.index] === coarseIdx) {
        if (fineStart === null || fineDim.index < fineStart) {
          fineStart = fineDim.index;
        }
        if (fineEnd === null || fineDim.index > fineEnd) {
          fineEnd = fineDim.index;
        }
      }
    }

    if (fineStart !== null && fineEnd !== null) {
      coarseToFineRange[coarseIdx] = { start: fineStart, finish: fineEnd };
    }
  }

  // Initialize cache structures
  const byCoarseDimension: Record<string, DimensionCache> = {};
  const byFineDimension: Record<string, DimensionCache> = {};
  const substitutionGroups: Record<string, SubstitutionGroupCache> = {};

  // Initialize coarse dimension caches
  for (const coarseDim of dimensionData.coarseDimensions) {
    byCoarseDimension[coarseDim.id] = {
      available: [],
      sortedByValue: []
    };
  }

  // Initialize fine dimension caches
  for (const fineDim of dimensionData.fineDimensions) {
    byFineDimension[fineDim.id] = {
      available: [],
      sortedByValue: []
    };
  }

  // Initialize substitution groups
  if (substitutionData.substitutionHierarchies) {
    for (const category of Object.keys(substitutionData.substitutionHierarchies)) {
      const commodities = substitutionData.substitutionHierarchies[category];
      substitutionGroups[category] = {
        members: Object.keys(commodities),
        available: Object.keys(commodities) // All are available in pre-computed cache
      };
    }
  }

  // Process each commodity with fulfillment vectors
  let totalCommodities = 0;
  for (const [commodityId, commodityData] of Object.entries(fulfillmentData.commodities)) {
    totalCommodities++;
    const fineVector = commodityData.fulfillmentVector?.fine;

    if (!fineVector) continue;

    // Add to fine dimension caches
    for (const [fineName, points] of Object.entries(fineVector)) {
      if (points > 0 && byFineDimension[fineName]) {
        byFineDimension[fineName].available.push({
          id: commodityId,
          value: points
        });
      }
    }

    // Aggregate to coarse dimension caches
    const coarseValues: Record<string, number> = {};
    for (const [fineName, points] of Object.entries(fineVector)) {
      if (points > 0) {
        const fineIndex = fineNameToIndex[fineName];
        if (fineIndex !== undefined) {
          const coarseIndex = fineToCoarseMap[fineIndex];
          if (coarseIndex !== undefined) {
            const coarseName = coarseIndexToName[coarseIndex];
            if (coarseName) {
              coarseValues[coarseName] = (coarseValues[coarseName] || 0) + points;
            }
          }
        }
      }
    }

    for (const [coarseName, totalPoints] of Object.entries(coarseValues)) {
      if (byCoarseDimension[coarseName]) {
        byCoarseDimension[coarseName].available.push({
          id: commodityId,
          value: totalPoints
        });
      }
    }
  }

  // Sort all caches by value (descending) and extract IDs
  for (const cache of Object.values(byFineDimension)) {
    cache.available.sort((a, b) => b.value - a.value);
    cache.sortedByValue = cache.available.map(entry => entry.id);
  }

  for (const cache of Object.values(byCoarseDimension)) {
    cache.available.sort((a, b) => b.value - a.value);
    cache.sortedByValue = cache.available.map(entry => entry.id);
  }

  // Generate hashes for change detection
  const fulfillmentHash = simpleHash(JSON.stringify(fulfillmentData));
  const dimensionHash = simpleHash(JSON.stringify(dimensionData));
  const substitutionHash = simpleHash(JSON.stringify(substitutionData));

  const cache: PreComputedCommodityCache = {
    version: '1.0.0',
    generatedAt: new Date().toISOString(),
    sourceDataHashes: {
      fulfillmentVectors: fulfillmentHash,
      dimensionDefinitions: dimensionHash,
      substitutionRules: substitutionHash
    },
    byCoarseDimension,
    byFineDimension,
    substitutionGroups,
    metadata: {
      coarseCacheCount: Object.keys(byCoarseDimension).length,
      fineCacheCount: Object.keys(byFineDimension).length,
      substitutionGroupCount: Object.keys(substitutionGroups).length,
      totalCommodities
    }
  };

  return cache;
}

/**
 * Save pre-computed commodity cache to JSON file
 */
export async function saveCommodityCache(cache: PreComputedCommodityCache): Promise<void> {
  const dataDir = await getDataDir();
  const versionPath = getActiveVersionPath();
  const filePath = `${dataDir}/${versionPath}/craving_system/commodity_cache.json`;
  const content = JSON.stringify(cache, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Load pre-computed commodity cache from JSON file
 */
export async function loadCommodityCache(): Promise<PreComputedCommodityCache | null> {
  try {
    const dataDir = await getDataDir();
    const versionPath = getActiveVersionPath();
    const filePath = `${dataDir}/${versionPath}/craving_system/commodity_cache.json`;
    const content = await readJsonFile(filePath);
    return JSON.parse(content);
  } catch {
    return null; // Cache doesn't exist yet
  }
}

/**
 * Generate and save the commodity cache
 * Returns the generated cache and time taken
 */
export async function generateAndSaveCommodityCache(): Promise<{
  cache: PreComputedCommodityCache;
  generationTimeMs: number;
}> {
  const startTime = performance.now();
  const cache = await generateCommodityCache();
  await saveCommodityCache(cache);
  const endTime = performance.now();

  return {
    cache,
    generationTimeMs: endTime - startTime
  };
}

/**
 * Check if cache needs regeneration by comparing source data hashes
 */
export async function cacheNeedsRegeneration(): Promise<{
  needsRegeneration: boolean;
  reason?: string;
}> {
  const existingCache = await loadCommodityCache();

  if (!existingCache) {
    return { needsRegeneration: true, reason: 'Cache does not exist' };
  }

  // Load current source data and compare hashes
  const [fulfillmentData, dimensionData, substitutionData] = await Promise.all([
    loadFulfillmentVectors(),
    loadDimensionDefinitions(),
    loadSubstitutionRules()
  ]);

  const currentFulfillmentHash = simpleHash(JSON.stringify(fulfillmentData));
  const currentDimensionHash = simpleHash(JSON.stringify(dimensionData));
  const currentSubstitutionHash = simpleHash(JSON.stringify(substitutionData));

  if (existingCache.sourceDataHashes.fulfillmentVectors !== currentFulfillmentHash) {
    return { needsRegeneration: true, reason: 'Fulfillment vectors have changed' };
  }
  if (existingCache.sourceDataHashes.dimensionDefinitions !== currentDimensionHash) {
    return { needsRegeneration: true, reason: 'Dimension definitions have changed' };
  }
  if (existingCache.sourceDataHashes.substitutionRules !== currentSubstitutionHash) {
    return { needsRegeneration: true, reason: 'Substitution rules have changed' };
  }

  return { needsRegeneration: false };
}
