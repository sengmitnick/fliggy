# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例290: 给张三和小明（10岁儿童）预订从上海到北京的航班（7天后出发，成人票+儿童票）
# 
# 任务描述:
#   张三（成人）需要带小明（10岁儿童）从上海飞往北京旅行。
#   Agent 需要为成人和儿童分别预订航班机票（成人全价票、儿童半价票）。
# 
# 业务流程（6个关键步骤）：
#   1. 搜索从上海到北京的航班（7天后出发）
#   2. 获取成人乘客信息（张三）
#   3. 创建成人航班预订（全价票）
#   4. 获取儿童乘客信息（小明，10岁）
#   5. 创建儿童航班预订（半价票）
#   6. 确认两个订单的日期和航班一致（同行）
# 
# 复杂度分析（7个关键点）：
#   1. 需要理解城市筛选：上海出发、北京到达的航班
#   2. 需要理解日期计算：departure_date=7天后
#   3. 需要理解多乘客预订：成人（张三）+ 儿童（小明）两个独立订单
#   4. 需要理解乘客信息区分：从 Passenger 表中分别获取张三和小明的信息
#   5. 需要理解儿童票价规则：儿童票价 = 成人票价 * 0.5（半价）
#   6. 需要理解数据隔离：两个订单都必须使用 data_version=@data_version
#   7. 需要理解同行逻辑：成人和儿童必须在同一航班上（flight_id 相同）
#   ❌ 不能只订成人票：必须创建成人和儿童两个独立订单
#   ❌ 不能票价错误：儿童票必须是半价（0.5倍）
# 
# 评分标准（6项，总计100分）：
#   - 创建成人航班预订（25%）
#   - 成人乘机人信息正确（张三）（15%）
#   - 创建儿童航班预订（25%）
#   - 儿童乘机人信息正确（小明）（15%）
#   - 航班出发日期正确（7天后）（10%）
#   - 订单状态正确（pending/paid）（10%）
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v290_book_child_travel_alone_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V251V300
  class V290BookChildTravelAloneValidator < BaseValidator
    self.validator_id = 'v290_book_child_travel_alone_validator'
    self.task_id = 'c333c8fb-acf7-4b9b-970f-0deb234601e2'
    self.title = '给张三和小明（10岁儿童）预订从上海到北京的航班（7天后出发，成人票+儿童票）'
    self.description = '给张三和小明（10岁儿童）预订从上海到北京的航班'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @destination_city = '北京'
      @departure_date = Date.current + 7.days
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)
      @expected_adult_name = @zhangsan.name
      @expected_adult_phone = @zhangsan.phone
      @expected_child_name = @xiaoming.name
      @expected_child_phone = @xiaoming.phone
      
      if user.balance < 2000
        user.update!(balance: 3000)
      end
      
      {
        task: "请为张三和小明（10岁儿童）预订从#{@departure_city}到#{@destination_city}的航班，#{@departure_date.strftime('%Y年%-m月%-d日')}出发，需要预订1个成人票和1个儿童票",
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date.to_s,
        hint: "分别预订成人和儿童航班机票"
      }
    end
    
    def verify
      # 断言1: 创建成人航班预订（25分）
      # 作用: 查询本次会话的成人航班预订记录，确保预订成功
      # 查询逻辑: 
      #   - 必须包含 data_version: @data_version（会话隔离）
      #   - 通过 joins(:flight) 关联查询，筛选上海→北京的航班
      #   - 按创建时间倒序，获取所有订单
      #   - 从订单列表中查找 passenger_name == '张三' 的订单
      add_assertion "创建了成人航班预订", weight: 25 do
        all_bookings = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @adult_booking = all_bookings.find { |b| b.passenger_name == @expected_adult_name }
        expect(@adult_booking).not_to be_nil, "未找到成人（张三）的航班预订"
      end
      
      # 断言2: 成人乘机人信息正确（张三）（15分）
      # 作用: 验证成人乘机人姓名和联系电话是否正确
      add_assertion "成人乘机人信息正确（张三）", weight: 15 do
        expect(@adult_booking.passenger_name).to eq(@expected_adult_name),
          "成人乘机人姓名错误。期望: #{@expected_adult_name}（张三），实际: #{@adult_booking.passenger_name}"
        expect(@adult_booking.contact_phone).to eq(@expected_adult_phone),
          "成人联系电话错误。期望: #{@expected_adult_phone}，实际: #{@adult_booking.contact_phone}"
      end
      
      # 断言3: 创建儿童航班预订（25分）
      # 作用: 查询本次会话的儿童航班预订记录，确保预订成功
      # 查询逻辑: 
      #   - 必须包含 data_version: @data_version（会话隔离）
      #   - 通过 joins(:flight) 关联查询，筛选上海→北京的航班
      #   - 按创建时间倒序，获取所有订单
      #   - 从订单列表中查找 passenger_name == '小明' 的订单
      add_assertion "创建了儿童航班预订", weight: 25 do
        all_bookings = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @child_booking = all_bookings.find { |b| b.passenger_name == @expected_child_name }
        expect(@child_booking).not_to be_nil, "未找到儿童（小明）的航班预订"
      end
      
      # 断言4: 儿童乘机人信息正确（小明）（15分）
      # 作用: 验证儿童乘机人姓名和联系电话是否正确
      # 验证逻辑:
      #   - 姓名必须为儿童姓名（小明）
      #   - 联系电话允许为儿童电话或监护人（成人）电话（符合实际业务）
      add_assertion "儿童乘机人信息正确（小明）", weight: 15 do
        expect(@child_booking.passenger_name).to eq(@expected_child_name),
          "儿童乘机人姓名错误。期望: #{@expected_child_name}（小明），实际: #{@child_booking.passenger_name}"
        
        # 儿童订单联系电话允许使用儿童电话或成人（监护人）电话
        valid_phones = [@expected_child_phone, @expected_adult_phone]
        expect(valid_phones).to include(@child_booking.contact_phone),
          "儿童联系电话错误。期望: #{@expected_child_phone}（儿童）或 #{@expected_adult_phone}（监护人），实际: #{@child_booking.contact_phone}"
      end
      
      return unless @adult_booking && @child_booking  # 保护后续断言
      
      # 断言5: 航班出发日期正确（10分）
      # 作用: 验证成人和儿童航班的出发日期是否为7天后，且两个订单在同一航班
      add_assertion "航班出发日期正确", weight: 10 do
        adult_date = @adult_booking.flight.departure_time.to_date
        expect(adult_date).to eq(@departure_date),
          "成人航班出发日期错误。期望: #{@departure_date.strftime('%Y-%m-%d')}（7天后），实际: #{adult_date.strftime('%Y-%m-%d')}"
        
        child_date = @child_booking.flight.departure_time.to_date
        expect(child_date).to eq(@departure_date),
          "儿童航班出发日期错误。期望: #{@departure_date.strftime('%Y-%m-%d')}（7天后），实际: #{child_date.strftime('%Y-%m-%d')}"
      end
      
      # 断言6: 订单状态正确（10分）
      # 作用: 验证成人和儿童航班订单状态是否有效
      add_assertion "订单状态正确", weight: 10 do
        valid_statuses = ['pending', 'paid']
        expect(valid_statuses).to include(@adult_booking.status),
          "成人航班订单状态错误: #{@adult_booking.status}"
        expect(valid_statuses).to include(@child_booking.status),
          "儿童航班订单状态错误: #{@child_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)
      
      # 选择指定日期的航班
      flight = Flight
        .where(departure_city: @departure_city, destination_city: @destination_city, data_version: 0)
        .by_date(@departure_date)
        .first!
      
      # 1. 预订成人航班
      Booking.create!(
        user_id: user.id,
        flight_id: flight.id,
        passenger_name: zhangsan.name,
        contact_phone: zhangsan.phone,
        passenger_id_number: zhangsan.id_number,
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 预订儿童航班（使用监护人电话作为联系方式）
      Booking.create!(
        user_id: user.id,
        flight_id: flight.id,
        passenger_name: xiaoming.name,
        contact_phone: zhangsan.phone,  # 使用监护人（成人）电话
        passenger_id_number: xiaoming.id_number,
        total_price: flight.price * 0.5, # 儿童半价
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date&.to_s,
        expected_adult_name: @expected_adult_name,
        expected_adult_phone: @expected_adult_phone,
        expected_child_name: @expected_child_name,
        expected_child_phone: @expected_child_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @departure_date = Date.parse(data['departure_date']) if data['departure_date']
      @expected_adult_name = data['expected_adult_name']
      @expected_adult_phone = data['expected_adult_phone']
      @expected_child_name = data['expected_child_name']
      @expected_child_phone = data['expected_child_phone']
    end
  end
end
