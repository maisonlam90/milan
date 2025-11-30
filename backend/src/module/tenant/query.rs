use uuid::Uuid;

/// Query lấy thông tin tenant cụ thể (theo ID)
pub struct GetTenantQuery {
    pub tenant_id: Uuid,
}

/// Query liệt kê tất cả tenant theo enterprise
pub struct ListTenantByEnterpriseQuery {
    pub enterprise_id: Uuid,
}

/// Query liệt kê tất cả tenant thuộc 1 company (có thể là công ty con)
pub struct ListTenantByCompanyQuery {
    pub company_id: Uuid,
}
