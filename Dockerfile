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

# Cài tiện ích cần thiết (bỏ Nginx)
RUN apt-get update && apt-get install -y curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy FE build → dùng serve để chạy
RUN apt-get install -y nodejs npm && npm install -g serve
COPY --from=frontend-builder /frontend/dist /app/frontend

# Copy backend binary
COPY --from=backend-builder /app/target/release/milan /usr/local/bin/milan

# Copy cert nếu dùng
COPY yugabyte.crt /app/yugabyte.crt

# Entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /usr/local/bin/milan /app/entrypoint.sh

EXPOSE 80 3000
ENTRYPOINT ["/app/entrypoint.sh"]
