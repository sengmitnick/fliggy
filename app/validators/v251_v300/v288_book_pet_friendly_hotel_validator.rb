# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例288: 预订宠物友好酒店
#
# 任务描述:
#   用户预订宠物友好酒店+宠物托运服务
#
# 评分标准:
#   - 创建酒店预订 (35%)
#   - 创建宠物托运服务 (30%)
#   - 入住日期正确 (20%)
#   - 订单状态正确 (15%)
module V251V300
  class V288BookPetFriendlyHotelValidator < BaseValidator
    self.validator_id = 'v288_book_pet_friendly_hotel_validator'
    self.task_id = 'c98da49b-44d4-45bb-848a-ddedf749cf01'
    self.title = '预订宠物友好酒店（4天后入住）'
    self.description = '用户预订宠物友好酒店+宠物托运服务'
    self.timeout_seconds = 300
    
    def prepare
      @city = '杭州'
      @check_in_date = Date.current + 4.days
      @check_out_date = @check_in_date + 3.days
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 2000
        user.update!(balance: 3000)
      end
      
      {
        task: "请预订#{@city}的宠物友好酒店，我要带宠物狗一起旅行，#{@check_in_date.strftime('%Y年%-m月%-d日')}入住，住#{(@check_out_date - @check_in_date).to_i}晚，需要宠物托运服务",
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        hint: "选择允许携带宠物的酒店，并预订宠物托运服务"
      }
    end
    
    def verify
      add_assertion "创建了酒店预订", weight: 35 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店预订"
      end
      
      add_assertion "创建了宠物托运服务", weight: 30 do
        @car_order = CarOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        # 使用用车订单模拟宠物托运服务
        expect(@car_order).not_to be_nil, "未找到宠物托运服务"
      end
      
      return unless @hotel_booking
      
      add_assertion "入住日期正确", weight: 20 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "订单状态正确", weight: 15 do
        valid_statuses = ['pending', 'paid']
        expect(valid_statuses).to include(@hotel_booking.status),
          "酒店订单状态错误: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 预订宠物友好酒店
      hotel = Hotel.where(city: @city, data_version: 0).first!
      
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 2,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name || '张三',
        guest_phone: user.phone || '13800138000',
        payment_method: '花呗',
        total_price: hotel.price * (@check_out_date - @check_in_date).to_i,
        status: 'pending',
        data_version: @data_version
      )
      
      # 2. 预订宠物托运服务（使用CarOrder模拟）
      car = Car.where(data_version: 0).first!
      CarOrder.create!(
        user_id: user.id,
        car_id: car.id,
        driver_name: user.name || '张三',
        driver_id_number: '440300199001011234',
        contact_phone: user.phone || '13800138000',
        pickup_datetime: @check_in_date,
        return_datetime: @check_in_date + 1.day,
        pickup_location: "#{@city}宠物托运站",
        status: 'pending',
        total_price: 200,
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
    end
  end
end
