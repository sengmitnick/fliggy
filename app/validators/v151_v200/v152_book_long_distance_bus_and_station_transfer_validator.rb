# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例152: 给张三订明天杭州到深圳的长途汽车票，到达后订深圳北站接站服务（接后天从上海来的朋友，G1303次下午4:30到，5点接，送到福田中心区）
#
# 任务描述:
#   张三计划明天从杭州坐长途汽车到深圳，并预订深圳北站接站服务送到福田中心区，接后天从上海来的朋友（G1303次列车，下午16:30到达，17:00接站）。
#   1. 杭州→深圳的长途汽车票（明天）
#   2. 深圳北站接站服务（从深圳北站接站，送至福田中心区，接后天从上海来的朋友G1303次，列车16:30到达，接站时间17:00）
#
# 任务分解步骤:
#   1. 查询杭州→深圳的长途汽车票（departure_date=明天）
#   2. 创建长途汽车票订单（乘客=张三）
#   3. 查询Train获取后天从上海到深圳北站的列车，确定列车号、到达时间
#   4. 查询TransferLocation获取深圳北站（location_type='train_station'，名称包含'深圳北站'）（接站地点）
#   5. 查询TransferLocation获取深圳福田中心区服务点（location_type='other'，名称包含'福田'）（送达地点）
#   6. 创建接站服务订单（transfer_type=train_pickup，train_number=列车号，location_from=深圳北站，location_to=福田服务点，pickup_datetime=列车到达后30分钟）
#
# 复杂度分析（6个复杂点）：
#   1. 多模块组合：需要同时创建长途汽车票订单+接站服务订单（2个不同类型的订单）
#   2. 列车信息查询：需要从 Train 模型查询朋友从上海来的列车信息（train_number、arrival_time）
#   3. 接站地点查询：需要从 TransferLocation 查询具体的接站地点（深圳北站，location_type='train_station'）
#   4. 送达地点查询：需要从 TransferLocation 查询具体的送达地点（福田中心区，不使用笼统的"市区"）
#   5. 时间计算：接站时间=列车到达后30分钟
#   6. 跨日期协调：汽车票明天，接站服务后天
#
# 评分标准（总分100）：
#   1. 创建了长途汽车票订单（20分）
#   2. 出发地正确=杭州（8分）
#   3. 目的地正确=深圳（8分）
#   4. 发车日期正确=明天（5分）
#   5. 创建了接站服务（20分）
#   6. 接站地点正确=深圳北站（从 TransferLocation 动态获取）（10分）
#   7. 送达地点正确=福田中心区服务点（从 TransferLocation 动态获取）（10分）
#   8. 接站服务关联了具体列车号（从上海来的列车）（10分）
#   9. 接站时间合理（列车到达后20-40分钟）（4分）
#   10. 乘客信息正确（张三）（5分）
#
# 使用方法:
#   rake validator:simulate_single[v152_book_long_distance_bus_and_station_transfer_validator]
#
module V151V200
  class V152BookLongDistanceBusAndStationTransferValidator < BaseValidator
    self.validator_id = 'v152_book_long_distance_bus_and_station_transfer_validator'
    self.task_id = 'a2b3c4d5-6e7f-8a9b-0c1d-2e3f4a5b6c7d'
    self.title = '给张三订明天杭州到深圳的长途汽车票，到达后订深圳北站接站服务（接后天从上海来的朋友，G1303次下午4:30到，5点接，送到福田中心区）'
    self.description = '给张三订明天杭州到深圳的长途汽车票，到达后订深圳北站接站服务（接后天从上海来的朋友，G1303次列车，下午16:30到达深圳北站，17:00接站，送到福田中心区）'
    self.timeout_seconds = 300

    def prepare
      @bus_travel_date = Date.tomorrow  # 明天坐长途汽车
      @pickup_date = Date.current + 2.days  # 后天接站
      @origin = '杭州'
      @destination = '深圳'
      @friend_origin = '上海'  # 朋友从上海来
      
      # 查询后天从上海到深圳北站的列车（获取列车号、到达时间）
      @train = Train.where(
        departure_city: @friend_origin,
        arrival_city: @destination,
        data_version: 0
      ).by_date(@pickup_date).find { |t| t.arrival_station.include?('深圳北站') }
      
      raise "数据包缺少后天从#{@friend_origin}到#{@destination}北站的列车" unless @train
      
      # 从列车获取关键信息
      @train_number = @train.train_number  # 列车号
      @train_arrival_time = @train.arrival_time  # 到达时间
      @train_arrival_station = @train.arrival_station  # 到达车站（接站点=高铁在哪下就在哪接）
      
      # 查询TransferLocation获取深圳福田中心区服务点（送达地点）
      @dropoff_loc = TransferLocation.where(
        city: @destination,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('福田') }
      
      raise "数据包缺少深圳福田中心区TransferLocation" unless @dropoff_loc
      
      @dropoff_location = @dropoff_loc.name  # 送达地点=福田中心区会展中心接送服务点（从TransferLocation动态获取）
      
      # 预查询乘客信息（用于 simulate 和 verify）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @zhangsan.name
      @expected_passenger_id = @zhangsan.id_number
      @expected_passenger_phone = @zhangsan.phone
      
      # 查找可用的长途汽车票
      @available_tickets = BusTicket
        .where(origin: @origin, destination: @destination, data_version: 0)
        .where(departure_date: @bus_travel_date)
        .to_a
      
      expect(@available_tickets).not_to be_empty, "数据包缺少杭州到深圳的长途汽车票"
      
      # 查找经济5座套餐（接站服务用）
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
        friend_origin: @friend_origin,
        train_number: @train_number,
        train_arrival_station: @train_arrival_station,
        dropoff_location: @dropoff_location,
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
      @friend_origin = state['friend_origin']
      @train_number = state['train_number']
      @train_arrival_station = state['train_arrival_station']
      @dropoff_location = state['dropoff_location']
      @expected_passenger_name = state['expected_passenger_name']
      @expected_passenger_id = state['expected_passenger_id']
      @expected_passenger_phone = state['expected_passenger_phone']
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 选择长途汽车票
      bus_ticket = @available_tickets.first
      
      # 创建长途汽车票订单
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
      
      # 计算接站时间（列车到达后30分钟）
      pickup_datetime = @train_arrival_time + 30.minutes
      
      # 创建接站服务（关联列车号）
      Transfer.create!(
        user: user,
        transfer_package_id: @best_package.id,
        transfer_type: 'train_pickup',
        service_type: 'from_station',
        location_from: @train_arrival_station,  # 接站地点=列车到达车站（从Train.arrival_station动态获取）
        location_to: @dropoff_location,  # 送达地点=福田服务点（从TransferLocation动态获取）
        pickup_datetime: pickup_datetime,  # 列车到达后30分钟
        train_number: @train_number,  # 关联列车号（从Train动态获取）
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
      # 断言1: 创建了长途汽车票订单（20分）
      add_assertion "创建了长途汽车票订单", weight: 20 do
        all_orders = BusTicketOrder
          .joins(:bus_ticket)
          .includes(:bus_ticket, :passengers)
          .where(bus_tickets: { origin: @origin, destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_orders).not_to be_empty, "未找到任何长途汽车票订单"
        
        @bus_orders = all_orders
        expect(@bus_orders.size).to be >= 1, "订单数量不足。期望至少1个订单，实际找到#{@bus_orders.size}个订单"
      end
      
      return if @bus_orders.nil? || @bus_orders.empty?
      
      # 断言2: 出发地正确=杭州（8分）
      add_assertion "出发地正确（#{@origin}）", weight: 8 do
        @bus_orders.each do |order|
          expect(order.bus_ticket.origin).to eq(@origin),
            "出发地错误。期望: #{@origin}, 实际: #{order.bus_ticket.origin}"
        end
      end
      
      # 断言3: 目的地正确=深圳（8分）
      add_assertion "目的地正确（#{@destination}）", weight: 8 do
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
      
      # 断言5: 创建了接站服务（20分）
      add_assertion "创建了接站服务", weight: 20 do
        all_transfers = Transfer
          .where(transfer_type: 'train_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_transfers).not_to be_empty, "未找到任何接站服务"
        
        @transfers = all_transfers
        expect(@transfers.size).to be >= 1, "接站服务数量不足。期望至少1个，实际找到#{@transfers.size}个"
      end
      
      return if @transfers.nil? || @transfers.empty?
      
      # 断言6: 接站地点正确=列车到达车站（从 Train.arrival_station 动态获取）（10分）
      add_assertion "接站地点正确（#{@train_arrival_station}，从Train.arrival_station动态获取）", weight: 10 do
        @transfers.each do |transfer|
          expect(transfer.location_from).to eq(@train_arrival_station),
            "接站地点错误。期望: #{@train_arrival_station}（从Train.arrival_station动态获取）, 实际: #{transfer.location_from}"
        end
      end
      
      # 断言7: 送达地点正确=福田中心区服务点（从 TransferLocation 动态获取）（10分）
      add_assertion "送达地点正确（#{@dropoff_location}，从TransferLocation动态获取）", weight: 10 do
        @transfers.each do |transfer|
          expect(transfer.location_to).to eq(@dropoff_location),
            "送达地点错误。期望: #{@dropoff_location}（从TransferLocation动态获取）, 实际: #{transfer.location_to}"
        end
      end
      
      # 断言8: 接站服务关联了具体列车号（从上海来的列车）（10分）
      add_assertion "接站服务关联了具体列车号（#{@friend_origin}→#{@destination}）", weight: 10 do
        @transfers.each do |transfer|
          expect(transfer.train_number).not_to be_nil, "接站服务未关联列车号"
          
          # 验证列车号对应的列车确实是从上海到深圳的
          train = Train.find_by(
            train_number: transfer.train_number,
            departure_city: @friend_origin,
            arrival_city: @destination,
            data_version: 0
          )
          
          expect(train).not_to be_nil,
            "列车号#{transfer.train_number}不是#{@friend_origin}到#{@destination}的列车"
          
          # 验证到达站是深圳北站
          if train
            expect(train.arrival_station).to include('深圳北站'),
              "列车到达站错误。期望: 深圳北站, 实际: #{train.arrival_station}"
          end
        end
      end
      
      # 断言9: 接站时间合理（列车到达后20-40分钟）（4分）
      add_assertion "接站时间合理（列车到达后20-40分钟）", weight: 4 do
        @transfers.each do |transfer|
          if transfer.train_number.present?
            # 查询对应的列车（必须指定日期）
            train = Train
              .where(train_number: transfer.train_number, data_version: 0)
              .where(departure_city: @friend_origin, arrival_city: @destination)
              .by_date(@pickup_date)
              .first
            
            if train && train.arrival_time.present?
              time_after_arrival = ((transfer.pickup_datetime - train.arrival_time) / 60.0).round
              is_reasonable = time_after_arrival >= 20 && time_after_arrival <= 40
              
              expect(is_reasonable).to be(true),
                "接站时间不合理。列车#{train.arrival_time.strftime('%H:%M')}到达，" \
                "接站时间#{transfer.pickup_datetime.strftime('%H:%M')}，" \
                "间隔#{time_after_arrival}分钟（应为20-40分钟）"
            end
          end
        end
      end
      
      # 断言10: 乘客信息正确（张三）（5分）
      add_assertion "乘客信息正确（张三）", weight: 5 do
        @bus_orders.each do |order|
          passengers = order.passengers.to_a
          expect(passengers).not_to be_empty, "汽车票订单缺少乘客信息"
          
          zhangsan = passengers.find { |p| p.passenger_name == @expected_passenger_name }
          expect(zhangsan).not_to be_nil, "未找到#{@expected_passenger_name}的乘客信息"
          expect(zhangsan.passenger_id_number).to eq(@expected_passenger_id),
            "身份证号错误。期望: #{@expected_passenger_id}, 实际: #{zhangsan.passenger_id_number}"
        end
      end
    end
  end
end
