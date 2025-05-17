use axum::{Router, routing::{get, post, delete}};
use super::handler::{create_tenant, get_tenant, assign_module, list_modules, remove_module};
use sqlx::PgPool;

// Định nghĩa router cho module tenant với các route CRUD
pub fn routes(pool: PgPool) -> Router<PgPool> {
    Router::new()
        .route("/tenant", post(create_tenant))                       // Tạo tenant mới
        .route("/tenant/:tenant_id", get(get_tenant))               // Xem tenant
        .route("/tenant/:tenant_id/modules", post(assign_module))   // Gán module
        .route("/tenant/:tenant_id/modules", get(list_modules))     // Liệt kê module
        .route("/tenant/:tenant_id/modules/:module_name", delete(remove_module)) // Gỡ module
        .route("/tenants-with-modules", get(super::handler::list_tenants_with_modules))
        .with_state(pool)
}
