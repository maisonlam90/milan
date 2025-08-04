use sqlx::PgPool;
use uuid::Uuid;
use crate::module::loan::model::LoanContract;

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