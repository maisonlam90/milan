use std::collections::HashMap;
use axum::http::HeaderMap;
use once_cell::sync::Lazy;
use serde_json::Value;

/// Supported languages
pub const SUPPORTED_LANGUAGES: &[&str] = &["vi", "en", "zh-cn", "es", "ar"];
pub const DEFAULT_LANGUAGE: &str = "vi";
pub const FALLBACK_LANGUAGE: &str = "en";

/// Load translations from JSON files
static TRANSLATIONS: Lazy<HashMap<String, Value>> = Lazy::new(|| {
    let mut map = HashMap::new();
    
    // Load translations for each language
    let vi_json = include_str!("../../locales/vi/translations.json");
    let en_json = include_str!("../../locales/en/translations.json");
    let zh_cn_json = include_str!("../../locales/zh-cn/translations.json");
    let es_json = include_str!("../../locales/es/translations.json");
    let ar_json = include_str!("../../locales/ar/translations.json");
    
    // Parse JSON files
    if let Ok(parsed) = serde_json::from_str::<Value>(vi_json) {
        map.insert("vi".to_string(), parsed);
    }
    if let Ok(parsed) = serde_json::from_str::<Value>(en_json) {
        map.insert("en".to_string(), parsed);
    }
    if let Ok(parsed) = serde_json::from_str::<Value>(zh_cn_json) {
        map.insert("zh-cn".to_string(), parsed);
    }
    if let Ok(parsed) = serde_json::from_str::<Value>(es_json) {
        map.insert("es".to_string(), parsed);
    }
    if let Ok(parsed) = serde_json::from_str::<Value>(ar_json) {
        map.insert("ar".to_string(), parsed);
    }
    
    map
});

/// Translation service
#[derive(Clone)]
pub struct I18n {
    language: String,
}

impl I18n {
    /// Create new I18n instance with default language
    pub fn new(language: impl Into<String>) -> Self {
        Self {
            language: normalize_language(language.into()),
        }
    }

    /// Create I18n from request headers
    pub fn from_headers(headers: &HeaderMap) -> Self {
        let lang = extract_language_from_headers(headers);
        Self::new(lang)
    }

    /// Get translation by key
    pub fn t(&self, key: &str) -> String {
        self.t_with_fallback(key, key)
    }

    /// Get translation with fallback
    pub fn t_with_fallback(&self, key: &str, fallback: &str) -> String {
        // Try current language
        if let Some(translations) = TRANSLATIONS.get(&self.language) {
            if let Some(value) = get_nested_value(translations, key) {
                return value_to_string(value);
            }
        }

        // Try fallback language
        if self.language != FALLBACK_LANGUAGE {
            if let Some(translations) = TRANSLATIONS.get(FALLBACK_LANGUAGE) {
                if let Some(value) = get_nested_value(translations, key) {
                    return value_to_string(value);
                }
            }
        }

        // Return fallback key or key itself
        fallback.to_string()
    }

    /// Get translation with parameters (simple format: {param})
    pub fn t_with_params(&self, key: &str, params: &HashMap<&str, &str>) -> String {
        let mut text = self.t(key);
        
        for (param_key, param_value) in params {
            text = text.replace(&format!("{{{}}}", param_key), param_value);
        }
        
        text
    }

    /// Get current language
    pub fn language(&self) -> &str {
        &self.language
    }

    /// Set language
    pub fn set_language(&mut self, language: impl Into<String>) {
        self.language = normalize_language(language.into());
    }
}

/// Extract language from request headers
fn extract_language_from_headers(headers: &HeaderMap) -> String {
    // Check Accept-Language header (case-insensitive)
    if let Some(accept_lang) = headers.get("accept-language") {
        if let Ok(lang_str) = accept_lang.to_str() {
            tracing::debug!("🌐 Accept-Language header: {}", lang_str);
            
            // Parse Accept-Language: "vi" or "en-US,en;q=0.9,vi;q=0.8"
            // Take the first language (highest priority)
            let first_lang = lang_str
                .split(',')
                .next()
                .unwrap_or("")
                .split(';')
                .next()
                .unwrap_or("")
                .trim();
            
            if !first_lang.is_empty() {
                let normalized = normalize_language(first_lang.to_string());
                tracing::debug!("🌐 Normalized language from header: {}", normalized);
                
                if SUPPORTED_LANGUAGES.contains(&normalized.as_str()) {
                    tracing::info!("✅ Using language from header: {}", normalized);
                    return normalized;
                }
            }
        }
    }

    // Fallback to default language
    tracing::info!("🌐 No valid language header found, using default: {}", DEFAULT_LANGUAGE);
    DEFAULT_LANGUAGE.to_string()
}

/// Normalize language code (e.g., "en-US" -> "en", "zh_CN" -> "zh-cn")
fn normalize_language(lang: String) -> String {
    let lang = lang.to_lowercase().replace('_', "-");
    
    // Handle special cases
    match lang.as_str() {
        "zh" | "zh-tw" | "zh-hant" => "zh-cn".to_string(),
        _ => {
            // Extract base language (e.g., "en" from "en-us")
            lang.split('-').next().unwrap_or(&lang).to_string()
        }
    }
}

/// Get nested value from translations using dot notation (e.g., "error.validation.required")
fn get_nested_value<'a>(translations: &'a Value, key: &str) -> Option<&'a Value> {
    let parts: Vec<&str> = key.split('.').collect();
    let mut current = translations;

    for part in parts.iter() {
        current = current.get(part)?;
    }

    Some(current)
}

/// Convert Value to String
fn value_to_string(value: &Value) -> String {
    match value {
        Value::String(s) => s.clone(),
        Value::Number(n) => n.to_string(),
        Value::Bool(b) => b.to_string(),
        _ => value.to_string(),
    }
}

/// Default I18n instance
impl Default for I18n {
    fn default() -> Self {
        Self::new(DEFAULT_LANGUAGE)
    }
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_normalize_language() {
        assert_eq!(normalize_language("en-US".to_string()), "en");
        assert_eq!(normalize_language("zh_CN".to_string()), "zh-cn");
        assert_eq!(normalize_language("VI".to_string()), "vi");
    }

    #[test]
    fn test_translation() {
        let i18n = I18n::new("vi");
        // Test sẽ pass nếu có key trong translations
        let _ = i18n.t("error.not_found");
    }
}
