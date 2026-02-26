# frozen_string_literal: true

require_relative '../base_validator'

# V239: 预订宠物友好酒店
#
# 任务描述:
#   用户需要预订允许携带宠物的酒店
#
# 评分标准:
#   - 创建了酒店订单 (30%)
#   - 酒店允许携带宠物 (40%)
#   - 入住日期和时长正确 (20%)
#   - 订单状态有效 (10%)
module V201V250
  class V239BookPetFriendlyHotelValidator < BaseValidator
    self.validator_id = 'v239_book_pet_friendly_hotel_validator'
    self.task_id = '5ff516ff-6f6f-6f8f-8f9f-7f0a1b2c3d4f'
    self.title = '帮张三订后天在成都的酒店，要允许携带宠物的，住2晚'
    self.description = '帮张三订后天在成都的酒店，要允许携带宠物的，住2晚'
    self.timeout_seconds = 300
    
    def prepare
      @city = '成都'
      @check_in_date = Date.current + 2.days
      @check_out_date = @check_in_date + 2.days
      
      # 查询demo_user乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = demo_user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_guest_phone = @zhangsan.phone
      
      # 查找宠物友好酒店（facilities包含"宠物"或"pet"）
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("facilities LIKE ? OR facilities LIKE ?", 
               "%宠物%", "%pet%")
        .to_a
      
      raise "未找到宠物友好酒店" if @available_hotels.empty?
      
      {
        task: "请预订#{@check_in_date.strftime('%Y年%m月%d日')}（后天）在#{@city}允许携带宠物的酒店，住2晚。",
        requirements: {
          city: @city,
          pet_friendly: '必须允许携带宠物',
          check_in_date: @check_in_date,
          nights: 2,
          purpose: '携带宠物'
        },
        hint: "选择允许携带宠物的酒店。"
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
      
      add_assertion "酒店允许携带宠物", weight: 40 do
        hotel = @hotel_booking.hotel
        is_pet_friendly = hotel.facilities&.include?('宠物') ||
                          hotel.facilities&.downcase&.include?('pet')
        
        expect(is_pet_friendly).to eq(true),
          "酒店不允许携带宠物。酒店: #{hotel.name}, 设施: #{hotel.facilities}"
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
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 选择第一家宠物友好酒店
      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).first
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: zhangsan.name,
        guest_phone: zhangsan.phone,
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
        check_out_date: @check_out_date.to_s,
        expected_guest_phone: @expected_guest_phone
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @expected_guest_phone = data['expected_guest_phone']
      
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("facilities LIKE ? OR facilities LIKE ?", 
               "%宠物%", "%pet%")
        .to_a
    end
  end
end
