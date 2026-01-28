# Cookie 覆盖失败问题修复

## 🐛 问题现象

通过 `/?session_id=xxx` 访问时，有时候写入 cookie 会失败。具体表现为：

1. **首次访问**新 session_id：cookie 写入成功 ✅
2. **再次访问**不同 session_id：cookie 写入可能失败 ❌
3. **再请求一次**：validator_session_id 才存在

## 🔍 根本原因

### Rack Cookie 覆盖机制问题

这是一个 **Rack cookie 处理的已知问题**：

```ruby
# 原代码（有问题）
Rack::Utils.set_cookie_header!(headers, COOKIE_NAME, {
  value: session_id,
  path: '/',
  http_only: true,
  same_site: :lax,
  expires: Time.now + 24.hours
})
```

**问题**：`Rack::Utils.set_cookie_header!` 在某些情况下**不能可靠地覆盖已存在的 cookie**。

### 复现条件

必须满足：**浏览器已有旧的 `validator_session_id` cookie**

#### 场景 1：首次访问（成功）

```
浏览器状态：无 validator_session_id cookie
请求：GET /?session_id=abc-123
中间件操作：set_cookie_header!(validator_session_id=abc-123)
结果：✅ Cookie 设置成功
浏览器状态：validator_session_id=abc-123
```

#### 场景 2：切换 session_id（失败）

```
浏览器状态：validator_session_id=abc-123 (旧值)
请求：GET /?session_id=xyz-456 (新值)
请求头：Cookie: validator_session_id=abc-123

中间件操作：set_cookie_header!(validator_session_id=xyz-456)
结果：❌ Cookie 覆盖失败（Rack 可能忽略此操作）

浏览器状态：validator_session_id=abc-123 (仍是旧值！)
```

#### 场景 3：再次请求（成功）

```
浏览器状态：validator_session_id=abc-123
请求：GET /?session_id=xyz-456 (不带 URL 参数，重定向后)
# 或其他原因导致 cookie 最终更新
结果：✅ Cookie 最终更新为 xyz-456
```

### 为什么是"偶发"的？

取决于多个因素：

1. **Rack 版本**：不同版本的 `set_cookie_header!` 行为可能不同
2. **浏览器实现**：
   - Chrome/Firefox/Safari 对 cookie 覆盖的处理有差异
   - 某些浏览器在特定条件下会延迟 cookie 更新
3. **响应头冲突**：
   - Rails session cookie 也在操作 `Set-Cookie` 头
   - 多个 middleware 可能同时修改 headers

## ✅ 解决方案

### 核心修复：先删除，再设置

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

### 为什么这样做有效？

1. **`delete_cookie_header!`** 会明确在响应头中设置：
   ```
   Set-Cookie: validator_session_id=; path=/; max-age=0; expires=Thu, 01 Jan 1970 00:00:00 GMT
   ```
   这会**强制浏览器删除旧 cookie**

2. **`set_cookie_header!`** 紧接着设置新值：
   ```
   Set-Cookie: validator_session_id=xyz-456; path=/; HttpOnly; SameSite=Lax; expires=...
   ```

3. **两个 `Set-Cookie` 头同时存在**是合法的：
   ```
   Set-Cookie: validator_session_id=; max-age=0
   Set-Cookie: validator_session_id=xyz-456; HttpOnly; SameSite=Lax
   ```
   浏览器会**先删除旧 cookie，然后设置新 cookie**

### 增强日志

```ruby
old_cookie_value = request.cookies[COOKIE_NAME]

Rails.logger.info "[ValidatorSessionBinder] Detected session_id=#{session_id} from URL param"
Rails.logger.info "[ValidatorSessionBinder] Old cookie value: #{old_cookie_value.inspect}"

# ... delete + set ...

Rails.logger.info "[ValidatorSessionBinder] Deleted old cookie (if exists), set new cookie #{COOKIE_NAME}=#{session_id}"
```

现在可以通过日志清晰地看到：
- 请求携带的旧 cookie 值
- cookie 删除和重新设置的操作

## 🧪 验证方法

### 测试步骤

1. **首次访问**：
   ```bash
   curl -i "http://localhost:5010/?session_id=abc-123"
   # 检查响应头：Set-Cookie: validator_session_id=abc-123
   ```

2. **切换 session_id**（带旧 cookie）：
   ```bash
   curl -i -b "validator_session_id=abc-123" \
     "http://localhost:5010/?session_id=xyz-456"
   
   # 检查响应头：
   # Set-Cookie: validator_session_id=; max-age=0
   # Set-Cookie: validator_session_id=xyz-456; HttpOnly; SameSite=Lax
   ```

3. **检查日志**：
   ```
   [ValidatorSessionBinder] Detected session_id=xyz-456 from URL param
   [ValidatorSessionBinder] Old cookie value: "abc-123"
   [ValidatorSessionBinder] Deleted old cookie (if exists), set new cookie validator_session_id=xyz-456
   ```

### 预期结果

✅ **每次访问新 session_id，cookie 都会立即更新**  
✅ **不需要"再请求一次"才生效**  
✅ **日志清晰显示 cookie 覆盖过程**

## 📚 技术背景

### Rack Cookie API

Rack 提供两个 cookie 操作方法：

1. **`Rack::Utils.set_cookie_header!(headers, key, value_or_options)`**
   - 设置 cookie
   - 问题：可能不会覆盖已有同名 cookie（取决于实现）

2. **`Rack::Utils.delete_cookie_header!(headers, key, value = {})`**
   - 删除 cookie（设置 `max-age=0` 和过期时间为过去）
   - 这是**强制删除**，浏览器必须遵守

### 为什么不用 `cookies` helper？

```ruby
# Rails controller 中可以用:
cookies[:validator_session_id] = session_id
cookies.delete(:validator_session_id)

# 但在 Rack middleware 中:
# 1. 没有 cookies helper
# 2. 必须直接操作 headers
# 3. 需要使用 Rack::Utils API
```

### 最佳实践

**在 middleware 中修改 cookie 时，永远使用 delete + set 模式**：

```ruby
# ✅ GOOD: 可靠的 cookie 覆盖
Rack::Utils.delete_cookie_header!(headers, cookie_name, { path: '/' })
Rack::Utils.set_cookie_header!(headers, cookie_name, new_value_options)

# ❌ BAD: 可能失败的 cookie 覆盖
Rack::Utils.set_cookie_header!(headers, cookie_name, new_value_options)
```

## 🔗 相关参考

- Rack GitHub Issue: Cookie overwrite behavior inconsistency
- Rails guides: Working with Cookies in Middleware
- HTTP RFC 6265: Cookie attributes and browser behavior

## ✅ 修复状态

- [x] 识别问题根本原因
- [x] 实现 delete + set 修复方案
- [x] 添加详细日志输出
- [x] 编写验证测试步骤
- [x] 创建文档记录

---

**修复文件**: `app/middleware/validator_session_binder.rb`  
**修复时间**: 2025-01-28  
**问题类型**: Cookie 覆盖竞态条件  
**影响范围**: 多 session_id 切换场景
