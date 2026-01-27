# 生产环境数据库配置说明

## 问题背景

为了实现多会话数据隔离，系统使用 PostgreSQL Row Level Security (RLS) 策略。RLS 策略要求应用程序使用**非超级用户**连接数据库。

## 重要变更

### ✅ 已自动化处理

在生产环境部署时，`bin/docker-entrypoint` 会自动：

1. **创建 `app_user` 角色**（如果不存在）
2. **授予所有必要权限**
3. **设置相同密码**（与主数据库用户相同）

### ⚠️ 需要手动配置

修改生产环境的 `config/database.yml`（或通过环境变量配置）：

```yaml
production:
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  url: <%= ENV.fetch('DATABASE_URL', '') %>
  
  # ⚠️ 关键变更：使用 app_user 而不是超级用户
  # 方式1：直接在 url 中指定
  # url: postgresql://app_user:password@host:5432/dbname
  
  # 方式2：分开配置（推荐）
  host: <%= ENV['DB_HOST'] || 'localhost' %>
  database: <%= ENV['DB_NAME'] || 'travel01_production' %>
  username: app_user  # ⚠️ 使用 app_user，不是 travel01 或 postgres
  password: <%= ENV['DB_PASSWORD'] %>
```

### 🐳 Docker Compose 环境变量配置

在 `.env` 文件中，DATABASE_URL 应使用 `app_user`：

```bash
# ❌ 错误（使用超级用户会绕过 RLS）
DATABASE_URL=postgresql://travel01:password@db:5432/travel01_production

# ✅ 正确（使用非超级用户，启用 RLS 策略）
DATABASE_URL=postgresql://app_user:password@db:5432/travel01_production
```

或者在 `docker-compose.yml` 中直接配置：

```yaml
web:
  environment:
    # ❌ 旧配置
    # DATABASE_URL: postgresql://${DB_USER:-travel01}:${DB_PASSWORD}@db:5432/${DB_NAME:-travel01_production}
    
    # ✅ 新配置（使用 app_user）
    DATABASE_URL: postgresql://app_user:${DB_PASSWORD}@db:5432/${DB_NAME:-travel01_production}
```

## 验证配置

部署后，进入容器验证：

```bash
# 进入 web 容器
docker-compose -f docker-compose.production.8core.yml exec web bash

# 检查当前数据库用户
rails runner "puts ActiveRecord::Base.connection.execute('SELECT current_user').first['current_user']"
# 输出应为: app_user

# 检查 RLS 策略是否生效
rails runner "
exec = ValidatorExecution.create!(
  execution_id: SecureRandom.uuid,
  user_id: User.first.id,
  state: { data: { data_version: 999 } },
  is_active: true
)
ActiveRecord::Base.connection.execute('SET app.data_version = 999')
HotelBooking.create!(
  hotel_id: Hotel.first.id,
  hotel_room_id: Hotel.first.hotel_rooms.first.id,
  user_id: User.first.id,
  check_in_date: Date.today,
  check_out_date: Date.today + 1,
  guest_name: 'Test',
  guest_phone: '13800138000',
  rooms_count: 1,
  adults_count: 2,
  children_count: 0,
  payment_method: '花呗',
  status: 'pending',
  total_price: 100
)
puts 'Session 999: ' + HotelBooking.count.to_s + ' bookings'
ActiveRecord::Base.connection.execute('SET app.data_version = 888')
puts 'Session 888: ' + HotelBooking.count.to_s + ' bookings (should be 0)'
"
# 输出应为: Session 999: 1 bookings / Session 888: 0 bookings
```

## 故障排查

### 问题1：RLS 策略不生效

**症状**：不同 session_id 能看到彼此的数据

**原因**：使用了超级用户连接数据库

**解决**：
```bash
# 检查当前用户
rails runner "puts ActiveRecord::Base.connection.execute('SELECT current_user, usesuper FROM pg_user WHERE usename = current_user').first"

# 如果 usesuper=t，说明是超级用户，需要修改配置
```

### 问题2：app_user 没有权限

**症状**：`PG::InsufficientPrivilege` 错误

**解决**：
```sql
-- 以超级用户身份连接数据库
psql -U travel01 -d travel01_production

-- 授予权限
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_user;
```

### 问题3：rake validator:reset_baseline 失败

**症状**：`permission denied to set parameter "session_replication_role"`

**原因**：这个任务需要超级用户权限

**解决**：`rake validator:reset_baseline` 已经修改为自动切换到 postgres 用户执行清理操作。

## 自动化脚本

如果需要手动初始化角色（非 Docker 环境），运行：

```bash
# 方式1：使用 SQL 文件
psql -U postgres -d travel01_production -f db/init_production_roles.sql

# 方式2：直接执行
psql -U postgres -d travel01_production -c "
  CREATE ROLE app_user WITH LOGIN NOSUPERUSER PASSWORD 'your_password';
  GRANT ALL PRIVILEGES ON DATABASE travel01_production TO app_user;
  GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_user;
  GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_user;
"
```

## 开发环境 vs 生产环境

| 环境 | 数据库用户 | RLS 策略 | 说明 |
|------|-----------|---------|------|
| 开发 | `app_user` | ✅ 启用 | 与生产保持一致 |
| 测试 | `postgres` | ❌ 跳过 | 测试时使用超级用户方便清理数据 |
| 生产 | `app_user` | ✅ 启用 | 必须使用非超级用户 |

## 迁移检查清单

- [ ] 修改 `.env` 或 `DATABASE_URL` 使用 `app_user`
- [ ] 修改 `docker-compose.yml` 的 `DATABASE_URL` 环境变量
- [ ] 重新部署应用（`deploy.sh` 会自动创建角色）
- [ ] 验证当前用户：`rails runner "puts ActiveRecord::Base.connection.execute('SELECT current_user').first['current_user']"`
- [ ] 测试多会话隔离功能

## 相关文件

- `bin/docker-entrypoint` - 自动创建 app_user 角色
- `db/init_production_roles.sql` - 手动初始化脚本
- `db/migrate/20260127095519_fix_rls_policies_for_app_user.rb` - RLS 策略迁移
- `lib/tasks/validator.rake` - rake validator:reset_baseline 任务
- `config/database.yml` - 数据库配置
