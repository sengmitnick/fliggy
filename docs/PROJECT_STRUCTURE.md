# 视觉模型训练验证框架 - 项目结构

## 📁 完整文件列表

```
项目根目录/
│
├── 📄 VISION_VALIDATION.md              # ⭐ 快速参考卡片（推荐从这里开始）
│
├── docs/                                 # 📚 完整文档目录
│   ├── README.md                         # 框架总览、快速开始、核心理念
│   ├── CLI_VALIDATION_GUIDE.md           # ⭐ 命令行工具完整使用指南
│   ├── vision_model_training_tasks.md    # 任务定义、验证规则详解
│   ├── tasks_table_for_vision_training.md # AndroidWorld风格任务表格
│   ├── DEMO_SCRIPT.md                    # 演示脚本（用于录制教程）
│   └── PROJECT_STRUCTURE.md              # 本文件：项目结构说明
│
├── lib/tasks/                            # 🛠️ Rake任务
│   └── vision_validate.rake              # 命令行验证工具实现
│
└── spec/validators/                      # ✅ 验证器
    └── flight_booking_task_validator.rb  # 任务结果验证逻辑
```

---

## 📖 文档阅读顺序

### 新手入门（5分钟快速上手）

1. **[VISION_VALIDATION.md](../VISION_VALIDATION.md)** - 快速参考卡片
   - 一句话说明
   - 常用命令
   - 参数说明

2. **运行第一个验证**
   ```bash
   rake vision:help
   rake vision:validate departure_city=深圳 arrival_city=武汉 departure_date=2025-01-15
   ```

### 深入学习（30分钟完整理解）

3. **[CLI_VALIDATION_GUIDE.md](CLI_VALIDATION_GUIDE.md)** - 命令行工具完整指南
   - 详细参数说明
   - 完整示例演示
   - 故障排除

4. **[README.md](README.md)** - 框架总览
   - 核心理念
   - 架构设计
   - 与AndroidWorld对比

5. **[vision_model_training_tasks.md](vision_model_training_tasks.md)** - 任务定义
   - 任务变体
   - 验证规则详解
   - 代码调用示例

6. **[tasks_table_for_vision_training.md](tasks_table_for_vision_training.md)** - 任务表格
   - 参考AndroidWorld论文格式
   - 所有任务的汇总表格

### 进阶使用（开发和扩展）

7. **[flight_booking_task_validator.rb](../spec/validators/flight_booking_task_validator.rb)** - 验证器源码
   - 实现细节
   - 可以基于此扩展新的验证逻辑

8. **[vision_validate.rake](../lib/tasks/vision_validate.rake)** - 命令行工具源码
   - Rake任务实现
   - 参数解析逻辑
   - 输出格式化

### 演示和教学

9. **[DEMO_SCRIPT.md](DEMO_SCRIPT.md)** - 演示脚本
   - 4个完整演示场景
   - 录制视频指南
   - 后期处理建议

---

## 🎯 快速导航

### 按用途查找

| 我想... | 查看文件 |
|--------|---------|
| 快速上手，运行第一个验证 | [VISION_VALIDATION.md](../VISION_VALIDATION.md) |
| 了解所有命令和参数 | [CLI_VALIDATION_GUIDE.md](CLI_VALIDATION_GUIDE.md) |
| 理解验证框架的设计理念 | [README.md](README.md) |
| 查看所有支持的任务类型 | [tasks_table_for_vision_training.md](tasks_table_for_vision_training.md) |
| 理解验证规则的细节 | [vision_model_training_tasks.md](vision_model_training_tasks.md) |
| 修改验证逻辑 | [flight_booking_task_validator.rb](../spec/validators/flight_booking_task_validator.rb) |
| 录制演示视频 | [DEMO_SCRIPT.md](DEMO_SCRIPT.md) |

### 按角色查找

| 角色 | 推荐阅读 |
|-----|---------|
| **测试人员** | VISION_VALIDATION.md → CLI_VALIDATION_GUIDE.md |
| **AI研究员** | README.md → vision_model_training_tasks.md → tasks_table_for_vision_training.md |
| **开发人员** | CLI_VALIDATION_GUIDE.md → flight_booking_task_validator.rb → vision_validate.rake |
| **产品经理** | README.md → DEMO_SCRIPT.md |
| **讲师/培训师** | DEMO_SCRIPT.md → CLI_VALIDATION_GUIDE.md |

---

## 🔧 核心组件说明

### 1. 命令行工具（lib/tasks/vision_validate.rake）

**功能**：
- 解析命令行参数
- 生成用户指令
- 调用验证器
- 格式化输出结果

**使用方法**：
```bash
rake vision:validate [参数列表]
rake vision:help  # 查看帮助
```

**关键特性**：
- ✅ 自动生成中文用户指令
- ✅ 彩色输出（成功/失败）
- ✅ 详细的预订详情展示
- ✅ 清晰的错误信息

---

### 2. 验证器（spec/validators/flight_booking_task_validator.rb）

**功能**：
- 记录初始数据库状态
- 检测新创建的预订记录
- 验证所有任务参数
- 返回验证结果和错误列表

**核心方法**：
```ruby
# 创建验证器
validator = FlightBookingTaskValidator.new(task_params)

# 记录初始状态
validator.record_initial_state

# 获取验证结果
result = validator.result
# => { valid: true/false, errors: [...] }
```

**验证规则**：
1. 新预订创建
2. 航班路线匹配
3. 出发日期匹配
4. 乘客信息匹配（可选）
5. 保险选择匹配（可选）
6. 支付状态匹配

---

### 3. 文档系统

#### 快速参考（VISION_VALIDATION.md）
- 🎯 目标：让用户在2分钟内运行第一个验证
- 📝 内容：常用命令、参数说明、示例输出

#### 完整指南（CLI_VALIDATION_GUIDE.md）
- 🎯 目标：详尽的使用说明和故障排除
- 📝 内容：所有参数、完整示例、工作流程、故障排除

#### 理论文档（README.md + vision_model_training_tasks.md）
- 🎯 目标：理解框架设计理念和验证规则
- 📝 内容：核心理念、验证规则、与AndroidWorld对比

#### 任务表格（tasks_table_for_vision_training.md）
- 🎯 目标：快速查看所有支持的任务
- 📝 内容：AndroidWorld风格的任务定义表格

---

## 📊 文档统计

| 文件 | 行数 | 用途 | 目标读者 |
|-----|------|------|---------|
| VISION_VALIDATION.md | ~150 | 快速参考 | 所有人 |
| CLI_VALIDATION_GUIDE.md | ~400 | 完整指南 | 测试人员、开发人员 |
| README.md | ~200 | 框架总览 | AI研究员、架构师 |
| vision_model_training_tasks.md | ~400 | 任务定义 | AI研究员 |
| tasks_table_for_vision_training.md | ~300 | 任务汇总 | 所有人 |
| DEMO_SCRIPT.md | ~400 | 演示脚本 | 讲师、视频制作者 |
| PROJECT_STRUCTURE.md | ~250 | 项目结构 | 开发人员 |

---

## 🔗 外部链接

- **AndroidWorld GitHub**: https://github.com/google-research/android_world
- **AndroidWorld 论文**: https://arxiv.org/abs/2405.14573
- **Rails 指南**: https://guides.rubyonrails.org/

---

## 🤝 贡献指南

### 添加新的验证规则

1. 编辑 `spec/validators/flight_booking_task_validator.rb`
2. 在 `validate` 方法中添加新的验证逻辑
3. 更新文档中的"验证规则"部分

### 添加新的任务参数

1. 编辑 `lib/tasks/vision_validate.rake` 的 `parse_validation_params` 方法
2. 在验证器中添加相应的验证逻辑
3. 更新文档中的"参数说明"部分
4. 在 `tasks_table_for_vision_training.md` 中添加新的任务示例

### 改进文档

1. 根据实际使用反馈更新示例
2. 添加常见问题到"故障排除"部分
3. 补充更多使用场景

---

## 📮 反馈和支持

如有问题或建议：

1. 查看文档的"故障排除"部分
2. 运行 `rake vision:help` 查看最新帮助
3. 查看验证器源码理解验证逻辑
4. 提交Issue或联系维护者

---

**祝使用愉快！🎉**
