# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例80: 给张建国购买境内旅游保险(65岁老人,联系人张三,5天后去北京玩5天,选医疗保额最高的)
# 
# 任务描述:
#   张建国65岁(张三的父亲/小明的爷爷),5天后要去北京玩5天,帮他买个境内旅游保险,
#   老人家要医疗保额最高的那种(老人通常需要更高保额)
#   注意：张建国的联系人是张三(他的儿子)
# 
# 复杂度分析:
#   1. 需要搜索"境内旅游"类型的保险产品
#   2. 需要理解老人需要更高的医疗保额
#   3. 需要对比各产品的医疗保额(coverage_details.medical)
#   4. 需要选择医疗保额最高的产品
#   5. 需要填写被保险人信息(张建国,65岁)
#   ❌ 不能一次性提供:需要先搜索→理解老人需求→对比保额→选择
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 保险类型正确(境内旅游)(20分)
#   - 目的地正确(北京)(5分)
#   - 出行开始时间正确(5天后)(5分)
#   - 保障天数正确(5天)(5分)
#   - 被保险人信息正确(张建国)(5分)
#   - 联系人信息正确(张三)(5分)
#   - 选择了医疗保额最高的产品 (25分)
#   - 订单价格计算正确 (10分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v080_buy_senior_travel_insurance_validator/start
#   
#   # Agent 通过界面操作完成购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V051V100
  class V080BuySeniorTravelInsuranceValidator < BaseValidator
    self.validator_id = 'v080_buy_senior_travel_insurance_validator'
    self.task_id = 'b0be2515-74d7-4a7d-823d-cac17397ff55'
    self.title = '给张建国购买境内旅游保险(65岁老人,联系人张三,5天后去北京玩5天,选医疗保额最高的)'
    self.description = '给张建国购买境内旅游保险(65岁老人,联系人张三,5天后去北京玩5天,选医疗保额最高的)。注意：张建国的联系人是张三(他的儿子)'
    self.timeout_seconds = 240
  
    # 准备阶段:设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载(v1 目录下所有数据包)
      @product_type = 'domestic'
      @destination = '北京'
      @days = 5
      @quantity = 1
      @age = 65
      @start_date = Date.current + 5.days  # 5天后开始
      @end_date = @start_date + @days - 1  # 保障结束日期
      
      # 查询 demo_user 的出行人信息(张建国 - 65岁老人)
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangjianguo = user.passengers.find_by!(name: '张建国', data_version: 0)
      @expected_insured_name = @zhangjianguo.name
      @expected_insured_id_number = @zhangjianguo.id_number
      
      # 查询联系人信息（老人的联系人应该是儿子张三）
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @zhangsan.name
      @expected_contact_phone = @zhangsan.phone
    
      # 查找境内旅游保险产品(注意:查询基线数据 data_version=0)
      # 包含所有产品(包括进阶款等非官方精选产品)
      # 排除运动保险(有 sports_injury 保障的产品)
      all_domestic_products = InsuranceProduct.where(
        product_type: @product_type,
        data_version: 0
      ).where('min_days <= ? AND max_days >= ?', @days, @days)
      
      @available_products = all_domestic_products.select do |p|
        # 排除有运动伤害保障的产品(如滑雪运动保险)
        !p.coverage_details.key?('sports_injury')
      end
    
      # 找到最高医疗保额值
      @highest_medical = @available_products.map { |p| p.coverage_details['medical'] || 0 }.max
    
      # 返回给 Agent 的任务信息
      {
        task: "#{@expected_insured_name}#{@age}岁,#{@days}天后要去#{@destination}玩#{@days}天,帮他买个境内旅游保险,老人家要医疗保额最高的那种",
        product_type: "境内旅游",
        destination: @destination,
        days: @days,
        quantity: @quantity,
        age: @age,
        insured_name: @expected_insured_name,
        start_date: @start_date.to_s,
        end_date: @end_date.to_s,
        hint: "老年人旅游风险较高,建议选择医疗保额(coverage_details.medical)最高的保险产品。系统中有多款产品(包括基础款、尊享款、进阶款等),请对比医疗保额后选择",
        available_products_count: @available_products.count,
        note: "老人旅游保险通常要求更高的医疗保障,部分产品可能有年龄限制"
      }
    end
  
    # 验证阶段:检查订单是否符合要求
    def verify
      # 断言1: 必须有订单创建(最近创建的一条)
      add_assertion "订单已创建", weight: 20 do
        all_insurance_orders = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_insurance_orders).not_to be_empty, "未找到任何InsuranceOrder记录"
        @insurance_order = all_insurance_orders.first
      end
    
      return unless @insurance_order # 如果没有订单,后续断言无法继续
    
      # 断言2: 保险类型正确(核心实体)
      add_assertion "保险类型正确(境内旅游)", weight: 20 do
        actual_type = @insurance_order.insurance_product.product_type
        expect(actual_type).to eq(@product_type),
          "保险类型错误。期望: #{@product_type}(境内旅游),实际: #{actual_type}"
      end
    
      # 断言3: 目的地正确
      add_assertion "目的地正确(#{@destination})", weight: 5 do
        actual_destination = @insurance_order.destination
        expect(actual_destination).to include(@destination),
          "目的地错误。期望包含: #{@destination}, 实际: #{actual_destination || '未填写'}"
      end
    
      # 断言4: 出行开始时间正确(5天后)
      add_assertion "出行开始时间正确(5天后,#{@start_date})", weight: 5 do
        actual_start_date = @insurance_order.start_date
        expect(actual_start_date).to eq(@start_date),
          "出行开始时间错误。期望: #{@start_date}(5天后), 实际: #{actual_start_date}"
      end
    
      # 断言5: 保障天数正确
      add_assertion "保障天数正确(#{@days}天)", weight: 5 do
        actual_days = @insurance_order.days
        expect(actual_days).to eq(@days),
          "保障天数错误。期望: #{@days}天, 实际: #{actual_days}天"
      end
      
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
      
      # 断言7: 联系人信息正确（老人的联系人应该是儿子张三）
      add_assertion "联系人信息正确（老人的联系人应该是儿子张三）", weight: 5 do
        insured_persons = @insurance_order.insured_persons || []
        expect(insured_persons).not_to be_empty, "未找到投保人信息"
        
        # 检查第一个被保险人的紧急联系人字段
        first_person = insured_persons.first
        emergency_contact_name = first_person['emergency_contact_name']
        emergency_contact_phone = first_person['emergency_contact_phone']
        
        # 验证紧急联系人姓名
        expect(emergency_contact_name).to eq(@expected_contact_name),
          "未找到有效的紧急联系人信息。期望联系人: #{@expected_contact_name}，实际: #{emergency_contact_name || '未填写'}"
        
        # 验证紧急联系人电话
        expect(emergency_contact_phone).to eq(@expected_contact_phone),
          "紧急联系人电话错误。期望: #{@expected_contact_phone}，实际: #{emergency_contact_phone || '未填写'}"
      end
    
      # 断言8: 选择了医疗保额最高的产品(核心评分项 - 业务逻辑)
      add_assertion "选择了医疗保额最高的产品", weight: 25 do
        # 获取所有境内旅游保险产品(包括进阶款等,排除运动保险)
        all_domestic_products = InsuranceProduct.where(
          product_type: @product_type,
          data_version: 0
        ).where('min_days <= ? AND max_days >= ?', @days, @days)
        
        all_products = all_domestic_products.select do |p|
          # 排除有运动伤害保障的产品(如滑雪运动保险)
          !p.coverage_details.key?('sports_injury')
        end
      
        # 找到最高医疗保额值
        highest_medical = all_products.map { |p| p.coverage_details['medical'] || 0 }.max
      
        # 获取所有达到最高医疗保额的产品
        highest_products = all_products.select do |p|
          (p.coverage_details['medical'] || 0) == highest_medical
        end
      
        actual_medical = @insurance_order.insurance_product.coverage_details['medical'] || 0
      
        # 检查选择的产品是否达到最高医疗保额
        expect(actual_medical).to eq(highest_medical),
          "未选择医疗保额最高的产品。" \
          "最高医疗保额: #{highest_medical}元(共#{highest_products.size}个产品达到此保额:#{highest_products.map(&:name).join('、')}),"\
          "实际选择: #{@insurance_order.insurance_product.name}(#{@insurance_order.insurance_product.company},医疗保额#{actual_medical}元,每天#{@insurance_order.insurance_product.price_per_day}元)。" \
          "老年人旅游应选择医疗保额最高的产品"
      end
    
      # 断言9: 订单价格计算正确
      add_assertion "订单价格计算正确", weight: 10 do
        # Get city_id from destination if available
        city = City.find_by(name: @insurance_order.destination, data_version: 0)
        city_id = city&.id
        
        # Use calculate_price to get correct price (considers city-specific pricing)
        expected_unit_price = @insurance_order.insurance_product.calculate_price(
          @insurance_order.days, 
          city_id: city_id
        )
        expected_total = expected_unit_price * @insurance_order.quantity
        actual_total = @insurance_order.total_price
      
        expect(actual_total).to eq(expected_total),
          "订单总价错误。期望: #{expected_total}元(单价#{expected_unit_price}元 × #{@insurance_order.quantity}人),实际: #{actual_total}元"
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
        age: @age,
        start_date: @start_date&.to_s,
        end_date: @end_date&.to_s,
        highest_medical: @highest_medical,
        expected_insured_name: @expected_insured_name,
        expected_insured_id_number: @expected_insured_id_number,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end
  
    # 从状态数据恢复
    def restore_from_state(data)
      @product_type = data['product_type']
      @destination = data['destination']
      @days = data['days']
      @quantity = data['quantity']
      @age = data['age']
      @start_date = Date.parse(data['start_date']) if data['start_date']
      @end_date = Date.parse(data['end_date']) if data['end_date']
      @highest_medical = data['highest_medical']
      @expected_insured_name = data['expected_insured_name']
      @expected_insured_id_number = data['expected_insured_id_number']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
    end
  
    # 模拟 Agent 行为的实现
    def simulate
      # 0. 加载用户和联系人信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangjianguo = user.passengers.find_by!(name: '张建国', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
    
      # 1. 搜索所有境内旅游保险产品(包括进阶款等,排除运动保险)
      all_domestic_products = InsuranceProduct.where(
        product_type: 'domestic',
        data_version: 0
      ).where('min_days <= ? AND max_days >= ?', @days, @days)
      
      available_products = all_domestic_products.select do |p|
        # 排除有运动伤害保障的产品(如滑雪运动保险)
        !p.coverage_details.key?('sports_injury')
      end
    
      # 2. 找到医疗保额最高的产品
      highest_medical = available_products.map { |p| p.coverage_details['medical'] || 0 }.max
      highest_products = available_products.select do |p|
        (p.coverage_details['medical'] || 0) == highest_medical
      end
    
      # 3. 选择第一个医疗保额最高的产品
      selected_product = highest_products.first
      raise "未找到符合条件的保险产品" unless selected_product
    
      # 4. 计算价格
      city = City.find_by(name: @destination, data_version: 0)
      unit_price = selected_product.calculate_price(@days, city_id: city&.id)
      total_price = unit_price * @quantity
    
      # 5. 准备投保人信息(张建国,65岁) + 紧急联系人(张三)
      insured_persons_data = [
        { 
          name: zhangjianguo.name, 
          id_number: zhangjianguo.id_number,
          emergency_contact_name: zhangsan.name,  # 添加紧急联系人
          emergency_contact_phone: zhangsan.phone
        }
      ]
    
      # 6. 创建订单
      order = InsuranceOrder.create!(
        user: user,
        insurance_product: selected_product,
        destination: @destination,
        start_date: @start_date,
        end_date: @end_date,
        days: @days,
        quantity: @quantity,
        insured_persons: insured_persons_data,
        unit_price: unit_price,
        total_price: total_price,
        data_version: @data_version
      )
    
      order
    end
  end
end
