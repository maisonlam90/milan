use axum::{Json, extract::{State, Extension}, http::StatusCode};
use std::sync::Arc;
use crate::core::state::AppState;
use serde::{Deserialize, Serialize}; 
use uuid::Uuid;
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

/// ✅ Trả danh sách module mà user hiện tại được phép sử dụng (để render menu)
/// GET /acl/me/modules
#[axum::debug_handler]
pub async fn my_modules(
    Extension(user): Extension<AuthUser>,
    State(state): State<Arc<AppState>>,
) -> Result<Json<Vec<String>>, (StatusCode, String)> {
    let pool_tenant = state.shard.get_pool_for_tenant(&user.tenant_id);
    let pool_global = state.shard.get_pool_for_tenant(&Uuid::nil());

    // 👑 admin?
    let is_admin = sqlx::query_scalar::<_, bool>(
        r#"
        SELECT EXISTS (
          SELECT 1
          FROM user_roles ur
          JOIN roles r
            ON r.tenant_id = ur.tenant_id
           AND r.id        = ur.role_id
          WHERE ur.tenant_id = $1
            AND ur.user_id   = $2
            AND r.name = 'admin'
        )
        "#
    )
    .bind(user.tenant_id)
    .bind(user.user_id)
    .fetch_one(pool_tenant)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    if is_admin {
        // Admin thấy tất cả: chuẩn hóa thành "<module>.access"
        let all = sqlx::query_scalar::<_, Option<String>>(
            r#"SELECT (module_name || '.access') AS perm FROM available_module ORDER BY module_name"#
        )
        .fetch_all(pool_global)
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
        return Ok(Json(all.into_iter().flatten().collect()));
    }

    // role_id của user trong shard tenant
    let role_ids: Vec<Uuid> = sqlx::query_scalar::<_, Uuid>(
        r#"SELECT role_id FROM user_roles WHERE tenant_id = $1 AND user_id = $2"#
    )
    .bind(user.tenant_id)
    .bind(user.user_id)
    .fetch_all(pool_tenant)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    if role_ids.is_empty() {
        return Ok(Json(vec![]));
    }

    // Chuẩn hóa quyền:
    // - "module.<key>" + action='access'   -> "<key>.access"
    // - resource LIKE "%.access"           -> resource (đã đúng)
    // - action='access' & resource ko có . -> resource || ".access"
    let perms = sqlx::query_scalar::<_, Option<String>>(
        r#"
        SELECT DISTINCT
          CASE
            WHEN p.resource LIKE 'module.%' AND p.action = 'access'
              THEN split_part(p.resource, '.', 2) || '.access'
            WHEN p.resource LIKE '%.access'
              THEN p.resource
            WHEN p.action = 'access'
              THEN p.resource || '.access'
            ELSE NULL
          END AS perm
        FROM role_permissions rp
        JOIN permissions p ON p.id = rp.permission_id
        WHERE rp.role_id = ANY($1)
          AND (
            p.resource LIKE 'module.%'
            OR p.resource LIKE '%.access'
            OR p.action = 'access'
          )
        ORDER BY 1
        "#
    )
    .bind(&role_ids)
    .fetch_all(pool_global)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(perms.into_iter().flatten().collect()))
}


/// (Tuỳ chọn) ✅ Trả effective permissions chi tiết (resource, action) cho user
/// GET /acl/me/permissions
#[derive(serde::Serialize)]
pub struct EffectivePermission { pub resource: String, pub action: String }

#[axum::debug_handler]
pub async fn my_permissions(
    Extension(user): Extension<AuthUser>,
    State(state): State<Arc<AppState>>,
) -> Result<Json<Vec<EffectivePermission>>, (StatusCode, String)> {
    let pool = state.shard.get_pool_for_tenant(&user.tenant_id);

    let rows = sqlx::query!(
        r#"
        SELECT DISTINCT p.resource, p.action
        FROM user_roles ur
        JOIN role_permissions rp ON rp.role_id = ur.role_id
        JOIN permissions p       ON p.id = rp.permission_id
        WHERE ur.user_id = $1 AND ur.tenant_id = $2
        "#,
        user.user_id,
        user.tenant_id
    )
    .fetch_all(pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    let data = rows.into_iter().map(|r| EffectivePermission {
        resource: r.resource, action: r.action
    }).collect();

    Ok(Json(data))
}


// struct request đã có Deserialize trước đó
#[derive(Debug, Deserialize)]
pub struct CreatePermissionReq {
    pub resource: String,
    pub action: String,
    pub label: String,
}

// ✅ struct trả JSON + FromRow cho sqlx::query_as::<_, T>()
#[derive(Serialize, sqlx::FromRow)]
pub struct AvailableModule {
    pub key: String,
    pub label: String,
}

#[axum::debug_handler]
pub async fn available_modules(
    State(state): State<Arc<AppState>>,
) -> Result<Json<Vec<AvailableModule>>, (StatusCode, String)> {
    let pool = state.shard.get_pool_for_tenant(&Uuid::nil()); // global

    // 👇 Đọc từ available_module, alias về key/label để FE dùng như cũ
    let rows = sqlx::query_as::<_, AvailableModule>(
        r#"
        SELECT module_name AS key,
               display_name AS label
        FROM available_module
        ORDER BY display_name
        "#,
    )
    .fetch_all(pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(rows))
}

#[axum::debug_handler]
pub async fn create_permission(
    Extension(_user): Extension<AuthUser>,           // yêu cầu JWT
    State(state): State<Arc<AppState>>,
    Json(req): Json<CreatePermissionReq>,
) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    // permissions là global => dùng shard "nil"
    let pool = state.shard.get_pool_for_tenant(&Uuid::nil());

    // Dùng ON CONFLICT DO UPDATE để luôn RETURNING id (kể cả khi đã tồn tại)
    let id = sqlx::query_scalar!(
        r#"
        INSERT INTO permissions (resource, action, label)
        VALUES ($1, $2, $3)
        ON CONFLICT (resource, action)
        DO UPDATE SET label = EXCLUDED.label
        RETURNING id
        "#,
        req.resource,
        req.action,
        req.label
    )
    .fetch_one(pool)
    .await
    .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;

    Ok(Json(serde_json::json!({ "status": "ok", "permission_id": id })))
}