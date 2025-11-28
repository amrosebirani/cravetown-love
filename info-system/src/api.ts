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
  GameVersion
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
