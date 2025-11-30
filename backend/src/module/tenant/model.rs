use serde::{Serialize, Deserialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

/// Struct ánh xạ bảng `tenant`
#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Tenant {
    pub tenant_id: Uuid,
    pub enterprise_id: Uuid,
    pub company_id: Option<Uuid>,
    pub name: String,
    pub slug: String,
    pub shard_id: String,
    pub created_at: Option<DateTime<Utc>>, // giữ Option để match query_as!
}

/// Struct ánh xạ bảng `tenant_module`
#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct TenantModule {
    pub tenant_id: Uuid,
    pub module_name: String,
    pub config_json: serde_json::Value,
    pub enabled_at: Option<DateTime<Utc>>, // giữ Option để match query_as!
}
