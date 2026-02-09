# 后台验证任务详情页面 - 断言显示功能

## 功能概述

后台验证任务详情页面 (`/admin/validation_tasks/:id`) 现在可以显示 `verify` 方法中定义的所有断言条件和权重得分。

## 显示内容

验证结果面板会展示以下信息:

### 1. 总体验证结果
- **通过/失败状态**: 绿色(通过) 或 红色(失败)
- **总得分**: 百分比形式 (0-100%)
- **会话 ID**: 用于追溯验证记录

### 2. 断言检查详情 (新增)
每个断言显示:
- **断言序号和名称**: 例如 "1. 订单已创建"
- **通过状态**: ✓ (绿色) 或 ✗ (红色)
- **权重**: 该断言的分数权重 (例如 "权重: 15%")
- **得分**: 通过则显示 "+15分", 失败显示 "0分"
- **错误信息**: 如果断言失败,显示详细的错误原因

### 3. 概要信息
- 如果有额外的验证说明,会显示在底部的"概要信息"区域

## 示例效果

以 `v014_search_fastest_bus_validator` 为例,验证结果会显示:

```
✓ 验证通过                    总得分: 100%

断言检查详情:

✓ 1. 订单已创建                     权重: 15%   +15分
✓ 2. 路线正确(杭州→深圳)            权重: 10%   +10分
✓ 3. 出发日期正确                   权重: 10%   +10分
✓ 4. 选择了行程时间最短的班次       权重: 30%   +30分
✓ 5. 订单金额准确                   权重: 20%   +20分
✓ 6. 乘车人数正确(1人)              权重: 15%   +15分
```

如果某个断言失败,会显示:

```
✗ 4. 选择了行程时间最短的班次       权重: 30%   0分
  未选择行程时间最短的班次。最短: 480分钟, 实际选择: 540分钟
```

## 技术实现

### 后端 API
验证接口 (`POST /api/verify/run`) 返回的数据结构:

```json
{
  "score": 1.0,
  "reason": "验证通过",
  "execution_status": "success",
  "assertions": [
    {
      "name": "订单已创建",
      "weight": 15,
      "passed": true,
      "error": null
    },
    {
      "name": "选择了行程时间最短的班次",
      "weight": 30,
      "passed": false,
      "error": "未选择行程时间最短的班次。最短: 480分钟, 实际选择: 540分钟"
    }
  ]
}
```

### 前端渲染
- 使用 JavaScript 动态生成断言列表 HTML
- 根据 `assertion.passed` 状态显示不同颜色
- 自动计算每个断言的得分贡献
- 支持深色模式

## 验证器开发指南

在 validator 的 `verify` 方法中使用 `add_assertion`:

```ruby
def verify
  # 断言1: 必须有订单创建
  add_assertion "订单已创建", weight: 15 do
    @order = BusTicketOrder.order(created_at: :desc).first
    expect(@order).not_to be_nil, "未找到任何大巴票订单记录"
  end

  return unless @order

  # 断言2: 路线正确
  add_assertion "路线正确（杭州→深圳）", weight: 10 do
    expect(@order.bus_ticket.origin).to eq(@origin)
    expect(@order.bus_ticket.destination).to eq(@destination)
  end

  # 断言3: 正确识别最短行程时间（核心评分）
  add_assertion "选择了行程时间最短的班次", weight: 30 do
    shortest_duration = all_buses.map(&:duration_minutes).compact.min
    booked_duration = @order.bus_ticket.duration_minutes
    
    expect(booked_duration).to eq(shortest_duration),
      "未选择行程时间最短的班次。最短: #{shortest_duration}分钟, 实际选择: #{booked_duration}分钟"
  end
end
```

### 最佳实践

1. **权重总和必须为 100**
   - 确保所有断言的 `weight` 参数加起来等于 100

2. **断言名称清晰明确**
   - 使用简洁、易懂的名称描述验证内容
   - 可以包含预期值,例如 "乘车人数正确（1人）"

3. **提供详细的错误信息**
   - 使用 `expect(..., "错误消息")` 的第二个参数提供详细说明
   - 对比预期值和实际值,帮助调试

4. **断言顺序合理**
   - 先验证基础条件(如订单是否存在)
   - 再验证具体字段
   - 最后验证复杂业务逻辑

5. **使用 return 提前结束**
   - 如果基础断言失败,使用 `return` 避免后续断言报错

## 相关文件

- **视图**: `app/views/admin/validation_tasks/show.html.erb`
- **控制器**: `app/controllers/admin/validation_tasks_controller.rb`
- **API 控制器**: `app/controllers/api/verify_controller.rb`
- **基础验证器**: `app/validators/base_validator.rb`

## 测试方法

1. 访问后台验证任务列表: `/admin/validation_tasks`
2. 点击任意验证器查看详情
3. 点击"启动新会话"创建验证会话
4. 在无痕模式下打开访问链接进行测试
5. 返回后台点击"验证"按钮
6. 查看断言检查详情区域,确认每个断言的通过/失败状态

## 更新日期

2025-01-18
