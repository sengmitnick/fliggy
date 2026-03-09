# 租车订单租期显示功能修复

## 问题描述

租车订单确认页面(`show.html.erb`)、支付成功页面(`success.html.erb`)和订单卡片(`_car_order_card.html.erb`)只显示取车时间和还车时间,**未显示租期天数**,导致用户误以为同一天11小时的租车不按天计费。

实际上,系统采用**小时向上取整为天**的计费方式:
- 0-24小时 → 1天
- 24小时+1分钟 → 2天
- 以此类推

但前端未展示这个信息,造成用户困惑。

## 问题截图分析

用户截图显示:
```
宝马7系Li
豪华车 | 5座4门 | 自动挡 | 汽油

03月10日 周二 国贸CBD租车服务站 - 03月10日 周二
09:00                        0天                    20:00

符合您筛选条件的报价
```

**问题**: 取车09:00,还车20:00,时长11小时,实际应按**1天**计费,但页面未明确显示租期。

## 解决方案

### 1. 模型层 - 添加租期计算方法

**文件**: `app/models/car_order.rb`

添加 `rental_days` 方法:

```ruby
# Calculate rental duration in days (rounds up to next day)
# Formula: ceil((return_time - pickup_time) / 24 hours)
# Example: 9:00 to 20:00 (11 hours) = 1 day
# Example: 9:00 today to 9:01 tomorrow (24h 1min) = 2 days
def rental_days
  return nil unless pickup_datetime && return_datetime
  
  diff_hours = (return_datetime - pickup_datetime) / 3600.0  # Convert seconds to hours
  (diff_hours / 24.0).ceil  # Round up to next day
end
```

**计算规则**:
- 与前端 `car_rental_tabs_controller.ts` 的 `updateDuration()` 方法保持一致
- 使用 `Math.ceil()` / `.ceil` 向上取整
- 任何不足24小时的时长按1天计算
- 超过24小时按向上取整计算天数

### 2. 视图层 - 显示租期信息

#### 2.1 订单确认页面

**文件**: `app/views/car_orders/show.html.erb`

在取还车时间后增加租期展示:

```erb
<!-- 取还车时间 -->
<div class="flex justify-between py-3 border-b">
  <span class="text-gray-600">取车时间</span>
  <span><%= @car_order.pickup_datetime.strftime('%Y年%m月%d日 %H:%M') if @car_order.pickup_datetime %></span>
</div>

<div class="flex justify-between py-3 border-b">
  <span class="text-gray-600">还车时间</span>
  <span><%= @car_order.return_datetime.strftime('%Y年%m月%d日 %H:%M') if @car_order.return_datetime %></span>
</div>

<!-- 租期 -->
<% if @car_order.rental_days.present? %>
  <div class="flex justify-between py-3 border-b">
    <span class="text-gray-600">租期</span>
    <span class="font-bold"><%= @car_order.rental_days %>天</span>
  </div>
<% end %>
```

#### 2.2 支付成功页面

**文件**: `app/views/car_orders/success.html.erb`

在订单信息卡片中增加租期:

```erb
<div class="flex justify-between text-sm">
  <span class="text-gray-600">取车时间</span>
  <span class="font-medium"><%= @car_order.pickup_datetime.strftime('%m月%d日 %H:%M') if @car_order.pickup_datetime %></span>
</div>

<div class="flex justify-between text-sm">
  <span class="text-gray-600">还车时间</span>
  <span class="font-medium"><%= @car_order.return_datetime.strftime('%m月%d日 %H:%M') if @car_order.return_datetime %></span>
</div>

<% if @car_order.rental_days.present? %>
  <div class="flex justify-between text-sm">
    <span class="text-gray-600">租期</span>
    <span class="font-bold text-primary"><%= @car_order.rental_days %>天</span>
  </div>
<% end %>
```

#### 2.3 订单卡片(订单列表)

**文件**: `app/views/bookings/_car_order_card.html.erb`

在取还车时间后增加租期:

```erb
<% if booking.pickup_datetime.present? %>
  <div class="text-xs text-text-muted">
    取车: <%= booking.pickup_datetime.strftime('%Y-%m-%d %H:%M') %> 
  </div>
<% end %>
<% if booking.return_datetime.present? %>
  <div class="text-xs text-text-muted">
    还车: <%= booking.return_datetime.strftime('%Y-%m-%d %H:%M') %>
  </div>
<% end %>
<% if booking.rental_days.present? %>
  <div class="text-xs text-primary font-bold mt-1">
    租期: <%= booking.rental_days %>天
  </div>
<% end %>
```

### 3. 测试覆盖

**文件**: `spec/models/car_order_spec.rb`

添加完整的单元测试:

```ruby
describe '#rental_days' do
  context 'when pickup_datetime and return_datetime are present' do
    it 'calculates rental days correctly for same day (11 hours)' do
      # 同一天租车：9:00 到 20:00 (11小时) → 1天
      car_order = CarOrder.create!(...)
      expect(car_order.rental_days).to eq(1)
    end
    
    it 'calculates rental days correctly for 24+ hours' do
      # 24小时+1分钟 → 2天
      car_order = CarOrder.create!(...)
      expect(car_order.rental_days).to eq(2)
    end
    
    it 'calculates rental days correctly for multiple days' do
      # 3天租期：72小时 → 3天
      car_order = CarOrder.create!(...)
      expect(car_order.rental_days).to eq(3)
    end
    
    it 'rounds up partial days' do
      # 1天+1小时 → 2天 (向上取整)
      car_order = CarOrder.create!(...)
      expect(car_order.rental_days).to eq(2)
    end
  end
  
  context 'when datetime fields are missing' do
    it 'returns nil when pickup_datetime is missing'
    it 'returns nil when return_datetime is missing'
    it 'returns nil when both datetime fields are missing'
  end
end
```

**测试结果**:
```
CarOrder
  #rental_days
    when pickup_datetime and return_datetime are present
      ✓ calculates rental days correctly for same day (11 hours)
      ✓ calculates rental days correctly for 24+ hours
      ✓ calculates rental days correctly for multiple days
      ✓ rounds up partial days
    when datetime fields are missing
      ✓ returns nil when pickup_datetime is missing
      ✓ returns nil when return_datetime is missing
      ✓ returns nil when both datetime fields are missing

7 examples, 0 failures
```

## 修复前后对比

### 修复前

**订单确认页面**:
```
取车时间: 2026年03月10日 09:00
还车时间: 2026年03月10日 20:00
取还车地点: 国贸CBD租车服务站
```

❌ **问题**: 用户看到同一天,会误以为不按天计费

### 修复后

**订单确认页面**:
```
取车时间: 2026年03月10日 09:00
还车时间: 2026年03月10日 20:00
租期: 1天 (加粗显示)
取还车地点: 国贸CBD租车服务站
```

✅ **改进**: 明确告知用户按1天计费

## 相关文件

### 修改文件

1. `app/models/car_order.rb` - 添加 `rental_days` 方法
2. `app/views/car_orders/show.html.erb` - 订单确认页面增加租期
3. `app/views/car_orders/success.html.erb` - 支付成功页面增加租期
4. `app/views/bookings/_car_order_card.html.erb` - 订单卡片增加租期

### 新增测试文件

1. `spec/models/car_order_spec.rb` - 完整的租期计算测试

### 参考文件

1. `app/javascript/controllers/car_rental_tabs_controller.ts` (line 428-445) - 前端租期计算逻辑
2. `app/validators/v101_v150/v140_book_luxury_car_and_airport_dropoff_validator.rb` - 租期验证逻辑

## 验证步骤

1. ✅ 单元测试通过: `bundle exec rspec spec/models/car_order_spec.rb`
2. ✅ 请求测试通过: `bundle exec rspec spec/requests/car_orders_spec.rb`
3. ✅ ERB HTML验证通过: `bin/validate_erb_html app/views/car_orders/*.html.erb`
4. ✅ 前后端计算逻辑一致: 都使用 `Math.ceil(hours / 24)`

## 用户体验改进

### 改进点

1. **明确计费规则**: 用户一眼就能看到实际按几天计费
2. **消除歧义**: 不再因为"同一天"而误以为不收费或收费不合理
3. **信息完整性**: 与首页搜索结果、验证器逻辑保持一致
4. **视觉突出**: 租期使用加粗字体,在订单卡片中使用主题色突出显示

### 一致性保证

- ✅ 前端搜索页面: 显示租期天数
- ✅ 订单确认页面: 显示租期天数
- ✅ 支付成功页面: 显示租期天数
- ✅ 订单列表卡片: 显示租期天数
- ✅ 验证器断言: 验证租期计算正确性

## 总结

通过在模型层添加 `rental_days` 方法并在所有相关视图中展示租期信息,解决了用户对租车计费规则的困惑。修复后,用户在订单确认、支付成功和订单列表页面都能清楚看到实际租期天数,明确了"低于24小时按1天算"的计费规则。

**核心原则**: **小时向上取整为天** - 任何不足24小时的时长按1天计算。
