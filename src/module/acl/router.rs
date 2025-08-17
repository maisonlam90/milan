use axum::{Router, routing::{get, post}, middleware};
use std::sync::Arc;
use crate::core::{state::AppState, auth::jwt_auth};
use crate::module::acl::handler;

pub fn routes() -> Router<Arc<AppState>> {
    let authed = Router::new()
        .route("/roles", get(handler::list_roles).post(handler::create_role))
        .route("/role-permissions", post(handler::assign_permissions_to_role))
        .route("/assign-role", post(handler::assign_role))
        .route("/me/modules", get(handler::my_modules))
        .route("/me/permissions", get(handler::my_permissions))
        .route("/permissions", post(handler::create_permission))   // 👈 thêm dòng này
        .layer(middleware::from_fn(jwt_auth));

    Router::new()
        .route("/acl/permissions", get(handler::list_permissions)) // public GET
        .route("/acl/available-modules", get(handler::available_modules)) // 👈 thêm
        .nest("/acl", authed)
}
