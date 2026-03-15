# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例216: 张三需要预订明天开始的连续多段行程：北京→上海→杭州→深圳（4天，使用飞机或火车）
#
# 任务描述:
#   张三需要预订明天开始的连续多段行程，依次游览北京→上海→杭州→深圳（4天），只能使用飞机或火车。
#   Agent需要预订3段交通（飞机或火车），确保各段时间衔接合理（同一天或次日）。
#
# 业务流程:
#   1. 张三向Agent提出需求：明天开始连续多段行程，北京→上海→杭州→深圳（4天）
#   2. Agent查询第一段交通（北京→上海），选择合适的航班或火车
#   3. Agent预订第一段交通
#   4. Agent查询第二段交通（上海→杭州），选择与第一段衔接合理的航班或火车
#   5. Agent预订第二段交通
#   6. Agent查询第三段交通（杭州→深圳），选择与第二段衔接合理的航班或火车
#   7. Agent预订第三段交通
#   8. Agent确认各段时间衔接合理（间隔1-48小时）
#
# 复杂度分析:
#   1. 需要理解连续多段行程概念（3段交通，4个城市）
#   2. 需要同时支持飞机和火车两种交通方式
#   3. 需要计算各段交通的时间衔接（确保间隔合理）
#   4. 需要协调多段行程的路线顺序
#
# 评分标准:
#   - 创建了3段交通订单 (20分)
#   - 第一段路线正确（北京→上海） (10分)
#   - 第二段路线正确（上海→杭州） (10分)
#   - 第三段路线正确（杭州→深圳） (10分)
#   - 第一段出发日期正确（明天） (10分)
#   - 各段时间衔接合理（间隔1-48小时） (20分)
#   - 乘客信息正确（张三） (15分)
#   - 订单状态有效 (5分)
module V201V250
  class V216BookConsecutiveTripsMultiDestinationValidator < BaseValidator
    self.validator_id = 'v216_book_consecutive_trips_multi_destination_validator'
    self.task_id = '5ff687f0-6f6f-4f9f-ff9f-0f2a3b4c5d6f'
    self.title = '张三需要预订明天开始的连续多段行程：北京→上海→杭州→深圳（4天，使用飞机或火车）'
    self.description = '张三需要预订明天开始的连续多段行程：北京→上海→杭州→深圳（4天，使用飞机或火车）'
    self.timeout_seconds = 300
    
    def prepare
      @city1 = '北京'
      @city2 = '上海'
      @city3 = '杭州'
      @city4 = '深圳'
      @start_date = Date.current + 1.day
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_id_number = @passenger.id_number
      @expected_phone = @passenger.phone
      
      # 查找各段可用交通
      @leg1_options = find_transport_options(@city1, @city2, @start_date)
      @leg2_options = find_transport_options(@city2, @city3, @start_date, @start_date + 2.days)
      @leg3_options = find_transport_options(@city3, @city4, @start_date + 1.day, @start_date + 3.days)
      
      raise "未找到#{@city1}→#{@city2}的交通" if @leg1_options.empty?
      raise "未找到#{@city2}→#{@city3}的交通" if @leg2_options.empty?
      raise "未找到#{@city3}→#{@city4}的交通" if @leg3_options.empty?
      
      {
        title: "今天是#{Date.current.strftime('%Y年%m月%d日')}。张三需要预订明天开始的连续多段行程：北京→上海→杭州→深圳（4天，使用飞机或火车）",
        description: "张三需要预订明天开始的连续多段行程：北京→上海→杭州→深圳（4天，使用飞机或火车）",
        scenario: "张三需要连续游览4个城市，使用飞机或火车",
        requirements: {
          cities: "#{@city1}→#{@city2}→#{@city3}→#{@city4}",
          start_date: @start_date.strftime('%Y-%m-%d'),
          days: 4,
          transport_types: '飞机或火车',
          passenger: '张三'
        },
        available_transports_sample: {
          leg1: "#{@city1}→#{@city2}: #{@leg1_options.size}个选项",
          leg2: "#{@city2}→#{@city3}: #{@leg2_options.size}个选项",
          leg3: "#{@city3}→#{@city4}: #{@leg3_options.size}个选项"
        }
      }
    end
    
    def verify
      add_assertion "创建了3段交通订单（飞机或火车）", weight: 20 do
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
      
      add_assertion "第一段出发日期正确（明天#{@start_date}）", weight: 10 do
        dep_time = get_departure_time(@leg1)
        dep_date = dep_time.to_date
        expect(dep_date).to eq(@start_date),
          "第一段出发日期错误。期望: #{@start_date}（明天）, 实际: #{dep_date}"
      end
      
      add_assertion "各段时间衔接合理（间隔1-48小时）", weight: 20 do
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
      
      add_assertion "乘客信息正确（张三）", weight: 15 do
        expect(@leg1.passenger_name).to eq(@expected_passenger_name),
          "第一段乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@leg1.passenger_name}"
        expect(@leg2.passenger_name).to eq(@expected_passenger_name),
          "第二段乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@leg2.passenger_name}"
        expect(@leg3.passenger_name).to eq(@expected_passenger_name),
          "第三段乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@leg3.passenger_name}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@leg1.status).to be_in(['pending', 'paid', 'completed'])
        expect(@leg2.status).to be_in(['pending', 'paid', 'completed'])
        expect(@leg3.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 预订第一段（明天，飞机或火车，优先选择晚上出发）
      leg1_on_start_date = @leg1_options.select { |t| get_time(t).to_date == @start_date }
      leg1 = if leg1_on_start_date.any?
               leg1_on_start_date.select { |t| get_time(t).hour >= 18 }.min_by { |t| t[:price] } || leg1_on_start_date.min_by { |t| t[:price] }
             else
               @leg1_options.min_by { |t| t[:price] }
             end
      create_transport_booking(user, leg1)
      
      # 预订第二段（飞机或火车，与第一段衔接）
      leg2 = @leg2_options.select { |t| get_time(t) > leg1_arrival_time(leg1) + 12.hours }.min_by { |t| t[:price] } || @leg2_options.min_by { |t| t[:price] }
      create_transport_booking(user, leg2)
      
      # 预订第三段（飞机或火车，与第二段衔接）
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
          passenger_name: @expected_passenger_name,
          passenger_id_number: @expected_id_number,
          contact_phone: @expected_phone,
          total_price: option[:price],
          accept_terms: true,
          status: 'paid',
          data_version: @data_version
        )
      else
        TrainBooking.create!(
          user: user,
          train: option[:transport],
          passenger_name: @expected_passenger_name,
          passenger_id_number: @expected_id_number,
          contact_phone: @expected_phone,
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
        start_date: @start_date.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_id_number: @expected_id_number,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      @city1 = data['city1']
      @city2 = data['city2']
      @city3 = data['city3']
      @city4 = data['city4']
      @start_date = Date.parse(data['start_date'])
      @expected_passenger_name = data['expected_passenger_name']
      @expected_id_number = data['expected_id_number']
      @expected_phone = data['expected_phone']
      
      @leg1_options = find_transport_options(@city1, @city2, @start_date)
      @leg2_options = find_transport_options(@city2, @city3, @start_date, @start_date + 2.days)
      @leg3_options = find_transport_options(@city3, @city4, @start_date + 1.day, @start_date + 3.days)
    end
  end
end
