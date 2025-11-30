-- ============================================================
-- 📄 INVOICE_LINK MODULE — Add is_default column
-- ============================================================

-- Thêm cột is_default vào provider_credentials
ALTER TABLE provider_credentials 
ADD COLUMN IF NOT EXISTS is_default BOOLEAN NOT NULL DEFAULT false;

-- Index cho is_default
CREATE INDEX IF NOT EXISTS idx_provider_credentials_default 
    ON provider_credentials(tenant_id, provider, is_default) 
    WHERE is_default = true;

-- Comment
COMMENT ON COLUMN provider_credentials.is_default IS 'Đánh dấu credentials mặc định cho provider (hệ thống sẽ tự động xuất hóa đơn vào provider mặc định)';






