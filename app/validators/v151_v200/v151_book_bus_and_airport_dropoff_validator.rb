# frozen_string_literal: true

require_relative '../base_validator'

# V151: 预订广州到深圳汽车票 + 深圳机场送机服务（关联具体航班）
# 验证用户能够完成汽车票预订+机场送机服务的组合下单，送机需关联具体航班

module V151V200
  class V151BookBusAndAirportDropoffValidator < BaseValidator
    self.validator_id = 'v151_book_bus_and_airport_dropoff_validator'
    self.task_id = 'f1a2b3c4-5d6e-7f8a-9b0c-1d2e3f4a5b6c'
    self.title = '给张三预订明天广州到深圳下午汽车票，并预订深圳机场送机（搭乘后天深圳飞杭州的航班）'
    self.description = '给张三订明天下午广州到深圳的汽车票，到达后订深圳机场送机服务（送张三去机场搭乘后天深圳飞杭州的航班）'
    self.timeout_seconds = 300

    def prepare
      @bus_travel_date = Date.tomorrow  # 明天坐汽车
      @flight_date = Date.current + 2.days  # 后天飞机
      @origin = '广州'
      @destination = '深圳'
      @flight_destination = '杭州'
      @dropoff_location = '深圳宝安国际机场'
      @airport_name = '宝安T3'
      @preferred_time = '14:00'  # 下午车次
      
      # 预查询乘客信息（避免 simulate 中查询 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_name = @passenger.name
      @expected_phone = @passenger.phone
      @expected_id_number = @passenger.id_number
      
      # 查找可用的汽车票（下午班次）
      @available_bus_tickets = BusTicket
        .where(origin: @origin, destination: @destination, data_version: 0)
        .where(departure_date: @bus_travel_date)
        .where("departure_time >= ?", '13:00')
        .where("departure_time <= ?", '17:00')
        .to_a
      
      expect(@available_bus_tickets).not_to be_empty, "数据包缺少广州到深圳的下午汽车票"
      
      # 查找可用的深圳飞杭州航班（后天）
      @available_flights = Flight
        .where(departure_city: @destination, destination_city: @flight_destination, data_version: 0)
        .where(flight_date: @flight_date)
        .where("departure_airport LIKE ?", "%宝安%")
        .to_a
      
      expect(@available_flights).not_to be_empty, "数据包缺少深圳飞杭州的航班"
      
      # 查找机场位置
      @airport_location = TransferLocation.find_by(
        city: @destination,
        location_type: 'airport',
        data_version: 0
      )
      
      expect(@airport_location).not_to be_nil, "未找到深圳机场位置"
      
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
      
      # 选择最接近偏好时间的班次
      bus_ticket = @available_bus_tickets.min_by { |t| (Time.parse(t.departure_time) - Time.parse(@preferred_time)).abs }
      
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
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number
      )
      
      # 选择后天的航班
      target_flight = @available_flights.min_by { |f| f.departure_time }
      raise "未找到可用航班" unless target_flight
      
      # 计算送机时间（航班起飞前2小时）
      pickup_datetime = target_flight.departure_time - 2.hours
      
      # 创建机场送机服务（关联航班号）
      Transfer.create!(
        user: user,
        transfer_package_id: @best_package.id,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: "#{@destination}市区",
        location_to: @airport_location.name,
        pickup_datetime: pickup_datetime,
        flight_number: target_flight.flight_number,  # 关键：关联航班号
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
        flight_date: @flight_date.to_s,
        origin: @origin,
        destination: @destination,
        flight_destination: @flight_destination,
        dropoff_location: @dropoff_location,
        airport_name: @airport_name,
        preferred_time: @preferred_time
      }
    end
    
    def restore_from_state(data)
      @data_version = data['data_version']
      @bus_travel_date = Date.parse(data['bus_travel_date']) if data['bus_travel_date']
      @flight_date = Date.parse(data['flight_date']) if data['flight_date']
      @origin = data['origin']
      @destination = data['destination']
      @flight_destination = data['flight_destination']
      @dropoff_location = data['dropoff_location']
      @airport_name = data['airport_name']
      @preferred_time = data['preferred_time']
      
      # 重新查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_name = @passenger.name
      @expected_phone = @passenger.phone
      @expected_id_number = @passenger.id_number
      
      # 重新查询可用汽车票
      @available_bus_tickets = BusTicket
        .where(origin: @origin, destination: @destination, data_version: 0)
        .where(departure_date: @bus_travel_date)
        .where("departure_time >= ?", '13:00')
        .where("departure_time <= ?", '17:00')
        .to_a
      
      # 重新查询可用航班
      @available_flights = Flight
        .where(departure_city: @destination, destination_city: @flight_destination, data_version: 0)
        .where(flight_date: @flight_date)
        .where("departure_airport LIKE ?", "%宝安%")
        .to_a
      
      # 重新查询机场位置
      @airport_location = TransferLocation.find_by(
        city: @destination,
        location_type: 'airport',
        data_version: 0
      )
      
      # 重新查询套餐
      @available_packages = TransferPackage.where(
        vehicle_category: 'economy_5',
        data_version: 0
      ).order(:price)
      
      @best_package = @available_packages.first if @available_packages.any?
    end

    def verify
      # 断言1: 创建了汽车票订单
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
      
      # 断言5: 选择了下午车次
      add_assertion "选择了下午车次（13:00-17:00）", weight: 5 do
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
      
      # 断言7: 送机目的地正确（机场）
      add_assertion "送机目的地正确（深圳机场）", weight: 5 do
        # 允许两种格式：“深圳宝安国际机场” 或 “宝安国际机场T3航站楼”
        location_matches = (@transfer.location_to.include?('深圳') && @transfer.location_to.include?('机场')) ||
                          (@transfer.location_to.include?('宝安') && @transfer.location_to.include?('机场'))
        expect(location_matches).to be(true),
          "送机目的地错误。期望: 深圳机场或宝安机场, 实际: #{@transfer.location_to}"
      end
      
      # 断言8: 送机服务关联了具体航班号
      add_assertion "送机服务关联了具体航班号（深圳→#{@flight_destination}）", weight: 15 do
        expect(@transfer.flight_number).not_to be_nil, "送机服务未关联航班号"
        
        # 验证航班号对应的航班确实是深圳飞杭州
        flight = Flight.find_by(
          flight_number: @transfer.flight_number,
          departure_city: @destination,
          destination_city: @flight_destination,
          data_version: 0
        )
        
        expect(flight).not_to be_nil,
          "航班号#{@transfer.flight_number}不是深圳飞#{@flight_destination}的航班"
      end
      
      # 断言9: 送机时间合理（航班起飞前1.5-2.5小时）
      add_assertion "送机时间合理（航班起飞前1.5-2.5小时）", weight: 10 do
        if @transfer.flight_number.present?
          flight = Flight.find_by(
            flight_number: @transfer.flight_number,
            flight_date: @flight_date,
            data_version: 0
          )
          
          if flight
            time_before_flight = ((flight.departure_time - @transfer.pickup_datetime) / 3600.0).round(1)
            is_reasonable = time_before_flight >= 1.5 && time_before_flight <= 2.5
            
            expect(is_reasonable).to be(true),
              "送机时间不合理。航班#{flight.departure_time.strftime('%H:%M')}起飞，" \
              "送机时间#{@transfer.pickup_datetime.strftime('%H:%M')}，" \
              "提前#{time_before_flight}小时（应为1.5-2.5小时）"
          end
        end
      end
      
      # 断言10: 乘客信息正确（张三）
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
