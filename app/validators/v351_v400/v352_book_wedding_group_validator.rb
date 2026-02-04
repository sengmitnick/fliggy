# frozen_string_literal: true

module V351V400
  # V372: 预订婚礼团（新人+亲友10人+婚纱摄影）
  class V352BookWeddingGroupValidator < BaseValidator
    self.validator_id = 352
    self.task_id = 'b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e'
    self.timeout_seconds = 180
    self.title = '预订婚礼团（新人+亲友10人+婚纱摄影）'
    self.description = '用户需要预订婚礼旅行，包含新人和10位亲友共12人的行程，以及婚纱摄影服务'

    def prepare
      @destination = Destination.find_by!(
        name: '三亚',
        data_version: 0
      )

      @hotel = Hotel.find_by!(
        name: '三亚亚龙湾瑞吉度假酒店',
        city: @destination.name,
        address: '亚龙湾',
        star_level: '五星级',
        price: 1680,
        data_version: 0
      )

      @room = HotelRoom.find_by!(
        hotel: @hotel,
        room_type: '海景套房',
        price: 1680,
        data_version: 0
      )

      @photo_service = DeepTravelProduct.find_by!(
        name: '三亚海滩婚纱摄影套餐',
        city: @destination.name,
        product_type: '婚纱摄影',
        price: 3800,
        includes_equipment: true,
        description: '含摄影师、化妆师、婚纱礼服',
        data_version: 0
      )

      @travel_date = Date.today + 30.days
      @duration = 3
      @group_size = 12

      # 创建12名成员（新人+亲友）
      @travelers = []
      [
        { name: '新郎', age: 28, role: 'groom' },
        { name: '新娘', age: 26, role: 'bride' },
        { name: '伴郎1', age: 28, role: 'groomsman' },
        { name: '伴娘1', age: 25, role: 'bridesmaid' },
        { name: '父亲（新郎）', age: 55, role: 'family' },
        { name: '母亲（新郎）', age: 53, role: 'family' },
        { name: '父亲（新娘）', age: 57, role: 'family' },
        { name: '母亲（新娘）', age: 54, role: 'family' },
        { name: '亲友1', age: 30, role: 'friend' },
        { name: '亲友2', age: 29, role: 'friend' },
        { name: '亲友3', age: 27, role: 'friend' },
        { name: '亲友4', age: 26, role: 'friend' }
      ].each_with_index do |traveler_info, idx|
        @travelers << Passenger.find_by!(
          name: traveler_info[:name],
          id_number: "4601#{(19900101 + idx * 100).to_s.rjust(10, '0')}",
          phone: "139#{(10000000 + idx).to_s.rjust(8, '0')}",
          data_version: 0
        )
      end

      {
        title: title,
        description: description,
        destination: @destination.name,
        hotel: @hotel.name,
        travel_date: @travel_date.to_s,
        duration: @duration,
        group_size: @group_size,
        photo_service: @photo_service.name,
        total_budget: "约30000元（住宿20000元 + 摄影3800元 + 其他）"
      }
    end

    def verify
      add_assertion "创建了至少6个酒店订单（12人住宿）", weight: 25 do
        all_orders = HotelBooking
          .joins(:hotel)
          .includes(:room, :hotel)
          .where(hotels: { name: @hotel.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @hotel_bookings = all_orders.select do |b|
          b.check_in_date >= @travel_date && b.check_in_date <= @travel_date + 1.day
        end
        
        expect(@hotel_bookings).not_to be_empty, "未找到任何酒店订单"
        expect(@hotel_bookings.size).to be >= 6, "订单数量不足。期望至少6个订单（12人），实际找到#{@hotel_bookings.size}个订单"
      end

      return if @hotel_bookings.nil? || @hotel_bookings.empty?

      add_assertion "酒店正确（#{@hotel.name}）", weight: 15 do
        @hotel_bookings.each do |booking|
          expect(booking.hotel.name).to eq(@hotel.name),
            "酒店错误。期望: #{@hotel.name}，实际: #{booking.hotel.name}"
        end
      end

      add_assertion "酒店星级为五星级", weight: 10 do
        expect(@hotel.star_level).to eq('五星级'),
          "酒店星级错误。期望: 五星级，实际: #{@hotel.star_level}"
      end

      add_assertion "住宿天数正确（3天2晚）", weight: 10 do
        @hotel_bookings.each do |booking|
          nights = (booking.check_out_date - booking.check_in_date).to_i
          expect(nights).to be >= 2, "住宿天数不足。期望至少2晚，实际: #{nights}晚"
        end
      end

      add_assertion "创建了婚纱摄影服务订单", weight: 30 do
        all_photo_orders = DeepTravelBooking
          .joins(:product)
          .includes(:product)
          .where(deep_travel_products: { name: @photo_service.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @photo_bookings = all_photo_orders
        
        expect(@photo_bookings).not_to be_empty, "未找到婚纱摄影服务订单"
        expect(@photo_bookings.size).to be >= 1, "摄影服务订单数量不足"
      end

      add_assertion "摄影服务类型正确", weight: 10 do
        return if @photo_bookings.nil? || @photo_bookings.empty?
        
        @photo_bookings.each do |booking|
          expect(booking.product.product_type).to eq('婚纱摄影'),
            "服务类型错误。期望: 婚纱摄影，实际: #{booking.product.product_type}"
        end
      end
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询三亚婚礼酒店、预订12人婚礼团套餐、预订婚纱摄影服务、创建订单"
    end

    def execution_state_data
      {
        destination_name: @destination&.name,
        hotel_name: @hotel&.name,
        travel_date: @travel_date&.to_s,
        duration: @duration,
        group_size: @group_size,
        photo_service_name: @photo_service&.name
      }
    end

    def restore_from_state(state)
      @destination = Destination.find_by(name: state['destination_name'], data_version: 0) if state['destination_name']
      @hotel = Hotel.find_by(name: state['hotel_name'], data_version: 0) if state['hotel_name']
      @travel_date = Date.parse(state['travel_date']) if state['travel_date']
      @duration = state['duration']
      @group_size = state['group_size']
      @photo_service = DeepTravelProduct.find_by(name: state['photo_service_name'], data_version: 0) if state['photo_service_name']
    end
  end
end
