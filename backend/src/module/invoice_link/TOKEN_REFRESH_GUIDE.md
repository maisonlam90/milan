# Hướng dẫn Test Auto-Refresh Token

## Tính năng

Hệ thống tự động refresh access token khi:
1. Token không tồn tại (`access_token = NULL`)
2. Token hết hạn (`token_expires_at <= NOW()`)
3. Token sắp hết hạn trong vòng 5 phút (`token_expires_at <= NOW() + 5 minutes`)

## Cách thức hoạt động

### 1. Khi Link Provider (Lần đầu)
```sql
-- Token mới được tạo và lưu vào DB
INSERT INTO invoice_link_provider_credentials (
    access_token = 'new_token_from_viettel',
    token_expires_at = NOW() + INTERVAL '24 hours'
)
```

### 2. Khi Gửi Hóa đơn
```rust
// Function ensure_valid_token() sẽ kiểm tra:

// Case 1: Token còn hạn
if token_expires_at > NOW() + 5 minutes {
    return current_token; // Sử dụng token hiện tại
}

// Case 2: Token hết hạn hoặc sắp hết hạn
if token_expires_at <= NOW() + 5 minutes {
    // Login lại vào provider
    new_token = viettel::login(username, password);
    
    // Update token mới vào DB
    UPDATE invoice_link_provider_credentials
    SET access_token = new_token,
        token_expires_at = NOW() + INTERVAL '24 hours';
    
    return new_token;
}
```

## Test Scenarios

### Scenario 1: Token còn hạn (Normal Flow)
```bash
# 1. Xem token hiện tại
psql -d your_db -c "SELECT id, provider, access_token, token_expires_at FROM invoice_link_provider_credentials WHERE provider = 'viettel';"

# 2. Gửi hóa đơn qua API
curl -X POST http://localhost:3000/invoice-link/send \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "invoice_id": "your-invoice-uuid",
    "provider": "viettel"
  }'

# 3. Kiểm tra log - Sẽ thấy message: "Token still valid, using existing token"
# Token trong DB không thay đổi
```

### Scenario 2: Token hết hạn (Auto Refresh)
```bash
# 1. Set token hết hạn trong DB (để test)
psql -d your_db -c "UPDATE invoice_link_provider_credentials 
                    SET token_expires_at = NOW() - INTERVAL '1 hour' 
                    WHERE provider = 'viettel';"

# 2. Xem token trước khi refresh
psql -d your_db -c "SELECT id, provider, LEFT(access_token, 20) as token_preview, token_expires_at 
                    FROM invoice_link_provider_credentials 
                    WHERE provider = 'viettel';"

# Output:
#  id  | provider | token_preview        | token_expires_at
# -----+----------+---------------------+------------------
#  ... | viettel  | old_token_abc...    | 2024-12-01 10:00 (expired)

# 3. Gửi hóa đơn qua API
curl -X POST http://localhost:3000/invoice-link/send \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "invoice_id": "your-invoice-uuid",
    "provider": "viettel"
  }'

# 4. Kiểm tra log - Sẽ thấy:
# ✅ "Refreshing token for credential ... (provider: viettel)"
# ✅ "Token refreshed successfully for credential ..."
# ✅ "Invoice ... sent to viettel successfully"

# 5. Xem token sau khi refresh
psql -d your_db -c "SELECT id, provider, LEFT(access_token, 20) as token_preview, token_expires_at 
                    FROM invoice_link_provider_credentials 
                    WHERE provider = 'viettel';"

# Output:
#  id  | provider | token_preview        | token_expires_at
# -----+----------+---------------------+------------------
#  ... | viettel  | new_token_xyz...    | 2024-12-02 10:00 (valid for 24h)
```

### Scenario 3: Token sắp hết hạn (Proactive Refresh)
```bash
# 1. Set token sắp hết hạn (3 phút nữa)
psql -d your_db -c "UPDATE invoice_link_provider_credentials 
                    SET token_expires_at = NOW() + INTERVAL '3 minutes' 
                    WHERE provider = 'viettel';"

# 2. Gửi hóa đơn - Token sẽ được refresh proactive
curl -X POST http://localhost:3000/invoice-link/send \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "invoice_id": "your-invoice-uuid",
    "provider": "viettel"
  }'

# 3. Log sẽ hiện: "Refreshing token for credential ... (provider: viettel)"
```

### Scenario 4: Không có token (First Time Refresh)
```bash
# 1. Xóa token trong DB
psql -d your_db -c "UPDATE invoice_link_provider_credentials 
                    SET access_token = NULL, 
                        token_expires_at = NULL 
                    WHERE provider = 'viettel';"

# 2. Gửi hóa đơn - Token sẽ được tạo mới
curl -X POST http://localhost:3000/invoice-link/send \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "invoice_id": "your-invoice-uuid",
    "provider": "viettel"
  }'

# 3. Log sẽ hiện: "No token found for credential ..., refreshing token"
```

## Kiểm tra Log

Backend log sẽ hiển thị các message sau:

### Token còn hạn
```
[INFO] Token still valid for credential abc-123-def, expires at: 2024-12-02 10:00:00
```

### Token hết hạn - Refresh thành công
```
[WARN] Token exists but expired at 2024-12-01 10:00:00, refreshing token for credential abc-123-def
[INFO] Refreshing token for credential abc-123-def (provider: viettel)
[INFO] Viettel login successful for username: 0100109106-507
[INFO] Token refreshed successfully for credential abc-123-def
[INFO] Invoice abc-invoice-id sent to viettel successfully
```

### Token hết hạn - Refresh thất bại (credentials sai)
```
[WARN] Token expired, refreshing token for credential abc-123-def
[INFO] Refreshing token for credential abc-123-def (provider: viettel)
[ERROR] Viettel login failed during token refresh: Viettel login failed: 401 - Invalid credentials
[ERROR] Failed to ensure valid token: RowNotFound
[ERROR] Failed to send invoice to viettel: ...
```

## Monitoring

Để monitor token expiry trong production:

```sql
-- Xem tất cả credentials và thời gian hết hạn
SELECT 
    id,
    tenant_id,
    provider,
    is_active,
    is_default,
    CASE 
        WHEN token_expires_at IS NULL THEN 'NO_EXPIRY_INFO'
        WHEN token_expires_at < NOW() THEN 'EXPIRED'
        WHEN token_expires_at < NOW() + INTERVAL '1 hour' THEN 'EXPIRING_SOON'
        ELSE 'VALID'
    END as token_status,
    token_expires_at,
    token_expires_at - NOW() as time_until_expiry
FROM invoice_link_provider_credentials
WHERE is_active = true
ORDER BY token_expires_at ASC;
```

## Best Practices

1. **Buffer Time**: Hệ thống refresh token trước 5 phút để tránh race condition
2. **Concurrent Requests**: Nếu có nhiều request đồng thời, mỗi request sẽ check và refresh riêng (có thể optimize sau với distributed lock)
3. **Error Handling**: Nếu refresh thất bại, hóa đơn sẽ không được gửi và status = 'failed'
4. **Token Lifetime**: Mặc định 24 giờ, có thể adjust trong code nếu Viettel API trả về `expires_in`

## Troubleshooting

### Lỗi: "No active credentials found"
```bash
# Kiểm tra xem có credentials active không
psql -d your_db -c "SELECT * FROM invoice_link_provider_credentials WHERE provider = 'viettel' AND is_active = true;"

# Nếu không có, cần link provider lại
curl -X POST http://localhost:3000/invoice-link/providers/link \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "viettel",
    "credentials": {
      "username": "0100109106-507",
      "password": "2wsxCDE#",
      "template_code": "1/3939",
      "invoice_series": "K25MEL"
    },
    "is_default": true
  }'
```

### Lỗi: "Viettel login failed"
- Check username/password trong DB
- Check network connection đến Viettel API
- Check Viettel API có đang hoạt động không

### Token refresh liên tục (loop)
- Kiểm tra thời gian server có đúng không: `date`
- Kiểm tra timezone: `SELECT NOW(), timezone('UTC', NOW());`

