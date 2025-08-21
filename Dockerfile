# Base layer: build Rust backend
FROM rust:1.82 as backend-builder

WORKDIR /app
COPY . .
RUN cargo build --release

# ───────────────────────────────────────────────────────────

# Base layer: build frontend
FROM node:20-alpine as frontend-builder

ARG VITE_BACKEND_URL
ENV VITE_BACKEND_URL=$VITE_BACKEND_URL

WORKDIR /frontend
COPY ./src/frontend/demo .

RUN yarn install
RUN yarn build

# ───────────────────────────────────────────────────────────

# Final image: chạy BE + serve FE
FROM debian:bullseye-slim

# Install serve + CA cert + node
RUN apt-get update && apt-get install -y \
    ca-certificates curl \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g serve \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy backend binary
COPY --from=backend-builder /app/target/release/axum /app/axum

# Copy frontend dist
COPY --from=frontend-builder /frontend/dist /app/frontend

# Cổng FE là 80, BE vẫn là 3000
EXPOSE 80
EXPOSE 3000

# Mặc định chạy cả backend và serve frontend
CMD ./axum & serve -s /app/frontend -l 80
# Copy file evn
COPY .env /app/.env
