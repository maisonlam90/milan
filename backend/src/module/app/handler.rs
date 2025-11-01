use axum::{
    extract::{Path, State},
    Json,
};
use std::{fs, path::Path as FsPath, sync::Arc};
use convert_case::{Case, Casing};
use serde::Serialize;

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

// ---------- 📦 Scan và seed available_module từ metadata.rs ----------

#[derive(Serialize)]
pub struct ScannedModule {
    pub module_name: String,
    pub display_name: String,
    pub description: String,
}

pub async fn scan_and_seed_modules(
    State(state): State<Arc<AppState>>,
) -> Result<Json<Vec<ScannedModule>>, AppError> {

    let module_root = FsPath::new("src/module");
    let mut result = Vec::new();
    let pool = state.shard.get_pool_for_system();

    let entries = fs::read_dir(module_root)
        .map_err(|e| AppError::InternalServerError(e.to_string()))?;

    for entry in entries {
        let entry = entry.map_err(|e| AppError::InternalServerError(e.to_string()))?;
        let path = entry.path();

        if path.is_dir() {
            let module_name = path.file_name().unwrap().to_string_lossy().to_string();
            let metadata_path = path.join("metadata.rs");

            if metadata_path.exists() {
                let content = fs::read_to_string(&metadata_path)
                    .map_err(|e| AppError::InternalServerError(e.to_string()))?;

                let display_name = content
                    .lines()
                    .find(|l| l.contains("DISPLAY_NAME"))
                    .and_then(|l| l.split('"').nth(1))
                    .unwrap_or(&module_name)
                    .replace('_', " ")
                    .to_case(Case::Title);

                let description = content
                    .lines()
                    .find(|l| l.contains("DESCRIPTION"))
                    .and_then(|l| l.split('"').nth(1))
                    .unwrap_or(&format!("Module {}", display_name))
                    .to_string();

                // 🔒 Transaction: insert available_module + permissions atomically
                let mut tx = pool
                    .begin()
                    .await
                    .map_err(|e| AppError::InternalServerError(e.to_string()))?;

                // 1) available_module
                sqlx::query!(
                    r#"
                    INSERT INTO available_module (module_name, display_name, description)
                    VALUES ($1, $2, $3)
                    ON CONFLICT DO NOTHING
                    "#,
                    module_name,
                    display_name,
                    description
                )
                .execute(&mut *tx)
                .await?;

                // 2) permissions (resource, action, label)
                const ACTIONS: [&str; 5] = ["access", "read", "create", "update", "delete"];
                for action in ACTIONS {
                    let label = match action {
                        "access" => format!("Truy cập module {}", display_name),
                        "read"   => format!("Xem {}", display_name),
                        "create" => format!("Tạo {}", display_name),
                        "update" => format!("Cập nhật {}", display_name),
                        "delete" => format!("Xoá {}", display_name),
                        _ => format!("{} {}", action, display_name),
                    };

                    sqlx::query!(
                        r#"
                        INSERT INTO permissions (resource, action, label)
                        VALUES ($1, $2, $3)
                        ON CONFLICT DO NOTHING
                        "#,
                        module_name,   // resource
                        action,        // action
                        label          // label
                    )
                    .execute(&mut *tx)
                    .await?;
                }

                tx.commit().await?;

                result.push(ScannedModule {
                    module_name,
                    display_name,
                    description,
                });
            }
        }
    }

    Ok(Json(result))
}