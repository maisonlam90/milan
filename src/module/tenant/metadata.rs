use serde_json::json;

// Schema JSON cho React để hiển thị form tạo tenant
pub fn tenant_form_schema() -> serde_json::Value {
    json!({
        "title": "Tenant Registration",
        "type": "object",
        "properties": {
            "name": { "type": "string", "title": "Tên tổ chức" },
            "shard_id": { "type": "string", "title": "Shard / Cluster" }
        },
        "required": ["name", "shard_id"]
    })
}