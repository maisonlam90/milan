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
use tracing::{debug, error}; // 👈 log nhẹ nhàng hơn

#[derive(Debug, Serialize, Deserialize)]
pub struct Claims {
    pub sub: String,
    pub tenant_id: String,
    pub exp: usize,
}

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
            .ok_or_else(|| {
                error!("❌ Không tìm thấy header Authorization");
                StatusCode::UNAUTHORIZED
            })?;

        let token = auth_header.strip_prefix("Bearer ")
            .ok_or_else(|| {
                error!("❌ Authorization không phải Bearer token");
                StatusCode::UNAUTHORIZED
            })?;

        let claims = decode::<Claims>(
            token,
            &DecodingKey::from_secret(b"super_secret_jwt_key"),
            &Validation::default(),
        )
        .map_err(|err| {
            error!("❌ Lỗi decode JWT: {:?}", err);
            StatusCode::UNAUTHORIZED
        })?
        .claims;

        let user_id = Uuid::parse_str(&claims.sub).map_err(|err| {
            error!("❌ Lỗi parse sub UUID: {:?}", err);
            StatusCode::UNAUTHORIZED
        })?;

        let tenant_id = Uuid::parse_str(&claims.tenant_id).map_err(|err| {
            error!("❌ Lỗi parse tenant_id UUID: {:?}", err);
            StatusCode::UNAUTHORIZED
        })?;

        Ok(AuthUser {
            user_id,
            tenant_id,
        })
    }
}

pub async fn jwt_auth(
    mut req: AxumRequest<axum::body::Body>,
    next: Next,
) -> Result<Response, StatusCode> {
    debug!("🔐 Middleware nhận request: {:?}", req.uri()); // <-- log luôn, không phụ thuộc debug_assertions

    let headers = req.headers();
    let auth_header = headers.get("Authorization")
        .and_then(|h| h.to_str().ok())
        .ok_or_else(|| {
            error!("❌ Không tìm thấy header Authorization (middleware)");
            StatusCode::UNAUTHORIZED
        })?;

    let token = auth_header.strip_prefix("Bearer ")
        .ok_or_else(|| {
            error!("❌ Authorization không phải Bearer token (middleware)");
            StatusCode::UNAUTHORIZED
        })?;

    let claims = decode::<Claims>(
        token,
        &DecodingKey::from_secret(b"super_secret_jwt_key"),
        &Validation::default(),
    )
    .map_err(|err| {
        error!("❌ Middleware decode JWT lỗi: {:?}", err);
        StatusCode::UNAUTHORIZED
    })?
    .claims;

    let user = AuthUser {
        user_id: Uuid::parse_str(&claims.sub).map_err(|err| {
            error!("❌ Middleware parse user_id UUID lỗi: {:?}", err);
            StatusCode::UNAUTHORIZED
        })?,
        tenant_id: Uuid::parse_str(&claims.tenant_id).map_err(|err| {
            error!("❌ Middleware parse tenant_id UUID lỗi: {:?}", err);
            StatusCode::UNAUTHORIZED
        })?,
    };

    req.extensions_mut().insert(user);

    Ok(next.run(req).await)
}
