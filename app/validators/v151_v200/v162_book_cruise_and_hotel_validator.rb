# frozen_string_literal: true

require_relative '../base_validator'

# V162: 预订上海邮轮 + 酒店住宿
# 验证用户能够完成邮轮预订+邮轮前一晚酒店住宿的组合下单

module V151V200
  class V162BookCruiseAndHotelValidator < BaseValidator
    self.validator_id = 'v162_book_cruise_and_hotel_validator'
    self.task_id = 'f2a3b4c5-6d7e-8f9a-0b1c-2d3e4f5a6b7c'
    self.title = '预订邮轮并预订酒店住宿（上海日本航线+前一晚住宿）'
    self.description = '预订后天上海出发的日本邮轮航线，并预订邮轮出发前一晚的上海酒店住宿'
    self.timeout_seconds = 300

    def prepare
      @departure_date = Date.tomorrow + 1.day  # 后天出发
      @hotel_checkin_date = Date.tomorrow      # 明天入住酒店（邮轮前一晚）
      @departure_port = '上海'
      @duration_days = 6
      @duration_nights = 5
      @adult_count = 2
      
      # 查找可用的上海邮轮班次
      @available_sailings = CruiseSailing
        .where("departure_port LIKE ?", "%#{@departure_port}%")
        .where(duration_days: @duration_days, duration_nights: @duration_nights, data_version: 0)
        .where("departure_date >= ?", @departure_date)
        .to_a
      
      expect(@available_sailings).not_to be_empty, "数据包缺少上海出发的邮轮班次"
      
      # 查找可用的上海酒店
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@departure_port}%")
        .where(data_version: 0)
        .to_a
      
      expect(@available_hotels).not_to be_empty, "数据包缺少上海酒店"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建邮轮订单
      sailing = @available_sailings.first
      ship = sailing.cruise_ship
      
      cabin_type = CabinType.where(data_version: 0, cruise_ship_id: ship.id, category: 'interior').first
      raise "未找到舱房类型" unless cabin_type
      
      cruise_product = CruiseProduct.find_or_create_by!(
        cruise_sailing_id: sailing.id,
        cabin_type_id: cabin_type.id,
        data_version: 0
      ) do |product|
        product.merchant_name = '邮轮旅游网'
        product.price_per_person = 3500.0
        product.occupancy_requirement = 2
        product.stock = 10
        product.sales_count = 0
        product.is_refundable = true
        product.requires_confirmation = false
        product.status = 'on_sale'
      end
      
      total_price = cruise_product.price_per_person * @adult_count
      
      CruiseOrder.create!(
        user_id: user.id,
        cruise_product_id: cruise_product.id,
        quantity: @adult_count,
        contact_name: user.name,
        contact_phone: '13800138000',
        total_price: total_price,
        accept_terms: true,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建酒店订单（邮轮前一晚）
      hotel = @available_hotels.first
      room = hotel.rooms.where(data_version: 0).order(:price).first
      
      # 如果没有房型，创建一个
      unless room
        room = Room.create!(
          hotel_id: hotel.id,
          name: '标准双人间',
          size: 25.0,
          bed_type: 'double',
          price: 400.0,
          original_price: 500.0,
          amenities: ['免费WiFi', '空调', '热水'].to_json,
          breakfast_included: true,
          cancellation_policy: '免费取消',
          data_version: 0
        )
      end
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @hotel_checkin_date,
        check_out_date: @hotel_checkin_date + 1.day,
        guest_name: user.name,
        guest_phone: '13800138000',
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        departure_date: @departure_date.to_s,
        hotel_checkin_date: @hotel_checkin_date.to_s,
        departure_port: @departure_port,
        duration_days: @duration_days,
        duration_nights: @duration_nights,
        adult_count: @adult_count
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @departure_date = Date.parse(data['departure_date']) if data['departure_date']
      @hotel_checkin_date = Date.parse(data['hotel_checkin_date']) if data['hotel_checkin_date']
      @departure_port = data['departure_port']
      @duration_days = data['duration_days']
      @duration_nights = data['duration_nights']
      @adult_count = data['adult_count']
    end

    def verify
      # 断言1: 创建了邮轮订单
      add_assertion "创建了邮轮订单", weight: 25 do
        @cruise_order = CruiseOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@cruise_order).not_to be_nil, "未找到任何邮轮订单"
      end
      
      return if @cruise_order.nil?
      
      # 断言2: 出发港正确
      add_assertion "出发港正确（#{@departure_port}）", weight: 10 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expect(sailing.departure_port).to include(@departure_port),
          "出发港错误。期望包含: #{@departure_port}, 实际: #{sailing.departure_port}"
      end
      
      # 断言3: 创建了酒店订单
      add_assertion "创建了酒店订单", weight: 30 do
        @hotel_booking = HotelBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到任何酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      # 断言4: 酒店城市正确
      add_assertion "酒店城市正确（#{@departure_port}）", weight: 15 do
        expect(@hotel_booking.hotel.city).to include(@departure_port),
          "酒店城市错误。期望: #{@departure_port}, 实际: #{@hotel_booking.hotel.city}"
      end
      
      # 断言5: 入住日期正确（邮轮前一晚）
      add_assertion "入住日期正确（邮轮前一晚）", weight: 20 do
        expect(@hotel_booking.check_in_date).to eq(@hotel_checkin_date),
          "入住日期错误。期望: #{@hotel_checkin_date}（邮轮前一晚）, 实际: #{@hotel_booking.check_in_date}"
      end
    end
  end
end
