use axum::{
    Router,
    routing::{get, post, delete},
};
use std::sync::Arc;

use crate::core::state::AppState;

// Các handler có tồn tại
use crate::module::tenant::handler::{
    create_tenant,
    create_enterprise,
    create_company,
    // Nếu các handler sau đây THỰC SỰ có trong handler.rs thì giữ lại, nếu không thì comment/remove
    // get_tenant,
    assign_module,
    list_modules,
    remove_module,
    list_tenants_with_modules,
    enable_enterprise_module,
    // list_tenants_by_enterprise,
    // list_tenants_by_company,
    // list_tenants_by_company_subtree,
};

/// Định nghĩa router cho module tenant sử dụng AppState (hybrid pool)
pub fn routes() -> Router<Arc<AppState>> {
    Router::new()
        // Tenant CRUD
        .route("/tenant", post(create_tenant))
        // .route("/tenant/:tenant_id", get(get_tenant))

        // Module gán/bỏ cho tenant
        .route("/tenant/:tenant_id/modules", post(assign_module))
        .route("/tenant/:tenant_id/modules", get(list_modules))
        .route("/tenant/:tenant_id/modules/:module_name", delete(remove_module))
        .route("/enterprise/:enterprise_id/modules", post(enable_enterprise_module))

        // Danh sách tổng hợp
        .route("/tenants-with-modules", get(list_tenants_with_modules))

        // Liệt kê theo tổ chức / công ty
        // .route("/enterprise/:id/tenants", get(list_tenants_by_enterprise))
        // .route("/company/:id/tenants", get(list_tenants_by_company))
        // .route("/company/:id/tenants/subtree", get(list_tenants_by_company_subtree))

        // Tạo tổ chức & công ty
        .route("/enterprise", post(create_enterprise))
        .route("/company", post(create_company))
}
