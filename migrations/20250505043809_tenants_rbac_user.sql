-- ============================================================
-- 5) RBAC (THEO TENANT) + USER (THEO TENANT)
--    - Role thuộc tenant
--    - user_roles gắn (tenant_id, user_id, role_id) để không lẫn giữa tenant
-- ============================================================
CREATE TABLE IF NOT EXISTS permissions (
  id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource TEXT NOT NULL,                 -- Ví dụ: user, loan, report
  action   TEXT NOT NULL,                 -- Ví dụ: read, create, update, delete
  label    TEXT NOT NULL,                 -- Tên hiển thị
  UNIQUE(resource, action)
);

CREATE TABLE IF NOT EXISTS roles (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id  UUID NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  name       TEXT NOT NULL,               -- Tên role (admin, staff, auditor…)
  module     TEXT,                        -- Module áp dụng (tùy chọn)
  UNIQUE (tenant_id, name),
  UNIQUE (tenant_id, id)                  -- thay cho việc ADD CONSTRAINT IF NOT EXISTS
);

CREATE TABLE IF NOT EXISTS role_permissions (
  role_id       UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

-- Users: PK có tenant_id để shard
CREATE TABLE IF NOT EXISTS users (
  tenant_id     UUID NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  user_id       UUID NOT NULL,
  email         TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  name          TEXT,
  created_at    TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (tenant_id, user_id),
  UNIQUE (tenant_id, email)
);

-- Mapping user ↔ role (tenant-aware)
CREATE TABLE IF NOT EXISTS user_roles (
  tenant_id UUID NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  user_id   UUID NOT NULL,
  role_id   UUID NOT NULL,
  PRIMARY KEY (tenant_id, user_id, role_id),
  -- FK composite đảm bảo role thuộc đúng tenant:
  FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
  -- (đã có UNIQUE(tenant_id,id) trên roles, nếu cần siết chặt hơn thì dùng
  --  FOREIGN KEY (tenant_id, role_id) REFERENCES roles(tenant_id, id) ON DELETE CASCADE
  --  nhưng khi đó cần định nghĩa FK composite ngay từ đầu ở bảng roles)
);

-- Seed permissions cơ bản cho module user
INSERT INTO permissions (resource, action, label) VALUES
 ('user','read','Xem danh sách người dùng'),
 ('user','create','Tạo người dùng mới'),
 ('user','update','Cập nhật người dùng'),
 ('user','delete','Xoá người dùng'),
 ('user','assign_role','Gán vai trò cho người dùng')
ON CONFLICT DO NOTHING;

-- Seed role admin cho tenant system
INSERT INTO roles (tenant_id, name, module)
VALUES ('00000000-0000-0000-0000-000000000000', 'admin', 'user')
ON CONFLICT DO NOTHING;

-- Gán toàn bộ quyền user.* vào role admin
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.resource = 'user'
WHERE r.name = 'admin'
  AND r.tenant_id = '00000000-0000-0000-0000-000000000000'
ON CONFLICT DO NOTHING;

-- Seed user admin hệ thống
INSERT INTO users (tenant_id, user_id, email, password_hash, name)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'admin@mailan.net',
  '$2b$12$KFP4bYhbxzhVPcjYME9PTutOJihMrdoqLf8g9do7d9b0om2v6szbO', -- bcrypt demo
  'System Admin'
)
ON CONFLICT DO NOTHING;

-- Tự gán role admin cho user admin (nếu cần, tìm user_id theo email)
INSERT INTO user_roles (tenant_id, user_id, role_id)
SELECT u.tenant_id, u.user_id, r.id
FROM users u
JOIN roles r ON r.tenant_id = u.tenant_id AND r.name = 'admin'
WHERE u.email = 'admin@mailan.net'
  AND u.tenant_id = '00000000-0000-0000-0000-000000000000'
ON CONFLICT DO NOTHING;
