# 租车租期计算修复文档

## 问题描述

用户报告租车详情页（`cars/show.html.erb`）显示租期为"0天"，即使选择的是同一天的时间段（例如：03月09日 13:55 到 03月09日 23:00，共9小时）。

### 用户截图分析
- 取车时间：03月09日 周 — 13:55
- 还车时间：03月09日 周 — 23:00
- 实际租期：9小时（应按1天计算）
- 显示结果：**0天**（错误）

## 根本原因

在 `app/views/cars/show.html.erb` 第62-70行，租期计算使用了简单的**日期相减**逻辑：

```ruby
# ❌ 错误的计算方式
pickup_date = Date.parse(@search_params[:pickup_date])
return_date = Date.parse(@search_params[:return_date])
days_count = (return_date - pickup_date).to_i  # 只计算日期差，不考虑具体时间
```

**问题**：
- 同一天的时间段（如 09:00-20:00），日期差 = 0
- 不符合租车行业"不足24小时按1天计算"的规则
- 与后端 `CarOrder#rental_days` 方法逻辑不一致

## 修复方案

### 1. 更新视图层计算逻辑

修改 `app/views/cars/show.html.erb`，使用与 `CarOrder` 模型相同的计算公式：

```ruby
# ✅ 正确的计算方式（向上取整）
pickup_datetime = Time.zone.parse("#{pickup_date} #{pickup_time}")
return_datetime = Time.zone.parse("#{return_date} #{return_time}")
diff_hours = (return_datetime - pickup_datetime) / 3600.0
days_count = (diff_hours / 24.0).ceil  # 向上取整
```

**计算规则**：
- 公式：`ceil((还车时间 - 取车时间) / 24小时)`
- 示例1：同一天 13:55-23:00（9小时）→ ceil(9/24) = **1天**
- 示例2：跨天 09:00-次日 09:01（24小时1分钟）→ ceil(24.016/24) = **2天**
- 示例3：3天整 09:00-第4天 09:00（72小时）→ ceil(72/24) = **3天**

### 2. 代码变更

**文件**：`app/views/cars/show.html.erb`  
**位置**：第62-70行

```diff
  <% 
    pickup_date = @search_params[:pickup_date].present? ? Date.parse(@search_params[:pickup_date]) : Date.today
    return_date = @search_params[:return_date].present? ? Date.parse(@search_params[:return_date]) : (Date.today + 2.days)
    pickup_time = @search_params[:pickup_time].presence || '10:00'
    return_time = @search_params[:return_time].presence || '10:00'
-   days_count = (return_date - pickup_date).to_i
+   
+   # Calculate rental days using same logic as CarOrder model (rounds up)
+   # Formula: ceil((return_datetime - pickup_datetime) / 24 hours)
+   # Example: Same day 13:55 to 23:00 (9 hours) = 1 day
+   pickup_datetime = Time.zone.parse("#{pickup_date} #{pickup_time}")
+   return_datetime = Time.zone.parse("#{return_date} #{return_time}")
+   diff_hours = (return_datetime - pickup_datetime) / 3600.0
+   days_count = (diff_hours / 24.0).ceil
+   
    pickup_location = @search_params[:pickup_location].presence || '天河国际机场T3'
    weekday_names = ['日', '一', '二', '三', '四', '五', '六']
  %>
```

## 验证结果

### 1. 单元测试（已存在）

`spec/models/car_order_spec.rb` 中已有 7 个测试用例覆盖所有场景：

```bash
$ bundle exec rspec spec/models/car_order_spec.rb

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

### 2. 实际页面测试

```bash
# 测试同一天租期（9小时）
$ curl -s 'http://localhost:3000/cars/1?pickup_date=2026-03-09&return_date=2026-03-09&pickup_time=13:55&return_time=23:00' \
  | grep -A 2 -B 2 '天</div>'

# 输出结果：
<div class="px-2 text-xs text-gray-400 whitespace-nowrap">1天</div>  ✅
```

**修复前**：显示 `0天`  
**修复后**：显示 `1天`

## 技术要点

### 1. 视图层与模型层逻辑一致性

- **模型层**（`CarOrder#rental_days`）：已实现正确的向上取整逻辑
- **视图层**（`cars/show.html.erb`）：现在使用相同的计算公式
- **好处**：保证前端展示与后端订单数据的租期计算完全一致

### 2. 租车行业标准规则

- **24小时制**：按实际小时数计算，向上取整到天
- **不足24小时按1天**：任何小于24小时的租期都算作1天
- **跨天逻辑**：从 Day 1 10:00 到 Day 2 10:01 = 2天（超过24小时即算2天）

### 3. 时区处理

使用 `Time.zone.parse` 确保时区正确处理：
```ruby
pickup_datetime = Time.zone.parse("#{pickup_date} #{pickup_time}")  # 使用 Rails 配置的时区
```

## 影响范围

### 修改的文件
- `app/views/cars/show.html.erb` - 租车详情页视图

### 不需要修改的文件
- `app/models/car_order.rb` - 模型层已经实现正确逻辑
- `app/views/car_orders/*.html.erb` - 订单页面使用模型方法，无需修改
- `app/javascript/controllers/car_rental_tabs_controller.ts` - 前端控制器已有正确逻辑

## 相关文档

- [租车订单租期显示修复](./CAR_ORDER_RENTAL_DAYS_DISPLAY_FIX.md) - 订单确认页面的租期显示修复
- `app/models/car_order.rb` - `rental_days` 方法实现
- `spec/models/car_order_spec.rb` - 租期计算测试用例

## 总结

**问题**：租车详情页使用日期相减导致同一天租期显示为 0 天  
**修复**：改用小时级别计算并向上取整，与后端模型逻辑保持一致  
**效果**：同一天 9 小时租期正确显示为 1 天  
**验证**：所有单元测试通过，实际页面渲染正确
