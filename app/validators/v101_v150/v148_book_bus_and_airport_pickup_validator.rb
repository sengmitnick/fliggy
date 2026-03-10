# frozen_string_literal: true

require_relative '../base_validator'


# 验证用例148: 帮张三预订明天早上深圳到广州的汽车票，并预订广州白云机场接机服务（明天下午15:00从北京飞往广州，18:20到达白云T1，接机至珠江新城）
#
# 任务描述:
#   张三计划明天早上从深圳坐汽车到广州，同时需要预订广州白云机场接机服务，（明天下午15:00从北京起飞的航班，预计18:20到达白云T1航站楼），接到珠江新城接送服务站。
#   1. 深圳→广州的汽车票（明天早上06:00-10:00，最好接近08:00）
#   2. 广州白云机场T1接机服务（接明天下午18:20到达的北京航班，接至珠江新城接送服务站）
#
# 任务分解步骤:
#   1. 查询深圳→广州的早班汽车票（departure_date=明天，departure_time在06:00-10:00之间）
#   2. 选择最接近08:00的班次
#   3. 创建汽车票订单（乘客=张三）
#   4. 查询Flight获取15:00从北京飞往广州的航班，确定到达机场（arrival_airport="白云T1"）
#   5. 查询TransferLocation获取广州珠江新城服务点（location_type='other'，名称包含'珠江新城'）
#   6. 创建接机服务订单（transfer_type=airport_pickup，location_from=航班到达机场（从Flight.arrival_airport获取），location_to=珠江新城服务点）
#
# 复杂度分析（5个复杂点）：
#   1. 多模块组合：需要同时创建汽车票订单+接机服务订单（2个不同类型的订单）
#   2. 时间窗口筛选：需要筛选早班车次（06:00-10:00）并选择最接近08:00的班次
#   3. 接机点查询：需要从 Flight 模型查询航班的 arrival_airport 字段（不硬编码）
#   4. 服务点查询：需要从 TransferLocation 查询具体的接送服务点（不使用笼统的"市区"）
#   5. 时间协调：需要协调汽车票到达时间与接机时间（确保接机服务在航班到达时间）
#
# 评分标准（总分100）：
#   1. 创建了汽车票订单（20分）
#   2. 出发地正确=深圳（10分）
#   3. 目的地正确=广州（10分）
#   4. 发车日期正确=明天（5分）
#   5. 选择了早班车次（06:00-10:00）（5分）
#   6. 乘车人信息正确=张三（10分）
#   7. 创建了机场接机服务（15分）
#   8. 接机上车点=航班到达机场（从 Flight.arrival_airport 动态获取）（10分）
#   9. 接机下车点=服务点（从 TransferLocation 动态获取）（10分）
#   10. 接机时间在航班到达时间之后（5分）
#
# 使用方法:
#   rake validator:simulate_single[v148_book_bus_and_airport_pickup_validator]
#
module V101V150
  class V148BookBusAndAirportPickupValidator < BaseValidator
    self.validator_id = 'v148_book_bus_and_airport_pickup_validator'
    self.task_id = 'c8d9e0f1-2a3b-4c5d-6e7f-8a9b0c1d2e3f'
    self.title = '帮张三预订明天早上深圳到广州的汽车票，并预订广州白云机场接机服务（明天下午15:00从北京飞往广州，18:20到达白云T1，接机至珠江新城）'
    self.description = '帮张三预订明天早上深圳到广州的汽车票，并预订广州白云机场接机服务（明天下午15:00从北京飞往广州，18:20到达白云T1，接机至珠江新城）'
    self.timeout_seconds = 300

    def prepare
      @travel_date = Date.tomorrow
      @origin = '深圳'
      @destination = '广州'
      @preferred_time = '08:00'
      
      # 查询航班信息（接机服务需要知道航班到达哪个航站楼）
      @flight = Flight.where(
        departure_city: '北京',
        destination_city: @destination,
        data_version: 0
      ).find { |f| f.departure_time.hour == 15 && f.departure_time.min == 0 }
      
      raise "数据包缺少15:00从北京飞往广州的航班" unless @flight
      
      # 从航班获取到达机场（由航班决定，不是用户选择）
      @flight_arrival_airport = @flight.arrival_airport  # "白云T1"
      
      # 查询TransferLocation获取广州珠江新城服务点（接机下车点）
      @service_loc = TransferLocation.where(
        city: @destination,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('珠江新城') }
      
      raise "数据包缺少广州珠江新城TransferLocation" unless @service_loc
      
      @service_location = @service_loc.name  # 服务点=珠江新城接送服务站（从TransferLocation动态获取）
      
      # 预查询乘客信息（用于 simulate 和 verify）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @zhangsan.name
      @expected_passenger_id = @zhangsan.id_number
      
      # 查找可用的汽车票（早上班次）
      @available_tickets = BusTicket
        .where(origin: @origin, destination: @destination, data_version: 0)
        .where(departure_date: @travel_date)
        .where("departure_time >= ?", '06:00')
        .where("departure_time <= ?", '10:00')
        .to_a
      
      expect(@available_tickets).not_to be_empty, "数据包缺少深圳到广州的早班汽车票"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 选择早上的班次
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
      
      # 创建乘客信息
      order.passengers.create!(
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number
      )
      
      # 创建机场接机服务（接从北京飞来的人）
      # 航班18:20到达，预留30分钟等待时间
      flight_arrival_time = @flight.arrival_time
      pickup_datetime = @travel_date.in_time_zone + flight_arrival_time.hour.hours + flight_arrival_time.min.minutes + 30.minutes
      
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @flight_arrival_airport,  # 上车点=航班到达机场（由 Flight.arrival_airport 决定，不是用户选择）
        location_to: @service_location,  # 下车点=珠江新城（用户选择，从 TransferLocation 动态获取）
        pickup_datetime: pickup_datetime,
        vehicle_type: 'economy_5',
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
        flight_id: @flight&.id,
        flight_arrival_airport: @flight_arrival_airport,
        service_location_name: @service_loc&.name,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @origin = data['origin']
      @destination = data['destination']
      @preferred_time = data['preferred_time']
      @flight_arrival_airport = data['flight_arrival_airport']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      
      # 重新查询Flight
      @flight = Flight.find_by(id: data['flight_id']) if data['flight_id']
      
      # 重新查询TransferLocation（服务点）
      @service_loc = TransferLocation.find_by(
        city: @destination,
        name: data['service_location_name'],
        location_type: 'other',
        data_version: 0
      ) if data['service_location_name']
      
      @service_location = @service_loc&.name
    end

    def verify
      # 断言1: 创建了汽车票订单 (20分)
      add_assertion "创建了汽车票订单", weight: 20 do
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
      
      # 断言2: 出发地正确（深圳） (10分)
      add_assertion "出发地正确（#{@origin}）", weight: 10 do
        expect(@bus_order.bus_ticket.origin).to eq(@origin),
          "出发地错误。期望: #{@origin}, 实际: #{@bus_order.bus_ticket.origin}"
      end
      
      # 断言3: 目的地正确（广州） (10分)
      add_assertion "目的地正确（#{@destination}）", weight: 10 do
        expect(@bus_order.bus_ticket.destination).to eq(@destination),
          "目的地错误。期望: #{@destination}, 实际: #{@bus_order.bus_ticket.destination}"
      end
      
      # 断言4: 发车日期正确（明天） (5分)
      add_assertion "发车日期正确（#{@travel_date}）", weight: 5 do
        expect(@bus_order.bus_ticket.departure_date).to eq(@travel_date),
          "发车日期错误。期望: #{@travel_date}（明天）, 实际: #{@bus_order.bus_ticket.departure_date}"
      end
      
      # 断言5: 选择了早班车次（06:00-10:00） (5分)
      add_assertion "选择了早班车次（06:00-10:00）", weight: 5 do
        dep_time = Time.parse(@bus_order.bus_ticket.departure_time)
        is_morning = dep_time.hour >= 6 && dep_time.hour <= 10
        expect(is_morning).to be(true),
          "未选择早班车次。实际发车时间: #{@bus_order.bus_ticket.departure_time}"
      end
      
      # 断言6: 乘车人信息正确（张三） (10分)
      add_assertion "乘车人信息正确（张三）", weight: 10 do
        passenger = @bus_order.passengers.first
        expect(passenger).not_to be_nil, "未找到乘车人信息"
        expect(passenger.passenger_name).to eq(@expected_passenger_name),
          "乘车人姓名错误。期望: #{@expected_passenger_name}，实际: #{passenger.passenger_name}"
        expect(passenger.passenger_id_number).to eq(@expected_passenger_id),
          "乘车人身份证错误。期望: #{@expected_passenger_id}，实际: #{passenger.passenger_id_number}"
      end
      
      # 断言7: 创建了机场接机服务 (15分)
      add_assertion "创建了机场接机服务", weight: 15 do
        @transfer = Transfer
          .where(transfer_type: 'airport_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到机场接机服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言8: 接机上车点=航班到达机场（由Flight.arrival_airport决定） (10分)
      add_assertion "接机上车点=航班到达机场（#{@flight_arrival_airport}）", weight: 10 do
        expect(@transfer.location_from).to eq(@flight_arrival_airport),
          "接机上车点错误。期望: #{@flight_arrival_airport}（由航班到达机场决定）, 实际: #{@transfer.location_from}"
      end
      
      # 断言9: 接机下车点=服务点（用户选择） (10分)
      add_assertion "接机下车点=服务点（#{@service_location}）", weight: 10 do
        expect(@transfer.location_to).to eq(@service_location),
          "接机下车点错误。期望: #{@service_location}, 实际: #{@transfer.location_to}"
      end
      
      # 断言10: 接机时间在航班到达时间之后 (5分)
      add_assertion "接机时间在航班到达时间之后", weight: 5 do
        flight_arrival = @travel_date.in_time_zone + @flight.arrival_time.hour.hours + @flight.arrival_time.min.minutes
        expect(@transfer.pickup_datetime).to be >= flight_arrival,
          "接机时间错误。航班到达: #{flight_arrival}, 接机时间: #{@transfer.pickup_datetime}"
      end
    end
  end
end
