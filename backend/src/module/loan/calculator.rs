use chrono::{DateTime, NaiveDate, Utc};
use chrono_tz::Asia::Bangkok;
use crate::module::loan::model::{LoanContract, LoanTransaction};

#[inline]
fn clamp_zero(x: f64) -> f64 { if x < 0.0 { 0.0 } else { x } }
#[inline]
fn biz_date(dt_utc: DateTime<Utc>) -> NaiveDate { dt_utc.with_timezone(&Bangkok).date_naive() }

pub fn calculate_interest_fields(contract: &mut LoanContract, txs: &mut [LoanTransaction]) {
    calculate_interest_fields_as_of(contract, txs, Utc::now());
}

pub fn calculate_interest_fields_as_of(
    contract: &mut LoanContract,
    txs: &mut [LoanTransaction],
    as_of: DateTime<Utc>,
) {
    let mut principal: f64 = 0.0;
    let mut accumulated_interest_total: f64 = 0.0;
    let mut accrued_interest_unpaid: f64 = 0.0;
    let mut total_paid_interest: i64 = 0;
    let mut total_paid_principal: i64 = 0; // 👈 mới

    let mut prev_date: NaiveDate = biz_date(contract.date_start);
    let daily_rate: f64 = (contract.interest_rate as f64) / 100.0 / 365.0;

    let mut today_local = biz_date(as_of);
    if let Some(end) = contract.date_end {
        let end_local = biz_date(end);
        if today_local > end_local { today_local = end_local; }
    }

    // đảm bảo order ổn định
    txs.sort_by_key(|tx| (tx.date, tx.id));
    let mut stop_at: Option<NaiveDate> = None;

    for tx in txs.iter_mut() {
        let cur = biz_date(tx.date);

        // reset projection per-tx
        tx.principal_applied = 0;
        tx.interest_applied  = 0;

        let days = (cur - prev_date).num_days().max(0);
        tx.days_from_prev = days as i32;

        // tính lãi dồn tới ngày txn
        let interest = principal * daily_rate * (days as f64);
        accumulated_interest_total += interest;
        accrued_interest_unpaid += interest;

        tx.interest_for_period  = interest.round() as i64;
        tx.accumulated_interest = accumulated_interest_total.round() as i64;

        let amt = tx.amount as f64;
        match tx.transaction_type.as_str() {
            "disbursement" | "additional" => {
                principal += amt;
                principal = clamp_zero(principal);
                // không áp vào lãi/gốc đã trả
            }
            "principal" => {
                // toàn bộ amount (abs) là trả gốc, nhưng không vượt quá dư nợ
                let pay_p = amt.abs().min(principal);
                principal -= pay_p;
                principal = clamp_zero(principal);

                tx.principal_applied = pay_p.round() as i64;       // 👈 projection
                total_paid_principal += tx.principal_applied;       // 👈 cộng dồn
            }
            "interest" => {
                let pay_i = amt.abs().min(clamp_zero(accrued_interest_unpaid));
                accrued_interest_unpaid -= pay_i;

                tx.interest_applied = pay_i.round() as i64;         // 👈 projection
                total_paid_interest += tx.interest_applied;          // field có sẵn
            }
            "liquidation" | "settlement" => {
                // trả lãi treo trước
                let mut pay_left = amt.abs();
                let applied_interest = pay_left.min(clamp_zero(accrued_interest_unpaid));
                accrued_interest_unpaid -= applied_interest;
                tx.interest_applied = applied_interest.round() as i64;
                total_paid_interest += tx.interest_applied;

                pay_left -= applied_interest;
                if pay_left > 0.0 {
                    let applied_principal = pay_left.min(principal);
                    principal -= applied_principal;
                    principal = clamp_zero(principal);

                    tx.principal_applied = applied_principal.round() as i64; // 👈 projection
                    total_paid_principal += tx.principal_applied;            // 👈 cộng dồn
                }
                stop_at = Some(cur);
            }
            _ => {}
        }

        tx.principal_balance = principal.round() as i64;
        prev_date = cur;

        if stop_at.is_some() { break; }
    }

    if stop_at.is_none() && today_local > prev_date {
        let tail_days = (today_local - prev_date).num_days();
        let tail_interest = principal * daily_rate * (tail_days as f64);
        accumulated_interest_total += tail_interest;
        accrued_interest_unpaid += tail_interest;
    }

    contract.current_principal    = principal.round() as i64;
    contract.accumulated_interest = accumulated_interest_total.round() as i64;
    contract.current_interest     = clamp_zero(accrued_interest_unpaid).round() as i64;
    contract.total_paid_interest  = total_paid_interest;

    // 👇 gán projection tổng “gốc đã trả” để FE hiển thị
    contract.total_paid_principal = total_paid_principal;
    // 👇 Thêm dòng này để BE trả luôn số tiền còn phải trả
    contract.payoff_due = contract.current_principal + contract.current_interest;
}

/// Tính số tiền cần trả để tất toán tại thời điểm `as_of`,
/// dựa trên trạng thái hợp đồng + dãy giao dịch đã diễn ra TRƯỚC thời điểm tất toán.
/// Công thức:
/// amount = current_principal + current_interest
///        + storage_fee_for_period (nếu có)
pub fn settlement_quote_as_of(
    contract: &LoanContract,
    txs_prefix: &mut [LoanTransaction],
    as_of: DateTime<Utc>,
) -> i64 {
    // Clone để tính toán "what-if" không làm bẩn state gốc
    let mut c = contract.clone();
    calculate_interest_fields_as_of(&mut c, txs_prefix, as_of);

    // ✅ Bỏ phần tính phí lưu kho theo collateral_value
    let amount = c.current_principal + c.current_interest;

    amount.max(0)
}


pub fn principal_paid_as_of(
    contract: &crate::module::loan::model::LoanContract,
    txs: &[LoanTransaction],
    as_of: DateTime<Utc>,
) -> i64 {
    // Sắp theo thời gian để tính đúng trình tự
    let mut items: Vec<&LoanTransaction> = txs.iter().collect();
    items.sort_by_key(|tx| (tx.date, tx.id));

    let daily_rate = (contract.interest_rate as f64) / 100.0 / 365.0;
    let mut principal: f64 = 0.0;
    let mut accrued_interest_unpaid: f64 = 0.0;
    let mut paid_principal_total: i64 = 0;

    // hàm ngày business theo Asia/Bangkok, giống file gốc
    fn biz_date_local(dt_utc: DateTime<Utc>) -> chrono::NaiveDate {
        use chrono_tz::Asia::Bangkok;
        dt_utc.with_timezone(&Bangkok).date_naive()
    }

    let mut prev_date = biz_date_local(contract.date_start);
    // dừng ở as_of (nếu giao dịch sau as_of thì bỏ qua)
    for tx in items {
        if tx.date > as_of { break; }

        let cur = biz_date_local(tx.date);
        let days = (cur - prev_date).num_days().max(0) as f64;

        // cộng lãi dồn đến ngày giao dịch
        accrued_interest_unpaid += principal * daily_rate * days;

        match tx.transaction_type.as_str() {
            "disbursement" | "additional" => {
                principal += tx.amount as f64;
                principal = clamp_zero(principal);
            }
            "principal" => {
                let p = (tx.amount as f64).abs();
                let applied = p.min(principal);
                principal -= applied;
                principal = clamp_zero(principal);
                paid_principal_total += applied.round() as i64;
            }
            "interest" => {
                let pay = (tx.amount as f64).abs();
                let applied = pay.min(clamp_zero(accrued_interest_unpaid));
                accrued_interest_unpaid -= applied;
            }
            "liquidation" | "settlement" => {
                let mut pay_left = (tx.amount as f64).abs();
                // trả lãi trước
                let applied_int = pay_left.min(clamp_zero(accrued_interest_unpaid));
                accrued_interest_unpaid -= applied_int;
                pay_left -= applied_int;
                // phần còn lại trừ vào gốc
                if pay_left > 0.0 {
                    let applied_principal = pay_left.min(principal);
                    principal -= applied_principal;
                    principal = clamp_zero(principal);
                    paid_principal_total += applied_principal.round() as i64;
                }
                // tất toán là điểm dừng logic — có thể break nếu muốn
            }
            _ => {}
        }

        prev_date = cur;
    }

    paid_principal_total
}