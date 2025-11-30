use uuid::Uuid;
use sqlx::{Pool, Postgres};
use serde_json::json;
use tracing::{error, info};
use anyhow::Result;

use super::{
    model::{InvoiceLinkStatus, ProviderCredentials},
    dto::{LinkProviderInput, SendInvoiceToProviderInput},
    invoice_link_viettel,
};
use crate::module::invoice::query as invoice_query;

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
            let username = input.credentials.get("username")
                .and_then(|v| v.as_str())
                .ok_or_else(|| sqlx::Error::RowNotFound)?;
            let password = input.credentials.get("password")
                .and_then(|v| v.as_str())
                .ok_or_else(|| sqlx::Error::RowNotFound)?;
            
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
            UPDATE provider_credentials
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
        SELECT id FROM provider_credentials
        WHERE tenant_id = $1 AND provider = $2 AND user_id = $3
        "#,
        tenant_id,
        input.provider,
        user_id,
    )
    .fetch_optional(pool)
    .await?;

    let credential_id = if let Some(record) = existing {
        // Update existing credentials
        sqlx::query!(
            r#"
            UPDATE provider_credentials
            SET credentials = $1,
                access_token = $2,
                is_active = true,
                is_default = $3,
                updated_at = $4
            WHERE id = $5 AND tenant_id = $6
            "#,
            json!(input.credentials),
            access_token,
            is_default,
            chrono::Utc::now(),
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
            INSERT INTO provider_credentials (
                id, tenant_id, user_id, provider, credentials, access_token, is_active, is_default, created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            "#,
            id,
            tenant_id,
            user_id,
            input.provider,
            json!(input.credentials),
            access_token,
            true,
            is_default,
            chrono::Utc::now(),
            chrono::Utc::now(),
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
    let credentials = if let Some(credential_id) = input.credential_id {
        sqlx::query_as!(
            ProviderCredentials,
            r#"
            SELECT id, tenant_id, user_id, provider, credentials, access_token, token_expires_at, is_active, is_default, created_at, updated_at
            FROM provider_credentials
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
            FROM provider_credentials
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
    .ok_or_else(|| sqlx::Error::RowNotFound)?;

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
                .ok_or_else(|| sqlx::Error::RowNotFound)?;
            
            let access_token = credentials.access_token
                .as_ref()
                .ok_or_else(|| sqlx::Error::RowNotFound)?;
            
            invoice_link_viettel::create_draft_invoice(username, access_token, &invoice, &credentials.credentials)
                .await
        }
        "mobifone" => {
            // TODO: Implement Mobifone
            return Err(sqlx::Error::RowNotFound);
        }
        _ => {
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

