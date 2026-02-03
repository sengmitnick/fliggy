# frozen_string_literal: true

require_relative '../base_validator'

# V210: 预订快速中转（航班转火车，中转时间≤3小时）
#
# 任务描述:
#   用户需要预订明天深圳→北京→天津，航班转火车，中转时间≤3小时
#
# 评分标准:
#   - 创建了航班和火车票订单 (20%)
#   - 第一段航班路线正确（深圳→北京） (10%)
#   - 第二段火车路线正确（北京→天津） (10%)
#   - 出发日期正确（明天） (10%)
#   - 中转时间≤3小时且衔接合理 (30%)
#   - 订单状态有效 (20%)
module V201V250
  class V210BookQuickConnectionTransferValidator < BaseValidator
    self.validator_id = 'v210_book_quick_connection_transfer_validator'
    self.task_id = '9fa021f4-0f0f-4f3f-ff3f-4f6a7b8c9d0f'
    self.title = '预订快速中转（航班转火车≤3小时）'
    self.description = '用户需要预订明天深圳→北京→天津，航班转火车，中转时间≤3小时'
    self.timeout_seconds = 300
    
    def prepare
      @origin_city = '深圳'
      @transfer_city = '北京'
      @destination_city = '天津'
      @travel_date = Date.today + 1.day
      @max_transfer_hours = 3
      
      # 查找可用航班和火车组合
      flights = Flight.where(
        departure_city: @origin_city,
        destination_city: @transfer_city,
        flight_date: @travel_date,
        data_version: 0
      ).to_a
      
      trains = Train.by_route(@transfer_city, @destination_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .to_a
      
      # 找到符合中转时间要求的组合
      @valid_combinations = []
      flights.each do |flight|
        arrival_time = flight.arrival_time
        trains.each do |train|
          transfer_hours = (train.departure_time - arrival_time) / 3600.0
          if transfer_hours >= 1 && transfer_hours <= @max_transfer_hours
            @valid_combinations << { flight: flight, train: train, transfer_hours: transfer_hours }
          end
        end
      end
      
      raise "未找到符合中转时间要求的组合" if @valid_combinations.empty?
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}（明天）从#{@origin_city}经#{@transfer_city}到#{@destination_city}的行程，要求航班转火车中转时间≤3小时，紧凑衔接。",
        requirements: {
          origin_city: @origin_city,
          transfer_city: @transfer_city,
          destination_city: @destination_city,
          travel_date: @travel_date,
          max_transfer_hours: "≤#{@max_transfer_hours}小时",
          purpose: '快速中转'
        },
        hint: "先订航班到#{@transfer_city}，再订火车到#{@destination_city}，确保中转时间在1-3小时之间。"
      }
    end
    
    def verify
      add_assertion "创建了航班和火车票订单", weight: 20 do
        flight_bookings = Booking
          .joins(:flight)
          .where(flights: { departure_city: @origin_city, destination_city: @transfer_city })
          .where(data_version: @data_version)
          .to_a
        
        train_bookings = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @transfer_city, arrival_city: @destination_city })
          .where(data_version: @data_version)
          .to_a
        
        @flight_booking = flight_bookings.first
        @train_booking = train_bookings.first
        
        expect(@flight_booking).not_to be_nil, "未找到#{@origin_city}→#{@transfer_city}的航班订单"
        expect(@train_booking).not_to be_nil, "未找到#{@transfer_city}→#{@destination_city}的火车票订单"
      end
      
      return if @flight_booking.nil? || @train_booking.nil?
      
      add_assertion "第一段航班路线正确（#{@origin_city}→#{@transfer_city}）", weight: 10 do
        expect(@flight_booking.flight.departure_city).to eq(@origin_city)
        expect(@flight_booking.flight.destination_city).to eq(@transfer_city)
      end
      
      add_assertion "第二段火车路线正确（#{@transfer_city}→#{@destination_city}）", weight: 10 do
        expect(@train_booking.train.departure_city).to eq(@transfer_city)
        expect(@train_booking.train.arrival_city).to eq(@destination_city)
      end
      
      add_assertion "出发日期正确（明天#{@travel_date}）", weight: 10 do
        expect(@flight_booking.flight.flight_date).to eq(@travel_date)
      end
      
      add_assertion "中转时间≤3小时且衔接合理", weight: 30 do
        arrival_time = @flight_booking.flight.arrival_time
        departure_time = @train_booking.train.departure_time
        transfer_hours = (departure_time - arrival_time) / 3600.0
        
        expect(transfer_hours).to be >= 1,
          "中转时间过短。实际: #{transfer_hours.round(1)}小时（建议≥1小时）"
        expect(transfer_hours).to be <= @max_transfer_hours,
          "中转时间过长。期望: ≤#{@max_transfer_hours}小时, 实际: #{transfer_hours.round(1)}小时"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@train_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择中转时间最短的组合
      best_combo = @valid_combinations.min_by { |c| c[:transfer_hours] }
      
      Booking.create!(
        user: user,
        flight: best_combo[:flight],
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: best_combo[:flight].price,
        accept_terms: true,
        status: 'paid',
        accept_terms: true,
        data_version: @data_version
      )
      
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
    end
    
    private
    
    def execution_state_data
      {
        origin_city: @origin_city,
        transfer_city: @transfer_city,
        destination_city: @destination_city,
        travel_date: @travel_date.to_s,
        max_transfer_hours: @max_transfer_hours
      }
    end
    
    def restore_from_state(data)
      @origin_city = data['origin_city']
      @transfer_city = data['transfer_city']
      @destination_city = data['destination_city']
      @travel_date = Date.parse(data['travel_date'])
      @max_transfer_hours = data['max_transfer_hours']
      
      flights = Flight.where(
        departure_city: @origin_city,
        destination_city: @transfer_city,
        flight_date: @travel_date,
        data_version: 0
      ).to_a
      
      trains = Train.by_route(@transfer_city, @destination_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .to_a
      
      @valid_combinations = []
      flights.each do |flight|
        arrival_time = flight.arrival_time
        trains.each do |train|
          transfer_hours = (train.departure_time - arrival_time) / 3600.0
          if transfer_hours >= 1 && transfer_hours <= @max_transfer_hours
            @valid_combinations << { flight: flight, train: train, transfer_hours: transfer_hours }
          end
        end
      end
    end
  end
end
