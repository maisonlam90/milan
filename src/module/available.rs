//Tao api available module fronend hien thi khi chon gan module
use axum::{Json, extract::State};
use serde::Serialize;
use sqlx::PgPool;

/// Cấu trúc trả về cho từng module khả dụng
#[derive(Serialize)]
pub struct AvailableModule {
    pub module_name: String,      // Tên kỹ thuật, ví dụ: 'user'
    pub display_name: String,     // Tên hiển thị, ví dụ: 'Quản lý người dùng'
}

/// Handler GET /available-modules
/// Truy vấn bảng available_module và trả về danh sách module có thể gán cho tenant
pub async fn get_available_modules(
    State(pool): State<PgPool>, // Lấy connection pool từ app state
) -> Result<Json<Vec<AvailableModule>>, (axum::http::StatusCode, String)> {
    let rows = sqlx::query_as!(
        AvailableModule,
        r#"
        SELECT module_name, display_name
        FROM available_module
        ORDER BY display_name
        "#
    )
    .fetch_all(&pool)
    .await
    .map_err(|e| (
        axum::http::StatusCode::INTERNAL_SERVER_ERROR,
        e.to_string()
    ))?;

    Ok(Json(rows)) // Trả về JSON danh sách module
}
