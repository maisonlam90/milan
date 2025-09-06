use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize)]
pub struct ModuleStatusDto {
    pub module_name: String,
    pub display_name: String,
    pub description: Option<String>,
    pub enabled: bool,
    pub can_enable: bool,
}
