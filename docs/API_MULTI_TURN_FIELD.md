# API 多轮对话标识字段说明

## 问题

甲方在调用 `GET /api/tasks` 时，无法区分哪些验证器是多轮对话用例，哪些是传统验证器。

## 解决方案

在 `GET /api/tasks` API 响应中增加 `is_multi_turn` 字段。

### API 响应示例

```bash
curl http://localhost:3000/api/tasks
```

```json
{
  "validators": [
    {
      "id": "v501_hotel_booking_multi_turn_validator",
      "task_id": "0b2d6f73-3d61-4dab-84da-4de740b906a3",
      "title": "酒店预订多轮对话",
      "description": "验证 Agent 是否能通过多轮对话获取完整信息并成功预订酒店",
      "is_multi_turn": true
    },
    {
      "id": "v001_flight_booking_validator",
      "task_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "title": "单程机票预订",
      "description": "验证 Agent 是否能正确预订单程机票",
      "is_multi_turn": false
    }
  ],
  "count": 2
}
```

## 字段说明

### `is_multi_turn`

**类型：** Boolean

**含义：**
- `true` → 多轮对话验证器
  - 需要使用 `POST /api/dialog/message` 接口与 Simul User 交互
  - Agent 每次发送消息后，调用此接口获取 Simul User 回复
  - 对话结束后调用 `POST /api/verify/run` 验证

- `false` → 传统验证器
  - 直接调用业务 API 完成任务
  - 完成后调用 `POST /api/verify/run` 验证

## 技术实现

### 1. BaseValidator 默认 `is_multi_turn: false`

```ruby
# app/validators/base_validator.rb
class BaseValidator
  class << self
    def metadata
      {
        id: task_id || validator_id,
        validator_id: validator_id,
        task_id: task_id,
        title: title,
        description: description,
        timeout: timeout_seconds,
        is_multi_turn: false  # 默认不支持多轮对话
      }
    end
  end
end
```

### 2. MultiTurnBaseValidator 覆盖 `is_multi_turn: true`

```ruby
# app/validators/multi_turn_base_validator.rb
class MultiTurnBaseValidator < BaseValidator
  class << self
    # Override metadata to mark multi-turn validators
    def metadata
      super.merge(is_multi_turn: true)
    end
  end
end
```

## 使用示例

### 甲方客户端伪代码

```python
import requests

# 1. 获取任务列表
response = requests.get("http://localhost:3000/api/tasks")
tasks = response.json()["validators"]

for task in tasks:
    task_id = task["id"]
    is_multi_turn = task["is_multi_turn"]
    
    # 2. 启动会话
    session_response = requests.post(
        f"http://localhost:3000/api/tasks/{task_id}/start",
        json={"agent_name": "MyAgent", "agent_version": "1.0"}
    )
    session_id = session_response.json()["session_id"]
    
    if is_multi_turn:
        # 3a. 多轮对话模式
        while True:
            # Agent 处理任务，生成消息
            agent_message = agent.generate_message()
            
            # 调用 dialog/message 获取 Simul User 回复
            dialog_response = requests.post(
                "http://localhost:3000/api/dialog/message",
                json={"session_id": session_id, "agent_message": agent_message}
            )
            
            simul_user_message = dialog_response.json()["simul_user_message"]
            should_continue = dialog_response.json()["should_continue"]
            
            # Agent 处理 Simul User 回复
            agent.process_user_message(simul_user_message)
            
            if not should_continue:
                break  # 对话结束
    else:
        # 3b. 传统模式
        # 直接调用业务 API 完成任务
        agent.complete_task()
    
    # 4. 提交验证
    verify_response = requests.post(
        "http://localhost:3000/api/verify/run",
        json={"session_id": session_id}
    )
    
    print(f"Task {task_id}: Score = {verify_response.json()['score']}")
```

## 相关文档

- [多轮对话验证器完整文档](./MULTI_TURN_VALIDATOR.md)
- [多轮对话快速上手](./MULTI_TURN_VALIDATOR_QUICKSTART.md)
- [多轮对话流程示例](./MULTI_TURN_DIALOG_FLOW_EXAMPLE.md)

## 变更历史

- **2025-02-02**: 添加 `is_multi_turn` 字段到 validator metadata
  - 修改 `BaseValidator.metadata` 添加默认值 `is_multi_turn: false`
  - 修改 `MultiTurnBaseValidator.metadata` 覆盖为 `is_multi_turn: true`
  - 更新所有相关文档
