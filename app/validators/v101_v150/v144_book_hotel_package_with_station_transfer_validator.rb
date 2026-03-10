# frozen_string_literal: true

require_relative '../base_validator'


# 验证用例144: 帮张三预订明天北京酒店套餐，住1晚，并预订北京南站接站服务（明天下午2点从上海到达，送至国贸CBD）
#
# 任务描述:
#   张三计划明天下午从上海乘高铁到北京（预计下午2点左右到达北京南站），入住北京酒店套餐，住1晚。
#   同时需要预订北京南站的接站服务（从上海乘高铁来，下午2点左右接站）送至国贸CBD。
#
# 任务分解步骤:
#   1. 查询北京的酒店套餐（使用 HotelPackage.where(city: '北京', night_count: 1)）
#   2. 筛选入住日期=明天（Date.tomorrow）、住宿晚数=1晚的套餐
#   3. 创建酒店套餐订单（contact_name=张三，contact_phone=张三电话，确保联系人信息匹配）
#   4. 创建火车站接站服务订单（transfer_type=train_pickup，明天下午2点从上海到达北京南站，location_from=北京南站北广场接送中心，location_to=国贸CBD）
#   5. 确保接站服务的乘客信息也使用张三的姓名和电话
#
# 复杂度分析（4个复杂点）：
#   1. 组合预订：需同时创建酒店套餐订单+火车站接站订单（2个不同类型的订单）
#   2. 联系人信息一致性：酒店订单联系人和接站服务乘客都必须使用张三的信息
#   3. 时间协调：接站时间需要匹配入住日期
#   4. 地点查询：需要从 TransferLocation 表查询北京南站接送中心和国贸CBD服务点
#
# 评分标准（总分100分）：
#   1. 创建了酒店套餐订单（25分）
#   2. 城市正确=北京（10分）
#   3. 入住日期正确=明天（10分）
#   4. 住宿晚数正确=1晚（10分）
#   5. 酒店订单联系人信息正确=张三（10分）
#   6. 创建了火车站接站服务（15分）
#   7. 接站服务乘客信息正确=张三（10分）
#   8. 接站地点=北京南站（根据上海→北京高铁到达站确定，非用户指定）（5分）
#   9. 下车点正确=国贸CBD（5分）
#
# 使用方法:
#   rake validator:simulate_single[v144_book_hotel_package_with_station_transfer_validator]

module V101V150
  class V144BookHotelPackageWithStationTransferValidator < BaseValidator
    self.validator_id = 'v144_book_hotel_package_with_station_transfer_validator'
    self.task_id = 'e4f5a6b7-8c9d-0e1f-2a3b-4c5d6e7f8a9b'
    self.title = '帮张三预订明天北京酒店套餐，住1晚，并预订北京南站接站服务（明天下午2点从上海到达，送至国贸CBD）'
    self.description = '帮张三预订明天北京酒店套餐，住1晚，并预订北京南站接站服务（明天下午2点从上海到达，送至国贸CBD）'
    
    def task_description
      "张三计划明天下午从上海乘高铁到北京（预计下午2点左右到达北京南站），" \
      "需要预订北京的1晚酒店套餐，并预订北京南站接站服务送至国贸CBD。"
    end
    self.timeout_seconds = 300

    def prepare
      @checkin_date = Date.tomorrow
      @nights = 1
      @city = '北京'
      
      # 查询上海→14:00左右到达北京的火车，从火车数据获取到达站
      @train = Train
        .where(departure_city: '上海', arrival_city: @city, data_version: 0)
        .by_date(@checkin_date)
        .find { |t| t.arrival_time.hour == 14 }
      
      raise "数据包缺少14:00到达北京的上海高铁" unless @train
      
      # 接站地点=火车到达站名称（从火车数据动态获取）
      @pickup_location = @train.arrival_station
      
      # 送达地点=用户指定的目的地
      @dropoff_location = '国贸CBD'
      
      # 预查询联系人信息（用于 simulate 和 verify）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @zhangsan.name
      @expected_contact_phone = @zhangsan.phone
      
      # 查找可用的1晚酒店套餐
      @available_packages = HotelPackage
        .where(city: @city, data_version: 0)
        .where(night_count: @nights)
        .to_a
      
      expect(@available_packages).not_to be_empty, "数据包缺少北京1晚酒店套餐"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      package = @available_packages.first
      option = package.package_options.first
      
      # 创建酒店套餐订单
      HotelPackageOrder.create!(
        user: user,
        hotel_package: package,
        hotel_id: package.hotel.id,
        package_option: option,
        passenger_id: passenger.id,
        contact_name: passenger.name,
        contact_phone: passenger.phone,
        check_in_date: @checkin_date,
        check_out_date: @checkin_date + @nights.days,
        total_price: option.price,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 创建火车站接站服务（北京南站到国贸CBD）
      Transfer.create!(
        user: user,
        transfer_type: 'train_pickup',
        service_type: 'from_station',
        location_from: @pickup_location,  # 火车到达站名称
        location_to: @dropoff_location,   # 用户指定目的地
        pickup_datetime: @checkin_date.in_time_zone + 14.hours,  # 下午2点
        vehicle_type: 'economy_5',
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        total_price: 80.0,
        status: 'pending',
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        checkin_date: @checkin_date.to_s,
        nights: @nights,
        city: @city,
        train_id: @train&.id,
        pickup_location: @pickup_location,
        dropoff_location: @dropoff_location,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @checkin_date = Date.parse(data['checkin_date']) if data['checkin_date']
      @nights = data['nights']
      @city = data['city']
      @pickup_location = data['pickup_location']
      @dropoff_location = data['dropoff_location']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
      
      # 重新查询火车数据
      @train = Train.find_by(id: data['train_id'], data_version: 0) if data['train_id']
    end

    def verify
      # 断言1: 创建了酒店套餐订单
      add_assertion "创建了酒店套餐订单", weight: 25 do
        all_orders = HotelPackageOrder
          .joins(:hotel_package)
          .includes(:hotel_package, :package_option)
          .where(hotel_packages: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_orders).not_to be_empty, "未找到任何酒店套餐订单"
        
        @hotel_package_order = all_orders.first
      end
      
      return if @hotel_package_order.nil?
      
      # 断言2: 城市正确
      add_assertion "城市正确（#{@city}）", weight: 10 do
        expect(@hotel_package_order.hotel_package.city).to eq(@city),
          "城市错误。期望: #{@city}, 实际: #{@hotel_package_order.hotel_package.city}"
      end
      
      # 断言3: 入住日期正确
      add_assertion "入住日期正确（#{@checkin_date}）", weight: 10 do
        expect(@hotel_package_order.check_in_date).to eq(@checkin_date),
          "入住日期错误。期望: #{@checkin_date}（明天）, 实际: #{@hotel_package_order.check_in_date}"
      end
      
      # 断言4: 住宿晚数正确
      add_assertion "住宿晚数正确（#{@nights}晚）", weight: 10 do
        actual_nights = (@hotel_package_order.check_out_date - @hotel_package_order.check_in_date).to_i
        expect(actual_nights).to eq(@nights),
          "住宿晚数错误。期望: #{@nights}晚, 实际: #{actual_nights}晚"
      end
      
      # 断言5: 酒店订单联系人信息正确（张三）
      add_assertion "酒店订单联系人信息正确（张三）", weight: 10 do
        expect(@hotel_package_order.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@hotel_package_order.contact_name}"
        expect(@hotel_package_order.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@hotel_package_order.contact_phone}"
      end
      
      # 断言6: 创建了火车站接站服务
      add_assertion "创建了火车站接站服务", weight: 15 do
        @transfer = Transfer
          .where(transfer_type: 'train_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到火车站接站服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言7: 接站服务乘客信息正确（张三）
      add_assertion "接站服务乘客信息正确（张三）", weight: 10 do
        expect(@transfer.passenger_name).to eq(@expected_contact_name),
          "乘客姓名错误。期望: #{@expected_contact_name}, 实际: #{@transfer.passenger_name}"
        expect(@transfer.passenger_phone).to eq(@expected_contact_phone),
          "乘客电话错误。期望: #{@expected_contact_phone}, 实际: #{@transfer.passenger_phone}"
      end
      
      # 断言8: 接站地点=北京南站（根据上海→北京高铁到达站确定）
      add_assertion "接站地点=北京南站（根据火车到达站确定）", weight: 5 do
        expect(@transfer.location_from).to eq(@pickup_location),
          "接站地点错误。上海→北京高铁到达#{@pickup_location}，应在#{@pickup_location}接站，实际: #{@transfer.location_from}"
      end
      
      # 断言9: 送达地点=国贸CBD（用户指定）
      add_assertion "送达地点=国贸CBD（用户指定）", weight: 5 do
        expect(@transfer.location_to).to eq(@dropoff_location),
          "送达地点错误。期望: #{@dropoff_location}, 实际: #{@transfer.location_to}"
      end
    end
  end
end
