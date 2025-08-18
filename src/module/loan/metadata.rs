use serde_json::json;
pub const DISPLAY_NAME: &str = "Loan";
pub const DESCRIPTION: &str = "Quản lí cho vay";
pub fn loan_form_schema() -> serde_json::Value {
    json!({
        "form": {
            "fields": [
                { "name": "contact_id", "label": "Khách hàng", "type": "select", "width": 12 },
                { "name": "name", "label": "Số hợp đồng", "type": "text", "width": 6 },
                { "name": "interest_rate", "label": "Lãi suất (%)", "type": "number", "width": 6},
                { "name": "date_start", "label": "Ngày hợp đồng", "type": "date", "width": 6  },
                { "name": "date_end", "label": "Ngày kết thúc", "type": "date", "width": 6  },
                { "name": "term_months", "label": "Kỳ hạn (tháng)", "type": "number", "width": 6 },
                { "name": "collateral_description", "label": "Tài sản thế chấp", "type": "text", "width": 6 },
                { "name": "collateral_value", "label": "Giá trị TS thế chấp", "type": "number", "width": 6 },
                { "name": "state", "label": "Trạng thái hợp đồng", "type": "text", "width": 6 }
            ]
        },
        "list": {
            "columns": [
                { "key": "name", "label": "Số HĐ" },
                { "key": "principal", "label": "Gốc (VNĐ)" },
                { "key": "interest_rate", "label": "Lãi suất (%)" },
                { "key": "term_months", "label": "Kỳ hạn (tháng)" },
                { "key": "date_start", "label": "Ngày bắt đầu" },
                { "key": "date_end", "label": "Ngày kết thúc" },
                { "key": "state", "label": "Trạng thái" }
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
