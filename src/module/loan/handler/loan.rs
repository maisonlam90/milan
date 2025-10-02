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

/// API lấy dashboard stats (6 ô số liệu)
pub async fn get_dashboard_stats(
    State(state): State<Arc<AppState>>,
    Extension(auth): Extension<AuthUser>,
) -> Json<serde_json::Value> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
    let tenant_id = auth.tenant_id;
    
    let now = chrono::Utc::now();
    let year = now.year();
    let month = now.month();
    
    // Cache key cho dashboard stats
    let cache_key = format!("dashboard_stats_{}_{}_{}",
        tenant_id, year, month
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

    // Lấy tất cả hợp đồng và transactions để tính toán
    let contracts = query::list_contracts(pool, tenant_id).await.unwrap_or_default();
    let mut monthly_interest = 0i64;
    let mut settled_this_month = 0i32;
    let mut active_contracts = 0i32;
    let mut new_contracts_this_month = 0i32;
    let mut total_outstanding = 0i64;
    let total_contracts = contracts.len() as i32;

    for mut contract in contracts {
        let mut transactions = query::get_transactions_by_contract(pool, tenant_id, contract.id)
            .await
            .unwrap_or_default();

        if transactions.is_empty() {
            continue;
        }

        // Tính toán interest_applied
        calculator::calculate_interest_fields(&mut contract, &mut transactions);

        // Kiểm tra contract tạo trong tháng này
        let contract_date = contract.created_at.with_timezone(&chrono_tz::Asia::Bangkok).date_naive();
        if contract_date.year() == year && contract_date.month() == month {
            new_contracts_this_month += 1;
        }

        // Kiểm tra trạng thái contract
        let mut is_settled = false;
        let mut current_principal = contract.current_principal;
        
        for tx in &transactions {
            let tx_date = tx.date.with_timezone(&chrono_tz::Asia::Bangkok).date_naive();
            
            // Lãi thu trong tháng
            if tx_date.year() == year && tx_date.month() == month {
                monthly_interest += tx.interest_applied;
            }

            // Cập nhật số dư
            match tx.transaction_type.as_str() {
                "disbursement" | "additional" => {
                    // Không làm gì, principal đã tính từ đầu
                }
                "principal" => {
                    current_principal -= tx.amount;
                }
                "settlement" | "liquidation" => {
                    current_principal -= tx.amount - tx.interest_applied;
                    // Kiểm tra tất toán trong tháng này
                    if tx_date.year() == year && tx_date.month() == month {
                        settled_this_month += 1;
                    }
                    is_settled = true;
                }
                _ => {} // interest không ảnh hưởng principal
            }
        }

        // Đếm hợp đồng đang hoạt động và tổng dư nợ
        if !is_settled && current_principal > 0 {
            active_contracts += 1;
            total_outstanding += current_principal;
        }
    }

    let result = serde_json::json!({
        "monthly_interest": monthly_interest,
        "settled_this_month": settled_this_month,
        "active_contracts": active_contracts,
        "new_contracts_this_month": new_contracts_this_month,
        "total_outstanding": total_outstanding,
        "total_contracts": total_contracts,
        "month": month,
        "year": year
    });

    // Cache kết quả
    {
        let mut cache = MONTHLY_INTEREST_CACHE.write().await;
        cache.insert(cache_key, (result.clone(), Instant::now()));
    }

    Json(result)
}

/// API lấy báo cáo hoạt động cho vay (thay thế Bandwidth Report) - OPTIMIZED
pub async fn get_loan_activity_report(
    State(state): State<Arc<AppState>>,
    Extension(auth): Extension<AuthUser>,
) -> Json<serde_json::Value> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
    let tenant_id = auth.tenant_id;
    
    // Cache key cho loan activity report
    let cache_key = format!("loan_activity_{}", tenant_id);

    // Check cache trước
    {
        let cache = MONTHLY_INTEREST_CACHE.read().await;
        if let Some((cached_response, cached_time)) = cache.get(&cache_key) {
            if cached_time.elapsed() < CACHE_TTL {
                return Json(cached_response.clone());
            }
        }
    }

    // ✅ OPTIMIZATION 1: Load tất cả data một lần
    let contracts = query::list_contracts(pool, tenant_id).await.unwrap_or_default();
    let today = chrono::Utc::now().date_naive();
    let current_month = today.month();
    let current_year = today.year();
    
    let mut new_loans_count = 0i32;
    let mut new_loans_amount = 0i64;
    let mut repayments_count = 0i32;
    let mut repayments_amount = 0i64;
    let mut overdue_count = 0i32;
    let mut overdue_amount = 0i64;
    let mut collections_count = 0i32;
    let mut collections_amount = 0i64;
    
    // Mục tiêu tháng (có thể config sau)
    let monthly_new_loans_target = 50i32;
    let monthly_repayments_target = 100i32;
    let monthly_overdue_target = 5i32; // Mục tiêu là ít quá hạn
    let monthly_collections_target = 80i32;

    // ✅ OPTIMIZATION 2: Tính chart_data từ dữ liệu đã có
    let days_in_month = match current_month {
        2 => if current_year % 4 == 0 { 29 } else { 28 },
        4 | 6 | 9 | 11 => 30,
        _ => 31,
    };
    
    let mut chart_data = vec![0i64; std::cmp::min(20, days_in_month) as usize];

    // ✅ OPTIMIZATION 3: Single loop - load và process tất cả data
    for mut contract in contracts {
        let mut transactions = query::get_transactions_by_contract(pool, tenant_id, contract.id)
            .await
            .unwrap_or_default();

        if transactions.is_empty() {
            continue;
        }

        // Tính toán interest_applied một lần duy nhất
        calculator::calculate_interest_fields(&mut contract, &mut transactions);

        // Kiểm tra hợp đồng mới trong tháng
        let contract_date = contract.created_at.with_timezone(&chrono_tz::Asia::Bangkok).date_naive();
        if contract_date.year() == current_year && contract_date.month() == current_month {
            new_loans_count += 1;
            new_loans_amount += contract.current_principal;
        }

        // Kiểm tra trạng thái quá hạn
        let last_disbursement = transactions
            .iter()
            .filter(|tx| matches!(tx.transaction_type.as_str(), "disbursement" | "additional"))
            .max_by_key(|tx| tx.date);

        if let Some(disbursement) = last_disbursement {
            let disbursement_date = disbursement.date.date_naive();
            let due_date = disbursement_date + chrono::Duration::days(contract.term_months as i64 * 30);
            let overdue_days = (today - due_date).num_days();
            
            if overdue_days > 0 {
                overdue_count += 1;
                // Tính số dư hiện tại cho hợp đồng quá hạn
                let mut current_balance = contract.current_principal;
                for tx in &transactions {
                    match tx.transaction_type.as_str() {
                        "principal" => current_balance -= tx.amount,
                        "settlement" | "liquidation" => current_balance -= tx.amount - tx.interest_applied,
                        _ => {}
                    }
                }
                overdue_amount += current_balance.max(0);
            }
        }

        // ✅ OPTIMIZATION 4: Process transactions một lần cho cả statistics và chart
        for tx in &transactions {
            let tx_date = tx.date.with_timezone(&chrono_tz::Asia::Bangkok).date_naive();
            
            // Đếm các giao dịch trong tháng cho statistics
            if tx_date.year() == current_year && tx_date.month() == current_month {
                match tx.transaction_type.as_str() {
                    "principal" | "interest" => {
                        repayments_count += 1;
                        repayments_amount += tx.amount;
                    }
                    "settlement" | "liquidation" => {
                        collections_count += 1;
                        collections_amount += tx.amount;
                    }
                    _ => {}
                }
                
                // ✅ OPTIMIZATION 5: Tính chart data cùng lúc
                if tx_date.day() <= 20 {
                    let day_index = (tx_date.day() - 1) as usize;
                    if day_index < chart_data.len() {
                        chart_data[day_index] += tx.amount;
                    }
                }
            }
        }
    }

    // Tính phần trăm hoàn thành mục tiêu
    let new_loans_progress = if monthly_new_loans_target > 0 {
        ((new_loans_count as f64 / monthly_new_loans_target as f64) * 100.0).min(100.0)
    } else { 0.0 };

    let repayments_progress = if monthly_repayments_target > 0 {
        ((repayments_count as f64 / monthly_repayments_target as f64) * 100.0).min(100.0)
    } else { 0.0 };

    let overdue_progress = if monthly_overdue_target > 0 {
        // Đối với quá hạn, % cao là không tốt
        ((overdue_count as f64 / monthly_overdue_target as f64) * 100.0).min(100.0)
    } else { 0.0 };

    let collections_progress = if monthly_collections_target > 0 {
        ((collections_count as f64 / monthly_collections_target as f64) * 100.0).min(100.0)
    } else { 0.0 };

    // Tính performance tổng thể
    let overall_performance = (new_loans_progress + repayments_progress + collections_progress - overdue_progress) / 3.0;

    let result = serde_json::json!({
        "title": "Báo cáo Hoạt động Cho vay",
        "activities": [
            {
                "name": "Hợp đồng mới",
                "count": new_loans_count,
                "amount": new_loans_amount,
                "unit": "HĐ",
                "progress": new_loans_progress,
                "color": "success",
                "target_label": "Mục tiêu tháng",
                "is_active": true
            },
            {
                "name": "Thanh toán",
                "count": repayments_count,
                "amount": repayments_amount,
                "unit": "GD",
                "progress": repayments_progress,
                "color": "info",
                "target_label": "Mục tiêu tháng",
                "is_active": false
            },
            {
                "name": "Quá hạn",
                "count": overdue_count,
                "amount": overdue_amount,
                "unit": "HĐ",
                "progress": overdue_progress,
                "color": "error",
                "target_label": "Mục tiêu tháng",
                "is_active": false
            },
            {
                "name": "Thu hồi",
                "count": collections_count,
                "amount": collections_amount,
                "unit": "GD",
                "progress": collections_progress,
                "color": "warning",
                "target_label": "Mục tiêu tháng",
                "is_active": true
            }
        ],
        "performance": {
            "value": format!("{:.1}%", overall_performance.abs()),
            "trend": if overall_performance >= 0.0 { "up" } else { "down" }
        },
        "chart_data": chart_data,
        "month": current_month,
        "year": current_year
    });

    // Cache kết quả
    {
        let mut cache = MONTHLY_INTEREST_CACHE.write().await;
        cache.insert(cache_key, (result.clone(), Instant::now()));
    }

    Json(result)
}

/// API lấy trạng thái hợp đồng vay (thay thế Projects Status)
pub async fn get_contract_status(
    State(state): State<Arc<AppState>>,
    Extension(auth): Extension<AuthUser>,
) -> Json<serde_json::Value> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
    let tenant_id = auth.tenant_id;
    
    // Cache key cho contract status
    let cache_key = format!("contract_status_{}", tenant_id);

    // Check cache trước
    {
        let cache = MONTHLY_INTEREST_CACHE.read().await;
        if let Some((cached_response, cached_time)) = cache.get(&cache_key) {
            if cached_time.elapsed() < CACHE_TTL {
                return Json(cached_response.clone());
            }
        }
    }

    // Lấy tất cả hợp đồng và transactions để tính toán
    let contracts = query::list_contracts(pool, tenant_id).await.unwrap_or_default();
    let today = chrono::Utc::now().date_naive();
    let current_month = today.month();
    let current_year = today.year();
    
    let mut active_contracts = 0i32;
    let mut total_progress = 0f64;
    let mut overdue_contracts = 0i32;
    let mut total_overdue_days = 0i64;
    let mut settled_this_month = 0i32;
    
    // Mục tiêu tất toán tháng này (có thể config sau)
    let monthly_settlement_target = 10i32; // Tạm thời hardcode 10 hợp đồng/tháng

    for mut contract in contracts {
        let mut transactions = query::get_transactions_by_contract(pool, tenant_id, contract.id)
            .await
            .unwrap_or_default();

        if transactions.is_empty() {
            continue;
        }

        // Tính toán interest_applied
        calculator::calculate_interest_fields(&mut contract, &mut transactions);

        // Kiểm tra trạng thái hợp đồng
        let mut is_settled = false;
        let mut current_principal = contract.current_principal;
        
        for tx in &transactions {
            match tx.transaction_type.as_str() {
                "principal" => {
                    current_principal -= tx.amount;
                }
                "settlement" | "liquidation" => {
                    current_principal -= tx.amount - tx.interest_applied;
                    is_settled = true;
                    
                    // Kiểm tra tất toán trong tháng này
                    let tx_date = tx.date.with_timezone(&chrono_tz::Asia::Bangkok).date_naive();
                    if tx_date.year() == current_year && tx_date.month() == current_month {
                        settled_this_month += 1;
                    }
                }
                _ => {}
            }
        }

        // Chỉ tính hợp đồng đang hoạt động
        if !is_settled && current_principal > 0 {
            active_contracts += 1;

            // Tính % tiến độ trả nợ
            let original_principal = contract.current_principal;
            let paid_principal = original_principal - current_principal;
            let progress_percentage = if original_principal > 0 {
                (paid_principal as f64 / original_principal as f64) * 100.0
            } else {
                0.0
            };
            total_progress += progress_percentage;

            // Tìm giao dịch giải ngân cuối cùng để tính ngày đáo hạn
            let last_disbursement = transactions
                .iter()
                .filter(|tx| matches!(tx.transaction_type.as_str(), "disbursement" | "additional"))
                .max_by_key(|tx| tx.date);

            if let Some(disbursement) = last_disbursement {
                let disbursement_date = disbursement.date.date_naive();
                let due_date = disbursement_date + chrono::Duration::days(contract.term_months as i64 * 30);
                let overdue_days = (today - due_date).num_days();

                if overdue_days > 0 {
                    overdue_contracts += 1;
                    total_overdue_days += overdue_days;
                }
            }
        }
    }

    // Tính toán kết quả
    let avg_progress = if active_contracts > 0 {
        total_progress / active_contracts as f64
    } else {
        0.0
    };

    let avg_overdue_days = if overdue_contracts > 0 {
        total_overdue_days as f64 / overdue_contracts as f64
    } else {
        0.0
    };

    let settlement_progress = if monthly_settlement_target > 0 {
        (settled_this_month as f64 / monthly_settlement_target as f64) * 100.0
    } else {
        0.0
    };

    let result = serde_json::json!([
        {
            "id": 1,
            "name": "Hợp đồng đang hoạt động",
            "description": format!("{} hợp đồng đang hoạt động", active_contracts),
            "color": "info",
            "category": "Hoạt động",
            "progress": avg_progress,
            "created_at": format!("Cập nhật: {}", today.format("%d/%m/%Y")),
            "count": active_contracts,
            "teamMembers": []
        },
        {
            "id": 2,
            "name": "Hợp đồng quá hạn",
            "description": format!("{} hợp đồng quá hạn", overdue_contracts),
            "color": "error",
            "category": "Quá hạn",
            "progress": avg_overdue_days.min(100.0), // Cap at 100% for display
            "created_at": format!("TB: {:.1} ngày", avg_overdue_days),
            "count": overdue_contracts,
            "teamMembers": []
        },
        {
            "id": 3,
            "name": "Hợp đồng tất toán",
            "description": format!("{}/{} hợp đồng tháng này", settled_this_month, monthly_settlement_target),
            "color": "success",
            "category": "Tất toán",
            "progress": settlement_progress.min(100.0), // Cap at 100%
            "created_at": format!("Mục tiêu: {} HĐ/tháng", monthly_settlement_target),
            "count": settled_this_month,
            "teamMembers": []
        }
    ]);

    // Cache kết quả
    {
        let mut cache = MONTHLY_INTEREST_CACHE.write().await;
        cache.insert(cache_key, (result.clone(), Instant::now()));
    }

    Json(result)
}

/// API lấy top hợp đồng có lợi nhuận cao nhất (thay thế Top Sellers)
pub async fn get_top_contracts(
    State(state): State<Arc<AppState>>,
    Extension(auth): Extension<AuthUser>,
) -> Json<serde_json::Value> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
    let tenant_id = auth.tenant_id;
    
    // Cache key cho top contracts
    let cache_key = format!("top_contracts_{}", tenant_id);

    // Check cache trước
    {
        let cache = MONTHLY_INTEREST_CACHE.read().await;
        if let Some((cached_response, cached_time)) = cache.get(&cache_key) {
            if cached_time.elapsed() < CACHE_TTL {
                return Json(cached_response.clone());
            }
        }
    }

    // Lấy tất cả hợp đồng và transactions để tính lợi nhuận
    let contracts = query::list_contracts(pool, tenant_id).await.unwrap_or_default();
    let mut contract_profits: Vec<serde_json::Value> = Vec::new();

    for mut contract in contracts {
        let mut transactions = query::get_transactions_by_contract(pool, tenant_id, contract.id)
            .await
            .unwrap_or_default();

        if transactions.is_empty() {
            continue;
        }

        // Tính toán interest_applied
        calculator::calculate_interest_fields(&mut contract, &mut transactions);

        // Lấy thông tin contact
        let contact = sqlx::query!(
            "SELECT name FROM contact WHERE tenant_id = $1 AND id = $2",
            tenant_id,
            contract.contact_id
        )
        .fetch_optional(pool)
        .await
        .unwrap_or(None);

        let contact_name = contact.map(|c| c.name).unwrap_or_else(|| "Unknown".to_string());

        // Tính tổng lợi nhuận (lãi đã thu)
        let total_interest_collected: i64 = transactions
            .iter()
            .map(|tx| tx.interest_applied)
            .sum();

        // Tính số tiền gốc đã thu
        let mut principal_collected = 0i64;
        for tx in &transactions {
            match tx.transaction_type.as_str() {
                "principal" => {
                    principal_collected += tx.amount;
                }
                "settlement" | "liquidation" => {
                    principal_collected += tx.amount - tx.interest_applied;
                }
                _ => {}
            }
        }

        // Tính tỷ lệ hoàn thành
        let completion_rate = if contract.current_principal > 0 {
            (principal_collected as f64 / contract.current_principal as f64) * 100.0
        } else {
            100.0
        };

        // Tính số ngày từ khi tạo hợp đồng
        let days_since_creation = (chrono::Utc::now().date_naive() - contract.created_at.date_naive()).num_days();

        // Tính lợi nhuận trung bình mỗi ngày
        let daily_profit = if days_since_creation > 0 {
            total_interest_collected as f64 / days_since_creation as f64
        } else {
            0.0
        };

        contract_profits.push(serde_json::json!({
            "uid": contract.id.to_string(),
            "name": contract.contract_number,
            "avatar": null, // Có thể thêm avatar cho contact sau
            "contact_name": contact_name,
            "contract_id": contract.id,
            "principal": contract.current_principal,
            "interest_collected": total_interest_collected,
            "principal_collected": principal_collected,
            "completion_rate": completion_rate,
            "daily_profit": daily_profit,
            "days_active": days_since_creation,
            "created_at": contract.created_at.format("%d/%m/%Y").to_string(),
            // Tính toán relations dựa trên performance
            "relations": {
                "profit_rate": (total_interest_collected as f64 / contract.current_principal.max(1) as f64).min(1.0),
                "completion": (completion_rate / 100.0).min(1.0),
                "efficiency": (daily_profit / 1000.0).min(1.0) // Scale theo 1000 VND/ngày
            }
        }));
    }

    // Sắp xếp theo tổng lợi nhuận giảm dần và lấy top 6
    contract_profits.sort_by(|a, b| {
        let profit_a = a["interest_collected"].as_i64().unwrap_or(0);
        let profit_b = b["interest_collected"].as_i64().unwrap_or(0);
        profit_b.cmp(&profit_a)
    });

    let top_contracts: Vec<serde_json::Value> = contract_profits.into_iter().take(6).collect();

    // Tính tổng lợi nhuận của top contracts
    let total_profit: i64 = top_contracts
        .iter()
        .map(|c| c["interest_collected"].as_i64().unwrap_or(0))
        .sum();

    let result = serde_json::json!({
        "top_contracts": top_contracts,
        "total_profit": total_profit,
        "summary": {
            "title": "Top Hợp đồng",
            "description": "Các hợp đồng có lợi nhuận cao nhất được cập nhật theo thời gian thực.",
            "growth_label": "Tổng lợi nhuận",
            "growth_value": total_profit
        }
    });

    // Cache kết quả
    {
        let mut cache = MONTHLY_INTEREST_CACHE.write().await;
        cache.insert(cache_key, (result.clone(), Instant::now()));
    }

    Json(result)
}

/// API lấy chất lượng danh mục cho vay (thay thế Customer Satisfaction)
pub async fn get_loan_portfolio_quality(
    State(state): State<Arc<AppState>>,
    Extension(auth): Extension<AuthUser>,
) -> Json<serde_json::Value> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
    let tenant_id = auth.tenant_id;
    
    // Cache key cho portfolio quality
    let cache_key = format!("portfolio_quality_{}", tenant_id);

    // Check cache trước
    {
        let cache = MONTHLY_INTEREST_CACHE.read().await;
        if let Some((cached_response, cached_time)) = cache.get(&cache_key) {
            if cached_time.elapsed() < CACHE_TTL {
                return Json(cached_response.clone());
            }
        }
    }

    // Lấy tất cả hợp đồng đang hoạt động
    let contracts = query::list_contracts(pool, tenant_id).await.unwrap_or_default();
    let today = chrono::Utc::now().date_naive();
    
    let mut excellent = 0i32;      // Đúng hạn
    let mut very_good = 0i32;      // Quá hạn 1-7 ngày
    let mut good = 0i32;           // Quá hạn 8-30 ngày  
    let mut poor = 0i32;           // Quá hạn 31-90 ngày
    let mut very_poor = 0i32;      // Quá hạn >90 ngày
    let mut total_active = 0i32;

    for mut contract in contracts {
        let mut transactions = query::get_transactions_by_contract(pool, tenant_id, contract.id)
            .await
            .unwrap_or_default();

        if transactions.is_empty() {
            continue;
        }

        // Tính toán để xác định trạng thái hợp đồng
        calculator::calculate_interest_fields(&mut contract, &mut transactions);

        // Kiểm tra xem hợp đồng đã tất toán chưa
        let mut is_settled = false;
        let mut current_principal = contract.current_principal;
        
        for tx in &transactions {
            match tx.transaction_type.as_str() {
                "principal" => {
                    current_principal -= tx.amount;
                }
                "settlement" | "liquidation" => {
                    current_principal -= tx.amount - tx.interest_applied;
                    is_settled = true;
                }
                _ => {}
            }
        }

        // Chỉ tính hợp đồng đang hoạt động
        if !is_settled && current_principal > 0 {
            total_active += 1;

            // Tìm giao dịch giải ngân cuối cùng để tính ngày đáo hạn
            let last_disbursement = transactions
                .iter()
                .filter(|tx| matches!(tx.transaction_type.as_str(), "disbursement" | "additional"))
                .max_by_key(|tx| tx.date);

            if let Some(disbursement) = last_disbursement {
                // Giả sử kỳ hạn là term_months từ ngày giải ngân cuối
                let disbursement_date = disbursement.date.date_naive();
                let due_date = disbursement_date + chrono::Duration::days(contract.term_months as i64 * 30);
                let overdue_days = (today - due_date).num_days();

                match overdue_days {
                    x if x <= 0 => excellent += 1,      // Đúng hạn hoặc chưa đến hạn
                    x if x <= 7 => very_good += 1,      // Quá hạn 1-7 ngày
                    x if x <= 30 => good += 1,          // Quá hạn 8-30 ngày
                    x if x <= 90 => poor += 1,          // Quá hạn 31-90 ngày
                    _ => very_poor += 1,                 // Quá hạn >90 ngày
                }
            } else {
                // Không có giao dịch giải ngân, coi như excellent
                excellent += 1;
            }
        }
    }

    // Tính phần trăm
    let calculate_percentage = |count: i32| -> f64 {
        if total_active > 0 {
            (count as f64 / total_active as f64) * 100.0
        } else {
            0.0
        }
    };

    // Tính điểm chất lượng tổng thể (weighted score)
    let quality_score = if total_active > 0 {
        let weighted_sum = excellent * 5 + very_good * 4 + good * 3 + poor * 2 + very_poor * 1;
        (weighted_sum as f64 / total_active as f64 / 5.0) * 10.0 // Scale to 0-10
    } else {
        0.0
    };

    let result = serde_json::json!({
        "quality_score": format!("{:.1}", quality_score),
        "total_active_contracts": total_active,
        "categories": [
            {
                "name": "Excellent",
                "count": excellent,
                "percentage": calculate_percentage(excellent) as i32,
                "color": "success"
            },
            {
                "name": "Very Good", 
                "count": very_good,
                "percentage": calculate_percentage(very_good) as i32,
                "color": "info"
            },
            {
                "name": "Good",
                "count": good, 
                "percentage": calculate_percentage(good) as i32,
                "color": "warning"
            },
            {
                "name": "Poor",
                "count": poor,
                "percentage": calculate_percentage(poor) as i32,
                "color": "error"
            },
            {
                "name": "Very Poor",
                "count": very_poor,
                "percentage": calculate_percentage(very_poor) as i32,
                "color": "error"
            }
        ]
    });

    // Cache kết quả
    {
        let mut cache = MONTHLY_INTEREST_CACHE.write().await;
        cache.insert(cache_key, (result.clone(), Instant::now()));
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

/// API lấy hoạt động gần đây (thay thế Users Activity)
pub async fn get_recent_activities(
    State(state): State<Arc<AppState>>,
    Extension(auth): Extension<AuthUser>,
) -> Json<serde_json::Value> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);
    let tenant_id = auth.tenant_id;
    
    // Cache key cho recent activities
    let cache_key = format!("recent_activities_{}", tenant_id);

    // Check cache trước
    {
        let cache = MONTHLY_INTEREST_CACHE.read().await;
        if let Some((cached_response, cached_time)) = cache.get(&cache_key) {
            if cached_time.elapsed() < CACHE_TTL {
                return Json(cached_response.clone());
            }
        }
    }

    // Lấy 5 transaction gần nhất với thông tin hợp đồng và contact
    let recent_transactions = sqlx::query!(
        r#"
        SELECT 
            lt.id,
            lt.transaction_type,
            lt.amount,
            lt.date,
            lt.note,
            lc.contract_number,
            c.name as contact_name
        FROM loan_transaction lt
        JOIN loan_contract lc ON lt.contract_id = lc.id
        JOIN contact c ON lc.contact_id = c.id
        WHERE lt.tenant_id = $1
        ORDER BY lt.date DESC, lt.created_at DESC
        LIMIT 5
        "#,
        tenant_id
    )
    .fetch_all(pool)
    .await
    .unwrap_or_default();

    let mut activities = Vec::new();

    for tx in recent_transactions {
        let (title, description, icon_type, color) = match tx.transaction_type.as_str() {
            "disbursement" => (
                "Giải ngân mới",
                format!("Giải ngân {} cho HĐ {}", 
                    format_currency(tx.amount), 
                    tx.contract_number
                ),
                "disbursement",
                "success"
            ),
            "additional" => (
                "Giải ngân bổ sung", 
                format!("Bổ sung {} cho HĐ {}", 
                    format_currency(tx.amount), 
                    tx.contract_number
                ),
                "additional",
                "info"
            ),
            "principal" => (
                "Trả gốc",
                format!("{} trả gốc {} - HĐ {}", 
                    tx.contact_name, 
                    format_currency(tx.amount), 
                    tx.contract_number
                ),
                "principal",
                "primary"
            ),
            "interest" => (
                "Trả lãi",
                format!("{} trả lãi {} - HĐ {}", 
                    tx.contact_name, 
                    format_currency(tx.amount), 
                    tx.contract_number
                ),
                "interest", 
                "warning"
            ),
            "settlement" => (
                "Tất toán",
                format!("{} tất toán {} - HĐ {}", 
                    tx.contact_name, 
                    format_currency(tx.amount), 
                    tx.contract_number
                ),
                "settlement",
                "success"
            ),
            "liquidation" => (
                "Thanh lý",
                format!("{} thanh lý {} - HĐ {}", 
                    tx.contact_name, 
                    format_currency(tx.amount), 
                    tx.contract_number
                ),
                "liquidation",
                "error"
            ),
            _ => (
                "Giao dịch khác",
                format!("Giao dịch {} - HĐ {}", 
                    format_currency(tx.amount), 
                    tx.contract_number
                ),
                "other",
                "secondary"
            )
        };

        activities.push(serde_json::json!({
            "id": tx.id,
            "title": title,
            "description": description,
            "amount": tx.amount,
            "formatted_amount": format_currency(tx.amount),
            "contract_number": tx.contract_number,
            "contact_name": tx.contact_name,
            "transaction_type": tx.transaction_type,
            "icon_type": icon_type,
            "color": color,
            "date": tx.date.timestamp(),
            "note": tx.note
        }));
    }

    let result = serde_json::json!({
        "activities": activities,
        "total_count": activities.len(),
        "title": "Hoạt động gần đây",
        "description": "Các giao dịch cho vay mới nhất"
    });

    // Cache kết quả
    {
        let mut cache = MONTHLY_INTEREST_CACHE.write().await;
        cache.insert(cache_key, (result.clone(), Instant::now()));
    }

    Json(result)
}

// Helper function để format currency
fn format_currency(amount: i64) -> String {
    if amount >= 1_000_000_000 {
        format!("{:.1} tỷ", amount as f64 / 1_000_000_000.0)
    } else if amount >= 1_000_000 {
        format!("{:.1} tr", amount as f64 / 1_000_000.0)
    } else if amount >= 1_000 {
        format!("{:.0}k", amount as f64 / 1_000.0)
    } else {
        format!("{}", amount)
    }
}
