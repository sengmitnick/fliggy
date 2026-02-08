# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例53: 给张三购买日本天包漫游流量（选最便宜的）
# 
# ⚠️ 重要说明:
#   本验证器测试的是 InternetDataPlan（漫游流量包），NOT InternetSimCard（SIM卡）
#   订单类型必须是 order_type='data_plan'，orderable_type='InternetDataPlan'
#   
#   InternetDataPlan = 运营商漫游流量包（如中国电信境外漫游包）
#   InternetSimCard = 境外当地SIM卡（如日本SIM卡）
#   两者是不同的产品类型！
# 
# 任务描述:
#   通过联系人选择器选择张三 → 自动填充他的手机号 → 选择日本天包最便宜的流量包 → 创建订单
#   
#   重要：手机号必须通过联系人（Passenger）获取，不是手动输入
#   
#   包含三种套餐类型（InternetDataPlan的plan_type字段）:
#   - 天包: 按天计费，如日本1天(28元)、3天(68元)、7天(128元)
#   - 月包: 按月计费，如香港30天(288元)、60天(528元)、90天(788元)
#   - 语音包: 语音通话包，如香港语音包100分钟(68元)、日本语音包100分钟(88元)
#   
#   筛选条件: region='日本' AND plan_type='天包' AND data_version=0（基线数据）
#   最便宜: 日本1天漫游包，28元（天包类型）
#   联系人: 张三（Passenger表中is_self=true的记录）
#   手机号: 从张三的Passenger记录获取
#   流量: 0.5GB/天，4G/5G漫游
#   
#   数据隔离: 使用data_version字段标记当前验证会话的订单，避免跨会话数据污染
# 
# 操作步骤:
#   1. 浏览日本流量包: 筛选天包类型
#   2. 对比价格: 1天(28元) < 3天(68元) < 7天(128元)
#   3. 选最便宜: 28元（日本1天漫游包，天包类型）
#   4. 点击联系人按钮: 选择张三（从Passenger表获取）
#   5. 自动填充手机号: 张三的电话号码
#   6. 计算总价: 28×1=28元
# 
# 评分标准:
#   - 订单已创建（使用data_version隔离会话） (20分)
#   - 订单类型=data_plan (10分)
#   - 选了具体流量包产品 (10分)
#   - 选了日本天包中最便宜的28元日本1天漫游包（基于data_version=0的基线数据） (35分)
#   - 手机号与张三的Passenger记录一致 (15分)
#   - 总价=28元 (10分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v053_buy_data_plan_validator/start
#   
#   # Agent 通过界面操作完成购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V051V100
  class V053BuyDataPlanValidator < BaseValidator
    self.validator_id = 'v053_buy_data_plan_validator'
    self.task_id = '22f7ecf1-8018-4a3f-8c00-f6fce7bee108'
    self.title = '给张三买日本天包漫游流量（选最便宜的）'
    self.description = '张三要去日本旅游，通过联系人选择器选择张三，帮他买天包漫游流量（运营商漫游包），选最便宜的套餐'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @region = '日本'
      @plan_type = '天包'
      @quantity = 1     # 1份
    
      # 查找张三的联系人信息（从Passenger表获取）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan_passenger = user.passengers.find_by!(is_self: true, data_version: 0)
      @zhangsan_phone = @zhangsan_passenger.phone
    
      # 查找日本天包流量包产品（注意：查询基线数据 data_version=0）
      @available_data_plans = InternetDataPlan.where(
        region: @region,
        plan_type: @plan_type,
        data_version: 0
      )
    
      # 返回给 Agent 的任务信息
      {
        task: "给张三购买日本天包漫游流量: 通过联系人选择器选择张三、1份、选最便宜的",
        product_type: "InternetDataPlan（漫游流量包，NOT SIM卡）",
        order_type_expected: "data_plan",
        region: @region,
        plan_type: @plan_type,
        quantity: @quantity,
        contact_name: @zhangsan_passenger.name,
        contact_phone: @zhangsan_phone,
        hint: "从日本天包类型漫游流量包（InternetDataPlan）中选择价格最低的套餐(28元，日本1天漫游包)。这是运营商漫游包，不是境外SIM卡。通过联系人选择器选择张三（#{@zhangsan_passenger.name}），系统会自动填充他的手机号（#{@zhangsan_phone}）",
        available_data_plans_count: @available_data_plans.count
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 必须有订单创建（使用data_version隔离当前会话的订单）
      add_assertion "订单已创建", weight: 20 do
        @internet_order = InternetOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@internet_order).not_to be_nil, "未找到任何境外上网订单记录（data_version: #{@data_version}）"
      end
    
      return unless @internet_order # 如果没有订单，后续断言无法继续
    
      # 断言2: 订单类型正确（必须是data_plan，不是sim_card）
      add_assertion "订单类型正确（data_plan）", weight: 10 do
        actual_type = @internet_order.order_type
        expect(actual_type).to eq('data_plan'),
          "订单类型错误。期望: data_plan（漫游流量包），实际: #{actual_type}。" \
          "注意：InternetDataPlan使用order_type='data_plan'，InternetSimCard使用'sim_card'"
      end
    
      # 断言3: 选择了具体的漫游流量包产品（InternetDataPlan）
      add_assertion "选择了具体的流量包产品", weight: 10 do
        expect(@internet_order.orderable_type).to eq('InternetDataPlan'), 
          "未选择流量包产品（orderable_type错误）。" \
          "期望: InternetDataPlan（漫游流量包），实际: #{@internet_order.orderable_type}。" \
          "注意：不要选择InternetSimCard（SIM卡）"
        expect(@internet_order.orderable_id).not_to be_nil, "未选择具体的流量包产品（orderable_id为空）"
        expect(@internet_order.orderable).not_to be_nil, "流量包产品记录不存在"
      end
    
      # 断言4: 选择了日本天包中最便宜的流量包（核心评分项）
      add_assertion "选择了日本天包中最便宜的流量包", weight: 35 do
        # 获取日本天包流量包
        japan_daily_data_plans = InternetDataPlan.where(
          region: '日本',
          plan_type: '天包',
          data_version: 0
        )
      
        # 找到价格最低的
        cheapest_data_plan = japan_daily_data_plans.min_by(&:price)
        actual_price = @internet_order.orderable.price
        cheapest_price = cheapest_data_plan.price
        data_plan = @internet_order.orderable
      
        # 验证地区和类型
        expect(data_plan.region).to eq('日本'),
          "流量包地区不匹配。预期: 日本, 实际: #{data_plan.region}"
        expect(data_plan.plan_type).to eq('天包'),
          "流量包类型不匹配。预期: 天包, 实际: #{data_plan.plan_type}"
      
        # 验证选择了最便宜的
        expect(@internet_order.orderable_id).to eq(cheapest_data_plan.id),
          "未选择日本天包中最便宜的流量包。" \
          "应选: #{cheapest_data_plan.name}（#{cheapest_price}元），" \
          "实际选择: #{data_plan.name}（#{actual_price}元）"
      end
    
      # 断言5: 手机号与张三的Passenger记录一致
      add_assertion "手机号与张三的联系人信息一致", weight: 15 do
        contact_info = begin
          JSON.parse(@internet_order.contact_info)
        rescue JSON::ParserError, TypeError
          nil
        end
      
        expect(contact_info).not_to be_nil, "contact_info 为空或无法解析"
        actual_phone = contact_info['phone']
        
        expect(actual_phone).to eq(@zhangsan_phone),
          "手机号与张三的联系人记录不一致。期望: #{@zhangsan_phone}（张三的Passenger记录），实际: #{actual_phone}。" \
          "请通过联系人选择器选择张三，而不是手动输入手机号"
      end
    
      # 断言6: 订单价格正确
      add_assertion "订单价格正确", weight: 10 do
        data_plan = @internet_order.orderable
        expected_price = data_plan.price * @quantity
        actual_price = @internet_order.total_price
        plan_type_text = data_plan.plan_type
      
        expect(actual_price).to eq(expected_price),
          "订单价格错误。期望: #{expected_price}元（#{data_plan.price}元 × #{@quantity}份，套餐类型: #{plan_type_text}），实际: #{actual_price}元"
      end
    end
  
    private
  
    # 保存执行状态数据
    def execution_state_data
      {
        region: @region,
        plan_type: @plan_type,
        quantity: @quantity,
        zhangsan_phone: @zhangsan_phone
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @region = data['region']
      @plan_type = data['plan_type']
      @quantity = data['quantity'].to_i if data['quantity']
      @zhangsan_phone = data['zhangsan_phone']
    
      # 重新加载可用流量包列表
      @available_data_plans = InternetDataPlan.where(
        region: @region,
        plan_type: @plan_type,
        data_version: 0
      )
      
      # 重新获取张三的联系人信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan_passenger = user.passengers.find_by!(is_self: true, data_version: 0)
    end
  
    # 模拟 AI Agent 操作：给张三购买日本天包流量，选择最便宜的
    def simulate
      # 1. 查找测试用户（数据包中已创建，使用基线数据data_version=0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 从联系人获取张三的手机号
      zhangsan_passenger = user.passengers.find_by!(is_self: true, data_version: 0)
      zhangsan_phone = zhangsan_passenger.phone
    
      # 3. 查找日本天包流量包产品（筛选基线数据data_version=0）
      available_data_plans = InternetDataPlan.where(
        region: @region,
        plan_type: @plan_type,
        data_version: 0
      )
    
      raise "未找到任何日本天包流量包产品" if available_data_plans.empty?
    
      # 4. 选择价格最低的流量包
      cheapest_data_plan = available_data_plans.min_by(&:price)
    
      raise "未找到可用的日本天包流量包产品" unless cheapest_data_plan
    
      # 5. 计算总价：单价 × 数量
      total_price = cheapest_data_plan.price * @quantity
    
      # 6. 创建境外上网订单（使用data_version标记当前会话）
      internet_order = InternetOrder.create!(
        user_id: user.id,
        orderable_type: 'InternetDataPlan',
        orderable_id: cheapest_data_plan.id,
        order_type: 'data_plan',
        region: cheapest_data_plan.region,
        quantity: @quantity,
        total_price: total_price,
        delivery_method: nil,
        contact_info: JSON.generate({
          phone: zhangsan_phone  # 使用从Passenger获取的手机号
        }),
        rental_info: JSON.generate({
          validity_days: cheapest_data_plan.validity_days,
          unit_price: cheapest_data_plan.price.to_f
        }),
        status: 'pending',
        data_version: @data_version
      )
    
      # 返回操作信息
      {
        action: 'create_internet_order',
        order_id: internet_order.id,
        order_number: internet_order.order_number,
        data_plan_name: cheapest_data_plan.name,
        region: cheapest_data_plan.region,
        price: cheapest_data_plan.price,
        validity_days: cheapest_data_plan.validity_days,
        quantity: @quantity,
        total_price: internet_order.total_price,
        user_email: user.email
      }
    end
    end
end
