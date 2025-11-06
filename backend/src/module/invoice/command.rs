use sqlx::PgPool;
use uuid::Uuid;
use chrono::{Datelike, NaiveDate};
use rust_decimal::prelude::ToPrimitive;

use crate::core::error::{AppError, ErrorResponse};
use crate::module::invoice::dto::{CreateInvoiceRequest, UpdateInvoiceRequest, PostInvoiceRequest, InvoiceResponse};

// ============================================================
// CREATE INVOICE
// ============================================================

pub async fn create_invoice(
    pool: &PgPool,
    tenant_id: Uuid,
    created_by: Uuid,
    payload: CreateInvoiceRequest,
) -> Result<InvoiceResponse, AppError> {
    let mut tx = pool.begin().await?;

    // 1. Generate invoice number
    let invoice_name = generate_invoice_number(
        &mut tx,
        tenant_id,
        &payload.move_type,
        payload.invoice_date,
    )
    .await?;

    // 2. Calculate totals from lines
    let mut amount_untaxed: i64 = 0;
    let mut amount_tax: i64 = 0;

    for line in &payload.lines {
        let quantity = line.quantity.as_ref()
            .and_then(|q| q.to_f64())
            .unwrap_or(1.0);
        let price_unit = line.price_unit.as_ref()
            .and_then(|p| p.to_i64())
            .unwrap_or(0) as f64;
        let discount = line.discount.as_ref()
            .and_then(|d| d.to_f64())
            .unwrap_or(0.0);

        let subtotal = (price_unit * quantity * (1.0 - discount / 100.0)) as i64;
        amount_untaxed += subtotal;
    }

    let amount_total = amount_untaxed + amount_tax;

    // 3. Insert account_move
    let _result = sqlx::query!(
        r#"
        INSERT INTO account_move (
            tenant_id, name, move_type, partner_id,
            state, payment_state,
            invoice_date, invoice_date_due,
            ref, narration,
            currency_id, journal_id, payment_term_id, fiscal_position_id,
            amount_untaxed, amount_tax, amount_total, amount_residual,
            created_by
        )
        VALUES (
            $1, $2, $3, $4,
            'draft', 'not_paid',
            $5, $6,
            $7, $8,
            $9, $10, $11, $12,
            $13, $14, $15, $16,
            $17
        )
        "#,
        tenant_id,
        invoice_name,
        payload.move_type,
        payload.partner_id,
        payload.invoice_date,
        payload.invoice_date_due,
        payload.r#ref,
        payload.narration,
        Some("VND"),
        payload.journal_id,
        payload.payment_term_id,
        payload.fiscal_position_id,
        amount_untaxed,
        amount_tax,
        amount_total,
        amount_total,
        created_by
    )
    .execute(tx.as_mut())
    .await?;

    // 4. Now query the created invoice
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
        WHERE am.tenant_id = $1 AND am.name = $2
        LIMIT 1
        "#,
        tenant_id,
        invoice_name
    )
    .fetch_one(tx.as_mut())
    .await?;

    let invoice = InvoiceResponse {
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
    };

    // 5. Insert lines (stub for now)
    for _line in payload.lines.iter() {
        // TODO: Implement line insertion with proper type conversions
    }

    tx.commit().await?;

    Ok(invoice)
}

// ============================================================
// HELPER FUNCTIONS
// ============================================================

async fn generate_invoice_number(
    tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    tenant_id: Uuid,
    move_type: &str,
    invoice_date: NaiveDate,
) -> Result<String, AppError> {
    let year = invoice_date.year();
    let month = invoice_date.month();
    let period_ym = year * 100 + month as i32;

    let result = sqlx::query_scalar::<_, Option<i64>>(
        r#"
        UPDATE invoice_counters_monthly
        SET counter = counter + 1
        WHERE tenant_id = $1 AND move_type = $2 AND period_ym = $3
        RETURNING counter
        "#,
    )
    .bind(tenant_id)
    .bind(move_type)
    .bind(period_ym)
    .fetch_optional(tx.as_mut())
    .await?;

    let counter = match result {
        Some(Some(c)) => c,
        _ => {
            sqlx::query_scalar::<_, i64>(
                r#"
                INSERT INTO invoice_counters_monthly (tenant_id, move_type, period_ym, counter)
                VALUES ($1, $2, $3, 1)
                RETURNING counter
                "#,
            )
            .bind(tenant_id)
            .bind(move_type)
            .bind(period_ym)
            .fetch_one(tx.as_mut())
            .await?
        }
    };

    let prefix = match move_type {
        "out_invoice" => "INV",
        "in_invoice" => "BILL",
        "out_refund" => "CRED",
        "in_refund" => "REFUND",
        "entry" => "ENTRY",
        _ => "DOC",
    };

    Ok(format!("{}/{:04}/{:02}/{:06}", prefix, year, month, counter))
}

// ============================================================
// STUBS (TODO)
// ============================================================

pub async fn update_invoice(
    _pool: &PgPool,
    _tenant_id: Uuid,
    _id: Uuid,
    _payload: UpdateInvoiceRequest,
) -> Result<InvoiceResponse, AppError> {
    Err(AppError::Validation(ErrorResponse {
        code: "not_implemented",
        message: "Not implemented".into(),
    }))
}

pub async fn delete_invoice(
    _pool: &PgPool,
    _tenant_id: Uuid,
    _id: Uuid,
) -> Result<(), AppError> {
    Ok(())
}

pub async fn post_invoice(
    _pool: &PgPool,
    _tenant_id: Uuid,
    _id: Uuid,
    _payload: PostInvoiceRequest,
) -> Result<InvoiceResponse, AppError> {
    Err(AppError::Validation(ErrorResponse {
        code: "not_implemented",
        message: "Not implemented".into(),
    }))
}

pub async fn reset_to_draft(
    _pool: &PgPool,
    _tenant_id: Uuid,
    _id: Uuid,
) -> Result<InvoiceResponse, AppError> {
    Err(AppError::Validation(ErrorResponse {
        code: "not_implemented",
        message: "Not implemented".into(),
    }))
}

pub async fn cancel_invoice(
    _pool: &PgPool,
    _tenant_id: Uuid,
    _id: Uuid,
) -> Result<InvoiceResponse, AppError> {
    Err(AppError::Validation(ErrorResponse {
        code: "not_implemented",
        message: "Not implemented".into(),
    }))
}

pub async fn reverse_invoice(
    _pool: &PgPool,
    _tenant_id: Uuid,
    _id: Uuid,
) -> Result<InvoiceResponse, AppError> {
    Err(AppError::Validation(ErrorResponse {
        code: "not_implemented",
        message: "Not implemented".into(),
    }))
}