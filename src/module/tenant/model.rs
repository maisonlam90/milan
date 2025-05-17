use serde::{Serialize, Deserialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

// Struct ánh xạ bảng tenant
#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Tenant {
    pub tenant_id: Uuid,               // ID định danh tenant
    pub name: String,                  // Tên tổ chức
    pub shard_id: String,              // Tên shard/cluster chứa tenant
    pub created_at: Option<DateTime<Utc>>, // Ngày tạo tenant
}

// Struct ánh xạ bảng tenant_module
#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct TenantModule {
    pub tenant_id: Uuid,               // ID tenant sở hữu module
    pub module_name: String,           // Tên module (VD: "ERP")
    pub config_json: serde_json::Value,// Cấu hình riêng cho module đó
    pub enabled_at: Option<DateTime<Utc>>, // Ngày bật module
}
