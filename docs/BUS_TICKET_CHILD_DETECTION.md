# 汽车票订单 - 儿童票自动识别功能

## 功能说明

在汽车票订单页面，系统会根据乘客的身份证号自动计算年龄，并显示相应的票种标签。

### 规则

- **儿童票**：12周岁以下（不含12周岁）
- **成人票**：12周岁及以上

### 视觉效果

- **儿童票标签**：橙色背景 + 橙色文字 + 橙色边框
- **成人票标签**：灰色文字 + 灰色边框

## 技术实现

### 1. Passenger 模型新增方法

**文件**：`app/models/passenger.rb`

```ruby
# 根据身份证号计算年龄
def age
  return nil unless id_type == '身份证' && id_number.present?
  
  # 从身份证号提取出生日期（第7-14位：YYYYMMDD）
  birth_year = id_number[6..9].to_i
  birth_month = id_number[10..11].to_i
  birth_day = id_number[12..13].to_i
  
  birth_date = Date.new(birth_year, birth_month, birth_day)
  today = Date.current
  
  # 计算周岁
  age = today.year - birth_date.year
  age -= 1 if today.month < birth_date.month || (today.month == birth_date.month && today.day < birth_date.day)
  
  age
rescue ArgumentError
  nil  # 无效日期返回 nil
end

# 判断是否为儿童票（12周岁以下）
def child_ticket?
  age_value = age
  age_value.present? && age_value < 12
end

# 获取票种标签文本
def ticket_type_label
  child_ticket? ? '儿童票' : '成人票'
end
```

### 2. 视图模板更新

**文件**：`app/views/bus_ticket_orders/new.html.erb`

**修改前**（第111行）：
```erb
<span class="text-[10px] text-gray-500 border border-gray-300 rounded px-1 py-[1px]">成人票</span>
```

**修改后**（第111行）：
```erb
<span class="text-[10px] <%= passenger.child_ticket? ? 'text-orange-600 border-orange-300 bg-orange-50' : 'text-gray-500 border-gray-300' %> border rounded px-1 py-[1px]">
  <%= passenger.ticket_type_label %>
</span>
```

### 3. 测试覆盖

**文件**：`spec/models/passenger_spec.rb`

测试覆盖了以下场景：
- 成人年龄计算（1990年出生，36岁）
- 儿童年龄计算（2015年出生，9岁 / 2018年出生，6岁）
- 无效身份证号处理
- 非身份证证件类型处理
- 儿童票判断逻辑
- 票种标签文本生成

**运行测试**：
```bash
bundle exec rspec spec/models/passenger_spec.rb
```

所有测试通过 ✅

## Demo 用户数据

**文件**：`app/validators/support/data_packs/v1/demo_user.rb`

系统内置的 demo 用户包含以下乘客：

| 姓名 | 身份证号 | 出生年份 | 年龄 | 票种 |
|------|---------|---------|------|------|
| 张三 | 110101199001011234 | 1990 | 36岁 | 成人票 |
| 李四 | 110101199002022345 | 1990 | 36岁 | 成人票 |
| 王芳 | 110101198506153456 | 1985 | 39岁 | 成人票 |
| 刘强 | 110101198803214567 | 1988 | 36岁 | 成人票 |
| **小明** | 110101201507085678 | 2015 | **9岁** | **儿童票** ⭐ |
| **小红** | 110101201808126789 | 2018 | **6岁** | **儿童票** ⭐ |

## 验证方法

### 命令行验证

```bash
rails runner "passenger = Passenger.find_by(name: '小明'); puts \"小明 - 年龄: #{passenger.age}岁, 票种: #{passenger.ticket_type_label}\""
```

输出：
```
小明 - 年龄: 10岁, 票种: 儿童票
```

### 浏览器验证

1. 访问汽车票订单页面：`/bus_ticket_orders/new?bus_ticket_id=<id>`
2. 查看乘客列表，"小明"和"小红"应显示橙色的"儿童票"标签
3. 其他成人乘客显示灰色的"成人票"标签

## 注意事项

1. **身份证号要求**：只对"身份证"类型的证件计算年龄，护照等其他证件类型默认显示"成人票"
2. **年龄边界**：12周岁当天起算成人票（12周岁生日当天开始为成人）
3. **无效身份证号**：如果身份证号格式错误或日期无效，返回 `nil`，默认显示"成人票"
4. **其他业务场景**：此功能目前仅应用于汽车票订单页面，机票和景点门票有各自的票种处理逻辑

## 相关文件

- 模型：`app/models/passenger.rb`
- 视图：`app/views/bus_ticket_orders/new.html.erb`（第85-144行）
- Stimulus 控制器：`app/javascript/controllers/bus_ticket_order_controller.ts`
- 测试：`spec/models/passenger_spec.rb`
- 数据包：`app/validators/support/data_packs/v1/demo_user.rb`

## 修复记录

### 问题1：儿童票标签固定显示“成人票”

**问题描述**：所有乘客都显示固定的“成人票”标签，无法区分儿童和成人

**解决方案**：
1. 在 `Passenger` 模型中添加 `age`、`child_ticket?`、`ticket_type_label` 方法
2. 根据身份证号计算年龄，12周岁以下为儿童票
3. 视图中动态显示票种标签，儿童票显示橙色样式

**提交日期**：2025-01-XX

### 问题2：只显示前5个乘客，导致第6个乘客（小红）不可见

**问题描述**：视图使用 `@passengers.first(5).each` 只显示前5个乘客，导致 demo 用户的第6个乘客（小红）无法显示

**原代码**（第94行）：
```erb
<% @passengers.first(5).each do |passenger| %>
```

**修复后**（第94行）：
```erb
<% @passengers.each do |passenger| %>
```

**逺辑说明**：
- 显示所有乘客，让用户可以看到完整的乘客列表
- “最多选择5人”的限制由 Stimulus 控制器处理（`bus_ticket_order_controller.ts` 第76-80行）
- 当用户尝试选择第6人时，会弹出提示：“最多只能选择5位乘车人”

**提交日期**：2025-01-XX
