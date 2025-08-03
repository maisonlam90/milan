use serde::Deserialize;
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
}
