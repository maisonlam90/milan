use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

/// Input để gửi hóa đơn đến Meinvoice
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct SendInvoiceToMeinvoiceInput {
    pub invoice_id: Uuid,
    /// API key của Meinvoice (có thể lưu trong config hoặc database)
    pub api_key: Option<String>,
    /// URL endpoint của Meinvoice API (có thể lưu trong config)
    pub api_url: Option<String>,
}

/// Response khi gửi hóa đơn thành công
#[derive(Debug, Serialize, Deserialize)]
pub struct SendInvoiceResponse {
    pub link_id: Uuid,
    pub status: String,
    pub meinvoice_invoice_id: Option<String>,
    pub meinvoice_invoice_number: Option<String>,
    pub message: Option<String>,
}

/// DTO cho invoice link
#[derive(Debug, Serialize, Deserialize)]
pub struct InvoiceLinkDto {
    pub id: Uuid,
    pub invoice_id: Uuid,
    pub meinvoice_invoice_id: Option<String>,
    pub meinvoice_invoice_number: Option<String>,
    pub status: String,
    pub error_message: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Filter để list invoice links
#[derive(Debug, Deserialize)]
pub struct ListInvoiceLinkFilter {
    pub invoice_id: Option<Uuid>,
    pub status: Option<String>,
    pub limit: Option<u32>,
    pub offset: Option<u32>,
}

/// Input để đăng nhập Meinvoice
#[derive(Debug, Deserialize, Serialize)]
pub struct MeinvoiceLoginInput {
    pub username: String,
    pub password: String,
    pub taxcode: String, // Mã số thuế
    pub appid: String,   // AppID được MISA cung cấp
    pub api_url: Option<String>,
}

/// Response khi đăng nhập Meinvoice thành công
#[derive(Debug, Serialize, Deserialize)]
pub struct MeinvoiceLoginResponse {
    pub success: bool,
    pub message: String,
    pub token: Option<String>, // Token từ Meinvoice nếu có
}

