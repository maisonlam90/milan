use serde_json::json;
use crate::core::i18n::I18n;

pub const DISPLAY_NAME: &str = "Loan";
pub const DESCRIPTION: &str = "Quản lí cho vay";

pub fn loan_form_schema(i18n: &I18n) -> serde_json::Value {
    json!({
        "form": {
            "fields": [
                { "name": "contact_id", "label": i18n.t("loan.field.customer"), "type": "select", "width": 12 },
                { "name": "contract_number", "label": i18n.t("loan.field.contractNumber"), "type": "text", "width": 6, "disabled": true },
                { "name": "interest_rate", "label": i18n.t("loan.field.interestRate"), "type": "number", "width": 6},
                { "name": "date_start", "label": i18n.t("loan.field.dateStart"), "type": "date", "width": 6  },
                { "name": "date_end", "label": i18n.t("loan.field.dateEnd"), "type": "date", "width": 6  },
                { "name": "term_months", "label": i18n.t("loan.field.termMonths"), "type": "number", "width": 6 },
                { "name": "state", "label": i18n.t("loan.field.state"), "type": "text", "width": 6 , "disabled": true},
            ]
        },
        "list": {
            "columns": [
                { "key": "contract_number", "label": i18n.t("loan.field.contractNumber") },
                { "key": "id", "label": i18n.t("loan.field.contractId") },
                { "key": "current_principal", "label": i18n.t("loan.field.principal") },
                { "key": "interest_rate", "label": i18n.t("loan.field.interestRate") },
                { "key": "term_months", "label": i18n.t("loan.field.termMonths") },
                { "key": "date_start", "label": i18n.t("loan.field.dateStart") },
                { "key": "date_end", "label": i18n.t("loan.field.dateEnd") },
                { "key": "state", "label": i18n.t("loan.field.state") }
            ]
        },
        "collateral": {
            "fields": [
                {
                    "name": "asset_type", "label": i18n.t("loan.field.assetType"), "type": "select",
                    "options": json!([
                        { "value": "vehicle", "label": i18n.t("loan.collateral.assetType.vehicle") },
                        { "value": "real_estate", "label": i18n.t("loan.collateral.assetType.realEstate") },
                        { "value": "jewelry", "label": i18n.t("loan.collateral.assetType.jewelry") },
                        { "value": "electronics", "label": i18n.t("loan.collateral.assetType.electronics") },
                        { "value": "other", "label": i18n.t("loan.collateral.assetType.other") }
                    ])
                },
                { "name": "owner_contact_id", "label": i18n.t("loan.collateral.ownerContact"), "type": "select" },
                { "name": "value_estimate", "label": i18n.t("loan.field.estimatedValue"), "type": "number" },
                {
                    "name": "status", "label": i18n.t("loan.field.status"), "type": "select",
                    "options": json!([
                        { "value": "available", "label": i18n.t("loan.collateral.status.available") },
                        { "value": "pledged",   "label": i18n.t("loan.collateral.status.pledged") },
                        { "value": "released",  "label": i18n.t("loan.collateral.status.released") },
                        { "value": "sold",      "label": i18n.t("loan.collateral.status.sold") }
                    ])
                },
                { "name": "description", "label": i18n.t("loan.field.description"), "type": "text" }
            ]
        },
        "notebook": {
            "fields": [
                { "name": "date", "label": i18n.t("loan.notebook.date"), "type": "date" },
                { "name": "transaction_type", "label": i18n.t("loan.notebook.transactionType"), "type": "select", "options": json!([
                    { "value": "disbursement", "label": i18n.t("loan.notebook.transactionType.disbursement") },
                    { "value": "additional", "label": i18n.t("loan.notebook.transactionType.additional") },
                    { "value": "interest", "label": i18n.t("loan.notebook.transactionType.interest") },
                    { "value": "principal", "label": i18n.t("loan.notebook.transactionType.principal") },
                    { "value": "liquidation", "label": i18n.t("loan.notebook.transactionType.liquidation") },
                    { "value": "settlement", "label": i18n.t("loan.notebook.transactionType.settlement") }
                ])},
                { "name": "amount", "label": i18n.t("loan.notebook.amount"), "type": "number" },
                { "name": "days_from_prev", "label": i18n.t("loan.notebook.daysFromPrev"), "type": "compute" },
                { "name": "interest_for_period", "label": i18n.t("loan.notebook.interestForPeriod"), "type": "compute" },
                { "name": "accumulated_interest", "label": i18n.t("loan.field.accumulatedInterest"), "type": "compute" },
                { "name": "principal_balance", "label": i18n.t("loan.notebook.principalBalance"), "type": "compute" },
                { "name": "note", "label": i18n.t("loan.notebook.note"), "type": "text" },
            ]
        }
    })
}
