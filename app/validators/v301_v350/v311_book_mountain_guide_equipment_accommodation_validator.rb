# frozen_string_literal: true

require_relative '../base_validator'

# V311: 预订登山向导+装备租赁+山顶住宿
#
# 任务描述:
#   用户需要预订登山服务套餐，包含专业向导、装备租赁和山顶住宿
#
# 评分标准:
#   - 创建了深度旅行订单（登山向导）(35%)
#   - 创建了酒店订单（山顶住宿）(30%)
#   - 创建了装备租赁订单（租车模拟）(20%)
#   - 订单状态和价格有效 (15%)
module V301V350
  class V311BookMountainGuideEquipmentAccommodationValidator < BaseValidator
    self.validator_id = 'v311_book_mountain_guide_equipment_accommodation_validator'
    self.task_id = 'f311a001-0001-4001-8001-000000000311'
    self.title = '预订登山向导+装备租赁+山顶住宿'
    self.description = '用户需要预订登山服务套餐，包含专业向导、装备租赁和山顶住宿'
    self.timeout_seconds = 300
    
    def prepare
      @travel_date = Date.current + 6.days
      @participant_count = 2
      @nights = 1
      
      # 查找山区景点
      @attraction = Attraction
        .where("name LIKE ? OR name LIKE ?", '%山%', '%峰%')
        .where(data_version: 0)
        .first
      
      @attraction ||= Attraction.where(data_version: 0).first
      raise "未找到山区景点" unless @attraction
      
      # 查找深度旅行产品（登山向导）
      @deep_travel_product = DeepTravelProduct
        .joins(:deep_travel_guide)
        .where(data_version: 0)
        .first
      
      raise "未找到深度旅行产品" unless @deep_travel_product
      
      @guide = @deep_travel_product.deep_travel_guide
      
      # 查找酒店（山顶住宿）
      @hotel = Hotel.where(data_version: 0).order(Arel.sql('RANDOM()')).first
      raise "未找到可用酒店" unless @hotel
      
      @hotel_room = @hotel.hotel_rooms.where(data_version: 0).first
      raise "未找到#{@hotel.name}的可用房间" unless @hotel_room
      
      # 查找装备租赁（租车模拟）
      @car = Car.where(data_version: 0).first
      raise "未找到可用车辆（装备租赁）" unless @car
      
      {
        task: "请预订#{@attraction.name}登山服务（#{@travel_date.strftime('%Y年%m月%d日')}出发，#{@participant_count}人），包含专业向导、装备租赁和山顶住宿#{@nights}晚。",
        requirements: {
          attraction: @attraction.name,
          travel_date: @travel_date,
          participant_count: @participant_count,
          nights: @nights,
          services: ['专业向导', '装备租赁', '山顶住宿']
        },
        hint: "需要预订深度旅行（向导）、酒店住宿和装备租赁。"
      }
    end
    
    def verify
      add_assertion "创建了深度旅行订单（登山向导）", weight: 35 do
        @deep_travel_booking = DeepTravelBooking
          .where(data_version: @data_version)
          .first
        
        expect(@deep_travel_booking).not_to be_nil, "未找到深度旅行订单（登山向导）"
      end
      
      return if @deep_travel_booking.nil?
      
      add_assertion "创建了酒店订单（山顶住宿）", weight: 30 do
        @hotel_booking = HotelBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单（山顶住宿）"
      end
      
      add_assertion "创建了装备租赁订单（租车模拟）", weight: 20 do
        @car_order = CarOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@car_order).not_to be_nil, "未找到装备租赁订单"
      end
      
      add_assertion "订单状态和价格有效", weight: 15 do
        expect(@deep_travel_booking.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@deep_travel_booking.total_price).to be > 0
        
        if @hotel_booking
          expect(@hotel_booking.status).to be_in(['pending', 'paid', 'confirmed'])
          expect(@hotel_booking.total_price).to be > 0
        end
        
        if @car_order
          expect(@car_order.status).to be_in(['pending', 'paid', 'confirmed'])
          expect(@car_order.total_price).to be > 0
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建深度旅行订单（登山向导）
      DeepTravelBooking.create!(
        user: user,
        deep_travel_guide: @guide,
        deep_travel_product: @deep_travel_product,
        travel_date: @travel_date,
        adult_count: @participant_count,
        child_count: 0,
        contact_name: user.name,
        contact_phone: '13800138000',
        total_price: @deep_travel_product.price,
        insurance_price: 0,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 创建酒店订单（山顶住宿）
      check_in_date = @travel_date
      check_out_date = check_in_date + @nights
      
      HotelBooking.create!(
        user: user,
        hotel: @hotel,
        hotel_room: @hotel_room,
        check_in_date: check_in_date,
        check_out_date: check_out_date,
        rooms_count: 1,
        adults_count: @participant_count,
        children_count: 0,
        guest_name: user.name,
        guest_phone: '13800138000',
        total_price: @hotel_room.price * @nights,
        payment_method: '花呗',
        status: 'paid',
        data_version: @data_version
      )
      
      # 3. 创建装备租赁订单（租车模拟）
      pickup_datetime = @travel_date.to_time + 9.hours
      return_datetime = (@travel_date + @nights).to_time + 18.hours
      
      CarOrder.create!(
        user: user,
        car: @car,
        pickup_datetime: pickup_datetime,
        return_datetime: return_datetime,
        total_price: @car.price_per_day * (@nights + 1),
        pickup_location: @attraction.name,
        driver_name: user.name,
        driver_id_number: '310101198001011234',
        contact_phone: '13800138000',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        travel_date: @travel_date.to_s,
        participant_count: @participant_count,
        nights: @nights,
        attraction_id: @attraction&.id,
        deep_travel_product_id: @deep_travel_product&.id,
        guide_id: @guide&.id,
        hotel_id: @hotel&.id,
        hotel_room_id: @hotel_room&.id,
        car_id: @car&.id
      }
    end
    
    def restore_from_state(data)
      @travel_date = Date.parse(data['travel_date'])
      @participant_count = data['participant_count']
      @nights = data['nights']
      
      @attraction = Attraction.find(data['attraction_id']) if data['attraction_id']
      @deep_travel_product = DeepTravelProduct.find(data['deep_travel_product_id']) if data['deep_travel_product_id']
      @guide = DeepTravelGuide.find(data['guide_id']) if data['guide_id']
      @hotel = Hotel.find(data['hotel_id']) if data['hotel_id']
      @hotel_room = HotelRoom.find(data['hotel_room_id']) if data['hotel_room_id']
      @car = Car.find(data['car_id']) if data['car_id']
    end
  end
end
