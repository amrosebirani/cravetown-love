use std::fs;
use std::path::PathBuf;
use tauri::Manager;
use std::io;

fn copy_dir_recursive(src: &PathBuf, dst: &PathBuf) -> io::Result<()> {
    if !dst.exists() {
        fs::create_dir_all(dst)?;
    }

    for entry in fs::read_dir(src)? {
        let entry = entry?;
        let file_type = entry.file_type()?;
        let src_path = entry.path();
        let dst_path = dst.join(entry.file_name());

        if file_type.is_dir() {
            copy_dir_recursive(&src_path, &dst_path)?;
        } else {
            fs::copy(&src_path, &dst_path)?;
        }
    }

    Ok(())
}

fn delete_dir_recursive(path: &PathBuf) -> io::Result<()> {
    if path.is_dir() {
        fs::remove_dir_all(path)?;
    }
    Ok(())
}

#[tauri::command]
fn read_json_file(file_path: String) -> Result<String, String> {
    fs::read_to_string(&file_path)
        .map_err(|e| format!("Failed to read file {}: {}", file_path, e))
}

#[tauri::command]
fn write_json_file(file_path: String, content: String) -> Result<(), String> {
    fs::write(&file_path, content)
        .map_err(|e| format!("Failed to write file {}: {}", file_path, e))
}

#[tauri::command]
fn get_data_dir(app_handle: tauri::AppHandle) -> Result<String, String> {
    // Get the app's base directory
    let app_dir = app_handle
        .path()
        .app_config_dir()
        .map_err(|e| format!("Failed to get app directory: {}", e))?;

    // In development, we want to go to the project root's data directory
    // The path structure in dev is: cravetown-love/info-system/src-tauri/target/debug/
    // We need to get to: cravetown-love/data/

    // For development, use a fixed path relative to the project
    let data_dir = if cfg!(debug_assertions) {
        // In dev mode, navigate from src-tauri directory to parent's data folder
        PathBuf::from(env!("CARGO_MANIFEST_DIR"))
            .parent()
            .ok_or_else(|| "Failed to get parent directory".to_string())?
            .parent()
            .ok_or_else(|| "Failed to get parent directory".to_string())?
            .join("data")
    } else {
        // In production, use app data directory
        app_dir.join("data")
    };

    data_dir
        .to_str()
        .ok_or_else(|| "Failed to convert path to string".to_string())
        .map(|s| s.to_string())
}

#[tauri::command]
fn create_version_directory(data_dir: String, version_id: String) -> Result<(), String> {
    let version_path = PathBuf::from(&data_dir).join(&version_id);

    // Create main version directory
    fs::create_dir_all(&version_path)
        .map_err(|e| format!("Failed to create version directory: {}", e))?;

    // Create craving_system subdirectory
    fs::create_dir_all(version_path.join("craving_system"))
        .map_err(|e| format!("Failed to create craving_system directory: {}", e))?;

    // Create empty placeholder files for required data files
    let files = vec![
        "building_recipes.json",
        "building_types.json",
        "commodities.json",
        "worker_types.json",
        "work_categories.json",
    ];

    for file in files {
        let file_path = version_path.join(file);
        let empty_data = match file {
            "building_recipes.json" => r#"{"recipes":[]}"#,
            "building_types.json" => r#"{"buildingTypes":[]}"#,
            "commodities.json" => r#"{"commodities":[]}"#,
            "worker_types.json" => r#"{"workerTypes":[]}"#,
            "work_categories.json" => r#"{"workCategories":[]}"#,
            _ => "{}",
        };
        fs::write(file_path, empty_data)
            .map_err(|e| format!("Failed to create {}: {}", file, e))?;
    }

    // Create craving system files
    let craving_files = vec![
        "dimension_definitions.json",
        "character_classes.json",
        "character_traits.json",
        "fulfillment_vectors.json",
        "enablement_rules.json",
    ];

    for file in craving_files {
        let file_path = version_path.join("craving_system").join(file);
        fs::write(file_path, "{}")
            .map_err(|e| format!("Failed to create craving_system/{}: {}", file, e))?;
    }

    Ok(())
}

#[tauri::command]
fn clone_version_directory(data_dir: String, source_id: String, target_id: String) -> Result<(), String> {
    let source_path = PathBuf::from(&data_dir).join(&source_id);
    let target_path = PathBuf::from(&data_dir).join(&target_id);

    if !source_path.exists() {
        return Err(format!("Source version directory not found: {}", source_id));
    }

    if target_path.exists() {
        return Err(format!("Target version directory already exists: {}", target_id));
    }

    copy_dir_recursive(&source_path, &target_path)
        .map_err(|e| format!("Failed to clone version directory: {}", e))?;

    Ok(())
}

#[tauri::command]
fn delete_version_directory(data_dir: String, version_id: String) -> Result<(), String> {
    let version_path = PathBuf::from(&data_dir).join(&version_id);

    if !version_path.exists() {
        return Err(format!("Version directory not found: {}", version_id));
    }

    delete_dir_recursive(&version_path)
        .map_err(|e| format!("Failed to delete version directory: {}", e))?;

    Ok(())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
  tauri::Builder::default()
    .plugin(tauri_plugin_fs::init())
    .setup(|app| {
      if cfg!(debug_assertions) {
        app.handle().plugin(
          tauri_plugin_log::Builder::default()
            .level(log::LevelFilter::Info)
            .build(),
        )?;
      }
      Ok(())
    })
    .invoke_handler(tauri::generate_handler![
      read_json_file,
      write_json_file,
      get_data_dir,
      create_version_directory,
      clone_version_directory,
      delete_version_directory
    ])
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
