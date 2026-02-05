# DataVersionable 系统模型排除机制

## 问题背景

当 `ApplicationRecord` 全局启用 `DataVersionable` 时，所有继承 `ApplicationRecord` 的模型都会自动获得：

1. **`default_scope`**: `where(data_version: DataVersionable.current_versions)`
2. **`before_create` 钩子**: 自动设置 `data_version` 字段

这对业务模型是正确的行为，但对于**系统模型**（如 Session, Administrator, ValidatorExecution）会导致问题：

### 症状
- ❌ 查询 Session 时报错：`PG::UndefinedColumn: ERROR: column sessions.data_version does not exist`
- ❌ 创建 Session 时报错：`unknown attribute 'data_version' for Session`
- ❌ `current_user` 变成 `nil`，导致视图报错：`undefined method 'name' for nil`

## 解决方案

对于**不需要 `data_version` 字段的系统模型**，需要同时移除两个机制：

### 1. 移除 `default_scope`（查询过滤）

```ruby
class Session < ApplicationRecord
  # 移除继承的 default_scope
  default_scope { unscope(where: :data_version) }
end
```

### 2. 跳过 `before_create` 钩子（自动设置字段）

```ruby
class Session < ApplicationRecord
  # 跳过 DataVersionable 的 before_create 回调
  skip_callback :create, :before, :set_data_version
end
```

## 完整示例

```ruby
class Session < ApplicationRecord
  belongs_to :user

  # Session 是系统模型，不使用 data_version 机制
  # 需要移除 ApplicationRecord 继承的 default_scope 和 callbacks
  default_scope { unscope(where: :data_version) }
  skip_callback :create, :before, :set_data_version

  before_create do
    self.user_agent = Current.user_agent
    self.ip_address = Current.ip_address
  end
end
```

## 系统模型列表

以下模型已应用排除机制（不使用 `data_version`）：

### ✅ 已修复的系统模型
- **Session**: 用户会话（不应有 data_version）
- **Administrator**: 管理员账号（不应有 data_version）
- **AdminOplog**: 管理员操作日志（不应有 data_version）
- **ValidatorExecution**: 验证器执行记录（不应有 data_version）

### ⚠️ ActiveStorage 模型
- **ActiveStorage::Blob**: 文件存储元数据（不继承 ApplicationRecord）
- **ActiveStorage::Attachment**: 文件关联（不继承 ApplicationRecord）
- **ActiveStorage::VariantRecord**: 图片变体（不继承 ApplicationRecord）

> ActiveStorage 模型不继承 `ApplicationRecord`，因此不会受影响，无需额外处理。

## 测试验证

运行以下测试确保修复正确：

```bash
bundle exec rspec spec/models/application_record_data_version_spec.rb
```

### 测试覆盖
1. ✅ 所有业务模型都有 `data_version` 字段
2. ✅ `ApplicationRecord` 全局包含 `DataVersionable`
3. ✅ 系统模型不应该有 `data_version` 字段
4. ✅ 创建记录时自动设置 `data_version`
5. ✅ 查询时自动过滤 `data_version`
6. ✅ 基线数据（`data_version='0'`）在所有会话中可见

## 原理说明

### 为什么需要同时移除 `default_scope` 和 `skip_callback`？

| 操作 | 只移除 default_scope | 只 skip_callback | 两者都移除 |
|------|---------------------|------------------|-----------|
| **查询模型** | ✅ 正常 | ❌ 查询失败（字段不存在） | ✅ 正常 |
| **创建模型** | ❌ 写入失败（字段不存在） | ✅ 正常 | ✅ 正常 |

**结论**：必须同时移除才能完全跳过 `DataVersionable` 机制。

### DataVersionable 继承链

```
ApplicationRecord (include DataVersionable)
    ↓
    ├── User (业务模型，保留 data_version)
    ├── InsuranceOrder (业务模型，保留 data_version)
    ├── Session (系统模型，移除 data_version 机制) ✅
    ├── Administrator (系统模型，移除 data_version 机制) ✅
    └── ValidatorExecution (系统模型，移除 data_version 机制) ✅
```

## 何时需要排除模型？

### ✅ 需要排除（不使用 data_version）
- 系统配置/管理模型（Administrator, AdminOplog）
- 会话管理模型（Session）
- 验证器框架模型（ValidatorExecution）
- 其他非业务数据的系统模型

### ❌ 不应排除（必须使用 data_version）
- 业务数据模型（User, Order, Booking, Product）
- 需要多租户/会话隔离的模型
- 验证器需要创建和验证的数据

## 常见问题

### Q: 为什么不直接给 Session 表添加 `data_version` 字段？
**A**: Session 是系统模型，不应该受验证器会话隔离机制影响。如果添加 `data_version`，会导致：
- 不同验证器会话的用户无法看到自己的 Session
- 自动登录功能失效
- 会话管理逻辑混乱

### Q: 如何判断一个模型是否应该排除？
**A**: 问自己：
1. 这个模型是否是业务数据？（订单、预订、产品等）
2. 验证器是否需要创建/查询这个模型的数据？

如果两个问题都是 **NO**，则应该排除。

### Q: 添加新的系统模型时需要注意什么？
**A**: 如果新模型不需要 `data_version`，记得添加排除逻辑：

```ruby
class NewSystemModel < ApplicationRecord
  # 系统模型，不使用 data_version 机制
  default_scope { unscope(where: :data_version) }
  skip_callback :create, :before, :set_data_version
end
```

## 参考文档
- `app/models/concerns/data_versionable.rb` - DataVersionable 实现
- `spec/models/application_record_data_version_spec.rb` - 测试规范
- `docs/VALIDATOR_DESIGN.md` - 验证器设计文档
