use serde::{Serialize, Deserialize};
use uuid::Uuid;

// 📡 Event gửi đi khi user được tạo
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserCreated {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub email: String,
}