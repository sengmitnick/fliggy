# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例151: 给张三订明天下午广州到深圳的汽车票，到达后订后天早上8点从福田中心区到深圳机场的送机服务
#
# 任务描述:
#   张三计划明天下午从广州坐汽车到深圳，并预订后天早上8点从福田中心区送他去深圳机场的送机服务。
#   1. 广州→深圳的汽车票（明天下午13:00-17:00）
#   2. 深圳机场送机服务（后天早上8:00，从福田中心区会展中心接送服务点出发，送至深圳宝安国际机场T3航站楼）
#
# 任务分解步骤:
#   1. 查询广州→深圳的下午汽车票（departure_date=明天，departure_time在13:00-17:00之间）
#   2. 创建汽车票订单（乘客=张三）
#   3. 查询TransferLocation获取深圳福田中心区服务点（location_type='other'，名称包含'福田'）（送机出发地）
#   4. 查询TransferLocation获取深圳机场位置（location_type='airport'，名称包含'宝安'）（送机目的地）
#   5. 创建送机服务订单（transfer_type=airport_dropoff，location_from=福田服务点，location_to=机场位置，pickup_datetime=后天早上8:00）
#
# 复杂度分析（5个复杂点）：
#   1. 多模块组合：需要同时创建汽车票订单+送机服务订单（2个不同类型的订单）
#   2. 时间窗口筛选：需要筛选下午班次（13:00-17:00）
#   3. 出发地查询：需要从 TransferLocation 查询具体的出发地服务点（福田中心区，不使用笼统的"市区"）
#   4. 机场位置查询：需要从 TransferLocation 查询具体的机场位置（宝安国际机场T3）
#   5. 明确时间：送机时间=后天早上8:00
#
# 评分标准（总分100）：
#   1. 创建了汽车票订单（20分）
#   2. 出发地正确=广州（10分）
#   3. 目的地正确=深圳（10分）
#   4. 发车日期正确=明天（5分）
#   5. 选择了下午班次（13:00-17:00）（5分）
#   6. 创建了机场送机服务（20分）
#   7. 送机出发地正确=福田中心区服务点（从 TransferLocation 动态获取）（10分）
#   8. 送机目的地正确=深圳宝安机场（从 TransferLocation 动态获取）（10分）
#   9. 送机时间正确=后天早上8:00（10分）
#
# 使用方法:
#   rake validator:simulate_single[v151_book_bus_and_airport_dropoff_validator]
#
module V151V200
  class V151BookBusAndAirportDropoffValidator < BaseValidator
    self.validator_id = 'v151_book_bus_and_airport_dropoff_validator'
    self.task_id = 'f1a2b3c4-5d6e-7f8a-9b0c-1d2e3f4a5b6c'
    self.title = '给张三订明天下午广州到深圳的汽车票，到达后订后天早上8点从福田中心区到深圳机场的送机服务'
    self.description = '给张三订明天下午广州到深圳的汽车票，到达后订后天早上8点从福田中心区到深圳机场的送机服务'
    self.timeout_seconds = 300

    def prepare
      @bus_travel_date = Date.tomorrow  # 明天坐汽车
      @pickup_date = Date.current + 2.days  # 后天送机
      @origin = '广州'
      @destination = '深圳'
      @pickup_time_str = '08:00'  # 明确的送机时间：后天早上8点
      
      # 查询TransferLocation获取深圳福田中心区服务点（送机出发地）
      @pickup_loc = TransferLocation.where(
        city: @destination,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('福田') }
      
      raise "数据包缺少深圳福田中心区TransferLocation" unless @pickup_loc
      
      @pickup_location = @pickup_loc.name  # 出发地=福田中心区会展中心接送服务点（从TransferLocation动态获取）
      
      # 查询TransferLocation获取深圳宝安机场位置（送机目的地）
      @airport_loc = TransferLocation.where(
        city: @destination,
        location_type: 'airport',
        data_version: 0
      ).find { |loc| loc.name.include?('宝安') }
      
      raise "数据包缺少深圳宝安机场TransferLocation" unless @airport_loc
      
      @airport_location = @airport_loc.name  # 机场位置=宝安国际机场T3航站楼（从TransferLocation动态获取）
      
      # 预查询乘客信息（用于 simulate 和 verify）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @zhangsan.name
      @expected_passenger_id = @zhangsan.id_number
      @expected_passenger_phone = @zhangsan.phone
      
      # 查找可用的汽车票（下午班次13:00-17:00）
      @available_tickets = BusTicket
        .where(origin: @origin, destination: @destination, data_version: 0)
        .where(departure_date: @bus_travel_date)
        .where("departure_time >= ?", '13:00')
        .where("departure_time <= ?", '17:00')
        .to_a
      
      expect(@available_tickets).not_to be_empty, "数据包缺少广州到深圳的下午汽车票"
      
      # 查找经济5座套餐（送机服务用）
      @available_packages = TransferPackage.where(
        vehicle_category: 'economy_5',
        data_version: 0
      ).order(:price)
      
      expect(@available_packages).not_to be_empty, "未找到经济5座套餐"
      
      @best_package = @available_packages.first
    end

    def execution_state_data
      {
        bus_travel_date: @bus_travel_date&.iso8601,
        pickup_date: @pickup_date&.iso8601,
        origin: @origin,
        destination: @destination,
        pickup_time_str: @pickup_time_str,
        pickup_location: @pickup_location,
        airport_location: @airport_location,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_passenger_phone: @expected_passenger_phone
      }
    end
    
    def restore_from_state(state)
      @bus_travel_date = Date.parse(state['bus_travel_date']) if state['bus_travel_date']
      @pickup_date = Date.parse(state['pickup_date']) if state['pickup_date']
      @origin = state['origin']
      @destination = state['destination']
      @pickup_time_str = state['pickup_time_str']
      @pickup_location = state['pickup_location']
      @airport_location = state['airport_location']
      @expected_passenger_name = state['expected_passenger_name']
      @expected_passenger_id = state['expected_passenger_id']
      @expected_passenger_phone = state['expected_passenger_phone']
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 选择汽车票
      bus_ticket = @available_tickets.first
      
      # 创建汽车票订单
      bus_order = BusTicketOrder.create!(
        user: user,
        bus_ticket: bus_ticket,
        passenger_count: 1,
        total_price: bus_ticket.price,
        status: 'paid',
        data_version: @data_version
      )
      
      bus_order.passengers.create!(
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number
      )
      
      # 构建明确的送机时间：后天早上8:00
      hour, minute = @pickup_time_str.split(':').map(&:to_i)
      pickup_datetime = @pickup_date.in_time_zone + hour.hours + minute.minutes
      
      # 创建机场送机服务
      Transfer.create!(
        user: user,
        transfer_package_id: @best_package.id,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: @pickup_location,  # 上车点=福田中心区服务点（从TransferLocation动态获取）
        location_to: @airport_location,  # 下车点=机场位置（从TransferLocation动态获取）
        pickup_datetime: pickup_datetime,  # 后天早上8:00
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        passenger_count: 1,
        luggage_count: 1,
        total_price: @best_package.price,
        discount_amount: 0,
        status: 'paid',
        driver_status: 'pending',
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
      
      # 断言2: 出发地正确=广州（10分）
      add_assertion "出发地正确（#{@origin}）", weight: 10 do
        @bus_orders.each do |order|
          expect(order.bus_ticket.origin).to eq(@origin),
            "出发地错误。期望: #{@origin}, 实际: #{order.bus_ticket.origin}"
        end
      end
      
      # 断言3: 目的地正确=深圳（10分）
      add_assertion "目的地正确（#{@destination}）", weight: 10 do
        @bus_orders.each do |order|
          expect(order.bus_ticket.destination).to eq(@destination),
            "目的地错误。期望: #{@destination}, 实际: #{order.bus_ticket.destination}"
        end
      end
      
      # 断言4: 发车日期正确=明天（5分）
      add_assertion "发车日期正确（明天=#{@bus_travel_date}）", weight: 5 do
        @bus_orders.each do |order|
          expect(order.bus_ticket.departure_date).to eq(@bus_travel_date),
            "发车日期错误。期望: #{@bus_travel_date}（明天）, 实际: #{order.bus_ticket.departure_date}"
        end
      end
      
      # 断言5: 选择了下午班次（13:00-17:00）（5分）
      add_assertion "选择了下午班次（13:00-17:00）", weight: 5 do
        @bus_orders.each do |order|
          departure_time = order.bus_ticket.departure_time
          expect(departure_time).not_to be_nil, "发车时间为空"
          
          # departure_time 已经是字符串格式（如 "14:00"）
          expect(departure_time >= '13:00' && departure_time <= '17:00').to be_truthy,
            "发车时间不在下午范围内。期望: 13:00-17:00之间, 实际: #{departure_time}"
        end
      end
      
      # 断言6: 创建了机场送机服务（20分）
      add_assertion "创建了机场送机服务", weight: 20 do
        all_transfers = Transfer
          .where(transfer_type: 'airport_dropoff', data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_transfers).not_to be_empty, "未找到任何机场送机服务"
        
        @transfers = all_transfers
        expect(@transfers.size).to be >= 1, "送机服务数量不足。期望至少1个，实际找到#{@transfers.size}个"
      end
      
      return if @transfers.nil? || @transfers.empty?
      
      # 断言7: 送机出发地正确=福田中心区服务点（从 TransferLocation 动态获取）（10分）
      add_assertion "送机出发地正确（#{@pickup_location}，从TransferLocation动态获取）", weight: 10 do
        @transfers.each do |transfer|
          expect(transfer.location_from).to eq(@pickup_location),
            "送机出发地错误。期望: #{@pickup_location}（从TransferLocation动态获取）, 实际: #{transfer.location_from}"
        end
      end
      
      # 断言8: 送机目的地正确=深圳宝安机场（从 TransferLocation 动态获取）（10分）
      add_assertion "送机目的地正确（#{@airport_location}，从TransferLocation动态获取）", weight: 10 do
        @transfers.each do |transfer|
          expect(transfer.location_to).to eq(@airport_location),
            "送机目的地错误。期望: #{@airport_location}（从TransferLocation动态获取）, 实际: #{transfer.location_to}"
        end
      end
      
      # 断言9: 送机时间正确=后天早上8:00（10分）
      add_assertion "送机时间正确（后天早上#{@pickup_time_str}）", weight: 10 do
        hour, minute = @pickup_time_str.split(':').map(&:to_i)
        expected_pickup_time = @pickup_date.in_time_zone + hour.hours + minute.minutes
        
        @transfers.each do |transfer|
          actual_pickup_time = transfer.pickup_datetime
          time_diff = (actual_pickup_time - expected_pickup_time).abs
          
          expect(time_diff).to be <= 600, # 允许10分钟误差
            "送机时间不正确。期望: #{expected_pickup_time.strftime('%Y-%m-%d %H:%M')}（后天早上#{@pickup_time_str}）, 实际: #{actual_pickup_time.strftime('%Y-%m-%d %H:%M')}"
        end
      end
    end
  end
end
