use chrono::{NaiveDate, Utc};
use crate::module::loan::model::{LoanContract, LoanTransaction};

pub fn calculate_interest_fields(contract: &mut LoanContract, transactions: &mut [LoanTransaction]) {
    let mut principal = contract.principal as f64;
    let mut accumulated_interest = 0.0;
    let mut prev_date = contract.date_start.naive_utc().date();

    let daily_rate = contract.interest_rate / 100.0 / 365.0;

    transactions.sort_by_key(|tx| (tx.date, tx.id));

    for tx in transactions.iter_mut() {
        let current_date = tx.date.naive_utc().date();
        let days = (current_date - prev_date).num_days().max(0);

        tx.days_from_prev = Some(days as i32);
        let interest = principal * daily_rate * (days as f64);
        tx.interest_for_period = Some(interest.round() as i64);
        accumulated_interest += interest;
        tx.accumulated_interest = Some(accumulated_interest.round() as i64);

        match tx.transaction_type.as_str() {
            "principal" | "additional" => {
                principal += tx.amount as f64;
            }
            _ => {}
        }

        tx.principal_balance = Some(principal.round() as i64);
        prev_date = current_date;
    }

    contract.current_principal = Some(principal.round() as i64);
    contract.accumulated_interest = Some(accumulated_interest.round() as i64);
    contract.total_paid_interest = Some(
        transactions
            .iter()
            .filter(|t| t.transaction_type == "interest" && t.amount < 0)
            .map(|t| -t.amount)
            .sum(),
    );
}
