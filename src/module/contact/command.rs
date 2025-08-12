use uuid::Uuid;
use sqlx::{Pool, Postgres};

#[derive(Debug)]
pub struct CreateContactDto {
    pub is_company: bool,
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
    pub notes: Option<String>,
    pub tags: Option<Vec<String>>,
}

#[derive(Debug)]
pub struct UpdateContactDto {
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
    pub notes: Option<String>,
    pub tags: Option<Vec<String>>,
}

/* ========== helpers ========== */

fn norm_str(v: &Option<String>) -> Option<String> {
    v.as_ref()
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .map(|s| s.to_string())
}

fn build_fallback_name(
    name: &Option<String>,
    display_name: &Option<String>,
    email: &Option<String>,
    phone: &Option<String>,
) -> String {
    norm_str(name)
        .or_else(|| norm_str(display_name))
        .or_else(|| norm_str(email))
        .or_else(|| norm_str(phone))
        .unwrap_or_else(|| "(không tên)".to_string())
}

fn build_tags_cached(tags: &Option<Vec<String>>) -> Option<String> {
    let t = tags.as_ref()?;
    if t.is_empty() {
        return None;
    }
    let joined = t
        .iter()
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .collect::<Vec<_>>()
        .join(",");
    if joined.is_empty() { None } else { Some(joined) }
}

/* ========== commands ========== */

pub async fn create_contact(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    dto: CreateContactDto,
) -> Result<Uuid, sqlx::Error> {
    let mut tx = pool.begin().await?;

    let name = build_fallback_name(&dto.name, &dto.display_name, &dto.email, &dto.phone);
    let display_name = norm_str(&dto.display_name).unwrap_or_else(|| name.clone());
    let tags_cached = build_tags_cached(&dto.tags);

    let id = Uuid::new_v4();

    sqlx::query!(
        r#"
        INSERT INTO contact (
            tenant_id, id, is_company, parent_id,
            name, display_name, email, phone, mobile, website,
            street, street2, city, state, zip, country_code, notes, tags_cached
        ) VALUES (
            $1, $2, $3, $4,
            $5, $6, $7, $8, $9, $10,
            $11, $12, $13, $14, $15, $16, $17, $18
        )
        "#,
        tenant_id, id, dto.is_company, dto.parent_id,
        name, display_name,
        norm_str(&dto.email),
        norm_str(&dto.phone),
        norm_str(&dto.mobile),
        norm_str(&dto.website),
        norm_str(&dto.street),
        norm_str(&dto.street2),
        norm_str(&dto.city),
        norm_str(&dto.state),
        norm_str(&dto.zip),
        norm_str(&dto.country_code),
        norm_str(&dto.notes),
        tags_cached
    )
    .execute(&mut *tx)
    .await?;

    // TODO (tuỳ schema): upsert bảng tag + link nếu có

    tx.commit().await?;
    Ok(id)
}

pub async fn update_contact(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    id: Uuid,
    dto: UpdateContactDto,
) -> Result<(), sqlx::Error> {
    let mut tx = pool.begin().await?;

    // Lấy dữ liệu hiện tại để fallback hợp lệ
    let current = sqlx::query!(
        r#"
        SELECT name, display_name, email, phone
        FROM contact
        WHERE tenant_id = $1 AND id = $2
        "#,
        tenant_id,
        id
    )
    .fetch_one(&mut *tx)
    .await?;

    // current.name (non-null trong schema) -> wrap Some(...)
    let input_name = dto.name.or_else(|| Some(current.name.clone()));
    let input_display = dto.display_name.or_else(|| current.display_name.clone());
    let input_email = dto.email.clone().or_else(|| current.email.clone());
    let input_phone = dto.phone.clone().or_else(|| current.phone.clone());

    let name = build_fallback_name(&input_name, &input_display, &input_email, &input_phone);
    let display_name = norm_str(&input_display).unwrap_or_else(|| name.clone());
    let tags_cached = build_tags_cached(&dto.tags);

    sqlx::query!(
        r#"
        UPDATE contact SET
            is_company   = COALESCE($3, is_company),
            parent_id    = COALESCE($4, parent_id),
            name         = $5,
            display_name = $6,
            email        = COALESCE($7, email),
            phone        = COALESCE($8, phone),
            mobile       = COALESCE($9, mobile),
            website      = COALESCE($10, website),
            street       = COALESCE($11, street),
            street2      = COALESCE($12, street2),
            city         = COALESCE($13, city),
            state        = COALESCE($14, state),
            zip          = COALESCE($15, zip),
            country_code = COALESCE($16, country_code),
            notes        = COALESCE($17, notes),
            tags_cached  = COALESCE($18, tags_cached),
            updated_at   = NOW()
        WHERE tenant_id = $1 AND id = $2
        "#,
        tenant_id, id,
        dto.is_company,
        dto.parent_id,
        name,
        display_name,
        norm_str(&dto.email),
        norm_str(&dto.phone),
        norm_str(&dto.mobile),
        norm_str(&dto.website),
        norm_str(&dto.street),
        norm_str(&dto.street2),
        norm_str(&dto.city),
        norm_str(&dto.state),
        norm_str(&dto.zip),
        norm_str(&dto.country_code),
        norm_str(&dto.notes),
        tags_cached
    )
    .execute(&mut *tx)
    .await?;

    // TODO (tuỳ schema): cập nhật bảng tag + link

    tx.commit().await?;
    Ok(())
}

pub async fn delete_contact(
    pool: &Pool<Postgres>,
    tenant_id: Uuid,
    id: Uuid,
) -> Result<(), sqlx::Error> {
    // Nếu có bảng link tag thì xoá trước (tuỳ schema)
    // sqlx::query!("DELETE FROM contact_tag_link WHERE tenant_id=$1 AND contact_id=$2", tenant_id, id)
    //    .execute(pool).await?;

    sqlx::query!(
        "DELETE FROM contact WHERE tenant_id = $1 AND id = $2",
        tenant_id, id
    )
    .execute(pool)
    .await?;
    Ok(())
}
