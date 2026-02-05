# frozen_string_literal: true

module V301V350
  class V330MountainClimbingEquipmentValidator < BaseValidator
    self.validator_id = 330
    self.task_id = "3bee5307-7b2d-4ad6-8efc-fe0c2130b9a8"
    self.title = "登山季高峰期装备租赁"
    self.description = "用户需要预订10月登山黄金季的专业装备租赁服务"
    self.timeout_seconds = 180

    def prepare
      # 10月登山黄金季（明年10月15日）
      @travel_date = Date.today + 280.days
      @destination = "黄山登山装备租赁"
      @rental_days = 3
      
      # 创建深度旅游服务商
      @agency = TravelAgency.find_by!(
        name: "安徽户外探险旅行社",
        data_version: 0
      )
      
      # 创建登山装备深度旅游产品
      @deep_product = DeepTravelProduct.find_by!(
        title: "黄山登山专业装备租赁套餐",
        location: "黄山",
        data_version: 0
      )

      {
        travel_date: @travel_date.to_s,
        destination: @destination,
        rental_days: @rental_days,
        product_title: @deep_product.title,
        task_info: "10月登山黄金季专业装备租赁预订"
      }
    end

    def simulate
      raise NotImplementedError, "请实现AI Agent逻辑：查询用户信息、查询#{@travel_date}的#{@destination}装备租赁产品、创建预订"
    end

    def verify
      add_assertion "创建了登山装备租赁预订", weight: 30 do
        all_bookings = DeepTravelBooking
          .joins(:deep_travel_product)
          .includes(:deep_travel_product)
          .where(deep_travel_products: { location: "黄山" })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何装备租赁预订"
        
        @bookings = all_bookings.select { |b|
          b.booking_date.to_date == @travel_date &&
          b.deep_travel_product.title.include?("装备")
        }
        
        expect(@bookings.size).to be >= 1, "未找到符合条件的预订"
      end

      return if @bookings.nil? || @bookings.empty?

      add_assertion "地点正确（黄山）", weight: 15 do
        @bookings.each do |booking|
          expect(booking.deep_travel_product.location).to eq("黄山"),
            "地点错误。期望: 黄山, 实际: #{booking.deep_travel_product.location}"
        end
      end

      add_assertion "租赁日期正确（10月登山季：#{@travel_date}）", weight: 20 do
        @bookings.each do |booking|
          actual_date = booking.booking_date.to_date
          expect(actual_date).to eq(@travel_date),
            "租赁日期错误。期望: #{@travel_date}（10月登山黄金季），实际: #{actual_date}"
        end
      end

      add_assertion "租赁天数正确（#{@rental_days}天）", weight: 15 do
        @bookings.each do |booking|
          expect(booking.traveler_count).to eq(@rental_days),
            "租赁天数错误。期望: #{@rental_days}天, 实际: #{booking.traveler_count}天"
        end
      end

      add_assertion "包含登山装备关键词", weight: 20 do
        @bookings.each do |booking|
          title = booking.deep_travel_product.title
          description = booking.deep_travel_product.description || ""
          expect(title.include?("装备") || title.include?("登山") || description.include?("登山杖")).to be true,
            "缺少登山装备关键词"
        end
      end
    end

    def execution_state_data
      {
        travel_date: @travel_date&.to_s,
        destination: @destination,
        rental_days: @rental_days,
        deep_product_id: @deep_product&.id
      }
    end

    def restore_from_state(state)
      @travel_date = Date.parse(state['travel_date']) if state['travel_date']
      @destination = state['destination']
      @rental_days = state['rental_days']
      @deep_product = DeepTravelProduct.find_by(id: state['deep_product_id']) if state['deep_product_id']
    end
  end
end
