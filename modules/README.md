# 📦 Modules Ngoài Binary

Thư mục này chứa các **module ngoài binary** - có thể phát triển mà **không cần rebuild backend**.

## 🎯 Mục Đích

- ✅ **Module ngoài binary**: Không compile vào backend
- ✅ **Tự động load**: Backend tự động scan khi khởi động
- ✅ **Độc lập**: Developer có thể phát triển module riêng
- ✅ **Hot reload**: Restart backend để load module mới

## 📁 Cấu Trúc

```
modules/
└── school/              # Module quản lý trường học
    └── manifest.json    # Metadata & config (bắt buộc)
```

## 🚀 Tạo Module Mới

### **Bước 1: Tạo Thư Mục**

```bash
mkdir -p modules/my-module
cd modules/my-module
```

### **Bước 2: Tạo `manifest.json`**

```json
{
  "name": "my-module",
  "display_name": "Module Của Tôi",
  "description": "Mô tả module",
  "version": "0.1.0",
  "metadata": {
    "form": {
      "fields": [
        { "name": "name", "label": "Tên", "type": "text", "width": 8, "required": true }
      ]
    },
    "list": {
      "columns": [
        { "name": "name", "label": "Tên" }
      ]
    }
  }
}
```

### **Bước 3: Restart Backend**

Backend tự động scan `modules/` và load module của bạn!

```
✅ Loaded module: my-module
✅ Loaded 1 modules ngoài binary
```

## 📡 API Endpoints

Sau khi load, backend expose các endpoints:

```
GET  /my-module/metadata  → Trả về metadata từ manifest.json
POST /my-module/create    → Tạo mới (cần implement handler)
GET  /my-module/list      → Danh sách (cần implement handler)
```

## 📝 Ví Dụ: Module School

Xem `modules/school/manifest.json` làm mẫu.

## ✅ Ưu Điểm

1. **Không rebuild backend** - Chỉ cần thêm `manifest.json`
2. **Độc lập** - Mỗi dev phát triển module riêng
3. **Dễ mở rộng** - Thêm module mới không ảnh hưởng backend

## 🔧 Phát Triển

- **Metadata**: Định nghĩa trong `manifest.json`
- **Routes**: Đăng ký trong `backend/src/api/router.rs`
- **Handlers**: Implement trong `backend/src/module/{name}/handler.rs`

