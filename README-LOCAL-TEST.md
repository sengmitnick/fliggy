# 🚀 本地测试快速启动指南

## 问题说明

你遇到的 `travel01_web` 容器不断重启的问题是因为：

**云端镜像配置了 `app_user` 数据库用户，但本地环境使用的是 `travel01` 用户，导致数据库认证失败。**

```
错误信息：password authentication failed for user "app_user"
```

---

## ✅ 解决方案：使用本地测试配置

我已经为你创建了专门的本地测试配置，它会：

1. ✅ **使用本地 Dockerfile 构建镜像**（不依赖阿里云镜像）
2. ✅ **简化数据库配置**（直接使用 PostgreSQL 默认用户）
3. ✅ **独立的端口**（避免冲突：Web=5011, DB=5433, Redis=6380）
4. ✅ **独立的数据卷**（不影响生产环境）
5. ✅ **详细的日志**（debug 级别，方便调试）

---

## 🎯 一键启动

```bash
# 直接运行本地测试部署脚本
bash local-deploy.sh
```

**首次运行需要构建镜像，大约 5-10 分钟，请耐心等待。**

---

## 📱 访问应用

启动完成后，访问以下地址：

| 功能 | 地址 |
|------|------|
| 🌐 用户端 | http://localhost:5011 |
| 🔧 管理后台 | http://localhost:5011/admin |
| 💚 健康检查 | http://localhost:5011/api/v1/health |

### 默认管理员账号

```
用户名: admin
密码: admin
```

---

## 📊 查看服务状态

```bash
# 查看所有容器状态
docker-compose -f docker-compose.local.yml ps

# 查看 Web 日志
docker-compose -f docker-compose.local.yml logs -f web

# 查看 Worker 日志
docker-compose -f docker-compose.local.yml logs -f worker
```

---

## 🛠️ 常用操作

### 停止服务
```bash
docker-compose -f docker-compose.local.yml down
```

### 重启服务
```bash
docker-compose -f docker-compose.local.yml restart web
```

### 完全重建（清除所有数据）
```bash
docker-compose -f docker-compose.local.yml down -v
bash local-deploy.sh
```

### 进入容器调试
```bash
# 进入 Web 容器
docker-compose -f docker-compose.local.yml exec web bash

# 进入 Rails console
docker-compose -f docker-compose.local.yml exec web rails console
```

---

## 🆚 本地测试 vs 生产部署

| 项目 | 生产部署 (`deploy.sh`) | 本地测试 (`local-deploy.sh`) |
|------|----------------------|----------------------------|
| 镜像来源 | 阿里云镜像仓库 | 本地 Dockerfile 构建 |
| 数据库用户 | `app_user` (需额外配置) | `travel01` (简化配置) |
| Web 端口 | 5010 | 5011 |
| DB 端口 | 5432 | 5433 |
| Redis 端口 | 6379 | 6380 |
| 容器前缀 | `travel01_` | `travel01_local_` |
| 适用场景 | 生产环境部署 | 本地开发测试 |

---

## ⚠️ 注意事项

1. **本地测试配置不要用于生产环境**
2. **两个配置可以共存**（使用不同的容器名和端口）
3. **首次构建需要时间**（下载依赖、编译资源）
4. **数据独立存储**（删除本地测试不影响生产数据）

---

## 📚 详细文档

更多详细信息，请查看：
- [本地测试部署指南](docs/local-testing-guide.md)

---

## 🐛 故障排查

### 容器一直重启怎么办？

```bash
# 1. 查看日志找到具体错误
docker-compose -f docker-compose.local.yml logs web

# 2. 检查数据库是否正常
docker-compose -f docker-compose.local.yml ps db

# 3. 完全重建
docker-compose -f docker-compose.local.yml down -v
bash local-deploy.sh
```

### 端口被占用怎么办？

```bash
# 查看哪个进程占用了端口
lsof -i :5011

# 编辑 .env.local 修改端口
vi .env.local
# 然后重启服务
```

### 数据库连接失败怎么办？

```bash
# 测试数据库连接
docker-compose -f docker-compose.local.yml exec db psql -U travel01 -d travel01_production -c "SELECT 1;"

# 如果失败，检查 .env.local 中的数据库配置
cat .env.local | grep DB_
```

---

## ✨ 开始使用

现在你可以运行：

```bash
bash local-deploy.sh
```

然后访问 http://localhost:5011 开始测试！

有问题随时查看日志：
```bash
docker-compose -f docker-compose.local.yml logs -f
```
