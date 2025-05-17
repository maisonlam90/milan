-- Bảng tenant chứa thông tin tổ chức và shard tương ứng
CREATE TABLE IF NOT EXISTS tenant (
    tenant_id UUID PRIMARY KEY,
    name TEXT NOT NULL,
    shard_id TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Bảng tenant_module ánh xạ tenant với các module mà họ sử dụng
CREATE TABLE IF NOT EXISTS tenant_module (
    tenant_id UUID NOT NULL,
    module_name TEXT NOT NULL,
    config_json JSONB DEFAULT '{}',
    enabled_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (tenant_id, module_name)
);

-- Bảng available_module lưu danh sách các module hệ thống có thể bật cho tenant
-- Bao gồm tên kỹ thuật, tên hiển thị, mô tả, metadata dạng JSON (UI schema, icon,...)
CREATE TABLE IF NOT EXISTS available_module (
    module_name TEXT PRIMARY KEY,               -- Tên kỹ thuật: 'user', 'payment',...
    display_name TEXT NOT NULL,                 -- Tên hiển thị: 'Quản lý người dùng'
    description TEXT,                           -- Mô tả ngắn về chức năng module
    metadata JSONB DEFAULT '{}'                 -- Metadata mở rộng: icon, màu, schema UI,...
);

-- Bảng phân quyền vai trò cho từng module theo user và tenant
CREATE TABLE IF NOT EXISTS user_role (
    tenant_id UUID NOT NULL,
    user_id UUID NOT NULL,
    module_name TEXT NOT NULL,
    role_name TEXT NOT NULL,
    PRIMARY KEY (tenant_id, user_id, module_name)
);

-- Tạo chỉ mục để tối ưu truy vấn module theo tenant
CREATE INDEX IF NOT EXISTS idx_tenant_module_tenant_id ON tenant_module (tenant_id);

-- Cho phép module_name nullable trong view tổng hợp để phù hợp LEFT JOIN
-- (Không cần sửa bảng chính vì module_name luôn có, xử lý nullable ở truy vấn)
