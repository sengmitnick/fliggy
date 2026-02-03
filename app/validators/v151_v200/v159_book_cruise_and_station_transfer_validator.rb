# frozen_string_literal: true

require_relative '../base_validator'

# V159: 预订上海邮轮 + 火车站接站服务
# 验证用户能够完成邮轮预订+火车站接站服务的组合下单

module V151V200
  class V159BookCruiseAndStationTransferValidator < BaseValidator
    self.validator_id = 'v159_book_cruise_and_station_transfer_validator'
    self.task_id = 'c9d0e1f2-3a4b-5c6d-7e8f-9a0b1c2d3e4f'
    self.title = '预订邮轮并预订火车站接站服务（上海日本航线）'
    self.description = '预订明天上海出发的日本邮轮航线，并预订当天的火车站接站服务'
    self.timeout_seconds = 300

    def prepare
      @departure_date = Date.tomorrow
      @departure_port = '上海'
      @station_location = '上海虹桥站'
      @duration_days = 6
      @duration_nights = 5
      @adult_count = 1
      
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
      
      # 创建火车站接站服务（出发当天）
      pickup_datetime = @departure_date.in_time_zone + 10.hours
      Transfer.create!(
        user: user,
        transfer_type: 'train_pickup',
        service_type: 'from_station',
        location_from: @station_location,
        location_to: "#{@departure_port}邮轮码头",
        pickup_datetime: pickup_datetime,
        vehicle_type: 'business_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 100.0,
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
      
      # 断言4: 创建了火车站接站服务
      add_assertion "创建了火车站接站服务", weight: 30 do
        @transfer = Transfer
          .where(transfer_type: 'train_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到火车站接站服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言5: 接站地点在上海
      add_assertion "接站地点在上海", weight: 10 do
        in_city = @transfer.location_from.include?(@departure_port) || @transfer.location_to.include?(@departure_port)
        expect(in_city).to be(true),
          "接站地点错误。期望包含: #{@departure_port}, 实际: #{@transfer.location_from} -> #{@transfer.location_to}"
      end
    end
  end
end
