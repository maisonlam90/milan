use axum::{Router, routing::{get, post, delete}, middleware};
use std::sync::Arc;

use crate::core::{state::AppState, auth::jwt_auth};
use super::handler;

pub fn routes() -> Router<Arc<AppState>> {
    Router::new().nest(
        "/app",
        Router::new()
            .route("/modules", get(handler::get_modules_status))
            .route("/modules/:module_name", post(handler::install_module))
            .route("/modules/:module_name", delete(handler::uninstall_module))
            .route("/scan", post(handler::scan_and_seed_modules)) // 🔧 Thêm route scan tại đây
            .layer(middleware::from_fn(jwt_auth)),
    )
}
