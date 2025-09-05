use axum::{Router, routing::{get, post}, middleware};
use std::sync::Arc;

use axum::routing::delete; // 👈 để dùng delete()
use crate::core::{state::AppState, auth::jwt_auth};
use crate::module::loan::handler;

pub fn routes() -> Router<Arc<AppState>> {
    Router::new()
        // ✅ Metadata public, không cần token
        .route("/loan/metadata", get(handler::get_metadata))
        .nest(
            "/loan",
            Router::new()
                .route("/create", post(handler::create_contract))
                .route("/list", get(handler::list_contracts))
                .route("/:id", get(handler::get_contract_by_id))       // lấy chi tiết
                .route("/:id/update", post(handler::update_contract))  // cập nhật
                .route("/:id", delete(handler::delete_contract))       // ✅ Xoá hợp đồng
                .route("/stats", get(handler::get_loan_stats))         //bao cao
                // ✅ Các route tài sản thế chấp theo hợp đồng
                .route("/:id/collaterals", get(handler::get_collaterals_by_contract))
                .route("/:id/collaterals/add", post(handler::add_collateral_to_contract))
                .route("/:id/collaterals/release", post(handler::release_collateral_from_contract))

                // ✅ Tạo/gộp trực tiếp tài sản
                .route("/collateral", post(handler::create_collateral))
                .route("/collateral", get(handler::list_collateral))
                .layer(middleware::from_fn(jwt_auth)),           // Tất cả require JWT
        )
}
