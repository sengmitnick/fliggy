# 数据包关联数据验证功能

## 问题背景

用户报告 `/tour_groups/1074` 没有行程安排（tour_itinerary_days），检查发现数据包中有多个跟团游产品缺少关联数据。

## 解决方案

扩展 `rake validator:validate_data_packs` 任务，增加对关联数据完整性的验证。

### 新增验证功能

在 `lib/data_pack_validator.rb` 中新增 `validate_associations` 方法，检查以下关联：

#### 验证规则

| 模型 | 关联 | 阈值 | 说明 |
|------|------|------|------|
| TourGroupProduct | tour_itinerary_days | 2% | 跟团游产品必须有行程安排 |
| Hotel | hotel_rooms | 5% | 酒店必须有房间信息 |
| Attraction | tickets | 10% | 景点必须有门票信息 |

**阈值说明**：
- 允许一定比例的记录缺少关联（容错）
- 超过阈值：❌ 报错，阻止 `rake validator:reset_baseline`
- 在阈值内：⚠️ 警告，但不阻止任务

### 实现细节

```ruby
def validate_associations(model_class, records)
  # 1. 检查模型是否需要验证关联
  # 2. 检查关联是否存在
  # 3. 统计缺失记录数量和比例
  # 4. 超过阈值报错，否则仅警告
  # 5. 显示前5个缺失记录的示例
end
```

**关键优化**：
- 动态检测模型的显示字段（title 或 name）
- 先计数（不使用 select），再查询示例（使用 select）
- 避免 SQL 错误：`COUNT(id, title)` → 分两步查询

### 使用方法

#### 验证所有数据包
```bash
rake validator:validate_data_packs
```

#### 验证并重置基线数据
```bash
rake validator:reset_baseline
```

### 验证输出示例

**通过（在阈值内）**:
```
✅ tour_groups.rb  - 所有检查通过
  ⚠️  TourGroupProduct 有 16/1074 (1.49%) 条记录缺少行程安排（tour_itinerary_days）（在阈值范围内）
```

**失败（超过阈值）**:
```
❌ tour_groups.rb  - 1 个问题
  → ❌ TourGroupProduct 有 30/1074 (2.8%) 条记录缺少行程安排（tour_itinerary_days）（超过阈值 2.0%）
  →   → 【精品小团】北京环球影城+故宫博物院 2天1晚 (ID: 1074)
  →   → 【精品小团】三亚亚龙湾+呀诺达雨林 6天5晚 (ID: 1070)
  →   → 【精品小团】三亚大小洞天+蜈支洲岛 6天5晚 (ID: 1060)
  →   → 【精品小团】北京故宫+天坛+颐和园 2天1晚 (ID: 1071)
  →   → 【精品小团】三亚蜈支洲岛+南山寺 6天5晚 (ID: 1065)
  →   ... 还有 25 条记录缺失
```

## 当前状态

### TourGroupProduct
- **总记录数**: 1074
- **缺少行程安排**: 16 (1.49%)
- **状态**: ✅ 在阈值内（仅警告）
- **缺失记录ID**: 1060, 1062, 1063, 1064, 1065, 1069, 1070, 1071, 1073, 1074 等

### 后续行动

需要在 `app/validators/support/data_packs/v1/tour_groups.rb` 中补充这16个产品的行程安排数据。

## 配置说明

在 `lib/data_pack_validator.rb` 的 `validate_associations` 方法中修改规则：

```ruby
association_rules = {
  'TourGroupProduct' => {
    association: :tour_itinerary_days,
    required: true,
    threshold: 0.02,  # 调整阈值（当前2%）
    message: '缺少行程安排（tour_itinerary_days）'
  },
  # 添加新的验证规则...
}
```

## 优势

1. **自动化验证** - 每次重置基线数据时自动检查
2. **早期发现问题** - 在数据包加载时就发现关联缺失
3. **具体错误信息** - 显示具体缺失的记录ID和名称
4. **灵活配置** - 可调整阈值和验证规则
5. **容错机制** - 允许少量记录缺失（阈值内）

## 相关文件

- `lib/data_pack_validator.rb` - 验证逻辑
- `lib/tasks/validator.rake` - 任务定义
- `app/validators/support/data_packs/v1/*.rb` - 数据包文件
- `docs/DATA_PACK_VALIDATION.md` - 数据包验证总体文档
