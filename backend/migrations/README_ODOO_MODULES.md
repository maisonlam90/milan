# Odoo ERP Module Migrations

## 📦 Module Overview

This directory contains **123 tables** extracted from Odoo ERP and converted to **YugabyteDB multi-tenant format** following the Milan Finance architecture.

### Modules Included

| Module | Tables | File | Description |
|--------|--------|------|-------------|
| **Product** | 39 | `20251205000000_product.sql` | Product catalog, variants, attributes, pricing |
| **Stock** | 66 | `20251205000001_stock.sql` | Inventory, warehouse, moves, picking, logistics |
| **Sale** | 15 | `20251205000002_sale.sql` | Sales orders, quotations, invoicing |
| **Purchase** | 3 | `20251205000003_purchase.sql` | Purchase orders, vendor management |

**Total: 123 tables**

---

## 🏗️ Architecture Changes

### Multi-Tenant Sharding

All main business tables have been converted to support **tenant-based sharding**:

```sql
CREATE TABLE public.product_template (
    tenant_id UUID NOT NULL,      -- Added for multi-tenancy
    id integer NOT NULL,
    name jsonb NOT NULL,
    -- ... other columns
);

ALTER TABLE ONLY public.product_template
    ADD CONSTRAINT product_template_pkey PRIMARY KEY (tenant_id, id);

CREATE INDEX IF NOT EXISTS idx_product_template_tenant 
    ON public.product_template(tenant_id);
```

### Key Features

✅ **tenant_id** added to all main tables  
✅ **Composite PRIMARY KEYs** (tenant_id, id) for sharding  
✅ **Tenant indexes** for fast lookups  
✅ **Preserved all original columns and comments**  
✅ **Compatible with YugabyteDB distributed SQL**  

---

## 📋 Module Details

### 1️⃣ Product Module (39 tables)

**Core Tables:**
- `product_template` - Product master data
- `product_product` - Product variants
- `product_attribute` - Product attributes (size, color, etc.)
- `product_attribute_value` - Attribute values
- `product_category` - Product categories
- `product_pricelist` - Price lists
- `product_pricelist_item` - Price list items
- `product_uom` - Units of measure
- `product_tag` - Product tags
- `product_supplierinfo` - Vendor information

**Additional Features:**
- Product combinations and variants
- Custom attributes and values
- Product documents and labels
- Price management
- Supplier relationships

### 2️⃣ Stock Module (66 tables)

**Core Tables:**
- `stock_location` - Warehouse locations
- `stock_warehouse` - Warehouses
- `stock_move` - Stock movements
- `stock_move_line` - Move line items
- `stock_quant` - Inventory quantities (quants)
- `stock_picking` - Picking operations
- `stock_picking_type` - Picking types (receipts, deliveries, etc.)
- `stock_lot` - Lot/serial numbers
- `stock_package` - Packages
- `stock_route` - Logistics routes
- `stock_rule` - Push/pull rules

**Advanced Features:**
- Multi-location inventory tracking
- Lot/serial number management
- Package tracking
- Routing and replenishment rules
- Inventory adjustments
- Backorder management
- Return operations
- Scrap management
- Storage categories
- Putaway strategies

### 3️⃣ Sale Module (15 tables)

**Core Tables:**
- `sale_order` - Sales orders
- `sale_order_line` - Order line items
- `sale_order_template` - Order templates
- `sale_order_template_line` - Template lines
- `sale_pdf_form_field` - PDF form fields

**Features:**
- Sales order management
- Down payment handling
- Order templates
- Discounts
- PDF customization
- Mass operations

### 4️⃣ Purchase Module (3 tables)

**Core Tables:**
- `purchase_order` - Purchase orders
- `purchase_order_line` - PO line items
- `purchase_order_stock_picking_rel` - PO to picking relation

**Features:**
- Purchase order management
- Vendor management
- Receipt tracking
- Bill/invoice integration

---

## 🔗 Table Relationships

### Cross-Module Dependencies

```
Product ──┐
          ├──→ Sale (products in orders)
          ├──→ Purchase (products to buy)
          └──→ Stock (inventory of products)

Stock ────┬──→ Sale (deliveries)
          └──→ Purchase (receipts)

Purchase ─→ Stock (receipts, picking)
Sale ─────→ Stock (deliveries, picking)
```

### Key Foreign Keys (to be implemented)

```sql
-- Sale → Product
ALTER TABLE sale_order_line 
    ADD CONSTRAINT fk_sale_line_product 
    FOREIGN KEY (tenant_id, product_id) 
    REFERENCES product_product(tenant_id, id);

-- Purchase → Product
ALTER TABLE purchase_order_line 
    ADD CONSTRAINT fk_purchase_line_product 
    FOREIGN KEY (tenant_id, product_id) 
    REFERENCES product_product(tenant_id, id);

-- Stock Move → Product
ALTER TABLE stock_move 
    ADD CONSTRAINT fk_stock_move_product 
    FOREIGN KEY (tenant_id, product_id) 
    REFERENCES product_product(tenant_id, id);
```

---

## 🚀 Usage

### Running Migrations

```bash
# Create database
sqlx database create

# Run all migrations
sqlx migrate run

# Or run specific module
psql -d your_database -f backend/migrations/20251205000000_product.sql
```

### Integration with Milan Finance

These modules integrate with the Milan Finance core:

```rust
// Example: Create sales order
pub async fn create_sale_order(
    ctx: UserContext,  // Contains tenant_id
    State(db): State<DbPool>,
    Json(input): Json<CreateSaleOrderDto>,
) -> Result<Json<SaleOrderDto>, AppError> {
    // Insert with tenant_id
    let order = sqlx::query_as!(
        SaleOrder,
        r#"
        INSERT INTO sale_order (tenant_id, partner_id, name, state, ...)
        VALUES ($1, $2, $3, $4, ...)
        RETURNING *
        "#,
        ctx.tenant_id,  // Automatic tenant isolation
        input.partner_id,
        input.name,
        "draft"
    )
    .fetch_one(&db)
    .await?;
    
    Ok(Json(order.into()))
}
```

---

## 📝 Next Steps

### 1. Data Type Optimization

Consider converting IDs from `integer` to `UUID`:

```sql
-- Current: id integer
-- Better: id UUID DEFAULT gen_random_uuid()

ALTER TABLE product_template 
    ALTER COLUMN id TYPE UUID USING gen_random_uuid();
```

### 2. Add Foreign Keys

Implement foreign key constraints between tables:

```sql
-- Example: Link sale_order_line to product
ALTER TABLE sale_order_line
    ADD CONSTRAINT fk_product
    FOREIGN KEY (tenant_id, product_id)
    REFERENCES product_product(tenant_id, id)
    ON DELETE RESTRICT;
```

### 3. Add Business Constraints

```sql
-- Example: Ensure positive quantities
ALTER TABLE sale_order_line
    ADD CONSTRAINT check_positive_qty
    CHECK (product_uom_qty > 0);

-- Example: Valid state transitions
ALTER TABLE sale_order
    ADD CONSTRAINT check_valid_state
    CHECK (state IN ('draft', 'sent', 'sale', 'done', 'cancel'));
```

### 4. Add Timestamps

```sql
-- Add audit columns if not present
ALTER TABLE product_template
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();
```

### 5. Optimize Indexes

```sql
-- Common query patterns
CREATE INDEX idx_sale_order_state 
    ON sale_order(tenant_id, state);
    
CREATE INDEX idx_product_category 
    ON product_template(tenant_id, categ_id);
    
CREATE INDEX idx_stock_location_usage 
    ON stock_location(tenant_id, usage);
```

---

## 🧪 Testing

```bash
# Test database creation
sqlx database create --database-url "postgresql://user:pass@localhost/test_db"

# Test migrations
sqlx migrate run --database-url "postgresql://user:pass@localhost/test_db"

# Verify tables
psql -d test_db -c "\dt public.*"

# Check constraints
psql -d test_db -c "
SELECT 
    table_name, 
    constraint_name, 
    constraint_type 
FROM information_schema.table_constraints 
WHERE table_schema = 'public' 
ORDER BY table_name;
"
```

---

## 📚 Resources

- [Milan Finance README](../../README.md)
- [YugabyteDB Documentation](https://docs.yugabyte.com/)
- [Odoo ERP Documentation](https://www.odoo.com/documentation/)
- [Multi-tenant Architecture Guide](../../README.md#database-sharding)

---

## ✅ Status

- [x] Extract tables from Odoo SQL dump
- [x] Add tenant_id to all main tables
- [x] Create composite PRIMARY KEYs
- [x] Add tenant sharding indexes
- [x] Preserve all columns and comments
- [x] Fix SQL syntax errors
- [ ] Add foreign key constraints
- [ ] Add business constraints (CHECK, UNIQUE)
- [ ] Convert IDs to UUID
- [ ] Add audit timestamps
- [ ] Create module-specific Rust handlers
- [ ] Write integration tests

---

**Generated:** 2025-12-04  
**Total Tables:** 123  
**Architecture:** Multi-tenant with tenant-based sharding  
**Database:** YugabyteDB (PostgreSQL compatible)

