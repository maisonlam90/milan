# ---------- Backend build layer ----------
    FROM rust:1.82 as backend-builder

    WORKDIR /app
    ARG SQLX_OFFLINE
    ENV SQLX_OFFLINE=${SQLX_OFFLINE}
    
    COPY . .
    RUN cargo build --release
    
    # ---------- Frontend build layer ----------
    FROM node:20-alpine as frontend-builder
    
    WORKDIR /frontend
    COPY ./src/frontend/demo ./
    RUN yarn install
    RUN yarn build
    
    # ---------- Final runtime image ----------
    FROM debian:bookworm-slim
    
    # Cài Nginx + tiện ích
    RUN apt-get update && apt-get install -y nginx curl ca-certificates && \
        rm -rf /var/lib/apt/lists/*
    
    # Xóa cấu hình mặc định
    RUN rm /etc/nginx/sites-enabled/default
    
    # Copy FE build vào Nginx web root
    COPY --from=frontend-builder /frontend/dist /usr/share/nginx/html
    
    # Copy Axum binary
    COPY --from=backend-builder /app/target/release/milan /usr/local/bin/milan
    
    # Copy cert nếu dùng
    COPY yugabyte.crt /app/yugabyte.crt
    
    # Copy Nginx config
    COPY nginx.conf /etc/nginx/sites-enabled/default
    
    # Entrypoint
    COPY entrypoint.sh /app/entrypoint.sh
    RUN chmod +x /usr/local/bin/milan /app/entrypoint.sh
    
    ENTRYPOINT ["/app/entrypoint.sh"]
    