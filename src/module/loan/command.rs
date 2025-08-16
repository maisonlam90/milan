use sqlx::PgPool;
use uuid::Uuid;
use chrono::{DateTime, Utc};
use crate::module::loan::dto::CreateContractInput;
use crate::module::loan::model::LoanContract;

// epoch seconds -> DateTime<Utc> (chrono >= 0.4.38)
fn epoch_to_utc(ts: i64) -> Result<DateTime<Utc>, sqlx::Error> {
    DateTime::<Utc>::from_timestamp(ts, 0)
        .ok_or_else(|| sqlx::Error::Protocol("Invalid timestamp".into()))
}

pub async fn create_contract(
    pool: &PgPool,
    tenant_id: Uuid,
    input: CreateContractInput,
) -> sqlx::Result<LoanContract> {
    let mut tx = pool.begin().await?;

    // tránh NULL cho cột NOT NULL
    let collateral_value = input.collateral_value.unwrap_or(0);
    let storage_fee_rate = input.storage_fee_rate.unwrap_or(0.0);
    let storage_fee = input.storage_fee.unwrap_or(0);
    let current_principal = input.current_principal.unwrap_or(0);
    let current_interest = input.current_interest.unwrap_or(0);
    let accumulated_interest = input.accumulated_interest.unwrap_or(0);
    let total_paid_interest = input.total_paid_interest.unwrap_or(0);
    let total_settlement_amount = input.total_settlement_amount.unwrap_or(0);

    let contract = sqlx::query_as!(
        LoanContract,
        r#"
        INSERT INTO loan_contract (
            tenant_id, contact_id, name, principal, interest_rate, term_months,
            date_start, date_end, collateral_description, collateral_value,
            storage_fee_rate, storage_fee, current_principal, current_interest,
            accumulated_interest, total_paid_interest, total_settlement_amount, state
        )
        VALUES (
            $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,
            $11,$12,$13,$14,$15,$16,$17,$18
        )
        RETURNING id, tenant_id, contact_id, name, principal, interest_rate, term_months,
                  date_start, date_end, collateral_description, collateral_value,
                  storage_fee_rate, storage_fee, current_principal, current_interest,
                  accumulated_interest, total_paid_interest, total_settlement_amount,
                  state, created_at, updated_at
        "#,
        tenant_id,
        input.contact_id,
        input.name,
        input.principal,
        input.interest_rate,
        input.term_months,
        input.date_start,
        input.date_end,
        input.collateral_description,
        collateral_value,
        storage_fee_rate,
        storage_fee,
        current_principal,
        current_interest,
        accumulated_interest,
        total_paid_interest,
        total_settlement_amount,
        input.state
    )
    .fetch_one(&mut *tx)
    .await?;

    for t in input.transactions.iter() {
        let date_parsed = epoch_to_utc(t.date)?;

        sqlx::query!(
            r#"
            INSERT INTO loan_transaction (
                contract_id, tenant_id, contact_id,
                transaction_type, amount, "date", note
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            "#,
            contract.id,
            tenant_id,
            input.contact_id,
            t.transaction_type,
            t.amount,
            date_parsed,
            t.note
        )
        .execute(&mut *tx)
        .await?;
    }

    tx.commit().await?;
    Ok(contract)
}

pub async fn update_contract(
    pool: &PgPool,
    tenant_id: Uuid,
    contract_id: Uuid,
    input: CreateContractInput,
) -> sqlx::Result<LoanContract> {
    let mut tx = pool.begin().await?;

    let updated = sqlx::query_as!(
        LoanContract,
        r#"
        UPDATE loan_contract
        SET
            contact_id = $1,
            name = $2,
            principal = $3,
            interest_rate = $4,
            term_months = $5,
            date_start = $6,
            date_end = $7,
            collateral_description = $8,
            collateral_value = $9,
            updated_at = NOW()
        WHERE id = $10 AND tenant_id = $11
        RETURNING id, tenant_id, contact_id, name, principal, interest_rate, term_months,
                  date_start, date_end, collateral_description, collateral_value,
                  storage_fee_rate, storage_fee, current_principal, current_interest,
                  accumulated_interest, total_paid_interest, total_settlement_amount,
                  state, created_at, updated_at
        "#,
        input.contact_id,
        input.name,
        input.principal,
        input.interest_rate,
        input.term_months,
        input.date_start,
        input.date_end,
        input.collateral_description,
        input.collateral_value.unwrap_or(0),
        contract_id,
        tenant_id,
    )
    .fetch_one(&mut *tx)
    .await?;

    sqlx::query!(
        "DELETE FROM loan_transaction WHERE contract_id = $1 AND tenant_id = $2",
        contract_id,
        tenant_id
    )
    .execute(&mut *tx)
    .await?;

    for t in input.transactions.iter() {
        let date_parsed = epoch_to_utc(t.date)?;
        sqlx::query!(
            r#"
            INSERT INTO loan_transaction (
                contract_id, tenant_id, contact_id,
                transaction_type, amount, "date", note
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7)
            "#,
            contract_id,
            tenant_id,
            input.contact_id,
            t.transaction_type,
            t.amount,
            date_parsed,
            t.note
        )
        .execute(&mut *tx)
        .await?;
    }

    tx.commit().await?;
    Ok(updated)
}

pub async fn delete_contract(
    pool: &PgPool,
    tenant_id: Uuid,
    contract_id: Uuid,
) -> sqlx::Result<()> {
    sqlx::query!(
        "DELETE FROM loan_contract WHERE id = $1 AND tenant_id = $2",
        contract_id,
        tenant_id
    )
    .execute(pool)
    .await?;
    Ok(())
}
