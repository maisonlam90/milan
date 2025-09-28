use serde_json::json;
pub const DISPLAY_NAME: &str = "Loan";
pub const DESCRIPTION: &str = "Quản lí cho vay";
pub fn loan_form_schema() -> serde_json::Value {
    json!({
        "form": {
            "fields": [
                { "name": "contact_id", "label": "Khách hàng", "type": "select", "width": 12 },
                { "name": "contract_number", "label": "Số hợp đồng", "type": "text", "width": 6, "disabled": true },
                { "name": "interest_rate", "label": "Lãi suất (%)", "type": "number", "width": 6},
                { "name": "date_start", "label": "Ngày hợp đồng", "type": "date", "width": 6  },
                { "name": "date_end", "label": "Ngày kết thúc", "type": "date", "width": 6  },
                { "name": "term_months", "label": "Kỳ hạn (tháng)", "type": "number", "width": 6 },
                { "name": "state", "label": "Trạng thái hợp đồng", "type": "text", "width": 6 , "disabled": true},
            ]
        },
        "list": {
            "columns": [
                { "key": "contract_number", "label": "Số HĐ" },
                { "key": "id", "label": "Id HĐ" },
                { "key": "current_principal", "label": "Gốc (VNĐ)" },
                { "key": "interest_rate", "label": "Lãi suất (%)" },
                { "key": "term_months", "label": "Kỳ hạn (tháng)" },
                { "key": "date_start", "label": "Ngày bắt đầu" },
                { "key": "date_end", "label": "Ngày kết thúc" },
                { "key": "state", "label": "Trạng thái" }
            ]
        },
        "collateral": {
            "fields": [
                {
                    "name": "asset_type", "label": "Loại tài sản", "type": "select",
                    "options": json!([
                        { "value": "vehicle", "label": "Xe cộ" },
                        { "value": "real_estate", "label": "Bất động sản" },
                        { "value": "jewelry", "label": "Trang sức" },
                        { "value": "electronics", "label": "Điện tử" },
                        { "value": "other", "label": "Khác" }
                    ])
                },
                { "name": "owner_contact_id", "label": "Chủ sở hữu (Contact)", "type": "select" },
                { "name": "value_estimate", "label": "Giá trị ước tính", "type": "number" },
                {
                    "name": "status", "label": "Trạng thái", "type": "select",
                    "options": json!([
                        { "value": "available", "label": "available" },
                        { "value": "pledged",   "label": "pledged" },
                        { "value": "released",  "label": "released" },
                        { "value": "sold",      "label": "sold" }
                    ])
                },
                { "name": "description", "label": "Mô tả", "type": "text" }
            ]
        },
        "notebook": {
            "fields": [
                { "name": "date", "label": "Ngày", "type": "date" },
                { "name": "transaction_type", "label": "Loại GD", "type": "select", "options": json!([
                    { "value": "disbursement", "label": "Giải ngân" },
                    { "value": "additional", "label": "Vay thêm" },
                    { "value": "interest", "label": "Thu lãi" },
                    { "value": "principal", "label": "Thu gốc" },
                    { "value": "liquidation", "label": "Thanh lý" },
                    { "value": "settlement", "label": "Tất toán" }
                ])},
                { "name": "amount", "label": "Số tiền", "type": "number" },
                { "name": "days_from_prev", "label": "Số ngày", "type": "compute" },
                { "name": "interest_for_period", "label": "Lãi kỳ này", "type": "compute" },
                { "name": "accumulated_interest", "label": "Lãi tích lũy", "type": "compute" },
                { "name": "principal_balance", "label": "Dư nợ gốc", "type": "compute" },
                { "name": "note", "label": "Ghi chú", "type": "text" },
            ]
        }
    })
}
