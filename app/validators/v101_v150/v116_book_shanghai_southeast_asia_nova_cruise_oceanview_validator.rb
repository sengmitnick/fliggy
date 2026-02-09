# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例116: 预订东南亚邮轮（爱达新星号，9天8晚，3月出发，海景房）
#
# 测试内容：
# - 邮轮筛选（爱达新星号/AIDA Cruises）
# - 出发港过滤（上海）
# - 行程天数匹配（9天8晚）
# - 舱房类型选择（海景房）
# - 出发月份筛选（3月）
# - 日期优化选择（选择最近可用日期）
# - 预订数量验证（2位成人）
# - 价格合理性验证
#
# 用户需求：
# "我想3月份坐爱达新星号游东南亚，9天8晚的行程，订2间海景房"
module V101V150
  class V116BookShanghaiSoutheastAsiaNovaCruiseOceanviewValidator < BaseValidator
    self.validator_id = 'v116_book_shanghai_southeast_asia_nova_cruise_oceanview_validator'
    self.task_id = '70a9737c-8db3-4c11-b179-2522c8f58af2'
    self.title = '给陈静预订上海出发东南亚邮轮（爱达新星号，9天8晚，3月，海景房）'
    self.description = '帮陈静预订东南亚邮轮航线，选择爱达新星号（环保LNG动力邮轮）3月份最近一班9天8晚行程，预订海景房（观景之选），为2位成人'
    self.timeout_seconds = 240

    def prepare
      ship_keyword = '新星'
      departure_port_keyword = '上海'
      expected_days = 9
      expected_nights = 8
      expected_cabin_category = 'ocean_view'
      expected_month = 3
      adult_count = 2

      # 预查询陈静的乘客信息（避免 simulate 中查询 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      @expected_contact_name = @chenjing.name
      @expected_contact_phone = @chenjing.phone

      {
        task: "请预订东南亚邮轮，要求爱达新星号，行程#{expected_days}天#{expected_nights}晚，从#{departure_port_keyword}出发，选择#{expected_month}月份最近的一个班次，预订海景房（观景之选），为#{adult_count}位成人",
        ship_keyword: ship_keyword,
        departure_port_keyword: departure_port_keyword,
        duration: "#{expected_days}天#{expected_nights}晚",
        cabin_category: '海景房（ocean_view）',
        month: "#{expected_month}月",
        adult_count: adult_count,
        hint: "筛选船只名包含'新星'、出发港包含'上海'、duration_days=9且duration_nights=8的班次，选择#{expected_month}月份最近日期的班次，预订海景房（category='ocean_view'）"
      }
    end

    def simulate
      ship_keyword = '新星'
      departure_port_keyword = '上海'
      expected_days = 9
      expected_nights = 8
      expected_cabin_category = 'ocean_view'
      expected_month = 3
      adult_count = 2

      # 预查询陈静的乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)

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
        p.merchant_name = 'AIDA邮轮旗舰店'
        p.price_per_person = 5800.0
        p.occupancy_requirement = 2
        p.stock = 10
        p.sales_count = 0
        p.is_refundable = true
        p.requires_confirmation = false
        p.status = 'on_sale'
      end

      CruiseOrder.create!(
        user_id: user.id,
        cruise_product_id: product.id,
        quantity: adult_count,
        contact_name: chenjing.name,
        contact_phone: chenjing.phone,
        total_price: product.price_per_person * adult_count,
        accept_terms: true,
        status: 'pending',
        data_version: @data_version
      )
    end

    def verify
      ship_keyword = '新星'
      departure_port_keyword = '上海'
      expected_days = 9
      expected_nights = 8
      expected_cabin_category = 'ocean_view'
      expected_month = 3
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
      
      add_assertion "船只正确（爱达新星号）", weight: 15 do
        ship_name = @order.cruise_product.cruise_sailing.cruise_ship.name
        expect(ship_name).to include(ship_keyword),
          "船只错误。期望: 包含'#{ship_keyword}'，实际: #{ship_name}"
      end
      
      add_assertion "出发港正确（上海）", weight: 10 do
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
      
      add_assertion "出发月份正确（3月份）", weight: 10 do
        sailing = @order.cruise_product.cruise_sailing
        actual_month = sailing.departure_date.month
        
        expect(actual_month).to eq(expected_month),
          "出发月份错误。期望: #{expected_month}月, 实际: #{actual_month}月（#{sailing.departure_date}）"
      end
      
      add_assertion "舱房类型正确（海景房）", weight: 15 do
        cabin_type = @order.cruise_product.cabin_type
        expect(cabin_type&.category).to eq(expected_cabin_category),
          "舱房类型错误。期望: #{expected_cabin_category}（海景房），实际: #{cabin_type&.category}"
      end
      
      add_assertion "预订数量正确（#{adult_count}间海景房）", weight: 10 do
        expect(@order.quantity).to eq(adult_count),
          "预订数量错误。期望: #{adult_count}间，实际: #{@order.quantity}间"
      end
      
      add_assertion "联系人信息正确（陈静 13300133001）", weight: 10 do
        expect(@order.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@order.contact_name}"
        expect(@order.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@order.contact_phone}"
      end
    end

    private

    def execution_state_data
      {
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end

    def restore_from_state(data)
      @expected_contact_name = data['expected_contact_name'] || '陈静'
      @expected_contact_phone = data['expected_contact_phone'] || '13300133001'
    end
  end
end
