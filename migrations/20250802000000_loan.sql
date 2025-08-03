-- Bảng hợp đồng vay (loan_contract)
CREATE TABLE IF NOT EXISTS loan_contract (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL,                         -- FK tới tenant
    customer_id UUID NOT NULL,                       -- FK tới user/customer

    name TEXT NOT NULL,                              -- Số hợp đồng
    principal BIGINT NOT NULL,                       -- Số tiền vay ban đầu
    interest_rate DOUBLE PRECISION NOT NULL,         -- Lãi suất %/năm
    term_months INT NOT NULL,                        -- Kỳ hạn (tháng)

    -- ❗ Chuyển từ DATE -> TIMESTAMPTZ để lưu cả giờ phút và múi giờ
    date_start TIMESTAMPTZ NOT NULL,                 -- Ngày bắt đầu vay
    date_end TIMESTAMPTZ,                            -- Ngày kết thúc

    collateral_description TEXT,                     -- Mô tả tài sản thế chấp
    collateral_value BIGINT DEFAULT 0,               -- Giá trị tài sản
    storage_fee_rate DOUBLE PRECISION DEFAULT 0,     -- % phí lưu kho/ngày
    storage_fee BIGINT DEFAULT 0,                    -- Tổng phí lưu kho

    current_principal BIGINT DEFAULT 0,              -- Số dư gốc hiện tại
    current_interest BIGINT DEFAULT 0,               -- Lãi chưa thu
    accumulated_interest BIGINT DEFAULT 0,           -- Lãi tích lũy
    total_paid_interest BIGINT DEFAULT 0,            -- Tổng lãi đã trả
    total_settlement_amount BIGINT DEFAULT 0,        -- Tổng tất toán

    state TEXT NOT NULL DEFAULT 'draft',             -- draft/active/paid/default
    created_at TIMESTAMPTZ DEFAULT NOW(),            -- ❗ Giữ TIMESTAMPTZ
    updated_at TIMESTAMPTZ DEFAULT NOW()             -- ❗ Giữ TIMESTAMPTZ
);

-- Bảng giao dịch của hợp đồng vay (loan_transaction)
CREATE TABLE IF NOT EXISTS loan_transaction (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contract_id UUID NOT NULL REFERENCES loan_contract(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL,                         -- FK tới tenant (để query nhanh)
    customer_id UUID NOT NULL,                       -- FK tới user/customer (để query nhanh)

    transaction_type TEXT NOT NULL CHECK (
        transaction_type IN (
            'disbursement',    -- Giải ngân
            'interest',        -- Thu lãi
            'principal',       -- Thu gốc
            'additional',      -- Giải ngân bổ sung
            'liquidation',     -- Thanh lý
            'settlement'       -- Tất toán
        )
    ),

    amount BIGINT NOT NULL,                          -- Số tiền (+/-)

    -- ❗ Chuyển từ DATE -> TIMESTAMPTZ để chính xác theo thời gian
    date TIMESTAMPTZ NOT NULL,                       -- Ngày giao dịch

    note TEXT,                                       -- Ghi chú

    days_from_prev INT DEFAULT 0,                    -- Số ngày tính lãi
    interest_for_period BIGINT DEFAULT 0,            -- Lãi kỳ này
    accumulated_interest BIGINT DEFAULT 0,           -- Lãi tích lũy sau giao dịch
    principal_balance BIGINT DEFAULT 0,              -- Dư nợ gốc sau giao dịch

    created_at TIMESTAMPTZ DEFAULT NOW(),            -- ❗ Giữ TIMESTAMPTZ
    updated_at TIMESTAMPTZ DEFAULT NOW()             -- ❗ Giữ TIMESTAMPTZ
);

-- Index tối ưu query
CREATE INDEX IF NOT EXISTS idx_loan_contract_tenant ON loan_contract(tenant_id);
CREATE INDEX IF NOT EXISTS idx_loan_contract_customer ON loan_contract(customer_id);

CREATE INDEX IF NOT EXISTS idx_loan_transaction_tenant ON loan_transaction(tenant_id);
CREATE INDEX IF NOT EXISTS idx_loan_transaction_customer ON loan_transaction(customer_id);
CREATE INDEX IF NOT EXISTS idx_loan_transaction_contract ON loan_transaction(contract_id);
