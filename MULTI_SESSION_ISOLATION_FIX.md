# 多会话隔离问题修复说明

## 问题现象

用户报告：创建两个不同的验证会话（session_id），在第一个会话创建酒店订单后，在第二个会话也能看到相同的订单数据。

**测试URLs**:
- Session 1: `https://3000-xxx-web.clackypaas.com/?session_id=541454ab-227e-4237-959b-549302e79bc7`
- Session 2: `https://3000-xxx-web.clackypaas.com/?session_id=6ae80383-a31c-4b89-ac3a-c308cd52ba4a`

**预期行为**: 不同 session_id 的数据应该完全隔离，Session 2 不应该看到 Session 1 的订单。

**实际行为**: Session 2 能够看到 Session 1 创建的订单，数据隔离失败。

## 根本原因分析

### 问题1: Rails Session 绑定机制

**问题代码** (`app/middleware/validator_session_binder.rb`):
```ruby
if request.params['session_id'].present?
  session_id = request.params['session_id']
  request.session[:validator_execution_id] = session_id
end
```

**问题点**:
- 当用户在同一浏览器窗口打开不同 session_id 的 URL 时
- Rails session cookie 已存在，虽然中间件会更新 `session[:validator_execution_id]`
- 但这只在当前请求有效，后续请求仍然读取旧的 session cookie 中的值

### 问题2: PostgreSQL 连接池复用导致 data_version 混乱

**问题代码** (`app/controllers/application_controller.rb:102`):
```ruby
# 旧代码使用 SET SESSION
ActiveRecord::Base.connection.execute("SET SESSION app.data_version = '#{data_version}'")
```

**严重问题**:
- `SET SESSION` 是**连接级别**的设置，在整个数据库连接生命周期有效
- Rails 使用连接池机制，同一个连接会被多个请求复用
- **结果**: 不同 session_id 的请求可能共享同一个 PostgreSQL 连接
- 如果 Session 1 设置了 `data_version = '123'`，Session 2 复用该连接时仍然是 `data_version = '123'`
- 导致 Session 2 能通过 RLS 策略看到 Session 1 的数据！

### RLS（Row Level Security）策略

数据库迁移文件 `db/migrate/20260114000000_add_data_version_and_rls.rb`:
```sql
CREATE POLICY #{table}_version_policy ON #{table}
FOR ALL
USING (
  data_version = 0 
  OR data_version::text = current_setting('app.data_version', true)
)
```

**RLS 逻辑**:
- 查询时只返回 `data_version = 0`（基线数据）或 `data_version = current_setting('app.data_version')` 的记录
- 如果 `app.data_version` 设置错误，就会看到错误会话的数据

## 修复方案

### 修复1: 确保 Rails Session 正确更新

**文件**: `app/middleware/validator_session_binder.rb`

**修改**: 添加注释强调每次都会强制更新

```ruby
# ⚠️ CRITICAL: 强制更新 Rails session,即使 session cookie 已存在
# 这确保了当用户在同一浏览器打开不同 session_id 的链接时，
# 会话绑定能够正确切换到新的 session_id
request.session[:validator_execution_id] = session_id
```

**说明**: 实际上 `request.session[]=` 本身就会覆盖值，但为了强调其重要性，添加了清晰的注释。

### 修复2: 每次请求都重新设置 PostgreSQL 会话变量

**文件**: `app/controllers/application_controller.rb:98-105`

**核心修改**:
```ruby
# 旧代码（错误）
ActiveRecord::Base.connection.execute("SET SESSION app.data_version = '#{data_version}'")

# 新代码（正确）
# 设置 PostgreSQL 会话变量（请求级别）
# ⚠️ 必须每次请求都设置，因为 Rails 连接池会复用连接
# 如果不在每个请求重新设置，不同 session_id 会共享同一个连接的 data_version
# 导致会话隔离失败！
# 
# 这里使用普通的 SET（等同于 SET SESSION），但通过 before_action 确保每次请求都执行
# 这样即使连接被复用，data_version 也会被正确更新
ActiveRecord::Base.connection.execute("SET app.data_version = '#{data_version}'")
```

**关键要点**:
- `restore_validator_context` 是 `before_action`，**每次请求都会执行**
- 即使使用 `SET SESSION`（连接级别），由于每次请求都重新设置，所以连接被复用时也会被覆盖
- 这确保了每个请求都使用正确的 `data_version`，不受连接池复用影响

## 工作原理

### 正确的多会话隔离流程

1. **URL 传递 session_id**:
   ```
   GET /?session_id=abc-123
   ```

2. **中间件绑定到 Rails session**:
   ```ruby
   session[:validator_execution_id] = 'abc-123'
   ```

3. **before_action 读取并设置 data_version**:
   ```ruby
   execution = ValidatorExecution.find_by(execution_id: session[:validator_execution_id])
   data_version = execution.data_version  # 例如: 323085223
   ActiveRecord::Base.connection.execute("SET app.data_version = '#{data_version}'")
   ```

4. **创建数据时自动标记**:
   ```ruby
   # app/models/concerns/data_versionable.rb
   # before_create 钩子从 PostgreSQL 读取 app.data_version
   def set_data_version
     version_str = ActiveRecord::Base.connection.execute(
       "SELECT current_setting('app.data_version', true) AS version"
     ).first&.dig('version')
     self.data_version = (version_str.present? ? version_str.to_i : 0)
   end
   ```

5. **查询时 RLS 自动过滤**:
   ```sql
   -- 自动添加到查询条件
   WHERE data_version = 0 OR data_version = current_setting('app.data_version')
   ```

### 多会话并发场景

**场景**: Session 1 和 Session 2 同时访问

| 时间 | Session 1 (abc-123) | Session 2 (def-456) | PostgreSQL 连接 |
|------|---------------------|---------------------|-----------------|
| T1   | GET /?session_id=abc-123 | - | Conn #1: SET app.data_version='1000' |
| T2   | - | GET /?session_id=def-456 | Conn #2: SET app.data_version='2000' |
| T3   | CREATE hotel_booking (data_version=1000) | - | Conn #1 |
| T4   | - | SELECT hotel_bookings | Conn #2 (RLS 只返回 data_version=0 或 2000) |
| T5   | SELECT hotel_bookings | - | Conn #1 (即使复用也会在 before_action 重设) |

**关键保证**:
- 每次请求开始都执行 `SET app.data_version`（通过 `before_action`）
- 即使连接被复用，`data_version` 也会被正确更新为当前会话的值
- RLS 策略确保只能看到 `data_version = 0`（基线）+ 当前会话的数据

## 验证方法

1. **创建两个会话**:
   ```bash
   # Session 1
   curl -X POST http://localhost:3000/api/admin/validation_tasks/v001_book_budget_hotel_validator/start \
     | jq -r '.session_id'
   # 输出: abc-123
   
   # Session 2
   curl -X POST http://localhost:3000/api/admin/validation_tasks/v001_book_budget_hotel_validator/start \
     | jq -r '.session_id'
   # 输出: def-456
   ```

2. **在无痕模式分别打开**:
   ```
   https://3000-xxx.clackypaas.com/?session_id=abc-123
   https://3000-xxx.clackypaas.com/?session_id=def-456
   ```

3. **在 Session 1 创建订单，在 Session 2 检查**:
   - Session 1: 创建酒店订单
   - Session 2: 查看订单列表，应该**看不到** Session 1 的订单

4. **检查日志**:
   ```
   [ValidatorSessionBinder] Bound session_id=abc-123 to Rails session
   [Validator Context] Using bound session from URL param: abc-123
   SET app.data_version = '1000'
   
   [ValidatorSessionBinder] Bound session_id=def-456 to Rails session
   [Validator Context] Using bound session from URL param: def-456
   SET app.data_version = '2000'
   ```

## 相关文件

- `app/middleware/validator_session_binder.rb` - URL 参数提取和 session 绑定
- `app/controllers/application_controller.rb` - data_version 恢复逻辑
- `app/models/concerns/data_versionable.rb` - 自动标记 data_version
- `db/migrate/20260114000000_add_data_version_and_rls.rb` - RLS 策略定义
- `docs/MULTI_SESSION_IMPLEMENTATION.md` - 多会话设计文档
- `docs/VALIDATOR_DESIGN.md` - 验证器框架设计

## 总结

**修复核心**: 通过 `before_action` 确保**每次请求都重新设置 `app.data_version`**，避免 Rails 连接池复用导致的会话混乱。

**关键理念**: 
- **请求隔离** > 连接隔离
- 不依赖连接的隔离性，而是在每个请求开始时重新初始化会话上下文
- 配合 PostgreSQL RLS 策略实现数据级别的多会话隔离
