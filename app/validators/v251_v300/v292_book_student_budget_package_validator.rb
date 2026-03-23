# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例292: 帮张三预订5天后北京→西安学生特惠套餐（火车票+青旅，总价≤500元）
#
# 任务描述:
#   张三是学生，需要预订5天后从北京到西安的经济出行套餐，总预算只有500元。
#   需要预订最便宜的火车票（二等座）和经济型青年旅社住宿。
#   Agent 需要创建1个火车票订单和1个酒店订单，确保总价格不超过预算，选择最经济的出行方案。
#
# 业务流程（8个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为乘客和入住人信息）
#   2. 搜索北京→西安火车（5天后出发）
#   3. 选择最便宜的火车票（按二等座价格升序排序）
#   4. 创建火车票订单（使用张三的乘客信息，座位类型=二等座）
#   5. 搜索西安市区经济型酒店（按价格升序排序）
#   6. 选择最便宜的青年旅社或经济型酒店
#   7. 计算入住天数（确保火车票+酒店总价≤500元预算）
#   8. 创建酒店订单（使用张三的入住人信息）
#
# 复杂度分析（8个关键点）：
#   1. 需要理解预算限制场景：总价格不能超过500元（火车票+酒店）
#   2. 需要明确火车路线（北京→西安，5天后出发）
#   3. 需要选择最便宜的二等座火车票（price_second_class 升序）
#   4. 需要使用受益人信息作为火车乘客和酒店入住人
#   5. 需要明确酒店城市（西安，到达城市）
#   6. 需要选择最便宜的经济型酒店（price 升序）
#   7. 需要理解价格优化逻辑：如果火车票+2晚酒店超过预算，则只住1晚
#   8. 需要验证总价格是否在预算范围内（火车票价格 + 酒店价格 ≤ 500元）
#   ❌ 不能随机选择：必须选择最便宜的火车和酒店组合，确保总价在预算内
#
# 评分标准（5项，总计100分）：
#   1. 创建了火车票预订（25分）
#   2. 创建了青旅酒店预订（25分）
#   3. 乘客信息正确（张三的姓名、身份证号、电话）（15分）
#   4. 总价格符合学生预算（≤500元）（20分）
#   5. 订单状态正确（fire车票和酒店订单状态均为 pending/paid/confirmed）（15分）
#
# 使用方法:
#   rake validator:simulate_single[v292_book_student_budget_package_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V251V300
  class V292BookStudentBudgetPackageValidator < BaseValidator
    self.validator_id = 'v292_book_student_budget_package_validator'
    self.task_id = 'fd50ec27-3219-4bab-9a00-659b10b5aeb0'
    self.title = '帮张三预订5天后北京→西安学生特惠套餐（火车票+青旅，总价≤500元）'
    self.description = '帮张三预订5天后北京→西安学生特惠套餐（火车票+青旅，总价≤500元）'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @destination_city = '西安'
      @travel_date = Date.current + 5.days
      @budget = 500
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @zhangsan.name
      @expected_passenger_id_number = @zhangsan.id_number
      @expected_contact_phone = @zhangsan.phone
      
      if user.balance < 1000
        user.update!(balance: 2000)
      end
      
      {
        title: "今天是#{Date.current.strftime('%Y年%m月%d日')}。帮张三预订5天后北京→西安学生特惠套餐（火车票+青旅，总价≤500元）",
        description: "帮张三预订5天后北京→西安学生特惠套餐（火车票+青旅，总价≤500元）",
        departure_city: @departure_city,
        destination_city: @destination_city,
        travel_date: @travel_date.to_s,
        budget: @budget
      }
    end
    
    def verify
      add_assertion "创建了火车票预订", weight: 25 do
        @train_booking = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@train_booking).not_to be_nil, "未找到从#{@departure_city}到#{@destination_city}的火车票预订"
      end
      
      return unless @train_booking
      
      add_assertion "创建了青旅酒店预订", weight: 25 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到#{@destination_city}的青旅预订"
      end
      
      add_assertion "乘客信息正确（张三）", weight: 15 do
        expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
          "火车票乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
        expect(@train_booking.passenger_id_number).to eq(@expected_passenger_id_number),
          "火车票乘客身份证号错误。期望: #{@expected_passenger_id_number}, 实际: #{@train_booking.passenger_id_number}"
        expect(@train_booking.contact_phone).to eq(@expected_contact_phone),
          "火车票联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@train_booking.contact_phone}"
      end
      
      return unless @hotel_booking
      
      add_assertion "总价格符合学生预算（≤#{@budget}元）", weight: 20 do
        total_price = @train_booking.total_price + @hotel_booking.total_price
        expect(total_price).to be <= @budget,
          "总价格超出预算。预算: #{@budget}元, 实际: #{total_price}元（火车票#{@train_booking.total_price}元 + 酒店#{@hotel_booking.total_price}元）"
      end
      
      add_assertion "订单状态正确", weight: 15 do
        valid_train_statuses = ['pending', 'paid', 'confirmed']
        valid_hotel_statuses = ['pending', 'paid', 'confirmed']
        
        expect(valid_train_statuses).to include(@train_booking.status),
          "火车票订单状态错误: #{@train_booking.status}"
        expect(valid_hotel_statuses).to include(@hotel_booking.status),
          "酒店订单状态错误: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 1. 预订火车票（二等座，价格低）
      train = Train.where(
        departure_city: @departure_city,
        arrival_city: @destination_city,
        data_version: 0
      ).order(price_second_class: :asc).first!
      
      train_price = train.price_second_class || 150
      
      # 2. 预订青旅（经济型酒店）
      hotel = Hotel.where(city: @destination_city, data_version: 0)
        .order(price: :asc)
        .first!
      
      hotel_price_per_night = hotel.price
      
      # 确保总价在预算内，如果超出，只住1晚
      nights = (train_price + hotel_price_per_night * 2 > @budget) ? 1 : 2
      check_out_date = @travel_date + nights.days
      total_hotel_price = hotel_price_per_night * nights
      
      TrainBooking.create!(
        user_id: user.id,
        train_id: train.id,
        passenger_name: zhangsan.name,
        passenger_id_number: zhangsan.id_number,
        contact_phone: zhangsan.phone,
        seat_type: 'second_class',
        ticket_count: 1,
        total_price: train_price,
        status: 'paid',
        accept_terms: true,
        insurance_type: 'none',
        data_version: @data_version
      )
      
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 1,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @travel_date,
        check_out_date: check_out_date,
        guest_name: zhangsan.name,
        guest_phone: zhangsan.phone,
        payment_method: '花呗',
        total_price: total_hotel_price,
        status: 'pending',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        travel_date: @travel_date&.to_s,
        budget: @budget,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id_number: @expected_passenger_id_number,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @budget = data['budget'].to_i if data['budget']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id_number = data['expected_passenger_id_number']
      @expected_contact_phone = data['expected_contact_phone']
    end
  end
end
