use axum::{extract::{State, Extension}, Json};
use axum::response::IntoResponse;
use bcrypt::verify as bcrypt_verify;
use chrono::DateTime;
use jsonwebtoken::{encode, EncodingKey, Header};
use serde::{Serialize, Deserialize};
use serde_json::json;
use sqlx::Row;
use std::sync::Arc;
use uuid::Uuid;

use crate::core::{auth::AuthUser, state::AppState, error::AppError};
use crate::module::user::{
    dto::{RegisterDto, LoginDto},
    command::create_user,
};

#[derive(Debug, Serialize, Deserialize)]
struct Claims {
    sub: String,
    tenant_id: String,
    exp: usize,
}

const SECRET_KEY: &[u8] = b"super_secret_jwt_key";

/// ✅ Đăng ký người dùng mới (dùng AppError)
pub async fn register(
    State(state): State<Arc<AppState>>,
    Json(mut input): Json<RegisterDto>,
) -> Result<impl IntoResponse, AppError> {
    // BE normalize để không phụ thuộc FE
    input.email = input.email.trim().to_lowercase();

    let pool = state.shard.get_pool_for_tenant(&Uuid::nil());

    // create_user trả Result<_, Box<dyn Error>> nên KHÔNG dùng AppError::from
    let user = create_user(pool, input)
        .await
        .map_err(|e| AppError::bad_request(e.to_string()))?;

    Ok(Json(json!({ "status": "ok", "email": user.email, "name": user.name })))
}

/// ✅ Đăng nhập, trả về token JWT (dùng AppError)
pub async fn login(
    State(state): State<Arc<AppState>>,
    Json(input): Json<LoginDto>,
) -> Result<impl IntoResponse, AppError> {
    // 1) Chuẩn hoá input (BE normalize)
    let tenant_slug = input.tenant_slug.trim().to_lowercase();
    let email       = input.email.trim().to_lowercase();
    let password    = input.password;

    // 2) Tra tenant từ meta DB (pool nil)
    let global_pool = state.shard.get_pool_for_tenant(&Uuid::nil());
    let tenant = sqlx::query!(
        r#"SELECT tenant_id, shard_id FROM tenant WHERE slug = $1"#,
        tenant_slug
    )
    .fetch_optional(global_pool)
    .await
    .map_err(AppError::from)? // chỉ dùng From cho sqlx::Error
    .ok_or_else(|| AppError::bad_request("Tenant không tồn tại hoặc slug không hợp lệ"))?;

    // 3) Lấy pool theo tenant và tìm user (email đã lowercase)
    let pool = state.shard.get_pool_for_tenant(&tenant.tenant_id);

    // Nếu bảng users có CHECK (email = lower(email)) thì so sánh trực tiếp email = $2
    let user = sqlx::query!(
        r#"
        SELECT tenant_id, user_id, email, name, password_hash
        FROM users
        WHERE tenant_id = $1 AND email = $2
        "#,
        tenant.tenant_id,
        email
    )
    .fetch_optional(pool)
    .await
    .map_err(AppError::from)?
    .ok_or_else(|| AppError::bad_request("Email hoặc mật khẩu không đúng"))?;

    // 4) Kiểm tra mật khẩu
    match bcrypt_verify(&password, &user.password_hash) {
        Ok(true) => {
            let expiration = (chrono::Utc::now().timestamp() + 3600) as usize;
            let claims = Claims {
                sub: user.user_id.to_string(),
                tenant_id: user.tenant_id.to_string(),
                exp: expiration,
            };

            let token = encode(&Header::default(), &claims, &EncodingKey::from_secret(SECRET_KEY))
                .map_err(|e| AppError::bad_request(format!("Lỗi tạo JWT: {e}")))?; // KHÔNG dùng internal

            Ok(Json(json!({
                "status": "ok",
                "token": token,
                "user": {
                    "id": user.user_id,
                    "email": user.email,
                    "name": user.name
                }
            })))
        }
        Ok(false) => Err(AppError::bad_request("Email hoặc mật khẩu không đúng")),
        Err(e) => Err(AppError::bad_request(format!("Lỗi kiểm tra mật khẩu: {e}"))),
    }
}

/// ✅ Trả về thông tin user đang đăng nhập
pub async fn whoami(
    Extension(auth_user): Extension<AuthUser>,
) -> Result<impl IntoResponse, AppError> {
    Ok(Json(json!({
        "user_id": auth_user.user_id,
        "tenant_id": auth_user.tenant_id,
    })))
}

/// ✅ Lấy danh sách user trong tenant
pub async fn list_users(
    Extension(auth_user): Extension<AuthUser>,
    State(state): State<Arc<AppState>>,
) -> Result<impl IntoResponse, AppError> {
    let is_admin = auth_user.tenant_id == Uuid::nil();
    let pool = state.shard.get_pool_for_tenant(&auth_user.tenant_id);

    let rows = if is_admin {
        sqlx::query(
            r#"
            SELECT u.tenant_id, t.name AS tenant_name, u.user_id, u.email, u.name, u.created_at
            FROM users u
            JOIN tenant t ON u.tenant_id = t.tenant_id
            ORDER BY u.created_at DESC
            "#
        )
        .fetch_all(pool)
        .await
    } else {
        sqlx::query(
            r#"
            SELECT u.tenant_id, t.name AS tenant_name, u.user_id, u.email, u.name, u.created_at
            FROM users u
            JOIN tenant t ON u.tenant_id = t.tenant_id
            WHERE u.tenant_id = $1
            ORDER BY u.created_at DESC
            "#
        )
        .bind(auth_user.tenant_id)
        .fetch_all(pool)
        .await
    }
    .map_err(AppError::from)?; // chỉ sqlx::Error mới dùng From

    let users: Vec<_> = rows
        .into_iter()
        .map(|row| {
            json!({
                "tenant_id": row.get::<Uuid, _>("tenant_id"),
                "tenant_name": row.get::<String, _>("tenant_name"),
                "user_id": row.get::<Uuid, _>("user_id"),
                "email": row.get::<String, _>("email"),
                "name": row.get::<String, _>("name"),
                "created_at": row.get::<DateTime<chrono::Utc>, _>("created_at"),
            })
        })
        .collect();

    Ok(Json(json!(users)))
}
