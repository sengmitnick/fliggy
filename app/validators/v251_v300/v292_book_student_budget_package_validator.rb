# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例292: 预订学生特惠套餐
#
# 任务描述:
#   用户预订学生特惠套餐（学生票+青旅+优惠）
#
# 评分标准:
#   - 创建火车票预订 (30%)
#   - 创建青旅酒店预订 (30%)
#   - 总价格符合学生预算 (25%)
#   - 订单状态正确 (15%)
module V251V300
  class V292BookStudentBudgetPackageValidator < BaseValidator
    self.validator_id = 'v292_book_student_budget_package_validator'
    self.task_id = 'fd50ec27-3219-4bab-9a00-659b10b5aeb0'
    self.title = '预订学生特惠套餐'
    self.description = '用户预订学生特惠套餐（学生票+青旅+优惠）'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @destination_city = '西安'
      @travel_date = Date.today + 5.days
      @budget = 500
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 1000
        user.update!(balance: 2000)
      end
      
      {
        task: "请为学生预订从#{@departure_city}到#{@destination_city}的经济型出行套餐，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，预算#{@budget}元以内，包括火车票和青旅住宿",
        departure_city: @departure_city,
        destination_city: @destination_city,
        travel_date: @travel_date.to_s,
        budget: @budget,
        hint: "选择经济实惠的火车票和青年旅社"
      }
    end
    
    def verify
      add_assertion "创建了火车票预订", weight: 30 do
        @train_booking = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@train_booking).not_to be_nil, "未找到从#{@departure_city}到#{@destination_city}的火车票预订"
      end
      
      add_assertion "创建了青旅酒店预订", weight: 30 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到#{@destination_city}的青旅预订"
      end
      
      return unless @train_booking && @hotel_booking
      
      add_assertion "总价格符合学生预算", weight: 25 do
        total_price = @train_booking.total_price + @hotel_booking.total_price
        expect(total_price).to be <= @budget,
          "总价格超出预算。预算: #{@budget}元, 实际: #{total_price}元"
      end
      
      add_assertion "订单状态正确", weight: 15 do
        valid_statuses = ['pending', 'paid']
        expect(valid_statuses).to include(@train_booking.status),
          "火车票订单状态错误: #{@train_booking.status}"
        expect(valid_statuses).to include(@hotel_booking.status),
          "酒店订单状态错误: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
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
        passenger_name: user.name || '李学生',
        passenger_id_number: '440300200201011234',
        contact_phone: user.phone || '13800138000',
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
        guest_name: user.name || '李学生',
        guest_phone: user.phone || '13800138000',
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
        budget: @budget
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @budget = data['budget'].to_i if data['budget']
    end
  end
end
