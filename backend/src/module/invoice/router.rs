use axum::{Router, routing::{get, post}, middleware};
use axum::routing::{delete, put};
use std::sync::Arc;

use crate::core::{state::AppState, auth::jwt_auth};
use super::handler;

pub fn routes() -> Router<Arc<AppState>> {
    Router::new()
        .route("/invoice/metadata", get(handler::get_metadata))
        .nest(
            "/invoice",
            Router::new()
                .route("/create", post(handler::create_invoice))
                .route("/list", get(handler::list_invoices))
                .route("/:id", get(handler::get_invoice_by_id))
                .route("/:id/update", put(handler::update_invoice))
                .route("/:id/confirm", post(handler::confirm_invoice))
                .route("/:id/cancel", post(handler::cancel_invoice))
                .route("/:id", delete(handler::delete_invoice))
                // Invoice lines
                .route("/:id/line", post(handler::add_invoice_line))
                .route("/:id/line/:line_id", put(handler::update_invoice_line))
                .route("/:id/line/:line_id", delete(handler::delete_invoice_line))
                .layer(middleware::from_fn(jwt_auth)),
        )
}

