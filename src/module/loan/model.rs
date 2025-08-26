use serde::{Serialize, Deserialize};
use sqlx::FromRow;
use uuid::Uuid;
use chrono::{DateTime, Utc};
use sqlx::types::BigDecimal;

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct LoanContract {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub contact_id: Uuid,
    pub name: String,

    /// %/năm (ví dụ 18.0 = 18%/năm)
    pub interest_rate: f64,

    pub term_months: i32,
    pub date_start: DateTime<Utc>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub date_end: Option<DateTime<Utc>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub collateral_description: Option<String>,

    // các cột dưới đây là NOT NULL ở DB
    pub collateral_value: i64,
    pub storage_fee_rate: f64,
    pub storage_fee: i64,

    pub current_principal: i64,
    pub current_interest: i64,
    pub accumulated_interest: i64,
    pub total_paid_interest: i64,
    pub total_settlement_amount: i64,
    pub total_paid_principal: i64, // projection

    pub state: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub created_by: Uuid,
    pub assignee_id: Option<Uuid>,
    pub shared_with: Option<Vec<Uuid>>,

    #[sqlx(skip)]
    pub payoff_due: i64, // projection: số tiền còn phải trả
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct LoanTransaction {
    pub id: Uuid,
    pub contract_id: Uuid,
    pub tenant_id: Uuid,
    pub contact_id: Uuid,

    /// disbursement | additional | interest | principal | liquidation | settlement
    pub transaction_type: String,

    /// Số tiền dương (UI nhập dương)
    pub amount: i64,

    #[sqlx(rename = "date")]
    pub date: DateTime<Utc>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,

    // NOT NULL DEFAULT 0 → không dùng Option
    pub days_from_prev: i32,
    pub interest_for_period: i64,
    pub accumulated_interest: i64,
    pub principal_balance: i64,

    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,

    #[sqlx(skip)]
    pub principal_applied: i64, // projection
    #[sqlx(skip)]
    pub interest_applied: i64,  // projection
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct CollateralAsset {
    pub tenant_id: Uuid,
    pub asset_id: Uuid,
    pub asset_type: String,
    pub description: Option<String>,
    pub value_estimate: Option<BigDecimal>,
    pub owner_contact_id: Option<Uuid>,
    pub status: String,              // 👈 mới: available | pledged | released | archived
    pub created_by: Uuid,
    pub created_at: DateTime<Utc>,   // NOT NULL theo DDL
}
