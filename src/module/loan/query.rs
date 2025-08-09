use sqlx::{PgPool, query_as};
use uuid::Uuid;
use crate::module::loan::model::{LoanContract, LoanTransaction};
use crate::module::loan::calculator::calculate_interest_fields;

pub async fn list_contracts(pool: &PgPool, tenant_id: Uuid) -> sqlx::Result<Vec<LoanContract>> {
    let contracts = sqlx::query_as!(
        LoanContract,
        r#"
        SELECT id, tenant_id, customer_id, name, principal, interest_rate, term_months,
               date_start, date_end, collateral_description, collateral_value,
               storage_fee_rate, storage_fee, current_principal, current_interest,
               accumulated_interest, total_paid_interest, total_settlement_amount,
               state, created_at, updated_at
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
        SELECT id, tenant_id, customer_id, name, principal, interest_rate, term_months,
               date_start, date_end, collateral_description, collateral_value,
               storage_fee_rate, storage_fee, current_principal, current_interest,
               accumulated_interest, total_paid_interest, total_settlement_amount,
               state, created_at, updated_at
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

/// Lấy giao dịch RAW (không tính trong SQL). Các trường tính toán được
/// trả về NULL để map vào Option<> trong LoanTransaction.
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
            lt.customer_id,
            lt.transaction_type,
            lt.amount,
            lt.date,
            lt.note,
            -- Các trường tính toán để Option<> nhận None, sẽ được calculator.rs điền sau
            NULL::int4   AS "days_from_prev?",
            NULL::int8   AS "interest_for_period?",
            NULL::int8   AS "accumulated_interest?",
            NULL::int8   AS "principal_balance?",
            lt.created_at,
            lt.updated_at
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

/// Hàm tích hợp: lấy contract + transactions raw, rồi tính bằng calculator.rs
pub async fn get_contract_detail(
    pool: &PgPool,
    tenant_id: Uuid,
    contract_id: Uuid,
) -> sqlx::Result<ContractDetail> {
    // 1) Lấy contract
    let mut contract = get_contract_by_id(pool, tenant_id, contract_id).await?;

    // 2) Lấy transactions RAW
    let mut txs = get_transactions_by_contract(pool, tenant_id, contract_id).await?;

    // 3) Tính toàn bộ trường phát sinh theo business rule (single source of truth)
    calculate_interest_fields(&mut contract, &mut txs);

    Ok(ContractDetail { contract, transactions: txs })
}
