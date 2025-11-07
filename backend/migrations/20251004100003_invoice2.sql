-- ============================================================
-- INVOICE2 MODULE — ADDITIONAL ACCOUNT TABLES (25+ Tables)
-- Supplement to invoice.sql containing missing tables from Odoo 17
-- ============================================================

-- ============================================================
-- SECTION 0: COMPANY TENANT (Company at tenant level)
-- ============================================================

-- Company Tenant (Company thuộc tenant, khác với company ở cấp enterprise)
CREATE TABLE IF NOT EXISTS company_tenant (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  name TEXT NOT NULL,
  code VARCHAR(50),
  currency_id UUID,
  parent_id UUID,
  active BOOLEAN DEFAULT TRUE,
  street TEXT,
  street2 TEXT,
  city TEXT,
  state TEXT,
  zip TEXT,
  country_code CHAR(2),
  phone TEXT,
  email TEXT,
  website TEXT,
  vat VARCHAR(50),
  company_registry VARCHAR(50),
  logo_url TEXT,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, code),
  
  CONSTRAINT fk_company_tenant_parent
    FOREIGN KEY (tenant_id, parent_id)
    REFERENCES company_tenant(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_company_tenant_created_by
    FOREIGN KEY (tenant_id, created_by)
    REFERENCES users(tenant_id, user_id)
    ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_company_tenant_parent ON company_tenant(tenant_id, parent_id);
CREATE INDEX IF NOT EXISTS idx_company_tenant_code ON company_tenant(tenant_id, code);
CREATE INDEX IF NOT EXISTS idx_company_tenant_active ON company_tenant(tenant_id, active) WHERE active = TRUE;

-- ============================================================
-- SECTION 1: ACCOUNT MERGE & WIZARD TABLES
-- ============================================================

-- 1.1 Account Merge Wizard
CREATE TABLE IF NOT EXISTS account_merge_wizard (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  company_id UUID,
  name VARCHAR(255),
  create_uid UUID,
  write_uid UUID,
  
  create_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  update_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_merge_wizard_company
    FOREIGN KEY (tenant_id, company_id)
    REFERENCES company_tenant(tenant_id, id)
    ON DELETE RESTRICT
);

-- 1.2 Account Merge Wizard Line
CREATE TABLE IF NOT EXISTS account_merge_wizard_line (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  wizard_id UUID NOT NULL,
  account_id UUID NOT NULL,
  sequence INTEGER DEFAULT 10,
  
  create_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  update_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_merge_wizard_line_wizard
    FOREIGN KEY (tenant_id, wizard_id)
    REFERENCES account_merge_wizard(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_merge_wizard_line_account
    FOREIGN KEY (tenant_id, account_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE CASCADE
);

-- 1.3 Account Merge Wizard <-> Account (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_account_account_merge_wizard_rel (
  tenant_id UUID NOT NULL,
  account_merge_wizard_id UUID NOT NULL,
  account_account_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, account_merge_wizard_id, account_account_id),
  
  CONSTRAINT fk_account_merge_wizard_rel_wizard
    FOREIGN KEY (tenant_id, account_merge_wizard_id)
    REFERENCES account_merge_wizard(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_account_merge_wizard_rel_account
    FOREIGN KEY (tenant_id, account_account_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE CASCADE
);

-- ============================================================
-- SECTION 2: ACCOUNT TAX RELATIONSHIP TABLES
-- ============================================================

-- 2.1 Account Default Tax (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_account_tax_default_rel (
  tenant_id UUID NOT NULL,
  account_id UUID NOT NULL,
  tax_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, account_id, tax_id),
  
  CONSTRAINT fk_account_tax_default_account
    FOREIGN KEY (tenant_id, account_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_account_tax_default_tax
    FOREIGN KEY (tenant_id, tax_id)
    REFERENCES account_tax(tenant_id, id)
    ON DELETE CASCADE
);

-- 2.2 Account <-> Product Template Tags (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_account_tag_product_template_rel (
  tenant_id UUID NOT NULL,
  product_template_id UUID NOT NULL,
  account_account_tag_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, product_template_id, account_account_tag_id),
  
  CONSTRAINT fk_tag_product_template_tag
    FOREIGN KEY (tenant_id, account_account_tag_id)
    REFERENCES account_account_tag(tenant_id, id)
    ON DELETE CASCADE
);

-- 2.3 Account <-> Company (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_account_res_company_rel (
  tenant_id UUID NOT NULL,
  account_account_id UUID NOT NULL,
  res_company_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, account_account_id, res_company_id),
  
  CONSTRAINT fk_account_company_account
    FOREIGN KEY (tenant_id, account_account_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_account_company_company
    FOREIGN KEY (tenant_id, res_company_id)
    REFERENCES company_tenant(tenant_id, id)
    ON DELETE CASCADE
);

-- ============================================================
-- SECTION 3: ACCRUAL WIZARDS
-- ============================================================

-- 3.1 Accrued Orders Wizard
CREATE TABLE IF NOT EXISTS account_accrued_orders_wizard (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  company_id UUID,
  journal_id UUID NOT NULL,
  currency_id UUID,
  account_id UUID NOT NULL,
  create_uid UUID,
  write_uid UUID,
  date DATE NOT NULL,
  reversal_date DATE NOT NULL,
  amount NUMERIC(20, 4),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_accrued_orders_journal
    FOREIGN KEY (tenant_id, journal_id)
    REFERENCES account_journal(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_accrued_orders_account
    FOREIGN KEY (tenant_id, account_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE RESTRICT
);

-- 3.2 Automatic Entry Wizard
CREATE TABLE IF NOT EXISTS account_automatic_entry_wizard (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  company_id UUID,
  journal_id UUID NOT NULL,
  action VARCHAR(50), -- 'change_account', 'change_partner', 'change_date'
  date DATE NOT NULL,
  reversal_date DATE NOT NULL,
  percentage NUMERIC(5, 2),
  total_amount NUMERIC(20, 4),
  new_label TEXT,
  account_id UUID,
  partner_id UUID,
  create_uid UUID,
  write_uid UUID,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_automatic_entry_journal
    FOREIGN KEY (tenant_id, journal_id)
    REFERENCES account_journal(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_automatic_entry_account
    FOREIGN KEY (tenant_id, account_id)
    REFERENCES account_account(tenant_id, id)
    ON DELETE SET NULL,
  CONSTRAINT fk_automatic_entry_partner
    FOREIGN KEY (tenant_id, partner_id)
    REFERENCES contact(tenant_id, id)
    ON DELETE SET NULL
);

-- 3.3 Automatic Entry Wizard <-> Move Line (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_automatic_entry_wizard_account_move_line_rel (
  tenant_id UUID NOT NULL,
  wizard_id UUID NOT NULL,
  move_line_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, wizard_id, move_line_id),
  
  CONSTRAINT fk_automatic_entry_wizard_rel
    FOREIGN KEY (tenant_id, wizard_id)
    REFERENCES account_automatic_entry_wizard(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_automatic_entry_moveline_rel
    FOREIGN KEY (tenant_id, move_line_id)
    REFERENCES account_move_line(tenant_id, id)
    ON DELETE CASCADE
);

-- 3.4 AutoPost Bills Wizard
CREATE TABLE IF NOT EXISTS account_autopost_bills_wizard (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  company_id UUID,
  enable_autopost BOOLEAN DEFAULT FALSE,
  post_date_number INTEGER DEFAULT 1,
  post_date_type VARCHAR(20), -- 'days', 'months'
  post_by_date VARCHAR(50), -- 'invoice_date', 'due_date'
  create_uid UUID,
  write_uid UUID,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id)
);

-- ============================================================
-- SECTION 4: BANK STATEMENT RELATIONSHIPS
-- ============================================================

-- 4.1 Bank Statement <-> Attachment (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_bank_statement_ir_attachment_rel (
  tenant_id UUID NOT NULL,
  statement_id UUID NOT NULL,
  attachment_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, statement_id, attachment_id),
  
  CONSTRAINT fk_bank_statement_attachment
    FOREIGN KEY (tenant_id, statement_id)
    REFERENCES account_bank_statement(tenant_id, id)
    ON DELETE CASCADE
);

-- 4.2 Payment <-> Bank Statement Line (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_payment_account_bank_statement_line_rel (
  tenant_id UUID NOT NULL,
  payment_id UUID NOT NULL,
  statement_line_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, payment_id, statement_line_id),
  
  CONSTRAINT fk_payment_bank_stmt_payment
    FOREIGN KEY (tenant_id, payment_id)
    REFERENCES account_payment(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_payment_bank_stmt_line
    FOREIGN KEY (tenant_id, statement_line_id)
    REFERENCES account_bank_statement_line(tenant_id, id)
    ON DELETE CASCADE
);

-- ============================================================
-- SECTION 5: FISCAL POSITION RELATIONSHIPS
-- ============================================================

-- 5.1 Fiscal Position Account Tax (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_fiscal_position_account_tax_rel (
  tenant_id UUID NOT NULL,
  position_id UUID NOT NULL,
  tax_src_id UUID NOT NULL,
  tax_dest_id UUID,
  
  PRIMARY KEY (tenant_id, position_id, tax_src_id),
  
  CONSTRAINT fk_fiscal_pos_account_tax_rel_position
    FOREIGN KEY (tenant_id, position_id)
    REFERENCES account_fiscal_position(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_fiscal_pos_account_tax_rel_src
    FOREIGN KEY (tenant_id, tax_src_id)
    REFERENCES account_tax(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_fiscal_pos_account_tax_rel_dest
    FOREIGN KEY (tenant_id, tax_dest_id)
    REFERENCES account_tax(tenant_id, id)
    ON DELETE CASCADE
);

-- 5.2 Fiscal Position <-> Country State (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_fiscal_position_res_country_state_rel (
  tenant_id UUID NOT NULL,
  position_id UUID NOT NULL,
  state_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, position_id, state_id),
  
  CONSTRAINT fk_fiscal_pos_state_rel
    FOREIGN KEY (tenant_id, position_id)
    REFERENCES account_fiscal_position(tenant_id, id)
    ON DELETE CASCADE
);

-- ============================================================
-- SECTION 6: INVOICE TRANSACTION & PAYMENT REGISTER
-- ============================================================

-- 6.1 Invoice Transaction (Ghi nhận giao dịch thanh toán)
CREATE TABLE IF NOT EXISTS account_invoice_transaction_rel (
  tenant_id UUID NOT NULL,
  move_id UUID NOT NULL,
  transaction_id VARCHAR(255) NOT NULL,
  
  PRIMARY KEY (tenant_id, move_id, transaction_id),
  
  CONSTRAINT fk_invoice_transaction_move
    FOREIGN KEY (tenant_id, move_id)
    REFERENCES account_move(tenant_id, id)
    ON DELETE CASCADE
);

-- 6.2 Payment Register (Đơn đăng ký thanh toán - Wizard)
CREATE TABLE IF NOT EXISTS account_payment_register (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  company_id UUID,
  payment_date DATE NOT NULL,
  journal_id UUID NOT NULL,
  currency_id UUID,
  payment_method_id UUID,
  partner_type VARCHAR(20), -- 'customer', 'supplier'
  partner_id UUID,
  source_currency_id UUID,
  can_edit_reference BOOLEAN DEFAULT FALSE,
  group_payment BOOLEAN DEFAULT FALSE,
  payment_difference NUMERIC(20, 4) DEFAULT 0,
  payment_difference_handling VARCHAR(20), -- 'open', 'reconcile'
  writeoff_account_id UUID,
  writeoff_label TEXT,
  create_uid UUID,
  write_uid UUID,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_payment_register_journal
    FOREIGN KEY (tenant_id, journal_id)
    REFERENCES account_journal(tenant_id, id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_payment_register_partner
    FOREIGN KEY (tenant_id, partner_id)
    REFERENCES contact(tenant_id, id)
    ON DELETE RESTRICT
);

-- 6.3 Payment Register <-> Move Line (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_payment_register_move_line_rel (
  tenant_id UUID NOT NULL,
  register_id UUID NOT NULL,
  move_line_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, register_id, move_line_id),
  
  CONSTRAINT fk_payment_register_rel_register
    FOREIGN KEY (tenant_id, register_id)
    REFERENCES account_payment_register(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_payment_register_rel_moveline
    FOREIGN KEY (tenant_id, move_line_id)
    REFERENCES account_move_line(tenant_id, id)
    ON DELETE CASCADE
);

-- ============================================================
-- SECTION 7: JOURNAL RELATIONSHIPS
-- ============================================================

-- 7.1 Journal <-> Journal Group (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_journal_account_journal_group_rel (
  tenant_id UUID NOT NULL,
  journal_id UUID NOT NULL,
  journal_group_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, journal_id, journal_group_id),
  
  CONSTRAINT fk_journal_group_rel_journal
    FOREIGN KEY (tenant_id, journal_id)
    REFERENCES account_journal(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_journal_group_rel_group
    FOREIGN KEY (tenant_id, journal_group_id)
    REFERENCES account_journal_group(tenant_id, id)
    ON DELETE CASCADE
);

-- 7.2 Journal <-> Reconcile Model (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_journal_account_reconcile_model_rel (
  tenant_id UUID NOT NULL,
  journal_id UUID NOT NULL,
  reconcile_model_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, journal_id, reconcile_model_id),
  
  CONSTRAINT fk_journal_reconcile_model_rel_journal
    FOREIGN KEY (tenant_id, journal_id)
    REFERENCES account_journal(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_journal_reconcile_model_rel_model
    FOREIGN KEY (tenant_id, reconcile_model_id)
    REFERENCES account_reconcile_model(tenant_id, id)
    ON DELETE CASCADE
);

-- ============================================================
-- SECTION 8: MOVE & PAYMENT RELATIONSHIPS
-- ============================================================

-- 8.1 Move <-> Payment (Direct relationship for multi-payments)
CREATE TABLE IF NOT EXISTS account_move__account_payment (
  tenant_id UUID NOT NULL,
  move_id UUID NOT NULL,
  payment_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, move_id, payment_id),
  
  CONSTRAINT fk_move_payment_direct_move
    FOREIGN KEY (tenant_id, move_id)
    REFERENCES account_move(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_move_payment_direct_payment
    FOREIGN KEY (tenant_id, payment_id)
    REFERENCES account_payment(tenant_id, id)
    ON DELETE CASCADE
);

-- 8.2 Move Send Wizard
CREATE TABLE IF NOT EXISTS account_move_send_wizard (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  company_id UUID,
  move_id UUID NOT NULL,
  enable_download BOOLEAN DEFAULT FALSE,
  enable_send BOOLEAN DEFAULT FALSE,
  prefixed_download_filename VARCHAR(255),
  prefixed_send_mail_with_sign BOOLEAN DEFAULT FALSE,
  prefixed_send_mail_template_edi VARCHAR(255),
  prefixed_send_mail_template_ubl VARCHAR(255),
  prefixed_send_mail_template_pdf VARCHAR(255),
  prefixed_send_mail_subject VARCHAR(255),
  prefixed_send_mail_body TEXT,
  prefixed_send_mail_body_is_html BOOLEAN DEFAULT TRUE,
  create_uid UUID,
  write_uid UUID,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_move_send_wizard_move
    FOREIGN KEY (tenant_id, move_id)
    REFERENCES account_move(tenant_id, id)
    ON DELETE CASCADE
);

-- 8.3 Move Send Wizard <-> Partner (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_move_send_wizard_res_partner_rel (
  tenant_id UUID NOT NULL,
  wizard_id UUID NOT NULL,
  partner_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, wizard_id, partner_id),
  
  CONSTRAINT fk_move_send_partner_rel_wizard
    FOREIGN KEY (tenant_id, wizard_id)
    REFERENCES account_move_send_wizard(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_move_send_partner_rel_partner
    FOREIGN KEY (tenant_id, partner_id)
    REFERENCES contact(tenant_id, id)
    ON DELETE CASCADE
);

-- 8.4 Move Send Batch Wizard
CREATE TABLE IF NOT EXISTS account_move_send_batch_wizard (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  company_id UUID,
  enable_download BOOLEAN DEFAULT FALSE,
  enable_send BOOLEAN DEFAULT FALSE,
  prefixed_send_mail_with_sign BOOLEAN DEFAULT FALSE,
  prefixed_send_mail_subject VARCHAR(255),
  prefixed_send_mail_body TEXT,
  create_uid UUID,
  write_uid UUID,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id)
);

-- 8.5 Move Send Batch Wizard <-> Move (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_move_account_move_send_batch_wizard_rel (
  tenant_id UUID NOT NULL,
  move_id UUID NOT NULL,
  wizard_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, move_id, wizard_id),
  
  CONSTRAINT fk_move_batch_wizard_rel_move
    FOREIGN KEY (tenant_id, move_id)
    REFERENCES account_move(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_move_batch_wizard_rel_wizard
    FOREIGN KEY (tenant_id, wizard_id)
    REFERENCES account_move_send_batch_wizard(tenant_id, id)
    ON DELETE CASCADE
);

-- 8.6 Move Resequence Wizard
CREATE TABLE IF NOT EXISTS account_resequence_wizard (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  company_id UUID,
  journal_id UUID,
  new_name VARCHAR(255),
  first_name VARCHAR(255),
  last_name VARCHAR(255),
  ordering VARCHAR(50), -- 'date', 'name'
  reverse_sequence BOOLEAN DEFAULT FALSE,
  create_uid UUID,
  write_uid UUID,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id),
  
  CONSTRAINT fk_resequence_wizard_journal
    FOREIGN KEY (tenant_id, journal_id)
    REFERENCES account_journal(tenant_id, id)
    ON DELETE SET NULL
);

-- 8.7 Move Resequence Wizard <-> Move (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_move_account_resequence_wizard_rel (
  tenant_id UUID NOT NULL,
  move_id UUID NOT NULL,
  wizard_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, move_id, wizard_id),
  
  CONSTRAINT fk_move_resequence_rel_move
    FOREIGN KEY (tenant_id, move_id)
    REFERENCES account_move(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_move_resequence_rel_wizard
    FOREIGN KEY (tenant_id, wizard_id)
    REFERENCES account_resequence_wizard(tenant_id, id)
    ON DELETE CASCADE
);

-- 8.8 Move Validate Wizard (M2M với account_move)
CREATE TABLE IF NOT EXISTS account_move_validate_account_move_rel (
  tenant_id UUID NOT NULL,
  source_move_id UUID NOT NULL,
  target_move_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, source_move_id, target_move_id),
  
  CONSTRAINT fk_move_validate_source
    FOREIGN KEY (tenant_id, source_move_id)
    REFERENCES account_move(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_move_validate_target
    FOREIGN KEY (tenant_id, target_move_id)
    REFERENCES account_move(tenant_id, id)
    ON DELETE CASCADE
);

-- ============================================================
-- SECTION 9: RECONCILIATION MODEL RELATIONSHIPS
-- ============================================================

-- 9.1 Reconcile Model Line <-> Tax (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_reconcile_model_line_account_tax_rel (
  tenant_id UUID NOT NULL,
  model_line_id UUID NOT NULL,
  tax_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, model_line_id, tax_id),
  
  CONSTRAINT fk_reconcile_model_line_tax_rel_line
    FOREIGN KEY (tenant_id, model_line_id)
    REFERENCES account_reconcile_model_line(tenant_id, id)
    ON DELETE CASCADE,
  CONSTRAINT fk_reconcile_model_line_tax_rel_tax
    FOREIGN KEY (tenant_id, tax_id)
    REFERENCES account_tax(tenant_id, id)
    ON DELETE CASCADE
);

-- ============================================================
-- SECTION 10: REPORTING RELATIONSHIPS
-- ============================================================

-- 10.1 Account Report <-> Section (Many-to-Many)
CREATE TABLE IF NOT EXISTS account_report_section_rel (
  tenant_id UUID NOT NULL,
  report_id UUID NOT NULL,
  section_id UUID NOT NULL,
  
  PRIMARY KEY (tenant_id, report_id, section_id),
  
  CONSTRAINT fk_report_section_rel_report
    FOREIGN KEY (tenant_id, report_id)
    REFERENCES account_report(tenant_id, id)
    ON DELETE CASCADE
);

-- ============================================================
-- SECTION 11: SECURE ENTRIES & HELPERS
-- ============================================================

-- 11.1 Secure Entries Wizard (Xác bảo các bút toán)
CREATE TABLE IF NOT EXISTS account_secure_entries_wizard (
  tenant_id UUID NOT NULL,
  id UUID NOT NULL,
  company_id UUID,
  closing_date DATE NOT NULL,
  action VARCHAR(50), -- 'lock', 'unlock'
  create_uid UUID,
  write_uid UUID,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  PRIMARY KEY (tenant_id, id)
);

-- ============================================================
-- COMMENTS FOR ADDITIONAL DOCUMENTATION
-- ============================================================

COMMENT ON TABLE account_merge_wizard IS 'Account merge wizard - Merge multiple accounts into one (Odoo: account.merge.wizard)';
COMMENT ON TABLE account_merge_wizard_line IS 'Account merge wizard lines';
COMMENT ON TABLE account_accrued_orders_wizard IS 'Accrued orders wizard - Create accrual journal entries (Odoo: account.accrued.orders.wizard)';
COMMENT ON TABLE account_automatic_entry_wizard IS 'Automatic entry wizard - Generate automatic entries (Odoo: account.automatic.entry.wizard)';
COMMENT ON TABLE account_autopost_bills_wizard IS 'Auto-post bills wizard (Odoo: account.autopost.bills.wizard)';
COMMENT ON TABLE account_payment_register IS 'Payment register - Multi-payment wizard (Odoo: account.payment.register)';
COMMENT ON TABLE account_move_send_wizard IS 'Move send wizard - Send invoices by email/download (Odoo: account.move.send.wizard)';
COMMENT ON TABLE account_move_send_batch_wizard IS 'Move send batch wizard - Send multiple invoices (Odoo: account.move.send.batch.wizard)';
COMMENT ON TABLE account_resequence_wizard IS 'Move resequence wizard - Reorder journal entries (Odoo: account.resequence.wizard)';
COMMENT ON TABLE account_secure_entries_wizard IS 'Secure entries wizard - Lock/unlock period (Odoo: account.secure.entries.wizard)';
COMMENT ON TABLE account_payment_register IS 'Payment registration tool (Odoo: account.payment.register)';

-- ============================================================
-- END OF INVOICE2 MODULE MIGRATION (25+ Tables Complete)
-- ============================================================