# APK 重建指南 - 自定义域名部署

## 📖 概述

本文档说明如何在甲方自定义域名/IP 部署后，重新生成 Android APK 文件。

### 为什么需要重建 APK？

Android APK（基于 TWA - Trusted Web Activity）内嵌了以下信息：

1. **部署地址 (`host`)**: APK 只能访问指定的域名/IP
2. **图标 URL**: 应用图标的下载地址
3. **Manifest URL**: PWA manifest 文件的地址

这些信息在 `twa-manifest.json` 中硬编码，**更换部署地址后必须重新构建 APK**。

---

## 🚀 快速开始

### 前提条件

1. ✅ 已通过 `deploy.sh` 完成 Rails 应用部署
2. ✅ 甲方服务器已配置好域名/IP 和端口
3. ✅ Rails 应用可通过浏览器正常访问
4. ✅ 服务器已安装 Node.js 和 JDK

### 一键重建 APK

```bash
# 1. 赋予执行权限
chmod +x rebuild_apk.sh

# 2. 运行重建脚本
bash rebuild_apk.sh
```

脚本会自动完成：
- ✅ 检查依赖（Node.js, Java）
- ✅ 获取甲方部署地址
- ✅ 验证服务可访问性
- ✅ 更新 twa-manifest.json 配置
- ✅ 重新构建 APK 和 AAB 文件
- ✅ 生成新的签名 APK

---

## 📋 详细步骤

### 步骤 1: 部署 Rails 应用

首先使用 `deploy.sh` 完成 Rails 应用部署：

```bash
# 甲方服务器上运行
bash deploy.sh
```

部署完成后，确认以下信息：
- 访问地址（IP + 端口，或域名）
- 端口号（默认 5010，或使用 Nginx 的 80/443）
- 应用可正常访问

**示例部署地址：**
- `http://192.168.1.100:5010` (IP + 自定义端口)
- `http://trip.example.com:5010` (域名 + 自定义端口)
- `http://trip.example.com` (域名，使用 Nginx 80)
- `https://trip.example.com` (域名，使用 Nginx 443 + SSL)

### 步骤 2: 验证服务可访问

在构建 APK 之前，确认服务可访问：

```bash
# 测试主页
curl -I http://YOUR_DEPLOY_HOST:PORT/

# 测试 PWA manifest（APK 需要此文件）
curl http://YOUR_DEPLOY_HOST:PORT/manifest.json

# 测试图标（APK 需要此文件）
curl -I http://YOUR_DEPLOY_HOST:PORT/trip-logo.png
```

如果无法访问，请检查：
- ✅ 防火墙是否开放端口
- ✅ Docker 容器是否正常运行 (`docker-compose ps`)
- ✅ Nginx 配置是否正确（如使用 Nginx）

### 步骤 3: 运行 APK 重建脚本

```bash
bash rebuild_apk.sh
```

**脚本执行流程：**

1. **检查依赖**: 验证 Node.js 和 Java 是否已安装
2. **输入部署地址**: 
   ```
   请输入您的部署地址（甲方实际访问地址）:
   示例 1: 192.168.1.100:5010 (IP + 端口)
   示例 2: trip.example.com (域名，使用 Nginx 80/443)
   示例 3: trip.example.com:5010 (域名 + 自定义端口)
   请输入部署地址: 
   ```
   
3. **验证服务**: 自动检查部署地址是否可访问
4. **备份配置**: 自动备份 `twa-manifest.json` → `twa-manifest.json.backup`
5. **更新配置**: 自动更新 `twa-manifest.json` 中的所有 URL
6. **输入密码**: 
   - **Keystore password**: Android 签名密钥库密码（默认: `123456`）
   - **Key password**: 密钥密码（默认: `123456`）
   
   ⚠️ **重要**: 必须使用与首次构建时相同的密码，否则无法更新 APK
   
7. **构建 APK**: 自动执行 `npx @bubblewrap/cli build`
8. **验证结果**: 显示生成的 APK 信息（大小、MD5）

### 步骤 4: 验证构建结果

构建完成后，检查生成的文件：

```bash
ls -lh app-release-*.apk app-release-*.aab
```

**生成的文件：**
- `app-release-signed.apk` (约 1.6MB) - **签名的 APK，用于分发**
- `app-release-bundle.aab` (约 1.8MB) - Android App Bundle
- `app-release-unsigned-aligned.apk` - 未签名版本（可忽略）

验证 APK 有效性：

```bash
# 检查文件类型
file app-release-signed.apk

# 查看 APK 内容
unzip -l app-release-signed.apk | head -n 20

# 计算 MD5
md5sum app-release-signed.apk
```

---

## 🔧 手动重建（不使用脚本）

如果无法使用自动化脚本，可以手动执行以下步骤：

### 1. 手动更新 twa-manifest.json

编辑 `twa-manifest.json`，修改以下字段：

```json
{
  "host": "192.168.1.100:5010",  // ← 修改为甲方实际地址
  "iconUrl": "http://192.168.1.100:5010/trip-logo.png",  // ← 修改
  "maskableIconUrl": "http://192.168.1.100:5010/trip-logo.png",  // ← 修改
  "monochromeIconUrl": "http://192.168.1.100:5010/trip-logo.png",  // ← 修改
  "webManifestUrl": "http://192.168.1.100:5010/manifest.json",  // ← 修改
  "fullScopeUrl": "http://192.168.1.100:5010/",  // ← 修改
  "signingKey": {
    "path": "/path/to/your/android.keystore",  // ← 修改为实际 keystore 路径
    "alias": "android"
  }
}
```

⚠️ **注意**: 
- `host` 字段**不包含协议** (http/https)
- 其他 URL 字段**必须包含完整协议**
- `signingKey.path` 必须是 keystore 文件的**绝对路径**

### 2. 清理旧文件

```bash
rm -f app-release-*.apk app-release-*.aab
```

### 3. 重新构建

```bash
npx @bubblewrap/cli build
```

输入密码时使用与首次构建相同的密码。

---

## 🛡️ 签名密钥管理

### 密钥文件

- **文件名**: `android.keystore`
- **默认位置**: 项目根目录 (`./android.keystore`)
- **默认密码**: `123456` (keystore password 和 key password)
- **别名**: `android`

### Keystore 路径检测

`rebuild_apk.sh` 脚本会自动检测 keystore 文件位置，按以下优先级：

1. **当前目录**: `./android.keystore`（最高优先级）
2. **用户主目录**: `~/android.keystore`
3. **现有配置**: 从 `twa-manifest.json` 读取现有的 `signingKey.path`
4. **不存在**: 将在当前目录创建新的 keystore

脚本会自动更新 `twa-manifest.json` 中的 `signingKey.path` 为检测到的路径。

### 甲方部署注意事项

**场景 1: 甲方首次构建 APK**
- keystore 不存在，脚本会提示创建
- 设置密码（建议使用强密码，非默认 `123456`）
- keystore 会保存在项目根目录

**场景 2: 使用已有的 keystore**
```bash
# 将 keystore 复制到项目根目录
cp /path/to/existing/android.keystore ./

# 或者创建软链接
ln -s /secure/location/android.keystore ./android.keystore

# 运行脚本，会自动检测并使用
bash rebuild_apk.sh
```

**场景 3: keystore 在自定义位置**
```bash
# 方法 1: 手动编辑 twa-manifest.json
vim twa-manifest.json
# 修改 "signingKey.path": "/custom/path/android.keystore"

# 方法 2: 环境变量（脚本暂不支持，需手动实现）
export KEYSTORE_PATH="/custom/path/android.keystore"
```

### 重要提示

1. **密钥必须保密**: `android.keystore` 是应用的签名密钥，泄露会导致安全风险
2. **密码一致性**: 更新 APK 时必须使用相同的 keystore 和密码
3. **密钥备份**: 建议备份 `android.keystore` 到安全位置
4. **生产环境**: 建议甲方使用自己的密钥和强密码（非默认 `123456`）

### 更换密钥（不推荐）

如果必须更换密钥：

1. 删除旧的 keystore: `rm android.keystore`
2. 重新初始化: `npx @bubblewrap/cli init`
3. 重新构建: `npx @bubblewrap/cli build`

⚠️ **警告**: 更换密钥后，用户无法直接升级旧版本 APK，必须卸载后重新安装。

---

## 📦 APK 分发流程

### 1. 构建完成后

```bash
# 生成构建信息文件
cat > APK_BUILD_INFO.txt <<EOF
应用名称: 旅游环境01
APK 文件: app-release-signed.apk
构建时间: $(date '+%Y-%m-%d %H:%M:%S')
绑定地址: YOUR_DEPLOY_HOST
MD5 校验: $(md5sum app-release-signed.apk | cut -d' ' -f1)
文件大小: $(du -h app-release-signed.apk | cut -f1)
EOF

cat APK_BUILD_INFO.txt
```

### 2. 打包交付文件

```bash
# 创建交付目录
mkdir -p delivery/apk

# 复制必要文件
cp app-release-signed.apk delivery/apk/
cp APK_BUILD_INFO.txt delivery/apk/
cp docs/APK_INSTALL_GUIDE.md delivery/apk/  # 安装指南

# 打包
tar -czf apk-delivery-$(date +%Y%m%d).tar.gz delivery/apk/
```

### 3. 交付给甲方

提供以下文件：
- ✅ `app-release-signed.apk` - 签名的 APK 文件
- ✅ `APK_BUILD_INFO.txt` - 构建信息（含 MD5 校验）
- ✅ `APK_INSTALL_GUIDE.md` - 安装指南（用户文档）

---

## 📱 用户安装流程

### Android 设备要求

- **最低版本**: Android 5.0 (API 21)
- **推荐版本**: Android 8.0+ (API 26+)
- **Chrome 版本**: Chrome 72+ (TWA 必需)

### 安装步骤

1. **下载 APK**: 将 `app-release-signed.apk` 传输到 Android 设备
2. **启用未知来源**: 设置 → 安全 → 允许安装未知来源应用
3. **安装 APK**: 点击 APK 文件，按提示安装
4. **首次启动**: 应用会自动连接到部署的 Rails 服务器

### 验证安装

打开应用后，检查：
- ✅ 应用图标正确显示
- ✅ 可以正常加载页面内容
- ✅ 登录/注册功能正常
- ✅ 图片和静态资源加载正常

---

## 🔄 更新 APK 流程

### 何时需要更新 APK？

以下情况需要重新构建并分发 APK：

1. **部署地址变更** (IP/域名/端口变化)
2. **应用图标更新** (更换 logo)
3. **应用名称变更** (修改 `launcherName`)
4. **版本升级** (更新 `appVersionCode` 和 `appVersionName`)

### 更新步骤

1. **修改版本号**:
   ```bash
   # 编辑 twa-manifest.json
   vim twa-manifest.json
   
   # 修改版本信息
   "appVersionName": "2",  // 版本名称（用户可见）
   "appVersionCode": 2      // 版本号（必须递增）
   ```

2. **重新构建**:
   ```bash
   bash rebuild_apk.sh
   ```

3. **使用相同密码**: 必须使用与首次构建相同的 keystore 密码

4. **分发新版本**: 用户可直接安装覆盖旧版本（无需卸载）

---

## ⚠️ 常见问题

### 1. 构建失败：Android SDK licenses

**错误信息**:
```
Failed to install the following Android SDK packages as some licences have not been accepted.
```

**解决方案**:
```bash
# 定位 sdkmanager
find ~/.bubblewrap -name sdkmanager

# 接受许可证
yes | /path/to/sdkmanager --sdk_root=/path/to/android_sdk --licenses
```

### 2. 密码错误：Keystore password

**错误信息**:
```
Keystore was tampered with, or password was incorrect
```

**解决方案**:
- 使用与首次构建时相同的密码
- 如果忘记密码，必须删除 `android.keystore` 并重新初始化（用户需卸载旧版）

### 3. APK 无法连接服务器

**可能原因**:
1. 部署地址配置错误（检查 `twa-manifest.json` 中的 `host` 字段）
2. 防火墙阻止端口访问
3. Rails 服务未启动
4. 设备网络无法访问部署地址

**解决方案**:
```bash
# 在设备上测试连接
# 1. 使用浏览器访问 http://YOUR_DEPLOY_HOST:PORT
# 2. 确认可以正常加载页面

# 在服务器上检查服务状态
docker-compose -f docker-compose.production.yml ps
docker-compose -f docker-compose.production.yml logs -f web
```

### 4. 图标不显示

**可能原因**:
- 图标文件路径错误
- 图标 URL 无法访问

**解决方案**:
```bash
# 测试图标 URL
curl -I http://YOUR_DEPLOY_HOST:PORT/trip-logo.png

# 检查 Rails public 目录
ls -lh public/trip-logo.png

# 如果缺失，从 app/assets/images 复制
cp app/assets/images/trip-logo.png public/
```

### 5. Keystore 路径错误

**错误信息**:
```
Keystore file does not exist: /home/runner/app/android.keystore
```

**解决方案**:
```bash
# 检查 keystore 文件位置
find . -name "android.keystore" -o -name "*.keystore"

# 方法 1: 移动 keystore 到项目根目录
mv /old/path/android.keystore ./

# 方法 2: 手动修改 twa-manifest.json 中的 path
vim twa-manifest.json
# 修改 "signingKey.path" 为实际路径

# 重新运行脚本
bash rebuild_apk.sh
```

**重要**: `rebuild_apk.sh` 脚本会自动检测并更新 keystore 路径，但如果手动修改了 `twa-manifest.json`，请确保路径为**绝对路径**。

### 6. 构建时间过长

**正常现象**: 首次构建需要下载 Android SDK (约 500MB)，耗时约 15-20 分钟

**解决方案**:
- 耐心等待，不要中断
- 后续构建会快很多（约 2-3 分钟）
- 可使用 `npx @bubblewrap/cli build --skipPwaValidation` 跳过 PWA 验证（加快速度）

---

## 🧪 测试清单

构建完成后，执行以下测试：

### 服务器端测试

```bash
# 1. 检查 Rails 服务状态
docker-compose -f docker-compose.production.yml ps

# 2. 测试主页访问
curl -I http://YOUR_DEPLOY_HOST:PORT/

# 3. 测试 PWA manifest
curl http://YOUR_DEPLOY_HOST:PORT/manifest.json

# 4. 测试图标访问
curl -I http://YOUR_DEPLOY_HOST:PORT/trip-logo.png

# 5. 测试 API 健康检查
curl http://YOUR_DEPLOY_HOST:PORT/api/v1/health
```

### APK 测试

```bash
# 1. 验证 APK 文件完整性
file app-release-signed.apk
# 输出应包含: Zip archive data

# 2. 检查 APK 签名
unzip -l app-release-signed.apk | grep META-INF
# 应包含: CERT.RSA, CERT.SF, MANIFEST.MF

# 3. 计算 MD5 校验和
md5sum app-release-signed.apk

# 4. 查看 APK 大小
du -h app-release-signed.apk
# 应约 1.6MB
```

### 设备端测试

- [ ] APK 可正常安装
- [ ] 应用图标正确显示
- [ ] 启动无闪退
- [ ] 首页内容正常加载
- [ ] 可正常登录/注册
- [ ] 图片和静态资源正常
- [ ] 可正常浏览和预订
- [ ] 网络请求正常

---

## 📚 相关文档

- [部署指南](DEPLOYMENT_GUIDE.md) - 完整的 Rails 应用部署文档
- [快速部署](QUICK_DEPLOY.md) - 5 分钟快速部署指南
- [Docker 部署方案](DOCKER_DEPLOYMENT.md) - Docker 商业化部署总结
- [APK 安装指南](APK_INSTALL_GUIDE.md) - 用户端 APK 安装文档

---

## 🆘 技术支持

如遇到问题，请检查：

1. **日志文件**: `docker-compose logs -f web`
2. **构建日志**: Bubblewrap CLI 的输出信息
3. **网络连接**: 确认设备可访问部署地址
4. **防火墙设置**: 确认端口已开放

---

## 📋 总结

| 场景 | 操作 | 文件 |
|------|------|------|
| 首次部署 | 运行 `deploy.sh` | Rails 应用 |
| 生成 APK | 运行 `rebuild_apk.sh` | APK 文件 |
| 更换域名 | 重新运行 `rebuild_apk.sh` | 新 APK |
| 版本升级 | 修改版本号 + `rebuild_apk.sh` | 新版本 APK |
| 更换图标 | 更新图标文件 + `rebuild_apk.sh` | 新 APK |

**核心原则**: APK 和部署地址强绑定，地址变更必须重新构建 APK。
