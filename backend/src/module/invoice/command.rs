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
    pub tax_rate: Option<BigDecimal>,        // Tax rate (%) - for simple calculation
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
    pub invoice_lines: Option<Vec<UpdateInvoiceLineDto>>,
}

#[derive(Debug)]
pub struct UpdateInvoiceLineDto {
    pub id: Option<Uuid>, // ID của line nếu đã tồn tại
    pub product_id: Option<Uuid>,
    pub product_uom_id: Option<Uuid>,
    pub name: Option<String>,
    pub quantity: Option<BigDecimal>,
    pub price_unit: Option<BigDecimal>,
    pub discount: Option<BigDecimal>,
    pub account_id: Option<Uuid>,
    pub tax_rate: Option<BigDecimal>, // Tax rate (%) - for simple calculation
    pub tax_ids: Option<Vec<Uuid>>,
    pub display_type: Option<String>,
    pub sequence: Option<i32>,
    pub analytic_distribution: Option<Value>,
}

/// Get or create default journal for tenant
async fn get_or_create_default_journal(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    user_id: Uuid,
) -> Result<Uuid, sqlx::Error> {
    // Try to get existing sale journal
    let journal = sqlx::query!(
        r#"
        SELECT id FROM account_journal
        WHERE tenant_id = $1 AND type = 'sale' AND active = TRUE
        ORDER BY sequence, created_at
        LIMIT 1
        "#,
        tenant_id
    )
    .fetch_optional(pool)
    .await?;

    if let Some(j) = journal {
        return Ok(j.id);
    }

    // Create default sale journal if not exists
    // Try to insert, if conflict (code already exists), get the existing one
    let journal_id = Uuid::new_v4();
    let _ = sqlx::query!(
        r#"
        INSERT INTO account_journal (
            tenant_id, id, name, code, type, active, created_by
        ) VALUES (
            $1, $2, 'Sales', 'SALE', 'sale', TRUE, $3
        )
        ON CONFLICT (tenant_id, code) DO NOTHING
        "#,
        tenant_id, journal_id, user_id
    )
    .execute(pool)
    .await;

    // Get the journal (either newly created or existing)
    let existing = sqlx::query!(
        r#"
        SELECT id FROM account_journal
        WHERE tenant_id = $1 AND code = 'SALE'
        LIMIT 1
        "#,
        tenant_id
    )
    .fetch_one(pool)
    .await?;
    
    Ok(existing.id)
}

/// Get default currency ID (for now, use a fixed UUID - can be improved later)
fn get_default_currency_id() -> Uuid {
    // TODO: Get from tenant settings or currency table
    // For now, use a fixed UUID that represents USD
    Uuid::parse_str("00000000-0000-0000-0000-000000000001").unwrap()
}

/// Get or create default account for revenue (for invoice lines)
async fn get_or_create_default_revenue_account(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    user_id: Uuid,
) -> Result<Uuid, sqlx::Error> {
    // Try to get existing revenue account
    let account = sqlx::query!(
        r#"
        SELECT id FROM account_account
        WHERE tenant_id = $1 AND account_type = 'income' AND deprecated = FALSE
        ORDER BY code, created_at
        LIMIT 1
        "#,
        tenant_id
    )
    .fetch_optional(pool)
    .await?;

    if let Some(acc) = account {
        return Ok(acc.id);
    }

    // Create default revenue account if not exists
    let account_id = Uuid::new_v4();
    let _ = sqlx::query!(
        r#"
        INSERT INTO account_account (
            tenant_id, id, code, name, account_type, internal_group, created_by
        ) VALUES (
            $1, $2, '400000', 'Product Sales', 'income', 'income', $3
        )
        ON CONFLICT (tenant_id, code) DO NOTHING
        "#,
        tenant_id, account_id, user_id
    )
    .execute(pool)
    .await;

    // Get the account (either newly created or existing)
    let existing = sqlx::query!(
        r#"
        SELECT id FROM account_account
        WHERE tenant_id = $1 AND code = '400000'
        LIMIT 1
        "#,
        tenant_id
    )
    .fetch_one(pool)
    .await?;
    
    Ok(existing.id)
}

/// Create a new invoice
pub async fn create_invoice(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    dto: CreateInvoiceDto,
) -> Result<Uuid, sqlx::Error> {
    let invoice_id = Uuid::new_v4();
    
    // Get or create default journal (use from DTO if provided, otherwise get/create default)
    let journal_id = if dto.journal_id != Uuid::nil() {
        dto.journal_id
    } else {
        get_or_create_default_journal(pool, tenant_id, dto.created_by).await?
    };
    
    // Get currency (use from DTO if provided, otherwise use default)
    let currency_id = if dto.currency_id != Uuid::nil() {
        dto.currency_id
    } else {
        get_default_currency_id()
    };
    
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
        tenant_id, invoice_id, invoice_name, dto.date, journal_id, currency_id,
        dto.partner_id, dto.commercial_partner_id, dto.partner_shipping_id, dto.partner_bank_id,
        dto.invoice_date, dto.invoice_date_due, dto.invoice_origin,
        dto.invoice_payment_term_id, dto.invoice_user_id, dto.invoice_incoterm_id, dto.fiscal_position_id,
        dto.narration,
        dto.created_by, dto.assignee_id, &dto.shared_with
    )
    .execute(pool)
    .await?;

    // Get default account for invoice lines (if needed)
    let default_account_id = get_or_create_default_revenue_account(pool, tenant_id, dto.created_by).await?;

    // Create invoice lines
    for (idx, line) in dto.invoice_lines.iter().enumerate() {
        let line_id = Uuid::new_v4();
        let sequence = line.sequence.unwrap_or((idx * 10) as i32);
        
        // Use account_id from line, or default account if not provided (and not a section/note)
        let account_id = if line.display_type.is_some() {
            None // Section/note lines don't need account
        } else {
            Some(line.account_id.unwrap_or(default_account_id))
        };
        
        // Calculate amounts (simplified)
        let quantity = line.quantity.as_ref().map(|q| q.clone()).unwrap_or_else(|| BigDecimal::from(1));
        let price_unit = line.price_unit.as_ref().map(|p| p.clone()).unwrap_or_else(|| BigDecimal::from(0));
        let discount = line.discount.as_ref().map(|d| d.clone()).unwrap_or_else(|| BigDecimal::from(0));
        let discount_factor = BigDecimal::from(1) - (discount / BigDecimal::from(100));
        let price_subtotal = &quantity * &price_unit * &discount_factor;
        
        // Calculate tax from tax_rate if provided
        let price_total = if let Some(tax_rate) = line.tax_rate.as_ref() {
            let tax_rate_decimal = tax_rate / BigDecimal::from(100);
            let tax_amount = &price_subtotal * tax_rate_decimal;
            &price_subtotal + &tax_amount
        } else {
            price_subtotal.clone()
        };
        
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
            tenant_id, line_id, invoice_id, currency_id,
            line.product_id, line.product_uom_id, line.quantity, line.price_unit, line.discount,
            line.name.as_deref(), sequence, line.display_type.as_deref(),
            account_id,
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

    if let Some(ref val) = dto.invoice_payment_term_id {
        if has_updates {
            query.push(", ");
        }
        query.push("invoice_payment_term_id = ");
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

    // Always update updated_at if there are any changes or if invoice_lines need to be synced
    if has_updates || dto.invoice_lines.is_some() {
        if has_updates {
            query.push(", updated_at = now()");
        } else {
            query.push("updated_at = now()");
        }
        query.push(" WHERE tenant_id = ");
        query.push_bind(tenant_id);
        query.push(" AND id = ");
        query.push_bind(invoice_id);

        query.build().execute(pool).await?;
    }

    // Sync invoice lines if provided (always sync even if no other fields changed)
    if let Some(ref lines) = dto.invoice_lines {
        sync_invoice_lines(pool, tenant_id, invoice_id, lines).await?;
    }

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

/// Sync invoice lines (add/update/delete)
async fn sync_invoice_lines(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    invoice_id: Uuid,
    lines: &[UpdateInvoiceLineDto],
) -> Result<(), sqlx::Error> {
    // Get currency and default account from invoice
    let invoice = sqlx::query!(
        "SELECT currency_id FROM account_move WHERE tenant_id = $1 AND id = $2",
        tenant_id, invoice_id
    )
    .fetch_one(pool)
    .await?;

    let default_account_id = get_or_create_default_revenue_account(pool, tenant_id, Uuid::nil()).await?;

    // Get existing line IDs
    let existing_lines = sqlx::query!(
        "SELECT id FROM account_move_line WHERE tenant_id = $1 AND move_id = $2",
        tenant_id, invoice_id
    )
    .fetch_all(pool)
    .await?;

    let existing_ids: std::collections::HashSet<Uuid> = existing_lines.iter().map(|l| l.id).collect();
    let new_ids: std::collections::HashSet<Uuid> = lines.iter()
        .filter_map(|l| l.id)
        .collect();

    // Delete lines that are not in the new list
    for existing_id in &existing_ids {
        if !new_ids.contains(existing_id) {
            delete_invoice_line(pool, tenant_id, invoice_id, *existing_id).await?;
        }
    }

    // Process each line
    for (idx, line) in lines.iter().enumerate() {
        let sequence = line.sequence.unwrap_or((idx * 10) as i32);

        if let Some(line_id) = line.id {
            // Update existing line
            update_invoice_line_full(pool, tenant_id, invoice_id, line_id, line, invoice.currency_id, default_account_id).await?;
        } else {
            // Create new line
            let line_id = Uuid::new_v4();
            let quantity = line.quantity.as_ref().map(|q| q.clone()).unwrap_or_else(|| BigDecimal::from(1));
            let price_unit = line.price_unit.as_ref().map(|p| p.clone()).unwrap_or_else(|| BigDecimal::from(0));
            let discount = line.discount.as_ref().map(|d| d.clone()).unwrap_or_else(|| BigDecimal::from(0));
            let discount_factor = BigDecimal::from(1) - (discount / BigDecimal::from(100));
            let price_subtotal = &quantity * &price_unit * &discount_factor;

            // Calculate tax from tax_rate if provided
            let price_total = if let Some(tax_rate) = line.tax_rate.as_ref() {
                let tax_rate_decimal = tax_rate / BigDecimal::from(100);
                let tax_amount = &price_subtotal * tax_rate_decimal;
                &price_subtotal + &tax_amount
            } else {
                price_subtotal.clone()
            };

            let account_id = if line.display_type.is_some() {
                None
            } else {
                Some(line.account_id.unwrap_or(default_account_id))
            };

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
                line.product_id, line.product_uom_id, line.quantity, line.price_unit, line.discount,
                line.name.as_deref(), sequence, line.display_type.as_deref(),
                account_id,
                price_subtotal, price_total
            )
            .execute(pool)
            .await?;

            // Create tax relations
            if let Some(ref tax_ids) = line.tax_ids {
                for tax_id in tax_ids {
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
        }
    }

    // Recalculate totals
    recalculate_invoice_totals(pool, tenant_id, invoice_id).await?;

    Ok(())
}

/// Update invoice line (full update with all fields)
async fn update_invoice_line_full(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    invoice_id: Uuid,
    line_id: Uuid,
    dto: &UpdateInvoiceLineDto,
    currency_id: Uuid,
    default_account_id: Uuid,
) -> Result<(), sqlx::Error> {
    // Calculate amounts
    let quantity = dto.quantity.as_ref().map(|q| q.clone()).unwrap_or_else(|| BigDecimal::from(1));
    let price_unit = dto.price_unit.as_ref().map(|p| p.clone()).unwrap_or_else(|| BigDecimal::from(0));
    let discount = dto.discount.as_ref().map(|d| d.clone()).unwrap_or_else(|| BigDecimal::from(0));
    let discount_factor = BigDecimal::from(1) - (discount / BigDecimal::from(100));
    let price_subtotal = &quantity * &price_unit * &discount_factor;

    // Calculate tax from tax_rate if provided
    let price_total = if let Some(tax_rate) = dto.tax_rate.as_ref() {
        let tax_rate_decimal = tax_rate / BigDecimal::from(100);
        let tax_amount = &price_subtotal * tax_rate_decimal;
        &price_subtotal + &tax_amount
    } else {
        price_subtotal.clone()
    };

    let account_id = if dto.display_type.is_some() {
        None
    } else {
        Some(dto.account_id.unwrap_or(default_account_id))
    };

    // Update line
    sqlx::query!(
        r#"
        UPDATE account_move_line
        SET 
            product_id = $1,
            product_uom_id = $2,
            name = $3,
            quantity = $4,
            price_unit = $5,
            discount = $6,
            account_id = $7,
            price_subtotal = $8,
            price_total = $9,
            sequence = COALESCE($10, sequence),
            display_type = $11
        WHERE tenant_id = $12 AND id = $13 AND move_id = $14
        "#,
        dto.product_id, dto.product_uom_id, dto.name.as_deref(),
        dto.quantity, dto.price_unit, dto.discount,
        account_id, price_subtotal, price_total,
        dto.sequence, dto.display_type.as_deref(),
        tenant_id, line_id, invoice_id
    )
    .execute(pool)
    .await?;

    // Update tax relations - always delete existing first
    sqlx::query!(
        "DELETE FROM account_move_line_tax_rel WHERE tenant_id = $1 AND move_line_id = $2",
        tenant_id, line_id
    )
    .execute(pool)
    .await?;

    // Add new tax relations if provided
    if let Some(ref tax_ids) = dto.tax_ids {
        for tax_id in tax_ids {
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

    Ok(())
}

/// Update invoice line
pub async fn update_invoice_line(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    invoice_id: Uuid,
    line_id: Uuid,
    dto: UpdateInvoiceLineDto,
) -> Result<(), sqlx::Error> {
    // Get currency and default account from invoice
    let invoice = sqlx::query!(
        "SELECT currency_id FROM account_move WHERE tenant_id = $1 AND id = $2",
        tenant_id, invoice_id
    )
    .fetch_one(pool)
    .await?;

    let default_account_id = get_or_create_default_revenue_account(pool, tenant_id, Uuid::nil()).await?;

    update_invoice_line_full(pool, tenant_id, invoice_id, line_id, &dto, invoice.currency_id, default_account_id).await?;

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

