use serde::{Deserialize, Serialize};
use uuid::Uuid;

// 🧾 Struct ánh xạ bảng users
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    pub tenant_id: Uuid, // ID của tenant (hệ thống đa tenant)
    pub user_id: Uuid,   // ID duy nhất cho mỗi user
    pub email: String,
    pub password_hash: String, // Mật khẩu đã mã hoá
    pub name: String,
    pub created_at: chrono::NaiveDateTime, // Ngày giờ tạo user
}