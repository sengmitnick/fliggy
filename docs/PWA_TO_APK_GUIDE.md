# 使用 Bubblewrap 将 PWA 打包成 APK 指南

本指南介绍如何使用 `@bubblewrap/cli` 将当前应用的 PWA 打包成 Android APK 文件。

## 前提条件

- Node.js 和 npm 已安装
- 应用已经具备 PWA 功能（manifest.json 和 service worker）
- 应用可以通过公网 URL 访问

## 步骤 1：确认 PWA 配置

### 1.1 检查 manifest.json

确认 `public/manifest.json` 文件已创建并包含必要信息：

```json
{
  "name": "旅游环境01",
  "short_name": "旅游环境01",
  "icons": [
    {
      "src": "/trip-logo.png",
      "type": "image/png",
      "sizes": "192x192"
    },
    {
      "src": "/trip-logo.png",
      "type": "image/png",
      "sizes": "512x512",
      "purpose": "any maskable"
    }
  ],
  "start_url": "/",
  "display": "standalone",
  "scope": "/",
  "description": "旅游环境01 - A Progressive Web App built with Rails",
  "theme_color": "#ffc105",
  "background_color": "#ffc105",
  "orientation": "any",
  "categories": ["productivity", "utilities"]
}
```

### 1.2 测试 manifest.json 访问

```bash
curl https://YOUR_DOMAIN/manifest.json
```

应该能看到正确的 JSON 响应。

### 1.3 确认应用运行

访问你的应用 URL，确保能正常访问。

## 步骤 2：初始化 Bubblewrap 项目

在本地开发环境（不在服务器上），运行以下命令：

```bash
npx @bubblewrap/cli init --manifest=https://YOUR_DOMAIN/manifest.json
```

### 交互式问题回答

Bubblewrap 会询问几个问题：

#### 1. 是否安装 JDK？
```
? Do you want Bubblewrap to install the JDK (recommended)?
  (Enter "No" to use your own JDK 17 installation) (Y/n)
```
**推荐回答**: `Y` （让 Bubblewrap 自动安装 JDK）

#### 2. Android SDK 位置
如果系统已有 Android SDK，会询问路径。如果没有，Bubblewrap 会自动下载安装。

#### 3. 应用包名
```
? Package name (Example: com.example.myapp):
```
**示例**: `com.tourism.app01`

#### 4. 应用存储位置
会询问是否在 Google Play 上架。根据你的需求回答。

### 完成初始化

初始化完成后，会在当前目录生成一个 Android 项目目录（通常以应用名命名）。

## 步骤 3：构建 APK

进入生成的项目目录，然后构建 APK：

```bash
cd YOUR_APP_DIRECTORY
npx @bubblewrap/cli build
```

构建过程可能需要几分钟。

## 步骤 4：获取 APK 文件

构建完成后，APK 文件位于：

```
./app-release-signed.apk
```

## 步骤 5：测试 APK

### 在模拟器上测试

如果你有 Android 模拟器，可以这样安装：

```bash
adb install app-release-signed.apk
```

### 在真机上测试

1. 将 APK 文件传输到手机
2. 在手机上启用"允许安装未知来源的应用"
3. 点击 APK 文件进行安装

## 步骤 6：配置 Digital Asset Links（可选但重要）

为了验证应用所有权，需要配置 Digital Asset Links。

### 6.1 生成 assetlinks.json

使用 [Peter's Asset Link Tool](https://play.google.com/store/apps/details?id=dev.conn.assetlinkstool) 或手动生成。

### 6.2 部署 assetlinks.json

将文件放置在：

```
https://YOUR_DOMAIN/.well-known/assetlinks.json
```

确保该文件可以公开访问。

## 常见问题

### Q1: manifest.json 无法访问
**解决方案**: 确保文件在 `public/` 目录下，并且 Rails 应用正在运行。

### Q2: 图标不显示
**解决方案**: 确保 manifest.json 中的图标路径正确，并且图标文件存在。建议使用 PNG 格式，尺寸至少 192x192 和 512x512。

### Q3: APK 安装后无法打开
**解决方案**: 检查应用的 `start_url` 是否正确，并且服务器可以从 Android 设备访问。

### Q4: 构建失败
**解决方案**: 
- 确保 Node.js 版本 >= 14
- 清除缓存：`rm -rf node_modules ~/.gradle`
- 重新安装依赖

## 高级配置

### 自定义应用图标

将高质量的 PNG 图标（512x512）放入项目，并在 manifest.json 中引用：

```json
{
  "icons": [
    {
      "src": "/path/to/icon-192.png",
      "type": "image/png",
      "sizes": "192x192"
    },
    {
      "src": "/path/to/icon-512.png",
      "type": "image/png",
      "sizes": "512x512",
      "purpose": "any maskable"
    }
  ]
}
```

### 配置启动画面

在 manifest.json 中添加：

```json
{
  "background_color": "#ffc105",
  "theme_color": "#ffc105"
}
```

### 更新 APK

当应用有更新时：

```bash
cd YOUR_APP_DIRECTORY
npx @bubblewrap/cli update
npx @bubblewrap/cli build
```

## 上传到 Google Play

### 1. 准备发布

确保已完成：
- [ ] 配置 Digital Asset Links
- [ ] 测试 APK 在多个设备上运行正常
- [ ] 准备应用截图和描述

### 2. 创建 Google Play 开发者账号

访问 [Google Play Console](https://play.google.com/console) 注册（需支付 $25 注册费）。

### 3. 创建应用

1. 登录 Play Console
2. 点击"创建应用"
3. 填写应用信息
4. 上传 `app-release-signed.apk`
5. 填写商店信息（标题、描述、截图等）
6. 提交审核

## 参考资源

- [Bubblewrap 官方文档](https://github.com/GoogleChromeLabs/bubblewrap)
- [PWA 指南](https://web.dev/progressive-web-apps/)
- [Trusted Web Activity](https://developers.google.com/web/android/trusted-web-activity)
- [Google Play 发布指南](https://support.google.com/googleplay/android-developer/answer/9859152)

## 当前应用信息

- **应用名称**: 旅游环境01
- **公网地址**: https://3000-f422deffffb4-web.clackypaas.com
- **Manifest URL**: https://3000-f422deffffb4-web.clackypaas.com/manifest.json
- **主题色**: #ffc105

## 快速命令参考

```bash
# 初始化项目
npx @bubblewrap/cli init --manifest=https://3000-f422deffffb4-web.clackypaas.com/manifest.json

# 构建 APK
npx @bubblewrap/cli build

# 更新项目配置
npx @bubblewrap/cli update

# 验证配置
npx @bubblewrap/cli validate --url=https://3000-f422deffffb4-web.clackypaas.com
```

---

完成这些步骤后，你就成功将 PWA 打包成了 Android APK！
