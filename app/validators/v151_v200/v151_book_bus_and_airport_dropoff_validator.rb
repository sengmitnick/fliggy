# frozen_string_literal: true

require_relative '../base_validator'

# V151: 预订广州到深圳汽车票 + 机场送机服务
# 验证用户能够完成汽车票预订+机场送机服务的组合下单

module V151V200
  class V151BookBusAndAirportDropoffValidator < BaseValidator
    self.validator_id = 'v151_book_bus_and_airport_dropoff_validator'
    self.task_id = 'f1a2b3c4-5d6e-7f8a-9b0c-1d2e3f4a5b6c'
    self.title = '预订汽车票后预订机场送机服务（广州-深圳）'
    self.description = '预订明天下午广州到深圳的汽车票，并预订深圳机场送机服务'
    self.timeout_seconds = 300

    def prepare
      @travel_date = Date.tomorrow
      @origin = '广州'
      @destination = '深圳'
      @dropoff_location = '深圳宝安国际机场'
      
      # 查找可用的汽车票（下午班次）
      @available_tickets = BusTicket
        .where(origin: @origin, destination: @destination, data_version: 0)
        .where(departure_date: @travel_date)
        .where("departure_time >= ?", '13:00')
        .where("departure_time <= ?", '17:00')
        .to_a
      
      expect(@available_tickets).not_to be_empty, "数据包缺少广州到深圳的下午汽车票"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      ticket = @available_tickets.first
      
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
      
      # 计算抵达时间，预订送机服务
      arrival_time = Time.parse(ticket.arrival_time)
      pickup_datetime = @travel_date.in_time_zone + arrival_time.hour.hours + arrival_time.min.minutes + 60.minutes
      
      # 创建机场送机服务
      Transfer.create!(
        user: user,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: "#{@destination}市区",
        location_to: @dropoff_location,
        pickup_datetime: pickup_datetime,
        vehicle_type: 'economy_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 100.0,
        status: 'pending',
        data_version: @data_version
      )
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
      
      # 断言5: 选择了下午车次
      add_assertion "选择了下午车次（13:00-17:00）", weight: 10 do
        dep_time = Time.parse(@bus_order.bus_ticket.departure_time)
        is_afternoon = dep_time.hour >= 13 && dep_time.hour <= 17
        expect(is_afternoon).to be(true),
          "未选择下午车次。实际发车时间: #{@bus_order.bus_ticket.departure_time}"
      end
      
      # 断言6: 创建了机场送机服务
      add_assertion "创建了机场送机服务", weight: 15 do
        @transfer = Transfer
          .where(transfer_type: 'airport_dropoff', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到机场送机服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言7: 送机目的地正确
      add_assertion "送机目的地正确（#{@dropoff_location}）", weight: 10 do
        expect(@transfer.location_to).to eq(@dropoff_location),
          "送机目的地错误。期望: #{@dropoff_location}, 实际: #{@transfer.location_to}"
      end
    end
  end
end
