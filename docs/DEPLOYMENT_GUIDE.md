# 旅游环境01 - 商业化本地部署指南

## 📋 目录

- [系统要求](#系统要求)
- [快速开始](#快速开始)
- [详细部署步骤](#详细部署步骤)
- [配置说明](#配置说明)
- [运维管理](#运维管理)
- [备份与恢复](#备份与恢复)
- [故障排查](#故障排查)
- [性能优化](#性能优化)

---

## 🖥️ 系统要求

### 最低配置
- **CPU**: 4 核
- **内存**: 8 GB
- **硬盘**: 50 GB 可用空间
- **操作系统**: Linux (Ubuntu 20.04+, CentOS 7+, Debian 10+) / macOS / Windows (with WSL2)

### 推荐配置
- **CPU**: 8 核或更多
- **内存**: 16 GB 或更多
- **硬盘**: 100 GB SSD
- **操作系统**: Ubuntu 22.04 LTS

### 软件依赖
- Docker Engine 20.10+
- Docker Compose 2.0+

---

## 🚀 快速开始

### 1. 安装 Docker 和 Docker Compose

#### Ubuntu/Debian
```bash
# 安装 Docker
curl -fsSL https://get.docker.com | sh

# 启动 Docker 服务
sudo systemctl start docker
sudo systemctl enable docker

# 将当前用户添加到 docker 组
sudo usermod -aG docker $USER

# 重新登录以使组更改生效
```

#### macOS
```bash
# 使用 Homebrew 安装
brew install --cask docker

# 或下载 Docker Desktop: https://www.docker.com/products/docker-desktop
```

#### Windows
下载并安装 Docker Desktop: https://www.docker.com/products/docker-desktop

### 2. 克隆项目代码

```bash
# 假设您已经收到项目代码包
cd /path/to/your/project
```

### 3. 配置环境变量

```bash
# 复制环境变量示例文件
cp .env.example .env

# 编辑配置文件
nano .env  # 或使用 vim、vi 等编辑器
```

**必须配置的关键项:**
```bash
SECRET_KEY_BASE=<64位随机字符串>
DB_PASSWORD=<数据库强密码>
REDIS_PASSWORD=<Redis强密码>
PUBLIC_HOST=http://your-domain.com  # 或 http://localhost:3000
```

**生成 SECRET_KEY_BASE:**
```bash
# 方法1: 使用 openssl
openssl rand -hex 64

# 方法2: 使用 Docker 临时容器
docker-compose -f docker-compose.production.yml run --rm web bundle exec rails secret
```

### 4. 启动服务

```bash
# 构建并启动所有服务
docker-compose -f docker-compose.production.yml up -d

# 查看服务状态
docker-compose -f docker-compose.production.yml ps

# 查看日志
docker-compose -f docker-compose.production.yml logs -f web
```

### 5. 初始化数据库

```bash
# 创建数据库并执行迁移
docker-compose -f docker-compose.production.yml exec web bundle exec rails db:create db:migrate

# (可选) 加载种子数据
docker-compose -f docker-compose.production.yml exec web bundle exec rails db:seed
```

### 6. 创建管理员账号

```bash
# 进入 Rails 控制台
docker-compose -f docker-compose.production.yml exec web bundle exec rails console

# 创建管理员
Administrator.create!(
  email: 'admin@example.com',
  password: 'your_strong_password',
  password_confirmation: 'your_strong_password'
)
```

### 7. 访问应用

打开浏览器访问:
- **用户端**: http://localhost:3000
- **管理后台**: http://localhost:3000/admin

---

## 📝 详细部署步骤

### 服务架构说明

本系统采用微服务架构，包含以下容器:

| 服务名 | 容器名 | 端口 | 说明 |
|--------|--------|------|------|
| db | travel01_postgres | 5432 | PostgreSQL 数据库 |
| redis | travel01_redis | 6379 | Redis 缓存和消息队列 |
| web | travel01_web | 3000 | Rails 主应用 |
| worker | travel01_worker | - | 后台任务处理器 |
| nginx | travel01_nginx | 80/443 | 反向代理 (可选) |

### 网络和数据卷

**数据卷 (持久化存储):**
- `postgres_data`: 数据库数据
- `redis_data`: Redis 持久化数据
- `storage_data`: ActiveStorage 文件存储
- `log_data`: 应用日志
- `tmp_data`: 临时文件

**网络:**
- `travel01_network`: 内部容器通信网络

---

## ⚙️ 配置说明

### 环境变量详解

#### 核心配置

**SECRET_KEY_BASE**
- 用于加密 session、cookies、密码等敏感数据
- 必须是64位随机字符串
- ⚠️ 生产环境切勿使用示例值

**DATABASE_URL**
- 格式: `postgresql://用户名:密码@主机:端口/数据库名`
- 在 docker-compose.production.yml 中已自动配置

**REDIS_URL**
- 格式: `redis://:密码@主机:端口/数据库编号`
- 用于缓存和 ActionCable 实时通信

#### 邮件配置

如需启用邮件功能 (用户注册、密码重置等)，请配置:

```bash
EMAIL_SMTP_ADDRESS=smtp.gmail.com
EMAIL_SMTP_PORT=587
EMAIL_SMTP_USERNAME=your_email@gmail.com
EMAIL_SMTP_PASSWORD=your_app_password
EMAIL_SMTP_DOMAIN=gmail.com
```

**常用邮件服务商配置:**

| 服务商 | SMTP 地址 | 端口 | 说明 |
|--------|-----------|------|------|
| Gmail | smtp.gmail.com | 587 | 需要开启两步验证并生成应用专用密码 |
| QQ邮箱 | smtp.qq.com | 587 | 需要开启 SMTP 服务并获取授权码 |
| 163邮箱 | smtp.163.com | 465 | 需要开启 SMTP 服务 |
| 阿里云 | smtpdm.aliyun.com | 465 | 企业邮箱推送服务 |

#### OAuth 社交登录

如需启用社交登录，请先在对应平台申请 OAuth 应用:

**Google:**
1. 访问 [Google Cloud Console](https://console.cloud.google.com/)
2. 创建项目并启用 Google+ API
3. 创建 OAuth 2.0 客户端 ID
4. 设置重定向 URI: `http://your-domain.com/auth/google_oauth2/callback`

**配置示例:**
```bash
GOOGLE_OAUTH_ENABLED=true
GOOGLE_CLIENT_ID=your_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_client_secret
```

同理配置 Facebook、Twitter、GitHub 等。

#### 性能调优参数

```bash
# Puma Web 服务器配置
RAILS_MAX_THREADS=10        # 每个 worker 的线程数 (5-10)
WEB_CONCURRENCY=2           # Worker 进程数 (CPU 核心数)

# GoodJob 后台任务配置
GOOD_JOB_MAX_THREADS=5      # 任务处理线程数
GOOD_JOB_POLL_INTERVAL=10   # 轮询间隔 (秒)
GOOD_JOB_QUEUES=*           # 处理的队列 (* 表示全部)
```

**调优建议:**
- `RAILS_MAX_THREADS`: 根据数据库连接池大小调整 (默认 pool: 15)
- `WEB_CONCURRENCY`: 设置为 CPU 核心数，每增加1个 worker 约增加 1GB 内存占用
- `GOOD_JOB_MAX_THREADS`: 根据后台任务量调整，建议 5-10

---

## 🛠️ 运维管理

### 常用命令

#### 服务管理

```bash
# 启动所有服务
docker-compose -f docker-compose.production.yml up -d

# 停止所有服务
docker-compose -f docker-compose.production.yml down

# 重启特定服务
docker-compose -f docker-compose.production.yml restart web

# 查看服务状态
docker-compose -f docker-compose.production.yml ps

# 查看实时日志
docker-compose -f docker-compose.production.yml logs -f

# 查看特定服务日志
docker-compose -f docker-compose.production.yml logs -f web
```

#### 数据库操作

```bash
# 进入数据库控制台
docker-compose -f docker-compose.production.yml exec db psql -U travel01 -d travel01_production

# 执行数据库迁移
docker-compose -f docker-compose.production.yml exec web bundle exec rails db:migrate

# 回滚迁移
docker-compose -f docker-compose.production.yml exec web bundle exec rails db:rollback

# 重置数据库 (⚠️ 危险操作，会删除所有数据)
docker-compose -f docker-compose.production.yml exec web bundle exec rails db:reset
```

#### 应用管理

```bash
# 进入 Rails 控制台
docker-compose -f docker-compose.production.yml exec web bundle exec rails console

# 清理缓存
docker-compose -f docker-compose.production.yml exec web bundle exec rails cache:clear

# 重新编译资源文件
docker-compose -f docker-compose.production.yml exec web bundle exec rails assets:precompile

# 查看路由
docker-compose -f docker-compose.production.yml exec web bundle exec rails routes
```

#### 容器管理

```bash
# 进入容器 Shell
docker-compose -f docker-compose.production.yml exec web bash

# 查看容器资源占用
docker stats

# 清理无用的 Docker 资源
docker system prune -a

# 查看容器详细信息
docker inspect travel01_web
```

### 监控和日志

#### 日志管理

应用日志存储在 `log_data` 数据卷中:

```bash
# 查看 Rails 日志
docker-compose -f docker-compose.production.yml exec web tail -f log/production.log

# 查看 Puma 日志
docker-compose -f docker-compose.production.yml logs -f web

# 查看数据库日志
docker-compose -f docker-compose.production.yml logs -f db

# 查看 Worker 日志
docker-compose -f docker-compose.production.yml logs -f worker
```

#### 性能监控

```bash
# 查看容器资源使用情况
docker stats travel01_web travel01_worker travel01_postgres travel01_redis

# 进入 Redis 控制台查看状态
docker-compose -f docker-compose.production.yml exec redis redis-cli -a your_redis_password
> INFO
> DBSIZE
> MEMORY STATS
```

---

## 💾 备份与恢复

### 数据库备份

#### 自动备份脚本

创建 `backup/backup.sh`:

```bash
#!/bin/bash

# 配置
BACKUP_DIR="/path/to/backup"
DB_CONTAINER="travel01_postgres"
DB_USER="travel01"
DB_NAME="travel01_production"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 执行备份
docker exec $DB_CONTAINER pg_dump -U $DB_USER $DB_NAME | gzip > $BACKUP_DIR/backup_$DATE.sql.gz

# 删除7天前的备份
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +7 -delete

echo "备份完成: backup_$DATE.sql.gz"
```

**添加定时任务 (每天凌晨2点备份):**

```bash
# 编辑 crontab
crontab -e

# 添加以下行
0 2 * * * /path/to/backup/backup.sh >> /path/to/backup/backup.log 2>&1
```

#### 手动备份

```bash
# 备份数据库
docker-compose -f docker-compose.production.yml exec db pg_dump -U travel01 travel01_production | gzip > backup/manual_backup_$(date +%Y%m%d).sql.gz

# 备份文件存储 (ActiveStorage)
docker run --rm -v travel01_storage_data:/data -v $(pwd)/backup:/backup alpine tar czf /backup/storage_backup_$(date +%Y%m%d).tar.gz -C /data .
```

### 数据恢复

```bash
# 1. 停止应用服务
docker-compose -f docker-compose.production.yml stop web worker

# 2. 恢复数据库
gunzip < backup/backup_20240101_020000.sql.gz | docker-compose -f docker-compose.production.yml exec -T db psql -U travel01 travel01_production

# 3. 恢复文件存储
docker run --rm -v travel01_storage_data:/data -v $(pwd)/backup:/backup alpine tar xzf /backup/storage_backup_20240101.tar.gz -C /data

# 4. 启动应用服务
docker-compose -f docker-compose.production.yml start web worker
```

---

## 🔧 故障排查

### 常见问题

#### 1. 服务无法启动

**问题**: `docker-compose up` 失败

**排查步骤:**
```bash
# 查看详细错误信息
docker-compose -f docker-compose.production.yml logs

# 检查端口占用
sudo netstat -tlnp | grep -E '3000|5432|6379|80'

# 检查 .env 文件是否正确配置
cat .env
```

**常见原因:**
- 端口被占用
- 环境变量未设置或格式错误
- Docker 磁盘空间不足

#### 2. 数据库连接失败

**问题**: `PG::ConnectionBad: could not connect to server`

**解决方案:**
```bash
# 检查数据库容器状态
docker-compose -f docker-compose.production.yml ps db

# 查看数据库日志
docker-compose -f docker-compose.production.yml logs db

# 确认数据库健康检查
docker-compose -f docker-compose.production.yml exec db pg_isready -U travel01

# 测试连接
docker-compose -f docker-compose.production.yml exec web bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')"
```

#### 3. Redis 连接失败

**问题**: `Redis::CannotConnectError`

**解决方案:**
```bash
# 检查 Redis 容器
docker-compose -f docker-compose.production.yml ps redis

# 测试 Redis 连接
docker-compose -f docker-compose.production.yml exec redis redis-cli -a your_redis_password ping

# 查看 Redis 日志
docker-compose -f docker-compose.production.yml logs redis
```

#### 4. 内存不足

**问题**: 容器频繁重启，OOM 错误

**解决方案:**
```bash
# 查看容器内存使用
docker stats --no-stream

# 调整 docker-compose.production.yml 中的资源限制
# 或增加主机内存

# 减少 worker 进程数
WEB_CONCURRENCY=1
```

#### 5. 静态资源 404

**问题**: CSS/JS 文件无法加载

**解决方案:**
```bash
# 重新编译资源
docker-compose -f docker-compose.production.yml exec web bundle exec rails assets:precompile

# 检查环境变量
docker-compose -f docker-compose.production.yml exec web printenv | grep RAILS

# 确认 RAILS_SERVE_STATIC_FILES=true
```

### 调试模式

```bash
# 临时启用详细日志
docker-compose -f docker-compose.production.yml exec web bash -c "RAILS_LOG_LEVEL=debug bundle exec rails console"

# 查看完整的环境变量
docker-compose -f docker-compose.production.yml exec web printenv

# 进入容器调试
docker-compose -f docker-compose.production.yml exec web bash
```

---

## ⚡ 性能优化

### 1. 数据库优化

```sql
-- 进入 PostgreSQL 控制台
docker-compose -f docker-compose.production.yml exec db psql -U travel01 travel01_production

-- 创建常用索引
CREATE INDEX CONCURRENTLY idx_bookings_user_id ON bookings(user_id);
CREATE INDEX CONCURRENTLY idx_bookings_created_at ON bookings(created_at DESC);

-- 分析表统计信息
ANALYZE bookings;

-- 查看慢查询
SELECT query, calls, mean_exec_time 
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;
```

### 2. Redis 缓存配置

在 `.env` 中添加:
```bash
REDIS_CACHE_URL=redis://:your_redis_password@redis:6379/2
```

### 3. CDN 加速

使用 Nginx 配置静态资源缓存，或接入第三方 CDN 服务。

### 4. 资源限制调整

根据实际负载调整 `docker-compose.production.yml` 中的资源限制:

```yaml
deploy:
  resources:
    limits:
      cpus: '8'      # 增加 CPU 限制
      memory: 8G     # 增加内存限制
```

---

## 📞 技术支持

如在部署过程中遇到问题，请提供以下信息:

1. 操作系统版本: `uname -a`
2. Docker 版本: `docker --version`
3. Docker Compose 版本: `docker-compose --version`
4. 错误日志: `docker-compose -f docker-compose.production.yml logs`
5. 服务状态: `docker-compose -f docker-compose.production.yml ps`

---

## 📄 附录

### 相关文档

- [项目架构说明](PROJECT_STRUCTURE.md)
- [API 文档](API_GUIDE.md)
- [管理后台使用指南](ADMIN_GUIDE.md)
- [开发环境配置](../README.md)

### 版本更新

```bash
# 拉取最新代码
git pull origin main

# 重新构建镜像
docker-compose -f docker-compose.production.yml build --no-cache

# 执行数据库迁移
docker-compose -f docker-compose.production.yml exec web bundle exec rails db:migrate

# 重启服务
docker-compose -f docker-compose.production.yml restart
```

---

**本文档最后更新**: 2024-01-18
