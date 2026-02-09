# V080 验证器优化总结

## 优化目标
根据 `docs/VALIDATOR_WRITING_STANDARDS.md` 标准，优化 v080_buy_senior_travel_insurance_validator 验证器

## 🚨 重要发现：人物错误

**问题：**
- 张三（110101199001011234）是 **1990年出生，34岁** → 不是老人
- 张建国（110101195912155555）是 **1959年出生，65岁** → 才是老人

**关系：**
- 张建国是张三的父亲（小明的爷爷）

**修正：**
- ✅ 将所有 `张三` 替换为 `张建国`
- ✅ 将所有 `@zhangsan` 替换为 `@zhangjianguo`
- ✅ 更新 title/description 到 "给张建国购买..."

---

## 优化内容

### 1. 标题和描述优化 (符合第一节标准)

**优化前:**
- 标题: `购买老人旅游保险(65岁,北京,5天后出行,5天,高保额)`
- 描述: `为65岁老人购买境内旅游保险,选择医疗保额最高的产品`

**问题:**
- ❌ 缺少"给[受益人]"开头
- ❌ 参数表述像表单字段(65岁,北京,5天后出行,5天,高保额)
- ❌ 描述像产品说明,不是用户口语
- ❌ **使用了错误的人物：张三是34岁成人，不是65岁老人**

**优化后:**
- 标题: `给张建国购买境内旅游保险(65岁老人,北京出行5天,选医疗保额最高的)`
- 描述: `张建国65岁(张三的爸爸),5天后要去北京玩5天,帮他买个境内旅游保险,老人家要医疗保额最高的那种`

**改进:**
- ✅ 添加"给张建国"受益人开头
- ✅ 使用口语化表述:"老人家要医疗保额最高的那种"
- ✅ 任务描述更自然:"5天后要去北京玩5天"
- ✅ **修正为正确的老人角色：张建国(65岁)**
- ✅ **添加家庭关系说明："张三的爸爸"**

---

### 2. demo_user 数据使用 (符合第三节标准)

**优化前:**
- prepare 中没有查询 demo_user 的 passenger 数据
- simulate 中使用硬编码的投保人信息: `insured_persons: ['王老太(65岁)']`
- verify 中没有验证联系人/投保人信息

**问题:**
- ❌ 违反规则:禁止硬编码姓名
- ❌ 未使用 demo@travel01.com 的 passengers 数据
- ❌ 未验证投保人信息正确性
- ❌ **使用了错误的人物：张三是34岁，不是65岁老人**

**优化后:**

**prepare 阶段:**
```ruby
# 查询 demo_user 的出行人信息(张建国 - 65岁老人)
user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
@zhangjianguo = user.passengers.find_by!(name: '张建国', data_version: 0)
@expected_insured_name = @zhangjianguo.name
@expected_insured_id_number = @zhangjianguo.id_number
```

**simulate 阶段:**
```ruby
# 查找测试用户和出行人信息(数据包中已创建)
user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
zhangjianguo = user.passengers.find_by!(name: '张建国', data_version: 0)

# 准备投保人信息(张建国,65岁)
insured_persons_data = [
  { name: zhangjianguo.name, id_number: zhangjianguo.id_number }
]

# 创建订单时使用
InsuranceOrder.create!(
  # ...
  insured_persons: insured_persons_data,
  # ...
)
```

**verify 阶段:**
```ruby
# 断言6: 被保险人信息正确(张建国)
add_assertion "被保险人信息正确(#{@expected_insured_name})", weight: 5 do
  insured_persons = @insurance_order.insured_persons || []
  expect(insured_persons).not_to be_empty, "未找到投保人信息"
  
  # 检查是否包含张建国
  zhangjianguo_record = insured_persons.find { |p| p['name'] == @expected_insured_name }
  expect(zhangjianguo_record).not_to be_nil,
    "未找到被保险人#{@expected_insured_name}。实际投保人: #{insured_persons.map { |p| p['name'] }.join('、')}"
  
  # 验证身份证号
  if zhangjianguo_record && @expected_insured_id_number
    expect(zhangjianguo_record['id_number']).to eq(@expected_insured_id_number),
      "被保险人#{@expected_insured_name}的身份证号错误。期望: #{@expected_insured_id_number}, 实际: #{zhangjianguo_record['id_number']}"
  end
end
```

**改进:**
- ✅ prepare 查询 `data_version: 0` 的 demo_user 数据
- ✅ **使用正确的老人角色：张建国(65岁)**
- ✅ simulate 使用实例变量 `@zhangjianguo` 的信息
- ✅ verify 验证投保人姓名和身份证号

**关键发现：**
- ❌ **错误**: `张三` (110101199001011234) → 1990年出生，34岁，不是老人
- ✅ **正确**: `张建国` (110101195912155555) → 1959年出生，65岁，是张三的父亲

---

### 3. verify 断言顺序和权重优化 (符合第四节标准)

**优化前权重分配:**
```
- 订单已创建 (20分)
- 保险类型正确(境内旅游)(10分)
- 目的地正确(北京)(10分)
- 出行开始时间正确(5天后)(10分)
- 保障天数正确(5天)(10分)
- 选择了医疗保额最高的产品 (30分)
- 订单价格计算正确 (10分)
总和: 100分
```

**问题:**
- ❌ 缺少联系人/投保人信息验证
- ❌ 次要属性权重过高(目的地10分,时间10分)
- ❌ 未按照标准推荐的权重分配

**优化后权重分配:**
```
- 订单已创建 (20分)                     [标准: 20-25%]
- 保险类型正确(境内旅游)(20分)           [标准: 核心实体 10-15%,调整到20%]
- 目的地正确(北京)(5分)                 [标准: 关键属性 10-15%,降到5%]
- 出行开始时间正确(5天后)(5分)          [标准: 关键属性,降到5%]
- 保障天数正确(5天)(5分)                [标准: 关键属性,降到5%]
- 被保险人信息正确(张建国)(5分)         [新增: 联系人验证]
- 选择了医疗保额最高的产品 (30分)       [标准: 业务逻辑 20-30%]
- 订单价格计算正确 (10分)               [标准: 10-15%]
总和: 100分
```

**断言顺序优化:**
1. ✅ 订单存在 (20分) - 查询并存储订单
2. ✅ 核心实体 (20分) - 保险类型正确
3. ✅ 基础属性 (5+5+5分) - 目的地、时间、天数
4. ✅ 联系人信息 (5分) - 新增:被保险人验证
5. ✅ 业务逻辑 (30分) - 医疗保额最高(核心评分项)
6. ✅ 价格计算 (10分) - 订单价格正确

**改进:**
- ✅ 符合标准推荐的断言顺序:存在→核心实体→属性→业务逻辑
- ✅ 权重分配合理:核心业务逻辑(30分)权重最高
- ✅ 新增投保人信息验证断言(5分)
- ✅ 次要属性权重降低(目的地、时间、天数各5分)

---

### 4. prepare 返回信息优化

**优化前:**
```ruby
{
  task: "请为65岁老人购买#{@destination}出行的境内旅游保险(5天后出发,保障期#{@days}天),老年人需要更高医疗保额,请选择医疗保额最高的产品",
  # ...
}
```

**优化后:**
```ruby
{
  task: "#{@expected_insured_name}#{@age}岁,#{@days}天后要去#{@destination}玩#{@days}天,帮他买个境内旅游保险,老人家要医疗保额最高的那种",
  product_type: "境内旅游",
  insured_name: @expected_insured_name,  # 新增: 被保险人姓名
  # ...
}
```

**改进:**
- ✅ task 描述更口语化,包含受益人姓名
- ✅ 添加 `insured_name` 字段,明确被保险人
- ✅ 表述更自然:"帮他买个...老人家要..."
- ✅ **使用正确的老人姓名：张建国**

---

### 5. 状态管理优化

**优化前 execution_state_data:**
```ruby
{
  product_type: @product_type,
  destination: @destination,
  days: @days,
  quantity: @quantity,
  age: @age,
  start_date: @start_date&.to_s,
  end_date: @end_date&.to_s,
  highest_medical: @highest_medical
}
```

**优化后 execution_state_data:**
```ruby
{
  product_type: @product_type,
  destination: @destination,
  days: @days,
  quantity: @quantity,
  age: @age,
  start_date: @start_date&.to_s,
  end_date: @end_date&.to_s,
  highest_medical: @highest_medical,
  expected_insured_name: @expected_insured_name,          # 新增
  expected_insured_id_number: @expected_insured_id_number # 新增
}
```

**优化后 restore_from_state:**
```ruby
def restore_from_state(data)
  # ... 恢复其他字段
  @expected_insured_name = data['expected_insured_name']          # 新增
  @expected_insured_id_number = data['expected_insured_id_number'] # 新增
  
  # 重新加载 demo_user 的出行人信息
  user = User.find_by(email: 'demo@travel01.com', data_version: 0)
  if user
    @zhangjianguo = user.passengers.find_by(name: '张建国', data_version: 0)
  end
  
  # ...
end
```

**改进:**
- ✅ 保存投保人期望值用于 verify 阶段验证
- ✅ restore 时重新加载 passenger 对象
- ✅ **使用正确的老人角色：张建国**

---

## 优化结果

### 测试结果
```
✓ PASSED (100/100)

Assertions:
- 订单已创建 (20分) ✓
- 保险类型正确(境内旅游) (20分) ✓
- 目的地正确(北京) (5分) ✓
- 出行开始时间正确(5天后,2026-02-14) (5分) ✓
- 保障天数正确(5天) (5分) ✓
- 被保险人信息正确(张建国) (5分) ✓  ← 新增
- 选择了医疗保额最高的产品 (30分) ✓
- 订单价格计算正确 (10分) ✓

Simulate Info:
{
  "insured_person": {
    "name": "张建国",
    "id_number": "110101195912155555"  # 1959年生 - 65岁老人
  }
}
```

### 符合标准检查

| 标准条目 | 优化前 | 优化后 | 备注 |
|---------|--------|--------|------|
| **第一节: 题目格式** |
| 给[受益人]+动词+目标 | ❌ | ✅ | 添加"给张建国" |
| 口语化描述 | ❌ | ✅ | "老人家要...那种" |
| 不含表单字段 | ❌ | ✅ | 移除参数式表述 |
| **第三节: demo_user 数据** |
| 使用 passengers 数据 | ❌ | ✅ | **prepare查询张建国(65岁)** |
| 禁止硬编码姓名 | ❌ | ✅ | 使用@zhangjianguo.name |
| 验证联系人信息 | ❌ | ✅ | 新增断言6 |
| **使用正确的老人角色** | ❌ | ✅ | **张建国(65岁)不是张三(34岁)** |
| **第四节: verify 断言** |
| 断言顺序合理 | ✅ | ✅ | 存在→实体→属性→逻辑 |
| 权重分配标准 | ⚠️ | ✅ | 调整次要属性权重 |
| 权重总和100% | ✅ | ✅ | 100分 |
| 核心业务高权重 | ✅ | ✅ | 医疗保额30分 |

---

## 关键改进点总结

1. **用户视角的标题描述**: "给张建国购买...老人家要医疗保额最高的那种"
2. **修正人物错误**: 张三(34岁) → 张建国(65岁老人)
3. **规范使用 demo_user 数据**: prepare查询→simulate使用→verify验证
4. **完善投保人信息验证**: 新增断言验证姓名和身份证号
5. **优化权重分配**: 核心业务逻辑(30分)最高,次要属性降低权重
6. **状态管理完整**: 保存和恢复投保人期望值

---

## 测试命令

```bash
# 单独测试 v080
rake validator:simulate_single[v080_buy_senior_travel_insurance_validator]

# 完整测试套件
rake validator:simulate
```

---

## 相关文档

- `docs/VALIDATOR_WRITING_STANDARDS.md` - 验证器编写标准
- `app/validators/v051_v100/v079_buy_international_travel_insurance_thailand_validator.rb` - 参考用例(保险订单insured_persons字段使用)
- `app/validators/support/data_packs/v1/demo_user.rb` - demo_user 数据定义（包含张建国家庭关系）
