-- ============================================================
-- 4) MODULE STORE (DANH MỤC MODULE + BẬT MODULE THEO ENTERPRISE/TENANT)
-- ============================================================
CREATE TABLE IF NOT EXISTS available_module (
  module_name  TEXT PRIMARY KEY,                 -- Định danh module
  display_name TEXT NOT NULL,                    -- Tên hiển thị
  description  TEXT,
  metadata     JSONB DEFAULT '{}'                -- Metadata mở rộng (schema, options…)
);

CREATE TABLE IF NOT EXISTS enterprise_module (
  enterprise_id UUID NOT NULL REFERENCES enterprise(enterprise_id) ON DELETE CASCADE,
  module_name   TEXT NOT NULL REFERENCES available_module(module_name),
  config_json   JSONB DEFAULT '{}',
  enabled_at    TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (enterprise_id, module_name)
);

CREATE TABLE IF NOT EXISTS tenant_module (
  tenant_id    UUID NOT NULL REFERENCES tenant(tenant_id) ON DELETE CASCADE,
  module_name  TEXT NOT NULL REFERENCES available_module(module_name),
  config_json  JSONB DEFAULT '{}',               -- Cấu hình override ở tenant
  enabled_at   TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (tenant_id, module_name)
);

CREATE INDEX IF NOT EXISTS idx_tenant_module_tenant_id ON tenant_module (tenant_id);

-- Seed module mẫu
INSERT INTO available_module (module_name, display_name, description) VALUES
  ('user', 'User Management', 'Quản lý người dùng'),
  ('loan', 'Loan', 'Quản lý khoản vay')
ON CONFLICT DO NOTHING;

-- Bật module user ở tenant system
INSERT INTO tenant_module (tenant_id, module_name)
VALUES ('00000000-0000-0000-0000-000000000000', 'user')
ON CONFLICT DO NOTHING;
