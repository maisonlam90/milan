use axum::{
    extract::{Path, State},
    http::{StatusCode, HeaderMap},
    Json,
};
use std::sync::Arc;
use serde_json::json;
use uuid::Uuid;
use tracing::error;

use crate::core::auth::AuthUser;
use crate::core::error::AppError;
use crate::core::state::AppState;
use crate::core::i18n::I18n;

use crate::module::loan::{
    calculator,
    command,
    dto::CreateContractInput,
    metadata::loan_form_schema,
    query,
};

pub async fn get_metadata(headers: HeaderMap) -> Result<Json<serde_json::Value>, StatusCode> {
    let i18n = I18n::from_headers(&headers);
    Ok(Json(loan_form_schema(&i18n)))
}

pub async fn create_contract(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    auth: AuthUser,
    Json(mut input): Json<CreateContractInput>,
) -> Result<Json<serde_json::Value>, AppError> {
    // ✅ validate sớm
    let i18n = I18n::from_headers(&headers);
    tracing::info!("🌐 Handler language: {}, message: {}", i18n.language(), i18n.t("error.loan.transactions_empty"));
    if input.transactions.is_empty() {
        return Err(AppError::bad_request_i18n(&i18n, "error.loan.transactions_empty"));
    }

    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    // 👇 IAM mặc định
    input.created_by = Some(auth.user_id);
    if input.assignee_id.is_none() {
        input.assignee_id = Some(auth.user_id);
    }
    input.shared_with.get_or_insert_with(|| vec![]);

    // 👇 tạo HĐ (contract_number tự sinh trong service)
    let contract = command::create_contract(pool, auth.tenant_id, input).await?;
    Ok(Json(json!({ "contract_id": contract.id })))
}

pub async fn list_contracts(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let contracts = query::list_contracts(pool, auth.tenant_id)
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
                "contract_number": c.contract_number,
                "current_principal": c.current_principal,
                "interest_rate": c.interest_rate,
                "term_months": c.term_months,
                "date_start": c.date_start.format("%Y-%m-%d").to_string(),
                "date_end": c.date_end.map(|d| d.format("%Y-%m-%d").to_string()).unwrap_or_default(),
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

    let mut contract = query::get_contract_by_id(pool, auth.tenant_id, contract_id)
        .await
        .map_err(|_| StatusCode::NOT_FOUND)?;

    let mut transactions = query::get_transactions_by_contract(pool, auth.tenant_id, contract_id)
        .await
        .map_err(|e| {
            error!("❌ Lỗi get_transactions_by_contract: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    // tính toán projection từ ledger
    calculator::calculate_interest_fields(&mut contract, &mut transactions);

    let mut value = serde_json::to_value(contract).unwrap();
    value["transactions"] = serde_json::to_value(transactions).unwrap();

    Ok(Json(value))
}

pub async fn update_contract(
    State(state): State<Arc<AppState>>,
    headers: HeaderMap,
    auth: AuthUser,
    Path(contract_id): Path<Uuid>,
    Json(input): Json<CreateContractInput>,
) -> Result<Json<serde_json::Value>, AppError> {
    // ✅ validate policy
    let i18n = I18n::from_headers(&headers);
    if input.transactions.is_empty() {
        return Err(AppError::bad_request_i18n(&i18n, "error.loan.transactions_empty"));
    }

    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    // contract_number immutable — logic nằm trong service
    command::update_contract(pool, auth.tenant_id, contract_id, input).await?;
    Ok(Json(json!({ "updated": true })))
}

pub async fn delete_contract(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(contract_id): Path<Uuid>,
) -> Result<StatusCode, StatusCode> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    command::delete_contract(pool, auth.tenant_id, contract_id)
        .await
        .map_err(|e| {
            error!("❌ Lỗi delete_contract: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    Ok(StatusCode::NO_CONTENT)
}