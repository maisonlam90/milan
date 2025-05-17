// ==========================
// 📁 src/core/auth.rs
// ==========================

use axum::{
    async_trait,
    extract::FromRequestParts,
    http::{request::Parts, StatusCode, Request as AxumRequest},
    middleware::Next,
    response::Response,
};
use jsonwebtoken::{decode, DecodingKey, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Giải mã token JWT từ Authorization header
#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,
    pub tenant_id: String,
    pub exp: usize,
}

/// User đã xác thực qua token JWT
#[derive(Debug, Clone)]
pub struct AuthUser {
    pub user_id: Uuid,
    pub tenant_id: Uuid,
}

#[async_trait]
impl<S> FromRequestParts<S> for AuthUser
where
    S: Send + Sync,
{
    type Rejection = StatusCode;

    async fn from_request_parts(
        parts: &mut Parts,
        _state: &S,
    ) -> Result<Self, Self::Rejection> {
        let auth_header = parts.headers.get("Authorization")
            .and_then(|h| h.to_str().ok())
            .ok_or(StatusCode::UNAUTHORIZED)?;

        let token = auth_header.strip_prefix("Bearer ")
            .ok_or(StatusCode::UNAUTHORIZED)?;

        let claims = decode::<Claims>(
            token,
            &DecodingKey::from_secret(b"super_secret_jwt_key"),
            &Validation::default(),
        )
        .map_err(|_| StatusCode::UNAUTHORIZED)?
        .claims;

        Ok(AuthUser {
            user_id: Uuid::parse_str(&claims.sub).map_err(|_| StatusCode::UNAUTHORIZED)?,
            tenant_id: Uuid::parse_str(&claims.tenant_id).map_err(|_| StatusCode::UNAUTHORIZED)?,
        })
    }
}

/// Middleware kiểm tra token, giải mã và gắn AuthUser vào request
pub async fn jwt_auth(
    mut req: AxumRequest<axum::body::Body>,
    next: Next,
) -> Result<Response, StatusCode> {
    let headers = req.headers();
    let auth_header = headers.get("Authorization")
        .and_then(|h| h.to_str().ok())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let token = auth_header.strip_prefix("Bearer ")
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let claims = decode::<Claims>(
        token,
        &DecodingKey::from_secret(b"super_secret_jwt_key"),
        &Validation::default(),
    )
    .map_err(|_| StatusCode::UNAUTHORIZED)?
    .claims;

    let user = AuthUser {
        user_id: Uuid::parse_str(&claims.sub).map_err(|_| StatusCode::UNAUTHORIZED)?,
        tenant_id: Uuid::parse_str(&claims.tenant_id).map_err(|_| StatusCode::UNAUTHORIZED)?,
    };

    req.extensions_mut().insert(user);

    Ok(next.run(req).await)
}
