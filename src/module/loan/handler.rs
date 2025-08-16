use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use std::sync::Arc;
use serde_json::json;
use uuid::Uuid;
use tracing::error; // 👈 THÊM DÒNG NÀY

use crate::core::auth::AuthUser;
use crate::core::state::AppState;
use crate::module::loan::{
    calculator,
    command,
    dto::CreateContractInput,
    metadata::loan_form_schema,
    query,
};

pub async fn get_metadata() -> Result<Json<serde_json::Value>, StatusCode> {
    Ok(Json(loan_form_schema()))
}

pub async fn create_contract(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Json(input): Json<CreateContractInput>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    match command::create_contract(pool, auth.tenant_id, input).await {
        Ok(contract) => Ok(Json(json!({ "contract_id": contract.id }))),
        Err(e) => {
            error!("❌ Lỗi khi tạo hợp đồng vay: {:?}", e);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

pub async fn list_contracts(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let contracts = query::list_contracts(&pool, auth.tenant_id)
        .await
        .map_err(|e| {
            error!("❌ Lỗi query list_contracts: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    let data: Vec<_> = contracts
        .into_iter()
        .map(|c| {
            json!({
                "id": c.id,
                "name": c.name,
                "principal": c.principal,
                "interest_rate": c.interest_rate,
                "term_months": c.term_months,
                "date_start": c.date_start.format("%d-%m-%Y").to_string(),
                "date_end": c.date_end.map(|d| d.format("%d-%m-%Y").to_string()).unwrap_or_default(),
                "state": c.state
            })
        })
        .collect();

    Ok(Json(json!(data)))
}

pub async fn get_contract_by_id(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(contract_id): Path<Uuid>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let mut contract = query::get_contract_by_id(&pool, auth.tenant_id, contract_id)
        .await
        .map_err(|_| StatusCode::NOT_FOUND)?;

    let mut transactions = query::get_transactions_by_contract(&pool, auth.tenant_id, contract_id)
        .await
        .map_err(|e| {
            error!("❌ Lỗi get_transactions_by_contract: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    calculator::calculate_interest_fields(&mut contract, &mut transactions);

    let mut value = serde_json::to_value(contract).unwrap();
    value["transactions"] = serde_json::to_value(transactions).unwrap();

    Ok(Json(value))
}

pub async fn update_contract(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(contract_id): Path<Uuid>,
    Json(input): Json<CreateContractInput>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    command::update_contract(pool, auth.tenant_id, contract_id, input)
        .await
        .map_err(|e| {
            error!("❌ Lỗi update_contract: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    Ok(Json(json!({ "updated": true })))
}

pub async fn delete_contract(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(contract_id): Path<Uuid>,
) -> Result<StatusCode, StatusCode> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    command::delete_contract(&pool, auth.tenant_id, contract_id)
        .await
        .map_err(|e| {
            error!("❌ Lỗi delete_contract: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    Ok(StatusCode::NO_CONTENT)
}
