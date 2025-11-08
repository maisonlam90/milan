#Lenh thuong dung

echo "🚀 Khởi động Axum...."
sudo fuser -k 3000/tcp
cd backend && cargo run
cd backend && RUST_LOG=debug cargo run

# Lenh do metadata.rs de do du lieu vao bang available module , va permission
cd backend && cargo run --bin gen_module | psql "postgres://admin:Maisonlan123@ap-southeast-1.e4c6174f-6538-4e47-93bf-0a2503819047.aws.yugabyte.cloud:5433/yugabyte?ssl=true&sslmode=require"

# Chay frontend 
cd /home/milan/milan/frontend/demo
yarn dev --host

# Lenh Database
// lenh migrate cloud yugabyte sql
export DATABASE_URL="postgres://yugabyte:Maisonlan123@192.168.1.4:5433/milan"
cargo sqlx migrate run

//xoa schema csdl
#psql "postgres://admin:Maisonlan123@ap-southeast-1.e4c6174f-6538-4e47-93bf-0a2503819047.aws.yugabyte.cloud:5433/yugabyte?ssl=true&sslmode=require" \
psql "postgres://yugabyte:Maisonlan123@192.168.1.4:5433/milan" \
  -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

// cache lai sqlx
export DATABASE_URL="postgres://yugabyte:Maisonlan123@192.168.1.4:5433/milan"
cargo sqlx prepare --workspace

// backup database
pg_dump "postgres://admin:Maisonlan123@ap-southeast-1.e4c6174f-6538-4e47-93bf-0a2503819047.aws.yugabyte.cloud:5433/yugabyte?ssl=true&sslmode=require" \
  -F c \
  -f yugabyte_backup_$(date +%F).dump