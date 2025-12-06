# Sale Module (WASM)

Module quản lý bán hàng được viết bằng Rust và biên dịch sang WebAssembly.

## Cấu trúc

```
modules/sale/
├── Cargo.toml              # Rust package configuration
├── src/
│   └── lib.rs             # Main module logic
├── target/
│   └── wasm32-wasi/
│       └── release/
│           └── sale.wasm  # Compiled WASM binary
├── build.sh               # Build script
├── manifest.json          # Module metadata
└── README.md             # This file
```

## Yêu cầu

- Rust toolchain (rustc, cargo)
- wasm32-wasi target: `rustup target add wasm32-wasi`
- (Optional) wasm-opt: `npm install -g wasm-opt` hoặc cài từ binaryen

## Build

### Sử dụng build script:

```bash
chmod +x build.sh
./build.sh
```

### Build thủ công:

```bash
cargo build --target wasm32-wasi --release
```

## Chức năng

Module sale cung cấp các chức năng:

### Business Logic

- **calculate_line_totals**: Tính toán subtotal, tax, và total cho mỗi dòng đơn hàng
- **calculate_order_totals**: Tính tổng đơn hàng từ các dòng
- **validate_state_transition**: Kiểm tra chuyển đổi trạng thái hợp lệ
- **can_modify_order**: Kiểm tra đơn hàng có thể sửa được không
- **can_cancel_order**: Kiểm tra đơn hàng có thể hủy được không
- **apply_discount**: Áp dụng giảm giá cho dòng đơn hàng
- **calculate_delivery_date**: Tính ngày giao hàng dự kiến

### State Transitions

```
draft → sent → sale → done
  ↓      ↓      ↓
cancel ←─────────┘
  ↓
draft
```

### WASM Exports

Module xuất các hàm C-compatible cho WASM:

- `calculate_line(qty, unit_price, tax_rate)`: Trả về JSON với subtotal, tax, total
- `validate_transition(current_state, new_state)`: Trả về JSON với valid và message
- `apply_line_discount(price_unit, discount_percent)`: Trả về giá sau giảm

## Testing

```bash
cargo test
```

## Tối ưu hóa

File Cargo.toml đã được cấu hình để tối ưu hóa kích thước WASM:

- Optimization level: "z" (optimize for size)
- LTO: enabled
- Strip symbols: enabled

Kích thước WASM mục tiêu: < 100KB

## Sử dụng trong ứng dụng

```rust
// Load WASM module
let wasm_bytes = std::fs::read("modules/sale/target/wasm32-wasi/release/sale.wasm")?;

// Use với wasmtime hoặc wasmer
// ... your WASM runtime code here
```

## Development

Để thêm chức năng mới:

1. Viết logic trong `src/lib.rs`
2. Thêm tests
3. Export hàm WASM nếu cần
4. Build lại module
5. Test với ứng dụng chính

## Notes

- Module này độc lập và có thể được load động
- Tất cả business logic liên quan đến sale nên nằm trong module này
- Module giao tiếp qua JSON cho dễ dàng tích hợp

