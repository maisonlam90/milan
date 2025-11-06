-- ============================================================
-- 📄 INVOICE MODULE — CREATE (Based on Odoo 19 account.move)
-- ============================================================
-- Reference: Odoo 19 addons/account/models/account_move.py
-- Model: account.move (invoice/bill)
-- Model: account.move.line (invoice lines)
-- Model: account.payment (payments)
-- ============================================================

SET TIME ZONE 'UTC';

-- ------------------------------------------------------------
-- 1) HÓA ĐƠN CHÍNH (account_move)
-- ------------------------------------------------------------
CREATE TABLE account_move (
    tenant_id UUID NOT NULL,                                   -- 🔑 shard key
    id        UUID NOT NULL DEFAULT gen_random_uuid(),         -- 🔑 id hóa đơn
    
    -- Thông tin cơ bản
    name                VARCHAR(255) NOT NULL,                         -- Số hóa đơn (INV/001, BILL/001, etc.)
    move_type           VARCHAR(50) NOT NULL,                   -- out_invoice, in_invoice, out_refund, in_refund, entry
    partner_id          UUID,                         -- Khách hàng/Nhà cung cấp (contact_id)
    
    -- Trạng thái
    state               VARCHAR(50) NOT NULL DEFAULT 'draft',   -- draft, posted, cancel
    payment_state       VARCHAR(50) NOT NULL DEFAULT 'not_paid',-- not_paid, in_payment, paid, partial, reversed
    
    -- Ngày tháng
    invoice_date        DATE NOT NULL,                          -- Ngày hóa đơn
    invoice_date_due    DATE,                                   -- Ngày đến hạn thanh toán
    date                DATE,                                   -- Ngày ghi sổ (accounting date)
    
    -- Tham chiếu
    ref                 VARCHAR(255),                           -- Vendor reference / Mã tham chiếu
    payment_reference   VARCHAR(255),                           -- Mã thanh toán
    
    -- Tiền tệ & Kế toán
    currency_id         VARCHAR(10) NOT NULL DEFAULT 'VND',     -- VND, USD, EUR, etc.
    journal_id          UUID,                                   -- Sổ nhật ký kế toán
    fiscal_position_id  UUID,                                   -- Vị thế thuế (tax mapping)
    payment_term_id     UUID,                                   -- Điều khoản thanh toán
    
    -- Số tiền (stored computed fields)
    amount_untaxed      BIGINT NOT NULL DEFAULT 0,              -- Tổng trước thuế
    amount_tax          BIGINT NOT NULL DEFAULT 0,              -- Tổng thuế
    amount_total        BIGINT NOT NULL DEFAULT 0,              -- Tổng cộng
    amount_residual     BIGINT NOT NULL DEFAULT 0,              -- Còn nợ
    
    -- Ghi chú
    narration           TEXT,                                   -- Ghi chú (notes)
    
    -- Metadata
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- IAM fields (phân quyền)
    created_by          UUID NOT NULL,
    assignee_id         UUID,
    shared_with         UUID[] DEFAULT '{}',
    
    PRIMARY KEY (tenant_id, id)
);

-- Index tối ưu
CREATE INDEX idx_account_move_tenant              ON account_move (tenant_id);
CREATE INDEX idx_account_move_tenant_name         ON account_move (tenant_id, name);
CREATE INDEX idx_account_move_tenant_partner      ON account_move (tenant_id, partner_id);
CREATE INDEX idx_account_move_tenant_state        ON account_move (tenant_id, state);
CREATE INDEX idx_account_move_tenant_payment_state ON account_move (tenant_id, payment_state);
CREATE INDEX idx_account_move_tenant_type         ON account_move (tenant_id, move_type);
CREATE INDEX idx_account_move_tenant_dates        ON account_move (tenant_id, invoice_date, invoice_date_due);

-- Index IAM
CREATE INDEX idx_account_move_created_by ON account_move(tenant_id, created_by);
CREATE INDEX idx_account_move_assignee   ON account_move(tenant_id, assignee_id);
CREATE INDEX idx_account_move_shared     ON account_move USING GIN(shared_with);

-- Trigger updated_at
CREATE OR REPLACE FUNCTION trg_account_move_set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

CREATE TRIGGER account_move_set_updated_at
BEFORE UPDATE ON account_move
FOR EACH ROW
EXECUTE FUNCTION trg_account_move_set_updated_at();

-- Tạo số hóa đơn tự động (giống loan)
CREATE TABLE IF NOT EXISTS invoice_counters_monthly (
  tenant_id  UUID NOT NULL,
  move_type  VARCHAR(50) NOT NULL,  -- out_invoice, in_invoice, etc.
  period_ym  INT  NOT NULL,          -- YYYYMM
  counter    BIGINT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, move_type, period_ym)
);

-- UNIQUE INDEX cho invoice number
CREATE UNIQUE INDEX IF NOT EXISTS uq_account_move_tenant_name
ON account_move (tenant_id, name) WHERE name IS NOT NULL;

-- ------------------------------------------------------------
-- 2) CHI TIẾT HÓA ĐƠN (account_move_line)
-- ------------------------------------------------------------
CREATE TABLE account_move_line (
    tenant_id   UUID NOT NULL,
    id          UUID NOT NULL DEFAULT gen_random_uuid(),
    move_id     UUID NOT NULL,                                 -- FK to account_move
    
    -- Thông tin sản phẩm/dịch vụ
    name        TEXT NOT NULL,                                 -- Mô tả (description)
    product_id  UUID,                                          -- ID sản phẩm (nếu có)
    
    -- Số lượng & Giá
    quantity            NUMERIC(16,4) NOT NULL DEFAULT 1.0,    -- Số lượng
    price_unit          BIGINT NOT NULL DEFAULT 0,             -- Đơn giá
    discount            NUMERIC(5,2) DEFAULT 0.00,             -- Giảm giá (%)
    
    -- Số tiền (stored computed)
    price_subtotal      BIGINT NOT NULL DEFAULT 0,             -- Tổng trước thuế
    price_total         BIGINT NOT NULL DEFAULT 0,             -- Tổng sau thuế
    
    -- Kế toán
    account_id          UUID,                                  -- Tài khoản kế toán
    analytic_distribution JSONB,                               -- Phân bổ chi phí phân tích
    
    -- Metadata
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- IAM fields
    created_by   UUID NOT NULL,
    
    PRIMARY KEY (tenant_id, id),
    
    CONSTRAINT fk_account_move_line_move
      FOREIGN KEY (tenant_id, move_id)
      REFERENCES account_move (tenant_id, id)
      ON DELETE CASCADE
);

-- Index tối ưu
CREATE INDEX idx_account_move_line_tenant     ON account_move_line (tenant_id);
CREATE INDEX idx_account_move_line_move       ON account_move_line (tenant_id, move_id);
CREATE INDEX idx_account_move_line_product    ON account_move_line (tenant_id, product_id);
CREATE INDEX idx_account_move_line_account    ON account_move_line (tenant_id, account_id);

-- GIN index for analytic_distribution
CREATE INDEX idx_account_move_line_analytic ON account_move_line USING GIN(analytic_distribution);

-- Trigger updated_at
CREATE OR REPLACE FUNCTION trg_account_move_line_set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

CREATE TRIGGER account_move_line_set_updated_at
BEFORE UPDATE ON account_move_line
FOR EACH ROW
EXECUTE FUNCTION trg_account_move_line_set_updated_at();

-- ------------------------------------------------------------
-- 3) THUẾ (account_tax)
-- ------------------------------------------------------------
CREATE TABLE account_tax (
    tenant_id   UUID NOT NULL,
    id          UUID NOT NULL DEFAULT gen_random_uuid(),
    
    name                VARCHAR(255) NOT NULL,                 -- Tên thuế (VAT 10%, VAT 5%, etc.)
    amount_type         VARCHAR(50) NOT NULL DEFAULT 'percent',-- percent, fixed, division
    amount              NUMERIC(16,4) NOT NULL DEFAULT 0,      -- Tỷ lệ % hoặc số tiền
    
    -- Loại thuế
    type_tax_use        VARCHAR(50) NOT NULL DEFAULT 'sale',   -- sale, purchase, none
    price_include       BOOLEAN DEFAULT FALSE,                 -- Giá đã bao gồm thuế
    
    -- Tài khoản
    account_id          UUID,                                  -- Tài khoản thuế
    refund_account_id   UUID,                                  -- Tài khoản thuế hoàn trả
    
    -- Metadata
    active      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by  UUID NOT NULL,
    
    PRIMARY KEY (tenant_id, id)
);

CREATE INDEX idx_account_tax_tenant ON account_tax (tenant_id);
CREATE INDEX idx_account_tax_type   ON account_tax (tenant_id, type_tax_use);

-- ------------------------------------------------------------
-- 4) BẢNG LIÊN KẾT: INVOICE LINE <-> TAX (Many-to-Many)
-- ------------------------------------------------------------
CREATE TABLE account_move_line_tax_rel (
    tenant_id           UUID NOT NULL,
    move_line_id        UUID NOT NULL,
    tax_id              UUID NOT NULL,
    
    PRIMARY KEY (tenant_id, move_line_id, tax_id),
    
    CONSTRAINT fk_move_line_tax_line
      FOREIGN KEY (tenant_id, move_line_id)
      REFERENCES account_move_line (tenant_id, id)
      ON DELETE CASCADE,
      
    CONSTRAINT fk_move_line_tax_tax
      FOREIGN KEY (tenant_id, tax_id)
      REFERENCES account_tax (tenant_id, id)
      ON DELETE CASCADE
);

CREATE INDEX idx_move_line_tax_line ON account_move_line_tax_rel (tenant_id, move_line_id);
CREATE INDEX idx_move_line_tax_tax  ON account_move_line_tax_rel (tenant_id, tax_id);

-- ------------------------------------------------------------
-- 5) THANH TOÁN (account_payment)
-- ------------------------------------------------------------
CREATE TABLE account_payment (
    tenant_id   UUID NOT NULL,
    id          UUID NOT NULL DEFAULT gen_random_uuid(),
    
    -- Thông tin thanh toán
    payment_type        VARCHAR(50) NOT NULL,                  -- inbound, outbound
    partner_type        VARCHAR(50) NOT NULL,                  -- customer, supplier
    partner_id          UUID NOT NULL,                         -- Khách hàng/Nhà cung cấp
    
    amount              BIGINT NOT NULL,                       -- Số tiền
    payment_date        DATE NOT NULL,                         -- Ngày thanh toán
    currency_id         VARCHAR(10) NOT NULL DEFAULT 'VND',
    
    -- Phương thức & Sổ
    payment_method_id   UUID,                                  -- Phương thức thanh toán
    journal_id          UUID,                                  -- Sổ ngân hàng/tiền mặt
    
    -- Tham chiếu
    communication       TEXT,                                  -- Memo / Thông tin thanh toán
    ref                 VARCHAR(255),                          -- Mã tham chiếu
    
    -- Trạng thái
    state               VARCHAR(50) NOT NULL DEFAULT 'draft',  -- draft, posted, sent, reconciled, cancelled
    
    -- Metadata
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by  UUID NOT NULL,
    
    PRIMARY KEY (tenant_id, id)
);

CREATE INDEX idx_account_payment_tenant     ON account_payment (tenant_id);
CREATE INDEX idx_account_payment_partner    ON account_payment (tenant_id, partner_id);
CREATE INDEX idx_account_payment_date       ON account_payment (tenant_id, payment_date);
CREATE INDEX idx_account_payment_state      ON account_payment (tenant_id, state);

-- Trigger updated_at
CREATE OR REPLACE FUNCTION trg_account_payment_set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

CREATE TRIGGER account_payment_set_updated_at
BEFORE UPDATE ON account_payment
FOR EACH ROW
EXECUTE FUNCTION trg_account_payment_set_updated_at();

-- ------------------------------------------------------------
-- 6) LIÊN KẾT: INVOICE <-> PAYMENT (Many-to-Many)
-- ------------------------------------------------------------
CREATE TABLE account_move_payment_rel (
    tenant_id   UUID NOT NULL,
    move_id     UUID NOT NULL,
    payment_id  UUID NOT NULL,
    amount      BIGINT NOT NULL DEFAULT 0,                     -- Số tiền thanh toán cho invoice này
    
    PRIMARY KEY (tenant_id, move_id, payment_id),
    
    CONSTRAINT fk_move_payment_move
      FOREIGN KEY (tenant_id, move_id)
      REFERENCES account_move (tenant_id, id)
      ON DELETE CASCADE,
      
    CONSTRAINT fk_move_payment_payment
      FOREIGN KEY (tenant_id, payment_id)
      REFERENCES account_payment (tenant_id, id)
      ON DELETE CASCADE
);

CREATE INDEX idx_move_payment_move    ON account_move_payment_rel (tenant_id, move_id);
CREATE INDEX idx_move_payment_payment ON account_move_payment_rel (tenant_id, payment_id);

-- ------------------------------------------------------------
-- 7) ĐIỀU KHOẢN THANH TOÁN (account_payment_term)
-- ------------------------------------------------------------
CREATE TABLE account_payment_term (
    tenant_id   UUID NOT NULL,
    id          UUID NOT NULL DEFAULT gen_random_uuid(),
    
    name        VARCHAR(255) NOT NULL,                         -- Tên (Net 30, Net 60, etc.)
    note        TEXT,                                          -- Mô tả
    
    -- Metadata
    active      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by  UUID NOT NULL,
    
    PRIMARY KEY (tenant_id, id)
);

CREATE INDEX idx_payment_term_tenant ON account_payment_term (tenant_id);

-- ------------------------------------------------------------
-- 8) CHI TIẾT ĐIỀU KHOẢN THANH TOÁN (account_payment_term_line)
-- ------------------------------------------------------------
CREATE TABLE account_payment_term_line (
    tenant_id           UUID NOT NULL,
    id                  UUID NOT NULL DEFAULT gen_random_uuid(),
    payment_term_id     UUID NOT NULL,
    
    value               VARCHAR(50) NOT NULL DEFAULT 'balance', -- percent, balance, fixed
    value_amount        NUMERIC(16,4) DEFAULT 0,                -- Giá trị (% hoặc số tiền)
    nb_days             INT DEFAULT 0,                          -- Số ngày
    
    PRIMARY KEY (tenant_id, id),
    
    CONSTRAINT fk_payment_term_line_term
      FOREIGN KEY (tenant_id, payment_term_id)
      REFERENCES account_payment_term (tenant_id, id)
      ON DELETE CASCADE
);

CREATE INDEX idx_payment_term_line_term ON account_payment_term_line (tenant_id, payment_term_id);

-- ------------------------------------------------------------
-- 9) SỔ NHẬT KÝ KẾ TOÁN (account_journal)
-- ------------------------------------------------------------
CREATE TABLE account_journal (
    tenant_id   UUID NOT NULL,
    id          UUID NOT NULL DEFAULT gen_random_uuid(),
    
    name        VARCHAR(255) NOT NULL,                         -- Tên sổ
    code        VARCHAR(50) NOT NULL,                          -- Mã sổ (INV, BILL, BANK, CASH)
    type        VARCHAR(50) NOT NULL,                          -- sale, purchase, cash, bank, general
    
    currency_id VARCHAR(10) DEFAULT 'VND',
    
    -- Metadata
    active      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by  UUID NOT NULL,
    
    PRIMARY KEY (tenant_id, id)
);

CREATE INDEX idx_account_journal_tenant ON account_journal (tenant_id);
CREATE INDEX idx_account_journal_type   ON account_journal (tenant_id, type);
CREATE UNIQUE INDEX idx_account_journal_code ON account_journal (tenant_id, code);

-- ------------------------------------------------------------
-- 10) PHƯƠNG THỨC THANH TOÁN (account_payment_method)
-- ------------------------------------------------------------
CREATE TABLE account_payment_method (
    tenant_id   UUID NOT NULL,
    id          UUID NOT NULL DEFAULT gen_random_uuid(),
    
    name        VARCHAR(255) NOT NULL,                         -- Tên (Cash, Bank Transfer, etc.)
    code        VARCHAR(50) NOT NULL,                          -- Mã (manual, electronic, check)
    payment_type VARCHAR(50) NOT NULL,                         -- inbound, outbound
    
    -- Metadata
    active      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by  UUID NOT NULL,
    
    PRIMARY KEY (tenant_id, id)
);

CREATE INDEX idx_payment_method_tenant ON account_payment_method (tenant_id);
CREATE INDEX idx_payment_method_type   ON account_payment_method (tenant_id, payment_type);

-- ------------------------------------------------------------
-- 11) VỊ THẾ THUẾ (account_fiscal_position) - Tax Mapping
-- ------------------------------------------------------------
CREATE TABLE account_fiscal_position (
    tenant_id   UUID NOT NULL,
    id          UUID NOT NULL DEFAULT gen_random_uuid(),
    
    name        VARCHAR(255) NOT NULL,                         -- Tên
    note        TEXT,                                          -- Mô tả
    
    -- Metadata
    active      BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by  UUID NOT NULL,
    
    PRIMARY KEY (tenant_id, id)
);

CREATE INDEX idx_fiscal_position_tenant ON account_fiscal_position (tenant_id);

-- ============================================================
-- 📊 VIEWS & FUNCTIONS
-- ============================================================

-- View: Danh sách invoice với thông tin partner
CREATE OR REPLACE VIEW v_account_move_list AS
SELECT 
    am.tenant_id,
    am.id,
    am.name,
    am.move_type,
    am.partner_id,
    c.name AS partner_name,
    am.state,
    am.payment_state,
    am.invoice_date,
    am.invoice_date_due,
    am.amount_untaxed,
    am.amount_tax,
    am.amount_total,
    am.amount_residual,
    am.currency_id,
    am.created_at,
    am.updated_at
FROM account_move am
LEFT JOIN contact c ON am.tenant_id = c.tenant_id AND am.partner_id = c.id;

-- ============================================================
-- ✅ DONE: Invoice Module Database Schema
-- ============================================================
-- Tables created:
-- 1. account_move (invoice/bill)
-- 2. account_move_line (invoice lines)
-- 3. account_tax (taxes)
-- 4. account_move_line_tax_rel (line <-> tax)
-- 5. account_payment (payments)
-- 6. account_move_payment_rel (invoice <-> payment)
-- 7. account_payment_term (payment terms)
-- 8. account_payment_term_line (payment term lines)
-- 9. account_journal (journals)
-- 10. account_payment_method (payment methods)
-- 11. account_fiscal_position (fiscal positions)
-- ============================================================

