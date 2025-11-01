use serde::{Serialize, Deserialize};
use sqlx::FromRow;
use uuid::Uuid;
use chrono::{DateTime, Utc, NaiveDate};
use sqlx::types::BigDecimal;

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AccountMove {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub name: String,
    pub move_type: String, // 'out_invoice', 'in_invoice', 'out_refund', 'in_refund', 'entry'
    pub partner_id: Option<Uuid>,
    pub state: String, // 'draft', 'posted', 'cancel'
    pub payment_state: String, // 'not_paid', 'in_payment', 'paid', 'partial', 'reversed', 'invoicing_legacy'
    pub invoice_date: NaiveDate,
    pub invoice_date_due: Option<NaiveDate>,
    pub r#ref: Option<String>,
    pub narration: Option<String>,
    pub currency_id: Option<Uuid>,
    pub journal_id: Uuid,
    pub payment_term_id: Option<Uuid>,
    pub fiscal_position_id: Option<Uuid>,
    pub amount_untaxed: BigDecimal,
    pub amount_tax: BigDecimal,
    pub amount_total: BigDecimal,
    pub amount_residual: BigDecimal,
    pub amount_residual_signed: BigDecimal,
    pub amount_signed: BigDecimal,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub created_by: Uuid,
    pub assignee_id: Option<Uuid>,
    pub shared_with: Option<Vec<Uuid>>,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AccountMoveLine {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub move_id: Uuid,
    pub name: String,
    pub product_id: Option<Uuid>,
    pub account_id: Uuid,
    pub partner_id: Option<Uuid>,
    pub date: NaiveDate,
    pub date_maturity: Option<NaiveDate>,
    pub debit: BigDecimal,
    pub credit: BigDecimal,
    pub amount_currency: BigDecimal,
    pub currency_id: Option<Uuid>,
    pub quantity: Option<BigDecimal>,
    pub price_unit: Option<BigDecimal>,
    pub discount: Option<BigDecimal>,
    pub tax_ids: Option<Vec<Uuid>>,
    pub analytic_distribution: Option<serde_json::Value>,
    pub balance: BigDecimal,
    pub amount_residual: BigDecimal,
    pub amount_residual_currency: BigDecimal,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub created_by: Uuid,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AccountTax {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub name: String,
    pub amount_type: String, // 'percent', 'fixed', 'group'
    pub amount: BigDecimal,
    pub type_tax_use: String, // 'sale', 'purchase', 'none'
    pub price_include: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub created_by: Uuid,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AccountPayment {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub name: String,
    pub payment_type: String, // 'inbound', 'outbound'
    pub partner_type: String, // 'customer', 'supplier'
    pub partner_id: Uuid,
    pub amount: BigDecimal,
    pub currency_id: Uuid,
    pub payment_date: NaiveDate,
    pub journal_id: Uuid,
    pub payment_method_id: Uuid,
    pub communication: Option<String>,
    pub state: String, // 'draft', 'posted', 'sent', 'reconciled', 'cancelled'
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub created_by: Uuid,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AccountPaymentTerm {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub name: String,
    pub note: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub created_by: Uuid,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AccountJournal {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub name: String,
    pub code: String,
    pub r#type: String, // 'sale', 'purchase', 'cash', 'bank', 'general'
    pub currency_id: Option<Uuid>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub created_by: Uuid,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AccountPaymentMethod {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub name: String,
    pub code: String,
    pub payment_type: String, // 'inbound', 'outbound'
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub created_by: Uuid,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AccountFiscalPosition {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub name: String,
    pub note: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub created_by: Uuid,
}
