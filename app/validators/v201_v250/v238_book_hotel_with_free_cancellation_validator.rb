# frozen_string_literal: true

require_relative '../base_validator'

# V238: 预订可免费取消的酒店
#
# 任务描述:
#   用户需要预订支持免费取消的酒店
#
# 评分标准:
#   - 创建了酒店订单 (30%)
#   - 酒店支持免费取消 (40%)
#   - 入住日期和时长正确 (20%)
#   - 订单状态有效 (10%)
module V201V250
  class V238BookHotelWithFreeCancellationValidator < BaseValidator
    self.validator_id = 'v238_book_hotel_with_free_cancellation_validator'
    self.task_id = '4ff405ff-5f5f-5f7f-7f8f-6f9a0b1c2d3f'
    self.title = '预订可免费取消的酒店（4天后入住）'
    self.description = '用户需要预订支持免费取消的酒店'
    self.timeout_seconds = 300
    
    def prepare
      @city = '深圳'
      @check_in_date = Date.current + 4.days
      @check_out_date = @check_in_date + 1.day
      
      # 查询demo_user乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = OpenStruct.new(
        name: demo_user.passenger_name,
        id_number: demo_user.passenger_id_number,
        phone: demo_user.passenger_phone
      )
      
      # 查找支持免费取消的酒店（cancellation_policy包含"免费"或"free"）
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("cancellation_policy LIKE ? OR cancellation_policy LIKE ?", 
               "%免费%", "%free%")
        .to_a
      
      raise "未找到支持免费取消的酒店" if @available_hotels.empty?
      
      {
        task: "请预订#{@check_in_date.strftime('%Y年%m月%d日')}在#{@city}支持免费取消的酒店，住1晚。",
        requirements: {
          city: @city,
          cancellation: '必须支持免费取消',
          check_in_date: @check_in_date,
          nights: 1,
          purpose: '行程灵活'
        },
        hint: "选择取消政策中包含'免费取消'的酒店。"
      }
    end
    
    def verify
      add_assertion "创建了酒店订单", weight: 30 do
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
      
      add_assertion "酒店支持免费取消", weight: 40 do
        hotel = @hotel_booking.hotel
        has_free_cancellation = hotel.cancellation_policy&.include?('免费') || 
                                hotel.cancellation_policy&.downcase&.include?('free')
        
        expect(has_free_cancellation).to eq(true),
          "酒店不支持免费取消。酒店: #{hotel.name}, 取消政策: #{hotel.cancellation_policy}"
      end
      
      add_assertion "入住日期和时长正确", weight: 20 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择第一家支持免费取消的酒店
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
        total_price: room.price,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("cancellation_policy LIKE ? OR cancellation_policy LIKE ?", 
               "%免费%", "%free%")
        .to_a
    end
  end
end
