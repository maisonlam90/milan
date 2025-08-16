use axum::{extract::{State, Extension}, Json};
use std::sync::Arc;
use sqlx::Row;
use axum::http::StatusCode;
use bcrypt::verify;
use crate::module::user::{dto::{RegisterDto, LoginDto}, command::create_user};
use serde_json::json;
use jsonwebtoken::{encode, EncodingKey, Header};
use serde::{Serialize, Deserialize};
use uuid::Uuid;
use chrono::DateTime;

use crate::core::{auth::AuthUser, state::AppState};

#[derive(Debug, Serialize, Deserialize)]
struct Claims {
    sub: String,
    tenant_id: String,
    exp: usize,
}

const SECRET_KEY: &[u8] = b"super_secret_jwt_key";

/// ✅ Đăng ký người dùng mới
pub async fn register(
    State(state): State<Arc<AppState>>,
    Json(input): Json<RegisterDto>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    let pool = state.shard.get_pool_for_tenant(&Uuid::nil());
    match create_user(pool, input).await {
        Ok(user) => Ok(Json(json!({ "status": "ok", "email": user.email, "name": user.name }))),
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR),
    }
}

/// ✅ Đăng nhập, trả về token JWT
pub async fn login(
    State(state): State<Arc<AppState>>,
    Json(input): Json<LoginDto>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    println!("🔐 Đăng nhập: email='{}' | tenant_slug='{}'", input.email, input.tenant_slug);

    let global_pool = state.shard.get_pool_for_tenant(&Uuid::nil());

    let tenant = sqlx::query!(
        "SELECT tenant_id, shard_id FROM tenant WHERE slug = $1",
        input.tenant_slug
    )
    .fetch_optional(global_pool)
    .await
    .map_err(|err| {
        eprintln!("❌ Lỗi khi tìm tenant từ slug: {:?}", err);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    let (tenant_id, _shard_id) = match tenant {
        Some(t) => (t.tenant_id, t.shard_id),
        None => {
            eprintln!("❌ Không tìm thấy tenant với slug='{}'", input.tenant_slug);
            return Err(StatusCode::UNAUTHORIZED);
        }
    };

    let pool = state.shard.get_pool_for_tenant(&tenant_id);

    let row = sqlx::query!(
        r#"
        SELECT tenant_id, user_id, email, name, password_hash
        FROM users
        WHERE email = $1 AND tenant_id = $2
        "#,
        input.email,
        tenant_id
    )
    .fetch_optional(pool)
    .await
    .map_err(|err| {
        eprintln!("❌ Lỗi truy vấn DB khi login: {:?}", err);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    let user = match row {
        Some(user) => user,
        None => {
            eprintln!("❌ Không tìm thấy user với email='{}' và tenant_slug='{}'", input.email, input.tenant_slug);
            return Err(StatusCode::UNAUTHORIZED);
        }
    };

    match verify(&input.password, &user.password_hash) {
        Ok(true) => {
            let expiration = chrono::Utc::now().timestamp() + 3600;
            let claims = Claims {
                sub: user.user_id.to_string(),
                tenant_id: user.tenant_id.to_string(),
                exp: expiration as usize,
            };

            let token = encode(&Header::default(), &claims, &EncodingKey::from_secret(SECRET_KEY))
                .map_err(|err| {
                    eprintln!("❌ Lỗi khi tạo JWT: {:?}", err);
                    StatusCode::INTERNAL_SERVER_ERROR
                })?;

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
        Ok(false) => {
            eprintln!("❌ Sai mật khẩu cho email='{}'", user.email);
            Err(StatusCode::UNAUTHORIZED)
        }
        Err(err) => {
            eprintln!("❌ Lỗi khi kiểm tra mật khẩu: {:?}", err);
            Err(StatusCode::INTERNAL_SERVER_ERROR)
        }
    }
}

/// ✅ Trả về thông tin user đang đăng nhập
pub async fn whoami(
    Extension(auth_user): Extension<AuthUser>,
) -> Json<serde_json::Value> {
    Json(json!({
        "user_id": auth_user.user_id,
        "tenant_id": auth_user.tenant_id,
    }))
}

/// ✅ Lấy danh sách user trong tenant
pub async fn list_users(
    Extension(auth_user): Extension<AuthUser>,
    State(state): State<Arc<AppState>>,
) -> Result<Json<serde_json::Value>, StatusCode> {
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
    .map_err(|e| {
        eprintln!("❌ Lỗi truy vấn danh sách users: {:?}", e);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

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
