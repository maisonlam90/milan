-- ---------- PERMISSIONS CẤP MODULE (để ẩn/hiện menu) ----------
-- Bạn có module nào thì thêm ở đây
INSERT INTO permissions (resource, action, label) VALUES
 ('module.user',    'access', 'Truy cập module Người dùng'),
 ('module.payment', 'access', 'Truy cập module Thanh toán'),
 ('module.loan',    'access', 'Truy cập module Cho vay'),
 ('module.acl',     'access', 'Truy cập module Phân quyền')
ON CONFLICT DO NOTHING;
