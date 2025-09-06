use sqlx::PgPool;
use std::collections::HashMap;
use std::sync::Arc;
use uuid::Uuid;

/// Quản lý ánh xạ tenant_id → shard_id → pool
/// - Trong giai đoạn đầu: dạng đơn shard (mock)
/// - Sau mở rộng: HashMap shard_id → pool
#[derive(Clone)]
pub struct ShardManager {
    pool: PgPool, // Legacy: single pool mặc định

    // 👇 Để chuẩn bị mở rộng multi-shard
    pub pools: HashMap<String, PgPool>,
}

impl ShardManager {
    /// Khởi tạo ShardManager từ 1 URL (single-shard mode)
    pub async fn new_from_url(database_url: &str) -> Arc<Self> {
        let pool = PgPool::connect(database_url)
            .await
            .expect("❌ Không kết nối được DB shard");
    
        let pools = HashMap::from([
            ("default".to_string(), pool.clone()),
            ("cluster1".to_string(), pool.clone()),
            ("admin-cluster".to_string(), pool.clone()), // 👈 THÊM DÒNG NÀY
        ]);
    
        Arc::new(Self { pool, pools })
    }

    /// Lấy pool từ tenant_id (dùng routing logic ngoài, hiện mock đơn shard)
    pub fn get_pool_for_tenant(&self, _tenant_id: &Uuid) -> &PgPool {
        &self.pool
    }

    /// Lấy pool theo shard_id (cho khởi tạo tenant)
    pub fn get_pool_for_shard(&self, shard_id: &str) -> Result<&PgPool, String> {
        self.pools.get(shard_id).ok_or_else(|| format!("Không tìm thấy shard '{}'", shard_id))
    }

    /// Lấy pool dùng cho các thao tác hệ thống (không gắn với tenant cụ thể)
    pub fn get_pool_for_system(&self) -> &PgPool {
        &self.pool
    }
}
