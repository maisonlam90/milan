use std::sync::Arc;
use crate::infra::{ telemetry::Telemetry, event_bus::EventPublisher, wasm_loader::ModuleRegistry};

pub use crate::infra::db::ShardManager;

#[derive(Clone)]
pub struct AppState {
    pub shard: Arc<ShardManager>,
    pub telemetry: Arc<Telemetry>,
    pub event_publisher: Arc<dyn EventPublisher + Send + Sync>,
    pub module_registry: Arc<ModuleRegistry>, // Module registry cho WASM modules ngoài binary
}

impl AppState {
    pub fn new(
        shard: Arc<ShardManager>,
        telemetry: Arc<Telemetry>,
        event_publisher: Arc<dyn EventPublisher + Send + Sync>,
        module_registry: Arc<ModuleRegistry>,
    ) -> Arc<Self> {
        Arc::new(Self {
            shard,
            telemetry,
            event_publisher,
            module_registry,
        })
    }
}
