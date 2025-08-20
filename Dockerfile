#!/bin/bash
set -e

IMAGE="ghcr.io/maisonlam90/axum:latest"
CONTAINER_NAME="axum"

echo "🚀 Login GHCR..."
echo "${GHCR_PAT}" | docker login ghcr.io -u maisonlam90 --password-stdin

echo "📥 Pull image mới..."
docker pull $IMAGE

echo "♻️ Restart container..."
docker stop $CONTAINER_NAME || true
docker rm $CONTAINER_NAME || true

docker run -d \
  --name $CONTAINER_NAME \
  -p 8000:8000 \     # Rust API
  -p 80:80 \         # Frontend static
  -v /etc/localtime:/etc/localtime:ro \
  $IMAGE
