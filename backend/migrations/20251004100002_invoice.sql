-- ============================================================
-- 📄 INVOICE MODULE — COMPLETE ACCOUNTING SYSTEM (78+ Tables)
-- Based on Odoo 17 Accounting Module
-- Compatible with YugabyteDB (PostgreSQL-based)
-- Multi-tenant with Linear Sharding Architecture
-- ============================================================
-- 
-- Table Categories:
-- 1. Chart of Accounts (Account, Group, Type, Tag)
-- 2. Journal & Journal Groups
-- 3. Tax System (Tax, Tax Group, Repartition)
-- 4. Invoice/Entry (Move, Move Line)
-- 5. Payment System (Payment, Payment Method, Payment Term)
-- 6. Reconciliation (Full, Partial, Model)
-- 7. Bank Statement
-- 8. Analytic Accounting (Plan, Account, Line, Distribution)
-- 9. Fiscal Position
-- 10. Reporting (Report, Report Line, Report Column, Expression)
-- 11. Wizards & Helpers
-- 12. Additional Features
-- ============================================================

-- ============================================================
-- SECTION 1: CHART OF ACCOUNTS
-- ============================================================

-- 1.1 Account Type (Loại tài khoản)
CREATE TABLE IF NOT EXISTS account_type (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  code VARCHAR(50) NOT NULL,
  name TEXT NOT NULL,
  internal_group VARCHAR(50), -- 'asset', 'liability', 'equity', 'income', 'expense', 'off_balance'
  include_initial_balance BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, code)
);

-- 1.2 Account Group (Nhóm tài khoản)
CREATE TABLE IF NOT EXISTS account_group (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  parent_id UUID,
  code_prefix_start VARCHAR(50),
  code_prefix_end VARCHAR(50),
  name TEXT NOT NULL,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_account_group_parent
    FOREIGN KEY (tenant_id, parent_id)
    REFERENCES account_group(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_account_group_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT,
  CONSTRAINT chk_group_prefix_length 
    CHECK (
      LENGTH(COALESCE(code_prefix_start, '')) = LENGTH(COALESCE(code_prefix_end, ''))
    )
);

CREATE INDEX IF NOT EXISTS idx_account_group_parent ON account_group(tenant_id, parent_id);

-- 1.3 Account Tag (Thẻ tài khoản - cho báo cáo)
CREATE TABLE IF NOT EXISTS account_account_tag (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  applicability VARCHAR(20) NOT NULL, -- 'accounts', 'taxes', 'products'
  country_id UUID,
  color INTEGER DEFAULT 0,
  active BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_account_tag_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

-- 1.4 Account (Tài khoản kế toán)
CREATE TABLE IF NOT EXISTS account_account (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  code VARCHAR(50) NOT NULL,
  name TEXT NOT NULL,
  account_type VARCHAR(50) NOT NULL, -- 'asset_receivable', 'asset_cash', 'liability_payable', 'expense', 'income', etc.
  internal_group VARCHAR(50), -- 'asset', 'liability', 'equity', 'income', 'expense'
  group_id UUID,
  currency_id UUID,
  reconcile BOOLEAN DEFAULT FALSE, -- Cho phép đối soát
  deprecated BOOLEAN DEFAULT FALSE,
  non_trade BOOLEAN DEFAULT FALSE,
  note TEXT,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, code),
  
  CONSTRAINT fk_account_group
    FOREIGN KEY (tenant_id, group_id)
    REFERENCES account_group(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_account_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_account_type ON account_account(tenant_id, account_type);
CREATE INDEX IF NOT EXISTS idx_account_code ON account_account(tenant_id, code);
CREATE INDEX IF NOT EXISTS idx_account_group ON account_account(tenant_id, group_id);
CREATE INDEX IF NOT EXISTS idx_account_reconcile ON account_account(tenant_id, reconcile) WHERE reconcile = TRUE;

-- 1.5 Account <-> Tag (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_account_tag_rel (
  tenant_id UUID NOT NULL,
  account_id UUID NOT NULL,
  tag_id UUID NOT NULL,
  PRIMARY KEY (tenant_id, account_id, tag_id),
  
  CONSTRAINT fk_account_tag_rel_account
    FOREIGN KEY (tenant_id, account_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_account_tag_rel_tag
    FOREIGN KEY (tenant_id, tag_id)
    REFERENCES account_account_tag(tenant_id, id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_account_tag_rel_account ON account_account_tag_rel(tenant_id, account_id);
CREATE INDEX IF NOT EXISTS idx_account_tag_rel_tag ON account_account_tag_rel(tenant_id, tag_id);

-- ============================================================
-- SECTION 2: JOURNAL SYSTEM
-- ============================================================

-- 2.1 Journal Group
CREATE TABLE IF NOT EXISTS account_journal_group (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  sequence INTEGER DEFAULT 10,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_journal_group_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

-- 2.2 Journal (Sổ nhật ký)
CREATE TABLE IF NOT EXISTS account_journal (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  code VARCHAR(10) NOT NULL,
  type VARCHAR(20) NOT NULL, -- 'sale', 'purchase', 'cash', 'bank', 'general'
  
  -- Accounts
  default_account_id UUID,
  suspense_account_id UUID,
  non_deductible_account_id UUID,
  profit_account_id UUID,
  loss_account_id UUID,
  
  currency_id UUID,
  sequence INTEGER DEFAULT 10,
  color INTEGER DEFAULT 0,
  active BOOLEAN DEFAULT TRUE,
  show_on_dashboard BOOLEAN DEFAULT TRUE,
  
  -- Bank settings
  bank_account_id UUID,
  bank_statements_source VARCHAR(50),
  
  -- Invoice settings
  refund_sequence BOOLEAN DEFAULT FALSE,
  payment_sequence BOOLEAN DEFAULT FALSE,
  invoice_reference_type VARCHAR(20) DEFAULT 'none', -- 'none', 'partner', 'invoice'
  invoice_reference_model VARCHAR(20) DEFAULT 'odoo', -- 'odoo', 'euro'
  restrict_mode_hash_table BOOLEAN DEFAULT FALSE,
  
  -- Sequence override
  sequence_override_regex TEXT,
  
  -- E-invoicing
  is_self_billing BOOLEAN DEFAULT FALSE,
  incoming_einvoice_notification_email VARCHAR(255),
  
  access_token VARCHAR(255),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, code),
  
  CONSTRAINT fk_journal_default_account
    FOREIGN KEY (tenant_id, default_account_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_journal_suspense_account
    FOREIGN KEY (tenant_id, suspense_account_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_journal_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT,
  CONSTRAINT chk_journal_type 
    CHECK (type IN ('sale', 'purchase', 'cash', 'bank', 'general'))
);

CREATE INDEX IF NOT EXISTS idx_journal_type ON account_journal(tenant_id, type);
CREATE INDEX IF NOT EXISTS idx_journal_active ON account_journal(tenant_id, active) WHERE active = TRUE;

-- 2.3 Journal <-> Journal Group (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_journal_group_rel (
  tenant_id UUID NOT NULL,
  journal_id UUID NOT NULL,
  group_id UUID NOT NULL,
  PRIMARY KEY (tenant_id, journal_id, group_id),
  
  CONSTRAINT fk_journal_group_rel_journal
    FOREIGN KEY (tenant_id, journal_id)
    REFERENCES account_journal(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_journal_group_rel_group
    FOREIGN KEY (tenant_id, group_id)
    REFERENCES account_journal_group(tenant_id, id)
    ON DELETE CASCADE
);

-- ============================================================
-- SECTION 3: TAX SYSTEM
-- ============================================================

-- 3.1 Tax Group
CREATE TABLE IF NOT EXISTS account_tax_group (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  sequence INTEGER DEFAULT 10,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id)
);

-- 3.2 Tax (Thuế)
CREATE TABLE IF NOT EXISTS account_tax (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  type_tax_use VARCHAR(20) NOT NULL, -- 'sale', 'purchase', 'none'
  amount_type VARCHAR(20) NOT NULL DEFAULT 'percent', -- 'percent', 'fixed', 'division'
  amount NUMERIC(12, 4) NOT NULL DEFAULT 0,
  tax_group_id UUID NOT NULL,
  country_id UUID,
  tax_scope VARCHAR(20), -- 'service', 'consu'
  
  -- Invoice display
  invoice_label TEXT,
  invoice_legal_notes TEXT,
  
  -- Advanced
  price_include_override VARCHAR(20), -- 'included', 'excluded', NULL
  active BOOLEAN DEFAULT TRUE,
  sequence INTEGER DEFAULT 10,
  
  -- Base amount
  include_base_amount BOOLEAN DEFAULT FALSE, -- Thuế này ảnh hưởng base của thuế khác
  is_base_affected BOOLEAN DEFAULT TRUE,
  
  -- Cash basis
  tax_exigibility VARCHAR(20) DEFAULT 'on_invoice', -- 'on_invoice', 'on_payment'
  cash_basis_transition_account_id UUID,
  
  -- Analytic
  analytic BOOLEAN DEFAULT FALSE,
  
  -- UBL/CII codes
  ubl_cii_tax_category_code VARCHAR(10),
  ubl_cii_tax_exemption_reason_code VARCHAR(10),
  
  -- Domestic
  is_domestic BOOLEAN DEFAULT FALSE,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_tax_group
    FOREIGN KEY (tenant_id, tax_group_id)
    REFERENCES account_tax_group(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_tax_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT,
  CONSTRAINT chk_tax_type_use 
    CHECK (type_tax_use IN ('sale', 'purchase', 'none')),
  CONSTRAINT chk_tax_amount_type 
    CHECK (amount_type IN ('percent', 'fixed', 'division'))
);

CREATE INDEX IF NOT EXISTS idx_tax_type_use ON account_tax(tenant_id, type_tax_use);
CREATE INDEX IF NOT EXISTS idx_tax_group ON account_tax(tenant_id, tax_group_id);
CREATE INDEX IF NOT EXISTS idx_tax_active ON account_tax(tenant_id, active) WHERE active = TRUE;

-- 3.3 Tax Repartition Line (Phân bổ thuế)
CREATE TABLE IF NOT EXISTS account_tax_repartition_line (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  invoice_tax_id UUID NOT NULL,
  factor_percent NUMERIC(5, 2) DEFAULT 100.0, -- % phân bổ
  repartition_type VARCHAR(20) NOT NULL, -- 'base', 'tax'
  account_id UUID,
  sequence INTEGER DEFAULT 1,
  use_in_tax_closing BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_tax_repartition_tax
    FOREIGN KEY (tenant_id, invoice_tax_id)
    REFERENCES account_tax(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_tax_repartition_account
    FOREIGN KEY (tenant_id, account_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT chk_tax_repartition_type 
    CHECK (repartition_type IN ('base', 'tax'))
);

CREATE INDEX IF NOT EXISTS idx_tax_repartition_tax ON account_tax_repartition_line(tenant_id, invoice_tax_id);

-- 3.4 Tax <-> Tag (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_tax_tag_rel (
  tenant_id UUID NOT NULL,
  tax_id UUID NOT NULL,
  tag_id UUID NOT NULL,
  PRIMARY KEY (tenant_id, tax_id, tag_id),
  
  CONSTRAINT fk_tax_tag_rel_tax
    FOREIGN KEY (tenant_id, tax_id)
    REFERENCES account_tax(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_tax_tag_rel_tag
    FOREIGN KEY (tenant_id, tag_id)
    REFERENCES account_account_tag(tenant_id, id)
    ON DELETE CASCADE
);

-- 3.5 Tax Filiation (Parent-Child relationship for tax groups)
CREATE TABLE IF NOT EXISTS account_tax_filiation_rel (
  tenant_id UUID NOT NULL,
  parent_tax_id UUID NOT NULL,
  child_tax_id UUID NOT NULL,
  PRIMARY KEY (tenant_id, parent_tax_id, child_tax_id),
  
  CONSTRAINT fk_tax_filiation_parent
    FOREIGN KEY (tenant_id, parent_tax_id)
    REFERENCES account_tax(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_tax_filiation_child
    FOREIGN KEY (tenant_id, child_tax_id)
    REFERENCES account_tax(tenant_id, id)
    ON DELETE CASCADE
);

-- ============================================================
-- SECTION 4: PAYMENT TERMS
-- ============================================================

-- 4.1 Payment Terms
CREATE TABLE IF NOT EXISTS account_payment_term (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  note TEXT,
  active BOOLEAN DEFAULT TRUE,
  display_on_invoice BOOLEAN DEFAULT TRUE,
  early_discount BOOLEAN DEFAULT FALSE,
  discount_percentage NUMERIC(5, 2),
  discount_days INTEGER,
  early_pay_discount_computation VARCHAR(20), -- 'included', 'excluded'
  sequence INTEGER DEFAULT 10,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_payment_term_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

-- 4.2 Payment Term Lines
CREATE TABLE IF NOT EXISTS account_payment_term_line (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  payment_term_id UUID NOT NULL,
  value VARCHAR(20) NOT NULL DEFAULT 'balance', -- 'balance', 'percent', 'fixed'
  value_amount NUMERIC(12, 2), -- % hoặc số tiền cố định
  nb_days INTEGER DEFAULT 0, -- Số ngày sau invoice date
  delay_type VARCHAR(30) DEFAULT 'days_after', -- 'days_after', 'days_after_end_of_month', 'days_after_end_of_next_month'
  days_next_month VARCHAR(2), -- '01' - '31'
  sequence INTEGER DEFAULT 10,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_payment_term_line_term
    FOREIGN KEY (tenant_id, payment_term_id)
    REFERENCES account_payment_term(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT chk_payment_term_line_value 
    CHECK (value IN ('balance', 'percent', 'fixed'))
);

CREATE INDEX IF NOT EXISTS idx_payment_term_line_term ON account_payment_term_line(tenant_id, payment_term_id);

-- ============================================================
-- SECTION 5: INVOICE / JOURNAL ENTRY (ACCOUNT MOVE)
-- ============================================================

-- 5.1 Account Move (Bút toán kế toán / Hóa đơn)
CREATE TABLE IF NOT EXISTS account_move (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  
  -- Basic info
  name VARCHAR(100), -- Số chứng từ (auto-generated)
  ref VARCHAR(100), -- Số tham chiếu
  date DATE NOT NULL, -- Ngày hạch toán
  journal_id UUID NOT NULL,
  currency_id UUID NOT NULL,
  
  -- Type & State
  move_type VARCHAR(20) NOT NULL, -- 'entry', 'out_invoice', 'out_refund', 'in_invoice', 'in_refund', 'out_receipt', 'in_receipt'
  state VARCHAR(20) NOT NULL DEFAULT 'draft', -- 'draft', 'posted', 'cancel'
  
  -- Partner info (for invoices)
  partner_id UUID,
  commercial_partner_id UUID,
  partner_shipping_id UUID,
  partner_bank_id UUID,
  
  -- Invoice specific
  invoice_date DATE, -- Ngày hóa đơn
  invoice_date_due DATE, -- Ngày đến hạn
  invoice_origin VARCHAR(200), -- Nguồn gốc (SO, PO...)
  invoice_payment_term_id UUID,
  invoice_user_id UUID, -- Salesperson
  invoice_incoterm_id UUID,
  invoice_cash_rounding_id UUID,
  fiscal_position_id UUID,
  
  -- Invoice display
  invoice_source_email VARCHAR(255),
  invoice_partner_display_name VARCHAR(255),
  incoterm_location VARCHAR(255),
  
  -- Payment info
  payment_reference VARCHAR(200),
  qr_code_method VARCHAR(50),
  payment_state VARCHAR(20), -- 'not_paid', 'in_payment', 'paid', 'partial', 'reversed', 'invoicing_legacy'
  preferred_payment_method_line_id UUID,
  
  -- Amounts
  invoice_currency_rate NUMERIC(20, 10),
  amount_untaxed NUMERIC(20, 4) DEFAULT 0,
  amount_tax NUMERIC(20, 4) DEFAULT 0,
  amount_total NUMERIC(20, 4) DEFAULT 0,
  amount_residual NUMERIC(20, 4) DEFAULT 0, -- Số tiền còn phải trả
  amount_untaxed_signed NUMERIC(20, 4) DEFAULT 0,
  amount_untaxed_in_currency_signed NUMERIC(20, 4) DEFAULT 0,
  amount_tax_signed NUMERIC(20, 4) DEFAULT 0,
  amount_total_signed NUMERIC(20, 4) DEFAULT 0,
  amount_total_in_currency_signed NUMERIC(20, 4) DEFAULT 0,
  amount_residual_signed NUMERIC(20, 4) DEFAULT 0,
  quick_edit_total_amount NUMERIC(20, 4),
  
  -- Narration
  narration TEXT,
  
  -- Reversal
  reversed_entry_id UUID, -- Link to original entry if this is reversal
  
  -- Auto post
  auto_post VARCHAR(20) DEFAULT 'no', -- 'no', 'at_date', 'monthly', 'quarterly', 'yearly'
  auto_post_until DATE,
  auto_post_origin_id UUID,
  
  -- Tax settings
  always_tax_exigible BOOLEAN DEFAULT FALSE,
  taxable_supply_date DATE,
  
  -- Security & tracking
  posted_before BOOLEAN DEFAULT FALSE,
  is_move_sent BOOLEAN DEFAULT FALSE,
  is_manually_modified BOOLEAN DEFAULT FALSE,
  checked BOOLEAN DEFAULT FALSE,
  made_sequence_gap BOOLEAN DEFAULT FALSE,
  
  -- Sequence
  sequence_number INTEGER,
  sequence_prefix VARCHAR(50),
  secure_sequence_number INTEGER,
  inalterable_hash VARCHAR(255),
  
  -- Statement link
  statement_line_id UUID,
  
  -- Tax cash basis
  tax_cash_basis_rec_id UUID,
  tax_cash_basis_origin_move_id UUID,
  
  -- Delivery date
  delivery_date DATE,
  
  -- Sending data (e-invoice)
  sending_data JSONB,
  
  -- Message attachment
  message_main_attachment_id UUID,
  
  -- Access token
  access_token VARCHAR(255),
  
  -- Idempotency
  idempotency_key TEXT,
  
  -- IAM
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  assignee_id UUID,
  shared_with UUID[] DEFAULT '{}',
  
  PRIMARY KEY (tenant_id, id),
  
  -- Foreign Keys
  CONSTRAINT fk_move_journal
    FOREIGN KEY (tenant_id, journal_id)
    REFERENCES account_journal(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_move_partner
    FOREIGN KEY (tenant_id, partner_id)
    REFERENCES contact(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_move_payment_term
    FOREIGN KEY (tenant_id, invoice_payment_term_id)
    REFERENCES account_payment_term(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_move_reversed
    FOREIGN KEY (tenant_id, reversed_entry_id)
    REFERENCES account_move(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_move_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_move_assignee
    FOREIGN KEY (tenant_id, assignee_id)
    REFERENCES users(tenant_id, user_id)
    ON DELETE SET NULL,
    
  -- Constraints
  CONSTRAINT chk_move_type CHECK (move_type IN ('entry', 'out_invoice', 'out_refund', 'in_invoice', 'in_refund', 'out_receipt', 'in_receipt')),
  CONSTRAINT chk_move_state CHECK (state IN ('draft', 'posted', 'cancel')),
  CONSTRAINT chk_payment_state CHECK (payment_state IS NULL OR payment_state IN ('not_paid', 'in_payment', 'paid', 'partial', 'reversed', 'invoicing_legacy'))
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_move_date ON account_move(tenant_id, date);
CREATE INDEX IF NOT EXISTS idx_move_state ON account_move(tenant_id, state);
CREATE INDEX IF NOT EXISTS idx_move_type ON account_move(tenant_id, move_type);
CREATE INDEX IF NOT EXISTS idx_move_partner ON account_move(tenant_id, partner_id);
CREATE INDEX IF NOT EXISTS idx_move_journal ON account_move(tenant_id, journal_id);
CREATE INDEX IF NOT EXISTS idx_move_payment_state ON account_move(tenant_id, payment_state);
CREATE INDEX IF NOT EXISTS idx_move_invoice_date ON account_move(tenant_id, invoice_date);
CREATE INDEX IF NOT EXISTS idx_move_name ON account_move(tenant_id, name);

-- IAM indexes
CREATE INDEX IF NOT EXISTS idx_move_created_by ON account_move(tenant_id, created_by);
CREATE INDEX IF NOT EXISTS idx_move_assignee ON account_move(tenant_id, assignee_id);
CREATE INDEX IF NOT EXISTS idx_move_shared ON account_move USING GIN(shared_with);

-- Idempotency
CREATE UNIQUE INDEX IF NOT EXISTS uq_move_idempotency
  ON account_move(tenant_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;

-- 5.2 Account Move Line (Chi tiết bút toán)
CREATE TABLE IF NOT EXISTS account_move_line (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  move_id UUID NOT NULL,
  
  -- Account info
  account_id UUID,
  journal_id UUID,
  currency_id UUID NOT NULL,
  company_currency_id UUID,
  
  -- Partner
  partner_id UUID,
  
  -- Product (for invoice lines)
  product_id UUID,
  product_uom_id UUID,
  quantity NUMERIC(16, 4),
  price_unit NUMERIC(20, 6),
  discount NUMERIC(5, 2) DEFAULT 0, -- %
  discount_date DATE,
  discount_amount_currency NUMERIC(20, 4),
  discount_balance NUMERIC(20, 4),
  
  -- Line info
  name TEXT, -- Description
  ref VARCHAR(200),
  move_name VARCHAR(200),
  parent_state VARCHAR(20), -- State của move
  sequence INTEGER DEFAULT 10,
  display_type VARCHAR(20), -- NULL, 'line_section', 'line_subsection', 'line_note'
  
  -- Debit/Credit (accounting entries)
  debit NUMERIC(20, 4) DEFAULT 0,
  credit NUMERIC(20, 4) DEFAULT 0,
  balance NUMERIC(20, 4) DEFAULT 0, -- debit - credit
  amount_currency NUMERIC(20, 4) DEFAULT 0, -- Số tiền theo currency của move
  
  -- Amounts (for invoice lines)
  price_subtotal NUMERIC(20, 4) DEFAULT 0, -- Subtotal before tax
  price_total NUMERIC(20, 4) DEFAULT 0, -- Total with tax
  
  -- Tax
  tax_base_amount NUMERIC(20, 4) DEFAULT 0,
  tax_line_id UUID, -- Nếu dòng này là dòng thuế
  group_tax_id UUID,
  tax_group_id UUID,
  tax_repartition_line_id UUID,
  
  -- Tax extra data
  extra_tax_data JSONB,
  deductible_amount NUMERIC(5, 2),
  
  -- Reconciliation
  full_reconcile_id UUID,
  matching_number VARCHAR(20),
  amount_residual NUMERIC(20, 4) DEFAULT 0,
  amount_residual_currency NUMERIC(20, 4) DEFAULT 0,
  reconciled BOOLEAN DEFAULT FALSE,
  reconcile_model_id UUID,
  
  -- Payment
  payment_id UUID,
  statement_line_id UUID,
  statement_id UUID,
  
  -- Dates
  date DATE,
  invoice_date DATE,
  date_maturity DATE, -- Ngày đáo hạn cho receivable/payable
  
  -- Analytic
  analytic_distribution JSONB, -- {'analytic_account_id': 100.0}
  
  -- Anglo-Saxon
  is_anglo_saxon_line BOOLEAN DEFAULT FALSE,
  is_storno BOOLEAN DEFAULT FALSE,
  
  -- Flags
  exclude_from_invoice_tab BOOLEAN DEFAULT FALSE,
  is_imported BOOLEAN DEFAULT FALSE,
  no_followup BOOLEAN DEFAULT FALSE,
  collapse_composition BOOLEAN DEFAULT FALSE,
  collapse_prices BOOLEAN DEFAULT FALSE,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  
  -- Foreign Keys
  CONSTRAINT fk_move_line_move
    FOREIGN KEY (tenant_id, move_id)
    REFERENCES account_move(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_move_line_account
    FOREIGN KEY (tenant_id, account_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_move_line_journal
    FOREIGN KEY (tenant_id, journal_id)
    REFERENCES account_journal(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_move_line_partner
    FOREIGN KEY (tenant_id, partner_id)
    REFERENCES contact(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_move_line_tax
    FOREIGN KEY (tenant_id, tax_line_id)
    REFERENCES account_tax(tenant_id, id)
    ON DELETE RESTRICT,
    
  -- Constraints
  CONSTRAINT chk_move_line_debit_credit CHECK ((debit * credit) = 0), -- Không thể có cả debit và credit
  CONSTRAINT chk_move_line_accountable CHECK (
    display_type IN ('line_section', 'line_subsection', 'line_note') OR account_id IS NOT NULL
  ),
  CONSTRAINT chk_move_line_display_null CHECK (
    display_type NOT IN ('line_section', 'line_subsection', 'line_note') OR 
    (account_id IS NULL AND debit = 0 AND credit = 0 AND amount_currency = 0)
  ),
  CONSTRAINT chk_move_line_currency_sign CHECK (
    display_type IN ('line_section', 'line_subsection', 'line_note') OR 
    ((balance <= 0 AND amount_currency <= 0) OR (balance >= 0 AND amount_currency >= 0))
  )
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_move_line_move ON account_move_line(tenant_id, move_id);
CREATE INDEX IF NOT EXISTS idx_move_line_account ON account_move_line(tenant_id, account_id);
CREATE INDEX IF NOT EXISTS idx_move_line_partner ON account_move_line(tenant_id, partner_id);
CREATE INDEX IF NOT EXISTS idx_move_line_product ON account_move_line(tenant_id, product_id);
CREATE INDEX IF NOT EXISTS idx_move_line_journal ON account_move_line(tenant_id, journal_id);
CREATE INDEX IF NOT EXISTS idx_move_line_date ON account_move_line(tenant_id, date);
CREATE INDEX IF NOT EXISTS idx_move_line_reconcile ON account_move_line(tenant_id, full_reconcile_id);
CREATE INDEX IF NOT EXISTS idx_move_line_matching ON account_move_line(tenant_id, matching_number) WHERE matching_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_move_line_balance ON account_move_line(tenant_id, account_id, partner_id, reconciled) WHERE NOT reconciled AND balance != 0;

-- 5.3 Move Line <-> Tax (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_move_line_tax_rel (
  tenant_id UUID NOT NULL,
  move_line_id UUID NOT NULL,
  tax_id UUID NOT NULL,
  PRIMARY KEY (tenant_id, move_line_id, tax_id),
  
  CONSTRAINT fk_move_line_tax_line
    FOREIGN KEY (tenant_id, move_line_id)
    REFERENCES account_move_line(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_move_line_tax_tax
    FOREIGN KEY (tenant_id, tax_id)
    REFERENCES account_tax(tenant_id, id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_move_line_tax_line ON account_move_line_tax_rel(tenant_id, move_line_id);
CREATE INDEX IF NOT EXISTS idx_move_line_tax_tax ON account_move_line_tax_rel(tenant_id, tax_id);

-- ============================================================
-- SECTION 6: PAYMENT SYSTEM
-- ============================================================

-- 6.1 Payment Method
CREATE TABLE IF NOT EXISTS account_payment_method (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  code VARCHAR(50) NOT NULL,
  payment_type VARCHAR(20) NOT NULL, -- 'inbound', 'outbound'
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, code, payment_type),
  CONSTRAINT chk_payment_method_type CHECK (payment_type IN ('inbound', 'outbound'))
);

-- 6.2 Payment Method Line (Journal-specific payment methods)
CREATE TABLE IF NOT EXISTS account_payment_method_line (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name VARCHAR(255),
  journal_id UUID NOT NULL,
  payment_method_id UUID NOT NULL,
  payment_account_id UUID,
  sequence INTEGER DEFAULT 10,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_payment_method_line_journal
    FOREIGN KEY (tenant_id, journal_id)
    REFERENCES account_journal(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_payment_method_line_method
    FOREIGN KEY (tenant_id, payment_method_id)
    REFERENCES account_payment_method(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_payment_method_line_account
    FOREIGN KEY (tenant_id, payment_account_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_payment_method_line_journal ON account_payment_method_line(tenant_id, journal_id);

-- 6.3 Payment
CREATE TABLE IF NOT EXISTS account_payment (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  
  -- Basic info
  name VARCHAR(100), -- Payment reference
  move_id UUID, -- Link to journal entry
  date DATE NOT NULL,
  
  -- Payment info
  payment_type VARCHAR(20) NOT NULL, -- 'outbound', 'inbound', 'transfer'
  partner_type VARCHAR(20), -- 'customer', 'supplier'
  partner_id UUID,
  partner_bank_id UUID,
  
  -- Amounts
  amount NUMERIC(20, 4) NOT NULL,
  amount_company_currency_signed NUMERIC(20, 4),
  currency_id UUID NOT NULL,
  
  -- Journal & method
  journal_id UUID NOT NULL,
  destination_journal_id UUID, -- For internal transfers
  payment_method_line_id UUID,
  payment_method_id UUID,
  
  -- Accounts
  destination_account_id UUID NOT NULL,
  outstanding_account_id UUID,
  
  -- Payment details
  payment_reference VARCHAR(200),
  memo TEXT,
  
  -- State
  state VARCHAR(20) NOT NULL DEFAULT 'draft', -- 'draft', 'posted', 'sent', 'reconciled', 'cancelled'
  is_reconciled BOOLEAN DEFAULT FALSE,
  is_matched BOOLEAN DEFAULT FALSE,
  is_sent BOOLEAN DEFAULT FALSE,
  
  -- Internal transfer
  paired_internal_transfer_payment_id UUID,
  
  -- Message attachment
  message_main_attachment_id UUID,
  
  -- Idempotency
  idempotency_key TEXT,
  
  -- IAM
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  assignee_id UUID,
  shared_with UUID[] DEFAULT '{}',
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_payment_move
    FOREIGN KEY (tenant_id, move_id)
    REFERENCES account_move(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_payment_partner
    FOREIGN KEY (tenant_id, partner_id)
    REFERENCES contact(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_payment_journal
    FOREIGN KEY (tenant_id, journal_id)
    REFERENCES account_journal(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_payment_dest_journal
    FOREIGN KEY (tenant_id, destination_journal_id)
    REFERENCES account_journal(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_payment_method_line
    FOREIGN KEY (tenant_id, payment_method_line_id)
    REFERENCES account_payment_method_line(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_payment_method
    FOREIGN KEY (tenant_id, payment_method_id)
    REFERENCES account_payment_method(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_payment_dest_account
    FOREIGN KEY (tenant_id, destination_account_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_payment_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_payment_assignee
    FOREIGN KEY (tenant_id, assignee_id)
    REFERENCES users(tenant_id, user_id)
    ON DELETE SET NULL,
    
  CONSTRAINT chk_payment_amount CHECK (amount >= 0),
  CONSTRAINT chk_payment_type CHECK (payment_type IN ('outbound', 'inbound', 'transfer')),
  CONSTRAINT chk_payment_state CHECK (state IN ('draft', 'posted', 'sent', 'reconciled', 'cancelled'))
);

CREATE INDEX IF NOT EXISTS idx_payment_date ON account_payment(tenant_id, date);
CREATE INDEX IF NOT EXISTS idx_payment_partner ON account_payment(tenant_id, partner_id);
CREATE INDEX IF NOT EXISTS idx_payment_journal ON account_payment(tenant_id, journal_id);
CREATE INDEX IF NOT EXISTS idx_payment_state ON account_payment(tenant_id, state);
CREATE INDEX IF NOT EXISTS idx_payment_created_by ON account_payment(tenant_id, created_by);
CREATE INDEX IF NOT EXISTS idx_payment_move ON account_payment(tenant_id, move_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_payment_idempotency
  ON account_payment(tenant_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;

-- 6.4 Payment <-> Move (Link table for multiple payments to one move)
CREATE TABLE IF NOT EXISTS account_move_payment_rel (
  tenant_id UUID NOT NULL,
  move_id UUID NOT NULL,
  payment_id UUID NOT NULL,
  PRIMARY KEY (tenant_id, move_id, payment_id),
  
  CONSTRAINT fk_move_payment_rel_move
    FOREIGN KEY (tenant_id, move_id)
    REFERENCES account_move(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_move_payment_rel_payment
    FOREIGN KEY (tenant_id, payment_id)
    REFERENCES account_payment(tenant_id, id)
    ON DELETE CASCADE
);

-- ============================================================
-- SECTION 7: RECONCILIATION
-- ============================================================

-- 7.1 Full Reconcile (Đối soát đầy đủ)
CREATE TABLE IF NOT EXISTS account_full_reconcile (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name VARCHAR(100), -- Reconcile reference
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_reconcile_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

-- 7.2 Partial Reconcile (Đối soát một phần)
CREATE TABLE IF NOT EXISTS account_partial_reconcile (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  
  debit_move_id UUID NOT NULL,
  credit_move_id UUID NOT NULL,
  full_reconcile_id UUID,
  
  amount NUMERIC(20, 4) NOT NULL,
  amount_currency NUMERIC(20, 4),
  currency_id UUID,
  
  max_date DATE, -- Max date of the two move lines
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_partial_reconcile_debit
    FOREIGN KEY (tenant_id, debit_move_id)
    REFERENCES account_move_line(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_partial_reconcile_credit
    FOREIGN KEY (tenant_id, credit_move_id)
    REFERENCES account_move_line(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_partial_reconcile_full
    FOREIGN KEY (tenant_id, full_reconcile_id)
    REFERENCES account_full_reconcile(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_partial_reconcile_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_partial_reconcile_debit ON account_partial_reconcile(tenant_id, debit_move_id);
CREATE INDEX IF NOT EXISTS idx_partial_reconcile_credit ON account_partial_reconcile(tenant_id, credit_move_id);
CREATE INDEX IF NOT EXISTS idx_partial_reconcile_full ON account_partial_reconcile(tenant_id, full_reconcile_id);

-- 7.3 Reconcile Model (Mẫu đối soát tự động)
CREATE TABLE IF NOT EXISTS account_reconcile_model (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  sequence INTEGER DEFAULT 10,
  active BOOLEAN DEFAULT TRUE,
  
  -- Trigger
  trigger VARCHAR(50) NOT NULL, -- 'manual', 'auto_reconcile', 'writeoff_button'
  
  -- Matching rules
  match_amount VARCHAR(50), -- 'lower', 'greater', 'between'
  match_amount_min NUMERIC(20, 4),
  match_amount_max NUMERIC(20, 4),
  match_label VARCHAR(50), -- 'contains', 'regex', 'exact'
  match_label_param TEXT,
  
  -- Partner mapping
  mapped_partner_id UUID,
  
  -- Activity
  next_activity_type_id UUID,
  
  -- Proposition
  can_be_proposed BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_reconcile_model_partner
    FOREIGN KEY (tenant_id, mapped_partner_id)
    REFERENCES contact(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_reconcile_model_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

-- 7.4 Reconcile Model Line (Chi tiết mẫu đối soát)
CREATE TABLE IF NOT EXISTS account_reconcile_model_line (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  model_id UUID NOT NULL,
  sequence INTEGER DEFAULT 10,
  
  account_id UUID,
  partner_id UUID,
  label TEXT,
  
  amount_type VARCHAR(20) NOT NULL, -- 'percentage', 'fixed', 'regex'
  amount_string VARCHAR(100) NOT NULL,
  amount NUMERIC(20, 4),
  
  -- Analytic
  analytic_distribution JSONB,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_reconcile_model_line_model
    FOREIGN KEY (tenant_id, model_id)
    REFERENCES account_reconcile_model(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_reconcile_model_line_account
    FOREIGN KEY (tenant_id, account_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_reconcile_model_line_partner
    FOREIGN KEY (tenant_id, partner_id)
    REFERENCES contact(tenant_id, id)
    ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_reconcile_model_line_model ON account_reconcile_model_line(tenant_id, model_id);

-- 7.5 Reconcile Model <-> Journal (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_reconcile_model_journal_rel (
  tenant_id UUID NOT NULL,
  model_id UUID NOT NULL,
  journal_id UUID NOT NULL,
  PRIMARY KEY (tenant_id, model_id, journal_id),
  
  CONSTRAINT fk_reconcile_model_journal_model
    FOREIGN KEY (tenant_id, model_id)
    REFERENCES account_reconcile_model(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_reconcile_model_journal_journal
    FOREIGN KEY (tenant_id, journal_id)
    REFERENCES account_journal(tenant_id, id)
    ON DELETE CASCADE
);

-- 7.6 Reconcile Model <-> Partner (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_reconcile_model_partner_rel (
  tenant_id UUID NOT NULL,
  model_id UUID NOT NULL,
  partner_id UUID NOT NULL,
  PRIMARY KEY (tenant_id, model_id, partner_id),
  
  CONSTRAINT fk_reconcile_model_partner_model
    FOREIGN KEY (tenant_id, model_id)
    REFERENCES account_reconcile_model(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_reconcile_model_partner_partner
    FOREIGN KEY (tenant_id, partner_id)
    REFERENCES contact(tenant_id, id)
    ON DELETE CASCADE
);

-- ============================================================
-- SECTION 8: BANK STATEMENT
-- ============================================================

-- 8.1 Bank Statement
CREATE TABLE IF NOT EXISTS account_bank_statement (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name VARCHAR(100) NOT NULL,
  reference VARCHAR(100),
  date DATE NOT NULL,
  journal_id UUID NOT NULL,
  balance_start NUMERIC(20, 4) DEFAULT 0,
  balance_end NUMERIC(20, 4) DEFAULT 0,
  balance_end_real NUMERIC(20, 4) DEFAULT 0,
  
  state VARCHAR(20) NOT NULL DEFAULT 'open', -- 'open', 'confirm'
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_statement_journal
    FOREIGN KEY (tenant_id, journal_id)
    REFERENCES account_journal(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_statement_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_statement_journal ON account_bank_statement(tenant_id, journal_id);
CREATE INDEX IF NOT EXISTS idx_statement_date ON account_bank_statement(tenant_id, date);

-- 8.2 Bank Statement Line
CREATE TABLE IF NOT EXISTS account_bank_statement_line (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  statement_id UUID NOT NULL,
  date DATE NOT NULL,
  sequence INTEGER DEFAULT 10,
  
  -- Transaction info
  payment_ref VARCHAR(200) NOT NULL,
  ref VARCHAR(200),
  partner_id UUID,
  
  -- Amount
  amount NUMERIC(20, 4) NOT NULL,
  foreign_currency_id UUID,
  amount_currency NUMERIC(20, 4),
  
  -- Reconciliation
  is_reconciled BOOLEAN DEFAULT FALSE,
  move_id UUID,
  
  -- Running balance
  running_balance NUMERIC(20, 4),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_statement_line_statement
    FOREIGN KEY (tenant_id, statement_id)
    REFERENCES account_bank_statement(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_statement_line_partner
    FOREIGN KEY (tenant_id, partner_id)
    REFERENCES contact(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_statement_line_move
    FOREIGN KEY (tenant_id, move_id)
    REFERENCES account_move(tenant_id, id)
    ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_statement_line_statement ON account_bank_statement_line(tenant_id, statement_id);
CREATE INDEX IF NOT EXISTS idx_statement_line_partner ON account_bank_statement_line(tenant_id, partner_id);
CREATE INDEX IF NOT EXISTS idx_statement_line_date ON account_bank_statement_line(tenant_id, date);

-- 8.3 Statement Line <-> Payment (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_statement_line_payment_rel (
  tenant_id UUID NOT NULL,
  statement_line_id UUID NOT NULL,
  payment_id UUID NOT NULL,
  PRIMARY KEY (tenant_id, statement_line_id, payment_id),
  
  CONSTRAINT fk_statement_line_payment_line
    FOREIGN KEY (tenant_id, statement_line_id)
    REFERENCES account_bank_statement_line(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_statement_line_payment_payment
    FOREIGN KEY (tenant_id, payment_id)
    REFERENCES account_payment(tenant_id, id)
    ON DELETE CASCADE
);

-- ============================================================
-- SECTION 9: ANALYTIC ACCOUNTING
-- ============================================================

-- 9.1 Analytic Plan
CREATE TABLE IF NOT EXISTS account_analytic_plan (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  color INTEGER DEFAULT 0,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id)
);

-- 9.2 Analytic Applicability (Quy tắc áp dụng plan)
CREATE TABLE IF NOT EXISTS account_analytic_applicability (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  analytic_plan_id UUID NOT NULL,
  business_domain VARCHAR(50) NOT NULL, -- 'general', 'invoice', 'bill', 'purchase_order', 'sale_order'
  applicability VARCHAR(50) NOT NULL, -- 'optional', 'mandatory', 'unavailable'
  product_categ_id UUID,
  account_prefix VARCHAR(50),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_analytic_applicability_plan
    FOREIGN KEY (tenant_id, analytic_plan_id)
    REFERENCES account_analytic_plan(tenant_id, id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_analytic_applicability_plan ON account_analytic_applicability(tenant_id, analytic_plan_id);

-- 9.3 Analytic Account
CREATE TABLE IF NOT EXISTS account_analytic_account (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  code VARCHAR(50),
  plan_id UUID NOT NULL,
  partner_id UUID,
  active BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_analytic_account_plan
    FOREIGN KEY (tenant_id, plan_id)
    REFERENCES account_analytic_plan(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_analytic_account_partner
    FOREIGN KEY (tenant_id, partner_id)
    REFERENCES contact(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_analytic_account_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_analytic_account_plan ON account_analytic_account(tenant_id, plan_id);
CREATE INDEX IF NOT EXISTS idx_analytic_account_partner ON account_analytic_account(tenant_id, partner_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_analytic_account_code
  ON account_analytic_account(tenant_id, code)
  WHERE code IS NOT NULL;

-- 9.4 Analytic Line
CREATE TABLE IF NOT EXISTS account_analytic_line (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  date DATE NOT NULL,
  account_id UUID NOT NULL,
  partner_id UUID,
  move_line_id UUID,
  general_account_id UUID,
  
  amount NUMERIC(20, 4) NOT NULL,
  unit_amount NUMERIC(16, 4),
  currency_id UUID,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_analytic_line_account
    FOREIGN KEY (tenant_id, account_id)
    REFERENCES account_analytic_account(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_analytic_line_partner
    FOREIGN KEY (tenant_id, partner_id)
    REFERENCES contact(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_analytic_line_move_line
    FOREIGN KEY (tenant_id, move_line_id)
    REFERENCES account_move_line(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_analytic_line_general_account
    FOREIGN KEY (tenant_id, general_account_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_analytic_line_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_analytic_line_account ON account_analytic_line(tenant_id, account_id);
CREATE INDEX IF NOT EXISTS idx_analytic_line_date ON account_analytic_line(tenant_id, date);
CREATE INDEX IF NOT EXISTS idx_analytic_line_move ON account_analytic_line(tenant_id, move_line_id);
CREATE INDEX IF NOT EXISTS idx_analytic_line_partner ON account_analytic_line(tenant_id, partner_id);

-- 9.5 Analytic Distribution Model (Mẫu phân bổ tự động)
CREATE TABLE IF NOT EXISTS account_analytic_distribution_model (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  analytic_distribution JSONB NOT NULL, -- {'analytic_account_id': 100.0}
  partner_id UUID,
  partner_category_id UUID,
  product_id UUID,
  product_categ_id UUID,
  account_prefix VARCHAR(50),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_analytic_dist_model_partner
    FOREIGN KEY (tenant_id, partner_id)
    REFERENCES contact(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_analytic_dist_model_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

-- ============================================================
-- SECTION 10: FISCAL POSITION
-- ============================================================

-- 10.1 Fiscal Position
CREATE TABLE IF NOT EXISTS account_fiscal_position (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  note TEXT,
  active BOOLEAN DEFAULT TRUE,
  auto_apply BOOLEAN DEFAULT FALSE,
  vat_required BOOLEAN DEFAULT FALSE,
  country_id UUID,
  country_group_id UUID,
  
  sequence INTEGER DEFAULT 10,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_fiscal_position_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

-- 10.2 Fiscal Position Account (Map tài khoản)
CREATE TABLE IF NOT EXISTS account_fiscal_position_account (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  position_id UUID NOT NULL,
  account_src_id UUID NOT NULL,
  account_dest_id UUID NOT NULL,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, position_id, account_src_id),
  
  CONSTRAINT fk_fiscal_pos_account_position
    FOREIGN KEY (tenant_id, position_id)
    REFERENCES account_fiscal_position(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_fiscal_pos_account_src
    FOREIGN KEY (tenant_id, account_src_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_fiscal_pos_account_dest
    FOREIGN KEY (tenant_id, account_dest_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_fiscal_pos_account_position ON account_fiscal_position_account(tenant_id, position_id);

-- 10.3 Fiscal Position Tax (Map thuế)
CREATE TABLE IF NOT EXISTS account_fiscal_position_tax (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  position_id UUID NOT NULL,
  tax_src_id UUID NOT NULL,
  tax_dest_id UUID,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, position_id, tax_src_id),
  
  CONSTRAINT fk_fiscal_pos_tax_position
    FOREIGN KEY (tenant_id, position_id)
    REFERENCES account_fiscal_position(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_fiscal_pos_tax_src
    FOREIGN KEY (tenant_id, tax_src_id)
    REFERENCES account_tax(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_fiscal_pos_tax_dest
    FOREIGN KEY (tenant_id, tax_dest_id)
    REFERENCES account_tax(tenant_id, id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_fiscal_pos_tax_position ON account_fiscal_position_tax(tenant_id, position_id);

-- ============================================================
-- SECTION 11: REPORTING SYSTEM
-- ============================================================

-- 11.1 Account Report (Báo cáo kế toán)
CREATE TABLE IF NOT EXISTS account_report (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  root_report_id UUID,
  country_id UUID,
  
  -- Settings
  chart_template VARCHAR(50),
  availability_condition VARCHAR(50),
  
  -- Display
  sequence INTEGER DEFAULT 10,
  active BOOLEAN DEFAULT TRUE,
  use_sections BOOLEAN DEFAULT FALSE,
  
  -- Filters
  default_opening_date_filter VARCHAR(50),
  filter_date_range BOOLEAN DEFAULT TRUE,
  filter_period_comparison BOOLEAN DEFAULT FALSE,
  filter_growth_comparison BOOLEAN DEFAULT FALSE,
  filter_show_draft BOOLEAN DEFAULT FALSE,
  filter_unreconciled BOOLEAN DEFAULT FALSE,
  filter_unfold_all BOOLEAN DEFAULT FALSE,
  filter_multi_company VARCHAR(50),
  filter_hide_0_lines VARCHAR(50),
  filter_hierarchy BOOLEAN DEFAULT FALSE,
  filter_journals BOOLEAN DEFAULT FALSE,
  filter_analytic BOOLEAN DEFAULT FALSE,
  filter_partner BOOLEAN DEFAULT FALSE,
  filter_account_type BOOLEAN DEFAULT FALSE,
  filter_aml_ir_filters BOOLEAN DEFAULT FALSE,
  filter_budgets BOOLEAN DEFAULT FALSE,
  
  -- Display options
  search_bar BOOLEAN DEFAULT FALSE,
  only_tax_exigible BOOLEAN DEFAULT FALSE,
  allow_foreign_vat BOOLEAN DEFAULT FALSE,
  
  -- Limits
  load_more_limit INTEGER,
  prefix_groups_threshold INTEGER,
  
  -- Rounding
  integer_rounding VARCHAR(50),
  currency_translation VARCHAR(50),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_account_report_root
    FOREIGN KEY (tenant_id, root_report_id)
    REFERENCES account_report(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_account_report_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_account_report_root ON account_report(tenant_id, root_report_id);

-- 11.2 Account Report Line (Dòng báo cáo)
CREATE TABLE IF NOT EXISTS account_report_line (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  code VARCHAR(50),
  report_id UUID NOT NULL,
  parent_id UUID,
  
  -- Grouping & Hierarchy
  groupby VARCHAR(50),
  hierarchy_level INTEGER,
  foldable BOOLEAN DEFAULT FALSE,
  print_on_new_page BOOLEAN DEFAULT FALSE,
  
  -- Display
  sequence INTEGER DEFAULT 10,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_report_line_report
    FOREIGN KEY (tenant_id, report_id)
    REFERENCES account_report(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_report_line_parent
    FOREIGN KEY (tenant_id, parent_id)
    REFERENCES account_report_line(tenant_id, id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_report_line_report ON account_report_line(tenant_id, report_id);
CREATE INDEX IF NOT EXISTS idx_report_line_parent ON account_report_line(tenant_id, parent_id);

-- 11.3 Account Report Column (Cột báo cáo)
CREATE TABLE IF NOT EXISTS account_report_column (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  expression_label VARCHAR(100),
  figure_type VARCHAR(50), -- 'none', 'monetary', 'integer', 'percentage', 'boolean', 'date'
  sortable BOOLEAN DEFAULT FALSE,
  sequence INTEGER DEFAULT 10,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id)
);

-- 11.4 Account Report Expression (Biểu thức tính toán)
CREATE TABLE IF NOT EXISTS account_report_expression (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  report_line_id UUID NOT NULL,
  column_id UUID,
  label VARCHAR(100) NOT NULL,
  engine VARCHAR(50) NOT NULL, -- 'domain', 'aggregation', 'tax_tags', 'external', 'custom'
  formula TEXT,
  subformula TEXT,
  date_scope VARCHAR(50),
  figure_type VARCHAR(50),
  
  -- Carryover
  carryover_target VARCHAR(50),
  
  -- Green/Red arrows
  green_on_positive BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_report_expression_line
    FOREIGN KEY (tenant_id, report_line_id)
    REFERENCES account_report_line(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_report_expression_column
    FOREIGN KEY (tenant_id, column_id)
    REFERENCES account_report_column(tenant_id, id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_report_expression_line ON account_report_expression(tenant_id, report_line_id);

-- 11.5 Account Report External Value (Giá trị ngoài hệ thống)
CREATE TABLE IF NOT EXISTS account_report_external_value (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  target_report_expression_id UUID NOT NULL,
  date DATE NOT NULL,
  value NUMERIC(20, 4),
  text_value TEXT,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_report_external_value_expression
    FOREIGN KEY (tenant_id, target_report_expression_id)
    REFERENCES account_report_expression(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_report_external_value_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_report_external_value_expression ON account_report_external_value(tenant_id, target_report_expression_id);

-- ============================================================
-- SECTION 12: ADDITIONAL FEATURES
-- ============================================================

-- 12.1 Incoterms (International Commercial Terms)
CREATE TABLE IF NOT EXISTS account_incoterms (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  code VARCHAR(10) NOT NULL,
  active BOOLEAN DEFAULT TRUE,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, code)
);

-- 12.2 Cash Rounding (Làm tròn tiền mặt)
CREATE TABLE IF NOT EXISTS account_cash_rounding (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  rounding NUMERIC(12, 6) NOT NULL,
  rounding_method VARCHAR(20) DEFAULT 'HALF-UP', -- 'HALF-UP', 'UP', 'DOWN'
  strategy VARCHAR(20) DEFAULT 'biggest_tax', -- 'biggest_tax', 'on_invoice', 'add_invoice_line'
  account_id UUID,
  loss_account_id UUID,
  profit_account_id UUID,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_cash_rounding_account
    FOREIGN KEY (tenant_id, account_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE SET NULL
);

-- 12.3 Financial Year Opening (Khai báo đầu kỳ)
CREATE TABLE IF NOT EXISTS account_financial_year_op (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  opening_move_id UUID,
  fiscalyear_last_day INTEGER,
  fiscalyear_last_month INTEGER,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_financial_year_op_move
    FOREIGN KEY (tenant_id, opening_move_id)
    REFERENCES account_move(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_financial_year_op_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

-- 12.4 Account Lock Exception (Ngoại lệ khóa sổ)
CREATE TABLE IF NOT EXISTS account_lock_exception (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  date DATE NOT NULL,
  description TEXT,
  user_id UUID NOT NULL,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_lock_exception_user
    FOREIGN KEY (tenant_id, user_id)
    REFERENCES users(tenant_id, user_id)
    ON DELETE CASCADE,
  CONSTRAINT fk_lock_exception_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

-- 12.5 Tax Alternatives (Thuế thay thế)
CREATE TABLE IF NOT EXISTS account_tax_alternatives (
  tenant_id UUID NOT NULL,
  original_tax_id UUID NOT NULL,
  alternative_tax_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, original_tax_id, alternative_tax_id),
  
  CONSTRAINT fk_tax_alternatives_original
    FOREIGN KEY (tenant_id, original_tax_id)
    REFERENCES account_tax(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_tax_alternatives_alternative
    FOREIGN KEY (tenant_id, alternative_tax_id)
    REFERENCES account_tax(tenant_id, id)
    ON DELETE CASCADE
);

-- 12.6 Move Reversal Tracking (Theo dõi bút toán đảo)
CREATE TABLE IF NOT EXISTS account_move_reversal (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  date DATE NOT NULL,
  reason TEXT,
  journal_id UUID,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_move_reversal_journal
    FOREIGN KEY (tenant_id, journal_id)
    REFERENCES account_journal(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_move_reversal_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

-- 12.7 Move Reversal <-> Original Moves (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_move_reversal_move_rel (
  tenant_id UUID NOT NULL,
  reversal_id UUID NOT NULL,
  move_id UUID NOT NULL,
  PRIMARY KEY (tenant_id, reversal_id, move_id),
  
  CONSTRAINT fk_move_reversal_rel_reversal
    FOREIGN KEY (tenant_id, reversal_id)
    REFERENCES account_move_reversal(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_move_reversal_rel_move
    FOREIGN KEY (tenant_id, move_id)
    REFERENCES account_move(tenant_id, id)
    ON DELETE CASCADE
);

-- 12.8 Move Reversal <-> New Moves (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_move_reversal_new_move_rel (
  tenant_id UUID NOT NULL,
  reversal_id UUID NOT NULL,
  new_move_id UUID NOT NULL,
  PRIMARY KEY (tenant_id, reversal_id, new_move_id),
  
  CONSTRAINT fk_move_reversal_new_rel_reversal
    FOREIGN KEY (tenant_id, reversal_id)
    REFERENCES account_move_reversal(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_move_reversal_new_rel_move
    FOREIGN KEY (tenant_id, new_move_id)
    REFERENCES account_move(tenant_id, id)
    ON DELETE CASCADE
);

-- 12.9 Setup Bank Manual Config (Cấu hình ngân hàng)
CREATE TABLE IF NOT EXISTS account_setup_bank_manual_config (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  acc_number VARCHAR(100) NOT NULL,
  bank_name VARCHAR(255),
  send_money_account_id UUID,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_bank_config_account
    FOREIGN KEY (tenant_id, send_money_account_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_bank_config_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

-- ============================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================

COMMENT ON TABLE account_move IS 'Journal entries and invoices - Core accounting table (Odoo: account.move)';
COMMENT ON TABLE account_move_line IS 'Journal items - Individual line items of accounting entries (Odoo: account.move.line)';
COMMENT ON TABLE account_account IS 'Chart of accounts - General ledger accounts (Odoo: account.account)';
COMMENT ON TABLE account_journal IS 'Accounting journals for categorizing entries (Odoo: account.journal)';
COMMENT ON TABLE account_tax IS 'Tax definitions (Odoo: account.tax)';
COMMENT ON TABLE account_payment IS 'Payment records (Odoo: account.payment)';
COMMENT ON TABLE account_payment_term IS 'Payment terms for invoices (Odoo: account.payment.term)';
COMMENT ON TABLE account_reconcile_model IS 'Reconciliation models for automatic matching (Odoo: account.reconcile.model)';
COMMENT ON TABLE account_bank_statement IS 'Bank statements (Odoo: account.bank.statement)';
COMMENT ON TABLE account_analytic_account IS 'Analytic accounts for cost/profit centers (Odoo: account.analytic.account)';
COMMENT ON TABLE account_fiscal_position IS 'Fiscal positions for tax mapping (Odoo: account.fiscal.position)';
COMMENT ON TABLE account_report IS 'Financial reports configuration (Odoo: account.report)';

COMMENT ON COLUMN account_move.move_type IS 'entry=Journal Entry, out_invoice=Customer Invoice, out_refund=Customer Credit Note, in_invoice=Vendor Bill, in_refund=Vendor Credit Note, out_receipt=Sales Receipt, in_receipt=Purchase Receipt';
COMMENT ON COLUMN account_move.state IS 'draft=Unposted, posted=Posted, cancel=Cancelled';
COMMENT ON COLUMN account_move.payment_state IS 'not_paid=Not Paid, in_payment=In Payment, paid=Paid, partial=Partially Paid, reversed=Reversed, invoicing_legacy=Legacy';
COMMENT ON COLUMN account_move.auto_post IS 'Auto-posting: no, at_date, monthly, quarterly, yearly';

COMMENT ON COLUMN account_move_line.display_type IS 'NULL=Normal line, line_section=Section, line_subsection=Subsection, line_note=Note';
COMMENT ON COLUMN account_move_line.balance IS 'debit - credit (always in company currency)';

COMMENT ON COLUMN account_tax.type_tax_use IS 'sale=Sales, purchase=Purchases, none=None';
COMMENT ON COLUMN account_tax.amount_type IS 'percent=Percentage, fixed=Fixed, division=Division';
COMMENT ON COLUMN account_tax.tax_exigibility IS 'on_invoice=Based on Invoice, on_payment=Based on Payment (cash basis)';

COMMENT ON COLUMN account_journal.type IS 'sale=Sales, purchase=Purchases, cash=Cash, bank=Bank, general=Miscellaneous';

-- ============================================================
-- END OF INVOICE MODULE MIGRATION (78+ Tables Complete)
-- ============================================================