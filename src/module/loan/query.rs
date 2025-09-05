use sqlx::{PgPool, query_as};
use uuid::Uuid;
use crate::module::loan::model::{LoanContract, LoanTransaction};
use crate::module::loan::calculator::calculate_interest_fields;
use sqlx::types::BigDecimal; // báo cáo

pub async fn list_contracts(pool: &PgPool, tenant_id: Uuid) -> sqlx::Result<Vec<LoanContract>> {
    let contracts = sqlx::query_as!(
        LoanContract,
        r#"
        SELECT
            id, tenant_id, contact_id, contract_number,
            interest_rate, term_months,
            date_start, date_end,
            storage_fee_rate, storage_fee,
            current_principal, current_interest,
            accumulated_interest, total_paid_interest, total_settlement_amount,
            state, created_at, updated_at,
            created_by, assignee_id, shared_with,
            0::int8 AS "total_paid_principal!",
            0::int8 AS "payoff_due!"
        FROM loan_contract
        WHERE tenant_id = $1
        ORDER BY date_start DESC
        "#,
        tenant_id
    )
    .fetch_all(pool)
    .await?;

    Ok(contracts)
}

pub async fn get_contract_by_id(
    pool: &PgPool,
    tenant_id: Uuid,
    contract_id: Uuid,
) -> sqlx::Result<LoanContract> {
    let contract = sqlx::query_as!(
        LoanContract,
        r#"
        SELECT
            id, tenant_id, contact_id, contract_number,
            interest_rate, term_months,
            date_start, date_end,
            storage_fee_rate, storage_fee,
            current_principal, current_interest,
            accumulated_interest, total_paid_interest, total_settlement_amount,
            state, created_at, updated_at,
            created_by, assignee_id, shared_with,
            0::int8 AS "total_paid_principal!",
            0::int8 AS "payoff_due!"
        FROM loan_contract
        WHERE tenant_id = $1 AND id = $2
        "#,
        tenant_id,
        contract_id
    )
    .fetch_one(pool)
    .await?;

    Ok(contract)
}

/// Lấy giao dịch RAW (không tính trong SQL).
pub async fn get_transactions_by_contract(
    pool: &PgPool,
    tenant_id: Uuid,
    contract_id: Uuid,
) -> Result<Vec<LoanTransaction>, sqlx::Error> {
    let rows = query_as!(
        LoanTransaction,
        r#"
        SELECT
            lt.id,
            lt.contract_id,
            lt.tenant_id,
            lt.contact_id,
            lt.transaction_type,
            lt.amount,
            lt.date                         AS "date!",
            lt.note,
            0::int4                         AS "days_from_prev!",
            0::int8                         AS "interest_for_period!",
            0::int8                         AS "accumulated_interest!",
            0::int8                         AS "principal_balance!",
            0::int8                         AS "principal_applied!",
            0::int8                         AS "interest_applied!",
            lt.created_at                   AS "created_at!",
            lt.updated_at                   AS "updated_at!"
        FROM loan_transaction lt
        WHERE lt.tenant_id = $1
          AND lt.contract_id = $2
        ORDER BY lt.date ASC, lt.id ASC
        "#,
        tenant_id,
        contract_id
    )
    .fetch_all(pool)
    .await?;

    Ok(rows)
}

/// DTO trả về cho API chi tiết hợp đồng
pub struct ContractDetail {
    pub contract: LoanContract,
    pub transactions: Vec<LoanTransaction>,
}

/// Hàm tích hợp: contract + transactions + tính toán projection
pub async fn get_contract_detail(
    pool: &PgPool,
    tenant_id: Uuid,
    contract_id: Uuid,
) -> sqlx::Result<ContractDetail> {
    let mut contract = get_contract_by_id(pool, tenant_id, contract_id).await?;
    let mut txs = get_transactions_by_contract(pool, tenant_id, contract_id).await?;
    calculate_interest_fields(&mut contract, &mut txs);
    Ok(ContractDetail { contract, transactions: txs })
}

// ================== Báo cáo ==================
#[derive(Debug)]
pub struct LoanStats {
    pub group_key: Option<f64>,
    pub total_issued: Option<BigDecimal>,
    pub total_repaid: Option<BigDecimal>,
}

pub async fn aggregate_by_month(
    pool: &PgPool,
    tenant_id: Uuid,
    year: i32,
) -> sqlx::Result<Vec<LoanStats>> {
    let rows = sqlx::query_as!(
        LoanStats,
        r#"
        SELECT
            EXTRACT(MONTH FROM lt.date) AS group_key,
            SUM(CASE WHEN lt.transaction_type IN ('disbursement','additional') THEN lt.amount ELSE 0 END)::numeric AS total_issued,
            SUM(CASE WHEN lt.transaction_type IN ('principal','interest')     THEN lt.amount ELSE 0 END)::numeric   AS total_repaid
        FROM loan_transaction lt
        WHERE lt.tenant_id = $1
          AND EXTRACT(YEAR FROM lt.date) = $2
        GROUP BY group_key
        ORDER BY group_key
        "#,
        tenant_id,
        year as f64
    )
    .fetch_all(pool)
    .await?;

    Ok(rows)
}

pub async fn aggregate_by_day(
    pool: &PgPool,
    tenant_id: Uuid,
    year: i32,
    month: u32,
) -> sqlx::Result<Vec<LoanStats>> {
    let rows = sqlx::query_as!(
        LoanStats,
        r#"
        SELECT
            EXTRACT(DAY FROM lt.date) AS group_key,
            SUM(CASE WHEN lt.transaction_type IN ('disbursement','additional') THEN lt.amount ELSE 0 END)::numeric AS total_issued,
            SUM(CASE WHEN lt.transaction_type IN ('principal','interest')     THEN lt.amount ELSE 0 END)::numeric   AS total_repaid
        FROM loan_transaction lt
        WHERE lt.tenant_id = $1
          AND EXTRACT(YEAR  FROM lt.date) = $2
          AND EXTRACT(MONTH FROM lt.date) = $3
        GROUP BY group_key
        ORDER BY group_key
        "#,
        tenant_id,
        year as f64,
        month as f64
    )
    .fetch_all(pool)
    .await?;

    Ok(rows)
}

pub async fn aggregate_by_year(
    pool: &PgPool,
    tenant_id: Uuid,
) -> sqlx::Result<Vec<LoanStats>> {
    let rows = sqlx::query_as!(
        LoanStats,
        r#"
        SELECT
            EXTRACT(YEAR FROM lt.date) AS group_key,
            SUM(CASE WHEN lt.transaction_type IN ('disbursement','additional') THEN lt.amount ELSE 0 END)::numeric AS total_issued,
            SUM(CASE WHEN lt.transaction_type IN ('principal','interest')     THEN lt.amount ELSE 0 END)::numeric   AS total_repaid
        FROM loan_transaction lt
        WHERE lt.tenant_id = $1
        GROUP BY group_key
        ORDER BY group_key
        "#,
        tenant_id
    )
    .fetch_all(pool)
    .await?;

    Ok(rows)
}
