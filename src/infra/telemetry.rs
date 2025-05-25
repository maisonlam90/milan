use std::sync::Arc;

/// Struct chứa hệ thống telemetry như logging, tracing, metrics,...
#[derive(Clone)]
pub struct Telemetry;

impl Telemetry {
    /// Hàm khởi tạo hệ thống telemetry. Có thể khởi tạo tracing tại đây.
    pub fn new() -> Arc<Self> {
        Arc::new(Self)
    }
}
