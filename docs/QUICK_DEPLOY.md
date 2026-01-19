# 飞猪旅游平台 - 快速开始指南

## 🚀 5分钟快速部署

### 前提条件

确保已安装:
- Docker 20.10+
- Docker Compose 2.0+

### 一键部署

```bash
# 1. 进入项目目录
cd /path/to/fliggy

# 2. 赋予执行权限
chmod +x deploy.sh

# 3. 执行一键部署
bash deploy.sh
```

脚本会自动完成以下任务:
1. ✅ 检查系统依赖
2. ✅ 配置环境变量
3. ✅ 创建必要目录
4. ✅ 配置 Nginx
5. ✅ 构建 Docker 镜像
6. ✅ 启动所有服务
7. ✅ 初始化数据库
8. ✅ 创建管理员账号

---

## 📋 手动部署步骤

如果需要更精细的控制，可按以下步骤手动部署:

### 1. 配置环境变量

```bash
# 复制示例配置
cp .env.example .env

# 编辑配置文件
nano .env
```

**必填配置项:**

```bash
# 生成密钥: openssl rand -hex 64
SECRET_KEY_BASE=your_64_char_random_string

# 设置强密码
DB_PASSWORD=your_strong_db_password
REDIS_PASSWORD=your_strong_redis_password

# 设置访问地址
PUBLIC_HOST=http://your-domain.com
```

### 2. 启动服务

```bash
# 构建镜像
docker-compose -f docker-compose.production.yml build

# 启动服务
docker-compose -f docker-compose.production.yml up -d

# 查看状态
docker-compose -f docker-compose.production.yml ps
```

### 3. 初始化数据库

```bash
# 创建数据库
docker-compose -f docker-compose.production.yml exec web bundle exec rails db:create

# 执行迁移
docker-compose -f docker-compose.production.yml exec web bundle exec rails db:migrate

# (可选) 加载种子数据
docker-compose -f docker-compose.production.yml exec web bundle exec rails db:seed
```

### 4. 创建管理员

```bash
# 进入 Rails 控制台
docker-compose -f docker-compose.production.yml exec web bundle exec rails console

# 创建管理员账号
Administrator.create!(
  email: 'admin@example.com',
  password: 'Admin123456!',
  password_confirmation: 'Admin123456!'
)
```

### 5. 访问应用

- **用户端**: http://localhost:3000
- **管理后台**: http://localhost:3000/admin

---

## 🔧 常用命令速查

### 服务管理

```bash
# 启动服务
docker-compose -f docker-compose.production.yml up -d

# 停止服务
docker-compose -f docker-compose.production.yml down

# 重启服务
docker-compose -f docker-compose.production.yml restart

# 查看状态
docker-compose -f docker-compose.production.yml ps

# 查看日志
docker-compose -f docker-compose.production.yml logs -f web
```

### 数据库操作

```bash
# 进入数据库
docker-compose -f docker-compose.production.yml exec db psql -U fliggy fliggy_production

# 执行迁移
docker-compose -f docker-compose.production.yml exec web bundle exec rails db:migrate

# 备份数据库
bash backup/backup.sh

# 恢复数据库
bash backup/restore.sh
```

### 应用管理

```bash
# 进入控制台
docker-compose -f docker-compose.production.yml exec web bundle exec rails console

# 清理缓存
docker-compose -f docker-compose.production.yml exec web bundle exec rails cache:clear

# 查看路由
docker-compose -f docker-compose.production.yml exec web bundle exec rails routes
```

---

## 📦 服务说明

| 服务 | 端口 | 说明 |
|------|------|------|
| web | 3000 | Rails 主应用 |
| db | 5432 | PostgreSQL 数据库 |
| redis | 6379 | Redis 缓存 |
| worker | - | 后台任务处理 |
| nginx | 80/443 | 反向代理 (可选) |

---

## 🔐 默认账号

首次部署后，可使用以下账号登录:

### 管理员账号
- 邮箱: admin@example.com
- 密码: Admin123456! (建议首次登录后修改)

---

## 📊 健康检查

```bash
# 检查所有服务状态
docker-compose -f docker-compose.production.yml ps

# 测试 Web 服务
curl http://localhost:3000/api/v1/health

# 测试数据库连接
docker-compose -f docker-compose.production.yml exec web bundle exec rails runner "puts ActiveRecord::Base.connection.execute('SELECT 1').first"

# 测试 Redis 连接
docker-compose -f docker-compose.production.yml exec redis redis-cli -a your_redis_password ping
```

---

## 🛡️ 安全建议

1. **修改默认密码**
   - 数据库密码
   - Redis 密码
   - 管理员密码

2. **启用 HTTPS**
   - 使用 Let's Encrypt 免费证书
   - 配置 SSL 证书

3. **防火墙配置**
   ```bash
   # 仅允许必要端口
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

4. **定期备份**
   ```bash
   # 添加定时任务
   crontab -e
   
   # 每天凌晨2点备份
   0 2 * * * /path/to/backup/backup.sh
   ```

---

## 🐛 故障排查

### 服务无法启动

```bash
# 查看详细日志
docker-compose -f docker-compose.production.yml logs

# 检查端口占用
sudo netstat -tlnp | grep -E '3000|5432|6379'
```

### 数据库连接失败

```bash
# 检查数据库状态
docker-compose -f docker-compose.production.yml exec db pg_isready -U fliggy

# 查看数据库日志
docker-compose -f docker-compose.production.yml logs db
```

### 内存不足

```bash
# 查看资源使用
docker stats

# 调整配置
nano .env
# 减少 WEB_CONCURRENCY 和 RAILS_MAX_THREADS
```

---

## 📚 更多文档

- [完整部署指南](DEPLOYMENT_GUIDE.md)
- [项目结构说明](PROJECT_STRUCTURE.md)
- [API 文档](API_GUIDE.md)
- [管理后台指南](ADMIN_GUIDE.md)

---

## 💡 获取帮助

如遇到问题，请:

1. 查看日志: `docker-compose -f docker-compose.production.yml logs -f`
2. 参考 [完整部署指南](DEPLOYMENT_GUIDE.md)
3. 检查 [故障排查](#故障排查) 章节

---

**祝部署顺利！** 🎉
