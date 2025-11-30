use crate::module::user::dto::RegisterDto;
use crate::module::user::model::User;
use crate::module::user::event::UserCreated;
use uuid::Uuid;
use sqlx::PgPool;
use chrono::{DateTime, Utc};
use bcrypt::hash;

pub async fn create_user(
    pool: &PgPool,
    dto: RegisterDto
) -> Result<User, Box<dyn std::error::Error + Send + Sync>> {
    let email_norm = dto.email.trim().to_lowercase();
    let hashed = hash(&dto.password, bcrypt::DEFAULT_COST)?;
    let now: DateTime<Utc> = Utc::now();

    let user = User {
        tenant_id: dto.tenant_id,
        user_id: Uuid::new_v4(),
        email: email_norm.clone(),
        password_hash: hashed.clone(),
        name: dto.name,
        created_at: Some(now), // 👈 wrapped in Some()
    };

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
        user.created_at
    )
    .execute(pool)
    .await?;

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
