# frozen_string_literal: true

require_relative '../base_validator'

# V225: 预订豪华套餐（总价≥3000元）
#
# 任务描述:
#   用户需要预订豪华套餐（高端航班+高星酒店），总价≥3000元
#
# 评分标准:
#   - 创建了航班订单 (20%)
#   - 创建了酒店订单 (20%)
#   - 总价格≥3000元 (40%)
#   - 订单状态有效 (20%)
module V201V250
  class V225BookLuxuryPackageOver3000Validator < BaseValidator
    self.validator_id = 'v225_book_luxury_package_over_3000_validator'
    self.task_id = '2ff243ff-3f3f-3f5f-5f6f-4f7a8b9c0d1f'
    self.title = '预订豪华套餐（≥3000元）'
    self.description = '用户需要预订豪华套餐（高端航班+高星酒店），总价≥3000元'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @arrival_city = '三亚'
      @flight_date = Date.current + 5.days
      @check_in_date = @flight_date
      @check_out_date = @check_in_date + 2.days
      @min_total_price = 3000
      
      # 查找高端航班（价格较高的）
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).order(price: :desc)
      
      # 查找高星酒店（价格较高的）
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0)
        .order(price: :desc)
      
      raise "未找到高端航班或酒店" if @available_flights.empty? || @available_hotels.empty?
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@arrival_city}的豪华套餐，包括高端航班和高星酒店2晚，总价要求≥#{@min_total_price}元。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date,
          min_total_price: "≥#{@min_total_price}元",
          purpose: '豪华高端出行'
        },
        hint: "选择高端航班和高星酒店，总价≥#{@min_total_price}元。"
      }
    end
    
    def verify
      add_assertion "创建了航班订单", weight: 20 do
        @flight_booking = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .first
        
        expect(@flight_booking).not_to be_nil, "未找到航班订单"
      end
      
      return if @flight_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 20 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "总价格≥#{@min_total_price}元", weight: 40 do
        flight_price = @flight_booking.total_price
        hotel_price = @hotel_booking.total_price
        total_price = flight_price + hotel_price
        
        expect(total_price).to be >= @min_total_price,
          "总价格未达到豪华标准。航班: #{flight_price}元, 酒店: #{hotel_price}元, 总计: #{total_price}元, 要求: ≥#{@min_total_price}元"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找到总价≥3000的组合（优先选择接近3000的）
      best_combo = nil
      best_excess = Float::INFINITY
      
      @available_flights.first(5).each do |flight|
        @available_hotels.first(5).each do |hotel|
          room = hotel.hotel_rooms.where(data_version: 0).first
          next unless room
          
          total = flight.price + (room.price * 2)
          next if total < @min_total_price
          
          excess = total - @min_total_price
          if excess < best_excess
            best_combo = { flight: flight, hotel: hotel, room: room }
            best_excess = excess
          end
        end
      end
      
      raise "未找到符合要求的豪华组合" if best_combo.nil?
      
      Booking.create!(
        user: user,
        flight: best_combo[:flight],
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: best_combo[:flight].price,
        accept_terms: true,
        status: 'paid',
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
        total_price: best_combo[:room].price * 2,
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
        flight_date: @flight_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        min_total_price: @min_total_price
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @flight_date = Date.parse(data['flight_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @min_total_price = data['min_total_price']
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).order(price: :desc)
      
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0)
        .order(price: :desc)
    end
  end
end
