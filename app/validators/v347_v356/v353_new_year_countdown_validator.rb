# frozen_string_literal: true

module V347V356
  class V353NewYearCountdownValidator < BaseValidator
    self.validator_id = 353
    self.task_id = "899e2fa6-b1ce-48a0-9632-975effe07027"
    self.title = "跨年倒数活动预订（烟火+派对）"
    self.description = "用户需要预订12月31日跨年晚会+烟火秀+派对"
    self.timeout_seconds = 180

    def prepare
      # 跨年倒数（明年12月31日）
      @travel_date = Date.today + 360.days
      @destination = "上海外滩跨年倒数"
      @traveler_count = 3
      
      # 创建旅行社
      @agency = TravelAgency.find_by!(
        name: "上海都市旅行社",
        data_version: 0
      )
      
      # 创建跨年活动景点
      @attraction = Attraction.find_by!(
        name: @destination,
        city: "上海",
        data_version: 0
      )

      # 创建跨年活动产品
      @tour = TourGroupProduct.find_by!(
        title: "上海外滩跨年倒数狂欢夜",
        destination: @destination,
        data_version: 0
      )

      {
        travel_date: @travel_date.to_s,
        destination: @destination,
        traveler_count: @traveler_count,
        tour_title: @tour.title,
        task_info: "跨年倒数活动预订（烟火秀+派对）"
      }
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、查询#{@travel_date}的#{@destination}跨年活动产品、创建预订"
    end

    def verify
      add_assertion "创建了跨年倒数活动预订", weight: 30 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何跨年活动预订"
        
        @tour_bookings = all_bookings.select { |b|
          b.departure_date.to_date == @travel_date
        }
        
        expect(@tour_bookings.size).to be >= 1, "未找到符合条件的预订"
      end

      return if @tour_bookings.nil? || @tour_bookings.empty?

      add_assertion "目的地正确（#{@destination}）", weight: 15 do
        @tour_bookings.each do |booking|
          expect(booking.tour_group_product.destination).to eq(@destination),
            "目的地错误。期望: #{@destination}, 实际: #{booking.tour_group_product.destination}"
        end
      end

      add_assertion "活动日期正确（跨年夜：#{@travel_date}）", weight: 20 do
        @tour_bookings.each do |booking|
          actual_date = booking.departure_date.to_date
          expect(actual_date).to eq(@travel_date),
            "活动日期错误。期望: #{@travel_date}（12月31日跨年夜），实际: #{actual_date}"
        end
      end

      add_assertion "人数正确（#{@traveler_count}人）", weight: 15 do
        @tour_bookings.each do |booking|
          expect(booking.traveler_count).to eq(@traveler_count),
            "人数错误。期望: #{@traveler_count}人, 实际: #{booking.traveler_count}人"
        end
      end

      add_assertion "包含跨年或烟火派对特色标签", weight: 20 do
        @tour_bookings.each do |booking|
          tags = booking.tour_group_product.tags || ""
          highlights = booking.tour_group_product.highlights || ""
          expect(tags.include?("跨年") || tags.include?("烟火") || highlights.include?("倒数") || highlights.include?("派对")).to be true,
            "缺少跨年或烟火派对特色标签"
        end
      end
    end

    def execution_state_data
      {
        travel_date: @travel_date&.to_s,
        destination: @destination,
        traveler_count: @traveler_count,
        tour_id: @tour&.id,
        attraction_id: @attraction&.id
      }
    end

    def restore_from_state(state)
      @travel_date = Date.parse(state['travel_date']) if state['travel_date']
      @destination = state['destination']
      @traveler_count = state['traveler_count']
      @tour = TourGroupProduct.find_by(id: state['tour_id']) if state['tour_id']
      @attraction = Attraction.find_by(id: state['attraction_id']) if state['attraction_id']
    end
  end
end
