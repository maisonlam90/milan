use serde::{Serialize, Deserialize};
use uuid::Uuid;
use chrono::NaiveDate;
use sqlx::types::BigDecimal;

// ============================================================
// QUERIES (CQRS)
// ============================================================

#[derive(Debug, Serialize, Deserialize)]
pub struct GetInvoiceQuery {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub invoice_id: Uuid,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ListInvoicesQuery {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub page: Option<i32>,
    pub limit: Option<i32>,
    pub move_type: Option<String>,
    pub state: Option<String>,
    pub payment_state: Option<String>,
    pub partner_id: Option<Uuid>,
    pub date_from: Option<NaiveDate>,
    pub date_to: Option<NaiveDate>,
    pub search: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GetInvoiceStatsQuery {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub date_from: Option<NaiveDate>,
    pub date_to: Option<NaiveDate>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GetInvoicePaymentsQuery {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub invoice_id: Uuid,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GetPaymentQuery {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub payment_id: Uuid,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GetOverdueInvoicesQuery {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub as_of_date: Option<NaiveDate>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GetMonthlyStatsQuery {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub year: Option<i32>,
    pub month: Option<u32>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GetAgingReportQuery {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub as_of_date: Option<NaiveDate>,
    pub partner_id: Option<Uuid>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GetTaxReportQuery {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub date_from: Option<NaiveDate>,
    pub date_to: Option<NaiveDate>,
    pub tax_id: Option<Uuid>,
}
