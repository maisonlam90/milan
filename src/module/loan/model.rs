use serde::{Serialize, Deserialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Serialize, Deserialize)]
pub struct LoanContract {
    pub id: Uuid,
    pub tenant_id: Uuid,
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
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct LoanTransaction {
    pub id: Uuid,
    pub contract_id: Uuid,
    pub tenant_id: Uuid,
    pub customer_id: Uuid,
    pub transaction_type: String,
    pub amount: i64,
    pub date: DateTime<Utc>,
    pub note: Option<String>,
    pub days_from_prev: Option<i32>,
    pub interest_for_period: Option<i64>,
    pub accumulated_interest: Option<i64>,
    pub principal_balance: Option<i64>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}
