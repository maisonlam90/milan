use axum::{
    extract::{Path, Query, State},
    response::IntoResponse,
    Json,
};
use serde_json::json;
use uuid::Uuid;
use std::sync::Arc;

use crate::core::{auth::AuthUser, state::AppState, error::AppError};

use super::{
    command,
    query,
    dto::{SendInvoiceToMeinvoiceInput, SendInvoiceResponse, ListInvoiceLinkFilter, MeinvoiceLoginInput, MeinvoiceLoginResponse},
};

/// Gửi hóa đơn đến Meinvoice
#[axum::debug_handler]
pub async fn send_invoice_to_meinvoice(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Json(input): Json<SendInvoiceToMeinvoiceInput>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    match command::send_invoice_to_meinvoice(pool, auth.tenant_id, auth.user_id, input.clone()).await {
        Ok(link_id) => {
            // Lấy thông tin link vừa tạo
            let link = query::get_invoice_link_by_id(pool, auth.tenant_id, link_id)
                .await
                .map_err(|e| AppError::internal(e.to_string()))?;

            match link {
                Some(l) => {
                    let status = l.status.clone();
                    Ok(Json(SendInvoiceResponse {
                        link_id: l.id,
                        status: status.clone(),
                        meinvoice_invoice_id: l.meinvoice_invoice_id,
                        meinvoice_invoice_number: l.meinvoice_invoice_number,
                        message: if status == "success" {
                            Some("Hóa đơn đã được gửi thành công đến Meinvoice".to_string())
                        } else if status == "failed" {
                            l.error_message
                        } else {
                            Some("Đang xử lý...".to_string())
                        },
                    }))
                },
                None => Err(AppError::internal("Failed to retrieve invoice link")),
            }
        }
        Err(e) => {
            // Nếu có lỗi, vẫn trả về link_id nếu đã tạo được record
            if let Ok(link) = query::get_latest_invoice_link_by_invoice_id(
                pool,
                auth.tenant_id,
                input.invoice_id,
            )
            .await
            {
                if let Some(l) = link {
                    return Ok(Json(SendInvoiceResponse {
                        link_id: l.id,
                        status: l.status,
                        meinvoice_invoice_id: l.meinvoice_invoice_id,
                        meinvoice_invoice_number: l.meinvoice_invoice_number,
                        message: l.error_message,
                    }));
                }
            }
            Err(AppError::bad_request(format!("Failed to send invoice: {}", e)))
        }
    }
}

/// Lấy danh sách invoice links
pub async fn list_invoice_links(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Query(filter): Query<ListInvoiceLinkFilter>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let links = query::list_invoice_links(pool, auth.tenant_id, filter)
        .await
        .map_err(|e| AppError::internal(e.to_string()))?;

    Ok(Json(json!({ "items": links })))
}

/// Lấy invoice link theo ID
pub async fn get_invoice_link_by_id(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let link = query::get_invoice_link_by_id(pool, auth.tenant_id, id)
        .await
        .map_err(|e| AppError::internal(e.to_string()))?;

    match link {
        Some(l) => Ok(Json(l)),
        None => Err(AppError::not_found("Invoice link not found")),
    }
}

/// Lấy invoice link theo invoice_id (link mới nhất)
pub async fn get_invoice_link_by_invoice_id(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(invoice_id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let link = query::get_latest_invoice_link_by_invoice_id(pool, auth.tenant_id, invoice_id)
        .await
        .map_err(|e| AppError::internal(e.to_string()))?;

    match link {
        Some(l) => Ok(Json(l)),
        None => Err(AppError::not_found("Invoice link not found")),
    }
}

/// Đăng nhập vào Meinvoice
#[axum::debug_handler]
pub async fn login_meinvoice(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Json(input): Json<MeinvoiceLoginInput>,
) -> Result<impl IntoResponse, AppError> {
    // Validate credentials with Meinvoice API
    let api_url = input.api_url.clone()
        .or_else(|| std::env::var("MEINVOICE_API_URL").ok())
        .unwrap_or_else(|| "https://testapi.meinvoice.vn".to_string());

    // Try to login to Meinvoice
    match command::login_to_meinvoice(&api_url, &input.username, &input.password, &input.taxcode, &input.appid).await {
        Ok(token) => {
            // Save credentials to database (encrypted)
            let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
            command::save_meinvoice_credentials(pool, auth.tenant_id, auth.user_id, &input, &token)
                .await
                .map_err(|e| AppError::internal(format!("Failed to save credentials: {}", e)))?;

            Ok(Json(MeinvoiceLoginResponse {
                success: true,
                message: "Đăng nhập thành công".to_string(),
                token: Some(token),
            }))
        }
        Err(e) => {
            Err(AppError::bad_request(format!("Đăng nhập thất bại: {}", e)))
        }
    }
}

