# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例199: 给张三预订CBD商务酒店+机场快线接送
#
# 任务描述:
#   预订CBD商务酒店+机场快线接送服务
#
# 评分标准:
#   - 创建了酒店订单 (30%)
#   - 创建了接送服务订单 (30%)
#   - 酒店为商务型（CBD/商圈） (15%)
#   - 乘客和入住人信息正确（李四） (15%)
#   - 接送服务类型正确（机场接送） (5%)
#   - 日期合理 (5%)
module V151V200
  class V199BookCbdBusinessHotelAndAirportShuttleValidator < BaseValidator
    self.validator_id = 'v199_book_cbd_business_hotel_and_airport_shuttle_validator'
    self.task_id = '1b8f7359-8e4c-4e2f-a7c8-ff25c53c02a3'
    self.title = '给张三预订CBD商务酒店+机场快线接送'
    self.description = '预订CBD商务酒店+机场快线接送'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @city = '上海'
      @check_in_date = Date.current + 1.day  # 明天
      
      # 查找酒店（不限制商务型）
      @available_hotels = Hotel
        .where(city: @city, data_version: 0)
        .order(price: :desc)
        .to_a
      
      expect(@available_hotels).not_to be_empty,
        "数据包缺少#{@city}的酒店"
      
      {
        task: "请为#{@passenger.name}预订#{@check_in_date.strftime('%m月%d日')}#{@city}CBD的商务酒店，并预订机场接送服务",
        city: @city,
        check_in_date: @check_in_date.strftime('%Y-%m-%d'),
        hint: "选择商务区的酒店，提供机场接送服务"
      }
    end
    
    def verify
      # 断言1: 创建了酒店订单 (30%)
      add_assertion "创建了酒店订单", weight: 30 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单（#{@city}）"
      end
      
      # 断言2: 创建了接送服务订单 (30%)
      add_assertion "创建了接送服务订单", weight: 30 do
        @transfer_order = Transfer
          .where(transfer_type: 'airport_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer_order).not_to be_nil, "未找到接送服务订单"
      end
      
      return if @hotel_booking.nil? || @transfer_order.nil?
      
      # 断言3: 酒店为商务型（CBD/商圈） (15%)
      add_assertion "酒店为商务型（CBD/商圈）", weight: 15 do
        hotel = @hotel_booking.hotel
        # 高星级或高价格酒店认为是商务型
        is_business = hotel.star_level.to_i >= 4 || hotel.price.to_f >= 500
        
        expect(is_business).to be(true),
          "酒店不是商务型。酒店: #{hotel.name}（星级: #{hotel.star_level}, 价格: #{hotel.price}）"
      end
      
      # 断言4: 乘客和入住人信息正确（李四） (15%)
      add_assertion "乘客和入住人信息正确（#{@expected_passenger_name}）", weight: 15 do
        # 检查接送服务乘客姓名
        expect(@transfer_order.passenger_name).to eq(@expected_passenger_name),
          "接送服务乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@transfer_order.passenger_name}"
        
        # 检查接送服务联系人
        expect(@transfer_order.passenger_phone).to eq(@expected_phone),
          "接送服务联系人电话错误。期望: #{@expected_phone}, 实际: #{@transfer_order.passenger_phone}"
        
        # 检查酒店入住人
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "酒店入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言5: 接送服务类型正确（机场接送） (5%)
      add_assertion "接送服务类型正确（机场接送）", weight: 5 do
        expect(@transfer_order.transfer_type).to eq('airport_pickup'),
          "接送服务类型错误。期望: airport_pickup，实际: #{@transfer_order.transfer_type}"
      end
      
      # 断言6: 日期合理 (5%)
      add_assertion "日期合理", weight: 5 do
        checkin_date = @hotel_booking.check_in_date
        transfer_date = @transfer_order.pickup_datetime.to_date
        expect((checkin_date - transfer_date).abs).to be <= 1
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '李四', data_version: 0)
      
      # 创建酒店订单（选择价格较高的酒店，表示商务型）
      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first!
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @check_in_date,
        check_out_date: @check_in_date + 2.days,
        guest_name: user.name,
        guest_phone: passenger.phone,
        payment_method: '花呗',
        total_price: room.price * 2,
        data_version: @data_version
      )
      
      # 创建机场接送订单
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: "#{@city}浦东国际机场",
        location_to: hotel.address || "#{@city}CBD",
        pickup_datetime: @check_in_date.to_time + 10.hours,
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        vehicle_type: '舒适型',
        provider_name: '快车服务',
        total_price: 120.0,
        passenger_count: 1,
        luggage_count: 1,
        driver_status: 'pending',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def is_business_hotel?(hotel)
      return true if hotel.hotel_type&.include?('商务')
      return true if hotel.hotel_type&.include?('CBD')
      return true if hotel.name&.include?('商务')
      return true if hotel.name&.include?('CBD')
      return true if hotel.region&.include?('CBD')
      return true if hotel.region&.include?('商圈')
      return true if hotel.region&.include?('金融区')
      return true if hotel.features&.include?('商务')
      false
    end
    
    def execution_state_data
      {
        city: @city,
        check_in_date: @check_in_date&.to_s
      }
    end
    
    def restore_from_state(data)
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
    end
  end
end