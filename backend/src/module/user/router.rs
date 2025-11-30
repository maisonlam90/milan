use axum::{Router, routing::{post, get}, middleware};
use std::sync::Arc;

use crate::core::{auth::jwt_auth, state::AppState};
use crate::module::user::handler::{register, login, whoami, list_users};

/// Trả về router của module `user`, dùng AppState để hỗ trợ hybrid pool.
pub fn routes() -> Router<Arc<AppState>> {
    Router::new()
        // Các route công khai
        .route("/user/register", post(register))
        .route("/user/login", post(login))

        // Các route yêu cầu xác thực JWT
        .nest(
            "/user",
            Router::new()
                .route("/me", get(whoami))
                .route("/users", get(list_users))
                .layer(middleware::from_fn(jwt_auth)),
        )
}
