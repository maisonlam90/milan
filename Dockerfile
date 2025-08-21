# Base layer: build Rust backend
FROM rust:1.82 as backend-builder

WORKDIR /app

# Copy toàn bộ project (tránh cache lại nếu thay đổi)
COPY . .

# Build release binary
RUN cargo build --release

# -----------------------------------------

# Base layer: build frontend
FROM node:20-alpine as frontend-builder

WORKDIR /frontend

COPY ./src/frontend/demo .

RUN yarn install && yarn build

# -----------------------------------------

# Final image chạy BE + serve FE
FROM debian:bullseye-slim

# Install serve + CA
RUN apt-get update && apt-get install -y \
    ca-certificates curl \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g serve \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy backend binary
COPY --from=backend-builder /app/target/release/axum /app/axum

# Copy frontend build
COPY --from=frontend-builder /frontend/dist /app/frontend

# Mặc định chạy cả hai
CMD ./axum & serve -s /app/frontend -l 80
