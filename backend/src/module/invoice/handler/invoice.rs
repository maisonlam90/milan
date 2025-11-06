use axum::{extract::{Path, Query, State}, Json, http::StatusCode};
use uuid::Uuid;
use std::sync::Arc;
use tracing::error;

use crate::core::state::AppState;
use crate::core::auth::AuthUser;
use crate::core::error::{AppError, ErrorResponse};
use crate::module::invoice::{
    dto::{
        CreateInvoiceRequest, UpdateInvoiceRequest, PostInvoiceRequest,
        InvoiceResponse, InvoiceListQuery, PaginatedResponse
    },
    model::AccountMove,
    command,
    query,
};

// ============================================================
// METADATA
// ============================================================

pub async fn get_metadata() -> Result<Json<serde_json::Value>, StatusCode> {
    let metadata = serde_json::json!({
        "move_types": [
            {"value": "out_invoice", "label": "Customer Invoice"},
            {"value": "in_invoice", "label": "Vendor Bill"},
            {"value": "out_refund", "label": "Customer Credit Note"},
            {"value": "in_refund", "label": "Vendor Credit Note"},
            {"value": "entry", "label": "Journal Entry"}
        ],
        "states": [
            {"value": "draft", "label": "Draft"},
            {"value": "posted", "label": "Posted"},
            {"value": "cancel", "label": "Cancelled"}
        ],
        "payment_states": [
            {"value": "not_paid", "label": "Not Paid"},
            {"value": "in_payment", "label": "In Payment"},
            {"value": "paid", "label": "Paid"},
            {"value": "partial", "label": "Partially Paid"},
            {"value": "reversed", "label": "Reversed"},
            {"value": "invoicing_legacy", "label": "Legacy"}
        ]
    });
    
    Ok(Json(metadata))
}

// ============================================================
// CRUD OPERATIONS
// ============================================================

pub async fn create_invoice(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Json(payload): Json<CreateInvoiceRequest>,
) -> Result<Json<InvoiceResponse>, AppError> {
    // 1. Validate input
    if payload.lines.is_empty() {
        return Err(AppError::Validation(ErrorResponse {
            code: "lines_empty",
            message: "Hóa đơn phải có ít nhất 1 dòng".into(),
        }));
    }

    if payload.move_type.is_empty() {
        return Err(AppError::Validation(ErrorResponse {
            code: "move_type_invalid",
            message: "Loại hóa đơn không hợp lệ".into(),
        }));
    }

    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
    let created_by = auth.user_id;

    // 2. Call command to create invoice
    let invoice = command::create_invoice(
        pool,
        auth.tenant_id,
        created_by,
        payload,
    )
    .await?;

    // 3. Return response
    Ok(Json(invoice))
}

pub async fn list_invoices(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Query(params): Query<InvoiceListQuery>,
) -> Result<Json<PaginatedResponse<InvoiceResponse>>, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let page = params.page.unwrap_or(1).max(1);
    let limit = params.limit.unwrap_or(10).min(100);
    let offset = (page - 1) * limit;

    // ✅ FIX: Clone params before using multiple times
    let params_clone = params.clone();

    let invoices = query::list_invoices(
        pool,
        auth.tenant_id,
        offset,
        limit,
        params.move_type,
        params.state,
        params.payment_state,
        params.partner_id,
        params.date_from,
        params.date_to,
        params.search,
    )
    .await?;

    let total = query::count_invoices(
        pool,
        auth.tenant_id,
        params_clone.move_type,
        params_clone.state,
        params_clone.payment_state,
        params_clone.partner_id,
        params_clone.date_from,
        params_clone.date_to,
        params_clone.search,
    )
    .await?;

    let total_pages = (total + limit as i64 - 1) / limit as i64;

    Ok(Json(PaginatedResponse {
        data: invoices,
        total,
        page,
        limit,
        total_pages: total_pages as i32,
    }))
}

pub async fn get_invoice_by_id(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<Json<InvoiceResponse>, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let invoice = query::get_invoice_by_id(pool, auth.tenant_id, id)
        .await?;

    Ok(Json(invoice))
}

pub async fn update_invoice(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<UpdateInvoiceRequest>,
) -> Result<Json<InvoiceResponse>, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    // ✅ Verify invoice exists and is in draft state
    let invoice = query::get_invoice_by_id(pool, auth.tenant_id, id).await?;

    if invoice.state != "draft" {
        return Err(AppError::Validation(ErrorResponse {
            code: "invoice_not_draft",
            message: "Chỉ có thể chỉnh sửa hóa đơn ở trạng thái Nháp".into(),
        }));
    }

    let updated = command::update_invoice(pool, auth.tenant_id, id, payload).await?;

    Ok(Json(updated))
}

pub async fn delete_invoice(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let invoice = query::get_invoice_by_id(pool, auth.tenant_id, id).await?;

    if invoice.state != "draft" {
        return Err(AppError::Validation(ErrorResponse {
            code: "invoice_not_draft",
            message: "Chỉ có thể xóa hóa đơn ở trạng thái Nháp".into(),
        }));
    }

    command::delete_invoice(pool, auth.tenant_id, id).await?;

    Ok(StatusCode::NO_CONTENT)
}

// ============================================================
// WORKFLOW ACTIONS
// ============================================================

pub async fn post_invoice(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(payload): Json<PostInvoiceRequest>,
) -> Result<Json<InvoiceResponse>, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let invoice = query::get_invoice_by_id(pool, auth.tenant_id, id).await?;

    if invoice.state != "draft" {
        return Err(AppError::Validation(ErrorResponse {
            code: "invoice_not_draft",
            message: "Chỉ có thể đăng hóa đơn ở trạng thái Nháp".into(),
        }));
    }

    let updated = command::post_invoice(pool, auth.tenant_id, id, payload).await?;

    Ok(Json(updated))
}

pub async fn reset_to_draft(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<Json<InvoiceResponse>, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let invoice = query::get_invoice_by_id(pool, auth.tenant_id, id).await?;

    if invoice.state == "draft" {
        return Err(AppError::Validation(ErrorResponse {
            code: "already_draft",
            message: "Hóa đơn đã ở trạng thái Nháp".into(),
        }));
    }

    let updated = command::reset_to_draft(pool, auth.tenant_id, id).await?;

    Ok(Json(updated))
}

pub async fn cancel_invoice(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<Json<InvoiceResponse>, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let invoice = query::get_invoice_by_id(pool, auth.tenant_id, id).await?;

    if invoice.state == "cancel" {
        return Err(AppError::Validation(ErrorResponse {
            code: "already_cancelled",
            message: "Hóa đơn đã bị hủy".into(),
        }));
    }

    let updated = command::cancel_invoice(pool, auth.tenant_id, id).await?;

    Ok(Json(updated))
}

pub async fn reverse_invoice(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<Json<InvoiceResponse>, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let invoice = query::get_invoice_by_id(pool, auth.tenant_id, id).await?;

    if invoice.state != "posted" {
        return Err(AppError::Validation(ErrorResponse {
            code: "invoice_not_posted",
            message: "Chỉ có thể đảo ngược hóa đơn ở trạng thái Đã đăng".into(),
        }));
    }

    let reversed = command::reverse_invoice(pool, auth.tenant_id, id).await?;

    Ok(Json(reversed))
}