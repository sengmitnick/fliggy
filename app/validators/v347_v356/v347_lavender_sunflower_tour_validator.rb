# frozen_string_literal: true

module V347V356
  class V347LavenderSunflowerTourValidator < BaseValidator
    self.validator_id = 347
    self.task_id = "b95cd2c4-f7d3-42b0-b9dd-dc6cdef60d9c"
    self.title = "花期限定游（薰衣草/向日葵）"
    self.description = "用户需要预订6月薰衣草盛开季的普罗旺斯风格观光游"
    self.timeout_seconds = 180

    def prepare
      # 6月薰衣草盛开季（明年6月15日）
      @travel_date = Date.today + 160.days
      @destination = "普罗旺斯风格薰衣草园"
      @traveler_count = 2
      
      # 创建旅行社
      @agency = TravelAgency.find_by!(
        name: "新疆伊犁花海旅行社",
        data_version: 0
      )
      
      # 创建薰衣草主题景点
      @attraction = Attraction.find_by!(
        name: @destination,
        city: "伊犁",
        data_version: 0
      )

      # 创建花期限定旅游产品
      @tour = TourGroupProduct.find_by!(
        title: "薰衣草花期限定观光游",
        destination: @destination,
        data_version: 0
      )

      {
        travel_date: @travel_date.to_s,
        destination: @destination,
        traveler_count: @traveler_count,
        tour_title: @tour.title,
        task_info: "6月薰衣草盛开季限定旅游预订"
      }
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、查询#{@travel_date}的#{@destination}花期限定游产品、创建预订"
    end

    def verify
      add_assertion "创建了薰衣草花期限定游预订", weight: 30 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何花期限定游预订"
        
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

      add_assertion "出发日期正确（6月薰衣草盛开季：#{@travel_date}）", weight: 20 do
        @tour_bookings.each do |booking|
          actual_date = booking.departure_date.to_date
          expect(actual_date).to eq(@travel_date),
            "出发日期错误。期望: #{@travel_date}（6月盛开季），实际: #{actual_date}"
        end
      end

      add_assertion "人数正确（#{@traveler_count}人）", weight: 15 do
        @tour_bookings.each do |booking|
          expect(booking.traveler_count).to eq(@traveler_count),
            "人数错误。期望: #{@traveler_count}人, 实际: #{booking.traveler_count}人"
        end
      end

      add_assertion "包含花期限定游特色标签", weight: 20 do
        @tour_bookings.each do |booking|
          tags = booking.tour_group_product.tags || ""
          expect(tags.include?("花期限定") || tags.include?("薰衣草")).to be true,
            "缺少花期限定游特色标签"
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
