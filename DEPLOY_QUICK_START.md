# 快速部署指南

## 一键部署（首次部署）

```bash
bash deploy.sh
```

## 快速更新（代码/数据库更新）

```bash
bash update.sh
```

适用场景：
- 代码更新
- 数据库 schema 变更（新增迁移文件）
- 配置文件修改
- Gemfile 依赖更新

## 部署选项说明

### 步骤 3: 选择服务器规格

```
1) 8核32G (甲方生产环境，默认) ← 推荐给甲方
2) 2核8G (本地测试/展示)
```

- **默认选项 1**: 使用 `docker-compose.production.8core.yml`
  - 适用于 8核32G 服务器
  - 甲方生产环境部署
  - 资源配置：
    - Web: 3 CPU cores, 8GB RAM
    - PostgreSQL: 2 CPU cores, 6GB RAM
    - Redis: 1 CPU core, 2GB RAM
    - Worker: 1 CPU core, 4GB RAM

- **选项 2**: 使用 `docker-compose.production.2core.yml`
  - 适用于 2核8G 服务器
  - 本地测试/演示环境
  - 资源配置：
    - Web: 0.8 CPU cores, 3GB RAM
    - PostgreSQL: 0.5 CPU cores, 1.5GB RAM
    - Redis: 0.3 CPU cores, 512MB RAM
    - Worker: 0.3 CPU cores, 1.5GB RAM

### 步骤 5: Nginx 配置

```
1) 不使用 Nginx (直接访问 Rails，默认) ← 推荐
2) 使用 Nginx (需要配置 nginx.conf)
```

- **默认选项 1**: 直接访问 Rails 应用
  - 访问端口: 5010 (符合甲方规范 5001-5050)
  - 适用场景: 单应用部署、API 服务
  - 优势: 配置简单、调试方便

- **选项 2**: 使用 Nginx 反向代理
  - 访问端口: 80/443
  - 适用场景: 需要 SSL、静态文件加速、多应用反向代理
  - 需要手动配置 `config/nginx.conf`

## 部署后访问

### 默认配置（8核32G + 不使用 Nginx）

- **用户端**: http://localhost:5010
- **管理后台**: http://localhost:5010/admin
- **API 健康检查**: http://localhost:5010/api/v1/health

### 验证系统 API (甲方规范)

```bash
# 获取验证器列表
curl http://localhost:5010/api/verify

# 创建训练会话
curl -X POST http://localhost:5010/api/tasks/book_flight/start

# 运行验证
curl -X POST http://localhost:5010/api/verify/run \
  -H "Content-Type: application/json" \
  -d '{"task_id": "book_flight", "session_id": "your-session-id"}'
```

## 常用命令

```bash
# 8核32G 配置
COMPOSE_FILE=docker-compose.production.8core.yml

# 2核8G 配置
# COMPOSE_FILE=docker-compose.production.2core.yml

# 查看服务状态
docker-compose -f $COMPOSE_FILE ps

# 查看日志
docker-compose -f $COMPOSE_FILE logs -f web

# 重启服务
docker-compose -f $COMPOSE_FILE restart web

# 停止服务
docker-compose -f $COMPOSE_FILE down

# 进入 Rails 控制台
docker-compose -f $COMPOSE_FILE exec web bundle exec rails console

# 查看数据统计
docker-compose -f $COMPOSE_FILE exec web bundle exec rails runner \
  'puts "Cities: #{City.count}, Flights: #{Flight.count}, Hotels: #{Hotel.count}"'
```

## 管理后台

### 默认管理员账号

部署脚本会**自动创建默认管理员账号**：

- **用户名**: admin
- **密码**: admin
- **角色**: super_admin

⚠️ **重要**: 首次登录后请立即修改密码！

### 访问管理后台

- **URL**: http://localhost:5010/admin
- **功能**: 管理用户、订单、航班、酒店等数据

### 修改管理员密码

登录后台后，点击右上角账号 → 修改密码

或通过命令行修改：

```bash
docker-compose -f docker-compose.production.8core.yml exec web bundle exec rails runner \
  "admin = Administrator.find_by(name: 'admin'); admin.update!(password: 'NewPassword123', password_confirmation: 'NewPassword123')"
```

### 创建其他管理员

```bash
docker-compose -f docker-compose.production.8core.yml exec web bundle exec rails runner \
  "Administrator.create!(name: 'username', password: 'password', password_confirmation: 'password', role: 'admin')"
```

**注意**: 管理后台仅用于数据管理，不应包含业务逻辑。

## 环境变量配置

关键配置项（`.env` 文件）：

```bash
# 应用端口 (必须在 5001-5050 范围内，符合甲方规范)
WEB_PORT=5010

# 数据库密码
DB_PASSWORD=your_secure_password

# Redis 密码
REDIS_PASSWORD=your_redis_password

# Rails 密钥
SECRET_KEY_BASE=your_secret_key

# 公开访问地址
PUBLIC_HOST=http://your-domain.com:5010
```

## 数据包说明

首次启动时会自动加载所有数据包：

- **140 个城市** (北京、上海、深圳...)
- **152 个目的地**
- **42 个航班**
- **9 个境外品牌** + **9 个境外商店** + **13 个优惠券**
- **酒店、汽车租赁、巴士票务、深度游** 等测试数据

查看数据加载日志：

```bash
docker-compose -f docker-compose.production.8core.yml logs web | grep "加载\|Created"
```

## 数据库相关

### 自动迁移机制

**容器启动时自动执行** `rails db:prepare`，会智能处理：

1. **新环境部署**
   - 自动创建数据库
   - 运行所有迁移文件
   - 加载数据包（data_version=0）

2. **代码更新场景**
   - 自动运行新的迁移文件
   - 保留现有数据
   - 不重复加载数据包

3. **无变更场景**
   - 检测到数据库已是最新版本
   - 跳过所有操作，直接启动

### 手动运行迁移（不推荐，仅调试用）

```bash
# 进入容器
docker-compose -f docker-compose.production.8core.yml exec web bash

# 查看迁移状态
rails db:migrate:status

# 手动运行迁移
rails db:migrate

# 回滚迁移
rails db:rollback
```

## 故障排查

### 服务一直重启

查看详细日志：
```bash
docker-compose -f docker-compose.production.8core.yml logs web --tail=100
```

### 端口冲突

修改 `.env` 中的 `WEB_PORT`，然后重新部署：
```bash
docker-compose -f docker-compose.production.8core.yml down
bash deploy.sh
```

### 数据未加载

手动触发数据包加载：
```bash
docker-compose -f docker-compose.production.8core.yml exec web \
  bundle exec rails runner \
  "Dir.glob(Rails.root.join('app/validators/support/data_packs/v1/*.rb')).sort.each { |f| load f }"
```

## 甲方环境交付

1. 确保 `.env` 中 `WEB_PORT` 在 5001-5050 范围
2. 选择 **8核32G 配置**（默认）
3. 选择 **不使用 Nginx**（默认）
4. 验证 API 端点可访问：
   - `GET /api/v1/health`
   - `POST /api/tasks/:id/start`
   - `POST /api/verify/run`

详细规范参见：`手机应用环境交付规范.md`
