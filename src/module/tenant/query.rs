use uuid::Uuid;

// Query lấy thông tin tenant cụ thể
pub struct GetTenantQuery {
    pub tenant_id: Uuid,
}