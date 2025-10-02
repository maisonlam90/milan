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
use chrono::{Datelike, NaiveDate};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::time::{Duration, Instant};
use tokio::sync::RwLock;
use once_cell::sync::Lazy;

use crate::core::auth::AuthUser;
use crate::core::error::{AppError, ErrorResponse};
use crate::core::state::AppState;

// Cache global cho stats với TTL 5 phút
static STATS_CACHE: Lazy<RwLock<HashMap<String, (StatsResponse, Instant)>>> = 
    Lazy::new(|| RwLock::new(HashMap::new()));

// Cache global cho monthly interest với TTL 5 phút
static MONTHLY_INTEREST_CACHE: Lazy<RwLock<HashMap<String, (serde_json::Value, Instant)>>> = 
    Lazy::new(|| RwLock::new(HashMap::new()));

const CACHE_TTL: Duration = Duration::from_secs(300); // 5 phút
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

    let mut contracts = query::list_contracts(pool, auth.tenant_id)
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
    pub use_report: Option<bool>,
}

#[derive(Serialize, Clone)]
pub struct Serie {
    pub contract_number: String,
    pub data: Vec<i64>,
}

#[derive(Serialize, Clone)]
pub struct StatsResponse {
    pub categories: Vec<String>,
    pub series: Vec<Serie>,
}

// Helper function để tính stats từ transactions (không cache)
async fn calculate_stats_from_transactions(
    pool: &sqlx::PgPool,
    tenant_id: Uuid,
    params: &StatsParams,
) -> StatsResponse {
    let range = params.range.clone().unwrap_or_else(|| "monthly".to_string());

    // Lấy tất cả hợp đồng và tính từ transactions với calculator
    let contracts = query::list_contracts(pool, tenant_id).await.unwrap_or_default();
    let mut monthly_stats: std::collections::BTreeMap<i32, (i64, i64)> = std::collections::BTreeMap::new();

    for mut contract in contracts {
        let mut transactions = query::get_transactions_by_contract(pool, tenant_id, contract.id)
            .await
            .unwrap_or_default();

        if transactions.is_empty() {
            continue;
        }

        // Tính toán interest_applied cho từng transaction
        calculator::calculate_interest_fields(&mut contract, &mut transactions);

        // Nhóm theo tháng/ngày/năm tùy theo range
        for tx in &transactions {
            let tx_date = tx.date.with_timezone(&chrono_tz::Asia::Bangkok).date_naive();
            
            let key = match range.as_str() {
                "daily" => {
                    // Chỉ lấy transactions trong tháng được chọn
                    let month = params.month.unwrap_or(1);
                    if tx_date.year() == params.year && tx_date.month() == month {
                        tx_date.day() as i32
                    } else {
                        continue;
                    }
                }
                "yearly" => tx_date.year(),
                _ => tx_date.month() as i32, // monthly
            };

            // Chỉ lấy transactions trong năm được chọn (trừ daily đã filter ở trên)
            if range != "daily" && tx_date.year() != params.year {
                continue;
            }

            let entry = monthly_stats.entry(key).or_insert((0, 0));

            // Loan Issued: disbursement + additional
            if matches!(tx.transaction_type.as_str(), "disbursement" | "additional") {
                entry.0 += tx.amount;
            }

            // Loan Repaid: principal + interest_applied (bao gồm cả lãi từ settlement/liquidation)
            if matches!(tx.transaction_type.as_str(), "principal" | "interest" | "settlement" | "liquidation") {
                if tx.transaction_type == "settlement" || tx.transaction_type == "liquidation" {
                    // Với settlement/liquidation, lấy interest_applied (đã được calculator tách)
                    entry.1 += tx.interest_applied;
                    // Cộng thêm phần principal (amount - interest_applied)
                    entry.1 += tx.amount - tx.interest_applied;
                } else {
                    // Với principal/interest thuần túy
                    entry.1 += tx.amount;
                }
            }
        }
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
                let (i, r) = monthly_stats.get(&(d as i32)).cloned().unwrap_or((0, 0));
                iv.push(i);
                rv.push(r);
            }
            (cats, iv, rv)
        }
        "yearly" => {
            let cats: Vec<String> = monthly_stats.keys().map(|y| y.to_string()).collect();
            let mut iv = Vec::with_capacity(cats.len());
            let mut rv = Vec::with_capacity(cats.len());
            for k in monthly_stats.keys() {
                let (i, r) = monthly_stats.get(k).cloned().unwrap_or((0, 0));
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
                let (i, r) = monthly_stats.get(&(mth as i32)).cloned().unwrap_or((0, 0));
                iv.push(i);
                rv.push(r);
            }
            (cats, iv, rv)
        }
    };

    StatsResponse {
        categories,
        series: vec![
            Serie { contract_number: "Loan Issued".into(), data: issued_vec },
            Serie { contract_number: "Loan Repaid".into(), data: repaid_vec },
        ],
    }
}


pub async fn get_loan_stats(
    State(state): State<Arc<AppState>>,
    Extension(auth): Extension<AuthUser>,
    Query(params): Query<StatsParams>,
) -> Json<StatsResponse> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
    
    // Tạo cache key
    let cache_key = format!("stats_{}_{}_{}_{}", 
        auth.tenant_id, 
        params.range.as_ref().unwrap_or(&"monthly".to_string()),
        params.year,
        params.month.unwrap_or(1)
    );

    // Check cache trước
    {
        let cache = STATS_CACHE.read().await;
        if let Some((cached_response, cached_time)) = cache.get(&cache_key) {
            if cached_time.elapsed() < CACHE_TTL {
                return Json(cached_response.clone());
            }
        }
    }

    // Hybrid approach: tháng hiện tại từ transactions, tháng cũ từ pre-computed
    let now = chrono::Utc::now();
    let current_year = now.year();
    let current_month = now.month();
    
    let result = if params.year == current_year && 
                    (params.range.as_ref().unwrap_or(&"monthly".to_string()) == "monthly" ||
                     (params.range.as_ref().unwrap_or(&"monthly".to_string()) == "daily" && 
                      params.month.unwrap_or(1) == current_month)) {
        // Tháng hiện tại: tính real-time từ transactions
        calculate_stats_from_transactions(pool, auth.tenant_id, &params).await
    } else {
        // Tháng cũ: lấy từ pre-computed (fallback to transactions nếu không có)
        calculate_stats_from_precomputed_or_fallback(pool, auth.tenant_id, &params).await
    };

    // Cache kết quả
    {
        let mut cache = STATS_CACHE.write().await;
        cache.insert(cache_key, (result.clone(), Instant::now()));
        
        // Cleanup cache cũ (giữ tối đa 100 entries)
        if cache.len() > 100 {
            let cutoff = Instant::now() - CACHE_TTL;
            cache.retain(|_, (_, time)| *time > cutoff);
        }
    }

    Json(result)
}

// Lấy từ pre-computed hoặc fallback to transactions
async fn calculate_stats_from_precomputed_or_fallback(
    pool: &sqlx::PgPool,
    tenant_id: Uuid,
    params: &StatsParams,
) -> StatsResponse {
    // TODO: Implement pre-computed table logic
    // Hiện tại fallback về transactions
    calculate_stats_from_transactions(pool, tenant_id, params).await
}

/// API lấy tổng lãi đã trả trong tháng hiện tại từ transactions (với cache)
pub async fn get_monthly_interest_income(
    State(state): State<Arc<AppState>>,
    Extension(auth): Extension<AuthUser>,
) -> Json<serde_json::Value> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
    
    // Tạo cache key
    let now = chrono::Utc::now();
    let cache_key = format!("monthly_interest_{}_{}_{}",
        auth.tenant_id,
        now.year(),
        now.month()
    );

    // Check cache trước
    {
        let cache = MONTHLY_INTEREST_CACHE.read().await;
        if let Some((cached_response, cached_time)) = cache.get(&cache_key) {
            if cached_time.elapsed() < CACHE_TTL {
                return Json(cached_response.clone());
            }
        }
    }
    
    // Cache miss, tính lại
    let year = now.year();
    let month = now.month();

    // Lấy tất cả giao dịch trong tháng hiện tại, tính tổng interest_applied từ calculator
    let contracts = query::list_contracts(pool, auth.tenant_id).await.unwrap_or_default();
    let total_contracts = contracts.len();
    let mut total_monthly_interest = 0i64;
    let mut processed_contracts = 0;

    for mut contract in contracts {
        // Lấy tất cả transactions của contract này
        let mut transactions = query::get_transactions_by_contract(pool, auth.tenant_id, contract.id)
            .await
            .unwrap_or_default();

        if transactions.is_empty() {
            continue;
        }

        // Tính toán interest_applied cho từng transaction
        calculator::calculate_interest_fields(&mut contract, &mut transactions);

        // Tổng interest_applied từ các giao dịch trong tháng hiện tại
        let monthly_interest: i64 = transactions
            .iter()
            .filter(|tx| {
                let tx_date = tx.date.with_timezone(&chrono_tz::Asia::Bangkok).date_naive();
                tx_date.year() == year && tx_date.month() == month
            })
            .map(|tx| tx.interest_applied)
            .sum();

        total_monthly_interest += monthly_interest;
        if monthly_interest > 0 {
            processed_contracts += 1;
        }
    }

    let result = serde_json::json!({
        "monthly_interest_paid": total_monthly_interest,
        "processed_contracts": processed_contracts,
        "total_contracts": total_contracts,
        "month": month,
        "year": year,
        "debug_info": format!("Xử lý {}/{} hợp đồng, tổng lãi thu trong {}/{}: {}", 
                             processed_contracts, total_contracts, month, year, total_monthly_interest)
    });

    // Cache kết quả
    {
        let mut cache = MONTHLY_INTEREST_CACHE.write().await;
        cache.insert(cache_key, (result.clone(), Instant::now()));
        
        // Cleanup cache cũ (giữ tối đa 50 entries)
        if cache.len() > 50 {
            let cutoff = Instant::now() - CACHE_TTL;
            cache.retain(|_, (_, time)| *time > cutoff);
        }
    }

    Json(result)
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
