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
    # CHANGE: bullseye-slim -> bookworm-slim (glibc >= 2.36) để hết lỗi GLIBC_* not found
    FROM debian:bookworm-slim
    
    # Cài đặt các công cụ cần thiết (runtime)
    # CHANGE: chỉ cần ca-certificates + nodejs + npm + serve (FE đã build ở stage trên)
    RUN apt-get update && apt-get install -y \
        ca-certificates nodejs npm curl \
     && npm install -g serve \
     && rm -rf /var/lib/apt/lists/*
    
    WORKDIR /app
    
    # Copy binary backend và frontend build
    COPY --from=backend-builder /app/target/release/axum /app/axum
    COPY --from=frontend-builder /frontend/dist /app/frontend
    
    # (tuỳ chọn) KHÔNG khuyến nghị copy .env vào image prod
    # COPY .env /app/.env
    # COPY yugabyte.crt /app/yugabyte.crt
    
    # CHANGE: đặt PORT mặc định cho BE là 3000 (có thể override khi run)
    ENV PORT=3000
    
    # CHANGE: expose cả 80 (FE) và 3000 (BE)
    EXPOSE 80 3000
    
    # CHANGE: chạy cả backend và frontend; dùng 'wait -n' để container thoát nếu 1 trong 2 process chết
    # - ./axum lắng nghe PORT=3000
    # - serve phục vụ FE build ở cổng 80
    CMD ["sh","-lc","./axum & serve -s /app/frontend -l 80 & wait -n"]
    