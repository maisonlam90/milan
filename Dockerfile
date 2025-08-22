# ---------- Backend build layer ----------
    FROM rust:1.82 as backend-builder

    WORKDIR /app
    
    # Copy project và bật SQLX_OFFLINE nếu có
    ARG SQLX_OFFLINE
    ENV SQLX_OFFLINE=${SQLX_OFFLINE}
    
    COPY . .
    
    RUN cargo build --release
    
    # ---------- Frontend build layer ----------
    FROM node:20-alpine as frontend-builder
    
    WORKDIR /frontend
    
    COPY ./src/frontend/demo .
    
    RUN yarn install
    ARG VITE_BACKEND_URL
    ENV VITE_BACKEND_URL=${VITE_BACKEND_URL}
    RUN yarn build
    
    # ---------- Final runtime image ----------
    FROM debian:bookworm-slim
    
    # Cài đặt các công cụ cần thiết
    RUN apt-get update && apt-get install -y \
        ca-certificates curl \
        && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
        && apt-get install -y nodejs \
        && npm install -g serve \
        && apt-get clean && rm -rf /var/lib/apt/lists/*
    
    WORKDIR /app
    
    # Copy binary backend và frontend build
    COPY --from=backend-builder /app/target/release/axum /app/axum
    COPY --from=frontend-builder /frontend/dist /app/frontend
    
    # Copy file cấu hình nếu có
    COPY .env /app/.env
    COPY yugabyte.crt /app/yugabyte.crt
    
    # Copy entrypoint script (quản lý cả BE + FE)
    COPY entrypoint.sh /app/entrypoint.sh
    RUN chmod +x /app/entrypoint.sh
    
    ENTRYPOINT ["/app/entrypoint.sh"]
    