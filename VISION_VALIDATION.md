# 🚀 视觉模型训练 - 快速验证指南

## 📖 一句话说明

用命令行工具验证大模型（或人工）是否成功完成机票预订任务。

> 🎉 **新手必看**：查看 [docs/QUICK_START_EXAMPLE.md](docs/QUICK_START_EXAMPLE.md) 了解真实使用场景！
> ⚠️ **重要**：查看 [docs/USAGE_WORKFLOW.md](docs/USAGE_WORKFLOW.md) 了解正确的使用流程！
> 📡 **API 调用**：查看 [docs/API_GUIDE.md](docs/API_GUIDE.md) 了解如何远程调用 API！

---

## ⚡ 快速开始

### 1. 查看帮助

```bash
rake vision:help
```

### 2. 运行验证

```bash
rake vision:validate \
  departure_city=深圳 \
  arrival_city=武汉 \
  departure_date=2025-01-15
```

### 3. 执行任务

看到提示后，手动完成预订流程或运行大模型。

### 4. 完成验证

按 Enter 键查看结果。

---

## 📝 常用命令

### 基础预订
```bash
rake vision:validate departure_city=深圳 arrival_city=武汉 departure_date=2025-01-15
```

### 指定乘客
```bash
rake vision:validate departure_city=北京 arrival_city=上海 departure_date=2025-01-20 \
  passenger_name=张三 contact_phone=13800138000
```

### 要求保险
```bash
rake vision:validate departure_city=广州 arrival_city=深圳 departure_date=2025-01-25 \
  insurance_required=true
```

### 拒绝保险
```bash
rake vision:validate departure_city=成都 arrival_city=重庆 departure_date=2025-01-28 \
  insurance_forbidden=true
```

### 只填表单不支付
```bash
rake vision:validate departure_city=杭州 arrival_city=成都 departure_date=2025-01-30 \
  should_complete_payment=false
```

---

## 📋 参数说明

### 必填参数（3个）
- `departure_city` - 出发城市
- `arrival_city` - 到达城市
- `departure_date` - 出发日期（格式：YYYY-MM-DD）

### 可选参数
- `user_id` - 用户ID（默认：1）
- `passenger_name` - 乘客姓名
- `contact_phone` - 联系电话
- `insurance_required` - 是否要求购买保险（true/false）
- `insurance_forbidden` - 是否禁止购买保险（true/false）
- `should_complete_payment` - 是否应完成支付（默认：true）

---

## ✅ 验证规则

工具会自动检查：

1. ✅ 是否创建了新预订记录
2. ✅ 出发城市、到达城市是否正确
3. ✅ 出发日期是否匹配
4. ✅ 乘客信息是否正确（如果指定）
5. ✅ 保险选择是否符合要求（如果指定）
6. ✅ 支付状态是否正确

---

## 📚 完整文档

- **[命令行工具详细指南](docs/CLI_VALIDATION_GUIDE.md)** - 完整使用说明、故障排除
- **[任务定义文档](docs/vision_model_training_tasks.md)** - 任务变体、验证规则
- **[任务表格](docs/tasks_table_for_vision_training.md)** - AndroidWorld风格的任务定义
- **[框架总览](docs/README.md)** - 架构、原理、评估指标

---

## 🎯 工作流程

```
1. 运行命令 → 2. 工具记录初始状态 → 3. 执行任务 → 4. 按Enter验证 → 5. 查看结果
```

---

## 💡 示例输出

### ✅ 成功

```
✅ 验证通过！任务成功完成

📦 预订详情：
   预订ID: 123
   航班号: CZ3456
   路线: 深圳 → 武汉
   日期: 2025年01月15日
   乘客: 张三
   保险: 优享保障 ¥50
   状态: 已支付
```

### ❌ 失败

```
❌ 验证失败！任务未完成

🔍 错误详情：
   1. 未找到新的预订记录
   2. 出发城市不匹配。期望：深圳，实际：广州
```

---

## 🔗 相关资源

- [AndroidWorld GitHub](https://github.com/google-research/android_world) - 参考项目
- [验证器源码](spec/validators/flight_booking_task_validator.rb) - 实现细节

---

**快速上手**：直接运行 `rake vision:help` 查看帮助！
