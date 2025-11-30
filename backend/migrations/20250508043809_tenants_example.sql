-- ============================================================
-- 6) (TUỲ CHỌN) SEED COMPANY NHIỀU CẤP MẪU + GẮN TENANT VÀO COMPANY LÁ
--    - Bỏ nếu bạn chưa cần cây công ty
-- ============================================================

-- Company cấp 1
INSERT INTO tenant_company (company_id, enterprise_id, name, slug)
VALUES
 ('11111111-1111-1111-1111-111111111111','00000000-0000-0000-0000-000000000001','Công ty Cấp 1 - A','c1-a')
ON CONFLICT DO NOTHING;

-- Company cấp 2
INSERT INTO tenant_company (company_id, enterprise_id, name, slug)
VALUES
 ('22222222-2222-2222-2222-222222222222','00000000-0000-0000-0000-000000000001','Công ty Cấp 2 - A1','c2-a1'),
 ('33333333-3333-3333-3333-333333333333','00000000-0000-0000-0000-000000000001','Công ty Cấp 2 - A2','c2-a2')
ON CONFLICT DO NOTHING;

-- Closure edges: tự thân (depth=0) + cha-con (depth=1)
INSERT INTO tenant_company_edge (enterprise_id, ancestor_id, descendant_id, depth) VALUES
 ('00000000-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111','11111111-1111-1111-1111-111111111111',0), -- A->A
 ('00000000-0000-0000-0000-000000000001','22222222-2222-2222-2222-222222222222','22222222-2222-2222-2222-222222222222',0), -- A1->A1
 ('00000000-0000-0000-0000-000000000001','33333333-3333-3333-3333-333333333333','33333333-3333-3333-3333-333333333333',0), -- A2->A2
 ('00000000-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111','22222222-2222-2222-2222-222222222222',1), -- A -> A1
 ('00000000-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111','33333333-3333-3333-3333-333333333333',1)  -- A -> A2
ON CONFLICT DO NOTHING;

-- Gắn tenant system vào company lá (A1)
UPDATE tenant
   SET company_id = '22222222-2222-2222-2222-222222222222'
 WHERE tenant_id  = '00000000-0000-0000-0000-000000000000';

-- ============================================================
-- 7) GỢI Ý QUERY (comment)
-- (giữ nguyên như bản trước; bỏ qua khi migrate)
-- ============================================================
-- Enterprise tổng hợp:
-- SELECT SUM(s.total_amount) FROM sales s
-- JOIN tenant t ON t.tenant_id = s.tenant_id
-- WHERE t.enterprise_id = $enterprise_id;

-- Company tổng hợp subtree:
-- WITH subtree AS (
--   SELECT descendant_id FROM company_edge
--   WHERE enterprise_id = $enterprise_id AND ancestor_id = $company_id
-- )
-- SELECT SUM(s.total_amount)
-- FROM tenant t JOIN subtree st ON st.descendant_id = t.company_id
-- JOIN sales s ON s.tenant_id = t.tenant_id;
