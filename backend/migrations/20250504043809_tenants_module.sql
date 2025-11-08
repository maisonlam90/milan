-- ============================================================
-- 4) MODULE STORE (DANH MỤC MODULE + BẬT MODULE THEO ENTERPRISE/TENANT)
--  - Siết: tenant chỉ bật module nếu enterprise đã bật module đó
--  - Đồng bộ enterprise_id vào tenant_module bằng trigger
-- ============================================================

CREATE TABLE IF NOT EXISTS available_module (
  module_name  TEXT PRIMARY KEY,                 -- Định danh module
  display_name TEXT NOT NULL,                    -- Tên hiển thị
  description  TEXT,
  metadata     JSONB DEFAULT '{}'                -- Metadata mở rộng (schema, options…)
);

CREATE TABLE IF NOT EXISTS tenant_enterprise_module (
  enterprise_id UUID NOT NULL REFERENCES tenant_enterprise(enterprise_id) ON DELETE CASCADE,
  module_name   TEXT NOT NULL REFERENCES available_module(module_name),
  config_json   JSONB DEFAULT '{}',
  enabled_at    TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (enterprise_id, module_name)
);

-- ⭐ Thêm enterprise_id vào tenant_module để tạo FK tới tenant_enterprise_module
CREATE TABLE IF NOT EXISTS tenant_module (
  tenant_id     UUID NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  enterprise_id UUID NOT NULL,                              -- denormalize, auto-fill từ tenant
  module_name   TEXT NOT NULL REFERENCES available_module(module_name),
  config_json   JSONB DEFAULT '{}',                         -- Cấu hình override ở tenant
  enabled_at    TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (tenant_id, module_name),

  -- Chặn bật module ở tenant nếu enterprise chưa bật
  FOREIGN KEY (enterprise_id, module_name)
    REFERENCES tenant_enterprise_module (enterprise_id, module_name)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_tenant_module_tenant_id ON tenant_module (tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_module_enterprise ON tenant_module (enterprise_id);

-- Trigger: tự đồng bộ tenant_module.enterprise_id = tenant.enterprise_id
CREATE OR REPLACE FUNCTION trg_fill_tenant_module_eid()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE v_eid UUID;
BEGIN
  SELECT t.enterprise_id INTO v_eid
  FROM tenant t
  WHERE t.tenant_id = NEW.tenant_id;

  IF v_eid IS NULL THEN
    RAISE EXCEPTION 'Tenant % không tồn tại', NEW.tenant_id;
  END IF;

  -- Ghi đè enterprise_id cho đúng nguồn chân lý
  NEW.enterprise_id := v_eid;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS tenant_module_fill_eid ON tenant_module;
CREATE TRIGGER tenant_module_fill_eid
BEFORE INSERT OR UPDATE ON tenant_module
FOR EACH ROW
EXECUTE FUNCTION trg_fill_tenant_module_eid();

-- ===========================
-- Seed module mẫu
-- ===========================
INSERT INTO available_module (module_name, display_name, description) VALUES
  ('tenant', 'Tenant', 'Quản lý tenant'),
  ('iam', 'iam', 'Quản lý phân quyền'),
  ('user', 'User Management', 'Quản lý người dùng')
ON CONFLICT DO NOTHING;

-- Bật module 'user' ở enterprise system (để tenant system có thể bật)
INSERT INTO tenant_enterprise_module (enterprise_id, module_name)
VALUES ('00000000-0000-0000-0000-000000000001', 'user')
ON CONFLICT DO NOTHING;

-- Bật module 'user' ở tenant system
INSERT INTO tenant_module (tenant_id, enterprise_id, module_name)
VALUES ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000001', 'user')
ON CONFLICT DO NOTHING;
