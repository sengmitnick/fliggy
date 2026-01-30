# rake validator:simulate API 端点校验功能

## 概述

为了防止 `rake validator:simulate` 因缺失必需的 API 端点而报错无法使用，现已集成 API 可用性检查。

## 改进内容

### 1. 自动检查必需的 API 端点

在运行验证器测试之前，`rake validator:simulate` 现在会自动检查以下 3 个必需的 API 端点：

| HTTP 方法 | 路径 | 描述 |
|----------|------|------|
| GET | `/api/tasks` | 获取任务列表 |
| POST | `/api/tasks/:id/start` | 创建训练会话 |
| POST | `/api/verify/run` | 验证接口 |

### 2. 执行流程

```
rake validator:simulate 执行步骤：

Step 0: 🔌 检查必需的 API 端点
  ✓ GET    /api/tasks                   - 获取任务列表
  ✓ POST   /api/tasks/:id/start          - 创建训练会话
  ✓ POST   /api/verify/run               - 验证接口
  ✅ All required API endpoints are available

Step 1: 🔍 检查权重总和
  ✅ All validators have correct weight sums (total = 100)

Step 2: 🧪 运行模拟测试
  ...
```

### 3. 错误处理

如果任何 API 端点缺失，任务会立即失败并显示错误：

```
❌ API Endpoint Errors Found:
----------------------------------------------------------------------
  → POST /api/tasks/:id/start - 路由不存在
----------------------------------------------------------------------

❌ 1 required API endpoint(s) are missing
Please ensure all required APIs are properly configured in routes.rb
```

## 配置位置

### 路由配置

确保 `config/routes.rb` 中包含以下路由：

```ruby
namespace :api do
  # 验证系统 API
  get 'tasks', to: 'verify#index'                         # 获取所有任务列表
  post 'tasks/:id/start', to: 'verify#start_task'         # 创建训练会话
  post 'verify/run', to: 'verify#run_verification'        # 验证接口
end
```

### 控制器实现

确保 `app/controllers/api/verify_controller.rb` 实现了以下方法：

- `index` - 处理 GET /api/tasks
- `start_task` - 处理 POST /api/tasks/:id/start
- `run_verification` - 处理 POST /api/verify/run

## 代码改动

### 1. lib/tasks/validator.rake

添加了 Step 0：检查必需的 API 端点

```ruby
# Step 0: 检查必需的 API 端点
puts "🔌 Step 0: Checking required API endpoints..."
api_errors = []

required_apis = [
  { method: 'GET', path: '/api/tasks', description: '获取任务列表' },
  { method: 'POST', path: '/api/tasks/:id/start', description: '创建训练会话' },
  { method: 'POST', path: '/api/verify/run', description: '验证接口' }
]

required_apis.each do |api|
  # 检查路由是否存在
  route_found = Rails.application.routes.routes.any? do |route|
    route.verb.match?(api[:method]) && 
    route.path.spec.to_s.gsub('(.:format)', '').match?(api[:path].gsub(':id', '[^/]+'))
  end
  
  # 记录错误或成功
end

# 如果有错误，立即退出
exit 1 if api_errors.any?
```

### 2. .clackyrules

在 "Testing Requirements" 部分添加了 Validator Testing 规则：

```markdown
**Validator Testing**:
- **CRITICAL**: `rake validator:simulate` automatically checks 3 required API endpoints before running tests:
  - `GET /api/tasks` - 获取任务列表
  - `POST /api/tasks/:id/start` - 创建训练会话
  - `POST /api/verify/run` - 验证接口
- If any API endpoint is missing, the task will fail with error before running validator simulations
- Ensure these routes are properly configured in `config/routes.rb` before running `rake validator:simulate`
- Run `rake validator:simulate` after creating/modifying validators to ensure all tests pass
```

## 使用方法

### 正常使用

```bash
# 运行所有验证器测试
rake validator:simulate

# 运行单个验证器测试
rake validator:simulate_single[v001_book_budget_hotel_validator]
```

### 验证 API 端点

如果需要单独验证 API 端点是否正确配置，可以运行：

```bash
# 检查所有 /api/tasks 相关路由
rails runner "puts Rails.application.routes.routes.select { |r| r.path.spec.to_s.include?('api/tasks') }.map { |r| [r.verb, r.path.spec.to_s] }.inspect"

# 检查 /api/verify/run 路由
rails runner "puts Rails.application.routes.routes.select { |r| r.path.spec.to_s.include?('api/verify/run') }.map { |r| [r.verb, r.path.spec.to_s] }.inspect"
```

## 优点

1. **提前发现问题**：在运行验证器之前就发现 API 配置问题
2. **清晰的错误提示**：明确指出缺失的 API 端点
3. **避免浪费时间**：不会在运行验证器测试到一半时才发现 API 不可用
4. **文档化要求**：明确记录验证器系统需要哪些 API 端点

## 相关文件

- `lib/tasks/validator.rake` - 任务定义和 API 检查逻辑
- `.clackyrules` - 项目规则和测试要求
- `config/routes.rb` - API 路由配置
- `app/controllers/api/verify_controller.rb` - API 控制器实现

## 测试验证

```bash
# 1. 检查语法
ruby -c lib/tasks/validator.rake

# 2. 验证路由存在
rails runner "puts Rails.application.routes.routes.select { |r| r.path.spec.to_s.include?('api/tasks') || r.path.spec.to_s.include?('api/verify/run') }.map { |r| [r.verb, r.path.spec.to_s] }.inspect"

# 3. 运行完整测试
rake validator:simulate
```

## 总结

通过添加 API 端点校验，`rake validator:simulate` 现在更加健壮和用户友好。它能够在早期阶段发现配置问题，避免在运行验证器测试时才出现神秘的 API 调用失败错误。
