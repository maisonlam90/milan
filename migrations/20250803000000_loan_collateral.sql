-- ============================================================
-- 🔄 RESET COLLATERAL (assets + link) — Postgres / Yugabyte YSQL
-- ============================================================

-- (Tuỳ hệ thống, giữ lại nếu chưa có)
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid()
SET TIME ZONE 'UTC';

-- 1) Drop theo thứ tự phụ thuộc
DROP TABLE IF EXISTS loan_collateral   CASCADE;
DROP TABLE IF EXISTS collateral_assets CASCADE;

-- 2) TÀI SẢN THẾ CHẤP
CREATE TABLE collateral_assets (
    tenant_id         UUID NOT NULL,                                   -- 🔑 shard key
    asset_id          UUID NOT NULL DEFAULT gen_random_uuid(),         -- 🔑 id tài sản
    asset_type        TEXT NOT NULL,                                   -- 'vehicle','real_estate',...
    description       TEXT,
    value_estimate    NUMERIC(18,2),                                   -- ↔ sqlx::types::BigDecimal (Option)
    owner_contact_id  UUID,                                            -- contact_id (nullable)
    status            TEXT NOT NULL DEFAULT 'available',               -- available/pledged/released/sold/disposed
    created_by        UUID NOT NULL,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

    PRIMARY KEY (tenant_id, asset_id),

    CONSTRAINT ck_collateral_asset_type_non_empty CHECK (length(trim(asset_type)) > 0),
    CONSTRAINT ck_collateral_value_positive      CHECK (value_estimate IS NULL OR value_estimate >= 0),
    CONSTRAINT ck_collateral_status              CHECK (status IN ('available','pledged','released','sold','disposed'))
);

-- Index phổ biến (phục vụ tìm kiếm theo chủ sở hữu / loại / trạng thái / audit)
CREATE INDEX idx_collateral_by_owner      ON collateral_assets (tenant_id, owner_contact_id);
CREATE INDEX idx_collateral_by_type       ON collateral_assets (tenant_id, asset_type);
CREATE INDEX idx_collateral_by_status     ON collateral_assets (tenant_id, status);
CREATE INDEX idx_collateral_by_created_by ON collateral_assets (tenant_id, created_by);
CREATE INDEX idx_collateral_created_at    ON collateral_assets (tenant_id, created_at);

-- (Nếu có bảng contact(tenant_id,id) thì mở FK dưới đây)
-- ALTER TABLE collateral_assets
--   ADD CONSTRAINT fk_collateral_owner_contact
--   FOREIGN KEY (tenant_id, owner_contact_id) REFERENCES contact(tenant_id, id);

-- 3) LIÊN KẾT HỢP ĐỒNG ↔ TÀI SẢN
CREATE TABLE loan_collateral (
    tenant_id    UUID NOT NULL,
    contract_id  UUID NOT NULL,
    asset_id     UUID NOT NULL,
    pledge_value NUMERIC(18,2),                          -- giá trị cam kết (tuỳ chọn)
    status       TEXT NOT NULL DEFAULT 'active',         -- active/released
    released_at  TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by   UUID NOT NULL,

    PRIMARY KEY (tenant_id, contract_id, asset_id),

    FOREIGN KEY (tenant_id, contract_id)
      REFERENCES loan_contract (tenant_id, id)
      ON DELETE CASCADE,

    FOREIGN KEY (tenant_id, asset_id)
      REFERENCES collateral_assets (tenant_id, asset_id)
      ON DELETE CASCADE,

    CONSTRAINT ck_pledge_value_positive CHECK (pledge_value IS NULL OR pledge_value >= 0),
    CONSTRAINT ck_loan_collateral_status CHECK (status IN ('active','released'))
);

-- Mỗi tài sản chỉ được "active" ở 1 hợp đồng tại 1 thời điểm
CREATE UNIQUE INDEX uq_asset_active_once
  ON loan_collateral (tenant_id, asset_id)
  WHERE status = 'active' AND released_at IS NULL;

-- Index tra cứu nhanh
CREATE INDEX idx_loan_collateral_by_asset    ON loan_collateral (tenant_id, asset_id);
CREATE INDEX idx_loan_collateral_by_contract ON loan_collateral (tenant_id, contract_id);
