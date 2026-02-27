# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例150: 帮张三预订明天北京到天津的早班汽车票，并预订天津火车站接站服务（接从上海坐火车来的人）
# 
# 任务描述:
#   Agent 需要在系统中完成两项预订：
#   1. 北京→天津的汽车票（明天早班06:00-10:00）
#   2. 天津火车站接站服务（接从上海坐火车来的人）
# 
# 复杂度分析:
#   1. 需要搜索北京→天津的汽车票
#   2. 需要选择"明天"出发日期
#   3. 需要筛选早班车次（06:00-10:00）
#   4. 需要预订天津火车站接站服务
#   5. 需要协调汽车票到达时间与接站时间
#   ✅ 多模块组合（汽车+接送） + 时间窗口筛选 + 时间协调
# 
# 评分标准:
#   - 创建了汽车票订单 (25分)
#   - 出发地正确（北京） (15分)
#   - 目的地正确（天津） (15分)
#   - 发车日期正确（明天） (5分)
#   - 乘车人信息正确（张三） (10分)
#   - 创建了火车站接站服务 (20分)
#   - 接站服务在目的地（天津） (10分)
#
module V101V150
  class V150BookBusAndCityCharterValidator < BaseValidator
    self.validator_id = 'v150_book_bus_and_city_charter_validator'
    self.task_id = 'e0f1a2b3-4c5d-6e7f-8a9b-0c1d2e3f4a5b'
    self.title = '帮张三预订明天北京到天津的早班汽车票，并预订天津火车站接站服务（接从上海坐火车来的人）'
    self.description = '帮张三预订明天北京到天津的早班汽车票，并预订天津火车站接站服务（接从上海坐火车来的人）'
    self.timeout_seconds = 300

    def prepare
      @travel_date = Date.tomorrow
      @origin = '北京'
      @destination = '天津'
      @preferred_time = '08:00' # 早班车
      @station_location = '天津站'
      
      # 预查询乘客信息（用于 simulate）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @zhangsan.name
      @expected_passenger_id = @zhangsan.id_number
      
      # 查找可用的汽车票（上午班次）
      @available_tickets = BusTicket
        .where(origin: @origin, destination: @destination, data_version: 0)
        .where(departure_date: @travel_date)
        .where("departure_time >= ?", '06:00')
        .where("departure_time <= ?", '10:00')
        .to_a
      
      expect(@available_tickets).not_to be_empty, "数据包缺少北京到天津的上午汽车票"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 选择最接近偏好时间的班次
      ticket = @available_tickets.min_by { |t| (Time.parse(t.departure_time) - Time.parse(@preferred_time)).abs }
      
      # 创建汽车票订单
      order = BusTicketOrder.create!(
        user: user,
        bus_ticket: ticket,
        passenger_count: 1,
        total_price: ticket.price,
        status: 'paid',
        data_version: @data_version
      )
      
      order.passengers.create!(
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number
      )
      
      # 计算抵达时间，预订火车站接站服务
      arrival_time = Time.parse(ticket.arrival_time)
      pickup_datetime = @travel_date.in_time_zone + arrival_time.hour.hours + arrival_time.min.minutes + 30.minutes
      
      # 创建火车站接站服务
      Transfer.create!(
        user: user,
        transfer_type: 'train_pickup',
        service_type: 'from_station',
        location_from: @station_location,
        location_to: "#{@destination}市区",
        pickup_datetime: pickup_datetime,
        vehicle_type: 'business_5',
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        total_price: 100.0,
        status: 'pending',
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        travel_date: @travel_date.to_s,
        origin: @origin,
        destination: @destination,
        preferred_time: @preferred_time,
        station_location: @station_location
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @origin = data['origin']
      @destination = data['destination']
      @preferred_time = data['preferred_time']
      @station_location = data['station_location']
    end

    def verify
      # 断言1: 创建了汽车票订单 (25分)
      add_assertion "创建了汽车票订单", weight: 25 do
        all_orders = BusTicketOrder
          .joins(:bus_ticket)
          .includes(:bus_ticket)
          .where(bus_tickets: { origin: @origin, destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_orders).not_to be_empty, "未找到任何汽车票订单"
        @bus_order = all_orders.first
      end
      
      return if @bus_order.nil?
      
      # 断言2: 出发地正确（北京） (15分)
      add_assertion "出发地正确（#{@origin}）", weight: 15 do
        expect(@bus_order.bus_ticket.origin).to eq(@origin),
          "出发地错误。期望: #{@origin}, 实际: #{@bus_order.bus_ticket.origin}"
      end
      
      # 断言3: 目的地正确（天津） (15分)
      add_assertion "目的地正确（#{@destination}）", weight: 15 do
        expect(@bus_order.bus_ticket.destination).to eq(@destination),
          "目的地错误。期望: #{@destination}, 实际: #{@bus_order.bus_ticket.destination}"
      end
      
      # 断言4: 发车日期正确（明天） (5分)
      add_assertion "发车日期正确（#{@travel_date}）", weight: 5 do
        expect(@bus_order.bus_ticket.departure_date).to eq(@travel_date),
          "发车日期错误。期望: #{@travel_date}（明天）, 实际: #{@bus_order.bus_ticket.departure_date}"
      end
      
      # 断言5: 乘车人信息正确（张三） (10分)
      add_assertion "乘车人信息正确（张三）", weight: 10 do
        passenger = @bus_order.passengers.first
        expect(passenger).not_to be_nil, "未找到乘车人信息"
        expect(passenger.passenger_name).to eq(@expected_passenger_name),
          "乘车人姓名错误。期望: #{@expected_passenger_name}，实际: #{passenger.passenger_name}"
        expect(passenger.passenger_id_number).to eq(@expected_passenger_id),
          "乘车人身份证错误。期望: #{@expected_passenger_id}，实际: #{passenger.passenger_id_number}"
      end
      
      # 断言6: 创建了火车站接站服务 (20分) - 核心评分项
      add_assertion "创建了火车站接站服务", weight: 20 do
        @transfer = Transfer
          .where(transfer_type: 'train_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到火车站接站服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言7: 接站服务在目的地（天津） (10分)
      add_assertion "接站服务在目的地（#{@destination}）", weight: 10 do
        in_city = @transfer.location_from.include?(@destination) || @transfer.location_to.include?(@destination)
        expect(in_city).to be(true),
          "接站服务地点错误。期望包含: #{@destination}, 实际: #{@transfer.location_from} -> #{@transfer.location_to}"
      end
    end
  end
end
