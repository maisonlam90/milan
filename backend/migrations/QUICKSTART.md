# 🚀 Quick Start Guide - Odoo ERP Modules

**Ready to deploy 123 production-ready tables in 5 minutes!**

---

## 📦 What You Get

4 fully-integrated ERP modules for Milan Finance:

```
✅ Product Module (39 tables) - Complete product catalog
✅ Stock Module (66 tables) - Advanced inventory management  
✅ Sale Module (15 tables) - Sales order processing
✅ Purchase Module (3 tables) - Purchase order management
```

**Total:** 123 tables, fully enhanced, production-ready

---

## 🏃 Quick Deploy

### Option 1: Using sqlx (Recommended)

```bash
cd /home/milan/milan/backend
sqlx migrate run
```

Done! All 123 tables deployed with indexes, constraints, and foreign keys.

### Option 2: Manual psql

```bash
cd /home/milan/milan/backend/migrations

# Deploy all modules
psql -d your_database << EOF
\i 20251205000000_product.sql
\i 20251205000001_stock.sql
\i 20251205000002_sale.sql
\i 20251205000003_purchase.sql
EOF
```

---

## ✅ Verify Deployment

```sql
-- Count tables
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name ~ '^(product_|stock_|sale_|purchase_)';
-- Should return: 123

-- Check a sample table
SELECT * FROM product_template LIMIT 5;
SELECT * FROM sale_order LIMIT 5;
SELECT * FROM stock_location LIMIT 5;
```

---

## 🎯 Key Features

### ✨ UUID IDs
```sql
id UUID NOT NULL DEFAULT gen_random_uuid()
```
Better sharding, globally unique, secure

### 🔗 Foreign Keys
```sql
-- Referential integrity enforced
sale_order_line → sale_order
sale_order_line → product_product
```

### ✅ Business Rules
```sql
-- Data validation at DB level
CHECK (amount_total >= 0)
CHECK (product_uom_qty > 0)
CHECK (state IN ('draft', 'sent', 'sale', 'done', 'cancel'))
```

### 🚀 Optimized Indexes
```sql
-- Fast queries
idx_sale_order_tenant (tenant_id)
idx_sale_order_state (tenant_id, state)
idx_sale_order_partner (tenant_id, partner_id)
```

---

## 📖 Basic Usage Examples

### Create a Product

```rust
// src/module/product/handler.rs
pub async fn create_product(
    ctx: UserContext,
    State(db): State<PgPool>,
    Json(input): Json<CreateProductDto>,
) -> Result<Json<ProductDto>, AppError> {
    let product = sqlx::query_as!(
        Product,
        r#"
        INSERT INTO product_template (
            tenant_id, name, categ_id, list_price, active
        )
        VALUES ($1, $2, $3, $4, true)
        RETURNING *
        "#,
        ctx.tenant_id,
        input.name,
        input.category_id,
        input.price
    )
    .fetch_one(&db)
    .await?;
    
    Ok(Json(product.into()))
}
```

### Create a Sale Order

```rust
pub async fn create_sale_order(
    ctx: UserContext,
    State(db): State<PgPool>,
    Json(input): Json<CreateSaleOrderDto>,
) -> Result<Json<SaleOrderDto>, AppError> {
    // Start transaction
    let mut tx = db.begin().await?;
    
    // Create order
    let order = sqlx::query_as!(
        SaleOrder,
        r#"
        INSERT INTO sale_order (
            tenant_id, partner_id, name, state, date_order
        )
        VALUES ($1, $2, $3, 'draft', NOW())
        RETURNING *
        "#,
        ctx.tenant_id,
        input.partner_id,
        input.name
    )
    .fetch_one(&mut *tx)
    .await?;
    
    // Create order lines
    for line in input.lines {
        sqlx::query!(
            r#"
            INSERT INTO sale_order_line (
                tenant_id, order_id, product_id, 
                product_uom_qty, price_unit
            )
            VALUES ($1, $2, $3, $4, $5)
            "#,
            ctx.tenant_id,
            order.id,
            line.product_id,
            line.quantity,
            line.price
        )
        .execute(&mut *tx)
        .await?;
    }
    
    tx.commit().await?;
    Ok(Json(order.into()))
}
```

### Query with Filters

```rust
pub async fn get_orders(
    ctx: UserContext,
    State(db): State<PgPool>,
    Query(params): Query<OrderFilter>,
) -> Result<Json<Vec<SaleOrderDto>>, AppError> {
    // Uses optimized indexes
    let orders = sqlx::query_as!(
        SaleOrder,
        r#"
        SELECT * FROM sale_order
        WHERE tenant_id = $1
          AND ($2::TEXT IS NULL OR state = $2)
          AND ($3::INT IS NULL OR partner_id = $3)
          AND date_order >= $4
        ORDER BY date_order DESC
        LIMIT 100
        "#,
        ctx.tenant_id,
        params.state,
        params.partner_id,
        params.from_date
    )
    .fetch_all(&db)
    .await?;
    
    Ok(Json(orders.into_iter().map(Into::into).collect()))
}
```

### Stock Movement

```rust
pub async fn create_stock_move(
    ctx: UserContext,
    State(db): State<PgPool>,
    Json(input): Json<CreateStockMoveDto>,
) -> Result<Json<StockMoveDto>, AppError> {
    let stock_move = sqlx::query_as!(
        StockMove,
        r#"
        INSERT INTO stock_move (
            tenant_id, product_id, product_uom_qty,
            location_id, location_dest_id, state
        )
        VALUES ($1, $2, $3, $4, $5, 'draft')
        RETURNING *
        "#,
        ctx.tenant_id,
        input.product_id,
        input.quantity,
        input.from_location_id,
        input.to_location_id
    )
    .fetch_one(&db)
    .await?;
    
    Ok(Json(stock_move.into()))
}
```

---

## 🔍 Common Queries

### Products by Category
```sql
SELECT p.* 
FROM product_template p
WHERE p.tenant_id = $1
  AND p.categ_id = $2
  AND p.active = true
ORDER BY p.name;
```

### Orders by State
```sql
SELECT o.*, p.name as partner_name
FROM sale_order o
JOIN res_partner p ON o.partner_id = p.id
WHERE o.tenant_id = $1
  AND o.state = 'draft'
ORDER BY o.date_order DESC;
```

### Stock by Location
```sql
SELECT 
    q.product_id,
    p.name as product_name,
    l.name as location_name,
    SUM(q.quantity) as total_qty
FROM stock_quant q
JOIN product_product p ON q.product_id = p.id
JOIN stock_location l ON q.location_id = l.id
WHERE q.tenant_id = $1
  AND l.usage = 'internal'
GROUP BY q.product_id, p.name, l.name
HAVING SUM(q.quantity) > 0;
```

---

## 🎓 Module Relationships

```
┌─────────────────────────────────────────────────────┐
│                    Product Module                   │
│  • product_template (master data)                   │
│  • product_product (variants)                       │
│  • product_category, attributes, pricing            │
└──────────────┬──────────────────────────────────────┘
               │
               ├──→ Sale Module
               │    • sale_order
               │    • sale_order_line → product_product
               │
               ├──→ Purchase Module
               │    • purchase_order
               │    • purchase_order_line → product_product
               │
               └──→ Stock Module
                    • stock_move → product_product
                    • stock_quant → product_product
                    • stock_location, warehouse, picking
```

---

## 📊 Performance Tips

### Use Tenant Index
```sql
-- Always filter by tenant_id first
WHERE tenant_id = $1 AND ...
```

### Use State Index
```sql
-- State queries are optimized
WHERE tenant_id = $1 AND state = 'sale'
```

### Use Date Index
```sql
-- Date range queries are fast
WHERE tenant_id = $1 
  AND date_order >= $2 
  AND date_order < $3
ORDER BY date_order DESC
```

### Batch Inserts
```rust
// Insert multiple rows efficiently
let mut qb = QueryBuilder::new(
    "INSERT INTO sale_order_line (tenant_id, order_id, product_id, product_uom_qty, price_unit)"
);

qb.push_values(lines, |mut b, line| {
    b.push_bind(tenant_id)
     .push_bind(order_id)
     .push_bind(line.product_id)
     .push_bind(line.quantity)
     .push_bind(line.price);
});

qb.build().execute(&db).await?;
```

---

## 🛠️ Maintenance

### Analyze Tables
```sql
-- Update statistics for query planner
ANALYZE product_template;
ANALYZE sale_order;
ANALYZE stock_move;
```

### Check Index Usage
```sql
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as scans,
    idx_tup_read as tuples_read
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC
LIMIT 20;
```

### Monitor Slow Queries
```sql
-- Enable pg_stat_statements extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Find slow queries
SELECT 
    substring(query, 1, 100) as query,
    calls,
    total_time,
    mean_time
FROM pg_stat_statements
WHERE query LIKE '%sale_order%'
ORDER BY total_time DESC
LIMIT 10;
```

---

## 📚 Documentation

- **FINAL_SUMMARY.txt** - Executive summary
- **ENHANCEMENTS_SUMMARY.md** - Detailed enhancements
- **README_ODOO_MODULES.md** - Module documentation
- **MIGRATION_SUMMARY.txt** - Technical details

---

## ✅ Production Checklist

- [x] Tables deployed
- [ ] Sample data loaded
- [ ] Indexes analyzed
- [ ] Performance tested
- [ ] Backup configured
- [ ] Monitoring setup

---

## 🆘 Troubleshooting

### Foreign Key Violations
```sql
-- Check if referenced records exist
SELECT * FROM product_product WHERE tenant_id = $1 AND id = $2;
```

### Constraint Violations
```sql
-- Check constraint details
SELECT * FROM information_schema.check_constraints
WHERE constraint_schema = 'public'
  AND constraint_name LIKE 'check_%';
```

### Slow Queries
```sql
-- Explain query plan
EXPLAIN ANALYZE
SELECT * FROM sale_order
WHERE tenant_id = $1 AND state = 'sale';
```

---

**You're all set! 🎉**

Start building your ERP features with these production-ready modules.

Need help? Check the full documentation or Milan Finance README.

