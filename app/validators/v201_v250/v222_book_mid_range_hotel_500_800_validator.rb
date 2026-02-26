# frozen_string_literal: true

require_relative '../base_validator'

# V222: 预订中档酒店（500-800元/晚）
#
# 任务描述:
#   用户需要预订酒店，价格区间500-800元/晚（中档舒适）
#
# 评分标准:
#   - 创建了酒店订单 (25%)
#   - 酒店单晚价格在500-800元区间内 (35%)
#   - 酒店位于目标城市 (15%)
#   - 入住人信息正确（姓名、手机号） (10%)
#   - 订单状态有效 (15%)
module V201V250
  class V222BookMidRangeHotel500800Validator < BaseValidator
    self.validator_id = 'v222_book_mid_range_hotel_500_800_validator'
    self.task_id = '9fe910fd-0f0f-0f2f-2f3f-1f4a5b6c7d8f'
    self.title = '张三打算2天后去杭州出差，想选一家中档舒适的酒店，预算是每晚500-800元'
    self.description = '张三打算2天后去杭州出差，想选一家中档舒适的酒店，预算是每晚500-800元'
    self.timeout_seconds = 300
    
    def prepare
      @city = '杭州'
      @check_in_date = Date.current + 2.days
      @check_out_date = @check_in_date + 1.day
      @min_price = 500
      @max_price = 800
      
      # 查询demo_user和乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      demo_passenger = Passenger.find_by!(user_id: demo_user.id, is_self: true, data_version: 0)
      @passenger = OpenStruct.new(
        name: demo_passenger.name,
        id_number: demo_passenger.id_number,
        phone: demo_passenger.phone
      )
      
      @available_hotels = Hotel.where(city: @city, data_version: 0).to_a.select do |h|
        h.price >= @min_price && h.price <= @max_price
      end
      
      raise "未找到价格在#{@min_price}-#{@max_price}元区间的酒店" if @available_hotels.empty?
      
      {
        task: "请预订#{@city}的中档舒适酒店，入住日期#{@check_in_date.strftime('%Y年%m月%d日')}（后天），价格要求500-800元/晚。",
        requirements: {
          city: @city,
          check_in_date: @check_in_date,
          price_range: '500-800元/晚',
          purpose: '中档舒适'
        },
        hint: "选择价格在500-800元区间的酒店，性价比高。"
      }
    end
    
    def verify
      add_assertion "创建了酒店订单", weight: 25 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "酒店单晚价格在500-800元区间内", weight: 35 do
        price = @hotel_booking.hotel.price
        expect(price).to be >= @min_price,
          "酒店价格过低。期望: ≥#{@min_price}元/晚, 实际: #{price}元/晚"
        expect(price).to be <= @max_price,
          "酒店价格过高。期望: ≤#{@max_price}元/晚, 实际: #{price}元/晚"
      end
      
      add_assertion "酒店位于#{@city}", weight: 15 do
        expect(@hotel_booking.hotel.city).to eq(@city),
          "酒店城市错误。期望: #{@city}, 实际: #{@hotel_booking.hotel.city}"
      end
      
      add_assertion "入住人信息正确（姓名、手机号）", weight: 10 do
        demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
        expect(@hotel_booking.guest_name).to eq(demo_user.name),
          "入住人姓名错误。期望: #{demo_user.name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@passenger.phone),
          "入住人电话错误。期望: #{@passenger.phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "订单状态有效", weight: 15 do
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择价格区间内评分最高的酒店
      hotel = @available_hotels.max_by(&:rating)
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
        total_price: hotel.price,
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
        min_price: @min_price,
        max_price: @max_price,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        passenger_phone: @passenger.phone
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @min_price = data['min_price']
      @max_price = data['max_price']
      
      # Restore passenger data from flattened fields
      @passenger = OpenStruct.new(
        name: data['passenger_name'],
        id_number: data['passenger_id_number'],
        phone: data['passenger_phone']
      )
      
      @available_hotels = Hotel.where(city: @city, data_version: 0).to_a.select do |h|
        h.price >= @min_price && h.price <= @max_price
      end
    end
  end
end
