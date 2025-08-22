use axum::http::{Method, header::{AUTHORIZATION, CONTENT_TYPE, ACCEPT, ORIGIN}};
use dotenvy::dotenv;
use std::{env, net::SocketAddr, sync::Arc, time::Duration};
use tower_http::cors::CorsLayer;
use axum::http::HeaderValue;

use api::router::build_router; // 👈 Build router từ module api
use core::state::AppState;
use infra::{db::ShardManager, telemetry::Telemetry, event_bus::EventPublisher};
// log file
use tracing_appender::rolling;
use tracing_appender::non_blocking;
use std::io;
use tracing_subscriber::{fmt, prelude::*, EnvFilter};

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

/// 🌐 Hàm tạo CORS layer từ biến môi trường ALLOWED_ORIGINS
fn cors_layer_from_env() -> CorsLayer {
    let origins_env = env::var("ALLOWED_ORIGINS").unwrap_or_default();
    let origins: Vec<HeaderValue> = origins_env
        .split(',')
        .filter_map(|s| {
            let s = s.trim();
            if s.is_empty() { None } else { Some(s.parse().ok()?) }
        })
        .collect();

    let mut layer = CorsLayer::new()
        .allow_methods([
            Method::GET,
            Method::POST,
            Method::PUT,
            Method::PATCH,
            Method::DELETE,
            Method::OPTIONS,
        ])
        .allow_headers([ACCEPT, CONTENT_TYPE, AUTHORIZATION, ORIGIN])
        .max_age(Duration::from_secs(24 * 60 * 60));

    if !origins.is_empty() {
        layer = layer.allow_origin(origins).allow_credentials(true);
    } else {
        use tower_http::cors::Any;
        layer = layer.allow_origin(Any);
    }

    layer
}

#[tokio::main]
async fn main() {
    dotenv().ok();

    // 👇 Khởi tạo hệ thống log (rất quan trọng)
    // Log luân phiên theo ngày, lưu vào thư mục "logs/"
    let file_appender = rolling::daily("logs", "app.log");
    let (file_writer, guard) = non_blocking(file_appender);
    Box::leak(Box::new(guard));

    tracing_subscriber::registry()
        .with(fmt::layer()
            .with_writer(io::stdout.and(file_writer))
            .with_ansi(false))
        .with(EnvFilter::from_default_env())
        .init();


    // 🧪 Đọc DATABASE_URL và khởi tạo ShardManager (hiện chỉ có 1 shard duy nhất)
    let db_url = env::var("DATABASE_URL").expect("⚠️ DATABASE_URL chưa được cấu hình");
    let shard = ShardManager::new_from_url(&db_url)
        .await;

    // 📦 Các thành phần hệ thống phụ trợ
    let telemetry = Telemetry::new();
    let event_publisher = Arc::new(DummyBus);

    // 🧠 AppState — chỉ chứa ShardManager, không còn PgPool cục bộ
    let app_state = AppState::new(shard.clone(), telemetry, event_publisher);

    // 🌐 CORS middleware để frontend gọi được (chuẩn hoá bằng ALLOWED_ORIGINS)
    let cors = cors_layer_from_env();

    // 🚦 Build Axum router và inject AppState + middleware
    let app = build_router(app_state.clone())
        .with_state(app_state)
        .layer(cors);

    // 🔌 Lắng nghe cổng HTTP
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
