# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例120: 订购火车票后预订接站服务（经济7座，多人出行）
#
# 任务描述:
#   家庭5人出游，订了重庆到成都东站的火车，需要接站到春熙路商圈。
#   需要创建2个订单：
#   - 1个火车票订单（重庆→成都东站）
#   - 1个接站订单（成都东站 → 春熙路商圈，经济7座）
#
# 复杂度分析:
#   1. 需要搜索并预订重庆到成都的火车
#   2. 需要识别火车到达站（成都东站）
#   3. 需要根据人数选择经济7座车型（5人+行李需要7座车）
#   4. 接送时间需要自动计算（火车到达后15分钟）
#   5. 选择最优价格
#
# 评分标准:
#   - 创建了火车订单和接站订单 (20分)
#   - 火车路线正确（重庆→成都）(10分)
#   - 接站起点正确（成都东站）(20分)
#   - 接站终点正确（春熙路商圈）(15分)
#   - 接送时间正确（火车到达后15分钟）(10分)
#   - 车型选择正确（经济7座，适合5人出行）(25分)
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v120_book_train_and_pickup_economy7_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V101V150
  class V120BookTrainAndPickupEconomy7Validator < BaseValidator
    self.validator_id = 'v120_book_train_and_pickup_economy7_validator'
    self.task_id = '97534ade-23a0-4a65-aeeb-023d90721c96'
    self.title = '订购火车票后预订接站服务（经济7座，多人出行）'
    self.description = '家庭5人出游，订购重庆到成都东站的火车，到达后预订接站到春熙路，选择经济7座'
    self.timeout_seconds = 300
  
    def prepare
      @departure_city = '重庆'
      @arrival_city = '成都'
      @arrival_station = '成都东站'
      @destination_location = '春熙路商圈'
      @travel_date = Date.current + 3.days
      @passenger_count = 5  # 5人出行
      @vehicle_category = 'economy_7'  # 经济7座
      @transfer_type = 'train_pickup'
      @service_type = 'from_station'
    
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
    
      raise "未找到经济7座套餐" if @available_packages.empty?
    
      @best_package = @available_packages.first
    
      {
        task: "请为家庭5人预订#{@travel_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@arrival_city}的火车（到达#{@arrival_station}），" \
              "并预订接站服务到#{@destination_location}（注意：5人出行需要选择7座车）",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          arrival_station: @arrival_station,
          travel_date: @travel_date.to_s,
          destination: @destination_location,
          passenger_count: @passenger_count,
          vehicle_category: '经济7座（5座车无法容纳5人+行李）',
          service_description: '接站服务（多人出行，需要7座车）'
        },
        hint: "5人出行加上行李，需要选择7座车（经济7座可载6人）。接送时间应为火车到达后15分钟",
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
    
      add_assertion "接送时间正确（火车到达后15分钟）", weight: 10 do
        train = @train_booking.train
        expected_pickup_time = train.arrival_time + 15.minutes
        time_diff = (@transfer.pickup_datetime - expected_pickup_time).abs
      
        expect(time_diff).to be <= 10.minutes,
          "接送时间错误。期望: #{expected_pickup_time.strftime('%H:%M')}（火车到达#{train.arrival_time.strftime('%H:%M')}后15分钟），" \
          "实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
      end
    
      add_assertion "车型选择正确（经济7座，适合5人出行）", weight: 25 do
        if @transfer.transfer_package.present?
          expect(@transfer.transfer_package.vehicle_category).to eq(@vehicle_category),
            "车型选择错误。期望: #{@vehicle_category}（经济7座，5人出行需要7座车），实际: #{@transfer.transfer_package.vehicle_category}"
        end
      
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
        passenger_name: '吴九',
        passenger_id_number: '500101199501011234',
        contact_phone: '13300133000',
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
        passenger_name: '吴九',
        passenger_phone: '13300133000',
        passenger_count: @passenger_count,
        luggage_count: 3,
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
        passenger_count: @passenger_count,
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
      @passenger_count = data['passenger_count']
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
