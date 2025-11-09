# Cấu hình i18n Backend - Tiếng Việt mặc định

## ✅ Đã cấu hình

### 1. Ngôn ngữ mặc định
- **DEFAULT_LANGUAGE**: `"vi"` (Tiếng Việt)
- **FALLBACK_LANGUAGE**: `"en"` (Tiếng Anh)
- File: `backend/src/core/i18n.rs`

### 2. Language Detection
Backend tự động detect ngôn ngữ theo thứ tự:
1. **Header `X-Language`**: `X-Language: vi`
2. **Header `Accept-Language`**: `Accept-Language: vi,en;q=0.9`
3. **Default**: `"vi"` (nếu không có header)

### 3. Error Messages
- Tất cả error messages sẽ được dịch theo ngôn ngữ được detect
- Nếu không tìm thấy translation, sẽ fallback về tiếng Anh
- File translations: `backend/locales/{lang}/translations.json`

## 🔧 Cách hoạt động

### Khi Frontend gọi API:

1. **Frontend gửi header** (tự động qua axios interceptor):
   ```
   Accept-Language: vi
   X-Language: vi
   ```

2. **Backend detect language**:
   ```rust
   let i18n = I18n::from_headers(&headers);
   // i18n.language() = "vi"
   ```

3. **Backend trả về error message**:
   ```rust
   return Err(AppError::bad_request_i18n(&i18n, "error.loan.transactions_empty"));
   // Message: "Phải có ít nhất 1 giao dịch"
   ```

### Khi không có header:

1. **Backend dùng default**:
   ```rust
   let i18n = I18n::default(); // Uses DEFAULT_LANGUAGE = "vi"
   ```

2. **Error message bằng tiếng Việt**:
   ```
   "Phải có ít nhất 1 giao dịch"
   ```

## 📝 Sử dụng trong Code

### Trong Handler:
```rust
use axum::http::HeaderMap;
use crate::core::i18n::I18n;
use crate::core::error::AppError;

pub async fn my_handler(headers: HeaderMap) -> Result<Json<Response>, AppError> {
    let i18n = I18n::from_headers(&headers);
    
    // Sử dụng i18n
    return Err(AppError::bad_request_i18n(&i18n, "error.loan.transactions_empty"));
}
```

### Trong Command Layer:
```rust
use crate::core::i18n::I18n;

pub async fn my_command() -> Result<(), AppError> {
    let i18n = I18n::default(); // Uses DEFAULT_LANGUAGE = "vi"
    
    // Sử dụng i18n
    return Err(AppError::bad_request_i18n(&i18n, "error.loan.transactions_empty"));
}
```

## 🌐 API Endpoints

### Lấy translations:
```bash
GET /i18n/translations?lang=vi
```

### Lấy danh sách ngôn ngữ:
```bash
GET /i18n/languages
```

## 🔍 Test

### Test với tiếng Việt:
```bash
curl -X POST http://localhost:3000/api/loan/contracts \
  -H "Content-Type: application/json" \
  -H "Accept-Language: vi" \
  -d '{"transactions": []}'

# Response:
# {
#   "code": "bad_request",
#   "message": "Phải có ít nhất 1 giao dịch"
# }
```

### Test với tiếng Anh:
```bash
curl -X POST http://localhost:3000/api/loan/contracts \
  -H "Content-Type: application/json" \
  -H "Accept-Language: en" \
  -d '{"transactions": []}'

# Response:
# {
#   "code": "bad_request",
#   "message": "At least 1 transaction is required"
# }
```

### Test không có header (dùng default = vi):
```bash
curl -X POST http://localhost:3000/api/loan/contracts \
  -H "Content-Type: application/json" \
  -d '{"transactions": []}'

# Response:
# {
#   "code": "bad_request",
#   "message": "Phải có ít nhất 1 giao dịch"
# }
```

## 📌 Lưu ý

1. **Frontend phải gửi header**: Frontend cần gửi header `Accept-Language` hoặc `X-Language` để backend detect đúng ngôn ngữ
2. **Fallback chain**: Backend sẽ fallback: Current Language → Fallback Language (en) → Key itself
3. **Default language**: Nếu không có header, backend sẽ dùng `DEFAULT_LANGUAGE = "vi"`

## 🔄 Tích hợp với Frontend

Frontend đã được cấu hình để tự động gửi header `Accept-Language` trong mọi request qua axios interceptor:

```typescript
// frontend/demo/src/utils/axios.ts
axiosInstance.interceptors.request.use((config) => {
  const currentLanguage = i18n.language || "vi";
  config.headers["Accept-Language"] = currentLanguage;
  config.headers["X-Language"] = currentLanguage;
  return config;
});
```

Điều này đảm bảo backend luôn nhận được ngôn ngữ hiện tại của frontend và trả về error messages đúng ngôn ngữ.

