#!/bin/bash

# Build script for sale WASM module

set -e

echo "Building sale WASM module..."

# Clean previous builds
cargo clean

# Build for wasm32-unknown-unknown target (no WASI needed for simple functions)
cargo build --target wasm32-unknown-unknown --release

# Create target directory if it doesn't exist
mkdir -p target/wasm32-unknown-unknown/release

# Copy the wasm file to a standard location
if [ -f "target/wasm32-unknown-unknown/release/sale.wasm" ]; then
    echo "✓ Build successful!"
    echo "WASM binary: target/wasm32-unknown-unknown/release/sale.wasm"
    
    # Get file size
    SIZE=$(ls -lh target/wasm32-unknown-unknown/release/sale.wasm | awk '{print $5}')
    echo "Size: $SIZE"
else
    echo "✗ Build failed - WASM binary not found"
    exit 1
fi

# Optional: Optimize with wasm-opt if available
if command -v wasm-opt &> /dev/null; then
    echo "Optimizing with wasm-opt..."
    wasm-opt -Oz target/wasm32-unknown-unknown/release/sale.wasm -o target/wasm32-unknown-unknown/release/sale.opt.wasm
    mv target/wasm32-unknown-unknown/release/sale.opt.wasm target/wasm32-unknown-unknown/release/sale.wasm
    SIZE=$(ls -lh target/wasm32-unknown-unknown/release/sale.wasm | awk '{print $5}')
    echo "Optimized size: $SIZE"
fi

echo "Done!"

