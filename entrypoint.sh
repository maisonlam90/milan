#!/bin/sh
set -e

# Chạy backend (port 3000 hoặc giá trị PORT được truyền vào container)
./axum &

# Chạy frontend (serve static trên port 80)
serve -s /app/frontend -l 80 &

# Giữ container sống, chờ process con
wait
