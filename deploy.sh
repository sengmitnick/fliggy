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
    print_info "步骤 1/8: 检查系统依赖..."
    
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
    print_info "步骤 2/8: 检查环境配置..."
    
    if [ ! -f .env ]; then
        print_warning ".env 文件不存在，从示例文件复制..."
        cp .env.example .env
        print_warning "请编辑 .env 文件并填写必要配置项！"
        echo ""
        echo "必填项包括:"
        echo "  - SECRET_KEY_BASE"
        echo "  - DB_PASSWORD"
        echo "  - REDIS_PASSWORD"
        echo "  - PUBLIC_HOST"
        echo ""
        read -p "按 Enter 键编辑配置文件..." </dev/tty
        ${EDITOR:-nano} .env
    else
        print_success ".env 文件已存在"
    fi

    # 验证必填配置项
    if ! grep -q "SECRET_KEY_BASE=.\+" .env || ! grep -q "DB_PASSWORD=.\+" .env || ! grep -q "REDIS_PASSWORD=.\+" .env; then
        print_error "环境配置不完整！请确保设置了 SECRET_KEY_BASE、DB_PASSWORD 和 REDIS_PASSWORD"
        exit 1
    fi
    print_success "环境配置验证通过"

    # 3. 创建必要目录
    print_info "步骤 3/8: 创建必要目录..."
    mkdir -p backup ssl log storage
    print_success "目录创建完成"

    # 4. 选择 Nginx 配置
    print_info "步骤 4/8: 配置 Nginx..."
    
    echo "请选择 Nginx 配置模式:"
    echo "  1) HTTP 模式 (默认)"
    echo "  2) HTTPS 模式 (需要 SSL 证书)"
    echo "  3) 不使用 Nginx (直接访问 Rails)"
    read -p "请输入选择 [1-3] (默认: 1): " nginx_choice </dev/tty
    
    nginx_choice=${nginx_choice:-1}
    
    case $nginx_choice in
        1)
            if [ -f config/nginx.production.conf ]; then
                cp config/nginx.production.conf config/nginx.conf
                print_success "已选择 HTTP 模式"
            else
                print_warning "nginx.production.conf 不存在，跳过 Nginx 配置"
            fi
            ;;
        2)
            if [ -f config/nginx.ssl.production.conf ]; then
                cp config/nginx.ssl.production.conf config/nginx.conf
                print_success "已选择 HTTPS 模式"
                print_warning "请确保 SSL 证书已放置在 ./ssl/ 目录下"
                print_info "证书文件应包括: fullchain.pem 和 privkey.pem"
            else
                print_warning "nginx.ssl.production.conf 不存在，跳过 Nginx 配置"
            fi
            ;;
        3)
            print_success "跳过 Nginx 配置，将直接访问 Rails 应用"
            # 注释掉 docker-compose 中的 nginx 服务
            ;;
        *)
            print_error "无效选择"
            exit 1
            ;;
    esac

    # 5. 构建镜像
    print_info "步骤 5/8: 构建 Docker 镜像..."
    docker-compose -f docker-compose.production.yml build --no-cache
    print_success "镜像构建完成"

    # 6. 启动服务
    print_info "步骤 6/8: 启动服务..."
    docker-compose -f docker-compose.production.yml up -d
    print_success "服务已启动"

    # 等待数据库就绪
    print_info "等待数据库初始化..."
    sleep 10

    # 7. 初始化数据库
    print_info "步骤 7/8: 初始化数据库..."
    
    docker-compose -f docker-compose.production.yml exec -T web bundle exec rails db:create || true
    docker-compose -f docker-compose.production.yml exec -T web bundle exec rails db:migrate
    print_success "数据库初始化完成"

    # 询问是否加载种子数据
    read -p "是否加载种子数据 (包含演示数据)? [y/N]: " load_seed </dev/tty
    if [[ "$load_seed" =~ ^[Yy]$ ]]; then
        docker-compose -f docker-compose.production.yml exec -T web bundle exec rails db:seed
        print_success "种子数据已加载"
    fi

    # 8. 创建管理员账号
    print_info "步骤 8/8: 创建管理员账号..."
    
    read -p "是否创建管理员账号? [Y/n]: " create_admin </dev/tty
    create_admin=${create_admin:-Y}
    
    if [[ "$create_admin" =~ ^[Yy]$ ]]; then
        read -p "管理员邮箱 [admin@example.com]: " admin_email </dev/tty
        admin_email=${admin_email:-admin@example.com}
        
        read -sp "管理员密码: " admin_password </dev/tty
        echo ""
        
        if [ -z "$admin_password" ]; then
            admin_password="Admin123456!"
            print_warning "未设置密码，使用默认密码: Admin123456!"
        fi
        
        docker-compose -f docker-compose.production.yml exec -T web bundle exec rails runner "
            admin = Administrator.find_or_initialize_by(email: '${admin_email}')
            admin.password = '${admin_password}'
            admin.password_confirmation = '${admin_password}'
            if admin.save
              puts '管理员账号创建成功！'
            else
              puts '管理员账号创建失败: ' + admin.errors.full_messages.join(', ')
            end
        "
        print_success "管理员账号已创建"
    fi

    # 完成
    echo ""
    echo "=========================================="
    print_success "部署完成！"
    echo "=========================================="
    echo ""
    
    # 获取访问地址
    PUBLIC_HOST=$(grep "^PUBLIC_HOST=" .env | cut -d'=' -f2-)
    WEB_PORT=$(grep "^WEB_PORT=" .env | cut -d'=' -f2-)
    WEB_PORT=${WEB_PORT:-3000}
    
    if [ "$nginx_choice" = "3" ]; then
        echo "🌐 访问地址:"
        echo "   用户端: http://localhost:${WEB_PORT}"
        echo "   管理后台: http://localhost:${WEB_PORT}/admin"
    elif [ "$nginx_choice" = "2" ]; then
        echo "🌐 访问地址:"
        echo "   用户端: https://your-domain.com"
        echo "   管理后台: https://your-domain.com/admin"
    else
        echo "🌐 访问地址:"
        echo "   用户端: http://localhost:${NGINX_HTTP_PORT:-80}"
        echo "   管理后台: http://localhost:${NGINX_HTTP_PORT:-80}/admin"
    fi
    
    echo ""
    echo "📊 服务状态:"
    docker-compose -f docker-compose.production.yml ps
    echo ""
    
    echo "📝 常用命令:"
    echo "   查看日志: docker-compose -f docker-compose.production.yml logs -f"
    echo "   停止服务: docker-compose -f docker-compose.production.yml down"
    echo "   重启服务: docker-compose -f docker-compose.production.yml restart"
    echo "   进入控制台: docker-compose -f docker-compose.production.yml exec web bundle exec rails console"
    echo ""
    
    print_info "详细文档请参考: docs/DEPLOYMENT_GUIDE.md"
}

# 执行主函数
main "$@"
