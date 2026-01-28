# 本地测试部署指南

## 问题诊断

### 当前问题：`travel01_web` 容器不断重启

**原因分析：**
```
数据库连接失败：password authentication failed for user "app_user"
```

云端镜像配置了 `app_user` 数据库用户，但本地 docker-compose 使用的是 `travel01` 用户，导致认证失败。

### 日志信息：
```bash
# 查看容器状态
docker ps -a | grep travel01_web
# 输出: Restarting (1) 12 seconds ago

# 查看错误日志
docker logs travel01_web --tail 50
# 输出: FATAL: password authentication failed for user "app_user"
```

---

## 解决方案

### 方案 1：修复当前部署（快速修复）

停止当前服务并修复数据库用户配置：

```bash
# 1. 停止所有服务
docker-compose -f docker-compose.production.2core.yml down -v

# 2. 修改 .env 文件，确保数据库配置一致
# 编辑 .env，修改以下内容：
DB_USER=travel01
DB_PASSWORD=你的密码

# 3. 修改 docker-compose.production.2core.yml 的第 75 行
# 将: DATABASE_URL: postgresql://app_user:${DB_PASSWORD}@db:5432/...
# 改为: DATABASE_URL: postgresql://${DB_USER:-travel01}:${DB_PASSWORD}@db:5432/...

# 4. 重新启动
docker-compose -f docker-compose.production.2core.yml up -d
```

### 方案 2：使用本地测试配置（推荐）

使用专门为本地测试准备的配置文件，避免依赖云端镜像：

```bash
# 1. 停止当前部署
bash -c 'docker-compose -f docker-compose.production.2core.yml down -v 2>/dev/null || true'

# 2. 使用本地测试部署脚本（自动构建本地镜像）
bash local-deploy.sh
```

**优点：**
- ✅ 使用本地 Dockerfile 构建，不依赖阿里云镜像
- ✅ 简化了数据库用户配置（直接使用 POSTGRES_USER）
- ✅ 独立的端口配置（5011），不与其他服务冲突
- ✅ 独立的数据卷，不影响生产环境数据
- ✅ 更详细的日志输出（debug 级别）

---

## 使用本地测试环境

### 快速启动

```bash
# 一键部署（首次使用，会构建镜像）
bash local-deploy.sh
```

### 访问地址

- **用户端**: http://localhost:5011
- **管理后台**: http://localhost:5011/admin
- **API健康检查**: http://localhost:5011/api/v1/health

### 默认账号

- **用户名**: admin
- **密码**: admin

---

## 常用命令

### 查看日志
```bash
# 查看 Web 服务日志
docker-compose -f docker-compose.local.yml logs -f web

# 查看 Worker 日志
docker-compose -f docker-compose.local.yml logs -f worker

# 查看所有服务日志
docker-compose -f docker-compose.local.yml logs -f
```

### 服务管理
```bash
# 查看服务状态
docker-compose -f docker-compose.local.yml ps

# 停止服务
docker-compose -f docker-compose.local.yml down

# 停止并删除数据
docker-compose -f docker-compose.local.yml down -v

# 重启服务
docker-compose -f docker-compose.local.yml restart web

# 重新构建并启动
docker-compose -f docker-compose.local.yml up --build -d
```

### 进入容器
```bash
# 进入 Web 容器
docker-compose -f docker-compose.local.yml exec web bash

# 在容器中执行 Rails 命令
docker-compose -f docker-compose.local.yml exec web rails console

# 执行数据库迁移
docker-compose -f docker-compose.local.yml exec web rails db:migrate

# 查看数据统计
docker-compose -f docker-compose.local.yml exec web rails runner 'puts "Cities: #{City.count}, Flights: #{Flight.count}"'
```

---

## 配置说明

### 关键差异

| 项目 | 生产部署 | 本地测试 |
|------|---------|---------|
| 镜像来源 | 阿里云镜像仓库 | 本地 Dockerfile 构建 |
| 数据库用户 | `app_user` (需要额外配置) | `travel01` (POSTGRES_USER) |
| Web 端口 | 5010 | 5011 |
| DB 端口 | 5432 | 5433 |
| Redis 端口 | 6379 | 6380 |
| 日志级别 | info | debug |
| Worker 数量 | 2 | 1 |
| 数据卷前缀 | `postgres_data` | `postgres_local_data` |

### 环境变量

本地测试使用 `.env.local` 文件，包含以下默认配置：

```env
# 数据库
DB_USER=travel01
DB_PASSWORD=travel01_password
DB_PORT=5433

# Redis
REDIS_PASSWORD=travel01_redis
REDIS_PORT=6380

# Web 服务
WEB_PORT=5011
PUBLIC_HOST=http://localhost:5011

# 性能
WEB_CONCURRENCY=1
RAILS_MAX_THREADS=5
```

---

## 故障排查

### 1. 容器不断重启
```bash
# 查看容器日志
docker logs travel01_local_web --tail 100

# 常见原因：
# - 数据库连接失败
# - 环境变量缺失
# - 端口冲突
```

### 2. 数据库连接失败
```bash
# 检查数据库容器状态
docker-compose -f docker-compose.local.yml ps db

# 检查数据库日志
docker-compose -f docker-compose.local.yml logs db

# 测试数据库连接
docker-compose -f docker-compose.local.yml exec db psql -U travel01 -d travel01_production -c "SELECT 1;"
```

### 3. 端口冲突
```bash
# 检查端口占用
lsof -i :5011
lsof -i :5433
lsof -i :6380

# 修改 .env.local 中的端口配置
```

### 4. 权限问题
```bash
# 确保脚本有执行权限
chmod +x local-deploy.sh

# 确保 Docker 有权限访问目录
sudo chown -R $(whoami) ./backup ./storage ./log
```

---

## 注意事项

⚠️ **重要提示：**

1. **本地测试配置仅用于开发测试**，不要用于生产环境
2. **独立的数据卷**：本地测试的数据不会影响生产环境
3. **端口隔离**：使用不同的端口（5011, 5433, 6380）避免冲突
4. **镜像构建**：首次启动需要构建镜像，可能需要 5-10 分钟
5. **资源占用**：本地测试使用较少的资源（1 个 worker）

---

## 从生产切换到本地测试

如果你已经使用 `deploy.sh` 部署了生产环境，现在想切换到本地测试：

```bash
# 1. 停止生产环境（不删除数据）
docker-compose -f docker-compose.production.2core.yml down

# 2. 启动本地测试环境
bash local-deploy.sh

# 3. 如果需要恢复生产环境
docker-compose -f docker-compose.production.2core.yml up -d
```

两个环境使用不同的容器名和数据卷，可以共存不冲突。
