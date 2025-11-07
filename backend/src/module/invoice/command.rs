use uuid::Uuid;
use sqlx::{Pool, Postgres};
use chrono::NaiveDate;
use sqlx::types::BigDecimal;
use serde_json::Value;

#[derive(Debug)]
pub struct CreateInvoiceDto {
    pub journal_id: Uuid,
    pub currency_id: Uuid,
    pub date: NaiveDate,
    pub partner_id: Option<Uuid>,
    pub commercial_partner_id: Option<Uuid>,
    pub partner_shipping_id: Option<Uuid>,
    pub partner_bank_id: Option<Uuid>,
    pub invoice_date: Option<NaiveDate>,
    pub invoice_date_due: Option<NaiveDate>,
    pub invoice_origin: Option<String>,
    pub invoice_payment_term_id: Option<Uuid>,
    pub invoice_user_id: Option<Uuid>,
    pub invoice_incoterm_id: Option<Uuid>,
    pub fiscal_position_id: Option<Uuid>,
    pub narration: Option<String>,
    pub invoice_lines: Vec<CreateInvoiceLineDto>,
    pub created_by: Uuid,
    pub assignee_id: Option<Uuid>,
    pub shared_with: Vec<Uuid>,
}

#[derive(Debug)]
pub struct CreateInvoiceLineDto {
    pub product_id: Option<Uuid>,
    pub product_uom_id: Option<Uuid>,
    pub name: Option<String>,
    pub quantity: Option<BigDecimal>,
    pub price_unit: Option<BigDecimal>,
    pub discount: Option<BigDecimal>,
    pub account_id: Option<Uuid>,
    pub tax_ids: Vec<Uuid>,
    pub display_type: Option<String>,
    pub sequence: Option<i32>,
    pub analytic_distribution: Option<Value>,
}

#[derive(Debug)]
pub struct UpdateInvoiceDto {
    pub journal_id: Option<Uuid>,
    pub currency_id: Option<Uuid>,
    pub date: Option<NaiveDate>,
    pub partner_id: Option<Uuid>,
    pub commercial_partner_id: Option<Uuid>,
    pub partner_shipping_id: Option<Uuid>,
    pub partner_bank_id: Option<Uuid>,
    pub invoice_date: Option<NaiveDate>,
    pub invoice_date_due: Option<NaiveDate>,
    pub invoice_origin: Option<String>,
    pub invoice_payment_term_id: Option<Uuid>,
    pub invoice_user_id: Option<Uuid>,
    pub invoice_incoterm_id: Option<Uuid>,
    pub fiscal_position_id: Option<Uuid>,
    pub narration: Option<String>,
    pub assignee_id: Option<Uuid>,
    pub shared_with: Option<Vec<Uuid>>,
}

#[derive(Debug)]
pub struct UpdateInvoiceLineDto {
    pub product_id: Option<Uuid>,
    pub product_uom_id: Option<Uuid>,
    pub name: Option<String>,
    pub quantity: Option<BigDecimal>,
    pub price_unit: Option<BigDecimal>,
    pub discount: Option<BigDecimal>,
    pub account_id: Option<Uuid>,
    pub tax_ids: Option<Vec<Uuid>>,
    pub display_type: Option<String>,
    pub sequence: Option<i32>,
    pub analytic_distribution: Option<Value>,
}

/// Create a new invoice
pub async fn create_invoice(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    dto: CreateInvoiceDto,
) -> Result<Uuid, sqlx::Error> {
    let invoice_id = Uuid::new_v4();
    
    // Generate invoice name/sequence (simplified - should use proper sequence)
    let invoice_name = format!("INV/{}", chrono::Utc::now().format("%Y/%m/%d"));
    
    sqlx::query!(
        r#"
        INSERT INTO account_move (
            tenant_id, id, name, date, journal_id, currency_id,
            move_type, state,
            partner_id, commercial_partner_id, partner_shipping_id, partner_bank_id,
            invoice_date, invoice_date_due, invoice_origin,
            invoice_payment_term_id, invoice_user_id, invoice_incoterm_id, fiscal_position_id,
            narration,
            amount_untaxed, amount_tax, amount_total, amount_residual,
            amount_untaxed_signed, amount_tax_signed, amount_total_signed, amount_residual_signed,
            created_by, assignee_id, shared_with
        ) VALUES (
            $1, $2, $3, $4, $5, $6,
            'out_invoice', 'draft',
            $7, $8, $9, $10,
            $11, $12, $13,
            $14, $15, $16, $17,
            $18,
            0, 0, 0, 0,
            0, 0, 0, 0,
            $19, $20, $21
        )
        "#,
        tenant_id, invoice_id, invoice_name, dto.date, dto.journal_id, dto.currency_id,
        dto.partner_id, dto.commercial_partner_id, dto.partner_shipping_id, dto.partner_bank_id,
        dto.invoice_date, dto.invoice_date_due, dto.invoice_origin,
        dto.invoice_payment_term_id, dto.invoice_user_id, dto.invoice_incoterm_id, dto.fiscal_position_id,
        dto.narration,
        dto.created_by, dto.assignee_id, &dto.shared_with
    )
    .execute(pool)
    .await?;

    // Create invoice lines
    for (idx, line) in dto.invoice_lines.iter().enumerate() {
        let line_id = Uuid::new_v4();
        let sequence = line.sequence.unwrap_or((idx * 10) as i32);
        
        // Calculate amounts (simplified)
        let quantity = line.quantity.as_ref().map(|q| q.clone()).unwrap_or_else(|| BigDecimal::from(1));
        let price_unit = line.price_unit.as_ref().map(|p| p.clone()).unwrap_or_else(|| BigDecimal::from(0));
        let discount = line.discount.as_ref().map(|d| d.clone()).unwrap_or_else(|| BigDecimal::from(0));
        let discount_factor = BigDecimal::from(1) - (discount / BigDecimal::from(100));
        let price_subtotal = &quantity * &price_unit * &discount_factor;
        let price_total = price_subtotal.clone(); // TODO: Add tax calculation
        
        sqlx::query!(
            r#"
            INSERT INTO account_move_line (
                tenant_id, id, move_id, currency_id,
                product_id, product_uom_id, quantity, price_unit, discount,
                name, sequence, display_type,
                account_id,
                price_subtotal, price_total,
                debit, credit, balance, amount_currency,
                exclude_from_invoice_tab
            ) VALUES (
                $1, $2, $3, $4,
                $5, $6, $7, $8, $9,
                $10, $11, $12,
                $13,
                $14, $15,
                0, 0, 0, 0,
                false
            )
            "#,
            tenant_id, line_id, invoice_id, dto.currency_id,
            line.product_id, line.product_uom_id, line.quantity, line.price_unit, line.discount,
            line.name.as_deref(), sequence, line.display_type.as_deref(),
            line.account_id,
            price_subtotal, price_total
        )
        .execute(pool)
        .await?;

        // Create tax relations
        for tax_id in &line.tax_ids {
            sqlx::query!(
                r#"
                INSERT INTO account_move_line_tax_rel (tenant_id, move_line_id, tax_id)
                VALUES ($1, $2, $3)
                ON CONFLICT DO NOTHING
                "#,
                tenant_id, line_id, tax_id
            )
            .execute(pool)
            .await?;
        }
    }

    // Recalculate totals
    recalculate_invoice_totals(pool, tenant_id, invoice_id).await?;

    Ok(invoice_id)
}

/// Update invoice
pub async fn update_invoice(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    invoice_id: Uuid,
    dto: UpdateInvoiceDto,
) -> Result<(), sqlx::Error> {
    let mut query = sqlx::QueryBuilder::new("UPDATE account_move SET ");

    let mut has_updates = false;

    if let Some(ref val) = dto.journal_id {
        if has_updates {
            query.push(", ");
        }
        query.push("journal_id = ");
        query.push_bind(val);
        has_updates = true;
    }

    if let Some(ref val) = dto.currency_id {
        if has_updates {
            query.push(", ");
        }
        query.push("currency_id = ");
        query.push_bind(val);
        has_updates = true;
    }

    if let Some(ref val) = dto.date {
        if has_updates {
            query.push(", ");
        }
        query.push("date = ");
        query.push_bind(val);
        has_updates = true;
    }

    if let Some(ref val) = dto.partner_id {
        if has_updates {
            query.push(", ");
        }
        query.push("partner_id = ");
        query.push_bind(val);
        has_updates = true;
    }

    if let Some(ref val) = dto.invoice_date {
        if has_updates {
            query.push(", ");
        }
        query.push("invoice_date = ");
        query.push_bind(val);
        has_updates = true;
    }

    if let Some(ref val) = dto.invoice_date_due {
        if has_updates {
            query.push(", ");
        }
        query.push("invoice_date_due = ");
        query.push_bind(val);
        has_updates = true;
    }

    if let Some(ref val) = dto.narration {
        if has_updates {
            query.push(", ");
        }
        query.push("narration = ");
        query.push_bind(val);
        has_updates = true;
    }

    if let Some(ref val) = dto.assignee_id {
        if has_updates {
            query.push(", ");
        }
        query.push("assignee_id = ");
        query.push_bind(val);
        has_updates = true;
    }

    if let Some(ref val) = dto.shared_with {
        if has_updates {
            query.push(", ");
        }
        query.push("shared_with = ");
        query.push_bind(val);
        has_updates = true;
    }

    if !has_updates {
        return Ok(());
    }

    query.push(", updated_at = now()");
    query.push(" WHERE tenant_id = ");
    query.push_bind(tenant_id);
    query.push(" AND id = ");
    query.push_bind(invoice_id);

    query.build().execute(pool).await?;

    Ok(())
}

/// Confirm/Post invoice
pub async fn confirm_invoice(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    invoice_id: Uuid,
    _user_id: Uuid,
) -> Result<(), sqlx::Error> {
    sqlx::query!(
        r#"
        UPDATE account_move
        SET state = 'posted', posted_before = true, updated_at = now()
        WHERE tenant_id = $1 AND id = $2 AND state = 'draft'
        "#,
        tenant_id, invoice_id
    )
    .execute(pool)
    .await?;

    Ok(())
}

/// Cancel invoice
pub async fn cancel_invoice(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    invoice_id: Uuid,
) -> Result<(), sqlx::Error> {
    sqlx::query!(
        r#"
        UPDATE account_move
        SET state = 'cancel', updated_at = now()
        WHERE tenant_id = $1 AND id = $2
        "#,
        tenant_id, invoice_id
    )
    .execute(pool)
    .await?;

    Ok(())
}

/// Delete invoice
pub async fn delete_invoice(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    invoice_id: Uuid,
) -> Result<(), sqlx::Error> {
    // Only allow deletion of draft invoices
    sqlx::query!(
        r#"
        DELETE FROM account_move
        WHERE tenant_id = $1 AND id = $2 AND state = 'draft'
        "#,
        tenant_id, invoice_id
    )
    .execute(pool)
    .await?;

    Ok(())
}

/// Add invoice line
pub async fn add_invoice_line(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    invoice_id: Uuid,
    dto: CreateInvoiceLineDto,
) -> Result<Uuid, sqlx::Error> {
    let line_id = Uuid::new_v4();
    
    // Get currency from invoice
    let invoice = sqlx::query!(
        "SELECT currency_id FROM account_move WHERE tenant_id = $1 AND id = $2",
        tenant_id, invoice_id
    )
    .fetch_one(pool)
    .await?;

    let quantity = dto.quantity.as_ref().map(|q| q.clone()).unwrap_or_else(|| BigDecimal::from(1));
    let price_unit = dto.price_unit.as_ref().map(|p| p.clone()).unwrap_or_else(|| BigDecimal::from(0));
    let discount = dto.discount.as_ref().map(|d| d.clone()).unwrap_or_else(|| BigDecimal::from(0));
    let discount_factor = BigDecimal::from(1) - (discount / BigDecimal::from(100));
    let price_subtotal = &quantity * &price_unit * &discount_factor;
    let price_total = price_subtotal.clone();

    sqlx::query!(
        r#"
        INSERT INTO account_move_line (
            tenant_id, id, move_id, currency_id,
            product_id, product_uom_id, quantity, price_unit, discount,
            name, sequence, display_type,
            account_id,
            price_subtotal, price_total,
            debit, credit, balance, amount_currency,
            exclude_from_invoice_tab
        ) VALUES (
            $1, $2, $3, $4,
            $5, $6, $7, $8, $9,
            $10, $11, $12,
            $13,
            $14, $15,
            0, 0, 0, 0,
            false
        )
        "#,
        tenant_id, line_id, invoice_id, invoice.currency_id,
        dto.product_id, dto.product_uom_id, dto.quantity, dto.price_unit, dto.discount,
        dto.name.as_deref(), dto.sequence, dto.display_type.as_deref(),
        dto.account_id,
        price_subtotal, price_total
    )
    .execute(pool)
    .await?;

    // Create tax relations
    for tax_id in &dto.tax_ids {
        sqlx::query!(
            r#"
            INSERT INTO account_move_line_tax_rel (tenant_id, move_line_id, tax_id)
            VALUES ($1, $2, $3)
            ON CONFLICT DO NOTHING
            "#,
            tenant_id, line_id, tax_id
        )
        .execute(pool)
        .await?;
    }

    // Recalculate totals
    recalculate_invoice_totals(pool, tenant_id, invoice_id).await?;

    Ok(line_id)
}

/// Update invoice line
pub async fn update_invoice_line(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    invoice_id: Uuid,
    line_id: Uuid,
    dto: UpdateInvoiceLineDto,
) -> Result<(), sqlx::Error> {
    // Simplified update - in production, build dynamic query
    if let Some(ref quantity) = dto.quantity {
        sqlx::query!(
            "UPDATE account_move_line SET quantity = $1 WHERE tenant_id = $2 AND id = $3 AND move_id = $4",
            quantity, tenant_id, line_id, invoice_id
        )
        .execute(pool)
        .await?;
    }

    if let Some(ref price_unit) = dto.price_unit {
        sqlx::query!(
            "UPDATE account_move_line SET price_unit = $1 WHERE tenant_id = $2 AND id = $3 AND move_id = $4",
            price_unit, tenant_id, line_id, invoice_id
        )
        .execute(pool)
        .await?;
    }

    if let Some(name) = dto.name {
        sqlx::query!(
            "UPDATE account_move_line SET name = $1 WHERE tenant_id = $2 AND id = $3 AND move_id = $4",
            name, tenant_id, line_id, invoice_id
        )
        .execute(pool)
        .await?;
    }

    // Recalculate totals
    recalculate_invoice_totals(pool, tenant_id, invoice_id).await?;

    Ok(())
}

/// Delete invoice line
pub async fn delete_invoice_line(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    invoice_id: Uuid,
    line_id: Uuid,
) -> Result<(), sqlx::Error> {
    sqlx::query!(
        r#"
        DELETE FROM account_move_line
        WHERE tenant_id = $1 AND id = $2 AND move_id = $3
        "#,
        tenant_id, line_id, invoice_id
    )
    .execute(pool)
    .await?;

    // Recalculate totals
    recalculate_invoice_totals(pool, tenant_id, invoice_id).await?;

    Ok(())
}

/// Recalculate invoice totals
async fn recalculate_invoice_totals(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    invoice_id: Uuid,
) -> Result<(), sqlx::Error> {
    // Calculate totals from lines (simplified)
    let totals = sqlx::query!(
        r#"
        SELECT 
            COALESCE(SUM(price_subtotal), 0)::numeric as amount_untaxed,
            COALESCE(SUM(price_total - price_subtotal), 0)::numeric as amount_tax,
            COALESCE(SUM(price_total), 0)::numeric as amount_total
        FROM account_move_line
        WHERE tenant_id = $1 AND move_id = $2 
            AND (display_type IS NULL OR display_type NOT IN ('line_section', 'line_subsection', 'line_note'))
        "#,
        tenant_id, invoice_id
    )
    .fetch_one(pool)
    .await?;

    sqlx::query!(
        r#"
        UPDATE account_move
        SET 
            amount_untaxed = $1,
            amount_tax = $2,
            amount_total = $3,
            amount_residual = $3,
            amount_untaxed_signed = $1,
            amount_tax_signed = $2,
            amount_total_signed = $3,
            amount_residual_signed = $3,
            updated_at = now()
        WHERE tenant_id = $4 AND id = $5
        "#,
        totals.amount_untaxed, totals.amount_tax, totals.amount_total,
        tenant_id, invoice_id
    )
    .execute(pool)
    .await?;

    Ok(())
}

