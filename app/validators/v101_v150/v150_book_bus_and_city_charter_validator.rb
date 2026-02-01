# frozen_string_literal: true

require_relative '../base_validator'

# V150: 预订北京到天津汽车票 + 火车站接站服务
# 验证用户能够完成汽车票预订+火车站接站服务的组合下单

module V101V150
  class V150BookBusAndCityCharterValidator < BaseValidator
    self.validator_id = 'v150_book_bus_and_city_charter_validator'
    self.task_id = 'e0f1a2b3-4c5d-6e7f-8a9b-0c1d2e3f4a5b'
    self.title = '预订汽车票并预订目的地火车站接站服务（北京-天津）'
    self.description = '预订明天北京到天津的早班汽车票，并预订天津火车站接站服务'
    self.timeout_seconds = 300

    def prepare
      @travel_date = Date.tomorrow
      @origin = '北京'
      @destination = '天津'
      @preferred_time = '08:00' # 早班车
      @station_location = '天津站'
      
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
        passenger_name: user.name,
        passenger_id_number: '110101199001011234'
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
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 100.0,
        status: 'pending',
        data_version: @data_version
      )
    end

    def verify
      # 断言1: 创建了汽车票订单
      add_assertion "创建了汽车票订单", weight: 30 do
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
      
      # 断言5: 创建了火车站接站服务
      add_assertion "创建了火车站接站服务", weight: 20 do
        @transfer = Transfer
          .where(transfer_type: 'train_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到火车站接站服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言6: 接站服务在目的地
      add_assertion "接站服务在目的地（#{@destination}）", weight: 10 do
        in_city = @transfer.location_from.include?(@destination) || @transfer.location_to.include?(@destination)
        expect(in_city).to be(true),
          "接站服务地点错误。期望包含: #{@destination}, 实际: #{@transfer.location_from} -> #{@transfer.location_to}"
      end
    end
  end
end
