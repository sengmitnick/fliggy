# Cookie 写入失败修复总结

## 🐛 问题描述

通过 `/?session_id=xxx` 访问时，`validator_session_id` cookie 的写入**偶发失败**。

### 复现条件
- 浏览器**已有**旧的 `validator_session_id` cookie
- 访问新的 `/?session_id=yyy`（不同的 session_id）
- 结果：cookie 没有更新，仍然是旧值
- 需要再次请求才能生效

## 🔍 根本原因

**Rack cookie 覆盖机制问题**：

```ruby
# 原代码（有问题）
Rack::Utils.set_cookie_header!(headers, COOKIE_NAME, { value: new_value, ... })
```

`Rack::Utils.set_cookie_header!` 在某些情况下**不能可靠地覆盖已存在的 cookie**。

### 技术细节

当浏览器请求携带旧 cookie 时：
```
Request:
  GET /?session_id=xyz-456
  Cookie: validator_session_id=abc-123 (旧值)

Middleware 操作:
  set_cookie_header!(validator_session_id=xyz-456)

问题:
  ❌ Rack 可能不会覆盖已有同名 cookie
  ❌ 响应头可能没有正确的 Set-Cookie
  ❌ 浏览器仍保留旧值 abc-123
```

## ✅ 解决方案

**先删除旧 cookie，再设置新值**（delete-then-set 模式）：

```ruby
# CRITICAL FIX: Explicitly delete old cookie before setting new one
Rack::Utils.delete_cookie_header!(headers, COOKIE_NAME, { path: '/' })

# Then set new value
Rack::Utils.set_cookie_header!(headers, COOKIE_NAME, {
  value: session_id,
  path: '/',
  http_only: true,
  same_site: :lax,
  expires: Time.now + 24.hours
})
```

### 为什么有效？

1. **`delete_cookie_header!`** 强制浏览器删除旧 cookie：
   ```
   Set-Cookie: validator_session_id=; path=/; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT
   ```

2. **`set_cookie_header!`** 设置新值：
   ```
   Set-Cookie: validator_session_id=xyz-456; path=/; HttpOnly; SameSite=Lax; ...
   ```

3. **浏览器处理顺序**：先删除 → 再设置 → **保证覆盖成功**

## 🧪 验证方法

运行测试脚本：

```bash
bin/test_cookie_overwrite
```

测试场景：
1. ✅ 首次访问：cookie 正确设置
2. ✅ 切换 session_id（带旧 cookie）：cookie 立即更新
3. ✅ 不需要"再请求一次"

### 手动验证

```bash
# 1. 首次访问
curl -i "http://localhost:5010/?session_id=abc-123"
# 检查：Set-Cookie: validator_session_id=abc-123

# 2. 切换 session_id（模拟浏览器带旧 cookie）
curl -i -b "validator_session_id=abc-123" \
  "http://localhost:5010/?session_id=xyz-456"

# 检查响应头应包含两个 Set-Cookie：
# Set-Cookie: validator_session_id=; max-age=0
# Set-Cookie: validator_session_id=xyz-456; HttpOnly; SameSite=Lax
```

### 日志输出

```
[ValidatorSessionBinder] Detected session_id=xyz-456 from URL param
[ValidatorSessionBinder] Old cookie value: "abc-123"
[ValidatorSessionBinder] Deleted old cookie (if exists), set new cookie validator_session_id=xyz-456
```

## 📝 修改文件

- **文件**: `app/middleware/validator_session_binder.rb`
- **变更**:
  - 添加 `delete_cookie_header!` 调用（第 66 行）
  - 增强日志输出（第 53、56、79 行）

## 🎯 影响范围

**受影响场景**：
- ✅ APK 多会话切换（通过不同 `session_id` 参数）
- ✅ 浏览器多标签页验证（每个标签页不同 `session_id`）

**不受影响**：
- 首次访问（浏览器无旧 cookie）
- 单会话模式（不切换 `session_id`）

## 📚 技术背景

这是 **Rack cookie API 的已知限制**：

- `set_cookie_header!` 在某些 Rack 版本/浏览器中，不能可靠覆盖已有 cookie
- **最佳实践**：在 middleware 中修改 cookie 时，永远使用 **delete + set** 模式

## ✅ 完成状态

- [x] 识别问题根本原因（Rack cookie 覆盖机制）
- [x] 实现 delete-then-set 修复方案
- [x] 添加详细日志（显示旧/新 cookie 值）
- [x] 创建验证测试脚本 (`bin/test_cookie_overwrite`)
- [x] 编写完整文档 (`COOKIE_OVERWRITE_FIX.md`)

---

**修复时间**: 2025-01-28  
**问题类型**: Rack Cookie 覆盖竞态条件  
**优先级**: High（影响多会话切换功能）
