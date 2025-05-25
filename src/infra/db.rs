use std::sync::Arc;

/// Quản lý các kết nối tới từng shard, ánh xạ từ tenant_id → PgPool
#[derive(Clone)]
pub struct ShardManager;

impl ShardManager {
    /// Hàm khởi tạo ShardManager, có thể load config shard từ file/env
    pub fn new() -> Arc<Self> {
        Arc::new(Self)
    }
}
