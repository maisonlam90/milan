use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use axum::Extension;
use axum::extract::Query;
use std::sync::Arc;
use serde_json::json;
use uuid::Uuid;
use tracing::error;
use bigdecimal::ToPrimitive;
use chrono::{Datelike, NaiveDate};
use serde::{Deserialize, Serialize};

use crate::core::auth::AuthUser;
use crate::core::error::{AppError, ErrorResponse};
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
    Json(mut input): Json<CreateContractInput>,
) -> Result<Json<serde_json::Value>, AppError> {
    // ✅ validate sớm
    if input.transactions.is_empty() {
        return Err(AppError::Validation(ErrorResponse {
            code: "transactions_empty",
            message: "Phải có ít nhất 1 giao dịch".into(),
        }));
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
    auth: AuthUser,
    Path(contract_id): Path<Uuid>,
    Json(input): Json<CreateContractInput>,
) -> Result<Json<serde_json::Value>, AppError> {
    // ✅ validate policy
    if input.transactions.is_empty() {
        return Err(AppError::Validation(ErrorResponse {
            code: "transactions_empty",
            message: "Phải có ít nhất 1 giao dịch".into(),
        }));
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

// ================== Báo cáo ==================
#[derive(Deserialize)]
pub struct StatsParams {
    pub year: i32,
    pub month: Option<u32>,
    pub range: Option<String>,
}

#[derive(Serialize)]
pub struct Serie {
    pub contract_number: String,
    pub data: Vec<i64>,
}

#[derive(Serialize)]
pub struct StatsResponse {
    pub categories: Vec<String>,
    pub series: Vec<Serie>,
}

pub async fn get_loan_stats(
    State(state): State<Arc<AppState>>,
    Extension(auth): Extension<AuthUser>,
    Query(params): Query<StatsParams>,
) -> Json<StatsResponse> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
    let tenant_id: Uuid = auth.tenant_id;
    let range = params.range.clone().unwrap_or_else(|| "monthly".to_string());

    let rows = match range.as_str() {
        "daily" => {
            let month = params.month.unwrap_or(1);
            query::aggregate_by_day(pool, tenant_id, params.year, month).await.unwrap_or_default()
        }
        "yearly" => {
            query::aggregate_by_year(pool, tenant_id).await.unwrap_or_default()
        }
        _ => {
            query::aggregate_by_month(pool, tenant_id, params.year).await.unwrap_or_default()
        }
    };

    use std::collections::BTreeMap;
    let mut m: BTreeMap<i32, (i64, i64)> = BTreeMap::new();
    for r in rows {
        let k = r.group_key.unwrap_or(0.0).round() as i32;
        let issued = r.total_issued.and_then(|v| v.to_i64()).unwrap_or(0);
        let repaid = r.total_repaid.and_then(|v| v.to_i64()).unwrap_or(0);
        m.insert(k, (issued, repaid));
    }

    let (categories, issued_vec, repaid_vec) = match range.as_str() {
        "daily" => {
            let month = params.month.unwrap_or(1);
            let last_day = last_day_of_month(params.year, month);
            let mut cats = Vec::with_capacity(last_day as usize);
            let mut iv = Vec::with_capacity(last_day as usize);
            let mut rv = Vec::with_capacity(last_day as usize);
            for d in 1..=last_day {
                cats.push(d.to_string());
                let (i, r) = m.get(&(d as i32)).cloned().unwrap_or((0, 0));
                iv.push(i);
                rv.push(r);
            }
            (cats, iv, rv)
        }
        "yearly" => {
            let cats: Vec<String> = m.keys().map(|y| y.to_string()).collect();
            let mut iv = Vec::with_capacity(cats.len());
            let mut rv = Vec::with_capacity(cats.len());
            for k in m.keys() {
                let (i, r) = m.get(k).cloned().unwrap_or((0, 0));
                iv.push(i);
                rv.push(r);
            }
            (cats, iv, rv)
        }
        _ => {
            let mut cats = Vec::with_capacity(12);
            let mut iv = Vec::with_capacity(12);
            let mut rv = Vec::with_capacity(12);
            for mth in 1..=12u32 {
                cats.push(short_month(mth).to_string());
                let (i, r) = m.get(&(mth as i32)).cloned().unwrap_or((0, 0));
                iv.push(i);
                rv.push(r);
            }
            (cats, iv, rv)
        }
    };

    Json(StatsResponse {
        categories,
        series: vec![
            Serie { contract_number: "Loan Issued".into(), data: issued_vec },
            Serie { contract_number: "Loan Repaid".into(), data: repaid_vec },
        ],
    })
}

fn last_day_of_month(year: i32, month: u32) -> u32 {
    let (ny, nm) = if month == 12 { (year + 1, 1) } else { (year, month + 1) };
    let first_next = NaiveDate::from_ymd_opt(ny, nm, 1).unwrap();
    let last = first_next.pred_opt().unwrap();
    last.day()
}

fn short_month(m: u32) -> &'static str {
    match m {
        1 => "Jan", 2 => "Feb", 3 => "Mar", 4 => "Apr", 5 => "May", 6 => "Jun",
        7 => "Jul", 8 => "Aug", 9 => "Sep", 10 => "Oct", 11 => "Nov", _ => "Dec",
    }
}
