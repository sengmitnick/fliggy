# frozen_string_literal: true

require_relative '../base_validator'

# V211: 预订长中转城市游览（中转时间5-8小时）
#
# 任务描述:
#   用户需要预订后天广州→上海→杭州航班，中转时间5-8小时可市内游览
#
# 评分标准:
#   - 创建了两段航班订单 (20%)
#   - 第一段航班路线正确（广州→上海） (10%)
#   - 第二段航班路线正确（上海→杭州） (10%)
#   - 中转时间在5-8小时区间内 (40%)
#   - 订单状态有效 (20%)
module V201V250
  class V211BookLongLayoverCityTourValidator < BaseValidator
    self.validator_id = 'v211_book_long_layover_city_tour_validator'
    self.task_id = '0fb132f5-1f1f-4f4f-ff4f-5f7a8b9c0d1f'
    self.title = '帮张三订后天从广州经上海到杭州的航班，要求在上海中转时间5-8小时，时间足够市内游览'
    self.description = '帮张三订后天从广州经上海到杭州的航班，要求在上海中转时间5-8小时，时间足够市内游览'
    self.timeout_seconds = 300
    
    def prepare
      @origin_city = '广州'
      @transfer_city = '上海'
      @destination_city = '杭州'
      @min_layover_hours = 5
      @max_layover_hours = 8
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_id_number = @passenger.id_number
      @expected_phone = @passenger.phone
      
      # 查找可用航班组合（不限定日期）
      first_flights = Flight.where(
        departure_city: @origin_city,
        destination_city: @transfer_city,
        data_version: 0
      ).to_a
      
      second_flights = Flight.where(
        departure_city: @transfer_city,
        destination_city: @destination_city,
        data_version: 0
      ).to_a
      
      # 找到符合中转时间要求的组合
      @valid_combinations = []
      first_flights.each do |f1|
        arrival_time = f1.arrival_time
        second_flights.each do |f2|
          layover_hours = (f2.departure_time - arrival_time) / 3600.0
          if layover_hours >= @min_layover_hours && layover_hours <= @max_layover_hours
            @valid_combinations << { first_flight: f1, second_flight: f2, layover_hours: layover_hours }
          end
        end
      end
      
      raise "未找到符合中转时间要求的组合" if @valid_combinations.empty?
      
      @travel_date = @valid_combinations.first[:first_flight].flight_date
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}（后天）从#{@origin_city}经#{@transfer_city}到#{@destination_city}的航班，要求在#{@transfer_city}中转时间5-8小时，可以市内游览。",
        requirements: {
          origin_city: @origin_city,
          transfer_city: @transfer_city,
          destination_city: @destination_city,
          travel_date: @travel_date,
          layover_hours: '5-8小时',
          purpose: '中转游览'
        },
        hint: "选择第一段航班到#{@transfer_city}，再选第二段航班到#{@destination_city}，确保中转时间5-8小时可以市内游览。"
      }
    end
    
    def verify
      add_assertion "创建了两段航班订单", weight: 20 do
        first_bookings = Booking
          .joins(:flight)
          .where(flights: { departure_city: @origin_city, destination_city: @transfer_city })
          .where(data_version: @data_version)
          .to_a
        
        second_bookings = Booking
          .joins(:flight)
          .where(flights: { departure_city: @transfer_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .to_a
        
        @first_booking = first_bookings.first
        @second_booking = second_bookings.first
        
        expect(@first_booking).not_to be_nil, "未找到#{@origin_city}→#{@transfer_city}的航班订单"
        expect(@second_booking).not_to be_nil, "未找到#{@transfer_city}→#{@destination_city}的航班订单"
      end
      
      return if @first_booking.nil? || @second_booking.nil?
      
      add_assertion "第一段航班路线正确（#{@origin_city}→#{@transfer_city}）", weight: 10 do
        expect(@first_booking.flight.departure_city).to eq(@origin_city)
        expect(@first_booking.flight.destination_city).to eq(@transfer_city)
      end
      
      add_assertion "第二段航班路线正确（#{@transfer_city}→#{@destination_city}）", weight: 10 do
        expect(@second_booking.flight.departure_city).to eq(@transfer_city)
        expect(@second_booking.flight.destination_city).to eq(@destination_city)
      end
      
      # 移除日期验证（数据包中日期固定）
      
      add_assertion "中转时间在5-8小时区间内", weight: 40 do
        arrival_time = @first_booking.flight.arrival_time
        departure_time = @second_booking.flight.departure_time
        layover_hours = (departure_time - arrival_time) / 3600.0
        
        expect(layover_hours).to be >= @min_layover_hours,
          "中转时间过短。期望: ≥#{@min_layover_hours}小时, 实际: #{layover_hours.round(1)}小时"
        expect(layover_hours).to be <= @max_layover_hours,
          "中转时间过长。期望: ≤#{@max_layover_hours}小时, 实际: #{layover_hours.round(1)}小时"
      end
      
      add_assertion "乘客信息正确（张三）", weight: 10 do
        expect(@first_booking.passenger_name).to eq(@expected_passenger_name),
          "第一段航班乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@first_booking.passenger_name}"
        expect(@second_booking.passenger_name).to eq(@expected_passenger_name),
          "第二段航班乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@second_booking.passenger_name}"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@first_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@second_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择中转时间接近6小时的组合（5-8小时中间值）
      best_combo = @valid_combinations.min_by { |c| (c[:layover_hours] - 6.5).abs }
      
      Booking.create!(
        user: user,
        flight: best_combo[:first_flight],
        passenger_name: @expected_passenger_name,
        passenger_id_number: @expected_id_number,
        contact_phone: @expected_phone,
        total_price: best_combo[:first_flight].price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      Booking.create!(
        user: user,
        flight: best_combo[:second_flight],
        passenger_name: @expected_passenger_name,
        passenger_id_number: @expected_id_number,
        contact_phone: @expected_phone,
        total_price: best_combo[:second_flight].price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        origin_city: @origin_city,
        transfer_city: @transfer_city,
        destination_city: @destination_city,
        travel_date: @travel_date.to_s,
        min_layover_hours: @min_layover_hours,
        max_layover_hours: @max_layover_hours,
        expected_passenger_name: @expected_passenger_name,
        expected_id_number: @expected_id_number,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      @origin_city = data['origin_city']
      @transfer_city = data['transfer_city']
      @destination_city = data['destination_city']
      @travel_date = Date.parse(data['travel_date'])
      @min_layover_hours = data['min_layover_hours']
      @max_layover_hours = data['max_layover_hours']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_id_number = data['expected_id_number']
      @expected_phone = data['expected_phone']
      
      first_flights = Flight.where(
        departure_city: @origin_city,
        destination_city: @transfer_city,
        data_version: 0
      ).to_a
      
      second_flights = Flight.where(
        departure_city: @transfer_city,
        destination_city: @destination_city,
        data_version: 0
      ).to_a
      
      @valid_combinations = []
      first_flights.each do |f1|
        arrival_time = f1.arrival_time
        second_flights.each do |f2|
          layover_hours = (f2.departure_time - arrival_time) / 3600.0
          if layover_hours >= @min_layover_hours && layover_hours <= @max_layover_hours
            @valid_combinations << { first_flight: f1, second_flight: f2, layover_hours: layover_hours }
          end
        end
      end
    end
  end
end
