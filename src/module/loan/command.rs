use sqlx::{PgPool, PgConnection};
use uuid::Uuid;
use chrono::{DateTime, Utc, Datelike};
use crate::module::loan::dto::CreateContractInput;
use crate::module::loan::model::LoanContract;
use crate::module::loan::model::LoanTransaction;
use crate::module::loan::calculator::settlement_quote_as_of;
use crate::module::loan::calculator::calculate_interest_fields_as_of;
use crate::core::error::{AppError, ErrorResponse};
use crate::module::loan::dto::CreateCollateralDto;

// epoch seconds -> DateTime<Utc>
fn epoch_to_utc(ts: i64) -> Result<DateTime<Utc>, sqlx::Error> {
    DateTime::<Utc>::from_timestamp(ts, 0)
        .ok_or_else(|| sqlx::Error::Protocol("Invalid timestamp".into()))
}

pub async fn create_contract(
    pool: &PgPool,
    tenant_id: Uuid,
    mut input: CreateContractInput,
) -> Result<LoanContract, AppError> {
    if input.transactions.is_empty() {
        return Err(AppError::Validation(ErrorResponse {
            code: "transactions_empty",
            message: "Phải có ít nhất 1 giao dịch".into(),
        }));
    }

    let mut tx = pool.begin().await?;

    let contract_number = generate_contract_number_monthly(
        tx.as_mut(),
        tenant_id,
        None,
    ).await?;

    let storage_fee_rate = input.storage_fee_rate.unwrap_or(0.0);
    let storage_fee = input.storage_fee.unwrap_or(0);
    let current_principal = input.current_principal.unwrap_or(0);
    let current_interest = input.current_interest.unwrap_or(0);
    let accumulated_interest = input.accumulated_interest.unwrap_or(0);
    let total_paid_interest = input.total_paid_interest.unwrap_or(0);
    let total_settlement_amount = input.total_settlement_amount.unwrap_or(0);
    let shared_with = input.shared_with.as_deref().unwrap_or(&[]);

    // 👉 Tự động xác định trạng thái ban đầu
    let mut state = "Nháp".to_string();
    if !input.transactions.is_empty() {
        state = "Hoạt động".to_string();
        for t in &input.transactions {
            match t.transaction_type.as_str() {
                "liquidation" => {
                    state = "Đã thanh lý".to_string();
                    break;
                }
                "settlement" => {
                    state = "Đã tất toán".to_string();
                    // vẫn tiếp tục vòng lặp để ưu tiên "liquidated" nếu có
                }
                _ => {}
            }
        }
    }

    let contract = sqlx::query_as!(
        LoanContract,
        r#"
        INSERT INTO loan_contract (
            tenant_id, contact_id, contract_number, interest_rate, term_months,
            date_start, date_end,
            storage_fee_rate, storage_fee, current_principal, current_interest,
            accumulated_interest, total_paid_interest, total_settlement_amount,
            state, created_by, assignee_id, shared_with
        )
        VALUES (
            $1, $2, $3, $4, $5,
            $6, $7,
            $8, $9, $10, $11,
            $12, $13, $14,
            $15, $16, $17, $18
        )
        RETURNING
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
        "#,
        tenant_id,
        input.contact_id,
        contract_number,
        input.interest_rate,
        input.term_months,
        input.date_start,
        input.date_end,
        storage_fee_rate,
        storage_fee,
        current_principal,
        current_interest,
        accumulated_interest,
        total_paid_interest,
        total_settlement_amount,
        state,
        input.created_by,
        input.assignee_id,
        shared_with
    )
    .fetch_one(tx.as_mut())
    .await?;

    // Lưu giao dịch
    let mut prefix: Vec<LoanTransaction> = Vec::new();
    for t in input.transactions.iter() {
        let date_parsed = epoch_to_utc(t.date)?;
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
        .execute(tx.as_mut())
        .await?;

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

    // 👉 Tự động cập nhật trạng thái theo giao dịch
    let mut state = "Nháp".to_string();
    if !input.transactions.is_empty() {
        state = "Hoạt động".to_string();
        for t in &input.transactions {
            match t.transaction_type.as_str() {
                "liquidation" => {
                    state = "Đã thanh lý".to_string();
                    break;
                }
                "settlement" => {
                    state = "Đã tất toán".to_string();
                    // vẫn tiếp tục vòng lặp để ưu tiên "liquidated" nếu có
                }
                _ => {}
            }
        }
    }

    let updated = sqlx::query_as!(
        LoanContract,
        r#"
        UPDATE loan_contract
        SET
            contact_id = $1,
            interest_rate = $2,
            term_months = $3,
            date_start = $4,
            date_end = $5,
            assignee_id = $6,
            shared_with = $7,
            state = $8,
            updated_at = NOW()
        WHERE id = $9 AND tenant_id = $10
        RETURNING
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
        "#,
        input.contact_id,
        input.interest_rate,
        input.term_months,
        input.date_start,
        input.date_end,
        input.assignee_id,
        shared_with,
        state,
        contract_id,
        tenant_id,
    )
    .fetch_one(tx.as_mut())
    .await?;

    sqlx::query!(
        "DELETE FROM loan_transaction WHERE contract_id = $1 AND tenant_id = $2",
        contract_id,
        tenant_id
    )
    .execute(tx.as_mut())
    .await?;

    let mut prefix: Vec<LoanTransaction> = Vec::new();
    for t in input.transactions.iter() {
        let date_parsed = epoch_to_utc(t.date)?;
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
        .execute(tx.as_mut())
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

pub async fn create_collateral(
    pool: &PgPool,
    tenant_id: Uuid,
    input: CreateCollateralDto,
    contract_id: Uuid,
    created_by: Uuid,
) -> Result<(), AppError> {
    // Tạo tài sản vào bảng collateral_assets (nếu cần)
    let asset = sqlx::query!(
        r#"
        INSERT INTO collateral_assets (
            tenant_id, asset_id, asset_type, description, value_estimate, status, created_by, created_at
        )
        VALUES ($1, gen_random_uuid(), $2, $3, $4, $5, $6, NOW())
        RETURNING asset_id
        "#,
        tenant_id,
        input.asset_type,
        input.description,
        input.value_estimate,
        input.status.unwrap_or("available".to_string()),
        created_by
    )
    .fetch_one(pool)
    .await?;

    // Ghi liên kết vào bảng loan_collateral
    sqlx::query!(
        r#"
        INSERT INTO loan_collateral (
            tenant_id, contract_id, asset_id, status, created_by, created_at
        )
        VALUES ($1, $2, $3, 'active', $4, NOW())
        "#,
        tenant_id,
        contract_id,
        asset.asset_id,
        created_by
    )
    .execute(pool)
    .await?;

    Ok(())
}

/// Sinh số HĐ dạng LOAN-{tenant}-{YYYYMM}-{000001}, reset theo **tháng hiện tại**
pub async fn generate_contract_number_monthly(
    conn: &mut PgConnection,
    tenant_id: Uuid,
    tenant_code: Option<String>,
) -> Result<String, sqlx::Error> {
    // 🕒 Lấy ngày hiện tại theo UTC.
    // Nếu muốn theo giờ VN (Asia/Bangkok), xem chú thích bên dưới.
    let d = Utc::now().date_naive();
    let period_ym: i32 = d.year() * 100 + (d.month() as i32);

    // UPSERT counter cho (tenant_id, period_ym)
    let no: i64 = sqlx::query_scalar(
        r#"
        INSERT INTO loan_counters_monthly (tenant_id, period_ym, counter, updated_at)
        VALUES ($1, $2, 1, now())
        ON CONFLICT (tenant_id, period_ym) DO UPDATE
          SET counter = loan_counters_monthly.counter + 1,
              updated_at = now()
        RETURNING counter
        "#
    )
    .bind(tenant_id)
    .bind(period_ym)
    .fetch_one(conn)
    .await?;

    // code tenant: ưu tiên tenant_code, fallback 5 ký tự đầu UUID
    let code: String = tenant_code.unwrap_or_else(|| tenant_id.to_string()[..5].to_string());
    Ok(format!("LOAN-{}-{:04}{:02}-{:06}", code, d.year(), d.month(), no))
}

/*
🔁 Nếu muốn THÁNG/TZ theo Việt Nam thay vì UTC:
1) Thêm vào Cargo.toml:
   chrono-tz = "0.8"

2) Thay 2 dòng trong hàm trên:
   use chrono_tz::Asia::Bangkok;
   let d = Utc::now().with_timezone(&Bangkok).date_naive();
*/
