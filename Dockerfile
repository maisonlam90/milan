# ---------- Backend build layer ----------
    FROM rust:1.82 as backend-builder

    WORKDIR /app
    
    ARG SQLX_OFFLINE
    ENV SQLX_OFFLINE=${SQLX_OFFLINE}
    
    COPY . .
    RUN cargo build --release && ls -lh /app/target/release/
    
    # ---------- Frontend build layer ----------
    FROM node:20-alpine as frontend-builder
    
    WORKDIR /frontend
    
    COPY ./src/frontend/demo ./
    RUN yarn install
    RUN yarn build
    
    # ---------- Final runtime image ----------
    FROM nginx:alpine
    
    # Copy FE build vào Nginx web root
    COPY --from=frontend-builder /frontend/dist /usr/share/nginx/html
    
    # Copy Axum binary từ build stage (thêm bước debug)
    COPY --from=backend-builder /app/target/release/axum /usr/local/bin/axum
    RUN chmod +x /usr/local/bin/axum && ls -lh /usr/local/bin/axum
    
    # Copy cert nếu dùng Yugabyte Cloud
    COPY yugabyte.crt /app/yugabyte.crt
    
    # Copy Nginx config để proxy /api
    COPY nginx.conf /etc/nginx/conf.d/default.conf
    
    # Copy entrypoint để chạy cả BE và FE
    COPY entrypoint.sh /app/entrypoint.sh
    RUN chmod +x /app/entrypoint.sh
    
    # Khởi động cả 2
    ENTRYPOINT ["/app/entrypoint.sh"]
    