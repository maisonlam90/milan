use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

/// Provider information cho dropdown
#[derive(Debug, Serialize, Deserialize)]
pub struct ProviderInfo {
    pub code: String, // 'viettel', 'mobifone'
    pub name: String, // Display name
    pub description: Option<String>,
}

/// Form field definition cho dynamic form
#[derive(Debug, Serialize, Deserialize)]
pub struct FormField {
    pub name: String,
    pub label: String,
    pub field_type: String, // 'text', 'password', 'email', etc.
    pub required: bool,
    pub placeholder: Option<String>,
    pub description: Option<String>,
}

/// Response trả về form fields cho provider
#[derive(Debug, Serialize, Deserialize)]
pub struct ProviderFormFieldsResponse {
    pub provider: String,
    pub fields: Vec<FormField>,
}

/// Input để link với provider (dynamic theo provider)
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct LinkProviderInput {
    pub provider: String, // 'viettel', 'mobifone'
    pub credentials: serde_json::Value, // Dynamic fields theo provider
    pub is_default: Option<bool>, // Đánh dấu credentials mặc định
}

/// Response khi link provider thành công
#[derive(Debug, Serialize, Deserialize)]
pub struct LinkProviderResponse {
    pub success: bool,
    pub message: String,
    pub credential_id: Option<Uuid>,
    pub provider: String,
}

/// Input để gửi hóa đơn đến provider
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct SendInvoiceToProviderInput {
    pub invoice_id: Uuid,
    pub provider: String, // 'viettel', 'mobifone'
    pub credential_id: Option<Uuid>, // ID của credentials đã lưu (nếu có)
}

/// Response khi gửi hóa đơn
#[derive(Debug, Serialize, Deserialize)]
pub struct SendInvoiceResponse {
    pub link_id: Uuid,
    pub status: String,
    pub provider_invoice_id: Option<String>,
    pub provider_invoice_number: Option<String>,
    pub message: Option<String>,
}

/// DTO cho invoice link
#[derive(Debug, Serialize, Deserialize)]
pub struct InvoiceLinkDto {
    pub id: Uuid,
    pub invoice_id: Uuid,
    pub provider: String,
    pub provider_invoice_id: Option<String>,
    pub provider_invoice_number: Option<String>,
    pub status: String,
    pub error_message: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Filter để list invoice links
#[derive(Debug, Deserialize)]
pub struct ListInvoiceLinkFilter {
    pub invoice_id: Option<Uuid>,
    pub provider: Option<String>,
    pub status: Option<String>,
    pub limit: Option<u32>,
    pub offset: Option<u32>,
}

/// DTO cho provider credentials
#[derive(Debug, Serialize, Deserialize)]
pub struct ProviderCredentialsDto {
    pub id: Uuid,
    pub provider: String,
    pub is_active: bool,
    pub is_default: bool,
    pub template_code: Option<String>,
    pub invoice_series: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

/// Input cho Viettel login (từ bash script)
#[derive(Debug, Deserialize, Serialize)]
pub struct ViettelLoginInput {
    pub username: String,
    pub password: String,
}

/// Input cho Mobifone login (sẽ implement sau)
#[derive(Debug, Deserialize, Serialize)]
pub struct MobifoneLoginInput {
    // Sẽ thêm sau khi có thông tin API
}

