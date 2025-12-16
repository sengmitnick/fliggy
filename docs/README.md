# 航班预订 - 大模型视觉训练任务

用于训练大模型视觉理解和Web操作能力的航班预订任务验证框架。

## 📚 文档

### 验证工具
- [**快速开始示例**](QUICK_START_EXAMPLE.md) - 🎉 新手必看！真实场景演示
- [**命令行验证工具**](CLI_VALIDATION_GUIDE.md) - ⭐ 推荐！直接在终端执行验证的完整指南
- [**REST API 指南**](API_GUIDE.md) - 📡 远程调用 API，适合大模型训练
- [**API 快速参考**](API_README.md) - API 常用命令速查

### 后台管理
- [**后台管理指南**](ADMIN_GUIDE.md) - 🛡️ 完整的后台管理系统说明

### 任务定义
- [**视觉训练任务指南**](vision_model_training_tasks.md) - 详细的任务定义、使用示例和验证规则
- [**任务表格汇总**](tasks_table_for_vision_training.md) - 参考AndroidWorld论文格式的任务定义表格

## 🎯 核心理念

本框架专为**大模型视觉能力训练**设计：

### 训练目标
让大模型像人类一样，通过观察屏幕、理解UI、点击按钮来完成任务。

### 验证方式
只检查**最终结果**（数据库记录），不关心中间步骤。

### 任务示例
```
用户指令：帮我订1月15号从深圳到武汉的机票

大模型需要：
1. 理解用户意图
2. 在网页上找到搜索框
3. 输入城市信息
4. 点击搜索按钮
5. 选择合适的航班
6. 填写表单
7. 处理弹窗
8. 完成支付

验证标准：
数据库中新增一条从深圳到武汉的已支付预订记录
```

## 🏗️ 架构

```
spec/validators/
└── flight_booking_task_validator.rb   # 任务结果验证器

docs/
├── README.md                           # 本文件
├── vision_model_training_tasks.md      # 详细任务指南
└── tasks_table_for_vision_training.md  # 任务汇总表格
```

## 🚀 快速开始

### 方式一：命令行验证（推荐）

最简单的方式是使用命令行工具：

```bash
# 查看帮助
rake vision:help

# 基础验证
rake vision:validate \
  departure_city=深圳 \
  arrival_city=武汉 \
  departure_date=2025-01-15
```

详细使用方法请查看 [命令行验证工具指南](CLI_VALIDATION_GUIDE.md)

### 方式二：代码调用

```ruby
# 1. 创建验证器并定义任务
validator = FlightBookingTaskValidator.new(
  user_id: 1,
  departure_city: "深圳",
  arrival_city: "武汉",
  departure_date: "2025-01-15",  # 必填
  should_complete_payment: true
)

# 2. 记录任务开始前的状态
validator.record_initial_state

# 3. 大模型执行任务（通过视觉识别和操作）
# model.execute_task("帮我订1月15号从深圳到武汉的机票")

# 4. 验证任务结果
result = validator.result

if result[:valid]
  puts "✅ 任务成功：大模型成功预订了机票"
else
  puts "❌ 任务失败："
  result[:errors].each { |error| puts "  - #{error}" }
end
```

### 完整示例（指定日期和乘客）

```ruby
validator = FlightBookingTaskValidator.new(
  user_id: 1,
  departure_city: "北京",
  arrival_city: "上海",
  departure_date: "2025-01-20",
  passenger_name: "张三",
  contact_phone: "13800138000",
  insurance_required: true,
  should_complete_payment: true
)

validator.record_initial_state

# 大模型执行...
# 用户指令："帮我订1月20号从北京到上海的机票，乘客张三，手机13800138000，要买保险"

result = validator.result
# 验证：是否创建了符合所有要求的预订记录
```

## 📋 支持的任务类型

| 任务类型 | 描述 | 复杂度 |
|---------|------|-------|
| **基础预订** | 指定出发城市、到达城市和日期 | ⭐ 简单 |
| **指定乘客** | 包含乘客姓名和手机号 | ⭐⭐ 中等 |
| **购买保险** | 需要选择保险产品 | ⭐⭐⭐ 复杂 |
| **拒绝保险** | 需要拒绝保险推荐 | ⭐⭐⭐ 复杂 |
| **仅填表单** | 不完成支付 | ⭐ 简单 |

## 🔍 验证规则

验证器检查以下内容：

1. ✅ **新预订创建**：是否生成新的预订记录
2. ✅ **航班路线**：出发城市、到达城市是否匹配
3. ✅ **出发日期**：日期是否匹配（必填）
4. ✅ **乘客信息**：姓名、手机号是否匹配（如果指定）
5. ✅ **保险选择**：是否按要求购买/不购买保险
6. ✅ **支付状态**：是否完成支付

**关键特性**：
- 只检查数据库最终状态
- 忽略其他用户的预订（噪音数据）
- 忽略任务开始前的历史预订
- 不关心大模型如何完成任务（中间步骤）

## 🧪 与 AndroidWorld 的对比

| 特性 | AndroidWorld | 本项目 |
|------|-------------|--------|
| **目标** | 训练模型操作Android应用 | 训练模型操作Web应用 |
| **任务示例** | "在VLC创建播放列表" | "预订深圳到武汉的机票" |
| **验证方式** | `execute_sql(query) == files` | `booking.departure_city == "深圳"` |
| **交互方式** | 触摸、滑动 | 鼠标点击、键盘输入 |
| **任务粒度** | 单个应用操作 | 完整业务流程 |

## 📊 评估指标

| 指标 | 说明 |
|------|------|
| **任务成功率** | 成功完成的任务占比 |
| **平均完成时间** | 完成一个任务的平均耗时 |
| **首次成功率** | 第一次尝试就成功的占比 |
| **错误类型分布** | 各类错误的统计分析 |

### 常见错误类型

- 路线错误：选择了错误的城市
- 日期错误：选择了错误的日期
- 信息缺失：未填写必需信息
- 保险错误：保险选择与要求不符
- 支付未完成：未完成支付流程
- 无新记录：未创建预订记录

## 🔗 相关资源

- [AndroidWorld GitHub](https://github.com/google-research/android_world)
- [AndroidWorld 论文](https://arxiv.org/abs/2405.14573)

## 📝 示例：Python伪代码

```python
# 创建验证器
validator = FlightBookingTaskValidator({
    'user_id': 1,
    'departure_city': '深圳',
    'arrival_city': '武汉',
    'should_complete_payment': True
})

# 记录初始状态
validator.record_initial_state()

# 大模型执行任务
vision_model.execute_task(
    instruction="帮我订1月15号从深圳到武汉的机票",
    screenshot=capture_screen(),
    browser=browser_instance
)

# 验证结果
success, errors = validator.validate()
print("成功" if success else f"失败: {errors}")
```

---

**核心思想**：给大模型一个任务目标，让它自己理解UI、规划步骤、完成操作，最后只检查数据库里是否有正确的预订记录。
