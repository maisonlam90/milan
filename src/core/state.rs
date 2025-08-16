use std::sync::Arc;
use crate::infra::{ telemetry::Telemetry, event_bus::EventPublisher};

pub use crate::infra::db::ShardManager;

#[derive(Clone)]
pub struct AppState {
    pub shard: Arc<ShardManager>, // chỉ còn ShardManager
    pub telemetry: Arc<Telemetry>,
    pub event_publisher: Arc<dyn EventPublisher + Send + Sync>,
}

impl AppState {
    pub fn new(
        shard: Arc<ShardManager>,
        telemetry: Arc<Telemetry>,
        event_publisher: Arc<dyn EventPublisher + Send + Sync>,
    ) -> Arc<Self> {
        Arc::new(Self {
            shard,
            telemetry,
            event_publisher,
        })
    }
}
