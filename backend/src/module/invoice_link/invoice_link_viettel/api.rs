use serde_json::json;
use anyhow::{Result, Context};
use tracing::{info, error};

use super::types::*;
use crate::module::invoice::dto::InvoiceDto;

const VIETTEL_API_BASE_URL: &str = "https://api-vinvoice.viettel.vn";
const VIETTEL_LOGIN_URL: &str = "https://api-vinvoice.viettel.vn/auth/login";
const VIETTEL_CREATE_INVOICE_URL_TEMPLATE: &str = "https://api-vinvoice.viettel.vn/services/einvoiceapplication/api/InvoiceAPI/InvoiceWS/createOrUpdateInvoiceDraft";

/// Đăng nhập vào Viettel API
/// Trả về access_token
pub async fn login(username: &str, password: &str) -> Result<String> {
    let client = reqwest::Client::new();
    
    let login_data = json!({
        "username": username,
        "password": password,
    });
    
    let response = client
        .post(VIETTEL_LOGIN_URL)
        .header("Content-Type", "application/json")
        .json(&login_data)
        .send()
        .await
        .context("Failed to send login request to Viettel")?;

    if !response.status().is_success() {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        error!("Viettel login failed: {} - {}", status, text);
        anyhow::bail!("Viettel login failed: {} - {}", status, text);
    }

    let json: serde_json::Value = response.json().await
        .context("Failed to parse Viettel login response")?;
    
    // Extract access_token từ response
    let access_token = json.get("access_token")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .or_else(|| {
            // Nếu không có access_token, thử tìm trong các field khác
            json.as_object()
                .and_then(|obj| obj.values().find_map(|v| v.as_str().map(|s| s.to_string())))
        })
        .context("Access token not found in Viettel login response")?;

    info!("Viettel login successful for username: {}", username);
    Ok(access_token)
}

/// Tạo draft invoice trên Viettel
pub async fn create_draft_invoice(
    username: &str,
    access_token: &str,
    invoice: &InvoiceDto,
    credentials: &serde_json::Value,
) -> Result<ViettelCreateInvoiceResponse> {
    let client = reqwest::Client::new();
    
    // Convert invoice từ hệ thống sang format Viettel
    let viettel_request = convert_invoice_to_viettel_format(invoice, credentials)?;
    
    let url = format!("{}/{}", VIETTEL_CREATE_INVOICE_URL_TEMPLATE, username);
    
    let response = client
        .post(&url)
        .header("Authorization", format!("Bearer {}", access_token))
        .header("Content-Type", "application/json")
        .json(&viettel_request)
        .send()
        .await
        .context("Failed to send create invoice request to Viettel")?;

    if !response.status().is_success() {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        error!("Viettel create invoice failed: {} - {}", status, text);
        anyhow::bail!("Viettel create invoice failed: {} - {}", status, text);
    }

    let json: serde_json::Value = response.json().await
        .context("Failed to parse Viettel create invoice response")?;
    
    info!("Viettel draft invoice created successfully for invoice: {}", invoice.id);
    
    // Parse response
    Ok(ViettelCreateInvoiceResponse {
        invoice_id: json.get("invoice_id")
            .and_then(|v| v.as_str())
            .map(|s| s.to_string()),
        invoice_number: json.get("invoice_number")
            .and_then(|v| v.as_str())
            .map(|s| s.to_string()),
        other: json,
    })
}

/// Chuyển đổi invoice từ hệ thống sang format Viettel
fn convert_invoice_to_viettel_format(invoice: &InvoiceDto, credentials: &serde_json::Value) -> Result<ViettelCreateInvoiceRequest> {
    // TODO: Map các trường từ invoice sang format Viettel
    // Hiện tại tạo structure cơ bản, cần map đầy đủ từ invoice DTO
    
    let items: Vec<ViettelItemInfo> = invoice.invoice_lines
        .iter()
        .enumerate()
        .map(|(idx, line)| {
            let quantity = line.quantity.as_ref()
                .and_then(|q| q.to_string().parse::<i32>().ok())
                .unwrap_or(1);
            
            let unit_price_with_tax = line.price_unit.as_ref()
                .and_then(|p| p.to_string().parse::<i64>().ok())
                .unwrap_or(0);
            
            // Lấy tax rate từ line (nếu có)
            let tax_percentage = line.tax_rate.as_ref()
                .and_then(|r| r.to_string().parse::<i32>().ok())
                .unwrap_or(10); // Default 10% nếu không có
            
            let item_total_with_tax = line.price_subtotal.to_string()
                .parse::<i64>()
                .unwrap_or(0);
            
            let item_total_before_tax = if tax_percentage > 0 {
                (item_total_with_tax * 100) / (100 + tax_percentage as i64)
            } else {
                item_total_with_tax
            };
            let tax_amount = item_total_with_tax - item_total_before_tax;
            
            ViettelItemInfo {
                line_number: (idx + 1) as i32,
                selection: 1,
                item_code: format!("ITEM{}", idx + 1),
                item_name: line.name.clone().unwrap_or_default(),
                unit_name: "cái".to_string(), // TODO: Lấy từ product_uom_id hoặc product
                quantity,
                unit_price_with_tax,
                item_total_amount_with_tax: item_total_with_tax,
                tax_percentage,
                item_total_amount_without_tax: item_total_before_tax,
                tax_amount,
            }
        })
        .collect();
    
    let total_without_tax: i64 = items.iter().map(|i| i.item_total_amount_without_tax).sum();
    let total_tax: i64 = items.iter().map(|i| i.tax_amount).sum();
    let total_with_tax: i64 = items.iter().map(|i| i.item_total_amount_with_tax).sum();
    
    // Lấy template_code và invoice_series từ credentials
    let template_code = credentials.get("template_code")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .unwrap_or_else(|| "1/3939".to_string()); // Default fallback
    
    let invoice_series = credentials.get("invoice_series")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .unwrap_or_else(|| "K25MEL".to_string()); // Default fallback

    Ok(ViettelCreateInvoiceRequest {
        general_invoice_info: ViettelGeneralInvoiceInfo {
            invoice_type: "1".to_string(),
            template_code,
            invoice_series,
            currency_code: "VND".to_string(),
            adjustment_type: "1".to_string(),
            payment_status: true,
            cus_get_invoice_right: true,
            user_name: "system".to_string(), // TODO: Lấy từ user context
        },
        buyer_info: ViettelBuyerInfo {
            buyer_name: invoice.partner_display_name.clone().unwrap_or_default(),
            buyer_legal_name: invoice.partner_display_name.clone(),
            buyer_tax_code: None, // TODO: Lấy từ partner
            buyer_address_line: None, // TODO: Lấy từ partner
        },
        seller_info: ViettelSellerInfo {
            seller_legal_name: "CÔNG TY TNHH DUY TÂN LONG AN".to_string(), // TODO: Lấy từ company config
            seller_tax_code: "0100109106-507".to_string(), // TODO: Lấy từ company config
            seller_address_line: Some("518A Đường Hòa Hảo, phường Minh Phụng, Thành phố Hồ Chí Minh".to_string()), // TODO: Lấy từ company config
            seller_phone_number: None, // TODO: Lấy từ company config
            seller_email: None, // TODO: Lấy từ company config
            seller_bank_account: None, // TODO: Lấy từ company config
            seller_bank_name: None, // TODO: Lấy từ company config
        },
        payments: vec![
            ViettelPayment {
                payment_method_name: "TM".to_string(), // TODO: Lấy từ invoice payment method
            }
        ],
        item_info: items,
        summarize_info: ViettelSummarizeInfo {
            total_amount_without_tax: total_without_tax,
            total_tax_amount: total_tax,
            total_amount_with_tax: total_with_tax,
        },
    })
}

