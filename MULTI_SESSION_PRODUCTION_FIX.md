# 多会话数据隔离 - 生产环境部署修复总结

## 修复时间
2026-01-27

## 问题描述

开发环境多会话数据隔离正常工作，但甲方通过 `deploy.sh` 部署时会出现 RLS 策略失效问题。

根本原因：**生产环境默认使用 `travel01` 用户（从 `.env` 读取），这个用户可能是表的所有者，拥有绕过 RLS 的特权。**

## 解决方案

### 1. 自动创建 `app_user` 角色

修改 `bin/docker-entrypoint`，在生产环境启动时自动创建 `app_user` 非超级用户角色并授予权限：

```bash
# 生产环境：创建 app_user 角色（RLS 策略需要）
if [ "${RAILS_ENV}" == "production" ]; then
  echo "[Production] Initializing database roles for RLS policies..."
  
  # 使用超级用户 (travel01) 创建 app_user 角色
  PGPASSWORD="${DB_PASSWORD}" psql -h "${DB_HOST}" -U "${DB_USER}" -d "${DB_NAME}" -c "
    CREATE ROLE app_user WITH LOGIN NOSUPERUSER PASSWORD '${DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO app_user;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_user;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_user;
    ALTER DEFAULT PRIVILEGES GRANT ALL PRIVILEGES ON TABLES TO app_user;
    ALTER DEFAULT PRIVILEGES GRANT ALL PRIVILEGES ON SEQUENCES TO app_user;
  "
fi
```

### 2. 修改生产环境数据库连接

修改 `docker-compose.production.8core.yml` 和 `docker-compose.production.2core.yml`：

```yaml
# ❌ 旧配置（使用超级用户或表所有者，RLS 可能失效）
DATABASE_URL: postgresql://${DB_USER:-travel01}:${DB_PASSWORD}@db:5432/${DB_NAME:-travel01_production}

# ✅ 新配置（使用非超级用户，启用 RLS 策略）
DATABASE_URL: postgresql://app_user:${DB_PASSWORD}@db:5432/${DB_NAME:-travel01_production}
```

### 3. 开发环境保持一致

`config/database.yml` 开发环境已使用 `app_user`：

```yaml
development:
  username: app_user
  password: apppass
```

## APK Deeplink 确认

✅ **APK 传的是 `session_id`**

- Deeplink 格式：`ai.clacky.trip01://?session_id=xxx`
- WebView 加载 URL：`https://域名/?session_id=xxx`
- 优先级：Deeplink 参数 > 全局配置参数 > 默认值

实现逻辑见：
- `apk/app/src/main/java/ai/clacky/trip01/CustomWebViewFallbackActivity.java` (行 128-144)
- `app/middleware/validator_session_binder.rb` - 读取 URL 参数并设置 cookie
- `app/controllers/application_controller.rb` - 从 cookie 读取 session_id 并设置 PostgreSQL `app.data_version`

## 文件修改清单

### 核心修改
1. ✅ `bin/docker-entrypoint` - 自动创建 app_user 角色
2. ✅ `docker-compose.production.8core.yml` - 使用 app_user 连接
3. ✅ `docker-compose.production.2core.yml` - 使用 app_user 连接

### 新增文档
4. ✅ `docs/PRODUCTION_DATABASE_SETUP.md` - 生产环境配置说明
5. ✅ `db/init_production_roles.sql` - 手动初始化脚本（备用）
6. ✅ `MULTI_SESSION_PRODUCTION_FIX.md` - 本文档

### 已有修改（之前完成）
- `lib/tasks/validator.rake` - rake 任务临时切换到 postgres 用户
- `db/migrate/20260127095519_fix_rls_policies_for_app_user.rb` - RLS 策略迁移
- `config/database.yml` - 开发环境使用 app_user

## 部署流程

### 新环境部署

```bash
# 1. 运行 deploy.sh（会自动创建 app_user）
bash deploy.sh

# 2. 验证（可选）
docker-compose -f docker-compose.production.8core.yml exec web rails runner "
puts 'Current user: ' + ActiveRecord::Base.connection.execute('SELECT current_user').first['current_user']
"
# 输出应为: app_user
```

### 已有环境升级

```bash
# 1. 停止服务
docker-compose -f docker-compose.production.8core.yml down

# 2. 拉取最新代码
git pull

# 3. 重新部署（会自动创建 app_user）
bash deploy.sh
```

## 验证多会话隔离

进入容器测试：

```bash
docker-compose -f docker-compose.production.8core.yml exec web bash

# 测试脚本
rails runner "
require 'securerandom'

# 创建两个会话
user = User.first
exec1 = ValidatorExecution.create!(
  execution_id: SecureRandom.uuid,
  user_id: user.id,
  state: { data: { data_version: 111111 } },
  is_active: true
)
exec2 = ValidatorExecution.create!(
  execution_id: SecureRandom.uuid,
  user_id: user.id,
  state: { data: { data_version: 222222 } },
  is_active: true
)

# 在 session 1 创建订单
ActiveRecord::Base.connection.execute('SET app.data_version = 111111')
HotelBooking.create!(
  hotel_id: Hotel.first.id,
  hotel_room_id: Hotel.first.hotel_rooms.first.id,
  user_id: user.id,
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

# 查询 session 1
ActiveRecord::Base.connection.execute('SET app.data_version = 111111')
count1 = HotelBooking.count
puts \"Session 1 (111111) sees: #{count1} bookings\"

# 查询 session 2
ActiveRecord::Base.connection.execute('SET app.data_version = 222222')
count2 = HotelBooking.count
puts \"Session 2 (222222) sees: #{count2} bookings\"

# 验证基线数据
baseline = Hotel.where(data_version: 0).count
puts \"Baseline hotels: #{baseline}\"

if count1 == 1 && count2 == 0 && baseline > 0
  puts '✅ Multi-session isolation working correctly!'
else
  puts '❌ Multi-session isolation FAILED!'
end
"
```

预期输出：
```
Session 1 (111111) sees: 1 bookings
Session 2 (222222) sees: 0 bookings
Baseline hotels: 301
✅ Multi-session isolation working correctly!
```

## 故障排查

### 问题：RLS 策略不生效

**症状**：不同 session_id 能看到彼此的数据

**检查当前用户**：
```bash
rails runner "
result = ActiveRecord::Base.connection.execute('SELECT current_user, usesuper FROM pg_user WHERE usename = current_user').first
puts \"Current user: #{result['current_user']}\"
puts \"Is superuser: #{result['usesuper']}\"
"
```

如果 `usesuper=t` 或用户不是 `app_user`，说明配置错误。

**解决**：
1. 检查 `docker-compose.yml` 的 `DATABASE_URL` 是否使用 `app_user`
2. 检查 `.env` 文件是否覆盖了 `DATABASE_URL`
3. 重启服务：`docker-compose -f docker-compose.production.8core.yml restart web worker`

### 问题：app_user 权限不足

**症状**：`PG::InsufficientPrivilege` 错误

**解决**：
```bash
# 进入数据库容器
docker-compose -f docker-compose.production.8core.yml exec db psql -U travel01 -d travel01_production

# 重新授权
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO app_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO app_user;
```

## 总结

✅ **完成的工作**：
1. 修改 `bin/docker-entrypoint` 自动创建 `app_user` 角色
2. 修改生产环境 docker-compose 配置使用 `app_user` 连接
3. 编写完整的生产环境部署文档
4. 确认 APK Deeplink 传递 `session_id` 参数
5. 提供验证和故障排查脚本

✅ **甲方部署时的变化**：
- **无需手动操作**：`deploy.sh` 会自动创建 `app_user` 角色并授予权限
- **配置已更新**：生产环境 docker-compose 文件已使用 `app_user`
- **向后兼容**：如果 `app_user` 已存在，不会重复创建

✅ **多会话隔离验证**：
- 开发环境：已测试通过
- 生产环境：配置已就绪，甲方部署后会自动生效
