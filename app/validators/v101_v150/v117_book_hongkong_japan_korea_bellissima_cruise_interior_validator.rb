# frozen_string_literal: true

require_relative '../base_validator'

# V117: 帮张三预订3月份香港出发的地中海辉煌号日韩邮轮（7天6晚，最近班次，2间内舱房）
#
# 任务描述:
#   用户需要为张三预订日韩邮轮服务，包含：
#   1) 邮轮订单（CruiseOrder，地中海辉煌号，香港出发）
#   2) 行程要求（7天6晚，3月份最近的班次）
#   3) 舱房类型（内舱房 interior，2间）
#   4) 乘客人数（2位成人）
#   确保船只、出发港、行程天数、出发月份（选择最近班次）、舱房类型和预订数量正确
#
# 评分标准:
#   - 创建了邮轮订单（地中海辉煌号） (20%)
#   - 船只正确（地中海辉煌号） (15%)
#   - 出发港正确（香港） (10%)
#   - 行程天数正确（7天6晚） (10%)
#   - 出发月份正确（3月份，最近班次） (10%)
#   - 舱房类型正确（内舱房） (15%)
#   - 预订数量正确（2间内舱房） (10%)
#   - 联系人信息正确（张三） (10%)
module V101V150
  class V117BookHongkongJapanKoreaBellissimaCruiseInteriorValidator < BaseValidator
    self.validator_id = 'v117_book_hongkong_japan_korea_bellissima_cruise_interior_validator'
    self.task_id = 'eb47869c-0c0f-4f08-b97a-49fa29721261'
    self.title = '帮张三预订3月份香港出发的地中海辉煌号日韩邮轮（7天6晚，最近班次，2间内舱房）'
    self.description = '帮张三预订3月份香港出发的地中海辉煌号日韩邮轮（7天6晚，最近班次，2间内舱房）'
    self.timeout_seconds = 240

    def prepare
      ship_keyword = '辉煌'
      departure_port_keyword = '香港'
      expected_days = 7
      expected_nights = 6
      expected_cabin_category = 'interior'
      expected_month = 3
      adult_count = 2

      # 预查询张三的乘客信息（避免 simulate 中查询 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @zhangsan.name
      @expected_contact_phone = @zhangsan.phone

      {
        task: "请预订日韩邮轮，要求地中海辉煌号，行程#{expected_days}天#{expected_nights}晚，从#{departure_port_keyword}出发，选择#{expected_month}月份最近的一个班次，预订内舱房（性价比之选），为#{adult_count}位成人",
        ship_keyword: ship_keyword,
        departure_port_keyword: departure_port_keyword,
        duration: "#{expected_days}天#{expected_nights}晚",
        cabin_category: '内舱房（interior）',
        month: "#{expected_month}月",
        adult_count: adult_count,
        hint: "筛选船只名包含'辉煌'、出发港包含'香港'、duration_days=7且duration_nights=6的班次，选择#{expected_month}月份最近日期的班次，预订内舱房（category='interior'）"
      }
    end

    def simulate
      ship_keyword = '辉煌'
      departure_port_keyword = '香港'
      expected_days = 7
      expected_nights = 6
      expected_cabin_category = 'interior'
      expected_month = 3
      adult_count = 2

      # 预查询张三的乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)

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
        p.merchant_name = 'MSC邮轮旗舰店'
        p.price_per_person = 4200.0
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
        contact_name: zhangsan.name,
        contact_phone: zhangsan.phone,
        total_price: product.price_per_person * adult_count,
        accept_terms: true,
        status: 'pending',
        data_version: @data_version
      )
    end

    def verify
      ship_keyword = '辉煌'
      departure_port_keyword = '香港'
      expected_days = 7
      expected_nights = 6
      expected_cabin_category = 'interior'
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
      
      add_assertion "船只正确（地中海辉煌号）", weight: 15 do
        ship_name = @order.cruise_product.cruise_sailing.cruise_ship.name
        expect(ship_name).to include(ship_keyword),
          "船只错误。期望: 包含'#{ship_keyword}'，实际: #{ship_name}"
      end
      
      add_assertion "出发港正确（香港）", weight: 10 do
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
      
      add_assertion "舱房类型正确（内舱房）", weight: 15 do
        cabin_type = @order.cruise_product.cabin_type
        expect(cabin_type&.category).to eq(expected_cabin_category),
          "舱房类型错误。期望: #{expected_cabin_category}（内舱房），实际: #{cabin_type&.category}"
      end
      
      add_assertion "预订数量正确（#{adult_count}间内舱房）", weight: 10 do
        expect(@order.quantity).to eq(adult_count),
          "预订数量错误。期望: #{adult_count}间，实际: #{@order.quantity}间"
      end
      
      add_assertion "联系人信息正确（张三 13800138000）", weight: 10 do
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
      @expected_contact_name = data['expected_contact_name'] || '张三'
      @expected_contact_phone = data['expected_contact_phone'] || '13800138000'
    end
  end
end
