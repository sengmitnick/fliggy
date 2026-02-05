# Data Pack Validation - Phase 1 Implementation Summary

## 实施时间
2026-02-04

## 实施内容

### ✅ 已完成

#### 1. 静默数据包加载（lib/tasks/validator.rake）
- 使用 `StringIO` 捕获数据包文件的输出
- 只显示包含"警告"/"错误"关键词的行
- 加载结果显示：`✓` 或 `⚠️`

#### 2. 自动化验证系统（lib/data_pack_validator.rb）

**核心特性：**
- ✅ **自动扫描**：无需手动配置，自动发现所有数据包文件（33个）
- ✅ **自动推断模型**：从文件内容中提取模型名（`Model.insert_all`, `Model.create`）
- ✅ **约定验证**：基于数据库 NOT NULL 约束自动检测必需字段
- ✅ **Schema 变化检测**：对比 `db/schema.rb` 版本，检测数据库变化

**验证规则：**
1. 检查模型是否有 `data_version` 字段（业务表必需）
2. 检查是否有基线数据（`data_version='0'` 的记录）
3. 检查必需字段是否有空值（抽样前3条记录）

#### 3. Schema 变化检测机制（最终方案）

**实现方式：内联常量（AI 可维护）**

```ruby
class DataPackValidator
  # Schema version constant - updated by AI when schema changes
  # This version should match db/schema.rb ActiveRecord::Schema.define(version: ...)
  VALIDATED_SCHEMA_VERSION = '2026_02_04_090615'
  
  def initialize
    @schema_version = extract_schema_version  # 从 schema.rb 读取当前版本
    @last_validated_version = VALIDATED_SCHEMA_VERSION  # 脚本中的常量
  end
end
```

**检测逻辑：**
- 当检测到 schema 变化时，立即终止验证并提示 AI
- AI 需要更新 `VALIDATED_SCHEMA_VERSION` 常量并检查验证逻辑
- 不再使用外部文件存储版本号

**为什么这样设计？**
- Schema 变化会使验证脚本本身失效（新增/删除字段、NOT NULL 约束变化）
- 验证脚本只能由 AI 重新生成，不能简单重新加载数据
- 使用内联常量比外部文件更简洁，避免文件管理问题

#### 4. 集成到 rake 任务

**新增任务：**
```bash
rake validator:validate_data_packs  # 独立验证任务
rake validator:reset_baseline       # 包含验证步骤
```

**reset_baseline 流程：**
1. 清空数据库
2. 静默加载数据包（带过滤）
3. 验证数据包完整性
4. 输出汇总结果

## 测试结果

### 初始测试（硬编码规则）
- 发现 13 个字段映射错误
- 修复后 12/12 通过

### 重构后测试（自动扫描）
- 发现 33 个数据包（非硬编码的 12 个）
- 验证结果：**29/33 通过**

### 失败的数据包分析

**4 个失败的数据包：**
1. `attractions.rb` - Attraction 模型缺少 data_version 字段
2. `cars.rb` - Car 模型缺少 data_version 字段  
3. `insurances.rb` - InsuranceProduct 模型缺少 data_version 字段
4. `visa_services.rb` - VisaProduct 模型缺少 data_version 字段

**问题原因：**
- 这些模型可能尚未迁移到 RLS（Row Level Security）系统
- 需要为这些模型添加 `data_version` 字段的 migration

### Schema 变化检测测试

**测试场景：**
```bash
# 1. 首次运行 - 无历史版本
rails runner "DataPackValidator.new.validate_all"
# → 检测到 schema_changed? = true（首次运行）
# → 提示 AI 更新常量

# 2. AI 更新常量后
VALIDATED_SCHEMA_VERSION = '2026_02_04_090615'
# → schema_changed? = false
# → 验证继续

# 3. 运行 migration 后
rails db:migrate  # schema 版本变为 2026_02_05_120000
rails runner "DataPackValidator.new.validate_all"
# → 检测到 schema_changed? = true
# → 提示 AI 更新常量并检查验证逻辑
```

**提示信息示例：**
```
⚠️  数据库 Schema 已变化，验证脚本需要更新！
   - 脚本中的 Schema 版本: 2026_02_04_090615
   - 当前数据库 Schema 版本: 2026_02_05_120000

🤖 验证脚本失效原因：
   - 新增字段未被验证
   - 删除字段仍在检查
   - NOT NULL 约束变化导致误报

📝 解决方案（仅限 AI 操作）：
   1. 打开 lib/data_pack_validator.rb
   2. 更新常量: VALIDATED_SCHEMA_VERSION = '2026_02_05_120000'
   3. 根据最新 schema 检查并更新验证逻辑
   4. 重新运行此验证命令

🚨 当前验证结果不可靠，终止执行
```

## 输出对比

### 修改前（冗余输出）
```
正在加载 flights_v1 数据包...
  航班日期范围: 2026-02-05 至 2026-02-20 (共16天)
  - 深圳到北京: 每天4个航班，最低价 550元（共 64 个）
  - 上海到深圳: 每天2个航班，最低价 450元（共 32 个）
  ... (15行输出)
✓ 数据包加载完成
```

### 修改后（简洁输出）
```
→ 加载 base.rb... ✓
→ 加载 flights.rb... ✓
→ 加载 hotels.rb... ✓
→ 加载 deep_travel_reviews.rb... ⚠️
    警告: 未找到匹配的见解员（ID: guide_123）

🔍 数据包验证 - 检查已加载数据的完整性
================================================================================
✅ base.rb                     - 所有检查通过
✅ flights.rb                  - 所有检查通过
❌ attractions.rb              - 1 个问题
  → Attraction 缺少 data_version 字段（业务表必须有此字段）
...

================================================================================
✅ 29/33 个数据包验证通过
================================================================================
```

## 核心实现文件

### 1. lib/data_pack_validator.rb
- `initialize` - 初始化并检查 schema 版本
- `schema_changed?` - 检测 schema 是否变化
- `validate_all` - 验证所有数据包
- `validate_data_pack(file_path)` - 验证单个数据包
- `infer_models_from_file(file_path)` - 从文件推断模型
- `validate_model(model_class)` - 验证单个模型
- `extract_schema_version` - 从 schema.rb 提取版本号

**关键常量：**
```ruby
# 脚本验证的 schema 版本（由 AI 更新）
VALIDATED_SCHEMA_VERSION = '2026_02_04_090615'

# 数据包目录
DATA_PACK_DIR = Rails.root.join('app/validators/support/data_packs/v1')
```

### 2. lib/tasks/validator.rake
修改了 `validator:reset_baseline` 任务：
- Step 2: 带输出过滤的数据包加载
- Step 3: 调用 DataPackValidator 进行验证

### 3. docs/DATA_PACK_VALIDATION.md
完整设计文档，包含三个阶段的实施计划

## 技术亮点

### 1. 自动发现机制
```ruby
# 不再需要维护硬编码的验证规则列表
VALIDATION_RULES = {
  'base.rb' => { models: ['City', 'Destination', 'User'], required_fields: [...] },
  # ... 32 more entries
}

# 改为自动扫描和推断
data_pack_files = Dir.glob(DATA_PACK_DIR.join('*.rb')).sort
models = infer_models_from_file(file_path)  # 正则提取
```

### 2. 约定优于配置
```ruby
# 不需要手动指定每个字段
required_fields: [:name, :price, :city]

# 改为从数据库 schema 读取 NOT NULL 约束
required_columns = model_class.columns
  .select { |col| !col.null && col.name !~ /^(id|created_at|updated_at)$/ }
  .map(&:name)
```

### 3. Schema 版本跟踪（内联常量方案）

**演进历史：**
1. **初版**：外部文件 `tmp/data_pack_validator_schema_version.txt`
   - 问题：临时文件可能丢失
2. **第二版**：外部文件 `config/data_pack_validator_schema_version.txt`
   - 问题：需要维护额外的文件，增加复杂度
3. **最终版**：内联常量 `VALIDATED_SCHEMA_VERSION`
   - 优势：简洁、无文件依赖、AI 易于更新

**为什么不自动保存版本？**
- Schema 变化会导致验证逻辑失效（新增/删除字段、约束变化）
- 验证脚本需要 AI 重新审查和更新，不能自动化
- 使用内联常量强制 AI 参与，避免"静默失效"

## 后续工作

### Phase 2: 数据包清理（待实施）
- 批量修改数据包文件，移除冗余输出
- 统一输出格式规范

### Phase 3: 验证规则完善（待实施）
- 外键完整性验证
- 数据格式验证（正则表达式）
- 数据范围验证（最小值/最大值）

## 经验总结

### 设计决策

1. **为什么不硬编码验证规则？**
   - 数据包数量可能增加（33 个，不是最初以为的 12 个）
   - 模型字段可能变化（需要频繁更新硬编码）
   - 自动推断更可靠且易维护

2. **为什么使用内联常量而非外部文件？**
   - 避免文件管理复杂度（路径、权限、丢失等）
   - 强制 AI 参与 schema 变化处理
   - 版本号和验证逻辑在同一文件中，便于同步更新

3. **为什么 schema 变化时不自动更新验证脚本？**
   - Schema 变化可能影响验证逻辑本身（新字段、删除字段）
   - 需要人工（AI）判断是否需要修改验证规则
   - 强制阻断可以避免错误的验证结果被忽略

### 技术难点

1. **正则提取模型名**
   - 需要匹配 `Model.insert_all`, `Model.create!`, `Model.where(...).update_all` 等多种模式
   - 需要排除系统表（Administrator, Session, ActiveStorage::*）

2. **Schema 版本提取**
   - 版本格式包含下划线：`2026_02_04_090615`
   - 正则需要匹配：`/ActiveRecord::Schema\[\d+\.\d+\]\.define\(version:\s*([\d_]+)\)/`

3. **输出过滤**
   - 使用 `StringIO` 重定向 `$stdout`
   - 加载完成后恢复原始 stdout
   - 只显示包含警告/错误关键词的行

## 测试建议

### 手动测试步骤

1. **测试正常流程：**
```bash
rake validator:reset_baseline
# 应该看到简洁的加载输出和验证结果
```

2. **测试 schema 变化检测：**
```bash
# 运行 migration
rails db:migrate

# 验证数据包
rake validator:validate_data_packs
# 应该看到 schema 变化提示

# AI 更新常量
# 编辑 lib/data_pack_validator.rb
# 修改 VALIDATED_SCHEMA_VERSION

# 再次验证
rake validator:validate_data_packs
# 应该正常通过
```

3. **测试失败的数据包：**
```bash
# 临时修改某个模型，删除 data_version 字段
rails runner "
  ActiveRecord::Migration.remove_column :flights, :data_version
"

# 验证应该失败
rake validator:validate_data_packs
```

### 自动化测试（Phase 3 可实现）

创建 RSpec 测试：
```ruby
RSpec.describe DataPackValidator do
  it "detects missing data_version field"
  it "validates required fields based on NOT NULL constraints"
  it "detects schema changes"
  it "infers models from data pack files"
end
```

## 结论

Phase 1 成功实现了：
1. ✅ 静默数据包加载（只显示关键错误）
2. ✅ 自动化验证系统（无需手动配置）
3. ✅ Schema 变化检测（使用内联常量，AI 可维护）
4. ✅ 集成到 rake 任务中

当前状态：29/33 数据包通过验证，4 个失败的数据包需要添加 `data_version` 字段。

**最终方案优势：**
- 简洁：无需维护外部文件
- 可维护：AI 可直接更新常量
- 安全：强制 AI 审查 schema 变化
- 透明：版本号和验证逻辑在同一文件中
