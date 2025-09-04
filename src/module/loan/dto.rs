use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};
use sqlx::types::BigDecimal;

// ================== LOAN ==================

#[derive(Debug, Deserialize)]
pub struct CreateContractInput {
    pub contact_id: Uuid,
    pub principal: i64,
    pub interest_rate: f64,
    pub term_months: i32,
    pub date_start: DateTime<Utc>,
    pub date_end: Option<DateTime<Utc>>,
    pub collateral_description: Option<String>,
    pub collateral_value: Option<i64>,
    pub storage_fee_rate: Option<f64>,
    pub storage_fee: Option<i64>,
    pub current_principal: Option<i64>,
    pub current_interest: Option<i64>,
    pub accumulated_interest: Option<i64>,
    pub total_paid_interest: Option<i64>,
    pub total_settlement_amount: Option<i64>,
    pub state: String,
    pub created_by: Option<Uuid>,
    pub assignee_id: Option<Uuid>,
    pub shared_with: Option<Vec<Uuid>>,
    pub collateral_asset_ids: Option<Vec<Uuid>>,

    #[serde(default)]
    pub transactions: Vec<TransactionInput>,
}

#[derive(Debug, Deserialize, Clone)]
pub struct TransactionInput {
    pub date: i64, // epoch seconds client gửi
    pub transaction_type: String,
    pub amount: i64,
    pub note: Option<String>,

    #[serde(skip_deserializing, default)]
    pub days_from_prev: Option<i32>,
    #[serde(skip_deserializing, default)]
    pub interest_for_period: Option<i64>,
    #[serde(skip_deserializing, default)]
    pub accumulated_interest: Option<i64>,
    #[serde(skip_deserializing, default)]
    pub principal_balance: Option<i64>,
}

// === DTO trả ra Frontend (view) ===
#[derive(Debug, Serialize)]
pub struct ContractView {
    pub contact_id: Uuid,
    pub contract_number: String,
    pub principal: i64,
    pub interest_rate: f64,
    pub term_months: i32,
    pub date_start: DateTime<Utc>,
    pub date_end: Option<DateTime<Utc>>,
    pub collateral_description: Option<String>,
    pub collateral_value: Option<i64>,
    pub storage_fee_rate: Option<f64>,
    pub storage_fee: Option<i64>,
    pub current_principal: Option<i64>,
    pub current_interest: Option<i64>,
    pub accumulated_interest: Option<i64>,
    pub total_paid_interest: Option<i64>,
    pub total_settlement_amount: Option<i64>,
    pub state: String,
    pub transactions: Vec<TransactionView>,
}

#[derive(Debug, Serialize)]
pub struct TransactionView {
    pub date: i64, // vẫn trả epoch/hoặc ISO tuỳ FE
    pub transaction_type: String,
    pub amount: i64,
    pub note: Option<String>,
    pub days_from_prev: i32,
    pub interest_for_period: Option<i64>,
    pub accumulated_interest: Option<i64>,
    pub principal_balance: Option<i64>,
}

// ================== COLLATERAL ==================

fn default_collateral_status() -> String {
    "available".to_string()
}

/// Dùng cho POST /loan/collateral
#[derive(Deserialize)]
pub struct CreateCollateralDto {
    pub asset_type: String,
    pub description: Option<String>,
    pub value_estimate: Option<BigDecimal>,
    pub owner_contact_id: Option<Uuid>,
    pub status: Option<String>,              // 👈 cho phép FE không gửi
    pub contract_id: Option<Uuid>,
}

#[derive(Serialize, sqlx::FromRow)]
pub struct CollateralAsset {
    pub tenant_id: Uuid,
    pub asset_id: Uuid,
    pub asset_type: String,
    pub description: Option<String>,
    pub value_estimate: Option<BigDecimal>,
    pub owner_contact_id: Option<Uuid>,
    pub status: String,                      // 👈 có status
    pub created_by: Uuid,
    pub created_at: DateTime<Utc>,
}
