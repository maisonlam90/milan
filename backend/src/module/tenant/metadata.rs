use serde_json::json;

/// Form tạo Enterprise
pub fn enterprise_form_schema() -> serde_json::Value {
    json!({
        "title": "Tạo Enterprise",
        "type": "object",
        "properties": {
            "name": { "type": "string", "title": "Tên enterprise" },
            "slug": { "type": "string", "title": "Slug (duy nhất)" }
        },
        "required": ["name"]
    })
}

/// UI schema (tuỳ chọn)
pub fn enterprise_form_ui() -> serde_json::Value {
    json!({
        "name": { "ui:placeholder": "Tập đoàn Mailan" },
        "slug": { "ui:placeholder": "mailan" }
    })
}

/// Form tạo Company (node trong cây)
pub fn company_form_schema() -> serde_json::Value {
    json!({
        "title": "Tạo Company",
        "type": "object",
        "properties": {
            "enterprise_id": { "type": "string", "format": "uuid", "title": "Enterprise ID" },
            "name": { "type": "string", "title": "Tên company" },
            "slug": { "type": "string", "title": "Slug (unique trong enterprise)" },
            "parent_company_id": { "type": "string", "format": "uuid", "title": "Parent Company ID (tuỳ chọn)" }
        },
        "required": ["enterprise_id", "name"]
    })
}

pub fn company_form_ui() -> serde_json::Value {
    json!({
        "enterprise_id": { "ui:placeholder": "UUID enterprise" },
        "name": { "ui:placeholder": "Công ty Miền Bắc" },
        "slug": { "ui:placeholder": "mien-bac" },
        "parent_company_id": { "ui:placeholder": "UUID parent (nếu có)" }
    })
}

/// Form tạo Tenant (đã nâng cấp)
pub fn tenant_form_schema() -> serde_json::Value {
    json!({
        "title": "Tạo tổ chức",
        "type": "object",
        "properties": {
            "enterprise_id": { "type": "string", "format": "uuid", "title": "Enterprise ID" },
            "company_id": { "type": "string", "format": "uuid", "title": "Company ID (tuỳ chọn)" },
            "name": { "type": "string", "title": "Tên tổ chức" },
            "slug": { "type": "string", "title": "Slug" },
            "shard_id": { "type": "string", "title": "Shard / Cluster" }
        },
        "required": ["enterprise_id", "name", "slug", "shard_id"]
    })
}
