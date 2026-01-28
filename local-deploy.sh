#!/bin/bash

# ===========================================
# 本地测试部署脚本
# ===========================================
# 使用方式: bash local-deploy.sh
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

# 主函数
main() {
    echo "=========================================="
    echo "  旅游环境01 - 本地测试部署"
    echo "=========================================="
    echo ""

    # 1. 检查 Docker
    print_info "步骤 1/6: 检查 Docker..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装！"
        exit 1
    fi
    print_success "Docker 已安装"

    # 2. 检查环境文件
    print_info "步骤 2/6: 检查环境配置..."
    if [ ! -f .env.local ]; then
        print_warning ".env.local 不存在，将使用默认配置"
        ENV_FILE=""
    else
        print_success ".env.local 已存在"
        ENV_FILE="--env-file .env.local"
    fi

    # 3. 清理旧容器和数据
    print_info "步骤 3/6: 清理旧容器和数据..."
    print_warning "正在停止并删除旧容器..."
    docker-compose -f docker-compose.local.yml down -v 2>/dev/null || true
    print_success "旧容器和数据已清理"

    # 4. 构建镜像
    print_info "步骤 4/6: 构建 Docker 镜像（本地构建，可能需要几分钟）..."
    docker-compose -f docker-compose.local.yml $ENV_FILE build --no-cache
    print_success "镜像构建完成"

    # 5. 启动服务
    print_info "步骤 5/6: 启动服务..."
    docker-compose -f docker-compose.local.yml $ENV_FILE up -d
    print_success "服务已启动"

    # 等待服务启动
    print_info "等待服务完全启动..."
    echo "   自动执行: rails db:prepare (创建数据库 + 运行迁移)"
    sleep 25

    # 6. 创建管理员账号
    print_info "步骤 6/6: 创建管理员账号..."
    docker-compose -f docker-compose.local.yml exec -T web /app/bin/rails runner "$(cat <<'RUBY'
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
)" 2>/dev/null || print_warning "应用尚未完全启动，请稍后手动创建管理员"

    # 完成
    echo ""
    echo "=========================================="
    print_success "本地测试环境部署完成！"
    echo "=========================================="
    echo ""

    # 获取端口配置
    WEB_PORT=5011
    if [ -f .env.local ]; then
        WEB_PORT=$(grep "^WEB_PORT=" .env.local | cut -d'=' -f2- || echo "5011")
    fi

    echo "🌐 访问地址:"
    echo "   用户端: http://localhost:${WEB_PORT}"
    echo "   管理后台: http://localhost:${WEB_PORT}/admin"
    echo "   API健康检查: http://localhost:${WEB_PORT}/api/v1/health"
    echo ""

    echo "🔐 默认管理员账号:"
    echo "   用户名: admin"
    echo "   密码: admin"
    echo ""

    echo "📊 服务状态:"
    docker-compose -f docker-compose.local.yml ps
    echo ""

    echo "📝 常用命令:"
    echo "   查看 Web 日志: docker-compose -f docker-compose.local.yml logs -f web"
    echo "   查看 Worker 日志: docker-compose -f docker-compose.local.yml logs -f worker"
    echo "   停止服务: docker-compose -f docker-compose.local.yml down"
    echo "   重启服务: docker-compose -f docker-compose.local.yml restart web"
    echo "   进入容器: docker-compose -f docker-compose.local.yml exec web bash"
    echo "   查看数据: docker-compose -f docker-compose.local.yml exec web rails runner 'puts \"Cities: \#{City.count}, Flights: \#{Flight.count}\"'"
    echo ""

    print_warning "提示: 本配置仅用于本地测试，生产环境请使用 deploy.sh"
}

# 执行主函数
main "$@"
