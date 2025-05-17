use crate::module::user::dto::RegisterDto;
use crate::module::user::model::User;
use crate::module::user::event::UserCreated;
use uuid::Uuid;
use sqlx::PgPool;
use chrono::Utc;
use bcrypt::hash;

// ✅ Tạo user mới và ghi vào DB
pub async fn create_user(pool: &PgPool, dto: RegisterDto) -> Result<User, Box<dyn std::error::Error + Send + Sync>> {
    let hashed = hash(&dto.password, bcrypt::DEFAULT_COST)?; // Mã hoá mật khẩu

    let user = User {
        tenant_id: dto.tenant_id,
        user_id: Uuid::new_v4(),
        email: dto.email,
        password_hash: hashed,
        name: dto.name,
        created_at: Utc::now().naive_utc(),
    };

    // Ghi vào bảng users
    sqlx::query!(
        r#"
        INSERT INTO users (tenant_id, user_id, email, password_hash, name, created_at)
        VALUES ($1, $2, $3, $4, $5, $6)
        "#,
        user.tenant_id,
        user.user_id,
        user.email,
        user.password_hash,
        user.name,
        user.created_at,
    )
    .execute(pool)
    .await?;

    // Gửi event (in ra log)
    println!("📤 Gửi event: UserCreated: {:?}", UserCreated {
        tenant_id: user.tenant_id,
        user_id: user.user_id,
        email: user.email.clone(),
    });

    Ok(user)
}