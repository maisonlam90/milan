use axum::{Router, routing::{get, post}, middleware};
use std::sync::Arc;
use crate::core::{state::AppState, auth::jwt_auth};
use crate::module::acl::handler;

/// ✅ Mount các route ACL với phân chia route public và route cần JWT auth
pub fn routes() -> Router<Arc<AppState>> {
    Router::new()
        // 🔓 Public: lấy danh sách permission không cần auth
        .route("/acl/permissions", get(handler::list_permissions))

        // 🔐 Các route cần auth (tạo role, gán quyền...)
        .nest(
            "/acl",
            Router::new()
                .route("/roles", get(handler::list_roles))
                .route("/roles", post(handler::create_role))
                .route("/role-permissions", post(handler::assign_permissions_to_role))
                .route("/assign-role", post(handler::assign_role))
                .layer(middleware::from_fn(jwt_auth)),
        )
}
