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
                       .route("/monthly-interest", get(handler::get_monthly_interest_income)) // lãi tháng
                       .route("/dashboard-stats", get(handler::get_dashboard_stats)) // 6 ô dashboard
                       .route("/portfolio-quality", get(handler::get_loan_portfolio_quality)) // chất lượng danh mục
                       .route("/contract-status", get(handler::get_contract_status)) // trạng thái hợp đồng
                       .route("/top-contracts", get(handler::get_top_contracts)) // top hợp đồng có lợi nhuận cao nhất
                       .route("/activity-report", get(handler::get_loan_activity_report)) // báo cáo hoạt động cho vay
                       .route("/recent-activities", get(handler::get_recent_activities)) // hoạt động gần đây
                .nest("/report", Router::new()
                    .route("/", get(handler::get_loan_report)) // ✅ API load báo cáo pivot
                    .route("/pivot-now", post(handler::pivot_now_all_contracts)) // ✅ Tính tất cả
                    .route("/:id/pivot-now", post(handler::pivot_now_contract))  // ✅ Tính 1 hợp đồng
                )
                // ✅ Các route tài sản thế chấp theo hợp đồng
                .route("/:id/collaterals", get(handler::get_collaterals_by_contract))
                .route("/:id/collaterals/add", post(handler::add_collateral_to_contract))
                .route("/:id/collaterals/release", post(handler::release_collateral_from_contract))

                // ✅ Tạo/gộp trực tiếp tài sản
                .route("/collateral", post(handler::create_collateral))
                .route("/collateral", get(handler::list_collateral))
                .route("/collateral/:asset_id", post(handler::update_collateral))
                .layer(middleware::from_fn(jwt_auth)),           // Tất cả require JWT
        )
}
