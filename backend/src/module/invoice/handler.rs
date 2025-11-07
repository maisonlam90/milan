use axum::{
    extract::{Path, Query, State},
    response::IntoResponse,
    Json,
};
use axum::http::StatusCode;
use serde_json::json;
use uuid::Uuid;
use std::sync::Arc;

use crate::core::{auth::AuthUser, state::AppState, error::AppError};

use super::{
    command,
    query,
    dto::{
        CreateInvoiceInput, UpdateInvoiceInput, CreateInvoiceLineInput, UpdateInvoiceLineInput,
        ListInvoiceFilter,
    },
    metadata::invoice_form_schema,
};

/// -------------------------
/// Metadata
/// -------------------------
pub async fn get_metadata() -> Result<impl IntoResponse, AppError> {
    Ok(Json(invoice_form_schema()))
}

/// -------------------------
/// Create invoice
/// -------------------------
pub async fn create_invoice(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Json(input): Json<CreateInvoiceInput>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let dto = command::CreateInvoiceDto {
        journal_id: input.journal_id,
        currency_id: input.currency_id,
        date: input.date,
        partner_id: input.partner_id,
        commercial_partner_id: input.commercial_partner_id,
        partner_shipping_id: input.partner_shipping_id,
        partner_bank_id: input.partner_bank_id,
        invoice_date: input.invoice_date,
        invoice_date_due: input.invoice_date_due,
        invoice_origin: input.invoice_origin,
        invoice_payment_term_id: input.invoice_payment_term_id,
        invoice_user_id: input.invoice_user_id,
        invoice_incoterm_id: input.invoice_incoterm_id,
        fiscal_position_id: input.fiscal_position_id,
        narration: input.narration,
        invoice_lines: input.invoice_lines.into_iter().map(|line| command::CreateInvoiceLineDto {
            product_id: line.product_id,
            product_uom_id: line.product_uom_id,
            name: line.name,
            quantity: line.quantity,
            price_unit: line.price_unit,
            discount: line.discount,
            account_id: line.account_id,
            tax_ids: line.tax_ids.unwrap_or_default(),
            display_type: line.display_type,
            sequence: line.sequence,
            analytic_distribution: line.analytic_distribution,
        }).collect(),
        created_by: auth.user_id,
        assignee_id: input.assignee_id,
        shared_with: input.shared_with.unwrap_or_default(),
    };

    let id = command::create_invoice(pool, auth.tenant_id, dto)
        .await
        .map_err(|e| AppError::bad_request(e.to_string()))?;

    Ok(Json(json!({ "id": id })))
}

/// -------------------------
/// List invoices
/// -------------------------
pub async fn list_invoices(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Query(filter): Query<ListInvoiceFilter>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let invoices = query::list_invoices(pool, auth.tenant_id, filter)
        .await
        .map_err(|e| AppError::internal(e.to_string()))?;

    Ok(Json(json!({ "items": invoices })))
}

/// -------------------------
/// Get invoice by ID
/// -------------------------
pub async fn get_invoice_by_id(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let invoice = query::get_invoice_by_id(pool, auth.tenant_id, id)
        .await
        .map_err(|e| AppError::internal(e.to_string()))?;

    match invoice {
        Some(inv) => Ok(Json(inv)),
        None => Err(AppError::not_found("Invoice not found")),
    }
}

/// -------------------------
/// Update invoice
/// -------------------------
pub async fn update_invoice(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(input): Json<UpdateInvoiceInput>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let dto = command::UpdateInvoiceDto {
        journal_id: input.journal_id,
        currency_id: input.currency_id,
        date: input.date,
        partner_id: input.partner_id,
        commercial_partner_id: input.commercial_partner_id,
        partner_shipping_id: input.partner_shipping_id,
        partner_bank_id: input.partner_bank_id,
        invoice_date: input.invoice_date,
        invoice_date_due: input.invoice_date_due,
        invoice_origin: input.invoice_origin,
        invoice_payment_term_id: input.invoice_payment_term_id,
        invoice_user_id: input.invoice_user_id,
        invoice_incoterm_id: input.invoice_incoterm_id,
        fiscal_position_id: input.fiscal_position_id,
        narration: input.narration,
        assignee_id: input.assignee_id,
        shared_with: input.shared_with,
    };

    command::update_invoice(pool, auth.tenant_id, id, dto)
        .await
        .map_err(|e| AppError::bad_request(e.to_string()))?;

    Ok(StatusCode::NO_CONTENT)
}

/// -------------------------
/// Confirm invoice (Post)
/// -------------------------
pub async fn confirm_invoice(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    command::confirm_invoice(pool, auth.tenant_id, id, auth.user_id)
        .await
        .map_err(|e| AppError::bad_request(e.to_string()))?;

    Ok(StatusCode::NO_CONTENT)
}

/// -------------------------
/// Cancel invoice
/// -------------------------
pub async fn cancel_invoice(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    command::cancel_invoice(pool, auth.tenant_id, id)
        .await
        .map_err(|e| AppError::bad_request(e.to_string()))?;

    Ok(StatusCode::NO_CONTENT)
}

/// -------------------------
/// Delete invoice
/// -------------------------
pub async fn delete_invoice(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    command::delete_invoice(pool, auth.tenant_id, id)
        .await
        .map_err(|e| AppError::bad_request(e.to_string()))?;

    Ok(StatusCode::NO_CONTENT)
}

/// -------------------------
/// Add invoice line
/// -------------------------
pub async fn add_invoice_line(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(input): Json<CreateInvoiceLineInput>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let dto = command::CreateInvoiceLineDto {
        product_id: input.product_id,
        product_uom_id: input.product_uom_id,
        name: input.name,
        quantity: input.quantity,
        price_unit: input.price_unit,
        discount: input.discount,
        account_id: input.account_id,
        tax_ids: input.tax_ids.unwrap_or_default(),
        display_type: input.display_type,
        sequence: input.sequence,
        analytic_distribution: input.analytic_distribution,
    };

    let line_id = command::add_invoice_line(pool, auth.tenant_id, id, dto)
        .await
        .map_err(|e| AppError::bad_request(e.to_string()))?;

    Ok(Json(json!({ "id": line_id })))
}

/// -------------------------
/// Update invoice line
/// -------------------------
pub async fn update_invoice_line(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path((id, line_id)): Path<(Uuid, Uuid)>,
    Json(input): Json<UpdateInvoiceLineInput>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let dto = command::UpdateInvoiceLineDto {
        product_id: input.product_id,
        product_uom_id: input.product_uom_id,
        name: input.name,
        quantity: input.quantity,
        price_unit: input.price_unit,
        discount: input.discount,
        account_id: input.account_id,
        tax_ids: input.tax_ids,
        display_type: input.display_type,
        sequence: input.sequence,
        analytic_distribution: input.analytic_distribution,
    };

    command::update_invoice_line(pool, auth.tenant_id, id, line_id, dto)
        .await
        .map_err(|e| AppError::bad_request(e.to_string()))?;

    Ok(StatusCode::NO_CONTENT)
}

/// -------------------------
/// Delete invoice line
/// -------------------------
pub async fn delete_invoice_line(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path((id, line_id)): Path<(Uuid, Uuid)>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    command::delete_invoice_line(pool, auth.tenant_id, id, line_id)
        .await
        .map_err(|e| AppError::bad_request(e.to_string()))?;

    Ok(StatusCode::NO_CONTENT)
}

