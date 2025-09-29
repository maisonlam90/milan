use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Input tạo mới liên hệ (FE đang gửi `name` là bắt buộc)
#[derive(Debug, Deserialize, Serialize)]
pub struct CreateContactInput {
    pub is_company: bool,
    pub parent_id: Option<Uuid>,

    pub name: String, // required (rỗng vẫn hợp lệ, command sẽ fallback)

    pub display_name: Option<String>,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub mobile: Option<String>,
    pub website: Option<String>,

    pub street: Option<String>,
    pub street2: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub zip: Option<String>,
    pub country_code: Option<String>,
    pub national_id: Option<String>,

    pub notes: Option<String>,
    pub tags: Option<Vec<String>>, // mảng nhãn
    // 👇 Thêm vào đây
    pub assignee_id: Option<Uuid>,
    pub shared_with: Option<Vec<Uuid>>,
}

/// Input cập nhật liên hệ (tất cả field đều optional)
#[derive(Debug, Default, Deserialize, Serialize)]
pub struct UpdateContactInput {
    pub is_company: Option<bool>,
    pub parent_id: Option<Uuid>,

    pub name: Option<String>,
    pub display_name: Option<String>,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub mobile: Option<String>,
    pub website: Option<String>,

    pub street: Option<String>,
    pub street2: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub zip: Option<String>,
    pub country_code: Option<String>,
    pub national_id: Option<String>,
    pub notes: Option<String>,
    pub tags: Option<Vec<String>>,
}

/// Query string cho API list
#[derive(Debug, Deserialize)]
pub struct ListFilter {
    pub q: Option<String>,
    pub is_company: Option<bool>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}
