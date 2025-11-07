use serde::{Serialize, Deserialize};
use uuid::Uuid;
use chrono::{DateTime, Utc, NaiveDate};
use sqlx::types::BigDecimal;
use sqlx::FromRow;

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum MoveType {
    Entry,
    OutInvoice,    // Customer Invoice
    OutRefund,     // Customer Credit Note
    InInvoice,     // Vendor Bill
    InRefund,      // Vendor Credit Note
    OutReceipt,    // Sales Receipt
    InReceipt,     // Purchase Receipt
}

impl MoveType {
    pub fn as_str(&self) -> &'static str {
        match self {
            MoveType::Entry => "entry",
            MoveType::OutInvoice => "out_invoice",
            MoveType::OutRefund => "out_refund",
            MoveType::InInvoice => "in_invoice",
            MoveType::InRefund => "in_refund",
            MoveType::OutReceipt => "out_receipt",
            MoveType::InReceipt => "in_receipt",
        }
    }
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum MoveState {
    Draft,
    Posted,
    Cancel,
}

impl MoveState {
    pub fn as_str(&self) -> &'static str {
        match self {
            MoveState::Draft => "draft",
            MoveState::Posted => "posted",
            MoveState::Cancel => "cancel",
        }
    }
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum PaymentState {
    NotPaid,
    InPayment,
    Paid,
    Partial,
    Reversed,
    InvoicingLegacy,
}

impl PaymentState {
    pub fn as_str(&self) -> &'static str {
        match self {
            PaymentState::NotPaid => "not_paid",
            PaymentState::InPayment => "in_payment",
            PaymentState::Paid => "paid",
            PaymentState::Partial => "partial",
            PaymentState::Reversed => "reversed",
            PaymentState::InvoicingLegacy => "invoicing_legacy",
        }
    }
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum DisplayType {
    LineSection,
    LineSubsection,
    LineNote,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AccountMove {
    pub id: Uuid,
    pub tenant_id: Uuid,
    
    // Basic info
    pub name: Option<String>,           // Số chứng từ (auto-generated)
    pub ref_field: Option<String>,      // Số tham chiếu
    pub date: NaiveDate,                // Ngày hạch toán
    pub journal_id: Uuid,
    pub currency_id: Uuid,
    
    // Type & State
    pub move_type: String,              // 'entry', 'out_invoice', 'out_refund', etc.
    pub state: String,                  // 'draft', 'posted', 'cancel'
    
    // Partner info (for invoices)
    pub partner_id: Option<Uuid>,
    pub commercial_partner_id: Option<Uuid>,
    pub partner_shipping_id: Option<Uuid>,
    pub partner_bank_id: Option<Uuid>,
    
    // Invoice specific
    pub invoice_date: Option<NaiveDate>,      // Ngày hóa đơn
    pub invoice_date_due: Option<NaiveDate>,  // Ngày đến hạn
    pub invoice_origin: Option<String>,       // Nguồn gốc (SO, PO...)
    pub invoice_payment_term_id: Option<Uuid>,
    pub invoice_user_id: Option<Uuid>,        // Salesperson
    pub invoice_incoterm_id: Option<Uuid>,
    pub invoice_cash_rounding_id: Option<Uuid>,
    pub fiscal_position_id: Option<Uuid>,
    
    // Invoice display
    pub invoice_source_email: Option<String>,
    pub invoice_partner_display_name: Option<String>,
    pub incoterm_location: Option<String>,
    
    // Payment info
    pub payment_reference: Option<String>,
    pub qr_code_method: Option<String>,
    pub payment_state: Option<String>,        // 'not_paid', 'in_payment', 'paid', etc.
    pub preferred_payment_method_line_id: Option<Uuid>,
    
    // Amounts
    pub invoice_currency_rate: Option<BigDecimal>,
    pub amount_untaxed: BigDecimal,
    pub amount_tax: BigDecimal,
    pub amount_total: BigDecimal,
    pub amount_residual: BigDecimal,             // Số tiền còn phải trả
    pub amount_untaxed_signed: BigDecimal,
    pub amount_untaxed_in_currency_signed: BigDecimal,
    pub amount_tax_signed: BigDecimal,
    pub amount_total_signed: BigDecimal,
    pub amount_total_in_currency_signed: BigDecimal,
    pub amount_residual_signed: BigDecimal,
    pub quick_edit_total_amount: Option<BigDecimal>,
    
    // Narration
    pub narration: Option<String>,            // Terms and Conditions
    
    // Reversal
    pub reversed_entry_id: Option<Uuid>,
    
    // Auto post
    pub auto_post: Option<String>,            // 'no', 'at_date', 'monthly', etc.
    pub auto_post_until: Option<NaiveDate>,
    pub auto_post_origin_id: Option<Uuid>,
    
    // Tax settings
    pub always_tax_exigible: bool,
    pub taxable_supply_date: Option<NaiveDate>,
    
    // Security & tracking
    pub posted_before: bool,
    pub is_move_sent: bool,
    pub is_manually_modified: bool,
    pub checked: bool,
    pub made_sequence_gap: bool,
    
    // Sequence
    pub sequence_number: Option<i32>,
    pub sequence_prefix: Option<String>,
    pub secure_sequence_number: Option<i32>,
    pub inalterable_hash: Option<String>,
    
    // Statement link
    pub statement_line_id: Option<Uuid>,
    
    // Tax cash basis
    pub tax_cash_basis_rec_id: Option<Uuid>,
    pub tax_cash_basis_origin_move_id: Option<Uuid>,
    
    // Delivery date
    pub delivery_date: Option<NaiveDate>,
    
    // Sending data (e-invoice)
    pub sending_data: Option<serde_json::Value>,
    
    // Message attachment
    pub message_main_attachment_id: Option<Uuid>,
    
    // Access token
    pub access_token: Option<String>,
    
    // Idempotency
    pub idempotency_key: Option<String>,
    
    // IAM
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub created_by: Uuid,
    pub assignee_id: Option<Uuid>,
    pub shared_with: Vec<Uuid>,
}

#[derive(Debug, Serialize, Deserialize, Clone, FromRow)]
pub struct AccountMoveLine {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub move_id: Uuid,
    
    // Account info
    pub account_id: Option<Uuid>,
    pub journal_id: Option<Uuid>,
    pub currency_id: Uuid,
    pub company_currency_id: Option<Uuid>,
    
    // Partner
    pub partner_id: Option<Uuid>,
    
    // Product (for invoice lines)
    pub product_id: Option<Uuid>,
    pub product_uom_id: Option<Uuid>,
    pub quantity: Option<BigDecimal>,
    pub price_unit: Option<BigDecimal>,
    pub discount: Option<BigDecimal>,            // %
    pub discount_date: Option<NaiveDate>,
    pub discount_amount_currency: Option<BigDecimal>,
    pub discount_balance: Option<BigDecimal>,
    
    // Line info
    pub name: Option<String>,                 // Description
    pub ref_field: Option<String>,
    pub move_name: Option<String>,
    pub parent_state: Option<String>,
    pub sequence: Option<i32>,
    pub display_type: Option<String>,         // NULL, 'line_section', 'line_subsection', 'line_note'
    
    // Debit/Credit (accounting entries)
    pub debit: BigDecimal,
    pub credit: BigDecimal,
    pub balance: BigDecimal,                     // debit - credit
    pub amount_currency: BigDecimal,
    
    // Amounts (for invoice lines)
    pub price_subtotal: BigDecimal,              // Subtotal before tax
    pub price_total: BigDecimal,                 // Total with tax
    
    // Tax
    pub tax_base_amount: BigDecimal,
    pub tax_line_id: Option<Uuid>,            // Nếu dòng này là dòng thuế
    pub group_tax_id: Option<Uuid>,
    pub tax_group_id: Option<Uuid>,
    pub tax_repartition_line_id: Option<Uuid>,
    
    // Tax extra data
    pub extra_tax_data: Option<serde_json::Value>,
    pub deductible_amount: Option<BigDecimal>,
    
    // Reconciliation
    pub full_reconcile_id: Option<Uuid>,
    pub matching_number: Option<String>,
    pub amount_residual: BigDecimal,
    pub amount_residual_currency: BigDecimal,
    pub reconciled: bool,
    pub reconcile_model_id: Option<Uuid>,
    
    // Payment
    pub payment_id: Option<Uuid>,
    pub statement_line_id: Option<Uuid>,
    pub statement_id: Option<Uuid>,
    
    // Dates
    pub date: Option<NaiveDate>,
    pub invoice_date: Option<NaiveDate>,
    pub date_maturity: Option<NaiveDate>,     // Ngày đáo hạn cho receivable/payable
    
    // Analytic
    pub analytic_distribution: Option<serde_json::Value>,  // {'analytic_account_id': 100.0}
    
    // Anglo-Saxon
    pub is_anglo_saxon_line: bool,
    pub is_storno: bool,
    
    // Flags
    pub exclude_from_invoice_tab: bool,
    pub is_imported: bool,
    pub no_followup: bool,
    pub collapse_composition: bool,
    pub collapse_prices: bool,
    
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

