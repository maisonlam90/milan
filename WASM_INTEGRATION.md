# WASM Module Integration Guide

Hướng dẫn chi tiết cách load và sử dụng WASM modules trong Milan platform.

## 🏗️ Kiến trúc

```
┌─────────────────┐
│  Backend API    │
│   (Axum/Rust)   │
└────────┬────────┘
         │
         ├─→ ModuleRegistry (wasm_loader.rs)
         │    ├─ Scan modules từ thư mục modules/
         │    ├─ Load manifest.json
         │    └─ Cache WASM instances
         │
         ├─→ WasmModule
         │    ├─ wasmtime Engine
         │    ├─ WASI support
         │    └─ Function execution
         │
         └─→ API Routes
              └─ POST /{module}/wasm/{function}
```

## 📁 Cấu trúc Module

Mỗi module WASM phải có cấu trúc sau:

```
modules/{module_name}/
├── manifest.json              # Module metadata (bắt buộc)
├── Cargo.toml                # Rust package config
├── src/
│   └── lib.rs                # Business logic
├── build.sh                  # Build script
└── target/
    └── wasm32-wasip1/
        └── release/
            └── {module_name}.wasm  # Compiled WASM binary
```

## 🚀 Load Module tại Runtime

### 1. Backend tự động scan modules khi khởi động

File: `backend/src/main.rs`

```rust
// Module Registry - Load WASM modules ngoài binary
let module_registry = ModuleRegistry::new();
let modules_dir = std::path::Path::new("modules");

if let Err(e) = module_registry.scan_modules(modules_dir) {
    tracing::warn!("⚠️  Không thể scan modules: {}", e);
} else {
    let count = module_registry.list_modules_owned().len();
    tracing::info!("✅ Loaded {} modules", count);
}

let module_registry = Arc::new(module_registry);
```

### 2. ModuleRegistry quản lý WASM instances

File: `backend/src/infra/wasm_loader.rs`

```rust
// Load WASM module vào cache (lazy loading)
let wasm_module = module_registry.load_wasm_module("sale")?;

// Call function
let result = module_registry.call_wasm_function(
    "sale",
    "calculate_line",
    vec![
        json!(10.0),   // qty
        json!(100.0),  // unit_price
        json!(10.0),   // tax_rate
    ]
)?;
```

## 🌐 API Endpoints

### 1. Get Module Metadata

```http
GET /sale/metadata
```

Response:
```json
{
  "name": "sale",
  "display_name": "Quản lý Bán Hàng",
  "version": "0.1.0",
  "metadata": { ... }
}
```

### 2. Call WASM Function

```http
POST /sale/wasm/calculate_line
Content-Type: application/json

{
  "args": [10.0, 100.0, 10.0]
}
```

Response:
```json
{
  "module": "sale",
  "function": "calculate_line",
  "result": "{\"subtotal\":1000.0,\"tax\":100.0,\"total\":1100.0}",
  "success": true
}
```

### 3. Validate State Transition

```http
POST /sale/wasm/validate_transition
Content-Type: application/json

{
  "args": ["draft", "sent"]
}
```

Response:
```json
{
  "module": "sale",
  "function": "validate_transition",
  "result": "{\"valid\":true,\"message\":\"Valid transition\"}",
  "success": true
}
```

## 📝 Example: Calling WASM from Frontend

### JavaScript/TypeScript

```typescript
// Calculate line totals
async function calculateLine(qty: number, unitPrice: number, taxRate: number) {
  const response = await fetch('/sale/wasm/calculate_line', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      args: [qty, unitPrice, taxRate]
    })
  });
  
  const data = await response.json();
  const result = JSON.parse(data.result);
  
  console.log('Subtotal:', result.subtotal);
  console.log('Tax:', result.tax);
  console.log('Total:', result.total);
  
  return result;
}

// Validate state transition
async function validateTransition(currentState: string, newState: string) {
  const response = await fetch('/sale/wasm/validate_transition', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      args: [currentState, newState]
    })
  });
  
  const data = await response.json();
  const result = JSON.parse(data.result);
  
  if (!result.valid) {
    alert(result.message);
    return false;
  }
  
  return true;
}

// Usage
const lineTotal = await calculateLine(10, 100, 10);
// => { subtotal: 1000, tax: 100, total: 1100 }

const canTransition = await validateTransition('draft', 'done');
// => false (invalid transition)
```

### cURL

```bash
# Calculate line
curl -X POST http://localhost:3000/sale/wasm/calculate_line \
  -H "Content-Type: application/json" \
  -d '{"args": [10.0, 100.0, 10.0]}'

# Validate transition
curl -X POST http://localhost:3000/sale/wasm/validate_transition \
  -H "Content-Type: application/json" \
  -d '{"args": ["draft", "sent"]}'

# Apply discount
curl -X POST http://localhost:3000/sale/wasm/apply_line_discount \
  -H "Content-Type: application/json" \
  -d '{"args": [100.0, 10.0]}'
```

## 🔧 Development Workflow

### 1. Tạo module mới

```bash
cd modules
mkdir my_module
cd my_module

# Tạo Cargo.toml, src/lib.rs, manifest.json
# (copy từ template)
```

### 2. Implement business logic

```rust
// modules/my_module/src/lib.rs

#[no_mangle]
pub extern "C" fn my_function(arg1: f64, arg2: f64) -> f64 {
    arg1 + arg2
}
```

### 3. Build WASM

```bash
cd modules/my_module
cargo build --target wasm32-wasip1 --release
```

### 4. Test từ API

```bash
curl -X POST http://localhost:3000/my_module/wasm/my_function \
  -H "Content-Type: application/json" \
  -d '{"args": [10.0, 20.0]}'
```

### 5. Hot reload (không cần restart backend)

Backend tự động reload modules khi có thay đổi (coming soon với file watcher).

## 🎯 Use Cases

### 1. Business Logic Isolation

Tách business logic khỏi core backend → dễ maintain và test riêng.

```rust
// Trong module sale
pub fn validate_sale_order(order: &SaleOrder) -> Result<(), String> {
    if order.amount_total < 0.0 {
        return Err("Amount cannot be negative".into());
    }
    // More validations...
    Ok(())
}
```

### 2. Plugin System

Cho phép third-party developers tạo modules mà không cần access source code chính.

### 3. Multi-tenancy Customization

Mỗi tenant có thể có custom business logic riêng (load WASM từ S3/database).

### 4. Performance

WASM chạy near-native speed, phù hợp cho computation-heavy tasks.

## ⚡ Performance

- **Load time**: ~50ms (first load, sau đó được cache)
- **Execution**: ~0.1ms cho simple functions
- **Memory**: WASM instance chiếm ~500KB RAM

## 🔐 Security

- WASM chạy trong sandbox, không có direct access vào filesystem/network
- WASI cung cấp controlled access tới system resources
- Module isolation đảm bảo không có memory leaks giữa modules

## 🐛 Debugging

### Enable WASM tracing

```bash
export WASMTIME_BACKTRACE_DETAILS=1
export RUST_LOG=debug
cargo run
```

### Check loaded modules

```bash
curl http://localhost:3000/api/modules
```

## 📚 References

- [WebAssembly Official](https://webassembly.org/)
- [wasmtime Documentation](https://docs.wasmtime.dev/)
- [WASI Specification](https://wasi.dev/)
- [Rust WASM Book](https://rustwasm.github.io/docs/book/)

## 🎉 Example: Sale Module

Module sale đã được tích hợp đầy đủ tại `modules/sale/`:

**Functions available:**
- `calculate_line(qty, unit_price, tax_rate)` → Calculate line totals
- `validate_transition(current_state, new_state)` → Validate state changes
- `apply_line_discount(price_unit, discount_percent)` → Apply discounts

**Try it:**

```bash
# Start backend
cd backend
cargo run

# In another terminal
curl -X POST http://localhost:3000/sale/wasm/calculate_line \
  -H "Content-Type: application/json" \
  -d '{"args": [5.0, 200.0, 10.0]}'
```

---

**Happy coding! 🚀**

