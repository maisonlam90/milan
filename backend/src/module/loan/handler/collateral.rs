use std::sync::Arc;

use axum::{
    extract::{State, Json, Path},
};
use uuid::Uuid;
use sqlx::PgPool;
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use sqlx::types::BigDecimal;

use crate::core::auth::AuthUser;
use crate::core::error::AppError;
use crate::core::state::AppState;
use crate::module::loan::dto::{CreateCollateralDto,CollateralAsset};



#[derive(Serialize, sqlx::FromRow)]
pub struct CollateralAssetView {
    pub tenant_id: Uuid,
    pub asset_id: Uuid,
    pub asset_type: String,
    pub description: Option<String>,
    pub value_estimate: Option<BigDecimal>,
    pub owner_contact_id: Option<Uuid>,
    pub status: String,
    pub created_by: Uuid,
    pub created_at: DateTime<Utc>,
    pub contract_id: Option<Uuid>,
    pub contract_number: Option<String>,
}

pub async fn list_collateral(
    State(state): State<Arc<AppState>>,
    user: AuthUser,
) -> Result<Json<Vec<CollateralAssetView>>, AppError> {
    let pool: &PgPool = state.shard.get_pool_for_tenant(&user.tenant_id);

    let items = sqlx::query_as!(
        CollateralAssetView,
        r#"
        SELECT a.tenant_id,
               a.asset_id,
               a.asset_type,
               a.description,
               a.value_estimate,
               a.owner_contact_id,
               a.status,
               a.created_by,
               a.created_at,
               lc.contract_id,
               c.contract_number
        FROM collateral_assets a
        LEFT JOIN loan_collateral lc
          ON lc.tenant_id = a.tenant_id
         AND lc.asset_id  = a.asset_id
         AND lc.status    = 'active'
        LEFT JOIN loan_contract c
          ON c.tenant_id = lc.tenant_id
         AND c.id        = lc.contract_id
        WHERE a.tenant_id = $1
        ORDER BY a.created_at DESC
        "#,
        user.tenant_id
    )
    .fetch_all(pool)
    .await?;

    Ok(Json(items))
}

pub async fn create_collateral(
    State(state): State<Arc<AppState>>,
    user: AuthUser,
    Json(payload): Json<CreateCollateralDto>,
) -> Result<Json<CollateralAsset>, AppError> {
    let pool: &PgPool = state.shard.get_pool_for_tenant(&user.tenant_id);
    let asset_id = Uuid::new_v4();
    let status = payload.status.unwrap_or_else(|| "available".to_string());

    // 1. Ghi vào bảng collateral_assets
    let rec = sqlx::query_as!(
        CollateralAsset,
        r#"
        INSERT INTO collateral_assets (
            tenant_id, asset_id, asset_type, description,
            value_estimate, owner_contact_id, status, created_by
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING tenant_id, asset_id, asset_type, description,
                  value_estimate, owner_contact_id, status, created_by, created_at
        "#,
        user.tenant_id,
        asset_id,
        payload.asset_type,
        payload.description,
        payload.value_estimate,
        payload.owner_contact_id,
        status,
        user.user_id
    )
    .fetch_one(pool)
    .await?;

    // 2. Nếu FE truyền contract_id, ghi liên kết vào loan_collateral
    if let Some(contract_id) = payload.contract_id.clone() {
        sqlx::query!(
            r#"
            INSERT INTO loan_collateral (
                tenant_id, contract_id, asset_id, status, created_by, created_at
            ) VALUES ($1, $2, $3, 'active', $4, NOW())
            "#,
            user.tenant_id,
            contract_id,
            asset_id,
            user.user_id
        )
        .execute(pool)
        .await?;
    }

    Ok(Json(rec))
}

pub async fn get_collaterals_by_contract(
    State(state): State<Arc<AppState>>,
    user: AuthUser,
    Path(contract_id): Path<Uuid>,
) -> Result<Json<Vec<CollateralAsset>>, AppError> {
    let pool = state.shard.get_pool_for_tenant(&user.tenant_id);

    let items = sqlx::query_as!(
        CollateralAsset,
        r#"
        SELECT a.tenant_id, a.asset_id, a.asset_type, a.description,
               a.value_estimate, a.owner_contact_id, a.status, a.created_by, a.created_at
        FROM loan_collateral lc
        JOIN collateral_assets a
          ON lc.tenant_id = a.tenant_id AND lc.asset_id = a.asset_id
        WHERE lc.tenant_id = $1 AND lc.contract_id = $2
        AND lc.status = 'active'
        ORDER BY a.created_at DESC
        "#,
        user.tenant_id,
        contract_id,
    )
    .fetch_all(pool)
    .await?;

    Ok(Json(items))
}

#[derive(Debug, Deserialize)]
pub struct AddCollateralDto {
    asset_id: Uuid,
    pledge_value: Option<BigDecimal>,
}

pub async fn add_collateral_to_contract(
    State(state): State<Arc<AppState>>,
    user: AuthUser,
    Path(contract_id): Path<Uuid>,
    Json(payload): Json<AddCollateralDto>,
) -> Result<(), AppError> {
    let pool = state.shard.get_pool_for_tenant(&user.tenant_id);

    sqlx::query!(
        r#"
        INSERT INTO loan_collateral (
            tenant_id, contract_id, asset_id,
            pledge_value, status, created_by, created_at
        )
        VALUES ($1, $2, $3, $4, 'active', $5, NOW())
        "#,
        user.tenant_id,
        contract_id,
        payload.asset_id,
        payload.pledge_value,
        user.user_id,
    )
    .execute(pool)
    .await?;

    Ok(())
}

#[derive(Debug, Deserialize)]
pub struct ReleaseCollateralDto {
    asset_id: Uuid,
}

pub async fn release_collateral_from_contract(
    State(state): State<Arc<AppState>>,
    user: AuthUser,
    Path(contract_id): Path<Uuid>,
    Json(payload): Json<ReleaseCollateralDto>,
) -> Result<(), AppError> {
    let pool = state.shard.get_pool_for_tenant(&user.tenant_id);

    sqlx::query!(
        r#"
        UPDATE loan_collateral
        SET status = 'released',
            released_at = NOW()
        WHERE tenant_id = $1
          AND contract_id = $2
          AND asset_id = $3
        "#,
        user.tenant_id,
        contract_id,
        payload.asset_id,
    )
    .execute(pool)
    .await?;

    Ok(())
}

#[derive(Debug, Deserialize)]
pub struct UpdateCollateralDto {
    pub asset_type: Option<String>,
    pub description: Option<String>,
    pub value_estimate: Option<BigDecimal>,
    pub owner_contact_id: Option<Uuid>,
    pub status: Option<String>,
}

/// Cập nhật tài sản thế chấp theo asset_id (thuộc tenant hiện tại)
pub async fn update_collateral(
    State(state): State<Arc<AppState>>,
    user: AuthUser,
    Path(asset_id): Path<Uuid>,
    Json(payload): Json<UpdateCollateralDto>,
) -> Result<Json<CollateralAsset>, AppError> {
    let pool = state.shard.get_pool_for_tenant(&user.tenant_id);

    // Lấy bản ghi hiện tại để merge giá trị Option
    let existing = sqlx::query_as!(
        CollateralAsset,
        r#"
        SELECT tenant_id, asset_id, asset_type, description,
               value_estimate, owner_contact_id, status, created_by, created_at
        FROM collateral_assets
        WHERE tenant_id = $1 AND asset_id = $2
        "#,
        user.tenant_id,
        asset_id
    )
    .fetch_one(pool)
    .await
    .map_err(|_| AppError::bad_request("asset not found"))?;

    let new_asset_type = payload.asset_type.unwrap_or(existing.asset_type.clone());
    let new_description = payload.description.or(existing.description.clone());
    let new_value_estimate = payload.value_estimate.or(existing.value_estimate.clone());
    let new_owner_contact_id = payload.owner_contact_id.or(existing.owner_contact_id);
    let new_status = payload.status.unwrap_or(existing.status.clone());

    let updated = sqlx::query_as!(
        CollateralAsset,
        r#"
        UPDATE collateral_assets
        SET asset_type = $3,
            description = $4,
            value_estimate = $5,
            owner_contact_id = $6,
            status = $7
        WHERE tenant_id = $1 AND asset_id = $2
        RETURNING tenant_id, asset_id, asset_type, description,
                  value_estimate, owner_contact_id, status, created_by, created_at
        "#,
        user.tenant_id,
        asset_id,
        new_asset_type,
        new_description,
        new_value_estimate,
        new_owner_contact_id,
        new_status,
    )
    .fetch_one(pool)
    .await?;

    Ok(Json(updated))
}