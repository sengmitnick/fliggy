# frozen_string_literal: true

require_relative '../base_validator'

# V226: 预订学生预算（总预算≤300元）
#
# 任务描述:
#   用户需要预订学生出行（火车票+经济酒店），总预算≤300元
#
# 评分标准:
#   - 创建了火车票订单 (25%)
#   - 创建了酒店订单 (25%)
#   - 总价格≤300元 (30%)
#   - 订单状态有效 (20%)
module V201V250
  class V226BookStudentBudgetUnder300Validator < BaseValidator
    self.validator_id = 'v226_book_student_budget_under_300_validator'
    self.task_id = '3ff354ff-4f4f-4f6f-6f7f-5f8a9b0c1d2f'
    self.title = '预订学生预算（≤300元）'
    self.description = '用户需要预订学生出行（火车票+经济酒店），总预算≤300元'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '广州'
      @arrival_city = '深圳'
      @max_budget = 300
      
      @available_trains = Train.by_route(@departure_city, @arrival_city)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0)
        .order(price: :asc)
      
      raise "未找到火车或酒店" if @available_trains.empty? || @available_hotels.empty?
      
      @travel_date = @available_trains.first.departure_time.to_date
      @check_in_date = @travel_date
      @check_out_date = @check_in_date + 1.day
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@arrival_city}的学生出行，包括火车票和经济型酒店1晚，总预算≤#{@max_budget}元。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          travel_date: @travel_date,
          max_budget: "≤#{@max_budget}元",
          purpose: '学生经济出行'
        },
        hint: "选择最便宜的火车票和酒店，总价≤#{@max_budget}元。"
      }
    end
    
    def verify
      add_assertion "创建了火车票订单", weight: 25 do
        @train_booking = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .first
        
        expect(@train_booking).not_to be_nil, "未找到火车票订单"
      end
      
      return if @train_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 25 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "总价格≤#{@max_budget}元", weight: 30 do
        train_price = @train_booking.total_price
        hotel_price = @hotel_booking.total_price
        total_price = train_price + hotel_price
        
        expect(total_price).to be <= @max_budget,
          "总价格超出学生预算。火车票: #{train_price}元, 酒店: #{hotel_price}元, 总计: #{total_price}元, 预算上限: #{@max_budget}元"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@train_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找到预算内最便宜的组合
      best_combo = nil
      
      @available_trains.first(3).each do |train|
        @available_hotels.first(5).each do |hotel|
          room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
          next unless room
          
          total = train.price_second_class + room.price
          next if total > @max_budget
          
          best_combo = { train: train, hotel: hotel, room: room }
          break if best_combo
        end
        break if best_combo
      end
      
      raise "未找到符合学生预算的组合" if best_combo.nil?
      
      TrainBooking.create!(
        user: user,
        train: best_combo[:train],
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        seat_type: 'second_class',
        ticket_count: 1,
        total_price: best_combo[:train].price_second_class,
        status: 'paid',
        accept_terms: true,
        data_version: @data_version
      )
      
      HotelBooking.create!(
        user: user,
        hotel: best_combo[:hotel],
        hotel_room: best_combo[:room],
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name,
        guest_phone: '13800138000',
        room_count: 1,
        total_price: best_combo[:room].price,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        max_budget: @max_budget
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @max_budget = data['max_budget']
      
      @available_trains = Train.by_route(@departure_city, @arrival_city)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0)
        .order(price: :asc)
    end
  end
end
