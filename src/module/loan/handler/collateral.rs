use std::sync::Arc;

use axum::{
    extract::{State, Json},
};
use uuid::Uuid;
use sqlx::PgPool;
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use sqlx::types::BigDecimal;

use crate::core::auth::AuthUser;
use crate::core::error::AppError;
use crate::core::state::AppState;

#[derive(Deserialize)]
pub struct CreateCollateralDto {
    pub asset_type: String,
    pub description: Option<String>,
    pub value_estimate: Option<BigDecimal>,
    pub owner_contact_id: Option<Uuid>,
    pub status: Option<String>,              // 👈 cho phép FE không gửi
}

#[derive(Serialize, sqlx::FromRow)]
pub struct CollateralAsset {
    pub tenant_id: Uuid,
    pub asset_id: Uuid,
    pub asset_type: String,
    pub description: Option<String>,
    pub value_estimate: Option<BigDecimal>,
    pub owner_contact_id: Option<Uuid>,
    pub status: String,                      // 👈 có status
    pub created_by: Uuid,
    pub created_at: DateTime<Utc>,
}

pub async fn create_collateral(
    State(state): State<Arc<AppState>>,
    user: AuthUser,
    Json(payload): Json<CreateCollateralDto>,
) -> Result<Json<CollateralAsset>, AppError> {
    let pool: &PgPool = state.shard.get_pool_for_tenant(&user.tenant_id);
    let asset_id = Uuid::new_v4();
    let status = payload.status.unwrap_or_else(|| "available".to_string());

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

    Ok(Json(rec))
}

pub async fn list_collateral(
    State(state): State<Arc<AppState>>,
    user: AuthUser,
) -> Result<Json<Vec<CollateralAsset>>, AppError> {
    let pool: &PgPool = state.shard.get_pool_for_tenant(&user.tenant_id);

    let items = sqlx::query_as!(
        CollateralAsset,
        r#"
        SELECT tenant_id, asset_id, asset_type, description,
               value_estimate, owner_contact_id, status, created_by, created_at
        FROM collateral_assets
        WHERE tenant_id = $1
        ORDER BY created_at DESC
        "#,
        user.tenant_id
    )
    .fetch_all(pool)
    .await?;

    Ok(Json(items))
}
