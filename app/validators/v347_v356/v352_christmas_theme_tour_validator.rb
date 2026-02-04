# frozen_string_literal: true

module V347V356
  class V352ChristmasThemeTourValidator < BaseValidator
    self.validator_id = 352
    self.task_id = "e8870656-7eae-48ee-b90a-b7f3802d7bbf"
    self.title = "圣诞节主题游（圣诞市场+灯光秀）"
    self.description = "用户需要预订12月圣诞节主题游（圣诞市场+灯光秀）"
    self.timeout_seconds = 180

    def prepare
      # 12月圣诞节（明年12月24日）
      @travel_date = Date.today + 353.days
      @destination = "哈尔滨圣诞市场"
      @traveler_count = 2
      
      # 创建旅行社
      @agency = TravelAgency.find_by!(
        name: "哈尔滨冰雪梦幻旅行社",
        data_version: 0
      )
      
      # 创建圣诞主题景点
      @attraction = Attraction.find_by!(
        name: @destination,
        city: "哈尔滨",
        data_version: 0
      )

      # 创建圣诞主题游产品
      @tour = TourGroupProduct.find_by!(
        title: "哈尔滨圣诞节主题游",
        destination: @destination,
        data_version: 0
      )

      {
        travel_date: @travel_date.to_s,
        destination: @destination,
        traveler_count: @traveler_count,
        tour_title: @tour.title,
        task_info: "圣诞节主题游预订（圣诞市场+灯光秀）"
      }
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、查询#{@travel_date}的#{@destination}圣诞主题游产品、创建预订"
    end

    def verify
      add_assertion "创建了圣诞节主题游预订", weight: 30 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何圣诞主题游预订"
        
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

      add_assertion "出发日期正确（圣诞节：#{@travel_date}）", weight: 20 do
        @tour_bookings.each do |booking|
          actual_date = booking.departure_date.to_date
          expect(actual_date).to eq(@travel_date),
            "出发日期错误。期望: #{@travel_date}（圣诞节），实际: #{actual_date}"
        end
      end

      add_assertion "人数正确（#{@traveler_count}人）", weight: 15 do
        @tour_bookings.each do |booking|
          expect(booking.traveler_count).to eq(@traveler_count),
            "人数错误。期望: #{@traveler_count}人, 实际: #{booking.traveler_count}人"
        end
      end

      add_assertion "包含圣诞节或主题游特色标签", weight: 20 do
        @tour_bookings.each do |booking|
          tags = booking.tour_group_product.tags || ""
          highlights = booking.tour_group_product.highlights || ""
          expect(tags.include?("圣诞") || highlights.include?("灯光秀") || highlights.include?("圣诞市场")).to be true,
            "缺少圣诞节或主题游特色标签"
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
