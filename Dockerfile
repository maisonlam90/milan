# Build stage
FROM rust:1.82 as builder
WORKDIR /app
COPY . .
RUN apt-get update && apt-get install -y libpq-dev
RUN cargo build --release

# Runtime stage
FROM debian:bullseye-slim
WORKDIR /app
RUN apt-get update && apt-get install -y libpq5 ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/axum /app/axum
EXPOSE 8080
ENTRYPOINT ["./axum"]
