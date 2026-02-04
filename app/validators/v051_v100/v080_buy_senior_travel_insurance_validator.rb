# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例80: 购买老人旅游保险（65岁，北京出行，5天，高保额）
# 
# 任务描述:
#   Agent 需要为65岁老人购买境内旅游保险，
#   选择医疗保额最高的产品（老人通常需要更高保额）
# 
# 复杂度分析:
#   1. 需要搜索"境内旅游"类型的保险产品
#   2. 需要理解老人需要更高的医疗保额
#   3. 需要对比各产品的医疗保额（coverage_details.medical）
#   4. 需要选择医疗保额最高的产品
#   5. 需要填写被保险人年龄等信息
#   ❌ 不能一次性提供：需要先搜索→理解老人需求→对比保额→选择
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 保险类型正确（境内旅游）(10分)
#   - 目的地正确（北京）(10分)
#   - 出行开始时间正确（5天后）(10分)
#   - 保障天数正确（5天）(10分)
#   - 选择了医疗保额最高的产品 (30分)
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
    self.title = '购买老人旅游保险（65岁，北京出行，5天，高保额）'
    self.description = '为65岁老人购买境内旅游保险，选择医疗保额最高的产品'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @product_type = 'domestic'
      @destination = '北京'
      @days = 5
      @quantity = 1
      @age = 65
      @start_date = Date.today + 5.days  # 5天后开始
      @end_date = @start_date + @days - 1  # 保障结束日期
    
      # 查找境内旅游保险产品（注意：查询基线数据 data_version=0）
      # 只筛选官方精选产品（official_select: true，前端首页显示）
      # 排除运动保险（有 sports_injury 保障的产品）
      all_domestic_products = InsuranceProduct.where(
        product_type: @product_type,
        official_select: true,
        data_version: 0
      ).where('min_days <= ? AND max_days >= ?', @days, @days)
      
      @available_products = all_domestic_products.select do |p|
        # 排除有运动伤害保障的产品（如滑雪运动保险）
        !p.coverage_details.key?('sports_injury')
      end
    
      # 找到最高医疗保额值
      @highest_medical = @available_products.map { |p| p.coverage_details['medical'] || 0 }.max
    
      # 返回给 Agent 的任务信息
      {
        task: "请为65岁老人购买#{@destination}出行的境内旅游保险（5天后出发，保障期#{@days}天），老年人需要更高医疗保额，请选择医疗保额最高的产品",
        product_type: "境内旅游",
        destination: @destination,
        days: @days,
        quantity: @quantity,
        age: @age,
        start_date: @start_date.to_s,
        end_date: @end_date.to_s,
        hint: "老年人旅游风险较高，建议选择医疗保额（coverage_details.medical）最高的保险产品。系统中官方精选有多款产品，请对比医疗保额后选择",
        available_products_count: @available_products.count,
        note: "老人旅游保险通常要求更高的医疗保障，部分产品可能有年龄限制"
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 必须有订单创建（最近创建的一条）
      add_assertion "订单已创建", weight: 20 do
        @insurance_order = InsuranceOrder.order(created_at: :desc).first
        expect(@insurance_order).not_to be_nil, "未找到任何保险订单记录"
      end
    
      return unless @insurance_order # 如果没有订单，后续断言无法继续
    
      # 断言2: 保险类型正确
      add_assertion "保险类型正确（境内旅游）", weight: 10 do
        actual_type = @insurance_order.insurance_product.product_type
        expect(actual_type).to eq(@product_type),
          "保险类型错误。期望: #{@product_type}（境内旅游），实际: #{actual_type}"
      end
    
      # 断言3: 目的地正确
      add_assertion "目的地正确（#{@destination}）", weight: 10 do
        actual_destination = @insurance_order.destination
        expect(actual_destination).to include(@destination),
          "目的地错误。期望包含: #{@destination}, 实际: #{actual_destination || '未填写'}"
      end
    
      # 断言4: 出行开始时间正确（5天后）
      add_assertion "出行开始时间正确（5天后，#{@start_date}）", weight: 10 do
        actual_start_date = @insurance_order.start_date
        expect(actual_start_date).to eq(@start_date),
          "出行开始时间错误。期望: #{@start_date}（5天后）, 实际: #{actual_start_date}"
      end
    
      # 断言5: 保障天数正确
      add_assertion "保障天数正确（#{@days}天）", weight: 10 do
        actual_days = @insurance_order.days
        expect(actual_days).to eq(@days),
          "保障天数错误。期望: #{@days}天, 实际: #{actual_days}天"
      end
    
      # 断言6: 选择了医疗保额最高的产品（核心评分项）
      add_assertion "选择了医疗保额最高的产品", weight: 30 do
        # 获取所有官方精选的境内旅游保险产品（排除运动保险）
        all_domestic_products = InsuranceProduct.where(
          product_type: @product_type,
          official_select: true,
          data_version: 0
        ).where('min_days <= ? AND max_days >= ?', @days, @days)
        
        all_products = all_domestic_products.select do |p|
          # 排除有运动伤害保障的产品（如滑雪运动保险）
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
          "最高医疗保额: #{highest_medical}元（共#{highest_products.size}个产品达到此保额：#{highest_products.map(&:name).join('、')}），" \
          "实际选择: #{@insurance_order.insurance_product.name}（#{@insurance_order.insurance_product.company}，医疗保额#{actual_medical}元，每天#{@insurance_order.insurance_product.price_per_day}元）。" \
          "老年人旅游应选择医疗保额最高的产品"
      end
    
      # 断言7: 订单价格计算正确
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
          "订单总价错误。期望: #{expected_total}元（单价#{expected_unit_price}元 × #{@insurance_order.quantity}人），实际: #{actual_total}元"
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
        highest_medical: @highest_medical
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @product_type = data['product_type']
      @destination = data['destination']
      @days = data['days']
      @quantity = data['quantity']
      @age = data['age']
      @highest_medical = data['highest_medical']
      @start_date = data['start_date'] ? Date.parse(data['start_date']) : nil
      @end_date = data['end_date'] ? Date.parse(data['end_date']) : nil
    
      # 重新加载可用产品列表（只筛选官方精选，排除运动保险）
      all_domestic_products = InsuranceProduct.where(
        product_type: @product_type,
        official_select: true,
        data_version: 0
      ).where('min_days <= ? AND max_days >= ?', @days, @days)
      
      @available_products = all_domestic_products.select do |p|
        !p.coverage_details.key?('sports_injury')
      end
    end
  
    # 模拟 AI Agent 操作：为65岁老人购买医疗保额最高的境内旅游保险
    def simulate
      # 1. 查找测试用户（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 查找官方精选的境内旅游保险产品（排除运动保险）
      all_domestic_products = InsuranceProduct.where(
        product_type: @product_type,
        official_select: true,
        data_version: 0
      ).where('min_days <= ? AND max_days >= ?', @days, @days)
      
      available_products = all_domestic_products.select do |p|
        # 排除有运动伤害保障的产品（如滑雪运动保险）
        !p.coverage_details.key?('sports_injury')
      end
    
      raise "未找到境内旅游保险产品" if available_products.empty?
    
      # 3. 选择医疗保额最高的产品（如果有多个，选择价格最低的）
      highest_medical = available_products.map { |p| p.coverage_details['medical'] || 0 }.max
      highest_products = available_products.select { |p| (p.coverage_details['medical'] || 0) == highest_medical }
      highest_medical_product = highest_products.min_by(&:price_per_day)
    
      raise "未找到可用的保险产品" unless highest_medical_product
    
      # 4. 计算价格（考虑城市差异化定价）
      city = City.find_by(name: @destination, data_version: 0)
      city_id = city&.id
      unit_price = highest_medical_product.calculate_price(@days, city_id: city_id)
    
      # 5. 创建保险订单
      insurance_order = InsuranceOrder.create!(
        user_id: user.id,
        insurance_product_id: highest_medical_product.id,
        source: 'standalone',  # 单独购买
        start_date: @start_date,
        end_date: @end_date,
        days: @days,
        destination: @destination,
        destination_type: 'domestic',
        insured_persons: ['王老太（65岁）'],
        unit_price: unit_price,
        quantity: @quantity,
        total_price: unit_price * @quantity,
        status: 'pending'
      )
    
      # 返回操作信息
      {
        action: 'create_insurance_order',
        order_id: insurance_order.id,
        insurance_product_name: highest_medical_product.name,
        company: highest_medical_product.company,
        product_type: highest_medical_product.product_type,
        medical_coverage: highest_medical_product.coverage_details['medical'],
        price_per_day: highest_medical_product.price_per_day,
        days: @days,
        quantity: @quantity,
        unit_price: unit_price,
        total_price: insurance_order.total_price,
        destination: @destination,
        age: @age,
        start_date: @start_date.to_s,
        user_email: user.email
      }
    end
    end
end
