use axum::{Router, routing::{get, post}, middleware};
use std::sync::Arc;
use crate::core::{state::AppState, auth::jwt_auth};
use crate::module::loan::handler;

pub fn routes() -> Router<Arc<AppState>> {
    Router::new()
        // ✅ Metadata public, không cần token
        .route("/loan/metadata", get(handler::get_metadata))
        .nest(
            "/loan",
            Router::new()
                .route("/create", post(handler::create_contract))   // đổi sang create_contract
                .route("/list", get(handler::list_contracts))       // đổi sang list_contracts
                .layer(middleware::from_fn(jwt_auth)),              // các route này require JWT
        )
}
