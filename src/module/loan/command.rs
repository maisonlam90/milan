use sqlx::PgPool;
use uuid::Uuid;
use chrono::{DateTime, Utc, NaiveDateTime};
use crate::module::loan::dto::CreateContractInput;
use crate::module::loan::model::LoanContract;

// Helper convert epoch seconds -> DateTime<Utc>
fn epoch_to_utc(ts: i64) -> Result<DateTime<Utc>, sqlx::Error> {
    let naive = NaiveDateTime::from_timestamp_opt(ts, 0)
        .ok_or_else(|| sqlx::Error::Protocol("Invalid timestamp".into()))?;
    Ok(DateTime::<Utc>::from_utc(naive, Utc))
}

pub async fn create_contract(
    pool: &PgPool,
    tenant_id: Uuid,
    input: CreateContractInput,
) -> sqlx::Result<LoanContract> {
    let mut tx = pool.begin().await?;

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
        RETURNING id, tenant_id, customer_id, name, principal, interest_rate, term_months,
                  date_start, date_end, collateral_description, collateral_value,
                  storage_fee_rate, storage_fee, current_principal, current_interest,
                  accumulated_interest, total_paid_interest, total_settlement_amount,
                  state, created_at, updated_at
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
    .fetch_one(&mut *tx)
    .await?;

    // 🚫 Không ghi các trường tính toán của transaction
    for t in input.transactions.iter() {
        let date_parsed = epoch_to_utc(t.date)?;

        sqlx::query!(
            r#"
            INSERT INTO loan_transaction (
                id, contract_id, tenant_id, customer_id,
                transaction_type, amount, date, note
                -- interest_for_period, accumulated_interest, principal_balance bỏ qua vì là computed
            )
            VALUES (
                uuid_generate_v4(), $1, $2, $3,
                $4, $5, $6, $7
            )
            "#,
            contract.id,
            tenant_id,
            input.customer_id,
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
            customer_id = $1,
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
        RETURNING id, tenant_id, customer_id, name, principal, interest_rate, term_months,
                  date_start, date_end, collateral_description, collateral_value,
                  storage_fee_rate, storage_fee, current_principal, current_interest,
                  accumulated_interest, total_paid_interest, total_settlement_amount,
                  state, created_at, updated_at
        "#,
        input.customer_id,
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

    // reset toàn bộ dòng giao dịch rồi insert lại dữ liệu gốc
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
                id, contract_id, tenant_id, customer_id,
                transaction_type, amount, date, note
                -- interest_for_period, accumulated_interest, principal_balance bỏ qua vì là computed
            )
            VALUES (
                uuid_generate_v4(), $1, $2, $3,
                $4, $5, $6, $7
            )
            "#,
            contract_id,
            tenant_id,
            input.customer_id,
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
