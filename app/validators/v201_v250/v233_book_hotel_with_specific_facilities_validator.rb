# frozen_string_literal: true

require_relative '../base_validator'

# V233: 预订带特定设施的酒店（如游泳池、健身房）
#
# 任务描述:
#   用户需要预订带有特定设施的酒店（如游泳池、健身房、停车场）
#
# 评分标准:
#   - 创建了酒店订单 (30%)
#   - 酒店包含所需设施 (40%)
#   - 入住日期和时长正确 (20%)
#   - 订单状态有效 (10%)
module V201V250
  class V233BookHotelWithSpecificFacilitiesValidator < BaseValidator
    self.validator_id = 'v233_book_hotel_with_specific_facilities_validator'
    self.task_id = '9ff9b0ff-0f0f-0f2f-2f3f-1f4a5b6c7d8f'
    self.title = '预订带特定设施的酒店'
    self.description = '用户需要预订带有特定设施的酒店（如游泳池、健身房、停车场）'
    self.timeout_seconds = 300
    
    def prepare
      @city = '上海'
      @required_facility = '游泳池'
      @check_in_date = Date.today + 1.day
      @check_out_date = @check_in_date + 1.day
      
      # 查找包含指定设施的酒店
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("facilities LIKE ?", "%#{@required_facility}%")
        .to_a
      
      raise "未找到带#{@required_facility}的酒店" if @available_hotels.empty?
      
      {
        task: "请预订#{@check_in_date.strftime('%Y年%m月%d日')}（明天）在#{@city}带#{@required_facility}的酒店，住1晚。",
        requirements: {
          city: @city,
          facilities: "必须有#{@required_facility}",
          check_in_date: @check_in_date,
          nights: 1,
          purpose: '运动健身'
        },
        hint: "选择设施中包含'#{@required_facility}'的酒店。"
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
      
      add_assertion "酒店包含所需设施（#{@required_facility}）", weight: 40 do
        hotel = @hotel_booking.hotel
        has_facility = hotel.facilities&.include?(@required_facility)
        
        expect(has_facility).to eq(true),
          "酒店不包含所需设施。要求: #{@required_facility}, 实际酒店设施: #{hotel.facilities}"
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
      
      # 选择第一家符合设施要求的酒店
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
        required_facility: @required_facility,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @required_facility = data['required_facility']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("facilities LIKE ?", "%#{@required_facility}%")
        .to_a
    end
  end
end
