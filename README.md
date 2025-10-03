# Milan Finance - Core Financial Platform

## 📋 Tổng quan dự án

**Milan Finance** được thiết kế để trở thành **nền tảng lõi cho các hệ thống tài chính có hiệu năng cao**, có khả năng mở rộng tuyến tính theo chiều ngang. Đây là một hệ thống đa thuê bao (multi-tenant) **thế hệ mới**, được xây dựng trên nền tảng kiến trúc **sharding tuyến tính (linear sharding)** tiên tiến, tối ưu hóa cho các nền tảng SaaS quy mô lớn và yêu cầu hiệu suất cực đại.

Với kiến trúc **CQRS (Command Query Responsibility Segregation) và Event-Driven** mạnh mẽ, Milan Finance đảm bảo khả năng mở rộng vượt trội, tính nhất quán dữ liệu và khả năng phục hồi cao. Backend được phát triển bằng **Rust**, mang lại hiệu suất cực đại, an toàn bộ nhớ và độ tin cậy tuyệt đối. Dữ liệu được quản lý bởi **YugabyteDB**, một cơ sở dữ liệu phân tán tương thích PostgreSQL, đảm bảo khả năng chịu lỗi và mở rộng ngang (horizontal scalability) không giới hạn.

Frontend của Milan Finance sử dụng **React và Tailwind CSS**, cung cấp trải nghiệm người dùng hiện đại, linh hoạt và dễ tùy biến. Toàn bộ hệ thống được triển khai trên **Kubernetes** với các pattern enterprise-grade như **Service Mesh (Istio)**, **API Gateway (Kong)**, **Observability Stack (Prometheus, Grafana, Jaeger)** và **ELK Stack**, đảm bảo vận hành ổn định, an toàn và dễ dàng quản lý ở mọi quy mô.

### 🎯 **Ứng dụng đa dạng**

Milan Finance được thiết kế để xây dựng các hệ thống:

- **🏢 ERP mạnh mẽ** - Hệ thống quản lý doanh nghiệp toàn diện
- **💱 Sàn giao dịch** - Trading platforms với hiệu suất cao
- **🏦 Core Banking** - Hệ thống ngân hàng lõi
- **🌐 Server IoT** - Internet of Things infrastructure
- **⛓️ Sàn Blockchain** - Blockchain trading platforms
- **📱 Server ứng dụng di động** - Mobile app backends
- **📊 Phần mềm quản lý** - Management software solutions

**Milan Finance không chỉ là một nền tảng tài chính thông thường, mà còn là một giải pháp công nghệ đột phá, sẵn sàng đáp ứng mọi thách thức của hệ thống tài chính hiện đại.**

### 🚀 Thông tin kỹ thuật
- **Backend**: Rust + Axum (hiệu suất cực đại, an toàn bộ nhớ)
- **Database**: YugabyteDB (distributed SQL, horizontal scaling)
- **Event System**: Kafka / NATS (event-driven architecture)
- **Architecture**: CQRS + Event Sourcing + Multi-tenant Sharding
- **Frontend**: React + Vite + Tailwind CSS (modern UI/UX)
- **Infrastructure**: Kubernetes + Istio + Kong + Observability Stack
- **Deployment**: GitOps + CI/CD + Blue-Green Deployment
- **Target Markets**: ERP, Trading, Banking, IoT, Blockchain, Mobile, Management

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
milan/
├── README.md                  # Project documentation
├── Cargo.toml                 # Rust dependencies
├── Cargo.lock                 # Dependency lock file
├── rust-toolchain.toml        # Rust toolchain configuration
├── Dockerfile                 # Container configuration
├── entrypoint.sh              # Application entry script
├── nginx.conf                 # Web server configuration
├── backend.log                # Application logs
├── logs/                      # Log directory
├── migrations/                # Database migrations
├── scripts/                   # Development scripts
│   ├── dev.sh                 # Development script
│   └── huong dan git.sh       # Git workflow guide
├── tools/                     # Development tools
│   └── gen_module.rs          # Module generator
├── target/                    # Build artifacts
├── k8s/                       # Kubernetes manifests
│   ├── deployment.yaml        # Application deployment
│   ├── service.yaml          # Service definition
│   ├── ingress.yaml          # Ingress configuration
│   ├── hpa.yaml              # Horizontal Pod Autoscaler
│   ├── vpa.yaml              # Vertical Pod Autoscaler
│   ├── pdb.yaml              # Pod Disruption Budget
│   ├── network-policy.yaml   # Network policies
│   └── monitoring.yaml       # Monitoring configuration
└── src/                       # Source code
    ├── main.rs                # Application entry point
    ├── config.rs              # Application configuration
    ├── app.rs                 # Axum app builder
    ├── core/                  # Core utilities & shared components
    │   ├── auth.rs           # Authentication logic
    │   ├── error.rs          # Global error types
    │   ├── iam.rs            # Identity & Access Management
    │   ├── json_with_log.rs  # JSON utilities with logging
    │   ├── log.rs            # Logging utilities
    │   ├── state.rs          # Application state management
    │   ├── mod.rs            # Module exports
    │   │
    │   # TODO: Cần bổ sung cho Milan Finance
    │   ├── types.rs          # Common types (TenantId, UserId, Money, Currency...)
    │   ├── context.rs        # Request context (tenant_id, user_id, permissions)
    │   ├── cache_types.rs    # Cache key types, TTL constants
    │   ├── cache_serialization.rs # Cache serialization/deserialization
    │   └── validation.rs     # Input validation utilities
    │
    ├── infra/                 # Infrastructure layer
    │   ├── db.rs             # Database connection & queries
    │   ├── event_bus.rs      # Event bus abstraction
    │   ├── telemetry.rs      # Logging, metrics, tracing
    │   ├── mod.rs            # Module exports
    │   │
    │   # TODO: Cần bổ sung cho Milan Finance
    │   ├── sharding.rs       # Tenant → Shard mapping
    │   ├── redis.rs          # Redis client & caching
    │   ├── cache_manager.rs # Multi-layer cache management
    │   ├── cache_strategy.rs # Cache invalidation strategy
    │   ├── connection_pool.rs # Database connection pooling
    │   └── health_check.rs   # Health check endpoints
    │
    ├── api/                   # API layer
    │   ├── router.rs         # Main router aggregation
    │   ├── mod.rs            # Module exports
    │   │
    │
    ├── tenant_router/         # Multi-tenant routing
    │   └── mod.rs            # Tenant resolution middleware
    │
    └── module/                # Domain modules
        ├── available.rs      # Module discovery & listing
        ├── app/              # Application management
        ├── contact/          # Contact management
        ├── iam/              # Identity & Access Management
        ├── loan/             # Loan management
        ├── tenant/           # Tenant management
        ├── user/             # User management
        │
        # TODO: Cần bổ sung modules cho Milan Finance
        ├── payment/          # Payment processing
        ├── banking/          # Banking operations
        └── analytics/        # Analytics & reporting
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

## 🚀 Kubernetes Architecture (Enterprise-Grade)

### 🏗️ Kiến trúc K8s Monolithic Advanced

Milan Finance sử dụng **Monolithic + Kubernetes** với các pattern enterprise-grade để đạt hiệu suất và độ tin cậy cao nhất.

```
┌─────────────────────────────────────────────────────────┐
│                    K8s Cluster                        │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   Istio     │  │    Kong     │  │  Prometheus │    │
│  │  Service    │  │   API       │  │  + Grafana  │    │
│  │   Mesh      │  │  Gateway    │  │  + Jaeger   │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐ │
│  │            Milan Finance (Monolith)               │ │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐  │ │
│  │  │  User   │ │  Loan   │ │ Contact │ │   IAM   │  │ │
│  │  │ Module  │ │ Module  │ │ Module  │ │ Module  │  │ │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘  │ │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐  │ │
│  │  │Payment  │ │Banking  │ │Analytics│ │   App   │  │ │
│  │  │ Module  │ │ Module  │ │ Module  │ │ Module  │  │ │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘  │ │
│  │  ┌─────────────────────────────────────────────────┐ │ │
│  │  │              L1 Cache (Memory)                │ │ │
│  │  │  Hot Data | Session Data | Frequently Used    │ │ │
│  │  └─────────────────────────────────────────────────┘ │ │
│  └─────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │
│  │   Redis     │  │   Kafka     │  │ YugabyteDB  │    │
│  │  Cluster    │  │   Stream    │  │  Cluster    │    │
│  │ (L2 Cache)  │  │ (Events)    │  │ (Database)  │    │
│  │  Shared     │  │             │  │             │    │
│  │  Persistent │  │             │  │             │    │
│  └─────────────┘  └─────────────┘  └─────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### 🔄 Multi-Layer Cache Architecture

Milan Finance sử dụng **kiến trúc cache 2 tầng** để đạt hiệu năng cực đại:

#### **L1 Cache (In-Memory)**
- **Vị trí**: Trong BE container (Memory)
- **Tốc độ**: Cực nhanh (RAM access)
- **Dung lượng**: Giới hạn (vài GB)
- **Scope**: Chỉ trong 1 pod
- **Dữ liệu**: Hot data, session data, frequently used

#### **L2 Cache (Redis External)**
- **Vị trí**: Redis Cluster riêng biệt
- **Tốc độ**: Nhanh (Network access)
- **Dung lượng**: Lớn (hàng TB)
- **Scope**: Tất cả pods
- **Dữ liệu**: Shared data, persistent cache

#### **Cache Flow**
```
Request → L1 Cache (Memory) → L2 Cache (Redis) → Database
    ↓           ↓                    ↓              ↓
   Fast      Faster              Fast           Slow
```

#### **Cache Hit Strategy**
1. **Check L1** (Memory) - Nếu có → Return ngay
2. **Check L2** (Redis) - Nếu có → Store vào L1 + Return  
3. **Check DB** - Nếu có → Store vào L2 + L1 + Return

#### **Cache Invalidation**
- **L1**: Automatic expiration, LRU eviction
- **L2**: TTL-based, tenant-specific invalidation
- **Cross-pod**: Redis pub/sub for cache invalidation
---