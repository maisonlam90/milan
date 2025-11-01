use redis::{Client, RedisResult};
use redis::aio::ConnectionManager;
use serde::{Deserialize, Serialize};
use std::time::{Duration, Instant};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::RwLock;
use once_cell::sync::Lazy;

// ✅ Multi-Layer Cache Service (L1 + L2)
pub struct CacheService {
    client: Client,
    // L1 Cache (In-Memory)
    l1_cache: Arc<RwLock<HashMap<String, (serde_json::Value, Instant)>>>,
}

// ✅ L1 Cache Entry
#[derive(Clone)]
struct L1CacheEntry {
    data: serde_json::Value,
    created_at: Instant,
    access_count: u64,
}

impl CacheService {
    pub fn new(redis_url: &str) -> RedisResult<Self> {
        let client = Client::open(redis_url)?;
        Ok(Self { 
            client,
            l1_cache: Arc::new(RwLock::new(HashMap::new())),
        })
    }

    pub async fn get_connection(&self) -> RedisResult<ConnectionManager> {
        self.client.get_connection_manager().await
    }

    // ✅ Multi-Layer Cache Strategy (L1 → L2 → DB)
    pub async fn get<T>(&self, key: &str) -> RedisResult<Option<T>>
    where
        T: for<'de> Deserialize<'de> + Serialize,
    {
        // 1. Check L1 Cache (Memory) - Nếu có → Return ngay
        {
            let l1_guard = self.l1_cache.read().await;
            if let Some((cached_data, cached_time)) = l1_guard.get(key) {
                if cached_time.elapsed() < Duration::from_secs(60) { // L1 TTL: 1 phút
                    let value: T = serde_json::from_value(cached_data.clone())
                        .map_err(|_| redis::RedisError::from((redis::ErrorKind::TypeError, "L1 deserialize error")))?;
                    return Ok(Some(value));
                }
            }
        }

        // 2. Check L2 Cache (Redis) - Nếu có → Store vào L1 + Return
        let mut conn = self.get_connection().await?;
        let data: Option<String> = redis::cmd("GET").arg(key).query_async(&mut conn).await?;
        
        if let Some(json) = data {
            let value: T = serde_json::from_str(&json)
                .map_err(|_| redis::RedisError::from((redis::ErrorKind::TypeError, "L2 deserialize error")))?;
            
            // Store vào L1 Cache
            let value_json = serde_json::to_value(&value)
                .map_err(|_| redis::RedisError::from((redis::ErrorKind::TypeError, "L1 serialize error")))?;
            
            {
                let mut l1_guard = self.l1_cache.write().await;
                l1_guard.insert(key.to_string(), (value_json, Instant::now()));
            }
            
            return Ok(Some(value));
        }

        // 3. Not found in both L1 and L2
        Ok(None)
    }

    // ✅ Multi-Layer Cache Set (L1 + L2)
    pub async fn set<T>(&self, key: &str, value: &T, ttl: Duration) -> RedisResult<()>
    where
        T: Serialize,
    {
        // Store vào L1 Cache (Memory)
        let value_json = serde_json::to_value(value)
            .map_err(|_| redis::RedisError::from((redis::ErrorKind::TypeError, "L1 serialize error")))?;
        
        {
            let mut l1_guard = self.l1_cache.write().await;
            l1_guard.insert(key.to_string(), (value_json, Instant::now()));
        }

        // Store vào L2 Cache (Redis)
        let mut conn = self.get_connection().await?;
        let json = serde_json::to_string(value)
            .map_err(|_| redis::RedisError::from((redis::ErrorKind::TypeError, "L2 serialize error")))?;
        
        redis::cmd("SETEX")
            .arg(key)
            .arg(ttl.as_secs())
            .arg(json)
            .query_async::<_, ()>(&mut conn)
            .await?;
        
        Ok(())
    }

    // ✅ Multi-Layer Cache Invalidation (L1 + L2)
    pub async fn del(&self, key: &str) -> RedisResult<()> {
        // Invalidate L1 Cache
        {
            let mut l1_guard = self.l1_cache.write().await;
            l1_guard.remove(key);
        }

        // Invalidate L2 Cache (Redis)
        let mut conn = self.get_connection().await?;
        redis::cmd("DEL").arg(key).query_async::<_, ()>(&mut conn).await?;
        Ok(())
    }

    pub async fn exists(&self, key: &str) -> RedisResult<bool> {
        let mut conn = self.get_connection().await?;
        let exists: bool = redis::cmd("EXISTS").arg(key).query_async(&mut conn).await?;
        Ok(exists)
    }

    // ✅ Dashboard-specific cache methods
    pub async fn get_dashboard_stats(&self, tenant_id: &str, month: u32, year: i32) -> RedisResult<Option<serde_json::Value>> {
        let key = format!("dashboard_stats:{}:{}:{}", tenant_id, year, month);
        self.get(&key).await
    }

    pub async fn set_dashboard_stats(&self, tenant_id: &str, month: u32, year: i32, data: &serde_json::Value) -> RedisResult<()> {
        let key = format!("dashboard_stats:{}:{}:{}", tenant_id, year, month);
        self.set(&key, data, Duration::from_secs(300)).await // 5 phút
    }

    pub async fn get_loan_stats(&self, tenant_id: &str, year: i32, month: Option<u32>, range: Option<&str>) -> RedisResult<Option<serde_json::Value>> {
        let range_str = range.unwrap_or("monthly");
        let month_str = month.map(|m| m.to_string()).unwrap_or_else(|| "all".to_string());
        let key = format!("loan_stats:{}:{}:{}:{}", tenant_id, year, month_str, range_str);
        self.get(&key).await
    }

    pub async fn set_loan_stats(&self, tenant_id: &str, year: i32, month: Option<u32>, range: Option<&str>, data: &serde_json::Value) -> RedisResult<()> {
        let range_str = range.unwrap_or("monthly");
        let month_str = month.map(|m| m.to_string()).unwrap_or_else(|| "all".to_string());
        let key = format!("loan_stats:{}:{}:{}:{}", tenant_id, year, month_str, range_str);
        self.set(&key, data, Duration::from_secs(300)).await // 5 phút
    }

    pub async fn get_monthly_interest(&self, tenant_id: &str, month: u32, year: i32) -> RedisResult<Option<serde_json::Value>> {
        let key = format!("monthly_interest:{}:{}:{}", tenant_id, year, month);
        self.get(&key).await
    }

    pub async fn set_monthly_interest(&self, tenant_id: &str, month: u32, year: i32, data: &serde_json::Value) -> RedisResult<()> {
        let key = format!("monthly_interest:{}:{}:{}", tenant_id, year, month);
        self.set(&key, data, Duration::from_secs(300)).await // 5 phút
    }

    pub async fn get_loan_activity(&self, tenant_id: &str, month: u32, year: i32) -> RedisResult<Option<serde_json::Value>> {
        let key = format!("loan_activity:{}:{}:{}", tenant_id, year, month);
        self.get(&key).await
    }

    pub async fn set_loan_activity(&self, tenant_id: &str, month: u32, year: i32, data: &serde_json::Value) -> RedisResult<()> {
        let key = format!("loan_activity:{}:{}:{}", tenant_id, year, month);
        self.set(&key, data, Duration::from_secs(300)).await // 5 phút
    }

    // ✅ Cache cleanup methods
    pub async fn clear_tenant_cache(&self, tenant_id: &str) -> RedisResult<()> {
        let mut conn = self.get_connection().await?;
        let pattern = format!("*:{}:*", tenant_id);
        
        // Get all keys matching pattern
        let keys: Vec<String> = redis::cmd("KEYS").arg(&pattern).query_async(&mut conn).await?;
        
        if !keys.is_empty() {
            redis::cmd("DEL").arg(keys).query_async::<_, ()>(&mut conn).await?;
        }
        
        Ok(())
    }

    // ✅ L1 Cache Cleanup (LRU Eviction)
    pub async fn cleanup_l1_cache(&self) {
        let mut l1_guard = self.l1_cache.write().await;
        
        // Remove expired entries
        let now = Instant::now();
        l1_guard.retain(|_, (_, created_at)| {
            now.duration_since(*created_at) < Duration::from_secs(60) // L1 TTL: 1 phút
        });

        // LRU eviction if cache is too large (max 1000 entries)
        if l1_guard.len() > 1000 {
            let mut entries: Vec<(String, (serde_json::Value, Instant))> = l1_guard.drain().collect();
            entries.sort_by(|a, b| a.1.1.cmp(&b.1.1)); // Sort by creation time
            entries.truncate(500); // Keep only 500 most recent entries
            
            l1_guard.clear();
            for (key, value) in entries {
                l1_guard.insert(key, value);
            }
        }
    }

    // ✅ Cache Statistics
    pub async fn get_cache_stats(&self) -> RedisResult<serde_json::Value> {
        let mut conn = self.get_connection().await?;
        
        // L2 Cache stats (Redis)
        let info: String = redis::cmd("INFO").arg("memory").query_async(&mut conn).await?;
        let db_size: i32 = redis::cmd("DBSIZE").query_async(&mut conn).await?;
        
        // L1 Cache stats (Memory)
        let l1_guard = self.l1_cache.read().await;
        let l1_size = l1_guard.len();
        
        Ok(serde_json::json!({
            "l1_cache": {
                "size": l1_size,
                "max_size": 1000,
                "ttl_seconds": 60
            },
            "l2_cache": {
                "db_size": db_size,
                "memory_info": info
            }
        }))
    }
}

// ✅ Global Redis client instance
static REDIS_CLIENT: Lazy<Option<CacheService>> = Lazy::new(|| {
    match std::env::var("REDIS_URL") {
        Ok(url) => {
            match CacheService::new(&url) {
                Ok(client) => Some(client),
                Err(e) => {
                    tracing::warn!("Failed to connect to Redis: {}", e);
                    None
                }
            }
        }
        Err(_) => {
            tracing::warn!("REDIS_URL not set, using in-memory cache fallback");
            None
        }
    }
});

// ✅ Helper functions for global cache access
pub async fn get_redis_client() -> Option<&'static CacheService> {
    REDIS_CLIENT.as_ref()
}

pub async fn is_redis_available() -> bool {
    REDIS_CLIENT.is_some()
}

// ✅ Background Cache Cleanup Task
pub async fn start_cache_cleanup_task() {
    if let Some(redis_client) = get_redis_client().await {
        tokio::spawn(async move {
            let mut interval = tokio::time::interval(Duration::from_secs(30)); // Cleanup every 30 seconds
            
            loop {
                interval.tick().await;
                redis_client.cleanup_l1_cache().await;
            }
        });
    }
}
