use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Deserialize)]
pub struct CreateContractInput {
    pub customer_id: Uuid,
    pub name: String,
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
    pub transactions: Vec<TransactionInput>, // input only
}

#[derive(Debug, Deserialize, Clone)]
pub struct TransactionInput {
    pub date: i64,                 // epoch seconds client gửi
    pub transaction_type: String,
    pub amount: i64,
    pub note: Option<String>,

    // ⛔ Client gửi gì cũng bị bỏ qua, luôn default None
    #[serde(skip_deserializing, default)]
    pub days_from_prev: Option<i32>,

    // (tương tự – nếu đây cũng là trường tính)
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
    pub customer_id: Uuid,
    pub name: String,
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
    pub date: i64,              // vẫn trả epoch/hoặc ISO tuỳ FE
    pub transaction_type: String,
    pub amount: i64,
    pub note: Option<String>,
    pub days_from_prev: i32,    // ✅ backend tính và trả về
    pub interest_for_period: Option<i64>,
    pub accumulated_interest: Option<i64>,
    pub principal_balance: Option<i64>,
}
