use axum::{Router};
use axum::http::{Method, header::{AUTHORIZATION, CONTENT_TYPE}};
use dotenvy::dotenv;
use std::{env, net::SocketAddr};
use sqlx::PgPool;
use api::router::build_router; // 👈 Hàm build các route từ module api
use tower_http::cors::{CorsLayer, Any}; // 👈 Middleware CORS để cho phép gọi từ frontend

// Các module con (command bus, query bus, event handler, tenant, etc)
mod core;
mod infra;
mod api;
mod module; // 👈 Module chính chứa user/payment/... và hàm sync_available_modules
mod tenant_router;
mod command_bus;
mod query_bus;
mod event_handler;

#[tokio::main]
async fn main() {
    // 📦 Load biến môi trường từ file .env
    dotenv().ok();

    // 🛠 Đọc biến môi trường DATABASE_URL và kết nối Postgres
    let db_url = env::var("DATABASE_URL").expect("⚠️ DATABASE_URL chưa được cấu hình");
    let db_pool = PgPool::connect(&db_url)
        .await
        .expect("❌ Không thể kết nối DB");

    // 🔄 Đồng bộ metadata các module (user, payment,...) vào bảng available_module
    // 👇 Chạy khi hệ thống khởi động
    module::sync_available_modules(&db_pool)
        .await
        .expect("❌ Không thể sync available_module");

    // 🌐 Cấu hình CORS cho phép mọi origin, phương thức và header
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods([Method::GET, Method::POST, Method::OPTIONS , Method::DELETE,])
        .allow_headers([AUTHORIZATION, CONTENT_TYPE]);

    // ⚙️ Build app router (mount tất cả route API) và gắn thêm middleware CORS
    let app = build_router(db_pool.clone()) // ✅ truyền pool
        .with_state(db_pool.clone())        // 👈 Cho route dùng chung pool DB
        .layer(cors);                       // 👈 Gắn CORS vào router để cho frontend gọi được

    // 🔌 Bind server với địa chỉ 0.0.0.0 để truy cập từ mạng LAN
    let port = env::var("PORT")
        .ok()
        .and_then(|s| s.parse::<u16>().ok())
        .unwrap_or(3000);
    let addr = SocketAddr::from(([0, 0, 0, 0], port));

    println!("🚀 Axum khởi động tại http://{}", addr);

    // 🚦 Khởi động server async
    if let Err(e) = axum::serve(tokio::net::TcpListener::bind(addr).await.unwrap(), app.into_make_service()).await {
        eprintln!("❌ Lỗi khi chạy server: {}", e);
    }
}
