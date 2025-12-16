# 📚 文档索引

> 快速找到你需要的文档

---

## 🎯 我想...

### 💨 快速上手

| 需求 | 推荐文档 | 阅读时间 |
|------|----------|----------|
| 我是第一次使用，想快速了解 | [快速开始示例](QUICK_START_EXAMPLE.md) 🎉 | 10分钟 |
| 我想查看常用命令 | [快速参考卡片](../VISION_VALIDATION.md) | 3分钟 |
| 我想了解所有参数 | [命令行工具指南](CLI_VALIDATION_GUIDE.md) | 20分钟 |

### 📖 深入学习

| 需求 | 推荐文档 | 阅读时间 |
|------|----------|----------|
| 我想理解框架的设计理念 | [框架总览](README.md) | 15分钟 |
| 我想理解验证规则 | [任务定义文档](vision_model_training_tasks.md) | 25分钟 |
| 我想查看所有任务类型 | [任务表格汇总](tasks_table_for_vision_training.md) | 10分钟 |
| 我想了解项目结构 | [项目结构说明](PROJECT_STRUCTURE.md) | 15分钟 |

### 🛠️ 开发和扩展

| 需求 | 推荐文档 | 阅读时间 |
|------|----------|----------|
| 我想修改验证逻辑 | [验证器源码](../spec/validators/flight_booking_task_validator.rb) | 20分钟 |
| 我想扩展命令行工具 | [Rake 任务源码](../lib/tasks/vision_validate.rake) | 15分钟 |
| 我想录制演示视频 | [演示脚本](DEMO_SCRIPT.md) | 20分钟 |

---

## 📁 按文件浏览

### 核心文档（必读）

#### 1. [快速开始示例](QUICK_START_EXAMPLE.md) 🎉
**适合人群**：所有新手

**内容**：
- ✅ 真实场景演示（郑州 → 广州）
- ✅ 完整工作流程
- ✅ 故障排除
- ✅ 常见问题

**何时阅读**：第一次使用工具时

---

#### 2. [快速参考卡片](../VISION_VALIDATION.md) ⭐
**适合人群**：所有用户

**内容**：
- ✅ 常用命令速查
- ✅ 参数说明
- ✅ 验证规则
- ✅ 示例输出

**何时阅读**：需要快速查看命令时

---

#### 3. [命令行工具完整指南](CLI_VALIDATION_GUIDE.md)
**适合人群**：测试人员、开发人员

**内容**：
- ✅ 所有参数详解（必填/可选）
- ✅ 6个完整示例
- ✅ 完整工作流程
- ✅ 故障排除

**何时阅读**：需要深入了解工具功能时

---

### 理论文档（深入理解）

#### 4. [框架总览](README.md)
**适合人群**：AI研究员、架构师

**内容**：
- ✅ 核心理念
- ✅ 架构设计
- ✅ 与 AndroidWorld 对比
- ✅ 评估指标

**何时阅读**：需要理解框架设计时

---

#### 5. [任务定义文档](vision_model_training_tasks.md)
**适合人群**：AI研究员、测试人员

**内容**：
- ✅ 任务目标
- ✅ 4种任务变体
- ✅ 验证规则详解
- ✅ 代码调用示例

**何时阅读**：需要理解验证规则时

---

#### 6. [任务表格汇总](tasks_table_for_vision_training.md)
**适合人群**：所有用户

**内容**：
- ✅ AndroidWorld 风格表格
- ✅ 所有任务类型一览
- ✅ 任务复杂度分类

**何时阅读**：需要快速查看所有任务类型时

---

### 辅助文档（按需阅读）

#### 7. [项目结构说明](PROJECT_STRUCTURE.md)
**适合人群**：开发人员

**内容**：
- ✅ 文件组织
- ✅ 组件说明
- ✅ 文档导航
- ✅ 扩展指南

**何时阅读**：需要了解项目结构时

---

#### 8. [演示脚本](DEMO_SCRIPT.md)
**适合人群**：讲师、视频制作者

**内容**：
- ✅ 4个演示场景
- ✅ 录制技巧
- ✅ 后期处理建议

**何时阅读**：需要录制演示视频时

---

#### 9. [中文总览](README_CN.md)
**适合人群**：中文用户

**内容**：
- ✅ 完整中文说明
- ✅ 使用场景
- ✅ 常见问题
- ✅ 技术细节

**何时阅读**：需要完整中文参考时

---

## 🎭 按角色推荐

### 👨‍💻 AI研究员

**推荐阅读顺序**：
1. [框架总览](README.md) - 理解设计理念
2. [任务定义文档](vision_model_training_tasks.md) - 理解验证规则
3. [任务表格汇总](tasks_table_for_vision_training.md) - 查看所有任务
4. [命令行工具指南](CLI_VALIDATION_GUIDE.md) - 实际使用

**核心关注**：
- 验证规则的设计
- 与 AndroidWorld 的对比
- 评估指标

---

### 🧪 测试人员

**推荐阅读顺序**：
1. [快速开始示例](QUICK_START_EXAMPLE.md) - 快速上手
2. [命令行工具指南](CLI_VALIDATION_GUIDE.md) - 掌握所有功能
3. [快速参考卡片](../VISION_VALIDATION.md) - 日常查阅

**核心关注**：
- 如何验证各种任务
- 故障排除
- 批量测试

---

### 💻 开发人员

**推荐阅读顺序**：
1. [项目结构说明](PROJECT_STRUCTURE.md) - 了解结构
2. [命令行工具指南](CLI_VALIDATION_GUIDE.md) - 理解功能
3. [验证器源码](../spec/validators/flight_booking_task_validator.rb) - 查看实现
4. [Rake 任务源码](../lib/tasks/vision_validate.rake) - 理解工具

**核心关注**：
- 代码结构
- 扩展方法
- API 设计

---

### 👨‍🏫 讲师/培训师

**推荐阅读顺序**：
1. [框架总览](README.md) - 理解背景
2. [演示脚本](DEMO_SCRIPT.md) - 准备教学材料
3. [快速开始示例](QUICK_START_EXAMPLE.md) - 实际演示

**核心关注**：
- 演示场景
- 录制技巧
- 学员常见问题

---

### 👔 产品经理

**推荐阅读顺序**：
1. [中文总览](README_CN.md) - 完整了解
2. [框架总览](README.md) - 理解价值
3. [任务表格汇总](tasks_table_for_vision_training.md) - 查看功能

**核心关注**：
- 业务价值
- 使用场景
- 功能覆盖

---

## 📊 文档统计

| 文档 | 行数 | 字数估算 | 阅读时间 |
|------|------|----------|----------|
| [快速开始示例](QUICK_START_EXAMPLE.md) | 291 | ~3,500 | 10分钟 |
| [快速参考卡片](../VISION_VALIDATION.md) | 154 | ~1,800 | 3分钟 |
| [命令行工具指南](CLI_VALIDATION_GUIDE.md) | 391 | ~4,800 | 20分钟 |
| [框架总览](README.md) | 211 | ~2,500 | 15分钟 |
| [任务定义文档](vision_model_training_tasks.md) | 406 | ~5,000 | 25分钟 |
| [任务表格汇总](tasks_table_for_vision_training.md) | 283 | ~3,400 | 10分钟 |
| [项目结构说明](PROJECT_STRUCTURE.md) | 240 | ~2,900 | 15分钟 |
| [演示脚本](DEMO_SCRIPT.md) | 339 | ~4,100 | 20分钟 |
| [中文总览](README_CN.md) | ~400 | ~4,800 | 25分钟 |
| **总计** | **~2,700** | **~33,000** | **~143分钟** |

---

## 🔍 快速搜索

### 按关键词查找

| 关键词 | 相关文档 |
|--------|----------|
| **快速上手** | [快速开始示例](QUICK_START_EXAMPLE.md) |
| **命令行** | [命令行工具指南](CLI_VALIDATION_GUIDE.md) |
| **参数** | [快速参考卡片](../VISION_VALIDATION.md) |
| **验证规则** | [任务定义文档](vision_model_training_tasks.md) |
| **故障排除** | [快速开始示例](QUICK_START_EXAMPLE.md#故障排除) |
| **示例** | [命令行工具指南](CLI_VALIDATION_GUIDE.md#使用示例) |
| **设计理念** | [框架总览](README.md#核心理念) |
| **AndroidWorld** | [框架总览](README.md#与-androidworld-的对比) |
| **扩展** | [项目结构说明](PROJECT_STRUCTURE.md#贡献指南) |
| **录制视频** | [演示脚本](DEMO_SCRIPT.md) |

---

## 🗺️ 学习路径

### 🚶 入门路径（30分钟）

1. [快速参考卡片](../VISION_VALIDATION.md) - 3分钟
2. [快速开始示例](QUICK_START_EXAMPLE.md) - 10分钟
3. 实际操作：运行第一个验证 - 5分钟
4. [命令行工具指南](CLI_VALIDATION_GUIDE.md) - 浏览示例部分 - 12分钟

✅ **完成后你将能够**：独立使用工具完成基本验证

---

### 🏃 进阶路径（60分钟）

1. [框架总览](README.md) - 15分钟
2. [任务定义文档](vision_model_training_tasks.md) - 25分钟
3. [任务表格汇总](tasks_table_for_vision_training.md) - 10分钟
4. [项目结构说明](PROJECT_STRUCTURE.md) - 10分钟

✅ **完成后你将能够**：理解框架设计，自定义验证规则

---

### 🏋️ 专家路径（120分钟）

1. 完成入门路径 + 进阶路径 - 90分钟
2. 阅读源码：
   - [验证器源码](../spec/validators/flight_booking_task_validator.rb) - 15分钟
   - [Rake 任务源码](../lib/tasks/vision_validate.rake) - 10分钟
3. [演示脚本](DEMO_SCRIPT.md) - 5分钟

✅ **完成后你将能够**：修改源码，扩展功能，录制教程

---

## 📮 获取帮助

### 内置帮助

```bash
rake vision:help
```

### 文档帮助

1. 查看 [快速开始示例](QUICK_START_EXAMPLE.md) 的故障排除部分
2. 查看 [命令行工具指南](CLI_VALIDATION_GUIDE.md) 的故障排除部分
3. 查看 [中文总览](README_CN.md) 的常见问题部分

### 源码帮助

- 验证器：[spec/validators/flight_booking_task_validator.rb](../spec/validators/flight_booking_task_validator.rb)
- 命令行工具：[lib/tasks/vision_validate.rake](../lib/tasks/vision_validate.rake)

---

## 🎉 开始使用

选择适合你的起点：

- 🆕 **新手**：从 [快速开始示例](QUICK_START_EXAMPLE.md) 开始
- 📖 **想深入了解**：从 [框架总览](README.md) 开始
- 💻 **开发人员**：从 [项目结构说明](PROJECT_STRUCTURE.md) 开始
- 🎬 **录制教程**：从 [演示脚本](DEMO_SCRIPT.md) 开始

---

**祝学习愉快！** 📚✨
