# 门票选择页面 UI 简化

## 问题描述
用户反馈票务选择页面的设计多余：点击"儿童票"标签后，还需要在下方再次选择具体的儿童票，造成重复操作。

## 解决方案
移除标签导航，将所有门票（成人票和儿童票）合并显示在同一个列表中，用户可以直接选择，无需两步操作。

## 技术实现

### 1. 视图文件修改
**文件**: `app/views/tickets/select.html.erb`

**改动**:
- ❌ 移除标签导航（成人票/儿童票切换按钮）
- ❌ 移除分离的 Adult Tickets Panel 和 Child Tickets Panel
- ✅ 合并为单一列表，显示所有可用门票
- ✅ 为每张票添加类型标签（蓝色"成人票" / 绿色"儿童票"）
- ❌ 移除 `data-controller="ticket-selector"` 属性

### 2. 删除不再需要的 Stimulus 控制器
**删除文件**: `app/javascript/controllers/ticket_selector_controller.ts`

**修改文件**: `app/javascript/controllers/index.ts`
- 移除 `TicketSelectorController` 的导入
- 移除 `ticket-selector` 的注册

### 3. 重新构建资源
```bash
npm run build
touch tmp/restart.txt  # 触发 Rails 重启
```

## UI 对比

### 修改前
```
游玩日期: [选择日期]

门票类型:
[成人票] [儿童票]  ← 需要先点这里

成人票选项:
○ 欢乐港湾成人票 - ¥180
```

### 修改后
```
游玩日期: [选择日期]

选择门票:
○ 欢乐港湾成人票 [成人票] - ¥180  ← 直接选择
○ 欢乐港湾儿童票 [儿童票] - ¥120
```

## 用户体验改进
1. **操作步骤减少**: 从"点击标签 → 选择票"变为"直接选择票"
2. **信息更清晰**: 所有选项一目了然，无需切换标签
3. **减少困惑**: 不会有"为什么点了儿童票还要再选一次"的疑问

## 文件修改列表
- ✏️ `app/views/tickets/select.html.erb` (简化 UI，移除标签)
- ❌ `app/javascript/controllers/ticket_selector_controller.ts` (删除)
- ✏️ `app/javascript/controllers/index.ts` (移除控制器注册)

## 测试验证
访问 `/tickets/82/select?visit_date=2026-01-25` 确认：
- ✅ 所有门票显示在同一列表中
- ✅ 每张票都有类型标签标识
- ✅ 可以直接选择任意票种
- ✅ 无 JavaScript 错误
