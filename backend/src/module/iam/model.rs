use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// ✅ Vai trò trong hệ thống RBAC theo tenant
#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Role {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub name: String,
    pub module: Option<String>,
}

/// ✅ Quyền trên resource + action (ví dụ: user.read)
#[derive(Debug, Serialize, Deserialize, sqlx::FromRow)]
pub struct Permission {
    pub id: Uuid,
    pub resource: String,
    pub action: String,
    pub label: String,
}

/// ✅ Ánh xạ role ↔ permission
#[derive(Debug, Serialize, Deserialize)]
pub struct RolePermission {
    pub role_id: Uuid,
    pub permission_id: Uuid,
}

/// ✅ Ánh xạ user ↔ role theo tenant
#[derive(Debug, Serialize, Deserialize)]
pub struct UserRole {
    pub user_id: Uuid,
    pub role_id: Uuid,
    pub tenant_id: Uuid,
}