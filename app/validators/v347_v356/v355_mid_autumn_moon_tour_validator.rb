# frozen_string_literal: true

module V347V356
  class V355MidAutumnMoonTourValidator < BaseValidator
    self.validator_id = 355
    self.task_id = "01149d68-e272-46ec-b4cd-0447764f4260"
    self.title = "中秋赏月主题游（月饼+赏月地）"
    self.description = "用户需要预订中秋节赏月主题游（月饼+赏月地）"
    self.timeout_seconds = 180

    def prepare
      # 中秋节（明年9月15日，农历八月十五）
      @travel_date = Date.today + 255.days
      @destination = "杭州西湖赏月地"
      @traveler_count = 4
      
      # 创建旅行社
      @agency = TravelAgency.find_by!(
        name: "杭州江南文化旅行社",
        data_version: 0
      )
      
      # 创建中秋赏月景点
      @attraction = Attraction.find_by!(
        name: @destination,
        city: "杭州",
        data_version: 0
      )

      # 创建中秋主题游产品
      @tour = TourGroupProduct.find_by!(
        title: "西湖中秋赏月主题游",
        destination: @destination,
        data_version: 0
      )

      {
        travel_date: @travel_date.to_s,
        destination: @destination,
        traveler_count: @traveler_count,
        tour_title: @tour.title,
        task_info: "中秋节赏月主题游预订（月饼+赏月地）"
      }
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、查询#{@travel_date}的#{@destination}中秋主题游产品、创建预订"
    end

    def verify
      add_assertion "创建了中秋赏月主题游预订", weight: 30 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何中秋主题游预订"
        
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

      add_assertion "出发日期正确（中秋节：#{@travel_date}）", weight: 20 do
        @tour_bookings.each do |booking|
          actual_date = booking.departure_date.to_date
          expect(actual_date).to eq(@travel_date),
            "出发日期错误。期望: #{@travel_date}（中秋节），实际: #{actual_date}"
        end
      end

      add_assertion "人数正确（#{@traveler_count}人）", weight: 15 do
        @tour_bookings.each do |booking|
          expect(booking.traveler_count).to eq(@traveler_count),
            "人数错误。期望: #{@traveler_count}人, 实际: #{booking.traveler_count}人"
        end
      end

      add_assertion "包含中秋或赏月特色标签", weight: 20 do
        @tour_bookings.each do |booking|
          tags = booking.tour_group_product.tags || ""
          highlights = booking.tour_group_product.highlights || ""
          expect(tags.include?("中秋") || tags.include?("赏月") || highlights.include?("月饼")).to be true,
            "缺少中秋或赏月特色标签"
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
