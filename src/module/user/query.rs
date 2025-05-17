use crate::module::user::model::User;
use sqlx::PgPool;
use uuid::Uuid;

// 🔍 Truy vấn danh sách user theo tenant
pub async fn find_users(pool: &PgPool, tenant_id: Uuid) -> sqlx::Result<Vec<User>> {
    let users = sqlx::query_as!(
        User,
        r#"
        SELECT tenant_id, user_id, email, password_hash, name, created_at
        FROM users
        WHERE tenant_id = $1
        "#,
        tenant_id
    )
    .fetch_all(pool)
    .await?;

    Ok(users)
}