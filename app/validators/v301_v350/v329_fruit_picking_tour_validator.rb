# frozen_string_literal: true

module V301V350
  class V329FruitPickingTourValidator < BaseValidator
    self.validator_id = 329
    self.task_id = "d4cd4dc4-0331-4d7d-a3f1-e7f33490e168"
    self.title = "水果采摘季体验游"
    self.description = "用户需要预订7月草莓采摘季的亲子采摘游"
    self.timeout_seconds = 180

    def prepare
      # 7月水果采摘季（明年7月10日）
      @travel_date = Date.today + 185.days
      @destination = "昌平草莓采摘园"
      @traveler_count = 4  # 亲子游通常2大2小
      
      # 创建旅行社
      @agency = TravelAgency.find_by!(
        name: "北京亲子体验旅行社",
        data_version: 0
      )
      
      # 创建采摘园景点
      @attraction = Attraction.find_by!(
        name: @destination,
        city: "北京",
        data_version: 0
      )

      # 创建采摘体验产品
      @tour = TourGroupProduct.find_by!(
        title: "昌平草莓采摘亲子体验游",
        destination: @destination,
        data_version: 0
      )

      {
        travel_date: @travel_date.to_s,
        destination: @destination,
        traveler_count: @traveler_count,
        tour_title: @tour.title,
        task_info: "7月水果采摘季亲子体验游预订"
      }
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、查询#{@travel_date}的#{@destination}采摘游产品、创建预订"
    end

    def verify
      add_assertion "创建了水果采摘游预订", weight: 30 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何采摘游预订"
        
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

      add_assertion "出发日期正确（7月采摘季：#{@travel_date}）", weight: 20 do
        @tour_bookings.each do |booking|
          actual_date = booking.departure_date.to_date
          expect(actual_date).to eq(@travel_date),
            "出发日期错误。期望: #{@travel_date}（7月采摘季），实际: #{actual_date}"
        end
      end

      add_assertion "人数正确（#{@traveler_count}人亲子游）", weight: 15 do
        @tour_bookings.each do |booking|
          expect(booking.traveler_count).to eq(@traveler_count),
            "人数错误。期望: #{@traveler_count}人（亲子游），实际: #{booking.traveler_count}人"
        end
      end

      add_assertion "包含水果采摘或亲子游特色标签", weight: 20 do
        @tour_bookings.each do |booking|
          tags = booking.tour_group_product.tags || ""
          category = booking.tour_group_product.tour_category || ""
          expect(tags.include?("采摘") || tags.include?("水果") || category.include?("亲子")).to be true,
            "缺少水果采摘或亲子游特色标签"
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
