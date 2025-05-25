use axum::{Json, extract::{State, Extension}, http::StatusCode};
use std::sync::Arc;
use crate::core::state::AppState;
use crate::module::acl::command::{AssignRoleCommand, CreateRoleCommand, AssignPermissionsCommand};
use crate::module::acl::model::{Permission, Role};
use crate::core::auth::AuthUser;

/// ✅ Gán vai trò cho user trong tenant
#[axum::debug_handler]
pub async fn assign_role(
    State(state): State<Arc<AppState>>,
    Json(cmd): Json<AssignRoleCommand>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let pool = state.shard.get_pool_for_tenant(&cmd.tenant_id);

    let res = sqlx::query!(
        "INSERT INTO user_roles (user_id, role_id, tenant_id) VALUES ($1, $2, $3)",
        cmd.user_id,
        cmd.role_id,
        cmd.tenant_id
    )
    .execute(pool)
    .await;

    match res {
        Ok(_) => Ok(Json(serde_json::json!({ "status": "ok" }))),
        Err(e) => Err((StatusCode::INTERNAL_SERVER_ERROR, e.to_string())),
    }
}

/// ✅ Trả danh sách tất cả quyền hệ thống (GET /acl/permissions)
#[axum::debug_handler]
pub async fn list_permissions(
    State(state): State<Arc<AppState>>,
) -> Result<Json<Vec<Permission>>, (StatusCode, String)> {
    let pool = state.shard.get_pool_for_tenant(&uuid::Uuid::nil());
    let rows = sqlx::query_as!(Permission, r#"
        SELECT id, resource, action, label FROM permissions ORDER BY resource, action
    "#)
    .fetch_all(pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(rows))
}

/// ✅ Trả danh sách vai trò của tenant hiện tại (GET /acl/roles)
#[axum::debug_handler]
pub async fn list_roles(
    Extension(user): Extension<AuthUser>,
    State(state): State<Arc<AppState>>,
) -> Result<Json<Vec<Role>>, (StatusCode, String)> {
    let pool = state.shard.get_pool_for_tenant(&user.tenant_id);
    let rows = sqlx::query_as!(Role, r#"
        SELECT id, tenant_id, name, module FROM roles WHERE tenant_id = $1 ORDER BY name
    "#, user.tenant_id)
    .fetch_all(pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(rows))
}

/// ✅ Tạo role mới cho tenant hiện tại
#[axum::debug_handler]
pub async fn create_role(
    Extension(user): Extension<AuthUser>,
    State(state): State<Arc<AppState>>,
    Json(cmd): Json<CreateRoleCommand>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let pool = state.shard.get_pool_for_tenant(&user.tenant_id);
    let role_id = uuid::Uuid::new_v4();

    sqlx::query!(
        "INSERT INTO roles (id, tenant_id, name, module) VALUES ($1, $2, $3, $4)",
        role_id,
        user.tenant_id,
        cmd.name,
        cmd.module
    )
    .execute(pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(serde_json::json!({ "status": "ok", "role_id": role_id })))
}

/// ✅ Gán nhiều permission cho 1 role
#[axum::debug_handler]
pub async fn assign_permissions_to_role(
    State(state): State<Arc<AppState>>,
    Json(cmd): Json<AssignPermissionsCommand>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let pool = state.shard.get_pool_for_tenant(&uuid::Uuid::nil());

    for perm_id in &cmd.permission_ids {
        sqlx::query!(
            "INSERT INTO role_permissions (role_id, permission_id) VALUES ($1, $2)",
            cmd.role_id,
            perm_id
        )
        .execute(pool)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
    }

    Ok(Json(serde_json::json!({ "status": "ok" })))
}