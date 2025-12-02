# Invoice Link Module - Tích hợp Hóa đơn điện tử

Module này cho phép tích hợp hệ thống hóa đơn với các nhà cung cấp hóa đơn điện tử (E-Invoice Providers) như Viettel, Mobifone, v.v.

## Tính năng

- ✅ Quản lý thông tin đăng nhập (credentials) của các provider
- ✅ Gửi hóa đơn tự động lên provider khi tạo invoice
- ✅ Theo dõi trạng thái liên kết hóa đơn
- ✅ Hỗ trợ nhiều provider (hiện tại: Viettel)

## Cấu trúc Database

### Bảng `invoice_link_provider_credentials`
Lưu thông tin đăng nhập của các provider:
- `username`, `password`: Thông tin đăng nhập
- `template_code`: Mẫu hóa đơn (ví dụ: "1/3939")
- `invoice_series`: Ký hiệu hóa đơn (ví dụ: "K25MEL")
- `is_default`: Đánh dấu credentials mặc định cho provider
- `is_active`: Credentials có đang hoạt động không

### Bảng `invoice_link`
Lưu lịch sử liên kết hóa đơn với provider:
- `invoice_id`: ID hóa đơn trong hệ thống
- `provider`: Tên provider (viettel, mobifone)
- `provider_invoice_id`: ID hóa đơn từ provider
- `status`: Trạng thái (pending, linked, failed)
- `error_message`: Thông báo lỗi nếu có

## API Endpoints

### 1. Quản lý Provider

#### Lấy danh sách providers
```http
GET /invoice-link/providers
```

Response:
```json
{
  "items": [
    {
      "code": "viettel",
      "name": "Viettel Invoice",
      "description": "Hệ thống hóa đơn điện tử Viettel"
    }
  ]
}
```

#### Lấy form fields của provider
```http
GET /invoice-link/providers/{provider}/form-fields
```

Response:
```json
{
  "provider": "viettel",
  "fields": [
    {
      "name": "username",
      "label": "Tên đăng nhập",
      "field_type": "text",
      "required": true
    },
    ...
  ]
}
```

#### Link provider với tenant
```http
POST /invoice-link/providers/link
Content-Type: application/json

{
  "provider": "viettel",
  "credentials": {
    "username": "0100109106-507",
    "password": "2wsxCDE#",
    "template_code": "1/3939",
    "invoice_series": "K25MEL"
  },
  "is_default": true
}
```

### 2. Gửi hóa đơn

#### Gửi hóa đơn đến provider
```http
POST /invoice-link/send
Content-Type: application/json

{
  "invoice_id": "uuid-of-invoice",
  "provider": "viettel",
  "credential_id": "uuid-of-credential" // optional, nếu không có sẽ dùng credential mặc định
}
```

Response:
```json
{
  "link_id": "uuid-of-link",
  "status": "linked",
  "provider_invoice_id": "INV123456",
  "provider_invoice_number": "K25MEL0000001",
  "message": "Hóa đơn đã được gửi thành công đến viettel"
}
```

### 3. Xem lịch sử

#### Lấy danh sách invoice links
```http
GET /invoice-link/list?invoice_id={uuid}&provider=viettel&status=linked
```

#### Lấy invoice link theo invoice_id
```http
GET /invoice-link/invoice/{invoice_id}
```

#### Lấy invoice link theo ID
```http
GET /invoice-link/{link_id}
```

## Sử dụng trong Frontend

Trong trang invoice-create, đã có nút "Tạo hóa đơn điện tử" để gửi hóa đơn lên Viettel:

```typescript
const handleCreateEInvoice = async () => {
  const response = await axiosInstance.post('/invoice-link/send', {
    invoice_id: invoiceId,
    provider: 'viettel',
  });
  
  if (response.data.status === 'linked') {
    // Thành công
    console.log('E-Invoice created:', response.data);
  }
};
```

## Demo Data

File migration `20251205000000_invoice_link_viettel_demo_data.sql` đã tạo sẵn credentials demo cho Viettel:

```json
{
  "username": "0100109106-507",
  "password": "2wsxCDE#",
  "template_code": "1/3939",
  "invoice_series": "K25MEL"
}
```

## Luồng hoạt động

1. **Setup credentials**: Quản trị viên thiết lập thông tin đăng nhập của provider qua API `/invoice-link/providers/link`
   - Hệ thống sẽ login vào provider để lấy access token
   - Lưu token và thời gian hết hạn (24 giờ) vào database

2. **Tạo hóa đơn**: User tạo hóa đơn trong hệ thống (invoice-create)

3. **Gửi lên provider**: User bấm nút "Tạo hóa đơn điện tử", hệ thống sẽ:
   - Lấy credentials mặc định của Viettel
   - **Kiểm tra token có còn hạn không:**
     - Nếu token còn hạn (hoặc sắp hết hạn trong 5 phút) → Login lại để lấy token mới
     - Nếu token còn hạn → Sử dụng token hiện tại
   - Chuyển đổi dữ liệu hóa đơn sang format Viettel
   - Gửi request tạo draft invoice lên Viettel
   - Lưu kết quả vào bảng `invoice_link`

4. **Theo dõi**: User có thể xem lịch sử gửi hóa đơn và trạng thái qua các API list

### Auto-Refresh Token

Hệ thống tự động refresh token khi:
- Token không tồn tại
- Token hết hạn
- Token sắp hết hạn (trong vòng 5 phút)

Khi refresh token, hệ thống sẽ:
1. Login lại vào provider API
2. Lưu token mới vào database
3. Cập nhật `token_expires_at` (mặc định +24 giờ)
4. Sử dụng token mới để gửi hóa đơn

## Viettel API Integration

### Login
```rust
pub async fn login(username: &str, password: &str) -> Result<String>
```
- URL: `https://api-vinvoice.viettel.vn/auth/login`
- Return: access_token

### Create Draft Invoice
```rust
pub async fn create_draft_invoice(
    username: &str,
    access_token: &str,
    invoice: &InvoiceDto,
    credentials: &serde_json::Value,
) -> Result<ViettelCreateInvoiceResponse>
```
- URL: `https://api-vinvoice.viettel.vn/services/einvoiceapplication/api/InvoiceAPI/InvoiceWS/createOrUpdateInvoiceDraft/{username}`
- Return: invoice_id, invoice_number

## TODO

- [x] Tự động refresh access token khi hết hạn ✅ (Hoàn thành - token tự động refresh khi hết hạn hoặc sắp hết hạn)
- [ ] Thêm hỗ trợ cho Mobifone
- [ ] Thêm tính năng hủy hóa đơn điện tử
- [ ] Webhook để nhận thông báo từ provider
- [ ] Encrypt credentials trước khi lưu vào DB
- [ ] Lấy thông tin công ty (seller_info) từ config thay vì hardcode
- [ ] Đọc `expires_in` từ Viettel API response (nếu có) thay vì hardcode 24 giờ

## Notes

- Credentials được lưu dạng JSON trong bảng `invoice_link_provider_credentials`
- Mỗi tenant có thể có nhiều credentials cho cùng 1 provider
- Hệ thống sẽ ưu tiên dùng credentials có `is_default = true`
- Nếu không có `is_default`, sẽ lấy credentials mới nhất (ORDER BY updated_at DESC)

