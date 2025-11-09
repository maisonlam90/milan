use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use std::fmt;
use crate::core::i18n::I18n;

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
    InternalServerError(String),
    NotFound(String), // ✅ Thêm variant NotFound
}

impl From<sqlx::Error> for AppError {
    fn from(e: sqlx::Error) -> Self {
        AppError::Db(e)
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        // Use default i18n for error messages
        // In production, you might want to extract i18n from request extensions
        let i18n = I18n::default();
        
        match self {
            AppError::Validation(err) => err.into_response(),

            AppError::Db(ref e) => {
                tracing::error!("❌ SQLx error: {e:?}");

                let payload = ErrorResponse {
                    code: "db_error",
                    message: match e {
                        sqlx::Error::Database(db_err) => db_err.message().to_string(),
                        _ => i18n.t("error.db_error"),
                    },
                };

                (StatusCode::INTERNAL_SERVER_ERROR, Json(payload)).into_response()
            }

            AppError::InternalServerError(msg) => {
                tracing::error!("❌ Internal error: {msg}");
                let payload = ErrorResponse {
                    code: "internal_error",
                    message: msg,
                };
                (StatusCode::INTERNAL_SERVER_ERROR, Json(payload)).into_response()
            }

            AppError::NotFound(msg) => {
                let payload = ErrorResponse {
                    code: "not_found",
                    message: msg,
                };
                (StatusCode::NOT_FOUND, Json(payload)).into_response()
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

    pub fn internal(msg: impl Into<String>) -> Self {
        AppError::InternalServerError(msg.into())
    }

    pub fn not_found(msg: impl Into<String>) -> Self {
        AppError::NotFound(msg.into())
    }

    /// Create error with i18n translation
    pub fn bad_request_i18n(i18n: &I18n, key: &str) -> Self {
        AppError::Validation(ErrorResponse {
            code: "bad_request",
            message: i18n.t(key),
        })
    }

    /// Create not found error with i18n
    pub fn not_found_i18n(i18n: &I18n, key: &str) -> Self {
        AppError::NotFound(i18n.t(key))
    }

    /// Create internal error with i18n
    pub fn internal_i18n(i18n: &I18n, key: &str) -> Self {
        AppError::InternalServerError(i18n.t(key))
    }
}
