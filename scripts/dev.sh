#!/bin/bash

set -e

echo "🔄 Loading .env file..."
source .env

echo "🧱 Đảm bảo YugabyteDB đang chạy..."
~/yugabyte-2.25.1.0/bin/yb-ctl start


echo "🛠 Chạy migrate..."
sqlx migrate run


echo "🚀 Khởi động Axum..."
sudo fuser -k 3000/tcp
cargo run
