#!/bin/bash

# ===========================================
# 旅游环境01 - 快速更新脚本
# ===========================================
# 用于代码更新、数据库迁移场景
# 使用方式: bash update.sh
# ===========================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

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

echo "=========================================="
echo "  旅游环境01 - 快速更新"
echo "=========================================="
echo ""

# 1. 检测使用哪个 docker-compose 文件
if [ -f ".env" ]; then
    WEB_PORT=$(grep "^WEB_PORT=" .env | cut -d'=' -f2-)
else
    print_error ".env 文件不存在！请先运行 bash deploy.sh 进行初始部署"
    exit 1
fi

# 2. 选择配置文件
echo "请选择服务器配置:"
echo "  1) 8核32G (甲方生产环境，默认)"
echo "  2) 2核8G (本地测试/展示)"
read -p "请输入选择 [1-2] (默认: 1): " server_spec

server_spec=${server_spec:-1}

case $server_spec in
    1)
        COMPOSE_FILE="docker-compose.production.8core.yml"
        print_success "使用 8核32G 配置"
        ;;
    2)
        COMPOSE_FILE="docker-compose.production.2core.yml"
        print_success "使用 2核8G 配置"
        ;;
    *)
        print_error "无效选择"
        exit 1
        ;;
esac

# 3. 检查是否使用 Nginx
echo ""
read -p "是否使用了 Nginx? [y/N]: " use_nginx
use_nginx=${use_nginx:-N}

if [[ "$use_nginx" =~ ^[Yy]$ ]]; then
    SERVICES="db redis web worker nginx"
else
    SERVICES="db redis web worker"
fi

# 4. 更新流程
echo ""
echo "=========================================="
echo "  开始更新"
echo "=========================================="
echo ""

print_info "步骤 1/5: 拉取最新代码..."
if [ -d .git ]; then
    git pull
    print_success "代码已更新"
else
    print_warning "非 Git 仓库，跳过代码拉取"
fi

print_info "步骤 2/5: 重建镜像..."
docker-compose -f $COMPOSE_FILE build web worker
print_success "镜像构建完成"

print_info "步骤 3/5: 停止旧服务..."
docker-compose -f $COMPOSE_FILE stop web worker
print_success "旧服务已停止"

print_info "步骤 4/5: 启动新服务..."
docker-compose -f $COMPOSE_FILE up -d $SERVICES
print_success "新服务已启动"

print_info "步骤 5/5: 等待服务就绪..."
echo "   提示: 容器启动时会自动执行 rails db:prepare"
echo "   提示: 这会自动运行新的数据库迁移（如果有）"
sleep 15

# 5. 验证更新
echo ""
echo "=========================================="
print_success "更新完成！"
echo "=========================================="
echo ""

echo "📊 服务状态:"
docker-compose -f $COMPOSE_FILE ps
echo ""

# 检查健康状态
print_info "验证服务健康状态..."
sleep 5

if curl -f -s http://localhost:${WEB_PORT:-5010}/api/v1/health > /dev/null 2>&1; then
    print_success "健康检查通过 ✓"
    echo ""
    curl -s http://localhost:${WEB_PORT:-5010}/api/v1/health | python3 -m json.tool 2>/dev/null || \
    curl -s http://localhost:${WEB_PORT:-5010}/api/v1/health
else
    print_warning "健康检查失败，请查看日志排查问题"
    echo ""
    echo "查看日志命令:"
    echo "  docker-compose -f $COMPOSE_FILE logs -f web"
fi

echo ""
echo "📝 常用命令:"
echo "   查看日志: docker-compose -f $COMPOSE_FILE logs -f web"
echo "   重启服务: docker-compose -f $COMPOSE_FILE restart web"
echo "   查看数据: docker-compose -f $COMPOSE_FILE exec web bundle exec rails runner 'puts \"Cities: \#{City.count}, Flights: \#{Flight.count}\"'"
echo ""
