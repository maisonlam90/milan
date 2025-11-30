use serde_json::json;
use crate::core::i18n::I18n;

pub const DISPLAY_NAME: &str = "Contact";
pub const DESCRIPTION: &str = "Quản lí liên hệ";

pub fn contact_form_schema(i18n: &I18n) -> serde_json::Value {
    json!({
      "form": {
        "fields": [
          { "name": "is_company", "label": i18n.t("contact.field.isCompany"), "type": "checkbox", "width": 4 },
          { "name": "parent_id", "label": i18n.t("contact.field.belongsToCompany"), "type": "select", "width": 8, "fetch": "/contact/list?is_company=true" },
          { "name": "name", "label": i18n.t("contact.field.name"), "type": "text", "width": 8, "required": true },
          { "name": "display_name", "label": i18n.t("contact.field.displayName"), "type": "text", "width": 4 },
          { "name": "national_id", "label": i18n.t("contact.field.nationalId"), "type": "text", "width": 6 },
          { "name": "email", "label": i18n.t("contact.field.email"), "type": "email", "width": 6 },
          { "name": "phone", "label": i18n.t("contact.field.phone"), "type": "text", "width": 6 },
          { "name": "mobile", "label": i18n.t("contact.field.mobile"), "type": "text", "width": 6 },
          { "name": "website", "label": i18n.t("contact.field.website"), "type": "text", "width": 6 },
          { "name": "street", "label": i18n.t("contact.field.street"), "type": "text", "width": 12 },
          { "name": "street2", "label": i18n.t("contact.field.street2"), "type": "text", "width": 12 },
          { "name": "city", "label": i18n.t("contact.field.city"), "type": "text", "width": 4 },
          { "name": "state", "label": i18n.t("contact.field.state"), "type": "text", "width": 4 },
          { "name": "zip", "label": i18n.t("contact.field.zip"), "type": "text", "width": 4 },
          { "name": "country_code", "label": i18n.t("contact.field.countryCode"), "type": "text", "width": 4 },
          { "name": "tags", "label": i18n.t("contact.field.tags"), "type": "tags", "width": 8 },
          { "name": "notes", "label": i18n.t("contact.field.notes"), "type": "textarea", "width": 12 }
        ]
      },
      "list": {
        "columns": [
          { "name": "name", "label": i18n.t("contact.field.name") },
          { "name": "display_name", "label": i18n.t("contact.field.displayName") },
          { "name": "email", "label": i18n.t("contact.field.email") },
          { "name": "phone", "label": i18n.t("contact.field.phone") },
          { "name": "is_company", "label": i18n.t("contact.field.company") },
          { "name": "state", "label": i18n.t("contact.field.address") },
        ],
        "search": { "placeholder": i18n.t("contact.list.searchPlaceholder") }
      }
    })
}
