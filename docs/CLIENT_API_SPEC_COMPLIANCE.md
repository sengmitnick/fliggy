# 甲方规范 API 兼容层实现文档

## 📋 概述

本文档记录了为符合甲方「手机应用环境交付规范」而实现的 API 兼容层。

---

## ✅ 已实现功能

### 1. 新增路由

#### `/api/tasks/:id/start` - 创建训练会话
- **方法**: POST
- **功能**: 创建新的验证会话（等同于 `/api/verify/:id/prepare`）
- **参数**: 
  - `:id` - 任务 ID（task_id，即 validator_id）
- **返回格式**:
```json
{
  "task": {
    "task": "请预订一张深圳到北京的低价机票",
    "departure_city": "深圳市",
    "destination_city": "北京市",
    "date": "2026-01-22",
    "hint": "系统中有多个航班可选，请选择价格最低的航班",
    "available_flights_count": 4,
    "lowest_price": "550.0"
  },
  "session_id": "242dd189-9dc8-4f83-8da1-ad1c1c09fada",
  "task_id": "book_flight_sz_to_bj"
}
```

#### `/api/verify/run` - 验证接口
- **方法**: POST
- **功能**: 验证任务完成情况（等同于 `/api/verify/:execution_id/result`）
- **参数**:
```json
{
  "task_id": "book_flight_sz_to_bj",
  "session_id": "242dd189-9dc8-4f83-8da1-ad1c1c09fada"
}
```
- **返回格式**:
```json
{
  "score": 0.8,                        // 归一化得分 0-1 (从 0-100 转换)
  "reason": "选择了最低价航班: 未选择最低价航班。最低价: 550, 实际: 680",
  "execution_status": "success",       // success=验证正常执行, fail=系统错误
  "metadata": {
    "details": {
      "process": [],                   // 预留字段
      "result": [
        {
          "child_verify_id": "step_1_订单已创建",
          "score": 1.0,                // 子步骤得分 0 或 1
          "weight": 0.2,               // 权重归一化 0-1
          "child_reason": {
            "passed": true,
            "error": null
          }
        },
        {
          "child_verify_id": "step_5_选择了最低价航班",
          "score": 0.0,
          "weight": 0.4,
          "child_reason": {
            "passed": false,
            "error": "未选择最低价航班。最低价: 550, 实际: 680"
          }
        }
      ]
    }
  }
}
```

---

## 🔄 格式转换逻辑

### `transform_to_client_format` 方法

将内部 `verify_result` 转换为甲方规范格式：

| 内部字段 | 甲方规范字段 | 转换规则 |
|---------|------------|---------|
| `score` (0-100) | `score` (0-1) | 除以 100 |
| `errors` (数组) | `reason` (字符串) | 用 `; ` 连接 |
| `status` (passed/failed/error) | `execution_status` (success/fail) | error → fail, 其他 → success |
| `assertions` | `metadata.details.result` | 逐项转换 |
| `assertions[].name` | `child_verify_id` | `step_N_原名称` |
| `assertions[].weight` (0-100) | `weight` (0-1) | 除以 100 |
| `assertions[].passed` | `score` | true → 1.0, false → 0.0 |

---

## 🧪 测试结果

### 测试 1: 创建训练会话
```bash
curl -X POST 'http://localhost:3000/api/tasks/book_flight_sz_to_bj/start'
```
**结果**: ✅ 成功返回 `session_id` 和 `task` 信息

### 测试 2: 验证接口（无订单）
```bash
curl -X POST 'http://localhost:3000/api/verify/run' \
  -H 'Content-Type: application/json' \
  -d '{"task_id":"book_flight_sz_to_bj","session_id":"<session_id>"}'
```
**结果**: ✅ 返回 `score: 0.0`，错误原因明确

### 测试 3: 缺少 session_id
```bash
curl -X POST 'http://localhost:3000/api/verify/run' \
  -d '{"task_id":"test"}'
```
**结果**: ✅ 返回 `execution_status: "fail"`, `reason: "缺少 session_id 参数"`

### 测试 4: 不存在的 session_id
```bash
curl -X POST 'http://localhost:3000/api/verify/run' \
  -d '{"task_id":"test","session_id":"invalid"}'
```
**结果**: ✅ 返回 404, `reason: "验证会话不存在或已过期"`

---

## 🏗️ 架构说明

### session_id 与 data_version 隔离

- **session_id** = **execution_id**: 一对一映射
- **并发隔离**: 通过 PostgreSQL RLS + `data_version` 机制自动实现
- **无需额外改动**: 现有架构天然支持多 Agent 并发执行

```
┌──────────────────────────────────┐
│ 数据库表（所有版本共存）          │
├──────────────────────────────────┤
│ data_version = 0                 │ ← 基线数据（所有 session 共享）
│   City, Destination, Flight      │
├──────────────────────────────────┤
│ data_version = session_id_A      │ ← Agent A 的临时数据
│   Booking, HotelBooking          │
├──────────────────────────────────┤
│ data_version = session_id_B      │ ← Agent B 的临时数据
│   Booking, HotelBooking          │
└──────────────────────────────────┘

RLS 策略自动过滤：
  USING (data_version = 0 OR data_version::text = current_setting('app.data_version'))
```

---

## 📝 使用示例

### 完整流程

```bash
# 1. 创建会话
response=$(curl -s -X POST 'http://localhost:3000/api/tasks/book_flight_sz_to_bj/start')
session_id=$(echo "$response" | jq -r '.session_id')
task=$(echo "$response" | jq -r '.task.task')

echo "任务: $task"
echo "会话ID: $session_id"

# 2. AI Agent 完成任务（预订机票）
# ... 用户在浏览器中操作或 Agent 自动完成 ...

# 3. 验证结果
curl -s -X POST 'http://localhost:3000/api/verify/run' \
  -H 'Content-Type: application/json' \
  -d "{\"task_id\":\"book_flight_sz_to_bj\",\"session_id\":\"$session_id\"}" \
  | jq .

# 输出示例:
# {
#   "score": 1.0,
#   "reason": "验证通过",
#   "execution_status": "success",
#   ...
# }
```

---

## 🔍 兼容性说明

### 现有接口不受影响

- **原接口**: `/api/verify/:id/prepare` 和 `/api/verify/:execution_id/result` 保持不变
- **新接口**: `/api/tasks/:id/start` 和 `/api/verify/run` 作为兼容层
- **内部实现**: 两套接口共享相同的业务逻辑

### 支持的 task_id（validator_id）

运行以下命令查看所有可用任务：
```bash
curl -X GET 'http://localhost:3000/api/verify' | jq '.validators[].validator_id'
```

示例输出：
```
"book_flight_sz_to_bj"
"search_cheapest_flight"
```

---

## 🚀 部署说明

### 环境要求

- Ruby 3.3+
- Rails 7.2+
- PostgreSQL 14+ (支持 RLS)

### 端口配置

服务运行在 **3000 端口**（可通过环境变量 `PORT` 调整）

### 健康检查

```bash
curl http://localhost:3000/api/verify
```

返回所有可用验证器列表即表示服务正常。

---

## 📚 相关文档

- [验证器系统设计文档](./VALIDATOR_DESIGN.md)
- [API 使用指南](./API_GUIDE.md)
- [甲方交付规范](../手机应用环境交付规范.md)

---

## 🎯 总结

✅ **已完成**:
1. 新增 `/api/tasks/:id/start` 和 `/api/verify/run` 兼容接口
2. 实现格式转换逻辑（`transform_to_client_format`）
3. 支持 `session_id` 参数（等同于 `execution_id`）
4. 返回格式完全符合甲方规范
5. 错误处理（区分系统错误和业务失败）
6. 所有测试通过

✅ **架构优势**:
- 无需数据库 schema 变更
- RLS + data_version 天然支持并发隔离
- 现有接口不受影响
- 代码复用率高

✅ **可扩展性**:
- 支持多 Agent 并发测试（通过不同 session_id）
- 支持自定义验证器（继承 BaseValidator）
- 支持自定义数据包（v1/v2/...）
