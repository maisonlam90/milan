#!/bin/bash

echo "🚀 Starting Axum backend..."
/usr/local/bin/milan &

echo "🌐 Starting Nginx to serve frontend..."
nginx -g 'daemon off;'
