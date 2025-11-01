use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

/// 🧾 Struct ánh xạ bảng `users`
/// - `created_at`: TIMESTAMPTZ -> `DateTime<Utc>`
/// - Ẩn `password_hash` khi serialize ra JSON để tránh lộ thông tin nhạy cảm
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    /// ID của tenant (đa-tenant)
    pub tenant_id: Uuid,
    /// ID duy nhất cho mỗi user trong tenant
    pub user_id: Uuid,
    /// Email đã được chuẩn hoá (lowercase) khi lưu
    pub email: String,
    /// Mật khẩu đã mã hoá (không serialize khi trả JSON)
    #[serde(skip_serializing)]
    pub password_hash: String,
    /// Tên hiển thị (NOT NULL theo schema)
    pub name: String,
    /// Thời điểm tạo (TIMESTAMPTZ)
    pub created_at: Option<DateTime<Utc>>, // 👈 chuyển thành Option
}
