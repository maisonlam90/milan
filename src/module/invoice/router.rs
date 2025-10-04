use axum::{Router, routing::{get, post, put, delete}, middleware};
use std::sync::Arc;

use crate::core::{state::AppState, auth::jwt_auth};
use crate::module::invoice::handler;

pub fn routes() -> Router<Arc<AppState>> {
    Router::new()
        // ✅ Metadata public, không cần token
        .route("/invoice/metadata", get(handler::get_metadata))
        .nest(
            "/invoice",
            Router::new()
                // CRUD Operations
                .route("/create", post(handler::create_invoice))
                .route("/list", get(handler::list_invoices))
                .route("/:id", get(handler::get_invoice_by_id))
                .route("/:id/update", put(handler::update_invoice))
                .route("/:id", delete(handler::delete_invoice))
                
                // Workflow Actions
                .route("/:id/post", post(handler::post_invoice))
                .route("/:id/reset-to-draft", post(handler::reset_to_draft))
                .route("/:id/cancel", post(handler::cancel_invoice))
                .route("/:id/reverse", post(handler::reverse_invoice))
                
                // Payment Operations
                .route("/:id/payments", get(handler::get_invoice_payments))
                .route("/:id/payments", post(handler::create_payment))
                .route("/payments/:payment_id", get(handler::get_payment_by_id))
                .route("/payments/:payment_id", put(handler::update_payment))
                .route("/payments/:payment_id", delete(handler::delete_payment))
                
                // Statistics
                .route("/stats", get(handler::get_invoice_stats))
                .route("/stats/by-type", get(handler::get_stats_by_type))
                .route("/stats/overdue", get(handler::get_overdue_stats))
                .route("/stats/monthly", get(handler::get_monthly_stats))
                
                // Reports
                .route("/report/summary", get(handler::get_invoice_summary_report))
                .route("/report/aging", get(handler::get_aging_report))
                .route("/report/tax", get(handler::get_tax_report))
                
                .layer(middleware::from_fn(jwt_auth))
        )
}
