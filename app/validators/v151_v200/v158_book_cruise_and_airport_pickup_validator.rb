# frozen_string_literal: true

require_relative '../base_validator'

# V158: 预订上海邮轮 + 机场接机服务
# 验证用户能够完成邮轮预订+机场接机服务的组合下单

module V151V200
  class V158BookCruiseAndAirportPickupValidator < BaseValidator
    self.validator_id = 'v158_book_cruise_and_airport_pickup_validator'
    self.task_id = 'b8c9d0e1-2f3a-4b5c-6d7e-8f9a0b1c2d3e'
    self.title = '预订邮轮并预订机场接机服务（上海日本航线）'
    self.description = '预订明天上海出发的日本邮轮航线，并预订当天的机场接机服务'
    self.timeout_seconds = 300

    def prepare
      @departure_date = Date.tomorrow
      @departure_port = '上海'
      @airport_location = '上海浦东国际机场'
      @duration_days = 6
      @duration_nights = 5
      @adult_count = 2
      
      # 查找可用的上海邮轮班次
      @available_sailings = CruiseSailing
        .where("departure_port LIKE ?", "%#{@departure_port}%")
        .where(duration_days: @duration_days, duration_nights: @duration_nights, data_version: 0)
        .where("departure_date >= ?", @departure_date)
        .to_a
      
      expect(@available_sailings).not_to be_empty, "数据包缺少上海出发的邮轮班次"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      sailing = @available_sailings.first
      ship = sailing.cruise_ship
      
      # 查找舱房类型（选择经济舱）
      cabin_type = CabinType.where(data_version: 0, cruise_ship_id: ship.id, category: 'interior').first
      raise "未找到舱房类型" unless cabin_type
      
      # 查找或创建邮轮产品
      cruise_product = CruiseProduct.find_or_create_by!(
        cruise_sailing_id: sailing.id,
        cabin_type_id: cabin_type.id,
        data_version: 0
      ) do |product|
        product.merchant_name = '邮轮旅游网'
        product.price_per_person = 3500.0
        product.occupancy_requirement = 2
        product.stock = 10
        product.sales_count = 0
        product.is_refundable = true
        product.requires_confirmation = false
        product.status = 'on_sale'
      end
      
      total_price = cruise_product.price_per_person * @adult_count
      
      # 创建邮轮订单
      CruiseOrder.create!(
        user_id: user.id,
        cruise_product_id: cruise_product.id,
        quantity: @adult_count,
        contact_name: user.name,
        contact_phone: '13800138000',
        total_price: total_price,
        accept_terms: true,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建机场接机服务（出发当天）
      pickup_datetime = @departure_date.in_time_zone + 9.hours
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @airport_location,
        location_to: "#{@departure_port}邮轮码头",
        pickup_datetime: pickup_datetime,
        vehicle_type: 'business_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 150.0,
        status: 'pending',
        data_version: @data_version
      )
    end

    def verify
      # 断言1: 创建了邮轮订单
      add_assertion "创建了邮轮订单", weight: 30 do
        @cruise_order = CruiseOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@cruise_order).not_to be_nil, "未找到任何邮轮订单"
      end
      
      return if @cruise_order.nil?
      
      # 断言2: 出发港正确
      add_assertion "出发港正确（#{@departure_port}）", weight: 15 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expect(sailing.departure_port).to include(@departure_port),
          "出发港错误。期望包含: #{@departure_port}, 实际: #{sailing.departure_port}"
      end
      
      # 断言3: 行程天数正确
      add_assertion "行程天数正确（#{@duration_days}天#{@duration_nights}晚）", weight: 15 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expect(sailing.duration_days).to eq(@duration_days),
          "行程天数错误。期望: #{@duration_days}天, 实际: #{sailing.duration_days}天"
      end
      
      # 断言4: 成人数量=2
      add_assertion "成人数量=2", weight: 10 do
        expect(@cruise_order.quantity).to eq(@adult_count),
          "成人数量错误。期望: #{@adult_count}, 实际: #{@cruise_order.quantity}"
      end
      
      # 断言5: 创建了机场接机服务
      add_assertion "创建了机场接机服务", weight: 30 do
        @transfer = Transfer
          .where(transfer_type: 'airport_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到机场接机服务订单"
      end
    end
  end
end
