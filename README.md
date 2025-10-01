# Milan ERP - System Documentation

## 📋 Tổng quan dự án

**Milan ERP** là hệ thống quản lý doanh nghiệp (ERP) đa thuê bao (multi-tenant) được xây dựng trên kiến trúc sharding tuyến tính, tối ưu cho SaaS platform quy mô lớn.

### Thông tin cơ bản
- **Ngôn ngữ backend**: Rust
- **Framework**: Axum
- **Database**: YugabyteDB (PostgreSQL-compatible, distributed)
- **Event Bus**: Kafka / NATS
- **Pattern**: CQRS + Event-Driven Architecture
- **Frontend**: React + Vite + Tailwind (Tailux theme)
- **Deployment**: Kubernetes + GitHub Actions

---

## 🏗️ Kiến trúc hệ thống

### Nguyên tắc thiết kế cốt lõi

1. **Sharding tuyến tính**: Mỗi tenant được định tuyến tới một shard cụ thể
2. **Module hóa**: Các module độc lập như Odoo apps
3. **CQRS**: Tách biệt Command (ghi) và Query (đọc)
4. **Event-Driven**: Giao tiếp giữa module qua domain events
5. **IAM hiện đại**: RBAC + ABAC với scope expressions

### Cấu trúc thư mục chuẩn

```
src/
├── main.rs                    # Entry point
├── config.rs                  # Cấu hình (env, shard rules)
├── app.rs                     # Axum app builder

├── core/                      # Shared utilities
│   ├── context.rs             # Request context (tenant_id, user_id)
│   ├── error.rs               # Global error types
│   ├── time.rs                # Time utilities
│   └── types.rs               # Common types (TenantId, UserId, Money...)

├── infra/                     # Infrastructure layer
│   ├── db.rs                  # Connection pool, query helpers
│   ├── sharding.rs            # Tenant → Shard mapping
│   ├── event_bus.rs           # Event bus abstraction
│   ├── redis.rs               # Redis client (optional)
│   └── telemetry.rs           # Logging, metrics, tracing

├── api/
│   ├── mod.rs
│   └── router.rs              # Main router aggregation

├── tenant_router/             # Tenant resolution middleware
│   ├── resolver.rs            # Extract tenant_id from token/header
│   └── router.rs              # Inject tenant_id into state

├── command_bus/               # CQRS Command dispatcher
│   ├── mod.rs
│   └── dispatcher.rs

├── query_bus/                 # CQRS Query dispatcher
│   ├── mod.rs
│   └── dispatcher.rs

├── event_handler/             # Event consumers
│   ├── mod.rs
│   └── user_handler.rs        # Example: handle UserCreated

└── module/                    # Domain modules
    ├── available.rs           # Module discovery & listing
    ├── user/
    ├── acl/
    ├── loan/
    ├── tenant/
    └── payment/
```

---

## 📦 Cấu trúc Module chuẩn

Mỗi module là một domain độc lập, tự quản lý logic nghiệp vụ của mình.

### Template cấu trúc

```
module/
└── {module_name}/
    ├── mod.rs              # Module registration
    ├── router.rs           # Axum routes
    ├── handler.rs          # HTTP handlers
    ├── command.rs          # Write operations (CQRS)
    ├── query.rs            # Read operations (CQRS)
    ├── model.rs            # Database models
    ├── dto.rs              # Data Transfer Objects
    ├── event.rs            # Domain events
    ├── metadata.rs         # UI form schema
    ├── calculator.rs       # Business logic calculations
    └── data.sql            # Schema definitions
```

### Quy tắc phát triển Module

#### ✅ Bắt buộc

- Mọi bảng chính PHẢI có `tenant_id` trong PRIMARY KEY
- Handler PHẢI trích xuất `tenant_id` từ context
- Không được JOIN cross-tenant
- Event phải được publish qua event_bus
- Phân quyền phải được kiểm tra qua IAM module

#### ❌ Cấm

- Hard-code logic phân quyền trong handler
- Dùng global counter/lookup table
- JOIN giữa các tenant khác nhau
- Bỏ qua tenant_id trong query

### Ví dụ: Module User

```rust
// module/user/handler.rs
use axum::{extract::State, Json};
use crate::core::context::UserContext;

pub async fn create_user(
    ctx: UserContext,
    State(db): State<DbPool>,
    Json(input): Json<CreateUserDto>,
) -> Result<Json<UserDto>, AppError> {
    // 1. Validate permissions
    check_permission(&ctx, "user", "create")?;
    
    // 2. Execute command
    let command = CreateUserCommand {
        tenant_id: ctx.tenant_id,
        data: input,
    };
    
    let user = command_bus::dispatch(command, &db).await?;
    
    // 3. Publish event
    event_bus::publish(UserCreatedEvent {
        tenant_id: ctx.tenant_id,
        user_id: user.id,
        timestamp: Utc::now(),
    }).await?;
    
    Ok(Json(user.into_dto()))
}
```

---

## 🔐 Hệ thống phân quyền IAM

### Mô hình RBAC + ABAC

```sql
-- Quyền cơ bản
CREATE TABLE permissions (
    id UUID PRIMARY KEY,
    resource VARCHAR(50),  -- 'invoice', 'user', 'loan'
    action VARCHAR(50)     -- 'read', 'create', 'update', 'delete'
);

-- Vai trò + Scope expressions
CREATE TABLE role_permissions (
    role_id UUID,
    permission_id UUID,
    scope_expr TEXT,  -- "created_by = $user_id" | "department_id = $user.dept"
    PRIMARY KEY (role_id, permission_id)
);

-- Gán vai trò cho user
CREATE TABLE user_roles (
    tenant_id UUID,
    user_id UUID,
    role_id UUID,
    PRIMARY KEY (tenant_id, user_id, role_id)
);

-- Module được kích hoạt theo tenant
CREATE TABLE tenant_modules (
    tenant_id UUID,
    module_name VARCHAR(50),
    enabled BOOLEAN,
    PRIMARY KEY (tenant_id, module_name)
);
```

### Scope Expression Examples

| Vai trò | Quyền | Scope Expression |
|---------|-------|------------------|
| employee | invoice:read | `created_by = $user_id` |
| manager | invoice:read | `department_id = $user.department_id` |
| admin | invoice:read | `true` (hoặc NULL - full access) |

### Cột bắt buộc cho bảng chính

Để hỗ trợ phân quyền linh hoạt:

| Cột | Kiểu | Mục đích |
|-----|------|----------|
| `created_by` | UUID | Người tạo bản ghi |
| `assignee_id` | UUID | Người được gán xử lý |
| `shared_with` | UUID[] | Danh sách user được chia sẻ |

### Ví dụ kiểm tra quyền

```rust
async fn get_invoice(
    ctx: UserContext,
    State(perms): State<UserPermissions>,
    Path(id): Path<Uuid>,
) -> Result<Json<InvoiceDto>, AppError> {
    let invoice = db::load_invoice(ctx.tenant_id, id).await?;
    
    if !check_permission(
        &ctx, 
        "invoice", 
        "read", 
        invoice.to_record_view(), 
        &perms
    ) {
        return Err(AppError::Forbidden);
    }
    
    Ok(Json(invoice.into_dto()))
}
```

---

## 🗄️ Database Sharding

### Nguyên tắc Sharding

1. **Tenant-based sharding**: Mỗi tenant thuộc về 1 shard cố định
2. **Consistent hashing**: Dùng `tenant_id` để map tới shard
3. **No cross-shard queries**: Tuyệt đối không JOIN cross-shard

### Cấu hình Shard

```rust
// infra/sharding.rs
pub struct ShardConfig {
    pub shard_id: u32,
    pub connection_string: String,
    pub tenant_range: (u64, u64), // Hash range
}

pub fn resolve_shard(tenant_id: Uuid) -> ShardId {
    let hash = hash_tenant_id(tenant_id);
    SHARD_MAP.get_shard_by_hash(hash)
}
```

### Schema Migration

```sql
-- Bảng tenant (global, không shard)
CREATE TABLE tenants (
    id UUID PRIMARY KEY,
    name VARCHAR(255),
    shard_id INTEGER,
    created_at TIMESTAMPTZ
);

-- Bảng business (sharded)
CREATE TABLE users (
    tenant_id UUID,
    id UUID,
    email VARCHAR(255),
    created_by UUID,
    PRIMARY KEY (tenant_id, id)
);

-- Index bắt buộc có tenant_id
CREATE INDEX idx_users_email ON users(tenant_id, email);
```

---

## 📡 Event-Driven Communication

### Quy tắc Event

1. **Immutable**: Event không được sửa sau khi publish
2. **Past tense**: Đặt tên sự kiện ở quá khứ (UserCreated, InvoicePaid)
3. **Domain events only**: Chỉ publish domain events, không publish technical events

### Ví dụ Event

```rust
// module/user/event.rs
#[derive(Serialize, Deserialize)]
pub struct UserCreatedEvent {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub email: String,
    pub timestamp: DateTime<Utc>,
}

// Publish event
event_bus::publish(UserCreatedEvent {
    tenant_id: ctx.tenant_id,
    user_id: user.id,
    email: user.email.clone(),
    timestamp: Utc::now(),
}).await?;
```

### Event Handler

```rust
// event_handler/user_handler.rs
pub async fn handle_user_created(event: UserCreatedEvent) -> Result<()> {
    // Ví dụ: Tạo profile mặc định
    let profile = UserProfile {
        tenant_id: event.tenant_id,
        user_id: event.user_id,
        display_name: event.email.clone(),
    };
    
    db::insert_profile(profile).await?;
    Ok(())
}
```

---

## 🎨 Frontend (Tailux)

### Cài đặt

```bash
cd axum/src/frontend/demo
yarn install
yarn dev --host
```

### Cấu trúc thư mục

```
frontend/
├── src/
│   ├── components/       # Reusable components
│   ├── pages/           # Page components
│   ├── services/        # API calls
│   ├── stores/          # State management
│   └── utils/           # Utilities
├── public/
└── package.json
```

### API Integration

```typescript
// services/api.ts
import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
  headers: {
    'X-Tenant-ID': getTenantId(),
  }
});

export const UserService = {
  async getUsers() {
    const { data } = await api.get('/api/users');
    return data;
  },
  
  async createUser(input: CreateUserInput) {
    const { data } = await api.post('/api/users', input);
    return data;
  }
};
```

---

## 🚀 Deployment

### GitHub Actions CI/CD

```yaml
# .github/workflows/ci.yml
name: CI/CD

on:
  push:
    branches: [main, develop]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions-rs/toolchain@v1
      - run: cargo build --release
      - run: cargo test
      
  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - run: kubectl apply -f k8s/
```

### Kubernetes Deployment

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: milan-erp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: milan-erp
  template:
    spec:
      containers:
      - name: milan-erp
        image: milan-erp:latest
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: url
```

---

## 📝 Quy tắc đặt tên & Code Convention

### Rust Code Style

```rust
// ✅ Good
pub struct UserCommand {
    tenant_id: Uuid,
    email: String,
}

impl UserCommand {
    pub async fn execute(&self, db: &DbPool) -> Result<User> {
        // Implementation
    }
}

// ❌ Bad
pub struct userCommand {  // PascalCase cho struct
    TenantID: Uuid,      // snake_case cho field
}
```

### SQL Naming

```sql
-- ✅ Good
CREATE TABLE user_profiles (
    tenant_id UUID,
    user_id UUID,
    display_name VARCHAR(255)
);

-- ❌ Bad
CREATE TABLE UserProfiles (  -- lowercase với underscore
    TenantID UUID,          -- lowercase
    UserID UUID
);
```

### API Endpoints

```
GET    /api/users              # List users
POST   /api/users              # Create user
GET    /api/users/:id          # Get user
PUT    /api/users/:id          # Update user
DELETE /api/users/:id          # Delete user
```

---

## 🧪 Testing

### Unit Test

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_create_user() {
        let db = setup_test_db().await;
        let tenant_id = Uuid::new_v4();
        
        let cmd = CreateUserCommand {
            tenant_id,
            email: "test@example.com".to_string(),
        };
        
        let result = cmd.execute(&db).await;
        assert!(result.is_ok());
    }
}
```

### Integration Test

```rust
#[tokio::test]
async fn test_user_api_flow() {
    let app = create_test_app().await;
    
    let response = app
        .post("/api/users")
        .json(&json!({
            "email": "test@example.com"
        }))
        .header("X-Tenant-ID", tenant_id.to_string())
        .send()
        .await;
    
    assert_eq!(response.status(), 201);
}
```

---

## 📚 Tài liệu tham khảo

### Kiến thức cần thiết

- [Axum Documentation](https://docs.rs/axum/)
- [YugabyteDB Docs](https://docs.yugabyte.com/)
- [CQRS Pattern](https://martinfowler.com/bliki/CQRS.html)
- [Sharding Strategies](https://www.mongodb.com/features/database-sharding)

### Best Practices

1. **Luôn validate tenant_id**: Không tin tưởng client input
2. **Cache permissions**: Không query IAM cho mỗi request
3. **Async everywhere**: Tận dụng Tokio async runtime
4. **Error handling**: Dùng Result<T, E> và propagate errors
5. **Logging**: Log mọi operation quan trọng với tenant_id

---

## 🆘 Troubleshooting

### Lỗi thường gặp

**1. Cross-tenant query detected**
```
Solution: Đảm bảo WHERE clause luôn có tenant_id
```

**2. Permission denied**
```
Solution: Kiểm tra user_roles và role_permissions
```

**3. Shard connection failed**
```
Solution: Verify shard_id mapping và connection string
```

### Debug Commands

```bash
# Check shard routing
cargo run -- --debug-shard <tenant_id>

# Verify permissions
cargo run -- --check-permission <user_id> <resource> <action>

# Test event publishing
cargo run -- --publish-test-event
```

---

## 📞 Liên hệ & Support

- **Team Lead**: [Tên người phụ trách]
- **Slack Channel**: #milan-erp-dev
- **Issue Tracker**: GitHub Issues
- **Documentation**: Confluence/Notion

---

**Version**: 1.0.0  
**Last Updated**: 01/10/2025  
**Maintained by**: Milan Development Team