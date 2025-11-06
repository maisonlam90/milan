use sqlx::PgPool;
use uuid::Uuid;
use chrono::NaiveDate;

use crate::core::error::{AppError, ErrorResponse};
use crate::module::invoice::dto::InvoiceResponse;

pub async fn get_invoice_by_id(
    pool: &PgPool,
    tenant_id: Uuid,
    id: Uuid,
) -> Result<InvoiceResponse, AppError> {
    let row = sqlx::query!(
        r#"
        SELECT
            am.id, am.name, am.move_type, am.partner_id,
            c.name AS partner_name,
            am.state, am.payment_state,
            am.invoice_date, am.invoice_date_due,
            am.ref,
            am.amount_untaxed, am.amount_tax, am.amount_total, am.amount_residual,
            am.created_at, am.updated_at
        FROM account_move am
        LEFT JOIN contact c ON am.tenant_id = c.tenant_id AND am.partner_id = c.id
        WHERE am.tenant_id = $1 AND am.id = $2
        "#,
        tenant_id,
        id
    )
    .fetch_optional(pool)
    .await?
    .ok_or_else(|| AppError::Validation(ErrorResponse {
        code: "invoice_not_found",
        message: "Hóa đơn không tồn tại".into(),
    }))?;

    Ok(InvoiceResponse {
        id: row.id,
        name: row.name,
        move_type: row.move_type,
        partner_id: row.partner_id,
        partner_name: Some(row.partner_name),
        state: row.state,
        payment_state: row.payment_state,
        invoice_date: row.invoice_date,
        invoice_date_due: row.invoice_date_due,
        r#ref: row.r#ref,
        amount_untaxed: row.amount_untaxed.into(),
        amount_tax: row.amount_tax.into(),
        amount_total: row.amount_total.into(),
        amount_residual: row.amount_residual.into(),
        created_at: row.created_at,
        updated_at: row.updated_at,
        lines: None,
    })
}

pub async fn list_invoices(
    pool: &PgPool,
    tenant_id: Uuid,
    offset: i32,
    limit: i32,
    move_type: Option<String>,
    state: Option<String>,
    payment_state: Option<String>,
    partner_id: Option<Uuid>,
    date_from: Option<NaiveDate>,
    date_to: Option<NaiveDate>,
    search: Option<String>,
) -> Result<Vec<InvoiceResponse>, AppError> {
    let search_pattern = search.map(|s| format!("%{}%", s));

    let rows = sqlx::query!(
        r#"
        SELECT
            am.id, am.name, am.move_type, am.partner_id,
            c.name AS partner_name,
            am.state, am.payment_state,
            am.invoice_date, am.invoice_date_due,
            am.ref,
            am.amount_untaxed, am.amount_tax, am.amount_total, am.amount_residual,
            am.created_at, am.updated_at
        FROM account_move am
        LEFT JOIN contact c ON am.tenant_id = c.tenant_id AND am.partner_id = c.id
        WHERE
            am.tenant_id = $1
            AND ($2::varchar IS NULL OR am.move_type = $2)
            AND ($3::varchar IS NULL OR am.state = $3)
            AND ($4::varchar IS NULL OR am.payment_state = $4)
            AND ($5::uuid IS NULL OR am.partner_id = $5)
            AND ($6::date IS NULL OR am.invoice_date >= $6)
            AND ($7::date IS NULL OR am.invoice_date <= $7)
            AND ($8::varchar IS NULL OR am.name ILIKE $8)
        ORDER BY am.invoice_date DESC, am.created_at DESC
        LIMIT $9 OFFSET $10
        "#,
        tenant_id,
        move_type,
        state,
        payment_state,
        partner_id,
        date_from,
        date_to,
        search_pattern,
        limit as i64,
        offset as i64
    )
    .fetch_all(pool)
    .await?;

    Ok(rows.into_iter().map(|row| InvoiceResponse {
        id: row.id,
        name: row.name,
        move_type: row.move_type,
        partner_id: row.partner_id,
        partner_name: Some(row.partner_name),
        state: row.state,
        payment_state: row.payment_state,
        invoice_date: row.invoice_date,
        invoice_date_due: row.invoice_date_due,
        r#ref: row.r#ref,
        amount_untaxed: row.amount_untaxed.into(),
        amount_tax: row.amount_tax.into(),
        amount_total: row.amount_total.into(),
        amount_residual: row.amount_residual.into(),
        created_at: row.created_at,
        updated_at: row.updated_at,
        lines: None,
    }).collect())
}

pub async fn count_invoices(
    pool: &PgPool,
    tenant_id: Uuid,
    move_type: Option<String>,
    state: Option<String>,
    payment_state: Option<String>,
    partner_id: Option<Uuid>,
    date_from: Option<NaiveDate>,
    date_to: Option<NaiveDate>,
    search: Option<String>,
) -> Result<i64, AppError> {
    let search_pattern = search.map(|s| format!("%{}%", s));

    let count = sqlx::query_scalar::<_, i64>(
        r#"
        SELECT COUNT(*)
        FROM account_move am
        WHERE
            am.tenant_id = $1
            AND ($2::varchar IS NULL OR am.move_type = $2)
            AND ($3::varchar IS NULL OR am.state = $3)
            AND ($4::varchar IS NULL OR am.payment_state = $4)
            AND ($5::uuid IS NULL OR am.partner_id = $5)
            AND ($6::date IS NULL OR am.invoice_date >= $6)
            AND ($7::date IS NULL OR am.invoice_date <= $7)
            AND ($8::varchar IS NULL OR am.name ILIKE $8)
        "#,
    )
    .bind(tenant_id)
    .bind(move_type)
    .bind(state)
    .bind(payment_state)
    .bind(partner_id)
    .bind(date_from)
    .bind(date_to)
    .bind(search_pattern)
    .fetch_one(pool)
    .await?;

    Ok(count)
}
