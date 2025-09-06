use axum::{
    extract::{Path, State},
    Json,
};
use std::sync::Arc;

use crate::core::{auth::AuthUser, state::AppState, error::AppError};
use crate::module::app::dto::ModuleStatusDto;

pub async fn get_modules_status(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
) -> Result<Json<Vec<ModuleStatusDto>>, AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    let rows = sqlx::query!(
        r#"
        SELECT am.module_name, am.display_name, am.description,
               (tm.module_name IS NOT NULL) AS "enabled!",
               (em.module_name IS NOT NULL) AS "can_enable!"
        FROM available_module am
        LEFT JOIN tenant t ON t.tenant_id = $1
        LEFT JOIN enterprise_module em
          ON am.module_name = em.module_name AND em.enterprise_id = t.enterprise_id
        LEFT JOIN tenant_module tm
          ON am.module_name = tm.module_name AND tm.tenant_id = $1
        "#,
        auth.tenant_id
    )
    .fetch_all(pool)
    .await?;

    let result = rows
        .into_iter()
        .map(|r| ModuleStatusDto {
            module_name: r.module_name,
            display_name: r.display_name,
            description: r.description,
            enabled: r.enabled,
            can_enable: r.can_enable,
        })
        .collect();

    Ok(Json(result))
}

pub async fn install_module(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(module_name): Path<String>,
) -> Result<(), AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    sqlx::query!(
        r#"
        INSERT INTO tenant_module (tenant_id, enterprise_id, module_name)
        SELECT $1, t.enterprise_id, $2
        FROM tenant t
        WHERE t.tenant_id = $1
        ON CONFLICT DO NOTHING
        "#,
        auth.tenant_id,
        module_name
    )
    .execute(pool)
    .await?;

    Ok(())
}

pub async fn uninstall_module(
    State(state): State<Arc<AppState>>,
    auth: AuthUser,
    Path(module_name): Path<String>,
) -> Result<(), AppError> {
    let pool = state.shard.get_pool_for_tenant(&auth.tenant_id);

    sqlx::query!(
        "DELETE FROM tenant_module
         WHERE tenant_id = $1 AND module_name = $2",
        auth.tenant_id,
        module_name
    )
    .execute(pool)
    .await?;

    Ok(())
}
