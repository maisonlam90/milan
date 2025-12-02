-- ============================================================
-- 📄 INVOICE_LINK MODULE — Add is_default & Fix FK constraint
-- ============================================================

-- Bỏ foreign key constraint với bảng users
-- Vì credentials thuộc về tenant, không cần ràng buộc chặt chẽ với user
ALTER TABLE invoice_link_provider_credentials
DROP CONSTRAINT IF EXISTS invoice_link_provider_credentials_tenant_id_user_id_fkey;

-- Thêm cột is_default vào invoice_link_provider_credentials
ALTER TABLE invoice_link_provider_credentials 
ADD COLUMN IF NOT EXISTS is_default BOOLEAN NOT NULL DEFAULT false;

-- Index cho is_default
CREATE INDEX IF NOT EXISTS idx_invoice_link_provider_credentials_default 
    ON invoice_link_provider_credentials(tenant_id, provider, is_default) 
    WHERE is_default = true;

-- Comments
COMMENT ON COLUMN invoice_link_provider_credentials.user_id IS 'User tạo credentials (không có foreign key constraint)';
COMMENT ON COLUMN invoice_link_provider_credentials.is_default IS 'Đánh dấu credentials mặc định cho provider (hệ thống sẽ tự động xuất hóa đơn vào provider mặc định)';



