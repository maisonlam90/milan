use sqlx::PgPool;
use std::collections::HashMap;
use std::sync::Arc;
use uuid::Uuid;

/// Quản lý ánh xạ tenant_id → shard_id → pool (mock single-shard)
#[derive(Clone)]
pub struct ShardManager {
    pool: PgPool, // hiện tại chỉ có 1 pool, dạng đơn shard
}

impl ShardManager {
    pub async fn new_from_url(database_url: &str) -> Arc<Self> {
        let pool = PgPool::connect(database_url).await.expect("❌ Không kết nối được DB shard");
        Arc::new(Self { pool })
    }

    /// Lấy pool từ tenant_id (hiện tại chỉ có 1 shard nên bỏ qua tenant)
    pub fn get_pool_for_tenant(&self, _tenant_id: &Uuid) -> &PgPool {
        &self.pool
    }
}
