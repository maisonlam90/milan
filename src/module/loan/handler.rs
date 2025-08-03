use axum::{
    extract::State,
    Json,
    http::StatusCode,
};
use std::sync::Arc;
use serde_json::json;
use crate::core::auth::AuthUser;
use crate::core::state::AppState;
use crate::module::loan::{
    metadata::loan_form_schema,
    dto::CreateContractInput,
    command,  // không import trực tiếp hàm để tránh trùng tên
    query,
};

/// ✅ Trả về metadata cho DynamicForm (public)
pub async fn get_metadata() -> Result<Json<serde_json::Value>, StatusCode> {
    Ok(Json(loan_form_schema()))
}

/// ✅ Tạo hợp đồng vay mới (cần JWT)
pub async fn create_contract(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Json(input): Json<CreateContractInput>
) -> Result<Json<serde_json::Value>, StatusCode> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let contract = command::create_contract(pool, auth.tenant_id, input)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(serde_json::json!({
        "contract_id": contract.id
    })))
}

/// ✅ Danh sách hợp đồng vay (cần JWT)
pub async fn list_contracts(
    State(state): State<Arc<AppState>>,
    auth: AuthUser
) -> Result<Json<serde_json::Value>, StatusCode> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let contracts = query::list_contracts(&pool, auth.tenant_id)
        .await
        .map_err(|e| {
            eprintln!("❌ Lỗi query list_contracts: {:?}", e);
            StatusCode::INTERNAL_SERVER_ERROR
        })?;

    // Chuyển dữ liệu sang JSON đúng format cho DynamicList
    let data: Vec<_> = contracts.into_iter().map(|c| {
        json!({
            "name": c.name,
            "principal": c.principal,
            "interest_rate": c.interest_rate,
            "term_months": c.term_months,
            "date_start": c.date_start.format("%d-%m-%Y").to_string(),
            "date_end": c.date_end.map(|d| d.format("%d-%m-%Y").to_string()).unwrap_or_default(),
            "state": c.state
        })
    }).collect();

    Ok(Json(json!(data)))
}