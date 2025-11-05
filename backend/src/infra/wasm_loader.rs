//! WASM Module Loader - Load modules ngoài binary
//! Cho phép các dev phát triển module mà không cần rebuild backend

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use serde_json::Value;
use anyhow::Result;
use std::sync::RwLock;

/// Module metadata từ manifest.json
#[derive(Debug, Clone)]
pub struct ModuleInfo {
    pub name: String,
    pub display_name: String,
    pub manifest_path: PathBuf,
    pub metadata: Value,
}

/// Module Registry - Quản lý modules ngoài binary
#[derive(Debug)]
pub struct ModuleRegistry {
    modules: RwLock<HashMap<String, ModuleInfo>>,
}

impl ModuleRegistry {
    pub fn new() -> Self {
        Self {
            modules: RwLock::new(HashMap::new()),
        }
    }

    /// Scan thư mục `modules/` và load tất cả modules
    pub fn scan_modules(&self, modules_dir: &Path) -> Result<()> {
        if !modules_dir.exists() {
            tracing::warn!("Modules directory không tồn tại: {:?}", modules_dir);
            // Nếu không tồn tại, coi như không có module ngoài
            let mut w = self.modules.write().unwrap();
            w.clear();
            return Ok(());
        }

        // Xây map mới từ đĩa rồi thay thế toàn bộ để phản ánh xóa/thêm
        let mut new_map: HashMap<String, ModuleInfo> = HashMap::new();

        // Scan các thư mục trong modules/
        for entry in std::fs::read_dir(modules_dir)? {
            let entry = entry?;
            let module_dir = entry.path();
            
            if !module_dir.is_dir() {
                continue;
            }

            let manifest_path = module_dir.join("manifest.json");
            
            // Chỉ load nếu có manifest.json
            if manifest_path.exists() {
                let manifest_str = std::fs::read_to_string(&manifest_path)?;
                let manifest: Value = serde_json::from_str(&manifest_str)?;
                
                let module_name = manifest["name"]
                    .as_str()
                    .map(|s| s.to_string())
                    .unwrap_or_else(|| entry.file_name().to_string_lossy().to_string());
                
                let info = ModuleInfo {
                    name: module_name.clone(),
                    display_name: manifest["display_name"]
                        .as_str()
                        .unwrap_or(&module_name)
                        .to_string(),
                    manifest_path: manifest_path.clone(),
                    metadata: manifest["metadata"].clone(),
                };

                new_map.insert(module_name.clone(), info);
                tracing::info!("✅ Loaded module: {}", module_name);
            }
        }

        // Thay thế toàn bộ registry
        let mut w = self.modules.write().unwrap();
        *w = new_map;

        Ok(())
    }

    /// Get metadata copy by module name
    pub fn get_metadata_owned(&self, name: &str) -> Option<Value> {
        self.modules.read().unwrap().get(name).map(|m| m.metadata.clone())
    }

    /// List all modules (owned copies)
    pub fn list_modules_owned(&self) -> Vec<ModuleInfo> {
        self.modules.read().unwrap().values().cloned().collect()
    }
}

impl Default for ModuleRegistry {
    fn default() -> Self {
        Self::new()
    }
}

