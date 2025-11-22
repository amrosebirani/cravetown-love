import { invoke } from '@tauri-apps/api/core';
import type { BuildingRecipesData, CommoditiesData, WorkerTypesData, BuildingTypesData, WorkCategoriesData } from './types';

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
  const filePath = `${dataDir}/building_recipes.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save building recipes to JSON file
 */
export async function saveBuildingRecipes(data: BuildingRecipesData): Promise<void> {
  const dataDir = await getDataDir();
  const filePath = `${dataDir}/building_recipes.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Load commodities from JSON file
 */
export async function loadCommodities(): Promise<CommoditiesData> {
  const dataDir = await getDataDir();
  const filePath = `${dataDir}/commodities.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save commodities to JSON file
 */
export async function saveCommodities(data: CommoditiesData): Promise<void> {
  const dataDir = await getDataDir();
  const filePath = `${dataDir}/commodities.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Load worker types from JSON file
 */
export async function loadWorkerTypes(): Promise<WorkerTypesData> {
  const dataDir = await getDataDir();
  const filePath = `${dataDir}/worker_types.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save worker types to JSON file
 */
export async function saveWorkerTypes(data: WorkerTypesData): Promise<void> {
  const dataDir = await getDataDir();
  const filePath = `${dataDir}/worker_types.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Load building types from JSON file
 */
export async function loadBuildingTypes(): Promise<BuildingTypesData> {
  const dataDir = await getDataDir();
  const filePath = `${dataDir}/building_types.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save building types to JSON file
 */
export async function saveBuildingTypes(data: BuildingTypesData): Promise<void> {
  const dataDir = await getDataDir();
  const filePath = `${dataDir}/building_types.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}

/**
 * Load work categories from JSON file
 */
export async function loadWorkCategories(): Promise<WorkCategoriesData> {
  const dataDir = await getDataDir();
  const filePath = `${dataDir}/work_categories.json`;
  const content = await readJsonFile(filePath);
  return JSON.parse(content);
}

/**
 * Save work categories to JSON file
 */
export async function saveWorkCategories(data: WorkCategoriesData): Promise<void> {
  const dataDir = await getDataDir();
  const filePath = `${dataDir}/work_categories.json`;
  const content = JSON.stringify(data, null, 2);
  await writeJsonFile(filePath, content);
}
