// Domain Event cho module Loan (sẽ dùng trong event bus nếu cần)
pub enum LoanEvent {
    LoanCreated,
    LoanApproved,
    LoanClosed,
}
