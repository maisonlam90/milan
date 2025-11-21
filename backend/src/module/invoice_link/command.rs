use uuid::Uuid;
use sqlx::{Pool, Postgres};
use serde_json::json;
use tracing::{error, info};
use anyhow::Result as AnyhowResult;

use super::model::InvoiceLinkStatus;
use super::dto::SendInvoiceToMeinvoiceInput;
use crate::module::invoice::query;
use crate::module::invoice::dto::InvoiceDto;

/// Gửi hóa đơn đến Meinvoice API
pub async fn send_invoice_to_meinvoice(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    user_id: Uuid,
    input: SendInvoiceToMeinvoiceInput,
) -> Result<Uuid, sqlx::Error> {
    // 1. Lấy thông tin invoice từ database
    let invoice = query::get_invoice_by_id(pool, tenant_id, input.invoice_id)
        .await?
        .ok_or_else(|| sqlx::Error::RowNotFound)?;

    // 2. Tạo record invoice_link với status pending
    let link_id = Uuid::new_v4();
    sqlx::query!(
        r#"
        INSERT INTO invoice_link (
            id, tenant_id, invoice_id, status, created_by, created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7)
        "#,
        link_id,
        tenant_id,
        input.invoice_id,
        InvoiceLinkStatus::Pending.as_str(),
        user_id,
        chrono::Utc::now(),
        chrono::Utc::now(),
    )
    .execute(pool)
    .await?;

    // 3. Chuyển đổi invoice sang format Meinvoice
    let meinvoice_data = convert_invoice_to_meinvoice_format(&invoice)
        .map_err(|e| {
            error!("Failed to convert invoice to Meinvoice format: {}", e);
            sqlx::Error::RowNotFound
        })?;

    // 4. Lấy config API (từ input hoặc từ database/config)
    let api_key = input.api_key
        .or_else(|| std::env::var("MEINVOICE_API_KEY").ok())
        .ok_or_else(|| sqlx::Error::RowNotFound)?;
    
    let api_url = input.api_url
        .or_else(|| std::env::var("MEINVOICE_API_URL").ok())
        .unwrap_or_else(|| "https://api.meinvoice.com.vn".to_string());

    // 5. Gửi request đến Meinvoice API
    let request_data = json!(meinvoice_data);
    let response = send_to_meinvoice_api(&api_url, &api_key, &request_data).await;

    // 6. Cập nhật invoice_link với kết quả
    match response {
        Ok(meinvoice_response) => {
            let meinvoice_id = meinvoice_response.get("invoice_id")
                .and_then(|v| v.as_str())
                .map(|s| s.to_string());
            let meinvoice_number = meinvoice_response.get("invoice_number")
                .and_then(|v| v.as_str())
                .map(|s| s.to_string());

            sqlx::query!(
                r#"
                UPDATE invoice_link
                SET status = $1,
                    meinvoice_invoice_id = $2,
                    meinvoice_invoice_number = $3,
                    request_data = $4,
                    response_data = $5,
                    updated_at = $6
                WHERE id = $7 AND tenant_id = $8
                "#,
                InvoiceLinkStatus::Success.as_str(),
                meinvoice_id,
                meinvoice_number,
                &request_data,
                &json!(meinvoice_response),
                chrono::Utc::now(),
                link_id,
                tenant_id,
            )
            .execute(pool)
            .await?;

            info!("Invoice {} sent to Meinvoice successfully", input.invoice_id);
            Ok(link_id)
        }
        Err(e) => {
            let error_msg = e.to_string();
            error!("Failed to send invoice to Meinvoice: {}", error_msg);

            sqlx::query!(
                r#"
                UPDATE invoice_link
                SET status = $1,
                    error_message = $2,
                    request_data = $3,
                    updated_at = $4
                WHERE id = $5 AND tenant_id = $6
                "#,
                InvoiceLinkStatus::Failed.as_str(),
                error_msg,
                &request_data,
                chrono::Utc::now(),
                link_id,
                tenant_id,
            )
            .execute(pool)
            .await?;

            Err(sqlx::Error::RowNotFound)
        }
    }
}

/// Chuyển đổi invoice từ hệ thống sang format Meinvoice
fn convert_invoice_to_meinvoice_format(invoice: &InvoiceDto) -> AnyhowResult<serde_json::Value> {
    // TODO: Map các trường từ invoice sang format của Meinvoice
    // Cần xem tài liệu API của Meinvoice để biết format chính xác
    // Ví dụ format cơ bản:
    Ok(json!({
        "invoice_number": invoice.name.clone(),
        "invoice_date": invoice.invoice_date,
        "partner_name": invoice.partner_display_name.clone(),
        "partner_tax_code": "", // Cần lấy từ partner
        "amount_untaxed": invoice.amount_untaxed.to_string(),
        "amount_tax": invoice.amount_tax.to_string(),
        "amount_total": invoice.amount_total.to_string(),
        "lines": invoice.invoice_lines.iter().map(|line| json!({
            "name": line.name.clone(),
            "quantity": line.quantity.as_ref().map(|q| q.to_string()),
            "price_unit": line.price_unit.as_ref().map(|p| p.to_string()),
            "price_subtotal": line.price_subtotal.to_string(),
        })).collect::<Vec<_>>(),
    }))
}

/// Gửi request đến Meinvoice API
async fn send_to_meinvoice_api(
    api_url: &str,
    api_key: &str,
    data: &serde_json::Value,
) -> Result<serde_json::Value, Box<dyn std::error::Error + Send + Sync>> {
    let client = reqwest::Client::new();
    
    let url = format!("{}/api/invoices", api_url);
    
    let response = client
        .post(&url)
        .header("Authorization", format!("Bearer {}", api_key))
        .header("Content-Type", "application/json")
        .json(data)
        .send()
        .await?;

    if response.status().is_success() {
        let json: serde_json::Value = response.json().await?;
        Ok(json)
    } else {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        Err(format!("Meinvoice API error {}: {}", status, text).into())
    }
}

/// Đăng nhập vào Meinvoice API
/// Theo tài liệu: https://doc.meinvoice.vn/api/Document/Login.html
pub async fn login_to_meinvoice(
    api_url: &str,
    username: &str,
    password: &str,
    taxcode: &str,
    appid: &str,
) -> Result<String, Box<dyn std::error::Error + Send + Sync>> {
    let client = reqwest::Client::new();
    
    // Endpoint theo tài liệu: <BaseURL>/auth/token
    let url = format!("{}/api/v3/auth/token", api_url);
    
    // Body parameter theo tài liệu
    let login_data = json!({
        "appid": appid,
        "taxcode": taxcode,
        "username": username,
        "password": password,
    });
    
    let response = client
        .post(&url)
        .header("Content-Type", "application/json")
        .json(&login_data)
        .send()
        .await?;

    if response.status().is_success() {
        let json: serde_json::Value = response.json().await?;
        
        // Response format theo tài liệu:
        // {
        //   "Success": true/false,
        //   "Data": "<token>",
        //   "ErrorCode": "...",
        //   "Errors": [],
        //   "CustomData": null
        // }
        
        let success = json.get("Success")
            .and_then(|v| v.as_bool())
            .unwrap_or(false);
        
        if success {
            let token = json.get("Data")
                .and_then(|v| v.as_str())
                .map(|s| s.to_string())
                .ok_or_else(|| "Token not found in response".to_string())?;
            
            Ok(token)
        } else {
            let error_code = json.get("ErrorCode")
                .and_then(|v| v.as_str())
                .unwrap_or("Unknown error");
            let errors = json.get("Errors")
                .and_then(|v| v.as_array())
                .map(|arr| arr.iter().filter_map(|v| v.as_str()).collect::<Vec<_>>().join(", "))
                .unwrap_or_default();
            
            Err(format!("Meinvoice login failed: ErrorCode={}, Errors={}", error_code, errors).into())
        }
    } else {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        Err(format!("Meinvoice login error {}: {}", status, text).into())
    }
}

/// Lưu thông tin đăng nhập Meinvoice vào database
pub async fn save_meinvoice_credentials(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    user_id: Uuid,
    input: &crate::module::invoice_link::dto::MeinvoiceLoginInput,
    token: &str,
) -> Result<(), sqlx::Error> {
    // TODO: Encrypt password before storing
    // For now, we'll store API key and URL, but not password
    // Password should be encrypted using bcrypt or similar
    
    // Check if credentials already exist for this user
    let existing = sqlx::query!(
        r#"
        SELECT id FROM meinvoice_credentials
        WHERE tenant_id = $1 AND user_id = $2
        "#,
        tenant_id,
        user_id,
    )
    .fetch_optional(pool)
    .await?;

    if let Some(record) = existing {
        // Update existing credentials
        sqlx::query!(
            r#"
            UPDATE meinvoice_credentials
            SET username = $1,
                api_key = $2,
                api_url = $3,
                token = $4,
                updated_at = $5
            WHERE id = $6 AND tenant_id = $7
            "#,
            input.username,
            input.appid, // Lưu appid vào api_key field (tạm thời, có thể tạo cột riêng sau)
            input.api_url.as_deref().unwrap_or("https://testapi.meinvoice.vn"),
            token,
            chrono::Utc::now(),
            record.id,
            tenant_id,
        )
        .execute(pool)
        .await?;
    } else {
        // Insert new credentials
        let id = Uuid::new_v4();
        sqlx::query!(
            r#"
            INSERT INTO meinvoice_credentials (
                id, tenant_id, user_id, username, api_key, api_url, token, created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
            "#,
            id,
            tenant_id,
            user_id,
            input.username,
            input.appid, // Lưu appid vào api_key field (tạm thời, có thể tạo cột riêng sau)
            input.api_url.as_deref().unwrap_or("https://testapi.meinvoice.vn"),
            token,
            chrono::Utc::now(),
            chrono::Utc::now(),
        )
        .execute(pool)
        .await?;
    }

    Ok(())
}

