use axum::{Router, routing::{get, post, delete}};
use std::sync::Arc;

use crate::core::state::AppState;
use super::handler::{
    create_tenant, get_tenant, assign_module, list_modules, remove_module,
    list_tenants_with_modules,
};

/// Định nghĩa router cho module tenant sử dụng AppState (hybrid pool)
pub fn routes() -> Router<Arc<AppState>> {
    Router::new()
        .route("/tenant", post(create_tenant))                             // Tạo tenant mới
        .route("/tenant/:tenant_id", get(get_tenant))                      // Truy vấn tenant
        .route("/tenant/:tenant_id/modules", post(assign_module))          // Gán module
        .route("/tenant/:tenant_id/modules", get(list_modules))            // Liệt kê module
        .route("/tenant/:tenant_id/modules/:module_name", delete(remove_module)) // Gỡ module
        .route("/tenants-with-modules", get(list_tenants_with_modules))    // Danh sách tổng hợp
}
