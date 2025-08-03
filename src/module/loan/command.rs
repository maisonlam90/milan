use sqlx::PgPool;
use uuid::Uuid;
use chrono::{DateTime, Utc};
use crate::module::loan::dto::CreateContractInput;
use crate::module::loan::model::LoanContract;

pub async fn create_contract(
    pool: &PgPool,
    tenant_id: Uuid,
    input: CreateContractInput,
) -> sqlx::Result<LoanContract> {
    let contract = sqlx::query_as!(
        LoanContract,
        r#"
        INSERT INTO loan_contract (
            tenant_id, customer_id, name, principal, interest_rate, term_months,
            date_start, date_end, collateral_description, collateral_value,
            storage_fee_rate, storage_fee, current_principal, current_interest,
            accumulated_interest, total_paid_interest, total_settlement_amount, state
        )
        VALUES (
            $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,
            $11,$12,$13,$14,$15,$16,$17,$18
        )
        RETURNING *
        "#,
        tenant_id,
        input.customer_id,
        input.name,
        input.principal,
        input.interest_rate,
        input.term_months,
        input.date_start,
        input.date_end,
        input.collateral_description,
        input.collateral_value,
        input.storage_fee_rate,
        input.storage_fee,
        input.current_principal,
        input.current_interest,
        input.accumulated_interest,
        input.total_paid_interest,
        input.total_settlement_amount,
        input.state
    )
    .fetch_one(pool)
    .await?;

    Ok(contract)
}
