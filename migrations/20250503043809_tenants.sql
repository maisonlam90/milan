-- ============================================================
-- 3) TENANT (CỬA HÀNG/ĐƠN VỊ TRIỂN KHAI) – SHARD KEY
--    - Mọi domain table nên có PRIMARY KEY (tenant_id, ...)
--    - tenant gắn vào 1 company cụ thể trong enterprise
--    - SIẾT: (enterprise_id, company_id) phải khớp company
-- ============================================================

-- (Nếu reset DB từ đầu, tạo bảng trực tiếp như sau)
CREATE TABLE IF NOT EXISTS tenant (
  tenant_id     UUID PRIMARY KEY,                                     -- 🔑 SHARD KEY
  enterprise_id UUID NOT NULL REFERENCES enterprise(enterprise_id),   -- Thuộc enterprise nào
  company_id    UUID,                                                 -- Gắn vào company (có thể NULL khi seed)
  name          TEXT NOT NULL,                                        -- Tên tenant
  slug          TEXT NOT NULL CHECK (slug = lower(slug)),                                        -- Định danh ngắn, unique trong enterprise
  shard_id      TEXT NOT NULL,                                        -- Thông tin shard/cluster
  created_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE (enterprise_id, slug)
);

-- ⭐ Siết ràng buộc: company_id (nếu có) PHẢI thuộc cùng enterprise_id
--   Cần company.uq_company_enterprise_company (enterprise_id, company_id) trước đó.
ALTER TABLE tenant
  DROP CONSTRAINT IF EXISTS tenant_company_id_fkey;  -- nếu schema cũ có FK 1 cột
ALTER TABLE tenant
  ADD CONSTRAINT fk_tenant_company_same_enterprise
  FOREIGN KEY (enterprise_id, company_id)
  REFERENCES company (enterprise_id, company_id)
  ON UPDATE CASCADE
  ON DELETE RESTRICT;

-- Tra cứu nhanh tenants theo company/enterprise
CREATE INDEX IF NOT EXISTS idx_tenant_company     ON tenant(company_id);
CREATE INDEX IF NOT EXISTS idx_tenant_enterprise  ON tenant(enterprise_id);

-- Seed tenant hệ thống (company_id để NULL → FK không bị check, OK)
INSERT INTO tenant (tenant_id, enterprise_id, name, slug, shard_id)
VALUES (
  '00000000-0000-0000-0000-000000000000',           -- tenant system
  '00000000-0000-0000-0000-000000000001',           -- enterprise system
  'System Admin Tenant',
  'mailan.net',
  'admin-cluster'
)
ON CONFLICT DO NOTHING;
