-- ============================================================
-- 2) COMPANY (đa cấp) dưới ENTERPRISE
--    - RÀNG BUỘC: không thể tạo cạnh cha-con lệch enterprise
--    - Dùng closure table company_edge
-- ============================================================

-- ========== BẢNG company ==========
CREATE TABLE IF NOT EXISTS company (
  company_id    UUID PRIMARY KEY,                                     -- ID công ty
  enterprise_id UUID NOT NULL REFERENCES enterprise(enterprise_id),   -- Thuộc enterprise nào
  name          TEXT NOT NULL,                                        -- Tên công ty
  slug          TEXT,                                                 -- Định danh ngắn (unique trong 1 enterprise)
  created_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE (enterprise_id, slug),

  -- Để làm đích cho các FK composite từ company_edge / tenant
  CONSTRAINT uq_company_enterprise_company UNIQUE (enterprise_id, company_id)
);

-- ========== BẢNG company_edge ==========
-- Closure table cho cây company:
-- - depth = 0: (node, node) chính nó
-- - depth = 1: quan hệ cha-con trực tiếp
-- - depth > 1: ancestor các cấp
CREATE TABLE IF NOT EXISTS company_edge (
  enterprise_id UUID NOT NULL,      -- enterprise của cạnh
  ancestor_id   UUID NOT NULL,      -- ID tổ tiên
  descendant_id UUID NOT NULL,      -- ID hậu duệ
  depth         INT  NOT NULL,      -- Độ sâu (0 = chính nó)

  PRIMARY KEY (enterprise_id, ancestor_id, descendant_id),

  -- ⭐ Siết chặt: ancestor & descendant PHẢI thuộc cùng enterprise_id
  CONSTRAINT fk_edge_ancestor
    FOREIGN KEY (enterprise_id, ancestor_id)
    REFERENCES company (enterprise_id, company_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,

  CONSTRAINT fk_edge_descendant
    FOREIGN KEY (enterprise_id, descendant_id)
    REFERENCES company (enterprise_id, company_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

-- ========== INDEX ==========
CREATE INDEX IF NOT EXISTS idx_company_edge_ancestor
  ON company_edge (enterprise_id, ancestor_id);
CREATE INDEX IF NOT EXISTS idx_company_edge_descendant
  ON company_edge (enterprise_id, descendant_id);

-- ========== FUNCTION cập nhật closure khi thêm node ==========
-- - Validate parent/child cùng enterprise
-- - Idempotent: ON CONFLICT DO NOTHING
CREATE OR REPLACE FUNCTION add_company_edge(_eid UUID, _parent UUID, _child UUID)
RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_parent_eid UUID;
  v_child_eid  UUID;
BEGIN
  -- 1) Validate parent thuộc _eid
  SELECT enterprise_id INTO v_parent_eid
  FROM company
  WHERE company_id = _parent;

  IF v_parent_eid IS NULL THEN
    RAISE EXCEPTION 'Parent company % không tồn tại', _parent;
  END IF;

  IF v_parent_eid <> _eid THEN
    RAISE EXCEPTION 'Parent company % không thuộc enterprise %', _parent, _eid;
  END IF;

  -- 2) Validate child thuộc _eid
  SELECT enterprise_id INTO v_child_eid
  FROM company
  WHERE company_id = _child;

  IF v_child_eid IS NULL THEN
    RAISE EXCEPTION 'Child company % không tồn tại', _child;
  END IF;

  IF v_child_eid <> _eid THEN
    RAISE EXCEPTION 'Child company % không thuộc enterprise %', _child, _eid;
  END IF;

  -- 3) Self-edge cho child (depth=0)
  INSERT INTO company_edge (enterprise_id, ancestor_id, descendant_id, depth)
  VALUES (_eid, _child, _child, 0)
  ON CONFLICT DO NOTHING;

  -- 4) Thêm các cạnh từ MỌI ancestor của parent → child, depth kế thừa + 1
  INSERT INTO company_edge (enterprise_id, ancestor_id, descendant_id, depth)
  SELECT ce.enterprise_id, ce.ancestor_id, _child, ce.depth + 1
  FROM company_edge ce
  WHERE ce.enterprise_id = _eid
    AND ce.descendant_id = _parent
  ON CONFLICT DO NOTHING;
END;
$$;
