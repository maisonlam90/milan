-- 🛡️ Seed permissions auto-generated from metadata.rs --

-- 📦 Module: tenant
INSERT INTO permissions (resource, action, label) VALUES
  ('tenant', 'access', 'Truy cập module tenant'),
  ('tenant', 'read',   'Xem tenant'),
  ('tenant', 'create', 'Tạo tenant'),
  ('tenant', 'update', 'Cập nhật tenant'),
  ('tenant', 'delete', 'Xoá tenant')
ON CONFLICT DO NOTHING;

-- 📦 Module: contact
INSERT INTO permissions (resource, action, label) VALUES
  ('contact', 'access', 'Truy cập module contact'),
  ('contact', 'read',   'Xem contact'),
  ('contact', 'create', 'Tạo contact'),
  ('contact', 'update', 'Cập nhật contact'),
  ('contact', 'delete', 'Xoá contact')
ON CONFLICT DO NOTHING;

-- 📦 Module: user
INSERT INTO permissions (resource, action, label) VALUES
  ('user', 'access', 'Truy cập module user'),
  ('user', 'read',   'Xem user'),
  ('user', 'create', 'Tạo user'),
  ('user', 'update', 'Cập nhật user'),
  ('user', 'delete', 'Xoá user')
ON CONFLICT DO NOTHING;

-- 📦 Module: loan
INSERT INTO permissions (resource, action, label) VALUES
  ('loan', 'access', 'Truy cập module loan'),
  ('loan', 'read',   'Xem loan'),
  ('loan', 'create', 'Tạo loan'),
  ('loan', 'update', 'Cập nhật loan'),
  ('loan', 'delete', 'Xoá loan')
ON CONFLICT DO NOTHING;

