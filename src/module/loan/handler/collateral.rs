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
use crate::module::loan::dto::{CreateCollateralDto,CollateralAsset};



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