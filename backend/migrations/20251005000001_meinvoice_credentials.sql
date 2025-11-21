-- ============================================================
-- 📄 MEINVOICE CREDENTIALS TABLE — Lưu thông tin đăng nhập Meinvoice
-- Multi-tenant with Linear Sharding Architecture
-- ============================================================

-- Meinvoice Credentials Table
-- Lưu thông tin đăng nhập Meinvoice cho mỗi user
CREATE TABLE IF NOT EXISTS meinvoice_credentials (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL,
    user_id UUID NOT NULL,                        -- User sở hữu credentials
    username VARCHAR(255) NOT NULL,               -- Username Meinvoice
    api_key VARCHAR(255) NOT NULL,                -- API Key (có thể mã hóa)
    api_url VARCHAR(500) NOT NULL DEFAULT 'https://api.meinvoice.com.vn',
    token TEXT,                                   -- Token từ Meinvoice (nếu có)
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    PRIMARY KEY (tenant_id, id),
    UNIQUE (tenant_id, user_id)                   -- Mỗi user chỉ có một bộ credentials
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_meinvoice_credentials_user_id ON meinvoice_credentials(tenant_id, user_id);

-- Comments
COMMENT ON TABLE meinvoice_credentials IS 'Lưu thông tin đăng nhập Meinvoice cho mỗi user';
COMMENT ON COLUMN meinvoice_credentials.user_id IS 'User sở hữu credentials';
COMMENT ON COLUMN meinvoice_credentials.username IS 'Username đăng nhập Meinvoice';
COMMENT ON COLUMN meinvoice_credentials.api_key IS 'API Key từ Meinvoice (nên mã hóa)';
COMMENT ON COLUMN meinvoice_credentials.token IS 'Token từ Meinvoice sau khi đăng nhập thành công';

