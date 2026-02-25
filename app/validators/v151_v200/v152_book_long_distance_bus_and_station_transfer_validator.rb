# frozen_string_literal: true

require_relative '../base_validator'

# V152: 预订杭州到深圳长途汽车票 + 深圳北站接站服务（关联具体火车）
# 验证用户能够完成长途汽车票预订+火车站接站服务的组合下单，接站需关联具体火车班次

module V151V200
  class V152BookLongDistanceBusAndStationTransferValidator < BaseValidator
    self.validator_id = 'v152_book_long_distance_bus_and_station_transfer_validator'
    self.task_id = 'a2b3c4d5-6e7f-8a9b-0c1d-2e3f4a5b6c7d'
    self.title = '给张三订明天杭州到深圳的长途汽车票，到达后订深圳北站接站服务（接后天从上海坐火车来的朋友）'
    self.description = '给张三订明天杭州到深圳的长途汽车票，到达后订深圳北站接站服务（接后天从上海坐火车来的朋友）'
    self.timeout_seconds = 300

    def prepare
      @bus_travel_date = Date.tomorrow  # 明天坐长途汽车
      @train_arrival_date = Date.current + 2.days  # 后天火车到达
      @origin = '杭州'
      @destination = '深圳'
      @pickup_location = '深圳北站'
      @train_origin = '上海'
      
      # 预查询乘客信息（避免 simulate 中查询 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_name = @passenger.name
      @expected_phone = @passenger.phone
      @expected_id_number = @passenger.id_number
      
      # 查找可用的长途汽车票
      @available_bus_tickets = BusTicket
        .where(origin: @origin, destination: @destination, data_version: 0)
        .where(departure_date: @bus_travel_date)
        .to_a
      
      expect(@available_bus_tickets).not_to be_empty, "数据包缺少杭州到深圳的长途汽车票"
      
      # 查找后天从上海到深圳北站的火车
      @available_trains = Train
        .where(departure_city: @train_origin, arrival_city: @destination, data_version: 0)
        .by_date(@train_arrival_date)
        .where("arrival_station LIKE ?", "%北站%")
        .to_a
      
      expect(@available_trains).not_to be_empty, "数据包缺少上海到深圳北站的火车"
      
      # 查找经济5座套餐
      @available_packages = TransferPackage.where(
        vehicle_category: 'economy_5',
        data_version: 0
      ).order(:price)
      
      expect(@available_packages).not_to be_empty, "未找到经济5座套餐"
      
      @best_package = @available_packages.first
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      bus_ticket = @available_bus_tickets.first
      
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
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number
      )
      
      # 选择后天到达的火车
      target_train = @available_trains.min_by { |t| t.arrival_time }
      raise "未找到可用火车" unless target_train
      
      # 计算接站时间（火车到达后15分钟）
      pickup_datetime = target_train.arrival_time + 15.minutes
      
      # 创建火车站接站服务（关联火车号）
      Transfer.create!(
        user: user,
        transfer_package_id: @best_package.id,
        transfer_type: 'train_pickup',
        service_type: 'from_station',
        location_from: @pickup_location,
        location_to: "#{@destination}市区",
        pickup_datetime: pickup_datetime,
        train_number: target_train.train_number,  # 关键：关联火车号
        passenger_name: @passenger.name,
        passenger_phone: @passenger.phone,
        passenger_count: 1,
        luggage_count: 1,
        total_price: @best_package.price,
        discount_amount: 0,
        status: 'paid',
        driver_status: 'pending',
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        bus_travel_date: @bus_travel_date.to_s,
        train_arrival_date: @train_arrival_date.to_s,
        origin: @origin,
        destination: @destination,
        pickup_location: @pickup_location,
        train_origin: @train_origin
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @bus_travel_date = Date.parse(data['bus_travel_date']) if data['bus_travel_date']
      @train_arrival_date = Date.parse(data['train_arrival_date']) if data['train_arrival_date']
      @origin = data['origin']
      @destination = data['destination']
      @pickup_location = data['pickup_location']
      @train_origin = data['train_origin']
      
      # 重新查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_name = @passenger.name
      @expected_phone = @passenger.phone
      @expected_id_number = @passenger.id_number
      
      # 重新查询汽车票
      @available_bus_tickets = BusTicket
        .where(origin: @origin, destination: @destination, data_version: 0)
        .where(departure_date: @bus_travel_date)
        .to_a
      
      # 重新查询火车
      @available_trains = Train
        .where(departure_city: @train_origin, arrival_city: @destination, data_version: 0)
        .by_date(@train_arrival_date)
        .where("arrival_station LIKE ?", "%北站%")
        .to_a
      
      # 重新查询套餐
      @available_packages = TransferPackage.where(
        vehicle_category: 'economy_5',
        data_version: 0
      ).order(:price)
      
      @best_package = @available_packages.first if @available_packages.any?
    end

    def verify
      # 断言1: 创建了长途汽车票订单
      add_assertion "创建了长途汽车票订单", weight: 20 do
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
      add_assertion "出发地正确（#{@origin}）", weight: 10 do
        expect(@bus_order.bus_ticket.origin).to eq(@origin),
          "出发地错误。期望: #{@origin}, 实际: #{@bus_order.bus_ticket.origin}"
      end
      
      # 断言3: 目的地正确
      add_assertion "目的地正确（#{@destination}）", weight: 10 do
        expect(@bus_order.bus_ticket.destination).to eq(@destination),
          "目的地错误。期望: #{@destination}, 实际: #{@bus_order.bus_ticket.destination}"
      end
      
      # 断言4: 发车日期正确
      add_assertion "发车日期正确（#{@bus_travel_date}）", weight: 5 do
        expect(@bus_order.bus_ticket.departure_date).to eq(@bus_travel_date),
          "发车日期错误。期望: #{@bus_travel_date}（明天）, 实际: #{@bus_order.bus_ticket.departure_date}"
      end
      
      # 断言5: 创建了火车站接站服务
      add_assertion "创建了火车站接站服务", weight: 15 do
        @transfer = Transfer
          .where(transfer_type: 'train_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到火车站接站服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言6: 接站地点正确
      add_assertion "接站地点正确（#{@pickup_location}）", weight: 5 do
        location_matches = @transfer.location_from.include?('深圳') && @transfer.location_from.include?('北')
        expect(location_matches).to be(true),
          "接站地点错误。期望: #{@pickup_location}, 实际: #{@transfer.location_from}"
      end
      
      # 断言7: 接站服务关联了具体火车号
      add_assertion "接站服务关联了具体火车号（#{@train_origin}→#{@destination}）", weight: 20 do
        expect(@transfer.train_number).not_to be_nil, "接站服务未关联火车号"
        
        # 验证火车号对应的火车确实是上海到深圳北站
        train = Train.find_by(
          train_number: @transfer.train_number,
          departure_city: @train_origin,
          arrival_city: @destination,
          data_version: 0
        )
        
        expect(train).not_to be_nil,
          "火车号#{@transfer.train_number}不是#{@train_origin}到#{@destination}的火车"
        
        # 验证到达站是深圳北站
        if train
          expect(train.arrival_station).to include('北'),
            "火车到达站错误。期望: 深圳北站, 实际: #{train.arrival_station}"
        end
      end
      
      # 断言8: 接站时间合理（火车到达后10-30分钟）
      add_assertion "接站时间合理（火车到达后10-30分钟）", weight: 10 do
        if @transfer.train_number.present?
          # 查询对应的火车（必须指定日期）
          train = Train
            .where(train_number: @transfer.train_number, data_version: 0)
            .where(departure_city: @train_origin, arrival_city: @destination)
            .by_date(@train_arrival_date)
            .first
          
          if train && train.arrival_time.present?
            time_after_arrival = ((@transfer.pickup_datetime - train.arrival_time) / 60.0).round
            is_reasonable = time_after_arrival >= 10 && time_after_arrival <= 30
            
            expect(is_reasonable).to be(true),
              "接站时间不合理。火车#{train.arrival_time.strftime('%H:%M')}到达，" \
              "接站时间#{@transfer.pickup_datetime.strftime('%H:%M')}，" \
              "间隔#{time_after_arrival}分钟（应为10-30分钟）"
          end
        end
      end
      
      # 断言9: 乘客信息正确（张三）
      add_assertion "乘客信息正确（张三）", weight: 5 do
        passengers = @bus_order.passengers.to_a
        expect(passengers).not_to be_empty, "汽车票订单缺少乘客信息"
        
        zhangsan = passengers.find { |p| p.passenger_name == @expected_name }
        expect(zhangsan).not_to be_nil, "未找到张三的乘客信息"
        expect(zhangsan.passenger_id_number).to eq(@expected_id_number),
          "身份证号错误。期望: #{@expected_id_number}, 实际: #{zhangsan.passenger_id_number}"
      end
    end
  end
end
