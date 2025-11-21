-- ============================================================
-- 📄 INVOICE_LINK MODULE — Link invoices to Meinvoice E-Invoice System
-- Multi-tenant with Linear Sharding Architecture
-- ============================================================

-- Invoice Link Table
-- Lưu thông tin liên kết giữa invoice trong hệ thống và hóa đơn điện tử trên Meinvoice
CREATE TABLE IF NOT EXISTS invoice_link (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL,
    invoice_id UUID NOT NULL,                    -- ID của invoice trong hệ thống
    meinvoice_invoice_id VARCHAR(255),           -- ID hóa đơn từ Meinvoice API
    meinvoice_invoice_number VARCHAR(255),       -- Số hóa đơn từ Meinvoice
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- 'pending', 'sent', 'success', 'failed'
    error_message TEXT,                          -- Thông báo lỗi nếu có
    request_data JSONB,                          -- Dữ liệu gửi đi đến Meinvoice
    response_data JSONB,                         -- Dữ liệu nhận về từ Meinvoice
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID NOT NULL,                    -- User tạo link
    
    PRIMARY KEY (tenant_id, id),
    FOREIGN KEY (tenant_id, invoice_id) REFERENCES account_move(tenant_id, id) ON DELETE CASCADE
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_invoice_link_invoice_id ON invoice_link(tenant_id, invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_link_status ON invoice_link(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_invoice_link_meinvoice_id ON invoice_link(tenant_id, meinvoice_invoice_id) WHERE meinvoice_invoice_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_invoice_link_created_at ON invoice_link(tenant_id, created_at DESC);

-- Comments
COMMENT ON TABLE invoice_link IS 'Liên kết giữa invoice trong hệ thống và hóa đơn điện tử trên Meinvoice';
COMMENT ON COLUMN invoice_link.invoice_id IS 'ID của invoice trong hệ thống (account_move.id)';
COMMENT ON COLUMN invoice_link.meinvoice_invoice_id IS 'ID hóa đơn từ Meinvoice API';
COMMENT ON COLUMN invoice_link.meinvoice_invoice_number IS 'Số hóa đơn từ Meinvoice';
COMMENT ON COLUMN invoice_link.status IS 'Trạng thái: pending, sent, success, failed';
COMMENT ON COLUMN invoice_link.request_data IS 'Dữ liệu JSON gửi đi đến Meinvoice API';
COMMENT ON COLUMN invoice_link.response_data IS 'Dữ liệu JSON nhận về từ Meinvoice API';

