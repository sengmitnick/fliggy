# frozen_string_literal: true

module V371V375
  # V373: 预订毕业旅行（学生团8人+经济实惠）
  class V373BookGraduationTripValidator < BaseValidator
    self.validator_id = 373
    self.task_id = 'c3d4e5f6-a7b8-4c9d-0e1f-2a3b4c5d6e7f'
    self.timeout_seconds = 180
    self.title = '预订毕业旅行（学生团8人+经济实惠）'
    self.description = '用户需要为学生团预订经济实惠的毕业旅行，8名学生，预算有限，追求性价比'

    def prepare
      @destination = Destination.find_by!(
        name: '西安',
        data_version: 0
      )

      # 查找经济型酒店
      @hotel = Hotel.find_by!(
        name: '西安钟楼青年旅舍',
        destination: @destination.name,
        address: '钟楼附近',
        star_rating: '经济型',
        price: 120,
        description: '干净整洁，交通便利，适合学生',
        data_version: 0
      )

      @room = HotelRoom.find_by!(
        hotel: @hotel,
        room_type: '四人间',
        price: 120,
        data_version: 0
      )

      # 跟团游产品
      @tour_product = TourGroupProduct.find_by!(
        name: '西安古都文化5日游（学生特惠）',
        destination: @destination.name,
        duration: 5,
        price: 1280,
        description: '含兵马俑、华清池、大雁塔等景点门票，学生价',
        data_version: 0
      )

      @travel_date = Date.today + 15.days
      @group_size = 8

      # 创建8名学生
      @students = []
      (1..8).each do |i|
        @students << Passenger.find_by!(
          name: "同学#{i}",
          id_number: "6101#{(20000101 + i * 10).to_s.rjust(10, '0')}",
          phone: "137#{(10000000 + i).to_s.rjust(8, '0')}",
          data_version: 0
        )
      end

      {
        title: title,
        description: description,
        destination: @destination.name,
        hotel: @hotel.name,
        tour_product: @tour_product.name,
        travel_date: @travel_date.to_s,
        duration: 5,
        group_size: @group_size,
        price_per_person: 1280,
        total_budget: "约10240元（人均1280元）"
      }
    end

    def verify
      add_assertion "创建了跟团游订单", weight: 30 do
        all_orders = TourGroupBooking
          .joins(:product)
          .includes(:product)
          .where(tour_group_products: { name: @tour_product.name })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @tour_bookings = all_orders.select { |b| b.departure_date == @travel_date }
        
        expect(@tour_bookings).not_to be_empty, "未找到跟团游订单"
        expect(@tour_bookings.size).to be >= 1, "订单数量不足"
      end

      return if @tour_bookings.nil? || @tour_bookings.empty?

      add_assertion "跟团游产品正确（#{@tour_product.name}）", weight: 15 do
        @tour_bookings.each do |booking|
          expect(booking.product.name).to eq(@tour_product.name),
            "产品错误。期望: #{@tour_product.name}，实际: #{booking.product.name}"
        end
      end

      add_assertion "出发日期正确（#{@travel_date}）", weight: 10 do
        @tour_bookings.each do |booking|
          expect(booking.departure_date).to eq(@travel_date),
            "出发日期错误。期望: #{@travel_date}，实际: #{booking.departure_date}"
        end
      end

      add_assertion "游客数量正确（8人）", weight: 15 do
        total_travelers = @tour_bookings.sum(&:traveler_count)
        expect(total_travelers).to be >= 8,
          "游客数量不足。期望至少8人，实际: #{total_travelers}人"
      end

      add_assertion "行程天数为5天", weight: 10 do
        expect(@tour_product.duration).to eq(5),
          "行程天数错误。期望: 5天，实际: #{@tour_product.duration}天"
      end

      add_assertion "价格经济实惠（人均≤1500元）", weight: 20 do
        @tour_bookings.each do |booking|
          per_person_price = booking.total_price.to_f / booking.traveler_count
          expect(per_person_price).to be <= 1500,
            "人均价格过高。期望≤1500元，实际: #{per_person_price.round(2)}元"
        end
      end
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询经济实惠的西安跟团游、预订8人学生团、创建订单"
    end

    def execution_state_data
      {
        destination_name: @destination&.name,
        hotel_name: @hotel&.name,
        tour_product_name: @tour_product&.name,
        travel_date: @travel_date&.to_s,
        group_size: @group_size
      }
    end

    def restore_from_state(state)
      @destination = Destination.find_by(name: state['destination_name'], data_version: 0) if state['destination_name']
      @hotel = Hotel.find_by(name: state['hotel_name'], data_version: 0) if state['hotel_name']
      @tour_product = TourGroupProduct.find_by(name: state['tour_product_name'], data_version: 0) if state['tour_product_name']
      @travel_date = Date.parse(state['travel_date']) if state['travel_date']
      @group_size = state['group_size']
    end
  end
end
