# frozen_string_literal: true

require_relative '../base_validator'

# V240: 预订无烟房
#
# 任务描述:
#   用户需要预订无烟房
#
# 评分标准:
#   - 创建了酒店订单 (25%)
#   - 酒店提供无烟客房设施 (40%)
#   - 入住人信息正确 (15%)
#   - 入住日期和时长正确 (15%)
#   - 订单状态有效 (5%)
module V201V250
  class V240BookNonSmokingRoomValidator < BaseValidator
    self.validator_id = 'v240_book_non_smoking_room_validator'
    self.task_id = '6ff627ff-7f7f-7f9f-9f0f-8f1a2b3c4d5f'
    self.title = '帮张三订明天在杭州的酒店，要无烟房，住1晚'
    self.description = '帮张三订明天在杭州的酒店，要无烟房，住1晚'
    self.timeout_seconds = 300
    
    def prepare
      @city = '杭州'
      @check_in_date = Date.current + 1.day
      @check_out_date = @check_in_date + 1.day
      
      # 查询demo_user乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = demo_user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_guest_phone = @zhangsan.phone
      
      # 查找有无烟客房设施的酒店
      @available_hotels = Hotel
        .where(city: @city, data_version: 0)
        .where("facilities LIKE ? OR facilities LIKE ?", "%无烟%", "%non-smoking%")
        .to_a
      
      raise "未找到提供无烟客房的酒店" if @available_hotels.empty?
      
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
      add_assertion "创建了酒店订单", weight: 25 do
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
      
      add_assertion "酒店提供无烟客房设施", weight: 40 do
        hotel = @hotel_booking.hotel
        is_non_smoking = hotel.facilities&.include?('无烟') ||
                         hotel.facilities&.downcase&.include?('non-smoking')
        
        expect(is_non_smoking).to eq(true),
          "酒店未提供无烟客房设施。设施: #{hotel.facilities}"
      end
      
      add_assertion "入住人信息正确（张三）", weight: 15 do
        expect(@hotel_booking.guest_name).to eq('张三'),
          "入住人姓名错误。期望: 张三, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_guest_phone),
          "入住人电话错误。期望: #{@expected_guest_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "入住日期和时长正确", weight: 15 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 选择第一家提供无烟客房的酒店，再选择该酒店的房间
      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first!
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room_id: room.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: zhangsan.name,
        guest_phone: zhangsan.phone,
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
        check_out_date: @check_out_date.to_s,
        expected_guest_phone: @expected_guest_phone
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @expected_guest_phone = data['expected_guest_phone']
      
      @available_hotels = Hotel
        .where(city: @city, data_version: 0)
        .where("facilities LIKE ? OR facilities LIKE ?", "%无烟%", "%non-smoking%")
        .to_a
    end
  end
end
