use sqlx::{PgPool, query_as};
use uuid::Uuid;
use crate::module::loan::model::{LoanContract, LoanTransaction};

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

pub async fn get_transactions_by_contract(
    pool: &PgPool,
    tenant_id: Uuid,
    contract_id: Uuid,
) -> Result<Vec<LoanTransaction>, sqlx::Error> {
    //
    // Công thức “tính bừa” (để có số liệu hiển thị):
    // - days_from_prev = GREATEST(CURRENT_DATE - lt.date::date, 0)
    // - daily_rate     = lc.interest_rate / 100 / 365
    // - principal_balance (running) = lc.principal + SUM(lt.amount) over (order by date, id)
    // - interest_for_period = principal_balance * daily_rate * days_from_prev
    // - accumulated_interest (running SUM over interest_for_period)
    //
    // Tất cả đều ép kiểu về INT/BIGINT để tránh yêu cầu feature `bigdecimal` của sqlx.
    //
    let rows = query_as!(
        LoanTransaction,
        r#"
        WITH tx AS (
            SELECT
                lt.id,
                lt.contract_id,
                lt.tenant_id,
                lt.customer_id,
                lt.transaction_type,
                lt.amount,
                lt.date,
                lt.note,
                lc.principal                                  AS contract_principal,
                (lc.interest_rate / 100.0 / 365.0)            AS daily_rate,           -- numeric (chỉ dùng nội bộ)
                GREATEST((CURRENT_DATE - lt.date::date), 0)   AS days_from_prev_i,     -- int
                lt.created_at,
                lt.updated_at
            FROM loan_transaction lt
            JOIN loan_contract lc
              ON lc.id = lt.contract_id
             AND lc.tenant_id = lt.tenant_id
            WHERE lt.tenant_id = $1
              AND lt.contract_id = $2
        ), enriched AS (
            SELECT
                id,
                contract_id,
                tenant_id,
                customer_id,
                transaction_type,
                amount,
                date,
                note,
                created_at,
                updated_at,
                -- running principal = principal gốc + cộng dồn amount theo thời gian
                (contract_principal
                 + SUM(amount) OVER (PARTITION BY contract_id ORDER BY date, id
                                     ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                )::bigint AS principal_balance_i,
                (days_from_prev_i)::int AS days_from_prev_i,
                daily_rate
            FROM tx
        ), calc AS (
            SELECT
                id,
                contract_id,
                tenant_id,
                customer_id,
                transaction_type,
                amount,
                date,
                note,
                created_at,
                updated_at,
                days_from_prev_i,
                principal_balance_i,
                -- interest_for_period ép về BIGINT để không cần NUMERIC ra ngoài
                ((principal_balance_i::numeric * daily_rate * (days_from_prev_i)::numeric))::bigint
                    AS interest_for_period_i
            FROM enriched
        ), final AS (
            SELECT
                id,
                contract_id,
                tenant_id,
                customer_id,
                transaction_type,
                amount,
                date,
                note,
                created_at,
                updated_at,
                days_from_prev_i,
                principal_balance_i,
                interest_for_period_i,
                -- SUM(bigint) -> numeric trong PG/YB, ép lại BIGINT để tránh bigdecimal
                (SUM(interest_for_period_i) OVER (PARTITION BY contract_id ORDER BY date, id))::bigint
                    AS accumulated_interest_i
            FROM calc
        )
        SELECT
            id,
            contract_id,
            tenant_id,
            customer_id,
            transaction_type,
            amount,
            date,
            note,
            -- ⚠️ Nếu struct LoanTransaction dùng Non-Option, đổi ? -> !
            (days_from_prev_i)::int          AS "days_from_prev?",
            (interest_for_period_i)::bigint  AS "interest_for_period?",
            (accumulated_interest_i)::bigint AS "accumulated_interest?",
            (principal_balance_i)::bigint    AS "principal_balance?",
            created_at,
            updated_at
        FROM final
        ORDER BY date ASC, id ASC
        "#,
        tenant_id,
        contract_id
    )
    .fetch_all(pool)
    .await?;

    Ok(rows)
}
