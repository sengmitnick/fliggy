# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例175: 给陈静预订后天北京到南京的高铁票，并预订南京南站接站到新街口商圈（高铁10:30到达南京南站，经济5座最便宜套餐）
#
# 任务描述:
#   陈静预订后天从北京到南京的高铁（上午10:30到达南京南站），到达后需要接站到新街口商圈。
#   需要创建2个订单：
#   1. 火车票订单（北京→南京南站，10:30到达）
#   2. 接站订单（南京南站 → 新街口商圈，经济5座，接站时间10:45）
#
# 业务流程:
#   1. 搜索并预订后天北京到南京的高铁（10:30到达南京南站）
#   2. 记录高铁到达时间和到达车站位置（南京南站）
#   3. 选择"接站"服务（from_station = 从车站接到目的地）
#   4. 上车点：南京南站（通过高铁信息自动确定）
#   5. 下车点：新街口商圈
#   6. 用车时间：高铁到达后15分钟（10:45接站）
#   7. 车型选择：经济5座（economy_5）
#   8. 选择该车型中价格最低的套餐
#
# 复杂度分析:
#   1. 需要搜索并预订后天北京到南京的高铁（10:30到达）
#   2. 需要识别高铁到达站（南京南站）
#   3. 接站服务，起点必须匹配高铁到达站
#   4. 接送时间需要自动计算（高铁到达后15分钟）
#   5. 需要根据要求选择经济5座车型
#   6. 从多个经济5座套餐中选择最便宜的
#
# 验证分数: 100分
#   - 创建了火车订单（后天北京→南京南站，10:30到达）: 15分
#   - 创建了接站订单: 15分
#   - 接站起点正确（南京南站）: 15分
#   - 接站终点正确（新街口商圈）: 10分
#   - 接送时间正确（高铁到达后15分钟，10:45接站）: 15分
#   - 车型正确（经济5座）: 10分
#   - 选择了该车型中价格最低的套餐: 10分
#   - 火车乘客和接站联系人信息正确（陈静）: 10分
#
# 相关文件:
#   - app/models/train_booking.rb
#   - app/models/transfer.rb
#   - app/models/train.rb
#   - app/models/transfer_package.rb
#   - app/models/transfer_location.rb

module V151V200
  class V175BookTrainAndStationPickupValidator < BaseValidator
    self.validator_id = 'v175_book_train_and_station_pickup_validator'
    self.task_id = '77ad42cd-6c18-4752-b8e4-f7ec1532fee0'
    self.title = '给陈静预订后天北京到南京的高铁票，并预订南京南站接站到新街口商圈（高铁10:30到达南京南站，经济5座最便宜套餐）'
    self.description = '帮陈静订后天从北京到南京的高铁（上午10:30到达南京南站），然后接站到新街口商圈'
    self.timeout_seconds = 300
  
    def prepare
      @departure_city = '北京'
      @arrival_city = '南京'
      @arrival_station = '南京南站'
      @destination_location = '新街口商圈'
      @travel_date = Date.current + 2.days  # 后天
      @arrival_hour = 10  # 上午10:30到达
      @arrival_minute = 30
      @vehicle_category = 'economy_5'
      @transfer_type = 'train_pickup'
      @service_type = 'from_station'
    
      # 预查询乘客信息（陈静）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '陈静', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
    
      # 查找可用高铁（北京→南京，10:30到达）
      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@travel_date)
       .where("train_number LIKE 'G%'")  # 高铁（G字头）
       .select { |t| t.arrival_time.hour == @arrival_hour && t.arrival_time.min == @arrival_minute }
    
      expect(@available_trains).not_to be_empty, "数据包缺少后天从#{@departure_city}到#{@arrival_city}的高铁（10:30到达）"
      return if @available_trains.empty?  # Guard clause
    
      # 查找车站位置
      @station_location = TransferLocation.find_by(
        city: @arrival_city,
        name: @arrival_station,
        location_type: 'train_station',
        data_version: 0
      )
    
      expect(@station_location).not_to be_nil, "数据包缺少车站位置: #{@arrival_station}"
      return if @station_location.nil?  # Guard clause
    
      # 查找目的地位置
      @destination = TransferLocation.find_by(
        city: @arrival_city,
        name: @destination_location,
        location_type: 'other',
        data_version: 0
      )
    
      expect(@destination).not_to be_nil, "数据包缺少目的地: #{@destination_location}"
      return if @destination.nil?  # Guard clause
    
      # 查找经济5座套餐
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        data_version: 0
      ).order(:price)
    
      expect(@available_packages).not_to be_empty, "数据包缺少经济5座套餐"
      return if @available_packages.empty?  # Guard clause
    
      @best_package = @available_packages.first
    
      # 获取示例高铁的时间信息
      @example_train = @available_trains.first
    
      {
        task: "请为陈静预订#{@travel_date.strftime('%Y年%m月%d日')}（后天）从#{@departure_city}到#{@arrival_city}的高铁（上午10:30到达#{@arrival_station}），" \
              "并预订接站服务到#{@destination_location}（经济5座）",
        scenario: "后天从#{@departure_city}坐高铁到#{@arrival_city}（上午10:30到达#{@arrival_station}），陈静需要接站送到#{@destination_location}",
        passenger: @expected_passenger_name,
        train_info: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          arrival_station: @arrival_station,
          travel_date: @travel_date.to_s,
          train_type: '高铁（G字头）',
          example_arrival_time: @example_train.arrival_time.strftime('%H:%M'),
          example_pickup_time: (@example_train.arrival_time + 15.minutes).strftime('%H:%M')
        },
        service_type: "火车站接站（from_station）",
        pickup_location: "#{@arrival_station}（上车点，通过高铁到达信息自动确定）",
        dropoff_location: "#{@destination_location}（下车点，目的地）",
        pickup_time_rule: "高铁到达时间后15分钟",
        vehicle_category: '经济5座（economy_5）',
        flow_hint: "1. 搜索并预订从#{@departure_city}到#{@arrival_city}的高铁（后天，10:30到达#{@arrival_station}） → 2. 记录高铁到达时间 → 3. 选择接站服务 → 4. 上车点自动=#{@arrival_station} → 5. 下车点输入#{@destination_location} → 6. 用车时间=高铁到达后15分钟（#{(@example_train.arrival_time + 15.minutes).strftime('%H:%M')}接站） → 7. 筛选经济5座车型 → 8. 选择该车型价格最低的套餐",
        hint: "先预订高铁票（10:30到达#{@arrival_station}），然后预订接站服务（接站时间=高铁到达时间+15分钟=#{(@example_train.arrival_time + 15.minutes).strftime('%H:%M')}），起点为#{@arrival_station}，终点为#{@destination_location}，必须选择经济5座中价格最低的套餐",
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
      # 断言1: 创建了火车订单（后天北京→南京南站，10:30到达）(15%)
      add_assertion "创建了火车订单（后天#{@departure_city}→#{@arrival_city}#{@arrival_station}，10:30到达）", weight: 15 do
        @train_bookings = TrainBooking
          .joins(:train)
          .where(trains: { 
            departure_city: @departure_city, 
            arrival_city: @arrival_city 
          })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(@train_bookings).not_to be_empty, "未找到从#{@departure_city}到#{@arrival_city}的火车订单"
        @train_booking = @train_bookings.first
        
        # 验证到达时间是10:30
        train = @train_booking.train
        arrival_time = train.arrival_time
        expect(arrival_time.hour).to eq(10), 
          "高铁到达时间错误。期望10:30到达，实际#{arrival_time.strftime('%H:%M')}到达"
        expect(arrival_time.min).to eq(30),
          "高铁到达时间错误。期望10:30到达，实际#{arrival_time.strftime('%H:%M')}到达"
      end
    
      return if @train_booking.nil?  # Guard clause after assertion 1
    
      # 断言2: 创建了接站订单 (15%)
      add_assertion "创建了接站订单", weight: 15 do
        @transfers = Transfer
          .where(transfer_type: @transfer_type, service_type: @service_type)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(@transfers).not_to be_empty, "未找到接站订单"
        @transfer = @transfers.first
      end
    
      return if @transfer.nil?  # Guard clause after assertion 2
    
      # 断言3: 接站起点正确（南京南站）(15%)
      add_assertion "接站起点正确（#{@arrival_station}）", weight: 15 do
        expect(@transfer.location_from).to eq(@arrival_station),
          "接站起点错误。期望: #{@arrival_station}（高铁到达站），实际: #{@transfer.location_from}"
      end
    
      # 断言4: 接站终点正确（新街口商圈）(10%)
      add_assertion "接站终点正确（#{@destination_location}）", weight: 10 do
        expect(@transfer.location_to).to eq(@destination_location),
          "接站终点错误。期望: #{@destination_location}, 实际: #{@transfer.location_to}"
      end
    
      # 断言5: 接送时间正确（高铁到达后15分钟，10:45接站）(15%)
      add_assertion "接送时间正确（高铁到达后15分钟，10:45接站）", weight: 15 do
        train = @train_booking.train
        expected_pickup_time = train.arrival_time + 15.minutes
      
        # 允许±10分钟误差
        time_diff = (@transfer.pickup_datetime - expected_pickup_time).abs
      
        expect(time_diff).to be <= 10.minutes,
          "接送时间错误。期望: #{expected_pickup_time.strftime('%H:%M')}（高铁到达#{train.arrival_time.strftime('%H:%M')}后15分钟），" \
          "实际: #{@transfer.pickup_datetime.strftime('%H:%M')}（相差#{(time_diff / 60).to_i}分钟）"
      end
    
      # 断言6: 车型正确（经济5座）(10%)
      add_assertion "车型正确（经济5座）", weight: 10 do
        expect(@transfer.transfer_package).not_to be_nil, "未选择车辆套餐"
        expect(@transfer.transfer_package.vehicle_category).to eq(@vehicle_category),
          "车型选择错误。期望: #{@vehicle_category}（经济5座），实际: #{@transfer.transfer_package.vehicle_category}"
      end
    
      # 断言7: 选择了该车型中价格最低的套餐 (10%)
      add_assertion "选择了该车型中价格最低的套餐", weight: 10 do
        packages = TransferPackage.where(vehicle_category: @vehicle_category, is_active: true, data_version: 0)
        cheapest = packages.min_by(&:price)
        actual_price = @transfer.transfer_package.price
        cheapest_price = cheapest.price
      
        expect(@transfer.transfer_package_id).to eq(cheapest.id),
          "未选择该车型最便宜套餐。" \
          "应选: #{cheapest.name} #{cheapest.category_name}（#{cheapest_price}元），" \
          "实际: #{@transfer.transfer_package.name} #{@transfer.transfer_package.category_name}（#{actual_price}元）"
      end
    
      # 断言8: 火车乘客和接站联系人信息正确（陈静）(10%)
      add_assertion "火车乘客和接站联系人信息正确（#{@expected_passenger_name}）", weight: 10 do
        # 验证火车订单乘客信息
        expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
          "火车乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
        expect(@train_booking.contact_phone).to eq(@expected_phone),
          "火车联系电话错误。期望: #{@expected_phone}, 实际: #{@train_booking.contact_phone}"
        
        # 验证接站订单联系人信息
        expect(@transfer.passenger_name).to eq(@expected_passenger_name),
          "接站联系人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@transfer.passenger_name}"
        expect(@transfer.passenger_phone).to eq(@expected_phone),
          "接站联系电话错误。期望: #{@expected_phone}, 实际: #{@transfer.passenger_phone}"
      end
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '陈静', data_version: 0)
    
      # 步骤1: 预订高铁（后天北京→南京南站，上午10:30到达）
      target_train = @available_trains.find { |t| t.arrival_time.hour == 10 && t.arrival_time.min == 30 } || @available_trains.first
      raise "未找到可用高铁" unless target_train
    
      train_booking = TrainBooking.create!(
        user_id: user.id,
        train_id: target_train.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        seat_type: 'second_class',
        total_price: target_train.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
    
      # 步骤2: 预订接站服务（南京南站 → 新街口商圈，经济5座，接站时间=高铁到达后15分钟）
      pickup_datetime = target_train.arrival_time + 15.minutes
    
      transfer = Transfer.create!(
        user_id: user.id,
        transfer_package_id: @best_package.id,
        transfer_type: @transfer_type,
        service_type: @service_type,
        location_from: @station_location.name,
        location_to: @destination.name,
        pickup_datetime: pickup_datetime,
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
        arrival_hour: @arrival_hour,
        arrival_minute: @arrival_minute,
        vehicle_category: @vehicle_category,
        transfer_type: @transfer_type,
        service_type: @service_type,
        expected_passenger_name: @expected_passenger_name,
        expected_phone: @expected_phone
      }
    end
  
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @arrival_station = data['arrival_station']
      @destination_location = data['destination_location']
      @travel_date = Date.parse(data['travel_date'])
      @arrival_hour = data['arrival_hour']
      @arrival_minute = data['arrival_minute']
      @vehicle_category = data['vehicle_category']
      @transfer_type = data['transfer_type']
      @service_type = data['service_type']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_phone = data['expected_phone']
    
      # 重新查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '陈静', data_version: 0)
    
      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@travel_date)
       .where("train_number LIKE 'G%'")
       .select { |t| t.arrival_time.hour == @arrival_hour && t.arrival_time.min == @arrival_minute }
    
      @station_location = TransferLocation.find_by(
        city: @arrival_city,
        name: @arrival_station,
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
