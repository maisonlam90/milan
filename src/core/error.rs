use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use std::fmt;

#[derive(Debug, Serialize, Clone)]
pub struct ErrorResponse {
    pub code: &'static str,
    pub message: String,
}

impl fmt::Display for ErrorResponse {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}: {}", self.code, self.message)
    }
}

impl IntoResponse for ErrorResponse {
    fn into_response(self) -> Response {
        (StatusCode::BAD_REQUEST, Json(self)).into_response()
    }
}

#[derive(Debug)]
pub enum AppError {
    Validation(ErrorResponse),
    Db(sqlx::Error),
}

impl From<sqlx::Error> for AppError {
    fn from(e: sqlx::Error) -> Self {
        AppError::Db(e)
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        match self {
            AppError::Validation(err) => err.into_response(),
            AppError::Db(ref e) => {
                // Ghi log rõ ràng ở backend
                tracing::error!("❌ SQLx error: {e:?}");

                let payload = ErrorResponse {
                    code: "db_error",
                    message: match e {
                        sqlx::Error::Database(db_err) => {
                            // Hiện message chi tiết của DB (ví dụ: CHECK constraint failed)
                            db_err.message().to_string()
                        }
                        _ => "Lỗi hệ thống (DB)".into(),
                    },
                };

                (StatusCode::INTERNAL_SERVER_ERROR, Json(payload)).into_response()
            }
        }
    }
}
impl AppError {
    pub fn bad_request(msg: impl Into<String>) -> Self {
        AppError::Validation(ErrorResponse {
            code: "bad_request",
            message: msg.into(),
        })
    }
}
