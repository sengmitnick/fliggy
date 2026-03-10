# frozen_string_literal: true

require_relative '../base_validator'

# V149BookBusAndStationTransferValidator
# 验证用例149: 帮张三预订明天早班上海到杭州的汽车票，并预订杭州东站接站服务（接从北京来的朋友，中午12:18到达杭州东站，接至钱江新城）
#
# 任务描述:
#   张三计划明天早上从上海坐汽车到杭州,同时需要预订杭州东站接站服务，接从北京坐火车来的朋友（G32次列车，中午12:18到达杭州东站），接到钱江新城接送服务点。
#   1. 上海→杭州的汽车票（明天早班06:00-10:00）
#   2. 杭州东站接站服务（接从北京来的G32次列车，中午12:18到达杭州东站，接至钱江新城接送服务点）
#
# 任务分解步骤:
#   1. 查询上海→杭州的早班汽车票（departure_date=明天，departure_time在06:00-10:00之间）
#   2. 创建汽车票订单（乘客=张三）
#   3. 查询Train获取从北京到杭州的火车（G32，12:18到达杭州东站），确定出发城市、车次号、到达车站
#   4. 查询TransferLocation获取杭州钱江新城服务点（location_type='other'，名称包含'钱江新城'）
#   5. 创建接站服务订单（transfer_type=train_pickup，train_number=火车车次，location_from=火车到达车站，location_to=钱江新城服务点）
#
# 复杂度分析（5个复杂点）：
#   1. 多模块组合：需要同时创建汽车票订单+接站服务订单（2个不同类型的订单）
#   2. 时间窗口筛选：需要筛选早班班次（06:00-10:00）
#   3. 接站信息查询：需要从 Train 模型查询火车的 departure_city、train_number、arrival_station 字段（不硬编码）
#   4. 服务点查询：需要从 TransferLocation 查询具体的接送服务点（不使用笼统的"市区"）
#   5. 时间协调：需要协调汽车票到达时间与接站时间（确保接站服务在火车到达时间）
#
# 评分标准（总分100）：
#   1. 创建了汽车票订单（20分）
#   2. 出发地正确=上海（10分）
#   3. 目的地正确=杭州（10分）
#   4. 发车日期正确=明天（5分）
#   5. 选择了早班班次（06:00-10:00）（5分）
#   6. 乘车人信息正确=张三（10分）
#   7. 创建了火车站接站服务（15分）
#   8. 接站火车车次正确（从 Train.train_number 动态获取）（5分）
#   9. 接站上车点=火车到达车站（从 Train.arrival_station 动态获取）（10分）
#   10. 接站下车点=服务点（从 TransferLocation 动态获取）（10分）
#
# 使用方法:
#   rake validator:simulate_single[v149_book_bus_and_station_transfer_validator]
#
module V101V150
  class V149BookBusAndStationTransferValidator < BaseValidator
    self.validator_id = 'v149_book_bus_and_station_transfer_validator'
    self.task_id = 'd9e0f1a2-3b4c-5d6e-7f8a-9b0c1d2e3f4a'
    self.title = '帮张三预订明天早班上海到杭州的汽车票，并预订杭州东站接站服务（接从北京来的朋友，中午12:18到达杭州东站，接至钱江新城）'
    self.description = '帮张三预订明天早班上海到杭州的汽车票，并预订杭州东站接站服务（接从北京来的朋友，G32次列车，中午12:18到达杭州东站，接至钱江新城）'
    self.timeout_seconds = 300

    def prepare
      @travel_date = Date.tomorrow
      @origin = '上海'
      @destination = '杭州'
      @pickup_location = '杭州东站'
      
      # 查询火车信息（接站服务需要知道火车的出发城市、车次号、到达车站）
      # 查找从北京到杭州的G32次列车（中午12:18到达杭州东站，07:30出发）
      @train = Train.where(
        departure_city: '北京',
        arrival_city: @destination,
        data_version: 0
      ).find { |t| t.train_number == 'G32' && t.departure_time.hour == 7 && t.departure_time.min == 30 }
      
      raise "数据包缺少从北京到杭州的G32次列车（07:30出发，12:18到达）" unless @train
      
      # 从火车获取关键信息（接站服务需要知道出发城市、车次号、到达车站）
      @train_departure_city = @train.departure_city  # "北京"
      @train_number = @train.train_number  # "G32"
      @train_arrival_station = @train.arrival_station  # "杭州东站"
      
      # 查询TransferLocation获取杭州钱江新城服务点（接站下车点）
      @service_loc = TransferLocation.where(
        city: @destination,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('钱江新城') }
      
      raise "数据包缺少杭州钱江新城TransferLocation" unless @service_loc
      
      @service_location = @service_loc.name  # 服务点=钱江新城接送服务点（从TransferLocation动态获取）
      
      # 预查询乘客信息（用于 simulate 和 verify）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @zhangsan.name
      @expected_passenger_id = @zhangsan.id_number
      
      # 查找可用的汽车票（早班班次）
      @available_tickets = BusTicket
        .where(origin: @origin, destination: @destination, data_version: 0)
        .where(departure_date: @travel_date)
        .where("departure_time >= ?", '06:00')
        .where("departure_time <= ?", '10:00')
        .to_a
      
      expect(@available_tickets).not_to be_empty, "数据包缺少上海到杭州的早班汽车票"
    end

    def execution_state_data
      {
        travel_date: @travel_date&.iso8601,
        origin: @origin,
        destination: @destination,
        pickup_location: @pickup_location,
        train_number: @train_number,
        train_departure_city: @train_departure_city,
        train_arrival_station: @train_arrival_station,
        service_location: @service_location,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id
      }
    end

    def restore_from_state(state)
      @travel_date = Date.parse(state['travel_date']) if state['travel_date']
      @origin = state['origin']
      @destination = state['destination']
      @pickup_location = state['pickup_location']
      @train_number = state['train_number']
      @train_departure_city = state['train_departure_city']
      @train_arrival_station = state['train_arrival_station']
      @service_location = state['service_location']
      @expected_passenger_name = state['expected_passenger_name']
      @expected_passenger_id = state['expected_passenger_id']
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
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
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number
      )
      
      # 计算抵达时间，预订接站服务
      # 火车12:18到达，预留20分钟等待时间
      train_arrival_time = @train.arrival_time
      pickup_datetime = @travel_date.in_time_zone + train_arrival_time.hour.hours + train_arrival_time.min.minutes + 20.minutes
      
      # 创建接站服务订单（接从北京来的朋友，G32次列车，中午12:18到达杭州东站）
      Transfer.create!(
        user: user,
        transfer_type: 'train_pickup',
        train_number: @train_number,  # 火车车次
        location_from: @train_arrival_station,  # 上车点=火车到达车站（从Train.arrival_station动态获取）
        location_to: @service_location,  # 下车点=钱江新城接送服务点（从TransferLocation动态获取）
        pickup_datetime: pickup_datetime,
        passenger_name: passenger.name,
        passenger_phone: '13800138000',
        passenger_count: 1,
        total_price: 150,
        status: 'paid',
        data_version: @data_version
      )
    end

    def verify
      # 断言1: 创建了汽车票订单（20分）
      add_assertion "创建了汽车票订单", weight: 20 do
        all_orders = BusTicketOrder
          .joins(:bus_ticket)
          .includes(:bus_ticket, :passengers)
          .where(bus_tickets: { origin: @origin, destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_orders).not_to be_empty, "未找到任何汽车票订单"
        
        @bus_orders = all_orders
        expect(@bus_orders.size).to be >= 1, "订单数量不足。期望至少1个订单，实际找到#{@bus_orders.size}个订单"
      end
      
      return if @bus_orders.nil? || @bus_orders.empty?
      
      # 断言2: 出发地正确=上海（10分）
      add_assertion "出发地正确（#{@origin}）", weight: 10 do
        @bus_orders.each do |order|
          expect(order.bus_ticket.origin).to eq(@origin),
            "出发地错误。期望: #{@origin}, 实际: #{order.bus_ticket.origin}"
        end
      end
      
      # 断言3: 目的地正确=杭州（10分）
      add_assertion "目的地正确（#{@destination}）", weight: 10 do
        @bus_orders.each do |order|
          expect(order.bus_ticket.destination).to eq(@destination),
            "目的地错误。期望: #{@destination}, 实际: #{order.bus_ticket.destination}"
        end
      end
      
      # 断言4: 发车日期正确=明天（5分）
      add_assertion "发车日期正确（明天=#{@travel_date}）", weight: 5 do
        @bus_orders.each do |order|
          expect(order.bus_ticket.departure_date).to eq(@travel_date),
            "发车日期错误。期望: #{@travel_date}（明天）, 实际: #{order.bus_ticket.departure_date}"
        end
      end
      
      # 断言5: 选择了早班班次（06:00-10:00）（5分）
      add_assertion "选择了早班班次（06:00-10:00）", weight: 5 do
        @bus_orders.each do |order|
          departure_time = order.bus_ticket.departure_time
          expect(departure_time).not_to be_nil, "发车时间为空"
          
          # departure_time 已经是字符串格式（如 "06:00"）
          expect(departure_time >= '06:00' && departure_time <= '10:00').to be_truthy,
            "发车时间不在早班范围内。期望: 06:00-10:00之间, 实际: #{departure_time}"
        end
      end
      
      # 断言6: 乘车人信息正确=张三（10分）
      add_assertion "乘车人信息正确（#{@expected_passenger_name}）", weight: 10 do
        @bus_orders.each do |order|
          passengers = order.passengers.to_a
          expect(passengers).not_to be_empty, "订单#{order.id}没有乘客信息"
          
          zhangsan = passengers.find { |p| p.passenger_name == @expected_passenger_name }
          expect(zhangsan).not_to be_nil,
            "未找到#{@expected_passenger_name}。实际乘客: #{passengers.map(&:passenger_name).join(', ')}"
          
          expect(zhangsan.passenger_id_number).to eq(@expected_passenger_id),
            "身份证号错误。期望: #{@expected_passenger_id}, 实际: #{zhangsan.passenger_id_number}"
        end
      end
      
      # 断言7: 创建了火车站接站服务（15分）
      add_assertion "创建了火车站接站服务", weight: 15 do
        all_transfers = Transfer
          .where(transfer_type: 'train_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_transfers).not_to be_empty, "未找到任何火车站接站服务"
        
        @transfers = all_transfers
        expect(@transfers.size).to be >= 1, "接站服务数量不足。期望至少1个，实际找到#{@transfers.size}个"
      end
      
      return if @transfers.nil? || @transfers.empty?
      
      # 断言8: 接站火车车次正确（从 Train.train_number 动态获取）（5分）
      add_assertion "接站火车车次正确（#{@train_number}，从#{@train_departure_city}来的列车）", weight: 5 do
        @transfers.each do |transfer|
          expect(transfer.train_number).to eq(@train_number),
            "接站火车车次错误。期望: #{@train_number}（从#{@train_departure_city}来的列车）, 实际: #{transfer.train_number}"
        end
      end
      
      # 断言9: 接站上车点=火车到达车站（从 Train.arrival_station 动态获取）（10分）
      add_assertion "接站上车点正确（#{@train_arrival_station}，从Train.arrival_station动态获取）", weight: 10 do
        @transfers.each do |transfer|
          expect(transfer.location_from).to eq(@train_arrival_station),
            "接站上车点错误。期望: #{@train_arrival_station}（从Train.arrival_station动态获取）, 实际: #{transfer.location_from}"
        end
      end
      
      # 断言10: 接站下车点=服务点（从 TransferLocation 动态获取）（10分）
      add_assertion "接站下车点正确（#{@service_location}，从TransferLocation动态获取）", weight: 10 do
        @transfers.each do |transfer|
          expect(transfer.location_to).to eq(@service_location),
            "接站下车点错误。期望: #{@service_location}（从TransferLocation动态获取）, 实际: #{transfer.location_to}"
        end
      end
    end
  end
end
