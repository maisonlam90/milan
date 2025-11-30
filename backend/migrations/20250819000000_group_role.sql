-- ============================================================
-- 2.1) ROLE GROUPS (tenant-aware, SHARD BY tenant_id)
--      Cho phép gom nhiều role vào 1 nhóm và gán user theo nhóm
-- ============================================================
CREATE TABLE IF NOT EXISTS role_groups (
  tenant_id   UUID NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  id          UUID NOT NULL DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,            -- ví dụ: 'ops_admins', 'sales_team'
  module      TEXT,                     -- optional: gắn nhóm theo module ('loan','payment'...)
  description TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, name)
);

CREATE INDEX IF NOT EXISTS idx_role_groups_tenant_name
  ON role_groups (tenant_id, name);
CREATE INDEX IF NOT EXISTS idx_role_groups_tenant_module
  ON role_groups (tenant_id, module);

-- Mapping GROUP -> ROLES (mỗi nhóm chứa nhiều role)
CREATE TABLE IF NOT EXISTS role_group_roles (
  tenant_id UUID NOT NULL,
  group_id  UUID NOT NULL,
  role_id   UUID NOT NULL,
  PRIMARY KEY (tenant_id, group_id, role_id),

  -- FK: group đúng tenant
  FOREIGN KEY (tenant_id, group_id)
    REFERENCES role_groups (tenant_id, id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  -- FK: role đúng tenant (matching composite key)
  FOREIGN KEY (tenant_id, role_id)
    REFERENCES roles (tenant_id, id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_role_group_roles_group
  ON role_group_roles (tenant_id, group_id);
CREATE INDEX IF NOT EXISTS idx_role_group_roles_role
  ON role_group_roles (tenant_id, role_id);

-- Gán USER -> GROUP (user tự động thừa hưởng tất cả roles trong group)
CREATE TABLE IF NOT EXISTS user_role_groups (
  tenant_id UUID NOT NULL,
  user_id   UUID NOT NULL,
  group_id  UUID NOT NULL,
  PRIMARY KEY (tenant_id, user_id, group_id),

  -- FK: user đúng tenant
  FOREIGN KEY (tenant_id, user_id)
    REFERENCES users (tenant_id, user_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  -- FK: group đúng tenant
  FOREIGN KEY (tenant_id, group_id)
    REFERENCES role_groups (tenant_id, id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_user_role_groups_user
  ON user_role_groups (tenant_id, user_id);
CREATE INDEX IF NOT EXISTS idx_user_role_groups_group
  ON user_role_groups (tenant_id, group_id);

-- ============================================================
-- 7.1) (SEED MẪU) Tạo nhóm 'sys_admins' và add role 'admin' (tenant hệ thống)
-- ============================================================
DO $$
DECLARE
  t_sys UUID := '00000000-0000-0000-0000-000000000000';
  gid   UUID;
  rid   UUID;
  uid   UUID;
BEGIN
  -- Nhóm sys_admins
  INSERT INTO role_groups (tenant_id, name, module, description)
  VALUES (t_sys, 'sys_admins', 'iam', 'Nhóm quản trị hệ thống')
  ON CONFLICT (tenant_id, name) DO NOTHING;

  SELECT id INTO gid FROM role_groups
  WHERE tenant_id = t_sys AND name = 'sys_admins' LIMIT 1;

  -- Lấy role admin của tenant hệ thống
  SELECT id INTO rid FROM roles
  WHERE tenant_id = t_sys AND name = 'admin' LIMIT 1;

  -- Liên kết group -> role admin
  IF gid IS NOT NULL AND rid IS NOT NULL THEN
    INSERT INTO role_group_roles (tenant_id, group_id, role_id)
    VALUES (t_sys, gid, rid)
    ON CONFLICT DO NOTHING;
  END IF;

  -- (tuỳ chọn) gán user admin vào nhóm
  SELECT user_id INTO uid FROM users
  WHERE tenant_id = t_sys AND lower(email) = lower('admin@mailan.net') LIMIT 1;

  IF gid IS NOT NULL AND uid IS NOT NULL THEN
    INSERT INTO user_role_groups (tenant_id, user_id, group_id)
    VALUES (t_sys, uid, gid)
    ON CONFLICT DO NOTHING;
  END IF;
END $$;
