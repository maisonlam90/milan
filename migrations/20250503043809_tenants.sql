-- ============================================================
-- 3) TENANT (CỬA HÀNG/ĐƠN VỊ TRIỂN KHAI) – SHARD KEY
--    - Mọi domain table nên có PRIMARY KEY (tenant_id, ...)
--    - tenant gắn vào 1 company cụ thể trong enterprise
-- ============================================================
CREATE TABLE IF NOT EXISTS tenant (
  tenant_id     UUID PRIMARY KEY,                                     -- SHARD KEY
  enterprise_id UUID NOT NULL REFERENCES enterprise(enterprise_id),   -- Thuộc enterprise nào
  company_id    UUID REFERENCES company(company_id),                  -- Gắn vào company (nullable trong seed)
  name          TEXT NOT NULL,                                        -- Tên tenant (cửa hàng)
  slug          TEXT NOT NULL,                                        -- Định danh ngắn, unique trong enterprise
  shard_id      TEXT NOT NULL,                                        -- Thông tin shard/cluster
  created_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE (enterprise_id, slug)
);

-- Tra cứu nhanh tenants theo company/enterprise
CREATE INDEX IF NOT EXISTS idx_tenant_company     ON tenant(company_id);
CREATE INDEX IF NOT EXISTS idx_tenant_enterprise  ON tenant(enterprise_id);

-- Seed tenant hệ thống (gắn enterprise system; company_id có thể set sau)
INSERT INTO tenant (tenant_id, enterprise_id, name, slug, shard_id)
VALUES (
  '00000000-0000-0000-0000-000000000000',           -- tenant system
  '00000000-0000-0000-0000-000000000001',           -- enterprise system
  'System Admin Tenant',
  'mailan.net',
  'admin-cluster'
)
ON CONFLICT DO NOTHING;
