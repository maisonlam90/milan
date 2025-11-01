use serde::{Serialize, Deserialize};
use uuid::Uuid;
use chrono::NaiveDate;
use sqlx::types::BigDecimal;

// ============================================================
// COMMANDS (CQRS)
// ============================================================

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateInvoiceCommand {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub move_type: String,
    pub partner_id: Option<Uuid>,
    pub invoice_date: NaiveDate,
    pub invoice_date_due: Option<NaiveDate>,
    pub r#ref: Option<String>,
    pub narration: Option<String>,
    pub journal_id: Uuid,
    pub payment_term_id: Option<Uuid>,
    pub fiscal_position_id: Option<Uuid>,
    pub lines: Vec<CreateInvoiceLineCommand>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateInvoiceLineCommand {
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
pub struct UpdateInvoiceCommand {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub invoice_id: Uuid,
    pub partner_id: Option<Uuid>,
    pub invoice_date: Option<NaiveDate>,
    pub invoice_date_due: Option<NaiveDate>,
    pub r#ref: Option<String>,
    pub narration: Option<String>,
    pub payment_term_id: Option<Uuid>,
    pub fiscal_position_id: Option<Uuid>,
    pub lines: Option<Vec<UpdateInvoiceLineCommand>>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct UpdateInvoiceLineCommand {
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
pub struct PostInvoiceCommand {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub invoice_id: Uuid,
    pub invoice_date: Option<NaiveDate>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ResetToDraftCommand {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub invoice_id: Uuid,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CancelInvoiceCommand {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub invoice_id: Uuid,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ReverseInvoiceCommand {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub invoice_id: Uuid,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatePaymentCommand {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
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

#[derive(Debug, Serialize, Deserialize)]
pub struct UpdatePaymentCommand {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub payment_id: Uuid,
    pub payment_type: Option<String>,
    pub partner_id: Option<Uuid>,
    pub amount: Option<BigDecimal>,
    pub currency_id: Option<Uuid>,
    pub payment_date: Option<NaiveDate>,
    pub journal_id: Option<Uuid>,
    pub payment_method_id: Option<Uuid>,
    pub communication: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct DeletePaymentCommand {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub payment_id: Uuid,
}
