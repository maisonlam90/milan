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
├── Dockerfile                 # Container configuration (builds both FE & BE)
├── nginx.conf                 # Web server configuration
├── backend.log                # Application logs
├── logs/                      # Log directory
├── scripts/                   # Development scripts
│   ├── dev.sh                 # Development script
│   └── huong dan git.sh       # Git workflow guide
├── k8s/                       # Kubernetes manifests
│   ├── deployment.yaml        # Application deployment
│   ├── service.yaml          # Service definition
│   ├── ingress.yaml          # Ingress configuration
│   ├── hpa.yaml              # Horizontal Pod Autoscaler
│   ├── vpa.yaml              # Vertical Pod Autoscaler
│   ├── pdb.yaml              # Pod Disruption Budget
│   ├── network-policy.yaml   # Network policies
│   └── monitoring.yaml       # Monitoring configuration
│
├── backend/                   # Backend (Rust/Axum)
│   ├── Cargo.toml             # Rust dependencies
│   ├── Cargo.lock             # Dependency lock file
│   ├── rust-toolchain.toml    # Rust toolchain configuration
│   ├── entrypoint.sh          # Application entry script
│   ├── migrations/            # Database migrations
│   ├── tools/                 # Development tools
│   │   └── gen_module.rs      # Module generator
│   ├── target/                # Build artifacts
│   └── src/                   # Backend source code
│       ├── main.rs            # Application entry point
│       ├── config.rs          # Application configuration
│       ├── app.rs             # Axum app builder
│       ├── core/              # Core utilities & shared components
│       │   ├── auth.rs       # Authentication logic
│       │   ├── error.rs      # Global error types
│       │   ├── iam.rs        # Identity & Access Management
│       │   ├── json_with_log.rs # JSON utilities with logging
│       │   ├── log.rs        # Logging utilities
│       │   ├── state.rs      # Application state management
│       │   ├── cache.rs      # Multi-layer cache (L1 Memory + L2 Redis)
│       │   ├── types.rs      # Common types (TenantId, UserId, Money...)
│       │   ├── context.rs    # Request context (tenant_id, user_id...)
│       │   ├── validation.rs # Input validation utilities
│       │   └── mod.rs        # Module exports
│       ├── infra/             # Infrastructure layer
│       │   ├── db.rs         # Database connection & queries
│       │   ├── event_bus.rs  # Event bus abstraction
│       │   ├── telemetry.rs  # Logging, metrics, tracing
│       │   └── mod.rs        # Module exports
│       ├── api/               # API layer
│       │   ├── router.rs     # Main router aggregation
│       │   └── mod.rs        # Module exports
│       ├── tenant_router/     # Multi-tenant routing
│       │   └── mod.rs        # Tenant resolution middleware
│       └── module/            # Domain modules
│           ├── available.rs  # Module discovery & listing
│           ├── app/          # Application management
│           ├── contact/      # Contact management
│           ├── iam/          # Identity & Access Management
│           ├── loan/         # Loan management
│           ├── tenant/       # Tenant management
│           └── user/         # User management
│
└── frontend/                  # Frontend (React/Vite/Tailwind)
    ├── demo/                  # Main frontend application
    │   ├── src/
    │   │   ├── components/   # Reusable components
    │   │   ├── pages/       # Page components
    │   │   ├── services/    # API calls
    │   │   ├── stores/      # State management
    │   │   └── utils/       # Utilities
    │   ├── public/
    │   └── package.json
    ├── demo1/                 # Additional demo apps
    ├── starter/               # Starter template
    └── ts/                    # TypeScript variants
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
cd frontend/demo
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

#### **Implementation: `src/core/cache.rs`**

```rust
// Multi-layer cache service
pub struct CacheService {
    client: Client,                    // Redis client
    l1_cache: Arc<RwLock<HashMap<String, (serde_json::Value, Instant)>>>,
}

impl CacheService {
    // L1 + L2 cache strategy
    pub async fn get<T>(&self, key: &str) -> RedisResult<Option<T>>
    where T: for<'de> Deserialize<'de> + Serialize {
        // 1. Check L1 Cache (Memory) - Nếu có → Return ngay
        // 2. Check L2 Cache (Redis) - Nếu có → Store vào L1 + Return
        // 3. Not found in both L1 and L2
    }
    
    // Store in both L1 and L2
    pub async fn set<T>(&self, key: &str, value: &T, ttl: Duration) -> RedisResult<()>
    where T: Serialize {
        // Store vào L2 (Redis)
        // Store vào L1 (Memory)
    }
}
```

#### **Cache Usage trong Dashboard**
```rust
// src/module/loan/handler/dashboard.rs
pub async fn get_dashboard_stats() -> Json<serde_json::Value> {
    // Check Redis cache trước
    if is_redis_available().await {
        if let Some(redis_client) = get_redis_client().await {
            if let Ok(Some(cached_data)) = redis_client.get_dashboard_stats(&tenant_id.to_string(), month, year).await {
                return Json(cached_data);
            }
        }
    }
    
    // Fallback to in-memory cache
    // ... fetch from database if not cached
}
```

---

## 📦 Dependencies

### Core Dependencies
```toml
# Web Framework
axum = "0.7"
tokio = { version = "1.0", features = ["full"] }

# Database
sqlx = { version = "0.7", features = ["runtime-tokio-rustls", "postgres", "chrono", "uuid", "bigdecimal"] }

# Authentication & Security
jsonwebtoken = "9.3"
bcrypt = "0.15"

# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# Utilities
uuid = { version = "1.0", features = ["v4", "serde"] }
chrono = { version = "0.4", features = ["serde"] }
anyhow = "1.0"
thiserror = "1.0"

# Redis Cache
redis = { version = "0.24", features = ["tokio-comp", "connection-manager"] }

# Logging & Monitoring
tracing = "0.1"
tracing-subscriber = "0.3"
```

### Redis Cache Features
- **`tokio-comp`**: Async Redis client với Tokio runtime
- **`connection-manager`**: Connection pooling cho Redis
- **Multi-layer caching**: L1 (Memory) + L2 (Redis)
- **Fallback strategy**: Redis → Memory → Database

---

## 🏗️ Core Components (Bắt buộc cho hệ thống lớn)

### 📋 **`src/core/types.rs`** - Common Types
```rust
// ✅ Core types cho Milan Finance
pub type TenantId = Uuid;
pub type UserId = Uuid;
pub type Money = struct { amount: i64, currency: Currency };

// ✅ Cache key types
pub enum CacheKey {
    DashboardStats(TenantId, u32, i32),
    LoanStats(TenantId, i32, Option<u32>, Option<String>),
}

// ✅ Cache TTLs
pub const CACHE_TTL_SHORT: u64 = 60;      // 1 minute
pub const CACHE_TTL_MEDIUM: u64 = 300;   // 5 minutes
```

### 🔐 **`src/core/context.rs`** - Request Context & Permissions
```rust
// ✅ User context cho request
pub struct UserContext {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub permissions: Vec<Permission>,
    pub metadata: RequestMetadata,
}

// ✅ Permission system
pub struct Permission {
    pub resource: String,    // "loan", "user", "dashboard"
    pub action: String,      // "read", "create", "update", "delete"
    pub scope: Option<String>, // "created_by = $user_id"
}
```

### ✅ **`src/core/validation.rs`** - Input Validation
```rust
// ✅ Validation utilities
pub struct ValidationError {
    pub field: String,
    pub message: String,
    pub code: String,
}

pub struct BusinessValidator;
impl BusinessValidator {
    pub fn validate_loan_amount(amount: i64, currency: &Currency) -> Result<(), ValidationError>;
    pub fn validate_interest_rate(rate: f64) -> Result<(), ValidationError>;
}
```

### 🗄️ **`src/infra/sharding.rs`** - Multi-Tenant Sharding
```rust
// ✅ Shard management
pub struct ShardManager {
    shards: Vec<ShardConfig>,
    tenant_shard_map: RwLock<HashMap<TenantId, String>>,
}

impl ShardManager {
    pub fn get_shard_for_tenant(&self, tenant_id: &TenantId) -> &ShardConfig;
    pub fn select_shard_for_tenant(&self, tenant_id: &TenantId) -> String;
}
```

### 🏥 **`src/infra/health_check.rs`** - Production Health Checks
```rust
// ✅ Health check endpoints
pub fn health_routes() -> Router<Arc<AppState>> {
    Router::new()
        .route("/health", get(health_check))
        .route("/ready", get(readiness_check))
        .route("/live", get(liveness_check))
}

// ✅ Service health monitoring
pub async fn check_database_health(pool: &PgPool) -> ServiceHealth;
pub async fn check_redis_health() -> ServiceHealth;
```

---

## 🌐 Hệ thống i18n (Đa ngôn ngữ)

### Tổng quan

Milan Finance hỗ trợ đa ngôn ngữ cho backend và frontend, cho phép hệ thống hoạt động với nhiều ngôn ngữ khác nhau.

### Ngôn ngữ được hỗ trợ

- **vi** (Tiếng Việt) - Ngôn ngữ mặc định
- **en** (English) - Ngôn ngữ fallback
- **zh-cn** (中文) - Tiếng Trung
- **es** (Español) - Tiếng Tây Ban Nha
- **ar** (العربية) - Tiếng Ả Rập

### Cấu trúc

```
backend/
├── src/core/i18n.rs              # Core i18n module
├── src/core/i18n_middleware.rs   # Middleware để detect language
├── src/api/i18n.rs               # API endpoints
└── locales/
    ├── vi/translations.json
    ├── en/translations.json
    ├── zh-cn/translations.json
    ├── es/translations.json
    └── ar/translations.json
```

### Sử dụng trong Backend

```rust
use crate::core::i18n::I18n;
use crate::core::error::AppError;

// Tạo I18n từ request headers
let i18n = I18n::from_headers(&headers);

// Sử dụng i18n để tạo error messages
return Err(AppError::not_found_i18n(&i18n, "error.user.not_found"));
```

### API Endpoints

- `GET /i18n/translations?lang=vi` - Lấy translations cho một ngôn ngữ
- `GET /i18n/languages` - Lấy danh sách ngôn ngữ được hỗ trợ

### Language Detection

Hệ thống tự động detect ngôn ngữ từ:
1. Query parameter: `?lang=vi`
2. Header `X-Language`: `X-Language: vi`
3. Header `Accept-Language`: `Accept-Language: vi,en;q=0.9`
4. Default: `vi` (Tiếng Việt)

Xem thêm chi tiết trong [I18N_GUIDE.md](backend/I18N_GUIDE.md)
