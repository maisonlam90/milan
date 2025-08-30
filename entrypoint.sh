#!/bin/bash

echo "🚀 Starting Milan backend..."
/usr/local/bin/milan &

echo "🌐 Starting Nginx to serve frontend..."
nginx -g 'daemon off;'
