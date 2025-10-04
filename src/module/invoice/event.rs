use serde::{Serialize, Deserialize};
use uuid::Uuid;
use chrono::{DateTime, Utc, NaiveDate};
use sqlx::types::BigDecimal;

// ============================================================
// DOMAIN EVENTS
// ============================================================

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct InvoiceCreatedEvent {
    pub tenant_id: Uuid,
    pub invoice_id: Uuid,
    pub move_type: String,
    pub partner_id: Option<Uuid>,
    pub amount_total: BigDecimal,
    pub created_by: Uuid,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct InvoiceUpdatedEvent {
    pub tenant_id: Uuid,
    pub invoice_id: Uuid,
    pub changes: serde_json::Value,
    pub updated_by: Uuid,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct InvoicePostedEvent {
    pub tenant_id: Uuid,
    pub invoice_id: Uuid,
    pub invoice_number: String,
    pub amount_total: BigDecimal,
    pub posted_by: Uuid,
    pub posted_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct InvoiceResetToDraftEvent {
    pub tenant_id: Uuid,
    pub invoice_id: Uuid,
    pub reset_by: Uuid,
    pub reset_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct InvoiceCancelledEvent {
    pub tenant_id: Uuid,
    pub invoice_id: Uuid,
    pub cancelled_by: Uuid,
    pub cancelled_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct InvoiceReversedEvent {
    pub tenant_id: Uuid,
    pub invoice_id: Uuid,
    pub reversal_id: Uuid,
    pub reversed_by: Uuid,
    pub reversed_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PaymentCreatedEvent {
    pub tenant_id: Uuid,
    pub payment_id: Uuid,
    pub invoice_id: Uuid,
    pub amount: BigDecimal,
    pub payment_type: String,
    pub created_by: Uuid,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PaymentUpdatedEvent {
    pub tenant_id: Uuid,
    pub payment_id: Uuid,
    pub changes: serde_json::Value,
    pub updated_by: Uuid,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct PaymentDeletedEvent {
    pub tenant_id: Uuid,
    pub payment_id: Uuid,
    pub invoice_id: Uuid,
    pub deleted_by: Uuid,
    pub deleted_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct InvoiceOverdueEvent {
    pub tenant_id: Uuid,
    pub invoice_id: Uuid,
    pub partner_id: Option<Uuid>,
    pub amount_overdue: BigDecimal,
    pub days_overdue: i32,
    pub due_date: NaiveDate,
    pub detected_at: DateTime<Utc>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct InvoicePaidEvent {
    pub tenant_id: Uuid,
    pub invoice_id: Uuid,
    pub amount_paid: BigDecimal,
    pub payment_state: String,
    pub paid_at: DateTime<Utc>,
}
