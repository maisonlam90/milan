# 📄 Invoice Module - Complete Guide

## 📋 Tổng quan

Module Invoice của Milan Finance được thiết kế dựa trên **Odoo 19 account.move module**. Module này cung cấp đầy đủ chức năng quản lý hóa đơn, bao gồm:

- ✅ Hóa đơn bán hàng (Customer Invoice)
- ✅ Hóa đơn mua hàng (Vendor Bill)
- ✅ Phiếu giảm giá (Credit Note / Debit Note)
- ✅ Quản lý thanh toán
- ✅ Thuế VAT
- ✅ Điều khoản thanh toán
- ✅ Sổ nhật ký kế toán
- ✅ Multi-currency support
- ✅ Multi-tenant với sharding

**Reference:**
- Odoo GitHub: https://github.com/odoo/odoo/tree/19.0/addons/account
- OpenAPI Spec: `docs/openapi-invoice.yaml`
- Database Migration: `migrations/20250820000000_invoice.sql`

---

## 🗄️ Database Schema

### Core Tables (11 tables)

#### 1. **account_move** - Hóa đơn chính
Bảng chính lưu trữ thông tin hóa đơn (giống Odoo account.move)

```sql
CREATE TABLE account_move (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL,
    name VARCHAR(255),                -- Số hóa đơn (INV/001, BILL/001)
    move_type VARCHAR(50),            -- out_invoice, in_invoice, out_refund, in_refund, entry
    partner_id UUID NOT NULL,         -- Khách hàng/Nhà cung cấp
    state VARCHAR(50),                -- draft, posted, cancel
    payment_state VARCHAR(50),        -- not_paid, in_payment, paid, partial, reversed
    invoice_date DATE,
    invoice_date_due DATE,
    amount_untaxed BIGINT,            -- Tổng trước thuế
    amount_tax BIGINT,                -- Tổng thuế
    amount_total BIGINT,              -- Tổng cộng
    amount_residual BIGINT,           -- Còn nợ
    ...
    PRIMARY KEY (tenant_id, id)
);
```

**Move Types:**
- `out_invoice` - Hóa đơn bán hàng (Customer Invoice)
- `in_invoice` - Hóa đơn mua hàng (Vendor Bill)
- `out_refund` - Phiếu giảm giá bán (Credit Note)
- `in_refund` - Phiếu giảm giá mua (Debit Note)
- `entry` - Bút toán chung (Journal Entry)

#### 2. **account_move_line** - Chi tiết hóa đơn
Bảng lưu trữ các dòng chi tiết trong hóa đơn

```sql
CREATE TABLE account_move_line (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL,
    move_id UUID NOT NULL,            -- FK to account_move
    name TEXT NOT NULL,               -- Mô tả sản phẩm/dịch vụ
    quantity NUMERIC(16,4),
    price_unit BIGINT,
    discount NUMERIC(5,2),            -- Giảm giá (%)
    price_subtotal BIGINT,            -- Tổng trước thuế
    price_total BIGINT,               -- Tổng sau thuế
    account_id UUID,                  -- Tài khoản kế toán
    analytic_distribution JSONB,      -- Phân bổ chi phí
    ...
    PRIMARY KEY (tenant_id, id)
);
```

#### 3. **account_tax** - Thuế
```sql
CREATE TABLE account_tax (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL,
    name VARCHAR(255),                -- VAT 10%, VAT 5%
    amount_type VARCHAR(50),          -- percent, fixed, division
    amount NUMERIC(16,4),             -- Tỷ lệ %
    type_tax_use VARCHAR(50),         -- sale, purchase, none
    price_include BOOLEAN,            -- Giá đã bao gồm thuế
    ...
);
```

#### 4. **account_payment** - Thanh toán
```sql
CREATE TABLE account_payment (
    tenant_id UUID NOT NULL,
    id UUID NOT NULL,
    payment_type VARCHAR(50),         -- inbound, outbound
    partner_type VARCHAR(50),         -- customer, supplier
    partner_id UUID,
    amount BIGINT,
    payment_date DATE,
    payment_method_id UUID,
    journal_id UUID,
    state VARCHAR(50),                -- draft, posted, reconciled, cancelled
    ...
);
```

#### 5-11. Supporting Tables
- `account_move_line_tax_rel` - Liên kết line ↔ tax (many-to-many)
- `account_move_payment_rel` - Liên kết invoice ↔ payment (many-to-many)
- `account_payment_term` - Điều khoản thanh toán
- `account_payment_term_line` - Chi tiết điều khoản
- `account_journal` - Sổ nhật ký kế toán
- `account_payment_method` - Phương thức thanh toán
- `account_fiscal_position` - Vị thế thuế (tax mapping)

---

## 🚀 API Endpoints

### CRUD Operations

#### 1. Create Invoice
```bash
POST /api/v1/invoice/create
Content-Type: application/json
Authorization: Bearer <token>

{
  "move_type": "out_invoice",
  "partner_id": "uuid",
  "invoice_date": "2025-01-15",
  "invoice_date_due": "2025-02-15",
  "currency_id": "VND",
  "invoice_lines": [
    {
      "name": "Laptop Dell XPS 15",
      "quantity": 2.0,
      "price_unit": 25000000,
      "discount": 5.0,
      "tax_ids": ["tax-uuid"]
    }
  ]
}
```

#### 2. List Invoices (with filters)
```bash
GET /api/v1/invoice/list?move_type=out_invoice&state=posted&limit=50&offset=0
Authorization: Bearer <token>
```

#### 3. Get Invoice Detail
```bash
GET /api/v1/invoice/{id}
Authorization: Bearer <token>
```

#### 4. Update Invoice (draft only)
```bash
PUT /api/v1/invoice/{id}/update
Content-Type: application/json
Authorization: Bearer <token>

{
  "invoice_date_due": "2025-03-01",
  "narration": "Updated notes"
}
```

#### 5. Delete Invoice (draft only)
```bash
DELETE /api/v1/invoice/{id}
Authorization: Bearer <token>
```

### Workflow Actions

#### 6. Post Invoice (Confirm)
```bash
POST /api/v1/invoice/{id}/post
Authorization: Bearer <token>
```
Chuyển hóa đơn từ `draft` → `posted`. Sau khi post không thể sửa được nữa.

#### 7. Reset to Draft
```bash
POST /api/v1/invoice/{id}/reset-to-draft
Authorization: Bearer <token>
```

#### 8. Cancel Invoice
```bash
POST /api/v1/invoice/{id}/cancel
Authorization: Bearer <token>
```

#### 9. Create Reverse/Credit Note
```bash
POST /api/v1/invoice/{id}/reverse
Content-Type: application/json
Authorization: Bearer <token>

{
  "reason": "Sản phẩm lỗi, hoàn trả",
  "date": "2025-01-20"
}
```

### Payment Operations

#### 10. Add Payment
```bash
POST /api/v1/invoice/{id}/payment
Content-Type: application/json
Authorization: Bearer <token>

{
  "amount": 10000000,
  "payment_date": "2025-01-16",
  "payment_method_id": "uuid",
  "journal_id": "uuid",
  "communication": "Thanh toán INV/2025/0001"
}
```

#### 11. Get Payments
```bash
GET /api/v1/invoice/{id}/payments
Authorization: Bearer <token>
```

### Statistics & Reports

#### 12. Invoice Statistics
```bash
GET /api/v1/invoice/stats?from_date=2025-01-01&to_date=2025-01-31&move_type=out_invoice
Authorization: Bearer <token>
```

#### 13. Overdue Invoices
```bash
GET /api/v1/invoice/overdue?limit=50
Authorization: Bearer <token>
```

#### 14. Upcoming Invoices
```bash
GET /api/v1/invoice/upcoming?days=7
Authorization: Bearer <token>
```

---

## 🔄 Invoice Workflow

### Customer Invoice Flow (out_invoice)

```
1. CREATE → draft
   ↓
2. Edit & add lines (có thể sửa)
   ↓
3. POST → posted (xác nhận, không sửa được)
   ↓
4. ADD PAYMENT → payment_state: partial/paid
   ↓
5. FULLY PAID → payment_state: paid
```

### Vendor Bill Flow (in_invoice)

```
1. CREATE → draft
   ↓
2. POST → posted
   ↓
3. ADD PAYMENT → payment_state: partial/paid
```

### Credit Note Flow (out_refund)

```
1. From existing invoice → REVERSE
   ↓
2. Create Credit Note (out_refund)
   ↓
3. POST → posted
   ↓
4. Payment reconciliation
```

---

## 💾 Database Migration

### Run Migration

```bash
# Apply invoice schema
psql -U postgres -d milan_db -f migrations/20250820000000_invoice.sql

# Apply seed data (optional, for testing)
psql -U postgres -d milan_db -f migrations/20250820000001_invoice_seed.sql
```

### Rollback (if needed)

```sql
-- Drop all invoice tables
DROP TABLE IF EXISTS account_move_payment_rel CASCADE;
DROP TABLE IF EXISTS account_move_line_tax_rel CASCADE;
DROP TABLE IF EXISTS account_payment_term_line CASCADE;
DROP TABLE IF EXISTS account_payment CASCADE;
DROP TABLE IF EXISTS account_move_line CASCADE;
DROP TABLE IF EXISTS account_move CASCADE;
DROP TABLE IF EXISTS account_tax CASCADE;
DROP TABLE IF EXISTS account_payment_term CASCADE;
DROP TABLE IF EXISTS account_journal CASCADE;
DROP TABLE IF EXISTS account_payment_method CASCADE;
DROP TABLE IF EXISTS account_fiscal_position CASCADE;
DROP TABLE IF EXISTS invoice_counters_monthly CASCADE;
DROP VIEW IF EXISTS v_account_move_list CASCADE;
```

---

## 🧪 Testing

### Sample Data Created by Seed

Seed data (`20250820000001_invoice_seed.sql`) tạo:

1. **2 Contacts:**
   - Công ty ABC (customer)
   - Nhà cung cấp XYZ (supplier)

2. **5 Payment Methods:**
   - Manual (inbound/outbound)
   - Electronic (inbound/outbound)
   - Check (outbound)

3. **5 Journals:**
   - INV (Customer Invoices)
   - BILL (Vendor Bills)
   - BANK (Bank)
   - CASH (Cash)
   - MISC (Miscellaneous)

4. **3 Taxes:**
   - VAT 10% (sale)
   - VAT 5% (sale)
   - VAT 10% (purchase)

5. **4 Payment Terms:**
   - Immediate Payment
   - 15 Days
   - 30 Days
   - 45 Days

6. **1 Customer Invoice (draft):**
   - INV/2025/0001
   - 2 lines (Laptop + Dịch vụ)
   - Total: 11,000,000 VND
   - With partial payment: 5,000,000 VND

7. **1 Vendor Bill (posted):**
   - BILL/2025/0001
   - 1 line (Nguyên liệu)
   - Total: 5,500,000 VND

### Test API Calls

```bash
# 1. Get list invoices
curl -X GET http://localhost:8080/api/v1/invoice/list \
  -H "Authorization: Bearer <token>"

# 2. Get invoice detail
curl -X GET http://localhost:8080/api/v1/invoice/{id} \
  -H "Authorization: Bearer <token>"

# 3. Create new invoice
curl -X POST http://localhost:8080/api/v1/invoice/create \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "move_type": "out_invoice",
    "partner_id": "uuid",
    "invoice_date": "2025-01-20",
    "invoice_date_due": "2025-02-20",
    "invoice_lines": [
      {
        "name": "Test Product",
        "quantity": 1,
        "price_unit": 1000000
      }
    ]
  }'

# 4. Post invoice
curl -X POST http://localhost:8080/api/v1/invoice/{id}/post \
  -H "Authorization: Bearer <token>"

# 5. Add payment
curl -X POST http://localhost:8080/api/v1/invoice/{id}/payment \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 1000000,
    "payment_date": "2025-01-21",
    "payment_method_id": "uuid",
    "journal_id": "uuid"
  }'
```

---

## 📊 Business Logic

### Amount Calculations

```rust
// Tính toán số tiền trong invoice line
price_subtotal = (quantity * price_unit) * (1 - discount/100)
price_total = price_subtotal * (1 + tax_rate/100)

// Tính toán tổng invoice
amount_untaxed = SUM(line.price_subtotal)
amount_tax = SUM(line.price_total - line.price_subtotal)
amount_total = amount_untaxed + amount_tax
amount_residual = amount_total - SUM(payments.amount)
```

### Payment State Logic

```rust
if amount_residual == 0 {
    payment_state = "paid"
} else if amount_residual == amount_total {
    payment_state = "not_paid"
} else if amount_residual < amount_total {
    payment_state = "partial"
}
```

### Invoice Number Generation

```sql
-- Format: {PREFIX}/{YYYY}/{NNNN}
-- Examples:
-- - INV/2025/0001  (Customer Invoice)
-- - BILL/2025/0001 (Vendor Bill)
-- - RINV/2025/0001 (Credit Note)

-- Auto-increment per tenant, per move_type, per month
```

---

## 🎯 Next Steps

1. ✅ **Database Schema** - Created
2. ✅ **OpenAPI Spec** - Created
3. ⏳ **Implement Rust Code:**
   - `src/module/invoice/mod.rs`
   - `src/module/invoice/model.rs`
   - `src/module/invoice/dto.rs`
   - `src/module/invoice/router.rs`
   - `src/module/invoice/handler/`
   - `src/module/invoice/command.rs`
   - `src/module/invoice/query.rs`
   - `src/module/invoice/event.rs`
   - `src/module/invoice/calculator.rs`
   - `src/module/invoice/metadata.rs`

4. ⏳ **Register Module:**
   - Update `src/module/mod.rs`
   - Update `src/api/router.rs`

5. ⏳ **Testing:**
   - Unit tests
   - Integration tests
   - API tests

---

## 📚 References

- **Odoo 19 Source:** https://github.com/odoo/odoo/tree/19.0/addons/account
- **OpenAPI 3.0 Spec:** https://swagger.io/specification/
- **Milan Finance README:** `/README.md`
- **PostgreSQL JSON:** https://www.postgresql.org/docs/current/datatype-json.html

---

## 🔧 Maintenance Notes

### Index Optimization
- Tất cả queries phải có `tenant_id` trong WHERE clause
- Composite indexes được tạo cho các queries phổ biến
- GIN indexes cho JSONB và Array columns

### Performance Considerations
- Use `amount_*` computed fields thay vì tính real-time
- Cache invoice statistics
- Pagination cho list endpoints (default limit: 50)

### Security
- All endpoints require JWT authentication
- IAM fields: `created_by`, `assignee_id`, `shared_with`
- Row-level permissions qua IAM module

---

**Version:** 1.0.0  
**Created:** 2025-01-15  
**Author:** Milan Finance Team

