# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例115: 预订加勒比邮轮（海洋光谱号，10天9晚，5月出发，阳台房）
#
# 测试内容：
# - 邮轮筛选（海洋光谱号/Royal Caribbean）
# - 出发港过滤（迈阿密）
# - 行程天数匹配（10天9晚）
# - 舱房类型选择（阳台房）
# - 出发月份筛选（5月）
# - 日期优化选择（选择最近可用日期）
# - 预订数量验证（2位成人）
# - 价格合理性验证
#
# 用户需求：
# "我想5月份坐海洋光谱号游加勒比，10天9晚的行程，订2间阳台房"
module V101V150
  class V115BookMiamiCaribbeanSpectrumCruiseBalconyValidator < BaseValidator
    self.validator_id = 'v115_book_miami_caribbean_spectrum_cruise_balcony_validator'
    self.task_id = 'b4a00a86-51cd-40b8-800a-67287efdfdd6'
    self.title = '预订加勒比邮轮（海洋光谱号，10天9晚，5月出发，阳台房）'
    self.description = '预订加勒比邮轮航线，选择海洋光谱号5月份最近一班10天9晚行程，预订阳台房（舒适之选），为2位成人'
    self.timeout_seconds = 240

    def prepare
      ship_keyword = '光谱'
      departure_port_keyword = '迈阿密'
      expected_days = 10
      expected_nights = 9
      expected_cabin_category = 'balcony'
      expected_month = 5
      adult_count = 2

      {
        task: "请预订加勒比邮轮，要求海洋光谱号，行程#{expected_days}天#{expected_nights}晚，从#{departure_port_keyword}出发，选择#{expected_month}月份最近的一个班次，预订阳台房（舒适之选），为#{adult_count}位成人",
        ship_keyword: ship_keyword,
        departure_port_keyword: departure_port_keyword,
        duration: "#{expected_days}天#{expected_nights}晚",
        cabin_category: '阳台房（balcony）',
        month: "#{expected_month}月",
        adult_count: adult_count,
        hint: "筛选船只名包含'光谱'、出发港包含'迈阿密'、duration_days=10且duration_nights=9的班次，选择#{expected_month}月份最近日期的班次，预订阳台房（category='balcony'）"
      }
    end

    def simulate
      ship_keyword = '光谱'
      departure_port_keyword = '迈阿密'
      expected_days = 10
      expected_nights = 9
      expected_cabin_category = 'balcony'
      expected_month = 5
      adult_count = 2

      sailing = CruiseSailing
        .joins(:cruise_ship)
        .where('cruise_ships.name LIKE ?', "%#{ship_keyword}%")
        .where('departure_port LIKE ?', "%#{departure_port_keyword}%")
        .where(duration_days: expected_days, duration_nights: expected_nights)
        .where('EXTRACT(MONTH FROM departure_date) = ?', expected_month)
        .where('departure_date >= ?', Date.current)
        .where(data_version: '0')
        .order(:departure_date)
        .first

      raise "未找到符合条件的航次（#{ship_keyword}，#{departure_port_keyword}，#{expected_days}天#{expected_nights}晚，#{expected_month}月）" unless sailing

      cabin_type = CabinType.where(data_version: '0', cruise_ship_id: sailing.cruise_ship_id, category: expected_cabin_category).first
      raise "未找到符合条件的舱房类型（#{expected_cabin_category}）" unless cabin_type

      product = CruiseProduct.find_or_create_by!(
        cruise_sailing_id: sailing.id,
        cabin_type_id: cabin_type.id,
        data_version: @data_version
      ) do |p|
        p.merchant_name = '皇家加勒比国际游轮旗舰店'
        p.price_per_person = 12800.0
        p.occupancy_requirement = 2
        p.stock = 10
        p.sales_count = 0
        p.is_refundable = true
        p.requires_confirmation = false
        p.status = 'on_sale'
      end

      user = User.first || User.create!(email: 'test@example.com', password: 'password')
      CruiseOrder.create!(
        user_id: user.id,
        cruise_product_id: product.id,
        quantity: adult_count,
        contact_name: '王五',
        contact_phone: '13800138008',
        total_price: product.price_per_person * adult_count,
        accept_terms: true,
        status: 'pending',
        data_version: @data_version
      )
    end

    def verify
      ship_keyword = '光谱'
      departure_port_keyword = '迈阿密'
      expected_days = 10
      expected_nights = 9
      expected_cabin_category = 'balcony'
      expected_month = 5
      adult_count = 2

      add_assertion "订单已创建", weight: 20 do
        all_orders = CruiseOrder
          .joins(cruise_product: { cruise_sailing: :cruise_ship })
          .where('cruise_ships.name LIKE ?', "%#{ship_keyword}%")
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_orders).not_to be_empty,
          "未找到任何邮轮订单。请确认是否已创建订单"
        
        @order = all_orders.find do |o|
          sailing = o.cruise_product.cruise_sailing
          cabin_type = o.cruise_product.cabin_type
          sailing.departure_port.include?(departure_port_keyword) &&
            cabin_type&.category == expected_cabin_category
        end
        
        expect(@order).not_to be_nil,
          "未找到符合条件的订单（出发港：#{departure_port_keyword}，舱房类型：#{expected_cabin_category}）"
      end
      
      return if @order.nil?
      
      add_assertion "船只正确（海洋光谱号）", weight: 15 do
        ship_name = @order.cruise_product.cruise_sailing.cruise_ship.name
        expect(ship_name).to include(ship_keyword),
          "船只错误。期望: 包含'#{ship_keyword}'，实际: #{ship_name}"
      end
      
      add_assertion "出发港正确（迈阿密）", weight: 10 do
        departure_port = @order.cruise_product.cruise_sailing.departure_port
        expect(departure_port).to include(departure_port_keyword),
          "出发港错误。期望: 包含'#{departure_port_keyword}'，实际: #{departure_port}"
      end
      
      add_assertion "行程天数正确（#{expected_days}天#{expected_nights}晚）", weight: 10 do
        sailing = @order.cruise_product.cruise_sailing
        actual_days = sailing.duration_days
        actual_nights = sailing.duration_nights
        
        expect(actual_days).to eq(expected_days),
          "行程天数错误。期望: #{expected_days}天，实际: #{actual_days}天"
        expect(actual_nights).to eq(expected_nights),
          "行程晚数错误。期望: #{expected_nights}晚，实际: #{actual_nights}晚"
      end
      
      add_assertion "出发月份正确（5月份）", weight: 10 do
        sailing = @order.cruise_product.cruise_sailing
        actual_month = sailing.departure_date.month
        
        expect(actual_month).to eq(expected_month),
          "出发月份错误。期望: #{expected_month}月, 实际: #{actual_month}月（#{sailing.departure_date}）"
      end
      
      add_assertion "舱房类型正确（阳台房）", weight: 15 do
        cabin_type = @order.cruise_product.cabin_type
        expect(cabin_type&.category).to eq(expected_cabin_category),
          "舱房类型错误。期望: #{expected_cabin_category}（阳台房），实际: #{cabin_type&.category}"
      end
      
      add_assertion "预订数量正确（#{adult_count}间阳台房）", weight: 10 do
        expect(@order.quantity).to eq(adult_count),
          "预订数量错误。期望: #{adult_count}间，实际: #{@order.quantity}间"
      end
      
      add_assertion "选择最近可用日期（5月份最早班次）", weight: 10 do
        available_sailings = CruiseSailing
          .joins(:cruise_ship)
          .where('cruise_ships.name LIKE ?', "%#{ship_keyword}%")
          .where('departure_port LIKE ?', "%#{departure_port_keyword}%")
          .where(duration_days: expected_days, duration_nights: expected_nights)
          .where('EXTRACT(MONTH FROM departure_date) = ?', expected_month)
          .where('departure_date >= ?', Date.current)
          .order(:departure_date)
          .to_a
        
        expect(available_sailings).not_to be_empty,
          "未找到符合条件的可用航次（船只：#{ship_keyword}，出发港：#{departure_port_keyword}，#{expected_days}天#{expected_nights}晚，#{expected_month}月）"
        
        earliest_sailing = available_sailings.first
        actual_sailing = @order.cruise_product.cruise_sailing
        
        expect(actual_sailing.departure_date).to eq(earliest_sailing.departure_date),
          "未选择最近日期。期望: #{earliest_sailing.departure_date}（最早），��际: #{actual_sailing.departure_date}"
      end
    end
  end
end
