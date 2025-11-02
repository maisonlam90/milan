//! External Modules Router - Tạo routes động từ modules ngoài binary
//! Load từ manifest.json trong modules/

use axum::{Router, routing::{get, post}, response::IntoResponse, Json, extract::{Path, Query, State}, middleware};
use serde_json::{Value, json};
use std::sync::Arc;
use std::collections::HashMap;

use crate::core::{auth::{AuthUser, jwt_auth}, state::AppState, error::AppError};

/// Tạo routes động từ module registry
pub fn routes(state: Arc<AppState>) -> Router<Arc<AppState>> {
    let mut router = Router::new();
    
    // Scan tất cả modules và tạo routes
    for module_info in state.module_registry.list_modules() {
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
    if let Some(metadata) = state.module_registry.get_metadata(&module_name) {
        tracing::info!("✅ Serving metadata cho module: {}", module_name);
        Ok(Json(metadata.clone()))
    } else {
        tracing::warn!("⚠️  Module không tìm thấy: {}", module_name);
        Err(AppError::not_found(&format!("Module '{}' not found", module_name)))
    }
}

/// Handler: GET /{module_name}/list - Generic list handler
async fn list_handler(
    State(_state): State<Arc<AppState>>,
    auth: AuthUser,
    _params: Query<HashMap<String, String>>,
    module_name: String,
) -> Result<impl IntoResponse, AppError> {
    tracing::info!("📋 List request cho module: {} (tenant: {})", module_name, auth.tenant_id);
    Ok(Json(vec![] as Vec<Value>))
}

/// Handler: POST /{module_name}/create - Generic create handler
async fn create_handler(
    State(_state): State<Arc<AppState>>,
    auth: AuthUser,
    body: Json<Value>,
    module_name: String,
) -> Result<impl IntoResponse, AppError> {
    tracing::info!("➕ Create request cho module: {} (tenant: {}, user: {})", 
        module_name, auth.tenant_id, auth.user_id);
    tracing::debug!("   Body: {:?}", body);
    
    Ok(Json(json!({
        "id": uuid::Uuid::new_v4(),
        "module": module_name,
        "message": "Created (demo - chưa implement logic)"
    })))
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

