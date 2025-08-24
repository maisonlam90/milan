use axum::{
    extract::{Path, State},
    response::{IntoResponse, Response},
    http::StatusCode,
    Json,
    debug_handler,
};
use std::sync::Arc;
use uuid::Uuid;
use chrono::Utc;
use tracing::{debug, error};
use serde_json::{json, Value};
use std::collections::HashMap;

use crate::{
    core::{state::AppState, error::AppError, json_with_log::JsonWithLog},
    module::tenant::command::{AssignModuleCommand, EnableEnterpriseModuleCommand},
};
use super::model::Tenant;
use super::command::CreateTenantCommand;
use super::dto::{CreateEnterpriseCommand, CreateCompanyCommand};

/// ==============================
/// Refactored Handlers
/// ==============================

/// POST /tenant — tạo tenant mới
pub async fn create_tenant(
    State(state): State<Arc<AppState>>,
    JsonWithLog(payload): JsonWithLog<CreateTenantCommand>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state
        .shard
        .get_pool_for_shard(&payload.shard_id)
        .map_err(|msg| AppError::bad_request(msg))?;

    let tenant_id = Uuid::new_v4();
    let created_at = Utc::now();

    let tenant = sqlx::query_as!(
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
    .await?;

    Ok((StatusCode::CREATED, Json(tenant)))
}

/// POST /enterprise — tạo enterprise mới
pub async fn create_enterprise(
    State(state): State<Arc<AppState>>,
    JsonWithLog(payload): JsonWithLog<CreateEnterpriseCommand>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&Uuid::nil());

    let res = sqlx::query!(
        r#"
        INSERT INTO enterprise (enterprise_id, name, slug)
        VALUES (gen_random_uuid(), $1, $2)
        RETURNING enterprise_id, name, slug
        "#,
        payload.name,
        payload.slug
    )
    .fetch_one(pool)
    .await?;

    let body = json!({
        "enterprise_id": res.enterprise_id,
        "name": res.name,
        "slug": res.slug
    });

    Ok((StatusCode::CREATED, Json(body)))
}

/// POST /company — tạo company mới (tuỳ chọn parent)
pub async fn create_company(
    State(state): State<Arc<AppState>>,
    JsonWithLog(payload): JsonWithLog<CreateCompanyCommand>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&Uuid::nil());

    let company_id = Uuid::new_v4();
    let enterprise_id = payload.enterprise_id;
    let parent = payload.parent_company_id;

    let mut tx = pool.begin().await?;

    if let Some(parent_id) = parent {
        let row = sqlx::query!(
            r#"SELECT enterprise_id FROM company WHERE company_id = $1"#,
            parent_id
        )
        .fetch_optional(&mut *tx)
        .await?;

        match row {
            Some(r) if r.enterprise_id != enterprise_id => {
                tx.rollback().await?;
                return Err(AppError::bad_request("Parent company khác enterprise"));
            }
            None => {
                tx.rollback().await?;
                return Err(AppError::bad_request("Parent company không tồn tại"));
            }
            _ => {}
        }
    }

    sqlx::query(
        r#"INSERT INTO company (company_id, enterprise_id, name, slug)
           VALUES ($1, $2, $3, $4)"#,
    )
    .bind(company_id)
    .bind(enterprise_id)
    .bind(&payload.name)
    .bind(&payload.slug)
    .execute(&mut *tx)
    .await?;

    if let Some(parent_id) = parent {
        sqlx::query("SELECT add_company_edge($1, $2, $3)")
            .bind(enterprise_id)
            .bind(parent_id)
            .bind(company_id)
            .execute(&mut *tx)
            .await?;
    } else {
        sqlx::query(
            r#"INSERT INTO company_edge (enterprise_id, ancestor_id, descendant_id, depth)
               VALUES ($1, $2, $2, 0)
               ON CONFLICT DO NOTHING"#,
        )
        .bind(enterprise_id)
        .bind(company_id)
        .execute(&mut *tx)
        .await?;
    }

    tx.commit().await?;

    let body = json!({
        "company_id": company_id,
        "enterprise_id": enterprise_id,
        "name": payload.name,
        "slug": payload.slug
    });

    Ok((StatusCode::CREATED, Json(body)))
}

/// ==============================
/// Các handler cũ (giữ nguyên)
/// ==============================

/// GET /tenants-with-modules — liệt kê tất cả tenant + danh sách module đã bật
pub async fn list_tenants_with_modules(
    State(state): State<Arc<AppState>>,
) -> Response {
    let pool = state.shard.get_pool_for_tenant(&Uuid::nil());

    let rows = sqlx::query!(
        r#"
        SELECT 
            t.tenant_id,
            t.enterprise_id,
            t.company_id,
            t.name,
            t.slug,
            t.shard_id,
            m.module_name as "module_name?"
        FROM tenant t
        LEFT JOIN tenant_module m 
          ON m.tenant_id = t.tenant_id
        ORDER BY t.name
        "#
    )
    .fetch_all(pool)
    .await;

    match rows {
        Ok(records) => {
            let mut agg: HashMap<
                Uuid,
                (Uuid, Option<Uuid>, String, String, String, Vec<String>)
            > = HashMap::new();

            for r in records {
                let entry = agg
                    .entry(r.tenant_id)
                    .or_insert_with(|| (
                        r.enterprise_id,
                        r.company_id,
                        r.name.clone(),
                        r.slug.clone(),
                        r.shard_id.clone(),
                        Vec::new(),
                    ));

                if let Some(m) = r.module_name {
                    entry.5.push(m);
                }
            }

            let list: Vec<serde_json::Value> = agg
                .into_iter()
                .map(|(tenant_id, (enterprise_id, company_id, name, slug, shard_id, modules))| {
                    json!({
                        "tenant_id": tenant_id,
                        "enterprise_id": enterprise_id,
                        "company_id": company_id,
                        "name": name,
                        "slug": slug,
                        "shard_id": shard_id,
                        "modules": modules
                    })
                })
                .collect();

            let body = serde_json::to_string(&list).unwrap();
            Response::builder()
                .status(StatusCode::OK)
                .header("content-type", "application/json")
                .body(axum::body::Body::from(body))
                .unwrap()
        }
        Err(err) => {
            debug!("❌ Lỗi truy vấn tenants-with-modules: {:?}", err);
            Response::builder()
                .status(StatusCode::INTERNAL_SERVER_ERROR)
                .body(axum::body::Body::from("Không lấy được danh sách tenants"))
                .unwrap()
        }
    }
}

/// POST /tenant/:tenant_id/modules — gán module cho tenant
#[debug_handler]
pub async fn assign_module(
    State(state): State<Arc<AppState>>,
    Path(tenant_id): Path<Uuid>,
    axum::Json(payload): axum::Json<AssignModuleCommand>,
) -> Response {
    let pool = state.shard.get_pool_for_tenant(&tenant_id);
    let cfg: Value = payload.config_json.unwrap_or_else(|| json!({}));

    let res = sqlx::query!(
        r#"
        INSERT INTO tenant_module (tenant_id, module_name, config_json)
        VALUES ($1, $2, $3)
        RETURNING tenant_id, module_name, enabled_at
        "#,
        tenant_id,
        payload.module_name,
        cfg
    )
    .fetch_one(pool)
    .await;

    match res {
        Ok(row) => {
            let body = json!({
                "tenant_id": row.tenant_id,
                "module_name": row.module_name,
                "enabled_at": row.enabled_at
            }).to_string();

            Response::builder()
                .status(StatusCode::CREATED)
                .header("content-type", "application/json")
                .body(axum::body::Body::from(body))
                .unwrap()
        }
        Err(sqlx::Error::Database(db)) => {
            let code: String = db.code().map(|c| c.into_owned()).unwrap_or_default();
            let msg = match code.as_str() {
                "23503" => r#"{"error":"Enterprise chưa bật module này hoặc tenant/module không hợp lệ"}"#,
                "23505" => r#"{"error":"Module đã được bật cho tenant"}"#,
                _ => r#"{"error":"Gán module thất bại"}"#,
            };

            debug!("❌ assign_module db_error: code={}, detail={:?}", code, db);
            Response::builder()
                .status(StatusCode::BAD_REQUEST)
                .header("content-type", "application/json")
                .body(axum::body::Body::from(msg))
                .unwrap()
        }
        Err(err) => {
            debug!("❌ assign_module error: {:?}", err);
            Response::builder()
                .status(StatusCode::INTERNAL_SERVER_ERROR)
                .body(axum::body::Body::from("Gán module thất bại"))
                .unwrap()
        }
    }
}

/// GET /tenant/:tenant_id/modules — liệt kê module của tenant
#[debug_handler]
pub async fn list_modules(
    State(state): State<Arc<AppState>>,
    Path(tenant_id): Path<Uuid>,
) -> Response {
    let pool = state.shard.get_pool_for_tenant(&tenant_id);

    let res = sqlx::query!(
        r#"
        SELECT module_name, config_json, enabled_at
        FROM tenant_module
        WHERE tenant_id = $1
        ORDER BY module_name
        "#,
        tenant_id
    )
    .fetch_all(pool)
    .await;

    match res {
        Ok(rows) => {
            let items: Vec<Value> = rows
                .into_iter()
                .map(|r| {
                    json!({
                        "module_name": r.module_name,
                        "config_json": r.config_json.unwrap_or(json!({})),
                        "enabled_at": r.enabled_at
                    })
                })
                .collect();

            let body = serde_json::to_string(&items).unwrap();
            Response::builder()
                .status(StatusCode::OK)
                .header("content-type", "application/json")
                .body(axum::body::Body::from(body))
                .unwrap()
        }
        Err(err) => {
            debug!("❌ list_modules error: {:?}", err);
            Response::builder()
                .status(StatusCode::INTERNAL_SERVER_ERROR)
                .body(axum::body::Body::from("Không lấy được danh sách module"))
                .unwrap()
        }
    }
}

/// DELETE /tenant/:tenant_id/modules/:module_name — gỡ module
#[debug_handler]
pub async fn remove_module(
    State(state): State<Arc<AppState>>,
    Path((tenant_id, module_name)): Path<(Uuid, String)>,
) -> Response {
    let pool = state.shard.get_pool_for_tenant(&tenant_id);

    let res = sqlx::query!(
        r#"
        DELETE FROM tenant_module
        WHERE tenant_id = $1 AND module_name = $2
        "#,
        tenant_id,
        module_name
    )
    .execute(pool)
    .await;

    match res {
        Ok(done) if done.rows_affected() > 0 => {
            Response::builder()
                .status(StatusCode::NO_CONTENT)
                .body(axum::body::Body::empty())
                .unwrap()
        }
        Ok(_) => {
            Response::builder()
                .status(StatusCode::NOT_FOUND)
                .body(axum::body::Body::from("Module không tồn tại ở tenant"))
                .unwrap()
        }
        Err(err) => {
            debug!("❌ remove_module error: {:?}", err);
            Response::builder()
                .status(StatusCode::INTERNAL_SERVER_ERROR)
                .body(axum::body::Body::from("Gỡ module thất bại"))
                .unwrap()
        }
    }
}

/// POST /enterprise/:enterprise_id/modules — bật module cho enterprise
#[debug_handler]
pub async fn enable_enterprise_module(
    State(state): State<Arc<AppState>>,
    Path(enterprise_id): Path<Uuid>,
    axum::Json(payload): axum::Json<EnableEnterpriseModuleCommand>,
) -> Response {
    let pool = state.shard.get_pool_for_tenant(&Uuid::nil()); 

    let cfg = payload.config_json.unwrap_or_else(|| json!({}));
    let res = sqlx::query!(
        r#"
        INSERT INTO enterprise_module (enterprise_id, module_name, config_json)
        VALUES ($1, $2, $3)
        RETURNING enterprise_id, module_name, enabled_at
        "#,
        enterprise_id,
        payload.module_name,
        cfg
    )
    .fetch_one(pool)
    .await;

    match res {
        Ok(row) => {
            let body = json!({
                "enterprise_id": row.enterprise_id,
                "module_name": row.module_name,
                "enabled_at": row.enabled_at
            }).to_string();

            Response::builder()
                .status(StatusCode::CREATED)
                .header("content-type", "application/json")
                .body(axum::body::Body::from(body))
                .unwrap()
        }
        Err(sqlx::Error::Database(db)) if db.code().as_deref() == Some("23505") => {
            Response::builder()
                .status(StatusCode::OK)
                .header("content-type", "application/json")
                .body(axum::body::Body::from(r#"{"ok":"module already enabled"}"#))
                .unwrap()
        }
        Err(err) => {
            debug!("❌ enable_enterprise_module: {:?}", err);
            Response::builder()
                .status(StatusCode::BAD_REQUEST)
                .header("content-type", "application/json")
                .body(axum::body::Body::from(r#"{"error":"Bật module cho enterprise thất bại"}"#))
                .unwrap()
        }
    }
}
