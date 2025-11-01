use axum::response::IntoResponse;
use axum::http::StatusCode;
use tracing::error;

pub async fn log_and_respond<E: std::error::Error>(err: E) -> impl IntoResponse {
    error!("❌ Internal server error: {:?}", err);
    StatusCode::INTERNAL_SERVER_ERROR
}