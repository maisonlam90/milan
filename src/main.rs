use axum::{Router};
use axum::http::{Method, header::{AUTHORIZATION, CONTENT_TYPE}};
use dotenvy::dotenv;
use std::{env, net::SocketAddr, sync::Arc};
use sqlx::PgPool;
use tower_http::cors::{CorsLayer, Any};

use api::router::build_router; // 👈 Build route từ module api
use core::state::AppState;
use infra::{db::ShardManager, telemetry::Telemetry, event_bus::EventPublisher};

// Các module con (command bus, query bus, event handler, tenant, etc)
mod core;
mod infra;
mod api;
mod module;
mod tenant_router;
mod command_bus;
mod query_bus;
mod event_handler;

/// Dummy event bus để demo (sẽ thay bằng Kafka/NATS sau)
struct DummyBus;
impl EventPublisher for DummyBus {
    fn publish(&self, topic: &str, payload: &[u8]) {
        println!("🌀 [EVENT] {topic}: {:?}", payload);
    }
}

#[tokio::main]
async fn main() {
    dotenv().ok();

    // 🛠 Kết nối DB truyền thống — dùng cho module chưa migrate
    let db_url = env::var("DATABASE_URL").expect("⚠️ DATABASE_URL chưa được cấu hình");
    let db_pool = PgPool::connect(&db_url)
        .await
        .expect("❌ Không thể kết nối DB");

    // 📦 Khởi tạo các hệ thống dùng chung
    let shard = ShardManager::new();              // Tạm mock, sẽ route tenant sau
    let telemetry = Telemetry::new();
    let event_publisher = Arc::new(DummyBus);

    // 🧠 AppState giữ toàn bộ context: pool cũ + shard + telemetry + event bus
    let app_state = AppState::new(db_pool.clone(), shard, telemetry, event_publisher);

    // 🔄 Đồng bộ metadata module (user, payment,...) vào bảng available_module
    module::sync_available_modules(&db_pool)
        .await
        .expect("❌ Không thể sync available_module");

    // 🌐 Middleware CORS cho frontend gọi
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods([Method::GET, Method::POST, Method::OPTIONS, Method::DELETE])
        .allow_headers([AUTHORIZATION, CONTENT_TYPE]);

    // ⚙️ Build Axum router + inject AppState + CORS
    let app = build_router(app_state.clone())
        .with_state(app_state)
        .layer(cors);

    // 🔌 Bind 0.0.0.0 để cho phép gọi từ máy khác (LAN, Docker...)
    let port = env::var("PORT")
        .ok()
        .and_then(|s| s.parse::<u16>().ok())
        .unwrap_or(3000);
    let addr = SocketAddr::from(([0, 0, 0, 0], port));

    println!("🚀 Axum khởi động tại http://{}", addr);

    if let Err(e) = axum::serve(tokio::net::TcpListener::bind(addr).await.unwrap(), app.into_make_service()).await {
        eprintln!("❌ Lỗi khi chạy server: {}", e);
    }
}
