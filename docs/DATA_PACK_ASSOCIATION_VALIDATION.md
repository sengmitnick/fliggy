# 数据包验证增强 - 关联表完整性检查

## 🎯 概述

基于 [VALIDATOR_SIMULATE_VS_REAL_USER.md](VALIDATOR_SIMULATE_VS_REAL_USER.md) 中 V259 问题的分析，我们扩展了 `DataPackValidator` 以自动检测数据包中的关联表缺失问题。

## ❌ 问题背景

**核心问题**：验证器的 `simulate()` 方法可以直接创建订单通过测试，但真实用户却无法完成购买流程。

**原因**：数据包中缺少必需的关联表记录（如 TicketSupplier、HotelRoom 等），导致用户在真实操作流程中遇到空页面。

**示例（V259）**：
- 数据包创建了门票（Ticket ID=37）
- 但没有创建对应的 TicketSupplier 记录
- 用户访问 `/tickets/37/suppliers` 时返回空列表
- 用户无法选择供应商，无法进入下一步购买流程
- 但验证器的 `simulate()` 直接创建了 TicketOrder，测试通过 ✅（误报）

## ✅ 解决方案

### 1. 扩展 DataPackValidator

**文件**：`lib/data_pack_validator.rb`

**新增验证功能**：

#### 1.1 关联表完整性检查（ASSOCIATION_RULES）

定义必需的关联关系并自动检测：

```ruby
ASSOCIATION_RULES = {
  'Ticket' => [
    { 
      association: :ticket_suppliers, 
      model: 'TicketSupplier', 
      required: true,  # 必需关联
      description: '门票必须关联至少1个供应商（用户购买时需选择供应商）',
      min_count: 1,  # 最少关联数量
      check_fields: {  # 关联记录必需字段
        current_price: '供应商价格不能为空', 
        stock: '库存信息必须设置（-1表示无限库存）' 
      }
    }
  ],
  'Hotel' => [
    { 
      association: :hotel_rooms, 
      model: 'HotelRoom', 
      required: true,
      description: '酒店必须关联至少1个房型（用户预订时需选择房型）',
      min_count: 1,
      check_fields: { price: '房型价格不能为空', room_type: '房型类型不能为空' }
    }
  ],
  'Flight' => [
    { 
      association: :flight_offers, 
      model: 'FlightOffer', 
      required: false,  # FlightOffer 不是必需的（可以使用 Flight.price）
      description: '航班可以有多个套餐优惠（非必需，但推荐创建）',
      min_count: 0,
      check_fields: { price: '套餐价格不能为空' }
    }
  ],
  'Attraction' => [
    { 
      association: :tickets, 
      model: 'Ticket', 
      required: false,  # 有些景点可能是免费的
      description: '景点可以有门票（如果 is_free=false 则应该有门票）',
      min_count: 0,
      conditional: ->(record) { !record.is_free }  # 条件检查：仅收费景点要求
    }
  ]
}.freeze
```

**验证逻辑**：
```ruby
def validate_associations(model_class, records)
  # 1. 抽样检查前 5 条记录
  # 2. 检查每条记录是否有必需的关联
  # 3. 检查关联记录的必需字段是否有效
  # 4. 如果缺失，报告错误并提供修复建议
end
```

#### 1.2 业务规则验证（BUSINESS_RULES）

检查关键业务字段的有效性：

```ruby
BUSINESS_RULES = {
  'TicketSupplier' => [
    { field: :current_price, rule: ->(val) { val.present? && val > 0 }, message: 'current_price 必须大于0' },
    { field: :stock, rule: ->(val) { val.present? && (val > 0 || val == -1) }, message: 'stock 必须大于0或为-1（无限库存）' }
  ],
  'HotelRoom' => [
    { field: :price, rule: ->(val) { val.present? && val > 0 }, message: 'price 必须大于0' },
    { field: :room_type, rule: ->(val) { val.present? }, message: 'room_type 不能为空' }
  ],
  'Flight' => [
    { field: :price, rule: ->(val) { val.present? && val > 0 }, message: 'price 必须大于0' },
    { field: :available_seats, rule: ->(val) { val.present? && val >= 0 }, message: 'available_seats 不能为空' }
  ],
  # ... 其他模型
}.freeze
```

**验证逻辑**：
```ruby
def validate_business_rules(model_class, records)
  # 1. 抽样检查前 3 条记录
  # 2. 对每条记录执行业务规则验证
  # 3. 报告违反规则的记录
end
```

### 2. 验证输出示例

#### 成功检测到问题（attractions.rb）

```bash
❌ attractions.rb                 - 5 个问题
  → ❌ Ticket 缺少必需关联 TicketSupplier：2/5 条记录缺失（门票必须关联至少1个供应商（用户购买时需选择供应商））
  →    → 示例: ID=3, 名称=深圳世界之窗成人票, 关联数=0
  →    → 示例: ID=4, 名称=深圳世界之窗儿童票, 关联数=0
  →    💡 修复建议: 在数据包中为 Ticket 创建关联的 TicketSupplier 记录
  →    💡 参考: 查看 app/validators/support/data_packs/v1/attractions.rb 中的 TicketSupplier 创建示例
```

#### 汇总报告

```bash
================================================================================
❌ 数据包验证失败
   - 通过: 30/32 个
   - 失败: 2/32 个

💡 请修复上述问题后重新运行 'rake validator:reset_baseline'
================================================================================
```

### 3. 根本原因分析

**attractions.rb 中的问题**：

```ruby
# ✅ 创建了门票（第 481-509 行）
tickets_data << {
  attraction_id: attractions["深圳世界之窗"].id,
  name: "深圳世界之窗成人票",
  ticket_type: "adult",
  # ...
}

# ❌ 但在后面的供应商关联代码（第 1154+ 行）中没有为这些门票创建 TicketSupplier
# 导致门票无法销售
```

**正确的做法**（参考 attractions.rb 中的深圳欢乐港湾）：

```ruby
# 1. 创建门票
tickets_data << {
  name: "深圳欢乐港湾成人票",
  # ...
}

# 2. 为门票创建供应商关联
ticket = tickets["深圳欢乐港湾_深圳欢乐港湾成人票"]
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["携程旅行"].id,
  current_price: 85,
  stock: 500,
  # ...
}
```

## 📋 验证规则清单

### 必需关联检查

| 主表 | 关联表 | 必需性 | 最少数量 | 说明 |
|------|--------|--------|---------|------|
| Ticket | TicketSupplier | ✅ 必需 | 1 | 用户购买门票时需要选择供应商 |
| Hotel | HotelRoom | ✅ 必需 | 1 | 用户预订酒店时需要选择房型 |
| Flight | FlightOffer | ❌ 可选 | 0 | 航班可以直接使用 Flight.price |
| Attraction | Ticket | ❌ 可选 | 0 | 免费景点（is_free=true）不需要门票 |

### 业务字段检查

| 模型 | 字段 | 规则 | 说明 |
|------|------|------|------|
| TicketSupplier | current_price | > 0 | 供应商价格必须大于0 |
| TicketSupplier | stock | > 0 或 = -1 | 库存必须大于0或为-1（无限库存） |
| HotelRoom | price | > 0 | 房型价格必须大于0 |
| HotelRoom | room_type | present | 房型类型不能为空 |
| Flight | price | > 0 | 航班价格必须大于0 |
| Flight | available_seats | >= 0 | 可用座位数不能为空 |

## 🚀 使用方法

### 1. 运行验证

```bash
# 验证所有数据包（不重新加载）
rake validator:validate_data_packs

# 重置基线数据（包含验证）
rake validator:reset_baseline
```

### 2. 修复数据包

当验证器报告关联缺失时：

1. **定位问题文件**：查看输出中的数据包文件名
2. **查看示例**：参考 `app/validators/support/data_packs/v1/attractions.rb` 中的正确实现
3. **添加关联数据**：在数据包末尾添加关联表的 `insert_all` 代码
4. **重新验证**：运行 `rake validator:reset_baseline`

**示例修复**（为深圳世界之窗添加供应商）：

```ruby
# app/validators/support/data_packs/v1/attractions.rb
# 在文件末尾添加（第 1154+ 行附近）

# 深圳世界之窗成人票 - 3个供应商
ticket = Ticket.joins(:attraction).find_by(
  attractions: { name: "深圳世界之窗" },
  ticket_type: "adult",
  data_version: 0
)

if ticket
  ticket_suppliers_data << {
    ticket_id: ticket.id,
    supplier_id: suppliers["携程旅行"].id,
    current_price: 170,
    original_price: 220,
    stock: 300,
    discount_info: "早鸟优惠",
    sales_count: 2580,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # ... 添加其他供应商 ...
end

# 深圳世界之窗儿童票 - 3个供应商
ticket = Ticket.joins(:attraction).find_by(
  attractions: { name: "深圳世界之窗" },
  ticket_type: "child",
  data_version: 0
)

if ticket
  ticket_suppliers_data << {
    ticket_id: ticket.id,
    supplier_id: suppliers["携程旅行"].id,
    current_price: 85,
    original_price: 110,
    stock: 200,
    discount_info: "儿童特惠",
    sales_count: 1280,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # ... 添加其他供应商 ...
end
```

## 🎯 预期效果

### 修复前

- ✅ 验证器测试通过（误报）
- ❌ 真实用户无法购买（访问供应商页面为空）

### 修复后

- ✅ 验证器测试通过
- ✅ 真实用户可以正常购买（可以选择供应商）

## 📚 相关文档

- [VALIDATOR_SIMULATE_VS_REAL_USER.md](VALIDATOR_SIMULATE_VS_REAL_USER.md) - V259 问题详细分析
- [DATA_PACK_VALIDATION.md](DATA_PACK_VALIDATION.md) - 数据包验证功能设计
- [.clackyrules](.clackyrules#data-packs) - 数据包文件组织规则

## 🏷️ 标签

`data-pack` `validation` `association` `business-rules` `v259-fix` `ticket-supplier` `hotel-room`

---

**总结**：通过扩展 `DataPackValidator` 添加关联表完整性检查和业务规则验证，我们可以在数据加载阶段就发现类似 V259 的问题，确保验证器测试通过 = 用户真实可用。
