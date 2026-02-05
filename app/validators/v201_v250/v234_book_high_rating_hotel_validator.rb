# frozen_string_literal: true

require_relative '../base_validator'

# V234: 预订高评分酒店（评分≥4.5星）
#
# 任务描述:
#   用户需要预订高评分酒店（评分≥4.5星）
#
# 评分标准:
#   - 创建了酒店订单 (30%)
#   - 酒店评分≥4.5星 (40%)
#   - 入住日期和时长正确 (20%)
#   - 订单状态有效 (10%)
module V201V250
  class V234BookHighRatingHotelValidator < BaseValidator
    self.validator_id = 'v234_book_high_rating_hotel_validator'
    self.task_id = '0ff0c1ff-1f1f-1f3f-3f4f-2f5a6b7c8d9f'
    self.title = '预订高评分酒店（≥4.5星）'
    self.description = '用户需要预订高评分酒店（评分≥4.5星）'
    self.timeout_seconds = 300
    
    def prepare
      @city = '杭州'
      @min_rating = 4.5
      @check_in_date = Date.current + 3.days
      @check_out_date = @check_in_date + 1.day
      
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("rating >= ?", @min_rating)
        .order(rating: :desc)
        .to_a
      
      raise "未找到评分≥#{@min_rating}星的酒店" if @available_hotels.empty?
      
      {
        task: "请预订#{@check_in_date.strftime('%Y年%m月%d日')}（3天后）在#{@city}的高评分酒店（评分≥#{@min_rating}星），住1晚。",
        requirements: {
          city: @city,
          min_rating: "≥#{@min_rating}星",
          check_in_date: @check_in_date,
          nights: 1,
          purpose: '追求品质'
        },
        hint: "选择评分≥#{@min_rating}星的酒店。"
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
      
      add_assertion "酒店评分≥#{@min_rating}星", weight: 40 do
        hotel = @hotel_booking.hotel
        expect(hotel.rating).to be >= @min_rating,
          "酒店评分不符合要求。要求: ≥#{@min_rating}星, 实际: #{hotel.rating}星（#{hotel.name}）"
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
      
      # 选择评分最高的酒店
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
        min_rating: @min_rating,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @min_rating = data['min_rating']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("rating >= ?", @min_rating)
        .order(rating: :desc)
        .to_a
    end
  end
end
