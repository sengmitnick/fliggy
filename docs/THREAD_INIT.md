# Thread Initialization Script

## 概述

`bin/thread_init` 是新环境初始化脚本，确保每个新线程环境都基于最新的主干代码启动。

## 为什么需要这个脚本？

在之前的 Git 操作流程中，新分支创建时可能**没有拉取主干最新代码**：

```bash
# ❌ 旧流程问题
git checkout -b s0203.13  # 基于本地 HEAD，可能已过期
git pull || true          # 如果当前分支不存在远程，拉取失败
```

这导致新环境可能基于过期的代码开发，造成：
- 缺少主干的最新功能
- 遗漏重要的 bug 修复
- 后续合并冲突增多

## 脚本功能

### 1. 拉取最新代码（自动）

脚本会：
1. 检测主干分支（按优先级：`main` > `master` > `develop`）
2. `git fetch origin <main_branch>` 获取最新提交
3. 比较本地和远程提交是否一致
4. 如果有更新，自动合并（优先 `merge`，失败时尝试 `rebase`）
5. 推送更新后的分支到远程（如果有上游跟踪）

**策略说明**：
- **优先 merge**: 保留当前分支的提交历史，适合多人协作
- **fallback rebase**: merge 失败时尝试 rebase，保持线性历史
- **冲突处理**: 如果都失败，中止操作并提示手动解决

### 2. 安装依赖

- `bundle install` - Ruby gems
- `npm install` - NPM packages

### 3. 初始化数据库

- 调用 `bin/db_init` 完成数据库设置

## 使用方式

### 自动执行（推荐）

配置在 `.1024` 文件中，新环境启动时自动运行：

```yaml
dependency_command: bin/thread_init
```

### 手动执行

```bash
bin/thread_init
```

## 输出示例

```
==========================================
🔄 线程环境初始化开始...
==========================================

📥 [1/3] 拉取最新代码...
   当前分支: s0203.13
   主干分支: origin/main
   检测到主干有更新，开始合并...
   ✓ 成功合并主干最新代码
   推送更新到远程...

📦 [2/3] 安装依赖...
   Ruby gems...
   NPM packages...

📊 [3/3] 初始化数据库...

==========================================
✅ 线程环境初始化完成！
==========================================

📝 环境信息：
   分支: s0203.13
   提交: abc1234
   主干: main

📝 后续操作：
   启动服务: bin/dev
   运行测试: rake test
```

## 失败处理

### 场景 1：未找到主干分支

```
⚠️  未找到主干分支（main/master/develop），跳过代码同步
```

**原因**：远程仓库没有标准主干分支名
**处理**：跳过代码同步，继续后续步骤

### 场景 2：合并冲突

```
❌ 代码合并失败，请手动解决冲突

== 请手动解决代码冲突后重试 ==
```

**原因**：本地修改与主干代码冲突
**处理**：
1. 手动解决冲突：`git status` 查看冲突文件
2. 编辑冲突文件，保留正确代码
3. 标记已解决：`git add <file>`
4. 完成合并：`git merge --continue` 或 `git rebase --continue`
5. 重新运行：`bin/thread_init`

## 对比旧流程

| 操作 | 旧流程 | 新流程（thread_init） |
|------|--------|----------------------|
| 检测主干分支 | ❌ 不检测 | ✅ 自动检测 |
| 拉取最新代码 | ⚠️ 尝试但可能失败 | ✅ 强制同步主干 |
| 合并策略 | ❌ 无 | ✅ merge/rebase 双保险 |
| 冲突处理 | ❌ 静默失败 | ✅ 明确提示 |
| 依赖安装 | ✅ 手动执行 | ✅ 自动执行 |
| 数据库初始化 | ✅ 手动执行 | ✅ 自动执行 |

## 技术细节

### 主干分支检测

```ruby
['main', 'master', 'develop'].each do |branch|
  if system("git show-ref --verify --quiet refs/remotes/origin/#{branch}")
    main_branch = branch
    break
  end
end
```

使用 `git show-ref --verify` 检查远程引用是否存在，优先级从高到低。

### 提交比较

```ruby
local_commit = `git rev-parse HEAD`.strip
remote_commit = `git rev-parse origin/#{main_branch}`.strip

if local_commit != remote_commit
  # 需要合并
end
```

比较 SHA-1 哈希值判断是否需要更新。

### 上游跟踪检测

```ruby
upstream = `git rev-parse --abbrev-ref @{u} 2>/dev/null`.strip
if !upstream.empty?
  system("git push origin #{current_branch} 2>/dev/null || true")
end
```

只有设置了上游跟踪的分支才推送，避免孤立分支推送失败。

## 最佳实践

1. **保持主干分支干净**：避免直接在 `main`/`master` 上开发
2. **及时解决冲突**：不要积累大量未合并的更改
3. **定期同步**：长期分支应定期手动运行 `bin/thread_init`
4. **检查输出**：初始化完成后检查环境信息是否正确

## 故障排查

### 问题：脚本卡在 git fetch

**可能原因**：网络问题或权限不足
**解决方案**：
```bash
# 手动 fetch 测试
git fetch origin main

# 检查网络连接
ping github.com

# 检查 SSH 密钥
ssh -T git@github.com
```

### 问题：bundle install 失败

**可能原因**：Ruby 版本不匹配或 gem 依赖问题
**解决方案**：
```bash
# 检查 Ruby 版本
ruby -v

# 清理缓存重试
bundle clean --force
bundle install
```

### 问题：数据库初始化失败

**可能原因**：PostgreSQL 未启动或权限不足
**解决方案**：
```bash
# 检查数据库连接
rails runner "puts ActiveRecord::Base.connection.current_database"

# 手动运行数据库初始化
bin/db_init
```

## 相关文件

- `.1024` - 环境配置文件
- `bin/db_init` - 数据库初始化脚本
- `config/database.yml` - 数据库配置

## 维护指南

如需修改脚本逻辑：
1. 编辑 `bin/thread_init`
2. 测试修改：`bin/thread_init`
3. 提交更改：`git add bin/thread_init && git commit -m "chore: update thread_init"`

如需添加新的初始化步骤，在脚本中插入新的 Step 块。
