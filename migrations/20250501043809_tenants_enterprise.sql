-- ============================================================
-- 🏢 Multi-tenant Sharded Schema: Enterprise → Company (multi-level) → Tenant→ modules/RBAC → users
-- - Shard theo tenant_id (KHÔNG shard theo enterprise/company)
-- - Company nhiều cấp dùng Closure Table (company_edge)
-- - Modules & RBAC theo tenant
-- - Có seed tối thiểu để khởi động môi trường dev
-- ============================================================
-- ============================================================
-- 1) ENTERPRISE: Tập đoàn / Thương hiệu cha
-- ============================================================
CREATE TABLE IF NOT EXISTS enterprise (
  enterprise_id UUID PRIMARY KEY,                -- ID duy nhất enterprise
  name          TEXT NOT NULL,                   -- Tên enterprise
  slug          TEXT UNIQUE,                     -- Định danh ngắn, unique toàn hệ thống
  created_at    TIMESTAMPTZ DEFAULT now()        -- Thời điểm tạo
);

-- Seed enterprise hệ thống (UUID cố định để dễ tham chiếu)
INSERT INTO enterprise (enterprise_id, name, slug)
VALUES ('00000000-0000-0000-0000-000000000001', 'System Enterprise', 'system')
ON CONFLICT DO NOTHING;
