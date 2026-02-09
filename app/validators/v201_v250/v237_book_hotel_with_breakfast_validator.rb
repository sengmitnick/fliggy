# frozen_string_literal: true

require_relative '../base_validator'

# V237: 预订带早餐的酒店
#
# 任务描述:
#   用户需要预订提供早餐的酒店
#
# 评分标准:
#   - 创建了酒店订单 (30%)
#   - 酒店提供早餐 (40%)
#   - 入住日期和时长正确 (20%)
#   - 订单状态有效 (10%)
module V201V250
  class V237BookHotelWithBreakfastValidator < BaseValidator
    self.validator_id = 'v237_book_hotel_with_breakfast_validator'
    self.task_id = '3ff3f4ff-4f4f-4f6f-6f7f-5f8a9b0c1d2f'
    self.title = '预订明天带早餐的酒店'
    self.description = '用户需要预订提供早餐的酒店'
    self.timeout_seconds = 300
    
    def prepare
      @city = '广州'
      @check_in_date = Date.current + 1.day
      @check_out_date = @check_in_date + 2.days
      
      # 查找提供早餐的酒店（通过facilities或name包含"早餐"）
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("facilities LIKE ? OR name LIKE ?", 
               "%早餐%", "%早餐%")
        .to_a
      
      raise "未找到提供早餐的酒店" if @available_hotels.empty?
      
      {
        task: "请预订#{@check_in_date.strftime('%Y年%m月%d日')}（明天）在#{@city}提供早餐的酒店，住2晚。",
        requirements: {
          city: @city,
          breakfast: '必须提供早餐',
          check_in_date: @check_in_date,
          nights: 2,
          purpose: '包含早餐'
        },
        hint: "选择设施或描述中包含'早餐'的酒店。"
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
      
      add_assertion "酒店提供早餐", weight: 40 do
        hotel = @hotel_booking.hotel
        has_breakfast = hotel.facilities&.include?('早餐') || 
                        hotel.name&.include?('早餐')
        
        expect(has_breakfast).to eq(true),
          "酒店不提供早餐。酒店: #{hotel.name}, 设施: #{hotel.facilities}"
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
      
      # 选择第一家提供早餐的酒店
      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).first
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name,
        guest_phone: '13800138000',
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
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("facilities LIKE ? OR name LIKE ?", 
               "%早餐%", "%早餐%")
        .to_a
    end
  end
end
