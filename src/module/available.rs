use axum::{Json, extract::State};
use serde::Serialize;
use std::sync::Arc;
use uuid::Uuid;

use crate::core::state::AppState;

/// Cấu trúc trả về cho từng module khả dụng
#[derive(Serialize)]
pub struct AvailableModule {
    pub module_name: String,      // Tên kỹ thuật, ví dụ: 'user'
    pub display_name: String,     // Tên hiển thị, ví dụ: 'Quản lý người dùng'
}

/// Handler GET /available-modules
/// Truy vấn bảng available_module và trả về danh sách module có thể gán cho tenant
pub async fn get_available_modules(
    State(state): State<Arc<AppState>>,
) -> Result<Json<Vec<AvailableModule>>, (axum::http::StatusCode, String)> {
    // 👉 Lấy pool từ ShardManager (dùng nil() nếu là bảng toàn cục)
    let pool = state.shard.get_pool_for_tenant(&Uuid::nil());

    let rows = sqlx::query_as!(
        AvailableModule,
        r#"
        SELECT module_name, display_name
        FROM available_module
        ORDER BY display_name
        "#
    )
    .fetch_all(pool)
    .await
    .map_err(|e| (
        axum::http::StatusCode::INTERNAL_SERVER_ERROR,
        e.to_string()
    ))?;

    Ok(Json(rows))
}
