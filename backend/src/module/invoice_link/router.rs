use axum::{Router, routing::{get, post}, middleware};
use std::sync::Arc;

use crate::core::{state::AppState, auth::jwt_auth};
use super::handler;

pub fn routes() -> Router<Arc<AppState>> {
    Router::new()
        .nest(
            "/invoice-link",
            Router::new()
                .route("/login", post(handler::login_meinvoice))
                .route("/send", post(handler::send_invoice_to_meinvoice))
                .route("/list", get(handler::list_invoice_links))
                .route("/:id", get(handler::get_invoice_link_by_id))
                .route("/invoice/:invoice_id", get(handler::get_invoice_link_by_invoice_id))
                .layer(middleware::from_fn(jwt_auth)),
        )
}

