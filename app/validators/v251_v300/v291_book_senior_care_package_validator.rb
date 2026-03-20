# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例291: 给张建国（65岁老人）预订九寨沟跟团游（2天1晚，10天后出发，含境内旅游保险）
# 
# 任务描述:
#   张建国（65岁老人）计刢10天后出发前往九寨沟旅游。
#   Agent 需要为老年人预订适合的跟团游产品，并购买境内旅游保险。
# 
# 业务流程（6个关键步骤）：
#   1. 搜索九寨沟跟团游产品（适合老年人，2天1晚）
#   2. 选择合适的旅游套餐（设置10天后的出行日期，确认游玩天数）
#   3. 填写联系人信息（张建国）并创建跟团游订单
#   4. 搜索境内旅游保险产品（product_type='domestic'）
#   5. 设置保险日期（从出行日期开始，覆盖旅游期间）
#   6. 填写被保险人信息（张建国，65岁）并创建保险订单
# 
# 复杂度分析（9个关键点）：
#   1. 需要理解目的地筛选：查找 destination='九寨沟' 的跟团游产品
#   2. 需要理解天数筛选：选择 duration=2 天的跟团游产品
#   3. 需要理解日期计算：travel_date=10天后
#   4. 需要理解老年人信息：从 Passenger 表中获取张建国（65岁）的信息
#   5. 需要理解组合购买：跟团游订单（TourGroupBooking）+ 保险订单（InsuranceOrder）两个订单
#   6. 需要理解保险类型选择：境内旅游险（product_type='domestic'）
#   7. 需要理解保险日期对齐：start_date=出行日期，覆盖旅游期间
#   8. 需要理解被保险人信息：insured_persons 包含张建国的姓名和身份证号
#   9. 需要理解数据隔离：两个订单都必须使用 data_version=@data_version
#   ❌ 不能忘记保险：老年人出行建议购买保险
#   ❌ 不能选错类型：必须选择境内旅游险（product_type='domestic'）
#   ❌ 不能选错天数：必须选择2天的跟团游产品
# 
# 评分标准（7项，总计100分）：
#   - 创建跟团游预订（20%）
#   - 创建境内旅游保险（20%）
#   - 被保险人信息正确（张建国，65岁）（15%）
#   - 跟团游天数正确（2天）（15%）
#   - 出行日期正确（10天后）（15%）
#   - 联系人信息正确（张建国）（10%）
#   - 订单状态正确（pending/confirmed/paid）（5%）
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v291_book_senior_care_package_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V251V300
  class V291BookSeniorCarePackageValidator < BaseValidator
    self.validator_id = 'v291_book_senior_care_package_validator'
    self.task_id = '09a76fc5-3c70-446f-a35e-e52d8ed218f9'
    self.title = '给张建国（65岁老人）预订九寨沟跟团游（2天1晚，10天后出发，含境内旅游保险）'
    self.description = '给张建国（65岁老人）预订九寨沟跟团游（2天1晚，10天后出发，含旅游保险）'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '九寨沟'
      @travel_date = Date.current + 10.days
      
      # 预查询跟团游产品信息（获取天数）
      tour_product = TourGroupProduct.find_by!(destination: @destination, data_version: 0)
      @expected_duration = tour_product.duration  # 2天
      
      # 预查询老年人乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangjianguo = user.passengers.find_by!(name: '张建国', data_version: 0)  # 65岁老人
      @expected_insured_name = @zhangjianguo.name
      @expected_insured_id_number = @zhangjianguo.id_number
      @expected_contact_phone = @zhangjianguo.phone
      
      if user.balance < 5000
        user.update!(balance: 8000)
      end
      
      {
        task: "请为张建国老人预订#{@destination}跟团游，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，游玩#{@expected_duration}天，需要适老化服务和老年人专用医疗保障",
        destination: @destination,
        travel_date: @travel_date.to_s,
        duration: @expected_duration,
        hint: "选择适合老年人的#{@expected_duration}天跟团游产品，并购买境内旅游保险"
      }
    end
    
    def verify
      # 断言1: 创建跟团游预订（20分）
      # 作用: 查询本次会话的跟团游预订记录，确保预订成功
      # 查询逻辑: 
      #   - 必须包含 data_version: @data_version（会话隔离）
      #   - 通过 joins(:tour_group_product) 关联查询，筛选 destination='九寨沟' 的产品
      #   - 按创建时间倒序，获取最新的预订
      add_assertion "创建了跟团游预订", weight: 20 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游预订"
      end
      
      return unless @tour_booking  # 保护后续断言
      
      # 断言2: 创建境内旅游保险（20分）
      # 作用: 查询本次会话的保险订单记录，确保购买保险
      # 查询逻辑: 
      #   - 必须包含 data_version: @data_version（会话隔离）
      #   - 按创建时间倒序，获取最新的保险订单
      add_assertion "创建了境内旅游保险", weight: 20 do
        @insurance = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@insurance).not_to be_nil, "未找到境内旅游保险订单"
      end
      
      # 断言3: 被保险人信息正确（张建国，65岁）（15分）
      # 作用: 验证保险被保险人姓名和身份证号是否正确
      # 验证逻辑:
      #   - 检查 insured_persons 字段是否非空
      #   - 从 insured_persons 数组中查找 name='张建国' 的记录
      #   - 验证身份证号是否匹配
      add_assertion "被保险人信息正确（张建国，65岁）", weight: 15 do
        return unless @insurance
        
        insured_persons = @insurance.insured_persons || []
        zhangjianguo_record = insured_persons.find { |p| p['name'] == @expected_insured_name }
        
        expect(zhangjianguo_record).not_to be_nil,
          "被保险人信息中未找到张建国"
        expect(zhangjianguo_record['id_number']).to eq(@expected_insured_id_number),
          "被保险人身份证号错误。期望: #{@expected_insured_id_number}, 实际: #{zhangjianguo_record['id_number']}"
      end
      
      # 断言4: 跟团游天数正确（2天）（15分）
      # 作用: 验证选择的跟团游产品天数是否正确
      # 验证逻辑:
      #   - 通过关联查询获取 tour_group_product.duration
      #   - 验证duration是否为2天
      add_assertion "跟团游天数正确（#{@expected_duration}天）", weight: 15 do
        expect(@tour_booking.tour_group_product.duration).to eq(@expected_duration),
          "跟团游天数错误。期望: #{@expected_duration}天, 实际: #{@tour_booking.tour_group_product.duration}天"
      end
      
      # 断言5: 出行日期正确（15分）
      # 作用: 验证跟团游出行日期是否为10天后
      add_assertion "出行日期正确（#{@travel_date}）", weight: 15 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}（10天后）, 实际: #{@tour_booking.travel_date}"
      end
      
      # 断言6: 联系人信息正确（张建国）（10分）
      # 作用: 验证跟团游订单的联系人姓名和电话是否正确
      add_assertion "联系人信息正确（张建国）", weight: 10 do
        expect(@tour_booking.contact_name).to eq(@expected_insured_name),
          "联系人姓名错误。期望: #{@expected_insured_name}, 实际: #{@tour_booking.contact_name}"
        expect(@tour_booking.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@tour_booking.contact_phone}"
      end
      
      # 断言7: 订单状态正确（5分）
      # 作用: 验证跟团游订单状态是否有效
      add_assertion "订单状态正确", weight: 5 do
        valid_statuses = ['pending', 'confirmed', 'paid']
        expect(valid_statuses).to include(@tour_booking.status),
          "跟团游订单状态错误: #{@tour_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangjianguo = user.passengers.find_by!(name: '张建国', data_version: 0)
      
      # 1. 预订跟团游
      tour_product = TourGroupProduct.where(destination: @destination, data_version: 0).first!
      tour_package = tour_product.tour_packages.first!
      
      TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: tour_product.id,
        tour_package_id: tour_package.id,
        travel_date: @travel_date,
        adult_count: 1,
        child_count: 0,
        contact_name: zhangjianguo.name,
        contact_phone: zhangjianguo.phone,
        insurance_type: 'none',
        total_price: tour_package.price,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 2. 购买境内旅游保险
      insurance_product = InsuranceProduct.where(data_version: 0).order(price_per_day: :desc).first!
      InsuranceOrder.create!(
        user_id: user.id,
        insurance_product_id: insurance_product.id,
        start_date: @travel_date,
        end_date: @travel_date + 5.days,
        days: 5,
        insured_persons: [{ name: zhangjianguo.name, id_number: zhangjianguo.id_number }],
        unit_price: insurance_product.price_per_day,
        quantity: 1,
        total_price: insurance_product.price_per_day * 5,
        status: 'paid',
        source: 'standalone',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date&.to_s,
        expected_duration: @expected_duration,
        expected_insured_name: @expected_insured_name,
        expected_insured_id_number: @expected_insured_id_number,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @expected_duration = data['expected_duration']
      @expected_insured_name = data['expected_insured_name']
      @expected_insured_id_number = data['expected_insured_id_number']
      @expected_contact_phone = data['expected_contact_phone']
    end
  end
end
