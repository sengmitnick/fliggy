# frozen_string_literal: true

require_relative '../base_validator'

# V157: 预订深圳跟团游 + 火车站送站服务（关联具体火车）
# 验证用户能够完成跟团游预订+火车站送站服务的组合下单，送站需关联具体火车班次

module V151V200
  class V157BookTourWithStationDropoffValidator < BaseValidator
    self.validator_id = 'v157_book_tour_with_station_dropoff_validator'
    self.task_id = 'a2b3c4d5-6e7f-8a9b-0c1d-2e3f4a5b6c8d'
    self.title = '给张三订明天深圳2日跟团游，并订火车站送站服务（送第3天从深圳北站到广州的火车）'
    self.description = '给张三订明天深圳2日跟团游，并订火车站送站服务（送第3天从深圳北站到广州的火车）'
    self.timeout_seconds = 300

    def prepare
      @tour_date = Date.current + 1.day  # 明天开始游玩
      @train_date = Date.current + 3.days  # 第3天离开
      @city = '深圳'
      @train_destination = '广州'
      @station_location = '深圳北站'
      @duration_days = 2
      
      # 预查询demo_user的乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 查找可用的深圳2日跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 2, data_version: 0)
        .to_a
      
      expect(@available_tours).not_to be_empty, "数据包缺少深圳2日跟团游产品"
      
      # 查找第3天从深圳北站到广州的火车
      @available_trains = Train
        .where(departure_city: @city, arrival_city: @train_destination, data_version: 0)
        .by_date(@train_date)
        .where("departure_station LIKE ?", "%北站%")
        .to_a
      
      expect(@available_trains).not_to be_empty, "数据包缺少深圳北站到广州的火车"
      
      # 查找舒适型5座套餐
      @available_packages = TransferPackage.where(
        vehicle_category: 'comfort_5',
        data_version: 0
      ).order(:price)
      
      expect(@available_packages).not_to be_empty, "未找到舒适型5座套餐"
      
      @best_package = @available_packages.first
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      tour = @available_tours.first
      tour_package = tour.tour_packages.where(data_version: 0).order(:price).first
      
      raise "产品 #{tour.title} 没有可用套餐" if tour_package.nil?
      
      # 创建跟团游订单
      TourGroupBooking.create!(
        user: user,
        tour_group_product: tour,
        tour_package: tour_package,
        travel_date: @tour_date,
        adult_count: 1,
        child_count: 0,
        contact_name: @passenger.name,
        contact_phone: @passenger.phone,
        total_price: tour_package.price,
        status: 'pending',
        data_version: @data_version
      )
      
      # 选择第3天出发的火车
      target_train = @available_trains.min_by { |t| t.departure_time }
      raise "未找到可用火车" unless target_train
      
      # 计算送站时间（火车出发前30分钟）
      pickup_datetime = target_train.departure_time - 30.minutes
      
      # 创建火车站送站服务（关联火车班次号）
      Transfer.create!(
        user: user,
        transfer_package_id: @best_package.id,
        transfer_type: 'train_dropoff',
        service_type: 'to_station',
        location_from: "#{@city}市区",
        location_to: @station_location,
        pickup_datetime: pickup_datetime,
        train_number: target_train.train_number,
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
        tour_date: @tour_date.to_s,
        train_date: @train_date.to_s,
        city: @city,
        train_destination: @train_destination,
        station_location: @station_location,
        duration_days: @duration_days
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @tour_date = Date.parse(data['tour_date']) if data['tour_date']
      @train_date = Date.parse(data['train_date']) if data['train_date']
      @city = data['city']
      @train_destination = data['train_destination']
      @station_location = data['station_location']
      @duration_days = data['duration_days']
      
      # 重新查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 重新查询跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 2, data_version: 0)
        .to_a
      
      # 重新查询火车
      @available_trains = Train
        .where(departure_city: @city, arrival_city: @train_destination, data_version: 0)
        .by_date(@train_date)
        .where("departure_station LIKE ?", "%北站%")
        .to_a
      
      # 重新查询套餐
      @available_packages = TransferPackage.where(
        vehicle_category: 'comfort_5',
        data_version: 0
      ).order(:price)
      
      @best_package = @available_packages.first if @available_packages.any?
    end

    def verify
      # 断言1: 创建了跟团游订单
      add_assertion "创建了跟团游订单", weight: 20 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product)
          .where(tour_group_products: { destination: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何跟团游订单"
        @tour_booking = all_bookings.first
      end
      
      return if @tour_booking.nil?
      
      # 断言2: 城市正确
      add_assertion "城市正确（#{@city}）", weight: 10 do
        expect(@tour_booking.tour_group_product.destination).to eq(@city),
          "城市错误。期望: #{@city}, 实际: #{@tour_booking.tour_group_product.destination}"
      end
      
      # 断言3: 出发日期正确
      add_assertion "出发日期正确（#{@tour_date}）", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@tour_date),
          "出发日期错误。期望: #{@tour_date}（明天）, 实际: #{@tour_booking.travel_date}"
      end
      
      # 断言4: 创建了火车站送站服务
      add_assertion "创建了火车站送站服务", weight: 15 do
        @transfer = Transfer
          .where(transfer_type: 'train_dropoff', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到火车站送站服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言5: 送站服务关联了具体火车班次号
      add_assertion "送站服务关联了具体火车班次号（#{@city}→#{@train_destination}）", weight: 20 do
        expect(@transfer.train_number).not_to be_nil, "送站服务未关联火车班次号"
        
        # 验证火车班次号对应的火车确实是深圳到广州
        train = Train.find_by(
          train_number: @transfer.train_number,
          departure_city: @city,
          arrival_city: @train_destination,
          data_version: 0
        )
        
        expect(train).not_to be_nil,
          "火车班次号#{@transfer.train_number}不是#{@city}到#{@train_destination}的火车"
        
        # 验证出发站是深圳北站
        if train
          expect(train.departure_station).to include('北站'),
            "火车出发站错误。期望: 深圳北站, 实际: #{train.departure_station}"
        end
      end
      
      # 断言6: 送站时间合理（火车出发前20-40分钟）
      add_assertion "送站时间合理（火车出发前20-40分钟）", weight: 10 do
        if @transfer.train_number.present?
          # 查询对应的火车（必须指定日期）
          train = Train
            .where(train_number: @transfer.train_number, data_version: 0)
            .where(departure_city: @city, arrival_city: @train_destination)
            .by_date(@train_date)
            .first
          
          if train && train.departure_time.present?
            time_before_train = ((train.departure_time - @transfer.pickup_datetime) / 60.0).round
            is_reasonable = time_before_train >= 20 && time_before_train <= 40
            
            expect(is_reasonable).to be(true),
              "送站时间不合理。火车#{train.departure_time.strftime('%H:%M')}出发，" \
              "送站时间#{@transfer.pickup_datetime.strftime('%H:%M')}，" \
              "提前#{time_before_train}分钟（应为20-40分钟）"
          end
        end
      end
      
      # 断言7: 送站地点正确（市区→火车站）
      add_assertion "送站地点正确（市区→火车站）", weight: 5 do
        expect(@transfer.location_from).to include("#{@city}市区"),
          "送站出发地错误。期望: #{@city}市区, 实际: #{@transfer.location_from}"
        expect(@transfer.location_to).to include(@city),
          "送站目的地错误。期望包含: #{@city}, 实际: #{@transfer.location_to}"
      end
      
      # 断言8: 联系人信息正确（张三）
      add_assertion "联系人信息正确（#{@expected_contact_name}）", weight: 10 do
        expect(@tour_booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@tour_booking.contact_name}"
        expect(@tour_booking.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@tour_booking.contact_phone}"
      end
    end
  end
end
