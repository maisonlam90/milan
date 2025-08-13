use serde::{Serialize, Deserialize};
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct LoanContract {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub contact_id: Uuid,
    pub name: String,

    /// Gốc ban đầu khi tạo hợp đồng
    pub principal: i64,

    /// %/năm (ví dụ 18.0 = 18%/năm)
    pub interest_rate: f64,

    pub term_months: i32,
    pub date_start: DateTime<Utc>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub date_end: Option<DateTime<Utc>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub collateral_description: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub collateral_value: Option<i64>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub storage_fee_rate: Option<f64>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub storage_fee: Option<i64>,

    /// Dư nợ gốc hiện tại (sau khi calculator.rs tính)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub current_principal: Option<i64>,

    /// Lãi đang treo (đã phát sinh nhưng chưa trả hết)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub current_interest: Option<i64>,

    /// Tổng lãi đã phát sinh tích lũy từ đầu kỳ (không trừ phần đã trả)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub accumulated_interest: Option<i64>,

    /// Tổng lãi KH đã trả
    #[serde(skip_serializing_if = "Option::is_none")]
    pub total_paid_interest: Option<i64>,

    /// Tổng tiền tất toán (nếu có logic tính)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub total_settlement_amount: Option<i64>,

    pub state: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub created_at: Option<DateTime<Utc>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub updated_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct LoanTransaction {
    pub id: Uuid,
    pub contract_id: Uuid,
    pub tenant_id: Uuid,
    pub contact_id: Uuid,

    /// disbursement | additional | interest | principal | liquidation | settlement
    pub transaction_type: String,

    /// Số tiền dương (UI nhập dương). Calculator sẽ chuẩn hóa nếu có âm.
    pub amount: i64,

    pub date: DateTime<Utc>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,

    // ====== Các trường được calculator.rs điền sau khi tính ======

    /// Số ngày giữa giao dịch này và giao dịch trước đó (hoặc ngày bắt đầu hợp đồng)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub days_from_prev: Option<i32>,

    /// Lãi phát sinh trong khoảng (days_from_prev) * principal * daily_rate
    #[serde(skip_serializing_if = "Option::is_none")]
    pub interest_for_period: Option<i64>,

    /// Tổng lãi phát sinh tích lũy đến thời điểm giao dịch này
    #[serde(skip_serializing_if = "Option::is_none")]
    pub accumulated_interest: Option<i64>,

    /// Dư nợ gốc sau khi áp dụng giao dịch này
    #[serde(skip_serializing_if = "Option::is_none")]
    pub principal_balance: Option<i64>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub created_at: Option<DateTime<Utc>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub updated_at: Option<DateTime<Utc>>,
}
