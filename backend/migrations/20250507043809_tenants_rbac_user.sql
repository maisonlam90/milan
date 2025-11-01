
-- ============================================================
-- 2) ROLES (tenant-aware, SHARD BY tenant_id)
--    PK = (tenant_id, id) để đồng định tuyến với users/user_roles
--    module: dùng cho vai trò "chính" của role, nhưng QUYỀN TRUY CẬP MENU
--            quyết định dựa vào permission 'module.*.access'
-- ============================================================
CREATE TABLE IF NOT EXISTS roles (
  tenant_id  UUID NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  id         UUID NOT NULL DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,      -- admin, staff, auditor...
  module     TEXT NOT NULL,      -- ví dụ: 'user' | 'payment' | 'loan' | 'iam'
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, name)
);

-- Truy vấn theo tenant + name / module
CREATE INDEX IF NOT EXISTS idx_roles_tenant_name   ON roles(tenant_id, name);
CREATE INDEX IF NOT EXISTS idx_roles_tenant_module ON roles(tenant_id, module);

-- ============================================================
-- 3) ROLE <-> PERMISSION (global permission pool)
-- ============================================================
CREATE TABLE IF NOT EXISTS role_permissions (
  role_id       UUID NOT NULL,  -- tham chiếu roles.id (id cục bộ trong tenant)
  permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);
-- (Tuỳ chọn) tra cứu ngược theo permission
-- CREATE INDEX IF NOT EXISTS idx_role_permissions_perm ON role_permissions(permission_id);

-- ============================================================
-- 4) USERS (tenant-aware, SHARD BY tenant_id)
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
  tenant_id     UUID NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  user_id       UUID NOT NULL,
  email         TEXT NOT NULL CHECK (email = lower(email)),
  password_hash TEXT NOT NULL,
  name          TEXT,
  created_at    TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (tenant_id, user_id)
);

-- Email unique theo tenant, KHÔNG phân biệt hoa–thường
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_tenant_email_norm
  ON users (tenant_id, lower(email));

CREATE INDEX IF NOT EXISTS idx_users_tenant_created_at
  ON users(tenant_id, created_at);

-- ============================================================
-- 5) USER <-> ROLE (tenant-aware, SIẾT CHẶT)
--    FK COMPOSITE đảm bảo role cùng tenant với user
-- ============================================================
CREATE TABLE IF NOT EXISTS user_roles (
  tenant_id UUID NOT NULL,      -- cùng tenant với user & role
  user_id   UUID NOT NULL,
  role_id   UUID NOT NULL,      -- tham chiếu roles.id (đã đồng-tenant qua FK composite)
  PRIMARY KEY (tenant_id, user_id, role_id),

  -- FK: user phải thuộc đúng tenant
  FOREIGN KEY (tenant_id, user_id)
    REFERENCES users (tenant_id, user_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  -- FK COMPOSITE: role cũng phải thuộc CHÍNH tenant đó
  FOREIGN KEY (tenant_id, role_id)
    REFERENCES roles (tenant_id, id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_user_roles_tenant_user ON user_roles(tenant_id, user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_tenant_role ON user_roles(tenant_id, role_id);

-- ============================================================
-- 6) SEED CƠ BẢN CHO TENANT HỆ THỐNG
--    - Tenant system = 00000000-0000-0000-0000-000000000000
--    - Tạo admin có đầy đủ quyền user.* và quyền truy cập tất cả module.*.access
-- ============================================================
-- Role admin (module đặt 'iam' chỉ để mô tả; quyền menu dựa trên permissions)
INSERT INTO roles (tenant_id, name, module)
VALUES ('00000000-0000-0000-0000-000000000000', 'admin', 'iam')
ON CONFLICT (tenant_id, name) DO NOTHING;

-- Gán toàn bộ quyền user.* cho admin
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.resource = 'user'
WHERE r.name = 'admin'
  AND r.tenant_id = '00000000-0000-0000-0000-000000000000'
ON CONFLICT DO NOTHING;

-- Gán quyền truy cập TẤT CẢ module.*.access cho admin
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.resource LIKE 'module.%' AND p.action = 'access'
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

-- Tự gán role admin cho user admin (theo tenant)
INSERT INTO user_roles (tenant_id, user_id, role_id)
SELECT u.tenant_id, u.user_id, r.id
FROM users u
JOIN roles r
  ON r.tenant_id = u.tenant_id
 AND r.name = 'admin'
WHERE u.email = 'admin@mailan.net'
  AND u.tenant_id = '00000000-0000-0000-0000-000000000000'
ON CONFLICT DO NOTHING;

-- ============================================================
-- 7) (TÙY CHỌN) SEED VÍ DỤ ROLE "staff_payment" CHỈ ĐƯỢC VÀO PAYMENT
--    - Dùng để test ẩn/hiện menu payment
-- ============================================================
DO $$
DECLARE rid UUID;
BEGIN
  -- role
  INSERT INTO roles (tenant_id, name, module)
  VALUES ('00000000-0000-0000-0000-000000000000', 'staff_payment', 'payment')
  ON CONFLICT (tenant_id, name) DO NOTHING;

  -- lấy id role vừa (hoặc đã) tạo
  SELECT id INTO rid FROM roles
   WHERE tenant_id = '00000000-0000-0000-0000-000000000000'
     AND name = 'staff_payment'
   LIMIT 1;

  -- chỉ cấp quyền vào module.payment (menu Payment xuất hiện)
  INSERT INTO role_permissions (role_id, permission_id)
  SELECT rid, p.id
  FROM permissions p
  WHERE p.resource = 'module.payment' AND p.action = 'access'
  ON CONFLICT DO NOTHING;

  -- (tuỳ chọn) cấp thêm user.read nếu cần xem danh sách user
  -- INSERT INTO role_permissions (role_id, permission_id)
  -- SELECT rid, p.id FROM permissions p
  -- WHERE p.resource = 'user' AND p.action = 'read'
  -- ON CONFLICT DO NOTHING;
END $$;