# frozen_string_literal: true

require_relative '../base_validator'

# V152: 预订杭州到深圳长途汽车票 + 火车站接站服务
# 验证用户能够完成长途汽车票预订+火车站接站服务的组合下单

module V151V200
  class V152BookLongDistanceBusAndStationTransferValidator < BaseValidator
    self.validator_id = 'v152_book_long_distance_bus_and_station_transfer_validator'
    self.task_id = 'a2b3c4d5-6e7f-8a9b-0c1d-2e3f4a5b6c7d'
    self.title = '预订长途汽车票后预订火车站接站服务（杭州-深圳）'
    self.description = '预订明天早上杭州到深圳的长途汽车票，并预订深圳火车站接站服务'
    self.timeout_seconds = 300

    def prepare
      @travel_date = Date.tomorrow
      @origin = '杭州'
      @destination = '深圳'
      @pickup_location = '深圳北站'
      
      # 查找可用的长途汽车票
      @available_tickets = BusTicket
        .where(origin: @origin, destination: @destination, data_version: 0)
        .where(departure_date: @travel_date)
        .to_a
      
      expect(@available_tickets).not_to be_empty, "数据包缺少杭州到深圳的长途汽车票"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      ticket = @available_tickets.first
      
      # 创建长途汽车票订单
      order = BusTicketOrder.create!(
        user: user,
        bus_ticket: ticket,
        passenger_count: 1,
        total_price: ticket.price,
        status: 'paid',
        data_version: @data_version
      )
      
      order.passengers.create!(
        passenger_name: user.name,
        passenger_id_number: '110101199001011234'
      )
      
      # 计算抵达时间，预订接站服务
      arrival_time = Time.parse(ticket.arrival_time)
      pickup_datetime = @travel_date.in_time_zone + arrival_time.hour.hours + arrival_time.min.minutes + 30.minutes
      
      # 创建火车站接站服务
      Transfer.create!(
        user: user,
        transfer_type: 'train_pickup',
        service_type: 'from_station',
        location_from: @pickup_location,
        location_to: "#{@destination}市区",
        pickup_datetime: pickup_datetime,
        vehicle_type: 'economy_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 80.0,
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
        pickup_location: @pickup_location
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @origin = data['origin']
      @destination = data['destination']
      @pickup_location = data['pickup_location']
    end

    def verify
      # 断言1: 创建了长途汽车票订单
      add_assertion "创建了长途汽车票订单", weight: 30 do
        all_orders = BusTicketOrder
          .joins(:bus_ticket)
          .includes(:bus_ticket)
          .where(bus_tickets: { origin: @origin, destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_orders).not_to be_empty, "未找到任何长途汽车票订单"
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
      
      # 断言5: 创建了火车站接站服务
      add_assertion "创建了火车站接站服务", weight: 20 do
        @transfer = Transfer
          .where(transfer_type: 'train_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到火车站接站服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言6: 接站地点正确
      add_assertion "接站地点正确（#{@pickup_location}）", weight: 10 do
        expect(@transfer.location_from).to eq(@pickup_location),
          "接站地点错误。期望: #{@pickup_location}, 实际: #{@transfer.location_from}"
      end
    end
  end
end
