#!/bin/sh
set -e

echo "🚀 Starting Axum backend..."
/usr/local/bin/axum &
AXUM_PID=$!

echo "🌐 Starting Nginx to serve frontend..."
nginx -g 'daemon off;' &

# Đợi Axum kết thúc, nếu có lỗi thì container cũng exit
wait $AXUM_PID
