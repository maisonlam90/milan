use serde::{Deserialize, Serialize};

/// Sale Order struct
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SaleOrder {
    pub id: Option<i32>,
    pub name: String,
    pub state: String,
    pub date_order: String,
    pub partner_id: i32,
    pub user_id: Option<i32>,
    pub company_id: i32,
    pub amount_untaxed: f64,
    pub amount_tax: f64,
    pub amount_total: f64,
}

/// Sale Order Line struct
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SaleOrderLine {
    pub id: Option<i32>,
    pub order_id: i32,
    pub product_id: Option<i32>,
    pub name: String,
    pub product_uom_qty: f64,
    pub price_unit: f64,
    pub tax_rate: Option<f64>,
    pub price_tax: f64,
    pub price_subtotal: f64,
    pub price_total: f64,
}

/// Calculate line totals
pub fn calculate_line_totals(
    qty: f64,
    unit_price: f64,
    tax_rate: f64,
) -> (f64, f64, f64) {
    let subtotal = qty * unit_price;
    let tax = subtotal * tax_rate / 100.0;
    let total = subtotal + tax;
    (subtotal, tax, total)
}

/// Calculate order totals from lines (internal Rust function)
pub fn calculate_order_totals_internal(lines: &[SaleOrderLine]) -> (f64, f64, f64) {
    let mut amount_untaxed = 0.0;
    let mut amount_tax = 0.0;
    let mut amount_total = 0.0;

    for line in lines {
        amount_untaxed += line.price_subtotal;
        amount_tax += line.price_tax;
        amount_total += line.price_total;
    }

    (amount_untaxed, amount_tax, amount_total)
}

/// Validate sale order state transition
pub fn validate_state_transition(current_state: &str, new_state: &str) -> Result<(), String> {
    let valid_transitions = match current_state {
        "draft" => vec!["sent", "sale", "cancel"],
        "sent" => vec!["draft", "sale", "cancel"],
        "sale" => vec!["done", "cancel"],
        "done" => vec![],
        "cancel" => vec!["draft"],
        _ => return Err(format!("Invalid current state: {}", current_state)),
    };

    if valid_transitions.contains(&new_state) {
        Ok(())
    } else {
        Err(format!(
            "Invalid state transition from '{}' to '{}'",
            current_state, new_state
        ))
    }
}

/// Check if order can be modified
pub fn can_modify_order(state: &str) -> bool {
    matches!(state, "draft" | "sent")
}

/// Check if order can be cancelled
pub fn can_cancel_order(state: &str) -> bool {
    !matches!(state, "done" | "cancel")
}

/// Apply discount to line
pub fn apply_discount(price_unit: f64, discount_percent: f64) -> f64 {
    price_unit * (1.0 - discount_percent / 100.0)
}

/// Calculate delivery date based on customer lead time
pub fn calculate_delivery_date(order_date: &str, customer_lead: i32) -> String {
    // This is a simplified version - you'd need proper date handling
    format!("{}+{}days", order_date, customer_lead)
}

// WASM exports
#[no_mangle]
pub extern "C" fn calculate_line(
    qty: f64,
    unit_price: f64,
    tax_rate: f64,
) -> *mut std::os::raw::c_char {
    let (subtotal, tax, total) = calculate_line_totals(qty, unit_price, tax_rate);
    let result = serde_json::json!({
        "subtotal": subtotal,
        "tax": tax,
        "total": total,
    });
    
    let json_str = serde_json::to_string(&result).unwrap_or_else(|_| "{}".to_string());
    let c_str = std::ffi::CString::new(json_str).unwrap();
    c_str.into_raw()
}

#[no_mangle]
pub extern "C" fn validate_transition(
    current_state_ptr: *const std::os::raw::c_char,
    new_state_ptr: *const std::os::raw::c_char,
) -> *mut std::os::raw::c_char {
    unsafe {
        let current_state = std::ffi::CStr::from_ptr(current_state_ptr)
            .to_str()
            .unwrap_or("");
        let new_state = std::ffi::CStr::from_ptr(new_state_ptr)
            .to_str()
            .unwrap_or("");

        let result = match validate_state_transition(current_state, new_state) {
            Ok(_) => serde_json::json!({"valid": true, "message": "Valid transition"}),
            Err(msg) => serde_json::json!({"valid": false, "message": msg}),
        };

        let json_str = serde_json::to_string(&result).unwrap_or_else(|_| "{}".to_string());
        let c_str = std::ffi::CString::new(json_str).unwrap();
        c_str.into_raw()
    }
}

#[no_mangle]
pub extern "C" fn apply_line_discount(price_unit: f64, discount_percent: f64) -> f64 {
    apply_discount(price_unit, discount_percent)
}

/// Calculate order totals - nhận 3 arrays và sum lại
/// Args: subtotals array, taxes array, totals array (mỗi array là JSON string)
#[no_mangle]
pub extern "C" fn calculate_order_totals(
    subtotals_json_ptr: *const std::os::raw::c_char,
    taxes_json_ptr: *const std::os::raw::c_char,
    totals_json_ptr: *const std::os::raw::c_char,
) -> *mut std::os::raw::c_char {
    unsafe {
        // Parse JSON arrays
        let subtotals_str = std::ffi::CStr::from_ptr(subtotals_json_ptr)
            .to_str()
            .unwrap_or("[]");
        let taxes_str = std::ffi::CStr::from_ptr(taxes_json_ptr)
            .to_str()
            .unwrap_or("[]");
        let totals_str = std::ffi::CStr::from_ptr(totals_json_ptr)
            .to_str()
            .unwrap_or("[]");
        
        let subtotals: Vec<f64> = serde_json::from_str(subtotals_str).unwrap_or_default();
        let taxes: Vec<f64> = serde_json::from_str(taxes_str).unwrap_or_default();
        let totals: Vec<f64> = serde_json::from_str(totals_str).unwrap_or_default();
        
        // Sum arrays
        let amount_untaxed: f64 = subtotals.iter().sum();
        let amount_tax: f64 = taxes.iter().sum();
        let amount_total: f64 = totals.iter().sum();
        
        let result = serde_json::json!({
            "untaxed": amount_untaxed,
            "tax": amount_tax,
            "total": amount_total,
        });
        
        let json_str = serde_json::to_string(&result).unwrap_or_else(|_| "{}".to_string());
        let c_str = std::ffi::CString::new(json_str).unwrap();
        c_str.into_raw()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_calculate_line_totals() {
        let (subtotal, tax, total) = calculate_line_totals(10.0, 100.0, 10.0);
        assert_eq!(subtotal, 1000.0);
        assert_eq!(tax, 100.0);
        assert_eq!(total, 1100.0);
    }

    #[test]
    fn test_state_transitions() {
        assert!(validate_state_transition("draft", "sent").is_ok());
        assert!(validate_state_transition("draft", "sale").is_ok());
        assert!(validate_state_transition("draft", "done").is_err());
        assert!(validate_state_transition("done", "cancel").is_err());
    }

    #[test]
    fn test_can_modify_order() {
        assert!(can_modify_order("draft"));
        assert!(can_modify_order("sent"));
        assert!(!can_modify_order("sale"));
        assert!(!can_modify_order("done"));
    }

    #[test]
    fn test_apply_discount() {
        let discounted_price = apply_discount(100.0, 10.0);
        assert_eq!(discounted_price, 90.0);
    }
}

