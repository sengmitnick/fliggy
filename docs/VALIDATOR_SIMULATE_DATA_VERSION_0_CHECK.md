# Validator Simulate Data Version 0 Creation Detection

## Problem Description

**CRITICAL ISSUE**: Many validators create `data_version: 0` records in their `simulate` methods to bypass missing data packs. This is a serious violation that:

1. **Pollutes baseline data**: Creates data in the shared baseline (data_version: 0) instead of session-scoped data
2. **Breaks test isolation**: Affects other validator executions due to shared data pollution
3. **Masks data pack gaps**: Hides missing test data that should be in data packs
4. **Creates dependency chaos**: Makes validators dependent on execution order

## Root Cause

Validators use fallback patterns like `@variable || Model.create!(..., data_version: 0)` when data packs are incomplete:

```ruby
# ❌ WRONG - V312 Example (Typical Anti-Pattern)
def simulate
  user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
  
  # 1. Create surfing activity with fallback creation
  surfing_activity = @surfing_activity || AttractionActivity.create!(
    attraction: @attraction,
    name: '冲浪教学（含装备）',
    description: '专业教练指导，提供全套冲浪装备',
    current_price: 280,
    data_version: 0  # ❌ Pollutes baseline data!
  )
  
  # 2. Create beach entertainment with fallback creation
  entertainment_activity = @entertainment_activity || AttractionActivity.create!(
    attraction: @attraction,
    name: '海滩娱乐项目',
    description: '沙滩排球、摩托艇、香蕉船等多项娱乐',
    current_price: 150,
    data_version: 0  # ❌ Pollutes baseline data!
  )
  
  # Create orders with session-scoped data_version (correct)
  ActivityOrder.create!(
    user: user,
    attraction_activity: surfing_activity,
    visit_date: @activity_date,
    quantity: @participant_count,
    total_price: surfing_activity.current_price * @participant_count,
    insurance_type: 'premium',
    status: 'paid',
    data_version: @data_version  # ✅ Correct - session-scoped
  )
end
```

**Why this is wrong:**

1. `@surfing_activity` is `nil` when data pack doesn't have this activity
2. Fallback creates `AttractionActivity` with `data_version: 0`
3. This record persists across validator sessions
4. Other validators will see this "fake" activity

## Detection Implementation

### Step 4.5 in `rake validator:simulate`

Added automated detection in `lib/tasks/validator.rake`:

```ruby
# Step 4.5: 检查 simulate 方法中是否私自创建 data_version: 0 的数据（绕过数据包）
puts "🔍 Step 4.5: Checking simulate methods for data_version: 0 creation violations..."
simulate_violations = []

validator_files = Dir[Rails.root.join('app/validators/**/*_validator.rb')]
validator_files.each do |file|
  next if file.end_while?('base_validator.rb')
  
  validator_name = File.basename(file, '.rb')
  content = File.read(file)
  
  # Extract simulate method content
  simulate_method = content.match(/def\s+simulate.*?^\s*end/m)&.[](0)
  
  if simulate_method
    violations = []
    
    # Check 1: Direct creation of data_version: 0 records (most severe)
    if simulate_method.match?(/\.create[!]?\([^)]*data_version:\s*0/m)
      creation_statements = simulate_method.scan(/(\w+)\.create[!]?\([^)]*data_version:\s*0[^)]*\)/m).flatten.uniq
      violations << "直接创建 data_version: 0 的记录: #{creation_statements.join(', ')}"
    end
    
    # Check 2: Fallback creation pattern bypassing data packs
    # Pattern: @variable || Model.create!(..., data_version: 0)
    if simulate_method.match?(/@\w+\s*\|\|\s*\w+\.create[!]?\([^)]*data_version:\s*0/m)
      fallback_patterns = simulate_method.scan(/@(\w+)\s*\|\|\s*(\w+)\.create[!]?/m)
      pattern_str = fallback_patterns.map { |var, model| "@#{var} || #{model}.create" }.join(', ')
      violations << "使用后备创建模式绕过数据包: #{pattern_str}"
    end
    
    # Check 3: insert/insert_all with data_version: 0
    if simulate_method.match?(/\.(insert|insert_all)\([^)]*data_version:\s*0/m)
      violations << "使用 insert/insert_all 创建 data_version: 0 的记录"
    end
    
    if violations.any?
      # Extract specific violation code lines
      violation_lines = []
      simulate_method.each_line.with_index do |line, idx|
        if line.match?(/data_version:\s*0/) && (line.match?(/\.create/) || line.match?(/\.insert/))
          violation_lines << { line_num: idx + 1, code: line.strip }
        end
      end
      
      simulate_violations << {
        validator: validator_name,
        file: file,
        violations: violations,
        code_samples: violation_lines.first(5)
      }
    end
  end
end
```

### Detection Results (Current State)

```
❌ 35 validator(s) have simulate methods that create data_version: 0 records

Affected validators:
- v163-v200: 22 validators creating HotelRoom (data_version: 0)
- v257, v260, v261, v265: Creating TourPackage (data_version: 0)
- v308, v310, v312, v314, v315, v316: Creating AttractionActivity (data_version: 0)
```

## Correct Pattern

### ✅ Proper Implementation

```ruby
# Step 1: Update data pack file (app/validators/support/data_packs/v1/attractions.rb)
puts "正在加载 attractions_v1 数据包..."

# Add surfing activities
AttractionActivity.insert_all([
  {
    attraction_id: Attraction.find_by(name: '深圳大梅沙海滨公园', data_version: 0)&.id,
    name: '冲浪教学（含装备）',
    description: '专业教练指导，提供全套冲浪装备',
    current_price: 280,
    data_version: 0
  },
  {
    attraction_id: Attraction.find_by(name: '深圳大梅沙海滨公园', data_version: 0)&.id,
    name: '海滩娱乐项目',
    description: '沙滩排球、摩托艇、香蕉船等多项娱乐',
    current_price: 150,
    data_version: 0
  }
])

puts "✓ 数据包加载完成"
```

```ruby
# Step 2: Update prepare method (validator file)
def prepare
  @activity_date = Date.current + 4.days
  @participant_count = 2
  
  # Fixed: Use find_by! (query only, no creation)
  @attraction = Attraction
    .joins(:attraction_activities)
    .where(name: '深圳大梅沙海滨公园', data_version: 0)
    .where(attraction_activities: { data_version: 0 })
    .first!
  
  # Query activities (must exist in data pack)
  @surfing_activity = @attraction.attraction_activities
    .where(name: '冲浪教学（含装备）', data_version: 0)
    .first!
  
  @entertainment_activity = @attraction.attraction_activities
    .where(name: '海滩娱乐项目', data_version: 0)
    .first!
  
  {
    task: "请预订深圳大梅沙海滨公园的冲浪服务...",
    requirements: { ... },
    hint: "需要预订深圳大梅沙海滨公园的多个活动..."
  }
end
```

```ruby
# Step 3: Update simulate method (validator file)
def simulate
  user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
  
  # ✅ CORRECT - No fallback creation, use data from prepare
  # 1. Create surfing activity order (session-scoped)
  ActivityOrder.create!(
    user: user,
    attraction_activity: @surfing_activity,  # From prepare (data_version: 0)
    visit_date: @activity_date,
    quantity: @participant_count,
    total_price: @surfing_activity.current_price * @participant_count,
    insurance_type: 'premium',
    status: 'paid',
    data_version: @data_version  # ✅ Session-scoped
  )
  
  # 2. Create beach entertainment order (session-scoped)
  ActivityOrder.create!(
    user: user,
    attraction_activity: @entertainment_activity,  # From prepare (data_version: 0)
    visit_date: @activity_date,
    quantity: @participant_count,
    total_price: @entertainment_activity.current_price * @participant_count,
    insurance_type: 'basic',
    status: 'paid',
    data_version: @data_version  # ✅ Session-scoped
  )
end
```

### Key Principles

| Layer | Data Type | data_version | Creation Location |
|-------|-----------|--------------|-------------------|
| **Data Pack** | Foundation data (Attraction, Hotel, Flight, etc.) | `0` | `app/validators/support/data_packs/v1/` |
| **Prepare** | Query only | N/A | Validator `prepare` method |
| **Simulate** | Business records (Orders, Bookings) | `@data_version` | Validator `simulate` method |

**Rules:**
1. ✅ Data packs create foundation data with `data_version: 0`
2. ✅ Prepare queries data with `find_by!` (no creation)
3. ✅ Simulate creates business records with `data_version: @data_version`
4. ❌ NEVER use `@var || Model.create!(..., data_version: 0)` fallback pattern
5. ❌ NEVER create `data_version: 0` records in `simulate` method

## Fix Workflow

### For Each Affected Validator:

1. **Identify missing data**: What foundation data is missing from data packs?
2. **Update data pack**: Add missing data to appropriate data pack file
3. **Update prepare**: Use `find_by!` to query data (ensure it exists)
4. **Update simulate**: Remove fallback creation, use instance variables from prepare
5. **Test**: Run `rake validator:reset_baseline` then `rake validator:simulate_single[validator_id]`

### Example Fix: V312

**Before:**
```ruby
def simulate
  surfing_activity = @surfing_activity || AttractionActivity.create!(..., data_version: 0)  # ❌ Fallback
end
```

**After:**
```ruby
# 1. Add to data pack (attractions.rb)
AttractionActivity.insert_all([
  { name: '冲浪教学（含装备）', ..., data_version: 0 }
])

# 2. Update prepare
def prepare
  @surfing_activity = @attraction.attraction_activities
    .where(name: '冲浪教学（含装备）', data_version: 0)
    .first!  # Must exist in data pack
end

# 3. Update simulate
def simulate
  ActivityOrder.create!(
    attraction_activity: @surfing_activity,  # ✅ From prepare
    data_version: @data_version  # ✅ Session-scoped
  )
end
```

## Impact Analysis

### Current State (35 Violating Validators)

**Category 1: Hotel Room Creation (22 validators)**
- v163-v200: Creating `HotelRoom` with `data_version: 0`
- **Fix**: Add hotel rooms to `hotels.rb` data pack

**Category 2: Tour Package Creation (4 validators)**
- v257, v260, v261, v265: Creating `TourPackage` with `data_version: 0`
- **Fix**: Add tour packages to `tours.rb` data pack

**Category 3: Attraction Activity Creation (9 validators)**
- v308, v310, v312, v314, v315, v316: Creating `AttractionActivity` with `data_version: 0`
- **Fix**: Add attraction activities to `attractions.rb` data pack

### Why This Matters

**Without this check:**
- Validators silently create baseline data during execution
- Data pack gaps remain hidden
- Test isolation is broken
- Debugging becomes difficult (why does validator A affect validator B?)

**With this check:**
- Forces proper data pack maintenance
- Ensures clean test isolation
- Makes data dependencies explicit
- Prevents cross-validator contamination

## Enforcement

### When Check Runs

Automatically runs as **Step 4.5** in:
```bash
rake validator:simulate          # All validators
rake validator:simulate_single[validator_id]  # Single validator
```

### Blocking Behavior

If violations are detected:
1. ❌ Simulation stops immediately (exit 1)
2. 📋 Lists all violating validators
3. 💡 Shows fix instructions
4. 🔧 Provides code samples

Simulation CANNOT proceed until all violations are fixed.

### Manual Check

```bash
# Check all validators
rake validator:simulate  # Step 4.5 included

# Fix validators, then re-check
# (fix process documented above)
```

## Future Improvements

### Potential Enhancements

1. **Stricter Detection**: Check for more indirect creation patterns
2. **Auto-Fix Tool**: Generate data pack entries from violations
3. **Data Pack Coverage Report**: Which models lack sufficient test data
4. **Dependency Graph**: Visualize validator data dependencies

### Long-term Solution

**Comprehensive Data Pack Validation**:
- Validate data pack completeness before running validators
- Ensure all validators have required foundation data
- Detect gaps early in the data pack loading phase

## Related Documentation

- `docs/DATA_PACK_VALIDATION.md` - Data pack validation system
- `docs/VALIDATOR_LINT_IMPLEMENTATION.md` - Validator static analysis
- `.clackyrules` - Project development rules (updated with this check)

## Summary

✅ **Detection Implemented**: Step 4.5 in `rake validator:simulate`  
❌ **Current Violations**: 35 validators need fixing  
🎯 **Goal**: Zero tolerance for `data_version: 0` creation in simulate methods  
🔧 **Fix**: Update data packs + remove fallback creation patterns  
📈 **Impact**: Cleaner test isolation + explicit data dependencies
