use axum::http::{Method, header::{AUTHORIZATION, CONTENT_TYPE}};
use dotenvy::dotenv;
use std::{env, net::SocketAddr, sync::Arc};
use tower_http::cors::{CorsLayer, Any};

use api::router::build_router;
use core::state::AppState;
use infra::{db::ShardManager, telemetry::Telemetry, event_bus::EventPublisher, wasm_loader::ModuleRegistry};
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

    // 🎯 Module Registry - Load WASM modules ngoài binary
    let module_registry = ModuleRegistry::new();
    // Tìm thư mục modules/ - thử từ root project trước
    let modules_dir = std::path::Path::new("modules");
    // Nếu không tìm thấy (backend chạy từ thư mục backend/), thử từ parent
    let modules_dir = if !modules_dir.exists() {
        std::path::Path::new("../modules")
    } else {
        modules_dir
    };
    
    if let Err(e) = module_registry.scan_modules(modules_dir) {
        tracing::warn!("⚠️  Không thể scan modules tại {:?}: {}", modules_dir, e);
    } else {
        let count = module_registry.list_modules_owned().len();
        if count > 0 {
            tracing::info!("✅ Loaded {} modules ngoài binary từ {:?}", count, modules_dir);
        } else {
            tracing::info!("✅ Scanned modules tại {:?} (0 modules found)", modules_dir);
        }
    }
    let module_registry = Arc::new(module_registry);

    // 🧠 AppState
    let app_state = AppState::new(shard.clone(), telemetry, event_publisher, module_registry);

    // 🌐 CORS middleware để frontend gọi được
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods([Method::GET, Method::POST, Method::PUT, Method::PATCH, Method::DELETE, Method::OPTIONS])
        .allow_headers([AUTHORIZATION, CONTENT_TYPE]);

    // + Thêm route "/" để test nhanh BE có sống
    use axum::routing::get;
    let app = build_router(app_state.clone())
        .with_state(app_state)
        .layer(cors)
        .route("/", get(|| async { "BE OK" }));


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
