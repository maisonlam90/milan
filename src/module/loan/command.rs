use sqlx::PgPool;
use uuid::Uuid;
use chrono::{DateTime, Utc};
use crate::module::loan::dto::CreateContractInput;
use crate::module::loan::model::LoanContract;
use crate::module::loan::model::LoanTransaction;
use crate::module::loan::calculator::settlement_quote_as_of;
use crate::module::loan::calculator::calculate_interest_fields_as_of;
use crate::core::error::{AppError, ErrorResponse};

// epoch seconds -> DateTime<Utc>
fn epoch_to_utc(ts: i64) -> Result<DateTime<Utc>, sqlx::Error> {
    DateTime::<Utc>::from_timestamp(ts, 0)
        .ok_or_else(|| sqlx::Error::Protocol("Invalid timestamp".into()))
}

pub async fn create_contract(
    pool: &PgPool,
    tenant_id: Uuid,
    input: CreateContractInput,
) -> Result<LoanContract, AppError> {
    if input.transactions.is_empty() {
        return Err(AppError::Validation(ErrorResponse {
            code: "transactions_empty",
            message: "Phải có ít nhất 1 giao dịch".into(),
        }));
    }

    let mut tx = pool.begin().await?;

    let collateral_value = input.collateral_value.unwrap_or(0);
    let storage_fee_rate = input.storage_fee_rate.unwrap_or(0.0);
    let storage_fee = input.storage_fee.unwrap_or(0);
    let current_principal = input.current_principal.unwrap_or(0);
    let current_interest = input.current_interest.unwrap_or(0);
    let accumulated_interest = input.accumulated_interest.unwrap_or(0);
    let total_paid_interest = input.total_paid_interest.unwrap_or(0);
    let total_settlement_amount = input.total_settlement_amount.unwrap_or(0);
    let shared_with = input.shared_with.as_deref().unwrap_or(&[]);

    let contract = sqlx::query_as!(
        LoanContract,
        r#"
        INSERT INTO loan_contract (
            tenant_id, contact_id, name, interest_rate, term_months,
            date_start, date_end, collateral_description, collateral_value,
            storage_fee_rate, storage_fee, current_principal, current_interest,
            accumulated_interest, total_paid_interest, total_settlement_amount,
            state, created_by, assignee_id, shared_with
        )
        VALUES (
            $1, $2, $3, $4, $5,
            $6, $7, $8, $9, $10,
            $11, $12, $13, $14, $15,
            $16, $17, $18, $19, $20
        )
        RETURNING
            id, tenant_id, contact_id, name,
            interest_rate, term_months,
            date_start, date_end,
            collateral_description, collateral_value,
            storage_fee_rate, storage_fee,
            current_principal, current_interest,
            accumulated_interest, total_paid_interest, total_settlement_amount,
            state, created_at, updated_at,
            created_by, assignee_id, shared_with,
            0::int8 AS "total_paid_principal!",
            0::int8 AS "payoff_due!"
        "#,
        tenant_id,
        input.contact_id,
        input.name,
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
        input.state,
        input.created_by,
        input.assignee_id,
        shared_with
    )
    .fetch_one(&mut *tx)
    .await?;

    // dãy giao dịch đã “diễn ra” để tính trạng thái dồn
    let mut prefix: Vec<LoanTransaction> = Vec::new();

    for t in input.transactions.iter() {
        let date_parsed = epoch_to_utc(t.date)?;

        // Tính trạng thái đến thời điểm giao dịch rồi VALIDATE
        let mut c_copy = contract.clone();
        let mut txs_copy = prefix.clone();
        calculate_interest_fields_as_of(&mut c_copy, &mut txs_copy, date_parsed);

        match t.transaction_type.as_str() {
            "interest" => {
                if t.amount > c_copy.current_interest {
                    return Err(AppError::Validation(ErrorResponse {
                        code: "interest_overpaid",
                        message: "Số tiền thu lãi vượt quá lãi hiện tại".to_string(),
                    }));
                }
            }
            "principal" => {
                if t.amount > c_copy.current_principal {
                    return Err(AppError::Validation(ErrorResponse {
                        code: "principal_overpaid",
                        message: "Số tiền thu gốc vượt quá dư nợ gốc".to_string(),
                    }));
                }
            }
            _ => {}
        }

        let computed_amount = if t.transaction_type == "settlement" {
            settlement_quote_as_of(&contract, &mut prefix, date_parsed)
        } else {
            t.amount
        };

        sqlx::query!(
            r#"
            INSERT INTO loan_transaction (
                contract_id, tenant_id, contact_id,
                transaction_type, amount, "date", note,
                created_by, assignee_id, shared_with
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            "#,
            contract.id,
            tenant_id,
            input.contact_id,
            t.transaction_type,
            computed_amount,
            date_parsed,
            t.note,
            input.created_by,
            input.assignee_id,
            shared_with
        )
        .execute(&mut *tx)
        .await?;

        // cập nhật prefix cho giao dịch kế tiếp
        prefix.push(LoanTransaction {
            id: Uuid::new_v4(),
            contract_id: contract.id,
            tenant_id,
            contact_id: input.contact_id,
            transaction_type: t.transaction_type.clone(),
            amount: computed_amount,
            date: date_parsed,
            note: t.note.clone(),
            days_from_prev: 0,
            interest_for_period: 0,
            accumulated_interest: 0,
            principal_balance: 0,
            principal_applied: 0,
            interest_applied: 0,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        });
    }

    tx.commit().await?;
    Ok(contract)
}
pub async fn update_contract(
    pool: &PgPool,
    tenant_id: Uuid,
    contract_id: Uuid,
    input: CreateContractInput,
) -> Result<LoanContract, AppError> {
    if input.transactions.is_empty() {
        return Err(AppError::Validation(ErrorResponse {
            code: "transactions_empty",
            message: "Phải có ít nhất 1 giao dịch".into(),
        }));
    }

    let mut tx = pool.begin().await?;
    let shared_with = input.shared_with.as_deref().unwrap_or(&[]);

    let updated = sqlx::query_as!(
        LoanContract,
        r#"
        UPDATE loan_contract
        SET
            contact_id = $1,
            name = $2,
            interest_rate = $3,
            term_months = $4,
            date_start = $5,
            date_end = $6,
            collateral_description = $7,
            collateral_value = $8,
            assignee_id = $9,
            shared_with = $10,
            updated_at = NOW()
        WHERE id = $11 AND tenant_id = $12
        RETURNING
            id, tenant_id, contact_id, name,
            interest_rate, term_months,
            date_start, date_end,
            collateral_description, collateral_value,
            storage_fee_rate, storage_fee,
            current_principal, current_interest,
            accumulated_interest, total_paid_interest, total_settlement_amount,
            state, created_at, updated_at,
            created_by, assignee_id, shared_with,
            0::int8 AS "total_paid_principal!",
            0::int8 AS "payoff_due!"
        "#,
        input.contact_id,
        input.name,
        input.interest_rate,
        input.term_months,
        input.date_start,
        input.date_end,
        input.collateral_description,
        input.collateral_value.unwrap_or(0),
        input.assignee_id,
        shared_with,
        contract_id,
        tenant_id,
    )
    .fetch_one(&mut *tx)
    .await?;

    // xoá-ghi lại transactions
    sqlx::query!(
        "DELETE FROM loan_transaction WHERE contract_id = $1 AND tenant_id = $2",
        contract_id,
        tenant_id
    )
    .execute(&mut *tx)
    .await?;

    let mut prefix: Vec<LoanTransaction> = Vec::new();

    for t in input.transactions.iter() {
        let date_parsed = epoch_to_utc(t.date)?;

        // Tính trạng thái đến thời điểm giao dịch rồi VALIDATE
        let mut c_copy = updated.clone();
        let mut txs_copy = prefix.clone();
        calculate_interest_fields_as_of(&mut c_copy, &mut txs_copy, date_parsed);

        match t.transaction_type.as_str() {
            "interest" => {
                if t.amount > c_copy.current_interest {
                    return Err(AppError::Validation(ErrorResponse {
                        code: "interest_overpaid",
                        message: "Số tiền thu lãi vượt quá lãi hiện tại".to_string(),
                    }));
                }
            }
            "principal" => {
                if t.amount > c_copy.current_principal {
                    return Err(AppError::Validation(ErrorResponse {
                        code: "principal_overpaid",
                        message: "Số tiền thu gốc vượt quá dư nợ gốc".to_string(),
                    }));
                }
            }
            _ => {}
        }

        let computed_amount = if t.transaction_type == "settlement" {
            settlement_quote_as_of(&updated, &mut prefix, date_parsed)
        } else {
            t.amount
        };

        sqlx::query!(
            r#"
            INSERT INTO loan_transaction (
                contract_id, tenant_id, contact_id,
                transaction_type, amount, "date", note,
                created_by, assignee_id, shared_with
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            "#,
            contract_id,
            tenant_id,
            input.contact_id,
            t.transaction_type,
            computed_amount,
            date_parsed,
            t.note,
            input.created_by,
            input.assignee_id,
            shared_with
        )
        .execute(&mut *tx)
        .await?;

        prefix.push(LoanTransaction {
            id: Uuid::new_v4(),
            contract_id,
            tenant_id,
            contact_id: input.contact_id,
            transaction_type: t.transaction_type.clone(),
            amount: computed_amount,
            date: date_parsed,
            note: t.note.clone(),
            days_from_prev: 0,
            interest_for_period: 0,
            accumulated_interest: 0,
            principal_balance: 0,
            principal_applied: 0,
            interest_applied: 0,
            created_at: Utc::now(),
            updated_at: Utc::now(),
        });
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
