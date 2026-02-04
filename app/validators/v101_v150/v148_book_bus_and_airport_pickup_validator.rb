# frozen_string_literal: true

require_relative '../base_validator'

# V148: 预订深圳到广州汽车票 + 机场接机服务
# 验证用户能够完成汽车票预订+机场接机服务的组合下单

module V101V150
  class V148BookBusAndAirportPickupValidator < BaseValidator
    self.validator_id = 'v148_book_bus_and_airport_pickup_validator'
    self.task_id = 'c8d9e0f1-2a3b-4c5d-6e7f-8a9b0c1d2e3f'
    self.title = '预订汽车票后预订机场接机服务（深圳-广州）'
    self.description = '预订明天早上深圳到广州的汽车票，并预订广州机场接机服务'
    self.timeout_seconds = 300

    def prepare
      @travel_date = Date.tomorrow
      @origin = '深圳'
      @destination = '广州'
      @pickup_location = '广州白云国际机场'
      @preferred_time = '08:00'
      
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
        passenger_name: user.name,
        passenger_id_number: '110101199001011234'
      )
      
      # 计算抵达时间，预订接机服务
      arrival_time = Time.parse(ticket.arrival_time)
      pickup_datetime = @travel_date.in_time_zone + arrival_time.hour.hours + arrival_time.min.minutes + 30.minutes
      
      # 创建机场接机服务
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @pickup_location,
        location_to: "#{@destination}市区",
        pickup_datetime: pickup_datetime,
        vehicle_type: 'economy_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
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
        pickup_location: @pickup_location,
        preferred_time: @preferred_time
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @origin = data['origin']
      @destination = data['destination']
      @pickup_location = data['pickup_location']
      @preferred_time = data['preferred_time']
    end

    def verify
      # 断言1: 创建了汽车票订单
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
      
      # 断言2: 出发地正确
      add_assertion "出发地正确（#{@origin}）", weight: 15 do
        expect(@bus_order.bus_ticket.origin).to eq(@origin),
          "出发地错误。期望: #{@origin}, 实际: #{@bus_order.bus_ticket.origin}"
      end
      
      # 断言3: 目的地正确
      add_assertion "目的地正确（#{@destination}）", weight: 15 do
        expect(@bus_order.bus_ticket.destination).to eq(@destination),
          "目的地错误。期望: #{@destination}, 实际: #{@bus_order.bus_ticket.destination}"
      end
      
      # 断言4: 发车日期正确
      add_assertion "发车日期正确（#{@travel_date}）", weight: 10 do
        expect(@bus_order.bus_ticket.departure_date).to eq(@travel_date),
          "发车日期错误。期望: #{@travel_date}（明天）, 实际: #{@bus_order.bus_ticket.departure_date}"
      end
      
      # 断言5: 选择了早班车次
      add_assertion "选择了早班车次（06:00-10:00）", weight: 10 do
        dep_time = Time.parse(@bus_order.bus_ticket.departure_time)
        is_morning = dep_time.hour >= 6 && dep_time.hour <= 10
        expect(is_morning).to be(true),
          "未选择早班车次。实际发车时间: #{@bus_order.bus_ticket.departure_time}"
      end
      
      # 断言6: 创建了机场接机服务
      add_assertion "创建了机场接机服务", weight: 15 do
        @transfer = Transfer
          .where(transfer_type: 'airport_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到机场接机服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言7: 接机地点正确
      add_assertion "接机地点正确（#{@pickup_location}）", weight: 10 do
        expect(@transfer.location_from).to eq(@pickup_location),
          "接机地点错误。期望: #{@pickup_location}, 实际: #{@transfer.location_from}"
      end
    end
  end
end
