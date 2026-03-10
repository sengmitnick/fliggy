# frozen_string_literal: true

require_relative '../base_validator'

# V150BookBusAndCityCharterValidator
# 验证用例150: 帮李四预订明天傍晚杭州到上海的汽车票，并预订杭州东站接站服务（接从上海来的朋友，早上07:25到达杭州东站，接至西湖风景区）
#
# 任务描述:
#   李四计划明天傍晚从杭州坐汽车到上海，但在出发前需要先接从上海坐火车来的朋友（G7302次列车，早上07:25到达杭州东站），接到西湖风景区游览一天后，再一起坐汽车去上海。
#   1. 杭州→上海的汽车票（明天傍晚18:00-21:00，给足时间接人游览一天）
#   2. 杭州东站接站服务（接从上海来的G7302次列车，早上07:25到达杭州东站，接至西湖风景区）
#
# 任务分解步骤:
#   1. 查询杭州→上海的傍晚汽车票（departure_date=明天，departure_time在18:00-21:00之间，给接人游览留足时间）
#   2. 创建汽车票订单（乘客=李四）
#   3. 查询Train获取从上海到杭州的火车（G7302，07:25到达杭州东站），确定出发城市、车次号、到达车站
#   4. 查询TransferLocation获取杭州西湖风景区服务点（location_type='other'，名称包含'西湖'）
#   5. 创建接站服务订单（transfer_type=train_pickup，train_number=火车车次，location_from=火车到达车站，location_to=西湖风景区）
#
# 复杂度分析（5个复杂点）：
#   1. 多模块组合：需要同时创建汽车票订单+接站服务订单（2个不同类型的订单）
#   2. 时间窗口筛选：需要筛选上午班次（10:00-14:00，留足接人游览时间）
#   3. 接站信息查询：需要从 Train 模型查询火车的 departure_city、train_number、arrival_station 字段（不硬编码）
#   4. 服务点查询：需要从 TransferLocation 查询具体的接送服务点（西湖风景区，不使用笼统的"市区"）
#   5. 时间协调：需要协调接站时间与汽车票发车时间（确保有足够时间接人+游览一天+赶车）
#
# 评分标准（总分100）：
#   1. 创建了汽车票订单（20分）
#   2. 出发地正确=杭州（10分）
#   3. 目的地正确=上海（10分）
#   4. 发车日期正确=明天（5分）
#   5. 选择了傍晚班次（18:00-21:00）（5分）
#   6. 乘车人信息正确=李四（10分）
#   7. 创建了火车站接站服务（15分）
#   8. 接站火车车次正确（从 Train.train_number 动态获取）（5分）
#   9. 接站上车点=火车到达车站（从 Train.arrival_station 动态获取）（10分）
#   10. 接站下车点=西湖风景区（从 TransferLocation 动态获取）（10分）
#
# 使用方法:
#   rake validator:simulate_single[v150_book_bus_and_city_charter_validator]
#
module V101V150
  class V150BookBusAndCityCharterValidator < BaseValidator
    self.validator_id = 'v150_book_bus_and_city_charter_validator'
    self.task_id = 'e0f1a2b3-4c5d-6e7f-8a9b-0c1d2e3f4a5b'
    self.title = '帮李四预订明天傍晚杭州到上海的汽车票，并预订杭州东站接站服务（接从上海来的朋友，早上07:25到达杭州东站，接至西湖风景区）'
    self.description = '帮李四预订明天傍晚杭州到上海的汽车票，并预订杭州东站接站服务（接从上海来的朋友，G7302次列车，早上07:25到达杭州东站，接至西湖风景区）'
    self.timeout_seconds = 300

    def prepare
      @travel_date = Date.tomorrow
      @origin = '杭州'
      @destination = '上海'
      @pickup_location = '杭州东站'
      
      # 查询火车信息（接站服务需要知道火车的出发城市、车次号、到达车站）
      # 查找从上海到杭州的G7302次列车（早上07:25到达杭州东站）
      @train = Train.where(
        departure_city: '上海',
        arrival_city: '杭州',
        data_version: 0
      ).find { |t| t.train_number == 'G7302' && t.arrival_time.hour == 7 && t.arrival_time.min == 25 }
      
      raise "数据包缺少从上海到杭州的G7302次列车（07:25到达）" unless @train
      
      # 从火车获取关键信息（接站服务需要知道出发城市、车次号、到达车站）
      @train_departure_city = @train.departure_city  # "上海"
      @train_number = @train.train_number  # "G7302"
      @train_arrival_station = @train.arrival_station  # "杭州东站"
      
      # 查询TransferLocation获取杭州西湖风景区服务点（接站下车点）
      @service_loc = TransferLocation.where(
        city: '杭州',
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('西湖') }
      
      raise "数据包缺少杭州西湖风景区TransferLocation" unless @service_loc
      
      @service_location = @service_loc.name  # 服务点=西湖风景区（从TransferLocation动态获取）
      
      # 预查询乘客信息（用于 simulate 和 verify）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_passenger_name = @lisi.name
      @expected_passenger_id = @lisi.id_number
      
      # 查找可用的汽车票（傍晚班次，18:00-21:00，留足接人游览一天时间）
      @available_tickets = BusTicket
        .where(origin: @origin, destination: @destination, data_version: 0)
        .where(departure_date: @travel_date)
        .where("departure_time >= ?", '18:00')
        .where("departure_time <= ?", '21:00')
        .to_a
      
      expect(@available_tickets).not_to be_empty, "数据包缺少杭州到上海的傍晚汽车票"
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
      passenger = user.passengers.find_by!(name: '李四', data_version: 0)
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
      
      # 计算接站时间
      # 火车07:25到达，预留10分钟等待时间
      train_arrival_time = @train.arrival_time
      pickup_datetime = @travel_date.in_time_zone + train_arrival_time.hour.hours + train_arrival_time.min.minutes + 10.minutes
      
      # 创建接站服务订单（接从上海来的朋友，G7302次列车，早上07:25到达杭州东站）
      Transfer.create!(
        user: user,
        transfer_type: 'train_pickup',
        train_number: @train_number,  # 火车车次
        location_from: @train_arrival_station,  # 上车点=火车到达车站（从Train.arrival_station动态获取）
        location_to: @service_location,  # 下车点=西湖风景区（从TransferLocation动态获取）
        pickup_datetime: pickup_datetime,
        passenger_name: passenger.name,
        passenger_phone: '13900139000',
        passenger_count: 1,
        total_price: 100,
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
      
      # 断言2: 出发地正确=杭州（10分）
      add_assertion "出发地正确（#{@origin}）", weight: 10 do
        @bus_orders.each do |order|
          expect(order.bus_ticket.origin).to eq(@origin),
            "出发地错误。期望: #{@origin}, 实际: #{order.bus_ticket.origin}"
        end
      end
      
      # 断言3: 目的地正确=上海（10分）
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
      
      # 断言5: 选择了傍晚班次（18:00-21:00）（5分）
      add_assertion "选择了傍晚班次（18:00-21:00）", weight: 5 do
        @bus_orders.each do |order|
          departure_time = order.bus_ticket.departure_time
          expect(departure_time).not_to be_nil, "发车时间为空"
          
          # departure_time 已经是字符串格式（如 "18:00"）
          expect(departure_time >= '18:00' && departure_time <= '21:00').to be_truthy,
            "发车时间不在傍晚范围内。期望: 18:00-21:00之间, 实际: #{departure_time}"
        end
      end
      
      # 断言6: 乘车人信息正确=李四（10分）
      add_assertion "乘车人信息正确（#{@expected_passenger_name}）", weight: 10 do
        @bus_orders.each do |order|
          passengers = order.passengers.to_a
          expect(passengers).not_to be_empty, "订单#{order.id}没有乘客信息"
          
          lisi = passengers.find { |p| p.passenger_name == @expected_passenger_name }
          expect(lisi).not_to be_nil,
            "未找到#{@expected_passenger_name}。实际乘客: #{passengers.map(&:passenger_name).join(', ')}"
          
          expect(lisi.passenger_id_number).to eq(@expected_passenger_id),
            "身份证号错误。期望: #{@expected_passenger_id}, 实际: #{lisi.passenger_id_number}"
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
      
      # 断言10: 接站下车点=西湖风景区（从 TransferLocation 动态获取）（10分）
      add_assertion "接站下车点正确（#{@service_location}，从TransferLocation动态获取）", weight: 10 do
        @transfers.each do |transfer|
          expect(transfer.location_to).to eq(@service_location),
            "接站下车点错误。期望: #{@service_location}（从TransferLocation动态获取）, 实际: #{transfer.location_to}"
        end
      end
    end
  end
end
