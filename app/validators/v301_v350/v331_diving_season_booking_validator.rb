# frozen_string_literal: true

module V301V350
  class V331DivingSeasonBookingValidator < BaseValidator
    self.validator_id = 331
    self.task_id = "7cecfa30-2efb-4558-8788-65309b357c4d"
    self.title = "潜水季最佳时间预订"
    self.description = "用户需要预订6月潜水最佳季节的海岛潜水行程"
    self.timeout_seconds = 180

    def prepare
      # 6月潜水最佳季节（明年6月20日）
      @travel_date = Date.today + 165.days
      @destination = "三亚蜈支洲岛潜水基地"
      @traveler_count = 2
      
      # 创建深度旅游服务商
      @agency = TravelAgency.find_by!(
        name: "三亚海洋运动旅行社",
        data_version: 0
      )
      
      # 创建潜水景点
      @attraction = Attraction.find_by!(
        name: @destination,
        city: "三亚",
        data_version: 0
      )

      # 创建潜水深度旅游产品
      @deep_product = DeepTravelProduct.find_by!(
        title: "蜈支洲岛深潜体验（6月最佳季）",
        location: @destination,
        data_version: 0
      )

      {
        travel_date: @travel_date.to_s,
        destination: @destination,
        traveler_count: @traveler_count,
        product_title: @deep_product.title,
        task_info: "6月潜水最佳季节海岛深潜预订"
      }
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、查询#{@travel_date}的#{@destination}潜水产品、创建预订"
    end

    def verify
      add_assertion "创建了潜水行程预订", weight: 30 do
        all_bookings = DeepTravelBooking
          .joins(:deep_travel_product)
          .includes(:deep_travel_product)
          .where(deep_travel_products: { location: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何潜水预订"
        
        @bookings = all_bookings.select { |b|
          b.booking_date.to_date == @travel_date
        }
        
        expect(@bookings.size).to be >= 1, "未找到符合条件的预订"
      end

      return if @bookings.nil? || @bookings.empty?

      add_assertion "目的地正确（#{@destination}）", weight: 15 do
        @bookings.each do |booking|
          expect(booking.deep_travel_product.location).to eq(@destination),
            "目的地错误。期望: #{@destination}, 实际: #{booking.deep_travel_product.location}"
        end
      end

      add_assertion "预订日期正确（6月潜水最佳季：#{@travel_date}）", weight: 20 do
        @bookings.each do |booking|
          actual_date = booking.booking_date.to_date
          expect(actual_date).to eq(@travel_date),
            "预订日期错误。期望: #{@travel_date}（6月最佳季），实际: #{actual_date}"
        end
      end

      add_assertion "人数正确（#{@traveler_count}人）", weight: 15 do
        @bookings.each do |booking|
          expect(booking.traveler_count).to eq(@traveler_count),
            "人数错误。期望: #{@traveler_count}人, 实际: #{booking.traveler_count}人"
        end
      end

      add_assertion "包含潜水相关关键词", weight: 20 do
        @bookings.each do |booking|
          title = booking.deep_travel_product.title
          description = booking.deep_travel_product.description || ""
          expect(title.include?("潜水") || title.include?("深潜") || description.include?("PADI")).to be true,
            "缺少潜水相关关键词"
        end
      end
    end

    def execution_state_data
      {
        travel_date: @travel_date&.to_s,
        destination: @destination,
        traveler_count: @traveler_count,
        deep_product_id: @deep_product&.id,
        attraction_id: @attraction&.id
      }
    end

    def restore_from_state(state)
      @travel_date = Date.parse(state['travel_date']) if state['travel_date']
      @destination = state['destination']
      @traveler_count = state['traveler_count']
      @deep_product = DeepTravelProduct.find_by(id: state['deep_product_id']) if state['deep_product_id']
      @attraction = Attraction.find_by(id: state['attraction_id']) if state['attraction_id']
    end
  end
end
