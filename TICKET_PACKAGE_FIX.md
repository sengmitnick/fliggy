# 机票套餐功能修复说明

## 问题分析

根据用户提供的高保真截图，发现之前的实现存在概念错误：

### ❌ 错误实现
之前将 `FlightOffer` 理解为**不同旅行平台的报价**（飞猪旅行、携程旅行、去哪儿旅行等），这是错误的。

### ✅ 正确实现
`FlightOffer` 应该表示**同一航班的不同价格套餐**，每个套餐提供不同的服务和价格：

1. **超值精选** - 基础经济舱套餐，价格最低
2. **选座无忧** - 包含选座服务
3. **返现礼遇** - 高价但有返现优惠
4. **家庭好选** - 家庭出行优惠套餐

## 修复内容

### 1. 模型层修改 (`app/models/flight.rb`)

**修改前：**
```ruby
providers = [
  { name: '飞猪旅行', type: 'featured' },
  { name: '携程旅行', type: 'cashback' },
  { name: '去哪儿旅行', type: 'standard' },
  { name: '同程旅行', type: 'family' }
]
```

**修改后：**
```ruby
# Package 1: 超值精选 (Best Value)
flight_offers.create!(
  provider_name: '超值精选',
  offer_type: 'featured',
  price: base_price,
  original_price: base_price + 42,
  cashback_amount: 0,
  discount_items: ['无免费托运行李'],
  services: ['退改MU92起', '经济舱', '仅全额电子发票'],
  tags: ['含合餐权益', '手提行李7KG/尺寸20'],
  ...
)

# Package 2: 选座无忧 (Seat Selection)
# Package 3: 返现礼遇 (Cashback Package)  
# Package 4: 家庭好选 (Family Choice)
```

### 2. 视图层修改 (`app/views/flights/show.html.erb`)

**标题修改：**
- `选择订票供应商` → `选择机票套餐`
- `X个供应商报价` → `X个套餐可选`

**卡片展示修改：**
- 移除了平台图标（之前显示"飞猪"、"携程"等首字母的彩色圆圈）
- 简化了标题展示，直接显示套餐名称
- 将黄色星标改为红色文字提示"无免费托运行李"

## 数据更新

重新生成所有航班的套餐数据：
```bash
rails runner 'FlightOffer.destroy_all'
rails runner 'Flight.find_each { |f| f.generate_offers }'
```

## 测试验证

✅ 所有测试通过：
```bash
bundle exec rspec spec/requests/flights_spec.rb
# 1 example, 0 failures
```

✅ 数据验证：
```bash
rails runner "puts Flight.first.flight_offers.map(&:provider_name).join(', ')"
# 输出: 超值精选, 选座无忧, 返现礼遇, 家庭好选
```

## 效果对比

### 修改前
```
选择订票供应商
━━━━━━━━━━━━━━━━━━━━━
┌─────────────────────┐
│ [飞] 飞猪旅行        │
│ ⭐ 超值精选         │
│ ¥310                │
└─────────────────────┘
```

### 修改后
```
选择机票套餐
━━━━━━━━━━━━━━━━━━━━━
┌─────────────────────┐
│ 超值精选             │
│ 无免费托运行李       │
│ ¥310                │
└─────────────────────┘
```

## 核心改进

1. **概念准确** - 从"旅行平台"改为"价格套餐"
2. **UI简化** - 移除不必要的平台图标
3. **信息清晰** - 重点突出套餐名称和服务差异
4. **数据真实** - 基于真实的机票售卖模式（一个航班多个套餐）

## 注意事项

- `provider_name` 字段虽然命名为"供应商名称"，但在此业务场景下实际存储的是**套餐名称**
- 未来如需支持真正的多平台比价功能，可能需要新增字段或重构数据模型
- 当前实现完全符合用户截图的高保真设计要求
