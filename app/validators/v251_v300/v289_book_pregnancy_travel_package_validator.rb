# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例289: 给王芳预订孕妇出行套餐（北京→三亚，5天后出发，航班+境内旅游险3天）
# 
# 任务描述:
#   王芳（孕妇）计划从北京飞往三亚旅行，需要预订航班并购买医疗保障服务。
#   Agent 需要完成航班预订和境内旅游险（医疗保障）的组合购买。
# 
# 业务流程（6个关键步骤）：
#   1. 搜索从北京到三亚的航班（5天后出发）
#   2. 选择舒适座位的航班（适合孕妇）
#   3. 填写乘机人信息（王芳）并创建航班预订
#   4. 搜索境内旅游险产品（product_type='domestic'）
#   5. 设置保险日期（出发日期开始，覆盖旅行期间）
#   6. 填写被保人信息（王芳）并创建保险订单
# 
# 复杂度分析（8个关键点）：
#   1. 需要理解城市筛选：北京出发、三亚到达的航班
#   2. 需要理解日期计算：departure_date=5天后
#   3. 需要理解乘机人信息：使用乘客信息中的王芳
#   4. 需要理解组合购买：航班预订（Booking）+ 境内旅游险（InsuranceOrder）两个订单
#   5. 需要理解保险日期对齐：start_date=出发日期、end_date=出发日期+3天（覆盖旅行期间）
#   6. 需要理解被保人信息：insured_persons 包含王芳的姓名和身份证号
#   7. 需要理解数据隔离：两个订单都必须使用 data_version=@data_version
#   8. 需要理解孕妇特殊需求：选择舒适座位、购买医疗保障（体现关怀）
#   ❌ 不能随机选择：必须精确选择指定日期的航班、保险日期必须对齐出发日期
# 
# 评分标准（7项，总计100分）：
#   - 创建航班预订（20%）
#   - 乘机人信息正确（王芳）（15%）
#   - 航班出发日期正确（5天后）（10%）
#   - 创建境内旅游险（20%）
#   - 保险被保人信息正确（王芳）（15%）
#   - 保险起止日期正确（出发日期开始，3天保障期）（10%）
#   - 订单状态正确（pending/paid）（10%）
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v289_book_pregnancy_travel_package_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V251V300
  class V289BookPregnancyTravelPackageValidator < BaseValidator
    self.validator_id = 'v289_book_pregnancy_travel_package_validator'
    self.task_id = 'd4278542-8379-49b9-8095-63846c0c97ab'
    self.title = '给王芳预订孕妇出行套餐（北京→三亚，5天后出发，航班+境内旅游险3天）'
    self.description = '给王芳（孕妇）预订从北京到三亚的航班+境内旅游险（医疗保障）'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @destination_city = '三亚'
      @departure_date = Date.current + 5.days  # 5天后出发
      
      # 预查询乘客信息（王芳）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_passenger_name = @wangfang.name
      @expected_contact_phone = @wangfang.phone
      
      # 确保用户余额充足
      if user.balance < 3000
        user.update!(balance: 5000)
      end
      
      # 返回给 Agent 的任务信息
      @insurance_days = 3  # 保险保障期3天
      @insurance_type = 'domestic'  # 境内旅游险
      
      {
        task: "请给王芳（孕妇）预订从#{@departure_city}到#{@destination_city}的孕妇友好航班，#{@departure_date.strftime('%Y年%-m月%-d日')}（5天后）出发，需要舒适座位和医疗保障服务。预订航班后，务必购买#{@insurance_days}天的境内旅游险（从出发日期#{@departure_date.strftime('%Y年%-m月%-d日')}开始）。",
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date.to_s,
        passenger_name: @expected_passenger_name,
        insurance_type: @insurance_type,
        insurance_days: @insurance_days,
        insurance_start_date: @departure_date.to_s,
        hint: "先预订航班，然后购买境内旅游险（产品类型：境内旅游险/domestic，保险期：#{@insurance_days}天，从#{@departure_date.strftime('%Y-%m-%d')}开始）"
      }
    end
    
    def verify
      # 断言1: 创建航班预订（20分）
      # 作用: 查询本次会话的航班预订记录，确保预订成功
      # 查询逻辑: 
      #   - 必须包含 data_version: @data_version（会话隔离）
      #   - 通过 joins(:flight) 关联查询，筛选北京→三亚的航班
      #   - 按创建时间倒序，获取最新的预订
      add_assertion "创建了航班预订", weight: 20 do
        @booking = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@booking).not_to be_nil, "未找到从#{@departure_city}到#{@destination_city}的航班预订"
      end
      
      return unless @booking  # 保护后续断言
      
      # 断言2: 乘机人信息正确（王芳）（15分）
      # 作用: 验证乘机人姓名和联系电话是否正确
      add_assertion "乘机人信息正确（#{@expected_passenger_name}）", weight: 15 do
        expect(@booking.passenger_name).to eq(@expected_passenger_name),
          "乘机人姓名错误。期望: #{@expected_passenger_name}（王芳），实际: #{@booking.passenger_name}"
        expect(@booking.contact_phone).to eq(@expected_contact_phone),
          "乘机人联系电话错误。期望: #{@expected_contact_phone}（王芳手机号），实际: #{@booking.contact_phone}"
      end
      
      # 断言3: 航班出发日期正确（5分）
      # 作用: 验证航班出发日期是否为5天后
      add_assertion "航班出发日期正确（#{@departure_date}）", weight: 5 do
        flight = @booking.flight
        booking_date = flight.departure_time.to_date
        expect(booking_date).to eq(@departure_date),
          "航班出发日期错误。期望: #{@departure_date.strftime('%Y-%m-%d')}（5天后），实际: #{booking_date.strftime('%Y-%m-%d')}"
      end
      
      # 断言4: 创建境内旅游险（20分）
      # 作用: 查询本次会话的保险订单记录，确保购买保险
      # 查询逻辑: 
      #   - 必须包含 data_version: @data_version（会话隔离）
      #   - 按创建时间倒序，获取最新的保险订单
      add_assertion "创建了境内旅游险", weight: 20 do
        @insurance = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@insurance).not_to be_nil, "未找到境内旅游险订单"
      end
      
      return unless @insurance  # 保护后续断言
      
      # 断言5: 保险被保人信息正确（王芳）（15分）
      # 作用: 验证保险被保人姓名是否正确
      # 验证逻辑:
      #   - 检查 insured_persons 字段是否非空
      #   - 支持 Array 或单个对象格式
      #   - 提取第一个被保人的姓名进行验证
      add_assertion "保险被保人信息正确（#{@expected_passenger_name}）", weight: 15 do
        insured_persons = @insurance.insured_persons
        expect(insured_persons).to be_present, "被保人信息为空"
        
        # 兼容数组和单个对象格式
        first_person = insured_persons.is_a?(Array) ? insured_persons.first : insured_persons
        person_name = first_person.is_a?(Hash) ? first_person['name'] || first_person[:name] : first_person.name
        
        expect(person_name).to eq(@expected_passenger_name),
          "被保人姓名错误。期望: #{@expected_passenger_name}（王芳），实际: #{person_name}"
      end
      
      # 断言6: 保险目的地城市正确（三亚）（10分）
      # 作用: 验证保险目的地是否为旅行目的地（三亚），而非出发地
      add_assertion "保险目的地城市正确（#{@destination_city}）", weight: 10 do
        expect(@insurance.destination).to eq(@destination_city),
          "保险目的地城市错误。期望: #{@destination_city}（旅行目的地），实际: #{@insurance.destination}"
        expect(@insurance.destination_type).to eq('domestic'),
          "保险类型错误。期望: domestic（境内），实际: #{@insurance.destination_type}"
      end
      
      # 断言7: 保险起止日期正确（10分）
      # 作用: 验证保险日期是否从出发日期开始，覆盖3天旅行期间
      add_assertion "保险起止日期正确（#{@departure_date}开始，3天保障期）", weight: 10 do
        expect(@insurance.start_date).to eq(@departure_date),
          "保险开始日期错误。期望: #{@departure_date.strftime('%Y-%m-%d')}（出发日期），实际: #{@insurance.start_date.strftime('%Y-%m-%d')}"
        
        expected_end_date = @departure_date + 2.days
        expect(@insurance.end_date).to eq(expected_end_date),
          "保险结束日期错误。期望: #{expected_end_date.strftime('%Y-%m-%d')}（覆盖3天：起始日+2天），实际: #{@insurance.end_date.strftime('%Y-%m-%d')}"
      end
      
      # 断言8: 订单状态正确（5分）
      # 作用: 验证航班订单状态是否有效
      add_assertion "订单状态正确（pending/paid）", weight: 5 do
        valid_statuses = ['pending', 'paid']
        expect(valid_statuses).to include(@booking.status),
          "航班订单状态错误。期望: pending 或 paid，实际: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # 1. 预订航班（选择指定日期的航班）
      flight = Flight
        .where(departure_city: @departure_city, destination_city: @destination_city, data_version: 0)
        .by_date(@departure_date)
        .first!
      
      Booking.create!(
        user_id: user.id,
        flight_id: flight.id,
        passenger_name: wangfang.name,
        contact_phone: wangfang.phone,
        passenger_id_number: wangfang.id_number,
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 购买境内旅游险（从出发日期开始，覆盖3天）
      # 选择 product_type='domestic' 的境内旅游险
      insurance_product = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .order(price_per_day: :asc)
        .first!
      InsuranceOrder.create!(
        user_id: user.id,
        insurance_product_id: insurance_product.id,
        start_date: @departure_date,
        end_date: @departure_date + 2.days,
        days: 3,
        destination: @destination_city,
        destination_type: 'domestic',
        insured_persons: [{ name: wangfang.name, id_number: wangfang.id_number }],
        unit_price: insurance_product.price_per_day,
        quantity: 1,
        total_price: insurance_product.price_per_day * 3,
        status: 'paid',
        source: 'standalone',
        data_version: @data_version
      )
    end
    
    private
    
    # 保存执行状态数据
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date&.to_s,
        insurance_type: @insurance_type,
        insurance_days: @insurance_days,
        expected_passenger_name: @expected_passenger_name,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    # 从状态恢复实例变量
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @departure_date = Date.parse(data['departure_date']) if data['departure_date']
      @insurance_type = data['insurance_type']
      @insurance_days = data['insurance_days']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_contact_phone = data['expected_contact_phone']
    end
  end
end
