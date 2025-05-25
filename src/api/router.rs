use std::sync::Arc;

use axum::{Router, routing::{get, post}, middleware};
use axum::http::{Method, header};
use tower_http::cors::{Any, CorsLayer};

use crate::module::{user, tenant, available};
use crate::core::{auth::jwt_auth, state::AppState};

/// Build tất cả router từ các module.
/// Sử dụng `Arc<AppState>` thay vì `PgPool` để hỗ trợ sharding.
pub fn build_router(state: Arc<AppState>) -> Router<Arc<AppState>> {
    // 🌐 Middleware CORS cho phép mọi origin, method, header
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods([Method::GET, Method::POST, Method::DELETE])
        .allow_headers([header::CONTENT_TYPE, header::AUTHORIZATION]);

    Router::new()
        // 🔐 Auth route (public)
        .route("/user/register", post(user::handler::register))
        .route("/user/login", post(user::handler::login))

        // 🔒 Route cần auth bằng JWT
        .nest(
            "/user",
            Router::new()
                .route("/profile", get(user::handler::whoami))
                .route("/users", get(user::handler::list_users))
                .layer(middleware::from_fn(jwt_auth)),
        )

        // 🧩 Route tenant (module → tenant binding)
        .merge(tenant::router::routes())

        // 📋 Route public lấy danh sách module khả dụng
        .route("/available-modules", get(available::get_available_modules))

        // 🌐 Gắn state + middleware CORS
        .with_state(state)
        .layer(cors)
}
