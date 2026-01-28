# 🎯 Docker 部署问题修复总结

**修复时间**: 2026-01-27
**问题**: `travel01_web` 容器不断重启（Restarting）

---

## 📋 问题诊断

### 根本原因

`travel01_web` 容器启动时数据库连接失败：

```
ActiveRecord::DatabaseConnectionError: password authentication failed for user "app_user"
```

**原因分析**：
1. **云端镜像**使用旧版 `bin/docker-entrypoint`，其中创建 `app_user` 的逻辑使用 `psql` 命令
2. **容器内没有 `psql` 客户端**，导致创建 `app_user` 失败
3. **docker-compose 配置**使用 `DATABASE_URL=postgresql://app_user:...`，但 `app_user` 未创建
4. **结果**：Rails 应用无法连接数据库，容器不断重启

---

## ✅ 解决方案

### 临时修复（手动创建 app_user）

在数据库容器中手动创建 `app_user` 角色：

```bash
# 手动创建 app_user 角色
docker exec travel01_postgres psql -U travel01 -d travel01_production -c "
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_user') THEN
      CREATE ROLE app_user WITH LOGIN NOSUPERUSER PASSWORD '123';
      RAISE NOTICE 'Created app_user';
   END IF;
END \$\$;

GRANT CONNECT ON DATABASE travel01_production TO app_user;
GRANT USAGE, CREATE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO app_user;
ALTER ROLE app_user SET search_path TO public;
"

# 重启 web 和 worker 容器
docker-compose -f docker-compose.production.2core.yml restart web worker
```

### 永久修复（已提交代码）

**修改文件**: `bin/docker-entrypoint`

**修改内容**:
- ❌ 移除依赖 `psql` 命令的方案
- ✅ 使用 `bundle exec rails runner` 通过 ActiveRecord 创建角色
- ✅ 添加数据库就绪等待逻辑
- ✅ 提供更详细的错误信息

关键代码：
```ruby
bundle exec rails runner -e production "
begin
  result = ActiveRecord::Base.connection.execute(\"SELECT 1 FROM pg_roles WHERE rolname = 'app_user'\")

  if result.to_a.empty?
    password = ENV['DB_PASSWORD'] || ENV['SUPER_PASSWORD']
    ActiveRecord::Base.connection.execute(\"CREATE ROLE app_user WITH LOGIN NOSUPERUSER PASSWORD '#{password}'\")
    # 授予权限...
    puts '[Production] ✅ app_user role created successfully'
  else
    puts '[Production] ✅ app_user role already exists'
  end
rescue => e
  puts \"[Production] ⚠️  Error: #{e.message}\"
end
"
```

---

## 🔄 验证结果

### 部署成功

```bash
# 容器状态
docker ps | grep travel01
# 输出：travel01_web Up 2 minutes (healthy)

# 健康检查
curl http://localhost:5010/api/v1/health
# 输出：{"status":"ok"}

# 首页访问
curl http://localhost:5010
# 输出：HTML content (旅游环境01)
```

### 数据库连接验证

```bash
docker exec travel01_web bundle exec rails runner "
puts 'Current user: ' + ActiveRecord::Base.connection.execute('SELECT current_user').first['current_user']
"
# 输出：Current user: app_user
```

---

## 📦 部署步骤（生产环境）

### 新环境部署

```bash
# 1. 确保有 .env 文件配置
cp .env.example .env
vi .env  # 配置数据库密码、SECRET_KEY_BASE等

# 2. 登录镜像仓库并拉取镜像
docker login qinglion-registry.cn-hangzhou.cr.aliyuncs.com
docker-compose -f docker-compose.production.2core.yml pull

# 3. 启动数据库和 Redis
docker-compose -f docker-compose.production.2core.yml up -d db redis

# 4. 手动创建 app_user（云端镜像需要）
docker exec travel01_postgres psql -U travel01 -d travel01_production -c "
CREATE ROLE app_user WITH LOGIN NOSUPERUSER PASSWORD 'YOUR_PASSWORD';
GRANT CONNECT ON DATABASE travel01_production TO app_user;
GRANT USAGE, CREATE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
ALTER DEFAULT PRIVILEGES GRANT USAGE, SELECT ON SEQUENCES TO app_user;
"

# 5. 启动 web 和 worker
docker-compose -f docker-compose.production.2core.yml up -d web worker

# 6. 等待服务就绪（约 1-2 分钟）
docker logs -f travel01_web

# 7. 访问验证
curl http://localhost:5010
```

### 已有环境更新

如果容器已在运行但需要创建 `app_user`：

```bash
# 1. 手动创建 app_user（见上方命令）

# 2. 重启容器
docker-compose -f docker-compose.production.2core.yml restart web worker
```

---

## 🆕 本地测试环境

为了方便本地测试，创建了独立的本地测试配置：

### 文件清单

- `docker-compose.local.yml` - 本地测试专用配置（使用本地构建）
- `.env.local` - 本地测试环境变量
- `local-deploy.sh` - 一键本地部署脚本
- `README-LOCAL-TEST.md` - 本地测试快速指南
- `docs/local-testing-guide.md` - 详细操作文档

### 快速启动

```bash
# 一键启动本地测试环境
bash local-deploy.sh

# 访问地址
open http://localhost:5011
```

### 特点

- ✅ 使用本地 Dockerfile 构建（不依赖云端镜像）
- ✅ 简化数据库配置（直接使用 `travel01` 用户）
- ✅ 独立端口（5011, 5433, 6380）避免冲突
- ✅ 独立数据卷（不影响生产数据）
- ✅ Debug 级别日志（方便调试）

---

## 🔧 重要配置文件

### docker-compose.production.yml

```yaml
web:
  environment:
    # ✅ 使用 app_user 支持 RLS 多会话隔离
    DATABASE_URL: postgresql://app_user:${DB_PASSWORD}@db:5432/${DB_NAME}
```

### bin/docker-entrypoint

```bash
# 生产环境自动创建 app_user
if [ "${RAILS_ENV}" == "production" ]; then
  # 使用 Rails runner 创建角色（不依赖 psql）
  bundle exec rails runner -e production "..."
fi
```

---

## ⚠️ 注意事项

### 为什么必须使用 app_user？

`app_user` 是为了支持**多会话数据隔离**功能（RLS 策略）：

- **PostgreSQL RLS（Row Level Security）**需要非超级用户才能生效
- **多会话功能**：不同 session_id 的数据互相隔离
- **甲方要求**：支持多个并发验证会话

详见文档：
- `MULTI_SESSION_PRODUCTION_FIX.md`
- `docs/PRODUCTION_DATABASE_SETUP.md`
- `db/migrate/20260127095519_fix_rls_policies_for_app_user.rb`

### 云端镜像 vs 本地构建

| 项目 | 云端镜像 | 本地构建 |
|------|---------|---------|
| 镜像源 | `qinglion-registry.cn-hangzhou.cr.aliyuncs.com/rl/travel01:latest` | 本地 Dockerfile |
| app_user 创建 | ⚠️ 需要手动创建（旧版 entrypoint） | ✅ 自动创建（新版 entrypoint） |
| 适用场景 | 生产部署（甲方要求） | 本地测试开发 |

**建议**：
1. **生产环境**：使用云端镜像 + 手动创建 `app_user`（等待新镜像发布）
2. **本地测试**：使用 `local-deploy.sh` 本地构建

---

## 📚 相关文档

- [本地测试快速指南](README-LOCAL-TEST.md)
- [本地测试详细文档](docs/local-testing-guide.md)
- [多会话生产环境修复](MULTI_SESSION_PRODUCTION_FIX.md)
- [生产数据库配置](docs/PRODUCTION_DATABASE_SETUP.md)

---

## ✅ 验证清单

部署完成后，请检查：

- [ ] `docker ps` 显示所有容器状态为 `Up (healthy)`
- [ ] `curl http://localhost:5010/api/v1/health` 返回 `{"status":"ok"}`
- [ ] `curl http://localhost:5010` 返回旅游环境01首页 HTML
- [ ] 数据库用户检查：
  ```bash
  docker exec travel01_web bundle exec rails runner "
  puts ActiveRecord::Base.connection.execute('SELECT current_user').first['current_user']
  "
  # 应输出: app_user
  ```
- [ ] 管理后台可访问：http://localhost:5010/admin
- [ ] 默认管理员登录（admin / admin）成功

---

## 🐛 故障排查

### 容器一直重启

```bash
# 1. 查看日志
docker logs travel01_web --tail 100

# 2. 常见错误
# - "password authentication failed for user app_user"
#   → 需要手动创建 app_user（见上方命令）

# - "psql: command not found"
#   → 云端镜像使用旧版 entrypoint，需要手动创建 app_user

# 3. 验证 app_user 是否存在
docker exec travel01_postgres psql -U travel01 -d travel01_production -c "
SELECT rolname FROM pg_roles WHERE rolname = 'app_user';
"
# 如果无结果，说明需要手动创建
```

### 数据库连接失败

```bash
# 检查数据库容器状态
docker-compose -f docker-compose.production.2core.yml ps db
# 应显示: Up (healthy)

# 测试数据库连接
docker exec travel01_postgres psql -U travel01 -d travel01_production -c "SELECT 1;"

# 检查 .env 文件配置
cat .env | grep -E "DB_USER|DB_PASSWORD|DB_NAME"
```

---

**修复完成！系统已成功部署并运行。** 🎉
