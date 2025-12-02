use uuid::Uuid;
use sqlx::{Pool, Postgres};
use serde_json::json;
use tracing::{error, info, warn};
use anyhow::Result;
use chrono::{Utc, Duration};

use super::{
    model::{InvoiceLinkStatus, ProviderCredentials},
    dto::{LinkProviderInput, SendInvoiceToProviderInput},
    invoice_link_viettel,
};
use crate::module::invoice::query as invoice_query;
use crate::module::contact::query as contact_query;

/// Kiểm tra và refresh token nếu cần
/// Trả về access_token mới (hoặc token cũ nếu còn hạn)
async fn ensure_valid_token(
    pool: &Pool<Postgres>,
    credentials: &mut ProviderCredentials,
) -> Result<String, sqlx::Error> {
    // Kiểm tra xem token có tồn tại và còn hạn không
    let needs_refresh = if let Some(_token) = &credentials.access_token {
        if let Some(expires_at) = credentials.token_expires_at {
            // Token hết hạn hoặc sắp hết hạn (trong vòng 5 phút)
            let now = Utc::now();
            let buffer = Duration::minutes(5);
            expires_at <= now + buffer
        } else {
            // Không có thông tin expiry, coi như hết hạn
            warn!("Token exists but no expiry time, refreshing token for credential {}", credentials.id);
            true
        }
    } else {
        // Không có token, cần refresh
        warn!("No token found for credential {}, refreshing token", credentials.id);
        true
    };

    if !needs_refresh {
        // Token còn hạn, trả về token hiện tại
        return Ok(credentials.access_token.as_ref().unwrap().clone());
    }

    // Token hết hạn hoặc không có, cần login lại
    info!("Refreshing token for credential {} (provider: {})", credentials.id, credentials.provider);

    let new_token = match credentials.provider.as_str() {
        "viettel" => {
            let username = credentials.credentials.get("username")
                .and_then(|v| v.as_str())
                .ok_or_else(|| {
                    error!("Username not found in credentials");
                    sqlx::Error::RowNotFound
                })?;
            
            let password = credentials.credentials.get("password")
                .and_then(|v| v.as_str())
                .ok_or_else(|| {
                    error!("Password not found in credentials");
                    sqlx::Error::RowNotFound
                })?;
            
            invoice_link_viettel::login(username, password)
                .await
                .map_err(|e| {
                    error!("Viettel login failed during token refresh: {}", e);
                    sqlx::Error::RowNotFound
                })?
        }
        "mobifone" => {
            // TODO: Implement Mobifone login
            error!("Mobifone not implemented yet");
            return Err(sqlx::Error::RowNotFound);
        }
        _ => {
            error!("Unknown provider: {}", credentials.provider);
            return Err(sqlx::Error::RowNotFound);
        }
    };

    // Tính thời gian hết hạn (giả sử token có hiệu lực 24 giờ)
    // Viettel API không trả về expires_in, nên ta set mặc định
    let token_expires_at = Utc::now() + Duration::hours(24);

    // Cập nhật token mới vào database
    sqlx::query!(
        r#"
        UPDATE invoice_link_provider_credentials
        SET access_token = $1,
            token_expires_at = $2,
            updated_at = $3
        WHERE id = $4 AND tenant_id = $5
        "#,
        new_token,
        token_expires_at,
        Utc::now(),
        credentials.id,
        credentials.tenant_id,
    )
    .execute(pool)
    .await?;

    info!("Token refreshed successfully for credential {}", credentials.id);

    // Cập nhật credentials object
    credentials.access_token = Some(new_token.clone());
    credentials.token_expires_at = Some(token_expires_at);

    Ok(new_token)
}

/// Link provider với tenant (lưu credentials)
pub async fn link_provider(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    user_id: Uuid,
    input: LinkProviderInput,
) -> Result<Uuid, sqlx::Error> {
    // Validate và login với provider để test credentials
    let access_token = match input.provider.as_str() {
        "viettel" => {
            // Validate tất cả các trường bắt buộc cho Viettel
            let username = input.credentials.get("username")
                .and_then(|v| v.as_str())
                .filter(|s| !s.is_empty())
                .ok_or_else(|| {
                    error!("Viettel credentials missing: username");
                    sqlx::Error::RowNotFound
                })?;
            
            let password = input.credentials.get("password")
                .and_then(|v| v.as_str())
                .filter(|s| !s.is_empty())
                .ok_or_else(|| {
                    error!("Viettel credentials missing: password");
                    sqlx::Error::RowNotFound
                })?;
            
            let template_code = input.credentials.get("template_code")
                .and_then(|v| v.as_str())
                .filter(|s| !s.is_empty())
                .ok_or_else(|| {
                    error!("Viettel credentials missing: template_code");
                    sqlx::Error::RowNotFound
                })?;
            
            let invoice_series = input.credentials.get("invoice_series")
                .and_then(|v| v.as_str())
                .filter(|s| !s.is_empty())
                .ok_or_else(|| {
                    error!("Viettel credentials missing: invoice_series");
                    sqlx::Error::RowNotFound
                })?;
            
            info!(
                "Viettel credentials validated - username: {}, template_code: {}, invoice_series: {}",
                username, template_code, invoice_series
            );
            
            invoice_link_viettel::login(username, password)
                .await
                .map_err(|e| {
                    error!("Viettel login failed: {}", e);
                    sqlx::Error::RowNotFound
                })?
        }
        "mobifone" => {
            // TODO: Implement Mobifone login
            return Err(sqlx::Error::RowNotFound);
        }
        _ => {
            return Err(sqlx::Error::RowNotFound);
        }
    };

    let is_default = input.is_default.unwrap_or(false);

    // Nếu set default, unset tất cả credentials khác của cùng provider
    if is_default {
        sqlx::query!(
            r#"
            UPDATE invoice_link_provider_credentials
            SET is_default = false
            WHERE tenant_id = $1 AND provider = $2
            "#,
            tenant_id,
            input.provider,
        )
        .execute(pool)
        .await?;
    }

    // Check if credentials already exist
    let existing = sqlx::query!(
        r#"
        SELECT id FROM invoice_link_provider_credentials
        WHERE tenant_id = $1 AND provider = $2 AND user_id = $3
        "#,
        tenant_id,
        input.provider,
        user_id,
    )
    .fetch_optional(pool)
    .await?;

    // Tính thời gian hết hạn token (mặc định 24 giờ)
    let token_expires_at = Utc::now() + Duration::hours(24);

    let credential_id = if let Some(record) = existing {
        // Update existing credentials
        sqlx::query!(
            r#"
            UPDATE invoice_link_provider_credentials
            SET credentials = $1,
                access_token = $2,
                token_expires_at = $3,
                is_active = true,
                is_default = $4,
                updated_at = $5
            WHERE id = $6 AND tenant_id = $7
            "#,
            json!(input.credentials),
            access_token,
            token_expires_at,
            is_default,
            Utc::now(),
            record.id,
            tenant_id,
        )
        .execute(pool)
        .await?;

        record.id
    } else {
        // Insert new credentials
        let id = Uuid::new_v4();
        sqlx::query!(
            r#"
            INSERT INTO invoice_link_provider_credentials (
                id, tenant_id, user_id, provider, credentials, access_token, token_expires_at, is_active, is_default, created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
            "#,
            id,
            tenant_id,
            user_id,
            input.provider,
            json!(input.credentials),
            access_token,
            token_expires_at,
            true,
            is_default,
            Utc::now(),
            Utc::now(),
        )
        .execute(pool)
        .await?;

        id
    };

    info!("Provider {} linked successfully for tenant {} (is_default: {})", input.provider, tenant_id, is_default);
    Ok(credential_id)
}

/// Gửi hóa đơn đến provider
pub async fn send_invoice_to_provider(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    user_id: Uuid,
    input: SendInvoiceToProviderInput,
) -> Result<Uuid, sqlx::Error> {
    // 1. Lấy invoice từ database
    let invoice = invoice_query::get_invoice_by_id(pool, tenant_id, input.invoice_id)
        .await?
        .ok_or_else(|| sqlx::Error::RowNotFound)?;

    // 2. Lấy credentials của provider
    let mut credentials = if let Some(credential_id) = input.credential_id {
        sqlx::query_as!(
            ProviderCredentials,
            r#"
            SELECT id, tenant_id, user_id, provider, credentials, access_token, token_expires_at, is_active, is_default, created_at, updated_at
            FROM invoice_link_provider_credentials
            WHERE id = $1 AND tenant_id = $2 AND provider = $3 AND is_active = true
            "#,
            credential_id,
            tenant_id,
            input.provider,
        )
        .fetch_optional(pool)
        .await?
    } else {
        // Ưu tiên lấy credentials mặc định, nếu không có thì lấy mới nhất
        sqlx::query_as!(
            ProviderCredentials,
            r#"
            SELECT id, tenant_id, user_id, provider, credentials, access_token, token_expires_at, is_active, is_default, created_at, updated_at
            FROM invoice_link_provider_credentials
            WHERE tenant_id = $1 AND provider = $2 AND is_active = true
            ORDER BY is_default DESC, updated_at DESC
            LIMIT 1
            "#,
            tenant_id,
            input.provider,
        )
        .fetch_optional(pool)
        .await?
    }
    .ok_or_else(|| {
        error!("No active credentials found for provider: {}", input.provider);
        sqlx::Error::RowNotFound
    })?;

    // 2.5. Đảm bảo token còn hạn, nếu không thì refresh
    let access_token = ensure_valid_token(pool, &mut credentials)
        .await
        .map_err(|e| {
            error!("Failed to ensure valid token: {:?}", e);
            e
        })?;

    // 2.6. Lấy thông tin contact nếu invoice có partner_id
    let contact_info = if let Some(partner_id) = invoice.partner_id {
        contact_query::get_contact_by_id(pool, tenant_id, partner_id)
            .await
            .ok()
    } else {
        None
    };

    // 3. Tạo record invoice_link với status pending
    let link_id = Uuid::new_v4();
    sqlx::query!(
        r#"
        INSERT INTO invoice_link (
            id, tenant_id, invoice_id, provider, status, created_by, created_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        "#,
        link_id,
        tenant_id,
        input.invoice_id,
        input.provider,
        InvoiceLinkStatus::Pending.as_str(),
        user_id,
        chrono::Utc::now(),
        chrono::Utc::now(),
    )
    .execute(pool)
    .await?;

    // 4. Gửi invoice đến provider
    let result = match input.provider.as_str() {
        "viettel" => {
            let username = credentials.credentials.get("username")
                .and_then(|v| v.as_str())
                .ok_or_else(|| {
                    error!("Username not found in credentials");
                    sqlx::Error::RowNotFound
                })?;
            
            // Sử dụng access_token đã được đảm bảo còn hạn
            invoice_link_viettel::create_draft_invoice(
                username, 
                &access_token, 
                &invoice, 
                &credentials.credentials,
                contact_info.as_ref()
            )
            .await
        }
        "mobifone" => {
            // TODO: Implement Mobifone
            error!("Mobifone not implemented yet");
            return Err(sqlx::Error::RowNotFound);
        }
        _ => {
            error!("Unknown provider: {}", input.provider);
            return Err(sqlx::Error::RowNotFound);
        }
    };

    // 5. Cập nhật invoice_link với kết quả
    match result {
        Ok(provider_response) => {
            sqlx::query!(
                r#"
                UPDATE invoice_link
                SET status = $1,
                    provider_invoice_id = $2,
                    provider_invoice_number = $3,
                    response_data = $4,
                    updated_at = $5
                WHERE id = $6 AND tenant_id = $7
                "#,
                InvoiceLinkStatus::Linked.as_str(),
                provider_response.invoice_id,
                provider_response.invoice_number,
                json!(provider_response),
                chrono::Utc::now(),
                link_id,
                tenant_id,
            )
            .execute(pool)
            .await?;

            info!("Invoice {} sent to {} successfully", input.invoice_id, input.provider);
            Ok(link_id)
        }
        Err(e) => {
            let error_msg = e.to_string();
            error!("Failed to send invoice to {}: {}", input.provider, error_msg);

            sqlx::query!(
                r#"
                UPDATE invoice_link
                SET status = $1,
                    error_message = $2,
                    updated_at = $3
                WHERE id = $4 AND tenant_id = $5
                "#,
                InvoiceLinkStatus::Failed.as_str(),
                error_msg,
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

