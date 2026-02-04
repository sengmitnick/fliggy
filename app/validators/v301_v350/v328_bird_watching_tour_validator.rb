# frozen_string_literal: true

module V301V350
  class V328BirdWatchingTourValidator < BaseValidator
    self.validator_id = 328
    self.task_id = "d496d5dd-1f67-424d-bdde-2a4d3becc9bf"
    self.title = "观鸟季专项游（候鸟迁徙季节）"
    self.description = "用户需要预订3月候鸟迁徙季的观鸟专项游"
    self.timeout_seconds = 180

    def prepare
      # 3月候鸟迁徙季（明年3月20日）
      @travel_date = Date.today + 75.days
      @destination = "鄱阳湖候鸟观测基地"
      @traveler_count = 3
      
      # 创建旅行社
      @agency = TravelAgency.find_by!(
        name: "江西鄱阳湖生态旅行社",
        data_version: 0
      )
      
      # 创建观鸟景点
      @attraction = Attraction.find_by!(
        name: @destination,
        city: "九江",
        data_version: 0
      )

      # 创建观鸟专项游产品
      @tour = TourGroupProduct.find_by!(
        title: "鄱阳湖候鸟迁徙观测游",
        destination: @destination,
        data_version: 0
      )

      {
        travel_date: @travel_date.to_s,
        destination: @destination,
        traveler_count: @traveler_count,
        tour_title: @tour.title,
        task_info: "3月候鸟迁徙季观鸟专项游预订"
      }
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、查询#{@travel_date}的#{@destination}观鸟游产品、创建预订"
    end

    def verify
      add_assertion "创建了候鸟观测游预订", weight: 30 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何观鸟游预订"
        
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

      add_assertion "出发日期正确（3月候鸟迁徙季：#{@travel_date}）", weight: 20 do
        @tour_bookings.each do |booking|
          actual_date = booking.departure_date.to_date
          expect(actual_date).to eq(@travel_date),
            "出发日期错误。期望: #{@travel_date}（3月迁徙季），实际: #{actual_date}"
        end
      end

      add_assertion "人数正确（#{@traveler_count}人）", weight: 15 do
        @tour_bookings.each do |booking|
          expect(booking.traveler_count).to eq(@traveler_count),
            "人数错误。期望: #{@traveler_count}人, 实际: #{booking.traveler_count}人"
        end
      end

      add_assertion "包含观鸟或生态游特色标签", weight: 20 do
        @tour_bookings.each do |booking|
          tags = booking.tour_group_product.tags || ""
          category = booking.tour_group_product.tour_category || ""
          expect(tags.include?("观鸟") || tags.include?("候鸟") || category.include?("生态")).to be true,
            "缺少观鸟或生态游特色标签"
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
