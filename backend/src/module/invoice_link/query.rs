use uuid::Uuid;
use sqlx::{Pool, Postgres, Row};
use super::dto::{InvoiceLinkDto, ListInvoiceLinkFilter, ProviderCredentialsDto};

/// Lấy invoice link theo ID
pub async fn get_invoice_link_by_id(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    link_id: Uuid,
) -> Result<Option<InvoiceLinkDto>, sqlx::Error> {
    let row = sqlx::query!(
        r#"
        SELECT 
            id, invoice_id, provider, provider_invoice_id, provider_invoice_number,
            status, error_message, created_at, updated_at
        FROM invoice_link
        WHERE id = $1 AND tenant_id = $2
        "#,
        link_id,
        tenant_id,
    )
    .fetch_optional(pool)
    .await?;

    Ok(row.map(|r| InvoiceLinkDto {
        id: r.id,
        invoice_id: r.invoice_id,
        provider: r.provider,
        provider_invoice_id: r.provider_invoice_id,
        provider_invoice_number: r.provider_invoice_number,
        status: r.status,
        error_message: r.error_message,
        created_at: r.created_at,
        updated_at: r.updated_at,
    }))
}

/// List invoice links với filter
pub async fn list_invoice_links(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    filter: ListInvoiceLinkFilter,
) -> Result<Vec<InvoiceLinkDto>, sqlx::Error> {
    let limit = filter.limit.unwrap_or(100).clamp(1, 500);
    let offset = filter.offset.unwrap_or(0).max(0);

    let mut query = String::from(
        r#"
        SELECT 
            id, invoice_id, provider, provider_invoice_id, provider_invoice_number,
            status, error_message, created_at, updated_at
        FROM invoice_link
        WHERE tenant_id = $1
        "#
    );

    let mut param_count = 2;

    if let Some(ref invoice_id) = filter.invoice_id {
        query.push_str(&format!(" AND invoice_id = ${}", param_count));
        param_count += 1;
    }

    if let Some(ref provider) = filter.provider {
        query.push_str(&format!(" AND provider = ${}", param_count));
        param_count += 1;
    }

    if let Some(ref status) = filter.status {
        query.push_str(&format!(" AND status = ${}", param_count));
        param_count += 1;
    }

    query.push_str(" ORDER BY created_at DESC LIMIT $");
    query.push_str(&param_count.to_string());
    param_count += 1;
    query.push_str(" OFFSET $");
    query.push_str(&param_count.to_string());

    let mut query_builder = sqlx::query(&query).bind(tenant_id);

    if let Some(ref invoice_id) = filter.invoice_id {
        query_builder = query_builder.bind(invoice_id);
    }

    if let Some(ref provider) = filter.provider {
        query_builder = query_builder.bind(provider);
    }

    if let Some(ref status) = filter.status {
        query_builder = query_builder.bind(status);
    }

    query_builder = query_builder.bind(limit as i64).bind(offset as i64);

    let rows = query_builder.fetch_all(pool).await?;

    let mut links = Vec::new();
    for row in rows {
        links.push(InvoiceLinkDto {
            id: row.try_get("id")?,
            invoice_id: row.try_get("invoice_id")?,
            provider: row.try_get("provider")?,
            provider_invoice_id: row.try_get("provider_invoice_id")?,
            provider_invoice_number: row.try_get("provider_invoice_number")?,
            status: row.try_get("status")?,
            error_message: row.try_get("error_message")?,
            created_at: row.try_get("created_at")?,
            updated_at: row.try_get("updated_at")?,
        });
    }

    Ok(links)
}

/// Lấy invoice link theo invoice_id (lấy link mới nhất)
pub async fn get_latest_invoice_link_by_invoice_id(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    invoice_id: Uuid,
) -> Result<Option<InvoiceLinkDto>, sqlx::Error> {
    let row = sqlx::query!(
        r#"
        SELECT 
            id, invoice_id, provider, provider_invoice_id, provider_invoice_number,
            status, error_message, created_at, updated_at
        FROM invoice_link
        WHERE invoice_id = $1 AND tenant_id = $2
        ORDER BY created_at DESC
        LIMIT 1
        "#,
        invoice_id,
        tenant_id,
    )
    .fetch_optional(pool)
    .await?;

    Ok(row.map(|r| InvoiceLinkDto {
        id: r.id,
        invoice_id: r.invoice_id,
        provider: r.provider,
        provider_invoice_id: r.provider_invoice_id,
        provider_invoice_number: r.provider_invoice_number,
        status: r.status,
        error_message: r.error_message,
        created_at: r.created_at,
        updated_at: r.updated_at,
    }))
}

/// Lấy danh sách credentials của tenant
pub async fn list_provider_credentials(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
) -> Result<Vec<ProviderCredentialsDto>, sqlx::Error> {
    let rows = sqlx::query!(
        r#"
        SELECT id, provider, is_active, is_default, created_at, updated_at
        FROM provider_credentials
        WHERE tenant_id = $1
        ORDER BY is_default DESC, updated_at DESC
        "#,
        tenant_id,
    )
    .fetch_all(pool)
    .await?;

    Ok(rows.into_iter().map(|r| ProviderCredentialsDto {
        id: r.id,
        provider: r.provider,
        is_active: r.is_active,
        is_default: r.is_default,
        created_at: r.created_at,
        updated_at: r.updated_at,
    }).collect())
}

