#!/bin/bash

# ===========================================
# APK 构建脚本（简化版 - 通用 APK）
# ===========================================
# 用法: bash build_apk.sh
# 说明:
#   - 构建通用 APK，不绑定特定服务器
#   - 运行时通过 adb shell settings 配置服务器地址
#   - 适用于云手机环境
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

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

main() {
    echo "=========================================="
    echo "  APK 构建（通用版本）"
    echo "=========================================="
    echo ""

    # 1. 检查 Docker
    print_info "步骤 1/4: 检查 Docker..."

    if ! command_exists docker; then
        print_error "Docker 未安装！请先安装 Docker。"
        exit 1
    fi
    print_success "Docker: $(docker --version)"

    # 2. 检查 apk 目录
    print_info "步骤 2/4: 检查 APK 项目..."

    if [ ! -d "apk" ]; then
        print_error "apk/ 目录不存在！"
        exit 1
    fi

    if [ ! -f "apk/build.gradle" ]; then
        print_error "apk/build.gradle 不存在！这不是一个完整的 Android 项目。"
        exit 1
    fi

    print_success "APK 项目检查通过"

    # 3. 构建 Docker 镜像（如果不存在）
    print_info "步骤 3/4: 准备 Docker 构建环境..."

    ANDROID_IMAGE="gradle-apk-builder:latest"

    # 检查镜像是否存在
    if ! docker image inspect $ANDROID_IMAGE >/dev/null 2>&1; then
        print_info "构建 Android Gradle 镜像（首次约 5-10 分钟）..."
        docker build -f Dockerfile.gradle -t $ANDROID_IMAGE .
        print_success "镜像构建完成"
    else
        print_success "使用已有镜像: $ANDROID_IMAGE"
    fi

    # 4. 在 Docker 中构建 APK
    print_info "步骤 4/4: 使用 Gradle 构建 APK..."
    echo ""

    # 清理旧的构建
    rm -rf apk/app/build/outputs/

    # 创建 Gradle 缓存目录
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

    # 验证构建结果
    echo ""
    print_info "验证构建结果..."

    if [ -f "apk/app/build/outputs/apk/release/app-release-unsigned.apk" ]; then
        # 复制到根目录
        cp apk/app/build/outputs/apk/release/app-release-unsigned.apk apk/app-release.apk

        # 签名 APK
        if [ -f "apk/android.keystore" ]; then
            echo ""
            print_info "签名 APK..."

            KEYSTORE_PASSWORD=${KEYSTORE_PASSWORD:-"123456"}
            KEY_ALIAS=${KEY_ALIAS:-"android"}
            KEY_PASSWORD=${KEY_PASSWORD:-"$KEYSTORE_PASSWORD"}

            SIGNED_APK="apk/app-release-signed.apk"
            ALIGNED_APK="apk/app-release-aligned.apk"

            rm -f "$SIGNED_APK" "$ALIGNED_APK"

            docker run --rm \
                -v "$(pwd)/apk:/project" \
                -w /project \
                $ANDROID_IMAGE \
                bash -c "
                    zipalign -v 4 app-release.apk app-release-aligned.apk > /dev/null 2>&1
                    apksigner sign \
                        --ks android.keystore \
                        --ks-pass pass:${KEYSTORE_PASSWORD} \
                        --ks-key-alias ${KEY_ALIAS} \
                        --key-pass pass:${KEY_PASSWORD} \
                        --out app-release-signed.apk \
                        app-release-aligned.apk 2>&1 | grep -v 'WARNING'
                    apksigner verify app-release-signed.apk > /dev/null 2>&1
                "

            if [ -f "$SIGNED_APK" ]; then
                rm -f "$ALIGNED_APK" apk/app-release.apk

                SIGNED_SIZE=$(du -h "$SIGNED_APK" | cut -f1)

                echo ""
                print_success "APK 构建和签名完成！"
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
                print_info "🎯 通用 APK 说明:"
                echo "   - APK 不绑定特定服务器"
                echo "   - 运行时通过 adb 配置服务器地址"
                echo "   - 一个 APK 可用于所有云手机实例"
                echo ""
                print_info "📱 使用方法:"
                echo "   1. 安装: adb install -r $SIGNED_APK"
                echo "   2. 配置: adb shell settings put global app_api_endpoint http://server:port"
                echo "   3. 启动: adb shell am start -n ai.clacky.trip01/.LauncherActivity"
                echo ""
                print_info "📚 详细文档:"
                echo "   查看 CLOUD_PHONE_DEPLOYMENT.md"
                echo ""

            else
                print_error "签名失败！"
                exit 1
            fi
        else
            print_error "未找到 keystore 文件，跳过签名"
            echo "   未签名 APK: apk/app-release.apk"
        fi

    else
        print_error "APK 构建失败！"
        exit 1
    fi

    print_success "构建完成！"
}

# 执行主函数
main "$@"
