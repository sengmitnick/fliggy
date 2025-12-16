# 📡 验证任务 API 指南

## 🎯 概述

提供 REST API 接口，用于远程创建和验证机票预订任务。特别适合大模型训练场景。

### 核心流程

```
1. 创建任务 (POST /api/validation_tasks)
   ↓
2. 大模型/人工执行预订
   ↓
3. 验证结果 (POST /api/validation_tasks/:task_id/verify)
```

---

## 🚀 快速开始

### 基础示例

```bash
# 1. 创建验证任务
curl -X POST http://localhost:3000/api/validation_tasks \
  -H "Content-Type: application/json" \
  -d '{
    "departure_city": "深圳",
    "arrival_city": "武汉",
    "departure_date": "2025-01-15"
  }'

# 响应：
# {
#   "success": true,
#   "task_id": "550e8400-e29b-41d4-a716-446655440000",
#   "message": "验证任务已创建，初始状态已记录",
#   "task_info": {
#     "user_instruction": "帮我订1月15号从深圳到武汉的机票",
#     "params": { ... },
#     "initial_booking_count": 18
#   },
#   "next_step": "执行预订任务后，调用 POST /api/validation_tasks/550e8400.../verify 进行验证"
# }

# 2. 执行预订任务（大模型或人工操作）
# ...

# 3. 验证结果
curl -X POST http://localhost:3000/api/validation_tasks/550e8400-e29b-41d4-a716-446655440000/verify

# 响应：
# {
#   "success": true,
#   "task_id": "550e8400-e29b-41d4-a716-446655440000",
#   "validation_result": {
#     "valid": true,
#     "errors": [],
#     "booking_details": { ... }
#   },
#   "message": "验证通过！任务成功完成"
# }
```

---

## 📋 API 端点

### 1. 创建验证任务

**端点**：`POST /api/validation_tasks`

**描述**：创建一个新的验证任务并记录初始状态

**请求参数**：

| 参数 | 类型 | 必填 | 说明 | 示例 |
|------|------|------|------|------|
| `departure_city` | string | ✅ | 出发城市 | `"深圳"` |
| `arrival_city` | string | ✅ | 到达城市 | `"武汉"` |
| `departure_date` | string | ✅ | 出发日期（YYYY-MM-DD） | `"2025-01-15"` |
| `user_id` | integer | ❌ | 用户ID | `1`（默认） |
| `passenger_name` | string | ❌ | 乘客姓名 | `"张三"` |
| `contact_phone` | string | ❌ | 联系电话 | `"13800138000"` |
| `insurance_required` | boolean | ❌ | 必须购买保险 | `true` |
| `insurance_forbidden` | boolean | ❌ | 不能购买保险 | `true` |
| `should_complete_payment` | boolean | ❌ | 是否完成支付 | `true`（默认） |

**请求示例**：

```bash
curl -X POST http://localhost:3000/api/validation_tasks \
  -H "Content-Type: application/json" \
  -d '{
    "departure_city": "北京",
    "arrival_city": "上海",
    "departure_date": "2025-01-20",
    "passenger_name": "张三",
    "contact_phone": "13800138000",
    "insurance_required": true
  }'
```

**成功响应**（201 Created）：

```json
{
  "success": true,
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "message": "验证任务已创建，初始状态已记录",
  "task_info": {
    "user_instruction": "帮我订1月20号从北京到上海的机票，乘客姓名张三，手机号13800138000，要买保险",
    "params": {
      "user_id": 1,
      "departure_city": "北京",
      "arrival_city": "上海",
      "departure_date": "2025-01-20",
      "passenger_name": "张三",
      "contact_phone": "13800138000",
      "insurance_required": true,
      "should_complete_payment": true
    },
    "initial_booking_count": 18
  },
  "next_step": "执行预订任务后，调用 POST /api/validation_tasks/550e8400-e29b-41d4-a716-446655440000/verify 进行验证"
}
```

**失败响应**（400 Bad Request）：

```json
{
  "success": false,
  "error": "缺少必填参数：departure_city, departure_date",
  "missing_params": ["departure_city", "departure_date"]
}
```

---

### 2. 验证任务结果

**端点**：`POST /api/validation_tasks/:task_id/verify`

**描述**：验证任务是否成功完成

**路径参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `task_id` | string | ✅ | 任务ID（创建时返回的） |

**请求示例**：

```bash
curl -X POST http://localhost:3000/api/validation_tasks/550e8400-e29b-41d4-a716-446655440000/verify
```

**成功响应**（200 OK）：

```json
{
  "success": true,
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "validation_result": {
    "valid": true,
    "errors": [],
    "booking_details": {
      "booking_id": 19,
      "flight": {
        "flight_number": "CZ3456",
        "departure_city": "北京",
        "destination_city": "上海",
        "departure_time": "2025-01-20T15:30:00+08:00",
        "arrival_time": "2025-01-20T17:50:00+08:00",
        "departure_date": "2025-01-20"
      },
      "passenger": {
        "name": "张三",
        "phone": "13800138000"
      },
      "insurance": {
        "type": "优享保障",
        "price": 50
      },
      "status": "paid",
      "total_price": 850,
      "created_at": "2025-01-15T10:30:00+08:00"
    }
  },
  "message": "验证通过！任务成功完成"
}
```

**失败响应**（422 Unprocessable Entity）：

```json
{
  "success": false,
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "validation_result": {
    "valid": false,
    "errors": [
      "未创建新的预订记录",
      "出发城市不匹配。期望：北京，实际：深圳"
    ],
    "booking_details": null
  },
  "message": "验证失败！任务未完成"
}
```

**任务不存在**（404 Not Found）：

```json
{
  "success": false,
  "error": "任务不存在或已过期",
  "task_id": "invalid-task-id"
}
```

---

### 3. 查询任务状态

**端点**：`GET /api/validation_tasks/:task_id`

**描述**：查询任务当前状态

**请求示例**：

```bash
curl http://localhost:3000/api/validation_tasks/550e8400-e29b-41d4-a716-446655440000
```

**成功响应**（200 OK）：

```json
{
  "success": true,
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "task_info": {
    "user_instruction": "帮我订1月20号从北京到上海的机票",
    "params": {
      "user_id": 1,
      "departure_city": "北京",
      "arrival_city": "上海",
      "departure_date": "2025-01-20"
    },
    "initial_booking_count": 18,
    "created_at": "2025-01-15T10:00:00+08:00",
    "expires_at": "2025-01-15T11:00:00+08:00"
  },
  "status": "waiting_for_execution",
  "message": "任务等待执行中"
}
```

---

### 4. 取消任务

**端点**：`DELETE /api/validation_tasks/:task_id`

**描述**：取消一个未验证的任务

**请求示例**：

```bash
curl -X DELETE http://localhost:3000/api/validation_tasks/550e8400-e29b-41d4-a716-446655440000
```

**成功响应**（200 OK）：

```json
{
  "success": true,
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "message": "任务已取消"
}
```

---

## 💡 使用场景

### 场景 1：训练大模型（Python）

```python
import requests
import time

# 配置
API_BASE = "http://localhost:3000/api"

# 1. 创建验证任务
response = requests.post(f"{API_BASE}/validation_tasks", json={
    "departure_city": "深圳",
    "arrival_city": "武汉",
    "departure_date": "2025-01-15"
})

task_data = response.json()
task_id = task_data["task_id"]
user_instruction = task_data["task_info"]["user_instruction"]

print(f"任务创建成功: {task_id}")
print(f"用户指令: {user_instruction}")

# 2. 大模型执行任务
vision_model.execute(user_instruction, screenshot=capture_screen())

# 等待完成
time.sleep(5)

# 3. 验证结果
response = requests.post(f"{API_BASE}/validation_tasks/{task_id}/verify")
result = response.json()

if result["success"]:
    print("✅ 验证通过！")
    print(f"预订ID: {result['validation_result']['booking_details']['booking_id']}")
else:
    print("❌ 验证失败！")
    print(f"错误: {result['validation_result']['errors']}")
```

---

### 场景 2：批量测试（Bash）

```bash
#!/bin/bash

API_BASE="http://localhost:3000/api"

# 测试任务列表
tasks=(
  '{"departure_city":"深圳","arrival_city":"武汉","departure_date":"2025-01-15"}'
  '{"departure_city":"北京","arrival_city":"上海","departure_date":"2025-01-20"}'
  '{"departure_city":"广州","arrival_city":"深圳","departure_date":"2025-01-25"}'
)

for task_json in "${tasks[@]}"; do
  echo "========================================"
  echo "测试任务: $task_json"
  
  # 创建任务
  response=$(curl -s -X POST "$API_BASE/validation_tasks" \
    -H "Content-Type: application/json" \
    -d "$task_json")
  
  task_id=$(echo $response | jq -r '.task_id')
  user_instruction=$(echo $response | jq -r '.task_info.user_instruction')
  
  echo "任务ID: $task_id"
  echo "用户指令: $user_instruction"
  
  # 执行任务（这里手动或调用大模型）
  echo "等待执行..."
  sleep 10
  
  # 验证结果
  verify_response=$(curl -s -X POST "$API_BASE/validation_tasks/$task_id/verify")
  success=$(echo $verify_response | jq -r '.success')
  
  if [ "$success" = "true" ]; then
    echo "✅ 验证通过"
  else
    echo "❌ 验证失败"
    echo "错误: $(echo $verify_response | jq -r '.validation_result.errors')"
  fi
  
  echo ""
done
```

---

### 场景 3：CI/CD 集成

```yaml
# .github/workflows/model_training.yml
name: Train Vision Model

on:
  push:
    branches: [ main ]

jobs:
  train:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Start Rails Server
        run: |
          rails server -d
          sleep 10
      
      - name: Run Training Tests
        run: |
          python scripts/train_model.py \
            --api-base http://localhost:3000/api \
            --iterations 100
      
      - name: Check Results
        run: python scripts/analyze_results.py
```

---

### 场景 4：Node.js 集成

```javascript
const axios = require('axios');

const API_BASE = 'http://localhost:3000/api';

async function testBooking() {
  try {
    // 1. 创建任务
    const createResponse = await axios.post(`${API_BASE}/validation_tasks`, {
      departure_city: '深圳',
      arrival_city: '武汉',
      departure_date: '2025-01-15'
    });
    
    const { task_id, task_info } = createResponse.data;
    console.log('任务创建成功:', task_id);
    console.log('用户指令:', task_info.user_instruction);
    
    // 2. 执行任务（调用大模型）
    await executeVisionModel(task_info.user_instruction);
    
    // 3. 验证结果
    const verifyResponse = await axios.post(
      `${API_BASE}/validation_tasks/${task_id}/verify`
    );
    
    if (verifyResponse.data.success) {
      console.log('✅ 验证通过！');
      console.log('预订详情:', verifyResponse.data.validation_result.booking_details);
    } else {
      console.log('❌ 验证失败！');
      console.log('错误:', verifyResponse.data.validation_result.errors);
    }
  } catch (error) {
    console.error('Error:', error.message);
  }
}

testBooking();
```

---

## 🔒 安全说明

### 当前实现

- ✅ 跳过 CSRF 验证（API 专用）
- ✅ 任务 ID 使用 UUID（不可预测）
- ✅ 任务自动过期（1小时）
- ❌ **未实现身份验证**（生产环境需要）

### 生产环境建议

1. **添加 API Token 认证**：

```ruby
# app/controllers/api/validation_tasks_controller.rb
before_action :authenticate_api_token

private

def authenticate_api_token
  token = request.headers['Authorization']&.split(' ')&.last
  unless valid_token?(token)
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end
```

2. **添加速率限制**：

```ruby
# Gemfile
gem 'rack-attack'

# config/initializers/rack_attack.rb
Rack::Attack.throttle('api/validation_tasks', limit: 100, period: 1.hour) do |req|
  req.ip if req.path.start_with?('/api/validation_tasks')
end
```

3. **添加日志记录**：

```ruby
after_action :log_api_request

def log_api_request
  Rails.logger.info "API Request: #{action_name} #{params[:id]} - #{response.status}"
end
```

---

## 📊 任务生命周期

```
创建 (POST /create)
   ↓
等待执行 (可查询状态 GET /:id)
   ↓
[执行预订任务]
   ↓
验证 (POST /:id/verify)
   ↓
完成/失败 (任务被删除)
```

**自动清理**：
- 任务缓存 1 小时后自动过期
- 验证后立即删除任务

---

## 🔍 故障排除

### 问题 1：任务不存在或已过期

**错误响应**：
```json
{
  "success": false,
  "error": "任务不存在或已过期",
  "task_id": "xxx"
}
```

**原因**：
- 任务已验证（验证后自动删除）
- 任务创建超过 1 小时
- task_id 错误

**解决方法**：
- 重新创建任务
- 确认 task_id 正确

---

### 问题 2：验证失败"未创建新记录"

**错误响应**：
```json
{
  "validation_result": {
    "valid": false,
    "errors": ["未创建新的预订记录"]
  }
}
```

**原因**：
- 预订任务未执行
- 预订失败
- 在创建任务前就完成了预订

**解决方法**：
- 确认预订流程已完成
- 检查浏览器是否显示"支付成功"
- 查询数据库确认记录：`curl http://localhost:3000/api/bookings/last`

---

### 问题 3：城市/日期不匹配

**错误响应**：
```json
{
  "validation_result": {
    "valid": false,
    "errors": [
      "出发城市不匹配。期望：深圳，实际：广州"
    ]
  }
}
```

**原因**：
- 预订了错误的航班
- 大模型理解错误

**解决方法**：
- 检查任务参数是否正确
- 重新训练大模型

---

## 📚 相关文档

- [命令行工具指南](CLI_VALIDATION_GUIDE.md) - 本地验证工具
- [使用流程说明](USAGE_WORKFLOW.md) - 理解验证时机
- [快速开始示例](QUICK_START_EXAMPLE.md) - 真实场景演示

---

## 🎉 总结

**API 优势**：

1. ✅ **远程调用**：支持分布式训练
2. ✅ **语言无关**：Python、Node.js、Bash 都可以使用
3. ✅ **异步执行**：创建任务后可以稍后验证
4. ✅ **易于集成**：标准 REST API，易于集成到任何系统

**核心流程**：

```
POST /api/validation_tasks → 大模型执行 → POST /api/validation_tasks/:id/verify
```

---

**现在就试试吧！** 🚀

```bash
curl -X POST http://localhost:3000/api/validation_tasks \
  -H "Content-Type: application/json" \
  -d '{
    "departure_city": "深圳",
    "arrival_city": "武汉",
    "departure_date": "2025-01-15"
  }'
```
