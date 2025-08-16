use serde::Deserialize;
use uuid::Uuid;
use serde_json::Value;


/// Payload JSON khi tạo tenant mới từ frontend (đã mở rộng schema)
#[derive(Debug, Deserialize)]
pub struct CreateTenantCommand {
    pub enterprise_id: Uuid,          // FK tới enterprise (bắt buộc)
    pub company_id: Option<Uuid>,     // Gắn công ty nếu có
    pub name: String,                 // Tên tenant
    pub slug: String,                 // Slug duy nhất trong enterprise
    pub shard_id: String,             // Shard chứa tenant
}

/// Payload JSON khi gán module cho tenant
#[derive(Debug, Deserialize)]
pub struct AssignModuleCommand {
    pub module_name: String,          // Tên module cần bật
    pub config_json: Option<Value>,   // Cấu hình riêng nếu có
}

#[derive(Debug, Deserialize)]
pub struct EnableEnterpriseModuleCommand {
    pub module_name: String,
    pub config_json: Option<Value>,
}