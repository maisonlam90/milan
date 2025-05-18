use axum::{middleware, Router};
use axum::http::{Method, header};
use tower_http::cors::{Any, CorsLayer};

use crate::module::{user, tenant, available}; // 👈 Import thêm module `available`
use crate::core::auth::jwt_auth;

pub fn build_router(pool: sqlx::PgPool) -> Router<sqlx::PgPool> {
    // 🌐 Cấu hình CORS: cho phép mọi origin/method/header
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods([Method::GET, Method::POST , Method::DELETE])
        .allow_headers([header::CONTENT_TYPE, header::AUTHORIZATION]);

    Router::new()
        // 🔐 Đăng ký user (public)
        .route("/user/register", axum::routing::post(user::handler::register))
        .route("/user/login", axum::routing::post(user::handler::login))

        // 🔒 Route yêu cầu JWT
        .nest(
            "/user",
            Router::new()
                .route("/profile", axum::routing::get(user::handler::whoami))
                .route("/users", axum::routing::get(user::handler::list_users))
                .layer(middleware::from_fn(jwt_auth)),
        )

        // 🧩 Route gán / lấy module của tenant
        .merge(tenant::router::routes(pool.clone())) // ✅ Truyền pool

        // 📋 Route public để lấy danh sách module khả dụng
        .route("/available-modules", axum::routing::get(available::get_available_modules))

        // 🌐 Gắn middleware CORS
        .layer(cors)
}
