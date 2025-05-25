use std::sync::Arc;
use sqlx::PgPool;

use crate::infra::{
    db::ShardManager,             // Quản lý shard theo tenant_id
    event_bus::EventPublisher,    // Abstraction gửi event (Kafka/NATS)
    telemetry::Telemetry,         // Logging, tracing, metrics
};

/// AppState lưu trữ toàn bộ context toàn cục của ứng dụng.
/// 
/// Thiết kế "hybrid" giúp bạn giữ `PgPool` cũ cho các module chưa migrate,
/// đồng thời hỗ trợ `ShardManager` cho các module mới dùng multi-tenant.
#[derive(Clone)]
pub struct AppState {
    /// Connection pool mặc định (cũ) — dùng cho các module chưa migrate
    pub default_pool: PgPool,

    /// ShardManager — ánh xạ tenant_id → pool phù hợp (cho module đã migrate)
    pub shard: Arc<ShardManager>,

    /// Telemetry system — logging, tracing, metrics,...
    pub telemetry: Arc<Telemetry>,

    /// Event bus interface — để publish domain event (UserCreated, PaymentSuccess,...)
    pub event_publisher: Arc<dyn EventPublisher + Send + Sync>,
}

impl AppState {
    /// Hàm khởi tạo AppState.
    /// Nhận vào default `PgPool` + ShardManager + các dịch vụ hệ thống khác.
    pub fn new(
        default_pool: PgPool,
        shard: Arc<ShardManager>,
        telemetry: Arc<Telemetry>,
        event_publisher: Arc<dyn EventPublisher + Send + Sync>,
    ) -> Arc<Self> {
        Arc::new(Self {
            default_pool,
            shard,
            telemetry,
            event_publisher,
        })
    }
}
