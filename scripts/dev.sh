#Lenh thuong dung

echo "🚀 Khởi động Axum...."
sudo fuser -k 3000/tcp
cargo run
RUST_LOG=debug cargo run

# Lenh do metadata.rs de do du lieu vao bang available module , va permission
cd backend && cargo run --bin gen_module | psql "postgres://admin:Maisonlan123@ap-southeast-1.e4c6174f-6538-4e47-93bf-0a2503819047.aws.yugabyte.cloud:5433/yugabyte?ssl=true&sslmode=require"

# Chay frontend 
cd /home/milan/milan/frontend/demo
yarn dev --host

# Lenh Database
// lenh migrate cloud yugabyte sql
export DATABASE_URL="postgres://yugabyte:Maisonlan123@192.168.1.21:5433/milan"
cargo sqlx migrate run

//xoa schema csdl
#psql "postgres://admin:Maisonlan123@ap-southeast-1.e4c6174f-6538-4e47-93bf-0a2503819047.aws.yugabyte.cloud:5433/yugabyte?ssl=true&sslmode=require" \
psql "postgres://yugabyte:Maisonlan123@192.168.1.21:5433/postgres" -c "
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE datname='milan';
"
-- Sau đó drop database
psql "postgres://yugabyte:Maisonlan123@192.168.1.21:5433/postgres" -c "DROP DATABASE milan;"

// đổi pass xong tạo pass mới
PGPASSWORD="yugabyte" psql -h 103.82.193.198 -p 5433 -U yugabyte -d yugabyte -c "ALTER USER yugabyte WITH PASSWORD 'Maisonlan123';"
psql "postgres://yugabyte:Maisonlan123@192.168.1.21:5433/postgres" -c "CREATE DATABASE milan;"


// cache lai sqlx
export DATABASE_URL="postgres://yugabyte:Maisonlan123@192.168.1.21:5433/milan"
cargo sqlx prepare --workspace

// backup database
pg_dump "postgres://yugabyte:Maisonlan123@192.168.1.21:5433/milan" \
  -F c \
  -f milan.dump

// backup database
yb-admin --master_addresses 192.168.1.21:7100,192.168.1.22:7100,192.168.1.23:7100 create_database_snapshot ysql.milan 0


// restore database đfdfgdfg gdfg
PGPASSWORD="Maisonlan123" pg_restore -d "postgres://yugabyte:Maisonlan123@192.168.1.21:5433/milan" -v milan.dump
