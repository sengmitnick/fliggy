# 旅游环境01 - Docker 商业化部署方案

## 📦 部署文件清单

本次更新为甲方商业化本地部署提供了完整的 Docker 容器化解决方案。

### 📁 新增文件

```
project/
├── docker-compose.production.yml     # 生产环境 Docker Compose 配置
├── .env.example                       # 环境变量配置示例
├── deploy.sh                          # 一键部署脚本 (已添加执行权限)
├── backup/
│   ├── backup.sh                      # 自动备份脚本
│   └── restore.sh                     # 数据恢复脚本
├── config/
│   ├── nginx.production.conf          # Nginx HTTP 配置
│   └── nginx.ssl.production.conf      # Nginx HTTPS 配置 (含 SSL)
└── docs/
    ├── DEPLOYMENT_GUIDE.md            # 完整部署指南 (60+ 页)
    └── QUICK_DEPLOY.md                # 5分钟快速开始指南
```

---

## 🚀 快速开始

### 方式一: 一键部署 (推荐)

```bash
# 1. 赋予执行权限 (如果需要)
chmod +x deploy.sh

# 2. 运行一键部署脚本
bash deploy.sh
```

脚本会引导您完成所有配置和部署步骤。

### 方式二: 手动部署

```bash
# 1. 配置环境变量
cp .env.example .env
nano .env  # 编辑必填项

# 2. 启动服务
docker-compose -f docker-compose.production.yml up -d

# 3. 初始化数据库
docker-compose -f docker-compose.production.yml exec web bundle exec rails db:create db:migrate

# 4. 创建管理员
docker-compose -f docker-compose.production.yml exec web bundle exec rails console
# Administrator.create!(email: 'admin@example.com', password: 'Admin123456!', password_confirmation: 'Admin123456!')
```

---

## 🏗️ 系统架构

### 服务组件

```
┌─────────────────────────────────────────────────────────────┐
│                         Nginx (可选)                         │
│                   反向代理 + SSL/TLS                         │
│                   端口: 80/443                               │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────┴──────────────────────────────────┐
│                      Rails Web 应用                          │
│                     Puma 服务器                              │
│                     端口: 3000                               │
└──────────────────┬───────────────────┬──────────────────────┘
                   │                   │
        ┌──────────┴─────────┐  ┌─────┴───────────┐
        │   PostgreSQL 16    │  │   Redis 7       │
        │   端口: 5432       │  │   端口: 6379    │
        │   持久化存储       │  │   缓存/队列     │
        └────────────────────┘  └─────────────────┘
                   │
        ┌──────────┴─────────┐
        │  GoodJob Worker    │
        │  后台任务处理器     │
        └────────────────────┘
```

### 数据持久化

所有重要数据都通过 Docker Volume 持久化:

- `postgres_data`: 数据库数据
- `redis_data`: Redis 持久化
- `storage_data`: 用户上传文件
- `log_data`: 应用日志
- `tmp_data`: 临时文件

---

## ⚙️ 配置说明

### 必填环境变量

在 `.env` 文件中必须配置以下项:

```bash
# 核心配置 (必填)
SECRET_KEY_BASE=<64位随机字符串>     # 使用 openssl rand -hex 64 生成
DB_PASSWORD=<强密码>                 # 数据库密码
REDIS_PASSWORD=<强密码>              # Redis 密码
PUBLIC_HOST=http://your-domain.com   # 应用访问地址
```

### 可选配置

```bash
# 邮件服务 (用于用户注册、密码重置)
EMAIL_SMTP_ADDRESS=smtp.example.com
EMAIL_SMTP_USERNAME=your_email@example.com
EMAIL_SMTP_PASSWORD=your_password

# OAuth 社交登录
GOOGLE_OAUTH_ENABLED=true
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_secret

# 性能调优
RAILS_MAX_THREADS=10                 # Web 线程数
WEB_CONCURRENCY=2                    # Worker 进程数
GOOD_JOB_MAX_THREADS=5               # 后台任务线程数
```

完整配置说明请参考 `.env.example`。

---

## 🔧 运维管理

### 常用命令

```bash
# 服务管理
docker-compose -f docker-compose.production.yml up -d      # 启动
docker-compose -f docker-compose.production.yml down       # 停止
docker-compose -f docker-compose.production.yml restart    # 重启
docker-compose -f docker-compose.production.yml ps         # 状态

# 日志查看
docker-compose -f docker-compose.production.yml logs -f web     # Web 日志
docker-compose -f docker-compose.production.yml logs -f worker  # Worker 日志
docker-compose -f docker-compose.production.yml logs -f db      # 数据库日志

# 数据库操作
docker-compose -f docker-compose.production.yml exec web bundle exec rails db:migrate  # 迁移
docker-compose -f docker-compose.production.yml exec web bundle exec rails console     # 控制台

# 备份与恢复
bash backup/backup.sh    # 执行备份
bash backup/restore.sh   # 恢复数据
```

### 自动备份

添加定时任务实现每日自动备份:

```bash
# 编辑 crontab
crontab -e

# 每天凌晨2点自动备份
0 2 * * * cd /path/to/project && bash backup/backup.sh >> backup/logs/cron.log 2>&1
```

---

## 📊 系统要求

### 最低配置
- CPU: 4 核
- 内存: 8 GB
- 硬盘: 50 GB
- 操作系统: Linux / macOS / Windows (WSL2)

### 推荐配置
- CPU: 8 核或更多
- 内存: 16 GB 或更多
- 硬盘: 100 GB SSD
- 操作系统: Ubuntu 22.04 LTS

### 软件依赖
- Docker Engine 20.10+
- Docker Compose 2.0+

---

## 🔐 安全建议

1. **修改所有默认密码**
   - 数据库密码 (`DB_PASSWORD`)
   - Redis 密码 (`REDIS_PASSWORD`)
   - 管理员登录密码

2. **启用 HTTPS**
   - 配置 SSL 证书
   - 使用 `config/nginx.ssl.production.conf`

3. **配置防火墙**
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

4. **定期备份**
   - 使用自动备份脚本
   - 异地备份重要数据

5. **监控日志**
   ```bash
   # 定期检查错误日志
   docker-compose -f docker-compose.production.yml logs --tail=100 web | grep ERROR
   ```

---

## 📈 性能优化

### 1. 资源限制调整

根据服务器配置调整 `docker-compose.production.yml` 中的资源限制:

```yaml
deploy:
  resources:
    limits:
      cpus: '8'      # 增加 CPU
      memory: 8G     # 增加内存
```

### 2. 并发配置

在 `.env` 中调整:

```bash
RAILS_MAX_THREADS=10      # 单个 worker 线程数
WEB_CONCURRENCY=4         # Worker 进程数 (约等于 CPU 核心数)
```

### 3. 数据库优化

```sql
-- 创建常用索引
CREATE INDEX CONCURRENTLY idx_bookings_user_id ON bookings(user_id);
CREATE INDEX CONCURRENTLY idx_bookings_created_at ON bookings(created_at DESC);
```

### 4. 启用 CDN

配置 Nginx 静态资源缓存或接入第三方 CDN 服务。

---

## 🐛 故障排查

### 问题 1: 服务无法启动

```bash
# 查看详细日志
docker-compose -f docker-compose.production.yml logs

# 检查端口占用
sudo netstat -tlnp | grep -E '3000|5432|6379'

# 检查磁盘空间
df -h
```

### 问题 2: 数据库连接失败

```bash
# 检查数据库状态
docker-compose -f docker-compose.production.yml exec db pg_isready -U travel01

# 测试连接
docker-compose -f docker-compose.production.yml exec web bundle exec rails runner "puts ActiveRecord::Base.connection.execute('SELECT 1')"
```

### 问题 3: Redis 连接失败

```bash
# 测试 Redis
docker-compose -f docker-compose.production.yml exec redis redis-cli -a your_password ping
```

### 问题 4: 内存不足

```bash
# 查看资源使用
docker stats

# 减少并发配置
WEB_CONCURRENCY=1
RAILS_MAX_THREADS=5
```

更多问题请参考 [完整部署指南](docs/DEPLOYMENT_GUIDE.md) 的故障排查章节。

---

## 📚 文档索引

### 快速参考
- [5分钟快速开始](docs/QUICK_DEPLOY.md) - 最快部署方式
- [环境变量配置](.env.example) - 所有可配置项说明

### 详细文档
- [完整部署指南](docs/DEPLOYMENT_GUIDE.md) - 60+ 页详细文档
  - 系统要求
  - 详细部署步骤
  - 配置说明
  - 运维管理
  - 备份与恢复
  - 故障排查
  - 性能优化

### 其他文档
- [项目架构说明](docs/PROJECT_STRUCTURE.md)
- [API 文档](docs/API_GUIDE.md)
- [管理后台指南](docs/ADMIN_GUIDE.md)

---

## 🎯 部署检查清单

部署前请确认:

- [ ] Docker 和 Docker Compose 已安装
- [ ] 已复制并配置 `.env` 文件
- [ ] `SECRET_KEY_BASE` 已设置为64位随机字符串
- [ ] `DB_PASSWORD` 和 `REDIS_PASSWORD` 已设置强密码
- [ ] `PUBLIC_HOST` 已设置为实际访问地址
- [ ] 服务器有足够的磁盘空间 (至少 50GB)
- [ ] 必要的端口已开放 (80, 443, 3000)

部署后请验证:

- [ ] 所有容器都在运行: `docker-compose -f docker-compose.production.yml ps`
- [ ] Web 服务可访问: `curl http://localhost:3000/api/v1/health`
- [ ] 数据库连接正常
- [ ] 管理员可以登录后台
- [ ] 备份脚本可以正常执行

---

## 📞 技术支持

如在部署过程中遇到问题，请提供:

1. 操作系统版本: `uname -a`
2. Docker 版本: `docker --version`
3. 错误日志: `docker-compose -f docker-compose.production.yml logs`
4. 服务状态: `docker-compose -f docker-compose.production.yml ps`

---

## 📄 更新日志

### 2024-01-18
- ✅ 新增生产环境 docker-compose 配置
- ✅ 新增环境变量配置示例
- ✅ 新增一键部署脚本
- ✅ 新增自动备份/恢复脚本
- ✅ 新增 Nginx 配置文件 (HTTP/HTTPS)
- ✅ 新增完整部署文档 (60+ 页)
- ✅ 新增快速开始指南

---

## 📖 相关链接

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [PostgreSQL 官方文档](https://www.postgresql.org/docs/)
- [Redis 官方文档](https://redis.io/documentation)
- [Nginx 官方文档](https://nginx.org/en/docs/)

---

**祝部署顺利！** 🎉

如有任何问题，请参考 [完整部署指南](docs/DEPLOYMENT_GUIDE.md) 或联系技术支持。
