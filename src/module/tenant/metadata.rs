use serde_json::json;

/// Schema JSON cho React để hiển thị form tạo tenant (mới)
pub fn tenant_form_schema() -> serde_json::Value {
    json!({
        "title": "Tạo tổ chức",
        "type": "object",
        "properties": {
            "enterprise_id": {
                "type": "string",
                "format": "uuid",
                "title": "Enterprise ID"
            },
            "company_id": {
                "type": "string",
                "format": "uuid",
                "title": "Company ID (tuỳ chọn)"
            },
            "name": {
                "type": "string",
                "title": "Tên tổ chức"
            },
            "slug": {
                "type": "string",
                "title": "Slug"
            },
            "shard_id": {
                "type": "string",
                "title": "Shard / Cluster"
            }
        },
        "required": ["enterprise_id", "name", "slug", "shard_id"]
    })
}
