#Lenh thuong dung

echo "🚀 Khởi động Axum..."
sudo fuser -k 3000/tcp
cargo run
RUST_LOG=debug cargo run

# Lenh do metadata.rs de do du lieu vao bang available module , va permission
cargo run --bin gen_module | psql "postgres://admin:Maisonlan123@ap-southeast-1.e4c6174f-6538-4e47-93bf-0a2503819047.aws.yugabyte.cloud:5433/yugabyte?ssl=true&sslmode=require"

# Chay frontend 
cd /home/milan/milan/src/frontend/demo
yarn dev --host

# Lenh Database
// lenh migrate cloud yugabyte sql
export DATABASE_URL="postgres://admin:Maisonlan123@ap-southeast-1.e4c6174f-6538-4e47-93bf-0a2503819047.aws.yugabyte.cloud:5433/yugabyte?ssl=true&sslmode=require"
cargo sqlx migrate run

//xoa schema csdl
psql "postgres://admin:Maisonlan123@ap-southeast-1.e4c6174f-6538-4e47-93bf-0a2503819047.aws.yugabyte.cloud:5433/yugabyte?ssl=true&sslmode=require" \
  -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"

// cache lai sqlx
export DATABASE_URL="postgres://admin:Maisonlan123@ap-southeast-1.e4c6174f-6538-4e47-93bf-0a2503819047.aws.yugabyte.cloud:5433/yugabyte?ssl=true&sslmode=require"
cargo sqlx prepare --workspace