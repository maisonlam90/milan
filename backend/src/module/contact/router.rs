use axum::{Router, routing::{get, post}, middleware};
use axum::routing::delete;
use std::sync::Arc;

use crate::core::{state::AppState, auth::jwt_auth};
use super::handler;

pub fn routes() -> Router<Arc<AppState>> {
    Router::new()
        .route("/contact/metadata", get(handler::get_metadata))
        .nest(
            "/contact",
            Router::new()
                .route("/create", post(handler::create_contact))
                .route("/list", get(handler::list_contacts))
                .route("/:id", get(handler::get_contact_by_id))
                .route("/:id/update", post(handler::update_contact))
                .route("/:id", delete(handler::delete_contact))
                .layer(middleware::from_fn(jwt_auth)),
        )
}
