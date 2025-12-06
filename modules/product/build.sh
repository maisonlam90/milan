#!/bin/bash
# Build script for product WASM module

set -e  # Exit on error

echo "🏗️  Building product WASM module..."

# Check if cargo is installed
if ! command -v cargo &> /dev/null; then
    echo "❌ Error: cargo is not installed"
    exit 1
fi

# Build the WASM module
echo "📦 Compiling Rust to WASM..."
cargo build --target wasm32-unknown-unknown --release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📄 WASM binary: target/wasm32-unknown-unknown/release/product.wasm"
    
    # Get file size
    wasm_file="target/wasm32-unknown-unknown/release/product.wasm"
    if [ -f "$wasm_file" ]; then
        size=$(ls -lh "$wasm_file" | awk '{print $5}')
        echo "📊 Binary size: $size"
    fi
else
    echo "❌ Build failed!"
    exit 1
fi

echo "✨ Done!"

