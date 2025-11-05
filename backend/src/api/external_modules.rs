//! External Modules Router - Tạo routes động từ modules ngoài binary
//! Load từ manifest.json trong modules/

use axum::{Router, routing::{get, post}, response::IntoResponse, Json, extract::{Path, Query, State}, middleware};
use serde_json::{Value, json};
use std::sync::Arc;
use std::collections::HashMap;

use crate::core::{auth::{AuthUser, jwt_auth}, state::AppState, error::AppError};
use sqlx::Row;

/// Tạo routes động từ module registry
pub fn routes(state: Arc<AppState>) -> Router<Arc<AppState>> {
    let mut router = Router::new();
    
    // Scan tất cả modules và tạo routes
    for module_info in state.module_registry.list_modules_owned() {
        let module_name = module_info.name.clone();
        let metadata = module_info.metadata.clone();
        
        // Tạo routes cho module này
        let module_router = create_module_routes(&module_name, metadata);
        router = router.merge(module_router);
        
        tracing::info!("✅ Registered routes cho module: {}", module_name);
    }
    
    router
}

/// Tạo routes cho một module cụ thể
fn create_module_routes(module_name: &str, _metadata: Value) -> Router<Arc<AppState>> {
    let base_path = format!("/{}", module_name);
    let module_name_clone = module_name.to_string();
    
    Router::new()
        // Public route - không cần auth
        .route(
            &format!("{}/metadata", base_path),
            get(move |state: State<Arc<AppState>>| {
                let name = module_name_clone.clone();
                async move {
                    get_module_metadata_handler(state, name).await
                }
            }),
        )
        // Protected routes - cần auth
        .nest(
            &base_path,
            Router::new()
                .route("/list", get({
                    let name = module_name.to_string();
                    move |state: State<Arc<AppState>>, auth: AuthUser, query: Query<HashMap<String, String>>| {
                        let name = name.clone();
                        async move {
                            list_handler(state, auth, query, name).await
                        }
                    }
                }))
                .route("/create", post({
                    let name = module_name.to_string();
                    move |state: State<Arc<AppState>>, auth: AuthUser, body: Json<Value>| {
                        let name = name.clone();
                        async move {
                            create_handler(state, auth, body, name).await
                        }
                    }
                }))
                .route("/:id", get({
                    let name = module_name.to_string();
                    move |state: State<Arc<AppState>>, auth: AuthUser, path: Path<String>| {
                        let name = name.clone();
                        async move {
                            get_by_id_handler(state, auth, path, name).await
                        }
                    }
                }))
                .layer(middleware::from_fn(jwt_auth)),
        )
}

/// Handler: GET /{module_name}/metadata
async fn get_module_metadata_handler(
    State(state): State<Arc<AppState>>,
    module_name: String,
) -> Result<impl IntoResponse, AppError> {
    if let Some(metadata) = state.module_registry.get_metadata_owned(&module_name) {
        tracing::info!("✅ Serving metadata cho module: {}", module_name);
        Ok(Json(metadata.clone()))
    } else {
        tracing::warn!("⚠️  Module không tìm thấy: {}", module_name);
        Err(AppError::not_found(&format!("Module '{}' not found", module_name)))
    }
}

/// Handler: GET /{module_name}/list - Generic list handler
async fn list_handler(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    _params: Query<HashMap<String, String>>,
    module_name: String,
) -> Result<impl IntoResponse, AppError> {
    tracing::info!("📋 List request cho module: {} (tenant: {})", module_name, auth.tenant_id);

    let metadata = state
        .module_registry
        .get_metadata_owned(&module_name)
        .ok_or_else(|| AppError::not_found(&format!("Module '{}' not found", module_name)))?;

    // Determine root table
    let root_table = metadata
        .get("root_table")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .unwrap_or_else(|| format!("{}_{}s", module_name, module_name));

    // Determine columns from list metadata, ensure id present
    let mut cols: Vec<String> = metadata
        .get("list")
        .and_then(|l| l.get("columns").and_then(|v| v.as_array().cloned()))
        .unwrap_or_default()
        .into_iter()
        .filter_map(|c| c.get("name").and_then(|n| n.as_str()).map(|s| s.to_string()))
        .collect();
    if !cols.iter().any(|c| c == "id") { cols.push("id".to_string()); }

    // Build SELECT
    let select_cols = cols
        .iter()
        .map(|c| format!("\"{}\"", c))
        .collect::<Vec<_>>()
        .join(", ");
    let sql = format!(
        "SELECT {} FROM {} WHERE tenant_id = $1 ORDER BY id DESC",
        select_cols, root_table
    );

    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
    let rows = sqlx::query(&sql)
        .bind(auth.tenant_id)
        .fetch_all(pool)
        .await
        .map_err(|e| AppError::internal(&format!("DB error: {}", e)))?;

    let list: Vec<Value> = rows
        .into_iter()
        .map(|row| {
            let mut obj = serde_json::Map::new();
            for c in &cols {
                // Try common types; fallback to string
                let v: Option<String> = row.try_get::<Option<String>, _>(c.as_str()).ok().flatten();
                if let Some(val) = v { obj.insert(c.clone(), Value::String(val)); continue; }
                // UUID as string
                if let Ok(idv) = row.try_get::<uuid::Uuid, _>(c.as_str()) {
                    obj.insert(c.clone(), Value::String(idv.to_string()));
                    continue;
                }
                // Leave null if not retrievable as string/uuid
                obj.insert(c.clone(), Value::Null);
            }
            Value::Object(obj)
        })
        .collect();

    Ok(Json(list))
}

/// Handler: POST /{module_name}/create - Generic create handler
async fn create_handler(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    body: Json<Value>,
    module_name: String,
) -> Result<impl IntoResponse, AppError> {
    tracing::info!("➕ Create request cho module: {} (tenant: {}, user: {})", 
        module_name, auth.tenant_id, auth.user_id);
    tracing::debug!("   Body: {:?}", body);

    let metadata = state
        .module_registry
        .get_metadata_owned(&module_name)
        .ok_or_else(|| AppError::not_found(&format!("Module '{}' not found", module_name)))?;

    let root_table = metadata
        .get("root_table")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .unwrap_or_else(|| format!("{}_{}s", module_name, module_name));

    // Allowed fields from form metadata
    let form_fields = metadata
        .get("form").and_then(|f| f.get("fields").and_then(|v| v.as_array().cloned()))
        .unwrap_or_default();

    let allowed_fields: Vec<String> = form_fields
        .iter()
        .filter_map(|f| f.get("name").and_then(|n| n.as_str()).map(|s| s.to_string()))
        .collect();

    // Validate required fields
    let required_fields: Vec<String> = form_fields
        .iter()
        .filter(|f| f.get("required").and_then(|r| r.as_bool()).unwrap_or(false))
        .filter_map(|f| f.get("name").and_then(|n| n.as_str()).map(|s| s.to_string()))
        .collect();

    let mut missing: Vec<String> = Vec::new();
    for rf in required_fields {
        match body.get(&rf) {
            None => missing.push(rf.clone()),
            Some(Value::Null) => missing.push(rf.clone()),
            Some(Value::String(s)) if s.trim().is_empty() => missing.push(rf.clone()),
            _ => {}
        }
    }
    if !missing.is_empty() {
        return Err(AppError::bad_request(&format!(
            "Thiếu trường bắt buộc: {}",
            missing.join(", ")
        )));
    }

    let id = uuid::Uuid::new_v4();
    let mut cols: Vec<String> = vec!["tenant_id".into(), "id".into()];
    let mut dyn_vals: Vec<Value> = Vec::new();

    for fname in allowed_fields {
        if let Some(v) = body.get(&fname) {
            cols.push(fname.clone());
            dyn_vals.push(v.clone());
        }
    }
    // Audit column
    cols.push("created_by".into());

    // Build SQL
    let col_sql = cols.iter().map(|c| format!("\"{}\"", c)).collect::<Vec<_>>().join(", ");
    let placeholders = (1..=cols.len()).map(|i| format!("${}", i)).collect::<Vec<_>>().join(", ");
    let sql = format!(
        "INSERT INTO {} ({}) VALUES ({})",
        root_table, col_sql, placeholders
    );

    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
    // Bind with correct types: tenant_id (Uuid), id (Uuid), dynamic fields (as text), created_by (Uuid)
    let mut q = sqlx::query(&sql)
        .bind(auth.tenant_id)
        .bind(id);

    // vals contains only dynamic field values in the same order as added to cols after tenant_id,id
    for v in dyn_vals.into_iter() {
        match v {
            Value::Null => { q = q.bind(Option::<String>::None); }
            Value::Bool(b) => { q = q.bind(b.to_string()); }
            Value::Number(n) => { q = q.bind(n.to_string()); }
            Value::String(s) => { q = q.bind(s); }
            other => { q = q.bind(other.to_string()); }
        }
    }

    // created_by at the end
    q = q.bind(auth.user_id);

    q.execute(pool)
        .await
        .map_err(|e| AppError::internal(&format!("DB error: {}", e)))?;

    Ok(Json(json!({ "id": id })))
}

/// Handler: GET /{module_name}/:id - Generic get by id handler
async fn get_by_id_handler(
    State(_state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<String>,
    module_name: String,
) -> Result<impl IntoResponse, AppError> {
    tracing::info!("🔍 Get by id cho module: {} (id: {}, tenant: {})", 
        module_name, id, auth.tenant_id);
    
    Ok(Json(json!({
        "id": id,
        "module": module_name,
        "message": "Mock data - chưa implement logic"
    })))
}

