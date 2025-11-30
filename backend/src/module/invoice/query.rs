use uuid::Uuid;
use sqlx::{Pool, Postgres, Row};
use sqlx::types::BigDecimal;

use super::dto::{InvoiceDto, InvoiceLineDto, ListInvoiceFilter};

/// List invoices with filters
pub async fn list_invoices(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    filter: ListInvoiceFilter,
) -> Result<Vec<InvoiceDto>, sqlx::Error> {
    let limit = filter.limit.unwrap_or(100).clamp(1, 500);
    let offset = filter.offset.unwrap_or(0).max(0);

    // Simplified query - filter in application layer for now
    // Use query and map manually to avoid type inference issues
    let rows = sqlx::query(
        r#"
        SELECT 
            am.id, am.tenant_id,
            am.name, am.ref as ref_field, am.date, am.journal_id, am.currency_id,
            am.move_type, am.state,
            am.partner_id, am.invoice_partner_display_name as partner_display_name,
            am.commercial_partner_id,
            am.invoice_date, am.invoice_date_due, am.invoice_origin,
            am.invoice_payment_term_id, am.invoice_user_id, am.fiscal_position_id,
            am.payment_state, am.payment_reference,
            COALESCE(am.amount_untaxed, 0)::numeric as amount_untaxed,
            COALESCE(am.amount_tax, 0)::numeric as amount_tax,
            COALESCE(am.amount_total, 0)::numeric as amount_total,
            COALESCE(am.amount_residual, 0)::numeric as amount_residual,
            am.narration,
            am.created_at, am.updated_at, am.created_by, am.assignee_id
        FROM account_move am
        WHERE am.tenant_id = $1
        ORDER BY am.date DESC, am.created_at DESC
        LIMIT $2 OFFSET $3
        "#
    )
    .bind(tenant_id)
    .bind(limit as i64)
    .bind(offset as i64)
    .fetch_all(pool)
    .await?;

    let mut invoices = Vec::new();
    for row in rows {
        invoices.push(InvoiceDto {
            id: row.try_get("id")?,
            tenant_id: row.try_get("tenant_id")?,
            name: row.try_get("name")?,
            ref_field: row.try_get("ref_field")?,
            date: row.try_get("date")?,
            journal_id: row.try_get("journal_id")?,
            currency_id: row.try_get("currency_id")?,
            move_type: row.try_get("move_type")?,
            state: row.try_get("state")?,
            partner_id: row.try_get("partner_id")?,
            partner_display_name: row.try_get("partner_display_name")?,
            commercial_partner_id: row.try_get("commercial_partner_id")?,
            invoice_date: row.try_get("invoice_date")?,
            invoice_date_due: row.try_get("invoice_date_due")?,
            invoice_origin: row.try_get("invoice_origin")?,
            invoice_payment_term_id: row.try_get("invoice_payment_term_id")?,
            invoice_user_id: row.try_get("invoice_user_id")?,
            fiscal_position_id: row.try_get("fiscal_position_id")?,
            payment_state: row.try_get("payment_state")?,
            payment_reference: row.try_get("payment_reference")?,
            amount_untaxed: row.try_get("amount_untaxed")?,
            amount_tax: row.try_get("amount_tax")?,
            amount_total: row.try_get("amount_total")?,
            amount_residual: row.try_get("amount_residual")?,
            narration: row.try_get("narration")?,
            invoice_lines: vec![], // Will be loaded separately if needed
            created_at: row.try_get("created_at")?,
            updated_at: row.try_get("updated_at")?,
            created_by: row.try_get("created_by")?,
            assignee_id: row.try_get("assignee_id")?,
        });
    }
    
    Ok(invoices)
}

/// Get invoice by ID with lines
pub async fn get_invoice_by_id(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    invoice_id: Uuid,
) -> Result<Option<InvoiceDto>, sqlx::Error> {
    // Get invoice
    let row_opt = sqlx::query(
        r#"
        SELECT 
            am.id, am.tenant_id,
            am.name, am.ref as ref_field, am.date, am.journal_id, am.currency_id,
            am.move_type, am.state,
            am.partner_id, am.invoice_partner_display_name as partner_display_name,
            am.commercial_partner_id,
            am.invoice_date, am.invoice_date_due, am.invoice_origin,
            am.invoice_payment_term_id, am.invoice_user_id, am.fiscal_position_id,
            am.payment_state, am.payment_reference,
            COALESCE(am.amount_untaxed, 0)::numeric as amount_untaxed,
            COALESCE(am.amount_tax, 0)::numeric as amount_tax,
            COALESCE(am.amount_total, 0)::numeric as amount_total,
            COALESCE(am.amount_residual, 0)::numeric as amount_residual,
            am.narration,
            am.created_at, am.updated_at, am.created_by, am.assignee_id
        FROM account_move am
        WHERE am.tenant_id = $1 AND am.id = $2
        "#
    )
    .bind(tenant_id)
    .bind(invoice_id)
    .fetch_optional(pool)
    .await?;

    if let Some(row) = row_opt {
        // Get invoice lines
        let lines = get_invoice_lines(pool, tenant_id, invoice_id).await?;

        let invoice = InvoiceDto {
            id: row.try_get("id")?,
            tenant_id: row.try_get("tenant_id")?,
            name: row.try_get("name")?,
            ref_field: row.try_get("ref_field")?,
            date: row.try_get("date")?,
            journal_id: row.try_get("journal_id")?,
            currency_id: row.try_get("currency_id")?,
            move_type: row.try_get("move_type")?,
            state: row.try_get("state")?,
            partner_id: row.try_get("partner_id")?,
            partner_display_name: row.try_get("partner_display_name")?,
            commercial_partner_id: row.try_get("commercial_partner_id")?,
            invoice_date: row.try_get("invoice_date")?,
            invoice_date_due: row.try_get("invoice_date_due")?,
            invoice_origin: row.try_get("invoice_origin")?,
            invoice_payment_term_id: row.try_get("invoice_payment_term_id")?,
            invoice_user_id: row.try_get("invoice_user_id")?,
            fiscal_position_id: row.try_get("fiscal_position_id")?,
            payment_state: row.try_get("payment_state")?,
            payment_reference: row.try_get("payment_reference")?,
            amount_untaxed: row.try_get("amount_untaxed")?,
            amount_tax: row.try_get("amount_tax")?,
            amount_total: row.try_get("amount_total")?,
            amount_residual: row.try_get("amount_residual")?,
            narration: row.try_get("narration")?,
            invoice_lines: lines,
            created_at: row.try_get("created_at")?,
            updated_at: row.try_get("updated_at")?,
            created_by: row.try_get("created_by")?,
            assignee_id: row.try_get("assignee_id")?,
        };

        Ok(Some(invoice))
    } else {
        Ok(None)
    }
}

/// Get invoice lines for an invoice
pub async fn get_invoice_lines(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    invoice_id: Uuid,
) -> Result<Vec<InvoiceLineDto>, sqlx::Error> {
    let line_rows = sqlx::query(
        r#"
        SELECT 
            aml.id, aml.move_id,
            aml.product_id,
            aml.name,
            aml.quantity, aml.price_unit, aml.discount,
            aml.account_id,
            COALESCE(aml.price_subtotal, 0)::numeric as price_subtotal,
            COALESCE(aml.price_total, 0)::numeric as price_total,
            aml.display_type,
            aml.sequence
        FROM account_move_line aml
        WHERE aml.tenant_id = $1 AND aml.move_id = $2
        ORDER BY COALESCE(aml.sequence, 0), aml.id
        "#
    )
    .bind(tenant_id)
    .bind(invoice_id)
    .fetch_all(pool)
    .await?;

    // Get tax IDs for each line
    let mut lines = Vec::new();
    for row in line_rows {
        let line_id: Uuid = row.try_get("id")?;
        
        let tax_ids = sqlx::query!(
            "SELECT tax_id FROM account_move_line_tax_rel WHERE tenant_id = $1 AND move_line_id = $2",
            tenant_id, line_id
        )
        .fetch_all(pool)
        .await?
        .into_iter()
        .map(|r| r.tax_id)
        .collect();

        let price_subtotal: BigDecimal = row.try_get("price_subtotal")?;
        let price_total: BigDecimal = row.try_get("price_total")?;
        let tax_amount = &price_total - &price_subtotal;

        // Calculate tax_rate from tax_amount and price_subtotal
        // tax_rate = (tax_amount / price_subtotal) * 100
        let tax_rate = if price_subtotal > BigDecimal::from(0) {
            Some((&tax_amount / &price_subtotal) * BigDecimal::from(100))
        } else {
            Some(BigDecimal::from(0))
        };

        lines.push(InvoiceLineDto {
            id: line_id,
            move_id: row.try_get("move_id")?,
            product_id: row.try_get("product_id")?,
            product_name: None,
            name: row.try_get("name")?,
            quantity: row.try_get("quantity")?,
            price_unit: row.try_get("price_unit")?,
            discount: row.try_get("discount")?,
            account_id: row.try_get("account_id")?,
            account_name: None,
            price_subtotal,
            price_total,
            tax_ids,
            tax_amount,
            tax_rate,
            display_type: row.try_get("display_type")?,
            sequence: row.try_get("sequence")?,
        });
    }

    Ok(lines)
}

