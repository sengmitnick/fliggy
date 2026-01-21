#!/bin/bash

# ===========================================
# APK 重建脚本 - 用于甲方自定义域名部署
# ===========================================
# 使用方式: bash rebuild_apk.sh
# 前提条件: 已通过 deploy.sh 部署 Rails 应用
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
    echo "  APK 重建脚本 - 自定义域名"
    echo "=========================================="
    echo ""

    # 1. 检查依赖
    print_info "步骤 1/7: 检查依赖..."
    
    if ! command_exists npx; then
        print_error "Node.js 未安装！请先安装 Node.js (需要 npm/npx)。"
        echo "安装命令: curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash - && sudo apt-get install -y nodejs"
        exit 1
    fi
    print_success "Node.js 已安装: $(node --version)"

    if ! command_exists java; then
        print_error "Java 未安装！请先安装 JDK。"
        echo "安装命令: sudo apt-get install -y default-jdk"
        exit 1
    fi
    print_success "Java 已安装: $(java -version 2>&1 | head -n 1)"

    # 2. 获取部署地址
    print_info "步骤 2/7: 配置部署地址..."
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
        # 默认使用 http (如果甲方使用 HTTPS，需要手动加 https://)
        DEPLOY_HOST="http://${DEPLOY_HOST}"
    fi

    print_success "部署地址: $DEPLOY_HOST"

    # 3. 验证服务可访问性
    print_info "步骤 3/7: 验证服务可访问性..."
    
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

    # 4. 备份原有配置
    print_info "步骤 4/7: 备份原有配置..."
    
    if [ -f twa-manifest.json ]; then
        cp twa-manifest.json twa-manifest.json.backup
        print_success "已备份 twa-manifest.json -> twa-manifest.json.backup"
    fi

    # 5. 更新 twa-manifest.json
    print_info "步骤 5/7: 更新 TWA 配置..."
    
    # 移除协议前缀（host 字段不需要协议）
    DEPLOY_HOST_NO_PROTOCOL=$(echo "$DEPLOY_HOST" | sed 's|^https\?://||')
    
    # 检测 keystore 文件位置
    KEYSTORE_PATH=""
    if [ -f android.keystore ]; then
        # 使用当前目录的绝对路径
        KEYSTORE_PATH="$(pwd)/android.keystore"
    elif [ -f "$HOME/android.keystore" ]; then
        KEYSTORE_PATH="$HOME/android.keystore"
    elif grep -q '"path":' twa-manifest.json 2>/dev/null; then
        # 从现有配置读取路径
        EXISTING_PATH=$(grep '"path":' twa-manifest.json | sed 's/.*"path": "\([^"]*\)".*/\1/')
        if [ -f "$EXISTING_PATH" ]; then
            KEYSTORE_PATH="$EXISTING_PATH"
        fi
    fi
    
    if [ -z "$KEYSTORE_PATH" ]; then
        print_warning "未找到 android.keystore 文件，将在当前目录创建新的 keystore"
        KEYSTORE_PATH="$(pwd)/android.keystore"
    else
        print_success "检测到 keystore: $KEYSTORE_PATH"
    fi
    
    # 使用 sed 更新配置（保留其他字段不变）
    if [ -f twa-manifest.json ]; then
        # 更新 host
        sed -i.tmp "s|\"host\": \"[^\"]*\"|\"host\": \"${DEPLOY_HOST_NO_PROTOCOL}\"|g" twa-manifest.json
        
        # 更新 iconUrl
        sed -i.tmp "s|\"iconUrl\": \"[^\"]*\"|\"iconUrl\": \"${DEPLOY_HOST}/trip-logo.png\"|g" twa-manifest.json
        
        # 更新 maskableIconUrl
        sed -i.tmp "s|\"maskableIconUrl\": \"[^\"]*\"|\"maskableIconUrl\": \"${DEPLOY_HOST}/trip-logo.png\"|g" twa-manifest.json
        
        # 更新 monochromeIconUrl
        sed -i.tmp "s|\"monochromeIconUrl\": \"[^\"]*\"|\"monochromeIconUrl\": \"${DEPLOY_HOST}/trip-logo.png\"|g" twa-manifest.json
        
        # 更新 webManifestUrl
        sed -i.tmp "s|\"webManifestUrl\": \"[^\"]*\"|\"webManifestUrl\": \"${DEPLOY_HOST}/manifest.json\"|g" twa-manifest.json
        
        # 更新 fullScopeUrl
        sed -i.tmp "s|\"fullScopeUrl\": \"[^\"]*\"|\"fullScopeUrl\": \"${DEPLOY_HOST}/\"|g" twa-manifest.json
        
        # 更新 signingKey.path（使用检测到的路径）
        sed -i.tmp "s|\"path\": \"[^\"]*\"|\"path\": \"${KEYSTORE_PATH}\"|g" twa-manifest.json
        
        # 删除临时文件
        rm -f twa-manifest.json.tmp
        
        print_success "twa-manifest.json 已更新为新的部署地址"
        print_success "Keystore 路径已更新为: $KEYSTORE_PATH"
    else
        print_error "twa-manifest.json 不存在！请先运行 'npx @bubblewrap/cli init'"
        exit 1
    fi

    # 6. 清理旧的 APK 文件
    print_info "步骤 6/7: 清理旧的 APK 文件..."
    
    rm -f app-release-*.apk app-release-*.aab
    print_success "已清理旧的 APK/AAB 文件"

    # 7. 重新构建 APK
    print_info "步骤 7/7: 重新构建 APK..."
    echo ""
    print_warning "构建过程中需要输入密码 (keystore password 和 key password):"
    print_warning "  - 如果是首次构建，请设置并记住密码"
    print_warning "  - 如果之前已构建过，请输入相同的密码 (默认: 123456)"
    echo ""
    
    # 使用 Bubblewrap CLI 重新构建
    npx @bubblewrap/cli build

    # 8. 验证构建结果
    echo ""
    print_info "验证构建结果..."
    
    if [ -f app-release-signed.apk ]; then
        APK_SIZE=$(du -h app-release-signed.apk | cut -f1)
        APK_MD5=$(md5sum app-release-signed.apk | cut -d' ' -f1)
        
        print_success "APK 构建成功！"
        echo ""
        echo "📦 生成的文件:"
        ls -lh app-release-*.apk app-release-*.aab 2>/dev/null | awk '{print "   " $9 " (" $5 ")"}'
        echo ""
        echo "🔐 APK 信息:"
        echo "   文件名: app-release-signed.apk"
        echo "   大小: $APK_SIZE"
        echo "   MD5: $APK_MD5"
        echo ""
        echo "🌐 绑定的部署地址:"
        echo "   $DEPLOY_HOST"
        echo ""
        
        print_info "后续步骤:"
        echo "   1. 将 app-release-signed.apk 发送给甲方"
        echo "   2. 甲方安装 APK 到 Android 设备"
        echo "   3. 确保设备可访问 ${DEPLOY_HOST}"
        echo "   4. 如需更换域名，请重新运行本脚本"
        echo ""
        
        print_warning "注意事项:"
        echo "   - APK 已绑定到 ${DEPLOY_HOST}，更换域名需重新构建"
        echo "   - 保留 android.keystore 和 twa-manifest.json 用于后续更新"
        echo "   - 更新 APK 时必须使用相同的 keystore 和密码"
        echo "   - 原配置已备份到 twa-manifest.json.backup"
        
    else
        print_error "APK 构建失败！请检查构建日志"
        
        # 恢复备份
        if [ -f twa-manifest.json.backup ]; then
            mv twa-manifest.json.backup twa-manifest.json
            print_info "已恢复原有配置"
        fi
        exit 1
    fi
}

# 执行主函数
main "$@"
