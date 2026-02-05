# frozen_string_literal: true

require_relative '../base_validator'

# V242: 预订高评分酒店（评分≥4.5）
#
# 任务描述:
#   用户需要预订评分≥4.5分的酒店
#
# 评分标准:
#   - 创建了酒店订单 (30%)
#   - 酒店评分≥4.5分 (50%)
#   - 订单状态有效 (20%)
module V201V250
  class V242BookHighRatedHotelAbove45Validator < BaseValidator
    self.validator_id = 'v242_book_high_rated_hotel_above_4_5_validator'
    self.task_id = 'b78a026e-5d5b-4128-a9bb-f78820f0bb2c'
    self.title = '预订高评分酒店（评分≥4.5）'
    self.description = '用户需要预订评分≥4.5分的酒店'
    self.timeout_seconds = 300
    
    def prepare
      @city = '上海'
      @check_in_date = Date.current + 2.days
      @check_out_date = @check_in_date + 1.day
      @min_rating = 4.5
      
      # 查找高评分酒店
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where('rating >= ?', @min_rating)
        .order(rating: :desc, price: :asc)
      
      raise "未找到符合条件的高评分酒店" if @available_hotels.empty?
      
      {
        task: "请预订#{@check_in_date.strftime('%Y年%m月%d日')}（后天）在#{@city}的酒店（住1晚），要求酒店评分≥#{@min_rating}分，选择高评分、服务质量好的酒店。",
        requirements: {
          city: @city,
          check_in_date: @check_in_date,
          nights: 1,
          min_rating: @min_rating
        },
        hint: "优先选择评分≥#{@min_rating}分的酒店，评分越高说明服务质量越好。"
      }
    end
    
    def verify
      add_assertion "创建了酒店订单", weight: 30 do
        all_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @booking = all_bookings.first
        expect(@booking).not_to be_nil, "未找到#{@city}的酒店订单"
      end
      
      return if @booking.nil?
      
      add_assertion "酒店评分≥#{@min_rating}分", weight: 50 do
        rating = @booking.hotel.rating
        expect(rating).to be >= @min_rating,
          "酒店评分不符合要求。期望: ≥#{@min_rating}分, 实际: #{rating}分, 酒店名称: #{@booking.hotel.name}"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择评分最高且价格合理的酒店
      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room_id: room.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name,
        guest_phone: '13800138000',
        payment_method: '花呗',
        total_price: room.price,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        min_rating: @min_rating
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @min_rating = data['min_rating']
      
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where('rating >= ?', @min_rating)
        .order(rating: :desc, price: :asc)
    end
  end
end
