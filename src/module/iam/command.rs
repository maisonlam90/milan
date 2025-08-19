use serde::Deserialize;
use uuid::Uuid;

/// 📥 Command gán vai trò cho user
#[derive(Debug, Deserialize)]
pub struct AssignRoleCommand {
    pub user_id: Uuid,
    pub role_id: Uuid,
    pub tenant_id: Uuid,
}

/// 📥 Command tạo vai trò mới
#[derive(Debug, Deserialize)]
pub struct CreateRoleCommand {
    pub name: String,
    pub module: Option<String>,
}

/// 📥 Command gán danh sách quyền cho 1 role
#[derive(Debug, Deserialize)]
pub struct AssignPermissionsCommand {
    pub role_id: Uuid,
    pub permission_ids: Vec<Uuid>,
}