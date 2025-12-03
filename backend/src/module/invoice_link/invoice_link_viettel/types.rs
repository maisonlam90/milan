use serde::{Deserialize, Serialize};

/// Response từ Viettel login API
#[derive(Debug, Deserialize, Serialize)]
pub struct ViettelLoginResponse {
    pub access_token: Option<String>,
    pub token_type: Option<String>,
    pub expires_in: Option<u64>,
    #[serde(flatten)]
    pub other: serde_json::Value,
}

/// Request body để tạo draft invoice Viettel
#[derive(Debug, Serialize, Deserialize)]
pub struct ViettelCreateInvoiceRequest {
    #[serde(rename = "generalInvoiceInfo")]
    pub general_invoice_info: ViettelGeneralInvoiceInfo,
    #[serde(rename = "buyerInfo")]
    pub buyer_info: ViettelBuyerInfo,
    #[serde(rename = "sellerInfo", skip_serializing_if = "Option::is_none")]
    pub seller_info: Option<ViettelSellerInfo>,
    pub payments: Vec<ViettelPayment>,
    #[serde(rename = "itemInfo")]
    pub item_info: Vec<ViettelItemInfo>,
    #[serde(rename = "summarizeInfo")]
    pub summarize_info: ViettelSummarizeInfo,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ViettelGeneralInvoiceInfo {
    #[serde(rename = "invoiceType")]
    pub invoice_type: String, // "1"
    #[serde(rename = "templateCode")]
    pub template_code: String, // "1/3939"
    #[serde(rename = "invoiceSeries")]
    pub invoice_series: String, // "K25MEL"
    #[serde(rename = "currencyCode")]
    pub currency_code: String, // "VND"
    #[serde(rename = "adjustmentType")]
    pub adjustment_type: String, // "1"
    #[serde(rename = "paymentStatus")]
    pub payment_status: bool,
    #[serde(rename = "cusGetInvoiceRight")]
    pub cus_get_invoice_right: bool,
    #[serde(rename = "userName")]
    pub user_name: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ViettelBuyerInfo {
    #[serde(rename = "buyerName")]
    pub buyer_name: String,
    #[serde(rename = "buyerLegalName")]
    pub buyer_legal_name: Option<String>,
    #[serde(rename = "buyerTaxCode")]
    pub buyer_tax_code: Option<String>,
    #[serde(rename = "buyerAddressLine")]
    pub buyer_address_line: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ViettelSellerInfo {
    #[serde(rename = "sellerLegalName")]
    pub seller_legal_name: String,
    #[serde(rename = "sellerTaxCode")]
    pub seller_tax_code: String,
    #[serde(rename = "sellerAddressLine")]
    pub seller_address_line: Option<String>,
    #[serde(rename = "sellerPhoneNumber")]
    pub seller_phone_number: Option<String>,
    #[serde(rename = "sellerEmail")]
    pub seller_email: Option<String>,
    #[serde(rename = "sellerBankAccount")]
    pub seller_bank_account: Option<String>,
    #[serde(rename = "sellerBankName")]
    pub seller_bank_name: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ViettelPayment {
    #[serde(rename = "paymentMethodName")]
    pub payment_method_name: String, // "TM", "CK", etc.
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ViettelItemInfo {
    #[serde(rename = "lineNumber")]
    pub line_number: i32,
    pub selection: i32,
    #[serde(rename = "itemCode")]
    pub item_code: String,
    #[serde(rename = "itemName")]
    pub item_name: String,
    #[serde(rename = "unitName")]
    pub unit_name: String,
    pub quantity: i32,
    #[serde(rename = "unitPrice", skip_serializing_if = "Option::is_none")]
    pub unit_price: Option<i64>,
    #[serde(rename = "unitPriceWithTax")]
    pub unit_price_with_tax: i64,
    #[serde(rename = "itemTotalAmountWithTax")]
    pub item_total_amount_with_tax: i64,
    #[serde(rename = "taxPercentage")]
    pub tax_percentage: f64,  // BigDecimal: -2, -1, 0, 5, 8, 10, hoặc giá trị % khác (vd: 12.34)
    #[serde(rename = "itemTotalAmountWithoutTax")]
    pub item_total_amount_without_tax: i64,
    #[serde(rename = "taxAmount")]
    pub tax_amount: i64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ViettelSummarizeInfo {
    #[serde(rename = "totalAmountWithoutTax")]
    pub total_amount_without_tax: i64,
    #[serde(rename = "totalTaxAmount")]
    pub total_tax_amount: i64,
    #[serde(rename = "totalAmountWithTax")]
    pub total_amount_with_tax: i64,
}

/// Response từ Viettel create invoice API
#[derive(Debug, Deserialize, Serialize)]
pub struct ViettelCreateInvoiceResponse {
    pub invoice_id: Option<String>,
    pub invoice_number: Option<String>,
    #[serde(flatten)]
    pub other: serde_json::Value,
}

