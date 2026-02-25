# frozen_string_literal: true

require_relative '../base_validator'

# V232: 预订指定地点附近的酒店（如市中心/景点附近）
#
# 任务描述:
#   用户需要预订特定地点附近的酒店（如市中心、火车站附近、景点附近）
#
# 评分标准:
#   - 创建了酒店订单 (25%)
#   - 酒店位置符合要求（在指定地点附近） (35%)
#   - 入住日期和时长正确 (20%)
#   - 入住人信息正确 (15%)
#   - 订单状态有效 (5%)
module V201V250
  class V232BookHotelNearSpecificLocationValidator < BaseValidator
    self.validator_id = 'v232_book_hotel_near_specific_location_validator'
    self.task_id = '8ff8a9ff-9f9f-9f1f-1f2f-0f3a4b5c6d7f'
    self.title = '张三后天要去北京开会，需要在CBD核心区附近预订酒店住2晚，方便参会'
    self.description = '张三后天要去北京开会，需要在CBD核心区附近预订酒店住2晚，方便参会'
    self.timeout_seconds = 300
    
    def prepare
      @city = '北京'
      @location_keyword = 'CBD核心区'  # 市中心/商圈
      @check_in_date = Date.current + 2.days
      @check_out_date = @check_in_date + 2.days
      
      # 查询demo_user乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      demo_passenger = Passenger.find_by!(user_id: demo_user.id, is_self: true, data_version: 0)
      @passenger = OpenStruct.new(
        name: demo_passenger.name,
        id_number: demo_passenger.id_number,
        phone: demo_passenger.phone
      )
      
      # 查找包含位置关键词的酒店
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("name LIKE ? OR address LIKE ?", "%#{@location_keyword}%", "%#{@location_keyword}%")
        .to_a
      
      raise "未找到#{@location_keyword}附近的酒店" if @available_hotels.empty?
      
      {
        task: "请预订#{@check_in_date.strftime('%Y年%m月%d日')}（后天）在#{@city}#{@location_keyword}附近的酒店，住2晚。",
        requirements: {
          city: @city,
          location: "#{@location_keyword}附近",
          check_in_date: @check_in_date,
          nights: 2,
          purpose: '位置便利'
        },
        hint: "选择名称或地址包含'#{@location_keyword}'的酒店。"
      }
    end
    
    def verify
      add_assertion "创建了酒店订单", weight: 25 do
        all_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .to_a
        
        @hotel_booking = all_bookings.first
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "酒店位置符合要求（#{@location_keyword}附近）", weight: 35 do
        hotel = @hotel_booking.hotel
        name_match = hotel.name.include?(@location_keyword)
        address_match = hotel.address&.include?(@location_keyword)
        
        expect(name_match || address_match).to eq(true),
          "酒店位置不符合要求。期望: #{@location_keyword}附近, 实际酒店: #{hotel.name}（地址: #{hotel.address}）"
      end
      
      add_assertion "入住日期和时长正确", weight: 20 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "入住人信息正确（姓名、手机号）", weight: 15 do
        demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
        expect(@hotel_booking.guest_name).to eq(demo_user.name),
          "入住人姓名错误。期望: #{demo_user.name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@passenger.phone),
          "入住人电话错误。期望: #{@passenger.phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择第一家符合位置要求的酒店
      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).first
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name,
        guest_phone: @passenger.phone,
        room_count: 1,
        total_price: room.price * 2,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        location_keyword: @location_keyword,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        passenger_phone: @passenger.phone
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @location_keyword = data['location_keyword']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      
      @passenger = OpenStruct.new(
        name: data['passenger_name'],
        id_number: data['passenger_id_number'],
        phone: data['passenger_phone']
      )
      
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("name LIKE ? OR address LIKE ?", "%#{@location_keyword}%", "%#{@location_keyword}%")
        .to_a
    end
  end
end
