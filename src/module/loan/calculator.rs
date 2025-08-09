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
//! - Hàm nhận `as_of` để tính “kỳ đuôi” tới hiện tại; có thể tạo “dòng ảo”
//!   giúp người dùng nhìn thấy rõ phần lãi phát sinh đến hôm nay.

use chrono::{DateTime, NaiveDate, Utc};
use uuid::Uuid;

use crate::module::loan::model::{LoanContract, LoanTransaction};

#[inline]
fn clamp_zero(x: f64) -> f64 {
    // Tiện ích: chặn âm về 0 cho các đại lượng như dư nợ, lãi treo
    if x < 0.0 { 0.0 } else { x }
}

/// API tương thích cũ: tính đến thời điểm hiện tại (Utc::now()), không sinh “dòng ảo”
/// Dùng nếu bạn chưa sửa handler để truyền `as_of`.
pub fn calculate_interest_fields(contract: &mut LoanContract, txs: &mut [LoanTransaction]) {
    let as_of = Utc::now();
    let _ = calculate_interest_fields_as_of(contract, txs, as_of, false);
}

/// Hàm chính: tính đến `as_of`.
/// - `append_virtual_row = true` => trả về một dòng giao dịch ảo (không lưu DB)
///   mô tả phần lãi phát sinh từ giao dịch cuối cùng tới `as_of` để UI hiển thị rõ ràng.
/// - Hàm trả `Option<LoanTransaction>`: Some(dòng_ảo) nếu có “kỳ đuôi” > 0 ngày.
pub fn calculate_interest_fields_as_of(
    contract: &mut LoanContract,
    txs: &mut [LoanTransaction],
    as_of: DateTime<Utc>,
    append_virtual_row: bool,
) -> Option<LoanTransaction> {
    // ===== 1) Khởi tạo biến trạng thái =====

    // Dư nợ gốc hiện tại (dùng f64 để tính; cuối cùng round về i64)
    let mut principal: f64 = contract.principal as f64;

    // Tổng lãi đã phát sinh toàn bộ lịch sử (không trừ đi phần đã trả)
    let mut accumulated_interest_total: f64 = 0.0;

    // Lãi đang treo: lãi phát sinh - lãi đã thu (chưa trả hết)
    let mut accrued_interest_unpaid: f64 = 0.0;

    // Tổng lãi đã thu (để hiển thị và kiểm toán)
    let mut total_paid_interest: i64 = 0;

    // Mốc ngày bắt đầu tính lãi (ngày giải ngân)
    let mut prev_date: NaiveDate = contract.date_start.naive_utc().date();

    // Lãi suất theo ngày
    let daily_rate: f64 = (contract.interest_rate as f64) / 100.0 / 365.0;

    // Chuẩn hoá `as_of`: nếu có `date_end` trên hợp đồng, không tính vượt quá ngày này
    let as_of_date = {
        let cap = contract.date_end.map(|d| d.naive_utc().date());
        let mut d = as_of.naive_utc().date();
        if let Some(end) = cap {
            if d > end { d = end; }
        }
        d
    };

    // Bảo đảm thứ tự giao dịch ổn định: theo (date, id)
    txs.sort_by_key(|tx| (tx.date, tx.id));

    // ===== 2) Duyệt từng giao dịch =====
    for tx in txs.iter_mut() {
        let cur = tx.date.naive_utc().date();

        // 2.1) Số ngày giữa giao dịch này và mốc trước
        let days = (cur - prev_date).num_days().max(0);
        tx.days_from_prev = Some(days as i32);

        // 2.2) Lãi phát sinh trong khoảng đó
        //      Công thức: principal * daily_rate * days
        let interest = principal * daily_rate * (days as f64);

        // Cập nhật các bộ đếm lãi
        accumulated_interest_total += interest;
        accrued_interest_unpaid += interest;

        // Ghi xuống dòng giao dịch
        tx.interest_for_period = Some(interest.round() as i64);
        tx.accumulated_interest = Some(accumulated_interest_total.round() as i64);

        // 2.3) Áp dụng số tiền theo loại giao dịch
        // Quy ước:
        //  - Số tiền (amount) người dùng nhập là DƯƠNG.
        //  - Nếu có âm (nhập nhầm), dùng `abs()` ở các loại “thu tiền”.
        let amt = tx.amount as f64;

        match tx.transaction_type.as_str() {
            // Giải ngân / vay thêm => tăng dư nợ gốc
            "disbursement" | "additional" => {
                // Nếu ai nhập âm, coi là giảm gốc (ít gặp), vẫn an toàn:
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
                // Nếu trả nhiều hơn lãi treo, phần dư KHÔNG tự trừ gốc ở loại này
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
            }

            // Loại khác/không xác định: bỏ qua (không thay đổi số dư)
            _ => {}
        }

        // 2.4) Ghi dư nợ gốc sau khi áp dụng giao dịch
        tx.principal_balance = Some(principal.round() as i64);

        // 2.5) Dời mốc sang ngày giao dịch hiện tại
        prev_date = cur;
    }

    // ===== 3) KỲ LÃI "ĐUÔI" từ giao dịch cuối -> `as_of_date` =====
    // Nếu người dùng mở màn hình hôm nay (as_of = now), ta cần cộng lãi từ
    // giao dịch cuối tới hôm nay để con số “đang treo” là đúng thực tế.
    let tail_days = (as_of_date - prev_date).num_days().max(0);
    let mut virtual_row: Option<LoanTransaction> = None;

    if tail_days > 0 {
        // Lãi phát sinh ở “đuôi”
        let tail_interest = principal * daily_rate * (tail_days as f64);

        // Cập nhật các bộ đếm lãi
        accumulated_interest_total += tail_interest;
        accrued_interest_unpaid += tail_interest;

        // Nếu muốn hiển thị minh bạch cho người dùng, tạo “dòng ảo”
        // (không lưu DB, id = nil) để notebook có thêm một hàng cuối:
        // "Tính lãi đến hôm nay"
        if append_virtual_row {
            virtual_row = Some(LoanTransaction {
                id: Uuid::nil(), // đánh dấu ảo
                contract_id: contract.id,
                tenant_id: contract.tenant_id,
                customer_id: contract.customer_id,
                transaction_type: "accrual".to_string(), // loại đặc biệt cho UI (chỉ hiển thị)
                amount: 0, // không phải một giao dịch tiền thật
                date: DateTime::<Utc>::from_utc(
                    as_of_date.and_hms_opt(0, 0, 0).unwrap(),
                    Utc
                ),
                note: Some("Tính lãi đến hôm nay".to_string()),
                days_from_prev: Some(tail_days as i32),
                interest_for_period: Some(tail_interest.round() as i64),
                accumulated_interest: Some(accumulated_interest_total.round() as i64),
                principal_balance: Some(principal.round() as i64),
                created_at: None,
                updated_at: None,
            });
        }
    }

    // ===== 4) Ghi kết quả cuối cùng lên hợp đồng =====
    contract.current_principal   = Some(principal.round() as i64);                 // dư nợ gốc hiện tại
    contract.accumulated_interest = Some(accumulated_interest_total.round() as i64); // tổng lãi phát sinh lịch sử
    contract.current_interest    = Some(clamp_zero(accrued_interest_unpaid).round() as i64); // lãi đang treo
    contract.total_paid_interest = Some(total_paid_interest);                      // lãi KH đã trả

    // Trả về dòng ảo (nếu có) để handler có thể push vào mảng giao dịch cho UI
    virtual_row
}
