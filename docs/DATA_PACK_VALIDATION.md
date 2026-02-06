# 数据包测试验证功能 - 设计文档

## 问题背景

### 当前问题
数据包加载时输出大量无意义的详细信息，真正重要的错误信息被淹没：

```
→ 加载 flights.rb...
正在加载 flights_v1 数据包...
  航班日期范围: 2026-02-05 至 2026-02-20 (共16天)
  - 深圳到北京: 每天4个航班，最低价 550元（共 64 个）
  - 上海到深圳: 每天2个航班，最低价 450元（共 32 个）
  ...（20行输出）
  ✓ 深圳→杭州: 32 个航班
  未找到匹配的见解员  # ← 关键错误被淹没
```

### 核心问题
1. **噪音过多**：数据包加载时输出大量计数、日期范围等无关信息
2. **错误难定位**：重要错误（如外键缺失、数据不完整）被大量输出掩盖
3. **缺乏验证**：没有统一的数据包完整性验证机制
4. **调试困难**：无法快速确认数据包是否正确加载

## 解决方案

### 设计目标
1. **静默加载**：数据包加载时只输出最核心的状态信息
2. **自动验证**：加载后自动验证数据完整性
3. **清晰报告**：错误信息清晰突出，易于定位问题
4. **独立测试**：提供单独的数据包验证命令

### 核心原则
- **默认静默**：正常加载时只输出文件名和状态（✓/✗）
- **异常突出**：警告/错误信息立即显示，带上下文说明
- **独立验证**：验证逻辑与加载逻辑分离，可独立运行

## 实施方案

### Phase 1: 基础设施（当前阶段）

#### 1.1 数据包验证器类

**文件：`lib/data_pack_validator.rb`**

功能：
- 验证数据包的完整性（记录数、必需字段）
- 验证数据包的正确性（外键关系、数据格式）
- 提供详细的错误报告

```ruby
class DataPackValidator
  # 验证规则定义
  VALIDATION_RULES = {
    'base.rb' => {
      models: {
        'City' => { 
          min_count: 50, 
          required_fields: [:name, :pinyin, :airport_code],
          description: '城市基础数据'
        },
        'Destination' => { 
          min_count: 10, 
          required_fields: [:name, :slug],
          description: '目的地数据'
        },
        'User' => { 
          min_count: 1, 
          required_fields: [:email, :password_digest],
          description: '测试用户'
        }
      }
    },
    'flights.rb' => {
      models: {
        'Flight' => { 
          min_count: 100, 
          required_fields: [:departure_city, :destination_city, :flight_number],
          description: '航班数据',
          sample_validations: [
            ->(record) { record.departure_city.present? || "缺少出发城市" },
            ->(record) { record.flight_number =~ /^[A-Z]{2}\d+$/ || "航班号格式错误: #{record.flight_number}" }
          ]
        }
      },
      foreign_key_checks: [
        { 
          model: 'Flight', 
          field: :departure_city, 
          references: 'City', 
          reference_field: :name,
          description: '航班出发城市必须存在于城市表'
        }
      ]
    }
    # 其他数据包规则逐步添加
  }
  
  def validate_data_pack(pack_name)
    # 验证单个数据包
  end
  
  def validate_all
    # 验证所有数据包
  end
  
  def generate_report
    # 生成验证报告
  end
end
```

#### 1.2 输出捕获与过滤

**修改：`lib/tasks/validator.rake`**

关键改进：
- 捕获数据包内的 `puts` 输出
- 过滤关键词（警告/错误/未找到）
- 只显示异常信息

```ruby
# Step 2: 重新加载数据包（静默模式）
data_pack_files.each do |file|
  filename = File.basename(file)
  print "  → 加载 #{filename}..."
  
  begin
    # 捕获输出
    original_stdout = $stdout
    $stdout = StringIO.new
    
    load file
    
    output = $stdout.string
    $stdout = original_stdout
    
    # 检查输出中是否有警告/错误关键词
    if output =~ /(警告|错误|失败|未找到|missing|error|failed)/i
      warnings << { file: filename, message: output }
      puts " ⚠️"
      puts "    #{output.lines.grep(/(警告|错误|失败|未找到)/i).join('    ')}"
    else
      puts " ✓"
    end
    
    loaded_files << filename
  rescue StandardError => e
    $stdout = original_stdout
    puts " ✗"
    puts "    错误: #{e.message}"
    exit 1
  end
end
```

#### 1.3 独立验证命令

**新增任务：`rake validator:validate_data_packs`**

功能：
- 不重新加载数据包
- 验证已加载数据的完整性
- 生成详细报告

```ruby
desc "Validate data pack integrity without reloading"
task validate_data_packs: :environment do
  puts "\n" + "="*80
  puts "🔍 数据包验证 - 检查已加载数据的完整性"
  puts "="*80 + "\n"
  
  validator = DataPackValidator.new
  results = validator.validate_all
  
  # 详细报告
  results[:packs].each do |pack_name, pack_result|
    if pack_result[:passed]
      puts "✅ #{pack_name.ljust(30)} - 所有检查通过"
    else
      puts "❌ #{pack_name.ljust(30)} - #{pack_result[:error_count]} 个问题"
      pack_result[:errors].each do |error|
        puts "  → #{error}"
      end
    end
  end
  
  # 汇总
  puts "\n" + "="*80
  if results[:all_passed]
    puts "✅ 所有数据包验证通过（#{results[:pack_count]} 个数据包）"
  else
    puts "❌ #{results[:failed_count]}/#{results[:pack_count]} 个数据包验证失败"
    exit 1
  end
  puts "="*80 + "\n"
end
```

### Phase 2: 数据包清理（待实施）

#### 2.1 批量修改数据包文件

目标：移除冗余输出，统一格式

**修改前（❌ 冗余输出）：**
```ruby
puts "正在加载 flights_v1 数据包..."
puts "  航班日期范围: #{start_date} 至 #{end_date} (共16天)"
puts "  - 深圳到北京: 每天4个航班，最低价 550元（共 64 个）"
puts "  - 上海到深圳: 每天2个航班，最低价 450元（共 32 个）"
# ... 大量输出 ...
```

**修改后（✅ 简洁输出）：**
```ruby
# 正常情况：完全静默（由 rake 任务统一输出）
# 异常情况：只输出关键错误
if some_critical_data_missing
  puts "警告: 未找到匹配的见解员（ID: #{guide_id}）"
  puts "建议: 检查 deep_travel_guides.rb 是否正确加载"
end
```

#### 2.2 统一输出格式

**规范：**
- ✅ **允许**：关键错误/警告信息（必须包含"警告"/"错误"关键词）
- ❌ **禁止**：日期范围、记录计数、加载完成提示等信息
- 💡 **详细模式**：通过 `ENV['DATA_PACK_VERBOSE']` 控制

### Phase 3: 验证规则完善（待实施）

## 🚨 Schema 变化检测机制

### 问题背景

Schema 变化会导致验证机制本身失效：

```ruby
# 验证器使用 model_class.columns 读取当前 schema
required_columns = model_class.columns
  .select { |col| !col.null && col.name !~ /^(id|created_at|updated_at)$/ }
  .map(&:name)
```

**问题**：
1. `model_class.columns` 读取的是**新 schema 的结构**
2. 但数据库中的数据是按**旧 schema 加载的**
3. 用新约束检查旧数据 → **验证结果不可信**

### 解决方案

**强制阻断验证 + 提示 AI 重新生成脚本**

```ruby
def validate_all
  # CRITICAL: Schema changes invalidate validation script itself
  if schema_changed?
    puts "\n⚠️  数据库 Schema 已变化，验证脚本需要更新！"
    puts "   - 脚本中的 Schema 版本: #{@last_validated_version}"
    puts "   - 当前数据库 Schema 版本: #{@schema_version}"
    puts "\n🤖 验证脚本失效原因："
    puts "   - 新增字段未被验证"
    puts "   - 删除字段仍在检查"
    puts "   - NOT NULL 约束变化导致误报"
    puts "\n📝 解决方案（仅限 AI 操作）："
    puts "   1. 打开 lib/data_pack_validator.rb"
    puts "   2. 更新常量: VALIDATED_SCHEMA_VERSION = '#{@schema_version}'"
    puts "   3. 根据最新 schema 检查并更新验证逻辑"
    puts "   4. 重新运行此验证命令\n"
    puts "🚨 当前验证结果不可靠，终止执行\n"
    exit 1
  end
  # ...
end
```

### Schema 版本跟踪

1. **提取版本**：从 `db/schema.rb` 中自动提取
   ```ruby
   # ActiveRecord::Schema[7.2].define(version: 2026_02_04_090615) do
   @schema_version = "2026_02_04_090615"
   ```

2. **保存版本**：使用内联常量（由 AI 更新）
   ```ruby
   class DataPackValidator
     # Schema version constant - updated by AI when schema changes
     VALIDATED_SCHEMA_VERSION = '2026_02_04_090615'
   end
   ```

3. **比较版本**：每次验证时检查
   ```ruby
   def schema_changed?
     return true if @last_validated_version.nil?
     @schema_version != @last_validated_version
   end
   ```

### 工作流程

```
1. 运行 migrate → Schema 版本变为 2026_02_05_123456

2. 运行验证 rake validator:validate_data_packs
   → 检测到 schema_changed? = true
   → 显示错误提示，阻断验证，exit 1
   → 提示 AI 更新 VALIDATED_SCHEMA_VERSION 常量

3. AI 更新脚本
   → 打开 lib/data_pack_validator.rb
   → 修改: VALIDATED_SCHEMA_VERSION = '2026_02_05_123456'
   → 检查并更新验证逻辑（如需）

4. 再次运行验证
   → schema_changed? = false
   → 验证继续
```

### 为什么必须阻断？

如果不阻断，可能出现：

```ruby
# 例子：在 migration 中添加了 NOT NULL 约束
class AddRequiredFieldToHotel < ActiveRecord::Migration[7.2]
  def change
    add_column :hotels, :star_rating, :integer, null: false, default: 3
  end
end

# 旧数据没有 star_rating 字段
# 新验证器检查 star_rating 必填 → 失败
# 但实际上是 schema 变化导致的，不是数据包问题
```

---

### Phase 3: 验证规则完善（待实施）

#### 3.1 为每个数据包定义验证规则

逐步完善 `VALIDATION_RULES`：
- `base.rb` - City, Destination, User
- `flights.rb` - Flight, FlightOffer
- `hotels.rb` - Hotel, HotelRoom, HotelPackage
- `trains.rb` - Train, TrainBooking
- `attractions.rb` - Attraction, Ticket, Activity
- `deep_travel_venues.rb` - DeepTravelGuide, DeepTravelProduct
- ... 其他数据包

#### 3.2 业务逻辑验证

示例：
```ruby
# 验证外键完整性
foreign_key_checks: [
  { model: 'Flight', field: :departure_city, references: 'City', reference_field: :name },
  { model: 'Hotel', field: :city, references: 'City', reference_field: :name }
]

# 验证数据格式
format_checks: [
  { model: 'Flight', field: :flight_number, pattern: /^[A-Z]{2}\d+$/ },
  { model: 'User', field: :email, pattern: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i }
]

# 验证数据范围
range_checks: [
  { model: 'Flight', field: :price, min: 0, max: 100000 },
  { model: 'Hotel', field: :star_rating, min: 1, max: 5 }
]
```

## 预期效果

### 修改前（当前）
```
→ 加载 flights.rb...
正在加载 flights_v1 数据包...
  航班日期范围: 2026-02-05 至 2026-02-20 (共16天)
  - 深圳到北京: 每天4个航班，最低价 550元（共 64 个）
  - 上海到深圳: 每天2个航班，最低价 450元（共 32 个）
  - 北京往返上海: 每天去程9个航班...
  - 广州往返成都: 每天各2个航班...
  ... (15行输出)
  ✓ 深圳→杭州: 32 个航班
 ✓
```

### 修改后（目标）
```
→ 加载 base.rb... ✓
→ 加载 flights.rb... ✓
→ 加载 hotels.rb... ✓
→ 加载 deep_travel_reviews.rb... ⚠️
    警告: 未找到匹配的见解员（ID: guide_123）
    建议: 检查 deep_travel_guides.rb 是否已加载
→ 加载 trains.rb... ✓

🔍 Step 3: 验证数据包完整性...
✅ 所有数据包验证通过（共 15 个数据包，2,847 条记录）
```

## 使用说明

### 开发者使用

**重置基线数据（带验证）：**
```bash
rake validator:reset_baseline
```

**仅验证数据包（不重新加载）：**
```bash
rake validator:validate_data_packs
```

**详细模式（调试用）：**
```bash
DATA_PACK_VERBOSE=true rake validator:reset_baseline
```

**导出验证报告（Phase 3）：**
```bash
rake validator:validate_data_packs EXPORT=report.json
```

### CI/CD 集成

```yaml
# .github/workflows/ci.yml
- name: Validate data packs
  run: |
    bundle exec rake validator:reset_baseline
    bundle exec rake validator:validate_data_packs
```

## 实施进度

- [x] Phase 1.1: 创建 DataPackValidator 类
- [x] Phase 1.2: 修改 validator.rake 输出捕获逻辑  
- [x] Phase 1.3: 添加 validate_data_packs 任务
- [x] **Phase 1.4: 添加关联表完整性检查（ASSOCIATION_RULES）** ✨ NEW
- [x] **Phase 1.5: 添加业务规则验证（BUSINESS_RULES）** ✨ NEW
- [ ] Phase 2.1: 批量清理数据包冗余输出
- [ ] Phase 2.2: 统一数据包输出格式
- [ ] Phase 3.1: 完善所有数据包验证规则
- [ ] Phase 3.2: 添加业务逻辑验证

## 注意事项

1. **向后兼容**：详细模式保留原有输出，确保不影响现有调试流程
2. **渐进式迁移**：数据包清理可以逐步进行，不必一次性完成
3. **验证规则维护**：新增数据包时，同步添加验证规则
4. **性能考虑**：验证逻辑不应显著增加加载时间（目标 <1s）

## 参考资料

- 原始讨论：https://github.com/your-org/your-repo/issues/xxx
- 相关文档：`docs/VALIDATOR_DESIGN.md`
- 数据包目录：`app/validators/support/data_packs/v1/`
- **新增功能文档**：`docs/DATA_PACK_ASSOCIATION_VALIDATION.md` - 关联表完整性检查和业务规则验证 ✨
