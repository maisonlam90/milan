//! External Modules Router - Tạo routes động từ modules ngoài binary
//! Load từ manifest.json trong modules/

use axum::{Router, routing::{get, post}, response::IntoResponse, Json, extract::{Path, Query, State}, middleware};
use serde_json::{Value, json};
use std::sync::Arc;
use std::collections::HashMap;

use crate::core::{auth::{AuthUser, jwt_auth}, state::AppState, error::AppError};
use sqlx::{Row, Pool, Postgres, Column};
use uuid::Uuid;
use bigdecimal::BigDecimal;
use chrono::{NaiveDateTime, DateTime, Utc};

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
                .route("/:id/update", post({
                    let name = module_name.to_string();
                    move |state: State<Arc<AppState>>, auth: AuthUser, path: Path<String>, body: Json<Value>| {
                        let name = name.clone();
                        async move {
                            update_handler(state, auth, path, body, name).await
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

/// Helper: Xử lý notebook lines một cách generic
/// Đọc metadata.notebook để biết table, foreign_key, fields
/// Tự động INSERT các lines từ body vào database
async fn handle_notebook_lines(
    pool: &Pool<Postgres>,
    tenant_id: &Uuid,
    user_id: &Uuid,
    parent_id: &Uuid,
    metadata: &Value,
    body: &Value,
) -> Result<(), AppError> {
    // Kiểm tra có notebook metadata không
    let notebook_meta = match metadata.get("notebook") {
        Some(n) => n,
        None => return Ok(()), // Không có notebook thì skip
    };

    // Lấy thông tin notebook
    let notebook_table = notebook_meta
        .get("table")
        .and_then(|v| v.as_str())
        .ok_or_else(|| AppError::bad_request("Notebook thiếu 'table'"))?;
    
    let foreign_key = notebook_meta
        .get("foreign_key")
        .and_then(|v| v.as_str())
        .ok_or_else(|| AppError::bad_request("Notebook thiếu 'foreign_key'"))?;
    
    let notebook_fields = notebook_meta
        .get("fields")
        .and_then(|v| v.as_array())
        .ok_or_else(|| AppError::bad_request("Notebook thiếu 'fields'"))?;

    // Build field type map and required fields
    let mut field_type_map: HashMap<String, String> = HashMap::new();
    let mut required_fields: HashMap<String, String> = HashMap::new(); // field_name -> default_value
    
    for field in notebook_fields {
        if let (Some(name), Some(field_type)) = (
            field.get("name").and_then(|n| n.as_str()),
            field.get("type").and_then(|t| t.as_str()),
        ) {
            field_type_map.insert(name.to_string(), field_type.to_string());
            
            // Track required fields with default values
            let is_required = field.get("required").and_then(|r| r.as_bool()).unwrap_or(false);
            if is_required {
                let default_val = match field_type {
                    "number" => "0",
                    "text" => "",
                    "checkbox" => "false",
                    _ => "",
                };
                required_fields.insert(name.to_string(), default_val.to_string());
            }
        }
    }

    // Tìm lines trong body - có thể là order_lines, invoice_lines, lines, etc.
    let lines = body
        .get("order_lines")
        .or_else(|| body.get("invoice_lines"))
        .or_else(|| body.get("lines"))
        .and_then(|v| v.as_array());

    if lines.is_none() {
        return Ok(()); // Không có lines thì skip
    }

    let lines = lines.unwrap();
    tracing::info!("📝 Xử lý {} notebook lines cho table '{}'", lines.len(), notebook_table);

    // INSERT từng line
    for (idx, line) in lines.iter().enumerate() {
        if !line.is_object() {
            continue;
        }

        let line_obj = line.as_object().unwrap();
        
        // Collect các field có trong line
        let mut insert_fields = vec!["tenant_id".to_string(), foreign_key.to_string()];
        let mut insert_values: Vec<String> = vec!["$1".to_string(), "$2".to_string()]; // tenant_id, foreign_key
        let mut param_count = 2;
        
        // Track which fields are present
        let mut fields_to_bind: Vec<(String, Value)> = Vec::new();

        // Add fields from line_obj
        for (field_name, field_value) in line_obj.iter() {
            // Skip system fields - id will be auto-generated, tenant_id and foreign_key are handled separately
            if field_name == "id" || field_name == "tenant_id" || field_name == foreign_key {
                continue;
            }
            
            // Check if this is a required field
            let is_required = required_fields.contains_key(field_name);
            
            // Skip null/empty values for non-required fields
            let is_empty = match field_value {
                Value::Null => true,
                Value::String(s) => s.trim().is_empty(),
                _ => false,
            };
            
            if is_empty && !is_required {
                continue;
            }

            insert_fields.push(field_name.clone());
            param_count += 1;

            // Xác định type cast
            // Note: PostgreSQL can handle numeric -> double precision conversion
            let type_cast = match field_type_map.get(field_name).map(|s| s.as_str()) {
                Some("datetime") => "::timestamp without time zone",
                Some("date") => "::date",
                Some("number") => "::numeric", // Will be converted to double precision if needed
                Some("checkbox") => "::boolean",
                _ => "",
            };

            insert_values.push(format!("${}{}", param_count, type_cast));
            fields_to_bind.push((field_name.clone(), field_value.clone()));
        }
        
        // Add missing required fields with default values
        for (req_field, default_val) in required_fields.iter() {
            if !line_obj.contains_key(req_field) {
                insert_fields.push(req_field.clone());
                param_count += 1;
                
                let type_cast = match field_type_map.get(req_field).map(|s| s.as_str()) {
                    Some("number") => "::numeric",
                    Some("checkbox") => "::boolean",
                    _ => "",
                };
                
                insert_values.push(format!("${}{}", param_count, type_cast));
                
                // Create default Value
                let default_value = match field_type_map.get(req_field).map(|s| s.as_str()) {
                    Some("number") => Value::String(default_val.clone()),
                    Some("checkbox") => Value::Bool(false),
                    _ => Value::String(default_val.clone()),
                };
                fields_to_bind.push((req_field.clone(), default_value));
            }
        }

        // created_by at the end
        param_count += 1;
        insert_fields.push("created_by".to_string());
        insert_values.push(format!("${}", param_count));

        let insert_sql = format!(
            "INSERT INTO {} ({}) VALUES ({})",
            notebook_table,
            insert_fields.join(", "),
            insert_values.join(", ")
        );

        tracing::debug!("   Line {}: {}", idx + 1, insert_sql);

        // Bind parameters
        let mut q = sqlx::query(&insert_sql);
        q = q.bind(tenant_id);
        q = q.bind(parent_id);

        for (field_name, field_value) in fields_to_bind.iter() {
            let field_type = field_type_map.get(field_name).map(|s| s.as_str()).unwrap_or("text");
            let is_required = required_fields.contains_key(field_name);

            match field_type {
                "checkbox" => {
                    q = q.bind(field_value.as_bool().unwrap_or(false));
                }
                "number" => {
                    // For number fields, handle null/empty for required fields
                    let val_str = match field_value {
                        Value::Null => {
                            if is_required {
                                Some("0".to_string()) // Default to 0 for required number fields
                            } else {
                                None
                            }
                        }
                        Value::String(s) => {
                            let trimmed = s.trim();
                            if trimmed.is_empty() {
                                if is_required {
                                    Some("0".to_string())
                                } else {
                                    None
                                }
                            } else {
                                // Validate it's a valid number
                                if trimmed.parse::<f64>().is_ok() {
                                    Some(trimmed.to_string())
                                } else if is_required {
                                    Some("0".to_string())
                                } else {
                                    None
                                }
                            }
                        }
                        Value::Number(n) => Some(n.to_string()),
                        _ => {
                            let s = field_value.to_string().trim().to_string();
                            if s.is_empty() && is_required {
                                Some("0".to_string())
                            } else if s.is_empty() {
                                None
                            } else {
                                Some(s)
                            }
                        }
                    };
                    q = q.bind(val_str);
                }
                "datetime" | "date" => {
                    let val_str = match field_value {
                        Value::Null => None,
                        Value::String(s) => {
                            let trimmed = s.trim();
                            if trimmed.is_empty() {
                                None
                            } else {
                                Some(trimmed.to_string())
                            }
                        }
                        Value::Number(n) => Some(n.to_string()),
                        _ => {
                            let s = field_value.to_string().trim().to_string();
                            if s.is_empty() { None } else { Some(s) }
                        }
                    };
                    q = q.bind(val_str);
                }
                _ => {
                    let val_str = match field_value {
                        Value::Null => {
                            if is_required {
                                Some("".to_string()) // Default to empty string for required text fields
                            } else {
                                None
                            }
                        }
                        Value::String(s) => {
                            let trimmed = s.trim();
                            if trimmed.is_empty() && !is_required {
                                None
                            } else {
                                Some(trimmed.to_string())
                            }
                        }
                        _ => {
                            let s = field_value.to_string().trim().to_string();
                            if s.is_empty() && !is_required {
                                None
                            } else {
                                Some(s)
                            }
                        }
                    };
                    q = q.bind(val_str);
                }
            }
        }

        // Bind created_by
        q = q.bind(user_id);

        q.execute(pool)
            .await
            .map_err(|e| AppError::internal(&format!("Lỗi khi insert notebook line: {}", e)))?;
    }

    tracing::info!("✅ Đã lưu {} notebook lines", lines.len());
    Ok(())
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
    let mut dyn_vals: Vec<(Value, Option<String>)> = Vec::new(); // (value, field_type)

    // Build field type map from metadata
    let field_type_map: std::collections::HashMap<String, String> = form_fields
        .iter()
        .filter_map(|f| {
            let name = f.get("name")?.as_str()?;
            let field_type = f.get("type")?.as_str()?;
            Some((name.to_string(), field_type.to_string()))
        })
        .collect();

    for fname in allowed_fields {
        if let Some(v) = body.get(&fname) {
            cols.push(fname.clone());
            let field_type = field_type_map.get(&fname).cloned();
            dyn_vals.push((v.clone(), field_type));
        }
    }
    // Audit column
    cols.push("created_by".into());

    // Build SQL with type casting for proper data types
    let col_sql = cols.iter().map(|c| format!("\"{}\"", c)).collect::<Vec<_>>().join(", ");
    
    // Build placeholders with CAST for proper types
    // Total: tenant_id ($1), id ($2), dyn_vals ($3..$N), created_by ($N+1)
    let mut placeholders: Vec<String> = vec!["$1".to_string(), "$2".to_string()]; // tenant_id, id
    
    let mut param_idx = 3; // Start from $3 for dynamic fields
    for (_, field_type) in dyn_vals.iter() {
        let placeholder = match field_type.as_deref() {
            Some("datetime") => format!("${}::timestamp without time zone", param_idx),
            Some("date") => format!("${}::date", param_idx),
            Some("number") | Some("integer") => format!("${}::numeric", param_idx),
            Some("checkbox") => format!("${}::boolean", param_idx),
            _ => format!("${}", param_idx),
        };
        placeholders.push(placeholder);
        param_idx += 1;
    }
    
    // created_by - last parameter
    placeholders.push(format!("${}", param_idx));
    
    // Verify counts match
    let expected_params = 2 + dyn_vals.len() + 1; // tenant_id, id, dyn_vals, created_by
    let placeholder_count = placeholders.len();
    let col_count = cols.len();
    
    if placeholder_count != expected_params || col_count != expected_params {
        tracing::error!("Parameter count mismatch: cols={}, placeholders={}, expected={}, dyn_vals={}", 
            col_count, placeholder_count, expected_params, dyn_vals.len());
        return Err(AppError::internal("Parameter count mismatch in SQL query"));
    }
    
    let placeholders_sql = placeholders.join(", ");
    let sql = format!(
        "INSERT INTO {} ({}) VALUES ({})",
        root_table, col_sql, placeholders_sql
    );

    tracing::debug!("SQL: {} params (cols={}, placeholders={})", expected_params, col_count, placeholder_count);

    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
    // Bind with correct types: tenant_id (Uuid), id (Uuid), dynamic fields (with proper types), created_by (Uuid)
    let mut q = sqlx::query(&sql)
        .bind(auth.tenant_id)
        .bind(id);

    // Bind values with proper types based on field type
    // Important: Bind type must match the CAST in SQL placeholder
    // Strategy: Always bind as string/text, let PostgreSQL CAST handle type conversion
    // Exception: Only bind boolean directly when field type is checkbox
    for (v, field_type) in dyn_vals.into_iter() {
        match (v, field_type.as_deref()) {
            (Value::Null, _) => {
                // For null values, bind as NULL string (PostgreSQL will handle NULL with CAST)
                q = q.bind(Option::<String>::None);
            }
            (Value::Bool(b), Some("checkbox")) => {
                // Only bind boolean directly when field type is checkbox
                q = q.bind(b);
            }
            (Value::Bool(b), _) => {
                // Boolean for non-checkbox field - convert to string
                q = q.bind(if b { "true" } else { "false" });
            }
            (Value::Number(n), Some("checkbox")) => {
                // Number for checkbox - convert to boolean
                let b = n.as_i64().map(|i| i != 0).unwrap_or(false);
                q = q.bind(b);
            }
            (Value::Number(n), _) => {
                // For all other cases, bind number as string and let PostgreSQL CAST
                q = q.bind(n.to_string());
            }
            (Value::String(s), Some("checkbox")) => {
                // Parse checkbox string to boolean
                let b = s.eq_ignore_ascii_case("true") || s.eq_ignore_ascii_case("1") || s.eq_ignore_ascii_case("yes");
                q = q.bind(b);
            }
            (Value::String(s), Some("datetime") | Some("date")) => {
                // For datetime/date, treat empty string as NULL
                if s.trim().is_empty() {
                    q = q.bind(Option::<String>::None);
                } else {
                    q = q.bind(s);
                }
            }
            (Value::String(s), Some("number") | Some("integer")) => {
                // For number fields, treat empty string as NULL
                if s.trim().is_empty() {
                    q = q.bind(Option::<String>::None);
                } else {
                    q = q.bind(s);
                }
            }
            (Value::String(s), _) => { 
                // For all other string values, bind as string
                // Treat empty string as NULL for better database handling
                if s.trim().is_empty() {
                    q = q.bind(Option::<String>::None);
                } else {
                    q = q.bind(s);
                }
            }
            (other, _) => { 
                // Fallback: convert to string
                q = q.bind(other.to_string()); 
            }
        }
    }

    // created_by at the end
    q = q.bind(auth.user_id);

    q.execute(pool)
        .await
        .map_err(|e| AppError::internal(&format!("DB error: {}", e)))?;

    // Xử lý notebook lines nếu có
    handle_notebook_lines(
        pool,
        &auth.tenant_id,
        &auth.user_id,
        &id,
        &metadata,
        &body,
    ).await?;

    Ok(Json(json!({ "id": id })))
}

/// Handler: POST /{module_name}/:id/update - Generic update handler
async fn update_handler(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<String>,
    body: Json<Value>,
    module_name: String,
) -> Result<impl IntoResponse, AppError> {
    tracing::info!("✏️ Update request cho module: {} (id: {}, tenant: {}, user: {})", 
        module_name, id, auth.tenant_id, auth.user_id);
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

    let form_fields = metadata
        .get("form").and_then(|f| f.get("fields").and_then(|v| v.as_array().cloned()))
        .unwrap_or_default();

    let allowed_fields: Vec<String> = form_fields
        .iter()
        .filter_map(|f| f.get("name").and_then(|n| n.as_str()).map(|s| s.to_string()))
        .collect();

    // Build field type map
    let field_type_map: HashMap<String, String> = form_fields
        .iter()
        .filter_map(|f| {
            let name = f.get("name")?.as_str()?;
            let field_type = f.get("type")?.as_str()?;
            Some((name.to_string(), field_type.to_string()))
        })
        .collect();

    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
    let record_id = uuid::Uuid::parse_str(&id)
        .map_err(|_| AppError::bad_request("Invalid UUID format"))?;

    // Build UPDATE statement
    let mut set_clauses: Vec<String> = Vec::new();
    let mut dyn_vals: Vec<(Value, Option<String>)> = Vec::new();
    let mut param_idx = 1;

    let body_obj = body.as_object()
        .ok_or_else(|| AppError::bad_request("Body phải là JSON object"))?;

    for (key, value) in body_obj.iter() {
        // Skip notebook fields và metadata fields
        if key == "order_lines" || key == "invoice_lines" || key == "lines" 
            || key == "id" || key == "tenant_id" || key == "created_by" || key == "created_at" {
            continue;
        }

        if !allowed_fields.contains(&key.to_string()) {
            continue;
        }

        // Determine type cast
        let field_type = field_type_map.get(key).map(|s| s.as_str());
        let type_cast = match field_type {
            Some("datetime") => "::timestamp without time zone",
            Some("date") => "::date",
            Some("number") => "::numeric",
            Some("checkbox") => "::boolean",
            _ => "",
        };

        set_clauses.push(format!("{} = ${}{}", key, param_idx, type_cast));
        dyn_vals.push((value.clone(), field_type.map(|s| s.to_string())));
        param_idx += 1;
    }

    if set_clauses.is_empty() {
        return Err(AppError::bad_request("Không có field nào để update"));
    }

    // Add updated_at
    set_clauses.push(format!("updated_at = ${}", param_idx));
    param_idx += 1;

    let update_sql = format!(
        "UPDATE {} SET {} WHERE tenant_id = ${} AND id = ${}",
        root_table,
        set_clauses.join(", "),
        param_idx,
        param_idx + 1
    );

    tracing::debug!("   SQL: {}", update_sql);

    let mut q = sqlx::query(&update_sql);

    // Bind values
    for (val, field_type_opt) in dyn_vals.into_iter() {
        match (val, field_type_opt.as_deref()) {
            (Value::Null, _) => {
                q = q.bind(Option::<String>::None);
            }
            (Value::Bool(b), Some("checkbox")) => {
                q = q.bind(b);
            }
            (Value::Bool(b), _) => {
                q = q.bind(if b { "true" } else { "false" });
            }
            (Value::Number(n), Some("checkbox")) => {
                let b = n.as_i64().map(|i| i != 0).unwrap_or(false);
                q = q.bind(b);
            }
            (Value::Number(n), _) => {
                q = q.bind(n.to_string());
            }
            (Value::String(s), Some("checkbox")) => {
                let b = s.eq_ignore_ascii_case("true") || s.eq_ignore_ascii_case("1") || s.eq_ignore_ascii_case("yes");
                q = q.bind(b);
            }
            (Value::String(s), Some("datetime") | Some("date") | Some("number")) => {
                if s.trim().is_empty() {
                    q = q.bind(Option::<String>::None);
                } else {
                    q = q.bind(s);
                }
            }
            (Value::String(s), _) => {
                if s.trim().is_empty() {
                    q = q.bind(Option::<String>::None);
                } else {
                    q = q.bind(s);
                }
            }
            (other, _) => {
                q = q.bind(other.to_string());
            }
        }
    }

    // Bind updated_at (NOW())
    q = q.bind(chrono::Utc::now());
    // Bind tenant_id and record id
    q = q.bind(auth.tenant_id);
    q = q.bind(record_id);

    q.execute(pool)
        .await
        .map_err(|e| AppError::internal(&format!("DB error: {}", e)))?;

    // Xử lý notebook lines nếu có
    // Chỉ xóa và insert lại nếu có key notebook lines trong body (kể cả mảng rỗng)
    // Nếu không có key này, giữ nguyên lines cũ
    let notebook_lines_key = body
        .get("order_lines")
        .or_else(|| body.get("invoice_lines"))
        .or_else(|| body.get("lines"));

    if let Some(lines_value) = notebook_lines_key {
        // Có key notebook lines trong body, cần update (xóa cũ và insert mới)
        if !lines_value.is_array() {
            return Err(AppError::bad_request("order_lines/invoice_lines/lines phải là array"));
        }
        // Delete existing lines first (chỉ khi có lines mới)
        if let Some(notebook_meta) = metadata.get("notebook") {
            if let (Some(notebook_table), Some(foreign_key)) = (
                notebook_meta.get("table").and_then(|v| v.as_str()),
                notebook_meta.get("foreign_key").and_then(|v| v.as_str()),
            ) {
                let delete_sql = format!(
                    "DELETE FROM {} WHERE tenant_id = $1 AND {} = $2",
                    notebook_table, foreign_key
                );
                sqlx::query(&delete_sql)
                    .bind(auth.tenant_id)
                    .bind(record_id)
                    .execute(pool)
                    .await
                    .map_err(|e| AppError::internal(&format!("Lỗi khi xóa notebook lines cũ: {}", e)))?;
                
                tracing::info!("🗑️ Đã xóa notebook lines cũ");
            }
        }

        // Insert new lines
        handle_notebook_lines(
            pool,
            &auth.tenant_id,
            &auth.user_id,
            &record_id,
            &metadata,
            &body,
        ).await?;
    } else {
        // Không có key notebook lines trong body, giữ nguyên lines cũ
        tracing::debug!("   Không có key notebook lines trong body, giữ nguyên lines cũ");
    }

    Ok(Json(json!({ "id": id, "message": "Updated successfully" })))
}

/// Handler: GET /{module_name}/:id - Generic get by id handler
async fn get_by_id_handler(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<String>,
    module_name: String,
) -> Result<impl IntoResponse, AppError> {
    tracing::info!("🔍 Get by id cho module: {} (id: {}, tenant: {})", 
        module_name, id, auth.tenant_id);

    let metadata = state
        .module_registry
        .get_metadata_owned(&module_name)
        .ok_or_else(|| AppError::not_found(&format!("Module '{}' not found", module_name)))?;

    let root_table = metadata
        .get("root_table")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .unwrap_or_else(|| format!("{}_{}s", module_name, module_name));

    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
    let record_id = uuid::Uuid::parse_str(&id)
        .map_err(|_| AppError::bad_request("Invalid UUID format"))?;

    // Query root record
    let sql = format!(
        "SELECT * FROM {} WHERE tenant_id = $1 AND id = $2",
        root_table
    );

    let row = sqlx::query(&sql)
        .bind(auth.tenant_id)
        .bind(record_id)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::internal(&format!("DB error: {}", e)))?
        .ok_or_else(|| AppError::not_found("Record not found"))?;

    // Convert row to JSON - try types in order: integer, Decimal (numeric), float, boolean, UUID, string
    let mut record: serde_json::Map<String, Value> = serde_json::Map::new();
    for idx in 0..row.len() {
        let col_name = row.column(idx).name();
        let value: Value = 
            // Try integer first (most common for IDs and numeric fields)
            if let Ok(v) = row.try_get::<Option<i32>, _>(idx) {
                v.map(|n| Value::Number(serde_json::Number::from(n))).unwrap_or(Value::Null)
            } else if let Ok(v) = row.try_get::<Option<i64>, _>(idx) {
                v.map(|n| Value::Number(serde_json::Number::from(n))).unwrap_or(Value::Null)
            } 
            // Try BigDecimal (PostgreSQL numeric type)
            else if let Ok(v) = row.try_get::<Option<BigDecimal>, _>(idx) {
                v.map(|d| {
                    // Convert BigDecimal to string then parse as f64
                    let d_str = d.to_string();
                    if let Ok(f64_val) = d_str.parse::<f64>() {
                        Value::Number(serde_json::Number::from_f64(f64_val).unwrap_or(serde_json::Number::from(0)))
                    } else {
                        Value::String(d_str)
                    }
                }).unwrap_or(Value::Null)
            }
            // Try float
            else if let Ok(v) = row.try_get::<Option<f64>, _>(idx) {
                v.map(|n| Value::Number(serde_json::Number::from_f64(n).unwrap_or(serde_json::Number::from(0)))).unwrap_or(Value::Null)
            }
            // Try boolean
            else if let Ok(v) = row.try_get::<Option<bool>, _>(idx) {
                v.map(Value::Bool).unwrap_or(Value::Null)
            }
            // Try NaiveDateTime (timestamp without time zone)
            else if let Ok(v) = row.try_get::<Option<NaiveDateTime>, _>(idx) {
                v.map(|dt| {
                    // Convert to ISO string format that dayjs can parse
                    // Format: YYYY-MM-DDTHH:MM:SS (ISO 8601 without timezone)
                    Value::String(dt.format("%Y-%m-%dT%H:%M:%S").to_string())
                }).unwrap_or(Value::Null)
            }
            // Try DateTime<Utc> (timestamp with time zone)
            else if let Ok(v) = row.try_get::<Option<DateTime<Utc>>, _>(idx) {
                v.map(|dt| {
                    // Convert to ISO 8601 string
                    Value::String(dt.to_rfc3339())
                }).unwrap_or(Value::Null)
            }
            // Try chrono::NaiveDate (date type)
            else if let Ok(v) = row.try_get::<Option<chrono::NaiveDate>, _>(idx) {
                v.map(|d| Value::String(d.format("%Y-%m-%d").to_string())).unwrap_or(Value::Null)
            }
            // Try UUID
            else if let Ok(v) = row.try_get::<Option<uuid::Uuid>, _>(idx) {
                v.map(|u| Value::String(u.to_string())).unwrap_or(Value::Null)
            }
            // Try string (last resort)
            else if let Ok(v) = row.try_get::<Option<String>, _>(idx) {
                v.map(|s| Value::String(s)).unwrap_or(Value::Null)
            }
            // Fallback: try to get as text
            else {
                match row.try_get::<Option<&str>, _>(idx) {
                    Ok(Some(s)) => Value::String(s.to_string()),
                    Ok(None) => Value::Null,
                    Err(_) => Value::Null,
                }
            };
        record.insert(col_name.to_string(), value);
    }

    // Load notebook lines if exists
    if let Some(notebook_meta) = metadata.get("notebook") {
        if let (Some(notebook_table), Some(foreign_key)) = (
            notebook_meta.get("table").and_then(|v| v.as_str()),
            notebook_meta.get("foreign_key").and_then(|v| v.as_str()),
        ) {
            let lines_sql = format!(
                "SELECT * FROM {} WHERE tenant_id = $1 AND {} = $2 ORDER BY sequence NULLS LAST, id",
                notebook_table, foreign_key
            );

            let lines_rows = sqlx::query(&lines_sql)
                .bind(auth.tenant_id)
                .bind(record_id)
                .fetch_all(pool)
                .await
                .map_err(|e| AppError::internal(&format!("DB error loading notebook lines: {}", e)))?;

            let mut lines: Vec<Value> = Vec::new();
            for line_row in lines_rows {
                let mut line_obj: serde_json::Map<String, Value> = serde_json::Map::new();
                for idx in 0..line_row.len() {
                    let col_name = line_row.column(idx).name();
                    // Skip tenant_id and foreign_key
                    if col_name == "tenant_id" || col_name == foreign_key {
                        continue;
                    }
                    // Convert row to JSON - try types in order: integer, Decimal (numeric), float, boolean, UUID, string
                    let value: Value = 
                        // Try integer first (most common for IDs and numeric fields)
                        if let Ok(v) = line_row.try_get::<Option<i32>, _>(idx) {
                            v.map(|n| Value::Number(serde_json::Number::from(n))).unwrap_or(Value::Null)
                        } else if let Ok(v) = line_row.try_get::<Option<i64>, _>(idx) {
                            v.map(|n| Value::Number(serde_json::Number::from(n))).unwrap_or(Value::Null)
                        } 
                        // Try BigDecimal (PostgreSQL numeric type)
                        else if let Ok(v) = line_row.try_get::<Option<BigDecimal>, _>(idx) {
                            v.map(|d| {
                                // Convert BigDecimal to string then parse as f64
                                let d_str = d.to_string();
                                if let Ok(f64_val) = d_str.parse::<f64>() {
                                    Value::Number(serde_json::Number::from_f64(f64_val).unwrap_or(serde_json::Number::from(0)))
                                } else {
                                    Value::String(d_str)
                                }
                            }).unwrap_or(Value::Null)
                        }
                        // Try float
                        else if let Ok(v) = line_row.try_get::<Option<f64>, _>(idx) {
                            v.map(|n| Value::Number(serde_json::Number::from_f64(n).unwrap_or(serde_json::Number::from(0)))).unwrap_or(Value::Null)
                        }
                        // Try boolean
                        else if let Ok(v) = line_row.try_get::<Option<bool>, _>(idx) {
                            v.map(Value::Bool).unwrap_or(Value::Null)
                        }
                        // Try NaiveDateTime (timestamp without time zone)
                        else if let Ok(v) = line_row.try_get::<Option<NaiveDateTime>, _>(idx) {
                            v.map(|dt| {
                                // Convert to ISO string format that dayjs can parse
                                // Format: YYYY-MM-DDTHH:MM:SS (ISO 8601 without timezone)
                                Value::String(dt.format("%Y-%m-%dT%H:%M:%S").to_string())
                            }).unwrap_or(Value::Null)
                        }
                        // Try DateTime<Utc> (timestamp with time zone)
                        else if let Ok(v) = line_row.try_get::<Option<DateTime<Utc>>, _>(idx) {
                            v.map(|dt| {
                                // Convert to ISO 8601 string
                                Value::String(dt.to_rfc3339())
                            }).unwrap_or(Value::Null)
                        }
                        // Try chrono::NaiveDate (date type)
                        else if let Ok(v) = line_row.try_get::<Option<chrono::NaiveDate>, _>(idx) {
                            v.map(|d| Value::String(d.format("%Y-%m-%d").to_string())).unwrap_or(Value::Null)
                        }
                        // Try UUID
                        else if let Ok(v) = line_row.try_get::<Option<uuid::Uuid>, _>(idx) {
                            v.map(|u| Value::String(u.to_string())).unwrap_or(Value::Null)
                        }
                        // Try string (last resort)
                        else if let Ok(v) = line_row.try_get::<Option<String>, _>(idx) {
                            v.map(|s| Value::String(s)).unwrap_or(Value::Null)
                        }
                        // Fallback: try to get as text
                        else {
                            match line_row.try_get::<Option<&str>, _>(idx) {
                                Ok(Some(s)) => Value::String(s.to_string()),
                                Ok(None) => Value::Null,
                                Err(_) => Value::Null,
                            }
                        };
                    line_obj.insert(col_name.to_string(), value);
                }
                lines.push(Value::Object(line_obj));
            }

            // Add lines to record with key "order_lines" or "invoice_lines" or "lines"
            let lines_key = if module_name == "sale" { "order_lines" } 
                           else if module_name == "invoice" { "invoice_lines" }
                           else { "lines" };
            record.insert(lines_key.to_string(), Value::Array(lines));
        }
    }

    Ok(Json(Value::Object(record)))
}

