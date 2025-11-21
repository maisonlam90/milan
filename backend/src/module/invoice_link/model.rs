use serde::{Serialize, Deserialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};
use sqlx::FromRow;

#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct InvoiceLink {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub invoice_id: Uuid,              // ID của invoice trong hệ thống
    pub meinvoice_invoice_id: Option<String>,  // ID hóa đơn từ Meinvoice
    pub meinvoice_invoice_number: Option<String>, // Số hóa đơn từ Meinvoice
    pub status: String,                // 'pending', 'sent', 'success', 'failed'
    pub error_message: Option<String>,
    pub request_data: Option<serde_json::Value>,  // Dữ liệu gửi đi
    pub response_data: Option<serde_json::Value>, // Dữ liệu nhận về
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub created_by: Uuid,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InvoiceLinkStatus {
    Pending,
    Sent,
    Success,
    Failed,
}

impl InvoiceLinkStatus {
    pub fn as_str(&self) -> &'static str {
        match self {
            InvoiceLinkStatus::Pending => "pending",
            InvoiceLinkStatus::Sent => "sent",
            InvoiceLinkStatus::Success => "success",
            InvoiceLinkStatus::Failed => "failed",
        }
    }

    pub fn from_str(s: &str) -> Self {
        match s {
            "pending" => InvoiceLinkStatus::Pending,
            "sent" => InvoiceLinkStatus::Sent,
            "success" => InvoiceLinkStatus::Success,
            "failed" => InvoiceLinkStatus::Failed,
            _ => InvoiceLinkStatus::Pending,
        }
    }
}

