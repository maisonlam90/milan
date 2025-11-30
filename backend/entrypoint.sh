#!/bin/bash

echo "🚀 Starting Milan backend..."
/usr/local/bin/milan &

echo "🌐 Serving frontend with serve on port 80..."
serve -s /app/frontend -l 80
