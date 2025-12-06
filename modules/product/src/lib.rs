use serde::{Deserialize, Serialize};

/// Product Template struct
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProductTemplate {
    pub id: Option<i32>,
    pub name: String,
    pub default_code: Option<String>,
    pub active: bool,
    pub type_: String, // "consu", "service", "product"
    pub categ_id: i32,
    pub list_price: f64,
    pub standard_price: f64,
    pub uom_id: i32,
    pub uom_po_id: Option<i32>,
    pub company_id: Option<i32>,
    pub barcode: Option<String>,
    pub sale_ok: bool,
    pub purchase_ok: bool,
    pub tracking: String, // "none", "serial", "lot"
    pub weight: Option<f64>,
    pub volume: Option<f64>,
    pub sale_delay: Option<i32>,
}

/// Product Variant struct
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProductVariant {
    pub id: Option<i32>,
    pub product_tmpl_id: i32,
    pub default_code: Option<String>,
    pub barcode: Option<String>,
    pub standard_price: f64,
    pub list_price: f64,
    pub volume: Option<f64>,
    pub weight: Option<f64>,
}

/// Calculate price with margin (markup)
/// Given cost and margin percentage, returns sale price
pub fn calculate_price_with_margin(cost: f64, margin_percent: f64) -> f64 {
    cost * (1.0 + margin_percent / 100.0)
}

/// Calculate margin from cost and sale price
/// Returns margin percentage
pub fn calculate_margin(cost: f64, sale_price: f64) -> f64 {
    if cost == 0.0 {
        return 0.0;
    }
    ((sale_price - cost) / cost) * 100.0
}

/// Calculate profit from cost and sale price
pub fn calculate_profit(cost: f64, sale_price: f64) -> f64 {
    sale_price - cost
}

/// Calculate total value of inventory (qty * cost)
pub fn calculate_inventory_value(qty: f64, cost: f64) -> f64 {
    qty * cost
}

/// Validate product code format
/// Product code should be alphanumeric, uppercase, and can contain hyphens
pub fn validate_product_code(code: &str) -> Result<(), String> {
    if code.is_empty() {
        return Err("Product code cannot be empty".to_string());
    }
    
    if code.len() > 50 {
        return Err("Product code too long (max 50 characters)".to_string());
    }
    
    for ch in code.chars() {
        if !ch.is_alphanumeric() && ch != '-' && ch != '_' {
            return Err(format!("Invalid character '{}' in product code", ch));
        }
    }
    
    Ok(())
}

/// Check if product type is valid
pub fn is_valid_product_type(type_: &str) -> bool {
    matches!(type_, "consu" | "service" | "product")
}

/// Check if tracking type is valid
pub fn is_valid_tracking_type(tracking: &str) -> bool {
    matches!(tracking, "none" | "serial" | "lot")
}

/// Calculate shipping weight (product weight + packaging)
pub fn calculate_shipping_weight(product_weight: f64, packaging_weight: f64) -> f64 {
    product_weight + packaging_weight
}

/// Calculate discount price
pub fn calculate_discount_price(list_price: f64, discount_percent: f64) -> f64 {
    list_price * (1.0 - discount_percent / 100.0)
}

/// Validate price is positive
pub fn validate_price(price: f64) -> Result<(), String> {
    if price < 0.0 {
        return Err("Price cannot be negative".to_string());
    }
    Ok(())
}

// WASM exports
#[no_mangle]
pub extern "C" fn calculate_price_margin(
    cost: f64,
    margin_percent: f64,
) -> *mut std::os::raw::c_char {
    let sale_price = calculate_price_with_margin(cost, margin_percent);
    let profit = calculate_profit(cost, sale_price);
    
    let result = serde_json::json!({
        "sale_price": sale_price,
        "profit": profit,
        "margin": margin_percent,
    });
    
    let json_str = serde_json::to_string(&result).unwrap_or_else(|_| "{}".to_string());
    let c_str = std::ffi::CString::new(json_str).unwrap();
    c_str.into_raw()
}

#[no_mangle]
pub extern "C" fn calculate_margin_from_prices(
    cost: f64,
    sale_price: f64,
) -> *mut std::os::raw::c_char {
    let margin = calculate_margin(cost, sale_price);
    let profit = calculate_profit(cost, sale_price);
    
    let result = serde_json::json!({
        "margin": margin,
        "profit": profit,
    });
    
    let json_str = serde_json::to_string(&result).unwrap_or_else(|_| "{}".to_string());
    let c_str = std::ffi::CString::new(json_str).unwrap();
    c_str.into_raw()
}

#[no_mangle]
pub extern "C" fn validate_code(
    code_ptr: *const std::os::raw::c_char,
) -> *mut std::os::raw::c_char {
    unsafe {
        let code = std::ffi::CStr::from_ptr(code_ptr)
            .to_str()
            .unwrap_or("");

        let result = match validate_product_code(code) {
            Ok(_) => serde_json::json!({"valid": true, "message": "Valid product code"}),
            Err(msg) => serde_json::json!({"valid": false, "message": msg}),
        };

        let json_str = serde_json::to_string(&result).unwrap_or_else(|_| "{}".to_string());
        let c_str = std::ffi::CString::new(json_str).unwrap();
        c_str.into_raw()
    }
}

#[no_mangle]
pub extern "C" fn calculate_inventory_total(qty: f64, cost: f64) -> f64 {
    calculate_inventory_value(qty, cost)
}

#[no_mangle]
pub extern "C" fn apply_discount(list_price: f64, discount_percent: f64) -> f64 {
    calculate_discount_price(list_price, discount_percent)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_calculate_price_with_margin() {
        let sale_price = calculate_price_with_margin(100.0, 20.0);
        assert_eq!(sale_price, 120.0);
    }

    #[test]
    fn test_calculate_margin() {
        let margin = calculate_margin(100.0, 120.0);
        assert_eq!(margin, 20.0);
    }

    #[test]
    fn test_calculate_profit() {
        let profit = calculate_profit(100.0, 120.0);
        assert_eq!(profit, 20.0);
    }

    #[test]
    fn test_validate_product_code() {
        assert!(validate_product_code("PROD-001").is_ok());
        assert!(validate_product_code("ABC123").is_ok());
        assert!(validate_product_code("").is_err());
        assert!(validate_product_code("PROD@001").is_err());
    }

    #[test]
    fn test_is_valid_product_type() {
        assert!(is_valid_product_type("consu"));
        assert!(is_valid_product_type("service"));
        assert!(is_valid_product_type("product"));
        assert!(!is_valid_product_type("invalid"));
    }

    #[test]
    fn test_calculate_discount_price() {
        let discounted = calculate_discount_price(100.0, 10.0);
        assert_eq!(discounted, 90.0);
    }
}

