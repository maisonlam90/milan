-- ============================================================
-- 📄 INVOICE_LINK MODULE — Link invoices to E-Invoice Providers
-- Multi-tenant with Linear Sharding Architecture
-- Supports multiple providers: Viettel, Mobifone, etc.
-- ============================================================

-- ============================================================
-- 1. PROVIDER CREDENTIALS TABLE
-- ============================================================
-- Lưu thông tin đăng nhập của các provider hóa đơn điện tử
CREATE TABLE IF NOT EXISTS provider_credentials (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL,
    user_id UUID NOT NULL,                          -- User tạo credentials
    provider VARCHAR(50) NOT NULL,                 -- 'viettel', 'mobifone', etc.
    credentials JSONB NOT NULL,                     -- Encrypted credentials (username, password, etc.)
    access_token TEXT,                              -- Access token từ provider API
    token_expires_at TIMESTAMPTZ,                   -- Thời gian hết hạn token
    is_active BOOLEAN NOT NULL DEFAULT true,        -- Credentials có đang active không
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    PRIMARY KEY (tenant_id, id),
    FOREIGN KEY (tenant_id, user_id) REFERENCES users(tenant_id, user_id) ON DELETE CASCADE
);

-- Indexes cho provider_credentials
CREATE INDEX IF NOT EXISTS idx_provider_credentials_tenant_provider 
    ON provider_credentials(tenant_id, provider) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_provider_credentials_user 
    ON provider_credentials(tenant_id, user_id);
CREATE INDEX IF NOT EXISTS idx_provider_credentials_updated_at 
    ON provider_credentials(tenant_id, updated_at DESC);

-- Comments
COMMENT ON TABLE provider_credentials IS 'Thông tin đăng nhập của các provider hóa đơn điện tử';
COMMENT ON COLUMN provider_credentials.provider IS 'Tên provider: viettel, mobifone, etc.';
COMMENT ON COLUMN provider_credentials.credentials IS 'Thông tin đăng nhập dạng JSON (nên được encrypt trước khi lưu)';
COMMENT ON COLUMN provider_credentials.access_token IS 'Access token từ provider API (có thể refresh)';
COMMENT ON COLUMN provider_credentials.token_expires_at IS 'Thời gian hết hạn của access_token';
COMMENT ON COLUMN provider_credentials.is_active IS 'Credentials có đang được sử dụng không';

-- ============================================================
-- 2. INVOICE LINK TABLE
-- ============================================================
-- Lưu thông tin liên kết giữa invoice trong hệ thống và hóa đơn điện tử trên các provider
CREATE TABLE IF NOT EXISTS invoice_link (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL,
    invoice_id UUID NOT NULL,                       -- ID của invoice trong hệ thống
    provider VARCHAR(50) NOT NULL,                 -- 'viettel', 'mobifone', etc.
    provider_invoice_id VARCHAR(255),              -- ID hóa đơn từ provider API
    provider_invoice_number VARCHAR(255),           -- Số hóa đơn từ provider
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- 'pending', 'linked', 'failed'
    error_message TEXT,                             -- Thông báo lỗi nếu có
    request_data JSONB,                            -- Dữ liệu gửi đi đến provider API
    response_data JSONB,                            -- Dữ liệu nhận về từ provider API
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID NOT NULL,                      -- User tạo link
    
    PRIMARY KEY (tenant_id, id),
    FOREIGN KEY (tenant_id, invoice_id) REFERENCES account_move(tenant_id, id) ON DELETE CASCADE,
    FOREIGN KEY (tenant_id, created_by) REFERENCES users(tenant_id, user_id) ON DELETE RESTRICT
);

-- Indexes cho invoice_link
CREATE INDEX IF NOT EXISTS idx_invoice_link_tenant_invoice 
    ON invoice_link(tenant_id, invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_link_provider 
    ON invoice_link(tenant_id, provider);
CREATE INDEX IF NOT EXISTS idx_invoice_link_status 
    ON invoice_link(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_invoice_link_provider_invoice_id 
    ON invoice_link(tenant_id, provider_invoice_id) WHERE provider_invoice_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_invoice_link_created_at 
    ON invoice_link(tenant_id, created_at DESC);

-- Comments
COMMENT ON TABLE invoice_link IS 'Liên kết giữa invoice trong hệ thống và hóa đơn điện tử trên các provider';
COMMENT ON COLUMN invoice_link.invoice_id IS 'ID của invoice trong hệ thống (account_move.id)';
COMMENT ON COLUMN invoice_link.provider IS 'Tên provider: viettel, mobifone, etc.';
COMMENT ON COLUMN invoice_link.provider_invoice_id IS 'ID hóa đơn từ provider API';
COMMENT ON COLUMN invoice_link.provider_invoice_number IS 'Số hóa đơn từ provider';
COMMENT ON COLUMN invoice_link.status IS 'Trạng thái: pending (đang xử lý), linked (đã liên kết thành công), failed (thất bại)';
COMMENT ON COLUMN invoice_link.request_data IS 'Dữ liệu JSON gửi đi đến provider API';
COMMENT ON COLUMN invoice_link.response_data IS 'Dữ liệu JSON nhận về từ provider API';

