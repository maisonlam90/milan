use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// 📥 Dữ liệu đăng ký tài khoản (client gửi lên)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RegisterDto {
    /// 🎯 Tenant hiện tại (đa-tenant)
    pub tenant_id: Uuid,
    pub email: String,
    pub password: String,
    pub name: String,
}

impl RegisterDto {
    /// Chuẩn hoá dữ liệu đầu vào:
    /// - email: trim + lowercase (khớp unique index (tenant_id, lower(email)))
    /// - name : trim
    pub fn clean(self) -> Self {
        let RegisterDto {
            tenant_id,
            email,
            password,
            name,
        } = self;

        Self {
            tenant_id,
            email: email.trim().to_lowercase(),
            password,
            name: name.trim().to_string(),
        }
    }

    /// Kiểm tra hợp lệ cơ bản để tránh rác đổ vào DB
    pub fn validate(&self) -> Result<(), String> {
        if self.email.is_empty() {
            return Err("Email không được để trống".into());
        }
        if !self.email.contains('@') || !self.email.contains('.') {
            return Err("Email không đúng định dạng cơ bản".into());
        }
        if self.password.len() < 6 {
            return Err("Mật khẩu tối thiểu 6 ký tự".into());
        }
        if self.name.trim().is_empty() {
            return Err("Tên không được để trống".into());
        }
        Ok(())
    }
}

/// 📥 Dữ liệu đăng nhập
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoginDto {
    pub email: String,
    pub password: String,
    /// 🆕 Slug định danh tenant (ví dụ: "mailan.net")
    pub tenant_slug: String,
}

impl LoginDto {
    /// Chuẩn hoá:
    /// - email: trim + lowercase
    /// - tenant_slug: trim + lowercase để so sánh nhất quán
    pub fn clean(self) -> Self {
        let LoginDto {
            email,
            password,
            tenant_slug,
        } = self;

        Self {
            email: email.trim().to_lowercase(),
            password,
            tenant_slug: tenant_slug.trim().to_lowercase(),
        }
    }

    pub fn validate(&self) -> Result<(), String> {
        if self.email.is_empty() || !self.email.contains('@') {
            return Err("Email đăng nhập không hợp lệ".into());
        }
        if self.password.is_empty() {
            return Err("Mật khẩu không được để trống".into());
        }
        if self.tenant_slug.trim().is_empty() {
            return Err("Tenant slug không được để trống".into());
        }
        Ok(())
    }
}
