// src/core/acl.rs
use crate::core::auth::AuthUser;
use uuid::Uuid;

/// ✅ Kiểm tra user có phải admin hệ thống không (tenant_id == nil)
pub fn is_sys_admin(user: &AuthUser) -> bool {
    user.tenant_id == Uuid::nil()
}

// 📌 Tạm thời chưa có kiểm tra permission cụ thể vì chưa caching
// Sau này có thể mở rộng: kiểm tra user có quyền cụ thể hay không theo permission
// pub fn has_permission(user: &AuthUser, resource: &str, action: &str) -> bool {
//     ...
// }
