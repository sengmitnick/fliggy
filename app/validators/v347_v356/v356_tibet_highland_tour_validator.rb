# frozen_string_literal: true

module V347V356
  class V356TibetHighlandTourValidator < BaseValidator
    self.validator_id = 356
    self.task_id = "5759fbe5-6a43-4267-bb0a-a503a4960f15"
    self.title = "预订西藏高原游+高反预防+医疗保障"
    self.description = "用户需要预订西藏高原游+高反预防+医疗保障"
    self.timeout_seconds = 180

    def prepare
      # 西藏旅游最佳季节（明年7月20日）
      @travel_date = Date.today + 195.days
      @destination = "拉萨布达拉宫"
      @traveler_count = 2
      @duration = 7
      
      # 创建旅行社
      @agency = TravelAgency.find_by!(
        name: "西藏高原探险旅行社",
        data_version: 0
      )
      
      # 创建西藏景点
      @attraction = Attraction.find_by!(
        name: @destination,
        city: "拉萨",
        data_version: 0
      )

      # 创建西藏高原游产品
      @tour = TourGroupProduct.find_by!(
        title: "西藏拉萨7日深度游（含医疗保障）",
        destination: @destination,
        data_version: 0
      )

      # 创建高原医疗保险
      @insurance = InsuranceProduct.find_by!(
        code: "TIBET_HIGHLAND_001",
        data_version: 0
      )

      {
        travel_date: @travel_date.to_s,
        destination: @destination,
        traveler_count: @traveler_count,
        duration: @duration,
        tour_title: @tour.title,
        insurance_name: @insurance.name,
        task_info: "西藏高原游预订（含高反预防和医疗保障）"
      }
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、查询#{@travel_date}的#{@destination}高原游产品和医疗保险、创建预订"
    end

    def verify
      add_assertion "创建了西藏高原游预订", weight: 25 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何西藏高原游预订"
        
        @tour_bookings = all_bookings.select { |b|
          b.departure_date.to_date == @travel_date
        }
        
        expect(@tour_bookings.size).to be >= 1, "未找到符合条件的预订"
      end

      return if @tour_bookings.nil? || @tour_bookings.empty?

      add_assertion "目的地正确（#{@destination}）", weight: 10 do
        @tour_bookings.each do |booking|
          expect(booking.tour_group_product.destination).to eq(@destination),
            "目的地错误。期望: #{@destination}, 实际: #{booking.tour_group_product.destination}"
        end
      end

      add_assertion "出发日期正确（#{@travel_date}）", weight: 15 do
        @tour_bookings.each do |booking|
          actual_date = booking.departure_date.to_date
          expect(actual_date).to eq(@travel_date),
            "出发日期错误。期望: #{@travel_date}, 实际: #{actual_date}"
        end
      end

      add_assertion "行程天数正确（#{@duration}天）", weight: 10 do
        @tour_bookings.each do |booking|
          expect(booking.tour_group_product.duration).to eq(@duration),
            "行程天数错误。期望: #{@duration}天, 实际: #{booking.tour_group_product.duration}天"
        end
      end

      add_assertion "包含高原游或医疗保障特色", weight: 15 do
        @tour_bookings.each do |booking|
          tags = booking.tour_group_product.tags || ""
          highlights = booking.tour_group_product.highlights || ""
          category = booking.tour_group_product.tour_category || ""
          expect(
            tags.include?("高原") || tags.include?("医疗保障") ||
            highlights.include?("高反预防") || highlights.include?("医疗") ||
            category.include?("高原")
          ).to be true,
            "缺少高原游或医疗保障特色标签"
        end
      end

      add_assertion "购买了高原医疗保险", weight: 25 do
        all_insurance_orders = InsuranceOrder
          .joins(:insurance_product)
          .includes(:insurance_product)
          .where(insurance_products: { insurance_type: "高原险" })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @insurance_orders = all_insurance_orders.select { |o|
          o.start_date.to_date == @travel_date &&
          o.duration_days == @duration
        }
        
        expect(@insurance_orders.size).to be >= 1,
          "未购买高原医疗保险。期望购买#{@duration}天高原险，实际未找到"
      end
    end

    def execution_state_data
      {
        travel_date: @travel_date&.to_s,
        destination: @destination,
        traveler_count: @traveler_count,
        duration: @duration,
        tour_id: @tour&.id,
        attraction_id: @attraction&.id,
        insurance_id: @insurance&.id
      }
    end

    def restore_from_state(state)
      @travel_date = Date.parse(state['travel_date']) if state['travel_date']
      @destination = state['destination']
      @traveler_count = state['traveler_count']
      @duration = state['duration']
      @tour = TourGroupProduct.find_by(id: state['tour_id']) if state['tour_id']
      @attraction = Attraction.find_by(id: state['attraction_id']) if state['attraction_id']
      @insurance = InsuranceProduct.find_by(id: state['insurance_id']) if state['insurance_id']
    end
  end
end
