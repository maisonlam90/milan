use serde::{Serialize, Deserialize};
use uuid::Uuid;

// ============================================================
// METADATA STRUCTS
// ============================================================

#[derive(Debug, Serialize, Deserialize)]
pub struct InvoiceMetadata {
    pub move_types: Vec<MoveTypeOption>,
    pub states: Vec<StateOption>,
    pub payment_states: Vec<PaymentStateOption>,
    pub journals: Vec<JournalOption>,
    pub payment_terms: Vec<PaymentTermOption>,
    pub payment_methods: Vec<PaymentMethodOption>,
    pub fiscal_positions: Vec<FiscalPositionOption>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct MoveTypeOption {
    pub value: String,
    pub label: String,
    pub description: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct StateOption {
    pub value: String,
    pub label: String,
    pub description: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PaymentStateOption {
    pub value: String,
    pub label: String,
    pub description: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct JournalOption {
    pub id: Uuid,
    pub name: String,
    pub code: String,
    pub r#type: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PaymentTermOption {
    pub id: Uuid,
    pub name: String,
    pub note: Option<String>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PaymentMethodOption {
    pub id: Uuid,
    pub name: String,
    pub code: String,
    pub payment_type: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FiscalPositionOption {
    pub id: Uuid,
    pub name: String,
    pub note: Option<String>,
}

// ============================================================
// HELPER FUNCTIONS
// ============================================================

impl InvoiceMetadata {
    pub fn default() -> Self {
        Self {
            move_types: vec![
                MoveTypeOption {
                    value: "out_invoice".to_string(),
                    label: "Customer Invoice".to_string(),
                    description: Some("Invoice sent to customers".to_string()),
                },
                MoveTypeOption {
                    value: "in_invoice".to_string(),
                    label: "Vendor Bill".to_string(),
                    description: Some("Bill received from suppliers".to_string()),
                },
                MoveTypeOption {
                    value: "out_refund".to_string(),
                    label: "Customer Credit Note".to_string(),
                    description: Some("Credit note sent to customers".to_string()),
                },
                MoveTypeOption {
                    value: "in_refund".to_string(),
                    label: "Vendor Credit Note".to_string(),
                    description: Some("Credit note received from suppliers".to_string()),
                },
                MoveTypeOption {
                    value: "entry".to_string(),
                    label: "Journal Entry".to_string(),
                    description: Some("Manual journal entry".to_string()),
                },
            ],
            states: vec![
                StateOption {
                    value: "draft".to_string(),
                    label: "Draft".to_string(),
                    description: Some("Invoice is in draft state".to_string()),
                },
                StateOption {
                    value: "posted".to_string(),
                    label: "Posted".to_string(),
                    description: Some("Invoice has been posted".to_string()),
                },
                StateOption {
                    value: "cancel".to_string(),
                    label: "Cancelled".to_string(),
                    description: Some("Invoice has been cancelled".to_string()),
                },
            ],
            payment_states: vec![
                PaymentStateOption {
                    value: "not_paid".to_string(),
                    label: "Not Paid".to_string(),
                    description: Some("Invoice has not been paid".to_string()),
                },
                PaymentStateOption {
                    value: "in_payment".to_string(),
                    label: "In Payment".to_string(),
                    description: Some("Payment is being processed".to_string()),
                },
                PaymentStateOption {
                    value: "paid".to_string(),
                    label: "Paid".to_string(),
                    description: Some("Invoice has been fully paid".to_string()),
                },
                PaymentStateOption {
                    value: "partial".to_string(),
                    label: "Partially Paid".to_string(),
                    description: Some("Invoice has been partially paid".to_string()),
                },
                PaymentStateOption {
                    value: "reversed".to_string(),
                    label: "Reversed".to_string(),
                    description: Some("Payment has been reversed".to_string()),
                },
                PaymentStateOption {
                    value: "invoicing_legacy".to_string(),
                    label: "Legacy".to_string(),
                    description: Some("Legacy invoicing system".to_string()),
                },
            ],
            journals: vec![],
            payment_terms: vec![],
            payment_methods: vec![],
            fiscal_positions: vec![],
        }
    }
}
