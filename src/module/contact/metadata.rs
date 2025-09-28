use serde_json::json;
pub const DISPLAY_NAME: &str = "Contact";
pub const DESCRIPTION: &str = "Quản lí liên hệ";

pub fn contact_form_schema() -> serde_json::Value {
    json!({
      "form": {
        "fields": [
          { "name": "is_company", "label": "Là công ty", "type": "checkbox", "width": 4 },
          { "name": "parent_id", "label": "Thuộc công ty", "type": "select", "width": 8, "fetch": "/contact/list?is_company=true" },
          { "name": "name", "label": "Tên", "type": "text", "width": 8, "required": true },
          { "name": "display_name", "label": "Tên hiển thị", "type": "text", "width": 4 },
          { "name": "email", "label": "Email", "type": "email", "width": 6 },
          { "name": "phone", "label": "Điện thoại", "type": "text", "width": 6 },
          { "name": "mobile", "label": "Di động", "type": "text", "width": 6 },
          { "name": "website", "label": "Website", "type": "text", "width": 6 },
          { "name": "street", "label": "Địa chỉ", "type": "text", "width": 12 },
          { "name": "street2", "label": "Địa chỉ 2", "type": "text", "width": 12 },
          { "name": "city", "label": "Thành phố", "type": "text", "width": 4 },
          { "name": "state", "label": "Tỉnh/Bang", "type": "text", "width": 4 },
          { "name": "zip", "label": "Mã bưu chính", "type": "text", "width": 4 },
          { "name": "country_code", "label": "Mã quốc gia (Ví dụ VN)", "type": "text", "width": 4 },
          { "name": "tags", "label": "Nhãn", "type": "tags", "width": 8 },
          { "name": "notes", "label": "Ghi chú", "type": "textarea", "width": 12 }
        ]
      },
      "list": {
        "columns": [
          { "name": "name", "label": "Tên" },
          { "name": "display_name", "label": "Tên hiển thị" },
          { "name": "email", "label": "Email" },
          { "name": "phone", "label": "Điện thoại" },
          { "name": "is_company", "label": "Công ty" },
          { "name": "state", "label": "Địa chỉ" },
        ],
        "search": { "placeholder": "Tìm theo tên/email/điện thoại" }
      }
    })
}
