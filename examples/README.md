# 验证 API 示例代码

本目录包含调用验证任务 API 的示例代码。

## 📋 文件说明

### Python 示例 (`python_example.py`)

**用途**：演示如何使用 Python 调用验证 API

**依赖安装**：

```bash
# 方法1: 使用 pip
pip3 install requests

# 方法2: 使用系统包管理器（Ubuntu/Debian）
sudo apt-get install python3-requests

# 方法3: 使用 pip 且没有 root 权限
pip3 install --user requests
```

**运行示例**：

```bash
# 基础示例
python3 examples/python_example.py basic

# 带参数示例
python3 examples/python_example.py params

# 批量测试示例
python3 examples/python_example.py batch

# 取消任务示例
python3 examples/python_example.py cancel
```

---

### Bash 示例 (`bash_example.sh`)

**用途**：演示如何使用 Bash/curl 调用验证 API

**依赖**：
- `curl` - 通常系统自带
- `jq` - 用于 JSON 格式化（可选）

**运行示例**：

```bash
# 添加执行权限
chmod +x examples/bash_example.sh

# 运行示例
./examples/bash_example.sh
```

---

## 🚀 快速开始

### 1. 确保 Rails 应用正在运行

```bash
# 在项目根目录运行
bin/dev
```

应用将在 `http://localhost:3000` 启动（或其他端口）。

### 2. 选择你喜欢的方式

#### 方式 A: 使用 Bash（推荐，无需安装依赖）

```bash
chmod +x examples/bash_example.sh
./examples/bash_example.sh
```

#### 方式 B: 使用 Python

```bash
# 先安装依赖
pip3 install requests

# 运行示例
python3 examples/python_example.py basic
```

#### 方式 C: 直接使用 curl

```bash
# 创建验证任务
curl -X POST http://localhost:3000/api/validation_tasks \
  -H "Content-Type: application/json" \
  -d '{
    "departure_city": "深圳",
    "arrival_city": "武汉",
    "departure_date": "2025-01-15"
  }'

# 返回的 task_id 用于后续验证
# 例如: "task_id": "550e8400-e29b-41d4-a716-446655440000"

# 然后执行预订操作...

# 最后验证结果
curl -X POST http://localhost:3000/api/validation_tasks/YOUR_TASK_ID/verify
```

---

## 📝 示例说明

### Python 示例包含 4 个场景

1. **basic** - 基础验证流程
   ```bash
   python3 examples/python_example.py basic
   ```

2. **params** - 带完整参数的验证
   ```bash
   python3 examples/python_example.py params
   ```

3. **batch** - 批量测试多个任务
   ```bash
   python3 examples/python_example.py batch
   ```

4. **cancel** - 取消任务
   ```bash
   python3 examples/python_example.py cancel
   ```

### Bash 示例包含完整流程

运行 `bash_example.sh` 会自动执行：
- 创建验证任务
- 查询任务状态
- 验证任务结果
- 取消任务

---

## ⚠️ 常见问题

### Q1: `ModuleNotFoundError: No module named 'requests'`

**原因**：Python 环境中没有安装 requests 库

**解决**：
```bash
pip3 install requests
# 或
pip3 install --user requests
```

### Q2: `pip: command not found` 或 `pip3: command not found`

**原因**：系统中没有安装 pip

**解决方案 A**（Ubuntu/Debian）：
```bash
sudo apt-get update
sudo apt-get install python3-pip
```

**解决方案 B**（使用系统包管理器直接安装 requests）：
```bash
sudo apt-get install python3-requests
```

**解决方案 C**（使用 Bash 示例代替）：
```bash
# Bash 示例不需要 Python 依赖
./examples/bash_example.sh
```

### Q3: `Connection refused` 或 `Failed to connect`

**原因**：Rails 应用没有运行，或端口不对

**解决**：
1. 确保 Rails 应用正在运行：`bin/dev`
2. 检查端口号（默认 3000）
3. 修改示例代码中的 `API_BASE` 变量

### Q4: 权限错误 `Permission denied`

**原因**：脚本没有执行权限

**解决**：
```bash
chmod +x examples/bash_example.sh
chmod +x examples/python_example.py
```

---

## 🔧 自定义配置

### 修改 API 地址

**Python 示例**：
```python
# 在 python_example.py 中修改
API_BASE = "http://localhost:3000/api"  # 改为你的地址
```

**Bash 示例**：
```bash
# 在 bash_example.sh 中修改
API_BASE="http://localhost:3000/api"  # 改为你的地址
```

### 修改测试参数

**Python 示例**：
```python
# 在 example_basic() 函数中修改
result = create_validation_task(
    departure_city="北京",     # 改为你的城市
    arrival_city="上海",       # 改为你的城市
    departure_date="2025-02-01"  # 改为你的日期
)
```

---

## 📚 相关文档

- [API 完整文档](../docs/API_GUIDE.md) - 详细的 API 说明
- [API 快速参考](../docs/API_README.md) - 常用命令速查
- [命令行工具](../docs/CLI_VALIDATION_GUIDE.md) - 本地验证工具

---

## 💡 提示

1. **推荐使用 Bash 示例**：无需安装额外依赖，直接运行即可
2. **Python 示例更灵活**：适合集成到自动化脚本或训练流程中
3. **命令行工具最简单**：本地开发时使用 `rake vision:validate` 最方便

---

## 🎯 下一步

1. 运行示例代码，熟悉 API 使用
2. 查看 [API_GUIDE.md](../docs/API_GUIDE.md) 了解更多用法
3. 将 API 集成到你的训练流程中

---

**需要帮助？** 查看 [完整文档](../docs/) 或联系开发团队。
