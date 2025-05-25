use axum::{Json, extract::{Path, State}};
use uuid::Uuid;
use axum::response::IntoResponse;
use axum::http::StatusCode;
use axum::debug_handler;
use serde::Serialize;
use std::collections::HashMap;
use std::sync::Arc;

use crate::core::state::AppState;
use super::model::{Tenant, TenantModule};
use super::command::{CreateTenantCommand, AssignModuleCommand};

// Tạo mới tenant (POST /tenant)
#[debug_handler]
pub async fn create_tenant(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<CreateTenantCommand>,
) -> impl IntoResponse {
    let pool = &state.default_pool;
    let tenant_id = Uuid::new_v4();
    let created_at = chrono::Utc::now();

    let result = sqlx::query_as::<_, Tenant>(
        r#"
        INSERT INTO tenant (tenant_id, name, slug, shard_id, created_at)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING tenant_id, name, slug, shard_id, created_at
        "#
    )
    .bind(tenant_id)
    .bind(&payload.name)
    .bind(&payload.slug)
    .bind(&payload.shard_id)
    .bind(created_at)
    .fetch_one(pool)
    .await;

    match result {
        Ok(tenant) => (StatusCode::CREATED, Json(tenant)).into_response(),
        Err(err) => (StatusCode::INTERNAL_SERVER_ERROR, Json(err.to_string())).into_response(),
    }
}

// Truy vấn thông tin tenant theo ID (GET /tenant/:id)
#[debug_handler]
pub async fn get_tenant(
    State(state): State<Arc<AppState>>,
    Path(tenant_id): Path<Uuid>,
) -> impl IntoResponse {
    let pool = &state.default_pool;

    let result = sqlx::query_as!(
        Tenant,
        r#"
        SELECT tenant_id, name, slug, shard_id, created_at
        FROM tenant
        WHERE tenant_id = $1
        "#,
        tenant_id
    )
    .fetch_one(pool)
    .await;

    match result {
        Ok(tenant) => Json(tenant).into_response(),
        Err(err) => (StatusCode::NOT_FOUND, Json(err.to_string())).into_response(),
    }
}

// Gán module cho tenant (POST /tenant/:id/modules)
#[debug_handler]
pub async fn assign_module(
    State(state): State<Arc<AppState>>,
    Path(tenant_id): Path<Uuid>,
    Json(payload): Json<AssignModuleCommand>,
) -> impl IntoResponse {
    let pool = &state.default_pool;

    let enabled_at = chrono::Utc::now();
    let config_json = payload.config_json.unwrap_or_else(|| serde_json::json!({}));

    let result = sqlx::query_as!(
        TenantModule,
        r#"
        INSERT INTO tenant_module (tenant_id, module_name, config_json, enabled_at)
        VALUES ($1, $2, $3, $4)
        RETURNING tenant_id, module_name, config_json, enabled_at
        "#,
        tenant_id,
        payload.module_name,
        config_json,
        enabled_at
    )
    .fetch_one(pool)
    .await;

    match result {
        Ok(module) => (StatusCode::CREATED, Json(module)).into_response(),
        Err(err) => (StatusCode::INTERNAL_SERVER_ERROR, Json(err.to_string())).into_response(),
    }
}

// Liệt kê các module của tenant (GET /tenant/:id/modules)
#[debug_handler]
pub async fn list_modules(
    State(state): State<Arc<AppState>>,
    Path(tenant_id): Path<Uuid>,
) -> impl IntoResponse {
    let pool = &state.default_pool;

    let result = sqlx::query_as!(
        TenantModule,
        r#"
        SELECT tenant_id, module_name, config_json, enabled_at
        FROM tenant_module
        WHERE tenant_id = $1
        "#,
        tenant_id
    )
    .fetch_all(pool)
    .await;

    match result {
        Ok(modules) => Json(modules).into_response(),
        Err(err) => (StatusCode::INTERNAL_SERVER_ERROR, Json(err.to_string())).into_response(),
    }
}

// Gỡ module khỏi tenant (DELETE /tenant/:id/modules/:module_name)
#[debug_handler]
pub async fn remove_module(
    State(state): State<Arc<AppState>>,
    Path((tenant_id, module_name)): Path<(Uuid, String)>,
) -> impl IntoResponse {
    let pool = &state.default_pool;

    let result = sqlx::query!(
        r#"
        DELETE FROM tenant_module
        WHERE tenant_id = $1 AND module_name = $2
        "#,
        tenant_id,
        module_name
    )
    .execute(pool)
    .await;

    match result {
        Ok(_) => StatusCode::NO_CONTENT.into_response(),
        Err(err) => (StatusCode::INTERNAL_SERVER_ERROR, Json(err.to_string())).into_response(),
    }
}

// ⚙️ Struct chứa tenant và danh sách module của họ
#[derive(Serialize)]
pub struct TenantWithModules {
    pub tenant_id: Uuid,
    pub name: String,
    pub slug: String, 
    pub shard_id: String,
    pub modules: Vec<String>,
}

// 📋 API danh sách tenant + module gán tương ứng (GET /tenants-with-modules)
#[debug_handler]
pub async fn list_tenants_with_modules(
    State(state): State<Arc<AppState>>,
) -> impl IntoResponse {
    let pool = &state.default_pool;

    let rows = sqlx::query!(
        r#"
        SELECT t.tenant_id, t.name, t.slug, t.shard_id, m.module_name as "module_name?"
        FROM tenant t
        LEFT JOIN tenant_module m ON t.tenant_id = m.tenant_id
        ORDER BY t.name
        "#
    )
    .fetch_all(pool)
    .await;

    match rows {
        Ok(records) => {
            let mut map: HashMap<Uuid, (String, String, String, Vec<String>)> = HashMap::new();
            for r in records {
                let entry = map.entry(r.tenant_id).or_insert_with(|| (
                    r.name.clone(),
                    r.slug.clone(),
                    r.shard_id.clone(),
                    vec![],
                ));
                if let Some(module_name) = r.module_name {
                    entry.3.push(module_name);
                }
            }
            let result: Vec<TenantWithModules> = map
                .into_iter()
                .map(|(tenant_id, (name, slug, shard_id, modules))| TenantWithModules {
                    tenant_id,
                    name,
                    slug,
                    shard_id,
                    modules,
                })
                .collect();

            Json(result).into_response()
        }
        Err(err) => (StatusCode::INTERNAL_SERVER_ERROR, Json(err.to_string())).into_response(),
    }
}
