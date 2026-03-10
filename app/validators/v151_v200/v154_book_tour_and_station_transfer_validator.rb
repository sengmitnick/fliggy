# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例154: 给张三订明天北京2日跟团游，并订火车站接站服务（接今天从上海来的朋友，G102次中午12点到北京南站，送到国贸CBD）
#
# 任务描述:
#   张三计划明天参加北京2日跟团游，并预订火车站接站服务送到国贸CBD，接今天从上海来的朋友（G102次列车，中午12:00到达北京南站）。
#   1. 北京2日跟团游（明天出发）
#   2. 北京南站接站服务（从北京南站接站，送至国贸CBD，接今天从上海来的朋友G102次，列车12:00到达）
#
# 任务分解步骤:
#   1. 查询北京2日跟团游产品
#   2. 创建跟团游订单（travel_date=明天，乘客=张三）
#   3. 查询Train获取今天从上海到北京的列车，确定列车号、到达时间、到达车站
#   4. 查询TransferLocation获取北京国贸CBD服务点（location_type='other'，名称包含'国贸'）（送达地点）
#   5. 创建接站服务订单（transfer_type=train_pickup，train_number=列车号，location_from=Train.arrival_station，location_to=国贸CBD服务点，pickup_datetime=列车到达后30分钟）
#
# 复杂度分析（5个复杂点）：
#   1. 多模块组合：需要同时创建跟团游订单+接站服务订单（2个不同类型的订单）
#   2. 列车信息查询：需要从 Train 模型查询朋友从上海来的列车信息（train_number、arrival_time、arrival_station）
#   3. 接站地点查询：需要从 Train.arrival_station 动态获取接站地点（列车在哪下就在哪接）
#   4. 送达地点查询：需要从 TransferLocation 查询具体的送达地点（国贸CBD，不使用笼统的"市区"）
#   5. 时间计算：接站时间=列车到达后10-30分钟
#
# 评分标准（总分100）：
#   1. 创建了跟团游订单（20分）
#   2. 城市正确=北京（10分）
#   3. 出发日期正确=明天（10分）
#   4. 行程天数正确=2天（5分）
#   5. 创建了火车站接站服务（15分）
#   6. 接站地点正确=列车到达车站（从 Train.arrival_station 动态获取）（8分）
#   7. 送达地点正确=国贸CBD服务点（从 TransferLocation 动态获取）（10分）
#   8. 接站服务关联了具体列车号（从上海来的列车）（10分）
#   9. 接站时间合理（列车到达后10-30分钟）（7分）
#   10. 联系人信息正确（张三）（5分）
#
# 使用方法:
#   rake validator:simulate_single[v154_book_tour_and_station_transfer_validator]
#
module V151V200
  class V154BookTourAndStationTransferValidator < BaseValidator
    self.validator_id = 'v154_book_tour_and_station_transfer_validator'
    self.task_id = 'd9e0f1a2-3b4c-5d6e-7f8a-9b0c1d2e3f5a'
    self.title = '给张三订明天北京2日跟团游，并订火车站接站服务（接今天从上海来的朋友，G102次中午12点到北京南站，送到国贸CBD）'
    self.description = '给张三订明天北京2日跟团游，并订火车站接站服务（接今天从上海来的朋友，G102次列车，中午12:00到达北京南站，送到国贸CBD）'
    self.timeout_seconds = 300

    def prepare
      @tour_date = Date.current + 1.day  # 明天游玩
      @train_date = Date.current  # 今天火车到达
      @city = '北京'
      @train_origin = '上海'
      
      # 查询今天从上海到北京的列车（获取列车号、到达时间、到达车站）
      @train = Train.where(
        departure_city: @train_origin,
        arrival_city: @city,
        data_version: 0
      ).by_date(@train_date).find { |t| t.arrival_station.include?('北京南站') }
      
      raise "数据包缺少今天从#{@train_origin}到#{@city}南站的列车" unless @train
      
      # 从列车获取关键信息
      @train_number = @train.train_number  # 列车号
      @train_arrival_time = @train.arrival_time  # 到达时间
      @train_arrival_station = @train.arrival_station  # 到达车站（接站点=高铁在哪下就在哪接）
      
      # 查询TransferLocation获取北京国贸CBD服务点（送达地点）
      @dropoff_loc = TransferLocation.where(
        city: @city,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('国贸') }
      
      raise "数据包缺少北京国贸CBDTransferLocation" unless @dropoff_loc
      
      @dropoff_location = @dropoff_loc.name  # 送达地点=国贸CBD（从TransferLocation动态获取）
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 查找可用的北京2日跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 2, data_version: 0)
        .to_a
      
      expect(@available_tours).not_to be_empty, "数据包缺少北京2日跟团游产品"
      
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
      
      # 计算接站时间（列车到达后30分钟）
      pickup_datetime = @train_arrival_time + 30.minutes
      
      # 创建火车站接站服务（关联列车号）
      Transfer.create!(
        user: user,
        transfer_package_id: @best_package.id,
        transfer_type: 'train_pickup',
        service_type: 'from_station',
        location_from: @train_arrival_station,  # 接站地点=列车到达车站（从Train.arrival_station动态获取）
        location_to: @dropoff_location,  # 送达地点=国贸CBD服务点（从TransferLocation动态获取）
        pickup_datetime: pickup_datetime,  # 列车到达后30分钟
        train_number: @train_number,  # 关联列车号（从Train动态获取）
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
        train_origin: @train_origin,
        train_number: @train_number,
        train_arrival_station: @train_arrival_station,
        dropoff_location: @dropoff_location,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @tour_date = Date.parse(data['tour_date']) if data['tour_date']
      @train_date = Date.parse(data['train_date']) if data['train_date']
      @city = data['city']
      @train_origin = data['train_origin']
      @train_number = data['train_number']
      @train_arrival_station = data['train_arrival_station']
      @dropoff_location = data['dropoff_location']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
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
      
      # 断言4: 行程天数正确（2天）
      add_assertion "行程天数正确（2天）", weight: 5 do
        expect(@tour_booking.tour_group_product.duration).to eq(2),
          "行程天数错误。期望: 2天, 实际: #{@tour_booking.tour_group_product.duration}天"
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
      
      # 断言6: 接站地点正确=列车到达车站（从 Train.arrival_station 动态获取）
      add_assertion "接站地点正确（#{@train_arrival_station}，从Train.arrival_station动态获取）", weight: 8 do
        expect(@transfer.location_from).to eq(@train_arrival_station),
          "接站地点错误。期望: #{@train_arrival_station}（从Train.arrival_station动态获取）, 实际: #{@transfer.location_from}"
      end
      
      # 断言7: 送达地点正确=国贸CBD服务点（从 TransferLocation 动态获取）
      add_assertion "送达地点正确（#{@dropoff_location}，从TransferLocation动态获取）", weight: 10 do
        expect(@transfer.location_to).to eq(@dropoff_location),
          "送达地点错误。期望: #{@dropoff_location}（从TransferLocation动态获取）, 实际: #{@transfer.location_to}"
      end
      
      # 断言8: 接站服务关联了具体列车号（从上海来的列车）
      add_assertion "接站服务关联了具体列车号（#{@train_origin}→#{@city}的列车）", weight: 10 do
        expect(@transfer.train_number).not_to be_nil, "接站服务未关联列车号"
        expect(@transfer.train_number).to eq(@train_number),
          "列车号错误。期望: #{@train_number}, 实际: #{@transfer.train_number}"
      end
      
      # 断言9: 接站时间合理（列车到达后10-30分钟）
      add_assertion "接站时间合理（列车到达后10-30分钟）", weight: 7 do
        if @transfer.train_number.present?
          # 查询对应的列车（必须指定日期）
          train = Train
            .where(train_number: @transfer.train_number, data_version: 0)
            .where(departure_city: @train_origin, arrival_city: @city)
            .by_date(@train_date)
            .first
          
          if train && train.arrival_time.present?
            time_after_arrival = ((@transfer.pickup_datetime - train.arrival_time) / 60.0).round
            is_reasonable = time_after_arrival >= 10 && time_after_arrival <= 30
            
            expect(is_reasonable).to be(true),
              "接站时间不合理。列车#{train.arrival_time.strftime('%H:%M')}到达，" \
              "接站时间#{@transfer.pickup_datetime.strftime('%H:%M')}，" \
              "间隔#{time_after_arrival}分钟（应为10-30分钟）"
          end
        end
      end
      
      # 断言9: 联系人信息正确（张三）
      add_assertion "联系人信息正确（张三）", weight: 5 do
        expect(@tour_booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@tour_booking.contact_name}"
        expect(@tour_booking.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@tour_booking.contact_phone}"
      end
    end
  end
end
