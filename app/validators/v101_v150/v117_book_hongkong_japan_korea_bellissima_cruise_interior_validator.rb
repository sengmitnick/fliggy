# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例117: 给张三、李四预订日韩邮轮（地中海辉煌号，香港出发，7天6晚，内舱房，最近的未来班次）
#
# 任务描述:
#   用户想预订日韩邮轮，为2位成人（张三、李四）。
#   要求地中海辉煌号，行程7天6晚，从香港出发，选择最近的未来班次，预订内舱房（性价比之选）。
#   Agent 需要在符合条件的班次中，选择departure_date（出发日期）最早的未来班次。
#
# 业务流程（5个关键步骤）：
#   1. 搜索地中海辉煌号的邮轮班次
#   2. 筛选船只名包含"辉煌"的班次
#   3. 筛选出发港包含"香港"、行程7天6晚的班次
#   4. 筛选未来日期的班次（departure_date >= 今天）
#   5. 选择departure_date最早的班次，预订内舱房（category='interior'），为2位成人，填写2位成人的出行信息，联系人从出行人中选择
#
# 复杂度分析（5个关键点）：
#   1. 需要理解邮轮筛选：船只名包含"地中海辉煌号"（关键词"辉煌"）
#   2. 需要理解出发港筛选：departure_port包含"香港"
#   3. 需要理解行程天数：duration_days=7且duration_nights=6
#   4. 需要选择未来最早的班次：对比多个班次的departure_date，选择最早的未来日期
#   5. 需要填写2位成人的出行信息，联系人从出行人中选择
#   ❌ 不能随机选择：必须精确筛选未来班次并选择最早日期的
#
# 评分标准（9项，总计100分）：
#   - 订单已创建（15分）
#   - 船只正确（地中海辉煌号）（10分）
#   - 出发港正确（香港）（10分）
#   - 行程天数正确（7天6晚）（10分）
#   - 出发日期在未来（15分）
#   - 舱房类型正确（内舱房）（15分）
#   - 预订数量正确（2位成人）（10分）
#   - 联系人信息正确（张三或李四）（5分）
#   - 选择了最近日期的未来班次（5分）
#   - 乘客信息正确（张三、李四）（5分）
module V101V150
  class V117BookHongkongJapanKoreaBellissimaCruiseInteriorValidator < BaseValidator
    self.validator_id = 'v117_book_hongkong_japan_korea_bellissima_cruise_interior_validator'
    self.task_id = 'eb47869c-0c0f-4f08-b97a-49fa29721261'
    self.title = '给张三、李四预订日韩邮轮（地中海辉煌号，香港出发，7天6晚，内舱房，最近的未来班次）'
    self.description = '预订日韩邮轮（地中海辉煌号，7天6晚，香港出发，最近的未来班次）'
    self.timeout_seconds = 240

    def prepare
      @ship_keyword = '辉煌'
      @departure_port_keyword = '香港'
      @expected_days = 7
      @expected_nights = 6
      @expected_cabin_category = 'interior'
      @adult_count = 2
      
      # 查询最近的未来班次的出发月份
      nearest_sailing = CruiseSailing
        .joins(:cruise_ship)
        .where('cruise_ships.name LIKE ?', "%#{@ship_keyword}%")
        .where('departure_port LIKE ?', "%#{@departure_port_keyword}%")
        .where(duration_days: @expected_days, duration_nights: @expected_nights)
        .where('departure_date >= ?', Date.current)
        .where(data_version: 0)
        .order(:departure_date)
        .first
      
      raise "未找到符合条件的未来航次（#{@ship_keyword}，#{@departure_port_keyword}，#{@expected_days}天#{@expected_nights}晚）" unless nearest_sailing
      
      @expected_month = nearest_sailing.departure_date.month
      @expected_departure_date = nearest_sailing.departure_date

      # 预查询乘客信息（避免 simulate 中查询 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_passenger_names = [@zhangsan.name, @lisi.name]
      
      # 有效联系人电话映射（联系人可以是任何一个出行人）
      @valid_contact_phones = {
        '张三' => @zhangsan.phone,
        '李四' => @lisi.phone
      }

      {
        task: "请预订日韩邮轮，要求地中海辉煌号，行程#{@expected_days}天#{@expected_nights}晚，从#{@departure_port_keyword}出发，选择最近的未来班次，预订内舱房（性价比之选），为#{@adult_count}位成人",
        ship_keyword: @ship_keyword,
        departure_port_keyword: @departure_port_keyword,
        duration: "#{@expected_days}天#{@expected_nights}晚",
        cabin_category: '内舱房（interior）',
        nearest_departure_date: @expected_departure_date.strftime('%Y-%m-%d'),
        adult_count: @adult_count,
        hint: "筛选船只名包含'辉煌'、出发港包含'香港'、duration_days=7且duration_nights=6的班次，选择最近日期的未来班次，预订内舱房（category='interior'）",
        expected_passengers: @expected_passenger_names.join('、')
      }
    end

    def simulate
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      lisi = user.passengers.find_by!(name: '李四', data_version: 0)

      sailing = CruiseSailing
        .joins(:cruise_ship)
        .where('cruise_ships.name LIKE ?', "%#{@ship_keyword}%")
        .where('departure_port LIKE ?', "%#{@departure_port_keyword}%")
        .where(duration_days: @expected_days, duration_nights: @expected_nights)
        .where('departure_date >= ?', Date.current)
        .where(data_version: '0')
        .order(:departure_date)
        .first

      raise "未找到符合条件的航次（#{@ship_keyword}，#{@departure_port_keyword}，#{@expected_days}天#{@expected_nights}晚）" unless sailing

      cabin_type = CabinType.where(data_version: '0', cruise_ship_id: sailing.cruise_ship_id, category: @expected_cabin_category).first
      raise "未找到符合条件的舱房类型（#{@expected_cabin_category}）" unless cabin_type

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
        quantity: @adult_count,
        contact_name: zhangsan.name,
        contact_phone: zhangsan.phone,
        passenger_info: [
          { name: zhangsan.name, id_number: zhangsan.id_number, phone: zhangsan.phone },
          { name: lisi.name, id_number: lisi.id_number, phone: lisi.phone }
        ],
        total_price: product.price_per_person * @adult_count,
        accept_terms: true,
        status: 'pending',
        data_version: @data_version
      )
    end

    def verify
      # 断言1: 订单已创建（权重15%）
      add_assertion "订单已创建", weight: 15 do
        all_orders = CruiseOrder
          .joins(cruise_product: { cruise_sailing: :cruise_ship })
          .where('cruise_ships.name LIKE ?', "%#{@ship_keyword}%")
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_orders).not_to be_empty,
          "未找到任何邮轮订单。请确认是否已创建订单"
        
        @order = all_orders.find do |o|
          sailing = o.cruise_product.cruise_sailing
          cabin_type = o.cruise_product.cabin_type
          sailing.departure_port.include?(@departure_port_keyword) &&
            cabin_type&.category == @expected_cabin_category
        end
        
        expect(@order).not_to be_nil,
          "未找到符合条件的订单（出发港：#{@departure_port_keyword}，舱房类型：#{@expected_cabin_category}）"
      end
      
      return if @order.nil?
      
      # 断言2: 船只正确（权重10%）
      add_assertion "船只正确（地中海辉煌号）", weight: 10 do
        ship_name = @order.cruise_product.cruise_sailing.cruise_ship.name
        expect(ship_name).to include(@ship_keyword),
          "船只错误。期望: 包含'#{@ship_keyword}'，实际: #{ship_name}"
      end
      
      # 断言3: 出发港正确（权重10%）
      add_assertion "出发港正确（香港）", weight: 10 do
        departure_port = @order.cruise_product.cruise_sailing.departure_port
        expect(departure_port).to include(@departure_port_keyword),
          "出发港错误。期望: 包含'#{@departure_port_keyword}'，实际: #{departure_port}"
      end
      
      # 断言4: 行程天数正确（权重10%）
      add_assertion "行程天数正确（#{@expected_days}天#{@expected_nights}晚）", weight: 10 do
        sailing = @order.cruise_product.cruise_sailing
        actual_days = sailing.duration_days
        actual_nights = sailing.duration_nights
        
        expect(actual_days).to eq(@expected_days),
          "行程天数错误。期望: #{@expected_days}天，实际: #{actual_days}天"
        expect(actual_nights).to eq(@expected_nights),
          "行程晚数错误。期望: #{@expected_nights}晚，实际: #{actual_nights}晚"
      end
      
      # 断言5: 出发日期在未来（权重15%）
      add_assertion "出发日期在未来", weight: 15 do
        sailing = @order.cruise_product.cruise_sailing
        
        expect(sailing.departure_date).to be >= Date.current,
          "出发日期必须在未来。实际: #{sailing.departure_date}（今天是#{Date.current}）"
      end
      
      # 断言6: 舱房类型正确（权重15%）
      add_assertion "舱房类型正确（内舱房）", weight: 15 do
        cabin_type = @order.cruise_product.cabin_type
        expect(cabin_type&.category).to eq(@expected_cabin_category),
          "舱房类型错误。期望: #{@expected_cabin_category}（内舱房），实际: #{cabin_type&.category}"
      end
      
      # 断言7: 预订数量正确（权重10%）
      add_assertion "预订数量正确（#{@adult_count}位成人）", weight: 10 do
        expect(@order.quantity).to eq(@adult_count),
          "预订数量错误。期望: #{@adult_count}位成人，实际: #{@order.quantity}位"
      end
      
      # 断言8: 联系人信息正确（权重5%）
      add_assertion "联系人信息正确（张三或李四）", weight: 5 do
        valid_contacts = ['张三', '李四']
        expect(valid_contacts).to include(@order.contact_name),
          "联系人姓名错误。期望: 张三或李四，实际: #{@order.contact_name}"
        
        expected_phone = @valid_contact_phones[@order.contact_name]
        expect(@order.contact_phone).to eq(expected_phone),
          "联系人电话与姓名不匹配。联系人: #{@order.contact_name}，期望电话: #{expected_phone}，实际电话: #{@order.contact_phone}"
      end
      
      # 断言9: 选择了最近日期的未来班次（权重5%）
      add_assertion "选择了最近日期的未来班次", weight: 5 do
        ship = CruiseShip.where(data_version: 0).where('name LIKE ?', "%#{@ship_keyword}%").first
        
        # 筛选符合条件的班次：正确的出发港、行程天数、未来日期
        available_sailings = CruiseSailing.where(
          data_version: 0,
          cruise_ship_id: ship.id,
          duration_days: @expected_days,
          duration_nights: @expected_nights
        ).where('departure_port LIKE ?', "%#{@departure_port_keyword}%")
         .where('departure_date >= ?', Date.current)
        
        nearest = available_sailings.order(departure_date: :asc).first
        actual_sailing = @order.cruise_product.cruise_sailing
        
        expect(actual_sailing.id).to eq(nearest.id),
          "未选择最近日期的未来班次。应选: #{nearest.departure_date}（#{nearest.departure_date.strftime('%Y年%m月%d日')}），实际: #{actual_sailing.departure_date}（#{actual_sailing.departure_date.strftime('%Y年%m月%d日')}）"
      end
      
      # 断言10: 乘客信息正确（权重5%）
      add_assertion "乘客信息正确（张三、李四）", weight: 5 do
        passengers = @order.passenger_list
        expect(passengers).not_to be_empty, "未填写乘客信息（passenger_info为空）"
        expect(passengers.size).to eq(@adult_count),
          "乘客数量错误。期望: #{@adult_count}位，实际: #{passengers.size}位"
        
        passenger_names = passengers.map { |p| p['name'] || p[:name] }.compact
        @expected_passenger_names.each do |expected_name|
          expect(passenger_names).to include(expected_name),
            "缺少乘客信息。期望包含: #{expected_name}，实际乘客: #{passenger_names.join('、')}"
        end
      end
    end

    private

    def execution_state_data
      {
        ship_keyword: @ship_keyword,
        departure_port_keyword: @departure_port_keyword,
        expected_days: @expected_days,
        expected_nights: @expected_nights,
        expected_cabin_category: @expected_cabin_category,
        expected_month: @expected_month,
        adult_count: @adult_count,
        expected_passenger_names: @expected_passenger_names,
        valid_contact_phones: @valid_contact_phones
      }
    end

    def restore_from_state(data)
      @ship_keyword = data['ship_keyword'] || '辉煌'
      @departure_port_keyword = data['departure_port_keyword'] || '香港'
      @expected_days = data['expected_days'] || 7
      @expected_nights = data['expected_nights'] || 6
      @expected_cabin_category = data['expected_cabin_category'] || 'interior'
      @expected_month = data['expected_month'] || 3
      @adult_count = data['adult_count'] || 2
      @expected_passenger_names = data['expected_passenger_names'] || ['张三', '李四']
      @valid_contact_phones = data['valid_contact_phones'] || { '张三' => '13800138000', '李四' => '13900139000' }
    end
  end
end
