# 智能返回按钮功能说明

## 功能概述
实现了一个智能返回按钮，根据用户的来源页面自动决定返回行为。

## 实现位置
- **Stimulus Controller**: `app/javascript/controllers/smart_back_controller.ts`
- **视图组件**: `app/views/shared/_transport_header.html.erb`

## 工作原理

### 1. 来源检测
使用 `document.referrer` 检测用户的来源页面：

```typescript
const referrer = document.referrer
const currentHost = window.location.host

if (referrer && referrer.includes(currentHost)) {
  // 来自站内 -> 使用 history.back()
  window.history.back()
} else {
  // 来自站外或直接访问 -> 返回指定页面
  window.location.href = this.fallbackValue
}
```

### 2. 返回策略

| 场景 | 行为 |
|------|------|
| 从站内其他页面跳转 | 返回上一页 (`history.back()`) |
| 直接访问（无来源） | 返回 fallback 页面（默认首页） |
| 从外部链接进入 | 返回 fallback 页面（默认首页） |
| 浏览器历史为空 | 返回 fallback 页面（默认首页） |

### 3. 使用方式

在 `_transport_header.html.erb` 中：

```erb
<div data-controller="smart-back" data-smart-back-fallback-value="<%= return_path %>">
  <a href="#" data-action="click->smart-back#goBack">
    <%= image_tag "返回.png" %>
  </a>
</div>
```

### 4. 应用页面

该功能已应用到以下页面的返回按钮：
- `/tour_groups` - 跟团游
- `/hotels` - 酒店
- `/flights` - 机票
- `/trains` - 火车票
- `/bus_tickets` - 汽车票
- `/cars` - 租车
- `/special_flights` - 特价机票

## 用户体验提升

1. **站内导航优化**：用户从首页进入详情页，点击返回会回到首页原位置
2. **外部链接友好**：用户从外部链接直接访问详情页，点击返回会去首页而不是报错
3. **直接访问保护**：用户直接访问 URL，点击返回会安全跳转到首页

## 技术特点

- ✅ 使用 Stimulus 框架，符合项目架构
- ✅ 自动检测来源，无需手动配置
- ✅ 支持自定义 fallback 路径
- ✅ 纯前端实现，无服务器负担
- ✅ 优雅降级，确保返回按钮始终可用
