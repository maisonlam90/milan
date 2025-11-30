use axum::{
    extract::Query,
    http::HeaderMap,
    response::Json,
    routing::get,
    Router,
};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;
use crate::core::i18n::{I18n, DEFAULT_LANGUAGE};
use crate::core::state::AppState;
use std::sync::Arc;

#[derive(Debug, Deserialize)]
pub struct TranslationsQuery {
    lang: Option<String>,
    namespace: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct TranslationsResponse {
    pub language: String,
    pub translations: Value,
}

/// Get translations for a specific language
pub async fn get_translations(
    headers: HeaderMap,
    Query(params): Query<TranslationsQuery>,
) -> Json<TranslationsResponse> {
    // Determine language from query param or headers
    let lang = params.lang
        .or_else(|| {
            // Try to extract from headers
            let i18n = I18n::from_headers(&headers);
            Some(i18n.language().to_string())
        })
        .unwrap_or_else(|| DEFAULT_LANGUAGE.to_string());

    // Load all translations for the language
    // This is a simplified version - in production, you might want to load from files
    let translations = load_translations_for_language(&lang);

    Json(TranslationsResponse {
        language: lang,
        translations,
    })
}

/// Get list of supported languages
pub async fn get_supported_languages() -> Json<HashMap<String, String>> {
    let mut languages = HashMap::new();
    
    languages.insert("vi".to_string(), "Tiếng Việt".to_string());
    languages.insert("en".to_string(), "English".to_string());
    languages.insert("zh-cn".to_string(), "中文".to_string());
    languages.insert("es".to_string(), "Español".to_string());
    languages.insert("ar".to_string(), "العربية".to_string());

    Json(languages)
}

/// Load translations for a specific language
fn load_translations_for_language(lang: &str) -> Value {
    // This function loads translations from the static TRANSLATIONS
    // In a real implementation, you might want to cache this or load from files
    match lang {
        "vi" => serde_json::from_str(include_str!("../../locales/vi/translations.json"))
            .unwrap_or_else(|_| serde_json::json!({})),
        "en" => serde_json::from_str(include_str!("../../locales/en/translations.json"))
            .unwrap_or_else(|_| serde_json::json!({})),
        "zh-cn" => serde_json::from_str(include_str!("../../locales/zh-cn/translations.json"))
            .unwrap_or_else(|_| serde_json::json!({})),
        "es" => serde_json::from_str(include_str!("../../locales/es/translations.json"))
            .unwrap_or_else(|_| serde_json::json!({})),
        "ar" => serde_json::from_str(include_str!("../../locales/ar/translations.json"))
            .unwrap_or_else(|_| serde_json::json!({})),
        _ => serde_json::from_str(include_str!("../../locales/vi/translations.json"))
            .unwrap_or_else(|_| serde_json::json!({})), // Fallback to Vietnamese (default)
    }
}

/// Create i18n router
pub fn routes() -> Router<Arc<AppState>> {
    Router::new()
        .route("/i18n/translations", get(get_translations))
        .route("/i18n/languages", get(get_supported_languages))
}
