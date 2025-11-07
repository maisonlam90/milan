use serde_json::json;

/// Invoice form schema/metadata for frontend
pub fn invoice_form_schema() -> serde_json::Value {
    json!({
        "fields": [
            {
                "name": "partner_id",
                "label": "Customer",
                "type": "relation",
                "required": true,
                "relation": {
                    "model": "contact",
                    "search_fields": ["name", "email", "phone"],
                    "display_field": "display_name"
                }
            },
            {
                "name": "invoice_date",
                "label": "Invoice Date",
                "type": "date",
                "required": true,
                "default": "today"
            },
            {
                "name": "invoice_date_due",
                "label": "Due Date",
                "type": "date",
                "required": false
            },
            {
                "name": "invoice_payment_term_id",
                "label": "Payment Terms",
                "type": "relation",
                "required": false,
                "relation": {
                    "model": "account_payment_term"
                }
            },
            {
                "name": "journal_id",
                "label": "Journal",
                "type": "relation",
                "required": true,
                "relation": {
                    "model": "account_journal",
                    "filter": {
                        "type": "sale"
                    }
                }
            },
            {
                "name": "currency_id",
                "label": "Currency",
                "type": "relation",
                "required": true,
                "relation": {
                    "model": "currency"
                }
            },
            {
                "name": "narration",
                "label": "Terms and Conditions",
                "type": "textarea",
                "required": false
            },
            {
                "name": "invoice_lines",
                "label": "Invoice Lines",
                "type": "one2many",
                "relation": {
                    "model": "account_move_line",
                    "fields": [
                        {
                            "name": "product_id",
                            "label": "Product",
                            "type": "relation",
                            "relation": {
                                "model": "product"
                            }
                        },
                        {
                            "name": "name",
                            "label": "Description",
                            "type": "text"
                        },
                        {
                            "name": "quantity",
                            "label": "Quantity",
                            "type": "decimal",
                            "default": 1.0
                        },
                        {
                            "name": "price_unit",
                            "label": "Unit Price",
                            "type": "decimal"
                        },
                        {
                            "name": "discount",
                            "label": "Discount (%)",
                            "type": "decimal"
                        },
                        {
                            "name": "tax_ids",
                            "label": "Taxes",
                            "type": "many2many",
                            "relation": {
                                "model": "account_tax"
                            }
                        },
                        {
                            "name": "price_subtotal",
                            "label": "Subtotal",
                            "type": "decimal",
                            "readonly": true,
                            "computed": true
                        },
                        {
                            "name": "price_total",
                            "label": "Total",
                            "type": "decimal",
                            "readonly": true,
                            "computed": true
                        }
                    ]
                }
            },
            {
                "name": "amount_untaxed",
                "label": "Untaxed Amount",
                "type": "decimal",
                "readonly": true,
                "computed": true
            },
            {
                "name": "amount_tax",
                "label": "Tax",
                "type": "decimal",
                "readonly": true,
                "computed": true
            },
            {
                "name": "amount_total",
                "label": "Total",
                "type": "decimal",
                "readonly": true,
                "computed": true
            },
            {
                "name": "amount_residual",
                "label": "Amount Due",
                "type": "decimal",
                "readonly": true,
                "computed": true
            }
        ],
        "states": [
            {
                "value": "draft",
                "label": "Draft",
                "color": "secondary"
            },
            {
                "value": "posted",
                "label": "Posted",
                "color": "success"
            },
            {
                "value": "cancel",
                "label": "Cancelled",
                "color": "danger"
            }
        ],
        "payment_states": [
            {
                "value": "not_paid",
                "label": "Not Paid"
            },
            {
                "value": "in_payment",
                "label": "In Payment"
            },
            {
                "value": "paid",
                "label": "Paid"
            },
            {
                "value": "partial",
                "label": "Partially Paid"
            }
        ]
    })
}

