-- ============================================================
-- 📇 CONTACT MODULE — RESET & CREATE (clean rebuild)
-- ============================================================

-- Bảng contact
CREATE TABLE IF NOT EXISTS contact (
  tenant_id   UUID NOT NULL,
  id          UUID NOT NULL,
  is_company  BOOLEAN NOT NULL DEFAULT FALSE,
  parent_id   UUID,

  name          TEXT NOT NULL,
  display_name  TEXT,
  email         TEXT,     -- CHECK + UNIQUE per-tenant ở dưới
  phone         TEXT,     -- digits only
  mobile        TEXT,     -- digits only
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

  created_by   UUID NOT NULL,    -- FK users cùng tenant
  assignee_id  UUID,
  shared_with  UUID[] DEFAULT '{}',

  PRIMARY KEY (tenant_id, id),

  -- CHECK
  CONSTRAINT contact_email_lower_check
    CHECK (email IS NULL OR email = lower(email)),
  CONSTRAINT contact_email_format_check
    CHECK (email IS NULL OR email ~ '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$'),
  CONSTRAINT contact_phone_digits_check
    CHECK (phone IS NULL OR phone  ~ '^[0-9]{8,15}$'),
  CONSTRAINT contact_mobile_digits_check
    CHECK (mobile IS NULL OR mobile ~ '^[0-9]{8,15}$'),
  CONSTRAINT contact_web_format_check
    CHECK (website IS NULL OR website ~* '^(https?://)?[a-z0-9.-]+\.[a-z]{2,}(/.*)?$'),
  CONSTRAINT contact_country_code_check
    CHECK (country_code IS NULL OR country_code ~ '^[A-Z]{2}$'),
  CONSTRAINT contact_zip_check
    CHECK (zip IS NULL OR zip ~ '^[A-Za-z0-9 -]{3,16}$'),

  -- FK composite để bảo đảm đồng-tenant (sharding đúng)
  CONSTRAINT fk_contact_parent_same_tenant
    FOREIGN KEY (tenant_id, parent_id) REFERENCES contact(tenant_id, id)
    ON UPDATE CASCADE ON DELETE SET NULL,
  CONSTRAINT fk_contact_created_by_user
    FOREIGN KEY (tenant_id, created_by) REFERENCES users(tenant_id, user_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_contact_assignee_user
    FOREIGN KEY (tenant_id, assignee_id) REFERENCES users(tenant_id, user_id)
    ON UPDATE CASCADE ON DELETE SET NULL
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
