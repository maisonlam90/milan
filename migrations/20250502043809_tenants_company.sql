-- ============================================================
-- 2) COMPANY (ĐA CẤP) DƯỚI ENTERPRISE
--    - Bảng company: node trong cây công ty
--    - Bảng company_edge: closure table lưu quan hệ ancestor/descendant
-- ============================================================
CREATE TABLE IF NOT EXISTS company (
  company_id    UUID PRIMARY KEY,                                     -- ID công ty
  enterprise_id UUID NOT NULL REFERENCES enterprise(enterprise_id),   -- Thuộc enterprise nào
  name          TEXT NOT NULL,                                        -- Tên công ty
  slug          TEXT,                                                 -- Định danh ngắn (unique trong 1 enterprise)
  created_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE (enterprise_id, slug)
);

-- Closure table cho cây company:
-- - depth = 0: (node, node) chính nó
-- - depth = 1: quan hệ cha-con trực tiếp
-- - depth > 1: ancestor các cấp
CREATE TABLE IF NOT EXISTS company_edge (
  enterprise_id UUID NOT NULL,      -- Ràng enterprise cho mọi cạnh
  ancestor_id   UUID NOT NULL,      -- ID tổ tiên
  descendant_id UUID NOT NULL,      -- ID hậu duệ
  depth         INT  NOT NULL,      -- Độ sâu (0 = chính nó)
  PRIMARY KEY (enterprise_id, ancestor_id, descendant_id)
  -- Có thể thêm FK cứng, nhưng dev ban đầu thường để mềm để insert batch nhanh:
  -- , FOREIGN KEY (ancestor_id)   REFERENCES company(company_id) ON DELETE CASCADE
  -- , FOREIGN KEY (descendant_id) REFERENCES company(company_id) ON DELETE CASCADE
);

-- Index phổ biến cho truy vấn subtree/ancestor
CREATE INDEX IF NOT EXISTS idx_company_edge_ancestor
  ON company_edge (enterprise_id, ancestor_id);
CREATE INDEX IF NOT EXISTS idx_company_edge_descendant
  ON company_edge (enterprise_id, descendant_id);
