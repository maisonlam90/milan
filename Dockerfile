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
    
    # Cài Nginx và tiện ích cần thiết
    RUN apt-get update && apt-get install -y \
        nginx curl ca-certificates && \
        apt-get clean && rm -rf /var/lib/apt/lists/*
    
    # FE: Copy build vào Nginx web root
    COPY --from=frontend-builder /frontend/dist /usr/share/nginx/html
    
    # BE: Copy binary đã build
    COPY --from=backend-builder /app/target/release/axum /usr/local/bin/axum
    RUN chmod +x /usr/local/bin/axum
    
    # Cert Yugabyte nếu cần
    COPY yugabyte.crt /app/yugabyte.crt
    
    # Nginx config (proxy /api → BE)
    COPY nginx.conf /etc/nginx/conf.d/default.conf
    
    # Entrypoint để khởi động cả FE + BE
    COPY entrypoint.sh /app/entrypoint.sh
    RUN chmod +x /app/entrypoint.sh
    
    ENTRYPOINT ["/app/entrypoint.sh"]
    