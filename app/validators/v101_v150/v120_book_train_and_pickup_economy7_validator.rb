# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例120: 给小红家庭预订重庆到成都火车票并预订接站服务（张建国、刘强、王芳、小明、小红，重庆→成都高铁，成都东站→春熙路，经济7座，3天后）
#
# 任务描述:
#   小红家庭5人出游（张建国爷爷、刘强爸爸、王芳妈妈、小明哥哥、小红妹妹），
#   订购重庆到成都东站的火车（3天后），到达后预订接站到春熙路。
#   Agent 需要为5人分别预订火车票，然后根据人数选择经济7座车型中价格最低的套餐
#
# 业务流程（8个关键步骤）：
#   1. 搜索重庆到成都的火车票（3天后出发）
#   2. 为5位家庭成员分别预订火车票（张建国、刘强、王芳、小明、小红各1张）
#   3. 确认火车到达站（成都东站）
#   4. 选择接站服务（from_station = 从车站接到目的地）
#   5. 接送时间自动计算（火车到达后15分钟）
#   6. 根据5人家庭需求，筛选经济7座车型
#   7. 浏览经济7座车型套餐，对比不同供应商的价格
#   8. 选择价格最低的套餐
#
# 复杂度分析（8个关键点）：
#   1. 需要理解"接站"含义：from_station = 从火车站出发，送到目的地
#   2. 需要为5位家庭成员分别预订火车票（5个订单）
#   3. 需要识别火车到达站（成都东站）作为接站起点
#   4. 需要选择目的地（春熙路商圈）作为接站终点
#   5. 需要自动计算接送时间（火车到达后15分钟）
#   6. 需要理解5人家庭需要7座车（座位需求匹配）
#   7. 需要对比同类车型不同供应商的价格
#   8. 需要选择最低价格的套餐
#   ❌ 不能一次性提供：需要先预订5张火车票→确认到达站→选接站服务→设置时间→筛选7座车型→对比价格→预订
#
# 评分标准（8项，总计100分）：
#   - 创建了5个火车订单和1个接站订单（25分）
#   - 火车路线正确（重庆→成都）（10分）
#   - 火车乘客信息正确（5人：张建国、刘强、王芳、小明、小红）（15分）
#   - 接站起点正确（成都东站）（10分）
#   - 接站终点正确（春熙路商圈）（10分）
#   - 接送时间正确（火车到达后15分钟）（10分）
#   - 选择了该车型中价格最低的套餐（15分）
#   - 接站联系人信息正确（5人中任意1人）（5分）
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
    self.title = '给小红家庭预订重庆到成都火车票并预订接站服务（张建国、刘强、王芳、小明、小红，重庆→成都高铁，成都东站→春熙路，经济7座，3天后）'
    self.description = '预订重庆到成都火车票（5人：张建国、刘强、王芳、小明、小红，3天后到达成都东站），预订接站服务（成都东站→春熙路商圈，经济7座）'
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
    
      # 预查询小红家庭5位成员的乘客信息（避免 simulate 中查询 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangjianguo = user.passengers.find_by!(name: '张建国', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      @xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)
      @xiaohong = user.passengers.find_by!(name: '小红', data_version: 0)
      
      @expected_passenger_names = [@zhangjianguo.name, @liuqiang.name, @wangfang.name, @xiaoming.name, @xiaohong.name].sort
      @all_passengers = {
        @zhangjianguo.name => @zhangjianguo,
        @liuqiang.name => @liuqiang,
        @wangfang.name => @wangfang,
        @xiaoming.name => @xiaoming,
        @xiaohong.name => @xiaohong
      }

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
        task: "请为小红家庭5人（张建国爷爷、刘强爸爸、王芳妈妈、小明哥哥、小红妹妹）预订#{@travel_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@arrival_city}的火车（到达#{@arrival_station}），" \
              "并预订接站服务到#{@destination_location}（注意：5人出行需要选择7座车，选择经济7座车型）",
        scenario: "3天后需要从重庆去成都，家庭5人出游，需要预订火车票，到达成都东站后需要接站送到春熙路商圈",
        train_info: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          arrival_station: @arrival_station,
          travel_date: @travel_date.to_s,
          passengers: '张建国（爷爷）、刘强（爸爸）、王芳（妈妈）、小明（哥哥）、小红（妹妹）',
          passenger_count: @passenger_count
        },
        service_type: "火车站接站（from_station）",
        pickup_location: "#{@arrival_station}（上车点，通过火车票确定）",
        dropoff_location: "#{@destination_location}（下车点，目的地）",
        pickup_datetime: "火车到达后15分钟",
        vehicle_category: '经济7座（economy_7）',
        flow_hint: "1. 搜索#{@departure_city}→#{@arrival_city}火车（3天后到达#{@arrival_station}） → 2. 为5位家庭成员分别预订火车票（张建国、刘强、王芳、小明、小红各1张） → 3. 确认到达站（#{@arrival_station}） → 4. 选择接站服务 → 5. 上车点自动=#{@arrival_station} → 6. 下车点输入#{@destination_location} → 7. 接送时间=火车到达后15分钟 → 8. 筛选经济7座车型 → 9. 对比同类车型不同供应商价格 → 10. 选择该车型中价格最低的套餐",
        hint: "家庭5人出行需要7座车（经济7座可容纳6人），接送时间应为火车到达后15分钟，选择economy_7车型中价格最低的套餐",
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
      add_assertion "创建了5个火车订单和1个接站订单", weight: 25 do
        @train_bookings = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(@train_bookings.size).to eq(5),
          "火车订单数量错误。期望: 5个订单（5位家庭成员各1张票），实际: #{@train_bookings.size}个订单"
        
        @train_booking = @train_bookings.first  # 用于后续验证火车信息
      
        @transfers = Transfer
          .where(transfer_type: @transfer_type, service_type: @service_type)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(@transfers).not_to be_empty, "未找到接站订单"
        expect(@transfers.size).to eq(1), "接站订单数量错误。期望: 1个接站订单，实际: #{@transfers.size}个"
        @transfer = @transfers.first
      end
    
      return if @train_bookings.nil? || @train_bookings.empty? || @transfer.nil?
    
      add_assertion "火车路线正确（#{@departure_city}→#{@arrival_city}）", weight: 10 do
        @train_bookings.each do |booking|
          train = booking.train
          expect(train.departure_city).to eq(@departure_city),
            "出发城市错误。期望: #{@departure_city}, 实际: #{train.departure_city}"
          expect(train.arrival_city).to eq(@arrival_city),
            "到达城市错误。期望: #{@arrival_city}, 实际: #{train.arrival_city}"
        end
      end
      
      add_assertion "火车乘客信息正确（5人：张建国、刘强、王芳、小明、小红）", weight: 15 do
        passenger_names = @train_bookings.map(&:passenger_name).sort
        
        expect(passenger_names).to eq(@expected_passenger_names),
          "火车票乘客名单不正确。期望: #{@expected_passenger_names.join('、')}, 实际: #{passenger_names.join('、')}"
        
        # 验证每位乘客的身份证号
        zhangjianguo_booking = @train_bookings.find { |b| b.passenger_name == '张建国' }
        expect(zhangjianguo_booking).not_to be_nil, "未找到张建国的火车票"
        expect(zhangjianguo_booking.passenger_id_number).to eq(@zhangjianguo.id_number),
          "张建国身份证号错误。期望: #{@zhangjianguo.id_number}, 实际: #{zhangjianguo_booking.passenger_id_number}"
        
        liuqiang_booking = @train_bookings.find { |b| b.passenger_name == '刘强' }
        expect(liuqiang_booking).not_to be_nil, "未找到刘强的火车票"
        expect(liuqiang_booking.passenger_id_number).to eq(@liuqiang.id_number),
          "刘强身份证号错误。期望: #{@liuqiang.id_number}, 实际: #{liuqiang_booking.passenger_id_number}"
        
        wangfang_booking = @train_bookings.find { |b| b.passenger_name == '王芳' }
        expect(wangfang_booking).not_to be_nil, "未找到王芳的火车票"
        expect(wangfang_booking.passenger_id_number).to eq(@wangfang.id_number),
          "王芳身份证号错误。期望: #{@wangfang.id_number}, 实际: #{wangfang_booking.passenger_id_number}"
        
        xiaoming_booking = @train_bookings.find { |b| b.passenger_name == '小明' }
        expect(xiaoming_booking).not_to be_nil, "未找到小明的火车票"
        expect(xiaoming_booking.passenger_id_number).to eq(@xiaoming.id_number),
          "小明身份证号错误。期望: #{@xiaoming.id_number}, 实际: #{xiaoming_booking.passenger_id_number}"
        
        xiaohong_booking = @train_bookings.find { |b| b.passenger_name == '小红' }
        expect(xiaohong_booking).not_to be_nil, "未找到小红的火车票"
        expect(xiaohong_booking.passenger_id_number).to eq(@xiaohong.id_number),
          "小红身份证号错误。期望: #{@xiaohong.id_number}, 实际: #{xiaohong_booking.passenger_id_number}"
      end
    
      add_assertion "接站起点正确（#{@arrival_station}）", weight: 10 do
        expect(@transfer.location_from).to eq(@arrival_station),
          "接站起点错误。期望: #{@arrival_station}（火车到达站），实际: #{@transfer.location_from}"
      end
    
      add_assertion "接站终点正确（#{@destination_location}）", weight: 10 do
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
      
      add_assertion "接站联系人信息正确（5人中任意1人）", weight: 5 do
        valid_passengers = [@zhangjianguo, @liuqiang, @wangfang, @xiaoming, @xiaohong]
        valid_names = valid_passengers.map(&:name)
        
        expect(valid_names).to include(@transfer.passenger_name),
          "接站联系人姓名错误。期望: 5人中任意1人（#{valid_names.join('、')}），实际: #{@transfer.passenger_name}"
        
        # 验证联系人电话与姓名匹配
        matched_passenger = valid_passengers.find { |p| p.name == @transfer.passenger_name }
        if matched_passenger
          expect(@transfer.passenger_phone).to eq(matched_passenger.phone),
            "接站联系电话与联系人不匹配。联系人: #{@transfer.passenger_name}，期望电话: #{matched_passenger.phone}，实际电话: #{@transfer.passenger_phone}"
        end
      end
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      target_train = @available_trains.order(:departure_time).first
      raise "未找到可用火车" unless target_train
    
      # 创建5个火车票订单（张建国、刘强、王芳、小明、小红各1张）
      family_passengers = [@zhangjianguo, @liuqiang, @wangfang, @xiaoming, @xiaohong]
      
      train_bookings = family_passengers.map do |passenger|
        TrainBooking.create!(
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
      end
    
      pickup_datetime = target_train.arrival_time + 15.minutes
    
      # 创建1个接站订单（经济7座，5人）
      transfer = Transfer.create!(
        user_id: user.id,
        transfer_package_id: @best_package.id,
        transfer_type: @transfer_type,
        service_type: @service_type,
        location_from: @station_location.name,
        location_to: @destination.name,
        pickup_datetime: pickup_datetime,
        passenger_name: @xiaohong.name,
        passenger_phone: @xiaohong.phone,
        passenger_count: @passenger_count,
        luggage_count: 3,
        total_price: @best_package.price,
        discount_amount: 0,
        status: 'paid',
        driver_status: 'pending',
        data_version: @data_version
      )
    
      { train_bookings: train_bookings, transfer: transfer }
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
        service_type: @service_type,
        expected_passenger_names: @expected_passenger_names
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
      @expected_passenger_names = data['expected_passenger_names'] || ['张建国', '刘强', '王芳', '小明', '小红'].sort
    
      # 重新查询乘客信息用于验证
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangjianguo = user.passengers.find_by!(name: '张建国', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      @xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)
      @xiaohong = user.passengers.find_by!(name: '小红', data_version: 0)
    
      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@travel_date)
    
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
