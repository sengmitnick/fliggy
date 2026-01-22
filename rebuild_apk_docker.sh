#!/bin/bash

# ===========================================
# APK 重建脚本 - Docker 版本（甲方专用）
# ===========================================
# 使用方式: bash rebuild_apk_docker.sh
# 优势: 无需安装 JDK 和 Android SDK，所有依赖在 Docker 内
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

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

main() {
    echo "=========================================="
    echo "  APK 重建脚本 - Docker 版本"
    echo "=========================================="
    echo ""

    # 1. 检查 Docker
    print_info "步骤 1/6: 检查 Docker..."

    if ! command_exists docker; then
        print_error "Docker 未安装！请先安装 Docker。"
        echo "安装命令: curl -fsSL https://get.docker.com | sh"
        exit 1
    fi
    print_success "Docker 已安装: $(docker --version)"

    # 2. 检查 apk 目录
    print_info "步骤 2/6: 检查 APK 项目..."

    if [ ! -d "apk" ]; then
        print_error "apk/ 目录不存在！请确认项目结构完整。"
        exit 1
    fi

    if [ ! -f "apk/twa-manifest.json" ]; then
        print_error "apk/twa-manifest.json 不存在！请先运行 'npx @bubblewrap/cli init'"
        exit 1
    fi
    print_success "APK 项目存在"

    # 3. 获取部署地址
    print_info "步骤 3/6: 配置部署地址..."
    echo ""

    # 从 .env 读取默认值
    if [ -f .env ]; then
        PUBLIC_HOST=$(grep "^PUBLIC_HOST=" .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        WEB_PORT=$(grep "^WEB_PORT=" .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        WEB_PORT=${WEB_PORT:-5010}
    fi

    echo "请输入您的部署地址（甲方实际访问地址）:"
    echo "  示例 1: 192.168.1.100:5010 (IP + 端口)"
    echo "  示例 2: trip.example.com (域名，使用 Nginx 80/443)"
    echo "  示例 3: trip.example.com:5010 (域名 + 自定义端口)"

    if [ -n "$PUBLIC_HOST" ]; then
        echo "  当前 .env 配置: ${PUBLIC_HOST}:${WEB_PORT}"
        read -p "请输入部署地址 (直接回车使用 .env 配置): " DEPLOY_HOST
        if [ -z "$DEPLOY_HOST" ]; then
            DEPLOY_HOST="${PUBLIC_HOST}:${WEB_PORT}"
        fi
    else
        read -p "请输入部署地址: " DEPLOY_HOST
    fi

    if [ -z "$DEPLOY_HOST" ]; then
        print_error "部署地址不能为空！"
        exit 1
    fi

    # 规范化地址（添加协议）
    if [[ ! "$DEPLOY_HOST" =~ ^https?:// ]]; then
        DEPLOY_HOST="http://${DEPLOY_HOST}"
    fi

    print_success "部署地址: $DEPLOY_HOST"

    # 4. 验证服务可访问性
    print_info "步骤 4/6: 验证服务可访问性..."

    echo "   正在检查 Rails 应用是否可访问..."
    if curl -s -f -o /dev/null -m 10 "${DEPLOY_HOST}/" || curl -s -f -o /dev/null -m 10 "${DEPLOY_HOST}/manifest.json"; then
        print_success "服务可访问"
    else
        print_warning "无法访问 ${DEPLOY_HOST}，请确认:"
        print_warning "  1. Rails 应用已通过 deploy.sh 启动"
        print_warning "  2. 防火墙已开放对应端口"
        print_warning "  3. 地址和端口正确"
        echo ""
        read -p "是否继续构建 APK？[y/N] " continue_build
        if [[ ! "$continue_build" =~ ^[Yy]$ ]]; then
            print_error "已取消构建"
            exit 1
        fi
    fi

    # 5. 备份和更新配置
    print_info "步骤 5/6: 更新 TWA 配置..."

    # 备份原有配置
    if [ -f apk/twa-manifest.json ]; then
        cp apk/twa-manifest.json apk/twa-manifest.json.backup
        print_success "已备份 twa-manifest.json"
    fi

    # 移除协议前缀（host 字段不需要协议）
    DEPLOY_HOST_NO_PROTOCOL=$(echo "$DEPLOY_HOST" | sed 's|^https\?://||')

    # 更新配置
    cd apk

    # 使用 sed 更新配置
    sed -i.tmp "s|\"host\": \"[^\"]*\"|\"host\": \"${DEPLOY_HOST_NO_PROTOCOL}\"|g" twa-manifest.json
    sed -i.tmp "s|\"iconUrl\": \"[^\"]*\"|\"iconUrl\": \"${DEPLOY_HOST}/trip-logo.png\"|g" twa-manifest.json
    sed -i.tmp "s|\"maskableIconUrl\": \"[^\"]*\"|\"maskableIconUrl\": \"${DEPLOY_HOST}/trip-logo.png\"|g" twa-manifest.json
    sed -i.tmp "s|\"webManifestUrl\": \"[^\"]*\"|\"webManifestUrl\": \"${DEPLOY_HOST}/manifest.json\"|g" twa-manifest.json
    sed -i.tmp "s|\"fullScopeUrl\": \"[^\"]*\"|\"fullScopeUrl\": \"${DEPLOY_HOST}/\"|g" twa-manifest.json

    # 更新 signingKey path 为容器内路径
    sed -i.tmp 's|"path": "[^"]*"|"path": "/workspace/android.keystore"|g' twa-manifest.json

    rm -f twa-manifest.json.tmp

    print_success "twa-manifest.json 已更新"

    cd ..

    # 6. 构建 Docker 镜像
    print_info "步骤 6/6: 使用 Docker 构建 APK..."
    echo ""

    print_warning "首次构建需要下载 Docker 镜像和 Android SDK (约 1GB)，预计 15-20 分钟"
    print_warning "后续构建会快很多（约 3-5 分钟）"
    echo ""

    # 获取 keystore 密码
    echo "请设置 APK 签名密码（用于后续 APK 更新）:"
    read -sp "Keystore password (默认: 123456): " KEYSTORE_PASSWORD
    echo ""
    KEYSTORE_PASSWORD=${KEYSTORE_PASSWORD:-123456}

    read -sp "Key password (默认: 与 Keystore 相同): " KEY_PASSWORD
    echo ""
    KEY_PASSWORD=${KEY_PASSWORD:-$KEYSTORE_PASSWORD}

    # 构建 Docker 镜像
    print_info "构建 APK 构建器镜像（JDK 17）..."
    docker build -f Dockerfile.apk -t apk-builder:latest . 2>&1 | grep -E "(Step|Successfully|sha256)" || true
    print_success "镜像构建完成（已包含 JDK 17）"

    # 清理旧的 APK 文件
    rm -f apk/app-release-*.apk apk/app-release-*.aab

    # 在 Docker 容器中构建 APK
    print_info "在 Docker 容器中构建 APK（非交互式）..."
    echo ""

    docker run --rm \
        -v "$(pwd)/apk:/workspace" \
        -e DEPLOY_HOST="${DEPLOY_HOST_NO_PROTOCOL}" \
        -e KEYSTORE_PASSWORD="${KEYSTORE_PASSWORD}" \
        -e KEY_PASSWORD="${KEY_PASSWORD}" \
        apk-builder:latest

    # 7. 验证构建结果
    echo ""
    print_info "验证构建结果..."

    if [ -f apk/app-release-signed.apk ]; then
        APK_SIZE=$(du -h apk/app-release-signed.apk | cut -f1)

        print_success "APK 构建成功！"
        echo ""
        echo "📦 生成的文件:"
        ls -lh apk/app-release-*.apk apk/app-release-*.aab 2>/dev/null | awk '{print "   " $9 " (" $5 ")"}'
        echo ""
        echo "🔐 APK 信息:"
        echo "   文件名: apk/app-release-signed.apk"
        echo "   大小: $APK_SIZE"
        if command_exists md5sum; then
            APK_MD5=$(md5sum apk/app-release-signed.apk | cut -d' ' -f1)
            echo "   MD5: $APK_MD5"
        fi
        echo ""
        echo "🌐 绑定的部署地址:"
        echo "   $DEPLOY_HOST"
        echo ""

        print_info "后续步骤:"
        echo "   1. 将 apk/app-release-signed.apk 发送给用户"
        echo "   2. 用户安装 APK 到 Android 设备"
        echo "   3. 确保设备可访问 ${DEPLOY_HOST}"
        echo "   4. 如需更换域名，请重新运行本脚本"
        echo ""

        print_warning "注意事项:"
        echo "   - APK 已绑定到 ${DEPLOY_HOST}，更换域名需重新构建"
        echo "   - 保留 apk/android.keystore 用于后续更新"
        echo "   - 更新 APK 时必须使用相同的密码"
        echo "   - 原配置已备份到 apk/twa-manifest.json.backup"

    else
        print_error "APK 构建失败！请检查构建日志"

        # 恢复备份
        if [ -f apk/twa-manifest.json.backup ]; then
            mv apk/twa-manifest.json.backup apk/twa-manifest.json
            print_info "已恢复原有配置"
        fi
        exit 1
    fi
}

# 执行主函数
main "$@"
