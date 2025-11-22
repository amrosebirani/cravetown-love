use std::fs;
use std::path::PathBuf;
use tauri::Manager;

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
      get_data_dir
    ])
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
