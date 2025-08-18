-- ============================================================
-- 📇 CONTACT MODULE — RESET & CREATE (clean rebuild)
-- ============================================================

-- Bảng contact
CREATE TABLE IF NOT EXISTS contact (
  tenant_id UUID NOT NULL,
  id        UUID NOT NULL,
  is_company BOOLEAN NOT NULL DEFAULT FALSE,
  parent_id UUID,

  name          TEXT NOT NULL,
  display_name  TEXT,
  email         TEXT,
  phone         TEXT,
  mobile        TEXT,
  website       TEXT,
  street        TEXT,
  street2       TEXT,
  city          TEXT,
  state         TEXT,
  zip           TEXT,
  country_code  CHAR(2),
  notes         TEXT,
  tags_cached   TEXT,
  idempotency_key TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- 👇 IAM phân quyền theo người tạo/giao việc/chia sẻ
  created_by   UUID NOT NULL,
  assignee_id  UUID,
  shared_with  UUID[] DEFAULT '{}',

  PRIMARY KEY (tenant_id, id)
);

ALTER TABLE contact
  ADD CONSTRAINT contact_parent_fk
  FOREIGN KEY (tenant_id, parent_id)
  REFERENCES contact (tenant_id, id) ON DELETE SET NULL;

-- Index tìm kiếm
CREATE INDEX IF NOT EXISTS idx_contact_tenant_name
  ON contact (tenant_id, lower(name));

CREATE INDEX IF NOT EXISTS idx_contact_tenant_email
  ON contact (tenant_id, lower(email));

CREATE INDEX IF NOT EXISTS idx_contact_tenant_phone
  ON contact (tenant_id, phone);

-- IAM Index
CREATE INDEX IF NOT EXISTS idx_contact_created_by ON contact(tenant_id, created_by);
CREATE INDEX IF NOT EXISTS idx_contact_assignee   ON contact(tenant_id, assignee_id);
CREATE INDEX IF NOT EXISTS idx_contact_shared     ON contact USING GIN(shared_with);

-- Idempotency
CREATE UNIQUE INDEX IF NOT EXISTS uq_contact_idem
  ON contact (tenant_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;

-- Bảng tag
CREATE TABLE IF NOT EXISTS contact_tag (
  tenant_id UUID NOT NULL,
  id        UUID NOT NULL,
  name      TEXT NOT NULL,
  name_key  TEXT NOT NULL,
  color     TEXT,
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, name_key)
);

-- Liên kết contact-tag
CREATE TABLE IF NOT EXISTS contact_tag_link (
  tenant_id  UUID NOT NULL,
  contact_id UUID NOT NULL,
  tag_id     UUID NOT NULL,
  PRIMARY KEY (tenant_id, contact_id, tag_id),
  FOREIGN KEY (tenant_id, contact_id) REFERENCES contact (tenant_id, id) ON DELETE CASCADE,
  FOREIGN KEY (tenant_id, tag_id)     REFERENCES contact_tag (tenant_id, id) ON DELETE CASCADE
);
