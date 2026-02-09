# v102-v106 验证器联系人断言修复总结

## 修复概述

为以下5个验证器添加了联系人信息验证断言，确保订单中的联系人姓名和电话匹配：

1. **v102_instant_book_chengdu_hotel_this_weekend_validator** - 酒店套餐预订
2. **v103_book_mediterranean_cruise_validator** - 地中海邮轮预订
3. **v104_book_southeast_asia_cruise_validator** - 东南亚邮轮预订
4. **v105_book_caribbean_cruise_validator** - 加勒比邮轮预订
5. **v106_book_cruise_with_preferences_validator** - 日韩邮轮预订（含特殊需求）

## 修复内容

### 1. v102_instant_book_chengdu_hotel_this_weekend_validator

**修改点：**
- 添加断言7：联系人信息正确（张三）- 权重5%
- 调整断言8（原断言7）：订单价格和数量正确 - 权重从10%调整为5%

**联系人验证：**
```ruby
add_assertion "联系人信息正确（张三）", weight: 5 do
  expect(@package_order.passenger&.name).to eq('张三'),
    "联系人姓名错误。期望: 张三, 实际: #{@package_order.passenger&.name}"
end
```

**测试结果：** ✅ PASSED (100/100)

---

### 2. v103_book_mediterranean_cruise_validator

**修改点：**
- 添加`@expected_passenger_names`和`@valid_contact_phones`实例变量
- 添加断言6：联系人信息正确（张三或李四）- 权重10%
- 调整断言7（原断言6）：选择了最近日期的班次 - 权重从15%调整为5%
- 更新`execution_state_data`和`restore_from_state`方法

**联系人验证：**
```ruby
# prepare方法中
@valid_contact_phones = {
  '张三' => @zhangsan.phone,
  '李四' => @lisi.phone
}

# verify方法中
add_assertion "联系人信息正确（张三或李四）", weight: 10 do
  valid_contacts = ['张三', '李四']
  expect(valid_contacts).to include(@order.contact_name),
    "联系人姓名错误。期望: 张三或李四, 实际: #{@order.contact_name}"
  
  expected_phone = @valid_contact_phones[@order.contact_name]
  expect(@order.contact_phone).to eq(expected_phone),
    "联系人电话与姓名不匹配。联系人: #{@order.contact_name}, 期望电话: #{expected_phone}, 实际电话: #{@order.contact_phone}"
end
```

**测试结果：** ✅ PASSED (100/100)

---

### 3. v104_book_southeast_asia_cruise_validator

**修改点：**
- 添加`@expected_passenger_names`和`@valid_contact_phones`实例变量
- 添加断言6：联系人信息正确（王芳或刘强）- 权重10%
- 调整断言7（原断言6）：选择了最近日期的班次 - 权重从15%调整为5%
- 更新`execution_state_data`和`restore_from_state`方法

**联系人验证：**
```ruby
# prepare方法中
@valid_contact_phones = {
  '王芳' => @wangfang.phone,
  '刘强' => @liuqiang.phone
}

# verify方法中
add_assertion "联系人信息正确（王芳或刘强）", weight: 10 do
  valid_contacts = ['王芳', '刘强']
  expect(valid_contacts).to include(@order.contact_name),
    "联系人姓名错误。期望: 王芳或刘强, 实际: #{@order.contact_name}"
  
  expected_phone = @valid_contact_phones[@order.contact_name]
  expect(@order.contact_phone).to eq(expected_phone),
    "联系人电话与姓名不匹配。联系人: #{@order.contact_name}, 期望电话: #{expected_phone}, 实际电话: #{@order.contact_phone}"
end
```

**测试结果：** ✅ PASSED (100/100)

---

### 4. v105_book_caribbean_cruise_validator

**修改点：**
- 更新任务标题和描述：将"赵六、周七"替换为"小明、小红"（数据包中存在的乘客）
- 更新`prepare`方法：查询小明和小红的乘客信息
- 添加`@expected_passenger_names`和`@valid_contact_phones`实例变量
- 添加断言6：联系人信息正确（小明或小红）- 权重10%
- 调整断言7（原断言6）：选择了最近日期的班次 - 权重从15%调整为5%
- 更新`simulate`方法：使用小明和小红创建订单
- 更新`execution_state_data`和`restore_from_state`方法

**联系人验证：**
```ruby
# prepare方法中
@valid_contact_phones = {
  '小明' => @xiaoming.phone,
  '小红' => @xiaohong.phone
}

# verify方法中
add_assertion "联系人信息正确（小明或小红）", weight: 10 do
  valid_contacts = ['小明', '小红']
  expect(valid_contacts).to include(@order.contact_name),
    "联系人姓名错误。期望: 小明或小红, 实际: #{@order.contact_name}"
  
  expected_phone = @valid_contact_phones[@order.contact_name]
  expect(@order.contact_phone).to eq(expected_phone),
    "联系人电话与姓名不匹配。联系人: #{@order.contact_name}, 期望电话: #{expected_phone}, 实际电话: #{@order.contact_phone}"
end
```

**测试结果：** ✅ PASSED (100/100)

---

### 5. v106_book_cruise_with_preferences_validator

**修改点：**
- 更新任务标题和描述：将"孙七、周八"替换为"张建国、陈静"（数据包中存在的乘客）
- 更新`prepare`方法：查询张建国和陈静的乘客信息
- 添加`@expected_passenger_names`和`@valid_contact_phones`实例变量
- 添加断言6：联系人信息正确（张建国或陈静）- 权重10%
- 调整断言7（原断言6）：选择了最近日期的班次 - 权重从10%调整为0%（不计分）
- 更新`simulate`方法：使用张建国和陈静创建订单
- 更新`execution_state_data`和`restore_from_state`方法

**联系人验证：**
```ruby
# prepare方法中
@valid_contact_phones = {
  '张建国' => @zhangjianguo.phone,
  '陈静' => @chenjing.phone
}

# verify方法中
add_assertion "联系人信息正确（张建国或陈静）", weight: 10 do
  valid_contacts = ['张建国', '陈静']
  expect(valid_contacts).to include(@order.contact_name),
    "联系人姓名错误。期望: 张建国或陈静, 实际: #{@order.contact_name}"
  
  expected_phone = @valid_contact_phones[@order.contact_name]
  expect(@order.contact_phone).to eq(expected_phone),
    "联系人电话与姓名不匹配。联系人: #{@order.contact_name}, 期望电话: #{expected_phone}, 实际电话: #{@order.contact_phone}"
end
```

**测试结果：** ✅ PASSED (100/100)

---

## 权重调整总结

### v102（酒店套餐）
- 新增断言7（联系人）：5%
- 断言8（价格数量）：10% → 5%
- 总权重：100%

### v103/v104（邮轮）
- 新增断言6（联系人）：10%
- 断言7（最近班次）：15% → 5%
- 总权重：100%

### v105（加勒比邮轮）
- 新增断言6（联系人）：10%
- 断言7（最近班次）：15% → 5%
- 总权重：100%

### v106（日韩邮轮）
- 新增断言6（联系人）：10%
- 断言7（最近班次）：10% → 0%（不计分）
- 总权重：100%

---

## 数据包依赖

所有验证器使用的乘客数据来自基线数据包（data_version: 0）：

| 验证器 | 乘客1 | 乘客1电话 | 乘客2 | 乘客2电话 |
|--------|-------|-----------|-------|-----------|
| v102 | 张三 | 13800138000 | - | - |
| v103 | 张三 | 13800138000 | 李四 | 13900139000 |
| v104 | 王芳 | 13900139001 | 刘强 | 13700137002 |
| v105 | 小明 | 13200132007 | 小红 | 13100131008 |
| v106 | 张建国 | 13800138001 | 陈静 | 13100131009 |

---

## 实现模式

所有邮轮验证器（v103-v106）遵循统一的联系人验证模式：

1. **prepare阶段**：预查询乘客信息并建立电话映射
2. **verify阶段**：验证联系人姓名在有效列表中，且电话与姓名匹配
3. **state管理**：保存和恢复`@expected_passenger_names`和`@valid_contact_phones`
4. **simulate阶段**：随机选择一个有效联系人创建订单

---

## 测试验证

所有5个验证器已通过`rake validator:simulate_single`测试：

```bash
rake validator:simulate_single[v102_instant_book_chengdu_hotel_this_weekend_validator]  # ✅ PASSED (100/100)
rake validator:simulate_single[v103_book_mediterranean_cruise_validator]                 # ✅ PASSED (100/100)
rake validator:simulate_single[v104_book_southeast_asia_cruise_validator]                # ✅ PASSED (100/100)
rake validator:simulate_single[v105_book_caribbean_cruise_validator]                     # ✅ PASSED (100/100)
rake validator:simulate_single[v106_book_cruise_with_preferences_validator]              # ✅ PASSED (100/100)
```

---

## 总结

本次修复成功为5个验证器添加了联系人信息验证断言，确保：

1. ✅ 联系人姓名在预期乘客列表中
2. ✅ 联系人电话与姓名正确匹配
3. ✅ 权重总和保持100%
4. ✅ 状态管理完整（execution_state_data/restore_from_state）
5. ✅ 所有验证器测试通过

修复参考了v095验证器的实现模式，保持了代码风格的一致性。
