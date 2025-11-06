use serde::{Serialize, Deserialize};
use uuid::Uuid;
use chrono::NaiveDate;
use sqlx::types::BigDecimal;

// ============================================================
// REQUEST DTOs
// ============================================================

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CreateInvoiceRequest {
    pub move_type: String,
    pub partner_id: Option<Uuid>,
    pub invoice_date: NaiveDate,
    pub invoice_date_due: Option<NaiveDate>,
    pub r#ref: Option<String>,
    pub narration: Option<String>,
    pub journal_id: Uuid,
    pub payment_term_id: Option<Uuid>,
    pub fiscal_position_id: Option<Uuid>,
    pub lines: Vec<CreateInvoiceLineRequest>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct CreateInvoiceLineRequest {
    pub name: String,
    pub product_id: Option<Uuid>,
    pub account_id: Uuid,
    pub quantity: Option<BigDecimal>,
    pub price_unit: Option<BigDecimal>,
    pub discount: Option<BigDecimal>,
    pub tax_ids: Option<Vec<Uuid>>,
    pub analytic_distribution: Option<serde_json::Value>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UpdateInvoiceRequest {
    pub partner_id: Option<Uuid>,
    pub invoice_date: Option<NaiveDate>,
    pub invoice_date_due: Option<NaiveDate>,
    pub r#ref: Option<String>,
    pub narration: Option<String>,
    pub payment_term_id: Option<Uuid>,
    pub fiscal_position_id: Option<Uuid>,
    pub lines: Option<Vec<UpdateInvoiceLineRequest>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UpdateInvoiceLineRequest {
    pub id: Option<Uuid>,
    pub name: Option<String>,
    pub product_id: Option<Uuid>,
    pub account_id: Option<Uuid>,
    pub quantity: Option<BigDecimal>,
    pub price_unit: Option<BigDecimal>,
    pub discount: Option<BigDecimal>,
    pub tax_ids: Option<Vec<Uuid>>,
    pub analytic_distribution: Option<serde_json::Value>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PostInvoiceRequest {
    pub invoice_date: Option<NaiveDate>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatePaymentRequest {
    pub payment_type: String,
    pub partner_id: Uuid,
    pub amount: BigDecimal,
    pub currency_id: Uuid,
    pub payment_date: NaiveDate,
    pub journal_id: Uuid,
    pub payment_method_id: Uuid,
    pub communication: Option<String>,
    pub move_ids: Vec<Uuid>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct InvoiceListQuery {
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

// ============================================================
// RESPONSE DTOs
// ============================================================

#[derive(Debug, Serialize, Deserialize)]
pub struct InvoiceResponse {
    pub id: Uuid,
    pub name: String,
    pub move_type: String,
    pub partner_id: Option<Uuid>,
    pub partner_name: Option<String>,
    pub state: String,
    pub payment_state: String,
    pub invoice_date: NaiveDate,
    pub invoice_date_due: Option<NaiveDate>,
    pub r#ref: Option<String>,
    pub amount_untaxed: BigDecimal,
    pub amount_tax: BigDecimal,
    pub amount_total: BigDecimal,
    pub amount_residual: BigDecimal,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,
    pub lines: Option<Vec<InvoiceLineResponse>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct InvoiceLineResponse {
    pub id: Uuid,
    pub name: String,
    pub product_id: Option<Uuid>,
    pub account_id: Uuid,
    pub quantity: Option<BigDecimal>,
    pub price_unit: Option<BigDecimal>,
    pub discount: Option<BigDecimal>,
    pub debit: BigDecimal,
    pub credit: BigDecimal,
    pub balance: BigDecimal,
    pub amount_residual: BigDecimal,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PaymentResponse {
    pub id: Uuid,
    pub name: String,
    pub payment_type: String,
    pub partner_id: Uuid,
    pub partner_name: String,
    pub amount: BigDecimal,
    pub currency_id: Uuid,
    pub payment_date: NaiveDate,
    pub state: String,
    pub communication: Option<String>,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct InvoiceStatsResponse {
    pub total_invoices: i64,
    pub total_amount: BigDecimal,
    pub draft_count: i64,
    pub posted_count: i64,
    pub paid_count: i64,
    pub overdue_count: i64,
    pub by_type: std::collections::HashMap<String, InvoiceTypeStats>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct InvoiceTypeStats {
    pub count: i64,
    pub total_amount: BigDecimal,
    pub paid_amount: BigDecimal,
    pub residual_amount: BigDecimal,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PaginatedResponse<T> {
    pub data: Vec<T>,
    pub total: i64,
    pub page: i32,
    pub limit: i32,
    pub total_pages: i32,
}