# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例83: 给张三购买全年交通意外险（北京，365天，全年无限次保障）
# 
# 任务描述:
#   Agent 需要为北京的商务人士购买全年交通意外险，
#   选择支持全年无限次保障的交通综合保险产品
# 
# 复杂度分析:
#   1. 需要搜索"交通意外"类型的保险产品
#   2. 需要识别全年计划产品（max_days=365）
#   3. 需要理解全年计划支持多次出行保障
#   4. 需要对比全年计划产品
#   5. 需要理解全年计划通常每日单价更低但总价更高
#   ❌ 不能一次性提供：需要先搜索→识别全年计划→理解优势→购买
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 保险类型正确（交通意外transport）(15分)
#   - 目的地正确（北京）(10分)
#   - 产品是全年计划（365天）(30分)
#   - 适合交通综合保障场景 (15分)
#   - 保障天数正确（365天）(10分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v083_buy_annual_travel_plan_validator/start
#   
#   # Agent 通过界面操作完成购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V051V100
  class V083BuyAnnualTravelPlanValidator < BaseValidator
    self.validator_id = 'v083_buy_annual_travel_plan_validator'
    self.task_id = 'a4b9bf4f-8238-4401-8ff3-a58352e12aea'
    self.title = '给张三购买全年交通意外险（北京，365天，全年无限次保障）'
    self.description = '购买全年交通意外险（北京，365天，全年无限次保障）'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @product_type = 'transport'
      @days = 365
      @quantity = 1
      @scene = '交通综合'
      @destination = '北京'  # 明确具体城市，交通意外险需要指定出发地
      @start_date = Date.current + 1.day  # 明天开始生效
      @end_date = @start_date + @days - 1  # 明年今天结束（365天后）
    
      # 查询被保险人信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_insured_name = @zhangsan.name
      @expected_insured_id_number = @zhangsan.id_number
      @expected_contact_phone = @zhangsan.phone  # 单人保险：被保险人就是联系人
    
      # 查找全年交通意外险产品（注意：查询基线数据 data_version=0）
      @available_products = InsuranceProduct.where(
        product_type: @product_type,
        data_version: 0
      ).where('max_days >= ?', 365)
    
      # 返回给 Agent 的任务信息
      {
        task: "请为张三购买全年交通意外险（在北京用，明天生效，保障期365天到明年今天结束），支持全年无限次保障",
        product_type: "交通意外",
        destination: @destination,
        plan_type: "全年计划",
        days: @days,
        quantity: @quantity,
        scene: @scene,
        insured_person: @expected_insured_name,
        start_date: @start_date.to_s,
        end_date: @end_date.to_s,
        hint: "全年交通意外险适合需要经常出差的商务人士，保障期365天，支持全年无限次保障。请选择max_days≥365且适合交通综合保障的产品",
        available_products_count: @available_products.count,
        note: "全年计划虽然总价较高，但平均每天单价很低，适合频繁出差的人士"
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 必须有订单创建（最近创建的一条）
      add_assertion "订单已创建", weight: 20 do
        all_insurance_orders = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_insurance_orders).not_to be_empty, "未找到任何InsuranceOrder记录"
        @insurance_order = all_insurance_orders.first
        # Replaced by expect(all_insurance_orders).not_to be_empty above, "未找到任何保险订单记录"
      end
    
      return unless @insurance_order # 如果没有订单，后续断言无法继续
    
      # 断言2: 保险类型正确（交通意外）
      add_assertion "保险类型正确（交通意外transport）", weight: 10 do
        actual_type = @insurance_order.insurance_product.product_type
        expect(actual_type).to eq(@product_type),
          "保险类型错误。期望: #{@product_type}（交通意外），实际: #{actual_type}。" \
          "全年交通意外险属于交通意外保险类型"
      end
    
      # 断言3: 目的地正确
      add_assertion "目的地正确（#{@destination}）", weight: 10 do
        actual_destination = @insurance_order.destination
        expect(actual_destination).to include(@destination),
          "目的地错误。期望包含: #{@destination}, 实际: #{actual_destination || '未填写'}"
      end
    
      # 断言4: 被保险人信息正确（张三）
      add_assertion "被保险人信息正确（#{@expected_insured_name}）", weight: 10 do
        insured_persons = @insurance_order.insured_persons || []
        zhangsan_record = insured_persons.find { |p| p['name'] == @expected_insured_name || p == @expected_insured_name }
        expect(zhangsan_record).not_to be_nil,
          "被保险人信息错误。期望: #{@expected_insured_name}，实际: #{insured_persons.inspect}"
        
        # 验证身份证号（如果是Hash结构）
        if zhangsan_record.is_a?(Hash) && zhangsan_record['id_number']
          expect(zhangsan_record['id_number']).to eq(@expected_insured_id_number),
            "被保险人身份证号错误。期望: #{@expected_insured_id_number}，实际: #{zhangsan_record['id_number']}"
        end
      end
    
      # 断言5: 联系人电话正确（张三的电话）
      add_assertion "联系人电话正确（#{@expected_contact_phone}）", weight: 5 do
        insured_persons = @insurance_order.insured_persons || []
        zhangsan_record = insured_persons.find { |p| p['name'] == @expected_insured_name || p == @expected_insured_name }
        
        # 单人保险：被保险人就是联系人，验证电话字段
        if zhangsan_record.is_a?(Hash)
          actual_phone = zhangsan_record['phone'] || zhangsan_record['contact_phone']
          expect(actual_phone).to eq(@expected_contact_phone),
            "联系人电话错误。期望: #{@expected_contact_phone}（#{@expected_insured_name}），实际: #{actual_phone}"
        end
      end
    
      # 断言6: 产品是全年计划（365天）（核心评分项）
      add_assertion "产品是全年计划（365天）", weight: 25 do
        product = @insurance_order.insurance_product
        max_days = product.max_days
      
        is_annual = (max_days >= 365)
      
        expect(is_annual).to be_truthy,
          "所选产品不支持全年计划。期望: max_days≥365, 实际: max_days=#{max_days}。" \
          "全年交通意外险支持365天保障期，可以全年无限次保障"
      end
    
      # 断言7: 适合交通综合保障场景
      add_assertion "适合交通综合保障场景", weight: 10 do
        scenes = @insurance_order.insurance_product.scenes || []
        has_scene = scenes.include?(@scene)
      
        expect(has_scene).to be_truthy,
          "所选产品不适合交通综合保障场景。期望: scenes包含'#{@scene}', 实际: scenes=#{scenes.inspect}。" \
          "全年交通意外险通常适合经常出差的商务人士"
      end
    
      # 断言8: 保障天数和日期逻辑正确（365天，从明天到明年今天）
      add_assertion "保障天数和日期逻辑正确（365天，从明天到明年今天）", weight: 10 do
        actual_days = @insurance_order.days
        expect(actual_days).to eq(@days),
          "保障天数错误。期望: #{@days}天（全年），实际: #{actual_days}天"
        
        # 验证日期逻辑：从明天开始
        actual_start = @insurance_order.start_date
        expect(actual_start).to eq(@start_date),
          "开始日期错误。期望: #{@start_date}（明天），实际: #{actual_start}"
        
        # 验证日期逻辑：到明年今天结束（365天后）
        actual_end = @insurance_order.end_date
        expect(actual_end).to eq(@end_date),
          "结束日期错误。期望: #{@end_date}（明年今天），实际: #{actual_end}"
        
        # 验证日期跨度确实是365天
        actual_duration = (actual_end - actual_start).to_i + 1
        expect(actual_duration).to eq(365),
          "日期跨度错误。期望: 365天，实际: #{actual_duration}天（#{actual_start} 到 #{actual_end}）"
      end
    end
  
    private
  
    # 保存执行状态数据
    def execution_state_data
      {
        product_type: @product_type,
        destination: @destination,
        days: @days,
        quantity: @quantity,
        scene: @scene,
        start_date: @start_date&.to_s,
        end_date: @end_date&.to_s,
        expected_insured_name: @expected_insured_name,
        expected_insured_id_number: @expected_insured_id_number,
        expected_contact_phone: @expected_contact_phone
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @product_type = data['product_type']
      @destination = data['destination']
      @days = data['days']
      @quantity = data['quantity']
      @scene = data['scene']
      @start_date = data['start_date'] ? Date.parse(data['start_date']) : nil
      @end_date = data['end_date'] ? Date.parse(data['end_date']) : nil
      @expected_insured_name = data['expected_insured_name']
      @expected_insured_id_number = data['expected_insured_id_number']
      @expected_contact_phone = data['expected_contact_phone']
    
      # 重新查询被保险人信息
      if @expected_insured_name
        user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
        @zhangsan = user.passengers.find_by!(name: @expected_insured_name, data_version: 0)
      end
    
      # 重新加载可用产品列表
      @available_products = InsuranceProduct.where(
        product_type: @product_type,
        data_version: 0
      ).where('max_days >= ?', 365)
    end
  
    # 模拟 AI Agent 操作：为张三购买全年交通意外险
    def simulate
      # 1. 查找测试用户（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 查找全年交通意外险产品
      available_products = InsuranceProduct.where(
        product_type: @product_type,
        data_version: 0
      ).where('max_days >= ?', 365)
    
      raise "未找到全年交通意外险产品" if available_products.empty?
    
      # 3. 选择适合交通综合保障的全年计划
      selected_product = available_products.find { |p| p.scenes&.include?(@scene) }
      selected_product ||= available_products.first  # 如果没有交通综合标签，选择第一个
    
      raise "未找到可用的保险产品" unless selected_product
    
      # 4. 构建被保险人信息（使用 prepare 中查询的张三信息）
      insured_persons_data = [{
        name: @zhangsan.name,
        id_number: @zhangsan.id_number,
        phone: @zhangsan.phone  # 联系电话
      }]
    
      # 5. 创建保险订单
      unit_price = selected_product.price_per_day * @days
    
      insurance_order = InsuranceOrder.create!(
        user_id: user.id,
        insurance_product_id: selected_product.id,
        source: 'standalone',  # 单独购买
        start_date: @start_date,
        end_date: @end_date,
        days: @days,
        destination: @destination,
        destination_type: 'domestic',
        insured_persons: insured_persons_data,
        unit_price: unit_price,
        quantity: @quantity,
        total_price: unit_price * @quantity,
        status: 'pending',
        data_version: @data_version
      )
    
      # 返回操作信息
      {
        action: 'create_insurance_order',
        order_id: insurance_order.id,
        insurance_product_name: selected_product.name,
        company: selected_product.company,
        product_type: selected_product.product_type,
        plan_type: '全年计划',
        scenes: selected_product.scenes,
        price_per_day: selected_product.price_per_day,
        days: @days,
        quantity: @quantity,
        unit_price: unit_price,
        total_price: insurance_order.total_price,
        start_date: @start_date.to_s,
        end_date: @end_date.to_s,
        user_email: user.email
      }
    end
    end
end