use serde::{Serialize, Deserialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};
use sqlx::FromRow;

/// Provider hóa đơn điện tử
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum InvoiceProvider {
    Viettel,
    Mobifone,
    // Có thể thêm các provider khác sau
}

impl InvoiceProvider {
    pub fn as_str(&self) -> &'static str {
        match self {
            InvoiceProvider::Viettel => "viettel",
            InvoiceProvider::Mobifone => "mobifone",
        }
    }

    pub fn from_str(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "viettel" => Some(InvoiceProvider::Viettel),
            "mobifone" => Some(InvoiceProvider::Mobifone),
            _ => None,
        }
    }

    pub fn display_name(&self) -> &'static str {
        match self {
            InvoiceProvider::Viettel => "Viettel Invoice",
            InvoiceProvider::Mobifone => "Mobifone Invoice",
        }
    }
}

/// Invoice link model
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct InvoiceLink {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub invoice_id: Uuid,
    pub provider: String, // 'viettel', 'mobifone', etc.
    pub provider_invoice_id: Option<String>, // ID hóa đơn từ provider
    pub provider_invoice_number: Option<String>, // Số hóa đơn từ provider
    pub status: String, // 'pending', 'linked', 'failed'
    pub error_message: Option<String>,
    pub request_data: Option<serde_json::Value>, // Dữ liệu gửi đi
    pub response_data: Option<serde_json::Value>, // Dữ liệu nhận về
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub created_by: Uuid,
}

/// Provider credentials model
#[derive(Debug, Clone, Serialize, Deserialize, FromRow)]
pub struct ProviderCredentials {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub provider: String, // 'viettel', 'mobifone', etc.
    pub credentials: serde_json::Value, // Encrypted credentials JSON
    pub access_token: Option<String>, // Access token từ provider
    pub token_expires_at: Option<DateTime<Utc>>, // Token expiry
    pub is_active: bool,
    pub is_default: bool, // Đánh dấu credentials mặc định
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InvoiceLinkStatus {
    Pending,
    Linked,
    Failed,
}

impl InvoiceLinkStatus {
    pub fn as_str(&self) -> &'static str {
        match self {
            InvoiceLinkStatus::Pending => "pending",
            InvoiceLinkStatus::Linked => "linked",
            InvoiceLinkStatus::Failed => "failed",
        }
    }

    pub fn from_str(s: &str) -> Self {
        match s {
            "pending" => InvoiceLinkStatus::Pending,
            "linked" => InvoiceLinkStatus::Linked,
            "failed" => InvoiceLinkStatus::Failed,
            _ => InvoiceLinkStatus::Pending,
        }
    }
}

