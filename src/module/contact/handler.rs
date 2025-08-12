use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    Json,
};
use std::sync::Arc;
use serde_json::json;
use uuid::Uuid;

use crate::core::auth::AuthUser;
use crate::core::state::AppState;

use super::{
    command,
    query,
    // Dto dùng để parse request (Query/Json)
    dto::{CreateContactInput, UpdateContactInput, ListFilter as DtoListFilter},
    metadata::contact_form_schema,
};

pub async fn get_metadata() -> Json<serde_json::Value> {
    Json(contact_form_schema())
}

pub async fn create_contact(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Json(input): Json<CreateContactInput>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let dto = command::CreateContactDto {
        is_company: input.is_company,
        parent_id: input.parent_id,
        // name trong input là String -> bọc Some(...)
        name: Some(input.name),
        display_name: input.display_name,
        email: input.email,
        phone: input.phone,
        mobile: input.mobile,
        website: input.website,
        street: input.street,
        street2: input.street2,
        city: input.city,
        state: input.state,
        zip: input.zip,
        country_code: input.country_code,
        notes: input.notes,
        tags: input.tags,
    };

    let id = command::create_contact(pool, auth.tenant_id, dto)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(json!({ "id": id })))
}

pub async fn update_contact(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
    Json(input): Json<UpdateContactInput>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let dto = command::UpdateContactDto {
        is_company: input.is_company,
        parent_id: input.parent_id,
        name: input.name,
        display_name: input.display_name,
        email: input.email,
        phone: input.phone,
        mobile: input.mobile,
        website: input.website,
        street: input.street,
        street2: input.street2,
        city: input.city,
        state: input.state,
        zip: input.zip,
        country_code: input.country_code,
        notes: input.notes,
        tags: input.tags,
    };

    command::update_contact(pool, auth.tenant_id, id, dto)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(json!({ "id": id, "ok": true })))
}

pub async fn delete_contact(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<StatusCode, StatusCode> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
    command::delete_contact(pool, auth.tenant_id, id)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    Ok(StatusCode::NO_CONTENT)
}

pub async fn get_contact_by_id(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
    let c = query::get_contact_by_id(pool, auth.tenant_id, id)
        .await
        .map_err(|_| StatusCode::NOT_FOUND)?;
    Ok(Json(serde_json::to_value(c).unwrap()))
}

pub async fn list_contacts(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Query(f): Query<DtoListFilter>,
) -> Result<Json<Vec<query::ContactListItem>>, StatusCode> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let items = query::list_contacts(
        pool,
        auth.tenant_id,
        query::ListFilter {
            q: f.q,
            is_company: f.is_company,
            limit: f.limit,
            offset: f.offset,
        },
    )
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    // Trả mảng phẳng cho FE (giống loan)
    Ok(Json(items))
}
