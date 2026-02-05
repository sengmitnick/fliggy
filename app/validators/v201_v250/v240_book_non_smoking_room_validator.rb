# frozen_string_literal: true

require_relative '../base_validator'

# V240: 预订无烟房
#
# 任务描述:
#   用户需要预订无烟房
#
# 评分标准:
#   - 创建了酒店订单 (30%)
#   - 房间为无烟房 (40%)
#   - 入住日期和时长正确 (20%)
#   - 订单状态有效 (10%)
module V201V250
  class V240BookNonSmokingRoomValidator < BaseValidator
    self.validator_id = 'v240_book_non_smoking_room_validator'
    self.task_id = '6ff627ff-7f7f-7f9f-9f0f-8f1a2b3c4d5f'
    self.title = '预订无烟房'
    self.description = '用户需要预订无烟房'
    self.timeout_seconds = 300
    
    def prepare
      @city = '杭州'
      @check_in_date = Date.current + 1.day
      @check_out_date = @check_in_date + 1.day
      
      # 查找无烟房（room_type包含"无烟"或"non-smoking"）
      @available_rooms = HotelRoom.joins(:hotel)
        .where(hotels: { city: @city, data_version: 0 })
        .where("hotel_rooms.room_type LIKE ? OR hotel_rooms.room_type LIKE ?", 
               "%无烟%", "%non-smoking%")
        .where(hotel_rooms: { data_version: 0 })
        .includes(:hotel)
        .to_a
      
      raise "未找到无烟房" if @available_rooms.empty?
      
      {
        task: "请预订#{@check_in_date.strftime('%Y年%m月%d日')}（明天）在#{@city}的无烟房，住1晚。",
        requirements: {
          city: @city,
          room_type: '无烟房',
          check_in_date: @check_in_date,
          nights: 1,
          purpose: '健康环境'
        },
        hint: "选择无烟房间。"
      }
    end
    
    def verify
      add_assertion "创建了酒店订单", weight: 30 do
        all_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel_room)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .to_a
        
        @hotel_booking = all_bookings.first
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "房间为无烟房", weight: 40 do
        room = @hotel_booking.hotel_room
        is_non_smoking = room.room_type&.include?('无烟') ||
                         room.room_type&.downcase&.include?('non-smoking')
        
        expect(is_non_smoking).to eq(true),
          "房间不是无烟房。房型: #{room.room_type}"
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
      
      # 选择第一个无烟房
      room = @available_rooms.first
      hotel = room.hotel
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room_id: room.id,
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
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      
      @available_rooms = HotelRoom.joins(:hotel)
        .where(hotels: { city: @city, data_version: 0 })
        .where("hotel_rooms.room_type LIKE ? OR hotel_rooms.room_type LIKE ?", 
               "%无烟%", "%non-smoking%")
        .where(hotel_rooms: { data_version: 0 })
        .includes(:hotel)
        .to_a
    end
  end
end
