# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例292: 给张三预订学生特惠套餐（北京-西安）
#
# 任务描述:
#   给张三预订5天后从北京到西安的学生特惠套餐，预算500元内，包括火车票和青旅
#
# 评分标准:
#   - 创建火车票预订 (25%)
#   - 创建青旅酒店预订 (25%)
#   - 乘客信息正确（张三）(15%)
#   - 总价格符合学生预算 (20%)
#   - 订单状态正确 (15%)
module V251V300
  class V292BookStudentBudgetPackageValidator < BaseValidator
    self.validator_id = 'v292_book_student_budget_package_validator'
    self.task_id = 'fd50ec27-3219-4bab-9a00-659b10b5aeb0'
    self.title = '帮张三订5天后从北京到西安的学生套餐，他预算只有500块，需要火车票和青旅住宿'
    self.description = '帮张三订5天后从北京到西安的学生套餐，他预算只有500块，需要火车票和青旅住宿'
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
        task: "请为张三预订从#{@departure_city}到#{@destination_city}的学生特惠套餐，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，预算#{@budget}元以内，包括火车票和青旅住宿",
        departure_city: @departure_city,
        destination_city: @destination_city,
        travel_date: @travel_date.to_s,
        budget: @budget,
        hint: "选择最便宜的火车票和青年旅社，确保总价在预算内"
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
