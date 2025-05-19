use serde::{Deserialize, Serialize};
use uuid::Uuid;

// 📥 Dữ liệu đăng ký tài khoản (từ client gửi lên)
#[derive(Debug, Serialize, Deserialize)]
pub struct RegisterDto {
    pub tenant_id: Uuid, // 🎯 Tenant hiện tại (đa tenant)
    pub email: String,
    pub password: String,
    pub name: String,
}

// 📥 Dữ liệu đăng nhập
#[derive(Debug, Serialize, Deserialize)]
pub struct LoginDto {
    pub email: String,
    pub password: String,
    pub tenant_slug: String, // 🆕 Thêm slug vào DTO
}