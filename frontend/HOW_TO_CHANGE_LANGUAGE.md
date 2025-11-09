# Hướng dẫn đổi ngôn ngữ Frontend

## Cách đổi ngôn ngữ

### Cách 1: Sử dụng Language Selector (Khuyên dùng)

1. Click vào **icon cờ** ở góc trên bên phải của header
2. Chọn ngôn ngữ bạn muốn:
   - 🇻🇳 Tiếng Việt
   - 🇬🇧 English
   - 🇨🇳 中文 (Tiếng Trung)
   - 🇪🇸 Español (Tiếng Tây Ban Nha)
   - 🇸🇦 العربية (Tiếng Ả Rập)

### Cách 2: Sử dụng URL Parameter

Thêm `?lang=vi` vào URL:

```
http://localhost:5173/dashboards/loan/loan-create?lang=vi
http://localhost:5173/dashboards/loan/loan-create?lang=en
http://localhost:5173/dashboards/loan/loan-create?lang=zh-cn
```

**Ví dụ:**
- Tiếng Việt: `http://localhost:5173/dashboards/loan/loan-create?lang=vi`
- Tiếng Anh: `http://localhost:5173/dashboards/loan/loan-create?lang=en`

### Cách 3: Sử dụng Browser Console

Mở Developer Tools (F12) và chạy:

```javascript
// Đổi sang tiếng Việt
localStorage.setItem('i18nextLng', 'vi');
location.reload();

// Đổi sang tiếng Anh
localStorage.setItem('i18nextLng', 'en');
location.reload();
```

## Kiểm tra ngôn ngữ hiện tại

### Cách 1: Xem icon cờ
- Icon cờ ở header sẽ hiển thị ngôn ngữ hiện tại

### Cách 2: Xem URL
- Nếu có `?lang=vi` trong URL → đang dùng tiếng Việt
- Nếu có `?lang=en` trong URL → đang dùng tiếng Anh

### Cách 3: Xem Console (Development mode)
- Mở Developer Tools (F12)
- Vào tab Console
- Bạn sẽ thấy log: `[i18n] Sending Accept-Language: vi` hoặc `[i18n] Sending Accept-Language: en`

### Cách 4: Xem localStorage
- Mở Developer Tools (F12)
- Vào tab Application → Local Storage
- Tìm key `i18nextLng`
- Giá trị sẽ là: `vi`, `en`, `zh-cn`, `es`, hoặc `ar`

## Ngôn ngữ được hỗ trợ

| Code | Ngôn ngữ | Flag |
|------|----------|------|
| `vi` | Tiếng Việt | 🇻🇳 |
| `en` | English | 🇬🇧 |
| `zh-cn` | 中文 | 🇨🇳 |
| `es` | Español | 🇪🇸 |
| `ar` | العربية | 🇸🇦 |

## Lưu ý

1. **Ngôn ngữ được lưu tự động**: Khi bạn đổi ngôn ngữ, nó sẽ được lưu vào:
   - `localStorage` (lưu vĩnh viễn)
   - URL parameter `?lang=vi` (tùy chọn)

2. **Backend tự động nhận ngôn ngữ**: Frontend sẽ tự động gửi header `Accept-Language` trong mọi API request, backend sẽ trả về error messages theo ngôn ngữ tương ứng.

3. **Ngôn ngữ mặc định**: Nếu không có ngôn ngữ được chọn, hệ thống sẽ dùng **Tiếng Việt** (`vi`) làm mặc định.

## Troubleshooting

### Vấn đề: Vẫn hiển thị tiếng Anh

**Giải pháp:**
1. Xóa localStorage:
   ```javascript
   localStorage.removeItem('i18nextLng');
   location.reload();
   ```

2. Thêm `?lang=vi` vào URL:
   ```
   http://localhost:5173/dashboards/loan/loan-create?lang=vi
   ```

3. Kiểm tra Console để xem header được gửi:
   - Mở Developer Tools (F12)
   - Vào tab Network
   - Xem request headers → `Accept-Language` phải là `vi`

### Vấn đề: Backend vẫn trả về tiếng Anh

**Kiểm tra:**
1. Frontend có gửi header `Accept-Language: vi` không?
   - Mở Developer Tools → Network tab
   - Xem request headers

2. Backend logs có hiển thị language được detect không?
   - Xem backend console logs
   - Tìm dòng: `🌐 Using language from header: vi`

3. Backend có file translations tiếng Việt không?
   - Kiểm tra: `backend/locales/vi/translations.json`

## Test

### Test nhanh:

1. Mở trang: `http://localhost:5173/dashboards/loan/loan-create?lang=vi`
2. Tạo loan contract với `transactions: []` (empty)
3. Submit form
4. Kiểm tra error message:
   - ✅ Tiếng Việt: "Phải có ít nhất 1 giao dịch"
   - ❌ Tiếng Anh: "At least 1 transaction is required"

### Test với Language Selector:

1. Click vào icon cờ ở header
2. Chọn "Tiếng Việt"
3. URL sẽ tự động thêm `?lang=vi`
4. Tất cả API requests sẽ gửi `Accept-Language: vi`
5. Backend sẽ trả về error messages bằng tiếng Việt

