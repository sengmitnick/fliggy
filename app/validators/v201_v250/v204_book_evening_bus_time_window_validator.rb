# frozen_string_literal: true

require_relative '../base_validator'

# V204: 预订晚间大巴（时间窗口）
#
# 任务描述:
#   用户需要预订明天18:00-20:00广州→深圳大巴（下班后出行）
#
# 评分标准:
#   - 创建了大巴票订单 (20%)
#   - 大巴路线正确（广州→深圳） (15%)
#   - 出发时间在18:00-20:00窗口内 (35%)
#   - 乘客信息正确 (10%)
#   - 订单状态有效 (20%)
module V201V250
  class V204BookEveningBusTimeWindowValidator < BaseValidator
    self.validator_id = 'v204_book_evening_bus_time_window_validator'
    self.task_id = '3c4465e8-4f4f-4d9a-af7f-8f0a1b2c3d4e'
    self.title = '给张三预订明天晚间大巴（时间窗口18:00-20:00，广州→深圳）'
    self.description = '张三需要预订明天18:00-20:00从广州到深圳的大巴，适合下班后出行'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '广州'
      @arrival_city = '深圳'
      @travel_date = Date.current + 1.day
      @time_window_start = 18  # 18:00
      @time_window_end = 20    # 20:00
      
      # 预查询乘客数据（避免 simulate 中使用 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      
      # 查找符合时间窗口的大巴
      all_buses = BusTicket.where(
        origin: @departure_city,
        destination: @arrival_city,
        data_version: 0
      )
      
      @available_buses = all_buses.select do |b|
        departure = Time.parse(b.departure_time)
        hour = departure.hour
        hour >= @time_window_start && hour < @time_window_end
      end
      
      raise "未找到符合条件的大巴" if @available_buses.empty?
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}（明天）晚上18:00-20:00从#{@departure_city}到#{@arrival_city}的大巴，适合下班后出行。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          travel_date: @travel_date,
          time_window: '18:00-20:00',
          purpose: '下班后出行'
        },
        hint: "选择晚间时段的大巴，出发时间在18:00-20:00之间。"
      }
    end
    
    def verify
      add_assertion "创建了大巴票订单", weight: 20 do
        all_orders = BusTicketOrder
          .joins(:bus_ticket)
          .includes(:bus_ticket)
          .where(bus_tickets: { origin: @departure_city, destination: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @order = all_orders.first
        expect(@order).not_to be_nil, "未找到从#{@departure_city}到#{@arrival_city}的大巴票订单"
      end
      
      return if @order.nil?
      
      add_assertion "大巴路线正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        expect(@order.bus_ticket.origin).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{@order.bus_ticket.origin}"
        expect(@order.bus_ticket.destination).to eq(@arrival_city),
          "到达城市错误。期望: #{@arrival_city}, 实际: #{@order.bus_ticket.destination}"
      end
      
      add_assertion "出发时间在18:00-20:00窗口内", weight: 35 do
        departure = Time.parse(@order.bus_ticket.departure_time)
        hour = departure.hour
        expect(hour).to be >= @time_window_start,
          "出发时间过早。期望: ≥#{@time_window_start}:00, 实际: #{departure.strftime('%H:%M')}"
        expect(hour).to be < @time_window_end,
          "出发时间过晚。期望: <#{@time_window_end}:00, 实际: #{departure.strftime('%H:%M')}"
      end
      
      add_assertion "乘客信息正确（#{@expected_passenger_name}）", weight: 10 do
        passenger = @order.passengers.first
        expect(passenger).not_to be_nil, "未找到乘客信息"
        expect(passenger.passenger_id_number).to eq(@expected_passenger_id),
          "乘客身份证错误。期望: #{@expected_passenger_id}（#{@expected_passenger_name}）, 实际: #{passenger.passenger_id_number}"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@order.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@order.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择符合时间窗口的大巴（优先选择价格低的）
      bus = @available_buses.min_by(&:price)
      
      # 使用 prepare 中预查询的乘客数据
      order = BusTicketOrder.create!(
        user_id: user.id,
        bus_ticket_id: bus.id,
        passenger_count: 1,
        total_price: bus.price,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建乘客信息
      order.passengers.create!(
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number
      )
      
      order
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date.to_s,
        time_window_start: @time_window_start,
        time_window_end: @time_window_end,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date'])
      @time_window_start = data['time_window_start']
      @time_window_end = data['time_window_end']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      
      # 恢复乘客对象
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: @expected_passenger_name, data_version: 0)
      
      all_buses = BusTicket.where(
        origin: @departure_city,
        destination: @arrival_city,
        data_version: 0
      )
      
      @available_buses = all_buses.select do |b|
        departure = Time.parse(b.departure_time)
        hour = departure.hour
        hour >= @time_window_start && hour < @time_window_end
      end
    end
  end
end
