-- ============================================================
-- 🏢 Multi-tenant Sharded Schema: Enterprise → Company → Tenant
-- - Shard theo tenant_id (KHÔNG shard enterprise/company)
-- - Ràng buộc "đúng enterprise" sẽ được SIẾT ở company.sql & tenant.sql
-- ============================================================

-- (Tuỳ chọn/YugabyteDB) gom meta tables vào 1 TABLEGROUP để FK lookup rẻ
-- CREATE TABLEGROUP IF NOT EXISTS meta_group;

-- 1) ENTERPRISE
CREATE TABLE IF NOT EXISTS enterprise (
  enterprise_id UUID PRIMARY KEY,                -- ID duy nhất enterprise
  name          TEXT NOT NULL,                   -- Tên enterprise
  slug          TEXT UNIQUE,                     -- Định danh ngắn, unique toàn hệ thống
  created_at    TIMESTAMPTZ DEFAULT now()        -- Thời điểm tạo
  -- ) TABLEGROUP meta_group                     -- (Tuỳ chọn/YB)
);

-- Seed enterprise hệ thống (UUID cố định để dễ tham chiếu)
INSERT INTO enterprise (enterprise_id, name, slug)
VALUES ('00000000-0000-0000-0000-000000000001', 'System Enterprise', 'system')
ON CONFLICT DO NOTHING;
