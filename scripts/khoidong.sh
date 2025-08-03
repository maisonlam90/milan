cargo run
cd /home/mailan/axum/src/frontend/demo
yarn dev --host


// lenh migrate cloud yugabyte sql
export DATABASE_URL="postgres://admin:Maisonlan123@ap-southeast-1.e4c6174f-6538-4e47-93bf-0a2503819047.aws.yugabyte.cloud:5433/yugabyte?ssl=true&sslmode=require"
cargo sqlx migrate run

//xoa schema csdl
psql "postgres://admin:Maisonlan123@ap-southeast-1.e4c6174f-6538-4e47-93bf-0a2503819047.aws.yugabyte.cloud:5433/yugabyte?ssl=true&sslmode=require" \
  -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
