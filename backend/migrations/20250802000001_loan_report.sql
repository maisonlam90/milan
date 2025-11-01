CREATE TABLE loan_report (
    tenant_id UUID NOT NULL,
    contract_id UUID NOT NULL,
    contact_id UUID NOT NULL,
    date       DATE NOT NULL, -- UTC-based (không phải local timezone)

    current_principal       BIGINT,
    current_interest        BIGINT,
    accumulated_interest    BIGINT,
    total_paid_interest     BIGINT,
    total_paid_principal    BIGINT,
    payoff_due              BIGINT,

    state TEXT NOT NULL,

    PRIMARY KEY (tenant_id, contract_id, date)
) SPLIT INTO 10 TABLETS;

CREATE INDEX idx_loan_report_tenant_date
ON loan_report (tenant_id, date);

CREATE INDEX idx_loan_report_tenant_state
ON loan_report (tenant_id, state);

CREATE INDEX IF NOT EXISTS idx_loan_tx_tenant_contract_date
ON loan_transaction (tenant_id, contract_id, date);

CREATE UNIQUE INDEX IF NOT EXISTS uq_loan_report_tenant_contract_date
ON loan_report (tenant_id, contract_id, date);