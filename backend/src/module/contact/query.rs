use sqlx::{Pool, Postgres};
use serde::Serialize;
use uuid::Uuid;
use chrono::{DateTime, Utc};

#[derive(Debug, Serialize)]
pub struct ContactListItem {
    pub id: Uuid,
    pub name: String,                 // luôn có giá trị hiển thị
    pub display_name: Option<String>,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub is_company: bool,
    pub tags: Option<String>,         // từ tags_cached
    pub state: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
    pub national_id: Option<String>,  // 👈 THÊM
}

#[derive(Debug)]
pub struct ListFilter {
    pub q: Option<String>,
    pub is_company: Option<bool>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

pub async fn list_contacts(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    f: ListFilter,
) -> Result<Vec<ContactListItem>, sqlx::Error> {
    let limit = f.limit.unwrap_or(200).clamp(1, 500);
    let offset = f.offset.unwrap_or(0).max(0);

    let q = f.q.unwrap_or_default();
    let has_q = !q.trim().is_empty();

    if has_q {
        let like = format!("%{}%", q.trim().to_lowercase());
        let rows = sqlx::query_as!(
            ContactListItem,
            r#"
            SELECT
                id,
                COALESCE(NULLIF(name,''), display_name, email, phone, '(không tên)') AS "name!: String",
                display_name,
                email,
                phone,
                is_company,
                NULLIF(tags_cached,'') AS "tags?: String",
                state,
                created_at,
                updated_at,
                national_id AS "national_id?: String"     -- 👈 THÊM
            FROM contact
            WHERE tenant_id = $1
              AND ($2::bool IS NULL OR is_company = $2)
              AND (
                    lower(coalesce(name, ''))         LIKE $3
                 OR lower(coalesce(display_name, '')) LIKE $3
                 OR lower(coalesce(email, ''))        LIKE $3
                 OR lower(coalesce(phone, ''))        LIKE $3
              )
            ORDER BY created_at DESC
            LIMIT $4 OFFSET $5
            "#,
            tenant_id,
            f.is_company,
            like,
            limit,
            offset
        )
        .fetch_all(pool)
        .await?;
        Ok(rows)
    } else {
        let rows = sqlx::query_as!(
            ContactListItem,
            r#"
            SELECT
                id,
                COALESCE(NULLIF(name,''), display_name, email, phone, '(không tên)') AS "name!: String",
                display_name,
                email,
                phone,
                is_company,
                NULLIF(tags_cached,'') AS "tags?: String",
                state,
                created_at,
                updated_at,
                national_id AS "national_id?: String"     -- 👈 THÊM
            FROM contact
            WHERE tenant_id = $1
              AND ($2::bool IS NULL OR is_company = $2)
            ORDER BY created_at DESC
            LIMIT $3 OFFSET $4
            "#,
            tenant_id,
            f.is_company,
            limit,
            offset
        )
        .fetch_all(pool)
        .await?;
        Ok(rows)
    }
}

#[derive(Debug, Serialize)]
pub struct ContactDetail {
    pub id: Uuid,
    pub is_company: bool,
    pub parent_id: Option<Uuid>,
    pub name: Option<String>,
    pub display_name: Option<String>,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub website: Option<String>,
    pub street: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub zip: Option<String>,
    pub country_code: Option<String>,
    pub tax_code: Option<String>,
    pub national_id: Option<String>,
    pub notes: Option<String>,
    pub tags_cached: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

pub async fn get_contact_by_id(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    id: Uuid,
) -> Result<ContactDetail, sqlx::Error> {
    let row = sqlx::query_as!(
        ContactDetail,
        r#"
        SELECT
            id,
            is_company,
            parent_id,
            name,
            display_name,
            email,
            phone,
            website,
            street,
            city,
            state,
            zip,
            country_code,
            tax_code AS "tax_code?: String",
            national_id AS "national_id?: String",
            notes,
            NULLIF(tags_cached,'') AS "tags_cached?: String",
            created_at,
            updated_at
        FROM contact
        WHERE tenant_id = $1 AND id = $2
        "#,
        tenant_id,
        id
    )
    .fetch_one(pool)
    .await?;

    Ok(row)
}
