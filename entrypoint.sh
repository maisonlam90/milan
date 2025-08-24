#!/bin/sh

echo "🚀 Starting Axum backend..."
/usr/local/bin/axum &

echo "🌐 Starting Nginx to serve frontend..."
nginx -g "daemon off;"
