use serde::{Deserialize, Serialize};
use uuid::Uuid;
use chrono::NaiveDate;
use sqlx::types::BigDecimal;

/// Input tạo mới invoice (Customer Invoice)
#[derive(Debug, Deserialize, Serialize)]
pub struct CreateInvoiceInput {
    // Basic info
    pub journal_id: Uuid,
    pub currency_id: Uuid,
    pub date: NaiveDate,                      // Ngày hạch toán
    
    // Partner info
    pub partner_id: Option<Uuid>,             // Customer
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
    pub fiscal_position_id: Option<Uuid>,
    
    // Invoice lines
    pub invoice_lines: Vec<CreateInvoiceLineInput>,
    
    // Narration
    pub narration: Option<String>,            // Terms and Conditions
    
    // IAM
    pub assignee_id: Option<Uuid>,
    pub shared_with: Option<Vec<Uuid>>,
}

/// Input tạo mới invoice line
#[derive(Debug, Deserialize, Serialize)]
pub struct CreateInvoiceLineInput {
    // Product
    pub product_id: Option<Uuid>,
    pub product_uom_id: Option<Uuid>,
    
    // Line info
    pub name: Option<String>,                 // Description
    pub quantity: Option<BigDecimal>,
    pub price_unit: Option<BigDecimal>,
    pub discount: Option<BigDecimal>,            // %
    
    // Account
    pub account_id: Option<Uuid>,
    
    // Tax
    pub tax_ids: Option<Vec<Uuid>>,           // Tax IDs
    
    // Display type
    pub display_type: Option<String>,         // 'line_section', 'line_subsection', 'line_note'
    
    // Sequence
    pub sequence: Option<i32>,
    
    // Analytic
    pub analytic_distribution: Option<serde_json::Value>,
}

/// Input cập nhật invoice
#[derive(Debug, Default, Deserialize, Serialize)]
pub struct UpdateInvoiceInput {
    // Basic info
    pub journal_id: Option<Uuid>,
    pub currency_id: Option<Uuid>,
    pub date: Option<NaiveDate>,
    
    // Partner info
    pub partner_id: Option<Uuid>,
    pub commercial_partner_id: Option<Uuid>,
    pub partner_shipping_id: Option<Uuid>,
    pub partner_bank_id: Option<Uuid>,
    
    // Invoice specific
    pub invoice_date: Option<NaiveDate>,
    pub invoice_date_due: Option<NaiveDate>,
    pub invoice_origin: Option<String>,
    pub invoice_payment_term_id: Option<Uuid>,
    pub invoice_user_id: Option<Uuid>,
    pub invoice_incoterm_id: Option<Uuid>,
    pub fiscal_position_id: Option<Uuid>,
    
    // Narration
    pub narration: Option<String>,
    
    // IAM
    pub assignee_id: Option<Uuid>,
    pub shared_with: Option<Vec<Uuid>>,
}

/// Input cập nhật invoice line
#[derive(Debug, Default, Deserialize, Serialize)]
pub struct UpdateInvoiceLineInput {
    pub product_id: Option<Uuid>,
    pub product_uom_id: Option<Uuid>,
    pub name: Option<String>,
    pub quantity: Option<BigDecimal>,
    pub price_unit: Option<BigDecimal>,
    pub discount: Option<BigDecimal>,
    pub account_id: Option<Uuid>,
    pub tax_ids: Option<Vec<Uuid>>,
    pub display_type: Option<String>,
    pub sequence: Option<i32>,
    pub analytic_distribution: Option<serde_json::Value>,
}

/// DTO cho Invoice response
#[derive(Debug, Serialize, Deserialize)]
pub struct InvoiceDto {
    pub id: Uuid,
    pub tenant_id: Uuid,
    
    // Basic info
    pub name: Option<String>,
    pub ref_field: Option<String>,
    pub date: NaiveDate,
    pub journal_id: Uuid,
    pub currency_id: Uuid,
    
    // Type & State
    pub move_type: String,
    pub state: String,
    
    // Partner info
    pub partner_id: Option<Uuid>,
    pub partner_display_name: Option<String>,
    pub commercial_partner_id: Option<Uuid>,
    
    // Invoice specific
    pub invoice_date: Option<NaiveDate>,
    pub invoice_date_due: Option<NaiveDate>,
    pub invoice_origin: Option<String>,
    pub invoice_payment_term_id: Option<Uuid>,
    pub invoice_user_id: Option<Uuid>,
    pub fiscal_position_id: Option<Uuid>,
    
    // Payment info
    pub payment_state: Option<String>,
    pub payment_reference: Option<String>,
    
    // Amounts
    pub amount_untaxed: BigDecimal,
    pub amount_tax: BigDecimal,
    pub amount_total: BigDecimal,
    pub amount_residual: BigDecimal,
    
    // Narration
    pub narration: Option<String>,
    
    // Invoice lines
    pub invoice_lines: Vec<InvoiceLineDto>,
    
    // IAM
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,
    pub created_by: Uuid,
    pub assignee_id: Option<Uuid>,
}

/// DTO cho Invoice Line response
#[derive(Debug, Serialize, Deserialize)]
pub struct InvoiceLineDto {
    pub id: Uuid,
    pub move_id: Uuid,
    
    // Product
    pub product_id: Option<Uuid>,
    pub product_name: Option<String>,
    
    // Line info
    pub name: Option<String>,
    pub quantity: Option<BigDecimal>,
    pub price_unit: Option<BigDecimal>,
    pub discount: Option<BigDecimal>,
    
    // Account
    pub account_id: Option<Uuid>,
    pub account_name: Option<String>,
    
    // Amounts
    pub price_subtotal: BigDecimal,
    pub price_total: BigDecimal,
    
    // Tax
    pub tax_ids: Vec<Uuid>,
    pub tax_amount: BigDecimal,
    
    // Display type
    pub display_type: Option<String>,
    pub sequence: Option<i32>,
}

/// Query string cho API list invoices
#[derive(Debug, Deserialize)]
pub struct ListInvoiceFilter {
    pub q: Option<String>,                    // Search by name, ref, partner
    pub partner_id: Option<Uuid>,
    pub journal_id: Option<Uuid>,
    pub move_type: Option<String>,            // 'out_invoice', 'in_invoice', etc.
    pub state: Option<String>,                // 'draft', 'posted', 'cancel'
    pub payment_state: Option<String>,        // 'not_paid', 'paid', etc.
    pub date_from: Option<NaiveDate>,
    pub date_to: Option<NaiveDate>,
    pub invoice_date_from: Option<NaiveDate>,
    pub invoice_date_to: Option<NaiveDate>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

