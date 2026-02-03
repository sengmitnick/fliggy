# frozen_string_literal: true

require_relative '../base_validator'

# V216: 预订连续多段行程（4城4天）
#
# 任务描述:
#   用户需要预订连续多段行程：北京→上海→杭州→深圳（4天）
#
# 评分标准:
#   - 创建了3段交通订单 (25%)
#   - 第一段路线正确（北京→上海） (10%)
#   - 第二段路线正确（上海→杭州） (10%)
#   - 第三段路线正确（杭州→深圳） (10%)
#   - 各段时间衔接合理（同一天或次日） (25%)
#   - 订单状态有效 (20%)
module V201V250
  class V216BookConsecutiveTripsMultiDestinationValidator < BaseValidator
    self.validator_id = 'v216_book_consecutive_trips_multi_destination_validator'
    self.task_id = '5ff687f0-6f6f-4f9f-ff9f-0f2a3b4c5d6f'
    self.title = '预订连续多段行程（4城4天）'
    self.description = '用户需要预订连续多段行程：北京→上海→杭州→深圳（4天）'
    self.timeout_seconds = 300
    
    def prepare
      @city1 = '北京'
      @city2 = '上海'
      @city3 = '杭州'
      @city4 = '深圳'
      @start_date = Date.today + 1.day
      
      # 查找各段可用交通
      @leg1_options = find_transport_options(@city1, @city2, @start_date)
      @leg2_options = find_transport_options(@city2, @city3, @start_date, @start_date + 2.days)
      @leg3_options = find_transport_options(@city3, @city4, @start_date + 1.day, @start_date + 3.days)
      
      raise "未找到#{@city1}→#{@city2}的交通" if @leg1_options.empty?
      raise "未找到#{@city2}→#{@city3}的交通" if @leg2_options.empty?
      raise "未找到#{@city3}→#{@city4}的交通" if @leg3_options.empty?
      
      {
        task: "请预订#{@start_date.strftime('%Y年%m月%d日')}（明天）开始的连续多段行程：#{@city1}→#{@city2}→#{@city3}→#{@city4}（4天），各段时间要衔接好。",
        requirements: {
          cities: "#{@city1}→#{@city2}→#{@city3}→#{@city4}",
          start_date: @start_date,
          days: 4,
          purpose: '多城市连续游览'
        },
        hint: "依次预订三段交通，确保时间衔接合理（同一天或次日）。"
      }
    end
    
    def verify
      add_assertion "创建了3段交通订单", weight: 25 do
        # 收集所有交通订单（航班+火车）
        flight_bookings = Booking
          .joins(:flight)
          .where(data_version: @data_version)
          .to_a
        
        train_bookings = TrainBooking
          .joins(:train)
          .where(data_version: @data_version)
          .to_a
        
        all_transports = (flight_bookings + train_bookings).sort_by do |b|
          if b.is_a?(Booking)
            b.flight.departure_time
          else
            b.train.departure_time
          end
        end
        
        expect(all_transports.size).to be >= 3, "交通订单数量不足。期望至少3段，实际: #{all_transports.size}段"
        
        @leg1 = all_transports[0]
        @leg2 = all_transports[1]
        @leg3 = all_transports[2]
      end
      
      return if @leg1.nil? || @leg2.nil? || @leg3.nil?
      
      add_assertion "第一段路线正确（#{@city1}→#{@city2}）", weight: 10 do
        dep, arr = get_route(@leg1)
        expect(dep).to eq(@city1), "第一段出发城市错误。期望: #{@city1}, 实际: #{dep}"
        expect(arr).to eq(@city2), "第一段到达城市错误。期望: #{@city2}, 实际: #{arr}"
      end
      
      add_assertion "第二段路线正确（#{@city2}→#{@city3}）", weight: 10 do
        dep, arr = get_route(@leg2)
        expect(dep).to eq(@city2), "第二段出发城市错误。期望: #{@city2}, 实际: #{dep}"
        expect(arr).to eq(@city3), "第二段到达城市错误。期望: #{@city3}, 实际: #{arr}"
      end
      
      add_assertion "第三段路线正确（#{@city3}→#{@city4}）", weight: 10 do
        dep, arr = get_route(@leg3)
        expect(dep).to eq(@city3), "第三段出发城市错误。期望: #{@city3}, 实际: #{dep}"
        expect(arr).to eq(@city4), "第三段到达城市错误。期望: #{@city4}, 实际: #{arr}"
      end
      
      add_assertion "各段时间衔接合理", weight: 25 do
        time1_arr = get_arrival_time(@leg1)
        time2_dep = get_departure_time(@leg2)
        time2_arr = get_arrival_time(@leg2)
        time3_dep = get_departure_time(@leg3)
        
        gap1_hours = (time2_dep - time1_arr) / 3600.0
        gap2_hours = (time3_dep - time2_arr) / 3600.0
        
        expect(gap1_hours).to be >= 1, "第1-2段衔接过紧。实际间隔: #{gap1_hours.round(1)}小时"
        expect(gap1_hours).to be <= 48, "第1-2段间隔过长。实际间隔: #{gap1_hours.round(1)}小时"
        expect(gap2_hours).to be >= 1, "第2-3段衔接过紧。实际间隔: #{gap2_hours.round(1)}小时"
        expect(gap2_hours).to be <= 48, "第2-3段间隔过长。实际间隔: #{gap2_hours.round(1)}小时"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@leg1.status).to be_in(['pending', 'paid', 'completed'])
        expect(@leg2.status).to be_in(['pending', 'paid', 'completed'])
        expect(@leg3.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 预订第一段（明天晚上）
      leg1 = @leg1_options.select { |t| get_time(t) > (@start_date.to_time + 18.hours) }.min_by { |t| t[:price] } || @leg1_options.min_by { |t| t[:price] }
      create_transport_booking(user, leg1)
      
      # 预订第二段（后天早上或中午）
      leg2 = @leg2_options.select { |t| get_time(t) > leg1_arrival_time(leg1) + 12.hours }.min_by { |t| t[:price] } || @leg2_options.min_by { |t| t[:price] }
      create_transport_booking(user, leg2)
      
      # 预订第三段（大后天或再后一天）
      leg3 = @leg3_options.select { |t| get_time(t) > leg2_arrival_time(leg2) + 12.hours }.min_by { |t| t[:price] } || @leg3_options.min_by { |t| t[:price] }
      create_transport_booking(user, leg3)
    end
    
    def get_time(option)
      if option[:type] == :flight
        option[:transport].departure_time
      else
        option[:transport].departure_time
      end
    end
    
    def leg1_arrival_time(option)
      if option[:type] == :flight
        option[:transport].arrival_time
      else
        option[:transport].arrival_time
      end
    end
    
    def leg2_arrival_time(option)
      if option[:type] == :flight
        option[:transport].arrival_time
      else
        option[:transport].arrival_time
      end
    end
    
    private
    
    def find_transport_options(from_city, to_city, start_date, end_date = nil)
      end_date ||= start_date + 1.day
      options = []
      
      # 查找航班
      flights = Flight.where(
        departure_city: from_city,
        destination_city: to_city,
        data_version: 0
      ).select { |f| f.flight_date >= start_date && f.flight_date <= end_date }
      
      flights.each do |f|
        options << { type: :flight, transport: f, price: f.price }
      end
      
      # 查找火车
      (start_date..end_date).each do |date|
        trains = Train.by_route(from_city, to_city).by_date(date).where(data_version: 0)
        trains.each do |t|
          options << { type: :train, transport: t, price: t.price_second_class }
        end
      end
      
      options
    end
    
    def create_transport_booking(user, option)
      if option[:type] == :flight
        Booking.create!(
          user: user,
          flight: option[:transport],
          passenger_name: user.name,
          passenger_id_number: '110101199001011234',
          contact_phone: '13800138000',
          total_price: option[:price],
          accept_terms: true,
          status: 'paid',
          data_version: @data_version
        )
      else
        TrainBooking.create!(
          user: user,
          train: option[:transport],
          passenger_name: user.name,
          passenger_id_number: '110101199001011234',
          contact_phone: '13800138000',
          seat_type: 'second_class',
          ticket_count: 1,
          total_price: option[:price],
          status: 'paid',
          accept_terms: true,
          data_version: @data_version
        )
      end
    end
    
    def get_route(booking)
      if booking.is_a?(Booking)
        [booking.flight.departure_city, booking.flight.destination_city]
      else
        [booking.train.departure_city, booking.train.arrival_city]
      end
    end
    
    def get_departure_time(booking)
      if booking.is_a?(Booking)
        booking.flight.departure_time
      else
        booking.train.departure_time
      end
    end
    
    def get_arrival_time(booking)
      if booking.is_a?(Booking)
        booking.flight.arrival_time
      else
        booking.train.arrival_time
      end
    end
    
    def execution_state_data
      {
        city1: @city1,
        city2: @city2,
        city3: @city3,
        city4: @city4,
        start_date: @start_date.to_s
      }
    end
    
    def restore_from_state(data)
      @city1 = data['city1']
      @city2 = data['city2']
      @city3 = data['city3']
      @city4 = data['city4']
      @start_date = Date.parse(data['start_date'])
      
      @leg1_options = find_transport_options(@city1, @city2, @start_date)
      @leg2_options = find_transport_options(@city2, @city3, @start_date, @start_date + 2.days)
      @leg3_options = find_transport_options(@city3, @city4, @start_date + 1.day, @start_date + 3.days)
    end
  end
end
