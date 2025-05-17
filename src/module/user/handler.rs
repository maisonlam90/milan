use axum::{extract::{State, Extension}, Json}; // ✅ Extension để lấy AuthUser từ middleware
use sqlx::PgPool;
use axum::http::StatusCode;
use bcrypt::verify;
use crate::module::user::{dto::{RegisterDto, LoginDto}, command::create_user};
use serde_json::json;
use jsonwebtoken::{encode, EncodingKey, Header};
use serde::{Serialize, Deserialize};
use crate::core::auth::AuthUser; // ✅ AuthUser từ middleware jwt_auth

#[derive(Debug, Serialize, Deserialize)]
struct Claims {
    sub: String,
    tenant_id: String,
    exp: usize,
}

const SECRET_KEY: &[u8] = b"super_secret_jwt_key";

/// ✅ Đăng ký người dùng mới
pub async fn register(
    State(pool): State<PgPool>,
    Json(input): Json<RegisterDto>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    match create_user(&pool, input).await {
        Ok(user) => Ok(Json(json!({ "status": "ok", "email": user.email, "name": user.name }))),
        Err(_) => Err(StatusCode::INTERNAL_SERVER_ERROR),
    }
}

/// ✅ Đăng nhập, trả về token JWT
pub async fn login(
    State(pool): State<PgPool>,
    Json(input): Json<LoginDto>,
) -> Result<Json<serde_json::Value>, StatusCode> {
    println!("🔐 Đăng nhập: tenant_id='{}', email='{}'", input.tenant_id, input.email);

    let row = sqlx::query!(
        r#"
        SELECT user_id, email, name, password_hash
        FROM users
        WHERE tenant_id = $1 AND email = $2
        "#,
        input.tenant_id,
        input.email
    )
    .fetch_optional(&pool)
    .await
    .map_err(|err| {
        eprintln!("❌ Lỗi truy vấn DB khi login: {:?}", err);
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    let user = match row {
        Some(user) => {
            println!("✅ Tìm thấy user: email='{}'", user.email);
            user
        }
        None => {
            eprintln!("❌ Không tìm thấy user với tenant_id='{}' email='{}'", input.tenant_id, input.email);
            return Err(StatusCode::UNAUTHORIZED);
        }
    };

    match verify(&input.password, &user.password_hash) {
        Ok(true) => {
            let expiration = chrono::Utc::now().timestamp() + 3600;
            let claims = Claims {
                sub: user.user_id.to_string(),
                tenant_id: input.tenant_id.to_string(),
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

/// ✅ Trả về thông tin user đang đăng nhập, lấy từ token JWT
pub async fn whoami(
    Extension(auth_user): Extension<AuthUser>, // 📥 Trích xuất user từ token đã xác thực
) -> Json<serde_json::Value> {
    Json(json!({
        "user_id": auth_user.user_id,
        "tenant_id": auth_user.tenant_id,
    }))
}
