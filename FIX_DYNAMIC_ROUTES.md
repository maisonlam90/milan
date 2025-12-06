# Fix Dynamic Routes - Không cần restart backend khi scan modules mới

## Vấn đề ban đầu:

### Cách cũ (Static routes):
```rust
// Routes được tạo 1 lần khi startup
pub fn routes(state: Arc<AppState>) -> Router<Arc<AppState>> {
    let mut router = Router::new();
    
    // Loop qua tất cả modules HIỆN TẠI và tạo routes
    for module_info in state.module_registry.list_modules_owned() {
        router = router.merge(create_module_routes(&module_info.name, ...));
    }
    
    router
}

// Mỗi module có routes riêng: /test/metadata, /product/metadata, ...
```

**Vấn đề:**
- ✅ Restart backend → `routes()` gọi lại → Routes mới được tạo → OK
- ❌ Chỉ scan → Registry update nhưng router CỐ ĐỊNH → Routes cũ → 404

### Cách mới (Dynamic routes):
```rust
// Routes SỬ DỤNG PATH PARAMETERS - không phụ thuộc vào modules hiện tại
pub fn routes(_state: Arc<AppState>) -> Router<Arc<AppState>> {
    Router::new()
        // /:module_name/metadata - Bất kỳ module nào cũng OK
        .route("/:module_name/metadata", get(handler))
        .route("/:module_name/list", get(handler))
        .route("/:module_name/create", post(handler))
        // ... tất cả routes dùng dynamic path
}
```

**Giải pháp:**
- ✅ Restart backend → Routes dynamic sẵn → OK
- ✅ Chỉ scan → Registry update → Routes dynamic vẫn match → OK

## Thay đổi chi tiết:

### Before (Static):
```rust
// File: backend/src/api/external_modules.rs

pub fn routes(state: Arc<AppState>) -> Router<Arc<AppState>> {
    let mut router = Router::new();
    
    // Tạo route cho từng module cụ thể
    for module_info in state.module_registry.list_modules_owned() {
        let module_name = module_info.name.clone();
        
        // /test/metadata, /product/metadata, etc.
        router = router.merge(create_module_routes(&module_name, ...));
    }
    
    router
}

fn create_module_routes(module_name: &str) -> Router<...> {
    Router::new()
        .route(&format!("/{}/metadata", module_name), get(handler))
        .route(&format!("/{}/list", module_name), get(handler))
        // ... hardcoded routes cho module cụ thể
}
```

### After (Dynamic):
```rust
pub fn routes(_state: Arc<AppState>) -> Router<Arc<AppState>> {
    Router::new()
        // Dynamic routes - module_name được extract từ path
        .route(
            "/:module_name/metadata",
            get(|State(state), Path(module_name): Path<String>| async move {
                get_module_metadata_handler(state, module_name).await
            }),
        )
        .route(
            "/:module_name/list",
            get(|State(state), auth, Path(module_name): Path<String>, query| async move {
                list_handler(state, auth, query, module_name).await
            }),
        )
        .route(
            "/:module_name/create",
            post(|State(state), auth, Path(module_name): Path<String>, body| async move {
                create_handler(state, auth, body, module_name).await
            }),
        )
        // ... tất cả routes đều dùng /:module_name
}
```

## Lợi ích:

1. **Không cần restart backend** khi thêm module mới
2. **Scan và dùng ngay** - Module mới tự động có routes
3. **Code đơn giản hơn** - Không cần loop và merge routes
4. **Linh hoạt** - Thêm module chỉ cần có manifest.json

## Test:

1. Ấn nút "Scan modules" → Backend scan và update registry
2. Frontend reload (auto sau 1.5s)
3. Vào `/test/test-create` → Gọi `/test/metadata` → 200 OK ✅
4. Fields hiện ra đầy đủ ✅

## Flow hoàn chỉnh:

```
1. Thêm module mới vào modules/test/
2. Tạo manifest.json với metadata
3. Ấn nút "Scan modules" trong UI
4. Backend:
   - Scan modules/ directory
   - Update registry với module mới
   - Insert vào available_module table
5. Frontend:
   - Auto reload sau 1.5s
6. Vào /test/test-create
7. Frontend gọi GET /:module_name/metadata (module_name = "test")
8. Backend:
   - Extract module_name từ path
   - Lookup trong registry
   - Trả về metadata
9. Frontend parse và render fields ✅
```

