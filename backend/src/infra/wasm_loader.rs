//! WASM Module Loader - Load modules ngoài binary
//! Cho phép các dev phát triển module mà không cần rebuild backend

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use serde_json::Value;
use anyhow::{Result, Context};
use std::sync::{Arc, RwLock};
use wasmtime::*;
use wasmtime_wasi::{WasiCtx, WasiCtxBuilder};
use wasmtime_wasi::preview1::WasiP1Ctx;

/// Module metadata từ manifest.json
#[derive(Debug, Clone)]
pub struct ModuleInfo {
    pub name: String,
    pub display_name: String,
    pub manifest_path: PathBuf,
    pub wasm_path: Option<PathBuf>,
    pub metadata: Value,
}

/// WASM Module instance đã được load
pub struct WasmModule {
    pub info: ModuleInfo,
    engine: Engine,
    module: Module,
}

impl WasmModule {
    /// Load WASM module từ file
    pub fn load(info: ModuleInfo, wasm_path: &Path) -> Result<Self> {
        let mut config = Config::new();
        config.wasm_simd(true);
        config.wasm_bulk_memory(true);
        config.wasm_multi_value(true);
        
        let engine = Engine::new(&config)?;
        let module = Module::from_file(&engine, wasm_path)
            .with_context(|| format!("Failed to load WASM from {:?}", wasm_path))?;
        
        Ok(Self {
            info,
            engine,
            module,
        })
    }

    /// Call một exported function từ WASM module
    /// Returns JSON string result
    pub fn call_function(&self, func_name: &str, args: Vec<Value>) -> Result<Option<String>> {
        tracing::info!("🚀 Calling WASM function '{}::{}' with {} args", self.info.name, func_name, args.len());
        
        // Create simple store (for wasm32-unknown-unknown modules - no WASI needed)
        let mut store = Store::new(&self.engine, ());

        // Check what imports the module needs
        let imports = self.module.imports().collect::<Vec<_>>();
        
        tracing::info!("Module '{}' has {} imports", self.info.name, imports.len());
        if !imports.is_empty() {
            for import in &imports {
                tracing::info!("  Import: {}::{}", import.module(), import.name());
            }
        }
        
        // Try to instantiate directly (wasm32-unknown-unknown should have no imports)
        let instance = Instance::new(&mut store, &self.module, &[])
            .map_err(|e| {
                tracing::error!("Failed to instantiate module '{}': {}", self.info.name, e);
                if !imports.is_empty() {
                    tracing::error!("Module has {} imports - please rebuild with wasm32-unknown-unknown target", imports.len());
                }
                anyhow::anyhow!("WASM execution error: {}", e)
            })?;
        
        // Get memory export (for string arguments)
        let memory = instance.get_memory(&mut store, "memory")
            .ok_or_else(|| anyhow::anyhow!("WASM module does not export 'memory' - string arguments not supported"))?;
        
        // Get the function
        let func = instance
            .get_func(&mut store, func_name)
            .with_context(|| format!("Function '{}' not found in module '{}'", func_name, self.info.name))?;

        // Get function type to determine parameter and return types
        let func_ty = func.ty(&store);
        
        tracing::info!("Function signature: {} params, {} results", 
            func_ty.params().len(), func_ty.results().len());
        for (i, param_ty) in func_ty.params().enumerate() {
            tracing::info!("  Param {}: {:?}", i, param_ty);
        }
        for (i, result_ty) in func_ty.results().enumerate() {
            tracing::info!("  Result {}: {:?}", i, result_ty);
        }
        
        // Collect expected param types
        let param_types: Vec<ValType> = func_ty.params().collect();
        
        // Convert JSON Value args to wasmtime::Val based on expected types
        let mut wasm_args = Vec::new();
        let mut string_ptrs = Vec::new(); // Track allocated strings to free later
        
        for (i, arg) in args.iter().enumerate() {
            let expected_type = param_types.get(i);
            
            match arg {
                Value::String(s) => {
                    // Allocate memory in WASM for the string
                    let bytes = s.as_bytes();
                    let len = bytes.len();
                    
                    // Allocate memory (simple allocator: just find free space)
                    // In production, you'd use a proper allocator
                    let ptr = memory.data_size(&store) as i32;
                    let new_size = ptr as usize + len + 1; // +1 for null terminator
                    
                    // Grow memory if needed
                    if new_size > memory.data_size(&store) as usize {
                        let pages_needed = ((new_size + 65535) / 65536) as u64; // Round up to pages
                        memory.grow(&mut store, pages_needed)?;
                    }
                    
                    // Write string to memory
                    let mut data = memory.data_mut(&mut store);
                    data[ptr as usize..ptr as usize + len].copy_from_slice(bytes);
                    data[ptr as usize + len] = 0; // Null terminator
                    
                    // Pass pointer as i32
                    wasm_args.push(Val::I32(ptr));
                    string_ptrs.push(ptr);
                }
                Value::Number(n) => {
                    // Convert based on expected param type
                    match expected_type {
                        Some(ValType::F64) => {
                            let val = n.as_f64().unwrap_or(0.0);
                            wasm_args.push(Val::F64(f64::to_bits(val)));
                        }
                        Some(ValType::F32) => {
                            let val = n.as_f64().unwrap_or(0.0) as f32;
                            wasm_args.push(Val::F32(f32::to_bits(val)));
                        }
                        Some(ValType::I64) => {
                            let val = n.as_i64().unwrap_or(0);
                            wasm_args.push(Val::I64(val));
                        }
                        Some(ValType::I32) | None => {
                            let val = n.as_i64().unwrap_or(0) as i32;
                            wasm_args.push(Val::I32(val));
                        }
                        _ => {
                            // Default to F64 for numbers if unknown type
                            let val = n.as_f64().unwrap_or(0.0);
                            wasm_args.push(Val::F64(f64::to_bits(val)));
                        }
                    }
                }
                _ => anyhow::bail!("Unsupported argument type: {:?}", arg),
            }
        }

        // Create results vector based on function signature
        let mut results = Vec::new();
        for result_ty in func_ty.results() {
            match result_ty {
                ValType::I32 => results.push(Val::I32(0)),
                ValType::I64 => results.push(Val::I64(0)),
                ValType::F32 => results.push(Val::F32(0)),
                ValType::F64 => results.push(Val::F64(0)),
                _ => results.push(Val::I32(0)),
            }
        }

        tracing::info!("Calling with {} args, expecting {} results", wasm_args.len(), results.len());
        for (i, arg) in wasm_args.iter().enumerate() {
            tracing::info!("  Arg {}: {:?}", i, arg);
        }

        // Call the function
        func.call(&mut store, &wasm_args, &mut results)?;
        
        tracing::info!("✅ WASM function called successfully");
        for (i, result) in results.iter().enumerate() {
            tracing::info!("  Result {}: {:?}", i, result);
        }

        // Get result pointer (if function returns string pointer)
        let result_ptr = match results.first() {
            Some(Val::I32(ptr)) => *ptr,
            _ => return Ok(None),
        };
        
        // Read result string from WASM memory
        if result_ptr != 0 {
            tracing::info!("📖 Reading result string from pointer: {}", result_ptr);
            let data = memory.data(&store);
            let mut result_bytes = Vec::new();
            let mut offset = result_ptr as usize;
            
            // Read until null terminator
            while offset < data.len() && data[offset] != 0 {
                result_bytes.push(data[offset]);
                offset += 1;
            }
            
            tracing::info!("📖 Read {} bytes from WASM memory", result_bytes.len());
            
            if !result_bytes.is_empty() {
                let result_str = String::from_utf8(result_bytes)
                    .map_err(|e| anyhow::anyhow!("Invalid UTF-8 in WASM result: {}", e))?;
                tracing::info!("✅ Decoded result: {}", result_str);
                return Ok(Some(result_str));
            } else {
                tracing::warn!("⚠️ Empty result bytes");
            }
        } else {
            tracing::warn!("⚠️ Result pointer is 0 (null)");
        }
        
        // Fallback: try to parse as number
        match results.first() {
            Some(Val::I32(v)) => Ok(Some(v.to_string())),
            Some(Val::I64(v)) => Ok(Some(v.to_string())),
            Some(Val::F32(bits)) => Ok(Some(f32::from_bits(*bits).to_string())),
            Some(Val::F64(bits)) => Ok(Some(f64::from_bits(*bits).to_string())),
            _ => Ok(None),
        }
    }

    /// Get module info
    pub fn info(&self) -> &ModuleInfo {
        &self.info
    }
}

/// Module Registry - Quản lý modules ngoài binary
pub struct ModuleRegistry {
    modules: RwLock<HashMap<String, ModuleInfo>>,
    wasm_modules: RwLock<HashMap<String, Arc<WasmModule>>>,
}

impl ModuleRegistry {
    pub fn new() -> Self {
        Self {
            modules: RwLock::new(HashMap::new()),
            wasm_modules: RwLock::new(HashMap::new()),
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
                
                // Tìm WASM binary trong module directory
                // Thử wasm32-unknown-unknown trước (không cần WASI), rồi mới wasip1
                let wasm_path = module_dir.join(format!("target/wasm32-unknown-unknown/release/{}.wasm", module_name));
                let wasm_path = if wasm_path.exists() {
                    Some(wasm_path)
                } else {
                    // Thử tìm trong wasip1
                    let wasip1_path = module_dir.join(format!("target/wasm32-wasip1/release/{}.wasm", module_name));
                    if wasip1_path.exists() {
                        Some(wasip1_path)
                    } else {
                        None
                    }
                };
                
                let info = ModuleInfo {
                    name: module_name.clone(),
                    display_name: manifest["display_name"]
                        .as_str()
                        .unwrap_or(&module_name)
                        .to_string(),
                    manifest_path: manifest_path.clone(),
                    wasm_path: wasm_path.clone(),
                    metadata: manifest["metadata"].clone(),
                };

                new_map.insert(module_name.clone(), info);
                
                if wasm_path.is_some() {
                    tracing::info!("✅ Loaded module with WASM: {}", module_name);
                } else {
                    tracing::info!("✅ Loaded module (no WASM): {}", module_name);
                }
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

    /// Load WASM module vào cache (nếu chưa load)
    pub fn load_wasm_module(&self, module_name: &str) -> Result<Arc<WasmModule>> {
        // Check if already loaded
        {
            let cache = self.wasm_modules.read().unwrap();
            if let Some(wasm_module) = cache.get(module_name) {
                return Ok(Arc::clone(wasm_module));
            }
        }

        // Get module info
        let info = {
            let modules = self.modules.read().unwrap();
            modules.get(module_name)
                .cloned()
                .with_context(|| format!("Module '{}' not found", module_name))?
        };

        // Check if has WASM binary
        let wasm_path = info.wasm_path
            .clone()
            .with_context(|| format!("Module '{}' has no WASM binary", module_name))?;

        // Load WASM module
        let wasm_module = WasmModule::load(info, &wasm_path)?;
        let wasm_module = Arc::new(wasm_module);

        // Cache it
        {
            let mut cache = self.wasm_modules.write().unwrap();
            cache.insert(module_name.to_string(), Arc::clone(&wasm_module));
        }

        tracing::info!("🚀 Loaded WASM module into cache: {}", module_name);
        Ok(wasm_module)
    }

    /// Call function trong WASM module
    pub fn call_wasm_function(
        &self,
        module_name: &str,
        func_name: &str,
        args: Vec<Value>,
    ) -> Result<Option<String>> {
        let wasm_module = self.load_wasm_module(module_name)?;
        wasm_module.call_function(func_name, args)
    }

    /// Unload WASM module từ cache
    pub fn unload_wasm_module(&self, module_name: &str) {
        let mut cache = self.wasm_modules.write().unwrap();
        cache.remove(module_name);
        tracing::info!("🗑️  Unloaded WASM module from cache: {}", module_name);
    }

    /// Unload tất cả WASM modules từ cache (dùng khi reload)
    pub fn unload_all_wasm_modules(&self) {
        let mut cache = self.wasm_modules.write().unwrap();
        let count = cache.len();
        cache.clear();
        tracing::info!("🗑️  Unloaded {} WASM modules from cache", count);
    }

    /// Get danh sách tất cả module names đã load WASM trong cache
    pub fn get_loaded_wasm_module_names(&self) -> Vec<String> {
        self.wasm_modules.read().unwrap().keys().cloned().collect()
    }

    /// Get số lượng WASM modules đã load trong cache
    pub fn loaded_wasm_count(&self) -> usize {
        self.wasm_modules.read().unwrap().len()
    }
}

impl Default for ModuleRegistry {
    fn default() -> Self {
        Self::new()
    }
}

