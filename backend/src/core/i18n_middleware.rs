use axum::{
    extract::Request,
    middleware::Next,
    response::Response,
};
use crate::core::i18n::I18n;

/// Middleware to extract language from request headers and add I18n to request extensions
pub async fn i18n_middleware(mut request: Request, next: Next) -> Response {
    let headers = request.headers();
    let i18n = I18n::from_headers(headers);
    
    // Add I18n to request extensions so handlers can access it
    request.extensions_mut().insert(i18n);
    
    next.run(request).await
}

/// Extract I18n from request extensions
pub fn get_i18n_from_request(request: &Request) -> Option<I18n> {
    request.extensions().get::<I18n>().cloned()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_i18n_middleware() {
        // Test sẽ được implement khi có test framework
    }
}
