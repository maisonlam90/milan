use serde::Deserialize;
use uuid::Uuid;
use serde_json::Value;

// Payload JSON khi tạo tenant mới từ frontend
#[derive(Debug, Deserialize)]
pub struct CreateTenantCommand {
    pub name: String,         // Tên tổ chức
    pub shard_id: String,     // Tên shard để map tenant
}

// Payload JSON khi gán module cho tenant
#[derive(Debug, Deserialize)]
pub struct AssignModuleCommand {
    pub module_name: String,          // Tên module cần bật
    pub config_json: Option<Value>,   // Cấu hình riêng nếu có
}