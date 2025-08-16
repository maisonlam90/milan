use crate::module::user::dto::RegisterDto;
use crate::module::user::model::User;
use crate::module::user::event::UserCreated;
use uuid::Uuid;
use sqlx::PgPool;
use chrono::{DateTime, Utc};
use bcrypt::hash;

// ✅ Tạo user mới và ghi vào DB
pub async fn create_user(
    pool: &PgPool,
    dto: RegisterDto
) -> Result<User, Box<dyn std::error::Error + Send + Sync>> {
    // Chuẩn hoá email để khớp unique index (tenant_id, lower(email))
    let email_norm = dto.email.trim().to_lowercase();

    // Hash mật khẩu
    let hashed = hash(&dto.password, bcrypt::DEFAULT_COST)?;

    // created_at phải là DateTime<Utc> để map TIMESTAMPTZ
    let now: DateTime<Utc> = Utc::now();

    let user = User {
        tenant_id: dto.tenant_id,
        user_id: Uuid::new_v4(),
        email: email_norm.clone(),
        password_hash: hashed.clone(),
        name: dto.name,
        created_at: now, // <-- DateTime<Utc>, không dùng naive_utc()
    };

    // Ghi vào bảng users
    // Nếu bạn muốn dùng DEFAULT now() của DB: bỏ cột created_at khỏi INSERT
    sqlx::query!(
        r#"
        INSERT INTO users (tenant_id, user_id, email, password_hash, name, created_at)
        VALUES ($1, $2, $3, $4, $5, $6)
        "#,
        user.tenant_id,
        user.user_id,
        user.email,         // đã được lower-case
        user.password_hash,
        user.name,
        user.created_at,    // DateTime<Utc> -> TIMESTAMPTZ
    )
    .execute(pool)
    .await?;

    // Gửi event (in log)
    println!(
        "📤 Gửi event: UserCreated: {:?}",
        UserCreated {
            tenant_id: user.tenant_id,
            user_id: user.user_id,
            email: user.email.clone(),
        }
    );

    Ok(user)
}
