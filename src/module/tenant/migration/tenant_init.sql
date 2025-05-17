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

-- Tạo chỉ mục để tối ưu truy vấn module theo tenant
CREATE INDEX IF NOT EXISTS idx_tenant_module_tenant_id ON tenant_module (tenant_id);

-- Cho phép module_name nullable trong view tổng hợp để phù hợp LEFT JOIN
-- (Không cần sửa bảng chính vì module_name luôn có, xử lý nullable ở truy vấn)
