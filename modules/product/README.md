# Product Module - WASM Integration

Module quản lý sản phẩm với WASM functions cho tính toán giá, margin, và validation.

## 📁 Cấu trúc

```
modules/product/
├── manifest.json           # Metadata cho form, notebook, list
├── Cargo.toml             # Rust project config
├── build.sh               # Build script
├── src/
│   └── lib.rs            # WASM functions
└── target/               # Build output (sau khi build)
```

## 🔧 Build WASM Module

```bash
cd modules/product
./build.sh
```

Output: `target/wasm32-unknown-unknown/release/product.wasm`

## 🌐 Backend Endpoints Cần Implement

Backend cần implement các endpoints sau:

### 1. Metadata Endpoint
```rust
GET /product/metadata

Response: Trả về nội dung file manifest.json
```

### 2. CRUD Endpoints
```rust
GET /product/list
  - Query params: page, limit, search, filters
  - Response: Danh sách products từ product_template

GET /product/:id
  - Response: Chi tiết product + variants (product_product)

POST /product/create
  - Body: Product data + variants
  - Response: Created product

POST /product/:id/update
  - Body: Product data + variants
  - Response: Updated product
```

### 3. WASM Function Endpoints
```rust
POST /product/wasm/calculate_price_margin
  - Body: { args: [cost, margin_percent] }
  - Response: { success: true, result: "{sale_price, profit, margin}" }

POST /product/wasm/calculate_margin_from_prices
  - Body: { args: [cost, sale_price] }
  - Response: { success: true, result: "{margin, profit}" }

POST /product/wasm/validate_code
  - Body: { args: ["PROD-001"] }
  - Response: { success: true, result: "{valid, message}" }

POST /product/wasm/calculate_inventory_total
  - Body: { args: [qty, cost] }
  - Response: { success: true, result: total_value }

POST /product/wasm/apply_discount
  - Body: { args: [list_price, discount_percent] }
  - Response: { success: true, result: discounted_price }
```

## 📊 Database Schema

Module sử dụng 2 bảng chính:

### product_template (Root table)
```sql
- tenant_id (UUID, PK)
- id (UUID, PK)
- name (text, required)
- default_code (text)
- type (text, required: "consu", "service", "product")
- categ_id (int)
- list_price (numeric)
- uom_id (int, required)
- tracking (text, required: "none", "serial", "lot")
- service_tracking (text, required)
- sale_ok (boolean)
- purchase_ok (boolean)
- weight (numeric)
- volume (numeric)
- sale_delay (int)
- description (jsonb)
- ...
```

### product_product (Variants - Notebook)
```sql
- tenant_id (UUID, PK)
- id (UUID, PK)
- product_tmpl_id (int, FK)
- default_code (text)
- barcode (text)
- standard_price (jsonb)
- volume (numeric)
- weight (numeric)
- active (boolean)
- ...
```

## 🎯 WASM Functions

### 1. calculate_price_with_margin
Tính giá bán từ giá vốn và tỷ suất lợi nhuận.

```rust
pub fn calculate_price_with_margin(cost: f64, margin_percent: f64) -> f64
```

Example: cost=100, margin=20% → sale_price=120

### 2. calculate_margin
Tính tỷ suất lợi nhuận từ giá vốn và giá bán.

```rust
pub fn calculate_margin(cost: f64, sale_price: f64) -> f64
```

Example: cost=100, sale_price=120 → margin=20%

### 3. validate_product_code
Validate mã sản phẩm (alphanumeric, hyphens, underscores, max 50 chars).

```rust
pub fn validate_product_code(code: &str) -> Result<(), String>
```

### 4. calculate_inventory_value
Tính tổng giá trị tồn kho.

```rust
pub fn calculate_inventory_value(qty: f64, cost: f64) -> f64
```

### 5. calculate_discount_price
Áp dụng giảm giá.

```rust
pub fn calculate_discount_price(list_price: f64, discount_percent: f64) -> f64
```

## 🎨 Frontend Components

### Product Create Page
Path: `/dashboards/product/product-create`

Features:
- Dynamic form từ metadata
- Product variants notebook
- Auto-calculate margin/profit bằng WASM
- Tabs cho thông tin chi tiết
- View/Edit mode

### Product List Page
Path: `/dashboards/product/product-list`

Features:
- AG Grid với dynamic columns từ metadata
- Search & filter
- Double-click để mở chi tiết
- Create new button

## 🚀 Quick Start

1. **Build WASM module:**
   ```bash
   cd modules/product
   ./build.sh
   ```

2. **Copy WASM binary vào backend:**
   ```bash
   cp target/wasm32-unknown-unknown/release/product.wasm ../../backend/wasm_modules/
   ```

3. **Implement backend endpoints** (xem phần Backend Endpoints ở trên)

4. **Add routes vào frontend router:**
   ```typescript
   // frontend/demo/src/app/router/protected.tsx
   {
     path: "/dashboards/product/product-list",
     element: <ProductListPage />
   },
   {
     path: "/dashboards/product/product-create",
     element: <ProductCreatePage />
   }
   ```

5. **Add navigation menu:**
   ```typescript
   // frontend/demo/src/app/navigation/segments/dashboards.ts
   {
     title: "Sản phẩm",
     icon: "ic:outline-inventory-2",
     path: "/dashboards/product/product-list"
   }
   ```

## 📝 Notes

- Module sử dụng cấu trúc tương tự module `sale`
- Metadata được load từ `manifest.json` thông qua API
- WASM functions được gọi qua backend proxy
- Multi-tenant support với `tenant_id` trong all tables
- Product variants được quản lý trong bảng `product_product`

## 🐛 Debugging

Nếu không thấy fields hiển thị:
1. Mở DevTools Console
2. Xem logs: "✅ Metadata loaded", "🔍 All fields converted", "🔍 Important fields"
3. Kiểm tra API response: `/product/metadata` phải trả về đúng cấu trúc manifest.json
4. Kiểm tra network tab: Xem request có thành công không

## 📚 Tham khảo

- Module sale: `modules/sale/`
- WASM Integration Guide: `WASM_INTEGRATION.md`
- Backend handler example: `backend/src/module/app/handler.rs`

