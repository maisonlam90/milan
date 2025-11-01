# ---------- Backend build layer ----------
FROM rust:1.89 as backend-builder

WORKDIR /app
ARG SQLX_OFFLINE
ENV SQLX_OFFLINE=${SQLX_OFFLINE}

COPY backend/ .
RUN cargo build --release


# ---------- Frontend build layer ----------
FROM node:20-alpine as frontend-builder

WORKDIR /frontend
COPY frontend/demo/ ./
RUN yarn install
RUN yarn build


# ---------- Final runtime image ----------
FROM debian:bookworm-slim

# Cài tiện ích + Node.js (để serve FE)
RUN apt-get update && \
    apt-get install -y curl ca-certificates && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g serve && \
    rm -rf /var/lib/apt/lists/*

# Copy FE build
COPY --from=frontend-builder /frontend/dist /app/frontend

# Copy backend binary
COPY --from=backend-builder /app/target/release/milan /usr/local/bin/milan

# Copy cert nếu dùng
COPY yugabyte.crt /app/yugabyte.crt 2>/dev/null || true

# Entrypoint
COPY backend/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /usr/local/bin/milan /app/entrypoint.sh

EXPOSE 80 3000
ENTRYPOINT ["/app/entrypoint.sh"]