use axum::{
    async_trait,
    extract::{FromRequest, Request},
    http::StatusCode,
    Json,
};
use serde::de::DeserializeOwned;
use std::ops::Deref;
use tracing::{debug, error}; // ✅ dùng tracing thay vì eprintln

/// Wrapper giúp log lỗi khi parse JSON thất bại
pub struct JsonWithLog<T>(pub T);

impl<T> Deref for JsonWithLog<T> {
    type Target = T;

    fn deref(&self) -> &Self::Target {
        &self.0
    }
}

#[async_trait]
impl<S, T> FromRequest<S> for JsonWithLog<T>
where
    S: Send + Sync,
    T: DeserializeOwned,
{
    type Rejection = StatusCode;

    async fn from_request(req: Request, state: &S) -> Result<Self, Self::Rejection> {
        let body = Json::<serde_json::Value>::from_request(req, state)
            .await
            .map_err(|err| {
                error!("❌ Lỗi đọc body JSON: {}", err);
                StatusCode::BAD_REQUEST
            })?;

        let value = body.0;

        match serde_json::from_value::<T>(value.clone()) {
            Ok(parsed) => Ok(JsonWithLog(parsed)),
            Err(err) => {
                debug!("❌ Deserialize JSON thất bại: {}\nDữ liệu: {}", err, value);
                Err(StatusCode::UNPROCESSABLE_ENTITY)
            }
        }
    }
}
