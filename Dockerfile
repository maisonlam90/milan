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
COPY ./src/frontend/demo .
RUN yarn install
ARG VITE_BACKEND_URL
ENV VITE_BACKEND_URL=${VITE_BACKEND_URL}
RUN yarn build

# ---------- Final runtime image ----------
FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy backend binary
COPY --from=backend-builder /app/target/release/axum /app/axum

# Copy frontend build vào /app/frontend
COPY --from=frontend-builder /frontend/dist /app/frontend

# Copy config
COPY .env /app/.env
COPY yugabyte.crt /app/yugabyte.crt

ENV PORT=3000
EXPOSE 3000

CMD ["./axum"]
