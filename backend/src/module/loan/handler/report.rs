use axum::{
    extract::{Path, State},
    Extension, Json,
};
use chrono::{NaiveDate, Utc};
use futures::stream::{self, StreamExt};
use serde_json::json;
use sqlx::{Arguments, postgres::PgArguments};
use std::{collections::{HashMap, HashSet}, sync::Arc};
use tracing::{debug, error};
use uuid::Uuid;
use crate::module::loan::model::LoanTransactionRow;

use crate::{
    core::{auth::AuthUser, error::AppError, state::AppState},
    module::loan::{calculator, query, model::{LoanReport, LoanReportView, LoanTransaction, LoanContract}},
};

/// ✅ Projection tức thời 1 hợp đồng (không ghi DB)
pub async fn pivot_now_contract(
    State(state): State<Arc<AppState>>,
    Extension(auth): Extension<AuthUser>,
    Path(contract_id): Path<Uuid>,
) -> Result<Json<LoanReport>, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let mut contract = query::get_contract_by_id(pool, auth.tenant_id, contract_id)
        .await
        .map_err(|_| AppError::bad_request("contract not found"))?;

    let mut txs = query::get_transactions_by_contract(pool, auth.tenant_id, contract.id)
        .await
        .map_err(|e| {
            error!("❌ Lỗi get_transactions_by_contract: {:?}", e);
            AppError::bad_request("transaction query failed")
        })?;

    let as_of = Utc::now();
    calculator::calculate_interest_fields_as_of(&mut contract, &mut txs, as_of);

    let snapshot = LoanReport {
        tenant_id: contract.tenant_id,
        contract_id: contract.id,
        contact_id: contract.contact_id,
        date: as_of.date_naive(),
        current_principal: Some(contract.current_principal),
        current_interest: Some(contract.current_interest),
        accumulated_interest: Some(contract.accumulated_interest),
        total_paid_interest: Some(contract.total_paid_interest),
        total_paid_principal: Some(contract.total_paid_principal),
        payoff_due: Some(contract.payoff_due),
        state: contract.state.clone(),
    };

    Ok(Json(snapshot))
}

/// ✅ Tính & ghi pivot tất cả hợp đồng của tenant
/// Cải tiến: load tất cả transactions 1 lần, group ở Rust
pub async fn pivot_now_all_contracts(
    State(state): State<Arc<AppState>>,
    Extension(auth): Extension<AuthUser>,
) -> Result<Json<serde_json::Value>, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let t0 = std::time::Instant::now();
    let contracts = query::list_contracts(pool, auth.tenant_id)
        .await
        .map_err(|e| AppError::internal(format!("Lỗi load contracts: {:?}", e)))?;
    debug!("⏱ list_contracts: {:?}", t0.elapsed());

    if contracts.is_empty() {
        return Ok(Json(json!({ "ok": true, "count": 0 })));
    }

    // --- A) Load all transactions in one query ---
    let _t_tx = std::time::Instant::now();
    let raw_txs: Vec<LoanTransactionRow> = sqlx::query_as!(
        LoanTransactionRow,
        r#"
        SELECT id, contract_id, tenant_id, contact_id,
            transaction_type, amount, date, note,
            days_from_prev, interest_for_period,
            accumulated_interest, principal_balance,
            created_at, updated_at
        FROM loan_transaction
        WHERE tenant_id = $1
        ORDER BY contract_id, date, id
        "#,
        auth.tenant_id
    )
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::internal(format!("Lỗi load all transactions: {:?}", e)))?;

    let all_txs: Vec<LoanTransaction> = raw_txs
        .into_iter()
        .map(|r| LoanTransaction {
            principal_applied: 0,
            interest_applied: 0,
            id: r.id,
            contract_id: r.contract_id,
            tenant_id: r.tenant_id,
            contact_id: r.contact_id,
            transaction_type: r.transaction_type,
            amount: r.amount,
            date: r.date,
            note: r.note,
            days_from_prev: r.days_from_prev,
            interest_for_period: r.interest_for_period,
            accumulated_interest: r.accumulated_interest,
            principal_balance: r.principal_balance,
            created_at: r.created_at,
            updated_at: r.updated_at,
        })
        .collect();


    // Group txs by contract_id
    let mut tx_map: HashMap<Uuid, Vec<LoanTransaction>> = HashMap::new();
    for tx in all_txs {
        tx_map.entry(tx.contract_id).or_default().push(tx);
    }

    // --- B) Song song tính toán ---
    let today = Utc::now().date_naive();
    let t_calc_all = std::time::Instant::now();
    let concurrency: usize = 8;

    let reports_res = stream::iter(contracts.into_iter())
        .map(|mut contract: LoanContract| {
            let txs = tx_map.remove(&contract.id).unwrap_or_default();
            async move {
                let t_calc = std::time::Instant::now();
                let mut txs_clone = txs; // mutable
                calculator::calculate_interest_fields(&mut contract, &mut txs_clone);
                let calc_ms = t_calc.elapsed();

                debug!("⏱ contract {}: calc={:?}", contract.id, calc_ms);

                Ok::<LoanReport, AppError>(LoanReport {
                    tenant_id: contract.tenant_id,
                    contract_id: contract.id,
                    contact_id: contract.contact_id,
                    date: today,
                    current_principal: Some(contract.current_principal),
                    current_interest: Some(contract.current_interest),
                    accumulated_interest: Some(contract.accumulated_interest),
                    total_paid_interest: Some(contract.total_paid_interest),
                    total_paid_principal: Some(contract.total_paid_principal),
                    payoff_due: Some(contract.payoff_due),
                    state: contract.state.clone(),
                })
            }
        })
        .buffer_unordered(concurrency)
        .collect::<Vec<_>>()
        .await;

    let mut reports: Vec<LoanReport> = Vec::with_capacity(reports_res.len());
    for r in reports_res {
        reports.push(r?);
    }
    debug!("⏱ total calc: {:?}", t_calc_all.elapsed());

    // Khử trùng (contract_id, date)
    let mut seen = HashSet::new();
    reports.retain(|r| seen.insert((r.contract_id, r.date)));

    if reports.is_empty() {
        return Ok(Json(json!({ "ok": true, "count": 0 })));
    }

    // --- C) Bulk UPSERT ---
    let t_write = std::time::Instant::now();
    let mut vals = String::new();
    let mut args = PgArguments::default();
    let mut i = 1;

    for r in &reports {
        if !vals.is_empty() {
            vals.push_str(", ");
        }
        vals.push_str(&format!(
            "(${}, ${}, ${}, ${}, ${}, ${}, ${}, ${}, ${}, ${}, ${})",
            i, i + 1, i + 2, i + 3, i + 4, i + 5, i + 6, i + 7, i + 8, i + 9, i + 10
        ));

        args.add(r.tenant_id);
        args.add(r.contract_id);
        args.add(r.contact_id);
        args.add(r.date);
        args.add(r.current_principal);
        args.add(r.current_interest);
        args.add(r.accumulated_interest);
        args.add(r.total_paid_interest);
        args.add(r.total_paid_principal);
        args.add(r.payoff_due);
        args.add(r.state.clone());

        i += 11;
    }

    let sql = format!(
        r#"
WITH v(tenant_id, contract_id, contact_id, date,
       current_principal, current_interest, accumulated_interest,
       total_paid_interest, total_paid_principal, payoff_due, state) AS (
  VALUES {vals}
)
INSERT INTO loan_report (
  tenant_id, contract_id, contact_id, date,
  current_principal, current_interest, accumulated_interest,
  total_paid_interest, total_paid_principal, payoff_due, state
)
SELECT tenant_id, contract_id, contact_id, date,
       current_principal, current_interest, accumulated_interest,
       total_paid_interest, total_paid_principal, payoff_due, state
FROM v
ON CONFLICT (tenant_id, contract_id, date) DO UPDATE SET
  current_principal     = EXCLUDED.current_principal,
  current_interest      = EXCLUDED.current_interest,
  accumulated_interest  = EXCLUDED.accumulated_interest,
  total_paid_interest   = EXCLUDED.total_paid_interest,
  total_paid_principal  = EXCLUDED.total_paid_principal,
  payoff_due            = EXCLUDED.payoff_due,
  state                 = EXCLUDED.state
"#,
        vals = vals
    );

    sqlx::query_with(&sql, args)
        .execute(pool)
        .await
        .map_err(|e| AppError::internal(format!("CTE upsert loan_report lỗi: {:?}", e)))?;

    debug!("⏱ write_report (UPSERT): {:?}", t_write.elapsed());

    Ok(Json(json!({ "ok": true, "count": reports.len() })))
}

/// ✅ API lấy dữ liệu pivot (đã ghi vào loan_report)
pub async fn get_loan_report(
    State(state): State<Arc<AppState>>,
    Extension(auth): Extension<AuthUser>,
) -> Result<Json<Vec<LoanReportView>>, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    // Mặc định: chỉ lấy ngày hôm nay. Có thể override qua query ?date=YYYY-MM-DD
    let today = Utc::now().date_naive();
    let date: NaiveDate = today;

    let rows = sqlx::query_as!(
        LoanReportView,
        r#"
        SELECT
            r.tenant_id,
            r.contract_id,
            r.contact_id,
            r.date,
            r.current_principal,
            r.current_interest,
            r.accumulated_interest,
            r.total_paid_interest,
            r.total_paid_principal,
            r.payoff_due,
            r.state,
            c.contract_number,
            co.name as contact_name
        FROM loan_report r
        JOIN loan_contract c
          ON c.id = r.contract_id AND c.tenant_id = r.tenant_id
        JOIN contact co
          ON co.id = r.contact_id AND co.tenant_id = r.tenant_id
        WHERE r.tenant_id = $1 AND r.date = $2
        ORDER BY c.contract_number DESC
        "#,
        auth.tenant_id,
        date,
    )
    .fetch_all(pool)
    .await
    .map_err(|e| AppError::internal(format!("Lỗi load báo cáo: {:?}", e)))?;

    Ok(Json(rows))
}
