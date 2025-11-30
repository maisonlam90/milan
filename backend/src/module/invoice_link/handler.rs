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
    dto::{
        ProviderInfo, ProviderFormFieldsResponse, FormField,
        LinkProviderInput, LinkProviderResponse,
        SendInvoiceToProviderInput, SendInvoiceResponse,
        ListInvoiceLinkFilter,
    },
    model::InvoiceProvider,
};

/// Lấy danh sách providers có sẵn
pub async fn list_providers() -> Result<impl IntoResponse, AppError> {
    let providers = vec![
        ProviderInfo {
            code: "viettel".to_string(),
            name: "Viettel Invoice".to_string(),
            description: Some("Hệ thống hóa đơn điện tử Viettel".to_string()),
        },
        ProviderInfo {
            code: "mobifone".to_string(),
            name: "Mobifone Invoice".to_string(),
            description: Some("Hệ thống hóa đơn điện tử Mobifone".to_string()),
        },
    ];

    Ok(Json(json!({ "items": providers })))
}

/// Lấy form fields cho provider (để hiển thị form động)
pub async fn get_provider_form_fields(
    Path(provider_code): Path<String>,
) -> Result<impl IntoResponse, AppError> {
    let provider = InvoiceProvider::from_str(&provider_code)
        .ok_or_else(|| AppError::bad_request(format!("Provider '{}' not found", provider_code)))?;

    let fields = match provider {
        InvoiceProvider::Viettel => vec![
            FormField {
                name: "username".to_string(),
                label: "Tên đăng nhập".to_string(),
                field_type: "text".to_string(),
                required: true,
                placeholder: Some("Nhập username".to_string()),
                description: Some("Username đăng nhập Viettel Invoice".to_string()),
            },
            FormField {
                name: "password".to_string(),
                label: "Mật khẩu".to_string(),
                field_type: "password".to_string(),
                required: true,
                placeholder: Some("Nhập mật khẩu".to_string()),
                description: Some("Mật khẩu đăng nhập Viettel Invoice".to_string()),
            },
            FormField {
                name: "template_code".to_string(),
                label: "Mẫu hóa đơn".to_string(),
                field_type: "text".to_string(),
                required: true,
                placeholder: Some("Ví dụ: 1/3939".to_string()),
                description: Some("Mẫu hóa đơn theo quy định của Viettel".to_string()),
            },
            FormField {
                name: "invoice_series".to_string(),
                label: "Ký hiệu hóa đơn".to_string(),
                field_type: "text".to_string(),
                required: true,
                placeholder: Some("Ví dụ: K25MEL".to_string()),
                description: Some("Ký hiệu hóa đơn theo quy định của Viettel".to_string()),
            },
        ],
        InvoiceProvider::Mobifone => {
            // TODO: Thêm fields cho Mobifone khi có thông tin API
            vec![]
        }
    };

    Ok(Json(ProviderFormFieldsResponse {
        provider: provider_code,
        fields,
    }))
}

/// Link provider với tenant (lưu credentials)
#[axum::debug_handler]
pub async fn link_provider(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Json(input): Json<LinkProviderInput>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    match command::link_provider(pool, auth.tenant_id, auth.user_id, input.clone()).await {
        Ok(credential_id) => {
            Ok(Json(LinkProviderResponse {
                success: true,
                message: format!("Đã liên kết thành công với {}", input.provider),
                credential_id: Some(credential_id),
                provider: input.provider,
            }))
        }
        Err(e) => {
            Err(AppError::bad_request(format!("Không thể liên kết với provider: {}", e)))
        }
    }
}

/// Gửi hóa đơn đến provider
#[axum::debug_handler]
pub async fn send_invoice_to_provider(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Json(input): Json<SendInvoiceToProviderInput>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    match command::send_invoice_to_provider(pool, auth.tenant_id, auth.user_id, input.clone()).await {
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
                        provider_invoice_id: l.provider_invoice_id,
                        provider_invoice_number: l.provider_invoice_number,
                        message: if status == "linked" {
                            Some(format!("Hóa đơn đã được gửi thành công đến {}", input.provider))
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
                        provider_invoice_id: l.provider_invoice_id,
                        provider_invoice_number: l.provider_invoice_number,
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

/// Lấy danh sách credentials đã link
pub async fn list_provider_credentials(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let credentials = query::list_provider_credentials(pool, auth.tenant_id)
        .await
        .map_err(|e| AppError::internal(e.to_string()))?;

    Ok(Json(json!({ "items": credentials })))
}

