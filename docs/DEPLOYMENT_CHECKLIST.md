# 飞猪旅游平台 - 商业化部署检查清单

## ✅ 部署前检查

### 1. 系统环境检查

- [ ] 服务器已安装 Docker Engine 20.10+
  ```bash
  docker --version
  ```

- [ ] 服务器已安装 Docker Compose 2.0+
  ```bash
  docker-compose --version
  ```

- [ ] 服务器满足最低配置要求
  - CPU: 4 核或更多
  - 内存: 8 GB 或更多
  - 硬盘: 50 GB 可用空间

- [ ] 必要的端口未被占用
  ```bash
  sudo netstat -tlnp | grep -E '3000|5432|6379|80|443'
  ```

### 2. 文件准备

- [ ] 项目代码已上传到服务器
- [ ] 已复制环境变量配置文件
  ```bash
  cp .env.example .env
  ```

- [ ] 已配置环境变量 (必填项)
  - [ ] `SECRET_KEY_BASE` - 使用 `openssl rand -hex 64` 生成
  - [ ] `DB_PASSWORD` - 设置强密码
  - [ ] `REDIS_PASSWORD` - 设置强密码
  - [ ] `PUBLIC_HOST` - 设置实际访问地址

- [ ] (可选) 已配置 SSL 证书
  - [ ] 证书文件放置在 `./ssl/` 目录
  - [ ] 证书文件包括: `fullchain.pem` 和 `privkey.pem`

### 3. 网络配置

- [ ] 防火墙已配置
  ```bash
  sudo ufw allow 80/tcp
  sudo ufw allow 443/tcp
  sudo ufw enable
  ```

- [ ] DNS 已正确配置 (如果使用域名)
  ```bash
  nslookup your-domain.com
  ```

### 4. 权限设置

- [ ] 部署脚本有执行权限
  ```bash
  chmod +x deploy.sh backup/backup.sh backup/restore.sh
  ```

- [ ] 当前用户在 docker 组中
  ```bash
  groups | grep docker
  ```

---

## 🚀 部署步骤检查

### 1. 配置验证

- [ ] 环境变量配置正确
  ```bash
  cat .env | grep -E 'SECRET_KEY_BASE|DB_PASSWORD|REDIS_PASSWORD|PUBLIC_HOST'
  ```

- [ ] 配置文件语法正确
  ```bash
  docker-compose -f docker-compose.production.yml config
  ```

### 2. 服务启动

- [ ] 镜像构建成功
  ```bash
  docker-compose -f docker-compose.production.yml build
  ```

- [ ] 所有服务已启动
  ```bash
  docker-compose -f docker-compose.production.yml up -d
  docker-compose -f docker-compose.production.yml ps
  ```

- [ ] 所有容器状态为 healthy 或 running
  ```bash
  docker ps | grep fliggy
  ```

### 3. 数据库初始化

- [ ] 数据库已创建
  ```bash
  docker-compose -f docker-compose.production.yml exec web bundle exec rails db:create
  ```

- [ ] 数据库迁移完成
  ```bash
  docker-compose -f docker-compose.production.yml exec web bundle exec rails db:migrate
  ```

- [ ] (可选) 种子数据已加载
  ```bash
  docker-compose -f docker-compose.production.yml exec web bundle exec rails db:seed
  ```

### 4. 管理员账号

- [ ] 管理员账号已创建
  ```bash
  docker-compose -f docker-compose.production.yml exec web bundle exec rails console
  # Administrator.create!(email: 'admin@example.com', password: 'Admin123456!', password_confirmation: 'Admin123456!')
  ```

- [ ] 管理员可以登录后台 `/admin`

---

## ✅ 部署后验证

### 1. 服务可用性检查

- [ ] Web 服务响应正常
  ```bash
  curl -I http://localhost:3000
  # 应返回 HTTP/2 200
  ```

- [ ] 健康检查接口正常
  ```bash
  curl http://localhost:3000/api/v1/health
  # 应返回 {"status":"ok"}
  ```

- [ ] 首页可以正常访问
  ```bash
  curl http://localhost:3000/
  # 应返回 HTML 内容
  ```

### 2. 数据库连接检查

- [ ] 数据库连接正常
  ```bash
  docker-compose -f docker-compose.production.yml exec db pg_isready -U fliggy
  # 应返回: accepting connections
  ```

- [ ] Rails 可以连接数据库
  ```bash
  docker-compose -f docker-compose.production.yml exec web bundle exec rails runner "puts ActiveRecord::Base.connection.execute('SELECT 1').first"
  # 应输出: {"?column?"=>1}
  ```

### 3. Redis 连接检查

- [ ] Redis 服务正常
  ```bash
  docker-compose -f docker-compose.production.yml exec redis redis-cli -a your_redis_password ping
  # 应返回: PONG
  ```

- [ ] ActionCable 可以连接 Redis
  ```bash
  docker-compose -f docker-compose.production.yml exec web bundle exec rails runner "puts ActionCable.server.pubsub.ping"
  ```

### 4. 后台任务检查

- [ ] GoodJob worker 正常运行
  ```bash
  docker-compose -f docker-compose.production.yml logs worker | tail -20
  # 应看到 "GoodJob started" 相关日志
  ```

### 5. 日志检查

- [ ] Web 服务无错误日志
  ```bash
  docker-compose -f docker-compose.production.yml logs web | grep -i error
  ```

- [ ] Worker 服务无错误日志
  ```bash
  docker-compose -f docker-compose.production.yml logs worker | grep -i error
  ```

- [ ] 数据库无错误日志
  ```bash
  docker-compose -f docker-compose.production.yml logs db | grep -i error
  ```

### 6. 功能验证

- [ ] 用户可以访问首页
- [ ] 用户可以注册/登录
- [ ] 管理员可以登录后台
- [ ] 搜索功能正常
- [ ] 订单创建功能正常

### 7. 性能检查

- [ ] 页面加载时间正常 (< 3秒)
  ```bash
  curl -o /dev/null -s -w "Total time: %{time_total}s\n" http://localhost:3000/
  ```

- [ ] 容器资源占用正常
  ```bash
  docker stats --no-stream
  ```

---

## 🔧 安全加固检查

### 1. 密码安全

- [ ] 数据库密码已修改 (不使用默认密码)
- [ ] Redis 密码已修改 (不使用默认密码)
- [ ] 管理员密码已修改 (不使用 Admin123456!)
- [ ] SECRET_KEY_BASE 已使用随机值 (不使用示例值)

### 2. 网络安全

- [ ] 防火墙已启用
- [ ] 仅开放必要的端口 (80, 443)
- [ ] 数据库端口未对外开放 (5432)
- [ ] Redis 端口未对外开放 (6379)

### 3. HTTPS 配置

- [ ] (生产环境) 已启用 HTTPS
- [ ] (生产环境) SSL 证书有效
- [ ] (生产环境) HTTP 自动重定向到 HTTPS
- [ ] (生产环境) HSTS 已启用

### 4. 备份配置

- [ ] 备份脚本可以正常执行
  ```bash
  bash backup/backup.sh
  ```

- [ ] 备份文件已生成
  ```bash
  ls -lh backup/database/ backup/storage/
  ```

- [ ] (推荐) 已配置定时备份
  ```bash
  crontab -l | grep backup.sh
  ```

---

## 📊 监控配置检查

### 1. 日志管理

- [ ] 日志目录已挂载
  ```bash
  docker volume inspect fliggy_log_data
  ```

- [ ] 日志可以正常写入
  ```bash
  docker-compose -f docker-compose.production.yml exec web ls -lh log/
  ```

- [ ] (推荐) 已配置日志轮转

### 2. 资源监控

- [ ] 可以查看容器资源使用情况
  ```bash
  docker stats
  ```

- [ ] (推荐) 已配置资源告警

### 3. 健康检查

- [ ] Docker 健康检查已配置
  ```bash
  docker inspect fliggy_web | grep -A 5 '"Health"'
  ```

- [ ] 健康检查状态正常

---

## 📝 文档确认

- [ ] 已阅读 [完整部署指南](docs/DEPLOYMENT_GUIDE.md)
- [ ] 已阅读 [快速部署指南](docs/QUICK_DEPLOY.md)
- [ ] 已保存常用命令
- [ ] 已记录管理员账号信息
- [ ] 已记录数据库连接信息

---

## 🎯 可选优化项

### 性能优化

- [ ] 已调整并发配置
  - `RAILS_MAX_THREADS`
  - `WEB_CONCURRENCY`
  - `GOOD_JOB_MAX_THREADS`

- [ ] 已配置 CDN (如需要)
- [ ] 已优化数据库索引
- [ ] 已配置静态资源缓存

### 高可用配置

- [ ] 已配置数据库主从复制 (如需要)
- [ ] 已配置 Redis Sentinel (如需要)
- [ ] 已配置负载均衡 (如需要)

### 监控告警

- [ ] 已接入监控系统 (如 Prometheus, Grafana)
- [ ] 已配置告警规则
- [ ] 已配置通知渠道

---

## 📞 支持联系

如检查过程中发现问题:

1. 查看 [故障排查文档](docs/DEPLOYMENT_GUIDE.md#故障排查)
2. 检查服务日志: `docker-compose -f docker-compose.production.yml logs -f`
3. 联系技术支持并提供:
   - 系统信息: `uname -a`
   - Docker 版本: `docker --version`
   - 服务状态: `docker-compose -f docker-compose.production.yml ps`
   - 错误日志

---

## ✅ 完成确认

所有检查项完成后，在此签字确认:

- **部署人员**: ________________
- **审核人员**: ________________
- **部署时间**: ________________
- **服务地址**: ________________

---

**祝部署成功！** 🎉
