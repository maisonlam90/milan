use axum::{
    extract::{Path, Query, State},
    http::{HeaderMap, StatusCode},
    response::IntoResponse,
    Json,
};
use serde_json::json;
use uuid::Uuid;
use std::sync::Arc;

use crate::core::{auth::AuthUser, state::AppState, error::AppError, i18n::I18n};

use super::{
    command,
    query,
    dto::{CreateContactInput, UpdateContactInput, ListFilter as DtoListFilter},
    metadata::contact_form_schema,
};

/// -------------------------
/// Helpers: normalize input
/// -------------------------
fn norm_opt_trim_lower(v: &Option<String>) -> Option<String> {
    v.as_ref()
        .map(|s| s.trim().to_lowercase())
        .filter(|s| !s.is_empty())
}

fn norm_opt_trim_upper2(v: &Option<String>) -> Option<String> {
    v.as_ref()
        .map(|s| s.trim().to_uppercase())
        .filter(|s| !s.is_empty())
        .map(|s| s.chars().take(2).collect::<String>())
}

fn norm_opt_digits(v: &Option<String>) -> Option<String> {
    v.as_ref()
        .map(|s| s.chars().filter(|c| c.is_ascii_digit()).collect::<String>())
        .filter(|s| !s.is_empty())
}

fn norm_opt_trim(v: &Option<String>) -> Option<String> {
    v.as_ref().map(|s| s.trim().to_string()).filter(|s| !s.is_empty())
}

/// -------------------------
/// Metadata
/// -------------------------
pub async fn get_metadata(headers: HeaderMap) -> Result<impl IntoResponse, AppError> {
    let i18n = I18n::from_headers(&headers);
    Ok(Json(contact_form_schema(&i18n)))
}

/// -------------------------
/// Create contact
/// -------------------------
pub async fn create_contact(
    State(state): State<Arc<AppState>>,
    auth: AuthUser, // dùng FromRequestParts đã có
    Json(input): Json<CreateContactInput>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    // ✅ Normalize ở BE để tránh 500 do CHECK
    let dto = command::CreateContactDto {
        is_company: input.is_company,
        parent_id: input.parent_id,
        name: Some(input.name.trim().to_string()),
        display_name: norm_opt_trim(&input.display_name),
        email:        norm_opt_trim_lower(&input.email),
        phone:        norm_opt_trim(&input.phone),
        mobile:       norm_opt_trim(&input.mobile),
        website:      norm_opt_trim(&input.website),
        street:       norm_opt_trim(&input.street),
        street2:      norm_opt_trim(&input.street2),
        city:         norm_opt_trim(&input.city),
        state:        norm_opt_trim(&input.state),
        zip:          norm_opt_trim(&input.zip),
        country_code: norm_opt_trim_upper2(&input.country_code),
        national_id:  norm_opt_digits(&input.national_id), 
        notes:        norm_opt_trim(&input.notes),
        tags:         input.tags, // tuỳ phần BE xử lý, giữ nguyên

        // IAM
        created_by:  auth.user_id,
        assignee_id: input.assignee_id,
        shared_with: input.shared_with.unwrap_or_default(),
    };

    let id = command::create_contact(pool, auth.tenant_id, dto)
        .await
        // create_contact không chắc trả sqlx::Error → không dùng AppError::from
        .map_err(|e| AppError::bad_request(e.to_string()))?;

    Ok(Json(json!({ "id": id })))
}

/// -------------------------
/// Update contact
/// -------------------------
pub async fn update_contact(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(input): Json<UpdateContactInput>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let dto = command::UpdateContactDto {
        is_company: input.is_company,
        parent_id:  input.parent_id,
        name:       input.name.map(|s| s.trim().to_string()),
        display_name: norm_opt_trim(&input.display_name),
        email:        norm_opt_trim_lower(&input.email),
        phone:        norm_opt_trim(&input.phone),
        mobile:       norm_opt_trim(&input.mobile),
        website:      norm_opt_trim(&input.website),
        street:       norm_opt_trim(&input.street),
        street2:      norm_opt_trim(&input.street2),
        city:         norm_opt_trim(&input.city),
        state:        norm_opt_trim(&input.state),
        zip:          norm_opt_trim(&input.zip),
        country_code: norm_opt_trim_upper2(&input.country_code),
        national_id:  norm_opt_digits(&input.national_id), 
        notes:        norm_opt_trim(&input.notes),
        tags:         input.tags,
    };

    command::update_contact(pool, auth.tenant_id, id, dto)
        .await
        .map_err(|e| AppError::bad_request(e.to_string()))?;

    Ok(Json(json!({ "id": id, "ok": true })))
}

/// -------------------------
/// Delete contact
/// -------------------------
pub async fn delete_contact(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    command::delete_contact(pool, auth.tenant_id, id)
        .await
        .map_err(|e| AppError::bad_request(e.to_string()))?;

    Ok(StatusCode::NO_CONTENT)
}

/// -------------------------
/// Get by id
/// -------------------------
pub async fn get_contact_by_id(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let c = query::get_contact_by_id(pool, auth.tenant_id, id)
        .await
        // hàm query thường trả sqlx::Error → dùng From
        .map_err(AppError::from)?;

    Ok(Json(serde_json::to_value(c).unwrap()))
}

/// -------------------------
/// List contacts
/// -------------------------
pub async fn list_contacts(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Query(f): Query<DtoListFilter>,
) -> Result<impl IntoResponse, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let items = query::list_contacts(
        pool,
        auth.tenant_id,
        query::ListFilter {
            q:         f.q,
            is_company: f.is_company,
            limit:     f.limit,
            offset:    f.offset,
        },
    )
    .await
    .map_err(AppError::from)?;

    Ok(Json(items))
}
