pub mod user;
pub mod tenant;
pub mod available; // 👈 Cho phép module router gọi được handler get_available_modules

// Ghi module vao tenant available_module
use sqlx::PgPool;
use user::metadata as user_metadata; // Import metadata của module user

/// Hàm đồng bộ metadata của tất cả module vào bảng `available_module`
/// - Chạy khi khởi động hệ thống
/// - Insert hoặc update tên, mô tả, UI metadata của module
pub async fn sync_available_modules(pool: &PgPool) -> Result<(), sqlx::Error> {
    // Tập hợp tất cả metadata module
    let modules = vec![
        user_metadata::metadata(),
        // Thêm module khác: payment_metadata::metadata(),...
    ];

    // Ghi vào bảng available_module
    for m in modules {
        sqlx::query!(
            r#"
            INSERT INTO available_module (module_name, display_name, description, metadata)
            VALUES ($1, $2, $3, $4)
            ON CONFLICT (module_name)
            DO UPDATE SET display_name = EXCLUDED.display_name,
                          description = EXCLUDED.description,
                          metadata = EXCLUDED.metadata
            "#,
            m.name,
            m.display_name,
            m.description,
            m.metadata
        )
        .execute(pool)
        .await?;
    }

    Ok(())
}