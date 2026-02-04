# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例294: 预订素食主义者服务
#
# 任务描述:
#   用户预订素食主义者专属服务（素食餐+酒店）
#
# 评分标准:
#   - 创建跟团游预订 (40%)
#   - 创建酒店预订 (35%)
#   - 出行日期正确 (15%)
#   - 订单状态正确 (10%)
module V251V300
  class V294BookVegetarianServiceValidator < BaseValidator
    self.validator_id = 'v294_book_vegetarian_service_validator'
    self.task_id = 'd91a0668-9efb-4c74-b6f2-78d678ebde69'
    self.title = '预订素食主义者服务'
    self.description = '用户预订素食主义者专属服务（素食餐+酒店）'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '峨眉山'
      @travel_date = Date.today + 8.days
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 3000
        user.update!(balance: 5000)
      end
      
      {
        task: "请预订#{@destination}素食主义者旅游套餐，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，需要素食餐饮和素食友好酒店",
        destination: @destination,
        travel_date: @travel_date.to_s,
        hint: "选择提供素食餐的跟团游和素食友好酒店"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订", weight: 40 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到跟团游预订"
      end
      
      add_assertion "创建了酒店预订", weight: 35 do
        @hotel_booking = HotelBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到酒店预订"
      end
      
      return unless @tour_booking
      
      add_assertion "出行日期正确", weight: 15 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}, 实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "订单状态正确", weight: 10 do
        valid_statuses = ['pending', 'confirmed', 'paid']
        expect(valid_statuses).to include(@tour_booking.status),
          "跟团游订单状态错误: #{@tour_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 预订跟团游
      tour_product = TourGroupProduct.where(data_version: 0).order(rating: :desc).first!
      tour_package = tour_product.tour_packages.first!
      
      TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: tour_product.id,
        tour_package_id: tour_package.id,
        travel_date: @travel_date,
        adult_count: 1,
        child_count: 0,
        contact_name: user.name || '李素食',
        contact_phone: user.phone || '13800138000',
        insurance_type: 'none',
        total_price: tour_package.price,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 2. 预订素食友好酒店
      hotel = Hotel.where(data_version: 0).order(rating: :desc).first!
      
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 1,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @travel_date,
        check_out_date: @travel_date + 2.days,
        guest_name: user.name || '李素食',
        guest_phone: user.phone || '13800138000',
        payment_method: '花呗',
        total_price: hotel.price * 2,
        status: 'pending',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date&.to_s
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
    end
  end
end
