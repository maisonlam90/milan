use axum::{Router, routing::{post, get}, middleware};
use crate::module::user::handler::{register, login, whoami};
use crate::core::auth::jwt_auth; // ✅ Middleware xác thực JWT

/// Trả về toàn bộ router của module user
pub fn routes() -> Router<sqlx::PgPool> {
    Router::new()
        // Các route công khai
        .route("/user/register", post(register))
        .route("/user/login", post(login))

        // Các route yêu cầu xác thực
        .nest(
            "/user",
            Router::new()
                .route("/me", get(whoami))
                .layer(middleware::from_fn(jwt_auth)), // 🔐 chỉ áp dụng middleware cho /user/me
        )
}