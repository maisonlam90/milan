-- 1) PERMISSIONS (global catalog)
--    - Thêm cả quyền chi tiết (resource.*)
--    - Thêm quyền CẤP MODULE: module.<module_key>.access
-- ============================================================
CREATE TABLE IF NOT EXISTS permissions (
  id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource TEXT NOT NULL,   -- vd: user, loan, report, module.user
  action   TEXT NOT NULL,   -- vd: read, create..., hoặc 'access' cho module
  label    TEXT NOT NULL,   -- tên hiển thị
  UNIQUE(resource, action)
);

-- Seed quyền chi tiết cho resource "user"
INSERT INTO permissions (resource, action, label) VALUES
 ('user','read','Xem danh sách người dùng'),
 ('user','create','Tạo người dùng mới'),
 ('user','update','Cập nhật người dùng'),
 ('user','delete','Xoá người dùng'),
 ('user','assign_role','Gán vai trò cho người dùng')
ON CONFLICT DO NOTHING;
