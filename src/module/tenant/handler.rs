use axum::{
    extract::{Path, State},
    response::IntoResponse,
    Json,
    http::StatusCode,
    debug_handler,
};
use std::{collections::HashMap, sync::Arc};
use uuid::Uuid;
use chrono::Utc;
use serde::Serialize;
use tracing::debug;

use crate::core::state::AppState;
use crate::core::json_with_log::JsonWithLog;


use super::{
    model::{Tenant, TenantModule},
    command::{CreateTenantCommand, AssignModuleCommand},
};

/// POST /tenant — tạo tenant mới
#[debug_handler]
pub async fn create_tenant(
    State(state): State<Arc<AppState>>,
    JsonWithLog(payload): JsonWithLog<CreateTenantCommand>,
) -> impl IntoResponse {
    let pool = match state.shard.get_pool_for_shard(&payload.shard_id) {
        Ok(p) => p,
        Err(msg) => {
            debug!("❌ {}", msg);
            return (StatusCode::BAD_REQUEST, Json("Shard không hợp lệ")).into_response();
        }
    };

    let tenant_id = Uuid::new_v4();
    let created_at = Utc::now();

    let result = sqlx::query_as!(
        Tenant,
        r#"
        INSERT INTO tenant (tenant_id, enterprise_id, company_id, name, slug, shard_id, created_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7)
        RETURNING tenant_id, enterprise_id, company_id, name, slug, shard_id, created_at
        "#,
        tenant_id,
        payload.enterprise_id,
        payload.company_id,
        payload.name,
        payload.slug,
        payload.shard_id,
        created_at
    )
    .fetch_one(pool)
    .await;

    match result {
        Ok(tenant) => (StatusCode::CREATED, Json(tenant)).into_response(),
        Err(err) => {
            debug!("❌ Lỗi khi tạo tenant (shard={}): {:?}", payload.shard_id, err);
            (StatusCode::INTERNAL_SERVER_ERROR, Json("Tạo tenant thất bại")).into_response()
        }
    }
}

/// GET /tenant/:tenant_id
#[debug_handler]
pub async fn get_tenant(
    State(state): State<Arc<AppState>>,
    Path(tenant_id): Path<Uuid>,
) -> impl IntoResponse {
    let pool = state.shard.get_pool_for_tenant(&tenant_id); // 👈 đã có tenant_id

    let result = sqlx::query_as!(
        Tenant,
        r#"
        SELECT tenant_id, enterprise_id, company_id, name, slug, shard_id, created_at
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

/// POST /tenant/:id/modules
#[debug_handler]
pub async fn assign_module(
    State(state): State<Arc<AppState>>,
    Path(tenant_id): Path<Uuid>,
    Json(payload): Json<AssignModuleCommand>,
) -> impl IntoResponse {
    let pool = state.shard.get_pool_for_tenant(&tenant_id);

    let config_json = payload.config_json.unwrap_or_else(|| serde_json::json!({}));
    let enabled_at = Utc::now();

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

/// GET /tenant/:id/modules
#[debug_handler]
pub async fn list_modules(
    State(state): State<Arc<AppState>>,
    Path(tenant_id): Path<Uuid>,
) -> impl IntoResponse {
    let pool = state.shard.get_pool_for_tenant(&tenant_id);

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

/// DELETE /tenant/:id/modules/:module_name
#[debug_handler]
pub async fn remove_module(
    State(state): State<Arc<AppState>>,
    Path((tenant_id, module_name)): Path<(Uuid, String)>,
) -> impl IntoResponse {
    let pool = state.shard.get_pool_for_tenant(&tenant_id);

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

/// Struct tổng hợp tenant + module
#[derive(Debug, Serialize)]
pub struct TenantWithModules {
    pub tenant_id: Uuid,
    pub name: String,
    pub slug: String,
    pub shard_id: String,
    pub modules: Vec<String>,
}

/// GET /tenants-with-modules
#[debug_handler]
pub async fn list_tenants_with_modules(
    State(state): State<Arc<AppState>>,
) -> impl IntoResponse {
    let pool = state.shard.get_pool_for_tenant(&Uuid::nil()); // 👈 dùng pool hệ thống

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
/// GET /enterprise/:id/tenants — liệt kê tenant theo enterprise_id
#[debug_handler]
pub async fn list_tenants_by_enterprise(
    State(state): State<Arc<AppState>>,
    Path(enterprise_id): Path<Uuid>,
) -> impl IntoResponse {
    let pool = state.shard.get_pool_for_tenant(&Uuid::nil());

    let result = sqlx::query_as!(
        Tenant,
        r#"
        SELECT tenant_id, enterprise_id, company_id, name, slug, shard_id, created_at
        FROM tenant
        WHERE enterprise_id = $1
        ORDER BY created_at DESC
        "#,
        enterprise_id
    )
    .fetch_all(pool)
    .await;

    match result {
        Ok(tenants) => Json(tenants).into_response(),
        Err(err) => (StatusCode::INTERNAL_SERVER_ERROR, Json(err.to_string())).into_response(),
    }
}

/// GET /company/:id/tenants — liệt kê tenant theo company_id
#[debug_handler]
pub async fn list_tenants_by_company(
    State(state): State<Arc<AppState>>,
    Path(company_id): Path<Uuid>,
) -> impl IntoResponse {
    let pool = state.shard.get_pool_for_tenant(&Uuid::nil());

    let result = sqlx::query_as!(
        Tenant,
        r#"
        SELECT tenant_id, enterprise_id, company_id, name, slug, shard_id, created_at
        FROM tenant
        WHERE company_id = $1
        ORDER BY created_at DESC
        "#,
        company_id
    )
    .fetch_all(pool)
    .await;

    match result {
        Ok(tenants) => Json(tenants).into_response(),
        Err(err) => (StatusCode::INTERNAL_SERVER_ERROR, Json(err.to_string())).into_response(),
    }
}
/// GET /company/:id/tenants/subtree — liệt kê tenant theo toàn bộ cây company (closure table)
#[debug_handler]
pub async fn list_tenants_by_company_subtree(
    State(state): State<Arc<AppState>>,
    Path(company_id): Path<Uuid>,
) -> impl IntoResponse {
    let pool = state.shard.get_pool_for_tenant(&Uuid::nil());

    // Tìm tất cả descendant của company_id
    let result = sqlx::query_as!(
        Tenant,
        r#"
        WITH subtree AS (
            SELECT descendant_id
            FROM company_edge
            WHERE ancestor_id = $1
        )
        SELECT t.tenant_id, t.enterprise_id, t.company_id, t.name, t.slug, t.shard_id, t.created_at
        FROM tenant t
        JOIN subtree s ON s.descendant_id = t.company_id
        ORDER BY t.created_at DESC
        "#,
        company_id
    )
    .fetch_all(pool)
    .await;

    match result {
        Ok(tenants) => Json(tenants).into_response(),
        Err(err) => (StatusCode::INTERNAL_SERVER_ERROR, Json(err.to_string())).into_response(),
    }
}
