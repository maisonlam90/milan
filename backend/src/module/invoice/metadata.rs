use serde_json::json;
use crate::core::i18n::I18n;

pub const DISPLAY_NAME: &str = "Invoice";
pub const DESCRIPTION: &str = "Quản lí hóa đơn";

pub fn invoice_form_schema(i18n: &I18n) -> serde_json::Value {
    json!({
        "form": {
            "fields": [
                { "name": "partner_id", "label": i18n.t("invoice.field.partner"), "type": "select", "width": 12 },
                { "name": "invoice_date", "label": i18n.t("invoice.field.invoiceDate"), "type": "date", "width": 6, "required": true },
                { "name": "invoice_date_due", "label": i18n.t("invoice.field.dueDate"), "type": "date", "width": 6 },
                { "name": "invoice_payment_term_id", "label": i18n.t("invoice.field.paymentTerms"), "type": "text", "width": 6 },
                { "name": "narration", "label": i18n.t("invoice.field.termsAndConditions"), "type": "textarea", "width": 12 },
            ]
        },
        "list": {
            "columns": [
                { "key": "invoice_number", "label": i18n.t("invoice.field.invoiceNumber") },
                { "key": "partner_id", "label": i18n.t("invoice.field.partner") },
                { "key": "invoice_date", "label": i18n.t("invoice.field.invoiceDate") },
                { "key": "invoice_date_due", "label": i18n.t("invoice.field.dueDate") },
                { "key": "amount_total", "label": i18n.t("invoice.field.total") },
                { "key": "amount_residual", "label": i18n.t("invoice.field.amountDue") },
                { "key": "state", "label": i18n.t("invoice.field.state") }
            ]
        },
        "invoiceLines": {
            "fields": [
                { "name": "name", "label": i18n.t("invoice.line.name"), "type": "text" },
                { "name": "quantity", "label": i18n.t("invoice.line.quantity"), "type": "number" },
                { "name": "price_unit", "label": i18n.t("invoice.line.unitPrice"), "type": "number" },
                { "name": "tax_rate", "label": i18n.t("invoice.line.tax"), "type": "number" },
                { "name": "amount", "label": i18n.t("invoice.line.amount"), "type": "compute" },
            ]
        },
        "notebook": {
            "fields": [
                { "name": "name", "label": i18n.t("invoice.line.name"), "type": "text" },
                { "name": "quantity", "label": i18n.t("invoice.line.quantity"), "type": "number" },
                { "name": "price_unit", "label": i18n.t("invoice.line.unitPrice"), "type": "number" },
                { "name": "tax_rate", "label": i18n.t("invoice.line.tax"), "type": "number" },
                { "name": "amount", "label": i18n.t("invoice.line.amount"), "type": "compute" },
            ]
        },
        "states": [
            {
                "value": "draft",
                "label": i18n.t("invoice.state.draft"),
                "color": "secondary"
            },
            {
                "value": "posted",
                "label": i18n.t("invoice.state.posted"),
                "color": "success"
            },
            {
                "value": "cancel",
                "label": i18n.t("invoice.state.cancelled"),
                "color": "danger"
            }
        ],
        "payment_states": [
            {
                "value": "not_paid",
                "label": i18n.t("invoice.paymentState.notPaid")
            },
            {
                "value": "in_payment",
                "label": i18n.t("invoice.paymentState.inPayment")
            },
            {
                "value": "paid",
                "label": i18n.t("invoice.paymentState.paid")
            },
            {
                "value": "partial",
                "label": i18n.t("invoice.paymentState.partial")
            }
        ]
    })
}
