use serde_json::json;
use anyhow::{Result, Context};
use tracing::{info, error};

use super::types::*;
use crate::module::invoice::dto::InvoiceDto;
use crate::module::contact::query::ContactDetail;

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
    contact_info: Option<&ContactDetail>,
) -> Result<ViettelCreateInvoiceResponse> {
    let client = reqwest::Client::new();
    
    // Convert invoice từ hệ thống sang format Viettel
    let viettel_request = convert_invoice_to_viettel_format(invoice, credentials, contact_info)?;
    
    // Log request JSON để debug
    if let Ok(json_str) = serde_json::to_string_pretty(&viettel_request) {
        info!("📤 Viettel request JSON:\n{}", json_str);
    } else {
        error!("Failed to serialize Viettel request to JSON");
    }
    
    // Log itemInfo chi tiết
    info!("📋 Total items: {}", viettel_request.item_info.len());
    for item in &viettel_request.item_info {
        info!("  - Line {}: {} x {} @ {} (with tax: {}) = {} (tax: {})", 
              item.line_number,
              item.item_name,
              item.quantity,
              item.unit_price.unwrap_or(0),
              item.unit_price_with_tax,
              item.item_total_amount_with_tax,
              item.tax_amount);
    }
    
    let url = format!("{}/{}", VIETTEL_CREATE_INVOICE_URL_TEMPLATE, username);
    info!("Sending invoice to Viettel URL: {}", url);
    
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
fn convert_invoice_to_viettel_format(
    invoice: &InvoiceDto, 
    credentials: &serde_json::Value,
    contact_info: Option<&ContactDetail>,
) -> Result<ViettelCreateInvoiceRequest> {
    // TODO: Map các trường từ invoice sang format Viettel
    // Hiện tại tạo structure cơ bản, cần map đầy đủ từ invoice DTO
    
    let items: Vec<ViettelItemInfo> = invoice.invoice_lines
        .iter()
        .filter(|line| line.display_type.is_none()) // Chỉ lấy các dòng sản phẩm, bỏ qua section/note
        .enumerate()
        .map(|(idx, line)| {
            let quantity = line.quantity.as_ref()
                .and_then(|q| q.to_string().parse::<f64>().ok())
                .unwrap_or(1.0);
            
            // price_unit là đơn giá CHƯA thuế trong hệ thống
            let unit_price_without_tax = line.price_unit.as_ref()
                .and_then(|p| p.to_string().parse::<f64>().ok())
                .unwrap_or(0.0);
            
            // Lấy tax rate từ line (nếu có)
            let tax_percentage = line.tax_rate.as_ref()
                .and_then(|r| r.to_string().parse::<i32>().ok())
                .unwrap_or(10); // Default 10% nếu không có
            
            // Lấy discount (%)
            let discount = line.discount.as_ref()
                .and_then(|d| d.to_string().parse::<f64>().ok())
                .unwrap_or(0.0);
            
            // Log để debug
            info!("Line {}: name={}, qty={}, price_unit={}, tax={}", 
                  idx + 1, 
                  line.name.as_ref().unwrap_or(&"N/A".to_string()),
                  quantity,
                  unit_price_without_tax,
                  tax_percentage);
            
            // Tính toán các giá trị
            let subtotal_before_tax = quantity * unit_price_without_tax * (1.0 - discount / 100.0);
            let tax_amount_calc = subtotal_before_tax * (tax_percentage as f64 / 100.0);
            let subtotal_with_tax = subtotal_before_tax + tax_amount_calc;
            
            // Đơn giá chưa thuế (làm tròn)
            let unit_price = if unit_price_without_tax > 0.0 {
                Some(unit_price_without_tax.round() as i64)
            } else {
                None
            };
            
            // Tính đơn giá có thuế (từ đơn giá chưa thuế)
            let unit_price_with_tax = if unit_price_without_tax > 0.0 {
                (unit_price_without_tax * (1.0 + tax_percentage as f64 / 100.0)).round() as i64
            } else {
                // Fallback: tính từ tổng tiền và số lượng
                if quantity > 0.0 {
                    (subtotal_with_tax / quantity).round() as i64
                } else {
                    0
                }
            };
            
            let item_total_with_tax = subtotal_with_tax.round() as i64;
            let item_total_without_tax = subtotal_before_tax.round() as i64;
            let tax_amount = item_total_with_tax - item_total_without_tax;
            
            info!("Line {} calculated: unit_price={:?}, unit_price_with_tax={}, total_with_tax={}, total_without_tax={}, tax={}", 
                  idx + 1, unit_price, unit_price_with_tax, item_total_with_tax, item_total_without_tax, tax_amount);
            
            ViettelItemInfo {
                line_number: (idx + 1) as i32, // Line number từ 1, 2, 3... sau khi đã filter
                selection: 1,
                item_code: line.product_id
                    .as_ref()
                    .map(|uuid| uuid.to_string())
                    .unwrap_or_else(|| format!("ITEM{}", idx + 1)),
                item_name: line.name.clone().unwrap_or_else(|| "Sản phẩm".to_string()),
                unit_name: "cái".to_string(), // TODO: Lấy từ product_uom_id
                quantity: quantity.round() as i32,
                unit_price, // Đơn giá chưa thuế
                unit_price_with_tax, // Đơn giá có thuế
                item_total_amount_with_tax: item_total_with_tax,
                tax_percentage,
                item_total_amount_without_tax: item_total_without_tax,
                tax_amount,
            }
        })
        .collect();
    
    // Validate: Phải có ít nhất 1 item
    if items.is_empty() {
        anyhow::bail!("Invoice must have at least one line item");
    }
    
    let total_without_tax: i64 = items.iter().map(|i| i.item_total_amount_without_tax).sum();
    let total_tax: i64 = items.iter().map(|i| i.tax_amount).sum();
    let total_with_tax: i64 = items.iter().map(|i| i.item_total_amount_with_tax).sum();
    
    info!("Invoice totals - Without tax: {}, Tax: {}, With tax: {}", 
          total_without_tax, total_tax, total_with_tax);
    
    // Lấy template_code và invoice_series từ credentials
    let template_code = credentials.get("template_code")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .unwrap_or_else(|| "1/3939".to_string()); // Default fallback
    
    let invoice_series = credentials.get("invoice_series")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .unwrap_or_else(|| "K25MEL".to_string()); // Default fallback

    // Lấy thông tin khách hàng từ contact (nếu có), nếu không thì dùng fallback
    let buyer_name = if let Some(contact) = contact_info {
        contact.display_name.clone()
            .or_else(|| contact.name.clone())
            .filter(|s| !s.is_empty())
            .unwrap_or_else(|| "Khách hàng".to_string())
    } else {
        invoice.partner_display_name.clone()
            .filter(|s| !s.is_empty())
            .unwrap_or_else(|| "Khách hàng".to_string())
    };

    let buyer_legal_name = if let Some(contact) = contact_info {
        contact.name.clone()
            .or_else(|| contact.display_name.clone())
            .filter(|s| !s.is_empty())
    } else {
        None
    };

    let buyer_tax_code = contact_info
        .and_then(|c| c.tax_code.clone())
        .filter(|s| !s.is_empty());

    // Chỉ lấy trường street, không lấy city, state, country
    let buyer_address = contact_info
        .and_then(|c| c.street.clone())
        .filter(|s| !s.is_empty());

    info!("Buyer info - Name: {}, Tax code: {:?}, Address: {:?}", 
          buyer_name, buyer_tax_code, buyer_address);
    
    Ok(ViettelCreateInvoiceRequest {
        general_invoice_info: ViettelGeneralInvoiceInfo {
            invoice_type: "1".to_string(),
            template_code,
            invoice_series,
            currency_code: "VND".to_string(),
            adjustment_type: "1".to_string(),
            payment_status: true,
            cus_get_invoice_right: true,
            user_name: "hung_test".to_string(), // Dùng username mặc định như trong bash script
        },
        buyer_info: ViettelBuyerInfo {
            buyer_name: buyer_name.clone(),
            buyer_legal_name: buyer_legal_name.or(Some(buyer_name.clone())),
            buyer_tax_code,
            buyer_address_line: buyer_address,
        },
        seller_info: ViettelSellerInfo {
            seller_legal_name: "CÔNG TY TNHH DUY TÂN LONG AN".to_string(),
            seller_tax_code: "0100109106-507".to_string(),
            seller_address_line: Some("518A Đường Hòa Hảo, phường Minh Phụng, Thành phố Hồ Chí Minh".to_string()),
            seller_phone_number: Some("0123456789".to_string()),
            seller_email: Some("einvoice@oms.vn".to_string()),
            seller_bank_account: Some("11223344".to_string()),
            seller_bank_name: Some("Ngân hàng ACB - CN Sài Gòn, Hồ Chí Minh".to_string()),
        },
        payments: vec![
            ViettelPayment {
                payment_method_name: "TM/CK".to_string(),
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

