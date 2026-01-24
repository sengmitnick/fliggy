#!/bin/bash

# ===========================================
# APK Gradle Docker 构建脚本（最优方案）
# ===========================================
# 使用方式: bash rebuild_apk_gradle_docker.sh
# 优势:
#   1. 比 Bubblewrap CLI 更快（直接使用 Gradle）
#   2. 无需本地配置 JDK/Android SDK（在 Docker 内）
#   3. 更灵活（完全控制 Gradle 构建）
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

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

main() {
    echo "=========================================="
    echo "  APK Gradle Docker 构建（推荐）"
    echo "=========================================="
    echo ""

    # 1. 检查 Docker
    print_info "步骤 1/8: 检查 Docker..."

    if ! command_exists docker; then
        print_error "Docker 未安装！请先安装 Docker。"
        exit 1
    fi
    print_success "Docker: $(docker --version)"

    # 2. 检查 apk 目录
    print_info "步骤 2/8: 检查 APK 项目..."

    if [ ! -d "apk" ]; then
        print_error "apk/ 目录不存在！"
        exit 1
    fi

    if [ ! -f "apk/build.gradle" ]; then
        print_error "apk/build.gradle 不存在！这不是一个完整的 Android 项目。"
        exit 1
    fi

    print_success "APK 项目检查通过"

    # 3. 获取部署地址
    print_info "步骤 3/8: 配置部署地址..."
    echo ""

    # 从 .env 读取默认值
    DEFAULT_DEPLOY_ADDR=""
    if [ -f .env ]; then
        PUBLIC_HOST=$(grep "^PUBLIC_HOST=" .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        WEB_PORT=$(grep "^WEB_PORT=" .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        WEB_PORT=${WEB_PORT:-5010}

        # 检查 PUBLIC_HOST 是否已经包含完整 URL（带协议或端口）
        if [[ "$PUBLIC_HOST" =~ ^https?:// ]] || [[ "$PUBLIC_HOST" =~ :[0-9]+$ ]]; then
            # PUBLIC_HOST 已经是完整地址，直接使用
            DEFAULT_DEPLOY_ADDR="$PUBLIC_HOST"
        elif [ -n "$PUBLIC_HOST" ]; then
            # PUBLIC_HOST 只是主机名，需要拼接端口
            DEFAULT_DEPLOY_ADDR="${PUBLIC_HOST}:${WEB_PORT}"
        fi
    fi

    echo "请输入您的部署地址（甲方实际访问地址）:"
    echo ""
    print_warning "⚠️  重要：Android TWA 要求使用 HTTPS 域名"
    echo "  示例: trip.example.com 或 https://trip.example.com"
    echo ""
    echo "  说明："
    echo "  - deploy.sh 可以继续用 HTTP（本地开发/内网）"
    echo "  - APK 打包必须使用 HTTPS 域名（生产环境）"
    echo "  - 甲方需要自行配置 HTTPS（Nginx/Cloudflare/云服务）"
    echo ""

    if [ -n "$DEFAULT_DEPLOY_ADDR" ]; then
        echo "  当前 .env 配置: ${DEFAULT_DEPLOY_ADDR}"
        read -p "请输入部署地址 (直接回车使用 .env 配置): " DEPLOY_HOST
        if [ -z "$DEPLOY_HOST" ]; then
            DEPLOY_HOST="$DEFAULT_DEPLOY_ADDR"
        fi
    else
        read -p "请输入部署地址: " DEPLOY_HOST
    fi

    if [ -z "$DEPLOY_HOST" ]; then
        print_error "部署地址不能为空！"
        exit 1
    fi

    # 规范化地址
    DEPLOY_PROTOCOL="https"

    if [[ "$DEPLOY_HOST" =~ ^https?:// ]]; then
        # DEPLOY_HOST 已包含协议
        DEPLOY_URL="$DEPLOY_HOST"
        # 提取协议
        if [[ "$DEPLOY_HOST" =~ ^http:// ]]; then
            DEPLOY_PROTOCOL="http"
        else
            DEPLOY_PROTOCOL="https"
        fi
        # 去除协议前缀（只保留 host:port）
        DEPLOY_HOST=$(echo "$DEPLOY_HOST" | sed -E 's|^https?://||')
        # 重新构建完整 URL
        DEPLOY_URL="${DEPLOY_PROTOCOL}://${DEPLOY_HOST}"
    else
        # DEPLOY_HOST 不包含协议，默认使用 https
        DEPLOY_URL="https://${DEPLOY_HOST}"
    fi

    # 检查是否使用 HTTP（不允许）
    if [[ "$DEPLOY_PROTOCOL" == "http" ]]; then
        echo ""
        print_error "错误：不支持 HTTP 协议"
        echo ""
        echo "Android TWA 要求使用 HTTPS 域名："
        echo "  - HTTP 会导致 APP 无法启动或卡在启动页"
        echo "  - Digital Asset Links 验证需要 HTTPS"
        echo ""
        echo "请使用 HTTPS 域名，例如："
        echo "  - your-domain.com"
        echo "  - https://your-domain.com"
        echo ""
        print_info "如何配置 HTTPS？"
        echo "  查看详细教程: HTTPS_DEPLOYMENT_GUIDE.md"
        echo "  推荐方案: Cloudflare（免费、简单）"
        echo ""
        exit 1
    fi

    print_success "部署地址: $DEPLOY_URL (${DEPLOY_PROTOCOL})"

    # 调试信息（开发时可以打开）
    # echo "DEBUG: DEPLOY_PROTOCOL=$DEPLOY_PROTOCOL"
    # echo "DEBUG: DEPLOY_HOST=$DEPLOY_HOST (不含协议)"
    # echo "DEBUG: DEPLOY_URL=$DEPLOY_URL"

    # 4. 备份原有配置
    print_info "步骤 4/8: 备份原有配置..."

    # 创建备份目录
    mkdir -p apk/backups

    if [ -f apk/app/build.gradle ]; then
        cp apk/app/build.gradle apk/backups/build.gradle.backup
        print_success "已备份 build.gradle"
    fi

    if [ -f apk/app/src/main/res/values/strings.xml ]; then
        cp apk/app/src/main/res/values/strings.xml apk/backups/strings.xml.backup
        print_success "已备份 strings.xml"
    fi

    # 清理旧的备份文件（避免 Gradle 编译错误）
    rm -f apk/app/src/main/res/values/*.backup
    rm -f apk/app/*.backup

    # 5. 更新配置文件
    print_info "步骤 5/8: 更新 Android 项目配置..."

    # 更新 build.gradle
    # 注意：DEPLOY_HOST 已去除协议前缀（只包含域名:端口）
    # 因为 build.gradle 会拼接: def launchUrl = "protocol://" + hostName + launchUrl
    sed -i.tmp "s|hostName: '[^']*'|hostName: '${DEPLOY_HOST}'|g" apk/app/build.gradle
    # 更新 webManifestUrl 和 fullScopeUrl（使用 -E 支持扩展正则）
    sed -i.tmp -E "s|resValue \"string\", \"webManifestUrl\", '(https?://)?[^']*'|resValue \"string\", \"webManifestUrl\", '${DEPLOY_URL}/manifest.json'|g" apk/app/build.gradle
    sed -i.tmp -E "s|resValue \"string\", \"fullScopeUrl\", '(https?://)?[^']*'|resValue \"string\", \"fullScopeUrl\", '${DEPLOY_URL}/'|g" apk/app/build.gradle
    # 更新 launchUrl 的协议（关键：build.gradle 中会拼接 protocol + hostName + launchUrl）
    sed -i.tmp -E "s|def launchUrl = \"https?://\"|def launchUrl = \"${DEPLOY_PROTOCOL}://\"|g" apk/app/build.gradle
    rm -f apk/app/build.gradle.tmp

    # 更新 strings.xml（assetStatements 中的 site 字段）
    sed -i.tmp -E "s|\\\\\"site\\\\\": \\\\\"(https?://)?[^\\\\]*\\\\\"|\\\\\"site\\\\\": \\\\\"${DEPLOY_URL}\\\\\"|g" apk/app/src/main/res/values/strings.xml
    rm -f apk/app/src/main/res/values/strings.xml.tmp

    print_success "配置文件已更新"

    # 6. 构建 Docker 镜像（如果不存在）
    print_info "步骤 6/8: 准备 Docker 构建环境..."

    ANDROID_IMAGE="gradle-apk-builder:latest"

    # 检查镜像是否存在
    if ! docker image inspect $ANDROID_IMAGE >/dev/null 2>&1; then
        print_info "构建 Android Gradle 镜像（首次约 5-10 分钟）..."
        docker build -f Dockerfile.gradle -t $ANDROID_IMAGE .
        print_success "镜像构建完成"
    else
        print_success "使用已有镜像: $ANDROID_IMAGE"
    fi

    # 7. 在 Docker 中构建 APK
    print_info "步骤 7/8: 使用 Gradle 构建 APK..."
    echo ""

    # 清理旧的构建
    rm -rf apk/app/build/outputs/

    # 创建 Gradle 缓存目录（如果不存在）
    mkdir -p .gradle-cache

    # 在 Docker 中运行 Gradle 构建
    docker run --rm \
        -v "$(pwd)/apk:/project" \
        -v "$(pwd)/.gradle-cache:/root/.gradle" \
        -w /project \
        $ANDROID_IMAGE \
        bash -c "
            echo '开始 Gradle 构建...'
            chmod +x ./gradlew
            ./gradlew clean assembleRelease --no-daemon --stacktrace
            echo '构建完成'
        "

    # 8. 验证构建结果
    echo ""
    print_info "验证构建结果..."

    APK_FILE=""
    if [ -f "apk/app/build/outputs/apk/release/app-release-unsigned.apk" ]; then
        # 复制到根目录
        cp apk/app/build/outputs/apk/release/app-release-unsigned.apk apk/app-release.apk
        APK_FILE="apk/app-release.apk"

        APK_SIZE=$(du -h "$APK_FILE" | cut -f1)

        echo ""
        print_success "APK 构建成功！"
        echo ""
        echo "📦 生成的文件:"
        echo "   $APK_FILE ($APK_SIZE)"
        echo ""
        echo "🔐 APK 信息:"
        echo "   文件大小: $APK_SIZE"
        if command -v md5sum >/dev/null 2>&1; then
            APK_MD5=$(md5sum "$APK_FILE" | cut -d' ' -f1)
            echo "   MD5: $APK_MD5"
        elif command -v md5 >/dev/null 2>&1; then
            APK_MD5=$(md5 -q "$APK_FILE")
            echo "   MD5: $APK_MD5"
        fi
        echo ""
        echo "🌐 绑定的部署地址:"
        echo "   $DEPLOY_URL"
        echo ""

        # 自动签名 APK
        if [ -f "apk/android.keystore" ]; then
            echo ""
            print_info "步骤 8/8: 签名 APK..."
            echo ""

            # 使用默认密码（可以从环境变量覆盖）
            KEYSTORE_PASSWORD=${KEYSTORE_PASSWORD:-"123456"}
            KEY_ALIAS=${KEY_ALIAS:-"android"}
            KEY_PASSWORD=${KEY_PASSWORD:-"$KEYSTORE_PASSWORD"}

            SIGNED_APK="apk/app-release-signed.apk"
            ALIGNED_APK="apk/app-release-aligned.apk"

            # 清理旧文件
            rm -f "$SIGNED_APK" "$ALIGNED_APK"

            # 在 Docker 中签名 APK
            docker run --rm \
                -v "$(pwd)/apk:/project" \
                -w /project \
                $ANDROID_IMAGE \
                bash -c "
                    echo '  1/3: 对齐 APK...'
                    zipalign -v 4 app-release.apk app-release-aligned.apk > /dev/null 2>&1

                    echo '  2/3: 签名 APK...'
                    apksigner sign \
                        --ks android.keystore \
                        --ks-pass pass:${KEYSTORE_PASSWORD} \
                        --ks-key-alias ${KEY_ALIAS} \
                        --key-pass pass:${KEY_PASSWORD} \
                        --out app-release-signed.apk \
                        app-release-aligned.apk 2>&1 | grep -v 'WARNING'

                    echo '  3/3: 验证签名...'
                    apksigner verify app-release-signed.apk > /dev/null 2>&1
                "

            # 检查签名结果
            if [ -f "$SIGNED_APK" ]; then
                # 清理临时文件
                rm -f "$ALIGNED_APK" "$APK_FILE"

                SIGNED_SIZE=$(du -h "$SIGNED_APK" | cut -f1)

                echo ""
                print_success "APK 签名成功！"
                echo ""
                echo "📦 最终 APK:"
                echo "   文件: $SIGNED_APK"
                echo "   大小: $SIGNED_SIZE"

                if command -v md5sum >/dev/null 2>&1; then
                    SIGNED_MD5=$(md5sum "$SIGNED_APK" | cut -d' ' -f1)
                    echo "   MD5: $SIGNED_MD5"
                elif command -v md5 >/dev/null 2>&1; then
                    SIGNED_MD5=$(md5 -q "$SIGNED_APK")
                    echo "   MD5: $SIGNED_MD5"
                fi

                echo ""
                echo "🌐 绑定地址: $DEPLOY_URL"
                echo ""
                print_info "安装到设备:"
                echo "   adb install $SIGNED_APK"
                echo ""
                print_info "或覆盖安装（保留数据）:"
                echo "   adb install -r $SIGNED_APK"
                echo ""

            else
                print_error "签名失败！"
                echo ""
                print_warning "未签名 APK 仍可用（仅限测试）:"
                echo "   $APK_FILE"
            fi

        else
            print_warning "⚠️ 未找到 keystore 文件"
            echo "   生成的是未签名 APK，无法直接安装到设备"
            echo ""
            echo "📦 未签名 APK:"
            echo "   $APK_FILE ($APK_SIZE)"
            echo ""
            print_info "如需签名，请运行: bash sign_apk.sh"
        fi

    else
        print_error "APK 构建失败！"

        # 恢复备份
        if [ -f apk/backups/build.gradle.backup ]; then
            cp apk/backups/build.gradle.backup apk/app/build.gradle
            print_info "已恢复 build.gradle"
        fi
        if [ -f apk/backups/strings.xml.backup ]; then
            cp apk/backups/strings.xml.backup apk/app/src/main/res/values/strings.xml
            print_info "已恢复 strings.xml"
        fi
        exit 1
    fi

    echo ""
    print_success "Gradle Docker 构建完成！"
    echo ""
    print_info "💡 Gradle 方式 vs Bubblewrap 方式:"
    echo "   ✅ Gradle: 更快（3-5 分钟）、更灵活"
    echo "   ⚠️ Bubblewrap: 更慢（15-20 分钟）、自动化程度高"
    echo ""
    print_info "💡 Docker 方式 vs 本地方式:"
    echo "   ✅ Docker: 无需配置 JDK/Android SDK"
    echo "   ⚠️ 本地: 需要配置完整的 Android 开发环境"
}

# 执行主函数
main "$@"
