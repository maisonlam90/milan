-- ============================
-- 📦 Cấu trúc bảng hệ thống đa tenant + ACL (Contextual RBAC)
-- ============================

-- Bảng tenant chứa thông tin tổ chức và shard tương ứng
CREATE TABLE IF NOT EXISTS tenant (
    tenant_id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    shard_id TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Bảng tenant_module ánh xạ tenant với các module mà họ sử dụng
CREATE TABLE IF NOT EXISTS tenant_module (
    tenant_id UUID NOT NULL,
    module_name TEXT NOT NULL,
    config_json JSONB DEFAULT '{}',
    enabled_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (tenant_id, module_name)
);

-- Bảng available_module lưu danh sách các module hệ thống có thể bật cho tenant
CREATE TABLE IF NOT EXISTS available_module (
    module_name TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    description TEXT,
    metadata JSONB DEFAULT '{}'
);

-- ============================
-- 🔐 ACL chuẩn RBAC mở rộng theo tenant
-- ============================

CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    name TEXT NOT NULL,
    module TEXT,
    UNIQUE(tenant_id, name)
);

CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    resource TEXT NOT NULL,
    action TEXT NOT NULL,
    label TEXT NOT NULL,
    UNIQUE(resource, action)
);

CREATE TABLE IF NOT EXISTS role_permissions (
    role_id UUID NOT NULL,
    permission_id UUID NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id UUID NOT NULL,
    role_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

-- ============================
-- 🔍 Chỉ mục và dữ liệu mặc định
-- ============================

CREATE INDEX IF NOT EXISTS idx_tenant_module_tenant_id ON tenant_module (tenant_id);

-- ✅ Tạo tenant hệ thống mặc định
INSERT INTO tenant (tenant_id, name, slug, shard_id)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  'System Admin Tenant',
  'mailan.net',
  'admin-cluster'
)
ON CONFLICT DO NOTHING;

-- ✅ Tạo user admin hệ thống (nếu bảng users đã tồn tại)
INSERT INTO users (tenant_id, user_id, email, password_hash, name, created_at)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'admin@mailan.net',
  '$2b$12$KFP4bYhbxzhVPcjYME9PTutOJihMrdoqLf8g9do7d9b0om2v6szbO',
  'System Admin',
  now()
)
ON CONFLICT DO NOTHING;

-- ✅ Tạo quyền cơ bản cho module user
INSERT INTO permissions (resource, action, label)
VALUES 
  ('user', 'read', 'Xem danh sách người dùng'),
  ('user', 'create', 'Tạo người dùng mới'),
  ('user', 'update', 'Cập nhật người dùng'),
  ('user', 'delete', 'Xoá người dùng'),
  ('user', 'assign_role', 'Gán vai trò cho người dùng')
ON CONFLICT DO NOTHING;

-- ✅ Tạo role admin toàn cục cho tenant hệ thống
INSERT INTO roles (tenant_id, name, module)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  'admin',
  'user'
)
ON CONFLICT DO NOTHING;

-- ✅ Gán toàn bộ quyền user.* vào role admin
INSERT INTO role_permissions (role_id, permission_id)
SELECT
  r.id,
  p.id
FROM roles r
JOIN permissions p ON p.resource = 'user'
WHERE r.name = 'admin' AND r.tenant_id = '00000000-0000-0000-0000-000000000000'
ON CONFLICT DO NOTHING;

-- ✅ Gán role admin cho user nếu tồn tại
INSERT INTO user_roles (user_id, role_id, tenant_id)
SELECT
  u.user_id,
  r.id,
  u.tenant_id
FROM users u
JOIN roles r ON r.name = 'admin' AND r.tenant_id = u.tenant_id
WHERE u.email = 'admin@example.com' AND u.tenant_id = '00000000-0000-0000-0000-000000000000'
ON CONFLICT DO NOTHING;
