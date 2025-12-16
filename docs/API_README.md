# 📡 REST API - 快速参考

## 🎯 为什么使用 API？

| 特性 | 命令行工具 | REST API |
|------|-----------|---------|
| **使用场景** | 本地开发测试 | 远程训练、CI/CD |
| **调用方式** | `rake vision:validate` | HTTP 请求 |
| **语言支持** | Ruby/Bash | 任意语言（Python、Node.js等） |
| **分布式** | ❌ | ✅ |
| **异步执行** | ❌ | ✅ |

---

## ⚡ 3步完成验证

### 步骤 1：创建任务

```bash
curl -X POST http://localhost:3000/api/validation_tasks \
  -H "Content-Type: application/json" \
  -d '{
    "departure_city": "深圳",
    "arrival_city": "武汉",
    "departure_date": "2025-01-15"
  }'
```

**响应**：
```json
{
  "success": true,
  "task_id": "550e8400-e29b-41d4-a716-446655440000",
  "task_info": {
    "user_instruction": "帮我订1月15号从深圳到武汉的机票"
  }
}
```

### 步骤 2：执行任务

大模型或人工完成预订操作

### 步骤 3：验证结果

```bash
curl -X POST http://localhost:3000/api/validation_tasks/550e8400.../verify
```

**响应（成功）**：
```json
{
  "success": true,
  "message": "验证通过！任务成功完成",
  "validation_result": {
    "valid": true,
    "booking_details": { ... }
  }
}
```

---

## 📋 可用端点

| 方法 | 端点 | 说明 |
|------|------|------|
| POST | `/api/validation_tasks` | 创建任务 |
| POST | `/api/validation_tasks/:id/verify` | 验证结果 |
| GET | `/api/validation_tasks/:id` | 查询状态 |
| DELETE | `/api/validation_tasks/:id` | 取消任务 |

---

## 💻 示例代码

### Python

```python
import requests

API_BASE = "http://localhost:3000/api"

# 1. 创建任务
response = requests.post(f"{API_BASE}/validation_tasks", json={
    "departure_city": "深圳",
    "arrival_city": "武汉",
    "departure_date": "2025-01-15"
})

task_id = response.json()["task_id"]

# 2. 执行任务（调用大模型）
# vision_model.execute(...)

# 3. 验证结果
response = requests.post(f"{API_BASE}/validation_tasks/{task_id}/verify")
result = response.json()

if result["success"]:
    print("✅ 验证通过！")
else:
    print(f"❌ 验证失败: {result['validation_result']['errors']}")
```

### Bash

```bash
# 1. 创建任务
response=$(curl -s -X POST http://localhost:3000/api/validation_tasks \
  -H "Content-Type: application/json" \
  -d '{"departure_city":"深圳","arrival_city":"武汉","departure_date":"2025-01-15"}')

task_id=$(echo $response | python3 -c "import sys,json; print(json.load(sys.stdin)['task_id'])")

# 2. 执行任务
# ...

# 3. 验证结果
curl -X POST http://localhost:3000/api/validation_tasks/$task_id/verify
```

### Node.js

```javascript
const axios = require('axios');

const API_BASE = 'http://localhost:3000/api';

// 1. 创建任务
const { data } = await axios.post(`${API_BASE}/validation_tasks`, {
  departure_city: '深圳',
  arrival_city: '武汉',
  departure_date: '2025-01-15'
});

const taskId = data.task_id;

// 2. 执行任务
// await visionModel.execute(...)

// 3. 验证结果
const result = await axios.post(`${API_BASE}/validation_tasks/${taskId}/verify`);

console.log(result.data.success ? '✅ 验证通过' : '❌ 验证失败');
```

---

## 📝 参数说明

### 必填参数（3个）

- `departure_city` - 出发城市
- `arrival_city` - 到达城市
- `departure_date` - 出发日期（YYYY-MM-DD）

### 可选参数

- `user_id` - 用户ID（默认：1）
- `passenger_name` - 乘客姓名
- `contact_phone` - 联系电话
- `insurance_required` - 必须购买保险
- `insurance_forbidden` - 不能购买保险
- `should_complete_payment` - 是否完成支付（默认：true）

---

## 🚀 完整示例脚本

查看 `examples/` 目录：

- **Python**: `python3 examples/python_example.py`
- **Bash**: `bash examples/bash_example.sh`

---

## 📚 完整文档

查看 [API_GUIDE.md](API_GUIDE.md) 获取：
- 详细的 API 文档
- 更多使用场景
- 错误处理
- 安全建议

---

## 🔄 API vs 命令行对比

### 使用命令行（本地）

```bash
rake vision:validate \
  departure_city=深圳 \
  arrival_city=武汉 \
  departure_date=2025-01-15
```

优点：
- ✅ 简单直接
- ✅ 适合本地开发

缺点：
- ❌ 只能本地使用
- ❌ 需要 Rails 环境

### 使用 API（远程）

```bash
curl -X POST http://localhost:3000/api/validation_tasks \
  -H "Content-Type: application/json" \
  -d '{"departure_city":"深圳","arrival_city":"武汉","departure_date":"2025-01-15"}'
```

优点：
- ✅ 可以远程调用
- ✅ 语言无关
- ✅ 易于集成
- ✅ 支持异步

缺点：
- ❌ 需要启动服务器

---

**推荐**：本地开发用命令行，生产/训练用 API！🚀
