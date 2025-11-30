use crate::module::user::model::User;
use sqlx::PgPool;
use uuid::Uuid;

// 🔍 Truy vấn danh sách user theo tenant
pub async fn find_users(pool: &PgPool, tenant_id: Uuid) -> sqlx::Result<Vec<User>> {
    sqlx::query_as!(
        User,
        r#"
        SELECT
            tenant_id,
            user_id,
            email,
            password_hash,
            name as "name!",
            created_at as "created_at?: chrono::DateTime<chrono::Utc>"
        FROM users
        WHERE tenant_id = $1
        ORDER BY created_at DESC
        "#,
        tenant_id
    )
    .fetch_all(pool)
    .await
}

// 🔍 Lấy 1 user theo ID
pub async fn find_user_by_id(pool: &PgPool, tenant_id: Uuid, user_id: Uuid) -> sqlx::Result<User> {
    sqlx::query_as!(
        User,
        r#"
        SELECT
            tenant_id,
            user_id,
            email,
            password_hash,
            name as "name!",
            created_at as "created_at?: chrono::DateTime<chrono::Utc>"
        FROM users
        WHERE tenant_id = $1 AND user_id = $2
        "#,
        tenant_id,
        user_id
    )
    .fetch_one(pool)
    .await
}
