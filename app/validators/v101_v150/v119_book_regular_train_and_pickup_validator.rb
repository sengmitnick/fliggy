# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例119: 订购火车票后预订接站服务（普通列车）
#
# 任务描述:
#   用户订了武汉到西安的普通列车，到达西安站（早晨07:30到达），需要接站到钟楼商圈。
#   需要创建2个订单：
#   - 1个火车票订单（武汉→西安站，K字头普通列车）
#   - 1个接站订单（西安站 → 钟楼商圈）
#
# 复杂度分析:
#   1. 需要搜索并预订武汉到西安的普通列车（K字头）
#   2. 需要识别火车到达站（西安站）
#   3. 早晨接站服务
#   4. 接送时间需要自动计算（火车到达后15分钟）
#   5. 选择经济5座并选择最优价格
#
# 评分标准:
#   - 创建了火车订单和接站订单 (20分)
#   - 火车路线正确（武汉→西安）(10分)
#   - 接站起点正确（西安站）(20分)
#   - 接站终点正确（钟楼商圈）(15分)
#   - 接送时间正确（早晨，火车到达后15分钟）(15分)
#   - 价格选择合理（20分)
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
    self.title = '订购火车票后预订接站服务（普通列车）'
    self.description = '订购武汉到西安的普通列车，到达西安站后预订接站到钟楼商圈'
    self.timeout_seconds = 300
  
    def prepare
      @departure_city = '武汉'
      @arrival_city = '西安'
      @arrival_station = '西安站'
      @destination_location = '钟楼商圈'
      @travel_date = Date.current + 2.days
      @vehicle_category = 'economy_5'
      @transfer_type = 'train_pickup'
      @service_type = 'from_station'
    
      # 查找普通列车（K字头）或任何到达西安的火车
      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@travel_date)
    
      raise "未找到符合条件的火车" if @available_trains.empty?
    
      @station_location = TransferLocation.find_by(
        city: @arrival_city,
        name: @arrival_station,
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
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@arrival_city}的火车（到达#{@arrival_station}，早晨07:30左右到达），" \
              "并预订接站服务到#{@destination_location}（选择经济5座车型）",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          arrival_station: @arrival_station,
          travel_date: @travel_date.to_s,
          arrival_time: '早晨07:30左右',
          destination: @destination_location,
          train_type: '普通列车（K字头或其他）',
          vehicle_category: '经济5座',
          service_description: '早晨火车站接站服务'
        },
        hint: "先预订火车票，然后根据火车到达时间预订接站服务。接送时间应为火车到达后15分钟（约07:45）",
        statistics: {
          available_trains: @available_trains.count,
          available_packages: @available_packages.count
        }
      }
    end
  
    def verify
      add_assertion "创建了火车订单和接站订单", weight: 20 do
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
        expect(train.departure_city).to eq(@departure_city)
        expect(train.arrival_city).to eq(@arrival_city)
      end
    
      add_assertion "接站起点正确（#{@arrival_station}）", weight: 20 do
        expect(@transfer.location_from).to eq(@arrival_station),
          "接站起点错误。期望: #{@arrival_station}（火车到达站），实际: #{@transfer.location_from}"
      end
    
      add_assertion "接站终点正确（#{@destination_location}）", weight: 15 do
        expect(@transfer.location_to).to eq(@destination_location),
          "接站终点错误。期望: #{@destination_location}, 实际: #{@transfer.location_to}"
      end
    
      add_assertion "接送时间正确（早晨，火车到达后15分钟）", weight: 15 do
        train = @train_booking.train
        expected_pickup_time = train.arrival_time + 15.minutes
        time_diff = (@transfer.pickup_datetime - expected_pickup_time).abs
      
        expect(time_diff).to be <= 10.minutes,
          "接送时间错误。期望: #{expected_pickup_time.strftime('%H:%M')}（火车到达#{train.arrival_time.strftime('%H:%M')}后15分钟），" \
          "实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
      end
    
      add_assertion "价格选择合理", weight: 20 do
        cheapest_price = TransferPackage
          .where(vehicle_category: @vehicle_category, data_version: @data_version)
          .minimum(:price)
      
        if cheapest_price.present?
          expect(@transfer.total_price).to be <= (cheapest_price * 1.05),
            "未选择最优价格。最低价: ¥#{cheapest_price}, 实际: ¥#{@transfer.total_price}"
        end
      end
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      target_train = @available_trains.order(:departure_time).first
      raise "未找到可用火车" unless target_train
    
      train_booking = TrainBooking.create!(
        user_id: user.id,
        train_id: target_train.id,
        passenger_name: '周八',
        passenger_id_number: '610101199401011234',
        contact_phone: '13400134000',
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
        passenger_name: '周八',
        passenger_phone: '13400134000',
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
        service_type: @service_type
      }
    end
  
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @arrival_station = data['arrival_station']
      @destination_location = data['destination_location']
      @travel_date = Date.parse(data['travel_date'])
      @vehicle_category = data['vehicle_category']
      @transfer_type = data['transfer_type']
      @service_type = data['service_type']
    
      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@travel_date)
    
      @station_location = TransferLocation.find_by(
        city: @arrival_city,
        name: @arrival_station,
        data_version: 0
      )
    
      @destination = TransferLocation.find_by(
        city: @arrival_city,
        name: @destination_location,
        data_version: 0
      )
    
      @available_packages = TransferPackage.where(
        vehicle_category: @vehicle_category,
        data_version: 0
      ).order(:price)
    
      @best_package = @available_packages.first if @available_packages.any?
    end
  end
end
