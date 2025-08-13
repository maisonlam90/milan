//! calculator.rs
//! ---------------------------------------------
//! TÍNH LÃI TÍCH LŨY THEO DÒNG GIAO DỊCH (NOTEBOOK)
//! - Công thức lãi ngày: principal * (rate/100/365) * days
//! - Loại giao dịch (khớp metadata.rs):
//!     disbursement  -> giải ngân:      +gốc
//!     additional    -> vay thêm:       +gốc
//!     principal     -> thu gốc:        -gốc
//!     interest      -> thu lãi:        -lãi treo (không đụng gốc)
//!     liquidation   -> thanh lý:       trả lãi trước, còn dư trừ gốc
//!     settlement    -> tất toán:       trả lãi trước, còn dư trừ gốc
//! - Trường cập nhật trên mỗi dòng tx: days_from_prev, interest_for_period,
//!   accumulated_interest, principal_balance
//! - Trường cập nhật trên contract: current_principal, current_interest,
//!   accumulated_interest (tổng lãi phát sinh lịch sử), total_paid_interest
//!
//! LƯU Ý THIẾT KẾ (sharding-friendly):
//! - Không tính lãi trong SQL; chỉ lấy dữ liệu thô rồi tính ở app layer
//!   (tránh window function cross-shard, dễ đổi business rule).
//! - Không tạo dòng ảo.
//! - “Tính đến hôm nay” phải hiểu theo NGÀY KINH DOANH local (Asia/Bangkok) và
//!   theo kiểu EXCLUSIVE (không cộng +1 ngày).

use chrono::{DateTime, NaiveDate, Utc};
use chrono_tz::Asia::Bangkok; // 👈 cần `chrono-tz = "0.8"` trong Cargo.toml
// use uuid::Uuid; // không cần nữa nếu không tạo dòng ảo

use crate::module::loan::model::{LoanContract, LoanTransaction};

#[inline]
fn clamp_zero(x: f64) -> f64 {
    // Tiện ích: chặn âm về 0 cho các đại lượng như dư nợ, lãi treo
    if x < 0.0 { 0.0 } else { x }
}

#[inline]
fn biz_date(dt_utc: DateTime<Utc>) -> NaiveDate {
    // Chuyển thời điểm UTC -> NGÀY KINH DOANH theo Asia/Bangkok
    // để tránh lệch ngày gây cảm giác “+1”.
    dt_utc.with_timezone(&Bangkok).date_naive()
}

/// API tương thích cũ: tính đến thời điểm hiện tại (Utc::now()), không sinh “dòng ảo”
pub fn calculate_interest_fields(contract: &mut LoanContract, txs: &mut [LoanTransaction]) {
    let as_of = Utc::now();
    calculate_interest_fields_as_of(contract, txs, as_of);
}

/// Hàm chính: tính đến `as_of` (hôm nay local), nhưng:
/// - Nếu có `settlement/liquidation`, DỪNG tại NGÀY đó (không tính kỳ đuôi).
/// - Nếu KHÔNG có, cộng lãi đến HÔM NAY (EXCLUSIVE) → không +1 ngày.
pub fn calculate_interest_fields_as_of(
    contract: &mut LoanContract,
    txs: &mut [LoanTransaction],
    as_of: DateTime<Utc>,
) {
    // ===== 1) Khởi tạo biến trạng thái =====
    let mut principal: f64 = contract.principal as f64;         // Dư nợ gốc
    let mut accumulated_interest_total: f64 = 0.0;              // Tổng lãi phát sinh lịch sử
    let mut accrued_interest_unpaid: f64 = 0.0;                 // Lãi treo (chưa thu)
    let mut total_paid_interest: i64 = 0;                       // Tổng lãi đã thu
    let mut prev_date: NaiveDate = biz_date(contract.date_start); // Mốc tính lãi (ngày local)
    let daily_rate: f64 = (contract.interest_rate as f64) / 100.0 / 365.0;

    // Chốt “hôm nay” theo ngày local (Asia/Bangkok)
    // và (tuỳ chọn) không vượt quá contract.date_end nếu có.
    let mut today_local = biz_date(as_of);
    if let Some(end) = contract.date_end {
        let end_local = biz_date(end);
        if today_local > end_local {
            today_local = end_local;
        }
    }

    // Bảo đảm thứ tự giao dịch ổn định: theo (date, id)
    txs.sort_by_key(|tx| (tx.date, tx.id));

    // Mốc dừng nếu gặp settlement/liquidation
    let mut stop_at: Option<NaiveDate> = None;

    // ===== 2) Duyệt từng giao dịch =====
    for tx in txs.iter_mut() {
        // NGÀY giao dịch theo local để tránh lệch ngày
        let cur = biz_date(tx.date);

        // 2.1) Số ngày giữa giao dịch này và mốc trước (EXCLUSIVE cur)
        // Ví dụ: prev=10, cur=13 => days = 3 (11,12,13? KHÔNG. Công thức .num_days() đã exclusive cur 0h local)
        let days = (cur - prev_date).num_days().max(0);
        tx.days_from_prev = Some(days as i32);

        // 2.2) Lãi phát sinh trong khoảng đó
        let interest = principal * daily_rate * (days as f64);

        // Cập nhật các bộ đếm lãi
        accumulated_interest_total += interest;
        accrued_interest_unpaid += interest;

        // Ghi xuống dòng giao dịch
        tx.interest_for_period = Some(interest.round() as i64);
        tx.accumulated_interest = Some(accumulated_interest_total.round() as i64);

        // 2.3) Áp dụng số tiền theo loại giao dịch
        let amt = tx.amount as f64;
        match tx.transaction_type.as_str() {
            // Giải ngân / vay thêm => tăng dư nợ gốc
            "disbursement" | "additional" => {
                principal += amt;
                principal = clamp_zero(principal);
            }
            // Thu gốc => giảm dư nợ gốc, KHÔNG đụng lãi treo
            "principal" => {
                principal -= amt.abs();
                principal = clamp_zero(principal);
            }
            // Thu lãi => trừ lãi treo, không đụng gốc
            "interest" => {
                let pay = amt.abs();
                let applied = pay.min(clamp_zero(accrued_interest_unpaid));
                accrued_interest_unpaid -= applied;
                total_paid_interest += applied.round() as i64;
            }
            // Thanh lý / Tất toán => trả lãi trước, phần dư trừ gốc
            "liquidation" | "settlement" => {
                let mut pay_left = amt.abs();

                // Trả lãi treo trước
                let applied_interest = pay_left.min(clamp_zero(accrued_interest_unpaid));
                accrued_interest_unpaid -= applied_interest;
                total_paid_interest += applied_interest.round() as i64;
                pay_left -= applied_interest;

                // Phần còn lại (nếu có) trừ vào gốc
                if pay_left > 0.0 {
                    principal -= pay_left;
                    principal = clamp_zero(principal);
                }

                // ✅ Đặt mốc dừng tại NGÀY giao dịch này (local)
                stop_at = Some(cur);
            }
            // Loại khác/không xác định: bỏ qua (không thay đổi số dư)
            _ => {}
        }

        // 2.4) Ghi dư nợ gốc sau khi áp dụng giao dịch
        tx.principal_balance = Some(principal.round() as i64);

        // 2.5) Dời mốc sang ngày giao dịch hiện tại (local)
        prev_date = cur;

        // ✅ Nếu đã gặp settlement/liquidation thì không xét các giao dịch sau
        if stop_at.is_some() {
            break;
        }
    }

    // ===== 3) KỲ LÃI "ĐUÔI" =====
    // - Nếu có stop_at: KHÔNG cộng thêm kỳ đuôi.
    // - Nếu KHÔNG có: cộng lãi từ giao dịch cuối tới HÔM NAY (local, EXCLUSIVE).
    if stop_at.is_none() && today_local > prev_date {
        // EXCLUSIVE: chỉ tính số ngày giữa prev_date và hôm nay 0h local; KHÔNG +1.
        let tail_days = (today_local - prev_date).num_days();
        let tail_interest = principal * daily_rate * (tail_days as f64);
        accumulated_interest_total += tail_interest;
        accrued_interest_unpaid += tail_interest;
    }

    // ===== 4) Ghi kết quả cuối cùng lên hợp đồng =====
    contract.current_principal   = Some(principal.round() as i64);                     // dư nợ gốc hiện tại
    contract.accumulated_interest = Some(accumulated_interest_total.round() as i64);   // tổng lãi phát sinh lịch sử
    contract.current_interest    = Some(clamp_zero(accrued_interest_unpaid).round() as i64); // lãi đang treo
    contract.total_paid_interest = Some(total_paid_interest);                          // lãi KH đã trả
}
