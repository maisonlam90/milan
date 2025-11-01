use std::{fs, path::Path};
use convert_case::{Case, Casing}; // Thêm vào Cargo.toml nếu chưa có

fn extract_metadata(path: &Path) -> (String, String) {
    let content = fs::read_to_string(path).unwrap_or_default();
    let mut display = None;
    let mut desc = None;

    for line in content.lines() {
        if let Some(value) = line.strip_prefix("pub const DISPLAY_NAME: &str = \"") {
            display = Some(value.trim_end_matches("\";").to_string());
        }
        if let Some(value) = line.strip_prefix("pub const DESCRIPTION: &str = \"") {
            desc = Some(value.trim_end_matches("\";").to_string());
        }
    }

    let fallback = path.parent().unwrap().file_name().unwrap().to_str().unwrap().replace('_', " ").to_case(Case::Title);
    let display_name = display.unwrap_or_else(|| fallback.clone());
    let description = desc.unwrap_or_else(|| format!("Module {}", fallback));
    (display_name, description)
}

fn main() {
    let module_root = Path::new("src/module");

    println!("-- 🌐 Seed available_module + permissions từ metadata.rs --\n");

    for entry in fs::read_dir(module_root).expect("Không đọc được thư mục module") {
        let entry = entry.unwrap();
        let path = entry.path();

        if path.is_dir() {
            let module_name = path.file_name().unwrap().to_str().unwrap();
            let metadata_path = path.join("metadata.rs");

            if metadata_path.exists() {
                let (display_name, description) = extract_metadata(&metadata_path);

                // Seed available_module
                println!("-- 📦 Module: {module_name}");
                println!("INSERT INTO available_module (module_name, display_name, description) VALUES");
                println!("  ('{module_name}', '{display_name}', '{description}')");
                println!("ON CONFLICT DO NOTHING;\n");

                // Seed permissions
                println!("INSERT INTO permissions (resource, action, label) VALUES");
                println!("  ('{0}', 'access', 'Truy cập module {1}'),", module_name, display_name);
                println!("  ('{0}', 'read',   'Xem {1}'),", module_name, display_name);
                println!("  ('{0}', 'create', 'Tạo {1}'),", module_name, display_name);
                println!("  ('{0}', 'update', 'Cập nhật {1}'),", module_name, display_name);
                println!("  ('{0}', 'delete', 'Xoá {1}')", module_name, display_name);
                println!("ON CONFLICT DO NOTHING;\n");
            }
        }
    }
}
