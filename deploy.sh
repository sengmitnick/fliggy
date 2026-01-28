#!/bin/bash

# ===========================================
# 旅游环境01 - 一键部署脚本
# ===========================================
# 使用方式: bash deploy.sh
# ===========================================

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印函数
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 主函数
main() {
    echo "=========================================="
    echo "  旅游环境01 - 商业化部署脚本"
    echo "=========================================="
    echo ""

    # 1. 检查系统依赖
    print_info "步骤 1/9: 检查系统依赖..."
    
    if ! command_exists docker; then
        print_error "Docker 未安装！请先安装 Docker。"
        echo "安装命令: curl -fsSL https://get.docker.com | sh"
        exit 1
    fi
    print_success "Docker 已安装: $(docker --version)"

    if ! command_exists docker-compose; then
        print_error "Docker Compose 未安装！请先安装 Docker Compose。"
        exit 1
    fi
    print_success "Docker Compose 已安装: $(docker-compose --version)"

    # 2. 检查 .env 文件
    print_info "步骤 2/9: 检查环境配置..."

    if [ ! -f .env ]; then
        print_info "从 .env.example 复制环境配置文件..."
        cp .env.example .env
        print_success ".env 文件已创建（使用示例配置）"
        print_info "提示: 如需自定义配置，请编辑 .env 文件"
    else
        print_success ".env 文件已存在"
    fi

    # 3. 选择服务器规格
    print_info "步骤 3/9: 选择服务器规格..."

    echo "请选择部署规格:"
    echo "  1) 8核32G (甲方生产环境，默认)"
    echo "  2) 2核8G (本地测试/展示)"
    read -p "请输入选择 [1-2] (默认: 1): " server_spec

    server_spec=${server_spec:-1}

    case $server_spec in
        1)
            COMPOSE_FILE="docker-compose.production.8core.yml"
            print_success "已选择 8核32G 配置（甲方生产环境）"
            ;;
        2)
            COMPOSE_FILE="docker-compose.production.2core.yml"
            print_success "已选择 2核8G 配置（本地测试）"
            ;;
        *)
            print_error "无效选择"
            exit 1
            ;;
    esac

    # 4. 清理旧数据和容器
    print_info "步骤 4/9: 清理旧数据和容器..."

    print_warning "正在停止现有容器并删除 Volume（清理历史数据）..."
    docker-compose -f $COMPOSE_FILE down -v 2>/dev/null || true
    print_success "旧数据和 Volume 已删除，将重新加载数据包"

    # 5. 创建必要目录
    print_info "步骤 5/9: 创建必要目录..."
    mkdir -p backup ssl log storage
    print_success "目录创建完成"

    # 6. 选择 Nginx 配置
    print_info "步骤 6/9: 配置 Nginx..."

    echo "是否使用 Nginx 反向代理?"
    echo "  1) 不使用 Nginx (直接访问 Rails，默认)"
    echo "  2) 使用 Nginx (需要配置 nginx.conf)"
    read -p "请输入选择 [1-2] (默认: 1): " nginx_choice

    nginx_choice=${nginx_choice:-1}
    USE_NGINX="false"

    case $nginx_choice in
        1)
            print_success "跳过 Nginx，将直接访问 Rails 应用 (端口 5010)"
            USE_NGINX="false"
            ;;
        2)
            USE_NGINX="true"
            if [ -f config/nginx.production.conf ]; then
                cp config/nginx.production.conf config/nginx.conf
                print_success "已配置 Nginx HTTP 模式"
                print_info "提示: 如需 HTTPS，请手动修改 config/nginx.conf"
            else
                print_warning "config/nginx.production.conf 不存在"
                print_warning "将使用默认 Nginx 配置"
            fi
            ;;
        *)
            print_error "无效选择"
            exit 1
            ;;
    esac

    # 7. 登录阿里云镜像仓库并拉取镜像
    print_info "步骤 7/9: 拉取 Docker 镜像..."

    # 阿里云镜像仓库配置
    REGISTRY="qinglion-registry.cn-hangzhou.cr.aliyuncs.com"
    USERNAME="seng@1805254468384588"
    PASSWORD="b6XKKS7hPhQjEC"

    print_info "登录阿里云镜像仓库..."
    echo "$PASSWORD" | docker login --username="$USERNAME" --password-stdin "$REGISTRY"

    if [ $? -eq 0 ]; then
        print_success "镜像仓库登录成功"
    else
        print_error "镜像仓库登录失败"
        exit 1
    fi

    print_info "拉取最新镜像..."
    docker-compose -f $COMPOSE_FILE pull web worker
    print_success "镜像拉取完成"

    # 8. 启动数据库和 Redis，创建 app_user 和运行迁移
    print_info "步骤 8/9: 数据库初始化..."

    # 从 .env 文件读取配置
    if [ -f .env ]; then
        set -a
        source .env
        set +a
    fi

    # 8.1 启动数据库和 Redis
    print_info "启动数据库和 Redis..."
    docker-compose -f $COMPOSE_FILE up -d db redis

    # 8.2 等待数据库就绪
    print_info "等待数据库就绪..."
    MAX_WAIT=60
    WAIT_COUNT=0
    until docker exec travel01_postgres bash -c "PGPASSWORD='${DB_PASSWORD}' psql -U ${DB_USER:-travel01} -d ${DB_NAME:-travel01_production} -c 'SELECT 1;'" >/dev/null 2>&1 || [ $WAIT_COUNT -eq $MAX_WAIT ]; do
        sleep 2
        WAIT_COUNT=$((WAIT_COUNT + 2))
        echo -n "."
    done
    echo ""

    if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
        print_error "数据库连接超时"
        exit 1
    fi
    print_success "数据库已就绪"

    # 8.3 创建 app_user 角色
    print_info "创建 app_user 数据库角色..."
    docker exec -i travel01_postgres bash -c "PGPASSWORD='${DB_PASSWORD}' psql -U ${DB_USER:-travel01} -d ${DB_NAME:-travel01_production}" <<'EOF_SQL'
DO $$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'app_user') THEN
      CREATE ROLE app_user WITH LOGIN NOSUPERUSER;
      RAISE NOTICE 'Created app_user';
   ELSE
      RAISE NOTICE 'app_user already exists';
   END IF;
END $$;
EOF_SQL

    docker exec -i travel01_postgres bash -c "PGPASSWORD='${DB_PASSWORD}' psql -U ${DB_USER:-travel01} -d ${DB_NAME:-travel01_production} -c \"ALTER ROLE app_user WITH PASSWORD '${DB_PASSWORD}';\""
    docker exec -i travel01_postgres bash -c "PGPASSWORD='${DB_PASSWORD}' psql -U ${DB_USER:-travel01} -d ${DB_NAME:-travel01_production} -c \"GRANT CONNECT ON DATABASE ${DB_NAME:-travel01_production} TO app_user;\""
    docker exec -i travel01_postgres bash -c "PGPASSWORD='${DB_PASSWORD}' psql -U ${DB_USER:-travel01} -d ${DB_NAME:-travel01_production} -c \"GRANT USAGE, CREATE ON SCHEMA public TO app_user;\""
    docker exec -i travel01_postgres bash -c "PGPASSWORD='${DB_PASSWORD}' psql -U ${DB_USER:-travel01} -d ${DB_NAME:-travel01_production} -c \"GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;\""
    docker exec -i travel01_postgres bash -c "PGPASSWORD='${DB_PASSWORD}' psql -U ${DB_USER:-travel01} -d ${DB_NAME:-travel01_production} -c \"GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;\""
    docker exec -i travel01_postgres bash -c "PGPASSWORD='${DB_PASSWORD}' psql -U ${DB_USER:-travel01} -d ${DB_NAME:-travel01_production} -c \"ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;\""
    docker exec -i travel01_postgres bash -c "PGPASSWORD='${DB_PASSWORD}' psql -U ${DB_USER:-travel01} -d ${DB_NAME:-travel01_production} -c \"ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO app_user;\""
    docker exec -i travel01_postgres bash -c "PGPASSWORD='${DB_PASSWORD}' psql -U ${DB_USER:-travel01} -d ${DB_NAME:-travel01_production} -c \"ALTER ROLE app_user SET search_path TO public;\""

    if [ $? -eq 0 ]; then
        print_success "app_user 角色创建成功"
    else
        print_error "app_user 角色创建失败"
        exit 1
    fi

    # 8.4 运行数据库迁移和数据初始化（使用一次性容器）
    print_info "运行数据库迁移和数据初始化..."
    ADMIN_DB_URL_VALUE="postgresql://${DB_USER:-travel01}:${DB_PASSWORD}@db:5432/${DB_NAME:-travel01_production}"

    docker-compose -f $COMPOSE_FILE run --rm \
      -e ADMIN_DB_URL="${ADMIN_DB_URL_VALUE}" \
      -e TEMP_DATABASE_URL="${ADMIN_DB_URL_VALUE}" \
      web bash -c "
        echo '开始数据库迁移...' && \
        bundle exec rake db:prepare && \
        echo '✓ 数据库迁移完成' && \
        echo '开始加载数据包...' && \
        bundle exec rake validator:reset_baseline && \
        echo '✓ 数据包加载完成'
      "

    if [ $? -eq 0 ]; then
        print_success "数据库迁移和数据初始化完成"
    else
        print_error "数据库初始化失败"
        exit 1
    fi

    # 8.5 重新授予 app_user 权限（迁移后的表）
    print_info "重新授予 app_user 权限（迁移后的表）..."
    docker exec -i travel01_postgres bash -c "PGPASSWORD='${DB_PASSWORD}' psql -U ${DB_USER:-travel01} -d ${DB_NAME:-travel01_production} -c \"GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;\""
    docker exec -i travel01_postgres bash -c "PGPASSWORD='${DB_PASSWORD}' psql -U ${DB_USER:-travel01} -d ${DB_NAME:-travel01_production} -c \"GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;\""

    if [ $? -eq 0 ]; then
        print_success "app_user 权限更新成功"
    else
        print_error "app_user 权限更新失败"
        exit 1
    fi

    # 9. 启动应用服务并配置安全策略
    print_info "步骤 9/9: 启动应用服务并配置安全策略..."

    # 9.1 启动 web 和 worker（不再自动运行 db:prepare，因为已经在初始化容器中完成）
    print_info "启动应用服务..."
    if [ "$USE_NGINX" = "true" ]; then
        docker-compose -f $COMPOSE_FILE up -d web worker nginx
    else
        docker-compose -f $COMPOSE_FILE up -d web worker
    fi

    # 9.2 等待服务完全启动
    print_info "等待服务完全启动..."
    MAX_WAIT=60
    WAIT_COUNT=0
    until docker-compose -f $COMPOSE_FILE exec -T web /app/bin/rails runner "puts 'ready'" >/dev/null 2>&1 || [ $WAIT_COUNT -eq $MAX_WAIT ]; do
        sleep 2
        WAIT_COUNT=$((WAIT_COUNT + 2))
        echo -n "."
    done
    echo ""

    if [ $WAIT_COUNT -ge $MAX_WAIT ]; then
        print_error "应用启动超时"
        exit 1
    fi
    print_success "应用服务已启动"

    # 9.3 启用 RLS 强制策略
    print_info "启用多会话隔离（RLS FORCE）..."
    ADMIN_DB_URL_VALUE="postgresql://${DB_USER:-travel01}:${DB_PASSWORD}@db:5432/${DB_NAME:-travel01_production}"
    docker-compose -f $COMPOSE_FILE exec -T -e ADMIN_DB_URL="${ADMIN_DB_URL_VALUE}" web bundle exec rake rls:force_enable 2>&1

    if [ $? -eq 0 ]; then
        print_success "RLS 策略已启用"
    else
        print_error "RLS 策略启用失败"
        exit 1
    fi

    # 9.4 创建默认管理员账号
    print_info "创建默认管理员账号..."
    docker-compose -f $COMPOSE_FILE exec -T web /app/bin/rails runner "$(cat <<'RUBY'
admin = Administrator.find_or_initialize_by(name: 'admin')
if admin.new_record?
  admin.password = 'admin'
  admin.password_confirmation = 'admin'
  admin.role = 'super_admin'
  admin.save!
  puts '✓ 管理员账号创建成功'
else
  puts "✓ 管理员已存在: #{admin.name} (#{admin.role})"
end
RUBY
)" 2>&1

    if [ $? -eq 0 ]; then
        print_success "管理员账号就绪"
    else
        print_warning "管理员账号创建失败，请手动创建"
    fi

    print_success "数据和安全策略初始化完成"

    # 完成
    echo ""
    echo "=========================================="
    print_success "部署完成！"
    echo "=========================================="
    echo ""

    # 获取访问地址
    PUBLIC_HOST=$(grep "^PUBLIC_HOST=" .env | cut -d'=' -f2-)
    WEB_PORT=$(grep "^WEB_PORT=" .env | cut -d'=' -f2-)
    WEB_PORT=${WEB_PORT:-5010}

    echo "🌐 访问地址:"
    if [ "$USE_NGINX" = "true" ]; then
        NGINX_HTTP_PORT=$(grep "^NGINX_HTTP_PORT=" .env | cut -d'=' -f2-)
        NGINX_HTTP_PORT=${NGINX_HTTP_PORT:-80}
        echo "   用户端: http://localhost:${NGINX_HTTP_PORT}"
        echo "   管理后台: http://localhost:${NGINX_HTTP_PORT}/admin"
        echo "   API健康检查: http://localhost:${NGINX_HTTP_PORT}/api/v1/health"
    else
        echo "   用户端: http://localhost:${WEB_PORT}"
        echo "   管理后台: http://localhost:${WEB_PORT}/admin"
        echo "   API健康检查: http://localhost:${WEB_PORT}/api/v1/health"
    fi

    echo ""
    echo "🔐 默认管理员账号:"
    echo "   用户名: admin"
    echo "   密码: admin"
    echo "   提示: 首次登录后请及时修改密码"

    echo ""
    echo "📡 验证系统 API (甲方规范):"
    echo "   创建会话: POST http://localhost:${WEB_PORT}/api/tasks/:id/start"
    echo "   运行验证: POST http://localhost:${WEB_PORT}/api/verify/run"
    echo "   验证列表: GET  http://localhost:${WEB_PORT}/api/verify"

    echo ""
    echo "📊 服务状态:"
    docker-compose -f $COMPOSE_FILE ps
    echo ""

    echo "📝 常用命令:"
    echo "   查看日志: docker-compose -f $COMPOSE_FILE logs -f web"
    echo "   停止服务: docker-compose -f $COMPOSE_FILE down"
    echo "   重启服务: docker-compose -f $COMPOSE_FILE restart web"
    echo "   查看数据: docker-compose -f $COMPOSE_FILE exec web bundle exec rails runner 'puts \"Cities: \#{City.count}, Flights: \#{Flight.count}\"'"
    echo ""

    # 验证端口配置
    if [ $WEB_PORT -lt 5001 ] || [ $WEB_PORT -gt 5050 ]; then
        print_warning "注意: WEB_PORT ($WEB_PORT) 不在甲方规范要求的 5001-5050 范围内"
        print_warning "建议修改 .env 中的 WEB_PORT 为 5001-5050 之间的值"
    fi
}

# 执行主函数
main "$@"
