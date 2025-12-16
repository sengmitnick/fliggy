# 示例代码依赖安装指南

## ❌ 遇到错误

如果你看到以下错误：

```
ModuleNotFoundError: No module named 'requests'
```

或

```
bash: pip: command not found
```

**不用担心！** 这是正常的，下面是解决方案。

---

## ✅ 解决方案

### 方案 1: 使用 Bash 示例（推荐，无需安装）

Bash 示例不需要任何 Python 依赖，直接就能运行：

```bash
chmod +x examples/bash_example.sh
./examples/bash_example.sh
```

**优点**：
- ✅ 无需安装任何依赖
- ✅ 系统自带 curl 命令即可
- ✅ 立即可用

---

### 方案 2: 安装 Python requests 库

如果你想使用 Python 示例，需要安装 `requests` 库：

#### 2.1 使用 pip3 安装（推荐）

```bash
pip3 install requests
```

如果提示权限不足，使用：

```bash
pip3 install --user requests
```

#### 2.2 使用系统包管理器安装

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install python3-requests
```

**CentOS/RHEL:**
```bash
sudo yum install python3-requests
```

**macOS:**
```bash
brew install python3
pip3 install requests
```

#### 2.3 如果 pip3 不存在，先安装 pip

**Ubuntu/Debian:**
```bash
sudo apt-get install python3-pip
```

**CentOS/RHEL:**
```bash
sudo yum install python3-pip
```

---

### 方案 3: 使用命令行工具（最简单）

如果你只是想测试验证功能，使用命令行工具最简单：

```bash
rake vision:validate departure_city=深圳 arrival_city=武汉 departure_date=2025-01-15
```

**优点**：
- ✅ 无需额外依赖
- ✅ 本地环境直接运行
- ✅ 最快速的测试方式

---

### 方案 4: 直接使用 curl

不需要任何脚本，直接用 curl 命令：

```bash
# 1. 创建验证任务
curl -X POST http://localhost:3000/api/validation_tasks \
  -H "Content-Type: application/json" \
  -d '{
    "departure_city": "深圳",
    "arrival_city": "武汉",
    "departure_date": "2025-01-15"
  }'

# 2. 复制返回的 task_id

# 3. 执行预订操作（手动或大模型）

# 4. 验证结果（替换 YOUR_TASK_ID）
curl -X POST http://localhost:3000/api/validation_tasks/YOUR_TASK_ID/verify
```

---

## 🎯 推荐使用顺序

1. **本地测试** → 使用 `rake vision:validate`
2. **快速验证 API** → 使用 `bash_example.sh`
3. **集成到代码** → 安装 Python requests 后使用 `python_example.py`
4. **手动调试** → 直接使用 `curl` 命令

---

## 📋 检查清单

安装前检查：

- [ ] Rails 应用正在运行（`bin/dev`）
- [ ] 可以访问 http://localhost:3000
- [ ] 系统中有 `curl` 命令（`which curl`）

如果使用 Python 示例：

- [ ] Python 3 已安装（`python3 --version`）
- [ ] pip3 已安装（`pip3 --version`）
- [ ] requests 库已安装（`python3 -c "import requests"`）

---

## 🔧 验证安装

### 检查 Python 环境

```bash
# 检查 Python 版本
python3 --version

# 检查 pip3
pip3 --version

# 检查 requests 库是否安装
python3 -c "import requests; print(requests.__version__)"
```

### 检查 curl

```bash
curl --version
```

---

## 💡 常见问题

### Q: 我在 Clacky 云环境中，没有 root 权限

**A:** 使用 `pip3 install --user requests` 安装到用户目录

### Q: 我不想安装任何东西

**A:** 使用 Bash 示例或命令行工具，它们不需要额外安装

### Q: 我的环境没有 pip

**A:** 使用系统包管理器安装 `python3-requests`，或直接使用 Bash/curl

### Q: 安装后还是报错

**A:** 尝试：
```bash
python3 -m pip install requests
```

---

## 📚 相关文档

- [示例代码说明](README.md) - 详细的使用指南
- [API 文档](../docs/API_GUIDE.md) - API 完整说明
- [命令行工具](../docs/CLI_VALIDATION_GUIDE.md) - 本地验证工具

---

## 🆘 仍然无法解决？

1. 查看 [examples/README.md](README.md) 获取更多信息
2. 使用 Bash 示例代替 Python 示例
3. 使用命令行工具 `rake vision:validate`
4. 直接使用 curl 命令

**记住：Python 示例只是一种方式，不是唯一方式！**
