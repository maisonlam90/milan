use std::sync::Arc;
use axum::{Router, routing::{get, post}, middleware};
use axum::http::{Method, header::{self, HeaderName}};
use tower_http::cors::{Any, CorsLayer};

use crate::module::{user, tenant, iam};
use crate::core::{auth::jwt_auth, state::AppState, i18n_middleware::i18n_middleware};
use crate::api::i18n;

/// Build tất cả router từ các module.
/// Sử dụng `Arc<AppState>` thay vì `PgPool` để hỗ trợ sharding.
pub fn build_router(state: Arc<AppState>) -> Router<Arc<AppState>> {
    // 🌐 Middleware CORS cho phép mọi origin, method, header
    // Allow Accept-Language header for i18n support
    let accept_language = HeaderName::from_static("accept-language");
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods([Method::GET, Method::POST, Method::DELETE, Method::PUT, Method::PATCH, Method::OPTIONS])
        .allow_headers([
            header::CONTENT_TYPE,
            header::AUTHORIZATION,
            accept_language, // Allow Accept-Language header for i18n
        ]);

    Router::new()
        // 🌐 i18n routes (public)
        .merge(i18n::routes())

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

        // 🛡️ Route phân quyền iam
        .merge(iam::router::routes()) // 👈 Mount iam router

        // 🛡️ Route module loan
        .merge(crate::module::loan::router::routes())

        // 🛡️ Route module contact
        .merge(crate::module::contact::router::routes())

        // 🛡️ Route module invoice
        .merge(crate::module::invoice::router::routes())

        // 🛡️ Route module invoice_link
        .merge(crate::module::invoice_link::router::routes())

        // 🛡️ Route module app
        .merge(crate::module::app::router::routes())

        // 🎓 Routes động từ modules ngoài binary (load từ manifest.json)
        .merge(crate::api::external_modules::routes(state.clone()))

        // 🌐 i18n middleware to detect language from headers
        .layer(middleware::from_fn(i18n_middleware))

        // 🌐 Gắn state + middleware CORS
        .with_state(state)
        .layer(cors)
}
