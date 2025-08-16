use serde::{Serialize, Deserialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

/// Đầu vào tạo tenant mới
#[derive(Debug, Deserialize)]
pub struct CreateTenantInput {
    pub enterprise_id: Uuid,              // Bắt buộc
    pub company_id: Option<Uuid>,         // Có thể null nếu chưa gắn công ty
    pub name: String,
    pub slug: String,
    pub shard_id: String,                 // ID shard chứa dữ liệu
}

/// Đầu ra (liệt kê tenant)
#[derive(Debug, Serialize)]
pub struct TenantDto {
    pub tenant_id: Uuid,
    pub enterprise_id: Uuid,
    pub company_id: Option<Uuid>,
    pub name: String,
    pub slug: String,
    pub shard_id: String,
    pub created_at: DateTime<Utc>,
}

/// Đầu vào bật module cho tenant
#[derive(Debug, Deserialize)]
pub struct EnableModuleInput {
    pub module_name: String,
    pub config_json: Option<serde_json::Value>,
}

/// Đầu ra module đã bật
#[derive(Debug, Serialize)]
pub struct TenantModuleDto {
    pub tenant_id: Uuid,
    pub module_name: String,
    pub config_json: serde_json::Value,
    pub enabled_at: DateTime<Utc>,
}
