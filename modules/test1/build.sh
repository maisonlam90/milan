#!/bin/bash
# Build script for test WASM module

set -e

echo "🏗️  Building test WASM module..."

if ! command -v cargo &> /dev/null; then
    echo "❌ Error: cargo is not installed"
    exit 1
fi

echo "📦 Compiling Rust to WASM..."
cargo build --target wasm32-unknown-unknown --release

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📄 WASM binary: target/wasm32-unknown-unknown/release/test.wasm"
    
    wasm_file="target/wasm32-unknown-unknown/release/test.wasm"
    if [ -f "$wasm_file" ]; then
        size=$(ls -lh "$wasm_file" | awk '{print $5}')
        echo "📊 Binary size: $size"
    fi
else
    echo "❌ Build failed!"
    exit 1
fi

echo "✨ Done!"

