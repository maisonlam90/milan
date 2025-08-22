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
    # CHANGE: bullseye-slim (glibc 2.31) → bookworm-slim (glibc >= 2.36) để hết lỗi GLIBC
    FROM debian:bookworm-slim
    
    # Cài đặt các công cụ cần thiết
    # CHANGE: cài ca-certificates + curl + nodejs + serve trên bookworm
    RUN apt-get update && apt-get install -y \
        ca-certificates curl gnupg \
     && mkdir -p /etc/apt/keyrings \
     && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
     && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
     && apt-get update && apt-get install -y nodejs \
     && npm install -g serve \
     && rm -rf /var/lib/apt/lists/*
    
    WORKDIR /app
    
    # Copy binary backend và frontend build
    COPY --from=backend-builder /app/target/release/axum /app/axum
    COPY --from=frontend-builder /frontend/dist /app/frontend
    
    # Copy file cấu hình nếu có (tuỳ chọn)
    # (GỢI Ý: tránh COPY .env vào image prod; dùng -e / secrets tốt hơn)
    # COPY .env /app/.env
    # COPY yugabyte.crt /app/yugabyte.crt
    
    # CHANGE: đặt PORT mặc định cho BE là 3000 (có thể override khi run)
    ENV PORT=3000
    
    # CHANGE: expose cả 80 (FE) và 3000 (BE)
    EXPOSE 80 3000
    
    # CHANGE: chạy cả backend và frontend; dùng 'wait -n' để container exit nếu 1 trong 2 process chết
    # - ./axum sẽ nghe ở PORT=3000
    # - serve sẽ phục vụ FE build ở cổng 80
    CMD ["sh","-lc","./axum & serve -s /app/frontend -l 80 & wait -n"]
    