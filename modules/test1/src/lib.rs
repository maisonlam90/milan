use serde::{Deserialize, Serialize};

/// Test Item struct
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TestItem {
    pub id: Option<i32>,
    pub name: String,
    pub code: Option<String>,
    pub active: bool,
    pub status: String,
    pub category_id: Option<i32>,
    pub price: f64,
    pub quantity: i32,
}

/// Test Item Line struct
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TestItemLine {
    pub id: Option<i32>,
    pub test_item_id: i32,
    pub name: String,
    pub value: f64,
    pub unit: Option<String>,
}

/// Calculate total value
pub fn calculate_total(price: f64, quantity: i32) -> f64 {
    price * quantity as f64
}

/// Validate test code format
pub fn validate_test_code(code: &str) -> Result<(), String> {
    if code.is_empty() {
        return Err("Test code cannot be empty".to_string());
    }
    
    if code.len() > 20 {
        return Err("Test code too long (max 20 characters)".to_string());
    }
    
    for ch in code.chars() {
        if !ch.is_alphanumeric() && ch != '-' && ch != '_' {
            return Err(format!("Invalid character '{}' in test code", ch));
        }
    }
    
    Ok(())
}

/// Check if status is valid
pub fn is_valid_status(status: &str) -> bool {
    matches!(status, "draft" | "active" | "archived")
}

// WASM exports
#[no_mangle]
pub extern "C" fn calculate_total_value(
    price: f64,
    quantity: f64,
) -> f64 {
    calculate_total(price, quantity as i32)
}

#[no_mangle]
pub extern "C" fn validate_code(
    code_ptr: *const std::os::raw::c_char,
) -> *mut std::os::raw::c_char {
    unsafe {
        let code = std::ffi::CStr::from_ptr(code_ptr)
            .to_str()
            .unwrap_or("");

        let result = match validate_test_code(code) {
            Ok(_) => serde_json::json!({"valid": true, "message": "Valid test code"}),
            Err(msg) => serde_json::json!({"valid": false, "message": msg}),
        };

        let json_str = serde_json::to_string(&result).unwrap_or_else(|_| "{}".to_string());
        let c_str = std::ffi::CString::new(json_str).unwrap();
        c_str.into_raw()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_calculate_total() {
        assert_eq!(calculate_total(100.0, 5), 500.0);
        assert_eq!(calculate_total(50.0, 0), 0.0);
    }

    #[test]
    fn test_validate_test_code() {
        assert!(validate_test_code("TEST-001").is_ok());
        assert!(validate_test_code("ABC123").is_ok());
        assert!(validate_test_code("").is_err());
        assert!(validate_test_code("TEST@001").is_err());
    }

    #[test]
    fn test_is_valid_status() {
        assert!(is_valid_status("draft"));
        assert!(is_valid_status("active"));
        assert!(is_valid_status("archived"));
        assert!(!is_valid_status("invalid"));
    }
}

