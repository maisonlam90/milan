use serde_json::json;

/// Cấu trúc chứa metadata cho 1 module: tên kỹ thuật, hiển thị, mô tả, UI schema,...
pub struct ModuleMetadata {
    pub name: &'static str,             // Tên module kỹ thuật (vd: 'user')
    pub display_name: &'static str,     // Tên hiển thị (vd: 'Quản lý người dùng')
    pub description: &'static str,      // Mô tả ngắn về chức năng module
    pub metadata: serde_json::Value,    // Metadata mở rộng cho UI: icon, form,...
}

/// Hàm trả về metadata của module `user`
pub fn metadata() -> ModuleMetadata {
    ModuleMetadata {
        name: "user",
        display_name: "Quản lý người dùng",
        description: "Tạo và quản lý người dùng hệ thống.",
        metadata: json!({
            "icon": "👤",
            "color": "blue",
            "form_schema": {
                "fields": [
                    { "name": "username", "type": "text", "label": "Tên đăng nhập" },
                    { "name": "email", "type": "email", "label": "Email" }
                ]
            }
        }),
    }
}
