-- ============================================================
-- 💳 LOAN MODULE — RESET & CREATE (clean rebuild)
-- ============================================================

-- 0) Extensions & timezone

SET TIME ZONE 'UTC';

-- ------------------------------------------------------------
-- 2) HỢP ĐỒNG VAY (loan_contract)
-- ------------------------------------------------------------
CREATE TABLE loan_contract (
    tenant_id UUID NOT NULL,                                   -- 🔑 shard key
    id        UUID NOT NULL DEFAULT gen_random_uuid(),         -- 🔑 id hợp đồng
    contact_id UUID NOT NULL,                                  -- KH/đối tác (khớp code: contact_id)

    contract_number            TEXT NOT NULL,                             -- Số/tên hợp đồng
    interest_rate   DOUBLE PRECISION NOT NULL,                 -- Lãi suất %/năm (vd: 0.18 = 18%)
    term_months     INT NOT NULL,                              -- Kỳ hạn (tháng)

    date_start      TIMESTAMPTZ NOT NULL,                      -- Ngày bắt đầu vay
    date_end        TIMESTAMPTZ,                               -- Ngày kết thúc (nullable)


    storage_fee_rate       DOUBLE PRECISION NOT NULL DEFAULT 0,-- % phí lưu kho/ngày
    storage_fee            BIGINT NOT NULL DEFAULT 0,          -- Tổng phí lưu kho

    current_principal       BIGINT NOT NULL DEFAULT 0,         -- Số dư gốc hiện tại
    current_interest        BIGINT NOT NULL DEFAULT 0,         -- Lãi chưa thu
    accumulated_interest    BIGINT NOT NULL DEFAULT 0,         -- Lãi tích lũy
    total_paid_interest     BIGINT NOT NULL DEFAULT 0,         -- Tổng lãi đã trả
    total_settlement_amount BIGINT NOT NULL DEFAULT 0,         -- Tổng tất toán

    state       TEXT NOT NULL DEFAULT 'draft',                 -- draft/active/paid/default
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- 👇 Thêm cho phân quyền bản ghi
    created_by   UUID NOT NULL,
    assignee_id  UUID,
    shared_with  UUID[] DEFAULT '{}',

    PRIMARY KEY (tenant_id, id)
);

-- Index tối ưu
CREATE INDEX idx_loan_contract_tenant          ON loan_contract (tenant_id);
CREATE INDEX idx_loan_contract_tenant_state    ON loan_contract (tenant_id, state);
CREATE INDEX idx_loan_contract_tenant_contact  ON loan_contract (tenant_id, contact_id);
CREATE INDEX idx_loan_contract_tenant_dates    ON loan_contract (tenant_id, date_start, date_end);

-- Index IAM
CREATE INDEX idx_loan_contract_created_by ON loan_contract(tenant_id, created_by);
CREATE INDEX idx_loan_contract_assignee   ON loan_contract(tenant_id, assignee_id);
CREATE INDEX idx_loan_contract_shared     ON loan_contract USING GIN(shared_with);

-- Trigger updated_at
CREATE OR REPLACE FUNCTION trg_loan_contract_set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

CREATE TRIGGER loan_contract_set_updated_at
BEFORE UPDATE ON loan_contract
FOR EACH ROW
EXECUTE FUNCTION trg_loan_contract_set_updated_at();

-- Tạo số hợp đồng tự động
-- 1) Counter theo tháng (per-tenant, per-YYYYMM)
-- Counter theo tenant + tháng (YYYYMM)
CREATE TABLE IF NOT EXISTS loan_counters_monthly (
  tenant_id  UUID NOT NULL,
  period_ym  INT  NOT NULL,
  counter    BIGINT NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, period_ym)
);


-- B) UNIQUE INDEX (idempotent, khuyến nghị)
CREATE UNIQUE INDEX IF NOT EXISTS uq_loan_contract_tenant_no_idx
ON loan_contract (tenant_id, contract_number);

-- ------------------------------------------------------------
-- 3) GIAO DỊCH HỢP ĐỒNG (loan_transaction)
-- ------------------------------------------------------------
CREATE TABLE loan_transaction (
    tenant_id   UUID NOT NULL,
    id          UUID NOT NULL DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL,
    contact_id  UUID NOT NULL,

    transaction_type TEXT NOT NULL CHECK (
      transaction_type IN (
        'disbursement','interest','principal',
        'additional','liquidation','settlement'
      )
    ),

    amount BIGINT NOT NULL,
    "date" TIMESTAMPTZ NOT NULL,
    note   TEXT,

    days_from_prev        INT    NOT NULL DEFAULT 0,
    interest_for_period   BIGINT NOT NULL DEFAULT 0,
    accumulated_interest  BIGINT NOT NULL DEFAULT 0,
    principal_balance     BIGINT NOT NULL DEFAULT 0,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- 👇 Thêm cho phân quyền bản ghi
    created_by   UUID NOT NULL,
    assignee_id  UUID,
    shared_with  UUID[] DEFAULT '{}',

    PRIMARY KEY (tenant_id, id),

    CONSTRAINT fk_loan_tx_contract
      FOREIGN KEY (tenant_id, contract_id)
      REFERENCES loan_contract (tenant_id, id)
      ON DELETE CASCADE
);

-- Index tối ưu
CREATE INDEX idx_loan_tx_tenant           ON loan_transaction (tenant_id);
CREATE INDEX idx_loan_tx_tenant_contract  ON loan_transaction (tenant_id, contract_id);
CREATE INDEX idx_loan_tx_tenant_contact   ON loan_transaction (tenant_id, contact_id);

-- Index IAM
CREATE INDEX idx_loan_tx_created_by ON loan_transaction(tenant_id, created_by);
CREATE INDEX idx_loan_tx_assignee   ON loan_transaction(tenant_id, assignee_id);
CREATE INDEX idx_loan_tx_shared     ON loan_transaction USING GIN(shared_with);

-- Trigger updated_at
CREATE OR REPLACE FUNCTION trg_loan_transaction_set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

CREATE TRIGGER loan_transaction_set_updated_at
BEFORE UPDATE ON loan_transaction
FOR EACH ROW
EXECUTE FUNCTION trg_loan_transaction_set_updated_at();
