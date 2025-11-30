use axum::{Router, routing::{get, post}, middleware};
use std::sync::Arc;

use crate::core::{state::AppState, auth::jwt_auth};
use super::handler;

pub fn routes() -> Router<Arc<AppState>> {
    Router::new()
        .nest(
            "/invoice-link",
            Router::new()
                // Provider management
                .route("/providers", get(handler::list_providers))
                .route("/providers/:provider/form-fields", get(handler::get_provider_form_fields))
                .route("/providers/link", post(handler::link_provider))
                .route("/providers/credentials", get(handler::list_provider_credentials))
                // Invoice linking
                .route("/send", post(handler::send_invoice_to_provider))
                .route("/list", get(handler::list_invoice_links))
                .route("/:id", get(handler::get_invoice_link_by_id))
                .route("/invoice/:invoice_id", get(handler::get_invoice_link_by_invoice_id))
                .layer(middleware::from_fn(jwt_auth)),
        )
}

