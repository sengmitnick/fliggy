# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例295: 预订穆斯林友好服务
#
# 任务描述:
#   用户预订穆斯林友好服务（清真餐+礼拜室）
#
# 任务描述:
#   用户预订穆斯林友好服务（清真餐+礼拜室）
#
# 评分标准:
#   - 创建跟团游预订 (40%)
#   - 创建酒店预订 (35%)
#   - 出行日期正确 (15%)
#   - 订单状态正确 (10%)
module V251V300
  class V295BookMuslimFriendlyServiceValidator < BaseValidator
    self.validator_id = 'v295_book_muslim_friendly_service_validator'
    self.task_id = '16fd7e2d-f8e9-49c8-91fc-72958aa2ec90'
    self.title = '预订穆斯林友好服务'
    self.description = '用户预订穆斯林友好服务（清真餐+礼拜室）'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '西安'
      @travel_date = Date.current + 6.days
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 3000
        user.update!(balance: 5000)
      end
      
      {
        task: "请预订#{@destination}穆斯林友好旅游套餐，#{@travel_date.strftime('%Y年%-m月%-d日')}出发，需要清真餐饮和配备礼拜室的酒店",
        destination: @destination,
        travel_date: @travel_date.to_s,
        hint: "选择提供清真餐的跟团游和穆斯林友好酒店"
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
        adult_count: 2,
        child_count: 0,
        contact_name: user.name || '阿里',
        contact_phone: user.phone || '13800138000',
        insurance_type: 'none',
        total_price: tour_package.price * 2,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 2. 预订穆斯林友好酒店
      hotel = Hotel.where(data_version: 0).order(rating: :desc).first!
      
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 2,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @travel_date,
        check_out_date: @travel_date + 3.days,
        guest_name: user.name || '阿里',
        guest_phone: user.phone || '13800138000',
        payment_method: '花呗',
        total_price: hotel.price * 3,
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
