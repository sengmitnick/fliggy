# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例119: 给李四预订上海到杭州火车票并预订接站服务（上海→杭州高铁，杭州东站→西湖，经济5座，后天下午）
#
# 任务描述:
#   用户订了上海到杭州的高铁，到达杭州东站（下午13:10到达），需要接站到西湖风景区。
#   Agent 需要搜索并预订火车票，然后根据火车到达时间预订接站服务，选择经济5座车型中价格最低的套餐
#
# 业务流程（8个关键步骤）：
#   1. 搜索上海到杭州的火车票（后天出发）
#   2. 筛选G字头高铁（高铁车次）
#   3. 筛选下午到达的班次（12:00-15:00之间到达）
#   4. 预订火车票（乘客李四，二等座）
#   5. 确认火车到达站（杭州东站）
#   6. 选择接站服务（from_station = 从车站接到目的地）
#   7. 接送时间自动计算（火车到达后15分钟）
#   8. 选择经济5座车型中价格最低的套餐
#
# 复杂度分析（8个关键点）：
#   1. 需要理解"接站"含义：from_station = 从火车站出发，送到目的地
#   2. 需要搜索并预订火车票（上海→杭州，G字头高铁）
#   3. 需要识别火车到达站（杭州东站）作为接站起点
#   4. 需要选择目的地（西湖风景区）作为接站终点
#   5. 需要自动计算接送时间（火车到达后15分钟）
#   6. 需要筛选经济5座车型（单人出行）
#   7. 需要对比同类车型不同供应商的价格
#   8. 需要选择最低价格的套餐
#   ❌ 不能一次性提供：需要先预订火车票→确认到达站→选接站服务→设置时间→筛选车型→对比价格→预订
#
# 评分标准（8项，总计100分）：
#   - 创建了火车订单和接站订单（15分）
#   - 火车路线正确（上海→杭州）（10分）
#   - 火车乘客信息正确（李四）（10分）
#   - 接站起点正确（杭州东站）（20分）
#   - 接站终点正确（西湖风景区）（10分）
#   - 接送时间正确（下午，火车到达后15分钟）（15分）
#   - 选择了该车型中价格最低的套餐（15分）
#   - 接站联系人信息正确（李四）（5分）
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v119_book_regular_train_and_pickup_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V101V150
  class V119BookRegularTrainAndPickupValidator < BaseValidator
    self.validator_id = 'v119_book_regular_train_and_pickup_validator'
    self.task_id = '39a9127b-f7bc-49ff-9e39-a91cd0d9a2e0'
    self.title = '给李四预订上海到杭州火车票并预订接站服务（上海→杭州高铁，杭州东站→西湖，经济5座，后天下午）'
    self.description = '预订上海到杭州高铁票（后天下午13:10到达杭州东站），预订接站服务（杭州东站→西湖风景区，经济5座，13:25）'
    self.timeout_seconds = 300
  
    def prepare
      @departure_city = '上海'
      @arrival_city = '杭州'
      @arrival_station = '杭州东站'
      @destination_location = '西湖风景区'
      @travel_date = Date.today + 2.days
      @vehicle_category = 'economy_5'
      @transfer_type = 'train_pickup'
      @service_type = 'from_station'
    
      # 预查询李四的乘客信息（避免 simulate 中查询 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_passenger_name = @lisi.name
      @expected_passenger_id_number = @lisi.id_number
      @expected_passenger_phone = @lisi.phone

      # 查找下午到达的高铁（G7308: 12:00出发 -> 13:10到达）
      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@travel_date)
       .where("train_number LIKE 'G%'")
       .where("EXTRACT(HOUR FROM arrival_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') >= 12")
       .where("EXTRACT(HOUR FROM arrival_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') < 15")
    
      raise "未找到符合条件的火车" if @available_trains.empty?
    
      @station_location = TransferLocation.find_by(
        city: @arrival_city,
        location_type: 'train_station',
        data_version: 0
      )
    
      raise "未找到车站位置: #{@arrival_station}" unless @station_location
    
      @destination = TransferLocation.find_by(
        city: @arrival_city,
        name: @destination_location,
        location_type: 'other',
        data_version: 0
      )
    
      raise "未找到目的地: #{@destination_location}" unless @destination
    
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        data_version: 0
      ).order(:price)
    
      raise "未找到经济5座套餐" if @available_packages.empty?
    
      @best_package = @available_packages.first
    
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@arrival_city}的火车（到达#{@arrival_station}，下午13:10左右到达），" \
              "并预订接站服务到#{@destination_location}（选择经济5座车型），乘客是李四",
        scenario: "后天需要从上海去杭州，需要预订高铁票，到达杭州东站后需要接站送到西湖风景区",
        train_info: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          arrival_station: @arrival_station,
          travel_date: @travel_date.to_s,
          arrival_time: '下午13:10左右',
          train_type: '高铁（G字头）',
          passenger: '李四'
        },
        service_type: "火车站接站（from_station）",
        pickup_location: "#{@arrival_station}（上车点，通过火车票确定）",
        dropoff_location: "#{@destination_location}（下车点，目的地）",
        pickup_datetime: "火车到达后15分钟（约13:25）",
        vehicle_category: '经济5座（economy_5）',
        flow_hint: "1. 搜索#{@departure_city}→#{@arrival_city}火车（G7308，后天下午13:10到达#{@arrival_station}） → 2. 预订火车票（乘客李四） → 3. 确认到达站（#{@arrival_station}） → 4. 选择接站服务 → 5. 上车点自动=#{@arrival_station} → 6. 下车点输入#{@destination_location} → 7. 接送时间=火车到达后15分钟 → 8. 筛选经济5座车型 → 9. 对比同类车型不同供应商价格 → 10. 选择该车型中价格最低的套餐",
        hint: "单人出行选择经济5座车型即可，接送时间应为火车到达后15分钟（约13:25），选择economy_5车型中价格最低的套餐",
        statistics: {
          available_trains: @available_trains.count,
          available_packages: @available_packages.count,
          price_range: {
            min: @available_packages.minimum(:price),
            max: @available_packages.maximum(:price)
          }
        }
      }
    end
  
    def verify
      add_assertion "创建了火车订单和接站订单", weight: 15 do
        @train_bookings = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(@train_bookings).not_to be_empty, "未找到#{@departure_city}到#{@arrival_city}的火车订单"
        @train_booking = @train_bookings.first
      
        @transfers = Transfer
          .where(transfer_type: @transfer_type, service_type: @service_type)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(@transfers).not_to be_empty, "未找到接站订单"
        @transfer = @transfers.first
      end
    
      return if @train_booking.nil? || @transfer.nil?
    
      add_assertion "火车路线正确（#{@departure_city}→#{@arrival_city}）", weight: 10 do
        train = @train_booking.train
        expect(train.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{train.departure_city}"
        expect(train.arrival_city).to eq(@arrival_city),
          "到达城市错误。期望: #{@arrival_city}, 实际: #{train.arrival_city}"
      end
      
      add_assertion "火车乘客信息正确（李四）", weight: 10 do
        expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
          "火车票乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
        expect(@train_booking.passenger_id_number).to eq(@expected_passenger_id_number),
          "火车票乘客身份证号错误。期望: #{@expected_passenger_id_number}, 实际: #{@train_booking.passenger_id_number}"
      end
    
      add_assertion "接站起点正确（#{@arrival_station}）", weight: 20 do
        expect(@transfer.location_from).to include("杭州东站"),
          "接站起点错误。期望: 包含'杭州东站'（火车到达站），实际: #{@transfer.location_from}"
      end
    
      add_assertion "接站终点正确（#{@destination_location}）", weight: 10 do
        expect(@transfer.location_to).to eq(@destination_location),
          "接站终点错误。期望: #{@destination_location}, 实际: #{@transfer.location_to}"
      end
    
      add_assertion "接送时间正确（下午，火车到达后15分钟）", weight: 15 do
        train = @train_booking.train
        expected_pickup_time = train.arrival_time + 15.minutes
        time_diff = (@transfer.pickup_datetime - expected_pickup_time).abs
      
        expect(time_diff).to be <= 10.minutes,
          "接送时间错误。期望: #{expected_pickup_time.strftime('%H:%M')}（火车到达#{train.arrival_time.strftime('%H:%M')}后15分钟），" \
          "实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
      end
    
      add_assertion "选择了该车型中价格最低的套餐", weight: 15 do
        packages = TransferPackage.where(vehicle_category: @vehicle_category, data_version: 0)
        cheapest = packages.min_by(&:price)
        actual_price = @transfer.transfer_package.price
        cheapest_price = cheapest.price
      
        expect(@transfer.transfer_package_id).to eq(cheapest.id),
          "未选择该车型最便宜套餐。" \
          "应选: #{cheapest.name} #{cheapest.category_name}（#{cheapest_price}元），" \
          "实际: #{@transfer.transfer_package.name} #{@transfer.transfer_package.category_name}（#{actual_price}元）"
      end
      
      add_assertion "接站联系人信息正确（李四）", weight: 5 do
        expect(@transfer.passenger_name).to eq(@expected_passenger_name),
          "接站乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@transfer.passenger_name}"
        expect(@transfer.passenger_phone).to eq(@expected_passenger_phone),
          "接站联系电话错误。期望: #{@expected_passenger_phone}, 实际: #{@transfer.passenger_phone}"
      end
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 选择下午到达的高铁（G7308: 12:00 -> 13:10）
      target_train = @available_trains.order(:arrival_time).first
      raise "未找到可用火车" unless target_train
    
      train_booking = TrainBooking.create!(
        user_id: user.id,
        train_id: target_train.id,
        passenger_name: @lisi.name,
        passenger_id_number: @lisi.id_number,
        contact_phone: @lisi.phone,
        seat_type: 'second_class',
        total_price: target_train.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
    
      pickup_datetime = target_train.arrival_time + 15.minutes
    
      transfer = Transfer.create!(
        user_id: user.id,
        transfer_package_id: @best_package.id,
        transfer_type: @transfer_type,
        service_type: @service_type,
        location_from: @station_location.name,
        location_to: @destination.name,
        pickup_datetime: pickup_datetime,
        passenger_name: @lisi.name,
        passenger_phone: @lisi.phone,
        passenger_count: 1,
        luggage_count: 1,
        total_price: @best_package.price,
        discount_amount: 0,
        status: 'paid',
        driver_status: 'pending',
        data_version: @data_version
      )
    
      { train_booking: train_booking, transfer: transfer }
    end
  
    private
  
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        arrival_station: @arrival_station,
        destination_location: @destination_location,
        travel_date: @travel_date.to_s,
        vehicle_category: @vehicle_category,
        transfer_type: @transfer_type,
        service_type: @service_type,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id_number: @expected_passenger_id_number,
        expected_passenger_phone: @expected_passenger_phone
      }
    end
  
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @arrival_station = data['arrival_station']
      @destination_location = data['destination_location']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @vehicle_category = data['vehicle_category']
      @transfer_type = data['transfer_type']
      @service_type = data['service_type']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id_number = data['expected_passenger_id_number']
      @expected_passenger_phone = data['expected_passenger_phone']
      
      # 重新查询 @lisi 对象（用于 simulate）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @lisi = user.passengers.find_by!(name: @expected_passenger_name, data_version: 0)
      
      # 重新查询 available_trains, station_location, destination, available_packages
      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@travel_date)
       .where("train_number LIKE 'G%'")
       .where("EXTRACT(HOUR FROM arrival_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') >= 12")
       .where("EXTRACT(HOUR FROM arrival_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') < 15")
      
      @station_location = TransferLocation.find_by(
        city: @arrival_city,
        location_type: 'train_station',
        data_version: 0
      )
      
      @destination = TransferLocation.find_by(
        city: @arrival_city,
        name: @destination_location,
        location_type: 'other',
        data_version: 0
      )
      
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        data_version: 0
      ).order(:price)
      
      @best_package = @available_packages.first
    end
    end
end
