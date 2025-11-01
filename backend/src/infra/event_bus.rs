/// Interface cho các hệ thống Event Bus (Kafka, NATS,...)
/// Mỗi implementation cụ thể sẽ cài `publish` khác nhau.
pub trait EventPublisher: Send + Sync {
    /// Gửi message tới topic tương ứng
    fn publish(&self, topic: &str, payload: &[u8]);
}
