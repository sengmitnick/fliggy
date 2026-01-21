# 旅游环境01 (Travel Platform)

一个功能完善的在线旅游预订平台，基于 Rails 7.2 + PostgreSQL + Redis 构建。

## 🚀 快速开始

### 开发环境部署

**环境要求:**
- Ruby 3.3.5+
- Rails 7.2+
- PostgreSQL 16+
- Node.js 18+
- Redis 7+ (可选)

**安装依赖:**

```bash
# 安装 Ruby 依赖
bundle install

# 安装前端依赖
npm install

# 配置数据库和应用
cp config/database.yml.example config/database.yml
cp config/application.yml.example config/application.yml

# 初始化数据库
bin/rails db:setup

# 启动开发服务器
bin/dev
```

访问: http://localhost:3000

---

## 🐳 商业化本地部署 (Docker)

### 方式一: 一键部署 (推荐)

```bash
# 赋予执行权限
chmod +x deploy.sh

# 运行一键部署脚本
bash deploy.sh
```

脚本会自动完成:
- ✅ 检查系统依赖
- ✅ 配置环境变量
- ✅ 构建 Docker 镜像
- ✅ 启动所有服务
- ✅ 初始化数据库
- ✅ 创建管理员账号

### 方式二: 手动部署

```bash
# 1. 配置环境变量
cp .env.example .env
nano .env  # 编辑必填配置项:
# - SECRET_KEY_BASE (使用 openssl rand -hex 64 生成)
# - DB_PASSWORD
# - REDIS_PASSWORD
# - PUBLIC_HOST

# 2. 启动服务
docker-compose -f docker-compose.production.yml up -d

# 3. 初始化数据库
docker-compose -f docker-compose.production.yml exec web bundle exec rails db:create db:migrate

# 4. 创建管理员
docker-compose -f docker-compose.production.yml exec web bundle exec rails console
# Administrator.create!(email: 'admin@example.com', password: 'Admin123456!', password_confirmation: 'Admin123456!')
```

### 部署文档

- 📖 [完整部署指南](docs/DEPLOYMENT_GUIDE.md) - 60+ 页详细文档 (系统要求、配置说明、运维管理、故障排查)
- ⚡ [5分钟快速开始](docs/QUICK_DEPLOY.md) - 快速部署指南
- 🐳 [Docker 部署方案](docs/DOCKER_DEPLOYMENT.md) - 商业化部署总结

### 服务架构

```
Nginx (可选) → Rails Web (Port 3000) → PostgreSQL (Port 5432)
                                      → Redis (Port 6379)
                   GoodJob Worker
```

### 常用命令

```bash
# 服务管理
docker-compose -f docker-compose.production.yml up -d      # 启动
docker-compose -f docker-compose.production.yml down       # 停止
docker-compose -f docker-compose.production.yml restart    # 重启
docker-compose -f docker-compose.production.yml ps         # 状态

# 日志查看
docker-compose -f docker-compose.production.yml logs -f web

# 数据库操作
docker-compose -f docker-compose.production.yml exec web bundle exec rails db:migrate
docker-compose -f docker-compose.production.yml exec web bundle exec rails console

# 备份与恢复
bash backup/backup.sh    # 执行备份
bash backup/restore.sh   # 恢复数据
```

---

## 📊 系统要求

### 开发环境
- Ruby 3.3.5+
- PostgreSQL 16+
- Node.js 18+

### 生产环境 (Docker)
- **最低配置**: 4核CPU, 8GB内存, 50GB硬盘
- **推荐配置**: 8核CPU, 16GB内存, 100GB SSD
- **软件依赖**: Docker Engine 20.10+, Docker Compose 2.0+

---

## 🎯 功能特性

### 核心功能
- ✈️ 机票预订 (国内/国际航班)
- 🏨 酒店预订 (含套餐、特价房)
- 🚄 火车票预订
- 🚌 汽车票预订
- 🎫 景点门票预订
- 🧳 跟团游/自由行
- 🚗 租车服务
- 🌐 出境游服务 (签证、上网、接送机)

### 技术特性
- 🔐 完整的用户认证系统 (支持 OAuth 社交登录)
- 💳 支付集成 (Stripe)
- 📧 邮件服务 (SMTP)
- 🔄 实时通信 (ActionCable)
- 📱 PWA 支持
- 🌍 国际化 (中英文)
- 🎨 响应式设计 (Tailwind CSS)
- 📊 管理后台
- 🔍 全文搜索
- 📈 数据分析

---

## 🛠️ 技术栈

### 后端
- **框架**: Ruby on Rails 7.2
- **数据库**: PostgreSQL 16
- **缓存**: Redis 7
- **队列**: GoodJob
- **Web 服务器**: Puma
- **认证**: Devise + OmniAuth

### 前端
- **CSS**: Tailwind CSS v3
- **JavaScript**: Stimulus + Turbo (Hotwire)
- **构建**: esbuild + cssbundling-rails

### DevOps
- **容器化**: Docker + Docker Compose
- **反向代理**: Nginx
- **部署**: 一键部署脚本
- **备份**: 自动备份脚本

---

## 📁 项目结构

```
project/
├── app/                          # 应用核心代码
│   ├── controllers/              # 控制器
│   ├── models/                   # 模型
│   ├── views/                    # 视图
│   ├── javascript/               # 前端 JavaScript (Stimulus)
│   └── assets/                   # 静态资源
├── config/                       # 配置文件
│   ├── database.yml.example      # 数据库配置示例
│   ├── application.yml.example   # 应用配置示例
│   ├── nginx.production.conf     # Nginx HTTP 配置
│   └── nginx.ssl.production.conf # Nginx HTTPS 配置
├── docs/                         # 文档目录
│   ├── DEPLOYMENT_GUIDE.md       # 完整部署指南
│   ├── QUICK_DEPLOY.md           # 快速部署指南
│   ├── DOCKER_DEPLOYMENT.md      # Docker 部署方案
│   ├── API_GUIDE.md              # API 文档
│   └── ADMIN_GUIDE.md            # 管理后台指南
├── backup/                       # 备份脚本
│   ├── backup.sh                 # 自动备份脚本
│   └── restore.sh                # 数据恢复脚本
├── docker-compose.yml            # 开发环境 Docker 配置
├── docker-compose.production.yml # 生产环境 Docker 配置
├── .env.example                  # 环境变量配置示例
├── deploy.sh                     # 一键部署脚本
├── Dockerfile                    # Docker 镜像构建文件
└── README.md                     # 本文档
```

详细架构说明请参考: [项目结构文档](docs/PROJECT_STRUCTURE.md)

---

## 🔐 管理后台

访问地址: `/admin`

**默认账号:**
- 用户名: `admin@example.com`
- 密码: `Admin123456!`

⚠️ **生产环境请务必修改默认密码！**

**管理功能:**
- 用户管理
- 订单管理
- 航班/酒店/门票管理
- 数据统计
- 系统配置

---

## 🧪 测试

```bash
# 运行所有测试
bundle exec rake test

# 运行单个测试文件
bundle exec rspec spec/requests/flights_spec.rb

# 运行 Stimulus 验证
bundle exec rspec spec/javascript/stimulus_validation_spec.rb

# 验证 ERB HTML 结构
bin/validate_erb_html
```

---

## 📖 文档索引

### 部署相关
- [完整部署指南](docs/DEPLOYMENT_GUIDE.md) - 生产环境部署详细步骤
- [快速部署指南](docs/QUICK_DEPLOY.md) - 5分钟快速开始
- [Docker 部署方案](docs/DOCKER_DEPLOYMENT.md) - 商业化部署总结

### 开发相关
- [项目结构说明](docs/PROJECT_STRUCTURE.md) - 项目架构和目录说明
- [API 文档](docs/API_GUIDE.md) - API 接口说明
- [管理后台指南](docs/ADMIN_GUIDE.md) - 后台功能使用说明

---

## 🔧 开发工具

### 代码生成器

```bash
# 批量生成模型
rails g models product name:string:default=Untitled price:decimal:default=0 + category name:string

# 生成控制器
rails g controller products index show --auth

# 生成 Stimulus 控制器
rails g stimulus_controller product_form

# 生成后台 CRUD
rails g admin_crud product

# 生成服务类
rails g service payment_processor
```

### 实用工具

```bash
# 获取开发用 token
rails dev:token[test@example.com]

# 验证 ERB HTML
bin/validate_erb_html app/views/flights/index.html.erb

# 查看路由
rails routes | grep flights
```

---

## 🚦 开发规范

本项目遵循以下规范:

1. **前端开发**: 使用 Stimulus controllers，禁止内联 JavaScript
2. **样式系统**: 使用 Tailwind CSS v3 和语义化 tokens
3. **Turbo Stream**: 优先使用 HTML 渲染，局部更新使用 Turbo Stream
4. **测试要求**: 所有功能必须通过 `rake test`
5. **代码质量**: 遵循 Fail Fast 原则，禁止静默失败

详细规范请参考: `.clackyrules` 文件

---

## 🤝 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📄 许可证

本项目仅供商业化部署使用，版权归开发团队所有。

---

## 📞 技术支持

如在使用过程中遇到问题:

1. 查看 [完整部署指南](docs/DEPLOYMENT_GUIDE.md) 故障排查章节
2. 查看 [快速部署指南](docs/QUICK_DEPLOY.md) 常见问题
3. 提供以下信息联系技术支持:
   - 操作系统版本
   - Docker 版本
   - 错误日志
   - 服务状态

---

## 🎉 更新日志

### v2.0.0 (2024-01-18)
- ✅ 新增完整的 Docker 商业化部署方案
- ✅ 新增一键部署脚本
- ✅ 新增自动备份/恢复功能
- ✅ 新增 Nginx 配置 (HTTP/HTTPS)
- ✅ 新增 60+ 页完整部署文档
- ✅ 新增环境变量配置管理

### v1.0.0 (2023-12-15)
- ✅ 初始版本发布
- ✅ 完整的旅游预订功能
- ✅ 用户认证系统
- ✅ 管理后台
- ✅ 响应式设计

---

**祝使用愉快！** 🎉
