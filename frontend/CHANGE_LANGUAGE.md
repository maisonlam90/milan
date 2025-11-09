# Hướng dẫn chuyển đổi ngôn ngữ Frontend

## Đã cấu hình

✅ Đã thêm tiếng Việt (vi) vào hệ thống i18n
✅ Đã đặt tiếng Việt làm ngôn ngữ mặc định
✅ Đã tạo file translations tiếng Việt

## Cách chuyển sang tiếng Việt

### Cách 1: Xóa localStorage (Khuyên dùng)

1. Mở **Developer Tools** (F12)
2. Vào tab **Console**
3. Chạy lệnh:
```javascript
localStorage.removeItem('i18nextLng');
location.reload();
```

### Cách 2: Set trực tiếp trong Console

1. Mở **Developer Tools** (F12)
2. Vào tab **Console**
3. Chạy lệnh:
```javascript
localStorage.setItem('i18nextLng', 'vi');
location.reload();
```

### Cách 3: Xóa qua Application tab

1. Mở **Developer Tools** (F12)
2. Vào tab **Application** (Chrome) hoặc **Storage** (Firefox)
3. Tìm **Local Storage** → chọn domain của bạn
4. Xóa key `i18nextLng` hoặc set giá trị thành `vi`
5. Refresh trang (F5)

## Cách chuyển sang tiếng Anh

Nếu muốn chuyển lại sang tiếng Anh:

```javascript
localStorage.setItem('i18nextLng', 'en');
location.reload();
```

## Các ngôn ngữ được hỗ trợ

- `vi` - Tiếng Việt (mặc định)
- `en` - English
- `zh-cn` - 中文 (Tiếng Trung)
- `es` - Español (Tiếng Tây Ban Nha)
- `ar` - العربية (Tiếng Ả Rập)

## Lưu ý

- Ngôn ngữ được lưu trong `localStorage` với key `i18nextLng`
- Nếu không có trong localStorage, hệ thống sẽ dùng ngôn ngữ mặc định (vi)
- Nếu không có trong localStorage và browser language là en, hệ thống sẽ dùng fallback (en)

## Tích hợp với Backend

Frontend sẽ tự động gửi header `Accept-Language` khi gọi API:
- Nếu language là `vi`, header sẽ là `Accept-Language: vi`
- Backend sẽ tự động detect và trả về error messages theo ngôn ngữ tương ứng

## Thêm translations mới

Để thêm translations mới, chỉnh sửa file:
- `frontend/demo/src/i18n/locales/vi/translations.json` - Tiếng Việt
- `frontend/demo/src/i18n/locales/en/translations.json` - Tiếng Anh
- Các file translations khác tương tự

Sau đó rebuild ứng dụng.

